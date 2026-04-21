// Phase 51: Daily cron — roll forward standing appointment visits.
//
// Runs at 08:00 UTC daily via pg_cron. For each standing appointment with an
// 'upcoming' visit whose scheduled_date has passed (> 1 day ago):
// 1. Mark the visit as 'assumed'
// 2. Set last_assumed_date on the parent appointment
// 3. Create the next 'upcoming' visit
// 4. If 2+ consecutive assumed visits without a confirmed one, flag for missed-visit nudge
//
// Deploy: supabase functions deploy roll-forward-standing-visits --no-verify-jwt

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);

    const now = new Date();
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split("T")[0];

    // Find all upcoming visits that are past due (scheduled_date < yesterday)
    const { data: overdueVisits, error: fetchError } = await supabase
      .from("standing_appointment_visits")
      .select("id, standing_appointment_id, scheduled_date")
      .eq("status", "upcoming")
      .lt("scheduled_date", yesterdayStr);

    if (fetchError) throw fetchError;
    if (!overdueVisits || overdueVisits.length === 0) {
      console.log("[roll-forward] No overdue visits found.");
      return new Response(JSON.stringify({ processed: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log(`[roll-forward] Processing ${overdueVisits.length} overdue visit(s).`);

    let processedCount = 0;
    let missedNudgeCount = 0;

    for (const visit of overdueVisits) {
      // 1. Mark as assumed
      const { error: updateError } = await supabase
        .from("standing_appointment_visits")
        .update({
          status: "assumed",
          confirmed_by: "assumed_rollforward",
          confirmed_at: now.toISOString(),
        })
        .eq("id", visit.id);

      if (updateError) {
        console.error(`[roll-forward] Failed to update visit ${visit.id}:`, updateError);
        continue;
      }

      // 2. Fetch the parent appointment for cadence info
      const { data: appointment, error: apptError } = await supabase
        .from("standing_appointments")
        .select("*")
        .eq("id", visit.standing_appointment_id)
        .single();

      if (apptError || !appointment) {
        console.error(`[roll-forward] Failed to fetch appointment for visit ${visit.id}:`, apptError);
        continue;
      }

      // Skip if paused or archived
      if (appointment.is_paused || appointment.archived_at) continue;

      // 3. Update last_assumed_date
      const { error: apptUpdateError } = await supabase
        .from("standing_appointments")
        .update({
          last_assumed_date: visit.scheduled_date,
          updated_at: now.toISOString(),
        })
        .eq("id", appointment.id);

      if (apptUpdateError) {
        console.error(`[roll-forward] Failed to update appointment ${appointment.id}:`, apptUpdateError);
      }

      // 4. Calculate next visit date
      const intervalDays = appointment.cadence_interval_days || cadenceIntervalFromType(appointment.cadence_type);
      const scheduledDate = new Date(visit.scheduled_date + "T00:00:00Z");
      scheduledDate.setDate(scheduledDate.getDate() + intervalDays);
      const nextDateStr = scheduledDate.toISOString().split("T")[0];

      // 5. Create next upcoming visit
      const { error: insertError } = await supabase
        .from("standing_appointment_visits")
        .insert({
          standing_appointment_id: appointment.id,
          scheduled_date: nextDateStr,
          status: "upcoming",
        });

      if (insertError) {
        console.error(`[roll-forward] Failed to create next visit for ${appointment.id}:`, insertError);
      }

      // 6. Update next_expected_date on the appointment
      const { error: nextDateError } = await supabase
        .from("standing_appointments")
        .update({ next_expected_date: nextDateStr, updated_at: now.toISOString() })
        .eq("id", appointment.id);

      if (nextDateError) {
        console.error(`[roll-forward] Failed to update next date for ${appointment.id}:`, nextDateError);
      }

      // 7. Maintain 4-visit rolling window — ensure at least 4 upcoming visits exist
      const VISIT_WINDOW_SIZE = 4;
      const { data: upcomingVisits } = await supabase
        .from("standing_appointment_visits")
        .select("id, scheduled_date")
        .eq("standing_appointment_id", appointment.id)
        .eq("status", "upcoming")
        .order("scheduled_date", { ascending: false });

      const upcomingCount = upcomingVisits?.length ?? 0;
      if (upcomingCount < VISIT_WINDOW_SIZE) {
        // Find the latest scheduled date to extend from
        const allVisits = await supabase
          .from("standing_appointment_visits")
          .select("scheduled_date")
          .eq("standing_appointment_id", appointment.id)
          .order("scheduled_date", { ascending: false })
          .limit(1);

        let lastDate = allVisits.data?.[0]?.scheduled_date || nextDateStr;
        const toGenerate = VISIT_WINDOW_SIZE - upcomingCount;

        for (let i = 0; i < toGenerate; i++) {
          const extendDate = new Date(lastDate + "T00:00:00Z");
          extendDate.setDate(extendDate.getDate() + intervalDays);
          lastDate = extendDate.toISOString().split("T")[0];

          await supabase
            .from("standing_appointment_visits")
            .insert({
              standing_appointment_id: appointment.id,
              scheduled_date: lastDate,
              status: "upcoming",
            });
        }
        console.log(`[roll-forward] Generated ${toGenerate} additional visit(s) for ${appointment.id} to maintain window`);
      }

      // 8. Check for missed-visit condition (2+ consecutive assumed without confirmed)
      const { data: recentVisits } = await supabase
        .from("standing_appointment_visits")
        .select("status")
        .eq("standing_appointment_id", appointment.id)
        .order("scheduled_date", { ascending: false })
        .limit(5);

      if (recentVisits) {
        let consecutiveAssumed = 0;
        for (const v of recentVisits) {
          if (v.status === "assumed") consecutiveAssumed++;
          else if (v.status === "confirmed") break;
        }
        if (consecutiveAssumed >= 2) {
          missedNudgeCount++;
          console.log(`[roll-forward] Missed-visit nudge for appointment ${appointment.id} (${consecutiveAssumed} consecutive assumed)`);
          // Future: Create an inbox item or dashboard alert for the user
        }
      }

      processedCount++;
    }

    console.log(`[roll-forward] Done. Processed: ${processedCount}, missed nudges: ${missedNudgeCount}`);
    return new Response(
      JSON.stringify({ processed: processedCount, missedNudges: missedNudgeCount }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[roll-forward] Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

function cadenceIntervalFromType(type: string): number {
  switch (type) {
    case "weekly": return 7;
    case "biweekly": return 14;
    case "triweekly": return 21;
    case "monthly": return 30;
    case "bimonthly": return 60;
    case "quarterly": return 91;
    case "semiannual": return 182;
    case "annual": return 365;
    default: return 30;
  }
}

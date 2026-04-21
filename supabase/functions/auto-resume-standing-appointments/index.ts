// Phase 51: Daily cron — auto-resume paused standing appointments.
//
// Runs at 07:00 UTC daily via pg_cron. For each paused appointment
// where auto_resume_date <= today:
// 1. Unpause the appointment
// 2. Set next_expected_date
// 3. Create new upcoming visit
// 4. Send push notification to the household
//
// Deploy: supabase functions deploy auto-resume-standing-appointments --no-verify-jwt

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

    const todayStr = new Date().toISOString().split("T")[0];
    const now = new Date().toISOString();

    // Find paused appointments ready to resume
    const { data: appointments, error: fetchError } = await supabase
      .from("standing_appointments")
      .select("*, contractors(company_name)")
      .eq("is_paused", true)
      .not("auto_resume_date", "is", null)
      .lte("auto_resume_date", todayStr)
      .is("archived_at", null);

    if (fetchError) throw fetchError;
    if (!appointments || appointments.length === 0) {
      console.log("[auto-resume] No appointments ready to resume.");
      return new Response(JSON.stringify({ resumed: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log(`[auto-resume] Resuming ${appointments.length} appointment(s).`);

    let resumedCount = 0;

    for (const appt of appointments) {
      const resumeDate = appt.auto_resume_date > todayStr ? appt.auto_resume_date : todayStr;

      // 1. Unpause
      const { error: updateError } = await supabase
        .from("standing_appointments")
        .update({
          is_paused: false,
          paused_at: null,
          pause_reason: null,
          auto_resume_date: null,
          next_expected_date: resumeDate,
          updated_at: now,
        })
        .eq("id", appt.id);

      if (updateError) {
        console.error(`[auto-resume] Failed to resume ${appt.id}:`, updateError);
        continue;
      }

      // 2. Create new upcoming visit
      const { error: visitError } = await supabase
        .from("standing_appointment_visits")
        .insert({
          standing_appointment_id: appt.id,
          scheduled_date: resumeDate,
          status: "upcoming",
        });

      if (visitError) {
        console.error(`[auto-resume] Failed to create visit for ${appt.id}:`, visitError);
      }

      // 3. Send push notification
      const vendorName = appt.contractors?.company_name || "Your vendor";
      const nextDay = getNextDayName(resumeDate);
      try {
        await supabase.functions.invoke("send-push-notification", {
          body: {
            recipient_user_ids: await getHouseholdUserIds(supabase, appt.household_id),
            title: `${vendorName} resumes today`,
            body: `Next visit expected ${nextDay}.`,
            data: { type: "standing_appointment_resumed", appointment_id: appt.id },
          },
        });
      } catch (pushError) {
        console.error(`[auto-resume] Push notification failed for ${appt.id}:`, pushError);
      }

      resumedCount++;
    }

    console.log(`[auto-resume] Done. Resumed: ${resumedCount}`);
    return new Response(
      JSON.stringify({ resumed: resumedCount }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[auto-resume] Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

async function getHouseholdUserIds(
  supabase: ReturnType<typeof createClient>,
  householdId: string
): Promise<string[]> {
  const { data } = await supabase
    .from("users")
    .select("id")
    .eq("household_id", householdId);
  return (data || []).map((u: { id: string }) => u.id);
}

function getNextDayName(dateStr: string): string {
  const date = new Date(dateStr + "T12:00:00Z");
  const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  return days[date.getUTCDay()];
}

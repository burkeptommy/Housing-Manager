// Haven Edge Function: cadence-notifications
//
// Fires evening-before and morning-of push notifications for household
// pickup rhythms (trash day, recycling, school dropoff, etc.).
//
// July 2026 rewrite (audit F1): this used to read the DEAD household_cadences
// table (Phase 55.3 removed every iOS writer; all cadence data now lives in
// `routines`). Pickup pushes fired against stale pre-Phase-55 rows and
// routines created since never notified. It now reads `routines`, ports the
// iOS RoutineOccurrenceExpander week/interval math faithfully, honors
// active_months, notifies only non-vendor "pickup" kinds (mirrors the iOS
// PickupDayBanner's !kind.isVendorBased filter — a vendor visit must not
// hijack the morning trash banner), and CLAIMS a per-(household,window,day)
// slot in routine_reminder_sends before pushing so hourly cron runs and
// stray re-triggers can never double-push.
//
// Invocation: POST { window: "evening_before" | "morning_of" }
// Scheduled hourly (migration 20270122); per-household local-hour gating
// selects the right households each run.
//
// Deploy: supabase functions deploy cadence-notifications --no-verify-jwt

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Window = "evening_before" | "morning_of";

// Routine kinds that read naturally as a pickup/day reminder. Mirrors the
// iOS RoutineKind.isVendorBased == false set (PickupDayBanner filter).
// Vendor-based kinds (cleaning, landscaping, pool_service, …, other_service)
// have their own scheduling surfaces and must NOT push a pickup reminder.
const PICKUP_KINDS = new Set([
  "trash", "recycling", "compost", "yard_waste",
  "recurring_delivery", "school_dropoff", "school_pickup",
  "other_cadence",
]);

// Day-interval per cadence_type for monthly+ routines (matches
// RoutineOccurrenceExpander.expandSingle).
const INTERVAL_DAYS: Record<string, number> = {
  monthly: 30, bimonthly: 60, quarterly: 91, semiannual: 182, annual: 365,
};

interface RoutineRow {
  id: string;
  household_id: string;
  routine_kind: string;
  label: string;
  cadence_type: string;
  cadence_interval_days: number | null;
  days_of_week: number[] | null;
  time_of_day: string | null;
  start_date: string;
  next_expected_date: string;
  active_months: number[];
  evening_before_reminder: boolean;
  morning_of_reminder: boolean;
}

const MS_PER_DAY = 24 * 60 * 60 * 1000;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const body = await req.json().catch(() => ({}));
    const window: Window = body.window === "morning_of" ? "morning_of" : "evening_before";

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // 1. Load active, property-scoped, pickup-kind routines with the right
    //    reminder flag. archived_at IS NULL + is_paused = false = live.
    const reminderCol = window === "evening_before"
      ? "evening_before_reminder"
      : "morning_of_reminder";

    const { data: routineRows, error: routineError } = await supabase
      .from("routines")
      .select(
        "id, household_id, routine_kind, label, cadence_type, cadence_interval_days, days_of_week, time_of_day, start_date, next_expected_date, active_months, evening_before_reminder, morning_of_reminder",
      )
      .is("archived_at", null)
      .eq("is_paused", false)
      .eq(reminderCol, true);

    if (routineError) {
      console.error("[cadence-notifications] routine fetch:", routineError);
      return new Response(
        JSON.stringify({ error: "Failed to load routines" }),
        { status: 500, headers },
      );
    }

    const rows = ((routineRows ?? []) as RoutineRow[])
      .filter((r) => PICKUP_KINDS.has(r.routine_kind));
    if (rows.length === 0) {
      return new Response(
        JSON.stringify({ window, households_notified: 0, routines_matched: 0 }),
        { status: 200, headers },
      );
    }

    // 2. Household timezones. NOTE (July 2026): `properties` has no
    //    timezone column today, so every household resolves to the
    //    documented America/New_York fallback (Haven's TestFlight is all
    //    Northeast). The map is kept so that when a `time_zone` column is
    //    added, restoring the lookup here is a one-line change — the rest
    //    of the function is already fully tz-parameterized.
    const timezoneByHousehold = new Map<string, string>();

    // 3. Per household, gate on the local surfacing window, then match each
    //    routine's occurrence math against the reference day (today for
    //    morning_of, tomorrow for evening_before).
    const matches = new Map<string, RoutineRow[]>();
    const localSendDayByHousehold = new Map<string, string>();
    const now = new Date();
    for (const row of rows) {
      const tz = timezoneByHousehold.get(row.household_id) ?? "America/New_York";
      const localHour = toTimezoneHour(now, tz);

      // Enforce the surfacing windows so a stray/hourly run outside the
      // window doesn't spam users.
      if (window === "evening_before" && (localHour < 18 || localHour >= 24)) continue;
      if (window === "morning_of" && (localHour < 0 || localHour >= 10)) continue;

      const referenceDate = window === "evening_before" ? addDays(now, 1) : now;
      if (!routineOccursOn(row, referenceDate, tz)) continue;

      if (!matches.has(row.household_id)) matches.set(row.household_id, []);
      matches.get(row.household_id)!.push(row);
      // The dedup key uses TODAY's local date (send day), not the reference
      // day — two evening pushes on the same evening must collapse.
      if (!localSendDayByHousehold.has(row.household_id)) {
        localSendDayByHousehold.set(row.household_id, localDateString(now, tz));
      }
    }

    if (matches.size === 0) {
      return new Response(
        JSON.stringify({ window, households_notified: 0, routines_matched: 0 }),
        { status: 200, headers },
      );
    }

    // 4. Recipients per household.
    const { data: userRows } = await supabase
      .from("users")
      .select("id, household_id")
      .in("household_id", Array.from(matches.keys()));
    const userIdsByHousehold = new Map<string, string[]>();
    for (const row of (userRows ?? []) as { id: string; household_id: string }[]) {
      if (!userIdsByHousehold.has(row.household_id)) userIdsByHousehold.set(row.household_id, []);
      userIdsByHousehold.get(row.household_id)!.push(row.id);
    }

    // 5. For each household: CLAIM the (household, window, send-day) slot
    //    atomically. Only the run that inserts the row actually pushes;
    //    hourly re-runs and re-triggers no-op. Then fire one collapsed push.
    let householdsNotified = 0;
    let routinesMatched = 0;
    for (const [householdId, routineList] of matches.entries()) {
      const userIds = userIdsByHousehold.get(householdId) ?? [];
      if (userIds.length === 0) continue;

      const sentOn = localSendDayByHousehold.get(householdId)!;
      const { data: claimed, error: claimErr } = await supabase
        .from("routine_reminder_sends")
        .insert({ household_id: householdId, reminder_window: window, sent_on: sentOn })
        .select("household_id");
      // A conflict (already sent this window today) yields an error with
      // no data — skip silently. A real error also skips (fail-safe: don't
      // double-push on an unknown DB state).
      if (claimErr || !claimed || claimed.length === 0) continue;

      const labels = routineList
        .map((c) => displayLabel(c.routine_kind))
        .filter((x): x is string => !!x);
      if (labels.length === 0) continue;

      const joined = joinLabels(labels);
      const whenPhrase = window === "evening_before" ? "tomorrow" : "this morning";
      const allPickupStyle = routineList.every((c) => isPickupType(c.routine_kind));
      const title = allPickupStyle ? `${joined} pickup ${whenPhrase}` : `${joined} ${whenPhrase}`;
      const timeHint = sharedTimeLabel(routineList);
      const bodyText = timeHint
        ? `Set out by ${timeHint}.`
        : `${window === "evening_before" ? "Tomorrow" : "Today"} in ${timeZoneShortName(
            timezoneByHousehold.get(householdId) ?? "America/New_York",
          )}.`;

      const pushResponse = await fetch(
        `${supabaseUrl}/functions/v1/send-push-notification`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${serviceRoleKey}`,
          },
          body: JSON.stringify({
            recipient_user_ids: userIds,
            title,
            body: bodyText,
            data: {
              type: "cadence",
              window,
              household_id: householdId,
              routine_ids: routineList.map((c) => c.id).join(","),
            },
          }),
        },
      );

      if (!pushResponse.ok) {
        const errorText = await pushResponse.text();
        console.error("[cadence-notifications] push failed", householdId, errorText.substring(0, 200));
        // Release the claim so the next run retries this household.
        await supabase.from("routine_reminder_sends")
          .delete()
          .eq("household_id", householdId).eq("reminder_window", window).eq("sent_on", sentOn);
        continue;
      }

      householdsNotified += 1;
      routinesMatched += routineList.length;
    }

    return new Response(
      JSON.stringify({ window, households_notified: householdsNotified, routines_matched: routinesMatched }),
      { status: 200, headers },
    );
  } catch (error) {
    console.error("[cadence-notifications] Error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers },
    );
  }
});

// MARK: - Occurrence matching (ports RoutineOccurrenceExpander)

/// True when the routine has an occurrence on `referenceDate` (evaluated in
/// the household timezone). Faithful port of the iOS expander:
///   - weekly/biweekly/triweekly: weekday ∈ days_of_week, month ∈
///     active_months, referenceDay ≥ start_date, and whole-weeks-since-start
///     % interval == 0.
///   - monthly/bimonthly/quarterly/semiannual/annual/custom_days: referenceDay
///     is a non-negative multiple of the interval from next_expected_date (or
///     start_date), month ∈ active_months.
function routineOccursOn(routine: RoutineRow, referenceDate: Date, tz: string): boolean {
  const refDay = startOfLocalDay(referenceDate, tz);
  const refMonth = monthLocal(referenceDate, tz);
  if (!routine.active_months.includes(refMonth)) return false;

  const cadence = routine.cadence_type;
  if (cadence === "weekly" || cadence === "biweekly" || cadence === "triweekly") {
    const daysOfWeek = routine.days_of_week ?? [];
    if (daysOfWeek.length === 0) return false;
    const weekday = dayOfWeekLocal(referenceDate, tz);
    if (!daysOfWeek.includes(weekday)) return false;
    const anchor = parseLocalDate(routine.start_date, tz);
    if (!anchor || refDay.getTime() < anchor.getTime()) return false;
    const interval = cadence === "weekly" ? 1 : cadence === "biweekly" ? 2 : 3;
    if (interval === 1) return true;
    const days = Math.round((refDay.getTime() - anchor.getTime()) / MS_PER_DAY);
    const weeks = Math.floor(days / 7);
    return weeks % interval === 0;
  }

  // Monthly+ / custom_days: interval-from-anchor.
  const intervalDays = cadence === "custom_days"
    ? (routine.cadence_interval_days ?? 0)
    : (INTERVAL_DAYS[cadence] ?? 0);
  if (intervalDays <= 0) return false;
  const anchor = parseLocalDate(routine.next_expected_date, tz)
    ?? parseLocalDate(routine.start_date, tz);
  if (!anchor) return false;
  const delta = Math.round((refDay.getTime() - anchor.getTime()) / MS_PER_DAY);
  if (delta < 0) return false;
  return delta % intervalDays === 0;
}

// MARK: - Copy / labels

function isPickupType(kind: string): boolean {
  return kind === "trash" || kind === "recycling" || kind === "compost"
    || kind === "yard_waste" || kind === "recurring_delivery";
}

function displayLabel(kind: string): string | null {
  switch (kind) {
    case "trash": return "Trash";
    case "recycling": return "Recycling";
    case "compost": return "Compost";
    case "yard_waste": return "Yard waste";
    case "recurring_delivery": return "Recurring delivery";
    case "school_dropoff": return "School dropoff";
    case "school_pickup": return "School pickup";
    case "other_cadence": return "Household reminder";
    default: return null;
  }
}

function joinLabels(labels: string[]): string {
  if (labels.length === 1) return labels[0];
  if (labels.length === 2) return `${labels[0]} and ${labels[1].toLowerCase()}`;
  const head = labels.slice(0, -1).map((l, i) => (i === 0 ? l : l.toLowerCase())).join(", ");
  return `${head}, and ${labels[labels.length - 1].toLowerCase()}`;
}

// MARK: - Timezone helpers (Intl-based, DST-safe)

function toTimezoneHour(date: Date, timeZone: string): number {
  const formatter = new Intl.DateTimeFormat("en-US", {
    hour: "2-digit", hour12: false, timeZone,
  });
  const parts = formatter.formatToParts(date);
  return Number(parts.find((p) => p.type === "hour")?.value ?? "0");
}

/// ISO 8601 weekday (1 = Sunday) in the target tz, matching the routines
/// schema (days_of_week) + iOS Calendar.weekday.
function dayOfWeekLocal(date: Date, timeZone: string): number {
  const weekdayString = new Intl.DateTimeFormat("en-US", { weekday: "short", timeZone }).format(date);
  const map: Record<string, number> = { Sun: 1, Mon: 2, Tue: 3, Wed: 4, Thu: 5, Fri: 6, Sat: 7 };
  return map[weekdayString] ?? 1;
}

function monthLocal(date: Date, timeZone: string): number {
  const monthStr = new Intl.DateTimeFormat("en-US", { month: "numeric", timeZone }).format(date);
  return Number(monthStr) || 1;
}

function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * MS_PER_DAY);
}

function timeZoneShortName(timeZone: string): string {
  const parts = new Intl.DateTimeFormat("en-US", { timeZoneName: "short", timeZone }).formatToParts(new Date());
  return parts.find((p) => p.type === "timeZoneName")?.value ?? timeZone;
}

/// "YYYY-MM-DD" for the given instant in the target tz (used as the dedup
/// send-day key + reference-day identity).
function localDateString(date: Date, timeZone: string): string {
  return new Intl.DateTimeFormat("en-CA", {
    year: "numeric", month: "2-digit", day: "2-digit", timeZone,
  }).format(date);
}

function startOfLocalDay(date: Date, timeZone: string): Date {
  const [y, m, d] = localDateString(date, timeZone).split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

function parseLocalDate(raw: string, timeZone: string): Date | null {
  const match = raw?.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (!match) return null;
  const [, y, m, d] = match;
  const utc = new Date(Date.UTC(Number(y), Number(m) - 1, Number(d)));
  return startOfLocalDay(utc, timeZone);
}

function sharedTimeLabel(rows: RoutineRow[]): string | null {
  const times = new Set<string>();
  for (const row of rows) {
    if (!row.time_of_day) return null;
    times.add(row.time_of_day);
  }
  if (times.size !== 1) return null;
  const [hh, mm] = Array.from(times)[0].split(":");
  const hour = Number(hh);
  const suffix = hour >= 12 ? "pm" : "am";
  const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  return mm === "00" ? `${displayHour}${suffix}` : `${displayHour}:${mm}${suffix}`;
}

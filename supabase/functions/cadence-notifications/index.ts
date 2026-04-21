// Haven Edge Function: cadence-notifications
// Phase 54D.4: Fires evening-before and morning-of push notifications
// for household cadences (trash day, recycling, school dropoff, etc.).
//
// Expected invocation:
//   POST /cadence-notifications
//   Body: { window: "evening_before" | "morning_of" }
//
// Run on a schedule (via Supabase scheduled functions or an external
// cron). Typical cadence:
//   - Every hour, or
//   - 6pm local per timezone bucket (evening_before)
//   - 7am local per timezone bucket (morning_of)
//
// This function is intentionally timezone-aware: it reads each
// household's primary property `time_zone` field and compares to UTC
// now to decide whether the household has crossed its evening or
// morning threshold. Households without a time_zone fall back to
// America/New_York since Haven's initial TestFlight is all Northeast.
//
// Deploy with:
//   supabase functions deploy cadence-notifications --no-verify-jwt

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Window = "evening_before" | "morning_of";

interface CadenceRow {
  id: string;
  household_id: string;
  cadence_type: string;
  label: string;
  days_of_week: number[];
  time_of_day: string | null;
  evening_before_reminder: boolean;
  morning_of_reminder: boolean;
  // Phase 54E.2: frequency + anchor. `weeks_interval == 1` is weekly
  // and ignores `anchor_date`.
  weeks_interval: number | null;
  anchor_date: string | null;
  created_at: string;
}

interface HouseholdRow {
  id: string;
  name: string | null;
}

interface PropertyRow {
  household_id: string;
  time_zone: string | null;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const body = await req.json().catch(() => ({}));
    const window: Window = body.window === "morning_of"
      ? "morning_of"
      : "evening_before";

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // 1. Load every active cadence with the right reminder flag.
    const reminderCol = window === "evening_before"
      ? "evening_before_reminder"
      : "morning_of_reminder";

    const { data: cadences, error: cadenceError } = await supabase
      .from("household_cadences")
      .select(
        "id, household_id, cadence_type, label, days_of_week, time_of_day, evening_before_reminder, morning_of_reminder, weeks_interval, anchor_date, created_at",
      )
      .eq("is_active", true)
      .eq(reminderCol, true);

    if (cadenceError) {
      console.error("[cadence-notifications] cadence fetch:", cadenceError);
      return new Response(
        JSON.stringify({ error: "Failed to load cadences" }),
        { status: 500, headers },
      );
    }

    const rows = (cadences ?? []) as CadenceRow[];
    if (rows.length === 0) {
      return new Response(
        JSON.stringify({ window, households_notified: 0, cadences_matched: 0 }),
        { status: 200, headers },
      );
    }

    // 2. Pull the household timezones in one shot. Falls back to
    //    America/New_York when a household has no property on file.
    const householdIds = Array.from(new Set(rows.map((r) => r.household_id)));
    const { data: propertyTzRows } = await supabase
      .from("properties")
      .select("household_id, time_zone")
      .in("household_id", householdIds);
    const timezoneByHousehold = new Map<string, string>();
    for (const row of (propertyTzRows ?? []) as PropertyRow[]) {
      if (row.time_zone && !timezoneByHousehold.has(row.household_id)) {
        timezoneByHousehold.set(row.household_id, row.time_zone);
      }
    }

    // Household name used in the notification body.
    const { data: householdRows } = await supabase
      .from("households")
      .select("id, name")
      .in("id", householdIds);
    const householdNameById = new Map<string, string>();
    for (const row of (householdRows ?? []) as HouseholdRow[]) {
      householdNameById.set(row.id, row.name ?? "Your home");
    }

    // 3. For each household, decide whether its local time is in the
    //    right surfacing window AND whether any of its cadences match
    //    today (morning_of) or tomorrow (evening_before).
    const matches = new Map<string, CadenceRow[]>();
    const now = new Date();
    for (const row of rows) {
      const tz = timezoneByHousehold.get(row.household_id) ?? "America/New_York";
      const localNow = toTimezone(now, tz);
      const localHour = localNow.hours;

      // Enforce the surfacing windows so a stray cron run outside the
      // window doesn't spam users.
      if (window === "evening_before" && (localHour < 18 || localHour >= 24)) {
        continue;
      }
      if (window === "morning_of" && (localHour < 0 || localHour >= 10)) {
        continue;
      }

      // ISO 8601 weekday. Convert from JS 0=Sunday to Haven's 1=Sunday
      // convention so the schema match works without translation.
      const referenceDate = window === "evening_before" ? addDays(now, 1) : now;
      const referenceWeekday = dayOfWeekLocal(referenceDate, tz);
      if (!row.days_of_week.includes(referenceWeekday)) continue;

      // Phase 54E.2: biweekly+ cadences only fire on weeks that match
      // the anchor date's offset. Skip otherwise.
      if (!matchesFrequency(row, referenceDate, tz)) continue;

      if (!matches.has(row.household_id)) {
        matches.set(row.household_id, []);
      }
      matches.get(row.household_id)!.push(row);
    }

    if (matches.size === 0) {
      return new Response(
        JSON.stringify({ window, households_notified: 0, cadences_matched: 0 }),
        { status: 200, headers },
      );
    }

    // 4. Resolve each household's push recipients in one shot.
    const { data: userRows } = await supabase
      .from("users")
      .select("id, household_id")
      .in("household_id", Array.from(matches.keys()));
    const userIdsByHousehold = new Map<string, string[]>();
    for (const row of (userRows ?? []) as { id: string; household_id: string }[]) {
      if (!userIdsByHousehold.has(row.household_id)) {
        userIdsByHousehold.set(row.household_id, []);
      }
      userIdsByHousehold.get(row.household_id)!.push(row.id);
    }

    // 5. Fire one push per household, collapsing multiple same-day
    //    cadences into a single summary line. "Trash and recycling
    //    pickup tomorrow morning" beats two separate notifications.
    let householdsNotified = 0;
    let cadencesMatched = 0;
    for (const [householdId, cadenceList] of matches.entries()) {
      const userIds = userIdsByHousehold.get(householdId) ?? [];
      if (userIds.length === 0) continue;

      const labels = cadenceList
        .map((c) => displayLabel(c.cadence_type))
        .filter((x): x is string => !!x);
      if (labels.length === 0) continue;

      const joined = joinLabels(labels);
      const whenPhrase = window === "evening_before"
        ? "tomorrow"
        : "this morning";
      // Phase 54E.2: only use "pickup" for waste-handling cadences.
      // Cleaning / lawn / pool / pest / school / delivery cadences
      // get a cleaner "Cleaning tomorrow morning" phrasing.
      const allPickupStyle = cadenceList.every((c) => isPickupType(c.cadence_type));
      const title = allPickupStyle
        ? `${joined} pickup ${whenPhrase}`
        : `${joined} ${whenPhrase}`;
      const timeHint = sharedTimeLabel(cadenceList);
      const body = timeHint
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
            body,
            data: {
              type: "cadence",
              window,
              household_id: householdId,
              cadence_ids: cadenceList.map((c) => c.id).join(","),
            },
          }),
        },
      );

      if (!pushResponse.ok) {
        const errorText = await pushResponse.text();
        console.error(
          "[cadence-notifications] push failed",
          householdId,
          errorText.substring(0, 200),
        );
        continue;
      }

      householdsNotified += 1;
      cadencesMatched += cadenceList.length;
    }

    return new Response(
      JSON.stringify({
        window,
        households_notified: householdsNotified,
        cadences_matched: cadencesMatched,
      }),
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

// MARK: - Helpers

/// Phase 54E.2: true when the cadence is one of the waste-handling
/// types that reads naturally as "X pickup tomorrow". Vendor-backed
/// cadences (cleaning, lawn, pool, pest) use cleaner phrasing without
/// the "pickup" verb.
function isPickupType(cadenceType: string): boolean {
  return cadenceType === "trash"
    || cadenceType === "recycling"
    || cadenceType === "compost"
    || cadenceType === "yard_waste"
    || cadenceType === "recurring_delivery";
}

function displayLabel(cadenceType: string): string | null {
  switch (cadenceType) {
    case "trash": return "Trash";
    case "recycling": return "Recycling";
    case "compost": return "Compost";
    case "yard_waste": return "Yard waste";
    case "recurring_delivery": return "Recurring delivery";
    case "school_dropoff": return "School dropoff";
    case "school_pickup": return "School pickup";
    // Phase 54E.2: vendor-backed cadences.
    case "cleaning": return "Cleaning";
    case "lawn_care": return "Lawn care";
    case "pool_service": return "Pool service";
    case "pest_control": return "Pest control";
    case "other": return "Household reminder";
    default: return null;
  }
}

function joinLabels(labels: string[]): string {
  if (labels.length === 1) return labels[0];
  if (labels.length === 2) {
    return `${labels[0]} and ${labels[1].toLowerCase()}`;
  }
  const head = labels.slice(0, -1).map((l, i) => i === 0 ? l : l.toLowerCase()).join(", ");
  const tail = labels[labels.length - 1].toLowerCase();
  return `${head}, and ${tail}`;
}

/// Returns the same hour / minute rendered in a target timezone so
/// we can compare against the evening-before / morning-of window
/// bounds. Uses `Intl.DateTimeFormat` with the `timeZone` option — this
/// is the standard way to do tz math in Deno without bringing in a
/// heavyweight library.
function toTimezone(date: Date, timeZone: string): { hours: number; minutes: number } {
  const formatter = new Intl.DateTimeFormat("en-US", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
    timeZone,
  });
  const parts = formatter.formatToParts(date);
  const hour = Number(parts.find((p) => p.type === "hour")?.value ?? "0");
  const minute = Number(parts.find((p) => p.type === "minute")?.value ?? "0");
  return { hours: hour, minutes: minute };
}

/// ISO 8601 weekday (1 = Sunday) rendered against the target timezone
/// so date rollovers near midnight resolve correctly.
function dayOfWeekLocal(date: Date, timeZone: string): number {
  const formatter = new Intl.DateTimeFormat("en-US", {
    weekday: "short",
    timeZone,
  });
  const weekdayString = formatter.format(date);
  const map: Record<string, number> = {
    "Sun": 1, "Mon": 2, "Tue": 3, "Wed": 4, "Thu": 5, "Fri": 6, "Sat": 7,
  };
  return map[weekdayString] ?? 1;
}

function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

function timeZoneShortName(timeZone: string): string {
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZoneName: "short",
    timeZone,
  });
  const parts = formatter.formatToParts(new Date());
  return parts.find((p) => p.type === "timeZoneName")?.value ?? timeZone;
}

/// Phase 54E.2: true when the candidate date falls on a matching week
/// for a biweekly+ cadence. Weekly cadences (interval 1) always match.
/// Weeks-since-anchor mod interval must equal zero. Dates before the
/// anchor never match — a cadence starting in April shouldn't backfill
/// March.
function matchesFrequency(
  row: CadenceRow,
  candidate: Date,
  timeZone: string,
): boolean {
  const interval = row.weeks_interval && row.weeks_interval > 0
    ? row.weeks_interval
    : 1;
  if (interval === 1) return true;

  const anchorSource = row.anchor_date ?? row.created_at;
  const anchor = parseLocalDate(anchorSource, timeZone);
  if (!anchor) return false;

  const candidateLocal = startOfLocalDay(candidate, timeZone);
  if (candidateLocal.getTime() < anchor.getTime()) return false;

  const diffMs = candidateLocal.getTime() - anchor.getTime();
  const days = Math.round(diffMs / (24 * 60 * 60 * 1000));
  const weeks = Math.floor(days / 7);
  return weeks % interval === 0;
}

/// Parses a date string (YYYY-MM-DD or ISO timestamp) as midnight in
/// the target timezone. Returns null when the string can't be parsed.
function parseLocalDate(raw: string, timeZone: string): Date | null {
  // Try YYYY-MM-DD first.
  const dateOnlyMatch = raw.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (!dateOnlyMatch) return null;
  const [, y, m, d] = dateOnlyMatch;
  // Construct as UTC to sidestep the server's local tz, then offset
  // by the target tz so the result represents "midnight in timeZone".
  const utc = new Date(Date.UTC(Number(y), Number(m) - 1, Number(d)));
  return startOfLocalDay(utc, timeZone);
}

/// Returns the start-of-day Date for a given timestamp in the target
/// timezone. Used so week-delta math is stable across DST shifts.
function startOfLocalDay(date: Date, timeZone: string): Date {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    timeZone,
  });
  const formatted = formatter.format(date);  // e.g. "2026-04-15"
  const [y, m, d] = formatted.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

/// Returns a shared "HH:mm" time when every cadence in the list has
/// the same time. Used to decide whether the notification body can
/// say "Set out by 7am".
function sharedTimeLabel(rows: CadenceRow[]): string | null {
  const times = new Set<string>();
  for (const row of rows) {
    if (!row.time_of_day) return null;
    times.add(row.time_of_day);
  }
  if (times.size !== 1) return null;
  const raw = Array.from(times)[0];
  // Postgres `time` is "HH:MM:SS" — strip seconds.
  const [hh, mm] = raw.split(":");
  const hour = Number(hh);
  const suffix = hour >= 12 ? "pm" : "am";
  const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  if (mm === "00") return `${displayHour}${suffix}`;
  return `${displayHour}:${mm}${suffix}`;
}

import { supabase, PROVIDER_API_URL } from "./supabase";
import type { Dashboard } from "./types";

/**
 * Fetch the entire workspace dashboard from the `handyman-provider` Edge
 * Function. The function uses the service-role key on the server side to
 * stitch together rows the homeowner-scoped RLS would otherwise hide
 * (handyman_requests are scoped by household_id, not by workspace).
 *
 * One round-trip per page load. Each screen reads from `useWorkspace()`
 * which caches the result in React state.
 */
export async function fetchDashboard(): Promise<Dashboard> {
  const { data: sessionData } = await supabase.auth.getSession();
  const session = sessionData.session;
  if (!session) throw new Error("Not signed in");

  const res = await fetch(PROVIDER_API_URL, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${session.access_token}`,
      apikey:
        // The function reads the apikey header for verify-jwt; pass the
        // anon key so requests are authenticated as the signed-in user.
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew",
      "Content-Type": "application/json",
    },
  });

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`Provider API ${res.status}: ${text || res.statusText}`);
  }
  return (await res.json()) as Dashboard;
}

/**
 * Mutation helper — POST any supported provider action and return the
 * updated dashboard. Mirrors handyman.js's providerRequest("POST", body).
 */
export async function postProviderAction<T = unknown>(
  action: string,
  body: Record<string, unknown> = {}
): Promise<T> {
  const { data: sessionData } = await supabase.auth.getSession();
  const session = sessionData.session;
  if (!session) throw new Error("Not signed in");

  const res = await fetch(PROVIDER_API_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${session.access_token}`,
      apikey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ action, ...body }),
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`Provider API ${res.status}: ${text || res.statusText}`);
  }
  return (await res.json()) as T;
}

// ─── Currency helpers ───

export function formatCurrency(value: number | string | null | undefined): string {
  const n = typeof value === "number" ? value : Number(value ?? 0);
  if (!Number.isFinite(n)) return "$0";
  return `$${n.toLocaleString(undefined, { minimumFractionDigits: n % 1 === 0 ? 0 : 2 })}`;
}

export function formatCurrencyCompact(value: number | string | null | undefined): string {
  const n = typeof value === "number" ? value : Number(value ?? 0);
  if (!Number.isFinite(n) || n === 0) return "$0";
  if (Math.abs(n) >= 1000) {
    return `$${(n / 1000).toFixed(1)}K`;
  }
  return `$${Math.round(n).toLocaleString()}`;
}

// ─── Date helpers ───

export function formatRelativeTime(iso: string | null | undefined): string {
  if (!iso) return "";
  const date = new Date(iso);
  if (isNaN(date.getTime())) return "";
  const ms = Date.now() - date.getTime();
  const secs = Math.floor(ms / 1000);
  if (secs < 60) return "just now";
  const mins = Math.floor(secs / 60);
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;
  return date.toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

export function formatTime12h(time: string | null | undefined): string {
  // "14:30" or "14:30:00" → "2:30 PM"
  if (!time) return "";
  const parts = time.split(":");
  if (parts.length < 2) return time;
  const hour = Number(parts[0]);
  const minute = Number(parts[1]);
  if (!Number.isFinite(hour) || !Number.isFinite(minute)) return time;
  const ampm = hour >= 12 ? "PM" : "AM";
  const h12 = hour % 12 === 0 ? 12 : hour % 12;
  const m = minute.toString().padStart(2, "0");
  return `${h12}:${m} ${ampm}`;
}

export function isToday(iso: string | null | undefined): boolean {
  if (!iso) return false;
  const today = new Date();
  const day = iso.length >= 10 ? iso.slice(0, 10) : "";
  const todayStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
  return day === todayStr;
}

// ─── Visit punch list parser ───────────────────────────────────

/**
 * Parses a maintenance_task's notes column into individual punch list
 * items. Recognises lines starting with `-`, `•`, `*`, or numeric `1.`/
 * `1)` markers. Strips header lines ("Punch list:", "What's included:")
 * and pulls duration markers ("~15 min", "(15 min)") into a separate
 * field. Mirrors the iOS VisitNotesParser.
 */
export interface PunchListItem {
  id: string;
  title: string;
  estimatedMinutes: number | null;
}

// ─── Punch-list categorization ────────────────────────────────
//
// Long visits (10+ items) are unscannable as a flat list. Group items
// by *physical work zone* — the thing a handyman actually optimizes
// against — so they can knock out everything in one area before
// moving on. Categories are ordered roughly outside → inside →
// safety walkaround, matching how a real visit flows.

export type PunchCategoryId =
  | "exterior"
  | "roofing"
  | "attic_insulation"
  | "plumbing"
  | "kitchen_laundry"
  | "bathrooms"
  | "hvac_air"
  | "electrical"
  | "safety"
  | "general";

export interface PunchCategoryMeta {
  id: PunchCategoryId;
  label: string;
  /** SF-style icon hint for the chrome layer (Icon.tsx name). */
  icon: string;
  /** Sort order — lower = render first. */
  order: number;
}

export const PUNCH_CATEGORIES: Record<PunchCategoryId, PunchCategoryMeta> = {
  exterior: { id: "exterior", label: "Exterior + Grounds", icon: "home", order: 1 },
  roofing: { id: "roofing", label: "Roof + Gutters", icon: "home", order: 2 },
  attic_insulation: { id: "attic_insulation", label: "Attic + Insulation", icon: "home", order: 3 },
  plumbing: { id: "plumbing", label: "Plumbing", icon: "wrench", order: 4 },
  kitchen_laundry: { id: "kitchen_laundry", label: "Kitchen + Laundry", icon: "home", order: 5 },
  bathrooms: { id: "bathrooms", label: "Bathrooms", icon: "wrench", order: 6 },
  hvac_air: { id: "hvac_air", label: "HVAC + Air", icon: "wrench", order: 7 },
  electrical: { id: "electrical", label: "Electrical", icon: "bolt", order: 8 },
  safety: { id: "safety", label: "Safety walkaround", icon: "shield", order: 9 },
  general: { id: "general", label: "Other", icon: "wrench", order: 10 },
};

/**
 * Keyword-based categorizer. Order matters — first match wins, so
 * specific phrases (e.g. "smoke detector") sit above broader ones
 * (e.g. "detector" → safety) and exterior-paint sits above
 * generic-paint. Any item not matched lands in "general".
 */
export function categorizePunchItem(title: string): PunchCategoryId {
  const t = title.toLowerCase();

  // Safety devices first — high confidence, narrow
  if (/(smoke|carbon monoxide|\bco\b|co2|fire extinguisher|radon)/.test(t)) return "safety";
  if (/(gfci|afci)/.test(t)) return "safety";

  // Roof + gutters
  if (/(gutter|downspout|roof|shingle|chimney|flashing)/.test(t)) return "roofing";

  // Attic + insulation
  if (/(attic|insulation)/.test(t)) return "attic_insulation";

  // Bathrooms — caulking specifically in bath/shower
  if (/(bath|shower|toilet|vanity)/.test(t)) return "bathrooms";

  // Kitchen + laundry
  if (/(dryer|washing machine|washer|dishwasher|garbage disposal|kitchen|range hood|fridge|refrigerator|ice maker)/.test(t)) return "kitchen_laundry";

  // HVAC + air
  if (/(hvac|furnace|boiler|ac\b|air condition|mini[- ]?split|heat pump|humidifier|filter|ceiling fan|duct|thermostat)/.test(t)) return "hvac_air";

  // Plumbing — broad after kitchen/bath
  if (/(pipe|plumb|water heater|anode|sump|drain|leak|valve)/.test(t)) return "plumbing";

  // Exterior — outdoor faucets, paint, siding, foundation, weatherstripping, etc.
  if (/(exterior|outdoor|outside|paint chip|siding|deck|fence|driveway|patio|hardscape|hose|faucet (?:bib)?|spigot|hose bib|winterize.*(faucet|hose)|reopen.*faucet|drain.*hose)/.test(t)) return "exterior";
  if (/(foundation|grading|landscape|tree|shrub|bush|pest)/.test(t)) return "exterior";
  if (/(weatherstrip|weather strip|window|door)/.test(t)) return "exterior"; // window/door caulking, weatherstripping is an exterior walkaround
  if (/(caulk|seal)/.test(t)) return "exterior";

  // Electrical — broad after safety
  if (/(outlet|breaker|panel|electric|wiring|ev charger)/.test(t)) return "electrical";

  return "general";
}

export interface CategorizedPunch {
  category: PunchCategoryMeta;
  items: PunchListItem[];
  totalMinutes: number;
}

/**
 * Groups a flat punch list into ordered categories. Empty categories
 * are dropped. totalMinutes per category is the sum of any
 * estimatedMinutes (null items contribute 0).
 */
export function categorizePunchList(items: PunchListItem[]): CategorizedPunch[] {
  if (items.length === 0) return [];
  const buckets = new Map<PunchCategoryId, PunchListItem[]>();
  for (const item of items) {
    const id = categorizePunchItem(item.title);
    const bucket = buckets.get(id) ?? [];
    bucket.push(item);
    buckets.set(id, bucket);
  }
  return Array.from(buckets.entries())
    .map(([id, items]) => ({
      category: PUNCH_CATEGORIES[id],
      items,
      totalMinutes: items.reduce((sum, i) => sum + (i.estimatedMinutes ?? 0), 0),
    }))
    .sort((a, b) => a.category.order - b.category.order);
}

export function parsePunchList(notes: string | null | undefined): PunchListItem[] {
  if (!notes) return [];
  const lines = notes.split(/\r?\n/);
  const items: PunchListItem[] = [];
  for (const raw of lines) {
    const trimmed = raw.trim();
    if (!trimmed) continue;
    const lower = trimmed.toLowerCase();
    if (
      lower.includes("what's included") ||
      lower.includes("punch list:") ||
      lower.includes("tasks:") ||
      lower.endsWith(":")
    ) continue;

    let working = trimmed;
    for (const prefix of ["- ", "• ", "* "]) {
      if (working.startsWith(prefix)) {
        working = working.slice(prefix.length);
        break;
      }
    }
    // Numeric "1. " / "1) "
    const numericMatch = working.match(/^(\d+)[.)]\s+/);
    if (numericMatch) working = working.slice(numericMatch[0].length);

    if (working.length < 3) continue;

    // Extract duration
    const durMatch = working.match(/[~(·•\-]\s*(\d+)\s*min\)?/i) || working.match(/(\d+)\s*min\b/i);
    const minutes = durMatch ? Number(durMatch[1]) : null;

    // Strip duration suffix
    const cleaned = working
      .replace(/\s*\(~?\d+\s*min\)\s*$/i, "")
      .replace(/\s*~\d+\s*min\s*$/i, "")
      .replace(/\s*[·•\-]\s*~?\d+\s*min\s*$/i, "")
      .replace(/\s*\d+\s*min\s*$/i, "")
      .trim();

    items.push({
      id: `${items.length}-${cleaned.slice(0, 40)}`,
      title: cleaned,
      estimatedMinutes: minutes,
    });
  }
  return items;
}

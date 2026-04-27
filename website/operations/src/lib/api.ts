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
export async function postProviderAction(
  action: string,
  body: Record<string, unknown> = {}
): Promise<unknown> {
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
  return await res.json();
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

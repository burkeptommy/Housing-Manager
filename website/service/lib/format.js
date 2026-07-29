// lib/format.js — shared formatting helpers for the Chez service portal.
// Contract (SERVICE_PORTAL_CONTRACT.md): fmtDate, fmtDateTime, fmtMoneyCents,
// fmtAgo, truncate. All null-safe: bad input returns "".

function parseDate(iso) {
  if (!iso) return null;
  const d = iso instanceof Date ? iso : new Date(iso);
  return Number.isNaN(d.getTime()) ? null : d;
}

/** "Jul 7" (adds the year when it isn't the current one). */
export function fmtDate(iso) {
  const d = parseDate(iso);
  if (!d) return "";
  const opts = { month: "short", day: "numeric" };
  if (d.getFullYear() !== new Date().getFullYear()) opts.year = "numeric";
  return d.toLocaleDateString(undefined, opts);
}

/** "Jul 7 · 2:30 PM" */
export function fmtDateTime(iso) {
  const d = parseDate(iso);
  if (!d) return "";
  const time = d.toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" });
  return `${fmtDate(d)} · ${time}`;
}

/** 123456 -> "$1,235" (whole dollars stay whole; fractional cents show 2dp). */
export function fmtMoneyCents(cents) {
  if (cents === null || cents === undefined) return "";
  const n = Number(cents);
  if (Number.isNaN(n)) return "";
  const dollars = n / 100;
  const isWhole = Math.abs(dollars % 1) < 0.005;
  return dollars.toLocaleString(undefined, {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: isWhole ? 0 : 2,
    maximumFractionDigits: isWhole ? 0 : 2,
  });
}

/** "just now" / "5m ago" / "3h ago" / "2d ago" / "Jul 7" for older. */
export function fmtAgo(iso) {
  const d = parseDate(iso);
  if (!d) return "";
  const diffMs = Date.now() - d.getTime();
  if (diffMs < 0) return fmtDate(d); // future timestamps read as a date
  const sec = Math.floor(diffMs / 1000);
  if (sec < 45) return "just now";
  const min = Math.floor(sec / 60);
  if (min < 60) return `${min}m ago`;
  const hr = Math.floor(min / 60);
  if (hr < 24) return `${hr}h ago`;
  const day = Math.floor(hr / 24);
  if (day < 7) return `${day}d ago`;
  return fmtDate(d);
}

/** Hard-truncate to n characters with a single ellipsis character. */
export function truncate(s, n) {
  if (s === null || s === undefined) return "";
  const str = String(s);
  const max = Number(n) || 0;
  if (max <= 0 || str.length <= max) return str;
  return `${str.slice(0, Math.max(1, max - 1)).trimEnd()}…`;
}

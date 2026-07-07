// lib/ics.js — client-side iCalendar (.ics) generation for visit rows.
//
// Phase C ships a downloadable calendar file per visit rather than a
// two-way calendar sync: for one operator over ~10 homes, a .ics the
// operator drops into their own calendar is the whole job, with zero
// server work and no failure modes. Revisit real sync at 50+ households.

// RFC 5545 text escaping: backslash, semicolon, comma, and newlines.
function escapeText(value) {
  return String(value ?? "")
    .replace(/\\/g, "\\\\")
    .replace(/;/g, "\\;")
    .replace(/,/g, "\\,")
    .replace(/\r?\n/g, "\\n");
}

// UTC stamp in the compact form iCalendar wants: 20260714T143000Z.
function toICSDate(input) {
  const d = input instanceof Date ? input : new Date(input);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
}

// Fold lines to 75 octets per RFC 5545 (continuation lines start with a
// space). Keeps strict parsers happy for long SUMMARY/LOCATION values.
function foldLine(line) {
  if (line.length <= 75) return line;
  const chunks = [];
  let rest = line;
  chunks.push(rest.slice(0, 75));
  rest = rest.slice(75);
  while (rest.length > 74) {
    chunks.push(" " + rest.slice(0, 74));
    rest = rest.slice(74);
  }
  if (rest.length) chunks.push(" " + rest);
  return chunks.join("\r\n");
}

/**
 * Build an .ics document for a single visit.
 * @param {object} opts
 * @param {string} opts.uid       stable unique id (use the visit id)
 * @param {string|Date} opts.start ISO datetime the visit is scheduled for
 * @param {number} [opts.durationMinutes=60]
 * @param {string} opts.summary   e.g. "Vendor: Tyler Heating at the Whitfields"
 * @param {string} [opts.location]
 * @param {string} [opts.description]
 * @returns {string|null} the .ics text, or null when start is unparseable
 */
export function buildVisitICS(opts) {
  const start = toICSDate(opts.start);
  if (!start) return null;
  const startDate = opts.start instanceof Date ? opts.start : new Date(opts.start);
  const durationMs = (opts.durationMinutes ?? 60) * 60 * 1000;
  const end = toICSDate(new Date(startDate.getTime() + durationMs));
  const stamp = toICSDate(new Date()) ?? start;

  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Chez//Service Portal//EN",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    "BEGIN:VEVENT",
    `UID:${escapeText(opts.uid || `chez-visit-${start}`)}@getchez.com`,
    `DTSTAMP:${stamp}`,
    `DTSTART:${start}`,
    `DTEND:${end}`,
    `SUMMARY:${escapeText(opts.summary || "Chez vendor visit")}`,
  ];
  if (opts.location) lines.push(`LOCATION:${escapeText(opts.location)}`);
  if (opts.description) lines.push(`DESCRIPTION:${escapeText(opts.description)}`);
  lines.push("END:VEVENT", "END:VCALENDAR");

  return lines.map(foldLine).join("\r\n");
}

/** Trigger a browser download of an .ics file. */
export function downloadICS(filename, icsText) {
  const blob = new Blob([icsText], { type: "text/calendar;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename.endsWith(".ics") ? filename : `${filename}.ics`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

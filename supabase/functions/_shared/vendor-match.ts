// vendor-match.ts
//
// Phase 7 M4 — the sender→vendor matching ladder, factored out of
// receive-email's STEP 1 so every ingestion path attributes senders the
// same way:
//
//   1. exact email    — sender address equals a contractor's email → HIGH
//   2. company domain — sender's domain equals a contractor's email or
//                       website domain (freemail domains excluded) → HIGH.
//                       billing@greenvalley.com matches a contractor saved
//                       as office@greenvalley.com.
//   3. fuzzy name     — sender display name vs company_name token overlap
//                       (the process-invoice scorer) → MEDIUM. Never a
//                       silent attribution: medium renders as an
//                       "Is this Green Valley Landscaping?" confirm row
//                       and the homeowner's answer feeds
//                       confirmed_contractor_id into apply.
//
// A lookalike display name at a freemail address can NEVER auto-attribute.

export interface VendorMatchContractor {
  id: string;
  company_name: string;
  category: string | null;
  email: string | null;
  website?: string | null;
}

export interface VendorMatchResult {
  contractor: VendorMatchContractor;
  tier: "exact_email" | "company_domain" | "fuzzy_name";
  confidence: "high" | "medium";
  evidence: string;
}

const FREEMAIL_DOMAINS = new Set([
  "gmail.com", "googlemail.com", "yahoo.com", "ymail.com", "outlook.com",
  "hotmail.com", "live.com", "msn.com", "icloud.com", "me.com", "mac.com",
  "aol.com", "comcast.net", "verizon.net", "att.net", "sbcglobal.net",
  "optonline.net", "optimum.net", "protonmail.com", "proton.me", "pm.me",
  "mail.com", "gmx.com", "zoho.com", "fastmail.com",
]);

export function extractEmailAddress(raw: string | null | undefined): string | null {
  if (!raw) return null;
  const m = raw.match(/[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/i);
  return m ? m[0].toLowerCase() : null;
}

/// Display name from a From-style header ("Crystal Pools <x@y>" → "Crystal Pools").
export function extractDisplayName(raw: string | null | undefined): string | null {
  if (!raw) return null;
  const beforeAngle = raw.split("<")[0].trim().replace(/^"|"$/g, "").trim();
  if (beforeAngle && !beforeAngle.includes("@")) return beforeAngle;
  return null;
}

function domainOf(email: string | null): string | null {
  if (!email) return null;
  const at = email.lastIndexOf("@");
  return at > 0 ? email.substring(at + 1).toLowerCase() : null;
}

/// Website → bare domain ("https://www.greenvalley.com/about" → "greenvalley.com").
function websiteDomain(website: string | null | undefined): string | null {
  if (!website) return null;
  const cleaned = website.toLowerCase()
    .replace(/^https?:\/\//, "")
    .replace(/^www\./, "")
    .split(/[/?#]/)[0]
    .trim();
  return cleaned.includes(".") ? cleaned : null;
}

/// The process-invoice token-overlap scorer, single-sourced here, with the
/// same light stemming task-ingest uses so "Landscaping" vs "Landscape Co"
/// still overlaps. Corporate suffixes are noise, not signal.
const NAME_STOP_WORDS = new Set(["the", "and", "inc", "llc", "co", "corp", "company", "services", "service"]);

function nameTokens(name: string): Set<string> {
  const tokens = new Set<string>();
  for (const raw of name.toLowerCase().split(/[^a-z0-9]+/)) {
    if (raw.length < 3 || NAME_STOP_WORDS.has(raw)) continue;
    let t = raw;
    if (t.length > 5 && t.endsWith("ing")) t = t.slice(0, -3);
    else if (t.length > 4 && t.endsWith("ed")) t = t.slice(0, -2);
    else if (t.length > 3 && t.endsWith("s")) t = t.slice(0, -1);
    // Final-e normalization so "landscape" meets stemmed "landscaping"
    // ("landscap") and "service" meets "servicing" ("servic").
    if (t.length > 6 && t.endsWith("e")) t = t.slice(0, -1);
    tokens.add(t);
  }
  return tokens;
}

function nameScore(a: string, b: string): number {
  const la = a.toLowerCase().trim();
  const lb = b.toLowerCase().trim();
  if (!la || !lb) return 0;
  if (la === lb) return 100;
  if (la.includes(lb) || lb.includes(la)) return 60;
  const ta = nameTokens(la);
  const tb = nameTokens(lb);
  if (ta.size === 0 || tb.size === 0) return 0;
  const overlap = [...ta].filter((t) => tb.has(t)).length;
  // All of the shorter name's content tokens matching is a strong signal
  // even when one side has extra words.
  if (overlap > 0 && overlap === Math.min(ta.size, tb.size)) return 60 + overlap * 5;
  return overlap > 0 ? 30 + overlap * 10 : 0;
}

export function matchVendorBySender(args: {
  senderEmail: string | null;
  senderDisplayName?: string | null;
  contractors: VendorMatchContractor[];
}): VendorMatchResult | null {
  const email = args.senderEmail?.toLowerCase().trim() || null;
  const senderDomain = domainOf(email);

  // Tier 1 — exact email.
  if (email) {
    const hit = args.contractors.find(
      (c) => (c.email || "").toLowerCase().trim() === email,
    );
    if (hit) {
      return { contractor: hit, tier: "exact_email", confidence: "high", evidence: `sender ${email} is on file` };
    }
  }

  // Tier 2 — company domain (never freemail).
  if (senderDomain && !FREEMAIL_DOMAINS.has(senderDomain)) {
    const hit = args.contractors.find((c) =>
      domainOf((c.email || "").toLowerCase().trim() || null) === senderDomain
      || websiteDomain(c.website) === senderDomain,
    );
    if (hit) {
      return { contractor: hit, tier: "company_domain", confidence: "high", evidence: `sender domain ${senderDomain} matches ${hit.company_name}` };
    }
  }

  // Tier 3 — fuzzy display name → MEDIUM (confirm row, never silent).
  const displayName = args.senderDisplayName?.trim();
  if (displayName && displayName.length > 2) {
    let best: { c: VendorMatchContractor; score: number } | null = null;
    for (const c of args.contractors) {
      const score = nameScore(displayName, c.company_name || "");
      if (score >= 60 && (!best || score > best.score)) best = { c, score };
    }
    if (best) {
      return {
        contractor: best.c,
        tier: "fuzzy_name",
        confidence: "medium",
        evidence: `sender name "${displayName}" resembles ${best.c.company_name}`,
      };
    }
  }

  return null;
}

// lib/fit.js — deterministic vendor fit heuristic for the vendor engine.
//
// Port of admin.js computeChezVendorFit (Phase 83 cockpit): existing-network
// bonus + certification + rating tier + review volume + phone availability,
// capped to the 15-99 band. Zero AI, renders in <1ms — the ranking has to be
// stable across repaints, so nothing here may read the clock or randomness.
//
// Candidates are the merged analyze_request payload rows: existing_vendors
// (contractor rows, `_source: "existing"`), places_candidates (Google Places
// rows, `_source: "places"`), and manual adds (`_source: "manual"`).

/** 15-99 fit score. Higher = call first. */
export function computeVendorFit(v) {
  if (!v || typeof v !== "object") return 15;
  let score = 50; // baseline
  if (v._source === "existing") score += 25; // already in their network
  if (v.is_haven_certified || v.is_top_rated) score += 18;
  const rating = Number(v.rating || 0);
  if (rating >= 4.8) score += 18;
  else if (rating >= 4.5) score += 12;
  else if (rating >= 4.0) score += 6;
  const reviews = Number(v.user_ratings_total || v.review_count || 0);
  if (reviews >= 100) score += 10;
  else if (reviews >= 25) score += 6;
  else if (reviews >= 5) score += 2;
  if (v.formatted_phone_number || v.phone) score += 4;
  return Math.min(99, Math.max(15, Math.round(score)));
}

/// Calibration label so the operator reads "79" as "Strong fit" without
/// memorizing the band (ported from the cockpit's Phase 85.5 tiers).
export function fitTierLabel(fit) {
  if (fit >= 90) return "Excellent fit";
  if (fit >= 80) return "Strong fit";
  if (fit >= 70) return "Decent fit";
  if (fit >= 55) return "Possible fit";
  return "Weak fit";
}

/// Meter tone. "success" is the only loud tier (svc green); purple stays
/// reserved for CTAs and active accents per the portal discipline.
export function fitTone(fit) {
  if (fit >= 85) return "success";
  if (fit >= 70) return "warning";
  return "muted";
}

// Haven Edge Function: find-local-vendors
//
// Phase 19n: When the user taps a "Find a contractor for: X" maintenance
// task, the iOS client calls this function with (town, state, category).
// We:
//   1. Check the local_vendor_results cache for (town, state, category)
//      rows fetched in the last 30 days.
//   2. On cache miss, call Google Places Text Search to find local
//      businesses matching the category near (town, state).
//   3. Fetch Place Details (phone + website) for each candidate.
//   4. Filter into "Top-Rated" (rating >= 4.7, >= 25 reviews, no
//      chain indicators — top 2) and "Suggested" (rating >= 4.5, >= 15
//      reviews — next 2).
//   5. Cache the top 4 in local_vendor_results.
//   6. Return them ranked.
//
// Cache TTL is 30 days, refreshed lazily on the next user request after
// expiry. This catches business closures, phone number changes, rating
// drift, and new high-rated entrants within a month while staying within
// Google Maps Platform Terms of Service guidance for cached Places data.
//
// Required env vars:
//   - SUPABASE_URL
//   - SUPABASE_SERVICE_ROLE_KEY (writes to local_vendor_results)
//   - GOOGLE_PLACES_API_KEY (Places API enabled, billing on)
//
// Deploy with: supabase functions deploy find-local-vendors --no-verify-jwt

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const PLACES_TEXT_SEARCH_URL = "https://places.googleapis.com/v1/places:searchText";
const CACHE_TTL_DAYS = 30;
const MAX_RESULTS = 4;

// Categories the iOS client may pass in. Most arrive as the chip id from
// Q15b (e.g. "hvac_service", "chimney_sweep") but the find-a-contractor
// task tap can also pass the system.category directly ("HVAC", "Roofing").
// `searchTerm` is the human phrase fed into Google Places Text Search.
const CATEGORY_SEARCH_TERMS: Record<string, string> = {
  // Q15b chip ids
  hvac_service: "HVAC heating and cooling service repair",
  plumber: "plumber",
  electrician: "electrician",
  roofer: "roofer",
  septic_pumper: "septic tank pumping service",
  well_water_service: "well water pump service",
  chimney_sweep: "chimney sweep",
  tree_service: "tree service",
  handyman: "handyman",
  // home_systems.category strings (lowercased before lookup)
  hvac: "HVAC heating and cooling service repair",
  plumbing: "plumber",
  electrical: "electrician",
  roofing: "roofer",
  "septic system": "septic tank pumping service",
  "well system": "well water pump service",
  "fire protection": "chimney sweep",
  landscaping: "landscaping company",
  "pool/spa": "pool service",
  pool: "pool service",
  irrigation: "sprinkler irrigation system repair service",
  "garage door": "garage door repair",
  // Build 90: categories that were falling through to raw search
  generator: "generator repair service technician",
  "crawl space": "crawl space encapsulation service",
  // Phase X+5 (coverage push): tighter / broader hints based on the
  // post-launch-seed audit. Original "basement waterproofing service"
  // returned 0 rows everywhere; "basement waterproofing contractor"
  // matches the way the real companies (Connecticut Basement Systems,
  // American Dry Basement, B-Dry, etc.) are categorized by Places.
  // Similarly "solar panel installer", "home security installer",
  // "pest control company", "swimming pool service" are the canonical
  // labels Places actually indexes — they outperform the prior phrasing
  // by 5-10× on cell-coverage in low-density categories.
  waterproofing: "basement waterproofing contractor",
  "water heater": "water heater repair plumber",
  "siding/exterior": "siding repair contractor",
  security: "home security system installer",
  solar: "solar panel installer",
  pest_control: "pest control company",
  pool_service: "swimming pool service",
  // Phase X+4 (dedup + category-correctness): the utility-account
  // queries below previously matched gas STATIONS (Exxon/Mobil/Shell/
  // Sunoco) because "natural gas" / "oil" / "propane" are too generic.
  // Specific phrases steer Google Places toward actual utility
  // delivery companies. Even with tightening, the negative-indicator
  // list in `isCategoryPolluter` catches anything that slips through.
  trash: "trash and recycling pickup service",
  electric: "electric utility company",
  natural_gas: "natural gas utility delivery service",
  oil: "home heating oil delivery service",
  propane: "propane delivery service",
  water: "municipal water utility service",
  internet_cable: "internet service provider",
  home_insurance: "homeowners insurance agency",
  auto_insurance: "auto insurance agency",
};

// Phase X+4 (category-correctness): some Google Places results pollute
// the category they were searched under because Places' relevance algo
// matches the search verb (e.g. "natural gas" matches gas stations).
// This list of substrings disqualifies a row from being SAVED under
// a category that's prone to such pollution. The same row is still
// returned to the user for the user-facing query (we want them to see
// the gas station if they search "gas station near me" for some other
// reason) — but we don't snapshot it into the long-term catalog under
// the wrong category.
const CATEGORY_POLLUTION_BLOCKLIST: Record<string, string[]> = {
  // Gas stations + oil-change shops constantly leak into utility cats
  natural_gas: [
    "exxon", "mobil", "shell", "sunoco", "bp ", " bp", "citgo",
    "gas station", "gulf", "cumberland farms", "valvoline",
    "mavis", "midas", "jiffy lube", "jiffy-lube",
    "7-eleven", "wawa", "speedway", "quik", "quick mart",
    "marathon", "phillips 66", "lukoil",
  ],
  oil: [
    "exxon", "mobil", "shell", "sunoco", "bp ", " bp", "citgo",
    "gas station", "valvoline", "mavis", "midas", "jiffy lube",
    "jiffy-lube", "express oil", "speedee", "express lube",
    "7-eleven", "wawa", "marathon", "phillips 66",
  ],
  propane: [
    "exxon", "mobil", "shell", "sunoco", "bp ", " bp", "citgo",
    "gas station", "cumberland farms",
    "7-eleven", "wawa", "speedway", "marathon",
  ],
  electric: [
    // Generic retailers that sell electronics shouldn't surface as
    // electric utility providers.
    "best buy", "p.c. richard", "pc richard",
  ],
  internet_cable: [
    // Phone/electronics stores under "internet" are mis-routed.
    "staples", "office depot", "wirelesszone",
  ],
  water: [
    // Parks/lakes/state forests show up because "water" matches water
    // bodies. Disqualify obvious parks/recreation rows.
    "state park", "state forest", "reservation", "preserve", "pond",
    "park ", "recreation", "beach", "lake ", "river ", "spring water refill",
  ],
};

function isCategoryPolluter(category: string, name: string): boolean {
  const list = CATEGORY_POLLUTION_BLOCKLIST[category.toLowerCase()];
  if (!list) return false;
  const lower = name.toLowerCase();
  return list.some((token) => lower.includes(token));
}

// Common chain indicators we filter out of "Top-Rated". Heuristic — the
// goal is to surface local independents, not nationals. The next tier
// ("Suggested") is unfiltered so chains can still appear there.
const CHAIN_INDICATORS = [
  "servpro",
  "mr. rooter",
  "mr rooter",
  "roto-rooter",
  "roto rooter",
  "ars",
  "stanley steemer",
  "terminix",
  "orkin",
  "home depot",
  "lowe's",
  "lowes",
  "ace hardware",
  "true value",
  "best buy",
  "geek squad",
  "molly maid",
  "two men and a truck",
  "1-800-got-junk",
  "junk king",
  "the maids",
  "merry maids",
  "trugreen",
  "true green",
  "scotts",
  "weed man",
  "lawn doctor",
  "ne raymond",
  // Build 90: retailers and non-service businesses
  "p.c. richard",
  "pc richard",
  "costco",
  "walmart",
  "target",
  "sears",
  "menards",
  "tractor supply",
  "northern tool",
  "harbor freight",
  "autozone",
  "o'reilly",
  "advance auto",
  "napa auto",
  "caraluzzi",
  "shoprite",
  "stop & shop",
  "stop and shop",
  "whole foods",
  "trader joe",
];

// Build 90: Exclude results that look like retailers or food businesses
// rather than service providers. Applied to ALL results (not just Haven
// Certified) because a grocery store should never appear for irrigation.
const RETAILER_INDICATORS = [
  "market",
  "supermarket",
  "grocery",
  "deli",
  "restaurant",
  "pizza",
  "cafe",
  "bakery",
  "catering",
  "caterer",
  "food service",
  "liquor",
  "wine",
  "beer",
  "furniture",
  "mattress",
  "flooring store",
  "appliance store",
  "rental",
  "car wash",
  "gas station",
  "storage",
  "self storage",
  "u-haul",
  "salon",
  "barber",
  "spa ",
  "nail ",
  "dry clean",
  "laundromat",
];

interface VendorCandidate {
  name: string;
  address: string | null;
  phone: string | null;
  website: string | null;
  rating: number | null;
  reviewCount: number | null;
  googlePlaceId: string;
  isTopRated: boolean;
  // Phase 72: real human-verified Chez Certified badge. Only true for rows
  // sourced from vendor_applications.status='chez_certified'. Google-derived
  // rows always carry isChezCertified=false.
  isChezCertified: boolean;
  rankPosition: number;
  // Phase X feedback: rows sourced from the seeded `utility_providers`
  // catalog (15k+ providers across HVAC / plumbing / trash / insurance /
  // etc.) carry this flag so iOS can render them in a dedicated
  // "FROM YOUR AREA" section above the Google-derived tiers. Logo and
  // brand color flow through when the catalog row has them (currently
  // ~9% coverage; the rest grow lazily via the picker's on-tap fetch).
  isFromCatalog: boolean;
  logoUrl: string | null;
  brandColor: string | null;
}

// Phase X feedback: map iOS category strings → `utility_providers.provider_type`
// values so the catalog merge knows what to query. Keys are lowercased
// matches against the iOS `category` payload (which can be a chip id,
// a `home_systems.category` string, or a free-text label like
// "Trash & Recycling"). Unmapped categories simply skip the catalog
// merge and fall back to Google-only — no error path needed.
const CATEGORY_TO_PROVIDER_TYPE: Record<string, string> = {
  // Service trades — heavily seeded (~700 rows each)
  hvac: "hvac",
  hvac_service: "hvac",
  "heating and cooling": "hvac",
  plumbing: "plumbing",
  plumber: "plumbing",
  electrical: "electrical",
  electrician: "electrical",
  roofing: "roofing",
  roofer: "roofing",
  "tree service": "tree_service",
  tree_service: "tree_service",
  "garage door": "garage_door",
  garage_door: "garage_door",
  "well system": "well_water_service",
  "well water service": "well_water_service",
  well_water_service: "well_water_service",
  "septic system": "septic_pumper",
  "septic pumper": "septic_pumper",
  septic_pumper: "septic_pumper",
  chimney: "chimney_sweep",
  "chimney sweep": "chimney_sweep",
  chimney_sweep: "chimney_sweep",
  // Utility / account-style — also seeded (200+ each)
  trash: "trash",
  "trash & recycling": "trash",
  "trash and recycling": "trash",
  sanitation: "trash",
  recycling: "trash",
  water: "water",
  oil: "oil",
  "heating oil": "oil",
  electric: "electric",
  electricity: "electric",
  propane: "propane",
  internet: "internet_cable",
  "internet & cable": "internet_cable",
  "internet cable": "internet_cable",
  internet_cable: "internet_cable",
  cable: "internet_cable",
  gas: "natural_gas",
  "natural gas": "natural_gas",
  natural_gas: "natural_gas",
  // Insurance lines (estate-adjacent life_insurance removed alongside the
  // rest of the estate categories — Chez v1 doesn't surface them)
  "home insurance": "home_insurance",
  homeowners: "home_insurance",
  "homeowners insurance": "home_insurance",
  home_insurance: "home_insurance",
  "auto insurance": "auto_insurance",
  auto: "auto_insurance",
  auto_insurance: "auto_insurance",
  // Phase X+5 (audit fix): every category the seed iterates needs an
  // entry here. The find-local-vendors function uses this map to gate
  // its `utility_providers` upsert — if a category falls through with
  // an undefined providerType, the upsert is silently skipped and the
  // 60 candidates from the Places paginated fetch are returned to the
  // caller WITHOUT ever being persisted. That's why the May 2026 seed
  // produced 0 google_places rows for these categories despite ~7,000
  // Google calls hitting them. All seven added below.
  landscaping: "landscaping",
  "lawn care": "landscaping",
  "lawn service": "landscaping",
  irrigation: "irrigation",
  sprinkler: "irrigation",
  "sprinkler system": "irrigation",
  pest_control: "pest_control",
  "pest control": "pest_control",
  exterminator: "pest_control",
  pool_service: "pool_service",
  "pool service": "pool_service",
  "pool/spa": "pool_service",
  pool: "pool_service",
  spa: "pool_service",
  security: "security",
  "home security": "security",
  "security system": "security",
  alarm: "security",
  solar: "solar",
  "solar panel": "solar",
  "solar installer": "solar",
  waterproofing: "waterproofing",
  "basement waterproofing": "waterproofing",
  "foundation waterproofing": "waterproofing",
  // Niche categories that may be queried but won't seed broadly
  generator: "generator",
  "crawl space": "crawl_space",
  "water heater": "water_heater",
  "siding/exterior": "siding",
  handyman: "handyman",
};

// Phase 72: pull active vendor applications matching the (state, category)
// query, dedup against Google results, and front-load them so chez_certified
// floats to the top and live_unverified appears mixed in below the badge tier.
async function mergeVendorApplications(
  supabase: ReturnType<typeof createClient>,
  googleVendors: VendorCandidate[],
  state: string,
  rawCategory: string,
): Promise<VendorCandidate[]> {
  try {
    // Phase 72.5: also fetch profile_completion_pct so we can use it as a
    // secondary sort within each Chez tier — a 90%-complete vendor with a
    // logo, photos, and credentials beats a 14%-complete bare-bones row.
    const { data: apps, error } = await supabase
      .from("vendor_applications")
      .select("id, business_name, phone, website, linked_google_place_id, status, verified_at, profile_completion_pct")
      .ilike("category", rawCategory)
      .contains("service_area_states", [state.toUpperCase()])
      .in("status", ["chez_certified", "live_unverified"])
      .order("status", { ascending: true })
      .order("profile_completion_pct", { ascending: false, nullsFirst: false })
      .order("verified_at", { ascending: false, nullsFirst: false })
      .limit(20);

    if (error || !apps || apps.length === 0) {
      if (error) console.warn("[find-local-vendors] application merge query failed:", error);
      return googleVendors;
    }

    const linkedGoogleIds = new Set<string>(
      apps
        .map((a) => a.linked_google_place_id)
        .filter((id): id is string => typeof id === "string" && id.length > 0),
    );
    const filteredGoogle = googleVendors.filter(
      (v) => !linkedGoogleIds.has(v.googlePlaceId),
    );

    const applicationVendors: VendorCandidate[] = apps.map((app) => ({
      name: app.business_name,
      address: null,
      phone: app.phone ?? null,
      website: app.website ?? null,
      rating: null,
      reviewCount: null,
      // Use linked place_id when we have it (preserves any future Google
      // metadata we want to surface) — otherwise synthesize from app uuid
      // so iOS Identifiable conformance still works.
      googlePlaceId: app.linked_google_place_id ?? `app:${app.id}`,
      isTopRated: false,
      isChezCertified: app.status === "chez_certified",
      rankPosition: 0,
      isFromCatalog: false,
      logoUrl: null,
      brandColor: null,
    }));

    // Sort: chez_certified > live_unverified. The SQL ORDER BY already
    // puts chez_certified first AND sorts by profile_completion_pct DESC
    // within each tier, so this client-side sort just preserves that.
    // Belt-and-suspenders — if PostgREST drops the secondary sort for any
    // reason, the JS sort still keeps Certified above Live.
    applicationVendors.sort((a, b) => {
      if (a.isChezCertified !== b.isChezCertified) return a.isChezCertified ? -1 : 1;
      return 0;
    });

    // Cap merged result at 6 — applications first, then Google fills in.
    // Phase 72 review: 8 felt too long in the find-vendor sheet; 6 keeps the
    // list scannable without scrolling on most devices.
    return [...applicationVendors, ...filteredGoogle].slice(0, 6);
  } catch (err) {
    console.warn("[find-local-vendors] application merge threw:", err);
    return googleVendors;
  }
}

// Phase X feedback: pull `utility_providers` rows whose `provider_type`
// matches the iOS category (per `CATEGORY_TO_PROVIDER_TYPE`) and whose
// `regions` array overlaps the user's town or state. These are the
// 15k+ seeded providers Tom sourced for the iOS picker; surfacing them
// in "Add a Pro" closes the gap where searches for catalog vendors
// (e.g. local trash haulers, HVAC pros) found only Google Places hits.
// Dedup'd against incoming Google results by website-domain match.
// Returns up to 8 catalog rows ranked: town match first, then state-only.
async function mergeUtilityProviders(
  supabase: ReturnType<typeof createClient>,
  existingVendors: VendorCandidate[],
  town: string,
  state: string,
  normalizedCategory: string,
  searchQuery: string | null,
): Promise<VendorCandidate[]> {
  try {
    const providerType =
      CATEGORY_TO_PROVIDER_TYPE[normalizedCategory] ??
      CATEGORY_TO_PROVIDER_TYPE[normalizedCategory.toLowerCase()];
    if (!providerType) {
      // Category doesn't map to any seeded provider_type — nothing to
      // merge. Common for super-niche categories (e.g. waterproofing
      // wasn't seeded). Skip silently; Google results carry the user.
      return existingVendors;
    }

    // Query: provider_type match AND regions array overlaps with
    // [town, state]. Reads from `utility_providers_visible` so
    // single-household user_pending rows stay private until promoted.
    // When `searchQuery` is set (user typed a vendor name in find-a-pro),
    // also filter by name ILIKE — surfaces the catalog row first before
    // we ever hit Google Places for the same name.
    const stateUpper = state.toUpperCase();
    let query = supabase
      .from("utility_providers_visible")
      .select("id, name, slug, website, phone, logo_url, brand_color, regions, address, rating, review_count")
      .eq("provider_type", providerType)
      .overlaps("regions", [town, state, stateUpper])
      .limit(60);
    if (searchQuery && searchQuery.trim().length > 0) {
      // Escape % and _ characters so user input doesn't accidentally
      // become a wildcard. PostgREST passes the value straight through
      // to ILIKE.
      const escaped = searchQuery.trim().replace(/[%_]/g, "\\$&");
      query = query.ilike("name", `%${escaped}%`);
    }
    const { data: catalogRows, error } = await query;

    if (error || !catalogRows || catalogRows.length === 0) {
      if (error) console.warn("[find-local-vendors] catalog merge query failed:", error);
      return existingVendors;
    }

    // Phase X feedback (data-quality safeguard): an audit of
    // `utility_providers` found ~10,585 service-trade rows with NEITHER
    // a website NOR phone — almost certainly templated synthetic seed
    // data (pattern: "[Town] Climate Control", "[Town] Heating &
    // Cooling", etc. across alphabetical MA towns). Until those rows
    // are cleaned up, filter them out at the merge boundary so they
    // never surface to homeowners as if they were real vendors.
    // Utility-account categories (electric, trash, etc.) are nearly
    // 100% real and unaffected by this filter.
    const realCatalogRows = catalogRows.filter((row) => {
      const hasWebsite = typeof row.website === "string" && row.website.trim().length > 0;
      const hasPhone = typeof row.phone === "string" && row.phone.trim().length > 0;
      return hasWebsite || hasPhone;
    });
    if (realCatalogRows.length === 0) {
      return existingVendors;
    }

    // Dedup against incoming vendors by website-domain match. A catalog
    // row whose domain already appears in Google results would otherwise
    // double-render. Names are too noisy to dedup on (suffix variants,
    // LLC vs Inc, etc.) — domain is the stable key.
    const normalizeDomain = (url: string | null): string => {
      if (!url) return "";
      return url
        .replace(/^https?:\/\//, "")
        .replace(/^www\./, "")
        .split("/")[0]
        .toLowerCase();
    };
    const existingDomains = new Set(
      existingVendors
        .map((v) => normalizeDomain(v.website))
        .filter((d) => d.length > 0),
    );

    // Rank: town-match first (more relevant), then state-only.
    const townLower = town.toLowerCase();
    const ranked = realCatalogRows
      .filter((row) => {
        const dom = normalizeDomain(row.website);
        return dom.length === 0 || !existingDomains.has(dom);
      })
      .sort((a, b) => {
        const aTown = (a.regions ?? []).some(
          (r: string) => r.toLowerCase() === townLower,
        );
        const bTown = (b.regions ?? []).some(
          (r: string) => r.toLowerCase() === townLower,
        );
        if (aTown !== bTown) return aTown ? -1 : 1;
        // Tiebreak alphabetical so results are deterministic.
        return a.name.localeCompare(b.name);
      })
      .slice(0, 10);

    const catalogVendors: VendorCandidate[] = ranked.map((row) => ({
      name: row.name,
      // Phase X+5: catalog rows now carry rich display data backfilled
      // from local_vendor_results (cache) at upsert time and via the
      // 20261329 migration for pre-existing rows. The find-a-pro UI
      // can now render a consistent card across catalog + Google rows.
      address: row.address ?? null,
      phone: row.phone ?? null,
      website: row.website ?? null,
      rating: row.rating ?? null,
      reviewCount: row.review_count ?? null,
      // Synthesize an id from the catalog uuid so iOS Identifiable
      // conformance still works. `up:` prefix distinguishes catalog
      // rows from Google place ids and `app:` vendor_application rows.
      googlePlaceId: `up:${row.id}`,
      // Phase X+5: catalog rows with rating >= 4.7 and >= 25 reviews
      // qualify for the "Top-Rated" filter chip the same way Google
      // results do. Surfaces strong catalog vendors in the rating-
      // filter scan instead of leaving them invisible.
      isTopRated: typeof row.rating === "number" && row.rating >= 4.7 && (row.review_count ?? 0) >= 25,
      isChezCertified: false,
      rankPosition: 0,
      isFromCatalog: true,
      logoUrl: row.logo_url ?? null,
      brandColor: row.brand_color ?? null,
    }));

    // Catalog rows go FIRST in the response — they're our seeded data,
    // higher trust than raw Google results, and iOS will render them in
    // a dedicated "FROM YOUR AREA" section above the existing tiers.
    return [...catalogVendors, ...existingVendors];
  } catch (err) {
    console.warn("[find-local-vendors] catalog merge threw:", err);
    return existingVendors;
  }
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const body = await req.json().catch(() => ({}));
    const town = (body.town ?? "").toString().trim();
    const state = (body.state ?? "").toString().trim();
    const rawCategory = (body.category ?? "").toString().trim();
    // Phase X feedback: optional vendor-name filter. When set, the catalog
    // merge filters by `name ILIKE %query%` before town/state ranking, so
    // a user typing "Redding Sanitation" in find-a-pro hits the catalog
    // row directly. Empty / missing → existing top-N-by-region behavior.
    const searchQueryRaw = body.searchQuery ?? body.search_query ?? null;
    const searchQuery = typeof searchQueryRaw === "string" && searchQueryRaw.trim().length > 0
      ? searchQueryRaw.trim()
      : null;

    if (!town || !state || !rawCategory) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: town, state, category",
        }),
        { status: 400, headers }
      );
    }

    // Normalize the category to a search-term lookup. Try the exact value
    // first, then a lowercased version, then fall through to using the
    // raw input as the search term itself.
    const normalizedKey = rawCategory.toLowerCase();
    const searchTerm =
      CATEGORY_SEARCH_TERMS[rawCategory] ??
      CATEGORY_SEARCH_TERMS[normalizedKey] ??
      rawCategory;

    // Use the normalized key as the cache lookup key so different inputs
    // ("HVAC" vs "hvac" vs "hvac_service") all share the same cache row.
    const cacheCategory = normalizedKey;

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const placesApiKey = Deno.env.get("GOOGLE_PLACES_API_KEY") ?? "";

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Server misconfigured: missing Supabase env" }),
        { status: 500, headers }
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // --- CACHE CHECK ---
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - CACHE_TTL_DAYS);

    const { data: cached, error: cacheError } = await supabase
      .from("local_vendor_results")
      .select("*")
      .eq("town", town)
      .eq("state", state)
      .eq("category", cacheCategory)
      .gte("fetched_at", cutoff.toISOString())
      .order("rank_position", { ascending: true })
      .limit(MAX_RESULTS);

    if (cacheError) {
      console.warn("[find-local-vendors] cache read failed:", cacheError);
    }

    if (cached && cached.length > 0) {
      console.log(
        `[find-local-vendors] cache HIT: ${town}, ${state}, ${cacheCategory} (${cached.length} rows)`
      );
      const vendors = cached.map((row): VendorCandidate => ({
        name: row.vendor_name,
        address: row.address,
        phone: row.phone,
        website: row.website,
        rating: row.rating != null ? Number(row.rating) : null,
        reviewCount: row.review_count,
        googlePlaceId: row.google_place_id,
        isTopRated: !!row.is_top_rated,
        // Cache only stores Google-derived rows. Real Chez Certified flag is
        // overlaid from vendor_applications below.
        isChezCertified: false,
        rankPosition: row.rank_position ?? 0,
        // Catalog rows are merged fresh on every request, not cached, so
        // these default false/null here.
        isFromCatalog: false,
        logoUrl: null,
        brandColor: null,
      }));
      const merged = await mergeVendorApplications(supabase, vendors, state, rawCategory);
      // Phase X feedback: also merge the seeded `utility_providers`
      // catalog so the homeowner sees our sourced regional vendors
      // (trash haulers, HVAC pros, etc.) alongside Google results.
      // `searchQuery` filters the catalog by name when the user typed
      // one in find-a-pro.
      const withCatalog = await mergeUtilityProviders(
        supabase,
        merged,
        town,
        state,
        cacheCategory,
        searchQuery,
      );
      return new Response(
        JSON.stringify({ vendors: withCatalog, cached: true }),
        { status: 200, headers }
      );
    }

    if (!placesApiKey) {
      return new Response(
        JSON.stringify({
          error: "Server misconfigured: missing GOOGLE_PLACES_API_KEY",
        }),
        { status: 500, headers }
      );
    }

    // --- GOOGLE PLACES TEXT SEARCH (paginated) ---
    // Places API (New) supports up to 3 pages (20 results each = 60 total)
    // via `pageToken`. The first call returns up to 20 results + an optional
    // `nextPageToken`. Subsequent calls echo the same textQuery but include
    // the pageToken to fetch the next 20. Pages 2 + 3 are fetched serially
    // because the token's validity is enforced server-side and pages must
    // be requested in order.
    //
    // Phase X+3 (UX coverage push): pagination triples our catalog yield
    // per cell at no engineering cost — each (town, category) discovery
    // bumps from ~12 unique to ~30-40 unique vendors. Bulk-seed run goes
    // from $113 → ~$340 for full pagination across the launch footprint.
    const query = `${searchTerm} near ${town}, ${state}`;
    console.log(`[find-local-vendors] Places search (paginated): ${query}`);

    const fieldMask = [
      "places.id",
      "places.displayName",
      "places.formattedAddress",
      "places.rating",
      "places.userRatingCount",
      "places.internationalPhoneNumber",
      "places.nationalPhoneNumber",
      "places.websiteUri",
      "nextPageToken",
    ].join(",");

    type RawPlace = {
      id?: string;
      displayName?: { text?: string };
      formattedAddress?: string;
      rating?: number;
      userRatingCount?: number;
      internationalPhoneNumber?: string;
      nationalPhoneNumber?: string;
      websiteUri?: string;
    };

    const fetchPage = async (pageToken: string | null): Promise<{
      places: RawPlace[];
      nextPageToken: string | null;
      ok: boolean;
      status: number;
      errText?: string;
    }> => {
      const body: Record<string, unknown> = { textQuery: query, maxResultCount: 20 };
      if (pageToken) body.pageToken = pageToken;
      const res = await fetch(PLACES_TEXT_SEARCH_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": placesApiKey,
          "X-Goog-FieldMask": fieldMask,
        },
        body: JSON.stringify(body),
      });
      if (!res.ok) {
        const errText = await res.text();
        return { places: [], nextPageToken: null, ok: false, status: res.status, errText };
      }
      const data = await res.json();
      return {
        places: (data.places ?? []) as RawPlace[],
        nextPageToken: data.nextPageToken ?? null,
        ok: true,
        status: 200,
      };
    };

    const allPlaces: RawPlace[] = [];
    let pageToken: string | null = null;
    let pageCount = 0;
    const MAX_PAGES = 3;
    while (pageCount < MAX_PAGES) {
      const page = await fetchPage(pageToken);
      if (!page.ok) {
        if (pageCount === 0) {
          // First page failed — bail with an error to the client.
          console.error(
            `[find-local-vendors] Places API error on page ${pageCount + 1}: ${page.status} ${page.errText}`,
          );
          return new Response(
            JSON.stringify({ error: "Places API call failed", status: page.status }),
            { status: 502, headers },
          );
        }
        // Page 2 or 3 failure — log + use what we have so far.
        console.warn(
          `[find-local-vendors] page ${pageCount + 1} failed (${page.status}), continuing with ${allPlaces.length} results`,
        );
        break;
      }
      allPlaces.push(...page.places);
      pageCount++;
      if (!page.nextPageToken) break;
      pageToken = page.nextPageToken;
      // The pageToken needs a brief beat to become valid server-side.
      await new Promise((r) => setTimeout(r, 200));
    }
    console.log(
      `[find-local-vendors] Places pagination: ${pageCount} page(s) × ${allPlaces.length} total results`,
    );

    const rawPlaces: RawPlace[] = allPlaces;

    if (rawPlaces.length === 0) {
      console.log("[find-local-vendors] zero results from Google Places");
      return new Response(
        JSON.stringify({ vendors: [], cached: false }),
        { status: 200, headers }
      );
    }

    // Normalize, filter incomplete rows, and rank.
    type Normalized = {
      name: string;
      address: string | null;
      phone: string | null;
      website: string | null;
      rating: number;
      reviewCount: number;
      googlePlaceId: string;
    };

    const normalized: Normalized[] = rawPlaces
      .filter((p) => p.id && p.displayName?.text)
      .map((p) => ({
        name: p.displayName!.text!,
        address: p.formattedAddress ?? null,
        phone: p.nationalPhoneNumber ?? p.internationalPhoneNumber ?? null,
        website: p.websiteUri ?? null,
        rating: typeof p.rating === "number" ? p.rating : 0,
        reviewCount: typeof p.userRatingCount === "number" ? p.userRatingCount : 0,
        googlePlaceId: p.id!,
      }));

    function isChain(name: string): boolean {
      const lower = name.toLowerCase();
      return CHAIN_INDICATORS.some((token) => lower.includes(token));
    }

    function isRetailer(name: string): boolean {
      const lower = name.toLowerCase();
      return RETAILER_INDICATORS.some((token) => lower.includes(token));
    }

    // Build 90: filter out obvious non-service businesses before ranking
    const serviceProviders = normalized.filter((p) => !isRetailer(p.name) && !isChain(p.name));

    // Top-Rated candidates: 4.7+ stars, 25+ reviews, service providers only.
    // Take top 2 by rating then review count.
    const havenCertified = serviceProviders
      .filter((p) => p.rating >= 4.7 && p.reviewCount >= 25)
      .sort((a, b) => {
        if (b.rating !== a.rating) return b.rating - a.rating;
        return b.reviewCount - a.reviewCount;
      })
      .slice(0, 2);

    const havenCertifiedIds = new Set(havenCertified.map((p) => p.googlePlaceId));

    // Suggested candidates: 4.5+ stars, 15+ reviews, service providers only.
    // Skip rows already selected as Top-Rated. Take next 2.
    const suggested = serviceProviders
      .filter(
        (p) =>
          !havenCertifiedIds.has(p.googlePlaceId) &&
          p.rating >= 4.5 &&
          p.reviewCount >= 15
      )
      .sort((a, b) => {
        if (b.rating !== a.rating) return b.rating - a.rating;
        return b.reviewCount - a.reviewCount;
      })
      .slice(0, 2);

    // Build the final ranked list.
    const finalVendors: VendorCandidate[] = [];
    let rank = 1;
    for (const p of havenCertified) {
      finalVendors.push({
        name: p.name,
        address: p.address,
        phone: p.phone,
        website: p.website,
        rating: p.rating,
        reviewCount: p.reviewCount,
        googlePlaceId: p.googlePlaceId,
        isTopRated: true,
        isChezCertified: false,
        rankPosition: rank++,
        isFromCatalog: false,
        logoUrl: null,
        brandColor: null,
      });
    }
    for (const p of suggested) {
      finalVendors.push({
        name: p.name,
        address: p.address,
        phone: p.phone,
        website: p.website,
        rating: p.rating,
        reviewCount: p.reviewCount,
        googlePlaceId: p.googlePlaceId,
        isTopRated: false,
        isChezCertified: false,
        rankPosition: rank++,
        isFromCatalog: false,
        logoUrl: null,
        brandColor: null,
      });
    }

    // --- WRITE CACHE ---
    if (finalVendors.length > 0) {
      const insertRows = finalVendors.map((v) => ({
        town,
        state,
        category: cacheCategory,
        vendor_name: v.name,
        google_place_id: v.googlePlaceId,
        address: v.address,
        phone: v.phone,
        website: v.website,
        rating: v.rating,
        review_count: v.reviewCount,
        is_top_rated: v.isTopRated,
        rank_position: v.rankPosition,
      }));
      const { error: insertError } = await supabase
        .from("local_vendor_results")
        .upsert(insertRows, {
          onConflict: "town,state,category,google_place_id",
        });
      if (insertError) {
        console.warn("[find-local-vendors] cache write failed:", insertError);
      } else {
        console.log(
          `[find-local-vendors] cached ${insertRows.length} rows for ${town}, ${state}, ${cacheCategory}`
        );
      }

      // Phase X feedback: organic catalog growth. Every Google Places
      // fetch persists results to `utility_providers` as
      // `source = 'google_places'` so real user searches grow the
      // catalog over time. The bulk-seed script (Phase 3) drives this
      // same path at scale. Dedup is by `google_place_id` (UNIQUE
      // partial index).
      //
      // Phase X+2: persist ALL chain/retailer-filtered service
      // providers (not just the 4 user-facing finalVendors). Google
      // Places typically returns 15-20 candidates per query; after
      // filtering, we get 8-15 real businesses per cell. Catalog
      // growth = same number of Google API calls × ~3x more
      // discovered businesses. Per-cell upsert is capped at the top
      // 15 by (rating, review_count) so we don't blow up the table.
      const providerType =
        CATEGORY_TO_PROVIDER_TYPE[cacheCategory] ??
        CATEGORY_TO_PROVIDER_TYPE[cacheCategory.toLowerCase()];
      if (providerType) {
        const stateUpper = state.toUpperCase();

        // Catalog candidates = all serviceProviders that passed the
        // chain/retailer filter AND have at least a website or phone
        // AND aren't in the category-pollution blocklist for this
        // category. Sorted by rating + review count, capped at 15 per
        // (town, category) to keep upserts tight.
        //
        // Phase X+5: also REJECT candidates whose formatted address
        // is in a state other than the one being searched. Google
        // Places matches on name-relevance and will surface (e.g.)
        // Redding, California businesses for a "near Redding, CT"
        // query because the town name matches. Without this check
        // we snapshot CA rows tagged with CT regions and a CT user
        // typing "Redding" in find-a-pro sees California companies.
        const addressStateMatches = (address: string | null): boolean => {
          if (!address) return true;  // no address → can't reject, accept
          const m = address.match(/, ([A-Z]{2}) \d{5}/);
          if (!m) return true;  // unparseable → accept
          return m[1].toUpperCase() === stateUpper;
        };
        const catalogCandidates = serviceProviders
          .filter((p) =>
            (p.website && p.website.trim().length > 0) ||
            (p.phone && p.phone.trim().length > 0)
          )
          .filter((p) => !isCategoryPolluter(providerType, p.name))
          .filter((p) => addressStateMatches(p.address))
          .sort((a, b) => {
            if (b.rating !== a.rating) return b.rating - a.rating;
            return b.reviewCount - a.reviewCount;
          })
          .slice(0, 15);

        if (catalogCandidates.length > 0) {
          // Phase X+4: root-domain dedup. A single brand (ADT,
          // Allstate, Eversource, Optimum, Xfinity) can have many
          // Google Places listings — one per physical store / agent /
          // service area. Each has a unique google_place_id but they
          // all share a root website domain. Without dedup we end up
          // with 55 "Allstate Insurance: Cara Benjamin" rows.
          //
          // Rule: for each new candidate, compute the root domain
          // (strip subdomains, e.g. "agents.allstate.com" →
          // "allstate.com"). Look up any existing utility_providers
          // row with the same provider_type AND a website whose root
          // domain matches. If found, expand THAT row's regions
          // instead of inserting a new row. Result: one ADT, one
          // Allstate, one Eversource — each with regions covering
          // every place we've discovered them.
          const rootDomain = (url: string | null): string => {
            if (!url) return "";
            const trimmed = url
              .replace(/^https?:\/\//, "")
              .replace(/^www\./, "")
              .split("/")[0]
              .toLowerCase();
            if (!trimmed) return "";
            // Strip subdomains: keep the last two segments. Doesn't
            // handle compound TLDs (.co.uk) but US-focused launch
            // doesn't need it.
            const parts = trimmed.split(".");
            if (parts.length < 2) return trimmed;
            return parts.slice(-2).join(".");
          };

          // Build a lookup of existing rows matching by either
          // root_domain OR google_place_id (covers both cases).
          const candidateDomains = catalogCandidates
            .map((v) => rootDomain(v.website))
            .filter((d) => d.length > 0);
          const candidatePlaceIds = catalogCandidates
            .map((v) => v.googlePlaceId)
            .filter((id): id is string => typeof id === "string" && id.length > 0);

          // Domain match: pull every row in this provider_type that
          // might share a root domain. PostgREST doesn't support a
          // server-side regexp_replace, so we fetch by website-LIKE
          // pattern per candidate and dedup client-side. To keep the
          // query bounded, we batch ILIKE clauses with `or`.
          const domainFilters = candidateDomains.map(
            (d) => `website.ilike.%${d}%`,
          );
          const { data: existingByDomain } = domainFilters.length > 0
            ? await supabase
                .from("utility_providers")
                .select("id, website, regions, source, google_place_id")
                .eq("provider_type", providerType)
                .or(domainFilters.join(","))
                .limit(200)
            : { data: [] as Array<{
                id: string;
                website: string | null;
                regions: string[] | null;
                source: string | null;
                google_place_id: string | null;
              }> };

          // Index existing rows by root domain so each candidate can
          // probe in O(1). Prefer admin/vendor_application/user_verified
          // rows when multiple exist for the same domain — those are
          // the canonical home for the brand.
          const existingByRootDomain = new Map<string, {
            id: string;
            regions: string[];
            source: string | null;
          }>();
          const sourceRank = (s: string | null): number => {
            switch (s) {
              case "admin": return 0;
              case "vendor_application": return 1;
              case "user_verified": return 2;
              case "google_places": return 3;
              case "user_pending": return 4;
              default: return 5;
            }
          };
          for (const row of (existingByDomain ?? [])) {
            const d = rootDomain(row.website);
            if (!d) continue;
            const current = existingByRootDomain.get(d);
            if (!current || sourceRank(row.source) < sourceRank(current.source)) {
              existingByRootDomain.set(d, {
                id: row.id,
                regions: row.regions ?? [],
                source: row.source,
              });
            }
          }

          // Also pull by google_place_id so re-discovery of the SAME
          // Place ID merges cleanly (the existing UNIQUE constraint
          // path).
          const { data: existingByPlace } = candidatePlaceIds.length > 0
            ? await supabase
                .from("utility_providers")
                .select("id, google_place_id, regions, source")
                .in("google_place_id", candidatePlaceIds)
            : { data: [] as Array<{
                id: string;
                google_place_id: string | null;
                regions: string[] | null;
                source: string | null;
              }> };
          const existingByPlaceId = new Map<string, {
            id: string;
            regions: string[];
            source: string | null;
          }>();
          for (const row of (existingByPlace ?? [])) {
            if (!row.google_place_id) continue;
            existingByPlaceId.set(row.google_place_id, {
              id: row.id,
              regions: row.regions ?? [],
              source: row.source,
            });
          }

          // Walk candidates: each becomes either an UPDATE of an
          // existing row's regions OR a fresh INSERT.
          const newInserts: Array<{
            name: string;
            slug: string;
            provider_type: string;
            website: string | null;
            phone: string | null;
            regions: string[];
            source: string;
            google_place_id: string;
            contribution_count: number;
            address: string | null;
            rating: number | null;
            review_count: number | null;
          }> = [];
          // Phase X+5: also enrich existing rows that lack rating/
          // address — initial seed wrote them with NULLs because the
          // catalog schema didn't carry those fields. As we re-encounter
          // them in new searches we now have the data to fill in.
          const enrichmentUpdates: Map<string, {
            address: string | null;
            rating: number | null;
            review_count: number | null;
          }> = new Map();
          const regionUpdates: Map<string, Set<string>> = new Map();
          let dedupedCount = 0;
          let insertedCount = 0;

          // Phase X+5 guardrail: prevent cross-state contamination.
          // When dedup matches a candidate to an existing row via
          // root domain, only merge regions if the existing row's
          // current home-state matches this search's state (or the
          // existing row has no anchored state yet, e.g. it carries
          // only ['US'] as a national brand).
          //
          // Without this guard, a CT-based business that surfaces in
          // a MI search via name-relevance bleed gets its regions
          // expanded to include MI, even though it doesn't operate
          // there. The audit found 20 such rows tagged with all 5
          // launch states.
          const NORTHEAST_STATES = new Set([
            "CT","NY","MA","RI","MI","NH","VT","ME","NJ","PA",
          ]);
          const homeStateOf = (regions: string[]): string | null => {
            const states = regions.filter((r) => NORTHEAST_STATES.has(r));
            if (states.length === 1) return states[0];
            return null;
          };

          for (const v of catalogCandidates) {
            const placeId = v.googlePlaceId;
            if (!placeId) continue;
            const domain = rootDomain(v.website);

            // Prefer place-id match first (exact same Google listing —
            // ALWAYS merge regions, no state guard needed since it's
            // literally the same record). Fall back to domain match
            // (collapses brand shards across different listings).
            const existingByPlace = existingByPlaceId.get(placeId);
            const existingByDomainOnly = domain ? existingByRootDomain.get(domain) : undefined;
            const existing = existingByPlace ?? existingByDomainOnly;

            // Cross-state guard ONLY applies to domain-only matches
            // (different google_place_id, same brand domain). For
            // exact place_id matches we always merge — same listing
            // surfacing in two adjacent-area searches is normal for
            // genuinely multi-market operators (e.g. Connecticut
            // Basement Systems serving CT + NY). The guard prevents
            // CT-only LLCs from getting MI regions tacked on via
            // domain-relevance bleed.
            const isPlaceIdMatch = existingByPlace !== undefined;
            const existingHomeState = existing ? homeStateOf(existing.regions) : null;
            const safeToMerge = !existing
              ? false
              : isPlaceIdMatch
                ? true  // same listing — always merge
                : existingHomeState === null || existingHomeState === stateUpper;

            if (existing && safeToMerge) {
              // Expand the existing row's regions with this town/state.
              const set = regionUpdates.get(existing.id) ?? new Set(existing.regions);
              set.add(town);
              set.add(stateUpper);
              regionUpdates.set(existing.id, set);
              // Enrich the existing row with rating/address if we have
              // data and the existing row doesn't yet — handles every
              // pre-20261329 row that landed in the catalog without
              // these fields.
              if (!existing.id.startsWith("pending-")) {
                enrichmentUpdates.set(existing.id, {
                  address: v.address ?? null,
                  rating: typeof v.rating === "number" ? v.rating : null,
                  review_count: typeof v.reviewCount === "number" ? v.reviewCount : null,
                });
              }
              dedupedCount++;
            } else {
              newInserts.push({
                name: v.name,
                slug: `gp-${placeId.toLowerCase()}`,
                provider_type: providerType,
                website: v.website,
                phone: v.phone,
                regions: [town, stateUpper],
                source: "google_places",
                google_place_id: placeId,
                contribution_count: 1,
                address: v.address ?? null,
                rating: typeof v.rating === "number" ? v.rating : null,
                review_count: typeof v.reviewCount === "number" ? v.reviewCount : null,
              });
              insertedCount++;
              // Add to existingByRootDomain so subsequent candidates
              // in this same batch don't also create a new row for
              // the same domain.
              if (domain) {
                existingByRootDomain.set(domain, {
                  id: "pending-" + placeId,
                  regions: [town, stateUpper],
                  source: "google_places",
                });
              }
            }
          }

          // Apply region updates (one UPDATE per existing row).
          // Phase X+5: also fold in any enrichment data (address /
          // rating / review_count) we discovered for the existing row.
          // COALESCE pattern via raw SQL would be cleaner, but the
          // PostgREST .update() doesn't expose COALESCE; instead we
          // only patch the rich fields when the existing value is
          // NULL, which we determine via a small pre-fetch.
          if (regionUpdates.size > 0) {
            const updateIds = Array.from(regionUpdates.keys()).filter(
              (id) => !id.startsWith("pending-"),
            );
            // Pre-fetch existing rich-field values for the targets so
            // we don't overwrite better data with worse.
            const { data: currentRich } = updateIds.length > 0
              ? await supabase
                  .from("utility_providers")
                  .select("id, address, rating, review_count")
                  .in("id", updateIds)
              : { data: [] as Array<{
                  id: string;
                  address: string | null;
                  rating: number | null;
                  review_count: number | null;
                }> };
            const currentRichMap = new Map(
              (currentRich ?? []).map((r) => [r.id, r]),
            );
            for (const id of updateIds) {
              const regions = regionUpdates.get(id);
              if (!regions) continue;
              const enrich = enrichmentUpdates.get(id);
              const cur = currentRichMap.get(id);
              const patch: Record<string, unknown> = {
                regions: Array.from(regions),
              };
              if (enrich) {
                if (cur?.address == null && enrich.address != null) patch.address = enrich.address;
                if (cur?.rating == null && enrich.rating != null) patch.rating = enrich.rating;
                if (cur?.review_count == null && enrich.review_count != null) patch.review_count = enrich.review_count;
              }
              const { error: updateError } = await supabase
                .from("utility_providers")
                .update(patch)
                .eq("id", id);
              if (updateError) {
                console.warn(
                  `[find-local-vendors] region/enrich update failed for ${id}:`,
                  updateError,
                );
              }
            }
          }

          // Apply new inserts.
          if (newInserts.length > 0) {
            const { error: insertError } = await supabase
              .from("utility_providers")
              .insert(newInserts);
            if (insertError) {
              console.warn(
                "[find-local-vendors] catalog insert failed:",
                insertError,
              );
            }
          }

          console.log(
            `[find-local-vendors] catalog: ${insertedCount} new, ${dedupedCount} folded into existing rows for ${town}, ${state}, ${cacheCategory}`,
          );
        }
      }
    }

    const mergedFinal = await mergeVendorApplications(supabase, finalVendors, state, rawCategory);
    // Phase X feedback: merge the seeded `utility_providers` catalog on
    // top so iOS gets a unified list (catalog rows first, then Chez
    // Certified applications, then Top-Rated Google, then Suggested).
    // `searchQuery` filters the catalog by name when set.
    const withCatalog = await mergeUtilityProviders(
      supabase,
      mergedFinal,
      town,
      state,
      cacheCategory,
      searchQuery,
    );
    return new Response(
      JSON.stringify({ vendors: withCatalog, cached: false }),
      { status: 200, headers }
    );
  } catch (error) {
    console.error("[find-local-vendors] Error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
      { status: 500, headers }
    );
  }
});

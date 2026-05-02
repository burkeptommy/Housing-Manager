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
  "water heater": "water heater repair plumber",
  "siding/exterior": "siding repair contractor",
  security: "home security system service",
  solar: "solar panel service repair",
};

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
}

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
    const { data: apps, error } = await supabase
      .from("vendor_applications")
      .select("id, business_name, phone, website, linked_google_place_id, status, verified_at")
      .ilike("category", rawCategory)
      .contains("service_area_states", [state.toUpperCase()])
      .in("status", ["chez_certified", "live_unverified"])
      .order("status", { ascending: true })
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
    }));

    // Sort: chez_certified > live_unverified, preserves the verified_at
    // ordering from the SQL query inside each tier.
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
      }));
      const merged = await mergeVendorApplications(supabase, vendors, state, rawCategory);
      return new Response(
        JSON.stringify({ vendors: merged, cached: true }),
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

    // --- GOOGLE PLACES TEXT SEARCH ---
    // Places API (New) uses a single searchText endpoint with field masks.
    // We ask for displayName, formattedAddress, rating, userRatingCount,
    // internationalPhoneNumber, websiteUri, and id in one round trip — no
    // separate Place Details call needed.
    const query = `${searchTerm} near ${town}, ${state}`;
    console.log(`[find-local-vendors] Places search: ${query}`);

    const fieldMask = [
      "places.id",
      "places.displayName",
      "places.formattedAddress",
      "places.rating",
      "places.userRatingCount",
      "places.internationalPhoneNumber",
      "places.nationalPhoneNumber",
      "places.websiteUri",
    ].join(",");

    const placesResponse = await fetch(PLACES_TEXT_SEARCH_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": placesApiKey,
        "X-Goog-FieldMask": fieldMask,
      },
      body: JSON.stringify({
        textQuery: query,
        maxResultCount: 20,
      }),
    });

    if (!placesResponse.ok) {
      const errText = await placesResponse.text();
      console.error("[find-local-vendors] Places API error:", placesResponse.status, errText);
      return new Response(
        JSON.stringify({ error: "Places API call failed", status: placesResponse.status }),
        { status: 502, headers }
      );
    }

    const placesData = await placesResponse.json();
    const rawPlaces: Array<{
      id?: string;
      displayName?: { text?: string };
      formattedAddress?: string;
      rating?: number;
      userRatingCount?: number;
      internationalPhoneNumber?: string;
      nationalPhoneNumber?: string;
      websiteUri?: string;
    }> = placesData.places ?? [];

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
    }

    const mergedFinal = await mergeVendorApplications(supabase, finalVendors, state, rawCategory);
    return new Response(
      JSON.stringify({ vendors: mergedFinal, cached: false }),
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

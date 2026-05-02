// Haven Edge Function: find-local-advisors
//
// When the user taps "Find an estate attorney" (or CPA, financial advisor,
// life insurance agent) on the Life tab, the iOS client calls this function
// with (town, state, advisorType). We:
//   1. Check the local_vendor_results cache for matching rows fetched in
//      the last 30 days (reuses the same cache table as find-local-vendors).
//   2. On cache miss, call Google Places Text Search to find local
//      professionals matching the advisor type near (town, state).
//   3. Filter into "Top-Rated" (rating >= 4.8, >= 10 reviews, no
//      chain indicators — top 2) and "Suggested" (rating >= 4.5, >= 5
//      reviews — next 5). Softer thresholds than vendors because professional
//      services typically have fewer reviews.
//   4. Cache the top 4 in local_vendor_results.
//   5. Return them ranked.
//
// Required env vars:
//   - SUPABASE_URL
//   - SUPABASE_SERVICE_ROLE_KEY (writes to local_vendor_results)
//   - GOOGLE_PLACES_API_KEY (Places API enabled, billing on)
//
// Deploy with: supabase functions deploy find-local-advisors --no-verify-jwt

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
// Build 90: bumped from 4 to 7 so the sheet shows 2 Top-Rated + 5
// Suggested, giving users a meaningful list of local options.
const MAX_RESULTS = 7;

// Advisor types the iOS client passes in, mapped to Google Places search terms.
const ADVISOR_SEARCH_TERMS: Record<string, string> = {
  estate_attorney: "estate planning attorney",
  cpa_tax: "CPA accountant tax advisor",
  financial_advisor: "financial advisor wealth management",
  life_insurance: "life insurance agent",
};

// Chain indicators filtered out of "Top-Rated" tier for professional
// advisors. The goal is to surface local independents and boutique firms
// over national chains. Chains can still appear in the "Suggested" tier.
const CHAIN_INDICATORS = [
  "h&r block",
  "hr block",
  "jackson hewitt",
  "liberty tax",
  "turbotax",
  "edward jones",
  "ameriprise",
  "primerica",
  "northwestern mutual",
  "mass mutual",
  "massmutual",
  "new york life",
  "prudential",
  "allstate",
  "state farm",
  "farmers insurance",
  "geico",
  "progressive",
  "nationwide",
];

interface AdvisorCandidate {
  name: string;
  address: string | null;
  phone: string | null;
  website: string | null;
  rating: number | null;
  reviewCount: number | null;
  googlePlaceId: string;
  isTopRated: boolean;
  // Phase 72: real human-verified Chez Certified badge. Only true for rows
  // sourced from vendor_applications.status='chez_certified'.
  isChezCertified: boolean;
  rankPosition: number;
}

// Phase 72: pull active vendor applications matching the (state, category)
// query and front-load them so chez_certified floats above Google results.
async function mergeAdvisorApplications(
  supabase: ReturnType<typeof createClient>,
  googleAdvisors: AdvisorCandidate[],
  state: string,
  rawCategory: string,
): Promise<AdvisorCandidate[]> {
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
      if (error) console.warn("[find-local-advisors] application merge query failed:", error);
      return googleAdvisors;
    }

    const linkedGoogleIds = new Set<string>(
      apps
        .map((a) => a.linked_google_place_id)
        .filter((id): id is string => typeof id === "string" && id.length > 0),
    );
    const filteredGoogle = googleAdvisors.filter(
      (v) => !linkedGoogleIds.has(v.googlePlaceId),
    );

    const applicationAdvisors: AdvisorCandidate[] = apps.map((app) => ({
      name: app.business_name,
      address: null,
      phone: app.phone ?? null,
      website: app.website ?? null,
      rating: null,
      reviewCount: null,
      googlePlaceId: app.linked_google_place_id ?? `app:${app.id}`,
      isTopRated: false,
      isChezCertified: app.status === "chez_certified",
      rankPosition: 0,
    }));

    applicationAdvisors.sort((a, b) => {
      if (a.isChezCertified !== b.isChezCertified) return a.isChezCertified ? -1 : 1;
      return 0;
    });

    return [...applicationAdvisors, ...filteredGoogle].slice(0, 6);
  } catch (err) {
    console.warn("[find-local-advisors] application merge threw:", err);
    return googleAdvisors;
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
    const rawAdvisorType = (body.category ?? "").toString().trim();

    if (!town || !state || !rawAdvisorType) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: town, state, category",
        }),
        { status: 400, headers }
      );
    }

    const normalizedKey = rawAdvisorType.toLowerCase();
    const searchTerm =
      ADVISOR_SEARCH_TERMS[rawAdvisorType] ??
      ADVISOR_SEARCH_TERMS[normalizedKey] ??
      rawAdvisorType;

    // Cache key uses the normalized advisor type so lookups are stable.
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
      console.warn("[find-local-advisors] cache read failed:", cacheError);
    }

    if (cached && cached.length > 0) {
      console.log(
        `[find-local-advisors] cache HIT: ${town}, ${state}, ${cacheCategory} (${cached.length} rows)`
      );
      const vendors = cached.map((row): AdvisorCandidate => ({
        name: row.vendor_name,
        address: row.address,
        phone: row.phone,
        website: row.website,
        rating: row.rating != null ? Number(row.rating) : null,
        reviewCount: row.review_count,
        googlePlaceId: row.google_place_id,
        isTopRated: !!row.is_top_rated,
        isChezCertified: false,
        rankPosition: row.rank_position ?? 0,
      }));
      const merged = await mergeAdvisorApplications(supabase, vendors, state, rawAdvisorType);
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
    const query = `${searchTerm} near ${town}, ${state}`;
    console.log(`[find-local-advisors] Places search: ${query}`);

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
      console.error("[find-local-advisors] Places API error:", placesResponse.status, errText);
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
      console.log("[find-local-advisors] zero results from Google Places");
      return new Response(
        JSON.stringify({ vendors: [], cached: false }),
        { status: 200, headers }
      );
    }

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

    // Top-Rated: 4.8+ stars, 10+ reviews, not a chain.
    // Softer thresholds than vendors — professional services get fewer reviews.
    const havenCertified = normalized
      .filter((p) => p.rating >= 4.8 && p.reviewCount >= 10 && !isChain(p.name))
      .sort((a, b) => {
        if (b.rating !== a.rating) return b.rating - a.rating;
        return b.reviewCount - a.reviewCount;
      })
      .slice(0, 2);

    const havenCertifiedIds = new Set(havenCertified.map((p) => p.googlePlaceId));

    // Suggested: 4.5+ stars, 5+ reviews. No chain filter.
    // Build 90: bumped from 2 to 5 so users see a meaningful list.
    const suggested = normalized
      .filter(
        (p) =>
          !havenCertifiedIds.has(p.googlePlaceId) &&
          p.rating >= 4.5 &&
          p.reviewCount >= 5
      )
      .sort((a, b) => {
        if (b.rating !== a.rating) return b.rating - a.rating;
        return b.reviewCount - a.reviewCount;
      })
      .slice(0, 5);

    const finalAdvisors: AdvisorCandidate[] = [];
    let rank = 1;
    for (const p of havenCertified) {
      finalAdvisors.push({
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
      finalAdvisors.push({
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
    if (finalAdvisors.length > 0) {
      const insertRows = finalAdvisors.map((v) => ({
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
        console.warn("[find-local-advisors] cache write failed:", insertError);
      } else {
        console.log(
          `[find-local-advisors] cached ${insertRows.length} rows for ${town}, ${state}, ${cacheCategory}`
        );
      }
    }

    const mergedFinal = await mergeAdvisorApplications(supabase, finalAdvisors, state, rawAdvisorType);
    return new Response(
      JSON.stringify({ vendors: mergedFinal, cached: false }),
      { status: 200, headers }
    );
  } catch (error) {
    console.error("[find-local-advisors] Error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
      { status: 500, headers }
    );
  }
});

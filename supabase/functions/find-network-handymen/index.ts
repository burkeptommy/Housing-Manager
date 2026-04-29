// Chez v1: find-network-handymen
//
// Public-friendly Edge Function for the homeowner-side find-a-handyman
// flow. Homeowners can't see `provider_workspaces` directly (RLS locks
// it down to workspace members), so this function uses service-role to
// query directory-listed workspaces and return a sanitized public shape
// that the iOS `FindLocalVendorSheet` and `ChezDirectorySearchView` can
// render alongside Google Places results.
//
// Contract:
//   POST {
//     town?: string,
//     state?: string,
//     zip?: string,
//     category?: string,
//     searchQuery?: string,   // when present → directory-search mode
//     nationwide?: boolean,   // drops the state filter when true
//   }
//   →    { providers: ChezFieldProvider[] }
//
// Two modes of operation:
//
//   "near_me" (default — searchQuery absent or empty):
//     1. `is_listed_in_directory = true`        (provider opt-in)
//     2. `categories @> [category]`             (e.g. ["handyman"])
//     3. `service_state ILIKE state`            (unless nationwide=true)
//     4. If `service_zip_codes` is non-empty, require zip-prefix-3 OR city
//        match; else drop from results.
//     Cap: 5.
//
//   "directory_search" (searchQuery present, even if empty after trim → still
//    qualifies as browsing intent when explicitly sent):
//     - Same filters 1-3 as near_me. Filter 4 (zip/city) is SKIPPED — the
//       homeowner is actively browsing, not auto-matching.
//     - When the query is non-empty, an ILIKE filter is added across
//       `company_name` and `display_blurb`.
//     - Cap: 25.
//
// Sort (both modes): `aggregate_rating DESC NULLS LAST`.
//
// Required env vars:
//   - SUPABASE_URL
//   - SUPABASE_SERVICE_ROLE_KEY
//
// Deploy with: supabase functions deploy find-network-handymen --no-verify-jwt

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const NEAR_ME_LIMIT = 5;
const DIRECTORY_SEARCH_LIMIT = 25;

interface RequestBody {
  town?: string;
  state?: string;
  zip?: string;
  category?: string;
  searchQuery?: string;
  nationwide?: boolean;
}

interface ProviderRow {
  id: string;
  company_name: string;
  primary_phone: string | null;
  website: string | null;
  service_city: string | null;
  service_state: string | null;
  service_zip_codes: string[] | null;
  categories: string[] | null;
  display_blurb: string | null;
  headshot_url: string | null;
  aggregate_rating: number | null;
  review_count: number | null;
}

interface ChezFieldProvider {
  id: string;
  workspaceId: string;
  name: string;
  phone: string | null;
  website: string | null;
  city: string | null;
  state: string | null;
  blurb: string | null;
  headshotUrl: string | null;
  rating: number | null;
  reviewCount: number;
  categories: string[];
  source: "chez_field";
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ providers: [] }, 405);
  }

  try {
    const body: RequestBody = await req.json().catch(() => ({}));
    const town = compact(body.town);
    const state = compact(body.state);
    const zip = compact(body.zip);
    const category = (compact(body.category) || "handyman").toLowerCase();
    const searchQuery = compact(body.searchQuery);
    const nationwide = body.nationwide === true;

    // Directory-search mode is triggered when the caller explicitly sends a
    // searchQuery field (the iOS browse view always sends one — empty string
    // for the initial unfiltered list, then the typed value once the user
    // searches). Auto-match callers omit the field and stay in near_me mode.
    const isDirectorySearch = body.searchQuery !== undefined;
    const limit = isDirectorySearch ? DIRECTORY_SEARCH_LIMIT : NEAR_ME_LIMIT;

    // State is required for near_me; directory-search allows nationwide.
    if (!state && !nationwide) {
      return jsonResponse({ providers: [] });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    let query = supabase
      .from("provider_workspaces")
      .select(
        `
          id,
          company_name,
          primary_phone,
          website,
          service_city,
          service_state,
          service_zip_codes,
          categories,
          display_blurb,
          headshot_url,
          aggregate_rating,
          review_count
        `,
      )
      .eq("is_listed_in_directory", true)
      .contains("categories", [category]);

    if (state && !nationwide) {
      query = query.ilike("service_state", state);
    }

    if (searchQuery) {
      // Postgrest .or() with ilike across two columns. Escape commas/parens
      // in user input so the value can't break out of the .or() expression.
      const safeQuery = searchQuery.replace(/[(),]/g, " ").trim();
      if (safeQuery) {
        const wildcard = `%${safeQuery}%`;
        query = query.or(
          `company_name.ilike.${wildcard},display_blurb.ilike.${wildcard}`,
        );
      }
    }

    const { data, error } = await query;

    if (error) {
      console.error("[find-network-handymen] query failed", error);
      return jsonResponse({ providers: [] });
    }

    // Skip the zip/city filter in directory-search mode — the homeowner is
    // actively browsing the directory, not auto-matching nearby pros.
    const filtered = isDirectorySearch
      ? (data ?? [])
      : (data ?? []).filter((row: ProviderRow) => {
        const zips = row.service_zip_codes ?? [];

        // If the provider has populated zip codes, require either a
        // zip-prefix match or a city match. Without either we treat
        // the provider as "not actually serving this homeowner" even
        // though they're in the same state.
        if (zips.length > 0) {
          const matchedZip = zip
            ? zips.some((z) => z.startsWith(zip.slice(0, 3)))
            : false;
          const matchedCity = town && row.service_city
            ? row.service_city.toLowerCase() === town.toLowerCase()
            : false;
          return matchedZip || matchedCity;
        }

        // No zip data → state-level match (already applied) is enough.
        return true;
      });

    const providers: ChezFieldProvider[] = filtered
      .sort((a: ProviderRow, b: ProviderRow) => {
        const aRating = a.aggregate_rating ?? -1;
        const bRating = b.aggregate_rating ?? -1;
        return bRating - aRating;
      })
      .slice(0, limit)
      .map((row: ProviderRow) => ({
        id: `chez_field_${row.id}`,
        workspaceId: row.id,
        name: row.company_name,
        phone: row.primary_phone,
        website: row.website,
        city: row.service_city,
        state: row.service_state,
        blurb: row.display_blurb,
        headshotUrl: row.headshot_url,
        rating: row.aggregate_rating,
        reviewCount: row.review_count ?? 0,
        categories: row.categories ?? [],
        source: "chez_field",
      }));

    return jsonResponse({ providers });
  } catch (error) {
    console.error("[find-network-handymen] unhandled", error);
    return jsonResponse({ providers: [] }, 500);
  }
});

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function compact(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

// Haven Edge Function: lookup-manual
// On-demand equipment manual lookup. Given a model number, brand name,
// or search query, finds the matching catalog entry and returns:
//   1. A direct PDF URL (if we have one cached in storage)
//   2. The manufacturer's support portal URL for that model
//   3. Equipment details (specs, common issues, maintenance schedule)
//
// If a cached PDF exists in our storage bucket, returns a signed URL.
// If not, returns the manufacturer's support portal deep link.
//
// Also used by Alfred chat to enrich responses about equipment.
//
// Usage:
//   POST /functions/v1/lookup-manual
//   Body: { "model_number": "K-3999" }
//   Body: { "query": "Kohler toilet" }
//   Body: { "brand": "carrier", "category": "furnace" }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { authFailure, requireHousehold } from "../_shared/require-household.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json().catch(() => ({}));
    const modelNumber: string | null = body.model_number ?? null;
    const query: string | null = body.query ?? null;
    const brand: string | null = body.brand ?? null;
    const category: string | null = body.category ?? null;
    const householdSystemId: string | null = body.home_system_id ?? null;

    // July 2026 security sweep (audit S1): the home_system_id branch reads
    // AND updates the row (catalog link-back), so the caller must own it.
    // Pure catalog searches (no system id) stay open — public catalog data.
    if (householdSystemId) {
      const corsJson = { ...corsHeaders, "Content-Type": "application/json" };
      const auth = await requireHousehold(req);
      if ("failure" in auth) return authFailure(auth, corsJson);
      const { data: owned } = await supabase
        .from("home_systems").select("household_id").eq("id", householdSystemId).single();
      if (!owned || owned.household_id !== auth.householdId) {
        return new Response(
          JSON.stringify({ error: "Access denied: system does not belong to your household" }),
          { status: 403, headers: corsJson },
        );
      }
    }

    // === Strategy 1: Lookup by home_system_id (user's actual equipment) ===
    if (householdSystemId) {
      const { data: system } = await supabase
        .from("home_systems")
        .select("*, catalog_entry_id")
        .eq("id", householdSystemId)
        .single();

      if (system?.catalog_entry_id) {
        return await respondWithCatalogEntry(supabase, supabaseUrl, system.catalog_entry_id, system);
      }

      // If no catalog link, try to match by model number stored on the system
      if (system?.model_number) {
        const match = await findByModelNumber(supabase, system.model_number);
        if (match) {
          // Link the home_system to the catalog entry for future lookups
          await supabase
            .from("home_systems")
            .update({ catalog_entry_id: match.id })
            .eq("id", householdSystemId);

          return await respondWithCatalogEntry(supabase, supabaseUrl, match.id, system);
        }
      }

      return new Response(
        JSON.stringify({
          found: false,
          system,
          suggestion: "No matching catalog entry found. Try searching by model number.",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // === Strategy 2: Lookup by exact model number ===
    if (modelNumber) {
      const match = await findByModelNumber(supabase, modelNumber);
      if (match) {
        return await respondWithCatalogEntry(supabase, supabaseUrl, match.id);
      }
    }

    // === Strategy 3: Full-text search ===
    const searchTerm = query ?? [brand, category].filter(Boolean).join(" ");
    if (searchTerm) {
      // Use the GIN full-text search index
      const tsQuery = searchTerm
        .split(/\s+/)
        .filter((w) => w.length > 1)
        .join(" & ");

      const { data: searchResults } = await supabase
        .from("equipment_catalog")
        .select(`
          id, model_number, model_name, series,
          fuel_type, installation_type, capacity_value, capacity_unit,
          msrp_usd, expected_lifespan_years, key_features, specs,
          product_url,
          equipment_manufacturers!inner (name, slug, support_url, support_phone, tier),
          equipment_categories!inner (name, slug, room)
        `)
        .textSearch(
          "model_number",
          tsQuery,
          { type: "websearch" }
        )
        .limit(10);

      // Fallback: ilike search if full-text didn't match
      let results = searchResults;
      if (!results || results.length === 0) {
        const { data: ilikeResults } = await supabase
          .from("equipment_catalog")
          .select(`
            id, model_number, model_name, series,
            fuel_type, installation_type, capacity_value, capacity_unit,
            msrp_usd, expected_lifespan_years, key_features, specs,
            product_url,
            equipment_manufacturers!inner (name, slug, support_url, support_phone, tier),
            equipment_categories!inner (name, slug, room)
          `)
          .or(
            `model_number.ilike.%${searchTerm}%,model_name.ilike.%${searchTerm}%,series.ilike.%${searchTerm}%`
          )
          .limit(10);
        results = ilikeResults;
      }

      // If searching by brand, also try manufacturer name match
      if ((!results || results.length === 0) && brand) {
        const { data: brandResults } = await supabase
          .from("equipment_catalog")
          .select(`
            id, model_number, model_name, series,
            fuel_type, installation_type, capacity_value, capacity_unit,
            msrp_usd, expected_lifespan_years, key_features, specs,
            product_url,
            equipment_manufacturers!inner (name, slug, support_url, support_phone, tier),
            equipment_categories!inner (name, slug, room)
          `)
          .ilike("equipment_manufacturers.name", `%${brand}%`)
          .limit(20);

        if (brandResults && category) {
          results = brandResults.filter((r: any) =>
            r.equipment_categories.name.toLowerCase().includes(category.toLowerCase())
          );
        } else {
          results = brandResults;
        }
      }

      if (results && results.length > 0) {
        // If single result, return full details with manuals
        if (results.length === 1) {
          return await respondWithCatalogEntry(supabase, supabaseUrl, results[0].id);
        }

        // Multiple results — return summary list
        return new Response(
          JSON.stringify({
            found: true,
            count: results.length,
            results: results.map((r: any) => ({
              id: r.id,
              model_number: r.model_number,
              model_name: r.model_name,
              manufacturer: r.equipment_manufacturers?.name,
              category: r.equipment_categories?.name,
              series: r.series,
              msrp: r.msrp_usd,
            })),
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    return new Response(
      JSON.stringify({
        found: false,
        suggestion:
          "No matching equipment found. Try a model number, brand name, or product description.",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({
        error: err instanceof Error ? err.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

// Find a catalog entry by model number (exact or prefix match)
async function findByModelNumber(supabase: any, modelNumber: string) {
  // Try exact match first
  let { data } = await supabase
    .from("equipment_catalog")
    .select("id, model_number")
    .eq("model_number", modelNumber)
    .limit(1)
    .single();

  if (data) return data;

  // Try prefix match (e.g., "K-3999" matches "K-3999-RA")
  const { data: prefixMatch } = await supabase
    .from("equipment_catalog")
    .select("id, model_number")
    .ilike("model_number", `${modelNumber}%`)
    .limit(1)
    .single();

  return prefixMatch;
}

// Build full response with catalog entry, manuals, issues, and schedules
async function respondWithCatalogEntry(
  supabase: any,
  supabaseUrl: string,
  catalogEntryId: string,
  homeSystem?: any
) {
  // Fetch catalog entry with all relations
  const { data: entry } = await supabase
    .from("equipment_catalog")
    .select(`
      *,
      equipment_manufacturers!inner (name, slug, support_url, support_phone, website_url, tier, parent_company),
      equipment_categories!inner (name, slug, room, typical_lifespan_years, description)
    `)
    .eq("id", catalogEntryId)
    .single();

  if (!entry) {
    return new Response(
      JSON.stringify({ found: false }),
      { headers: { "Content-Type": "application/json" } }
    );
  }

  // Fetch manuals
  const { data: manuals } = await supabase
    .from("equipment_manuals")
    .select("*")
    .eq("catalog_entry_id", catalogEntryId);

  // Build manual URLs — prefer cached PDFs, fall back to source URLs
  const manualLinks: Record<string, { url: string; cached: boolean; size_kb?: number }> = {};

  for (const manual of manuals ?? []) {
    if (manual.file_size_bytes && manual.file_size_bytes > 0 && manual.file_path) {
      // We have the PDF cached — generate a signed URL
      const { data: signedUrl } = await supabase.storage
        .from("equipment-manuals")
        .createSignedUrl(manual.file_path, 3600); // 1 hour expiry

      manualLinks[manual.manual_type] = {
        url: signedUrl?.signedUrl ?? manual.source_url,
        cached: true,
        size_kb: Math.round(manual.file_size_bytes / 1024),
      };
    } else {
      manualLinks[manual.manual_type] = {
        url: manual.source_url,
        cached: false,
      };
    }
  }

  // Fetch common issues for this model or category
  const { data: issues } = await supabase
    .from("equipment_common_issues")
    .select("*")
    .or(`catalog_entry_id.eq.${catalogEntryId},category_id.eq.${entry.category_id}`)
    .limit(10);

  // Fetch service schedules for this model or category
  const { data: schedules } = await supabase
    .from("equipment_service_schedules")
    .select("*")
    .or(`catalog_entry_id.eq.${catalogEntryId},category_id.eq.${entry.category_id}`)
    .limit(10);

  const manufacturer = entry.equipment_manufacturers;
  const category = entry.equipment_categories;

  return new Response(
    JSON.stringify({
      found: true,
      equipment: {
        model_number: entry.model_number,
        model_name: entry.model_name,
        series: entry.series,
        manufacturer: manufacturer.name,
        manufacturer_tier: manufacturer.tier,
        parent_company: manufacturer.parent_company,
        category: category.name,
        room: category.room,
        fuel_type: entry.fuel_type,
        installation_type: entry.installation_type,
        capacity: entry.capacity_value
          ? `${entry.capacity_value} ${entry.capacity_unit}`
          : null,
        msrp: entry.msrp_usd,
        expected_lifespan_years: entry.expected_lifespan_years,
        is_current_model: entry.is_current_model,
        key_features: entry.key_features,
        specs: entry.specs,
        product_url: entry.product_url,
      },
      support: {
        phone: manufacturer.support_phone,
        website: manufacturer.support_url ?? manufacturer.website_url,
      },
      manuals: manualLinks,
      common_issues: (issues ?? []).map((i: any) => ({
        title: i.issue_title,
        description: i.description,
        symptoms: i.symptoms,
        typical_fix: i.typical_fix,
        diy_difficulty: i.diy_difficulty,
        estimated_cost: i.estimated_repair_cost_low && i.estimated_repair_cost_high
          ? `$${i.estimated_repair_cost_low}-$${i.estimated_repair_cost_high}`
          : null,
        typical_occurrence_years: i.typical_occurrence_years,
        parts_needed: i.parts_needed,
      })),
      maintenance_schedule: (schedules ?? []).map((s: any) => ({
        task: s.task_name,
        description: s.description,
        frequency_months: s.frequency_months,
        estimated_cost: s.estimated_cost,
        diy_possible: s.diy_possible,
        professional_recommended: s.professional_recommended,
        parts_needed: s.parts_needed,
      })),
      home_system: homeSystem ?? null,
    }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
}

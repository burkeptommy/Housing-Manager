// Haven Edge Function: property-lookup
// Looks up property data from RentCast API given an address.
// Returns: yearBuilt, sqft, beds, baths, propertyType, features, estimated value.
// Used during onboarding to instantly populate a property profile.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const RENTCAST_BASE = "https://api.rentcast.io/v1";

interface PropertyResult {
  yearBuilt: number | null;
  squareFootage: number | null;
  lotSize: number | null;
  bedrooms: number | null;
  bathrooms: number | null;
  propertyType: string | null;
  lastSaleDate: string | null;
  lastSalePrice: number | null;
  estimatedValue: number | null;
  estimatedValueLow: number | null;
  estimatedValueHigh: number | null;
  features: {
    roofType: string | null;
    heatingType: string | null;
    heatingFuel: string | null;
    coolingType: string | null;
    foundationType: string | null;
    exteriorType: string | null;
    architectureType: string | null;
    pool: boolean;
    poolType: string | null;
    garage: boolean;
    garageType: string | null;
    garageSpaces: number | null;
    stories: number | null;
    fireplace: boolean;
    fireplaceType: string | null;
  };
  taxAssessment: {
    year: number | null;
    value: number | null;
  } | null;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const rentcastKey = Deno.env.get("RENTCAST_API_KEY");
    if (!rentcastKey) {
      return new Response(
        JSON.stringify({ error: "RENTCAST_API_KEY not set" }),
        { status: 500, headers }
      );
    }

    const body = await req.json();
    const { address } = body;

    if (!address || typeof address !== "string" || address.trim().length < 5) {
      return new Response(
        JSON.stringify({ error: "Valid address string required" }),
        { status: 400, headers }
      );
    }

    const trimmedAddress = address.trim();
    console.log(`[property-lookup] Looking up: ${trimmedAddress}`);

    // --- CHECK CACHE ---
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    let supabase: ReturnType<typeof createClient> | null = null;

    if (supabaseUrl && serviceRoleKey) {
      supabase = createClient(supabaseUrl, serviceRoleKey);

      // Simple hash for cache key: lowercase, strip extra spaces
      const addressHash = trimmedAddress.toLowerCase().replace(/\s+/g, " ");

      const { data: cached } = await supabase
        .from("property_lookups")
        .select("lookup_data")
        .eq("address_hash", addressHash)
        .single();

      if (cached?.lookup_data) {
        console.log("[property-lookup] Cache hit");
        return new Response(
          JSON.stringify({ success: true, property: cached.lookup_data, cached: true }),
          { status: 200, headers }
        );
      }
    }

    // --- CALL RENTCAST (two endpoints in parallel) ---
    const encoded = encodeURIComponent(trimmedAddress);
    const rentcastHeaders = {
      Accept: "application/json",
      "X-Api-Key": rentcastKey,
    };

    const [propertyRes, avmRes] = await Promise.allSettled([
      fetch(`${RENTCAST_BASE}/properties?address=${encoded}`, {
        headers: rentcastHeaders,
      }),
      fetch(`${RENTCAST_BASE}/avm/value?address=${encoded}`, {
        headers: rentcastHeaders,
      }),
    ]);

    // --- PARSE PROPERTY DATA ---
    let propertyData: Record<string, unknown> | null = null;

    if (propertyRes.status === "fulfilled" && propertyRes.value.ok) {
      const propJson = await propertyRes.value.json();
      // RentCast returns an array; take first result
      if (Array.isArray(propJson) && propJson.length > 0) {
        propertyData = propJson[0];
      } else if (!Array.isArray(propJson) && propJson.id) {
        propertyData = propJson;
      }
    } else {
      const reason =
        propertyRes.status === "rejected"
          ? propertyRes.reason
          : `HTTP ${propertyRes.value.status}`;
      console.error(`[property-lookup] Property API failed: ${reason}`);
    }

    // --- PARSE AVM DATA ---
    let avmData: Record<string, unknown> | null = null;

    if (avmRes.status === "fulfilled" && avmRes.value.ok) {
      const avmJson = await avmRes.value.json();
      avmData = avmJson;
    } else {
      const reason =
        avmRes.status === "rejected"
          ? avmRes.reason
          : `HTTP ${avmRes.value.status}`;
      console.error(`[property-lookup] AVM API failed: ${reason}`);
    }

    // --- NEITHER RETURNED DATA ---
    if (!propertyData && !avmData) {
      console.log("[property-lookup] No data found for address");
      return new Response(
        JSON.stringify({ success: false, error: "not_found" }),
        { status: 200, headers }
      );
    }

    // --- MERGE INTO UNIFIED RESPONSE ---
    const features = (propertyData?.features as Record<string, unknown>) ?? {};

    const result: PropertyResult = {
      yearBuilt: (propertyData?.yearBuilt as number) ?? null,
      squareFootage: (propertyData?.squareFootage as number) ?? null,
      lotSize: (propertyData?.lotSize as number) ?? null,
      bedrooms: (propertyData?.bedrooms as number) ?? null,
      bathrooms: (propertyData?.bathrooms as number) ?? null,
      propertyType: (propertyData?.propertyType as string) ?? null,
      lastSaleDate: (propertyData?.lastSaleDate as string) ?? null,
      lastSalePrice: (propertyData?.lastSalePrice as number) ?? null,
      estimatedValue: (avmData?.price as number) ?? (avmData?.value as number) ?? null,
      estimatedValueLow: (avmData?.priceLow as number) ?? (avmData?.valueLow as number) ?? null,
      estimatedValueHigh: (avmData?.priceHigh as number) ?? (avmData?.valueHigh as number) ?? null,
      features: {
        roofType: (features.roofType as string) ?? (features.roofCover as string) ?? (features.roofMaterial as string) ?? null,
        heatingType: (features.heatingType as string) ?? (features.heating as string) ?? null,
        heatingFuel: (features.heatingFuel as string) ?? (features.heatingFuelType as string) ?? null,
        coolingType: (features.coolingType as string) ?? (features.cooling as string) ?? (features.airConditioningType as string) ?? null,
        foundationType: (features.foundationType as string) ?? (features.foundation as string) ?? null,
        exteriorType: (features.exteriorType as string) ?? (features.exteriorWallType as string) ?? (features.exteriorWalls as string) ?? null,
        architectureType: (features.architectureType as string) ?? (features.archStyle as string) ?? null,
        pool: !!(features.pool || features.hasPool || features.poolType),
        poolType: (features.poolType as string) ?? null,
        garage: !!(features.garage || features.garageType),
        garageType: (features.garageType as string) ?? null,
        garageSpaces: (features.garageSpaces as number) ?? (features.parkingSpaces as number) ?? null,
        stories: (features.stories as number) ?? (features.floorCount as number) ?? null,
        fireplace: !!(features.fireplace || features.hasFireplace || features.fireplaceType),
        fireplaceType: (features.fireplaceType as string) ?? null,
      },
      taxAssessment: null,
    };

    // Tax assessment — RentCast returns an object or array
    const tax = propertyData?.taxAssessments ?? propertyData?.taxAssessment;
    if (tax) {
      if (typeof tax === "object" && !Array.isArray(tax)) {
        // Object keyed by year: { "2024": { value: 500000 } }
        const years = Object.keys(tax).map(Number).filter(n => !isNaN(n)).sort((a, b) => b - a);
        if (years.length > 0) {
          const latest = (tax as Record<string, Record<string, unknown>>)[String(years[0])];
          result.taxAssessment = {
            year: years[0],
            value: (latest?.value as number) ?? (latest?.totalValue as number) ?? null,
          };
        }
      }
    }

    console.log(
      `[property-lookup] Found: yearBuilt=${result.yearBuilt}, sqft=${result.squareFootage}, value=${result.estimatedValue}`
    );

    // --- CACHE RESULT ---
    if (supabase) {
      const addressHash = trimmedAddress.toLowerCase().replace(/\s+/g, " ");
      supabase
        .from("property_lookups")
        .upsert(
          { address_hash: addressHash, lookup_data: result },
          { onConflict: "address_hash" }
        )
        .then(({ error }) => {
          if (error) console.error("[property-lookup] Cache write failed:", error.message);
          else console.log("[property-lookup] Cached result");
        });
    }

    return new Response(
      JSON.stringify({ success: true, property: result }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error("[property-lookup] Error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers }
    );
  }
});

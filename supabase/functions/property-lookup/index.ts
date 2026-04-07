// Haven Edge Function: property-lookup
// Looks up property data from ATTOM (primary) with RentCast (fallback).
// ATTOM returns richer data: AVM with confidence score, tax assessment with
// actual tax amount, sales history with buyer/seller, owner info.
// Returns: yearBuilt, sqft, beds, baths, propertyType, features, estimated value,
// tax details, confidence score.
// Used during onboarding to instantly populate a property profile.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const ATTOM_BASE = "https://api.gateway.attomdata.com/propertyapi/v1.0.0";
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
  estimatedValueConfidence: number | null; // ATTOM confidence score 0-100
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
    basementSize: number | null;
    constructionCondition: string | null;
    qualityRating: string | null;
  };
  taxAssessment: {
    year: number | null;
    assessedValue: number | null;
    marketValue: number | null;
    taxAmount: number | null;
    taxPerSqFt: number | null;
  } | null;
  ownerInfo: {
    ownerName: string | null;
    absenteeOwner: boolean;
    mailingAddress: string | null;
  } | null;
  dataSource: "attom" | "rentcast";
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
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

    // --- ATTOM PRIMARY ---
    const attomKey = Deno.env.get("ATTOM_API_KEY");
    let result: PropertyResult | null = null;

    if (attomKey) {
      result = await tryAttom(trimmedAddress, attomKey);
    }

    // --- RENTCAST FALLBACK (for addresses ATTOM doesn't cover) ---
    if (!result) {
      const rentcastKey = Deno.env.get("RENTCAST_API_KEY");
      if (rentcastKey) {
        console.log("[property-lookup] ATTOM miss, trying RentCast fallback");
        result = await tryRentcast(trimmedAddress, rentcastKey);
        // RentCast tends to undervalue — adjust +5%
        if (result?.estimatedValue) {
          result.estimatedValue = Math.round(result.estimatedValue * 1.05);
          if (result.estimatedValueLow) result.estimatedValueLow = Math.round(result.estimatedValueLow * 1.05);
          if (result.estimatedValueHigh) result.estimatedValueHigh = Math.round(result.estimatedValueHigh * 1.05);
        }
      }
    }

    if (!result) {
      console.log("[property-lookup] No data found for address from either source");
      return new Response(
        JSON.stringify({ success: false, error: "not_found" }),
        { status: 200, headers }
      );
    }

    console.log(
      `[property-lookup] Found via ${result.dataSource}: yearBuilt=${result.yearBuilt}, sqft=${result.squareFootage}, value=${result.estimatedValue}, confidence=${result.estimatedValueConfidence}`
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

// --- ATTOM Data Solutions ---

async function tryAttom(address: string, apiKey: string): Promise<PropertyResult | null> {
  try {
    // Parse address into address1 (street) and address2 (city, state zip)
    const { address1, address2 } = parseAddressForAttom(address);
    if (!address1 || !address2) return null;

    const url = `${ATTOM_BASE}/attomavm/detail?address1=${encodeURIComponent(address1)}&address2=${encodeURIComponent(address2)}`;
    const res = await fetch(url, {
      headers: { apikey: apiKey, Accept: "application/json" },
      signal: AbortSignal.timeout(12000),
    });

    if (!res.ok) {
      console.error(`[property-lookup] ATTOM HTTP ${res.status}`);
      return null;
    }

    const data = await res.json();
    const properties = data?.property;
    if (!properties || !Array.isArray(properties) || properties.length === 0) {
      console.log("[property-lookup] ATTOM: no results");
      return null;
    }

    const p = properties[0];
    const summary = p.summary ?? {};
    const building = p.building ?? {};
    const size = building.size ?? {};
    const rooms = building.rooms ?? {};
    const interior = building.interior ?? {};
    const parking = building.parking ?? {};
    const bldgSummary = building.summary ?? {};
    const utilities = p.utilities ?? {};
    const avm = p.avm?.amount ?? {};
    const sale = p.sale ?? {};
    const saleAmount = sale.amount ?? {};
    const assessment = p.assessment ?? {};
    const assessed = assessment.assessed ?? {};
    const market = assessment.market ?? {};
    const tax = assessment.tax ?? {};
    const owner = p.owner ?? {};

    return {
      yearBuilt: summary.yearbuilt ?? null,
      squareFootage: size.livingsize ?? size.bldgsize ?? null,
      lotSize: p.lot?.lotsize2 ?? null, // sqft
      bedrooms: rooms.beds ?? null,
      bathrooms: rooms.bathstotal ?? null,
      propertyType: summary.propertyType ?? summary.propclass ?? null,
      lastSaleDate: sale.saleTransDate ?? null,
      lastSalePrice: saleAmount.saleamt ?? null,
      estimatedValue: avm.value ?? null,
      estimatedValueLow: avm.low ?? null,
      estimatedValueHigh: avm.high ?? null,
      estimatedValueConfidence: avm.scr ?? null,
      features: {
        roofType: null, // ATTOM doesn't return roof type in AVM endpoint
        heatingType: utilities.heatingtype ?? null,
        heatingFuel: utilities.heatingfuel ?? null,
        coolingType: null, // Not in ATTOM standard response
        foundationType: null,
        exteriorType: utilities.walltype ?? null,
        architectureType: bldgSummary.archStyle ?? null,
        pool: false, // Not reliably in ATTOM AVM endpoint
        poolType: null,
        garage: !!(parking.prkgType),
        garageType: parking.prkgType ?? null,
        garageSpaces: parking.prkgSize ? Math.round((parking.prkgSize as number) / 200) : null,
        stories: bldgSummary.levels ?? null,
        fireplace: interior.fplcind === "Y" || (interior.fplccount ?? 0) > 0,
        fireplaceType: interior.fplctype ?? null,
        basementSize: interior.bsmtsize ?? null,
        constructionCondition: building.construction?.condition ?? null,
        qualityRating: bldgSummary.quality ?? null,
      },
      taxAssessment: {
        year: tax.taxyear ?? null,
        assessedValue: assessed.assdttlvalue ?? null,
        marketValue: market.mktttlvalue ?? null,
        taxAmount: tax.taxamt ?? null,
        taxPerSqFt: tax.taxpersizeunit ?? null,
      },
      ownerInfo: owner.owner1?.fullname ? {
        ownerName: owner.owner1.fullname,
        absenteeOwner: summary.absenteeInd !== "OWNER OCCUPIED",
        mailingAddress: owner.mailingaddressoneline ?? null,
      } : null,
      dataSource: "attom",
    };
  } catch (err) {
    console.error("[property-lookup] ATTOM error:", err);
    return null;
  }
}

function parseAddressForAttom(fullAddress: string): { address1: string | null; address2: string | null } {
  // ATTOM needs address1 (street) and address2 (city, state zip)
  // Input: "123 Main St, Shelton, CT 06484" or "123 Main St Shelton CT 06484"
  const parts = fullAddress.split(",").map(s => s.trim());

  if (parts.length >= 3) {
    // "123 Main St, Shelton, CT 06484"
    return { address1: parts[0], address2: parts.slice(1).join(", ") };
  }
  if (parts.length === 2) {
    // "123 Main St, Shelton CT 06484"
    return { address1: parts[0], address2: parts[1] };
  }

  // No commas — try to split on state abbreviation pattern
  const stateMatch = fullAddress.match(/^(.+?)\s+([\w\s]+,?\s*[A-Z]{2}\s*\d{5}(?:-\d{4})?)$/);
  if (stateMatch) {
    return { address1: stateMatch[1], address2: stateMatch[2] };
  }

  // Last resort: assume first part is street, rest is city/state
  const words = fullAddress.split(/\s+/);
  if (words.length >= 4) {
    // Heuristic: street number + name is usually first 2-4 words
    const zipIdx = words.findIndex(w => /^\d{5}/.test(w));
    if (zipIdx >= 3) {
      const street = words.slice(0, zipIdx - 2).join(" ");
      const cityStateZip = words.slice(zipIdx - 2).join(" ");
      return { address1: street, address2: cityStateZip };
    }
  }

  return { address1: null, address2: null };
}

// --- RentCast Fallback ---

async function tryRentcast(address: string, apiKey: string): Promise<PropertyResult | null> {
  try {
    const encoded = encodeURIComponent(address);
    const rentcastHeaders = { Accept: "application/json", "X-Api-Key": apiKey };

    const [propertyRes, avmRes] = await Promise.allSettled([
      fetch(`${RENTCAST_BASE}/properties?address=${encoded}`, { headers: rentcastHeaders, signal: AbortSignal.timeout(10000) }),
      fetch(`${RENTCAST_BASE}/avm/value?address=${encoded}`, { headers: rentcastHeaders, signal: AbortSignal.timeout(10000) }),
    ]);

    let propertyData: Record<string, unknown> | null = null;
    if (propertyRes.status === "fulfilled" && propertyRes.value.ok) {
      const propJson = await propertyRes.value.json();
      if (Array.isArray(propJson) && propJson.length > 0) propertyData = propJson[0];
      else if (!Array.isArray(propJson) && propJson?.id) propertyData = propJson;
    }

    let avmData: Record<string, unknown> | null = null;
    if (avmRes.status === "fulfilled" && avmRes.value.ok) {
      avmData = await avmRes.value.json();
    }

    if (!propertyData && !avmData) return null;

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
      estimatedValueConfidence: null, // RentCast doesn't provide confidence score
      features: {
        roofType: (features.roofType as string) ?? (features.roofCover as string) ?? null,
        heatingType: (features.heatingType as string) ?? (features.heating as string) ?? null,
        heatingFuel: (features.heatingFuel as string) ?? null,
        coolingType: (features.coolingType as string) ?? (features.cooling as string) ?? null,
        foundationType: (features.foundationType as string) ?? (features.foundation as string) ?? null,
        exteriorType: (features.exteriorType as string) ?? (features.exteriorWallType as string) ?? null,
        architectureType: (features.architectureType as string) ?? (features.archStyle as string) ?? null,
        pool: !!(features.pool || features.hasPool || features.poolType),
        poolType: (features.poolType as string) ?? null,
        garage: !!(features.garage || features.garageType),
        garageType: (features.garageType as string) ?? null,
        garageSpaces: (features.garageSpaces as number) ?? null,
        stories: (features.stories as number) ?? null,
        fireplace: !!(features.fireplace || features.hasFireplace),
        fireplaceType: (features.fireplaceType as string) ?? null,
        basementSize: null,
        constructionCondition: null,
        qualityRating: null,
      },
      taxAssessment: null,
      ownerInfo: null,
      dataSource: "rentcast",
    };

    // Tax assessment from RentCast
    const tax = propertyData?.taxAssessments ?? propertyData?.taxAssessment;
    if (tax && typeof tax === "object" && !Array.isArray(tax)) {
      const years = Object.keys(tax).map(Number).filter(n => !isNaN(n)).sort((a, b) => b - a);
      if (years.length > 0) {
        const latest = (tax as Record<string, Record<string, unknown>>)[String(years[0])];
        result.taxAssessment = {
          year: years[0],
          assessedValue: (latest?.value as number) ?? (latest?.totalValue as number) ?? null,
          marketValue: null,
          taxAmount: null,
          taxPerSqFt: null,
        };
      }
    }

    return result;
  } catch (err) {
    console.error("[property-lookup] RentCast error:", err);
    return null;
  }
}

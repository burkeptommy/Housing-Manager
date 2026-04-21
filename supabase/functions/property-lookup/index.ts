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

// Phase 60.1: cache version token. Every cached row in property_lookups is
// keyed on `${normalizedAddress}|v${CACHE_VERSION}`. Bump this constant
// whenever the response shape changes (new fields, renamed fields, type
// changes) so every stale row becomes a miss and refetches fresh data from
// ATTOM. Phase 20 shipped a bathrooms Int -> Double type change with no
// cache bust, leaving pre-Phase-20 rows poisoning the iOS decoder
// indefinitely. This constant prevents that class of bug going forward.
const CACHE_VERSION = 2;

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
  estimatedValueConfidence: number | null; // 0-100 confidence (ATTOM AVM scr, ai_comps: 70, computed: 40, estimated: 25)
  /// Phase 16e + 18g: which fallback layer produced `estimatedValue`. One of
  /// "attom" | "rentcast" | "ai_comps" | "computed" | "estimated". Surfaced
  /// in iOS as a caption beneath the value to build trust.
  estimatedValueSource: "attom" | "rentcast" | "ai_comps" | "computed" | "estimated" | null;
  /// Phase 18g: When `estimatedValueSource = "ai_comps"`, this carries the
  /// short paragraph Claude returned explaining its methodology. iOS shows
  /// it in a tappable info modal so users understand where the number came
  /// from. NULL for every other source.
  estimatedValueReasoning?: string | null;
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
      // Phase 60.1: version the cache key so rows written before a
      // response-shape change (e.g. Phase 20's bathrooms Int -> Double
      // widening) become cache-misses on the next lookup and refetch
      // fresh data from ATTOM.
      const addressHash = `${trimmedAddress.toLowerCase().replace(/\s+/g, " ")}|v${CACHE_VERSION}`;

      const { data: cached } = await supabase
        .from("property_lookups")
        .select("lookup_data")
        .eq("address_hash", addressHash)
        .single();

      if (cached?.lookup_data) {
        console.log(`[property-lookup] Cache hit (v${CACHE_VERSION})`);
        return new Response(
          JSON.stringify({ success: true, property: cached.lookup_data, cached: true }),
          { status: 200, headers }
        );
      }
    }

    // --- ATTOM PRIMARY ---
    const attomKey = Deno.env.get("ATTOM_API_KEY");
    const rentcastKey = Deno.env.get("RENTCAST_API_KEY");
    let result: PropertyResult | null = null;

    if (attomKey) {
      result = await tryAttom(trimmedAddress, attomKey);
    }

    // --- RENTCAST PARTIAL FALLBACK (Phase 16e) ---
    // ATTOM sometimes returns rich property data with a NULL AVM (the case
    // that broke 146 Putnam Park Road). When that happens, call RentCast just
    // for its AVM and overlay it on the existing ATTOM record so we keep the
    // richer property data.
    if (rentcastKey) {
      const attomMissingAvm = result != null && result.estimatedValue == null;
      if (!result || attomMissingAvm) {
        if (result) {
          console.log("[property-lookup] ATTOM hit but no AVM, overlaying RentCast value");
        } else {
          console.log("[property-lookup] ATTOM miss, trying RentCast fallback");
        }
        const rentcastResult = await tryRentcast(trimmedAddress, rentcastKey);
        if (rentcastResult) {
          // RentCast tends to undervalue — adjust +5% (matches the original
          // RentCast-only path that's been in production for months).
          if (rentcastResult.estimatedValue) {
            rentcastResult.estimatedValue = Math.round(rentcastResult.estimatedValue * 1.05);
            if (rentcastResult.estimatedValueLow) {
              rentcastResult.estimatedValueLow = Math.round(rentcastResult.estimatedValueLow * 1.05);
            }
            if (rentcastResult.estimatedValueHigh) {
              rentcastResult.estimatedValueHigh = Math.round(rentcastResult.estimatedValueHigh * 1.05);
            }
          }
          if (result && attomMissingAvm) {
            // Keep ATTOM's richer property data, overlay just the AVM.
            result.estimatedValue = rentcastResult.estimatedValue;
            result.estimatedValueLow = rentcastResult.estimatedValueLow;
            result.estimatedValueHigh = rentcastResult.estimatedValueHigh;
            result.estimatedValueConfidence =
              rentcastResult.estimatedValueConfidence ?? result.estimatedValueConfidence;
            if (result.estimatedValue != null) {
              result.estimatedValueSource = "rentcast";
            }
          } else {
            result = rentcastResult;
            if (result.estimatedValue != null) {
              result.estimatedValueSource = "rentcast";
            }
          }
        }
      }
    }

    // --- CLAUDE WEB SEARCH FALLBACK (Phase 18g) ---
    // The case that broke 146 Putnam Park Road in Bethel CT: ATTOM had
    // rich data but no AVM, RentCast returned $673K (2% above the 2021
    // sale price of $660K), and Zillow / Redfin / Compass agree the place
    // is worth $850K-$1M. RentCast's AVM is materially undervaluing rural
    // / luxury markets. When RentCast disagrees with last-sale appreciation
    // by more than ~10%, ask Claude with web search to estimate from
    // recent comparable sales. Claude is a *better* fallback than the
    // arithmetic computed layer below for these markets.
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (anthropicKey && result && shouldUseClaudeFallback(result)) {
      try {
        console.log("[property-lookup] Trying Claude web-search fallback");
        const claudeEstimate = await estimateValueViaClaude(
          {
            address: trimmedAddress,
            yearBuilt: result.yearBuilt,
            squareFootage: result.squareFootage,
            bedrooms: result.bedrooms,
            bathrooms: result.bathrooms,
            lastSalePrice: result.lastSalePrice,
            lastSaleDate: result.lastSaleDate,
            propertyType: result.propertyType,
          },
          anthropicKey
        );
        if (claudeEstimate?.value) {
          console.log(
            `[property-lookup] Claude estimate: $${claudeEstimate.value} (${claudeEstimate.lowValue}-${claudeEstimate.highValue}, conf=${claudeEstimate.confidence})`
          );
          result.estimatedValue = claudeEstimate.value;
          result.estimatedValueLow = claudeEstimate.lowValue ?? null;
          result.estimatedValueHigh = claudeEstimate.highValue ?? null;
          result.estimatedValueConfidence = claudeEstimate.confidence ?? 70;
          result.estimatedValueSource = "ai_comps";
          result.estimatedValueReasoning = claudeEstimate.reasoning ?? null;
        }
      } catch (err) {
        console.warn("[property-lookup] Claude fallback failed:", err);
      }
    }

    // --- COMPUTED FALLBACK: appreciate last sale price (Phase 16e) ---
    // When neither AVM came back, but we still have the last sale on record,
    // compound it by ~3.5% per year (the long-run US average) so the user gets
    // *some* number instead of a blank Investment Summary.
    if (result && result.estimatedValue == null && result.lastSalePrice && result.lastSaleDate) {
      try {
        const salePriceNum = Number(result.lastSalePrice);
        const saleDate = new Date(result.lastSaleDate);
        if (!Number.isNaN(salePriceNum) && !Number.isNaN(saleDate.getTime())) {
          const yearsSinceSale =
            (Date.now() - saleDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000);
          const annualAppreciation = 0.035; // conservative US average
          result.estimatedValue = Math.round(
            salePriceNum * Math.pow(1 + annualAppreciation, Math.max(0, yearsSinceSale))
          );
          result.estimatedValueSource = "computed";
          result.estimatedValueConfidence = 40;
        }
      } catch (err) {
        console.warn("[property-lookup] Computed fallback failed:", err);
      }
    }

    // --- FINAL FALLBACK: square footage × state median (Phase 16e) ---
    // Even rural addresses with no sales record almost always have a sqft on
    // file. Multiplying by a state median is rough but always better than nil.
    if (result && result.estimatedValue == null && result.squareFootage) {
      const stateAbbr = extractStateAbbreviation(trimmedAddress);
      const medianPerSqft = stateAbbr
        ? STATE_MEDIAN_PRICE_PER_SQFT[stateAbbr] ?? 200
        : 200;
      result.estimatedValue = Math.round(result.squareFootage * medianPerSqft);
      result.estimatedValueSource = "estimated";
      result.estimatedValueConfidence = 25;
    }

    if (!result) {
      console.log("[property-lookup] No data found for address from either source");
      return new Response(
        JSON.stringify({ success: false, error: "not_found" }),
        { status: 200, headers }
      );
    }

    // Backfill the source field for the happy ATTOM path so callers always
    // see a value when `estimatedValue != null`.
    if (result.estimatedValue != null && !result.estimatedValueSource) {
      result.estimatedValueSource =
        result.dataSource === "rentcast" ? "rentcast" : "attom";
    }

    console.log(
      `[property-lookup] Found via ${result.dataSource}: yearBuilt=${result.yearBuilt}, sqft=${result.squareFootage}, value=${result.estimatedValue}, confidence=${result.estimatedValueConfidence}`
    );

    // --- CACHE RESULT ---
    if (supabase) {
      // Phase 60.1: matches the versioned read-side hash so writes never
      // land under a key that future reads can't find.
      const addressHash = `${trimmedAddress.toLowerCase().replace(/\s+/g, " ")}|v${CACHE_VERSION}`;
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
      estimatedValueSource: avm.value != null ? "attom" : null,
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
      estimatedValueSource: null, // backfilled by the caller after the +5% adjustment
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

// --- Phase 16e: square footage × state median fallback ---

// --- Phase 18g: Claude web-search fallback ---

interface ClaudeValueInput {
  address: string;
  yearBuilt: number | null;
  squareFootage: number | null;
  bedrooms: number | null;
  bathrooms: number | null;
  lastSalePrice: number | null;
  lastSaleDate: string | null;
  propertyType: string | null;
}

interface ClaudeEstimate {
  value: number | null;
  lowValue: number | null;
  highValue: number | null;
  confidence: number | null;
  reasoning: string | null;
}

/// Phase 18g: When ATTOM has no AVM AND RentCast either failed or returned
/// a value that disagrees materially with the last-sale appreciation curve,
/// fall back to Claude with web search. The arithmetic computed layer below
/// is the next fallback after Claude — Claude is preferred because it can
/// see actual recent comps in the neighborhood, which matters in rural /
/// luxury markets where RentCast undervalues by 20-30%.
function shouldUseClaudeFallback(result: PropertyResult): boolean {
  // Always try Claude when there's still no estimated value at all.
  if (result.estimatedValue == null) return true;
  // Try Claude when RentCast came back but the value is suspiciously low
  // relative to a known sale price (less than 5% appreciation since the
  // sale, even though many years may have passed). This catches the 146
  // Putnam Park Road case directly.
  if (
    result.estimatedValueSource === "rentcast" &&
    result.lastSalePrice != null &&
    result.lastSaleDate != null
  ) {
    try {
      const lastSaleDate = new Date(result.lastSaleDate);
      const yearsSinceSale =
        (Date.now() - lastSaleDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000);
      // If at least 2 years have passed but RentCast says less than 5%
      // appreciation total, it's almost certainly undervaluing.
      if (yearsSinceSale >= 2) {
        const minExpected = Number(result.lastSalePrice) * 1.05;
        if (result.estimatedValue < minExpected) {
          return true;
        }
      }
    } catch {
      // Date parse failure — let Claude try anyway.
      return true;
    }
  }
  return false;
}

async function estimateValueViaClaude(
  input: ClaudeValueInput,
  apiKey: string
): Promise<ClaudeEstimate | null> {
  const facts = [
    `Address: ${input.address}`,
    input.yearBuilt ? `Year built: ${input.yearBuilt}` : null,
    input.squareFootage ? `Square footage: ${input.squareFootage.toLocaleString()}` : null,
    input.bedrooms ? `Bedrooms: ${input.bedrooms}` : null,
    input.bathrooms ? `Bathrooms: ${input.bathrooms}` : null,
    input.propertyType ? `Property type: ${input.propertyType}` : null,
    input.lastSalePrice && input.lastSaleDate
      ? `Last sale: $${Number(input.lastSalePrice).toLocaleString()} on ${input.lastSaleDate}`
      : null,
  ]
    .filter(Boolean)
    .join("\n");

  const prompt = `You are a residential real estate valuation expert. Estimate the current 2026 market value for this single-family home.

Property facts:
${facts}

Methodology:
1. Use the web search tool to find recent (last 6 months) comparable sales in the same neighborhood / town / school district. Aim for 5-10 comps within 0.5 miles, similar size and age.
2. Cross-reference with public Zillow / Redfin / Compass / Realtor.com listings or estimates for this exact address if available.
3. Adjust for size, age, condition, lot size, and recent market appreciation in the area.
4. Provide a tight low/mid/high range with a confidence level reflecting how many comps you found.

Return ONLY a JSON object with these exact keys, no markdown fences:
{
  "value": <integer mid estimate>,
  "lowValue": <integer low end of range>,
  "highValue": <integer high end of range>,
  "confidence": <integer 0-100 — 80+ when 5+ recent comps exist, 60 when scarce>,
  "reasoning": "<one paragraph 2-4 sentences: how many comps you found, the range you saw, the key adjustments you made>"
}`;

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-6",
      max_tokens: 2048,
      tools: [
        {
          type: "web_search_20250305",
          name: "web_search",
          max_uses: 5,
        },
      ],
      system:
        "You are a real estate valuation expert. Use web search to find recent comparable sales. Return only valid JSON, no markdown fences, no preamble.",
      messages: [{ role: "user", content: prompt }],
    }),
    signal: AbortSignal.timeout(60000),
  });

  if (!response.ok) {
    const errText = await response.text();
    console.error(
      `[property-lookup] Claude API error: ${response.status} ${errText.substring(0, 300)}`
    );
    return null;
  }

  const data = await response.json();
  // Tool-use responses come back as an array of content blocks. The final
  // text block contains the JSON we want; intermediate blocks are tool_use
  // / tool_result pairs that we ignore.
  const blocks = (data.content as Array<{ type: string; text?: string }>) ?? [];
  const textBlocks = blocks.filter((b) => b.type === "text" && b.text);
  // Take the LAST text block, which is Claude's final answer after all
  // tool calls completed.
  const finalText = textBlocks[textBlocks.length - 1]?.text;
  if (!finalText) {
    console.warn("[property-lookup] Claude returned no text block");
    return null;
  }

  try {
    // Strip any markdown fences just in case (system prompt asks for none).
    const cleaned = finalText.replace(/```json\s*|\s*```/g, "").trim();
    // If Claude wrapped the JSON in extra prose, find the first {...} block.
    const jsonMatch = cleaned.match(/\{[\s\S]*\}/);
    const payload = jsonMatch ? jsonMatch[0] : cleaned;
    const parsed = JSON.parse(payload);
    if (typeof parsed.value !== "number") {
      console.warn(
        "[property-lookup] Claude estimate missing 'value':",
        finalText.substring(0, 300)
      );
      return null;
    }
    return {
      value: Math.round(parsed.value),
      lowValue: typeof parsed.lowValue === "number" ? Math.round(parsed.lowValue) : null,
      highValue: typeof parsed.highValue === "number" ? Math.round(parsed.highValue) : null,
      confidence: typeof parsed.confidence === "number" ? Math.round(parsed.confidence) : null,
      reasoning: typeof parsed.reasoning === "string" ? parsed.reasoning : null,
    };
  } catch (err) {
    console.warn(
      "[property-lookup] Failed to parse Claude estimate:",
      err,
      "raw:",
      finalText.substring(0, 300)
    );
    return null;
  }
}

/// Pull the two-letter state abbreviation out of the original address string.
/// Robust to "City, ST 12345" and "City ST 12345" shapes.
function extractStateAbbreviation(address: string): string | null {
  const match = address.toUpperCase().match(/\b([A-Z]{2})\s*\d{5}(?:-\d{4})?\b/);
  if (match) return match[1];
  // Last resort: look for any 2-letter token preceded by a comma.
  const fallback = address.toUpperCase().match(/,\s*([A-Z]{2})\b/);
  return fallback?.[1] ?? null;
}

/// Median residential price per square foot by state, mid-2025 figures from
/// Zillow / NAR data. These are deliberately approximate — they're only used
/// as a final-fallback when ATTOM, RentCast, AND last-sale fallback have all
/// failed, and they're flagged as "estimated" / 25% confidence in the UI.
const STATE_MEDIAN_PRICE_PER_SQFT: Record<string, number> = {
  AL: 145,
  AK: 240,
  AZ: 270,
  AR: 130,
  CA: 450,
  CO: 290,
  CT: 240,
  DE: 200,
  FL: 260,
  GA: 175,
  HI: 700,
  ID: 290,
  IL: 165,
  IN: 140,
  IA: 145,
  KS: 145,
  KY: 140,
  LA: 145,
  ME: 230,
  MD: 240,
  MA: 360,
  MI: 165,
  MN: 195,
  MS: 130,
  MO: 155,
  MT: 320,
  NE: 165,
  NV: 280,
  NH: 270,
  NJ: 290,
  NM: 195,
  NY: 320,
  NC: 195,
  ND: 165,
  OH: 140,
  OK: 135,
  OR: 320,
  PA: 165,
  RI: 280,
  SC: 180,
  SD: 175,
  TN: 200,
  TX: 180,
  UT: 290,
  VT: 250,
  VA: 240,
  WA: 360,
  WV: 130,
  WI: 175,
  WY: 240,
  DC: 540,
};

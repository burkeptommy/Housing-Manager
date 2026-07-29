// Haven Edge Function: scrape-manuals
// Navigates manufacturer support portals to find real PDF download URLs
// for equipment manuals. Uses brand-specific scraping strategies to extract
// direct PDF links from support pages.
//
// Usage:
//   POST /functions/v1/scrape-manuals
//   Body: { "manufacturer_slug": "samsung", "batch_size": 10 }
//   Body: { "model_number": "RF29DB9900QDAA" }
//
// This function finds the PDF URL, updates equipment_manuals.source_url,
// then triggers download-manuals to actually download and store the PDF.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { requireAdminOrInternal } from "../_shared/require-household.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Brand-specific scraping strategies
// Each strategy knows how to construct a URL and extract PDF links from the response
interface ScrapingStrategy {
  // Build the URL to search for a model's manual
  buildSearchUrl: (modelNumber: string) => string;
  // Extract PDF URLs from the HTML response
  extractPdfUrls: (html: string, modelNumber: string) => { owners_manual?: string; installation_guide?: string; spec_sheet?: string };
}

const strategies: Record<string, ScrapingStrategy> = {
  // === SAMSUNG ===
  samsung: {
    buildSearchUrl: (model) =>
      `https://www.samsung.com/us/support/model/${model}/`,
    extractPdfUrls: (html, model) => {
      const urls: Record<string, string> = {};
      // Samsung embeds download links with data-url or href containing .pdf
      const pdfMatches = html.match(/https?:\/\/[^\s"'<>]+\.pdf/gi) ?? [];
      for (const url of pdfMatches) {
        const lower = url.toLowerCase();
        if (lower.includes("user") || lower.includes("owner") || lower.includes("manual")) {
          urls.owners_manual = url;
        } else if (lower.includes("install")) {
          urls.installation_guide = url;
        } else if (lower.includes("spec") || lower.includes("dimension")) {
          urls.spec_sheet = url;
        }
      }
      // Also check Samsung download center pattern
      const downloadMatch = html.match(
        /https?:\/\/downloadcenter\.samsung\.com\/content\/[^\s"'<>]+\.pdf/gi
      );
      if (downloadMatch && downloadMatch.length > 0) {
        if (!urls.owners_manual) urls.owners_manual = downloadMatch[0];
        if (downloadMatch.length > 1 && !urls.installation_guide)
          urls.installation_guide = downloadMatch[1];
      }
      return urls;
    },
  },

  // === LG ===
  lg: {
    buildSearchUrl: (model) =>
      `https://www.lg.com/us/support/products/${model}.html`,
    extractPdfUrls: (html) => {
      const urls: Record<string, string> = {};
      // LG uses gscs-b2c.lge.com for PDF hosting
      const pdfMatches =
        html.match(
          /https?:\/\/gscs-b2c\.lge\.com\/downloadResource\/[^\s"'<>]+\.pdf/gi
        ) ?? [];
      for (const url of pdfMatches) {
        const lower = url.toLowerCase();
        if (
          lower.includes("owner") ||
          lower.includes("mfl") ||
          lower.includes("manual")
        ) {
          if (!urls.owners_manual) urls.owners_manual = url;
        } else if (lower.includes("install")) {
          if (!urls.installation_guide) urls.installation_guide = url;
        } else if (lower.includes("spec")) {
          if (!urls.spec_sheet) urls.spec_sheet = url;
        }
      }
      // Fallback: any PDF on LG's CDN
      if (!urls.owners_manual && pdfMatches.length > 0)
        urls.owners_manual = pdfMatches[0];
      return urls;
    },
  },

  // === WHIRLPOOL FAMILY (Whirlpool, Maytag, KitchenAid, Amana) ===
  whirlpool: {
    buildSearchUrl: (model) =>
      `https://www.whirlpool.com/support/product-help.html?model=${model}`,
    extractPdfUrls: (html) => {
      const urls: Record<string, string> = {};
      // Whirlpool hosts on their content dam
      const pdfMatches =
        html.match(
          /https?:\/\/[^\s"'<>]*whirlpool\.com\/content\/dam\/[^\s"'<>]+\.pdf/gi
        ) ?? [];
      for (const url of pdfMatches) {
        const lower = url.toLowerCase();
        if (lower.includes("use") || lower.includes("care") || lower.includes("owner")) {
          if (!urls.owners_manual) urls.owners_manual = url;
        } else if (lower.includes("install")) {
          if (!urls.installation_guide) urls.installation_guide = url;
        } else if (lower.includes("dimension") || lower.includes("spec")) {
          if (!urls.spec_sheet) urls.spec_sheet = url;
        }
      }
      if (!urls.owners_manual && pdfMatches.length > 0)
        urls.owners_manual = pdfMatches[0];
      return urls;
    },
  },

  // === GE FAMILY (GE, GE Profile, Monogram, Cafe, Hotpoint) ===
  "ge-appliances": {
    buildSearchUrl: (model) =>
      `https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber=${model}`,
    extractPdfUrls: (html) => {
      const urls: Record<string, string> = {};
      // GE uses products.geappliances.com for PDF retrieval
      const pdfMatches =
        html.match(
          /https?:\/\/products\.geappliances\.com\/[^\s"'<>]+\.pdf/gi
        ) ?? [];
      // Also check for their MarketingObjectRetrieval pattern
      const moMatches =
        html.match(
          /https?:\/\/products\.geappliances\.com\/MarketingObjectRetrieval\/[^\s"'<>]+/gi
        ) ?? [];
      const allMatches = [...pdfMatches, ...moMatches];
      for (const url of allMatches) {
        const lower = url.toLowerCase();
        if (lower.includes("owner") || lower.includes("useandcare")) {
          if (!urls.owners_manual) urls.owners_manual = url;
        } else if (lower.includes("install")) {
          if (!urls.installation_guide) urls.installation_guide = url;
        } else if (lower.includes("spec") || lower.includes("dimension")) {
          if (!urls.spec_sheet) urls.spec_sheet = url;
        }
      }
      if (!urls.owners_manual && allMatches.length > 0)
        urls.owners_manual = allMatches[0];
      return urls;
    },
  },

  // === BSH FAMILY (Bosch, Thermador, Gaggenau) ===
  bosch: {
    buildSearchUrl: (model) =>
      `https://www.bosch-home.com/us/support/${model}`,
    extractPdfUrls: (html) => {
      const urls: Record<string, string> = {};
      // BSH hosts on media3.bsh-group.com
      const pdfMatches =
        html.match(
          /https?:\/\/media3\.bsh-group\.com\/Documents\/[^\s"'<>]+\.pdf/gi
        ) ?? [];
      for (const url of pdfMatches) {
        const lower = url.toLowerCase();
        if (lower.includes("manual") || lower.includes("instruction")) {
          if (!urls.owners_manual) urls.owners_manual = url;
        } else if (lower.includes("install")) {
          if (!urls.installation_guide) urls.installation_guide = url;
        } else if (lower.includes("spec") || lower.includes("data")) {
          if (!urls.spec_sheet) urls.spec_sheet = url;
        }
      }
      if (!urls.owners_manual && pdfMatches.length > 0)
        urls.owners_manual = pdfMatches[0];
      return urls;
    },
  },

  // === KOHLER (Bathroom) ===
  kohler: {
    buildSearchUrl: (model) =>
      `https://www.us.kohler.com/us/search?q=${model}&type=documents`,
    extractPdfUrls: (html) => {
      const urls: Record<string, string> = {};
      const pdfMatches =
        html.match(/https?:\/\/[^\s"'<>]*kohler[^\s"'<>]*\.pdf/gi) ?? [];
      for (const url of pdfMatches) {
        const lower = url.toLowerCase();
        if (lower.includes("spec") || lower.includes("sheet")) {
          if (!urls.spec_sheet) urls.spec_sheet = url;
        } else if (lower.includes("install")) {
          if (!urls.installation_guide) urls.installation_guide = url;
        } else {
          if (!urls.owners_manual) urls.owners_manual = url;
        }
      }
      return urls;
    },
  },

  // === TOTO (Bathroom) ===
  toto: {
    buildSearchUrl: (model) =>
      `https://www.totousa.com/search?q=${model}`,
    extractPdfUrls: (html) => {
      const urls: Record<string, string> = {};
      const pdfMatches =
        html.match(/https?:\/\/[^\s"'<>]*toto[^\s"'<>]*\.pdf/gi) ?? [];
      for (const url of pdfMatches) {
        const lower = url.toLowerCase();
        if (lower.includes("spec")) {
          if (!urls.spec_sheet) urls.spec_sheet = url;
        } else if (lower.includes("install") || lower.includes("rough")) {
          if (!urls.installation_guide) urls.installation_guide = url;
        } else {
          if (!urls.owners_manual) urls.owners_manual = url;
        }
      }
      return urls;
    },
  },

  // === PENTAIR (Pool) ===
  pentair: {
    buildSearchUrl: (model) =>
      `https://www.pentair.com/en-us/search.html?q=${model}&type=documents`,
    extractPdfUrls: (html) => {
      const urls: Record<string, string> = {};
      const pdfMatches =
        html.match(
          /https?:\/\/[^\s"'<>]*pentair\.com\/content\/dam\/[^\s"'<>]+\.pdf/gi
        ) ?? [];
      for (const url of pdfMatches) {
        const lower = url.toLowerCase();
        if (lower.includes("owner") || lower.includes("manual") || lower.includes("operation")) {
          if (!urls.owners_manual) urls.owners_manual = url;
        } else if (lower.includes("install")) {
          if (!urls.installation_guide) urls.installation_guide = url;
        } else if (lower.includes("spec") || lower.includes("dimension")) {
          if (!urls.spec_sheet) urls.spec_sheet = url;
        }
      }
      if (!urls.owners_manual && pdfMatches.length > 0)
        urls.owners_manual = pdfMatches[0];
      return urls;
    },
  },

  // === GENERAC ===
  generac: {
    buildSearchUrl: (model) =>
      `https://www.generac.com/service-support/product-support-lookup?modelNumber=${model}`,
    extractPdfUrls: (html) => {
      const urls: Record<string, string> = {};
      const pdfMatches =
        html.match(/https?:\/\/[^\s"'<>]*generac[^\s"'<>]*\.pdf/gi) ?? [];
      for (const url of pdfMatches) {
        const lower = url.toLowerCase();
        if (lower.includes("owner") || lower.includes("manual")) {
          if (!urls.owners_manual) urls.owners_manual = url;
        } else if (lower.includes("install") || lower.includes("wiring")) {
          if (!urls.installation_guide) urls.installation_guide = url;
        } else if (lower.includes("spec")) {
          if (!urls.spec_sheet) urls.spec_sheet = url;
        }
      }
      if (!urls.owners_manual && pdfMatches.length > 0)
        urls.owners_manual = pdfMatches[0];
      return urls;
    },
  },
};

// Map brand families to their strategy
const brandStrategyMap: Record<string, string> = {
  // Whirlpool family
  whirlpool: "whirlpool",
  maytag: "whirlpool",
  kitchenaid: "whirlpool",
  amana: "whirlpool",
  // GE family
  "ge-appliances": "ge-appliances",
  "ge-profile": "ge-appliances",
  monogram: "ge-appliances",
  cafe: "ge-appliances",
  hotpoint: "ge-appliances",
  // BSH family
  bosch: "bosch",
  thermador: "bosch",
  gaggenau: "bosch",
  // Direct mappings
  samsung: "samsung",
  lg: "lg",
  kohler: "kohler",
  toto: "toto",
  pentair: "pentair",
  generac: "generac",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // July 2026 security sweep (audit S9): these batch/admin utilities were
  // fully unauthenticated in prod (arbitrary uploads, batch-job triggers,
  // Claude spend). Admin JWT (CHEZ_ADMIN_EMAILS), the internal secret, or
  // the service-role bearer are now required.
  if (!(await requireAdminOrInternal(req))) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json().catch(() => ({}));
    const manufacturerSlug: string | null = body.manufacturer_slug ?? null;
    const modelNumber: string | null = body.model_number ?? null;
    const batchSize: number = body.batch_size ?? 10;
    const triggerDownload: boolean = body.trigger_download ?? false;

    if (!manufacturerSlug && !modelNumber) {
      return new Response(
        JSON.stringify({
          error: "Provide manufacturer_slug or model_number",
          available_strategies: Object.keys(brandStrategyMap),
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Determine which strategy to use
    const strategyKey = manufacturerSlug
      ? brandStrategyMap[manufacturerSlug]
      : null;

    if (manufacturerSlug && !strategyKey) {
      return new Response(
        JSON.stringify({
          error: `No scraping strategy for "${manufacturerSlug}"`,
          available_strategies: Object.keys(brandStrategyMap),
          suggestion:
            "For brands without strategies, research PDF URLs manually and use download-manuals directly.",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get models to process
    let query = supabase
      .from("equipment_catalog")
      .select(
        `
        id,
        model_number,
        model_name,
        equipment_manufacturers!inner (
          name,
          slug
        )
      `
      );

    if (modelNumber) {
      query = query.eq("model_number", modelNumber);
    } else if (manufacturerSlug) {
      query = query.eq("equipment_manufacturers.slug", manufacturerSlug);
    }

    query = query.limit(batchSize);

    const { data: models, error: queryError } = await query;
    if (queryError) throw new Error(queryError.message);
    if (!models || models.length === 0) {
      return new Response(
        JSON.stringify({ message: "No models found", processed: 0 }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const results: Array<{
      model_number: string;
      status: string;
      urls_found: number;
      details: Record<string, string>;
    }> = [];

    for (const model of models) {
      const manufacturer = (model as any).equipment_manufacturers;
      const slug = manufacturer?.slug;
      const activeStrategy = strategies[brandStrategyMap[slug] ?? ""];

      if (!activeStrategy) {
        results.push({
          model_number: model.model_number,
          status: "no_strategy",
          urls_found: 0,
          details: {},
        });
        continue;
      }

      try {
        const searchUrl = activeStrategy.buildSearchUrl(model.model_number);
        console.log(
          `[scrape-manuals] Fetching: ${searchUrl}`
        );

        const response = await fetch(searchUrl, {
          signal: AbortSignal.timeout(15000),
          headers: {
            "User-Agent":
              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            Accept: "text/html,application/xhtml+xml",
          },
          redirect: "follow",
        });

        if (!response.ok) {
          results.push({
            model_number: model.model_number,
            status: `http_${response.status}`,
            urls_found: 0,
            details: {},
          });
          continue;
        }

        const html = await response.text();
        const pdfUrls = activeStrategy.extractPdfUrls(html, model.model_number);
        const urlCount = Object.keys(pdfUrls).length;

        // Update equipment_manuals with found PDF URLs
        for (const [manualType, pdfUrl] of Object.entries(pdfUrls)) {
          if (pdfUrl) {
            await supabase
              .from("equipment_manuals")
              .update({
                source_url: pdfUrl,
                last_verified_at: new Date().toISOString(),
              })
              .eq("catalog_entry_id", model.id)
              .eq("manual_type", manualType);
          }
        }

        results.push({
          model_number: model.model_number,
          status: urlCount > 0 ? "found" : "no_pdfs_found",
          urls_found: urlCount,
          details: pdfUrls,
        });

        // Rate limiting — 500ms between requests to be respectful
        await new Promise((r) => setTimeout(r, 500));
      } catch (err) {
        results.push({
          model_number: model.model_number,
          status: "error",
          urls_found: 0,
          details: {
            error: err instanceof Error ? err.message : "Unknown error",
          },
        });
      }
    }

    const found = results.filter((r) => r.status === "found").length;
    const totalUrls = results.reduce((sum, r) => sum + r.urls_found, 0);

    // Optionally trigger download-manuals for the found URLs
    if (triggerDownload && found > 0 && manufacturerSlug) {
      fetch(`${supabaseUrl}/functions/v1/download-manuals`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${serviceRoleKey}`,
        },
        body: JSON.stringify({
          manufacturer_slug: manufacturerSlug,
          batch_size: found * 3,
        }),
      }).catch(() => {}); // Fire and forget
    }

    return new Response(
      JSON.stringify({
        processed: results.length,
        models_with_pdfs: found,
        total_urls_found: totalUrls,
        results,
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

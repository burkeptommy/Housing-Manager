// Haven Edge Function: enrich-provider-logos
// One-shot batch backfill that walks `utility_providers` rows where logo_url IS
// NULL, calls the existing brand-logo function for each, and writes back the
// returned logoUrl + brandColor. Used to populate the freshly-seeded insurance
// rows from Phase 16a after the migration runs.
//
// Optional body: { "limit": number, "providerType": string }
//   - limit (default 200) — max rows to process per invocation
//   - providerType — narrow to just one slice (e.g. "auto_insurance")
//
// Deploy:
//   supabase functions deploy enrich-provider-logos --no-verify-jwt
//
// Manually invoke:
//   curl -X POST "https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/enrich-provider-logos" \
//     -H "Content-Type: application/json" \
//     -d '{"limit": 200}'

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ProviderRow {
  id: string;
  name: string;
  slug: string;
  website: string | null;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const brandfetchApiKey = Deno.env.get("BRANDFETCH_API_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Supabase env not configured" }),
        { status: 500, headers }
      );
    }
    if (!brandfetchApiKey) {
      return new Response(
        JSON.stringify({ error: "BRANDFETCH_API_KEY not configured" }),
        { status: 500, headers }
      );
    }

    let body: { limit?: number; providerType?: string } = {};
    try {
      body = await req.json();
    } catch {
      // Empty body is fine — falls back to defaults below.
    }
    const limit = Math.max(1, Math.min(500, body.limit ?? 200));
    const providerType = body.providerType?.trim();

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    let query = supabase
      .from("utility_providers")
      .select("id,name,slug,website")
      .is("logo_url", null)
      .order("name", { ascending: true })
      .limit(limit);
    if (providerType) {
      query = query.eq("provider_type", providerType);
    }
    const { data, error } = await query;
    if (error) {
      console.error("[enrich-provider-logos] Query error:", error.message);
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers }
      );
    }

    const rows: ProviderRow[] = (data ?? []) as unknown as ProviderRow[];
    if (rows.length === 0) {
      return new Response(
        JSON.stringify({ success: true, scanned: 0, enriched: 0, message: "No rows need enrichment" }),
        { status: 200, headers }
      );
    }

    console.log(`[enrich-provider-logos] Enriching ${rows.length} providers`);

    let enriched = 0;
    let failed = 0;
    // Brandfetch is rate-limited, so process in small chunks with a brief
    // breather between each. 25 per chunk + 2s sleep is well under the
    // documented per-minute ceiling on the Starter plan.
    const chunkSize = 25;
    for (let i = 0; i < rows.length; i += chunkSize) {
      const chunk = rows.slice(i, i + chunkSize);
      const results = await Promise.allSettled(
        chunk.map((row) => enrichRow(row, brandfetchApiKey, supabaseUrl, serviceRoleKey))
      );
      for (const result of results) {
        if (result.status === "fulfilled" && result.value) enriched += 1;
        else failed += 1;
      }
      if (i + chunkSize < rows.length) {
        await sleep(2000);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        scanned: rows.length,
        enriched,
        failed,
      }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error("[enrich-provider-logos] Error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers }
    );
  }
});

async function enrichRow(
  row: ProviderRow,
  brandfetchApiKey: string,
  supabaseUrl: string,
  serviceRoleKey: string
): Promise<boolean> {
  // Prefer website (direct domain lookup is more reliable than the search API).
  let domain: string | null = null;
  if (row.website) {
    domain = row.website
      .replace(/^https?:\/\//, "")
      .replace(/\/.*$/, "")
      .toLowerCase()
      .trim();
    if (!domain) domain = null;
  }

  let logoUrl: string | null = null;
  let brandColor: string | null = null;

  try {
    if (domain) {
      const res = await fetch(`https://api.brandfetch.io/v2/brands/${domain}`, {
        headers: { Authorization: `Bearer ${brandfetchApiKey}` },
        signal: AbortSignal.timeout(10000),
      });
      if (res.ok) {
        const brand = await res.json();
        const extracted = extractBrandData(brand);
        logoUrl = extracted.logoUrl ?? extracted.iconUrl;
        brandColor = extracted.brandColor;
      } else {
        console.warn(
          `[enrich-provider-logos] Brandfetch ${res.status} for ${row.name} (${domain})`
        );
      }
    } else {
      // No website on the seed row — fall back to a name search.
      const searchRes = await fetch(
        `https://api.brandfetch.io/v2/search/${encodeURIComponent(row.name)}`,
        {
          headers: { Authorization: `Bearer ${brandfetchApiKey}` },
          signal: AbortSignal.timeout(10000),
        }
      );
      if (searchRes.ok) {
        const results = await searchRes.json();
        if (Array.isArray(results) && results.length > 0) {
          const top = results[0];
          if (top?.icon) logoUrl = top.icon;
        }
      }
    }
  } catch (err) {
    console.warn(`[enrich-provider-logos] Lookup failed for ${row.name}:`, err);
    return false;
  }

  if (!logoUrl) {
    return false;
  }

  // Write back via REST so we don't need a second supabase client per row.
  const updateRes = await fetch(
    `${supabaseUrl}/rest/v1/utility_providers?id=eq.${row.id}`,
    {
      method: "PATCH",
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({
        logo_url: logoUrl,
        brand_color: brandColor,
      }),
    }
  );
  if (!updateRes.ok) {
    console.error(
      `[enrich-provider-logos] Update failed for ${row.name}: HTTP ${updateRes.status}`
    );
    return false;
  }
  return true;
}

function extractBrandData(brand: any) {
  const logos: { url: string; format: string; theme: string; type: string }[] = [];
  const icons: { url: string; format: string; theme: string }[] = [];
  const colors: { hex: string; type: string }[] = [];

  for (const logoGroup of brand.logos ?? []) {
    const type = logoGroup.type ?? "logo";
    for (const format of logoGroup.formats ?? []) {
      const entry = {
        url: format.src,
        format: format.format ?? "png",
        theme: logoGroup.theme ?? "light",
        type,
      };
      if (type === "icon" || type === "symbol") {
        icons.push(entry);
      } else {
        logos.push(entry);
      }
    }
  }

  for (const color of brand.colors ?? []) {
    colors.push({ hex: color.hex, type: color.type ?? "accent" });
  }

  const rasterFormats = ["png", "jpeg", "webp"];
  const pickBest = (items: typeof icons, preferTheme = "dark") => {
    const rasterThemed = items.find(
      (i) => rasterFormats.includes(i.format) && i.theme === preferTheme
    );
    if (rasterThemed) return rasterThemed.url;
    const rasterAny = items.find((i) => rasterFormats.includes(i.format));
    if (rasterAny) return rasterAny.url;
    return (
      items.find((i) => i.theme === preferTheme)?.url ??
      items[0]?.url ??
      null
    );
  };

  return {
    logoUrl: pickBest(logos as any),
    iconUrl: pickBest(icons as any),
    brandColor:
      colors.find((c) => c.type === "accent")?.hex ??
      colors.find((c) => c.type === "dark")?.hex ??
      colors[0]?.hex ??
      null,
  };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

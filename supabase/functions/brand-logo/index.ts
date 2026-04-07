import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const brandfetchApiKey = Deno.env.get("BRANDFETCH_API_KEY");
    if (!brandfetchApiKey) {
      return new Response(
        JSON.stringify({ error: "Brandfetch API not configured" }),
        { status: 500, headers }
      );
    }

    const body = await req.json();
    const { query, domain } = body;

    if (!query && !domain) {
      return new Response(
        JSON.stringify({ error: "Missing query or domain" }),
        { status: 400, headers }
      );
    }

    // If we have a domain, fetch directly from the Brand API
    if (domain) {
      return await fetchBrandByDomain(domain, brandfetchApiKey, headers);
    }

    // Otherwise search by name first, then fetch the top result
    return await searchAndFetchBrand(query, brandfetchApiKey, headers);
  } catch (error) {
    console.error("[brand-logo] Error:", error);
    return new Response(
      JSON.stringify({ error: error.message ?? "Brand lookup failed" }),
      { status: 500, headers }
    );
  }
});

async function fetchBrandByDomain(
  domain: string,
  apiKey: string,
  headers: Record<string, string>
): Promise<Response> {
  // Clean domain — strip protocol and path
  const cleanDomain = domain
    .replace(/^https?:\/\//, "")
    .replace(/\/.*$/, "")
    .toLowerCase();

  console.log(`[brand-logo] Fetching brand for domain: ${cleanDomain}`);

  const res = await fetch(
    `https://api.brandfetch.io/v2/brands/${cleanDomain}`,
    {
      headers: { Authorization: `Bearer ${apiKey}` },
      signal: AbortSignal.timeout(10000),
    }
  );

  if (!res.ok) {
    const errText = await res.text();
    console.error(
      `[brand-logo] Brandfetch API error: ${res.status} ${errText.substring(0, 200)}`
    );
    return new Response(
      JSON.stringify({ error: "Brand not found", domain: cleanDomain }),
      { status: 404, headers }
    );
  }

  const brand = await res.json();
  const result = extractBrandData(brand);

  console.log(
    `[brand-logo] Found: ${result.name}, logos: ${result.logos.length}, icons: ${result.icons.length}`
  );

  return new Response(JSON.stringify(result), { status: 200, headers });
}

async function searchAndFetchBrand(
  query: string,
  apiKey: string,
  headers: Record<string, string>
): Promise<Response> {
  console.log(`[brand-logo] Searching for: ${query}`);

  // Search for matching brands
  const searchRes = await fetch("https://api.brandfetch.io/v2/search/" + encodeURIComponent(query), {
    headers: { Authorization: `Bearer ${apiKey}` },
    signal: AbortSignal.timeout(10000),
  });

  if (!searchRes.ok) {
    const errText = await searchRes.text();
    console.error(
      `[brand-logo] Search error: ${searchRes.status} ${errText.substring(0, 200)}`
    );
    return new Response(
      JSON.stringify({ error: "Brand search failed" }),
      { status: 502, headers }
    );
  }

  const searchResults = await searchRes.json();

  if (!searchResults || searchResults.length === 0) {
    return new Response(
      JSON.stringify({ error: "No brands found", query }),
      { status: 404, headers }
    );
  }

  // Take the top result and fetch full brand data
  const topResult = searchResults[0];
  const domain = topResult.domain;

  if (!domain) {
    // Return search result info without full brand data
    return new Response(
      JSON.stringify({
        name: topResult.name ?? query,
        domain: null,
        brandId: topResult.brandId ?? null,
        icon: topResult.icon ?? null,
        logos: [],
        icons: topResult.icon ? [{ url: topResult.icon, format: "png" }] : [],
        colors: [],
      }),
      { status: 200, headers }
    );
  }

  // Fetch full brand details for the top search result
  return await fetchBrandByDomain(domain, apiKey, headers);
}

function extractBrandData(brand: any) {
  const logos: { url: string; format: string; theme: string; type: string }[] =
    [];
  const icons: { url: string; format: string; theme: string }[] = [];
  const colors: { hex: string; type: string }[] = [];

  // Extract logos
  for (const logoGroup of brand.logos ?? []) {
    const type = logoGroup.type ?? "logo"; // "logo", "symbol", "icon"
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

  // Extract colors
  for (const color of brand.colors ?? []) {
    colors.push({ hex: color.hex, type: color.type ?? "accent" });
  }

  // Prefer PNG/JPEG over SVG for iOS AsyncImage compatibility
  const rasterFormats = ["png", "jpeg", "webp"];
  const pickBest = (items: typeof icons, preferTheme = "dark") => {
    // First try: raster format in preferred theme
    const rasterThemed = items.find(
      (i) => rasterFormats.includes(i.format) && i.theme === preferTheme
    );
    if (rasterThemed) return rasterThemed.url;
    // Second try: any raster format
    const rasterAny = items.find((i) => rasterFormats.includes(i.format));
    if (rasterAny) return rasterAny.url;
    // Fallback: any format in preferred theme, then any
    return (
      items.find((i) => i.theme === preferTheme)?.url ??
      items[0]?.url ??
      null
    );
  };

  return {
    name: brand.name ?? "",
    domain: brand.domain ?? null,
    brandId: brand.id ?? null,
    logos,
    icons,
    colors,
    // Convenience: best logo and icon URLs for quick use (prefer raster for iOS)
    logoUrl: pickBest(logos as any),
    iconUrl: pickBest(icons as any),
    brandColor: colors.find((c) => c.type === "accent")?.hex ??
      colors.find((c) => c.type === "dark")?.hex ??
      colors[0]?.hex ?? null,
  };
}

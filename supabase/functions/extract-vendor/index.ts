import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicApiKey) {
      return new Response(JSON.stringify({ error: "AI not configured" }), { status: 500, headers });
    }

    const body = await req.json();
    const { url } = body;

    if (!url) {
      return new Response(JSON.stringify({ error: "Missing URL" }), { status: 400, headers });
    }

    console.log(`[extract-vendor] Fetching: ${url}`);

    // Fetch the website HTML
    let htmlContent: string;
    try {
      const siteResponse = await fetch(url, {
        headers: {
          "User-Agent": "Mozilla/5.0 (compatible; ChezBot/1.0; +https://getchez.com)",
          "Accept": "text/html,application/xhtml+xml",
        },
        signal: AbortSignal.timeout(15000),
      });

      if (!siteResponse.ok) {
        return new Response(
          JSON.stringify({ error: `Website returned status ${siteResponse.status}` }),
          { status: 400, headers }
        );
      }

      htmlContent = await siteResponse.text();
    } catch (fetchErr) {
      return new Response(
        JSON.stringify({ error: "Could not reach that website. Check the URL." }),
        { status: 400, headers }
      );
    }

    // Trim HTML to a reasonable size for Claude (keep first 15000 chars)
    // Strip script/style tags to reduce noise
    const cleaned = htmlContent
      .replace(/<script[\s\S]*?<\/script>/gi, "")
      .replace(/<style[\s\S]*?<\/style>/gi, "")
      .replace(/<[^>]+>/g, " ")
      .replace(/\s+/g, " ")
      .trim()
      .substring(0, 15000);

    console.log(`[extract-vendor] Extracted ${cleaned.length} chars of text from site`);

    // Send to Claude for extraction
    const claudeRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 2048,
        system: `You extract business contact information from website text. Return ONLY valid JSON with these fields:
{
  "business_name": "The company/business name",
  "contact_name": "Owner or primary contact name if found, null if not",
  "phone": "Primary phone number formatted as (XXX) XXX-XXXX, empty string if not found",
  "email": "Primary email address, empty string if not found",
  "address": "Full business address, empty string if not found",
  "license_number": "Any professional license number mentioned, empty string if not found",
  "services": ["Array of specific services this business offers, e.g. 'HVAC Installation', 'Plumbing Repair', 'Drain Cleaning'"],
  "hours": "Business hours if found, null if not",
  "description": "One sentence about what this business does"
}
Return ONLY JSON. No markdown. No explanation.`,
        messages: [{
          role: "user",
          content: `Extract business contact information from this website (${url}):\n\n${cleaned}`,
        }],
      }),
    });

    if (!claudeRes.ok) {
      const errText = await claudeRes.text();
      console.error(`[extract-vendor] Claude error: ${claudeRes.status} ${errText.substring(0, 200)}`);
      return new Response(
        JSON.stringify({ error: "AI extraction failed" }),
        { status: 502, headers }
      );
    }

    const claudeData = await claudeRes.json();
    let rawText = claudeData.content?.[0]?.text ?? "";

    // Strip markdown fences
    let cleaned2 = rawText.trim();
    if (cleaned2.startsWith("```json")) cleaned2 = cleaned2.slice(7);
    else if (cleaned2.startsWith("```")) cleaned2 = cleaned2.slice(3);
    if (cleaned2.endsWith("```")) cleaned2 = cleaned2.slice(0, -3);

    const result = JSON.parse(cleaned2.trim());

    console.log(`[extract-vendor] Extracted: ${result.business_name}, services: ${result.services?.length ?? 0}`);

    return new Response(JSON.stringify(result), { status: 200, headers });

  } catch (error) {
    console.error("[extract-vendor] Error:", error);
    return new Response(
      JSON.stringify({ error: error.message ?? "Extraction failed" }),
      { status: 500, headers }
    );
  }
});

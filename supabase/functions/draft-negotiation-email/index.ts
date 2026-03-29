// Haven Edge Function: draft-negotiation-email
// Takes quote analysis results and drafts a professional negotiation email.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface NegotiationRequest {
  vendor_name: string;
  vendor_email?: string;
  homeowner_name?: string;
  project_type?: string;
  quote_total: number;
  estimated_fair_total: number;
  potential_savings: number;
  overpriced_items: Array<{
    description: string;
    quoted_price: number;
    market_price: number;
    rating_reason: string;
  }>;
  negotiation_tips: string[];
  property_location?: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicApiKey) {
      return new Response(
        JSON.stringify({ error: "ANTHROPIC_API_KEY not set" }),
        { status: 500, headers }
      );
    }

    const body: NegotiationRequest = await req.json();
    const {
      vendor_name,
      vendor_email,
      homeowner_name,
      project_type,
      quote_total,
      estimated_fair_total,
      potential_savings,
      overpriced_items,
      negotiation_tips,
      property_location,
    } = body;

    if (!vendor_name || !overpriced_items?.length) {
      return new Response(
        JSON.stringify({ error: "Missing vendor_name or overpriced_items" }),
        { status: 400, headers }
      );
    }

    const systemPrompt = `You are a professional communication writer helping a homeowner negotiate a contractor quote. Write a polite but firm email that:
1. Thanks the contractor for the quote
2. Mentions specific line items that appear above market rate with the fair market price
3. Points out any common scope items that appear to be MISSING from the quote (e.g., missing warranty terms, missing permit costs, missing cleanup/disposal fees, missing material specs)
4. Asks if there's flexibility on pricing
5. Asks about warranty and guarantee terms if not mentioned
6. Keeps a respectful, professional tone throughout
7. Does NOT use em dashes, excessive exclamation marks, or overly casual language
8. Is concise (under 250 words)
9. Ends with an invitation to discuss

Return ONLY the email body text. No subject line, no JSON, no formatting instructions.`;

    const itemSummary = overpriced_items
      .map(
        (item) =>
          `- ${item.description}: Quoted $${item.quoted_price.toFixed(2)}, market rate ~$${item.market_price.toFixed(2)} (${item.rating_reason})`
      )
      .join("\n");

    const userPrompt = `Draft a negotiation email for this contractor quote:

CONTRACTOR: ${vendor_name}
${project_type ? `PROJECT: ${project_type}` : ""}
${property_location ? `LOCATION: ${property_location}` : ""}
${homeowner_name ? `HOMEOWNER: ${homeowner_name}` : ""}

QUOTE TOTAL: $${quote_total.toFixed(2)}
FAIR MARKET ESTIMATE: $${estimated_fair_total.toFixed(2)}
POTENTIAL SAVINGS: $${potential_savings.toFixed(2)}

OVERPRICED LINE ITEMS:
${itemSummary}

NEGOTIATION CONTEXT:
${negotiation_tips.join("\n")}

Write a professional email the homeowner can send to this contractor.`;

    const claudeResponse = await fetch(
      "https://api.anthropic.com/v1/messages",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": anthropicApiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: 1024,
          system: systemPrompt,
          messages: [{ role: "user", content: userPrompt }],
        }),
      }
    );

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text();
      console.error(`[draft-negotiation-email] Claude error: ${errText}`);
      return new Response(
        JSON.stringify({ error: "AI service error", detail: errText.substring(0, 500) }),
        { status: 502, headers }
      );
    }

    const claudeData = await claudeResponse.json();
    const emailBody = claudeData?.content?.[0]?.text ?? "";

    const subject = `Re: ${project_type || "Project"} Quote${vendor_name ? ` from ${vendor_name}` : ""}`;

    console.log(`[draft-negotiation-email] Generated email for ${vendor_name}`);

    return new Response(
      JSON.stringify({
        success: true,
        email: {
          subject,
          body: emailBody,
          to: vendor_email || null,
          savings: potential_savings,
        },
      }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error("[draft-negotiation-email] Error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers }
    );
  }
});

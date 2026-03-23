import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const VALID_CATEGORIES = [
  "Will","Trust","Power of Attorney","Healthcare Directive","Guardianship Designation","Letter of Intent",
  "LLC Operating Agreement","LP Agreement","S-Corp Documents","EIN Documentation","Annual Filings","Bylaws",
  "Deed","Mortgage","Title Insurance","Survey","HOA Documents","Lease Agreement","Property Tax Records",
  "Life Insurance","Umbrella Insurance","Homeowners Insurance","Auto Insurance","Jewelry/Art Rider",
  "Long-Term Care Insurance","Disability Insurance","Directors & Officers Insurance",
  "Brokerage Account","Retirement Account (IRA/401k)","Bank Account","529 Plan",
  "Beneficiary Designation","Stock Options/RSUs","Crypto Wallet","Alternative Investments",
  "Federal Tax Return","State Tax Return","Gift Tax Return (Form 709)","Property Tax Record",
  "Estate & Trust Return (Form 1041)",
  "Vehicle Title","Art Appraisal","Jewelry Appraisal","Collectibles Documentation","Boat/Aircraft Registration",
  "Domain Names","Digital Account Inventory","Social Media Accounts","Intellectual Property",
  "Passport","Birth Certificate","Marriage Certificate","Divorce Decree","Social Security Card",
  "Citizenship/Immigration","Death Certificate",
  "Employment Agreement","Non-Compete/NDA","Partnership Agreement","Buy-Sell Agreement","Succession Plan",
  "Project Plan","Contractor Quote","Project Invoice","Before/After Photos","Permit",
  "Inspection Report","Completion Certificate",
  "Blueprint/Floor Plan","Property Layout","Appliance Manual","Warranty Card",
  "Home Inventory","Utility Account","Vendor Contract",
  "Home Bill/Invoice","Property Tax Bill","Utility Bill","Repair Estimate","Renovation Budget",
  "Other Personal Documents",
];

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    // --- ENV CHECK ---
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicApiKey) {
      return new Response(JSON.stringify({ error: "ANTHROPIC_API_KEY not set" }), { status: 500, headers });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // --- PARSE REQUEST ---
    const body = await req.json();
    const { document_id, text, image_base64, category, household_id, document_title } = body;

    if (!document_id || !household_id) {
      return new Response(JSON.stringify({ error: "Missing document_id or household_id" }), { status: 400, headers });
    }
    if (!text && !image_base64) {
      return new Response(JSON.stringify({ error: "No content. Send text or image_base64." }), { status: 400, headers });
    }

    console.log(`[analyze] doc=${document_id} household=${household_id} hasText=${!!text} hasImage=${!!image_base64}`);

    // --- BUILD CLAUDE REQUEST ---
    const messages_content: Array<Record<string, unknown>> = [];

    if (text) {
      messages_content.push({
        type: "text",
        text: `Category hint: ${category ?? "Unknown"}\nTitle: ${document_title ?? "Unknown"}\n\nDocument text:\n${text}`,
      });
    } else {
      messages_content.push({
        type: "image",
        source: { type: "base64", media_type: "image/jpeg", data: image_base64 },
      });
      messages_content.push({
        type: "text",
        text: `Category hint: ${category ?? "Unknown"}\nTitle: ${document_title ?? "Unknown"}\n\nAnalyze this document. Extract all text and include in "extracted_text" field.`,
      });
    }

    // --- CALL CLAUDE ---
    console.log("[analyze] Calling Claude API...");
    const t0 = Date.now();

    const claudeRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 4096,
        system: `You are a document analysis assistant for a home management and estate planning app. Return ONLY valid JSON with these fields:
{
  "summary": "2-3 sentence summary",
  "category_suggestion": "one of: ${VALID_CATEGORIES.join(", ")}",
  "key_dates": [{"label":"string","date":"YYYY-MM-DD"}],
  "key_parties": [{"name":"string","role":"string"}],
  "flags": [{"severity":"critical|warning|info","message":"string"}],
  "extracted_metadata": {"key":"value"},
  "cross_reference_suggestions": ["category names"]
}

CLASSIFICATION RULES (follow strictly):
- "Employment Agreement" means a SIGNED CONTRACT between employer and employee with terms of employment, compensation, termination clauses, etc. Do NOT use this for resumes, CVs, cover letters, or job descriptions.
- Resumes, CVs, cover letters, job descriptions, LinkedIn profiles, and career documents → "Other Personal Documents" with an info flag: "This appears to be a resume/CV rather than a legal agreement. Filed under Other Personal Documents."
- School transcripts, diplomas, report cards, course materials → "Other Personal Documents"
- Recipes, personal letters, non-business correspondence → "Other Personal Documents"
- Any document NOT directly relevant to home management, estate planning, insurance, financial records, property, or personal identification → "Other Personal Documents" with an info flag explaining what it is and why it was filed there.

IMPORTANT: When in doubt between a specific category and "Other Personal Documents", consider whether the document has legal/financial significance to the household. A resume has no legal significance — it is NOT an employment agreement.

If analyzing an image, also include "extracted_text" with all readable text.
Return ONLY JSON. No markdown. No explanation.`,
        messages: [{ role: "user", content: messages_content }],
      }),
    });

    console.log(`[analyze] Claude responded in ${Date.now() - t0}ms with status ${claudeRes.status}`);

    if (!claudeRes.ok) {
      const errText = await claudeRes.text();
      console.error(`[analyze] Claude error ${claudeRes.status}: ${errText.substring(0, 300)}`);
      return new Response(
        JSON.stringify({
          error: `Claude API error (${claudeRes.status})`,
          detail: errText.substring(0, 200),
          claude_status: claudeRes.status,
        }),
        { status: 502, headers }
      );
    }

    const claudeData = await claudeRes.json();
    const rawText = claudeData.content?.[0]?.text ?? "";

    // --- PARSE RESPONSE ---
    let analysis: Record<string, unknown>;
    try {
      let cleaned = rawText.trim();
      if (cleaned.startsWith("```json")) cleaned = cleaned.slice(7);
      else if (cleaned.startsWith("```")) cleaned = cleaned.slice(3);
      if (cleaned.endsWith("```")) cleaned = cleaned.slice(0, -3);
      analysis = JSON.parse(cleaned.trim());
    } catch {
      console.error("[analyze] JSON parse failed, using fallback. Raw:", rawText.substring(0, 200));
      analysis = {
        summary: rawText.substring(0, 500),
        category_suggestion: category ?? "Unknown",
        flags: [], key_dates: [], key_parties: [],
        extracted_metadata: {}, cross_reference_suggestions: [],
      };
    }

    // Validate category
    const suggested = (analysis.category_suggestion as string) ?? "";
    if (!VALID_CATEGORIES.includes(suggested)) {
      const lower = suggested.toLowerCase();
      const match = VALID_CATEGORIES.find(c => c.toLowerCase() === lower || lower.includes(c.toLowerCase()) || c.toLowerCase().includes(lower));
      analysis.category_suggestion = match ?? (category ?? "Unknown");
    }

    console.log(`[analyze] Success! Category: ${analysis.category_suggestion}`);

    // --- RETURN IMMEDIATELY ---
    // Send the analysis back to the client NOW. DB operations happen after.
    const responseBody = JSON.stringify(analysis);

    // --- FIRE-AND-FORGET DB OPERATIONS ---
    // These run in the background. If they fail, the client still gets the analysis.
    if (supabaseUrl && serviceRoleKey) {
      const svc = createClient(supabaseUrl, serviceRoleKey);

      // Update document record
      svc.from("documents").update({
        ai_summary: analysis.summary,
        ai_flags: analysis.flags ?? [],
        category: analysis.category_suggestion,
        metadata: {
          cross_references: analysis.cross_reference_suggestions ?? [],
          extracted_metadata: analysis.extracted_metadata ?? {},
        },
      }).eq("id", document_id).then(({ error }) => {
        if (error) console.error("[analyze] DB update failed:", error.message);
        else console.log("[analyze] Document updated in DB");
      });

      // Store extracted text
      const extractedText = (analysis.extracted_text as string) ?? text ?? "";
      if (extractedText.length > 0) {
        svc.from("document_content").upsert({
          document_id,
          household_id,
          extracted_text: extractedText,
          extraction_method: text ? "text_extraction" : "ocr",
          extracted_at: new Date().toISOString(),
          last_ai_analysis_at: new Date().toISOString(),
          ai_model_version: "claude-sonnet-4-6",
        }, { onConflict: "document_id" }).then(({ error }) => {
          if (error) console.error("[analyze] document_content upsert failed:", error.message);
        });
      }

      // Log
      svc.from("access_log").insert({
        household_id,
        user_id: body.user_id ?? null,
        action: "document_ai_analyzed",
        resource_type: "document",
        resource_id: document_id,
        actor_type: "ai_analysis",
        metadata: { model: "claude-sonnet-4-6", category: analysis.category_suggestion },
      }).then(({ error }) => {
        if (error) console.warn("[analyze] access_log insert failed:", error.message);
      });
    }

    return new Response(responseBody, { status: 200, headers });

  } catch (error) {
    console.error("[analyze] Unhandled:", error);
    return new Response(
      JSON.stringify({ error: error.message ?? "Internal error", detail: String(error) }),
      { status: 500, headers }
    );
  }
});

// Haven Edge Function: analyze-document
// Receives document text/image, calls Claude API, returns AI summary + flags + category suggestion.
// Stores results back in the document record.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface AnalyzeRequest {
  document_id: string;
  text?: string;
  image_base64?: string;
  category?: string;
  household_id: string;
}

interface AnalyzeResponse {
  summary: string;
  category_suggestion: string;
  flags: Array<{
    severity: "critical" | "warning" | "info";
    message: string;
  }>;
  key_dates: Array<{
    label: string;
    date: string;
  }>;
  key_parties: Array<{
    name: string;
    role: string;
  }>;
  extracted_metadata: Record<string, string>;
  cross_reference_suggestions: string[];
}

const ANALYSIS_PROMPT = `You are a document analysis assistant for a premium estate organization service. Analyze the following document and return a JSON response with:

1. "summary" — A 2-3 sentence plain-language summary of what this document is and its key provisions
2. "category_suggestion" — Your best guess at the document category if not already provided. Use one of: Will, Trust, Power of Attorney, Healthcare Directive, Guardianship Designation, Letter of Intent, LLC Operating Agreement, LP Agreement, S-Corp Documents, EIN Documentation, Annual Filings, Bylaws, Deed, Mortgage, Title Insurance, Survey, HOA Documents, Lease Agreement, Property Tax Records, Life Insurance, Umbrella Insurance, Homeowners Insurance, Auto Insurance, Jewelry/Art Rider, Long-Term Care Insurance, Disability Insurance, Directors & Officers Insurance, Brokerage Account, Retirement Account (IRA/401k), Bank Account, 529 Plan, Beneficiary Designation, Stock Options/RSUs, Crypto Wallet, Alternative Investments, Federal Tax Return, State Tax Return, Gift Tax Return (Form 709), Property Tax Record, Estate & Trust Return (Form 1041), Vehicle Title, Art Appraisal, Jewelry Appraisal, Collectibles Documentation, Boat/Aircraft Registration, Domain Names, Digital Account Inventory, Social Media Accounts, Intellectual Property, Passport, Birth Certificate, Marriage Certificate, Divorce Decree, Social Security Card, Citizenship/Immigration, Death Certificate, Employment Agreement, Non-Compete/NDA, Partnership Agreement, Buy-Sell Agreement, Succession Plan
3. "key_dates" — Array of dates found (effective date, expiration, renewal, etc.) with labels. Each: { "label": string, "date": "YYYY-MM-DD" }
4. "key_parties" — Array of people/entities named in the document with their roles. Each: { "name": string, "role": string }
5. "flags" — Array of potential issues or items needing attention, each with:
   - "severity": "critical" | "warning" | "info"
   - "message": Plain language description of the issue
6. "extracted_metadata" — Any relevant structured data as key-value pairs (policy numbers, account numbers last 4 digits, institution names, coverage amounts, etc.)
7. "cross_reference_suggestions" — Array of document category names that should be checked against this document (e.g., if this is a trust, suggest checking beneficiary designations on financial accounts)

Respond ONLY with valid JSON. No markdown, no explanation, no code fences.`;

serve(async (req: Request) => {
  try {
    // Verify auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body: AnalyzeRequest = await req.json();
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicApiKey) {
      return new Response(
        JSON.stringify({ error: "AI service not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Build Claude message content
    const content: Array<Record<string, unknown>> = [];

    if (body.text) {
      content.push({
        type: "text",
        text: `Document category: ${body.category ?? "Unknown"}\n\nDocument text:\n${body.text}`,
      });
    } else if (body.image_base64) {
      content.push({
        type: "image",
        source: {
          type: "base64",
          media_type: "image/jpeg",
          data: body.image_base64,
        },
      });
      content.push({
        type: "text",
        text: `Document category: ${body.category ?? "Unknown"}\n\nPlease analyze the document shown in the image above.`,
      });
    } else {
      return new Response(
        JSON.stringify({ error: "No document content provided. Send either 'text' or 'image_base64'." }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Call Claude API
    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 4096,
        system: ANALYSIS_PROMPT,
        messages: [{ role: "user", content }],
      }),
    });

    if (!claudeResponse.ok) {
      const errorText = await claudeResponse.text();
      console.error("Claude API error:", errorText);
      return new Response(
        JSON.stringify({ error: "AI analysis failed" }),
        { status: 502, headers: { "Content-Type": "application/json" } }
      );
    }

    const claudeData = await claudeResponse.json();
    const rawText = claudeData.content?.[0]?.text ?? "";

    // Parse the JSON response from Claude
    let analysis: AnalyzeResponse;
    try {
      analysis = JSON.parse(rawText);
    } catch {
      console.error("Failed to parse Claude response as JSON:", rawText);
      analysis = {
        summary: rawText.substring(0, 500),
        category_suggestion: body.category ?? "Unknown",
        flags: [],
        key_dates: [],
        key_parties: [],
        extracted_metadata: {},
        cross_reference_suggestions: [],
      };
    }

    // Store AI results back in the document record
    const { error: updateError } = await supabase
      .from("documents")
      .update({
        ai_summary: analysis.summary,
        ai_flags: analysis.flags,
      })
      .eq("id", body.document_id);

    if (updateError) {
      console.error("Failed to update document with AI results:", updateError);
    }

    return new Response(JSON.stringify(analysis), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("analyze-document error:", error);
    return new Response(
      JSON.stringify({ error: error.message ?? "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

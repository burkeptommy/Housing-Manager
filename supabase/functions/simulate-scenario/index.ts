// Haven Edge Function: simulate-scenario
// Receives scenario_id + household_id + optional params, gathers all household data,
// sends a specialized prompt to Claude, returns structured JSON for the iOS app to render.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ScenarioRequest {
  scenario_id?: string;
  custom_query?: string;
  household_id: string;
  params?: Record<string, string>;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    // --- ENV CHECK ---
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicApiKey) {
      return new Response(
        JSON.stringify({ error: "ANTHROPIC_API_KEY not set" }),
        { status: 500, headers }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // --- PARSE REQUEST ---
    const body: ScenarioRequest = await req.json();
    const { scenario_id, custom_query, household_id, params } = body;

    if (!household_id) {
      return new Response(
        JSON.stringify({ error: "Missing household_id" }),
        { status: 400, headers }
      );
    }

    if (!scenario_id && !custom_query) {
      return new Response(
        JSON.stringify({ error: "Missing scenario_id or custom_query" }),
        { status: 400, headers }
      );
    }

    const isCustom = !scenario_id && !!custom_query;
    console.log(
      `[simulate-scenario] ${isCustom ? "custom" : "preset"}=${isCustom ? custom_query : scenario_id} household=${household_id}`
    );

    // --- FETCH ALL HOUSEHOLD DATA ---
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const [
      householdResult,
      membersResult,
      propertiesResult,
      documentsResult,
      maintenanceResult,
      warrantiesResult,
      systemsResult,
    ] = await Promise.all([
      supabase.from("households").select("*").eq("id", household_id).single(),
      supabase.from("family_members").select("*").eq("household_id", household_id),
      supabase.from("properties").select("*").eq("household_id", household_id),
      supabase.from("documents").select("*").eq("household_id", household_id).is("deleted_at", null),
      supabase.from("maintenance_tasks").select("*").eq("household_id", household_id),
      supabase.from("warranties").select("*").eq("household_id", household_id),
      supabase.from("home_systems").select("*").eq("household_id", household_id),
    ]);

    const household = householdResult.data;
    const members = membersResult.data ?? [];
    const properties = propertiesResult.data ?? [];
    const documents = documentsResult.data ?? [];
    const maintenance = maintenanceResult.data ?? [];
    const warranties = warrantiesResult.data ?? [];
    const systems = systemsResult.data ?? [];

    // Fetch document content (summaries + extracted text) for key documents
    const { data: documentContent } = await supabase
      .from("document_content")
      .select("document_id, extracted_text")
      .eq("household_id", household_id);

    // Build document summaries with content
    const documentSummaries = documents.map((doc: Record<string, unknown>) => {
      const content = documentContent?.find(
        (c: Record<string, unknown>) => c.document_id === doc.id
      );
      const excerpt = content?.extracted_text
        ? (content.extracted_text as string).substring(0, 2000)
        : null;
      return {
        title: doc.title,
        category: doc.category,
        ai_summary: doc.ai_summary,
        ai_flags: doc.ai_flags,
        uploaded_at: doc.created_at,
        property_id: doc.property_id,
        excerpt,
      };
    });

    // Track what data we have for personalization scoring
    const documentsUsed: string[] = [];
    const documentsMissing: string[] = [];

    // Check for key document types
    const docCategories = documents.map(
      (d: Record<string, unknown>) => (d.category as string || "").toLowerCase()
    );

    const checkDoc = (name: string, keywords: string[]) => {
      const found = keywords.some((kw) =>
        docCategories.some((c) => c.includes(kw))
      );
      if (found) documentsUsed.push(name);
      else documentsMissing.push(name);
    };

    checkDoc("Trust", ["trust"]);
    checkDoc("Will", ["will"]);
    checkDoc("Life Insurance", ["life insurance"]);
    checkDoc("Mortgage", ["mortgage"]);
    checkDoc("Property Records", ["deed", "title"]);
    checkDoc("Beneficiary Designations", ["beneficiary"]);
    checkDoc("Tax Returns", ["tax return"]);
    checkDoc("Power of Attorney", ["power of attorney"]);
    checkDoc("Insurance Policies", ["insurance"]);
    checkDoc("Retirement Accounts", ["retirement", "ira", "401k"]);

    // --- BUILD HOUSEHOLD CONTEXT ---
    const householdContext = `
HOUSEHOLD DATA:
${household ? `Household: ${household.name || "Unknown"}` : "No household data"}

FAMILY MEMBERS:
${
  members.length > 0
    ? members
        .map(
          (m: Record<string, unknown>) =>
            `- ${m.first_name} ${m.last_name} (${m.relationship || "member"}, DOB: ${m.date_of_birth || "unknown"})`
        )
        .join("\n")
    : "No family members added"
}

PROPERTIES:
${
  properties.length > 0
    ? properties
        .map(
          (p: Record<string, unknown>) =>
            `- ${p.name}: ${p.street || ""}, ${p.city || ""}, ${p.state || ""} ${p.zip || ""} (Type: ${p.property_type || "unknown"}, Purchase Price: ${p.purchase_price ? "$" + p.purchase_price : "unknown"}, Purchase Date: ${p.purchase_date || "unknown"}, Current Value: ${p.estimated_value ? "$" + p.estimated_value : "unknown"})`
        )
        .join("\n")
    : "No properties added"
}

HOME SYSTEMS:
${
  systems.length > 0
    ? systems
        .map(
          (s: Record<string, unknown>) =>
            `- ${s.name} (${s.type || "unknown"}, installed: ${s.install_date || "unknown"}, warranty expires: ${s.warranty_expiration || "unknown"})`
        )
        .join("\n")
    : "No home systems tracked"
}

DOCUMENTS (with AI summaries):
${
  documentSummaries.length > 0
    ? documentSummaries
        .map(
          (d: Record<string, unknown>) =>
            `- [${d.category}] ${d.title}${d.ai_summary ? "\n  Summary: " + d.ai_summary : ""}${d.ai_flags ? "\n  Flags: " + JSON.stringify(d.ai_flags) : ""}${d.excerpt ? "\n  Content: " + d.excerpt : ""}`
        )
        .join("\n")
    : "No documents uploaded"
}

WARRANTIES:
${
  warranties.length > 0
    ? warranties
        .map(
          (w: Record<string, unknown>) =>
            `- ${w.item_name}: expires ${w.expiration_date || "unknown"} (provider: ${w.provider || "unknown"})`
        )
        .join("\n")
    : "No warranties tracked"
}

MAINTENANCE:
${
  maintenance.length > 0
    ? maintenance
        .map(
          (t: Record<string, unknown>) =>
            `- ${t.title}: ${t.status || "unknown"} (due: ${t.next_due_date || "unknown"})`
        )
        .join("\n")
    : "No maintenance tasks"
}
`.trim();

    // --- BUILD SCENARIO PROMPT ---
    const scenarioPrompt = isCustom
      ? buildCustomPrompt(custom_query!, householdContext, documentsUsed, documentsMissing)
      : buildScenarioPrompt(scenario_id!, householdContext, params, documentsUsed, documentsMissing);

    // --- CALL CLAUDE ---
    console.log(`[simulate-scenario] Calling Claude for: ${isCustom ? "custom query" : scenario_id}`);

    const hasAnyData = members.length > 0 || properties.length > 0 || documents.length > 0;

    let claudeResponse: Response;
    try {
      claudeResponse = await fetch(
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
            max_tokens: 8192,
            system: `You are a financial and estate planning scenario simulator. You MUST return ONLY valid JSON — no markdown code fences, no backticks, no explanation outside the JSON object. Start your response with { and end with }.

IMPORTANT: In the "summary" field of your JSON response, always begin with: "This analysis is for educational and informational purposes only and does not constitute legal, financial, or tax advice. Please consult qualified professionals before making decisions based on these results."${
              !hasAnyData
                ? " The user has not uploaded any documents or added household data yet. Provide helpful GENERAL advice about this topic, clearly noting that you don't have their specific data. Explain the general benefits, considerations, and steps they should take. Recommend they upload relevant documents to get personalized analysis."
                : ""
            }`,
            messages: [
              {
                role: "user",
                content: scenarioPrompt,
              },
            ],
          }),
        }
      );
    } catch (fetchErr) {
      console.error(`[simulate-scenario] Fetch to Claude failed:`, fetchErr);
      return new Response(
        JSON.stringify({
          error: "Failed to connect to AI service",
          detail: String(fetchErr),
        }),
        { status: 502, headers }
      );
    }

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text();
      console.error(
        `[simulate-scenario] Claude API error (${claudeResponse.status}): ${errText}`
      );

      // Parse specific error types for better client messaging
      let errorMessage = "AI service error";
      let errorCode = "ai_error";
      try {
        const errJson = JSON.parse(errText);
        const errType = errJson?.error?.type ?? "";
        const errMsg = errJson?.error?.message ?? "";

        if (claudeResponse.status === 401) {
          errorMessage = "AI service authentication failed";
          errorCode = "auth_error";
        } else if (claudeResponse.status === 429) {
          errorMessage = "AI service is rate limited. Please wait a moment and try again.";
          errorCode = "rate_limited";
        } else if (errType === "not_found_error" || errMsg.includes("model")) {
          errorMessage = "AI model configuration error";
          errorCode = "model_error";
          console.error(`[simulate-scenario] Model error — check model ID is valid`);
        } else if (claudeResponse.status === 400) {
          errorMessage = "AI request was invalid";
          errorCode = "bad_request";
        } else if (claudeResponse.status >= 500) {
          errorMessage = "AI service is temporarily unavailable";
          errorCode = "ai_unavailable";
        }
        console.error(`[simulate-scenario] Parsed error type: ${errType}, message: ${errMsg}`);
      } catch {
        // errText was not JSON
      }

      return new Response(
        JSON.stringify({
          error: errorMessage,
          error_code: errorCode,
          detail: errText.substring(0, 500),
        }),
        { status: 502, headers }
      );
    }

    const claudeData = await claudeResponse.json();
    const aiText =
      claudeData?.content?.[0]?.text ?? '{"error": "No response from AI"}';

    // Extract JSON from response
    let result: Record<string, unknown>;
    try {
      // Try direct parse first
      result = JSON.parse(aiText);
    } catch {
      // Try extracting JSON from markdown code block or surrounding text
      const jsonMatch = aiText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          result = JSON.parse(jsonMatch[0]);
        } catch {
          console.error("[simulate-scenario] Failed to parse extracted JSON");
          result = {
            title: "Scenario Analysis",
            severity: "informational",
            summary: aiText.substring(0, 500),
            timeline: [],
            action_items: [],
            recommendations: [],
          };
        }
      } else {
        result = {
          title: "Scenario Analysis",
          severity: "informational",
          summary: aiText.substring(0, 500),
          timeline: [],
          action_items: [],
          recommendations: [],
        };
      }
    }

    // Inject personalization data
    result.documents_used = documentsUsed;
    result.documents_missing = documentsMissing;

    console.log(`[simulate-scenario] Success for scenario: ${scenario_id}`);

    return new Response(JSON.stringify(result), { status: 200, headers });
  } catch (err) {
    console.error("[simulate-scenario] Error:", err);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        detail: String(err),
      }),
      { status: 500, headers }
    );
  }
});

// --- PROMPT BUILDER ---

function buildScenarioPrompt(
  scenarioId: string,
  householdContext: string,
  params: Record<string, string> | undefined,
  documentsUsed: string[],
  documentsMissing: string[]
): string {
  const category = scenarioId.split("_")[0]; // "estate", "tax", "home", "wealth", "kids", "insurance"

  const hasDocuments = documentsUsed.length > 0;
  const hasMinimalData = documentsUsed.length === 0 && documentsMissing.length > 0;

  const baseInstructions = `You are a financial and estate planning scenario simulator for Haven, a home management app. You have access to this family's document vault and financial picture. Generate a detailed scenario analysis.

IMPORTANT RULES:
1. Use the ACTUAL names, amounts, and details from the household data below when available. Never use generic placeholders if real data exists.
2. If specific data is missing, provide GENERAL expert advice about the topic. Explain the general benefits, typical numbers, and considerations. Clearly note what you're estimating or generalizing.
3. ${hasMinimalData ? "The user has very few documents uploaded. Provide helpful general guidance while noting that uploading specific documents (list which ones) would allow much more personalized analysis." : "Be specific and actionable — this should feel like a personal consultation."}
4. Always include that this is for educational/planning purposes only, not legal or financial advice.
5. Recommend consulting appropriate professionals.
6. Return ONLY valid JSON — no markdown, no code blocks, no explanation outside the JSON.

${householdContext}

PERSONALIZATION:
- Documents available: ${documentsUsed.join(", ") || "None"}
- Missing documents: ${documentsMissing.join(", ") || "None"}
${params ? `\nUSER-PROVIDED PARAMETERS:\n${Object.entries(params).map(([k, v]) => `- ${k}: ${v}`).join("\n")}` : ""}
`;

  const responseStructures: Record<string, string> = {
    estate: `Return JSON with this EXACT structure:
{
  "title": "scenario title using their real names",
  "severity": "critical" | "important" | "informational",
  "summary": "One paragraph executive summary using real names, amounts, and specific details from their documents",
  "timeline": [
    {
      "step": 1,
      "title": "Immediately",
      "description": "What happens first — use real names and specifics",
      "details": ["specific detail 1", "specific detail 2"],
      "flag": "warning" | "good" | "critical" | null
    }
  ],
  "financial_impact": {
    "assets_protected": "$X total in trust",
    "assets_at_risk": "$X outside trust (probate)",
    "tax_exposure": "$X estimated",
    "insurance_payouts": "$X total",
    "breakdown": [
      {"item": "Asset name", "amount": "$X", "status": "protected" | "at_risk" | "unknown", "goes_to": "Who receives it", "flag": "Warning note if any or null"}
    ]
  },
  "guardian_chain": [
    {"name": "Full Name", "relationship": "Relationship", "status": "primary" | "alternate"}
  ],
  "action_items": [
    {
      "priority": "critical" | "high" | "medium" | "low",
      "title": "Action title",
      "description": "Detailed description with specifics",
      "effort": "Estimated time/effort"
    }
  ],
  "recommendations": ["Specific recommendation 1", "Specific recommendation 2"],
  "did_you_know": "An interesting, relevant fact about estate planning that relates to their situation",
  "disclaimer": "This analysis is for planning purposes only and does not constitute legal, tax, or financial advice. Consult qualified professionals before making decisions."
}`,

    tax: `Return JSON with this EXACT structure:
{
  "title": "scenario title using their real names/business",
  "severity": "critical" | "important" | "informational",
  "summary": "One paragraph executive summary with real numbers",
  "current_situation": {"key": "value pairs describing current state"},
  "proposed_situation": {"key": "value pairs describing proposed state"},
  "savings_breakdown": {
    "annual_tax_savings": "$X",
    "details": ["Specific savings detail 1", "Detail 2"]
  },
  "steps_to_implement": ["Step 1", "Step 2"],
  "risks_and_considerations": ["Risk 1", "Risk 2"],
  "timeline": [
    {"step": 1, "title": "Step title", "description": "Details", "details": [], "flag": null}
  ],
  "action_items": [
    {"priority": "high", "title": "Action", "description": "Details", "effort": "Time estimate"}
  ],
  "recommendations": ["Recommendation 1"],
  "did_you_know": "Relevant tax fact",
  "disclaimer": "This analysis is for planning purposes only and does not constitute legal, tax, or financial advice. Consult qualified professionals before making decisions."
}`,

    home: `Return JSON with this EXACT structure:
{
  "title": "scenario title using their real property address",
  "severity": "critical" | "important" | "informational",
  "summary": "One paragraph executive summary with real numbers",
  "current_value_estimate": "$X",
  "purchase_price": "$X",
  "mortgage_balance": "$X estimated",
  "closing_costs_estimate": "$X",
  "capital_gains": "$X",
  "exclusion_available": "$X",
  "net_proceeds": "$X",
  "timeline": [
    {"step": 1, "title": "Step title", "description": "Details", "details": [], "flag": null}
  ],
  "tax_implications": ["Implication 1", "Implication 2"],
  "action_items": [
    {"priority": "high", "title": "Action", "description": "Details", "effort": "Time estimate"}
  ],
  "recommendations": ["Recommendation 1"],
  "did_you_know": "Relevant property/real estate fact",
  "disclaimer": "This analysis is for planning purposes only and does not constitute legal, tax, or financial advice. Consult qualified professionals before making decisions."
}`,

    wealth: `Return JSON with this EXACT structure:
{
  "title": "scenario title using their real names/business",
  "severity": "critical" | "important" | "informational",
  "summary": "One paragraph executive summary",
  "current_situation": {"key": "value pairs"},
  "proposed_situation": {"key": "value pairs"},
  "savings_breakdown": {
    "annual_tax_savings": "$X",
    "details": ["Detail 1"]
  },
  "steps_to_implement": ["Step 1", "Step 2"],
  "risks_and_considerations": ["Risk 1"],
  "timeline": [
    {"step": 1, "title": "Step title", "description": "Details", "details": [], "flag": null}
  ],
  "action_items": [
    {"priority": "high", "title": "Action", "description": "Details", "effort": "Time estimate"}
  ],
  "recommendations": ["Recommendation 1"],
  "did_you_know": "Relevant wealth/business fact",
  "disclaimer": "This analysis is for planning purposes only and does not constitute legal, tax, or financial advice. Consult qualified professionals before making decisions."
}`,

    kids: `Return JSON with this EXACT structure:
{
  "title": "scenario title using their kids' real names",
  "severity": "critical" | "important" | "informational",
  "summary": "One paragraph executive summary using real names and ages",
  "current_situation": {"key": "value pairs"},
  "proposed_situation": {"key": "value pairs"},
  "savings_breakdown": {
    "annual_tax_savings": "$X",
    "details": ["Detail 1"]
  },
  "timeline": [
    {"step": 1, "title": "Step title", "description": "Details", "details": [], "flag": null}
  ],
  "action_items": [
    {"priority": "high", "title": "Action", "description": "Details", "effort": "Time estimate"}
  ],
  "recommendations": ["Recommendation 1"],
  "did_you_know": "Relevant education/529 fact",
  "disclaimer": "This analysis is for planning purposes only and does not constitute legal, tax, or financial advice. Consult qualified professionals before making decisions."
}`,

    insurance: `Return JSON with this EXACT structure:
{
  "title": "scenario title using their real details",
  "severity": "critical" | "important" | "informational",
  "summary": "One paragraph executive summary",
  "timeline": [
    {"step": 1, "title": "Step title", "description": "Details", "details": [], "flag": null}
  ],
  "financial_impact": {
    "assets_protected": "$X covered by insurance",
    "assets_at_risk": "$X not covered or underinsured",
    "tax_exposure": "$0",
    "breakdown": [
      {"item": "Coverage area", "amount": "$X", "status": "protected" | "at_risk", "goes_to": null, "flag": "Gap note if any"}
    ]
  },
  "action_items": [
    {"priority": "high", "title": "Action", "description": "Details", "effort": "Time estimate"}
  ],
  "recommendations": ["Recommendation 1"],
  "did_you_know": "Relevant insurance fact",
  "disclaimer": "This analysis is for planning purposes only and does not constitute legal, tax, or financial advice. Consult qualified professionals before making decisions."
}`,
  };

  // Map scenario IDs to their specific prompts
  const scenarioPrompts: Record<string, string> = {
    // Estate
    estate_both_die: "Analyze what happens if both spouses/partners die tomorrow. Show the complete estate flow — who gets what, what's protected in the trust vs. exposed to probate, guardian chain for minor children, insurance payouts, and every action item to fix gaps.",
    estate_spouse_dies: "Analyze what happens if only one spouse/partner passes away. Show joint vs. individual asset flow, survivor benefits, next steps for the surviving spouse.",
    estate_incapacitated: "Analyze what happens if the primary account holder becomes incapacitated. Who has power of attorney, healthcare directive decisions, access to accounts, and what gaps exist.",
    estate_wrong_beneficiaries: "Analyze which accounts have beneficiary designations that bypass the trust or go to the wrong people. Show where the money actually goes vs. where they probably want it to go.",
    estate_probate: "Analyze what the probate process would look like for this estate. What's in the trust vs. what isn't, estimated cost and timeline of probate, and what needs to be retitled.",
    estate_kids_early_money: "Analyze what happens if the children need access to trust money before the specified age. Show trust distribution rules, hardship provisions, trustee discretion.",
    estate_guardian_cant_serve: "Analyze what happens if the named guardian can't or won't serve. Show the successor chain, court appointment process, and how to prepare.",

    // Tax
    tax_renovation: `Analyze the tax implications of a home renovation. ${params?.renovation_type ? `Type: ${params.renovation_type}.` : ""} ${params?.budget ? `Budget: $${params.budget}.` : ""} Show potential deductions, energy credits, cost basis increase, and ROI.`,
    tax_hire_kids: "Analyze what happens if they hire their minor children in their business. Show UTMA rules, standard deduction benefits, Roth IRA for minors, and tax savings.",
    tax_roth_conversion: "Analyze the implications of converting Traditional IRA to Roth IRA. Show tax hit now vs. tax-free growth, break-even point, and optimal conversion strategy.",
    tax_529_max: "Analyze maxing out 529 contributions. Show state tax deduction, growth projections, superfunding option, and comparison scenarios.",
    tax_cost_segregation: "Analyze doing a cost segregation study on their property. Show accelerated depreciation potential, year-one deduction, and long-term impact.",
    tax_1031_exchange: "Analyze doing a 1031 exchange. Show deferred capital gains, requirements, timeline, and risks.",
    tax_qcd: "Analyze making a Qualified Charitable Distribution from their IRA. Show tax benefits, eligibility requirements, and optimal strategy.",
    tax_home_office: "Analyze taking the home office deduction. Compare square footage method vs. simplified method and show which saves more.",

    // Home
    home_refinance: `Analyze refinancing the mortgage. ${params?.new_rate ? `New rate: ${params.new_rate}%.` : ""} ${params?.new_term ? `New term: ${params.new_term}.` : ""} Show break-even analysis, monthly savings, and total interest comparison.`,
    home_sell: `Analyze selling the house today. ${params?.sale_price ? `Estimated sale price: $${params.sale_price}.` : ""} Show net proceeds after mortgage payoff, closing costs, capital gains, and exclusion availability.`,
    home_rent_out: "Analyze renting out the house. Show projected cash flow, tax implications, depreciation benefits, and landlord considerations.",
    home_finish_basement: "Analyze finishing the basement. Show cost vs. value added, ROI analysis, permit requirements, and impact on home value.",
    home_solar: "Analyze adding solar panels. Show 30% federal credit, payback period, energy savings, and impact on home value.",
    home_roof_replacement: "Analyze replacing the roof. Show insurance claim process, depreciation schedule, out-of-pocket estimate, and impact on home value.",
    home_transfer_trust: "Analyze transferring the home to their trust. Show why it matters for probate avoidance, deed retitling steps, and considerations.",
    home_value_drop: "Analyze a 20% drop in home value. Show equity impact, underwater scenarios if applicable, strategic options, and long-term outlook.",

    // Wealth
    wealth_llc: "Analyze setting up an LLC for their business. Show liability protection, tax election options, formation steps, and cost.",
    wealth_business_in_trust: "Analyze putting their business in their trust. Show estate planning benefits, succession planning, and tax implications.",
    wealth_sep_ira: "Analyze setting up a SEP-IRA vs Solo 401(k). Show contribution limits, tax savings comparison, and which is better for their situation.",
    wealth_scorp: "Analyze S-Corp election and paying themselves a salary from their LLC. Show FICA savings, reasonable compensation requirements, and implementation steps.",
    wealth_irrevocable_trust: "Analyze creating an irrevocable trust. Show asset protection benefits, estate tax reduction, loss of control trade-off, and when it makes sense.",
    wealth_annual_gifting: "Analyze annual gifting to children. Show $18K exclusion strategy, 529 superfunding option, and lifetime exemption planning.",
    wealth_ilit: "Analyze buying life insurance inside an ILIT (Irrevocable Life Insurance Trust). Show how it removes insurance proceeds from the taxable estate.",
    wealth_utma: "Analyze setting up a UTMA for each child. Show pros, cons, kiddie tax rules, and comparison to 529 plans.",

    // Kids
    kids_529_private_school: "Analyze using 529 funds for private school. Show K-12 withdrawal rules, $10K annual limit, state tax impact, and strategy.",
    kids_scholarships: "Analyze what happens if the kids get scholarships. Show 529 penalty-free withdrawal options, Roth rollover rules, and optimal strategy.",
    kids_superfund_529: "Analyze superfunding the 529 plans. Show 5-year gift tax election, front-loading amount per child, and growth projections.",
    kids_college_costs_double: "Analyze what happens if college costs double by the time their kids attend. Project based on kids' current ages and 529 balances.",
    kids_no_college: "Analyze what happens if one kid doesn't go to college. Show beneficiary change options, Roth rollover, penalty-free alternatives.",

    // Insurance
    insurance_sued: "Analyze what happens if they get sued. Show umbrella coverage analysis, asset exposure, protection gaps, and recommendations.",
    insurance_house_fire: "Analyze what happens if the house burns down. Show full insurance claim walkthrough, coverage gaps, timeline, and living expense coverage.",
    insurance_disability: "Analyze what happens if they become disabled. Show disability coverage gap analysis, income replacement needs, and policy recommendations.",
    insurance_ltc: "Analyze what happens if they need long-term care. Show cost projections, impact without LTC policy, Medicaid planning considerations.",
    insurance_life_not_enough: "Analyze what happens if their life insurance isn't enough. Show coverage gap calculation — income replacement, debts, education costs, and how much more they need.",
  };

  const scenarioInstruction =
    scenarioPrompts[scenarioId] ??
    "Provide a general scenario analysis based on the household data.";

  const responseStructure =
    responseStructures[category] ?? responseStructures["estate"];

  return `${baseInstructions}

SCENARIO: ${scenarioInstruction}

${responseStructure}`;
}

// --- CUSTOM FREEFORM PROMPT BUILDER ---

function buildCustomPrompt(
  query: string,
  householdContext: string,
  documentsUsed: string[],
  documentsMissing: string[]
): string {
  const hasAnyDocs = documentsUsed.length > 0;

  return `You are the "What If?" Scenario Simulator for Haven, a premium estate and home management platform. You have access to this family's financial picture.

${hasAnyDocs
    ? "The user has uploaded documents. Analyze their question thoroughly using their actual data. Be specific — use real names, real dollar amounts, real policy numbers, real dates from their documents."
    : "The user has NOT uploaded relevant documents yet. Provide helpful GENERAL expert advice about their question. Use typical industry numbers, general best practices, and expert guidance. Clearly note that this is general advice, and explain exactly which documents they should upload to get a personalized analysis. Still be thorough and actionable — make the general advice genuinely useful."
  }

${householdContext}

PERSONALIZATION:
- Documents available: ${documentsUsed.join(", ") || "None"}
- Missing documents: ${documentsMissing.join(", ") || "None"}

USER'S QUESTION: "${query}"

Return ONLY valid JSON (no markdown, no code blocks) with this structure:
{
  "title": "Clear, specific title for this scenario",
  "severity": "critical" | "important" | "informational" | "opportunity",
  "summary": "2-3 sentence executive summary of the scenario and its impact on this family",
  "sections": [
    {
      "heading": "Section title",
      "icon": "SF Symbol name (e.g., dollarsign.circle, house.fill, shield.fill)",
      "content": "Detailed analysis text — use real numbers from their documents. Use markdown formatting (bold, bullets) for readability.",
      "highlight": "A key number or fact to call out prominently (optional, can be null)",
      "flag": "good" | "warning" | "critical" | null
    }
  ],
  "financial_impact": {
    "summary_line": "One-line financial impact (e.g., 'Could save $8,400/year in taxes')",
    "details": [
      {"label": "Current situation", "value": "$X"},
      {"label": "After this change", "value": "$Y"},
      {"label": "Net benefit", "value": "$Z/year", "flag": "good"}
    ]
  },
  "timeline": [
    {
      "step": 1,
      "title": "Step title",
      "description": "What to do and when",
      "details": [],
      "flag": null
    }
  ],
  "action_items": [
    {
      "priority": "critical" | "high" | "medium" | "low",
      "title": "Specific action to take",
      "description": "Why and how",
      "effort": "5 minutes / 1 hour / Professional needed"
    }
  ],
  "risks_and_considerations": [
    "Risk or downside to consider"
  ],
  "recommendations": [
    "Strategic recommendation based on their overall picture"
  ],
  "related_scenarios": [
    "Other What If questions they should explore based on this analysis"
  ],
  "did_you_know": "An interesting, relevant fact or statistic",
  "confidence_level": "high" | "medium" | "low",
  "confidence_note": "What additional documents or info would improve this analysis",
  "disclaimer": "This analysis is for educational and planning purposes only. Consult qualified professionals before making financial, legal, or tax decisions."
}

IMPORTANT RULES:
- Use ACTUAL numbers from their documents. Never make up account balances, policy numbers, or coverage amounts.
- If you don't have enough data for a specific part, say so explicitly and explain what document they'd need to upload.
- Be honest about uncertainty. If a calculation depends on variables you don't know, provide a range.
- Always include practical action items — not just theory.
- The "related_scenarios" field should suggest 2-3 follow-up questions they might want to explore.
- Make it INTERESTING. Include the "did_you_know" fact. Use real-world examples and comparisons.
- For tax scenarios: always note "consult your CPA" but still give specific, useful analysis.
- For legal scenarios: always note "consult your attorney" but still explain the concepts clearly.
- The "severity" field: use "opportunity" for scenarios where they could benefit from taking action (green/positive framing), "informational" for neutral analysis, "important" for things they should address soon, "critical" for urgent gaps or risks.
- Include 3-5 sections that logically break down the analysis.
- The "sections" array is the main content — structure it however makes sense for the question.`;
}

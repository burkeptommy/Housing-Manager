// Haven Edge Function: research-project
// Receives a home improvement project description, calls Claude to research
// realistic costs, materials, and tips, and optionally updates the property_projects record.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ResearchRequest {
  project_name: string;
  category?: string;
  description?: string;
  property_location?: string;
  project_id?: string;
  user_toolkit?: string[];
  freeform?: boolean;
  style_preferences?: string;
  pinterest_url?: string;
  project_type?: string; // "diy" | "professional" | "undecided"
  inspiration_images?: string[]; // base64-encoded JPEG images
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
    const body: ResearchRequest = await req.json();
    const { project_name, category, description, property_location, project_id, user_toolkit, freeform, style_preferences, pinterest_url, project_type, inspiration_images } = body;
    const isProProject = project_type === "professional";
    const isDiyProject = project_type === "diy";
    const hasInspirationImages = inspiration_images && inspiration_images.length > 0;

    // --- FETCH PINTEREST STYLE CONTEXT (best-effort) ---
    let pinterestContext = "";
    if (pinterest_url && pinterest_url.includes("pinterest.com")) {
      try {
        console.log(`[research-project] Fetching Pinterest board: ${pinterest_url}`);
        const pinterestRes = await fetch(pinterest_url, {
          headers: {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html",
          },
        });
        if (pinterestRes.ok) {
          const html = await pinterestRes.text();
          const descriptions: string[] = [];

          // Pinterest embeds pin data as __PWS_DATA__ JSON in a script tag
          const pwsMatch = html.match(/__PWS_DATA__[^>]*>([\s\S]*?)<\/script>/);
          if (pwsMatch?.[1]) {
            try {
              const pwsData = JSON.parse(pwsMatch[1]);
              // Walk the JSON tree to find pin descriptions and titles
              const extract = (obj: unknown, depth = 0): void => {
                if (depth > 8 || descriptions.length >= 30) return;
                if (typeof obj === "string" && obj.length > 15 && obj.length < 300
                    && !obj.includes("pinterest") && !obj.includes("http")
                    && !obj.includes("<") && !obj.match(/^[0-9a-f-]+$/)) {
                  descriptions.push(obj);
                }
                if (Array.isArray(obj)) {
                  for (const item of obj.slice(0, 50)) extract(item, depth + 1);
                } else if (obj && typeof obj === "object") {
                  const record = obj as Record<string, unknown>;
                  // Prioritize known description fields
                  for (const key of ["description", "title", "closeup_description", "grid_title", "seo_title", "rich_summary"]) {
                    if (typeof record[key] === "string" && (record[key] as string).length > 10) {
                      descriptions.push(record[key] as string);
                    }
                  }
                  for (const val of Object.values(record).slice(0, 20)) {
                    extract(val, depth + 1);
                  }
                }
              };
              extract(pwsData);
            } catch { /* JSON parse of PWS data failed — not critical */ }
          }

          // Fallback: extract alt/title attributes from HTML
          if (descriptions.length === 0) {
            const titleMatches = html.match(/(?:alt|title|aria-label)="([^"]{15,200})"/gi) ?? [];
            for (const m of titleMatches) {
              const text = m.replace(/^(?:alt|title|aria-label)="/i, "").replace(/"$/, "");
              if (!text.includes("Pinterest") && !text.includes("Sign up") && text.length > 15) {
                descriptions.push(text);
              }
            }
          }

          // Deduplicate and cap
          const unique = [...new Set(descriptions)].slice(0, 20);
          if (unique.length > 0) {
            pinterestContext = `Pinterest board references these styles/items: ${unique.join("; ")}`;
            console.log(`[research-project] Extracted ${unique.length} Pinterest descriptions`);
          } else {
            // Even if we couldn't extract descriptions, use the URL as a hint
            const query = pinterest_url.match(/[?&]q=([^&]+)/)?.[1];
            if (query) {
              pinterestContext = `Pinterest search query: ${decodeURIComponent(query).replace(/\+/g, " ")}`;
              console.log(`[research-project] Using Pinterest search query as style hint`);
            }
          }
        }
      } catch (err) {
        console.warn(`[research-project] Pinterest fetch failed (non-blocking): ${err}`);
      }
    }

    // Build style context — Pinterest takes precedence when provided
    const hasPinterest = pinterestContext.length > 0;
    const styleContext = hasPinterest
      ? `PINTEREST BOARD (PRIMARY STYLE REFERENCE — match this aesthetic above all else): ${pinterestContext}${style_preferences ? `\n\nAdditional preferences from user: ${style_preferences}` : ""}`
      : style_preferences || "";
    const hasStyle = styleContext.length > 0;

    if (!project_name) {
      return new Response(
        JSON.stringify({ error: "Missing project_name" }),
        { status: 400, headers }
      );
    }

    // For freeform/quick-entry mode, category is optional and will be auto-detected
    const isFreeform = freeform || !category;
    const effectiveCategory = category || "auto-detect";

    console.log(
      `[research-project] Researching: "${project_name}" (${effectiveCategory}${isFreeform ? ", freeform" : ""})${project_id ? ` project_id=${project_id}` : ""}`
    );

    // --- BUILD LOCATION CONTEXT ---
    const locationContext = property_location
      ? `The property is located in ${property_location}. Factor in regional pricing, local permit requirements, and any climate or code considerations specific to this area.`
      : "No specific property location was provided. Use national average pricing for the United States.";

    // --- BUILD TOOLKIT CONTEXT ---
    const toolkitContext = !isProProject && user_toolkit && user_toolkit.length > 0
      ? `\n\nIMPORTANT: The user already owns these tools: ${user_toolkit.join(", ")}. Do NOT include any of these in typicalItems. The user does not need to buy them again.`
      : "";

    // --- BUILD PROJECT TYPE CONTEXT ---
    const projectTypeContext = isProProject
      ? `\n\nIMPORTANT — THIS IS A "HIRE A PRO" PROJECT:
The homeowner plans to hire a contractor for this project. Do NOT include:
- Tools, tool rentals, or equipment the contractor would bring
- Construction consumables the contractor provides (screws, nails, adhesives, tape, drop cloths, sandpaper, etc.)
- Safety equipment (respirators, gloves, glasses, etc.)
- Dumpster/disposal rentals (contractors include this in their bids)

DO include:
- Design selections the homeowner decides on (fixtures, finishes, appliances, paint colors, tile, countertops, cabinet style, hardware/pulls, lighting)
- Permits (homeowner often pays separately)
- Items the homeowner might purchase themselves to save money or get exactly what they want (e.g., a specific faucet, light fixture, or appliance)

The typicalItems list should focus on the DESIGN CHOICES and MATERIALS the homeowner selects — the things that define the look and feel of the finished project. The contractor handles everything else.`
      : isDiyProject
      ? `\n\nThis is a DIY project. Include a comprehensive list of everything the homeowner needs to buy, rent, or pay for — tools, materials, safety equipment, permits, disposal, etc. Be thorough about commonly forgotten items.`
      : "";

    // --- BUILD PROMPTS ---
    const systemPrompt = `You are a home improvement cost estimator and project research assistant for Haven, a home management app. You MUST return ONLY valid JSON — no markdown code fences, no backticks, no explanation outside the JSON object. Start your response with { and end with }.

Your job is to provide realistic, detailed cost estimates for home improvement projects. Follow these rules:

1. Use real 2025-2026 retail pricing. For design items (finishes, fixtures, furniture, lighting, decor), source from aspirational retailers: Crate & Barrel, Pottery Barn, West Elm, Restoration Hardware, Arhaus, CB2, Article, Rejuvenation, Lumens, Serena & Lily, Wayfair, Anthropologie, Ballard Designs, or Ethan Allen. For construction items (tools, lumber, hardware, safety), use Home Depot, Lowe's, or Menards.
2. Always include a waste factor (usually 10-15% for materials) in your estimates.
3. Include commonly forgotten items — underlayment, fasteners, adhesives, primers, drop cloths, disposal fees, permit fees, tool rentals, etc. Homeowners consistently underestimate because they forget these things.
4. Be honest about difficulty. If a project looks simple but has gotchas (e.g., asbestos abatement, load-bearing walls, plumbing rough-in), call them out clearly.
5. Pro costs should reflect real contractor pricing including labor, overhead, markup, and profit margin — not just labor + materials.
6. DIY costs should include tool rentals or purchases that a typical homeowner wouldn't already own.
7. For the items list, use specific product names and real unit prices where possible rather than vague categories.
8. Timeframes should reflect realistic DIY pace (weekends only) vs. professional pace.${toolkitContext}${projectTypeContext}
${hasStyle ? `
STYLE PREFERENCES:
${styleContext}
` : `
No specific style preferences were provided. Suggest a tasteful, broadly appealing design direction based on current 2025-2026 trends for this type of project. Choose a cohesive aesthetic that would work well in most homes.
`}
DESIGN VISION — ALWAYS INCLUDE:
The response MUST always include these design fields:
- "designMoodDescription": 2-3 sentence evocative description of the overall aesthetic vision — paint a picture of how the finished space will look and feel
- "styleNotes": Explain how your specific product suggestions create a cohesive look
- "colorPalette": Array of 5-7 colors that define the complete palette. MUST include specific recommendations for: walls, trim, accent wall (if applicable), ceiling, and any accent colors. Each entry: { "name": "Benjamin Moore Pale Oak OC-20", "hex": "#F5F0E8", "usage": "Main walls throughout", "role": "primary|accent|neutral|trim|ceiling" }. Use REAL paint color names with brand and code when possible (e.g., "Benjamin Moore White Dove OC-17" not just "White").
- "materialPairings": Array of 2-4 material combinations showing how finishes work together, each with { "primary": "White oak engineered hardwood", "secondary": "Brushed brass cabinet pulls", "location": "Floor + kitchen hardware" }

For typicalItems, ALWAYS include a "designGroup" field on each item:
- "design" = items that define the look (finishes, fixtures, lighting, paint, tile, countertops, furniture, decorative hardware, appliances)
- "construction" = items that are structural/utilitarian (lumber, drywall, screws, tools, safety, rentals, permits, disposal, tape, adhesives)

Product sourcing rules:
- Source specific products that match the aesthetic — use brand names and model numbers (e.g., "Delta Trinsic Single Handle Faucet in Champagne Bronze" not "kitchen faucet")
- Match finishes, materials, and design language to the style (e.g., brushed brass hardware for modern farmhouse, walnut stain for mid-century)
- Still provide accurate 2025-2026 retail pricing from real stores
- If a Pinterest board was referenced, match the aesthetic visible in the pin descriptions
- Design items should come FIRST in the typicalItems array, before construction items`;

    const categoryInstruction = isFreeform
      ? `The user described this project in their own words. Determine the best matching category from this list: Kitchen Renovation, Bathroom Renovation, Flooring, Painting, Roofing, Windows & Doors, Deck / Patio, Landscaping, Electrical, Plumbing, HVAC, Basement, Garage, Built-ins & Shelving, Fencing, Siding / Exterior, Insulation, Smart Home, Additions, Other. Include a "detectedCategory" field in your response with the best match, and a "detectedProjectName" with a clean, concise project name.`
      : "";

    const userPrompt = `Research the following home improvement project and provide a detailed cost estimate.

PROJECT: ${project_name}
${!isFreeform ? `CATEGORY: ${effectiveCategory}` : ""}
${description ? `DESCRIPTION: ${description}` : ""}
${categoryInstruction}

LOCATION: ${locationContext}

Return JSON with this EXACT structure:
{${isFreeform ? `
  "detectedCategory": "Best matching category from the list above",
  "detectedProjectName": "Clean, concise project name (e.g., 'Kitchen Cabinet Refacing' not 'I want to redo my kitchen cabinets')",` : ""}
  "projectSummary": "2-3 sentence overview of what this project involves, scope, and key considerations",
  "designMoodDescription": "2-3 sentence evocative description of the finished aesthetic — paint a picture",
  "styleNotes": "How these specific product selections create a cohesive look",
  "colorPalette": [
    { "name": "Real paint color name with brand (e.g. Benjamin Moore White Dove OC-17)", "hex": "#HEXVAL", "usage": "Specific location: Main walls, Trim & doors, Accent wall, Ceiling, Cabinet color, etc.", "role": "primary|accent|neutral|trim|ceiling" }
  ],
  "materialPairings": [
    { "primary": "Main material/finish", "secondary": "Complementary material/finish", "location": "Where they meet" }
  ],
  "typicalItems": [
    {
      "name": "Specific product/material name",
      "category": "materials" | "tools" | "hardware" | "rental" | "permits" | "disposal" | "safety",
      "designGroup": "design" | "construction",
      "necessity": "required" | "optional" | "likely_owned",
      "multiProjectUseful": false,
      "quantity": 1,
      "unit": "each" | "sq ft" | "linear ft" | "gallon" | "bag" | "box" | "bundle" | "day" | "flat fee",
      "price": 29.99,
      "store": "Home Depot" | "Lowe's" | "Crate & Barrel" | "Pottery Barn" | "West Elm" | "Restoration Hardware" | "Arhaus" | "CB2" | "Article" | "Rejuvenation" | "Lumens" | "Wayfair" | "Anthropologie" | "Ballard Designs" | "Ethan Allen" | "Serena & Lily" | "Specialty" | "Online" | "Municipal" | "Rental Center"
    }
  ],
  "estimatedDiyCost": {
    "low": 500,
    "high": 1200,
    "breakdown": [
      {"category": "Materials", "amount": "$400-$800"},
      {"category": "Tools & Rentals", "amount": "$50-$150"},
      {"category": "Permits & Fees", "amount": "$50-$250"}
    ]
  },
  "estimatedProCost": {
    "low": 1500,
    "high": 3500,
    "breakdown": [
      {"category": "Labor", "amount": "$800-$1800"},
      {"category": "Materials (contractor pricing)", "amount": "$500-$1000"},
      {"category": "Overhead & Profit", "amount": "$200-$700"}
    ]
  },
  "tipsAndWarnings": [
    "Practical tip or important warning — be specific and actionable"
  ],
  "suggestedVideoTopics": [
    "YouTube search query that would help a DIYer with this specific project"
  ],
  "permitNotes": "Whether permits are typically required, what type, approximate cost and timeline, and consequences of skipping them",
  "difficultyLevel": "beginner" | "intermediate" | "advanced" | "professional-recommended",
  "estimatedTimeframe": {
    "diy": "e.g., 2-3 weekends",
    "professional": "e.g., 2-4 days"
  },
  "dealRating": "good_value" | "fair" | "premium",
  "dealRatingReason": "Brief explanation of whether typical costs for this project represent good value for what you get",
  "homeValueImpact": {
    "score": 72,
    "label": "High ROI" | "Moderate ROI" | "Low ROI" | "Lifestyle Only",
    "typicalRoi": "70-80%",
    "explanation": "Brief explanation of how this project typically affects home resale value and marketability"
  }
}

IMPORTANT:
- The typicalItems list should be comprehensive — include EVERYTHING someone would need to buy, rent, or pay for. 10-25 items is typical.
- Prices in typicalItems should be per-unit prices. The quantity field handles multiples.
- The low/high cost ranges should reflect the realistic spread for a typical-sized version of this project (e.g., average room size, average home size).
- Include at least 3-5 tips/warnings that are specific to THIS project, not generic advice.
- For necessity: "required" = must buy for the project to succeed. "optional" = improves outcome but not essential (e.g., nicer tape, knee pads, premium finishes). "likely_owned" = common household tools the user probably already has (screwdriver, tape measure, utility knife, drill, level, etc.).
- For multiProjectUseful: set to true for tools and items that are broadly useful beyond this specific project (e.g., a stud finder, cordless drill, or oscillating multi-tool). Set to false for project-specific materials and consumables.
- For homeValueImpact score (0-100): Kitchen/bathroom remodels score 70-85, curb appeal 60-75, maintenance/repair 40-60, purely cosmetic/lifestyle 10-30. Base this on real estate industry data about typical ROI at resale.
- dealRating should assess whether the MEDIAN cost of this project is good value for what you get (not comparing to a user budget).
- Include 2-4 video topic suggestions that would actually help someone doing this project.`;

    // --- CALL CLAUDE ---
    console.log(`[research-project] Calling Claude for: "${project_name}"${hasInspirationImages ? ` (with ${inspiration_images!.length} inspiration images)` : ""}`);

    // Build message content — text-only or multimodal with inspiration images
    let messageContent: unknown;
    if (hasInspirationImages) {
      // Multimodal: include inspiration images for Claude to analyze
      const contentBlocks: unknown[] = [];
      for (const img of inspiration_images!) {
        contentBlocks.push({
          type: "image",
          source: {
            type: "base64",
            media_type: "image/jpeg",
            data: img,
          },
        });
      }
      contentBlocks.push({
        type: "text",
        text: `The user uploaded these inspiration photos showing the aesthetic they want for their project. Analyze the colors, materials, textures, furniture styles, and overall mood visible in these images. Use this visual context to inform all your product recommendations, color palette, and design mood description.\n\n${userPrompt}`,
      });
      messageContent = contentBlocks;
    } else {
      messageContent = userPrompt;
    }

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
            max_tokens: 16384,
            system: systemPrompt,
            messages: [
              {
                role: "user",
                content: messageContent,
              },
            ],
          }),
        }
      );
    } catch (fetchErr) {
      console.error(`[research-project] Fetch to Claude failed:`, fetchErr);
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
        `[research-project] Claude API error (${claudeResponse.status}): ${errText}`
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
          console.error(`[research-project] Model error — check model ID is valid`);
        } else if (claudeResponse.status === 400) {
          errorMessage = "AI request was invalid";
          errorCode = "bad_request";
        } else if (claudeResponse.status >= 500) {
          errorMessage = "AI service is temporarily unavailable";
          errorCode = "ai_unavailable";
        }
        console.error(`[research-project] Parsed error type: ${errType}, message: ${errMsg}`);
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
    let research: Record<string, unknown>;
    try {
      // Strip markdown code fences if present
      let cleaned = aiText.trim();
      if (cleaned.startsWith("```json")) cleaned = cleaned.slice(7);
      else if (cleaned.startsWith("```")) cleaned = cleaned.slice(3);
      if (cleaned.endsWith("```")) cleaned = cleaned.slice(0, -3);
      cleaned = cleaned.trim();

      research = JSON.parse(cleaned);
    } catch {
      // Try extracting JSON from markdown code block or surrounding text
      const jsonMatch = aiText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          research = JSON.parse(jsonMatch[0]);
        } catch {
          console.error("[research-project] Failed to parse extracted JSON");
          research = {
            projectSummary: aiText.substring(0, 500),
            typicalItems: [],
            estimatedDiyCost: { low: 0, high: 0, breakdown: [] },
            estimatedProCost: { low: 0, high: 0, breakdown: [] },
            tipsAndWarnings: [],
            suggestedVideoTopics: [],
            permitNotes: "Unable to parse AI response",
            difficultyLevel: "unknown",
            estimatedTimeframe: { diy: "unknown", professional: "unknown" },
          };
        }
      } else {
        research = {
          projectSummary: aiText.substring(0, 500),
          typicalItems: [],
          estimatedDiyCost: { low: 0, high: 0, breakdown: [] },
          estimatedProCost: { low: 0, high: 0, breakdown: [] },
          tipsAndWarnings: [],
          suggestedVideoTopics: [],
          permitNotes: "Unable to parse AI response",
          difficultyLevel: "unknown",
          estimatedTimeframe: { diy: "unknown", professional: "unknown" },
        };
      }
    }

    // --- ENRICH DESIGN ITEMS WITH PRODUCT IMAGES via Serper (best-effort, parallel) ---
    const serperKey = Deno.env.get("SERPER_API_KEY");
    const items = (research.typicalItems as Array<Record<string, unknown>>) ?? [];

    if (serperKey && items.length > 0) {
      // Only fetch images for design items (finishes, fixtures, furniture, etc.)
      const designItems = items.filter((item) => item.designGroup === "design");
      const itemsToEnrich = designItems.length > 0 ? designItems : items.slice(0, 10);

      console.log(`[research-project] Fetching images for ${itemsToEnrich.length} items via Serper`);

      await Promise.allSettled(
        itemsToEnrich.map(async (item) => {
          try {
            const res = await fetch("https://google.serper.dev/images", {
              method: "POST",
              headers: {
                "X-API-KEY": serperKey,
                "Content-Type": "application/json",
              },
              body: JSON.stringify({ q: `${item.name} ${item.store || ""}`, num: 1 }),
            });
            if (!res.ok) return;
            const data = await res.json();
            const first = (data as any)?.images?.[0];
            if (first) {
              item.imageUrl = first.imageUrl;
              item.productUrl = first.link ?? null;
            }
          } catch {
            // Non-blocking — item just won't have an image
          }
        })
      );

      const enriched = itemsToEnrich.filter((i) => i.imageUrl).length;
      console.log(`[research-project] Enriched ${enriched}/${itemsToEnrich.length} items with images`);
    }

    // --- OPTIONALLY UPDATE property_projects RECORD ---
    console.log(`[research-project] project_id=${project_id}, supabaseUrl=${supabaseUrl ? "set" : "MISSING"}, serviceRoleKey=${serviceRoleKey ? "set" : "MISSING"}`);
    console.log(`[research-project] research keys: ${Object.keys(research).join(", ")}`);
    console.log(`[research-project] has designMoodDescription: ${!!research.designMoodDescription}`);
    if (project_id) {
      try {
        const supabase = createClient(supabaseUrl, serviceRoleKey);

        const diyCost = research.estimatedDiyCost as Record<string, unknown> | undefined;
        const proCost = research.estimatedProCost as Record<string, unknown> | undefined;

        const diyAvg =
          diyCost && typeof diyCost.low === "number" && typeof diyCost.high === "number"
            ? Math.round((diyCost.low + diyCost.high) / 2)
            : null;
        const proAvg =
          proCost && typeof proCost.low === "number" && typeof proCost.high === "number"
            ? Math.round((proCost.low + proCost.high) / 2)
            : null;

        const updatePayload: Record<string, unknown> = {
          ai_research: research,
          ai_research_updated_at: new Date().toISOString(),
        };

        if (diyAvg !== null) {
          updatePayload.estimated_diy_cost = diyAvg;
        }
        if (proAvg !== null) {
          updatePayload.estimated_pro_cost = proAvg;
        }

        // If freeform, update project name and category from AI detection
        if (isFreeform) {
          const detected = research as Record<string, unknown>;
          if (detected.detectedCategory && typeof detected.detectedCategory === "string") {
            updatePayload.category = detected.detectedCategory;
          }
          if (detected.detectedProjectName && typeof detected.detectedProjectName === "string") {
            updatePayload.name = detected.detectedProjectName;
          }
        }

        console.log(`[research-project] Attempting update with payload keys: ${Object.keys(updatePayload).join(", ")}`);
        console.log(`[research-project] ai_research size: ${JSON.stringify(updatePayload.ai_research).length} bytes`);

        const { error: updateError, data: updateData } = await supabase
          .from("property_projects")
          .update(updatePayload)
          .eq("id", project_id)
          .select("id, ai_research");

        console.log(`[research-project] Update result: error=${updateError?.message ?? "none"}, rows=${updateData?.length ?? 0}, ai_research_saved=${updateData?.[0]?.ai_research != null}`);

        if (updateError) {
          console.error(
            `[research-project] Failed to update property_projects: ${updateError.message}`
          );
          // Don't fail the whole request — still return the research
        } else {
          console.log(
            `[research-project] Updated property_projects ${project_id} with research data`
          );
        }
      } catch (dbErr) {
        console.error(`[research-project] DB update error:`, dbErr);
      }
    }

    console.log(`[research-project] Success for: "${project_name}"`);

    return new Response(
      JSON.stringify({ success: true, research }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error("[research-project] Error:", err);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        detail: String(err),
      }),
      { status: 500, headers }
    );
  }
});

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
  "Appraisal Report","Home Inspection Report",
  "Life Insurance","Umbrella Insurance","Homeowners Insurance","Auto Insurance","Flood Insurance",
  "Jewelry/Art Rider","Long-Term Care Insurance","Disability Insurance","Directors & Officers Insurance",
  "Brokerage Account","Retirement Account (IRA/401k)","Bank Account","529 Plan",
  "Beneficiary Designation","Stock Options/RSUs","Crypto Wallet","Alternative Investments","Vehicle Loan Statement",
  "Federal Tax Return","State Tax Return","Gift Tax Return (Form 709)","Property Tax Record",
  "Estate & Trust Return (Form 1041)","K-1 Partnership Return",
  "Vehicle Title","Vehicle Registration","Vehicle Purchase/Lease Agreement","Emissions Inspection",
  "Art Appraisal","Jewelry Appraisal","Collectibles Documentation","Boat/Aircraft Registration",
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

    // --- FETCH PROPERTY CONTEXT ---
    const supabase = createClient(supabaseUrl, serviceRoleKey);
    let propertyContext = "";
    try {
      const { data: properties } = await supabase
        .from("properties")
        .select("id, name, street, city, state, zip_code")
        .eq("household_id", household_id)
        .limit(5);
      if (properties && properties.length > 0) {
        const propList = properties.map((p: any) =>
          `- "${p.name}": ${[p.street, p.city, p.state, p.zip_code].filter(Boolean).join(", ")} (id: ${p.id})`
        ).join("\n");
        propertyContext = `\n\nThe user owns these properties:\n${propList}\nIf this document relates to one of these properties (matching address, property name, or location), include the property_id in your response.`;
      }
    } catch { /* non-blocking */ }

    // --- BUILD CLAUDE REQUEST ---
    const messages_content: Array<Record<string, unknown>> = [];

    if (text) {
      messages_content.push({
        type: "text",
        text: `Category hint: ${category ?? "Unknown"}\nTitle: ${document_title ?? "Unknown"}\n\nDocument text:\n${text}`,
      });
    } else {
      // Detect media type — PDFs use "document" type, images use "image" type
      // Also accept content_type hint from the caller
      const contentTypeHint = body.content_type as string | undefined;
      let mediaType = contentTypeHint || "image/jpeg";
      if (image_base64.startsWith("/9j/")) mediaType = "image/jpeg";
      else if (image_base64.startsWith("iVBOR")) mediaType = "image/png";
      else if (image_base64.startsWith("JVBER")) mediaType = "application/pdf";
      else if (image_base64.startsWith("R0lG")) mediaType = "image/gif";
      else if (image_base64.startsWith("UklG")) mediaType = "image/webp";

      const isPdf = mediaType === "application/pdf";
      messages_content.push(
        isPdf
          ? { type: "document", source: { type: "base64", media_type: mediaType, data: image_base64 } }
          : { type: "image", source: { type: "base64", media_type: mediaType, data: image_base64 } }
      );
      messages_content.push({
        type: "text",
        text: `Category hint: ${category ?? "Unknown"}\nTitle: ${document_title ?? "Unknown"}\n\nAnalyze this document. Extract all text and include in "extracted_text" field.`,
      });
    }

    // --- CALL CLAUDE WITH RETRY ---
    console.log("[analyze] Calling Claude API...");
    const t0 = Date.now();

    const claudeRequestBody = JSON.stringify({
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
  "cross_reference_suggestions": ["category names"],
  "vendor_info": {
    "name": "company/business name or null",
    "phone": "phone number or null",
    "email": "email or null",
    "address": "address or null",
    "license": "license/cert number or null",
    "specialties": ["HVAC", "Plumbing", etc.] or []
  },
  "home_systems": [
    {
      "name": "system name (e.g., Central AC, Water Heater, Roof)",
      "category": "HVAC|Plumbing|Electrical|Roofing|Appliance|Security|Other",
      "manufacturer": "brand/manufacturer or null",
      "model": "model number or null",
      "serial": "serial number or null",
      "installDate": "YYYY-MM-DD or null",
      "condition": "good|fair|poor|critical or null",
      "notes": "any relevant details"
    }
  ],
  "maintenance_suggestions": [
    {
      "task": "what needs to be done",
      "urgency": "critical|soon|routine",
      "dueDate": "YYYY-MM-DD or null",
      "estimatedCost": "rough cost estimate or null"
    }
  ],
  "insurance_policy": {
    "type": "auto|home|umbrella|renters|flood|life|other or null",
    "provider": "Carrier name or null",
    "policy_number": "string or null",
    "effective_date": "YYYY-MM-DD or null",
    "expiration_date": "YYYY-MM-DD or null",
    "coverage_amounts": {"dwelling": number, "liability": number, "deductible": number} or null,
    "vehicles_covered": [{"vin": "string", "year": number, "make": "string", "model": "string"}] or [],
    "bundled_policies": ["auto","home","umbrella","renters","flood"] or []
  },
  "property_id": "UUID of the matching property if this document relates to a specific property (from the list below), or null"
}${propertyContext}

EXTRACTION RULES:
- vendor_info: Extract if the document is from a contractor, service company, vendor, or business. Include for: quotes, invoices, service reports, warranties, vendor contracts, repair estimates, inspection reports.
- home_systems: Extract if the document mentions specific home systems, appliances, or equipment. Especially important for: inspection reports (extract ALL systems inspected), warranty cards (extract the covered system), appliance manuals, service reports, completion certificates.
- maintenance_suggestions: Extract if the document recommends maintenance, repairs, or follow-up work. Especially from: inspection reports, service reports, warranty cards (maintenance requirements to keep warranty valid).
- insurance_policy: Extract if this is a declarations page, policy summary, ID card, binder, or any insurance document. The "type" should be the PRIMARY policy type (auto/home/umbrella/etc). The "bundled_policies" list captures any OTHER policy types that appear on the same declaration (e.g. a State Farm dec page that lists both auto AND home gets "auto" as type and ["home"] in bundled_policies). When the user uploads such a declaration we surface both policies in the inbox so they can confirm both with one tap.
- If none of these apply (e.g., a will or passport), return null/empty arrays for those fields.

VEHICLE DETECTION:
- If this document is auto insurance, vehicle title, registration, inspection report, or any vehicle-related document, set category_suggestion to "Auto Insurance" or "Vehicle Title" as appropriate.
- Extract ALL VINs (17-character Vehicle Identification Numbers) found anywhere in the document and include them in extracted_metadata as "detected_vins": ["VIN1", "VIN2"].
- Also extract vehicle details (year, make, model) if mentioned and include as "detected_vehicles": [{"vin": "...", "year": 2024, "make": "Tesla", "model": "Model Y"}].
- For auto insurance documents that list multiple vehicles, extract ALL vehicles listed on the policy.

CLASSIFICATION RULES (follow strictly):
- "Employment Agreement" means a SIGNED CONTRACT between employer and employee with terms of employment, compensation, termination clauses, etc. Do NOT use this for resumes, CVs, cover letters, or job descriptions.
- Resumes, CVs, cover letters, job descriptions, LinkedIn profiles, and career documents → "Other Personal Documents" with an info flag.
- School transcripts, diplomas, report cards, course materials → "Other Personal Documents"
- Any document NOT directly relevant to home management, estate planning, insurance, financial records, property, or personal identification → "Other Personal Documents" with an info flag.

If analyzing an image, also include "extracted_text" with all readable text.
Return ONLY JSON. No markdown. No explanation.`,
      messages: [{ role: "user", content: messages_content }],
    });

    let claudeData: Record<string, unknown> | null = null;
    let lastClaudeError = "";

    for (let attempt = 1; attempt <= 2; attempt++) {
      try {
        const claudeRes = await fetch("https://api.anthropic.com/v1/messages", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-api-key": anthropicApiKey,
            "anthropic-version": "2023-06-01",
          },
          body: claudeRequestBody,
        });

        console.log(`[analyze] Claude responded in ${Date.now() - t0}ms with status ${claudeRes.status} (attempt ${attempt})`);

        if (claudeRes.ok) {
          claudeData = await claudeRes.json();
          break;
        }

        const errText = await claudeRes.text();
        lastClaudeError = `${claudeRes.status}: ${errText.substring(0, 300)}`;
        console.error(`[analyze] Claude error (attempt ${attempt}): ${lastClaudeError}`);

        // Don't retry on 4xx client errors
        if (claudeRes.status >= 400 && claudeRes.status < 500) break;

        if (attempt < 2) await new Promise(r => setTimeout(r, 2000));
      } catch (fetchErr) {
        lastClaudeError = String(fetchErr);
        console.error(`[analyze] Fetch error (attempt ${attempt}): ${lastClaudeError}`);
        if (attempt < 2) await new Promise(r => setTimeout(r, 2000));
      }
    }

    if (!claudeData) {
      return new Response(
        JSON.stringify({
          error: `Claude API error`,
          detail: lastClaudeError.substring(0, 200),
        }),
        { status: 502, headers }
      );
    }

    const rawText = (claudeData as any).content?.[0]?.text ?? "";

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

      // NOTE: content_hash is now set at document creation time (receive-email, process-inbox-item,
      // DocumentUploadManager). No longer computed here to avoid race conditions or hash mismatches.

      // Update document record (including property_id if AI matched a property)
      const docUpdate: Record<string, unknown> = {
        ai_summary: analysis.summary,
        ai_flags: analysis.flags ?? [],
        category: analysis.category_suggestion,
        metadata: {
          cross_references: analysis.cross_reference_suggestions ?? [],
          extracted_metadata: analysis.extracted_metadata ?? {},
        },
      };
      if (analysis.property_id) {
        docUpdate.property_id = analysis.property_id;
        console.log(`[analyze] Auto-linked to property: ${analysis.property_id}`);
      }
      svc.from("documents").update(docUpdate).eq("id", document_id).then(({ error }) => {
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

      // Auto-create vendor if extracted
      const vendorInfo = analysis.vendor_info as Record<string, unknown> | null;
      if (vendorInfo?.name && (vendorInfo?.phone || vendorInfo?.email)) {
        const vendorName = vendorInfo.name as string;
        // Check if vendor already exists
        svc.from("contractors")
          .select("id")
          .eq("household_id", household_id)
          .ilike("company_name", `%${vendorName}%`)
          .limit(1)
          .then(async ({ data: existing }) => {
            if (!existing || existing.length === 0) {
              const { error: vErr } = await svc.from("contractors").insert({
                household_id,
                company_name: vendorName,
                phone: (vendorInfo.phone as string) || "Not provided",
                email: vendorInfo.email as string || null,
                address: vendorInfo.address as string || null,
                license_number: vendorInfo.license as string || null,
                specialties: (vendorInfo.specialties as string[])?.length > 0 ? vendorInfo.specialties : null,
                notes: `Auto-added from document: ${document_title ?? document_id}`,
              });
              if (vErr) console.error("[analyze] Vendor creation failed:", vErr.message);
              else console.log(`[analyze] Auto-created vendor: ${vendorName}`);
            } else {
              console.log(`[analyze] Vendor already exists: ${vendorName}`);
            }
          });
      }

      // --- AUTO-DETECT VINs AND LINK TO VEHICLES ---
      // Extract VINs from the document text and auto-link to matching vehicles.
      // If unmatched VINs are found, store them in metadata for iOS to prompt "Add vehicle?"
      const fullText = `${analysis.summary ?? ""} ${(analysis.extracted_text as string) ?? text ?? ""}`;
      const vinRegex = /\b[A-HJ-NPR-Z0-9]{17}\b/g;
      const detectedVins = [...new Set((fullText.match(vinRegex) ?? []).map((v: string) => v.toUpperCase()))];

      // Also check if the category is auto/vehicle related
      const vehicleCategories = ["Auto Insurance", "Vehicle Title", "Boat/Aircraft Registration"];
      const isVehicleDoc = vehicleCategories.some(c => (analysis.category_suggestion as string)?.includes(c));

      if (detectedVins.length > 0 || isVehicleDoc) {
        console.log(`[analyze] Detected ${detectedVins.length} VIN(s): ${detectedVins.join(", ")}${isVehicleDoc ? " (vehicle-related category)" : ""}`);

        const { data: vehicles } = await svc
          .from("vehicles")
          .select("id, vin, year, make, model")
          .eq("household_id", household_id);

        const matchedVehicleIds: string[] = [];
        const unmatchedVins: string[] = [];

        for (const vin of detectedVins) {
          const match = (vehicles ?? []).find((v: any) => v.vin && v.vin.toUpperCase() === vin);
          if (match) {
            matchedVehicleIds.push(match.id);
            console.log(`[analyze] VIN ${vin} matched vehicle: ${match.year} ${match.make} ${match.model}`);
          } else {
            unmatchedVins.push(vin);
            console.log(`[analyze] VIN ${vin} has no matching vehicle - will prompt user to add`);
          }
        }

        // Link document to the first matched vehicle (documents.vehicle_id is singular)
        if (matchedVehicleIds.length > 0) {
          await svc.from("documents")
            .update({ vehicle_id: matchedVehicleIds[0] })
            .eq("id", document_id);
          console.log(`[analyze] Auto-linked document to vehicle ${matchedVehicleIds[0]}`);
        }

        // Store unmatched VINs and all detected VINs in document metadata for iOS prompt
        if (unmatchedVins.length > 0 || matchedVehicleIds.length > 0) {
          const existingMeta = (docUpdate.metadata as Record<string, unknown>) ?? {};
          docUpdate.metadata = {
            ...existingMeta,
            detected_vins: detectedVins,
            matched_vehicle_ids: matchedVehicleIds,
            unmatched_vins: unmatchedVins,
          };
          // Re-update the document with VIN metadata
          svc.from("documents").update({ metadata: docUpdate.metadata }).eq("id", document_id).then(({ error }) => {
            if (error) console.error("[analyze] VIN metadata update failed:", error.message);
          });
        }
      }

      // Auto-link family members from key_parties
      const keyParties = analysis.key_parties as Array<{ name: string; role: string }> | null;
      if (keyParties && keyParties.length > 0) {
        svc.from("family_members")
          .select("id, first_name, last_name")
          .eq("household_id", household_id)
          .then(async ({ data: members }) => {
            if (!members || members.length === 0) return;
            for (const party of keyParties) {
              const partyName = (party.name || "").toLowerCase();
              if (!partyName || partyName.length < 3) continue;
              const matched = members.find((m: any) => {
                const first = (m.first_name || "").toLowerCase();
                const last = (m.last_name || "").toLowerCase();
                return first.length > 1 && last.length > 1
                  && partyName.includes(first) && partyName.includes(last);
              });
              if (matched) {
                const { error: linkErr } = await svc.from("document_family_members").upsert({
                  document_id,
                  family_member_id: matched.id,
                }, { onConflict: "document_id,family_member_id" });
                if (linkErr) {
                  console.warn(`[analyze] Family member link failed for ${matched.first_name}: ${linkErr.message}`);
                } else {
                  console.log(`[analyze] Linked document to family member: ${matched.first_name} ${matched.last_name}`);
                }
              }
            }
          });
      }

      // Auto-create home systems if extracted (for inspection reports, warranty cards, etc.)
      // SKIP auto-creating systems/tasks for invoices, quotes, and bills.
      // Invoices go through process-invoice for task completion.
      // Quotes go through project flow for quote analysis.
      const invoiceAndQuoteCategories = ["Home Bill/Invoice", "Project Invoice", "Repair Estimate", "Contractor Quote", "Utility Bill"];
      const docCategory = (analysis.category_suggestion as string) ?? category ?? "";
      const isInvoice = invoiceAndQuoteCategories.some(c => docCategory.toLowerCase().includes(c.toLowerCase()));
      const homeSystems = analysis.home_systems as Array<Record<string, unknown>> | null;
      if (homeSystems && homeSystems.length > 0 && !isInvoice) {
        // Get property for this household
        svc.from("properties")
          .select("id")
          .eq("household_id", household_id)
          .limit(1)
          .then(async ({ data: props }) => {
            const propertyId = props?.[0]?.id;
            if (!propertyId) return;

            for (const sys of homeSystems) {
              const sysName = sys.name as string;
              if (!sysName) continue;

              // Check if system already exists
              const { data: existingSys } = await svc.from("home_systems")
                .select("id")
                .eq("property_id", propertyId)
                .ilike("name", `%${sysName}%`)
                .limit(1);

              if (!existingSys || existingSys.length === 0) {
                const { error: sysErr } = await svc.from("home_systems").insert({
                  household_id,
                  property_id: propertyId,
                  name: sysName,
                  category: (sys.category as string) || "Other",
                  manufacturer: (sys.manufacturer as string) || null,
                  model_number: (sys.model as string) || null,
                  serial_number: (sys.serial as string) || null,
                  install_date: (sys.installDate as string) || null,
                  notes: `Auto-added from document: ${document_title ?? "uploaded document"}. ${(sys.notes as string) || ""}`.trim(),
                });
                if (sysErr) console.error(`[analyze] System creation failed for ${sysName}:`, sysErr.message);
                else console.log(`[analyze] Auto-created home system: ${sysName}`);
              }
            }
          });
      }

      // Auto-create maintenance tasks from suggestions
      // Also skip auto-creating maintenance tasks for invoices (invoice intelligence handles this)
      const maintSuggestions = analysis.maintenance_suggestions as Array<Record<string, unknown>> | null;
      if (maintSuggestions && maintSuggestions.length > 0 && !isInvoice) {
        svc.from("properties")
          .select("id")
          .eq("household_id", household_id)
          .limit(1)
          .then(async ({ data: props }) => {
            const propertyId = props?.[0]?.id;
            if (!propertyId) return;

            for (const maint of maintSuggestions) {
              const taskName = maint.task as string;
              if (!taskName) continue;

              const dueDate = (maint.dueDate as string) || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split("T")[0];
              const { error: mErr } = await svc.from("maintenance_tasks").insert({
                household_id,
                property_id: propertyId,
                title: taskName,
                frequency: "once",
                next_due_date: dueDate,
                priority: maint.urgency === "critical" ? "high" : maint.urgency === "soon" ? "medium" : "low",
                notes: `Auto-suggested from document analysis. ${(maint.estimatedCost as string) ? `Estimated cost: ${maint.estimatedCost}` : ""}`.trim(),
              });
              if (mErr) console.error(`[analyze] Maintenance task creation failed for ${taskName}:`, mErr.message);
              else console.log(`[analyze] Auto-created maintenance task: ${taskName}`);
            }
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
        metadata: {
          model: "claude-sonnet-4-6",
          category: analysis.category_suggestion,
          auto_created_vendor: !!vendorInfo?.name,
          auto_created_systems: homeSystems?.length ?? 0,
          auto_created_maintenance: maintSuggestions?.length ?? 0,
        },
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

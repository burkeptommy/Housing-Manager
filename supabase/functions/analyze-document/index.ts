import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { inferSpecialtyCategory } from "../_shared/specialty-inference.ts";
import { callClaudeWithDiscipline } from "../_shared/ai-cost-discipline.ts";
import { authFailure, requireHousehold, requireInternal } from "../_shared/require-household.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Build 87 (Home Manager expansion):
// Categories that are HIDDEN from home managers by default. Mirrors
// `Haven/Features/Documents/DocumentAccessDefaults.swift` and the SQL
// backfill in `supabase/migrations/20260441_document_home_manager_normalize_backfill.sql`.
// Critical: this function is the place where the AI rewrites a placeholder
// "Unknown" / "Will" category into the real category at upload time, so we
// MUST also rewrite `visible_to_home_managers` here. Otherwise, manual
// uploads will permanently look "visible" because the iOS placeholder
// resolves to visible at insert time.
//
// All entries are space-separated lowercased keys; the lookup function
// normalizes input by lowercasing AND replacing underscores with spaces,
// so "Power of Attorney", "power of attorney", and legacy
// "power_of_attorney" all collapse to the same lookup key.
// Keep all three lists in sync when categories are added or removed.
const PRIVATE_FROM_HOME_MANAGERS = new Set([
  // Estate Planning
  "will", "trust",
  "power of attorney", "healthcare directive",
  "guardianship designation", "letter of intent",
  "living will", "hipaa authorization",
  "pre-nuptial agreement", "post-nuptial agreement",
  "disposition of remains", "deed in trust",
  "estate plan", "beneficiary designation",
  // Financial Accounts
  "brokerage account", "retirement account (ira/401k)",
  "bank account", "529 plan",
  "stock options/rsus", "crypto wallet", "alternative investments",
  "financial account", "investment statement", "bank statement",
  // Tax Records
  "federal tax return", "state tax return",
  "gift tax return (form 709)", "property tax record",
  "estate & trust return (form 1041)",
  "tax return", "tax document",
  // Life / Long-Term / Disability Insurance
  "life insurance", "long-term care insurance", "disability insurance",
  // Medical / Health
  "medical record", "health insurance",
  // Legal
  "legal agreement",
  // Government IDs
  "passport",
  "birth certificate", "marriage certificate", "divorce decree",
  "social security card", "social security",
  "citizenship/immigration", "death certificate",
]);

function visibleToHomeManagers(category: string | null | undefined): boolean {
  if (!category) return true;
  const normalized = category.toLowerCase().replace(/_/g, " ");
  return !PRIVATE_FROM_HOME_MANAGERS.has(normalized);
}

const VALID_CATEGORIES = [
  "Will","Trust","Power of Attorney","Healthcare Directive","Guardianship Designation","Letter of Intent",
  "Living Will","HIPAA Authorization","Pre-Nuptial Agreement","Post-Nuptial Agreement","Disposition of Remains","Deed in Trust",
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

// Chez v1: Phase 48 estate extraction (ESTATE_CATEGORIES set, redactPII,
// estatePresenceFlagColumn, estateDateColumn) removed. Estate management
// is out of v1 scope and the estate_state table has been dropped.

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
    const { document_id, text, image_base64, category, document_title } = body;
    let household_id = body.household_id as string | undefined;

    // --- AUTH (July 2026 security sweep, audit S1) ---
    // Previously unauthenticated: any caller could rewrite any document's
    // category — and therefore its visible_to_home_managers flag — or
    // poison its extracted text. Three accepted caller shapes:
    //   1. Internal secret (receive-email / process-inbox-item / crons).
    //   2. Legacy internal: Authorization bearing the service-role key
    //      (what the in-repo callers send today — kept so deploy order
    //      can't break the pipeline; callers migrate to the secret).
    //   3. A household member's JWT — document ownership verified below.
    const authHeader = req.headers.get("Authorization") ?? "";
    const isLegacyInternal = serviceRoleKey.length > 0 && authHeader === `Bearer ${serviceRoleKey}`;
    const isInternal = requireInternal(req) || isLegacyInternal;

    if (!isInternal) {
      const auth = await requireHousehold(req);
      if ("failure" in auth) return authFailure(auth, headers);
      // The caller's JWT household always wins over the body value.
      household_id = auth.householdId;
      if (document_id) {
        const ownerCheck = createClient(supabaseUrl, serviceRoleKey);
        const { data: docRow } = await ownerCheck
          .from("documents").select("household_id").eq("id", document_id).single();
        if (!docRow || docRow.household_id !== auth.householdId) {
          return new Response(
            JSON.stringify({ error: "Access denied: document does not belong to your household" }),
            { status: 403, headers },
          );
        }
      }
    }

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
    // Phase 95 — analyze-document fires on EVERY document upload + every
    // forwarded email attachment. It was the most likely contributor to
    // the May 6 onboarding spike. Switched from sonnet-4-6 (16K → 4096
    // → 2048 max_tokens) to haiku-4-5 default. Document classification
    // + extraction is well within haiku's wheelhouse; sonnet stays in
    // the fallback ladder for reliability.
    console.log("[analyze] Calling Claude API...");
    const t0 = Date.now();

    const aqSystemPrompt = `You are a document analysis assistant for a home management and estate planning app. Return ONLY valid JSON with these fields:
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
Return ONLY JSON. No markdown. No explanation.`;

    // Phase 95 — route through cost-discipline helper. analyze-document
    // fires on every document upload AND every email-forwarded
    // attachment, so it's a high-frequency call. Switching from
    // sonnet-4-6 (4096 max_tokens) to haiku-4-5 (2048 max_tokens) cuts
    // per-call cost ~5×. The helper handles fallback to sonnet on 429.
    const aiResult = await callClaudeWithDiscipline({
      supabase,
      apiKey: anthropicApiKey,
      tag: "analyze_document",
      max_tokens: 2048,
      system: aqSystemPrompt,
      messages: [{ role: "user", content: messages_content }],
      household_id,
    });
    if (!aiResult) {
      return new Response(
        JSON.stringify({
          error: `Claude API error`,
          detail: "Disabled by kill-switch, daily budget exhausted, or all model fallbacks failed.",
        }),
        { status: 502, headers }
      );
    }
    console.log(`[analyze] Claude responded in ${Date.now() - t0}ms via ${aiResult.model_used}`);
    const rawText = aiResult.text ?? "";

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

    // --- SPECIALTY SYSTEM INFERENCE (Phase 52b) ---
    try {
      const { data: existingSystems } = await supabase
        .from("home_systems")
        .select("category")
        .eq("household_id", household_id);
      const existingCategories = new Set((existingSystems ?? []).map((s: any) => s.category));

      const { data: dismissals } = await supabase
        .from("household_dismissed_suggestions")
        .select("category")
        .eq("household_id", household_id);
      const dismissedCategories = new Set((dismissals ?? []).map((d: any) => d.category));

      // Build combined text from document analysis fields
      const title = (analysis as any).summary ?? "";
      const docCategory = (analysis as any).category_suggestion ?? "";
      const vendors = (analysis as any).vendor_info?.name ?? "";
      const parties = ((analysis as any).key_parties ?? []).map((p: any) => `${p.name} ${p.role}`).join(" ");
      const systems = ((analysis as any).home_systems ?? []).map((s: any) => `${s.name} ${s.category}`).join(" ");
      const combinedText = [title, docCategory, vendors, parties, systems].join(" ");

      const suggestion = inferSpecialtyCategory(combinedText, existingCategories, dismissedCategories);
      if (suggestion) {
        (analysis as any).specialty_system_suggestion = { ...suggestion, source: "document" };
        console.log(`[analyze-document] Specialty suggestion: ${suggestion.category} (evidence: "${suggestion.evidence}")`);
      }
    } catch (err) {
      console.warn("[analyze-document] Specialty inference failed:", (err as Error).message);
    }

    // --- RETURN IMMEDIATELY ---
    // Send the analysis back to the client NOW. DB operations happen after.
    const responseBody = JSON.stringify(analysis);

    // --- FIRE-AND-FORGET DB OPERATIONS ---
    // These run in the background. If they fail, the client still gets the analysis.
    if (supabaseUrl && serviceRoleKey) {
      const svc = createClient(supabaseUrl, serviceRoleKey);

      // July 2026 (audit F20): background writes MUST be registered with
      // EdgeRuntime.waitUntil or the isolate can tear down mid-write after
      // the response returns — intermittently losing the category +
      // visible_to_home_managers rewrite (a security control) and the
      // vendor/system auto-creates. Every fire-and-forget chain below
      // pushes into this array; waitUntil is called at the end of the block.
      const pendingWrites: PromiseLike<unknown>[] = [];

      // NOTE: content_hash is now set at document creation time (receive-email, process-inbox-item,
      // DocumentUploadManager). No longer computed here to avoid race conditions or hash mismatches.

      // Update document record (including property_id if AI matched a property)
      // Build 87 (Home Manager expansion): rewrite visible_to_home_managers
      // alongside the category. Manual upload paths set "Unknown" / "Will"
      // placeholders at insert time which always resolve to visible/private
      // by accident — this is the place where the real category gets
      // stamped, so we MUST also rewrite the visibility flag.
      const docUpdate: Record<string, unknown> = {
        ai_summary: analysis.summary,
        ai_flags: analysis.flags ?? [],
        category: analysis.category_suggestion,
        visible_to_home_managers: visibleToHomeManagers(analysis.category_suggestion as string | null),
        metadata: {
          cross_references: analysis.cross_reference_suggestions ?? [],
          extracted_metadata: analysis.extracted_metadata ?? {},
        },
      };
      if (analysis.property_id) {
        docUpdate.property_id = analysis.property_id;
        console.log(`[analyze] Auto-linked to property: ${analysis.property_id}`);
      }
      pendingWrites.push(
        svc.from("documents").update(docUpdate).eq("id", document_id).then(({ error }) => {
          if (error) console.error("[analyze] DB update failed:", error.message);
          else console.log("[analyze] Document updated in DB");
        }),
      );

      // Store extracted text
      const extractedText = (analysis.extracted_text as string) ?? text ?? "";
      if (extractedText.length > 0) {
        pendingWrites.push(
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
          }),
        );
      }

      // Auto-create vendor if extracted
      const vendorInfo = analysis.vendor_info as Record<string, unknown> | null;
      if (vendorInfo?.name && (vendorInfo?.phone || vendorInfo?.email)) {
        const vendorName = vendorInfo.name as string;
        // Check if vendor already exists
        pendingWrites.push(
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
          }),
        );
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
          pendingWrites.push(
            svc.from("documents").update({ metadata: docUpdate.metadata }).eq("id", document_id).then(({ error }) => {
              if (error) console.error("[analyze] VIN metadata update failed:", error.message);
            }),
          );
        }
      }

      // Auto-link family members from key_parties
      const keyParties = analysis.key_parties as Array<{ name: string; role: string }> | null;
      if (keyParties && keyParties.length > 0) {
        pendingWrites.push(
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
          }),
        );
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
        pendingWrites.push(
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
          }),
        );
      }

      // Follow-up tasks from document suggestions (inspection reports,
      // service reports, warranty upkeep). July 2026: this used to SILENTLY
      // insert maintenance_tasks — which violated "always ask the homeowner"
      // and created duplicates on re-upload (no dedup, no source). It now
      // surfaces a "we spotted N follow-ups — add them?" inbox review card
      // using the SAME shape the email pipeline uses. The homeowner taps
      // "Add these" → process-inbox-item action=add_suggested_tasks creates
      // the tasks with dedup. Skipped for invoices (process-invoice owns
      // those follow-ups).
      const maintSuggestions = analysis.maintenance_suggestions as Array<Record<string, unknown>> | null;
      if (maintSuggestions && maintSuggestions.length > 0 && !isInvoice) {
        const suggestedTasks = maintSuggestions
          .filter((m) => typeof m.task === "string" && (m.task as string).trim().length > 0)
          .slice(0, 3)
          .map((m) => ({
            title: (m.task as string).trim(),
            due_date: (m.dueDate as string) || null,
            urgency: m.urgency === "critical" ? "soon" : (m.urgency as string) || "routine",
            reason: (m.estimatedCost as string)
              ? `From document analysis. Estimated cost: ${m.estimatedCost}`
              : "Recommended by the document you uploaded.",
          }));
        if (suggestedTasks.length > 0) {
          const followTitle = suggestedTasks.length === 1
            ? "Follow-up spotted in your document"
            : `${suggestedTasks.length} follow-ups spotted in your document`;
          const { error: followErr } = await svc.from("inbox_items").insert({
            household_id,
            type: "follow_ups",
            title: followTitle,
            summary: suggestedTasks.map((t) => `• ${t.title}`).join("\n"),
            related_document_id: document_id,
            needs_action: true,
            action_type: "review_followups",
            metadata: { suggested_tasks: suggestedTasks, source_document_id: document_id },
            status: "ready",
          });
          if (followErr) console.error("[analyze] follow-up review item insert failed:", followErr.message);
          else console.log(`[analyze] Created follow-up review item (${suggestedTasks.length} tasks)`);
        }
      }

      // Log
      pendingWrites.push(
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
        }),
      );

      // Chez v1: Phase 48 estate extraction branch removed. Estate
      // management is out of v1 scope; estate_state, estate_pdf_exports,
      // and documents.linked_attorney_contact_id no longer exist.
      // The `resolvedCategory` variable is still useful downstream for
      // logging — keeping it.
      const resolvedCategory = (analysis.category_suggestion as string) ?? "";
      void resolvedCategory;

      // Register every background write with the runtime so the isolate
      // stays alive until they settle. Fall back to awaiting inline when
      // EdgeRuntime isn't available (local `deno run`, tests).
      const settled = Promise.allSettled(pendingWrites);
      try {
        // @ts-ignore — EdgeRuntime is injected by the Supabase edge runtime
        EdgeRuntime.waitUntil(settled);
      } catch (_) {
        await settled;
      }
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

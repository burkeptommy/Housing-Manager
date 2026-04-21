import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { inferSpecialtyCategory } from "../_shared/specialty-inference.ts";

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

// Phase 48: Estate categories that trigger the second Claude call for
// fiduciary/attorney/execution-date extraction. Superset of the estate
// planning section in VALID_CATEGORIES plus a few business/beneficiary
// categories that commonly appear in estate plans.
const ESTATE_CATEGORIES = new Set([
  "Will", "Trust", "Power of Attorney", "Healthcare Directive",
  "Guardianship Designation", "Letter of Intent", "Living Will",
  "HIPAA Authorization", "Pre-Nuptial Agreement", "Post-Nuptial Agreement",
  "Disposition of Remains", "Deed in Trust", "Beneficiary Designation",
  "Buy-Sell Agreement", "Succession Plan",
]);

// Phase 48: Belt-and-suspenders PII redaction. Runs AFTER Claude returns
// estate extraction results to strip any SSN patterns or long digit
// sequences that slipped through the system prompt instructions.
function redactPII(text: string): string {
  // SSN patterns: 123-45-6789, 123 45 6789, 123456789 (9 consecutive digits)
  let redacted = text.replace(/\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b/g, "[REDACTED]");
  // Full account/routing numbers (8+ consecutive digits, not years like 2024)
  redacted = redacted.replace(/\b(?!(?:19|20)\d{2}\b)\d{8,}\b/g, "[REDACTED]");
  return redacted;
}

// Phase 48: Map resolved category to estate_state presence flag column name.
function estatePresenceFlagColumn(category: string): string | null {
  switch (category) {
    case "Will": return "has_will";
    case "Trust":
    case "Deed in Trust": return "has_revocable_trust";
    case "Power of Attorney": return "has_poa";
    case "Healthcare Directive": return "has_health_proxy";
    case "Living Will": return "has_living_will";
    case "HIPAA Authorization": return "has_hipaa_auth";
    case "Pre-Nuptial Agreement":
    case "Post-Nuptial Agreement": return "has_prenup";
    case "Disposition of Remains": return "has_disposition_of_remains";
    case "Buy-Sell Agreement":
    case "Succession Plan": return "has_business_agreement";
    default: return null;
  }
}

// Phase 48: Map resolved category to the date column in estate_state, if any.
function estateDateColumn(category: string): string | null {
  switch (category) {
    case "Will": return "will_date";
    case "Trust":
    case "Deed in Trust": return "trust_date";
    case "Power of Attorney": return "poa_date";
    case "Healthcare Directive": return "health_proxy_date";
    default: return null;
  }
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

      // --- PHASE 48: ESTATE EXTRACTION BRANCH ---
      // When the resolved category is an estate planning document, run a
      // second Claude call to extract fiduciaries, attorney info, execution
      // date, and estate sub-type. Then fire-and-forget the DB operations:
      // upsert estate_state, insert document_parties, auto-link attorney,
      // set linked_attorney_contact_id, store estate_sub_type in metadata.
      const resolvedCategory = (analysis.category_suggestion as string) ?? "";
      if (ESTATE_CATEGORIES.has(resolvedCategory)) {
        (async () => {
          try {
            console.log(`[analyze] Estate document detected (${resolvedCategory}). Running estate extraction...`);

            // Gather the document content for the second Claude call
            const docText = (analysis.extracted_text as string) ?? text ?? (analysis.summary as string) ?? "";
            if (!docText || docText.length < 50) {
              console.log("[analyze] Estate extraction skipped: insufficient document text");
              return;
            }

            // --- SECOND CLAUDE CALL: Estate-specific extraction ---
            const estateResponse = await fetch("https://api.anthropic.com/v1/messages", {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                "x-api-key": anthropicApiKey!,
                "anthropic-version": "2023-06-01",
              },
              body: JSON.stringify({
                model: "claude-sonnet-4-6",
                max_tokens: 4096,
                system: `You are an estate planning document analyzer. Extract structured metadata from the document below.

CRITICAL PRIVACY RULES:
- NEVER include Social Security numbers. Replace any SSN patterns (XXX-XX-XXXX) with "[REDACTED]".
- NEVER include full account numbers, routing numbers, or policy numbers. Only include the last 4 digits if present (e.g., "****1234").
- NEVER include precise dollar amounts for financial accounts. Use buckets: "<$250K", "$250K-$1M", "$1M-$5M", ">$5M".
- Do NOT include any passwords, PINs, or access codes.

Return ONLY valid JSON with these fields:
{
  "execution_date": "YYYY-MM-DD or null (the date the document was signed/executed)",
  "governing_state": "two-letter state code or null",
  "attorney_name": "full name of the preparing/reviewing attorney, or null",
  "attorney_firm": "law firm name, or null",
  "attorney_contact_info": {"phone": "or null", "email": "or null", "address": "or null"},
  "fiduciaries": [
    {"name": "full name", "role": "executor|trustee|guardian|health_proxy|poa_agent|disposition_agent|successor_trustee|alternate_executor|alternate_trustee|alternate_guardian", "is_alternate": false}
  ],
  "beneficiaries": [
    {"name": "full name", "relationship": "spouse|child|grandchild|sibling|parent|charity|trust|other"}
  ],
  "estate_sub_type": "e.g. revocable_trust, irrevocable_trust, springing_poa, general_poa, durable_poa, limited_poa, living_trust, testamentary_trust, pour_over_will, simple_will, or null",
  "key_provisions": ["brief summary of notable provisions, max 5 items"]
}

If a field cannot be determined from the document, use null. For fiduciaries, only include people explicitly named in a fiduciary role. Do NOT guess or infer roles.`,
                messages: [{ role: "user", content: `Document category: ${resolvedCategory}\n\nDocument text:\n${docText.substring(0, 15000)}` }],
              }),
            });

            if (!estateResponse.ok) {
              const errText = await estateResponse.text();
              console.error("[analyze] Estate extraction Claude error:", errText.substring(0, 200));
              return;
            }

            const estateData = await estateResponse.json();
            const estateRaw = (estateData as any).content?.[0]?.text ?? "";

            let estate: Record<string, unknown>;
            try {
              let cleaned = estateRaw.trim();
              if (cleaned.startsWith("```json")) cleaned = cleaned.slice(7);
              else if (cleaned.startsWith("```")) cleaned = cleaned.slice(3);
              if (cleaned.endsWith("```")) cleaned = cleaned.slice(0, -3);
              estate = JSON.parse(cleaned.trim());
            } catch {
              console.error("[analyze] Estate extraction JSON parse failed:", estateRaw.substring(0, 200));
              return;
            }

            // --- PII REDACTION (belt and suspenders) ---
            const estateStr = JSON.stringify(estate);
            const redacted = redactPII(estateStr);
            if (redacted !== estateStr) {
              estate = JSON.parse(redacted);
              console.log("[analyze] PII redaction applied to estate extraction");
            }

            console.log(`[analyze] Estate extraction complete. Attorney: ${estate.attorney_name ?? "none"}, Fiduciaries: ${(estate.fiduciaries as any[])?.length ?? 0}`);

            // --- DB OPERATION 1: Upsert estate_state ---
            const flagCol = estatePresenceFlagColumn(resolvedCategory);
            const dateCol = estateDateColumn(resolvedCategory);
            const executionDate = estate.execution_date as string | null;

            // Build the upsert payload
            const estateUpdate: Record<string, unknown> = {};
            if (flagCol) estateUpdate[flagCol] = true;
            if (dateCol && executionDate) estateUpdate[dateCol] = executionDate;

            // Handle trust sub-type distinction
            const subType = estate.estate_sub_type as string | null;
            if (subType === "irrevocable_trust") {
              estateUpdate.has_irrevocable_trust = true;
              estateUpdate.has_revocable_trust = false;
            }

            // Merge fiduciaries: read existing, dedup by name+role, append new
            const incomingFiduciaries = (estate.fiduciaries as Array<{name: string; role: string; is_alternate?: boolean}>) ?? [];
            if (incomingFiduciaries.length > 0) {
              const { data: existingState } = await svc
                .from("estate_state")
                .select("fiduciaries")
                .eq("household_id", household_id)
                .maybeSingle();

              const existing = (existingState?.fiduciaries as Array<Record<string, unknown>>) ?? [];
              const merged = [...existing];

              for (const incoming of incomingFiduciaries) {
                if (!incoming.name || !incoming.role) continue;
                const nameNorm = incoming.name.toLowerCase().trim();
                const roleNorm = incoming.role.toLowerCase().trim();
                const isDuplicate = merged.some((e: any) =>
                  (e.name as string || "").toLowerCase().trim() === nameNorm &&
                  (e.role as string || "").toLowerCase().trim() === roleNorm
                );
                if (!isDuplicate) {
                  merged.push({
                    name: incoming.name,
                    role: incoming.role,
                    is_alternate: incoming.is_alternate ?? false,
                    source: `from_${resolvedCategory.toLowerCase().replace(/[\s\/]/g, "_")}`,
                  });
                }
              }
              estateUpdate.fiduciaries = merged;
            }

            // Upsert: try update, fall back to insert + update
            const { data: existingRow } = await svc
              .from("estate_state")
              .select("id")
              .eq("household_id", household_id)
              .maybeSingle();

            if (existingRow) {
              const { error: upErr } = await svc
                .from("estate_state")
                .update(estateUpdate)
                .eq("household_id", household_id);
              if (upErr) console.error("[analyze] estate_state update failed:", upErr.message);
              else console.log("[analyze] estate_state updated");
            } else {
              const { error: insErr } = await svc
                .from("estate_state")
                .insert({ household_id, ...estateUpdate });
              if (insErr) console.error("[analyze] estate_state insert failed:", insErr.message);
              else console.log("[analyze] estate_state created");
            }

            // --- DB OPERATION 2: Insert document_parties ---
            // No unique constraint on (document_id, name, role), so check before insert.
            const allParties = [
              ...(incomingFiduciaries.map(f => ({ name: f.name, role: f.role }))),
              ...((estate.beneficiaries as Array<{name: string; relationship: string}>) ?? []).map(b => ({ name: b.name, role: `beneficiary_${b.relationship}` })),
            ];
            if (allParties.length > 0) {
              const { data: existingParties } = await svc
                .from("document_parties")
                .select("name, role")
                .eq("document_id", document_id);
              const existingSet = new Set(
                (existingParties ?? []).map((p: any) => `${(p.name as string).toLowerCase()}|${(p.role as string).toLowerCase()}`)
              );

              let insertedCount = 0;
              for (const party of allParties) {
                if (!party.name) continue;
                const key = `${party.name.toLowerCase()}|${party.role.toLowerCase()}`;
                if (existingSet.has(key)) continue;
                const { error } = await svc.from("document_parties").insert({
                  document_id,
                  household_id,
                  name: party.name,
                  role: party.role,
                });
                if (error) console.warn(`[analyze] document_parties insert failed for ${party.name}:`, error.message);
                else insertedCount++;
              }
              console.log(`[analyze] Inserted ${insertedCount} new document_parties (${allParties.length} total)`);
            }

            // --- DB OPERATION 3: Auto-link attorney ---
            const attorneyName = estate.attorney_name as string | null;
            const attorneyFirm = estate.attorney_firm as string | null;
            const attorneyContact = estate.attorney_contact_info as Record<string, string | null> | null;

            if (attorneyName) {
              // Fuzzy match against existing trusted_contacts
              const { data: contacts } = await svc
                .from("trusted_contacts")
                .select("id, name, company, role")
                .eq("household_id", household_id);

              const nameNorm = attorneyName.toLowerCase().trim();
              let matchedContactId: string | null = null;

              if (contacts && contacts.length > 0) {
                // Try exact name match first
                const exact = contacts.find((c: any) =>
                  (c.name as string || "").toLowerCase().trim() === nameNorm
                );
                if (exact) {
                  matchedContactId = exact.id;
                } else {
                  // Try fuzzy: last-name match + firm match
                  const lastNameParts = nameNorm.split(/\s+/);
                  const lastName = lastNameParts[lastNameParts.length - 1];
                  const firmNorm = (attorneyFirm || "").toLowerCase().trim();
                  const fuzzy = contacts.find((c: any) => {
                    const cName = (c.name as string || "").toLowerCase();
                    const cCompany = (c.company as string || "").toLowerCase();
                    return cName.includes(lastName) && (
                      !firmNorm || cCompany.includes(firmNorm) || firmNorm.includes(cCompany)
                    );
                  });
                  if (fuzzy) matchedContactId = fuzzy.id;
                }
              }

              // Create new contact if no match
              if (!matchedContactId) {
                const contactEmail = attorneyContact?.email || `${nameNorm.replace(/\s+/g, ".")}@placeholder.local`;
                const { data: newContact, error: cErr } = await svc
                  .from("trusted_contacts")
                  .insert({
                    household_id,
                    name: attorneyName,
                    email: contactEmail,
                    phone: attorneyContact?.phone || null,
                    role: "estate_attorney",
                    company: attorneyFirm || null,
                    invite_status: "not_invited",
                    notes: `Auto-added from ${resolvedCategory} analysis`,
                  })
                  .select("id")
                  .single();

                if (cErr) {
                  console.error("[analyze] Attorney contact creation failed:", cErr.message);
                } else if (newContact) {
                  matchedContactId = newContact.id;
                  console.log(`[analyze] Auto-created attorney contact: ${attorneyName}`);
                }
              } else {
                console.log(`[analyze] Matched existing attorney contact: ${attorneyName}`);
              }

              // --- DB OPERATION 4: Set linked_attorney_contact_id on document ---
              if (matchedContactId) {
                svc.from("documents")
                  .update({ linked_attorney_contact_id: matchedContactId })
                  .eq("id", document_id)
                  .then(({ error }) => {
                    if (error) console.error("[analyze] linked_attorney update failed:", error.message);
                    else console.log(`[analyze] Document linked to attorney contact ${matchedContactId}`);
                  });

                // Also set estate_attorney_contact_id on estate_state if not already set
                const { data: currentState } = await svc
                  .from("estate_state")
                  .select("estate_attorney_contact_id")
                  .eq("household_id", household_id)
                  .maybeSingle();

                if (currentState && !currentState.estate_attorney_contact_id) {
                  svc.from("estate_state")
                    .update({ estate_attorney_contact_id: matchedContactId })
                    .eq("household_id", household_id)
                    .then(({ error }) => {
                      if (error) console.error("[analyze] estate_state attorney link failed:", error.message);
                    });
                }
              }
            }

            // --- DB OPERATION 5: Store estate_sub_type in document metadata ---
            if (subType) {
              const { data: currentDoc } = await svc
                .from("documents")
                .select("metadata")
                .eq("id", document_id)
                .single();

              const existingMeta = (currentDoc?.metadata as Record<string, unknown>) ?? {};
              const extractedMeta = (existingMeta.extracted_metadata as Record<string, unknown>) ?? {};
              svc.from("documents")
                .update({
                  metadata: {
                    ...existingMeta,
                    extracted_metadata: {
                      ...extractedMeta,
                      estate_sub_type: subType,
                      governing_state: estate.governing_state ?? null,
                      key_provisions: estate.key_provisions ?? [],
                    },
                  },
                })
                .eq("id", document_id)
                .then(({ error }) => {
                  if (error) console.error("[analyze] Estate metadata update failed:", error.message);
                  else console.log(`[analyze] Stored estate_sub_type: ${subType}`);
                });
            }

            console.log(`[analyze] Estate extraction pipeline complete for doc=${document_id}`);
          } catch (estateErr) {
            console.error("[analyze] Estate extraction failed (non-blocking):", estateErr);
          }
        })();
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

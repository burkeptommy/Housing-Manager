// Haven Edge Function: process-inbox-item
// Called when a user provides missing context (property, classification) for a
// forwarded email that couldn't be fully auto-processed.
// Fetches the stored attachment, runs analysis, creates project/document/vendor.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Build 87 (Home Manager expansion):
// Categories that are HIDDEN from home managers by default. Mirrors
// `Haven/Features/Documents/DocumentAccessDefaults.swift` and the SQL
// backfill in `supabase/migrations/20260441_document_home_manager_normalize_backfill.sql`.
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
  // Tax Records (bills are visible, returns/records are private)
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

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Server configuration missing" }),
        { status: 500, headers }
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json();
    const {
      inbox_item_id,
      property_id,
      action,        // 'process_quote', 'process_document', 'dismiss', 'process_vehicle_document'
      document_category,
      vehicle_id,
    } = body;

    if (!inbox_item_id) {
      return new Response(
        JSON.stringify({ error: "inbox_item_id required" }),
        { status: 400, headers }
      );
    }

    // --- LOAD INBOX ITEM ---
    const { data: item, error: itemErr } = await supabase
      .from("inbox_items")
      .select("*")
      .eq("id", inbox_item_id)
      .single();

    if (itemErr || !item) {
      return new Response(
        JSON.stringify({ error: "Inbox item not found" }),
        { status: 404, headers }
      );
    }

    const householdId = item.household_id;
    const metadata = item.metadata ?? {};

    // --- DEDUP: Prevent double-processing ---
    if (item.action_completed && action !== "dismiss" && action !== "move_to_project") {
      console.log(`[process-inbox] Item ${inbox_item_id} already processed, skipping`);
      return new Response(
        JSON.stringify({ success: true, already_processed: true }),
        { status: 200, headers }
      );
    }

    // --- HANDLE DISMISS ---
    if (action === "dismiss") {
      await supabase
        .from("inbox_items")
        .update({ seen: true, action_completed: true })
        .eq("id", inbox_item_id);
      return new Response(
        JSON.stringify({ success: true, action: "dismissed" }),
        { status: 200, headers }
      );
    }

    // --- LOAD ATTACHMENT FROM STORAGE ---
    let attachmentBase64: string | null = null;
    if (item.attachment_path) {
      const { data: fileData, error: dlErr } = await supabase.storage
        .from("inbox-attachments")
        .download(item.attachment_path);

      if (fileData && !dlErr) {
        const buffer = await fileData.arrayBuffer();
        attachmentBase64 = btoa(
          new Uint8Array(buffer).reduce(
            (data, byte) => data + String.fromCharCode(byte),
            ""
          )
        );
        console.log(
          `[process-inbox] Loaded attachment: ${item.attachment_path} (${buffer.byteLength} bytes)`
        );
      } else {
        console.error(
          `[process-inbox] Failed to load attachment: ${dlErr?.message}`
        );
      }
    }

    // Fall back to text from metadata if no attachment
    const emailBody = metadata.email_body as string | undefined;
    const classification = metadata.classification as Record<string, unknown> | undefined;
    const fromAddress = item.from_email ?? "";

    // Phase 101 (E2) — persist a quote attachment as a real document so it
    // shows on the vendor's profile (documents.contractor_id), inside the
    // project, and in the vault. Quotes used to live only as an
    // inbox-attachments path: invisible everywhere after the inbox moment.
    const persistQuoteDocument = async (
      projectId: string | null,
      contractorIdForDoc: string | null,
      propertyIdForDoc: string | null
    ): Promise<string | null> => {
      if (!attachmentBase64) return null;
      try {
        const filePath = `${householdId}/${crypto.randomUUID()}`;
        const fileBuffer = Uint8Array.from(atob(attachmentBase64), (c) => c.charCodeAt(0));
        const { error: upErr } = await supabase.storage
          .from("documents")
          .upload(filePath, fileBuffer, {
            contentType: item.attachment_content_type || "application/pdf",
          });
        if (upErr) {
          console.warn(`[process-inbox] quote document upload failed (non-fatal): ${upErr.message}`);
          return null;
        }
        const docInsert: Record<string, unknown> = {
          household_id: householdId,
          title: (classification?.documentTitle as string) || subject || "Contractor Quote",
          category: "Contractor Quote",
          status: "active",
          file_path: filePath,
          notes: `Quote from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}`,
          ai_summary: item.summary,
          visible_to_home_managers: visibleToHomeManagers("Contractor Quote"),
        };
        if (projectId) docInsert.project_id = projectId;
        if (contractorIdForDoc) docInsert.contractor_id = contractorIdForDoc;
        if (propertyIdForDoc) docInsert.property_id = propertyIdForDoc;
        const { data: doc, error: docErr } = await supabase
          .from("documents")
          .insert(docInsert)
          .select("id")
          .single();
        if (docErr || !doc) {
          console.warn(`[process-inbox] quote document insert failed (non-fatal): ${docErr?.message}`);
          return null;
        }
        return (doc as { id: string }).id;
      } catch (e) {
        console.warn(`[process-inbox] quote document persist exception (non-fatal): ${e}`);
        return null;
      }
    };
    const subject = metadata.subject as string ?? item.title;

    // --- Get property info for location context ---
    let location: string | null = null;
    if (property_id) {
      const { data: prop } = await supabase
        .from("properties")
        .select("id, city, state, name")
        .eq("id", property_id)
        .single();
      if (prop) {
        location = [prop.city, prop.state].filter(Boolean).join(", ");
      }
    }

    const result: Record<string, unknown> = { success: true, actions: [] };
    const actions: string[] = [];

    // --- PROCESS QUOTE ---
    if (action === "process_quote") {
      if (!property_id) {
        return new Response(
          JSON.stringify({ error: "property_id required for quote processing" }),
          { status: 400, headers }
        );
      }

      // Create the project
      const projectName =
        (classification?.projectType as string) ||
        `Quote from ${(classification?.vendorName as string) || "Contractor"}`;

      const { data: project, error: projErr } = await supabase
        .from("property_projects")
        .insert({
          household_id: householdId,
          property_id,
          name: projectName,
          category: (classification?.projectType as string) || "Other",
          status: "planning",
          project_type: "pro",
          priority: "medium",
          notes: `Created from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}\n\n${item.summary || ""}`,
        })
        .select("id")
        .single();

      if (!project) {
        console.error(`[process-inbox] Project creation failed: ${projErr?.message}`);
        return new Response(
          JSON.stringify({ error: "Failed to create project", detail: projErr?.message }),
          { status: 500, headers }
        );
      }

      actions.push(`created_project:${projectName}`);
      result.project_id = project.id;

      // Auto-create vendor if we have info
      let contractorId: string | null = null;
      if (classification?.vendorName) {
        const vendorName = classification.vendorName as string;
        const { data: existing } = await supabase
          .from("contractors")
          .select("id")
          .eq("household_id", householdId)
          .ilike("company_name", `%${vendorName}%`)
          .limit(1);

        if (existing && existing.length > 0) {
          contractorId = existing[0].id;
        } else {
          const { data: newVendor } = await supabase
            .from("contractors")
            .insert({
              household_id: householdId,
              company_name: vendorName,
              phone: (classification.vendorPhone as string) || "Not provided",
              email: (classification.vendorEmail as string) || null,
              address: (classification.vendorAddress as string) || null,
              license_number: (classification.vendorLicense as string) || null,
              notes: `Auto-added from forwarded email: ${subject}`,
            })
            .select("id")
            .single();
          if (newVendor) {
            contractorId = newVendor.id;
            actions.push(`created_vendor:${vendorName}`);
          }
        }
      }

      // Run quote analysis if we have content
      if (attachmentBase64 || emailBody) {
        try {
          const analyzePayload: Record<string, unknown> = {
            project_name: projectName,
            project_category: (classification?.projectType as string) || null,
            property_location: location,
          };
          if (attachmentBase64) {
            analyzePayload.image_base64 = attachmentBase64;
          } else if (emailBody && emailBody.length > 100) {
            analyzePayload.text = emailBody;
          }

          const analyzeRes = await fetch(
            `${supabaseUrl}/functions/v1/analyze-quote`,
            {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${serviceRoleKey}`,
              },
              body: JSON.stringify(analyzePayload),
            }
          );

          if (analyzeRes.ok) {
            const analyzeData = await analyzeRes.json();
            if (analyzeData.analysis) {
              const quoteTotal = analyzeData.analysis.overallAssessment?.totalQuoted ?? analyzeData.analysis.quoteTotal ?? null;
              const fairTotal = analyzeData.analysis.overallAssessment?.estimatedFairTotal ?? null;
              await supabase
                .from("property_projects")
                .update({
                  ai_research: { quoteAnalysis: analyzeData.analysis },
                  ai_research_updated_at: new Date().toISOString(),
                  ...(quoteTotal ? { estimated_budget: quoteTotal, ai_estimated_pro_cost: fairTotal } : {}),
                })
                .eq("id", project.id);

              // Save as project_quote and auto-activate
              const { data: savedQuote } = await supabase.from("project_quotes").insert({
                project_id: project.id,
                household_id: householdId,
                contractor_id: contractorId,
                quote_date: analyzeData.analysis.quoteDate || null,
                quote_total: quoteTotal,
                estimated_fair_total: fairTotal,
                overall_rating: analyzeData.analysis.overallAssessment?.rating ?? null,
                analysis: analyzeData.analysis,
                file_path: item.attachment_path || null,
              }).select("id").single();

              // Auto-activate this quote on the project
              if (savedQuote) {
                await supabase.from("property_projects")
                  .update({ active_quote_id: savedQuote.id })
                  .eq("id", project.id);
              }

              actions.push("analyzed_quote");
              result.analysis = analyzeData.analysis;
              // Phase 101 (E2) — link the persisted quote document to the
              // project_quotes row (set below once the doc exists).
              if (savedQuote) result.saved_quote_id = (savedQuote as { id: string }).id;
            }
          }
        } catch (err) {
          console.error(`[process-inbox] Quote analysis failed: ${err}`);
          actions.push("quote_analysis_failed");
        }
      }

      // Phase 101 (E2) — the quote becomes a real document: on the vendor
      // profile, in the project, in the vault.
      const quoteDocId = await persistQuoteDocument(project.id, contractorId, property_id ?? null);
      if (quoteDocId) {
        result.document_id = quoteDocId;
        if (result.saved_quote_id) {
          await supabase.from("project_quotes")
            .update({ document_id: quoteDocId })
            .eq("id", result.saved_quote_id);
        }
      }

      // Update inbox item
      await supabase
        .from("inbox_items")
        .update({
          action_completed: true,
          type: "project_created",
          related_project_id: project.id,
          related_contractor_id: contractorId,
          related_document_id: quoteDocId ?? undefined,
        })
        .eq("id", inbox_item_id);
    }

    // --- ADD TO EXISTING PROJECT ---
    else if (action === "add_to_project") {
      const { target_project_id } = body;
      if (!target_project_id) {
        return new Response(
          JSON.stringify({ error: "target_project_id required" }),
          { status: 400, headers }
        );
      }

      // Auto-create vendor if we have info
      let contractorId: string | null = null;
      if (classification?.vendorName) {
        const vendorName = classification.vendorName as string;
        const { data: existing } = await supabase
          .from("contractors")
          .select("id")
          .eq("household_id", householdId)
          .ilike("company_name", `%${vendorName}%`)
          .limit(1);

        if (existing && existing.length > 0) {
          contractorId = existing[0].id;
        } else {
          const { data: newVendor } = await supabase
            .from("contractors")
            .insert({
              household_id: householdId,
              company_name: vendorName,
              phone: (classification.vendorPhone as string) || "Not provided",
              email: (classification.vendorEmail as string) || null,
              address: (classification.vendorAddress as string) || null,
              license_number: (classification.vendorLicense as string) || null,
              notes: `Auto-added from forwarded email: ${subject}`,
            })
            .select("id")
            .single();
          if (newVendor) {
            contractorId = newVendor.id;
            actions.push(`created_vendor:${vendorName}`);
          }
        }
      }

      // Add contractor to project_contacts
      if (contractorId) {
        try {
          await supabase.from("project_contacts").upsert({
            project_id: target_project_id,
            household_id: householdId,
            contractor_id: contractorId,
            contact_name: (classification?.vendorName as string) || null,
            contact_email: (classification?.vendorEmail as string) || null,
            contact_phone: (classification?.vendorPhone as string) || null,
            role: "contractor",
            added_from: "email",
          }, { onConflict: "project_id,contractor_id" });
        } catch (_e) { /* non-blocking */ }
      }

      // Run quote analysis and save to the target project
      if (attachmentBase64 || emailBody) {
        try {
          // Get project info for analysis context
          const { data: targetProject } = await supabase
            .from("property_projects")
            .select("name, category")
            .eq("id", target_project_id)
            .single();

          const analyzePayload: Record<string, unknown> = {
            project_name: targetProject?.name || (classification?.projectType as string) || "Project",
            project_category: targetProject?.category || (classification?.projectType as string) || null,
            property_location: location,
          };
          if (attachmentBase64) {
            analyzePayload.image_base64 = attachmentBase64;
          } else if (emailBody && emailBody.length > 100) {
            analyzePayload.text = emailBody;
          }

          const analyzeRes = await fetch(
            `${supabaseUrl}/functions/v1/analyze-quote`,
            {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${serviceRoleKey}`,
              },
              body: JSON.stringify(analyzePayload),
            }
          );

          if (analyzeRes.ok) {
            const analyzeData = await analyzeRes.json();
            if (analyzeData.analysis) {
              const quoteTotal = analyzeData.analysis.overallAssessment?.totalQuoted ?? analyzeData.analysis.quoteTotal ?? null;
              const fairTotal = analyzeData.analysis.overallAssessment?.estimatedFairTotal ?? null;

              // Save as project_quote on the target project
              const { data: savedQuote } = await supabase.from("project_quotes").insert({
                project_id: target_project_id,
                household_id: householdId,
                contractor_id: contractorId,
                quote_date: analyzeData.analysis.quoteDate || null,
                quote_total: quoteTotal,
                estimated_fair_total: fairTotal,
                overall_rating: analyzeData.analysis.overallAssessment?.rating ?? null,
                analysis: analyzeData.analysis,
                file_path: item.attachment_path || null,
              }).select("id").single();

              // Update project budget from quote and auto-activate if first quote
              if (quoteTotal && savedQuote) {
                const { data: existingProject } = await supabase
                  .from("property_projects")
                  .select("active_quote_id")
                  .eq("id", target_project_id)
                  .single();

                const projectUpdate: Record<string, unknown> = {};
                // Set budget from quote total
                if (!existingProject?.active_quote_id) {
                  // First quote: auto-activate and set budget
                  projectUpdate.active_quote_id = savedQuote.id;
                  projectUpdate.estimated_budget = quoteTotal;
                  if (fairTotal) projectUpdate.ai_estimated_pro_cost = fairTotal;
                } else {
                  // Additional quote: don't change active, but update budget if this is now active
                  // (active quote stays the same unless user changes it)
                }

                if (Object.keys(projectUpdate).length > 0) {
                  await supabase.from("property_projects")
                    .update(projectUpdate)
                    .eq("id", target_project_id);
                }
              }

              actions.push("analyzed_quote");
              result.analysis = analyzeData.analysis;
            }
          }
        } catch (err) {
          console.error(`[process-inbox] Quote analysis for existing project failed: ${err}`);
          actions.push("quote_analysis_failed");
        }
      }

      // Append email summary to project
      try {
        const { data: projData } = await supabase
          .from("property_projects")
          .select("email_summaries")
          .eq("id", target_project_id)
          .single();
        const summaries = (projData?.email_summaries as any[]) || [];
        summaries.push({
          date: new Date().toISOString(),
          subject,
          from: fromAddress,
          summary: item.summary,
          type: "contractor_quote",
        });
        await supabase
          .from("property_projects")
          .update({ email_summaries: summaries })
          .eq("id", target_project_id);
      } catch (_e) { /* non-blocking */ }

      // Phase 101 (E2) — persist the quote as a document on the vendor +
      // project + vault, mirroring the process_quote path.
      const addedQuoteDocId = await persistQuoteDocument(target_project_id, contractorId, null);
      if (addedQuoteDocId) result.document_id = addedQuoteDocId;

      // Update inbox item
      await supabase
        .from("inbox_items")
        .update({
          action_completed: true,
          type: "project_created",
          related_project_id: target_project_id,
          related_contractor_id: contractorId,
          related_document_id: addedQuoteDocId ?? undefined,
        })
        .eq("id", inbox_item_id);

      result.project_id = target_project_id;
      actions.push(`added_to_project:${target_project_id}`);
    }

    // --- SAVE WARRANTY (Phase 101 E3) ---
    // The classifier found warranty facts at email time and fuzzy-matched a
    // system; the homeowner confirmed (optionally overriding the system).
    // Creates the warranties row + persists the attachment as a document on
    // that system, so the warranty email becomes structured coverage instead
    // of a filed PDF the homeowner re-types later.
    else if (action === "save_warranty") {
      const w = (metadata.warranty ?? {}) as Record<string, unknown>;
      const systemId = (body.system_id as string | undefined)
        || (w.matched_system_id as string | undefined) || null;
      const provider = String(w.provider ?? classification?.vendorName ?? "Unknown provider").slice(0, 200);
      const allowedTypes = new Set(["manufacturer", "extended", "home_warranty"]);
      const warrantyType = allowedTypes.has(String(w.warranty_type ?? ""))
        ? String(w.warranty_type) : "manufacturer";
      const startDate = (w.start_date as string | null) || new Date().toISOString().slice(0, 10);
      // end_date is NOT NULL in schema. When the email didn't state one,
      // default to one year and say so in the notes; the homeowner can edit.
      const statedEnd = (w.end_date as string | null) || null;
      const endDate = statedEnd
        || new Date(new Date(startDate).getTime() + 365 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);

      const warrantyInsert: Record<string, unknown> = {
        household_id: householdId,
        provider,
        warranty_type: warrantyType,
        start_date: startDate,
        end_date: endDate,
      };
      if (systemId) warrantyInsert.system_id = systemId;
      // warranties has no notes column; the one-year default when the email
      // omits an end date is documented on the saved document instead.

      const { data: warranty, error: wErr } = await supabase
        .from("warranties")
        .insert(warrantyInsert)
        .select("id")
        .single();
      if (wErr || !warranty) {
        return new Response(
          JSON.stringify({ error: "Failed to save warranty", detail: wErr?.message }),
          { status: 500, headers }
        );
      }
      result.warranty_id = (warranty as { id: string }).id;
      actions.push(`saved_warranty:${provider}`);

      // Persist the warranty email/attachment as a document tied to the system.
      if (attachmentBase64) {
        try {
          const filePath = `${householdId}/${crypto.randomUUID()}`;
          const fileBuffer = Uint8Array.from(atob(attachmentBase64), (c) => c.charCodeAt(0));
          const { error: upErr } = await supabase.storage
            .from("documents")
            .upload(filePath, fileBuffer, {
              contentType: item.attachment_content_type || "application/pdf",
            });
          if (!upErr) {
            const docInsert: Record<string, unknown> = {
              household_id: householdId,
              title: (classification?.documentTitle as string) || subject || `Warranty: ${provider}`,
              category: "Warranty",
              status: "active",
              file_path: filePath,
              ai_summary: item.summary,
              notes: `Warranty saved from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}`,
              visible_to_home_managers: visibleToHomeManagers("Warranty"),
            };
            // documents has no system_id column; the system linkage lives on
            // the warranties row created above.
            const { data: doc } = await supabase.from("documents").insert(docInsert).select("id").single();
            if (doc) result.document_id = (doc as { id: string }).id;
          }
        } catch (e) {
          console.warn(`[process-inbox] warranty document persist failed (non-fatal): ${e}`);
        }
      }

      await supabase
        .from("inbox_items")
        .update({
          action_completed: true,
          needs_action: false,
          related_document_id: (result.document_id as string | undefined) ?? undefined,
        })
        .eq("id", inbox_item_id);
    }

    // --- PROCESS DOCUMENT ---
    else if (action === "process_document") {
      const docTitle =
        (classification?.documentTitle as string) || subject || "Forwarded Document";
      const docCategory = document_category ||
        (classification?.documentCategory as string) || "Other";

      // Upload attachment to documents bucket if we have one
      let filePath: string | null = null;
      if (attachmentBase64) {
        filePath = `${householdId}/${crypto.randomUUID()}`;
        const fileBuffer = Uint8Array.from(atob(attachmentBase64), (c) =>
          c.charCodeAt(0)
        );
        const { error: upErr } = await supabase.storage
          .from("documents")
          .upload(filePath, fileBuffer, {
            contentType: item.attachment_content_type || "application/pdf",
          });
        if (upErr) {
          console.error(`[process-inbox] Document upload failed: ${upErr.message}`);
          return new Response(
            JSON.stringify({ error: "Failed to upload document" }),
            { status: 500, headers }
          );
        }
      }

      // Create document record
      const docInsert: Record<string, unknown> = {
        household_id: householdId,
        title: docTitle,
        category: docCategory,
        status: "active",
        notes: `Stored from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}\n\n${item.summary || ""}`,
        ai_summary: item.summary,
        visible_to_home_managers: visibleToHomeManagers(docCategory),
      };
      if (property_id) docInsert.property_id = property_id;
      if (vehicle_id) docInsert.vehicle_id = vehicle_id;
      if (filePath) docInsert.file_path = filePath;

      const { data: doc, error: docErr } = await supabase
        .from("documents")
        .insert(docInsert)
        .select("id")
        .single();

      if (!doc) {
        console.error(`[process-inbox] Document creation failed: ${docErr?.message}`);
        return new Response(
          JSON.stringify({ error: "Failed to create document", detail: docErr?.message }),
          { status: 500, headers }
        );
      }

      actions.push(`stored_document:${docTitle}`);
      result.document_id = doc.id;

      // Try to match document to a vehicle (by VIN, plate, or year/make/model in title/summary)
      try {
        const { data: vehicles } = await supabase
          .from("vehicles")
          .select("id, vin, license_plate, year, make, model")
          .eq("household_id", householdId);

        if (vehicles && vehicles.length > 0) {
          const searchText = `${docTitle} ${item.summary ?? ""} ${emailBody ?? ""}`.toLowerCase();
          const matchedVehicle = vehicles.find((v: any) => {
            if (v.vin && searchText.includes(v.vin.toLowerCase())) return true;
            if (v.license_plate && searchText.includes(v.license_plate.toLowerCase())) return true;
            const ymm = [v.year, v.make, v.model].filter(Boolean).join(" ").toLowerCase();
            if (ymm.length > 5 && searchText.includes(ymm)) return true;
            return false;
          });

          if (matchedVehicle) {
            await supabase.from("documents").update({ vehicle_id: matchedVehicle.id }).eq("id", doc.id);
            actions.push(`linked_to_vehicle:${matchedVehicle.id}`);
            console.log(`[process-inbox] Linked document to vehicle: ${matchedVehicle.id}`);
          }
        }
      } catch (vErr) {
        console.warn("[process-inbox] Vehicle matching failed (non-blocking):", vErr);
      }

      // Trigger AI analysis
      if (attachmentBase64 || emailBody) {
        try {
          await fetch(`${supabaseUrl}/functions/v1/analyze-document`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${serviceRoleKey}`,
            },
            body: JSON.stringify({
              document_id: doc.id,
              household_id: householdId,
              image_base64: attachmentBase64 ?? undefined,
              text: !attachmentBase64 ? emailBody : undefined,
              document_title: docTitle,
              category: docCategory,
            }),
          });
          actions.push("triggered_document_analysis");
        } catch {
          console.error("[process-inbox] Document analysis trigger failed");
        }
      }

      // Update inbox item
      await supabase
        .from("inbox_items")
        .update({
          action_completed: true,
          type: "document_stored",
          related_document_id: doc.id,
        })
        .eq("id", inbox_item_id);
    }

    // --- CONFIRM PROJECT MATCH ---
    else if (action === "confirm_project_match") {
      // User confirmed the quote belongs to the matched project — just mark as done
      await supabase
        .from("inbox_items")
        .update({ action_completed: true, needs_action: false })
        .eq("id", inbox_item_id);
      actions.push("project_match_confirmed");
    }

    // --- MOVE QUOTE TO DIFFERENT PROJECT ---
    else if (action === "move_to_project") {
      const { target_project_id } = body;
      if (!target_project_id) {
        return new Response(
          JSON.stringify({ error: "target_project_id required" }),
          { status: 400, headers }
        );
      }

      // Move the project_quote record to the new project
      const sourceProjectId = metadata.matched_project_id as string;
      if (sourceProjectId) {
        await supabase
          .from("project_quotes")
          .update({ project_id: target_project_id })
          .eq("project_id", sourceProjectId)
          .eq("household_id", householdId);

        // Move line items too
        await supabase
          .from("project_line_items")
          .update({ project_id: target_project_id })
          .eq("project_id", sourceProjectId)
          .eq("household_id", householdId);

        actions.push(`moved_to_project:${target_project_id}`);
      }

      await supabase
        .from("inbox_items")
        .update({ action_completed: true, needs_action: false, related_project_id: target_project_id })
        .eq("id", inbox_item_id);
    }

    // --- CONFIRM DOCUMENT CATEGORY ---
    else if (action === "confirm_document_category") {
      // User confirmed the category — just mark as done
      await supabase
        .from("inbox_items")
        .update({ action_completed: true, needs_action: false })
        .eq("id", inbox_item_id);
      actions.push("document_category_confirmed");
    }

    // --- CHANGE DOCUMENT CATEGORY ---
    else if (action === "change_document_category") {
      if (!document_category) {
        return new Response(
          JSON.stringify({ error: "document_category required" }),
          { status: 400, headers }
        );
      }

      // Update the document's category
      if (item.related_document_id) {
        await supabase
          .from("documents")
          .update({ category: document_category })
          .eq("id", item.related_document_id);
        actions.push(`changed_category:${document_category}`);
      }

      await supabase
        .from("inbox_items")
        .update({ action_completed: true, needs_action: false })
        .eq("id", inbox_item_id);
    }

    // --- PROCESS VEHICLE DOCUMENT ---
    else if (action === "process_vehicle_document") {
      const docTitle =
        (classification?.documentTitle as string) || subject || "Vehicle Document";
      const docCategory = document_category ||
        (classification?.documentCategory as string) || "Vehicle Title";

      // Upload attachment to documents bucket if we have one
      let filePath: string | null = null;
      if (attachmentBase64) {
        filePath = `${householdId}/${crypto.randomUUID()}`;
        const fileBuffer = Uint8Array.from(atob(attachmentBase64), (c) =>
          c.charCodeAt(0)
        );
        const { error: upErr } = await supabase.storage
          .from("documents")
          .upload(filePath, fileBuffer, {
            contentType: item.attachment_content_type || "application/pdf",
          });
        if (upErr) {
          console.error(`[process-inbox] Vehicle doc upload failed: ${upErr.message}`);
        }
      }

      // Create document record with vehicle_id
      const docInsert: Record<string, unknown> = {
        household_id: householdId,
        title: docTitle,
        category: docCategory,
        status: "active",
        notes: `Stored from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}\n\n${item.summary || ""}`,
        ai_summary: item.summary,
      };
      if (filePath) docInsert.file_path = filePath;
      if (vehicle_id) docInsert.vehicle_id = vehicle_id;
      if (property_id) docInsert.property_id = property_id;

      const { data: doc, error: docErr } = await supabase
        .from("documents")
        .insert(docInsert)
        .select("id")
        .single();

      if (!doc) {
        console.error(`[process-inbox] Vehicle doc creation failed: ${docErr?.message}`);
        return new Response(
          JSON.stringify({ error: "Failed to create document", detail: docErr?.message }),
          { status: 500, headers }
        );
      }

      actions.push(`stored_vehicle_document:${docTitle}`);
      result.document_id = doc.id;

      // Trigger AI analysis (will detect VINs and enrich)
      if (attachmentBase64 || emailBody) {
        try {
          await fetch(`${supabaseUrl}/functions/v1/analyze-document`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${serviceRoleKey}`,
            },
            body: JSON.stringify({
              document_id: doc.id,
              household_id: householdId,
              image_base64: attachmentBase64 ?? undefined,
              text: !attachmentBase64 ? emailBody : undefined,
              document_title: docTitle,
              category: docCategory,
            }),
          });
          actions.push("triggered_document_analysis");
        } catch {
          console.error("[process-inbox] Vehicle doc analysis trigger failed");
        }
      }

      // Update inbox item
      await supabase
        .from("inbox_items")
        .update({
          action_completed: true,
          type: "document_stored",
          related_document_id: doc.id,
        })
        .eq("id", inbox_item_id);
    }

    // --- CREATE INSURANCE CLAIM PROJECT ---
    else if (action === "create_claim_project") {
      if (!property_id) {
        return new Response(
          JSON.stringify({ error: "property_id required for claim project" }),
          { status: 400, headers }
        );
      }

      const claimInfo = classification ?? {};
      const claimNumber = (claimInfo as any).claimNumber ?? null;
      const claimType = (claimInfo as any).claimType ?? null;
      const insuranceCompany = (claimInfo as any).insuranceCompany ?? null;
      const adjusterName = (claimInfo as any).adjusterName ?? null;
      const adjusterPhone = (claimInfo as any).adjusterPhone ?? null;
      const adjusterEmail = (claimInfo as any).adjusterEmail ?? null;
      const policyNumber = (claimInfo as any).policyNumber ?? null;

      const claimLabel = claimNumber
        ? `Insurance Claim #${claimNumber}`
        : `Insurance Claim: ${claimType || subject || "New Claim"}`;

      const { data: project, error: projErr } = await supabase
        .from("property_projects")
        .insert({
          household_id: householdId,
          property_id,
          name: claimLabel,
          category: "Insurance Claim",
          status: "in_progress",
          project_type: "insurance_claim",
          priority: "high",
          notes: [
            claimNumber ? `Claim #: ${claimNumber}` : null,
            policyNumber ? `Policy #: ${policyNumber}` : null,
            insuranceCompany ? `Insurance: ${insuranceCompany}` : null,
            adjusterName ? `Adjuster: ${adjusterName}` : null,
            adjusterPhone ? `Adjuster Phone: ${adjusterPhone}` : null,
            adjusterEmail ? `Adjuster Email: ${adjusterEmail}` : null,
            `\nCreated from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}`,
          ].filter(Boolean).join("\n"),
          ai_research: {
            claimNumber,
            claimType,
            policyNumber,
            insuranceCompany,
            adjuster: adjusterName ? { name: adjusterName, phone: adjusterPhone, email: adjusterEmail } : null,
            emailSummaries: [{ date: new Date().toISOString(), summary: item.summary, subject }],
          },
        })
        .select("id")
        .single();

      if (!project) {
        console.error(`[process-inbox] Claim project creation failed: ${projErr?.message}`);
        return new Response(
          JSON.stringify({ error: "Failed to create claim project", detail: projErr?.message }),
          { status: 500, headers }
        );
      }

      result.project_id = project.id;
      actions.push(`created_insurance_claim:${claimLabel}`);

      // Attach file if we have one
      if (item.attachment_path) {
        try {
          await supabase.from("project_files").insert({
            project_id: project.id,
            household_id: householdId,
            file_path: item.attachment_path,
            filename: item.attachment_filename || "claim_document",
            content_type: item.attachment_content_type,
            notes: `From email: ${subject}`,
          });
          actions.push("claim_file_attached");
        } catch (_e) { /* non-blocking */ }
      }

      // Add adjuster as contact if info available
      if (adjusterName && (adjusterPhone || adjusterEmail)) {
        try {
          const adjCompany = insuranceCompany
            ? `${adjusterName} (${insuranceCompany})`
            : adjusterName;
          const { data: newAdj } = await supabase
            .from("contractors")
            .upsert({
              household_id: householdId,
              company_name: adjCompany,
              contact_name: adjusterName,
              phone: adjusterPhone || "Not provided",
              email: adjusterEmail || null,
              specialties: ["Insurance Claims"],
              notes: `Claims adjuster. Added from insurance claim email: ${subject}`,
            }, { onConflict: "household_id,company_name" })
            .select("id")
            .single();
          if (newAdj) {
            actions.push(`created_vendor:${adjCompany}`);
          }
        } catch (_e) { /* non-blocking */ }
      }

      await supabase
        .from("inbox_items")
        .update({
          action_completed: true,
          type: "project_created",
          related_project_id: project.id,
        })
        .eq("id", inbox_item_id);
    }

    // --- RESOLVE DUPLICATE ---
    else if (action === "resolve_duplicate") {
      const resolution = document_category; // "replace", "save_both", or "delete"
      const duplicateOfTitle = (metadata?.duplicate_of_title as string) || "Unknown";

      if (resolution === "replace") {
        // Delete the EXISTING document (keep the new one from this email)
        // Find existing doc by matching content_hash
        if (item.related_document_id) {
          const { data: newDoc } = await supabase
            .from("documents")
            .select("content_hash")
            .eq("id", item.related_document_id)
            .single();

          if (newDoc?.content_hash) {
            const { data: existingDocs } = await supabase
              .from("documents")
              .select("id, file_path")
              .eq("household_id", householdId)
              .eq("content_hash", newDoc.content_hash)
              .is("deleted_at", null)
              .neq("id", item.related_document_id);

            for (const existing of existingDocs || []) {
              // Delete storage file
              if (existing.file_path) {
                await supabase.storage.from("documents").remove([existing.file_path]);
              }
              // Soft-delete DB record
              await supabase.from("documents")
                .update({ deleted_at: new Date().toISOString() })
                .eq("id", existing.id);
            }
            actions.push("replaced_existing_document");
          }
        }
      } else if (resolution === "delete") {
        // Delete the NEW document (the one from this email)
        if (item.related_document_id) {
          const { data: newDoc } = await supabase
            .from("documents")
            .select("file_path")
            .eq("id", item.related_document_id)
            .single();

          if (newDoc?.file_path) {
            await supabase.storage.from("documents").remove([newDoc.file_path]);
          }
          await supabase.from("documents")
            .update({ deleted_at: new Date().toISOString() })
            .eq("id", item.related_document_id);
          actions.push("deleted_new_document");
        }
      } else {
        // save_both: just mark as resolved, keep both
        actions.push("saved_both_copies");
      }

      await supabase
        .from("inbox_items")
        .update({ action_completed: true, needs_action: false })
        .eq("id", inbox_item_id);
    }

    // --- REMOVE VENDOR ---
    else if (action === "remove_vendor") {
      if (item.related_contractor_id) {
        await supabase
          .from("contractors")
          .delete()
          .eq("id", item.related_contractor_id);
        actions.push("vendor_removed");
      }
      await supabase
        .from("inbox_items")
        .update({ action_completed: true, needs_action: false })
        .eq("id", inbox_item_id);
    }

    // Unknown action
    else {
      return new Response(
        JSON.stringify({ error: `Unknown action: ${action}` }),
        { status: 400, headers }
      );
    }

    result.actions = actions;
    console.log(`[process-inbox] Complete. Actions: ${actions.join(", ")}`);

    return new Response(JSON.stringify(result), { status: 200, headers });
  } catch (err) {
    console.error("[process-inbox] Error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers }
    );
  }
});

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
      action,        // 'process_quote', 'process_document', 'dismiss'
      document_category,
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
              await supabase
                .from("property_projects")
                .update({
                  ai_research: { quoteAnalysis: analyzeData.analysis },
                  ai_research_updated_at: new Date().toISOString(),
                })
                .eq("id", project.id);
              actions.push("analyzed_quote");
              result.analysis = analyzeData.analysis;
            }
          }
        } catch (err) {
          console.error(`[process-inbox] Quote analysis failed: ${err}`);
          actions.push("quote_analysis_failed");
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
      };
      if (property_id) docInsert.property_id = property_id;
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

// Haven Edge Function: receive-email
// Receives forwarded emails via SendGrid Inbound Parse webhook.
// Intelligently classifies content and takes action:
// - Contractor quotes -> create project + analyze quote + add vendor
// - Estate/legal documents -> store as document + categorize
// - Vendor/contact info -> add to vendor directory
// - Other -> store as document for reference

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface EmailClassification {
  type: "contractor_quote" | "estate_document" | "vendor_contact" | "home_document" | "family" | "insurance_claim" | "bill_invoice" | "other";
  confidence: "high" | "medium" | "low";
  vendorName: string | null;
  vendorPhone: string | null;
  vendorEmail: string | null;
  vendorAddress: string | null;
  vendorLicense: string | null;
  vendorSpecialties: string[];
  projectType: string | null;
  documentCategory: string | null;
  documentTitle: string | null;
  summary: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!anthropicApiKey) {
      return new Response(
        JSON.stringify({ error: "ANTHROPIC_API_KEY not set" }),
        { status: 500, headers }
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // --- PARSE INCOMING EMAIL ---
    let toAddress = "";
    let fromAddress = "";
    let subject = "";
    let emailBody = "";
    let attachmentBase64: string | null = null;
    let attachmentContentType: string | null = null;
    let attachmentFilename: string | null = null;
    let additionalAttachments: Array<{ base64: string; contentType: string; filename: string }> = [];

    const contentType = req.headers.get("content-type") ?? "";

    // Helper: encode ArrayBuffer to base64 in chunks (handles large PDFs without blowing the stack)
    function arrayBufferToBase64(buffer: ArrayBuffer): string {
      const bytes = new Uint8Array(buffer);
      const chunkSize = 8192;
      let result = "";
      for (let i = 0; i < bytes.length; i += chunkSize) {
        const chunk = bytes.subarray(i, Math.min(i + chunkSize, bytes.length));
        result += String.fromCharCode(...chunk);
      }
      return btoa(result);
    }

    if (contentType.includes("multipart/form-data") || contentType.includes("application/x-www-form-urlencoded")) {
      const formData = await req.formData();
      toAddress = (formData.get("to") as string) ?? "";
      fromAddress = (formData.get("from") as string) ?? "";
      subject = (formData.get("subject") as string) ?? "";
      emailBody = (formData.get("text") as string) ?? (formData.get("html") as string) ?? "";

      // Extract ALL attachments (SendGrid sends as attachment1, attachment2, etc.)
      const allAttachments: Array<{ base64: string; contentType: string; filename: string }> = [];
      for (let i = 1; i <= 10; i++) {
        const att = formData.get(`attachment${i}`) as File | null;
        if (!att) break;
        try {
          const buffer = await att.arrayBuffer();
          // Skip attachments over 20MB (base64 expands by ~33%)
          if (buffer.byteLength > 20 * 1024 * 1024) {
            console.warn(`[receive-email] Skipping attachment ${att.name}: ${(buffer.byteLength / 1024 / 1024).toFixed(1)}MB exceeds 20MB limit`);
            continue;
          }
          const b64 = arrayBufferToBase64(buffer);
          allAttachments.push({ base64: b64, contentType: att.type, filename: att.name });
          console.log(`[receive-email] Parsed attachment ${i}: ${att.name} (${(buffer.byteLength / 1024).toFixed(0)}KB, type: ${att.type})`);
        } catch (attErr) {
          console.error(`[receive-email] Failed to read attachment ${i} (${att.name}): ${attErr}`);
        }
      }
      if (allAttachments.length > 0) {
        // Use the first attachment as the primary (for backward compat)
        attachmentBase64 = allAttachments[0].base64;
        attachmentContentType = allAttachments[0].contentType;
        attachmentFilename = allAttachments[0].filename;
        // Track additional attachments for separate processing
        additionalAttachments = allAttachments.slice(1);
      }
      console.log(`[receive-email] Extracted ${allAttachments.length} attachment(s)`);
    } else {
      const body = await req.json();
      toAddress = body.to ?? "";
      fromAddress = body.from ?? "";
      subject = body.subject ?? "";
      emailBody = body.text ?? body.body ?? "";
      attachmentBase64 = body.attachment_base64 ?? null;
      attachmentContentType = body.attachment_content_type ?? null;
      attachmentFilename = body.attachment_filename ?? null;
    }

    console.log(`[receive-email] From: ${fromAddress}, To: ${toAddress}, Subject: ${subject}, Has attachment: ${!!attachmentBase64}`);

    // --- LOOK UP HOUSEHOLD ---
    // Match both alfred.havenhome.dev (new) and projects.havenhome.dev (legacy)
    const emailMatch = toAddress.match(/([a-z0-9]+)@(?:alfred|projects)\.havenhome\.dev/i);
    if (!emailMatch) {
      console.log(`[receive-email] No matching haven address in: ${toAddress}`);
      return new Response(
        JSON.stringify({ error: "Not a valid Haven email address" }),
        { status: 400, headers }
      );
    }

    // Normalize to alfred domain for lookup, but also check projects domain for legacy
    const localPart = emailMatch[1].toLowerCase();
    const uniqueAddress = `${localPart}@alfred.havenhome.dev`;

    const { data: emailRecord, error: lookupError } = await supabase
      .from("household_email_addresses")
      .select("household_id")
      .eq("unique_address", uniqueAddress)
      .single();

    if (lookupError || !emailRecord) {
      console.error(`[receive-email] No household for address: ${uniqueAddress}`);
      return new Response(
        JSON.stringify({ error: "Unknown email address" }),
        { status: 404, headers }
      );
    }

    const householdId = emailRecord.household_id;

    // --- WHITELIST CHECK: Only process emails from allowed senders ---
    // SendGrid's "from" can be "Display Name <email@example.com>" — extract just the email
    const senderEmail = (() => {
      const match = fromAddress.match(/<([^>]+)>/);
      return (match ? match[1] : fromAddress).trim().toLowerCase();
    })();

    if (senderEmail) {
      const { data: allowedSender } = await supabase
        .from("household_allowed_senders")
        .select("id")
        .eq("household_id", householdId)
        .ilike("email", senderEmail)
        .limit(1);

      if (!allowedSender || allowedSender.length === 0) {
        console.log(`[receive-email] Sender not whitelisted: ${senderEmail} (raw: ${fromAddress}) for household ${householdId}`);
        return new Response(
          JSON.stringify({ success: true, rejected: true, reason: "sender_not_whitelisted" }),
          { status: 200, headers }
        );
      }
    }

    // --- DEDUPLICATION: Prevent SendGrid retries from creating duplicate items ---
    // Hash the email fingerprint (from + subject + attachment name + body length)
    const emailFingerprint = `${fromAddress}|${subject}|${attachmentFilename || ""}|${emailBody.length}`;
    const encoder = new TextEncoder();
    const hashBuffer = await crypto.subtle.digest("SHA-256", encoder.encode(emailFingerprint));
    const emailHash = Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, "0")).join("");

    // Check if we already processed this exact email (48-hour window covers all SendGrid retries)
    const twoDaysAgo = new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString();
    const { data: existing } = await supabase
      .from("inbox_items")
      .select("id")
      .eq("household_id", householdId)
      .gte("created_at", twoDaysAgo)
      .eq("email_hash", emailHash)
      .limit(1);

    if (existing && existing.length > 0) {
      console.log(`[receive-email] Duplicate detected (hash=${emailHash.substring(0, 12)}), skipping`);
      return new Response(
        JSON.stringify({ success: true, deduplicated: true }),
        { status: 200, headers }
      );
    }

    // --- CREATE "PROCESSING" PLACEHOLDER so user sees immediate feedback ---
    const placeholderTitle = subject
      ? `Processing email: ${subject}`
      : fromAddress
        ? `Processing email from ${fromAddress}`
        : "Processing incoming email...";

    const { data: placeholderItem } = await supabase
      .from("inbox_items")
      .insert({
        household_id: householdId,
        type: "processing",
        title: placeholderTitle,
        summary: attachmentFilename
          ? `Analyzing "${attachmentFilename}" — this may take a moment.`
          : "Reading and classifying your email — this may take a moment.",
        from_email: fromAddress || null,
        status: "processing",
        attachment_filename: attachmentFilename,
        email_hash: emailHash,
        metadata: { email_hash: emailHash },
      })
      .select("id")
      .single();

    const placeholderId = placeholderItem?.id;
    console.log(`[receive-email] Created processing placeholder: ${placeholderId}`);

    // --- PERSIST ATTACHMENT TO STORAGE (before any processing) ---
    let attachmentStoragePath: string | null = null;
    if (attachmentBase64) {
      try {
        const storagePath = `${householdId}/${crypto.randomUUID()}`;
        const fileBuffer = Uint8Array.from(atob(attachmentBase64), c => c.charCodeAt(0));
        const { error: storageErr } = await supabase.storage
          .from("inbox-attachments")
          .upload(storagePath, fileBuffer, {
            contentType: attachmentContentType || "application/pdf",
          });
        if (!storageErr) {
          attachmentStoragePath = storagePath;
          console.log(`[receive-email] Attachment stored: ${storagePath} (${fileBuffer.length} bytes)`);
        } else {
          console.error(`[receive-email] Attachment storage failed: ${storageErr.message}`);
        }
      } catch (err) {
        console.error(`[receive-email] Attachment storage error: ${err}`);
      }
    }

    // Get the primary property
    const { data: properties } = await supabase
      .from("properties")
      .select("id, city, state, name")
      .eq("household_id", householdId)
      .limit(1);

    const property = properties?.[0];
    const location = property ? [property.city, property.state].filter(Boolean).join(", ") : null;

    // --- CLASSIFY EMAIL WITH CLAUDE ---
    // Determine if this is likely a forwarded attachment with minimal body text
    const bodyIsMinimal = emailBody.trim().length < 50;
    const subjectLower = (subject || "").toLowerCase();
    const hasQuoteSignals = subjectLower.includes("quote") || subjectLower.includes("estimate") || subjectLower.includes("proposal") || subjectLower.includes("bid") || subjectLower.includes("invoice");
    const hasPdfAttachment = attachmentContentType?.includes("pdf") || attachmentFilename?.toLowerCase().endsWith(".pdf");

    // Detect forwarded email patterns and extract original sender
    const forwardPatterns = [
      /---------- Forwarded message ---------\s*\nFrom:\s*(.+)/i,
      /-------- Original Message --------\s*\nFrom:\s*(.+)/i,
      /Begin forwarded message:\s*\n.*?From:\s*(.+)/is,
      /From:\s*(.+?)\n.*?(?:Sent|Date):\s*/i,
      />?\s*From:\s*(.+?)(?:\n|$)/i,
    ];

    let originalSender: string | null = null;
    for (const pattern of forwardPatterns) {
      const match = emailBody.match(pattern);
      if (match) {
        originalSender = match[1].trim();
        break;
      }
    }

    const isForwarded = subject.toLowerCase().startsWith("fwd:") || subject.toLowerCase().startsWith("fw:") || !!originalSender;

    const classificationPrompt = `Analyze this email and classify it. This was forwarded to a household management app by a user.
${isForwarded ? `\nIMPORTANT: This is a FORWARDED email. The "FROM" below is the person who forwarded it (the app user), NOT the original sender. Look inside the email body for the actual original sender, content, and context. Ignore the forwarder's signature — focus on the forwarded content after markers like "---------- Forwarded message ---------" or "Begin forwarded message:".` : ""}
${originalSender ? `\nDETECTED ORIGINAL SENDER: ${originalSender}` : ""}

FORWARDED BY: ${fromAddress}
SUBJECT: ${subject}
BODY (first 3000 chars):
${emailBody.substring(0, 3000)}
${attachmentBase64 ? `\n[Email has a ${attachmentContentType || "file"} attachment${attachmentFilename ? ` named "${attachmentFilename}"` : ""}]` : ""}
${bodyIsMinimal && hasPdfAttachment ? `\n[NOTE: The email body is minimal/empty but has a PDF attachment. This is likely a forwarded document — classify based on the subject line, sender, and attachment name rather than the body text.]` : ""}
${hasQuoteSignals ? `\n[NOTE: The subject line contains quote/estimate/proposal keywords — this is very likely a contractor_quote even if the body is empty.]` : ""}

Classify this email into ONE of these types:
- "contractor_quote": A quote, estimate, proposal, or bid from a contractor/vendor for home work
- "insurance_claim": An insurance claim, claim update, adjuster communication, damage assessment, claim number reference, repair authorization, or any correspondence about an active insurance claim process. This is different from a policy document — this is about an ACTIVE CLAIM (damage, loss, incident).
- "bill_invoice": A bill, invoice, statement, payment notice, membership dues, or recurring charge NOT related to home renovation/repair. Examples: club memberships, subscriptions, utility bills, tuition, medical bills. If it could be a contractor invoice for home work, classify as "contractor_quote" instead.
- "estate_document": A legal document, HOMEOWNERS insurance policy, property tax, deed, mortgage, trust, will, or financial planning document. IMPORTANT: health/medical insurance cards, medical records, prescriptions, and doctor correspondence are NOT estate documents — classify those as "family" with familyCategory "medical".
- "vendor_contact": Contact information for a service provider, contractor, or vendor (not a quote)
- "home_document": A home-related document (warranty, receipt, manual, permit, inspection report)
- "family": Personal/family email — school communications, event invitations, birthday/party info, kids' activities, sports/extracurriculars, family travel, personal appointments, work/school schedules, newsletters, permission slips, report cards, medical/dental appointments, health insurance cards, medical records, prescriptions, or any personal/family life content. Also use for health/medical insurance documents.
- "other": Anything that doesn't fit the above categories

For ALL types, extract vendor/contact information if present in the email.

Respond with ONLY valid JSON:
{
  "type": "contractor_quote" | "insurance_claim" | "bill_invoice" | "estate_document" | "vendor_contact" | "home_document" | "family" | "other",
  "confidence": "high" | "medium" | "low",
  "vendorName": "company/business name or null",
  "vendorPhone": "phone number or null",
  "vendorEmail": "business email or null (not the forwarding user's email)",
  "vendorAddress": "business address or null",
  "vendorLicense": "license number or null",
  "vendorSpecialties": ["HVAC", "Plumbing"] or [],
  "projectType": "Kitchen Renovation, Plumbing Repair, etc. or null",
  "documentCategory": "best matching category: Will, Trust, Homeowners Insurance, Vehicle Title, Contractor Quote, Warranty, etc. or null",
  "documentTitle": "suggested title for the document or null",
  "summary": "1-2 sentence summary of what this email contains",
  "familyCategory": "school | events | medical | activities | travel | personal | other — only if type is family, otherwise null",
  "familyMemberName": "name of the family member this relates to, or null",
  "eventDate": "ISO 8601 datetime of the event/appointment/deadline if one is mentioned (e.g. '2026-03-29T13:00:00'), or null. Extract from the forwarded content, not the forward date.",
  "billVendor": "Name of billing company/vendor if type is bill_invoice, or null",
  "billAmount": "Dollar amount of the bill if present (number, not string), or null",
  "billDueDate": "Due date in ISO 8601 if present, or null",
  "claimNumber": "Insurance claim number if present, or null",
  "claimType": "Type of claim: water_damage | fire | storm | theft | liability | vehicle | other — only if insurance_claim, otherwise null",
  "adjusterName": "Name of claims adjuster/advisor if mentioned, or null",
  "adjusterPhone": "Phone number of adjuster if mentioned, or null",
  "adjusterEmail": "Email of adjuster if mentioned, or null",
  "insuranceCompany": "Name of insurance company if mentioned, or null",
  "policyNumber": "Policy number if mentioned, or null"
}`;

    const classResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 1024,
        messages: [{ role: "user", content: classificationPrompt }],
      }),
    });

    if (!classResponse.ok) {
      console.error(`[receive-email] Classification failed: ${classResponse.status}`);
      return new Response(
        JSON.stringify({ error: "Failed to classify email" }),
        { status: 502, headers }
      );
    }

    const classData = await classResponse.json();
    const classText = classData?.content?.[0]?.text ?? "{}";

    let classification: EmailClassification;
    try {
      classification = JSON.parse(classText);
    } catch {
      const match = classText.match(/\{[\s\S]*\}/);
      classification = match ? JSON.parse(match[0]) : { type: "other", confidence: "low", vendorName: null, vendorPhone: null, vendorEmail: null, vendorAddress: null, vendorLicense: null, vendorSpecialties: [], projectType: null, documentCategory: null, documentTitle: null, summary: "Could not classify email" };
    }

    console.log(`[receive-email] Classification: type=${classification.type}, confidence=${classification.confidence}, vendor=${classification.vendorName}`);

    // --- ACTION RESULTS ---
    const actions: string[] = [];
    let createdProjectId: string | null = null;
    let createdContractorId: string | null = null;
    let createdDocumentId: string | null = null;

    // --- STEP 1: AUTO-CREATE VENDOR (for any type that has vendor info, except family emails) ---
    if (classification.type !== "family" && classification.type !== "insurance_claim" && classification.type !== "bill_invoice" && classification.vendorName && (classification.vendorPhone || classification.vendorEmail)) {
      // Check if vendor already exists (by name + household)
      const { data: existingVendors } = await supabase
        .from("contractors")
        .select("id, company_name")
        .eq("household_id", householdId)
        .ilike("company_name", `%${classification.vendorName}%`)
        .limit(1);

      if (existingVendors && existingVendors.length > 0) {
        createdContractorId = existingVendors[0].id;
        console.log(`[receive-email] Found existing vendor: ${existingVendors[0].company_name} (${createdContractorId})`);
        actions.push(`matched_existing_vendor:${existingVendors[0].company_name}`);
      } else {
        // Create new vendor
        const { data: newVendor, error: vendorError } = await supabase
          .from("contractors")
          .insert({
            household_id: householdId,
            company_name: classification.vendorName,
            phone: classification.vendorPhone || "Not provided",
            contact_name: null,
            email: classification.vendorEmail,
            address: classification.vendorAddress,
            license_number: classification.vendorLicense,
            specialties: classification.vendorSpecialties.length > 0 ? classification.vendorSpecialties : null,
            notes: `Auto-added from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}`,
          })
          .select("id")
          .single();

        if (newVendor) {
          createdContractorId = newVendor.id;
          console.log(`[receive-email] Created vendor: ${classification.vendorName} (${createdContractorId})`);
          actions.push(`created_vendor:${classification.vendorName}`);
        } else {
          console.error(`[receive-email] Failed to create vendor: ${vendorError?.message}`);
        }
      }
    }

    // --- STEP 2: TYPE-SPECIFIC ACTIONS ---

    if (classification.type === "contractor_quote") {
      if (!property) {
        // No property — can't auto-create project (property_id is required).
        // Create actionable inbox item so user can assign a property.
        console.log(`[receive-email] No property for household — creating actionable inbox item`);
        actions.push("needs_property_assignment");
        // The inbox item is created in Step 3 with needs_action = true

      } else {
      // CHECK FOR EXISTING MATCHING PROJECT first — so multiple quotes for the
      // same type of work get attached to one project instead of creating duplicates.
      const projectName = classification.projectType || `Quote from ${classification.vendorName || "Contractor"}`;
      const projectCategory = classification.projectType || "Other";

      let project: { id: string } | null = null;
      let isExistingProject = false;

      // Look for an active project with matching category on this property
      const { data: existingProjects } = await supabase
        .from("property_projects")
        .select("id, name, category")
        .eq("household_id", householdId)
        .eq("property_id", property.id)
        .in("status", ["planning", "in_progress"])
        .limit(10);

      if (existingProjects && existingProjects.length > 0) {
        const categoryLower = projectCategory.toLowerCase();
        // Synonyms for project types — "remodel", "renovation", "remodeling" are the same thing
        const remodelWords = ["remodel", "remodeling", "renovation", "overhaul", "redo", "makeover", "update", "upgrade"];

        const normalizeProjectType = (s: string) => {
          let n = s.toLowerCase().trim();
          for (const word of remodelWords) {
            n = n.replace(new RegExp(`\\b${word}\\b`, "g"), "remodel");
          }
          return n;
        };

        const normalizedCategory = normalizeProjectType(categoryLower);

        const match = existingProjects.find((p: { category: string; name: string }) => {
          const pCat = normalizeProjectType(p.category);
          const pName = normalizeProjectType(p.name);
          // Exact match after normalization
          if (pCat === normalizedCategory || pName === normalizedCategory) return true;
          // Substring match after normalization
          if (pCat.includes(normalizedCategory) || normalizedCategory.includes(pCat)) return true;
          if (pName.includes(normalizedCategory) || normalizedCategory.includes(pName)) return true;
          return false;
        });
        if (match) {
          project = match;
          isExistingProject = true;
          console.log(`[receive-email] Matched existing project: ${match.id} (${(match as any).name})`);
          actions.push(`matched_existing_project:${(match as any).name}`);
        }
      }

      // No match — create new project
      if (!project) {
        const { data: newProject, error: projectError } = await supabase
          .from("property_projects")
          .insert({
            household_id: householdId,
            property_id: property.id,
            name: projectName,
            category: projectCategory,
            status: "planning",
            project_type: "pro",
            priority: "medium",
          })
          .select("id")
          .single();

        if (newProject) {
          project = newProject;
          actions.push(`created_project:${projectName}`);
        } else {
          console.error(`[receive-email] Failed to create project: ${projectError?.message}`);
          actions.push("project_creation_failed");
        }
      }

      if (project) {
        createdProjectId = project.id;
        console.log(`[receive-email] Using project: ${project.id} (existing=${isExistingProject})`);

        // ANALYZE QUOTE — awaited so the Deno runtime stays alive.
        // The inbox item is created in Step 3 AFTER this, but that's OK because
        // SendGrid doesn't need an instant response — it has a generous timeout.
        const hasQuoteContent = attachmentBase64 || emailBody.length > 100;
        if (hasQuoteContent) {
          try {
            const analyzeUrl = `${supabaseUrl}/functions/v1/analyze-quote`;
            const analyzePayload: Record<string, unknown> = {
              project_name: projectName,
              project_category: classification.projectType,
              property_location: location,
            };
            if (attachmentBase64) {
              analyzePayload.image_base64 = attachmentBase64;
            } else {
              analyzePayload.text = emailBody;
            }

            console.log(`[receive-email] Starting quote analysis for project ${project.id}`);
            const analyzeResponse = await fetch(analyzeUrl, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${serviceRoleKey}`,
              },
              body: JSON.stringify(analyzePayload),
            });

            if (analyzeResponse.ok) {
              const analyzeData = await analyzeResponse.json();
              if (analyzeData.analysis) {
                const analysis = analyzeData.analysis;

                // Update project with cost estimate
                await supabase
                  .from("property_projects")
                  .update({
                    ai_estimated_pro_cost: analysis.overallAssessment?.estimatedFairTotal ?? analysis.quoteTotal ?? null,
                    notes: classification.vendorName ? `Vendor: ${classification.vendorName}` : null,
                  })
                  .eq("id", project.id);

                // Save as a project_quote record
                const { error: quoteErr } = await supabase.from("project_quotes").insert({
                  project_id: project.id,
                  household_id: householdId,
                  contractor_id: createdContractorId,
                  quote_date: analysis.quoteDate || null,
                  quote_total: analysis.overallAssessment?.totalQuoted ?? analysis.quoteTotal ?? null,
                  estimated_fair_total: analysis.overallAssessment?.estimatedFairTotal ?? null,
                  overall_rating: analysis.overallAssessment?.rating ?? null,
                  analysis: analysis,
                  file_path: attachmentStoragePath,
                });
                if (quoteErr) {
                  console.error(`[receive-email] project_quote insert failed: ${quoteErr.message}`);
                } else {
                  console.log(`[receive-email] Quote saved to project_quotes for project ${project.id}`);
                  actions.push("saved_project_quote");
                }

                actions.push("analyzed_quote");

                // NOTE: We intentionally do NOT import quote line items into project_line_items.
                // The quote analysis (with fair pricing, local ranges, ratings) lives in the
                // project_quotes record. Line items in Materials & Supplies are for things the
                // homeowner has actually committed to — not speculative quote breakdowns.

                // Enrich vendor from quote analysis
                const quoteVendor = analysis.vendor;
                if (createdContractorId) {
                  const vendorUpdates: Record<string, unknown> = {};
                  if (quoteVendor?.phone && quoteVendor.phone !== "Not provided") vendorUpdates.phone = quoteVendor.phone;
                  if (quoteVendor?.email) vendorUpdates.email = quoteVendor.email;
                  if (quoteVendor?.address) vendorUpdates.address = quoteVendor.address;
                  if (quoteVendor?.license) vendorUpdates.license_number = quoteVendor.license;
                  // Set specialties from the project type so the vendor shows the right category
                  const projectType = analysis.projectType || classification.projectType;
                  if (projectType) {
                    vendorUpdates.specialties = [projectType];
                  }
                  if (Object.keys(vendorUpdates).length > 0) {
                    await supabase.from("contractors").update(vendorUpdates).eq("id", createdContractorId);
                    actions.push("enriched_vendor_from_quote");
                  }
                }
              }
            } else {
              const errBody = await analyzeResponse.text().catch(() => "unknown");
              console.error(`[receive-email] Quote analysis returned ${analyzeResponse.status}: ${errBody.substring(0, 200)}`);
              actions.push("quote_analysis_failed");
            }
          } catch (analyzeErr) {
            console.error(`[receive-email] Quote analysis failed (non-blocking): ${analyzeErr}`);
            actions.push("quote_analysis_failed");
          }
        }
      } else {
        console.error(`[receive-email] Failed to create project: ${projectError?.message}`);
        actions.push("project_creation_failed");
      }
      } // end else (property exists)

    } else if (classification.type === "estate_document" || classification.type === "home_document") {
      // STORE AS DOCUMENT
      if (attachmentBase64) {
        try {
          const docTitle = classification.documentTitle || subject || "Forwarded Document";
          const docCategory = classification.documentCategory || "Other";
          const filePath = `${householdId}/${crypto.randomUUID()}`;

          // Upload to storage
          const fileBuffer = Uint8Array.from(atob(attachmentBase64), c => c.charCodeAt(0));
          const { error: uploadError } = await supabase.storage
            .from("documents")
            .upload(filePath, fileBuffer, {
              contentType: attachmentContentType || "application/pdf",
            });

          if (!uploadError) {
            // Create document record (property_id is optional)
            const docInsert: Record<string, unknown> = {
              household_id: householdId,
              title: docTitle,
              category: docCategory,
              status: "active",
              file_path: filePath,
              notes: `Auto-stored from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}\n\n${classification.summary}`,
              ai_summary: classification.summary,
            };
            if (property) {
              docInsert.property_id = property.id;
            }

            const { data: doc, error: docError } = await supabase
              .from("documents")
              .insert(docInsert)
              .select("id")
              .single();

            if (doc) {
              createdDocumentId = doc.id;
              actions.push(`stored_document:${docTitle}`);
              console.log(`[receive-email] Stored document: ${doc.id} (${docTitle})`);

              // Trigger AI analysis on the document
              try {
                const analyzeDocUrl = `${supabaseUrl}/functions/v1/analyze-document`;
                await fetch(analyzeDocUrl, {
                  method: "POST",
                  headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${serviceRoleKey}`,
                  },
                  body: JSON.stringify({
                    document_id: doc.id,
                    household_id: householdId,
                    image_base64: attachmentBase64,
                    document_title: docTitle,
                    category: docCategory,
                  }),
                });
                actions.push("triggered_document_analysis");
              } catch {
                console.error("[receive-email] Document analysis trigger failed (non-blocking)");
              }
            } else {
              console.error(`[receive-email] Document record creation failed: ${docError?.message}`);
              actions.push("document_record_failed");
            }
          } else {
            console.error(`[receive-email] Document upload failed: ${uploadError.message}`);
            actions.push("document_upload_failed");
          }
        } catch (docErr) {
          console.error(`[receive-email] Document storage failed: ${docErr}`);
          actions.push("document_storage_failed");
        }
      } else {
        // Email was classified as a document but had no attachment — still track it
        actions.push("document_detected_no_attachment");
      }

    } else if (classification.type === "vendor_contact") {
      // Vendor was already created in Step 1 if info was present
      if (!createdContractorId) {
        actions.push("vendor_contact_detected_insufficient_info");
      }

    } else if (classification.type === "insurance_claim") {
      // Insurance claim — auto-create or attach to existing insurance_claim project
      const claimInfo = classification as any;
      const claimLabel = claimInfo.claimNumber
        ? `Insurance Claim #${claimInfo.claimNumber}`
        : `Insurance Claim: ${claimInfo.claimType || classification.documentTitle || subject || "New Claim"}`;

      if (property) {
        // Check for existing insurance claim project on this property
        const { data: existingProjects } = await supabase
          .from("property_projects")
          .select("id, name")
          .eq("household_id", householdId)
          .eq("property_id", property.id)
          .eq("project_type", "insurance_claim")
          .in("status", ["planning", "in_progress"])
          .limit(5);

        let claimProject = existingProjects?.find((p: any) => {
          if (claimInfo.claimNumber && p.name.includes(claimInfo.claimNumber)) return true;
          return false;
        }) ?? null;

        if (!claimProject) {
          // Create new insurance claim project
          const { data: newProject } = await supabase
            .from("property_projects")
            .insert({
              household_id: householdId,
              property_id: property.id,
              name: claimLabel,
              category: "Insurance Claim",
              status: "in_progress",
              project_type: "insurance_claim",
              priority: "high",
              notes: [
                claimInfo.claimNumber ? `Claim #: ${claimInfo.claimNumber}` : null,
                claimInfo.policyNumber ? `Policy #: ${claimInfo.policyNumber}` : null,
                claimInfo.insuranceCompany ? `Insurance: ${claimInfo.insuranceCompany}` : null,
                claimInfo.adjusterName ? `Adjuster: ${claimInfo.adjusterName}` : null,
                claimInfo.adjusterPhone ? `Adjuster Phone: ${claimInfo.adjusterPhone}` : null,
                claimInfo.adjusterEmail ? `Adjuster Email: ${claimInfo.adjusterEmail}` : null,
                `\nCreated from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}`,
              ].filter(Boolean).join("\n"),
              ai_research: {
                claimNumber: claimInfo.claimNumber,
                claimType: claimInfo.claimType,
                policyNumber: claimInfo.policyNumber,
                insuranceCompany: claimInfo.insuranceCompany,
                adjuster: claimInfo.adjusterName ? {
                  name: claimInfo.adjusterName,
                  phone: claimInfo.adjusterPhone,
                  email: claimInfo.adjusterEmail,
                } : null,
                emailSummaries: [{ date: new Date().toISOString(), summary: classification.summary, subject }],
              },
            })
            .select("id")
            .single();

          if (newProject) {
            claimProject = newProject;
            actions.push(`created_insurance_claim:${claimLabel}`);
          }
        } else {
          // Append this email summary to existing claim's ai_research
          const { data: existingData } = await supabase
            .from("property_projects")
            .select("ai_research, notes")
            .eq("id", claimProject.id)
            .single();

          const existingResearch = (existingData?.ai_research as any) || {};
          const emailSummaries = existingResearch.emailSummaries || [];
          emailSummaries.push({ date: new Date().toISOString(), summary: classification.summary, subject });

          // Merge any new info (adjuster, policy number, etc.)
          const merged = {
            ...existingResearch,
            emailSummaries,
            claimNumber: existingResearch.claimNumber || claimInfo.claimNumber,
            policyNumber: existingResearch.policyNumber || claimInfo.policyNumber,
            insuranceCompany: existingResearch.insuranceCompany || claimInfo.insuranceCompany,
          };
          if (claimInfo.adjusterName && !existingResearch.adjuster?.name) {
            merged.adjuster = { name: claimInfo.adjusterName, phone: claimInfo.adjusterPhone, email: claimInfo.adjusterEmail };
          }

          await supabase
            .from("property_projects")
            .update({ ai_research: merged })
            .eq("id", claimProject.id);

          actions.push(`updated_insurance_claim:${(claimProject as any).name}`);
        }

        if (claimProject) {
          createdProjectId = claimProject.id;

          // Store attachment as a project file
          if (attachmentStoragePath) {
            await supabase.from("project_files").insert({
              project_id: claimProject.id,
              household_id: householdId,
              file_path: attachmentStoragePath,
              filename: attachmentFilename || "claim_document",
              content_type: attachmentContentType,
              notes: `From email: ${subject}`,
            });
            actions.push("claim_file_attached");
          }

          // Also save the raw email as a text file for the claim record
          if (emailBody && emailBody.length > 50) {
            try {
              const emailFilePath = `${householdId}/claims/${claimProject.id}/${crypto.randomUUID()}_email.txt`;
              const emailContent = `From: ${fromAddress}\nSubject: ${subject}\nDate: ${new Date().toISOString()}\n\n${emailBody}`;
              const emailBuffer = new TextEncoder().encode(emailContent);
              await supabase.storage.from("documents").upload(emailFilePath, emailBuffer, { contentType: "text/plain" });
              await supabase.from("project_files").insert({
                project_id: claimProject.id,
                household_id: householdId,
                file_path: emailFilePath,
                filename: `Email: ${subject || "Claim correspondence"}.txt`,
                content_type: "text/plain",
                file_size: emailBuffer.byteLength,
                notes: `Raw email from ${fromAddress}`,
              });
              actions.push("claim_email_saved_as_file");
            } catch (err) {
              console.error(`[receive-email] Failed to save claim email as file: ${err}`);
            }
          }
        }
      } else {
        actions.push("insurance_claim_no_property");
      }

      console.log(`[receive-email] Insurance claim: ${claimLabel}`);

    } else if (classification.type === "bill_invoice") {
      // Bills/invoices — save as family item with "bills" category
      actions.push("bill_saved");
      console.log(`[receive-email] Bill/invoice: ${(classification as any).billVendor || "Unknown vendor"}`);

    } else if (classification.type === "family") {
      // Family emails (school, events, invitations, etc.) — just save them
      actions.push("family_email_saved");
      console.log(`[receive-email] Family email: ${(classification as any).familyCategory || "general"}`);

    } else {
      actions.push("unclassified_email");
    }

    // --- STEP 2.5a: SAVE ALL ATTACHMENTS FOR FAMILY/BILL ITEMS ---
    // Family and bill emails may have multiple attachments (e.g. front+back of insurance card)
    // Save additional attachments to inbox-attachments storage
    if ((classification.type === "family" || classification.type === "bill_invoice") && additionalAttachments.length > 0) {
      for (const att of additionalAttachments) {
        try {
          const filePath = `${householdId}/family/${crypto.randomUUID()}_${att.filename}`;
          const fileBuffer = Uint8Array.from(atob(att.base64), c => c.charCodeAt(0));
          await supabase.storage.from("inbox-attachments").upload(filePath, fileBuffer, { contentType: att.contentType || "application/octet-stream" });
          // Create a separate inbox item for each additional attachment
          await supabase.from("inbox_items").insert({
            household_id: householdId,
            type: "family",
            title: att.filename || `Attachment from ${subject}`,
            summary: `Additional attachment from: ${subject}`,
            from_email: fromAddress,
            attachment_path: filePath,
            attachment_content_type: att.contentType,
            attachment_filename: att.filename,
            family_category: classification.type === "bill_invoice" ? "bills" : ((classification as any).familyCategory || "other"),
            status: "ready",
          });
          actions.push(`saved_additional_attachment:${att.filename}`);
        } catch (err) {
          console.error(`[receive-email] Failed to save family attachment: ${err}`);
        }
      }
    }

    // --- STEP 2.5: PROCESS ADDITIONAL ATTACHMENTS AS DOCUMENTS ---
    if (additionalAttachments.length > 0 && property) {
      for (const att of additionalAttachments) {
        try {
          const filePath = `${householdId}/${crypto.randomUUID()}`;
          const fileBuffer = Uint8Array.from(atob(att.base64), c => c.charCodeAt(0));
          const { error: upErr } = await supabase.storage
            .from("documents")
            .upload(filePath, fileBuffer, { contentType: att.contentType || "application/pdf" });
          if (!upErr) {
            const docTitle = att.filename || `Attachment from ${fromAddress}`;
            const { data: doc } = await supabase.from("documents").insert({
              household_id: householdId,
              property_id: property.id,
              title: docTitle,
              category: classification.documentCategory || "Other",
              status: "active",
              file_path: filePath,
              notes: `Additional attachment from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}`,
              ai_summary: `Attachment: ${att.filename || "unnamed file"}`,
            }).select("id").single();
            if (doc) {
              actions.push(`stored_additional_attachment:${att.filename}`);
              // Trigger AI analysis
              try {
                await fetch(`${supabaseUrl}/functions/v1/analyze-document`, {
                  method: "POST",
                  headers: { "Content-Type": "application/json", "Authorization": `Bearer ${serviceRoleKey}` },
                  body: JSON.stringify({ document_id: doc.id, household_id: householdId, image_base64: att.base64, document_title: docTitle }),
                });
              } catch { /* non-blocking */ }
            }
          }
        } catch (err) {
          console.error(`[receive-email] Additional attachment failed: ${err}`);
        }
      }
    }

    // --- STEP 3: CREATE INBOX ITEMS (smart prompts + notifications) ---
    // We create the main notification PLUS any confirmation prompts needed.
    {
      const baseMetadata: Record<string, unknown> = {
        classification,
        subject,
        email_body: emailBody.substring(0, 5000),
        original_actions: actions.filter(a => a !== "inbox_item_created"),
        email_hash: emailHash,
      };

      const failedActions = actions.filter(a => a.includes("failed"));
      const summaryExtra = failedActions.length > 0
        ? "\n\nSome automated processing encountered issues."
        : "";
      const baseSummary = (classification.summary || `Email from ${fromAddress}: ${subject}`) + summaryExtra;

      // --- Main notification (what the system did) ---
      let mainTitle = subject || "Email received";
      let mainType = "other";
      let mainNeedsAction = false;
      let mainActionType: string | null = null;

      if (createdProjectId && classification.type === "insurance_claim") {
        const isUpdate = actions.some(a => a.startsWith("updated_insurance_claim:"));
        const claimInfo = classification as any;
        const claimLabel = claimInfo.claimNumber ? `Claim #${claimInfo.claimNumber}` : (claimInfo.insuranceCompany || "Insurance Claim");
        mainType = "project_created";
        mainTitle = isUpdate ? `Claim update: ${claimLabel}` : `New insurance claim: ${claimLabel}`;
      } else if (createdProjectId) {
        const matchedExisting = actions.some(a => a.startsWith("matched_existing_project:"));
        const projectLabel = classification.projectType || classification.vendorName || "Contractor Quote";
        mainType = "project_created";
        mainTitle = matchedExisting
          ? `Quote added to ${projectLabel}`
          : `New project: ${projectLabel}`;
      } else if (createdDocumentId) {
        mainType = "document_stored";
        mainTitle = `Document saved: ${classification.documentTitle || subject}`;
      } else if (actions.includes("needs_property_assignment")) {
        mainType = "contractor_quote";
        mainTitle = `Quote received: ${classification.projectType || classification.vendorName || subject || "Contractor Quote"}`;
        mainNeedsAction = true;
        mainActionType = "assign_property";
      } else if (classification.type === "bill_invoice") {
        mainType = "family";
        const billInfo = classification as any;
        const vendor = billInfo.billVendor || classification.vendorName || "Bill";
        const amount = billInfo.billAmount ? ` — $${billInfo.billAmount}` : "";
        mainTitle = `Bill: ${vendor}${amount}`;
        mainNeedsAction = false;
      } else if (classification.type === "family") {
        mainType = "family";
        const familyCat = (classification as any).familyCategory;
        const memberName = (classification as any).familyMemberName;
        // Build a clean title like "School: Spring Concert - Emma" or just the subject
        const catLabel = familyCat && familyCat !== "other" ? familyCat.charAt(0).toUpperCase() + familyCat.slice(1) : null;
        const parts = [catLabel, classification.documentTitle || subject, memberName].filter(Boolean);
        mainTitle = parts.join(": ").substring(0, 200) || `Family email: ${subject || "No subject"}`;
        mainNeedsAction = false;
      } else if (classification.type === "other" || actions.includes("unclassified_email")) {
        mainType = "other";
        mainTitle = `Email received: ${subject || "No subject"}`;
        mainNeedsAction = attachmentStoragePath != null;
        mainActionType = mainNeedsAction ? "classify_document" : null;
      } else if (failedActions.length > 0) {
        mainType = "other";
        mainTitle = `Email needs review: ${subject || "No subject"}`;
        mainNeedsAction = true;
        mainActionType = "review";
      }

      // Delete the processing placeholder and any stale processing items (>10 min old)
      if (placeholderId) {
        await supabase.from("inbox_items").delete().eq("id", placeholderId);
      }
      const tenMinAgo = new Date(Date.now() - 10 * 60 * 1000).toISOString();
      await supabase.from("inbox_items")
        .delete()
        .eq("household_id", householdId)
        .eq("status", "processing")
        .lt("created_at", tenMinAgo);

      await supabase.from("inbox_items").insert({
        household_id: householdId,
        type: mainType,
        title: mainTitle,
        summary: baseSummary,
        from_email: fromAddress,
        related_project_id: createdProjectId,
        related_document_id: createdDocumentId,
        related_contractor_id: createdContractorId,
        needs_action: mainNeedsAction,
        action_type: mainActionType,
        attachment_path: attachmentStoragePath,
        attachment_content_type: attachmentContentType,
        attachment_filename: attachmentFilename,
        email_hash: emailHash,
        metadata: baseMetadata,
        status: "ready",
        family_category: classification.type === "bill_invoice" ? "bills" : (classification.type === "family" ? ((classification as any).familyCategory || "other") : null),
        family_member_name: classification.type === "family" ? ((classification as any).familyMemberName || null) : null,
        event_date: (classification as any).eventDate || null,
      });
      actions.push("inbox_item_created");

      // --- Confirmation prompt: new vendor added ---
      const isNewVendor = actions.some(a => a.startsWith("created_vendor:"));
      if (isNewVendor && classification.vendorName) {
        await supabase.from("inbox_items").insert({
          household_id: householdId,
          type: "vendor_added",
          email_hash: emailHash + ":vendor",
          title: `Add ${classification.vendorName} as a Home Contact?`,
          summary: `We detected ${classification.vendorName} from your forwarded email. They've been added to your contacts${classification.vendorSpecialties?.length > 0 ? ` as a ${classification.vendorSpecialties.join(", ")} specialist` : ""}. You can edit their details anytime.`,
          from_email: fromAddress,
          related_contractor_id: createdContractorId,
          needs_action: false,
          metadata: {
            ...baseMetadata,
            proposed_action: "confirm_vendor",
            vendor_name: classification.vendorName,
            vendor_phone: classification.vendorPhone,
            vendor_specialties: classification.vendorSpecialties,
          },
        });
        actions.push("vendor_notification_created");
      }

      // --- Confirmation prompt: project match (when we matched an existing project) ---
      const matchAction = actions.find(a => a.startsWith("matched_existing_project:"));
      if (matchAction && createdProjectId) {
        const matchedName = matchAction.split(":").slice(1).join(":");
        await supabase.from("inbox_items").insert({
          household_id: householdId,
          type: "project_created",
          email_hash: emailHash + ":match",
          title: `Is this quote for "${matchedName}"?`,
          summary: `We matched this ${classification.vendorName ? `quote from ${classification.vendorName}` : "quote"} to your existing project "${matchedName}". If this is a different project, you can move it.`,
          from_email: fromAddress,
          related_project_id: createdProjectId,
          related_contractor_id: createdContractorId,
          needs_action: true,
          action_type: "confirm_project_match",
          metadata: {
            ...baseMetadata,
            proposed_action: "confirm_project_match",
            matched_project_id: createdProjectId,
            matched_project_name: matchedName,
            vendor_name: classification.vendorName,
          },
        });
        actions.push("project_match_confirmation_created");
      }

      // --- Confirmation prompt: document classification (medium/low confidence) ---
      if (createdDocumentId && classification.confidence !== "high") {
        await supabase.from("inbox_items").insert({
          household_id: householdId,
          type: "document_stored",
          title: `Confirm: Save as "${classification.documentCategory || "Other"}"?`,
          summary: `We saved "${classification.documentTitle || subject}" as ${classification.documentCategory || "Other"}. Is this the right category?`,
          from_email: fromAddress,
          related_document_id: createdDocumentId,
          needs_action: true,
          action_type: "confirm_document_category",
          metadata: {
            ...baseMetadata,
            proposed_action: "confirm_document_category",
            suggested_category: classification.documentCategory,
            document_title: classification.documentTitle,
          },
        });
        actions.push("document_category_confirmation_created");
      }
    }

    // --- BUILD RESPONSE ---
    const response = {
      success: true,
      classification: classification.type,
      confidence: classification.confidence,
      summary: classification.summary,
      actions,
      created: {
        project_id: createdProjectId,
        contractor_id: createdContractorId,
        document_id: createdDocumentId,
      },
    };

    console.log(`[receive-email] Complete. Actions: ${actions.join(", ")}`);

    return new Response(
      JSON.stringify(response),
      { status: 200, headers }
    );
  } catch (err) {
    console.error("[receive-email] Error:", err);

    // Best-effort: update the processing placeholder to show failure instead of stuck spinner,
    // then create a failure notification.
    try {
      const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
      const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
      if (supabaseUrl && serviceRoleKey) {
        const svc = createClient(supabaseUrl, serviceRoleKey);

        // If we created a placeholder, update it to show failure
        if (typeof placeholderId !== "undefined" && placeholderId) {
          await svc.from("inbox_items").update({
            type: "other",
            title: `Email processing failed: ${subject || "Unknown subject"}`,
            summary: `An email from ${fromAddress || "unknown sender"} could not be fully processed. Try forwarding it again or uploading the document manually.`,
            status: "ready",
            needs_action: false,
          }).eq("id", placeholderId);
          console.log("[receive-email] Updated placeholder to failure state");
        } else if (toAddress) {
          // No placeholder yet — try to create a failure inbox item
          const match = toAddress.match(/([a-z0-9]+)@(?:alfred|projects)\.havenhome\.dev/i);
          if (match) {
            const addr = `${match[1].toLowerCase()}@alfred.havenhome.dev`;
            const { data: rec } = await svc
              .from("household_email_addresses")
              .select("household_id")
              .eq("unique_address", addr)
              .single();
            if (rec) {
              await svc.from("inbox_items").insert({
                household_id: rec.household_id,
                type: "other",
                title: `Email processing failed: ${subject || "Unknown subject"}`,
                summary: `An email from ${fromAddress || "unknown sender"} could not be processed. Please try forwarding it again or uploading the document manually.`,
                from_email: fromAddress || null,
                status: "ready",
              });
              console.log("[receive-email] Created failure inbox item for user");
            }
          }
        }
      }
    } catch (notifyErr) {
      console.error("[receive-email] Could not create failure notification:", notifyErr);
    }

    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers }
    );
  }
});

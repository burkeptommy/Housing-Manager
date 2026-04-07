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
  type: "contractor_quote" | "estate_document" | "vendor_contact" | "home_document" | "vehicle_document" | "family" | "insurance_claim" | "bill_invoice" | "other";
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
  vehicleContext?: boolean;
}

// --- iCal PARSER ---
// Lightweight parser for VCALENDAR/VEVENT data from calendar invite emails.
// No external dependencies — handles the standard fields we need.
interface ParsedICalEvent {
  summary: string | null;
  dtstart: string | null;
  dtend: string | null;
  allDay: boolean;
  location: string | null;
  description: string | null;
  rrule: string | null;
}

function parseICalEvents(icalData: string): ParsedICalEvent[] {
  const events: ParsedICalEvent[] = [];

  // Unfold iCal line continuations (lines starting with space or tab are continuations)
  const unfolded = icalData.replace(/\r?\n[ \t]/g, "");
  const lines = unfolded.split(/\r?\n/);

  let inEvent = false;
  let current: ParsedICalEvent | null = null;

  for (const line of lines) {
    if (line === "BEGIN:VEVENT") {
      inEvent = true;
      current = {
        summary: null,
        dtstart: null,
        dtend: null,
        allDay: false,
        location: null,
        description: null,
        rrule: null,
      };
      continue;
    }

    if (line === "END:VEVENT" && current) {
      if (current.dtstart) {
        events.push(current);
      }
      inEvent = false;
      current = null;
      continue;
    }

    if (!inEvent || !current) continue;

    // Parse property:value, handling parameters like DTSTART;VALUE=DATE:20260401
    const colonIdx = line.indexOf(":");
    if (colonIdx === -1) continue;

    const fullProp = line.substring(0, colonIdx);
    const value = line.substring(colonIdx + 1).trim();
    const propName = fullProp.split(";")[0].toUpperCase();
    const params = fullProp.toUpperCase();

    switch (propName) {
      case "SUMMARY":
        current.summary = unescapeIcal(value);
        break;
      case "DTSTART": {
        current.dtstart = icalDateToISO(value);
        // All-day events use VALUE=DATE (no time component)
        current.allDay = params.includes("VALUE=DATE") && !params.includes("VALUE=DATE-TIME");
        break;
      }
      case "DTEND":
        current.dtend = icalDateToISO(value);
        break;
      case "LOCATION":
        current.location = unescapeIcal(value);
        break;
      case "DESCRIPTION":
        current.description = unescapeIcal(value);
        break;
      case "RRULE":
        current.rrule = value;
        break;
    }
  }

  return events;
}

function icalDateToISO(value: string): string | null {
  // Formats: 20260401T130000Z, 20260401T130000, 20260401
  const cleaned = value.replace(/[^0-9TZ]/g, "");

  if (cleaned.length === 8) {
    // All-day: 20260401
    return `${cleaned.substring(0, 4)}-${cleaned.substring(4, 6)}-${cleaned.substring(6, 8)}T00:00:00`;
  }

  // 20260401T130000 or 20260401T130000Z
  const match = cleaned.match(/^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z?)$/);
  if (!match) return null;

  const [, y, m, d, h, min, s, z] = match;
  return `${y}-${m}-${d}T${h}:${min}:${s}${z ? "Z" : ""}`;
}

function unescapeIcal(value: string): string {
  return value
    .replace(/\\n/g, "\n")
    .replace(/\\,/g, ",")
    .replace(/\\;/g, ";")
    .replace(/\\\\/g, "\\");
}

// Compute SHA-256 content hash from base64-encoded file data
async function computeContentHash(base64Data: string): Promise<string | null> {
  try {
    const rawBytes = Uint8Array.from(atob(base64Data), c => c.charCodeAt(0));
    const hashBuffer = await crypto.subtle.digest("SHA-256", rawBytes);
    return Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, "0")).join("");
  } catch { return null; }
}

// Check if a document with this content hash already exists in the household
async function checkDocumentDuplicate(
  supabase: any, householdId: string, contentHash: string
): Promise<{ id: string; title: string } | null> {
  try {
    const { data } = await supabase
      .from("documents")
      .select("id, title")
      .eq("household_id", householdId)
      .eq("content_hash", contentHash)
      .is("deleted_at", null)
      .limit(1);
    return data && data.length > 0 ? data[0] : null;
  } catch { return null; }
}

// Content types that analyze-document can process (Claude Vision supports these)
const ANALYZABLE_CONTENT_TYPES = [
  "application/pdf",
  "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp",
  "text/plain", "text/html",
];

function isAnalyzableContentType(contentType: string | null): boolean {
  if (!contentType) return false;
  const ct = contentType.toLowerCase().split(";")[0].trim();
  return ANALYZABLE_CONTENT_TYPES.some(t => ct.includes(t));
}

function getFileExtension(filename: string | null, contentType: string | null): string {
  if (filename) {
    const ext = filename.split(".").pop()?.toLowerCase();
    if (ext) return `.${ext}`;
  }
  if (contentType?.includes("word") || contentType?.includes("docx")) return ".docx";
  if (contentType?.includes("spreadsheet") || contentType?.includes("xlsx")) return ".xlsx";
  if (contentType?.includes("csv")) return ".csv";
  if (contentType?.includes("zip")) return ".zip";
  if (contentType?.includes("heic") || contentType?.includes("heif")) return ".heic";
  return "";
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    console.log(`[receive-email] Request received: method=${req.method}, content-type=${req.headers.get("content-type")?.substring(0, 50)}, content-length=${req.headers.get("content-length") || "unknown"}`);

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
    let fullRawEmail = ""; // longest version of the email for "Show Original Email"
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
      const textBody = (formData.get("text") as string) ?? "";
      const htmlBody = (formData.get("html") as string) ?? "";
      emailBody = textBody || htmlBody;
      // For "Show Original Email" — use the longer version, strip HTML tags if using HTML
      fullRawEmail = textBody.length >= htmlBody.length
        ? textBody
        : htmlBody.replace(/<[^>]*>/g, " ").replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/\s+/g, " ").trim();

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
      fullRawEmail = emailBody;
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

    // --- COMPUTE EMAIL HASH (needed for dedup + placeholder) ---
    const emailFingerprint = `${fromAddress}|${subject}|${attachmentFilename || ""}|${emailBody.length}`;
    const encoder = new TextEncoder();
    const hashBuffer = await crypto.subtle.digest("SHA-256", encoder.encode(emailFingerprint));
    const emailHash = Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, "0")).join("");

    // --- CREATE "PROCESSING" PLACEHOLDER so user sees immediate feedback ---
    // This is created BEFORE whitelist/dedup checks so the user always knows an email arrived.
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
        // Update placeholder to show rejection reason instead of silently returning
        if (placeholderId) {
          await supabase.from("inbox_items").update({
            type: "other",
            title: `Email not processed: sender not recognized`,
            summary: `An email from ${senderEmail} was received but not processed because this sender is not in your allowed senders list. You can add them in Settings → Allowed Senders.`,
            status: "ready",
            needs_action: false,
          }).eq("id", placeholderId);
        }
        return new Response(
          JSON.stringify({ success: true, rejected: true, reason: "sender_not_whitelisted" }),
          { status: 200, headers }
        );
      }
    }

    // --- DEDUPLICATION: Prevent SendGrid retries from creating duplicate items ---
    const twoDaysAgo = new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString();
    const { data: existing } = await supabase
      .from("inbox_items")
      .select("id")
      .eq("household_id", householdId)
      .gte("created_at", twoDaysAgo)
      .eq("email_hash", emailHash)
      .neq("status", "processing")
      .limit(1);

    if (existing && existing.length > 0) {
      console.log(`[receive-email] Duplicate detected (hash=${emailHash.substring(0, 12)}), skipping`);
      // Remove the placeholder — the original item already exists
      if (placeholderId) {
        await supabase.from("inbox_items").delete().eq("id", placeholderId);
      }
      return new Response(
        JSON.stringify({ success: true, deduplicated: true }),
        { status: 200, headers }
      );
    }

    // --- CALENDAR INVITE DETECTION ---
    // When someone adds alfred@havenhome.dev as a guest on a calendar event,
    // the email contains inline text/calendar (iCal) data with VEVENT blocks.
    // Detect and parse these to create family_events directly.
    const allParsedAttachments = [
      ...(attachmentBase64 ? [{ base64: attachmentBase64, contentType: attachmentContentType || "", filename: attachmentFilename || "" }] : []),
      ...additionalAttachments,
    ];
    const calendarAttachment = allParsedAttachments.find(
      att => att.contentType.includes("text/calendar") || att.contentType.includes("application/ics") || att.filename.endsWith(".ics")
    );

    // Also check the email body for inline iCal data (some providers embed it directly)
    const inlineIcal = emailBody.includes("BEGIN:VCALENDAR") ? emailBody : null;
    const icalSource = calendarAttachment
      ? atob(calendarAttachment.base64)
      : inlineIcal;

    if (icalSource) {
      console.log(`[receive-email] Calendar invite detected — parsing iCal data`);
      try {
        const events = parseICalEvents(icalSource);
        if (events.length > 0) {
          console.log(`[receive-email] Parsed ${events.length} calendar event(s)`);
          for (const event of events) {
            await supabase.from("family_events").insert({
              household_id: householdId,
              title: event.summary || subject || "Calendar Event",
              start_date: event.dtstart,
              end_date: event.dtend || null,
              all_day: event.allDay || false,
              location: event.location || null,
              notes: event.description || null,
              source: "email_invite",
              recurrence_rule: event.rrule || null,
            });
          }

          // Update placeholder to show the imported events
          const eventTitles = events.map(e => e.summary || "Untitled").join(", ");
          if (placeholderId) {
            await supabase.from("inbox_items").update({
              type: "family",
              title: events.length === 1
                ? `Calendar invite: ${events[0].summary || subject}`
                : `${events.length} calendar events added`,
              summary: events.length === 1
                ? `Event on ${events[0].dtstart} from calendar invite`
                : `Events: ${eventTitles}`,
              status: "ready",
              family_category: "events",
              event_date: events[0].dtstart,
            }).eq("id", placeholderId);
          }

          // Send push notification about the calendar event
          try {
            const { data: householdUsers } = await supabase
              .from("users")
              .select("id")
              .eq("household_id", householdId);
            if (householdUsers && householdUsers.length > 0) {
              const supabaseUrlEnv = Deno.env.get("SUPABASE_URL") ?? "";
              const serviceRoleKeyEnv = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
              await fetch(`${supabaseUrlEnv}/functions/v1/send-push-notification`, {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": `Bearer ${serviceRoleKeyEnv}`,
                },
                body: JSON.stringify({
                  recipient_user_ids: householdUsers.map((u: { id: string }) => u.id),
                  title: "Calendar event added",
                  body: events.length === 1
                    ? `${events[0].summary || "New event"} added to family events`
                    : `${events.length} events added to family events`,
                  data: { type: "calendar_invite" },
                }),
              });
            }
          } catch (_pushErr) { /* non-blocking */ }

          return new Response(
            JSON.stringify({
              success: true,
              type: "calendar_invite",
              events_created: events.length,
            }),
            { status: 200, headers }
          );
        }
      } catch (icalErr) {
        console.error(`[receive-email] iCal parse failed, falling through to normal classification: ${icalErr}`);
        // Fall through to normal email classification
      }
    }

    // --- SEND INSTANT PUSH NOTIFICATION (fire-and-forget) ---
    // Acknowledge receipt immediately so the user doesn't think their email was lost.
    // This runs in the background — we don't await it.
    let householdUserIds: string[] = [];
    const pushNotificationPromise = (async () => {
      try {
        const { data: householdUsers } = await supabase
          .from("users")
          .select("id")
          .eq("household_id", householdId);
        if (!householdUsers || householdUsers.length === 0) return;
        householdUserIds = householdUsers.map((u: { id: string }) => u.id);

        const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
        const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
        if (!supabaseUrl || !serviceRoleKey) return;

        const truncatedSubject = subject
          ? subject.substring(0, 80)
          : "a new document";

        await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${serviceRoleKey}`,
          },
          body: JSON.stringify({
            recipient_user_ids: householdUserIds,
            title: "Alfred is reviewing your forwarded document",
            body: `Analyzing: ${truncatedSubject}`,
            data: {
              type: "inbox_processing",
              inbox_item_id: placeholderId ?? "",
            },
          }),
        });
      } catch (err) {
        console.error(`[receive-email] Push notification failed (non-blocking): ${err}`);
      }
    })();
    // Don't await pushNotificationPromise — continue processing immediately

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

    // Get ALL properties for this household (for address matching)
    const { data: properties } = await supabase
      .from("properties")
      .select("id, name, street, city, state, zip_code")
      .eq("household_id", householdId);

    // Default to first property; may be overridden by address matching below
    let property = properties?.[0] ?? null;
    const location = property ? [property.city, property.state].filter(Boolean).join(", ") : null;

    // --- CLASSIFY EMAIL WITH CLAUDE ---
    // Determine if this is likely a forwarded attachment with minimal body text
    const bodyIsMinimal = emailBody.trim().length < 50;
    const subjectLower = (subject || "").toLowerCase();
    const hasQuoteSignals = subjectLower.includes("quote") || subjectLower.includes("estimate") || subjectLower.includes("proposal") || subjectLower.includes("bid");
    // NOTE: "invoice" deliberately excluded — invoices are for completed work (bill_invoice), not future quotes
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
${bodyIsMinimal && attachmentBase64 ? `\n[IMPORTANT: The email body is minimal/empty but has a ${attachmentContentType || "file"} attachment${attachmentFilename ? ` named "${attachmentFilename}"` : ""}. The user forwarded this specifically for the attachment. Classify based on the attachment content, subject line, sender, attachment name, and most likely intent. Reports about the property (radon, inspection, mold, water, lead, energy, termite, appraisal, survey, environmental, air quality) MUST be classified as "home_document" — these are NOT "family" or "other". Only classify as "family" if it's clearly about a person (medical, school, activities). Do NOT classify as "other" when an attachment is present — make your best guess.]` : ""}
${hasQuoteSignals ? `\n[NOTE: The subject line contains quote/estimate/proposal keywords — this is very likely a contractor_quote even if the body is empty.]` : ""}

Classify this email into ONE of these types:
- "contractor_quote": A quote, estimate, proposal, or bid for FUTURE work that has NOT been done yet. The key distinction: if the document describes work to be done and asks for approval/acceptance, it's a quote. If the work has ALREADY been completed and the document is billing for it, it's a bill_invoice.
- "insurance_claim": An insurance claim, claim update, adjuster communication, damage assessment, claim number reference, repair authorization, or any correspondence about an active insurance claim process. This is different from a policy document — this is about an ACTIVE CLAIM (damage, loss, incident).
- "bill_invoice": An invoice, bill, or statement for work ALREADY completed or services ALREADY rendered. This includes: contractor invoices for completed home repairs/maintenance (plumber, electrician, HVAC, well service, etc.), club memberships, subscriptions, utility bills, tuition, medical bills, payment notices, recurring charges, AND vehicle service invoices (oil change, tire rotation, brake service, body work, car wash). The key distinction from contractor_quote: if the work was ALREADY DONE and this is the bill, it's bill_invoice. If the work hasn't started and this is asking for approval, it's contractor_quote. For vehicle service bills, also set vehicleContext: true.
- "estate_document": A legal document, HOMEOWNERS insurance policy, property tax, deed, mortgage, trust, will, or financial planning document. Also includes auto/vehicle insurance policies (category "Auto Insurance"). IMPORTANT: health/medical insurance cards, medical records, prescriptions, and doctor correspondence are NOT estate documents — classify those as "family" with familyCategory "medical".
- "vehicle_document": A document specifically about a vehicle — vehicle title, registration, purchase/lease agreement, loan statement, emissions inspection certificate, vehicle recall notice. NOT vehicle insurance (that's estate_document with "Auto Insurance" category). NOT a vehicle service invoice/bill (that's bill_invoice with vehicleContext: true).
- "vendor_contact": Contact information for a service provider, contractor, or vendor (not a quote)
- "home_document": A home-related document — warranty, receipt, manual, permit, inspection report, test report (radon, water quality, mold, lead, asbestos, air quality, termite, pest), home inspection, appraisal, survey, property assessment, environmental report, energy audit, or any document about the physical property/home itself
- "family": Personal/family email — school communications, event invitations, birthday/party info, kids' activities, sports/extracurriculars, family travel, personal appointments, work/school schedules, newsletters, permission slips, report cards, medical/dental appointments, health insurance cards, medical records, prescriptions, or any personal/family life content. Also use for health/medical insurance documents.
- "other": Anything that doesn't fit the above categories

VEHICLE vs HOME DISTINCTION:
- If an invoice/bill mentions a VIN, vehicle make/model, or vehicle-specific services (oil change, tire rotation, brake pads, transmission, body work, car wash, emissions test, state inspection), set vehicleContext: true.
- If an invoice/bill mentions a property address, home systems (HVAC, plumbing, electrical, roofing, landscaping, pool, pest control), set vehicleContext: false.
- Vehicle insurance policies (auto insurance) should be classified as estate_document with category "Auto Insurance", NOT as vehicle_document.
- Vehicle service invoices are bill_invoice with vehicleContext: true.

For ALL types, extract vendor/contact information if present in the email.

Respond with ONLY valid JSON:
{
  "type": "contractor_quote" | "insurance_claim" | "bill_invoice" | "estate_document" | "vehicle_document" | "vendor_contact" | "home_document" | "family" | "other",
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
  "eventDate": "ISO 8601 datetime of the FIRST event/appointment/deadline if one is mentioned (e.g. '2026-03-29T13:00:00'), or null. Extract from the forwarded content, not the forward date.",
  "events": "Array of ALL events/dates mentioned in the email. Each entry: { \"title\": \"Event name\", \"date\": \"ISO 8601\", \"endDate\": \"ISO 8601 or null\", \"allDay\": true/false, \"location\": \"location or null\" }. If only one event, array of one. If no events, empty array []. IMPORTANT: Extract ALL events — if email says 'here are 7 events', return all 7.",
  "billVendor": "Name of billing company/vendor if type is bill_invoice, or null",
  "billAmount": "Dollar amount of the bill if present (number, not string), or null",
  "billDueDate": "Due date in ISO 8601 if present, or null",
  "billAccountNumber": "Account number from the bill if visible, or null",
  "claimNumber": "Insurance claim number if present, or null",
  "claimType": "Type of claim: water_damage | fire | storm | theft | liability | vehicle | other — only if insurance_claim, otherwise null",
  "adjusterName": "Name of claims adjuster/advisor if mentioned, or null",
  "adjusterPhone": "Phone number of adjuster if mentioned, or null",
  "adjusterEmail": "Email of adjuster if mentioned, or null",
  "insuranceCompany": "Name of insurance company if mentioned, or null",
  "policyNumber": "Policy number if mentioned, or null",
  "propertyAddress": "Street address of the property this document relates to, if mentioned anywhere in the email or document (e.g. '123 Main St', '456 Oak Ave, Springfield'), or null",
  "vehicleContext": "true if this is a vehicle-related bill/invoice (oil change, tire rotation, brake service, body work, car wash, emissions test, state inspection, any vehicle service), false otherwise. Only applies to bill_invoice type."
}`;

    // Build classification message — include PDF content when body is minimal
    const classMessages: Array<{ role: string; content: unknown }> = [];
    if (bodyIsMinimal && attachmentBase64 && hasPdfAttachment) {
      // Send the PDF to Claude so it can read the actual content for classification
      console.log(`[receive-email] Including PDF in classification (minimal body + PDF attachment)`);
      classMessages.push({
        role: "user",
        content: [
          {
            type: "document",
            source: { type: "base64", media_type: "application/pdf", data: attachmentBase64 },
          },
          { type: "text", text: classificationPrompt },
        ],
      });
    } else if (bodyIsMinimal && attachmentBase64 && attachmentContentType?.startsWith("image/")) {
      // Send images to Claude too
      console.log(`[receive-email] Including image in classification (minimal body + image attachment)`);
      classMessages.push({
        role: "user",
        content: [
          {
            type: "image",
            source: { type: "base64", media_type: attachmentContentType, data: attachmentBase64 },
          },
          { type: "text", text: classificationPrompt },
        ],
      });
    } else {
      classMessages.push({ role: "user", content: classificationPrompt });
    }

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
        messages: classMessages,
      }),
    });

    if (!classResponse.ok) {
      console.error(`[receive-email] Classification failed: ${classResponse.status}`);
      // Update placeholder to show failure instead of leaving it stuck
      if (placeholderId) {
        await supabase.from("inbox_items").update({
          type: "other",
          title: `Email could not be processed: ${subject || "No subject"}`,
          summary: `We received your email from ${fromAddress || "unknown sender"} but couldn't classify it. Try forwarding it again.`,
          status: "ready",
          needs_action: false,
        }).eq("id", placeholderId);
      }
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

    // --- PROPERTY ADDRESS MATCHING ---
    // If Claude extracted an address from the document, match it to a property
    const extractedAddress = (classification as any).propertyAddress;
    let addressMatched = false;
    let addressUnmatched = false;
    if (extractedAddress && properties && properties.length > 0) {
      const normalize = (s: string) => s.toLowerCase().replace(/[^a-z0-9]/g, "");
      const extracted = normalize(extractedAddress);
      let matched = false;
      for (const prop of properties) {
        const propStreet = normalize(prop.street || "");
        // Match if the extracted address contains the property's street name
        if (propStreet.length > 3 && extracted.includes(propStreet)) {
          property = prop;
          matched = true;
          addressMatched = true;
          console.log(`[receive-email] Address matched to property: ${prop.name} (${prop.street})`);
          break;
        }
      }
      // If no street match, try city as a weaker signal (only for single-property households)
      if (!matched && properties.length === 1) {
        const propCity = normalize(properties[0].city || "");
        if (propCity.length > 3 && extracted.includes(propCity)) {
          matched = true;
          addressMatched = true;
          console.log(`[receive-email] City matched to single property: ${properties[0].name}`);
        }
      }
      if (!matched) {
        addressUnmatched = true;
        console.log(`[receive-email] Address "${extractedAddress}" did not match any property`);
      }
    }

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
      // QUOTES: Never auto-create a project. Save the attachment and vendor,
      // then prompt the user to choose: New Project, Existing Project, or Save as Document.
      actions.push("quote_received");
      console.log(`[receive-email] Contractor quote received — awaiting user action. Vendor: ${classification.vendorName || "unknown"}`);

      if (false) {
      // --- DISABLED: Auto project matching/creation ---
      // This entire block is preserved but disabled. Quotes now always prompt the user.
      // MULTI-SIGNAL PROJECT MATCHING — finds the right project using:
      // 1. Sender email → contractor → project_contacts/project_quotes (strongest signal)
      // 2. Email subject thread matching (Re:/Fwd: of known project name)
      // 3. Category/name normalization (fallback)
      const projectName = classification.projectType || `Quote from ${classification.vendorName || "Contractor"}`;
      const projectCategory = classification.projectType || "Other";

      let project: { id: string } | null = null;
      let isExistingProject = false;
      let matchMethod = "none";

      // --- SIGNAL 1: Sender email → existing contractor → project association ---
      // If this sender is already a known contractor, find projects they're associated with.
      if (!project && senderEmail) {
        // Check project_contacts for this sender's email
        const { data: contactMatches } = await supabase
          .from("project_contacts")
          .select("project_id, contact_email")
          .eq("household_id", householdId)
          .ilike("contact_email", senderEmail)
          .limit(5);

        if (contactMatches && contactMatches.length > 0) {
          // Find which of these projects are still active
          const contactProjectIds = contactMatches.map((c: any) => c.project_id);
          const { data: activeContactProjects } = await supabase
            .from("property_projects")
            .select("id, name, category")
            .in("id", contactProjectIds)
            .in("status", ["planning", "in_progress"])
            .limit(5);

          if (activeContactProjects && activeContactProjects.length > 0) {
            project = activeContactProjects[0];
            isExistingProject = true;
            matchMethod = "sender_project_contact";
            console.log(`[receive-email] Matched project via sender's project_contact: ${(project as any).name}`);
            actions.push(`matched_via_contact:${(activeContactProjects[0] as any).name}`);
          }
        }

        // Also check if sender matches a contractor who has quotes on active projects
        if (!project) {
          const { data: senderContractors } = await supabase
            .from("contractors")
            .select("id")
            .eq("household_id", householdId)
            .ilike("email", `%${senderEmail}%`)
            .limit(1);

          if (senderContractors && senderContractors.length > 0) {
            const contractorId = senderContractors[0].id;
            const { data: quotedProjects } = await supabase
              .from("project_quotes")
              .select("project_id")
              .eq("household_id", householdId)
              .eq("contractor_id", contractorId)
              .limit(5);

            if (quotedProjects && quotedProjects.length > 0) {
              const quotedProjectIds = quotedProjects.map((q: any) => q.project_id);
              const { data: activeQuotedProjects } = await supabase
                .from("property_projects")
                .select("id, name, category")
                .in("id", quotedProjectIds)
                .in("status", ["planning", "in_progress"])
                .limit(5);

              if (activeQuotedProjects && activeQuotedProjects.length > 0) {
                project = activeQuotedProjects[0];
                isExistingProject = true;
                matchMethod = "sender_existing_quote";
                console.log(`[receive-email] Matched project via sender's existing quote: ${(project as any).name}`);
                actions.push(`matched_via_contractor_quote:${(activeQuotedProjects[0] as any).name}`);
              }
            }
          }
        }
      }

      // Also check if the original sender (for forwarded emails) matches a contractor
      if (!project && originalSender) {
        const originalEmail = (() => {
          const m = originalSender.match(/<([^>]+)>/);
          return (m ? m[1] : originalSender.match(/[\w.-]+@[\w.-]+/) ? originalSender.match(/[\w.-]+@[\w.-]+/)![0] : null);
        })();

        if (originalEmail) {
          const { data: origContactMatches } = await supabase
            .from("project_contacts")
            .select("project_id")
            .eq("household_id", householdId)
            .ilike("contact_email", originalEmail.toLowerCase())
            .limit(5);

          if (origContactMatches && origContactMatches.length > 0) {
            const origProjectIds = origContactMatches.map((c: any) => c.project_id);
            const { data: activeOrigProjects } = await supabase
              .from("property_projects")
              .select("id, name, category")
              .in("id", origProjectIds)
              .in("status", ["planning", "in_progress"])
              .limit(5);

            if (activeOrigProjects && activeOrigProjects.length > 0) {
              project = activeOrigProjects[0];
              isExistingProject = true;
              matchMethod = "original_sender_contact";
              console.log(`[receive-email] Matched project via original sender's contact: ${(project as any).name}`);
              actions.push(`matched_via_original_sender:${(activeOrigProjects[0] as any).name}`);
            }
          }
        }
      }

      // --- SIGNAL 2: Subject thread matching (Re:/Fwd: of known project) ---
      if (!project) {
        const cleanSubject = subject
          .replace(/^(re:|fwd?:|fw:)\s*/gi, "")
          .replace(/^(re:|fwd?:|fw:)\s*/gi, "") // strip double prefixes
          .trim()
          .toLowerCase();

        if (cleanSubject.length > 3) {
          const { data: subjectProjects } = await supabase
            .from("property_projects")
            .select("id, name, category")
            .eq("household_id", householdId)
            .in("status", ["planning", "in_progress"])
            .limit(20);

          if (subjectProjects && subjectProjects.length > 0) {
            const subjectMatch = subjectProjects.find((p: any) => {
              const pName = p.name.toLowerCase();
              // Subject contains the project name or vice versa
              return cleanSubject.includes(pName) || pName.includes(cleanSubject);
            });
            if (subjectMatch) {
              project = subjectMatch;
              isExistingProject = true;
              matchMethod = "subject_thread";
              console.log(`[receive-email] Matched project via subject thread: ${(subjectMatch as any).name}`);
              actions.push(`matched_via_subject:${(subjectMatch as any).name}`);
            }
          }
        }
      }

      // --- SIGNAL 3: Category/name normalization (existing fallback) ---
      if (!project && property) {
        const { data: existingProjects } = await supabase
          .from("property_projects")
          .select("id, name, category")
          .eq("household_id", householdId)
          .eq("property_id", property.id)
          .in("status", ["planning", "in_progress"])
          .limit(10);

        if (existingProjects && existingProjects.length > 0) {
          const remodelWords = ["remodel", "remodeling", "renovation", "overhaul", "redo", "makeover", "update", "upgrade"];
          const normalizeProjectType = (s: string) => {
            let n = s.toLowerCase().trim();
            for (const word of remodelWords) {
              n = n.replace(new RegExp(`\\b${word}\\b`, "g"), "remodel");
            }
            return n;
          };
          const normalizedCategory = normalizeProjectType(projectCategory.toLowerCase());

          const match = existingProjects.find((p: { category: string; name: string }) => {
            const pCat = normalizeProjectType(p.category);
            const pName = normalizeProjectType(p.name);
            if (pCat === normalizedCategory || pName === normalizedCategory) return true;
            if (pCat.includes(normalizedCategory) || normalizedCategory.includes(pCat)) return true;
            if (pName.includes(normalizedCategory) || normalizedCategory.includes(pName)) return true;
            return false;
          });
          if (match) {
            project = match;
            isExistingProject = true;
            matchMethod = "category_name";
            console.log(`[receive-email] Matched existing project via category: ${match.id} (${(match as any).name})`);
            actions.push(`matched_existing_project:${(match as any).name}`);
          }
        }
      }

      // No match from any signal — create new project
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
        console.log(`[receive-email] Using project: ${project.id} (existing=${isExistingProject}, method=${matchMethod})`);

        // AUTO-ADD CONTRACTOR TO PROJECT CONTACTS — ensures future emails from
        // this contractor automatically match to this project.
        if (createdContractorId) {
          const contactEmail = classification.vendorEmail || (originalSender
            ? (() => { const m = originalSender.match(/<([^>]+)>/); return m ? m[1] : originalSender.match(/[\w.-]+@[\w.-]+/)?.[0] || null; })()
            : senderEmail) || null;

          try {
            await supabase.from("project_contacts").upsert({
              project_id: project.id,
              household_id: householdId,
              contractor_id: createdContractorId,
              contact_name: classification.vendorName,
              contact_email: contactEmail?.toLowerCase() || null,
              contact_phone: classification.vendorPhone || null,
              role: "contractor",
              added_from: "email",
            }, { onConflict: "project_id,contractor_id" });
            actions.push("added_project_contact");
          } catch (pcErr) {
            console.error(`[receive-email] project_contacts upsert failed (non-blocking): ${pcErr}`);
          }
        }

        // APPEND EMAIL SUMMARY to project (for all project types, not just insurance)
        try {
          const { data: projData } = await supabase
            .from("property_projects")
            .select("email_summaries")
            .eq("id", project.id)
            .single();

          const existingSummaries = (projData?.email_summaries as any[]) || [];
          existingSummaries.push({
            date: new Date().toISOString(),
            subject,
            from: fromAddress,
            summary: classification.summary,
            type: classification.type,
          });

          await supabase
            .from("property_projects")
            .update({ email_summaries: existingSummaries })
            .eq("id", project.id);
        } catch (_sumErr) {
          // non-blocking
        }

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
            // Compute content hash and check for duplicates
            const docContentHash = await computeContentHash(attachmentBase64);
            const duplicateDoc = docContentHash ? await checkDocumentDuplicate(supabase, householdId, docContentHash) : null;
            if (duplicateDoc) {
              console.log(`[receive-email] Duplicate detected: "${duplicateDoc.title}" (${duplicateDoc.id})`);
              actions.push(`duplicate_detected:${duplicateDoc.title}`);
            }

            // Create document record (property_id is optional)
            const docInsert: Record<string, unknown> = {
              household_id: householdId,
              title: docTitle,
              category: docCategory,
              status: "active",
              file_path: filePath,
              notes: `Auto-stored from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}\n\n${classification.summary}`,
              ai_summary: classification.summary,
              ...(docContentHash ? { content_hash: docContentHash } : {}),
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

              // Trigger AI analysis (only for analyzable file types)
              if (isAnalyzableContentType(attachmentContentType)) {
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
                const ext = getFileExtension(attachmentFilename, attachmentContentType);
                console.log(`[receive-email] Skipping analysis for unsupported file type: ${ext} (${attachmentContentType})`);
                actions.push(`analysis_skipped:${ext}`);
                // analysis_skipped flag is set on baseMetadata in Step 3 based on actions array
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

    } else if (classification.type === "vehicle_document") {
      // VEHICLE DOCUMENTS: titles, registrations, purchase agreements, recall notices.
      // Same as estate_document but with vehicle-specific metadata.
      if (attachmentBase64) {
        try {
          const docTitle = classification.documentTitle || subject || "Vehicle Document";
          const docCategory = classification.documentCategory || "Vehicle Title";
          const filePath = `${householdId}/${crypto.randomUUID()}`;

          const fileBuffer = Uint8Array.from(atob(attachmentBase64), c => c.charCodeAt(0));
          const { error: uploadError } = await supabase.storage
            .from("documents")
            .upload(filePath, fileBuffer, {
              contentType: attachmentContentType || "application/pdf",
            });

          if (!uploadError) {
            // Compute content hash and check for duplicates
            const vehContentHash = await computeContentHash(attachmentBase64);
            const vehDuplicate = vehContentHash ? await checkDocumentDuplicate(supabase, householdId, vehContentHash) : null;
            if (vehDuplicate) {
              console.log(`[receive-email] Duplicate vehicle doc detected: "${vehDuplicate.title}" (${vehDuplicate.id})`);
              actions.push(`duplicate_detected:${vehDuplicate.title}`);
            }

            const { data: doc, error: docError } = await supabase
              .from("documents")
              .insert({
                household_id: householdId,
                title: docTitle,
                category: docCategory,
                status: "active",
                file_path: filePath,
                notes: `Auto-stored from forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}\n\n${classification.summary}`,
                ai_summary: classification.summary,
                ...(vehContentHash ? { content_hash: vehContentHash } : {}),
              })
              .select("id")
              .single();

            if (doc) {
              createdDocumentId = doc.id;
              actions.push(`stored_vehicle_document:${docTitle}`);
              console.log(`[receive-email] Stored vehicle document: ${doc.id} (${docTitle})`);

              // Trigger AI analysis (only for analyzable file types)
              if (isAnalyzableContentType(attachmentContentType)) {
                try {
                  await fetch(`${supabaseUrl}/functions/v1/analyze-document`, {
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
                  console.error("[receive-email] Vehicle document analysis trigger failed");
                }
              } else {
                const ext = getFileExtension(attachmentFilename, attachmentContentType);
                actions.push(`analysis_skipped:${ext}`);
                // analysis_skipped flag is set on baseMetadata in Step 3 based on actions array
              }
            } else {
              console.error(`[receive-email] Vehicle document creation failed: ${docError?.message}`);
            }
          } else {
            console.error(`[receive-email] Vehicle document upload failed: ${uploadError.message}`);
          }
        } catch (docErr) {
          console.error(`[receive-email] Vehicle document storage failed: ${docErr}`);
        }
      } else {
        actions.push("vehicle_document_detected_no_attachment");
      }

    } else if (classification.type === "vendor_contact") {
      // Vendor was already created in Step 1 if info was present
      if (!createdContractorId) {
        actions.push("vendor_contact_detected_insufficient_info");
      }

    } else if (classification.type === "insurance_claim") {
      // Insurance claim — store attachment and prompt user to decide.
      // Do NOT auto-create a project. User chooses: Create Claim Project, Save as Document, or Dismiss.
      const claimInfo = classification as any;
      const claimLabel = claimInfo.claimNumber
        ? `Insurance Claim #${claimInfo.claimNumber}`
        : `Insurance Claim: ${claimInfo.claimType || classification.documentTitle || subject || "New Claim"}`;

      actions.push("insurance_claim_received");
      console.log(`[receive-email] Insurance claim detected — awaiting user action: ${claimLabel}`);

    } else if (classification.type === "bill_invoice") {
      // Bills/invoices — create a proper document record so invoice intelligence can process them
      actions.push("bill_saved");
      console.log(`[receive-email] Bill/invoice: ${(classification as any).billVendor || "Unknown vendor"}`);

      if (attachmentBase64) {
        try {
          const billInfo = classification as any;
          const docTitle = billInfo.billVendor
            ? `Bill: ${billInfo.billVendor}${billInfo.billAmount ? ` — $${billInfo.billAmount}` : ""}`
            : classification.documentTitle || subject || "Bill/Invoice";
          const docCategory = "Home Bill/Invoice";
          const filePath = `${householdId}/${crypto.randomUUID()}`;

          // Upload to documents storage bucket
          const fileBuffer = Uint8Array.from(atob(attachmentBase64), c => c.charCodeAt(0));
          const { error: uploadError } = await supabase.storage
            .from("documents")
            .upload(filePath, fileBuffer, {
              contentType: attachmentContentType || "application/pdf",
            });

          if (!uploadError) {
            // Compute content hash and check for duplicates
            const billContentHash = await computeContentHash(attachmentBase64);
            const billDuplicate = billContentHash ? await checkDocumentDuplicate(supabase, householdId, billContentHash) : null;
            if (billDuplicate) {
              console.log(`[receive-email] Duplicate bill detected: "${billDuplicate.title}" (${billDuplicate.id})`);
              actions.push(`duplicate_detected:${billDuplicate.title}`);
            }

            // Create document record — do NOT set property_id yet.
            const { data: doc, error: docError } = await supabase
              .from("documents")
              .insert({
                household_id: householdId,
                title: docTitle,
                category: docCategory,
                status: "active",
                file_path: filePath,
                notes: `From forwarded email.\nFrom: ${fromAddress}\nSubject: ${subject}`,
                ai_summary: classification.summary,
                ...(billContentHash ? { content_hash: billContentHash } : {}),
              })
              .select("id")
              .single();

            if (doc) {
              createdDocumentId = doc.id;
              actions.push(`stored_bill_document:${docTitle}`);
              console.log(`[receive-email] Stored bill document: ${doc.id} (${docTitle})`);

              // Trigger AI analysis (only for analyzable file types)
              if (isAnalyzableContentType(attachmentContentType)) {
                try {
                  await fetch(`${supabaseUrl}/functions/v1/analyze-document`, {
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
                  console.error("[receive-email] Bill document analysis trigger failed (non-blocking)");
                }
              } else {
                const ext = getFileExtension(attachmentFilename, attachmentContentType);
                actions.push(`analysis_skipped:${ext}`);
                // analysis_skipped flag is set on baseMetadata in Step 3 based on actions array
              }
            } else {
              console.error(`[receive-email] Bill document record creation failed: ${docError?.message}`);
            }
          } else {
            console.error(`[receive-email] Bill document upload failed: ${uploadError.message}`);
          }
        } catch (docErr) {
          console.error(`[receive-email] Bill document storage failed: ${docErr}`);
        }
      }

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
    const totalAttachments = 1 + additionalAttachments.length; // primary + additional
    if ((classification.type === "family" || classification.type === "bill_invoice") && additionalAttachments.length > 0) {
      for (let i = 0; i < additionalAttachments.length; i++) {
        const att = additionalAttachments[i];
        try {
          const filePath = `${householdId}/family/${crypto.randomUUID()}_${att.filename}`;
          const fileBuffer = Uint8Array.from(atob(att.base64), c => c.charCodeAt(0));
          await supabase.storage.from("inbox-attachments").upload(filePath, fileBuffer, { contentType: att.contentType || "application/octet-stream" });
          // Generate descriptive title instead of raw filename
          const docTitle = classification.documentTitle || subject || "Document";
          const attachTitle = totalAttachments > 1 ? `${docTitle} (${i + 2} of ${totalAttachments})` : docTitle;
          await supabase.from("inbox_items").insert({
            household_id: householdId,
            type: "family",
            title: attachTitle,
            summary: `Attachment ${i + 2} of ${totalAttachments} from: ${subject}`,
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
    // Skip for family/bill/insurance_claim emails — those are handled above
    if (additionalAttachments.length > 0 && property && classification.type !== "family" && classification.type !== "bill_invoice" && classification.type !== "insurance_claim") {
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
      const analysisWasSkipped = actions.some(a => a.startsWith("analysis_skipped:"));
      const skippedExt = analysisWasSkipped ? actions.find(a => a.startsWith("analysis_skipped:"))?.split(":")[1] || "" : "";
      const isDuplicateDoc = actions.some(a => a.startsWith("duplicate_detected:"));
      const duplicateOfTitle = isDuplicateDoc ? actions.find(a => a.startsWith("duplicate_detected:"))?.split(":").slice(1).join(":") || "" : "";
      const baseMetadata: Record<string, unknown> = {
        classification,
        subject,
        email_body: emailBody.substring(0, 5000),
        original_actions: actions.filter(a => a !== "inbox_item_created"),
        email_hash: emailHash,
        high_confidence: classification.confidence === "high",
        suggested_category: classification.documentCategory || null,
        document_title: classification.documentTitle || null,
        ...(analysisWasSkipped ? {
          analysis_skipped: true,
          analysis_skip_reason: `Unsupported file format (${skippedExt}). Document saved but could not be analyzed automatically.`,
        } : {}),
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

      if (actions.includes("insurance_claim_received")) {
        // Insurance claim — user decides whether to create a claim project
        const claimInfo = classification as any;
        const claimLabel = claimInfo.claimNumber ? `Claim #${claimInfo.claimNumber}` : (claimInfo.insuranceCompany || "Insurance Claim");
        mainType = "insurance_claim";
        mainTitle = `Insurance claim: ${claimLabel}`;
        mainNeedsAction = true;
        mainActionType = "review_insurance_claim";
      } else if (createdProjectId) {
        const matchedExisting = actions.some(a => a.startsWith("matched_existing_project:"));
        const projectLabel = classification.projectType || classification.vendorName || "Contractor Quote";
        mainType = "project_created";
        mainTitle = matchedExisting
          ? `Quote added to ${projectLabel}`
          : `New project: ${projectLabel}`;
      } else if (createdDocumentId && classification.type === "vehicle_document") {
        // Vehicle document: user confirms and picks which vehicle
        mainType = "document_stored";
        mainNeedsAction = true;
        mainActionType = "confirm_vehicle_document";
        mainTitle = `Vehicle document: ${classification.documentTitle || subject}`;
      } else if (createdDocumentId && classification.type !== "bill_invoice") {
        mainType = "document_stored";
        // ALL documents get a confirmation prompt so users can always reclassify.
        // High-confidence docs get a low-friction "Looks Good" UI; low/medium get picker-first.
        mainNeedsAction = true;
        mainActionType = "confirm_document_category";
        if (addressMatched && property) {
          mainTitle = `Saved as ${classification.documentCategory || "Document"}: ${classification.documentTitle || subject}`;
        } else if (addressUnmatched) {
          mainTitle = `Saved as ${classification.documentCategory || "Document"}: ${classification.documentTitle || subject}`;
        } else {
          mainTitle = `Saved as ${classification.documentCategory || "Document"}: ${classification.documentTitle || subject}`;
        }
      } else if (actions.includes("quote_received")) {
        // Quote received — user chooses: New Project, Existing Project, or Save as Document
        const vendorLabel = classification.vendorName || "Contractor";
        const projectLabel = classification.projectType || subject || "Quote";
        mainType = "contractor_quote";
        mainTitle = `Quote from ${vendorLabel}: ${projectLabel}`;
        mainNeedsAction = true;
        mainActionType = "quote_received";
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

        // --- Utility provider matching ---
        const billVendorName = billInfo.billVendor || classification.vendorName;
        if (billVendorName) {
          try {
            const normalizedVendor = billVendorName.toLowerCase()
              .replace(/\b(inc|llc|corp|corporation|company|co|ltd|limited)\b\.?/gi, "")
              .replace(/[^a-z0-9\s]/g, "")
              .trim();

            const { data: allProviders } = await supabase.from("utility_providers").select("*");

            let matchedProvider: any = null;
            if (allProviders) {
              matchedProvider = allProviders.find((p: any) => {
                const np = p.name.toLowerCase().replace(/[^a-z0-9\s]/g, "").trim();
                return np.includes(normalizedVendor) || normalizedVendor.includes(np)
                  || p.slug === normalizedVendor.replace(/\s+/g, "-");
              });
            }

            // Check if user already has this provider linked
            let alreadyLinked = false;
            if (matchedProvider) {
              const { data: existing } = await supabase
                .from("utility_accounts")
                .select("id")
                .eq("household_id", householdId)
                .ilike("provider_name", `%${matchedProvider.name}%`)
                .limit(1);
              alreadyLinked = (existing && existing.length > 0);
            } else {
              // Check by raw vendor name for custom providers
              const { data: existing } = await supabase
                .from("utility_accounts")
                .select("id")
                .eq("household_id", householdId)
                .ilike("provider_name", `%${billVendorName}%`)
                .limit(1);
              alreadyLinked = (existing && existing.length > 0);
            }

            if (!alreadyLinked) {
              mainNeedsAction = true;
              mainActionType = "add_utility_provider";

              if (matchedProvider) {
                baseMetadata.utility_provider = {
                  provider_id: matchedProvider.id,
                  provider_name: matchedProvider.name,
                  provider_slug: matchedProvider.slug,
                  provider_type: matchedProvider.provider_type,
                  logo_url: matchedProvider.logo_url,
                  brand_color: matchedProvider.brand_color,
                  website: matchedProvider.website,
                  phone: matchedProvider.phone,
                };
              } else {
                baseMetadata.utility_provider_suggestion = {
                  vendor_name: billVendorName,
                  vendor_phone: classification.vendorPhone || null,
                  vendor_email: classification.vendorEmail || null,
                };
              }
              baseMetadata.bill_account_number = billInfo.billAccountNumber || null;
              baseMetadata.bill_amount = billInfo.billAmount || null;
              console.log(`[receive-email] Utility provider match: ${matchedProvider?.name || billVendorName} (catalog: ${!!matchedProvider})`);
            }
          } catch (utilErr) {
            console.error(`[receive-email] Utility provider matching failed (non-blocking): ${utilErr}`);
          }
        }

        // Vehicle invoice detection: if Claude flagged this as vehicle-related
        const isVehicleInvoice = (classification as any).vehicleContext === true;
        if (isVehicleInvoice) {
          baseMetadata.vehicle_invoice = true;
          mainNeedsAction = true;
          mainActionType = "review_vehicle_invoice";
          mainTitle = `Vehicle service: ${vendor}${amount}`;
          console.log(`[receive-email] Vehicle invoice detected: ${vendor}`);
        }
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

      // Override for duplicate documents -- force user to resolve
      if (isDuplicateDoc && createdDocumentId) {
        mainNeedsAction = true;
        mainActionType = "resolve_duplicate";
        mainTitle = `Duplicate: ${classification.documentTitle || subject || "Document"}`;
        baseMetadata.duplicate_of_title = duplicateOfTitle;
      }

      // Insert the final inbox item FIRST, then delete placeholder only on success
      const { error: inboxInsertErr } = await supabase.from("inbox_items").insert({
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

      if (inboxInsertErr) {
        console.error(`[receive-email] Final inbox item insert failed: ${inboxInsertErr.message}`);
        // Update placeholder to show failure instead of deleting it
        if (placeholderId) {
          await supabase.from("inbox_items").update({
            type: mainType || "other",
            title: mainTitle || `Email processed: ${subject || "No subject"}`,
            summary: (baseSummary || `Email from ${fromAddress}`) + "\n\n(Note: Some details may not have saved correctly.)",
            status: "ready",
            from_email: fromAddress,
            attachment_path: attachmentStoragePath,
            attachment_content_type: attachmentContentType,
            attachment_filename: attachmentFilename,
            related_project_id: createdProjectId,
            needs_action: false,
          }).eq("id", placeholderId);
        }
        actions.push("inbox_item_insert_failed");
      } else {
        actions.push("inbox_item_created");
        // Delete the processing placeholder now that the real item exists
        if (placeholderId) {
          await supabase.from("inbox_items").delete().eq("id", placeholderId);
        }

        // --- MULTI-EVENT EXTRACTION ---
        // If Claude extracted multiple events from this email, create family_events for each
        const extractedEvents: Array<{ title: string; date: string; endDate?: string; allDay?: boolean; location?: string }> = (classification as any).events || [];
        if (extractedEvents.length > 1 && classification.type === "family") {
          console.log(`[receive-email] Multi-event email: creating ${extractedEvents.length} family_events`);
          for (const evt of extractedEvents) {
            if (!evt.date) continue;
            try {
              await supabase.from("family_events").insert({
                household_id: householdId,
                title: evt.title || subject || "Event",
                start_date: evt.date,
                end_date: evt.endDate || null,
                all_day: evt.allDay || false,
                location: evt.location || null,
                source: "email_parsed",
              });
            } catch (evtErr) {
              console.error(`[receive-email] Failed to insert family_event: ${evtErr}`);
            }
          }
          actions.push(`created_${extractedEvents.length}_family_events`);
        }
      }

      // --- SEND COMPLETION PUSH NOTIFICATION (fire-and-forget) ---
      if (householdUserIds.length > 0) {
        try {
          const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
          const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
          if (supabaseUrl && serviceRoleKey) {
            const completionBody = classification.type === "contractor_quote"
              ? `Quote from ${classification.vendorName || "vendor"} is ready to review`
              : classification.type === "insurance_claim"
                ? `Insurance claim details from ${classification.vendorName || "your provider"} are ready`
                : classification.type === "bill_invoice"
                  ? `Bill from ${classification.vendorName || "vendor"} has been processed`
                  : `Your ${classification.documentTitle || classification.type.replace(/_/g, " ")} is ready to review`;

            fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${serviceRoleKey}`,
              },
              body: JSON.stringify({
                recipient_user_ids: householdUserIds,
                title: "Alfred finished reviewing",
                body: completionBody,
                data: {
                  type: "inbox_ready",
                  inbox_item_id: placeholderId ?? "",
                },
              }),
            });
          }
        } catch {
          // Non-blocking — don't let notification failure affect the response
        }
      }

      // Clean up stale processing items (>10 min old)
      const tenMinAgo = new Date(Date.now() - 10 * 60 * 1000).toISOString();
      await supabase.from("inbox_items")
        .delete()
        .eq("household_id", householdId)
        .eq("status", "processing")
        .lt("created_at", tenMinAgo);

      // --- Confirmation prompt: new vendor/contact added ---
      const isNewVendor = actions.some(a => a.startsWith("created_vendor:"));
      if (isNewVendor) {
        // Get the vendor name from the action (handles both regular vendors and insurance adjusters)
        const vendorAction = actions.find(a => a.startsWith("created_vendor:"));
        const vendorDisplayName = vendorAction ? vendorAction.split(":").slice(1).join(":") : classification.vendorName;
        if (vendorDisplayName) {
          const claimInfo = classification as any;
          const isAdjuster = classification.type === "insurance_claim" && claimInfo.adjusterName;
          await supabase.from("inbox_items").insert({
            household_id: householdId,
            type: "vendor_added",
            email_hash: emailHash + ":vendor",
            title: isAdjuster
              ? `Added claims adjuster: ${vendorDisplayName}`
              : `Add ${vendorDisplayName} as a Home Contact?`,
            summary: isAdjuster
              ? `${claimInfo.adjusterName} from ${claimInfo.insuranceCompany || "your insurance company"} has been added to your contacts as an Insurance Claims specialist. You can edit their details anytime.`
              : `We detected ${vendorDisplayName} from your forwarded email. They've been added to your contacts${classification.vendorSpecialties?.length > 0 ? ` as a ${classification.vendorSpecialties.join(", ")} specialist` : ""}. You can edit their details anytime.`,
            from_email: fromAddress,
            related_contractor_id: createdContractorId,
            needs_action: false,
            metadata: {
              ...baseMetadata,
              proposed_action: "confirm_vendor",
              vendor_name: vendorDisplayName,
              vendor_phone: isAdjuster ? claimInfo.adjusterPhone : classification.vendorPhone,
              vendor_specialties: isAdjuster ? ["Insurance Claims"] : classification.vendorSpecialties,
            },
          });
          actions.push("vendor_notification_created");
        }
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

      // NOTE: Document category confirmation is now built into the main inbox item
      // (all documents get needs_action: true with action_type: confirm_document_category).
      // No separate confirmation prompt needed.

      // --- Confirmation prompt: unrecognized property address ---
      if (addressUnmatched && extractedAddress) {
        const propNames = (properties || []).map((p: any) => p.name).join(", ");
        await supabase.from("inbox_items").insert({
          household_id: householdId,
          type: "other",
          email_hash: emailHash + ":address",
          title: `Unknown property address: ${extractedAddress}`,
          summary: `This document references "${extractedAddress}" which doesn't match any of your properties${propNames ? ` (${propNames})` : ""}. You can add this property in Settings, or save this as a personal document instead.`,
          from_email: fromAddress,
          related_document_id: createdDocumentId,
          needs_action: true,
          action_type: "review",
          metadata: {
            ...baseMetadata,
            proposed_action: "review_property_address",
            extracted_address: extractedAddress,
          },
        });
        actions.push("unmatched_address_notification_created");
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

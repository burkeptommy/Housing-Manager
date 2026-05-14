import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  householdContractorCategoryFor,
  routineKindForChip,
  defaultCadenceForQuizRoutine,
  isLikelySameVendor,
  normalizeCompanyName,
  chezRequestRoutingForUrgency,
  type AssessmentUrgency,
} from "../_shared/quiz-mapper-shared.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const PROVIDER_SITE_URL = "https://www.getchez.com/handyman.html";
// Field tech surface is now the native Chez Field iOS app (TestFlight).
// The legacy PWA at /handyman-visit.html was retired 2026-05-08; every
// outbound link that used to point at it now routes the contractor to
// install the iOS app, which authenticates them as a workspace member
// and opens the visit on the Today tab.
const FIELD_SITE_URL = "https://testflight.apple.com/join/sw4xWsTA";
const QUOTE_SITE_URL = "https://www.getchez.com/handyman-quote.html";
const FROM_EMAIL = "hello@getchez.com";
const FROM_NAME = "Chez Field";

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function compactString(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function escapeHtml(value: unknown) {
  return compactString(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function firstName(value: unknown) {
  const fullName = compactString(value);
  if (!fullName) return "";
  return fullName.split(/\s+/)[0] ?? fullName;
}

function displayNameOrEmail(name: unknown, email: unknown, fallback = "Client") {
  return compactString(name) || compactString(email) || fallback;
}

function capitalize(value: unknown) {
  const raw = compactString(value);
  return raw ? `${raw[0]?.toUpperCase() ?? ""}${raw.slice(1)}` : "";
}

function uniqueByEmail(rows: Array<{ email: string; name?: string | null }>) {
  const seen = new Set<string>();
  return rows.filter((row) => {
    const email = normalizedEmail(row.email);
    if (!email || seen.has(email)) return false;
    seen.add(email);
    row.email = email;
    return true;
  });
}

function listText(values: string[]) {
  const clean = values.map((value) => compactString(value)).filter(Boolean);
  if (!clean.length) return "";
  if (clean.length === 1) return clean[0];
  if (clean.length === 2) return `${clean[0]} and ${clean[1]}`;
  return `${clean.slice(0, -1).join(", ")}, and ${clean[clean.length - 1]}`;
}

function moneyLabel(value: unknown) {
  const amount = numberValue(value);
  return `$${amount.toFixed(2)}`;
}

function quoteStatusDescription(status: string) {
  switch (status) {
    case "sent":
      return "Quote sent";
    case "viewed":
      return "Viewed";
    case "approved":
      return "Approved";
    case "declined":
      return "Declined";
    case "withdrawn":
      return "Withdrawn";
    default:
      return "Draft";
  }
}

function normalizedEmail(value: unknown) {
  return compactString(value).toLowerCase();
}

function ilikeTerm(value: unknown) {
  return compactString(value)
    .replaceAll("%", "")
    .replaceAll("_", "")
    .replaceAll(",", " ")
    .trim();
}

function phoneDigits(value: unknown) {
  return compactString(value).replace(/\D+/g, "");
}

function numberValue(value: unknown) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return 0;
}

function isoNow() {
  return new Date().toISOString();
}

function roundMoney(value: number) {
  return Math.round(value * 100) / 100;
}

function localDateString(value?: string | null) {
  const date = value ? new Date(value) : new Date();
  if (Number.isNaN(date.getTime())) return "";
  return date.toISOString().slice(0, 10);
}

function addressLine(parts: Array<unknown>) {
  return parts.map((part) => compactString(part)).filter(Boolean).join(", ");
}

function shortAccessCode(prefix = "CHEZ") {
  return `${prefix}-${crypto.randomUUID().replaceAll("-", "").slice(0, 6).toUpperCase()}`;
}

function roleLabel(role: string) {
  switch (role) {
    case "owner":
      return "Owner";
    case "admin":
      return "Administrator";
    case "dispatcher":
      return "Dispatcher";
    case "technician":
      return "Field technician";
    default:
      return "Team member";
  }
}

function rolePermissions(role: string) {
  const canManageCrew = role === "owner" || role === "admin";
  const canAssignWork = canManageCrew || role === "dispatcher";
  const canBuildQuotes = canAssignWork;
  const canSeeFinancials = canAssignWork;
  const canManageWorkspace = canManageCrew;
  return {
    canManageCrew,
    canAssignWork,
    canBuildQuotes,
    canManageWorkspace,
    canSeeFinancials,
    canSeeWorkspaceOverview: canAssignWork,
    isFieldTechnician: role === "technician",
  };
}

function quoteStatusLabel(status: string) {
  switch (status) {
    case "draft":
      return "Draft";
    case "sent":
      return "Sent";
    case "viewed":
      return "Viewed";
    case "approved":
      return "Approved";
    case "declined":
      return "Declined";
    case "withdrawn":
      return "Withdrawn";
    case "countered_by_homeowner":
      return "Homeowner countered";
    case "superseded":
      return "Superseded";
    default:
      return "Quote";
  }
}

function requestStatusLabel(status: string) {
  switch (status) {
    case "draft":
      return "Draft";
    case "submitted":
      return "Requested";
    case "scheduled":
      return "Scheduled";
    case "sent_to_handyman":
      return "Sent to contractor";
    case "alternate_dates_proposed":
      return "Dates proposed";
    case "awaiting_homeowner":
      return "Reply needed";
    case "confirmed":
      return "Confirmed";
    case "on_my_way":
      return "On my way";
    case "checked_in":
      return "Checked in";
    case "quoted":
      return "Quoted";
    case "in_progress":
      return "In progress";
    case "completed":
      return "Completed";
    case "follow_up_recommended":
      return "Follow-up recommended";
    case "cancelled":
      return "Cancelled";
    case "declined":
      return "Declined";
    default:
      return "Visit update";
  }
}

/**
 * Normalize a raw provider_quotes.line_items row (snake_case from the
 * DB) into the camelCase shape every client reads. Without this, the
 * React Quotes screen reads `line.unitPrice` as undefined and renders
 * every row as $0 even though the row stores the correct value, and
 * the Edit Quote modal pre-fills with zeros and silently destroys
 * the prices on save.
 */
function mapLineItemForClient(item: Record<string, unknown>) {
  const quantity = numberValue(item.quantity ?? 1);
  const unitPrice = numberValue(item.unit_price ?? item.unitPrice ?? 0);
  return {
    id: compactString(item.id) || undefined,
    name: compactString(item.name),
    description: compactString(item.description),
    unit: compactString(item.unit) || "ea",
    quantity,
    unitPrice,
    total: numberValue(item.total ?? quantity * unitPrice),
    // Phase 78: optional cross-link to a structured punch item. The
    // homeowner reviewing a quote can see "this line covers [punch item]";
    // the handyman building a quote can drag a punch item into the line.
    punchItemId: compactString(item.punch_item_id ?? item.punchItemId) || undefined,
  };
}

/// Phase 78: client-facing shape for `handyman_punch_items` rows. Camel-
/// cases column names + drops noisy server-only fields. Both the field
/// app and the desktop Operations Desk decode this shape.
function mapPunchItemForClient(item: Record<string, unknown>) {
  return {
    id: compactString(item.id),
    householdId: compactString(item.household_id),
    propertyId: compactString(item.property_id) || null,
    assignedVisitTaskId: compactString(item.assigned_visit_task_id) || null,
    systemId: compactString(item.system_id) || null,
    systemLabelSnapshot: compactString(item.system_label_snapshot) || null,
    templateId: compactString(item.template_id) || null,
    title: compactString(item.title),
    description: compactString(item.description) || null,
    source: compactString(item.source),
    status: compactString(item.status) || "pending",
    priority: compactString(item.priority) || "medium",
    estimatedMinutes: item.estimated_minutes != null ? numberValue(item.estimated_minutes) : null,
    estimatedCostRange: compactString(item.estimated_cost_range) || null,
    materialRequired: Boolean(item.material_required),
    costBasis: compactString(item.cost_basis) || "time_and_materials",
    attachments: Array.isArray(item.attachments) ? item.attachments : [],
    // Wave M2 — capture depth fields. Field tech writes these via
    // attach_punch_photo / attach_punch_voice / set_punch_materials /
    // set_punch_time_spent. Operations Desk + iOS Field both decode this
    // shape; defaults stay aligned with the column defaults so a brand
    // new row reads as `[]`/`0`/`null` everywhere.
    materialsUsed: Array.isArray(item.materials_used) ? item.materials_used : [],
    timeSpentSeconds: item.time_spent_seconds != null ? numberValue(item.time_spent_seconds) : 0,
    voiceNotePath: compactString(item.voice_note_path) || null,
    addedAfterLock: Boolean(item.added_after_lock),
    proposedByRole: compactString(item.proposed_by_role) || null,
    proposedAt: item.proposed_at ?? null,
    proposalMessage: compactString(item.proposal_message) || null,
    proposalStatus: compactString(item.proposal_status) || "none",
    proposalExpiresAt: item.proposal_expires_at ?? null,
    acceptedAt: item.accepted_at ?? null,
    declinedAt: item.declined_at ?? null,
    declinedReason: compactString(item.declined_reason) || null,
    completedAt: item.completed_at ?? null,
    createdAt: item.created_at,
    updatedAt: item.updated_at,
  };
}

function quoteSummary(lineItems: Array<Record<string, unknown>>) {
  const subtotal = roundMoney(
    lineItems.reduce((sum, item) => {
      const quantity = numberValue(item.quantity || 1);
      const unitPrice = numberValue(item.unit_price || item.unitPrice || 0);
      return sum + quantity * unitPrice;
    }, 0),
  );
  return {
    subtotal,
    taxTotal: 0,
    total: subtotal,
  };
}

function providerInviteUrl(token: string) {
  return `${PROVIDER_SITE_URL}?invite=${encodeURIComponent(token)}`;
}

function teamInviteUrl(token: string) {
  return `${PROVIDER_SITE_URL}?teamInvite=${encodeURIComponent(token)}`;
}

function fieldVisitUrl(_token: string, _visitId?: string | null) {
  // 2026-05-08: the PWA at /handyman-visit.html is retired. The token /
  // visit-id parameters are no longer in use because the native Chez Field
  // iOS app authenticates workspace members via Supabase session, not a
  // portal_token, and resolves the visit by request id from the Today tab.
  // We return the bare TestFlight URL so any outbound email / SMS still
  // gives the contractor a working install link. Parameters are intentionally
  // discarded but kept on the signature so the call sites compile unchanged.
  return FIELD_SITE_URL;
}

function publicQuoteUrl(token: string) {
  return `${QUOTE_SITE_URL}?quote=${encodeURIComponent(token)}`;
}

function quoteRecipientKind(householdId: string) {
  if (householdId) return "linked_home";
  return "prospect";
}

function providerQuoteMessageBody(
  title: string,
  total: number,
  lineItemCount: number,
  note?: string,
) {
  const summary = `${title} is ready at ${moneyLabel(total)} across ${lineItemCount} line item${lineItemCount === 1 ? "" : "s"}.`;
  const cleanNote = compactString(note);
  return cleanNote ? `${summary} ${cleanNote}` : summary;
}

function quotePreviewText(title: string, total: number, providerName: string) {
  return `${providerName} sent ${title} for ${moneyLabel(total)}.`;
}

function emailShell(args: { preview: string; heading: string; greeting: string; intro: string; bodyHtml: string; ctaLabel?: string; ctaUrl?: string; footer?: string }) {
  const cta = args.ctaLabel && args.ctaUrl
    ? `<tr><td style="padding:28px 32px 0 32px;text-align:center;">
        <a href="${escapeHtml(args.ctaUrl)}" style="display:inline-block;padding:14px 28px;background:#ef6f5d;color:#fff;text-decoration:none;border-radius:14px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:15px;font-weight:700;">${escapeHtml(args.ctaLabel)}</a>
      </td></tr>`
    : "";

  return `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${escapeHtml(args.heading)}</title>
  </head>
  <body style="margin:0;padding:0;background:#f3eee7;font-family:Georgia,serif;color:#2a2252;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f3eee7;">
      <tr>
        <td align="center" style="padding:40px 16px;">
          <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;background:#fbf8f4;border-radius:22px;border:1px solid rgba(42,34,82,0.08);overflow:hidden;">
            <tr>
              <td style="padding:28px 32px 8px 32px;background:linear-gradient(160deg,#2a2252,#473985);color:#fff;">
                <div style="font-size:13px;letter-spacing:0.16em;text-transform:uppercase;opacity:0.78;">Chez Field</div>
                <div style="font-size:32px;line-height:1.08;font-weight:700;margin-top:10px;">${escapeHtml(args.heading)}</div>
                <div style="font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:14px;line-height:1.55;color:rgba(255,255,255,0.82);margin-top:12px;">${escapeHtml(args.preview)}</div>
              </td>
            </tr>
            <tr>
              <td style="padding:28px 32px 0 32px;font-size:18px;line-height:1.5;">${escapeHtml(args.greeting)}</td>
            </tr>
            <tr>
              <td style="padding:16px 32px 0 32px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:15px;line-height:1.7;color:#2a2252;">${escapeHtml(args.intro)}</td>
            </tr>
            <tr>
              <td style="padding:24px 32px 0 32px;">${args.bodyHtml}</td>
            </tr>
            ${cta}
            <tr>
              <td style="padding:28px 32px 32px 32px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:12px;line-height:1.6;color:rgba(42,34,82,0.68);text-align:center;">${escapeHtml(args.footer || "Chez Field keeps the quote, client communication, and home context together so the next stop is easier than the last.")}</td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}

function quoteLineItemsHtml(lineItems: Array<Record<string, unknown>>) {
  return `
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;border:1px solid rgba(42,34,82,0.09);border-radius:18px;overflow:hidden;background:#fff;">
      <tr>
        <td colspan="3" style="padding:16px 18px;background:rgba(42,34,82,0.04);font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:12px;letter-spacing:0.12em;text-transform:uppercase;color:rgba(42,34,82,0.72);">Scope</td>
      </tr>
      ${lineItems.map((item) => {
        const quantity = numberValue(item.quantity || 1);
        const unitPrice = numberValue(item.unit_price || item.unitPrice || 0);
        const lineTotal = quantity * unitPrice;
        return `
          <tr>
            <td style="padding:16px 18px;border-top:1px solid rgba(42,34,82,0.08);vertical-align:top;">
              <div style="font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:15px;font-weight:700;color:#2a2252;">${escapeHtml(item.name)}</div>
              ${compactString(item.description) ? `<div style="margin-top:6px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:13px;line-height:1.5;color:rgba(42,34,82,0.74);">${escapeHtml(item.description)}</div>` : ""}
            </td>
            <td style="padding:16px 18px;border-top:1px solid rgba(42,34,82,0.08);font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:14px;color:rgba(42,34,82,0.78);white-space:nowrap;vertical-align:top;">${escapeHtml(String(quantity))} ${escapeHtml(compactString(item.unit) || "ea")} × ${moneyLabel(unitPrice)}</td>
            <td style="padding:16px 18px;border-top:1px solid rgba(42,34,82,0.08);font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:14px;font-weight:700;color:#2a2252;white-space:nowrap;text-align:right;vertical-align:top;">${moneyLabel(lineTotal)}</td>
          </tr>
        `;
      }).join("")}
    </table>
  `;
}

function quoteLineItemsText(lineItems: Array<Record<string, unknown>>) {
  return lineItems.map((item) => {
    const quantity = numberValue(item.quantity || 1);
    const unitPrice = numberValue(item.unit_price || item.unitPrice || 0);
    const lineTotal = quantity * unitPrice;
    const description = compactString(item.description);
    return [
      `- ${compactString(item.name)} (${quantity} ${compactString(item.unit) || "ea"} x ${moneyLabel(unitPrice)} = ${moneyLabel(lineTotal)})`,
      description ? `  ${description}` : "",
    ].filter(Boolean).join("\n");
  }).join("\n");
}

async function sendEmail(options: {
  to: Array<{ email: string; name?: string | null }>;
  subject: string;
  html: string;
  text: string;
  replyToEmail?: string | null;
  replyToName?: string | null;
  categories?: string[];
}) {
  const sendgridKey = Deno.env.get("SENDGRID_API_KEY");
  if (!sendgridKey) {
    throw new Error("Email service not configured");
  }

  const recipients = uniqueByEmail(options.to);
  if (!recipients.length) {
    throw new Error("No email recipients found");
  }

  const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${sendgridKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      personalizations: [
        {
          to: recipients.map((recipient) => ({
            email: recipient.email,
            name: compactString(recipient.name) || undefined,
          })),
          subject: options.subject,
        },
      ],
      from: { email: FROM_EMAIL, name: FROM_NAME },
      reply_to: options.replyToEmail
        ? {
            email: options.replyToEmail,
            name: compactString(options.replyToName) || FROM_NAME,
          }
        : undefined,
      content: [
        { type: "text/plain", value: options.text },
        { type: "text/html", value: options.html },
      ],
      categories: options.categories ?? ["handyman_provider"],
    }),
  });

  if (!response.ok) {
    const detail = await response.text().catch(() => "");
    throw new Error(`SendGrid ${response.status}: ${detail.slice(0, 240)}`);
  }

  return {
    sent: true,
    channel: "email",
    recipientCount: recipients.length,
    recipients: recipients.map((recipient) => recipient.email),
  };
}

type ServiceClient = ReturnType<typeof createClient>;

async function getAuthenticatedUser(service: ServiceClient, req: Request) {
  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice("Bearer ".length) : "";
  if (!token) return null;
  const { data, error } = await service.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user;
}

async function currentHouseholdIdForUser(service: ServiceClient, userId: string) {
  if (!userId) return null;
  const { data, error } = await service
    .from("users")
    .select("household_id")
    .eq("id", userId)
    .limit(1)
    .maybeSingle();
  if (error) throw error;
  return compactString(data?.household_id);
}

const MEMBER_SELECT =
  "id, workspace_id, role, full_name, email, phone, title, status, invite_token, user_id, provider_workspaces(*)";

async function getWorkspaceMembership(
  service: ServiceClient,
  userId: string,
  authEmail?: string,
  preferredWorkspaceId?: string,
) {
  // Wave S: when the caller passes a preferredWorkspaceId (the SPA sends
  // this from localStorage so the user's last-selected workspace sticks),
  // try to load the membership for THAT workspace first. Fall through to
  // the default first-active selection only if the preferred workspace
  // isn't a valid membership for this user. We never trust the preference
  // blindly — RLS-equivalent check via `.eq("user_id", userId)` and
  // `.eq("status", "active")` ensures the caller actually belongs there.
  if (preferredWorkspaceId) {
    const preferred = await service
      .from("provider_workspace_members")
      .select(MEMBER_SELECT)
      .eq("user_id", userId)
      .eq("workspace_id", preferredWorkspaceId)
      .eq("status", "active")
      .limit(1)
      .maybeSingle();
    if (preferred.error) throw preferred.error;
    if (preferred.data) return preferred.data as Record<string, unknown>;
  }

  // Primary: active row already pinned to this auth.users.id.
  const direct = await service
    .from("provider_workspace_members")
    .select(MEMBER_SELECT)
    .eq("user_id", userId)
    .eq("status", "active")
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();
  if (direct.error) throw direct.error;
  if (direct.data) return direct.data as Record<string, unknown>;

  const trimmedEmail = authEmail?.trim().toLowerCase();
  if (!trimmedEmail) return null;

  // Fallback 1: an active row whose email matches the verified auth email
  // but whose user_id points at a different auth.users row. Happens when
  // the same person signs in via different providers (email/password on web,
  // Apple Sign-In on iOS, etc.) — Supabase keeps separate auth.users rows
  // per identity but the verified email is the same. Claim the row by
  // repointing user_id to the current session so the fast path hits next time.
  const activeByEmail = await service
    .from("provider_workspace_members")
    .select(MEMBER_SELECT)
    .ilike("email", trimmedEmail)
    .eq("status", "active")
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();
  if (activeByEmail.error) throw activeByEmail.error;
  if (activeByEmail.data) {
    const row = activeByEmail.data as Record<string, unknown>;
    const memberId = compactString(row.id);
    if (memberId && compactString(row.user_id) !== userId) {
      await service
        .from("provider_workspace_members")
        .update({ user_id: userId, last_seen_at: isoNow(), updated_at: isoNow() })
        .eq("id", memberId);
    }
    return { ...row, user_id: userId };
  }

  // Fallback 2: an invited row addressed to the verified auth email (no
  // explicit invite token in the request). Auto-claim it on first sign-in
  // so a sole proprietor / single-seat invitee doesn't dead-end.
  const invitedByEmail = await service
    .from("provider_workspace_members")
    .select(MEMBER_SELECT)
    .ilike("email", trimmedEmail)
    .eq("status", "invited")
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();
  if (invitedByEmail.error) throw invitedByEmail.error;
  if (invitedByEmail.data) {
    const row = invitedByEmail.data as Record<string, unknown>;
    const memberId = compactString(row.id);
    if (memberId) {
      await service
        .from("provider_workspace_members")
        .update({
          user_id: userId,
          status: "active",
          invite_token: null,
          last_seen_at: isoNow(),
          updated_at: isoNow(),
        })
        .eq("id", memberId);
    }
    return { ...row, user_id: userId, status: "active", invite_token: null };
  }

  return null;
}

async function fetchTeamInvitePreview(service: ServiceClient, token: string) {
  const { data, error } = await service
    .from("provider_workspace_members")
    .select("id, workspace_id, role, full_name, email, phone, title, status, provider_workspaces(*)")
    .eq("invite_token", token)
    .eq("status", "invited")
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  if (!data) return null;

  const workspace = (data.provider_workspaces as Record<string, unknown> | undefined) ?? {};
  return {
    token,
    inviteUrl: teamInviteUrl(token),
    member: {
      id: compactString(data.id),
      fullName: compactString(data.full_name) || "Team member",
      email: compactString(data.email),
      phone: compactString(data.phone),
      title: compactString(data.title) || roleLabel(compactString(data.role)),
      role: compactString(data.role),
      roleLabel: roleLabel(compactString(data.role)),
      status: compactString(data.status),
    },
    workspace: {
      id: compactString(workspace.id),
      companyName: compactString(workspace.company_name) || "Chez Field",
      primaryEmail: compactString(workspace.primary_email),
      primaryPhone: compactString(workspace.primary_phone),
      website: compactString(workspace.website),
    },
  };
}

async function householdRecipients(service: ServiceClient, householdId: string) {
  if (!householdId) return [];
  const { data, error } = await service
    .from("users")
    .select("email, full_name")
    .eq("household_id", householdId);
  if (error) throw error;
  return uniqueByEmail(
    ((data ?? []) as Record<string, unknown>[])
      .map((row) => ({
        email: normalizedEmail(row.email),
        name: compactString(row.full_name),
      })),
  );
}

async function providerNotificationRecipients(service: ServiceClient, workspaceId: string) {
  const [{ data: workspace, error: workspaceError }, { data: members, error: membersError }] = await Promise.all([
    service
      .from("provider_workspaces")
      .select("company_name, primary_email, primary_phone")
      .eq("id", workspaceId)
      .limit(1)
      .maybeSingle(),
    service
      .from("provider_workspace_members")
      .select("email, full_name, role, status")
      .eq("workspace_id", workspaceId)
      .eq("status", "active"),
  ]);

  if (workspaceError) throw workspaceError;
  if (membersError) throw membersError;

  const quoteCapable = ((members ?? []) as Record<string, unknown>[])
    .filter((row) => rolePermissions(compactString(row.role)).canBuildQuotes)
    .map((row) => ({
      email: normalizedEmail(row.email),
      name: compactString(row.full_name),
    }));

  const recipients = uniqueByEmail([
    ...quoteCapable,
    {
      email: normalizedEmail(workspace?.primary_email),
      name: compactString(workspace?.company_name),
    },
  ]);

  return {
    recipients,
    workspace: {
      companyName: compactString(workspace?.company_name) || "Chez Field",
      primaryEmail: compactString(workspace?.primary_email),
      primaryPhone: compactString(workspace?.primary_phone),
    },
  };
}

function serializeProviderDirectoryWorkspace(
  workspace: Record<string, unknown> | null | undefined,
  options: {
    isLinked?: boolean;
    isPreferred?: boolean;
  } = {},
) {
  return {
    id: compactString(workspace?.id),
    companyName: compactString(workspace?.company_name) || "Chez Field",
    primaryEmail: compactString(workspace?.primary_email),
    primaryPhone: compactString(workspace?.primary_phone),
    website: compactString(workspace?.website),
    activeMemberCount: numberValue(workspace?.active_member_count),
    invitedMemberCount: numberValue(workspace?.invited_member_count),
    isLinked: Boolean(options.isLinked),
    isPreferred: Boolean(options.isPreferred),
  };
}

async function searchProviderDirectory(
  service: ServiceClient,
  userId: string,
  query: string,
  limit = 18,
) {
  const householdId = await currentHouseholdIdForUser(service, userId);
  const cleanQuery = ilikeTerm(query);

  let workspaceQuery = service
    .from("provider_workspaces")
    .select("id, company_name, primary_email, primary_phone, website, active_member_count, invited_member_count, updated_at")
    .order("updated_at", { ascending: false })
    .limit(limit);

  if (cleanQuery) {
    workspaceQuery = workspaceQuery.or(
      `company_name.ilike.%${cleanQuery}%,primary_email.ilike.%${cleanQuery}%,website.ilike.%${cleanQuery}%`,
    );
  }

  const { data: workspaces, error: workspaceError } = await workspaceQuery;
  if (workspaceError) throw workspaceError;

  const rows = (workspaces ?? []) as Record<string, unknown>[];
  if (!rows.length) return [];

  const workspaceIds = rows.map((row) => compactString(row.id)).filter(Boolean);
  let linkedWorkspaceIds = new Set<string>();
  let preferredWorkspaceIds = new Set<string>();

  if (householdId) {
    const [{ data: household }, { data: householdContractors, error: contractorError }] = await Promise.all([
      service
        .from("households")
        .select("preferred_handyman_contractor_id")
        .eq("id", householdId)
        .limit(1)
        .maybeSingle(),
      service
        .from("contractors")
        .select("id")
        .eq("household_id", householdId),
    ]);

    if (contractorError) throw contractorError;

    const householdContractorIds = ((householdContractors ?? []) as Record<string, unknown>[])
      .map((row) => compactString(row.id))
      .filter(Boolean);

    if (householdContractorIds.length) {
      const { data: links, error: linkError } = await service
        .from("provider_contractor_links")
        .select("workspace_id, contractor_id")
        .in("workspace_id", workspaceIds)
        .in("contractor_id", householdContractorIds);

      if (linkError) throw linkError;

      const preferredContractorId = compactString(household?.preferred_handyman_contractor_id);
      linkedWorkspaceIds = new Set(
        ((links ?? []) as Record<string, unknown>[])
          .map((row) => compactString(row.workspace_id))
          .filter(Boolean),
      );
      preferredWorkspaceIds = new Set(
        ((links ?? []) as Record<string, unknown>[])
          .filter((row) => compactString(row.contractor_id) === preferredContractorId)
          .map((row) => compactString(row.workspace_id))
          .filter(Boolean),
      );
    }
  }

  return rows.map((workspace) =>
    serializeProviderDirectoryWorkspace(workspace, {
      isLinked: linkedWorkspaceIds.has(compactString(workspace.id)),
      isPreferred: preferredWorkspaceIds.has(compactString(workspace.id)),
    })
  );
}

async function addQuoteMessage(
  service: ServiceClient,
  message: {
    workspaceId: string;
    quoteId: string;
    requestId?: string | null;
    householdId?: string | null;
    senderRole: "provider" | "homeowner" | "prospect" | "haven";
    senderName?: string | null;
    senderEmail?: string | null;
    deliveryChannel?: "system" | "email" | "web" | "in_app";
    body: string;
    metadata?: Record<string, unknown>;
  },
) {
  const { error } = await service.from("provider_quote_messages").insert({
    workspace_id: message.workspaceId,
    quote_id: message.quoteId,
    request_id: message.requestId || null,
    household_id: message.householdId || null,
    sender_role: message.senderRole,
    sender_name: compactString(message.senderName) || null,
    sender_email: normalizedEmail(message.senderEmail) || null,
    delivery_channel: message.deliveryChannel || "system",
    body: message.body,
    metadata: message.metadata ?? {},
  });
  if (error) throw error;
}

async function linkProviderWorkspaceForHomeowner(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const userId = compactString(user.id);
  const householdId = await currentHouseholdIdForUser(service, userId);
  if (!householdId) {
    throw new Error("This login does not have a homeowner household yet");
  }

  const workspaceId = compactString(body.workspaceId || body.workspace_id);
  if (!workspaceId) throw new Error("Missing provider workspace");

  const { data: workspace, error: workspaceError } = await service
    .from("provider_workspaces")
    .select("id, company_name, primary_email, primary_phone, website, active_member_count, invited_member_count")
    .eq("id", workspaceId)
    .limit(1)
    .maybeSingle();

  if (workspaceError) throw workspaceError;
  if (!workspace) throw new Error("Provider workspace not found");

  const contractorId = await ensureHouseholdContractorForWorkspace(service, {
    workspaceId,
    householdId,
    companyName: compactString(workspace.company_name),
    contactName: compactString(workspace.company_name),
    email: compactString(workspace.primary_email),
    phone: compactString(workspace.primary_phone),
    website: compactString(workspace.website),
    claimSource: "manual",
  });

  if (!contractorId) throw new Error("Could not connect this provider to the home");

  const setPreferred = body.setPreferred !== false;
  if (setPreferred) {
    const { error: householdError } = await service
      .from("households")
      .update({
        preferred_handyman_contractor_id: contractorId,
      })
      .eq("id", householdId);

    if (householdError) throw householdError;
  }

  const { data: contractor, error: contractorError } = await service
    .from("contractors")
    .select("*")
    .eq("id", contractorId)
    .limit(1)
    .single();

  if (contractorError) throw contractorError;

  return {
    contractor,
    workspace: serializeProviderDirectoryWorkspace(workspace as Record<string, unknown>, {
      isLinked: true,
      isPreferred: setPreferred,
    }),
  };
}

async function mirrorQuoteMessageToRequestThread(
  service: ServiceClient,
  params: {
    requestId?: string | null;
    householdId?: string | null;
    senderRole: "homeowner" | "vendor" | "haven";
    body: string;
    metadata?: Record<string, unknown>;
  },
) {
  if (!params.requestId || !params.householdId) return;
  const { error } = await service.from("handyman_request_messages").insert({
    request_id: params.requestId,
    household_id: params.householdId,
    sender_role: params.senderRole,
    body: params.body,
    metadata: params.metadata ?? {},
  });
  if (error) throw error;
}

async function publicQuotePayload(service: ServiceClient, token: string) {
  const { data: quote, error: quoteError } = await service
    .from("provider_quotes")
    .select("*")
    .eq("public_share_token", token)
    .limit(1)
    .maybeSingle();

  if (quoteError) throw quoteError;
  if (!quote) return null;

  const propertyId = compactString(quote.property_id);
  const workspaceId = compactString(quote.workspace_id);
  const householdId = compactString(quote.household_id);

  const [{ data: property }, { data: workspace }, { data: messages }, { data: recipients }] = await Promise.all([
    propertyId
      ? service
          .from("properties")
          .select("id, name, street, city, state, zip_code")
          .eq("id", propertyId)
          .limit(1)
          .maybeSingle()
      : Promise.resolve({ data: null }),
    service
      .from("provider_workspaces")
      .select("id, company_name, primary_email, primary_phone, website")
      .eq("id", workspaceId)
      .limit(1)
      .maybeSingle(),
    service
      .from("provider_quote_messages")
      .select("*")
      .eq("quote_id", quote.id)
      .order("created_at", { ascending: true })
      .limit(24),
    householdId
      ? service
          .from("users")
          .select("email, full_name")
          .eq("household_id", householdId)
          .limit(8)
      : Promise.resolve({ data: [] as Record<string, unknown>[] }),
  ]);

  const propertyName = compactString(property?.name);
  const propertyAddress = [property?.street, property?.city, property?.state, property?.zip_code]
    .map((value) => compactString(value))
    .filter(Boolean)
    .join(", ");

  const linkedRecipients = ((recipients ?? []) as Record<string, unknown>[])
    .map((row) => ({
      email: normalizedEmail(row.email),
      name: compactString(row.full_name),
    }))
    .filter((row) => row.email);

  const recipientName = compactString(quote.prospect_name)
    || listText(linkedRecipients.map((row) => firstName(row.name || row.email)).filter(Boolean))
    || propertyName
    || "Client";
  const recipientEmail = compactString(quote.prospect_email) || linkedRecipients[0]?.email || "";

  return {
    quote,
    workspace: {
      companyName: compactString(workspace?.company_name) || "Chez Field",
      primaryEmail: compactString(workspace?.primary_email),
      primaryPhone: compactString(workspace?.primary_phone),
      website: compactString(workspace?.website),
    },
    property: property
      ? {
          name: propertyName || "Home",
          address: propertyAddress,
        }
      : null,
    recipient: {
      kind: compactString(quote.recipient_kind) || (householdId ? "linked_home" : "prospect"),
      name: recipientName,
      email: recipientEmail,
      phone: compactString(quote.prospect_phone),
      address: compactString(quote.prospect_address),
    },
    messages: ((messages ?? []) as Record<string, unknown>[]).map((row) => ({
      id: compactString(row.id),
      senderRole: compactString(row.sender_role),
      senderName: compactString(row.sender_name),
      body: compactString(row.body),
      createdAt: row.created_at,
      deliveryChannel: compactString(row.delivery_channel),
      metadata: row.metadata ?? {},
    })),
  };
}

function serializePublicQuote(payload: Awaited<ReturnType<typeof publicQuotePayload>>) {
  if (!payload) return null;
  const quote = payload.quote as Record<string, unknown>;
  const lineItems = Array.isArray(quote.line_items) ? quote.line_items : [];
  return {
    id: compactString(quote.id),
    title: compactString(quote.title),
    status: compactString(quote.status),
    statusLabel: quoteStatusLabel(compactString(quote.status)),
    statusDescription: quoteStatusDescription(compactString(quote.status)),
    currency: compactString(quote.currency) || "USD",
    subtotal: numberValue(quote.subtotal),
    taxTotal: numberValue(quote.tax_total),
    total: numberValue(quote.total),
    lineItems,
    scopeNotes: compactString(quote.scope_notes),
    homeownerMessage: compactString(quote.homeowner_message),
    sentAt: quote.sent_at,
    viewedAt: quote.viewed_at,
    approvedAt: quote.approved_at,
    declinedAt: quote.declined_at,
    publicShareUrl: publicQuoteUrl(compactString(quote.public_share_token)),
    workspace: payload.workspace,
    property: payload.property,
    recipient: payload.recipient,
    messages: payload.messages,
  };
}

async function respondToPublicQuote(
  service: ServiceClient,
  body: Record<string, unknown>,
) {
  const quoteToken = compactString(body.quoteToken);
  const responseType = compactString(body.responseType);
  const rawMessage = compactString(body.body);
  if (!quoteToken || !responseType) {
    throw new Error("Quote token and response type are required");
  }

  const payload = await publicQuotePayload(service, quoteToken);
  if (!payload) throw new Error("Quote not found");

  const quote = payload.quote as Record<string, unknown>;
  const quoteId = compactString(quote.id);
  const now = isoNow();
  const senderRole = payload.recipient.kind === "linked_home" ? "homeowner" : "prospect";
  const senderName = compactString(body.senderName) || payload.recipient.name || "Client";
  const senderEmail = normalizedEmail(body.senderEmail) || payload.recipient.email || "";

  let nextStatus = compactString(quote.status);
  let messageBody = rawMessage;
  const metadata: Record<string, unknown> = {
    event: "quote_response",
    response_type: responseType,
  };

  if (responseType === "approved") {
    nextStatus = "approved";
    messageBody = messageBody || "Approved the quote.";
  } else if (responseType === "declined") {
    nextStatus = "declined";
    messageBody = messageBody || "Declined the quote.";
  } else if (responseType === "question") {
    if (!messageBody) throw new Error("Add a question or note before sending");
    if (nextStatus === "sent") nextStatus = "viewed";
    metadata.event = "quote_question";
  } else {
    throw new Error("Unsupported quote response");
  }

  const { data: updatedQuote, error: updateError } = await service
    .from("provider_quotes")
    .update({
      status: nextStatus,
      viewed_at: quote.viewed_at ?? now,
      approved_at: responseType === "approved" ? now : quote.approved_at ?? null,
      declined_at: responseType === "declined" ? now : quote.declined_at ?? null,
      updated_at: now,
    })
    .eq("id", quoteId)
    .select()
    .single();

  if (updateError || !updatedQuote) throw updateError ?? new Error("Failed to update quote");

  await addQuoteMessage(service, {
    workspaceId: compactString(updatedQuote.workspace_id),
    quoteId,
    requestId: compactString(updatedQuote.request_id) || null,
    householdId: compactString(updatedQuote.household_id) || null,
    senderRole: senderRole as "homeowner" | "prospect",
    senderName,
    senderEmail,
    deliveryChannel: "web",
    body: messageBody,
    metadata,
  });

  if (compactString(updatedQuote.request_id) && compactString(updatedQuote.household_id)) {
    await service
      .from("handyman_requests")
      .update({ updated_at: now })
      .eq("id", compactString(updatedQuote.request_id));

    await mirrorQuoteMessageToRequestThread(service, {
      requestId: compactString(updatedQuote.request_id),
      householdId: compactString(updatedQuote.household_id),
      senderRole: "homeowner",
      body: messageBody,
      metadata: {
        ...metadata,
        quote_id: quoteId,
      },
    });
  }

  const providerDelivery = await sendProviderQuoteResponseEmail(service, {
    workspaceId: compactString(updatedQuote.workspace_id),
    quoteTitle: compactString(updatedQuote.title),
    quoteStatus: nextStatus,
    clientName: senderName,
    body: messageBody,
    publicShareToken: compactString(updatedQuote.public_share_token),
  }).catch((deliveryError) => ({
    sent: false,
    channel: "email",
    recipientCount: 0,
    error: deliveryError instanceof Error ? deliveryError.message : String(deliveryError),
  }));

  return {
    quote: serializePublicQuote(await publicQuotePayload(service, quoteToken)),
    delivery: providerDelivery,
  };
}

async function sendQuoteEmail(
  service: ServiceClient,
  params: {
    quote: Record<string, unknown>;
    workspaceId: string;
    lineItems: Array<Record<string, unknown>>;
    propertyName: string;
    propertyAddress: string;
    title: string;
    homeownerMessage: string;
    scopeNotes: string;
    total: number;
  },
) {
  const { workspace } = await providerNotificationRecipients(service, params.workspaceId);
  const linkedRecipients = compactString(params.quote.household_id)
    ? await householdRecipients(service, compactString(params.quote.household_id))
    : [];
  const recipientKind = compactString(params.quote.recipient_kind);
  const prospectRecipients = compactString(params.quote.prospect_email)
    ? [{ email: normalizedEmail(params.quote.prospect_email), name: compactString(params.quote.prospect_name) }]
    : [];
  const to = recipientKind === "linked_home" ? linkedRecipients : uniqueByEmail(prospectRecipients);

  if (!to.length) {
    throw new Error(recipientKind === "linked_home"
      ? "No homeowner email is available for this Chez home yet"
      : "A prospect email is required to send this quote");
  }

  const recipientName = recipientKind === "linked_home"
    ? listText(to.map((row) => firstName(row.name || row.email)).filter(Boolean)) || "there"
    : firstName(prospectRecipients[0]?.name || prospectRecipients[0]?.email) || "there";
  const shareUrl = publicQuoteUrl(compactString(params.quote.public_share_token));
  const note = compactString(params.homeownerMessage);
  const scopeNotes = compactString(params.scopeNotes);
  const preview = quotePreviewText(params.title, params.total, workspace.companyName);
  const intro = recipientKind === "linked_home"
    ? `${workspace.companyName} priced the requested work${params.propertyName ? ` for ${params.propertyName}` : ""}. You can review the line items, approve it, ask a question, or decline it from the secure Chez quote page.`
    : `${workspace.companyName} put together your quote. You can review the line items and respond from the secure Chez quote page.`;

  const bodyHtml = `
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="display:grid;gap:16px;">
      <tr><td style="padding:18px;border-radius:18px;background:#fff;border:1px solid rgba(42,34,82,0.09);">
        <div style="font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:12px;letter-spacing:0.12em;text-transform:uppercase;color:rgba(42,34,82,0.68);">Quote</div>
        <div style="margin-top:10px;font-size:28px;font-weight:700;color:#2a2252;">${moneyLabel(params.total)}</div>
        <div style="margin-top:8px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:14px;color:rgba(42,34,82,0.74);">${escapeHtml(params.title)}${params.propertyName ? ` · ${escapeHtml(params.propertyName)}` : ""}</div>
        ${params.propertyAddress ? `<div style="margin-top:6px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:13px;color:rgba(42,34,82,0.62);">${escapeHtml(params.propertyAddress)}</div>` : ""}
      </td></tr>
      <tr><td>${quoteLineItemsHtml(params.lineItems)}</td></tr>
      ${note ? `<tr><td style="padding:18px;border-radius:18px;background:rgba(239,111,93,0.08);border:1px solid rgba(239,111,93,0.16);font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:14px;line-height:1.6;color:#2a2252;"><strong style="display:block;margin-bottom:6px;">Note from ${escapeHtml(workspace.companyName)}</strong>${escapeHtml(note)}</td></tr>` : ""}
      ${scopeNotes ? `<tr><td style="padding:18px;border-radius:18px;background:rgba(42,34,82,0.04);border:1px solid rgba(42,34,82,0.09);font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:14px;line-height:1.6;color:#2a2252;"><strong style="display:block;margin-bottom:6px;">Scope notes</strong>${escapeHtml(scopeNotes)}</td></tr>` : ""}
    </table>
  `;
  const text = [
    `Hi ${recipientName},`,
    "",
    intro,
    "",
    `${params.title}: ${moneyLabel(params.total)}`,
    params.propertyName ? params.propertyName : "",
    params.propertyAddress ? params.propertyAddress : "",
    "",
    quoteLineItemsText(params.lineItems),
    note ? `\nNote from ${workspace.companyName}: ${note}` : "",
    scopeNotes ? `\nScope notes: ${scopeNotes}` : "",
    "",
    `Review the quote: ${shareUrl}`,
    "",
    workspace.primaryEmail ? `Questions: ${workspace.primaryEmail}` : "",
    workspace.primaryPhone ? `Phone: ${workspace.primaryPhone}` : "",
  ].filter(Boolean).join("\n");

  const delivery = await sendEmail({
    to,
    subject: recipientKind === "linked_home"
      ? `${workspace.companyName} sent your Chez quote${params.propertyName ? ` for ${params.propertyName}` : ""}`
      : `${workspace.companyName} sent your quote`,
    html: emailShell({
      preview,
      heading: "Your quote is ready",
      greeting: `Hi ${recipientName},`,
      intro,
      bodyHtml,
      ctaLabel: "Review quote",
      ctaUrl: shareUrl,
      footer: workspace.primaryEmail || workspace.primaryPhone
        ? `Questions? Reach ${workspace.companyName}${workspace.primaryEmail ? ` at ${workspace.primaryEmail}` : ""}${workspace.primaryPhone ? `${workspace.primaryEmail ? " or " : " at "}${workspace.primaryPhone}` : ""}.`
        : undefined,
    }),
    text,
    replyToEmail: workspace.primaryEmail || null,
    replyToName: workspace.companyName,
    categories: ["handyman_quote"],
  });

  return {
    ...delivery,
    workspace,
    recipientCount: to.length,
    shareUrl,
  };
}

async function sendRequestMessageEmail(
  service: ServiceClient,
  params: {
    workspaceId: string;
    householdId: string;
    propertyName: string;
    propertyAddress: string;
    requestTitle: string;
    requestStatusLabel: string;
    messageBody: string;
    quoteUrl?: string | null;
  },
) {
  const recipients = await householdRecipients(service, params.householdId);
  if (!recipients.length) {
    throw new Error("No homeowner email is available for this Chez home yet");
  }
  const { workspace } = await providerNotificationRecipients(service, params.workspaceId);
  const recipientName = listText(recipients.map((row) => firstName(row.name || row.email)).filter(Boolean)) || "there";
  const intro = `${workspace.companyName} sent an update${params.propertyName ? ` for ${params.propertyName}` : ""}.`;
  const bodyHtml = `
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="display:grid;gap:16px;">
      <tr><td style="padding:18px;border-radius:18px;background:#fff;border:1px solid rgba(42,34,82,0.09);">
        <div style="font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:12px;letter-spacing:0.12em;text-transform:uppercase;color:rgba(42,34,82,0.68);">Home update</div>
        <div style="margin-top:10px;font-size:24px;font-weight:700;color:#2a2252;">${escapeHtml(params.requestTitle)}</div>
        <div style="margin-top:8px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:14px;color:rgba(42,34,82,0.74);">${escapeHtml(params.requestStatusLabel)}${params.propertyName ? ` · ${escapeHtml(params.propertyName)}` : ""}</div>
        ${params.propertyAddress ? `<div style="margin-top:6px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:13px;color:rgba(42,34,82,0.62);">${escapeHtml(params.propertyAddress)}</div>` : ""}
      </td></tr>
      <tr><td style="padding:18px;border-radius:18px;background:rgba(42,34,82,0.04);border:1px solid rgba(42,34,82,0.09);font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:15px;line-height:1.7;color:#2a2252;">${escapeHtml(params.messageBody)}</td></tr>
    </table>
  `;
  const text = [
    `Hi ${recipientName},`,
    "",
    intro,
    "",
    params.requestTitle,
    params.requestStatusLabel,
    params.propertyName ? params.propertyName : "",
    params.propertyAddress ? params.propertyAddress : "",
    "",
    params.messageBody,
    "",
    params.quoteUrl ? `Review the latest quote: ${params.quoteUrl}` : "Open Chez to reply or coordinate the next step.",
    "",
    workspace.primaryEmail ? `Questions: ${workspace.primaryEmail}` : "",
    workspace.primaryPhone ? `Phone: ${workspace.primaryPhone}` : "",
  ].filter(Boolean).join("\n");

  return await sendEmail({
    to: recipients,
    subject: `${workspace.companyName} sent an update${params.propertyName ? ` for ${params.propertyName}` : ""}`,
    html: emailShell({
      preview: `${workspace.companyName} sent an update about ${params.requestTitle}.`,
      heading: "There’s a new home update",
      greeting: `Hi ${recipientName},`,
      intro,
      bodyHtml,
      ctaLabel: params.quoteUrl ? "Review latest quote" : undefined,
      ctaUrl: params.quoteUrl || undefined,
      footer: "Open Chez to reply or coordinate next steps with your contractor.",
    }),
    text,
    replyToEmail: workspace.primaryEmail || null,
    replyToName: workspace.companyName,
    categories: ["handyman_message"],
  });
}

async function sendProviderQuoteResponseEmail(
  service: ServiceClient,
  params: {
    workspaceId: string;
    quoteTitle: string;
    quoteStatus: string;
    clientName: string;
    body: string;
    publicShareToken: string;
  },
) {
  const { recipients, workspace } = await providerNotificationRecipients(service, params.workspaceId);
  if (!recipients.length) return { sent: false, channel: "email", recipientCount: 0, recipients: [] as string[] };
  const shareUrl = publicQuoteUrl(params.publicShareToken);
  const intro = `${params.clientName} ${params.quoteStatus === "approved" ? "approved" : params.quoteStatus === "declined" ? "declined" : "responded to"} ${params.quoteTitle}.`;
  const html = emailShell({
    preview: `${params.clientName} responded to ${params.quoteTitle}.`,
    heading: "Quote response received",
    greeting: `Hi ${firstName(workspace.companyName) || "team"},`,
    intro,
    bodyHtml: `<div style="padding:18px;border-radius:18px;background:#fff;border:1px solid rgba(42,34,82,0.09);font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:15px;line-height:1.7;color:#2a2252;"><strong style="display:block;margin-bottom:8px;">${escapeHtml(capitalize(params.quoteStatus) || "Response")}</strong>${escapeHtml(params.body)}</div>`,
    ctaLabel: "Open quote",
    ctaUrl: shareUrl,
  });
  const text = [
    intro,
    "",
    params.body,
    "",
    `Open quote: ${shareUrl}`,
  ].join("\n");

  return await sendEmail({
    to: recipients,
    subject: `${params.clientName} responded to ${params.quoteTitle}`,
    html,
    text,
    replyToEmail: workspace.primaryEmail || null,
    replyToName: workspace.companyName,
    categories: ["handyman_quote_response"],
  });
}

async function ensureWorkspaceForUser(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const userId = compactString(user.id);
  if (!userId) throw new Error("Missing user id");

  const existing = await getWorkspaceMembership(service, userId, normalizedEmail(user.email));
  const fullName =
    compactString(body.fullName) ||
    compactString((user.user_metadata as Record<string, unknown> | undefined)?.full_name) ||
    compactString((user.user_metadata as Record<string, unknown> | undefined)?.name) ||
    compactString(user.email);
  const email = normalizedEmail(user.email);
  const teamInviteToken = compactString(body.teamInviteToken);
  const companyName =
    compactString(body.companyName) ||
    compactString((existing?.provider_workspaces as Record<string, unknown> | undefined)?.company_name) ||
    compactString(body.company_name) ||
    "Chez Field";
  const primaryPhone = compactString(body.phone);
  const website = compactString(body.website);
  const title = compactString(body.title);
  const now = isoNow();

  if (existing) {
    const workspace = existing.provider_workspaces as Record<string, unknown>;
    await service
      .from("provider_workspaces")
      .update({
        company_name: companyName || workspace.company_name || "Chez Field",
        primary_email: email || workspace.primary_email || null,
        primary_phone: primaryPhone || workspace.primary_phone || null,
        website: website || workspace.website || null,
        updated_at: now,
      })
      .eq("id", workspace.id);

    await service
      .from("provider_workspace_members")
      .update({
        full_name: fullName || existing.full_name || null,
        email: email || existing.email || null,
        phone: primaryPhone || existing.phone || null,
        title: title || existing.title || roleLabel(compactString(existing.role)),
        last_seen_at: now,
        updated_at: now,
      })
      .eq("id", existing.id);

    return compactString(workspace.id);
  }

  if (teamInviteToken) {
    const { data: invitedMember, error: invitedMemberError } = await service
      .from("provider_workspace_members")
      .select("id, workspace_id, role, full_name, email, phone, title, provider_workspaces(*)")
      .eq("invite_token", teamInviteToken)
      .eq("status", "invited")
      .limit(1)
      .maybeSingle();

    if (invitedMemberError) throw invitedMemberError;
    if (invitedMember) {
      const workspace = (invitedMember.provider_workspaces as Record<string, unknown> | undefined) ?? {};
      await service
        .from("provider_workspace_members")
        .update({
          user_id: userId,
          full_name: fullName || invitedMember.full_name || null,
          email: email || invitedMember.email || null,
          phone: primaryPhone || invitedMember.phone || null,
          title: title || invitedMember.title || roleLabel(compactString(invitedMember.role)),
          status: "active",
          invite_token: null,
          last_seen_at: now,
          updated_at: now,
        })
        .eq("id", invitedMember.id);

      await service
        .from("provider_workspaces")
        .update({
          primary_email: compactString(workspace.primary_email) || email || null,
          primary_phone: compactString(workspace.primary_phone) || primaryPhone || null,
          updated_at: now,
        })
        .eq("id", invitedMember.workspace_id);

      return compactString(invitedMember.workspace_id);
    }
  }

  const { data: workspace, error: workspaceError } = await service
    .from("provider_workspaces")
    .insert({
      company_name: companyName,
      primary_email: email || null,
      primary_phone: primaryPhone || null,
      website: website || null,
      updated_at: now,
    })
    .select()
    .single();

  if (workspaceError || !workspace) throw workspaceError ?? new Error("Failed to create workspace");

  const { error: memberError } = await service.from("provider_workspace_members").insert({
    workspace_id: workspace.id,
    user_id: userId,
    full_name: fullName || null,
    email: email || null,
    phone: primaryPhone || null,
    title: title || "Owner",
    role: "owner",
    status: "active",
    last_seen_at: now,
    updated_at: now,
    // Phase 85 dispatch: brand-new workspace → signup user is the
    // default assignee. Sole-prop case is the common one; a second
    // teammate added later can be re-flipped via the Crew screen.
    is_default_assignee: true,
  });

  if (memberError) throw memberError;
  return compactString(workspace.id);
}

async function linkContractorToWorkspace(
  service: ServiceClient,
  workspaceId: string,
  contractorId: string,
  claimSource: string,
) {
  if (!workspaceId || !contractorId) return;
  const { data: existing } = await service
    .from("provider_contractor_links")
    .select("id")
    .eq("workspace_id", workspaceId)
    .eq("contractor_id", contractorId)
    .limit(1)
    .maybeSingle();

  if (existing) return;

  await service.from("provider_contractor_links").insert({
    workspace_id: workspaceId,
    contractor_id: contractorId,
    claim_source: claimSource,
  });
}

async function ensureHouseholdContractorForWorkspace(
  service: ServiceClient,
  params: {
    workspaceId: string;
    householdId: string;
    companyName: string;
    contactName: string;
    email: string;
    phone: string;
    website: string;
    claimSource: string;
  },
) {
  const householdId = compactString(params.householdId);
  const workspaceId = compactString(params.workspaceId);
  if (!householdId || !workspaceId) return null;

  const normalizedPhone = phoneDigits(params.phone);
  const normalizedProviderEmail = normalizedEmail(params.email);
  const normalizedCompanyName = compactString(params.companyName);

  const { data: householdContractors, error: contractorError } = await service
    .from("contractors")
    .select("id, company_name, email, phone")
    .eq("household_id", householdId);

  if (contractorError) throw contractorError;

  const existing = (householdContractors ?? []).find((contractor) => {
    const contractorEmail = normalizedEmail(contractor.email);
    const contractorPhone = phoneDigits(contractor.phone);
    const contractorName = compactString(contractor.company_name);
    return Boolean(
      (normalizedProviderEmail && contractorEmail === normalizedProviderEmail) ||
        (normalizedPhone && contractorPhone === normalizedPhone) ||
        (normalizedCompanyName && contractorName && contractorName.toLowerCase() === normalizedCompanyName.toLowerCase()),
    );
  });

  let contractorId = compactString(existing?.id);
  if (!contractorId) {
    const { data: created, error: createError } = await service
      .from("contractors")
      .insert({
        household_id: householdId,
        company_name: normalizedCompanyName || "Chez Field",
        contact_name: compactString(params.contactName) || null,
        email: normalizedProviderEmail || null,
        phone: compactString(params.phone) || "",
        specialties: ["Handyman"],
        category: "Handyman",
        website: compactString(params.website) || null,
        source: "manual",
      })
      .select("id")
      .single();

    if (createError) throw createError;
    contractorId = compactString(created?.id);
  }

  if (contractorId) {
    await linkContractorToWorkspace(service, workspaceId, contractorId, params.claimSource);
  }

  return contractorId || null;
}

async function createSignedDocumentUrl(service: ServiceClient, path: string) {
  const cleanPath = compactString(path);
  if (!cleanPath) return null;
  const { data, error } = await service.storage.from("documents").createSignedUrl(cleanPath, 60 * 60);
  if (error) {
    console.warn("[handyman-provider] failed to sign document", cleanPath, error.message);
    return null;
  }
  return compactString(data?.signedUrl);
}

async function createSignedSystemPhotoUrl(service: ServiceClient, path: string) {
  const cleanPath = compactString(path);
  if (!cleanPath) return null;
  const { data, error } = await service.storage
    .from("home-system-photos")
    .createSignedUrl(cleanPath, 60 * 60);
  if (error) {
    console.warn("[handyman-provider] failed to sign system photo", cleanPath, error.message);
    return null;
  }
  return compactString(data?.signedUrl);
}

/**
 * Wave M3 — sign a path that lives in home-system-attachments (voice
 * memos + future field-only attachments). One-hour TTL keeps things
 * fresh for cross-app playback without round-trips.
 */
async function signSystemAttachmentUrl(service: ServiceClient, path: string) {
  const cleanPath = compactString(path);
  if (!cleanPath) return null;
  const { data, error } = await service.storage
    .from("home-system-attachments")
    .createSignedUrl(cleanPath, 60 * 60);
  if (error) {
    console.warn("[handyman-provider] failed to sign system attachment", cleanPath, error.message);
    return null;
  }
  return compactString(data?.signedUrl);
}

/**
 * Decode a base64 string (with or without a data: URL prefix) into a
 * Uint8Array suitable for handing to supabase storage.upload.
 */
function decodeBase64Body(raw: string): Uint8Array {
  const cleaned = raw.includes(",") ? raw.split(",", 2)[1] : raw;
  const binary = atob(cleaned);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function safeFilenameSegment(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9.-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 64) || "photo";
}

async function autoLinkWorkspaceContractors(
  service: ServiceClient,
  workspaceId: string,
  email: string,
  phone: string,
) {
  if (!workspaceId) return;

  if (email) {
    const { data: matches } = await service
      .from("contractors")
      .select("id")
      .ilike("email", email);
    for (const match of matches ?? []) {
      await linkContractorToWorkspace(service, workspaceId, compactString(match.id), "email_match");
    }
  }

  if (phone) {
    const { data: contractors } = await service
      .from("contractors")
      .select("id, phone")
      .not("phone", "is", null);
    for (const contractor of contractors ?? []) {
      if (phoneDigits(contractor.phone) === phone) {
        await linkContractorToWorkspace(service, workspaceId, compactString(contractor.id), "phone_match");
      }
    }
  }
}

async function fetchInvitePreview(service: ServiceClient, token: string) {
  const { data: session, error } = await service
    .from("handyman_portal_sessions")
    .select("*")
    .eq("portal_token", token)
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  if (!session) return null;

  const propertyId = compactString(session.property_id);
  const contractorId = compactString(session.contractor_id);
  const visitTaskId = compactString(session.visit_task_id);

  const [{ data: property }, { data: contractor }, { data: request }] = await Promise.all([
    propertyId
      ? service
          .from("properties")
          .select("id, name, street, city, state, zip_code")
          .eq("id", propertyId)
          .limit(1)
          .maybeSingle()
      : Promise.resolve({ data: null }),
    contractorId
      ? service
          .from("contractors")
          .select("id, company_name, contact_name, email, phone")
          .eq("id", contractorId)
          .limit(1)
          .maybeSingle()
      : Promise.resolve({ data: null }),
    visitTaskId
      ? service
          .from("handyman_requests")
          .select("id, title, preferred_timing, status, request_type, household_id")
          .eq("visit_task_id", visitTaskId)
          .order("updated_at", { ascending: false })
          .limit(1)
          .maybeSingle()
      : Promise.resolve({ data: null }),
  ]);

  return {
    token,
    providerUrl: providerInviteUrl(token),
    fieldUrl: fieldVisitUrl(token, visitTaskId || null),
    title: compactString(request?.title) || compactString(session.title) || "Chez Contractor Visit",
    preferredTiming: compactString(request?.preferred_timing) || compactString((session.seed_payload as Record<string, unknown> | undefined)?.scheduledDate),
    requestStatus: compactString(request?.status) || null,
    requestStatusLabel: request ? requestStatusLabel(compactString(request.status)) : null,
    householdId: compactString(request?.household_id),
    property: property
      ? {
          id: property.id,
          name: compactString(property.name),
          address: [property.street, property.city, property.state, property.zip_code].filter(Boolean).join(", "),
        }
      : null,
    contractor: contractor
      ? {
          id: contractor.id,
          companyName: compactString(contractor.company_name),
          contactName: compactString(contractor.contact_name),
          email: compactString(contractor.email),
          phone: compactString(contractor.phone),
        }
      : null,
  };
}

async function claimInviteForWorkspace(
  service: ServiceClient,
  workspaceId: string,
  inviteToken: string,
  providerProfile?: {
    companyName?: string;
    contactName?: string;
    email?: string;
    phone?: string;
    website?: string;
  },
) {
  const preview = await fetchInvitePreview(service, inviteToken);
  if (!preview) return null;

  const contractorId = compactString((preview.contractor as Record<string, unknown> | null)?.id);
  if (contractorId) {
    await linkContractorToWorkspace(service, workspaceId, contractorId, "invite");
  } else {
    const householdId = compactString(preview.householdId);
    if (householdId) {
      await ensureHouseholdContractorForWorkspace(service, {
        workspaceId,
        householdId,
        companyName: compactString(providerProfile?.companyName) || compactString((preview.contractor as Record<string, unknown> | null)?.companyName) || "Chez Field",
        contactName: compactString(providerProfile?.contactName),
        email: normalizedEmail(providerProfile?.email),
        phone: compactString(providerProfile?.phone),
        website: compactString(providerProfile?.website),
        claimSource: "invite_household_seed",
      });
    }
  }

  return preview;
}

async function loadDashboard(
  service: ServiceClient,
  user: Record<string, unknown>,
  preferredWorkspaceId?: string,
) {
  const userId = compactString(user.id);
  const userEmail = normalizedEmail(user.email);
  const membership = await getWorkspaceMembership(
    service,
    userId,
    userEmail,
    preferredWorkspaceId,
  );
  if (!membership) {
    console.log("[handyman-provider] needsWorkspace=true", {
      userId,
      email: userEmail,
    });
    return {
      needsWorkspace: true,
      currentUser: {
        id: user.id,
        email: normalizedEmail(user.email),
        fullName:
          compactString((user.user_metadata as Record<string, unknown> | undefined)?.full_name) ||
          compactString((user.user_metadata as Record<string, unknown> | undefined)?.name),
      },
    };
  }

  const workspace = (membership.provider_workspaces as Record<string, unknown> | undefined) ?? {};
  const workspaceId = compactString(workspace.id);
  const currentRole = compactString(membership.role);
  const permissions = rolePermissions(currentRole);

  await service
    .from("provider_workspace_members")
    .update({ last_seen_at: isoNow(), updated_at: isoNow() })
    .eq("id", membership.id);

  const { data: contractorLinks, error: contractorLinkError } = await service
    .from("provider_contractor_links")
    .select("contractor_id, contractors(id, company_name, contact_name, email, phone, specialties, category)")
    .eq("workspace_id", workspaceId);

  if (contractorLinkError) throw contractorLinkError;
  const contractorIds = (contractorLinks ?? [])
    .map((row: Record<string, unknown>) => compactString(row.contractor_id))
    .filter(Boolean);

  // Sprint #4 R4-E-2 fix: localDateString() uses UTC, so "today" rolls
  // over to tomorrow at 8 PM EDT (00:00 UTC). The workspace dashboard
  // hero + the per-tech "stops today" pill both use this string to
  // filter route_date == today. We mirror todaySummaryForProvider's tz
  // resolution: prefer the workspace's first-linked household's
  // primary property time_zone, fall back to America/New_York.
  let dashboardTimeZone = FIELD_DEFAULT_TIMEZONE;
  try {
    const firstContractorId = contractorIds[0];
    if (firstContractorId) {
      const { data: contractor } = await service
        .from("contractors")
        .select("household_id")
        .eq("id", firstContractorId)
        .maybeSingle();
      const householdId = compactString(contractor?.household_id);
      if (householdId) {
        const { data: prop } = await service
          .from("properties")
          .select("time_zone")
          .eq("household_id", householdId)
          .order("created_at", { ascending: true })
          .limit(1)
          .maybeSingle();
        const propTz = compactString(prop?.time_zone);
        if (propTz) dashboardTimeZone = propTz;
      }
    }
  } catch (err) {
    console.error("[handyman-provider] dashboard tz lookup failed", err);
  }
  const today = fieldFormatYmdInZone(new Date(), dashboardTimeZone);

  const [
    teamMembersResult,
    assignmentsResult,
    requestsResult,
    sessionsResult,
    quotesResult,
    savedItemsResult,
    invoicesResult,
    // Wave S — list every workspace this user is an active member of so
    // the SPA can render a switcher dropdown. Single round-trip alongside
    // the existing parallel batch so adding the switcher costs ~0ms.
    availableWorkspacesResult,
  ] = await Promise.all([
    service
      .from("provider_workspace_members")
      .select("id, workspace_id, user_id, full_name, email, phone, title, role, status, invite_token, last_seen_at, created_at, updated_at, is_default_assignee")
      .eq("workspace_id", workspaceId)
      .order("status", { ascending: true })
      .order("created_at", { ascending: true }),
    service
      .from("provider_visit_assignments")
      .select("*")
      .eq("workspace_id", workspaceId)
      .order("route_date", { ascending: true })
      .order("stop_order", { ascending: true }),
    // Bugfix Sprint #5 R7-E-1 — bumped cap from 120 → 500. The
    // previous 120 cap silently truncated active workspaces (a 5-tech
    // crew running 5 visits/day hits 120 in <1 week of backlog). 500
    // covers ~3 months of active-workspace volume; real pagination +
    // total_count is deferred to a future wave. Tiebreak by id so
    // updated_at ties don't drop rows non-deterministically.
    contractorIds.length
      ? service
          .from("handyman_requests")
          .select("*")
          .in("contractor_id", contractorIds)
          .order("updated_at", { ascending: false })
          .order("id", { ascending: true })
          .limit(500)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    contractorIds.length
      ? service
          .from("handyman_portal_sessions")
          .select("*")
          .in("contractor_id", contractorIds)
          .order("updated_at", { ascending: false })
          .order("id", { ascending: true })
          .limit(500)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    service
      .from("provider_quotes")
      .select("*")
      .eq("workspace_id", workspaceId)
      .order("updated_at", { ascending: false })
      .order("id", { ascending: true })
      .limit(500),
    service
      .from("provider_saved_quote_items")
      .select("*")
      .eq("workspace_id", workspaceId)
      .order("sort_order", { ascending: true })
      .order("created_at", { ascending: false }),
    // Wave Q (Section 8) — provider invoices.
    service
      .from("provider_invoices")
      .select("*")
      .eq("workspace_id", workspaceId)
      .order("updated_at", { ascending: false })
      .order("id", { ascending: true })
      .limit(500),
    // Wave S — fetch every workspace this user can switch into. Filtered
    // to active memberships only so revoked/invited rows never leak. The
    // joined `provider_workspaces` row gives us company_name + primary_email.
    service
      .from("provider_workspace_members")
      .select("workspace_id, role, status, provider_workspaces(id, company_name, primary_email)")
      .eq("user_id", userId)
      .eq("status", "active"),
  ]);

  if (teamMembersResult.error) throw teamMembersResult.error;
  if (assignmentsResult.error) throw assignmentsResult.error;
  if (requestsResult.error) throw requestsResult.error;
  if (sessionsResult.error) throw sessionsResult.error;
  if (quotesResult.error) throw quotesResult.error;
  if (savedItemsResult.error) throw savedItemsResult.error;
  if (invoicesResult.error) throw invoicesResult.error;
  if (availableWorkspacesResult.error) throw availableWorkspacesResult.error;

  // Wave S — distill the membership rows into a clean { id, companyName,
  // primaryEmail, role, isCurrent } array. Multiple rows for the same
  // workspace_id (rare — would mean stale dup data) collapse to the
  // first hit. Sorted alphabetically by company name to match common
  // workspace-switcher UX (Slack, Linear, Notion).
  const availableWorkspaceMap = new Map<string, Record<string, unknown>>();
  for (const row of (availableWorkspacesResult.data ?? []) as Record<string, unknown>[]) {
    const ws = (row.provider_workspaces as Record<string, unknown> | undefined) ?? {};
    const id = compactString(ws.id) || compactString(row.workspace_id);
    if (!id || availableWorkspaceMap.has(id)) continue;
    availableWorkspaceMap.set(id, {
      id,
      companyName: compactString(ws.company_name) || "Workspace",
      primaryEmail: compactString(ws.primary_email),
      role: compactString(row.role),
      isCurrent: id === workspaceId,
    });
  }
  const availableWorkspaces = Array.from(availableWorkspaceMap.values()).sort((a, b) =>
    String(a.companyName).localeCompare(String(b.companyName)),
  );

  let teamMembers = (teamMembersResult.data ?? []) as Record<string, unknown>[];
  let assignments = (assignmentsResult.data ?? []) as Record<string, unknown>[];
  const requests = (requestsResult.data ?? []) as Record<string, unknown>[];
  let sessions = (sessionsResult.data ?? []) as Record<string, unknown>[];
  let quotes = (quotesResult.data ?? []) as Record<string, unknown>[];
  const savedItems = (savedItemsResult.data ?? []) as Record<string, unknown>[];
  let invoices = (invoicesResult.data ?? []) as Record<string, unknown>[];
  const myMemberId = compactString(membership.id);

  let visibleRequests = requests;
  if (permissions.isFieldTechnician) {
    const allowedRequestIds = new Set(
      assignments
        .filter((row) => compactString(row.assigned_member_id) === myMemberId)
        .map((row) => compactString(row.request_id))
        .filter(Boolean),
    );
    assignments = assignments.filter((row) => compactString(row.assigned_member_id) === myMemberId);
    visibleRequests = requests.filter((row) => allowedRequestIds.has(compactString(row.id)));
    const allowedVisitIds = new Set(
      visibleRequests.map((row) => compactString(row.visit_task_id)).filter(Boolean),
    );
    sessions = sessions.filter((row) => allowedVisitIds.has(compactString(row.visit_task_id)));
    quotes = quotes.filter((row) => {
      const requestId = compactString(row.request_id);
      return requestId ? allowedRequestIds.has(requestId) : compactString(row.created_by_user_id) === userId;
    });
    invoices = invoices.filter((row) => {
      const requestId = compactString(row.request_id);
      return requestId ? allowedRequestIds.has(requestId) : compactString(row.created_by_user_id) === userId;
    });
    teamMembers = teamMembers.filter((row) => compactString(row.id) === myMemberId);
  }

  const requestIds = visibleRequests.map((row) => compactString(row.id)).filter(Boolean);
  const visitIds = [
    ...new Set(
      [...visibleRequests.map((row) => compactString(row.visit_task_id)), ...sessions.map((row) => compactString(row.visit_task_id))]
        .filter(Boolean),
    ),
  ];
  const propertyIds = [
    ...new Set(
      [
        ...visibleRequests.map((row) => compactString(row.property_id)),
        ...sessions.map((row) => compactString(row.property_id)),
        ...quotes.map((row) => compactString(row.property_id)),
        ...invoices.map((row) => compactString(row.property_id)),
      ].filter(Boolean),
    ),
  ];

  // Section 19d: pull chez_profile for every household in scope so the
  // contractor sees standing instructions (esp. spending tiers — the
  // contractor needs to know whether to ping Chez before a $500+
  // proposal). Phase 80.1 added the JSONB column; this SPA was the
  // last consumer to wire it in.
  const householdIds = [
    ...new Set(
      [...visibleRequests.map((row) => compactString(row.household_id)), ...quotes.map((row) => compactString(row.household_id))]
        .filter(Boolean),
    ),
  ];
  const { data: householdsForProfile } = householdIds.length
    ? await service
        .from("households")
        .select("id, chez_profile")
        .in("id", householdIds)
    : { data: [] as Record<string, unknown>[] };
  const chezProfileByHouseholdId = new Map<string, Record<string, unknown> | null>();
  for (const row of householdsForProfile ?? []) {
    chezProfileByHouseholdId.set(compactString(row.id), (row.chez_profile as Record<string, unknown>) ?? null);
  }

  // T3.1 + T3.2 (post-overnight) — per-home routines + vendors so the
  // home detail surface can render Routines + Vendors sub-tabs. Pull
  // ALL routines and contractors for the in-scope households in one
  // batch each, then index by household_id for the per-home loop below.
  // Soft-deleted rows excluded. Limit: 50 routines + 50 contractors per
  // home is plenty (HNW estates that exceed this can scroll).
  const { data: routinesForHomes } = householdIds.length
    ? await service
        .from("routines")
        .select("id, household_id, label, routine_kind, cadence_type, days_of_week, time_of_day, active_months, vendor_id, cost_cents, setup_state, paused_at, archived_at, chez_owned")
        .in("household_id", householdIds)
        .is("archived_at", null)
        .order("created_at", { ascending: false })
    : { data: [] as Record<string, unknown>[] };
  const routinesByHouseholdId = new Map<string, Record<string, unknown>[]>();
  for (const row of routinesForHomes ?? []) {
    const householdId = compactString(row.household_id);
    if (!householdId) continue;
    const list = routinesByHouseholdId.get(householdId) ?? [];
    list.push(row);
    routinesByHouseholdId.set(householdId, list);
  }
  const { data: contractorsForHomes } = householdIds.length
    ? await service
        .from("contractors")
        .select("id, household_id, company_name, contact_name, phone, email, website, category, source, logo_url, brand_color, chez_owned")
        .in("household_id", householdIds)
        .order("created_at", { ascending: false })
    : { data: [] as Record<string, unknown>[] };
  const contractorsByHouseholdId = new Map<string, Record<string, unknown>[]>();
  for (const row of contractorsForHomes ?? []) {
    const householdId = compactString(row.household_id);
    if (!householdId) continue;
    const list = contractorsByHouseholdId.get(householdId) ?? [];
    list.push(row);
    contractorsByHouseholdId.set(householdId, list);
  }

  // N-customer-phone fix: pull the primary family_member phone per
  // household so the visit detail header can render a tap-to-call
  // FieldTappablePhoneRow. We prefer the row whose relationship is
  // 'Primary Client' (the homeowner of record) and fall back to any
  // family_member with a phone on file. Soft-deleted rows are excluded.
  const { data: familyMembersForPhones } = householdIds.length
    ? await service
        .from("family_members")
        .select("household_id, relationship, phone, first_name, last_name, member_type, deleted_at")
        .in("household_id", householdIds)
        .is("deleted_at", null)
    : { data: [] as Record<string, unknown>[] };
  const customerPhoneByHouseholdId = new Map<string, string>();
  for (const row of familyMembersForPhones ?? []) {
    const householdId = compactString(row.household_id);
    const phone = compactString(row.phone);
    if (!householdId || !phone) continue;
    // Skip rows that are home managers / staff — we want the actual
    // homeowner's number, not a property manager (different phone tree).
    const memberType = (compactString(row.member_type) || "family").toLowerCase();
    if (memberType === "home_manager" || memberType === "staff") continue;
    const isPrimary = (compactString(row.relationship) || "").toLowerCase() === "primary client";
    if (isPrimary) {
      // Primary always wins; overwrite any prior fallback.
      customerPhoneByHouseholdId.set(householdId, phone);
      continue;
    }
    if (!customerPhoneByHouseholdId.has(householdId)) {
      customerPhoneByHouseholdId.set(householdId, phone);
    }
  }

  const quoteIds = quotes.map((row) => compactString(row.id)).filter(Boolean);

  const [messagesResult, reportsResult, propertiesResult, systemsResult, visitTasksResult, quoteMessagesResult, openTasksResult, documentsResult, punchItemsResult, techNotesResult] = await Promise.all([
    requestIds.length
      ? service
          .from("handyman_request_messages")
          .select("*")
          .in("request_id", requestIds)
          .order("created_at", { ascending: false })
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    sessions.length
      ? service
          .from("handyman_visit_reports")
          .select("*")
          .in("portal_session_id", sessions.map((row) => compactString(row.id)).filter(Boolean))
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    propertyIds.length
      ? service
          .from("properties")
          .select("id, name, street, city, state, zip_code, property_type")
          .in("id", propertyIds)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    propertyIds.length
      ? service
          .from("home_systems")
          .select("id, property_id, name, category, manufacturer, model_number, serial_number, notes, install_date, status, subtype, catalog_series, catalog_model_name, catalog_fuel_type, catalog_features, reliability_score, score_summary, last_service_date, next_service_due, total_spent, cached_manual_links, photos")
          .in("property_id", propertyIds)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    visitIds.length
      ? service
          .from("maintenance_tasks")
          .select("id, title, scheduled_date, next_due_date, notes, description")
          .in("id", visitIds)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    quoteIds.length
      ? service
          .from("provider_quote_messages")
          .select("*")
          .in("quote_id", quoteIds)
          .order("created_at", { ascending: false })
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    propertyIds.length
      ? service
          .from("maintenance_tasks")
          .select("id, property_id, title, next_due_date, priority, assignment_type, service_key, is_archived")
          .in("property_id", propertyIds)
          .order("next_due_date", { ascending: true })
          .limit(400)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    propertyIds.length
      ? service
          .from("documents")
          .select("id, property_id, title, category, notes, uploaded_at, file_path")
          .in("property_id", propertyIds)
          .is("deleted_at", null)
          .order("uploaded_at", { ascending: false })
          .limit(300)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    // Phase 78: structured punch list rows. Pulled by the visit_task_id
    // FK so each visit row can carry its own punchItems[] alongside the
    // legacy notes blob (which the backfill should have trimmed).
    visitIds.length
      ? service
          .from("handyman_punch_items")
          .select("id, household_id, property_id, assigned_visit_task_id, system_id, system_label_snapshot, template_id, title, description, source, status, priority, estimated_minutes, estimated_cost_range, material_required, cost_basis, attachments, materials_used, time_spent_seconds, voice_note_path, added_after_lock, proposed_by_user_id, proposed_by_role, proposed_at, proposal_message, proposal_status, proposal_expires_at, accepted_by_user_id, accepted_at, declined_by_user_id, declined_at, declined_reason, completed_at, completed_visit_task_id, archived_at, created_at, updated_at")
          .in("assigned_visit_task_id", visitIds)
          .is("archived_at", null)
          .order("created_at", { ascending: true })
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    // Wave M6 — tech notes count per request. Cheap aggregate so the
    // visit list rows can show a "3 internal notes" badge without
    // pulling the full bodies for every visit. List-style fetch lets us
    // count by request_id locally.
    requestIds.length
      ? service
          .from("provider_visit_tech_notes")
          .select("request_id")
          .eq("workspace_id", workspaceId)
          .in("request_id", requestIds)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
  ]);

  if (messagesResult.error) throw messagesResult.error;
  if (reportsResult.error) throw reportsResult.error;
  if (propertiesResult.error) throw propertiesResult.error;
  if (systemsResult.error) throw systemsResult.error;
  if (visitTasksResult.error) throw visitTasksResult.error;
  if (quoteMessagesResult.error) throw quoteMessagesResult.error;
  if (openTasksResult.error) throw openTasksResult.error;
  if (documentsResult.error) throw documentsResult.error;
  if (punchItemsResult.error) throw punchItemsResult.error;
  if (techNotesResult.error) throw techNotesResult.error;

  const messages = (messagesResult.data ?? []) as Record<string, unknown>[];
  const reports = (reportsResult.data ?? []) as Record<string, unknown>[];
  const properties = (propertiesResult.data ?? []) as Record<string, unknown>[];
  const systems = (systemsResult.data ?? []) as Record<string, unknown>[];
  const visitTasks = (visitTasksResult.data ?? []) as Record<string, unknown>[];
  const quoteMessages = (quoteMessagesResult.data ?? []) as Record<string, unknown>[];
  const openTasks = (openTasksResult.data ?? []) as Record<string, unknown>[];
  const propertyDocuments = (documentsResult.data ?? []) as Record<string, unknown>[];
  const punchItems = (punchItemsResult.data ?? []) as Record<string, unknown>[];
  // Wave M6 — count tech notes per request for the assignment badge.
  const techNoteRows = (techNotesResult.data ?? []) as Record<string, unknown>[];
  const techNotesCountByRequestId = new Map<string, number>();
  for (const row of techNoteRows) {
    const requestId = compactString(row.request_id);
    if (!requestId) continue;
    techNotesCountByRequestId.set(requestId, (techNotesCountByRequestId.get(requestId) ?? 0) + 1);
  }

  // Phase 78: bucket punch items by their assigned visit so each visit
  // row can carry its own punchItems[] without an N+1 query.
  const punchItemsByVisitTaskId = new Map<string, Record<string, unknown>[]>();
  for (const item of punchItems) {
    const key = compactString(item.assigned_visit_task_id);
    if (!key) continue;
    const existing = punchItemsByVisitTaskId.get(key);
    if (existing) {
      existing.push(item);
    } else {
      punchItemsByVisitTaskId.set(key, [item]);
    }
  }

  const propertyById = new Map(properties.map((row) => [compactString(row.id), row]));
  const reportBySessionId = new Map(reports.map((row) => [compactString(row.portal_session_id), row]));
  const visitById = new Map(visitTasks.map((row) => [compactString(row.id), row]));
  const memberById = new Map(teamMembers.map((row) => [compactString(row.id), row]));
  const assignmentByRequestId = new Map(assignments.map((row) => [compactString(row.request_id), row]));
  // Phase 73 sub-phase B: counter chains create multiple quotes per
  // request_id. `quotes` is ordered by updated_at DESC, so walking it
  // and skipping when we've already seen a request_id keeps the
  // freshest quote (typically a `countered_by_homeowner` row, then a
  // provider re-quote, etc.). The legacy `new Map(arr)` constructor
  // ended up keeping the oldest because duplicate keys are
  // last-write-wins.
  const quoteByRequestId = new Map<string, Record<string, unknown>>();
  for (const row of quotes) {
    const requestId = compactString(row.request_id);
    if (!requestId) continue;
    if (quoteByRequestId.has(requestId)) continue;
    quoteByRequestId.set(requestId, row);
  }

  const latestMessageByRequestId = new Map<string, Record<string, unknown>>();
  for (const message of messages) {
    const requestId = compactString(message.request_id);
    if (!requestId || latestMessageByRequestId.has(requestId)) continue;
    latestMessageByRequestId.set(requestId, message);
  }

  const messagesByRequestId = new Map<string, Record<string, unknown>[]>();
  for (const message of messages) {
    const requestId = compactString(message.request_id);
    if (!requestId) continue;
    const bucket = messagesByRequestId.get(requestId) ?? [];
    bucket.push(message);
    messagesByRequestId.set(requestId, bucket);
  }

  const systemsByPropertyId = new Map<string, Record<string, unknown>[]>();
  for (const system of systems) {
    const propertyId = compactString(system.property_id);
    if (!propertyId) continue;
    const bucket = systemsByPropertyId.get(propertyId) ?? [];
    bucket.push(system);
    systemsByPropertyId.set(propertyId, bucket);
  }

  const openTasksByPropertyId = new Map<string, Record<string, unknown>[]>();
  for (const task of openTasks) {
    if (task.is_archived === true) continue;
    const propertyId = compactString(task.property_id);
    if (!propertyId) continue;
    const bucket = openTasksByPropertyId.get(propertyId) ?? [];
    bucket.push(task);
    openTasksByPropertyId.set(propertyId, bucket);
  }

  const signedDocuments = await Promise.all(
    propertyDocuments.map(async (document) => ({
      ...document,
      signed_url: await createSignedDocumentUrl(service, compactString(document.file_path)),
    })),
  );

  const filesByPropertyId = new Map<string, Record<string, unknown>[]>();
  for (const document of signedDocuments) {
    const propertyId = compactString(document.property_id);
    if (!propertyId) continue;
    const bucket = filesByPropertyId.get(propertyId) ?? [];
    bucket.push(document);
    filesByPropertyId.set(propertyId, bucket);
  }

  const sessionByVisitId = new Map<string, Record<string, unknown>>();
  for (const session of sessions) {
    const visitId = compactString(session.visit_task_id);
    if (!visitId || sessionByVisitId.has(visitId)) continue;
    sessionByVisitId.set(visitId, session);
  }

  const latestQuoteMessageByQuoteId = new Map<string, Record<string, unknown>>();
  const quoteMessagesByQuoteId = new Map<string, Record<string, unknown>[]>();
  for (const message of quoteMessages) {
    const quoteId = compactString(message.quote_id);
    if (!quoteId) continue;
    if (!latestQuoteMessageByQuoteId.has(quoteId)) {
      latestQuoteMessageByQuoteId.set(quoteId, message);
    }
    const bucket = quoteMessagesByQuoteId.get(quoteId) ?? [];
    bucket.push(message);
    quoteMessagesByQuoteId.set(quoteId, bucket);
  }

  // Wave M2 — pre-sign punch-item attachment URLs so iOS / SPA can render
  // thumbnails inline without a per-image round-trip. Runs once per
  // dashboard load before the synchronous visit map below.
  // Pre-Phase-M2 rows have no attachments and skip the signing entirely.
  const signedAttachmentsByItemId = new Map<string, unknown[]>();
  const signedVoiceUrlByItemId = new Map<string, string | null>();
  const allPunchAttachmentSigning: Array<Promise<void>> = [];
  for (const items of punchItemsByVisitTaskId.values()) {
    for (const item of items) {
      const attachments = Array.isArray(item.attachments)
        ? (item.attachments as Record<string, unknown>[])
        : [];
      if (attachments.length > 0) {
        allPunchAttachmentSigning.push(
          (async () => {
            const signed = await Promise.all(
              attachments.map(async (att) => {
                const path = compactString(att.path);
                if (!path) return att;
                const signedUrl = await createSignedPunchAttachmentUrl(service, path);
                return { ...att, signedUrl };
              }),
            );
            signedAttachmentsByItemId.set(compactString(item.id), signed);
          })(),
        );
      }
      const voicePath = compactString(item.voice_note_path);
      if (voicePath) {
        allPunchAttachmentSigning.push(
          (async () => {
            const signedUrl = await createSignedPunchAttachmentUrl(service, voicePath);
            signedVoiceUrlByItemId.set(compactString(item.id), signedUrl);
          })(),
        );
      }
    }
  }
  await Promise.all(allPunchAttachmentSigning);

  const visitRows = visibleRequests.map((request) => {
    const requestId = compactString(request.id);
    const visitId = compactString(request.visit_task_id);
    const propertyId = compactString(request.property_id);
    const property = propertyById.get(propertyId) ?? null;
    const session = (visitId ? sessionByVisitId.get(visitId) : null) ?? null;
    const report = session ? reportBySessionId.get(compactString(session.id)) ?? null : null;
    const visit = visitId ? visitById.get(visitId) ?? null : null;
    const message = latestMessageByRequestId.get(requestId) ?? null;
    const quote = quoteByRequestId.get(requestId) ?? null;
    const assignment = assignmentByRequestId.get(requestId) ?? null;
    const assignedMember = assignment ? memberById.get(compactString(assignment.assigned_member_id)) ?? null : null;
    // Prefer the request's `confirmed_visit_at` over the assignment's
    // route_date — the homeowner's accept_visit_time always updates
    // confirmed_visit_at, but if there was no assignment at the time
    // of accept (or the RPC's assignment-sync was added after this
    // request) route_date can lag. confirmedVisitAt is the truth.
    const confirmedDate = compactString(request.confirmed_visit_at).slice(0, 10);
    const routeDate =
      confirmedDate ||
      compactString(assignment?.route_date) ||
      compactString(visit?.scheduled_date) ||
      compactString(visit?.next_due_date);

    return {
      requestId,
      householdId: compactString(request.household_id),
      propertyId,
      contractorId: compactString(request.contractor_id),
      title: compactString(request.title),
      requestType: compactString(request.request_type),
      status: compactString(request.status),
      statusLabel: requestStatusLabel(compactString(request.status)),
      preferredTiming: compactString(request.preferred_timing),
      // Section 19a — surface origin + urgency so the desktop can render
      // a "Routed by Chez" pill on requests created by the Chez admin
      // (source='haven') and an Emergency pill on urgency='urgent' rows.
      source: compactString(request.source) || null,
      urgency: compactString(request.urgency) || null,
      // Wave M8 — set when the visit was scheduled from the field tech's
      // end-of-visit wizard. Operations Desk renders a "Suggested by
      // visit" pill so the operator knows the row was tech-driven.
      suggestedByRequestId: compactString(request.suggested_by_request_id) || null,
      // Wave M9 — mid-stream cancellation context. Operations Desk's
      // VisitDetail renders "Cancelled mid-visit at HH:MM, reason: ..."
      // when status='cancelled' and these fields are populated.
      cancellationReason: compactString(request.cancellation_reason) || null,
      cancelledAt: request.cancelled_at ?? null,
      cancelledByMemberId: compactString(request.cancelled_by_member_id) || null,
      proposedVisitAt: request.proposed_visit_at ?? null,
      proposedByRole: compactString(request.proposed_by_role) || null,
      proposedAt: request.proposed_at ?? null,
      confirmedVisitAt: request.confirmed_visit_at ?? null,
      updatedAt: request.updated_at,
      routeDate,
      property: property
        ? {
            id: property.id,
            name: compactString(property.name),
            address: [property.street, property.city, property.state, property.zip_code].filter(Boolean).join(", "),
            // N-customer-phone fix: customer phone keyed off the
            // request's household so the iOS visit detail can render a
            // tap-to-call FieldTappablePhoneRow without a second
            // round-trip. Resolves from the family_members lookup
            // populated above (primary client first, any non-staff
            // family_member fallback).
            customerPhone: customerPhoneByHouseholdId.get(compactString(request.household_id)) || null,
          }
        : null,
      visit: visit
        ? {
            id: visit.id,
            title: compactString(visit.title),
            scheduledDate: compactString(visit.scheduled_date),
            dueDate: compactString(visit.next_due_date),
            // Phase 74b: surface task notes/description so the desktop
            // visit detail can parse the punch list ("What's included:")
            // out of the maintenance_task that backs this visit.
            notes: compactString(visit.notes),
            description: compactString(visit.description),
          }
        : null,
      fieldWorkspace: session
        ? {
            portalToken: compactString(session.portal_token),
            url: fieldVisitUrl(compactString(session.portal_token), visitId || null),
            reportStatus: report ? compactString(report.report_status) : "draft",
            completedAt: report?.completed_at ?? null,
          }
        : null,
      assignment: assignment
        ? {
            id: compactString(assignment.id),
            memberId: compactString(assignment.assigned_member_id),
            memberName:
              compactString(assignedMember?.full_name) ||
              compactString(assignedMember?.email) ||
              "Unassigned",
            memberRole: compactString(assignedMember?.role),
            memberRoleLabel: roleLabel(compactString(assignedMember?.role)),
            routeDate,
            windowStartTime: compactString(assignment.window_start_time),
            windowEndTime: compactString(assignment.window_end_time),
            stopOrder: numberValue(assignment.stop_order || 0),
            routeNotes: compactString(assignment.route_notes),
            // Wave M1 — visit lifecycle. Surface clock_in/clock_out + GPS +
            // pause accumulation so the Operations Desk can render the
            // "TIME ON-SITE" stat + verified-arrival pill on VisitDetail.
            clockInAt: assignment.clock_in_at ?? null,
            clockOutAt: assignment.clock_out_at ?? null,
            pausedSeconds: numberValue(assignment.paused_seconds || 0),
            clockInLat: assignment.clock_in_lat !== null && assignment.clock_in_lat !== undefined
              ? Number(assignment.clock_in_lat)
              : null,
            clockInLng: assignment.clock_in_lng !== null && assignment.clock_in_lng !== undefined
              ? Number(assignment.clock_in_lng)
              : null,
            clockInAccuracyM: assignment.clock_in_accuracy_m !== null && assignment.clock_in_accuracy_m !== undefined
              ? Number(assignment.clock_in_accuracy_m)
              : null,
            // Wave M6 — count of internal tech notes on this request.
            // Surfaces a "N notes" badge on visit list rows so a tech
            // walking up to a job knows there's prior context to read.
            techNotesCount: techNotesCountByRequestId.get(requestId) ?? 0,
            // Wave M9 — co-tech roster + access method/notes. iOS Field
            // and Operations Desk both read these to render co-tech
            // avatars + lockbox badges on the visit detail header.
            coTechMemberIds: Array.isArray(assignment.co_tech_member_ids)
              ? (assignment.co_tech_member_ids as unknown[]).map((v) => compactString(v)).filter(Boolean)
              : [],
            accessMethod: compactString(assignment.access_method) || null,
            accessNotes: compactString(assignment.access_notes) || null,
          }
        : null,
      latestMessage: message
        ? {
            senderRole: compactString(message.sender_role),
            body: compactString(message.body),
            createdAt: message.created_at,
          }
        : null,
      // Sprint #3 R3-E-3: per-visit quote envelope on visitRows is the
      // financial coordination payload (totals, signed-name, signature
      // path). Field technicians don't manage quote pricing or signature
      // workflows, so return null for them. Owners/dispatchers continue
      // to see the full envelope so the visit-detail card can show the
      // signed-quote summary alongside the sign-off block.
      quote: permissions.isFieldTechnician
        ? null
        : (quote
        ? {
            id: quote.id,
            status: compactString(quote.status),
            statusLabel: quoteStatusLabel(compactString(quote.status)),
            total: numberValue(quote.total),
            lineItems: (Array.isArray(quote.line_items) ? quote.line_items : []).map(mapLineItemForClient),
            scopeNotes: compactString(quote.scope_notes) || null,
            homeownerMessage: compactString(quote.homeowner_message) || null,
            parentQuoteId: compactString(quote.parent_quote_id) || null,
            signedAt: quote.signed_at ?? null,
            signedName: compactString(quote.signed_name) || null,
            // Wave M4 — kitchen-table signature artifact. Operations
            // Desk + iOS Field both decode this so the post-sign
            // confirmation strip + the homeowner inbox row both render
            // the captured PNG inline.
            signaturePath: compactString(quote.signature_path) || null,
            signerRole: compactString(quote.signer_role) || null,
            homeownerRevisedAt: quote.homeowner_revised_at ?? null,
            updatedAt: quote.updated_at,
            publicShareUrl: publicQuoteUrl(compactString(quote.public_share_token)),
          }
        : null),
      // Phase 78: structured punch list. Replaces the legacy notes-bullet
      // text the field app used to regex-parse. Items already filtered to
      // archived_at IS NULL on the server side.
      // Wave M2 — fold pre-signed attachment + voice URLs into the
      // payload so the field UI renders thumbnails + audio playback
      // without a per-asset round-trip.
      punchItems: (punchItemsByVisitTaskId.get(visitId) ?? []).map((item) => {
        const mapped = mapPunchItemForClient(item) as Record<string, unknown>;
        const itemId = compactString(item.id);
        const signedAttachments = signedAttachmentsByItemId.get(itemId);
        if (signedAttachments) {
          mapped.attachments = signedAttachments;
        }
        const signedVoiceUrl = signedVoiceUrlByItemId.get(itemId);
        if (signedVoiceUrl !== undefined) {
          mapped.voiceNoteSignedUrl = signedVoiceUrl;
        }
        return mapped;
      }),
    };
  }).sort((lhs, rhs) => {
    const leftDate = lhs.routeDate || "9999-12-31";
    const rightDate = rhs.routeDate || "9999-12-31";
    if (leftDate !== rightDate) return leftDate.localeCompare(rightDate);
    const leftStop = lhs.assignment?.stopOrder || 999;
    const rightStop = rhs.assignment?.stopOrder || 999;
    if (leftStop !== rightStop) return leftStop - rightStop;
    return String(lhs.updatedAt || "").localeCompare(String(rhs.updatedAt || ""));
  });

  const homes = await Promise.all(propertyIds.map(async (propertyId) => {
    const property = propertyById.get(propertyId);
    const homeSystems = systemsByPropertyId.get(propertyId) ?? [];
    const homeTasks = openTasksByPropertyId.get(propertyId) ?? [];
    const homeVisits = visitRows.filter((row) => row.property?.id === propertyId);
    const completed = homeVisits
      .filter((row) => row.fieldWorkspace?.reportStatus === "completed")
      .sort((lhs, rhs) => String(rhs.fieldWorkspace?.completedAt || "").localeCompare(String(lhs.fieldWorkspace?.completedAt || "")));
    const recentVisits = [...homeVisits]
      .sort((lhs, rhs) =>
        String(rhs.fieldWorkspace?.completedAt || rhs.routeDate || rhs.updatedAt || "").localeCompare(
          String(lhs.fieldWorkspace?.completedAt || lhs.routeDate || lhs.updatedAt || ""),
        )
      )
      .slice(0, 8);
    const homeFiles = (filesByPropertyId.get(propertyId) ?? []).slice(0, 16);

    const homeHouseholdId = compactString(homeVisits[0]?.householdId);
    const chezProfile = homeHouseholdId ? chezProfileByHouseholdId.get(homeHouseholdId) ?? null : null;
    return {
      propertyId,
      householdId: homeHouseholdId,
      name: compactString(property?.name) || "Home",
      address: [property?.street, property?.city, property?.state, property?.zip_code].filter(Boolean).join(", "),
      systemCount: homeSystems.length,
      openRequests: homeVisits.filter((row) => !["completed", "cancelled", "declined"].includes(row.status)).length,
      lastCompletedVisit: completed[0]?.fieldWorkspace?.completedAt ?? null,
      assignedMembers: [...new Set(homeVisits.map((row) => row.assignment?.memberName).filter(Boolean))],
      // Section 19d: pass-through subset of households.chez_profile so
      // the contractor SPA can render standing-instructions banners
      // (spending tier, vendor preferences, logistics). Send only the
      // contractor-relevant subset — full profile incl. communication
      // prefs is intentionally not surfaced to the contractor (privacy).
      chezProfile: chezProfile
        ? {
            spendingTiers: (chezProfile as Record<string, unknown>)?.spending_tiers ?? null,
            vendorPreferences: (chezProfile as Record<string, unknown>)?.vendor_preferences ?? null,
            logistics: (chezProfile as Record<string, unknown>)?.logistics ?? null,
          }
        : null,
      // T3.1 + T3.2 (post-overnight) — per-home routines + vendors so
      // the field app's home detail can render Routines + Vendors sub-
      // tabs (Wave 3a Section 6.13/6.14 gap). Both are camelCase-mapped
      // for iOS Codable parity. Cap at 50 each — HNW estates that
      // exceed this are exotic; UI scrolls.
      routines: (homeHouseholdId ? routinesByHouseholdId.get(homeHouseholdId) ?? [] : [])
        .slice(0, 50)
        .map((r) => {
          const rec = r as Record<string, unknown>;
          return {
            id: compactString(rec.id),
            label: compactString(rec.label),
            kind: compactString(rec.routine_kind),
            cadence: compactString(rec.cadence_type),
            daysOfWeek: Array.isArray(rec.days_of_week)
              ? (rec.days_of_week as number[]).map((n) => Number(n)).filter((n) => Number.isFinite(n))
              : [],
            timeOfDay: compactString(rec.time_of_day) || null,
            activeMonths: Array.isArray(rec.active_months)
              ? (rec.active_months as number[]).map((n) => Number(n)).filter((n) => Number.isFinite(n))
              : [],
            vendorId: compactString(rec.vendor_id) || null,
            costCents: numberValue(rec.cost_cents) || null,
            setupState: compactString(rec.setup_state) || "active",
            chezOwned: Boolean(rec.chez_owned),
            paused: rec.paused_at != null,
          };
        }),
      vendors: (homeHouseholdId ? contractorsByHouseholdId.get(homeHouseholdId) ?? [] : [])
        .slice(0, 50)
        .map((v) => {
          const rec = v as Record<string, unknown>;
          return {
            id: compactString(rec.id),
            companyName: compactString(rec.company_name),
            contactName: compactString(rec.contact_name) || null,
            phone: compactString(rec.phone) || null,
            email: compactString(rec.email) || null,
            website: compactString(rec.website) || null,
            category: compactString(rec.category) || null,
            source: compactString(rec.source) || "manual",
            logoUrl: compactString(rec.logo_url) || null,
            brandColor: compactString(rec.brand_color) || null,
            chezOwned: Boolean(rec.chez_owned),
          };
        }),
      // Sign photos in parallel — bucket is private so the React side
      // needs short-lived signed URLs to display thumbnails.
      systems: await Promise.all(homeSystems.map(async (system) => ({
        id: system.id,
        name: compactString(system.name),
        category: compactString(system.category),
        manufacturer: compactString(system.manufacturer),
        modelNumber: compactString(system.model_number),
        serialNumber: compactString(system.serial_number),
        notes: compactString(system.notes),
        installDate: compactString(system.install_date),
        status: compactString(system.status),
        subtype: compactString(system.subtype),
        catalogSeries: compactString(system.catalog_series),
        catalogModelName: compactString(system.catalog_model_name),
        catalogFuelType: compactString(system.catalog_fuel_type),
        catalogFeatures: Array.isArray(system.catalog_features)
          ? system.catalog_features.map((value) => compactString(value)).filter(Boolean)
          : [],
        reliabilityScore: numberValue(system.reliability_score || 0) || null,
        scoreSummary: compactString(system.score_summary),
        lastServiceDate: compactString(system.last_service_date),
        nextServiceDue: compactString(system.next_service_due),
        totalSpent: numberValue(system.total_spent || 0),
        cachedManualLinks: Array.isArray(system.cached_manual_links)
          ? system.cached_manual_links.map((link) => ({
              type: compactString((link as Record<string, unknown>).type),
              url: compactString((link as Record<string, unknown>).url),
              cached: Boolean((link as Record<string, unknown>).cached),
            })).filter((link) => link.url)
          : [],
        photos: Array.isArray(system.photos)
          ? await Promise.all(
              (system.photos as Record<string, unknown>[]).map(async (photo) => ({
                path: compactString(photo.path),
                contentType: compactString(photo.content_type),
                uploadedAt: compactString(photo.uploaded_at),
                uploadedBy: compactString(photo.uploaded_by),
                caption: compactString(photo.caption),
                signedUrl: await createSignedSystemPhotoUrl(service, compactString(photo.path)),
              })),
            ).then((photos) => photos.filter((p) => p.path))
          : [],
        // Wave M3 — system inventory authoring fields. Sign the voice
        // memo path so the SPA can play it back inline. The decommission
        // / follow-up timestamps + reasons drive the operator-side
        // status pills and "next visit prep" surfacing.
        decommissionedAt: compactString(system.decommissioned_at) || null,
        decommissionReason: compactString(system.decommissioned_reason) || null,
        markedForFollowupAt: compactString(system.marked_for_followup_at) || null,
        followupReason: compactString(system.followup_reason) || null,
        voiceNotePath: compactString(system.voice_note_path) || null,
        voiceNoteSignedUrl: compactString(system.voice_note_path)
          ? await signSystemAttachmentUrl(service, compactString(system.voice_note_path))
          : null,
      }))),
      openTasks: homeTasks.slice(0, 16).map((task) => ({
        id: compactString(task.id),
        title: compactString(task.title),
        dueDate: compactString(task.next_due_date),
        priority: compactString(task.priority),
        assignmentType: compactString(task.assignment_type),
        serviceKey: compactString(task.service_key),
      })),
      recentVisits: recentVisits.map((visit) => ({
        id: visit.id,
        title: visit.title,
        routeDate: visit.routeDate || visit.visit?.scheduledDate || null,
        statusLabel: visit.statusLabel || null,
        completedAt: visit.fieldWorkspace?.completedAt || null,
      })),
      files: homeFiles.map((file) => ({
        id: compactString(file.id),
        title: compactString(file.title),
        category: compactString(file.category),
        uploadedAt: file.uploaded_at,
        notes: compactString(file.notes),
        signedUrl: compactString(file.signed_url),
      })),
    };
  }));

  const messageThreads = visibleRequests.map((request) => {
    const requestId = compactString(request.id);
    const propertyId = compactString(request.property_id);
    const message = latestMessageByRequestId.get(requestId);
    const property = propertyById.get(propertyId);
    const visitRow = visitRows.find((row) => row.requestId === requestId) ?? null;
    const threadHistory = (messagesByRequestId.get(requestId) ?? [])
      .slice(0, 6)
      .map((row) => ({
        id: compactString(row.id),
        body: compactString(row.body),
        senderRole: compactString(row.sender_role),
        createdAt: row.created_at,
        metadata: (row.metadata ?? {}) as Record<string, unknown>,
      }));

    return {
      requestId,
      propertyId,
      title: compactString(request.title),
      requestType: compactString(request.request_type),
      preferredTiming: compactString(request.preferred_timing),
      status: compactString(request.status),
      statusLabel: requestStatusLabel(compactString(request.status)),
      propertyName: compactString(property?.name) || "Home",
      propertyAddress: [property?.street, property?.city, property?.state, property?.zip_code].filter(Boolean).join(", "),
      latestMessage: compactString(message?.body) || "No messages yet. Start the thread.",
      latestMessageAt: message?.created_at ?? request.updated_at,
      senderRole: compactString(message?.sender_role) || "No thread yet",
      assignedMemberName: compactString(visitRow?.assignment?.memberName),
      fieldWorkspaceUrl: compactString(visitRow?.fieldWorkspace?.url),
      recentMessages: threadHistory,
      // Sprint #3 R3-E-3: strip financial coordination data (quote totals,
      // signer names) for technicians. They legitimately see the thread
      // (it's their visit) but quote pricing + signed-name + invoice
      // amounts are dispatch / owner concerns, not field-tech concerns.
      // Owners and dispatchers continue to see the full quote envelope.
      quote: permissions.isFieldTechnician ? null : (visitRow?.quote ?? null),
    };
  });

  const recentWork = visitRows
    .filter((row) => row.fieldWorkspace?.reportStatus === "completed")
    .sort((lhs, rhs) => String(rhs.fieldWorkspace?.completedAt || "").localeCompare(String(lhs.fieldWorkspace?.completedAt || "")))
    .slice(0, 8);

  const activeMembers = teamMembers.filter((row) => compactString(row.status) === "active");
  // T5.8 (post-overnight) — per-tech revenue + utilization metrics
  // for the Operations Desk Crew screen. HomeDetail.tsx already
  // computes lifetime spend client-side from visit.quote.total; we
  // surface the same shape here aggregated per workspace member.
  // Plus a 30-day count for "this month" utilization context.
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    .toISOString().slice(0, 10);
  const teamMemberRows = teamMembers.map((member) => {
    const memberId = compactString(member.id);
    const memberVisits = visitRows.filter((row) => row.assignment?.memberId === memberId);
    const todayStops = memberVisits.filter((row) => row.routeDate === today).length;
    const openVisits = memberVisits.filter((row) => !["completed", "cancelled", "declined"].includes(row.status)).length;
    const completedCount = memberVisits.filter((row) => row.status === "completed").length;
    // Lifetime $ — sum of quote.total for every visit assigned to this
    // member where a quote exists and the visit ended in 'completed'.
    // Cents-precision Number to avoid floating drift.
    const lifetimeRevenueCents = memberVisits
      .filter((row) => row.status === "completed" && row.quote?.total != null)
      .reduce((sum, row) => sum + Math.round(Number(row.quote?.total ?? 0) * 100), 0);
    // This-month $ — same aggregation, scoped to last 30 days by
    // routeDate. Visits without a routeDate are treated as 'today'
    // (recent activity) so they don't accidentally drop off.
    const thisMonthRevenueCents = memberVisits
      .filter((row) => row.status === "completed" && row.quote?.total != null)
      .filter((row) => {
        const date = row.routeDate ?? today;
        return date >= thirtyDaysAgo;
      })
      .reduce((sum, row) => sum + Math.round(Number(row.quote?.total ?? 0) * 100), 0);
    // Utilization rate — completed / (completed + open). 0-1.0.
    // Surfaces as a percentage on the Crew screen.
    const totalAssigned = completedCount + openVisits;
    const utilizationRate = totalAssigned > 0 ? completedCount / totalAssigned : 0;
    return {
      id: memberId,
      userId: compactString(member.user_id),
      fullName: compactString(member.full_name) || compactString(member.email) || "Team member",
      email: compactString(member.email),
      phone: compactString(member.phone),
      title: compactString(member.title) || roleLabel(compactString(member.role)),
      role: compactString(member.role),
      roleLabel: roleLabel(compactString(member.role)),
      status: compactString(member.status),
      inviteUrl: compactString(member.invite_token) ? teamInviteUrl(compactString(member.invite_token)) : null,
      lastSeenAt: member.last_seen_at,
      todayStops,
      openVisits,
      completedCount,
      // T5.8 — analytics fields
      lifetimeRevenueCents,
      thisMonthRevenueCents,
      utilizationRate,
      mobileFocus: compactString(member.role) === "technician",
      isDefaultAssignee: member.is_default_assignee === true,
    };
  }).sort((lhs, rhs) => {
    if (lhs.status !== rhs.status) return lhs.status.localeCompare(rhs.status);
    return lhs.fullName.localeCompare(rhs.fullName);
  });

  const stats = {
    requestedVisits: visitRows.filter((row) => ["submitted", "sent_to_handyman", "alternate_dates_proposed", "awaiting_homeowner"].includes(row.status)).length,
    upcomingVisits: visitRows.filter((row) => ["confirmed", "scheduled", "on_my_way", "checked_in", "in_progress"].includes(row.status)).length,
    unassignedVisits: visitRows.filter((row) => !row.assignment?.memberId && !["completed", "cancelled", "declined"].includes(row.status)).length,
    todayStops: visitRows.filter((row) => row.routeDate === today && !["completed", "cancelled", "declined"].includes(row.status)).length,
    homesServiced: homes.length,
    activeMembers: activeMembers.length,
    draftQuotes: quotes.filter((quote) => compactString(quote.status) === "draft").length,
    quotesSent: quotes.filter((quote) => compactString(quote.status) === "sent").length,
    completedVisits: recentWork.length,
    openThreads: messageThreads.length,
    myAssignedVisits: visitRows.filter((row) => row.assignment?.memberId === myMemberId).length,
  };

  return {
    needsWorkspace: false,
    currentUser: {
      id: user.id,
      memberId: myMemberId,
      email: normalizedEmail(user.email),
      fullName:
        compactString(membership.full_name) ||
        compactString((user.user_metadata as Record<string, unknown> | undefined)?.full_name) ||
        compactString((user.user_metadata as Record<string, unknown> | undefined)?.name),
      role: currentRole,
      roleLabel: roleLabel(currentRole),
    },
    permissions,
    workspace: {
      id: workspaceId,
      companyName: compactString(workspace.company_name),
      primaryEmail: compactString(workspace.primary_email),
      primaryPhone: compactString(workspace.primary_phone),
      website: compactString(workspace.website),
      contractorCount: contractorIds.length,
      activeMemberCount: activeMembers.length,
      invitedMemberCount: teamMemberRows.filter((row) => row.status === "invited").length,
      providerUrl: PROVIDER_SITE_URL,
      // Wave P: branding + directory fields the Settings screen reads/writes.
      // Always serialize (empty string / [] when null) so the SPA never has
      // to special-case undefined.
      licenseNumber: compactString(workspace.license_number),
      serviceState: compactString(workspace.service_state),
      serviceCity: compactString(workspace.service_city),
      serviceZipCodes: Array.isArray(workspace.service_zip_codes)
        ? (workspace.service_zip_codes as unknown[]).map((z) => compactString(z)).filter(Boolean)
        : [],
      categories: Array.isArray(workspace.categories)
        ? (workspace.categories as unknown[]).map((c) => compactString(c)).filter(Boolean)
        : [],
      displayBlurb: compactString(workspace.display_blurb),
      headshotUrl: compactString(workspace.headshot_url),
      isListedInDirectory: Boolean(workspace.is_listed_in_directory),
    },
    linkedContractors: (contractorLinks ?? []).map((row: Record<string, unknown>) => {
      const contractor = (row.contractors as Record<string, unknown> | undefined) ?? {};
      return {
        contractorId: compactString(row.contractor_id),
        companyName: compactString(contractor.company_name),
        contactName: compactString(contractor.contact_name),
        email: compactString(contractor.email),
        phone: compactString(contractor.phone),
        category: compactString(contractor.category),
      };
    }),
    stats,
    visits: visitRows,
    homes,
    messages: messageThreads,
    recentWork,
    teamMembers: teamMemberRows,
    // Sprint #3 R3-E-3: technicians don't manage quote pricing or
    // signature workflows. Strip the array entirely; owners and
    // dispatchers continue to see the full quote envelope.
    quotes: permissions.isFieldTechnician ? [] : quotes.map((quote) => {
      const property = propertyById.get(compactString(quote.property_id));
      const lineItems = (Array.isArray(quote.line_items) ? quote.line_items : []).map(mapLineItemForClient);
      const quoteId = compactString(quote.id);
      const latestQuoteMessage = latestQuoteMessageByQuoteId.get(quoteId) ?? null;
      const recentQuoteMessages = (quoteMessagesByQuoteId.get(quoteId) ?? [])
        .slice(0, 6)
        .map((message) => ({
          id: compactString(message.id),
          senderRole: compactString(message.sender_role),
          senderName: compactString(message.sender_name),
          body: compactString(message.body),
          createdAt: message.created_at,
          deliveryChannel: compactString(message.delivery_channel),
        }));
      const recipientKind = compactString(quote.recipient_kind) || (compactString(quote.household_id) ? "linked_home" : "prospect");
      const recipientName = compactString(quote.prospect_name) || compactString(property?.name) || "Client";
      const recipientEmail = compactString(quote.prospect_email);
      return {
        id: quote.id,
        workspaceId: compactString(quote.workspace_id),
        contractorId: compactString(quote.contractor_id),
        householdId: compactString(quote.household_id),
        propertyId: compactString(quote.property_id),
        visitTaskId: compactString(quote.visit_task_id),
        title: compactString(quote.title),
        status: compactString(quote.status),
        statusLabel: quoteStatusLabel(compactString(quote.status)),
        propertyName: compactString(property?.name) || "",
        recipientKind,
        recipientName,
        recipientEmail,
        recipientPhone: compactString(quote.prospect_phone),
        recipientAddress: compactString(quote.prospect_address),
        audienceLabel: recipientKind === "prospect"
          ? (recipientName || recipientEmail || "Prospect")
          : (compactString(property?.name) || "Home"),
        total: numberValue(quote.total),
        itemCount: lineItems.length,
        updatedAt: quote.updated_at,
        sentAt: quote.sent_at,
        lastSentAt: quote.last_sent_at,
        viewedAt: quote.viewed_at,
        approvedAt: quote.approved_at,
        declinedAt: quote.declined_at,
        // Wave Z.3 — surface negotiation metadata so the desktop can
        // render the version timeline. Phase 73b added these columns.
        signedAt: quote.signed_at ?? null,
        signedName: compactString(quote.signed_name) || null,
        // Wave M4 — kitchen-table signature artifact. Operations Desk
        // appends "· signed in person" / "· witnessed" suffixes off
        // these two fields to make in-person signatures readable in
        // the Quotes list.
        signaturePath: compactString(quote.signature_path) || null,
        signerRole: compactString(quote.signer_role) || null,
        // Wave M8 — set when the quote was staged from the field tech's
        // end-of-visit wizard. Drives the "Suggested by visit" badge
        // on the Quotes list + selected card so the operator knows the
        // row is a draft from the field needing line items + send.
        suggestedByRequestId: compactString(quote.suggested_by_request_id) || null,
        homeownerRevisedAt: quote.homeowner_revised_at ?? null,
        requestId: compactString(quote.request_id),
        publicShareUrl: publicQuoteUrl(compactString(quote.public_share_token)),
        lineItems,
        homeownerMessage: compactString(quote.homeowner_message),
        scopeNotes: compactString(quote.scope_notes),
        latestMessage: latestQuoteMessage
          ? {
              senderRole: compactString(latestQuoteMessage.sender_role),
              senderName: compactString(latestQuoteMessage.sender_name),
              body: compactString(latestQuoteMessage.body),
              createdAt: latestQuoteMessage.created_at,
            }
          : null,
        recentMessages: recentQuoteMessages,
        // Wave V.1 — quote bundles. parent_quote_id is the FK chain
        // shared with Phase 73b counter-offers, but the bundle case is
        // distinguished by the BUNDLE_MARKER sentinel in scope_notes.
        // bundleTierLabel is the per-child label parsed off the title
        // suffix; bundleMeta on the parent carries the tier list +
        // chosen-child breadcrumb if a tier has been picked.
        parentQuoteId: compactString(quote.parent_quote_id) || null,
        bundleMeta: (() => {
          const { meta } = parseBundleScopeNotes(compactString(quote.scope_notes));
          return meta;
        })(),
        bundleTierLabel: (() => {
          if (!quote.parent_quote_id) return null;
          const childTitle = compactString(quote.title);
          // Tier lives as title suffix " · {label}". Parent title may
          // not be in scope here (it's a different row), so fall back
          // to splitting on the last " · " separator.
          const idx = childTitle.lastIndexOf(" · ");
          return idx >= 0 ? childTitle.slice(idx + 3) : null;
        })(),
      };
    }),
    // Sprint #3 R3-E-3: saved quote items are the line-item library
    // used to BUILD quotes. Technicians don't build quotes, so empty
    // for them — matches the same role-aware narrowing as quotes / invoices.
    savedQuoteItems: permissions.isFieldTechnician ? [] : savedItems.map((item) => ({
      id: item.id,
      name: compactString(item.name),
      description: compactString(item.description),
      unit: compactString(item.unit) || "ea",
      defaultQuantity: numberValue(item.default_quantity || 1),
      defaultUnitPrice: numberValue(item.default_unit_price || 0),
      sortOrder: numberValue(item.sort_order),
    })),
    // Wave Q (Section 8) — provider invoices.
    //
    // Sprint #3 R3-E-3: technicians don't manage invoicing (it's a
    // dispatch / owner concern). The pre-fix flow filtered invoices
    // to the technician's own visits but still surfaced totals,
    // subtotals, line items, and amount-paid — financial detail the
    // field tech doesn't need to do their job. Strip the invoices
    // array entirely for the technician role; owners and dispatchers
    // continue to see the full envelope.
    invoices: permissions.isFieldTechnician ? [] : invoices.map((row) => {
      const property = propertyById.get(compactString(row.property_id));
      const lineItems = (Array.isArray(row.line_items) ? row.line_items : []).map(mapLineItemForClient);
      const status = compactString(row.status) || "draft";
      return {
        id: compactString(row.id),
        workspaceId: compactString(row.workspace_id),
        contractorId: compactString(row.contractor_id) || null,
        householdId: compactString(row.household_id) || null,
        propertyId: compactString(row.property_id) || null,
        requestId: compactString(row.request_id) || null,
        sourceQuoteId: compactString(row.source_quote_id) || null,
        invoiceNumber: compactString(row.invoice_number),
        title: compactString(row.title) || "",
        status,
        statusLabel: invoiceStatusLabel(status),
        currency: compactString(row.currency) || "USD",
        lineItems,
        scopeNotes: compactString(row.scope_notes) || null,
        homeownerMessage: compactString(row.homeowner_message) || null,
        subtotal: numberValue(row.subtotal),
        taxTotal: numberValue(row.tax_total),
        total: numberValue(row.total),
        amountPaid: numberValue(row.amount_paid),
        propertyName: compactString(property?.name) || "",
        dueDate: compactString(row.due_date) || null,
        sentAt: row.sent_at ?? null,
        paidAt: row.paid_at ?? null,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      };
    }),
    // Wave S — every workspace this user can switch into. Single-workspace
    // users get a length=1 array; the SPA hides the dropdown affordance.
    availableWorkspaces,
  };
}

function invoiceStatusLabel(status: string): string {
  switch (status) {
    case "draft":
      return "Draft";
    case "sent":
      return "Sent";
    case "viewed":
      return "Viewed";
    case "paid":
      return "Paid";
    case "partial":
      return "Partially paid";
    case "overdue":
      return "Overdue";
    case "void":
      return "Void";
    default:
      return status || "Draft";
  }
}

/**
 * Allow a provider to edit a home_system row for a property they have
 * a confirmed work relationship with (i.e. there's at least one
 * handyman_request linking that property's household to one of the
 * workspace's linked contractors). Lets the handyman update make/model/
 * notes after a visit from desktop without granting broad RLS write
 * access on home_systems.
 */
async function updateHomeSystemForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const systemId = compactString(body.systemId);
  if (!systemId) throw new Error("systemId is required");

  // Verify the system's property is one we serve.
  const { data: system, error: systemError } = await service
    .from("home_systems")
    .select("id, property_id, household_id")
    .eq("id", systemId)
    .maybeSingle();
  if (systemError) throw systemError;
  if (!system) throw new Error("System not found");

  const propertyId = compactString(system.property_id);
  if (!propertyId) throw new Error("System has no property");

  // Workspace must have at least one handyman_request for this property's
  // household via one of its linked contractors.
  const { data: links } = await service
    .from("provider_contractor_links")
    .select("contractor_id")
    .eq("workspace_id", workspaceId);
  const contractorIds = (links ?? [])
    .map((row: Record<string, unknown>) => compactString(row.contractor_id))
    .filter(Boolean);
  if (contractorIds.length === 0) throw new Error("Workspace has no linked contractors");

  const { data: linkedRequest } = await service
    .from("handyman_requests")
    .select("id")
    .eq("property_id", propertyId)
    .in("contractor_id", contractorIds)
    .limit(1)
    .maybeSingle();
  if (!linkedRequest) throw new Error("This home isn't on your books");

  // Build update payload — only include fields that were sent.
  const update: Record<string, unknown> = { updated_at: isoNow() };
  if (typeof body.name === "string")          update.name = compactString(body.name);
  if (typeof body.manufacturer === "string")  update.manufacturer = compactString(body.manufacturer);
  if (typeof body.modelNumber === "string")   update.model_number = compactString(body.modelNumber);
  if (typeof body.serialNumber === "string")  update.serial_number = compactString(body.serialNumber);
  if (typeof body.notes === "string")         update.notes = compactString(body.notes);
  if (typeof body.installDate === "string")   update.install_date = compactString(body.installDate);

  const { data: updated, error: updateError } = await service
    .from("home_systems")
    .update(update)
    .eq("id", systemId)
    .select()
    .single();
  if (updateError) throw updateError;
  return { system: updated };
}

/**
 * Shared helper — confirms the calling workspace serves this property
 * via at least one handyman_request through one of its linked
 * contractors, and returns the system row.
 */
async function loadSystemForProviderWrite(
  service: ServiceClient,
  workspaceId: string,
  systemId: string,
) {
  const { data: system, error: systemError } = await service
    .from("home_systems")
    .select("id, property_id, household_id, photos")
    .eq("id", systemId)
    .maybeSingle();
  if (systemError) throw systemError;
  if (!system) throw new Error("System not found");

  const propertyId = compactString(system.property_id);
  if (!propertyId) throw new Error("System has no property");

  const { data: links } = await service
    .from("provider_contractor_links")
    .select("contractor_id")
    .eq("workspace_id", workspaceId);
  const contractorIds = (links ?? [])
    .map((row: Record<string, unknown>) => compactString(row.contractor_id))
    .filter(Boolean);
  if (contractorIds.length === 0) throw new Error("Workspace has no linked contractors");

  const { data: linkedRequest } = await service
    .from("handyman_requests")
    .select("id")
    .eq("property_id", propertyId)
    .in("contractor_id", contractorIds)
    .limit(1)
    .maybeSingle();
  if (!linkedRequest) throw new Error("This home isn't on your books");

  return system;
}

/**
 * Upload a photo of a home_system. The web client reads the file as
 * base64 (already client-side compressed to a sane size — typically
 * <500KB), POSTs it through here, and we write through the service
 * role so we never have to expose bucket-level write RLS to providers
 * across household boundaries. The path lands in the system's
 * `photos` JSONB array; the read path signs short-lived URLs.
 */
async function uploadHomeSystemPhotoForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const systemId = compactString(body.systemId);
  if (!systemId) throw new Error("systemId is required");

  const fileBase64 = compactString(body.fileBase64);
  if (!fileBase64) throw new Error("fileBase64 is required");
  const filename = safeFilenameSegment(compactString(body.filename) || "photo.jpg");
  const contentType = compactString(body.contentType) || "image/jpeg";
  const caption = compactString(body.caption);

  const system = await loadSystemForProviderWrite(service, workspaceId, systemId);
  const householdId = compactString(system.household_id);
  if (!householdId) throw new Error("System has no household");

  // Path: {household_id}/{system_id}/{timestamp}-{filename}
  const stamp = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const path = `${householdId}/${systemId}/${stamp}-${filename}`;

  const bytes = decodeBase64Body(fileBase64);
  const { error: uploadError } = await service.storage
    .from("home-system-photos")
    .upload(path, bytes, { contentType, upsert: false });
  if (uploadError) throw new Error(`Upload failed: ${uploadError.message}`);

  const existing = Array.isArray(system.photos) ? (system.photos as unknown[]) : [];
  const nextPhotos = [
    ...existing,
    {
      path,
      content_type: contentType,
      uploaded_at: isoNow(),
      uploaded_by: userId || null,
      caption: caption || null,
    },
  ];

  const { error: updateError } = await service
    .from("home_systems")
    .update({ photos: nextPhotos, updated_at: isoNow() })
    .eq("id", systemId);
  if (updateError) throw updateError;

  const signedUrl = await createSignedSystemPhotoUrl(service, path);
  return { photo: { path, contentType, uploadedAt: isoNow(), uploadedBy: userId, caption, signedUrl } };
}

async function deleteHomeSystemPhotoForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const systemId = compactString(body.systemId);
  const path = compactString(body.path);
  if (!systemId) throw new Error("systemId is required");
  if (!path) throw new Error("path is required");

  const system = await loadSystemForProviderWrite(service, workspaceId, systemId);
  const existing = Array.isArray(system.photos) ? (system.photos as Record<string, unknown>[]) : [];
  const nextPhotos = existing.filter((row) => compactString(row.path) !== path);

  // Best-effort storage cleanup; ignore failure (the row removal is
  // the source of truth for the UI).
  await service.storage.from("home-system-photos").remove([path]).catch((err: unknown) => {
    console.warn("[handyman-provider] failed to remove system photo", path, err);
  });

  const { error: updateError } = await service
    .from("home_systems")
    .update({ photos: nextPhotos, updated_at: isoNow() })
    .eq("id", systemId);
  if (updateError) throw updateError;

  return { ok: true };
}

/**
 * Split a visit's punch list into two visits. The provider hand-picks
 * which items should move to a follow-up; we trim those lines from
 * the original maintenance_task's notes, create a brand-new
 * maintenance_task + handyman_request for the follow-up with just the
 * moved items, and drop a system message in the original thread so
 * the homeowner sees what happened.
 */
async function splitVisitPunchList(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canAssignWork");

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");

  const movedTitles = Array.isArray(body.movedTitles)
    ? (body.movedTitles as unknown[]).map(compactString).filter(Boolean)
    : [];
  if (movedTitles.length === 0) throw new Error("Pick at least one item to move");

  const followUpTitle = compactString(body.followUpTitle) || "Follow-up visit";
  // maintenance_tasks.next_due_date is NOT NULL — fall back to +14
  // days when the provider didn't pick a target date in the modal.
  const requestedFollowUpDate = compactString(body.followUpDate);
  const followUpDate = requestedFollowUpDate || (() => {
    const d = new Date();
    d.setDate(d.getDate() + 14);
    return d.toISOString().slice(0, 10);
  })();

  // Fetch the original request + verify the workspace owns it via the
  // contractor link.
  const { data: original, error: originalError } = await service
    .from("handyman_requests")
    .select("id, household_id, property_id, contractor_id, visit_task_id, title, request_type, urgency, recommended_lane")
    .eq("id", requestId)
    .maybeSingle();
  if (originalError) throw originalError;
  if (!original) throw new Error("Visit not found");

  const contractorId = compactString(original.contractor_id);
  if (contractorId) {
    const { data: link } = await service
      .from("provider_contractor_links")
      .select("workspace_id")
      .eq("workspace_id", workspaceId)
      .eq("contractor_id", contractorId)
      .maybeSingle();
    if (!link) throw new Error("This visit isn't on your books");
  }

  const householdId = compactString(original.household_id);
  const propertyId = compactString(original.property_id);
  const originalTaskId = compactString(original.visit_task_id);
  if (!householdId || !propertyId || !originalTaskId) {
    throw new Error("Visit is missing the linked maintenance task");
  }

  // Fetch the linked maintenance_task to read + rewrite notes.
  const { data: originalTask, error: taskError } = await service
    .from("maintenance_tasks")
    .select("id, notes, title, scheduled_date, priority")
    .eq("id", originalTaskId)
    .maybeSingle();
  if (taskError) throw taskError;
  if (!originalTask) throw new Error("Linked task not found");

  const originalNotes = compactString(originalTask.notes);

  // Partition the notes lines: anything whose cleaned title is in
  // movedTitles moves; everything else stays. We preserve the original
  // header/preamble lines (anything before the first list item) as-is
  // on the staying side.
  const lines = originalNotes.split(/\r?\n/);
  const moved: string[] = [];
  const staying: string[] = [];
  const movedSet = new Set(movedTitles.map((t) => t.toLowerCase().trim()));

  for (const raw of lines) {
    const trimmed = raw.trim();
    if (!trimmed) {
      staying.push(raw);
      continue;
    }
    // Strip bullet/number prefix + any trailing duration marker so the
    // cleaned title matches what the React side sent.
    let working = trimmed;
    for (const prefix of ["- ", "• ", "* "]) {
      if (working.startsWith(prefix)) {
        working = working.slice(prefix.length);
        break;
      }
    }
    const numericMatch = working.match(/^(\d+)[.)]\s+/);
    if (numericMatch) working = working.slice(numericMatch[0].length);

    const cleaned = working
      .replace(/\s*\(~?\d+\s*min\)\s*$/i, "")
      .replace(/\s*~\d+\s*min\s*$/i, "")
      .replace(/\s*[·•\-]\s*~?\d+\s*min\s*$/i, "")
      .replace(/\s*\d+\s*min\s*$/i, "")
      .trim();

    if (cleaned && movedSet.has(cleaned.toLowerCase())) {
      moved.push(raw); // preserve the original line shape (bullet, duration)
    } else {
      staying.push(raw);
    }
  }

  if (moved.length === 0) {
    throw new Error("Couldn't match any of the moved items in the notes");
  }

  // Update the original task's notes with only the staying items.
  // maintenance_tasks doesn't have updated_at — only created_at.
  const stayingNotes = staying.join("\n").trimEnd();
  const { error: trimError } = await service
    .from("maintenance_tasks")
    .update({ notes: stayingNotes })
    .eq("id", originalTaskId);
  if (trimError) throw trimError;

  // Create the new follow-up task with the moved items as notes. Lead
  // with a "Punch list:" header so the parser picks it up cleanly on
  // both sides.
  const followUpNotes = ["Punch list:", ...moved].join("\n");
  const { data: newTask, error: newTaskError } = await service
    .from("maintenance_tasks")
    .insert({
      property_id: propertyId,
      household_id: householdId,
      title: followUpTitle,
      description: null,
      frequency: "Once",
      next_due_date: followUpDate,
      scheduled_date: followUpDate,
      priority: compactString(originalTask.priority) || "Medium",
      assigned_contractor_id: contractorId || null,
      notes: followUpNotes,
      assignment_type: "vendor",
      needs_vendor: false,
      assigned_route: "handyman",
      service_key: "handyman:visit-split",
    })
    .select("id")
    .single();
  if (newTaskError || !newTask) throw newTaskError ?? new Error("Could not create follow-up task");

  // Create the new request, mirroring the original's metadata.
  // Source must be one of: homeowner, haven, vendor, field. We're
  // the provider creating it, so "vendor" matches the schema's intent.
  const { data: newRequest, error: newRequestError } = await service
    .from("handyman_requests")
    .insert({
      household_id: householdId,
      property_id: propertyId,
      contractor_id: contractorId || null,
      visit_task_id: compactString(newTask.id),
      created_by_user_id: userId,
      request_type: compactString(original.request_type) || "standard_visit",
      source: "vendor",
      title: followUpTitle,
      details: null,
      preferred_timing: followUpDate,
      urgency: compactString(original.urgency) || "routine",
      status: "submitted",
      first_visit_setup_requested: false,
      recommended_lane: compactString(original.recommended_lane) || "handyman",
      quick_upsell_titles: [],
    })
    .select()
    .single();
  if (newRequestError || !newRequest) throw newRequestError ?? new Error("Could not create follow-up visit");

  // Drop a system message in the original thread so the homeowner
  // sees what happened (and a confirmation in the new thread). Use
  // the existing "vendor" sender_role so RLS + display layer treat
  // it like a normal vendor message.
  const movedSummary = `${moved.length} item${moved.length === 1 ? "" : "s"} moved to a follow-up visit${followUpDate ? ` on ${followUpDate}` : ""}.`;
  // handyman_request_messages does NOT have a sender_user_id column
  // (PGRST204 confirmed). Stash the actor in metadata.actor_user_id so
  // the audit trail still has provenance without breaking the insert.
  // Wave Z subagent flagged this as a latent bug; this is the fix.
  await service.from("handyman_request_messages").insert([
    {
      request_id: requestId,
      household_id: householdId,
      sender_role: "vendor",
      body: `Split this visit: ${movedSummary} The follow-up is now its own thread.`,
      metadata: { kind: "text", split_to_request_id: newRequest.id, actor_user_id: userId },
    },
    {
      request_id: newRequest.id,
      household_id: householdId,
      sender_role: "vendor",
      body: `Created from a previous visit. ${moved.length} item${moved.length === 1 ? "" : "s"} ready to schedule${followUpDate ? ` for ${followUpDate}` : ""}.`,
      metadata: { kind: "text", split_from_request_id: requestId, actor_user_id: userId },
    },
  ]);

  // Push the homeowner so the new visit doesn't sit silently.
  await notifyHomeownersForRequest(service, householdId, {
    title: "A second visit was scheduled",
    body: movedSummary,
    requestId: newRequest.id,
    eventType: "handyman_visit_split",
    extra: { source_request_id: requestId },
  });

  return {
    ok: true,
    movedCount: moved.length,
    remainingCount: staying.filter((l) => l.trim().length > 0).length,
    newRequestId: newRequest.id,
    newTaskId: newTask.id,
  };
}

/**
 * Add a "managed" client (homeowner + property) without requiring the
 * homeowner to install the Chez app first. Creates a household with
 * no auth user, a property, a contractor linked to the workspace, and
 * a placeholder handyman_request so the home immediately surfaces in
 * /homes / /visits / dashboard counts. The homeowner can later claim
 * the household by signing up with the email we stored.
 */
async function addClientForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canAssignWork");

  const clientName = compactString(body.clientName);
  const street = compactString(body.street);
  if (!clientName) throw new Error("Client name is required");
  if (!street) throw new Error("Street address is required");

  const email = normalizedEmail(body.email);
  const phone = compactString(body.phone);
  const city = compactString(body.city);
  const state = compactString(body.state);
  const zip = compactString(body.zip);
  const notes = compactString(body.notes);

  // 1. Household — no linked auth user; this is a "managed" household
  //    the provider is operating on behalf of. The homeowner can claim
  //    it later by signing up with `claim_email`.
  const { data: household, error: householdError } = await service
    .from("households")
    .insert({
      name: `${clientName}'s home`,
      claim_email: email || null,
      managed_by_provider_workspace_id: workspaceId,
    })
    .select("id")
    .single();
  if (householdError || !household) throw householdError ?? new Error("Could not create household");
  const householdId = compactString(household.id);

  // 2. Property anchored to that household.
  const fullAddress = [street, city, state, zip].filter(Boolean).join(", ");
  const { data: property, error: propertyError } = await service
    .from("properties")
    .insert({
      household_id: householdId,
      name: street,
      street,
      city: city || null,
      state: state || null,
      zip_code: zip || null,
      property_type: "Single Family",
    })
    .select("id, name, street, city, state, zip_code")
    .single();
  if (propertyError || !property) throw propertyError ?? new Error("Could not create property");
  const propertyId = compactString(property.id);

  // 3. Workspace info for the contractor mirror.
  const { data: workspace } = await service
    .from("provider_workspaces")
    .select("company_name, primary_email, primary_phone, website")
    .eq("id", workspaceId)
    .maybeSingle();

  const contractorId = await ensureHouseholdContractorForWorkspace(service, {
    workspaceId,
    householdId,
    companyName: compactString(workspace?.company_name),
    contactName: compactString(workspace?.company_name),
    email: compactString(workspace?.primary_email),
    phone: compactString(workspace?.primary_phone),
    website: compactString(workspace?.website),
    claimSource: "manual",
  });

  // 4. Placeholder request so the home shows up in /homes (the
  //    homes list aggregates from handyman_requests). Marked as
  //    "scheduled" rather than "submitted" so it doesn't pollute
  //    the unassigned dispatch queue. The provider can build quotes
  //    or actual visits against this request.
  const noteParts: string[] = [`Added by ${compactString(user.email) || "the provider"}.`];
  if (notes) noteParts.push(notes);
  if (email) noteParts.push(`Contact: ${email}`);
  if (phone) noteParts.push(`Phone: ${phone}`);

  await service
    .from("handyman_requests")
    .insert({
      household_id: householdId,
      property_id: propertyId,
      contractor_id: contractorId || null,
      created_by_user_id: userId,
      request_type: "standard_visit",
      source: "vendor",
      title: `Initial setup: ${clientName}`,
      details: noteParts.join("\n"),
      preferred_timing: null,
      urgency: "routine",
      status: "scheduled",
      first_visit_setup_requested: true,
      recommended_lane: "handyman",
      quick_upsell_titles: [],
    });

  return {
    ok: true,
    household: {
      id: householdId,
      name: `${clientName}'s home`,
      email,
      phone,
    },
    property: {
      id: propertyId,
      name: compactString(property.name),
      address: fullAddress,
    },
  };
}

/**
 * Delete a draft quote. Only `draft` rows can be deleted — sent /
 * viewed / approved / declined quotes have a paper trail and stay on
 * record. Workspace-scoped via assertWorkspaceAccess + an explicit
 * workspace_id match on the row.
 */
async function deleteQuoteForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canBuildQuotes");

  const quoteId = compactString(body.quoteId);
  if (!quoteId) throw new Error("quoteId is required");

  const { data: quote, error: quoteError } = await service
    .from("provider_quotes")
    .select("id, status, workspace_id")
    .eq("id", quoteId)
    .eq("workspace_id", workspaceId)
    .maybeSingle();
  if (quoteError) throw quoteError;
  if (!quote) throw new Error("Quote not found");
  if (compactString(quote.status) !== "draft") {
    throw new Error("Only draft quotes can be deleted. Withdraw or supersede sent quotes instead.");
  }

  // Wave V.1 — when the deleted quote is a BUNDLE PARENT, walk its
  // children too. Children carry their own provider_quote_messages
  // (the bundle-sent event lives on the parent only, but counter-offer
  // chains can attach messages to children) so clean those first.
  const { data: childIdsRaw } = await service
    .from("provider_quotes")
    .select("id, status")
    .eq("parent_quote_id", quoteId);
  const children = (childIdsRaw ?? []) as Array<{ id: string; status: string }>;
  // Refuse to delete a bundle parent if any child has been sent — the
  // homeowner has already seen the offer. Force the contractor to
  // withdraw individual children first instead. For pure-draft bundles
  // (no child sent), cascade clean.
  if (children.some((c) => compactString(c.status) !== "draft")) {
    throw new Error("This bundle has tiers that have already been sent. Withdraw them individually instead.");
  }
  if (children.length > 0) {
    const childIds = children.map((c) => compactString(c.id));
    await service.from("provider_quote_messages").delete().in("quote_id", childIds);
    await service.from("provider_quotes").delete().in("id", childIds);
  }

  // Cascade: provider_quote_messages have ON DELETE CASCADE on most
  // schemas, but be defensive — clean them out first.
  await service.from("provider_quote_messages").delete().eq("quote_id", quoteId);
  const { error: deleteError } = await service
    .from("provider_quotes")
    .delete()
    .eq("id", quoteId);
  if (deleteError) throw deleteError;
  return { ok: true, quoteId };
}

/**
 * Update the status on a handyman_request from the provider side. Used
 * by the desktop "Mark complete" / "Reopen" buttons. Validates the
 * request belongs to the calling workspace.
 */
async function updateRequestStatusForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  const status = compactString(body.status);
  if (!requestId) throw new Error("requestId is required");
  const allowed = [
    "submitted", "scheduled", "sent_to_handyman", "alternate_dates_proposed",
    "awaiting_homeowner", "confirmed", "on_my_way", "checked_in", "quoted",
    "in_progress", "completed", "follow_up_recommended", "cancelled", "declined",
  ];
  if (!allowed.includes(status)) throw new Error(`Invalid status: ${status}`);

  const { data: links } = await service
    .from("provider_contractor_links")
    .select("contractor_id")
    .eq("workspace_id", workspaceId);
  const contractorIds = (links ?? [])
    .map((row: Record<string, unknown>) => compactString(row.contractor_id))
    .filter(Boolean);

  const { data: request } = await service
    .from("handyman_requests")
    .select("id, contractor_id, status")
    .eq("id", requestId)
    .maybeSingle();
  if (!request) throw new Error("Request not found");
  if (!contractorIds.includes(compactString(request.contractor_id))) {
    throw new Error("Request not in this workspace");
  }

  // Sprint #4 R5-E-3: don't overwrite a terminal state (cancelled) with
  // a different terminal state (completed). When an operator hits Complete
  // after a concurrent Cancel landed, the cancel wins and we don't write
  // a contradictory audit row.
  const currentStatus = compactString(request.status);
  if (currentStatus === "cancelled" && status === "completed") {
    throw new Error("Visit was cancelled; cannot mark complete.");
  }
  if (currentStatus === "completed" && status === "cancelled") {
    throw new Error("Visit was completed; cannot mark cancelled.");
  }
  // Idempotent: same-state writes are no-ops with no audit message.
  if (currentStatus === status) {
    return { request };
  }

  const { data: updated, error: updateError } = await service
    .from("handyman_requests")
    .update({ status, updated_at: isoNow() })
    .eq("id", requestId)
    .select()
    .single();
  if (updateError) throw updateError;

  // Cross-app parity: append an audit-trail message to the homeowner's
  // conversation thread so they see WHEN the contractor flipped the
  // status and to WHAT. Without this, the homeowner has zero record of
  // visit completion / cancellation events. The sender_role CHECK
  // constraint is ('homeowner', 'haven', 'vendor'); we use 'vendor' so
  // the message renders inline as a contractor-side update with the
  // existing iOS message-thread layout. The body is a short, neutral
  // status flip — the homeowner's iOS app already formats sender_role
  // 'vendor' as the contractor's voice. Failures here do NOT roll back
  // the status update; the audit message is best-effort.
  try {
    const householdId = compactString(updated.household_id);
    const statusLabel = (() => {
      switch (status) {
        case "completed": return "Visit marked complete.";
        case "in_progress": return "Visit started.";
        case "on_my_way": return "Tech on the way.";
        case "checked_in": return "Tech checked in.";
        case "cancelled": return "Visit cancelled.";
        case "follow_up_recommended": return "Follow-up recommended after this visit.";
        case "scheduled": return "Visit scheduled.";
        case "confirmed": return "Visit confirmed.";
        case "awaiting_homeowner": return "Awaiting your response.";
        case "alternate_dates_proposed": return "New time options proposed.";
        case "submitted": return "Request received.";
        case "sent_to_handyman": return "Request sent to the contractor.";
        case "quoted": return "Quote ready for review.";
        case "declined": return "Request declined.";
        default: return `Status changed to ${status}.`;
      }
    })();
    if (householdId) {
      await service.from("handyman_request_messages").insert({
        request_id: requestId,
        household_id: householdId,
        sender_role: "vendor",
        body: statusLabel,
        metadata: { kind: "status_change", status },
      });
    }
  } catch (auditErr) {
    console.error("[handyman-provider] audit-trail message insert failed", auditErr);
  }

  return { request: updated };
}

// Wave M1 — visit lifecycle handlers.
//
// Four actions cover the on-site beat for a field tech:
//   start_visit   — clock in (records GPS + flips request to in_progress)
//   pause_visit   — open a pause window with a reason (no status flip)
//   resume_visit  — close the open pause and bank the elapsed seconds
//   complete_visit — clock out + flip to completed (audit message + total)
//
// Auth: every action goes through assertWorkspaceAccess() so a tech in
// workspace A cannot stamp clock_in on a visit in workspace B. The visit
// row is loaded by request_id + workspace_id, so a missing/foreign row
// fails the membership check before any write happens.
//
// Pause math: provider_visit_pauses rows store the open pause window;
// resume_visit folds the elapsed seconds into the assignment's
// paused_seconds counter and stamps resumed_at on the pause row. We
// keep the pause table around as the audit trail (one row per pause
// window with reason + actor) and `paused_seconds` as the running
// total the iOS clock subtracts from elapsed for the live counter.

async function loadAssignmentForLifecycle(
  service: ServiceClient,
  workspaceId: string,
  requestId: string,
) {
  const { data: assignment, error } = await service
    .from("provider_visit_assignments")
    .select("*")
    .eq("workspace_id", workspaceId)
    .eq("request_id", requestId)
    .maybeSingle();
  if (error) throw error;
  if (!assignment) {
    throw new Error("No assignment found for this visit. Confirm scheduling first.");
  }
  return assignment;
}

// Wave M1 — convert a raw provider_visit_assignments row (snake_case) to
// the camelCase shape iOS' HavenFieldVisitAssignment expects. Mirrors the
// keys baked into loadDashboard so start/pause/resume/complete responses
// round-trip cleanly through the resilient decoder.
function serializeAssignment(row: Record<string, unknown>): Record<string, unknown> {
  return {
    id: compactString(row.id),
    memberId: compactString(row.assigned_member_id),
    routeDate: compactString(row.route_date),
    windowStartTime: compactString(row.window_start_time),
    windowEndTime: compactString(row.window_end_time),
    stopOrder: numberValue(row.stop_order || 0),
    routeNotes: compactString(row.route_notes),
    clockInAt: row.clock_in_at ?? null,
    clockOutAt: row.clock_out_at ?? null,
    pausedSeconds: numberValue(row.paused_seconds || 0),
    clockInLat: row.clock_in_lat !== null && row.clock_in_lat !== undefined
      ? Number(row.clock_in_lat)
      : null,
    clockInLng: row.clock_in_lng !== null && row.clock_in_lng !== undefined
      ? Number(row.clock_in_lng)
      : null,
    clockInAccuracyM: row.clock_in_accuracy_m !== null && row.clock_in_accuracy_m !== undefined
      ? Number(row.clock_in_accuracy_m)
      : null,
    // Wave M9 — visit edge cases. Co-tech roster + access method/notes
    // round-trip on every assignment-shaped response so the iOS visit
    // detail can render the co-tech avatars + lockbox badge without a
    // separate fetch. Operations Desk reads the same fields.
    coTechMemberIds: Array.isArray(row.co_tech_member_ids)
      ? (row.co_tech_member_ids as unknown[]).map((v) => compactString(v)).filter(Boolean)
      : [],
    accessMethod: compactString(row.access_method) || null,
    accessNotes: compactString(row.access_notes) || null,
  };
}

async function startVisitForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");

  const assignment = await loadAssignmentForLifecycle(service, workspaceId, requestId);

  // Idempotent: if clock_in_at already set, return the existing row
  // instead of double-stamping. Tech may have tapped twice on a slow
  // network. Surfacing the already-recorded value lets the iOS app
  // resume into the running-clock state without confusion.
  if (assignment.clock_in_at) {
    return { assignment: serializeAssignment(assignment) };
  }

  const lat = body.latitude !== null && body.latitude !== undefined && body.latitude !== ""
    ? Number(body.latitude)
    : null;
  const lng = body.longitude !== null && body.longitude !== undefined && body.longitude !== ""
    ? Number(body.longitude)
    : null;
  const accuracyRaw = body.accuracy !== null && body.accuracy !== undefined && body.accuracy !== ""
    ? Number(body.accuracy)
    : null;
  const accuracy = accuracyRaw !== null && Number.isFinite(accuracyRaw)
    ? Math.round(accuracyRaw)
    : null;

  const now = isoNow();
  const updates: Record<string, unknown> = {
    clock_in_at: now,
    updated_at: now,
  };
  if (lat !== null && Number.isFinite(lat)) updates.clock_in_lat = lat;
  if (lng !== null && Number.isFinite(lng)) updates.clock_in_lng = lng;
  if (accuracy !== null) updates.clock_in_accuracy_m = accuracy;

  // Sprint #4 R5-E-8 fix: atomic conditional UPDATE so a rapid
  // double-tap doesn't overwrite clock_in_at twice. The pre-check at
  // line ~3818 (`if (assignment.clock_in_at) return …`) is a stale
  // read; two parallel calls both pass it and both write. With
  // `.is("clock_in_at", null)`, only the first writer commits and the
  // second writer sees zero rows affected — refetch and return the
  // canonical row.
  const { data: updated, error: updateError } = await service
    .from("provider_visit_assignments")
    .update(updates)
    .eq("id", assignment.id)
    .is("clock_in_at", null)
    .select()
    .maybeSingle();
  if (updateError) throw updateError;
  if (!updated) {
    // Another writer beat us. Refetch the assignment and return it.
    const refetched = await loadAssignmentForLifecycle(service, workspaceId, requestId);
    return { assignment: serializeAssignment(refetched) };
  }

  // Flip the request to in_progress when starting fresh — only when the
  // status is in a pre-start phase. Don't downgrade a more advanced
  // status (e.g. quoted, follow_up_recommended).
  try {
    const { data: request } = await service
      .from("handyman_requests")
      .select("id, status, household_id")
      .eq("id", requestId)
      .maybeSingle();
    if (request) {
      const currentStatus = compactString(request.status);
      const startableStatuses = [
        "submitted", "scheduled", "sent_to_handyman", "alternate_dates_proposed",
        "awaiting_homeowner", "confirmed", "on_my_way", "checked_in",
      ];
      if (startableStatuses.includes(currentStatus)) {
        await service
          .from("handyman_requests")
          .update({ status: "in_progress", updated_at: now })
          .eq("id", requestId);
        const householdId = compactString(request.household_id);
        if (householdId) {
          await service.from("handyman_request_messages").insert({
            request_id: requestId,
            household_id: householdId,
            sender_role: "vendor",
            body: "Visit started.",
            metadata: { kind: "status_change", status: "in_progress" },
          });
        }
      }
    }
  } catch (err) {
    console.error("[handyman-provider] start_visit status flip failed", err);
  }

  return { assignment: serializeAssignment(updated) };
}

async function pauseVisitForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");
  const reason = compactString(body.reason);

  const assignment = await loadAssignmentForLifecycle(service, workspaceId, requestId);
  if (!assignment.clock_in_at) {
    throw new Error("Start the visit before pausing.");
  }

  // If a pause is already open, return it instead of opening a second
  // one. Prevents the "user double-tapped Pause" race producing two
  // overlapping pause windows.
  const { data: existingOpen } = await service
    .from("provider_visit_pauses")
    .select("*")
    .eq("assignment_id", assignment.id)
    .is("resumed_at", null)
    .maybeSingle();
  if (existingOpen) {
    return { pause: existingOpen };
  }

  const { data: pause, error } = await service
    .from("provider_visit_pauses")
    .insert({
      workspace_id: workspaceId,
      assignment_id: assignment.id,
      reason: reason || null,
      created_by_user_id: userId || null,
    })
    .select()
    .single();
  if (error || !pause) throw error ?? new Error("Failed to pause visit");

  return { pause };
}

async function resumeVisitForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");

  const assignment = await loadAssignmentForLifecycle(service, workspaceId, requestId);

  // Find the open pause. If there isn't one, return the assignment
  // as-is — caller likely raced a tap.
  const { data: openPause } = await service
    .from("provider_visit_pauses")
    .select("*")
    .eq("assignment_id", assignment.id)
    .is("resumed_at", null)
    .order("paused_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!openPause) {
    return { assignment: serializeAssignment(assignment) };
  }

  const now = isoNow();
  const pausedAtMs = new Date(compactString(openPause.paused_at) || now).getTime();
  const resumedAtMs = new Date(now).getTime();
  const elapsedSec = Math.max(0, Math.round((resumedAtMs - pausedAtMs) / 1000));

  const { error: pauseUpdateError } = await service
    .from("provider_visit_pauses")
    .update({ resumed_at: now })
    .eq("id", openPause.id);
  if (pauseUpdateError) throw pauseUpdateError;

  const newPausedSeconds = numberValue(assignment.paused_seconds || 0) + elapsedSec;
  const { data: updated, error: assignmentUpdateError } = await service
    .from("provider_visit_assignments")
    .update({
      paused_seconds: newPausedSeconds,
      updated_at: now,
    })
    .eq("id", assignment.id)
    .select()
    .single();
  if (assignmentUpdateError || !updated) {
    throw assignmentUpdateError ?? new Error("Failed to resume visit");
  }

  return { assignment: serializeAssignment(updated), addedSeconds: elapsedSec };
}

async function completeVisitForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");

  const assignment = await loadAssignmentForLifecycle(service, workspaceId, requestId);
  const assignmentId = compactString(assignment.id);
  if (!assignmentId) throw new Error("Assignment id missing on lifecycle row.");

  // Sprint #4 R5-E-3 fix (race vs cancel_visit_mid_stream): if the
  // request is already in a terminal state (cancelled), don't try to
  // flip it to completed. Returning the current assignment state is
  // the right idempotent answer — if the user tapped Complete after
  // a concurrent Cancel landed, the cancel won.
  const { data: currentReq } = await service
    .from("handyman_requests")
    .select("status")
    .eq("id", requestId)
    .maybeSingle();
  const currentStatus = compactString(currentReq?.status);
  if (currentStatus === "cancelled") {
    throw new Error("Visit was cancelled by another member; cannot mark complete.");
  }
  if (currentStatus === "completed" && assignment.clock_out_at) {
    // Already completed by a prior tap; idempotent return so the iOS
    // app sees the final state without re-stamping clock_out.
    const startMs = assignment.clock_in_at ? new Date(compactString(assignment.clock_in_at)).getTime() : null;
    const endMs = assignment.clock_out_at ? new Date(compactString(assignment.clock_out_at)).getTime() : null;
    const totalSeconds = startMs && endMs
      ? Math.max(0, Math.round((endMs - startMs) / 1000) - numberValue(assignment.paused_seconds || 0))
      : 0;
    return { assignment: serializeAssignment(assignment), totalSeconds };
  }

  const now = isoNow();

  // C-1 fix (2026-05-08): the original implementation built a partial
  // updates dict (skipping clock_out_at when already set) and then ran
  // updateRequestStatusForProvider AFTER the assignment update. Verifier
  // caught a state where the audit message landed but the canonical row
  // showed clock_out_at = null and request.status = in_progress on the
  // SAME tap. Two independent UPDATE statements + one INSERT, all
  // best-effort, means the audit row could land while either UPDATE was
  // skipped (or, more insidiously, the iOS Sim phantom-tap during
  // sign-out sometimes drove a complete_visit call where the assignment
  // update silently no-op'd). The fix: ALWAYS overwrite clock_out_at on
  // a Complete tap (the user explicitly asked to close the visit; we are
  // not idempotent at the column-value level, only at the "visit is now
  // closed" semantic), THEN re-read the assignment row to confirm the
  // write landed BEFORE running the request-status flip + audit message.
  // If either canonical write fails or doesn't reflect afterwards, throw
  // before the audit message gets inserted so the homeowner thread doesn't
  // tell a story the rest of the system disagrees with.

  // 1. Close any open pause window first so paused_seconds includes the
  //    trailing pause. "I forgot to resume before tapping Complete"
  //    shouldn't mis-credit minutes.
  let bankedPausedSeconds = numberValue(assignment.paused_seconds || 0);
  const { data: openPause } = await service
    .from("provider_visit_pauses")
    .select("*")
    .eq("assignment_id", assignmentId)
    .is("resumed_at", null)
    .maybeSingle();
  if (openPause) {
    const pausedAtMs = new Date(compactString(openPause.paused_at) || now).getTime();
    const resumedAtMs = new Date(now).getTime();
    const elapsedSec = Math.max(0, Math.round((resumedAtMs - pausedAtMs) / 1000));
    const { error: pauseUpdateError } = await service
      .from("provider_visit_pauses")
      .update({ resumed_at: now })
      .eq("id", openPause.id);
    if (pauseUpdateError) throw pauseUpdateError;
    bankedPausedSeconds += elapsedSec;
  }

  // 2. Stamp the FULL desired final state of the assignment row in one
  //    UPDATE. We always set clock_out_at to `now` because the user just
  //    tapped Complete; we want this row reflecting the close even if a
  //    prior tap left it half-stamped. paused_seconds is the canonical
  //    accumulator including the just-closed pause.
  const updates: Record<string, unknown> = {
    clock_out_at: assignment.clock_out_at ?? now,
    paused_seconds: bankedPausedSeconds,
    updated_at: now,
  };

  const { data: updated, error: updateError } = await service
    .from("provider_visit_assignments")
    .update(updates)
    .eq("id", assignmentId)
    .select()
    .single();
  if (updateError || !updated) {
    console.error("[handyman-provider] complete_visit assignment update failed", {
      assignmentId, requestId, workspaceId, error: updateError,
    });
    throw updateError ?? new Error("Failed to stamp clock_out on the visit. Try again.");
  }

  // 3. Verify the canonical write actually reflected. If clock_out_at is
  //    still null after the update lands (the failure mode the verifier
  //    caught), throw before we insert any audit message so the homeowner
  //    thread doesn't tell a story the rest of the system disagrees with.
  if (!updated.clock_out_at) {
    console.error("[handyman-provider] complete_visit clock_out_at still null after update", {
      assignmentId, requestId, workspaceId, returned: updated,
    });
    throw new Error("Visit completion didn't persist. Pull to refresh and try again.");
  }

  // 4. Flip the request to completed via the existing handler so the
  //    status-change audit message + cross-app parity ride along
  //    automatically. Wrapped in try so we can re-read the request to
  //    confirm the flip landed before returning success.
  try {
    await updateRequestStatusForProvider(
      service,
      user,
      { workspaceId, requestId, status: "completed" },
    );
  } catch (err) {
    console.error("[handyman-provider] complete_visit status flip failed", {
      assignmentId, requestId, workspaceId, error: err,
    });
    throw err;
  }

  // 5. Belt-and-braces: re-read the request row and confirm the status
  //    actually flipped. If it didn't, something silent is wrong (RLS
  //    policy change, race with another writer); throw with a specific
  //    message so the iOS app surfaces "Visit completion didn't fully
  //    save" instead of "Visit complete" with a stale status pill.
  const { data: requestAfter } = await service
    .from("handyman_requests")
    .select("id, status")
    .eq("id", requestId)
    .maybeSingle();
  if (!requestAfter || compactString(requestAfter.status) !== "completed") {
    console.error("[handyman-provider] complete_visit request.status didn't flip", {
      assignmentId, requestId, workspaceId, requestAfter,
    });
    throw new Error("Visit closed but request status didn't flip. Pull to refresh and try again.");
  }

  // Compute total time on-site so the iOS app can show the final stat.
  const startMs = updated.clock_in_at ? new Date(compactString(updated.clock_in_at)).getTime() : null;
  const endMs = updated.clock_out_at ? new Date(compactString(updated.clock_out_at)).getTime() : null;
  const totalSeconds = startMs && endMs
    ? Math.max(0, Math.round((endMs - startMs) / 1000) - numberValue(updated.paused_seconds || 0))
    : 0;

  return { assignment: serializeAssignment(updated), totalSeconds };
}

// MARK: - Wave M9 — visit edge cases (co-tech + access method + mid-stream cancel)
//
// Three small actions on top of M1's lifecycle. Each gates on
// assertWorkspaceAccess + verifies the assignment for (workspace, request)
// before mutating. Inserts a structured audit row on
// handyman_request_messages so the operations desk + homeowner thread can
// render the change inline.
//
// add_co_tech              — appends a member id to co_tech_member_ids.
//                            Both members can check off punch items and
//                            their identity is captured per check-off via
//                            the existing punch-item update flow.
// set_access_method        — captures customer_present | lockbox |
//                            key_under_mat | door_code + free-form notes.
// cancel_visit_mid_stream  — closes any open pause window, stamps
//                            handyman_requests.status='cancelled' +
//                            cancellation_reason + cancelled_at +
//                            cancelled_by_member_id, and optionally
//                            scheduled a placeholder follow-up visit.

const M9_ACCESS_METHODS = new Set([
  "customer_present",
  "lockbox",
  "key_under_mat",
  "door_code",
]);

const M9_CANCEL_REASONS = new Set([
  "weather",
  "customer_cancelled",
  "tech_emergency",
  "other",
]);

async function addCoTechForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  const memberId = compactString(body.memberId);
  if (!requestId) throw new Error("requestId is required");
  if (!memberId) throw new Error("memberId is required");

  // The candidate member must also belong to the same workspace. Stops a
  // tech from accidentally adding a member from a different workspace
  // (the autocomplete on the iOS side already filters, this is the
  // server-side belt-and-suspenders).
  const { data: memberRow, error: memberLookupErr } = await service
    .from("provider_workspace_members")
    .select("id, workspace_id, status, full_name, email")
    .eq("id", memberId)
    .maybeSingle();
  if (memberLookupErr) throw memberLookupErr;
  if (!memberRow) throw new Error("Co-tech member not found");
  if (compactString(memberRow.workspace_id) !== workspaceId) {
    throw new Error("Co-tech member is not in this workspace");
  }
  if (compactString(memberRow.status) !== "active") {
    throw new Error("Co-tech member is not active");
  }

  const assignment = await loadAssignmentForLifecycle(service, workspaceId, requestId);

  // Don't add the primary tech as a co-tech of themselves.
  if (compactString(assignment.assigned_member_id) === memberId) {
    throw new Error("This member is already the primary tech on the visit.");
  }

  const existing = Array.isArray(assignment.co_tech_member_ids)
    ? (assignment.co_tech_member_ids as unknown[]).map((v) => compactString(v)).filter(Boolean)
    : [];
  // Idempotent — if the member is already a co-tech, return the row as-is.
  if (existing.includes(memberId)) {
    return { assignment: serializeAssignment(assignment) };
  }

  const updatedList = [...existing, memberId];
  const now = isoNow();

  const { data: updated, error: updateError } = await service
    .from("provider_visit_assignments")
    .update({
      co_tech_member_ids: updatedList,
      updated_at: now,
    })
    .eq("id", assignment.id)
    .select()
    .single();
  if (updateError || !updated) throw updateError ?? new Error("Failed to add co-tech");

  // Audit-trail message. Workspace-internal context only (sender_role
  // 'vendor' so the homeowner sees a benign "We added another tech"
  // line in their thread; metadata.kind='co_tech_added' lets the
  // Operations Desk render a structured chip if it wants).
  const householdId = compactString((assignment as Record<string, unknown>).household_id) ||
    await loadHouseholdIdForRequest(service, requestId);
  if (householdId) {
    const memberLabel = compactString(memberRow.full_name) ||
      compactString(memberRow.email) ||
      "another tech";
    try {
      await service.from("handyman_request_messages").insert({
        request_id: requestId,
        household_id: householdId,
        sender_role: "vendor",
        body: `We added ${memberLabel} as a co-tech on this visit.`,
        metadata: { kind: "co_tech_added", member_id: memberId },
      });
    } catch (err) {
      console.error("[handyman-provider] add_co_tech audit-message failed", err);
    }
  }

  return { assignment: serializeAssignment(updated) };
}

async function setAccessMethodForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");

  const method = compactString(body.method);
  if (!method) throw new Error("method is required");
  if (!M9_ACCESS_METHODS.has(method)) {
    throw new Error(`Unsupported access method: ${method}`);
  }

  const notes = compactString(body.notes) || null;

  const assignment = await loadAssignmentForLifecycle(service, workspaceId, requestId);
  const now = isoNow();

  const { data: updated, error: updateError } = await service
    .from("provider_visit_assignments")
    .update({
      access_method: method,
      access_notes: notes,
      updated_at: now,
    })
    .eq("id", assignment.id)
    .select()
    .single();
  if (updateError || !updated) throw updateError ?? new Error("Failed to save access method");

  return { assignment: serializeAssignment(updated) };
}

async function cancelVisitMidStreamForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");

  const reasonRaw = compactString(body.reason);
  if (!reasonRaw) throw new Error("reason is required");
  // Allow free-form 'other' text by accepting any reason that starts
  // with one of the canonical keywords, plus accept any reason if it
  // matches the canonical set. This is intentionally permissive so a
  // human-typed reason ("Customer not home, neighbor said they left")
  // round-trips even though it's not on the canonical list.
  const canonicalReason = M9_CANCEL_REASONS.has(reasonRaw) ? reasonRaw : "other";
  const reasonForRecord = reasonRaw;

  const partialState = (body.partialState ?? null) as Record<string, unknown> | null;
  const scheduleFollowup = partialState && partialState.scheduleFollowup === true;

  const memberId = compactString(membership.id) || null;

  const { data: requestRow, error: requestErr } = await service
    .from("handyman_requests")
    .select("id, household_id, status, contractor_id, property_id")
    .eq("id", requestId)
    .maybeSingle();
  if (requestErr) throw requestErr;
  if (!requestRow) throw new Error("Request not found");
  const householdId = compactString(requestRow.household_id);

  // Sprint #4 R5-E-12B BLOCKER: cross-workspace guard.
  await assertRequestInWorkspace(service, requestId, workspaceId);

  // Idempotent — if already in a terminal state (cancelled OR completed),
  // just return the existing state. This is a fast-path check; the
  // atomic UPDATE+RETURNING below is the canonical race guard.
  if (compactString(requestRow.status) === "cancelled" ||
      compactString(requestRow.status) === "completed") {
    return {
      request: {
        id: compactString(requestRow.id),
        status: compactString(requestRow.status),
        cancellationReason: null,
        cancelledAt: null,
        cancelledByMemberId: null,
      },
      followupRequestId: null,
    };
  }

  const assignment = await loadAssignmentForLifecycle(service, workspaceId, requestId);
  const now = isoNow();

  // 1. Close any open pause so paused_seconds banks correctly. Don't
  //    auto-clock-out — cancellation is distinct from completion and we
  //    want to leave clock_out_at null so the homeowner thread reads
  //    "cancelled at 10:42" rather than "completed at 10:42".
  if (assignment.clock_in_at) {
    const { data: openPause } = await service
      .from("provider_visit_pauses")
      .select("*")
      .eq("assignment_id", assignment.id)
      .is("resumed_at", null)
      .maybeSingle();
    if (openPause) {
      const pausedAtMs = new Date(compactString(openPause.paused_at) || now).getTime();
      const resumedAtMs = new Date(now).getTime();
      const elapsedSec = Math.max(0, Math.round((resumedAtMs - pausedAtMs) / 1000));
      await service
        .from("provider_visit_pauses")
        .update({ resumed_at: now })
        .eq("id", openPause.id);
      const newPausedSeconds = numberValue(assignment.paused_seconds || 0) + elapsedSec;
      await service
        .from("provider_visit_assignments")
        .update({ paused_seconds: newPausedSeconds, updated_at: now })
        .eq("id", assignment.id);
    }
  }

  // 2. Sprint #4 R5-E-3 + R5-E-7 fix: atomic UPDATE with status guard.
  //    The previous implementation read status, then if-not-cancelled
  //    wrote — a stale-read race window where two concurrent cancels
  //    (or a cancel+complete pair) both passed the read check and both
  //    wrote, producing duplicate audit messages and mixed columns.
  //    Now: filter the UPDATE on `status NOT IN ('cancelled', 'completed')`
  //    + RETURNING. If 0 rows came back, another writer already won
  //    the terminal-state race; return the current state and skip the
  //    audit-message insert so the homeowner thread doesn't show two
  //    contradictory explanations.
  const { data: cancelUpdated, error: cancelErr } = await service
    .from("handyman_requests")
    .update({
      status: "cancelled",
      cancellation_reason: reasonForRecord,
      cancelled_at: now,
      cancelled_by_member_id: memberId,
      cancelled_by_user_id: userId || null,
      cancelled_by_role: "handyman",
      proposal_status: "cancelled",
      updated_at: now,
    })
    .eq("id", requestId)
    .not("status", "in", '("cancelled","completed")')
    .select("id, status")
    .maybeSingle();
  if (cancelErr) throw cancelErr;
  if (!cancelUpdated) {
    // Another concurrent caller already moved the visit to a terminal
    // state. Re-read the canonical row and return it; do NOT insert
    // duplicate audit messages or schedule a follow-up against a visit
    // that's already closed.
    const { data: finalRow } = await service
      .from("handyman_requests")
      .select("id, status, cancellation_reason, cancelled_at, cancelled_by_member_id")
      .eq("id", requestId)
      .maybeSingle();
    return {
      request: {
        id: compactString(finalRow?.id) || requestId,
        status: compactString(finalRow?.status) || "cancelled",
        cancellationReason: compactString(finalRow?.cancellation_reason) || null,
        cancelledAt: finalRow?.cancelled_at ?? null,
        cancelledByMemberId: compactString(finalRow?.cancelled_by_member_id) || null,
      },
      followupRequestId: null,
    };
  }

  // 3. Audit-trail message on the homeowner thread. 'haven' role so the
  //    thread renderer treats it as informational, not "the contractor
  //    typed this".
  if (householdId) {
    try {
      await service.from("handyman_request_messages").insert({
        request_id: requestId,
        household_id: householdId,
        sender_role: "haven",
        body: `Visit cancelled mid-stream. Reason: ${reasonForRecord}.`,
        metadata: {
          kind: "visit_cancelled",
          reason: canonicalReason,
          reason_text: reasonForRecord,
          schedule_followup: scheduleFollowup,
        },
      });
    } catch (err) {
      console.error("[handyman-provider] cancel_visit_mid_stream audit-message failed", err);
    }
  }

  // 4. Optionally create a placeholder follow-up request stamped against
  //    the same household + property + contractor. Pre-stamps an
  //    assignment for the same tech so dispatch can confirm the slot.
  let followupRequestId: string | null = null;
  if (scheduleFollowup && householdId) {
    const followupTitle = compactString(partialState?.followupTitle) || "Follow-up visit (rescheduled after mid-stream cancel)";
    const proposedDate = compactString(partialState?.proposedDate) || null;
    const durationMinutes = Math.max(15, numberValue(partialState?.durationMinutes ?? 60));
    const contractorId = compactString(requestRow.contractor_id) || null;
    const propertyId = compactString(requestRow.property_id) || null;

    try {
      const { data: newRequest, error: insertErr } = await service
        .from("handyman_requests")
        .insert({
          household_id: householdId,
          property_id: propertyId,
          contractor_id: contractorId,
          request_type: "standard_visit",
          source: "vendor",
          title: followupTitle,
          status: proposedDate ? "scheduled" : "submitted",
          preferred_timing: proposedDate,
          proposed_visit_at: proposedDate,
          proposed_by_role: "handyman",
          proposed_at: proposedDate ? now : null,
          proposal_status: proposedDate ? "none" : "pending",
          parent_request_id: requestId,
          suggested_by_request_id: requestId,
          suggested_at: now,
        })
        .select("id, title")
        .single();
      if (insertErr || !newRequest) throw insertErr ?? new Error("Failed to create follow-up");

      followupRequestId = compactString(newRequest.id);

      // Pre-stamp an assignment for the same tech (matches M8's pattern).
      if (memberId && proposedDate) {
        const routeDate = proposedDate.length >= 10 ? proposedDate.slice(0, 10) : null;
        let nextStopOrder = 1;
        if (routeDate) {
          const { data: existingStops } = await service
            .from("provider_visit_assignments")
            .select("stop_order")
            .eq("workspace_id", workspaceId)
            .eq("assigned_member_id", memberId)
            .eq("route_date", routeDate)
            .order("stop_order", { ascending: false })
            .limit(1)
            .maybeSingle();
          const maxOrder = numberValue(existingStops?.stop_order || 0);
          if (maxOrder >= 1) nextStopOrder = maxOrder + 1;
        }
        await service
          .from("provider_visit_assignments")
          .insert({
            workspace_id: workspaceId,
            request_id: followupRequestId,
            assigned_member_id: memberId,
            assigned_by_user_id: userId,
            route_date: routeDate,
            stop_order: nextStopOrder,
          });
      }

      // Audit-trail message on the original thread linking to the new
      // request so the homeowner sees the pivot.
      try {
        await service.from("handyman_request_messages").insert({
          request_id: requestId,
          household_id: householdId,
          sender_role: "haven",
          body: proposedDate
            ? `We've scheduled a follow-up visit on ${formatHumanDateForSuggestion(proposedDate)}.`
            : `We've created a placeholder follow-up so we can pick this up again.`,
          metadata: {
            kind: "followup_visit_after_cancel",
            request_id: followupRequestId,
            proposed_date: proposedDate,
            duration_minutes: durationMinutes,
          },
        });
      } catch (err) {
        console.error("[handyman-provider] cancel followup audit-message failed", err);
      }
    } catch (err) {
      console.error("[handyman-provider] cancel_visit_mid_stream followup insert failed", err);
      // Don't fail the whole call — the cancel itself landed.
    }
  }

  return {
    request: {
      id: requestId,
      status: "cancelled",
      cancellationReason: reasonForRecord,
      cancelledAt: now,
      cancelledByMemberId: memberId,
    },
    followupRequestId,
  };
}

// Small helper — load the household_id for a request so audit-trail
// inserts can land. Avoids a redundant select when callers already have
// the request row in hand.
async function loadHouseholdIdForRequest(
  service: ServiceClient,
  requestId: string,
): Promise<string | null> {
  const { data: row } = await service
    .from("handyman_requests")
    .select("household_id")
    .eq("id", requestId)
    .maybeSingle();
  return compactString(row?.household_id) || null;
}

// MARK: - Wave M8 — end-of-visit suggestion authoring
//
// Three light-touch artifact creators. Each gates on
// assertWorkspaceAccess + verifies the originating handyman_requests
// row belongs to the caller's workspace, then creates a downstream row
// (maintenance_tasks / provider_quotes / handyman_requests) tagged
// with `suggested_by_request_id` so the homeowner-side surfaces (and
// the Operations Desk Quotes / Dispatch screens) can render the
// "Suggested by visit" badge.
//
// Distinct from `propose_homeowner_task` / `propose_followup_visit`
// which carry the full proposal/expiration/approval ceremony — these
// are tech-driven recommendations the homeowner reads, not pending
// approvals that block the homeowner's queue.

interface VisitContextForSuggestion {
  requestId: string;
  householdId: string;
  propertyId: string | null;
  workspaceId: string;
}

async function loadVisitContextForSuggestion(
  service: ServiceClient,
  workspaceId: string,
  requestId: string,
): Promise<VisitContextForSuggestion> {
  if (!requestId) throw new Error("requestId is required");

  // Make sure the assignment exists for this workspace + request — same
  // gate the lifecycle helpers use, prevents a tech from another
  // workspace seeding artifacts onto an unrelated request.
  await loadAssignmentForLifecycle(service, workspaceId, requestId);

  const { data: req, error } = await service
    .from("handyman_requests")
    .select("id, household_id, property_id")
    .eq("id", requestId)
    .maybeSingle();
  if (error) throw error;
  if (!req) throw new Error("Originating request not found");

  return {
    requestId: compactString(req.id),
    householdId: compactString(req.household_id),
    propertyId: compactString(req.property_id) || null,
    workspaceId,
  };
}

async function suggestFollowupTask(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const ctx = await loadVisitContextForSuggestion(
    service,
    workspaceId,
    compactString(body.requestId),
  );

  const title = compactString(body.title);
  if (!title) throw new Error("title is required");
  if (title.length > 200) throw new Error("title is too long (max 200 chars)");

  const description = compactString(body.description) || null;
  // dueDate is an optional ISO date string ("2026-08-15"). The
  // maintenance_tasks.next_due_date column is NOT NULL, so when the
  // tech doesn't pick a specific date we default to 30 days out — far
  // enough to feel "soon" without forcing a deadline that misleads the
  // homeowner into thinking the contractor scheduled it.
  const explicitDueDate = compactString(body.dueDate);
  const dueDate = explicitDueDate || (() => {
    const d = new Date();
    d.setUTCDate(d.getUTCDate() + 30);
    return d.toISOString().slice(0, 10);
  })();
  // Default the property scope to the visit's property so the row
  // surfaces on the right home in the homeowner's task surfaces.
  const propertyId = compactString(body.propertyId) || ctx.propertyId;
  const householdId = compactString(body.householdId) || ctx.householdId;

  const now = isoNow();

  // Sprint #4 R5-E-10 fix: rapid double-tap dedup. iOS button debounce
  // doesn't catch a 22ms repeat tap, and the homeowner sees two
  // identical "We suggested a follow-up task" messages + two duplicate
  // tasks. Look for a recent identical insert in the last 5 minutes
  // before writing; if one exists, return its id idempotently.
  const dedupWindowStartIso = new Date(Date.now() - 5 * 60 * 1000).toISOString();
  const { data: recentDup } = await service
    .from("maintenance_tasks")
    .select("id, title")
    .eq("suggested_by_request_id", ctx.requestId)
    .eq("title", title)
    .gte("suggested_at", dedupWindowStartIso)
    .order("suggested_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (recentDup) {
    return { ok: true, taskId: compactString(recentDup.id), deduped: true };
  }

  const { data: inserted, error: insertErr } = await service
    .from("maintenance_tasks")
    .insert({
      household_id: householdId,
      property_id: propertyId,
      title,
      description,
      frequency: "Once",
      next_due_date: dueDate,
      priority: "medium",
      assignment_type: "either",
      source: "contractor_suggestion",
      suggested_by_request_id: ctx.requestId,
      suggested_by_workspace_id: workspaceId,
      suggested_at: now,
    })
    .select("id, title")
    .single();
  if (insertErr) {
    // Sprint #4 R5-E-10: handle race-loser case from the unique partial
    // index uq_maintenance_tasks_suggestion_dedup (Postgres error code
    // 23505 = unique_violation). When a truly-concurrent caller's INSERT
    // gets rejected by the DB, refetch the winning row and return its
    // id idempotently rather than surfacing the constraint error.
    if ((insertErr as { code?: string }).code === "23505") {
      const { data: winner } = await service
        .from("maintenance_tasks")
        .select("id, title")
        .eq("suggested_by_request_id", ctx.requestId)
        .eq("title", title)
        .order("suggested_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (winner) {
        return { ok: true, taskId: compactString(winner.id), deduped: true };
      }
    }
    throw insertErr;
  }

  const taskId = compactString(inserted.id);

  // Audit-trail message on the request thread so the homeowner sees the
  // suggestion in context. metadata.kind = 'task_suggested' lets the
  // thread renderer pick a distinct treatment.
  await mirrorQuoteMessageToRequestThread(service, {
    requestId: ctx.requestId,
    householdId: ctx.householdId,
    senderRole: "vendor",
    body: `We suggested a follow-up task: ${title}`,
    metadata: {
      kind: "task_suggested",
      task_id: taskId,
      task_title: title,
      due_date: explicitDueDate || null,
    },
  });

  await notifyHomeownersForRequest(service, ctx.householdId, {
    title: "New follow-up suggested",
    body: title.length > 80 ? title.slice(0, 77) + "…" : title,
    requestId: ctx.requestId,
    eventType: "handyman_task_suggested",
    extra: { task_id: taskId, suggestion_kind: "task" },
  });

  return { ok: true, taskId };
}

async function suggestFollowupQuote(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const ctx = await loadVisitContextForSuggestion(
    service,
    workspaceId,
    compactString(body.requestId),
  );

  const title = compactString(body.title) || "Follow-up quote";
  const scopeNotes = compactString(body.scopeNotes) || null;
  const propertyId = compactString(body.propertyId) || ctx.propertyId;
  const householdId = compactString(body.householdId) || ctx.householdId;

  // Pull the contractor_id from the originating request — that's the
  // canonical workspace ↔ household contractor relationship and matches
  // what every other workspace-driven quote write uses (M4's
  // build_quote_from_visit, save_quote, send_quote all walk this same
  // edge from request → contractor).
  const { data: parentReq } = await service
    .from("handyman_requests")
    .select("contractor_id")
    .eq("id", ctx.requestId)
    .maybeSingle();
  const contractorId = compactString(parentReq?.contractor_id) || null;

  const now = isoNow();

  // Sprint #4 R5-E-10 fix: rapid double-tap dedup for follow-up quote
  // drafts. Same pattern as suggestFollowupTask — 5-minute window on
  // (request_id, title) returns the existing draft id rather than
  // inserting a second draft the user never asked for.
  const dedupWindowStartIso = new Date(Date.now() - 5 * 60 * 1000).toISOString();
  const { data: recentDup } = await service
    .from("provider_quotes")
    .select("id, title")
    .eq("workspace_id", workspaceId)
    .eq("suggested_by_request_id", ctx.requestId)
    .eq("title", title)
    .eq("status", "draft")
    .gte("suggested_at", dedupWindowStartIso)
    .order("suggested_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (recentDup) {
    return { ok: true, quoteId: compactString(recentDup.id), title: compactString(recentDup.title), deduped: true };
  }

  // public_share_token is NOT NULL on provider_quotes (the prospect
  // share link is keyed off it). crypto.randomUUID() in Deno is the
  // standard token source — matches save_quote's behavior, which lets
  // Postgres' default fill it in for us. We assign explicitly because
  // some Postgres environments don't provision a default for the column
  // until the first save_quote write hydrates it.
  const publicShareToken = crypto.randomUUID();

  const { data: inserted, error: insertErr } = await service
    .from("provider_quotes")
    .insert({
      workspace_id: workspaceId,
      contractor_id: contractorId,
      household_id: householdId,
      property_id: propertyId,
      request_id: ctx.requestId,
      title,
      status: "draft",
      currency: "USD",
      line_items: [],
      scope_notes: scopeNotes,
      subtotal: 0,
      tax_total: 0,
      total: 0,
      created_by_user_id: userId,
      updated_by_user_id: userId,
      recipient_kind: "linked_home",
      public_share_token: publicShareToken,
      suggested_by_request_id: ctx.requestId,
      suggested_at: now,
    })
    .select("id, title")
    .single();
  if (insertErr) {
    // Sprint #4 R5-E-10: race-loser case from uq_provider_quotes_suggestion_dedup.
    if ((insertErr as { code?: string }).code === "23505") {
      const { data: winner } = await service
        .from("provider_quotes")
        .select("id, title")
        .eq("workspace_id", workspaceId)
        .eq("suggested_by_request_id", ctx.requestId)
        .eq("title", title)
        .eq("status", "draft")
        .order("suggested_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (winner) {
        return { ok: true, quoteId: compactString(winner.id), title: compactString(winner.title), deduped: true };
      }
    }
    throw insertErr;
  }

  const quoteId = compactString(inserted.id);

  // Don't push the homeowner thread yet — the quote is still a draft.
  // The tech finishes building it inside M4's quote builder and the
  // existing send_quote flow handles the customer-visible message.

  return { ok: true, quoteId, title };
}

async function scheduleFollowupVisit(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);

  const ctx = await loadVisitContextForSuggestion(
    service,
    workspaceId,
    compactString(body.requestId),
  );

  const proposedDate = compactString(body.proposedDate);
  if (!proposedDate) throw new Error("proposedDate is required");
  const durationMinutes = Math.max(15, numberValue(body.durationMinutes ?? 60));
  const titleOverride = compactString(body.title) || "Follow-up visit";
  const details = compactString(body.details) || null;

  // Pull the parent request's contractor_id so the new row stays on
  // the same vendor relationship.
  const { data: parent } = await service
    .from("handyman_requests")
    .select("contractor_id")
    .eq("id", ctx.requestId)
    .maybeSingle();
  const contractorId = compactString(parent?.contractor_id) || null;

  const now = isoNow();

  // Sprint #4 R5-E-10 fix: rapid double-tap dedup for follow-up visit
  // requests. 5-minute window on (parent_request_id, title, proposed_date)
  // returns the existing follow-up id idempotently rather than scheduling
  // two visits the user never asked for.
  const dedupWindowStartIso = new Date(Date.now() - 5 * 60 * 1000).toISOString();
  const { data: recentDup } = await service
    .from("handyman_requests")
    .select("id, title")
    .eq("parent_request_id", ctx.requestId)
    .eq("title", titleOverride)
    .eq("proposed_visit_at", proposedDate)
    .gte("suggested_at", dedupWindowStartIso)
    .order("suggested_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (recentDup) {
    return {
      ok: true,
      requestId: compactString(recentDup.id),
      title: compactString(recentDup.title),
      assignmentId: null,
      deduped: true,
    };
  }

  const { data: newRequest, error: insertErr } = await service
    .from("handyman_requests")
    .insert({
      household_id: ctx.householdId,
      property_id: ctx.propertyId,
      contractor_id: contractorId,
      request_type: "standard_visit",
      source: "vendor",
      title: titleOverride,
      details,
      status: "scheduled",
      preferred_timing: proposedDate,
      proposed_visit_at: proposedDate,
      proposed_by_role: "handyman",
      proposed_at: now,
      proposal_status: "none",
      parent_request_id: ctx.requestId,
      suggested_by_request_id: ctx.requestId,
      suggested_at: now,
    })
    .select("id, title")
    .single();
  if (insertErr) {
    // Sprint #4 R5-E-10: race-loser case from uq_handyman_requests_followup_dedup.
    if ((insertErr as { code?: string }).code === "23505") {
      const { data: winner } = await service
        .from("handyman_requests")
        .select("id, title")
        .eq("parent_request_id", ctx.requestId)
        .eq("title", titleOverride)
        .eq("proposed_visit_at", proposedDate)
        .order("suggested_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (winner) {
        return {
          ok: true,
          requestId: compactString(winner.id),
          title: compactString(winner.title),
          assignmentId: null,
          deduped: true,
        };
      }
    }
    throw insertErr;
  }

  const newRequestId = compactString(newRequest.id);

  // Pre-stamp a provider_visit_assignments row so the new request lands
  // back on the same tech's calendar (the most natural assignee — the
  // tech who suggested the follow-up usually wants to do the work).
  const memberId = compactString(membership.id);
  let assignmentId: string | null = null;
  if (memberId) {
    const routeDate = proposedDate.length >= 10 ? proposedDate.slice(0, 10) : null;
    // stop_order has a > 0 CHECK constraint. Compute the next free slot
    // for this tech on this date so the new visit lands at the end of
    // their day. Falls back to 1 when there are no other stops yet.
    let nextStopOrder = 1;
    if (routeDate) {
      const { data: existingStops } = await service
        .from("provider_visit_assignments")
        .select("stop_order")
        .eq("workspace_id", workspaceId)
        .eq("assigned_member_id", memberId)
        .eq("route_date", routeDate)
        .order("stop_order", { ascending: false })
        .limit(1)
        .maybeSingle();
      const maxOrder = numberValue(existingStops?.stop_order || 0);
      if (maxOrder >= 1) nextStopOrder = maxOrder + 1;
    }

    const { data: assignmentRow, error: assignmentErr } = await service
      .from("provider_visit_assignments")
      .insert({
        workspace_id: workspaceId,
        request_id: newRequestId,
        assigned_member_id: memberId,
        assigned_by_user_id: userId,
        route_date: routeDate,
        stop_order: nextStopOrder,
      })
      .select("id")
      .single();
    if (assignmentErr) {
      // Don't fail the whole call — the request landed, the homeowner
      // sees it, and dispatch can manually assign later. But surface the
      // failure so the operator can see why the calendar slot is empty.
      console.error("[handyman-provider:schedule_followup_visit] assignment insert failed", assignmentErr);
    } else {
      assignmentId = compactString(assignmentRow?.id);
    }
  }

  // Post a system audit message on the parent thread so the homeowner
  // sees the visit suggestion in the same conversation. Use 'haven' role
  // for the system bubble so the thread renderer treats it as
  // informational, not "the contractor said this".
  await mirrorQuoteMessageToRequestThread(service, {
    requestId: ctx.requestId,
    householdId: ctx.householdId,
    senderRole: "haven",
    body: `We scheduled a follow-up visit on ${formatHumanDateForSuggestion(proposedDate)}.`,
    metadata: {
      kind: "followup_visit_scheduled",
      request_id: newRequestId,
      proposed_date: proposedDate,
      duration_minutes: durationMinutes,
    },
  });

  await notifyHomeownersForRequest(service, ctx.householdId, {
    title: "Follow-up visit scheduled",
    body: `${titleOverride} on ${formatHumanDateForSuggestion(proposedDate)}.`,
    requestId: newRequestId,
    eventType: "handyman_visit_suggested",
    extra: { followup_request_id: newRequestId, suggestion_kind: "visit" },
  });

  return { ok: true, requestId: newRequestId, title: titleOverride, assignmentId };
}

function formatHumanDateForSuggestion(iso: string): string {
  // Render a server-side ISO timestamp as "Wed, Aug 15 at 9:00 AM" for
  // the audit-trail message body. Falls back to the raw string on parse
  // failure so we never null-insert into the message body.
  try {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return iso;
    const dateFmt = new Intl.DateTimeFormat("en-US", {
      weekday: "short",
      month: "short",
      day: "numeric",
    });
    const timeFmt = new Intl.DateTimeFormat("en-US", {
      hour: "numeric",
      minute: "2-digit",
    });
    return `${dateFmt.format(d)} at ${timeFmt.format(d)}`;
  } catch {
    return iso;
  }
}

// MARK: - Wave M11 — End-of-day summary + day completion
//
// Aggregates today's stops + clock totals + materials + invoiced revenue +
// a tomorrow preview. Reads M1's clock_in_at / clock_out_at / paused_seconds
// off provider_visit_assignments and falls back to 0 cleanly if any layer
// (M5 invoices, attachments, materials) hasn't shipped yet. The iOS app
// renders this as the "Day complete" hero on the Today tab once the last
// stop's clock_out_at lands.

const FIELD_DEFAULT_TIMEZONE = "America/New_York";

function fieldFormatYmdInZone(date: Date, timeZone: string): string {
  // Intl gives us locale-formatted parts in the workspace tz; we reassemble
  // YYYY-MM-DD so the comparison against route_date (DATE column, no tz)
  // matches calendar day in the operator's frame, not UTC.
  try {
    const fmt = new Intl.DateTimeFormat("en-CA", {
      timeZone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
    const parts = fmt.formatToParts(date);
    const y = parts.find((p) => p.type === "year")?.value ?? "1970";
    const m = parts.find((p) => p.type === "month")?.value ?? "01";
    const d = parts.find((p) => p.type === "day")?.value ?? "01";
    return `${y}-${m}-${d}`;
  } catch {
    // Fallback to naive UTC if timezone string is invalid
    return date.toISOString().slice(0, 10);
  }
}

function fieldAddDaysYmd(ymd: string, days: number): string {
  // ymd is YYYY-MM-DD; treat as UTC for the +1d math then re-emit.
  // Day arithmetic across DST is fine because we're only adding integer
  // days and never asking for an hour-of-day.
  const [y, m, d] = ymd.split("-").map((s) => Number(s));
  if (!y || !m || !d) return ymd;
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() + days);
  const yy = dt.getUTCFullYear();
  const mm = String(dt.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(dt.getUTCDate()).padStart(2, "0");
  return `${yy}-${mm}-${dd}`;
}

async function todaySummaryForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const userId = compactString(user.id);
  if (!userId) throw new Error("Unauthenticated");

  // Resolve workspace: prefer the body's workspaceId (so multi-workspace
  // users hit the one they're viewing), fall back to the caller's first
  // active membership when omitted (sole-mode default).
  let workspaceId = compactString(body.workspaceId);
  if (workspaceId) {
    await assertWorkspaceAccess(service, userId, workspaceId);
  } else {
    const m = await getWorkspaceMembership(service, userId);
    if (!m) throw new Error("No provider workspace found");
    const ws = (m as Record<string, unknown>).provider_workspaces as
      | Record<string, unknown>
      | undefined;
    workspaceId = compactString(ws?.id);
    if (!workspaceId) throw new Error("Workspace id missing on membership row.");
  }

  // Workspace timezone: provider_workspaces has no tz column today, so
  // we default to America/New_York. If the workspace has at least one
  // linked household with a primary property carrying time_zone, prefer
  // that. Soft fallback — bad lookups never block the summary.
  let timeZone = FIELD_DEFAULT_TIMEZONE;
  try {
    const { data: linkRow } = await service
      .from("provider_contractor_links")
      .select("contractor_id")
      .eq("workspace_id", workspaceId)
      .limit(1)
      .maybeSingle();
    const contractorId = compactString(linkRow?.contractor_id);
    if (contractorId) {
      const { data: contractor } = await service
        .from("contractors")
        .select("household_id")
        .eq("id", contractorId)
        .maybeSingle();
      const householdId = compactString(contractor?.household_id);
      if (householdId) {
        const { data: prop } = await service
          .from("properties")
          .select("time_zone")
          .eq("household_id", householdId)
          .order("created_at", { ascending: true })
          .limit(1)
          .maybeSingle();
        const propTz = compactString(prop?.time_zone);
        if (propTz) timeZone = propTz;
      }
    }
  } catch (err) {
    console.error("[handyman-provider] today_summary tz lookup failed", err);
  }

  const now = new Date();
  const todayYmd = fieldFormatYmdInZone(now, timeZone);
  const tomorrowYmd = fieldAddDaysYmd(todayYmd, 1);

  // Pull all assignments scheduled for today. We filter completed vs
  // remaining in JS off clock_out_at (M1's lifecycle column).
  const { data: todayAssignmentsRaw, error: todayErr } = await service
    .from("provider_visit_assignments")
    .select(
      "id, request_id, route_date, window_start_time, stop_order, clock_in_at, clock_out_at, paused_seconds",
    )
    .eq("workspace_id", workspaceId)
    .eq("route_date", todayYmd)
    .order("stop_order", { ascending: true });
  if (todayErr) throw todayErr;
  const todayAssignments = (todayAssignmentsRaw ?? []) as Array<Record<string, unknown>>;

  // Stops completed today vs remaining
  const completedAssignments = todayAssignments.filter(
    (a) => !!compactString(a.clock_out_at),
  );
  const remainingAssignments = todayAssignments.filter(
    (a) => !compactString(a.clock_out_at),
  );

  // Total clock minutes across today's completed assignments. For each
  // assignment with both clock_in_at + clock_out_at, total = (out - in) -
  // paused_seconds. Round to whole minutes; rounding errors of ±1 minute
  // per stop are well within the precision the field tech actually cares
  // about.
  let totalClockSeconds = 0;
  for (const a of completedAssignments) {
    const inAt = compactString(a.clock_in_at);
    const outAt = compactString(a.clock_out_at);
    if (!inAt || !outAt) continue;
    const inMs = new Date(inAt).getTime();
    const outMs = new Date(outAt).getTime();
    if (!Number.isFinite(inMs) || !Number.isFinite(outMs) || outMs <= inMs) continue;
    const elapsed = Math.max(0, Math.round((outMs - inMs) / 1000) - numberValue(a.paused_seconds || 0));
    totalClockSeconds += elapsed;
  }
  const totalClockMinutes = Math.round(totalClockSeconds / 60);

  // Resolve today's request rows for customer + address. One round-trip
  // for every today_request_id, then index for the per-stop loop.
  const todayRequestIds = todayAssignments
    .map((a) => compactString(a.request_id))
    .filter((id) => !!id);
  const requestById = new Map<string, Record<string, unknown>>();
  if (todayRequestIds.length > 0) {
    const { data: requestRows, error: requestErr } = await service
      .from("handyman_requests")
      .select("id, title, household_id, property_id, visit_task_id, contractor_id")
      .in("id", todayRequestIds);
    if (requestErr) throw requestErr;
    for (const r of (requestRows ?? []) as Array<Record<string, unknown>>) {
      const id = compactString(r.id);
      if (id) requestById.set(id, r);
    }
  }

  // Resolve property rows for address line on each stop
  const todayPropertyIds = Array.from(requestById.values())
    .map((r) => compactString(r.property_id))
    .filter((id) => !!id);
  const propertyById = new Map<string, Record<string, unknown>>();
  if (todayPropertyIds.length > 0) {
    const { data: propRows } = await service
      .from("properties")
      .select("id, address, household_id")
      .in("id", todayPropertyIds);
    for (const p of (propRows ?? []) as Array<Record<string, unknown>>) {
      const id = compactString(p.id);
      if (id) propertyById.set(id, p);
    }
  }

  // Resolve household → primary user name for customer label. Lazy lookup
  // per household so we don't blow N+1 queries when the same household has
  // multiple stops on the same day.
  const todayHouseholdIds = new Set<string>();
  for (const r of requestById.values()) {
    const hid = compactString(r.household_id);
    if (hid) todayHouseholdIds.add(hid);
  }
  const customerByHousehold = new Map<string, string>();
  if (todayHouseholdIds.size > 0) {
    const { data: userRows } = await service
      .from("users")
      .select("household_id, first_name, last_name, email")
      .in("household_id", Array.from(todayHouseholdIds))
      .order("created_at", { ascending: true });
    for (const u of (userRows ?? []) as Array<Record<string, unknown>>) {
      const hid = compactString(u.household_id);
      if (!hid || customerByHousehold.has(hid)) continue;
      const first = compactString(u.first_name);
      const last = compactString(u.last_name);
      const full = [first, last].filter((s) => s.length > 0).join(" ");
      customerByHousehold.set(hid, full || compactString(u.email) || "Customer");
    }
  }

  // Materials cost across today's punch items. Sum across every punch item
  // attached to today's visit_task_ids: qty * unit_cost. Round to whole
  // cents at the end.
  let materialsCostCents = 0;
  const visitTaskIds = Array.from(requestById.values())
    .map((r) => compactString(r.visit_task_id))
    .filter((id) => !!id);
  if (visitTaskIds.length > 0) {
    const { data: punchRows } = await service
      .from("handyman_punch_items")
      .select("materials_used, assigned_visit_task_id")
      .in("assigned_visit_task_id", visitTaskIds)
      .is("archived_at", null);
    for (const p of (punchRows ?? []) as Array<Record<string, unknown>>) {
      const materials = Array.isArray(p.materials_used) ? p.materials_used : [];
      for (const m of materials as Array<Record<string, unknown>>) {
        const qty = Number(m.qty || 0);
        const unitCost = Number(m.unit_cost || 0);
        if (Number.isFinite(qty) && Number.isFinite(unitCost) && qty > 0 && unitCost > 0) {
          materialsCostCents += Math.round(qty * unitCost * 100);
        }
      }
    }
  }

  // Revenue invoiced today. Sum provider_invoices.total where workspace_id
  // matches AND DATE(sent_at) in workspace tz = today. Best-effort — if
  // the table doesn't exist (M5 hasn't shipped yet on this branch), or the
  // query errors, gracefully return 0.
  let revenueInvoicedCents = 0;
  const invoiceByRequestId = new Map<string, string>();
  try {
    // Pull every invoice for this workspace that was sent in the last 48h
    // (covers any tz drift) — filter to today in JS.
    const cutoff = new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString();
    const { data: invRows, error: invErr } = await service
      .from("provider_invoices")
      .select("id, request_id, total, sent_at, status")
      .eq("workspace_id", workspaceId)
      .gte("sent_at", cutoff)
      .not("sent_at", "is", null);
    if (invErr) {
      console.error("[handyman-provider] today_summary invoices read failed", invErr);
    } else {
      for (const inv of (invRows ?? []) as Array<Record<string, unknown>>) {
        const sentAt = compactString(inv.sent_at);
        if (!sentAt) continue;
        const sentYmd = fieldFormatYmdInZone(new Date(sentAt), timeZone);
        if (sentYmd !== todayYmd) continue;
        const totalDollars = Number(inv.total || 0);
        if (Number.isFinite(totalDollars) && totalDollars > 0) {
          revenueInvoicedCents += Math.round(totalDollars * 100);
        }
        const reqId = compactString(inv.request_id);
        const invId = compactString(inv.id);
        if (reqId && invId && !invoiceByRequestId.has(reqId)) {
          invoiceByRequestId.set(reqId, invId);
        }
      }
    }
  } catch (err) {
    console.error("[handyman-provider] today_summary invoices lookup failed", err);
  }

  // Build per-stop summary for the iOS list. Order matches stop_order
  // ascending (already sorted off the SELECT).
  const stops = todayAssignments.map((a) => {
    const requestId = compactString(a.request_id);
    const request = requestId ? requestById.get(requestId) : undefined;
    const propertyId = compactString(request?.property_id);
    const property = propertyId ? propertyById.get(propertyId) : undefined;
    const householdId = compactString(request?.household_id);
    const customerName = householdId
      ? (customerByHousehold.get(householdId) || "Customer")
      : "Customer";
    const inAt = compactString(a.clock_in_at);
    const outAt = compactString(a.clock_out_at);
    let totalMinutes = 0;
    if (inAt && outAt) {
      const inMs = new Date(inAt).getTime();
      const outMs = new Date(outAt).getTime();
      if (Number.isFinite(inMs) && Number.isFinite(outMs) && outMs > inMs) {
        totalMinutes = Math.round(
          (Math.max(0, (outMs - inMs) / 1000) - numberValue(a.paused_seconds || 0)) / 60,
        );
      }
    }
    return {
      requestId,
      customerName,
      address: compactString(property?.address) || "",
      title: compactString(request?.title) || "Visit",
      clockInAt: inAt || null,
      clockOutAt: outAt || null,
      totalMinutes,
      invoiceId: requestId ? (invoiceByRequestId.get(requestId) || null) : null,
    };
  });

  // Tomorrow preview — count + first stop. We pull the same shape as
  // today, but only enough to surface the headline.
  const { data: tomorrowAssignmentsRaw } = await service
    .from("provider_visit_assignments")
    .select("id, request_id, window_start_time, stop_order")
    .eq("workspace_id", workspaceId)
    .eq("route_date", tomorrowYmd)
    .order("stop_order", { ascending: true });
  const tomorrowAssignments = (tomorrowAssignmentsRaw ?? []) as Array<Record<string, unknown>>;

  let firstAt: string | null = null;
  let firstCustomer: string | null = null;
  if (tomorrowAssignments.length > 0) {
    const first = tomorrowAssignments[0];
    firstAt = compactString(first.window_start_time) || null;
    const firstRequestId = compactString(first.request_id);
    if (firstRequestId) {
      const { data: reqRow } = await service
        .from("handyman_requests")
        .select("household_id")
        .eq("id", firstRequestId)
        .maybeSingle();
      const hid = compactString(reqRow?.household_id);
      if (hid) {
        const { data: userRow } = await service
          .from("users")
          .select("first_name, last_name, email")
          .eq("household_id", hid)
          .order("created_at", { ascending: true })
          .limit(1)
          .maybeSingle();
        if (userRow) {
          const f = compactString(userRow.first_name);
          const l = compactString(userRow.last_name);
          const full = [f, l].filter((s) => s.length > 0).join(" ");
          firstCustomer = full || compactString(userRow.email) || null;
        }
      }
    }
  }

  return {
    today: {
      date: todayYmd,
      stopsCompleted: completedAssignments.length,
      stopsRemaining: remainingAssignments.length,
      totalClockMinutes,
      materialsCostCents,
      revenueInvoicedCents,
      stops,
    },
    tomorrow: {
      date: tomorrowYmd,
      stopsCount: tomorrowAssignments.length,
      firstAt,
      firstCustomer,
      weather: null,
    },
  };
}

// MARK: - Wave M6 — internal tech-to-tech notes
//
// Distinct from the customer-visible thread on `handyman_request_messages`.
// Workspace members write notes to coordinate context between techs +
// dispatch ("Customer prefers side door access" / "Brought wrong fitting,
// fix on next visit"); the homeowner never sees them. The Operations
// Desk + iOS field app both render the same rows from this table.

async function addTechNoteForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");
  // Sprint #4 R5-E-12B BLOCKER: tech notes are workspace-scoped, but
  // the row is keyed by request_id. Without this guard a W1 caller
  // could pass a W2 request_id and the row would land in W2's thread
  // even though the workspace_id stamp is W1.
  await assertRequestInWorkspace(service, requestId, workspaceId);

  const noteBody = compactString(body.body);
  if (!noteBody) throw new Error("body is required");
  if (noteBody.length > 4000) throw new Error("Note is too long (max 4000 chars)");

  const memberId = compactString(membership.id);

  const { data: inserted, error: insertError } = await service
    .from("provider_visit_tech_notes")
    .insert({
      workspace_id: workspaceId,
      request_id: requestId,
      author_member_id: memberId,
      body: noteBody,
    })
    .select()
    .single();

  if (insertError || !inserted) throw insertError ?? new Error("Failed to add tech note");

  // Return the note with the author name baked in so iOS doesn't need
  // a second round-trip to render the row. Mirrors list_tech_notes shape.
  const authorName =
    compactString(membership.full_name) ||
    compactString(membership.email) ||
    "Workspace member";

  return {
    note: {
      id: compactString(inserted.id),
      requestId: compactString(inserted.request_id),
      authorMemberId: compactString(inserted.author_member_id),
      authorName,
      body: compactString(inserted.body),
      createdAt: inserted.created_at,
    },
  };
}

async function listTechNotesForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");
  // Sprint #4 R5-E-12B: belt-and-braces — the SELECT below already
  // double-filters on workspace_id, so a cross-workspace requestId
  // returns an empty array, but we throw early so the caller gets a
  // clear "Request not found" error instead of a misleading empty
  // notes array.
  await assertRequestInWorkspace(service, requestId, workspaceId);

  const { data: notes, error } = await service
    .from("provider_visit_tech_notes")
    .select("id, request_id, author_member_id, body, created_at")
    .eq("workspace_id", workspaceId)
    .eq("request_id", requestId)
    .order("created_at", { ascending: true });

  if (error) throw error;

  const memberIds = Array.from(
    new Set(
      (notes ?? [])
        .map((row: Record<string, unknown>) => compactString(row.author_member_id))
        .filter(Boolean),
    ),
  );

  const memberById = new Map<string, Record<string, unknown>>();
  if (memberIds.length > 0) {
    const { data: members } = await service
      .from("provider_workspace_members")
      .select("id, full_name, email")
      .in("id", memberIds);
    for (const member of (members ?? []) as Record<string, unknown>[]) {
      memberById.set(compactString(member.id), member);
    }
  }

  return {
    notes: (notes ?? []).map((row: Record<string, unknown>) => {
      const member = memberById.get(compactString(row.author_member_id));
      return {
        id: compactString(row.id),
        requestId: compactString(row.request_id),
        authorMemberId: compactString(row.author_member_id),
        authorName:
          compactString(member?.full_name) ||
          compactString(member?.email) ||
          "Workspace member",
        body: compactString(row.body),
        createdAt: row.created_at,
      };
    }),
  };
}

// MARK: - Wave M2 — Punch list capture depth
//
// Photos + voice + materials + per-item time on top of the existing
// handyman_punch_items rows. Auth: caller must be a member of the
// workspace AND the punch item must belong to a request whose contractor
// is linked to that workspace. Mirrors the workspace-scoped chain that
// update_punch_item_status uses to derive the contractor link.

/**
 * Resolves a punch item to its (household, contractor, workspace) tuple
 * and asserts the caller has workspace access. Returns the punch item
 * row + its derived workspace id so the caller can insert / update with
 * confidence the link is real. Throws on any boundary failure (missing
 * item, missing contractor link, wrong workspace).
 */
async function loadPunchItemForWorkspace(
  service: ServiceClient,
  user: Record<string, unknown>,
  workspaceId: string,
  itemId: string,
) {
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const { data: item, error: itemErr } = await service
    .from("handyman_punch_items")
    .select(
      "id, household_id, property_id, assigned_visit_task_id, attachments, materials_used, time_spent_seconds, voice_note_path",
    )
    .eq("id", itemId)
    .maybeSingle();
  if (itemErr) throw itemErr;
  if (!item) throw new Error("Punch item not found");

  // Resolve the workspace this item lives under via:
  // punch_item.assigned_visit_task_id
  //   -> handyman_requests.contractor_id
  //   -> provider_contractor_links.workspace_id
  // If any link is missing or points to a different workspace, deny.
  const visitTaskId = compactString(item.assigned_visit_task_id);
  if (!visitTaskId) {
    throw new Error("Punch item not linked to a visit");
  }

  const { data: linkedReq } = await service
    .from("handyman_requests")
    .select("contractor_id")
    .eq("visit_task_id", visitTaskId)
    .limit(1)
    .maybeSingle();
  const contractorId = compactString(linkedReq?.contractor_id);
  if (!contractorId) throw new Error("Visit not linked to a contractor");

  const { data: workspaceLink } = await service
    .from("provider_contractor_links")
    .select("workspace_id")
    .eq("contractor_id", contractorId)
    .limit(1)
    .maybeSingle();
  const itemWorkspaceId = compactString(workspaceLink?.workspace_id);
  if (!itemWorkspaceId || itemWorkspaceId !== workspaceId) {
    throw new Error("Punch item belongs to a different workspace");
  }

  return item;
}

/**
 * Sign a punch-item-attachments storage path so the iOS app can render
 * an inline thumbnail. Mirrors createSignedSystemPhotoUrl. 1-hour TTL.
 */
async function createSignedPunchAttachmentUrl(service: ServiceClient, path: string) {
  const cleanPath = compactString(path);
  if (!cleanPath) return null;
  const { data, error } = await service.storage
    .from("punch-item-attachments")
    .createSignedUrl(cleanPath, 60 * 60);
  if (error) {
    console.warn(
      "[handyman-provider] failed to sign punch attachment",
      cleanPath,
      error.message,
    );
    return null;
  }
  return compactString(data?.signedUrl);
}

/**
 * Wave M2 — attach a photo to a punch item. Bytes arrive as base64 from
 * iOS (PhotosPicker → UIImage → JPEG → base64) or from the desktop SPA
 * via the same shape. We trust the client to have downsized to a sane
 * width before send; this function does NOT resize server-side because
 * Deno doesn't ship sharp / imagemagick and the iOS side already passes
 * a JPEG at compressionQuality 0.82. Storage path mirrors home-system-photos:
 * `<household_id>/<item_id>/<timestamp>-<random>.jpg`. Returns the
 * updated row with signed URLs filled in for every attachment so the
 * iOS UI can render the new thumbnail without a re-fetch round-trip.
 */
async function attachPunchPhotoForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const itemId = compactString(body.itemId);
  if (!workspaceId) throw new Error("workspaceId is required");
  if (!itemId) throw new Error("itemId is required");

  const item = await loadPunchItemForWorkspace(service, user, workspaceId, itemId);

  const fileBase64 = compactString(body.base64) || compactString(body.fileBase64);
  if (!fileBase64) throw new Error("base64 is required");
  const contentType = compactString(body.contentType) || "image/jpeg";
  const caption = compactString(body.caption);

  const householdId = compactString(item.household_id);
  if (!householdId) throw new Error("Punch item has no household");

  const stamp = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const ext = contentType.includes("png") ? "png" : "jpg";
  const path = `${householdId}/${itemId}/${stamp}.${ext}`;

  const bytes = decodeBase64Body(fileBase64);
  const { error: uploadError } = await service.storage
    .from("punch-item-attachments")
    .upload(path, bytes, { contentType, upsert: false });
  if (uploadError) throw new Error(`Upload failed: ${uploadError.message}`);

  const now = isoNow();
  const existing = Array.isArray(item.attachments) ? (item.attachments as unknown[]) : [];
  const newRecord = {
    kind: "photo",
    path,
    contentType,
    caption: caption || null,
    uploadedAt: now,
    uploadedBy: compactString(user.id) || null,
  };
  const nextAttachments = [...existing, newRecord];

  const { data: updated, error: updErr } = await service
    .from("handyman_punch_items")
    .update({ attachments: nextAttachments, updated_at: now })
    .eq("id", itemId)
    .select(
      "id, household_id, property_id, assigned_visit_task_id, attachments, materials_used, time_spent_seconds, voice_note_path, status, title",
    )
    .single();
  if (updErr || !updated) throw updErr ?? new Error("Failed to attach photo");

  // Sign every photo path so the iOS app can render thumbnails inline.
  const signed = await Promise.all(
    (Array.isArray(updated.attachments) ? (updated.attachments as Record<string, unknown>[]) : []).map(
      async (att) => {
        const p = compactString(att.path);
        if (!p) return att;
        const signedUrl = await createSignedPunchAttachmentUrl(service, p);
        return { ...att, signedUrl };
      },
    ),
  );

  return {
    item: {
      id: compactString(updated.id),
      attachments: signed,
      materialsUsed: Array.isArray(updated.materials_used) ? updated.materials_used : [],
      timeSpentSeconds: numberValue(updated.time_spent_seconds || 0),
      voiceNotePath: compactString(updated.voice_note_path) || null,
    },
  };
}

/**
 * Wave M2 — attach a voice note to a punch item. Bytes arrive as base64
 * from iOS' AVAudioRecorder (m4a/aac, single track, mono). We overwrite
 * any prior voice_note_path because the field flow only supports ONE
 * voice note per item — the tech can re-record but never accumulates a
 * playlist. The previous file is best-effort removed from storage.
 */
async function attachPunchVoiceForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const itemId = compactString(body.itemId);
  if (!workspaceId) throw new Error("workspaceId is required");
  if (!itemId) throw new Error("itemId is required");

  const item = await loadPunchItemForWorkspace(service, user, workspaceId, itemId);

  const fileBase64 = compactString(body.base64);
  if (!fileBase64) throw new Error("base64 is required");
  const mimeType = compactString(body.mimeType) || "audio/m4a";

  const householdId = compactString(item.household_id);
  if (!householdId) throw new Error("Punch item has no household");

  // One voice note per item — overwrite if one already exists. Best-effort
  // remove the old file from storage so we don't leak bytes.
  const previousPath = compactString(item.voice_note_path);
  if (previousPath) {
    await service.storage.from("punch-item-attachments").remove([previousPath]).catch((err) => {
      console.warn("[handyman-provider] failed to remove prior voice note", previousPath, err);
    });
  }

  const ext = mimeType.includes("aac") ? "aac" : "m4a";
  const path = `${householdId}/${itemId}/voice-${Date.now()}.${ext}`;

  const bytes = decodeBase64Body(fileBase64);
  const { error: uploadError } = await service.storage
    .from("punch-item-attachments")
    .upload(path, bytes, { contentType: mimeType, upsert: true });
  if (uploadError) throw new Error(`Upload failed: ${uploadError.message}`);

  const now = isoNow();
  const { data: updated, error: updErr } = await service
    .from("handyman_punch_items")
    .update({ voice_note_path: path, updated_at: now })
    .eq("id", itemId)
    .select(
      "id, household_id, property_id, assigned_visit_task_id, attachments, materials_used, time_spent_seconds, voice_note_path, status, title",
    )
    .single();
  if (updErr || !updated) throw updErr ?? new Error("Failed to attach voice note");

  const signedVoiceUrl = await createSignedPunchAttachmentUrl(service, path);

  return {
    item: {
      id: compactString(updated.id),
      attachments: Array.isArray(updated.attachments) ? updated.attachments : [],
      materialsUsed: Array.isArray(updated.materials_used) ? updated.materials_used : [],
      timeSpentSeconds: numberValue(updated.time_spent_seconds || 0),
      voiceNotePath: compactString(updated.voice_note_path) || null,
      voiceNoteSignedUrl: signedVoiceUrl,
    },
  };
}

/**
 * Wave M2 — replace the materials_used JSONB array on a punch item.
 * Each row is `{ sku?: string, name: string, qty: number, unit_cost: number }`.
 * The contractor desk consumes the same shape on the post-visit review
 * surface so per-item materials cost rolls into the invoice convertor.
 * Validates: name non-empty, qty >= 0, unit_cost >= 0. Rejects the
 * whole array on any invalid row so the iOS UI can surface a precise
 * error message.
 */
async function setPunchMaterialsForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const itemId = compactString(body.itemId);
  if (!workspaceId) throw new Error("workspaceId is required");
  if (!itemId) throw new Error("itemId is required");

  await loadPunchItemForWorkspace(service, user, workspaceId, itemId);

  const raw = Array.isArray(body.materials) ? (body.materials as Record<string, unknown>[]) : [];
  const cleaned = raw.map((row, idx) => {
    const name = compactString(row.name);
    if (!name) throw new Error(`Material ${idx + 1} is missing a name`);
    const qtyRaw = numberValue(row.qty ?? row.quantity ?? 0);
    const qty = Number.isFinite(qtyRaw) && qtyRaw >= 0 ? qtyRaw : 0;
    const unitCostRaw = numberValue(row.unit_cost ?? row.unitCost ?? 0);
    const unitCost = Number.isFinite(unitCostRaw) && unitCostRaw >= 0 ? unitCostRaw : 0;
    const sku = compactString(row.sku);
    return {
      ...(sku ? { sku } : {}),
      name,
      qty,
      unit_cost: unitCost,
    };
  });

  const now = isoNow();
  const { data: updated, error: updErr } = await service
    .from("handyman_punch_items")
    .update({ materials_used: cleaned, updated_at: now })
    .eq("id", itemId)
    .select(
      "id, attachments, materials_used, time_spent_seconds, voice_note_path",
    )
    .single();
  if (updErr || !updated) throw updErr ?? new Error("Failed to save materials");

  return {
    item: {
      id: compactString(updated.id),
      attachments: Array.isArray(updated.attachments) ? updated.attachments : [],
      materialsUsed: Array.isArray(updated.materials_used) ? updated.materials_used : [],
      timeSpentSeconds: numberValue(updated.time_spent_seconds || 0),
      voiceNotePath: compactString(updated.voice_note_path) || null,
    },
  };
}

/**
 * Wave M2 — set the per-item time-spent counter. The iOS UI runs an
 * in-memory timer (reset on each toggle) and POSTs the final elapsed
 * seconds when the tech stops the timer. Server clamps to non-negative
 * integer; negative or NaN values fall back to 0.
 */
async function setPunchTimeSpentForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const itemId = compactString(body.itemId);
  if (!workspaceId) throw new Error("workspaceId is required");
  if (!itemId) throw new Error("itemId is required");

  await loadPunchItemForWorkspace(service, user, workspaceId, itemId);

  const raw = numberValue(body.seconds ?? 0);
  const seconds = Number.isFinite(raw) && raw >= 0 ? Math.round(raw) : 0;

  const now = isoNow();
  const { data: updated, error: updErr } = await service
    .from("handyman_punch_items")
    .update({ time_spent_seconds: seconds, updated_at: now })
    .eq("id", itemId)
    .select(
      "id, attachments, materials_used, time_spent_seconds, voice_note_path",
    )
    .single();
  if (updErr || !updated) throw updErr ?? new Error("Failed to save time spent");

  return {
    item: {
      id: compactString(updated.id),
      attachments: Array.isArray(updated.attachments) ? updated.attachments : [],
      materialsUsed: Array.isArray(updated.materials_used) ? updated.materials_used : [],
      timeSpentSeconds: numberValue(updated.time_spent_seconds || 0),
      voiceNotePath: compactString(updated.voice_note_path) || null,
    },
  };
}

// ─── Wave M12 — "Need part" flow ──────────────────────────────────
//
// Mid-visit, the field tech realizes they need a part. Tap "Need part"
// on a visit (or on a specific punch item) → POST create_part_request →
// row lands in `provider_part_requests` → operator sees it on the Routes
// screen "Part Requests" sub-section in real time → operator dispatches
// another tech, marks ordered with supplier ETA, or marks fulfilled.
//
// 4 actions:
//   - create_part_request: insert one row + push to workspace
//     owners/admins/dispatchers when urgency='blocking_now'
//   - update_part_status: status walk + supplier metadata
//   - list_open_part_requests: returns workspace's open rows for the
//     iOS Today-screen pill + the Operations Desk Routes section
//   - attach_part_request_photo: upload a photo to the existing
//     punch-item-attachments bucket under a part-requests/ prefix and
//     append it to the part request's photos JSONB

/**
 * Wave M12 — sign a part-request photo path. Mirrors
 * createSignedPunchAttachmentUrl but kept distinct for traceability.
 * 1-hour TTL.
 */
async function createSignedPartRequestPhotoUrl(service: ServiceClient, path: string) {
  const cleanPath = compactString(path);
  if (!cleanPath) return null;
  const { data, error } = await service.storage
    .from("punch-item-attachments")
    .createSignedUrl(cleanPath, 60 * 60);
  if (error) {
    console.warn(
      "[handyman-provider] failed to sign part-request photo",
      cleanPath,
      error.message,
    );
    return null;
  }
  return compactString(data?.signedUrl);
}

/**
 * Wave M12 — convert a `provider_part_requests` row into the camelCase
 * shape iOS' `HavenFieldPartRequest` model expects, with photo paths
 * resolved to signed URLs so the iOS lightbox / list view can render
 * inline thumbnails without per-asset round-trips.
 */
async function serializePartRequest(
  service: ServiceClient,
  row: Record<string, unknown>,
) {
  const rawPhotos = Array.isArray(row.photos) ? (row.photos as Record<string, unknown>[]) : [];
  const signedPhotos = await Promise.all(
    rawPhotos.map(async (att) => {
      const p = compactString(att.path);
      if (!p) return att;
      const signedUrl = await createSignedPartRequestPhotoUrl(service, p);
      return { ...att, signedUrl };
    }),
  );
  return {
    id: compactString(row.id),
    workspaceId: compactString(row.workspace_id),
    requestId: compactString(row.request_id) || null,
    punchItemId: compactString(row.punch_item_id) || null,
    description: compactString(row.description),
    urgency: compactString(row.urgency) || "next_visit",
    photos: signedPhotos,
    status: compactString(row.status) || "open",
    supplier: compactString(row.supplier) || null,
    supplierEta: row.supplier_eta ?? null,
    fulfilledAt: row.fulfilled_at ?? null,
    requestedByMemberId: compactString(row.requested_by_member_id),
    createdAt: row.created_at ?? null,
    updatedAt: row.updated_at ?? null,
  };
}

/**
 * Wave M12 — load a part request by id and verify it belongs to a
 * workspace the calling user is a member of. Mirrors the dual-gate
 * pattern: assertWorkspaceAccess on the caller-supplied workspaceId,
 * then a second check that the row's `workspace_id` matches.
 */
async function loadPartRequestForWorkspace(
  service: ServiceClient,
  user: Record<string, unknown>,
  workspaceId: string,
  partRequestId: string,
) {
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const { data: row, error } = await service
    .from("provider_part_requests")
    .select("*")
    .eq("id", partRequestId)
    .maybeSingle();
  if (error) throw error;
  if (!row) throw new Error("Part request not found");

  const rowWorkspaceId = compactString(row.workspace_id);
  if (rowWorkspaceId !== workspaceId) {
    throw new Error("Part request belongs to a different workspace");
  }
  return row;
}

/**
 * Wave M12 — create a part request. Either `requestId` or `punchItemId`
 * must be present (one for visit-level, one for punch-item-level —
 * both can be set if a punch item lives on a specific request). When
 * urgency='blocking_now', fires a push notification to every active
 * owner/admin/dispatcher in the workspace so the operator can react in
 * real time. Returns the new row.
 */
async function createPartRequestForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  if (!workspaceId) throw new Error("workspaceId is required");

  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  const memberId = compactString(membership.id);
  if (!memberId) throw new Error("Could not resolve workspace member id");

  const requestId = compactString(body.requestId) || null;
  const punchItemId = compactString(body.punchItemId) || null;
  if (!requestId && !punchItemId) {
    throw new Error("Either requestId or punchItemId is required");
  }

  // Sprint #4 R5-E-12B: cross-workspace guard on optional requestId.
  // The punchItemId path has its own loadPunchItemForWorkspace check
  // upstream when needed; this protects the direct-requestId path that
  // skips punch item lookup.
  if (requestId) {
    await assertRequestInWorkspace(service, requestId, workspaceId);
  }

  const description = compactString(body.description);
  if (!description) throw new Error("description is required");

  const urgencyRaw = compactString(body.urgency) || "next_visit";
  const urgency = ["blocking_now", "next_visit", "order_for_stock"].includes(urgencyRaw)
    ? urgencyRaw
    : "next_visit";

  // Photos can be passed as an array of { kind, path, signedUrl?, caption? }
  // already-uploaded objects (the iOS UI uploads via attach_part_request_photo
  // first, then passes the resolved entries here). We do NOT re-sign here; the
  // serializer below will fold in fresh signed URLs on the response.
  const rawPhotos = Array.isArray(body.photos) ? (body.photos as Record<string, unknown>[]) : [];
  const photos = rawPhotos
    .map((p) => {
      const path = compactString(p.path);
      if (!path) return null;
      return {
        kind: compactString(p.kind) || "photo",
        path,
        contentType: compactString(p.contentType) || "image/jpeg",
        caption: compactString(p.caption) || null,
        uploadedAt: p.uploadedAt ?? isoNow(),
        uploadedBy: compactString(p.uploadedBy) || userId || null,
      };
    })
    .filter((p): p is NonNullable<typeof p> => p !== null);

  // If a punchItemId is supplied, optionally hydrate the parent request
  // for the row so future joins work without back-and-forth lookups.
  let resolvedRequestId = requestId;
  if (!resolvedRequestId && punchItemId) {
    const { data: punch } = await service
      .from("handyman_punch_items")
      .select("assigned_visit_task_id")
      .eq("id", punchItemId)
      .maybeSingle();
    const visitTaskId = compactString((punch as Record<string, unknown> | null)?.assigned_visit_task_id);
    if (visitTaskId) {
      const { data: linked } = await service
        .from("handyman_requests")
        .select("id")
        .eq("visit_task_id", visitTaskId)
        .limit(1)
        .maybeSingle();
      const linkedRequestId = compactString((linked as Record<string, unknown> | null)?.id);
      if (linkedRequestId) resolvedRequestId = linkedRequestId;
    }
  }

  const now = isoNow();
  const { data: inserted, error: insErr } = await service
    .from("provider_part_requests")
    .insert({
      workspace_id: workspaceId,
      request_id: resolvedRequestId,
      punch_item_id: punchItemId,
      description,
      urgency,
      photos,
      status: "open",
      requested_by_member_id: memberId,
      created_at: now,
      updated_at: now,
    })
    .select("*")
    .single();
  if (insErr || !inserted) throw insErr ?? new Error("Failed to create part request");

  // Fire-and-forget push to operations members for the blocking-now
  // urgency tier. Mirrors the existing notifyProvider pattern but
  // targets a narrower audience (owners + admins + dispatchers — techs
  // typically aren't the ones routing inventory).
  if (urgency === "blocking_now") {
    notifyOpsMembersForPartRequest(service, workspaceId, {
      title: "Part needed now",
      body: description.length > 100 ? `${description.slice(0, 97)}...` : description,
      partRequestId: compactString(inserted.id),
      requestId: resolvedRequestId,
    }).catch((e) => console.error("[handyman-provider:part_request] push failed", e));
  }

  return { partRequest: await serializePartRequest(service, inserted) };
}

/**
 * Wave M12 — update a part request's status + optional supplier metadata.
 * Status transitions: open → ordered → in_truck → fulfilled (or open →
 * cancelled). When status flips to fulfilled, stamp `fulfilled_at = now()`.
 */
async function updatePartStatusForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const partRequestId = compactString(body.partRequestId);
  if (!workspaceId) throw new Error("workspaceId is required");
  if (!partRequestId) throw new Error("partRequestId is required");

  await loadPartRequestForWorkspace(service, user, workspaceId, partRequestId);

  const statusRaw = compactString(body.status);
  if (!statusRaw) throw new Error("status is required");
  if (!["open", "ordered", "in_truck", "fulfilled", "cancelled"].includes(statusRaw)) {
    throw new Error("Invalid status");
  }

  const supplier = compactString(body.supplier);
  const supplierEtaRaw = compactString(body.supplierEta);
  const now = isoNow();

  const update: Record<string, unknown> = {
    status: statusRaw,
    updated_at: now,
  };
  if (supplier) update.supplier = supplier;
  if (supplierEtaRaw) update.supplier_eta = supplierEtaRaw;
  if (statusRaw === "fulfilled") update.fulfilled_at = now;

  const { data: updated, error: updErr } = await service
    .from("provider_part_requests")
    .update(update)
    .eq("id", partRequestId)
    .select("*")
    .single();
  if (updErr || !updated) throw updErr ?? new Error("Failed to update part request");

  return { partRequest: await serializePartRequest(service, updated) };
}

/**
 * Wave M12 — list every part request for a workspace, optionally
 * filtered to status='open'. Defaults to the open-only query so the
 * Today-screen pill + Routes section render the active queue without
 * a status param. Caller passes `status: "all"` to fetch everything.
 */
async function listPartRequestsForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  if (!workspaceId) throw new Error("workspaceId is required");
  await assertWorkspaceAccess(service, userId, workspaceId);

  const statusFilter = compactString(body.status) || "open";

  let query = service
    .from("provider_part_requests")
    .select("*")
    .eq("workspace_id", workspaceId)
    .order("created_at", { ascending: false })
    .limit(100);

  if (statusFilter !== "all") {
    query = query.eq("status", statusFilter);
  }

  const { data: rows, error } = await query;
  if (error) throw error;

  const partRequests = await Promise.all(
    (rows ?? []).map((row) => serializePartRequest(service, row as Record<string, unknown>)),
  );
  return { partRequests, openCount: partRequests.filter((p) => p.status === "open").length };
}

/**
 * Wave M12 — attach a photo to a part request. Mirrors attach_punch_photo
 * but stores under a `part-requests/` prefix in the same bucket so we
 * don't have to provision a separate one. The iOS UI typically uploads
 * BEFORE submitting create_part_request, then passes the returned
 * `path` + `signedUrl` in the photos array of the create call.
 */
async function attachPartRequestPhotoForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  if (!workspaceId) throw new Error("workspaceId is required");
  await assertWorkspaceAccess(service, userId, workspaceId);

  const fileBase64 = compactString(body.base64) || compactString(body.fileBase64);
  if (!fileBase64) throw new Error("base64 is required");
  const contentType = compactString(body.contentType) || "image/jpeg";
  const caption = compactString(body.caption);

  const stamp = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const ext = contentType.includes("png") ? "png" : "jpg";
  // Storage path: part-requests/<workspace_id>/<stamp>.<ext>
  // No partRequestId in the path because uploads happen BEFORE the
  // request row exists; the row references the path after create.
  const path = `part-requests/${workspaceId}/${stamp}.${ext}`;

  const bytes = decodeBase64Body(fileBase64);
  const { error: uploadError } = await service.storage
    .from("punch-item-attachments")
    .upload(path, bytes, { contentType, upsert: false });
  if (uploadError) throw new Error(`Upload failed: ${uploadError.message}`);

  const signedUrl = await createSignedPartRequestPhotoUrl(service, path);

  return {
    photo: {
      kind: "photo",
      path,
      contentType,
      caption: caption || null,
      uploadedAt: isoNow(),
      uploadedBy: userId || null,
      signedUrl,
    },
  };
}

/**
 * Wave M12 — fire a push to every active owner/admin/dispatcher in the
 * workspace when a blocking-now part request lands. Techs are
 * intentionally skipped — they're field staff, not the inventory
 * routers. Mirrors notifyProviderForRequest's send-push-notification
 * call shape but resolves user_ids by joining workspace members on
 * role.
 */
async function notifyOpsMembersForPartRequest(
  service: ServiceClient,
  workspaceId: string,
  payload: {
    title: string;
    body: string;
    partRequestId: string;
    requestId?: string | null;
  },
): Promise<void> {
  try {
    const { data: members } = await service
      .from("provider_workspace_members")
      .select("user_id, role")
      .eq("workspace_id", workspaceId)
      .eq("status", "active")
      .in("role", ["owner", "admin", "dispatcher"]);

    const userIds = ((members ?? []) as Record<string, unknown>[])
      .map((row) => compactString(row.user_id))
      .filter(Boolean);

    if (userIds.length === 0) return;

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const data: Record<string, string> = {
      type: "part_request_blocking",
      part_request_id: payload.partRequestId,
      workspace_id: workspaceId,
    };
    if (payload.requestId) data.request_id = payload.requestId;

    await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({
        recipient_user_ids: userIds,
        title: payload.title,
        body: payload.body,
        data,
      }),
    });
  } catch (pushError) {
    console.error("[handyman-provider:notifyOpsMembersForPartRequest] push failed", pushError);
  }
}

async function assertWorkspaceAccess(service: ServiceClient, userId: string, workspaceId: string) {
  const membership = await getWorkspaceMembership(service, userId);
  if (!membership) throw new Error("No provider workspace found");
  const activeWorkspaceId = compactString((membership.provider_workspaces as Record<string, unknown> | undefined)?.id);
  if (activeWorkspaceId !== workspaceId) throw new Error("Workspace access denied");
  return membership;
}

// Sprint #4 R5-E-12B fix (BLOCKER cross-tenant isolation): every action
// that takes a `requestId` must verify the request actually belongs to
// the caller's workspace. Without this guard, a malicious or buggy
// caller could pass a foreign workspaceId-validated `workspaceId` plus
// a `requestId` belonging to another contractor's customer, and the
// handler would happily write a message / tech note / status update
// against the foreign request — emailing the foreign customer with
// content they didn't ask for and polluting their thread.
//
// Most lifecycle handlers already enforce this implicitly by going
// through `loadAssignmentForLifecycle(workspaceId, requestId)` (which
// scopes the SELECT by both columns); the bugs are in handlers that
// take requestId for non-assignment writes (sendMessage,
// addTechNoteForProvider) or for actions that don't need an assignment
// row to exist (e.g. message threads where no assignment was ever
// created). The workspace ↔ request linkage is via the
// `provider_contractor_links.contractor_id` <-> `handyman_requests.contractor_id`
// edge — same shape that buildQuoteFromVisit / convertVisitToInvoice
// already check inline.
//
// Throws on mismatch; returns void on pass. Callers should run this
// AFTER assertWorkspaceAccess (which validates membership) and BEFORE
// any DB writes that reference requestId.
async function assertRequestInWorkspace(
  service: ServiceClient,
  requestId: string,
  workspaceId: string,
) {
  if (!requestId) throw new Error("requestId is required");
  if (!workspaceId) throw new Error("workspaceId is required");

  const { data: requestRow, error: requestErr } = await service
    .from("handyman_requests")
    .select("id, contractor_id")
    .eq("id", requestId)
    .maybeSingle();
  if (requestErr) throw requestErr;
  if (!requestRow) throw new Error("Request not found in this workspace");

  const contractorId = compactString(requestRow.contractor_id);
  if (!contractorId) {
    // Request exists but has no contractor — can't possibly belong to
    // this workspace. Treat as a not-found / cross-tenant violation.
    throw new Error("Request not found in this workspace");
  }

  const { data: link, error: linkErr } = await service
    .from("provider_contractor_links")
    .select("workspace_id")
    .eq("contractor_id", contractorId)
    .eq("workspace_id", workspaceId)
    .maybeSingle();
  if (linkErr) throw linkErr;
  if (!link) {
    throw new Error("Request not found in this workspace");
  }
}

function assertPermission(membership: Record<string, unknown>, permission: keyof ReturnType<typeof rolePermissions>) {
  const permissions = rolePermissions(compactString(membership.role));
  if (!permissions[permission]) {
    throw new Error("Permission denied");
  }
  return permissions;
}

async function inviteTeamMember(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canManageCrew");

  const email = normalizedEmail(body.email);
  if (!email) throw new Error("Team member email is required");

  const role = compactString(body.role) || "technician";
  if (!["owner", "admin", "dispatcher", "technician"].includes(role)) {
    throw new Error("Invalid team member role");
  }

  const fullName = compactString(body.fullName) || compactString(body.name) || email;
  const phone = compactString(body.phone) || null;
  const title = compactString(body.title) || roleLabel(role);
  const inviteToken = crypto.randomUUID();
  const now = isoNow();

  const { data: existing, error: existingError } = await service
    .from("provider_workspace_members")
    .select("*")
    .eq("workspace_id", workspaceId)
    .ilike("email", email)
    .limit(1)
    .maybeSingle();

  if (existingError) throw existingError;

  const payload = {
    workspace_id: workspaceId,
    user_id: existing?.user_id ?? null,
    full_name: fullName,
    email,
    phone,
    title,
    role,
    status: existing?.user_id ? compactString(existing.status) || "active" : "invited",
    invite_token: existing?.user_id ? compactString(existing.invite_token) || null : inviteToken,
    invite_sent_at: existing?.user_id ? existing.invite_sent_at ?? null : now,
    invited_by_user_id: userId,
    updated_at: now,
  };

  const mutation = existing?.id
    ? service
        .from("provider_workspace_members")
        .update(payload)
        .eq("id", existing.id)
        .select()
        .single()
    : service
        .from("provider_workspace_members")
        .insert(payload)
        .select()
        .single();

  const { data, error } = await mutation;
  if (error || !data) throw error ?? new Error("Failed to invite team member");

  return {
    id: compactString(data.id),
    fullName: compactString(data.full_name),
    email: compactString(data.email),
    phone: compactString(data.phone),
    title: compactString(data.title) || roleLabel(compactString(data.role)),
    role: compactString(data.role),
    roleLabel: roleLabel(compactString(data.role)),
    status: compactString(data.status),
    inviteUrl: compactString(data.invite_token) ? teamInviteUrl(compactString(data.invite_token)) : null,
  };
}

async function updateTeamMember(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canManageCrew");

  const memberId = compactString(body.memberId);
  if (!memberId) throw new Error("Missing team member");

  const updates: Record<string, unknown> = {
    updated_at: isoNow(),
  };
  if (typeof body.role !== "undefined") updates.role = compactString(body.role);
  if (typeof body.status !== "undefined") updates.status = compactString(body.status);
  if (typeof body.title !== "undefined") updates.title = compactString(body.title) || null;
  if (typeof body.phone !== "undefined") updates.phone = compactString(body.phone) || null;

  // Phase 85 dispatch: flipping is_default_assignee=true must clear
  // every peer first because the partial unique index allows only one
  // default per workspace. Do the clear in the same transaction-y
  // pattern Tom uses elsewhere — best-effort sequential writes,
  // tolerant of the rare race where two operators flip simultaneously
  // (the second update will surface a 23505 unique-violation that the
  // SPA can retry).
  const flippingDefault =
    typeof body.isDefaultAssignee !== "undefined" &&
    body.isDefaultAssignee === true;
  if (typeof body.isDefaultAssignee !== "undefined") {
    updates.is_default_assignee = body.isDefaultAssignee === true;
  }

  if (flippingDefault) {
    const { error: clearError } = await service
      .from("provider_workspace_members")
      .update({ is_default_assignee: false, updated_at: isoNow() })
      .eq("workspace_id", workspaceId)
      .neq("id", memberId)
      .eq("is_default_assignee", true);
    if (clearError) throw clearError;
  }

  const { data, error } = await service
    .from("provider_workspace_members")
    .update(updates)
    .eq("id", memberId)
    .eq("workspace_id", workspaceId)
    .select()
    .single();

  if (error || !data) throw error ?? new Error("Failed to update team member");
  return data;
}

/// Chez v1: directory listing fields. The homeowner-side
/// `find-network-handymen` Edge Function reads these to surface
/// providers in the find-a-handyman flow. Only owner/admin members
/// (via `canManageWorkspace`) can edit.
async function updateWorkspaceDirectory(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canManageWorkspace");

  const updates: Record<string, unknown> = {
    updated_at: isoNow(),
  };

  // Wave P: identity fields (company name, primary contact, website,
  // license). Live alongside the directory fields below — the Settings
  // screen treats them as one logical save. Each typeof-guarded so a
  // partial update only writes the fields the caller passed.
  if (typeof body.companyName !== "undefined") {
    const name = compactString(body.companyName);
    if (!name) throw new Error("Company name cannot be blank");
    updates.company_name = name.slice(0, 200);
  }
  if (typeof body.primaryEmail !== "undefined") {
    const raw = compactString(body.primaryEmail);
    if (raw && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(raw)) {
      throw new Error("Primary email is not a valid email address");
    }
    updates.primary_email = raw ? raw.toLowerCase() : null;
  }
  if (typeof body.primaryPhone !== "undefined") {
    updates.primary_phone = compactString(body.primaryPhone) || null;
  }
  if (typeof body.website !== "undefined") {
    updates.website = compactString(body.website) || null;
  }
  if (typeof body.licenseNumber !== "undefined") {
    const raw = compactString(body.licenseNumber);
    updates.license_number = raw ? raw.slice(0, 80) : null;
  }

  if (typeof body.isListedInDirectory !== "undefined") {
    updates.is_listed_in_directory = Boolean(body.isListedInDirectory);
  }
  if (typeof body.serviceState !== "undefined") {
    const stateRaw = compactString(body.serviceState);
    updates.service_state = stateRaw ? stateRaw.toUpperCase().slice(0, 2) : null;
  }
  if (typeof body.serviceCity !== "undefined") {
    updates.service_city = compactString(body.serviceCity) || null;
  }
  if (typeof body.serviceZipCodes !== "undefined") {
    const raw = body.serviceZipCodes;
    let zips: string[] = [];
    if (Array.isArray(raw)) {
      zips = raw.map((z) => compactString(z)).filter((z) => z.length > 0);
    } else if (typeof raw === "string") {
      zips = raw
        .split(/[,;\s]+/)
        .map((z) => z.trim())
        .filter((z) => /^\d{5}$/.test(z));
    }
    // Dedupe + cap to a sensible max so a paste of every NY zip can't
    // bloat a single workspace row.
    updates.service_zip_codes = Array.from(new Set(zips)).slice(0, 50);
  }
  if (typeof body.categories !== "undefined") {
    const raw = body.categories;
    let cats: string[] = [];
    if (Array.isArray(raw)) {
      cats = raw.map((c) => compactString(c).toLowerCase()).filter((c) => c.length > 0);
    } else if (typeof raw === "string") {
      cats = compactString(raw)
        .toLowerCase()
        .split(/[,;\s]+/)
        .map((c) => c.trim())
        .filter((c) => c.length > 0);
    }
    if (cats.length === 0) cats = ["handyman"];
    updates.categories = Array.from(new Set(cats)).slice(0, 10);
  }
  if (typeof body.displayBlurb !== "undefined") {
    const blurb = compactString(body.displayBlurb);
    updates.display_blurb = blurb.length === 0 ? null : blurb.slice(0, 280);
  }
  if (typeof body.headshotUrl !== "undefined") {
    const url = compactString(body.headshotUrl);
    updates.headshot_url = url.length === 0 ? null : url;
  }

  const { data, error } = await service
    .from("provider_workspaces")
    .update(updates)
    .eq("id", workspaceId)
    .select(
      "id, company_name, primary_email, primary_phone, website, license_number, is_listed_in_directory, service_state, service_city, service_zip_codes, categories, display_blurb, headshot_url, aggregate_rating, review_count",
    )
    .single();

  if (error || !data) throw error ?? new Error("Failed to update workspace directory");
  return data;
}

async function assignVisit(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canAssignWork");

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("Missing request");

  const assignedMemberId = compactString(body.assignedMemberId) || null;
  let routeDate = compactString(body.routeDate) || null;
  let windowStartTime = compactString(body.windowStartTime) || null;
  let windowEndTime = compactString(body.windowEndTime) || null;
  const routeNotes = compactString(body.routeNotes) || null;
  const stopOrder = numberValue(body.stopOrder || 0);

  if (assignedMemberId) {
    const { data: member } = await service
      .from("provider_workspace_members")
      .select("id")
      .eq("id", assignedMemberId)
      .eq("workspace_id", workspaceId)
      .eq("status", "active")
      .limit(1)
      .maybeSingle();
    if (!member) throw new Error("Assigned team member is not in this workspace");
  }

  const { data: request, error: requestError } = await service
    .from("handyman_requests")
    .select("id, visit_task_id, status, confirmed_visit_at")
    .eq("id", requestId)
    .limit(1)
    .maybeSingle();

  if (requestError || !request) throw requestError ?? new Error("Request not found");

  // Lock the visit date to the homeowner-confirmed time. The dispatch
  // UI is for picking WHO does the work, not WHEN — when the homeowner
  // already accepted a time, any client-side date the UI sends gets
  // ignored. Without this, opening the assign panel on a confirmed
  // visit and clicking a tech would silently rebook to whatever date
  // the picker happened to default to.
  const confirmedAt = compactString(request.confirmed_visit_at);
  if (confirmedAt) {
    const confirmedDate = new Date(confirmedAt);
    if (!Number.isNaN(confirmedDate.getTime())) {
      const yyyy = confirmedDate.getUTCFullYear();
      const mm = String(confirmedDate.getUTCMonth() + 1).padStart(2, "0");
      const dd = String(confirmedDate.getUTCDate()).padStart(2, "0");
      const hh = String(confirmedDate.getUTCHours()).padStart(2, "0");
      const mi = String(confirmedDate.getUTCMinutes()).padStart(2, "0");
      const endHh = String((confirmedDate.getUTCHours() + 2) % 24).padStart(2, "0");
      routeDate = `${yyyy}-${mm}-${dd}`;
      windowStartTime = `${hh}:${mi}:00`;
      windowEndTime = `${endHh}:${mi}:00`;
    }
  }

  if (!assignedMemberId && !routeDate && !windowStartTime && !windowEndTime && !routeNotes && stopOrder <= 0) {
    await service
      .from("provider_visit_assignments")
      .delete()
      .eq("workspace_id", workspaceId)
      .eq("request_id", requestId);
    return { removed: true };
  }

  const payload = {
    workspace_id: workspaceId,
    request_id: requestId,
    visit_task_id: compactString(request.visit_task_id) || null,
    assigned_member_id: assignedMemberId,
    assigned_by_user_id: userId,
    route_date: routeDate,
    window_start_time: windowStartTime,
    window_end_time: windowEndTime,
    stop_order: stopOrder > 0 ? stopOrder : null,
    route_notes: routeNotes,
    updated_at: isoNow(),
  };

  const { data, error } = await service
    .from("provider_visit_assignments")
    .upsert(payload, { onConflict: "workspace_id,request_id" })
    .select()
    .single();

  if (error || !data) throw error ?? new Error("Failed to assign visit");

  const currentStatus = compactString(request.status);
  if (assignedMemberId && ["submitted", "scheduled"].includes(currentStatus)) {
    await service
      .from("handyman_requests")
      .update({
        status: "sent_to_handyman",
        updated_at: isoNow(),
      })
      .eq("id", requestId);
  }

  return data;
}

/**
 * Wave Z.1 — Drag-to-reschedule on the calendar. Moves a visit's
 * route_date to a new day. Lighter-touch than propose_visit_time:
 * - Doesn't go through the homeowner accept/decline cycle
 * - Doesn't shift confirmed_visit_at hours (calendar drag is day-grain)
 * - Keeps the same assigned tech, window times, stop_order
 *
 * Use cases:
 * 1. Unconfirmed/draft visits — contractor moves the proposed day
 * 2. Already-confirmed visits — contractor needs to shift; an audit
 *    message lands in the thread so the homeowner sees what happened.
 *    For confirmed visits the SPA also shows a confirm dialog before
 *    calling here.
 *
 * Writes a `visit_rescheduled` audit message into handyman_request_messages
 * so the homeowner-side thread mirrors the change (cross-app parity per
 * Section 22 mandate).
 */
async function rescheduleVisit(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canAssignWork");

  const requestId = compactString(body.requestId);
  const newRouteDate = compactString(body.newRouteDate);
  if (!requestId) throw new Error("Missing request");
  if (!newRouteDate || !/^\d{4}-\d{2}-\d{2}$/.test(newRouteDate)) {
    throw new Error("Invalid newRouteDate (expected yyyy-MM-dd)");
  }

  // Lookup the visit assignment row + parent request for context.
  const { data: assignment } = await service
    .from("provider_visit_assignments")
    .select("id, route_date")
    .eq("workspace_id", workspaceId)
    .eq("request_id", requestId)
    .limit(1)
    .maybeSingle();
  if (!assignment) throw new Error("Visit assignment not found");

  const { data: request } = await service
    .from("handyman_requests")
    .select("id, household_id, status, confirmed_visit_at, title")
    .eq("id", requestId)
    .limit(1)
    .maybeSingle();
  if (!request) throw new Error("Request not found");

  const oldRouteDate = compactString(assignment.route_date);
  const householdId = compactString(request.household_id);
  const wasConfirmed = Boolean(compactString(request.confirmed_visit_at));

  // Update the assignment row. Confirmed visits also need confirmed_visit_at
  // shifted to keep the calendar truth in sync — preserve the original
  // hour/minute when shifting.
  await service
    .from("provider_visit_assignments")
    .update({
      route_date: newRouteDate,
      updated_at: isoNow(),
    })
    .eq("id", compactString(assignment.id));

  if (wasConfirmed) {
    const oldConfirmed = new Date(compactString(request.confirmed_visit_at));
    if (!Number.isNaN(oldConfirmed.getTime())) {
      const [yyyy, mm, dd] = newRouteDate.split("-").map((s) => Number(s));
      const newConfirmed = new Date(oldConfirmed);
      newConfirmed.setUTCFullYear(yyyy, mm - 1, dd);
      await service
        .from("handyman_requests")
        .update({
          confirmed_visit_at: newConfirmed.toISOString(),
          updated_at: isoNow(),
        })
        .eq("id", requestId);
    }
  }

  // Audit message — keeps the homeowner thread in sync. Same pattern
  // Wave Y2 used for cross-app parity.
  if (householdId) {
    const dateLabel = (iso: string) => {
      try {
        const d = new Date(`${iso}T12:00:00Z`);
        return d.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" });
      } catch (_) {
        return iso;
      }
    };
    const oldLabel = oldRouteDate ? dateLabel(oldRouteDate) : "an earlier date";
    const newLabel = dateLabel(newRouteDate);
    const visitTitle = compactString(request.title) || "Visit";

    // Note: handyman_request_messages doesn't have a sender_user_id
    // column (only sender_role + body + metadata). Pre-existing
    // inserts elsewhere in this file include sender_user_id silently;
    // PostgREST rejects the insert outright (PGRST204), so we omit it
    // here and stash the actor's user id in metadata instead so it
    // remains queryable for audit.
    await service.from("handyman_request_messages").insert({
      request_id: requestId,
      household_id: householdId,
      sender_role: "vendor",
      body: `${visitTitle} moved from ${oldLabel} to ${newLabel}.`,
      metadata: {
        kind: "visit_rescheduled",
        actor_user_id: userId,
        old_route_date: oldRouteDate || null,
        new_route_date: newRouteDate,
        was_confirmed: wasConfirmed,
      },
    });

    if (wasConfirmed) {
      // Push the homeowner only when the visit was already confirmed —
      // otherwise the desktop drag is just calendar planning the
      // homeowner doesn't need a notification for yet.
      await notifyHomeownersForRequest(service, householdId, {
        title: "Visit moved",
        body: `${visitTitle} is now ${newLabel}.`,
        requestId,
        eventType: "handyman_visit_rescheduled",
        extra: { old_route_date: oldRouteDate || null, new_route_date: newRouteDate },
      });
    }
  }

  return {
    ok: true,
    requestId,
    oldRouteDate: oldRouteDate || null,
    newRouteDate,
    wasConfirmed,
  };
}

/**
 * Wave Z.2 — Aggregate task list for the cross-customer Tasks screen.
 *
 * Returns every open punch item across the workspace's customers + every
 * non-archived maintenance_task linked to a workspace-assigned visit.
 * One trip on demand (not part of loadDashboard) so the regular page
 * loads stay lean.
 *
 * Source-of-truth boundaries (how we decide what's "this workspace's"):
 * 1. handyman_punch_items: items whose assigned_visit_task_id appears
 *    on a visit currently assigned to this workspace via
 *    provider_visit_assignments.
 * 2. maintenance_tasks: tasks where task.id is referenced by a
 *    workspace assignment as visit_task_id (i.e., the contractor is
 *    going to work on it).
 *
 * Customer name resolution: punch_items already carry household_id,
 * maintenance_tasks have property_id. We fold both into a
 * household-name lookup pulled from properties + households.
 */
async function fetchAggregateTasks(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  // Find every visit_task_id this workspace is assigned to.
  const { data: assignments, error: aErr } = await service
    .from("provider_visit_assignments")
    .select("request_id, visit_task_id, assigned_member_id, route_date")
    .eq("workspace_id", workspaceId);
  if (aErr) throw aErr;

  const visitTaskIds = [
    ...new Set(
      (assignments ?? [])
        .map((row: Record<string, unknown>) => compactString(row.visit_task_id))
        .filter(Boolean),
    ),
  ];
  const requestIds = [
    ...new Set(
      (assignments ?? [])
        .map((row: Record<string, unknown>) => compactString(row.request_id))
        .filter(Boolean),
    ),
  ];

  // Member→tech-name index for the "By tech" filter.
  const { data: members } = await service
    .from("provider_workspace_members")
    .select("id, full_name, email")
    .eq("workspace_id", workspaceId);
  const memberIndex = new Map<string, string>();
  for (const row of (members ?? []) as Record<string, unknown>[]) {
    const name = compactString(row.full_name) || compactString(row.email) || "Tech";
    memberIndex.set(compactString(row.id), name);
  }
  const visitTechByVisitTaskId = new Map<string, string>();
  for (const row of (assignments ?? []) as Record<string, unknown>[]) {
    const vt = compactString(row.visit_task_id);
    const am = compactString(row.assigned_member_id);
    if (vt && am) {
      visitTechByVisitTaskId.set(vt, memberIndex.get(am) || "Tech");
    }
  }

  // Fetch maintenance tasks + punch items in parallel.
  const [tasksResult, punchResult] = await Promise.all([
    visitTaskIds.length
      ? service
          .from("maintenance_tasks")
          .select(
            "id, title, priority, scheduled_date, next_due_date, property_id, household_id, assignment_type, is_archived, last_completed_date, parent_routine_id, notes",
          )
          .in("id", visitTaskIds)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    visitTaskIds.length
      ? service
          .from("handyman_punch_items")
          .select(
            "id, household_id, property_id, assigned_visit_task_id, title, description, source, status, priority, estimated_minutes, estimated_cost_range, completed_at, archived_at, created_at, updated_at",
          )
          .in("assigned_visit_task_id", visitTaskIds)
          .is("archived_at", null)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
  ]);
  if (tasksResult.error) throw tasksResult.error;
  if (punchResult.error) throw punchResult.error;

  const tasks = (tasksResult.data ?? []) as Record<string, unknown>[];
  const punchItems = (punchResult.data ?? []) as Record<string, unknown>[];

  // Resolve customer names. We need property_id → property.name and
  // household_id → primary contact name (fall back to property name).
  const propertyIds = [
    ...new Set(
      [
        ...tasks.map((row) => compactString(row.property_id)),
        ...punchItems.map((row) => compactString(row.property_id)),
      ].filter(Boolean),
    ),
  ];
  const householdIds = [
    ...new Set(
      [
        ...tasks.map((row) => compactString(row.household_id)),
        ...punchItems.map((row) => compactString(row.household_id)),
      ].filter(Boolean),
    ),
  ];

  const [propertiesResult, requestsResult] = await Promise.all([
    propertyIds.length
      ? service
          .from("properties")
          .select("id, name, household_id, street, city, state")
          .in("id", propertyIds)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    requestIds.length
      ? service
          .from("handyman_requests")
          .select("id, household_id, property_id, title, visit_task_id")
          .in("id", requestIds)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
  ]);

  const propertyById = new Map<string, Record<string, unknown>>();
  for (const row of (propertiesResult.data ?? []) as Record<string, unknown>[]) {
    propertyById.set(compactString(row.id), row);
  }

  // Customer label resolution: prefer property.name (e.g. "Burke Residence"),
  // fall back to street, then "Customer" placeholder.
  function customerLabel(propertyId: string, householdId: string): string {
    const p = propertyById.get(propertyId);
    if (p) {
      const name = compactString(p.name);
      if (name) return name;
      const street = compactString(p.street);
      if (street) return street;
    }
    if (householdId) return "Customer";
    return "Customer";
  }

  // Source label friendly for UI.
  function sourceKindLabel(source: string): string {
    switch (source) {
      case "manual": return "Manual punch item";
      case "promoted_from_task": return "Promoted from task";
      case "migrated_from_task": return "Migrated from task";
      case "auto_seed_handyman_tier": return "Routed to contractor";
      case "recommended": return "Recommended service";
      case "template": return "Template-seeded";
      default: return source.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
    }
  }

  // Map punch items.
  const aggregatePunch = punchItems.map((row) => {
    const propertyId = compactString(row.property_id);
    const householdId = compactString(row.household_id);
    const visitTaskId = compactString(row.assigned_visit_task_id);
    const status = compactString(row.status) || "pending";
    return {
      id: `pi:${compactString(row.id)}`,
      source: "punch_item" as const,
      title: compactString(row.title) || "Untitled item",
      customerName: customerLabel(propertyId, householdId),
      customerPropertyId: propertyId,
      estimatedMinutes: numberValue(row.estimated_minutes) || null,
      dueDate: null as string | null,
      status: ["pending", "in_progress", "done", "cancelled"].includes(status) ? status : "pending",
      visitTaskId: visitTaskId || null,
      sourceKindLabel: sourceKindLabel(compactString(row.source)),
      assignedTechName: visitTaskId ? visitTechByVisitTaskId.get(visitTaskId) || null : null,
      rawId: compactString(row.id),
    };
  });

  // Map maintenance tasks. Only show tasks whose status is meaningful
  // and not archived. Treat is_archived === true as filtered out.
  const aggregateTasks = tasks
    .filter((row) => row.is_archived !== true)
    .map((row) => {
      const propertyId = compactString(row.property_id);
      const householdId = compactString(row.household_id);
      const taskId = compactString(row.id);
      const due = compactString(row.scheduled_date) || compactString(row.next_due_date) || null;
      const completed = Boolean(compactString(row.last_completed_date));
      // Project the row to a UI status. maintenance_tasks doesn't carry
      // pending/in_progress like punch items — derive from completion.
      const uiStatus = completed ? "done" : "pending";
      return {
        id: `mt:${taskId}`,
        source: "maintenance_task" as const,
        title: compactString(row.title) || "Untitled task",
        customerName: customerLabel(propertyId, householdId),
        customerPropertyId: propertyId,
        estimatedMinutes: null as number | null,
        dueDate: due,
        status: uiStatus,
        visitTaskId: taskId,
        sourceKindLabel: "Visit task",
        assignedTechName: visitTechByVisitTaskId.get(taskId) || null,
        rawId: taskId,
      };
    });

  // Sort: open first (by dueDate asc, nulls last), then completed.
  function statusOrder(s: string): number {
    if (s === "done" || s === "cancelled") return 1;
    return 0;
  }
  const all = [...aggregatePunch, ...aggregateTasks];
  all.sort((a, b) => {
    const so = statusOrder(a.status) - statusOrder(b.status);
    if (so !== 0) return so;
    if (a.dueDate && b.dueDate) return a.dueDate.localeCompare(b.dueDate);
    if (a.dueDate) return -1;
    if (b.dueDate) return 1;
    return a.title.localeCompare(b.title);
  });

  // Note: requestsResult is fetched in the parallel Promise.all above
  // because future iterations may need request titles for grouping.
  // Not used in v1 output — referenced here so unused-var lint doesn't
  // fire and to make the intent visible at the boundary.
  void requestsResult;

  return { tasks: all };
}

function buildFieldSystemSeed(system: Record<string, unknown>) {
  const category = compactString(system.category) || "Other";
  return {
    id: compactString(system.id) || crypto.randomUUID(),
    system_id: compactString(system.id) || null,
    name: compactString(system.name) || category,
    category,
    manufacturer: compactString(system.manufacturer) || null,
    model_number: compactString(system.model_number) || null,
    serial_number: compactString(system.serial_number) || null,
    install_date: compactString(system.install_date) || null,
    notes: compactString(system.notes) || null,
    last_service_date: compactString(system.last_service_date) || null,
    next_service_due: compactString(system.next_service_due) || null,
    subtype: compactString(system.subtype) || null,
    catalog_series: compactString(system.catalog_series) || null,
    catalog_model_name: compactString(system.catalog_model_name) || null,
    catalog_fuel_type: compactString(system.catalog_fuel_type) || null,
    catalog_features: Array.isArray(system.catalog_features)
      ? system.catalog_features.map((feature) => compactString(feature)).filter(Boolean)
      : [],
    reliability_score: numberValue(system.reliability_score || 0) || null,
    score_summary: compactString(system.score_summary) || null,
    cached_manual_links: Array.isArray(system.cached_manual_links)
      ? system.cached_manual_links
      : [],
    needs_setup:
      !compactString(system.model_number) ||
      !compactString(system.serial_number),
    serviced: false,
  };
}

function buildAdHocSeedPayload(params: {
  visitId: string;
  title: string;
  scheduledDate: string;
  property: Record<string, unknown>;
  systems: Record<string, unknown>[];
  companyName: string;
  contactEmail: string;
  contactPhone: string;
  details: string;
}) {
  const seededSystems = params.systems.map(buildFieldSystemSeed);
  const knownSystems = [
    ...new Set(
      seededSystems
        .map((system) => compactString(system.category))
        .filter(Boolean),
    ),
  ];
  const firstVisit = seededSystems.length === 0;

  return {
    visitId: params.visitId,
    visitTitle: params.title,
    scheduledDate: params.scheduledDate,
    dueDate: params.scheduledDate,
    firstVisit,
    property: {
      name: compactString(params.property.name) || "Home",
      addressLine: addressLine([
        params.property.street,
        params.property.city,
        params.property.state,
        params.property.zip_code,
      ]),
      propertyType: compactString(params.property.property_type) || "Home",
      squareFootage: numberValue(params.property.square_feet || params.property.squareFootage || 0) || null,
      yearBuilt: numberValue(params.property.year_built || params.property.yearBuilt || 0) || null,
      systemCount: seededSystems.length,
      knownSystems,
      systems: seededSystems,
    },
    contractorName: params.companyName || "Chez Field",
    contractorPhone: params.contactPhone || null,
    contractorEmail: params.contactEmail || null,
    homeownerNotes: params.details || "",
    checklist: [
      {
        id: "adhoc-1",
        title: "Review scope and homeowner priorities",
        subtitle: "Confirm what should be handled during this stop.",
        category: "visit",
        status: "todo",
        source: "included",
        recommended: false,
      },
      {
        id: "adhoc-2",
        title: "Capture model labels for anything you touch",
        subtitle: "Use label photos so the next visit starts with the right parts and context.",
        category: "systems",
        status: "todo",
        source: "included",
        recommended: false,
      },
      {
        id: "adhoc-3",
        title: "Leave service notes for the next visit",
        subtitle: "Record practical notes, filters, shutoffs, or materials needed next time.",
        category: "notes",
        status: "todo",
        source: "included",
        recommended: false,
      },
    ],
    diyClaims: [],
    quickUpsells: [],
    setupPrompts: firstVisit
      ? [
          {
            id: "setup-1",
            title: "Inventory major systems and appliances",
            detail: "Add the key systems this home will rely on so future visits are faster.",
            category: "inventory",
            isRequired: true,
          },
          {
            id: "setup-2",
            title: "Capture model and serial labels",
            detail: "Prioritize HVAC, water heater, laundry, kitchen appliances, and electrical panels.",
            category: "labels",
            isRequired: true,
          },
        ]
      : [],
    coordination: {
      request_id: null,
      status: "confirmed",
      status_label: requestStatusLabel("confirmed"),
      intro: "This ad hoc visit is confirmed and ready to start.",
      last_message: params.details || null,
      scheduled_date: params.scheduledDate,
      request_title: params.title,
      needs_homeowner_reply: false,
    },
    recommendations: [],
  };
}

async function createAdHocVisit(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);

  const propertyId = compactString(body.propertyId);
  if (!propertyId) throw new Error("Missing home");

  const title = compactString(body.title) || "Ad hoc visit";
  const details = compactString(body.details || body.notes);
  const requestType = compactString(body.requestType) || "standard_visit";
  if (!["standard_visit", "quote", "repair", "install", "assembly", "question", "setup"].includes(requestType)) {
    throw new Error("Invalid visit type");
  }

  const { data: property, error: propertyError } = await service
    .from("properties")
    .select("id, household_id, name, street, city, state, zip_code, property_type, square_footage, year_built, time_zone")
    .eq("id", propertyId)
    .limit(1)
    .maybeSingle();

  if (propertyError) throw propertyError;
  if (!property) throw new Error("Home not found");

  // Sprint #4 R4-E-2 fix: when scheduledDate is provided, normalize via
  // localDateString (passes through YYYY-MM-DD strings unchanged); when
  // omitted, default to "today" in the property's local time zone, not
  // UTC, so a 9 PM EDT ad hoc add doesn't land on tomorrow's calendar.
  const scheduledDate = (() => {
    const explicit = compactString(body.scheduledDate);
    if (explicit) return localDateString(explicit);
    const tz = compactString(property.time_zone) || FIELD_DEFAULT_TIMEZONE;
    return fieldFormatYmdInZone(new Date(), tz);
  })();

  const householdId = compactString(property.household_id);
  if (!householdId) throw new Error("This home is missing a household record");

  const workspace = (membership.provider_workspaces as Record<string, unknown> | undefined) ?? {};
  const companyName = compactString(workspace.company_name) || "Chez Field";
  const contactEmail = compactString(membership.email) || compactString(workspace.primary_email);
  const contactPhone = compactString(membership.phone) || compactString(workspace.primary_phone);

  const contractorId = await ensureHouseholdContractorForWorkspace(service, {
    workspaceId,
    householdId,
    companyName,
    contactName: compactString(membership.full_name) || companyName,
    email: contactEmail,
    phone: contactPhone,
    website: compactString(workspace.website),
    claimSource: "manual",
  });

  const { data: systems, error: systemsError } = await service
    .from("home_systems")
    .select("id, name, category, manufacturer, model_number, serial_number, notes, install_date, subtype, catalog_series, catalog_model_name, catalog_fuel_type, catalog_features, reliability_score, score_summary, last_service_date, next_service_due, cached_manual_links")
    .eq("property_id", propertyId);

  if (systemsError) throw systemsError;

  const { data: visitTask, error: taskError } = await service
    .from("maintenance_tasks")
    .insert({
      property_id: propertyId,
      household_id: householdId,
      title,
      description: details || null,
      frequency: "Once",
      next_due_date: scheduledDate,
      priority: compactString(body.priority) || "Medium",
      assigned_contractor_id: contractorId || null,
      notes: details || null,
      assignment_type: "vendor",
      needs_vendor: false,
      scheduled_date: scheduledDate,
      assigned_route: "handyman",
      service_key: "handyman:field-ad-hoc",
    })
    .select("id, title, scheduled_date, next_due_date")
    .single();

  if (taskError || !visitTask) throw taskError ?? new Error("Could not create visit");

  const { data: request, error: requestError } = await service
    .from("handyman_requests")
    .insert({
      household_id: householdId,
      property_id: propertyId,
      contractor_id: contractorId || null,
      visit_task_id: compactString(visitTask.id),
      created_by_user_id: userId,
      request_type: requestType,
      source: "field",
      title,
      details: details || null,
      preferred_timing: scheduledDate,
      urgency: compactString(body.urgency) || "routine",
      status: "confirmed",
      first_visit_setup_requested: (systems ?? []).length === 0,
      recommended_lane: requestType,
      quick_upsell_titles: [],
    })
    .select()
    .single();

  if (requestError || !request) throw requestError ?? new Error("Could not create request");

  const portalToken = crypto.randomUUID();
  const seedPayload = buildAdHocSeedPayload({
    visitId: compactString(visitTask.id),
    title,
    scheduledDate,
    property: property as Record<string, unknown>,
    systems: (systems ?? []) as Record<string, unknown>[],
    companyName,
    contactEmail,
    contactPhone,
    details,
  });

  const { error: sessionError } = await service
    .from("handyman_portal_sessions")
    .insert({
      household_id: householdId,
      property_id: propertyId,
      contractor_id: contractorId || null,
      visit_task_id: compactString(visitTask.id),
      created_by_user_id: userId,
      title,
      portal_token: portalToken,
      status: "active",
      first_visit: (systems ?? []).length === 0,
      seed_payload: seedPayload,
    });

  if (sessionError) throw sessionError;

  const { error: assignmentError } = await service
    .from("provider_visit_assignments")
    .upsert(
      {
        workspace_id: workspaceId,
        request_id: compactString(request.id),
        visit_task_id: compactString(visitTask.id),
        assigned_member_id: compactString(membership.id) || null,
        assigned_by_user_id: userId,
        route_date: scheduledDate,
        updated_at: isoNow(),
      },
      { onConflict: "workspace_id,request_id" },
    );

  if (assignmentError) throw assignmentError;

  await service.from("handyman_request_messages").insert({
    request_id: compactString(request.id),
    household_id: householdId,
    sender_role: "vendor",
    body: details || `${title} was added from Chez Field.`,
    metadata: {
      event: "ad_hoc_visit_created",
      source: "field",
    },
  });

  return {
    requestId: compactString(request.id),
    visitTaskId: compactString(visitTask.id),
    portalToken,
    portalUrl: fieldVisitUrl(portalToken, compactString(visitTask.id)),
    scheduledDate,
    title,
    propertyId,
  };
}

function serializePairingRequest(row: Record<string, unknown>, companyName: string) {
  const accessCode = compactString(row.access_code);
  const homeName = compactString(row.home_name) || "This home";
  const homeownerName = compactString(row.homeowner_name) || "the homeowner";
  return {
    id: compactString(row.id),
    status: compactString(row.status) || "pending_homeowner",
    accessCode,
    homeName,
    homeownerName,
    address: addressLine([row.address_line, row.city, row.state, row.postal_code]),
    shareText: `Download Chez and use pairing code ${accessCode} to connect ${homeName} with ${companyName}. If you already have Chez, ask support to add this contractor using the code ${accessCode}.`,
  };
}

async function createPairingRequest(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);

  const homeName = compactString(body.homeName || body.propertyName);
  const homeownerEmail = normalizedEmail(body.homeownerEmail);
  const homeownerPhone = compactString(body.homeownerPhone);
  if (!homeName) throw new Error("Home name is required");
  if (!homeownerEmail && !homeownerPhone) {
    throw new Error("Add a homeowner email or phone so the pairing request has a real destination");
  }

  const workspace = (membership.provider_workspaces as Record<string, unknown> | undefined) ?? {};
  const companyName = compactString(workspace.company_name) || "Chez Field";
  const accessCode = shortAccessCode("CHEZ");

  const { data, error } = await service
    .from("provider_home_pairing_requests")
    .insert({
      workspace_id: workspaceId,
      created_by_user_id: userId,
      homeowner_name: compactString(body.homeownerName) || null,
      homeowner_email: homeownerEmail || null,
      homeowner_phone: compactString(body.homeownerPhone) || null,
      home_name: homeName,
      address_line: compactString(body.addressLine) || null,
      city: compactString(body.city) || null,
      state: compactString(body.state) || null,
      postal_code: compactString(body.postalCode) || null,
      notes: compactString(body.notes) || null,
      access_code: accessCode,
      status: "pending_homeowner",
    })
    .select()
    .single();

  if (error || !data) throw error ?? new Error("Could not create pairing request");

  return {
    pairingRequest: serializePairingRequest(data as Record<string, unknown>, companyName),
  };
}

async function saveQuote(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
  sendNow: boolean,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canBuildQuotes");

  const quoteId = compactString(body.quoteId);
  const existingQuote = quoteId
    ? await service
        .from("provider_quotes")
        .select("*")
        .eq("id", quoteId)
        .eq("workspace_id", workspaceId)
        .limit(1)
        .maybeSingle()
    : { data: null, error: null };
  if (existingQuote.error) throw existingQuote.error;

  // Phase 74b: when the client passes only a quoteId (e.g. send_quote
  // re-firing on a draft), `body.lineItems` is missing — fall back to
  // whatever the existing row already has so the second mutation
  // doesn't blow up "at least one line item required".
  const incomingLineItems = Array.isArray(body.lineItems)
    ? (body.lineItems as Array<Record<string, unknown>>)
    : null;
  const fallbackLineItems = Array.isArray(existingQuote.data?.line_items)
    ? (existingQuote.data!.line_items as Array<Record<string, unknown>>)
    : [];
  const sourceLineItems = incomingLineItems ?? fallbackLineItems;
  const lineItems = sourceLineItems
    .map((item) => {
      // Wave M4 — preserve punch_item_id so the operator desk can
      // render "this line covers <punch item title>" + the photos
      // when the line was pre-filled from the BuildQuoteSheet.
      const punchItemId = compactString(item.punch_item_id ?? item.punchItemId) || null;
      const base: Record<string, unknown> = {
        id: compactString(item.id) || crypto.randomUUID(),
        name: compactString(item.name),
        description: compactString(item.description),
        unit: compactString(item.unit) || "ea",
        quantity: numberValue(item.quantity || 1),
        unit_price: numberValue(item.unitPrice || item.unit_price || 0),
      };
      if (punchItemId) base.punch_item_id = punchItemId;
      return base;
    })
    .filter((item) => item.name);
  const totals = quoteSummary(lineItems);
  const now = isoNow();

  const requestId = compactString(body.requestId) || null;
  let visitTaskId = compactString(body.visitTaskId) || compactString(existingQuote.data?.visit_task_id) || null;
  let contractorId = compactString(body.contractorId) || compactString(existingQuote.data?.contractor_id) || null;
  let householdId = compactString(body.householdId) || compactString(existingQuote.data?.household_id);
  let propertyId = compactString(body.propertyId) || compactString(existingQuote.data?.property_id);
  let title = compactString(body.title);
  const homeownerMessage = compactString(body.homeownerMessage);
  const scopeNotes = compactString(body.scopeNotes);
  let prospectName = compactString(body.prospectName) || compactString(existingQuote.data?.prospect_name);
  let prospectEmail = normalizedEmail(body.prospectEmail) || normalizedEmail(existingQuote.data?.prospect_email);
  const prospectPhone = compactString(body.prospectPhone) || compactString(existingQuote.data?.prospect_phone);
  const prospectAddress = compactString(body.prospectAddress) || compactString(existingQuote.data?.prospect_address);

  if (requestId) {
    const { data: request } = await service
      .from("handyman_requests")
      .select("id, household_id, property_id, contractor_id, visit_task_id, title")
      .eq("id", requestId)
      .limit(1)
      .maybeSingle();
    if (request) {
      householdId = compactString(request.household_id) || householdId;
      propertyId = compactString(request.property_id) || propertyId;
      contractorId = compactString(request.contractor_id) || contractorId;
      visitTaskId = compactString(request.visit_task_id) || visitTaskId;
      title = title || `Quote for ${compactString(request.title)}`;
    }
  }

  const recipientKind = quoteRecipientKind(householdId);
  title = title || (recipientKind === "prospect" && prospectName ? `Quote for ${prospectName}` : "Untitled quote");

  if (!workspaceId || lineItems.length === 0) {
    throw new Error("Workspace and at least one line item are required");
  }

  if (recipientKind === "linked_home" && !householdId) {
    throw new Error("Choose a Chez client request before sending this quote to a home");
  }

  if (sendNow && recipientKind === "prospect" && !prospectEmail) {
    throw new Error("A prospect email is required to send a standalone quote");
  }

  const basePayload = {
    workspace_id: workspaceId,
    contractor_id: contractorId,
    household_id: householdId || null,
    property_id: propertyId || null,
    request_id: requestId,
    visit_task_id: visitTaskId,
    title,
    recipient_kind: recipientKind,
    prospect_name: recipientKind === "prospect" ? prospectName || null : null,
    prospect_email: recipientKind === "prospect" ? prospectEmail || null : null,
    prospect_phone: recipientKind === "prospect" ? prospectPhone || null : null,
    prospect_address: recipientKind === "prospect" ? prospectAddress || null : null,
    status: sendNow ? "draft" : compactString(body.status) || "draft",
    currency: "USD",
    line_items: lineItems,
    scope_notes: scopeNotes || null,
    homeowner_message: homeownerMessage || null,
    subtotal: totals.subtotal,
    tax_total: totals.taxTotal,
    total: totals.total,
    updated_by_user_id: userId,
    updated_at: now,
    sent_at: sendNow ? null : existingQuote.data?.sent_at ?? null,
    last_sent_at: existingQuote.data?.last_sent_at ?? null,
    sent_via: existingQuote.data?.sent_via ?? [],
    viewed_at: sendNow ? null : existingQuote.data?.viewed_at ?? null,
    approved_at: sendNow ? null : existingQuote.data?.approved_at ?? null,
    declined_at: sendNow ? null : existingQuote.data?.declined_at ?? null,
  };

  const mutation = quoteId
    ? service.from("provider_quotes").update(basePayload).eq("id", quoteId).select().single()
    : service.from("provider_quotes").insert({
        ...basePayload,
        created_by_user_id: userId,
        // Phase 72b made `public_share_token` NOT NULL with no default.
        // The Phase 73b counter path was patched to populate it; the
        // primary save_quote path was missed and threw 500 on every
        // new draft. Mint one here on insert so saving a fresh quote
        // works end-to-end.
        public_share_token: crypto.randomUUID(),
      }).select().single();

  const { data: initialQuote, error } = await mutation;
  if (error || !initialQuote) throw error ?? new Error("Failed to save quote");

  let quote = initialQuote as Record<string, unknown>;
  let delivery: Record<string, unknown> | null = null;

  let propertyName = "";
  let propertyAddress = "";
  if (propertyId) {
    const { data: property } = await service
      .from("properties")
      .select("name, street, city, state, zip_code")
      .eq("id", propertyId)
      .limit(1)
      .maybeSingle();
    propertyName = compactString(property?.name);
    propertyAddress = [property?.street, property?.city, property?.state, property?.zip_code]
      .map((value) => compactString(value))
      .filter(Boolean)
      .join(", ");
  }

  if (sendNow) {
    // The in-app channel (iOS Handyman tab chat thread + the public
    // quote page) is always available — that's our source of truth.
    // Email is best-effort; if SendGrid trips or the homeowner has no
    // email on file we still want the quote to land. Mark it sent,
    // post to chat, then try email after.
    const shareUrl = publicQuoteUrl(compactString(quote.public_share_token));
    const bodyText = providerQuoteMessageBody(title, totals.total, lineItems.length, homeownerMessage);

    const { data: sentQuote, error: sentError } = await service
      .from("provider_quotes")
      .update({
        status: "sent",
        sent_at: now,
        last_sent_at: now,
        sent_via: ["in_app"],
        viewed_at: null,
        approved_at: null,
        declined_at: null,
        updated_by_user_id: userId,
        updated_at: now,
      })
      .eq("id", compactString(quote.id))
      .select()
      .single();
    if (sentError || !sentQuote) throw sentError ?? new Error("Failed to finalize quote send");
    quote = sentQuote as Record<string, unknown>;

    await addQuoteMessage(service, {
      workspaceId,
      quoteId: compactString(quote.id),
      requestId,
      householdId,
      senderRole: "provider",
      senderName: compactString(membership.full_name) || compactString(user.email),
      senderEmail: compactString(user.email),
      deliveryChannel: "in_app",
      body: bodyText,
      metadata: {
        event: "quote_sent",
        total: totals.total,
        lineItemCount: lineItems.length,
        shareUrl,
      },
    });

    if (requestId) {
      await service
        .from("handyman_requests")
        .update({
          status: "quoted",
          updated_at: now,
        })
        .eq("id", requestId);

      // Mirror the quote-sent into the request chat thread so the
      // homeowner's iOS Handyman tab renders a rich quote card with a
      // "Review quote" CTA. `kind: "quote_sent"` is the new
      // discriminator iOS reads alongside the existing event field.
      await mirrorQuoteMessageToRequestThread(service, {
        requestId,
        householdId,
        senderRole: "vendor",
        body: bodyText,
        metadata: {
          kind: "quote_sent",
          event: "quote_sent",
          quote_id: compactString(quote.id),
          total: totals.total,
          line_item_count: lineItems.length,
          share_url: shareUrl,
        },
      });
    }

    // Push notification so the homeowner doesn't have to be in the
    // app to know a quote landed. Routes to Tasks → Handyman → quote
    // review per the handyman_* push deep-link handler.
    if (householdId) {
      await notifyHomeownersForRequest(service, householdId, {
        title: `${propertyName ? "Quote ready for " + propertyName : "Quote ready"}`,
        body: `${moneyLabel(totals.total)} from your contractor. Tap to review.`,
        requestId: requestId || compactString(quote.id),
        eventType: "handyman_quote_sent",
        extra: { quote_id: compactString(quote.id) },
      });
    }

    // Cross-app parity: when a quote is sent WITHOUT a linked request
    // (ad-hoc quote to a Chez homeowner, e.g. from the Quotes screen
    // not tied to an existing visit), the mirrorQuoteMessageToRequestThread
    // call above no-ops (it requires both requestId and householdId).
    // Without an inbox row the homeowner has no in-app surface for the
    // quote — only a push notification, which iOS-less homeowners and
    // anyone who's missed the push will never see. Drop a best-effort
    // inbox_items row so the quote appears in their universal inbox.
    if (householdId && !requestId) {
      try {
        const summary = title
          ? `Quote: ${title} · ${moneyLabel(totals.total)}`
          : `New quote: ${moneyLabel(totals.total)}`;
        // Wave Y2 — stamp metadata so iOS can deep-link from the
        // homeowner's inbox row to the underlying provider_quotes row.
        await service.from("inbox_items").insert({
          household_id: householdId,
          type: "handyman_quote_received",
          title: propertyName ? `Quote ready for ${propertyName}` : "Quote ready",
          summary,
          from_email: compactString(user.email),
          seen: false,
          metadata: {
            quote_id: compactString(quote.id),
            property_id: compactString(propertyId),
            total: totals.total,
            quote_kind: compactString(quote.kind),
          },
        });
      } catch (inboxErr) {
        console.error("[handyman-provider] inbox_items insert failed for ad-hoc quote", inboxErr);
      }
    }

    // Email is additive — try it but never let a failure roll back
    // the in-app send. Update sent_via best-effort to record the
    // channel that worked.
    delivery = await sendQuoteEmail(service, {
      quote,
      workspaceId,
      lineItems,
      propertyName,
      propertyAddress,
      title,
      homeownerMessage,
      scopeNotes,
      total: totals.total,
    }).catch((deliveryError) => ({
      sent: false,
      channel: "email",
      recipientCount: 0,
      error: deliveryError instanceof Error ? deliveryError.message : String(deliveryError),
    }));

    if (delivery.sent) {
      await service
        .from("provider_quotes")
        .update({ sent_via: ["in_app", "email"], updated_at: isoNow() })
        .eq("id", compactString(quote.id));
    }
  }

  return { quote, delivery };
}

// ─── Wave V.1 — quote bundles (good/better/best) ─────────────────
//
// A "bundle" is a parent quote with N child quotes. The parent's row
// is a wrapper: it holds the shared title, scope, homeowner_message,
// recipient context, and a sentinel string in scope_notes
// (BUNDLE_MARKER followed by JSON metadata) so the SPA can identify
// it. Each child has parent_quote_id pointing at the parent and
// carries the actual line items + per-tier total. Tier label rides
// in the child title as " · Good" / " · Better" / " · Best" suffix.
//
// On the homeowner side, the iOS app sees ONE message in the chat
// thread (the parent's "quote_bundle_sent" event) with a list of
// children attached so it can render a 3-card picker. When the
// homeowner picks a tier, decide_quote_bundle flips the chosen
// child to 'approved', the others to 'superseded', and stamps the
// parent with chosen-tier breadcrumb in scope_notes.
//
// This implementation deliberately reuses the existing schema
// (parent_quote_id from Phase 73b) without a migration. Encoding the
// bundle metadata in scope_notes keeps the row layout backward-
// compatible with every existing single-tier read path.

const BUNDLE_MARKER = "[CHEZ_QUOTE_BUNDLE]";

interface BundleTier {
  label: string;
  lineItems: Array<Record<string, unknown>>;
  scopeNotes?: string;
}

interface BundleMeta {
  bundle: true;
  tiers: string[];
  chosenChildId?: string | null;
  chosenTierLabel?: string | null;
}

function buildBundleScopeNotes(meta: BundleMeta, baseScope: string | null): string {
  // Marker on the FIRST line so the SPA can detect it even if the
  // contractor types into the scope-notes field. The marker carries
  // its own JSON payload after a colon. The contractor-authored scope
  // (if any) trails on its own line below.
  const json = JSON.stringify(meta);
  const marker = `${BUNDLE_MARKER}:${json}`;
  return baseScope ? `${marker}\n${baseScope}` : marker;
}

function parseBundleScopeNotes(scopeNotes: string | null | undefined): {
  meta: BundleMeta | null;
  authorScope: string;
} {
  const text = compactString(scopeNotes);
  if (!text.startsWith(BUNDLE_MARKER + ":")) return { meta: null, authorScope: text };
  const newlineIdx = text.indexOf("\n");
  const markerLine = newlineIdx >= 0 ? text.slice(0, newlineIdx) : text;
  const trailing = newlineIdx >= 0 ? text.slice(newlineIdx + 1) : "";
  const jsonStr = markerLine.slice(BUNDLE_MARKER.length + 1);
  try {
    const meta = JSON.parse(jsonStr) as BundleMeta;
    if (meta && meta.bundle === true && Array.isArray(meta.tiers)) {
      return { meta, authorScope: trailing };
    }
  } catch {
    // fall through
  }
  return { meta: null, authorScope: text };
}

async function saveQuoteBundle(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
  sendNow: boolean,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canBuildQuotes");

  // Wave V.1 — re-send path for an existing draft bundle. The contractor
  // saved the bundle as draft earlier, then clicked Send on the detail
  // panel. Skip the insert flow entirely and just walk parent +
  // children, flip status to sent, and fire the chat / push.
  const bundleId = compactString(body.bundleId);
  if (bundleId) {
    return await sendExistingBundle(service, user, membership, bundleId);
  }

  const tiersRaw = Array.isArray(body.tiers) ? (body.tiers as Array<Record<string, unknown>>) : [];
  const tiers: BundleTier[] = tiersRaw
    .map((t) => ({
      label: compactString(t.label) || "Option",
      lineItems: Array.isArray(t.lineItems)
        ? (t.lineItems as Array<Record<string, unknown>>).map((item) => {
            // Wave M4 — preserve punch_item_id so the operator desk
            // can render "this line covers <punch item title>" + the
            // photos when the line was pre-filled from the iOS
            // BuildQuoteSheet. Without this, bundles strip the
            // cross-link and the operator only sees a name.
            const punchItemId = compactString(item.punch_item_id ?? item.punchItemId) || null;
            const base: Record<string, unknown> = {
              id: compactString(item.id) || crypto.randomUUID(),
              name: compactString(item.name),
              description: compactString(item.description),
              unit: compactString(item.unit) || "ea",
              quantity: numberValue(item.quantity || 1),
              unit_price: numberValue(item.unitPrice || item.unit_price || 0),
            };
            if (punchItemId) base.punch_item_id = punchItemId;
            return base;
          }).filter((item) => item.name)
        : [],
      scopeNotes: compactString(t.scopeNotes) || undefined,
    }))
    .filter((t) => t.lineItems.length > 0);

  if (tiers.length < 2) {
    throw new Error("A quote bundle needs at least two tiers. Use save_quote for a single-tier quote.");
  }
  if (tiers.length > 4) {
    throw new Error("A quote bundle is capped at four tiers (Good / Better / Best is plenty).");
  }

  // Pre-compute totals per tier for response shaping.
  const tierTotals = tiers.map((t) => quoteSummary(t.lineItems));

  const requestId = compactString(body.requestId) || null;
  const propertyId = compactString(body.propertyId) || null;
  let householdId = compactString(body.householdId) || null;
  let contractorId = compactString(body.contractorId) || null;
  let visitTaskId = compactString(body.visitTaskId) || null;
  let parentTitle = compactString(body.title);
  const parentHomeownerMessage = compactString(body.homeownerMessage);
  const parentScopeNotes = compactString(body.scopeNotes);
  const prospectName = compactString(body.prospectName);
  const prospectEmail = normalizedEmail(body.prospectEmail);
  const prospectPhone = compactString(body.prospectPhone);
  const prospectAddress = compactString(body.prospectAddress);

  if (requestId) {
    const { data: request } = await service
      .from("handyman_requests")
      .select("id, household_id, property_id, contractor_id, visit_task_id, title")
      .eq("id", requestId)
      .limit(1)
      .maybeSingle();
    if (request) {
      householdId = compactString(request.household_id) || householdId;
      contractorId = compactString(request.contractor_id) || contractorId;
      visitTaskId = compactString(request.visit_task_id) || visitTaskId;
      parentTitle = parentTitle || `Quote for ${compactString(request.title)}`;
    }
  }

  const recipientKind = quoteRecipientKind(householdId);
  parentTitle =
    parentTitle ||
    (recipientKind === "prospect" && prospectName ? `Quote for ${prospectName}` : "Untitled quote");

  if (recipientKind === "linked_home" && !householdId) {
    throw new Error("Choose a Chez client request before sending this quote to a home");
  }
  if (sendNow && recipientKind === "prospect" && !prospectEmail) {
    throw new Error("A prospect email is required to send a standalone quote");
  }

  const now = isoNow();

  // Bundle parent: holds the wrapper. line_items stays empty, total is
  // 0 (UI reads tier totals off the children). scope_notes carries
  // the BUNDLE_MARKER + tier list so the SPA can identify it.
  const parentBundleMeta: BundleMeta = {
    bundle: true,
    tiers: tiers.map((t) => t.label),
  };
  const parentScopeWithMarker = buildBundleScopeNotes(parentBundleMeta, parentScopeNotes || null);

  const parentPayload = {
    workspace_id: workspaceId,
    contractor_id: contractorId,
    household_id: householdId || null,
    property_id: propertyId,
    request_id: requestId,
    visit_task_id: visitTaskId,
    title: parentTitle,
    recipient_kind: recipientKind,
    prospect_name: recipientKind === "prospect" ? prospectName || null : null,
    prospect_email: recipientKind === "prospect" ? prospectEmail || null : null,
    prospect_phone: recipientKind === "prospect" ? prospectPhone || null : null,
    prospect_address: recipientKind === "prospect" ? prospectAddress || null : null,
    status: "draft",
    currency: "USD",
    line_items: [],
    scope_notes: parentScopeWithMarker,
    homeowner_message: parentHomeownerMessage || null,
    subtotal: 0,
    tax_total: 0,
    total: 0,
    created_by_user_id: userId,
    updated_by_user_id: userId,
    updated_at: now,
    public_share_token: crypto.randomUUID(),
  };

  const { data: parentRow, error: parentErr } = await service
    .from("provider_quotes")
    .insert(parentPayload)
    .select()
    .single();
  if (parentErr || !parentRow) throw parentErr ?? new Error("Failed to insert bundle parent");

  // Insert each child with parent_quote_id pointing at the parent.
  // Tier label rides in the title suffix.
  const childRows: Array<Record<string, unknown>> = [];
  for (let i = 0; i < tiers.length; i++) {
    const tier = tiers[i];
    const totals = tierTotals[i];
    const childPayload = {
      workspace_id: workspaceId,
      contractor_id: contractorId,
      household_id: householdId || null,
      property_id: propertyId,
      request_id: requestId,
      visit_task_id: visitTaskId,
      title: `${parentTitle} · ${tier.label}`,
      recipient_kind: recipientKind,
      prospect_name: recipientKind === "prospect" ? prospectName || null : null,
      prospect_email: recipientKind === "prospect" ? prospectEmail || null : null,
      prospect_phone: recipientKind === "prospect" ? prospectPhone || null : null,
      prospect_address: recipientKind === "prospect" ? prospectAddress || null : null,
      status: "draft",
      currency: "USD",
      line_items: tier.lineItems,
      scope_notes: tier.scopeNotes || null,
      homeowner_message: parentHomeownerMessage || null,
      subtotal: totals.subtotal,
      tax_total: totals.taxTotal,
      total: totals.total,
      parent_quote_id: parentRow.id,
      created_by_user_id: userId,
      updated_by_user_id: userId,
      updated_at: now,
      public_share_token: crypto.randomUUID(),
    };
    const { data: childRow, error: childErr } = await service
      .from("provider_quotes")
      .insert(childPayload)
      .select()
      .single();
    if (childErr || !childRow) {
      // Clean up parent + any prior children if a child insert fails so
      // we don't leave an orphan bundle in a half-built state.
      await service.from("provider_quotes").delete().eq("id", parentRow.id);
      for (const prior of childRows) {
        await service.from("provider_quotes").delete().eq("id", compactString(prior.id));
      }
      throw childErr ?? new Error("Failed to insert bundle child");
    }
    childRows.push(childRow as Record<string, unknown>);
  }

  let parent = parentRow as Record<string, unknown>;
  let delivery: Record<string, unknown> | null = null;

  if (sendNow) {
    // Flip parent + every child from draft to sent.
    const sendIds = [parent.id, ...childRows.map((c) => c.id)] as string[];
    const { error: sendErr } = await service
      .from("provider_quotes")
      .update({
        status: "sent",
        sent_at: now,
        last_sent_at: now,
        sent_via: ["in_app"],
        viewed_at: null,
        approved_at: null,
        declined_at: null,
        updated_by_user_id: userId,
        updated_at: now,
      })
      .in("id", sendIds);
    if (sendErr) throw sendErr;

    // Re-read the parent with status flipped.
    const { data: refetched } = await service
      .from("provider_quotes")
      .select("*")
      .eq("id", parent.id)
      .limit(1)
      .maybeSingle();
    if (refetched) parent = refetched as Record<string, unknown>;

    // One in-app message per bundle (not per tier) on the request
    // thread. The metadata.kind discriminator is `quote_bundle_sent`
    // so iOS can render a 3-tier card. The body summarizes the tier
    // range so even a list-only client renders something useful.
    const tierSummary = childRows
      .map((c, i) => `${tiers[i].label}: ${moneyLabel(numberValue(c.total))}`)
      .join(" · ");
    const bodyText = `${parentTitle} is ready with ${tiers.length} options. ${tierSummary}.`;

    await addQuoteMessage(service, {
      workspaceId,
      quoteId: compactString(parent.id),
      requestId,
      householdId: householdId || null,
      senderRole: "provider",
      senderName: compactString(membership.full_name) || compactString(user.email),
      senderEmail: compactString(user.email),
      deliveryChannel: "in_app",
      body: bodyText,
      metadata: {
        event: "quote_bundle_sent",
        kind: "quote_bundle_sent",
        bundle_parent_id: compactString(parent.id),
        tiers: childRows.map((c, i) => ({
          quote_id: compactString(c.id),
          label: tiers[i].label,
          total: numberValue(c.total),
          line_item_count: tiers[i].lineItems.length,
          public_share_url: publicQuoteUrl(compactString(c.public_share_token)),
        })),
      },
    });

    if (requestId) {
      await service
        .from("handyman_requests")
        .update({ status: "quoted", updated_at: now })
        .eq("id", requestId);

      await mirrorQuoteMessageToRequestThread(service, {
        requestId,
        householdId: householdId || null,
        senderRole: "vendor",
        body: bodyText,
        metadata: {
          kind: "quote_bundle_sent",
          event: "quote_bundle_sent",
          bundle_parent_id: compactString(parent.id),
          tiers: childRows.map((c, i) => ({
            quote_id: compactString(c.id),
            label: tiers[i].label,
            total: numberValue(c.total),
            line_item_count: tiers[i].lineItems.length,
          })),
        },
      });
    }

    if (householdId) {
      await notifyHomeownersForRequest(service, householdId, {
        title: "Quote ready · pick a tier",
        body: `${tiers.length} options from your contractor. Tap to compare.`,
        requestId: requestId || compactString(parent.id),
        eventType: "handyman_quote_bundle_sent",
        extra: { bundle_parent_id: compactString(parent.id) },
      });
    }

    delivery = { sent: true, channel: "in_app", recipientCount: 1 };
  }

  return { parent, children: childRows, delivery };
}

async function sendExistingBundle(
  service: ServiceClient,
  user: Record<string, unknown>,
  membership: Record<string, unknown>,
  bundleId: string,
) {
  // Walk parent + every child. Validate parent has a BUNDLE_MARKER so
  // we don't accidentally send a single-tier quote through this path.
  const { data: parent } = await service
    .from("provider_quotes")
    .select("*")
    .eq("id", bundleId)
    .limit(1)
    .maybeSingle();
  if (!parent) throw new Error("Bundle parent not found");

  const { meta } = parseBundleScopeNotes(compactString(parent.scope_notes));
  if (!meta || !meta.bundle) throw new Error("This quote isn't a bundle.");

  const { data: childrenRaw } = await service
    .from("provider_quotes")
    .select("*")
    .eq("parent_quote_id", bundleId);
  const children = ((childrenRaw ?? []) as Array<Record<string, unknown>>).slice();
  if (children.length === 0) throw new Error("Bundle has no tiers — nothing to send.");

  // Sort children by the tier order recorded on the parent.
  const order = meta.tiers ?? [];
  children.sort((a, b) => {
    const at = compactString(a.title);
    const bt = compactString(b.title);
    const ai = order.findIndex((t) => at.endsWith(" · " + t));
    const bi = order.findIndex((t) => bt.endsWith(" · " + t));
    return (ai === -1 ? 999 : ai) - (bi === -1 ? 999 : bi);
  });

  const now = isoNow();
  const userId = compactString(user.id);
  const sendIds = [bundleId, ...children.map((c) => compactString(c.id))];
  const { error: sendErr } = await service
    .from("provider_quotes")
    .update({
      status: "sent",
      sent_at: now,
      last_sent_at: now,
      sent_via: ["in_app"],
      viewed_at: null,
      approved_at: null,
      declined_at: null,
      updated_by_user_id: userId,
      updated_at: now,
    })
    .in("id", sendIds);
  if (sendErr) throw sendErr;

  const refreshed = await service
    .from("provider_quotes")
    .select("*")
    .eq("id", bundleId)
    .limit(1)
    .maybeSingle();
  const updatedParent = (refreshed.data ?? parent) as Record<string, unknown>;

  const tierLabels: string[] = order.length > 0 ? order : children.map((c) => {
    const t = compactString(c.title);
    const p = compactString(parent.title);
    return t.startsWith(p + " · ") ? t.slice(p.length + 3) : t;
  });
  const tierSummary = children
    .map((c, i) => `${tierLabels[i] ?? "Option"}: ${moneyLabel(numberValue(c.total))}`)
    .join(" · ");
  const bodyText = `${compactString(parent.title)} is ready with ${children.length} options. ${tierSummary}.`;

  const requestId = compactString(parent.request_id) || null;
  const householdId = compactString(parent.household_id) || null;

  await addQuoteMessage(service, {
    workspaceId: compactString(parent.workspace_id),
    quoteId: bundleId,
    requestId,
    householdId,
    senderRole: "provider",
    senderName: compactString(membership.full_name) || compactString(user.email),
    senderEmail: compactString(user.email),
    deliveryChannel: "in_app",
    body: bodyText,
    metadata: {
      event: "quote_bundle_sent",
      kind: "quote_bundle_sent",
      bundle_parent_id: bundleId,
      tiers: children.map((c, i) => ({
        quote_id: compactString(c.id),
        label: tierLabels[i] ?? "Option",
        total: numberValue(c.total),
        line_item_count: Array.isArray(c.line_items) ? c.line_items.length : 0,
        public_share_url: publicQuoteUrl(compactString(c.public_share_token)),
      })),
    },
  });

  if (requestId) {
    await service
      .from("handyman_requests")
      .update({ status: "quoted", updated_at: now })
      .eq("id", requestId);

    await mirrorQuoteMessageToRequestThread(service, {
      requestId,
      householdId,
      senderRole: "vendor",
      body: bodyText,
      metadata: {
        kind: "quote_bundle_sent",
        event: "quote_bundle_sent",
        bundle_parent_id: bundleId,
        tiers: children.map((c, i) => ({
          quote_id: compactString(c.id),
          label: tierLabels[i] ?? "Option",
          total: numberValue(c.total),
          line_item_count: Array.isArray(c.line_items) ? c.line_items.length : 0,
        })),
      },
    });
  }

  if (householdId) {
    await notifyHomeownersForRequest(service, householdId, {
      title: "Quote ready · pick a tier",
      body: `${children.length} options from your contractor. Tap to compare.`,
      requestId: requestId || bundleId,
      eventType: "handyman_quote_bundle_sent",
      extra: { bundle_parent_id: bundleId },
    });
  }

  return { parent: updatedParent, children, delivery: { sent: true, channel: "in_app", recipientCount: 1 } };
}

async function decideQuoteBundle(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  // Provider-side acceptance of a bundle on behalf of the homeowner.
  // Useful in the demo when the contractor is walking the homeowner
  // through tiers in person and just wants to confirm the pick.
  // Phase 80+ chez-concierge will route the homeowner-side decision
  // through its own action; this is the contractor-portal lever.
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canBuildQuotes");

  const parentId = compactString(body.parentId);
  const chosenChildId = compactString(body.chosenChildId);
  if (!parentId || !chosenChildId) {
    throw new Error("parentId and chosenChildId are required");
  }

  // Load parent + every child for consistency check.
  const { data: parent } = await service
    .from("provider_quotes")
    .select("*")
    .eq("id", parentId)
    .eq("workspace_id", workspaceId)
    .limit(1)
    .maybeSingle();
  if (!parent) throw new Error("Bundle parent not found");

  const { data: childrenRaw } = await service
    .from("provider_quotes")
    .select("*")
    .eq("parent_quote_id", parentId);
  const children = (childrenRaw ?? []) as Array<Record<string, unknown>>;
  const chosenChild = children.find((c) => compactString(c.id) === chosenChildId);
  if (!chosenChild) throw new Error("Chosen tier is not a child of this bundle");

  const now = isoNow();

  // Flip chosen child to approved, others to superseded.
  const otherIds = children
    .filter((c) => compactString(c.id) !== chosenChildId)
    .map((c) => compactString(c.id));

  await service
    .from("provider_quotes")
    .update({
      status: "approved",
      approved_at: now,
      updated_by_user_id: userId,
      updated_at: now,
    })
    .eq("id", chosenChildId);

  if (otherIds.length > 0) {
    await service
      .from("provider_quotes")
      .update({
        status: "superseded",
        updated_by_user_id: userId,
        updated_at: now,
      })
      .in("id", otherIds);
  }

  // Update parent: flip status to approved + record chosen-tier
  // breadcrumb in scope_notes so the SPA + homeowner thread can
  // render "Homeowner picked the {tier} tier".
  const { meta, authorScope } = parseBundleScopeNotes(compactString(parent.scope_notes));
  const tierLabel = (() => {
    const childTitle = compactString(chosenChild.title);
    const parentTitle = compactString(parent.title);
    if (childTitle.startsWith(parentTitle + " · ")) {
      return childTitle.slice(parentTitle.length + 3);
    }
    return childTitle;
  })();
  const updatedMeta: BundleMeta = {
    bundle: true,
    tiers: meta?.tiers ?? children.map((c) => {
      const t = compactString(c.title);
      const p = compactString(parent.title);
      return t.startsWith(p + " · ") ? t.slice(p.length + 3) : t;
    }),
    chosenChildId,
    chosenTierLabel: tierLabel,
  };
  const updatedScope = buildBundleScopeNotes(updatedMeta, authorScope || null);

  await service
    .from("provider_quotes")
    .update({
      status: "approved",
      approved_at: now,
      scope_notes: updatedScope,
      updated_by_user_id: userId,
      updated_at: now,
    })
    .eq("id", parentId);

  // Audit message on the parent's quote thread.
  await addQuoteMessage(service, {
    workspaceId,
    quoteId: parentId,
    requestId: compactString(parent.request_id) || null,
    householdId: compactString(parent.household_id) || null,
    senderRole: "provider",
    senderName: compactString(membership.full_name) || compactString(user.email),
    senderEmail: compactString(user.email),
    deliveryChannel: "system",
    body: `Homeowner picked the ${tierLabel} tier (${moneyLabel(numberValue(chosenChild.total))}).`,
    metadata: {
      event: "quote_bundle_decided",
      kind: "quote_bundle_decided",
      bundle_parent_id: parentId,
      chosen_child_id: chosenChildId,
      chosen_tier_label: tierLabel,
    },
  });

  return { parentId, chosenChildId, chosenTierLabel: tierLabel };
}

/**
 * Wave M4 — sign a quote (kitchen-table close).
 *
 * Field tech presents the draft quote on their iPad, the homeowner
 * draws their finger across the canvas, the tech taps Submit. iOS
 * encodes the canvas to a PNG → base64 and ships it here. We upload
 * to the private quote-signatures bucket, stamp signed_at /
 * signed_name / signature_path / signer_role, and (when the quote is
 * still in draft) walk the quote to "approved" so the operator desk +
 * homeowner inbox treat it as a finalized close.
 *
 * Pre-Phase 73b approved quotes were stamped via sign_provider_quote
 * (the homeowner-typed-name flow). M4 reuses signed_at + signed_name
 * so the homeowner-side "Approved (Jane Smith)" caption renders
 * regardless of which channel produced the signature; the new
 * signature_path adds the visual artifact contractors need at audit
 * time and signer_role distinguishes a witness signature (e.g. a
 * spouse who's not the named contract holder) from the principal.
 */
async function signQuote(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canBuildQuotes");

  const quoteId = compactString(body.quoteId);
  if (!quoteId) throw new Error("quoteId is required");

  const signedName = compactString(body.signedName);
  if (!signedName) throw new Error("signedName is required");

  const signerRoleRaw = compactString(body.signerRole) || "homeowner";
  if (signerRoleRaw !== "homeowner" && signerRoleRaw !== "witness") {
    throw new Error("signerRole must be 'homeowner' or 'witness'");
  }

  const signatureBase64 = compactString(body.signatureBase64) || compactString(body.base64);
  if (!signatureBase64) throw new Error("signatureBase64 is required");

  // Verify the quote belongs to this workspace before touching it.
  const { data: quote, error: quoteErr } = await service
    .from("provider_quotes")
    .select(
      "id, workspace_id, status, household_id, request_id, title, total, parent_quote_id, signature_path",
    )
    .eq("id", quoteId)
    .maybeSingle();
  if (quoteErr) throw quoteErr;
  if (!quote) throw new Error("Quote not found");
  if (compactString(quote.workspace_id) !== workspaceId) {
    throw new Error("Quote belongs to a different workspace");
  }

  const householdId = compactString(quote.household_id);
  if (!householdId) {
    throw new Error("Cannot sign a prospect quote (no household linked yet)");
  }

  // Best-effort cleanup of a prior signature on this quote — should be
  // rare in practice (the field flow only signs once) but if a tech
  // hits Submit twice we don't want orphaned bytes.
  const previousPath = compactString(quote.signature_path);
  if (previousPath) {
    await service.storage.from("quote-signatures").remove([previousPath]).catch((err) => {
      console.warn("[handyman-provider] failed to remove prior signature", previousPath, err);
    });
  }

  const stamp = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  // Storage path: <workspace_id>/<quote_id>/<random>.png
  // workspace_id-first lets us list-all signatures per workspace in
  // future audits without an index scan.
  const path = `${workspaceId}/${quoteId}/${stamp}.png`;

  const bytes = decodeBase64Body(signatureBase64);
  const { error: uploadErr } = await service.storage
    .from("quote-signatures")
    .upload(path, bytes, { contentType: "image/png", upsert: false });
  if (uploadErr) throw new Error(`Signature upload failed: ${uploadErr.message}`);

  const now = isoNow();
  const currentStatus = compactString(quote.status);
  // Walk to approved when the quote was sent / viewed / countered /
  // even draft (kitchen-table close skips the send step because the
  // tech is sitting next to the homeowner). Already-approved quotes
  // get a re-stamp without status change. Withdrawn quotes can't be
  // signed.
  if (currentStatus === "withdrawn") {
    throw new Error("Withdrawn quotes can't be signed");
  }
  const shouldFlipToApproved = currentStatus !== "approved";

  const updates: Record<string, unknown> = {
    signature_path: path,
    signed_at: now,
    signed_name: signedName,
    signer_role: signerRoleRaw,
    updated_by_user_id: userId,
    updated_at: now,
  };
  if (shouldFlipToApproved) {
    updates.status = "approved";
    updates.approved_at = now;
  }

  const { data: updated, error: updErr } = await service
    .from("provider_quotes")
    .update(updates)
    .eq("id", quoteId)
    .select(
      "id, status, signature_path, signed_at, signed_name, signer_role, approved_at, total, title, request_id, household_id",
    )
    .single();
  if (updErr || !updated) throw updErr ?? new Error("Failed to stamp signature");

  // Sign a short-lived URL so the iOS app can render the captured
  // signature back inline as a confirmation strip — same pattern as
  // punch-item attachments in M2.
  const { data: signed } = await service.storage
    .from("quote-signatures")
    .createSignedUrl(path, 60 * 60);
  const signedUrl = compactString(signed?.signedUrl);

  // Mirror an audit trail row to the request thread so the operator
  // desk + homeowner inbox both see "Signed by [Name]" without
  // round-tripping through the quote panel. Same pattern as
  // sign_provider_quote in 20260907_phase73b_quote_negotiation.sql.
  const requestId = compactString(updated.request_id);
  if (requestId) {
    await mirrorQuoteMessageToRequestThread(service, {
      requestId,
      householdId,
      senderRole: "vendor",
      body:
        signerRoleRaw === "witness"
          ? `${signedName} witnessed the quote signing.`
          : `${signedName} signed the quote.`,
      metadata: {
        kind: "quote_signed",
        quote_id: quoteId,
        signed_name: signedName,
        signed_at: now,
        signer_role: signerRoleRaw,
        total: numberValue(updated.total),
      },
    });
  }

  return {
    quote: {
      id: compactString(updated.id),
      status: compactString(updated.status),
      signaturePath: compactString(updated.signature_path),
      signatureSignedUrl: signedUrl,
      signedAt: updated.signed_at ?? null,
      signedName: compactString(updated.signed_name) || null,
      signerRole: compactString(updated.signer_role) || null,
      approvedAt: updated.approved_at ?? null,
      total: numberValue(updated.total),
      title: compactString(updated.title),
    },
  };
}

/**
 * Wave M4 — pre-fill a quote from a completed visit.
 *
 * Walks the visit's punch items, picks the ones that are completed
 * (status = 'completed' OR has any time tracked OR has materials
 * recorded), and constructs draft quote line items: one per punch
 * item, with labor priced at workspace.default_hourly_rate_cents *
 * (time_spent_seconds / 3600), plus a materials sub-cost rolled
 * directly into the unit_price (so the line item reads as a single
 * "labor + materials" row). The `punchItemId` foreign key gets
 * stamped on each line item so the operator desk's quote detail can
 * render "this line covers <punch item title>" + the photos.
 *
 * Returns the new quote row (status=draft, parent_quote_id=null) +
 * the unsaved line items so the iOS BuildQuoteSheet can render them
 * editable. The actual save round-trip happens via save_quote /
 * send_quote / save_quote_bundle on the user's tap of Send.
 *
 * If the visit has no completed punch items, the pre-fill returns
 * an empty line items array — the field tech can build the quote
 * from scratch with the customer block + property block already
 * populated.
 */
async function buildQuoteFromVisit(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canBuildQuotes");

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");

  const { data: request, error: requestErr } = await service
    .from("handyman_requests")
    .select(
      "id, household_id, property_id, contractor_id, visit_task_id, title, status",
    )
    .eq("id", requestId)
    .maybeSingle();
  if (requestErr) throw requestErr;
  if (!request) throw new Error("Visit / request not found");

  const householdId = compactString(request.household_id);
  const propertyId = compactString(request.property_id);
  const contractorId = compactString(request.contractor_id);
  const visitTaskId = compactString(request.visit_task_id);

  // Verify the request belongs to this workspace via the contractor link.
  if (contractorId) {
    const { data: link } = await service
      .from("provider_contractor_links")
      .select("workspace_id")
      .eq("contractor_id", contractorId)
      .eq("workspace_id", workspaceId)
      .maybeSingle();
    if (!link) throw new Error("Visit belongs to a different workspace");
  }

  // Default labor rate from the workspace. Stored as cents to keep
  // arithmetic integer; convert to dollars-per-second for the per-item
  // labor pricing math.
  const { data: workspace } = await service
    .from("provider_workspaces")
    .select("default_hourly_rate_cents")
    .eq("id", workspaceId)
    .maybeSingle();
  const hourlyRateCents = numberValue(workspace?.default_hourly_rate_cents ?? 12500);
  const dollarsPerSecond = hourlyRateCents / 100 / 3600;

  // Pull every non-archived punch item assigned to this visit. We
  // include all statuses (not just 'completed') so a tech who tracked
  // time but didn't tap Complete still gets the line item — the
  // homeowner's pricing should reflect work actually done.
  let punchItems: Record<string, unknown>[] = [];
  if (visitTaskId) {
    const { data: items, error: itemsErr } = await service
      .from("handyman_punch_items")
      .select(
        "id, title, description, status, materials_used, time_spent_seconds, completed_at, archived_at, attachments",
      )
      .eq("assigned_visit_task_id", visitTaskId)
      .is("archived_at", null);
    if (itemsErr) throw itemsErr;
    punchItems = (items ?? []) as Record<string, unknown>[];
  }

  // Filter to "actually-done" rows: status = completed OR time tracked
  // OR materials recorded. A row that's still pending with no evidence
  // of work doesn't belong on a kitchen-table quote.
  const eligible = punchItems.filter((item) => {
    const status = compactString(item.status);
    const timeSec = numberValue(item.time_spent_seconds || 0);
    const materials = Array.isArray(item.materials_used) ? item.materials_used : [];
    return status === "completed" || timeSec > 0 || materials.length > 0;
  });

  // Build line items. Each punch item becomes one line:
  //   name = punch item title
  //   description = labor minutes + materials breakdown
  //   quantity = 1, unit_price = labor cost + materials cost
  //   punchItemId = the source punch item id (for cross-link)
  const lineItems = eligible.map((item) => {
    const title = compactString(item.title) || "Visit work";
    const timeSec = numberValue(item.time_spent_seconds || 0);
    const laborMinutes = Math.round(timeSec / 60);
    const laborCost = roundMoney(timeSec * dollarsPerSecond);

    const materials = (Array.isArray(item.materials_used) ? item.materials_used : []) as Array<
      Record<string, unknown>
    >;
    const materialsCost = roundMoney(
      materials.reduce((sum, m) => {
        const qty = numberValue(m.qty ?? 1);
        const unit = numberValue(m.unit_cost ?? m.unitCost ?? 0);
        return sum + qty * unit;
      }, 0),
    );

    const descParts: string[] = [];
    if (laborMinutes > 0) {
      descParts.push(
        `Labor: ${laborMinutes} min @ ${moneyLabel(hourlyRateCents / 100)}/hr`,
      );
    }
    if (materials.length > 0) {
      const matSummary = materials
        .map((m) => `${numberValue(m.qty ?? 1)}× ${compactString(m.name) || "item"}`)
        .join(", ");
      descParts.push(`Materials: ${matSummary}`);
    }

    return {
      id: crypto.randomUUID(),
      name: title,
      description: descParts.join(" · "),
      unit: "ea",
      quantity: 1,
      unit_price: roundMoney(laborCost + materialsCost),
      // Cross-link so the operator desk can render the source punch
      // item's photos / voice on the quote line.
      punch_item_id: compactString(item.id),
    };
  });

  const totals = quoteSummary(lineItems);
  const requestTitle = compactString(request.title) || "Visit";
  const draftTitle = `Quote for ${requestTitle}`;

  // Return the raw shape the iOS BuildQuoteSheet pre-fills its form
  // with. We deliberately do NOT insert a draft row — the field tech
  // edits the lines + customer block in-memory, then a tap of Save /
  // Send round-trips through save_quote / send_quote / save_quote_bundle.
  return {
    draft: {
      requestId,
      householdId,
      propertyId,
      contractorId,
      visitTaskId,
      workspaceId,
      title: draftTitle,
      lineItems: lineItems.map((line) => ({
        id: line.id,
        name: line.name,
        description: line.description,
        unit: line.unit,
        quantity: line.quantity,
        unitPrice: line.unit_price,
        punchItemId: line.punch_item_id,
      })),
      subtotal: totals.subtotal,
      taxTotal: totals.taxTotal,
      total: totals.total,
      defaultHourlyRateCents: hourlyRateCents,
      eligibleCount: eligible.length,
      visitedCount: punchItems.length,
    },
  };
}

/**
 * Wave M13 — list this workspace's recent quotes for the duplication
 * picker. Returns up to `limit` quotes (default 50), sorted reverse-
 * chronologically by `updated_at`. Optional `daysBack` window (default
 * 30, max 3650 to allow "all time"). Workspace-scoped via the same
 * permission check as save_quote / build_quote_from_visit so techs
 * without canBuildQuotes can't enumerate other workspaces' quotes.
 *
 * Bundle parents (`parent_quote_id IS NULL` AND has BUNDLE_MARKER) and
 * standalone quotes show; bundle children are filtered out so the
 * picker doesn't surface 3 rows per Good/Better/Best bundle. Each row
 * carries enough metadata for the iOS picker (customer name, total,
 * date, status pill, line item count) so the field tech can pick the
 * right quote without a second round-trip.
 *
 * The same iOS picker AND the Operations Desk Quotes screen call this
 * action, so the response shape is generic enough to render in both
 * contexts.
 */
async function listRecentQuotes(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canBuildQuotes");

  const limitRaw = numberValue(body.limit ?? 50);
  const limit = Math.max(1, Math.min(200, Math.round(limitRaw)));
  const daysBackRaw = numberValue(body.daysBack ?? 30);
  const daysBack = Math.max(1, Math.min(3650, Math.round(daysBackRaw)));

  const cutoff = new Date(Date.now() - daysBack * 24 * 60 * 60 * 1000).toISOString();

  // Fetch one extra row in case we need to skip a bundle child / parent
  // pair after filtering. Bundle parents always carry the BUNDLE_MARKER
  // sentinel in scope_notes (Wave V.1) — we keep them and drop the
  // children so the picker shows one row per bundle.
  const { data: rows, error } = await service
    .from("provider_quotes")
    .select(
      "id, workspace_id, household_id, property_id, contractor_id, request_id, title, status, total, line_items, prospect_name, scope_notes, parent_quote_id, signed_at, signed_name, signature_path, signer_role, updated_at, created_at",
    )
    .eq("workspace_id", workspaceId)
    .gte("updated_at", cutoff)
    .order("updated_at", { ascending: false })
    .limit(limit * 2);

  if (error) throw error;

  // Drop bundle children (parent_quote_id is set on children); keep
  // bundle parents + standalone quotes.
  const nonChildren = ((rows ?? []) as Record<string, unknown>[]).filter(
    (q) => !compactString(q.parent_quote_id),
  );

  // Resolve display names: prefer prospect_name (standalone quotes),
  // fall back to property name when household_id is set, fall back to
  // "Customer". Pull every distinct property_id in one round-trip.
  const propertyIds = Array.from(
    new Set(
      nonChildren
        .map((q) => compactString(q.property_id))
        .filter(Boolean),
    ),
  );
  const propertyMap = new Map<string, Record<string, unknown>>();
  if (propertyIds.length > 0) {
    const { data: properties } = await service
      .from("properties")
      .select("id, name, street, city, state")
      .in("id", propertyIds);
    for (const p of (properties ?? []) as Record<string, unknown>[]) {
      const id = compactString(p.id);
      if (id) propertyMap.set(id, p);
    }
  }

  const summaries = nonChildren.slice(0, limit).map((q) => {
    const propertyId = compactString(q.property_id);
    const property = propertyId ? propertyMap.get(propertyId) : undefined;
    const propertyName = compactString(property?.name);
    const propertyAddress = [
      property?.street,
      property?.city,
      property?.state,
    ]
      .map((v) => compactString(v))
      .filter(Boolean)
      .join(", ");
    const customerName =
      compactString(q.prospect_name) ||
      propertyName ||
      "Customer";
    const lineItems = Array.isArray(q.line_items) ? q.line_items : [];
    const isBundleParent = compactString(q.scope_notes).includes("[BUNDLE]");

    return {
      id: compactString(q.id),
      title: compactString(q.title),
      customerName,
      customerAddress: propertyAddress,
      total: numberValue(q.total ?? 0),
      status: compactString(q.status),
      statusLabel: quoteStatusLabel(compactString(q.status)),
      lineItemCount: lineItems.length,
      isBundle: isBundleParent,
      isSigned: Boolean(compactString(q.signed_at)),
      signedName: compactString(q.signed_name) || null,
      updatedAt: q.updated_at ?? null,
      createdAt: q.created_at ?? null,
      // Source identifiers so the duplicate flow can pre-fill the
      // duplicate_quote action without a second lookup.
      householdId: compactString(q.household_id) || null,
      propertyId: propertyId || null,
      requestId: compactString(q.request_id) || null,
    };
  });

  return {
    quotes: summaries,
    daysBack,
    limit,
  };
}

/**
 * Wave M13 — duplicate an existing quote into a fresh draft. Kitchen-
 * table efficiency: "same as the Smith house yesterday." Validates
 * workspace membership for the source quote (read access via the
 * source's workspace_id matching the caller's workspace) AND the
 * target household (the workspace must serve that household via a
 * provider_contractor_links row).
 *
 * Copies line items + scope_notes + tier structure if the source is a
 * bundle parent (parent + every child re-inserted with new ids and
 * the new parent's id wired in). Strips signature fields, signed_at,
 * approval timestamps. Strips `punch_item_id` from each line because
 * those refer to a different visit's punch items. Stamps
 * `notes = "Duplicated from quote <invoice_number or id>"` on
 * scope_notes so the operator desk sees provenance.
 *
 * Same action callable from iOS BuildQuoteSheet AND the Operations
 * Desk Quotes screen — body shape is identical in both clients.
 *
 * Returns the new quote id + the unsaved draft payload (matching the
 * shape of build_quote_from_visit) so the iOS sheet can hydrate
 * editor state without a second round-trip.
 */
async function duplicateQuote(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canBuildQuotes");

  const sourceQuoteId = compactString(body.sourceQuoteId);
  if (!sourceQuoteId) throw new Error("sourceQuoteId is required");

  // Pull the source quote and verify it belongs to this workspace.
  const { data: source, error: sourceErr } = await service
    .from("provider_quotes")
    .select(
      "id, workspace_id, contractor_id, household_id, property_id, request_id, visit_task_id, title, scope_notes, line_items, parent_quote_id, recipient_kind, prospect_name, prospect_email, prospect_phone, prospect_address",
    )
    .eq("id", sourceQuoteId)
    .maybeSingle();
  if (sourceErr) throw sourceErr;
  if (!source) throw new Error("Source quote not found");
  if (compactString(source.workspace_id) !== workspaceId) {
    throw new Error("Source quote belongs to a different workspace");
  }

  // Source can be a bundle parent — pull its children so we duplicate
  // the whole tier structure. Bundle children carry their tier label
  // in title (e.g. "Quote for X · Better") + parent_quote_id.
  const isSourceBundle =
    !compactString(source.parent_quote_id) &&
    compactString(source.scope_notes).includes("[BUNDLE]");
  let sourceChildren: Record<string, unknown>[] = [];
  if (isSourceBundle) {
    const { data: kids, error: kidsErr } = await service
      .from("provider_quotes")
      .select(
        "id, title, scope_notes, line_items, prospect_name, prospect_email, prospect_phone, prospect_address",
      )
      .eq("parent_quote_id", sourceQuoteId)
      .order("created_at", { ascending: true });
    if (kidsErr) throw kidsErr;
    sourceChildren = (kids ?? []) as Record<string, unknown>[];
  }

  // Resolve target household + property + request. The target IDs win
  // over the source's IDs (the whole point of duplication is to send
  // to a different customer).
  const targetHouseholdId =
    compactString(body.targetHouseholdId) || compactString(source.household_id);
  const targetPropertyId =
    compactString(body.targetPropertyId) || compactString(source.property_id);
  const targetRequestId = compactString(body.targetRequestId) || null;

  // Verify the workspace serves the target household via the contractor
  // link table. This protects against picking a quote and pasting it
  // onto a household that belongs to a different operator.
  if (targetHouseholdId) {
    const { data: contractorLinks } = await service
      .from("provider_contractor_links")
      .select("contractor_id, contractors(household_id)")
      .eq("workspace_id", workspaceId);
    const linkedHouseholdIds = new Set(
      ((contractorLinks ?? []) as Record<string, unknown>[])
        .map((row) => {
          const c = row.contractors as Record<string, unknown> | undefined;
          return compactString(c?.household_id);
        })
        .filter(Boolean),
    );
    if (linkedHouseholdIds.size > 0 && !linkedHouseholdIds.has(targetHouseholdId)) {
      throw new Error("Workspace does not serve this target household");
    }
  }

  // If the targetRequestId is set, verify it belongs to a household
  // this workspace serves AND pull the contractor_id off it (so the
  // duplicate's contractor_id is correct).
  let contractorId = compactString(source.contractor_id);
  if (targetRequestId) {
    const { data: targetRequest } = await service
      .from("handyman_requests")
      .select("id, household_id, property_id, contractor_id")
      .eq("id", targetRequestId)
      .maybeSingle();
    if (targetRequest) {
      if (targetHouseholdId && compactString(targetRequest.household_id) !== targetHouseholdId) {
        throw new Error("targetRequestId belongs to a different household than targetHouseholdId");
      }
      contractorId = compactString(targetRequest.contractor_id) || contractorId;
    }
  }

  // Strip signature / approval / sent / pricing-status fields when
  // copying; the new draft starts fresh. Intentionally NOT setting
  // punch_item_id on the new line items: duplicate doesn't carry
  // punch item cross-links from the source visit (those refer to a
  // completed visit's punch items, not this one).
  const stripLineItem = (item: Record<string, unknown>) => ({
    id: crypto.randomUUID(),
    name: compactString(item.name),
    description: compactString(item.description),
    unit: compactString(item.unit) || "ea",
    quantity: numberValue(item.quantity ?? 1),
    unit_price: numberValue(item.unit_price ?? item.unitPrice ?? 0),
  });

  // Source quote provenance label that lands in scope_notes so the
  // operator desk + iOS picker see "Duplicated from quote XYZ".
  const sourceTitle = compactString(source.title) || "Untitled";
  const provenanceNote = `Duplicated from quote: ${sourceTitle}`;

  const now = isoNow();

  // Title: pre-fill from source title but the field tech edits it
  // before sending. Recipient overrides default to the source's prospect
  // fields when targetHouseholdId is null (pure prospect-to-prospect
  // duplicate).
  const newTitle = sourceTitle;
  const recipientKind = targetHouseholdId ? "linked_home" : "prospect";

  if (isSourceBundle) {
    // Bundle duplicate: insert new parent + new children with line
    // items per tier. Mirror the saveQuoteBundle insert sequence.
    const sourceParentScope = compactString(source.scope_notes);
    const newParentScope = `${sourceParentScope}\n\n${provenanceNote}`.trim();

    const parentPayload = {
      workspace_id: workspaceId,
      contractor_id: contractorId || null,
      household_id: targetHouseholdId || null,
      property_id: targetPropertyId || null,
      request_id: targetRequestId,
      visit_task_id: null,
      title: newTitle,
      recipient_kind: recipientKind,
      prospect_name: recipientKind === "prospect" ? compactString(source.prospect_name) || null : null,
      prospect_email: recipientKind === "prospect" ? compactString(source.prospect_email) || null : null,
      prospect_phone: recipientKind === "prospect" ? compactString(source.prospect_phone) || null : null,
      prospect_address: recipientKind === "prospect" ? compactString(source.prospect_address) || null : null,
      status: "draft",
      currency: "USD",
      line_items: [],
      scope_notes: newParentScope,
      homeowner_message: null,
      subtotal: 0,
      tax_total: 0,
      total: 0,
      created_by_user_id: userId,
      updated_by_user_id: userId,
      updated_at: now,
      public_share_token: crypto.randomUUID(),
      // Critical: do NOT carry signature fields, signed_at, sent_at,
      // approved_at, declined_at — the duplicate is a fresh draft.
    };

    const { data: parentRow, error: parentErr } = await service
      .from("provider_quotes")
      .insert(parentPayload)
      .select()
      .single();
    if (parentErr || !parentRow) throw parentErr ?? new Error("Failed to insert duplicate bundle parent");

    const newChildRows: Record<string, unknown>[] = [];
    for (const child of sourceChildren) {
      const sourceChildLines = Array.isArray(child.line_items)
        ? (child.line_items as Record<string, unknown>[])
        : [];
      const newChildLines = sourceChildLines.map(stripLineItem).filter((l) => l.name);
      const childTotals = quoteSummary(newChildLines);

      const childPayload = {
        workspace_id: workspaceId,
        contractor_id: contractorId || null,
        household_id: targetHouseholdId || null,
        property_id: targetPropertyId || null,
        request_id: targetRequestId,
        visit_task_id: null,
        title: compactString(child.title) || newTitle,
        recipient_kind: recipientKind,
        prospect_name: recipientKind === "prospect" ? compactString(source.prospect_name) || null : null,
        prospect_email: recipientKind === "prospect" ? compactString(source.prospect_email) || null : null,
        prospect_phone: recipientKind === "prospect" ? compactString(source.prospect_phone) || null : null,
        prospect_address: recipientKind === "prospect" ? compactString(source.prospect_address) || null : null,
        status: "draft",
        currency: "USD",
        line_items: newChildLines,
        scope_notes: compactString(child.scope_notes) || null,
        homeowner_message: null,
        subtotal: childTotals.subtotal,
        tax_total: childTotals.taxTotal,
        total: childTotals.total,
        parent_quote_id: parentRow.id,
        created_by_user_id: userId,
        updated_by_user_id: userId,
        updated_at: now,
        public_share_token: crypto.randomUUID(),
      };
      const { data: childRow, error: childErr } = await service
        .from("provider_quotes")
        .insert(childPayload)
        .select()
        .single();
      if (childErr || !childRow) {
        // Roll back parent + any prior children so we don't leave a
        // half-built bundle.
        await service.from("provider_quotes").delete().eq("id", parentRow.id);
        for (const prior of newChildRows) {
          await service.from("provider_quotes").delete().eq("id", compactString(prior.id));
        }
        throw childErr ?? new Error("Failed to insert duplicate bundle child");
      }
      newChildRows.push(childRow as Record<string, unknown>);
    }

    return {
      duplicate: {
        id: compactString(parentRow.id),
        isBundle: true,
        childIds: newChildRows.map((c) => compactString(c.id)),
        title: newTitle,
        sourceQuoteId,
      },
    };
  }

  // Single-tier duplicate: one row, line items copied with stripped
  // punch_item_id, signature fields cleared.
  const sourceLines = Array.isArray(source.line_items)
    ? (source.line_items as Record<string, unknown>[])
    : [];
  const newLines = sourceLines.map(stripLineItem).filter((l) => l.name);
  const totals = quoteSummary(newLines);

  const sourceScope = compactString(source.scope_notes);
  const newScope = sourceScope
    ? `${sourceScope}\n\n${provenanceNote}`
    : provenanceNote;

  const insertPayload = {
    workspace_id: workspaceId,
    contractor_id: contractorId || null,
    household_id: targetHouseholdId || null,
    property_id: targetPropertyId || null,
    request_id: targetRequestId,
    visit_task_id: null,
    title: newTitle,
    recipient_kind: recipientKind,
    prospect_name: recipientKind === "prospect" ? compactString(source.prospect_name) || null : null,
    prospect_email: recipientKind === "prospect" ? compactString(source.prospect_email) || null : null,
    prospect_phone: recipientKind === "prospect" ? compactString(source.prospect_phone) || null : null,
    prospect_address: recipientKind === "prospect" ? compactString(source.prospect_address) || null : null,
    status: "draft",
    currency: "USD",
    line_items: newLines,
    scope_notes: newScope,
    homeowner_message: null,
    subtotal: totals.subtotal,
    tax_total: totals.taxTotal,
    total: totals.total,
    created_by_user_id: userId,
    updated_by_user_id: userId,
    updated_at: now,
    public_share_token: crypto.randomUUID(),
    // Critical: signature fields, signed_at, signed_name,
    // signature_path, signer_role, sent_at, approved_at, declined_at,
    // public_share_token — all NULL / freshly-minted, never copied.
  };

  const { data: newQuote, error: insertErr } = await service
    .from("provider_quotes")
    .insert(insertPayload)
    .select()
    .single();
  if (insertErr || !newQuote) throw insertErr ?? new Error("Failed to insert duplicate quote");

  // Return a draft payload shape that mirrors build_quote_from_visit
  // so the iOS BuildQuoteSheet's `hydrate(from:)` flow can pick this
  // up without a second round-trip. The iOS picker will then route the
  // user back into the editor with the line items pre-loaded.
  return {
    duplicate: {
      id: compactString(newQuote.id),
      isBundle: false,
      title: newTitle,
      sourceQuoteId,
      // Mirror HavenFieldQuoteDraftPayload shape so the editor can
      // hydrate without a separate round-trip.
      draft: {
        requestId: targetRequestId,
        householdId: targetHouseholdId || null,
        propertyId: targetPropertyId || null,
        contractorId: contractorId || null,
        visitTaskId: null,
        workspaceId,
        title: newTitle,
        lineItems: newLines.map((line) => ({
          id: compactString(line.id),
          name: compactString(line.name),
          description: compactString(line.description),
          unit: compactString(line.unit) || "ea",
          quantity: numberValue(line.quantity ?? 1),
          unitPrice: numberValue(line.unit_price ?? 0),
          punchItemId: null,
        })),
        subtotal: totals.subtotal,
        taxTotal: totals.taxTotal,
        total: totals.total,
        defaultHourlyRateCents: 12500,
        eligibleCount: newLines.length,
        visitedCount: 0,
      },
    },
  };
}

async function saveQuoteItem(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canBuildQuotes");

  const payload = {
    workspace_id: workspaceId,
    created_by_user_id: userId,
    name: compactString(body.name),
    description: compactString(body.description) || null,
    unit: compactString(body.unit) || "ea",
    default_quantity: numberValue(body.defaultQuantity || 1),
    default_unit_price: numberValue(body.defaultUnitPrice || 0),
    sort_order: numberValue(body.sortOrder || 0),
    updated_at: isoNow(),
  };

  if (!payload.name) throw new Error("Line item name is required");

  const itemId = compactString(body.itemId);
  const mutation = itemId
    ? service
        .from("provider_saved_quote_items")
        .update(payload)
        .eq("id", itemId)
        .eq("workspace_id", workspaceId)
        .select()
        .single()
    : service
        .from("provider_saved_quote_items")
        .insert(payload)
        .select()
        .single();

  const { data, error } = await mutation;
  if (error || !data) throw error ?? new Error("Failed to save quote item");
  return data;
}

// ─── Wave Q (Section 8) — Provider invoices ───
//
// `saveInvoice` upserts a draft invoice. When `body.send === true`,
// flips status to "sent" and mirrors the invoice into the homeowner's
// inbox + (optionally) the request thread, mirroring the quote-send
// pattern.

/// Wave M5 — convert a completed visit into a draft invoice.
///
/// Mirrors `buildQuoteFromVisit` (Wave M4) but lands the lines on
/// the invoice path instead of the quote path. For each completed
/// punch item we emit two kinds of line items:
///   1) Labor line: name = "Labor: <punch title>", qty = hours
///      (time_spent_seconds / 3600), unit_price =
///      workspace.default_hourly_rate_cents / 100.
///   2) One Material line per `materials_used` entry, with that
///      material's qty + unit_cost.
///
/// Each line item carries `punch_item_id` for traceability so the
/// Operations Desk + homeowner inbox can link back. Returns the same
/// shape iOS pre-fills its FieldBuildInvoiceSheet form with — we do
/// NOT insert a draft row here; the field tech edits in-memory and
/// taps Save / Send to round-trip through `save_invoice` /
/// `send_invoice`.
async function convertVisitToInvoice(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  // Same role gate as save_invoice: owners + admins build invoices.
  assertPermission(membership, "canBuildQuotes");

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");

  const { data: request, error: requestErr } = await service
    .from("handyman_requests")
    .select(
      "id, household_id, property_id, contractor_id, visit_task_id, title, status",
    )
    .eq("id", requestId)
    .maybeSingle();
  if (requestErr) throw requestErr;
  if (!request) throw new Error("Visit / request not found");

  const householdId = compactString(request.household_id);
  const propertyId = compactString(request.property_id);
  const contractorId = compactString(request.contractor_id);
  const visitTaskId = compactString(request.visit_task_id);

  // Verify the request belongs to this workspace via the contractor link.
  if (contractorId) {
    const { data: link } = await service
      .from("provider_contractor_links")
      .select("workspace_id")
      .eq("contractor_id", contractorId)
      .eq("workspace_id", workspaceId)
      .maybeSingle();
    if (!link) throw new Error("Visit belongs to a different workspace");
  }

  // Default labor rate from the workspace settings (Wave M4 column,
  // default 12500 cents = $125/hr). Same source as build_quote_from_visit.
  const { data: workspace } = await service
    .from("provider_workspaces")
    .select("default_hourly_rate_cents")
    .eq("id", workspaceId)
    .maybeSingle();
  const hourlyRateCents = numberValue(workspace?.default_hourly_rate_cents ?? 12500);
  const hourlyRate = hourlyRateCents / 100;

  // Pull every non-archived punch item assigned to this visit.
  let punchItems: Record<string, unknown>[] = [];
  if (visitTaskId) {
    const { data: items, error: itemsErr } = await service
      .from("handyman_punch_items")
      .select(
        "id, title, description, status, materials_used, time_spent_seconds, completed_at, archived_at",
      )
      .eq("assigned_visit_task_id", visitTaskId)
      .is("archived_at", null);
    if (itemsErr) throw itemsErr;
    punchItems = (items ?? []) as Record<string, unknown>[];
  }

  // Same eligibility rule as build_quote_from_visit: include rows that
  // were marked done OR have time tracked OR have materials recorded.
  const eligible = punchItems.filter((item) => {
    const status = compactString(item.status);
    const timeSec = numberValue(item.time_spent_seconds || 0);
    const materials = Array.isArray(item.materials_used) ? item.materials_used : [];
    return status === "completed" || timeSec > 0 || materials.length > 0;
  });

  // Build line items. One Labor line per punch item + one Material line
  // per material entry. Materials get their own row so the homeowner
  // sees the parts breakdown clearly on the invoice (vs the quote
  // which bundles labor + materials into a single line).
  const lineItems: Array<Record<string, unknown>> = [];
  for (const item of eligible) {
    const punchId = compactString(item.id);
    const title = compactString(item.title) || "Visit work";
    const timeSec = numberValue(item.time_spent_seconds || 0);
    const hours = roundMoney(timeSec / 3600);
    const materials = (Array.isArray(item.materials_used) ? item.materials_used : []) as Array<
      Record<string, unknown>
    >;

    // Labor line: only emit if there's tracked time. A pure-materials
    // punch item still gets material lines below.
    if (hours > 0) {
      const minutes = Math.round(timeSec / 60);
      lineItems.push({
        id: crypto.randomUUID(),
        name: `Labor: ${title}`,
        description: `${minutes} min @ ${moneyLabel(hourlyRate)}/hr`,
        unit: "hr",
        quantity: hours,
        unit_price: hourlyRate,
        punch_item_id: punchId,
      });
    } else if (materials.length === 0 && compactString(item.status) === "completed") {
      // Completed punch with no time + no materials: still emit a
      // 30-min minimum labor line so the technician's time doesn't
      // ghost on the customer's bill.
      lineItems.push({
        id: crypto.randomUUID(),
        name: `Labor: ${title}`,
        description: "Visit task completed",
        unit: "hr",
        quantity: 0.5,
        unit_price: hourlyRate,
        punch_item_id: punchId,
      });
    }

    for (const material of materials) {
      const matName = compactString(material.name) || "Material";
      const qty = numberValue(material.qty ?? 1);
      const unit = compactString(material.unit) || "ea";
      const unitCost = numberValue(material.unit_cost ?? material.unitCost ?? 0);
      if (qty <= 0) continue;
      lineItems.push({
        id: crypto.randomUUID(),
        name: matName,
        description: `Used on ${title}`,
        unit,
        quantity: qty,
        unit_price: unitCost,
        punch_item_id: punchId,
      });
    }
  }

  const totals = invoiceSummary(lineItems);
  const requestTitle = compactString(request.title) || "Visit";
  const draftTitle = `Invoice for ${requestTitle}`;

  return {
    draft: {
      requestId,
      householdId,
      propertyId,
      contractorId,
      visitTaskId,
      workspaceId,
      title: draftTitle,
      lineItems: lineItems.map((line) => ({
        id: compactString(line.id),
        name: compactString(line.name),
        description: compactString(line.description),
        unit: compactString(line.unit) || "ea",
        quantity: numberValue(line.quantity),
        unitPrice: numberValue(line.unit_price),
        punchItemId: compactString(line.punch_item_id) || null,
      })),
      subtotal: totals.subtotal,
      taxTotal: totals.taxTotal,
      total: totals.total,
      defaultHourlyRateCents: hourlyRateCents,
      eligibleCount: eligible.length,
      visitedCount: punchItems.length,
    },
  };
}

function generateInvoiceNumber(): string {
  const now = new Date();
  const year = now.getUTCFullYear();
  const month = String(now.getUTCMonth() + 1).padStart(2, "0");
  // 6-char base36 suffix from a random uint32 — collision risk on a
  // single workspace is negligible at the volumes we're targeting and
  // the unique index protects us.
  const rand = Math.floor(Math.random() * 0xffffff)
    .toString(36)
    .toUpperCase()
    .padStart(6, "0");
  return `INV-${year}${month}-${rand}`;
}

function invoiceSummary(lineItems: Array<Record<string, unknown>>) {
  const subtotal = roundMoney(
    lineItems.reduce((sum, item) => {
      const quantity = numberValue(item.quantity || 1);
      const unitPrice = numberValue(item.unit_price || item.unitPrice || 0);
      return sum + quantity * unitPrice;
    }, 0),
  );
  return {
    subtotal,
    taxTotal: 0,
    total: subtotal,
  };
}

function providerInvoiceMessageBody(
  title: string,
  total: number,
  lineItemCount: number,
  note?: string,
) {
  const summary = `${title} for ${moneyLabel(total)} across ${lineItemCount} line item${lineItemCount === 1 ? "" : "s"}.`;
  const cleanNote = compactString(note);
  return cleanNote ? `${summary} ${cleanNote}` : summary;
}

async function saveInvoice(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  // Reuse the canBuildQuotes permission for invoice authoring; same role
  // gate (owner / admin) applies and we don't want to mint a new perm
  // flag for v1.
  assertPermission(membership, "canBuildQuotes");

  const invoiceId = compactString(body.invoiceId);
  const existing = invoiceId
    ? await service
        .from("provider_invoices")
        .select("*")
        .eq("id", invoiceId)
        .eq("workspace_id", workspaceId)
        .limit(1)
        .maybeSingle()
    : { data: null, error: null };
  if (existing.error) throw existing.error;

  // Optional: prefill from a source quote when caller passes
  // sourceQuoteId. We snapshot line items + scope notes + total so
  // future quote edits don't retroactively mutate the invoice.
  const sourceQuoteId = compactString(body.sourceQuoteId);
  let sourceQuote: Record<string, unknown> | null = null;
  if (sourceQuoteId && !existing.data) {
    const { data: quoteRow, error: quoteError } = await service
      .from("provider_quotes")
      .select("*")
      .eq("id", sourceQuoteId)
      .eq("workspace_id", workspaceId)
      .limit(1)
      .maybeSingle();
    if (quoteError) throw quoteError;
    sourceQuote = quoteRow as Record<string, unknown> | null;
  }

  const incomingLineItems = Array.isArray(body.lineItems)
    ? (body.lineItems as Array<Record<string, unknown>>)
    : null;
  const fallbackLineItems = Array.isArray(existing.data?.line_items)
    ? (existing.data!.line_items as Array<Record<string, unknown>>)
    : Array.isArray(sourceQuote?.line_items)
    ? (sourceQuote!.line_items as Array<Record<string, unknown>>)
    : [];
  const sourceLineItems = incomingLineItems ?? fallbackLineItems;
  const lineItems = sourceLineItems
    .map((item) => {
      // Wave M5 — preserve the cross-link to the source punch item so
      // the Operations Desk can render the punch's photos / voice note
      // on the invoice line. Mirror M4's save_quote treatment of the
      // same field on quote lines.
      const punchItemId =
        compactString(item.punch_item_id) || compactString(item.punchItemId) || null;
      const base: Record<string, unknown> = {
        id: compactString(item.id) || crypto.randomUUID(),
        name: compactString(item.name),
        description: compactString(item.description),
        unit: compactString(item.unit) || "ea",
        quantity: numberValue(item.quantity || 1),
        unit_price: numberValue(item.unitPrice || item.unit_price || 0),
      };
      if (punchItemId) base.punch_item_id = punchItemId;
      return base;
    })
    .filter((item) => item.name);

  if (!workspaceId || lineItems.length === 0) {
    throw new Error("Workspace and at least one line item are required");
  }

  const totals = invoiceSummary(lineItems);
  const now = isoNow();
  const sendNow = Boolean(body.send);

  const householdId =
    compactString(body.householdId) ||
    compactString(existing.data?.household_id) ||
    compactString(sourceQuote?.household_id) ||
    null;
  const propertyId =
    compactString(body.propertyId) ||
    compactString(existing.data?.property_id) ||
    compactString(sourceQuote?.property_id) ||
    null;
  const requestId =
    compactString(body.requestId) ||
    compactString(existing.data?.request_id) ||
    compactString(sourceQuote?.request_id) ||
    null;
  const visitTaskId =
    compactString(body.visitTaskId) ||
    compactString(existing.data?.visit_task_id) ||
    compactString(sourceQuote?.visit_task_id) ||
    null;
  const contractorId =
    compactString(body.contractorId) ||
    compactString(existing.data?.contractor_id) ||
    compactString(sourceQuote?.contractor_id) ||
    null;
  const title =
    compactString(body.title) ||
    compactString(existing.data?.title) ||
    (sourceQuote ? `Invoice for ${compactString(sourceQuote.title)}` : "Invoice");
  const scopeNotes =
    compactString(body.scopeNotes) || compactString(existing.data?.scope_notes) || null;
  const homeownerMessage =
    compactString(body.homeownerMessage) ||
    compactString(existing.data?.homeowner_message) ||
    null;
  const dueDate = compactString(body.dueDate) || compactString(existing.data?.due_date) || null;

  const invoiceNumber = compactString(existing.data?.invoice_number) || generateInvoiceNumber();

  const payload = {
    workspace_id: workspaceId,
    contractor_id: contractorId,
    household_id: householdId,
    property_id: propertyId,
    request_id: requestId,
    visit_task_id: visitTaskId,
    source_quote_id:
      sourceQuoteId || compactString(existing.data?.source_quote_id) || null,
    invoice_number: invoiceNumber,
    title,
    status: existing.data?.status || "draft",
    currency: "USD",
    line_items: lineItems,
    scope_notes: scopeNotes,
    homeowner_message: homeownerMessage,
    subtotal: totals.subtotal,
    tax_total: totals.taxTotal,
    total: totals.total,
    amount_paid: numberValue(existing.data?.amount_paid || 0),
    due_date: dueDate,
    updated_at: now,
  };

  const mutation = existing.data
    ? service
        .from("provider_invoices")
        .update(payload)
        .eq("id", invoiceId)
        .select()
        .single()
    : service
        .from("provider_invoices")
        .insert({
          ...payload,
          created_by_user_id: userId,
        })
        .select()
        .single();

  const { data: invoiceRow, error } = await mutation;
  if (error || !invoiceRow) throw error ?? new Error("Failed to save invoice");

  let invoice = invoiceRow as Record<string, unknown>;

  if (sendNow) {
    invoice = await deliverInvoice(service, {
      invoice,
      lineItems,
      total: totals.total,
      title,
      homeownerMessage: homeownerMessage ?? "",
      requestId,
      householdId,
      userId,
      providerName:
        compactString(membership.full_name) || compactString(user.email) || "Your contractor",
      propertyId,
    });
  }

  return { invoice };
}

async function deliverInvoice(
  service: ServiceClient,
  args: {
    invoice: Record<string, unknown>;
    lineItems: Array<Record<string, unknown>>;
    total: number;
    title: string;
    homeownerMessage: string;
    requestId: string | null;
    householdId: string | null;
    userId: string;
    providerName: string;
    propertyId: string | null;
  },
) {
  const now = isoNow();
  const invoiceId = compactString(args.invoice.id);

  const { data: sentRow, error } = await service
    .from("provider_invoices")
    .update({
      status: "sent",
      sent_at: now,
      updated_at: now,
    })
    .eq("id", invoiceId)
    .select()
    .single();
  if (error || !sentRow) throw error ?? new Error("Failed to mark invoice sent");

  const bodyText = providerInvoiceMessageBody(
    args.title,
    args.total,
    args.lineItems.length,
    args.homeownerMessage,
  );

  // Mirror the send into the request chat thread so the homeowner's
  // iOS app surfaces an "Invoice received" entry on the request. Same
  // pattern as quote-send.
  if (args.requestId && args.householdId) {
    await mirrorQuoteMessageToRequestThread(service, {
      requestId: args.requestId,
      householdId: args.householdId,
      senderRole: "vendor",
      body: bodyText,
      metadata: {
        kind: "invoice_sent",
        event: "invoice_sent",
        invoice_id: invoiceId,
        invoice_number: compactString(sentRow.invoice_number),
        total: args.total,
        line_item_count: args.lineItems.length,
      },
    });
  }

  // Universal inbox row so the invoice always lands in the homeowner's
  // Needs-Action list, even on ad-hoc invoices not tied to a request.
  if (args.householdId) {
    let propertyName = "";
    if (args.propertyId) {
      const { data: property } = await service
        .from("properties")
        .select("name")
        .eq("id", args.propertyId)
        .limit(1)
        .maybeSingle();
      propertyName = compactString(property?.name);
    }
    try {
      const summary = `${args.title} · ${moneyLabel(args.total)}`;
      // Wave Y2 — stamp metadata so iOS can deep-link from the
      // homeowner's inbox row to the underlying invoice.
      await service.from("inbox_items").insert({
        household_id: args.householdId,
        type: "invoice_received",
        title: propertyName ? `Invoice for ${propertyName}` : "Invoice received",
        summary,
        from_email: args.providerName,
        seen: false,
        metadata: {
          invoice_id: invoiceId,
          property_id: compactString(args.propertyId),
          request_id: compactString(args.requestId),
          total: args.total,
        },
      });
    } catch (inboxErr) {
      console.error("[handyman-provider] inbox_items insert failed for invoice", inboxErr);
    }

    // Push notification — same pattern as quote send.
    await notifyHomeownersForRequest(service, args.householdId, {
      title: "Invoice received",
      body: `${moneyLabel(args.total)} from your contractor. Tap to review.`,
      requestId: args.requestId || invoiceId,
      eventType: "handyman_invoice_sent",
      extra: { invoice_id: invoiceId },
    });
  }

  return sentRow as Record<string, unknown>;
}

async function voidInvoice(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const invoiceId = compactString(body.invoiceId);
  if (!workspaceId || !invoiceId) throw new Error("workspaceId and invoiceId are required");
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canBuildQuotes");

  const now = isoNow();
  const { data, error } = await service
    .from("provider_invoices")
    .update({
      status: "void",
      voided_at: now,
      updated_at: now,
    })
    .eq("id", invoiceId)
    .eq("workspace_id", workspaceId)
    .select()
    .single();
  if (error || !data) throw error ?? new Error("Failed to void invoice");

  const requestId = compactString(data.request_id);
  const householdId = compactString(data.household_id);
  if (requestId && householdId) {
    await mirrorQuoteMessageToRequestThread(service, {
      requestId,
      householdId,
      senderRole: "vendor",
      body: `Invoice ${compactString(data.invoice_number)} was voided.`,
      metadata: {
        kind: "invoice_voided",
        event: "invoice_voided",
        invoice_id: invoiceId,
      },
    });
  }
  return { invoice: data as Record<string, unknown> };
}

async function markInvoicePaid(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const invoiceId = compactString(body.invoiceId);
  if (!workspaceId || !invoiceId) throw new Error("workspaceId and invoiceId are required");
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);
  assertPermission(membership, "canBuildQuotes");

  const now = isoNow();
  const { data: existing } = await service
    .from("provider_invoices")
    .select("total")
    .eq("id", invoiceId)
    .eq("workspace_id", workspaceId)
    .limit(1)
    .maybeSingle();
  const totalAmount = numberValue(existing?.total || 0);

  const { data, error } = await service
    .from("provider_invoices")
    .update({
      status: "paid",
      paid_at: now,
      amount_paid: totalAmount,
      updated_at: now,
    })
    .eq("id", invoiceId)
    .eq("workspace_id", workspaceId)
    .select()
    .single();
  if (error || !data) throw error ?? new Error("Failed to mark invoice paid");

  const requestId = compactString(data.request_id);
  const householdId = compactString(data.household_id);
  if (requestId && householdId) {
    await mirrorQuoteMessageToRequestThread(service, {
      requestId,
      householdId,
      senderRole: "vendor",
      body: `Invoice ${compactString(data.invoice_number)} marked paid.`,
      metadata: {
        kind: "invoice_paid",
        event: "invoice_paid",
        invoice_id: invoiceId,
      },
    });
  }
  return { invoice: data as Record<string, unknown> };
}

async function sendMessage(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  const membership = await assertWorkspaceAccess(service, userId, workspaceId);

  const messageBody = compactString(body.body);
  if (!messageBody) throw new Error("Message is required");

  let requestId = compactString(body.requestId);
  const propertyId = compactString(body.propertyId);
  const nextStatus = compactString(body.status);

  if (!requestId && !propertyId) {
    throw new Error("Choose a home or request before sending a message");
  }

  // Sprint #4 R5-E-12B BLOCKER: when caller supplies requestId, verify
  // the request actually belongs to their workspace. Without this, a
  // W1 caller could pass a W2 requestId and we'd happily insert a
  // message into W2's thread + email W2's customer. The propertyId
  // path below has its own contractor-link check (line ~9750) that
  // rejects unlinked homes; this guards the requestId path identically.
  if (requestId) {
    await assertRequestInWorkspace(service, requestId, workspaceId);
  }

  let request:
    | {
        id?: string | null;
        household_id?: string | null;
        property_id?: string | null;
        title?: string | null;
        status?: string | null;
      }
    | null = null;

  if (requestId) {
    const { data: existingRequest, error: requestError } = await service
      .from("handyman_requests")
      .select("id, household_id, property_id, title, status")
      .eq("id", requestId)
      .limit(1)
      .maybeSingle();

    if (requestError || !existingRequest) throw requestError ?? new Error("Request not found");
    request = existingRequest;
  } else if (propertyId) {
    const { data: property, error: propertyError } = await service
      .from("properties")
      .select("id, household_id, name")
      .eq("id", propertyId)
      .limit(1)
      .maybeSingle();

    if (propertyError || !property) throw propertyError ?? new Error("Home not found");

    const householdId = compactString(property.household_id);
    if (!householdId) throw new Error("Home is missing a household");

    const workspace = (membership.provider_workspaces as Record<string, unknown> | undefined) ?? {};
    const { data: contractorLinks, error: contractorLinkError } = await service
      .from("provider_contractor_links")
      .select("contractor_id, contractors(id, household_id)")
      .eq("workspace_id", workspaceId);

    if (contractorLinkError) throw contractorLinkError;

    const linkedContractorId = ((contractorLinks ?? []) as Record<string, unknown>[])
      .find((row) => {
        const contractor = row.contractors as Record<string, unknown> | null;
        return compactString(contractor?.household_id) === householdId;
      })
      ?.contractor_id;

    const contractorId = compactString(linkedContractorId);
    if (!contractorId) {
      throw new Error("This home has not granted Chez Field access to this handyman yet");
    }

    const { data: recentRequests, error: recentRequestsError } = await service
      .from("handyman_requests")
      .select("id, household_id, property_id, title, status")
      .eq("property_id", propertyId)
      .eq("contractor_id", contractorId)
      .order("updated_at", { ascending: false })
      .limit(12);

    if (recentRequestsError) throw recentRequestsError;

    request = ((recentRequests ?? []) as Record<string, unknown>[])
      .find((candidate) => !["completed", "cancelled", "declined"].includes(compactString(candidate.status)));

    if (!request) {
      const threadTitle = compactString(body.threadTitle) || `Message from ${compactString(workspace.company_name) || "Chez Field"}`;
      const { data: createdRequest, error: createRequestError } = await service
        .from("handyman_requests")
        .insert({
          household_id: householdId,
          property_id: propertyId,
          contractor_id: contractorId,
          created_by_user_id: userId,
          request_type: "question",
          source: "vendor",
          title: threadTitle,
          details: compactString(body.threadContext) || null,
          urgency: "routine",
          status: nextStatus || "awaiting_homeowner",
        })
        .select("id, household_id, property_id, title, status")
        .single();

      if (createRequestError || !createdRequest) {
        throw createRequestError ?? new Error("Failed to create a homeowner thread");
      }
      request = createdRequest;
    }

    requestId = compactString(request.id);
  }

  if (!request || !requestId) throw new Error("Request not found");

  // Wave T: caller may pass `metadata` to ride a structured payload on
  // the message (attachments array, kind: "visit_proposed" slot card,
  // etc.). We always stamp event=provider_message so the existing
  // notification path keeps working; caller-supplied keys override
  // only when they don't collide with reserved event identity.
  const incomingMetadata =
    typeof body.metadata === "object" && body.metadata !== null
      ? (body.metadata as Record<string, unknown>)
      : {};

  const payload: Record<string, unknown> = {
    request_id: requestId,
    household_id: request.household_id,
    sender_role: "vendor",
    body: messageBody,
    metadata: {
      ...incomingMetadata,
      event: "provider_message",
    },
  };

  const { data: message, error } = await service
    .from("handyman_request_messages")
    .insert(payload)
    .select()
    .single();
  if (error || !message) throw error ?? new Error("Failed to send message");

  let finalStatus = compactString(request.status);
  await service
    .from("handyman_requests")
    .update({ status: nextStatus || finalStatus, updated_at: isoNow() })
    .eq("id", requestId);
  if (nextStatus) {
    finalStatus = nextStatus;
  }

  const requestPropertyId = compactString(request.property_id);
  const { data: property } = requestPropertyId
    ? await service
        .from("properties")
        .select("name, street, city, state, zip_code")
        .eq("id", requestPropertyId)
        .limit(1)
        .maybeSingle()
    : { data: null };
  const latestQuote = await service
    .from("provider_quotes")
    .select("public_share_token, status")
    .eq("request_id", requestId)
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const delivery = await sendRequestMessageEmail(service, {
    workspaceId,
    householdId: compactString(request.household_id),
    propertyName: compactString(property?.name),
    propertyAddress: [property?.street, property?.city, property?.state, property?.zip_code]
      .map((value) => compactString(value))
      .filter(Boolean)
      .join(", "),
    requestTitle: compactString(request.title),
    requestStatusLabel: requestStatusLabel(finalStatus),
    messageBody,
    quoteUrl: latestQuote.data?.public_share_token && compactString(latestQuote.data?.status) !== "draft"
      ? publicQuoteUrl(compactString(latestQuote.data.public_share_token))
      : null,
  }).catch((deliveryError) => ({
    sent: false,
    channel: "email",
    recipientCount: 0,
    error: deliveryError instanceof Error ? deliveryError.message : String(deliveryError),
  }));

  return { message, delivery, requestId, propertyId: requestPropertyId || propertyId || null };
}

/// Phase 73 sub-phase A: fire-and-forget push to every linked user in a
/// household. Used by the scheduling wrappers below so the homeowner
/// gets a notification the instant their provider proposes or accepts
/// a visit time. Errors are logged and swallowed — pushes shouldn't
/// fail the underlying state write.
/**
 * Push to every active member of the provider workspace serving this
 * request. The homeowner-side iOS calls this after their accept_visit_time
 * or propose_visit_time RPC succeeds — without it, the handyman has no
 * way to know they need to act on a counter-proposal until they happen
 * to refresh the operations desk.
 */
async function notifyProviderForRequest(
  service: ServiceClient,
  contractorId: string | null,
  payload: {
    title: string;
    body: string;
    requestId: string;
    eventType: string;
    extra?: Record<string, string>;
  },
): Promise<void> {
  if (!contractorId) return;

  try {
    // Contractor → workspace via provider_contractor_links.
    const { data: links } = await service
      .from("provider_contractor_links")
      .select("workspace_id")
      .eq("contractor_id", contractorId);

    const workspaceIds = ((links ?? []) as Record<string, unknown>[])
      .map((row) => compactString(row.workspace_id))
      .filter(Boolean);

    if (workspaceIds.length === 0) return;

    // Active workspace members → their auth user_ids.
    const { data: members } = await service
      .from("provider_workspace_members")
      .select("user_id")
      .in("workspace_id", workspaceIds)
      .eq("status", "active");

    const userIds = ((members ?? []) as Record<string, unknown>[])
      .map((row) => compactString(row.user_id))
      .filter(Boolean);

    if (userIds.length === 0) return;

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const data: Record<string, string> = {
      type: payload.eventType,
      request_id: payload.requestId,
      ...(payload.extra ?? {}),
    };

    await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({
        recipient_user_ids: userIds,
        title: payload.title,
        body: payload.body,
        data,
      }),
    });
  } catch (pushError) {
    console.error("[handyman-provider:notifyProvider] push failed", pushError);
  }
}

async function notifyHomeownersForRequest(
  service: ServiceClient,
  householdId: string | null,
  payload: {
    title: string;
    body: string;
    requestId: string;
    eventType: string;
    extra?: Record<string, string>;
  },
): Promise<void> {
  if (!householdId) return;

  try {
    const { data: userRows, error: userError } = await service
      .from("users")
      .select("id")
      .eq("household_id", householdId);

    if (userError) {
      console.error("[handyman-provider:notify] user lookup failed", userError);
      return;
    }

    const userIds = (userRows ?? [])
      .map((row) => compactString((row as Record<string, unknown>).id))
      .filter(Boolean);

    if (userIds.length === 0) return;

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const data: Record<string, string> = {
      type: payload.eventType,
      request_id: payload.requestId,
      household_id: householdId,
      ...(payload.extra ?? {}),
    };

    await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({
        recipient_user_ids: userIds,
        title: payload.title,
        body: payload.body,
        data,
      }),
    });
  } catch (pushError) {
    console.error("[handyman-provider:notify] push failed", pushError);
  }
}

function formatScheduleForPush(value: unknown): string {
  if (!value || typeof value !== "string") return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString("en-US", {
    timeZone: "America/New_York",
    weekday: "short",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

/// Phase 73 follow-up: homeowner-initiated `provider_contractor_links`
/// insert. Called by the iOS app right after `ChezDirectoryService.adopt`
/// stamps a `chez_field` contractor row. Without this link the
/// provider's dispatch board can't discover the household — they see
/// requests with `contractor_id` set, but the workspace → contractor
/// link table is empty, so the dashboard query returns nothing.
///
/// Authorization model:
///   1. Supabase auth JWT proves the caller is a real user.
///   2. We resolve the caller's household and require that the
///      contractor row's `household_id` matches — so the caller can
///      only link contractors *they* adopted.
///   3. The contractor's `notes` field must contain the workspace id
///      (the adopt flow stamps "Chez Field workspace: <uuid>"). This
///      proves the homeowner went through the directory adopt flow
///      rather than crafting a request to grab a workspace they
///      shouldn't have access to.
///   4. The workspace must be opted into the directory
///      (`is_listed_in_directory = true`).
///
/// Idempotent — re-calling with an existing link returns
/// `{ linked: true, alreadyLinked: true }` without erroring.
async function linkAdoptedProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const userId = compactString(user.id);
  if (!userId) throw new Error("Unauthorized");

  const workspaceId = compactString(body.workspaceId);
  const contractorId = compactString(body.contractorId);
  if (!workspaceId) throw new Error("workspaceId is required");
  if (!contractorId) throw new Error("contractorId is required");

  const householdId = await currentHouseholdIdForUser(service, userId);
  if (!householdId) throw new Error("No household for caller");

  // 1. Contractor must exist, belong to the caller's household, and
  //    carry the workspace_id in notes (proof of adoption flow).
  const { data: contractor, error: contractorError } = await service
    .from("contractors")
    .select("id, household_id, notes, source")
    .eq("id", contractorId)
    .maybeSingle();
  if (contractorError) throw contractorError;
  if (!contractor) throw new Error("Contractor not found");
  if (compactString(contractor.household_id) !== householdId) {
    throw new Error("Contractor belongs to a different household");
  }
  const notes = compactString(contractor.notes);
  if (!notes.includes(workspaceId)) {
    throw new Error("Contractor was not adopted from this workspace");
  }

  // 2. Workspace must exist and be directory-listed.
  const { data: workspace, error: workspaceError } = await service
    .from("provider_workspaces")
    .select("id, company_name, is_listed_in_directory")
    .eq("id", workspaceId)
    .maybeSingle();
  if (workspaceError) throw workspaceError;
  if (!workspace) throw new Error("Workspace not found");
  if (workspace.is_listed_in_directory !== true) {
    throw new Error("Workspace is not opted into the directory");
  }

  // 3. Idempotent insert — if the link already exists, return success.
  const { data: existingLinks, error: existingError } = await service
    .from("provider_contractor_links")
    .select("id")
    .eq("workspace_id", workspaceId)
    .eq("contractor_id", contractorId)
    .limit(1);
  if (existingError) throw existingError;
  if ((existingLinks ?? []).length > 0) {
    return { linked: true, alreadyLinked: true };
  }

  // 4. Whether this should be the workspace's primary link for this
  //    homeowner. We mark it primary if no other link exists for the
  //    same contractor (different workspaces could compete in theory,
  //    but in practice the homeowner only adopts one workspace per
  //    contractor row).
  const { data: anyExisting } = await service
    .from("provider_contractor_links")
    .select("id")
    .eq("contractor_id", contractorId)
    .limit(1);
  const isPrimary = (anyExisting ?? []).length === 0;

  const { error: insertError } = await service
    .from("provider_contractor_links")
    .insert({
      workspace_id: workspaceId,
      contractor_id: contractorId,
      is_primary: isPrimary,
      claim_source: "manual",
    });
  if (insertError) throw insertError;

  return { linked: true, alreadyLinked: false, isPrimary };
}

/// Phase 73 sub-phase A: provider-side wrapper around the
/// `propose_visit_time` SQL function. Validates that the calling user
/// belongs to the workspace whose contractor link covers this request,
/// then invokes the RPC with `proposed_by_role = 'handyman'`. The RPC
/// itself walks the status machine and appends a system message.
async function proposeVisitTimeForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  const proposedAt = compactString(body.proposedAt);
  const note = compactString(body.note);

  if (!requestId) throw new Error("requestId is required");
  if (!proposedAt) throw new Error("proposedAt is required");

  // Confirm this request actually belongs to a contractor linked to the
  // calling workspace before letting the RPC fire. Without this guard
  // any authenticated provider could propose times on any household's
  // requests; the SQL RPC runs as `security invoker` which only checks
  // RLS visibility on `handyman_requests`, not workspace ownership.
  const { data: request, error: requestError } = await service
    .from("handyman_requests")
    .select("id, contractor_id")
    .eq("id", requestId)
    .maybeSingle();

  if (requestError || !request) {
    throw requestError ?? new Error("Request not found");
  }

  const contractorId = compactString(request.contractor_id);
  if (!contractorId) {
    throw new Error("Request has no linked contractor");
  }

  const { data: links, error: linksError } = await service
    .from("provider_contractor_links")
    .select("contractor_id")
    .eq("workspace_id", workspaceId);

  if (linksError) throw linksError;
  const linkedContractorIds = new Set(
    ((links ?? []) as Record<string, unknown>[])
      .map((row) => compactString(row.contractor_id))
      .filter(Boolean),
  );

  if (!linkedContractorIds.has(contractorId)) {
    throw new Error("This workspace is not linked to this homeowner's contractor");
  }

  const { data: updated, error: rpcError } = await service.rpc("propose_visit_time", {
    p_request_id: requestId,
    p_proposed_at: proposedAt,
    p_proposed_by_role: "handyman",
    p_note: note || null,
  });

  if (rpcError) throw rpcError;

  const updatedRequest = (Array.isArray(updated) ? updated[0] : updated) as
    | Record<string, unknown>
    | null;
  const householdId = compactString(updatedRequest?.household_id);
  const workspace = (await service
    .from("provider_workspaces")
    .select("company_name")
    .eq("id", workspaceId)
    .maybeSingle()).data as Record<string, unknown> | null;
  const providerName = compactString(workspace?.company_name) || "Your provider";
  const formattedTime = formatScheduleForPush(updatedRequest?.proposed_visit_at);

  await notifyHomeownersForRequest(service, householdId, {
    title: `${providerName} proposed a visit time`,
    body: formattedTime
      ? `Suggested ${formattedTime}. Tap to accept or counter.`
      : "Tap to review the proposal.",
    requestId,
    eventType: "handyman_proposed_time",
  });

  return { request: updated };
}

/// Wave T: contractor proposes 2-3 candidate slots for the homeowner
/// to pick from. Inserts a single message into the thread with
/// `metadata.kind = "visit_proposed"` and a `slots` array; the
/// homeowner-side iOS reads this metadata to render a slot card with
/// tap-to-accept buttons. We do NOT call propose_visit_time per slot
/// because that would create N proposed_visit_at writes on the request
/// row; the slot card is just chat content. When the homeowner accepts
/// one, the existing accept_visit_time path takes over.
async function proposeVisitSlotsForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");

  const rawSlots = Array.isArray(body.slots) ? body.slots : [];
  const slots = (rawSlots as unknown[])
    .map((slot) => {
      if (!slot || typeof slot !== "object") return null;
      const start = compactString((slot as Record<string, unknown>).start);
      const end = compactString((slot as Record<string, unknown>).end);
      const note = compactString((slot as Record<string, unknown>).note);
      if (!start) return null;
      return { start, end: end || null, note: note || null };
    })
    .filter((slot): slot is { start: string; end: string | null; note: string | null } => slot !== null);

  if (slots.length === 0) {
    throw new Error("At least one slot is required");
  }
  if (slots.length > 5) {
    throw new Error("Send no more than five candidate slots at a time");
  }

  // Confirm workspace ownership of this request before writing.
  const { data: request, error: requestError } = await service
    .from("handyman_requests")
    .select("id, contractor_id, household_id, title, status")
    .eq("id", requestId)
    .maybeSingle();

  if (requestError || !request) {
    throw requestError ?? new Error("Request not found");
  }

  const contractorId = compactString(request.contractor_id);
  if (!contractorId) {
    throw new Error("Request has no linked contractor");
  }

  const { data: links, error: linksError } = await service
    .from("provider_contractor_links")
    .select("contractor_id")
    .eq("workspace_id", workspaceId);

  if (linksError) throw linksError;
  const linkedContractorIds = new Set(
    ((links ?? []) as Record<string, unknown>[])
      .map((row) => compactString(row.contractor_id))
      .filter(Boolean),
  );

  if (!linkedContractorIds.has(contractorId)) {
    throw new Error("This workspace is not linked to this homeowner's contractor");
  }

  const messageBody = compactString(body.body) ||
    `Pick a time that works. We have ${slots.length} option${slots.length === 1 ? "" : "s"}:\n` +
      slots
        .map((slot, idx) => {
          const t = formatScheduleForPush(slot.start) || slot.start;
          return `${idx + 1}. ${t}`;
        })
        .join("\n");

  const { data: message, error: messageError } = await service
    .from("handyman_request_messages")
    .insert({
      request_id: requestId,
      household_id: request.household_id,
      sender_role: "vendor",
      body: messageBody,
      metadata: {
        event: "provider_message",
        kind: "visit_proposed",
        slots,
      },
    })
    .select()
    .single();

  if (messageError || !message) {
    throw messageError ?? new Error("Failed to insert visit proposal message");
  }

  // Bump request updated_at so the inbox reorders.
  await service
    .from("handyman_requests")
    .update({ updated_at: isoNow() })
    .eq("id", requestId);

  return { message, requestId, slots };
}

/// Wave T: upload one photo attachment for a request thread. Caller
/// posts base64 data plus a content_type and filename. We upload to
/// the message-attachments bucket and return a signed URL the caller
/// can immediately render in the thread bubble. The actual message
/// row gets created by a follow-up `send_message` call where the
/// caller passes `metadata.attachments` with the path/URL we returned.
async function uploadMessageAttachment(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  if (!requestId) throw new Error("requestId is required");

  const dataBase64 = compactString(body.dataBase64);
  if (!dataBase64) throw new Error("dataBase64 is required");

  const contentType = compactString(body.contentType) || "image/jpeg";
  if (!contentType.startsWith("image/")) {
    throw new Error("Only image content types are supported");
  }

  // Confirm workspace ownership of this request before writing.
  const { data: request, error: requestError } = await service
    .from("handyman_requests")
    .select("id, contractor_id, household_id")
    .eq("id", requestId)
    .maybeSingle();

  if (requestError || !request) {
    throw requestError ?? new Error("Request not found");
  }

  const contractorId = compactString(request.contractor_id);
  if (!contractorId) {
    throw new Error("Request has no linked contractor");
  }

  const { data: links, error: linksError } = await service
    .from("provider_contractor_links")
    .select("contractor_id")
    .eq("workspace_id", workspaceId);

  if (linksError) throw linksError;
  const linkedContractorIds = new Set(
    ((links ?? []) as Record<string, unknown>[])
      .map((row) => compactString(row.contractor_id))
      .filter(Boolean),
  );

  if (!linkedContractorIds.has(contractorId)) {
    throw new Error("This workspace is not linked to this homeowner's contractor");
  }

  // Decode base64. Reject anything bigger than 8 MB (after decode) to
  // keep storage bills sane; the SPA already resizes to ~1600px JPEG
  // at 80% quality before sending so this is a hard ceiling.
  const cleanBase64 = dataBase64.replace(/^data:[^,]+,/, "");
  const bytes = base64ToUint8Array(cleanBase64);
  if (bytes.byteLength > 8 * 1024 * 1024) {
    throw new Error("Image too large. Keep attachments under 8MB.");
  }

  // Pick an extension based on content type so the URL is friendly.
  const extension = contentType === "image/png"
    ? "png"
    : contentType === "image/webp"
      ? "webp"
      : contentType === "image/gif"
        ? "gif"
        : "jpg";

  const random = crypto.randomUUID().replace(/-/g, "").slice(0, 16);
  const householdId = compactString(request.household_id);
  const path = `${householdId}/${requestId}/${random}.${extension}`;

  const { error: uploadError } = await service.storage
    .from("message-attachments")
    .upload(path, bytes, {
      contentType,
      upsert: false,
    });

  if (uploadError) {
    throw new Error(`Upload failed: ${uploadError.message}`);
  }

  // Mint a signed URL valid 7 days. The reader path will re-mint each
  // time the thread is fetched (same pattern as document-viewer).
  const { data: signed, error: signedError } = await service.storage
    .from("message-attachments")
    .createSignedUrl(path, 60 * 60 * 24 * 7);

  if (signedError || !signed) {
    throw signedError ?? new Error("Failed to mint signed URL");
  }

  return {
    path,
    contentType,
    signedUrl: signed.signedUrl,
    bytes: bytes.byteLength,
  };
}

// Decode base64 to a Uint8Array. Deno doesn't ship Buffer; the standard
// approach is atob + Uint8Array.from. We strip data URL prefixes upstream.
function base64ToUint8Array(base64: string): Uint8Array {
  const binary = atob(base64);
  const len = binary.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

/// Phase 73 sub-phase A: provider-side wrapper around `accept_visit_time`.
/// Walks `confirmed_visit_at = proposed_visit_at` + status to `confirmed`,
/// appends an audit message. Same workspace-ownership check as
/// `proposeVisitTimeForProvider`.
async function acceptVisitTimeForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const requestId = compactString(body.requestId);
  const note = compactString(body.note);
  if (!requestId) throw new Error("requestId is required");

  const { data: request, error: requestError } = await service
    .from("handyman_requests")
    .select("id, contractor_id")
    .eq("id", requestId)
    .maybeSingle();

  if (requestError || !request) {
    throw requestError ?? new Error("Request not found");
  }

  const contractorId = compactString(request.contractor_id);
  if (!contractorId) {
    throw new Error("Request has no linked contractor");
  }

  const { data: links, error: linksError } = await service
    .from("provider_contractor_links")
    .select("contractor_id")
    .eq("workspace_id", workspaceId);

  if (linksError) throw linksError;
  const linkedContractorIds = new Set(
    ((links ?? []) as Record<string, unknown>[])
      .map((row) => compactString(row.contractor_id))
      .filter(Boolean),
  );

  if (!linkedContractorIds.has(contractorId)) {
    throw new Error("This workspace is not linked to this homeowner's contractor");
  }

  const { data: updated, error: rpcError } = await service.rpc("accept_visit_time", {
    p_request_id: requestId,
    p_accepted_by_role: "handyman",
    p_note: note || null,
  });

  if (rpcError) throw rpcError;

  const updatedRequest = (Array.isArray(updated) ? updated[0] : updated) as
    | Record<string, unknown>
    | null;
  const householdId = compactString(updatedRequest?.household_id);
  const workspace = (await service
    .from("provider_workspaces")
    .select("company_name")
    .eq("id", workspaceId)
    .maybeSingle()).data as Record<string, unknown> | null;
  const providerName = compactString(workspace?.company_name) || "Your provider";
  const formattedTime = formatScheduleForPush(updatedRequest?.confirmed_visit_at);

  await notifyHomeownersForRequest(service, householdId, {
    title: `${providerName} confirmed your visit`,
    body: formattedTime
      ? `Locked in for ${formattedTime}.`
      : "The visit time is now confirmed.",
    requestId,
    eventType: "handyman_accepted_time",
  });

  return { request: updated };
}

// ============================================================================
// Phase 84.5 — Free Handyman Assessment + 3-Mode Onboarding
// ============================================================================
//
// Field-side actions for capturing systems / vendors / routines / documents
// during a home_assessment visit. The homeowner-side actions live in
// chez-concierge/index.ts. The shared workspace is the public.home_assessments
// table created by 20261210_chez_home_assessment.sql.

interface AssessmentRecord {
  id: string;
  household_id: string;
  property_id: string;
  status: string;
  visit_assignment_id: string | null;
  handyman_member_id: string | null;
  captured_quiz_state: Record<string, unknown> | null;
  captured_systems: Array<Record<string, unknown>> | null;
  captured_contractors: Array<Record<string, unknown>> | null;
  captured_routines: Array<Record<string, unknown>> | null;
  captured_document_paths: string[] | null;
  captured_attributes: Record<string, unknown> | null;
}

async function loadAssessment(service: ServiceClient, assessmentId: string): Promise<AssessmentRecord | null> {
  const { data, error } = await service
    .from("home_assessments")
    .select("*")
    .eq("id", assessmentId)
    .maybeSingle();
  if (error || !data) return null;
  return data as unknown as AssessmentRecord;
}

async function assertHandymanCanWrite(
  service: ServiceClient,
  user: { id: string },
  assessment: AssessmentRecord
): Promise<{ ok: boolean; reason?: string }> {
  if (!assessment.visit_assignment_id) {
    return { ok: false, reason: "assessment has no dispatched visit yet" };
  }
  const { data: visit } = await service
    .from("provider_visit_assignments")
    .select("workspace_id, assigned_member_id")
    .eq("id", assessment.visit_assignment_id)
    .maybeSingle();
  if (!visit) return { ok: false, reason: "visit not found" };
  const v = visit as { workspace_id: string; assigned_member_id: string | null };
  // Caller must be a member of the workspace.
  const { data: membership } = await service
    .from("provider_workspace_members")
    .select("id, role")
    .eq("workspace_id", v.workspace_id)
    .eq("user_id", user.id)
    .maybeSingle();
  if (!membership) return { ok: false, reason: "not a member of the assigned workspace" };
  return { ok: true };
}

async function dispatchHomeAssessment(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const assessmentId = compactString(body.assessment_id);
  const workspaceId = compactString(body.workspace_id);
  const memberId = compactString(body.member_id) || null;
  const routeDate = compactString(body.route_date) || null;
  const windowStart = compactString(body.window_start_time) || null;
  const windowEnd = compactString(body.window_end_time) || null;
  if (!assessmentId || !workspaceId) {
    throw new Error("assessment_id + workspace_id required");
  }
  await assertWorkspaceAccess(service, user.id, workspaceId);

  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");

  // home_assessment dispatch creates a placeholder handyman_request +
  // provider_visit_assignment so the technician sees it in their queue.
  // The visit's request_id points at a stub handyman_requests row.

  // 1. Create a stub handyman_request (the existing assignment infra
  //    requires one; we treat it as the assessment's surrogate).
  const { data: stubRequest, error: reqErr } = await service
    .from("handyman_requests")
    .insert({
      household_id: assessment.household_id,
      property_id: assessment.property_id,
      title: "Home assessment (Chez free)",
      summary: "Capture systems, vendors, routines, documents during the free Chez home assessment.",
      status: "scheduled",
      request_kind: "home_assessment",
    })
    .select("id")
    .single();
  if (reqErr || !stubRequest) {
    // request_kind column may not exist on older schemas — retry
    // without it. Surfaces as a clearer error if both fail.
    const { data: retry } = await service
      .from("handyman_requests")
      .insert({
        household_id: assessment.household_id,
        property_id: assessment.property_id,
        title: "Home assessment (Chez free)",
        summary: "Capture systems, vendors, routines, documents during the free Chez home assessment.",
        status: "scheduled",
      })
      .select("id")
      .single();
    if (!retry) throw new Error(`failed to create stub request: ${reqErr?.message ?? "unknown"}`);
    (stubRequest as unknown as { id: string }).id = (retry as { id: string }).id;
  }
  const stubRequestId = (stubRequest as { id: string }).id;

  // 2. Create the visit assignment, tagged as home_assessment.
  const { data: visit, error: visitErr } = await service
    .from("provider_visit_assignments")
    .insert({
      workspace_id: workspaceId,
      request_id: stubRequestId,
      assigned_member_id: memberId,
      assigned_by_user_id: user.id,
      route_date: routeDate,
      window_start_time: windowStart,
      window_end_time: windowEnd,
      visit_type: "home_assessment",
    })
    .select("*")
    .single();
  if (visitErr || !visit) throw new Error(`failed to create visit: ${visitErr?.message ?? "unknown"}`);

  // 3. Update the assessment row to point at the visit + technician.
  await service
    .from("home_assessments")
    .update({
      visit_assignment_id: (visit as { id: string }).id,
      handyman_member_id: memberId,
      status: "scheduled",
      scheduled_at: isoNow(),
    })
    .eq("id", assessmentId);

  return { ok: true, visit_assignment_id: (visit as { id: string }).id, request_id: stubRequestId };
}

async function markAssessmentEnRoute(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const assessmentId = compactString(body.assessment_id);
  if (!assessmentId) throw new Error("assessment_id required");
  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");
  const auth = await assertHandymanCanWrite(service, user, assessment);
  if (!auth.ok) throw new Error(auth.reason ?? "not authorized");

  await service
    .from("home_assessments")
    .update({ status: "en_route", en_route_at: isoNow() })
    .eq("id", assessmentId);
  return { ok: true, status: "en_route" };
}

async function startAssessmentVisit(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const assessmentId = compactString(body.assessment_id);
  if (!assessmentId) throw new Error("assessment_id required");
  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");
  const auth = await assertHandymanCanWrite(service, user, assessment);
  if (!auth.ok) throw new Error(auth.reason ?? "not authorized");

  await service
    .from("home_assessments")
    .update({ status: "in_progress", started_at: isoNow() })
    .eq("id", assessmentId);
  return { ok: true, status: "in_progress" };
}

function mergeJsonbArrayByKey(
  existing: Array<Record<string, unknown>> | null,
  incoming: Array<Record<string, unknown>> | null,
  keyField: string
): Array<Record<string, unknown>> {
  // Dedup by keyField, preferring incoming values. Used for captured_systems
  // (key=category), captured_contractors (key=company_name),
  // captured_routines (key=kind+vendor_name).
  const merged = new Map<string, Record<string, unknown>>();
  for (const item of existing ?? []) {
    const k = compactString((item as Record<string, unknown>)[keyField]).toLowerCase();
    if (k) merged.set(k, item);
  }
  for (const item of incoming ?? []) {
    const k = compactString((item as Record<string, unknown>)[keyField]).toLowerCase();
    if (k) merged.set(k, { ...(merged.get(k) ?? {}), ...item });
  }
  return Array.from(merged.values());
}

async function updateAssessmentProgress(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const assessmentId = compactString(body.assessment_id);
  if (!assessmentId) throw new Error("assessment_id required");
  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");
  const auth = await assertHandymanCanWrite(service, user, assessment);
  if (!auth.ok) throw new Error(auth.reason ?? "not authorized");

  const updates: Record<string, unknown> = {};

  if (body.captured_quiz_state && typeof body.captured_quiz_state === "object") {
    updates.captured_quiz_state = {
      ...(assessment.captured_quiz_state ?? {}),
      ...(body.captured_quiz_state as Record<string, unknown>),
    };
  }
  if (Array.isArray(body.captured_systems)) {
    updates.captured_systems = mergeJsonbArrayByKey(
      assessment.captured_systems,
      body.captured_systems as Array<Record<string, unknown>>,
      "category"
    );
  }
  if (Array.isArray(body.captured_contractors)) {
    updates.captured_contractors = mergeJsonbArrayByKey(
      assessment.captured_contractors,
      body.captured_contractors as Array<Record<string, unknown>>,
      "company_name"
    );
  }
  if (Array.isArray(body.captured_routines)) {
    // Routines key on (kind + vendor_name) — synthesize a pseudo-key.
    const synthesized = (body.captured_routines as Array<Record<string, unknown>>).map((r) => ({
      ...r,
      _key: `${compactString(r.kind)}::${compactString(r.vendor_name)}`,
    }));
    const existing = (assessment.captured_routines ?? []).map((r) => ({
      ...r,
      _key: `${compactString(r.kind)}::${compactString(r.vendor_name)}`,
    }));
    updates.captured_routines = mergeJsonbArrayByKey(existing, synthesized, "_key").map((r) => {
      const copy = { ...r };
      delete (copy as Record<string, unknown>)._key;
      return copy;
    });
  }
  if (Array.isArray(body.captured_document_paths)) {
    const existing = new Set(assessment.captured_document_paths ?? []);
    for (const p of body.captured_document_paths as string[]) {
      const c = compactString(p);
      if (c) existing.add(c);
    }
    updates.captured_document_paths = Array.from(existing);
  }
  if (body.captured_attributes && typeof body.captured_attributes === "object") {
    updates.captured_attributes = {
      ...(assessment.captured_attributes ?? {}),
      ...(body.captured_attributes as Record<string, unknown>),
    };
  }
  if (typeof body.handyman_notes === "string") {
    updates.handyman_notes = body.handyman_notes;
  }
  if (Object.keys(updates).length === 0) {
    return { ok: true, no_op: true };
  }

  await service.from("home_assessments").update(updates).eq("id", assessmentId);
  return { ok: true };
}

async function submitAssessmentData(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>,
  serviceUrl: string,
  serviceRoleKey: string
) {
  const assessmentId = compactString(body.assessment_id);
  if (!assessmentId) throw new Error("assessment_id required");
  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");
  const auth = await assertHandymanCanWrite(service, user, assessment);
  if (!auth.ok) throw new Error(auth.reason ?? "not authorized");
  if (assessment.status === "completed" || assessment.status === "cancelled") {
    throw new Error(`cannot submit from status ${assessment.status}`);
  }

  // Final updates on the captured_* JSONB if the handyman shipped any
  // last-second changes alongside submit.
  if (
    body.captured_quiz_state || body.captured_systems || body.captured_contractors ||
    body.captured_routines || body.captured_document_paths || body.captured_attributes ||
    body.handyman_notes
  ) {
    await updateAssessmentProgress(service, user, body);
  }

  await service
    .from("home_assessments")
    .update({ status: "submitted", submitted_at: isoNow() })
    .eq("id", assessmentId);

  // Run the ingestion path. On any error, roll status back to in_progress.
  let ingestionError: string | null = null;
  try {
    await ingestAssessment(service, assessmentId);
  } catch (err) {
    ingestionError = err instanceof Error ? err.message : String(err);
    console.error("[handyman-provider] ingestion failed:", err);
    await service
      .from("home_assessments")
      .update({
        status: "submitted", // stay submitted so admin can retry; admin_notes captures the error
        admin_notes: `Ingestion failed: ${ingestionError}`,
      })
      .eq("id", assessmentId);
    return { ok: false, error: `ingestion failed: ${ingestionError}` };
  }

  // Push the homeowner that their home is set up.
  const fresh = await loadAssessment(service, assessmentId);
  if (fresh) {
    const { data: householdUsers } = await service
      .from("users")
      .select("id")
      .eq("household_id", fresh.household_id);
    const userIds = ((householdUsers as Array<{ id: string }> | null) ?? []).map((u) => u.id);
    if (userIds.length > 0) {
      await sendAssessmentPush(serviceUrl, serviceRoleKey, userIds, "Your home is set up", "Your Chez handyman finished. Open Chez to see what we captured.", {
        type: "chez_assessment_complete",
        assessment_id: assessmentId,
      });
    }
  }

  return { ok: true, status: "awaiting_review" };
}

async function uploadAssessmentDocument(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const assessmentId = compactString(body.assessment_id);
  const filename = compactString(body.filename);
  const contentType = compactString(body.content_type) || "application/octet-stream";
  const base64 = compactString(body.file_base64);
  if (!assessmentId || !filename || !base64) {
    throw new Error("assessment_id + filename + file_base64 required");
  }
  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");
  const auth = await assertHandymanCanWrite(service, user, assessment);
  if (!auth.ok) throw new Error(auth.reason ?? "not authorized");

  // Decode + upload to the documents bucket under assessments/<id>/...
  const safeName = filename.replace(/[^a-zA-Z0-9_.\-]/g, "_");
  const path = `assessments/${assessmentId}/${Date.now()}_${safeName}`;
  const bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
  const { error: upErr } = await service.storage
    .from("documents")
    .upload(path, bytes, { contentType, upsert: false });
  if (upErr) throw new Error(`upload failed: ${upErr.message}`);

  // Append the path to captured_document_paths.
  const existing = assessment.captured_document_paths ?? [];
  const next = Array.from(new Set([...existing, path]));
  await service.from("home_assessments").update({ captured_document_paths: next }).eq("id", assessmentId);

  return { ok: true, path };
}

async function fetchAssessmentForVisit(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const visitId = compactString(body.visit_assignment_id);
  const assessmentId = compactString(body.assessment_id);
  if (!visitId && !assessmentId) {
    throw new Error("visit_assignment_id or assessment_id required");
  }

  let q = service.from("home_assessments").select("*");
  if (assessmentId) {
    q = q.eq("id", assessmentId);
  } else {
    q = q.eq("visit_assignment_id", visitId);
  }
  const { data, error } = await q.maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) return { assessment: null };

  // Also include household + property context for the field app's
  // "where am I" header.
  const a = data as unknown as AssessmentRecord;
  const { data: property } = await service
    .from("properties")
    .select("id, address_line_1, city, state, zip_code, year_built, square_footage")
    .eq("id", a.property_id)
    .maybeSingle();
  const { data: household } = await service
    .from("households")
    .select("id, name")
    .eq("id", a.household_id)
    .maybeSingle();

  return { assessment: a, property, household };
}

async function sendAssessmentPush(
  serviceUrl: string,
  serviceRoleKey: string,
  userIds: string[],
  title: string,
  bodyText: string,
  data: Record<string, unknown>
) {
  if (!userIds.length) return;
  try {
    await fetch(`${serviceUrl}/functions/v1/send-push-notification`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${serviceRoleKey}`,
        apikey: serviceRoleKey,
      },
      body: JSON.stringify({ user_ids: userIds, title, body: bodyText, data }),
    });
  } catch (err) {
    console.error("[handyman-provider] push failed:", err);
  }
}

// ============================================================================
// Phase 84.5 — Ingestion path
// ============================================================================
//
// Reads captured_* JSONB from a submitted home_assessments row and writes
// the canonical Haven tables (home_systems, contractors, routines,
// documents, properties.house_quiz_state).  Run on submit_assessment_data
// (auto) or admin "Run ingestion" override.

async function ingestAssessment(service: ServiceClient, assessmentId: string) {
  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");
  if (assessment.status === "completed" || assessment.status === "awaiting_review") {
    return; // idempotent — don't re-ingest
  }

  const householdId = assessment.household_id;
  const propertyId = assessment.property_id;
  const isSupplement = (assessment as Record<string, unknown>).is_existing_user_supplement === true;

  // ============================================================
  // 1. SYSTEMS — G6 / G15 / G18 / G44 (condition + decommission)
  // ============================================================
  const systems = (assessment.captured_systems ?? []) as Array<Record<string, unknown>>;
  for (const s of systems) {
    const category = compactString(s.category);
    if (!category) continue;
    const manufacturer = compactString(s.manufacturer) || null;
    const model = compactString(s.model) || null;
    const installYear = typeof s.install_year === "number" ? s.install_year : null;
    const installDate = installYear ? `${installYear}-01-01` : null;
    const subtype = compactString(s.subtype) || null;
    const notes = compactString(s.notes) || null;
    const conditionRating = compactString(s.condition_rating) || null;
    const conditionNotes = compactString(s.condition_notes) || null;
    const conditionPhotos = Array.isArray(s.condition_photos) ? s.condition_photos : [];
    const equipmentPhotos = Array.isArray(s.equipment_plate_photos) ? s.equipment_plate_photos : [];
    const isDecommissioned = s.is_decommissioned === true;
    const decommissionReason = compactString(s.decommissioned_reason) || null;

    // find-or-create by (household, property, category, model). Supplement
    // mode patches existing rows; first-time mode skips duplicates.
    const { data: existing } = await service
      .from("home_systems")
      .select("id, install_date_source, condition_rating")
      .eq("household_id", householdId)
      .eq("property_id", propertyId)
      .eq("category", category)
      .eq("model_number", model ?? "")
      .maybeSingle();

    if (existing) {
      // Supplement / update path: handyman observation always wins over
      // ATTOM estimate (G6). Apply decommission flag if set.
      const update: Record<string, unknown> = {
        condition_rating: conditionRating ?? existing.condition_rating,
        condition_notes: conditionNotes,
        condition_photos: conditionPhotos.length ? conditionPhotos : undefined,
        last_assessed_at: isoNow(),
        install_date_source: existing.install_date_source === "vendor_invoice"
          ? "vendor_invoice"
          : "handyman_observed",
      };
      if (isDecommissioned) {
        update.is_active = false;
        update.decommissioned_at = isoNow();
        update.decommissioned_reason = decommissionReason;
      }
      await service.from("home_systems").update(update).eq("id", existing.id);
      continue;
    }

    await service.from("home_systems").insert({
      household_id: householdId,
      property_id: propertyId,
      category,
      subtype,
      name: [manufacturer, model].filter(Boolean).join(" ") || category,
      manufacturer,
      model_number: model,
      install_date: installDate,
      install_date_source: "handyman_observed",
      notes,
      condition_rating: conditionRating,
      condition_notes: conditionNotes,
      condition_photos: conditionPhotos,
      photos: equipmentPhotos,
      last_assessed_at: isoNow(),
      onboarded_via: "handyman_assessment",
      is_active: !isDecommissioned,
      decommissioned_at: isDecommissioned ? isoNow() : null,
      decommissioned_reason: isDecommissioned ? decommissionReason : null,
    });
  }

  // ============================================================
  // 2. CONTRACTORS — G7 (fuzzy dedup) / G8 (canonical category) / G15
  // ============================================================
  const contractors = (assessment.captured_contractors ?? []) as Array<Record<string, unknown>>;
  // Pre-load existing contractors once for fuzzy dedup
  const { data: existingContractors } = await service
    .from("contractors")
    .select("id, company_name, phone, category")
    .eq("household_id", householdId);
  const existingList = (existingContractors ?? []) as Array<{
    id: string; company_name: string; phone: string | null; category: string | null;
  }>;

  for (const c of contractors) {
    const companyName = compactString(c.company_name);
    if (!companyName) continue;
    const phone = compactString(c.phone) || null;
    // Canonicalize category from chip_id when handyman captured via chip
    const chipId = compactString(c.chip_id) || null;
    const category = compactString(c.category)
      || (chipId ? householdContractorCategoryFor(chipId) : null);

    // Fuzzy dedup against existing roster
    const match = existingList.find((row) => isLikelySameVendor(
      { companyName: row.company_name, phone: row.phone },
      { companyName, phone }
    ));

    if (match) {
      // Patch only fields that are currently null
      const update: Record<string, unknown> = {};
      if (!match.phone && phone) update.phone = phone;
      if (!match.category && category) update.category = category;
      if (Object.keys(update).length > 0) {
        await service.from("contractors").update(update).eq("id", match.id);
      }
      continue;
    }

    const { data: inserted } = await service
      .from("contractors")
      .insert({
        household_id: householdId,
        company_name: companyName,
        category,
        phone,
        email: compactString(c.email) || null,
        website: compactString(c.website) || null,
        source: "home_assessment",
        onboarded_via: "handyman_assessment",
      })
      .select("id, company_name, phone, category")
      .single();
    if (inserted) {
      existingList.push(inserted as { id: string; company_name: string; phone: string | null; category: string | null });
    }
  }

  // ============================================================
  // 3. ROUTINES — G12 full RoutineInsert shape, G15 attribution
  // ============================================================
  const routines = (assessment.captured_routines ?? []) as Array<Record<string, unknown>>;
  for (const r of routines) {
    const kind = compactString(r.kind) || (compactString(r.chip_id) ? routineKindForChip(compactString(r.chip_id)) : null);
    if (!kind) continue;
    const vendorName = compactString(r.vendor_name) || null;
    const label = compactString(r.label) || (vendorName ? `${kind} · ${vendorName}` : kind);

    // Apply default cadence + active_months based on kind, then override
    // with anything explicitly captured.
    const defaults = defaultCadenceForQuizRoutine(kind);
    const cadenceType = compactString(r.cadence_type) || defaults.cadenceType;
    const cadenceIntervalDays = typeof r.cadence_interval_days === "number"
      ? r.cadence_interval_days
      : defaults.cadenceIntervalDays;
    const daysOfWeek = Array.isArray(r.days_of_week)
      ? r.days_of_week
      : (typeof r.day_of_week === "number" ? [r.day_of_week] : null);
    const activeMonths = Array.isArray(r.active_months) ? r.active_months : defaults.activeMonths;
    const timeOfDay = compactString(r.time_of_day) || null;

    // Look up vendor_id by company name (with fuzzy dedup just used).
    let vendorId: string | null = null;
    if (vendorName) {
      const v = existingList.find((row) =>
        normalizeCompanyName(row.company_name) === normalizeCompanyName(vendorName)
      );
      if (v) vendorId = v.id;
    }

    // Dedup by (household, kind, vendor_id)
    const { data: existing } = await service
      .from("routines")
      .select("id")
      .eq("household_id", householdId)
      .eq("routine_kind", kind)
      .eq("vendor_id", vendorId ?? "")
      .is("archived_at", null)
      .maybeSingle();
    if (existing) continue;

    await service.from("routines").insert({
      household_id: householdId,
      property_id: propertyId,
      label,
      routine_kind: kind,
      cadence_type: cadenceType,
      cadence_interval_days: cadenceIntervalDays,
      days_of_week: daysOfWeek,
      active_months: activeMonths,
      time_of_day: timeOfDay,
      vendor_id: vendorId,
      setup_state: vendorId ? "active" : "pending_vendor",
      scope: "property",
      onboarded_via: "handyman_assessment",
    });
  }

  // ============================================================
  // 4. VEHICLES — Q24 (was missing from original)
  // ============================================================
  const vehicles = ((assessment as Record<string, unknown>).captured_vehicles ?? []) as Array<Record<string, unknown>>;
  for (const v of vehicles) {
    const vin = compactString(v.vin);
    const make = compactString(v.make);
    const model = compactString(v.model);
    if (!vin && !make && !model) continue;
    // Dedup on VIN
    if (vin) {
      const { data: existing } = await service
        .from("vehicles")
        .select("id")
        .eq("household_id", householdId)
        .eq("vin", vin)
        .maybeSingle();
      if (existing) continue;
    }
    await service.from("vehicles").insert({
      household_id: householdId,
      vin: vin || null,
      year: typeof v.year === "number" ? v.year : null,
      make: make || null,
      model: model || null,
      trim: compactString(v.trim) || null,
      color: compactString(v.color) || null,
      license_plate: compactString(v.license_plate) || null,
      mileage: typeof v.mileage === "number" ? v.mileage : null,
      onboarded_via: "handyman_assessment",
    });
  }

  // ============================================================
  // 5. UTILITY ACCOUNTS — Q16/17/19/26
  // ============================================================
  const utilityAccounts = ((assessment as Record<string, unknown>).captured_utility_accounts ?? []) as Array<Record<string, unknown>>;
  for (const ua of utilityAccounts) {
    const providerName = compactString(ua.provider_name);
    const providerType = compactString(ua.provider_type);
    if (!providerName || !providerType) continue;
    const { data: existing } = await service
      .from("utility_accounts")
      .select("id")
      .eq("household_id", householdId)
      .eq("provider_type", providerType)
      .ilike("provider_name", providerName)
      .maybeSingle();
    if (existing) continue;
    await service.from("utility_accounts").insert({
      household_id: householdId,
      property_id: propertyId,
      provider_name: providerName,
      provider_type: providerType,
      account_number: compactString(ua.account_number) || null,
      monthly_cost_cents: typeof ua.monthly_cost_cents === "number" ? ua.monthly_cost_cents : null,
      phone: compactString(ua.phone) || null,
      website: compactString(ua.website) || null,
      onboarded_via: "handyman_assessment",
    });
  }

  // ============================================================
  // 6. DOCUMENTS — G4 attribution
  // ============================================================
  const docPaths = (assessment.captured_document_paths ?? []) as Array<string | Record<string, unknown>>;
  for (const item of docPaths) {
    const path = typeof item === "string" ? item : compactString((item as Record<string, unknown>).path);
    if (!path) continue;
    const docMeta = typeof item === "object" ? (item as Record<string, unknown>) : {};
    const filename = path.split("/").pop() ?? path;
    const { data: existing } = await service
      .from("documents")
      .select("id")
      .eq("household_id", householdId)
      .eq("file_path", path)
      .maybeSingle();
    if (existing) continue;
    await service.from("documents").insert({
      household_id: householdId,
      property_id: propertyId,
      filename,
      file_path: path,
      category: compactString(docMeta.category) || "Home Document",
      visible_to_home_managers: true,
      uploaded_via: "handyman_assessment",
    });
  }

  // ============================================================
  // 7. QUICK-FIXES → backdated service_records (G21)
  // ============================================================
  const quickFixes = ((assessment as Record<string, unknown>).captured_quick_fixes ?? []) as Array<Record<string, unknown>>;
  for (const qf of quickFixes) {
    const description = compactString(qf.description);
    if (!description) continue;
    await service.from("service_records").insert({
      household_id: householdId,
      property_id: propertyId,
      system_id: compactString(qf.system_id) || null,
      service_date: new Date().toISOString().slice(0, 10),
      description,
      cost_cents: typeof qf.cost_cents === "number" ? qf.cost_cents : 0,
      notes: "Fixed during Chez handyman assessment.",
    });
  }

  // ============================================================
  // 8. RECOMMENDED TASKS → chez_requests / property_projects /
  //    maintenance_tasks (G19, G20, G25, G36, G45, G46, G48)
  // ============================================================
  const { data: recommendations } = await service
    .from("assessment_recommended_tasks")
    .select("*")
    .eq("assessment_id", assessmentId);
  const recList = (recommendations ?? []) as Array<Record<string, unknown>>;
  const HIGH_COST_THRESHOLD_CENTS = 500_000; // $5,000

  for (const rec of recList) {
    // Skip already-handled rows
    if (rec.fixed_during_visit === true) continue;
    if (rec.spawned_chez_request_id || rec.spawned_project_id || rec.spawned_maintenance_task_id) continue;

    const recId = compactString(rec.id);
    const homeownerResponse = compactString(rec.homeowner_response);
    const urgency = compactString(rec.urgency) as AssessmentUrgency;
    const isDisputed = rec.disputed === true;
    const isHomeownerHandled = homeownerResponse === "homeowner_handled";
    const isDeclined = homeownerResponse === "declined";
    const observationSource = compactString(rec.observation_source) || "handyman_observed";
    const needsVerification = rec.needs_verification === true || observationSource === "homeowner_reported";
    const estCost = typeof rec.estimated_cost_cents === "number" ? rec.estimated_cost_cents : 0;

    // G46: homeowner_handled → spawn maintenance_task with their date
    if (isHomeownerHandled) {
      const { data: task } = await service
        .from("maintenance_tasks")
        .insert({
          household_id: householdId,
          property_id: propertyId,
          system_id: compactString(rec.system_id) || null,
          title: compactString(rec.title),
          description: compactString(rec.description) || null,
          priority: "medium",
          status: "pending",
          assignment_type: "personal",
          assigned_route: "diy",
          scheduled_date: compactString(rec.homeowner_handled_scheduled_for) || null,
          notes: `Homeowner-handled via ${compactString(rec.homeowner_handled_vendor) || "their own arrangement"}.`,
        })
        .select("id")
        .single();
      if (task) {
        await service
          .from("assessment_recommended_tasks")
          .update({ spawned_maintenance_task_id: (task as { id: string }).id })
          .eq("id", recId);
      }
      continue;
    }

    // G48: declined-but-disputed → still create chez_request, mark disputed
    // G48: declined-and-not-disputed → skip entirely (homeowner doesn't want it)
    if (isDeclined && !isDisputed) continue;

    const routing = chezRequestRoutingForUrgency(urgency);
    const tags: string[] = [];
    if (needsVerification) tags.push("needs_verification");
    if (isDisputed) tags.push("disputed");
    if (urgency === "urgent") tags.push("urgent_safety");

    // Create chez_request
    const reqInsert: Record<string, unknown> = {
      household_id: householdId,
      property_id: propertyId,
      submitted_by_user_id: null, // handyman-generated, not homeowner-submitted
      category: routing.category,
      summary: compactString(rec.title),
      description: compactString(rec.description) || compactString(rec.homeowner_visible_notes),
      status: "open",
      sla_due_at: routing.bypassesSLA ? null : (
        routing.slaHours
          ? new Date(Date.now() + routing.slaHours * 3600_000).toISOString()
          : null
      ),
      admin_initiated: true,
      tags,
      source: "home_assessment",
    };
    const { data: chezReq } = await service
      .from("chez_requests")
      .insert(reqInsert)
      .select("id")
      .single();

    let projectId: string | null = null;

    // G36: high-cost → ALSO create property_projects
    if (estCost > HIGH_COST_THRESHOLD_CENTS) {
      const { data: proj } = await service
        .from("property_projects")
        .insert({
          household_id: householdId,
          property_id: propertyId,
          title: compactString(rec.title),
          description: compactString(rec.description) || null,
          status: "planning",
          entry_type: "planned",
          estimated_budget: estCost / 100,
        })
        .select("id")
        .single();
      if (proj) projectId = (proj as { id: string }).id;
    }

    // Backlink the recommendation row
    await service
      .from("assessment_recommended_tasks")
      .update({
        spawned_chez_request_id: chezReq ? (chezReq as { id: string }).id : null,
        spawned_project_id: projectId,
      })
      .eq("id", recId);
  }

  // ============================================================
  // 9. PRE-VISIT QUIZ ANSWERS + completedAt
  // ============================================================
  const captured_quiz_state = assessment.captured_quiz_state ?? {};
  const merged_quiz_state = {
    ...captured_quiz_state,
    completedAt: new Date().toISOString(),
  };
  const { data: prop } = await service
    .from("properties")
    .select("house_quiz_state, attributes")
    .eq("id", propertyId)
    .maybeSingle();
  const existingState = ((prop as { house_quiz_state: Record<string, unknown> | null } | null)?.house_quiz_state) ?? {};
  // Merge captured_attributes deep — preserve any existing keys not overridden
  const mergedAttributes = {
    ...((prop as { attributes: Record<string, unknown> | null } | null)?.attributes ?? {}),
    ...(assessment.captured_attributes ?? {}),
  };
  // Stamp assessment_mode so the homeowner-side knows ingestion happened
  mergedAttributes["assessment_mode"] = "handyman";
  await service
    .from("properties")
    .update({
      house_quiz_state: { ...existingState, ...merged_quiz_state },
      attributes: mergedAttributes,
    })
    .eq("id", propertyId);

  // ============================================================
  // 10. AUTO-FLIP chez_owned ON GROUP TOGGLES (Phase 84 inheritance)
  // ============================================================
  // If household has chez_ownership_groups.{systems|vendors|routines}.on=true,
  // every newly-created entity in that group gets chez_owned=true.
  const { data: hh } = await service
    .from("households")
    .select("chez_ownership_groups")
    .eq("id", householdId)
    .maybeSingle();
  const groups = (hh as { chez_ownership_groups: Record<string, unknown> | null } | null)?.chez_ownership_groups ?? {};
  const isOwned = (group: string) => {
    const g = groups[group] as { on?: boolean } | undefined;
    return g?.on === true;
  };
  if (isOwned("systems")) {
    await service.from("home_systems")
      .update({ chez_owned: true, chez_owned_at: isoNow() })
      .eq("property_id", propertyId)
      .eq("onboarded_via", "handyman_assessment")
      .is("chez_owned", null);
  }
  if (isOwned("vendors")) {
    await service.from("contractors")
      .update({ chez_owned: true, chez_owned_at: isoNow() })
      .eq("household_id", householdId)
      .eq("onboarded_via", "handyman_assessment")
      .is("chez_owned", null);
  }
  if (isOwned("routines")) {
    await service.from("routines")
      .update({ chez_owned: true, chez_owned_at: isoNow() })
      .eq("household_id", householdId)
      .eq("onboarded_via", "handyman_assessment")
      .is("chez_owned", null);
  }

  // ============================================================
  // 11. FINAL STATUS FLIP
  // ============================================================
  await service
    .from("home_assessments")
    .update({
      status: "awaiting_review",
      ingested_at: isoNow(),
    })
    .eq("id", assessmentId);

  // ============================================================
  // 12. CHEZ ACTIVITY LOG — Phase 85 PR 5c
  // ============================================================
  //
  // Surface the completed assessment in the homeowner's "This week
  // with Chez" digest + permanent activity history. Soft-fail: if
  // log_chez_activity isn't deployed yet (pre-20261213 envs) the
  // ingestion still succeeds.
  try {
    const systemCount = systems.length;
    const recommendationCount = recList.length;
    const quickFixCount = quickFixes.length;
    const titleParts: string[] = [];
    if (systemCount > 0) titleParts.push(`${systemCount} system${systemCount === 1 ? "" : "s"}`);
    if (recommendationCount > 0) titleParts.push(`${recommendationCount} follow-up${recommendationCount === 1 ? "" : "s"}`);
    if (quickFixCount > 0) titleParts.push(`${quickFixCount} quick fix${quickFixCount === 1 ? "" : "es"}`);
    const summary = titleParts.length > 0 ? titleParts.join(" · ") : "Visit complete";
    await service.rpc("log_chez_activity", {
      p_household_id: householdId,
      p_activity_type: "assessment_completed",
      p_title: "Home assessment complete",
      p_description: summary,
      p_entity_type: "home_assessment",
      p_entity_id: assessmentId,
      p_cost_cents: null,
      p_occurred_at: isoNow(),
      p_surface_on_dashboard: true,
    });

    // Per-system log entries — only when there's a notable count to
    // signal in the digest (skip noise on tiny visits)
    if (systemCount >= 3) {
      await service.rpc("log_chez_activity", {
        p_household_id: householdId,
        p_activity_type: "system_added",
        p_title: `${systemCount} systems documented`,
        p_description: null,
        p_entity_type: "home_assessment",
        p_entity_id: assessmentId,
        p_cost_cents: null,
        p_occurred_at: isoNow(),
        p_surface_on_dashboard: false,
      });
    }
    if (recommendationCount > 0) {
      await service.rpc("log_chez_activity", {
        p_household_id: householdId,
        p_activity_type: "recommendation_logged",
        p_title: `${recommendationCount} recommendation${recommendationCount === 1 ? "" : "s"} logged`,
        p_description: null,
        p_entity_type: "home_assessment",
        p_entity_id: assessmentId,
        p_cost_cents: null,
        p_occurred_at: isoNow(),
        p_surface_on_dashboard: false,
      });
    }
  } catch (err) {
    console.warn("[handyman-provider] log_chez_activity failed (non-fatal):", err);
  }
}

// ============================================================================
// Phase 84.5 round 2 — additional helper actions (G18-G50)
// ============================================================================

/** Homeowner-side: create or fetch the assessment row at signup. */
async function requestHomeAssessment(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const propertyId = compactString(body.property_id);
  const householdId = compactString(body.household_id);
  if (!propertyId || !householdId) throw new Error("property_id + household_id required");

  // Idempotent — reuse an active assessment if one exists.
  const { data: existing } = await service
    .from("home_assessments")
    .select("*")
    .eq("property_id", propertyId)
    .not("status", "in", "(completed,cancelled)")
    .maybeSingle();
  if (existing) {
    return { ok: true, assessment: existing, was_existing: true };
  }

  // Phase 95 / gap #4: optional preferred-window fields. Picker on the
  // iOS booking sheet lets the homeowner say "any time after May 12,
  // mornings preferred." Cockpit uses these when assigning a handyman
  // so the visit lands inside the window instead of being silently
  // scheduled by the dispatcher.
  const preferredWindowStart = compactString(body.preferred_window_start);
  const preferredTimeOfDay = compactString(body.preferred_time_of_day);

  const { data: created, error } = await service
    .from("home_assessments")
    .insert({
      property_id: propertyId,
      household_id: householdId,
      status: "pending",
      homeowner_concerns: compactString(body.homeowner_concerns) || null,
      homeowner_present: body.homeowner_present !== false,
      homeowner_access_notes: compactString(body.homeowner_access_notes) || null,
      is_existing_user_supplement: body.is_existing_user_supplement === true,
      preferred_window_start: preferredWindowStart || null,
      preferred_time_of_day: preferredTimeOfDay || null,
    })
    .select("*")
    .single();
  if (error || !created) throw new Error(`failed to create assessment: ${error?.message}`);

  // Phase 95 / gap #5: confirmation email via SendGrid so the homeowner
  // has something in writing the moment the request lands. Push fires
  // separately from iOS via UNUserNotification — handled client-side
  // because that's a local notification, not a remote one.
  try {
    await sendAssessmentRequestConfirmationEmail(service, householdId, {
      preferredWindowStart,
      preferredTimeOfDay,
    });
  } catch (e) {
    console.error("[chez-assessment-confirmation] email failed:", e);
    // never break the request flow on email failure
  }

  return { ok: true, assessment: created, was_existing: false };
}

/** Phase 95 / gap #5 — email backstop the moment a homeowner books a
 *  Chez handyman onboarding visit. Brand-voiced as Chez (per the
 *  audit's #74 brand sweep). Sends to every household admin's email. */
async function sendAssessmentRequestConfirmationEmail(
  service: ServiceClient,
  householdId: string,
  details: { preferredWindowStart?: string; preferredTimeOfDay?: string }
): Promise<void> {
  const sendgridKey = Deno.env.get("SENDGRID_API_KEY");
  if (!sendgridKey) return;

  const { data: members } = await service
    .from("household_members")
    .select("user_id, role")
    .eq("household_id", householdId)
    .in("role", ["owner", "admin"]);
  const memberIds = ((members as Array<{ user_id: string }> | null) ?? [])
    .map((m) => m.user_id)
    .filter(Boolean);
  if (memberIds.length === 0) return;

  const { data: users } = await service
    .from("users")
    .select("email, full_name")
    .in("id", memberIds);
  const recipients = ((users as Array<{ email: string; full_name?: string }> | null) ?? [])
    .filter((u) => !!u.email);
  if (recipients.length === 0) return;

  const windowSummary = (() => {
    if (!details.preferredWindowStart && !details.preferredTimeOfDay) {
      return "We'll be in touch shortly with a date and time that works for you.";
    }
    const parts: string[] = [];
    if (details.preferredWindowStart) {
      parts.push(`earliest date you're available: ${details.preferredWindowStart}`);
    }
    if (details.preferredTimeOfDay) {
      parts.push(`time of day preference: ${details.preferredTimeOfDay}`);
    }
    return `We've noted your preferences (${parts.join(", ")}) and will reach out to confirm a slot.`;
  })();

  const subject = "Your Chez handyman onboarding visit is being scheduled";
  const text = `Hi,

Your request for a Chez handyman onboarding visit has been received.

${windowSummary}

A member of the Chez team will reach out within one business day to confirm the date and time.

Thanks for trusting us with your home,
The Chez team`;

  const html = `<p>Hi,</p>
<p>Your request for a Chez handyman onboarding visit has been received.</p>
<p>${windowSummary}</p>
<p>A member of the Chez team will reach out within one business day to confirm the date and time.</p>
<p>Thanks for trusting us with your home,<br/>The Chez team</p>`;

  await fetch("https://api.sendgrid.com/v3/mail/send", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${sendgridKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      personalizations: recipients.map((r) => ({
        to: [{ email: r.email, name: r.full_name ?? undefined }],
      })),
      from: { email: "hello@getchez.com", name: "Chez" },
      subject,
      content: [
        { type: "text/plain", value: text },
        { type: "text/html", value: html },
      ],
    }),
  });
}

/** Handyman captures a recommendation during the visit. (G18, G19, G20, G45) */
async function addRecommendedTask(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const assessmentId = compactString(body.assessment_id);
  if (!assessmentId) throw new Error("assessment_id required");
  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");
  const auth = await assertHandymanCanWrite(service, user, assessment);
  if (!auth.ok) throw new Error(auth.reason ?? "not authorized");

  const urgency = compactString(body.urgency) || "soon";
  const observationSource = compactString(body.observation_source) || "handyman_observed";
  const needsVerification = body.needs_verification === true
    || observationSource === "homeowner_reported";

  const { data: created, error } = await service
    .from("assessment_recommended_tasks")
    .insert({
      assessment_id: assessmentId,
      system_id: compactString(body.system_id) || null,
      zone: compactString(body.zone) || null,
      title: compactString(body.title),
      description: compactString(body.description) || null,
      category: compactString(body.category) || null,
      urgency,
      recommended_owner: compactString(body.recommended_owner) || "chez_vendor",
      recommended_template_key: compactString(body.recommended_template_key) || null,
      observation_source: observationSource,
      needs_verification: needsVerification,
      estimated_cost_cents: typeof body.estimated_cost_cents === "number"
        ? body.estimated_cost_cents : null,
      handyman_notes: compactString(body.handyman_notes) || null,
      homeowner_visible_notes: compactString(body.homeowner_visible_notes) || null,
      photos: Array.isArray(body.photos) ? body.photos : [],
    })
    .select("*")
    .single();
  if (error || !created) throw new Error(`failed: ${error?.message}`);

  // G20: urgent finding — fire admin push immediately
  if (urgency === "urgent") {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const adminEmails = (Deno.env.get("CHEZ_ADMIN_EMAILS") ?? "").split(",").filter(Boolean);
    if (adminEmails.length > 0) {
      const { data: admins } = await service
        .from("users")
        .select("id")
        .in("email", adminEmails);
      const adminIds = ((admins as Array<{ id: string }> | null) ?? []).map((u) => u.id);
      if (adminIds.length > 0) {
        await sendAssessmentPush(
          supabaseUrl, serviceRoleKey, adminIds,
          "🚨 Urgent finding during assessment",
          compactString(body.title),
          { type: "chez_assessment_urgent_finding", assessment_id: assessmentId, recommendation_id: (created as { id: string }).id }
        );
      }
    }
  }

  return { ok: true, recommended_task: created };
}

/** T5.6 (post-overnight) — admin gate action. Tom flags a submitted
 * assessment as needing revision before it ships verbatim to the
 * homeowner. Sets home_assessments.status='needs_revision' + stamps
 * admin_notes (the reason). Fires push to the original handyman
 * member so they see the flag in the field app.
 *
 * Auth: caller must be in CHEZ_ADMIN_EMAILS. We DON'T do
 * assertWorkspaceAccess here since admins reach across workspaces.
 *
 * Closes Wave 6 finding 16.5.
 */
async function flagAssessmentForRevision(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>,
) {
  const assessmentId = compactString(body.assessment_id);
  const reason = compactString(body.reason);
  if (!assessmentId) throw new Error("assessment_id required");
  if (!reason) throw new Error("reason required (what does the handyman need to fix?)");

  // Admin auth — caller's email must be on the allowlist.
  const adminEmails = (Deno.env.get("CHEZ_ADMIN_EMAILS") ?? "").split(",").filter(Boolean);
  if (adminEmails.length === 0) {
    throw new Error("CHEZ_ADMIN_EMAILS not configured");
  }
  const { data: callerRow } = await service
    .from("users").select("email").eq("id", user.id).maybeSingle();
  const callerEmail = (compactString(callerRow?.email) || "").toLowerCase();
  if (!adminEmails.map((e) => e.toLowerCase()).includes(callerEmail)) {
    throw new Error("Admin only");
  }

  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");

  // Walk the row to needs_revision status with the reason in admin_notes.
  // Existing admin_notes are appended-to so multiple revision rounds
  // build a clean audit trail.
  const existingNotes = compactString((assessment as Record<string, unknown>).admin_notes) || "";
  const stamped = `[${isoNow()}] Revision requested: ${reason}`;
  const combinedNotes = existingNotes
    ? `${existingNotes}\n\n${stamped}`
    : stamped;

  const { data: updated, error: updateError } = await service
    .from("home_assessments")
    .update({
      status: "needs_revision",
      admin_notes: combinedNotes,
      updated_at: isoNow(),
    })
    .eq("id", assessmentId)
    .select("*")
    .single();
  if (updateError) throw updateError;

  // Fire push to the original handyman member so they see the flag
  // in the field app.
  const handymanMemberId = compactString((assessment as Record<string, unknown>).handyman_member_id);
  if (handymanMemberId) {
    const { data: memberRow } = await service
      .from("provider_workspace_members")
      .select("user_id")
      .eq("id", handymanMemberId)
      .maybeSingle();
    const handymanUserId = compactString(memberRow?.user_id);
    if (handymanUserId) {
      const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
      const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
      await sendAssessmentPush(
        supabaseUrl, serviceRoleKey, [handymanUserId],
        "Assessment flagged for revision",
        reason,
        {
          type: "chez_assessment_corrections_received",
          assessment_id: assessmentId,
        },
      );
    }
  }

  return { ok: true, assessment: updated };
}

/** T5.6 (post-overnight) — admin gate action. Tom approves or
 * rejects a handyman's vendor recommendation BEFORE it reaches the
 * homeowner. Updates assessment_recommended_tasks.recommended_owner
 * (admin_approved → routed; admin_rejected → not routed) plus
 * stamps approval_decided_at + approval_decided_by.
 *
 * Auth: caller must be in CHEZ_ADMIN_EMAILS.
 *
 * Closes Wave 6 finding 16.6.
 */
async function decideHandymanRecommendation(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>,
) {
  const taskId = compactString(body.task_id);
  const decision = compactString(body.decision); // 'approve' | 'reject'
  const reason = compactString(body.reason);
  if (!taskId) throw new Error("task_id required");
  if (!["approve", "reject"].includes(decision)) {
    throw new Error("decision must be approve or reject");
  }

  // Admin auth (same pattern as flagAssessmentForRevision).
  const adminEmails = (Deno.env.get("CHEZ_ADMIN_EMAILS") ?? "").split(",").filter(Boolean);
  if (adminEmails.length === 0) {
    throw new Error("CHEZ_ADMIN_EMAILS not configured");
  }
  const { data: callerRow } = await service
    .from("users").select("email").eq("id", user.id).maybeSingle();
  const callerEmail = (compactString(callerRow?.email) || "").toLowerCase();
  if (!adminEmails.map((e) => e.toLowerCase()).includes(callerEmail)) {
    throw new Error("Admin only");
  }

  // Build update — append the decision to handyman_notes audit trail.
  const { data: existing } = await service
    .from("assessment_recommended_tasks")
    .select("handyman_notes, recommended_owner")
    .eq("id", taskId)
    .maybeSingle();
  const existingNotes = compactString(existing?.handyman_notes) || "";
  const stamped = `[${isoNow()}] Admin ${decision}: ${reason || "no reason given"}`;
  const combinedNotes = existingNotes
    ? `${existingNotes}\n${stamped}`
    : stamped;

  const newOwner = decision === "approve"
    ? "chez_vendor"  // routed normally
    : "rejected_by_admin";

  const { data: updated, error: updateError } = await service
    .from("assessment_recommended_tasks")
    .update({
      recommended_owner: newOwner,
      handyman_notes: combinedNotes,
    })
    .eq("id", taskId)
    .select("*")
    .single();
  if (updateError) throw updateError;
  return { ok: true, recommended_task: updated };
}

/** Wrap-up: homeowner_response / disputed / homeowner_handled. (G46, G48) */
async function updateRecommendedTask(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const taskId = compactString(body.task_id);
  if (!taskId) throw new Error("task_id required");

  const update: Record<string, unknown> = {};
  const allowed = [
    "homeowner_response", "homeowner_handled_scheduled_for", "homeowner_handled_vendor",
    "disputed", "title", "description", "urgency", "estimated_cost_cents",
    "handyman_notes", "homeowner_visible_notes", "needs_verification",
    "recommended_owner",
  ];
  for (const k of allowed) {
    if (body[k] !== undefined) update[k] = body[k];
  }
  if (Object.keys(update).length === 0) return { ok: true, no_changes: true };

  const { data: updated, error } = await service
    .from("assessment_recommended_tasks")
    .update(update)
    .eq("id", taskId)
    .select("*")
    .single();
  if (error) throw new Error(`failed: ${error.message}`);
  return { ok: true, recommended_task: updated };
}

/** G21 — handyman quick-fix during the visit. */
async function markTaskFixedDuringVisit(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const taskId = compactString(body.task_id);
  const costCents = typeof body.cost_cents === "number" ? body.cost_cents : 0;
  if (!taskId) throw new Error("task_id required");

  const { data: rec } = await service
    .from("assessment_recommended_tasks")
    .select("*, home_assessments!inner(household_id, property_id)")
    .eq("id", taskId)
    .maybeSingle();
  if (!rec) throw new Error("recommended task not found");
  const r = rec as Record<string, unknown> & { home_assessments: { household_id: string; property_id: string } };

  // Create backdated service_record
  const { data: sr } = await service
    .from("service_records")
    .insert({
      household_id: r.home_assessments.household_id,
      property_id: r.home_assessments.property_id,
      system_id: compactString(r.system_id) || null,
      service_date: new Date().toISOString().slice(0, 10),
      description: `Fixed during Chez assessment: ${compactString(r.title)}`,
      cost_cents: costCents,
      notes: compactString(r.handyman_notes) || null,
    })
    .select("id")
    .single();

  await service
    .from("assessment_recommended_tasks")
    .update({
      fixed_during_visit: true,
      spawned_service_record_id: sr ? (sr as { id: string }).id : null,
    })
    .eq("id", taskId);

  return { ok: true, service_record_id: sr ? (sr as { id: string }).id : null };
}

/**
 * G44 (legacy) + Wave M3 — mark a system inactive without archiving.
 * M3 added workspace-member auth + a verification round-trip through
 * loadSystemForProviderWrite() so a tech can't decommission a system in
 * a household their workspace doesn't serve. Accepts both the legacy
 * `system_id` arg name and the M3+ `systemId` shape.
 */
async function decommissionSystem(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  if (workspaceId) {
    await assertWorkspaceAccess(service, userId, workspaceId);
  }

  const systemId = compactString(body.systemId) || compactString(body.system_id);
  const reason = compactString(body.reason) || null;
  if (!systemId) throw new Error("systemId required");

  if (workspaceId) {
    await loadSystemForProviderWrite(service, workspaceId, systemId);
  }

  const { data: updated, error: updateError } = await service
    .from("home_systems")
    .update({
      is_active: false,
      decommissioned_at: isoNow(),
      decommissioned_reason: reason,
      status: "decommissioned",
    })
    .eq("id", systemId)
    .select()
    .single();
  if (updateError) throw updateError;

  return { ok: true, system: updated };
}

/**
 * Wave M3 — mark a system for follow-up on the next visit. Tech couldn't
 * access this system this visit (tenant out, attic locked, breaker
 * panel buried). Surfaces on the next visit's prep checklist + on the
 * homeowner's dashboard if material. Workspace-member auth required.
 */
async function markSystemFollowupForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const systemId = compactString(body.systemId);
  if (!systemId) throw new Error("systemId is required");
  const reason = compactString(body.reason) || null;

  await loadSystemForProviderWrite(service, workspaceId, systemId);

  const { data: updated, error: updateError } = await service
    .from("home_systems")
    .update({
      marked_for_followup_at: isoNow(),
      followup_reason: reason,
    })
    .eq("id", systemId)
    .select()
    .single();
  if (updateError) throw updateError;

  return { ok: true, system: updated };
}

/**
 * Wave M3 — clear the follow-up flag on a system. Used when the tech
 * returns and finishes the work, or marks "Got it" to explicitly drop
 * it off the next-visit prep list. Workspace-member auth required.
 */
async function clearSystemFollowupForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const systemId = compactString(body.systemId);
  if (!systemId) throw new Error("systemId is required");

  await loadSystemForProviderWrite(service, workspaceId, systemId);

  const { data: updated, error: updateError } = await service
    .from("home_systems")
    .update({
      marked_for_followup_at: null,
      followup_reason: null,
    })
    .eq("id", systemId)
    .select()
    .single();
  if (updateError) throw updateError;

  return { ok: true, system: updated };
}

/**
 * Wave M3 — record a voice memo against a system. Bytes land in the
 * home-system-attachments bucket as
 * `<household_id>/<system_id>/voice-<stamp>.m4a`, and the canonical
 * column home_systems.voice_note_path stores the path. The read path
 * signs short-lived URLs through the same bucket. Setting a fresh memo
 * overwrites the previous one — single-shot per system in v1.
 */
async function attachSystemVoiceForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const systemId = compactString(body.systemId);
  if (!systemId) throw new Error("systemId is required");
  const fileBase64 = compactString(body.base64) || compactString(body.fileBase64);
  if (!fileBase64) throw new Error("base64 is required");
  const mimeType = compactString(body.mimeType) || "audio/mp4";

  const system = await loadSystemForProviderWrite(service, workspaceId, systemId);
  const householdId = compactString(system.household_id);
  if (!householdId) throw new Error("System has no household");

  const stamp = `${Date.now()}`;
  const ext = mimeType.includes("mp4") || mimeType.includes("m4a")
    ? "m4a"
    : mimeType.includes("wav")
      ? "wav"
      : "audio";
  const path = `${householdId}/${systemId}/voice-${stamp}.${ext}`;

  const bytes = decodeBase64Body(fileBase64);
  const { error: uploadError } = await service.storage
    .from("home-system-attachments")
    .upload(path, bytes, { contentType: mimeType, upsert: false });
  if (uploadError) throw new Error(`Upload failed: ${uploadError.message}`);

  const { error: updateError } = await service
    .from("home_systems")
    .update({ voice_note_path: path })
    .eq("id", systemId);
  if (updateError) throw updateError;

  let signedUrl: string | null = null;
  try {
    const { data: signed } = await service.storage
      .from("home-system-attachments")
      .createSignedUrl(path, 60 * 60);
    signedUrl = signed?.signedUrl ?? null;
  } catch (err) {
    console.warn("[handyman-provider] failed to sign system voice url", err);
  }

  return { ok: true, voicePath: path, signedUrl, mimeType };
}

/**
 * Wave M3 — delete a recorded voice memo for a system. Best-effort
 * storage cleanup + null out the column so the iOS UI hides the row.
 */
async function deleteSystemVoiceForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const systemId = compactString(body.systemId);
  if (!systemId) throw new Error("systemId is required");

  const system = await loadSystemForProviderWrite(service, workspaceId, systemId);
  const existingPath = compactString((system as Record<string, unknown>).voice_note_path);

  if (existingPath) {
    await service.storage
      .from("home-system-attachments")
      .remove([existingPath])
      .catch((err: unknown) => {
        console.warn("[handyman-provider] failed to remove system voice", existingPath, err);
      });
  }

  const { error: updateError } = await service
    .from("home_systems")
    .update({ voice_note_path: null })
    .eq("id", systemId);
  if (updateError) throw updateError;

  return { ok: true };
}

/**
 * Wave M3 — create a new home_systems row for a property the workspace
 * serves. Mirrors the workspace-auth pattern of updateHomeSystemForProvider
 * (load-system / contractor-link / linked-request gate) but for INSERT
 * instead of UPDATE. Bypasses the homeowner-only RLS policy on
 * home_systems INSERT by writing through the service role.
 */
async function createHomeSystemForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const propertyId = compactString(body.propertyId);
  const householdId = compactString(body.householdId);
  if (!propertyId) throw new Error("propertyId is required");
  if (!householdId) throw new Error("householdId is required");
  const name = compactString(body.name);
  if (!name) throw new Error("name is required");

  // Verify the workspace serves this property via at least one
  // handyman_request through one of its linked contractors. Mirrors
  // loadSystemForProviderWrite() but for create-time when no system_id
  // exists yet.
  const { data: links } = await service
    .from("provider_contractor_links")
    .select("contractor_id")
    .eq("workspace_id", workspaceId);
  const contractorIds = (links ?? [])
    .map((row: Record<string, unknown>) => compactString(row.contractor_id))
    .filter(Boolean);
  if (contractorIds.length === 0) throw new Error("Workspace has no linked contractors");

  const { data: linkedRequest } = await service
    .from("handyman_requests")
    .select("id")
    .eq("property_id", propertyId)
    .in("contractor_id", contractorIds)
    .limit(1)
    .maybeSingle();
  if (!linkedRequest) throw new Error("This home isn't on your books");

  const insert: Record<string, unknown> = {
    property_id: propertyId,
    household_id: householdId,
    name,
    onboarded_via: compactString(body.onboardedVia) || "field_visit",
  };
  if (typeof body.category === "string") insert.category = compactString(body.category);
  if (typeof body.manufacturer === "string") insert.manufacturer = compactString(body.manufacturer);
  if (typeof body.modelNumber === "string") insert.model_number = compactString(body.modelNumber);
  if (typeof body.serialNumber === "string") insert.serial_number = compactString(body.serialNumber);
  if (typeof body.installDate === "string") insert.install_date = compactString(body.installDate);
  if (typeof body.notes === "string") insert.notes = compactString(body.notes);
  if (typeof body.subtype === "string") insert.subtype = compactString(body.subtype);

  const { data: created, error: createError } = await service
    .from("home_systems")
    .insert(insert)
    .select()
    .single();
  if (createError) throw createError;

  return { ok: true, system: created };
}

/**
 * Wave M3 — wrapper around the existing identify-equipment edge
 * function. The field iOS app posts a base64 JPEG of a model plate +
 * optional category; we forward it server-side so the workspace-auth
 * boundary stays inside handyman-provider and the operator never has to
 * juggle a second function URL. Returns the structured AI extraction
 * for the iOS confirmation card to render.
 */
async function extractSystemFromPhotoForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const userId = compactString(user.id);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const fileBase64 = compactString(body.base64) || compactString(body.fileBase64);
  if (!fileBase64) throw new Error("base64 is required");
  const category = compactString(body.category) || null;

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const url = `${supabaseUrl}/functions/v1/identify-equipment`;
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${serviceKey}`,
      "apikey": serviceKey,
    },
    body: JSON.stringify({ image_base64: fileBase64, category }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`identify-equipment failed: ${response.status} ${errText.slice(0, 300)}`);
  }

  const result = await response.json();
  return {
    ok: true,
    identified: result.identified === true,
    manufacturer: result.manufacturer ?? null,
    modelNumber: result.model_number ?? null,
    serialNumber: result.serial_number ?? null,
    productType: result.product_type ?? null,
    additionalSpecs: result.additional_specs ?? null,
    confidence: result.confidence ?? null,
    rawText: result.raw_text ?? null,
    catalogMatch: result.catalog_match ?? null,
  };
}

/**
 * Wave M10 — Haversine distance between two lat/lng points in meters.
 * Pure function so we can sort the customer list deterministically.
 */
function haversineMeters(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6371000; // Earth radius in meters
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Wave M10 — geocode a free-form address string via Nominatim
 * (OpenStreetMap). 1-second-per-request rate limit per their TOS, so
 * the caller MUST throttle when looping. 2-second timeout per call.
 * Returns null on any failure (rate-limit, no match, timeout) so the
 * caller can degrade gracefully rather than fail the whole request.
 *
 * Per Nominatim TOS we MUST set a unique User-Agent. We use the Chez
 * Field iOS app identifier so abuse complaints route to a real address.
 */
async function geocodeAddress(address: string): Promise<{ lat: number; lng: number } | null> {
  const trimmed = address.trim();
  if (!trimmed) return null;

  try {
    const url = new URL("https://nominatim.openstreetmap.org/search");
    url.searchParams.set("q", trimmed);
    url.searchParams.set("format", "json");
    url.searchParams.set("limit", "1");
    url.searchParams.set("addressdetails", "0");

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 2000);
    const response = await fetch(url.toString(), {
      headers: {
        "User-Agent": "ChezField/1.0 (https://getchez.com; tom@getchez.com)",
        "Accept": "application/json",
      },
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!response.ok) return null;
    const results = await response.json() as Array<{ lat?: string; lon?: string }>;
    if (!Array.isArray(results) || results.length === 0) return null;
    const first = results[0];
    const lat = parseFloat(first.lat ?? "");
    const lng = parseFloat(first.lon ?? "");
    if (Number.isNaN(lat) || Number.isNaN(lng)) return null;
    return { lat, lng };
  } catch (err) {
    console.warn("[handyman-provider] geocode failed for", trimmed.slice(0, 60), err);
    return null;
  }
}

/**
 * Wave M10 — "Closest customer to me." Returns the workspace's
 * customers sorted by Haversine distance from the tech's current
 * location. Properties don't carry lat/lng columns yet, so we
 * geocode `street, city, state, zip` via Nominatim with one second
 * between requests (their TOS) — capped at `limit + 5` candidates so
 * we don't slam their service on big workspaces.
 *
 * Customers without a usable address (or that fail to geocode) are
 * dropped from the result silently. The iOS UI surfaces "no
 * customers with mappable addresses" via the empty state when the
 * array is empty, distinct from the geolocation-denied empty state.
 */
async function nearestCustomersForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const userId = compactString(user.id);
  let workspaceId = compactString(body.workspaceId);
  if (!workspaceId) {
    const m = await getWorkspaceMembership(service, userId);
    if (!m) throw new Error("No provider workspace found");
    const ws = (m as Record<string, unknown>).provider_workspaces as Record<string, unknown> | undefined;
    workspaceId = compactString(ws?.id);
    if (!workspaceId) throw new Error("Workspace id missing on membership row.");
  } else {
    await assertWorkspaceAccess(service, userId, workspaceId);
  }

  const lat = numberValue(body.latitude);
  const lng = numberValue(body.longitude);
  if (Number.isNaN(lat) || Number.isNaN(lng) || lat === 0 || lng === 0) {
    throw new Error("latitude and longitude are required");
  }

  const limitRaw = numberValue(body.limit ?? 10);
  const limit = Math.max(1, Math.min(20, Math.floor(limitRaw)));

  // 1. Pull contractor links → contractors → households for this
  //    workspace. Households can have multiple contractor rows
  //    (legacy + chez_field-sourced) so we de-dup by household.
  const { data: links, error: linksError } = await service
    .from("provider_contractor_links")
    .select("contractor_id, contractors(id, household_id, company_name, contact_name)")
    .eq("workspace_id", workspaceId);
  if (linksError) throw linksError;

  const householdIds = new Set<string>();
  const householdMeta = new Map<string, { contactName: string; companyName: string }>();
  for (const link of (links ?? []) as Array<Record<string, unknown>>) {
    const c = link.contractors as Record<string, unknown> | null;
    if (!c) continue;
    const householdId = compactString(c.household_id);
    if (!householdId || householdIds.has(householdId)) continue;
    householdIds.add(householdId);
    householdMeta.set(householdId, {
      contactName: compactString(c.contact_name) || "",
      companyName: compactString(c.company_name) || "",
    });
  }

  if (householdIds.size === 0) {
    return { ok: true, customers: [], note: "Workspace has no linked customers." };
  }

  // 2. Pull one property per household. Sort by created_at so the
  //    "first property" is the canonical pin for that customer.
  const { data: properties, error: propsError } = await service
    .from("properties")
    .select("id, household_id, name, street, city, state, zip_code, created_at")
    .in("household_id", Array.from(householdIds))
    .order("created_at", { ascending: true });
  if (propsError) throw propsError;

  const byHousehold = new Map<string, Record<string, unknown>>();
  for (const p of (properties ?? []) as Array<Record<string, unknown>>) {
    const hid = compactString(p.household_id);
    if (!hid) continue;
    if (!byHousehold.has(hid)) byHousehold.set(hid, p);
  }

  // 3. Build the candidate list. We cap to `limit + 5` candidates
  //    we actually attempt to geocode — Nominatim's 1/sec rate limit
  //    means a 100-customer workspace would take 100s otherwise. v1
  //    accepts this ceiling; future work: persist lat/lng on
  //    properties at create time so we skip the geocoding step.
  const candidates: Array<{
    householdId: string;
    propertyId: string;
    customerName: string;
    address: string;
    fallbackAddress: string;
  }> = [];
  for (const [hid, prop] of byHousehold) {
    const street = compactString(prop.street);
    const city = compactString(prop.city);
    const stateCode = compactString(prop.state);
    const zip = compactString(prop.zip_code);
    const address = [street, city, stateCode, zip].filter(Boolean).join(", ");
    // Fallback used when the full street address doesn't geocode
    // (synthetic / misspelled / unrecognized streets). City + state
    // gets us a town-center pin which is good enough to show "this
    // customer is in Ridgefield, ~3 miles away."
    const fallbackAddress = [city, stateCode].filter(Boolean).join(", ");
    if (!address && !fallbackAddress) continue;
    const meta = householdMeta.get(hid);
    const customerName = meta?.contactName || compactString(prop.name) || meta?.companyName || "Customer";
    candidates.push({
      householdId: hid,
      propertyId: compactString(prop.id),
      customerName,
      address: address || fallbackAddress,
      fallbackAddress,
    });
  }

  if (candidates.length === 0) {
    return { ok: true, customers: [], note: "No customers have an address on file yet." };
  }

  const geocodeCap = Math.min(candidates.length, limit + 5);
  type Resolved = {
    householdId: string;
    propertyId: string;
    customerName: string;
    address: string;
    latitude: number;
    longitude: number;
    distanceMeters: number;
  };
  const resolved: Resolved[] = [];

  for (let i = 0; i < geocodeCap; i++) {
    const candidate = candidates[i];
    let coords = await geocodeAddress(candidate.address);
    // If the full street address didn't match, try city+state. We
    // only do the fallback when the addresses differ so we don't
    // double-spend the rate limit on rows where the full address
    // already collapses to a town-center pin.
    if (!coords && candidate.fallbackAddress && candidate.fallbackAddress !== candidate.address) {
      await new Promise(resolve => setTimeout(resolve, 1100));
      coords = await geocodeAddress(candidate.fallbackAddress);
    }
    if (coords) {
      resolved.push({
        householdId: candidate.householdId,
        propertyId: candidate.propertyId,
        customerName: candidate.customerName,
        address: candidate.address,
        latitude: coords.lat,
        longitude: coords.lng,
        distanceMeters: Math.round(haversineMeters(lat, lng, coords.lat, coords.lng)),
      });
    }
    // Nominatim TOS: max 1 request per second. Skip the wait on the
    // last iteration so we don't pad the response.
    if (i < geocodeCap - 1) {
      await new Promise(resolve => setTimeout(resolve, 1100));
    }
  }

  resolved.sort((a, b) => a.distanceMeters - b.distanceMeters);
  return {
    ok: true,
    customers: resolved.slice(0, limit),
    geocodedCount: resolved.length,
    candidateCount: candidates.length,
  };
}

/**
 * Wave M10 — extract structured business-card data via Claude Vision.
 * Mirrors `extractSystemFromPhotoForProvider`'s shape but routes to
 * Claude directly with a card-specific prompt rather than going
 * through identify-equipment (which would try to match the result
 * against the equipment catalog).
 *
 * The iOS UI presents the result as an editable confirmation card; we
 * never auto-save. All fields are nullable because business cards
 * vary wildly in completeness.
 */
async function extractBusinessCardForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const userId = compactString(user.id);
  const workspaceId = compactString(body.workspaceId);
  if (workspaceId) {
    await assertWorkspaceAccess(service, userId, workspaceId);
  } else {
    const m = await getWorkspaceMembership(service, userId);
    if (!m) throw new Error("No provider workspace found");
  }

  const fileBase64 = compactString(body.imageBase64) || compactString(body.base64);
  if (!fileBase64) throw new Error("imageBase64 is required");

  const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!anthropicApiKey) {
    throw new Error("ANTHROPIC_API_KEY is not configured");
  }

  const prompt = `You are reading a business card to capture a vendor's contact info.

Extract these fields from the card image:
- companyName: the business / brand name (e.g., "Smith Plumbing & Heating")
- contactName: the person's name (e.g., "John Smith")
- phone: primary phone number (any format)
- email: email address
- website: website URL or domain
- tradeCategory: best-fit trade label from this list, or null if unclear:
  Plumbing, HVAC, Electrical, Roofing, Landscaping, Pest Control,
  Pool Service, Septic, Well, Chimney, Tree Service, Handyman,
  Cleaning, Painting, Carpentry, General Contractor, Other

If a field isn't on the card or you can't read it confidently, use null.

Respond with ONLY valid JSON in this exact shape, no prose:
{
  "companyName": "..." or null,
  "contactName": "..." or null,
  "phone": "..." or null,
  "email": "..." or null,
  "website": "..." or null,
  "tradeCategory": "..." or null,
  "confidence": "high" or "medium" or "low",
  "rawText": "all readable text from the card"
}`;

  const visionResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": anthropicApiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: "image/jpeg",
                data: fileBase64,
              },
            },
            { type: "text", text: prompt },
          ],
        },
      ],
    }),
  });

  if (!visionResponse.ok) {
    const errText = await visionResponse.text();
    throw new Error(`Claude Vision failed: ${visionResponse.status} ${errText.slice(0, 300)}`);
  }

  const visionData = await visionResponse.json();
  const visionText: string = visionData.content?.[0]?.text ?? "";

  let extracted: Record<string, unknown>;
  try {
    const jsonMatch = visionText.match(/\{[\s\S]*\}/);
    extracted = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(visionText);
  } catch {
    return {
      ok: true,
      companyName: null,
      contactName: null,
      phone: null,
      email: null,
      website: null,
      tradeCategory: null,
      confidence: "low",
      rawText: visionText.slice(0, 500),
      parseError: "Could not parse the card. Re-shoot or fill it in by hand.",
    };
  }

  return {
    ok: true,
    companyName: compactString(extracted.companyName) || null,
    contactName: compactString(extracted.contactName) || null,
    phone: compactString(extracted.phone) || null,
    email: compactString(extracted.email) || null,
    website: compactString(extracted.website) || null,
    tradeCategory: compactString(extracted.tradeCategory) || null,
    confidence: compactString(extracted.confidence) || "medium",
    rawText: compactString(extracted.rawText) || null,
  };
}

/**
 * Wave M10 — insert a `contractors` row from a business-card capture.
 * Mirrors the M3 `create_home_system` pattern: workspace members
 * can't directly INSERT into `contractors` because the table is
 * household-scoped via RLS. This wrapper validates the caller belongs
 * to the workspace, validates the workspace serves the target
 * household (via `provider_contractor_links`), then inserts via the
 * service-role client.
 *
 * Source is stamped `chez_field` per the Phase 19k+ source
 * discriminator. `specialties` is set to a single-element array
 * containing the trade category so the homeowner-side coverage logic
 * can match the new vendor against open systems.
 */
async function createContractorFromCardForProvider(
  service: ServiceClient,
  user: Record<string, unknown>,
  body: Record<string, unknown>,
) {
  const userId = compactString(user.id);
  const workspaceId = compactString(body.workspaceId);
  await assertWorkspaceAccess(service, userId, workspaceId);

  const householdId = compactString(body.householdId);
  const companyName = compactString(body.companyName);
  const phone = compactString(body.phone);
  if (!householdId) throw new Error("householdId is required");
  if (!companyName) throw new Error("Company name is required");
  if (!phone) throw new Error("Phone is required");

  // Confirm the workspace actually serves this household via the
  // contractor-links table (same access guard pattern as
  // create_home_system).
  const { data: linkRows } = await service
    .from("provider_contractor_links")
    .select("contractor_id, contractors!inner(household_id)")
    .eq("workspace_id", workspaceId);
  const servesHousehold = (linkRows ?? []).some((row: Record<string, unknown>) => {
    const c = row.contractors as Record<string, unknown> | null;
    return compactString(c?.household_id) === householdId;
  });
  if (!servesHousehold) {
    throw new Error("Workspace does not serve this household");
  }

  const contactName = compactString(body.contactName);
  const email = normalizedEmail(body.email);
  const website = compactString(body.website);
  const tradeCategory = compactString(body.tradeCategory);
  const notes = compactString(body.notes);
  const specialties = tradeCategory ? [tradeCategory] : null;

  const { data: created, error: insertError } = await service
    .from("contractors")
    .insert({
      household_id: householdId,
      company_name: companyName,
      contact_name: contactName || null,
      phone,
      email: email || null,
      website: website || null,
      specialties,
      notes: notes || null,
      source: "chez_field",
    })
    .select("id, household_id, company_name, contact_name, phone, email, website, specialties, source")
    .single();

  if (insertError) throw insertError;
  return { ok: true, contractor: created };
}

/** G47 — multi-handyman support: add a workspace member to an assessment. */
async function addAssessmentMember(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const assessmentId = compactString(body.assessment_id);
  const memberId = compactString(body.member_id);
  const role = compactString(body.role) || null;
  const isPrimary = body.is_primary === true;
  if (!assessmentId || !memberId) throw new Error("assessment_id + member_id required");

  // If marking primary, demote existing primary first
  if (isPrimary) {
    await service
      .from("home_assessment_members")
      .update({ is_primary: false })
      .eq("assessment_id", assessmentId)
      .eq("is_primary", true);
  }

  const { data, error } = await service
    .from("home_assessment_members")
    .upsert({
      assessment_id: assessmentId,
      member_id: memberId,
      is_primary: isPrimary,
      role,
    }, { onConflict: "assessment_id,member_id" })
    .select("*")
    .single();
  if (error) throw new Error(`failed: ${error.message}`);
  return { ok: true, member: data };
}

/** G32 — multi-session: open a continuation visit. */
async function startContinuationVisit(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const assessmentId = compactString(body.assessment_id);
  const workspaceId = compactString(body.workspace_id);
  const memberId = compactString(body.member_id) || null;
  const routeDate = compactString(body.route_date) || null;
  const windowStart = compactString(body.window_start_time) || null;
  const windowEnd = compactString(body.window_end_time) || null;
  if (!assessmentId || !workspaceId) throw new Error("assessment_id + workspace_id required");

  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");
  const orig = assessment as unknown as { request_id?: string; visit_assignment_id: string | null; session_count: number };

  // Get the original handyman_request id from the existing visit
  let stubRequestId: string | null = null;
  if (orig.visit_assignment_id) {
    const { data: origVisit } = await service
      .from("provider_visit_assignments")
      .select("request_id")
      .eq("id", orig.visit_assignment_id)
      .maybeSingle();
    stubRequestId = (origVisit as { request_id: string } | null)?.request_id ?? null;
  }
  if (!stubRequestId) throw new Error("original visit not found — cannot open continuation");

  const { data: visit, error: visitErr } = await service
    .from("provider_visit_assignments")
    .insert({
      workspace_id: workspaceId,
      request_id: stubRequestId,
      assigned_member_id: memberId,
      assigned_by_user_id: user.id,
      route_date: routeDate,
      window_start_time: windowStart,
      window_end_time: windowEnd,
      visit_type: "home_assessment_continuation",
    })
    .select("*")
    .single();
  if (visitErr || !visit) throw new Error(`failed: ${visitErr?.message ?? "unknown"}`);

  await service
    .from("home_assessments")
    .update({
      visit_assignment_id: (visit as { id: string }).id,
      session_count: (orig.session_count ?? 1) + 1,
      status: "scheduled",
    })
    .eq("id", assessmentId);

  return { ok: true, visit_assignment_id: (visit as { id: string }).id };
}

/** G40 — homeowner cancels a pending assessment. */
async function cancelAssessment(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const assessmentId = compactString(body.assessment_id);
  const reason = compactString(body.reason) || null;
  if (!assessmentId) throw new Error("assessment_id required");

  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");
  if (assessment.status === "completed") throw new Error("cannot cancel a completed assessment");

  await service
    .from("home_assessments")
    .update({
      status: "cancelled",
      cancelled_at: isoNow(),
      cancellation_reason: reason,
    })
    .eq("id", assessmentId);

  // Clear assessment_mode on the property so the homeowner sees the
  // self-onboard flow on next launch.
  const { data: prop } = await service
    .from("properties")
    .select("attributes")
    .eq("id", assessment.property_id)
    .maybeSingle();
  const attrs = ((prop as { attributes: Record<string, unknown> | null } | null)?.attributes) ?? {};
  delete attrs["assessment_mode"];
  await service
    .from("properties")
    .update({ attributes: attrs })
    .eq("id", assessment.property_id);

  return { ok: true };
}

/** G40 — homeowner requests a different time. */
async function rescheduleAssessment(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const assessmentId = compactString(body.assessment_id);
  const requestNotes = compactString(body.notes) || null;
  if (!assessmentId) throw new Error("assessment_id required");

  await service
    .from("home_assessments")
    .update({
      reschedule_requested_at: isoNow(),
      reschedule_request_notes: requestNotes,
    })
    .eq("id", assessmentId);

  return { ok: true };
}

// ============================================================================
// End Phase 84.5
// ============================================================================

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "Missing Supabase configuration" }, 500);
    }

    const service = createClient(supabaseUrl, serviceRoleKey);
    const url = new URL(req.url);

    if (req.method === "GET") {
      const inviteToken = compactString(url.searchParams.get("invite"));
      if (inviteToken) {
        const preview = await fetchInvitePreview(service, inviteToken);
        if (!preview) return json({ error: "Invite not found" }, 404);
        return json({ invite: preview });
      }

      const publicQuoteToken = compactString(url.searchParams.get("quote"));
      if (publicQuoteToken) {
        const payload = await publicQuotePayload(service, publicQuoteToken);
        if (!payload) return json({ error: "Quote not found" }, 404);

        const quote = payload.quote as Record<string, unknown>;
        if (compactString(quote.status) === "sent" && !quote.viewed_at) {
          await service
            .from("provider_quotes")
            .update({
              status: "viewed",
              viewed_at: isoNow(),
              updated_at: isoNow(),
            })
            .eq("id", compactString(quote.id));
        }

        return json({ publicQuote: serializePublicQuote(await publicQuotePayload(service, publicQuoteToken)) });
      }

      const teamInviteToken = compactString(url.searchParams.get("teamInvite"));
      if (teamInviteToken) {
        const preview = await fetchTeamInvitePreview(service, teamInviteToken);
        if (!preview) return json({ error: "Team invite not found" }, 404);
        return json({ teamInvite: preview });
      }

      const providerDirectoryMode = compactString(url.searchParams.get("directory"));
      if (providerDirectoryMode === "1" || providerDirectoryMode === "true") {
        const user = await getAuthenticatedUser(service, req);
        if (!user) return json({ error: "Unauthorized" }, 401);
        const query = compactString(url.searchParams.get("q"));
        const providers = await searchProviderDirectory(
          service,
          compactString(user.id),
          query,
          Math.min(Math.max(numberValue(url.searchParams.get("limit")), 1), 24) || 18,
        );
        return json({ providers });
      }

      const user = await getAuthenticatedUser(service, req);
      if (!user) return json({ error: "Unauthorized" }, 401);
      // Wave S — accept `?workspace=<uuid>` so the SPA can request a
      // specific workspace from a multi-workspace user. The membership
      // helper validates the user actually belongs there before honoring
      // it; an unrecognized id falls through to the default first-active
      // pick rather than returning an error.
      const requestedWorkspaceId = compactString(url.searchParams.get("workspace"));
      const dashboard = await loadDashboard(
        service,
        user as unknown as Record<string, unknown>,
        requestedWorkspaceId,
      );
      return json(dashboard);
    }

    if (req.method === "POST") {
      const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
      const action = compactString(body.action);

      if (action === "respond_public_quote") {
        const response = await respondToPublicQuote(service, body);
        return json(response);
      }

      const user = await getAuthenticatedUser(service, req);
      if (!user) return json({ error: "Unauthorized" }, 401);

      if (action === "bootstrap_workspace") {
        const workspaceId = await ensureWorkspaceForUser(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        const userEmail = normalizedEmail(user.email);
        const userPhone = phoneDigits(body.phone || "");
        await autoLinkWorkspaceContractors(service, workspaceId, userEmail, userPhone);
        const inviteToken = compactString(body.inviteToken);
        if (inviteToken) {
          await claimInviteForWorkspace(service, workspaceId, inviteToken, {
            companyName: compactString(body.companyName) || compactString(body.company_name),
            contactName:
              compactString(body.fullName) ||
              compactString((user.user_metadata as Record<string, unknown> | undefined)?.full_name) ||
              compactString((user.user_metadata as Record<string, unknown> | undefined)?.name),
            email: userEmail,
            phone: compactString(body.phone),
            website: compactString(body.website),
          });
        }
        const dashboard = await loadDashboard(service, user as unknown as Record<string, unknown>);
        return json(dashboard);
      }

      if (action === "invite_team_member") {
        const member = await inviteTeamMember(service, user as unknown as Record<string, unknown>, body);
        return json({ member });
      }

      if (action === "update_team_member") {
        const member = await updateTeamMember(service, user as unknown as Record<string, unknown>, body);
        return json({ member });
      }

      if (action === "update_workspace_directory") {
        const workspace = await updateWorkspaceDirectory(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json({ workspace });
      }

      if (action === "assign_visit") {
        const assignment = await assignVisit(service, user as unknown as Record<string, unknown>, body);
        return json({ assignment });
      }

      if (action === "reschedule_visit") {
        const result = await rescheduleVisit(service, user as unknown as Record<string, unknown>, body);
        return json(result);
      }

      if (action === "fetch_aggregate_tasks") {
        const result = await fetchAggregateTasks(service, user as unknown as Record<string, unknown>, body);
        return json(result);
      }

      if (action === "create_ad_hoc_visit") {
        const result = await createAdHocVisit(service, user as unknown as Record<string, unknown>, body);
        return json(result);
      }

      if (action === "create_pairing_request") {
        const result = await createPairingRequest(service, user as unknown as Record<string, unknown>, body);
        return json(result);
      }

      if (action === "link_invite") {
        const membership = await getWorkspaceMembership(service, compactString(user.id), normalizedEmail(user.email));
        const workspaceId = compactString((membership?.provider_workspaces as Record<string, unknown> | undefined)?.id);
        if (!workspaceId) return json({ error: "No provider workspace found" }, 400);
        const inviteToken = compactString(body.inviteToken);
        if (!inviteToken) return json({ error: "Missing invite token" }, 400);
        const preview = await claimInviteForWorkspace(service, workspaceId, inviteToken, {
          companyName:
            compactString((user.user_metadata as Record<string, unknown> | undefined)?.company_name) ||
            compactString((membership?.provider_workspaces as Record<string, unknown> | undefined)?.company_name),
          contactName:
            compactString((user.user_metadata as Record<string, unknown> | undefined)?.full_name) ||
            compactString((user.user_metadata as Record<string, unknown> | undefined)?.name),
          email: normalizedEmail(user.email),
          phone: compactString(body.phone),
          website:
            compactString(body.website) ||
            compactString((membership?.provider_workspaces as Record<string, unknown> | undefined)?.website),
        });
        const dashboard = await loadDashboard(service, user as unknown as Record<string, unknown>);
        return json({ ...dashboard, linkedInvite: preview });
      }

      if (action === "link_homeowner_contractor") {
        const result = await linkProviderWorkspaceForHomeowner(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "save_quote_item") {
        const item = await saveQuoteItem(service, user as unknown as Record<string, unknown>, body);
        return json({ item });
      }

      if (action === "save_quote") {
        const result = await saveQuote(service, user as unknown as Record<string, unknown>, body, false);
        return json(result);
      }

      if (action === "send_quote") {
        const result = await saveQuote(service, user as unknown as Record<string, unknown>, body, true);
        return json(result);
      }

      // Wave V.1 — quote bundles (good/better/best)
      if (action === "save_quote_bundle") {
        const result = await saveQuoteBundle(
          service,
          user as unknown as Record<string, unknown>,
          body,
          false,
        );
        return json(result);
      }
      if (action === "send_quote_bundle") {
        const result = await saveQuoteBundle(
          service,
          user as unknown as Record<string, unknown>,
          body,
          true,
        );
        return json(result);
      }
      if (action === "decide_quote_bundle") {
        const result = await decideQuoteBundle(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M4 — kitchen-table close: build a draft quote pre-filled
      // from the visit's punch items, and capture a signature on
      // approval. signQuote stamps signature_path / signed_at /
      // signed_name / signer_role and walks the quote to approved.
      if (action === "build_quote_from_visit") {
        const result = await buildQuoteFromVisit(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }
      if (action === "sign_quote") {
        const result = await signQuote(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M13 — kitchen-table efficiency: "same as the Smith house
      // yesterday." `list_recent_quotes` powers the picker in iOS
      // BuildQuoteSheet's "Or duplicate from another quote" flow AND
      // the Operations Desk Quotes screen Duplicate button.
      // `duplicate_quote` walks the source quote (including bundle
      // children if any), strips signature + approval + punch-item
      // cross-links, and inserts a fresh draft.
      if (action === "list_recent_quotes") {
        const result = await listRecentQuotes(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }
      if (action === "duplicate_quote") {
        const result = await duplicateQuote(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave Q (Section 8) — provider invoices.
      // Wave M5 — convert visit → invoice draft (one-tap close-out).
      if (action === "convert_visit_to_invoice") {
        const result = await convertVisitToInvoice(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }
      if (action === "save_invoice") {
        const result = await saveInvoice(service, user as unknown as Record<string, unknown>, body);
        return json(result);
      }
      if (action === "send_invoice") {
        const result = await saveInvoice(
          service,
          user as unknown as Record<string, unknown>,
          { ...body, send: true },
        );
        return json(result);
      }
      if (action === "void_invoice") {
        const result = await voidInvoice(service, user as unknown as Record<string, unknown>, body);
        return json(result);
      }
      if (action === "mark_invoice_paid") {
        const result = await markInvoicePaid(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "send_message") {
        const result = await sendMessage(service, user as unknown as Record<string, unknown>, body);
        return json(result);
      }

      if (action === "link_adopted_provider") {
        const result = await linkAdoptedProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "propose_visit_time") {
        const result = await proposeVisitTimeForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave T: contractor proposes 2-3 candidate slots in one shot.
      // Drops a single message into the thread with metadata.kind =
      // "visit_proposed" + slots array; the homeowner picks one and
      // a downstream action accepts it. Chat-card UX, not a calendar
      // round-trip per slot.
      if (action === "propose_visit_slots") {
        const result = await proposeVisitSlotsForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave T: photo upload helper. Caller posts base64 image; we
      // upload to the message-attachments bucket under a
      // household/request scoped path, mint a signed URL, and return
      // it. Caller then sends a regular message with metadata.attachments
      // referencing the same path + URL. We don't create the message
      // here so the caller can compose body + attachments together.
      if (action === "upload_message_attachment") {
        const result = await uploadMessageAttachment(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Homeowner-initiated push to the handyman after the homeowner
      // RPC has already updated the DB. iOS calls this after
      // accept_visit_time / propose_visit_time so the operations desk
      // gets notified instead of silently waiting for a manual refresh.
      if (action === "homeowner_notify_provider") {
        const requestId = compactString(body.requestId);
        const eventType = compactString(body.eventType) || "homeowner_message";
        const title = compactString(body.title) || "Update from your homeowner";
        const messageBody = compactString(body.body) || "";
        if (!requestId) throw new Error("requestId is required");

        const { data: req } = await service
          .from("handyman_requests")
          .select("id, contractor_id, household_id")
          .eq("id", requestId)
          .maybeSingle();
        if (!req) throw new Error("Request not found");

        // Trust check: caller must own the household this request
        // belongs to. Otherwise any signed-in user could spam pushes
        // to any provider.
        const callerUserId = compactString(user.id);
        const { data: callerRow } = await service
          .from("users")
          .select("household_id")
          .eq("id", callerUserId)
          .maybeSingle();
        const callerHouseholdId = compactString(callerRow?.household_id);
        if (!callerHouseholdId || callerHouseholdId !== compactString(req.household_id)) {
          throw new Error("You don't own this request");
        }

        await notifyProviderForRequest(service, compactString(req.contractor_id), {
          title,
          body: messageBody,
          requestId,
          eventType,
        });
        return json({ ok: true });
      }

      if (action === "accept_visit_time") {
        const result = await acceptVisitTimeForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "update_home_system") {
        const result = await updateHomeSystemForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "update_request_status") {
        const result = await updateRequestStatusForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M1 — visit lifecycle actions. start / pause / resume / complete
      // each operate on the assignment row for (workspace, request) and
      // bank elapsed time across pause windows.
      if (action === "start_visit") {
        const result = await startVisitForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "pause_visit") {
        const result = await pauseVisitForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "resume_visit") {
        const result = await resumeVisitForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "complete_visit") {
        const result = await completeVisitForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M9 — visit edge cases (co-tech + access method + mid-stream cancel).
      if (action === "add_co_tech") {
        const result = await addCoTechForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "set_access_method") {
        const result = await setAccessMethodForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "cancel_visit_mid_stream") {
        const result = await cancelVisitMidStreamForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M8 — end-of-visit suggestion authoring. The tech wraps a
      // visit and proposes follow-up work that drives recurring revenue.
      // Three light-touch artifact creators; no proposal/expiration
      // ceremony (use propose_homeowner_task / propose_followup_visit
      // for the heavier approval-bearing flows).
      if (action === "suggest_followup_task") {
        const result = await suggestFollowupTask(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }
      if (action === "suggest_followup_quote") {
        const result = await suggestFollowupQuote(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }
      if (action === "schedule_followup_visit") {
        const result = await scheduleFollowupVisit(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M11 — End-of-day summary. Aggregates today's stops + clock
      // totals + materials + invoiced revenue + tomorrow preview. Reads
      // M1's clock_in_at / clock_out_at off provider_visit_assignments;
      // gracefully returns 0 revenue when M5's provider_invoices isn't
      // populated yet.
      if (action === "today_summary") {
        const result = await todaySummaryForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M6 — internal tech notes (workspace-scoped, hidden from
      // homeowner). Auth is handled in the helper functions via
      // assertWorkspaceAccess; both functions return camelCase shapes.
      if (action === "add_tech_note") {
        const result = await addTechNoteForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "list_tech_notes") {
        const result = await listTechNotesForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M2 — punch list capture depth.
      if (action === "attach_punch_photo") {
        const result = await attachPunchPhotoForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "attach_punch_voice") {
        const result = await attachPunchVoiceForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "set_punch_materials") {
        const result = await setPunchMaterialsForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "set_punch_time_spent") {
        const result = await setPunchTimeSpentForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M12 — "Need part" flow. Mid-visit, the field tech flags a
      // needed part for operator coordination. 4 actions cover the
      // round-trip: upload a photo (returns the storage path + signed
      // URL), submit the request (creates the row + fires push to ops
      // members when blocking_now), update its status (operator routes
      // it / orders it / fulfills it), list the open queue (Today pill
      // + Operations Desk Routes section).
      if (action === "attach_part_request_photo") {
        const result = await attachPartRequestPhotoForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "create_part_request") {
        const result = await createPartRequestForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "update_part_status") {
        const result = await updatePartStatusForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "list_open_part_requests") {
        const result = await listPartRequestsForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "upload_home_system_photo") {
        const result = await uploadHomeSystemPhotoForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "delete_home_system_photo") {
        const result = await deleteHomeSystemPhotoForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "delete_quote") {
        const result = await deleteQuoteForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "split_visit_punch_list") {
        const result = await splitVisitPunchList(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "add_client") {
        const result = await addClientForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Phase 75h: provider replies to a homeowner question on a
      // specific line item. Inserts a provider-authored comment +
      // marks the parent question as answered + pushes the homeowner.
      if (action === "reply_to_quote_comment") {
        const workspaceId = compactString(body.workspaceId);
        const userId = compactString(user.id);
        const membership = await assertWorkspaceAccess(service, userId, workspaceId);
        assertPermission(membership, "canBuildQuotes");

        const parentCommentId = compactString(body.parentCommentId);
        const replyBody = compactString(body.body);
        if (!parentCommentId) throw new Error("parentCommentId is required");
        if (!replyBody) throw new Error("Reply body is required");

        // Load the parent comment + the parent quote so we know which
        // workspace + line + household this applies to.
        const { data: parent, error: parentError } = await service
          .from("provider_quote_comments")
          .select("id, quote_id, line_item_id, status")
          .eq("id", parentCommentId)
          .maybeSingle();
        if (parentError) throw parentError;
        if (!parent) throw new Error("Parent comment not found");

        const { data: quote, error: quoteError } = await service
          .from("provider_quotes")
          .select("id, workspace_id, household_id, request_id, title")
          .eq("id", parent.quote_id)
          .eq("workspace_id", workspaceId)
          .maybeSingle();
        if (quoteError) throw quoteError;
        if (!quote) throw new Error("Quote not found in this workspace");

        const { data: inserted, error: insertError } = await service
          .from("provider_quote_comments")
          .insert({
            quote_id: parent.quote_id,
            line_item_id: parent.line_item_id,
            parent_comment_id: parentCommentId,
            author_role: "provider",
            author_user_id: userId,
            body: replyBody,
            status: "answered",
          })
          .select()
          .single();
        if (insertError) throw insertError;

        // Mark the original question as answered.
        await service
          .from("provider_quote_comments")
          .update({ status: "answered" })
          .eq("id", parentCommentId);

        // Push the homeowner so they see the reply without manual refresh.
        if (compactString(quote.household_id)) {
          await notifyHomeownersForRequest(service, compactString(quote.household_id), {
            title: "Your handyman replied",
            body: `New reply on "${compactString(quote.title)}". Tap to read.`,
            requestId: compactString(quote.request_id) || compactString(quote.id),
            eventType: "handyman_quote_reply",
            extra: { quote_id: compactString(quote.id) },
          });
        }

        return json({ ok: true, reply: inserted });
      }

      // =====================================================================
      // Phase 78 — Homeowner ↔ Handyman coordination actions
      // =====================================================================

      // Homeowner-callable. Converts an existing maintenance_task into a
      // handyman punch list item. Sets delegated_to_punch_item_id on the
      // source task so the homeowner UI can hide it from the primary list
      // while preserving service history. If no upcoming handyman visit
      // exists, the punch item lands as a wishlist item
      // (assigned_visit_task_id = null).
      if (action === "delegate_task_to_punch_list") {
        const callerUserId = compactString(user.id);
        const taskId = compactString(body.taskId);
        if (!taskId) return json({ error: "taskId is required" }, 400);

        const { data: task, error: taskErr } = await service
          .from("maintenance_tasks")
          .select("id, household_id, property_id, system_id, title, priority, estimated_cost, delegated_to_punch_item_id")
          .eq("id", taskId)
          .maybeSingle();
        if (taskErr) throw taskErr;
        if (!task) return json({ error: "Task not found" }, 404);

        // Caller must own the household.
        const { data: callerRow } = await service
          .from("users").select("household_id").eq("id", callerUserId).maybeSingle();
        if (compactString(callerRow?.household_id) !== compactString(task.household_id)) {
          return json({ error: "Not your household" }, 403);
        }

        if (compactString(task.delegated_to_punch_item_id)) {
          return json({ error: "Task is already delegated" }, 409);
        }

        // Resolve target visit (caller-supplied OR next unlocked handyman
        // visit on this property).
        let targetVisitTaskId = compactString(body.targetVisitTaskId) || null;
        if (!targetVisitTaskId && task.property_id) {
          const { data: nextVisit } = await service
            .from("maintenance_tasks")
            .select("id")
            .eq("property_id", task.property_id)
            .eq("household_id", task.household_id)
            .like("template_id", "Handyman:%")
            .is("archived_at", null)
            .is("delegated_to_punch_item_id", null)
            .gte("next_due_date", new Date().toISOString().slice(0, 10))
            .order("next_due_date", { ascending: true })
            .limit(1)
            .maybeSingle();
          targetVisitTaskId = compactString(nextVisit?.id) || null;
        }

        // Snapshot the system label so an archived/renamed system later
        // still renders a sensible label.
        let systemLabelSnapshot: string | null = null;
        if (task.system_id) {
          const { data: sys } = await service
            .from("home_systems")
            .select("name")
            .eq("id", task.system_id)
            .maybeSingle();
          systemLabelSnapshot = compactString(sys?.name) || null;
        }

        const now = new Date().toISOString();
        const { data: punchInsert, error: punchErr } = await service
          .from("handyman_punch_items")
          .insert({
            household_id: task.household_id,
            property_id: task.property_id,
            title: compactString(task.title),
            source: "maintenance_task",
            source_task_id: taskId,
            delegated_from_task_id: taskId,
            assigned_visit_task_id: targetVisitTaskId,
            system_id: task.system_id,
            system_label_snapshot: systemLabelSnapshot,
            status: targetVisitTaskId ? "assigned" : "pending",
            priority: compactString(task.priority) || "medium",
            added_by_user_id: callerUserId,
            proposed_by_user_id: callerUserId,
            proposed_by_role: "homeowner",
            proposed_at: now,
            proposal_status: "accepted",
            accepted_by_user_id: callerUserId,
            accepted_at: now,
          })
          .select("id, assigned_visit_task_id")
          .single();
        if (punchErr) throw punchErr;

        await service
          .from("maintenance_tasks")
          .update({
            delegated_to_punch_item_id: compactString(punchInsert.id),
            updated_at: now,
          })
          .eq("id", taskId);

        // Fan-out: tell the linked handyman a new item appeared.
        if (targetVisitTaskId) {
          const { data: visitReq } = await service
            .from("handyman_requests")
            .select("id, contractor_id, visit_locked_at, household_id")
            .eq("visit_task_id", targetVisitTaskId)
            .limit(1)
            .maybeSingle();
          if (visitReq?.contractor_id) {
            await notifyProviderForRequest(service, compactString(visitReq.contractor_id), {
              title: "New punch item from homeowner",
              body: `"${compactString(task.title)}" added to the upcoming visit.`,
              requestId: compactString(visitReq.id),
              eventType: "handyman_punch_item_added",
            });
            // Mark added_after_lock if visit is already locked.
            if (compactString(visitReq.visit_locked_at)) {
              await service
                .from("handyman_punch_items")
                .update({ added_after_lock: true, updated_at: now })
                .eq("id", compactString(punchInsert.id));
            }
          }
        }

        return json({
          ok: true,
          punchItemId: compactString(punchInsert.id),
          assignedVisitTaskId: compactString(punchInsert.assigned_visit_task_id) || null,
        });
      }

      // Handyman-callable. Flags a maintenance task for the homeowner to
      // accept ("you need a roofer"). Creates a maintenance_tasks row with
      // proposal_status='pending' that lands in the homeowner's proposals
      // inbox. Requires workspace access on the visit's contractor.
      if (action === "propose_homeowner_task") {
        const workspaceId = compactString(body.workspaceId);
        const userId = compactString(user.id);
        await assertWorkspaceAccess(service, userId, workspaceId);

        const originVisitTaskId = compactString(body.originVisitTaskId);
        const title = compactString(body.title);
        const message = compactString(body.message);
        const suggestedCategory = compactString(body.suggestedCategory) || null;
        const attachments = Array.isArray(body.attachments) ? body.attachments : [];
        const requiresApproval = Boolean(body.requiresHomeownerApproval);

        if (!originVisitTaskId) return json({ error: "originVisitTaskId is required" }, 400);
        if (!title) return json({ error: "title is required" }, 400);

        // Resolve household + property from the originating visit.
        const { data: visit } = await service
          .from("maintenance_tasks")
          .select("id, household_id, property_id")
          .eq("id", originVisitTaskId)
          .maybeSingle();
        if (!visit) return json({ error: "Originating visit not found" }, 404);

        const now = new Date().toISOString();
        const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();

        // Suggested vendor search payload pre-filters FindLocalVendorSheet.
        let suggestedVendorSearch: Record<string, unknown> | null = null;
        if (suggestedCategory && visit.property_id) {
          const { data: prop } = await service
            .from("properties").select("city, state").eq("id", visit.property_id).maybeSingle();
          suggestedVendorSearch = {
            category: suggestedCategory,
            town: compactString(prop?.city) || null,
            state: compactString(prop?.state) || null,
          };
        }

        const { data: inserted, error: insertErr } = await service
          .from("maintenance_tasks")
          .insert({
            household_id: visit.household_id,
            property_id: visit.property_id,
            title,
            description: message,
            frequency: "Once",
            next_due_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
            priority: "medium",
            assignment_type: "vendor",
            needs_vendor: true,
            suggested_category: suggestedCategory,
            suggested_vendor_search: suggestedVendorSearch,
            proposed_by_user_id: userId,
            proposed_by_role: "handyman",
            proposed_at: now,
            proposal_message: message || null,
            proposal_status: "pending",
            proposal_expires_at: expiresAt,
            proposal_attachments: attachments,
            proposal_origin_visit_task_id: originVisitTaskId,
            requires_homeowner_approval: requiresApproval,
          })
          .select("id")
          .single();
        if (insertErr) throw insertErr;

        await notifyHomeownersForRequest(service, compactString(visit.household_id), {
          title: "Your handyman flagged something",
          body: title.length > 80 ? title.slice(0, 77) + "…" : title,
          requestId: compactString(inserted.id),
          eventType: "handyman_proposal_pending",
          extra: { task_id: compactString(inserted.id), kind: "task" },
        });

        return json({ ok: true, taskId: compactString(inserted.id) });
      }

      // Handyman-callable. Suggests a follow-up visit, optionally bringing
      // along punch items from the originating visit. Creates a new
      // handyman_requests row with proposal_status='pending'. Optional
      // proposed_visit_at uses the existing propose_visit_time RPC for
      // homeowner-side accept/counter ergonomics.
      if (action === "propose_followup_visit") {
        const workspaceId = compactString(body.workspaceId);
        const userId = compactString(user.id);
        await assertWorkspaceAccess(service, userId, workspaceId);

        const parentRequestId = compactString(body.parentRequestId);
        const title = compactString(body.title) || "Follow-up visit";
        const details = compactString(body.details);
        const proposedAt = compactString(body.proposedAt);
        const punchItemIds = Array.isArray(body.punchItemIds)
          ? (body.punchItemIds as unknown[]).map((v) => compactString(v)).filter(Boolean)
          : [];
        const costEstimateLow = body.costEstimateLow != null ? numberValue(body.costEstimateLow) : null;
        const costEstimateHigh = body.costEstimateHigh != null ? numberValue(body.costEstimateHigh) : null;
        const costEstimateKind = compactString(body.costEstimateKind) || (costEstimateLow != null || costEstimateHigh != null ? "ballpark" : "none");

        if (!parentRequestId) return json({ error: "parentRequestId is required" }, 400);

        const { data: parent } = await service
          .from("handyman_requests")
          .select("id, household_id, property_id, contractor_id")
          .eq("id", parentRequestId)
          .maybeSingle();
        if (!parent) return json({ error: "Parent request not found" }, 404);

        const now = new Date().toISOString();
        const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();

        const { data: newRequest, error: reqErr } = await service
          .from("handyman_requests")
          .insert({
            household_id: parent.household_id,
            property_id: parent.property_id,
            contractor_id: parent.contractor_id,
            request_type: "standard_visit",
            source: "vendor",
            title,
            details: details || null,
            status: "submitted",
            parent_request_id: parentRequestId,
            proposal_status: "pending",
            proposal_expires_at: expiresAt,
            proposal_message: details || null,
            cost_estimate_low: costEstimateLow,
            cost_estimate_high: costEstimateHigh,
            cost_estimate_kind: costEstimateKind,
          })
          .select("id, visit_task_id")
          .single();
        if (reqErr) throw reqErr;

        // If a proposed time was supplied, run propose_visit_time so the
        // existing accept_visit_time machinery covers homeowner accept.
        if (proposedAt) {
          await service.rpc("propose_visit_time", {
            p_request_id: compactString(newRequest.id),
            p_proposed_at: proposedAt,
            p_proposed_by_role: "handyman",
            p_note: details || null,
          });
        }

        // Pre-attach punch items by setting their assigned_visit_task_id
        // to the new request's visit_task_id (created by propose_visit_time
        // or by a follow-up trigger; may be null at this point — server
        // gracefully handles that and the punch items remain on the parent
        // visit until the new visit's task row materializes).
        if (punchItemIds.length && newRequest.visit_task_id) {
          await service
            .from("handyman_punch_items")
            .update({
              assigned_visit_task_id: compactString(newRequest.visit_task_id),
              status: "assigned",
              updated_at: now,
            })
            .in("id", punchItemIds);
        }

        await notifyHomeownersForRequest(service, compactString(parent.household_id), {
          title: "Follow-up visit suggested",
          body: title,
          requestId: compactString(newRequest.id),
          eventType: "handyman_proposal_pending",
          extra: { request_id: compactString(newRequest.id), kind: "request" },
        });

        return json({ ok: true, requestId: compactString(newRequest.id) });
      }

      // Generic accept/decline/cancel for any of the three proposal-bearing
      // rows (task, punch_item, request). Either party may call. The DB
      // unique partial index prevents double-accept races.
      if (action === "respond_to_proposal") {
        const callerUserId = compactString(user.id);
        const kind = compactString(body.kind);
        const targetId = compactString(body.id);
        // body.action is "respond_to_proposal" (already consumed by the
        // outer router). The actual decision rides on body.decision.
        const decision = compactString(body.decision);
        const reason = compactString(body.reason);
        if (!["task", "punch_item", "request"].includes(kind)) {
          return json({ error: "kind must be task | punch_item | request" }, 400);
        }
        if (!["accept", "decline", "cancel"].includes(decision)) {
          return json({ error: "action must be accept | decline | cancel" }, 400);
        }
        if (!targetId) return json({ error: "id is required" }, 400);

        const tableMap: Record<string, string> = {
          task: "maintenance_tasks",
          punch_item: "handyman_punch_items",
          request: "handyman_requests",
        };
        const tableName = tableMap[kind];

        const { data: existing } = await service
          .from(tableName)
          .select(
            tableName === "handyman_requests"
              ? "id, household_id, contractor_id, proposal_status, requires_homeowner_approval"
              : "id, household_id, proposal_status, requires_homeowner_approval, proposed_by_role"
          )
          .eq("id", targetId)
          .maybeSingle();
        if (!existing) return json({ error: "Proposal not found" }, 404);

        if (compactString(existing.proposal_status) !== "pending") {
          return json({ error: `Proposal is ${compactString(existing.proposal_status)}; cannot respond` }, 409);
        }

        // Caller authorization. Homeowner-side: caller must be in the
        // household. Handyman-side: caller must be a workspace member of
        // the contractor on the request.
        const { data: callerRow } = await service
          .from("users").select("household_id").eq("id", callerUserId).maybeSingle();
        const callerHouseholdId = compactString(callerRow?.household_id);
        const isHomeowner = callerHouseholdId === compactString(existing.household_id);

        let isHandyman = false;
        if (!isHomeowner && tableName === "handyman_requests" && existing.contractor_id) {
          const { data: workspaceLink } = await service
            .from("provider_contractor_links")
            .select("workspace_id")
            .eq("contractor_id", compactString(existing.contractor_id))
            .limit(1)
            .maybeSingle();
          if (workspaceLink?.workspace_id) {
            try {
              await assertWorkspaceAccess(service, callerUserId, compactString(workspaceLink.workspace_id));
              isHandyman = true;
            } catch (_) { /* not a member */ }
          }
        }
        if (!isHomeowner && !isHandyman) return json({ error: "Not authorized" }, 403);

        // Home manager guardrail: above-threshold proposals can't be
        // accepted by managers/staff — only the homeowner.
        if (decision === "accept" && existing.requires_homeowner_approval) {
          const { data: caller } = await service
            .from("family_members")
            .select("member_type")
            .eq("linked_user_id", callerUserId)
            .maybeSingle();
          const memberType = compactString(caller?.member_type);
          if (memberType === "home_manager" || memberType === "staff") {
            return json({ error: "This proposal needs homeowner approval" }, 403);
          }
        }

        const now = new Date().toISOString();
        // maintenance_tasks doesn't have an `updated_at` column — only
        // handyman_punch_items and handyman_requests do. Pre-Wave-6 the
        // payload included updated_at unconditionally and EVERY accept /
        // decline of a handyman task proposal returned PGRST204 schema
        // errors, breaking 100% of homeowner accept-flow on the most
        // visible Section 5 entry point. Branch on table.
        const includeUpdatedAt = tableName !== "maintenance_tasks";
        const updatePayload: Record<string, unknown> =
          decision === "accept"
            ? { proposal_status: "accepted", accepted_by_user_id: callerUserId, accepted_at: now, ...(includeUpdatedAt ? { updated_at: now } : {}) }
            : decision === "decline"
            ? { proposal_status: "declined", declined_by_user_id: callerUserId, declined_at: now, declined_reason: reason || null, ...(includeUpdatedAt ? { updated_at: now } : {}) }
            : { proposal_status: "cancelled", ...(includeUpdatedAt ? { updated_at: now } : {}) };

        const { error: updErr } = await service
          .from(tableName)
          .update(updatePayload)
          .eq("id", targetId)
          .eq("proposal_status", "pending");          // optimistic guard
        if (updErr) {
          if (String(updErr.code) === "23505") {
            return json({ error: "Already responded by another user" }, 409);
          }
          throw updErr;
        }

        // Side-effects per kind on accept:
        if (decision === "accept" && kind === "request") {
          // Walk request status to scheduled so the visit shows up on
          // the calendar. The existing propose_visit_time / accept_visit_time
          // machinery handles the time-side; this only flips proposal_status.
          await service.from("handyman_requests")
            .update({ status: "scheduled", updated_at: now })
            .eq("id", targetId);
        }

        // Notify the OTHER side.
        const eventType = decision === "accept"
          ? "handyman_proposal_accepted"
          : decision === "decline"
          ? "handyman_proposal_declined"
          : "handyman_proposal_cancelled";

        if (isHomeowner && tableName === "handyman_requests" && existing.contractor_id) {
          await notifyProviderForRequest(service, compactString(existing.contractor_id), {
            title: decision === "accept" ? "Homeowner accepted" : decision === "decline" ? "Homeowner declined" : "Homeowner cancelled",
            body: `Proposal ${decision}ed.`,
            requestId: targetId,
            eventType,
          });
        } else if (isHandyman) {
          await notifyHomeownersForRequest(service, compactString(existing.household_id), {
            title: decision === "accept" ? "Your handyman accepted" : "Your handyman cancelled",
            body: `Proposal ${decision}ed.`,
            requestId: targetId,
            eventType,
          });
        }

        return json({ ok: true });
      }

      // Either party. Adds one or more punch items to a specific visit.
      // For new items, supports template_id (auto-fills minutes/category)
      // OR free-text title. If the visit is locked and the caller is the
      // homeowner, items get added_after_lock=true so the handyman sees a
      // "needs your confirmation" badge.
      if (action === "add_punch_items_to_visit") {
        const callerUserId = compactString(user.id);
        const visitTaskId = compactString(body.visitTaskId);
        const items = Array.isArray(body.items) ? body.items : [];
        if (!visitTaskId) return json({ error: "visitTaskId is required" }, 400);
        if (!items.length) return json({ error: "items[] is required" }, 400);

        const { data: visit } = await service
          .from("maintenance_tasks")
          .select("id, household_id, property_id")
          .eq("id", visitTaskId)
          .maybeSingle();
        if (!visit) return json({ error: "Visit not found" }, 404);

        const { data: callerRow } = await service
          .from("users").select("household_id").eq("id", callerUserId).maybeSingle();
        const callerHouseholdId = compactString(callerRow?.household_id);
        const isHomeowner = callerHouseholdId === compactString(visit.household_id);

        // Workspace access check for handyman caller path. Reuses the
        // visit's linked request to discover the contractor.
        let isHandyman = false;
        let visitLockedAt: string | null = null;
        const { data: linkedReq } = await service
          .from("handyman_requests")
          .select("id, contractor_id, visit_locked_at")
          .eq("visit_task_id", visitTaskId)
          .limit(1)
          .maybeSingle();
        if (linkedReq) {
          visitLockedAt = compactString(linkedReq.visit_locked_at) || null;
          if (!isHomeowner && linkedReq.contractor_id) {
            const { data: workspaceLink } = await service
              .from("provider_contractor_links")
              .select("workspace_id")
              .eq("contractor_id", compactString(linkedReq.contractor_id))
              .limit(1)
              .maybeSingle();
            if (workspaceLink?.workspace_id) {
              try {
                await assertWorkspaceAccess(service, callerUserId, compactString(workspaceLink.workspace_id));
                isHandyman = true;
              } catch (_) { /* not a member */ }
            }
          }
        }
        if (!isHomeowner && !isHandyman) return json({ error: "Not authorized" }, 403);

        const callerRole = isHomeowner ? "homeowner" : "handyman";
        const now = new Date().toISOString();
        const inserts: Record<string, unknown>[] = [];

        for (const raw of items) {
          const item = raw as Record<string, unknown>;
          const templateId = compactString(item.templateId) || null;
          let title = compactString(item.title);
          let minutes = item.estimatedMinutes != null ? numberValue(item.estimatedMinutes) : null;
          let categorySnapshot: string | null = null;

          if (templateId) {
            const { data: tpl } = await service
              .from("punch_list_templates")
              .select("title, default_minutes, system_category")
              .eq("id", templateId)
              .maybeSingle();
            if (tpl) {
              if (!title) title = compactString(tpl.title);
              if (minutes == null && tpl.default_minutes != null) minutes = numberValue(tpl.default_minutes);
              categorySnapshot = compactString(tpl.system_category) || null;
            }
          }

          if (!title) continue;

          // Resolve system_id by category match on the property.
          let systemId: string | null = compactString(item.systemId) || null;
          let systemLabel: string | null = null;
          if (!systemId && categorySnapshot && visit.property_id) {
            const { data: sys } = await service
              .from("home_systems")
              .select("id, name")
              .eq("property_id", visit.property_id)
              .ilike("category", categorySnapshot)
              .limit(1)
              .maybeSingle();
            if (sys) {
              systemId = compactString(sys.id);
              systemLabel = compactString(sys.name);
            }
          } else if (systemId) {
            const { data: sys } = await service
              .from("home_systems").select("name").eq("id", systemId).maybeSingle();
            systemLabel = compactString(sys?.name) || null;
          }

          inserts.push({
            household_id: visit.household_id,
            property_id: visit.property_id,
            assigned_visit_task_id: visitTaskId,
            template_id: templateId,
            title,
            source: templateId ? "template" : "manual",
            system_id: systemId,
            system_label_snapshot: systemLabel,
            estimated_minutes: minutes,
            priority: compactString(item.priority) || "medium",
            material_required: Boolean(item.materialRequired),
            status: "assigned",
            added_by_user_id: callerUserId,
            added_after_lock: Boolean(visitLockedAt) && isHomeowner,
            proposed_by_user_id: callerUserId,
            proposed_by_role: callerRole,
            proposed_at: now,
            proposal_status: "accepted",
            accepted_by_user_id: callerUserId,
            accepted_at: now,
          });
        }

        if (!inserts.length) return json({ error: "No valid items to add" }, 400);

        const { data: insertedRows, error: insertErr } = await service
          .from("handyman_punch_items")
          .insert(inserts)
          .select("id");
        if (insertErr) throw insertErr;

        // Notify the OTHER side.
        if (isHomeowner && linkedReq?.contractor_id && visitLockedAt) {
          await notifyProviderForRequest(service, compactString(linkedReq.contractor_id), {
            title: "Punch items added after lock",
            body: `${inserts.length} new ${inserts.length === 1 ? "item" : "items"} need your confirmation.`,
            requestId: compactString(linkedReq.id),
            eventType: "handyman_punch_item_added",
          });
        } else if (isHandyman) {
          await notifyHomeownersForRequest(service, compactString(visit.household_id), {
            title: "Punch items added to your visit",
            body: `${inserts.length} new ${inserts.length === 1 ? "item" : "items"}.`,
            requestId: linkedReq ? compactString(linkedReq.id) : visitTaskId,
            eventType: "handyman_punch_item_added",
          });
        }

        return json({ ok: true, count: insertedRows.length, ids: insertedRows.map((r) => compactString(r.id)) });
      }

      // Either party. Marks a punch item status (assigned → in_progress
      // → done) without going through accept/decline. Used by handyman
      // during a live visit to check items off, and by homeowner to
      // cancel an item ("nevermind").
      if (action === "update_punch_item_status") {
        const callerUserId = compactString(user.id);
        const itemId = compactString(body.itemId);
        const newStatus = compactString(body.status);
        if (!itemId) return json({ error: "itemId is required" }, 400);
        if (!["pending", "assigned", "in_progress", "done", "cancelled"].includes(newStatus)) {
          return json({ error: "Invalid status" }, 400);
        }

        const { data: item } = await service
          .from("handyman_punch_items")
          .select("id, household_id, assigned_visit_task_id")
          .eq("id", itemId)
          .maybeSingle();
        if (!item) return json({ error: "Punch item not found" }, 404);

        const { data: callerRow } = await service
          .from("users").select("household_id").eq("id", callerUserId).maybeSingle();
        const isHomeowner = compactString(callerRow?.household_id) === compactString(item.household_id);

        // Workspace check for handyman path.
        let isHandyman = false;
        if (!isHomeowner && item.assigned_visit_task_id) {
          const { data: linkedReq } = await service
            .from("handyman_requests")
            .select("contractor_id")
            .eq("visit_task_id", compactString(item.assigned_visit_task_id))
            .limit(1)
            .maybeSingle();
          if (linkedReq?.contractor_id) {
            const { data: workspaceLink } = await service
              .from("provider_contractor_links")
              .select("workspace_id")
              .eq("contractor_id", compactString(linkedReq.contractor_id))
              .limit(1)
              .maybeSingle();
            if (workspaceLink?.workspace_id) {
              try {
                await assertWorkspaceAccess(service, callerUserId, compactString(workspaceLink.workspace_id));
                isHandyman = true;
              } catch (_) { /* not a member */ }
            }
          }
        }
        if (!isHomeowner && !isHandyman) return json({ error: "Not authorized" }, 403);

        const now = new Date().toISOString();
        const updatePayload: Record<string, unknown> = {
          status: newStatus,
          updated_at: now,
        };
        if (newStatus === "done") {
          updatePayload.completed_at = now;
          // The trg_punch_item_completion trigger will bump
          // home_systems.last_service_date if the item is system-linked.
        }

        const { error: updErr } = await service
          .from("handyman_punch_items")
          .update(updatePayload)
          .eq("id", itemId);
        if (updErr) throw updErr;

        return json({ ok: true });
      }

      // Wave O: Either party. Edits an existing punch item's title,
      // description, estimated minutes, priority, or material flag.
      // Status / completion / archival flow through dedicated actions.
      // Used by the contractor SPA inline editor and the iOS app row sheet.
      if (action === "update_punch_item") {
        const callerUserId = compactString(user.id);
        const itemId = compactString(body.itemId);
        if (!itemId) return json({ error: "itemId is required" }, 400);

        const { data: item } = await service
          .from("handyman_punch_items")
          .select("id, household_id, assigned_visit_task_id")
          .eq("id", itemId)
          .maybeSingle();
        if (!item) return json({ error: "Punch item not found" }, 404);

        const { data: callerRow } = await service
          .from("users").select("household_id").eq("id", callerUserId).maybeSingle();
        const isHomeowner = compactString(callerRow?.household_id) === compactString(item.household_id);

        let isHandyman = false;
        if (!isHomeowner && item.assigned_visit_task_id) {
          const { data: linkedReq } = await service
            .from("handyman_requests")
            .select("contractor_id")
            .eq("visit_task_id", compactString(item.assigned_visit_task_id))
            .limit(1)
            .maybeSingle();
          if (linkedReq?.contractor_id) {
            const { data: workspaceLink } = await service
              .from("provider_contractor_links")
              .select("workspace_id")
              .eq("contractor_id", compactString(linkedReq.contractor_id))
              .limit(1)
              .maybeSingle();
            if (workspaceLink?.workspace_id) {
              try {
                await assertWorkspaceAccess(service, callerUserId, compactString(workspaceLink.workspace_id));
                isHandyman = true;
              } catch (_) { /* not a member */ }
            }
          }
        }
        if (!isHomeowner && !isHandyman) return json({ error: "Not authorized" }, 403);

        const updatePayload: Record<string, unknown> = { updated_at: new Date().toISOString() };
        if (typeof body.title === "string") {
          const t = compactString(body.title);
          if (!t) return json({ error: "title cannot be empty" }, 400);
          updatePayload.title = t;
        }
        if (typeof body.description === "string" || body.description === null) {
          updatePayload.description = compactString(body.description) || null;
        }
        if (body.estimatedMinutes != null) {
          const n = numberValue(body.estimatedMinutes);
          if (!Number.isFinite(n) || n < 0) return json({ error: "estimatedMinutes must be >= 0" }, 400);
          updatePayload.estimated_minutes = n;
        } else if (body.estimatedMinutes === null) {
          updatePayload.estimated_minutes = null;
        }
        if (typeof body.priority === "string") {
          const p = compactString(body.priority);
          if (!["low", "medium", "high", "urgent"].includes(p)) {
            return json({ error: "Invalid priority" }, 400);
          }
          updatePayload.priority = p;
        }
        if (body.materialRequired != null) {
          updatePayload.material_required = Boolean(body.materialRequired);
        }

        const { error: updErr } = await service
          .from("handyman_punch_items")
          .update(updatePayload)
          .eq("id", itemId);
        if (updErr) throw updErr;

        return json({ ok: true });
      }

      // Wave O: Either party. Soft-deletes a punch item by stamping
      // archived_at. The dashboard query already filters on
      // archived_at IS NULL so the row drops out of every UI surface
      // immediately. Recovery is a manual DB operation by design —
      // homeowners and contractors get a confirm dialog before this fires.
      if (action === "archive_punch_item") {
        const callerUserId = compactString(user.id);
        const itemId = compactString(body.itemId);
        if (!itemId) return json({ error: "itemId is required" }, 400);

        const { data: item } = await service
          .from("handyman_punch_items")
          .select("id, household_id, assigned_visit_task_id")
          .eq("id", itemId)
          .maybeSingle();
        if (!item) return json({ error: "Punch item not found" }, 404);

        const { data: callerRow } = await service
          .from("users").select("household_id").eq("id", callerUserId).maybeSingle();
        const isHomeowner = compactString(callerRow?.household_id) === compactString(item.household_id);

        let isHandyman = false;
        if (!isHomeowner && item.assigned_visit_task_id) {
          const { data: linkedReq } = await service
            .from("handyman_requests")
            .select("contractor_id")
            .eq("visit_task_id", compactString(item.assigned_visit_task_id))
            .limit(1)
            .maybeSingle();
          if (linkedReq?.contractor_id) {
            const { data: workspaceLink } = await service
              .from("provider_contractor_links")
              .select("workspace_id")
              .eq("contractor_id", compactString(linkedReq.contractor_id))
              .limit(1)
              .maybeSingle();
            if (workspaceLink?.workspace_id) {
              try {
                await assertWorkspaceAccess(service, callerUserId, compactString(workspaceLink.workspace_id));
                isHandyman = true;
              } catch (_) { /* not a member */ }
            }
          }
        }
        if (!isHomeowner && !isHandyman) return json({ error: "Not authorized" }, 403);

        const now = new Date().toISOString();
        const { error: updErr } = await service
          .from("handyman_punch_items")
          .update({ archived_at: now, updated_at: now })
          .eq("id", itemId);
        if (updErr) throw updErr;

        return json({ ok: true });
      }

      // Either party. Soft-cancels a handyman_request and reverts any
      // attached punch items back to wishlist (assigned_visit_task_id=null).
      if (action === "cancel_handyman_request") {
        const callerUserId = compactString(user.id);
        const requestId = compactString(body.requestId);
        const reason = compactString(body.reason);
        if (!requestId) return json({ error: "requestId is required" }, 400);

        const { data: request } = await service
          .from("handyman_requests")
          .select("id, household_id, contractor_id, visit_task_id, status")
          .eq("id", requestId)
          .maybeSingle();
        if (!request) return json({ error: "Request not found" }, 404);
        if (compactString(request.status) === "cancelled") {
          return json({ error: "Already cancelled" }, 409);
        }

        const { data: callerRow } = await service
          .from("users").select("household_id").eq("id", callerUserId).maybeSingle();
        const isHomeowner = compactString(callerRow?.household_id) === compactString(request.household_id);

        let isHandyman = false;
        if (!isHomeowner && request.contractor_id) {
          const { data: workspaceLink } = await service
            .from("provider_contractor_links")
            .select("workspace_id")
            .eq("contractor_id", compactString(request.contractor_id))
            .limit(1)
            .maybeSingle();
          if (workspaceLink?.workspace_id) {
            try {
              await assertWorkspaceAccess(service, callerUserId, compactString(workspaceLink.workspace_id));
              isHandyman = true;
            } catch (_) {}
          }
        }
        if (!isHomeowner && !isHandyman) return json({ error: "Not authorized" }, 403);

        const callerRole = isHomeowner ? "homeowner" : "handyman";
        const now = new Date().toISOString();

        await service
          .from("handyman_requests")
          .update({
            status: "cancelled",
            cancelled_at: now,
            cancelled_by_user_id: callerUserId,
            cancelled_by_role: callerRole,
            proposal_status: compactString(request.proposal_status) === "pending" ? "cancelled" : compactString(request.proposal_status),
            proposal_message: reason || null,
            updated_at: now,
          })
          .eq("id", requestId);

        // Revert linked punch items to wishlist state.
        if (request.visit_task_id) {
          await service
            .from("handyman_punch_items")
            .update({
              assigned_visit_task_id: null,
              status: "pending",
              updated_at: now,
            })
            .eq("assigned_visit_task_id", compactString(request.visit_task_id))
            .neq("status", "done");
        }

        const eventType = "handyman_request_cancelled";
        if (isHomeowner && request.contractor_id) {
          await notifyProviderForRequest(service, compactString(request.contractor_id), {
            title: "Visit cancelled by homeowner",
            body: reason || "The homeowner cancelled this visit.",
            requestId,
            eventType,
          });
        } else if (isHandyman) {
          await notifyHomeownersForRequest(service, compactString(request.household_id), {
            title: "Visit cancelled by your handyman",
            body: reason || "Your handyman cancelled this visit.",
            requestId,
            eventType,
          });
        }

        return json({ ok: true });
      }

      // ============================================================
      // Phase 84.5 — Free Handyman Assessment dispatch + capture flow
      // ============================================================

      // Admin-only. Creates the provider_visit_assignments row that
      // links a home_assessments row to a workspace + technician,
      // moving the assessment from 'pending' to 'scheduled'.
      if (action === "dispatch_home_assessment") {
        const result = await dispatchHomeAssessment(service, user, body);
        return json(result);
      }

      // Handyman flips status='en_route' on their assessment visit.
      if (action === "mark_assessment_en_route") {
        const result = await markAssessmentEnRoute(service, user, body);
        return json(result);
      }

      // Handyman flips status='in_progress' when they arrive at the home.
      if (action === "start_assessment_visit") {
        const result = await startAssessmentVisit(service, user, body);
        return json(result);
      }

      // Autosave during capture. Handyman pushes a partial captured_*
      // payload; we deep-merge into the row so partial work survives
      // crashes / connectivity drops.
      if (action === "update_assessment_progress") {
        const result = await updateAssessmentProgress(service, user, body);
        return json(result);
      }

      // Final submission. Stamps submitted_at then runs the ingestion
      // path (writes home_systems / contractors / routines / documents /
      // house_quiz_state from the captured_* JSONB) and pushes the
      // homeowner.
      if (action === "submit_assessment_data") {
        const result = await submitAssessmentData(service, user, body, supabaseUrl, serviceRoleKey);
        return json(result);
      }

      // Handyman uploads a document captured at the home (warranty,
      // manual, invoice). Writes to the `documents` storage bucket
      // and appends the path to home_assessments.captured_document_paths.
      if (action === "upload_assessment_document") {
        const result = await uploadAssessmentDocument(service, user, body);
        return json(result);
      }

      // HavenField loads assessment context for an active visit.
      if (action === "fetch_assessment_for_visit") {
        const result = await fetchAssessmentForVisit(service, user, body);
        return json(result);
      }

      // ============================================================
      // Phase 84.5 round 2 — gap-closure actions
      // ============================================================

      // Homeowner-side: create the pending assessment row at signup.
      if (action === "request_home_assessment") {
        const result = await requestHomeAssessment(service, user, body);
        return json(result);
      }

      // Handyman captures a recommendation. Urgent items fire admin push.
      if (action === "add_recommended_task") {
        const result = await addRecommendedTask(service, user, body);
        return json(result);
      }

      // Wrap-up: homeowner_response / homeowner_handled / disputed.
      if (action === "update_recommended_task") {
        const result = await updateRecommendedTask(service, user, body);
        return json(result);
      }

      // T5.6 (post-overnight) — admin gate actions. Tom-only via the
      // Operations Desk Concierge cockpit. Both checks the
      // CHEZ_ADMIN_EMAILS allowlist before allowing the write.
      if (action === "flag_assessment_for_revision") {
        const result = await flagAssessmentForRevision(service, user, body);
        return json(result);
      }

      if (action === "decide_handyman_recommendation") {
        const result = await decideHandymanRecommendation(service, user, body);
        return json(result);
      }

      // Quick-fix during the visit. Skips chez_request fan-out.
      if (action === "mark_task_fixed_during_visit") {
        const result = await markTaskFixedDuringVisit(service, user, body);
        return json(result);
      }

      // Decommission a system without archiving (G44 + Wave M3).
      if (action === "decommission_system") {
        const result = await decommissionSystem(service, user, body);
        return json(result);
      }

      // Wave M3 — system inventory authoring on the field iOS app.
      if (action === "mark_system_followup") {
        const result = await markSystemFollowupForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "clear_system_followup") {
        const result = await clearSystemFollowupForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "attach_system_voice") {
        const result = await attachSystemVoiceForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "delete_system_voice") {
        const result = await deleteSystemVoiceForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "extract_system_from_photo") {
        const result = await extractSystemFromPhotoForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      if (action === "create_home_system") {
        const result = await createHomeSystemForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M10 — "Closest customer to me." Returns the workspace's
      // customers sorted by Haversine distance from the tech's
      // current location. Geocodes addresses via Nominatim on the
      // server side.
      if (action === "nearest_customers") {
        const result = await nearestCustomersForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M10 — extract structured data from a business card photo
      // via Claude Vision. Returns editable fields the iOS UI
      // confirms before saving as a `contractors` row.
      if (action === "extract_business_card") {
        const result = await extractBusinessCardForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Wave M10 — insert a `contractors` row from a business-card
      // capture. RLS on contractors blocks direct writes from
      // workspace-member sessions; this wrapper validates the
      // workspace serves the target household, then inserts via the
      // service-role client with `source = 'chez_field'`.
      if (action === "create_contractor_from_card") {
        const result = await createContractorFromCardForProvider(
          service,
          user as unknown as Record<string, unknown>,
          body,
        );
        return json(result);
      }

      // Multi-handyman: add a workspace member (G47).
      if (action === "add_assessment_member") {
        const result = await addAssessmentMember(service, user, body);
        return json(result);
      }

      // Open a continuation visit for a paused assessment (G32).
      if (action === "start_continuation_visit") {
        const result = await startContinuationVisit(service, user, body);
        return json(result);
      }

      // Homeowner cancels (G40).
      if (action === "cancel_assessment") {
        const result = await cancelAssessment(service, user, body);
        return json(result);
      }

      // Homeowner requests a different time (G40).
      if (action === "reschedule_assessment") {
        const result = await rescheduleAssessment(service, user, body);
        return json(result);
      }

      // ============================================================
      // End Phase 84.5
      // ============================================================

      // Cron-callable. Flips proposal_status='expired' on all rows past
      // proposal_expires_at. Service-role only — guarded by the function's
      // caller (scheduled tasks pass a special header) OR a workspace owner
      // sweep.
      if (action === "expire_stale_proposals") {
        const now = new Date().toISOString();
        const tables = ["maintenance_tasks", "handyman_punch_items", "handyman_requests"];
        const counts: Record<string, number> = {};
        for (const tbl of tables) {
          const { data, error: expErr } = await service
            .from(tbl)
            .update({ proposal_status: "expired", updated_at: now })
            .lt("proposal_expires_at", now)
            .eq("proposal_status", "pending")
            .select("id");
          if (expErr) throw expErr;
          counts[tbl] = (data ?? []).length;
        }
        return json({ ok: true, expired: counts });
      }

      return json({ error: "Unknown action" }, 400);
    }

    return json({ error: "Method not allowed" }, 405);
  } catch (error) {
    console.error("[handyman-provider] unhandled error", error);
    // Surface real failure reasons. Supabase's PostgrestError isn't
    // an `instanceof Error` — it's a plain object with `message` /
    // `details` / `hint` / `code`. Without this the React side just
    // sees "Internal error" and we have to dig through dashboard
    // logs to find a CHECK violation.
    let message = "Internal error";
    if (error instanceof Error) {
      message = error.message;
    } else if (error && typeof error === "object") {
      const err = error as Record<string, unknown>;
      const msg = compactString(err.message);
      const details = compactString(err.details);
      const hint = compactString(err.hint);
      const code = compactString(err.code);
      // Joined with " · " (middle-dot) per CLAUDE.md "no em dashes in
      // user-facing copy" — this string can leak to the iOS field app
      // through error.localizedDescription on a 5xx response.
      message = [msg, details, hint, code ? `(${code})` : ""].filter(Boolean).join(" · ") || "Internal error";
    }
    return json({ error: message }, 500);
  }
});

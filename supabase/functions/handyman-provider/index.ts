import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const PROVIDER_SITE_URL = "https://www.getchez.com/handyman.html";
const FIELD_SITE_URL = "https://www.getchez.com/handyman-visit.html";
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
      return "Sent to handyman";
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

function fieldVisitUrl(token: string, visitId?: string | null) {
  const params = new URLSearchParams({ token });
  if (visitId) params.set("visit", visitId);
  return `${FIELD_SITE_URL}?${params.toString()}`;
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

async function getWorkspaceMembership(service: ServiceClient, userId: string) {
  const { data, error } = await service
    .from("provider_workspace_members")
    .select("id, workspace_id, role, full_name, email, phone, title, status, invite_token, provider_workspaces(*)")
    .eq("user_id", userId)
    .eq("status", "active")
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  return data as Record<string, unknown> | null;
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
      footer: "Open Chez to reply or coordinate next steps with your handyman.",
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

  const existing = await getWorkspaceMembership(service, userId);
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
    title: compactString(request?.title) || compactString(session.title) || "Chez Handyman Visit",
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

async function loadDashboard(service: ServiceClient, user: Record<string, unknown>) {
  const userId = compactString(user.id);
  const membership = await getWorkspaceMembership(service, userId);
  if (!membership) {
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
  const today = localDateString();

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

  const [
    teamMembersResult,
    assignmentsResult,
    requestsResult,
    sessionsResult,
    quotesResult,
    savedItemsResult,
  ] = await Promise.all([
    service
      .from("provider_workspace_members")
      .select("id, workspace_id, user_id, full_name, email, phone, title, role, status, invite_token, last_seen_at, created_at, updated_at")
      .eq("workspace_id", workspaceId)
      .order("status", { ascending: true })
      .order("created_at", { ascending: true }),
    service
      .from("provider_visit_assignments")
      .select("*")
      .eq("workspace_id", workspaceId)
      .order("route_date", { ascending: true })
      .order("stop_order", { ascending: true }),
    contractorIds.length
      ? service
          .from("handyman_requests")
          .select("*")
          .in("contractor_id", contractorIds)
          .order("updated_at", { ascending: false })
          .limit(120)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    contractorIds.length
      ? service
          .from("handyman_portal_sessions")
          .select("*")
          .in("contractor_id", contractorIds)
          .order("updated_at", { ascending: false })
          .limit(120)
      : Promise.resolve({ data: [] as Record<string, unknown>[], error: null }),
    service
      .from("provider_quotes")
      .select("*")
      .eq("workspace_id", workspaceId)
      .order("updated_at", { ascending: false })
      .limit(120),
    service
      .from("provider_saved_quote_items")
      .select("*")
      .eq("workspace_id", workspaceId)
      .order("sort_order", { ascending: true })
      .order("created_at", { ascending: false }),
  ]);

  if (teamMembersResult.error) throw teamMembersResult.error;
  if (assignmentsResult.error) throw assignmentsResult.error;
  if (requestsResult.error) throw requestsResult.error;
  if (sessionsResult.error) throw sessionsResult.error;
  if (quotesResult.error) throw quotesResult.error;
  if (savedItemsResult.error) throw savedItemsResult.error;

  let teamMembers = (teamMembersResult.data ?? []) as Record<string, unknown>[];
  let assignments = (assignmentsResult.data ?? []) as Record<string, unknown>[];
  const requests = (requestsResult.data ?? []) as Record<string, unknown>[];
  let sessions = (sessionsResult.data ?? []) as Record<string, unknown>[];
  let quotes = (quotesResult.data ?? []) as Record<string, unknown>[];
  const savedItems = (savedItemsResult.data ?? []) as Record<string, unknown>[];
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
      [...visibleRequests.map((row) => compactString(row.property_id)), ...sessions.map((row) => compactString(row.property_id)), ...quotes.map((row) => compactString(row.property_id))]
        .filter(Boolean),
    ),
  ];

  const quoteIds = quotes.map((row) => compactString(row.id)).filter(Boolean);

  const [messagesResult, reportsResult, propertiesResult, systemsResult, visitTasksResult, quoteMessagesResult, openTasksResult, documentsResult] = await Promise.all([
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
  ]);

  if (messagesResult.error) throw messagesResult.error;
  if (reportsResult.error) throw reportsResult.error;
  if (propertiesResult.error) throw propertiesResult.error;
  if (systemsResult.error) throw systemsResult.error;
  if (visitTasksResult.error) throw visitTasksResult.error;
  if (quoteMessagesResult.error) throw quoteMessagesResult.error;
  if (openTasksResult.error) throw openTasksResult.error;
  if (documentsResult.error) throw documentsResult.error;

  const messages = (messagesResult.data ?? []) as Record<string, unknown>[];
  const reports = (reportsResult.data ?? []) as Record<string, unknown>[];
  const properties = (propertiesResult.data ?? []) as Record<string, unknown>[];
  const systems = (systemsResult.data ?? []) as Record<string, unknown>[];
  const visitTasks = (visitTasksResult.data ?? []) as Record<string, unknown>[];
  const quoteMessages = (quoteMessagesResult.data ?? []) as Record<string, unknown>[];
  const openTasks = (openTasksResult.data ?? []) as Record<string, unknown>[];
  const propertyDocuments = (documentsResult.data ?? []) as Record<string, unknown>[];

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
          }
        : null,
      latestMessage: message
        ? {
            senderRole: compactString(message.sender_role),
            body: compactString(message.body),
            createdAt: message.created_at,
          }
        : null,
      quote: quote
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
            homeownerRevisedAt: quote.homeowner_revised_at ?? null,
            updatedAt: quote.updated_at,
            publicShareUrl: publicQuoteUrl(compactString(quote.public_share_token)),
          }
        : null,
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

    return {
      propertyId,
      householdId: compactString(homeVisits[0]?.householdId),
      name: compactString(property?.name) || "Home",
      address: [property?.street, property?.city, property?.state, property?.zip_code].filter(Boolean).join(", "),
      systemCount: homeSystems.length,
      openRequests: homeVisits.filter((row) => !["completed", "cancelled", "declined"].includes(row.status)).length,
      lastCompletedVisit: completed[0]?.fieldWorkspace?.completedAt ?? null,
      assignedMembers: [...new Set(homeVisits.map((row) => row.assignment?.memberName).filter(Boolean))],
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
      quote: visitRow?.quote ?? null,
    };
  });

  const recentWork = visitRows
    .filter((row) => row.fieldWorkspace?.reportStatus === "completed")
    .sort((lhs, rhs) => String(rhs.fieldWorkspace?.completedAt || "").localeCompare(String(lhs.fieldWorkspace?.completedAt || "")))
    .slice(0, 8);

  const activeMembers = teamMembers.filter((row) => compactString(row.status) === "active");
  const teamMemberRows = teamMembers.map((member) => {
    const memberId = compactString(member.id);
    const memberVisits = visitRows.filter((row) => row.assignment?.memberId === memberId);
    const todayStops = memberVisits.filter((row) => row.routeDate === today).length;
    const openVisits = memberVisits.filter((row) => !["completed", "cancelled", "declined"].includes(row.status)).length;
    const completedCount = memberVisits.filter((row) => row.status === "completed").length;
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
      mobileFocus: compactString(member.role) === "technician",
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
    quotes: quotes.map((quote) => {
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
      };
    }),
    savedQuoteItems: savedItems.map((item) => ({
      id: item.id,
      name: compactString(item.name),
      description: compactString(item.description),
      unit: compactString(item.unit) || "ea",
      defaultQuantity: numberValue(item.default_quantity || 1),
      defaultUnitPrice: numberValue(item.default_unit_price || 0),
      sortOrder: numberValue(item.sort_order),
    })),
  };
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
  await service.from("handyman_request_messages").insert([
    {
      request_id: requestId,
      household_id: householdId,
      sender_role: "vendor",
      sender_user_id: userId,
      body: `Split this visit: ${movedSummary} The follow-up is now its own thread.`,
      metadata: { kind: "text", split_to_request_id: newRequest.id },
    },
    {
      request_id: newRequest.id,
      household_id: householdId,
      sender_role: "vendor",
      sender_user_id: userId,
      body: `Created from a previous visit. ${moved.length} item${moved.length === 1 ? "" : "s"} ready to schedule${followUpDate ? ` for ${followUpDate}` : ""}.`,
      metadata: { kind: "text", split_from_request_id: requestId },
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
    .select("id, contractor_id")
    .eq("id", requestId)
    .maybeSingle();
  if (!request) throw new Error("Request not found");
  if (!contractorIds.includes(compactString(request.contractor_id))) {
    throw new Error("Request not in this workspace");
  }

  const { data: updated, error: updateError } = await service
    .from("handyman_requests")
    .update({ status, updated_at: isoNow() })
    .eq("id", requestId)
    .select()
    .single();
  if (updateError) throw updateError;
  return { request: updated };
}

async function assertWorkspaceAccess(service: ServiceClient, userId: string, workspaceId: string) {
  const membership = await getWorkspaceMembership(service, userId);
  if (!membership) throw new Error("No provider workspace found");
  const activeWorkspaceId = compactString((membership.provider_workspaces as Record<string, unknown> | undefined)?.id);
  if (activeWorkspaceId !== workspaceId) throw new Error("Workspace access denied");
  return membership;
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
      "id, company_name, is_listed_in_directory, service_state, service_city, service_zip_codes, categories, display_blurb, headshot_url, aggregate_rating, review_count",
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
  const scheduledDate = localDateString(compactString(body.scheduledDate) || undefined) || localDateString();
  const requestType = compactString(body.requestType) || "standard_visit";
  if (!["standard_visit", "quote", "repair", "install", "assembly", "question", "setup"].includes(requestType)) {
    throw new Error("Invalid visit type");
  }

  const { data: property, error: propertyError } = await service
    .from("properties")
    .select("id, household_id, name, street, city, state, zip_code, property_type, square_feet, year_built")
    .eq("id", propertyId)
    .limit(1)
    .maybeSingle();

  if (propertyError) throw propertyError;
  if (!property) throw new Error("Home not found");

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
    shareText: `Download Chez and use pairing code ${accessCode} to connect ${homeName} with ${companyName}. If you already have Chez, ask support to add this handyman using the code ${accessCode}.`,
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
    .map((item) => ({
      id: compactString(item.id) || crypto.randomUUID(),
      name: compactString(item.name),
      description: compactString(item.description),
      unit: compactString(item.unit) || "ea",
      quantity: numberValue(item.quantity || 1),
      unit_price: numberValue(item.unitPrice || item.unit_price || 0),
    }))
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
  title = title || (recipientKind === "prospect" && prospectName ? `Quote for ${prospectName}` : "Handyman quote");

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

  const payload: Record<string, unknown> = {
    request_id: requestId,
    household_id: request.household_id,
    sender_role: "vendor",
    body: messageBody,
    metadata: {
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
      const dashboard = await loadDashboard(service, user as unknown as Record<string, unknown>);
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

      if (action === "create_ad_hoc_visit") {
        const result = await createAdHocVisit(service, user as unknown as Record<string, unknown>, body);
        return json(result);
      }

      if (action === "create_pairing_request") {
        const result = await createPairingRequest(service, user as unknown as Record<string, unknown>, body);
        return json(result);
      }

      if (action === "link_invite") {
        const membership = await getWorkspaceMembership(service, compactString(user.id));
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
      message = [msg, details, hint, code ? `(${code})` : ""].filter(Boolean).join(" — ") || "Internal error";
    }
    return json({ error: message }, 500);
  }
});

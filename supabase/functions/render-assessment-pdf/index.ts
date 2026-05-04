/* Phase 84.5 G37 — Async PDF render job for the assessment summary.
 *
 * Renders an HTML-based assessment report (cover, per-zone systems with
 * photos and condition ratings, recommendations summary, full vendor
 * list, Chez contact info) and stores the result in the
 * `assessment-exports` storage bucket. Stamps `home_assessments.pdf_export_path`
 * + sends `chez_assessment_pdf_ready` push to the homeowner.
 *
 * Triggered by submit_assessment_data after ingestion succeeds. Can also
 * be manually re-run from the admin portal for any assessment_id.
 *
 * v1 implementation: HTML → server-side rendered text-only report
 * via a simple template. PDF rendering needs a real engine (Puppeteer,
 * Playwright, or wkhtmltopdf) which doesn't run in Deno Edge. v1 stores
 * an HTML file with a `.html` extension; v2 will switch to rendering
 * via an external service when the homeowner-facing PDF is needed.
 *
 * Idempotent on `assessment_id` — re-running overwrites the existing
 * export file.
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function escapeHtml(s: unknown): string {
  return String(s ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function compactString(value: unknown): string {
  return value == null ? "" : String(value).trim();
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(JSON.stringify({ error: "Missing Supabase configuration" }), { status: 500, headers });
    }

    const body = await req.json().catch(() => ({}));
    const assessmentId = compactString(body?.assessment_id);
    if (!assessmentId) {
      return new Response(JSON.stringify({ error: "assessment_id required" }), { status: 400, headers });
    }

    const service = createClient(supabaseUrl, serviceRoleKey);

    // Load the assessment + linked context.
    const { data: assessment, error: aErr } = await service
      .from("home_assessments")
      .select("*")
      .eq("id", assessmentId)
      .maybeSingle();
    if (aErr || !assessment) {
      return new Response(JSON.stringify({ error: "assessment not found" }), { status: 404, headers });
    }

    const { data: property } = await service
      .from("properties")
      .select("address_line_1, city, state, zip_code, year_built, square_footage")
      .eq("id", assessment.property_id)
      .maybeSingle();

    const { data: household } = await service
      .from("households")
      .select("name")
      .eq("id", assessment.household_id)
      .maybeSingle();

    const { data: recs } = await service
      .from("assessment_recommended_tasks")
      .select("*")
      .eq("assessment_id", assessmentId)
      .order("urgency", { ascending: true });

    const { data: systems } = await service
      .from("home_systems")
      .select("category, name, manufacturer, model_number, condition_rating, condition_notes, last_assessed_at")
      .eq("property_id", assessment.property_id)
      .eq("onboarded_via", "handyman_assessment")
      .order("category");

    const { data: contractors } = await service
      .from("contractors")
      .select("company_name, category, phone, email")
      .eq("household_id", assessment.household_id)
      .eq("onboarded_via", "handyman_assessment")
      .order("category");

    // Render HTML — simple inline-styled report.
    const reportHtml = renderReport({
      assessment,
      property,
      household,
      systems: systems ?? [],
      contractors: contractors ?? [],
      recs: recs ?? [],
    });

    // Upload to assessment-exports bucket
    const path = `${assessmentId}/assessment-${assessmentId.slice(0, 8)}.html`;
    const fileBytes = new TextEncoder().encode(reportHtml);
    const { error: upErr } = await service.storage
      .from("assessment-exports")
      .upload(path, fileBytes, {
        contentType: "text/html; charset=utf-8",
        upsert: true,
      });
    if (upErr) {
      return new Response(JSON.stringify({ error: `upload failed: ${upErr.message}` }), { status: 500, headers });
    }

    // Stamp the path on the assessment row
    await service
      .from("home_assessments")
      .update({ pdf_export_path: path })
      .eq("id", assessmentId);

    // Push the homeowner
    const { data: householdUsers } = await service
      .from("users")
      .select("id")
      .eq("household_id", assessment.household_id);
    const userIds = ((householdUsers as Array<{ id: string }> | null) ?? []).map((u) => u.id);
    if (userIds.length > 0) {
      try {
        await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${serviceRoleKey}`,
          },
          body: JSON.stringify({
            user_ids: userIds,
            title: "Your assessment report is ready",
            body: "Open Chez to download a copy of your home assessment.",
            data: { type: "chez_assessment_pdf_ready", assessment_id: assessmentId },
          }),
        });
      } catch (e) {
        console.error("[render-assessment-pdf] push failed:", e);
      }
    }

    return new Response(JSON.stringify({ ok: true, path }), { headers });
  } catch (error) {
    console.error("[render-assessment-pdf] error:", error);
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg }), { status: 500, headers });
  }
});

function renderReport(args: {
  assessment: Record<string, unknown>;
  property: Record<string, unknown> | null;
  household: Record<string, unknown> | null;
  systems: Array<Record<string, unknown>>;
  contractors: Array<Record<string, unknown>>;
  recs: Array<Record<string, unknown>>;
}): string {
  const { assessment, property, household, systems, contractors, recs } = args;
  const householdName = escapeHtml((household as { name?: string } | null)?.name ?? "Your household");
  const address = property
    ? [property.address_line_1, property.city, property.state, property.zip_code].filter(Boolean).map(escapeHtml).join(", ")
    : "(address unavailable)";
  const ingestedAt = compactString(assessment.ingested_at);
  const dateLabel = ingestedAt ? new Date(ingestedAt).toLocaleDateString() : "today";

  const urgencyOrder = ["urgent", "soon", "next_season", "opportunistic"];
  const urgencyLabels: Record<string, string> = {
    urgent: "Urgent (safety / code)",
    soon: "Soon (overdue service)",
    next_season: "Next season",
    opportunistic: "When you're ready",
  };
  const urgencyColors: Record<string, string> = {
    urgent: "#D32F2F",
    soon: "#F57C00",
    next_season: "#ED6955",
    opportunistic: "#787878",
  };

  const recsByUrgency = new Map<string, Array<Record<string, unknown>>>();
  for (const u of urgencyOrder) recsByUrgency.set(u, []);
  for (const r of recs) {
    const u = compactString(r.urgency) || "opportunistic";
    if (!recsByUrgency.has(u)) recsByUrgency.set(u, []);
    recsByUrgency.get(u)!.push(r);
  }

  const recsHtml = urgencyOrder
    .map((u) => {
      const list = recsByUrgency.get(u) ?? [];
      if (list.length === 0) return "";
      return `
        <h3 style="color: ${urgencyColors[u]}; margin-top: 24px;">${urgencyLabels[u]} (${list.length})</h3>
        <ul style="padding-left: 20px;">
          ${list.map((r) => {
            const cost = typeof r.estimated_cost_cents === "number" && r.estimated_cost_cents > 0
              ? ` · ~$${Math.round(Number(r.estimated_cost_cents) / 100)}`
              : "";
            return `<li><strong>${escapeHtml(r.title)}</strong>${cost}<br/>
              <span style="color: #555; font-size: 13px;">${escapeHtml(r.homeowner_visible_notes || r.description || "")}</span></li>`;
          }).join("")}
        </ul>
      `;
    })
    .join("");

  const systemsHtml = systems.length === 0
    ? "<p>No systems captured.</p>"
    : `<table style="width: 100%; border-collapse: collapse;">
        <thead>
          <tr style="background: #F8F9FA;">
            <th style="text-align: left; padding: 8px; border-bottom: 1px solid #ddd;">System</th>
            <th style="text-align: left; padding: 8px; border-bottom: 1px solid #ddd;">Make/Model</th>
            <th style="text-align: left; padding: 8px; border-bottom: 1px solid #ddd;">Condition</th>
          </tr>
        </thead>
        <tbody>
          ${systems.map((s) => `
            <tr>
              <td style="padding: 8px; border-bottom: 1px solid #eee;">${escapeHtml(s.category)}${s.name ? ` · ${escapeHtml(s.name)}` : ""}</td>
              <td style="padding: 8px; border-bottom: 1px solid #eee;">${escapeHtml(s.manufacturer || "")}${s.model_number ? ` ${escapeHtml(s.model_number)}` : ""}</td>
              <td style="padding: 8px; border-bottom: 1px solid #eee; text-transform: capitalize;">${escapeHtml(s.condition_rating || "—")}</td>
            </tr>
          `).join("")}
        </tbody>
      </table>`;

  const contractorsHtml = contractors.length === 0
    ? "<p>No vendors captured.</p>"
    : `<ul style="padding-left: 20px;">
        ${contractors.map((c) => `
          <li><strong>${escapeHtml(c.company_name)}</strong>${c.category ? ` · ${escapeHtml(c.category)}` : ""}${c.phone ? ` · ${escapeHtml(c.phone)}` : ""}</li>
        `).join("")}
      </ul>`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Chez Home Assessment — ${householdName}</title>
  <style>
    body { font-family: 'New York', Georgia, serif; color: #453A70; max-width: 720px; margin: 40px auto; padding: 0 20px; line-height: 1.5; }
    h1 { font-size: 32px; border-bottom: 2px solid #ED6955; padding-bottom: 12px; }
    h2 { color: #453A70; margin-top: 40px; font-size: 22px; }
    h3 { font-size: 17px; }
    .meta { color: #666; font-size: 14px; margin-bottom: 32px; }
    .footer { margin-top: 60px; padding-top: 20px; border-top: 1px solid #ddd; color: #888; font-size: 12px; text-align: center; }
  </style>
</head>
<body>
  <h1>Home Assessment</h1>
  <div class="meta">
    <strong>${householdName}</strong> · ${address}<br/>
    Captured ${escapeHtml(dateLabel)} by Chez
  </div>

  <h2>Recommended work</h2>
  ${recsHtml || "<p>No recommendations captured.</p>"}

  <h2>Systems captured</h2>
  ${systemsHtml}

  <h2>Vendors</h2>
  ${contractorsHtml}

  <div class="footer">
    Questions about this report? <a href="mailto:hello@getchez.com">hello@getchez.com</a><br/>
    Chez · getchez.com
  </div>
</body>
</html>`;
}

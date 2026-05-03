// Chez Edge Function: admin-vendor-applications
//
// Phase 72: admin CRUD over vendor_applications. Authenticated via the
// caller's Supabase JWT — the function checks `auth.users.email` against
// the ADMIN_EMAILS allowlist below. The website admin portal already uses
// the same allowlist pattern (`ADMIN_EMAIL = "tom@getchez.com"` in admin.js).
//
// Actions:
//   - list:           list applications with optional status filter + pagination
//   - get:            single application by id
//   - mark_certified: flip status to chez_certified, send "you're certified" email
//   - mark_rejected:  flip status to rejected, no email (silent rejection per spec)
//   - resend_confirm: re-fire the magic-link email (admin escape hatch)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ADMIN_EMAILS = new Set<string>([
    "tom@getchez.com",
    // Add other admin emails here as the team grows
]);

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface AdminRequest {
    action?: "list" | "get" | "mark_certified" | "mark_rejected" | "resend_confirm";
    application_id?: string;
    status_filter?: string;
    limit?: number;
    offset?: number;
    notes?: string;
}

serve(async (req: Request) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }
    const headers = { ...corsHeaders, "Content-Type": "application/json" };

    if (req.method !== "POST") {
        return new Response(
            JSON.stringify({ error: "Method not allowed" }),
            { status: 405, headers },
        );
    }

    try {
        const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
        const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
        const sendgridKey = Deno.env.get("SENDGRID_API_KEY") ?? "";

        if (!supabaseUrl || !serviceRoleKey) {
            return new Response(
                JSON.stringify({ error: "Server misconfigured" }),
                { status: 500, headers },
            );
        }

        // ----- Auth: extract user from Supabase JWT in Authorization header -----
        const authHeader = req.headers.get("Authorization") ?? "";
        const jwt = authHeader.replace(/^Bearer\s+/i, "").trim();
        if (!jwt) {
            return new Response(
                JSON.stringify({ error: "Missing Authorization header" }),
                { status: 401, headers },
            );
        }

        const supabaseAuth = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
            global: { headers: { Authorization: `Bearer ${jwt}` } },
        });
        const { data: userResp, error: userErr } = await supabaseAuth.auth.getUser(jwt);
        const userEmail = userResp?.user?.email?.toLowerCase() ?? "";
        if (userErr || !userEmail || !ADMIN_EMAILS.has(userEmail)) {
            console.warn(`[admin-vendor-applications] Unauthorized: email=${userEmail}`);
            return new Response(
                JSON.stringify({ error: "Forbidden" }),
                { status: 403, headers },
            );
        }
        const userId = userResp!.user!.id;

        // ----- Service-role client for actual data ops -----
        const supabase = createClient(supabaseUrl, serviceRoleKey);

        let body: AdminRequest;
        try {
            body = await req.json();
        } catch {
            return new Response(
                JSON.stringify({ error: "Invalid JSON body" }),
                { status: 400, headers },
            );
        }

        switch (body.action) {
            // -------------------------------------------------------------
            case "list": {
                const limit = Math.min(Math.max(body.limit ?? 50, 1), 200);
                const offset = Math.max(body.offset ?? 0, 0);
                // Phase 72.5: include profile_completion_pct so the admin
                // desk can show a per-row pill + sort the queue by it.
                // PostgREST exposes the row-typed function as a computed
                // column on this table.
                let query = supabase
                    .from("vendor_applications")
                    .select(
                        "id, business_name, contact_name, email, phone, website, category, " +
                        "service_area_states, status, email_confirmed_at, verified_at, " +
                        "verified_notes, rejected_at, rejection_notes, linked_google_place_id, " +
                        "created_at, profile_completion_pct",
                        { count: "exact" },
                    )
                    .order("created_at", { ascending: false })
                    .range(offset, offset + limit - 1);

                if (body.status_filter) {
                    query = query.eq("status", body.status_filter);
                }

                const { data, count, error } = await query;
                if (error) {
                    console.error("[admin-vendor-applications] List error:", error);
                    return new Response(
                        JSON.stringify({ error: "List failed" }),
                        { status: 500, headers },
                    );
                }
                return new Response(
                    JSON.stringify({ applications: data ?? [], total: count ?? 0 }),
                    { status: 200, headers },
                );
            }

            // -------------------------------------------------------------
            case "get": {
                if (!body.application_id) {
                    return new Response(
                        JSON.stringify({ error: "application_id required" }),
                        { status: 400, headers },
                    );
                }
                const { data, error } = await supabase
                    .from("vendor_applications")
                    .select("*")
                    .eq("id", body.application_id)
                    .maybeSingle();
                if (error || !data) {
                    return new Response(
                        JSON.stringify({ error: "Application not found" }),
                        { status: 404, headers },
                    );
                }
                return new Response(
                    JSON.stringify({ application: data }),
                    { status: 200, headers },
                );
            }

            // -------------------------------------------------------------
            case "mark_certified": {
                if (!body.application_id) {
                    return new Response(
                        JSON.stringify({ error: "application_id required" }),
                        { status: 400, headers },
                    );
                }

                const { data: existing, error: lookupErr } = await supabase
                    .from("vendor_applications")
                    .select("id, business_name, contact_name, email, status")
                    .eq("id", body.application_id)
                    .maybeSingle();
                if (lookupErr || !existing) {
                    return new Response(
                        JSON.stringify({ error: "Application not found" }),
                        { status: 404, headers },
                    );
                }

                if (existing.status === "rejected") {
                    return new Response(
                        JSON.stringify({ error: "Cannot certify a rejected application" }),
                        { status: 409, headers },
                    );
                }

                const { error: updateErr } = await supabase
                    .from("vendor_applications")
                    .update({
                        status: "chez_certified",
                        verified_at: new Date().toISOString(),
                        verified_by: userId,
                        verified_notes: body.notes ?? null,
                    })
                    .eq("id", body.application_id);

                if (updateErr) {
                    console.error("[admin-vendor-applications] Certify error:", updateErr);
                    return new Response(
                        JSON.stringify({ error: "Could not certify" }),
                        { status: 500, headers },
                    );
                }

                // Fire-and-forget "you're certified" email
                if (sendgridKey) {
                    const emailBody = {
                        personalizations: [{ to: [{ email: existing.email, name: existing.contact_name }] }],
                        from: { email: "hello@getchez.com", name: "Chez" },
                        reply_to: { email: "tom@getchez.com" },
                        subject: `${existing.business_name} is now Chez Certified`,
                        content: [
                            {
                                type: "text/plain",
                                value: [
                                    `Hi ${existing.contact_name},`,
                                    "",
                                    `${existing.business_name} is now Chez Certified.`,
                                    "",
                                    "You'll appear at the top of find-vendor results for households in your service area, with the Chez Certified badge alongside your listing.",
                                    "",
                                    "Households on Chez are vetted high-net-worth families looking for trusted local pros. We'll continue to send your listing to relevant matches.",
                                    "",
                                    "If anything about your business changes (phone, service area, etc.), you can update your listing yourself at:",
                                    "https://getchez.com/vendor-portal.html",
                                    "(Sign in with this same email — we'll send you a magic link, no password needed.)",
                                    "",
                                    "— The Chez team",
                                    "getchez.com",
                                ].join("\n"),
                            },
                        ],
                    };
                    fetch("https://api.sendgrid.com/v3/mail/send", {
                        method: "POST",
                        headers: {
                            Authorization: `Bearer ${sendgridKey}`,
                            "Content-Type": "application/json",
                        },
                        body: JSON.stringify(emailBody),
                    }).catch((e) => {
                        console.error("[admin-vendor-applications] Certify email error:", e);
                    });
                }

                return new Response(
                    JSON.stringify({ success: true, status: "chez_certified" }),
                    { status: 200, headers },
                );
            }

            // -------------------------------------------------------------
            case "mark_rejected": {
                if (!body.application_id) {
                    return new Response(
                        JSON.stringify({ error: "application_id required" }),
                        { status: 400, headers },
                    );
                }
                const { error: updateErr } = await supabase
                    .from("vendor_applications")
                    .update({
                        status: "rejected",
                        rejected_at: new Date().toISOString(),
                        rejected_by: userId,
                        rejection_notes: body.notes ?? null,
                    })
                    .eq("id", body.application_id);
                if (updateErr) {
                    console.error("[admin-vendor-applications] Reject error:", updateErr);
                    return new Response(
                        JSON.stringify({ error: "Could not reject" }),
                        { status: 500, headers },
                    );
                }
                // Silent rejection per spec — no email
                return new Response(
                    JSON.stringify({ success: true, status: "rejected" }),
                    { status: 200, headers },
                );
            }

            // -------------------------------------------------------------
            case "resend_confirm": {
                if (!body.application_id) {
                    return new Response(
                        JSON.stringify({ error: "application_id required" }),
                        { status: 400, headers },
                    );
                }
                const { data: app, error: lookupErr } = await supabase
                    .from("vendor_applications")
                    .select("email, contact_name, business_name, email_confirm_token, status, service_area_states")
                    .eq("id", body.application_id)
                    .maybeSingle();
                if (lookupErr || !app) {
                    return new Response(
                        JSON.stringify({ error: "Application not found" }),
                        { status: 404, headers },
                    );
                }
                if (app.status !== "pending_email_confirm") {
                    return new Response(
                        JSON.stringify({ error: "Application already confirmed" }),
                        { status: 409, headers },
                    );
                }

                // Refresh token + sent_at so the new link gets a fresh TTL
                const { error: updateErr, data: updated } = await supabase
                    .from("vendor_applications")
                    .update({
                        email_confirm_token: crypto.randomUUID(),
                        email_confirm_sent_at: new Date().toISOString(),
                    })
                    .eq("id", body.application_id)
                    .select("email_confirm_token")
                    .single();

                if (updateErr || !updated) {
                    return new Response(
                        JSON.stringify({ error: "Could not refresh token" }),
                        { status: 500, headers },
                    );
                }

                if (sendgridKey) {
                    const confirmUrl =
                        `https://getchez.com/vendor-confirm.html?token=${updated.email_confirm_token}`;
                    fetch("https://api.sendgrid.com/v3/mail/send", {
                        method: "POST",
                        headers: {
                            Authorization: `Bearer ${sendgridKey}`,
                            "Content-Type": "application/json",
                        },
                        body: JSON.stringify({
                            personalizations: [{ to: [{ email: app.email, name: app.contact_name }] }],
                            from: { email: "hello@getchez.com", name: "Chez" },
                            reply_to: { email: "tom@getchez.com" },
                            subject: `Confirm your Chez vendor listing for ${app.business_name}`,
                            content: [
                                {
                                    type: "text/plain",
                                    value: [
                                        `Hi ${app.contact_name},`,
                                        "",
                                        `Click the link below to confirm your email for ${app.business_name}:`,
                                        "",
                                        confirmUrl,
                                        "",
                                        "— The Chez team",
                                    ].join("\n"),
                                },
                            ],
                        }),
                    }).catch((e) => {
                        console.error("[admin-vendor-applications] Resend email error:", e);
                    });
                }

                return new Response(
                    JSON.stringify({ success: true }),
                    { status: 200, headers },
                );
            }

            // -------------------------------------------------------------
            default:
                return new Response(
                    JSON.stringify({ error: "Unknown action" }),
                    { status: 400, headers },
                );
        }
    } catch (error) {
        console.error("[admin-vendor-applications] Unhandled error:", error);
        return new Response(
            JSON.stringify({ error: "Internal server error" }),
            { status: 500, headers },
        );
    }
});

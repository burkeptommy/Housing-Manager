// Chez Edge Function: vendor-self-service
//
// Phase 72 / gap 21: lets a vendor update or remove their own listing
// without going through the admin. Authenticated by Supabase magic-link
// auth (signInWithOtp on the vendor's submission email). The function
// matches the calling user's email against vendor_applications.email
// to authorize each operation — no admin role required, no per-row RLS
// changes, no separate vendor user table.
//
// Actions:
//   - get_my_listing       — return the vendor's own application row
//   - update_my_listing    — edit business_name, contact_name, phone,
//                            website, service_area_states (NOT category;
//                            that stays admin-controlled to prevent vendors
//                            shifting trades after certification)
//   - remove_my_listing    — soft-delete by setting status='rejected'
//                            with rejection_notes='self-removed'
//
// Behaviour:
//   - If the caller's email matches no application: 404
//   - If the application is rejected: most actions return 410 (gone),
//     except they can still see their old data via get_my_listing
//   - If the caller updates fields, status stays the same — they don't
//     need to re-confirm via magic link

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const VALID_US_STATES = new Set<string>([
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA",
    "KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
    "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT",
    "VA","WA","WV","WI","WY","DC",
]);

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface SelfServiceRequest {
    action?: "get_my_listing" | "update_my_listing" | "remove_my_listing";
    business_name?: string;
    contact_name?: string;
    phone?: string;
    website?: string | null;
    service_area_states?: string[];
}

function trimOrNull(s: string | null | undefined, max: number): string | null {
    if (!s) return null;
    const t = s.trim();
    if (!t) return null;
    return t.length > max ? t.slice(0, max) : t;
}

function normalizeWebsite(raw: string | null): string | null {
    if (!raw) return null;
    let url = raw.trim();
    if (!url) return null;
    if (!/^https?:\/\//i.test(url)) {
        url = `https://${url}`;
    }
    try {
        return new URL(url).toString();
    } catch {
        return null;
    }
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
        const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
        if (!supabaseUrl || !serviceRoleKey) {
            return new Response(
                JSON.stringify({ error: "Server misconfigured" }),
                { status: 500, headers },
            );
        }

        // ----- Auth: extract user from caller's JWT -----
        const authHeader = req.headers.get("Authorization") ?? "";
        const jwt = authHeader.replace(/^Bearer\s+/i, "").trim();
        if (!jwt) {
            return new Response(
                JSON.stringify({ error: "Missing Authorization header" }),
                { status: 401, headers },
            );
        }

        const supabaseAuth = createClient(supabaseUrl, anonKey, {
            global: { headers: { Authorization: `Bearer ${jwt}` } },
        });
        const { data: userResp, error: userErr } = await supabaseAuth.auth.getUser(jwt);
        const userEmail = userResp?.user?.email?.toLowerCase() ?? "";
        if (userErr || !userEmail) {
            return new Response(
                JSON.stringify({ error: "Invalid or expired session" }),
                { status: 401, headers },
            );
        }

        // ----- Service-role client for the actual data ops -----
        const supabase = createClient(supabaseUrl, serviceRoleKey);

        // Look up the application by the caller's email. Single active
        // application per email is enforced by the unique partial index, so
        // we only need to grab one row. Rejected rows still load so the
        // vendor sees their old data, but mutations are gated on status.
        const { data: app, error: lookupErr } = await supabase
            .from("vendor_applications")
            .select("*")
            .ilike("email", userEmail)
            .order("created_at", { ascending: false })
            .limit(1)
            .maybeSingle();

        if (lookupErr) {
            console.error("[vendor-self-service] lookup error:", lookupErr);
            return new Response(
                JSON.stringify({ error: "Could not look up your application" }),
                { status: 500, headers },
            );
        }

        if (!app) {
            return new Response(
                JSON.stringify({ error: "No vendor application found for this email" }),
                { status: 404, headers },
            );
        }

        let body: SelfServiceRequest;
        try {
            body = await req.json();
        } catch {
            return new Response(
                JSON.stringify({ error: "Invalid JSON body" }),
                { status: 400, headers },
            );
        }

        switch (body.action) {
            case "get_my_listing":
                return new Response(
                    JSON.stringify({ application: app }),
                    { status: 200, headers },
                );

            case "update_my_listing": {
                if (app.status === "rejected") {
                    return new Response(
                        JSON.stringify({
                            error: "This listing has been removed and cannot be edited. Re-apply at getchez.com/vendor-apply.html.",
                        }),
                        { status: 410, headers },
                    );
                }

                // Collect editable fields. Each is optional — only fields
                // present in the body are updated. Validation matches the
                // submit function: phones >= 7 digits, states must be valid
                // US codes, etc.
                const update: Record<string, unknown> = {};

                const businessName = trimOrNull(body.business_name, 200);
                if (body.business_name !== undefined) {
                    if (!businessName) {
                        return new Response(
                            JSON.stringify({ error: "business_name cannot be empty" }),
                            { status: 400, headers },
                        );
                    }
                    update.business_name = businessName;
                }

                const contactName = trimOrNull(body.contact_name, 100);
                if (body.contact_name !== undefined) {
                    if (!contactName) {
                        return new Response(
                            JSON.stringify({ error: "contact_name cannot be empty" }),
                            { status: 400, headers },
                        );
                    }
                    update.contact_name = contactName;
                }

                const phone = trimOrNull(body.phone, 30);
                if (body.phone !== undefined) {
                    const digits = (phone ?? "").replace(/\D/g, "");
                    if (digits.length < 7) {
                        return new Response(
                            JSON.stringify({ error: "phone must have at least 7 digits" }),
                            { status: 400, headers },
                        );
                    }
                    update.phone = phone;
                }

                if (body.website !== undefined) {
                    update.website = normalizeWebsite(body.website ? String(body.website) : null);
                }

                if (body.service_area_states !== undefined) {
                    const states = (body.service_area_states ?? [])
                        .map((s) => (typeof s === "string" ? s.trim().toUpperCase() : ""))
                        .filter((s) => VALID_US_STATES.has(s));
                    if (states.length === 0) {
                        return new Response(
                            JSON.stringify({ error: "service_area_states must contain at least one valid US state" }),
                            { status: 400, headers },
                        );
                    }
                    update.service_area_states = states;
                }

                if (Object.keys(update).length === 0) {
                    return new Response(
                        JSON.stringify({ error: "No editable fields provided" }),
                        { status: 400, headers },
                    );
                }

                const { data: updated, error: updateErr } = await supabase
                    .from("vendor_applications")
                    .update(update)
                    .eq("id", app.id)
                    .select("*")
                    .single();
                if (updateErr || !updated) {
                    console.error("[vendor-self-service] update error:", updateErr);
                    return new Response(
                        JSON.stringify({ error: "Could not update your listing" }),
                        { status: 500, headers },
                    );
                }
                return new Response(
                    JSON.stringify({ success: true, application: updated }),
                    { status: 200, headers },
                );
            }

            case "remove_my_listing": {
                if (app.status === "rejected") {
                    return new Response(
                        JSON.stringify({ success: true, already_removed: true }),
                        { status: 200, headers },
                    );
                }
                const { error: removeErr } = await supabase
                    .from("vendor_applications")
                    .update({
                        status: "rejected",
                        rejected_at: new Date().toISOString(),
                        rejection_notes: "self-removed by vendor",
                    })
                    .eq("id", app.id);
                if (removeErr) {
                    console.error("[vendor-self-service] remove error:", removeErr);
                    return new Response(
                        JSON.stringify({ error: "Could not remove your listing" }),
                        { status: 500, headers },
                    );
                }
                return new Response(
                    JSON.stringify({ success: true }),
                    { status: 200, headers },
                );
            }

            default:
                return new Response(
                    JSON.stringify({ error: "Unknown action" }),
                    { status: 400, headers },
                );
        }
    } catch (error) {
        console.error("[vendor-self-service] Unhandled error:", error);
        return new Response(
            JSON.stringify({ error: "Internal server error" }),
            { status: 500, headers },
        );
    }
});

// Chez Edge Function: vendor-self-service
//
// Phase 72 / 72.5: lets a vendor update or remove their own listing
// without going through the admin. Authenticated by Supabase magic-link
// auth (signInWithOtp on the vendor's submission email). The function
// matches the calling user's email against vendor_applications.email
// to authorize each operation — no admin role required, no per-row RLS
// changes, no separate vendor user table.
//
// Actions:
//   - get_my_listing       — return the vendor's row + profile_completion_pct
//   - update_my_listing    — edit ANY field except email / category / status
//                            and the admin-managed verification timestamps
//   - accept_terms         — stamp accepted_terms_at = now()
//   - remove_my_listing    — soft-delete by setting status='rejected' with
//                            rejection_notes='self-removed'
//
// Phase 72.5 fields added: logo_url, brand_color, description, about,
// years_in_business, photo_urls, license_number, license_state,
// insurance_carrier, insurance_policy_number, insurance_expiry,
// insurance_coverage_cents, coi_document_url, service_area_towns,
// service_radius_miles, hours_json, emergency_available, lead_email,
// lead_phone, notify_on_lead.
//
// What stays admin-controlled:
//   - category               (vendors can't shift trades after certification)
//   - status                 (admin-only: certify / reject)
//   - license_verified_at    (admin-only: only Tom flips after license check)
//   - coi_verified_at        (admin-only: only Tom flips after COI review)

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
    action?:
        | "get_my_listing"
        | "update_my_listing"
        | "accept_terms"
        | "remove_my_listing";
    // Phase 72 base fields
    business_name?: string;
    contact_name?: string;
    phone?: string;
    website?: string | null;
    service_area_states?: string[];
    // Phase 72.5 — profile basics
    logo_url?: string | null;
    brand_color?: string | null;
    description?: string | null;
    about?: string | null;
    years_in_business?: number | null;
    photo_urls?: string[];
    // Phase 72.5 — trust + credentials
    license_number?: string | null;
    license_state?: string | null;
    insurance_carrier?: string | null;
    insurance_policy_number?: string | null;
    insurance_expiry?: string | null; // YYYY-MM-DD
    insurance_coverage_cents?: number | null;
    coi_document_url?: string | null;
    // Phase 72.5 — service area + ops + lead routing
    service_area_towns?: string[];
    service_radius_miles?: number | null;
    hours_json?: Record<string, unknown> | null;
    emergency_available?: boolean;
    lead_email?: string | null;
    lead_phone?: string | null;
    notify_on_lead?: boolean;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function trimOrNull(s: string | null | undefined, max: number): string | null {
    if (s === null || s === undefined) return null;
    const t = String(s).trim();
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

function isValidEmail(s: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s) && s.length <= 255;
}

function isValidIsoDate(s: string): boolean {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
    const d = new Date(s + "T00:00:00Z");
    return !Number.isNaN(d.getTime());
}

function clampInt(
    n: unknown,
    min: number,
    max: number,
): { ok: true; value: number } | { ok: false; reason: string } {
    if (typeof n !== "number" || !Number.isFinite(n) || !Number.isInteger(n)) {
        return { ok: false, reason: "must be an integer" };
    }
    if (n < min || n > max) {
        return { ok: false, reason: `must be between ${min} and ${max}` };
    }
    return { ok: true, value: n };
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

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

        // ---- Helper: fetch the latest row + completion pct in one shot ----
        // profile_completion_pct(vendor_applications) is exposed by PostgREST
        // as a computed column on this table — selecting it inline returns
        // the value alongside the row.
        const fetchWithCompletion = async (id: string) => {
            const { data, error } = await supabase
                .from("vendor_applications")
                .select("*, profile_completion_pct")
                .eq("id", id)
                .maybeSingle();
            if (error) {
                console.error("[vendor-self-service] fetchWithCompletion error:", error);
            }
            const row = (data ?? null) as Record<string, unknown> | null;
            const pct = row && typeof row.profile_completion_pct === "number"
                ? (row.profile_completion_pct as number)
                : null;
            return { application: row, profile_completion_pct: pct };
        };

        switch (body.action) {
            // ============================================================
            case "get_my_listing": {
                const out = await fetchWithCompletion(app.id);
                return new Response(JSON.stringify(out), { status: 200, headers });
            }

            // ============================================================
            case "accept_terms": {
                if (app.status === "rejected") {
                    return new Response(
                        JSON.stringify({ error: "This listing has been removed." }),
                        { status: 410, headers },
                    );
                }
                if (app.accepted_terms_at) {
                    const out = await fetchWithCompletion(app.id);
                    return new Response(
                        JSON.stringify({ success: true, already_accepted: true, ...out }),
                        { status: 200, headers },
                    );
                }
                const { error: termsErr } = await supabase
                    .from("vendor_applications")
                    .update({ accepted_terms_at: new Date().toISOString() })
                    .eq("id", app.id);
                if (termsErr) {
                    console.error("[vendor-self-service] accept_terms error:", termsErr);
                    return new Response(
                        JSON.stringify({ error: "Could not record terms acceptance" }),
                        { status: 500, headers },
                    );
                }
                const out = await fetchWithCompletion(app.id);
                return new Response(
                    JSON.stringify({ success: true, ...out }),
                    { status: 200, headers },
                );
            }

            // ============================================================
            case "update_my_listing": {
                if (app.status === "rejected") {
                    return new Response(
                        JSON.stringify({
                            error: "This listing has been removed and cannot be edited. Re-apply at getchez.com/vendor-apply.html.",
                        }),
                        { status: 410, headers },
                    );
                }

                // Each field is optional. Only present fields update — `undefined`
                // is "leave alone", explicit `null` is "clear it".
                const update: Record<string, unknown> = {};
                const errors: string[] = [];

                // ---- base fields (Phase 72) --------------------------
                if (body.business_name !== undefined) {
                    const v = trimOrNull(body.business_name, 200);
                    if (!v) errors.push("business_name cannot be empty");
                    else update.business_name = v;
                }

                if (body.contact_name !== undefined) {
                    const v = trimOrNull(body.contact_name, 100);
                    if (!v) errors.push("contact_name cannot be empty");
                    else update.contact_name = v;
                }

                if (body.phone !== undefined) {
                    const v = trimOrNull(body.phone, 30);
                    const digits = (v ?? "").replace(/\D/g, "");
                    if (digits.length < 7) errors.push("phone must have at least 7 digits");
                    else update.phone = v;
                }

                if (body.website !== undefined) {
                    update.website = body.website === null ? null
                        : normalizeWebsite(String(body.website));
                }

                if (body.service_area_states !== undefined) {
                    const states = (body.service_area_states ?? [])
                        .map((s) => (typeof s === "string" ? s.trim().toUpperCase() : ""))
                        .filter((s) => VALID_US_STATES.has(s));
                    if (states.length === 0) {
                        errors.push("service_area_states must contain at least one valid US state");
                    } else {
                        update.service_area_states = states;
                    }
                }

                // ---- profile basics ---------------------------------
                if (body.logo_url !== undefined) {
                    update.logo_url = body.logo_url === null
                        ? null
                        : trimOrNull(body.logo_url, 1000);
                }

                if (body.brand_color !== undefined) {
                    if (body.brand_color === null) {
                        update.brand_color = null;
                    } else {
                        const v = String(body.brand_color).trim();
                        if (!/^#[0-9A-Fa-f]{6}$/.test(v)) {
                            errors.push("brand_color must be a 6-digit hex like #ED6955");
                        } else {
                            update.brand_color = v;
                        }
                    }
                }

                if (body.description !== undefined) {
                    if (body.description === null) {
                        update.description = null;
                    } else {
                        const v = trimOrNull(body.description, 200);
                        if (!v) update.description = null;
                        else update.description = v;
                    }
                }

                if (body.about !== undefined) {
                    if (body.about === null) {
                        update.about = null;
                    } else {
                        const v = trimOrNull(body.about, 2000);
                        if (!v) update.about = null;
                        else update.about = v;
                    }
                }

                if (body.years_in_business !== undefined) {
                    if (body.years_in_business === null) {
                        update.years_in_business = null;
                    } else {
                        const r = clampInt(body.years_in_business, 0, 200);
                        if (!r.ok) errors.push(`years_in_business ${r.reason}`);
                        else update.years_in_business = r.value;
                    }
                }

                if (body.photo_urls !== undefined) {
                    if (!Array.isArray(body.photo_urls)) {
                        errors.push("photo_urls must be an array of strings");
                    } else {
                        const urls = body.photo_urls
                            .map((u) => (typeof u === "string" ? u.trim() : ""))
                            .filter((u) => u.length > 0 && u.length <= 1000);
                        update.photo_urls = urls;
                    }
                }

                // ---- trust + credentials ----------------------------
                if (body.license_number !== undefined) {
                    update.license_number = body.license_number === null
                        ? null
                        : trimOrNull(body.license_number, 100);
                }

                if (body.license_state !== undefined) {
                    if (body.license_state === null) {
                        update.license_state = null;
                    } else {
                        const v = String(body.license_state).trim().toUpperCase();
                        if (!VALID_US_STATES.has(v)) {
                            errors.push("license_state must be a valid US state code");
                        } else {
                            update.license_state = v;
                        }
                    }
                }

                if (body.insurance_carrier !== undefined) {
                    update.insurance_carrier = body.insurance_carrier === null
                        ? null
                        : trimOrNull(body.insurance_carrier, 200);
                }

                if (body.insurance_policy_number !== undefined) {
                    update.insurance_policy_number = body.insurance_policy_number === null
                        ? null
                        : trimOrNull(body.insurance_policy_number, 100);
                }

                if (body.insurance_expiry !== undefined) {
                    if (body.insurance_expiry === null || body.insurance_expiry === "") {
                        update.insurance_expiry = null;
                    } else {
                        const v = String(body.insurance_expiry).trim();
                        if (!isValidIsoDate(v)) {
                            errors.push("insurance_expiry must be YYYY-MM-DD");
                        } else {
                            update.insurance_expiry = v;
                        }
                    }
                }

                if (body.insurance_coverage_cents !== undefined) {
                    if (body.insurance_coverage_cents === null) {
                        update.insurance_coverage_cents = null;
                    } else if (typeof body.insurance_coverage_cents !== "number" || body.insurance_coverage_cents < 0) {
                        errors.push("insurance_coverage_cents must be a non-negative number");
                    } else {
                        update.insurance_coverage_cents = Math.floor(body.insurance_coverage_cents);
                    }
                }

                if (body.coi_document_url !== undefined) {
                    update.coi_document_url = body.coi_document_url === null
                        ? null
                        : trimOrNull(body.coi_document_url, 1000);
                    // Re-uploading the COI invalidates any prior verification.
                    if (body.coi_document_url !== app.coi_document_url) {
                        update.coi_verified_at = null;
                    }
                }

                // ---- service area + ops + lead routing --------------
                if (body.service_area_towns !== undefined) {
                    if (!Array.isArray(body.service_area_towns)) {
                        errors.push("service_area_towns must be an array of strings");
                    } else {
                        const towns = body.service_area_towns
                            .map((t) => (typeof t === "string" ? t.trim() : ""))
                            .filter((t) => t.length > 0 && t.length <= 200);
                        update.service_area_towns = towns;
                    }
                }

                if (body.service_radius_miles !== undefined) {
                    if (body.service_radius_miles === null) {
                        update.service_radius_miles = null;
                    } else {
                        const r = clampInt(body.service_radius_miles, 1, 500);
                        if (!r.ok) errors.push(`service_radius_miles ${r.reason}`);
                        else update.service_radius_miles = r.value;
                    }
                }

                if (body.hours_json !== undefined) {
                    if (body.hours_json === null) {
                        update.hours_json = null;
                    } else if (typeof body.hours_json !== "object" || Array.isArray(body.hours_json)) {
                        errors.push("hours_json must be an object keyed by weekday");
                    } else {
                        update.hours_json = body.hours_json;
                    }
                }

                if (body.emergency_available !== undefined) {
                    if (typeof body.emergency_available !== "boolean") {
                        errors.push("emergency_available must be a boolean");
                    } else {
                        update.emergency_available = body.emergency_available;
                    }
                }

                if (body.lead_email !== undefined) {
                    if (body.lead_email === null || body.lead_email === "") {
                        update.lead_email = null;
                    } else {
                        const v = String(body.lead_email).trim().toLowerCase();
                        if (!isValidEmail(v)) errors.push("lead_email must be a valid email");
                        else update.lead_email = v;
                    }
                }

                if (body.lead_phone !== undefined) {
                    if (body.lead_phone === null || body.lead_phone === "") {
                        update.lead_phone = null;
                    } else {
                        const v = trimOrNull(body.lead_phone, 30);
                        const digits = (v ?? "").replace(/\D/g, "");
                        if (digits.length < 7) errors.push("lead_phone must have at least 7 digits");
                        else update.lead_phone = v;
                    }
                }

                if (body.notify_on_lead !== undefined) {
                    if (typeof body.notify_on_lead !== "boolean") {
                        errors.push("notify_on_lead must be a boolean");
                    } else {
                        update.notify_on_lead = body.notify_on_lead;
                    }
                }

                if (errors.length > 0) {
                    return new Response(
                        JSON.stringify({ error: errors.join("; "), code: "invalid_input" }),
                        { status: 400, headers },
                    );
                }

                if (Object.keys(update).length === 0) {
                    return new Response(
                        JSON.stringify({ error: "No editable fields provided" }),
                        { status: 400, headers },
                    );
                }

                const { error: updateErr } = await supabase
                    .from("vendor_applications")
                    .update(update)
                    .eq("id", app.id);
                if (updateErr) {
                    console.error("[vendor-self-service] update error:", updateErr);
                    return new Response(
                        JSON.stringify({ error: "Could not update your listing" }),
                        { status: 500, headers },
                    );
                }
                const out = await fetchWithCompletion(app.id);
                return new Response(
                    JSON.stringify({ success: true, ...out }),
                    { status: 200, headers },
                );
            }

            // ============================================================
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

            // ============================================================
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

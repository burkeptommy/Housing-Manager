// Chez Edge Function: submit-vendor-application
//
// Phase 72: public-facing vendor self-signup endpoint. Called from the
// getchez.com/vendor-apply.html form (or any future client). Creates a row
// in `vendor_applications` with status='pending_email_confirm' and emails
// the applicant a magic-link confirmation. Click → confirm-vendor-application
// flips status to 'live_unverified'.
//
// Spam controls:
//   - 3 attempts per IP per hour (recorded in vendor_application_attempts)
//   - Email is required; the magic-link gate filters disposable/typo emails
//   - One active (non-rejected) application per email enforced by DB index

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// Canonical categories — server-side validator for the vendor application form.
//
// SOURCE OF TRUTH: website/admin-data/vendor-categories.json
// (the form fetches it on page load to populate the <select>).
//
// MUST also stay in sync with `Haven/Features/Property/Services/SystemCategoryRegistry.swift`
// (the iOS app's category model — different shape, includes tier metadata).
//
// Adding/renaming a category requires updating ALL THREE: this Set + the JSON
// file + the Swift registry. The JSON is authoritative for the public form;
// this Set is authoritative for server-side validation; Swift is authoritative
// for in-app system modeling.
// ---------------------------------------------------------------------------
const VALID_CATEGORIES = new Set<string>([
    // Tier 1 universal
    "Roofing", "HVAC", "Plumbing", "Electrical", "Water Heater",
    "Pest Control", "Security System", "Cleaning Service", "Handyman",
    "Trash & Recycling",
    // Tier 2 conditional
    "Landscaping", "Snow Removal", "Gutter Cleaning", "Chimney",
    "Septic System", "Well System", "Generator", "Tree Service",
    "Window Cleaning", "Pet Waste", "Mosquito & Tick", "Air Quality",
    // Specialty
    "Pool/Spa", "Hot Tub", "Deck/Outdoor", "Driveway Sealcoating",
    "Pressure Washing", "Solar", "EV Charger", "Smart Home",
    "Water Treatment", "Boiler", "Radiant Floor", "Painting",
    "Siding/Exterior", "Elevator", "Wine Cellar", "Attic & Foundation",
    // Sub-system
    "Appliance", "Crawl Space", "Garage Door", "Sump Pump",
    "Irrigation", "Fire Protection",
]);

// Phase 72 / gap 19: alias map that canonicalizes common synonyms before
// validation. Defensive — the website form's dropdown already submits
// canonical keys, but direct API consumers (Zapier, partner integrations,
// future vendor self-service portal) might pass these variants.
//
// Lookup is case-insensitive: input is lowercased, then matched against
// keys here, falling through to canonical case-insensitive lookup.
const CATEGORY_ALIASES: Record<string, string> = {
    // HVAC family
    "ac": "HVAC",
    "air conditioning": "HVAC",
    "ac repair": "HVAC",
    "heating": "HVAC",
    "heating and cooling": "HVAC",
    "hvac repair": "HVAC",
    // Landscaping family
    "lawn": "Landscaping",
    "lawn care": "Landscaping",
    "lawn service": "Landscaping",
    "yard service": "Landscaping",
    "yard care": "Landscaping",
    "lawn mowing": "Landscaping",
    "garden": "Landscaping",
    // Pool family
    "pool": "Pool/Spa",
    "pool service": "Pool/Spa",
    "pool maintenance": "Pool/Spa",
    "spa": "Pool/Spa",
    // Plumbing family
    "drain": "Plumbing",
    "drain cleaning": "Plumbing",
    "drain repair": "Plumbing",
    // Tree family
    "tree removal": "Tree Service",
    "arborist": "Tree Service",
    // Pressure washing family
    "power washing": "Pressure Washing",
    "soft washing": "Pressure Washing",
    // Cleaning family
    "house cleaning": "Cleaning Service",
    "maid service": "Cleaning Service",
    "housekeeping": "Cleaning Service",
    // Handyman / carpentry
    "carpenter": "Handyman",
    "carpentry": "Handyman",
    "general contractor": "Handyman",
    "handyperson": "Handyman",
    // Pest family
    "exterminator": "Pest Control",
    "rodent control": "Pest Control",
    // Driveway family
    "asphalt sealing": "Driveway Sealcoating",
    "blacktop sealing": "Driveway Sealcoating",
    // Mosquito family
    "mosquito": "Mosquito & Tick",
    "tick spraying": "Mosquito & Tick",
    "mosquito spraying": "Mosquito & Tick",
};

function canonicalizeCategory(input: string): string | null {
    const trimmed = input.trim();
    if (!trimmed) return null;
    // Direct canonical match (case-insensitive lookup against VALID_CATEGORIES)
    for (const canonical of VALID_CATEGORIES) {
        if (canonical.toLowerCase() === trimmed.toLowerCase()) {
            return canonical;
        }
    }
    // Alias resolution
    const aliased = CATEGORY_ALIASES[trimmed.toLowerCase()];
    if (aliased && VALID_CATEGORIES.has(aliased)) {
        return aliased;
    }
    return null;
}

const VALID_US_STATES = new Set<string>([
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA",
    "KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
    "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT",
    "VA","WA","WV","WI","WY","DC",
]);

const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour
const RATE_LIMIT_MAX_ATTEMPTS = 3;

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface SubmitRequest {
    business_name?: string;
    contact_name?: string;
    email?: string;
    phone?: string;
    website?: string | null;
    category?: string;
    service_area_states?: string[];
}

function trimOrNull(s: string | null | undefined, max: number): string | null {
    if (!s) return null;
    const t = s.trim();
    if (!t) return null;
    return t.length > max ? t.slice(0, max) : t;
}

function isValidEmail(email: string): boolean {
    return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
}

function normalizePhoneDigits(phone: string): string {
    return phone.replace(/\D/g, "");
}

function normalizeWebsite(raw: string | null): string | null {
    if (!raw) return null;
    let url = raw.trim();
    if (!url) return null;
    if (!/^https?:\/\//i.test(url)) {
        url = `https://${url}`;
    }
    try {
        const parsed = new URL(url);
        return parsed.toString();
    } catch {
        return null;
    }
}

function getClientIp(req: Request): string {
    const forwarded = req.headers.get("x-forwarded-for");
    if (forwarded) {
        const first = forwarded.split(",")[0]?.trim();
        if (first) return first;
    }
    return req.headers.get("x-real-ip") ?? "0.0.0.0";
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
            console.error("[submit-vendor-application] Missing supabase env");
            return new Response(
                JSON.stringify({ error: "Server misconfigured" }),
                { status: 500, headers },
            );
        }

        const supabase = createClient(supabaseUrl, serviceRoleKey);
        const ip = getClientIp(req);

        // ----------- Rate limit check (3 per IP per hour) -----------
        const windowStart = new Date(Date.now() - RATE_LIMIT_WINDOW_MS).toISOString();
        const { count: recentCount, error: countErr } = await supabase
            .from("vendor_application_attempts")
            .select("id", { count: "exact", head: true })
            .eq("ip", ip)
            .gte("attempted_at", windowStart);

        if (countErr) {
            console.error("[submit-vendor-application] Rate-limit query error:", countErr);
            // Fail open — don't block legit submissions on a transient query error
        } else if ((recentCount ?? 0) >= RATE_LIMIT_MAX_ATTEMPTS) {
            console.warn(`[submit-vendor-application] Rate limit hit for ip=${ip}`);
            return new Response(
                JSON.stringify({
                    error: "Too many submissions from this IP. Try again in an hour.",
                    code: "rate_limited",
                }),
                { status: 429, headers },
            );
        }

        // ----------- Parse + validate request -----------
        let body: SubmitRequest;
        try {
            body = await req.json();
        } catch {
            return new Response(
                JSON.stringify({ error: "Invalid JSON body" }),
                { status: 400, headers },
            );
        }

        const businessName = trimOrNull(body.business_name, 200);
        const contactName = trimOrNull(body.contact_name, 100);
        const email = trimOrNull(body.email, 255)?.toLowerCase();
        const phone = trimOrNull(body.phone, 30);
        const website = normalizeWebsite(trimOrNull(body.website ?? null, 500));
        // Canonicalize category to handle aliases (e.g. "AC" → "HVAC"). The
        // form sends canonical keys today, but defensive normalization here
        // lets API consumers pass natural-language variants too.
        const rawCategory = trimOrNull(body.category, 100);
        const category = rawCategory ? canonicalizeCategory(rawCategory) : null;
        const states = (body.service_area_states ?? [])
            .map((s) => (typeof s === "string" ? s.trim().toUpperCase() : ""))
            .filter((s) => VALID_US_STATES.has(s));

        const errors: string[] = [];
        if (!businessName) errors.push("business_name is required");
        if (!contactName) errors.push("contact_name is required");
        if (!email || !isValidEmail(email)) errors.push("valid email is required");
        if (!phone || normalizePhoneDigits(phone).length < 7) {
            errors.push("valid phone is required");
        }
        if (!category) {
            errors.push("category must be one of the supported Chez categories");
        }
        if (states.length === 0) {
            errors.push("at least one US service-area state is required");
        }

        if (errors.length > 0) {
            return new Response(
                JSON.stringify({ error: errors.join("; "), code: "invalid_input" }),
                { status: 400, headers },
            );
        }

        // ----------- Record the attempt (rate-limit accounting) -----------
        // Always log even on subsequent failures — gives us visibility into spam
        await supabase.from("vendor_application_attempts").insert({ ip });

        // ----------- Insert application -----------
        const { data: inserted, error: insertErr } = await supabase
            .from("vendor_applications")
            .insert({
                business_name: businessName,
                contact_name: contactName,
                email,
                phone,
                website,
                category,
                service_area_states: states,
                submission_ip: ip,
            })
            .select("id, email_confirm_token")
            .single();

        if (insertErr || !inserted) {
            // Most likely cause: unique constraint on lower(email) — already an
            // active application for this email
            const isDuplicate = (insertErr?.code ?? "") === "23505";
            console.error("[submit-vendor-application] Insert error:", insertErr);
            return new Response(
                JSON.stringify({
                    error: isDuplicate
                        ? "There's already an active application for this email. Check your inbox for the confirmation link."
                        : "Could not save your application. Please try again.",
                    code: isDuplicate ? "duplicate_application" : "insert_failed",
                }),
                { status: isDuplicate ? 409 : 500, headers },
            );
        }

        // ----------- Send magic-link confirmation email -----------
        if (sendgridKey) {
            const confirmUrl =
                `https://getchez.com/vendor-confirm.html?token=${inserted.email_confirm_token}`;
            const sendgridBody = {
                personalizations: [{ to: [{ email, name: contactName }] }],
                from: { email: "hello@getchez.com", name: "Chez" },
                reply_to: { email: "tom@getchez.com" },
                subject: `Confirm your Chez vendor listing for ${businessName}`,
                content: [
                    {
                        type: "text/plain",
                        value: [
                            `Hi ${contactName},`,
                            "",
                            `Thanks for applying to list ${businessName} on Chez.`,
                            "",
                            "Click the link below to confirm your email and go live in our directory:",
                            "",
                            confirmUrl,
                            "",
                            "Once confirmed, your business will appear in find-vendor results for households in:",
                            states.join(", "),
                            "",
                            "We'll reach out by phone over the next few days to verify your business and award the Chez Certified badge.",
                            "",
                            "Once you confirm, you can update your listing anytime at:",
                            "https://getchez.com/vendor-portal.html",
                            "",
                            "Questions? Just reply to this email.",
                            "",
                            "— The Chez team",
                            "getchez.com",
                        ].join("\n"),
                    },
                ],
            };

            const sendgridResp = await fetch(
                "https://api.sendgrid.com/v3/mail/send",
                {
                    method: "POST",
                    headers: {
                        Authorization: `Bearer ${sendgridKey}`,
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify(sendgridBody),
                },
            );

            if (!sendgridResp.ok) {
                const errText = await sendgridResp.text().catch(() => "unknown");
                console.error(
                    `[submit-vendor-application] SendGrid ${sendgridResp.status}: ${errText}`,
                );
                // Don't fail the submit on email failure — the row is in the DB
                // and an admin can manually re-trigger the email if needed
            }
        } else {
            console.warn("[submit-vendor-application] SENDGRID_API_KEY not set; skipping email");
        }

        return new Response(
            JSON.stringify({
                success: true,
                message: "Check your email for a confirmation link.",
                application_id: inserted.id,
            }),
            { status: 201, headers },
        );
    } catch (error) {
        console.error("[submit-vendor-application] Unhandled error:", error);
        return new Response(
            JSON.stringify({ error: "Internal server error" }),
            { status: 500, headers },
        );
    }
});

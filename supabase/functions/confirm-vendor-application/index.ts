// Chez Edge Function: confirm-vendor-application
//
// Phase 72: magic-link target for vendor email confirmation. Called by
// website/vendor-confirm.html on page load with ?token=<uuid>. Looks up
// the application by token, runs dedup against local_vendor_results, flips
// status to 'live_unverified', and returns a JSON status the client renders.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TOKEN_TTL_DAYS = 7;

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

function extractDomain(url: string | null | undefined): string | null {
    if (!url) return null;
    try {
        const parsed = new URL(url);
        return parsed.hostname.toLowerCase().replace(/^www\./, "");
    } catch {
        return null;
    }
}

function normalizePhoneDigits(phone: string | null | undefined): string {
    return (phone ?? "").replace(/\D/g, "");
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
            return new Response(
                JSON.stringify({ error: "Server misconfigured" }),
                { status: 500, headers },
            );
        }
        const supabase = createClient(supabaseUrl, serviceRoleKey);

        // Token can come from query string (GET) or JSON body (POST)
        let token: string | null = null;
        const url = new URL(req.url);
        token = url.searchParams.get("token");
        if (!token && req.method === "POST") {
            try {
                const body = await req.json();
                token = body?.token ?? null;
            } catch {
                /* ignore */
            }
        }

        if (!token || !/^[0-9a-f-]{36}$/i.test(token)) {
            return new Response(
                JSON.stringify({ status: "invalid", message: "Confirmation token is missing or malformed." }),
                { status: 400, headers },
            );
        }

        const { data: app, error: lookupErr } = await supabase
            .from("vendor_applications")
            .select("id, status, business_name, email, phone, website, email_confirm_sent_at, linked_google_place_id")
            .eq("email_confirm_token", token)
            .maybeSingle();

        if (lookupErr) {
            console.error("[confirm-vendor-application] Lookup error:", lookupErr);
            return new Response(
                JSON.stringify({ status: "error", message: "Could not look up the application." }),
                { status: 500, headers },
            );
        }

        if (!app) {
            return new Response(
                JSON.stringify({ status: "not_found", message: "We couldn't find an application for this link." }),
                { status: 404, headers },
            );
        }

        // Already confirmed (idempotent)
        if (app.status === "live_unverified" || app.status === "chez_certified") {
            return new Response(
                JSON.stringify({
                    status: "already_confirmed",
                    business_name: app.business_name,
                    is_certified: app.status === "chez_certified",
                }),
                { status: 200, headers },
            );
        }

        if (app.status === "rejected") {
            return new Response(
                JSON.stringify({
                    status: "rejected",
                    message: "This application is no longer active. Contact tom@getchez.com if you believe this is in error.",
                }),
                { status: 410, headers },
            );
        }

        // Token TTL check
        const sentAt = new Date(app.email_confirm_sent_at).getTime();
        if (Date.now() - sentAt > TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000) {
            return new Response(
                JSON.stringify({
                    status: "expired",
                    message: `This confirmation link expired (${TOKEN_TTL_DAYS}-day limit). Please re-submit your application at getchez.com/vendor-apply.html.`,
                }),
                { status: 410, headers },
            );
        }

        // ----- Dedup check against existing Google Places listings -----
        // Match priority: full normalized phone digits (exact) → website
        // domain (exact, case-insensitive). First hit wins.
        //
        // Phone match uses the full normalized digit string rather than the
        // trailing 7. The trailing-7 substring approach false-positives when
        // two unrelated businesses happen to share their last 7 digits, which
        // is rare but real (saw it during gap review).
        let linkedPlaceId: string | null = app.linked_google_place_id ?? null;

        if (!linkedPlaceId) {
            const phoneDigits = normalizePhoneDigits(app.phone);
            const websiteDomain = extractDomain(app.website);

            if (phoneDigits.length >= 7) {
                // Pull candidates with at least one common digit run, then
                // do exact-match comparison after normalizing both sides.
                // Using `like` on the raw column would miss formatted variants
                // like "(203) 555-1234" vs "+1-203-555-1234".
                const { data: candidates } = await supabase
                    .from("local_vendor_results")
                    .select("google_place_id, phone")
                    .not("phone", "is", null)
                    .ilike("phone", `%${phoneDigits.slice(-4)}%`)
                    .limit(50);
                const matched = (candidates ?? []).find((row) => {
                    const otherDigits = (row.phone ?? "").replace(/\D/g, "");
                    return otherDigits.length >= 7 && otherDigits === phoneDigits;
                });
                if (matched?.google_place_id) {
                    linkedPlaceId = matched.google_place_id;
                }
            }

            if (!linkedPlaceId && websiteDomain) {
                // Exact-domain match. Strip protocol + leading www on both
                // sides so https://www.foo.com matches http://foo.com matches
                // www.foo.com. We can't store a normalized domain column
                // without a schema migration, so do the normalization in SQL
                // via lower() + ilike against patterns that bracket the
                // domain to defeat substring false positives.
                const { data: domainCandidates } = await supabase
                    .from("local_vendor_results")
                    .select("google_place_id, website")
                    .not("website", "is", null)
                    .ilike("website", `%${websiteDomain}%`)
                    .limit(50);
                const matched = (domainCandidates ?? []).find((row) => {
                    const otherDomain = extractDomain(row.website);
                    return otherDomain === websiteDomain;
                });
                if (matched?.google_place_id) {
                    linkedPlaceId = matched.google_place_id;
                }
            }
        }

        // ----- Flip to live_unverified -----
        const { error: updateErr } = await supabase
            .from("vendor_applications")
            .update({
                status: "live_unverified",
                email_confirmed_at: new Date().toISOString(),
                linked_google_place_id: linkedPlaceId,
            })
            .eq("id", app.id);

        if (updateErr) {
            console.error("[confirm-vendor-application] Update error:", updateErr);
            return new Response(
                JSON.stringify({ status: "error", message: "Could not confirm your application." }),
                { status: 500, headers },
            );
        }

        return new Response(
            JSON.stringify({
                status: "confirmed",
                business_name: app.business_name,
                linked_to_existing: !!linkedPlaceId,
            }),
            { status: 200, headers },
        );
    } catch (error) {
        console.error("[confirm-vendor-application] Unhandled error:", error);
        return new Response(
            JSON.stringify({ status: "error", message: "Internal server error" }),
            { status: 500, headers },
        );
    }
});

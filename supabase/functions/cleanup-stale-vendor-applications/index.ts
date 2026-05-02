// Chez Edge Function: cleanup-stale-vendor-applications
//
// Phase 72 / gap fix: nightly cleanup pass for vendor_applications.
//
// Two operations:
//   1. Auto-reject applications that never confirmed their email after 30
//      days. Sets status='rejected', rejection_notes='auto: never confirmed'.
//      The unique-active-email index lets the same vendor re-apply after.
//   2. Vacuum vendor_application_attempts older than 24 hours (rate-limit
//      log doesn't need permanent retention).
//
// Schedule via Supabase scheduled functions (or external cron) hitting this
// URL daily. Returns counts of rows affected for observability.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const STALE_PENDING_DAYS = 30;

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

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

        // ----- 1. Auto-reject stale pending applications -----
        const staleCutoff = new Date(
            Date.now() - STALE_PENDING_DAYS * 24 * 60 * 60 * 1000,
        ).toISOString();

        const { data: rejectedRows, error: rejectErr } = await supabase
            .from("vendor_applications")
            .update({
                status: "rejected",
                rejected_at: new Date().toISOString(),
                rejection_notes: `auto: never confirmed within ${STALE_PENDING_DAYS} days`,
            })
            .eq("status", "pending_email_confirm")
            .lt("email_confirm_sent_at", staleCutoff)
            .select("id");

        const rejectedCount = rejectedRows?.length ?? 0;

        if (rejectErr) {
            console.error("[cleanup-stale-vendor-applications] auto-reject error:", rejectErr);
        } else if (rejectedCount > 0) {
            console.log(
                `[cleanup-stale-vendor-applications] auto-rejected ${rejectedCount} stale pending applications`,
            );
        }

        // ----- 2. Vacuum old rate-limit attempts (24h retention) -----
        const attemptsCutoff = new Date(
            Date.now() - 24 * 60 * 60 * 1000,
        ).toISOString();

        const { data: vacuumed, error: vacuumErr } = await supabase
            .from("vendor_application_attempts")
            .delete()
            .lt("attempted_at", attemptsCutoff)
            .select("id");

        const vacuumedCount = vacuumed?.length ?? 0;

        if (vacuumErr) {
            console.error("[cleanup-stale-vendor-applications] vacuum error:", vacuumErr);
        } else if (vacuumedCount > 0) {
            console.log(
                `[cleanup-stale-vendor-applications] vacuumed ${vacuumedCount} rate-limit log rows`,
            );
        }

        return new Response(
            JSON.stringify({
                success: true,
                rejected_stale_pending: rejectedCount,
                vacuumed_rate_limit_log: vacuumedCount,
            }),
            { status: 200, headers },
        );
    } catch (error) {
        console.error("[cleanup-stale-vendor-applications] Unhandled error:", error);
        return new Response(
            JSON.stringify({ error: "Internal server error" }),
            { status: 500, headers },
        );
    }
});

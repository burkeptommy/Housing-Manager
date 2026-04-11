import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const token = url.searchParams.get("token");

    if (!token) {
      return new Response(
        JSON.stringify({ valid: false, error: "Missing token parameter" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Use service role to bypass RLS (public endpoint)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Lookup export by verification token
    const { data: exportRow, error: fetchError } = await supabase
      .from("estate_pdf_exports")
      .select("*")
      .eq("verification_token", token)
      .maybeSingle();

    if (fetchError) {
      console.error("[verify-estate-export] Fetch error:", fetchError);
      return new Response(
        JSON.stringify({ valid: false, error: "Internal error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!exportRow) {
      return new Response(
        JSON.stringify({ valid: false, error: "Invalid verification link" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check if revoked
    if (exportRow.revoked_at) {
      return new Response(
        JSON.stringify({ valid: false, error: "This link has been revoked", revoked: true }),
        { status: 410, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check expiry
    const expiresAt = new Date(exportRow.expires_at);
    if (new Date() > expiresAt) {
      return new Response(
        JSON.stringify({
          valid: false,
          error: "This link has expired. Please ask the sender to generate a new one.",
          expired: true,
        }),
        { status: 410, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check access count
    if (exportRow.access_count >= exportRow.max_access_count) {
      return new Response(
        JSON.stringify({
          valid: false,
          error: "This link has reached its maximum access count.",
          max_reached: true,
        }),
        { status: 410, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Valid! Increment access count and log access
    const ipRaw = req.headers.get("x-forwarded-for") || req.headers.get("cf-connecting-ip") || "unknown";
    // Hash the IP for privacy
    const encoder = new TextEncoder();
    const hashBuffer = await crypto.subtle.digest("SHA-256", encoder.encode(ipRaw));
    const ipHash = Array.from(new Uint8Array(hashBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("")
      .substring(0, 16);

    const accessLog = exportRow.access_log || [];
    accessLog.push({
      accessed_at: new Date().toISOString(),
      ip_hash: ipHash,
    });

    await supabase
      .from("estate_pdf_exports")
      .update({
        access_count: exportRow.access_count + 1,
        access_log: accessLog,
      })
      .eq("id", exportRow.id);

    // Get first name from the household for the verification display
    const { data: household } = await supabase
      .from("households")
      .select("name")
      .eq("id", exportRow.household_id)
      .single();

    // Return verification info (no PII, no document content)
    const truncatedHash = exportRow.pdf_content_hash
      ? exportRow.pdf_content_hash.substring(0, 12)
      : null;

    return new Response(
      JSON.stringify({
        valid: true,
        household_name: household?.name || "Haven User",
        generated_at: exportRow.created_at,
        pdf_hash_truncated: truncatedHash,
        access_remaining: exportRow.max_access_count - exportRow.access_count - 1,
        template_used: exportRow.template_used,
        readiness_score: exportRow.estate_readiness_score,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("[verify-estate-export] Unhandled error:", err);
    return new Response(
      JSON.stringify({ valid: false, error: "Internal error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// Haven Edge Function: send-catalog-request
// Sends an email to tom@havenhome.dev when a user can't find their equipment
// in the catalog, so the team can add it.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const sendgridApiKey = Deno.env.get("SENDGRID_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const body = await req.json();
    const { brand, systemType, modelNumber, notes, userId, householdId } = body;

    if (!brand || !systemType) {
      return new Response(
        JSON.stringify({ error: "Brand and system type are required" }),
        { status: 400, headers }
      );
    }

    // Look up user info for context
    let userEmail = "Unknown";
    let userName = "A Haven user";
    let householdName = "";
    if (userId) {
      const supabase = createClient(supabaseUrl, serviceRoleKey);
      const { data: user } = await supabase
        .from("users")
        .select("email, full_name")
        .eq("id", userId)
        .single();
      if (user) {
        userEmail = user.email || "Unknown";
        userName = user.full_name || userEmail;
      }
      if (householdId) {
        const { data: household } = await supabase
          .from("households")
          .select("name")
          .eq("id", householdId)
          .single();
        householdName = household?.name || "";
      }
    }

    const emailBody = `
A Haven user couldn't find their equipment in the catalog.

Brand: ${brand}
System Type: ${systemType}
${modelNumber ? `Model Number: ${modelNumber}` : ""}
${notes ? `Additional Info: ${notes}` : ""}

User: ${userName} (${userEmail})
${householdName ? `Household: ${householdName}` : ""}

Please add this to the equipment database so it's available next time.
    `.trim();

    // Send via SendGrid if API key is available
    if (sendgridApiKey) {
      const sgResponse = await fetch("https://api.sendgrid.com/v3/mail/send", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${sendgridApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          personalizations: [{ to: [{ email: "tom@havenhome.dev" }] }],
          from: { email: "alfred@havenhome.dev", name: "Haven Equipment Catalog" },
          subject: `Equipment Request: ${brand} ${systemType}${modelNumber ? ` (${modelNumber})` : ""}`,
          content: [{ type: "text/plain", value: emailBody }],
        }),
      });

      if (!sgResponse.ok) {
        const errText = await sgResponse.text().catch(() => "unknown");
        console.error(`[send-catalog-request] SendGrid error: ${sgResponse.status} ${errText}`);
      } else {
        console.log(`[send-catalog-request] Email sent: ${brand} ${systemType}`);
      }
    } else {
      // Fallback: just log it
      console.log(`[send-catalog-request] No SENDGRID_API_KEY — logging request:`);
      console.log(emailBody);
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error(`[send-catalog-request] Error: ${err}`);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers }
    );
  }
});

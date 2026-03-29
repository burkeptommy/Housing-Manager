// Haven Edge Function: send-push-notification
// Sends APNs push notifications to specified users by looking up their device tokens.
//
// Required Supabase secrets:
//   APNS_KEY_ID       - Key ID from Apple Developer portal
//   APNS_TEAM_ID      - Apple Developer Team ID
//   APNS_PRIVATE_KEY  - Contents of the .p8 auth key file (base64-encoded)
//   APNS_BUNDLE_ID    - App bundle ID (com.havenhome.app)
//   APNS_ENVIRONMENT  - "production" or "development" (defaults to "production")

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface PushRequest {
  recipient_user_ids: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

// Cache the JWT for APNs (valid for 1 hour, we refresh every 50 min)
let cachedJwt: string | null = null;
let jwtExpiresAt = 0;

async function getApnsJwt(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedJwt && now < jwtExpiresAt) return cachedJwt;

  const keyId = Deno.env.get("APNS_KEY_ID")!;
  const teamId = Deno.env.get("APNS_TEAM_ID")!;
  const privateKeyBase64 = Deno.env.get("APNS_PRIVATE_KEY")!;

  // Decode the .p8 key (base64 → PEM text → import)
  const privateKeyPem = atob(privateKeyBase64);
  const privateKey = await jose.importPKCS8(privateKeyPem, "ES256");

  const jwt = await new jose.SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt(now)
    .sign(privateKey);

  cachedJwt = jwt;
  jwtExpiresAt = now + 50 * 60; // refresh in 50 minutes
  return jwt;
}

async function sendApnsPush(
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<boolean> {
  const bundleId = Deno.env.get("APNS_BUNDLE_ID") || "com.havenhome.app";
  const environment = Deno.env.get("APNS_ENVIRONMENT") || "production";
  const host =
    environment === "production"
      ? "api.push.apple.com"
      : "api.sandbox.push.apple.com";

  const jwt = await getApnsJwt();

  const payload = {
    aps: {
      alert: { title, body },
      sound: "default",
      badge: 1,
    },
    ...(data || {}),
  };

  try {
    const response = await fetch(`https://${host}/3/device/${token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": bundleId,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "content-type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const err = await response.text();
      console.error(`[APNs] Failed for token ${token.slice(0, 8)}...: ${response.status} ${err}`);
      return false;
    }
    return true;
  } catch (error) {
    console.error(`[APNs] Error sending to ${token.slice(0, 8)}...:`, error);
    return false;
  }
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    // Verify auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers,
      });
    }

    // Check required secrets
    if (!Deno.env.get("APNS_KEY_ID") || !Deno.env.get("APNS_PRIVATE_KEY")) {
      console.error("[Push] APNs secrets not configured");
      return new Response(
        JSON.stringify({ error: "Push notifications not configured" }),
        { status: 503, headers }
      );
    }

    const { recipient_user_ids, title, body, data } =
      (await req.json()) as PushRequest;

    if (!recipient_user_ids?.length || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: recipient_user_ids, title, body" }),
        { status: 400, headers }
      );
    }

    // Create service-role client to read all device tokens
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Look up device tokens for all recipients
    const { data: tokens, error: tokenError } = await supabase
      .from("device_tokens")
      .select("token, user_id")
      .in("user_id", recipient_user_ids);

    if (tokenError) {
      console.error("[Push] Token lookup error:", tokenError);
      return new Response(
        JSON.stringify({ error: "Failed to look up device tokens" }),
        { status: 500, headers }
      );
    }

    if (!tokens?.length) {
      return new Response(
        JSON.stringify({ sent: 0, message: "No device tokens found for recipients" }),
        { status: 200, headers }
      );
    }

    // Send push to each device
    let sent = 0;
    let failed = 0;
    const staleTokens: string[] = [];

    for (const { token } of tokens) {
      const success = await sendApnsPush(token, title, body, data);
      if (success) {
        sent++;
      } else {
        failed++;
        staleTokens.push(token);
      }
    }

    // Clean up stale tokens (410 Gone responses mean the token is invalid)
    if (staleTokens.length > 0) {
      await supabase
        .from("device_tokens")
        .delete()
        .in("token", staleTokens);
    }

    console.log(`[Push] Sent: ${sent}, Failed: ${failed}, Stale cleaned: ${staleTokens.length}`);

    return new Response(
      JSON.stringify({ sent, failed, total_tokens: tokens.length }),
      { status: 200, headers }
    );
  } catch (error) {
    console.error("[Push] Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers }
    );
  }
});

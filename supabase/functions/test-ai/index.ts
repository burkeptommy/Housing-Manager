import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };
  const results: Record<string, unknown> = {};

  // Check env vars
  results.has_anthropic_key = !!Deno.env.get("ANTHROPIC_API_KEY");
  results.anthropic_key_prefix = Deno.env.get("ANTHROPIC_API_KEY")?.substring(0, 10) + "...";
  results.has_supabase_url = !!Deno.env.get("SUPABASE_URL");
  results.has_service_role_key = !!Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  // Try a simple Claude API call
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (apiKey) {
    try {
      const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: 50,
          messages: [{ role: "user", content: "Reply with exactly: HAVEN_AI_TEST_OK" }],
        }),
      });

      results.claude_status = response.status;
      results.claude_ok = response.ok;

      if (response.ok) {
        const data = await response.json();
        results.claude_response = data.content?.[0]?.text ?? "no text";
        results.model_used = data.model;
      } else {
        const errorText = await response.text();
        results.claude_error = errorText.substring(0, 500);
      }
    } catch (e) {
      results.claude_fetch_error = e.message;
    }
  } else {
    results.claude_error = "No API key to test with";
  }

  return new Response(JSON.stringify(results, null, 2), { status: 200, headers });
});

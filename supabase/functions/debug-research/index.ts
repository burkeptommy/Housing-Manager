import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Content-Type": "application/json",
  };

  if (req.method === "OPTIONS") return new Response("ok", { headers });

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  const results: Record<string, unknown> = {
    has_url: !!supabaseUrl,
    has_key: !!serviceRoleKey,
  };

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  // 1. Get the most recent project
  const { data: projects, error: fetchError } = await supabase
    .from("property_projects")
    .select("id, name, ai_research")
    .order("created_at", { ascending: false })
    .limit(1);

  if (fetchError) {
    results.fetch_error = fetchError.message;
    return new Response(JSON.stringify(results, null, 2), { status: 200, headers });
  }

  const project = projects?.[0];
  if (!project) {
    results.error = "No projects found";
    return new Response(JSON.stringify(results, null, 2), { status: 200, headers });
  }

  results.project_name = project.name;
  results.project_id = project.id;
  results.ai_research_before = project.ai_research === null ? "NULL" : "EXISTS";

  // 2. Try to write a test ai_research value
  const testResearch = {
    projectSummary: "Test summary",
    designMoodDescription: "A warm, inviting space with natural light",
    colorPalette: [
      { name: "Benjamin Moore White Dove OC-17", hex: "#F3EFE0", usage: "Main walls", role: "primary" }
    ],
    materialPairings: [
      { primary: "White oak flooring", secondary: "Brass hardware", location: "Throughout" }
    ],
    styleNotes: "Test style notes",
    typicalItems: [],
    tipsAndWarnings: ["Test tip"],
  };

  const { error: updateError, data: updateData, count } = await supabase
    .from("property_projects")
    .update({ ai_research: testResearch, ai_research_updated_at: new Date().toISOString() })
    .eq("id", project.id)
    .select("id, ai_research");

  results.update_error = updateError?.message ?? null;
  results.update_data_count = updateData?.length ?? 0;
  results.update_returned_research = updateData?.[0]?.ai_research != null;

  // 3. Re-read to verify
  const { data: verify } = await supabase
    .from("property_projects")
    .select("ai_research")
    .eq("id", project.id)
    .single();

  results.ai_research_after = verify?.ai_research === null ? "STILL NULL" : "NOW EXISTS";
  if (verify?.ai_research) {
    results.after_keys = Object.keys(verify.ai_research).sort();
    results.after_has_mood = verify.ai_research.designMoodDescription != null;
  }

  return new Response(JSON.stringify(results, null, 2), { status: 200, headers });
});

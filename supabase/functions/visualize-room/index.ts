// Haven Edge Function: visualize-room
// Calls Decor8 AI to generate room visualizations — redesigns, paint previews,
// kitchen/bathroom remodels, inspirational designs, and landscaping.
// Tracks per-user monthly usage (25 generations/month limit).

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { authFailure, requireHousehold } from "../_shared/require-household.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const MONTHLY_LIMIT = 25;
const DECOR8_BASE = "https://api.decor8.ai";

// Map Haven style chips → Decor8 design_style values (lowercase for API)
const STYLE_MAP: Record<string, string> = {
  modern: "modern",
  farmhouse: "modernfarmhouse",
  traditional: "traditional",
  "mid-century": "midcenturymodern",
  minimalist: "minimalist",
  industrial: "industrial",
  coastal: "coastal",
  scandinavian: "scandinavian",
  bohemian: "bohemian",
  transitional: "transitional",
  rustic: "rustic",
  contemporary: "contemporary",
};

// Map Haven project categories → Decor8 room_type values (lowercase, no spaces)
const ROOM_TYPE_MAP: Record<string, string> = {
  "kitchen renovation": "kitchen",
  "bathroom renovation": "bathroom",
  basement: "familyroom",
  garage: "garage",
  "deck / patio": "patio",
  "built-ins & shelving": "livingroom",
  flooring: "livingroom",
  painting: "livingroom",
  electrical: "livingroom",
  plumbing: "bathroom",
  hvac: "livingroom",
  "windows & doors": "livingroom",
  roofing: "livingroom",
  fencing: "patio",
  "siding / exterior": "livingroom",
  insulation: "livingroom",
  "smart home": "livingroom",
  additions: "livingroom",
  landscaping: "patio",
  other: "livingroom",
};

interface VisualizeRequest {
  room_image_base64?: string;
  project_id: string;
  household_id: string;
  user_id: string;
  visualization_type: string; // room_design | wall_color | inspiration | kitchen | bathroom | landscaping
  design_style?: string;
  color_hex?: string;
  color_scheme?: string;
  user_prompt?: string;
  room_type?: string;
  project_category?: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const decor8Key = Deno.env.get("DECOR8_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!decor8Key) {
      return new Response(
        JSON.stringify({ error: "DECOR8_API_KEY not set" }),
        { status: 500, headers }
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const body: VisualizeRequest = await req.json();
    const {
      room_image_base64,
      project_id,
      household_id,
      user_id,
      visualization_type,
      design_style,
      color_hex,
      color_scheme,
      user_prompt,
      room_type,
      project_category,
    } = body;

    if (!project_id || !household_id || !user_id) {
      return new Response(
        JSON.stringify({ error: "project_id, household_id, and user_id are required" }),
        { status: 400, headers }
      );
    }

    // July 2026 security sweep (audit S1): storage paths + usage counters
    // keyed on body household_id/user_id were unverified. The caller's JWT
    // identity must match both, and the project must be theirs.
    const auth = await requireHousehold(req);
    if ("failure" in auth) return authFailure(auth, headers);
    if (household_id !== auth.householdId || user_id !== auth.userId) {
      return new Response(
        JSON.stringify({ error: "Access denied: identity mismatch" }),
        { status: 403, headers }
      );
    }
    {
      const { data: proj } = await supabase
        .from("property_projects").select("household_id").eq("id", project_id).single();
      if (!proj || proj.household_id !== auth.householdId) {
        return new Response(
          JSON.stringify({ error: "Access denied: project does not belong to your household" }),
          { status: 403, headers }
        );
      }
    }

    // --- CHECK MONTHLY USAGE LIMIT ---
    const { data: userData } = await supabase
      .from("users")
      .select("viz_generations_used, viz_generations_reset_at")
      .eq("id", user_id)
      .single();

    let usedThisMonth = userData?.viz_generations_used ?? 0;
    const resetAt = userData?.viz_generations_reset_at
      ? new Date(userData.viz_generations_reset_at)
      : new Date(0);

    // Reset counter if it's been more than 30 days
    const daysSinceReset = (Date.now() - resetAt.getTime()) / (1000 * 60 * 60 * 24);
    if (daysSinceReset >= 30) {
      usedThisMonth = 0;
      await supabase
        .from("users")
        .update({ viz_generations_used: 0, viz_generations_reset_at: new Date().toISOString() })
        .eq("id", user_id);
    }

    if (usedThisMonth >= MONTHLY_LIMIT) {
      return new Response(
        JSON.stringify({
          error: "Monthly visualization limit reached",
          generations_used: usedThisMonth,
          generations_remaining: 0,
          limit: MONTHLY_LIMIT,
        }),
        { status: 429, headers }
      );
    }

    // --- UPLOAD INPUT IMAGE TO SUPABASE STORAGE (for Decor8 URL input) ---
    let inputImageUrl: string | null = null;
    let inputImagePath: string | null = null;

    if (room_image_base64) {
      const storagePath = `${household_id}/${project_id}/input_${crypto.randomUUID()}.jpg`;
      const fileBuffer = Uint8Array.from(atob(room_image_base64), (c) => c.charCodeAt(0));
      const { error: uploadErr } = await supabase.storage
        .from("room-visualizations")
        .upload(storagePath, fileBuffer, { contentType: "image/jpeg" });

      if (!uploadErr) {
        inputImagePath = storagePath;
        // Get a signed URL for Decor8 to access
        const { data: signedData } = await supabase.storage
          .from("room-visualizations")
          .createSignedUrl(storagePath, 600); // 10 min expiry
        inputImageUrl = signedData?.signedUrl ?? null;
        console.log(`[visualize-room] Input image uploaded: ${storagePath}`);
      } else {
        console.error(`[visualize-room] Input upload failed: ${uploadErr.message}`);
      }
    }

    // --- RESOLVE DECOR8 PARAMETERS ---
    const category = (project_category ?? "other").toLowerCase();
    const resolvedRoomType = room_type || ROOM_TYPE_MAP[category] || "livingroom";

    // Map design style from Haven chips to Decor8 values
    let resolvedStyle = design_style || "modern";
    const styleLower = resolvedStyle.toLowerCase();
    for (const [key, value] of Object.entries(STYLE_MAP)) {
      if (styleLower.includes(key)) {
        resolvedStyle = value;
        break;
      }
    }

    // Merge color_scheme into user_prompt (Decor8 color_scheme param expects enum values, not free text)
    const resolvedPrompt = [
      color_scheme ? `Color palette: ${color_scheme}.` : "",
      user_prompt || "",
    ].filter(Boolean).join(" ") || undefined;

    console.log(
      `[visualize-room] Type: ${visualization_type}, Style: ${resolvedStyle}, Room: ${resolvedRoomType}, Category: ${category}`
    );

    // --- ROUTE TO CORRECT DECOR8 ENDPOINT ---
    let decor8Endpoint: string;
    let decor8Body: Record<string, unknown>;

    switch (visualization_type) {
      case "wall_color":
        if (!inputImageUrl || !color_hex) {
          return new Response(
            JSON.stringify({ error: "room_image_base64 and color_hex are required for wall color preview" }),
            { status: 400, headers }
          );
        }
        decor8Endpoint = "/change_wall_color";
        decor8Body = {
          input_image_url: inputImageUrl,
          color_hex: color_hex,
          room_type: resolvedRoomType,
          num_images: 1,
        };
        break;

      case "kitchen":
        if (!inputImageUrl) {
          return new Response(
            JSON.stringify({ error: "room_image_base64 is required for kitchen remodel" }),
            { status: 400, headers }
          );
        }
        decor8Endpoint = "/remodel_kitchen";
        decor8Body = {
          input_image_url: inputImageUrl,
          design_style: resolvedStyle,
          user_prompt: resolvedPrompt,
          num_images: 1,
        };
        break;

      case "bathroom":
        if (!inputImageUrl) {
          return new Response(
            JSON.stringify({ error: "room_image_base64 is required for bathroom remodel" }),
            { status: 400, headers }
          );
        }
        decor8Endpoint = "/remodel_bathroom";
        decor8Body = {
          input_image_url: inputImageUrl,
          design_style: resolvedStyle,
          user_prompt: resolvedPrompt,
          num_images: 1,
        };
        break;

      case "landscaping":
        if (!inputImageUrl) {
          return new Response(
            JSON.stringify({ error: "room_image_base64 is required for landscaping design" }),
            { status: 400, headers }
          );
        }
        decor8Endpoint = "/generate_landscaping_designs";
        decor8Body = {
          input_image_url: inputImageUrl,
          design_style: resolvedStyle,
          user_prompt: resolvedPrompt,
          num_images: 1,
        };
        break;

      case "inspiration":
        // No input image needed
        decor8Endpoint = "/generate_inspirational_designs";
        decor8Body = {
          room_type: resolvedRoomType,
          design_style: resolvedStyle,
          user_prompt: resolvedPrompt,
          num_images: 1,
        };
        break;

      case "room_design":
      default:
        if (!inputImageUrl) {
          // Fall back to inspiration if no image
          decor8Endpoint = "/generate_inspirational_designs";
          decor8Body = {
            room_type: resolvedRoomType,
            design_style: resolvedStyle,
            color_scheme: color_scheme || undefined,
            user_prompt: resolvedPrompt,
            num_images: 1,
          };
        } else {
          decor8Endpoint = "/generate_designs_for_room";
          decor8Body = {
            input_image_url: inputImageUrl,
            room_type: resolvedRoomType,
            design_style: resolvedStyle,
            color_scheme: color_scheme || undefined,
            user_prompt: resolvedPrompt,
            num_images: 1,
          };
        }
        break;
    }

    // --- CALL DECOR8 API ---
    console.log(`[visualize-room] Calling Decor8: ${decor8Endpoint}`);

    const decor8Response = await fetch(`${DECOR8_BASE}${decor8Endpoint}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${decor8Key}`,
      },
      body: JSON.stringify(decor8Body),
    });

    if (!decor8Response.ok) {
      const errText = await decor8Response.text();
      console.error(`[visualize-room] Decor8 error (${decor8Response.status}): ${errText.substring(0, 300)}`);
      return new Response(
        JSON.stringify({ error: "Room visualization failed", detail: errText.substring(0, 200) }),
        { status: 502, headers }
      );
    }

    const decor8Data = await decor8Response.json();
    console.log(`[visualize-room] Decor8 response received`);

    // Extract image URL from response (varies by endpoint)
    let outputImageUrl: string | null = null;
    const info = (decor8Data as any)?.info;
    if (info?.images?.[0]?.url) {
      outputImageUrl = info.images[0].url;
    } else if (info?.url) {
      outputImageUrl = info.url;
    }

    if (!outputImageUrl) {
      console.error(`[visualize-room] No image in Decor8 response: ${JSON.stringify(decor8Data).substring(0, 300)}`);
      return new Response(
        JSON.stringify({ error: "No visualization generated" }),
        { status: 502, headers }
      );
    }

    // --- SAVE VISUALIZATION RECORD ---
    const { data: vizRecord, error: vizErr } = await supabase
      .from("project_visualizations")
      .insert({
        project_id,
        household_id,
        created_by: user_id,
        visualization_type,
        input_image_path: inputImagePath,
        output_image_url: outputImageUrl,
        design_style: resolvedStyle,
        color_hex: color_hex || null,
        user_prompt: user_prompt || null,
      })
      .select("id")
      .single();

    if (vizErr) {
      console.error(`[visualize-room] DB insert failed: ${vizErr.message}`);
    }

    // --- INCREMENT USAGE COUNTER ---
    const newCount = usedThisMonth + 1;
    await supabase
      .from("users")
      .update({ viz_generations_used: newCount })
      .eq("id", user_id);

    console.log(
      `[visualize-room] Success! Type: ${visualization_type}, Style: ${resolvedStyle}, Usage: ${newCount}/${MONTHLY_LIMIT}`
    );

    return new Response(
      JSON.stringify({
        success: true,
        image_url: outputImageUrl,
        visualization_id: vizRecord?.id,
        generations_used: newCount,
        generations_remaining: MONTHLY_LIMIT - newCount,
      }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error("[visualize-room] Error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers }
    );
  }
});

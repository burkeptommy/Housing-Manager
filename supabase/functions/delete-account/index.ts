// Haven Edge Function: delete-account
// Permanently deletes a user's account and all associated data.
// Requires service_role to delete auth users and cascade household data.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // Extract user ID from the Authorization header JWT
    const authHeader = req.headers.get("authorization") ?? "";
    const token = authHeader.replace("Bearer ", "");

    if (!token) {
      return new Response(
        JSON.stringify({ error: "No authorization token" }),
        { status: 401, headers }
      );
    }

    // Create clients
    const anonClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY") ?? serviceRoleKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    // Get the authenticated user
    const { data: { user }, error: userError } = await anonClient.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired session" }),
        { status: 401, headers }
      );
    }

    const userId = user.id;
    console.log(`[delete-account] Starting deletion for user ${userId}`);

    // Get user's household
    const { data: userData } = await serviceClient
      .from("users")
      .select("household_id")
      .eq("id", userId)
      .single();

    const householdId = userData?.household_id;

    if (householdId) {
      // Check if this user is the only one in the household
      const { data: householdUsers } = await serviceClient
        .from("users")
        .select("id")
        .eq("household_id", householdId);

      const isOnlyUser = !householdUsers || householdUsers.length <= 1;

      if (isOnlyUser) {
        // Delete all storage files for this household
        console.log(`[delete-account] Deleting storage for household ${householdId}`);
        const { data: files } = await serviceClient.storage
          .from("documents")
          .list(householdId.toLowerCase());

        if (files && files.length > 0) {
          // List all files recursively
          for (const folder of files) {
            const { data: subFiles } = await serviceClient.storage
              .from("documents")
              .list(`${householdId.toLowerCase()}/${folder.name}`);

            if (subFiles && subFiles.length > 0) {
              const paths = subFiles.map(
                (f) => `${householdId.toLowerCase()}/${folder.name}/${f.name}`
              );
              await serviceClient.storage.from("documents").remove(paths);
            }
          }
        }

        // Delete the household — CASCADE will delete:
        // family_members, documents, document_family_members, document_content,
        // properties, home_systems, warranties, contractors, maintenance_tasks,
        // service_records, completion_scores, trusted_contacts, service_contracts,
        // property_projects, project_line_items, household_toolkit,
        // household_invitations, household_merge_requests, analytics_events (household_id)
        console.log(`[delete-account] Deleting household ${householdId} (sole user)`);
        await serviceClient
          .from("households")
          .delete()
          .eq("id", householdId);
      } else {
        // Other users exist — just remove this user's data
        console.log(`[delete-account] Removing user ${userId} from shared household`);

        // Delete user's chat messages
        await serviceClient
          .from("chat_messages")
          .delete()
          .eq("user_id", userId);

        // Nullify access log entries (preserve audit trail)
        await serviceClient
          .from("access_log")
          .update({ user_id: null })
          .eq("user_id", userId);
      }
    }

    // Delete the user row from public.users
    console.log(`[delete-account] Deleting user row ${userId}`);
    await serviceClient
      .from("users")
      .delete()
      .eq("id", userId);

    // Delete the auth user (requires service role)
    console.log(`[delete-account] Deleting auth user ${userId}`);
    const { error: deleteAuthError } = await serviceClient.auth.admin.deleteUser(userId);
    if (deleteAuthError) {
      console.error(`[delete-account] Auth delete error: ${deleteAuthError.message}`);
      // Don't fail — data is already deleted, auth record cleanup can happen later
    }

    console.log(`[delete-account] Successfully deleted account for ${userId}`);

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error("[delete-account] Error:", err);
    return new Response(
      JSON.stringify({ error: "Account deletion failed", detail: String(err) }),
      { status: 500, headers }
    );
  }
});

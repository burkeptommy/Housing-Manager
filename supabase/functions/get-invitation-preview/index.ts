// Haven Edge Function: get-invitation-preview
//
// Returns a JSON preview of the household referenced by an invite code.
// Used by the InviteCodeEntrySheet on iOS so the recipient can see who
// invited them and what household they would be joining BEFORE creating an
// account. Reads with the service role so that pre-authentication clients
// (no session) can resolve the invitation, but only returns safe public
// fields.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface PreviewRequest {
  invite_code: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      console.error("[get-invitation-preview] Supabase env not configured");
      return new Response(
        JSON.stringify({ error: "Server misconfigured" }),
        { status: 500, headers }
      );
    }

    const body = (await req.json()) as PreviewRequest;
    const rawCode = body?.invite_code?.trim().toUpperCase().replace(/-/g, "");
    if (!rawCode || rawCode.length !== 6) {
      return new Response(
        JSON.stringify({ error: "Invalid invite_code: must be 6 characters" }),
        { status: 400, headers }
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Look up the invitation. We deliberately fetch the latest one so a
    // resent code still resolves cleanly.
    const { data: invitation, error: inviteError } = await supabase
      .from("household_invitations")
      .select(
        "id, household_id, invited_by, invited_email, status, expires_at, personal_message, family_member_id"
      )
      .eq("invite_code", rawCode)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (inviteError) {
      console.error("[get-invitation-preview] Lookup error:", inviteError);
      return new Response(
        JSON.stringify({ error: "Failed to look up invitation" }),
        { status: 500, headers }
      );
    }

    if (!invitation) {
      return new Response(
        JSON.stringify({ error: "Invitation not found", error_code: "not_found" }),
        { status: 404, headers }
      );
    }

    // Status guards. Front-end branches on these.
    if (invitation.status === "revoked") {
      return new Response(
        JSON.stringify({ error: "Invitation has been revoked", error_code: "revoked" }),
        { status: 410, headers }
      );
    }
    if (invitation.status === "accepted") {
      return new Response(
        JSON.stringify({ error: "Invitation has already been accepted", error_code: "accepted" }),
        { status: 410, headers }
      );
    }
    if (invitation.expires_at && new Date(invitation.expires_at).getTime() < Date.now()) {
      return new Response(
        JSON.stringify({ error: "Invitation has expired", error_code: "expired" }),
        { status: 410, headers }
      );
    }

    // Resolve the inviter (full name + avatar) and household summary.
    const [{ data: inviter }, { data: household }, { data: properties }, { data: systems }, { data: tasks }, { data: members }, { data: familyMember }] = await Promise.all([
      supabase
        .from("users")
        .select("id, full_name, email")
        .eq("id", invitation.invited_by)
        .maybeSingle(),
      supabase
        .from("households")
        .select("id, name")
        .eq("id", invitation.household_id)
        .maybeSingle(),
      supabase
        .from("properties")
        .select("id, street, city, state")
        .eq("household_id", invitation.household_id),
      supabase
        .from("home_systems")
        .select("id")
        .eq("household_id", invitation.household_id),
      supabase
        .from("maintenance_tasks")
        .select("id")
        .eq("household_id", invitation.household_id),
      supabase
        .from("family_members")
        .select("id, first_name, avatar_url")
        .eq("household_id", invitation.household_id),
      invitation.family_member_id
        ? supabase
            .from("family_members")
            .select("first_name")
            .eq("id", invitation.family_member_id)
            .maybeSingle()
        : Promise.resolve({ data: null }),
    ]);

    const primaryProperty =
      (properties || []).find((p: { street?: string | null }) => (p.street || "").length > 0) ||
      (properties || [])[0] ||
      null;

    const householdAddress = primaryProperty
      ? [primaryProperty.street, primaryProperty.city, primaryProperty.state]
          .filter((part) => typeof part === "string" && part.length > 0)
          .join(", ")
      : null;

    const inviteeFirstName = familyMember?.first_name ?? null;

    const responseBody = {
      invite_code: rawCode,
      inviter_name: inviter?.full_name ?? null,
      inviter_avatar_url: null, // users table has no avatar URL today; reserved for future.
      household_name: household?.name ?? null,
      household_address: householdAddress,
      invitee_first_name: inviteeFirstName,
      invitee_email: invitation.invited_email,
      personal_message: invitation.personal_message ?? null,
      system_count: (systems || []).length,
      task_count: (tasks || []).length,
      member_count: (members || []).length,
      property_count: (properties || []).length,
      expires_at: invitation.expires_at,
      status: invitation.status,
    };

    return new Response(JSON.stringify(responseBody), { status: 200, headers });
  } catch (error) {
    console.error("[get-invitation-preview] Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers }
    );
  }
});

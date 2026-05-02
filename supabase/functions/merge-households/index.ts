import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// --- Duplicate detection helpers ---

function normalizeStr(s: string | null | undefined): string {
  return (s || "").trim().toLowerCase();
}

function findPropertyDuplicates(sourceProps: any[], targetProps: any[]) {
  const duplicates: any[] = [];
  const sourceOnly: any[] = [];
  const matchedTargetIds = new Set<string>();

  for (const sp of sourceProps) {
    const sAddr = `${normalizeStr(sp.street)}_${normalizeStr(sp.city)}_${normalizeStr(sp.state)}`;
    let matched = false;

    if (sAddr !== "__") {
      for (const tp of targetProps) {
        if (matchedTargetIds.has(tp.id)) continue;
        const tAddr = `${normalizeStr(tp.street)}_${normalizeStr(tp.city)}_${normalizeStr(tp.state)}`;
        if (sAddr === tAddr) {
          duplicates.push({ source: sp, target: tp, match_reason: "Same address" });
          matchedTargetIds.add(tp.id);
          matched = true;
          break;
        }
      }
    }
    if (!matched) sourceOnly.push(sp);
  }

  const targetOnly = targetProps.filter((tp: any) => !matchedTargetIds.has(tp.id));
  return { duplicates, source_only: sourceOnly, target_only: targetOnly };
}

function findDuplicatesByFields(
  sourceItems: any[],
  targetItems: any[],
  keyFn: (item: any) => string,
  matchReason: string,
) {
  const duplicates: any[] = [];
  const sourceOnly: any[] = [];
  const targetKeyMap = new Map<string, any>();

  for (const t of targetItems) {
    const key = keyFn(t);
    if (key) targetKeyMap.set(key, t);
  }

  const matchedTargetIds = new Set<string>();

  for (const s of sourceItems) {
    const key = keyFn(s);
    if (key && targetKeyMap.has(key)) {
      const target = targetKeyMap.get(key)!;
      duplicates.push({ source: s, target, match_reason: matchReason });
      matchedTargetIds.add(target.id);
    } else {
      sourceOnly.push(s);
    }
  }

  const targetOnly = targetItems.filter((t: any) => !matchedTargetIds.has(t.id));
  return { duplicates, source_only: sourceOnly, target_only: targetOnly };
}

function findContractorDuplicates(sourceItems: any[], targetItems: any[]) {
  const duplicates: any[] = [];
  const sourceOnly: any[] = [];
  const matchedTargetIds = new Set<string>();

  for (const s of sourceItems) {
    let matched = false;
    const sName = normalizeStr(s.company_name);
    const sPhone = normalizeStr(s.phone);

    for (const t of targetItems) {
      if (matchedTargetIds.has(t.id)) continue;
      const tName = normalizeStr(t.company_name);
      const tPhone = normalizeStr(t.phone);

      if ((sName && sName === tName) || (sPhone && sPhone === tPhone)) {
        duplicates.push({
          source: s,
          target: t,
          match_reason: sName === tName ? "Same company name" : "Same phone number",
        });
        matchedTargetIds.add(t.id);
        matched = true;
        break;
      }
    }
    if (!matched) sourceOnly.push(s);
  }

  const targetOnly = targetItems.filter((t: any) => !matchedTargetIds.has(t.id));
  return { duplicates, source_only: sourceOnly, target_only: targetOnly };
}

// Build a map from source property ID -> target property ID for matched properties
function buildPropertyMapping(propertyPreview: any, resolutions: any): Map<string, string> {
  const mapping = new Map<string, string>();
  for (const dup of propertyPreview.duplicates) {
    const resolution = resolutions?.properties?.[dup.source.id];
    if (resolution === "keep_source") {
      // Source property survives — target's children need re-parenting to source
      mapping.set(dup.target.id, dup.source.id);
    } else {
      // Default: keep target — source's children get re-parented to target
      mapping.set(dup.source.id, dup.target.id);
    }
  }
  return mapping;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const responseHeaders = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Authenticate the caller
    const authHeader = req.headers.get("Authorization");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader || "" } },
    });
    const { data: { user }, error: authError } = await authClient.auth.getUser();
    if (!user || authError) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: responseHeaders });
    }

    const body = await req.json();
    const { action, merge_request_id, email, resolutions } = body;

    // === ACTION: check_user ===
    if (action === "check_user") {
      const { data: users } = await supabase
        .from("users")
        .select("id, full_name, email, household_id")
        .eq("email", email.toLowerCase().trim())
        .limit(1);

      if (users && users.length > 0) {
        const existingUser = users[0];
        let householdName = null;
        if (existingUser.household_id) {
          const { data: hh } = await supabase
            .from("households")
            .select("name")
            .eq("id", existingUser.household_id)
            .single();
          householdName = hh?.name;
        }
        return new Response(JSON.stringify({
          exists: true,
          user_id: existingUser.id,
          name: existingUser.full_name,
          household_id: existingUser.household_id,
          household_name: householdName,
        }), { headers: responseHeaders });
      }

      return new Response(JSON.stringify({ exists: false }), { headers: responseHeaders });
    }

    // === ACTION: create_merge_request ===
    if (action === "create_merge_request") {
      const { data: targetUsers } = await supabase
        .from("users")
        .select("id, household_id")
        .eq("email", email.toLowerCase().trim())
        .limit(1);

      if (!targetUsers || targetUsers.length === 0) {
        return new Response(JSON.stringify({ error: "User not found" }), { status: 404, headers: responseHeaders });
      }

      const targetUser = targetUsers[0];

      const { data: requesterUser } = await supabase
        .from("users")
        .select("full_name, household_id")
        .eq("id", user.id)
        .single();

      const { data: targetHousehold } = await supabase
        .from("households")
        .select("name")
        .eq("id", requesterUser.household_id)
        .single();

      const { data: sourceHousehold } = await supabase
        .from("households")
        .select("name")
        .eq("id", targetUser.household_id)
        .single();

      const { data: mergeReq, error: insertError } = await supabase
        .from("household_merge_requests")
        .insert({
          source_household_id: targetUser.household_id,
          target_household_id: requesterUser.household_id,
          requested_by: user.id,
          requested_for_email: email.toLowerCase().trim(),
          target_user_id: targetUser.id,
          source_household_name: sourceHousehold?.name || "Unknown",
          target_household_name: targetHousehold?.name || "Unknown",
          requester_name: requesterUser.full_name || "A family member",
        })
        .select()
        .single();

      if (insertError) {
        console.error("Failed to create merge request:", insertError);
        return new Response(JSON.stringify({ error: insertError.message }), { status: 500, headers: responseHeaders });
      }

      return new Response(JSON.stringify({ success: true, merge_request: mergeReq }), { headers: responseHeaders });
    }

    // === ACTION: preview_merge ===
    // Compares both households and returns a diff with duplicates detected
    if (action === "preview_merge") {
      const { data: mergeReq } = await supabase
        .from("household_merge_requests")
        .select("*")
        .eq("id", merge_request_id)
        .single();

      if (!mergeReq) {
        return new Response(JSON.stringify({ error: "Merge request not found" }), { status: 404, headers: responseHeaders });
      }

      if (mergeReq.status !== "pending") {
        return new Response(JSON.stringify({ error: "Merge request already resolved" }), { status: 400, headers: responseHeaders });
      }

      const sourceId = mergeReq.source_household_id;
      const targetId = mergeReq.target_household_id;

      // Fetch all data from both households in parallel
      const [
        { data: sourceProps },
        { data: targetProps },
        { data: sourceSystems },
        { data: targetSystems },
        { data: sourceTasks },
        { data: targetTasks },
        { data: sourceContractors },
        { data: targetContractors },
        { data: sourceDocs },
        { data: targetDocs },
        { data: sourceMembers },
        { data: targetMembers },
      ] = await Promise.all([
        supabase.from("properties").select("*").eq("household_id", sourceId),
        supabase.from("properties").select("*").eq("household_id", targetId),
        supabase.from("home_systems").select("*").eq("household_id", sourceId),
        supabase.from("home_systems").select("*").eq("household_id", targetId),
        supabase.from("maintenance_tasks").select("*").eq("household_id", sourceId),
        supabase.from("maintenance_tasks").select("*").eq("household_id", targetId),
        supabase.from("contractors").select("*").eq("household_id", sourceId),
        supabase.from("contractors").select("*").eq("household_id", targetId),
        supabase.from("documents").select("*").eq("household_id", sourceId),
        supabase.from("documents").select("*").eq("household_id", targetId),
        supabase.from("family_members").select("*").eq("household_id", sourceId),
        supabase.from("family_members").select("*").eq("household_id", targetId),
      ]);

      // Detect duplicates per entity type
      const propertyPreview = findPropertyDuplicates(sourceProps || [], targetProps || []);

      // Build property ID mapping for child entity matching
      const propSourceToTarget = new Map<string, string>();
      for (const dup of propertyPreview.duplicates) {
        propSourceToTarget.set(dup.source.id, dup.target.id);
      }

      // Home systems: match by name+category on matched properties
      const systemPreview = findDuplicatesByFields(
        sourceSystems || [],
        targetSystems || [],
        (item: any) => {
          const mappedPropId = propSourceToTarget.get(item.property_id) || item.property_id;
          return `${normalizeStr(item.name)}_${normalizeStr(item.category)}_${mappedPropId}`;
        },
        "Same system on same property",
      );

      // Maintenance tasks: match by title on matched properties
      const taskPreview = findDuplicatesByFields(
        sourceTasks || [],
        targetTasks || [],
        (item: any) => {
          const mappedPropId = propSourceToTarget.get(item.property_id) || item.property_id;
          return `${normalizeStr(item.title)}_${mappedPropId}`;
        },
        "Same task on same property",
      );

      // Contractors: match by name or phone
      const contractorPreview = findContractorDuplicates(sourceContractors || [], targetContractors || []);

      // Documents: match by title + category
      const documentPreview = findDuplicatesByFields(
        sourceDocs || [],
        targetDocs || [],
        (item: any) => `${normalizeStr(item.title)}_${normalizeStr(item.category)}`,
        "Same document title and category",
      );

      // Family members: match by first+last name
      const memberPreview = findDuplicatesByFields(
        sourceMembers || [],
        targetMembers || [],
        (item: any) => `${normalizeStr(item.first_name)}_${normalizeStr(item.last_name)}`,
        "Same name",
      );

      const preview = {
        properties: propertyPreview,
        home_systems: systemPreview,
        maintenance_tasks: taskPreview,
        contractors: contractorPreview,
        documents: documentPreview,
        family_members: memberPreview,
      };

      const totalDuplicates =
        propertyPreview.duplicates.length +
        systemPreview.duplicates.length +
        taskPreview.duplicates.length +
        contractorPreview.duplicates.length +
        documentPreview.duplicates.length +
        memberPreview.duplicates.length;

      const totalSourceOnly =
        propertyPreview.source_only.length +
        systemPreview.source_only.length +
        taskPreview.source_only.length +
        contractorPreview.source_only.length +
        documentPreview.source_only.length +
        memberPreview.source_only.length;

      const categoriesWithConflicts: string[] = [];
      if (propertyPreview.duplicates.length > 0) categoriesWithConflicts.push("properties");
      if (systemPreview.duplicates.length > 0) categoriesWithConflicts.push("home_systems");
      if (taskPreview.duplicates.length > 0) categoriesWithConflicts.push("maintenance_tasks");
      if (contractorPreview.duplicates.length > 0) categoriesWithConflicts.push("contractors");
      if (documentPreview.duplicates.length > 0) categoriesWithConflicts.push("documents");
      if (memberPreview.duplicates.length > 0) categoriesWithConflicts.push("family_members");

      const summary = {
        total_duplicates: totalDuplicates,
        source_only: totalSourceOnly,
        target_only:
          propertyPreview.target_only.length +
          systemPreview.target_only.length +
          taskPreview.target_only.length +
          contractorPreview.target_only.length +
          documentPreview.target_only.length +
          memberPreview.target_only.length,
        categories_with_conflicts: categoriesWithConflicts,
      };

      // Cache the preview
      await supabase
        .from("household_merge_requests")
        .update({ preview_data: { preview, summary } })
        .eq("id", merge_request_id);

      return new Response(JSON.stringify({
        preview,
        summary,
        source_household_name: mergeReq.source_household_name,
        target_household_name: mergeReq.target_household_name,
      }), { headers: responseHeaders });
    }

    // === ACTION: execute_merge ===
    // Resolution-aware merge: uses user's choices for duplicates
    if (action === "execute_merge") {
      const { data: mergeReq } = await supabase
        .from("household_merge_requests")
        .select("*")
        .eq("id", merge_request_id)
        .single();

      if (!mergeReq) {
        return new Response(JSON.stringify({ error: "Merge request not found" }), { status: 404, headers: responseHeaders });
      }

      if (mergeReq.status !== "pending") {
        return new Response(JSON.stringify({ error: "Merge request already resolved" }), { status: 400, headers: responseHeaders });
      }

      if (mergeReq.target_user_id !== user.id && mergeReq.requested_for_email !== user.email) {
        return new Response(JSON.stringify({ error: "Not authorized to accept this request" }), { status: 403, headers: responseHeaders });
      }

      const sourceId = mergeReq.source_household_id;
      const targetId = mergeReq.target_household_id;
      const userResolutions = resolutions || {};

      console.log(`Executing smart merge: ${sourceId} → ${targetId}`);

      // Re-fetch the preview to know which items are duplicates vs unique
      const cachedPreview = mergeReq.preview_data;
      if (!cachedPreview) {
        return new Response(JSON.stringify({ error: "No preview data. Call preview_merge first." }), { status: 400, headers: responseHeaders });
      }

      const { preview } = cachedPreview;

      // Save resolution choices for audit
      await supabase
        .from("household_merge_requests")
        .update({ resolution_choices: userResolutions })
        .eq("id", merge_request_id);

      // --- Helper to resolve duplicates for a given entity type ---
      async function resolveDuplicates(
        table: string,
        categoryPreview: any,
        categoryResolutions: Record<string, string> | undefined,
        propertyMapping?: Map<string, string>,
      ) {
        // 1. Move source-only items to target household
        for (const item of categoryPreview.source_only) {
          const updateData: any = { household_id: targetId };
          // Re-parent to matched property if applicable
          if (propertyMapping && item.property_id && propertyMapping.has(item.property_id)) {
            updateData.property_id = propertyMapping.get(item.property_id);
          }
          await supabase.from(table).update(updateData).eq("id", item.id);
        }

        // 2. Handle duplicates based on user resolution
        for (const dup of categoryPreview.duplicates) {
          const resolution = categoryResolutions?.[dup.source.id] || "keep_target";

          if (resolution === "keep_source") {
            // Delete target version, move source to target household
            await supabase.from(table).delete().eq("id", dup.target.id);
            const updateData: any = { household_id: targetId };
            if (propertyMapping && dup.source.property_id && propertyMapping.has(dup.source.property_id)) {
              updateData.property_id = propertyMapping.get(dup.source.property_id);
            }
            await supabase.from(table).update(updateData).eq("id", dup.source.id);
          } else {
            // keep_target (default): delete source version
            await supabase.from(table).delete().eq("id", dup.source.id);
          }
        }
      }

      // --- Execute merge in dependency order ---

      // 1. Properties first (parents of systems, tasks, service records)
      // Build property ID mapping: loser prop ID -> winner prop ID
      const propertyMapping = new Map<string, string>();
      const propResolutions = userResolutions.properties || {};

      for (const dup of preview.properties.duplicates) {
        const resolution = propResolutions[dup.source.id] || "keep_target";
        if (resolution === "keep_source") {
          propertyMapping.set(dup.target.id, dup.source.id);
        } else {
          propertyMapping.set(dup.source.id, dup.target.id);
        }
      }

      // Re-parent child records from losing properties BEFORE deleting them
      for (const [loserId, winnerId] of propertyMapping.entries()) {
        // Re-parent home_systems
        await supabase
          .from("home_systems")
          .update({ property_id: winnerId })
          .eq("property_id", loserId);

        // Re-parent maintenance_tasks
        await supabase
          .from("maintenance_tasks")
          .update({ property_id: winnerId })
          .eq("property_id", loserId);

        // Re-parent service_records (via system_id they'll follow, but also direct property references)
        await supabase
          .from("service_records")
          .update({ property_id: winnerId })
          .eq("property_id", loserId);

        // Re-parent documents linked to property
        await supabase
          .from("documents")
          .update({ property_id: winnerId })
          .eq("property_id", loserId);
      }

      // Now resolve properties
      await resolveDuplicates("properties", preview.properties, propResolutions);

      // 2. Home systems (after properties settled)
      await resolveDuplicates("home_systems", preview.home_systems, userResolutions.home_systems, propertyMapping);

      // 3. Maintenance tasks
      await resolveDuplicates("maintenance_tasks", preview.maintenance_tasks, userResolutions.maintenance_tasks, propertyMapping);

      // 4. Contractors (no property dependency)
      await resolveDuplicates("contractors", preview.contractors, userResolutions.contractors);

      // 5. Documents
      await resolveDuplicates("documents", preview.documents, userResolutions.documents);

      // 6. Family members
      await resolveDuplicates("family_members", preview.family_members, userResolutions.family_members);

      // 6.5 Move vehicles (deduplicate by VIN if both households have the same car)
      {
        const { data: sourceVehicles } = await supabase.from("vehicles").select("*").eq("household_id", sourceId);
        const { data: targetVehicles } = await supabase.from("vehicles").select("vin").eq("household_id", targetId);
        const targetVins = new Set((targetVehicles ?? []).map((v: any) => v.vin).filter(Boolean));

        for (const v of sourceVehicles ?? []) {
          if (v.vin && targetVins.has(v.vin)) {
            // Duplicate VIN — delete source vehicle (cascade deletes service records + recalls)
            await supabase.from("vehicles").delete().eq("id", v.id);
          } else {
            // Unique — move to target household
            await supabase.from("vehicles").update({ household_id: targetId }).eq("id", v.id);
          }
        }
        // Move orphaned service records and recalls
        await supabase.from("vehicle_service_records").update({ household_id: targetId }).eq("household_id", sourceId);
        await supabase.from("vehicle_recalls").update({ household_id: targetId }).eq("household_id", sourceId);
      }

      // 7. Move remaining non-preview entities (no dedup needed)
      const bulkMigrateTables = [
        "warranties", "service_records", "chat_messages", "document_content",
        "access_log", "dismissed_categories", "scenario_history", "household_invitations",
      ];

      for (const table of bulkMigrateTables) {
        const { error } = await supabase
          .from(table)
          .update({ household_id: targetId })
          .eq("household_id", sourceId);
        if (error) console.error(`Error migrating ${table}:`, error);
      }

      // 8. Delete source completion scores (will be recalculated)
      await supabase.from("completion_scores").delete().eq("household_id", sourceId);

      // 9. Move the accepting user to the target household
      const { error: userUpdateError } = await supabase
        .from("users")
        .update({ household_id: targetId })
        .eq("id", user.id);
      if (userUpdateError) console.error("Error updating user household:", userUpdateError);

      // 9b. Link the accepting user to their family_member record (by email match)
      const { data: acceptingUserData } = await supabase
        .from("users")
        .select("id, email")
        .eq("id", user.id)
        .single();

      if (acceptingUserData?.email) {
        await supabase
          .from("family_members")
          .update({ linked_user_id: user.id })
          .eq("household_id", targetId)
          .ilike("email", acceptingUserData.email);
      }

      // 9c. Also link the requester to their family_member record
      const { data: requesterData } = await supabase
        .from("users")
        .select("id, email")
        .eq("id", mergeReq.requested_by)
        .single();

      if (requesterData?.email) {
        await supabase
          .from("family_members")
          .update({ linked_user_id: mergeReq.requested_by })
          .eq("household_id", targetId)
          .ilike("email", requesterData.email);
      }

      // 10. Mark merge request as accepted
      await supabase
        .from("household_merge_requests")
        .update({ status: "accepted", resolved_at: new Date().toISOString() })
        .eq("id", merge_request_id);

      // 11. Reconcile household email addresses
      // Delete the source household's forwarding email (target keeps theirs)
      await supabase
        .from("household_email_addresses")
        .delete()
        .eq("household_id", sourceId);

      // Ensure target household has an email address
      const { data: targetEmail } = await supabase
        .from("household_email_addresses")
        .select("id")
        .eq("household_id", targetId)
        .limit(1);

      if (!targetEmail || targetEmail.length === 0) {
        await supabase
          .from("household_email_addresses")
          .insert({
            household_id: targetId,
            unique_address: targetId.substring(0, 8).toLowerCase() + "@alfred.getchez.com",
          });
      }

      // 12. Reconcile inbox items (move source inbox items to target)
      await supabase
        .from("inbox_items")
        .update({ household_id: targetId })
        .eq("household_id", sourceId);

      // 13. Soft-delete the source household
      await supabase
        .from("households")
        .update({ deactivated_at: new Date().toISOString() })
        .eq("id", sourceId);

      console.log(`Smart merge complete: ${sourceId} → ${targetId}`);

      return new Response(JSON.stringify({
        success: true,
        message: "Households merged successfully",
        target_household_id: targetId,
      }), { headers: responseHeaders });
    }

    // === ACTION: accept_merge (legacy fallback) ===
    // Backwards compat: auto-resolves all duplicates by keeping target
    if (action === "accept_merge") {
      const { data: mergeReq } = await supabase
        .from("household_merge_requests")
        .select("*")
        .eq("id", merge_request_id)
        .single();

      if (!mergeReq) {
        return new Response(JSON.stringify({ error: "Merge request not found" }), { status: 404, headers: responseHeaders });
      }

      if (mergeReq.status !== "pending") {
        return new Response(JSON.stringify({ error: "Merge request already resolved" }), { status: 400, headers: responseHeaders });
      }

      if (mergeReq.target_user_id !== user.id && mergeReq.requested_for_email !== user.email) {
        return new Response(JSON.stringify({ error: "Not authorized to accept this request" }), { status: 403, headers: responseHeaders });
      }

      const sourceId = mergeReq.source_household_id;
      const targetId = mergeReq.target_household_id;

      console.log(`Legacy merge (auto-resolve): ${sourceId} → ${targetId}`);

      // Bulk move all data, simple dedup for family members only
      const migrateTables = [
        "documents", "properties", "home_systems", "warranties", "contractors",
        "maintenance_tasks", "service_records", "chat_messages", "document_content",
        "access_log", "dismissed_categories", "scenario_history", "household_invitations",
      ];

      for (const table of migrateTables) {
        const { error } = await supabase
          .from(table)
          .update({ household_id: targetId })
          .eq("household_id", sourceId);
        if (error) console.error(`Error migrating ${table}:`, error);
      }

      await supabase.from("completion_scores").delete().eq("household_id", sourceId);

      // Family members: simple name-based dedup
      const { data: targetMembers } = await supabase
        .from("family_members").select("*").eq("household_id", targetId);
      const { data: sourceMembers } = await supabase
        .from("family_members").select("*").eq("household_id", sourceId);

      if (sourceMembers) {
        const targetNames = new Set(
          (targetMembers || []).map((m: any) =>
            `${m.first_name.toLowerCase()}_${m.last_name.toLowerCase()}`
          )
        );
        for (const member of sourceMembers) {
          const nameKey = `${member.first_name.toLowerCase()}_${member.last_name.toLowerCase()}`;
          if (targetNames.has(nameKey)) {
            await supabase.from("family_members").delete().eq("id", member.id);
          } else {
            await supabase.from("family_members").update({ household_id: targetId }).eq("id", member.id);
          }
        }
      }

      await supabase.from("users").update({ household_id: targetId }).eq("id", user.id);

      // Link both users to their family_member records
      const { data: acceptingUser } = await supabase
        .from("users").select("id, email").eq("id", user.id).single();
      if (acceptingUser?.email) {
        await supabase.from("family_members")
          .update({ linked_user_id: user.id })
          .eq("household_id", targetId)
          .ilike("email", acceptingUser.email);
      }
      const { data: requester } = await supabase
        .from("users").select("id, email").eq("id", mergeReq.requested_by).single();
      if (requester?.email) {
        await supabase.from("family_members")
          .update({ linked_user_id: mergeReq.requested_by })
          .eq("household_id", targetId)
          .ilike("email", requester.email);
      }

      await supabase
        .from("household_merge_requests")
        .update({ status: "accepted", resolved_at: new Date().toISOString() })
        .eq("id", merge_request_id);

      // Reconcile household email addresses
      await supabase
        .from("household_email_addresses")
        .delete()
        .eq("household_id", sourceId);

      const { data: targetEmailLegacy } = await supabase
        .from("household_email_addresses")
        .select("id")
        .eq("household_id", targetId)
        .limit(1);

      if (!targetEmailLegacy || targetEmailLegacy.length === 0) {
        await supabase
          .from("household_email_addresses")
          .insert({
            household_id: targetId,
            unique_address: targetId.substring(0, 8).toLowerCase() + "@alfred.getchez.com",
          });
      }

      // Move inbox items to target
      await supabase
        .from("inbox_items")
        .update({ household_id: targetId })
        .eq("household_id", sourceId);

      // Soft-delete source household
      await supabase
        .from("households")
        .update({ deactivated_at: new Date().toISOString() })
        .eq("id", sourceId);

      console.log(`Legacy merge complete: ${sourceId} → ${targetId}`);

      return new Response(JSON.stringify({
        success: true,
        message: "Households merged successfully",
        target_household_id: targetId,
      }), { headers: responseHeaders });
    }

    // === ACTION: decline_merge ===
    if (action === "decline_merge") {
      await supabase
        .from("household_merge_requests")
        .update({ status: "declined", resolved_at: new Date().toISOString() })
        .eq("id", merge_request_id);

      return new Response(JSON.stringify({ success: true }), { headers: responseHeaders });
    }

    // === ACTION: check_pending_merges ===
    if (action === "check_pending_merges") {
      const { data: pending } = await supabase
        .from("household_merge_requests")
        .select("*")
        .or(`target_user_id.eq.${user.id},requested_for_email.eq.${user.email}`)
        .eq("status", "pending")
        .order("created_at", { ascending: false })
        .limit(1);

      return new Response(JSON.stringify({
        has_pending: pending && pending.length > 0,
        merge_request: pending?.[0] || null,
      }), { headers: responseHeaders });
    }

    return new Response(
      JSON.stringify({ error: "Unknown action" }),
      { status: 400, headers: responseHeaders }
    );

  } catch (error) {
    console.error("merge-households error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

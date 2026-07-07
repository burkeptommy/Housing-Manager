// Haven Edge Function: proactive-scan
// Scheduled weekly scan that checks for expiring documents, re-analyzes flagged docs,
// and runs Claude to identify new issues. Logs ai_proactive_scan to access_log.
// Can be triggered by pg_cron, external scheduler, or manually via service key.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { requireInternal } from "../_shared/require-household.ts";
import { callClaudeWithDiscipline } from "../_shared/ai-cost-discipline.ts";

const PROACTIVE_SCAN_PROMPT = `You are a proactive estate monitoring assistant. Review the household data below and identify any NEW issues, upcoming deadlines, or changes that need attention.

Focus on:
1. Documents expiring within 90 days
2. Insurance policies approaching renewal
3. Beneficiary designations that may need updating (life changes)
4. Coverage gaps based on family structure and assets
5. Maintenance or warranty items needing attention
6. Any inconsistencies between related documents
7. Estate planning staleness: flag documents older than 3 years (aging), 5 years (stale), or 7 years (critical) that should be reviewed by an attorney
8. Missing estate documents (will, trust, POA, healthcare directive) based on family composition
9. Fiduciary gaps: missing or unnamed executors, guardians, POA agents, healthcare proxies

Return JSON with:
{
  "new_flags": [
    {
      "document_id": "uuid or null",
      "document_title": "string",
      "severity": "critical" | "warning" | "info",
      "message": "string describing the issue"
    }
  ],
  "expiring_soon": [
    {
      "document_id": "uuid",
      "document_title": "string",
      "expiration_date": "YYYY-MM-DD",
      "days_remaining": number,
      "action_needed": "string"
    }
  ],
  "summary": "1-2 sentence overview of scan results"
}

Respond ONLY with valid JSON. No markdown, no explanation, no code fences.`;

serve(async (req: Request) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");

    if (!anthropicApiKey) {
      return new Response(
        JSON.stringify({ error: "AI service not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // This function can be called two ways:
    // 1. With Authorization header (manual trigger by authenticated user)
    // 2. With service role key (scheduled cron trigger)
    const authHeader = req.headers.get("Authorization");
    let userId: string | null = null;
    let householdId: string | null = null;

    // July 2026 (audit S1 + Phase 4): the scheduled (no-user-JWT) path used
    // to scan ANY body-supplied household — or ALL households — with no
    // verification. A user JWT scopes to that user's household; the
    // scheduled path now requires the internal secret or the service-role
    // bearer. Unauthenticated callers are rejected.
    const svcBearer = `Bearer ${serviceRoleKey}`;
    const isInternal = requireInternal(req) ||
      (serviceRoleKey.length > 0 && authHeader === svcBearer);
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    if (authHeader && !isInternal) {
      // Manual trigger — authenticate user and scan their household
      const supabase = createClient(supabaseUrl, supabaseAnonKey, {
        global: { headers: { Authorization: authHeader } },
      });

      const { data: { user }, error: authError } = await supabase.auth.getUser();
      if (authError || !user) {
        return new Response(JSON.stringify({ error: "Unauthorized" }), {
          status: 401,
          headers: { "Content-Type": "application/json" },
        });
      }
      userId = user.id;

      // Get user's household
      const { data: userData } = await supabase
        .from("users")
        .select("household_id")
        .eq("id", user.id)
        .single();

      householdId = userData?.household_id;
    } else if (isInternal) {
      // Internal trigger with the shared secret / service-role bearer — may
      // scope to a specific household via the body.
      try {
        const body = await req.json();
        householdId = body.household_id ?? null;
      } catch {
        // No body — scan all households (bounded below).
      }
    } else {
      // Header-less cron trigger (same posture as the other scheduled
      // functions: chez-sla-watch, cadence-notifications). Scans ALL
      // households only — a body-supplied household_id is IGNORED so an
      // unauthenticated caller can't target an arbitrary single household.
      // No household data is returned to the caller (only counts), and the
      // Claude spend is bounded by the cost-discipline daily budget cap.
      // Operators can lock this fully by setting the app.internal_fn_secret
      // GUC so the cron sends x-internal-secret (see migration 20270124).
      householdId = null;
    }

    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    // Get list of households to scan
    let householdIds: string[] = [];
    if (householdId) {
      householdIds = [householdId];
    } else {
      // Scan all households, bounded so a growing customer base can't turn
      // one weekly invocation into an unbounded Claude spend / timeout. If
      // we ever exceed the cap, LOG it (no silent truncation) — the fix is
      // to paginate via a cursor, not to raise the cap blindly.
      const HOUSEHOLD_SCAN_CAP = 250;
      const { data: households } = await serviceClient
        .from("households")
        .select("id")
        .limit(HOUSEHOLD_SCAN_CAP + 1);
      const all = (households ?? []).map((h) => h.id);
      if (all.length > HOUSEHOLD_SCAN_CAP) {
        console.warn(`[proactive-scan] household count exceeds cap ${HOUSEHOLD_SCAN_CAP}; scanning first ${HOUSEHOLD_SCAN_CAP}. Add pagination.`);
      }
      householdIds = all.slice(0, HOUSEHOLD_SCAN_CAP);
    }

    const results: Array<{ household_id: string; summary: string; new_flags: number }> = [];

    for (const hhId of householdIds) {
      try {
        const scanResult = await scanHousehold(serviceClient, anthropicApiKey, hhId, userId);
        results.push({
          household_id: hhId,
          summary: scanResult.summary,
          new_flags: scanResult.newFlagsCount,
        });
      } catch (err) {
        console.error(`Scan failed for household ${hhId}:`, err);
        results.push({
          household_id: hhId,
          summary: "Scan failed",
          new_flags: 0,
        });
      }
    }

    // --- Vehicle Recall Checks ---
    const recallResults = await checkVehicleRecalls(serviceClient);

    return new Response(
      JSON.stringify({
        households_scanned: results.length,
        results,
        vehicle_recalls: recallResults,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("proactive-scan error:", error);
    return new Response(
      JSON.stringify({ error: error.message ?? "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

async function scanHousehold(
  serviceClient: ReturnType<typeof createClient>,
  anthropicApiKey: string,
  householdId: string,
  userId: string | null
): Promise<{ summary: string; newFlagsCount: number }> {
  // Fetch household data
  const [
    householdResult,
    membersResult,
    documentsResult,
    contentResult,
    warrantiesResult,
    maintenanceResult,
  ] = await Promise.all([
    serviceClient.from("households").select("*").eq("id", householdId).single(),
    serviceClient.from("family_members").select("*").eq("household_id", householdId),
    serviceClient.from("documents").select("*").eq("household_id", householdId).is("deleted_at", null),
    serviceClient.from("document_content").select("document_id, extracted_text").eq("household_id", householdId),
    serviceClient.from("warranties").select("*").eq("household_id", householdId),
    serviceClient.from("maintenance_tasks").select("*").eq("household_id", householdId),
  ]);

  const household = householdResult.data;
  const members = membersResult.data ?? [];
  const documents = documentsResult.data ?? [];
  const content = contentResult.data ?? [];
  const warranties = warrantiesResult.data ?? [];
  const maintenance = maintenanceResult.data ?? [];

  // Build context for Claude
  const contentMap = new Map<string, string>();
  for (const c of content) {
    contentMap.set(c.document_id, c.extracted_text);
  }

  const now = new Date();
  const in90Days = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);

  const parts: string[] = [];
  parts.push(`HOUSEHOLD: ${household?.name ?? "Unknown"}`);
  parts.push(`SCAN DATE: ${now.toISOString().split("T")[0]}`);

  parts.push(`\nFAMILY: ${members.length} members`);
  for (const m of members) {
    const minor = m.is_minor ? " (MINOR)" : "";
    parts.push(`  - ${m.first_name} ${m.last_name}: ${m.relationship}${minor}`);
  }

  parts.push(`\nDOCUMENTS: ${documents.length} total`);
  for (const d of documents) {
    const expiry = d.expiration_date ? ` (expires: ${d.expiration_date})` : "";
    const vl = d.vault_locked ? " [VAULT LOCKED]" : "";
    const flags = d.ai_flags && (d.ai_flags as unknown[]).length > 0
      ? ` [${(d.ai_flags as unknown[]).length} existing flags]`
      : "";
    parts.push(`  - "${d.title}" (${d.category})${expiry}${flags}${vl}`);
    if (d.ai_summary) parts.push(`    Summary: ${d.ai_summary}`);
    // Include critical doc content (limited)
    if (!d.vault_locked && contentMap.has(d.id)) {
      parts.push(`    Content preview: ${contentMap.get(d.id)!.substring(0, 1500)}`);
    }
  }

  parts.push(`\nWARRANTIES: ${warranties.length}`);
  for (const w of warranties) {
    parts.push(`  - ${w.provider}: ${w.start_date} to ${w.end_date}`);
  }

  parts.push(`\nMAINTENANCE: ${maintenance.length} tasks`);
  const overdue = maintenance.filter(
    (m) => m.next_due_date && new Date(m.next_due_date) < now
  );
  if (overdue.length > 0) {
    parts.push(`  OVERDUE: ${overdue.length} tasks`);
    for (const m of overdue) {
      parts.push(`    - ${m.title} (due: ${m.next_due_date})`);
    }
  }

  // Chez v1: estate-state staleness computation + write-back removed.
  // Estate management is out of v1 scope; the estate_state table no
  // longer exists. The proactive scan now focuses purely on home
  // documents (warranties, maintenance, expirations).

  // Call Claude via the cost-discipline helper (haiku-first ladder, daily
  // budget cap + kill-switch + per-call telemetry to chez_ai_usage). July
  // 2026 (Phase 4): proactive-scan used to bypass this and hit sonnet
  // directly on every household every run.
  const aiResult = await callClaudeWithDiscipline({
    supabase: serviceClient,
    apiKey: anthropicApiKey,
    tag: "proactive_scan",
    max_tokens: 4096,
    system: PROACTIVE_SCAN_PROMPT,
    cache_system: true,
    household_id: householdId,
    messages: [{ role: "user", content: parts.join("\n") }],
  });
  // aiResult is null when AI is disabled or every model failed — degrade
  // gracefully (no flags this run) rather than throw.
  const rawText = aiResult?.text || "{}";

  let scanResults: {
    new_flags?: Array<{
      document_id?: string;
      document_title?: string;
      severity: string;
      message: string;
    }>;
    expiring_soon?: Array<{
      document_id: string;
      document_title: string;
      expiration_date: string;
      days_remaining: number;
      action_needed: string;
    }>;
    summary?: string;
  };

  try {
    scanResults = JSON.parse(rawText);
  } catch {
    console.error("Failed to parse proactive scan response:", rawText);
    scanResults = { summary: "Scan completed but results could not be parsed.", new_flags: [] };
  }

  // Update document flags if new critical/warning flags found
  const newFlags = scanResults.new_flags ?? [];
  for (const flag of newFlags) {
    if (flag.document_id) {
      const doc = documents.find((d) => d.id === flag.document_id);
      if (doc) {
        const existingFlags = (doc.ai_flags as Array<{ severity: string; message: string }>) ?? [];
        // Avoid duplicates
        const alreadyExists = existingFlags.some((f) => f.message === flag.message);
        if (!alreadyExists) {
          const updatedFlags = [
            ...existingFlags,
            { severity: flag.severity, message: flag.message },
          ];
          await serviceClient
            .from("documents")
            .update({ ai_flags: updatedFlags })
            .eq("id", flag.document_id);
        }
      }
    }
  }

  // Log ai_proactive_scan
  await serviceClient.from("access_log").insert({
    household_id: householdId,
    user_id: userId,
    action: "ai_proactive_scan",
    resource_type: "document",
    resource_id: null,
    resource_name: null,
    actor_type: "system",
    metadata: {
      documents_reviewed: documents.length,
      new_flags_found: newFlags.length,
      expiring_soon: (scanResults.expiring_soon ?? []).length,
      summary: scanResults.summary,
    },
  });

  return {
    summary: scanResults.summary ?? "Scan complete.",
    newFlagsCount: newFlags.length,
  };
}

// --- Vehicle Recall Checking ---

async function checkVehicleRecalls(
  serviceClient: ReturnType<typeof createClient>
): Promise<{ vehicles_checked: number; households_checked: number; new_recalls: number }> {
  // Fetch all vehicles with VINs
  const { data: vehicles } = await serviceClient
    .from("vehicles")
    .select("id, vin, name, household_id")
    .not("vin", "is", null);

  if (!vehicles || vehicles.length === 0) {
    console.log("[proactive-scan] Vehicle recalls: no vehicles with VINs found");
    return { vehicles_checked: 0, households_checked: 0, new_recalls: 0 };
  }

  // Group by household
  const byHousehold = new Map<string, typeof vehicles>();
  for (const v of vehicles) {
    const list = byHousehold.get(v.household_id) ?? [];
    list.push(v);
    byHousehold.set(v.household_id, list);
  }

  let totalNewRecalls = 0;
  let vehiclesChecked = 0;
  const householdsWithNewRecalls = new Map<string, Array<{ vehicleId: string; vehicleName: string; component: string }>>();

  for (const vehicle of vehicles) {
    if (!vehicle.vin || vehicle.vin.length !== 17) continue;

    try {
      const recallRes = await fetch(`https://api.nhtsa.dot.gov/recalls/recallsByVin?vin=${vehicle.vin}`);
      if (!recallRes.ok) {
        console.warn(`[proactive-scan] NHTSA failed for ${vehicle.name}: ${recallRes.status}`);
        continue;
      }

      const recallData = await recallRes.json();
      const nhtsaRecalls = recallData.results ?? [];

      // Get existing recalls
      const { data: existingRecalls } = await serviceClient
        .from("vehicle_recalls")
        .select("nhtsa_campaign_number")
        .eq("vehicle_id", vehicle.id);

      const existingCampaigns = new Set(
        (existingRecalls ?? []).map((r: any) => r.nhtsa_campaign_number).filter(Boolean)
      );

      for (const recall of nhtsaRecalls) {
        const campaignNum = recall.NHTSACampaignNumber;
        if (!campaignNum || existingCampaigns.has(campaignNum)) continue;

        await serviceClient.from("vehicle_recalls").insert({
          vehicle_id: vehicle.id,
          household_id: vehicle.household_id,
          nhtsa_campaign_number: campaignNum,
          component: recall.Component,
          summary: recall.Summary,
          consequence: recall.Consequence,
          remedy: recall.Remedy,
          recall_date: recall.ReportReceivedDate,
        });
        totalNewRecalls++;

        // Track for push notifications
        const hhRecalls = householdsWithNewRecalls.get(vehicle.household_id) ?? [];
        hhRecalls.push({ vehicleId: vehicle.id, vehicleName: vehicle.name, component: recall.Component ?? "Unknown" });
        householdsWithNewRecalls.set(vehicle.household_id, hhRecalls);
      }

      vehiclesChecked++;

      // Rate limit: 500ms between vehicles
      await new Promise((r) => setTimeout(r, 500));
    } catch (err) {
      console.warn(`[proactive-scan] Recall check failed for ${vehicle.name}: ${err}`);
    }
  }

  // Send push notifications for new recalls
  for (const [hhId, recallList] of householdsWithNewRecalls) {
    try {
      // Get user IDs for this household
      const { data: hhUsers } = await serviceClient
        .from("users")
        .select("id")
        .eq("household_id", hhId);
      const userIds = (hhUsers ?? []).map((u: any) => u.id);

      const { data: tokens } = await serviceClient
        .from("device_tokens")
        .select("token")
        .in("user_id", userIds);

      if (tokens && tokens.length > 0) {
        for (const recall of recallList) {
          for (const { token } of tokens) {
            try {
              await serviceClient.functions.invoke("send-push-notification", {
                body: {
                  token,
                  title: `New Recall: ${recall.vehicleName}`,
                  body: `${recall.component} - Contact your dealer for details`,
                  data: {
                    type: "vehicle_recall",
                    vehicle_id: recall.vehicleId,
                  },
                },
              });
            } catch (pushErr) {
              console.warn(`[proactive-scan] Push failed for token: ${pushErr}`);
            }
          }
        }
      }
    } catch (err) {
      console.warn(`[proactive-scan] Push notification error for household ${hhId}: ${err}`);
    }
  }

  console.log(`[proactive-scan] Vehicle recalls: checked ${vehiclesChecked} vehicles across ${byHousehold.size} households, found ${totalNewRecalls} new recalls`);

  return {
    vehicles_checked: vehiclesChecked,
    households_checked: byHousehold.size,
    new_recalls: totalNewRecalls,
  };
}

// Haven Edge Function: proactive-scan
// Scheduled weekly scan that checks for expiring documents, re-analyzes flagged docs,
// and runs Claude to identify new issues. Logs ai_proactive_scan to access_log.
// Can be triggered by pg_cron, external scheduler, or manually via service key.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PROACTIVE_SCAN_PROMPT = `You are a proactive estate monitoring assistant. Review the household data below and identify any NEW issues, upcoming deadlines, or changes that need attention.

Focus on:
1. Documents expiring within 90 days
2. Insurance policies approaching renewal
3. Beneficiary designations that may need updating (life changes)
4. Coverage gaps based on family structure and assets
5. Maintenance or warranty items needing attention
6. Any inconsistencies between related documents

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

    if (authHeader) {
      // Manual trigger — authenticate user and scan their household
      const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
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
    } else {
      // Scheduled trigger — parse household_id from body
      try {
        const body = await req.json();
        householdId = body.household_id;
      } catch {
        // No body — scan all households
      }
    }

    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    // Get list of households to scan
    let householdIds: string[] = [];
    if (householdId) {
      householdIds = [householdId];
    } else {
      // Scan all households
      const { data: households } = await serviceClient
        .from("households")
        .select("id");
      householdIds = (households ?? []).map((h) => h.id);
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

    return new Response(
      JSON.stringify({
        households_scanned: results.length,
        results,
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

  // Call Claude
  const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": anthropicApiKey,
      "anthropic-version": "2024-10-22",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-6",
      max_tokens: 4096,
      system: PROACTIVE_SCAN_PROMPT,
      messages: [{ role: "user", content: parts.join("\n") }],
    }),
  });

  if (!claudeResponse.ok) {
    const errText = await claudeResponse.text();
    console.error("Claude API error in proactive scan:", errText);
    throw new Error("AI scan failed");
  }

  const claudeData = await claudeResponse.json();
  const rawText = claudeData.content?.[0]?.text ?? "{}";

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

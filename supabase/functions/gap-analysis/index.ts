// Haven Edge Function: gap-analysis
// Fetches full household inventory + document content, calls Claude for comprehensive gap analysis,
// returns structured results and updates completion_scores table.
// Logs ai_gap_analysis to access_log.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers for all responses
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface GapAnalysisRequest {
  household_id: string;
  user_id?: string;
}

const GAP_ANALYSIS_PROMPT = `You are an estate organization expert analyzing a family's complete document portfolio. Given the household data below, perform a thorough gap analysis and return a JSON response.

Analyze and return ONLY valid JSON (no markdown fences, no explanation) with:

1. "overall_readiness_score" — Integer 0-100 representing estate readiness
2. "summary" — A 2-3 sentence overview of the household's estate readiness
3. "missing_critical_documents" — Array of documents that SHOULD exist based on family structure but don't:
   - Consider: number of properties (need deed, insurance, title for each), number of family members (need individual documents), business entities, minor children (need guardianship designation), etc.
   - Each entry: { "category": string, "reason": string, "priority": "critical"|"high"|"medium" }
4. "inconsistencies" — Array of cross-document issues:
   - Beneficiary mismatches between trusts and account designations
   - Assets not titled to trust when a trust exists
   - Insurance coverage gaps (e.g., no umbrella policy with multiple properties)
   - Expired or outdated documents
   - Each entry: { "severity": "critical"|"warning"|"info", "message": string, "related_documents": string[], "recommended_action": string }
5. "upcoming_actions" — Array of time-sensitive items:
   - Documents expiring within 90 days
   - Insurance renewals approaching
   - Recommended review dates
   - Each entry: { "action": string, "due_date": "YYYY-MM-DD" or null, "priority": "critical"|"high"|"medium" }
6. "recommendations" — Array of general advice:
   - Missing protections common for families of this size/complexity
   - Organizational improvements
   - Each entry: { "title": string, "description": string, "priority": "critical"|"high"|"medium" }
7. "section_scores" — Object mapping section group names to { "score": 0-100, "actual": int, "expected": int }. Sections: "Estate Planning", "Entity Documents", "Real Estate", "Insurance", "Financial Accounts", "Tax Records", "Personal Property", "Digital Assets", "Personal Identification", "Professional & Business"

CRITICAL: Respond with ONLY the JSON object. No markdown code fences. No explanation text before or after.`;

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const responseHeaders = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    // === Validate environment variables ===
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { status: 500, headers: responseHeaders }
      );
    }

    if (!anthropicApiKey) {
      console.error("ANTHROPIC_API_KEY is not set in Supabase secrets!");
      return new Response(
        JSON.stringify({ error: "AI service not configured", detail: "ANTHROPIC_API_KEY is not set" }),
        { status: 500, headers: responseHeaders }
      );
    }

    if (!serviceRoleKey) {
      console.error("SUPABASE_SERVICE_ROLE_KEY is not set");
      return new Response(
        JSON.stringify({ error: "Server configuration error", detail: "Missing service role key" }),
        { status: 500, headers: responseHeaders }
      );
    }

    // === Authenticate user ===
    const authHeader = req.headers.get("Authorization");

    let userId: string | null = null;
    let supabase;

    if (authHeader) {
      supabase = createClient(supabaseUrl, supabaseAnonKey, {
        global: { headers: { Authorization: authHeader } },
      });

      try {
        const { data: { user }, error: authError } = await supabase.auth.getUser();
        if (user && !authError) {
          userId = user.id;
          console.log("Authenticated via JWT:", userId);
        } else {
          console.warn("JWT auth failed:", authError?.message, "- will try service client");
        }
      } catch (authErr) {
        console.warn("JWT auth threw:", authErr, "- will try service client");
      }
    }

    // If JWT auth failed, create client with service role for DB operations
    if (!supabase || !userId) {
      console.log("Using service client fallback for auth");
      supabase = createClient(supabaseUrl, serviceRoleKey);
    }

    const body: GapAnalysisRequest = await req.json();
    const householdId = body.household_id;

    // Use JWT-authenticated userId, or fall back to body-provided userId
    if (!userId && body.user_id) {
      userId = body.user_id;
      console.log("Using body-provided user_id:", userId);
    }

    // Service client for document_content access and logging
    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    // Fetch household data via the user-scoped supabase client (RLS
    // enforced) — but document_content is fetched in a SECOND pass
    // gated by the visible doc IDs from the first query, since
    // document_content goes through serviceClient (RLS bypassed) and
    // needs explicit gating.
    const [
      householdResult,
      membersResult,
      propertiesResult,
      documentsResult,
      systemsResult,
      warrantiesResult,
      maintenanceResult,
    ] = await Promise.all([
      supabase.from("households").select("*").eq("id", householdId).single(),
      supabase.from("family_members").select("*").eq("household_id", householdId),
      supabase.from("properties").select("*").eq("household_id", householdId),
      supabase.from("documents").select("*").eq("household_id", householdId).is("deleted_at", null),
      supabase.from("home_systems").select("*").eq("household_id", householdId),
      supabase.from("warranties").select("*").eq("household_id", householdId),
      supabase.from("maintenance_tasks").select("*").eq("household_id", householdId),
    ]);

    const household = householdResult.data;
    const members = membersResult.data ?? [];
    const properties = propertiesResult.data ?? [];
    const documents = documentsResult.data ?? [];
    const systems = systemsResult.data ?? [];
    const warranties = warrantiesResult.data ?? [];
    const maintenance = maintenanceResult.data ?? [];

    // Build 87 (Home Manager expansion): gate the document_content fetch
    // by IDs the caller can actually see. The `documents` array above
    // came through the user-scoped supabase client so it's already
    // RLS-filtered. Without this `.in()` filter, gap-analysis would feed
    // private estate / financial / medical content into Claude's prompt
    // for home managers.
    const visibleDocIds = (documents as Array<Record<string, unknown>>)
      .map((d) => d.id as string)
      .filter((id) => !!id);
    const documentContent = visibleDocIds.length > 0
      ? ((await serviceClient
          .from("document_content")
          .select("document_id, extracted_text")
          .eq("household_id", householdId)
          .in("document_id", visibleDocIds)).data ?? [])
      : [];

    // Build comprehensive household data string for Claude
    const householdData = buildHouseholdDataString(
      household,
      members,
      properties,
      documents,
      systems,
      warranties,
      maintenance,
      documentContent
    );

    // Call Claude API
    console.log("Calling Claude API for gap analysis with model claude-sonnet-4-6...");

    let claudeResponse: Response;
    try {
      claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": anthropicApiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: 8192,
          system: GAP_ANALYSIS_PROMPT,
          messages: [
            {
              role: "user",
              content: `HOUSEHOLD DATA:\n\n${householdData}`,
            },
          ],
        }),
        signal: AbortSignal.timeout(120000),
      });
    } catch (fetchError) {
      const isTimeout = fetchError.name === "TimeoutError" || fetchError.name === "AbortError";
      console.error("Fetch to Claude API failed:", fetchError.name, fetchError.message);
      return new Response(
        JSON.stringify({
          error: isTimeout ? "Gap analysis timed out. Please try again." : "Failed to reach AI service",
        }),
        { status: isTimeout ? 504 : 502, headers: responseHeaders }
      );
    }

    if (!claudeResponse.ok) {
      const errorText = await claudeResponse.text();
      console.error(`Claude API returned ${claudeResponse.status}: ${errorText}`);

      let errorDetail = "AI analysis failed";
      switch (claudeResponse.status) {
        case 401:
          errorDetail = "AI service authentication failed. Check ANTHROPIC_API_KEY.";
          break;
        case 429:
          errorDetail = "Too many requests. Please wait a moment and try again.";
          break;
        default:
          try {
            const parsed = JSON.parse(errorText);
            if (parsed.error?.message) errorDetail = parsed.error.message;
          } catch {}
      }

      return new Response(
        JSON.stringify({ error: errorDetail, claude_status: claudeResponse.status }),
        { status: 502, headers: responseHeaders }
      );
    }

    const claudeData = await claudeResponse.json();
    const rawText = claudeData.content?.[0]?.text ?? "";

    // Parse Claude's response — strip markdown fences if present
    let analysis: Record<string, unknown>;
    try {
      let cleanedText = rawText.trim();
      if (cleanedText.startsWith("```json")) {
        cleanedText = cleanedText.slice(7);
      } else if (cleanedText.startsWith("```")) {
        cleanedText = cleanedText.slice(3);
      }
      if (cleanedText.endsWith("```")) {
        cleanedText = cleanedText.slice(0, -3);
      }
      cleanedText = cleanedText.trim();

      analysis = JSON.parse(cleanedText);
    } catch {
      console.error("Failed to parse gap analysis response:", rawText.substring(0, 500));
      return new Response(
        JSON.stringify({ error: "Failed to parse AI analysis results" }),
        { status: 500, headers: responseHeaders }
      );
    }

    // Update completion_scores table with section scores
    const sectionScores = analysis.section_scores as Record<
      string,
      { score: number; actual: number; expected: number }
    > | undefined;

    if (sectionScores) {
      const upserts = Object.entries(sectionScores).map(
        ([category, scores]) => ({
          household_id: householdId,
          category,
          expected_count: scores.expected,
          actual_count: scores.actual,
          completion_percentage: scores.score,
          last_calculated_at: new Date().toISOString(),
        })
      );

      for (const upsert of upserts) {
        try {
          await supabase
            .from("completion_scores")
            .upsert(upsert, { onConflict: "household_id,category" });
        } catch (upsertErr) {
          console.warn("Failed to upsert completion score:", upsertErr);
        }
      }
    }

    // Log ai_gap_analysis to access_log
    try {
      const analyzedDocIds = documentContent.map((dc) => dc.document_id);
      await serviceClient.from("access_log").insert({
        household_id: householdId,
        user_id: userId ?? null,
        action: "ai_gap_analysis",
        resource_type: "document",
        resource_id: null,
        resource_name: null,
        actor_type: "ai_analysis",
        metadata: {
          model: "claude-sonnet-4-6",
          documents_analyzed: analyzedDocIds.length,
          overall_readiness_score: analysis.overall_readiness_score,
          vault_locked_excluded: documents.filter((d) => d.vault_locked === true).length,
        },
      });
    } catch (logErr) {
      console.warn("Failed to log gap analysis:", logErr);
    }

    // Transform response for iOS client
    const criticalGaps = [
      ...((analysis.missing_critical_documents as Array<Record<string, string>>) ?? [])
        .filter((d) => d.priority === "critical")
        .map((d) => ({
          title: `Missing: ${d.category}`,
          description: d.reason,
        })),
      ...((analysis.inconsistencies as Array<Record<string, unknown>>) ?? [])
        .filter((i) => i.severity === "critical")
        .map((i) => ({
          title: "Critical Issue",
          description: i.message as string,
        })),
    ];

    const warnings = [
      ...((analysis.missing_critical_documents as Array<Record<string, string>>) ?? [])
        .filter((d) => d.priority === "high")
        .map((d) => ({
          title: `Missing: ${d.category}`,
          description: d.reason,
        })),
      ...((analysis.inconsistencies as Array<Record<string, unknown>>) ?? [])
        .filter((i) => i.severity === "warning")
        .map((i) => ({
          title: "Warning",
          description: i.message as string,
        })),
      ...((analysis.upcoming_actions as Array<Record<string, string>>) ?? []).map(
        (a) => ({
          title: a.action,
          description: a.due_date ? `Due: ${a.due_date}` : "Action needed",
        })
      ),
    ];

    const recommendations = (
      (analysis.recommendations as Array<Record<string, string>>) ?? []
    ).map((r) => ({
      title: r.title,
      description: r.description,
    }));

    const clientResponse = {
      summary: (analysis.summary as string) ?? "Analysis complete.",
      overall_readiness_score: (analysis.overall_readiness_score as number) ?? 0,
      critical_gaps: criticalGaps,
      warnings,
      recommendations,
      section_scores: sectionScores ?? {},
    };

    return new Response(JSON.stringify(clientResponse), {
      status: 200,
      headers: responseHeaders,
    });
  } catch (error) {
    console.error("gap-analysis error:", error);
    return new Response(
      JSON.stringify({ error: error.message ?? "Internal server error" }),
      { status: 500, headers: responseHeaders }
    );
  }
});

function buildHouseholdDataString(
  household: Record<string, unknown> | null,
  members: Array<Record<string, unknown>>,
  properties: Array<Record<string, unknown>>,
  documents: Array<Record<string, unknown>>,
  systems: Array<Record<string, unknown>>,
  warranties: Array<Record<string, unknown>>,
  maintenance: Array<Record<string, unknown>>,
  documentContent: Array<{ document_id: string; extracted_text: string }>
): string {
  const parts: string[] = [];

  // Build a map of document_id -> extracted_text for quick lookup
  const contentMap = new Map<string, string>();
  for (const dc of documentContent) {
    contentMap.set(dc.document_id, dc.extracted_text);
  }

  // Household
  parts.push(`HOUSEHOLD: ${household?.name ?? "Unknown"}`);

  // Family members
  parts.push("\nFAMILY MEMBERS:");
  if (members.length === 0) {
    parts.push("  No family members added.");
  } else {
    for (const m of members) {
      const age = m.date_of_birth
        ? `, age ${calculateAge(m.date_of_birth as string)}`
        : "";
      const minor = m.is_minor ? " (MINOR)" : "";
      parts.push(
        `  - ${m.first_name} ${m.last_name}: ${m.relationship}${age}${minor}`
      );
    }
  }

  // Properties
  parts.push("\nPROPERTIES:");
  if (properties.length === 0) {
    parts.push("  No properties added.");
  } else {
    for (const p of properties) {
      const addr = [p.street, p.city, p.state].filter(Boolean).join(", ");
      const propSystems = systems.filter((s) => s.property_id === p.id);
      const propMaint = maintenance.filter((m) => m.property_id === p.id);
      parts.push(
        `  - ${p.name} (${p.property_type}): ${addr || "No address"}`
      );
      parts.push(`    Systems: ${propSystems.length}`);
      parts.push(`    Maintenance tasks: ${propMaint.length}`);
    }
  }

  // Chez v1: estate-state injection removed. Estate management is out of
  // v1 scope and the estate_state table has been dropped.

  // Documents by category — now includes extracted text for critical documents
  parts.push("\nDOCUMENTS:");
  if (documents.length === 0) {
    parts.push("  No documents uploaded.");
  } else {
    // Critical categories where full text is most valuable for gap analysis
    const criticalCategories = new Set([
      "Will", "Trust", "Power of Attorney", "Healthcare Directive",
      "Guardianship Designation", "Life Insurance", "Umbrella Insurance",
      "Beneficiary Designation", "Deed",
    ]);

    const grouped = new Map<string, Array<Record<string, unknown>>>();
    for (const d of documents) {
      const cat = d.category as string;
      if (!grouped.has(cat)) grouped.set(cat, []);
      grouped.get(cat)!.push(d);
    }
    for (const [category, docs] of grouped.entries()) {
      parts.push(`  ${category}: ${docs.length} document(s)`);
      for (const d of docs) {
        const flags =
          d.ai_flags && (d.ai_flags as unknown[]).length > 0
            ? ` [${(d.ai_flags as unknown[]).length} flag(s)]`
            : "";
        const expiry = d.expiration_date
          ? ` (expires: ${d.expiration_date})`
          : "";
        const vaultLocked = d.vault_locked === true
          ? " [VAULT LOCKED — content not available for analysis]"
          : "";
        parts.push(`    - "${d.title}"${expiry}${flags}${vaultLocked}`);
        if (d.ai_summary) {
          parts.push(`      AI Summary: ${d.ai_summary}`);
        }
        // Include extracted text for critical categories (not vault-locked)
        if (
          criticalCategories.has(category) &&
          d.vault_locked !== true &&
          contentMap.has(d.id as string)
        ) {
          const text = contentMap.get(d.id as string)!;
          // Limit to 3000 chars per document to stay within context
          parts.push(`      Extracted Content: ${text.substring(0, 3000)}`);
        }
      }
    }
  }

  // Warranties
  parts.push("\nWARRANTIES:");
  if (warranties.length === 0) {
    parts.push("  No warranties tracked.");
  } else {
    for (const w of warranties) {
      parts.push(
        `  - ${w.provider} (${w.warranty_type}): ${w.start_date} to ${w.end_date}`
      );
    }
  }

  return parts.join("\n");
}

function calculateAge(dateOfBirth: string): number {
  const dob = new Date(dateOfBirth);
  const now = new Date();
  let age = now.getFullYear() - dob.getFullYear();
  const monthDiff = now.getMonth() - dob.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < dob.getDate())) {
    age--;
  }
  return age;
}

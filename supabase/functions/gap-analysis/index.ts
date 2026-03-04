// Haven Edge Function: gap-analysis
// Fetches full household inventory, calls Claude for comprehensive gap analysis,
// returns structured results and updates completion_scores table.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface GapAnalysisRequest {
  household_id: string;
}

const GAP_ANALYSIS_PROMPT = `You are an estate organization expert analyzing a family's complete document portfolio. Given the household data below, perform a thorough gap analysis and return a JSON response.

Analyze and return JSON with:

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

Respond ONLY with valid JSON. No markdown, no explanation, no code fences.`;

serve(async (req: Request) => {
  try {
    // Verify auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body: GapAnalysisRequest = await req.json();
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicApiKey) {
      return new Response(
        JSON.stringify({ error: "AI service not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const householdId = body.household_id;

    // Fetch all household data in parallel
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
      supabase.from("documents").select("*").eq("household_id", householdId),
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

    // Build comprehensive household data string for Claude
    const householdData = buildHouseholdDataString(
      household,
      members,
      properties,
      documents,
      systems,
      warranties,
      maintenance
    );

    // Call Claude API
    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 8192,
        system: GAP_ANALYSIS_PROMPT,
        messages: [
          {
            role: "user",
            content: `HOUSEHOLD DATA:\n\n${householdData}`,
          },
        ],
      }),
    });

    if (!claudeResponse.ok) {
      const errorText = await claudeResponse.text();
      console.error("Claude API error:", errorText);
      return new Response(
        JSON.stringify({ error: "AI analysis failed" }),
        { status: 502, headers: { "Content-Type": "application/json" } }
      );
    }

    const claudeData = await claudeResponse.json();
    const rawText = claudeData.content?.[0]?.text ?? "";

    // Parse Claude's response
    let analysis: Record<string, unknown>;
    try {
      analysis = JSON.parse(rawText);
    } catch {
      console.error("Failed to parse gap analysis response:", rawText);
      return new Response(
        JSON.stringify({ error: "Failed to parse AI analysis results" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
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
        await supabase
          .from("completion_scores")
          .upsert(upsert, { onConflict: "household_id,category" });
      }
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
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("gap-analysis error:", error);
    return new Response(
      JSON.stringify({ error: error.message ?? "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
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
  maintenance: Array<Record<string, unknown>>
): string {
  const parts: string[] = [];

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

  // Documents by category
  parts.push("\nDOCUMENTS:");
  if (documents.length === 0) {
    parts.push("  No documents uploaded.");
  } else {
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
        parts.push(`    - "${d.title}"${expiry}${flags}`);
        if (d.ai_summary) {
          parts.push(`      AI Summary: ${d.ai_summary}`);
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

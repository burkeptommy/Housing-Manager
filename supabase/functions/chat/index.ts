// Haven Edge Function: chat
// Receives user message + conversation history + household context, calls Claude API, returns response.
// Persists both user and assistant messages to chat_messages table.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface ChatRequest {
  message: string;
  conversation_history: Array<{
    role: "user" | "assistant";
    content: string;
  }>;
  context_type?: "general" | "document" | "property" | "maintenance";
  context_id?: string;
  household_id: string;
}

interface ChatResponse {
  reply: string;
  context_type: string;
}

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

    const body: ChatRequest = await req.json();
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicApiKey) {
      return new Response(
        JSON.stringify({ error: "AI service not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Fetch household context for system prompt
    const systemPrompt = await buildSystemPrompt(supabase, body);

    // Build messages array
    const messages = [
      ...body.conversation_history.map((msg) => ({
        role: msg.role as "user" | "assistant",
        content: msg.content,
      })),
      { role: "user" as const, content: body.message },
    ];

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
        max_tokens: 2048,
        system: systemPrompt,
        messages,
      }),
    });

    if (!claudeResponse.ok) {
      const errorText = await claudeResponse.text();
      console.error("Claude API error:", errorText);
      return new Response(
        JSON.stringify({ error: "AI chat failed" }),
        { status: 502, headers: { "Content-Type": "application/json" } }
      );
    }

    const claudeData = await claudeResponse.json();
    const reply = claudeData.content?.[0]?.text ?? "I apologize, but I wasn't able to generate a response. Please try again.";

    // Persist both messages to chat_messages table
    const now = new Date().toISOString();
    await supabase.from("chat_messages").insert([
      {
        household_id: body.household_id,
        user_id: user.id,
        role: "user",
        content: body.message,
        context_type: body.context_type ?? "general",
        context_id: body.context_id ?? null,
        created_at: now,
      },
      {
        household_id: body.household_id,
        user_id: user.id,
        role: "assistant",
        content: reply,
        context_type: body.context_type ?? "general",
        context_id: body.context_id ?? null,
        created_at: now,
      },
    ]);

    const response: ChatResponse = {
      reply,
      context_type: body.context_type ?? "general",
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("chat error:", error);
    return new Response(
      JSON.stringify({ error: error.message ?? "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

// Build the full system prompt with household context
async function buildSystemPrompt(
  supabase: ReturnType<typeof createClient>,
  body: ChatRequest
): Promise<string> {
  const householdId = body.household_id;

  // Fetch all household data in parallel
  const [
    householdResult,
    membersResult,
    propertiesResult,
    documentsResult,
    maintenanceResult,
    warrantiesResult,
    systemsResult,
  ] = await Promise.all([
    supabase.from("households").select("*").eq("id", householdId).single(),
    supabase.from("family_members").select("*").eq("household_id", householdId),
    supabase.from("properties").select("*").eq("household_id", householdId),
    supabase.from("documents").select("*").eq("household_id", householdId),
    supabase.from("maintenance_tasks").select("*").eq("household_id", householdId),
    supabase.from("warranties").select("*").eq("household_id", householdId),
    supabase.from("home_systems").select("*").eq("household_id", householdId),
  ]);

  const household = householdResult.data;
  const members = membersResult.data ?? [];
  const properties = propertiesResult.data ?? [];
  const documents = documentsResult.data ?? [];
  const maintenance = maintenanceResult.data ?? [];
  const warranties = warrantiesResult.data ?? [];
  const systems = systemsResult.data ?? [];

  // Build family members section
  const membersList = members
    .map((m: Record<string, unknown>) => {
      const age = m.date_of_birth
        ? `age ${calculateAge(m.date_of_birth as string)}`
        : "";
      return `- ${m.first_name} ${m.last_name} (${m.relationship}${age ? ", " + age : ""})`;
    })
    .join("\n");

  // Build properties section
  const propertiesList = properties
    .map((p: Record<string, unknown>) => {
      const addr = [p.street, p.city, p.state].filter(Boolean).join(", ");
      return `- ${p.name} (${addr || "No address"})`;
    })
    .join("\n");

  // Build document status by section group
  const docsByCategory = groupDocumentsBySection(documents);
  const documentStatus = Object.entries(docsByCategory)
    .map(([section, docs]) => {
      const flagged = (docs as Array<Record<string, unknown>>).filter(
        (d) => d.ai_flags && (d.ai_flags as unknown[]).length > 0
      );
      const flagInfo = flagged.length > 0
        ? ` (${flagged.length} flag${flagged.length > 1 ? "s" : ""})`
        : "";
      return `- ${section}: ${(docs as unknown[]).length} document${(docs as unknown[]).length !== 1 ? "s" : ""}${flagInfo}`;
    })
    .join("\n");

  // Build active flags
  const activeFlags = documents
    .filter((d: Record<string, unknown>) => d.ai_flags && (d.ai_flags as unknown[]).length > 0)
    .flatMap((d: Record<string, unknown>) =>
      (d.ai_flags as Array<{ severity: string; message: string }>).map((f) => ({
        document: d.title as string,
        ...f,
      }))
    );

  const flagsList = activeFlags.length > 0
    ? activeFlags
        .map((f) => `- [${(f.severity as string).toUpperCase()}] ${f.document}: ${f.message}`)
        .join("\n")
    : "No active flags.";

  // Build property status
  const now = new Date();
  const propertyStatus = properties
    .map((p: Record<string, unknown>) => {
      const propSystems = systems.filter(
        (s: Record<string, unknown>) => s.property_id === p.id
      );
      const propMaintenance = maintenance.filter(
        (m: Record<string, unknown>) => m.property_id === p.id
      );
      const overdue = propMaintenance.filter(
        (m: Record<string, unknown>) =>
          m.next_due_date && new Date(m.next_due_date as string) < now
      );
      const propWarranties = warranties.filter((w: Record<string, unknown>) =>
        propSystems.some((s: Record<string, unknown>) => s.id === w.system_id)
      );
      const expiring = propWarranties.filter((w: Record<string, unknown>) => {
        const end = new Date(w.end_date as string);
        const diffDays = (end.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        return diffDays > 0 && diffDays <= 90;
      });

      const addr = [p.street, p.city].filter(Boolean).join(", ");
      const addrStr = addr ? ` (${addr})` : "";
      return `- ${p.name}${addrStr}: ${propSystems.length} systems, ${overdue.length} overdue maintenance, ${expiring.length} warranties expiring within 90 days`;
    })
    .join("\n");

  // Build context-specific prefix
  let contextPrefix = "";
  if (body.context_type === "document" && body.context_id) {
    const doc = documents.find(
      (d: Record<string, unknown>) => d.id === body.context_id
    );
    if (doc) {
      contextPrefix = `\nCONTEXT: The user is currently viewing document: "${doc.title}" (${doc.category}).\nPrioritize answering questions about this specific document, but you can reference other household data as needed.\n`;
    }
  } else if (body.context_type === "property" && body.context_id) {
    const prop = properties.find(
      (p: Record<string, unknown>) => p.id === body.context_id
    );
    if (prop) {
      contextPrefix = `\nCONTEXT: The user is currently viewing property: "${prop.name}" (${[prop.street, prop.city].filter(Boolean).join(", ")}).\nPrioritize answering questions about this specific property, but you can reference other household data as needed.\n`;
    }
  }

  return `You are Haven AI, the intelligent assistant built into Haven — a premium estate document organization and home management platform serving high-net-worth families.

HOUSEHOLD CONTEXT:
Household: ${household?.name ?? "Unknown"}
Family Members:
${membersList || "No family members added yet."}
Properties:
${propertiesList || "No properties added yet."}

DOCUMENT STATUS:
${documentStatus || "No documents uploaded yet."}

Active Flags:
${flagsList}

PROPERTY STATUS:
${propertyStatus || "No properties added yet."}
${contextPrefix}
YOUR ROLE:
- Help families understand their document coverage and estate readiness
- Explain estate planning concepts in plain, accessible language
- Identify gaps and recommend next steps
- Provide home maintenance guidance and scheduling recommendations
- Answer questions about their specific documents and properties
- Be warm, professional, and reassuring — these are sensitive topics

IMPORTANT BOUNDARIES:
- You are NOT a lawyer, financial advisor, CPA, or insurance agent
- Always recommend consulting appropriate professionals for specific legal, tax, or financial advice
- Never provide specific investment, tax, or legal recommendations
- You CAN explain concepts, identify gaps, and suggest questions to ask their professionals
- If asked about a specific document, reference the data you have but suggest they review the actual document for details
- Format responses with markdown for readability (bold, bullets, etc.)`;
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

function groupDocumentsBySection(
  documents: Array<Record<string, unknown>>
): Record<string, Array<Record<string, unknown>>> {
  const sectionMap: Record<string, string[]> = {
    "Estate Planning": [
      "Will", "Trust", "Power of Attorney", "Healthcare Directive",
      "Guardianship Designation", "Letter of Intent",
    ],
    "Entity Documents": [
      "LLC Operating Agreement", "LP Agreement", "S-Corp Documents",
      "EIN Documentation", "Annual Filings", "Bylaws",
    ],
    "Real Estate": [
      "Deed", "Mortgage", "Title Insurance", "Survey",
      "HOA Documents", "Lease Agreement", "Property Tax Records",
    ],
    "Insurance": [
      "Life Insurance", "Umbrella Insurance", "Homeowners Insurance",
      "Auto Insurance", "Jewelry/Art Rider", "Long-Term Care Insurance",
      "Disability Insurance", "Directors & Officers Insurance",
    ],
    "Financial Accounts": [
      "Brokerage Account", "Retirement Account (IRA/401k)", "Bank Account",
      "529 Plan", "Beneficiary Designation", "Stock Options/RSUs",
      "Crypto Wallet", "Alternative Investments",
    ],
    "Tax Records": [
      "Federal Tax Return", "State Tax Return", "Gift Tax Return (Form 709)",
      "Property Tax Record", "Estate & Trust Return (Form 1041)",
    ],
    "Personal Property": [
      "Vehicle Title", "Art Appraisal", "Jewelry Appraisal",
      "Collectibles Documentation", "Boat/Aircraft Registration",
    ],
    "Digital Assets": [
      "Domain Names", "Digital Account Inventory",
      "Social Media Accounts", "Intellectual Property",
    ],
    "Personal Identification": [
      "Passport", "Birth Certificate", "Marriage Certificate",
      "Divorce Decree", "Social Security Card", "Citizenship/Immigration",
      "Death Certificate",
    ],
    "Professional & Business": [
      "Employment Agreement", "Non-Compete/NDA", "Partnership Agreement",
      "Buy-Sell Agreement", "Succession Plan",
    ],
  };

  const result: Record<string, Array<Record<string, unknown>>> = {};

  for (const doc of documents) {
    const category = doc.category as string;
    let section = "Other";
    for (const [sectionName, categories] of Object.entries(sectionMap)) {
      if (categories.includes(category)) {
        section = sectionName;
        break;
      }
    }
    if (!result[section]) result[section] = [];
    result[section].push(doc);
  }

  return result;
}

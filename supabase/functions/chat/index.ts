// Haven Edge Function: chat
// Receives user message + conversation history + household context, calls Claude API, returns response.
// Persists both user and assistant messages to chat_messages table.
// Queries document_content for relevant documents to include in AI context.
// Logs ai_chat_query to access_log.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers for all responses
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// AES-256-GCM encryption for at-rest chat message protection
async function encryptMessage(plaintext: string, keyBase64: string): Promise<string> {
  const keyBytes = Uint8Array.from(atob(keyBase64), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey("raw", keyBytes, "AES-GCM", false, ["encrypt"]);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encoded = new TextEncoder().encode(plaintext);
  const ciphertext = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, encoded);
  // Combine IV + ciphertext, return as base64
  const combined = new Uint8Array(iv.length + ciphertext.byteLength);
  combined.set(iv);
  combined.set(new Uint8Array(ciphertext), iv.length);
  return btoa(String.fromCharCode(...combined));
}

interface ChatRequest {
  message: string;
  conversation_history: Array<{
    role: "user" | "assistant";
    content: string;
  }>;
  context_type?: "general" | "document" | "property" | "project" | "maintenance";
  context_id?: string;
  household_id: string;
  user_id?: string;
  encryption_key?: string; // Base64-encoded AES-256 key from client for at-rest encryption
}

interface ChatResponse {
  reply: string;
  context_type: string;
}

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

    const body: ChatRequest = await req.json();

    // Use JWT-authenticated userId, or fall back to body-provided userId
    if (!userId && body.user_id) {
      userId = body.user_id;
      console.log("Using body-provided user_id:", userId);
    }

    // Service client for logging and document_content access
    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    // Fetch household context + document content for system prompt
    const { systemPrompt, referencedDocumentIds, equipmentContext } = await buildSystemPrompt(
      supabase,
      serviceClient,
      body,
      userId
    );

    // Build messages array
    const messages = [
      ...body.conversation_history.map((msg) => ({
        role: msg.role as "user" | "assistant",
        content: msg.content,
      })),
      { role: "user" as const, content: body.message },
    ];

    // Call Claude API
    console.log("Calling Claude API for chat with model claude-sonnet-4-6...");

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
          max_tokens: 2048,
          system: systemPrompt,
          messages,
        }),
        signal: AbortSignal.timeout(60000),
      });
    } catch (fetchError) {
      const isTimeout = fetchError.name === "TimeoutError" || fetchError.name === "AbortError";
      console.error("Fetch to Claude API failed:", fetchError.name, fetchError.message);
      return new Response(
        JSON.stringify({
          error: isTimeout ? "AI response timed out. Please try again." : "Failed to reach AI service",
          detail: fetchError.message,
        }),
        { status: isTimeout ? 504 : 502, headers: responseHeaders }
      );
    }

    if (!claudeResponse.ok) {
      const errorText = await claudeResponse.text();
      console.error(`Claude API returned ${claudeResponse.status}: ${errorText}`);

      let errorDetail = "AI chat failed";
      switch (claudeResponse.status) {
        case 401:
          errorDetail = "AI service authentication failed. Check ANTHROPIC_API_KEY.";
          break;
        case 429:
          errorDetail = "Too many requests. Please wait a moment and try again.";
          break;
        case 529:
          errorDetail = "AI service temporarily overloaded. Please try again in a few minutes.";
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
    const reply = claudeData.content?.[0]?.text ?? "I apologize, but I wasn't able to generate a response. Please try again.";

    // Persist both messages to chat_messages table (encrypted at rest if key provided)
    const now = new Date().toISOString();
    try {
      let storedUserContent = body.message;
      let storedReply = reply;

      if (body.encryption_key) {
        try {
          storedUserContent = await encryptMessage(body.message, body.encryption_key);
          storedReply = await encryptMessage(reply, body.encryption_key);
        } catch (encErr) {
          console.warn("Chat encryption failed, storing plaintext:", encErr);
          // Fall back to plaintext — don't block the chat
        }
      }

      await supabase.from("chat_messages").insert([
        {
          household_id: body.household_id,
          user_id: userId ?? null,
          role: "user",
          content: storedUserContent,
          context_type: body.context_type ?? "general",
          context_id: body.context_id ?? null,
          created_at: now,
        },
        {
          household_id: body.household_id,
          user_id: userId ?? null,
          role: "assistant",
          content: storedReply,
          context_type: body.context_type ?? "general",
          context_id: body.context_id ?? null,
          created_at: now,
        },
      ]);
    } catch (chatErr) {
      console.warn("Failed to persist chat messages:", chatErr);
    }

    // Log ai_chat_query to access_log
    try {
      await serviceClient.from("access_log").insert({
        household_id: body.household_id,
        user_id: userId ?? null,
        action: "ai_chat_query",
        resource_type: "chat",
        resource_id: null,
        resource_name: null,
        actor_type: "user",
        metadata: {
          context_type: body.context_type ?? "general",
          context_id: body.context_id ?? null,
          documents_referenced: referencedDocumentIds,
          message_preview: body.message.substring(0, 100),
        },
      });
    } catch (logErr) {
      console.warn("Failed to log chat query:", logErr);
    }

    const response: ChatResponse = {
      reply,
      context_type: body.context_type ?? "general",
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: responseHeaders,
    });
  } catch (error) {
    console.error("chat error:", error);
    return new Response(
      JSON.stringify({ error: error.message ?? "Internal server error" }),
      { status: 500, headers: responseHeaders }
    );
  }
});

// Build the full system prompt with household context + document content
async function buildSystemPrompt(
  supabase: ReturnType<typeof createClient>,
  serviceClient: ReturnType<typeof createClient>,
  body: ChatRequest,
  userId?: string
): Promise<{ systemPrompt: string; referencedDocumentIds: string[]; equipmentContext: string }> {
  const householdId = body.household_id;
  const referencedDocumentIds: string[] = [];

  // Fetch all household data in parallel (including current user's name)
  const [
    householdResult,
    membersResult,
    propertiesResult,
    documentsResult,
    maintenanceResult,
    warrantiesResult,
    systemsResult,
    serviceContractsResult,
    projectsResult,
    currentUserResult,
  ] = await Promise.all([
    supabase.from("households").select("*").eq("id", householdId).single(),
    supabase.from("family_members").select("*").eq("household_id", householdId),
    supabase.from("properties").select("*").eq("household_id", householdId),
    supabase.from("documents").select("*").eq("household_id", householdId).is("deleted_at", null),
    supabase.from("maintenance_tasks").select("*").eq("household_id", householdId),
    supabase.from("warranties").select("*").eq("household_id", householdId),
    supabase.from("home_systems").select("*").eq("household_id", householdId),
    supabase.from("service_contracts").select("*").eq("household_id", householdId),
    supabase.from("property_projects").select("*").eq("household_id", householdId),
    userId ? supabase.from("users").select("full_name").eq("id", userId).single() : Promise.resolve({ data: null }),
  ]);

  const household = householdResult.data;
  const members = membersResult.data ?? [];
  const properties = propertiesResult.data ?? [];
  const documents = documentsResult.data ?? [];
  const maintenance = maintenanceResult.data ?? [];
  const warranties = warrantiesResult.data ?? [];
  const systems = systemsResult.data ?? [];
  const serviceContracts = (serviceContractsResult.data ?? []) as Record<string, unknown>[];
  const projects = projectsResult.data ?? [];
  const currentUserName = currentUserResult.data?.full_name ?? null;

  // Fetch document content for context-specific or keyword-matched documents
  let documentContentSection = "";

  if (body.context_type === "document" && body.context_id) {
    // User is viewing a specific document — fetch its full extracted text
    // Only include if document is not soft-deleted
    const doc = documents.find((d: Record<string, unknown>) => d.id === body.context_id);
    if (doc) {
      const { data: content } = await serviceClient
        .from("document_content")
        .select("extracted_text, document_id")
        .eq("document_id", body.context_id)
        .single();

      if (content?.extracted_text) {
        const title = (doc?.title as string) ?? "Unknown Document";
        documentContentSection = `\nDOCUMENT CONTENT (user is currently viewing "${title}"):\n${content.extracted_text.substring(0, 8000)}\n`;
        referencedDocumentIds.push(content.document_id);
      }
    }
  } else {
    // Search for relevant documents based on the user's message
    const keywords = extractKeywords(body.message);
    if (keywords.length > 0) {
      // Fetch all document content for this household and filter by relevance
      const { data: allContent } = await serviceClient
        .from("document_content")
        .select("document_id, extracted_text")
        .eq("household_id", householdId);

      if (allContent && allContent.length > 0) {
        // Match documents by title/category keywords or content keywords
        const relevant = allContent
          .map((c) => {
            const doc = documents.find((d: Record<string, unknown>) => d.id === c.document_id);
            const title = ((doc?.title as string) ?? "").toLowerCase();
            const category = ((doc?.category as string) ?? "").toLowerCase();
            const text = (c.extracted_text ?? "").toLowerCase();
            const score = keywords.reduce((acc, kw) => {
              const kwLower = kw.toLowerCase();
              if (title.includes(kwLower)) return acc + 3;
              if (category.includes(kwLower)) return acc + 2;
              if (text.includes(kwLower)) return acc + 1;
              return acc;
            }, 0);
            return { ...c, doc, score };
          })
          .filter((c) => c.score > 0)
          .sort((a, b) => b.score - a.score)
          .slice(0, 3); // Top 3 most relevant

        if (relevant.length > 0) {
          documentContentSection = "\nRELEVANT DOCUMENT CONTENT:\n";
          for (const r of relevant) {
            const title = (r.doc?.title as string) ?? "Unknown";
            const category = (r.doc?.category as string) ?? "Unknown";
            // Limit each document to 4000 chars to stay within context
            const snippet = r.extracted_text.substring(0, 4000);
            documentContentSection += `\n--- ${title} (${category}) ---\n${snippet}\n`;
            referencedDocumentIds.push(r.document_id);
          }
        }
      }
    }
  }

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
      const vaultLocked = (docs as Array<Record<string, unknown>>).filter(
        (d) => d.vault_locked === true
      );
      const flagInfo = flagged.length > 0
        ? ` (${flagged.length} flag${flagged.length > 1 ? "s" : ""})`
        : "";
      const vaultInfo = vaultLocked.length > 0
        ? ` [${vaultLocked.length} vault-locked]`
        : "";
      return `- ${section}: ${(docs as unknown[]).length} document${(docs as unknown[]).length !== 1 ? "s" : ""}${flagInfo}${vaultInfo}`;
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

      // Property attributes (roof material, siding, etc.)
      const attrs = (p.attributes ?? {}) as Record<string, unknown>;
      const attrParts: string[] = [];
      if (attrs.roof_material) attrParts.push(`${String(attrs.roof_material).replace(/_/g, " ")} roof`);
      if (attrs.siding_material) attrParts.push(`${String(attrs.siding_material).replace(/_/g, " ")} siding`);
      if (attrs.water_source) attrParts.push(`${String(attrs.water_source)} water`);
      if (attrs.has_water_softener === true || attrs.has_water_softener === "true") attrParts.push("water softener");
      if (attrs.has_ev_charger === true || attrs.has_ev_charger === "true") attrParts.push("EV charger");
      if (attrs.deck_material && attrs.deck_material !== "none") attrParts.push(`${attrs.deck_material} deck`);
      if (attrs.fence_material && attrs.fence_material !== "none") attrParts.push(`${attrs.fence_material} fence`);
      const attrStr = attrParts.length > 0 ? `, ${attrParts.join(", ")}` : "";

      // Service contracts for this property
      const propContracts = serviceContracts.filter((c) => c.property_id === p.id);
      const contractStr = propContracts.length > 0
        ? `\n  Service contracts: ${propContracts.map((c) => `${String(c.service_type).replace(/_/g, " ")}${c.provider_name ? ` (${c.provider_name})` : ""}${c.frequency ? `, ${c.frequency}` : ""}`).join("; ")}`
        : "";

      return `- ${p.name}${addrStr}: ${propSystems.length} systems, ${overdue.length} overdue maintenance, ${expiring.length} warranties expiring within 90 days${attrStr}${contractStr}`;
    })
    .join("\n");

  // Build active projects section
  const activeProjects = projects.filter(
    (p: any) => p.status === "planning" || p.status === "in_progress"
  );
  const projectsList = activeProjects.length > 0
    ? activeProjects.map((p: any) => {
        const budget = p.estimated_budget ? `$${Math.round(p.estimated_budget)}` : "not set";
        const spent = `$${Math.round(p.actual_spend || 0)}`;
        const over = (p.actual_spend || 0) > (p.estimated_budget || Infinity);
        const property = properties.find((prop: any) => prop.id === p.property_id);
        return `- ${p.name} (${p.category}, ${property?.name ?? "Unknown property"}): ${p.status}, Budget: ${budget}, Spent: ${spent}${over ? " ⚠️ OVER BUDGET" : ""}`;
      }).join("\n")
    : "No active projects";

  // Build equipment catalog context for the user's home systems
  let equipmentContext = "";
  const systemsWithCatalog = systems.filter((s: any) => s.catalog_entry_id);
  if (systemsWithCatalog.length > 0) {
    const catalogIds = systemsWithCatalog.map((s: any) => s.catalog_entry_id);
    const { data: catalogEntries } = await serviceClient
      .from("equipment_catalog")
      .select(`
        id, model_number, model_name, series, expected_lifespan_years, key_features, specs,
        equipment_manufacturers!inner (name, support_url, support_phone),
        equipment_categories!inner (name)
      `)
      .in("id", catalogIds);

    if (catalogEntries && catalogEntries.length > 0) {
      equipmentContext = "\nEQUIPMENT DATABASE MATCHES:\n" + catalogEntries.map((e: any) => {
        const mfg = e.equipment_manufacturers;
        return `- ${mfg.name} ${e.model_number} (${e.model_name}): ${e.expected_lifespan_years}yr lifespan. Support: ${mfg.support_phone ?? mfg.support_url ?? "N/A"}`;
      }).join("\n");
    }
  }

  // If user mentions equipment-related keywords, note the lookup capability
  const msgLower = body.message.toLowerCase();
  const equipmentKeywords = ["manual", "model", "filter", "part", "repair", "maintenance", "install", "spec", "troubleshoot", "fix", "replace", "broken", "not working", "warranty"];
  const mentionsEquipment = equipmentKeywords.some(kw => msgLower.includes(kw));

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
  } else if (body.context_type === "project" && body.context_id) {
    const proj = projects.find(
      (p: Record<string, unknown>) => p.id === body.context_id
    );
    if (proj) {
      const property = properties.find((p: Record<string, unknown>) => p.id === proj.property_id);
      const propName = property ? ` at ${property.name}` : "";
      const budget = proj.estimated_budget ? `, Budget: $${Math.round(proj.estimated_budget as number)}` : "";
      const spent = proj.actual_spend ? `, Spent: $${Math.round(proj.actual_spend as number)}` : "";
      const notes = proj.notes ? `\nProject notes: ${proj.notes}` : "";
      contextPrefix = `\nCONTEXT: The user is currently viewing project: "${proj.name}" (${proj.category}${propName}, Status: ${proj.status}${budget}${spent}).${notes}\nPrioritize answering questions about this specific project, but you can reference other household data as needed.\n`;
    }
  }

  const systemPrompt = `You are Alfred, the intelligent concierge built into Haven — a premium estate document organization and home management platform for high-net-worth families.

You are named after the archetype of the trusted family butler — discreet, knowledgeable, always prepared. You speak with warmth, precision, and quiet confidence. You never use jargon when plain language works. You address the user by their first name when appropriate.

HOUSEHOLD CONTEXT:
Current User: ${currentUserName ?? "Unknown"} (this is the person you are speaking with right now — address them by their first name)
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

ACTIVE HOME PROJECTS:
${projectsList}
${contextPrefix}${documentContentSection}${equipmentContext}
EQUIPMENT REFERENCE DATABASE:
Haven has an extensive equipment catalog with 2,800+ models across 219 brands covering kitchen appliances, HVAC, water heaters, laundry, generators, sump pumps, well water systems, bathroom fixtures, irrigation, and pool systems. When users ask about specific equipment:
- You can reference model specs, expected lifespan, common issues, and maintenance schedules
- You can direct them to the manufacturer's support portal or provide a cached PDF manual
- If the user mentions a model number or brand, you can look it up and provide detailed information
- For troubleshooting, reference common issues and typical fixes from the database
- For maintenance, provide the recommended service schedule with parts lists and costs${mentionsEquipment ? "\n- The user appears to be asking about equipment — be proactive about referencing the catalog data." : ""}

YOUR ROLE:
- Help families understand their document coverage and estate readiness
- Explain estate planning concepts in plain, accessible language
- Identify gaps and recommend next steps
- Provide home maintenance guidance and scheduling recommendations
- When discussing maintenance, roofing, pest control, landscaping, or similar topics, reference property attributes and service contracts if available. If key attributes are missing (e.g., roof material, pest control provider), you can mention: "I don't have your [detail] on file yet — you can update this on your dashboard, or just tell me here."
- Answer questions about their specific documents and properties
- When document content is provided above, use it to give specific, accurate answers
- Be warm, professional, and reassuring — these are sensitive topics
- Sound like a trusted private advisor, not a chatbot

CRITICAL CONVERSATION RULE:
- You MUST ONLY respond to the user's MOST RECENT message (the last message in the conversation)
- Previous messages are provided for context only — do NOT re-answer, revisit, or summarize previous questions or your previous responses
- Treat older messages as background context, not as things that need a response
- If the user's latest message is a follow-up, answer just that follow-up

IMPORTANT BOUNDARIES:
- You are NOT a lawyer, financial advisor, CPA, or insurance agent
- Always recommend consulting appropriate professionals for specific legal, tax, or financial advice
- Never provide specific investment, tax, or legal recommendations
- You CAN explain concepts, identify gaps, and suggest questions to ask their professionals
- If asked about a specific document, reference the extracted content when available
- Vault-locked documents have their content hidden from AI — acknowledge they exist but note you cannot analyze their contents
- Format responses with markdown for readability (bold, bullets, etc.)

SCOPE — WHAT YOU HELP WITH:
You are Alfred, a personal family concierge. You help with anything a trusted family advisor or estate manager would handle. This includes but is not limited to:
- Home management: maintenance, repairs, systems, vendors, renovations, home improvement, seasonal prep
- Estate planning: wills, trusts, powers of attorney, guardianship, beneficiaries, succession
- Documents: understanding, organizing, and managing all uploaded documents
- Financial concepts: tax strategies, retirement planning concepts, insurance coverage, wealth preservation, budgeting
- Family life: travel planning, kids' activities, school research, meal planning, event coordination, relocation
- Property: buying, selling, refinancing, rental strategies, home valuation, neighborhood research
- "What If?" scenarios: any hypothetical about the user's home, estate, finances, family, or lifestyle
- Vendor and contractor guidance: finding services, understanding quotes, negotiating tips
- General life management: scheduling, organization, productivity, moving, downsizing

SCOPE — WHAT YOU DECLINE:
If a user asks something clearly outside the scope of a family concierge — like help with school homework, coding or programming, writing essays or academic papers, creating business software, generating creative fiction, solving math problems unrelated to their finances, or any other request that has nothing to do with their home, family, estate, finances, or lifestyle — politely decline and redirect.

When declining, say something warm like:
"I'm best at helping with your home, family, and estate — that's where I really shine. For [what they asked about], you might want to try a general AI assistant. Is there anything about your property, documents, or family planning I can help with instead?"

Be generous in interpretation. If there's any reasonable connection to their home, family, finances, or lifestyle, help them. Only decline requests that are clearly and unambiguously outside scope — like "help me debug this React component" or "write my history essay" or "explain quantum physics."

CONCIERGE HANDOFF:
If the user asks for something that requires human action — like booking travel, scheduling real appointments, finding specific local vendors, coordinating with professionals, or anything you can't complete yourself — offer to connect them with their Haven concierge.

Say something like: "I can connect you with your Haven concierge for this — they can [specific thing]. Want me to send them a message with the details?"

Things the concierge handles:
- Finding and vetting local vendors and service providers
- Booking travel and accommodations
- Scheduling kids' camps and activities
- Coordinating with attorneys, CPAs, and financial advisors
- Uploading documents on the user's behalf
- Getting quotes for home projects
- Any task that requires human judgment, phone calls, or coordination

You can help PREPARE for these tasks (draft emails, research options, organize information) but let the concierge EXECUTE them. When handing off, include a summary of the conversation context so the concierge team has full context.`;

  return { systemPrompt, referencedDocumentIds, equipmentContext };
}

// Extract likely search keywords from user message
function extractKeywords(message: string): string[] {
  const stopWords = new Set([
    "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
    "have", "has", "had", "do", "does", "did", "will", "would", "could",
    "should", "may", "might", "shall", "can", "need", "dare", "ought",
    "used", "to", "of", "in", "for", "on", "with", "at", "by", "from",
    "as", "into", "through", "during", "before", "after", "above", "below",
    "between", "out", "off", "over", "under", "again", "further", "then",
    "once", "here", "there", "when", "where", "why", "how", "all", "both",
    "each", "few", "more", "most", "other", "some", "such", "no", "nor",
    "not", "only", "own", "same", "so", "than", "too", "very", "just",
    "don", "should", "now", "what", "who", "my", "me", "i", "you", "your",
    "it", "its", "this", "that", "these", "those", "about", "tell",
  ]);

  return message
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, "")
    .split(/\s+/)
    .filter((w) => w.length > 2 && !stopWords.has(w));
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
    "Home Projects": [
      "Project Plan", "Contractor Quote", "Project Invoice",
      "Before/After Photos", "Permit", "Inspection Report", "Completion Certificate",
    ],
    "Home Records": [
      "Blueprint/Floor Plan", "Property Layout", "Appliance Manual",
      "Warranty Card", "Home Inventory", "Utility Account", "Vendor Contract",
    ],
    "Home Financials": [
      "Home Bill/Invoice", "Property Tax Bill", "Utility Bill",
      "Repair Estimate", "Renovation Budget",
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

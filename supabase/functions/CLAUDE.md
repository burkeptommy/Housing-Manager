# Haven Edge Functions -- Context for Claude Code

## Overview

All Edge Functions are Deno/TypeScript, deployed to Supabase. They are the ONLY place the Claude API key lives. The iOS app calls them via `HavenSupabase.callEdgeFunction()`.

## Deploy Command

```bash
supabase functions deploy [function-name] --no-verify-jwt
```

The `--no-verify-jwt` flag is critical. Without it, functions reject requests.

Link first if not already: `supabase link --project-ref jsucwnkntdrxhysojgri`

## Standard Pattern (Every Function)

```typescript
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    // ... function logic
  } catch (error) {
    console.error("[function-name] Error:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers });
  }
});
```

## Claude API Call Pattern

```typescript
const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "x-api-key": anthropicApiKey,
    "anthropic-version": "2023-06-01",  // some functions use "2024-10-22"
  },
  body: JSON.stringify({
    model: "claude-sonnet-4-6",
    max_tokens: 4096,  // varies by function (4096-8192)
    system: "System prompt here. Always end with: Return ONLY valid JSON.",
    messages: [{ role: "user", content: userContent }],
  }),
});
```

**All functions use `claude-sonnet-4-6`.** All system prompts end with instructions to return only valid JSON (no markdown fences, no backticks).

## Environment Variables Available

- `ANTHROPIC_API_KEY` -- Claude API key
- `SUPABASE_URL` -- Project URL
- `SUPABASE_SERVICE_ROLE_KEY` -- Bypasses RLS (use carefully)
- `SUPABASE_ANON_KEY` -- Public anon key
- `SENDGRID_API_KEY` -- For email sending (used by `send-push-notification` and email functions)
- `GOOGLE_CUSTOM_SEARCH_KEY` / `GOOGLE_CUSTOM_SEARCH_CX` -- For product image search in research-project
- `BRANDFETCH_API_KEY` -- For fetching brand logos (vendors, manufacturers, utility providers)
- `ATTOM_API_KEY` -- ATTOM Data Solutions for property valuation, tax assessment, sales history (primary)
- `RENTCAST_API_KEY` -- RentCast for property data (fallback when ATTOM returns no results)

## Function Inventory

### Core AI Functions
- **analyze-document/** -- AI document analysis on upload. Accepts text or image_base64. Returns summary, category suggestion, key dates, key parties, flags, extracted metadata, cross-reference suggestions. Writes results to `documents` and `document_content` tables. Phase 48: estate categories trigger a second Claude call for estate-specific extraction (fiduciaries, execution dates, attorney info, estate_sub_type) with PII redaction, and fire-and-forget upserts to `estate_state`.
- **chat/** -- Alfred AI chat. Builds full household context via `Promise.all` (members, properties, systems, documents, warranties, maintenance, contractors, projects). Context injection is SERVER-SIDE in this file, not in ChatViewModel.swift.
- **gap-analysis/** -- Estate document gap analysis. Compares uploaded docs against expected coverage for the household composition.
- **simulate-scenario/** -- Scenario Studio. Accepts scenario_id (preset) or custom_query. Builds household context, simulates financial/estate scenarios.
- **proactive-scan/** -- Background document scanning. Reviews all docs for expiration, cross-reference issues, missing coverage. Returns new_flags and expiring_soon arrays. Phase 48: also computes estate staleness and writes tier/reasons to estate_state.

### Estate (Phase 48)
- **verify-estate-export/** -- Public endpoint (no auth). Validates estate PDF verification tokens. Checks expiry (7 days), access count (3 max), revocation. Increments counter, logs hashed IP. Returns household name, generation date, truncated hash, access remaining. Called by havenhome.dev/verify page.

### Property & Equipment
- **search-equipment/** -- Searches equipment_catalog table by text query. Returns matching models with specs.
- **identify-equipment/** -- Photo identification via Claude Vision. Extracts manufacturer/model/serial from equipment plates, matches against catalog.
- **lookup-manual/** -- Finds manuals, common issues, and service schedules for a model number from the catalog.
- **score-equipment/** -- AI reliability scoring for equipment models.
- **score-property/** -- AI property condition scoring.
- **research-project/** -- AI research for home improvement projects. Returns cost estimates, materials lists, tips, permit notes, difficulty, ROI, design suggestions.
- **project-feasibility/** -- Quick ROI/feasibility check for project types.
- **property-lookup/** -- Address-based property data lookup. Uses ATTOM Data Solutions as primary (AVM endpoint with confidence score, tax assessment, owner info), with RentCast as fallback. Results cached in `property_lookups` table. Returns `PropertyResult` with `estimatedValueConfidence`, `taxAssessment` (assessed/market/tax amount), and `dataSource` field.
- **visualize-room/** -- AI room visualization for design projects.

### Invoice Intelligence
- **process-invoice/** -- AI invoice analysis for smart maintenance completion. Receives `document_id`, `property_id`, `household_id`. Fetches document content, existing systems (with parent/child relationships), tasks, and contractors. Uses Claude to match completed tasks, discover new systems (with duplicate detection and sub-system grouping via `parent_system_id`/`parent_system_name`), extract vendor info, identify follow-ups. Consolidates tasks at homeowner level and limits follow-ups to 3 max. Returns structured JSON with `completed_tasks`, `new_systems_discovered`, `vendor`, `service_summary`, `parts_and_materials`, `follow_up_needed`.

### Quotes & Negotiation
- **analyze-quote/** -- AI analysis of contractor quotes. Accepts image or text. Returns line-item breakdown with fair market prices, local price ranges, overall rating, negotiation tips, DIY alternative.
- **draft-negotiation-email/** -- Generates negotiation email based on quote analysis.

### Email Pipeline
- **receive-email/** -- SendGrid Inbound Parse webhook. Receives forwarded emails, creates inbox_items. For `bill_invoice` type emails with attachments, also creates a document record in the `documents` table (category "Home Bill/Invoice"), uploads the attachment to the documents storage bucket, and triggers `analyze-document`. This enables invoice intelligence (Phase 38) for email-forwarded bills.
- **process-inbox-item/** -- AI processing of inbox items. Classifies content, extracts data, routes to appropriate feature (document, maintenance task, project, family event).

### Household Management
- **merge-households/** -- Atomic household merge across 15+ tables using service_role. Handles invite, preview, and execute actions.
- **delete-account/** -- Cascading account deletion. Uses auth token to identify user, deletes across all tables.
- **send-push-notification/** -- APNs push via Supabase's built-in push or direct APNs call.

### Vendor & Document
- **extract-vendor/** -- Crawls a website URL to extract vendor/contractor info.
- **view-document/** -- Secure document preview. Decrypts server-side, streams back to client.

### Catalog Management (Admin/Build-time)
- **enrich-catalog/** -- Enriches equipment catalog entries with additional data.
- **expand-catalog/** -- Adds new entries to equipment catalog.
- **scrape-manuals/** -- Scrapes manufacturer websites for manual URLs.
- **download-manuals/** -- Downloads and caches manual PDFs.
- **upload-manual/** -- Uploads manual files to Supabase storage.
- **send-catalog-request/** -- User-submitted request for missing catalog entries.

### Brand & Logo
- **brand-logo/** -- Fetches brand logos, icons, and colors via Brandfetch API. Accepts `query` (search by name) or `domain` (direct lookup). Returns logoUrl, iconUrl, brandColor, plus full arrays of all logo/icon formats and colors. Use this for ALL logo fetching — vendors, manufacturers, utility providers, any company.

### Vehicle
- **vehicle-lookup/** -- VIN decode via NHTSA APIs + Claude Vision (image-to-VIN extraction). Returns decoded vehicle info (year, make, model, trim, engine, drive type), NHTSA recalls, and AI-generated maintenance schedule specific to the vehicle. Accepts `vin` string or `image_base64`.
- **check-vehicle-recalls/** -- Re-checks NHTSA for new recalls on all household vehicles with VINs. Compares against existing recalls by campaign number. Inserts only new ones.

### Utility
- **test-ai/** -- Dev/test endpoint for Claude API connectivity.
- **debug-research/** -- Debug endpoint for research-project.
- **research-item-alternative/** -- Finds alternative products for project line items.

## Key Architectural Decision

**Alfred's context injection happens HERE in `chat/index.ts`, not in `ChatViewModel.swift` on the client.** The chat function uses `Promise.all` to fetch all household data (members, properties, systems, docs, warranties, maintenance, contractors, projects) and builds the full context string server-side before sending to Claude. This keeps sensitive data server-side and ensures Claude always has complete household context.

## Database Access Pattern

```typescript
const supabase = createClient(supabaseUrl, serviceRoleKey);

// Service role bypasses RLS -- use for server-side operations
const { data, error } = await supabase
  .from("table_name")
  .select("*")
  .eq("household_id", householdId);
```

## Error Response Pattern

```typescript
// Input validation
if (!required_field) {
  return new Response(JSON.stringify({ error: "Missing required_field" }), { status: 400, headers });
}

// Claude API errors
if (!claudeResponse.ok) {
  const errText = await claudeResponse.text();
  console.error("[function-name] Claude API error:", errText);
  return new Response(JSON.stringify({ error: "AI analysis failed" }), { status: 502, headers });
}

// JSON parse errors (Claude sometimes returns invalid JSON)
try {
  result = JSON.parse(rawText);
} catch {
  console.error("[function-name] Failed to parse response:", rawText.substring(0, 500));
  // Attempt to extract JSON from markdown fences
  const jsonMatch = rawText.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) result = JSON.parse(jsonMatch[1].trim());
}
```

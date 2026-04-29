import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const PREVIEW_TOKEN = "preview-handyman-visit-20260423-premier";
const PREVIEW_VISIT_ID = "a6d1c5d5-0b3c-44ab-88f6-6b0d1f234567";
const PREVIEW_REQUEST_ID = "38ea99f6-1809-4cc9-b5d6-2ebfca820001";

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function compactString(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function isNonEmptyArray(value: unknown) {
  return Array.isArray(value) && value.length > 0;
}

function requestStatusLabel(status: string) {
  switch (status) {
    case "draft":
      return "Draft";
    case "submitted":
      return "Requested";
    case "scheduled":
      return "Scheduled";
    case "sent_to_handyman":
      return "Sent to handyman";
    case "alternate_dates_proposed":
      return "Dates proposed";
    case "awaiting_homeowner":
      return "Reply needed";
    case "confirmed":
      return "Confirmed";
    case "on_my_way":
      return "On my way";
    case "checked_in":
      return "Checked in";
    case "quoted":
      return "Quoted";
    case "in_progress":
      return "In progress";
    case "completed":
      return "Completed";
    case "follow_up_recommended":
      return "Follow-up recommended";
    case "cancelled":
      return "Cancelled";
    case "declined":
      return "Declined";
    default:
      return "Visit update";
  }
}

function homeownerSummary(status: string) {
  switch (status) {
    case "draft":
      return "This visit is still a draft.";
    case "submitted":
      return "Chez saved the request and is getting it ready to send.";
    case "scheduled":
      return "The visit has a date, but the handyman still needs to confirm through Chez.";
    case "sent_to_handyman":
      return "Use the buttons below to confirm the date or suggest another option before starting the visit.";
    case "alternate_dates_proposed":
      return "The handyman suggested different timing and is waiting on the homeowner.";
    case "awaiting_homeowner":
      return "The handyman sent a question or note that needs a homeowner reply.";
    case "confirmed":
      return "The visit is confirmed. The field workspace is unlocked.";
    case "on_my_way":
      return "The handyman is on the way.";
    case "checked_in":
      return "The handyman has checked in and started the visit.";
    case "quoted":
      return "A quote is ready for review.";
    case "in_progress":
      return "The visit is actively in progress.";
    case "completed":
      return "The visit is complete.";
    case "follow_up_recommended":
      return "The visit is complete and follow-up work was recommended.";
    case "cancelled":
      return "This visit was cancelled.";
    case "declined":
      return "This visit was declined.";
    default:
      return "Manage the visit through Chez.";
  }
}

function isoNow() {
  return new Date().toISOString();
}

function isoDatePlus(days: number) {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

const PREVIEW_REQUEST = {
  id: PREVIEW_REQUEST_ID,
  household_id: "00000000-0000-0000-0000-000000000001",
  property_id: "00000000-0000-0000-0000-000000000002",
  contractor_id: "00000000-0000-0000-0000-000000000003",
  visit_task_id: PREVIEW_VISIT_ID,
  created_by_user_id: null,
  request_type: "standard_visit",
  source: "homeowner",
  title: "Confirm Spring Handyman Visit",
  details: "Please confirm the date or suggest another option through the Chez link.",
  preferred_timing: "2026-04-25",
  urgency: "routine",
  status: "sent_to_handyman",
  first_visit_setup_requested: true,
  recommended_lane: "standard_visit",
  quick_upsell_titles: ["Mudroom shelf reinforcement", "TV wire concealment in den"],
  created_at: "2026-04-23T14:20:00.000Z",
  updated_at: "2026-04-23T14:25:00.000Z",
};

function previewMessages(status = PREVIEW_REQUEST.status) {
  return [
    {
      id: "320c9ceb-0ee5-4c85-9c59-647efd6b0001",
      request_id: PREVIEW_REQUEST_ID,
      household_id: PREVIEW_REQUEST.household_id,
      sender_role: "homeowner",
      body: "Requested Spring Handyman Visit for Apr 25.",
      metadata: { event: "requested_visit" },
      created_at: "2026-04-23T14:20:00.000Z",
    },
    {
      id: "320c9ceb-0ee5-4c85-9c59-647efd6b0002",
      request_id: PREVIEW_REQUEST_ID,
      household_id: PREVIEW_REQUEST.household_id,
      sender_role: "haven",
      body:
        "Chez prepared the visit link so the handyman can confirm the date, suggest another option, or begin the visit once it is confirmed.",
      metadata: { event: "invite_ready" },
      created_at: "2026-04-23T14:25:00.000Z",
    },
    {
      id: "320c9ceb-0ee5-4c85-9c59-647efd6b0003",
      request_id: PREVIEW_REQUEST_ID,
      household_id: PREVIEW_REQUEST.household_id,
      sender_role: "vendor",
      body:
        status === "confirmed"
          ? "Confirmed for Apr 25. We will use the Chez field page on arrival."
          : "Please confirm or suggest another date from the Chez link.",
      metadata: { event: "status_preview" },
      created_at: "2026-04-23T14:30:00.000Z",
    },
  ];
}

function previewCoordination(status = PREVIEW_REQUEST.status, messages = previewMessages(status)) {
  return {
    request_id: PREVIEW_REQUEST_ID,
    status,
    status_label: requestStatusLabel(status),
    intro: homeownerSummary(status),
    last_message: messages[messages.length - 1]?.body ?? null,
    scheduled_date: "2026-04-25",
    request_title: PREVIEW_REQUEST.title,
    needs_homeowner_reply: status === "alternate_dates_proposed" || status === "awaiting_homeowner",
  };
}

const PREVIEW_SESSION = {
  id: "c2d0b170-fabd-4f11-9c06-7c6d3e8a0001",
  household_id: "00000000-0000-0000-0000-000000000001",
  property_id: "00000000-0000-0000-0000-000000000002",
  contractor_id: "00000000-0000-0000-0000-000000000003",
  visit_task_id: PREVIEW_VISIT_ID,
  created_by_user_id: null,
  title: "Spring Handyman Visit",
  portal_token: PREVIEW_TOKEN,
  status: "active",
  first_visit: true,
  seed_payload: {
    visitId: PREVIEW_VISIT_ID,
    visitTitle: "Spring Handyman Visit",
    scheduledDate: "2026-04-25",
    dueDate: "2026-04-25",
    firstVisit: true,
    property: {
      name: "River House",
      addressLine: "16 Harbor Lane, Greenwich, CT",
      propertyType: "Single Family Home",
      squareFootage: 6400,
      yearBuilt: 2007,
      systemCount: 5,
      knownSystems: ["HVAC", "Water Heater", "Appliance", "Security", "Electrical"],
      systems: [
        {
          id: "sys-1",
          system_id: "11111111-1111-1111-1111-111111111111",
          name: "Main HVAC",
          category: "HVAC",
          manufacturer: "Carrier",
          model_number: "24VNA9",
          serial_number: "",
          install_date: "2021-05-01",
          notes: "Main mechanical room.",
          last_service_date: "2025-10-01",
          next_service_due: "2026-05-01",
          needs_setup: true,
          serviced: false,
        },
        {
          id: "sys-2",
          system_id: "22222222-2222-2222-2222-222222222222",
          name: "Water Heater",
          category: "Water Heater",
          manufacturer: "Rheem",
          model_number: "",
          serial_number: "",
          install_date: "",
          notes: "Basement utility room.",
          last_service_date: "",
          next_service_due: "",
          needs_setup: true,
          serviced: false,
        },
      ],
    },
    contractorName: "North Shore Handyman Co.",
    contractorPhone: "(203) 555-0148",
    contractorEmail: "crew@northshorehandyman.com",
    homeownerNotes:
      "Please work through the standard spring list, fix the side gate latch if it is quick, and tell us if the mudroom shelving can be tightened while you are there.",
    checklist: [
      {
        id: "check-1",
        title: "Replace smoke and CO detector batteries",
        subtitle: "Standard spring safety sweep across all floors.",
        category: "safety",
        status: "todo",
        source: "included",
        recommended: false,
      },
      {
        id: "check-2",
        title: "Inspect exterior caulking at windows and doors",
        subtitle: "Flag anything that needs a larger follow-up repair.",
        category: "exterior",
        status: "todo",
        source: "included",
        recommended: false,
      },
      {
        id: "check-3",
        title: "Tighten loose cabinet hardware in kitchen and mudroom",
        subtitle: "High-value quick win while on site.",
        category: "interior",
        status: "todo",
        source: "included",
        recommended: false,
      },
      {
        id: "check-4",
        title: "Adjust side gate latch",
        subtitle: "Homeowner reported it sticking after rain.",
        category: "exterior",
        status: "todo",
        source: "punch_list",
        recommended: false,
      },
    ],
    diyClaims: [
      {
        id: "diy-1",
        title: "Swap guest-room light bulbs",
        subtitle: "Homeowner already claimed this one.",
        category: "lighting",
        status: "claimed_by_owner",
        source: "diy",
        recommended: false,
      },
    ],
    quickUpsells: [
      {
        id: "upsell-1",
        title: "Whole-house relamping",
        detail: "Several stair and exterior fixtures are nearing end of life.",
        category: "lighting",
        priceHint: "$150-$450",
        minutesHint: 45,
      },
      {
        id: "upsell-2",
        title: "Mudroom shelf reinforcement",
        detail: "Looks like a 20-minute hardware tighten-up while already on site.",
        category: "storage",
        priceHint: "$75-$150",
        minutesHint: 20,
      },
    ],
    setupPrompts: [
      {
        id: "setup-1",
        title: "Inventory major systems and appliances",
        detail:
          "Capture anything Chez is still missing so the next visit starts with the right context.",
        category: "inventory",
        isRequired: true,
      },
      {
        id: "setup-2",
        title: "Capture model and serial labels",
        detail: "Prioritize HVAC, water heater, laundry, refrigerator, and range.",
        category: "labels",
        isRequired: true,
      },
    ],
    coordination: previewCoordination(),
    recommendations: [
      {
        id: "rec-1",
        title: "Mudroom shelf reinforcement",
        detail: "Looks like a 20-minute tighten-up while already on site.",
        category: "storage",
        priority: "normal",
        create_follow_up: false,
      },
      {
        id: "rec-2",
        title: "TV wire concealment in den",
        detail: "Homeowner asked for a quote if time allows.",
        category: "install",
        priority: "normal",
        create_follow_up: false,
      },
    ],
  },
  last_opened_at: null,
  expires_at: "2026-05-14T12:00:00.000Z",
  created_at: "2026-04-23T14:25:00.000Z",
  updated_at: "2026-04-23T14:25:00.000Z",
};

function previewReportFrom(bodyReport: Record<string, unknown> = {}) {
  const reportStatus =
    typeof bodyReport.reportStatus === "string" ? bodyReport.reportStatus : "draft";
  const coordinationStatus =
    typeof bodyReport.coordinationStatus === "string"
      ? bodyReport.coordinationStatus
      : PREVIEW_REQUEST.status;
  return {
    id: "0b1d9a55-0a01-4bc2-9f0f-7e50de550001",
    portal_session_id: PREVIEW_SESSION.id,
    household_id: PREVIEW_SESSION.household_id,
    property_id: PREVIEW_SESSION.property_id,
    contractor_id: PREVIEW_SESSION.contractor_id,
    visit_task_id: PREVIEW_SESSION.visit_task_id,
    request_id: PREVIEW_REQUEST_ID,
    report_status: reportStatus,
    checklist: Array.isArray(bodyReport.checklist) ? bodyReport.checklist : [],
    setup_prompts: Array.isArray(bodyReport.setupPrompts) ? bodyReport.setupPrompts : [],
    quick_upsells: Array.isArray(bodyReport.quickUpsells) ? bodyReport.quickUpsells : [],
    homeowner_notes:
      typeof bodyReport.homeownerNotes === "string"
        ? bodyReport.homeownerNotes
        : PREVIEW_SESSION.seed_payload.homeownerNotes,
    field_notes: typeof bodyReport.fieldNotes === "string" ? bodyReport.fieldNotes : "",
    systems_snapshot: Array.isArray(bodyReport.systemsSnapshot)
      ? bodyReport.systemsSnapshot
      : PREVIEW_SESSION.seed_payload.property.systems,
    recommendations: Array.isArray(bodyReport.recommendations)
      ? bodyReport.recommendations
      : PREVIEW_SESSION.seed_payload.recommendations,
    coordination_status: coordinationStatus,
    started_at: typeof bodyReport.startedAt === "string" ? bodyReport.startedAt : null,
    completed_at: typeof bodyReport.completedAt === "string" ? bodyReport.completedAt : null,
    last_synced_at: isoNow(),
    created_at: "2026-04-23T14:25:00.000Z",
    updated_at: isoNow(),
  };
}

function normalizeChecklist(raw: unknown, seed: Record<string, unknown>[] = []) {
  const base = isNonEmptyArray(raw) ? raw : seed;
  return base.map((item) => ({
    ...item,
    status: compactString((item as Record<string, unknown>).status) || "todo",
  }));
}

function normalizeSetupPrompts(raw: unknown, seed: Record<string, unknown>[] = []) {
  const base = isNonEmptyArray(raw) ? raw : seed;
  return base.map((prompt) => ({
    ...prompt,
    done: Boolean((prompt as Record<string, unknown>).done),
  }));
}

function normalizeUpsells(raw: unknown, seed: Record<string, unknown>[] = []) {
  const base = isNonEmptyArray(raw) ? raw : seed;
  return base.map((upsell) => ({
    ...upsell,
    added: Boolean((upsell as Record<string, unknown>).added),
  }));
}

function normalizeSystems(raw: unknown, seed: Record<string, unknown>[] = []) {
  const base = isNonEmptyArray(raw) ? raw : seed;
  return base
    .map((system, index) => {
      const row = system as Record<string, unknown>;
      const name = compactString(row.name);
      const category = compactString(row.category) || "Other";
      if (!name) return null;
      return {
        id: compactString(row.id) || `system-${index + 1}`,
        system_id: compactString(row.system_id) || null,
        name,
        category,
        manufacturer: compactString(row.manufacturer) || null,
        model_number: compactString(row.model_number) || null,
        serial_number: compactString(row.serial_number) || null,
        install_date: compactString(row.install_date) || null,
        notes: compactString(row.notes) || null,
        last_service_date: compactString(row.last_service_date) || null,
        next_service_due: compactString(row.next_service_due) || null,
        catalog_entry_id: compactString(row.catalog_entry_id) || null,
        catalog_series: compactString(row.catalog_series) || null,
        catalog_model_name: compactString(row.catalog_model_name) || null,
        catalog_features: Array.isArray(row.catalog_features)
          ? row.catalog_features.map((feature) => compactString(feature)).filter(Boolean)
          : [],
        catalog_fuel_type: compactString(row.catalog_fuel_type) || null,
        catalog_enriched_at: compactString(row.catalog_enriched_at) || null,
        subtype: compactString(row.subtype) || null,
        custom_category_name: compactString(row.custom_category_name) || null,
        catalog_display_name: compactString(row.catalog_display_name) || null,
        catalog_subtitle: compactString(row.catalog_subtitle) || null,
        identification_confidence: compactString(row.identification_confidence) || null,
        identified_raw_text: compactString(row.identified_raw_text) || null,
        label_photo_name: compactString(row.label_photo_name) || null,
        photo_captured_at: compactString(row.photo_captured_at) || null,
        needs_setup: Boolean(row.needs_setup),
        serviced: Boolean(row.serviced),
      };
    })
    .filter(Boolean);
}

function normalizeRecommendations(raw: unknown, seed: Record<string, unknown>[] = []) {
  const base = isNonEmptyArray(raw) ? raw : seed;
  return base
    .map((recommendation, index) => {
      const row = recommendation as Record<string, unknown>;
      const title = compactString(row.title);
      if (!title) return null;
      return {
        id: compactString(row.id) || `recommendation-${index + 1}`,
        title,
        detail: compactString(row.detail),
        category: compactString(row.category) || "maintenance",
        priority: compactString(row.priority) || "normal",
        create_follow_up: Boolean(row.create_follow_up),
      };
    })
    .filter(Boolean);
}

/**
 * Phase 73 sub-phase C: home-profile snapshot for the field PWA.
 *
 * Pulls a read-only summary of:
 *   - home_systems for the property (category, name, last serviced)
 *   - recent invoices (documents with category like 'Home Bill/Invoice')
 *   - open handyman_punch_items for the property
 *
 * The portal_token already gates access at the session level; this
 * helper just fetches whatever the session's household_id +
 * property_id resolve to. Service-role queries — RLS is bypassed.
 *
 * Everything is sized so the technician sees enough context to do the
 * job: 12 systems, 6 invoices, 12 punch items. Larger payloads slow
 * the field PWA's offline cache and aren't useful in the field.
 */
async function fetchHomeProfile(
  supabase: ReturnType<typeof createClient>,
  params: { householdId: string; propertyId: string | null },
) {
  if (!params.householdId) {
    return { systems: [], recentInvoices: [], punchList: [], openTasks: [] };
  }

  const propertyFilter = params.propertyId;

  const [systemsResult, invoicesResult, punchResult, openTasksResult] = await Promise.all([
    propertyFilter
      ? supabase
          .from("home_systems")
          .select(
            "id, category, name, manufacturer, model_number, last_service_date, service_interval_days, notes",
          )
          .eq("property_id", propertyFilter)
          .is("archived_at", null)
          .order("category", { ascending: true })
          .order("name", { ascending: true })
          .limit(12)
      : Promise.resolve({ data: [], error: null }),
    supabase
      .from("documents")
      .select("id, name, category, summary, document_date, total_amount, vendor_name")
      .eq("household_id", params.householdId)
      .ilike("category", "%invoice%")
      .order("document_date", { ascending: false })
      .limit(6),
    propertyFilter
      ? supabase
          .from("handyman_punch_items")
          .select("id, title, description, notes, source, created_at, estimated_minutes")
          .eq("property_id", propertyFilter)
          .is("archived_at", null)
          .is("completed_at", null)
          .order("created_at", { ascending: false })
          .limit(12)
      : Promise.resolve({ data: [], error: null }),
    propertyFilter
      ? supabase
          .from("maintenance_tasks")
          .select(
            "id, title, description, frequency, next_due_date, priority, assigned_route, system_id, last_completed_date",
          )
          .eq("property_id", propertyFilter)
          .is("archived_at", null)
          .order("next_due_date", { ascending: true, nullsFirst: false })
          .limit(20)
      : Promise.resolve({ data: [], error: null }),
  ]);

  if (systemsResult.error) {
    console.error("[handyman-portal] systems fetch error", systemsResult.error);
  }
  if (invoicesResult.error) {
    console.error("[handyman-portal] invoices fetch error", invoicesResult.error);
  }
  if (punchResult.error) {
    console.error("[handyman-portal] punch list fetch error", punchResult.error);
  }
  if (openTasksResult.error) {
    console.error("[handyman-portal] open tasks fetch error", openTasksResult.error);
  }

  return {
    systems: ((systemsResult.data ?? []) as Record<string, unknown>[]).map((row) => ({
      id: compactString(row.id),
      category: compactString(row.category),
      name: compactString(row.name),
      manufacturer: compactString(row.manufacturer) || null,
      modelNumber: compactString(row.model_number) || null,
      lastServiceDate: row.last_service_date ?? null,
      serviceIntervalDays: row.service_interval_days ?? null,
      notes: compactString(row.notes) || null,
    })),
    recentInvoices: ((invoicesResult.data ?? []) as Record<string, unknown>[]).map((row) => ({
      id: compactString(row.id),
      name: compactString(row.name),
      category: compactString(row.category),
      summary: compactString(row.summary) || null,
      documentDate: row.document_date ?? null,
      totalAmount: row.total_amount ?? null,
      vendorName: compactString(row.vendor_name) || null,
    })),
    punchList: ((punchResult.data ?? []) as Record<string, unknown>[]).map((row) => ({
      id: compactString(row.id),
      // The punch items table uses `title` and `description`. Map to
      // `label` / `notes` on the wire so the field PWA's existing
      // shape is preserved; `description` falls back to the legacy
      // `notes` column when older inserts populated only that one.
      label: compactString(row.title),
      notes: compactString(row.description) || compactString(row.notes) || null,
      source: compactString(row.source) || null,
      estimatedMinutes: row.estimated_minutes ?? null,
      createdAt: row.created_at ?? null,
    })),
    openTasks: ((openTasksResult.data ?? []) as Record<string, unknown>[]).map((row) => ({
      id: compactString(row.id),
      title: compactString(row.title),
      description: compactString(row.description) || null,
      frequency: compactString(row.frequency) || null,
      nextDueDate: row.next_due_date ?? null,
      priority: compactString(row.priority) || null,
      assignedRoute: compactString(row.assigned_route) || null,
      systemId: compactString(row.system_id) || null,
    })),
  };
}

function previewHomeProfile() {
  return {
    systems: [
      {
        id: "preview-system-1",
        category: "HVAC",
        name: "Furnace · 1st Floor",
        manufacturer: "Trane",
        modelNumber: "XR16",
        lastServiceDate: "2025-11-12",
        serviceIntervalDays: 365,
        notes: "Filter slot is on the right side of the unit.",
      },
      {
        id: "preview-system-2",
        category: "Plumbing",
        name: "Water heater · Basement",
        manufacturer: "Rinnai",
        modelNumber: "RUR199i",
        lastServiceDate: "2026-01-04",
        serviceIntervalDays: 365,
        notes: null,
      },
    ],
    recentInvoices: [
      {
        id: "preview-invoice-1",
        name: "Tyler Heating · Tune-up.pdf",
        category: "Home Bill/Invoice",
        summary: "Annual furnace tune-up. Replaced humidifier filter.",
        documentDate: "2025-11-12",
        totalAmount: 285,
        vendorName: "Tyler Heating",
      },
    ],
    punchList: [
      {
        id: "preview-punch-1",
        label: "Re-caulk bath and shower seams",
        notes: "Mostly upstairs guest bath.",
        source: "manual",
        createdAt: "2026-04-20T15:00:00.000Z",
      },
      {
        id: "preview-punch-2",
        label: "Lubricate squeaky door hinges",
        notes: null,
        source: "recommended",
        createdAt: "2026-04-22T10:00:00.000Z",
      },
    ],
  };
}

async function fetchRequestContext(
  supabase: ReturnType<typeof createClient>,
  visitTaskId: string | null,
) {
  if (!visitTaskId) return { request: null, messages: [] };

  const { data: request, error: requestError } = await supabase
    .from("handyman_requests")
    .select("*")
    .eq("visit_task_id", visitTaskId)
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (requestError) {
    console.error("[handyman-portal] request fetch error", requestError);
    return { request: null, messages: [] };
  }

  if (!request) return { request: null, messages: [] };

  const { data: messages, error: messageError } = await supabase
    .from("handyman_request_messages")
    .select("*")
    .eq("request_id", request.id)
    .order("created_at", { ascending: true });

  if (messageError) {
    console.error("[handyman-portal] message fetch error", messageError);
    return { request, messages: [] };
  }

  return { request, messages: messages ?? [] };
}

async function appendRequestMessage(
  supabase: ReturnType<typeof createClient>,
  requestId: string,
  householdId: string,
  senderRole: string,
  body: string,
  metadata: Record<string, string> = {},
) {
  const trimmedBody = body.trim();
  if (!trimmedBody) return;

  await supabase.from("handyman_request_messages").insert({
    request_id: requestId,
    household_id: householdId,
    sender_role: senderRole,
    body: trimmedBody,
    metadata,
  });
}

async function ensureRequest(
  supabase: ReturnType<typeof createClient>,
  session: Record<string, unknown>,
  existingRequest: Record<string, unknown> | null,
  status: string | null,
) {
  if (existingRequest) return existingRequest;
  if (!session.visit_task_id) return null;

  const payload = {
    household_id: session.household_id,
    property_id: session.property_id,
    contractor_id: session.contractor_id,
    visit_task_id: session.visit_task_id,
    request_type: "standard_visit",
    source: "vendor",
    title: session.title,
    details: "Manage this Chez handyman visit through the magic link.",
    preferred_timing: (session.seed_payload as Record<string, unknown>)?.scheduledDate ?? null,
    urgency: "routine",
    status: status ?? "sent_to_handyman",
    first_visit_setup_requested: Boolean(session.first_visit),
    recommended_lane: "standard_visit",
    quick_upsell_titles: [],
  };

  const { data, error } = await supabase
    .from("handyman_requests")
    .insert(payload)
    .select()
    .single();

  if (error) {
    console.error("[handyman-portal] request create error", error);
    return null;
  }

  return data;
}

function actionMessage(action: Record<string, unknown>, scheduledDate: string | null) {
  const note = compactString(action.message);
  const proposedDate = compactString(action.proposedDate);
  switch (action.type) {
    case "confirm_date":
      return {
        status: "confirmed",
        body: proposedDate
          ? `Confirmed for ${proposedDate}.`
          : scheduledDate
            ? `Confirmed for ${scheduledDate}.`
            : "Confirmed the requested visit.",
      };
    case "propose_other_dates":
      return {
        status: "alternate_dates_proposed",
        body:
          note ||
          (proposedDate
            ? `Can we move this to ${proposedDate}?`
            : "Can we look at other dates for this visit?"),
      };
    case "ask_question":
      return {
        status: "awaiting_homeowner",
        body: note || "I have a question before confirming this visit.",
      };
    case "decline_visit":
      return {
        status: "declined",
        body: note || "We need to decline this visit.",
      };
    default:
      return null;
  }
}

function recommendationDueDate(priority: string) {
  switch (priority) {
    case "high":
      return isoDatePlus(7);
    case "low":
      return isoDatePlus(30);
    default:
      return isoDatePlus(14);
  }
}

async function upsertSystems(
  supabase: ReturnType<typeof createClient>,
  session: Record<string, unknown>,
  systemsSnapshot: Record<string, unknown>[],
) {
  const hydrated: Record<string, unknown>[] = [];
  const existingSelect = `
    id,
    subtype,
    custom_category_name,
    manufacturer,
    model_number,
    serial_number,
    install_date,
    notes,
    last_service_date,
    next_service_due,
    catalog_entry_id,
    catalog_series,
    catalog_model_name,
    catalog_features,
    catalog_fuel_type,
    catalog_enriched_at
  `;

  for (const system of systemsSnapshot) {
    const propertyId = compactString(session.property_id);
    const householdId = compactString(session.household_id);
    const name = compactString(system.name);
    const category = compactString(system.category) || "Other";
    const catalogEntryId = compactString(system.catalog_entry_id);
    if (!propertyId || !householdId || !name) {
      hydrated.push(system);
      continue;
    }

    let systemId = compactString(system.system_id);
    let existingRow: Record<string, unknown> | null = null;
    if (systemId) {
      const { data: existing } = await supabase
        .from("home_systems")
        .select(existingSelect)
        .eq("id", systemId)
        .limit(1)
        .maybeSingle();
      existingRow = existing as Record<string, unknown> | null;
    }

    if (!systemId) {
      if (catalogEntryId) {
        const { data: catalogMatch } = await supabase
          .from("home_systems")
          .select(existingSelect)
          .eq("property_id", propertyId)
          .eq("catalog_entry_id", catalogEntryId)
          .limit(1)
          .maybeSingle();
        systemId = catalogMatch?.id ?? "";
        existingRow = (catalogMatch as Record<string, unknown> | null) ?? existingRow;
      }
    }

    if (!systemId) {
      const { data: match } = await supabase
        .from("home_systems")
        .select(existingSelect)
        .eq("property_id", propertyId)
        .ilike("name", name)
        .eq("category", category)
        .limit(1)
        .maybeSingle();
      systemId = match?.id ?? "";
      existingRow = (match as Record<string, unknown> | null) ?? existingRow;
    }

    const existingFeatures = Array.isArray(existingRow?.catalog_features)
      ? existingRow.catalog_features.map((feature) => compactString(feature)).filter(Boolean)
      : [];
    const updates = {
      name,
      category,
      subtype: compactString(system.subtype) || compactString(existingRow?.subtype) || null,
      custom_category_name:
        compactString(system.custom_category_name) ||
        compactString(existingRow?.custom_category_name) ||
        null,
      manufacturer: compactString(system.manufacturer) || compactString(existingRow?.manufacturer) || null,
      model_number: compactString(system.model_number) || compactString(existingRow?.model_number) || null,
      serial_number: compactString(system.serial_number) || compactString(existingRow?.serial_number) || null,
      install_date: compactString(system.install_date) || compactString(existingRow?.install_date) || null,
      notes: compactString(system.notes) || compactString(existingRow?.notes) || null,
      last_service_date:
        compactString(system.last_service_date) || compactString(existingRow?.last_service_date) || null,
      next_service_due:
        compactString(system.next_service_due) || compactString(existingRow?.next_service_due) || null,
      catalog_entry_id: catalogEntryId || compactString(existingRow?.catalog_entry_id) || null,
      catalog_series: compactString(system.catalog_series) || compactString(existingRow?.catalog_series) || null,
      catalog_model_name:
        compactString(system.catalog_model_name) || compactString(existingRow?.catalog_model_name) || null,
      catalog_features: Array.isArray(system.catalog_features)
        ? system.catalog_features.map((feature) => compactString(feature)).filter(Boolean)
        : existingFeatures,
      catalog_fuel_type:
        compactString(system.catalog_fuel_type) || compactString(existingRow?.catalog_fuel_type) || null,
      catalog_enriched_at:
        compactString(system.catalog_enriched_at) || compactString(existingRow?.catalog_enriched_at) || null,
    };

    if (systemId) {
      await supabase
        .from("home_systems")
        .update(updates)
        .eq("id", systemId);
      hydrated.push({ ...system, ...updates, system_id: systemId });
      continue;
    }

    const { data: inserted, error } = await supabase
      .from("home_systems")
      .insert({
        property_id: propertyId,
        household_id: householdId,
        ...updates,
      })
      .select("id")
      .single();

    if (error) {
      console.error("[handyman-portal] create system error", error);
      hydrated.push(system);
      continue;
    }

    hydrated.push({ ...system, ...updates, system_id: inserted.id });
  }

  return hydrated;
}

async function createCompletionWritebacks(
  supabase: ReturnType<typeof createClient>,
  session: Record<string, unknown>,
  reportStatus: string,
  previouslyCompleted: boolean,
  systemsSnapshot: Record<string, unknown>[],
  recommendations: Record<string, unknown>[],
) {
  if (reportStatus !== "completed" || previouslyCompleted) return;

  const householdId = compactString(session.household_id);
  const propertyId = compactString(session.property_id);
  const contractorId = compactString(session.contractor_id) || null;
  const visitTitle = compactString(session.title) || "Handyman visit";
  const completedAt = isoDatePlus(0);

  for (const system of systemsSnapshot) {
    if (!system.serviced || !compactString(system.system_id) || !propertyId || !householdId) continue;
    await supabase.from("service_records").insert({
      property_id: propertyId,
      household_id: householdId,
      system_id: compactString(system.system_id),
      contractor_id: contractorId,
      service_date: completedAt,
      service_type: "Handyman visit",
      description: `${visitTitle}: ${compactString(system.name)}`,
      notes: compactString(system.notes) || `Updated during ${visitTitle}.`,
    });
  }

  for (const recommendation of recommendations) {
    if (!recommendation.create_follow_up || !propertyId || !householdId) continue;
    await supabase.from("maintenance_tasks").insert({
      property_id: propertyId,
      household_id: householdId,
      title: compactString(recommendation.title),
      description: compactString(recommendation.detail) || null,
      frequency: "Once",
      next_due_date: recommendationDueDate(compactString(recommendation.priority)),
      priority: compactString(recommendation.priority) === "high" ? "High" : "Medium",
      assignment_type: "either",
      needs_vendor: false,
      notes: `Created from Haven handyman recommendation for ${visitTitle}.`,
      assigned_route: "vendor",
      service_key: compactString(recommendation.category) || null,
    });
  }
}

/**
 * Phase 73 sub-phase D: technician marks one of the homeowner's
 * punch-list items complete from the field PWA. We refuse the write
 * if the punch item belongs to a different household than the portal
 * session — a portal_token is scoped to one household, so this is the
 * authorization check.
 */
async function completePunchItemForVisit(
  supabase: ReturnType<typeof createClient>,
  session: Record<string, unknown>,
  punchItemId: string,
) {
  const householdId = compactString(session.household_id);
  if (!householdId || !punchItemId) return;

  const { data: punchItem, error: fetchError } = await supabase
    .from("handyman_punch_items")
    .select("id, household_id, completed_at")
    .eq("id", punchItemId)
    .maybeSingle();

  if (fetchError) {
    console.error("[handyman-portal] punch item lookup error", fetchError);
    return;
  }
  if (!punchItem) return;
  if (compactString(punchItem.household_id) !== householdId) {
    console.warn("[handyman-portal] punch item household mismatch — skipping");
    return;
  }
  if (punchItem.completed_at) return;

  const visitTaskId = compactString(session.visit_task_id) || null;

  const { error: updateError } = await supabase
    .from("handyman_punch_items")
    .update({
      completed_at: isoNow(),
      completed_visit_task_id: visitTaskId,
    })
    .eq("id", punchItemId);

  if (updateError) {
    console.error("[handyman-portal] punch item complete error", updateError);
  }
}

/**
 * Phase 73 sub-phase D: technician marks an open homeowner
 * maintenance task complete from the field PWA. Same household-scoped
 * authorization check as the punch-item path.
 */
async function completeTaskForVisit(
  supabase: ReturnType<typeof createClient>,
  session: Record<string, unknown>,
  taskId: string,
) {
  const householdId = compactString(session.household_id);
  if (!householdId || !taskId) return;

  const { data: task, error: fetchError } = await supabase
    .from("maintenance_tasks")
    .select("id, household_id, frequency, system_id, last_completed_date, archived_at")
    .eq("id", taskId)
    .maybeSingle();

  if (fetchError) {
    console.error("[handyman-portal] task lookup error", fetchError);
    return;
  }
  if (!task) return;
  if (compactString(task.household_id) !== householdId) {
    console.warn("[handyman-portal] task household mismatch — skipping");
    return;
  }
  if (task.archived_at) return;

  const completedAt = isoNow();
  // The maintenance_tasks table tracks completion via `last_completed_date`
  // — there's no separate `completed_at` column. The homeowner-side
  // reconciler reads this date and recomputes `next_due_date` from
  // the task's cadence on the next reload, so we don't need to bump
  // it here.
  const { error: updateError } = await supabase
    .from("maintenance_tasks")
    .update({
      last_completed_date: completedAt.slice(0, 10),
      updated_at: completedAt,
    })
    .eq("id", taskId);

  if (updateError) {
    console.error("[handyman-portal] task complete error", updateError);
  }

  // Stamp the home_systems.last_service_date too so the visit shows
  // up in the system's service history right away.
  const systemId = compactString(task.system_id);
  if (systemId) {
    await supabase
      .from("home_systems")
      .update({
        last_service_date: completedAt.slice(0, 10),
        updated_at: completedAt,
      })
      .eq("id", systemId);
  }
}

async function syncCoordinationState(
  supabase: ReturnType<typeof createClient>,
  session: Record<string, unknown>,
  existingRequest: Record<string, unknown> | null,
  report: Record<string, unknown>,
  coordinationAction: Record<string, unknown> | null,
  recommendations: Record<string, unknown>[],
) {
  let request = existingRequest;
  let nextStatus = compactString(report.coordinationStatus) || compactString(request?.status);
  const statusFromAction = coordinationAction ? actionMessage(coordinationAction, compactString(report.scheduledDate)) : null;

  if (statusFromAction) {
    nextStatus = statusFromAction.status;
  } else if (report.reportStatus === "in_progress") {
    nextStatus = "checked_in";
  } else if (report.reportStatus === "completed") {
    nextStatus = recommendations.some((item) => item.create_follow_up)
      ? "follow_up_recommended"
      : "completed";
  }

  request = await ensureRequest(supabase, session, request, nextStatus || null);
  if (!request) return { request: null, messages: [] as Record<string, unknown>[] };

  if (nextStatus && request.status !== nextStatus) {
    const update: Record<string, unknown> = { status: nextStatus, updated_at: isoNow() };
    const proposedDate = compactString(coordinationAction?.proposedDate);
    if (proposedDate) {
      update.preferred_timing = proposedDate;
    }

    const { data: updated } = await supabase
      .from("handyman_requests")
      .update(update)
      .eq("id", request.id)
      .select()
      .single();
    request = updated ?? request;
  }

  if (statusFromAction) {
    await appendRequestMessage(
      supabase,
      request.id,
      request.household_id,
      "vendor",
      statusFromAction.body,
      {
        event: compactString(coordinationAction?.type) || "coordination_update",
        proposed_date: compactString(coordinationAction?.proposedDate),
      },
    );
  }

  const refreshed = await fetchRequestContext(supabase, compactString(session.visit_task_id) || null);
  return refreshed;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);

    if (req.method === "GET") {
      const token = url.searchParams.get("token");
      if (!token) return json({ error: "Missing token" }, 400);

      if (token === PREVIEW_TOKEN) {
        return json({
          session: PREVIEW_SESSION,
          report: null,
          request: PREVIEW_REQUEST,
          messages: previewMessages(),
          homeProfile: previewHomeProfile(),
        });
      }

      const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      );

      const { data: session, error: sessionError } = await supabase
        .from("handyman_portal_sessions")
        .select("*")
        .eq("portal_token", token)
        .limit(1)
        .maybeSingle();

      if (sessionError) {
        console.error("[handyman-portal] session fetch error", sessionError);
        return json({ error: "Failed to load portal session" }, 500);
      }
      if (!session) return json({ error: "Portal not found" }, 404);

      if (session.status === "revoked") {
        return json({ error: "Portal has been revoked" }, 410);
      }
      if (session.expires_at && new Date(session.expires_at).getTime() < Date.now()) {
        await supabase
          .from("handyman_portal_sessions")
          .update({ status: "expired", updated_at: isoNow() })
          .eq("id", session.id);
        return json({ error: "Portal has expired" }, 410);
      }

      const { data: report } = await supabase
        .from("handyman_visit_reports")
        .select("*")
        .eq("portal_session_id", session.id)
        .limit(1)
        .maybeSingle();

      const requestContext = await fetchRequestContext(
        supabase,
        compactString(session.visit_task_id) || null,
      );

      const homeProfile = await fetchHomeProfile(supabase, {
        householdId: compactString(session.household_id),
        propertyId: compactString(session.property_id) || null,
      });

      await supabase
        .from("handyman_portal_sessions")
        .update({
          last_opened_at: isoNow(),
          updated_at: isoNow(),
        })
        .eq("id", session.id);

      return json({
        session,
        report,
        request: requestContext.request,
        messages: requestContext.messages,
        homeProfile,
      });
    }

    if (req.method === "POST") {
      const body = await req.json();
      const token = typeof body?.token === "string" ? body.token : null;
      const report = (body?.report ?? {}) as Record<string, unknown>;
      const coordinationAction =
        body?.coordinationAction && typeof body.coordinationAction === "object"
          ? (body.coordinationAction as Record<string, unknown>)
          : null;
      // Phase 73 sub-phase D: technician contributions back. The field
      // PWA can mark a homeowner punch item or maintenance task complete
      // in the same POST request that saves the visit report draft.
      // Both actions are scoped by portal_session — the technician can
      // only act on items that belong to the household tied to their
      // token.
      const completePunchItemId = compactString(body?.completePunchItemId);
      const completeTaskId = compactString(body?.completeTaskId);

      if (!token) return json({ error: "Missing token" }, 400);

      if (token === PREVIEW_TOKEN) {
        const action = coordinationAction ? actionMessage(coordinationAction, "2026-04-25") : null;
        const requestStatus =
          action?.status ||
          (report.reportStatus === "in_progress"
            ? "checked_in"
            : report.reportStatus === "completed"
              ? "completed"
              : compactString(report.coordinationStatus) || PREVIEW_REQUEST.status);
        const messages = previewMessages(requestStatus);
        if (action) {
          messages.push({
            id: crypto.randomUUID(),
            request_id: PREVIEW_REQUEST_ID,
            household_id: PREVIEW_REQUEST.household_id,
            sender_role: "vendor",
            body: action.body,
            metadata: { event: compactString(coordinationAction?.type) || "preview_action" },
            created_at: isoNow(),
          });
        }
        const savedReport = previewReportFrom({
          ...report,
          coordinationStatus: requestStatus,
        });
        return json({
          success: true,
          session: {
            ...PREVIEW_SESSION,
            status: savedReport.report_status === "completed" ? "completed" : "active",
            last_opened_at: isoNow(),
            updated_at: isoNow(),
            seed_payload: {
              ...PREVIEW_SESSION.seed_payload,
              coordination: previewCoordination(requestStatus, messages),
            },
          },
          report: savedReport,
          request: {
            ...PREVIEW_REQUEST,
            status: requestStatus,
            updated_at: isoNow(),
          },
          messages,
        });
      }

      const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      );

      const { data: session, error: sessionError } = await supabase
        .from("handyman_portal_sessions")
        .select("*")
        .eq("portal_token", token)
        .limit(1)
        .maybeSingle();

      if (sessionError) {
        console.error("[handyman-portal] session write fetch error", sessionError);
        return json({ error: "Failed to load portal session" }, 500);
      }
      if (!session) return json({ error: "Portal not found" }, 404);

      const seedPayload = (session.seed_payload ?? {}) as Record<string, unknown>;
      const propertySeed = (seedPayload.property ?? {}) as Record<string, unknown>;

      const { data: existing } = await supabase
        .from("handyman_visit_reports")
        .select("id, report_status")
        .eq("portal_session_id", session.id)
        .limit(1)
        .maybeSingle();

      const previouslyCompleted = existing?.report_status === "completed";
      const requestContext = await fetchRequestContext(
        supabase,
        compactString(session.visit_task_id) || null,
      );

      const checklist = normalizeChecklist(report.checklist, (seedPayload.checklist as Record<string, unknown>[]) ?? []);
      const setupPrompts = normalizeSetupPrompts(
        report.setupPrompts,
        (seedPayload.setupPrompts as Record<string, unknown>[]) ?? [],
      );
      const quickUpsells = normalizeUpsells(
        report.quickUpsells,
        (seedPayload.quickUpsells as Record<string, unknown>[]) ?? [],
      );
      const systemsSnapshot = await upsertSystems(
        supabase,
        session,
        normalizeSystems(report.systemsSnapshot, (propertySeed.systems as Record<string, unknown>[]) ?? []),
      );
      const recommendations = normalizeRecommendations(
        report.recommendations,
        (seedPayload.recommendations as Record<string, unknown>[]) ?? [],
      );

      const coordination = await syncCoordinationState(
        supabase,
        session,
        requestContext.request,
        report,
        coordinationAction,
        recommendations,
      );

      const payload = {
        portal_session_id: session.id,
        household_id: session.household_id,
        property_id: session.property_id,
        contractor_id: session.contractor_id,
        visit_task_id: session.visit_task_id,
        request_id: coordination.request?.id ?? requestContext.request?.id ?? null,
        report_status: compactString(report.reportStatus) || "draft",
        checklist,
        setup_prompts: setupPrompts,
        quick_upsells: quickUpsells,
        homeowner_notes: compactString(report.homeownerNotes) || null,
        field_notes: compactString(report.fieldNotes) || null,
        systems_snapshot: systemsSnapshot,
        recommendations,
        coordination_status:
          coordination.request?.status ||
          compactString(report.coordinationStatus) ||
          requestContext.request?.status ||
          null,
        started_at: compactString(report.startedAt) || null,
        completed_at: compactString(report.completedAt) || null,
        last_synced_at: isoNow(),
        updated_at: isoNow(),
      };

      const reportMutation = existing
        ? supabase
            .from("handyman_visit_reports")
            .update(payload)
            .eq("id", existing.id)
            .select()
            .single()
        : supabase
            .from("handyman_visit_reports")
            .insert(payload)
            .select()
            .single();

      const { data: savedReport, error: reportError } = await reportMutation;
      if (reportError) {
        console.error("[handyman-portal] report save error", reportError);
        return json({ error: "Failed to save report" }, 500);
      }

      await createCompletionWritebacks(
        supabase,
        session,
        payload.report_status,
        previouslyCompleted,
        systemsSnapshot,
        recommendations,
      );

      // Phase 73 sub-phase D: scoped technician writebacks. Both
      // actions check that the targeted row belongs to the same
      // household as the portal session so a stolen token can't be
      // used to complete arbitrary household items.
      if (completePunchItemId) {
        await completePunchItemForVisit(
          supabase,
          session,
          completePunchItemId,
        );
      }
      if (completeTaskId) {
        await completeTaskForVisit(
          supabase,
          session,
          completeTaskId,
        );
      }

      const sessionStatus = payload.report_status === "completed" ? "completed" : "active";
      const { data: updatedSession } = await supabase
        .from("handyman_portal_sessions")
        .update({
          status: sessionStatus,
          last_opened_at: isoNow(),
          updated_at: isoNow(),
        })
        .eq("id", session.id)
        .select()
        .single();

      const refreshedHomeProfile = await fetchHomeProfile(supabase, {
        householdId: compactString(session.household_id),
        propertyId: compactString(session.property_id) || null,
      });

      return json({
        success: true,
        session: updatedSession ?? session,
        report: savedReport,
        request: coordination.request,
        messages: coordination.messages,
        homeProfile: refreshedHomeProfile,
      });
    }

    return json({ error: "Method not allowed" }, 405);
  } catch (error) {
    console.error("[handyman-portal] unhandled error", error);
    return json({ error: "Internal error" }, 500);
  }
});

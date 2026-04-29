// =============================================================================
// admin-architecture.js — Object Browser
// =============================================================================
// A walkable map of every object the admin/iOS app cares about: what it
// represents, its key fields, what it belongs to, what it owns, and how
// it ties into the rest of the system. Click any relationship to jump
// to the related object.
//
// Hand-curated rather than parsed from Swift because the actual story
// is mostly about cross-table relationships that no single Swift file
// captures.

export const OBJECT_MAP = [
  {
    key: "property",
    emoji: "🏠",
    name: "Property",
    cluster: "Home",
    purpose:
      "The home itself. Everything else hangs off this — systems, tasks, vendors, family, vehicles, documents, projects.",
    primaryKeys: ["id (uuid)", "household_id (uuid)"],
    keyFields: [
      { label: "address / city / state / zip", desc: "The physical address. State drives regional pack." },
      { label: "year_built", desc: "Token used in quiz titles ('Your 1962 home…')." },
      { label: "square_footage", desc: "Token used in quiz titles." },
      { label: "estimated_value / range", desc: "ATTOM-derived. Drives the Investment Summary card." },
      { label: "purchase_price / purchase_date", desc: "From Q4. Anchors the equity calculation." },
      { label: "regional_pack", desc: "Auto-derived from state. Gates regional templates (Northeast, etc.)." },
      { label: "house_quiz_state (JSONB)", desc: "Every quiz answer this property has given, plus completion timestamps." },
      { label: "attributes (JSONB)", desc: "Free-form flags like has_pets, has_humidifier, has_pool_safety_fence — read by the reconciler to filter templates." },
    ],
    relationships: [
      { kind: "owns", target: "home_system", label: "Has many home systems", desc: "One row per HVAC unit / water heater / pool / etc." },
      { kind: "owns", target: "maintenance_task", label: "Has many maintenance tasks", desc: "Concrete to-dos seeded for this property." },
      { kind: "owns", target: "routine", label: "Has many routines", desc: "Recurring rhythms — cleaning, trash, lawn care." },
      { kind: "owns", target: "family_member", label: "Has many family members + staff", desc: "Spouse, kids, home manager, household staff." },
      { kind: "owns", target: "vehicle", label: "Has many vehicles", desc: "Cars in the household." },
      { kind: "owns", target: "contractor", label: "Has many contractors", desc: "Vendors the household has hired or considered." },
      { kind: "owns", target: "document", label: "Has many documents", desc: "Anything uploaded — bills, warranties, plans." },
      { kind: "owns", target: "project", label: "Has many projects", desc: "Bigger one-off jobs and renovations." },
    ],
  },
  {
    key: "home_system",
    emoji: "⚙️",
    name: "Home System",
    cluster: "Home",
    purpose:
      "A physical system at a property — the HVAC, the water heater, the pool, the chimney. The bridge between abstract System Categories and concrete tasks.",
    primaryKeys: ["id (uuid)", "property_id (uuid)", "category (text)"],
    keyFields: [
      { label: "category", desc: "Matches a System Category key (HVAC, Plumbing, Pool/Spa, etc.)." },
      { label: "name", desc: "User-facing label for this specific instance ('Main HVAC', 'Pool heater')." },
      { label: "subtype / subtypes", desc: "Tags like 'tank', 'natural_lawn', 'pool_chlorine' that templates gate on." },
      { label: "parent_system_id", desc: "Optional — sub-systems like 'Filter under HVAC' link upward." },
      { label: "service_interval_days", desc: "Optional override for cadence (set from quiz, invoice, or manual)." },
      { label: "last_service_date", desc: "Refreshed by invoice processing; drives next-due math." },
    ],
    relationships: [
      { kind: "belongs_to", target: "property", label: "Belongs to a property" },
      { kind: "references", target: "system_category", label: "Categorized by a System Category", desc: "Matched by the `category` text column." },
      { kind: "owns", target: "maintenance_task", label: "Has many maintenance tasks", desc: "Tasks scoped to this specific system." },
    ],
  },
  {
    key: "maintenance_task",
    emoji: "✅",
    name: "Maintenance Task",
    cluster: "Tasks",
    purpose:
      "A concrete to-do for a homeowner — 'Schedule annual roof inspection on May 1'. Created by the reconciler from a Maintenance Template, or manually by the homeowner.",
    primaryKeys: ["id (uuid)", "property_id (uuid)", "template_id (text)"],
    keyFields: [
      { label: "title / description / notes", desc: "What the homeowner sees. For vendor-managed, title rewrites to 'Schedule [Vendor]: …'." },
      { label: "scheduled_date / next_due_date", desc: "When it should fire. Driven by frequency + seasonal anchor." },
      { label: "completed_at / archived_at", desc: "Lifecycle. Completion drives the next next-due date." },
      { label: "assignment_type", desc: "Personal / Vendor / Either. The 4-tier picker maps to this + routing_override + safety_floor." },
      { label: "assigned_to_user_id", desc: "Family member (homeowner, spouse, home manager) responsible." },
      { label: "assigned_contractor_id", desc: "Linked vendor when one's on file for the matching category." },
      { label: "needs_vendor", desc: "True when assignment_type='vendor' but no contractor matched yet — surfaces the 'Find a contractor' card." },
      { label: "parent_routine_id", desc: "Phase 66 — when set, this task lives under a routine and hides from the standalone task list." },
      { label: "bundle_parent_task_id", desc: "When this is a bundle child, points at the parent task that rolls them up." },
    ],
    relationships: [
      { kind: "belongs_to", target: "property", label: "Belongs to a property" },
      { kind: "belongs_to", target: "home_system", label: "Optionally tied to a home system", desc: "Most tasks are scoped to a system; some are property-level." },
      { kind: "references", target: "maintenance_template", label: "Templated from a Maintenance Template", desc: "template_id matches the template's templateKey." },
      { kind: "references", target: "family_member", label: "Optionally assigned to a family member" },
      { kind: "references", target: "contractor", label: "Optionally linked to a contractor / vendor" },
      { kind: "belongs_to", target: "routine", label: "Optionally part of a routine", desc: "When parent_routine_id is set, the task lives under that routine's program." },
      { kind: "belongs_to", target: "vehicle", label: "Optionally a vehicle task", desc: "vehicle_id set means this is a car maintenance item." },
    ],
  },
  {
    key: "maintenance_template",
    emoji: "📋",
    name: "Maintenance Template",
    cluster: "Tasks",
    purpose:
      "The DEFINITION of a recurring maintenance task. Lives in Swift code (146 of them). The reconciler reads templates and creates Maintenance Tasks from them based on the property's facts.",
    primaryKeys: ["templateKey (derived: stableId or '{category}:{title}')"],
    keyFields: [
      { label: "title / description / notes", desc: "User-facing copy that lands on the eventual task." },
      { label: "system_category", desc: "Which system this template lives under." },
      { label: "frequency", desc: "Cadence ('Annually', 'Biweekly')." },
      { label: "seasonal_timing", desc: "Optional anchor ('Spring' / 'Fall') for next-due math." },
      { label: "assignment_type / routing_override / safety_floor", desc: "Together drive the 4-tier 'who handles this' choice." },
      { label: "required_subtypes", desc: "Tags the home system has to match (e.g. ['tank'] for tank water heaters)." },
      { label: "is_essential", desc: "If on, auto-seeded at quiz completion. If off, only via 'Recommended for your home'." },
      { label: "regional_pack", desc: "Optional regional gate." },
      { label: "bundle_id / bundle_title", desc: "When set, this template rolls up into a bigger seasonal visit." },
    ],
    relationships: [
      { kind: "owns", target: "maintenance_task", label: "Many tasks are seeded from this template", desc: "1 template → N tasks across all properties." },
      { kind: "references", target: "system_category", label: "Lives under a system category" },
    ],
  },
  {
    key: "routine",
    emoji: "🔁",
    name: "Routine",
    cluster: "Tasks",
    purpose:
      "A recurring rhythm — biweekly cleaning, trash day, weekly lawn care. Different from maintenance tasks: routines are PROGRAMS the homeowner runs continuously; tasks are individual to-dos.",
    primaryKeys: ["id (uuid)", "property_id (uuid)", "routine_kind (text)"],
    keyFields: [
      { label: "label", desc: "User-facing name ('Renata's Cleaning', 'Trash')." },
      { label: "routine_kind", desc: "Maps to a Routine Kind enum value." },
      { label: "vendor_id (contractor)", desc: "Optional — the pro running the routine. Cleaning-style routines need one; trash-style routines often don't." },
      { label: "system_id", desc: "Optional — when the routine targets a specific system (the pool, the boiler)." },
      { label: "cadence_type / interval / days_of_week / time_of_day", desc: "How often + when." },
      { label: "active_months", desc: "Which months it runs (snow Dec–Apr, lawn Apr–Nov, cleaning year-round)." },
      { label: "estimated_cost_per_visit_cents", desc: "Per-visit price." },
      { label: "setup_state", desc: "Phase 66: draft / pending_vendor / active / paused / archived." },
      { label: "scope / vehicle_id / program_mode", desc: "Phase 66: vehicle-scoped routines for shop-managed cars." },
    ],
    relationships: [
      { kind: "belongs_to", target: "property", label: "Belongs to a property" },
      { kind: "references", target: "contractor", label: "Optionally linked to a contractor (the vendor running it)" },
      { kind: "references", target: "home_system", label: "Optionally tied to a home system" },
      { kind: "references", target: "routine_kind", label: "Categorized by a Routine Kind" },
      { kind: "owns", target: "routine_visit", label: "Has many routine visits", desc: "One per actual visit." },
      { kind: "owns", target: "maintenance_task", label: "Optionally adopts maintenance tasks", desc: "Phase 66 — tasks with parent_routine_id hide from the flat list and live under the routine instead." },
    ],
  },
  {
    key: "routine_visit",
    emoji: "📅",
    name: "Routine Visit",
    cluster: "Tasks",
    purpose:
      "A single instance of a routine — 'Wednesday April 30: Renata cleans'. Tracks confirmation, actual cost, what got done.",
    primaryKeys: ["id (uuid)", "routine_id (uuid)"],
    keyFields: [
      { label: "scheduled_date / completed_date", desc: "When." },
      { label: "visit_state", desc: "planned / scheduled / in_progress / completed / cancelled / skipped." },
      { label: "actual_cost_cents", desc: "What it actually cost." },
      { label: "target_window_start / end", desc: "Time window if specified." },
    ],
    relationships: [
      { kind: "belongs_to", target: "routine", label: "Belongs to a routine" },
      { kind: "owns", target: "handyman_punch_item", label: "May bundle handyman punch items", desc: "On handyman visits, punch items get assigned to a specific routine_visit." },
    ],
  },
  {
    key: "handyman_punch_item",
    emoji: "🔨",
    name: "Handyman Punch Item",
    cluster: "Tasks",
    purpose:
      "A small repair or maintenance item the homeowner queues up for the next handyman visit. Caulk a tile, fix a hinge, swap a filter.",
    primaryKeys: ["id (uuid)", "household_id (uuid)", "property_id (uuid)"],
    keyFields: [
      { label: "title / description", desc: "What needs doing." },
      { label: "source", desc: "manual (typed) / recommended (from suggestions) / maintenance_task (delegated)." },
      { label: "estimated_minutes / estimated_cost_range", desc: "Sizing." },
      { label: "status / priority / completed_at / archived_at", desc: "Lifecycle." },
      { label: "assigned_visit_task_id", desc: "Phase 78: when bundled into a handyman visit, points at that routine_visit's task." },
      { label: "delegated_from_task_id", desc: "When a homeowner converts a maintenance task into a punch item, this links back." },
      { label: "proposal_status / proposed_by_role", desc: "Phase 78: lets the handyman propose adding items, lets the homeowner approve." },
    ],
    relationships: [
      { kind: "belongs_to", target: "property", label: "Belongs to a property" },
      { kind: "belongs_to", target: "routine_visit", label: "Optionally bundled into a routine visit" },
      { kind: "references", target: "maintenance_task", label: "Optionally delegated from a maintenance task" },
      { kind: "references", target: "home_system", label: "Optionally linked to a home system" },
    ],
  },
  {
    key: "system_category",
    emoji: "🏷️",
    name: "System Category",
    cluster: "Catalog",
    purpose:
      "The registry of system types — Roofing, HVAC, Plumbing, etc. Defines the universe of categories home systems can belong to and templates can target.",
    primaryKeys: ["categoryKey (text)"],
    keyFields: [
      { label: "display_name", desc: "User-facing name." },
      { label: "tier", desc: "Universal / Conditional / Specialty / SubSystem." },
      { label: "default_cadence", desc: "Suggested cadence shown to set expectation." },
      { label: "icon", desc: "SF Symbol fallback for the category." },
      { label: "show_in_vendor_coverage", desc: "Hides sub-systems from the vendor-coverage UI." },
    ],
    relationships: [
      { kind: "owns", target: "home_system", label: "Many home systems are categorized by this" },
      { kind: "owns", target: "maintenance_template", label: "Many templates target this category" },
    ],
  },
  {
    key: "routine_kind",
    emoji: "🌀",
    name: "Routine Kind",
    cluster: "Catalog",
    purpose:
      "Enum of routine types — cleaning, landscaping, pool service, trash, recycling, etc. Drives the icon, default cadence, and form behavior when adding a new routine.",
    primaryKeys: ["rawValue (text)"],
    keyFields: [
      { label: "display_label", desc: "User-facing label." },
      { label: "icon", desc: "SF Symbol." },
      { label: "is_vendor_based", desc: "Drives whether the form requires a contractor." },
      { label: "seeder_default.cadence_type / active_months / reminders", desc: "Pre-fills when adding a routine of this kind." },
    ],
    relationships: [
      { kind: "owns", target: "routine", label: "Many routines are of this kind" },
    ],
  },
  {
    key: "contractor",
    emoji: "🛠",
    name: "Contractor (Vendor)",
    cluster: "People",
    purpose:
      "A pro the household has hired or might hire — Tyler Heating, Renata's cleaning, the local handyman. Captured at the quiz, after invoices, or manually.",
    primaryKeys: ["id (uuid)", "household_id (uuid)"],
    keyFields: [
      { label: "company_name / contact_name / phone / email", desc: "Identity + contact." },
      { label: "category", desc: "Trade — must match a System Category for vendor coverage to find them." },
      { label: "specialties", desc: "Multi-trade vendors list more than one." },
      { label: "logo_url / brand_color / website", desc: "Brand assets snapshot from Brandfetch." },
      { label: "source", desc: "manual / quiz / find_vendor — where the contractor came from." },
      { label: "utility_provider_id", desc: "Optional link back to the utility-provider catalog row when sourced from the quiz." },
    ],
    relationships: [
      { kind: "belongs_to", target: "property", label: "Belongs to a household (and thus a property)" },
      { kind: "owns", target: "routine", label: "May run one or more routines" },
      { kind: "owns", target: "maintenance_task", label: "May own (be assigned to) maintenance tasks" },
      { kind: "owns", target: "project_quote", label: "May provide quotes on projects" },
    ],
  },
  {
    key: "family_member",
    emoji: "👤",
    name: "Family Member",
    cluster: "People",
    purpose:
      "A person in the household — homeowner, spouse, kids, home manager, household staff. Some have an iOS account (linked_user_id), some are reference-only.",
    primaryKeys: ["id (uuid)", "household_id (uuid)"],
    keyFields: [
      { label: "first_name / last_name / dob", desc: "Identity. DOB drives is_minor for kids." },
      { label: "relationship", desc: "Spouse / Child / Parent / etc." },
      { label: "member_type", desc: "family / home_manager / staff. Drives document visibility + UI placement." },
      { label: "linked_user_id", desc: "Set when the person has their own Haven account." },
      { label: "school", desc: "For kids — drives school-pickup routine context." },
      { label: "is_expecting / expected_date", desc: "Pregnancy tracking from the quiz." },
    ],
    relationships: [
      { kind: "belongs_to", target: "property", label: "Belongs to a household" },
      { kind: "owns", target: "maintenance_task", label: "May be assigned tasks (assigned_to_user_id)" },
      { kind: "owns", target: "document", label: "May be tagged on documents (document_family_members)" },
    ],
  },
  {
    key: "vehicle",
    emoji: "🚗",
    name: "Vehicle",
    cluster: "Things",
    purpose:
      "A car the household owns. VIN-decoded into year/make/model. Has its own AI-generated maintenance schedule.",
    primaryKeys: ["id (uuid)", "household_id (uuid)"],
    keyFields: [
      { label: "year / make / model / trim", desc: "Identity. Drives the AI maintenance schedule prompt." },
      { label: "vin / license_plate", desc: "Identifiers." },
      { label: "mileage / mileage_updated_at", desc: "Used for next-service-due math." },
      { label: "primary_driver / covered_drivers", desc: "Who drives it." },
      { label: "registration_expiry / insurance_expiry", desc: "Renewal alerts on the vehicle detail." },
    ],
    relationships: [
      { kind: "belongs_to", target: "property", label: "Belongs to a household (often a property)" },
      { kind: "owns", target: "vehicle_service_record", label: "Has many service records" },
      { kind: "owns", target: "maintenance_task", label: "Has many vehicle maintenance tasks", desc: "Tasks with vehicle_id NOT NULL are car-scoped." },
      { kind: "owns", target: "document", label: "Has many documents (title, registration, insurance)" },
    ],
  },
  {
    key: "vehicle_service_record",
    emoji: "🧾",
    name: "Vehicle Service Record",
    cluster: "Things",
    purpose:
      "A historical service event for a vehicle — oil change, tire rotation, brake job. Auto-created when a vehicle invoice is processed.",
    primaryKeys: ["id (uuid)", "vehicle_id (uuid)"],
    keyFields: [
      { label: "service_name / serviced_at / mileage_at_service / cost", desc: "What, when, what miles, how much." },
      { label: "shop_name", desc: "Free-text shop name (not a contractor link by default)." },
    ],
    relationships: [
      { kind: "belongs_to", target: "vehicle", label: "Belongs to a vehicle" },
    ],
  },
  {
    key: "document",
    emoji: "📄",
    name: "Document",
    cluster: "Things",
    purpose:
      "A file the homeowner has — bill, warranty, insurance, contract, plan, manual. Routes through analyze-document for OCR + categorization.",
    primaryKeys: ["id (uuid)", "household_id (uuid)"],
    keyFields: [
      { label: "category", desc: "AI-suggested or user-corrected (Mortgage, Utility, Will, etc.)." },
      { label: "visible_to_home_managers", desc: "Build 87 — gates document visibility for home_manager + staff member_types." },
      { label: "linked_attorney_contact_id", desc: "For estate docs, points at the attorney trusted_contact." },
      { label: "vehicle_id / project_id", desc: "Optional links to the thing this document is about." },
      { label: "content_hash", desc: "SHA-256 dedup key." },
      { label: "detected_vins / matched_vehicle_ids", desc: "VIN auto-link from analyze-document." },
    ],
    relationships: [
      { kind: "belongs_to", target: "property", label: "Belongs to a household" },
      { kind: "references", target: "vehicle", label: "Optionally about a vehicle" },
      { kind: "references", target: "project", label: "Optionally part of a project" },
      { kind: "references", target: "family_member", label: "Optionally tagged with family members" },
    ],
  },
  {
    key: "project",
    emoji: "🛠",
    name: "Project",
    cluster: "Things",
    purpose:
      "A bigger one-off job — kitchen reno, roof replacement, pool installation. Has quotes, line items, files, contacts.",
    primaryKeys: ["id (uuid)", "household_id (uuid)"],
    keyFields: [
      { label: "title / category / status", desc: "What + lifecycle." },
      { label: "entry_type", desc: "planned (active project) / historical (logged after the fact)." },
      { label: "active_quote_id", desc: "Which quote is currently selected." },
      { label: "estimated_budget", desc: "Driven by the active quote." },
    ],
    relationships: [
      { kind: "belongs_to", target: "property", label: "Belongs to a property" },
      { kind: "owns", target: "project_quote", label: "Has many quotes" },
      { kind: "owns", target: "document", label: "Has many documents (plans, invoices, photos)" },
    ],
  },
  {
    key: "project_quote",
    emoji: "💵",
    name: "Project Quote",
    cluster: "Things",
    purpose:
      "A vendor's quote on a project. Has line items, total, version history, share token for handyman portal.",
    primaryKeys: ["id (uuid)", "project_id (uuid)", "contractor_id (uuid)"],
    keyFields: [
      { label: "total / status / sent_at / accepted_at", desc: "Money + lifecycle." },
      { label: "public_share_token", desc: "Lets the vendor view + counter without an account." },
      { label: "version / parent_quote_id", desc: "Quote version chain (negotiations)." },
    ],
    relationships: [
      { kind: "belongs_to", target: "project", label: "Belongs to a project" },
      { kind: "belongs_to", target: "contractor", label: "From a specific contractor" },
    ],
  },
  {
    key: "quiz_question",
    emoji: "❓",
    name: "Quiz Question",
    cluster: "Onboarding",
    purpose:
      "A question in the homeowner onboarding quiz. Defined in Swift code (41 of them). Each answer drives downstream system + task creation via the answer mapper.",
    primaryKeys: ["id (text — qN_kind)"],
    keyFields: [
      { label: "title / subtitle / fallback_title", desc: "User-facing copy. Title supports {state}/{street} tokens." },
      { label: "kind", desc: "single_choice / multi_select / currency / provider_search / etc." },
      { label: "answer_options", desc: "Buttons the homeowner taps." },
      { label: "provider_types / provider_follow_up_answer_ids", desc: "When picking certain answers reveals an inline provider picker." },
      { label: "dynamic_skip", desc: "Auto-skip rule based on prior answers." },
    ],
    relationships: [
      { kind: "owns", target: "quiz_answer", label: "Each property has one answer per question (when answered)" },
      { kind: "references", target: "system_category", label: "Often creates a system category at answer time", desc: "Heuristic: q3b (HVAC type) creates an HVAC system, q12 (pool) creates Pool/Spa, etc." },
    ],
  },
  {
    key: "quiz_answer",
    emoji: "🟢",
    name: "Quiz Answer (Property State)",
    cluster: "Onboarding",
    purpose:
      "The homeowner's answer to a quiz question. Stored as one entry inside `properties.house_quiz_state.answers` JSONB — not its own table.",
    primaryKeys: ["properties.house_quiz_state.answers[questionId]"],
    keyFields: [
      { label: "answer_id / selected_ids / custom_text", desc: "What was picked. Multi-select uses selected_ids." },
      { label: "selected_provider_id", desc: "When the answer captured a utility provider." },
      { label: "kids / expecting_entries", desc: "Q28 family-with-kids expansion." },
      { label: "generator_fuel_type / generator_provider_id", desc: "Q22 generator inline form." },
      { label: "answered_at", desc: "Timestamp." },
    ],
    relationships: [
      { kind: "belongs_to", target: "property", label: "Stored on the property's house_quiz_state" },
      { kind: "belongs_to", target: "quiz_question", label: "Answers a specific question" },
    ],
  },
  {
    key: "edge_function_prompt",
    emoji: "🧠",
    name: "Edge Function Prompt",
    cluster: "Backend",
    purpose:
      "An AI prompt that runs server-side in a Supabase Edge Function. About 90% of the app's intelligence lives in these — analyze-document, gap-analysis, simulate-scenario, vehicle-lookup, etc.",
    primaryKeys: ["function_name (folder name)"],
    keyFields: [
      { label: "system_prompt", desc: "What we tell Claude to do. Shape of the answer is encoded here." },
      { label: "model", desc: "Claude model used (Sonnet, Haiku, Opus)." },
      { label: "source_file", desc: "Path to index.ts in the repo." },
    ],
    relationships: [
      { kind: "owns", target: "maintenance_task", label: "vehicle-lookup creates vehicle maintenance tasks", desc: "After VIN decode, Claude generates a per-vehicle schedule that becomes maintenance_tasks rows." },
    ],
  },
];

const CLUSTERS = [
  { key: "Home", label: "🏠 Home", description: "The property itself and the systems on it." },
  { key: "Tasks", label: "✅ Tasks + Routines", description: "What needs doing, what recurs, what got done." },
  { key: "People", label: "👥 People", description: "Family, staff, contractors." },
  { key: "Things", label: "📦 Things owned", description: "Vehicles, documents, projects." },
  { key: "Catalog", label: "🏷️ Static catalog", description: "Read-only registries that templates and routines reference." },
  { key: "Onboarding", label: "❓ Onboarding", description: "The quiz and its answers." },
  { key: "Backend", label: "🧠 Backend", description: "Server-side AI prompts." },
];

// =============================================================================
// Public API
// =============================================================================

export function renderArchitectureView() {
  const clusterHtml = CLUSTERS
    .map((cluster) => {
      const objects = OBJECT_MAP.filter((o) => o.cluster === cluster.key);
      return `
        <section class="admin-arch__cluster">
          <header>
            <h3>${escapeHtml(cluster.label)}</h3>
            <p>${escapeHtml(cluster.description)}</p>
          </header>
          <div class="admin-arch__grid">
            ${objects.map(renderObjectCard).join("")}
          </div>
        </section>
      `;
    })
    .join("");

  return `
    <div class="admin-arch">
      <header class="admin-arch__intro">
        <p>Walkable map of every object the lab tracks — fields, relationships, and how they connect.
        Click any "→ X" link to jump to that object's card.</p>
      </header>
      ${clusterHtml}
    </div>
  `;
}

function renderObjectCard(obj) {
  const fields = (obj.keyFields || [])
    .map(
      (f) => `
        <li>
          <strong>${escapeHtml(f.label)}</strong>
          <span>${escapeHtml(f.desc || "")}</span>
        </li>
      `
    )
    .join("");

  const owns = (obj.relationships || []).filter((r) => r.kind === "owns");
  const belongsTo = (obj.relationships || []).filter((r) => r.kind === "belongs_to");
  const refs = (obj.relationships || []).filter((r) => r.kind === "references");

  return `
    <article class="admin-arch__card" id="arch-${escapeHtml(obj.key)}" data-arch-card="${escapeHtml(obj.key)}">
      <header>
        <span class="admin-arch__emoji">${obj.emoji}</span>
        <div>
          <h4>${escapeHtml(obj.name)}</h4>
          <code>${escapeHtml(obj.key)}</code>
        </div>
      </header>
      <p class="admin-arch__purpose">${escapeHtml(obj.purpose)}</p>
      ${
        obj.primaryKeys?.length
          ? `<div class="admin-arch__keys">
              <strong>Primary keys</strong>
              <code>${obj.primaryKeys.map(escapeHtml).join(" · ")}</code>
            </div>`
          : ""
      }
      ${
        fields
          ? `<details class="admin-arch__fields"><summary>${obj.keyFields.length} key fields</summary><ul>${fields}</ul></details>`
          : ""
      }
      ${renderRelGroup("Belongs to", belongsTo, "belongs-to")}
      ${renderRelGroup("Owns / has many", owns, "owns")}
      ${renderRelGroup("References", refs, "references")}
    </article>
  `;
}

function renderRelGroup(title, rels, klass) {
  if (!rels.length) return "";
  return `
    <div class="admin-arch__rels admin-arch__rels--${escapeHtml(klass)}">
      <strong>${escapeHtml(title)}</strong>
      <ul>
        ${rels
          .map(
            (r) => `
              <li>
                <button type="button" class="admin-arch__rel-link" data-arch-target="${escapeHtml(r.target)}">
                  → ${escapeHtml(targetName(r.target))}
                </button>
                <span class="admin-arch__rel-label">${escapeHtml(r.label)}${
              r.desc ? ` · <em>${escapeHtml(r.desc)}</em>` : ""
            }</span>
              </li>
            `
          )
          .join("")}
      </ul>
    </div>
  `;
}

function targetName(key) {
  const obj = OBJECT_MAP.find((o) => o.key === key);
  return obj ? `${obj.emoji} ${obj.name}` : key;
}

export function attachArchitectureHandlers(container) {
  container.querySelectorAll("[data-arch-target]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const targetKey = btn.dataset.archTarget;
      const target = container.querySelector(`#arch-${CSS.escape(targetKey)}`);
      if (!target) return;
      target.scrollIntoView({ behavior: "smooth", block: "start" });
      target.classList.add("is-flashing");
      setTimeout(() => target.classList.remove("is-flashing"), 1800);
    });
  });
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

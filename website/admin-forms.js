// =============================================================================
// admin-forms.js — schema-driven entity editor
// =============================================================================
// Per-surface schemas + a generic renderer that takes a JSON entity (from
// website/admin-data/*.json) and turns it into purpose-built form controls
// (selects, toggles, chip pickers, list editors) — no raw JSON anywhere.
//
// Editing a field on a "live" entity (Swift-baked) doesn't mutate Swift; it
// produces a proposed_diff captured on the next saved note (intent =
// change_request). The diff strip below the form previews the diff in plain
// English ("frequency: 'Annually' → 'Every 18 months'") before save.

// -----------------------------------------------------------------------------
// Enum option lists — matched to Swift truth
// -----------------------------------------------------------------------------

export const ENUMS = {
  quizSection: [
    { value: "homeBasics", label: "Home Basics" },
    { value: "inside", label: "Inside Your Home" },
    { value: "outside", label: "Outside & Landscaping" },
    { value: "energyServices", label: "Energy & Services" },
    { value: "backupEnergy", label: "Backup & Energy" },
    { value: "vehicles", label: "Vehicles & Garage" },
    { value: "protectionPeople", label: "Protection & People" },
  ],
  quizChapter: [
    { value: "yourHome", label: "Your Home" },
    { value: "yourPros", label: "Your Pros" },
    { value: "yourPeople", label: "Your People" },
  ],
  quizKind: [
    { value: "singleChoice", label: "Single choice" },
    { value: "multiSelect", label: "Multi select" },
    { value: "currency", label: "Currency input" },
    { value: "yesNoLender", label: "Yes / No / Skip" },
    { value: "vehicleCount", label: "Vehicle count" },
    { value: "vehicleAdd", label: "Vehicle add (VIN / manual)" },
    { value: "providerSearch", label: "Provider search picker" },
    { value: "caretakers", label: "Caretakers (Q28 sub-flow)" },
    { value: "generatorAdd", label: "Generator add (Q22)" },
    { value: "householdContractors", label: "Household contractors (Q15b)" },
    { value: "slider", label: "Slider (legacy)" },
  ],
  providerTypes: [
    { value: "electric", label: "Electric" },
    { value: "internet_cable", label: "Internet / Cable" },
    { value: "natural_gas", label: "Natural Gas" },
    { value: "oil", label: "Oil" },
    { value: "propane", label: "Propane" },
    { value: "water", label: "Water" },
    { value: "trash", label: "Trash" },
    { value: "landscaping", label: "Landscaping" },
    { value: "pool_service", label: "Pool service" },
    { value: "pest_control", label: "Pest control" },
    { value: "irrigation", label: "Irrigation" },
    { value: "security", label: "Security" },
    { value: "snow_removal", label: "Snow removal" },
    { value: "auto_insurance", label: "Auto insurance" },
    { value: "home_insurance", label: "Home insurance" },
    { value: "estate_attorney", label: "Estate attorney" },
    { value: "cpa_tax", label: "CPA / Tax" },
    { value: "financial_advisor", label: "Financial advisor" },
    { value: "life_insurance", label: "Life insurance" },
  ],

  taskAssignmentType: [
    { value: "personal", label: "Personal — DIY only" },
    { value: "vendor", label: "Vendor — pro only" },
    { value: "either", label: "Either — defaults to DIY, flippable" },
  ],
  // Phase 5d — Tom-facing renaming of the underlying assignmentType +
  // routingOverride + safetyFloor combo into a single 4-tier choice.
  // homeowner_only is intentionally never the default for a template —
  // homeowners pull tasks into that bucket explicitly at runtime.
  assignmentTier: [
    { value: "vendor_only", label: "Vendor only" },
    { value: "vendor_or_handyman", label: "Vendor or Handyman (default)" },
    { value: "handyman_only", label: "Handyman only" },
    { value: "homeowner_only", label: "I'll do it myself (runtime only — never seeded)" },
  ],
  taskRoutingOverride: [
    { value: "", label: "(use default — vendorDefault)" },
    { value: "vendorOnly", label: "Vendor only (no DIY path)" },
    { value: "vendorDefault", label: "Vendor default (3-option picker)" },
    { value: "diyDefault", label: "DIY default (handyman / DIY picker)" },
    { value: "diyCapable", label: "DIY capable (3-option picker)" },
    { value: "bundledIntoParent", label: "Bundled into parent" },
  ],
  taskPriority: [
    { value: "High", label: "High" },
    { value: "Medium", label: "Medium" },
    { value: "Low", label: "Low" },
  ],
  taskFrequency: [
    { value: "Daily", label: "Daily" },
    { value: "Weekly", label: "Weekly" },
    { value: "Biweekly", label: "Biweekly" },
    { value: "Monthly", label: "Monthly" },
    { value: "Bi-monthly", label: "Bi-monthly" },
    { value: "Quarterly", label: "Quarterly" },
    { value: "Semi-annually", label: "Semi-annually" },
    { value: "Annually", label: "Annually" },
    { value: "Every 2-3 years", label: "Every 2–3 years" },
    { value: "Every 3 years", label: "Every 3 years" },
    { value: "Every 5 years", label: "Every 5 years" },
    { value: "Every 10 years", label: "Every 10 years" },
    { value: "Per event", label: "Per event" },
    { value: "On demand", label: "On demand" },
    { value: "Once", label: "Once" },
  ],
  taskSeasonalTiming: [
    { value: "", label: "(year-round — no specific season)" },
    { value: "Spring", label: "Spring" },
    { value: "Summer", label: "Summer" },
    { value: "Fall", label: "Fall" },
    { value: "Winter", label: "Winter" },
    { value: "Spring/Fall", label: "Spring/Fall" },
  ],
  regionalPack: [
    { value: "", label: "(universal — all regions)" },
    { value: "northeast", label: "Northeast" },
    { value: "southeast", label: "Southeast" },
    { value: "midwest", label: "Midwest" },
    { value: "southwest", label: "Southwest" },
    { value: "west", label: "West" },
  ],

  systemTier: [
    { value: "universal", label: "Tier 1 — Universal (every home)" },
    { value: "conditional", label: "Tier 2 — Conditional (gated by quiz)" },
    { value: "specialty", label: "Tier 3 — Specialty (Browse sheet)" },
    { value: "subSystem", label: "Sub-system (hides from coverage)" },
  ],

  cadenceType: [
    { value: "weekly", label: "Weekly" },
    { value: "biweekly", label: "Biweekly" },
    { value: "triweekly", label: "Triweekly" },
    { value: "monthly", label: "Monthly" },
    { value: "bimonthly", label: "Bimonthly" },
    { value: "quarterly", label: "Quarterly" },
    { value: "semiannual", label: "Semi-annual" },
    { value: "annual", label: "Annual" },
    { value: "customDays", label: "Custom days" },
  ],

  claudeModel: [
    { value: "claude-opus-4-7", label: "Opus 4.7" },
    { value: "claude-sonnet-4-6", label: "Sonnet 4.6" },
    { value: "claude-haiku-4-5-20251001", label: "Haiku 4.5" },
    { value: "claude-3-5-sonnet-latest", label: "Sonnet 3.5 (legacy)" },
    { value: "claude-3-haiku-20240307", label: "Haiku 3 (legacy)" },
  ],
};

// -----------------------------------------------------------------------------
// Per-surface schemas
// -----------------------------------------------------------------------------

export const SCHEMAS = {
  quiz: {
    title: "Quiz Question",
    groups: [
      { id: "identity", label: "Identity" },
      { id: "copy", label: "User-facing copy" },
      { id: "structure", label: "Placement" },
      { id: "behavior", label: "Behavior" },
      { id: "answers", label: "Answer options" },
      { id: "extras", label: "Skip + provider rules" },
      { id: "impact", label: "Cross-entity impact" },
    ],
    fields: [
      { key: "id", label: "Question ID (Swift-baked)", group: "identity", type: "text", readonly: true,
        usage: "Internal name for this question. Other parts of the app look it up by this name to find what the homeowner picked, decide which tasks to seed, and tag any notes you've written. Don't rename without flagging — anything pointing at the old name will break." },
      { key: "title", label: "Title", group: "copy", type: "text",
        help: "Supports {yearBuilt}, {street}, {state}, {city}, {squareFootage}, {roofType} tokens.",
        usage: "What the homeowner sees as the big headline on the question card. Anything in curly braces like {state} or {street} gets filled in from the property's facts when we have them. If we don't, the fallback title below shows up instead. Action-first phrasing reads cleanest." },
      { key: "subtitle", label: "Subtitle", group: "copy", type: "textarea", rows: 2,
        usage: "Smaller body text under the title. Use it to explain WHY we're asking — what we'll do with the answer. Helps the homeowner trust the question." },
      { key: "fallbackTitle", label: "Fallback title (when tokens unresolved)", group: "copy", type: "text",
        help: "Used as the literal title if a {token} can't resolve. Leave blank if title has no tokens.",
        usage: "Backup title shown when one of the curly-brace tokens (like {street} or {state}) can't be filled in. Required if the main title uses tokens — otherwise the homeowner can see literal '{state}' on screen, which is a trust killer." },
      { key: "section", label: "Section (legacy grouping)", group: "structure", type: "select", enumKey: "quizSection",
        usage: "Old way of grouping questions (Home Basics, Inside, Outside, Energy & Services, etc.). Mostly cosmetic now — the chapter field below is what actually drives the quiz flow." },
      { key: "chapter", label: "Chapter", group: "structure", type: "select", enumKey: "quizChapter",
        usage: "Which big chapter the question lives in. Three chapters total: Your Home (the property facts), Your Pros (the people you've already hired), Your People (your family). The chapter intro card fires between chapter switches. The order matters for one specific reason: Q36 (DIY-vs-vendor preference) lives in Your Pros so it gets answered BEFORE the vendor questions in section 3, otherwise tasks would seed under the wrong assignment." },
      { key: "kind", label: "Question kind", group: "behavior", type: "select", enumKey: "quizKind",
        usage: "What kind of question this is — single choice, multi-select, currency input, provider picker, vehicle add, etc. Determines what the input looks like on the homeowner's screen and how their answer is saved. Changing kind on a question that's already live will lose anyone's prior answer." },
      { key: "supportsSelectAll", label: "Show 'Select all' pill (multi-select only)", group: "behavior", type: "boolean",
        usage: "Adds a 'Select all / Deselect all' shortcut button on multi-select questions. Currently only the appliances question uses it because picking every appliance one at a time is annoying when most homeowners have most of them." },
      { key: "documentUploadCategory", label: "Document upload category (optional)", group: "behavior", type: "text",
        usage: "Lets the homeowner skip answering and upload a document instead. The doc gets saved into their vault under whatever category you set here. Currently used for mortgage statements and utility bills — it's a nice escape hatch for questions where the answer is on a piece of paper they already have." },
      { key: "answerOptions", label: "Answer options", group: "answers", type: "answer-options",
        usage: "The buttons or chips the homeowner sees as their answer choices. Each option has a label they read, an optional icon, and an internal ID we use to remember what they picked. Reordering changes the visual order; renaming an ID will lose anyone who already picked that option." },
      { key: "providerTypes", label: "Provider types (for providerSearch kind)", group: "extras", type: "enum-list", enumKey: "providerTypes",
        usage: "When this question shows the provider picker (or pops one up after a follow-up answer), this is the list of which providers it shows — electric, internet, lawn care, pest control, etc. Has to match the categories we have in our provider catalog or no results will show." },
      { key: "providerFollowUpAnswerIds", label: "Provider follow-up answer IDs", group: "extras", type: "chip-list",
        help: "Comma-separated answer option IDs that trigger an inline provider picker.",
        usage: "If the homeowner picks one of these specific answers, an extra provider picker pops up inline so they can name the company. Used for things like 'I have a pro' on the lawn question, 'Quarterly pro service' on the pest question, 'Monitored alarm' on the security question." },
      { key: "providerSearchPlaceholder", label: "Provider picker placeholder", group: "extras", type: "text",
        usage: "The grayed-out hint text inside the provider search box (like 'TruGreen, BrightView…'). Just a UI nudge to help the homeowner know what to type." },
      { key: "dynamicSkip", label: "Dynamic skip rule (Swift closure)", group: "extras", type: "code", readonly: true,
        help: "Conditional skip logic captured raw from Swift. Editing requires a code change.",
        usage: "An automatic skip rule that fires when prior answers make this question pointless. For example, if the homeowner already said they have no lawn, we skip both the lawn-type question and the irrigation question. Read-only here — the rule lives in app code and needs an engineer to change." },
      { key: "dynamicProviderTypes", label: "Dynamic provider-types rule (Swift closure)", group: "extras", type: "code", readonly: true,
        usage: "Same idea as the static provider-types list above, but computed on the fly from prior answers. The heating-fuel-provider question uses this to only show oil suppliers if the homeowner picked oil heating, propane suppliers if they picked propane, etc. If it would resolve to an empty list (electric / geothermal heating), the question auto-skips entirely." },
      { key: "_impact.creates_systems", label: "Creates these systems (heuristic)", group: "impact", type: "chip-list", readonly: true,
        usage: "Best guess at which home systems this question creates when the homeowner answers it. For example, the HVAC question creates an 'HVAC' system on their property; the pool question creates a 'Pool' system. The Decisions queue and Impact tab use this to show what changes when this question fires." },
    ],
  },

  tasks: {
    title: "Maintenance Template",
    groups: [
      { id: "tier", label: "Who handles this" },
      { id: "identity", label: "Identity" },
      { id: "copy", label: "User-facing copy" },
      { id: "schedule", label: "Schedule + cost" },
      { id: "routing", label: "Assignment + routing (advanced)" },
      { id: "gating", label: "Gating + scope" },
      { id: "bundle", label: "Bundle membership" },
      { id: "extras", label: "Advanced" },
    ],
    fields: [
      { key: "_tier", label: "Who handles this task", group: "tier", type: "assignment-tier",
        usage: "The single field that decides how this task lands on a homeowner's screen. Vendor only = always a pro (gas, panel, roof). Vendor or Handyman = the homeowner can pick (default for most maintenance). Handyman only = small DIY-friendly items that bundle into a handyman visit. I'll do it myself = runtime-only — homeowners pull tasks here themselves; templates never ship in this state. Changing this here updates the underlying assignment type, routing override, and safety floor all at once." },
      { key: "templateKey", label: "Template key (Swift-derived)", group: "identity", type: "text", readonly: true,
        usage: "Internal ID for this template. Every actual task we create from it carries this ID, so we can count completions, attach notes, and remember the homeowner's history. Don't rename without setting a stable ID override below — you'd lose all the history." },
      { key: "stableId", label: "Stable ID override (rename safety)", group: "identity", type: "text",
        help: "Use only when renaming a template whose previous title is referenced by existing task rows.",
        usage: "Set this if you're renaming a template that's already been used by real households — point it at the OLD name. That way existing tasks stay attached to the same template and the homeowner's completion history doesn't get orphaned. Leave blank for brand-new templates." },
      { key: "systemCategory", label: "System category", group: "identity", type: "system-picker",
        usage: "Which home system this task lives under (Roofing, HVAC, Plumbing, etc.). The homeowner sees their tasks grouped by these categories on the Property tab. Also determines which tier the system is in — Universal, Conditional, or Specialty." },
      { key: "title", label: "Title", group: "copy", type: "text",
        help: "Action-first: 'Schedule …', 'Check …', 'Inspect …'. No 'Professional X' titles.",
        usage: "What the homeowner sees as the task name. Action-first phrasing reads cleanest ('Schedule annual roof inspection' beats 'Annual roof inspection'). When the task is linked to a specific vendor on the household, the title automatically rewrites to 'Schedule [Vendor]: [task]' so it reads like a real to-do, not a generic template." },
      { key: "description", label: "Description", group: "copy", type: "textarea", rows: 4,
        usage: "Body text on the task detail screen. For tasks where a vendor handles the work, we automatically prepend 'Your job: book the appointment and be home for it. [Vendor] will handle the work.' before this text — so the homeowner knows what's expected of them." },
      { key: "notes", label: "Pro tips / notes", group: "copy", type: "textarea", rows: 3,
        usage: "Optional pro tips shown in the task detail screen. Use this for the WHY behind the cadence ('do this before the first frost' / 'after pool closing'). The {city} and {state} placeholders get filled in from the property's address." },
      { key: "frequency", label: "Frequency", group: "schedule", type: "select", enumKey: "taskFrequency", allowCustom: true,
        usage: "How often this task should happen. Annually, biweekly, every 2-3 years, etc. Drives when the next-due date lands after the homeowner finishes one. Custom values are allowed." },
      { key: "seasonalTiming", label: "Seasonal anchor", group: "schedule", type: "select", enumKey: "taskSeasonalTiming",
        usage: "If the task should fire in a specific season, set it here. We auto-walk the next-due date to the right season instead of just adding the interval to today — so 'gutter cleaning' lands in October even if you complete it in February. Only matters for annual+ cadences; weekly / monthly tasks ignore it." },
      { key: "estimatedCostRange", label: "Estimated cost range", group: "schedule", type: "text",
        usage: "What the homeowner can expect to pay (e.g. '$200–$400'). Shown on vendor-managed task cards. Eventually we'll roll these up into the projected-spend chart on the Property tab." },
      { key: "priority", label: "Priority", group: "schedule", type: "select", enumKey: "taskPriority",
        usage: "High / Medium / Low. We only flash a priority pill on the task card for tasks that are overdue, or in the rare critical/urgent cases — High is the default and showing it everywhere just made the UI noisy." },
      { key: "maxIntervalDays", label: "Max interval (days, optional)", group: "schedule", type: "number",
        help: "Warns user when extending frequency past this cap.",
        usage: "Maximum days the homeowner can stretch the cadence to. If they try to push it further (say, change a smoke detector test from 'Annually' to 'Every 5 years'), we warn them. Used for safety-critical items where stretching the cadence is dangerous." },
      { key: "warrantyLinked", label: "Warranty-linked (warns on cadence change)", group: "schedule", type: "boolean",
        usage: "If on, we show a 'this may void your warranty' warning when the homeowner tries to extend the cadence. Used for HVAC tune-ups, annual boiler service, generator service — manufacturer warranties tie to documented service intervals, and stretching them risks the warranty." },
      { key: "assignmentType", label: "Assignment type", group: "routing", type: "select", enumKey: "taskAssignmentType",
        usage: "Who does this task. Personal = the homeowner does it themselves. Vendor = always a pro. Either = flexible — defaults to homeowner but can flip based on the homeowner's overall DIY-vs-vendor preference, or via the per-task button." },
      { key: "routingOverride", label: "Routing override", group: "routing", type: "select", enumKey: "taskRoutingOverride",
        usage: "Fine-grained control over the task's UI options. Vendor only = no DIY option (find-a-pro card only). DIY default = handyman or DIY only, never a vendor (no matter what the homeowner picked for preferences). DIY capable = three-way picker (vendor / handyman / DIY). Bundled = this template never appears solo, only inside a bigger bundled visit (Spring Roofing, Fall Handyman, etc.)." },
      { key: "safetyFloor", label: "Safety floor (always vendor regardless of preference)", group: "routing", type: "boolean",
        usage: "If on, the task ALWAYS goes to a vendor — no matter what the homeowner's DIY preference says. Used for gas work, panel work, roofs, septic systems, wells, chimneys — things that aren't safe to hand a homeowner even if they wanted to do it." },
      { key: "diyEffortMinutes", label: "DIY effort (minutes)", group: "routing", type: "number",
        usage: "How long the task takes to do yourself, in minutes. Shown on the task card as '5 min' or '1 hr 30 min'. Also used to decide bundling: tasks under 60 min are eligible for handyman bundles, tasks under 30 min default to DIY when preference is 'mixed', etc." },
      { key: "diyEffortLabel", label: "DIY effort label", group: "routing", type: "text",
        help: "e.g. 'Anyone can do this', 'Need a stepladder', 'Skip if you don't like heights'",
        usage: "Short skill descriptor shown next to the time estimate ('Anyone can do this' / 'Need a stepladder' / 'Comfortable with tools helps' / 'Skip if you don't like heights'). Sets expectation before the homeowner taps in." },
      { key: "isEssential", label: "Essential (auto-seeded at quiz time)", group: "gating", type: "boolean",
        usage: "If on, every household automatically gets this task seeded right after they finish the quiz. If off, the task only shows up if the homeowner adds it from the 'Recommended for your home' sheet. Use 'off' for nice-to-haves that not every house needs." },
      { key: "isDIY", label: "isDIY (deprecated — use assignmentType + diyEffortMinutes)", group: "gating", type: "boolean",
        usage: "Old field — superseded by Assignment Type and DIY Effort above. Still around so older templates keep working, but new templates should leave it alone." },
      { key: "professionalRequired", label: "professionalRequired (deprecated — use safetyFloor)", group: "gating", type: "boolean",
        usage: "Old field — superseded by Safety Floor and Routing Override. Still around for older templates." },
      { key: "regionalPack", label: "Regional pack", group: "gating", type: "select", enumKey: "regionalPack",
        usage: "If set, this template only shows up for homes in that region (Northeast, Southeast, etc.). Region is auto-detected from the property's state. Leave blank for templates that apply everywhere — that's the default." },
      { key: "requiredSubtypes", label: "Required subtypes", group: "gating", type: "chip-list",
        help: "Tags that gate this template on the home_systems row's subtype set.",
        usage: "Tags the home system has to match for this template to apply. For example, 'tank' for tank water heaters only, or 'has_pets' for pet-only items. ALL of the listed subtypes have to match — empty means the template always applies to anyone with the parent system." },
      { key: "equipmentKeywords", label: "Equipment keywords (child-system migration)", group: "gating", type: "chip-list",
        usage: "Once we identify a specific piece of equipment in the home (a Bosch dishwasher, a Carrier furnace), we move tasks that match these keywords from the parent system to that specific equipment record. So 'replace water filter' migrates from the generic 'Plumbing' system to the actual fridge once we know which fridge it is." },
      { key: "bundleId", label: "Bundle ID", group: "bundle", type: "text",
        help: "e.g. 'Roofing:spring', 'Handyman:fall'. Bundled templates roll up into one task.",
        usage: "If set, this template gets folded into a bigger seasonal visit (e.g. 'Roofing:spring', 'Handyman:fall', 'Pool/Spa:opening'). Multiple templates sharing the same bundle ID roll up into ONE task on the homeowner's screen with a 'What's included' checklist underneath. Cleaner than five separate tasks for the same visit." },
      { key: "bundleTitle", label: "Bundle title (first child only)", group: "bundle", type: "text",
        usage: "The title for the whole bundled visit. Only the FIRST template in a bundle needs to set this; siblings inherit it. The homeowner sees this as their task title (e.g. 'Spring Landscaping Service' instead of five separate landscaping line items)." },
      { key: "_impact.in_bundle.siblings", label: "Sibling templates in this bundle", group: "extras", type: "chip-list", readonly: true,
        usage: "Other templates that get rolled into the same bundled visit as this one. Lets you see at a glance what's actually in a bundle without having to read code." },
    ],
  },

  routines: {
    title: "Routine Kind",
    groups: [
      { id: "identity", label: "Identity" },
      { id: "display", label: "Display" },
      { id: "defaults", label: "Seeder defaults" },
    ],
    fields: [
      { key: "rawValue", label: "Raw value (DB)", group: "identity", type: "text", readonly: true,
        usage: "How this routine kind is stored in the database. Don't rename — anything we've already saved would break." },
      { key: "swiftCase", label: "Swift case", group: "identity", type: "text", readonly: true,
        usage: "Internal name in the app code. The user-facing label below is what shows on screen." },
      { key: "displayLabel", label: "Display label", group: "display", type: "text",
        usage: "What the homeowner sees on screen for this kind of routine — 'Cleaning', 'Pool service', 'Trash', etc. When a vendor is linked to the routine, the vendor's name shows instead, but this label is the fallback." },
      { key: "icon", label: "SF Symbol icon", group: "display", type: "text",
        help: "e.g. 'sparkles', 'leaf.fill', 'snowflake'. Must exist in Apple's SF Symbols catalog.",
        usage: "The icon next to the routine when no vendor logo is available. Falls back to a generic icon if the name doesn't match anything in Apple's catalog. Test it in Apple's SF Symbols app before shipping a new one." },
      { key: "isVendorBased", label: "Vendor-based (defaults to having a contractor link)", group: "display", type: "boolean",
        usage: "If on, the form defaults to having a vendor attached (cleaning, landscaping, pool service). If off, it's typically a self-managed cadence (trash day, recurring delivery). Also affects the dashboard banner copy: cadence routines say 'pickup tomorrow', vendor routines say 'visit tomorrow'." },
      { key: "seederDefault.cadenceType", label: "Default cadence", group: "defaults", type: "select", enumKey: "cadenceType",
        usage: "Default rhythm the routine starts with when a homeowner picks this kind. Weekly, monthly, etc. They can change it after." },
      { key: "seederDefault.activeMonths", label: "Default active months (1=Jan…12=Dec)", group: "defaults", type: "month-picker",
        usage: "Which months of the year the routine runs by default. Snow removal defaults to Dec–Apr, lawn care defaults to Apr–Nov, year-round things like trash leave this empty (which means all 12 months)." },
      { key: "seederDefault.defaultEveningBeforeReminder", label: "Default evening-before reminder", group: "defaults", type: "boolean",
        usage: "Default 'remind me the night before' setting. The dashboard banner surfaces these between 6pm and midnight on the day before the routine fires." },
      { key: "seederDefault.defaultMorningOfReminder", label: "Default morning-of reminder", group: "defaults", type: "boolean",
        usage: "Default 'remind me morning of' setting. Surfaces in the dashboard banner before 10am on the day-of." },
    ],
  },

  handyman: {
    title: "Handyman Template",
    groups: [
      { id: "tier", label: "Who handles this" },
      { id: "identity", label: "Identity" },
      { id: "copy", label: "User-facing copy" },
      { id: "schedule", label: "Schedule + effort" },
      { id: "routing", label: "Routing (advanced)" },
    ],
    fields: [
      { key: "_tier", label: "Who handles this task", group: "tier", type: "assignment-tier",
        usage: "Same as the Tasks surface — picks Vendor only / Vendor or Handyman / Handyman only / I'll do it myself. Most handyman items default to Handyman only since they're small and DIY-friendly. Changes here update the underlying assignment type, routing override, and safety floor together." },
      { key: "templateKey", label: "Template key", group: "identity", type: "text", readonly: true,
        usage: "Same internal ID as a regular maintenance template — these are just the subset that the homeowner can add to a handyman visit." },
      { key: "systemCategory", label: "System category", group: "identity", type: "system-picker",
        usage: "Most handyman items live under the 'Handyman' category, but some stay under their primary system (e.g. an HVAC filter swap stays under HVAC even if it's eligible for the handyman bundle)." },
      { key: "bundleId", label: "Bundle (Handyman:spring / Handyman:fall)", group: "identity", type: "text",
        usage: "'Handyman:spring' or 'Handyman:fall' for the seasonal handyman visits. Items sharing the same bundle ID roll up into one visit on the homeowner's screen." },
      { key: "title", label: "Title", group: "copy", type: "text",
        usage: "What the homeowner sees on the handyman visit checklist. Items the homeowner adds manually via 'Add to handyman list' don't go through templates — this is for the seeded ones only." },
      { key: "description", label: "Description", group: "copy", type: "textarea", rows: 3,
        usage: "Body text on the task detail screen for this handyman item." },
      { key: "notes", label: "Notes", group: "copy", type: "textarea", rows: 2,
        usage: "Optional pro tips. For Handyman:spring or Handyman:fall bundle parents, this often lists what's typically covered in a spring or fall visit." },
      { key: "frequency", label: "Frequency", group: "schedule", type: "select", enumKey: "taskFrequency", allowCustom: true,
        usage: "How often this item recurs. Most handyman items are semi-annual (Spring + Fall) or annual." },
      { key: "seasonalTiming", label: "Seasonal anchor", group: "schedule", type: "select", enumKey: "taskSeasonalTiming",
        usage: "Which season this item should fire in. Drives the next-due-date math so the item lands in the right month." },
      { key: "diyEffortMinutes", label: "Effort (minutes)", group: "schedule", type: "number",
        usage: "Time estimate. To be eligible for the handyman bundle, items have to be 60 minutes or under — bigger jobs need a real vendor visit, not a punch-list bundle." },
      { key: "diyEffortLabel", label: "Effort label", group: "schedule", type: "text",
        usage: "Skill descriptor (e.g. 'Anyone can do this' / 'Need a stepladder'). Sets expectation before the homeowner taps in." },
      { key: "estimatedCostRange", label: "Cost range", group: "schedule", type: "text",
        usage: "Per-item cost. We sum these for the whole spring or fall visit when items are bundled." },
      { key: "routingOverride", label: "Routing override", group: "routing", type: "select", enumKey: "taskRoutingOverride",
        usage: "Has to be set so the item is eligible for handyman ('DIY default' or 'DIY capable'). Vendor-only items skip this path entirely." },
      { key: "assignmentType", label: "Assignment type", group: "routing", type: "select", enumKey: "taskAssignmentType",
        usage: "Same as the regular maintenance template field — Personal / Vendor / Either. Most handyman items are 'Either' with low effort." },
      { key: "safetyFloor", label: "Safety floor", group: "routing", type: "boolean",
        usage: "If on, the item NEVER lands on a punch list — the handyman path is bypassed and the template forces a vendor visit. Used for unsafe-to-DIY items." },
    ],
  },

  systems: {
    title: "System Category",
    groups: [
      { id: "identity", label: "Identity" },
      { id: "display", label: "Display" },
      { id: "behavior", label: "Behavior" },
    ],
    fields: [
      { key: "categoryKey", label: "Category key (matches home_systems.category)", group: "identity", type: "text", readonly: true,
        usage: "Internal name for this category. Stored on every home system the homeowner has, and referenced by every template gated to this category. Renaming breaks every existing system row plus every template that points at it." },
      { key: "displayName", label: "Display name", group: "display", type: "text",
        usage: "What the homeowner sees on the Property tab and in vendor coverage chips." },
      { key: "icon", label: "SF Symbol icon", group: "display", type: "text",
        usage: "Default icon for this category when no vendor logo is available. We try the brand logo first, then fall back to this icon, then to initials." },
      { key: "tier", label: "Tier", group: "behavior", type: "select", enumKey: "systemTier",
        usage: "How this category gets surfaced. Universal = automatically added to every property (HVAC, Plumbing, Electrical). Conditional = added based on quiz answers (snow removal for Northeast homes, septic for properties without municipal sewer). Specialty = only via the Browse sheet on the Property tab — uncommon stuff like wine cellars or saunas. Sub-system = hidden from vendor coverage; lives under a parent system (HVAC's filter, the pool's heater)." },
      { key: "displayPriority", label: "Display priority (sort within tier)", group: "behavior", type: "number",
        usage: "Sort order within tier — lower numbers come first. Used to order the vendor coverage gap list." },
      { key: "defaultCadence", label: "Default cadence", group: "behavior", type: "select", enumKey: "taskFrequency", allowCustom: true,
        usage: "Suggested cadence shown on the vendor coverage card to set expectation ('Cleaning Service · biweekly'). Doesn't auto-create routines — just informational so the homeowner knows what 'normal' looks like." },
      { key: "showInVendorCoverage", label: "Show in vendor coverage", group: "behavior", type: "boolean",
        usage: "If off, hides this category from the vendor-coverage UI on the homeowner's home screen. Used for sub-systems that live under a parent (the pool's heater shouldn't list separately — it's part of the Pool category)." },
      { key: "specialtyGroup", label: "Specialty group (for Browse sheet)", group: "behavior", type: "text",
        usage: "For Specialty-tier categories, the section heading shown in the Browse Specialty Systems sheet (e.g. 'Outdoor Amenities', 'Smart Home & Energy'). Helps the homeowner find related options." },
    ],
  },

  vehicles: {
    title: "Vehicle Task Generation",
    groups: [
      { id: "source", label: "Source" },
      { id: "prompt", label: "System prompt" },
      { id: "samples", label: "Sample outputs" },
    ],
    fields: [
      { key: "sourceFile", label: "Source file", group: "source", type: "text", readonly: true,
        usage: "Path to the file in the codebase that holds this prompt. The file is the source of truth — what you see here is a snapshot." },
      { key: "sourceExists", label: "Source exists in repo", group: "source", type: "boolean", readonly: true,
        usage: "Off if we couldn't find the file when we last refreshed the snapshot. Means the snapshot is stale or the file was moved." },
      { key: "systemPrompt", label: "System prompt", group: "prompt", type: "textarea", rows: 14,
        help: "Sent to Claude with role: 'system'. Drives per-vehicle maintenance schedule generation.",
        usage: "The instructions sent to Claude that drive the per-vehicle maintenance schedule. After a homeowner adds a vehicle (by VIN or manually), Claude reads these instructions plus the vehicle's year/make/model and emits the suggested maintenance items. Cached sample outputs on the right show what the prompt actually produces for a few representative vehicles." },
      { key: "cachedSamples", label: "Cached sample outputs (4 representative vehicles)", group: "samples", type: "json-readonly",
        usage: "What the prompt actually produces for a few sample vehicles (BMW X5, Honda CR-V, Tesla Model 3, Ford F-150). Re-cached when you run the export script with the refresh flag." },
    ],
  },

  prompts: {
    title: "Edge Function Prompt",
    groups: [
      { id: "identity", label: "Identity" },
      { id: "behavior", label: "Behavior" },
      { id: "prompt", label: "System prompt" },
    ],
    fields: [
      { key: "functionName", label: "Function name", group: "identity", type: "text", readonly: true,
        usage: "The folder name for this AI function. To deploy a change, run `supabase functions deploy [name] --no-verify-jwt`." },
      { key: "sourceFile", label: "Source file", group: "identity", type: "text", readonly: true,
        usage: "Path to the file in the codebase that holds this prompt." },
      { key: "model", label: "Model", group: "behavior", type: "select", enumKey: "claudeModel", allowCustom: true,
        usage: "Which Claude model handles this task. Sonnet for most everyday work, Haiku for cheap classification, Opus for hard reasoning. Update this when migrating model versions." },
      { key: "systemPrompt", label: "System prompt (first detected)", group: "prompt", type: "textarea", rows: 16,
        help: "Heuristic extraction. v2 will surface every message role + structured response shape.",
        usage: "The first instruction block sent to Claude. About 90% of the app's intelligence lives here — what answers go in, what shape comes out. Changing the prompt requires deploying the function for it to take effect." },
    ],
  },
};

// -----------------------------------------------------------------------------
// Renderer
// -----------------------------------------------------------------------------

export function renderEntityForm(viewId, entity, original = entity) {
  const schema = SCHEMAS[viewId];
  if (!schema) {
    return `<p class="admin-muted">No structured form schema for "${escapeHtml(viewId)}" yet.</p>`;
  }
  if (!entity) {
    return `<p class="admin-muted">Select something to see its full configuration.</p>`;
  }
  const groupHtml = schema.groups
    .map((g) => renderGroup(g, schema, entity, original))
    .filter(Boolean)
    .join("");
  return `<div class="admin-form" data-form-root data-view-id="${escapeHtml(viewId)}">${groupHtml}</div>`;
}

function renderGroup(group, schema, entity, original) {
  const fields = schema.fields.filter((f) => f.group === group.id);
  if (!fields.length) return "";
  const fieldHtml = fields.map((f) => renderField(f, entity, original)).join("");
  return `
    <fieldset class="admin-form__group">
      <legend>${escapeHtml(group.label)}</legend>
      ${fieldHtml}
    </fieldset>
  `;
}

function renderField(field, entity, original) {
  // Phase 5d — virtual fields (assignment-tier) compute their value
  // from the entity's existing fields rather than reading a key.
  let value;
  let originalValue;
  if (field.type === "assignment-tier") {
    value = readAssignmentTier(entity);
    originalValue = readAssignmentTier(original);
  } else {
    value = readPath(entity, field.key);
    originalValue = readPath(original, field.key);
  }
  const changed = !equalDeep(value, originalValue);
  const help = field.help
    ? `<small class="admin-form__help">${escapeHtml(field.help)}</small>`
    : "";
  const changedTag = changed
    ? `<span class="admin-form__changed">changed</span>`
    : "";
  // Phase 4b — every field gets a (?) info button surfacing the `usage`
  // string from the schema. Click toggles a popover with the explainer.
  const infoBtn = field.usage
    ? `<button type="button" class="admin-form__info" data-info-text="${escapeHtml(field.usage)}" data-info-label="${escapeHtml(field.label)}" aria-label="What is ${escapeHtml(field.label)} used for?">?</button>`
    : "";
  const control = renderControl(field, value);
  return `
    <label class="admin-form__field ${changed ? "is-changed" : ""}" data-field-key="${escapeHtml(field.key)}">
      <span class="admin-form__label">
        ${escapeHtml(field.label)}
        ${infoBtn}
        ${changedTag}
      </span>
      ${control}
      ${help}
    </label>
  `;
}

function renderControl(field, value) {
  const readonlyAttr = field.readonly ? "readonly disabled" : "";
  const dataKey = `data-field-key="${escapeHtml(field.key)}"`;
  switch (field.type) {
    case "text":
      return `<input type="text" ${dataKey} value="${escapeHtml(stringify(value))}" ${readonlyAttr} />`;
    case "number":
      return `<input type="number" ${dataKey} value="${escapeHtml(stringify(value))}" ${readonlyAttr} />`;
    case "textarea": {
      const rows = field.rows || 4;
      return `<textarea ${dataKey} rows="${rows}" ${readonlyAttr}>${escapeHtml(stringify(value))}</textarea>`;
    }
    case "boolean": {
      const checked = value === true ? "checked" : "";
      return `
        <span class="admin-form__toggle">
          <input type="checkbox" ${dataKey} ${checked} ${readonlyAttr} />
          <span class="admin-form__toggle-label">${value === true ? "On" : "Off"}</span>
        </span>
      `;
    }
    case "assignment-tier": {
      const opts = ENUMS.assignmentTier;
      const stringValue = stringify(value);
      const optionsHtml = opts
        .map((o) => `<option value="${escapeHtml(o.value)}" ${o.value === stringValue ? "selected" : ""}>${escapeHtml(o.label)}</option>`)
        .join("");
      return `<select ${dataKey} data-control="assignment-tier" ${readonlyAttr}>${optionsHtml}</select>`;
    }
    case "select": {
      const opts = ENUMS[field.enumKey] || [];
      const stringValue = stringify(value);
      const matched = opts.some((o) => o.value === stringValue);
      const includeCustom = field.allowCustom && !matched && stringValue;
      const optionsHtml = opts
        .map(
          (o) =>
            `<option value="${escapeHtml(o.value)}" ${o.value === stringValue ? "selected" : ""}>${escapeHtml(o.label)}</option>`
        )
        .join("");
      const customOpt = includeCustom
        ? `<option value="${escapeHtml(stringValue)}" selected>${escapeHtml(stringValue)} (custom)</option>`
        : "";
      return `<select ${dataKey} ${readonlyAttr}>${optionsHtml}${customOpt}</select>`;
    }
    case "answer-options":
      return renderAnswerOptions(value || [], field, readonlyAttr);
    case "chip-list":
      return renderChipList(value || [], field, readonlyAttr);
    case "enum-list":
      return renderEnumList(value || [], field, readonlyAttr);
    case "month-picker":
      return renderMonthPicker(value || [], field, readonlyAttr);
    case "system-picker": {
      const stringValue = stringify(value) || "";
      // Pull known categories from the datalist that admin.js populates
      // at startup. Building from a single source keeps the dropdown in
      // sync with system-categories.json.
      const datalist = typeof document !== "undefined"
        ? document.querySelector("#admin-system-options")
        : null;
      const opts = datalist
        ? Array.from(datalist.querySelectorAll("option")).map((o) => ({ value: o.value, label: o.textContent || o.value }))
        : [];
      const known = new Set(opts.map((o) => o.value));
      const includeCustom = stringValue && !known.has(stringValue);
      const optionsHtml = opts
        .map((o) => `<option value="${escapeHtml(o.value)}" ${o.value === stringValue ? "selected" : ""}>${escapeHtml(o.label)}</option>`)
        .join("");
      const customOpt = includeCustom
        ? `<option value="${escapeHtml(stringValue)}" selected>${escapeHtml(stringValue)} (custom)</option>`
        : "";
      const placeholderOpt = !stringValue
        ? `<option value="" selected disabled>Pick a system…</option>`
        : "";
      const addNewOpt = `<option value="__add_new__">+ Add new system…</option>`;
      return `
        <span class="admin-form__system-picker">
          <select ${dataKey} data-control="system-picker" ${readonlyAttr}>
            ${placeholderOpt}
            ${optionsHtml}
            ${customOpt}
            ${addNewOpt}
          </select>
        </span>
      `;
    }
    case "code":
      return `<pre class="admin-form__code" ${dataKey}>${escapeHtml(stringify(value)) || "<em>(none)</em>"}</pre>`;
    case "json-readonly":
      return `<pre class="admin-form__code" ${dataKey}>${escapeHtml(JSON.stringify(value ?? null, null, 2))}</pre>`;
    default:
      return `<input type="text" ${dataKey} value="${escapeHtml(stringify(value))}" />`;
  }
}

function renderAnswerOptions(options, field, readonlyAttr) {
  const list = options
    .map(
      (opt, idx) => `
        <li class="admin-form__answer-option" data-index="${idx}">
          <span class="admin-form__answer-icon">${opt.icon ? `<code>${escapeHtml(opt.icon)}</code>` : "—"}</span>
          <code class="admin-form__answer-id">${escapeHtml(opt.id || "")}</code>
          <span class="admin-form__answer-label">${escapeHtml(opt.label || "")}</span>
          ${opt.acceptsCustomInput ? `<span class="admin-pill admin-pill--note">accepts custom</span>` : ""}
        </li>
      `
    )
    .join("");
  return `
    <div class="admin-form__answer-options" data-field-key="${escapeHtml(field.key)}" ${readonlyAttr.includes("disabled") ? "data-readonly" : ""}>
      <ol>${list || `<li class="admin-muted">No options.</li>`}</ol>
      <p class="admin-form__hint">${
        readonlyAttr ? "Edit answer options via a proposal note." : "Edit options inline (proposal mode)"
      }</p>
    </div>
  `;
}

function renderChipList(values, field, readonlyAttr) {
  const items = (values || [])
    .map((v) => `<span class="admin-chip">${escapeHtml(stringify(v))}</span>`)
    .join("");
  const inputHtml = readonlyAttr
    ? ""
    : `<input type="text" class="admin-form__chip-input" data-field-key="${escapeHtml(field.key)}" placeholder="Type and press Enter to add" />`;
  return `
    <div class="admin-form__chips" data-field-key="${escapeHtml(field.key)}">
      ${items || `<span class="admin-muted">(empty)</span>`}
      ${inputHtml}
    </div>
  `;
}

function renderEnumList(values, field, readonlyAttr) {
  const opts = ENUMS[field.enumKey] || [];
  const set = new Set(values || []);
  const chips = opts
    .map((o) => {
      const active = set.has(o.value);
      return `
        <button type="button" class="admin-chip admin-chip--toggle ${active ? "is-active" : ""}"
                data-field-key="${escapeHtml(field.key)}" data-chip-value="${escapeHtml(o.value)}"
                ${readonlyAttr.includes("disabled") ? "disabled" : ""}>
          ${escapeHtml(o.label)}
        </button>
      `;
    })
    .join("");
  return `<div class="admin-form__chips" data-field-key="${escapeHtml(field.key)}">${chips}</div>`;
}

function renderMonthPicker(values, field, readonlyAttr) {
  const set = new Set((values || []).map(Number));
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  const chips = months
    .map(
      (label, i) => `
        <button type="button" class="admin-chip admin-chip--toggle ${set.has(i + 1) ? "is-active" : ""}"
                data-field-key="${escapeHtml(field.key)}" data-chip-value="${i + 1}"
                ${readonlyAttr.includes("disabled") ? "disabled" : ""}>
          ${label}
        </button>
      `
    )
    .join("");
  return `<div class="admin-form__chips" data-field-key="${escapeHtml(field.key)}">${chips}</div>`;
}

// -----------------------------------------------------------------------------
// Form state mutation + diff computation
// -----------------------------------------------------------------------------

export function attachFormHandlers(container, viewId, original, current, onChange) {
  if (!container) return;
  const root = container.querySelector?.("[data-form-root]") || container;
  if (!root) return;

  // Inputs (text / number / textarea / select)
  root.querySelectorAll("input[type='text'], input[type='number'], textarea, select").forEach((input) => {
    if (input.dataset.fieldKey == null) return;
    if (input.classList.contains("admin-form__chip-input")) return;
    const handler = () => {
      let v = input.value;
      if (input.type === "number") v = v === "" ? null : Number(v);
      // Assignment-tier: write back to the underlying assignmentType +
      // routingOverride + safetyFloor combo via the helper, then bail
      // (we don't want to write the literal tier value to a field).
      if (input.dataset.control === "assignment-tier") {
        writeAssignmentTier(current, v);
        onChange?.(current);
        return;
      }
      // System-picker: trap the "+ Add new system…" sentinel and prompt
      // for a fresh value before committing.
      if (input.dataset.control === "system-picker" && v === "__add_new__") {
        const fresh = window.prompt("New system category name:", "");
        if (!fresh || !fresh.trim()) {
          // Revert to the previous value.
          input.value = readPath(current, input.dataset.fieldKey) || "";
          return;
        }
        v = fresh.trim();
        // Add a custom <option> so the dropdown still shows it after
        // selection. The exporter's next pass will pick it up if the
        // proposal lands.
        const customOption = document.createElement("option");
        customOption.value = v;
        customOption.textContent = `${v} (proposed new)`;
        customOption.selected = true;
        // Insert before the "+ Add new" sentinel.
        const sentinel = input.querySelector('option[value="__add_new__"]');
        if (sentinel) input.insertBefore(customOption, sentinel);
        else input.appendChild(customOption);
        input.value = v;
      }
      writePath(current, input.dataset.fieldKey, v);
      onChange?.(current);
    };
    input.addEventListener("input", handler);
    input.addEventListener("change", handler);
  });

  // Booleans
  root.querySelectorAll("input[type='checkbox']").forEach((input) => {
    if (input.dataset.fieldKey == null) return;
    input.addEventListener("change", () => {
      writePath(current, input.dataset.fieldKey, input.checked);
      onChange?.(current);
    });
  });

  // Toggle chips (enum-list, month-picker)
  root.querySelectorAll(".admin-chip--toggle").forEach((chip) => {
    if (chip.disabled) return;
    chip.addEventListener("click", () => {
      const key = chip.dataset.fieldKey;
      const raw = chip.dataset.chipValue;
      const value = /^\d+$/.test(raw) ? Number(raw) : raw;
      const arr = readPath(current, key) || [];
      const next = Array.isArray(arr) ? arr.slice() : [];
      const idx = next.indexOf(value);
      if (idx >= 0) next.splice(idx, 1);
      else next.push(value);
      next.sort((a, b) => (typeof a === "number" ? a - b : String(a).localeCompare(String(b))));
      writePath(current, key, next);
      chip.classList.toggle("is-active");
      onChange?.(current);
    });
  });

  // Chip-list inputs (string array)
  root.querySelectorAll(".admin-form__chip-input").forEach((input) => {
    input.addEventListener("keydown", (event) => {
      if (event.key !== "Enter") return;
      event.preventDefault();
      const key = input.dataset.fieldKey;
      const value = input.value.trim();
      if (!value) return;
      const arr = readPath(current, key) || [];
      const next = Array.isArray(arr) ? arr.slice() : [];
      next.push(value);
      writePath(current, key, next);
      input.value = "";
      onChange?.(current);
    });
  });

  // Info buttons — click toggles a popover anchored to the button.
  root.querySelectorAll(".admin-form__info").forEach((btn) => {
    btn.addEventListener("click", (event) => {
      event.preventDefault();
      event.stopPropagation();
      showInfoPopover(btn);
    });
  });
}

// Phase 4b — info popover. Lazy-built singleton anchored next to the
// clicked (?) button. Click anywhere to dismiss.
let infoPopoverEl = null;
function showInfoPopover(anchorBtn) {
  hideInfoPopover();
  const text = anchorBtn.dataset.infoText || "";
  const label = anchorBtn.dataset.infoLabel || "";
  const pop = document.createElement("div");
  pop.className = "admin-info-popover";
  pop.innerHTML = `
    <header>
      <strong>${escapeHtml(label)}</strong>
      <button type="button" class="admin-info-popover__close" aria-label="Close">×</button>
    </header>
    <p>${escapeHtml(text)}</p>
  `;
  document.body.appendChild(pop);
  const rect = anchorBtn.getBoundingClientRect();
  // Position below the button by default; flip up if too low.
  const popHeight = 200;
  const wantedTop = rect.bottom + 8;
  const flipUp = wantedTop + popHeight > window.innerHeight - 16;
  pop.style.top = (flipUp ? Math.max(16, rect.top - popHeight - 8) : wantedTop) + "px";
  pop.style.left = Math.min(window.innerWidth - 360 - 16, Math.max(16, rect.left - 16)) + "px";
  infoPopoverEl = pop;
  pop.querySelector(".admin-info-popover__close")?.addEventListener("click", hideInfoPopover);
  // Click outside closes
  setTimeout(() => {
    document.addEventListener("click", outsideClickHandler);
    document.addEventListener("keydown", escHandler);
  }, 0);
}

function hideInfoPopover() {
  if (infoPopoverEl) {
    infoPopoverEl.remove();
    infoPopoverEl = null;
  }
  document.removeEventListener("click", outsideClickHandler);
  document.removeEventListener("keydown", escHandler);
}

function outsideClickHandler(event) {
  if (!infoPopoverEl) return;
  if (infoPopoverEl.contains(event.target)) return;
  hideInfoPopover();
}

function escHandler(event) {
  if (event.key === "Escape") hideInfoPopover();
}

export function computeProposedDiff(viewId, original, current) {
  const schema = SCHEMAS[viewId];
  if (!schema) return {};
  const diff = {};
  for (const field of schema.fields) {
    if (field.readonly) continue;
    let from;
    let to;
    if (field.type === "assignment-tier") {
      from = readAssignmentTier(original);
      to = readAssignmentTier(current);
    } else {
      from = readPath(original, field.key);
      to = readPath(current, field.key);
    }
    if (!equalDeep(from, to)) diff[field.key] = { from, to };
  }
  return diff;
}

export function renderDiffStrip(diff, schema) {
  const keys = Object.keys(diff);
  if (!keys.length) return "";
  const items = keys
    .map((k) => {
      const field = schema?.fields.find((f) => f.key === k);
      const label = field?.label || k;
      const from = formatValueForDiff(diff[k].from, field);
      const to = formatValueForDiff(diff[k].to, field);
      return `
        <li class="admin-diff__item">
          <span class="admin-diff__field">${escapeHtml(label)}</span>
          <span class="admin-diff__from">${escapeHtml(from)}</span>
          <span class="admin-diff__arrow">→</span>
          <span class="admin-diff__to">${escapeHtml(to)}</span>
        </li>
      `;
    })
    .join("");
  return `
    <div class="admin-diff-strip">
      <div class="admin-diff-strip__header">
        <strong>${keys.length} pending change${keys.length === 1 ? "" : "s"}</strong>
        <span class="admin-muted">Save will record this as a change_request note with a structured diff.</span>
      </div>
      <ul class="admin-diff-strip__list">${items}</ul>
    </div>
  `;
}

function formatValueForDiff(value, field) {
  if (value == null || value === "") return "(empty)";
  if (Array.isArray(value)) return value.length === 0 ? "(empty)" : value.map(formatItemSummary).join(", ");
  if (typeof value === "boolean") return value ? "On" : "Off";
  if (typeof value === "object") return JSON.stringify(value).slice(0, 80);
  return String(value);
}

function formatItemSummary(item) {
  if (item == null) return "null";
  if (typeof item === "string") return item;
  if (typeof item === "object") return item.label || item.id || item.value || JSON.stringify(item).slice(0, 30);
  return String(item);
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

function readPath(obj, path) {
  if (!obj || !path) return undefined;
  const parts = path.split(".");
  let cur = obj;
  for (const p of parts) {
    if (cur == null) return undefined;
    cur = cur[p];
  }
  return cur;
}

function writePath(obj, path, value) {
  if (!obj || !path) return;
  const parts = path.split(".");
  let cur = obj;
  for (let i = 0; i < parts.length - 1; i++) {
    if (cur[parts[i]] == null || typeof cur[parts[i]] !== "object") cur[parts[i]] = {};
    cur = cur[parts[i]];
  }
  cur[parts[parts.length - 1]] = value;
}

function equalDeep(a, b) {
  if (a === b) return true;
  if (a == null || b == null) return a == null && b == null;
  if (typeof a !== typeof b) return false;
  if (typeof a !== "object") return false;
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  if (Array.isArray(a)) {
    if (a.length !== b.length) return false;
    for (let i = 0; i < a.length; i++) if (!equalDeep(a[i], b[i])) return false;
    return true;
  }
  const ak = Object.keys(a);
  const bk = Object.keys(b);
  if (ak.length !== bk.length) return false;
  for (const k of ak) if (!equalDeep(a[k], b[k])) return false;
  return true;
}

function stringify(value) {
  if (value == null) return "";
  if (typeof value === "string") return value;
  if (typeof value === "boolean") return value ? "true" : "false";
  if (typeof value === "object") return JSON.stringify(value);
  return String(value);
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// Phase 5d — Assignment tier helpers.
//
// Maps the underlying `assignmentType + routingOverride + safetyFloor`
// combo into one of 4 user-facing tiers. The 4th tier ("homeowner_only")
// is reserved for runtime — templates never ship as that, homeowners
// pull tasks in via the per-task button. We allow it in the dropdown
// for completeness but warn at save time.

export function readAssignmentTier(entity) {
  if (!entity) return "vendor_or_handyman";
  if (entity.safetyFloor === true) return "vendor_only";
  const ro = entity.routingOverride;
  if (ro === "vendorOnly") return "vendor_only";
  if (ro === "diyDefault") return "handyman_only";
  if (ro === "bundledIntoParent") {
    // Bundle children inherit their parent's tier. Fall through to
    // assignmentType reading.
  }
  if (entity.assignmentType === "vendor") return "vendor_only";
  if (entity.assignmentType === "personal" && ro !== "diyCapable") {
    return "handyman_only";
  }
  return "vendor_or_handyman";
}

export function writeAssignmentTier(entity, tier) {
  if (!entity) return;
  switch (tier) {
    case "vendor_only":
      entity.assignmentType = "vendor";
      entity.routingOverride = "vendorOnly";
      entity.safetyFloor = true;
      break;
    case "vendor_or_handyman":
      entity.assignmentType = "either";
      entity.routingOverride = "vendorDefault";
      entity.safetyFloor = false;
      break;
    case "handyman_only":
      entity.assignmentType = "personal";
      entity.routingOverride = "diyDefault";
      entity.safetyFloor = false;
      break;
    case "homeowner_only":
      // Same Swift mapping as handyman_only, but with a homeowner-only
      // hint in the entity for downstream validation. Templates should
      // not actually ship in this state — handled by save-time warning.
      entity.assignmentType = "personal";
      entity.routingOverride = "diyDefault";
      entity.safetyFloor = false;
      entity._tierWarning = "This tier is runtime-only — templates shouldn't seed in 'I'll do it myself'.";
      break;
  }
}

// Phase 5d — Title case helper. Capitalises content words while leaving
// short prepositions/articles lowercase (except first/last). Used on
// task/template/routine/system display titles to keep the lab tidy.
const TITLE_CASE_LOWERCASE_WORDS = new Set([
  "a", "an", "and", "as", "at", "but", "by", "for", "from", "in", "into",
  "nor", "of", "on", "or", "out", "the", "to", "via", "vs", "with",
]);

export function titleCase(input) {
  if (input == null) return "";
  const s = String(input);
  if (!s.trim()) return s;
  // Preserve leading/trailing whitespace.
  const tokens = s.split(/(\s+)/);
  let firstWord = -1;
  let lastWord = -1;
  tokens.forEach((tok, i) => {
    if (/\S/.test(tok)) {
      if (firstWord < 0) firstWord = i;
      lastWord = i;
    }
  });
  return tokens
    .map((tok, i) => {
      if (!/\S/.test(tok)) return tok;
      // Preserve URLs / template-key patterns / tokens (e.g. {state})
      if (/^https?:\/\//i.test(tok)) return tok;
      if (tok.startsWith("{") && tok.endsWith("}")) return tok;
      // Hyphenated words capitalize each part
      const parts = tok.split("-").map((p, j) => capitalizeWord(p, i === firstWord || i === lastWord || j > 0));
      return parts.join("-");
    })
    .join("");
}

function capitalizeWord(word, forceCapital) {
  if (!word) return word;
  const lower = word.toLowerCase();
  if (!forceCapital && TITLE_CASE_LOWERCASE_WORDS.has(lower)) return lower;
  // Preserve all-caps acronyms (HVAC, EV, GFCI, etc.) — if the original
  // word is 2+ chars and ALL upper, leave it alone.
  if (word.length >= 2 && word === word.toUpperCase() && /[A-Z]/.test(word)) {
    return word;
  }
  return lower.charAt(0).toUpperCase() + lower.slice(1);
}

export const __forTesting = { readPath, writePath, equalDeep, escapeHtml, titleCase };

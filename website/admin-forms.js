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
        usage: "Stable identifier used everywhere downstream — house_quiz_state JSONB key on properties, scope_id on every admin_codex_note about this Q, dispatch key in HouseQuizAnswerMapper's switch statement, and the lookup key for HouseQuizFeedbackLibrary entries. Do not rename without renaming all references." },
      { key: "title", label: "Title", group: "copy", type: "text",
        help: "Supports {yearBuilt}, {street}, {state}, {city}, {squareFootage}, {roofType} tokens.",
        usage: "Rendered as the question's primary headline in HouseQuizView. PropertyFactBundle interpolates the {tokens} at render time; if any token is unresolvable, fallbackTitle wins. Action-first phrasing reads better in the iOS card layout." },
      { key: "subtitle", label: "Subtitle", group: "copy", type: "textarea", rows: 2,
        usage: "Smaller body text under the title in HouseQuizView. Use it to explain WHY we're asking — what we'll do with the answer." },
      { key: "fallbackTitle", label: "Fallback title (when tokens unresolved)", group: "copy", type: "text",
        help: "Used as the literal title if a {token} can't resolve. Leave blank if title has no tokens.",
        usage: "HouseQuizQuestion.personalizedTitle(using:) returns this when any token in the main title can't resolve against PropertyFactBundle. Required for every title that contains tokens — without it, users can see literal '{state}' on screen." },
      { key: "section", label: "Section (legacy grouping)", group: "structure", type: "select", enumKey: "quizSection",
        usage: "Pre-Phase-60.3 organizing concept (homeBasics / inside / outside / etc). Some legacy UI still groups by section; new flows group by chapter instead." },
      { key: "chapter", label: "Chapter", group: "structure", type: "select", enumKey: "quizChapter",
        usage: "Phase 60.3 grouping that drives the chapter intro card, the chapter progress pill, and Q36's repositioning. yourPros chapter intentionally fires Q36 BEFORE Q11/Q13/Q14/Q15 so the preference tier is set before vendor branches persist .either tasks." },
      { key: "kind", label: "Question kind", group: "behavior", type: "select", enumKey: "quizKind",
        usage: "Drives which renderer HouseQuizView uses (singleChoiceBody / multiSelectBody / currencyBody / providerCaptureInline / etc) and which save shape HouseQuizAnswer takes (answerId / selectedIds / generatorFuelType / kids / etc). Changing kind on an existing Q is a breaking change for persisted answers." },
      { key: "supportsSelectAll", label: "Show 'Select all' pill (multi-select only)", group: "behavior", type: "boolean",
        usage: "Build 86 opt-in flag, currently only Q10 (appliances) uses it. Renders a 'Select all / Deselect all' pill above the chip grid. Skips 'Other' (custom input) and 'None of these' (mutual-exclusion) options when toggling." },
      { key: "documentUploadCategory", label: "Document upload category (optional)", group: "behavior", type: "text",
        usage: "When set, the quiz card shows an 'Upload instead' button that lets the user attach a doc (mortgage statement, utility bill, etc) directly. The upload bypasses the answer flow and lands as a documents row with this category. Currently used by Q5 (mortgage) and Q19 (utility bill)." },
      { key: "answerOptions", label: "Answer options", group: "answers", type: "answer-options",
        usage: "Rendered as the chip grid (singleChoice/multiSelect) or as label-only metadata (kinds with custom forms). Each AnswerOption has id, label, optional icon (SF Symbol), and acceptsCustomInput flag. Reordering changes user-visible order; renaming an id orphans persisted answers." },
      { key: "providerTypes", label: "Provider types (for providerSearch kind)", group: "extras", type: "enum-list", enumKey: "providerTypes",
        usage: "Static list of provider_type tokens that the picker filters on (matches utility_providers.provider_type column). Used by all kind=providerSearch questions plus inline pickers triggered by providerFollowUpAnswerIds. Q19 uses dynamicProviderTypes instead." },
      { key: "providerFollowUpAnswerIds", label: "Provider follow-up answer IDs", group: "extras", type: "chip-list",
        help: "Comma-separated answer option IDs that trigger an inline provider picker.",
        usage: "When the user picks any of these answer ids, HouseQuizView reveals an inline UtilityProviderSearchPicker scoped to providerTypes. Used by Q11 (lawn=pro), Q13 (pest=quarterly_pro), Q14 (irrigation=full/drip), Q15 (security=monitored)." },
      { key: "providerSearchPlaceholder", label: "Provider picker placeholder", group: "extras", type: "text",
        usage: "Build 87 per-question placeholder for the inline provider picker (e.g. 'TruGreen, BrightView…'). Nil falls back to the picker's built-in default." },
      { key: "dynamicSkip", label: "Dynamic skip rule (Swift closure)", group: "extras", type: "code", readonly: true,
        help: "Conditional skip logic captured raw from Swift. Editing requires a code change.",
        usage: "Closure called at advance time with HouseQuizState. Returning true causes the view model to mark this question skipped and move to the next. Used by Q11b (skip when no_lawn), Q12b/Q12c (skip when not pool), Q14 (skip when no_lawn), Q19 (skip when electric/geothermal heating), Q25b (skip when no garage)." },
      { key: "dynamicProviderTypes", label: "Dynamic provider-types rule (Swift closure)", group: "extras", type: "code", readonly: true,
        usage: "Phase 18b runtime narrowing of providerTypes based on prior answers. Q19 reads Q3's heating fuel and returns ['oil'] / ['propane'] / [] (empty = skip). When this resolves to empty the view auto-skips the Q." },
      { key: "_impact.creates_systems", label: "Creates these systems (heuristic)", group: "impact", type: "chip-list", readonly: true,
        usage: "Heuristic backreference baked at JSON-export time — best-guess of which home_systems.category rows the answer mapper will create when this Q is answered. Used by the Decisions queue + Impact tab to show downstream effects." },
    ],
  },

  tasks: {
    title: "Maintenance Template",
    groups: [
      { id: "identity", label: "Identity" },
      { id: "copy", label: "User-facing copy" },
      { id: "schedule", label: "Schedule + cost" },
      { id: "routing", label: "Assignment + routing" },
      { id: "gating", label: "Gating + scope" },
      { id: "bundle", label: "Bundle membership" },
      { id: "extras", label: "Advanced" },
    ],
    fields: [
      { key: "templateKey", label: "Template key (Swift-derived)", group: "identity", type: "text", readonly: true,
        usage: "Reconciler dedup key + the value that lands on every maintenance_tasks.template_id column. Derived as stableId ?? '{systemCategory}:{title}'. The admin_template_stats RPC counts rows by this key." },
      { key: "stableId", label: "Stable ID override (rename safety)", group: "identity", type: "text",
        help: "Use only when renaming a template whose previous title is referenced by existing task rows.",
        usage: "When set, overrides the derived templateKey. Use ONLY when renaming a template whose old title is referenced by existing maintenance_tasks rows — set to the EXACT previous templateKey ('{oldCategory}:{oldTitle}') so the reconciler keeps deduping correctly and existing completion history stays attached." },
      { key: "systemCategory", label: "System category", group: "identity", type: "system-picker",
        usage: "Maps to home_systems.category. Determines which system row this template seeds tasks under, and via SystemCategoryRegistry, which tier (universal/conditional/specialty) the system is gated to." },
      { key: "title", label: "Title", group: "copy", type: "text",
        help: "Action-first: 'Schedule …', 'Check …', 'Inspect …'. No 'Professional X' titles.",
        usage: "Rendered on UnifiedTaskCard. When linked to a vendor, the card reframes to 'Schedule {Vendor}: {title.lowercased}' (Phase 19l). Voice rules: action-first verbs, no em dashes, no 'Professional X' prefixes." },
      { key: "description", label: "Description", group: "copy", type: "textarea", rows: 4,
        usage: "Body text on the task detail sheet. For vendor-managed tasks, MaintenanceTaskReconciler prepends 'Your job: book the appointment and be home for it. {Vendor} will handle the work.' before this string." },
      { key: "notes", label: "Pro tips / notes", group: "copy", type: "textarea", rows: 3,
        usage: "Optional notes shown in the task detail sheet's 'Pro tips' callout. Often interpolated with {city}/{state} via MaintenanceTemplate.interpolated(city:state:)." },
      { key: "frequency", label: "Frequency", group: "schedule", type: "select", enumKey: "taskFrequency", allowCustom: true,
        usage: "Parsed by MaintenanceTemplate.interval into DateComponents that drive the next-due-date math. Phase 50 added biweekly/triweekly/every-N-weeks support." },
      { key: "seasonalTiming", label: "Seasonal anchor", group: "schedule", type: "select", enumKey: "taskSeasonalTiming",
        usage: "Phase 54A: tells MaintenanceTaskReconciler.initialDueDate to walk to the next Spring/Summer/Fall/Winter anchor instead of today+interval, with a 14-day lookahead buffer. Sub-annual cadences ignore this; annual+ cadences honor it." },
      { key: "estimatedCostRange", label: "Estimated cost range", group: "schedule", type: "text",
        usage: "Shown in vendor-managed task subtitles ('$200-$400'). Future: aggregated into the InvestmentSummaryCard's projected-spend rollup." },
      { key: "priority", label: "Priority", group: "schedule", type: "select", enumKey: "taskPriority",
        usage: "High/Medium/Low. UnifiedTaskCard renders a priority pill ONLY for high-priority overdue tasks or critical/urgent — Phase 56.6 stopped rendering for plain 'High' since it was the default and appearing on ~70% of cards." },
      { key: "maxIntervalDays", label: "Max interval (days, optional)", group: "schedule", type: "number",
        help: "Warns user when extending frequency past this cap.",
        usage: "FrequencyPickerSheet warns when the user tries to extend a task's next-due past this cap. Used for safety-sensitive items (smoke detectors capped 365, septic pumping capped 1825)." },
      { key: "warrantyLinked", label: "Warranty-linked (warns on cadence change)", group: "schedule", type: "boolean",
        usage: "When true, FrequencyPickerSheet shows a 'this may void your warranty' warning. Used for HVAC tune-ups, annual boiler service, generator service — manufacturer warranty terms tie to documented service intervals." },
      { key: "assignmentType", label: "Assignment type", group: "routing", type: "select", enumKey: "taskAssignmentType",
        usage: "Personal (always DIY) / Vendor (always pro) / Either (defaults personal, flippable by Q36 + per-task toggle). Drives which UnifiedTaskCard variant renders + whether the reconciler tries to link a contractor at task-creation time." },
      { key: "routingOverride", label: "Routing override", group: "routing", type: "select", enumKey: "taskRoutingOverride",
        usage: "Phase 50 routing hint independent of assignmentType. .vendorOnly = single-option picker; .vendorDefault = 3-option (vendor/handyman/DIY); .diyDefault = handyman+DIY 2-option, hard floor against Q36 flip; .diyCapable = 3-option but defaults DIY; .bundledIntoParent = template never renders standalone, only via its bundle parent." },
      { key: "safetyFloor", label: "Safety floor (always vendor regardless of preference)", group: "routing", type: "boolean",
        usage: "Reconciler.resolveAssignment short-circuits and forces .vendor lane regardless of preference tier. Used for gas, panel, roof, septic, well, chimney — flat-out unsafe to hand a homeowner." },
      { key: "diyEffortMinutes", label: "DIY effort (minutes)", group: "routing", type: "number",
        usage: "Time estimate shown on personal task cards as 'X min' / 'X hr Y min'. Used by Day1TaskCurator to decide if a task is small enough to delegate to handyman ('mixed' tier: tasks > 30 min go to vendor lane; 'hire-out': all to vendor)." },
      { key: "diyEffortLabel", label: "DIY effort label", group: "routing", type: "text",
        help: "e.g. 'Anyone can do this', 'Need a stepladder', 'Skip if you don't like heights'",
        usage: "Difficulty descriptor shown alongside diyEffortMinutes on UnifiedTaskCard. Helps users self-assess before tapping in." },
      { key: "isEssential", label: "Essential (auto-seeded at quiz time)", group: "gating", type: "boolean",
        usage: "When true, MaintenanceTaskReconciler seeds this template at quiz completion. When false, the template only surfaces in the 'Recommended for your home' (Phase 54C) sheet — opt-in, not auto-seeded." },
      { key: "isDIY", label: "isDIY (deprecated — use assignmentType + diyEffortMinutes)", group: "gating", type: "boolean",
        usage: "Pre-Phase 19k field. Use assignmentType + diyEffortMinutes instead. Kept on existing templates for backward compatibility." },
      { key: "professionalRequired", label: "professionalRequired (deprecated — use safetyFloor)", group: "gating", type: "boolean",
        usage: "Pre-Phase 50 field. Use safetyFloor + routingOverride instead." },
      { key: "regionalPack", label: "Regional pack", group: "gating", type: "select", enumKey: "regionalPack",
        usage: "Phase 57 regional gate. When set, template only surfaces on properties whose properties.regional_pack matches (auto-derived from state). Nil = universal — no regional gating." },
      { key: "requiredSubtypes", label: "Required subtypes", group: "gating", type: "chip-list",
        help: "Tags that gate this template on the home_systems row's subtype set.",
        usage: "MaintenanceTemplates.activeSubtypes(category, flags) builds an active set per property; this template only seeds if ALL its required subtypes are in that set. Common values: ['tank'] for tank water heaters, ['pool', 'pool_chlorine'] for chlorine-pool-only templates, ['has_pets'] for pet-related items." },
      { key: "equipmentKeywords", label: "Equipment keywords (child-system migration)", group: "gating", type: "chip-list",
        usage: "Phase 19h-: when a child home_system row matching these keywords is added (e.g. a Filter under HVAC), the reconciler migrates matching tasks from the parent system to the child. Used to move 'replace HVAC filter' tasks to a specific equipment record once it's added." },
      { key: "bundleId", label: "Bundle ID", group: "bundle", type: "text",
        help: "e.g. 'Roofing:spring', 'Handyman:fall'. Bundled templates roll up into one task.",
        usage: "Phase 50 bundle marker. All templates sharing the same bundleId roll up into ONE maintenance_tasks row at reconcile time, with a 'What's included:' checklist in notes. The bundle's templateKey is the bundleId itself." },
      { key: "bundleTitle", label: "Bundle title (first child only)", group: "bundle", type: "text",
        usage: "Display title for the bundle parent task. Read from the FIRST child template; siblings inherit it. Reframed at render time when a vendor is linked: 'Schedule {Vendor}: {bundleTitle.lowercased}'." },
      { key: "_impact.in_bundle.siblings", label: "Sibling templates in this bundle", group: "extras", type: "chip-list", readonly: true,
        usage: "Backreference baked at JSON-export time — the other templates that share this template's bundleId. Helps audit bundle composition without grepping Swift." },
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
        usage: "Stored on routines.routine_kind in Postgres. Stable string identifier — do not rename. iOS RoutineKind enum case rawValue maps to this." },
      { key: "swiftCase", label: "Swift case", group: "identity", type: "text", readonly: true,
        usage: "iOS-side enum case name (camelCase). Used by the routine kind switch statements (displayLabel, icon, isVendorBased, supportsVendorLink)." },
      { key: "displayLabel", label: "Display label", group: "display", type: "text",
        usage: "User-visible text on RoutineRow, RoutineDetailView, and Apple Calendar-style chips. Shown when no vendor is linked; vendor-linked routines render the vendor name instead." },
      { key: "icon", label: "SF Symbol icon", group: "display", type: "text",
        help: "e.g. 'sparkles', 'leaf.fill', 'snowflake'. Must exist in Apple's SF Symbols catalog.",
        usage: "Falls through VendorLogoView's hierarchy: vendor logo → category SF Symbol → routine kind icon → generic. Tested in Apple's SF Symbols app before shipping." },
      { key: "isVendorBased", label: "Vendor-based (defaults to having a contractor link)", group: "display", type: "boolean",
        usage: "Drives form defaults in RoutineEditSheet (vendor section visible/required) + per-banner copy in PickupDayBanner (cadence-based routines say 'pickup tomorrow', vendor-based routines say 'visit tomorrow')." },
      { key: "seederDefault.cadenceType", label: "Default cadence", group: "defaults", type: "select", enumKey: "cadenceType",
        usage: "Pre-fills RoutineEditSheet when adding a routine of this kind. Maps to routines.cadence_type column on insert." },
      { key: "seederDefault.activeMonths", label: "Default active months (1=Jan…12=Dec)", group: "defaults", type: "month-picker",
        usage: "Pre-fills routines.active_months. Snow removal defaults to {12,1,2,3,4}, lawn care to {4..11}, year-round routines like trash leave this empty (= all 12 months)." },
      { key: "seederDefault.defaultEveningBeforeReminder", label: "Default evening-before reminder", group: "defaults", type: "boolean",
        usage: "Pre-fills the routine row's evening_before_reminder flag. The PickupDayBanner surfaces these between 6pm and midnight on the day before the routine fires." },
      { key: "seederDefault.defaultMorningOfReminder", label: "Default morning-of reminder", group: "defaults", type: "boolean",
        usage: "Pre-fills the routine row's morning_of_reminder flag. PickupDayBanner surfaces these before 10am on the day-of." },
    ],
  },

  handyman: {
    title: "Handyman Template",
    groups: [
      { id: "identity", label: "Identity" },
      { id: "copy", label: "User-facing copy" },
      { id: "schedule", label: "Schedule + effort" },
      { id: "routing", label: "Routing" },
    ],
    fields: [
      { key: "templateKey", label: "Template key", group: "identity", type: "text", readonly: true,
        usage: "Same dedup key shared with Tasks. Filtered subset (routingOverride .diyDefault / .diyCapable + Handyman:* bundles) flow into the punch-list path." },
      { key: "systemCategory", label: "System category", group: "identity", type: "system-picker",
        usage: "Most handyman templates land under 'Handyman' but some live under their primary category (e.g. HVAC filter swap stays under HVAC)." },
      { key: "bundleId", label: "Bundle (Handyman:spring / Handyman:fall)", group: "identity", type: "text",
        usage: "Phase 54B bundles. 'Handyman:spring' rolls up the spring punch list; 'Handyman:fall' rolls up the fall list. Children share this id and inherit bundleTitle from the first child." },
      { key: "title", label: "Title", group: "copy", type: "text",
        usage: "Rendered on the punch list as a single line. Punch items added at runtime via 'Add to handyman list' bypass templates entirely." },
      { key: "description", label: "Description", group: "copy", type: "textarea", rows: 3,
        usage: "Body text on the task detail sheet." },
      { key: "notes", label: "Notes", group: "copy", type: "textarea", rows: 2,
        usage: "Optional pro tips. For Handyman:spring/fall bundle parents, this often lists what's typically covered in a spring/fall visit." },
      { key: "frequency", label: "Frequency", group: "schedule", type: "select", enumKey: "taskFrequency", allowCustom: true,
        usage: "Most handyman templates are semi-annual (Spring + Fall) or annual." },
      { key: "seasonalTiming", label: "Seasonal anchor", group: "schedule", type: "select", enumKey: "taskSeasonalTiming",
        usage: "Drives next-due via Phase 54A's initialDueDate seasonal anchor walk." },
      { key: "diyEffortMinutes", label: "Effort (minutes)", group: "schedule", type: "number",
        usage: "Day1TaskCurator's handyman-eligibility check requires diyEffortMinutes ≤ 60. Items larger than that need a real vendor visit, not a punch list bundle." },
      { key: "diyEffortLabel", label: "Effort label", group: "schedule", type: "text",
        usage: "Difficulty descriptor — same field as the parent Tasks schema." },
      { key: "estimatedCostRange", label: "Cost range", group: "schedule", type: "text",
        usage: "Per-item cost. Aggregated for the whole spring/fall visit when bundled." },
      { key: "routingOverride", label: "Routing override", group: "routing", type: "select", enumKey: "taskRoutingOverride",
        usage: "Handyman path requires .diyDefault or .diyCapable. .vendorOnly templates can't end up here." },
      { key: "assignmentType", label: "Assignment type", group: "routing", type: "select", enumKey: "taskAssignmentType",
        usage: "Same semantics as Tasks. Most handyman templates are .either with low diyEffortMinutes." },
      { key: "safetyFloor", label: "Safety floor", group: "routing", type: "boolean",
        usage: "If true, never lands on a punch list — handyman path is bypassed and the template forces vendor lane." },
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
        usage: "Stored as home_systems.category text. The reconciler matches templates' systemCategory against this. Renaming breaks every existing system row + every template gated to it." },
      { key: "displayName", label: "Display name", group: "display", type: "text",
        usage: "User-facing name on PropertyDetailView's systems list, in vendor coverage chips, and in the Browse Specialty Systems sheet." },
      { key: "icon", label: "SF Symbol icon", group: "display", type: "text",
        usage: "Default icon for this category when no vendor logo is available. VendorLogoView falls through: brand logo → category icon → initials." },
      { key: "tier", label: "Tier", group: "behavior", type: "select", enumKey: "systemTier",
        usage: "Universal (auto-backfilled to every property), Conditional (gated by quiz answers), Specialty (Browse sheet only), SubSystem (hidden from Vendor Coverage; lives under a parent)." },
      { key: "displayPriority", label: "Display priority (sort within tier)", group: "behavior", type: "number",
        usage: "Sort order within tier — lower numbers come first. Used by VendorCoverageSheet's gap-list ordering." },
      { key: "defaultCadence", label: "Default cadence", group: "behavior", type: "select", enumKey: "taskFrequency", allowCustom: true,
        usage: "Shown in vendor-coverage UI to set expectation ('Cleaning Service · biweekly'). Doesn't auto-create routines — those need an explicit user action." },
      { key: "showInVendorCoverage", label: "Show in vendor coverage", group: "behavior", type: "boolean",
        usage: "When false, hides this category from VendorCoverageSheet (used for SubSystem-tier rows that live under a parent)." },
      { key: "specialtyGroup", label: "Specialty group (for Browse sheet)", group: "behavior", type: "text",
        usage: "Header label in BrowseSpecialtySystemsSheet (e.g. 'Outdoor Amenities', 'Smart Home & Energy'). Tier-3 specialty categories grouped by this." },
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
        usage: "Path to the edge function in repo (supabase/functions/vehicle-lookup/index.ts)." },
      { key: "sourceExists", label: "Source exists in repo", group: "source", type: "boolean", readonly: true,
        usage: "Set to false when the exporter couldn't find the file. Indicates a stale snapshot or a moved/deleted edge function." },
      { key: "systemPrompt", label: "System prompt", group: "prompt", type: "textarea", rows: 14,
        help: "Sent to Claude with role: 'system'. Drives per-vehicle maintenance schedule generation.",
        usage: "Sent to Claude with role: 'system'. Drives the AI-generated per-vehicle maintenance schedule that lands as maintenance_tasks rows after VIN decode. Cached samples on the right show what the prompt produces for representative vehicles." },
      { key: "cachedSamples", label: "Cached sample outputs (4 representative vehicles)", group: "samples", type: "json-readonly",
        usage: "Cached responses from running the live edge function with synthetic inputs (BMW X5, Honda CR-V, Tesla Model 3, Ford F-150). Refreshed when --refresh-samples flag passed to exporter." },
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
        usage: "Folder name under supabase/functions/. Deploy with `supabase functions deploy {name} --no-verify-jwt`." },
      { key: "sourceFile", label: "Source file", group: "identity", type: "text", readonly: true,
        usage: "Path to index.ts. Click 'Open in admin detail' to jump back to the listed prompt panel." },
      { key: "model", label: "Model", group: "behavior", type: "select", enumKey: "claudeModel", allowCustom: true,
        usage: "Claude model passed to the @anthropic-ai/sdk client. Use claude-sonnet-4-6 for most production prompts; haiku for cheap classification; opus for hard reasoning. Update this when migrating model versions." },
      { key: "systemPrompt", label: "System prompt (first detected)", group: "prompt", type: "textarea", rows: 16,
        help: "Heuristic extraction. v2 will surface every message role + structured response shape.",
        usage: "First role:'system' content extracted by the Swift→JSON exporter. Where 90% of the app's intelligence lives. Changing the prompt requires `supabase functions deploy {function_name} --no-verify-jwt` to ship." },
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
  const value = readPath(entity, field.key);
  const originalValue = readPath(original, field.key);
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
    case "system-picker":
      return `<input type="text" ${dataKey} value="${escapeHtml(stringify(value))}" list="admin-system-options" ${readonlyAttr} />`;
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
    const from = readPath(original, field.key);
    const to = readPath(current, field.key);
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

export const __forTesting = { readPath, writePath, equalDeep, escapeHtml };

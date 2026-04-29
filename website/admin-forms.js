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
      { key: "id", label: "Question ID (Swift-baked)", group: "identity", type: "text", readonly: true },
      { key: "title", label: "Title", group: "copy", type: "text",
        help: "Supports {yearBuilt}, {street}, {state}, {city}, {squareFootage}, {roofType} tokens." },
      { key: "subtitle", label: "Subtitle", group: "copy", type: "textarea", rows: 2 },
      { key: "fallbackTitle", label: "Fallback title (when tokens unresolved)", group: "copy", type: "text",
        help: "Used as the literal title if a {token} can't resolve. Leave blank if title has no tokens." },
      { key: "section", label: "Section (legacy grouping)", group: "structure", type: "select", enumKey: "quizSection" },
      { key: "chapter", label: "Chapter", group: "structure", type: "select", enumKey: "quizChapter" },
      { key: "kind", label: "Question kind", group: "behavior", type: "select", enumKey: "quizKind" },
      { key: "supportsSelectAll", label: "Show 'Select all' pill (multi-select only)", group: "behavior", type: "boolean" },
      { key: "documentUploadCategory", label: "Document upload category (optional)", group: "behavior", type: "text" },
      { key: "answerOptions", label: "Answer options", group: "answers", type: "answer-options" },
      { key: "providerTypes", label: "Provider types (for providerSearch kind)", group: "extras", type: "enum-list", enumKey: "providerTypes" },
      { key: "providerFollowUpAnswerIds", label: "Provider follow-up answer IDs", group: "extras", type: "chip-list",
        help: "Comma-separated answer option IDs that trigger an inline provider picker." },
      { key: "providerSearchPlaceholder", label: "Provider picker placeholder", group: "extras", type: "text" },
      { key: "dynamicSkip", label: "Dynamic skip rule (Swift closure)", group: "extras", type: "code", readonly: true,
        help: "Conditional skip logic captured raw from Swift. Editing requires a code change." },
      { key: "dynamicProviderTypes", label: "Dynamic provider-types rule (Swift closure)", group: "extras", type: "code", readonly: true },
      { key: "_impact.creates_systems", label: "Creates these systems (heuristic)", group: "impact", type: "chip-list", readonly: true },
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
      { key: "templateKey", label: "Template key (Swift-derived)", group: "identity", type: "text", readonly: true },
      { key: "stableId", label: "Stable ID override (rename safety)", group: "identity", type: "text",
        help: "Use only when renaming a template whose previous title is referenced by existing task rows." },
      { key: "systemCategory", label: "System category", group: "identity", type: "system-picker" },
      { key: "title", label: "Title", group: "copy", type: "text",
        help: "Action-first: 'Schedule …', 'Check …', 'Inspect …'. No 'Professional X' titles." },
      { key: "description", label: "Description", group: "copy", type: "textarea", rows: 4 },
      { key: "notes", label: "Pro tips / notes", group: "copy", type: "textarea", rows: 3 },
      { key: "frequency", label: "Frequency", group: "schedule", type: "select", enumKey: "taskFrequency", allowCustom: true },
      { key: "seasonalTiming", label: "Seasonal anchor", group: "schedule", type: "select", enumKey: "taskSeasonalTiming" },
      { key: "estimatedCostRange", label: "Estimated cost range", group: "schedule", type: "text" },
      { key: "priority", label: "Priority", group: "schedule", type: "select", enumKey: "taskPriority" },
      { key: "maxIntervalDays", label: "Max interval (days, optional)", group: "schedule", type: "number",
        help: "Warns user when extending frequency past this cap." },
      { key: "warrantyLinked", label: "Warranty-linked (warns on cadence change)", group: "schedule", type: "boolean" },
      { key: "assignmentType", label: "Assignment type", group: "routing", type: "select", enumKey: "taskAssignmentType" },
      { key: "routingOverride", label: "Routing override", group: "routing", type: "select", enumKey: "taskRoutingOverride" },
      { key: "safetyFloor", label: "Safety floor (always vendor regardless of preference)", group: "routing", type: "boolean" },
      { key: "diyEffortMinutes", label: "DIY effort (minutes)", group: "routing", type: "number" },
      { key: "diyEffortLabel", label: "DIY effort label", group: "routing", type: "text",
        help: "e.g. 'Anyone can do this', 'Need a stepladder', 'Skip if you don't like heights'" },
      { key: "isEssential", label: "Essential (auto-seeded at quiz time)", group: "gating", type: "boolean" },
      { key: "isDIY", label: "isDIY (deprecated — use assignmentType + diyEffortMinutes)", group: "gating", type: "boolean" },
      { key: "professionalRequired", label: "professionalRequired (deprecated — use safetyFloor)", group: "gating", type: "boolean" },
      { key: "regionalPack", label: "Regional pack", group: "gating", type: "select", enumKey: "regionalPack" },
      { key: "requiredSubtypes", label: "Required subtypes", group: "gating", type: "chip-list",
        help: "Tags that gate this template on the home_systems row's subtype set." },
      { key: "equipmentKeywords", label: "Equipment keywords (child-system migration)", group: "gating", type: "chip-list" },
      { key: "bundleId", label: "Bundle ID", group: "bundle", type: "text",
        help: "e.g. 'Roofing:spring', 'Handyman:fall'. Bundled templates roll up into one task." },
      { key: "bundleTitle", label: "Bundle title (first child only)", group: "bundle", type: "text" },
      { key: "_impact.in_bundle.siblings", label: "Sibling templates in this bundle", group: "extras", type: "chip-list", readonly: true },
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
      { key: "rawValue", label: "Raw value (DB)", group: "identity", type: "text", readonly: true },
      { key: "swiftCase", label: "Swift case", group: "identity", type: "text", readonly: true },
      { key: "displayLabel", label: "Display label", group: "display", type: "text" },
      { key: "icon", label: "SF Symbol icon", group: "display", type: "text",
        help: "e.g. 'sparkles', 'leaf.fill', 'snowflake'. Must exist in Apple's SF Symbols catalog." },
      { key: "isVendorBased", label: "Vendor-based (defaults to having a contractor link)", group: "display", type: "boolean" },
      { key: "seederDefault.cadenceType", label: "Default cadence", group: "defaults", type: "select", enumKey: "cadenceType" },
      { key: "seederDefault.activeMonths", label: "Default active months (1=Jan…12=Dec)", group: "defaults", type: "month-picker" },
      { key: "seederDefault.defaultEveningBeforeReminder", label: "Default evening-before reminder", group: "defaults", type: "boolean" },
      { key: "seederDefault.defaultMorningOfReminder", label: "Default morning-of reminder", group: "defaults", type: "boolean" },
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
      { key: "templateKey", label: "Template key", group: "identity", type: "text", readonly: true },
      { key: "systemCategory", label: "System category", group: "identity", type: "system-picker" },
      { key: "bundleId", label: "Bundle (Handyman:spring / Handyman:fall)", group: "identity", type: "text" },
      { key: "title", label: "Title", group: "copy", type: "text" },
      { key: "description", label: "Description", group: "copy", type: "textarea", rows: 3 },
      { key: "notes", label: "Notes", group: "copy", type: "textarea", rows: 2 },
      { key: "frequency", label: "Frequency", group: "schedule", type: "select", enumKey: "taskFrequency", allowCustom: true },
      { key: "seasonalTiming", label: "Seasonal anchor", group: "schedule", type: "select", enumKey: "taskSeasonalTiming" },
      { key: "diyEffortMinutes", label: "Effort (minutes)", group: "schedule", type: "number" },
      { key: "diyEffortLabel", label: "Effort label", group: "schedule", type: "text" },
      { key: "estimatedCostRange", label: "Cost range", group: "schedule", type: "text" },
      { key: "routingOverride", label: "Routing override", group: "routing", type: "select", enumKey: "taskRoutingOverride" },
      { key: "assignmentType", label: "Assignment type", group: "routing", type: "select", enumKey: "taskAssignmentType" },
      { key: "safetyFloor", label: "Safety floor", group: "routing", type: "boolean" },
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
      { key: "categoryKey", label: "Category key (matches home_systems.category)", group: "identity", type: "text", readonly: true },
      { key: "displayName", label: "Display name", group: "display", type: "text" },
      { key: "icon", label: "SF Symbol icon", group: "display", type: "text" },
      { key: "tier", label: "Tier", group: "behavior", type: "select", enumKey: "systemTier" },
      { key: "displayPriority", label: "Display priority (sort within tier)", group: "behavior", type: "number" },
      { key: "defaultCadence", label: "Default cadence", group: "behavior", type: "select", enumKey: "taskFrequency", allowCustom: true },
      { key: "showInVendorCoverage", label: "Show in vendor coverage", group: "behavior", type: "boolean" },
      { key: "specialtyGroup", label: "Specialty group (for Browse sheet)", group: "behavior", type: "text" },
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
      { key: "sourceFile", label: "Source file", group: "source", type: "text", readonly: true },
      { key: "sourceExists", label: "Source exists in repo", group: "source", type: "boolean", readonly: true },
      { key: "systemPrompt", label: "System prompt", group: "prompt", type: "textarea", rows: 14,
        help: "Sent to Claude with role: 'system'. Drives per-vehicle maintenance schedule generation." },
      { key: "cachedSamples", label: "Cached sample outputs (4 representative vehicles)", group: "samples", type: "json-readonly" },
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
      { key: "functionName", label: "Function name", group: "identity", type: "text", readonly: true },
      { key: "sourceFile", label: "Source file", group: "identity", type: "text", readonly: true },
      { key: "model", label: "Model", group: "behavior", type: "select", enumKey: "claudeModel", allowCustom: true },
      { key: "systemPrompt", label: "System prompt (first detected)", group: "prompt", type: "textarea", rows: 16,
        help: "Heuristic extraction. v2 will surface every message role + structured response shape." },
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
  const control = renderControl(field, value);
  return `
    <label class="admin-form__field ${changed ? "is-changed" : ""}" data-field-key="${escapeHtml(field.key)}">
      <span class="admin-form__label">
        ${escapeHtml(field.label)}
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

import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";
import {
  SCHEMAS,
  renderEntityForm,
  attachFormHandlers,
  computeProposedDiff,
  renderDiffStrip,
  titleCase,
} from "/admin-forms.js";
import {
  openQuestionPreview,
  openQuizFlowPreview,
  closePreview,
} from "/admin-preview.js";
import {
  DEFAULT_FACTS,
  runSimulation,
  renderSimulatorUI,
  renderFactForm,
  attachFactFormHandlers,
  renderQuizModeUI,
  attachQuizModeHandlers,
  quizAnswerToFacts,
  QUIZ_PRESETS,
} from "/admin-simulator.js";
import {
  renderArchitectureOverview,
  renderArchitectureObject,
  attachArchitectureHandlers,
  findObject as findArchObject,
  getObjectMapLite,
  getClusters,
} from "/admin-architecture.js";

const SUPABASE_URL = "https://jsucwnkntdrxhysojgri.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";

const ADMIN_EMAIL = "tom@getchez.com";
const LOCAL_ITEMS_KEY = "chez-admin-content-items-v1";
const LOCAL_NOTES_KEY = "chez-admin-codex-notes-v1";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: false,
  },
});

const VIEWS = [
  {
    id: "decisions",
    label: "Decisions",
    type: "decision",
    title: "Decisions Queue",
    eyebrow: "Curate to launch",
    subtitle: "Auto-flagged entities awaiting your call. Approve, cut, or note for Claude.",
  },
  {
    id: "quiz",
    label: "Quiz",
    type: "question",
    title: "Quiz Builder",
    eyebrow: "Onboarding",
    subtitle: "Every quiz question with full Swift-side configuration. Notes round-trip to Claude.",
    liveSource: "quiz-questions",
  },
  {
    id: "tasks",
    label: "Tasks",
    type: "task",
    title: "Maintenance Templates",
    eyebrow: "MaintenanceTemplates.swift",
    subtitle: "Every template Haven seeds — full field set, lint warnings, bundle membership.",
    liveSource: "templates",
  },
  {
    id: "routines",
    label: "Routines",
    type: "routine",
    title: "Routine Kinds",
    eyebrow: "RoutineKind enum + RoutineSeeder defaults",
    subtitle: "The 20 kinds of recurring rhythms (vendor + cadence) the app understands.",
    liveSource: "routine-kinds",
  },
  {
    id: "handyman",
    label: "Handyman",
    type: "handyman",
    title: "Handyman Library + Punch List",
    eyebrow: "Spring auto-pops · Fall auto-pops · Library opt-in",
    subtitle:
      "Every template that can land on the handyman's plate. 🌷 Spring + 🍂 Fall items auto-populate the punch list at season anchors. 🛠️ Library items are opt-in — the homeowner picks them up via Recommended Services.",
    liveSource: "handyman-templates",
  },
  {
    id: "recommended",
    label: "Recommended",
    type: "recommended",
    title: "Recommended Services + Optional Tasks",
    eyebrow: "isEssential: false — homeowner opts in",
    subtitle:
      "Every opt-in template in the library. None of these auto-seed at quiz completion — the homeowner adds them via Recommended Services or the handyman punch list. Use this surface to audit voice and gating before the homeowner sees the menu.",
    liveSource: "templates",
  },
  {
    id: "systems",
    label: "Systems",
    type: "system",
    title: "System Categories",
    eyebrow: "SystemCategoryRegistry",
    subtitle: "Tiered registry that gates vendor coverage + drives template grouping.",
    liveSource: "system-categories",
  },
  {
    id: "vehicles",
    label: "Vehicles",
    type: "vehicle",
    title: "Vehicle Task Generation",
    eyebrow: "vehicle-lookup edge function",
    subtitle: "The prompt that generates per-vehicle maintenance schedules.",
    liveSource: "vehicle-task-prompt",
  },
  {
    id: "prompts",
    label: "Prompts",
    type: "prompt",
    title: "Edge Function Prompts",
    eyebrow: "supabase/functions/*/index.ts",
    subtitle: "All 50+ Edge Functions — first system prompt, model, and notes.",
    liveSource: "edge-function-prompts",
  },
  {
    id: "simulator",
    label: "Simulate",
    type: "simulator",
    title: "Reconciler Simulator",
    eyebrow: "What would seed?",
    subtitle: "Pick property facts and see what tasks the reconciler would create. JS port of MaintenanceTaskReconciler + Day1TaskCurator.",
  },
  {
    id: "searches",
    label: "Searches",
    type: "search",
    title: "Search Builders (legacy)",
    eyebrow: "Provider and system search",
    subtitle: "Hand-curated search-surface defaults. Will fold into Vendors+Systems eventually.",
  },
  {
    id: "activity",
    label: "Activity",
    type: "activity",
    title: "Recent Activity",
    eyebrow: "Applied + reverted timeline",
    subtitle: "Every change Claude has shipped, in reverse-chronological order.",
  },
  {
    id: "architecture",
    label: "Architecture",
    type: "architecture",
    title: "Object Architecture",
    eyebrow: "What objects exist + how they relate",
    subtitle: "Walkable map of every entity, its key fields, and its relationships. Click any “→ X” link to jump to the related object's card.",
  },
  {
    id: "claude_file",
    label: "Claude file",
    type: "claude_file",
    title: "CLAUDE_ADMIN_NOTES.md (live preview)",
    eyebrow: "What Claude reads next session",
    subtitle: "Live render of what's in your notes file right now. Mirrors the sync script's output without needing a local terminal.",
  },
  {
    id: "notes",
    label: "Notes",
    type: "note",
    title: "All Notes",
    eyebrow: "Product memory for Claude + Codex",
    subtitle: "Every contextual note you've saved. Filter by intent + target.",
  },
];

const DEFAULT_ROUTINES = [
  ["Cleaning / housekeeping", "Biweekly", "Wednesday 9:00 AM", "Year-round", "housekeeping_program"],
  ["Landscaping", "Weekly", "Wednesday 8:00 AM", "April-November", "landscaping_program"],
  ["Trash and recycling", "Weekly", "Wednesday 7:00 PM", "Year-round", "waste_program"],
  ["Pool service", "Weekly", "Tuesday 10:00 AM", "May-September", "pool_program"],
  ["Pest control", "Every 90 days", "No default weekday", "Year-round", "pest_and_termite_program"],
  ["Pet waste pickup", "Weekly", "Wednesday 8:00 AM", "Year-round", "custom_routine_program"],
  ["Mosquito and tick spraying", "Triweekly", "Tuesday", "April-October", "mosquito_and_tick_program"],
  ["Snow removal contract", "Every 90 days", "No default weekday", "December-April", "snow_and_ice_management_program"],
  ["Irrigation program", "Annual", "No default weekday", "March-November", "irrigation_program"],
  ["Security and smart-home program", "Annual", "No default weekday", "Year-round", "security_and_smart_home_program"],
  ["HVAC program", "Annual", "No default weekday", "Year-round", "hvac_program"],
  ["Generator program", "Annual", "No default weekday", "Year-round", "generator_program"],
  ["Handyman recurring", "On demand", "No default cadence", "Year-round", "handyman_recurring"],
];

const DEFAULT_VENDOR_CATEGORIES = [
  ["Handyman", "Always visible in Q15b. Stamps preferred handyman and feeds Next Handyman Visit."],
  ["House cleaner", "Creates cleaning routine when provider is captured."],
  ["HVAC service", "Creates HVAC service routine/program."],
  ["Plumber", "Routes plumbing work."],
  ["Electrician", "Routes electrical work."],
  ["Roofer", "Routes roofing, gutter, and roof inspection work."],
  ["Tree service", "Routes tree assessment and pruning work."],
  ["Mosquito & tick", "Creates seasonal mosquito/tick routine."],
  ["Snow removal", "Snow-state gated winter contract."],
  ["Pet waste", "Pet-gated recurring pickup service."],
  ["Septic pumper", "Visible only for septic homes."],
  ["Well water service", "Visible only for well homes."],
  ["Chimney sweep", "Visible when fireplace/chimney signal exists."],
  ["Hardscape / masonry", "Visible when Q11 says mostly hardscape."],
  ["Generator service", "Visible when generator exists."],
];

const DEFAULT_SEARCHES = [
  ["Vendor search", "Search local vendors by category, city, state, rating, and certification.", ["landscaping", "pool_service", "pest_control", "irrigation", "security", "trash"]],
  ["Utility provider search", "Search electric, internet, gas, oil, propane, trash, and insurance providers.", ["electric", "internet_cable", "oil", "propane", "natural_gas", "home_insurance"]],
  ["System search", "Search canonical system categories the quiz can create.", ["HVAC", "Roofing", "Water Heater", "Electrical", "Crawl Space", "Generator", "Solar", "Pool/Spa"]],
  ["Equipment search", "Search brand, model, serial, and manuals for system profiles.", ["manufacturer", "model", "manual", "warranty"]],
  ["Handyman scope search", "Search low-effort punch-list tasks that can be bundled into first visit.", ["caulk", "gutter", "GFCI", "smoke", "filter", "door", "dryer vent"]],
];

const DEFAULT_SYSTEMS = [
  "HVAC",
  "Roofing",
  "Water Heater",
  "Electrical",
  "Plumbing",
  "Well System",
  "Septic System",
  "Crawl Space",
  "Sump Pump",
  "Pool/Spa",
  "Irrigation",
  "Security System",
  "Generator",
  "Solar",
  "Garage Door",
  "Chimney",
  "Appliance",
  "Landscaping",
  "Handyman",
];

const state = {
  session: null,
  storageMode: "cloud",
  view: "quiz",
  auditQuestions: [],
  auditTasks: [],
  adminItems: [],
  notes: [],
  liveData: {}, // { quiz-questions: { generatedAt, count, entries: [...] }, templates: ..., ... }
  selected: null,
  search: "",
  statusFilter: "all",
  // Phase 5q — extra filter axes for Tasks / Recommended / Handyman so
  // Tom can narrow 220+ templates down by lifecycle + season + routing
  // without scrolling. Reset to "all" on view change.
  lifecycleFilter: "all", // all | auto_seed | opt_in | bundle_child | bundle_parent
  seasonFilter: "all",    // all | Spring | Summer | Fall | Winter | year_round | Spring/Fall
  routingFilter: "all",   // all | vendor_only | vendor_or_handyman | handyman_only | bundled
  // Phase 7 — simulator scratch state. Fact bundle + last result so
  // re-rendering the surface doesn't reset Tom's edits.
  simFacts: structuredCloneSafePure(DEFAULT_FACTS),
  simResult: null,
  // Phase 5k — Quiz Mode state.
  simMode: "quiz",  // "quiz" | "facts"
  simQuizAnswers: {},
  // Phase 5e — currently-focused architecture object (null = overview).
  archSelectedKey: null,
};

function structuredCloneSafePure(value) {
  return JSON.parse(JSON.stringify(value ?? {}));
}

const el = {
  login: document.querySelector("[data-login]"),
  app: document.querySelector("[data-app]"),
  loginForm: document.querySelector("[data-login-form]"),
  loginEmail: document.querySelector("[data-login-email]"),
  loginPassword: document.querySelector("[data-login-password]"),
  loginFeedback: document.querySelector("[data-login-feedback]"),
  sessionEmail: document.querySelector("[data-session-email]"),
  signOut: document.querySelector("[data-sign-out]"),
  nav: document.querySelector("[data-nav]"),
  viewEyebrow: document.querySelector("[data-view-eyebrow]"),
  viewTitle: document.querySelector("[data-view-title]"),
  viewSubtitle: document.querySelector("[data-view-subtitle]"),
  storageWarning: document.querySelector("[data-storage-warning]"),
  search: document.querySelector("[data-search]"),
  statusFilter: document.querySelector("[data-status-filter]"),
  stats: document.querySelector("[data-stats]"),
  list: document.querySelector("[data-list]"),
  emptyDetail: document.querySelector("[data-empty-detail]"),
  detail: document.querySelector("[data-detail]"),
  detailKind: document.querySelector("[data-detail-kind]"),
  detailTitle: document.querySelector("[data-detail-title]"),
  detailSubtitle: document.querySelector("[data-detail-subtitle]"),
  detailStatus: document.querySelector("[data-detail-status]"),
  fieldTitle: document.querySelector("[data-field-title]"),
  fieldStatus: document.querySelector("[data-field-status]"),
  fieldCategory: document.querySelector("[data-field-category]"),
  fieldSort: document.querySelector("[data-field-sort]"),
  fieldDescription: document.querySelector("[data-field-description]"),
  fieldPayload: document.querySelector("[data-field-payload]"),
  saveItem: document.querySelector("[data-save-item]"),
  promoteItem: document.querySelector("[data-promote-item]"),
  duplicateItem: document.querySelector("[data-duplicate-item]"),
  deleteItem: document.querySelector("[data-delete-item]"),
  newItem: document.querySelector("[data-new-item]"),
  exportConfig: document.querySelector("[data-export-config]"),
  contextNote: document.querySelector("[data-context-note]"),
  contextNotes: document.querySelector("[data-context-notes]"),
  saveNote: document.querySelector("[data-save-note]"),
  // Admin Lab v2 — Phase 4 note form additions
  fieldIntent: document.querySelector("[data-field-intent]"),
  fieldTarget: document.querySelector("[data-field-target]"),
  // Phase 4b — schema-driven form + diff + previews
  formHost: document.querySelector("[data-form-host]"),
  diffHost: document.querySelector("[data-diff-host]"),
  curatedForm: document.querySelector("[data-curated-form]"),
  previewQuestion: document.querySelector("[data-preview-question]"),
  previewQuiz: document.querySelector("[data-preview-quiz]"),
  systemOptions: document.querySelector("#admin-system-options"),
  // Phase 7.5 — launch lifecycle controls
  lockToggle: document.querySelector("[data-lock-toggle]"),
  launchPill: document.querySelector("[data-launch-pill]"),
  readinessPill: document.querySelector("[data-readiness-pill]"),
  readinessCount: document.querySelector("[data-readiness-count]"),
  readinessBar: document.querySelector("[data-readiness-bar]"),
  readinessHint: document.querySelector("[data-readiness-hint]"),
  // Phase 5 — note attachments
  fieldAttachment: document.querySelector("[data-field-attachment]"),
  attachmentStatus: document.querySelector("[data-attachment-status]"),
  // Phase 4b — Impact + Usage tabs
  detailTabs: document.querySelector("[data-detail-tabs]"),
  impactHost: document.querySelector("[data-impact-host]"),
  usageHost: document.querySelector("[data-usage-host]"),
  // Phase 5i — Global search palette
  palette: document.querySelector("[data-palette]"),
  paletteInput: document.querySelector("[data-palette-input]"),
  paletteResults: document.querySelector("[data-palette-results]"),
  paletteHint: document.querySelector("[data-palette-hint]"),
};

const paletteState = { open: false, results: [], activeIndex: 0 };

// Phase 5 — pending file uploads queued for the next note save
const pendingAttachments = [];

// Phase 4b — per-detail editing state. `original` is the unmodified entity
// from the JSON snapshot (or admin_content_items row). `current` is a deep
// clone we mutate as Tom edits. The diff between the two is the
// proposed_diff that gets attached to the next saved note.
const editingState = {
  viewId: null,
  original: null,
  current: null,
};

init();

async function init() {
  wireEvents();
  await restoreSession();
}

function wireEvents() {
  el.loginForm.addEventListener("submit", signIn);
  el.signOut.addEventListener("click", signOut);
  el.search.addEventListener("input", () => {
    state.search = el.search.value;
    renderList();
  });
  el.statusFilter.addEventListener("change", () => {
    state.statusFilter = el.statusFilter.value;
    renderList();
  });
  el.newItem.addEventListener("click", createNewItem);
  el.exportConfig.addEventListener("click", exportConfig);
  el.saveItem.addEventListener("click", saveSelectedItem);
  el.promoteItem.addEventListener("click", promoteSelectedItem);
  el.duplicateItem.addEventListener("click", duplicateSelectedItem);
  el.deleteItem.addEventListener("click", deleteSelectedItem);
  el.saveNote.addEventListener("click", saveContextNote);

  // Phase 4b — preview buttons + flow drilldown
  el.lockToggle?.addEventListener("click", () => toggleLockSelected());

  // Phase 5 — file attachment uploader
  el.fieldAttachment?.addEventListener("change", handleAttachmentSelect);

  // Phase 4b — detail-panel tab switching
  el.detailTabs?.querySelectorAll("[data-detail-tab]").forEach((btn) => {
    btn.addEventListener("click", () => switchDetailTab(btn.dataset.detailTab));
  });

  // Phase 7.5 — keyboard shortcuts (only when no input has focus)
  document.addEventListener("keydown", (event) => {
    const target = event.target;
    const inField =
      target instanceof HTMLInputElement ||
      target instanceof HTMLTextAreaElement ||
      target instanceof HTMLSelectElement ||
      (target?.isContentEditable);
    // Cmd+K / Ctrl+K opens the global palette regardless of focus
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault();
      openPalette();
      return;
    }
    if (paletteState.open) return; // palette has its own keymap
    if (event.key === "?" && event.shiftKey && !inField) {
      event.preventDefault();
      showShortcutHelp();
      return;
    }
    if (event.key === "/" && !inField) {
      event.preventDefault();
      el.search?.focus();
      el.search?.select();
      return;
    }
    if (event.key === "Escape" && !inField) {
      if (state.search) {
        state.search = "";
        el.search.value = "";
        render();
      } else if (state.selected) {
        state.selected = null;
        render();
      }
    }
  });

  // Phase 5i — Palette wiring
  el.palette?.querySelectorAll("[data-palette-dismiss]").forEach((node) => {
    node.addEventListener("click", () => closePalette());
  });
  el.paletteInput?.addEventListener("input", () => {
    paletteState.activeIndex = 0;
    renderPaletteResults();
  });
  el.paletteInput?.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      event.preventDefault();
      closePalette();
      return;
    }
    if (event.key === "ArrowDown") {
      event.preventDefault();
      paletteState.activeIndex = Math.min(paletteState.results.length - 1, paletteState.activeIndex + 1);
      renderPaletteResults();
      return;
    }
    if (event.key === "ArrowUp") {
      event.preventDefault();
      paletteState.activeIndex = Math.max(0, paletteState.activeIndex - 1);
      renderPaletteResults();
      return;
    }
    if (event.key === "Enter") {
      event.preventDefault();
      const r = paletteState.results[paletteState.activeIndex];
      if (r) activatePaletteResult(r);
    }
  });

  el.previewQuestion?.addEventListener("click", () => {
    if (!state.selected || state.selected.itemType !== "question") return;
    const q = structuredCloneSafe(editingState.current ?? state.selected.payload);
    openQuestionPreview(q, buildPreviewOptions());
  });
  el.previewQuiz?.addEventListener("click", () => {
    const entries = state.liveData["quiz-questions"]?.entries || [];
    if (!entries.length) {
      alert("Quiz JSON not loaded yet. Run scripts/export_swift_admin_data.mjs and refresh.");
      return;
    }
    // Annotate each Q with note count so the walkthrough's notes panel
    // shows the historical thread.
    const annotated = entries.map((q) => ({
      ...q,
      _noteCount: state.notes.filter((n) => n.scopeType === "question" && (n.scopeId === q.id || n.scopeTitle === q.title))
        .length,
    }));
    openQuizFlowPreview(annotated, buildPreviewOptions());
  });
}

// Phase 7+ — Build the options bag passed into preview overlays. Wires
// mapper-effects digest, per-question note lookups, and the live note
// save handler so the preview's notes panel round-trips into
// admin_codex_notes (and thus into CLAUDE_ADMIN_NOTES.md after sync).
function buildPreviewOptions() {
  return {
    mapperEffects: state.liveData["quiz-mapper-effects"]?.effectsByQuestion || {},
    notesForQuestion: (qId) =>
      state.notes
        .filter((n) => n.scopeType === "question" && (n.scopeId === qId || n.scopeTitle === qId))
        .sort((a, b) => +new Date(b.createdAt) - +new Date(a.createdAt)),
    onSaveNote: async ({ scopeId, scopeTitle, body, intent, target, snapshot }) => {
      await writeNote({
        scopeType: "question",
        scopeId,
        scopeTitle,
        body,
        intent: intent || "feedback",
        target: target || "claude",
        snapshot: snapshot || {},
      });
    },
    onJumpToDetail: (qId) => {
      // Jump back to the Quiz surface and select the matching item.
      state.view = "quiz";
      const items = liveItemsForView("quiz") || [];
      const match = items.find((i) => i.payload?.id === qId);
      if (match) state.selected = match;
      render();
    },
  };
}

// =============================================================================
// Phase 5i — Cmd+K global palette
// =============================================================================
// Indexes every entity (quiz / tasks / handyman / routines / systems /
// vehicles / prompts) plus every saved note + every architecture object.
// Match score = simple substring presence with a tier preference (titles
// rank above bodies). Result list capped at 25 to keep rendering fast.

function openPalette() {
  if (!el.palette) return;
  paletteState.open = true;
  paletteState.activeIndex = 0;
  el.palette.hidden = false;
  el.palette.classList.add("is-open");
  el.paletteInput.value = "";
  renderPaletteResults();
  setTimeout(() => el.paletteInput.focus(), 10);
}

function closePalette() {
  if (!el.palette) return;
  paletteState.open = false;
  el.palette.hidden = true;
  el.palette.classList.remove("is-open");
  paletteState.results = [];
  paletteState.activeIndex = 0;
}

function buildPaletteIndex() {
  const out = [];
  // Live entities
  for (const surfaceId of ["quiz", "tasks", "handyman", "routines", "systems", "vehicles", "prompts"]) {
    const items = liveItemsForView(surfaceId) || [];
    for (const item of items) {
      out.push({
        kind: "entity",
        view: surfaceId,
        item,
        emoji: surfaceEmoji(surfaceId),
        title: item.title,
        subtitle: `${surfaceLabel(surfaceId)} · ${item.category || ""}`,
        searchText: [
          item.title,
          item.category,
          item.description,
          item.payload?.id,
          item.payload?.templateKey,
          item.payload?.categoryKey,
          item.payload?.functionName,
          item.payload?.rawValue,
          item.payload?.systemCategory,
        ]
          .filter(Boolean)
          .join(" ")
          .toLowerCase(),
      });
    }
  }
  // Architecture objects
  for (const obj of getObjectMapLite()) {
    out.push({
      kind: "architecture",
      archKey: obj.key,
      emoji: obj.emoji,
      title: obj.name,
      subtitle: `Architecture · ${obj.cluster}`,
      searchText: `${obj.name} ${obj.cluster} ${obj.key}`.toLowerCase(),
    });
  }
  // Notes
  for (const note of state.notes) {
    if (note.parentNoteId) continue;
    out.push({
      kind: "note",
      note,
      emoji: "📝",
      title: note.scopeTitle || note.body?.slice(0, 60) || "(untitled note)",
      subtitle: `Note · ${note.intent || "feedback"} · ${note.scopeType || "general"}${note.appliedAt ? " · applied" : ""}`,
      searchText: [note.body, note.scopeTitle, note.scopeId, note.intent, note.scopeType]
        .filter(Boolean)
        .join(" ")
        .toLowerCase(),
    });
  }
  return out;
}

function surfaceEmoji(viewId) {
  return (
    {
      quiz: "❓",
      tasks: "✅",
      handyman: "🔨",
      routines: "🔁",
      systems: "🏷️",
      vehicles: "🚗",
      prompts: "🧠",
    }[viewId] || "•"
  );
}

function surfaceLabel(viewId) {
  return (
    {
      quiz: "Quiz",
      tasks: "Tasks",
      handyman: "Handyman",
      routines: "Routines",
      systems: "Systems",
      vehicles: "Vehicles",
      prompts: "Prompts",
    }[viewId] || viewId
  );
}

function renderPaletteResults() {
  if (!el.paletteResults) return;
  const query = (el.paletteInput?.value || "").trim().toLowerCase();
  const tokens = query.split(/\s+/).filter(Boolean);
  const all = buildPaletteIndex();

  const scored = tokens.length
    ? all
        .map((r) => {
          let score = 0;
          for (const tok of tokens) {
            if (r.title.toLowerCase().includes(tok)) score += 4;
            if (r.searchText.includes(tok)) score += 2;
          }
          return { r, score };
        })
        .filter((x) => x.score > 0)
        .sort((a, b) => b.score - a.score)
        .map((x) => x.r)
    : all.filter((r) => r.kind === "entity" && (r.view === "quiz" || r.view === "tasks")).slice(0, 12);

  paletteState.results = scored.slice(0, 25);
  if (paletteState.activeIndex >= paletteState.results.length) {
    paletteState.activeIndex = Math.max(0, paletteState.results.length - 1);
  }

  if (!paletteState.results.length) {
    el.paletteResults.innerHTML = `<div class="admin-palette__empty">${query ? `No matches for "${escapeHtml(query)}"` : "Type to search any entity, note, or edge function…"}</div>`;
    if (el.paletteHint) {
      el.paletteHint.textContent = query
        ? "Try a partial title or a question id like 'q3' or 'roof'."
        : "Start typing to search across every quiz question, template, system, routine, edge function, and saved note.";
    }
    return;
  }

  el.paletteResults.innerHTML = paletteState.results
    .map(
      (r, i) => `
        <button type="button" class="admin-palette__result ${i === paletteState.activeIndex ? "is-active" : ""}" data-palette-index="${i}">
          <span class="admin-palette__result-emoji">${r.emoji}</span>
          <span class="admin-palette__result-body">
            <span class="admin-palette__result-title">${escapeHtml(r.title)}</span>
            <span class="admin-palette__result-subtitle">${escapeHtml(r.subtitle)}</span>
          </span>
        </button>
      `
    )
    .join("");

  el.paletteResults.querySelectorAll("[data-palette-index]").forEach((btn) => {
    btn.addEventListener("mouseenter", () => {
      paletteState.activeIndex = Number(btn.dataset.paletteIndex);
      renderPaletteResults();
    });
    btn.addEventListener("click", () => {
      const r = paletteState.results[Number(btn.dataset.paletteIndex)];
      if (r) activatePaletteResult(r);
    });
  });

  if (el.paletteHint) {
    el.paletteHint.textContent = `${paletteState.results.length} match${paletteState.results.length === 1 ? "" : "es"} · Enter to open · Esc to close`;
  }
}

function activatePaletteResult(r) {
  closePalette();
  if (r.kind === "entity") {
    state.view = r.view;
    state.selected = r.item;
    render();
    return;
  }
  if (r.kind === "architecture") {
    state.view = "architecture";
    state.archSelectedKey = r.archKey;
    render();
    return;
  }
  if (r.kind === "note") {
    if (noteCanJumpToEntity(r.note)) {
      const targetView = viewIdForType(r.note.scopeType);
      const targetItem = locateLiveItemByScope(r.note);
      if (targetView && targetItem) {
        state.view = targetView;
        state.selected = targetItem;
        render();
        return;
      }
    }
    state.view = "notes";
    state.selected = r.note;
    render();
  }
}

function showShortcutHelp() {
  alert(
    [
      "Keyboard shortcuts",
      "",
      "Cmd/Ctrl+K — open the global search palette (any entity, note, edge fn)",
      "/ — focus the surface search input",
      "Esc — close palette, then clear search, then deselect, then close preview",
      "↑↓ — navigate palette results",
      "Enter — open the highlighted palette result",
      "? — this help",
    ].join("\n")
  );
}

function indexOfSelectedQuestion() {
  const entries = state.liveData["quiz-questions"]?.entries || [];
  const id = state.selected?.payload?.id;
  if (!id) return 1;
  const idx = entries.findIndex((q) => q.id === id);
  return idx >= 0 ? idx + 1 : 1;
}

function populateSystemOptions() {
  if (!el.systemOptions) return;
  const sys = state.liveData["system-categories"]?.entries || [];
  el.systemOptions.innerHTML = sys
    .map(
      (s) =>
        `<option value="${escapeHtml(s.categoryKey)}">${escapeHtml(s.displayName || s.categoryKey)} · Tier ${escapeHtml(
          s.tier || "?"
        )}</option>`
    )
    .join("");
}

async function restoreSession() {
  const { data } = await supabase.auth.getSession();
  const session = data.session;
  if (!session || session.user.email?.toLowerCase() !== ADMIN_EMAIL) {
    showLogin();
    return;
  }
  state.session = session;
  await showApp();
}

async function signIn(event) {
  event.preventDefault();
  const email = el.loginEmail.value.trim().toLowerCase();
  const password = el.loginPassword.value;
  if (email !== ADMIN_EMAIL) {
    el.loginFeedback.textContent = "This admin is allowlisted for Tom only.";
    return;
  }
  el.loginFeedback.textContent = "Signing in...";
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    el.loginFeedback.textContent = error.message;
    return;
  }
  if (data.session?.user.email?.toLowerCase() !== ADMIN_EMAIL) {
    await supabase.auth.signOut();
    el.loginFeedback.textContent = "Signed in user is not allowlisted.";
    return;
  }
  state.session = data.session;
  el.loginPassword.value = "";
  await showApp();
}

async function signOut() {
  await supabase.auth.signOut();
  state.session = null;
  showLogin();
}

function showLogin() {
  el.login.classList.remove("is-hidden");
  el.app.classList.add("is-hidden");
}

async function showApp() {
  el.login.classList.add("is-hidden");
  el.app.classList.remove("is-hidden");
  el.sessionEmail.textContent = state.session?.user.email ?? ADMIN_EMAIL;
  renderNav();
  await loadLiveData();
  populateSystemOptions();
  await loadAuditData();
  await loadAdminData();
  render();
}

async function loadAuditData() {
  const [quizText, taskText] = await Promise.all([
    fetch("/admin-data/quiz-audit.tsv").then((r) => r.text()).catch(() => ""),
    fetch("/admin-data/task-audit.tsv").then((r) => r.text()).catch(() => ""),
  ]);
  state.auditQuestions = parseTsv(quizText).map(questionAuditToItem);
  state.auditTasks = parseTsv(taskText).map(taskAuditToItem);
}

// Phase 4 (Admin Lab v2): load Swift-derived JSON snapshots emitted by
// scripts/export_swift_admin_data.mjs. These are the canonical source for
// the Quiz / Tasks / Routines / Handyman / Systems / Vehicles / Prompts views.
const LIVE_SOURCES = [
  "quiz-questions",
  "templates",
  "system-categories",
  "routine-kinds",
  "handyman-templates",
  "vehicle-task-prompt",
  "edge-function-prompts",
  "quiz-feedback",
  "quiz-mapper-effects",
];

async function loadLiveData() {
  const results = await Promise.all(
    LIVE_SOURCES.map((name) =>
      fetch(`/admin-data/${name}.json`)
        .then((r) => (r.ok ? r.json() : null))
        .catch(() => null)
    )
  );
  state.liveData = Object.fromEntries(
    LIVE_SOURCES.map((name, i) => [name, results[i] || { entries: [] }])
  );
}

function liveItemsForView(viewId) {
  const view = VIEWS.find((v) => v.id === viewId);
  if (!view?.liveSource) return null;
  const src = state.liveData[view.liveSource];
  if (!src) return null;

  const mapper = LIVE_MAPPERS[view.id];
  if (!mapper) return null;

  const entries = src.entries || src.functions || [];
  // Vehicle-task-prompt is a single entity, not an array. Wrap it.
  if (view.id === "vehicles") {
    return [mapper(src, 0)];
  }
  return entries.map((entry, idx) => mapper(entry, idx)).filter(Boolean);
}

const LIVE_MAPPERS = {
  quiz: (q, idx) => ({
    id: `live-quiz-${q.id}`,
    source: "live",
    itemType: "question",
    // Prefix with order number so Tom can scan the actual sequence at
    // a glance. idx comes from the JSON's source order, which mirrors
    // HouseQuizQuestionLibrary.swift declaration order.
    title: `${idx + 1}. ${q.title || q.id}`,
    status: "active",
    category: `${q.chapter || "?"} · ${q.section || "?"}`,
    sortOrder: idx + 1,
    description: q.subtitle || q.fallbackTitle || "",
    payload: q,
    lintCount: (q._lint || []).length,
  }),
  tasks: (t, idx) => ({
    id: `live-task-${slug(t.templateKey)}`,
    source: "live",
    itemType: "task",
    // Title Case for task display — Swift source stays as-is until a
    // change_request lands, but the lab UI reads cleaner this way.
    title: titleCase(t.title),
    status: t.isEssential ? "active" : "draft",
    category: t.systemCategory,
    sortOrder: idx + 1,
    description: t.description || t.notes || "",
    payload: t,
    lintCount: (t._lint || []).length,
  }),
  routines: (r, idx) => ({
    id: `live-routine-${r.rawValue || r.swiftCase}`,
    source: "live",
    itemType: "routine",
    title: titleCase(r.displayLabel || r.rawValue),
    status: "active",
    category: r.isVendorBased ? "Vendor-based" : "Cadence-based",
    sortOrder: idx + 1,
    description: r.seederDefault
      ? `Default cadence ${r.seederDefault.cadenceType || "?"}, active months ${
          (r.seederDefault.activeMonths || []).join(",") || "year-round"
        }`
      : "(no seeder default captured)",
    payload: r,
    lintCount: (r._lint || []).length,
  }),
  handyman: (t, idx) => {
    // Phase 5p — Surface bundle membership clearly so Tom can scan the
    // library and know which items auto-populate vs. which are available
    // for the homeowner / handyman to opt into. Sort order pulls
    // auto-populating bundles to the top: Spring → Fall → Library.
    const bundleSpring = t.bundleId === "Handyman:spring";
    const bundleFall = t.bundleId === "Handyman:fall";
    const isLibrary = !t.bundleId;
    const bucketLabel = bundleSpring
      ? "🌷 Auto-populates Spring punch list"
      : bundleFall
      ? "🍂 Auto-populates Fall punch list"
      : "🛠️ Library — homeowner opt-in";
    const sortBucket = bundleSpring ? 0 : bundleFall ? 1 : 2;
    return {
      id: `live-handyman-${slug(t.templateKey)}`,
      source: "live",
      itemType: "handyman",
      title: titleCase(t.title),
      status: t.isEssential ? "active" : "draft",
      category: bucketLabel,
      // Sort: bundle-spring first, then bundle-fall, then library — and
      // alphabetically within each bucket so the list reads as 3 grouped
      // sections without needing real <h2> dividers.
      sortOrder: sortBucket * 1000 + (titleCase(t.title) || "").charCodeAt(0),
      description: t.description || "",
      payload: { ...t, _autoPopulates: bundleSpring ? "spring" : bundleFall ? "fall" : null, _libraryOnly: isLibrary },
      lintCount: (t._lint || []).length,
    };
  },
  // Phase 5q — Recommended view shares the templates JSON with the
  // Tasks view but filters down to isEssential: false (homeowner opts
  // in). Returning null for essentials skips them via .filter(Boolean)
  // in liveItemsForView.
  recommended: (t, idx) => {
    if (t.isEssential !== false) return null;
    const inHandymanBundle = t.bundleId?.startsWith("Handyman:");
    if (inHandymanBundle) return null; // bundle children belong on the Handyman surface
    const isHandymanLibrary = t.systemCategory === "Handyman" && !t.bundleId;
    const bucket = isHandymanLibrary ? "🛠️ Handyman library" : `✨ ${t.systemCategory}`;
    return {
      id: `live-recommended-${slug(t.templateKey)}`,
      source: "live",
      itemType: "recommended",
      title: titleCase(t.title),
      status: "draft", // never active by default — opt-in only
      category: bucket,
      // Group by bucket (Handyman library first, then alpha by category),
      // alpha within each bucket.
      sortOrder: (isHandymanLibrary ? 0 : 1) * 1000 + (titleCase(t.title) || "").charCodeAt(0),
      description: t.description || t.notes || "",
      payload: { ...t, _isHandymanLibrary: isHandymanLibrary },
      lintCount: (t._lint || []).length,
    };
  },
  systems: (s, idx) => ({
    id: `live-system-${s.categoryKey}`,
    source: "live",
    itemType: "system",
    title: titleCase(s.displayName || s.categoryKey),
    status: s.tier === "universal" ? "active" : s.tier === "conditional" ? "draft" : "defer",
    category: `Tier ${s.tier || "?"}${s.specialtyGroup ? ` · ${s.specialtyGroup}` : ""}`,
    sortOrder: s.displayPriority || idx + 1,
    description: s.defaultCadence ? `Default cadence ${s.defaultCadence}` : "",
    payload: s,
    lintCount: (s._lint || []).length,
  }),
  vehicles: (src) => ({
    id: `live-vehicle-prompt`,
    source: "live",
    itemType: "vehicle",
    title: "vehicle-lookup edge function prompt",
    status: src.sourceExists ? "active" : "draft",
    category: "AI-generated maintenance schedule",
    sortOrder: 1,
    description: src.systemPrompt
      ? `Prompt is ${src.systemPrompt.length} chars. Cached samples: ${(src.cachedSamples || []).length}.`
      : "(prompt not extracted)",
    payload: src,
    lintCount: 0,
  }),
  prompts: (p, idx) => ({
    id: `live-prompt-${p.functionName}`,
    source: "live",
    itemType: "prompt",
    title: p.functionName,
    status: p.systemPrompt ? "active" : "draft",
    category: p.model || "(no model detected)",
    sortOrder: idx + 1,
    description: p.systemPrompt
      ? `${p.systemPrompt.length} char prompt`
      : "(no system prompt found by heuristic)",
    payload: p,
    lintCount: 0,
  }),
};

async function loadAdminData() {
  state.storageMode = "cloud";
  el.storageWarning.hidden = true;
  try {
    const [{ data: items, error: itemError }, { data: notes, error: noteError }] = await Promise.all([
      supabase
        .from("admin_content_items")
        .select("*")
        .order("sort_order", { ascending: true })
        .order("updated_at", { ascending: false }),
      supabase
        .from("admin_codex_notes")
        .select("*")
        .order("created_at", { ascending: false })
        .limit(250),
    ]);
    if (itemError) throw itemError;
    if (noteError) throw noteError;
    state.adminItems = (items ?? []).map(dbItemToUi);
    state.notes = (notes ?? []).map(dbNoteToUi);
  } catch (error) {
    console.warn("[admin] falling back to local draft mode", error);
    state.storageMode = "local";
    el.storageWarning.hidden = false;
    state.adminItems = readLocal(LOCAL_ITEMS_KEY);
    state.notes = readLocal(LOCAL_NOTES_KEY);
  }
}

function parseTsv(text) {
  const lines = text.trim().split(/\r?\n/).filter(Boolean);
  if (lines.length < 2) return [];
  const headers = lines[0].split("\t");
  return lines.slice(1).map((line) => {
    const cols = line.split("\t");
    return Object.fromEntries(headers.map((header, index) => [header, cols[index] ?? ""]));
  });
}

function questionAuditToItem(row) {
  const id = row.ID || `question-${row["#"]}`;
  const disposition = recommendedQuestionDisposition(id);
  return {
    id: `audit-question-${id}`,
    source: "audit",
    itemType: "question",
    title: row.Title || id,
    status: disposition.status,
    category: row.Chapter || row.Section || "Quiz",
    sortOrder: Number(row["#"] || 0),
    description: row.Description || row.Intent || "",
    payload: {
      questionId: id,
      chapter: row.Chapter,
      section: row.Section,
      kind: row.Kind,
      answerOptions: splitPipe(row["Answer Options"]),
      searchMechanic: row["Search Mechanic"],
      intent: cleanEstateLanguage(row.Intent),
      sourceLine: row["Source Line"],
      recommendation: disposition.note,
    },
  };
}

function taskAuditToItem(row, index) {
  const type = classifyTask(row);
  return {
    id: `audit-task-${index + 1}-${slug(row.Category)}-${slug(row.Title)}`,
    source: "audit",
    itemType: "task",
    title: row.Title || "Untitled task",
    status: "active",
    category: row.Category || "Task",
    sortOrder: index + 1,
    description: row.Description || row.Notes || "",
    payload: {
      operationalType: type,
      season: row.Season,
      cadence: row.Frequency,
      priority: row.Priority,
      cost: row.Cost,
      whoHandles: row["Who handles"],
      routingHint: row["Routing hint"],
      safetyFloor: row["Always pro (safety)"] === "true",
      warrantyLinked: row["Warranty-linked"] === "true",
      requiredSubtypes: splitCsv(row["Required subtypes"]),
      bundle: row.Bundle,
      bundleTitle: row["Bundle title"],
      regionalGate: row["Regional gate"],
      notes: row.Notes,
    },
  };
}

function defaultItemsForView(viewId) {
  // Phase 4: Swift-derived JSON wins when available — falls back to legacy
  // TSV / hardcoded defaults so the admin keeps working if the exporter
  // hasn't run yet.
  const live = liveItemsForView(viewId);
  if (live && live.length > 0) return live;
  if (viewId === "quiz") return state.auditQuestions;
  if (viewId === "tasks") return state.auditTasks;
  if (viewId === "routines") {
    return DEFAULT_ROUTINES.map((r, i) => ({
      id: `default-routine-${slug(r[0])}`,
      source: "default",
      itemType: "routine",
      title: r[0],
      status: "active",
      category: "Routine",
      sortOrder: i + 1,
      description: `${r[0]} defaults to ${r[1]}, ${r[2]}, ${r[3]}.`,
      payload: { cadence: r[1], defaultDayTime: r[2], activeMonths: r[3], serviceKey: r[4] },
    }));
  }
  if (viewId === "vendors") {
    return DEFAULT_VENDOR_CATEGORIES.map((v, i) => ({
      id: `default-vendor-${slug(v[0])}`,
      source: "default",
      itemType: "vendor",
      title: v[0],
      status: "active",
      category: "Vendor category",
      sortOrder: i + 1,
      description: v[1],
      payload: { category: v[0], currentBehavior: v[1] },
    }));
  }
  if (viewId === "searches") {
    return DEFAULT_SEARCHES.map((s, i) => ({
      id: `default-search-${slug(s[0])}`,
      source: "default",
      itemType: "search",
      title: s[0],
      status: "active",
      category: "Search",
      sortOrder: i + 1,
      description: s[1],
      payload: { scopes: s[2] },
    }));
  }
  if (viewId === "systems") {
    return DEFAULT_SYSTEMS.map((name, i) => ({
      id: `default-system-${slug(name)}`,
      source: "default",
      itemType: "system",
      title: name,
      status: "active",
      category: "System category",
      sortOrder: i + 1,
      description: `${name} can be created, confirmed, or searched from onboarding/admin flows.`,
      payload: { systemCategory: name },
    }));
  }
  return [];
}

function itemsForCurrentView() {
  if (state.view === "notes") return [];
  const view = currentView();
  const defaults = defaultItemsForView(state.view);
  const drafts = state.adminItems.filter((item) => item.itemType === view.type);
  return [...drafts, ...defaults].sort((a, b) => {
    if ((a.source === "admin") !== (b.source === "admin")) return a.source === "admin" ? -1 : 1;
    return (a.sortOrder ?? 9999) - (b.sortOrder ?? 9999) || a.title.localeCompare(b.title);
  });
}

function render() {
  const view = currentView();
  el.viewEyebrow.textContent = view.eyebrow;
  el.viewTitle.textContent = view.title;
  el.viewSubtitle.textContent = view.subtitle;
  el.search.value = state.search;
  el.statusFilter.value = state.statusFilter;
  el.newItem.textContent = state.view === "notes" ? "Add note" : "Add item";
  renderNav();

  // Phase 4b — Preview-entire-quiz button is only relevant on the quiz view.
  if (el.previewQuiz) {
    if (state.view === "quiz") el.previewQuiz.classList.remove("is-hidden");
    else el.previewQuiz.classList.add("is-hidden");
  }

  if (state.view === "notes") {
    renderNotesView();
  } else if (state.view === "decisions") {
    renderDecisionsView();
  } else if (state.view === "activity") {
    renderActivityView();
  } else if (state.view === "claude_file") {
    renderClaudeFileView();
  } else if (state.view === "architecture") {
    renderArchitectureSurface();
  } else if (state.view === "simulator") {
    renderSimulatorView();
  } else {
    renderList();
    renderDetail();
  }
  renderReadiness();
}

// =============================================================================
// Phase 7 — Reconciler simulator surface
// =============================================================================

function renderSimulatorView() {
  // Phase 5k — Quiz Mode lives on the left rail (presets + chip pickers
  // for system-creating answers + Q15b contractors). Facts Mode is the
  // legacy raw-subtype-toggle view. Toggle in the topbar of the list.
  const modeToggle = `
    <div class="admin-sim__mode-toggle">
      <button type="button" class="admin-sim__mode ${state.simMode === "quiz" ? "is-active" : ""}" data-sim-mode="quiz">Quiz Mode</button>
      <button type="button" class="admin-sim__mode ${state.simMode === "facts" ? "is-active" : ""}" data-sim-mode="facts">Facts Mode (advanced)</button>
    </div>
  `;

  if (state.simMode === "quiz") {
    el.list.innerHTML = `${modeToggle}${renderQuizModeUI(state.simQuizAnswers, state.liveData["quiz-questions"])}`;
    attachQuizModeHandlers(el.list, state.simQuizAnswers, () => {
      runAndRenderSimulation();
    });
  } else {
    el.list.innerHTML = `${modeToggle}${renderFactForm(state.simFacts)}`;
    attachFactFormHandlers(el.list, state.simFacts, () => runAndRenderSimulation());
  }

  el.list.querySelectorAll("[data-sim-mode]").forEach((btn) => {
    btn.addEventListener("click", () => {
      state.simMode = btn.dataset.simMode;
      renderSimulatorView();
    });
  });

  el.emptyDetail.classList.add("is-hidden");
  el.detail.classList.remove("is-hidden");
  // Hide everything in the detail panel that doesn't apply here.
  el.curatedForm?.classList.add("is-hidden");
  if (el.formHost) el.formHost.innerHTML = "";
  if (el.diffHost) el.diffHost.innerHTML = "";
  el.detailKind.textContent = "simulator";
  el.detailTitle.textContent =
    state.simMode === "quiz" ? "What seeds for these quiz answers?" : "What seeds for these facts?";
  el.detailSubtitle.textContent =
    state.simMode === "quiz"
      ? "Pick answers on the left (or load a preset) to see what tasks get created and how they route. The 4-tier breakdown shows who ends up handling each task."
      : "Toggle subtypes directly to test reconciler edge cases.";
  el.detailStatus.textContent = "preview";
  el.detailStatus.dataset.tone = "active";
  if (el.lockToggle) el.lockToggle.classList.add("is-hidden");
  if (el.previewQuestion) el.previewQuestion.classList.add("is-hidden");
  if (el.launchPill) el.launchPill.classList.add("is-hidden");

  // Hide tabs — simulator is a single-pane view.
  if (el.detailTabs) el.detailTabs.classList.add("is-hidden");
  document.querySelectorAll("[data-tab-pane]").forEach((p) => {
    if (p.dataset.tabPane === "edit") {
      p.classList.add("is-active");
      p.removeAttribute("hidden");
    }
  });

  runAndRenderSimulation();
}

function runAndRenderSimulation() {
  const templatesJSON = state.liveData["templates"];
  const systemsJSON = state.liveData["system-categories"];
  if (!templatesJSON?.entries) {
    el.formHost.innerHTML = `<p class="admin-muted">Templates JSON not loaded yet. Run scripts/export_swift_admin_data.mjs and refresh.</p>`;
    return;
  }

  // Phase 5k — when Quiz Mode is active, derive facts from quiz answers
  // (with any preset's factsOverride applied) before running the sim.
  let factsForSim = state.simFacts;
  if (state.simMode === "quiz") {
    // Find a preset whose answers exactly match — used to apply
    // state/yearBuilt/sqft overrides automatically.
    const matchingPreset = QUIZ_PRESETS.find((p) =>
      Object.entries(p.answers).every(([k, v]) => {
        const cur = state.simQuizAnswers[k];
        if (typeof v === "string") return cur === v;
        if (v && typeof v === "object" && v.selectedIds) {
          const curIds = new Set(cur?.selectedIds || []);
          const wantIds = new Set(v.selectedIds);
          if (curIds.size !== wantIds.size) return false;
          for (const x of wantIds) if (!curIds.has(x)) return false;
          return true;
        }
        return false;
      })
    );
    const baseFacts = matchingPreset?.factsOverride
      ? { ...DEFAULT_FACTS, ...matchingPreset.factsOverride, subtypes: {}, hasContractorsFor: {} }
      : { ...DEFAULT_FACTS, subtypes: {}, hasContractorsFor: {} };
    factsForSim = quizAnswerToFacts(state.simQuizAnswers, baseFacts);
  }

  state.simResult = runSimulation(factsForSim, templatesJSON, systemsJSON);
  if (el.formHost) el.formHost.innerHTML = renderSimulatorUI(state.simResult);

  // Stats bar — Tasks / Routines / Punch list / Vendor only / Vendor or Handyman
  const lanes = state.simResult.lanes;
  const allTasks = [...(lanes.bundles || []), ...(lanes.vendor || []), ...(lanes.findContractor || []), ...(lanes.personal || [])];
  const ROUTINE_CATS = new Set(["Landscaping", "Cleaning Service", "Pool/Spa", "Hot Tub", "Pest Control", "Snow Removal", "Mosquito & Tick", "Pet Waste", "Window Cleaning", "Gutter Cleaning", "Trash & Recycling"]);
  // Routine cadences (Tom's rule): weekly / biweekly / monthly / quarterly only.
  // Semi-annual / annual / multi-year are tasks (need explicit coordination).
  const ROUTINE_FREQS = new Set(["Weekly", "Biweekly", "Triweekly", "Monthly", "Bi-monthly", "Quarterly"]);
  const isRoutineCandidate = (t) => {
    if (t.assignmentType === "personal" || t.safetyFloor === true || t.routingOverride === "diyDefault") return false;
    return ROUTINE_CATS.has(t.systemCategory) && ROUTINE_FREQS.has(t.frequency);
  };
  const tierCounts = { routine: 0, vendor_only: 0, vendor_or_handyman: 0, handyman_only: 0 };
  const routineCats = new Set();
  for (const t of allTasks) {
    if (isRoutineCandidate(t)) {
      routineCats.add(t.systemCategory);
      tierCounts.routine++;
    } else if (t.safetyFloor === true || t.routingOverride === "vendorOnly" || (t.assignmentType === "vendor" && !t.routingOverride)) {
      tierCounts.vendor_only++;
    } else if (t.routingOverride === "diyDefault" || t.assignmentType === "personal") {
      tierCounts.handyman_only++;
    } else {
      tierCounts.vendor_or_handyman++;
    }
  }
  const punchTotal = state.simResult.counts.punchList || 0;
  el.stats.innerHTML = `
    <div class="admin-stat"><strong>${state.simResult.counts.total}</strong><span>Tasks</span></div>
    <div class="admin-stat"><strong>${routineCats.size}</strong><span>Routines</span></div>
    <div class="admin-stat"><strong>${punchTotal}</strong><span>Punch list</span></div>
    <div class="admin-stat"><strong>${tierCounts.vendor_only}</strong><span>Vendor only</span></div>
    <div class="admin-stat"><strong>${tierCounts.vendor_or_handyman}</strong><span>Vendor or Handyman</span></div>
  `;

  attachSimulatorJumpHandlers(el.formHost);
}

// Phase 5p — Click any simulator row (task / routine / punch list item /
// bundle child) and jump straight to that entity's detail panel so Tom
// can leave a note in the same spot the proposal needs to land. Handlers
// re-attach on every simulator render.
function attachSimulatorJumpHandlers(host) {
  if (!host) return;

  // Template-key jumps (tasks, handyman items, bundle children, punch list)
  host.querySelectorAll("[data-jump-template-key]").forEach((node) => {
    const key = node.getAttribute("data-jump-template-key");
    if (!key) return;
    node.classList.add("is-clickable");
    node.addEventListener("click", (e) => {
      e.stopPropagation();
      jumpToTemplate(key);
    });
  });

  // Routine-kind jumps (routine cards in the routine section)
  host.querySelectorAll("[data-jump-routine-kind]").forEach((node) => {
    const kind = node.getAttribute("data-jump-routine-kind");
    if (!kind) return;
    node.classList.add("is-clickable");
    node.addEventListener("click", (e) => {
      e.stopPropagation();
      jumpToRoutine(kind);
    });
  });
}

function jumpToTemplate(templateKey) {
  // Match by payload.templateKey since admin.js's live mapper keeps the
  // canonical key in payload. Try Handyman surface first — handyman-
  // templates.json is a filtered subset of templates.json, so any key
  // that lives there is a DIY/bundle entity that belongs in the
  // Handyman view. Tasks surface picks up the rest.
  for (const surfaceId of ["handyman", "tasks"]) {
    const items = liveItemsForView(surfaceId) || [];
    const hit = items.find((i) => i.payload?.templateKey === templateKey);
    if (hit) {
      state.view = surfaceId;
      state.selected = hit;
      state.search = "";
      state.statusFilter = "all";
      state.lifecycleFilter = "all";
      state.seasonFilter = "all";
      state.routingFilter = "all";
      render();
      return;
    }
  }
  console.warn(`[admin] No live item matched templateKey="${templateKey}"`);
}

function jumpToRoutine(kind) {
  // Simulator's kind values like "landscaping", "poolService" should
  // match either rawValue (snake_case: "pool_service") or swiftCase
  // (camelCase: "poolService") on the live routine entry.
  const items = liveItemsForView("routines") || [];
  const hit = items.find(
    (i) => i.payload?.rawValue === kind || i.payload?.swiftCase === kind
  );
  if (hit) {
    state.view = "routines";
    state.selected = hit;
    state.search = "";
    state.statusFilter = "all";
    state.lifecycleFilter = "all";
    state.seasonFilter = "all";
    state.routingFilter = "all";
    render();
    return;
  }
  console.warn(`[admin] No live routine matched kind="${kind}"`);
}

function renderNav() {
  const counts = countByView();
  el.nav.innerHTML = VIEWS.map((view) => `
    <button type="button" class="${state.view === view.id ? "is-active" : ""}" data-view="${escapeHtml(view.id)}">
      <span>${escapeHtml(view.label)}</span>
      <small>${counts[view.id] ?? 0}</small>
    </button>
  `).join("");
  el.nav.querySelectorAll("[data-view]").forEach((button) => {
    button.addEventListener("click", () => {
      state.view = button.dataset.view;
      state.selected = null;
      state.search = "";
      state.statusFilter = "all";
      state.lifecycleFilter = "all";
      state.seasonFilter = "all";
      state.routingFilter = "all";
      render();
    });
  });
}

function renderList() {
  const all = itemsForCurrentView();
  const filtered = filterItems(all);
  renderStats(all, filtered);
  const facets = renderFacetPills(all);
  el.list.innerHTML = (facets ? facets : "") + (filtered.map((item) => itemRowHtml(item)).join("") || emptyListHtml());
  attachFacetPillHandlers(el.list);
  el.list.querySelectorAll("[data-item-id]").forEach((button) => {
    button.addEventListener("click", () => {
      state.selected = all.find((item) => item.id === button.dataset.itemId) ?? null;
      renderList();
      renderDetail();
    });
  });
}

// Phase 5q — Facet pill rows for Tasks / Handyman / Recommended.
// Three filter axes (lifecycle / season / routing) with explainer
// captions so the labels aren't bare nouns. Layout uses a 2-column
// grid: fixed-width label + caption on the left, wrapping pill row on
// the right, so pills always start at the same x and never wrap into
// the label column.
function renderFacetPills(allItems) {
  if (!["tasks", "handyman", "recommended"].includes(state.view)) return "";
  // Compute counts on the FULL view so pill counts stay stable across
  // filter selections — same UX as Apple Mail / Linear.
  const lifecycleCounts = countByLifecycle(allItems);
  const seasonCounts = countBySeason(allItems);
  const routingCounts = countByRouting(allItems);

  const pill = (axis, value, label, count, title = "") => {
    if (count === 0 && value !== "all") return "";
    const isActive = state[`${axis}Filter`] === value;
    return `<button type="button" class="admin-facet-pill ${isActive ? "is-active" : ""}" data-facet-axis="${escapeHtml(axis)}" data-facet-value="${escapeHtml(value)}" ${title ? `title="${escapeHtml(title)}"` : ""}>
      <span class="admin-facet-pill__label">${label}</span>
      <span class="admin-facet-pill__count">${count}</span>
    </button>`;
  };

  const axisRow = (label, caption, pillsHtml) => `
    <div class="admin-facet-row">
      <div class="admin-facet-row__head">
        <span class="admin-facet-row__label">${escapeHtml(label)}</span>
        <span class="admin-facet-row__caption admin-muted">${caption}</span>
      </div>
      <div class="admin-facet-row__pills">${pillsHtml}</div>
    </div>
  `;

  return `
    <div class="admin-facets">
      ${axisRow(
        "Lifecycle",
        "When does this template enter the homeowner's task list?",
        [
          pill("lifecycle", "all", "All", allItems.length),
          pill("lifecycle", "auto_seed", "Auto-seeds", lifecycleCounts.auto_seed, "Fires automatically the moment the homeowner finishes the quiz. No homeowner action required."),
          pill("lifecycle", "opt_in", "Opt-in", lifecycleCounts.opt_in, "Never seeds automatically. Homeowner adds it from Recommended Services or the handyman punch list 'Recommended' section."),
          pill("lifecycle", "bundle_child", `Bundle child (${lifecycleCounts.bundle_parent} bundles)`, lifecycleCounts.bundle_child, `Never gets its own task row. Rolls up into one of ${lifecycleCounts.bundle_parent} parent visits (e.g. Spring Landscaping Service, Pool Opening Service). Click to see children grouped by bundle.`),
        ].join("")
      )}
      ${axisRow(
        "Season",
        "When during the year is this typically scheduled?",
        [
          pill("season", "all", "All", allItems.length),
          pill("season", "Spring", "🌷 Spring", seasonCounts.Spring, "Mar–May. Opening tasks: HVAC cooling tune-up, irrigation startup, pool open, mulching, gutter cleaning."),
          pill("season", "Summer", "☀️ Summer", seasonCounts.Summer, "Jun–Aug. Warm-weather work: exterior painting, deck staining, hardscape repairs."),
          pill("season", "Fall", "🍂 Fall", seasonCounts.Fall, "Sep–Nov. Winterization: HVAC heating tune-up, boiler service, chimney sweep, snow plow contract."),
          pill("season", "Winter", "❄️ Winter", seasonCounts.Winter, "Dec–Feb. Cold-weather indoor projects + dormant tree pruning."),
          pill("season", "Spring/Fall", "🔁 Spring/Fall", seasonCounts["Spring/Fall"], "Twice-a-year cadence — runs at both seasonal anchors."),
          pill("season", "year_round", "🔄 Year-round", seasonCounts.year_round, "No seasonal anchor. Homeowner schedules whenever convenient."),
        ].join("")
      )}
      ${axisRow(
        "Routing",
        "Who handles this by default?",
        [
          pill("routing", "all", "All", allItems.length),
          pill("routing", "vendor", "Vendor", routingCounts.vendor, "Always a pro — gas, panel, roof, septic, generator. Homeowner can't safely take this on."),
          pill("routing", "vendor_or_handyman", "Vendor or Handyman", routingCounts.vendor_or_handyman, "Defaults to a vendor visit, but the handyman can knock it out on a punch-list visit too."),
          pill("routing", "handyman", "Handyman", routingCounts.handyman, "Punch-list items the handyman tackles. Homeowner can still pull any of these into 'I'll do it myself' if they want."),
          pill("routing", "homeowner_pull", "I'll do it myself", routingCounts.homeowner_pull, "Always 0 by default. Only populates when the homeowner explicitly pulls a task off another routing lane."),
          pill("routing", "routine", "Routines", routingCounts.routine, "Recurring vendor work (landscaping, cleaning, pool service, pest control) that gets extracted into a Routine card instead of a one-off task."),
        ].join("")
      )}
    </div>
  `;
}

function attachFacetPillHandlers(host) {
  host.querySelectorAll("[data-facet-axis]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const axis = btn.dataset.facetAxis;
      const value = btn.dataset.facetValue;
      state[`${axis}Filter`] = value;
      renderList();
    });
  });
}

function lifecycleOf(item) {
  const t = item.payload || {};
  if (t.bundleId) return "bundle_child";
  if (t.isEssential === false) return "opt_in";
  return "auto_seed";
}

function countByLifecycle(items) {
  const out = { auto_seed: 0, opt_in: 0, bundle_child: 0, bundle_parent: 0 };
  const bundleSizes = new Map();
  for (const i of items) {
    if (i.payload?.bundleId) {
      bundleSizes.set(i.payload.bundleId, (bundleSizes.get(i.payload.bundleId) || 0) + 1);
    }
    out[lifecycleOf(i)]++;
  }
  // bundle_parent count = number of distinct bundleIds with 2+ children.
  for (const size of bundleSizes.values()) if (size >= 2) out.bundle_parent++;
  return out;
}

function countBySeason(items) {
  const out = { Spring: 0, Summer: 0, Fall: 0, Winter: 0, "Spring/Fall": 0, year_round: 0 };
  for (const i of items) {
    const s = i.payload?.seasonalTiming;
    if (!s) out.year_round++;
    else if (out[s] !== undefined) out[s]++;
    else out.year_round++;
  }
  return out;
}

// Phase 5q — Routine-eligible categories + cadences. Mirrors the
// simulator's SIM_ROUTINE_CATEGORIES + SIM_ROUTINE_FREQUENCIES so the
// admin's "Routines" routing filter shows the same templates the
// reconciler would extract into a routine card at runtime.
const ADMIN_ROUTINE_CATEGORIES = new Set([
  "Landscaping", "Cleaning Service", "Pool/Spa", "Hot Tub",
  "Pest Control", "Snow Removal", "Mosquito & Tick", "Pet Waste",
  "Window Cleaning", "Gutter Cleaning", "Trash & Recycling",
]);
const ADMIN_ROUTINE_FREQUENCIES = new Set([
  "Weekly", "Biweekly", "Triweekly", "Monthly", "Bi-monthly", "Quarterly",
]);

function isRoutineCandidate(t) {
  if (!t) return false;
  if (t.assignmentType === "personal") return false;
  if (t.safetyFloor === true) return false;
  if (t.routingOverride === "diyDefault") return false;
  if (!ADMIN_ROUTINE_FREQUENCIES.has(t.frequency)) return false;
  if (!ADMIN_ROUTINE_CATEGORIES.has(t.systemCategory)) return false;
  return true;
}

// Phase 5q — Re-mapped routing taxonomy per Tom: drop "DIY" nomenclature
// (homeowners don't DIY by default; "I'll do it myself" is a runtime pull
// only). Add "Routines" as a first-class lane for recurring vendor work.
//
// Routing categories:
//   vendor             — always a pro (safetyFloor, gas, panel, roof, septic)
//   vendor_or_handyman — defaults to vendor, handyman can also tackle
//   handyman           — punch-list items the handyman handles
//   homeowner_pull     — never the default (always 0); only set when the
//                        homeowner explicitly pulls a task to themselves
//   routine            — recurring vendor work that gets routine-extracted
function routingOf(item) {
  const t = item.payload || {};
  // Routines take priority over the underlying assignmentType — recurring
  // vendor work surfaces as a routine even if the template ships as
  // `vendorDefault`. Mirrors simIsRoutineCandidate in admin-simulator.js.
  if (isRoutineCandidate(t)) return "routine";
  // Bundle children inherit routing from the synthesized bundle parent.
  // For filtering purposes, treat them as part of their bundle's routing
  // lane (most bundles end up vendor_or_handyman or vendor).
  if (t.bundleId) {
    if (t.safetyFloor === true) return "vendor";
    if (t.routingOverride === "vendorOnly") return "vendor";
    if (t.assignmentType === "vendor") return "vendor";
    return "vendor_or_handyman";
  }
  if (t.safetyFloor === true) return "vendor";
  if (t.routingOverride === "vendorOnly") return "vendor";
  if (t.assignmentType === "vendor" && !t.routingOverride) return "vendor";
  if (t.routingOverride === "diyDefault" || t.routingOverride === "diyCapable") return "handyman";
  if (t.assignmentType === "personal") return "handyman";
  return "vendor_or_handyman";
}

function countByRouting(items) {
  const out = { vendor: 0, vendor_or_handyman: 0, handyman: 0, homeowner_pull: 0, routine: 0 };
  for (const i of items) out[routingOf(i)]++;
  return out;
}

function renderStats(all, filtered) {
  const active = all.filter((item) => item.status === "active").length;
  const cuts = all.filter((item) => item.status === "cut" || item.status === "defer").length;
  el.stats.innerHTML = `
    <div class="admin-stat"><strong>${all.length}</strong><span>Total</span></div>
    <div class="admin-stat"><strong>${active}</strong><span>Active</span></div>
    <div class="admin-stat"><strong>${filtered.length}</strong><span>Visible</span></div>
  `;
  if (cuts > 0 && state.view === "quiz") {
    el.stats.innerHTML += `<div class="admin-stat"><strong>${cuts}</strong><span>Cut/defer</span></div>`;
  }
}

function renderDetail() {
  // Re-show the tabs strip in case the simulator view hid it on the
  // previous render.
  el.detailTabs?.classList.remove("is-hidden");

  const item = state.selected;
  if (!item) {
    el.emptyDetail.classList.remove("is-hidden");
    el.detail.classList.add("is-hidden");
    resetEditingState();
    return;
  }
  el.emptyDetail.classList.add("is-hidden");
  el.detail.classList.remove("is-hidden");
  el.detailKind.textContent = `${item.source} ${item.itemType}`;
  el.detailTitle.textContent = item.title;
  el.detailSubtitle.textContent = [item.category, item.payload?.questionId, item.payload?.operationalType, item.payload?.cadence]
    .filter(Boolean)
    .join(" · ");
  el.detailStatus.textContent = item.status;
  el.detailStatus.dataset.tone = item.status;

  // Phase 4b — branch on whether this surface has a structured schema.
  const viewId = state.view;
  const schema = SCHEMAS[viewId];
  const hasLiveSchema = !!schema && item.source === "live";

  // Toggle preview-question button on quiz only.
  if (el.previewQuestion) {
    if (item.itemType === "question") el.previewQuestion.classList.remove("is-hidden");
    else el.previewQuestion.classList.add("is-hidden");
  }

  if (hasLiveSchema) {
    // Hide curated/legacy form. Render schema-driven form into formHost.
    el.curatedForm?.classList.add("is-hidden");
    if (el.formHost) {
      // Deep-clone payload into editing state so inline edits don't mutate
      // the cached liveData rendering. Original stays pristine for diff.
      editingState.viewId = viewId;
      editingState.original = structuredCloneSafe(item.payload ?? {});
      editingState.current = structuredCloneSafe(item.payload ?? {});
      el.formHost.innerHTML = renderEntityForm(viewId, editingState.current, editingState.original);
      attachFormHandlers(el.formHost, viewId, editingState.original, editingState.current, () => {
        renderDiff();
      });
    }
    renderDiff();
    el.saveItem.textContent = "Save proposed change";
    el.promoteItem.disabled = true;
    // Phase 5 — duplicate works on live entities as a proposal_add note.
    el.duplicateItem.disabled = false;
    el.duplicateItem.textContent = "Clone as proposal";
    el.deleteItem.disabled = true;
  } else {
    // Curated / legacy mode — keep original form behavior.
    el.curatedForm?.classList.remove("is-hidden");
    if (el.formHost) el.formHost.innerHTML = "";
    if (el.diffHost) el.diffHost.innerHTML = "";
    resetEditingState();
    el.fieldTitle.value = item.title ?? "";
    el.fieldStatus.value = item.status ?? "draft";
    el.fieldCategory.value = item.category ?? "";
    el.fieldSort.value = String(item.sortOrder ?? 0);
    el.fieldDescription.value = item.description ?? "";
    if (el.fieldPayload) el.fieldPayload.value = JSON.stringify(item.payload ?? {}, null, 2);
    el.saveItem.textContent = "Save item";
    el.promoteItem.disabled = item.source === "admin";
    el.duplicateItem.disabled = false;
    el.duplicateItem.textContent = "Duplicate";
    el.deleteItem.disabled = item.source !== "admin";
  }

  // Phase 7.5 — launch lifecycle pill + lock toggle label
  const launch = effectiveLaunchStatus(item);
  if (el.launchPill) {
    if (launch && launch !== "draft") {
      el.launchPill.textContent = launch;
      el.launchPill.dataset.tone = launch;
      el.launchPill.classList.remove("is-hidden");
    } else {
      el.launchPill.classList.add("is-hidden");
    }
  }
  if (el.lockToggle) {
    if (item.itemType === "decision" || item.itemType === "activity" || item.itemType === "note") {
      el.lockToggle.classList.add("is-hidden");
    } else {
      el.lockToggle.classList.remove("is-hidden");
      el.lockToggle.textContent = launch === "approved" ? "Unlock" : "Lock as approved";
      el.lockToggle.classList.toggle("admin-button--locked", launch === "approved");
    }
  }

  el.contextNote.value = "";
  renderContextNotes(item);
  el.saveNote.textContent = "Save note";

  // Phase 4b — reset to Edit tab whenever the selection changes; clear
  // cached usage stats only if the entity changed.
  const cacheKey = entityCacheKey(item);
  if (cacheKey !== TAB_STATE.lastEntityKey) {
    TAB_STATE.lastEntityKey = cacheKey;
    switchDetailTab("edit");
  } else {
    if (TAB_STATE.active === "impact") renderImpactTab();
    if (TAB_STATE.active === "usage") renderUsageTab();
  }
}

// Phase 7.5 — show "X of Y approved" + progress bar in the topbar for
// surfaces where it makes sense (live entities — Quiz/Tasks/Routines/etc.)
function renderReadiness() {
  if (!el.readinessPill) return;
  const surfaces = ["quiz", "tasks", "routines", "handyman", "systems", "vehicles", "prompts"];
  if (!surfaces.includes(state.view)) {
    el.readinessPill.classList.add("is-hidden");
    return;
  }
  const items = itemsForCurrentView().filter((i) => i.source === "live");
  const total = items.length;
  const approved = items.filter((i) => effectiveLaunchStatus(i) === "approved").length;
  const pct = total ? Math.round((approved / total) * 100) : 0;
  el.readinessPill.classList.remove("is-hidden");
  el.readinessCount.textContent = `${approved} / ${total} approved · ${pct}%`;
  el.readinessBar.style.width = `${pct}%`;
  el.readinessHint.textContent = approved === total
    ? "Surface ready to ship."
    : `${total - approved} entities still need your call.`;
}

// =============================================================================
// Phase 4b — Detail panel tabs (Edit / Impact / Usage)
// =============================================================================

const TAB_STATE = { active: "edit", lastEntityKey: null, usageCache: new Map() };

function switchDetailTab(tabId) {
  if (!tabId) return;
  TAB_STATE.active = tabId;
  el.detailTabs?.querySelectorAll("[data-detail-tab]").forEach((btn) => {
    btn.classList.toggle("is-active", btn.dataset.detailTab === tabId);
  });
  document.querySelectorAll("[data-tab-pane]").forEach((pane) => {
    const match = pane.dataset.tabPane === tabId;
    pane.classList.toggle("is-active", match);
    if (match) pane.removeAttribute("hidden");
    else pane.setAttribute("hidden", "");
  });
  if (tabId === "impact") renderImpactTab();
  if (tabId === "usage") renderUsageTab();
}

function entityCacheKey(item) {
  if (!item) return null;
  return `${item.itemType}::${liveEntityIdFor(item)}`;
}

// -- Impact tab -------------------------------------------------------------
// Renders cross-entity references baked into _impact at export time.

function renderImpactTab() {
  if (!el.impactHost) return;
  const item = state.selected;
  if (!item) {
    el.impactHost.innerHTML = `<p class="admin-muted">Select an entity to see what depends on it.</p>`;
    return;
  }
  const p = item.payload || {};
  const impact = p._impact || {};
  const sections = [];

  if (item.itemType === "question") {
    if (impact.creates_systems?.length) {
      sections.push(impactSection("Creates systems", impact.creates_systems.map((s) => ({ label: s, hint: "home_systems.category" }))));
    }
    if (impact.unlocks_templates?.length) {
      sections.push(impactSection("Unlocks templates", impact.unlocks_templates.map((s) => ({ label: s }))));
    }
    if (impact.gates_questions?.length) {
      sections.push(impactSection("Gates these questions via dynamicSkip", impact.gates_questions.map((s) => ({ label: s }))));
    }
    // Heuristic — find templates whose requiredSubtypes mention answer ids
    const tmplLinked = templatesGatedByQuestion(item);
    if (tmplLinked.length) {
      sections.push(impactSection(`Templates that may gate on this Q's answer IDs (${tmplLinked.length})`, tmplLinked.map((t) => ({ label: t.title, hint: t.systemCategory, navTo: { view: "tasks", id: t.templateKey } }))));
    }
  } else if (item.itemType === "task" || item.itemType === "handyman") {
    const meta = impact.system_category_meta;
    if (meta) {
      sections.push(impactSection("System category", [{ label: meta.categoryKey, hint: `Tier ${meta.tier} · priority ${meta.displayPriority}`, navTo: { view: "systems", id: meta.categoryKey } }]));
    }
    if (impact.in_bundle) {
      sections.push(impactSection(`Bundle: ${impact.in_bundle.bundleId}${impact.in_bundle.bundleTitle ? " — " + impact.in_bundle.bundleTitle : ""}`, (impact.in_bundle.siblings || []).map((s) => ({ label: s, hint: "sibling template" }))));
    }
    const matchingQ = questionsCreatingCategory(p.systemCategory);
    if (matchingQ.length) {
      sections.push(impactSection("Quiz questions that create this system", matchingQ.map((q) => ({ label: q.id, hint: q.title, navTo: { view: "quiz", id: q.id } }))));
    }
  } else if (item.itemType === "system") {
    if (impact.templates_in_category?.length) {
      sections.push(impactSection(`${impact.templates_in_category.length} templates in this category`, impact.templates_in_category.map((k) => ({ label: k, navTo: { view: "tasks", id: k } }))));
    }
    if (impact.created_by_questions?.length) {
      sections.push(impactSection("Created by these quiz questions", impact.created_by_questions.map((q) => ({ label: q, navTo: { view: "quiz", id: q } }))));
    } else {
      const matchingQ = questionsCreatingCategory(p.categoryKey);
      if (matchingQ.length) {
        sections.push(impactSection("Created by these quiz questions", matchingQ.map((q) => ({ label: q.id, hint: q.title, navTo: { view: "quiz", id: q.id } }))));
      }
    }
  } else if (item.itemType === "routine") {
    if (impact.categories_served?.length) {
      sections.push(impactSection("System categories served", impact.categories_served.map((c) => ({ label: c, navTo: { view: "systems", id: c } }))));
    }
    if (impact.handyman_singleton) {
      sections.push(impactSection("Special status", [{ label: "Singleton — one active handyman routine per property" }]));
    }
  }

  // Always-on lint summary
  const lints = p._lint || [];
  if (lints.length) {
    sections.push(`
      <section class="admin-impact__section admin-impact__section--lint">
        <h4>Voice lint warnings (${lints.length})</h4>
        <ul>
          ${lints.map((l) => `<li><code>${escapeHtml(l.ruleId)}</code> on ${escapeHtml(l.field)} — ${escapeHtml(l.message)}<br/><small>${escapeHtml(l.snippet || "")}</small></li>`).join("")}
        </ul>
      </section>
    `);
  }

  // Notes summary
  const noteCount = state.notes.filter((n) => itemNoteMatches(n, item)).length;
  sections.push(`
    <section class="admin-impact__section">
      <h4>Notes on this entity</h4>
      <p class="admin-muted">${noteCount} note${noteCount === 1 ? "" : "s"} captured. Switch to the Edit tab to read or add.</p>
    </section>
  `);

  el.impactHost.innerHTML = sections.length
    ? sections.join("")
    : `<p class="admin-muted">No cross-entity impact captured for this entity yet. The exporter's backreference pass is heuristic — v2 will deepen the graph.</p>`;

  // Wire navTo links
  el.impactHost.querySelectorAll("[data-nav-to]").forEach((node) => {
    node.addEventListener("click", () => {
      const view = node.dataset.navTo;
      const id = node.dataset.navId;
      jumpToEntity(view, id);
    });
  });
}

function impactSection(title, items) {
  return `
    <section class="admin-impact__section">
      <h4>${escapeHtml(title)}</h4>
      <ul class="admin-impact__list">
        ${items
          .map(
            (it) => `
              <li>
                <span class="admin-impact__label" ${it.navTo ? `data-nav-to="${escapeHtml(it.navTo.view)}" data-nav-id="${escapeHtml(it.navTo.id)}"` : ""}>${escapeHtml(it.label)}</span>
                ${it.hint ? `<span class="admin-impact__hint">${escapeHtml(it.hint)}</span>` : ""}
              </li>
            `
          )
          .join("")}
      </ul>
    </section>
  `;
}

function templatesGatedByQuestion(question) {
  const answerIds = (question.payload?.answerOptions || []).map((o) => o.id).filter(Boolean);
  if (!answerIds.length) return [];
  const templates = state.liveData["templates"]?.entries || [];
  const matched = [];
  for (const t of templates) {
    const subs = t.requiredSubtypes || [];
    if (subs.some((s) => answerIds.includes(s))) matched.push(t);
    if (matched.length >= 30) break;
  }
  return matched;
}

function questionsCreatingCategory(categoryKey) {
  if (!categoryKey) return [];
  const questions = state.liveData["quiz-questions"]?.entries || [];
  return questions.filter((q) => (q._impact?.creates_systems || []).includes(categoryKey));
}

function jumpToEntity(view, id) {
  if (!view || !id) return;
  state.view = view;
  const items = liveItemsForView(view) || [];
  const target = items.find((i) =>
    [i.payload?.id, i.payload?.templateKey, i.payload?.categoryKey, i.payload?.functionName, i.payload?.rawValue]
      .filter(Boolean)
      .includes(id)
  );
  if (target) state.selected = target;
  TAB_STATE.active = "edit";
  render();
}

// -- Usage tab --------------------------------------------------------------
// Lazy-fetches the matching admin_*_stats RPC for the current entity.

async function renderUsageTab() {
  if (!el.usageHost) return;
  const item = state.selected;
  if (!item) {
    el.usageHost.innerHTML = `<p class="admin-muted">Select an entity to see live usage stats.</p>`;
    return;
  }
  const cacheKey = entityCacheKey(item);
  if (TAB_STATE.usageCache.has(cacheKey)) {
    renderUsageStats(TAB_STATE.usageCache.get(cacheKey), item);
    return;
  }
  el.usageHost.innerHTML = `<p class="admin-muted">Loading live stats from production…</p>`;
  try {
    const stats = await fetchUsageStats(item);
    TAB_STATE.usageCache.set(cacheKey, stats);
    renderUsageStats(stats, item);
  } catch (err) {
    el.usageHost.innerHTML = `<p class="admin-muted">Stats unavailable: ${escapeHtml(err.message || String(err))}</p>`;
  }
}

async function fetchUsageStats(item) {
  const liveId = liveEntityIdFor(item);
  if (item.itemType === "question") {
    const { data, error } = await supabase.rpc("admin_quiz_question_stats", { p_question_id: liveId });
    if (error) throw error;
    return { kind: "question", data };
  }
  if (item.itemType === "task" || item.itemType === "handyman") {
    const { data, error } = await supabase.rpc("admin_template_stats", { p_template_key: liveId });
    if (error) throw error;
    return { kind: "template", data };
  }
  if (item.itemType === "system") {
    const { data, error } = await supabase.rpc("admin_system_category_stats", { p_category_key: liveId });
    if (error) throw error;
    return { kind: "system", data };
  }
  if (item.itemType === "routine") {
    const { data, error } = await supabase.rpc("admin_routine_kind_stats", { p_kind: liveId });
    if (error) throw error;
    return { kind: "routine", data };
  }
  return { kind: "none", data: null };
}

function renderUsageStats(stats, item) {
  if (!el.usageHost) return;
  if (!stats || stats.kind === "none") {
    el.usageHost.innerHTML = `<p class="admin-muted">No usage stats are tracked for ${escapeHtml(item.itemType)} entities.</p>`;
    return;
  }
  const d = stats.data || {};

  if (stats.kind === "question") {
    const dist = d.distribution || {};
    const distItems = Object.entries(dist)
      .sort((a, b) => b[1] - a[1])
      .map(([k, n]) => `<li><code>${escapeHtml(k)}</code> <strong>${n}</strong></li>`)
      .join("");
    el.usageHost.innerHTML = `
      <div class="admin-usage">
        <div class="admin-usage__row">
          ${statTile("Quiz starts", d.started_count)}
          ${statTile("Quiz completions", d.completed_count)}
          ${statTile("Answered this Q", d.answered_count)}
          ${statTile("Drop-off rate", d.drop_off_rate != null ? `${Math.round(d.drop_off_rate * 100)}%` : "—")}
        </div>
        <h4>Answer distribution</h4>
        <ul class="admin-usage__list">${distItems || `<li class="admin-muted">No answers recorded yet.</li>`}</ul>
        ${recommendationFor(stats, item)}
      </div>
    `;
    return;
  }

  if (stats.kind === "template") {
    el.usageHost.innerHTML = `
      <div class="admin-usage">
        <div class="admin-usage__row">
          ${statTile("Seeded", d.seeded_count)}
          ${statTile("Completed", d.completed_count)}
          ${statTile("Archived", d.archived_count)}
          ${statTile("Overdue", d.overdue_count)}
        </div>
        <div class="admin-usage__row">
          ${statTile("Distinct properties", d.distinct_properties)}
          ${statTile("Completion rate", d.completion_rate != null ? `${Math.round(d.completion_rate * 100)}%` : "—")}
          ${statTile("Archive rate", d.archive_rate != null ? `${Math.round(d.archive_rate * 100)}%` : "—")}
        </div>
        ${recommendationFor(stats, item)}
      </div>
    `;
    return;
  }

  if (stats.kind === "system") {
    el.usageHost.innerHTML = `
      <div class="admin-usage">
        <div class="admin-usage__row">
          ${statTile("Properties carrying", d.property_count)}
          ${statTile("With vendor linked", d.with_vendor_count)}
          ${statTile("With open task", d.with_open_task_count)}
          ${statTile("Vendor coverage rate", d.vendor_coverage_rate != null ? `${Math.round(d.vendor_coverage_rate * 100)}%` : "—")}
        </div>
        ${recommendationFor(stats, item)}
      </div>
    `;
    return;
  }

  if (stats.kind === "routine") {
    el.usageHost.innerHTML = `
      <div class="admin-usage">
        <div class="admin-usage__row">
          ${statTile("Active routines", d.active_count)}
          ${statTile("Paused", d.paused_count)}
          ${statTile("Archived", d.archived_count)}
          ${statTile("Avg confidence", d.avg_confidence_score != null ? d.avg_confidence_score : "—")}
        </div>
        ${recommendationFor(stats, item)}
      </div>
    `;
    return;
  }
}

function statTile(label, value) {
  return `
    <div class="admin-stat-tile">
      <strong>${escapeHtml(value == null ? "—" : String(value))}</strong>
      <span>${escapeHtml(label)}</span>
    </div>
  `;
}

// Heuristic recommendation given stats — keep / rewrite / cut / investigate.
function recommendationFor(stats, item) {
  const d = stats?.data || {};
  let level = "keep";
  let reason = "Looks healthy.";
  if (stats.kind === "question") {
    if (d.started_count >= 10 && d.drop_off_rate != null && d.drop_off_rate > 0.25) {
      level = "rewrite";
      reason = `${Math.round(d.drop_off_rate * 100)}% drop-off across ${d.started_count} starts. Copy or skip rule may be failing.`;
    } else if (d.answered_count === 0 && d.started_count >= 10) {
      level = "cut";
      reason = `Zero answers across ${d.started_count} quiz starts. Strong cut candidate.`;
    } else if (d.started_count < 10) {
      level = "n/a";
      reason = "Too new to call (fewer than 10 quiz starts).";
    }
  } else if (stats.kind === "template") {
    if (d.seeded_count >= 10 && (d.completion_rate || 0) < 0.05) {
      level = "cut";
      reason = `${Math.round((d.completion_rate || 0) * 100)}% completion across ${d.seeded_count} seedings. Strong cut candidate.`;
    } else if (d.seeded_count >= 10 && (d.archive_rate || 0) > 0.4) {
      level = "rewrite";
      reason = `${Math.round((d.archive_rate || 0) * 100)}% archive rate. Users keep dismissing this — copy or relevance issue.`;
    } else if (d.seeded_count < 10) {
      level = "n/a";
      reason = "Too new to call (fewer than 10 seedings).";
    }
  } else if (stats.kind === "system") {
    if (d.property_count >= 10 && (d.vendor_coverage_rate || 0) < 0.1) {
      level = "investigate";
      reason = `Only ${Math.round((d.vendor_coverage_rate || 0) * 100)}% of properties have a vendor for this. Quiz/contractor flow may be missing this category.`;
    } else if (d.property_count < 10) {
      level = "n/a";
      reason = "Too new to call.";
    }
  }
  const tone = { keep: "active", rewrite: "reshape", cut: "cut", investigate: "defer", "n/a": "draft" }[level] || "draft";
  return `
    <div class="admin-usage__recommendation" data-tone="${tone}">
      <strong>Recommendation: ${escapeHtml(level)}</strong>
      <p>${escapeHtml(reason)}</p>
    </div>
  `;
}

function resetEditingState() {
  editingState.viewId = null;
  editingState.original = null;
  editingState.current = null;
}

function renderDiff() {
  if (!el.diffHost) return;
  if (!editingState.viewId) {
    el.diffHost.innerHTML = "";
    return;
  }
  const diff = computeProposedDiff(editingState.viewId, editingState.original, editingState.current);
  el.diffHost.innerHTML = renderDiffStrip(diff, SCHEMAS[editingState.viewId]);
  // Highlight save button when changes exist
  if (Object.keys(diff).length > 0) {
    el.saveItem.classList.add("admin-button--has-changes");
  } else {
    el.saveItem.classList.remove("admin-button--has-changes");
  }
}

// =============================================================================
// Phase 7.5 — Decisions queue
// =============================================================================
// Auto-flagged entities awaiting Tom's call. Rules:
//   - Live entities not yet approved AND with high impact (large bundle,
//     gates other questions, or template count > 5 in category)
//   - Entities with lint hits AND launch_status != approved
//   - Entities with question_for_claude notes pending
//   - Entities with change_request notes pending application
// Each row gets one-click Approve / Cut / Open buttons so the tab can be
// burned through quickly.

function renderDecisionsView() {
  const decisions = computeDecisionQueue();
  el.search.value = state.search || "";

  el.stats.innerHTML = `
    <div class="admin-stat"><strong>${decisions.length}</strong><span>Awaiting your call</span></div>
    <div class="admin-stat"><strong>${decisions.filter((d) => d.severity === "lint").length}</strong><span>Lint</span></div>
    <div class="admin-stat"><strong>${decisions.filter((d) => d.severity === "question").length}</strong><span>Questions</span></div>
    <div class="admin-stat"><strong>${decisions.filter((d) => d.severity === "proposal").length}</strong><span>Proposals</span></div>
  `;

  const filtered = state.search
    ? decisions.filter((d) =>
        [d.title, d.reason, d.itemType].join(" ").toLowerCase().includes(state.search.toLowerCase())
      )
    : decisions;

  el.list.innerHTML = filtered.length
    ? filtered.map((d) => decisionRowHtml(d)).join("")
    : `<div class="admin-empty-detail" style="min-height:240px"><h3>No decisions waiting</h3><p>Surfaces are clean. Move to Quiz or Tasks for active curation.</p></div>`;

  el.list.querySelectorAll("[data-decision-action]").forEach((btn) => {
    btn.addEventListener("click", async (event) => {
      event.stopPropagation();
      const decisionId = btn.closest("[data-decision-id]")?.dataset.decisionId;
      const action = btn.dataset.decisionAction;
      const decision = decisions.find((d) => d.id === decisionId);
      if (!decision) return;
      await handleDecisionAction(decision, action);
    });
  });
  el.list.querySelectorAll("[data-decision-id][data-open-detail]").forEach((row) => {
    row.addEventListener("click", () => {
      const decisionId = row.dataset.decisionId;
      const decision = decisions.find((d) => d.id === decisionId);
      if (!decision?.targetItem) return;
      // Jump to the entity's home surface.
      state.view = decision.targetView;
      state.selected = decision.targetItem;
      render();
    });
  });

  el.emptyDetail.classList.add("is-hidden");
  el.detail.classList.add("is-hidden");
}

function computeDecisionQueue() {
  const queue = [];
  const surfaces = ["quiz", "tasks", "routines", "handyman", "systems", "vehicles", "prompts"];

  // 1. question_for_claude pending notes — top priority
  for (const note of state.notes) {
    if (note.intent === "question_for_claude" && !note.appliedAt) {
      queue.push({
        id: `q4c-${note.id}`,
        severity: "question",
        title: `${note.scopeTitle || "Open question"}`,
        reason: note.body?.slice(0, 200) || "(no body)",
        itemType: note.scopeType,
        targetView: viewIdForType(note.scopeType),
        targetItem: locateLiveItemByScope(note),
        recommendation: "Answer first — Tom is waiting on you.",
        primaryActions: ["open"],
      });
    }
  }

  // 2. Pending change_request / proposal_* notes
  for (const note of state.notes) {
    if (
      ["change_request", "proposal_add", "proposal_delete"].includes(note.intent) &&
      !note.appliedAt &&
      !note.revertedAt
    ) {
      queue.push({
        id: `proposal-${note.id}`,
        severity: "proposal",
        title: `${note.intent}: ${note.scopeTitle || "(unscoped)"}`,
        reason: note.body?.slice(0, 200) || "(no body)",
        itemType: note.scopeType,
        targetView: viewIdForType(note.scopeType),
        targetItem: locateLiveItemByScope(note),
        recommendation: "Apply or revert this proposal.",
        primaryActions: ["open"],
      });
    }
  }

  // 3. Lint violations on un-approved live entities — emit one queue
  // entry per actual lint hit so Tom sees the specific issue + the
  // offending snippet, not 35 rows of canned copy.
  for (const surfaceId of surfaces) {
    const items = liveItemsForView(surfaceId) || [];
    for (const item of items) {
      const lintHits = item.payload?._lint || [];
      if (!lintHits.length) continue;
      const launch = effectiveLaunchStatus(item);
      if (launch === "approved" || launch === "shipped") continue;
      for (const hit of lintHits) {
        queue.push({
          id: `lint-${surfaceId}-${item.id}-${hit.ruleId}-${hit.field}`,
          severity: "lint",
          title: item.title,
          reason: lintReasonFor(hit),
          itemType: item.itemType,
          targetView: surfaceId,
          targetItem: item,
          recommendation: lintRecommendationFor(hit),
          primaryActions: ["open", "approve", "cut"],
        });
      }
    }
  }

  // 4. High-impact entities not yet approved (top tier in registry, or
  // bundle parents). Cap to 30 to avoid drowning the queue.
  let highImpactCount = 0;
  for (const surfaceId of surfaces) {
    const items = liveItemsForView(surfaceId) || [];
    for (const item of items) {
      if (highImpactCount >= 30) break;
      const launch = effectiveLaunchStatus(item);
      if (launch === "approved" || launch === "shipped") continue;
      const high = isHighImpact(item);
      if (!high) continue;
      // Skip if already in queue from earlier rules.
      const already = queue.some((q) => q.targetItem?.id === item.id);
      if (already) continue;
      queue.push({
        id: `impact-${surfaceId}-${item.id}`,
        severity: "impact",
        title: item.title,
        reason: high,
        itemType: item.itemType,
        targetView: surfaceId,
        targetItem: item,
        recommendation: "Review + lock if it's right.",
        primaryActions: ["open", "approve", "cut"],
      });
      highImpactCount += 1;
    }
  }

  return queue;
}

// Phase 5f — turn raw lint hits into specific, actionable rows.
function lintReasonFor(hit) {
  const fieldLabel = (hit.field || "").replace("answerOption.", "answer label ");
  const snippet = (hit.snippet || "").trim();
  const trimmed = snippet.length > 140 ? snippet.slice(0, 137) + "…" : snippet;
  if (hit.ruleId === "no-em-dash") {
    return `Em-dash in ${fieldLabel}: "${trimmed}"`;
  }
  if (hit.ruleId === "no-professional-x-titles") {
    return `Title starts with "Professional X": "${trimmed}"`;
  }
  if (hit.ruleId === "answer-label-max-words") {
    return `Answer label is too long: "${trimmed}"`;
  }
  return `${hit.ruleId} on ${fieldLabel}: "${trimmed}"`;
}

function lintRecommendationFor(hit) {
  if (hit.ruleId === "no-em-dash") {
    return "Replace the em-dash with a comma or hyphen — em-dashes read as AI-generated to HNW readers.";
  }
  if (hit.ruleId === "no-professional-x-titles") {
    return 'Use action-first phrasing instead — "Annual X" or "Schedule X".';
  }
  if (hit.ruleId === "answer-label-max-words") {
    return "Trim the label to 7 or fewer words. Long answer chips wrap awkwardly.";
  }
  return "Open the entity, fix the flagged copy, then approve.";
}

function isHighImpact(item) {
  const p = item.payload || {};
  if (p.bundleId) return `Bundle parent (${p.bundleId})`;
  if ((p._impact?.templates_in_category || []).length > 5) {
    return `${p._impact.templates_in_category.length} templates depend on this category`;
  }
  if (p.tier === "universal") return "Universal-tier system (every household)";
  if (p.safetyFloor === true) return "Safety-floor template";
  if (p.requiredSubtypes?.length === 0 && item.itemType === "task") return "Universal template (no gating)";
  return null;
}

function viewIdForType(type) {
  return (
    {
      question: "quiz",
      task: "tasks",
      handyman: "handyman",
      recommended: "recommended",
      routine: "routines",
      system: "systems",
      vehicle: "vehicles",
      prompt: "prompts",
    }[type] || "quiz"
  );
}

function locateLiveItemByScope(note) {
  const surface = viewIdForType(note.scopeType);
  const items = liveItemsForView(surface) || [];
  return (
    items.find((i) =>
      [i.payload?.id, i.payload?.templateKey, i.payload?.categoryKey, i.payload?.functionName, i.payload?.rawValue]
        .filter(Boolean)
        .includes(note.scopeId)
    ) ||
    items.find((i) => i.title === note.scopeTitle) ||
    null
  );
}

function decisionRowHtml(decision) {
  const severityLabel =
    {
      question: "Open question",
      proposal: "Pending proposal",
      lint: "Lint issue",
      impact: "High-impact entity",
    }[decision.severity] || decision.severity;
  const severityTone =
    {
      question: "defer",
      proposal: "active",
      lint: "cut",
      impact: "reshape",
    }[decision.severity] || "active";
  const actions = decision.primaryActions
    .map((a) => {
      if (a === "open") return `<button type="button" class="admin-button" data-decision-action="open">Open</button>`;
      if (a === "approve") return `<button type="button" class="admin-button admin-button--primary" data-decision-action="approve">Approve</button>`;
      if (a === "cut") return `<button type="button" class="admin-button admin-button--danger" data-decision-action="cut">Cut</button>`;
      return "";
    })
    .join("");
  return `
    <div class="admin-decision" data-decision-id="${escapeHtml(decision.id)}" data-open-detail>
      <div class="admin-decision__top">
        <span class="admin-pill" data-tone="${severityTone}">${escapeHtml(severityLabel)}</span>
        <strong>${escapeHtml(decision.title)}</strong>
        <span class="admin-muted">${escapeHtml(decision.itemType || "")}</span>
      </div>
      <p class="admin-decision__reason">${escapeHtml(decision.reason)}</p>
      <p class="admin-decision__rec">${escapeHtml(decision.recommendation)}</p>
      <div class="admin-decision__actions">${actions}</div>
    </div>
  `;
}

async function handleDecisionAction(decision, action) {
  if (action === "open" && decision.targetItem) {
    state.view = decision.targetView;
    state.selected = decision.targetItem;
    render();
    return;
  }
  if (action === "approve" && decision.targetItem) {
    state.selected = decision.targetItem;
    await toggleLockSelected(); // toggles to approved (or unlocks if already)
    render();
    return;
  }
  if (action === "cut" && decision.targetItem) {
    state.selected = decision.targetItem;
    const ok = confirm(`Mark "${decision.targetItem.title}" as cut?`);
    if (!ok) return;
    await markCutLive(decision.targetItem);
    render();
  }
}

async function markCutLive(item) {
  if (state.storageMode !== "cloud") return;
  const liveId = liveEntityIdFor(item);
  if (!liveId) return;
  const shadow = findLockShadow(item);
  const row = {
    item_type: item.itemType,
    title: item.title,
    status: "cut",
    category: item.category || null,
    description: item.description || null,
    sort_order: item.sortOrder ?? 0,
    payload: shadow?.payload ?? { live_entity_id: liveId, source: "live_lock" },
    live_entity_id: liveId,
    launch_status: "sunset",
    locked_at: new Date().toISOString(),
  };
  try {
    if (shadow?.id) {
      await supabase.from("admin_content_items").update(row).eq("id", shadow.id);
    } else {
      await supabase.from("admin_content_items").insert(row);
    }
    await loadAdminData();
  } catch (error) {
    alert(`Cut save failed: ${error.message}`);
  }
}

// =============================================================================
// Phase 7.5 — Activity feed
// =============================================================================

function renderActivityView() {
  // Applied notes + reverted notes, reverse chronological
  const events = [];
  for (const note of state.notes) {
    if (note.appliedAt) {
      events.push({
        type: "applied",
        when: note.appliedAt,
        note,
      });
    }
    if (note.revertedAt) {
      events.push({ type: "reverted", when: note.revertedAt, note });
    }
  }
  // Locks too — admin_content_items that have locked_at
  for (const item of state.adminItems) {
    if (item.lockedAt) {
      events.push({ type: "locked", when: item.lockedAt, item });
    }
  }
  events.sort((a, b) => +new Date(b.when) - +new Date(a.when));

  el.stats.innerHTML = `
    <div class="admin-stat"><strong>${events.length}</strong><span>Events</span></div>
    <div class="admin-stat"><strong>${events.filter((e) => e.type === "applied").length}</strong><span>Applied</span></div>
    <div class="admin-stat"><strong>${events.filter((e) => e.type === "locked").length}</strong><span>Locks</span></div>
    <div class="admin-stat"><strong>${events.filter((e) => e.type === "reverted").length}</strong><span>Reverted</span></div>
  `;

  el.list.innerHTML = events.length
    ? events.map(activityRowHtml).join("")
    : `<div class="admin-empty-detail" style="min-height:240px"><h3>No activity yet</h3><p>Apply a note or lock an entity to see it here.</p></div>`;

  el.emptyDetail.classList.add("is-hidden");
  el.detail.classList.add("is-hidden");
}

function activityRowHtml(event) {
  if (event.type === "applied" || event.type === "reverted") {
    const note = event.note;
    const tone = event.type === "applied" ? "active" : "cut";
    return `
      <article class="admin-activity admin-activity--${event.type}">
        <header>
          <span class="admin-pill" data-tone="${tone}">${event.type}</span>
          <strong>${escapeHtml(note.scopeTitle || "(unscoped)")}</strong>
          <span class="admin-muted">${escapeHtml(formatDate(event.when))}</span>
        </header>
        <p class="admin-muted">${escapeHtml(note.scopeType || "general")}${note.appliedCommit ? ` · commit ${escapeHtml(note.appliedCommit.slice(0, 7))}` : ""}</p>
        <pre>${escapeHtml(note.body || "")}</pre>
      </article>
    `;
  }
  if (event.type === "locked") {
    return `
      <article class="admin-activity admin-activity--locked">
        <header>
          <span class="admin-pill" data-tone="active">locked</span>
          <strong>${escapeHtml(event.item.title || "(untitled)")}</strong>
          <span class="admin-muted">${escapeHtml(formatDate(event.when))}</span>
        </header>
        <p class="admin-muted">${escapeHtml(event.item.itemType)} · launch_status: ${escapeHtml(event.item.launchStatus || "?")}</p>
      </article>
    `;
  }
  return "";
}

// =============================================================================
// Phase 5e — Architecture surface
// =============================================================================
// Walkable object-relationship map. Renders the OBJECT_MAP as a single
// scrollable surface (no list/detail split — it's already self-organized
// by cluster). The list panel is hidden; everything goes in the right
// pane.

function renderArchitectureSurface() {
  el.emptyDetail.classList.add("is-hidden");
  el.detail.classList.remove("is-hidden");

  // Hide everything else in the detail panel that doesn't apply.
  el.curatedForm?.classList.add("is-hidden");
  if (el.formHost) el.formHost.innerHTML = "";
  if (el.diffHost) el.diffHost.innerHTML = "";
  if (el.lockToggle) el.lockToggle.classList.add("is-hidden");
  if (el.previewQuestion) el.previewQuestion.classList.add("is-hidden");
  if (el.launchPill) el.launchPill.classList.add("is-hidden");
  if (el.detailTabs) el.detailTabs.classList.add("is-hidden");

  // Header reflects whether we're looking at an object or the overview.
  const focused = state.archSelectedKey ? findArchObject(state.archSelectedKey) : null;
  if (focused) {
    el.detailKind.textContent = focused.cluster;
    el.detailTitle.textContent = `${focused.emoji} ${focused.name}`;
    el.detailSubtitle.textContent = "Click any related object to navigate to it.";
    el.detailStatus.textContent = "object";
  } else {
    el.detailKind.textContent = "object map";
    el.detailTitle.textContent = "Pick an object to start";
    el.detailSubtitle.textContent = "Or use the left rail to jump straight in.";
    el.detailStatus.textContent = "overview";
  }
  el.detailStatus.dataset.tone = "active";

  // Render the appropriate body into formHost.
  if (el.formHost) {
    const extras = focused?.key === "edge_function_prompt"
      ? { edge_function_prompt: renderEdgeFunctionInventory() }
      : {};
    el.formHost.innerHTML = focused
      ? renderArchitectureObject(focused.key, extras)
      : renderArchitectureOverview();
    attachArchitectureHandlers(el.formHost, {
      onOpen: openArchitectureObject,
      onBack: clearArchitectureObject,
    });
    // Wire edge-function click-throughs to jump to the Prompts surface.
    el.formHost.querySelectorAll("[data-edge-fn-jump]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const fnName = btn.dataset.edgeFnJump;
        state.view = "prompts";
        const items = liveItemsForView("prompts") || [];
        state.selected = items.find((i) => i.payload?.functionName === fnName) || null;
        render();
      });
    });
  }

  // Left rail: cluster-grouped quick-jump nav with the current object
  // highlighted (cluster headers separate the list visually).
  const lite = getObjectMapLite();
  const clusters = getClusters();
  el.list.innerHTML = `
    <div class="admin-arch__nav">
      <strong>Object map</strong>
      ${clusters
        .map((cluster) => {
          const objects = lite.filter((o) => o.cluster === cluster.key);
          if (!objects.length) return "";
          return `
            <div class="admin-arch__nav-cluster">
              <span class="admin-arch__nav-cluster-label">${escapeHtml(cluster.label)}</span>
              <ul>
                ${objects
                  .map(
                    (o) => `
                      <li>
                        <button type="button" data-arch-jump="${escapeHtml(o.key)}" class="${state.archSelectedKey === o.key ? "is-active" : ""}">
                          <span>${o.emoji}</span> ${escapeHtml(o.name)}
                        </button>
                      </li>
                    `
                  )
                  .join("")}
              </ul>
            </div>
          `;
        })
        .join("")}
    </div>
  `;
  el.list.querySelectorAll("[data-arch-jump]").forEach((btn) => {
    btn.addEventListener("click", () => openArchitectureObject(btn.dataset.archJump));
  });

  el.stats.innerHTML = focused
    ? `<div class="admin-stat"><strong>${focused.keyFields?.length || 0}</strong><span>Key fields</span></div>
       <div class="admin-stat"><strong>${(focused.relationships || []).length}</strong><span>Outgoing links</span></div>`
    : `<div class="admin-stat"><strong>${lite.length}</strong><span>Objects mapped</span></div>
       <div class="admin-stat"><strong>${clusters.length}</strong><span>Clusters</span></div>`;
}

// Phase 5g — render the edge functions inventory injected into the
// Edge Function Prompt architecture detail. Groups the 50+ functions
// by purpose so the page reads cleanly. Click any row to jump straight
// to that prompt on the Prompts surface.
function renderEdgeFunctionInventory() {
  const fns = state.liveData["edge-function-prompts"]?.entries || [];
  if (!fns.length) {
    return `<section class="admin-arch__panel"><h4>Edge function inventory</h4><p class="admin-muted">No edge functions exported yet — run scripts/export_swift_admin_data.mjs and refresh.</p></section>`;
  }
  const buckets = bucketEdgeFunctions(fns);
  const totalFns = fns.length;
  const withPrompt = fns.filter((f) => f.systemPrompt).length;
  const sectionsHtml = buckets
    .filter((b) => b.fns.length)
    .map(
      (b) => `
        <section class="admin-arch__edge-bucket">
          <header>
            <h5>${escapeHtml(b.label)}</h5>
            <span class="admin-muted">${b.fns.length} function${b.fns.length === 1 ? "" : "s"}</span>
          </header>
          <ul>
            ${b.fns
              .map((fn) => `
                <li>
                  <button type="button" class="admin-arch__edge-fn" data-edge-fn-jump="${escapeHtml(fn.functionName)}">
                    <code>${escapeHtml(fn.functionName)}</code>
                    <span class="admin-arch__edge-fn-meta">
                      ${fn.model ? `<span>${escapeHtml(fn.model)}</span>` : ""}
                      ${fn.systemPrompt ? `<span>${fn.systemPrompt.length} char prompt</span>` : `<span class="admin-arch__edge-fn-warn">no prompt detected</span>`}
                    </span>
                  </button>
                </li>
              `).join("")}
          </ul>
        </section>
      `
    )
    .join("");
  return `
    <section class="admin-arch__panel admin-arch__panel--edge">
      <h4>Edge function inventory (${totalFns})</h4>
      <p class="admin-muted">${withPrompt} of ${totalFns} have a detected system prompt. Click any function to open it on the Prompts surface.</p>
      <div class="admin-arch__edge-buckets">
        ${sectionsHtml}
      </div>
    </section>
  `;
}

const EDGE_FUNCTION_BUCKETS = [
  {
    key: "doc_ai",
    label: "📄 Document + AI insights",
    match: /^(analyze|process-invoice|gap-analysis|simulate-scenario|proactive-scan|chat|extract-vendor)/,
  },
  {
    key: "email",
    label: "📧 Email pipeline",
    match: /^(receive-email|process-inbox-item|send-)/,
  },
  {
    key: "vehicle",
    label: "🚗 Vehicle",
    match: /^(vehicle-|check-vehicle)/,
  },
  {
    key: "property",
    label: "🏠 Property + lookup",
    match: /^(property-lookup|brand-logo|find-local-vendors|view-document|verify-)/,
  },
  {
    key: "equipment",
    label: "🛠 Equipment + manuals",
    match: /^(search-equipment|identify-equipment|lookup-manual|score-equipment|enrich-catalog|expand-catalog|scrape-manuals|download-manuals|upload-manual|send-catalog-request)/,
  },
  {
    key: "quote",
    label: "💵 Quote + project",
    match: /^(analyze-quote|draft-negotiation-email|research-project|project-feasibility|visualize-room|score-property)/,
  },
  {
    key: "household",
    label: "👥 Household + account",
    match: /^(merge-households|delete-account|send-push|cadence-notifications|handyman-portal|find-network-handymen)/,
  },
];

function bucketEdgeFunctions(fns) {
  const buckets = EDGE_FUNCTION_BUCKETS.map((b) => ({ label: b.label, fns: [] }));
  const other = { label: "🧩 Other", fns: [] };
  fns.forEach((fn) => {
    const idx = EDGE_FUNCTION_BUCKETS.findIndex((b) => b.match.test(fn.functionName));
    if (idx >= 0) buckets[idx].fns.push(fn);
    else other.fns.push(fn);
  });
  buckets.forEach((b) => b.fns.sort((a, c) => a.functionName.localeCompare(c.functionName)));
  other.fns.sort((a, c) => a.functionName.localeCompare(c.functionName));
  return [...buckets, other];
}

function openArchitectureObject(key) {
  state.archSelectedKey = key;
  renderArchitectureSurface();
  // Scroll the new detail to the top so it always starts clean.
  if (el.formHost) el.formHost.scrollTop = 0;
}

function clearArchitectureObject() {
  state.archSelectedKey = null;
  renderArchitectureSurface();
}

// =============================================================================
// Phase 5b — CLAUDE_ADMIN_NOTES.md live preview
// =============================================================================
// Mirrors what scripts/sync_claude_admin_notes.mjs produces, rendered in
// the browser so Tom can see exactly what next-session Claude will read
// without dropping into a terminal. Same priority order: questions for
// Claude → pending changes → open feedback by entity → recently applied.

function renderClaudeFileView() {
  el.emptyDetail.classList.add("is-hidden");
  el.detail.classList.add("is-hidden");

  // Filter to claude/both target + non-archived, then group.
  const claudeNotes = state.notes.filter(
    (n) => n.target === "claude" || n.target === "both"
  );

  const pending = claudeNotes.filter(
    (n) =>
      !n.appliedAt &&
      !n.revertedAt &&
      ["change_request", "proposal_add", "proposal_delete"].includes(n.intent)
  );
  const questions = claudeNotes.filter(
    (n) => !n.appliedAt && n.intent === "question_for_claude"
  );
  const feedback = claudeNotes.filter(
    (n) =>
      !n.appliedAt &&
      !n.revertedAt &&
      !["change_request", "proposal_add", "proposal_delete", "question_for_claude"].includes(n.intent)
  );
  const applied = claudeNotes.filter((n) => n.appliedAt && !n.revertedAt);

  el.stats.innerHTML = `
    <div class="admin-stat"><strong>${pending.length}</strong><span>Pending changes</span></div>
    <div class="admin-stat"><strong>${questions.length}</strong><span>Open questions</span></div>
    <div class="admin-stat"><strong>${feedback.length}</strong><span>Feedback</span></div>
    <div class="admin-stat"><strong>${applied.length}</strong><span>Applied</span></div>
  `;

  // Build threaded structure (parent → children) so replies render nested.
  const threaded = nestThreadsForFile(claudeNotes);

  const listHtml = `
    <div class="admin-claude-file">
      <header class="admin-claude-file__header">
        <p class="admin-eyebrow">CLAUDE_ADMIN_NOTES.md</p>
        <h2>${escapeHtml(claudeNotes.length)} note${claudeNotes.length === 1 ? "" : "s"} synced to Claude</h2>
        <p class="admin-muted">Live preview. Saving a note above auto-updates this view. The actual
        <code>CLAUDE_ADMIN_NOTES.md</code> file refreshes on the next sync —
        run <code>node scripts/sync_claude_admin_notes.mjs</code> locally to write the file.</p>
      </header>

      ${
        questions.length
          ? `<section class="admin-claude-file__section admin-claude-file__section--question">
              <h3>❓ Questions for Claude (answer first)</h3>
              ${threaded.filter((n) => questions.includes(n)).map(claudeFileNoteHtml).join("")}
            </section>`
          : ""
      }

      ${
        pending.length
          ? `<section class="admin-claude-file__section admin-claude-file__section--pending">
              <h3>⚡ Pending Changes (act on these first)</h3>
              ${threaded.filter((n) => pending.includes(n)).map(claudeFileNoteHtml).join("")}
            </section>`
          : ""
      }

      ${
        feedback.length
          ? `<section class="admin-claude-file__section">
              <h3>📋 Open Feedback (by entity)</h3>
              ${renderFeedbackByEntity(threaded.filter((n) => feedback.includes(n)))}
            </section>`
          : ""
      }

      ${
        applied.length
          ? `<section class="admin-claude-file__section admin-claude-file__section--applied">
              <h3>✅ Recently Applied</h3>
              <p class="admin-muted">Already shipped. Read for retroactive QA only.</p>
              ${renderFeedbackByEntity(threaded.filter((n) => applied.includes(n)))}
            </section>`
          : ""
      }

      ${
        !claudeNotes.length
          ? `<div class="admin-empty-detail" style="min-height:240px">
              <h3>No notes yet</h3>
              <p>Save a note from any detail panel or quiz preview and it'll show up here.</p>
            </div>`
          : ""
      }
    </div>
  `;

  el.list.innerHTML = listHtml;

  // Wire revert buttons inside the file preview.
  el.list.querySelectorAll("[data-revert-note]").forEach((btn) => {
    btn.addEventListener("click", async (event) => {
      event.stopPropagation();
      await revertNote(btn.dataset.revertNote);
      renderClaudeFileView();
    });
  });
}

function nestThreadsForFile(notes) {
  // Wrap each note with replies array; populate from parentNoteId.
  const byId = new Map(notes.map((n) => [n.id, { ...n, replies: [] }]));
  const top = [];
  for (const n of notes) {
    const wrapped = byId.get(n.id);
    if (n.parentNoteId && byId.has(n.parentNoteId)) {
      byId.get(n.parentNoteId).replies.push(wrapped);
    } else {
      top.push(wrapped);
    }
  }
  top.sort((a, b) => +new Date(b.createdAt) - +new Date(a.createdAt));
  for (const t of top) t.replies.sort((a, b) => +new Date(a.createdAt) - +new Date(b.createdAt));
  return top;
}

function renderFeedbackByEntity(notes) {
  // Group by scopeType + scopeId for a clean per-entity view.
  const groups = new Map();
  for (const note of notes) {
    const key = `${note.scopeType || "general"}::${note.scopeId || note.scopeTitle || "(unscoped)"}`;
    if (!groups.has(key)) {
      groups.set(key, {
        scopeType: note.scopeType || "general",
        scopeTitle: note.scopeTitle || "Unnamed",
        scopeId: note.scopeId,
        notes: [],
      });
    }
    groups.get(key).notes.push(note);
  }
  const ordered = [...groups.values()].sort((a, b) => {
    const order = ["question", "task", "handyman", "routine", "system", "vehicle", "prompt", "general"];
    const ai = order.indexOf(a.scopeType);
    const bi = order.indexOf(b.scopeType);
    if (ai !== bi) return (ai < 0 ? 99 : ai) - (bi < 0 ? 99 : bi);
    return a.scopeTitle.localeCompare(b.scopeTitle);
  });
  return ordered
    .map(
      (g) => `
        <article class="admin-claude-file__entity">
          <header>
            <span class="admin-pill admin-pill--note">${escapeHtml(g.scopeType)}</span>
            <strong>${escapeHtml(g.scopeTitle)}</strong>
            ${g.scopeId ? `<code>${escapeHtml(g.scopeId)}</code>` : ""}
          </header>
          ${g.notes.map(claudeFileNoteHtml).join("")}
        </article>
      `
    )
    .join("");
}

function claudeFileNoteHtml(note, depth = 0) {
  const author = note.author || "tom";
  const ts = note.createdAt ? formatDate(note.createdAt) : "?";
  const intent = note.intent || "feedback";
  const headerBits = [ts, intent, author];
  if (note.appliedAt) {
    headerBits.push(`applied ${formatDate(note.appliedAt)}`);
    if (note.appliedCommit) headerBits.push(`commit ${note.appliedCommit.slice(0, 7)}`);
  }
  if (note.revertedAt) headerBits.push(`reverted ${formatDate(note.revertedAt)}`);

  const diffHtml =
    note.proposedDiff && Object.keys(note.proposedDiff).length
      ? `<details class="admin-claude-file__diff"><summary>Proposed diff</summary><pre>${escapeHtml(JSON.stringify(note.proposedDiff, null, 2))}</pre></details>`
      : "";

  const attachments = (note.attachmentUrls || [])
    .map((url) => `<a href="${escapeHtml(url)}" target="_blank" rel="noopener" class="admin-claude-file__attachment">attachment</a>`)
    .join(" ");

  const revertBtn =
    note.appliedAt && !note.revertedAt
      ? `<button type="button" class="admin-button admin-button--secondary admin-button--xs" data-revert-note="${escapeHtml(note.id)}">Revert</button>`
      : "";

  const replies = (note.replies || []).map((r) => claudeFileNoteHtml(r, depth + 1)).join("");

  return `
    <article class="admin-claude-file__note ${depth > 0 ? "admin-claude-file__note--reply" : ""}">
      <header>
        <span class="admin-claude-file__note-meta">${escapeHtml(headerBits.join(" · "))}</span>
        ${revertBtn}
      </header>
      <pre>${escapeHtml(note.body || "")}</pre>
      ${attachments ? `<div class="admin-claude-file__attachments">${attachments}</div>` : ""}
      ${diffHtml}
      ${replies}
    </article>
  `;
}

function renderNotesView() {
  // Phase 5h — text search across body + scope title + scope id. Reuses
  // the existing list-tools search input (state.search) so the same
  // box that filters every other surface filters notes too.
  const query = (state.search || "").trim().toLowerCase();
  const matchesQuery = (n) => {
    if (!query) return true;
    return [n.body, n.scopeTitle, n.scopeId, n.intent, n.scopeType]
      .filter(Boolean)
      .some((s) => String(s).toLowerCase().includes(query));
  };

  // Top-level notes only; replies stay nested under their parents on the
  // entity's detail panel.
  const topLevel = state.notes.filter((n) => !n.parentNoteId).filter(matchesQuery);

  el.stats.innerHTML = `
    <div class="admin-stat"><strong>${topLevel.length}</strong><span>${query ? "Matching" : "Notes"}</span></div>
    <div class="admin-stat"><strong>${state.notes.filter((n) => !n.appliedAt && ["change_request","proposal_add","proposal_delete"].includes(n.intent)).length}</strong><span>Pending</span></div>
    <div class="admin-stat"><strong>${state.notes.filter((n) => n.appliedAt).length}</strong><span>Applied</span></div>
  `;

  el.list.innerHTML = topLevel.map((note) => {
    const canJump = noteCanJumpToEntity(note);
    const intent = note.intent || "feedback";
    const author = note.author || "tom";
    const appliedPill = note.appliedAt
      ? `<span class="admin-pill" data-tone="active">applied</span>`
      : note.revertedAt
      ? `<span class="admin-pill" data-tone="cut">reverted</span>`
      : "";
    const jumpHint = canJump
      ? `<span class="admin-list-item__jump" title="Open the ${escapeHtml(note.scopeType)} this note is about">Open ${escapeHtml(note.scopeType)} →</span>`
      : `<span class="admin-pill">general</span>`;
    return `
      <button class="admin-list-item" data-note-id="${escapeHtml(note.id)}">
        <div class="admin-list-item__top">
          <strong>${escapeHtml(note.scopeTitle || "General note")}</strong>
          <span class="admin-pill admin-pill--note">${escapeHtml(intent)}</span>
          ${author === "claude" ? `<span class="admin-pill admin-pill--note">claude</span>` : ""}
          ${appliedPill}
        </div>
        <p>${escapeHtml((note.body || "").slice(0, 220))}</p>
        <div class="admin-list-item__meta">
          <span>${escapeHtml(formatDate(note.createdAt))}</span>
          ${jumpHint}
        </div>
      </button>
    `;
  }).join("") || emptyListHtml("No notes yet.");

  el.list.querySelectorAll("[data-note-id]").forEach((button) => {
    button.addEventListener("click", () => {
      const note = state.notes.find((n) => n.id === button.dataset.noteId);
      if (!note) return;
      // Phase 5c — clicking a note jumps to the entity it was placed on so
      // Tom can read the existing thread + write a new note in the same
      // place. General notes (no scope) keep the legacy in-pane editor.
      if (noteCanJumpToEntity(note)) {
        const targetView = viewIdForType(note.scopeType);
        const targetItem = locateLiveItemByScope(note);
        if (targetView && targetItem) {
          state.view = targetView;
          state.selected = targetItem;
          render();
          return;
        }
      }
      // Fallback for general notes / orphaned scope: show in pane.
      state.selected = note;
      renderGeneralNoteFallback(note);
    });
  });

  // Initial pane state — empty until a note is clicked.
  el.emptyDetail.classList.remove("is-hidden");
  el.detail.classList.add("is-hidden");
  el.emptyDetail.querySelector("h3").textContent = query
    ? `${topLevel.length} note${topLevel.length === 1 ? "" : "s"} matching "${query}"`
    : "Pick a note to open its entity.";
  el.emptyDetail.querySelector("p").textContent = query
    ? "Click any matching note to open the entity it's about. Search clears when you switch surfaces or hit Esc."
    : "Notes are written about a specific quiz question, template, system, or routine. Click one to open that entity's detail panel — you'll see the full thread and can add another note right there. General notes (no entity scope) stay in this pane. Type in the search box above to filter by body or entity.";
}

function noteCanJumpToEntity(note) {
  if (!note?.scopeType || !note?.scopeId) return false;
  return ["question", "task", "handyman", "routine", "system", "vehicle", "prompt"].includes(note.scopeType);
}

function renderGeneralNoteFallback(note) {
  el.emptyDetail.classList.add("is-hidden");
  el.detail.classList.remove("is-hidden");
  el.detailTabs?.classList.add("is-hidden");
  el.curatedForm?.classList.remove("is-hidden");
  if (el.formHost) el.formHost.innerHTML = "";
  if (el.diffHost) el.diffHost.innerHTML = "";
  el.detailKind.textContent = "general note";
  el.detailTitle.textContent = note.scopeTitle || "Running notes";
  el.detailSubtitle.textContent = note.createdAt ? formatDate(note.createdAt) : "Saved general note.";
  el.detailStatus.textContent = note.intent || "feedback";
  el.detailStatus.dataset.tone = note.appliedAt ? "active" : "draft";
  el.fieldTitle.value = note.scopeTitle || "General admin note";
  el.fieldStatus.value = "active";
  el.fieldCategory.value = note.scopeType || "general";
  el.fieldSort.value = "0";
  el.fieldDescription.value = note.body || "";
  if (el.fieldPayload) el.fieldPayload.value = JSON.stringify(note.snapshot ?? {}, null, 2);
  el.contextNote.value = "";
  el.contextNotes.innerHTML = "";
  el.promoteItem.disabled = true;
  el.duplicateItem.disabled = true;
  el.deleteItem.disabled = true;
  el.saveItem.textContent = "Save general note";
  el.saveNote.textContent = "Save note";
}

function renderContextNotes(item) {
  const allMatching = state.notes.filter((note) => itemNoteMatches(note, item));
  if (!allMatching.length) {
    el.contextNotes.innerHTML = `
      <div class="admin-note-card">
        <strong>No notes on this item yet.</strong>
        <pre>Write one above. The note auto-captures the entity's full Swift configuration so Claude can act on it next session without re-exploring.</pre>
      </div>
    `;
    return;
  }

  // Phase 5 — thread by parent_note_id so Claude's replies nest under
  // Tom's original notes inline.
  const byId = new Map(allMatching.map((n) => [n.id, { ...n, replies: [] }]));
  const top = [];
  for (const n of allMatching) {
    const wrapped = byId.get(n.id);
    if (n.parentNoteId && byId.has(n.parentNoteId)) {
      byId.get(n.parentNoteId).replies.push(wrapped);
    } else {
      top.push(wrapped);
    }
  }
  top.sort((a, b) => +new Date(b.createdAt) - +new Date(a.createdAt));
  for (const t of top) {
    t.replies.sort((a, b) => +new Date(a.createdAt) - +new Date(b.createdAt));
  }

  const limit = 8;
  el.contextNotes.innerHTML = top.slice(0, limit).map((note) => renderNoteCard(note, 0)).join("");
  if (top.length > limit) {
    el.contextNotes.innerHTML += `<p class="admin-muted" style="margin-top:8px">…and ${top.length - limit} more older notes (Notes tab to see all).</p>`;
  }
  // Wire revert buttons
  el.contextNotes.querySelectorAll("[data-revert-note]").forEach((btn) => {
    btn.addEventListener("click", async (event) => {
      event.stopPropagation();
      await revertNote(btn.dataset.revertNote);
    });
  });
}

function renderNoteCard(note, depth) {
  const intent = note.intent || "feedback";
  const author = note.author || "tom";
  const isApplied = !!note.appliedAt;
  const isReverted = !!note.revertedAt;
  const pill = isApplied
    ? `<span class="admin-pill" data-tone="active" title="Applied ${formatDate(note.appliedAt)}${
        note.appliedCommit ? " · " + note.appliedCommit.slice(0, 7) : ""
      }">applied</span>`
    : isReverted
    ? `<span class="admin-pill" data-tone="cut">reverted</span>`
    : `<span class="admin-pill admin-pill--note">${escapeHtml(intent)}</span>`;
  const authorTag = author === "claude"
    ? `<span class="admin-pill admin-pill--note">claude</span>`
    : "";
  const revertBtn = isApplied && !isReverted
    ? `<button type="button" class="admin-button admin-button--secondary admin-button--xs" data-revert-note="${escapeHtml(note.id)}">Revert</button>`
    : "";
  const attachments = (note.snapshot?.attachment_urls || note.attachmentUrls || [])
    .map((url) => `<img src="${escapeHtml(url)}" alt="attachment" class="admin-note-card__attachment" />`)
    .join("");
  const replies = (note.replies || [])
    .map((reply) => renderNoteCard(reply, depth + 1))
    .join("");
  return `
    <article class="admin-note-card admin-note-card--depth-${Math.min(depth, 2)}" ${depth > 0 ? 'data-reply="true"' : ""}>
      <div class="admin-note-card__top">
        <strong>${escapeHtml(note.scopeTitle || "Context note")}</strong>
        ${pill}
        ${authorTag}
      </div>
      <small>${escapeHtml(formatDate(note.createdAt))} · target: ${escapeHtml(note.target || "claude")}</small>
      <pre>${escapeHtml(note.body || "")}</pre>
      ${attachments ? `<div class="admin-note-card__attachments">${attachments}</div>` : ""}
      ${revertBtn ? `<div class="admin-note-card__actions">${revertBtn}</div>` : ""}
      ${replies}
    </article>
  `;
}

// Phase 5 — flip applied note to reverted; Claude reads this as "undo"
// instructions on next session start.
async function revertNote(noteId) {
  if (!noteId) return;
  if (!confirm("Mark this applied change as reverted? Claude will apply the reverse next session.")) return;
  if (state.storageMode !== "cloud") {
    alert("Revert requires cloud storage.");
    return;
  }
  try {
    const { data, error } = await supabase
      .from("admin_codex_notes")
      .update({ reverted_at: new Date().toISOString() })
      .eq("id", noteId)
      .select("*")
      .single();
    if (error) throw error;
    state.notes = state.notes.map((n) => (n.id === noteId ? dbNoteToUi(data) : n));
    if (state.selected) renderContextNotes(state.selected);
    else renderActivityView();
  } catch (error) {
    alert(`Revert failed: ${error.message}`);
  }
}

function itemNoteMatches(note, item) {
  // Phase 4: live entities expose ids under different keys per surface.
  // Quiz: id (e.g. "q3_heating_fuel"). Templates: templateKey / stableId.
  // Systems: categoryKey. Routines: rawValue / swiftCase. Edge fns:
  // functionName. Vehicles: synthetic "vehicle-prompt".
  const possibleIds = new Set([
    item.id,
    item.payload?.id,
    item.payload?.questionId,
    item.payload?.templateKey,
    item.payload?.stableId,
    item.payload?.categoryKey,
    item.payload?.functionName,
    item.payload?.rawValue,
    item.payload?.swiftCase,
    `${item.category || ""}:${item.title || ""}`,
  ].filter(Boolean).map(String));
  return note.scopeType === item.itemType
    && (possibleIds.has(String(note.scopeId || "")) || note.scopeTitle === item.title);
}

function itemRowHtml(item) {
  const isActive = state.selected?.id === item.id;
  const meta = [
    item.source,
    item.category,
    item.payload?.kind,
    item.payload?.operationalType,
    item.payload?.cadence,
    item.payload?.routing,
    item.payload?.assignmentType,
    item.payload?.frequency,
  ].filter(Boolean);
  const noteCount = state.notes.filter((n) => itemNoteMatches(n, item)).length;
  const noteBadge = noteCount > 0
    ? `<span class="admin-pill admin-pill--note">${noteCount} note${noteCount === 1 ? "" : "s"}</span>`
    : "";
  const lintBadge = item.lintCount > 0
    ? `<span class="admin-pill admin-pill--lint" title="${item.lintCount} voice-lint hit(s)">${item.lintCount} lint</span>`
    : "";
  // Phase 7.5 — launch lifecycle pill
  const launch = effectiveLaunchStatus(item);
  const launchBadge = launch && launch !== "draft"
    ? `<span class="admin-pill admin-pill--launch" data-tone="${launch}">${escapeHtml(launch)}</span>`
    : "";
  // Phase 5p — handyman bucket pill so Tom can scan the library for
  // auto-populating items vs. opt-in library items at a glance.
  let handymanBadge = "";
  if (item.itemType === "handyman") {
    if (item.payload?._autoPopulates === "spring") {
      handymanBadge = `<span class="admin-pill admin-pill--bundle-spring" title="Auto-populates the spring handyman punch list">🌷 Auto-pops</span>`;
    } else if (item.payload?._autoPopulates === "fall") {
      handymanBadge = `<span class="admin-pill admin-pill--bundle-fall" title="Auto-populates the fall handyman punch list">🍂 Auto-pops</span>`;
    } else if (item.payload?._libraryOnly) {
      handymanBadge = `<span class="admin-pill admin-pill--library" title="Library item — opt-in via Recommended Services">🛠️ Library</span>`;
    }
  }
  // Phase 5q — task lifecycle + season pills with concrete "how to opt
  // in" / "rolls up into X" context so the row is self-explanatory.
  let lifecycleBadge = "";
  let seasonBadge = "";
  if (["task", "recommended", "handyman"].includes(item.itemType)) {
    const t = item.payload || {};
    if (t.bundleId) {
      const parentTitle = prettyBundleTitle(t.bundleId);
      const siblingCount = countBundleSiblings(t.bundleId);
      const tooltip = `Never seeds as its own task. Rolls up into "${parentTitle}" alongside ${siblingCount - 1} sibling${siblingCount - 1 === 1 ? "" : "s"}. The homeowner sees ONE scheduled visit, not ${siblingCount} separate tasks.`;
      lifecycleBadge = `<span class="admin-pill admin-pill--bundle-child" title="${escapeHtml(tooltip)}">↳ ${escapeHtml(parentTitle)} (${siblingCount} items)</span>`;
    } else if (t.isEssential === false) {
      // Phase 5q — surface HOW the opt-in surfaces. Handyman-category
      // opt-ins land on the punch list "Recommended" section; everything
      // else lands in the Recommended Services view (Phase 54C).
      const optInSurface = t.systemCategory === "Handyman"
        ? "Surfaced in the handyman punch list 'Recommended' section. Homeowner taps + to add it to the next handyman visit."
        : "Surfaced in PropertyDetailView → Recommended Services. Homeowner taps + on the card to schedule it.";
      lifecycleBadge = `<span class="admin-pill admin-pill--optin" title="${escapeHtml(optInSurface)}">Opt-in</span>`;
    }
    if (t.seasonalTiming) {
      const seasonEmoji = { Spring: "🌷", Summer: "☀️", Fall: "🍂", Winter: "❄️", "Spring/Fall": "🔁" }[t.seasonalTiming] || "";
      seasonBadge = seasonEmoji
        ? `<span class="admin-pill admin-pill--season" title="${escapeHtml(t.seasonalTiming)} task">${seasonEmoji} ${escapeHtml(t.seasonalTiming)}</span>`
        : "";
    }
  }
  return `
    <button class="admin-list-item ${isActive ? "is-active" : ""}" data-item-id="${escapeHtml(item.id)}">
      <div class="admin-list-item__top">
        <strong>${escapeHtml(item.title)}</strong>
        <span class="admin-pill" data-tone="${escapeHtml(item.status)}">${escapeHtml(item.status)}</span>
        ${handymanBadge}
        ${lifecycleBadge}
        ${seasonBadge}
        ${launchBadge}
        ${lintBadge}
        ${noteBadge}
      </div>
      <p>${escapeHtml(item.description || "").slice(0, 220)}</p>
      <div class="admin-list-item__meta">
        ${meta.map((m) => `<span>${escapeHtml(String(m))}</span>`).join("")}
      </div>
    </button>
  `;
}

// Phase 5q — Count siblings in a bundle so a "Bundle child" row can
// show "↳ Spring Landscaping visit (4 items)" instead of leaving the
// reader guessing how many things land together.
function countBundleSiblings(bundleId) {
  if (!bundleId) return 0;
  const templates = state.liveData?.templates?.entries || [];
  return templates.filter((t) => t.bundleId === bundleId).length;
}

// Phase 5q — Map a bundleId like "Pool/Spa:opening" or "Landscaping:spring"
// into a homeowner-readable parent visit title. Mirrors the simulator's
// prettifyBundleId() helper but keeps it here so admin.js stays self-
// contained without importing simulator code.
function prettyBundleTitle(bundleId) {
  if (!bundleId) return "";
  const [category, season] = bundleId.split(":");
  const seasonLabel = {
    spring: "Spring", fall: "Fall", summer: "Summer", winter: "Winter",
    annual: "Annual", ongoing: "Ongoing", triennial: "Every 3 yrs",
    opening: "Opening", closing: "Closing",
  }[season] || (season || "").charAt(0).toUpperCase() + (season || "").slice(1);
  return `${seasonLabel} ${category} visit`;
}

function emptyListHtml(text = "Nothing matches this filter.") {
  return `<div class="admin-empty-detail" style="min-height:220px"><h3>${escapeHtml(text)}</h3></div>`;
}

function filterItems(items) {
  const q = state.search.trim().toLowerCase();
  // Phase 5q — facet filters apply on Tasks / Handyman / Recommended
  // surfaces. Other surfaces ignore them so legacy behavior is unchanged.
  const facetSurface = ["tasks", "handyman", "recommended"].includes(state.view);
  return items.filter((item) => {
    if (state.statusFilter !== "all" && item.status !== state.statusFilter) return false;
    if (facetSurface) {
      if (state.lifecycleFilter !== "all" && lifecycleOf(item) !== state.lifecycleFilter) return false;
      if (state.seasonFilter !== "all") {
        const s = item.payload?.seasonalTiming;
        if (state.seasonFilter === "year_round" && s) return false;
        if (state.seasonFilter !== "year_round" && s !== state.seasonFilter) return false;
      }
      if (state.routingFilter !== "all" && routingOf(item) !== state.routingFilter) return false;
    }
    if (!q) return true;
    return [item.title, item.category, item.description, JSON.stringify(item.payload ?? {})]
      .join(" ")
      .toLowerCase()
      .includes(q);
  });
}

async function createNewItem() {
  if (state.view === "notes") {
    state.selected = null;
    renderNotesView();
    el.fieldDescription.focus();
    return;
  }
  const view = currentView();
  const item = {
    id: `local-${Date.now()}`,
    source: "admin",
    isNew: true,
    itemType: view.type,
    title: `New ${view.type}`,
    status: "draft",
    category: defaultCategoryForView(view),
    sortOrder: state.adminItems.filter((i) => i.itemType === view.type).length + 1,
    description: "",
    payload: defaultPayloadForView(view),
  };
  state.adminItems.unshift(item);
  state.selected = item;
  render();
}

function defaultCategoryForView(view) {
  if (view.id === "tasks") return "Handyman";
  if (view.id === "quiz") return "Your Home";
  return view.label;
}

function defaultPayloadForView(view) {
  if (view.id === "quiz") {
    return {
      questionId: `admin_question_${Date.now()}`,
      chapter: "your_home",
      section: "homeBasics",
      kind: "singleChoice",
      answerOptions: [
        { id: "yes", label: "Yes" },
        { id: "no", label: "No" },
      ],
      intent: "Low-code admin-created question. Add answer mapping in Swift only if this answer needs custom side effects.",
    };
  }
  if (view.id === "tasks") {
    return {
      systemCategory: "Handyman",
      operationalType: "Handyman task",
      cadence: "Annually",
      season: "",
      priority: "Medium",
      cost: "$150-$400",
      assignmentType: "either",
      routing: "diyCapable",
      requiredSubtypes: [],
      essential: false,
      warrantyLinked: false,
      notes: "Low-code task template created from /admin.",
    };
  }
  if (view.id === "routines") {
    return {
      cadence: "Biweekly",
      defaultDayTime: "Wednesday 9:00 AM",
      activeMonths: "Year-round",
      serviceKey: "custom_routine",
    };
  }
  if (view.id === "vendors") {
    return {
      providerType: "handyman",
      orchestrationDefault: "quote_or_schedule",
      searchEnabled: true,
    };
  }
  if (view.id === "searches") {
    return {
      scopes: ["vendors", "systems"],
      placeholder: "Search vendors, systems, or equipment...",
    };
  }
  if (view.id === "systems") {
    return {
      systemCategory: "Handyman",
      createsSystem: true,
    };
  }
  return {};
}

async function promoteSelectedItem() {
  if (!state.selected || state.selected.source === "admin") return;
  const promoted = {
    ...state.selected,
    id: `local-${Date.now()}`,
    source: "admin",
    isNew: true,
    title: state.selected.title,
    payload: {
      ...state.selected.payload,
      promotedFromAuditId: state.selected.id,
    },
  };
  state.adminItems.unshift(promoted);
  state.selected = promoted;
  render();
}

async function duplicateSelectedItem() {
  if (!state.selected) return;
  // Phase 5 — for live entities, "duplicate" becomes a proposal_add note
  // that captures the cloned payload. Claude reads it as "create a new
  // entity like this one with these tweaks." For curated drafts the
  // existing in-memory clone-as-draft path stays.
  if (state.selected.source === "live") {
    const cloned = structuredCloneSafe(state.selected.payload);
    // Strip identity fields so Claude knows this is meant as a NEW entity
    delete cloned.id;
    delete cloned.templateKey;
    delete cloned.stableId;
    delete cloned.functionName;
    delete cloned.rawValue;
    delete cloned.categoryKey;
    await writeNote({
      scopeType: state.selected.itemType,
      scopeId: liveEntityIdFor(state.selected),
      scopeTitle: `${state.selected.title} (clone proposal)`,
      body:
        `Propose adding a NEW ${state.selected.itemType} based on "${state.selected.title}". ` +
        `Edit the proposed_diff before saving in admin or write a follow-up note here with the changes you want.`,
      intent: "proposal_add",
      target: el.fieldTarget?.value || "claude",
      proposedDiff: { based_on: liveEntityIdFor(state.selected), new_entity: cloned },
      snapshot: {
        itemType: state.selected.itemType,
        category: state.selected.category,
        payload: state.selected.payload,
        capturedAt: new Date().toISOString(),
      },
    });
    flashSavePill();
    renderContextNotes(state.selected);
    return;
  }

  const copy = {
    ...state.selected,
    id: `local-${Date.now()}`,
    source: "admin",
    isNew: true,
    title: `${state.selected.title} copy`,
    payload: structuredCloneSafe(state.selected.payload),
  };
  state.adminItems.unshift(copy);
  state.selected = copy;
  render();
}

// Phase 5 — attachment upload pipeline
async function handleAttachmentSelect(event) {
  const files = Array.from(event.target?.files || []);
  if (!files.length) return;
  if (state.storageMode !== "cloud") {
    alert("Attachments require cloud storage. Local-draft mode skips file uploads.");
    return;
  }
  for (const file of files) {
    setAttachmentStatus(`Uploading ${file.name}…`);
    try {
      const url = await uploadAttachment(file);
      pendingAttachments.push({ name: file.name, url, type: file.type });
      setAttachmentStatus(`${pendingAttachments.length} file(s) ready to attach. Save the note to commit.`);
    } catch (err) {
      console.warn("[admin] attachment upload failed", err);
      setAttachmentStatus(`Upload failed: ${err.message}`);
    }
  }
  // Reset the input so the same file can be re-selected.
  event.target.value = "";
}

async function uploadAttachment(file) {
  // Path: <user_id>/<scope_type>/<timestamp>-<filename>
  const userId = state.session?.user?.id || "anon";
  const scope = state.selected?.itemType || "general";
  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "_");
  const path = `${userId}/${scope}/${Date.now()}-${safeName}`;
  const { error } = await supabase.storage.from("admin-attachments").upload(path, file, {
    upsert: false,
    contentType: file.type,
  });
  if (error) throw error;
  // Signed URL valid for a year; admin is Tom-only so this stays private.
  const { data: signed, error: signErr } = await supabase.storage
    .from("admin-attachments")
    .createSignedUrl(path, 60 * 60 * 24 * 365);
  if (signErr) throw signErr;
  return signed?.signedUrl || null;
}

function setAttachmentStatus(text) {
  if (!el.attachmentStatus) return;
  el.attachmentStatus.textContent = text;
}

function consumePendingAttachments() {
  const urls = pendingAttachments.filter((a) => !!a.url).map((a) => a.url);
  pendingAttachments.length = 0;
  setAttachmentStatus("");
  return urls;
}

async function saveSelectedItem() {
  if (state.view === "notes") {
    await saveGeneralNote();
    return;
  }

  // Phase 4b — live entity edits become structured proposed_diff notes,
  // never direct mutations to admin_content_items.
  if (editingState.viewId && state.selected?.source === "live") {
    await saveLiveProposal();
    return;
  }

  const current = state.selected;
  if (!current) return;
  // Curated mode — payload still shipped as JSON because admin_content_items
  // doesn't have a per-surface schema. Hidden textarea is populated from
  // structured data when we switch to it; otherwise stays the prior value.
  let payload;
  try {
    payload = JSON.parse(el.fieldPayload.value || "{}");
  } catch {
    alert("Payload JSON is invalid. Fix it before saving.");
    return;
  }
  const item = {
    ...current,
    source: "admin",
    itemType: currentView().type,
    title: el.fieldTitle.value.trim() || "Untitled",
    status: el.fieldStatus.value,
    category: el.fieldCategory.value.trim(),
    sortOrder: Number(el.fieldSort.value || 0),
    description: el.fieldDescription.value.trim(),
    payload,
    isNew: current.source !== "admin" || current.isNew,
  };

  if (state.storageMode === "cloud") {
    try {
      const saved = await saveItemCloud(item);
      replaceAdminItem(saved);
      state.selected = saved;
    } catch (error) {
      alert(`Cloud save failed: ${error.message}`);
      return;
    }
  } else {
    replaceAdminItem(item);
    writeLocal(LOCAL_ITEMS_KEY, state.adminItems);
  }
  render();
}

// Phase 7.5 — toggle launch_status between draft and approved on the
// admin_content_items shadow row that tracks lock state for live entities.
async function toggleLockSelected() {
  const item = state.selected;
  if (!item) return;
  const liveId = liveEntityIdFor(item);
  if (!liveId) {
    alert("This entity has no stable identifier to anchor a lock against.");
    return;
  }
  const shadow = findLockShadow(item);
  const targetStatus = shadow?.launchStatus === "approved" ? "draft" : "approved";

  const row = {
    item_type: item.itemType,
    title: item.title,
    status: shadow?.status || "active",
    category: item.category || null,
    description: item.description || null,
    sort_order: item.sortOrder ?? 0,
    payload: shadow?.payload ?? { live_entity_id: liveId, source: "live_lock" },
    live_entity_id: liveId,
    launch_status: targetStatus,
    locked_at: targetStatus === "approved" ? new Date().toISOString() : null,
  };

  if (state.storageMode !== "cloud") {
    alert("Lock requires cloud storage. Local-draft mode can't anchor approval state.");
    return;
  }

  try {
    let saved;
    if (shadow?.id) {
      const { data, error } = await supabase
        .from("admin_content_items")
        .update(row)
        .eq("id", shadow.id)
        .select("*")
        .single();
      if (error) throw error;
      saved = dbItemToUi(data);
      state.adminItems = state.adminItems.map((a) => (a.id === saved.id ? saved : a));
    } else {
      const { data, error } = await supabase
        .from("admin_content_items")
        .insert(row)
        .select("*")
        .single();
      if (error) throw error;
      saved = dbItemToUi(data);
      state.adminItems.unshift(saved);
    }
    renderDetail();
    renderList();
    renderReadiness();
  } catch (error) {
    alert(`Lock save failed: ${error.message}`);
  }
}

async function saveLiveProposal() {
  const item = state.selected;
  if (!item || !editingState.viewId) return;
  const diff = computeProposedDiff(editingState.viewId, editingState.original, editingState.current);
  const changedKeys = Object.keys(diff);
  if (!changedKeys.length) {
    alert("No changes to save. Edit a field first.");
    return;
  }
  const userBody = (el.contextNote.value || "").trim();
  const summary = changedKeys
    .map((k) => `${k}: ${formatDiffValue(diff[k].from)} → ${formatDiffValue(diff[k].to)}`)
    .join("\n");
  const body = userBody
    ? `${userBody}\n\n---\nField changes:\n${summary}`
    : `Field changes:\n${summary}`;
  await writeNote({
    scopeType: item.itemType,
    scopeId:
      item.payload?.id ||
      item.payload?.questionId ||
      item.payload?.templateKey ||
      item.payload?.stableId ||
      item.payload?.categoryKey ||
      item.payload?.functionName ||
      item.payload?.rawValue ||
      item.id,
    scopeTitle: item.title,
    body,
    intent: "change_request",
    target: el.fieldTarget?.value || "claude",
    proposedDiff: diff,
    snapshot: {
      itemType: item.itemType,
      status: item.status,
      category: item.category,
      description: item.description,
      payload: editingState.original,
      capturedAt: new Date().toISOString(),
      capturedFrom: window.location.origin,
    },
  });
  el.contextNote.value = "";
  // Keep the form's `current` values, but reset original to current so the
  // diff strip clears (the proposal is now captured in a note).
  editingState.original = structuredCloneSafe(editingState.current);
  el.formHost.innerHTML = renderEntityForm(editingState.viewId, editingState.current, editingState.original);
  attachFormHandlers(el.formHost, editingState.viewId, editingState.original, editingState.current, () => {
    renderDiff();
  });
  renderDiff();
  renderContextNotes(item);
  flashSavePill();
  el.saveItem.textContent = "Saved ✓";
  setTimeout(() => {
    el.saveItem.textContent = "Save proposed change";
  }, 1500);
}

function formatDiffValue(value) {
  if (value == null || value === "") return "(empty)";
  if (Array.isArray(value)) {
    if (!value.length) return "(empty)";
    return value
      .map((v) => (typeof v === "object" && v ? v.label || v.id || JSON.stringify(v) : String(v)))
      .join(",");
  }
  if (typeof value === "boolean") return value ? "On" : "Off";
  if (typeof value === "object") return JSON.stringify(value).slice(0, 60);
  return String(value);
}

async function deleteSelectedItem() {
  const item = state.selected;
  if (!item || item.source !== "admin") return;
  if (!confirm(`Delete "${item.title}"?`)) return;
  if (state.storageMode === "cloud" && !item.id.startsWith("local-")) {
    const { error } = await supabase.from("admin_content_items").delete().eq("id", item.id);
    if (error) {
      alert(`Delete failed: ${error.message}`);
      return;
    }
  }
  state.adminItems = state.adminItems.filter((existing) => existing.id !== item.id);
  writeLocal(LOCAL_ITEMS_KEY, state.adminItems);
  state.selected = null;
  render();
}

async function saveItemCloud(item) {
  const row = {
    item_type: item.itemType,
    title: item.title,
    status: item.status,
    category: item.category,
    description: item.description,
    sort_order: item.sortOrder,
    payload: item.payload ?? {},
  };
  if (item.id && !item.id.startsWith("local-") && !item.isNew) {
    const { data, error } = await supabase
      .from("admin_content_items")
      .update(row)
      .eq("id", item.id)
      .select("*")
      .single();
    if (error) throw error;
    return dbItemToUi(data);
  }
  const { data, error } = await supabase
    .from("admin_content_items")
    .insert(row)
    .select("*")
    .single();
  if (error) throw error;
  return dbItemToUi(data);
}

async function saveGeneralNote() {
  const body = el.fieldDescription.value.trim();
  if (!body) {
    alert("Write a note first.");
    return;
  }
  await writeNote({
    scopeType: el.fieldCategory.value.trim() || "general",
    scopeId: null,
    scopeTitle: el.fieldTitle.value.trim() || "General admin note",
    body,
    snapshot: parseJsonLoose(el.fieldPayload.value),
  });
  el.fieldDescription.value = "";
  await loadAdminData();
  renderNotesView();
}

async function saveContextNote() {
  const item = state.selected;
  const body = el.contextNote.value.trim();
  if (!item || !body) {
    alert("Select an item and write a note first.");
    return;
  }
  const intent = el.fieldIntent?.value || "feedback";
  const target = el.fieldTarget?.value || "claude";
  await writeNote({
    scopeType: item.itemType,
    scopeId: item.payload?.id || item.payload?.questionId || item.payload?.templateKey || item.payload?.stableId || item.payload?.categoryKey || item.payload?.functionName || item.payload?.rawValue || item.id,
    scopeTitle: item.title,
    body,
    intent,
    target,
    snapshot: {
      itemType: item.itemType,
      status: item.status,
      category: item.category,
      description: item.description,
      // Phase 4: full Swift-derived entity snapshot so Claude can read the
      // note next session with complete context (impact, lint, raw fields).
      payload: item.payload,
      capturedAt: new Date().toISOString(),
      capturedFrom: window.location.origin,
    },
  });
  el.contextNote.value = "";
  renderContextNotes(item);
  flashSavePill();
}

function flashSavePill() {
  const btn = el.saveNote;
  if (!btn) return;
  const original = btn.textContent;
  btn.textContent = "Saved ✓";
  btn.disabled = true;
  setTimeout(() => {
    btn.textContent = original;
    btn.disabled = false;
  }, 1500);
}

async function writeNote(note) {
  // Phase 5 — drain any uploaded attachments staged for this note.
  const attachmentUrls = note.attachmentUrls || consumePendingAttachments();
  const full = {
    id: `note-${Date.now()}`,
    createdAt: new Date().toISOString(),
    intent: note.intent || "feedback",
    target: note.target || "claude",
    author: "tom",
    attachmentUrls,
    ...note,
  };
  if (state.storageMode === "cloud") {
    try {
      const { data, error } = await supabase
        .from("admin_codex_notes")
        .insert({
          scope_type: full.scopeType,
          scope_id: full.scopeId,
          scope_title: full.scopeTitle,
          body: full.body,
          snapshot: full.snapshot ?? {},
          // Admin Lab v2 columns
          intent: full.intent,
          target: full.target,
          author: full.author,
          proposed_diff: full.proposedDiff ?? null,
          attachment_urls: attachmentUrls,
        })
        .select("*")
        .single();
      if (error) throw error;
      const saved = dbNoteToUi(data);
      state.notes.unshift(saved);
      writeLocal(LOCAL_NOTES_KEY, state.notes);
      mirrorNoteToLocalFile(saved);
      return saved;
    } catch (error) {
      console.warn("[admin] note cloud save failed, falling back to local", error);
      state.storageMode = "local";
      el.storageWarning.hidden = false;
    }
  }
  state.notes.unshift(full);
  writeLocal(LOCAL_NOTES_KEY, state.notes);
  mirrorNoteToLocalFile(full);
  return full;
}

function mirrorNoteToLocalFile(note) {
  if (!["localhost", "127.0.0.1"].includes(window.location.hostname)) return;
  fetch("http://localhost:8787/admin-note", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(note),
  }).catch(() => {
    // Optional local bridge. If it is not running, Supabase/localStorage still saved.
  });
}

function exportConfig() {
  if (state.view === "notes") {
    downloadText("CODEX_ADMIN_NOTES.md", notesMarkdown());
    return;
  }
  const payload = {
    generatedAt: new Date().toISOString(),
    view: state.view,
    storageMode: state.storageMode,
    adminItems: state.adminItems,
    notes: state.notes,
  };
  downloadText("chez-admin-config.json", JSON.stringify(payload, null, 2));
}

function replaceAdminItem(item) {
  state.adminItems = [
    item,
    ...state.adminItems.filter((existing) => existing.id !== item.id && existing.id !== state.selected?.id),
  ];
  if (state.storageMode === "local") writeLocal(LOCAL_ITEMS_KEY, state.adminItems);
}

function countByView() {
  return Object.fromEntries(VIEWS.map((view) => {
    if (view.id === "notes") return [view.id, state.notes.length];
    const defaults = defaultItemsForView(view.id).length;
    const drafts = state.adminItems.filter((item) => item.itemType === view.type).length;
    return [view.id, defaults + drafts];
  }));
}

function currentView() {
  return VIEWS.find((view) => view.id === state.view) ?? VIEWS[0];
}

function recommendedQuestionDisposition(id) {
  const cut = new Set(["q5_mortgage", "q23_vehicle_count", "q24_vehicle_add", "q26_auto_insurance", "q29_estate_docs"]);
  const defer = new Set(["q16_electric", "q17_internet"]);
  const reshape = new Set(["q4_purchase", "q30_priorities"]);
  if (cut.has(id)) return { status: "cut", note: "Cut from homeowner first quiz." };
  if (defer.has(id)) return { status: "defer", note: "Move to optional setup after home operating plan." };
  if (reshape.has(id)) return { status: "reshape", note: "Keep the data only if reframed around operations." };
  return { status: "active", note: "Keep in first homeowner quiz." };
}

function classifyTask(row) {
  if (row.Category === "Handyman" || String(row.Bundle || "").startsWith("Handyman")) return "Handyman task";
  if (/Weekly|Biweekly|Monthly|Quarterly|Semi-annually/i.test(row.Frequency || "")) return "Recurring template";
  return "Task";
}

function dbItemToUi(row) {
  return {
    id: row.id,
    source: "admin",
    itemType: row.item_type,
    title: row.title,
    status: row.status,
    category: row.category ?? "",
    sortOrder: row.sort_order ?? 0,
    description: row.description ?? "",
    payload: row.payload ?? {},
    updatedAt: row.updated_at,
    // Phase 7.5 — launch lifecycle
    launchStatus: row.launch_status || "draft",
    lockedAt: row.locked_at || null,
    reviewedAt: row.reviewed_at || null,
    liveEntityId: row.live_entity_id || null,
  };
}

// Phase 7.5 — given a live item, find its admin_content_items shadow row.
function findLockShadow(item) {
  if (item?.source !== "live") return null;
  const liveId = liveEntityIdFor(item);
  if (!liveId) return null;
  return state.adminItems.find(
    (a) => a.itemType === item.itemType && a.liveEntityId === liveId
  );
}

function liveEntityIdFor(item) {
  return (
    item.payload?.id ||
    item.payload?.questionId ||
    item.payload?.templateKey ||
    item.payload?.stableId ||
    item.payload?.categoryKey ||
    item.payload?.functionName ||
    item.payload?.rawValue ||
    item.id
  );
}

function effectiveLaunchStatus(item) {
  if (item.source === "admin") return item.launchStatus || "draft";
  const shadow = findLockShadow(item);
  return shadow?.launchStatus || "draft";
}

function dbNoteToUi(row) {
  return {
    id: row.id,
    scopeType: row.scope_type,
    scopeId: row.scope_id,
    scopeTitle: row.scope_title,
    body: row.body,
    snapshot: row.snapshot ?? {},
    createdAt: row.created_at,
    intent: row.intent || "feedback",
    target: row.target || "claude",
    author: row.author || "tom",
    appliedAt: row.applied_at || null,
    appliedCommit: row.applied_commit || null,
    proposedDiff: row.proposed_diff ?? null,
    parentNoteId: row.parent_note_id ?? null,
    revertedAt: row.reverted_at ?? null,
    attachmentUrls: Array.isArray(row.attachment_urls) ? row.attachment_urls : [],
  };
}

function cleanEstateLanguage(value) {
  return String(value || "")
    .replace(/estate planning/gi, "home operations")
    .replace(/estate readiness/gi, "home readiness")
    .replace(/Estate/gi, "Home");
}

function splitPipe(value) {
  return String(value || "")
    .split("|")
    .map((x) => x.trim())
    .filter(Boolean);
}

function splitCsv(value) {
  return String(value || "")
    .split(",")
    .map((x) => x.trim())
    .filter(Boolean);
}

function parseJsonLoose(value) {
  try {
    return JSON.parse(value || "{}");
  } catch {
    return { raw: value };
  }
}

function slug(value) {
  return String(value || "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 60);
}

function readLocal(key) {
  try {
    return JSON.parse(localStorage.getItem(key) || "[]");
  } catch {
    return [];
  }
}

function writeLocal(key, value) {
  localStorage.setItem(key, JSON.stringify(value));
}

function structuredCloneSafe(value) {
  return JSON.parse(JSON.stringify(value ?? {}));
}

function formatDate(iso) {
  if (!iso) return "";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return iso;
  return date.toLocaleString(undefined, { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
}

function notesMarkdown() {
  const lines = [
    "# Codex Admin Notes",
    "",
    `Exported: ${new Date().toISOString()}`,
    "",
  ];
  for (const note of state.notes) {
    lines.push(`## ${note.scopeTitle || "General note"}`);
    lines.push("");
    lines.push(`- Type: ${note.scopeType || "general"}`);
    if (note.scopeId) lines.push(`- ID: ${note.scopeId}`);
    lines.push(`- Created: ${note.createdAt || ""}`);
    lines.push("");
    lines.push(note.body || "");
    lines.push("");
    lines.push("```json");
    lines.push(JSON.stringify(note.snapshot ?? {}, null, 2));
    lines.push("```");
    lines.push("");
  }
  return lines.join("\n");
}

function downloadText(filename, text) {
  const blob = new Blob([text], { type: "text/plain;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";
import {
  SCHEMAS,
  renderEntityForm,
  attachFormHandlers,
  computeProposedDiff,
  renderDiffStrip,
} from "/admin-forms.js";
import {
  openQuestionPreview,
  openQuizFlowPreview,
  closePreview,
} from "/admin-preview.js";

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
    title: "Handyman-Eligible Templates",
    eyebrow: "diyDefault + diyCapable + Handyman bundles",
    subtitle: "The subset of templates that flow into the punch-list / handyman visit path.",
    liveSource: "handyman-templates",
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
    id: "searches",
    label: "Searches",
    type: "search",
    title: "Search Builders (legacy)",
    eyebrow: "Provider and system search",
    subtitle: "Hand-curated search-surface defaults. Will fold into Vendors+Systems eventually.",
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
};

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
};

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
  el.previewQuestion?.addEventListener("click", () => {
    if (!state.selected || state.selected.itemType !== "question") return;
    openQuestionPreview(structuredCloneSafe(editingState.current ?? state.selected.payload), {
      index: indexOfSelectedQuestion(),
      total: state.liveData["quiz-questions"]?.entries?.length || 41,
    });
  });
  el.previewQuiz?.addEventListener("click", () => {
    const entries = state.liveData["quiz-questions"]?.entries || [];
    if (!entries.length) {
      alert("Quiz JSON not loaded yet. Run scripts/export_swift_admin_data.mjs and refresh.");
      return;
    }
    // Annotate each Q with note count for the flow listing.
    const annotated = entries.map((q) => ({
      ...q,
      _noteCount: state.notes.filter((n) => n.scopeType === "question" && (n.scopeId === q.id || n.scopeTitle === q.title))
        .length,
    }));
    openQuizFlowPreview(annotated);
    // Wire flow item clicks to open single-question preview.
    setTimeout(() => {
      document.querySelectorAll("[data-preview-question-id]").forEach((btn) => {
        btn.addEventListener("click", () => {
          const id = btn.dataset.previewQuestionId;
          const q = entries.find((entry) => entry.id === id);
          if (!q) return;
          closePreview();
          openQuestionPreview(q, { index: entries.findIndex((entry) => entry.id === id) + 1, total: entries.length });
        });
      });
    }, 60);
  });
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
    title: q.title || q.id,
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
    title: t.title,
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
    title: r.displayLabel || r.rawValue,
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
  handyman: (t, idx) => ({
    id: `live-handyman-${slug(t.templateKey)}`,
    source: "live",
    itemType: "handyman",
    title: t.title,
    status: t.isEssential ? "active" : "draft",
    category: t.bundleId || t.systemCategory,
    sortOrder: idx + 1,
    description: t.description || "",
    payload: t,
    lintCount: (t._lint || []).length,
  }),
  systems: (s, idx) => ({
    id: `live-system-${s.categoryKey}`,
    source: "live",
    itemType: "system",
    title: s.displayName || s.categoryKey,
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
  } else {
    renderList();
    renderDetail();
  }
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
      render();
    });
  });
}

function renderList() {
  const all = itemsForCurrentView();
  const filtered = filterItems(all);
  renderStats(all, filtered);
  el.list.innerHTML = filtered.map((item) => itemRowHtml(item)).join("") || emptyListHtml();
  el.list.querySelectorAll("[data-item-id]").forEach((button) => {
    button.addEventListener("click", () => {
      state.selected = all.find((item) => item.id === button.dataset.itemId) ?? null;
      renderList();
      renderDetail();
    });
  });
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
    el.duplicateItem.disabled = true;
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
    el.deleteItem.disabled = item.source !== "admin";
  }

  el.contextNote.value = "";
  renderContextNotes(item);
  el.saveNote.textContent = "Save note";
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

function renderNotesView() {
  el.stats.innerHTML = `
    <div class="admin-stat"><strong>${state.notes.length}</strong><span>Notes</span></div>
    <div class="admin-stat"><strong>${state.storageMode}</strong><span>Storage</span></div>
    <div class="admin-stat"><strong>${new Date().toLocaleDateString()}</strong><span>Today</span></div>
  `;
  el.list.innerHTML = state.notes.map((note) => `
    <button class="admin-list-item ${state.selected?.id === note.id ? "is-active" : ""}" data-note-id="${escapeHtml(note.id)}">
      <div class="admin-list-item__top">
        <strong>${escapeHtml(note.scopeTitle || "General note")}</strong>
        <span class="admin-pill">${escapeHtml(note.scopeType || "note")}</span>
      </div>
      <p>${escapeHtml(note.body).slice(0, 180)}</p>
      <div class="admin-list-item__meta">
        <span>${escapeHtml(formatDate(note.createdAt))}</span>
      </div>
    </button>
  `).join("") || emptyListHtml("No notes yet.");

  el.list.querySelectorAll("[data-note-id]").forEach((button) => {
    button.addEventListener("click", () => {
      state.selected = state.notes.find((note) => note.id === button.dataset.noteId) ?? null;
      renderNotesView();
    });
  });

  el.emptyDetail.classList.add("is-hidden");
  el.detail.classList.remove("is-hidden");
  const note = state.selected?.body ? state.selected : null;
  el.detailKind.textContent = "codex note";
  el.detailTitle.textContent = note?.scopeTitle || "Running notes";
  el.detailSubtitle.textContent = note ? formatDate(note.createdAt) : "Save a general note or export all notes as Markdown.";
  el.detailStatus.textContent = state.storageMode;
  el.detailStatus.dataset.tone = state.storageMode === "cloud" ? "active" : "defer";
  el.fieldTitle.value = note?.scopeTitle || "General admin note";
  el.fieldStatus.value = "active";
  el.fieldCategory.value = note?.scopeType || "general";
  el.fieldSort.value = "0";
  el.fieldDescription.value = note?.body || "";
  el.fieldPayload.value = JSON.stringify(note?.snapshot ?? { source: "admin-notes" }, null, 2);
  el.contextNote.value = "";
  el.contextNotes.innerHTML = "";
  el.promoteItem.disabled = true;
  el.duplicateItem.disabled = true;
  el.deleteItem.disabled = true;
  el.saveItem.textContent = "Save general note";
  el.saveNote.textContent = "Save note for Codex";
}

function renderContextNotes(item) {
  const notes = state.notes.filter((note) => itemNoteMatches(note, item)).slice(0, 8);
  if (!notes.length) {
    el.contextNotes.innerHTML = `
      <div class="admin-note-card">
        <strong>No notes on this item yet.</strong>
        <pre>Write one above. The note auto-captures the entity's full Swift configuration so Claude can act on it next session without re-exploring.</pre>
      </div>
    `;
    return;
  }
  el.contextNotes.innerHTML = notes.map((note) => {
    const intent = note.intent || "feedback";
    const author = note.author || "tom";
    const appliedPill = note.appliedAt
      ? `<span class="admin-pill" data-tone="active" title="Applied ${formatDate(note.appliedAt)}${
          note.appliedCommit ? " · " + note.appliedCommit.slice(0, 7) : ""
        }">applied</span>`
      : note.revertedAt
      ? `<span class="admin-pill" data-tone="cut">reverted</span>`
      : `<span class="admin-pill admin-pill--note">${intent}</span>`;
    const authorTag = author === "claude"
      ? `<span class="admin-pill admin-pill--note">claude</span>`
      : "";
    return `
      <article class="admin-note-card">
        <div class="admin-note-card__top">
          <strong>${escapeHtml(note.scopeTitle || "Context note")}</strong>
          ${appliedPill}
          ${authorTag}
        </div>
        <small>${escapeHtml(formatDate(note.createdAt))} · target: ${escapeHtml(note.target || "claude")}</small>
        <pre>${escapeHtml(note.body || "")}</pre>
      </article>
    `;
  }).join("");
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
  return `
    <button class="admin-list-item ${isActive ? "is-active" : ""}" data-item-id="${escapeHtml(item.id)}">
      <div class="admin-list-item__top">
        <strong>${escapeHtml(item.title)}</strong>
        <span class="admin-pill" data-tone="${escapeHtml(item.status)}">${escapeHtml(item.status)}</span>
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

function emptyListHtml(text = "Nothing matches this filter.") {
  return `<div class="admin-empty-detail" style="min-height:220px"><h3>${escapeHtml(text)}</h3></div>`;
}

function filterItems(items) {
  const q = state.search.trim().toLowerCase();
  return items.filter((item) => {
    if (state.statusFilter !== "all" && item.status !== state.statusFilter) return false;
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
  const full = {
    id: `note-${Date.now()}`,
    createdAt: new Date().toISOString(),
    intent: note.intent || "feedback",
    target: note.target || "claude",
    author: "tom",
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
  };
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

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
    id: "activity",
    label: "Activity",
    type: "activity",
    title: "Recent Activity",
    eyebrow: "Applied + reverted timeline",
    subtitle: "Every change Claude has shipped, in reverse-chronological order.",
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
};

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

function showShortcutHelp() {
  alert(
    [
      "Keyboard shortcuts",
      "",
      "/ — focus the search input",
      "Esc — clear search, then deselect, then close any open preview",
      "? — this help",
      "",
      "(More shortcuts coming — keyboard-only review pass is on the roadmap.)",
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
  } else if (state.view === "decisions") {
    renderDecisionsView();
  } else if (state.view === "activity") {
    renderActivityView();
  } else {
    renderList();
    renderDetail();
  }
  renderReadiness();
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

  // 3. Lint violations on un-approved live entities
  for (const surfaceId of surfaces) {
    const items = liveItemsForView(surfaceId) || [];
    for (const item of items) {
      const lintCount = item.lintCount || 0;
      const launch = effectiveLaunchStatus(item);
      if (lintCount > 0 && launch !== "approved" && launch !== "shipped") {
        queue.push({
          id: `lint-${surfaceId}-${item.id}`,
          severity: "lint",
          title: item.title,
          reason: `${lintCount} voice-lint hit${lintCount === 1 ? "" : "s"}.`,
          itemType: item.itemType,
          targetView: surfaceId,
          targetItem: item,
          recommendation: "Fix the voice issue, then lock as approved.",
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
  return `
    <button class="admin-list-item ${isActive ? "is-active" : ""}" data-item-id="${escapeHtml(item.id)}">
      <div class="admin-list-item__top">
        <strong>${escapeHtml(item.title)}</strong>
        <span class="admin-pill" data-tone="${escapeHtml(item.status)}">${escapeHtml(item.status)}</span>
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

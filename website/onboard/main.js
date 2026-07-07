// Chez onboarding capture app — entry point and screen router.
// Token-gated: ?session=<token> is the credential; the chez-onboard edge
// function validates it on every call. Flow:
//   token gate -> property confirm -> hub -> capture screens -> wrap up ->
//   submit -> success (or ingestion-error, which is still a saved visit).

import * as api from "./api.js";
import * as store from "./store.js";
import { el, toast, updateSyncBadge, wireSyncBadge } from "./ui.js";
import { initSystems } from "./capture-systems.js";
import { initSimple } from "./capture-simple.js";

// ---------- router ----------

const screenRenderers = {}; // name -> render fn, called on entry

function registerScreen(name, renderFn) {
  screenRenderers[name] = renderFn;
}

function goto(name) {
  for (const section of document.querySelectorAll("[data-screen]")) {
    section.hidden = section.dataset.screen !== name;
  }
  const render = screenRenderers[name];
  if (render) render();
  window.scrollTo(0, 0);
}

// Shared context handed to the capture modules.
const ctx = {
  goto,
  registerScreen,
  dictionaries: {},
  property: null,
  household: null,
  session: null,
};

// ---------- dead ends ----------

const DEADEND_COPY = {
  expired: {
    title: "This link has expired",
    message: "Ask Chez for a fresh one.",
  },
  revoked: {
    title: "This link is no longer active",
    message: "Ask Chez for a fresh one.",
  },
  unknown: {
    title: "This link is not quite right",
    message: "Ask Chez to send a new setup link.",
  },
  network: {
    title: "Could not reach Chez",
    message: "Check your connection, then reopen the link.",
  },
};

function deadEnd(kind) {
  const copy = DEADEND_COPY[kind] || DEADEND_COPY.unknown;
  document.getElementById("deadend-title").textContent = copy.title;
  document.getElementById("deadend-message").textContent = copy.message;
  goto("deadend");
}

// ---------- hub ----------

function renderHub() {
  const s = store.state;
  const counts = {
    systems: s.systems.length,
    contractors: s.contractors.length,
    routines: s.routines.length,
    utility_accounts: s.utility_accounts.length,
    quick_fixes: s.quick_fixes.length,
    recommendations: s.recommendations.length,
    household: (s.attributes && s.attributes.vendor_preference_tier) ? "✓" : "–",
  };
  for (const node of document.querySelectorAll("[data-count]")) {
    const key = node.dataset.count;
    if (key in counts) node.textContent = String(counts[key]);
  }
}

function wireHubTiles() {
  for (const btn of document.querySelectorAll("[data-goto]")) {
    btn.addEventListener("click", () => goto(btn.dataset.goto));
  }
}

// ---------- confirm screen ----------

function renderConfirm(bootstrap) {
  const p = bootstrap.property || {};
  const h = bootstrap.household || {};
  const a = bootstrap.assessment || {};

  document.getElementById("confirm-street").textContent = p.street || "This home";
  document.getElementById("confirm-citystate").textContent =
    [p.city, p.state].filter(Boolean).join(", ") + (p.zip_code ? " " + p.zip_code : "");

  const meta = document.getElementById("confirm-meta");
  meta.textContent = "";
  if (p.year_built) meta.append(el("span", {}, `Built ${p.year_built}`));
  if (p.square_footage) meta.append(el("span", {}, `${Number(p.square_footage).toLocaleString("en-US")} sq ft`));
  if (p.property_type) meta.append(el("span", {}, prettyPropertyType(p.property_type)));

  const owner = document.getElementById("confirm-owner");
  owner.textContent = h.homeowner_first_name
    ? `You are setting up ${h.homeowner_first_name}'s home.`
    : "You are setting up this homeowner's account.";

  const startBtn = document.getElementById("start-visit-btn");
  if (a.status === "in_progress") startBtn.textContent = "Continue visit";
}

function prettyPropertyType(t) {
  return String(t || "").replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

async function startVisit() {
  const btn = document.getElementById("start-visit-btn");
  btn.disabled = true;
  try {
    await api.call("start_visit", {});
    goto("hub");
  } catch (e) {
    if (e.code === "expired" || e.code === "revoked") return; // dead end already shown
    toast("Could not start the visit. Try again.");
  } finally {
    btn.disabled = false;
  }
}

// ---------- wrap up ----------

function renderWrapUp() {
  const s = store.state;
  const summary = document.getElementById("wrapup-summary");
  summary.textContent = "";
  const rows = [
    ["Systems captured", s.systems.length],
    ["Vendors captured", s.contractors.length],
    ["Routines captured", s.routines.length],
    ["Utilities captured", s.utility_accounts.length],
    ["Household details", (s.attributes && s.attributes.vendor_preference_tier) ? "Done" : "Not yet"],
    ["Quick fixes logged", s.quick_fixes.length],
    ["Follow-ups", s.recommendations.length],
  ];
  for (const [label, value] of rows) {
    summary.append(el("div", { class: "ob-summary-row" },
      el("span", {}, label),
      el("span", { class: "ob-summary-count" }, String(value)),
    ));
  }

  const concerns = document.getElementById("wrapup-concerns");
  concerns.value = s.concerns || "";
}

function wireWrapUp() {
  const concerns = document.getElementById("wrapup-concerns");
  concerns.addEventListener("change", () => {
    store.state.concerns = concerns.value;
    store.saveSection("concerns");
  });
  document.getElementById("submit-visit-btn").addEventListener("click", submitVisit);
}

let submitting = false;

async function submitVisit() {
  if (submitting) return;
  submitting = true;
  const btn = document.getElementById("submit-visit-btn");
  btn.disabled = true;
  btn.textContent = "Submitting…";
  try {
    // Flush the concerns field even without a blur, then drain the queue.
    const concerns = document.getElementById("wrapup-concerns");
    if ((concerns.value || "") !== (store.state.concerns || "")) {
      store.state.concerns = concerns.value;
      await store.saveSection("concerns");
    }
    const synced = await store.syncNow();
    if (!synced) {
      toast("Some captures have not synced yet. Check your connection and try again.");
      return;
    }

    const res = await api.call("submit", {}, { timeoutMs: 120000 });
    if (res.ok) {
      if (res.awaiting_review) {
        document.getElementById("success-message").textContent =
          "Chez will review everything captured and finish the setup. The homeowner gets the reveal in their app.";
      }
      goto("success");
    } else {
      // Submitted and saved server-side; ingestion will be finished by Chez.
      goto("ingest-error");
    }
  } catch (e) {
    if (e.code === "expired" || e.code === "revoked") return; // dead end shown
    if (e.status === 409) {
      goto("submitted");
      return;
    }
    toast(e.code === "network"
      ? "No connection. Everything is saved on this phone. Try again in a minute."
      : "Could not submit yet. Try again.");
  } finally {
    submitting = false;
    btn.disabled = false;
    btn.textContent = "Submit visit";
  }
}

// ---------- boot ----------

async function boot() {
  const token = new URLSearchParams(window.location.search).get("session");
  if (!token) {
    deadEnd("unknown");
    return;
  }

  api.init(token, (kind) => deadEnd(kind));
  store.init(token);

  registerScreen("hub", renderHub);
  registerScreen("wrapup", renderWrapUp);
  initSystems(ctx);
  initSimple(ctx);

  wireHubTiles();
  wireWrapUp();
  document.getElementById("start-visit-btn").addEventListener("click", startVisit);
  wireSyncBadge(async () => {
    toast("Syncing…", 1200);
    const ok = await store.syncNow();
    toast(ok ? "Everything is synced." : "Still waiting on a connection. Your work is saved on this phone.");
  });

  store.subscribe(() => {
    // Keep hub counts live whenever it is the visible screen.
    const hub = document.querySelector('[data-screen="hub"]');
    if (hub && !hub.hidden) renderHub();
  });

  let bootstrap;
  try {
    bootstrap = await api.call("bootstrap", {});
  } catch (e) {
    if (e.code === "expired" || e.code === "revoked" || e.code === "unknown") return; // dead end shown
    deadEnd("network");
    return;
  }

  ctx.dictionaries = bootstrap.dictionaries || {};
  ctx.property = bootstrap.property || null;
  ctx.household = bootstrap.household || null;
  ctx.session = bootstrap.session || null;

  store.mergeBootstrap(bootstrap.assessment || {});
  updateSyncBadge(store.pendingCount());

  const assessmentStatus = (bootstrap.assessment && bootstrap.assessment.status) || "pending";
  if (assessmentStatus !== "pending" && assessmentStatus !== "in_progress") {
    // Already submitted (or ingestion failed after submit) — capture is closed.
    goto("submitted");
    return;
  }

  renderConfirm(bootstrap);
  goto("confirm");
}

boot();

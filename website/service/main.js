// main.js — boot orchestration for the Chez service portal (service.html).
//
// Owns: auth flow (login card, admin-403 gate), the fetch_service_boot
// bootstrap, the nav rail, the hash router (+ the ?case= deep-link shim),
// the Cmd+K queue palette, and the honest "next phase" stubs for
// Homes / Visits / Vendors / Ops.
//
// The case view is a sibling deliverable at ./views/case/index.js exporting
// `enter(requestId)` / `leave()`. It's imported lazily inside the route so
// this half of the portal stays testable standalone; a missing module
// surfaces as a toast instead of a crash.

import { initAuth, currentUser, signIn, signOut, callConcierge, ApiError } from "./api.js";
import { state, setState } from "./state.js";
import { zone, invalidate, esc } from "./render.js";
import * as router from "./router.js";
import { bindShortcuts } from "./actions.js";
import { uiGet } from "./storage.js";
import { toast } from "./components/toast.js";
import { slaPill } from "./components/pills.js";
import { truncate } from "./lib/format.js";
import * as todayView from "./views/today.js";

// ── Element handles (static shell in service.html) ──────────────────────────

const el = {
  loading: document.querySelector("[data-svc-loading]"),
  login: document.querySelector("[data-svc-login]"),
  loginForm: document.querySelector("[data-svc-login-form]"),
  loginEmail: document.querySelector("[data-svc-login-email]"),
  loginPassword: document.querySelector("[data-svc-login-password]"),
  loginFeedback: document.querySelector("[data-svc-login-feedback]"),
  loginSubmit: document.querySelector("[data-svc-login-submit]"),
  gate: document.querySelector("[data-svc-gate]"),
  gateTitle: document.querySelector("[data-svc-gate-title]"),
  gateBody: document.querySelector("[data-svc-gate-body]"),
  gateAction: document.querySelector("[data-svc-gate-action]"),
  app: document.querySelector("[data-svc-app]"),
  appShell: document.querySelector(".svc-app"),
  nav: document.querySelector("[data-svc-nav]"),
  sessionEmail: document.querySelector("[data-svc-session-email]"),
  signOutBtn: document.querySelector("[data-svc-sign-out]"),
  view: document.getElementById("svc-view"),
};

function showOnly(which) {
  el.loading.hidden = which !== "loading";
  el.login.hidden = which !== "login";
  el.gate.hidden = which !== "gate";
  el.app.hidden = which !== "app";
}

let gateHandler = null;
function showGate({ title, body, actionLabel, onAction }) {
  el.gateTitle.textContent = title;
  el.gateBody.textContent = body;
  el.gateAction.textContent = actionLabel;
  gateHandler = onAction;
  showOnly("gate");
}
el.gateAction.addEventListener("click", () => gateHandler?.());

// ── Nav rail ────────────────────────────────────────────────────────────────
// Phase A: Today + Cases are live. Homes / Visits / Vendors / Ops are honest
// stubs (a real view that says the work lands in the next phase) so nothing
// on this rail is a dead button.

const ICONS = {
  today:
    '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"><circle cx="8" cy="8" r="3.1"/><path d="M8 1.6v1.6M8 12.8v1.6M1.6 8h1.6M12.8 8h1.6M3.5 3.5l1.1 1.1M11.4 11.4l1.1 1.1M12.5 3.5l-1.1 1.1M4.6 11.4l-1.1 1.1"/></svg>',
  cases:
    '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"><path d="M2.2 3.6h11.6v7H7.4l-3 2.6v-2.6H2.2z"/></svg>',
  homes:
    '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"><path d="M2.4 7.6 8 2.8l5.6 4.8M3.8 6.8v6h8.4v-6"/></svg>',
  visits:
    '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"><rect x="2.2" y="3.2" width="11.6" height="10" rx="1.5"/><path d="M2.2 6.4h11.6M5.4 1.8v2.4M10.6 1.8v2.4"/></svg>',
  vendors:
    '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"><rect x="2.2" y="5.2" width="11.6" height="8" rx="1.5"/><path d="M5.6 5.2V3.8a1.6 1.6 0 0 1 1.6-1.6h1.6a1.6 1.6 0 0 1 1.6 1.6v1.4M2.2 8.6h11.6"/></svg>',
  ops:
    '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M1.8 8.4h2.6l1.8-4.2 3.4 7.6 1.8-3.4h2.8"/></svg>',
};

const NAV = [
  { id: "today", label: "Today", hash: "#/today", live: true },
  { id: "cases", label: "Cases", hash: "#/cases", live: true },
  { id: "homes", label: "Homes", hash: "#/homes", live: false },
  { id: "visits", label: "Visits", hash: "#/visits", live: false },
  { id: "vendors", label: "Vendors", hash: "#/vendors", live: false },
  { id: "ops", label: "Ops", hash: "#/ops", live: false },
];

function navActiveId() {
  const hash = location.hash || "#/today";
  if (hash === "#/cases" || hash.startsWith("#/case/")) return "cases";
  const hit = NAV.find((n) => n.hash === hash);
  return hit ? hit.id : "today";
}

function renderNav() {
  const activeId = navActiveId();
  const unread = state.queue.filter((q) => q.unread_for_admin).length;
  const item = (n) => `
    <a class="svc-rail__item${n.id === activeId ? " is-active" : ""}" href="${n.hash}">
      <span class="svc-rail__icon" aria-hidden="true">${ICONS[n.id] || ""}</span>
      <span class="svc-rail__label">${n.label}</span>
      ${n.id === "cases" && unread > 0 ? `<span class="svc-rail__badge">${unread}</span>` : ""}
      ${n.live ? "" : '<span class="svc-rail__soon">Soon</span>'}
    </a>
  `;
  const live = NAV.filter((n) => n.live).map(item).join("");
  const next = NAV.filter((n) => !n.live).map(item).join("");
  return `
    ${live}
    <div class="svc-rail__divider" role="presentation"></div>
    ${next}
  `;
}

// ── Stub views (capability gating, not dead chrome) ─────────────────────────

const STUB_COPY = {
  homes: "Every household Chez manages, with standing instructions, coverage, and the full entity picture.",
  visits: "The visit calendar across every home, with completion and no-show tracking.",
  vendors: "The cross-household vendor registry: answer rates, quotes, jobs won.",
  ops: "Response times, effort per case, and how the desk is running.",
};

function stubRoute(id, label) {
  return {
    pattern: `#/${id}`,
    enter() {
      el.view.innerHTML = `
        <div class="svc-stub">
          <div class="svc-stub__card">
            <p class="svc-eyebrow">Coming in the next phase</p>
            <h2 class="svc-stub__title">${label}</h2>
            <p class="svc-stub__body">${STUB_COPY[id] || ""}</p>
            <p class="svc-stub__note">Until it lands here, this work lives in the <a href="/admin.html">admin portal</a>.</p>
          </div>
        </div>
      `;
    },
    leave() {
      el.view.innerHTML = "";
    },
  };
}

// ── Case view (lazy; built by the case agent against the same contract) ─────

let caseModule = null;

async function loadCaseModule() {
  if (caseModule) return caseModule;
  caseModule = await import("./views/case/index.js");
  return caseModule;
}

async function enterCase(requestId) {
  // #/cases with no id falls back to the active case, then the top of the
  // queue; a null target is legal (queue rail + empty workspace).
  const target = requestId ?? state.activeCaseId ?? state.queue[0]?.id ?? null;
  let mod;
  try {
    mod = await loadCaseModule();
  } catch (err) {
    caseModule = null; // don't cache the failure; retry on the next visit
    console.warn("[svc] case view module missing or failed to load", err);
    toast("Case view unavailable", "error");
    return;
  }
  try {
    await mod.enter(target);
  } catch (err) {
    console.error("[svc] case enter failed", err);
    toast("Couldn't open the case.", "error");
  }
}

function leaveCase() {
  try {
    caseModule?.leave();
  } catch (err) {
    console.error("[svc] case leave failed", err);
  }
}

// ── Command palette (Cmd+K): search the queue, Enter jumps ──────────────────

let palette = null;

function openPalette() {
  if (palette) return;
  if (!state.queue.length) {
    toast("No open cases to search yet.");
    return;
  }
  const wrap = document.createElement("div");
  wrap.className = "svc-palette";
  wrap.innerHTML = `
    <div class="svc-palette__scrim" data-palette-scrim></div>
    <div class="svc-palette__panel" role="dialog" aria-modal="true" aria-label="Search cases">
      <input class="svc-palette__input" data-palette-input type="text"
             placeholder="Search cases by home, summary, or category…"
             autocomplete="off" spellcheck="false" />
      <div class="svc-palette__results" data-palette-results></div>
      <p class="svc-palette__hint">&#8593;&#8595; to move &middot; Enter opens &middot; Esc closes</p>
    </div>
  `;
  document.body.appendChild(wrap);
  document.body.classList.add("svc-modal-open"); // reuse shortcut suppression

  const input = wrap.querySelector("[data-palette-input]");
  const results = wrap.querySelector("[data-palette-results]");
  let matches = [];
  let activeIdx = 0;

  const catLabel = (c) =>
    ({ find_vendor: "find a vendor", get_quote: "get a quote", schedule_visit: "schedule a visit",
       coordinate_task: "coordinate a task", find_handyman: "find a handyman", general: "general help" }[c] || c || "");

  const filter = () => {
    const q = input.value.trim().toLowerCase();
    matches = state.queue
      .filter((r) => {
        if (!q) return true;
        return [r.household_name, r.summary, catLabel(r.category), r.id]
          .some((f) => (f || "").toLowerCase().includes(q));
      })
      .slice(0, 12);
    activeIdx = 0;
    paint();
  };

  const paint = () => {
    if (!matches.length) {
      results.innerHTML = '<p class="svc-palette__empty">No matching cases.</p>';
      return;
    }
    results.innerHTML = matches
      .map(
        (r, i) => `
        <div class="svc-palette__item${i === activeIdx ? " is-active" : ""}" data-palette-id="${esc(r.id)}">
          <span class="svc-palette__who">${esc(r.household_name || "Household")}</span>
          <span class="svc-palette__what">${esc(truncate(r.summary, 64))}</span>
          <span class="svc-palette__spacer"></span>
          ${slaPill(r)}
        </div>`
      )
      .join("");
  };

  const close = () => {
    wrap.remove();
    document.body.classList.remove("svc-modal-open");
    palette = null;
  };

  input.addEventListener("input", filter);
  input.addEventListener("keydown", (e) => {
    if (e.key === "Escape") { e.preventDefault(); close(); }
    else if (e.key === "ArrowDown") { e.preventDefault(); activeIdx = Math.min(activeIdx + 1, matches.length - 1); paint(); }
    else if (e.key === "ArrowUp") { e.preventDefault(); activeIdx = Math.max(activeIdx - 1, 0); paint(); }
    else if (e.key === "Enter") {
      e.preventDefault();
      const hit = matches[activeIdx];
      if (hit) { close(); router.navigate(`#/case/${encodeURIComponent(hit.id)}`); }
    }
  });
  results.addEventListener("click", (e) => {
    const item = e.target.closest("[data-palette-id]");
    if (!item) return;
    const id = item.dataset.paletteId;
    close();
    router.navigate(`#/case/${encodeURIComponent(id)}`);
  });
  wrap.querySelector("[data-palette-scrim]").addEventListener("click", close);

  palette = { close };
  filter();
  input.focus();
}

// ── Boot ────────────────────────────────────────────────────────────────────

let routerStarted = false;
let shellMounted = false;

function applyCaseShim() {
  // chez-concierge emails/pushes deep-link as service.html?case=<id>;
  // translate to the hash route before the router's first dispatch.
  const params = new URLSearchParams(location.search);
  const caseId = params.get("case");
  if (!caseId) return;
  history.replaceState(null, "", `${location.pathname}#/case/${encodeURIComponent(caseId)}`);
}

function mountShell() {
  el.sessionEmail.textContent = state.user?.email || "";
  el.appShell.dataset.density = state.ui.density === "compact" ? "compact" : "normal";
  zone("nav", el.nav, renderNav);
  if (shellMounted) return;
  shellMounted = true;
  el.signOutBtn.addEventListener("click", async () => {
    try {
      await signOut();
    } catch (err) {
      console.warn("[svc] sign out failed", err);
    }
    // Full reload: tears down views, zones, shortcut maps, and any in-flight
    // state in one move. Operators sign out rarely; simplicity wins.
    location.replace(location.pathname);
  });
  window.addEventListener("hashchange", () => invalidate("nav"));
}

function startRouter() {
  if (routerStarted) return;
  routerStarted = true;
  router.start(
    [
      { pattern: "#/today", enter: () => todayView.enter(), leave: () => todayView.leave() },
      { pattern: "#/cases", enter: () => enterCase(null), leave: () => leaveCase() },
      { pattern: "#/case/:id", enter: (p) => enterCase(p.id), leave: () => leaveCase() },
      stubRoute("homes", "Homes"),
      stubRoute("visits", "Visits"),
      stubRoute("vendors", "Vendors"),
      stubRoute("ops", "Ops"),
    ],
    () => router.navigate("#/today")
  );
  bindShortcuts({ "Meta+k": () => openPalette() });
}

async function enterApp() {
  showOnly("loading");
  let boot;
  try {
    boot = await callConcierge("fetch_service_boot");
  } catch (err) {
    if (err instanceof ApiError && err.status === 403) {
      try {
        await signOut();
      } catch {
        /* best effort */
      }
      showGate({
        title: "This portal is for the Chez operator.",
        body: "That account signed in fine, but it isn't on the operator allowlist, so the desk stays closed.",
        actionLabel: "Back to sign in",
        onAction: () => {
          el.loginFeedback.textContent = "";
          showOnly("login");
        },
      });
      return;
    }
    console.error("[svc] boot failed", err);
    showGate({
      title: "The desk didn't answer.",
      body: `${err.message || err} Give it another try in a moment.`,
      actionLabel: "Try again",
      onAction: () => enterApp(),
    });
    return;
  }

  setState({
    user: currentUser(),
    boot,
    queue: Array.isArray(boot.queue) ? boot.queue : [],
    ui: { ...state.ui, ...uiGet() },
  });
  showOnly("app");
  mountShell();
  applyCaseShim();
  startRouter();
  invalidate("nav");
}

async function handleLoginSubmit(event) {
  event.preventDefault();
  const email = el.loginEmail.value.trim().toLowerCase();
  const password = el.loginPassword.value;
  if (!email || !password) {
    el.loginFeedback.textContent = "Enter your email and password.";
    return;
  }
  el.loginFeedback.textContent = "Signing in…";
  el.loginSubmit.disabled = true;
  try {
    await signIn(email, password);
    el.loginPassword.value = "";
    el.loginFeedback.textContent = "";
    await enterApp();
  } catch (err) {
    el.loginFeedback.textContent = err.message || "Sign in failed. Try again.";
  } finally {
    el.loginSubmit.disabled = false;
  }
}

async function boot() {
  el.loginForm.addEventListener("submit", handleLoginSubmit);
  showOnly("loading");
  let user = null;
  try {
    user = await initAuth();
  } catch (err) {
    console.error("[svc] auth init failed", err);
    showGate({
      title: "The desk didn't answer.",
      body: "Couldn't reach the sign-in service. Check the connection and try again.",
      actionLabel: "Try again",
      onAction: () => location.reload(),
    });
    return;
  }
  if (!user) {
    showOnly("login");
    return;
  }
  await enterApp();
}

boot();

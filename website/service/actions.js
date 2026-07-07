// actions.js — delegated action dispatch + global keyboard shortcuts.
//
// Contract (SERVICE_PORTAL_CONTRACT.md):
//   bindActions(rootEl, table) — ONE click + ONE keydown(Enter/Space)
//     listener on rootEl; dispatches to
//     table[el.closest('[data-action]').dataset.action](el, event).
//     Event handlers are never inline in HTML; every interactive element
//     carries data-action and routes through a dispatch table.
//   bindShortcuts(map) — global keydown: {"j": fn, "Meta+k": fn, ...}.
//     Ignores keystrokes while focus is in input/textarea/select/
//     contenteditable. Also suppressed while a modal is open (modal.js puts
//     `svc-modal-open` on <body>) so j/k never move the queue behind a
//     dialog. "Ctrl" is treated as "Meta" so ⌘K bindings work off-Mac.
//
// Both functions return a dispose() for view teardown. Later bindShortcuts
// maps win on key conflicts (last bound, first served).

function isTypingContext(el) {
  if (!el || !(el instanceof Element)) return false;
  const tag = el.tagName;
  if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return true;
  if (el.isContentEditable) return true;
  return false;
}

export function bindActions(rootEl, table) {
  if (!rootEl) return () => {};
  const dispatch = (event) => {
    const target = event.target instanceof Element ? event.target.closest("[data-action]") : null;
    if (!target || !rootEl.contains(target)) return null;
    const fn = table[target.dataset.action];
    if (!fn) {
      console.warn(`[actions] no handler for "${target.dataset.action}"`);
      return null;
    }
    return { fn, target };
  };

  const onClick = (event) => {
    const hit = dispatch(event);
    if (!hit) return;
    try {
      hit.fn(hit.target, event);
    } catch (err) {
      console.error(`[actions] "${hit.target.dataset.action}" failed`, err);
    }
  };

  const onKeydown = (event) => {
    if (event.key !== "Enter" && event.key !== " ") return;
    if (isTypingContext(event.target)) return;
    const hit = dispatch(event);
    if (!hit) return;
    // Native buttons/links already synthesize a click on Enter/Space;
    // dispatching here too would double-fire.
    const tag = hit.target.tagName;
    if (tag === "BUTTON" || tag === "A") return;
    event.preventDefault();
    try {
      hit.fn(hit.target, event);
    } catch (err) {
      console.error(`[actions] "${hit.target.dataset.action}" failed`, err);
    }
  };

  rootEl.addEventListener("click", onClick);
  rootEl.addEventListener("keydown", onKeydown);
  return () => {
    rootEl.removeEventListener("click", onClick);
    rootEl.removeEventListener("keydown", onKeydown);
  };
}

// ── Global shortcuts ────────────────────────────────────────────────────────

const registry = [];
let installed = false;

function normalizeCombo(spec) {
  const parts = String(spec).split("+").map((p) => p.trim()).filter(Boolean);
  const key = parts.pop() || "";
  const mods = new Set(parts.map((p) => p.toLowerCase()));
  const out = [];
  if (mods.has("meta") || mods.has("cmd") || mods.has("ctrl")) out.push("Meta");
  if (mods.has("alt") || mods.has("option")) out.push("Alt");
  if (mods.has("shift")) out.push("Shift");
  out.push(key.length === 1 ? key.toLowerCase() : key);
  return out.join("+");
}

function comboOf(event) {
  const out = [];
  if (event.metaKey || event.ctrlKey) out.push("Meta");
  if (event.altKey) out.push("Alt");
  if (event.shiftKey && event.key.length === 1) out.push("Shift");
  out.push(event.key.length === 1 ? event.key.toLowerCase() : event.key);
  return out.join("+");
}

function onGlobalKeydown(event) {
  if (isTypingContext(document.activeElement) || isTypingContext(event.target)) return;
  if (document.body.classList.contains("svc-modal-open")) return;
  const combo = comboOf(event);
  for (let i = registry.length - 1; i >= 0; i--) {
    const fn = registry[i].map[combo];
    if (fn) {
      event.preventDefault();
      try {
        fn(event);
      } catch (err) {
        console.error(`[shortcuts] "${combo}" failed`, err);
      }
      return;
    }
  }
}

export function bindShortcuts(map) {
  const normalized = {};
  for (const [spec, fn] of Object.entries(map || {})) {
    normalized[normalizeCombo(spec)] = fn;
  }
  const entry = { map: normalized };
  registry.push(entry);
  if (!installed) {
    installed = true;
    window.addEventListener("keydown", onGlobalKeydown);
  }
  return () => {
    const i = registry.indexOf(entry);
    if (i >= 0) registry.splice(i, 1);
  };
}

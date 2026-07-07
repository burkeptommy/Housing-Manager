// components/modal.js — dialog primitive for the Chez service portal.
//
// Contract: openModal({ title, bodyHtml, actions: [{label, kind, onClick}],
// onClose }) -> { close, el }. ESC and a backdrop click both close.
//
// Behavior notes for consumers (views/case/resolve.js etc.):
//   - `el` is the dialog panel (query your form fields off it).
//   - Action buttons do NOT auto-close when they have an onClick; the
//     handler receives ({ close, el }, event) and closes explicitly, so
//     async submits can validate and keep the dialog open on failure.
//   - An action WITHOUT onClick just closes (use it for Cancel).
//   - kind: "primary" (purple CTA) | "danger" | anything else -> neutral.
//   - While any modal is open, <body> carries `svc-modal-open`; actions.js
//     suppresses global shortcuts off that class.

import { esc } from "../render.js";

let openCount = 0;

export function openModal({ title = "", bodyHtml = "", actions = [], onClose } = {}) {
  const backdrop = document.createElement("div");
  backdrop.className = "svc-modal-backdrop";
  backdrop.innerHTML = `
    <div class="svc-modal" role="dialog" aria-modal="true"${title ? ` aria-label="${esc(title)}"` : ""}>
      <header class="svc-modal__head">
        <h3 class="svc-modal__title">${esc(title)}</h3>
        <button type="button" class="svc-modal__x" data-modal-x aria-label="Close">&times;</button>
      </header>
      <div class="svc-modal__body">${bodyHtml}</div>
      ${actions.length ? '<footer class="svc-modal__actions" data-modal-actions></footer>' : ""}
    </div>
  `;

  const el = backdrop.querySelector(".svc-modal");
  let closed = false;

  const close = () => {
    if (closed) return;
    closed = true;
    document.removeEventListener("keydown", onKeydown, true);
    backdrop.remove();
    openCount = Math.max(0, openCount - 1);
    if (openCount === 0) document.body.classList.remove("svc-modal-open");
    try {
      onClose?.();
    } catch (err) {
      console.error("[modal] onClose failed", err);
    }
  };

  const api = { close, el };

  const onKeydown = (event) => {
    if (event.key !== "Escape") return;
    // Only the top-most modal responds to ESC.
    const all = document.querySelectorAll(".svc-modal-backdrop");
    if (all.length && all[all.length - 1] !== backdrop) return;
    event.preventDefault();
    close();
  };

  backdrop.addEventListener("mousedown", (event) => {
    if (event.target === backdrop) close();
  });
  backdrop.querySelector("[data-modal-x]").addEventListener("click", close);
  document.addEventListener("keydown", onKeydown, true);

  const footer = backdrop.querySelector("[data-modal-actions]");
  if (footer) {
    for (const action of actions) {
      const btn = document.createElement("button");
      btn.type = "button";
      const kindClass =
        action.kind === "primary"
          ? " svc-btn--primary"
          : action.kind === "danger"
            ? " svc-btn--danger"
            : "";
      btn.className = `svc-btn${kindClass}`;
      btn.textContent = action.label ?? "OK";
      btn.addEventListener("click", (event) => {
        if (typeof action.onClick === "function") {
          try {
            action.onClick(api, event);
          } catch (err) {
            console.error("[modal] action failed", err);
          }
        } else {
          close();
        }
      });
      footer.appendChild(btn);
    }
  }

  document.body.appendChild(backdrop);
  openCount += 1;
  document.body.classList.add("svc-modal-open");

  // Focus the first focusable control so keyboard flow starts inside.
  const focusable = el.querySelector(
    "input, textarea, select, button:not([data-modal-x])"
  );
  (focusable || el.querySelector("[data-modal-x]"))?.focus();

  return api;
}

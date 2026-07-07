// Service portal v2 - case view: reply composer zone.
//
// Draft persists to the per-case scratchpad (debounced 300ms) so a reload
// or case switch never loses typed work. Typing NEVER invalidates this
// zone (render-rule discipline); the snippet popover inside it is updated
// imperatively instead.
//
// Send fires the verified reply payload:
//   { action: "reply", request_id, content, acknowledgement_required, to_status? }
// and appends the message optimistically before the server confirms.

import { invalidate, esc } from "../../render.js";
import { state } from "../../state.js";
import { callConcierge } from "../../api.js";
import { scratchGet, scratchSet } from "../../storage.js";
import { toast } from "../../components/toast.js";
import { truncate } from "../../lib/format.js";
import { scrollThreadToBottom } from "./thread.js";
import { markWaiting, reopenCase } from "./resolve.js";
import { queueCaseEvent } from "./index.js";

let sending = false;
let draftTimer = null;
let snip = { open: false, query: "", sel: 0 };

function activeId() {
  return state.activeCaseId;
}

function activeBundle() {
  const id = activeId();
  return id ? state.cases[id] : null;
}

function composerInput() {
  return document.querySelector("[data-composer-input]");
}

export function resetComposerFor() {
  sending = false;
  snip = { open: false, query: "", sel: 0 };
  if (draftTimer) {
    clearTimeout(draftTimer);
    draftTimer = null;
  }
}

// ---------------------------------------------------------------------------
// Zone render
// ---------------------------------------------------------------------------

export function renderComposerZone() {
  const id = activeId();
  const bundle = activeBundle();
  if (!id) return "";

  const request = bundle && bundle.request ? bundle.request : null;
  const status = request ? request.status : null;

  if (status === "resolved") {
    return `
      <div class="svc-composer svc-composer--locked">
        <span>This case is resolved. Reopen it to reply.</span>
        <button type="button" class="svc-btn svc-btn--small" data-action="composer-reopen">Reopen</button>
      </div>
    `;
  }

  const scratch = scratchGet(id) || {};
  const draft = typeof scratch.composerDraft === "string" ? scratch.composerDraft : "";
  const ack = !!scratch.ackRequired;
  const disabled = !request || sending;
  const waitingLabel = status === "waiting_customer" ? "Resume this case" : "Mark waiting on homeowner";

  return `
    <div class="svc-composer">
      <div class="svc-snip" data-snip hidden></div>
      <textarea
        class="svc-textarea svc-composer__input"
        data-composer-input
        rows="3"
        placeholder="Reply as Chez. Type / for snippets."
        ${!request ? "disabled" : ""}
      >${esc(draft)}</textarea>
      <div class="svc-composer__bar">
        <label class="svc-check" title="Routes the reply into the homeowner's Needs Action inbox">
          <input type="checkbox" data-composer-ack ${ack ? "checked" : ""} ${disabled ? "disabled" : ""} />
          <span>Needs homeowner reply</span>
        </label>
        <select class="svc-select" data-composer-status ${disabled ? "disabled" : ""} title="What the case becomes after this reply">
          <option value="">Keep open</option>
          <option value="waiting_customer">Waiting on homeowner</option>
        </select>
        <button type="button" class="svc-btn svc-btn--ghost svc-btn--small" data-action="composer-toggle-waiting" ${disabled ? "disabled" : ""}>${esc(waitingLabel)}</button>
        <button type="button" class="svc-btn svc-btn--primary" data-action="composer-send" ${disabled ? "disabled" : ""} title="Send (Cmd+Enter)">${sending ? "Sending..." : "Send"}</button>
      </div>
    </div>
  `;
}

// ---------------------------------------------------------------------------
// Snippet picker ("/" at the start of an empty composer)
// ---------------------------------------------------------------------------

function snippetSource() {
  const boot = state.boot;
  return boot && Array.isArray(boot.snippets) ? boot.snippets : [];
}

function filteredSnippets() {
  const q = snip.query.toLowerCase();
  return snippetSource()
    .filter((s) => s && (s.slug || s.label || s.body))
    .filter((s) => !q
      || String(s.slug || "").toLowerCase().includes(q)
      || String(s.label || "").toLowerCase().includes(q))
    .slice(0, 8);
}

function renderSnippetPop() {
  const pop = document.querySelector("[data-snip]");
  if (!pop) return;
  if (!snip.open) {
    pop.hidden = true;
    pop.innerHTML = "";
    return;
  }
  const items = filteredSnippets();
  if (snip.sel >= items.length) snip.sel = Math.max(0, items.length - 1);
  pop.hidden = false;
  if (items.length === 0) {
    pop.innerHTML = `<div class="svc-snip__empty">No snippets match "/${esc(snip.query)}". Keep typing your reply.</div>`;
    return;
  }
  pop.innerHTML = `
    <div class="svc-snip__hint">Snippets. Arrows to move, Enter to insert.</div>
    ${items.map((s, i) => `
      <button type="button" class="svc-snip__item ${i === snip.sel ? "is-sel" : ""}" data-action="snip-pick" data-snip-id="${esc(s.id || "")}">
        <span class="svc-snip__slug">/${esc(s.slug || "snippet")}</span>
        <span class="svc-snip__label">${esc(s.label || "")}</span>
        <span class="svc-snip__preview">${esc(truncate(String(s.body || ""), 60))}</span>
      </button>
    `).join("")}
  `;
}

function closeSnippets() {
  if (!snip.open) return;
  snip = { open: false, query: "", sel: 0 };
  renderSnippetPop();
}

function insertSnippet(snippet) {
  const input = composerInput();
  const id = activeId();
  if (!input || !snippet || !id) return;
  input.value = String(snippet.body || "");
  input.focus();
  input.setSelectionRange(input.value.length, input.value.length);
  saveDraftNow(id, input.value);
  closeSnippets();
  if (snippet.id) {
    // Fire and forget: use tracking must never block the composer.
    callConcierge("record_snippet_use", { snippet_id: snippet.id }).catch(() => {});
  }
}

export function pickSnippet(snippetId) {
  const snippet = snippetSource().find((s) => s && s.id === snippetId);
  if (snippet) insertSnippet(snippet);
}

// ---------------------------------------------------------------------------
// Draft persistence
// ---------------------------------------------------------------------------

function saveDraftNow(id, value) {
  if (!id) return;
  scratchSet(id, { composerDraft: value });
}

/// Called by index.js on leave so a pending debounce never loses the tail
/// of a draft.
export function flushDraft(id) {
  if (draftTimer) {
    clearTimeout(draftTimer);
    draftTimer = null;
  }
  const input = composerInput();
  if (input && id) saveDraftNow(id, input.value);
}

// ---------------------------------------------------------------------------
// Delegated event handlers (wired by index.js at the view shell)
// ---------------------------------------------------------------------------

export function handleComposerInput(target) {
  const id = activeId();
  if (!id) return;

  if (target.matches("[data-composer-ack]")) {
    scratchSet(id, { ackRequired: !!target.checked });
    return;
  }
  if (!target.matches("[data-composer-input]")) return;

  const value = target.value;
  if (draftTimer) clearTimeout(draftTimer);
  draftTimer = setTimeout(() => {
    draftTimer = null;
    saveDraftNow(id, value);
  }, 300);

  // Slash picker: active while the entire draft is a single leading
  // "/token" (the moment a space or newline lands, it is prose, not a
  // snippet lookup).
  const match = /^\/([^\s]*)$/.exec(value);
  if (match) {
    snip.open = true;
    snip.query = match[1] || "";
  } else {
    snip.open = false;
    snip.query = "";
  }
  renderSnippetPop();
}

export function handleComposerKeydown(e, target) {
  if (!target.matches("[data-composer-input]")) return;

  if (snip.open) {
    const items = filteredSnippets();
    if (e.key === "ArrowDown") {
      e.preventDefault();
      snip.sel = items.length === 0 ? 0 : (snip.sel + 1) % items.length;
      renderSnippetPop();
      return;
    }
    if (e.key === "ArrowUp") {
      e.preventDefault();
      snip.sel = items.length === 0 ? 0 : (snip.sel - 1 + items.length) % items.length;
      renderSnippetPop();
      return;
    }
    if (e.key === "Enter" || e.key === "Tab") {
      if (items.length > 0) {
        e.preventDefault();
        insertSnippet(items[snip.sel] || items[0]);
      } else {
        closeSnippets();
      }
      return;
    }
    if (e.key === "Escape") {
      e.preventDefault();
      closeSnippets();
      return;
    }
  }

  if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
    e.preventDefault();
    sendReply();
  }
}

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------

export function toggleWaiting() {
  const id = activeId();
  const bundle = activeBundle();
  if (!id || !bundle || !bundle.request) return;
  if (bundle.request.status === "waiting_customer") {
    reopenCase(id, { fromWaiting: true });
  } else {
    markWaiting(id);
  }
}

export function reopenFromComposer() {
  const id = activeId();
  if (id) reopenCase(id);
}

export async function sendReply() {
  const id = activeId();
  const bundle = activeBundle();
  if (!id || !bundle || !bundle.request || sending) return;
  if (bundle.request.status === "resolved") {
    toast("This case is resolved. Reopen it to reply.", "info");
    return;
  }

  const input = composerInput();
  const content = input ? input.value.trim() : "";
  if (!content) {
    toast("Type a reply first.", "error");
    return;
  }

  const ackEl = document.querySelector("[data-composer-ack]");
  const statusEl = document.querySelector("[data-composer-status]");
  const acknowledgementRequired = !!(ackEl && ackEl.checked);
  const toStatus = statusEl && statusEl.value ? statusEl.value : undefined;

  closeSnippets();
  // Kill any in-flight draft debounce (it could re-save the sent text after
  // the post-send clear), then keep the draft in scratch until the server
  // confirms so a failed send never eats the reply.
  if (draftTimer) {
    clearTimeout(draftTimer);
    draftTimer = null;
  }
  saveDraftNow(id, content);

  sending = true;
  invalidate("case-composer");

  const tempId = `optimistic-${Date.now()}`;
  const optimistic = {
    id: tempId,
    role: "concierge",
    content,
    attachments: [],
    created_at: new Date().toISOString(),
    _optimistic: true,
  };
  if (!Array.isArray(bundle.messages)) bundle.messages = [];
  bundle.messages.push(optimistic);
  invalidate("case-thread");
  requestAnimationFrame(scrollThreadToBottom);

  try {
    const resp = await callConcierge("reply", {
      request_id: id,
      content,
      acknowledgement_required: acknowledgementRequired,
      to_status: toStatus,
    });

    const idx = bundle.messages.findIndex((mm) => mm && mm.id === tempId);
    if (resp && resp.message) {
      if (idx >= 0) bundle.messages.splice(idx, 1, resp.message);
      else bundle.messages.push(resp.message);
    } else if (idx >= 0) {
      delete bundle.messages[idx]._optimistic;
    }

    const now = new Date().toISOString();
    bundle.request.last_message_at = now;
    if (toStatus && toStatus !== bundle.request.status) {
      bundle.request.status = toStatus;
      bundle.messages.push({
        id: `local-system-${Date.now()}`,
        role: "system",
        content: toStatus === "waiting_customer" ? "Chez is waiting on your answer." : "Chez reopened this request.",
        created_at: now,
        attachments: [],
      });
      invalidate("case-topbar");
    }
    const row = (state.queue || []).find((r) => r && r.id === id);
    if (row) {
      row.last_message_at = now;
      if (toStatus) row.status = toStatus;
    }

    scratchSet(id, { composerDraft: "", ackRequired: false });
    queueCaseEvent(id, "reply_sent");
    toast("Sent.", "success");
  } catch (err) {
    const idx = bundle.messages.findIndex((mm) => mm && mm.id === tempId);
    if (idx >= 0) bundle.messages.splice(idx, 1);
    toast(`Reply did not send: ${err && err.message ? err.message : err}`, "error");
  } finally {
    sending = false;
    invalidate("case-composer", "case-thread", "case-queue-list");
    requestAnimationFrame(scrollThreadToBottom);
  }
}

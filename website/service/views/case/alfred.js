// Service portal v2 - case view: Alfred rail.
//
// Case-scoped single-shot chat against the verified edge action:
//   { action: "ask_alfred", request_id, question } -> { answer }
// The server loads the request + dossier + thread itself, so the client
// only ships the question. Conversation history lives in the per-case
// scratchpad (survives reloads and case switches; LRU capped by storage.js).

import { invalidate, esc } from "../../render.js";
import { state } from "../../state.js";
import { callConcierge } from "../../api.js";
import { scratchGet, scratchSet } from "../../storage.js";
import { toast } from "../../components/toast.js";
import { fmtAgo } from "../../lib/format.js";

const SUGGESTED_PROMPTS = [
  "Summarize where this stands",
  "What should I ask the vendor?",
  "Draft my next reply",
];

const HISTORY_CAP = 40;

let pending = false;
let inputTimer = null;

function activeId() {
  return state.activeCaseId;
}

function chatFor(id) {
  const scratch = scratchGet(id) || {};
  return Array.isArray(scratch.alfredChat) ? scratch.alfredChat : [];
}

export function resetAlfredFor() {
  pending = false;
  if (inputTimer) {
    clearTimeout(inputTimer);
    inputTimer = null;
  }
}

// ---------------------------------------------------------------------------
// Zone render
// ---------------------------------------------------------------------------

export function renderAlfredZone() {
  if (!state.ui.alfredOpen) return "";
  const id = activeId();
  if (!id) return "";

  const scratch = scratchGet(id) || {};
  const chat = chatFor(id);
  const draft = typeof scratch.alfredInput === "string" ? scratch.alfredInput : "";

  const historyHtml = chat.length === 0 && !pending
    ? `<div class="svc-alfred__empty">Ask about this case. Alfred reads the work order, the thread, and this home's history before answering.</div>`
    : chat.map((entry) => {
        if (!entry || typeof entry !== "object") return "";
        const isQ = entry.role === "q";
        return `
          <div class="svc-alfred__msg ${isQ ? "svc-alfred__msg--q" : "svc-alfred__msg--a"}">
            <div class="svc-alfred__bubble">${esc(String(entry.text || ""))}</div>
            ${entry.at ? `<div class="svc-alfred__time">${esc(fmtAgo(entry.at))}</div>` : ""}
          </div>
        `;
      }).join("");

  return `
    <div class="svc-alfred">
      <div class="svc-alfred__head">
        <div>
          <div class="svc-alfred__title">Alfred</div>
          <div class="svc-alfred__hint">Case copilot. Answers stay on this side of the desk.</div>
        </div>
        ${chat.length > 0 ? `<button type="button" class="svc-btn svc-btn--ghost svc-btn--small" data-action="alfred-clear">Clear</button>` : ""}
      </div>
      <div class="svc-alfred__scroll" data-alfred-scroll>
        ${historyHtml}
        ${pending ? `<div class="svc-alfred__msg svc-alfred__msg--a"><div class="svc-alfred__bubble svc-alfred__bubble--pending">Alfred is thinking...</div></div>` : ""}
      </div>
      <div class="svc-alfred__suggest">
        ${SUGGESTED_PROMPTS.map((p) => `<button type="button" class="svc-suggest" data-action="alfred-suggest" data-q="${esc(p)}" ${pending ? "disabled" : ""}>${esc(p)}</button>`).join("")}
      </div>
      <div class="svc-alfred__inputrow">
        <textarea class="svc-textarea svc-alfred__input" data-alfred-input rows="2" placeholder="Ask Alfred about this case" ${pending ? "disabled" : ""}>${esc(draft)}</textarea>
        <button type="button" class="svc-btn svc-btn--small" data-action="alfred-send" ${pending ? "disabled" : ""}>Ask</button>
      </div>
    </div>
  `;
}

export function scrollAlfredToBottom() {
  const scroller = document.querySelector("[data-alfred-scroll]");
  if (scroller) scroller.scrollTop = scroller.scrollHeight;
}

// ---------------------------------------------------------------------------
// Delegated handlers (wired by index.js)
// ---------------------------------------------------------------------------

export function handleAlfredInput(target) {
  if (!target.matches("[data-alfred-input]")) return;
  const id = activeId();
  if (!id) return;
  const value = target.value;
  if (inputTimer) clearTimeout(inputTimer);
  inputTimer = setTimeout(() => {
    inputTimer = null;
    scratchSet(id, { alfredInput: value });
  }, 300);
}

export function handleAlfredKeydown(e, target) {
  if (!target.matches("[data-alfred-input]")) return;
  if (e.key === "Enter" && !e.shiftKey) {
    e.preventDefault();
    sendFromInput();
  }
}

// ---------------------------------------------------------------------------
// Ask flow
// ---------------------------------------------------------------------------

export function sendFromInput() {
  const input = document.querySelector("[data-alfred-input]");
  const question = input ? input.value.trim() : "";
  askAlfred(question);
}

export async function askAlfred(question) {
  const id = activeId();
  const q = typeof question === "string" ? question.trim() : "";
  if (!id || !q || pending) return;

  // Kill any in-flight input debounce so it cannot re-save the question
  // into alfredInput after we clear it below.
  if (inputTimer) {
    clearTimeout(inputTimer);
    inputTimer = null;
  }

  const before = chatFor(id);
  const withQuestion = [...before, { role: "q", text: q, at: new Date().toISOString() }].slice(-HISTORY_CAP);
  scratchSet(id, { alfredChat: withQuestion, alfredInput: "" });

  pending = true;
  invalidate("case-alfred");
  requestAnimationFrame(scrollAlfredToBottom);

  let answer;
  try {
    const resp = await callConcierge("ask_alfred", { request_id: id, question: q });
    answer = resp && typeof resp.answer === "string" && resp.answer.trim()
      ? resp.answer.trim()
      : "Alfred came back empty on that one. Try rephrasing.";
  } catch (err) {
    answer = "Alfred could not answer that one. Try again in a moment.";
    toast(`Alfred error: ${err && err.message ? err.message : err}`, "error");
  }

  const current = chatFor(id);
  const withAnswer = [...current, { role: "a", text: answer, at: new Date().toISOString() }].slice(-HISTORY_CAP);
  scratchSet(id, { alfredChat: withAnswer });

  pending = false;
  invalidate("case-alfred");
  requestAnimationFrame(scrollAlfredToBottom);
}

export function clearAlfredChat() {
  const id = activeId();
  if (!id) return;
  scratchSet(id, { alfredChat: [] });
  invalidate("case-alfred");
}

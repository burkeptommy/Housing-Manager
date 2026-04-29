// =============================================================================
// admin-preview.js — render quiz questions and the full quiz walkthrough
// =============================================================================
// HTML/CSS-based mock of the iOS quiz UI in a phone-frame on the left,
// with a structured explainer + live notes panel on the right.
//
// Two entry points:
//   openQuestionPreview(question, options)  — single Q
//   openQuizFlowPreview(questions, options) — interactive prev/next walkthrough
//
// `options` extension surface (passed in by admin.js):
//   factBundle           — initial property facts for token resolution
//   mapperEffects        — { [questionId]: { effects: [...], rawSnippet: "" } }
//   notesForQuestion     — (questionId) => Note[]   for the recent-notes list
//   onSaveNote           — async ({ scopeId, scopeTitle, body, intent, target,
//                                    snapshot }) => void   live note save
//   onJumpToDetail       — (questionId) => void  (closes preview, opens admin
//                                                  detail for that Q)

const COLORS = {
  cream: "#F8F9FA",
  creamLight: "#FFFFFF",
  navy800: "#453A70",
  navy700: "#524580",
  action: "#ED6955",
  textOnAction: "#FFFFFF",
  beige200: "#EDEEF0",
  beige300: "#D8DADF",
  textMuted: "rgba(69,58,112,0.62)",
};

// ---- Default fact bundle for token resolution ----------------------------

const DEFAULT_FACT_BUNDLE = {
  yearBuilt: "1962",
  street: "Park Avenue",
  city: "Greenwich",
  state: "CT",
  squareFootage: "4,200 sqft",
  roofType: "asphalt shingle",
};

// ---- Public API ----------------------------------------------------------

export function openQuestionPreview(question, options = {}) {
  const ctx = makeContext([question], 0, options);
  const overlay = showModal({
    title: "Preview question",
    subtitle: question.id,
    body: renderPanel(question, ctx),
    accent: "salmon",
    wide: true,
  });
  wirePanel(overlay, ctx, () => {});
}

export function openQuizFlowPreview(questions, options = {}) {
  if (!questions?.length) return;
  const ctx = makeContext(questions, 0, options);
  const overlay = showModal({
    title: "Preview entire quiz",
    subtitle: `${questions.length} questions in render order`,
    body: renderPanel(questions[0], ctx),
    accent: "indigo",
    wide: true,
  });

  function reRender() {
    const panel = overlay.querySelector(".qp-modal__body");
    if (!panel) return;
    panel.innerHTML = renderPanel(ctx.questions[ctx.index], ctx);
    wirePanel(overlay, ctx, reRender);
  }

  wirePanel(overlay, ctx, reRender);
  // Keyboard arrow nav (escape is handled in showModal already)
  const arrowHandler = (event) => {
    if (!document.body.contains(overlay)) {
      document.removeEventListener("keydown", arrowHandler);
      return;
    }
    if (event.target?.tagName === "INPUT" || event.target?.tagName === "TEXTAREA" || event.target?.tagName === "SELECT") return;
    if (event.key === "ArrowRight") {
      event.preventDefault();
      goNext(ctx, reRender);
    } else if (event.key === "ArrowLeft") {
      event.preventDefault();
      goPrev(ctx, reRender);
    }
  };
  document.addEventListener("keydown", arrowHandler);
}

export function closePreview() {
  const modal = document.querySelector("[data-preview-modal]");
  if (modal) modal.remove();
}

// ---- Context bag ----------------------------------------------------------

function makeContext(questions, index, options) {
  return {
    questions,
    index,
    isWalkthrough: questions.length > 1,
    factBundle: { ...DEFAULT_FACT_BUNDLE, ...(options.factBundle || {}) },
    mapperEffects: options.mapperEffects || {},
    notesForQuestion: options.notesForQuestion || (() => []),
    onSaveNote: options.onSaveNote || null,
    onJumpToDetail: options.onJumpToDetail || null,
  };
}

function goNext(ctx, reRender) {
  if (ctx.index < ctx.questions.length - 1) {
    ctx.index += 1;
    reRender();
  }
}

function goPrev(ctx, reRender) {
  if (ctx.index > 0) {
    ctx.index -= 1;
    reRender();
  }
}

// ---- Panel rendering ------------------------------------------------------

function renderPanel(question, ctx) {
  const navHtml = ctx.isWalkthrough ? renderNavStrip(ctx) : "";
  return `
    ${navHtml}
    <div class="qp">
      <div class="qp__chrome">
        ${renderPhoneFrame(question, ctx)}
      </div>
      <aside class="qp__meta">
        ${renderExplainer(question, ctx)}
        ${renderNotesPanel(question, ctx)}
        ${renderTokenControls(question, ctx)}
      </aside>
    </div>
  `;
}

function renderNavStrip(ctx) {
  const { index, questions } = ctx;
  const q = questions[index];
  const prevDisabled = index === 0;
  const nextDisabled = index === questions.length - 1;
  return `
    <div class="qp-nav">
      <button type="button" class="qp-nav__btn" data-prev ${prevDisabled ? "disabled" : ""}>
        ← Previous
      </button>
      <div class="qp-nav__progress">
        <div class="qp-nav__progress-bar"><div style="width:${((index + 1) / questions.length) * 100}%"></div></div>
        <div class="qp-nav__counter">
          <strong>${index + 1}</strong> of ${questions.length} ·
          <code>${escapeHtml(q.id)}</code>
        </div>
      </div>
      <button type="button" class="qp-nav__btn qp-nav__btn--primary" data-next ${nextDisabled ? "disabled" : ""}>
        Next →
      </button>
    </div>
  `;
}

// ---- Phone frame ----------------------------------------------------------

function renderPhoneFrame(q, ctx) {
  const interpolatedTitle = resolveTokens(q.title, ctx.factBundle, q.fallbackTitle);
  return `
    <div class="qp__phone">
      <div class="qp__statusbar">9:41</div>
      <div class="qp__nav">
        <span class="qp__nav-back">‹ Back</span>
        <span class="qp__chapter-pill">${escapeHtml(chapterTitle(q.chapter))} · ${escapeHtml(q.section || "")}</span>
      </div>
      <div class="qp__progress">
        <div class="qp__progress-bar" style="width:${Math.min(100, ((ctx.index + 1) / ctx.questions.length) * 100)}%"></div>
      </div>
      <div class="qp__body">
        <h1 class="qp__title">${escapeHtml(interpolatedTitle || q.fallbackTitle || "(no title)")}</h1>
        ${q.subtitle ? `<p class="qp__subtitle">${escapeHtml(q.subtitle)}</p>` : ""}
        <div class="qp__answers">
          ${renderAnswerControls(q)}
        </div>
      </div>
      <div class="qp__cta">
        <button class="qp__cta-btn">Continue</button>
      </div>
    </div>
  `;
}

function renderAnswerControls(q) {
  const kind = q.kind;
  const opts = q.answerOptions || [];

  if (kind === "currency") {
    return `
      <div class="qp__currency">
        <span class="qp__currency-prefix">$</span>
        <input type="text" placeholder="0" class="qp__currency-input" disabled />
      </div>
      ${opts.length ? `<div class="qp__answer-row">${opts.map((o) => optionChip(o, "single")).join("")}</div>` : ""}
    `;
  }

  if (kind === "yesNoLender") {
    return `
      <div class="qp__answer-row">
        <button class="qp__answer-btn qp__answer-btn--single">Yes</button>
        <button class="qp__answer-btn qp__answer-btn--single">No</button>
        <button class="qp__answer-btn qp__answer-btn--single qp__answer-btn--ghost">Prefer not to say</button>
      </div>
    `;
  }

  if (kind === "vehicleCount") {
    return `
      <div class="qp__answer-row">
        ${["0", "1", "2", "3", "4+"].map((n) => `<button class="qp__answer-btn qp__answer-btn--count">${n}</button>`).join("")}
      </div>
    `;
  }

  if (kind === "vehicleAdd") {
    return `
      <div class="qp__answer-row qp__answer-row--stacked">
        <button class="qp__answer-btn qp__answer-btn--primary">Scan VIN</button>
        <button class="qp__answer-btn qp__answer-btn--ghost">Enter manually</button>
      </div>
    `;
  }

  if (kind === "providerSearch") {
    return `
      <div class="qp__provider">
        <input type="text" class="qp__provider-input" placeholder="${escapeHtml(q.providerSearchPlaceholder || "Search providers…")}" disabled />
        <p class="qp__provider-hint">Filters by ${(q.providerTypes || []).map(escapeHtml).join(" / ") || "(any)"}</p>
      </div>
    `;
  }

  if (kind === "caretakers" || kind === "generatorAdd" || kind === "householdContractors") {
    return `
      <div class="qp__custom-form">
        <div class="qp__custom-form-pill">${escapeHtml(kindLabel(kind))} · custom inline form</div>
        <p class="qp__custom-form-note">${customFormNoteFor(kind)}</p>
        ${opts.length ? `<div class="qp__answer-row">${opts.map((o) => optionChip(o, "single")).join("")}</div>` : ""}
      </div>
    `;
  }

  if (kind === "multiSelect") {
    return `
      <div class="qp__answer-grid">
        ${opts.map((o) => optionChip(o, "multi")).join("")}
      </div>
      ${q.supportsSelectAll ? `<button class="qp__select-all">Select all</button>` : ""}
    `;
  }

  return `
    <div class="qp__answer-grid">
      ${opts.map((o) => optionChip(o, "single")).join("")}
    </div>
  `;
}

function optionChip(opt, mode) {
  const icon = opt.icon ? `<span class="qp__option-icon" title="${escapeHtml(opt.icon)}">●</span>` : "";
  const customTag = opt.acceptsCustomInput ? `<span class="qp__option-custom">+ custom</span>` : "";
  return `
    <button class="qp__answer-btn qp__answer-btn--${mode}">
      ${icon}
      <span class="qp__option-label">${escapeHtml(opt.label || opt.id || "")}</span>
      ${customTag}
    </button>
  `;
}

function customFormNoteFor(kind) {
  if (kind === "caretakers")
    return "Walks spouse → kids → caretakers → home manager sub-steps. Each sub-step can create family_member rows via HouseholdInviteCoordinator at apply time.";
  if (kind === "generatorAdd")
    return "Captures generator type (whole-home / portable / none), fuel type, and an optional provider. Creates a separate utility_account when fuel differs from Q3's heating fuel.";
  return "Multi-select chip grid with inline provider picker per chip. Saved chips become contractor rows + auto-created vendor routines per category.";
}

// ---- Explainer panel ------------------------------------------------------
// Pulls together everything we know about a question so Tom can see the
// behavior without flipping back to the admin form.

function renderExplainer(q, ctx) {
  const tokens = extractTokens(q.title);
  const lints = q._lint || [];
  const mapperEntry = ctx.mapperEffects?.[q.id];
  const downstream = downstreamEffects(q);

  const sections = [];

  // Identity + metadata
  sections.push(`
    <section class="qp__exp-section">
      <h3>What this question does</h3>
      <dl class="qp__dl">
        <dt>Question ID</dt><dd><code>${escapeHtml(q.id)}</code></dd>
        <dt>Kind</dt><dd>${escapeHtml(kindLabel(q.kind))}</dd>
        <dt>Section</dt><dd>${escapeHtml(q.section || "?")}</dd>
        <dt>Chapter</dt><dd>${escapeHtml(chapterTitle(q.chapter))}</dd>
        ${q.fallbackTitle ? `<dt>Fallback title</dt><dd>${escapeHtml(q.fallbackTitle)}</dd>` : ""}
        ${tokens.length ? `<dt>Tokens used</dt><dd>${tokens.map((t) => `<code>{${escapeHtml(t)}}</code>`).join(" ")}</dd>` : ""}
        ${q.documentUploadCategory ? `<dt>Doc upload</dt><dd>${escapeHtml(q.documentUploadCategory)} (user can upload instead of answering)</dd>` : ""}
        ${q.supportsSelectAll ? `<dt>Select-all pill</dt><dd>Enabled</dd>` : ""}
      </dl>
    </section>
  `);

  // Per-answer breakdown
  if (q.answerOptions?.length) {
    sections.push(renderAnswersTable(q));
  }

  // Mapper side-effects digest
  if (mapperEntry) {
    sections.push(`
      <section class="qp__exp-section">
        <h3>Side effects when answered</h3>
        <ul class="qp__effect-list">
          ${(mapperEntry.effects || []).map((e) => `<li>${escapeHtml(e)}</li>`).join("")}
        </ul>
        ${mapperEntry.rawSnippet ? `<details class="qp__exp-details"><summary>Raw HouseQuizAnswerMapper snippet</summary><pre>${escapeHtml(mapperEntry.rawSnippet)}</pre></details>` : ""}
      </section>
    `);
  }

  // Provider routing
  if (q.kind === "providerSearch" || q.providerTypes?.length || q.providerFollowUpAnswerIds?.length) {
    sections.push(`
      <section class="qp__exp-section">
        <h3>Provider routing</h3>
        ${q.providerTypes?.length ? `<p>Static provider types: ${q.providerTypes.map((t) => `<code>${escapeHtml(t)}</code>`).join(", ")}</p>` : ""}
        ${q.dynamicProviderTypes ? `<p>Has a <strong>dynamic</strong> provider-types closure — narrows the picker based on prior answers (e.g. Q19 reads Q3's heating fuel).</p>` : ""}
        ${q.providerFollowUpAnswerIds?.length ? `<p>These answer IDs trigger an <strong>inline provider picker</strong>: ${q.providerFollowUpAnswerIds.map((a) => `<code>${escapeHtml(a)}</code>`).join(", ")}</p>` : ""}
        ${q.providerSearchPlaceholder ? `<p>Picker placeholder: "${escapeHtml(q.providerSearchPlaceholder)}"</p>` : ""}
      </section>
    `);
  }

  // Skip + downstream gating
  if (q.dynamicSkip || downstream.gates.length || downstream.creates.length) {
    sections.push(`
      <section class="qp__exp-section">
        <h3>Flow + downstream</h3>
        ${q.dynamicSkip ? `
          <div class="qp__skip-note">
            ⚠️ Has a <strong>dynamicSkip</strong> rule — the quiz auto-skips this question when prior answers make it irrelevant.
            <details><summary>Closure source</summary><pre>${escapeHtml(typeof q.dynamicSkip === "string" ? q.dynamicSkip : JSON.stringify(q.dynamicSkip))}</pre></details>
          </div>
        ` : ""}
        ${downstream.creates.length ? `<p><strong>Creates these systems:</strong> ${downstream.creates.map((s) => `<code>${escapeHtml(s)}</code>`).join(", ")}</p>` : ""}
        ${downstream.gates.length ? `<p><strong>Likely gates downstream Q's:</strong> ${downstream.gates.map((s) => `<code>${escapeHtml(s)}</code>`).join(", ")}</p>` : ""}
      </section>
    `);
  }

  // Lint warnings
  if (lints.length) {
    sections.push(`
      <section class="qp__exp-section qp__exp-section--lint">
        <h3>Voice lint warnings (${lints.length})</h3>
        <ul class="qp__effect-list">
          ${lints.map((l) => `<li><code>${escapeHtml(l.ruleId)}</code> on ${escapeHtml(l.field)} — ${escapeHtml(l.message)}<br/><small>${escapeHtml(l.snippet || "")}</small></li>`).join("")}
        </ul>
      </section>
    `);
  }

  // Jump to detail panel link
  if (ctx.onJumpToDetail) {
    sections.push(`
      <div class="qp__jump">
        <button type="button" class="qp-nav__btn qp-nav__btn--ghost" data-jump-to-detail="${escapeHtml(q.id)}">
          Open in admin detail →
        </button>
      </div>
    `);
  }

  return sections.join("");
}

function renderAnswersTable(q) {
  return `
    <section class="qp__exp-section">
      <h3>Answer breakdown (${q.answerOptions.length})</h3>
      <table class="qp__answers-table">
        <thead><tr><th>id</th><th>label</th><th>icon</th><th>signal</th></tr></thead>
        <tbody>
          ${q.answerOptions.map((o) => `
            <tr>
              <td><code>${escapeHtml(o.id || "")}</code></td>
              <td>${escapeHtml(o.label || "")}</td>
              <td>${o.icon ? `<code>${escapeHtml(o.icon)}</code>` : "—"}</td>
              <td>${signalForAnswer(q, o)}</td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    </section>
  `;
}

function signalForAnswer(q, opt) {
  const tags = [];
  if (q.providerFollowUpAnswerIds?.includes(opt.id)) tags.push("opens provider picker");
  if (opt.acceptsCustomInput) tags.push("accepts custom input");
  if (opt.id === "not_sure" || opt.id === "skip") tags.push("non-answer");
  return tags.length ? tags.join(", ") : "—";
}

function downstreamEffects(q) {
  const out = { creates: [], gates: [] };
  // creates_systems comes from _impact heuristic baked at export time
  if (q._impact?.creates_systems?.length) out.creates = q._impact.creates_systems;
  if (q._impact?.gates_questions?.length) out.gates = q._impact.gates_questions;
  // dynamicSkip closure scan — pluck quoted question ids out of the raw source
  if (typeof q.dynamicSkip === "string") {
    const matches = q.dynamicSkip.match(/"q\w+"/g) || [];
    for (const m of matches) {
      const id = m.replace(/"/g, "");
      if (id !== q.id && !out.gates.includes(id)) out.gates.push(id);
    }
  }
  return out;
}

// ---- Notes panel ----------------------------------------------------------

function renderNotesPanel(q, ctx) {
  const notes = ctx.notesForQuestion(q.id) || [];
  return `
    <section class="qp__notes" data-note-scope-id="${escapeHtml(q.id)}" data-note-scope-title="${escapeHtml(q.title || q.id)}">
      <h3>Live note for Claude</h3>
      <p class="qp__notes-help admin-muted">Captures the question + your comment so I can act on it next session without re-exploring.</p>
      <div class="qp__notes-row">
        <label>
          <span>Intent</span>
          <select data-note-intent>
            <option value="feedback">Feedback</option>
            <option value="change_request">Change request</option>
            <option value="proposal_add">Add new option</option>
            <option value="proposal_delete">Cut this question</option>
            <option value="bug">Bug</option>
            <option value="idea">Idea</option>
            <option value="question_for_claude">Question for Claude</option>
          </select>
        </label>
        <label>
          <span>Target</span>
          <select data-note-target>
            <option value="claude" selected>CLAUDE_ADMIN_NOTES.md</option>
            <option value="codex">CODEX_ADMIN_NOTES.md</option>
            <option value="both">Both</option>
          </select>
        </label>
      </div>
      <textarea data-note-body rows="4" placeholder="e.g. 'Cut the Not Sure option — it's covering 30% of answers and we get no signal.' or 'Reorder so {state} appears in the title only when we have it.'"></textarea>
      <div class="qp__notes-actions">
        <button type="button" class="qp-nav__btn qp-nav__btn--primary" data-note-save>Save note</button>
        <span class="qp__notes-feedback admin-muted" data-note-feedback></span>
      </div>
      ${notes.length ? `
        <div class="qp__notes-recent">
          <h4>Recent notes on this question (${notes.length})</h4>
          ${notes.slice(0, 5).map((n) => `
            <article class="qp__notes-recent-item">
              <header>
                <span class="admin-pill admin-pill--note">${escapeHtml(n.intent || "feedback")}</span>
                <small>${escapeHtml(formatNoteDate(n.createdAt))}${n.appliedAt ? ` · applied ${escapeHtml(formatNoteDate(n.appliedAt))}` : ""}</small>
              </header>
              <pre>${escapeHtml(n.body || "")}</pre>
            </article>
          `).join("")}
          ${notes.length > 5 ? `<p class="admin-muted">…and ${notes.length - 5} more.</p>` : ""}
        </div>
      ` : ""}
    </section>
  `;
}

function formatNoteDate(iso) {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleString(undefined, { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
}

// ---- Token controls -------------------------------------------------------

function renderTokenControls(q, ctx) {
  return `
    <section class="qp__token-controls">
      <h4>Try different property facts</h4>
      <p class="admin-muted qp__notes-help">Edits update the title above live so you can see token resolution.</p>
      ${Object.keys(ctx.factBundle).map((k) => `
        <label class="qp__token-row">
          <span>${escapeHtml(k)}</span>
          <input type="text" data-fact-key="${escapeHtml(k)}" value="${escapeHtml(ctx.factBundle[k])}" />
        </label>
      `).join("")}
    </section>
  `;
}

// ---- Wire interactions ----------------------------------------------------

function wirePanel(overlay, ctx, reRender) {
  // Nav buttons
  overlay.querySelector("[data-prev]")?.addEventListener("click", () => goPrev(ctx, reRender));
  overlay.querySelector("[data-next]")?.addEventListener("click", () => goNext(ctx, reRender));

  // Jump-to-detail
  overlay.querySelector("[data-jump-to-detail]")?.addEventListener("click", (event) => {
    const qId = event.currentTarget.dataset.jumpToDetail;
    closePreview();
    ctx.onJumpToDetail?.(qId);
  });

  // Token-fact updates — re-render on change so the title interpolates live
  overlay.querySelectorAll("[data-fact-key]").forEach((input) => {
    input.addEventListener("input", () => {
      ctx.factBundle[input.dataset.factKey] = input.value;
      // Just update the title in place to avoid full re-render (preserves
      // notes textarea state).
      const phoneTitle = overlay.querySelector(".qp__title");
      if (phoneTitle) {
        const q = ctx.questions[ctx.index];
        phoneTitle.textContent = resolveTokens(q.title, ctx.factBundle, q.fallbackTitle) || q.fallbackTitle || "(no title)";
      }
    });
  });

  // Save note
  overlay.querySelector("[data-note-save]")?.addEventListener("click", () => saveNoteFromPanel(overlay, ctx, reRender));
  // Cmd/Ctrl-Enter inside note body also saves
  overlay.querySelector("[data-note-body]")?.addEventListener("keydown", (event) => {
    if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
      event.preventDefault();
      saveNoteFromPanel(overlay, ctx, reRender);
    }
  });
}

async function saveNoteFromPanel(overlay, ctx, reRender) {
  const scopeNode = overlay.querySelector("[data-note-scope-id]");
  if (!scopeNode || !ctx.onSaveNote) return;
  const body = overlay.querySelector("[data-note-body]")?.value?.trim();
  if (!body) {
    setNoteFeedback(overlay, "Write something first.", "warn");
    return;
  }
  const scopeId = scopeNode.dataset.noteScopeId;
  const scopeTitle = scopeNode.dataset.noteScopeTitle;
  const intent = overlay.querySelector("[data-note-intent]")?.value || "feedback";
  const target = overlay.querySelector("[data-note-target]")?.value || "claude";
  const q = ctx.questions[ctx.index];

  setNoteFeedback(overlay, "Saving…", "");
  try {
    await ctx.onSaveNote({
      scopeId,
      scopeTitle,
      body,
      intent,
      target,
      snapshot: {
        itemType: "question",
        category: `${q.chapter || "?"} · ${q.section || "?"}`,
        payload: q,
        capturedAt: new Date().toISOString(),
        capturedFrom: "preview-panel",
      },
    });
    overlay.querySelector("[data-note-body]").value = "";
    setNoteFeedback(overlay, "Saved ✓", "ok");
    // Refresh recent-notes list — full re-render is the simplest path, but
    // only re-render this question's panel section to preserve nav state.
    reRender();
  } catch (err) {
    setNoteFeedback(overlay, `Save failed: ${err.message || err}`, "warn");
  }
}

function setNoteFeedback(overlay, text, tone) {
  const node = overlay.querySelector("[data-note-feedback]");
  if (!node) return;
  node.textContent = text;
  node.dataset.tone = tone || "";
  if (tone === "ok") setTimeout(() => { node.textContent = ""; node.dataset.tone = ""; }, 2200);
}

// ---- Token resolution + helpers -------------------------------------------

function resolveTokens(rawTitle, facts, fallback) {
  if (!rawTitle) return fallback || "";
  const tokens = extractTokens(rawTitle);
  if (!tokens.length) return rawTitle;
  let resolved = rawTitle;
  let unresolved = false;
  for (const t of tokens) {
    const v = facts?.[t];
    if (v == null || v === "") {
      unresolved = true;
      break;
    }
    resolved = resolved.replaceAll(`{${t}}`, v);
  }
  if (unresolved && fallback) return fallback;
  return resolved;
}

function extractTokens(s) {
  if (!s) return [];
  const matches = String(s).matchAll(/\{(\w+)\}/g);
  const out = [];
  for (const m of matches) out.push(m[1]);
  return out;
}

function chapterTitle(key) {
  return (
    {
      yourHome: "Your Home",
      yourPros: "Your Pros",
      yourPeople: "Your People",
      your_home: "Your Home",
      your_pros: "Your Pros",
      your_people: "Your People",
    }[key] || key || ""
  );
}

function kindLabel(kind) {
  return (
    {
      singleChoice: "Single choice",
      multiSelect: "Multi-select",
      currency: "Currency input",
      yesNoLender: "Yes / No / Skip",
      vehicleCount: "Vehicle count",
      vehicleAdd: "Add vehicle",
      providerSearch: "Provider picker",
      caretakers: "Caretakers form",
      generatorAdd: "Generator form",
      householdContractors: "Contractor chips",
      slider: "Slider (legacy)",
    }[kind] || kind || ""
  );
}

// ---- Modal show / hide ----------------------------------------------------

function showModal({ title, subtitle, body, accent = "indigo", wide = false }) {
  closePreview();
  const tone = accent === "salmon" ? "qp-modal--salmon" : "qp-modal--indigo";
  const wideClass = wide ? "qp-modal--wide" : "";
  const overlay = document.createElement("div");
  overlay.dataset.previewModal = "true";
  overlay.className = `qp-modal ${tone} ${wideClass}`;
  overlay.innerHTML = `
    <div class="qp-modal__scrim" data-preview-dismiss></div>
    <div class="qp-modal__panel" role="dialog" aria-modal="true">
      <header class="qp-modal__header">
        <div>
          <p class="qp-modal__eyebrow">Preview</p>
          <h2>${escapeHtml(title)}</h2>
          ${subtitle ? `<p class="qp-modal__subtitle">${escapeHtml(subtitle)}</p>` : ""}
        </div>
        <button type="button" class="qp-modal__close" data-preview-dismiss aria-label="Close preview">×</button>
      </header>
      <div class="qp-modal__body">${body}</div>
    </div>
  `;
  document.body.appendChild(overlay);
  overlay.querySelectorAll("[data-preview-dismiss]").forEach((el) =>
    el.addEventListener("click", () => closePreview())
  );
  document.addEventListener("keydown", escListener);
  return overlay;
}

function escListener(event) {
  if (event.key === "Escape") {
    closePreview();
    document.removeEventListener("keydown", escListener);
  }
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

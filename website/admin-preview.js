// =============================================================================
// admin-preview.js — render quiz questions and the full quiz flow
// =============================================================================
// HTML/CSS-based mock of the iOS quiz UI. Cosmic Indigo + Pearl White +
// Salmon Action palette per CLAUDE.md. Used for "Preview this question"
// (single Q overlay) and "Preview entire quiz" (step-through).
//
// Rendering favors clarity over pixel-perfect SwiftUI parity — the goal
// is "does the copy + flow read right" not "does it look exactly like
// the iOS app".

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

// -----------------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------------

export function openQuestionPreview(question, options = {}) {
  const html = renderQuestionPreviewHtml(question, options);
  showModal({
    title: "Preview question",
    subtitle: question.id,
    body: html,
    accent: "salmon",
  });
}

export function openQuizFlowPreview(questions, options = {}) {
  const html = renderQuizFlowHtml(questions, options);
  showModal({
    title: "Preview entire quiz",
    subtitle: `${questions.length} questions in render order`,
    body: html,
    accent: "indigo",
    wide: true,
  });
}

export function closePreview() {
  const modal = document.querySelector("[data-preview-modal]");
  if (modal) modal.remove();
}

// -----------------------------------------------------------------------------
// Single-question render
// -----------------------------------------------------------------------------

function renderQuestionPreviewHtml(q, opts = {}) {
  const factBundle = opts.factBundle || DEFAULT_FACT_BUNDLE;
  const interpolatedTitle = resolveTokens(q.title, factBundle, q.fallbackTitle);
  const tokenCount = countTokens(q.title);
  const skipNote = q.dynamicSkip
    ? `<p class="qp__skip-note">⚠️ Has a dynamic skip rule. The quiz may auto-skip this question for some answers.</p>`
    : "";
  const providerNote = q.dynamicProviderTypes
    ? `<p class="qp__skip-note">↪ Provider list is computed at render time from prior answers.</p>`
    : "";

  return `
    <div class="qp">
      <div class="qp__chrome">
        <div class="qp__phone">
          <div class="qp__statusbar">9:41</div>
          <div class="qp__nav">
            <span class="qp__nav-back">‹ Back</span>
            <span class="qp__chapter-pill">${escapeHtml(chapterTitle(q.chapter))} · ${escapeHtml(q.section || "")}</span>
          </div>
          <div class="qp__progress"><div class="qp__progress-bar" style="width:${Math.min(100, ((opts.index || 1) / (opts.total || 41)) * 100)}%"></div></div>
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
      </div>

      <aside class="qp__meta">
        <h3>What this question does</h3>
        <dl class="qp__dl">
          <dt>Kind</dt><dd>${escapeHtml(q.kind || "?")}</dd>
          <dt>Section</dt><dd>${escapeHtml(q.section || "?")}</dd>
          <dt>Chapter</dt><dd>${escapeHtml(chapterTitle(q.chapter))}</dd>
          ${tokenCount > 0 ? `<dt>Tokens</dt><dd>${tokenCount} in title (${escapeHtml(extractTokens(q.title).join(", "))})</dd>` : ""}
          ${q.fallbackTitle ? `<dt>Fallback</dt><dd>${escapeHtml(q.fallbackTitle)}</dd>` : ""}
          ${(q.providerTypes && q.providerTypes.length) ? `<dt>Provider types</dt><dd>${q.providerTypes.map(escapeHtml).join(", ")}</dd>` : ""}
          ${(q.providerFollowUpAnswerIds && q.providerFollowUpAnswerIds.length) ? `<dt>Follow-up answers</dt><dd>${q.providerFollowUpAnswerIds.map(escapeHtml).join(", ")}</dd>` : ""}
          ${q.documentUploadCategory ? `<dt>Document upload</dt><dd>${escapeHtml(q.documentUploadCategory)}</dd>` : ""}
          ${q.supportsSelectAll ? `<dt>Select all</dt><dd>Pill enabled</dd>` : ""}
        </dl>
        ${skipNote}
        ${providerNote}
        ${(q._impact?.creates_systems?.length) ? `
          <div class="qp__impact">
            <strong>Creates systems:</strong> ${q._impact.creates_systems.map(escapeHtml).join(", ")}
          </div>
        ` : ""}
        ${q._lint?.length ? `
          <div class="qp__lint">
            <strong>Lint warnings (${q._lint.length}):</strong>
            <ul>${q._lint.map(l => `<li><code>${escapeHtml(l.ruleId)}</code> on ${escapeHtml(l.field)} — ${escapeHtml(l.message)}</li>`).join("")}</ul>
          </div>
        ` : ""}

        <div class="qp__token-controls">
          <h4>Try different property facts</h4>
          ${renderFactInputs(factBundle)}
        </div>
      </aside>
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
      <div class="qp__answer-row">
        ${opts.map((o) => optionChip(o, "single")).join("")}
      </div>
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
        <p class="qp__provider-hint">Filters by ${(q.providerTypes || []).map(escapeHtml).join(" / ") || "(any)"} in ${q._impact?.region || "your region"}.</p>
      </div>
    `;
  }

  if (kind === "caretakers" || kind === "generatorAdd" || kind === "householdContractors") {
    return `
      <div class="qp__custom-form">
        <div class="qp__custom-form-pill">${escapeHtml(kindLabel(kind))} · custom inline form</div>
        <p class="qp__custom-form-note">This kind shows a structured form embedded in the question. ${
          kind === "caretakers" ? "Walks spouse → kids → caretakers → home manager sub-steps." :
          kind === "generatorAdd" ? "Captures generator type, fuel, and optional provider." :
          "Multi-select chips with inline provider picker per chip."
        }</p>
        ${opts.length ? `<div class="qp__answer-row">${opts.map((o) => optionChip(o, "single")).join("")}</div>` : ""}
      </div>
    `;
  }

  // singleChoice / multiSelect / slider fallthrough
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

// -----------------------------------------------------------------------------
// Quiz flow render
// -----------------------------------------------------------------------------

function renderQuizFlowHtml(questions, opts = {}) {
  const grouped = groupByChapter(questions);
  const chapters = Object.keys(grouped);
  const totalCount = questions.length;
  let qIndex = 0;
  return `
    <div class="qf">
      <div class="qf__legend">
        <span class="qf__legend-item"><span class="qf__legend-dot qf__legend-dot--ok"></span> ${totalCount} questions across ${chapters.length} chapter${chapters.length === 1 ? "" : "s"}</span>
        <span class="qf__legend-item"><span class="qf__legend-dot qf__legend-dot--skip"></span> dynamicSkip rule</span>
        <span class="qf__legend-item"><span class="qf__legend-dot qf__legend-dot--lint"></span> lint warnings</span>
        <span class="qf__legend-item"><span class="qf__legend-dot qf__legend-dot--token"></span> uses tokens</span>
      </div>
      ${chapters
        .map((chapterKey) => {
          const chapter = chapterTitle(chapterKey);
          const list = grouped[chapterKey];
          return `
            <section class="qf__chapter">
              <header class="qf__chapter-header">
                <h2>${escapeHtml(chapter)}</h2>
                <span class="qf__chapter-count">${list.length} questions</span>
              </header>
              <ol class="qf__list">
                ${list.map((q) => {
                  qIndex += 1;
                  return renderQuizFlowItem(q, qIndex);
                }).join("")}
              </ol>
            </section>
          `;
        })
        .join("")}
    </div>
  `;
}

function renderQuizFlowItem(q, n) {
  const flags = [];
  if (q.dynamicSkip) flags.push(`<span class="qf__flag qf__flag--skip" title="Has dynamicSkip">↷</span>`);
  if (countTokens(q.title) > 0) flags.push(`<span class="qf__flag qf__flag--token" title="Uses tokens">{x}</span>`);
  if ((q._lint || []).length) flags.push(`<span class="qf__flag qf__flag--lint" title="${q._lint.length} lint hits">⚠</span>`);
  const note = (q._noteCount || 0) > 0 ? `<span class="qf__notes">${q._noteCount} note${q._noteCount === 1 ? "" : "s"}</span>` : "";
  const opts = (q.answerOptions || []).slice(0, 6).map((o) => o.label || o.id).filter(Boolean).join(" · ");
  const moreOpts = (q.answerOptions || []).length > 6 ? ` +${q.answerOptions.length - 6} more` : "";
  return `
    <li class="qf__item" data-question-id="${escapeHtml(q.id)}">
      <button class="qf__item-btn" data-preview-question-id="${escapeHtml(q.id)}">
        <span class="qf__item-num">${n}</span>
        <span class="qf__item-body">
          <span class="qf__item-title">${escapeHtml(resolveTokens(q.title, DEFAULT_FACT_BUNDLE, q.fallbackTitle))}</span>
          ${q.subtitle ? `<span class="qf__item-subtitle">${escapeHtml(q.subtitle)}</span>` : ""}
          <span class="qf__item-meta">
            <code>${escapeHtml(q.id)}</code>
            <span>${escapeHtml(kindLabel(q.kind))}</span>
            ${opts ? `<span class="qf__item-opts">${escapeHtml(opts + moreOpts)}</span>` : ""}
          </span>
        </span>
        <span class="qf__item-flags">
          ${flags.join("")}
          ${note}
        </span>
      </button>
    </li>
  `;
}

// -----------------------------------------------------------------------------
// Token resolution + helpers
// -----------------------------------------------------------------------------

const DEFAULT_FACT_BUNDLE = {
  yearBuilt: "1962",
  street: "Park Avenue",
  city: "Greenwich",
  state: "CT",
  squareFootage: "4,200 sqft",
  roofType: "asphalt shingle",
};

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

function countTokens(s) {
  return extractTokens(s).length;
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

function groupByChapter(questions) {
  const groups = {};
  for (const q of questions) {
    const key = q.chapter || "ungrouped";
    if (!groups[key]) groups[key] = [];
    groups[key].push(q);
  }
  return groups;
}

function renderFactInputs(facts) {
  return Object.keys(facts)
    .map(
      (k) => `
        <label class="qp__token-row">
          <span>${escapeHtml(k)}</span>
          <input type="text" data-fact-key="${escapeHtml(k)}" value="${escapeHtml(facts[k])}" />
        </label>
      `
    )
    .join("");
}

// -----------------------------------------------------------------------------
// Modal show / hide
// -----------------------------------------------------------------------------

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

const SUPABASE_URL = "https://jsucwnkntdrxhysojgri.supabase.co";
const PROVIDER_API_URL = `${SUPABASE_URL}/functions/v1/handyman-provider`;
const params = new URLSearchParams(window.location.search);
const quoteToken = params.get("quote") || "";

const dom = {
  quoteTitle: document.getElementById("quote-title"),
  quoteLede: document.getElementById("quote-lede"),
  heroChips: document.getElementById("quote-hero-chips"),
  quoteStatusTitle: document.getElementById("quote-status-title"),
  quoteStatusChip: document.getElementById("quote-status-chip"),
  quoteTotal: document.getElementById("quote-total"),
  quoteAudience: document.getElementById("quote-audience"),
  quoteCompany: document.getElementById("quote-company"),
  quoteProperty: document.getElementById("quote-property"),
  quoteSentAt: document.getElementById("quote-sent-at"),
  copyQuoteLink: document.getElementById("copy-quote-link"),
  quoteNoteCard: document.getElementById("quote-note-card"),
  quoteNote: document.getElementById("quote-note"),
  quoteScopeCard: document.getElementById("quote-scope-card"),
  quoteScope: document.getElementById("quote-scope"),
  responseName: document.getElementById("response-name"),
  responseEmail: document.getElementById("response-email"),
  responseBody: document.getElementById("response-body"),
  approveQuote: document.getElementById("approve-quote"),
  askQuestion: document.getElementById("ask-question"),
  declineQuote: document.getElementById("decline-quote"),
  responseFeedback: document.getElementById("response-feedback"),
  lineItemList: document.getElementById("line-item-list"),
  quoteTimeline: document.getElementById("quote-timeline"),
  signatureOverlay: document.getElementById("signature-overlay"),
  signatureName: document.getElementById("signature-name"),
  signatureConfirm: document.getElementById("signature-confirm"),
  signatureCancel: document.getElementById("signature-cancel"),
};

const state = {
  quote: null,
};

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function money(value) {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(Number.isFinite(Number(value)) ? Number(value) : 0);
}

function shortDate(value) {
  if (!value) return "Not sent yet";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    year: date.getFullYear() !== new Date().getFullYear() ? "numeric" : undefined,
    hour: "numeric",
    minute: "2-digit",
  });
}

function setFeedback(text, isError = false) {
  dom.responseFeedback.textContent = text || "";
  dom.responseFeedback.classList.toggle("error", Boolean(text && isError));
}

function openSignatureModal() {
  if (!dom.signatureOverlay) return;
  // Pre-fill from the response form's name field if present
  dom.signatureName.value = (dom.responseName.value || "").trim();
  dom.signatureConfirm.disabled = !dom.signatureName.value.trim();
  dom.signatureOverlay.classList.remove("hidden");
  setTimeout(() => dom.signatureName.focus(), 80);
}

function closeSignatureModal() {
  dom.signatureOverlay?.classList.add("hidden");
}

function chip(label, tone = "") {
  return `<span class="status-chip${tone ? ` ${tone}` : ""}">${escapeHtml(label)}</span>`;
}

async function loadQuote() {
  if (!quoteToken) {
    dom.quoteTitle.textContent = "This quote link is missing its token";
    dom.quoteLede.textContent = "Ask the handyman company to send the quote again.";
    return;
  }

  const response = await fetch(`${PROVIDER_API_URL}?quote=${encodeURIComponent(quoteToken)}`);
  const payload = await response.json().catch(() => ({}));
  if (!response.ok || !payload.publicQuote) {
    throw new Error(payload.error || "Quote not found");
  }
  state.quote = payload.publicQuote;
  renderQuote();
}

function renderQuote() {
  const quote = state.quote;
  if (!quote) return;

  dom.quoteTitle.textContent = quote.title || "Handyman quote";
  dom.quoteLede.textContent = quote.recipient?.kind === "linked_home"
    ? "Review the scope, approve it, ask a question, or decline it. Chez will keep the collaboration trail clean."
    : "Review the scope, approve it, ask a question, or decline it from the same secure quote link.";
  dom.heroChips.innerHTML = [
    chip(quote.statusLabel, quote.status === "approved" ? "success" : quote.status === "declined" ? "accent" : quote.status === "viewed" ? "warning" : ""),
    quote.property?.name ? chip(quote.property.name) : "",
    quote.workspace?.companyName ? chip(quote.workspace.companyName) : "",
  ].join("");

  dom.quoteStatusTitle.textContent = quote.status === "approved"
    ? "Approved and ready"
    : quote.status === "declined"
      ? "Declined"
      : quote.status === "viewed"
        ? "Viewed and awaiting next step"
        : "Ready for review";
  dom.quoteStatusChip.textContent = quote.statusLabel;
  dom.quoteStatusChip.className = `status-chip${
    quote.status === "approved" ? " success" : quote.status === "declined" ? " accent" : quote.status === "viewed" ? " warning" : ""
  }`;

  dom.quoteTotal.textContent = money(quote.total);
  dom.quoteAudience.textContent = [
    quote.recipient?.name || "",
    quote.recipient?.email || "",
    quote.recipient?.address || "",
  ].filter(Boolean).join(" · ");
  dom.quoteCompany.textContent = quote.workspace?.companyName || "Chez Handyman";
  dom.quoteProperty.textContent = quote.property?.name
    ? `${quote.property.name}${quote.property.address ? ` · ${quote.property.address}` : ""}`
    : quote.recipient?.address || "Standalone quote";
  dom.quoteSentAt.textContent = shortDate(quote.sentAt || quote.viewedAt);

  dom.quoteNoteCard.classList.toggle("hidden", !quote.homeownerMessage);
  dom.quoteNote.textContent = quote.homeownerMessage || "";
  dom.quoteScopeCard.classList.toggle("hidden", !quote.scopeNotes);
  dom.quoteScope.textContent = quote.scopeNotes || "";

  dom.lineItemList.innerHTML = (quote.lineItems || []).map((item) => {
    const quantity = Number(item.quantity || 1);
    const unitPrice = Number(item.unit_price || item.unitPrice || 0);
    const total = quantity * unitPrice;
    return `
      <article class="line-item-card">
        <div class="line-item-head">
          <div>
            <p class="line-item-title">${escapeHtml(item.name)}</p>
            ${item.description ? `<p>${escapeHtml(item.description)}</p>` : ""}
          </div>
          <strong>${money(total)}</strong>
        </div>
        <div class="line-item-meta">${escapeHtml(String(quantity))} ${escapeHtml(item.unit || "ea")} × ${money(unitPrice)}</div>
      </article>
    `;
  }).join("");

  dom.quoteTimeline.innerHTML = (quote.messages || []).length
    ? quote.messages.slice().reverse().map((message) => `
        <article class="timeline-entry">
          <div class="timeline-meta">${escapeHtml(message.senderName || message.senderRole)} · ${escapeHtml(shortDate(message.createdAt))}</div>
          <p>${escapeHtml(message.body)}</p>
        </article>
      `).join("")
    : `<article class="timeline-entry"><p>No collaboration yet. Your response will appear here.</p></article>`;

  dom.responseName.value = quote.recipient?.name || "";
  dom.responseEmail.value = quote.recipient?.email || "";
  dom.approveQuote.textContent = quote.status === "approved" ? "Approved" : "Approve quote";
  dom.declineQuote.textContent = quote.status === "declined" ? "Declined" : "Decline";
}

async function respondToQuote(responseType) {
  if (!state.quote) return;
  const body = {
    action: "respond_public_quote",
    quoteToken,
    responseType,
    senderName: dom.responseName.value.trim(),
    senderEmail: dom.responseEmail.value.trim(),
    body: dom.responseBody.value.trim(),
  };

  try {
    const response = await fetch(PROVIDER_API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok || !payload.quote) {
      throw new Error(payload.error || "Could not update the quote");
    }
    state.quote = payload.quote;
    dom.responseBody.value = "";
    renderQuote();
    setFeedback(
      payload.delivery?.sent === false
        ? `Response saved, but provider email delivery still needs attention: ${payload.delivery.error || "No email was sent."}`
        : (responseType === "approved"
            ? "Quote approved."
            : responseType === "declined"
              ? "Quote declined."
              : "Question sent."),
      Boolean(payload.delivery && payload.delivery.sent === false),
    );
  } catch (error) {
    setFeedback(error.message, true);
  }
}

function bindEvents() {
  dom.copyQuoteLink.addEventListener("click", async () => {
    if (!state.quote?.publicShareUrl) return;
    try {
      await navigator.clipboard.writeText(state.quote.publicShareUrl);
      setFeedback("Quote link copied.");
    } catch {
      setFeedback("Could not copy the quote link.", true);
    }
  });

  // Approve gates through the signature modal — typed name acts as the
  // homeowner's authorization, mirroring the iOS HandymanQuoteReviewSheet.
  dom.approveQuote.addEventListener("click", () => {
    if (state.quote?.status === "approved") return;
    openSignatureModal();
  });
  dom.declineQuote.addEventListener("click", () => respondToQuote("declined"));
  dom.askQuestion.addEventListener("click", () => respondToQuote("question"));

  if (dom.signatureOverlay) {
    dom.signatureName.addEventListener("input", () => {
      dom.signatureConfirm.disabled = !dom.signatureName.value.trim();
    });
    dom.signatureCancel.addEventListener("click", closeSignatureModal);
    dom.signatureOverlay.addEventListener("click", (event) => {
      if (event.target === dom.signatureOverlay) closeSignatureModal();
    });
    dom.signatureConfirm.addEventListener("click", async () => {
      const signed = dom.signatureName.value.trim();
      if (!signed) return;
      // Sync the typed name back into the response form so the server
      // has it on the record.
      dom.responseName.value = signed;
      dom.signatureConfirm.disabled = true;
      dom.signatureConfirm.textContent = "Approving…";
      await respondToQuote("approved");
      dom.signatureConfirm.textContent = "Approve quote";
      dom.signatureConfirm.disabled = false;
      closeSignatureModal();
    });
    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && !dom.signatureOverlay.classList.contains("hidden")) {
        closeSignatureModal();
      }
    });
  }
}

async function init() {
  bindEvents();
  try {
    await loadQuote();
  } catch (error) {
    dom.quoteTitle.textContent = "This quote could not be loaded";
    dom.quoteLede.textContent = error.message;
    dom.heroChips.innerHTML = chip("Unavailable", "accent");
    dom.lineItemList.innerHTML = "";
    dom.quoteTimeline.innerHTML = "";
  }
}

init();

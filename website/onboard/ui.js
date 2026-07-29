// Chez onboarding capture app — shared UI building blocks.
// Everything renders through el() with textContent, so user-entered
// strings are never interpreted as HTML.

export function el(tag, props = {}, ...children) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(props || {})) {
    if (v == null) continue;
    if (k === "class") node.className = v;
    else if (k === "dataset") Object.assign(node.dataset, v);
    else if (k.startsWith("on") && typeof v === "function") node.addEventListener(k.slice(2), v);
    else if (k === "value" || k === "checked" || k === "disabled" || k === "hidden" || k === "placeholder" || k === "type" || k === "rows" || k === "inputMode") node[k] = v;
    else node.setAttribute(k, v);
  }
  for (const c of children.flat(Infinity)) {
    if (c == null || c === false) continue;
    node.append(c.nodeType ? c : document.createTextNode(String(c)));
  }
  return node;
}

// "next_season" -> "Next season"
export function humanize(id) {
  const s = String(id || "").replace(/_/g, " ").trim();
  return s.charAt(0).toUpperCase() + s.slice(1);
}

// ---------- money ----------

export function parseMoneyToCents(str) {
  const cleaned = String(str || "").replace(/[^0-9.]/g, "");
  if (!cleaned) return null;
  const dollars = parseFloat(cleaned);
  if (!isFinite(dollars) || dollars < 0) return null;
  return Math.round(dollars * 100);
}

export function centsToDollars(cents) {
  if (cents == null) return "";
  const d = cents / 100;
  return Number.isInteger(d) ? String(d) : d.toFixed(2);
}

export function formatCents(cents) {
  if (cents == null) return "";
  return "$" + (cents / 100).toLocaleString("en-US", { maximumFractionDigits: 0 });
}

// ---------- fields ----------

export function field(labelText, inputEl, hintText) {
  return el("div", { class: "ob-field" },
    el("label", {}, labelText),
    inputEl,
    hintText ? el("p", { class: "ob-hint" }, hintText) : null,
  );
}

export function textInput({ value = "", placeholder = "", type = "text", inputMode = null, oninput = null }) {
  return el("input", { class: "ob-input", type, value, placeholder, inputMode, oninput });
}

export function textArea({ value = "", placeholder = "", rows = 3, oninput = null }) {
  const t = el("textarea", { class: "ob-input ob-textarea", rows, placeholder, oninput });
  t.value = value;
  return t;
}

// ---------- chips ----------

// options: [{ id, label }]. multi: selected is a Set-like array.
export function chipRow({ options, selected, onSelect, small = false }) {
  const row = el("div", { class: "ob-chip-row" });
  for (const opt of options) {
    const isSel = Array.isArray(selected) ? selected.includes(opt.id) : selected === opt.id;
    row.append(el("button", {
      type: "button",
      class: "ob-chip" + (small ? " ob-chip-sm" : "") + (isSel ? " is-selected" : ""),
      onclick: () => onSelect(opt),
    }, opt.label));
  }
  return row;
}

// Full-width stacked option buttons. options: [{ id, label, sub? }]
export function choiceButtons({ options, selected, onSelect }) {
  const group = el("div", { class: "ob-choice-group" });
  for (const opt of options) {
    group.append(el("button", {
      type: "button",
      class: "ob-choice" + (selected === opt.id ? " is-selected" : ""),
      onclick: () => onSelect(opt),
    }, opt.label));
  }
  return group;
}

// ---------- toggle ----------

export function toggleRow(label, checked, onChange) {
  const row = el("div", {
    class: "ob-toggle-row" + (checked ? " is-on" : ""),
    role: "switch",
    "aria-checked": String(!!checked),
    tabindex: "0",
  },
    el("span", { class: "ob-toggle-label" }, label),
    el("span", { class: "ob-toggle-track" }),
  );
  const flip = () => {
    const on = !row.classList.contains("is-on");
    row.classList.toggle("is-on", on);
    row.setAttribute("aria-checked", String(on));
    onChange(on);
  };
  row.addEventListener("click", flip);
  row.addEventListener("keydown", (e) => {
    if (e.key === " " || e.key === "Enter") { e.preventDefault(); flip(); }
  });
  return row;
}

// ---------- month chips ----------

const MONTH_LABELS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

// selected: array of month ints 1-12. onChange receives the new array.
export function monthChips(selected, onChange) {
  const grid = el("div", { class: "ob-month-chips" });
  const current = new Set(selected || []);
  for (let m = 1; m <= 12; m++) {
    const btn = el("button", {
      type: "button",
      class: "ob-month-chip" + (current.has(m) ? " is-selected" : ""),
      onclick: () => {
        if (current.has(m)) current.delete(m); else current.add(m);
        btn.classList.toggle("is-selected", current.has(m));
        onChange([...current].sort((a, b) => a - b));
      },
    }, MONTH_LABELS[m - 1]);
    grid.append(btn);
  }
  return grid;
}

// ---------- photos ----------

async function fileToDataUrl(file) {
  return new Promise((resolve, reject) => {
    const r = new FileReader();
    r.onload = () => resolve(r.result);
    r.onerror = () => reject(r.error || new Error("read failed"));
    r.readAsDataURL(file);
  });
}

function loadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error("decode failed"));
    img.src = src;
  });
}

// Reads a camera file and downsizes it so uploads stay well under the 8MB
// decoded cap and identify calls stay fast on cell connections.
export async function readImageScaled(file, maxDim = 1600) {
  const dataUrl = await fileToDataUrl(file);
  try {
    const img = await loadImage(dataUrl);
    const scale = Math.min(1, maxDim / Math.max(img.width || 1, img.height || 1));
    if (scale >= 1 && file.size < 3 * 1024 * 1024) {
      return { base64: dataUrl.split(",")[1], contentType: file.type || "image/jpeg", dataUrl };
    }
    const canvas = document.createElement("canvas");
    canvas.width = Math.max(1, Math.round((img.width || 1) * scale));
    canvas.height = Math.max(1, Math.round((img.height || 1) * scale));
    canvas.getContext("2d").drawImage(img, 0, 0, canvas.width, canvas.height);
    const jpeg = canvas.toDataURL("image/jpeg", 0.82);
    return { base64: jpeg.split(",")[1], contentType: "image/jpeg", dataUrl: jpeg };
  } catch (_e) {
    return { base64: dataUrl.split(",")[1], contentType: file.type || "image/jpeg", dataUrl };
  }
}

// A tappable photo tile that opens the camera. Caller handles the upload and
// drives visual state through the returned handle.
// onSelect(file) fires when the operator takes or picks a photo.
export function photoTile({ label = "Add photo", onSelect }) {
  const input = el("input", {
    type: "file",
    accept: "image/*",
    capture: "environment",
    class: "ob-hidden-input",
    "aria-hidden": "true",
    tabindex: "-1",
  });
  input.addEventListener("change", () => {
    const file = input.files && input.files[0];
    input.value = "";
    if (file) onSelect(file);
  });

  const tile = el("button", { type: "button", class: "ob-photo-tile ob-photo-tile-add", onclick: () => input.click() },
    el("span", { class: "ob-photo-plus" }, "+"),
    el("span", {}, label),
  );

  const root = el("span", { style: "display:contents" }, tile, input);

  return {
    root,
    // state: "empty" | "uploading" | "done" | "error"; src: preview url
    setState(state, src) {
      tile.textContent = "";
      tile.classList.toggle("ob-photo-tile-add", state === "empty");
      if (src) tile.append(el("img", { src, alt: "" }));
      if (state === "empty") {
        tile.append(el("span", { class: "ob-photo-plus" }, "+"), el("span", {}, label));
      } else if (state === "uploading") {
        tile.append(el("span", { class: "ob-photo-state" }, "Saving…"));
      } else if (state === "error") {
        tile.append(el("span", { class: "ob-photo-state" }, "Tap to retry"));
      }
    },
  };
}

// Static tile for an already-saved photo (path known, url maybe cached).
export function savedPhotoTile(src) {
  const tile = el("span", { class: "ob-photo-tile" });
  if (src) tile.append(el("img", { src, alt: "" }));
  else tile.append(el("span", {}, "Saved"));
  return tile;
}

// ---------- editor footer ----------

// Standard Save / Remove / Cancel footer shared by every entry editor.
// Returns a single element because Element.append() does not flatten arrays.
// actions: { save, cancel, remove? }. Remove renders only when provided;
// removal always lives here behind its confirm, never on a card's tap.
export function editorFooter(actions, saveLabel) {
  return el("div", { class: "ob-editor-footer" },
    el("button", { type: "button", class: "ob-btn ob-btn-primary", onclick: actions.save }, saveLabel),
    actions.remove
      ? el("button", { type: "button", class: "ob-btn ob-btn-danger-quiet", onclick: actions.remove }, "Remove")
      : null,
    el("button", { type: "button", class: "ob-btn ob-btn-danger-quiet", onclick: actions.cancel }, "Cancel"),
  );
}

// ---------- toast ----------

let toastTimer = null;

export function toast(message, ms = 2600) {
  const root = document.getElementById("toast-root");
  if (!root) return;
  root.textContent = "";
  root.append(el("div", { class: "ob-toast" }, message));
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { root.textContent = ""; }, ms);
}

// ---------- confirm dialog ----------

export function confirmDialog(message, confirmLabel = "Yes, remove it") {
  return new Promise((resolve) => {
    const root = document.getElementById("dialog-root");
    if (!root) { resolve(window.confirm(message)); return; }
    const close = (result) => { root.textContent = ""; resolve(result); };
    const backdrop = el("div", { class: "ob-dialog-backdrop", onclick: (e) => { if (e.target === backdrop) close(false); } },
      el("div", { class: "ob-dialog" },
        el("p", {}, message),
        el("div", { class: "ob-dialog-actions" },
          el("button", { type: "button", class: "ob-btn ob-btn-primary", onclick: () => close(true) }, confirmLabel),
          el("button", { type: "button", class: "ob-btn ob-btn-secondary", onclick: () => close(false) }, "Cancel"),
        ),
      ),
    );
    root.append(backdrop);
  });
}

// ---------- sync badge ----------

export function updateSyncBadge(count) {
  const badge = document.getElementById("sync-badge");
  const num = document.getElementById("sync-badge-count");
  if (!badge || !num) return;
  num.textContent = String(count);
  badge.hidden = count === 0;
}

export function wireSyncBadge(onTap) {
  const badge = document.getElementById("sync-badge");
  if (badge) badge.addEventListener("click", onTap);
}

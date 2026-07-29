// Chez onboarding capture app — systems flow.
// List -> category grid -> photo -> identify from photo -> details -> save.
// Elements match the chez-onboard contract system shape:
// { name, category, manufacturer?, model_number?, serial_number?, install_year?,
//   condition?, condition_notes?, photos?: [storagePath], notes? }

import * as api from "./api.js";
import * as store from "./store.js";
import {
  el, field, textInput, textArea, chipRow, choiceButtons, editorFooter,
  photoTile, savedPhotoTile, toast, confirmDialog, readImageScaled, humanize,
} from "./ui.js";

// storage path -> preview url (signed url or local data url). Session-only;
// photos captured before a reload just show a "Saved" tile.
const photoUrlCache = {};

const CONDITION_LABELS = {
  good: "Good",
  fair: "Fair",
  needs_attention: "Needs attention",
  urgent: "Urgent",
};

const DECADES = [
  { id: "2020s", label: "2020s", year: 2022 },
  { id: "2010s", label: "2010s", year: 2015 },
  { id: "2000s", label: "2000s", year: 2005 },
  { id: "1990s", label: "1990s", year: 1995 },
  { id: "older", label: "Older", year: 1985 },
];

let ctx = null;
let draft = null; // { index: number|null, data: {...}, lastBase64: string|null }

export function initSystems(context) {
  ctx = context;
  ctx.registerScreen("systems", renderList);
  ctx.registerScreen("system-edit", renderEditor);
}

function blankSystem() {
  return { name: "", category: "", manufacturer: "", model_number: "", serial_number: "", install_year: null, condition: "", notes: "", photos: [] };
}

function openEditor(index) {
  const source = index == null ? blankSystem() : store.state.systems[index];
  draft = { index, data: JSON.parse(JSON.stringify({ ...blankSystem(), ...source })), lastBase64: null };
  ctx.goto("system-edit");
}

// ---------- list ----------

function renderList() {
  const body = document.getElementById("systems-body");
  body.textContent = "";

  const systems = store.state.systems;
  if (systems.length === 0) {
    body.append(el("div", { class: "ob-empty" }, "No systems captured yet. Start with the biggest thing in the basement."));
  } else {
    const list = el("div", { class: "ob-card-list" });
    systems.forEach((sys, i) => {
      const thumbSrc = (sys.photos || []).map((p) => photoUrlCache[p]).find(Boolean);
      list.append(el("div", { class: "ob-card", onclick: () => openEditor(i) },
        thumbSrc ? el("img", { class: "ob-card-thumb", src: thumbSrc, alt: "" }) : el("span", { class: "ob-card-thumb" }),
        el("span", { class: "ob-card-main" },
          el("span", { class: "ob-card-title" }, sys.name || sys.category || "System"),
          el("span", { class: "ob-card-sub" }, [sys.category, sys.manufacturer].filter(Boolean).join(" · ")),
        ),
        sys.condition ? el("span", {
          class: "ob-card-pill" + (sys.condition === "urgent" || sys.condition === "needs_attention" ? " ob-card-pill-urgent" : ""),
        }, CONDITION_LABELS[sys.condition] || humanize(sys.condition)) : null,
      ));
    });
    body.append(list);
  }

  body.append(el("button", { type: "button", class: "ob-btn ob-btn-primary", onclick: () => openEditor(null) }, "Add system"));
}

// ---------- editor ----------

function renderEditor() {
  if (!draft) { openEditor(null); return; }
  const body = document.getElementById("system-edit-body");
  const title = document.getElementById("system-edit-title");
  title.textContent = draft.index == null ? "Add system" : (draft.data.name || "Edit system");
  body.textContent = "";

  const d = draft.data;

  // --- category grid ---
  const catWrap = el("div", { class: "ob-field" }, el("label", {}, "What is it?"));
  const catRow = () => chipRow({
    options: (ctx.dictionaries.system_categories || []).map((c) => ({ id: c, label: c })),
    selected: d.category,
    onSelect: (opt) => {
      const prev = d.category;
      d.category = opt.id;
      if (!d.name || d.name === prev) { d.name = opt.id; nameInput.value = opt.id; }
      catHolder.textContent = "";
      catHolder.append(catRow());
    },
    small: true,
  });
  const catHolder = el("div", {});
  catHolder.append(catRow());
  catWrap.append(catHolder);
  body.append(catWrap);

  // --- photos ---
  const photoWrap = el("div", { class: "ob-field" }, el("label", {}, "Photo of the unit and its label"));
  const photoHolder = el("div", { class: "ob-photo-row" });
  photoWrap.append(photoHolder);
  body.append(photoWrap);

  const identifyBtn = el("button", { type: "button", class: "ob-btn ob-btn-quiet", disabled: !draft.lastBase64, onclick: runIdentify },
    "Identify from photo");
  body.append(el("div", { class: "ob-field" }, identifyBtn,
    el("p", { class: "ob-hint" }, "Chez reads the model plate and fills in the details below.")));

  function refreshPhotos() {
    photoHolder.textContent = "";
    for (const path of d.photos || []) {
      photoHolder.append(savedPhotoTile(photoUrlCache[path]));
    }
    const tile = photoTile({ label: "Add photo", onSelect: (file) => uploadPhoto(file, tile) });
    photoHolder.append(tile.root);
  }

  async function uploadPhoto(file, tile) {
    try {
      const { base64, contentType, dataUrl } = await readImageScaled(file);
      tile.setState("uploading", dataUrl);
      const res = await api.call("upload_photo", {
        kind: "system",
        filename: `system-${Date.now()}.jpg`,
        content_type: contentType,
        base64,
      }, { timeoutMs: 90000 });
      d.photos = d.photos || [];
      d.photos.push(res.path);
      photoUrlCache[res.path] = res.signed_url || dataUrl;
      draft.lastBase64 = base64;
      identifyBtn.disabled = false;
      refreshPhotos();
    } catch (e) {
      tile.setState("empty");
      toast(e && e.code === "network" ? "No connection. That photo did not save, try again." : "That photo did not save. Try again.");
    }
  }

  async function runIdentify() {
    if (!draft.lastBase64) return;
    identifyBtn.disabled = true;
    identifyBtn.textContent = "Reading the label…";
    try {
      const res = await api.call("identify_equipment", {
        image_base64: draft.lastBase64,
        category: d.category || undefined,
      }, { timeoutMs: 90000 });
      const r = (res && res.result) || {};
      let filled = 0;
      if (r.manufacturer) { d.manufacturer = r.manufacturer; mfgInput.value = r.manufacturer; filled++; }
      if (r.model_number) { d.model_number = r.model_number; modelInput.value = r.model_number; filled++; }
      if (r.serial_number) { d.serial_number = r.serial_number; serialInput.value = r.serial_number; filled++; }
      toast(filled > 0 ? "Details filled in from the photo. Double-check them." : "Could not read a label in that photo. Type what you see.");
    } catch (e) {
      toast(e && e.status === 429 ? "Photo identify limit reached for this visit. Type the details instead." : "Could not identify from that photo. Type what you see.");
    } finally {
      identifyBtn.disabled = false;
      identifyBtn.textContent = "Identify from photo";
    }
  }

  refreshPhotos();

  // --- details ---
  const nameInput = textInput({ value: d.name, placeholder: "e.g. Boiler", oninput: (e) => { d.name = e.target.value; } });
  body.append(field("Name", nameInput));

  const mfgInput = textInput({ value: d.manufacturer || "", placeholder: "e.g. Weil-McLain", oninput: (e) => { d.manufacturer = e.target.value; } });
  body.append(field("Manufacturer", mfgInput));

  const modelInput = textInput({ value: d.model_number || "", placeholder: "Model number", oninput: (e) => { d.model_number = e.target.value; } });
  body.append(field("Model number", modelInput));

  const serialInput = textInput({ value: d.serial_number || "", placeholder: "Serial number", oninput: (e) => { d.serial_number = e.target.value; } });
  body.append(field("Serial number", serialInput));

  // --- install year: decade chips + fine tune ---
  const yearWrap = el("div", { class: "ob-field" }, el("label", {}, "Roughly when was it installed?"));
  const decadeHolder = el("div", {});
  const yearInput = el("input", {
    class: "ob-input", type: "number", inputMode: "numeric",
    value: d.install_year ? String(d.install_year) : "",
    placeholder: "Year",
    oninput: (e) => { d.install_year = parseInt(e.target.value, 10) || null; refreshDecades(); },
  });
  const step = (delta) => {
    const base = d.install_year || new Date().getFullYear();
    d.install_year = base + delta;
    yearInput.value = String(d.install_year);
    refreshDecades();
  };
  function decadeFor(year) {
    if (!year) return null;
    if (year >= 2020) return "2020s";
    if (year >= 2010) return "2010s";
    if (year >= 2000) return "2000s";
    if (year >= 1990) return "1990s";
    return "older";
  }
  function refreshDecades() {
    decadeHolder.textContent = "";
    decadeHolder.append(chipRow({
      options: DECADES,
      selected: decadeFor(d.install_year),
      onSelect: (opt) => {
        d.install_year = DECADES.find((x) => x.id === opt.id).year;
        yearInput.value = String(d.install_year);
        refreshDecades();
      },
      small: true,
    }));
  }
  refreshDecades();
  yearWrap.append(decadeHolder,
    el("div", { class: "ob-stepper" },
      el("button", { type: "button", class: "ob-stepper-btn", onclick: () => step(-1) }, "−"),
      yearInput,
      el("button", { type: "button", class: "ob-stepper-btn", onclick: () => step(1) }, "+"),
    ),
  );
  body.append(yearWrap);

  // --- condition ---
  const condWrap = el("div", { class: "ob-field" }, el("label", {}, "Condition"));
  const condHolder = el("div", {});
  const condOptions = (ctx.dictionaries.condition_ratings || ["good", "fair", "needs_attention", "urgent"])
    .map((c) => ({ id: c, label: CONDITION_LABELS[c] || humanize(c) }));
  function refreshCondition() {
    condHolder.textContent = "";
    condHolder.append(choiceButtons({
      options: condOptions,
      selected: d.condition,
      onSelect: (opt) => { d.condition = opt.id; refreshCondition(); },
    }));
  }
  refreshCondition();
  condWrap.append(condHolder);
  body.append(condWrap);

  // --- note ---
  body.append(field("Note (optional)", textArea({
    value: d.notes || "",
    placeholder: "Anything worth remembering about this unit.",
    oninput: (e) => { d.notes = e.target.value; },
  })));

  // --- actions (same Save / Remove / Cancel layout as every other editor) ---
  body.append(editorFooter({
    save,
    cancel: () => { draft = null; ctx.goto("systems"); },
    remove: draft.index != null ? removeSystem : null,
  }, "Save system"));

  function save() {
    if (!d.category) { toast("Pick a category first."); return; }
    const item = {
      name: (d.name || d.category).trim(),
      category: d.category,
      photos: d.photos || [],
    };
    if (d.manufacturer) item.manufacturer = d.manufacturer.trim();
    if (d.model_number) item.model_number = d.model_number.trim();
    if (d.serial_number) item.serial_number = d.serial_number.trim();
    if (d.install_year) item.install_year = d.install_year;
    if (d.condition) item.condition = d.condition;
    if (d.notes) item.notes = d.notes.trim();

    if (draft.index == null) store.state.systems.push(item);
    else store.state.systems[draft.index] = item;
    store.saveSection("systems");
    draft = null;
    ctx.goto("systems");
    toast("System saved.");
  }

  async function removeSystem() {
    const ok = await confirmDialog(`Remove ${d.name || "this system"}?`);
    if (!ok) return;
    store.state.systems.splice(draft.index, 1);
    store.saveSection("systems");
    draft = null;
    ctx.goto("systems");
  }
}

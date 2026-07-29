// Chez onboarding capture app — the non-system capture screens, driven by
// small config objects: Vendors, Routines, Utilities, Household, Quick fixes,
// Follow-ups. Element shapes match the chez-onboard contract exactly.
// Every list section supports add, edit-in-place (tap a card), and remove
// (explicit button in the editor, behind a confirm — never the card tap).

import * as api from "./api.js";
import * as store from "./store.js";
import {
  el, field, textInput, textArea, chipRow, choiceButtons, toggleRow, monthChips,
  photoTile, savedPhotoTile, toast, confirmDialog, readImageScaled, humanize,
  parseMoneyToCents, centsToDollars, formatCents, editorFooter,
} from "./ui.js";

const photoUrlCache = {}; // storage path -> preview url, session-only

const CADENCE_LABELS = {
  weekly: "Weekly",
  biweekly: "Every 2 weeks",
  triweekly: "Every 3 weeks",
  monthly: "Monthly",
  quarterly: "Quarterly",
  semiannual: "Twice a year",
  annual: "Yearly",
  custom_days: "Custom",
};

const UTILITY_LABELS = {
  electric: "Electric",
  natural_gas: "Natural gas",
  propane: "Propane",
  oil: "Heating oil",
  water: "Water",
  sewer: "Sewer",
  internet_cable: "Internet and cable",
  trash: "Trash",
  security: "Security",
  solar: "Solar",
  other: "Other",
};

const URGENCY_LABELS = {
  urgent: "Urgent",
  soon: "Soon",
  next_season: "Next season",
  opportunistic: "When convenient",
};

const YEAR_ROUND = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

let ctx = null;

export function initSimple(context) {
  ctx = context;
  ctx.registerScreen("vendors", makeListScreen(vendorsConfig()));
  ctx.registerScreen("routines", makeListScreen(routinesConfig()));
  ctx.registerScreen("utilities", makeListScreen(utilitiesConfig()));
  ctx.registerScreen("household", renderHousehold);
  ctx.registerScreen("quickfixes", makeListScreen(quickFixesConfig()));
  ctx.registerScreen("punchlist", makeListScreen(punchListConfig()));
}

// ---------- shared: single-photo field ----------

function photoField(labelText, kind, draftObj) {
  const holder = el("div", { class: "ob-photo-row" });
  const wrap = el("div", { class: "ob-field" }, el("label", {}, labelText), holder);

  function refresh() {
    holder.textContent = "";
    for (const p of draftObj.photos || []) holder.append(savedPhotoTile(photoUrlCache[p]));
    const tile = photoTile({ label: "Add photo", onSelect: (file) => upload(file, tile) });
    holder.append(tile.root);
  }

  async function upload(file, tile) {
    try {
      const { base64, contentType, dataUrl } = await readImageScaled(file);
      tile.setState("uploading", dataUrl);
      const res = await api.call("upload_photo", {
        kind,
        filename: `${kind}-${Date.now()}.jpg`,
        content_type: contentType,
        base64,
      }, { timeoutMs: 90000 });
      draftObj.photos = draftObj.photos || [];
      draftObj.photos.push(res.path);
      photoUrlCache[res.path] = res.signed_url || dataUrl;
      refresh();
    } catch (_e) {
      tile.setState("empty");
      toast("That photo did not save. Try again.");
    }
  }

  refresh();
  return wrap;
}

// ---------- shared: list + editor screen factory ----------

// cfg: { bodyId, addLabel, emptyCopy, getItems, cardContent(item),
//        makeDraft(itemOrNull), buildEditor(body, draft, actions),
//        commit(draft, index), remove(index, item) }
// Tapping a card always opens the editor prefilled with that entry.
function makeListScreen(cfg) {
  let mode = "list";
  let draft = null;
  let index = null;

  function enter() {
    mode = "list";
    draft = null;
    index = null;
    render();
  }

  function render() {
    const body = document.getElementById(cfg.bodyId);
    body.textContent = "";
    if (mode === "list") renderListView(body);
    else cfg.buildEditor(body, draft, {
      save: async () => {
        const ok = await cfg.commit(draft, index);
        if (ok === false) return;
        enter();
      },
      cancel: enter,
      remove: index != null && cfg.remove ? async () => {
        const ok = await confirmDialog("Remove this entry?");
        if (!ok) return;
        await cfg.remove(index, cfg.getItems()[index]);
        enter();
      } : null,
    });
  }

  function openEditor(i) {
    index = i;
    draft = cfg.makeDraft(i == null ? null : cfg.getItems()[i]);
    mode = "edit";
    render();
  }

  function renderListView(body) {
    const items = cfg.getItems();
    if (items.length === 0) {
      body.append(el("div", { class: "ob-empty" }, cfg.emptyCopy));
    } else {
      const list = el("div", { class: "ob-card-list" });
      items.forEach((item, i) => {
        list.append(el("div", { class: "ob-card", onclick: () => openEditor(i) }, cfg.cardContent(item)));
      });
      body.append(list);
    }
    body.append(el("button", { type: "button", class: "ob-btn ob-btn-primary", onclick: () => openEditor(null) }, cfg.addLabel));
  }

  return enter;
}

// ---------- vendors ----------

function vendorsConfig() {
  return {
    bodyId: "vendors-body",
    addLabel: "Add vendor",
    emptyCopy: "No vendors yet. Ask who plows, who mows, who they call when the heat dies.",
    getItems: () => store.state.contractors,
    cardContent: (item) => [
      el("span", { class: "ob-card-main" },
        el("span", { class: "ob-card-title" }, item.company_name || "Vendor"),
        el("span", { class: "ob-card-sub" }, [item.category, item.phone].filter(Boolean).join(" · ")),
      ),
      item.chez_handles ? el("span", { class: "ob-card-pill ob-card-pill-urgent" }, "Chez handles") : null,
    ],
    makeDraft: (item) => item
      ? JSON.parse(JSON.stringify(item))
      : { company_name: "", phone: "", category: "", chip_id: "", chez_handles: false },
    buildEditor: buildVendorEditor,
    commit: (draft, index) => {
      if (!draft.company_name.trim()) { toast("Add the company name."); return false; }
      if (!draft.category) { toast("Pick what they do."); return false; }
      const item = {
        company_name: draft.company_name.trim(),
        category: draft.category,
        chez_handles: !!draft.chez_handles,
      };
      if (draft.phone && draft.phone.trim()) item.phone = draft.phone.trim();
      if (draft.chip_id) item.chip_id = draft.chip_id;
      if (index == null) store.state.contractors.push(item);
      else store.state.contractors[index] = item;
      store.saveSection("contractors");
      toast("Vendor saved.");
    },
    remove: (index) => {
      store.state.contractors.splice(index, 1);
      store.saveSection("contractors");
    },
  };
}

function buildVendorEditor(body, draft, actions) {
  const chips = (ctx.dictionaries.vendor_chips || []).map((c) => ({ id: c.id, label: c.label, category: c.category }));
  chips.push({ id: "", label: "Something else", category: "" });

  const chipHolder = el("div", {});
  const otherHolder = el("div", {});
  let otherMode = draft.category && !chips.some((c) => c.id && c.id === draft.chip_id);

  function refreshChips() {
    chipHolder.textContent = "";
    const selectedId = otherMode ? "" : (draft.chip_id || null);
    chipHolder.append(chipRow({
      options: chips,
      selected: selectedId,
      onSelect: (opt) => {
        if (opt.id === "") {
          otherMode = true;
          draft.chip_id = "";
          draft.category = "";
        } else {
          otherMode = false;
          draft.chip_id = opt.id;
          draft.category = opt.category;
        }
        refreshChips();
        refreshOther();
      },
      small: true,
    }));
  }

  function refreshOther() {
    otherHolder.textContent = "";
    if (otherMode) {
      otherHolder.append(field("What do they do?", textInput({
        value: draft.category || "",
        placeholder: "e.g. Window Cleaning",
        oninput: (e) => { draft.category = e.target.value; },
      })));
    }
  }

  refreshChips();
  refreshOther();

  body.append(
    el("div", { class: "ob-field" }, el("label", {}, "What kind of vendor?"), chipHolder),
    otherHolder,
    field("Company name", textInput({
      value: draft.company_name,
      placeholder: "e.g. Blue Fox Landscaping",
      oninput: (e) => { draft.company_name = e.target.value; },
    })),
    field("Phone (optional)", textInput({
      value: draft.phone || "",
      type: "tel",
      inputMode: "tel",
      placeholder: "914 555 0100",
      oninput: (e) => { draft.phone = e.target.value; },
    })),
    toggleRow("Chez handles this vendor?", !!draft.chez_handles, (on) => { draft.chez_handles = on; }),
    editorFooter(actions, "Save vendor"),
  );
}

// ---------- routines ----------

function routineKinds() {
  return (ctx.dictionaries.routine_kinds || []).map((k) => ({
    id: k.id,
    label: k.label || humanize(k.id),
    default_cadence: k.default_cadence || {},
  }));
}

function kindLabel(id) {
  const k = routineKinds().find((x) => x.id === id);
  return k ? k.label : humanize(id);
}

function routinesConfig() {
  return {
    bodyId: "routines-body",
    addLabel: "Add routine",
    emptyCopy: "No routines yet. Capture the rhythms: lawn, pool, cleaning, plowing.",
    getItems: () => store.state.routines,
    cardContent: (item) => [
      el("span", { class: "ob-card-main" },
        el("span", { class: "ob-card-title" }, item.label || kindLabel(item.kind)),
        el("span", { class: "ob-card-sub" }, [
          CADENCE_LABELS[item.cadence_type] || humanize(item.cadence_type),
          item.vendor_name,
          item.estimated_cost_per_visit_cents != null ? formatCents(item.estimated_cost_per_visit_cents) + " per visit" : null,
        ].filter(Boolean).join(" · ")),
      ),
      item.chez_handles ? el("span", { class: "ob-card-pill ob-card-pill-urgent" }, "Chez handles") : null,
    ],
    makeDraft: (item) => item
      ? JSON.parse(JSON.stringify(item))
      : { kind: "", label: "", vendor_name: "", cadence_type: "", days_of_week: null, active_months: YEAR_ROUND.slice(), estimated_cost_per_visit_cents: null, chez_handles: false },
    buildEditor: buildRoutineEditor,
    commit: (draft, index) => {
      if (!draft.kind) { toast("Pick what kind of routine this is."); return false; }
      if (!draft.cadence_type) { toast("Pick how often it happens."); return false; }
      const item = {
        kind: draft.kind,
        cadence_type: draft.cadence_type,
        active_months: (draft.active_months && draft.active_months.length) ? draft.active_months : YEAR_ROUND.slice(),
        chez_handles: !!draft.chez_handles,
      };
      if (draft.label && draft.label.trim()) item.label = draft.label.trim();
      if (draft.vendor_name) item.vendor_name = draft.vendor_name;
      if (draft.days_of_week && draft.days_of_week.length) item.days_of_week = draft.days_of_week;
      if (draft.estimated_cost_per_visit_cents != null) item.estimated_cost_per_visit_cents = draft.estimated_cost_per_visit_cents;
      if (index == null) store.state.routines.push(item);
      else store.state.routines[index] = item;
      store.saveSection("routines");
      toast("Routine saved.");
    },
    remove: (index) => {
      store.state.routines.splice(index, 1);
      store.saveSection("routines");
    },
  };
}

function buildRoutineEditor(body, draft, actions) {
  const kinds = routineKinds();

  // kind chips
  const kindHolder = el("div", {});
  function refreshKinds() {
    kindHolder.textContent = "";
    kindHolder.append(chipRow({
      options: kinds,
      selected: draft.kind,
      onSelect: (opt) => {
        draft.kind = opt.id;
        const dc = opt.default_cadence || {};
        draft.cadence_type = dc.cadenceType || dc.cadence_type || draft.cadence_type || "weekly";
        const dow = dc.daysOfWeek || dc.days_of_week;
        if (dow && dow.length) draft.days_of_week = dow;
        const months = dc.activeMonths || dc.active_months;
        draft.active_months = (months && months.length) ? months.slice() : YEAR_ROUND.slice();
        refreshKinds();
        refreshCadence();
        refreshMonths();
      },
      small: true,
    }));
  }

  // vendor picker from captured vendors
  const vendorHolder = el("div", {});
  function refreshVendors() {
    vendorHolder.textContent = "";
    const options = [{ id: "", label: "No vendor yet" }]
      .concat(store.state.contractors.map((c) => ({ id: c.company_name, label: c.company_name })));
    vendorHolder.append(chipRow({
      options,
      selected: draft.vendor_name || "",
      onSelect: (opt) => { draft.vendor_name = opt.id; refreshVendors(); },
      small: true,
    }));
  }

  // cadence chips (custom_days is excluded: the visit picks the nearest
  // standard cadence; the homeowner can fine-tune in the app later)
  const cadenceHolder = el("div", {});
  function refreshCadence() {
    cadenceHolder.textContent = "";
    const options = (ctx.dictionaries.cadence_types || Object.keys(CADENCE_LABELS))
      .filter((c) => c !== "custom_days")
      .map((c) => ({ id: c, label: CADENCE_LABELS[c] || humanize(c) }));
    cadenceHolder.append(chipRow({
      options,
      selected: draft.cadence_type,
      onSelect: (opt) => { draft.cadence_type = opt.id; refreshCadence(); },
      small: true,
    }));
  }

  // active months: quick presets + month chips
  const monthsHolder = el("div", {});
  function sameMonths(a, b) {
    return a.length === b.length && a.slice().sort((x, y) => x - y).join() === b.slice().sort((x, y) => x - y).join();
  }
  function refreshMonths() {
    monthsHolder.textContent = "";
    const current = draft.active_months || YEAR_ROUND.slice();
    const presets = [
      { id: "year", label: "Year-round", months: YEAR_ROUND.slice() },
      { id: "apr_nov", label: "Apr to Nov", months: [4, 5, 6, 7, 8, 9, 10, 11] },
      { id: "dec_mar", label: "Dec to Mar", months: [12, 1, 2, 3] },
    ];
    const selectedPreset = presets.find((p) => sameMonths(p.months, current));
    monthsHolder.append(chipRow({
      options: presets,
      selected: selectedPreset ? selectedPreset.id : null,
      onSelect: (opt) => {
        draft.active_months = presets.find((p) => p.id === opt.id).months.slice();
        refreshMonths();
      },
      small: true,
    }));
    monthsHolder.append(el("div", { style: "height:10px" }));
    monthsHolder.append(monthChips(current, (months) => {
      draft.active_months = months;
      // re-render only the preset row highlight on next full refresh
    }));
  }

  refreshKinds();
  refreshVendors();
  refreshCadence();
  refreshMonths();

  body.append(
    el("div", { class: "ob-field" }, el("label", {}, "What kind of routine?"), kindHolder),
    field("Name (optional)", textInput({
      value: draft.label || "",
      placeholder: "e.g. Weekly mow",
      oninput: (e) => { draft.label = e.target.value; },
    })),
    el("div", { class: "ob-field" }, el("label", {}, "Who does it?"), vendorHolder,
      el("p", { class: "ob-hint" }, "Vendors you captured show up here.")),
    el("div", { class: "ob-field" }, el("label", {}, "How often?"), cadenceHolder),
    el("div", { class: "ob-field" }, el("label", {}, "Which months?"), monthsHolder),
    field("Cost per visit (optional)", textInput({
      value: centsToDollars(draft.estimated_cost_per_visit_cents),
      inputMode: "decimal",
      placeholder: "$",
      oninput: (e) => { draft.estimated_cost_per_visit_cents = parseMoneyToCents(e.target.value); },
    })),
    toggleRow("Chez handles this routine?", !!draft.chez_handles, (on) => { draft.chez_handles = on; }),
    editorFooter(actions, "Save routine"),
  );
}

// ---------- utilities ----------

function utilitiesConfig() {
  return {
    bodyId: "utilities-body",
    addLabel: "Add utility",
    emptyCopy: "No utilities yet. Who supplies power, water, internet, fuel?",
    getItems: () => store.state.utility_accounts,
    cardContent: (item) => [
      el("span", { class: "ob-card-main" },
        el("span", { class: "ob-card-title" }, item.provider_name || "Provider"),
        el("span", { class: "ob-card-sub" }, UTILITY_LABELS[item.provider_type] || humanize(item.provider_type)),
      ),
    ],
    makeDraft: (item) => item
      ? JSON.parse(JSON.stringify(item))
      : { provider_type: "", provider_name: "" },
    buildEditor: (body, draft, actions) => {
      const typeHolder = el("div", {});
      function refreshTypes() {
        typeHolder.textContent = "";
        typeHolder.append(chipRow({
          options: (ctx.dictionaries.utility_types || Object.keys(UTILITY_LABELS))
            .map((t) => ({ id: t, label: UTILITY_LABELS[t] || humanize(t) })),
          selected: draft.provider_type,
          onSelect: (opt) => { draft.provider_type = opt.id; refreshTypes(); },
          small: true,
        }));
      }
      refreshTypes();
      body.append(
        el("div", { class: "ob-field" }, el("label", {}, "What kind of service?"), typeHolder),
        field("Provider name", textInput({
          value: draft.provider_name,
          placeholder: "e.g. Con Edison",
          oninput: (e) => { draft.provider_name = e.target.value; },
        })),
        el("p", { class: "ob-trust", style: "margin-bottom:20px" },
          "Chez only records who provides the service. No account numbers, no logins, no codes."),
        editorFooter(actions, "Save utility"),
      );
    },
    commit: (draft, index) => {
      if (!draft.provider_type) { toast("Pick the service type."); return false; }
      if (!draft.provider_name.trim()) { toast("Add the provider name."); return false; }
      const item = { provider_type: draft.provider_type, provider_name: draft.provider_name.trim() };
      if (index == null) store.state.utility_accounts.push(item);
      else store.state.utility_accounts[index] = item;
      store.saveSection("utility_accounts");
      toast("Utility saved.");
    },
    remove: (index) => {
      store.state.utility_accounts.splice(index, 1);
      store.saveSection("utility_accounts");
    },
  };
}

// ---------- household (single form, not a list) ----------

function renderHousehold() {
  const body = document.getElementById("household-body");
  body.textContent = "";

  const attrs = store.state.attributes || {};
  const draft = {
    has_pets: attrs.has_pets === "true",
    pet_notes: attrs.pet_notes || "",
    occupancy_notes: attrs.occupancy_notes || "",
    tier: attrs.vendor_preference_tier || "",
  };

  const petNotesHolder = el("div", {});
  function refreshPetNotes() {
    petNotesHolder.textContent = "";
    if (draft.has_pets) {
      petNotesHolder.append(field("Pets", textInput({
        value: draft.pet_notes,
        placeholder: "e.g. Two dogs, gate stays closed",
        oninput: (e) => { draft.pet_notes = e.target.value; },
      })));
    }
  }
  refreshPetNotes();

  const tierHolder = el("div", {});
  function refreshTier() {
    tierHolder.textContent = "";
    tierHolder.append(choiceButtons({
      options: [
        { id: "diy", label: "They handle it" },
        { id: "mixed", label: "Mix" },
        { id: "hire_out", label: "Hire it out" },
      ],
      selected: draft.tier,
      onSelect: (opt) => { draft.tier = opt.id; refreshTier(); },
    }));
  }
  refreshTier();

  body.append(
    toggleRow("Pets in the home?", draft.has_pets, (on) => { draft.has_pets = on; refreshPetNotes(); }),
    petNotesHolder,
    field("Who lives here? (optional)", textArea({
      value: draft.occupancy_notes,
      placeholder: "e.g. Couple plus two kids, home manager on Tuesdays",
      oninput: (e) => { draft.occupancy_notes = e.target.value; },
    })),
    el("div", { class: "ob-field" },
      el("label", {}, "How do they want home upkeep handled?"),
      tierHolder,
    ),
    el("button", {
      type: "button", class: "ob-btn ob-btn-primary", onclick: () => {
        const attrsOut = { ...store.state.attributes };
        attrsOut.has_pets = draft.has_pets ? "true" : "false";
        if (draft.pet_notes.trim()) attrsOut.pet_notes = draft.pet_notes.trim();
        else delete attrsOut.pet_notes;
        if (draft.occupancy_notes.trim()) attrsOut.occupancy_notes = draft.occupancy_notes.trim();
        else delete attrsOut.occupancy_notes;
        if (draft.tier) attrsOut.vendor_preference_tier = draft.tier;
        store.state.attributes = attrsOut;
        store.saveSection("attributes");
        toast("Household details saved.");
        ctx.goto("hub");
      },
    }, "Save household details"),
  );
}

// ---------- quick fixes ----------

function quickFixesConfig() {
  return {
    bodyId: "quickfixes-body",
    addLabel: "Log a quick fix",
    emptyCopy: "Fixed something on the spot? Log it here so the homeowner sees the value.",
    getItems: () => store.state.quick_fixes,
    cardContent: (item) => [
      el("span", { class: "ob-card-main" },
        el("span", { class: "ob-card-title" }, item.description || "Quick fix"),
        el("span", { class: "ob-card-sub" }, [
          "Fixed on the spot",
          item.cost_cents != null ? formatCents(item.cost_cents) : null,
        ].filter(Boolean).join(" · ")),
      ),
    ],
    makeDraft: (item) => item
      ? JSON.parse(JSON.stringify(item))
      : { description: "", cost_cents: null, photos: [], fixed_at: null },
    buildEditor: (body, draft, actions) => {
      body.append(
        field("What did you fix?", textArea({
          value: draft.description,
          placeholder: "e.g. Tightened the loose stair rail by the mudroom",
          oninput: (e) => { draft.description = e.target.value; },
        })),
        field("Parts cost (optional)", textInput({
          value: centsToDollars(draft.cost_cents),
          inputMode: "decimal",
          placeholder: "$",
          oninput: (e) => { draft.cost_cents = parseMoneyToCents(e.target.value); },
        })),
        photoField("Photo (optional)", "quick_fix", draft),
        editorFooter(actions, "Save quick fix"),
      );
    },
    commit: (draft, index) => {
      if (!draft.description.trim()) { toast("Describe what you fixed."); return false; }
      const item = {
        description: draft.description.trim(),
        fixed_at: draft.fixed_at || new Date().toISOString(),
      };
      if (draft.cost_cents != null) item.cost_cents = draft.cost_cents;
      if (draft.photos && draft.photos.length) item.photos = draft.photos;
      if (index == null) store.state.quick_fixes.push(item);
      else store.state.quick_fixes[index] = item;
      store.saveSection("quick_fixes");
      toast("Nice. Logged as fixed on the spot.");
    },
    remove: (index) => {
      store.state.quick_fixes.splice(index, 1);
      store.saveSection("quick_fixes");
    },
  };
}

// ---------- follow-ups (recommendations) ----------

const OWNER_LABELS = {
  homeowner_diy: "Homeowner will handle",
  chez_handyman: "Chez handyman",
  chez_vendor: "Chez finds a pro",
};

function punchListConfig() {
  return {
    bodyId: "punchlist-body",
    addLabel: "Add follow-up",
    emptyCopy: "Anything that needs follow-up goes here so nothing gets missed. The homeowner sees these in their app.",
    getItems: () => store.state.recommendations,
    cardContent: (item) => [
      el("span", { class: "ob-card-main" },
        el("span", { class: "ob-card-title" }, item.title || "Follow-up"),
        el("span", { class: "ob-card-sub" }, [
          OWNER_LABELS[item.recommended_owner],
          item.zone,
          item.estimated_cost_cents != null ? "about " + formatCents(item.estimated_cost_cents) : null,
        ].filter(Boolean).join(" · ") || "Tap to edit"),
      ),
      el("span", {
        class: "ob-card-pill" + (item.urgency === "urgent" || item.urgency === "soon" ? " ob-card-pill-urgent" : ""),
      }, URGENCY_LABELS[item.urgency] || humanize(item.urgency)),
    ],
    makeDraft: (item) => ({
      title: "", description: "", urgency: "", zone: "",
      estimated_cost_cents: null, photos: [], recommended_owner: "chez_handyman",
      ...(item ? JSON.parse(JSON.stringify(item)) : {}),
    }),
    buildEditor: (body, draft, actions) => {
      const urgencyHolder = el("div", {});
      function refreshUrgency() {
        urgencyHolder.textContent = "";
        urgencyHolder.append(choiceButtons({
          options: (ctx.dictionaries.urgencies || Object.keys(URGENCY_LABELS))
            .map((u) => ({ id: u, label: URGENCY_LABELS[u] || humanize(u) })),
          selected: draft.urgency,
          onSelect: (opt) => { draft.urgency = opt.id; refreshUrgency(); },
        }));
      }
      refreshUrgency();
      const ownerHolder = el("div", {});
      function refreshOwner() {
        ownerHolder.textContent = "";
        ownerHolder.append(choiceButtons({
          options: [
            { id: "homeowner_diy", label: OWNER_LABELS.homeowner_diy },
            { id: "chez_handyman", label: OWNER_LABELS.chez_handyman },
            { id: "chez_vendor", label: OWNER_LABELS.chez_vendor },
          ],
          selected: draft.recommended_owner || "chez_handyman",
          onSelect: (opt) => { draft.recommended_owner = opt.id; refreshOwner(); },
        }));
      }
      refreshOwner();
      body.append(
        field("What needs doing?", textInput({
          value: draft.title,
          placeholder: "e.g. Repoint chimney crown",
          oninput: (e) => { draft.title = e.target.value; },
        })),
        field("Details (optional)", textArea({
          value: draft.description || "",
          placeholder: "What you saw and what should happen next.",
          oninput: (e) => { draft.description = e.target.value; },
        })),
        el("div", { class: "ob-field" }, el("label", {}, "How urgent?"), urgencyHolder),
        el("div", { class: "ob-field" }, el("label", {}, "Who handles it?"), ownerHolder),
        field("Rough cost (optional)", textInput({
          value: centsToDollars(draft.estimated_cost_cents),
          inputMode: "decimal",
          placeholder: "$",
          oninput: (e) => { draft.estimated_cost_cents = parseMoneyToCents(e.target.value); },
        })),
        field("Where in the home? (optional)", textInput({
          value: draft.zone || "",
          placeholder: "e.g. Roof, basement, backyard",
          oninput: (e) => { draft.zone = e.target.value; },
        })),
        photoField("Photo (optional)", "recommendation", draft),
        editorFooter(actions, draft.id != null ? "Save follow-up" : "Add follow-up"),
      );
    },
    commit: (draft, index) => {
      if (!draft.title.trim()) { toast("Give it a short title."); return false; }
      if (!draft.urgency) { toast("Pick how urgent it is."); return false; }
      const rec = {
        title: draft.title.trim(),
        urgency: draft.urgency,
        recommended_owner: draft.recommended_owner || "chez_handyman",
      };
      if (draft.description && draft.description.trim()) rec.description = draft.description.trim();
      if (draft.zone && draft.zone.trim()) rec.zone = draft.zone.trim();
      if (draft.estimated_cost_cents != null) rec.estimated_cost_cents = draft.estimated_cost_cents;
      if (draft.photos && draft.photos.length) rec.photos = draft.photos;
      if (index != null) {
        // Resolve the live id at save time: a queued add may have swapped the
        // temp id for the server id while the editor was open.
        const current = store.state.recommendations[index];
        if (current) store.updateRecommendation(current.id, rec);
        toast("Follow-up updated.");
      } else {
        store.addRecommendation(rec);
        toast("Added to follow-ups.");
      }
    },
    remove: async (_index, item) => {
      await store.deleteRecommendation(item.id);
    },
  };
}

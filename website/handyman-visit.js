const EDGE_URL =
  "https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/handyman-portal";
const IDENTIFY_EDGE_URL =
  "https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/identify-equipment";

const dom = {
  connectivityPill: document.getElementById("connectivity-pill"),
  visitTitle: document.getElementById("visit-title"),
  visitSubtitle: document.getElementById("visit-subtitle"),
  propertyName: document.getElementById("property-name"),
  propertyAddress: document.getElementById("property-address"),
  contractorName: document.getElementById("contractor-name"),
  contractorContact: document.getElementById("contractor-contact"),
  coordinationStatus: document.getElementById("coordination-status"),
  coordinationSummary: document.getElementById("coordination-summary"),
  coordinationNote: document.getElementById("coordination-note"),
  proposedDate: document.getElementById("proposed-date"),
  confirmDateButton: document.getElementById("confirm-date-button"),
  proposeDateButton: document.getElementById("propose-date-button"),
  askQuestionButton: document.getElementById("ask-question-button"),
  declineButton: document.getElementById("decline-button"),
  messageList: document.getElementById("message-list"),
  checklistList: document.getElementById("checklist-list"),
  checklistCount: document.getElementById("checklist-count"),
  executionLockNote: document.getElementById("execution-lock-note"),
  recommendationList: document.getElementById("recommendation-list"),
  systemList: document.getElementById("system-list"),
  systemCount: document.getElementById("system-count"),
  profileProgressChip: document.getElementById("profile-progress-chip"),
  profileBuilderCopy: document.getElementById("profile-builder-copy"),
  profileIdentifiedCount: document.getElementById("profile-identified-count"),
  profileNeedsSetupCount: document.getElementById("profile-needs-setup-count"),
  profileServicedCount: document.getElementById("profile-serviced-count"),
  profileCaptureButton: document.getElementById("profile-capture-button"),
  profileReviewSetupButton: document.getElementById("profile-review-setup-button"),
  addSystemPhotoButton: document.getElementById("add-system-photo-button"),
  addSystemPhotoInput: document.getElementById("add-system-photo-input"),
  addSystemButton: document.getElementById("add-system-button"),
  setupList: document.getElementById("setup-list"),
  setupCount: document.getElementById("setup-count"),
  firstVisitCard: document.getElementById("first-visit-card"),
  fieldNotes: document.getElementById("field-notes"),
  homeownerNotes: document.getElementById("homeowner-notes"),
  scheduledDate: document.getElementById("scheduled-date"),
  knownSystems: document.getElementById("known-systems"),
  propertyType: document.getElementById("property-type"),
  coordinationState: document.getElementById("coordination-state"),
  syncState: document.getElementById("sync-state"),
  systemUpdateCount: document.getElementById("system-update-count"),
  startVisitButton: document.getElementById("start-visit-button"),
  completeVisitButton: document.getElementById("complete-visit-button"),
  syncButton: document.getElementById("sync-button"),
  taskTemplate: document.getElementById("task-item-template"),
  recommendationTemplate: document.getElementById("recommendation-item-template"),
  systemTemplate: document.getElementById("system-item-template"),
  messageTemplate: document.getElementById("message-item-template"),
  // Phase 73 sub-phase C: home-profile read-only panels.
  homeProfileCard: document.getElementById("home-profile-card"),
  homeProfileSummaryChip: document.getElementById("home-profile-summary-chip"),
  homeProfileSystems: document.getElementById("home-profile-systems"),
  homeProfilePunch: document.getElementById("home-profile-punch"),
  homeProfileInvoices: document.getElementById("home-profile-invoices"),
  homeProfileTasks: document.getElementById("home-profile-tasks"),
  // Free-form chat composer (Phase 75)
  chatComposer: document.getElementById("chat-composer"),
  chatInput: document.getElementById("chat-input"),
  chatSendButton: document.getElementById("chat-send-button"),
  chatStatus: document.getElementById("chat-status"),
};

const token = new URLSearchParams(window.location.search).get("token");
// Storage key was renamed in the Chez rebrand. Existing offline drafts under
// the old "haven-handyman-portal:*" key will be ignored; given how transient
// these drafts are, we accept the one-time loss rather than carrying a
// migration shim forward.
const draftKey = `chez-handyman-portal:${token || "demo"}`;

const demoSession = {
  id: "demo-session",
  title: "Spring Handyman Visit",
  portal_token: "demo",
  seed_payload: {
    visitId: null,
    visitTitle: "Spring Handyman Visit",
    scheduledDate: null,
    dueDate: "2026-05-14",
    firstVisit: true,
    property: {
      name: "River House",
      addressLine: "16 Harbor Lane, Greenwich, CT",
      propertyType: "Single Family Home",
      squareFootage: 6400,
      yearBuilt: 2007,
      systemCount: 2,
      knownSystems: ["HVAC", "Appliance"],
      systems: [
        {
          id: "hvac",
          name: "Main HVAC",
          category: "HVAC",
          manufacturer: "Carrier",
          model_number: "",
          serial_number: "",
          install_date: "2021-05-01",
          notes: "",
          last_service_date: "",
          next_service_due: "",
          needs_setup: true,
          serviced: false,
        },
      ],
    },
    contractorName: "Preferred Handyman",
    contractorPhone: "(203) 555-0123",
    contractorEmail: "crew@example.com",
    homeownerNotes: "Please check the side gate latch and note any attic issues before summer.",
    checklist: [
      {
        id: "smoke",
        title: "Replace smoke and CO detector batteries",
        subtitle: "Spring safety sweep",
        category: "safety",
        status: "todo",
        source: "included",
        recommended: false,
      },
      {
        id: "caulk",
        title: "Inspect exterior caulking around windows and doors",
        subtitle: "Flag any areas that need a larger follow-up",
        category: "exterior",
        status: "todo",
        source: "included",
        recommended: false,
      },
    ],
    quickUpsells: [
      {
        id: "relamp",
        title: "Whole-house relamping",
        detail: "Owner already has overdue stairwell and exterior sconces.",
        category: "lighting",
        priceHint: "$150-$500",
        minutesHint: 45,
      },
    ],
    setupPrompts: [
      {
        id: "inventory",
        title: "Inventory major systems and appliances",
        detail: "Add anything Chez is still missing so future visits start with the right context.",
        category: "inventory",
        isRequired: true,
      },
    ],
    coordination: {
      status: "sent_to_handyman",
      status_label: "Sent to handyman",
      intro: "Confirm the requested date or suggest another option before starting the visit.",
      last_message: "Chez prepared the visit link for the handyman.",
      scheduled_date: "2026-05-14",
      needs_homeowner_reply: false,
    },
    recommendations: [
      {
        id: "rec-1",
        title: "Whole-house relamping",
        detail: "Owner already has overdue stairwell and exterior sconces.",
        category: "lighting",
        priority: "normal",
        create_follow_up: false,
      },
    ],
  },
};

const state = {
  session: null,
  request: null,
  messages: [],
  pendingCoordinationAction: null,
  report: {
    reportStatus: "draft",
    coordinationStatus: null,
    checklist: [],
    setupPrompts: [],
    quickUpsells: [],
    systemsSnapshot: [],
    recommendations: [],
    fieldNotes: "",
    homeownerNotes: "",
    startedAt: null,
    completedAt: null,
  },
  // Phase 73 sub-phase C: read-only home profile snapshot fetched
  // alongside the session. The portal_token is the only auth, so this
  // mirrors what the homeowner-side iOS app shows about the property —
  // active systems, recent invoices, open punch list.
  homeProfile: { systems: [], recentInvoices: [], punchList: [] },
  dirty: false,
  systemIdentifyStatus: {},
};

function compactString(value) {
  return typeof value === "string" ? value.trim() : "";
}

function titleCase(value) {
  return compactString(value)
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ")
    .split(" ")
    .filter(Boolean)
    .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
    .join(" ");
}

function systemKey(system, index) {
  return (
    compactString(system?.system_id) ||
    compactString(system?.id) ||
    `system-${index + 1}`
  );
}

function loadDraft() {
  try {
    const raw = localStorage.getItem(draftKey);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function saveDraft() {
  localStorage.setItem(
    draftKey,
    JSON.stringify({
      session: state.session,
      request: state.request,
      messages: state.messages,
      pendingCoordinationAction: state.pendingCoordinationAction,
      report: state.report,
      dirty: state.dirty,
      savedAt: new Date().toISOString(),
    }),
  );
}

function setSyncState(text) {
  dom.syncState.textContent = text;
}

function setConnectivity() {
  const online = navigator.onLine;
  dom.connectivityPill.textContent = online
    ? state.dirty
      ? "Online, changes pending sync"
      : "Online"
    : "Offline, saving locally";
  dom.connectivityPill.style.background = online
    ? "rgba(45, 125, 87, 0.12)"
    : "rgba(214, 122, 47, 0.12)";
  dom.connectivityPill.style.color = online ? "#2d7d57" : "#d67a2f";
}

function seed() {
  return state.session?.seed_payload || demoSession.seed_payload;
}

function coordinationStatus() {
  return (
    state.request?.status ||
    state.report.coordinationStatus ||
    seed().coordination?.status ||
    "draft"
  );
}

function coordinationLabel() {
  return (
    state.request?.status_label ||
    seed().coordination?.status_label ||
    coordinationStatus().replaceAll("_", " ")
  );
}

function executionUnlocked() {
  const unlockedStatuses = [
    "confirmed",
    "on_my_way",
    "checked_in",
    "in_progress",
    "completed",
    "follow_up_recommended",
  ];
  return unlockedStatuses.includes(coordinationStatus()) || !state.request;
}

function syncableChecklist() {
  return state.report.checklist.length
    ? state.report.checklist
    : (seed().checklist || []).map((item) => ({
        ...item,
        status: item.status || "todo",
      }));
}

function syncableSetupPrompts() {
  return state.report.setupPrompts.length
    ? state.report.setupPrompts
    : (seed().setupPrompts || []).map((prompt) => ({
        ...prompt,
        done: false,
      }));
}

function syncableRecommendations() {
  const base = state.report.recommendations.length
    ? state.report.recommendations
    : seed().recommendations?.length
      ? seed().recommendations
      : (seed().quickUpsells || []).map((upsell) => ({
          id: upsell.id,
          title: upsell.title,
          detail: upsell.detail,
          category: upsell.category,
          priority: "normal",
          create_follow_up: false,
        }));
  return base.map((item) => ({
    ...item,
    create_follow_up: Boolean(item.create_follow_up),
  }));
}

function syncableSystems() {
  return state.report.systemsSnapshot.length
    ? state.report.systemsSnapshot
    : (seed().property?.systems || []).map((system) => ({
        ...system,
        serviced: Boolean(system.serviced),
      }));
}

function updateSystemAtIndex(index, updater) {
  state.report.systemsSnapshot = syncableSystems().map((current, currentIndex) =>
    currentIndex === index ? updater({ ...current }) : current,
  );
}

function normalizedCategoryHint(system) {
  const category = compactString(system?.category);
  return category ? category.toLowerCase().replace(/\s+/g, "-") : null;
}

function makeSystemName(existingSystem, result) {
  const existingName = compactString(existingSystem?.name);
  if (existingName) return existingName;

  const catalogDisplay = compactString(result.catalog_match?.display_name);
  if (catalogDisplay) return catalogDisplay;

  const manufacturer = compactString(result.manufacturer);
  const modelNumber = compactString(result.model_number);
  if (manufacturer && modelNumber) return `${manufacturer} ${modelNumber}`;

  const productType = titleCase(result.product_type);
  if (productType) return productType;

  return "New system";
}

function makeSystemPatch(existingSystem, result, fileName) {
  const catalogMatch = result.catalog_match || null;
  const catalogSpecs = catalogMatch?.specs || {};
  const categoryName =
    compactString(catalogMatch?.category?.name) ||
    titleCase(result.product_type) ||
    compactString(existingSystem?.category) ||
    "Other";
  const subtypeHint =
    compactString(catalogMatch?.category?.name) ||
    titleCase(result.product_type) ||
    compactString(existingSystem?.subtype) ||
    null;

  return {
    ...existingSystem,
    name: makeSystemName(existingSystem, result),
    category: categoryName,
    subtype: subtypeHint,
    manufacturer: compactString(result.manufacturer) || compactString(existingSystem?.manufacturer) || "",
    model_number: compactString(result.model_number) || compactString(existingSystem?.model_number) || "",
    serial_number: compactString(result.serial_number) || compactString(existingSystem?.serial_number) || "",
    catalog_entry_id: compactString(catalogMatch?.id) || compactString(existingSystem?.catalog_entry_id) || null,
    catalog_series: compactString(catalogSpecs.series) || compactString(existingSystem?.catalog_series) || null,
    catalog_model_name:
      compactString(catalogMatch?.model_name) ||
      compactString(existingSystem?.catalog_model_name) ||
      null,
    catalog_features: Array.isArray(catalogSpecs.key_features)
      ? catalogSpecs.key_features.filter((feature) => compactString(feature))
      : Array.isArray(existingSystem?.catalog_features)
        ? existingSystem.catalog_features
        : [],
    catalog_fuel_type:
      compactString(catalogSpecs.fuel_type) ||
      compactString(existingSystem?.catalog_fuel_type) ||
      null,
    catalog_enriched_at: catalogMatch ? new Date().toISOString() : compactString(existingSystem?.catalog_enriched_at) || null,
    catalog_display_name:
      compactString(catalogMatch?.display_name) ||
      compactString(existingSystem?.catalog_display_name) ||
      null,
    catalog_subtitle:
      compactString(catalogMatch?.subtitle) ||
      compactString(existingSystem?.catalog_subtitle) ||
      null,
    identification_confidence:
      compactString(result.confidence) || compactString(existingSystem?.identification_confidence) || null,
    identified_raw_text:
      compactString(result.raw_text) || compactString(existingSystem?.identified_raw_text) || null,
    label_photo_name: fileName || compactString(existingSystem?.label_photo_name) || null,
    photo_captured_at: new Date().toISOString(),
    needs_setup: false,
  };
}

function beginSystemIdentify(key, message) {
  state.systemIdentifyStatus[key] = { tone: "working", message };
}

function finishSystemIdentify(key, tone, message) {
  state.systemIdentifyStatus[key] = { tone, message };
}

function clearSystemIdentify(key) {
  delete state.systemIdentifyStatus[key];
}

function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result;
      if (typeof result !== "string") {
        reject(new Error("Could not read the label photo"));
        return;
      }
      const [, base64] = result.split(",", 2);
      resolve(base64 || "");
    };
    reader.onerror = () => reject(new Error("Could not read the label photo"));
    reader.readAsDataURL(file);
  });
}

async function identifyEquipmentFromFile(file, categoryHint) {
  const imageBase64 = await fileToBase64(file);
  const response = await fetch(IDENTIFY_EDGE_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      image_base64: imageBase64,
      category: categoryHint,
    }),
  });

  if (!response.ok) {
    throw new Error("Chez could not identify the equipment label");
  }

  return response.json();
}

async function identifyExistingSystem(index, file) {
  const systems = syncableSystems();
  const currentSystem = systems[index];
  const key = systemKey(currentSystem, index);

  beginSystemIdentify(key, "Analyzing the label photo...");
  setSyncState("Reading the equipment label...");
  render();

  try {
    const result = await identifyEquipmentFromFile(file, normalizedCategoryHint(currentSystem));
    if (!result?.identified) {
      throw new Error("The label was too blurry to identify. Try a closer, straighter photo.");
    }

    updateSystemAtIndex(index, (current) => makeSystemPatch(current, result, file.name));
    finishSystemIdentify(
      key,
      result.catalog_match ? "success" : "warning",
      result.catalog_match
        ? "Catalog match found. Chez filled in the system details."
        : "Label captured. Chez filled in the details, but this model is not in the catalog yet.",
    );
    markDirty("System identified from label photo");
    render();
  } catch (error) {
    setSyncState("Could not identify that label photo");
    finishSystemIdentify(
      key,
      "error",
      error instanceof Error ? error.message : "Could not identify the label photo.",
    );
    render();
  }
}

async function addSystemFromPhoto(file) {
  beginSystemIdentify("new-system", "Analyzing the label photo...");
  setSyncState("Reading the equipment label...");
  render();

  try {
    const result = await identifyEquipmentFromFile(file, null);
    if (!result?.identified) {
      throw new Error("The label was too blurry to identify. Try another photo.");
    }

    state.report.systemsSnapshot = [
      ...syncableSystems(),
      makeSystemPatch(
        {
          id: `local-${Date.now()}`,
          install_date: "",
          notes: "",
          last_service_date: "",
          next_service_due: "",
          serviced: false,
          needs_setup: false,
        },
        result,
        file.name,
      ),
    ];
    finishSystemIdentify(
      "new-system",
      result.catalog_match ? "success" : "warning",
      result.catalog_match
        ? "New system added from the label photo."
        : "New system added from the label photo. Chez did not find a catalog match yet.",
    );
    clearSystemIdentify("new-system");
    markDirty("Added a system from a label photo");
    render();
  } catch (error) {
    setSyncState("Could not identify that label photo");
    finishSystemIdentify(
      "new-system",
      "error",
      error instanceof Error ? error.message : "Could not identify the label photo.",
    );
    clearSystemIdentify("new-system");
    render();
  }
}

function render() {
  const currentSeed = seed();
  const coordination = currentSeed.coordination || {};
  const unlocked = executionUnlocked();
  const systems = syncableSystems();
  const setupPrompts = syncableSetupPrompts();
  const identifiedSystems = systems.filter((system) =>
    compactString(system.catalog_entry_id) ||
    compactString(system.model_number) ||
    compactString(system.serial_number),
  );
  const setupNeededCount = systems.filter((system) => {
    const missingLabelData =
      !compactString(system.catalog_entry_id) &&
      !compactString(system.model_number) &&
      !compactString(system.serial_number);
    return Boolean(system.needs_setup) || missingLabelData;
  }).length;
  const servicedCount = systems.filter((system) => Boolean(system.serviced)).length;

  dom.visitTitle.textContent = currentSeed.visitTitle;
  dom.visitSubtitle.textContent = unlocked
    ? currentSeed.firstVisit
      ? "Handle the checklist, photograph equipment labels, and leave the house record sharper than you found it."
      : "Work through the checklist, refresh system details, and leave profitable next-step recommendations."
    : "Confirm the date or suggest another option first. Once the visit is confirmed, the field workspace unlocks.";
  dom.propertyName.textContent = currentSeed.property.name;
  dom.propertyAddress.textContent = currentSeed.property.addressLine || "Address not available";
  dom.contractorName.textContent = currentSeed.contractorName || "Unassigned";
  dom.contractorContact.textContent =
    currentSeed.contractorPhone || currentSeed.contractorEmail || "No contact shared yet";
  dom.scheduledDate.textContent = currentSeed.scheduledDate || currentSeed.dueDate || "Unscheduled";
  const knownSystemLabels = Array.from(
    new Set(
      systems
        .map((system) => compactString(system.category) || compactString(system.name))
        .filter(Boolean),
    ),
  );
  dom.knownSystems.textContent =
    knownSystemLabels.length > 0
      ? knownSystemLabels.join(", ")
      : currentSeed.property.knownSystems?.length > 0
        ? currentSeed.property.knownSystems.join(", ")
        : "No major systems on file yet";
  dom.propertyType.textContent = currentSeed.property.propertyType;
  dom.coordinationState.textContent = coordinationLabel();
  dom.systemUpdateCount.textContent = String(
    systems.filter((system) =>
      system.serviced ||
      compactString(system.system_id) ||
      compactString(system.catalog_entry_id) ||
      compactString(system.model_number) ||
      compactString(system.serial_number),
    ).length,
  );

  dom.fieldNotes.value = state.report.fieldNotes || "";
  dom.homeownerNotes.value = state.report.homeownerNotes || currentSeed.homeownerNotes || "";
  dom.coordinationNote.value = state.pendingCoordinationAction?.message || "";
  dom.proposedDate.value = state.pendingCoordinationAction?.proposedDate || "";
  dom.coordinationStatus.textContent = coordinationLabel();
  dom.coordinationSummary.textContent =
    state.request?.intro ||
    coordination.intro ||
    "Confirm the visit or suggest another date before starting work.";

  dom.profileProgressChip.textContent = `${identifiedSystems.length} profiled`;
  dom.profileBuilderCopy.textContent = currentSeed.firstVisit
    ? "First visit is the setup visit. Photograph labels, add missing systems, and capture service notes so the next trip starts with the right parts and context."
    : "Every visit should sharpen the house record. Refresh labels, note service details, and leave the next tech with a cleaner picture of the home.";
  dom.profileIdentifiedCount.textContent = String(identifiedSystems.length);
  dom.profileNeedsSetupCount.textContent = String(setupNeededCount + setupPrompts.filter((prompt) => !prompt.done).length);
  dom.profileServicedCount.textContent = String(servicedCount);
  dom.profileCaptureButton.textContent =
    identifiedSystems.length > 0 ? "Capture another label photo" : "Capture first label photo";
  dom.profileReviewSetupButton.textContent =
    setupPrompts.length > 0 ? "Review setup prompts" : "Review systems";

  const messages = state.messages.length
    ? state.messages
    : currentSeed.coordination?.last_message
      ? [
          {
            id: "seed-message",
            sender_role: "haven",
            created_at: new Date().toISOString(),
            body: currentSeed.coordination.last_message,
          },
        ]
      : [];
  dom.messageList.innerHTML = "";
  messages.forEach((message) => {
    const node = dom.messageTemplate.content.firstElementChild.cloneNode(true);
    // Display label only — the underlying sender_role value stays "haven"
    // so server-side filtering and DB CHECK constraints keep working.
    node.querySelector(".message-role").textContent =
      message.sender_role === "haven" ? "Chez" : message.sender_role.replaceAll("_", " ");
    node.querySelector(".message-time").textContent = new Date(
      message.created_at || Date.now(),
    ).toLocaleString();
    node.querySelector(".message-body").textContent = message.body;
    dom.messageList.appendChild(node);
  });

  const checklist = syncableChecklist();
  dom.checklistCount.textContent = `${checklist.length} item${checklist.length === 1 ? "" : "s"}`;
  dom.executionLockNote.textContent = unlocked
    ? ""
    : "Confirm the visit above before checking off tasks or marking the visit complete.";
  dom.checklistList.innerHTML = "";
  checklist.forEach((item, index) => {
    const node = dom.taskTemplate.content.firstElementChild.cloneNode(true);
    const checkbox = node.querySelector(".task-checkbox");
    checkbox.checked = item.status === "done";
    checkbox.disabled = !unlocked;
    checkbox.addEventListener("change", () => {
      state.report.checklist = syncableChecklist().map((current, currentIndex) =>
        currentIndex === index
          ? { ...current, status: checkbox.checked ? "done" : "todo" }
          : current,
      );
      markDirty("Checklist updated locally");
    });
    node.querySelector(".task-title").textContent = item.title;
    node.querySelector(".task-subtitle").textContent = item.subtitle || "No extra note";
    node.querySelector(".task-badge").textContent =
      item.source === "punch_list" ? "Punch list" : "Visit";
    dom.checklistList.appendChild(node);
  });

  const recommendations = syncableRecommendations();
  dom.recommendationList.innerHTML = "";
  if (recommendations.length === 0) {
    dom.recommendationList.innerHTML =
      `<p class="task-subtitle">No extra follow-up recommendations have been added yet.</p>`;
  } else {
    recommendations.forEach((recommendation, index) => {
      const node = dom.recommendationTemplate.content.firstElementChild.cloneNode(true);
      node.querySelector(".recommendation-title").textContent = recommendation.title;
      node.querySelector(".recommendation-detail").textContent =
        recommendation.detail || "No detail added yet.";
      node.querySelector(".recommendation-hint").textContent =
        recommendation.priority === "high" ? "High priority" : "Worth flagging";
      const checkbox = node.querySelector(".recommendation-checkbox");
      checkbox.checked = Boolean(recommendation.create_follow_up);
      checkbox.addEventListener("change", () => {
        state.report.recommendations = syncableRecommendations().map((current, currentIndex) =>
          currentIndex === index
            ? { ...current, create_follow_up: checkbox.checked }
            : current,
        );
        markDirty("Recommendations updated locally");
      });
      dom.recommendationList.appendChild(node);
    });
  }

  dom.systemCount.textContent = `${systems.length} system${systems.length === 1 ? "" : "s"}`;
  dom.systemList.innerHTML = "";
  systems.forEach((system, index) => {
    const node = dom.systemTemplate.content.firstElementChild.cloneNode(true);
    const key = systemKey(system, index);
    const identifyStatus = state.systemIdentifyStatus[key] || null;
    const bind = (selector, field) => {
      const input = node.querySelector(selector);
      input.value = system[field] || "";
      input.addEventListener("input", () => {
        updateSystemAtIndex(index, (current) => ({ ...current, [field]: input.value }));
        markDirty("Systems updated locally");
      });
    };

    bind(".system-name", "name");
    bind(".system-category", "category");
    bind(".system-manufacturer", "manufacturer");
    bind(".system-model", "model_number");
    bind(".system-serial", "serial_number");
    bind(".system-install-date", "install_date");

    const notesInput = node.querySelector(".system-notes");
    notesInput.value = system.notes || "";
    notesInput.addEventListener("input", () => {
      updateSystemAtIndex(index, (current) => ({ ...current, notes: notesInput.value }));
      markDirty("Systems updated locally");
    });

    const servicedToggle = node.querySelector(".system-serviced");
    servicedToggle.checked = Boolean(system.serviced);
    servicedToggle.disabled = !unlocked;
    servicedToggle.addEventListener("change", () => {
      updateSystemAtIndex(index, (current) => ({ ...current, serviced: servicedToggle.checked }));
      markDirty("Systems updated locally");
    });

    const captureTitle = node.querySelector(".system-capture-title");
    const captureDetail = node.querySelector(".system-capture-detail");
    const photoButton = node.querySelector(".system-photo-button");
    const photoInput = node.querySelector(".system-photo-input");
    const matchTitle = node.querySelector(".system-match-title");
    const matchSubtitle = node.querySelector(".system-match-subtitle");
    const matchPill = node.querySelector(".system-match-pill");
    const detailNote = node.querySelector(".system-detail-note");
    const feedback = node.querySelector(".system-feedback");

    const hasCatalogMatch = Boolean(compactString(system.catalog_entry_id));
    const hasModelData = Boolean(compactString(system.model_number) || compactString(system.serial_number));
    const captureCopy = system.photo_captured_at
      ? "Retake the label photo any time you want Chez to refresh the equipment match and cached service details."
      : "Take a photo of the model and serial plate. Chez will match it to the equipment catalog and fill in the details for you.";
    captureTitle.textContent = hasCatalogMatch
      ? "Refresh this system from a label photo"
      : hasModelData
        ? "Capture the label to enrich this system"
        : "Let Chez identify this system";
    captureDetail.textContent = captureCopy;
    photoButton.textContent = identifyStatus?.tone === "working"
      ? "Analyzing label..."
      : system.photo_captured_at
        ? "Retake label photo"
        : "Take label photo";
    photoButton.disabled = Boolean(identifyStatus?.tone === "working");
    photoInput.addEventListener("change", async (event) => {
      const file = event.target.files?.[0];
      if (!file) return;
      await identifyExistingSystem(index, file);
      photoInput.value = "";
    });
    photoButton.addEventListener("click", () => {
      photoInput.click();
    });

    matchTitle.textContent =
      compactString(system.catalog_display_name) ||
      compactString(system.name) ||
      "No label captured yet";
    matchSubtitle.textContent =
      compactString(system.catalog_subtitle) ||
      (hasModelData
        ? [
            compactString(system.manufacturer),
            compactString(system.model_number),
            compactString(system.serial_number) ? `Serial ${compactString(system.serial_number)}` : "",
          ]
            .filter(Boolean)
            .join(" · ")
        : "Use a label photo to preload the brand, model, and service context.");
    matchPill.textContent = hasCatalogMatch
      ? "Catalog matched"
      : hasModelData
        ? "Label captured"
        : "Needs label";
    matchPill.classList.toggle("is-success", hasCatalogMatch);
    matchPill.classList.toggle("is-warning", !hasCatalogMatch && hasModelData);
    matchPill.classList.toggle("is-neutral", !hasCatalogMatch && !hasModelData);

    detailNote.textContent = hasCatalogMatch
      ? "Chez filled these in from the equipment catalog. Adjust anything manually only if the label photo needs a correction."
      : "Chez will fill these in from the label photo. Adjust anything manually only if it needs a correction.";

    if (identifyStatus?.message) {
      feedback.textContent = identifyStatus.message;
      feedback.classList.remove("hidden");
      feedback.classList.toggle("is-success", identifyStatus.tone === "success");
      feedback.classList.toggle("is-warning", identifyStatus.tone === "warning" || identifyStatus.tone === "working");
      feedback.classList.toggle("is-error", identifyStatus.tone === "error");
    } else {
      feedback.classList.add("hidden");
      feedback.textContent = "";
      feedback.classList.remove("is-success", "is-warning", "is-error");
    }

    const needsSetupPill = node.querySelector(".system-needs-setup");
    needsSetupPill.classList.toggle("hidden", !system.needs_setup);
    dom.systemList.appendChild(node);
  });

  const prompts = setupPrompts;
  dom.setupCount.textContent = `${prompts.length} prompt${prompts.length === 1 ? "" : "s"}`;
  dom.setupList.innerHTML = "";
  dom.firstVisitCard.style.display = currentSeed.firstVisit ? "block" : "none";
  prompts.forEach((prompt, index) => {
    const wrapper = document.createElement("div");
    wrapper.className = `setup-item ${prompt.isRequired ? "required" : ""}`;
    wrapper.innerHTML = `
      <div class="setup-topline">
        <strong>${prompt.title}</strong>
        <span>${prompt.isRequired ? "Required" : "Recommended"}</span>
      </div>
      <p>${prompt.detail}</p>
    `;
    const toggle = document.createElement("label");
    toggle.className = "upsell-toggle";
    toggle.innerHTML = `<input type="checkbox" ${prompt.done ? "checked" : ""}><span>Done</span>`;
    toggle.querySelector("input").addEventListener("change", (event) => {
      state.report.setupPrompts = syncableSetupPrompts().map((current, currentIndex) =>
        currentIndex === index
          ? { ...current, done: event.target.checked }
          : current,
      );
      markDirty("Setup prompts updated locally");
    });
    wrapper.appendChild(toggle);
    dom.setupList.appendChild(wrapper);
  });

  dom.startVisitButton.disabled = !unlocked;
  dom.completeVisitButton.disabled = !unlocked;

  renderHomeProfile();
}

// Phase 73 sub-phase C: read-only home profile panels.
//
// The data lives on `state.homeProfile` (loaded from the portal GET).
// Three sections render: systems on file, open punch list, recent
// invoices. Each uses the same compact-card pattern so the technician
// can scan in seconds. Empty states keep the section header but
// surface a quiet placeholder so the technician knows the homeowner
// hasn't logged anything yet (vs. a load failure).
function renderHomeProfile() {
  if (!dom.homeProfileCard) return;
  const profile = state.homeProfile || { systems: [], recentInvoices: [], punchList: [] };

  if (dom.homeProfileSummaryChip) {
    const counts = [
      `${profile.systems.length} system${profile.systems.length === 1 ? "" : "s"}`,
      `${profile.punchList.length} punch`,
      `${profile.recentInvoices.length} invoice${profile.recentInvoices.length === 1 ? "" : "s"}`,
    ];
    dom.homeProfileSummaryChip.textContent = counts.join(" · ");
  }

  if (dom.homeProfileSystems) {
    if (profile.systems.length === 0) {
      dom.homeProfileSystems.innerHTML = `<p class="task-subtitle">No systems on file yet. Add what you find on the visit.</p>`;
    } else {
      dom.homeProfileSystems.innerHTML = profile.systems
        .map((system) => {
          const meta = [
            compactString(system.manufacturer),
            compactString(system.modelNumber) ? `Model ${escapeText(system.modelNumber)}` : "",
            system.lastServiceDate ? `Last serviced ${escapeText(formatProfileDate(system.lastServiceDate))}` : "",
          ]
            .filter(Boolean)
            .join(" · ");
          const notes = compactString(system.notes);
          return `
            <div class="home-profile-row">
              <div class="home-profile-row-head">
                <strong>${escapeText(system.name || "Unnamed system")}</strong>
                <span class="home-profile-tag">${escapeText(system.category || "System")}</span>
              </div>
              ${meta ? `<div class="home-profile-meta">${meta}</div>` : ""}
              ${notes ? `<p class="home-profile-note">${escapeText(notes)}</p>` : ""}
            </div>
          `;
        })
        .join("");
    }
  }

  if (dom.homeProfilePunch) {
    if (profile.punchList.length === 0) {
      dom.homeProfilePunch.innerHTML = `<p class="task-subtitle">Punch list is empty. Anything the homeowner adds before your visit will show here.</p>`;
    } else {
      dom.homeProfilePunch.innerHTML = profile.punchList
        .map((item) => {
          const sourceLabel = punchSourceLabel(item.source);
          const notes = compactString(item.notes);
          const minutes = item.estimatedMinutes ? `${item.estimatedMinutes} min` : "";
          return `
            <div class="home-profile-row" data-punch-id="${escapeText(item.id)}">
              <div class="home-profile-row-head">
                <strong>${escapeText(item.label || "Punch item")}</strong>
                ${sourceLabel ? `<span class="home-profile-tag">${escapeText(sourceLabel)}</span>` : ""}
              </div>
              ${minutes ? `<div class="home-profile-meta">${escapeText(minutes)}</div>` : ""}
              ${notes ? `<p class="home-profile-note">${escapeText(notes)}</p>` : ""}
              <div class="home-profile-actions">
                <button class="secondary-button small-button" type="button" data-mark-punch-done="${escapeText(item.id)}">Mark done</button>
              </div>
            </div>
          `;
        })
        .join("");
      dom.homeProfilePunch.querySelectorAll("[data-mark-punch-done]").forEach((button) => {
        button.addEventListener("click", () => {
          markPunchItemDone(button.getAttribute("data-mark-punch-done"));
        });
      });
    }
  }

  if (dom.homeProfileTasks) {
    const openTasks = profile.openTasks || [];
    if (openTasks.length === 0) {
      dom.homeProfileTasks.innerHTML = `<p class="task-subtitle">No open homeowner tasks at this property.</p>`;
    } else {
      dom.homeProfileTasks.innerHTML = openTasks
        .map((task) => {
          const meta = [
            task.priority ? `${escapeText(task.priority)} priority` : "",
            task.frequency ? escapeText(task.frequency) : "",
            task.nextDueDate ? `Due ${escapeText(formatProfileDate(task.nextDueDate))}` : "",
          ]
            .filter(Boolean)
            .join(" · ");
          const description = compactString(task.description);
          return `
            <div class="home-profile-row" data-task-id="${escapeText(task.id)}">
              <div class="home-profile-row-head">
                <strong>${escapeText(task.title || "Maintenance task")}</strong>
                ${task.assignedRoute ? `<span class="home-profile-tag">${escapeText(task.assignedRoute)}</span>` : ""}
              </div>
              ${meta ? `<div class="home-profile-meta">${meta}</div>` : ""}
              ${description ? `<p class="home-profile-note">${escapeText(description)}</p>` : ""}
              <div class="home-profile-actions">
                <button class="secondary-button small-button" type="button" data-mark-task-done="${escapeText(task.id)}">Mark complete</button>
              </div>
            </div>
          `;
        })
        .join("");
      dom.homeProfileTasks.querySelectorAll("[data-mark-task-done]").forEach((button) => {
        button.addEventListener("click", () => {
          markOpenTaskDone(button.getAttribute("data-mark-task-done"));
        });
      });
    }
  }

  if (dom.homeProfileInvoices) {
    if (profile.recentInvoices.length === 0) {
      dom.homeProfileInvoices.innerHTML = `<p class="task-subtitle">No recent invoices on file at this property.</p>`;
    } else {
      dom.homeProfileInvoices.innerHTML = profile.recentInvoices
        .map((invoice) => {
          const meta = [
            compactString(invoice.vendorName),
            invoice.documentDate ? formatProfileDate(invoice.documentDate) : "",
            invoice.totalAmount != null ? formatCurrency(invoice.totalAmount) : "",
          ]
            .filter(Boolean)
            .join(" · ");
          const summary = compactString(invoice.summary);
          return `
            <div class="home-profile-row">
              <div class="home-profile-row-head">
                <strong>${escapeText(invoice.name || "Invoice")}</strong>
              </div>
              ${meta ? `<div class="home-profile-meta">${meta}</div>` : ""}
              ${summary ? `<p class="home-profile-note">${escapeText(summary)}</p>` : ""}
            </div>
          `;
        })
        .join("");
    }
  }
}

function punchSourceLabel(source) {
  switch ((source || "").toLowerCase()) {
    case "recommended":
      return "Recommended";
    case "maintenance_task":
      return "From maintenance";
    case "manual":
      return "Manual";
    default:
      return "";
  }
}

function escapeText(value) {
  if (value == null) return "";
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function formatProfileDate(value) {
  if (!value) return "";
  try {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return value;
    return date.toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  } catch {
    return value;
  }
}

function formatCurrency(value) {
  const num = Number(value);
  if (!Number.isFinite(num)) return "";
  return num.toLocaleString(undefined, {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  });
}

function markDirty(syncMessage) {
  state.dirty = true;
  saveDraft();
  setConnectivity();
  setSyncState(syncMessage);
}

async function fetchPortal() {
  if (!token) {
    state.session = demoSession;
    render();
    setConnectivity();
    setSyncState("Demo mode");
    return;
  }

  const response = await fetch(`${EDGE_URL}?token=${encodeURIComponent(token)}`);
  if (!response.ok) throw new Error("Failed to fetch portal");

  const payload = await response.json();
  state.session = payload.session;
  state.request = payload.request || null;
  state.messages = payload.messages || [];
  state.homeProfile = payload.homeProfile || {
    systems: [],
    recentInvoices: [],
    punchList: [],
  };

  if (payload.report) {
    state.report = {
      reportStatus: payload.report.report_status || "draft",
      coordinationStatus: payload.report.coordination_status || null,
      checklist: payload.report.checklist || [],
      setupPrompts: payload.report.setup_prompts || [],
      quickUpsells: payload.report.quick_upsells || [],
      systemsSnapshot: payload.report.systems_snapshot || [],
      recommendations: payload.report.recommendations || [],
      fieldNotes: payload.report.field_notes || "",
      homeownerNotes: payload.report.homeowner_notes || "",
      startedAt: payload.report.started_at || null,
      completedAt: payload.report.completed_at || null,
    };
  }

  state.pendingCoordinationAction = null;
  state.dirty = false;
  state.systemIdentifyStatus = {};
  saveDraft();
  render();
  setConnectivity();
  setSyncState("Up to date");
}

async function syncDraft() {
  if (!navigator.onLine) {
    setConnectivity();
    setSyncState("Offline, draft saved on device");
    return;
  }

  if (!token) {
    setConnectivity();
    setSyncState("Demo mode");
    return;
  }

  state.report.fieldNotes = dom.fieldNotes.value;
  state.report.homeownerNotes = dom.homeownerNotes.value;

  // Phase 73 sub-phase D: optionally piggyback a punch item or task
  // completion onto the report sync. Both are consumed by the portal
  // edge function inside the same POST so we don't burn a second
  // round-trip when the technician taps "Mark done" in the field.
  const completePunchItemId = state.pendingCompletePunchItemId || null;
  const completeTaskId = state.pendingCompleteTaskId || null;

  const response = await fetch(EDGE_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      token,
      report: state.report,
      coordinationAction: state.pendingCoordinationAction,
      completePunchItemId,
      completeTaskId,
    }),
  });

  if (!response.ok) throw new Error("Failed to sync draft");

  const payload = await response.json();
  state.session = payload.session || state.session;
  state.request = payload.request || state.request;
  state.messages = payload.messages || state.messages;
  if (payload.homeProfile) {
    state.homeProfile = payload.homeProfile;
  }
  if (payload.report) {
    state.report.reportStatus = payload.report.report_status || state.report.reportStatus;
    state.report.coordinationStatus =
      payload.report.coordination_status || state.report.coordinationStatus;
    state.report.systemsSnapshot = payload.report.systems_snapshot || state.report.systemsSnapshot;
    state.report.recommendations = payload.report.recommendations || state.report.recommendations;
  }
  state.pendingCoordinationAction = null;
  state.pendingCompletePunchItemId = null;
  state.pendingCompleteTaskId = null;
  state.dirty = false;
  saveDraft();
  render();
  setConnectivity();
  setSyncState("Synced just now");
}

// Phase 73 sub-phase D: optimistic "Mark done" for a punch item. Pulls
// it out of the local state immediately, queues the writeback for the
// next syncDraft, and triggers a sync. If the sync fails the item
// reappears on the next portal GET — we don't add it back optimistically
// to keep the queue logic simple.
async function markPunchItemDone(punchItemId) {
  if (!punchItemId) return;
  state.homeProfile.punchList = (state.homeProfile.punchList || []).filter(
    (item) => item.id !== punchItemId,
  );
  state.pendingCompletePunchItemId = punchItemId;
  markDirty("Punch item completion queued");
  try {
    await syncDraft();
  } catch (error) {
    setSyncState(error instanceof Error ? error.message : "Sync failed");
  }
}

// Phase 73 sub-phase D: optimistic completion for a homeowner task.
// Same pattern as markPunchItemDone — pull from the visible list,
// queue the writeback, sync.
async function markOpenTaskDone(taskId) {
  if (!taskId) return;
  state.homeProfile.openTasks = (state.homeProfile.openTasks || []).filter(
    (task) => task.id !== taskId,
  );
  state.pendingCompleteTaskId = taskId;
  markDirty("Task completion queued");
  try {
    await syncDraft();
  } catch (error) {
    setSyncState(error instanceof Error ? error.message : "Sync failed");
  }
}

/**
 * Send a free-form chat message to the homeowner. Reuses the
 * ask_question coordination action (which is the existing message
 * sender) but preserves coordination_status so casual chat doesn't
 * flip the visit to "awaiting_homeowner". Optimistic append so the
 * message appears in the local list instantly.
 */
async function sendChatMessage(body) {
  const trimmed = compactString(body);
  if (!trimmed) return;
  const previousStatus = state.report.coordinationStatus;

  // Optimistic local insert so the tech sees the message immediately.
  state.messages = [
    ...state.messages,
    {
      id: `local-${Date.now()}`,
      sender_role: "haven",
      created_at: new Date().toISOString(),
      body: trimmed,
    },
  ];
  state.pendingCoordinationAction = {
    type: "ask_question",
    message: trimmed,
    proposedDate: "",
    quietStatus: true, // hint to syncDraft to restore prior status
  };

  dom.chatInput.value = "";
  dom.chatSendButton.disabled = true;
  dom.chatStatus.textContent = "Sending…";
  dom.chatStatus.classList.remove("error");
  render();
  markDirty("Message queued");

  try {
    await syncDraft();
    // Restore the prior coordination status so the chat doesn't bump
    // visit state. ask_question would otherwise stamp
    // "awaiting_homeowner" on the report.
    if (previousStatus && state.report.coordinationStatus === "awaiting_homeowner") {
      state.report.coordinationStatus = previousStatus;
    }
    dom.chatStatus.textContent = "Sent";
    setTimeout(() => {
      if (dom.chatStatus.textContent === "Sent") dom.chatStatus.textContent = "";
    }, 2200);
  } catch (error) {
    dom.chatStatus.textContent = error instanceof Error ? error.message : "Couldn't send.";
    dom.chatStatus.classList.add("error");
  }
}

async function applyCoordinationAction(type) {
  state.pendingCoordinationAction = {
    type,
    message: dom.coordinationNote.value,
    proposedDate: dom.proposedDate.value,
  };

  switch (type) {
    case "confirm_date":
      state.report.coordinationStatus = "confirmed";
      break;
    case "propose_other_dates":
      state.report.coordinationStatus = "alternate_dates_proposed";
      break;
    case "ask_question":
      state.report.coordinationStatus = "awaiting_homeowner";
      break;
    case "decline_visit":
      state.report.coordinationStatus = "declined";
      break;
    default:
      break;
  }

  markDirty("Coordination updated locally");
  try {
    await syncDraft();
  } catch {
    setSyncState("Could not sync right now");
  }
}

function registerEvents() {
  dom.fieldNotes.addEventListener("input", () => {
    state.report.fieldNotes = dom.fieldNotes.value;
    markDirty("Notes updated locally");
  });

  dom.homeownerNotes.addEventListener("input", () => {
    state.report.homeownerNotes = dom.homeownerNotes.value;
    markDirty("Notes updated locally");
  });

  dom.addSystemPhotoButton.addEventListener("click", () => {
    dom.addSystemPhotoInput.click();
  });

  dom.profileCaptureButton.addEventListener("click", () => {
    dom.addSystemPhotoInput.click();
  });

  dom.profileReviewSetupButton.addEventListener("click", () => {
    const target = syncableSetupPrompts().length > 0 ? dom.firstVisitCard : dom.systemList;
    target.scrollIntoView({ behavior: "smooth", block: "start" });
  });

  dom.addSystemPhotoInput.addEventListener("change", async (event) => {
    const file = event.target.files?.[0];
    if (!file) return;
    await addSystemFromPhoto(file);
    dom.addSystemPhotoInput.value = "";
  });

  dom.addSystemButton.addEventListener("click", () => {
    state.report.systemsSnapshot = [
      ...syncableSystems(),
      {
        id: `local-${Date.now()}`,
        name: "",
        category: "Other",
        manufacturer: "",
        model_number: "",
        serial_number: "",
        install_date: "",
        notes: "",
        last_service_date: "",
        next_service_due: "",
        needs_setup: true,
        serviced: false,
        catalog_entry_id: null,
        catalog_series: null,
        catalog_model_name: null,
        catalog_features: [],
        catalog_fuel_type: null,
        catalog_enriched_at: null,
        catalog_display_name: null,
        catalog_subtitle: null,
        identification_confidence: null,
        identified_raw_text: null,
        label_photo_name: null,
        photo_captured_at: null,
        subtype: null,
      },
    ];
    markDirty("Added a system locally");
    render();
  });

  dom.confirmDateButton.addEventListener("click", async () => {
    await applyCoordinationAction("confirm_date");
  });

  dom.proposeDateButton.addEventListener("click", async () => {
    await applyCoordinationAction("propose_other_dates");
  });

  dom.askQuestionButton.addEventListener("click", async () => {
    await applyCoordinationAction("ask_question");
  });

  // Free-form chat composer — sends a message to the homeowner without
  // touching coordination_status. Piggybacks the ask_question
  // coordination action with the chat input as the message body, then
  // restores the prior status so the visit isn't bumped to
  // "awaiting_homeowner" just because the tech said hi.
  dom.chatInput.addEventListener("input", () => {
    dom.chatSendButton.disabled = !dom.chatInput.value.trim();
  });

  dom.chatComposer.addEventListener("submit", async (event) => {
    event.preventDefault();
    const body = dom.chatInput.value.trim();
    if (!body) return;
    await sendChatMessage(body);
  });

  dom.declineButton.addEventListener("click", async () => {
    await applyCoordinationAction("decline_visit");
  });

  dom.startVisitButton.addEventListener("click", () => {
    if (!executionUnlocked()) {
      setSyncState("Confirm the visit first");
      return;
    }
    state.report.reportStatus = "in_progress";
    state.report.coordinationStatus = "checked_in";
    state.report.startedAt = state.report.startedAt || new Date().toISOString();
    markDirty("Visit checked in");
  });

  dom.completeVisitButton.addEventListener("click", () => {
    if (!executionUnlocked()) {
      setSyncState("Confirm the visit first");
      return;
    }
    state.report.reportStatus = "completed";
    state.report.coordinationStatus = "completed";
    state.report.completedAt = new Date().toISOString();
    markDirty("Visit marked complete locally");
  });

  dom.syncButton.addEventListener("click", async () => {
    try {
      await syncDraft();
    } catch {
      setSyncState("Could not sync right now");
    }
  });

  window.addEventListener("online", async () => {
    setConnectivity();
    try {
      if (state.dirty) await syncDraft();
    } catch {
      setSyncState("Back online, but sync still failed");
    }
  });

  window.addEventListener("offline", () => {
    setConnectivity();
    setSyncState("Offline, draft saved locally");
  });
}

async function boot() {
  const cached = loadDraft();
  if (cached?.session) {
    state.session = cached.session;
    state.request = cached.request || null;
    state.messages = cached.messages || [];
    state.pendingCoordinationAction = cached.pendingCoordinationAction || null;
    state.report = cached.report || state.report;
    state.dirty = Boolean(cached.dirty);
    render();
  }

  registerEvents();
  setConnectivity();

  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("handyman-visit-sw.js").catch(() => {});
  }

  try {
    await fetchPortal();
  } catch {
    if (!state.session) {
      state.session = demoSession;
      render();
    }
    setConnectivity();
    setSyncState("Using saved local draft");
  }

  // Phase 75: live message polling. The portal token is anonymous so
  // we can't subscribe to Supabase Realtime here — but a 30s pull on
  // page focus + every 30s while the tab is visible covers the
  // overwhelmingly common case of the tech glancing at the phone
  // between systems. We skip while offline or when the document is
  // hidden to save battery.
  let pollTimer = null;
  function startPolling() {
    stopPolling();
    pollTimer = setInterval(() => {
      if (document.hidden || !navigator.onLine || !token) return;
      if (state.dirty) return; // mid-edit; let syncDraft win
      fetchPortal().catch(() => {/* swallow — next tick will retry */});
    }, 30_000);
  }
  function stopPolling() {
    if (pollTimer) clearInterval(pollTimer);
    pollTimer = null;
  }
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) return;
    if (!navigator.onLine || !token || state.dirty) return;
    fetchPortal().catch(() => {});
  });
  startPolling();
}

boot();

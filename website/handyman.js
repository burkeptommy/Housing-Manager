import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = "https://jsucwnkntdrxhysojgri.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";
const PROVIDER_API_URL = `${SUPABASE_URL}/functions/v1/handyman-provider`;

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
const params = new URLSearchParams(window.location.search);
const inviteToken = params.get("invite") || "";
const teamInviteToken = params.get("teamInvite") || "";

const dom = {
  pageGrid: document.getElementById("page-grid"),
  experienceTitle: document.getElementById("experience-title"),
  experienceLede: document.getElementById("experience-lede"),
  workspaceModePill: document.getElementById("workspace-mode-pill"),
  authPanel: document.getElementById("auth-panel"),
  workspacePanel: document.getElementById("workspace-panel"),
  authStatus: document.getElementById("auth-status"),
  authFeedback: document.getElementById("auth-feedback"),
  authHelperCopy: document.getElementById("auth-helper-copy"),
  signOutButton: document.getElementById("sign-out-button"),
  invitePreviewCard: document.getElementById("invite-preview-card"),
  inviteKicker: document.getElementById("invite-kicker"),
  inviteTitle: document.getElementById("invite-title"),
  inviteStatus: document.getElementById("invite-status"),
  inviteSummary: document.getElementById("invite-summary"),
  inviteLabelA: document.getElementById("invite-label-a"),
  inviteLabelB: document.getElementById("invite-label-b"),
  inviteLabelC: document.getElementById("invite-label-c"),
  inviteLabelD: document.getElementById("invite-label-d"),
  inviteHome: document.getElementById("invite-home"),
  inviteDate: document.getElementById("invite-date"),
  inviteCompany: document.getElementById("invite-company"),
  inviteFieldLink: document.getElementById("invite-field-link"),
  companyField: document.getElementById("company-field"),
  showSignIn: document.getElementById("show-sign-in"),
  showSignUp: document.getElementById("show-sign-up"),
  signInForm: document.getElementById("sign-in-form"),
  signUpForm: document.getElementById("sign-up-form"),
  signInEmail: document.getElementById("sign-in-email"),
  signInPassword: document.getElementById("sign-in-password"),
  signUpName: document.getElementById("sign-up-name"),
  signUpCompany: document.getElementById("sign-up-company"),
  signUpEmail: document.getElementById("sign-up-email"),
  signUpPhone: document.getElementById("sign-up-phone"),
  signUpWebsite: document.getElementById("sign-up-website"),
  signUpPassword: document.getElementById("sign-up-password"),
  workspaceName: document.getElementById("workspace-name"),
  workspaceMeta: document.getElementById("workspace-meta"),
  workspaceTags: document.getElementById("workspace-tags"),
  currentRoleLabel: document.getElementById("current-role-label"),
  currentRoleCopy: document.getElementById("current-role-copy"),
  permissionTags: document.getElementById("permission-tags"),
  navButtons: Array.from(document.querySelectorAll(".nav-button")),
  tabPanels: Array.from(document.querySelectorAll(".tab-panel")),
  controlBar: document.querySelector(".control-bar"),
  quickNewQuote: document.getElementById("quick-new-quote"),
  quickOpenMyDay: document.getElementById("quick-open-my-day"),
  mobileSnapshot: document.getElementById("mobile-snapshot"),
  mobileSnapshotEyebrow: document.getElementById("mobile-snapshot-eyebrow"),
  mobileSnapshotTitle: document.getElementById("mobile-snapshot-title"),
  mobileSnapshotChip: document.getElementById("mobile-snapshot-chip"),
  mobileKpiGrid: document.getElementById("mobile-kpi-grid"),
  mobilePriorityList: document.getElementById("mobile-priority-list"),
  statsGrid: document.getElementById("stats-grid"),
  todayBoard: document.getElementById("today-board"),
  crewWorkload: document.getElementById("crew-workload"),
  quotePipeline: document.getElementById("quote-pipeline"),
  overviewMessages: document.getElementById("overview-messages"),
  dispatchSummary: document.getElementById("dispatch-summary"),
  dispatchBoard: document.getElementById("dispatch-board"),
  calendarList: document.getElementById("calendar-list"),
  routesList: document.getElementById("routes-list"),
  teamForm: document.getElementById("team-form"),
  teamName: document.getElementById("team-name"),
  teamEmail: document.getElementById("team-email"),
  teamPhone: document.getElementById("team-phone"),
  teamRole: document.getElementById("team-role"),
  teamTitle: document.getElementById("team-title"),
  teamFeedback: document.getElementById("team-feedback"),
  crewList: document.getElementById("crew-list"),
  homesList: document.getElementById("homes-list"),
  quotesList: document.getElementById("quotes-list"),
  recentWorkList: document.getElementById("recent-work-list"),
  messagesList: document.getElementById("messages-list"),
  messageThreadDetail: document.getElementById("message-thread-detail"),
  messageThreadHistory: document.getElementById("message-thread-history"),
  messageForm: document.getElementById("message-form"),
  messageRequestTitle: document.getElementById("message-request-title"),
  messageStatus: document.getElementById("message-status"),
  messageBody: document.getElementById("message-body"),
  sendMessageButton: document.getElementById("send-message-button"),
  // Chez v1: directory listing form
  directoryStatusPill: document.getElementById("directory-status-pill"),
  directoryForm: document.getElementById("directory-form"),
  directoryListed: document.getElementById("directory-listed"),
  directoryState: document.getElementById("directory-state"),
  directoryCity: document.getElementById("directory-city"),
  directoryZips: document.getElementById("directory-zips"),
  directoryCategories: document.getElementById("directory-categories"),
  directoryBlurb: document.getElementById("directory-blurb"),
  directoryHeadshot: document.getElementById("directory-headshot"),
  directoryFeedback: document.getElementById("directory-feedback"),
  directorySaveButton: document.getElementById("directory-save-button"),
  savedItemForm: document.getElementById("saved-item-form"),
  savedItemName: document.getElementById("saved-item-name"),
  savedItemDescription: document.getElementById("saved-item-description"),
  savedItemUnit: document.getElementById("saved-item-unit"),
  savedItemQuantity: document.getElementById("saved-item-quantity"),
  savedItemPrice: document.getElementById("saved-item-price"),
  savedItemsList: document.getElementById("saved-items-list"),
  savedItemPicker: document.getElementById("saved-item-picker"),
  newQuoteButton: document.getElementById("new-quote-button"),
  quoteModal: document.getElementById("quote-modal"),
  closeQuoteModal: document.getElementById("close-quote-modal"),
  quoteModalTitle: document.getElementById("quote-modal-title"),
  quoteForm: document.getElementById("quote-form"),
  quoteKindLinked: document.getElementById("quote-kind-linked"),
  quoteKindProspect: document.getElementById("quote-kind-prospect"),
  quoteLinkedMode: document.getElementById("quote-linked-mode"),
  quoteProspectMode: document.getElementById("quote-prospect-mode"),
  quoteContextSelect: document.getElementById("quote-context-select"),
  quoteRequestTitle: document.getElementById("quote-request-title"),
  quoteContextSummary: document.getElementById("quote-context-summary"),
  quoteProspectSummary: document.getElementById("quote-prospect-summary"),
  quoteContextHelper: document.getElementById("quote-context-helper"),
  quoteProspectName: document.getElementById("quote-prospect-name"),
  quoteProspectEmail: document.getElementById("quote-prospect-email"),
  quoteProspectPhone: document.getElementById("quote-prospect-phone"),
  quoteProspectAddress: document.getElementById("quote-prospect-address"),
  quoteTitle: document.getElementById("quote-title"),
  quoteHomeownerMessage: document.getElementById("quote-homeowner-message"),
  quoteScopeNotes: document.getElementById("quote-scope-notes"),
  addLineItemButton: document.getElementById("add-line-item-button"),
  quoteLineItems: document.getElementById("quote-line-items"),
  quoteSubtotal: document.getElementById("quote-subtotal"),
  saveQuoteButton: document.getElementById("save-quote-button"),
  sendQuoteButton: document.getElementById("send-quote-button"),
  quoteFeedback: document.getElementById("quote-feedback"),
  statCardTemplate: document.getElementById("stat-card-template"),
};

const state = {
  authMode: "sign-in",
  session: null,
  invitePreview: null,
  dashboard: null,
  selectedRequestId: null,
  quoteDraft: null,
  inviteLinked: false,
  activeTab: "overview",
  tabInitialized: false,
  deviceMode: "desktop",
};

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function setFeedback(node, text, isError = false) {
  if (!node) return;
  node.textContent = text || "";
  node.style.color = text ? (isError ? "#c65241" : "#2f8b65") : "";
}

function money(value) {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(Number.isFinite(Number(value)) ? Number(value) : 0);
}

function shortDate(value) {
  if (!value) return "TBD";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: date.getFullYear() !== new Date().getFullYear() ? "numeric" : undefined,
  });
}

function shortDateTime(value) {
  if (!value) return "TBD";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

function isoDate(value) {
  if (!value) return "";
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return value;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return date.toISOString().slice(0, 10);
}

function todayIso() {
  return new Date().toISOString().slice(0, 10);
}

function quoteTotals(lineItems) {
  return Math.round(
    lineItems.reduce((sum, item) => sum + Number(item.quantity || 0) * Number(item.unitPrice || 0), 0) * 100,
  ) / 100;
}

function routeDateForVisit(visit) {
  return (
    visit?.assignment?.routeDate ||
    visit?.routeDate ||
    visit?.visit?.scheduledDate ||
    visit?.visit?.dueDate ||
    ""
  );
}

function routeWindowLabel(visit) {
  const start = visit?.assignment?.windowStartTime || "";
  const end = visit?.assignment?.windowEndTime || "";
  if (!start && !end) return "";
  if (start && end) return `${start} – ${end}`;
  return start || end;
}

function statusChip(statusLabel, tone = "") {
  const toneClass = tone ? ` ${tone}` : "";
  return `<span class="data-chip${toneClass}">${escapeHtml(statusLabel)}</span>`;
}

function detectDeviceMode() {
  const compactViewport = window.matchMedia("(max-width: 960px)").matches;
  const coarsePointer = window.matchMedia("(pointer: coarse)").matches && window.matchMedia("(hover: none)").matches;
  return compactViewport || (coarsePointer && window.innerWidth < 1180) ? "mobile" : "desktop";
}

function isMobileMode() {
  return state.deviceMode === "mobile";
}

function syncExperienceMode() {
  state.deviceMode = detectDeviceMode();
  const mobile = isMobileMode();
  document.body.classList.toggle("device-mobile", mobile);
  document.body.classList.toggle("device-desktop", !mobile);

  const signedIn = Boolean(state.dashboard && !state.dashboard.needsWorkspace);
  dom.pageGrid.classList.toggle("workspace-live", signedIn);
  if (!signedIn) {
    dom.workspaceModePill.textContent = "Secure access";
    dom.experienceTitle.textContent = "Run the company. Keep every home moving.";
    dom.experienceLede.textContent =
      "Owners and dispatchers manage routing, calendars, crew assignments, quotes, and home history while each technician gets a focused workspace for visits, messaging, systems capture, and execution.";
    dom.mobileSnapshot.classList.add("hidden");
    return;
  }

  const permissions = providerPermissions();
  if (mobile) {
    dom.workspaceModePill.textContent = permissions.isFieldTechnician ? "Today's work" : "Active queue";
    dom.experienceTitle.textContent = permissions.isFieldTechnician
      ? "See your stops, message homes, and complete the work."
      : "Keep the queue moving.";
    dom.experienceLede.textContent = permissions.isFieldTechnician
      ? "Your assigned visits, homeowner replies, home systems context, and execution tools stay close at hand."
      : "Stay on top of the active queue, homeowner communication, homes, and quick quote follow-up.";
    return;
  }

  dom.workspaceModePill.textContent = permissions.isFieldTechnician ? "Assigned work" : "Operations desk";
  dom.experienceTitle.textContent = permissions.isFieldTechnician
    ? `${state.dashboard.workspace.companyName} field workspace`
    : `${state.dashboard.workspace.companyName} operations desk`;
  dom.experienceLede.textContent = permissions.isFieldTechnician
    ? "See assigned work, homeowner context, home systems, and visit details in one place."
    : "Route visits, manage the crew, plan the calendar, and build quotes from one Chez Handyman workspace.";
}

function workspaceSeed() {
  return {
    fullName: dom.signUpName.value.trim(),
    companyName: dom.signUpCompany.value.trim() || state.invitePreview?.workspace?.companyName || state.invitePreview?.contractor?.companyName || "",
    phone: dom.signUpPhone.value.trim() || state.invitePreview?.member?.phone || state.invitePreview?.contractor?.phone || "",
    website: dom.signUpWebsite.value.trim(),
    inviteToken,
    teamInviteToken,
    title: state.invitePreview?.member?.title || "",
  };
}

function providerPermissions() {
  return state.dashboard?.permissions || {
    canManageCrew: false,
    canAssignWork: false,
    canBuildQuotes: false,
    canSeeFinancials: false,
    canSeeWorkspaceOverview: false,
    isFieldTechnician: false,
  };
}

async function providerRequest(method = "GET", body = null, search = "") {
  const session = state.session || (await supabase.auth.getSession()).data.session;
  const headers = {
    "Content-Type": "application/json",
  };
  if (session?.access_token) {
    headers.Authorization = `Bearer ${session.access_token}`;
  }

  const response = await fetch(`${PROVIDER_API_URL}${search}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(payload.error || "Request failed");
  }
  return payload;
}

function showAuthMode(mode) {
  state.authMode = mode;
  dom.showSignIn.classList.toggle("active", mode === "sign-in");
  dom.showSignUp.classList.toggle("active", mode === "sign-up");
  dom.signInForm.classList.toggle("hidden", mode !== "sign-in");
  dom.signUpForm.classList.toggle("hidden", mode !== "sign-up");
}

function showTab(name) {
  state.activeTab = name;
  dom.navButtons.forEach((button) => {
    if (button.classList.contains("hidden")) return;
    button.classList.toggle("active", button.dataset.tab === name);
  });
  dom.tabPanels.forEach((panel) => {
    panel.classList.toggle("active", panel.dataset.panel === name);
  });
}

function copyText(text) {
  if (!text) return;
  if (navigator.clipboard?.writeText) {
    navigator.clipboard.writeText(text).catch(() => undefined);
  }
}

async function loadInvitePreview() {
  if (!inviteToken && !teamInviteToken) {
    dom.invitePreviewCard.classList.add("hidden");
    return;
  }

  try {
    if (teamInviteToken) {
      const payload = await fetch(`${PROVIDER_API_URL}?teamInvite=${encodeURIComponent(teamInviteToken)}`).then((response) => response.json());
      if (!payload?.teamInvite) throw new Error("Missing team invite");
      state.invitePreview = payload.teamInvite;

      dom.inviteKicker.textContent = "Team invite";
      dom.inviteTitle.textContent = `Join ${payload.teamInvite.workspace.companyName}`;
      dom.inviteStatus.textContent = payload.teamInvite.member.roleLabel;
      dom.inviteSummary.textContent =
        "Create your secure login to see your assigned visits, route, homes, messages, and field workspaces from Chez Handyman.";
      dom.inviteLabelA.textContent = "Company";
      dom.inviteLabelB.textContent = "Role";
      dom.inviteLabelC.textContent = "Invitee";
      dom.inviteLabelD.textContent = "Join link";
      dom.inviteHome.textContent = payload.teamInvite.workspace.companyName;
      dom.inviteDate.textContent = payload.teamInvite.member.roleLabel;
      dom.inviteCompany.textContent = payload.teamInvite.member.fullName;
      dom.inviteFieldLink.href = payload.teamInvite.inviteUrl || "#";
      dom.inviteFieldLink.textContent = "Open secure team invite";
      dom.authHelperCopy.textContent = "This invite attaches you to an existing Chez Handyman company account. Once you log in, the workspace will open with the visits, homes, messages, and tools that match your role.";
      dom.companyField.classList.add("hidden");
      dom.signUpCompany.value = payload.teamInvite.workspace.companyName || "";
      dom.signUpName.value = payload.teamInvite.member.fullName || "";
      dom.signUpEmail.value = payload.teamInvite.member.email || "";
      dom.signUpPhone.value = payload.teamInvite.member.phone || "";
      dom.signInEmail.value = payload.teamInvite.member.email || "";
      return;
    }

    const payload = await fetch(`${PROVIDER_API_URL}?invite=${encodeURIComponent(inviteToken)}`).then((response) => response.json());
    if (!payload?.invite) throw new Error("Missing invite");
    state.invitePreview = payload.invite;
    dom.inviteKicker.textContent = "Visit invite";
    dom.inviteTitle.textContent = payload.invite.title || "Claim this Chez visit";
    dom.inviteStatus.textContent = payload.invite.requestStatusLabel || "Secure link";
    dom.inviteSummary.textContent =
      "Create your Chez Handyman account to confirm this visit, route future work, and keep every home's systems record sharper after each stop.";
    dom.inviteLabelA.textContent = "Home";
    dom.inviteLabelB.textContent = "Requested date";
    dom.inviteLabelC.textContent = "Company";
    dom.inviteLabelD.textContent = "Field workspace";
    dom.inviteHome.textContent = payload.invite.property?.name || "Home";
    dom.inviteDate.textContent = payload.invite.preferredTiming || "TBD";
    dom.inviteCompany.textContent = payload.invite.contractor?.companyName || "Handyman company";
    dom.inviteFieldLink.href = payload.invite.fieldUrl || "#";
    dom.inviteFieldLink.textContent = "Preview linked visit workspace";
    dom.companyField.classList.remove("hidden");
    if (!dom.signUpCompany.value) dom.signUpCompany.value = payload.invite.contractor?.companyName || "";
    if (!dom.signUpPhone.value) dom.signUpPhone.value = payload.invite.contractor?.phone || "";
  } catch {
    dom.invitePreviewCard.classList.add("hidden");
  }
}

async function refreshWorkspace() {
  syncExperienceMode();
  const { data } = await supabase.auth.getSession();
  state.session = data.session;

  if (!state.session) {
    document.body.classList.remove("workspace-authenticated");
    dom.pageGrid.classList.remove("workspace-live");
    dom.authStatus.textContent = "Signed out";
    dom.authPanel.classList.remove("hidden");
    dom.workspacePanel.classList.add("hidden");
    dom.signOutButton.classList.add("hidden");
    return;
  }

  dom.authStatus.textContent = state.session.user.email || "Signed in";
  dom.signOutButton.classList.remove("hidden");

  // Chez v2 (Phase 67): hide the auth pitch immediately on session
  // confirmation. The user is going to /operations/ in a moment — they
  // shouldn't see a "sign in" form while we confirm the workspace.
  dom.authPanel.classList.add("hidden");

  let dashboard = await providerRequest("GET");

  if (dashboard.needsWorkspace) {
    dom.pageGrid.classList.remove("workspace-live");
    const seed = workspaceSeed();
    if (teamInviteToken || seed.companyName) {
      dashboard = await providerRequest("POST", {
        action: "bootstrap_workspace",
        ...seed,
      });
      setFeedback(dom.authFeedback, "Workspace ready. Loading your Chez Handyman desk.");
    } else {
      dom.authPanel.classList.remove("hidden");
      dom.workspacePanel.classList.add("hidden");
      showAuthMode("sign-up");
      setFeedback(dom.authFeedback, "Finish the account details to create your provider workspace.", true);
      return;
    }
  } else if (inviteToken && !state.inviteLinked) {
    dashboard = await providerRequest("POST", {
      action: "link_invite",
      inviteToken,
    });
    state.inviteLinked = true;
  }

  state.dashboard = dashboard;

  // Chez v2 (Phase 67): hand off to the Operations Desk SPA BEFORE
  // adding the `workspace-authenticated` class — that class is what
  // reveals the embedded workspace panel (now deprecated). Skipping
  // the class-add prevents a flash of the old UI before the navigation
  // takes effect. Honor ?next= so deep links from the SPA round-trip
  // through sign-out → sign-in.
  const next = params.get("next") || "/operations/";
  const safeNext = next.startsWith("/operations") ? next : "/operations/";
  window.location.assign(safeNext);
  return;
}

function applyContextualNav() {
  const permissions = providerPermissions();
  const mobile = isMobileMode();

  const buttonMap = Object.fromEntries(dom.navButtons.map((button) => [button.dataset.tab, button]));
  const allowedTabs = mobile
    ? new Set(["dispatch", "messages", "homes"])
    : new Set(["overview", "dispatch", "calendar", "routes", "homes", "messages"]);
  if (!mobile && permissions.canManageCrew) allowedTabs.add("crew");
  if (permissions.canBuildQuotes) allowedTabs.add("quotes");

  dom.navButtons.forEach((button) => {
    const isAllowed = allowedTabs.has(button.dataset.tab);
    button.classList.toggle("hidden", !isAllowed);
  });

  if (buttonMap.dispatch) {
    buttonMap.dispatch.textContent = mobile
      ? (permissions.isFieldTechnician ? "My day" : "Visits")
      : (permissions.canAssignWork ? "Dispatch" : "Visits");
  }
  if (buttonMap.overview) {
    buttonMap.overview.textContent = "Overview";
  }
  if (buttonMap.messages) buttonMap.messages.textContent = mobile ? "Chat" : "Messages";
  if (buttonMap.homes) buttonMap.homes.textContent = "Homes";
  if (buttonMap.quotes) buttonMap.quotes.textContent = "Quotes";

  if (!allowedTabs.has(state.activeTab)) {
    state.activeTab = mobile ? "dispatch" : (permissions.isFieldTechnician ? "dispatch" : "overview");
  }
  showTab(state.activeTab);
}

function renderWorkspaceHeader() {
  const dashboard = state.dashboard;
  const permissions = providerPermissions();
  const mobile = isMobileMode();
  const activeTags = [
    `${dashboard.workspace.contractorCount} contractor link${dashboard.workspace.contractorCount === 1 ? "" : "s"}`,
    `${dashboard.workspace.activeMemberCount} active team`,
    `${dashboard.stats.upcomingVisits} upcoming`,
    `${dashboard.stats.homesServiced} homes`,
  ];

  dom.workspaceName.textContent = dashboard.workspace.companyName;
  dom.workspaceMeta.textContent = [
    dashboard.currentUser.fullName || dashboard.currentUser.email,
    dashboard.currentUser.roleLabel,
    dashboard.workspace.primaryPhone || dashboard.workspace.primaryEmail,
  ]
    .filter(Boolean)
    .join(" · ");

  dom.workspaceTags.innerHTML = activeTags
    .map((text) => `<span class="data-chip">${escapeHtml(text)}</span>`)
    .join("");

  dom.currentRoleLabel.textContent = permissions.isFieldTechnician ? "Field workspace" : "Operations workspace";
  dom.currentRoleCopy.textContent = permissions.isFieldTechnician
    ? "Your workspace centers on assigned visits, field execution, systems capture, and homeowner updates."
    : "This workspace is tuned for routing, crew management, calendar planning, quoting, and message orchestration across every home.";

  const permissionTags = [];
  if (permissions.canAssignWork) permissionTags.push("Dispatch");
  if (permissions.canManageCrew) permissionTags.push("Crew admin");
  if (permissions.canBuildQuotes) permissionTags.push("Quotes");
  if (permissions.isFieldTechnician) permissionTags.push("Field execution");
  permissionTags.push(dashboard.currentUser.roleLabel);

  dom.permissionTags.innerHTML = permissionTags
    .map((text) => `<span class="data-chip">${escapeHtml(text)}</span>`)
    .join("");

  if (mobile) {
    if (permissions.isFieldTechnician) {
      dom.controlBar.querySelector(".section-eyebrow").textContent = "Today's work";
      dom.controlBar.querySelector("h3").textContent = "Open the next stop, review the home, and keep updates flowing.";
      dom.controlBar.querySelector(".card-copy").textContent = "Assigned visits, homeowner chat, homes, and execution stay front and center.";
      dom.quickOpenMyDay.textContent = "My day";
    } else {
      dom.controlBar.querySelector(".section-eyebrow").textContent = "Active queue";
      dom.controlBar.querySelector("h3").textContent = "Check the active queue, answer homeowners, and keep the crew moving.";
      dom.controlBar.querySelector(".card-copy").textContent = "Review the queue, make quick routing decisions, answer messages, and keep follow-up moving.";
      dom.quickOpenMyDay.textContent = "Open visits";
    }
    dom.quickNewQuote.textContent = "Quotes";
  } else if (permissions.isFieldTechnician) {
    dom.controlBar.querySelector(".section-eyebrow").textContent = "Field workspace";
    dom.controlBar.querySelector("h3").textContent = "See your assigned work, today's route, and the homes you need to service.";
    dom.controlBar.querySelector(".card-copy").textContent = "This view keeps the field team focused on execution while still giving broader context when it is useful.";
    dom.quickOpenMyDay.textContent = "Open visits";
    dom.quickNewQuote.textContent = "New quote";
  } else {
    dom.controlBar.querySelector(".section-eyebrow").textContent = "Operations";
    dom.controlBar.querySelector("h3").textContent = "Own the queue, route the field team, and keep every home moving forward.";
    dom.controlBar.querySelector(".card-copy").textContent = "Plan the week, route jobs, manage the crew, and build quotes from one Chez Handyman workspace.";
    dom.quickOpenMyDay.textContent = "Open my day";
    dom.quickNewQuote.textContent = "New quote";
  }

  dom.quickNewQuote.classList.toggle("hidden", !permissions.canBuildQuotes || permissions.isFieldTechnician);
  dom.newQuoteButton.classList.toggle("hidden", !permissions.canBuildQuotes);
}

function renderStats() {
  const stats = state.dashboard.stats;
  const permissions = providerPermissions();
  const specs = isMobileMode()
    ? permissions.isFieldTechnician
      ? [
          ["My visits", stats.myAssignedVisits, "Assigned right now"],
          ["Today", stats.todayStops, "Stops on today’s list"],
          ["Messages", stats.openThreads, "Homeowner threads"],
        ]
      : [
          ["Queue", stats.requestedVisits, "Visits needing company action"],
          ["Unassigned", stats.unassignedVisits, "Still need a tech"],
          ["Quotes", stats.draftQuotes + stats.quotesSent, "Draft and sent scopes"],
        ]
    : permissions.isFieldTechnician
      ? [
          ["Assigned", stats.myAssignedVisits, "Visits currently routed to you"],
          ["Today", stats.todayStops, "Stops planned for today"],
          ["Upcoming", stats.upcomingVisits, "Confirmed or actively scheduled work"],
          ["Messages", stats.openThreads, "Homeowner threads in your queue"],
          ["Completed", stats.completedVisits, "Recent work closed out"],
          ["Homes", stats.homesServiced, "Homes visible in your field workspace"],
        ]
      : [
          ["Requested", stats.requestedVisits, "Homeowner work waiting on a company reply"],
          ["Unassigned", stats.unassignedVisits, "Jobs that still need a technician"],
          ["Today", stats.todayStops, "Stops currently on today's route board"],
          ["Crew", stats.activeMembers, "Active team members in the workspace"],
          ["Draft quotes", stats.draftQuotes, "Scopes still being priced internally"],
          ["Sent quotes", stats.quotesSent, "Quotes already in homeowner communication"],
        ];

  dom.statsGrid.innerHTML = "";
  dom.statsGrid.classList.toggle("compact-stats", isMobileMode());
  specs.forEach(([label, value, note]) => {
    const card = dom.statCardTemplate.content.firstElementChild.cloneNode(true);
    card.querySelector(".stat-label").textContent = label;
    card.querySelector(".stat-value").textContent = value;
    card.querySelector(".stat-note").textContent = note;
    dom.statsGrid.appendChild(card);
  });
}

function renderMobileSnapshot() {
  const mobile = isMobileMode();
  dom.mobileSnapshot.classList.toggle("hidden", !mobile);
  if (!mobile) return;

  const permissions = providerPermissions();
  const stats = state.dashboard.stats;
  const visits = state.dashboard.visits || [];
  const openVisits = visits.filter((visit) => !["completed", "cancelled", "declined"].includes(visit.status));
  const nextVisit = openVisits[0] || null;

  if (permissions.isFieldTechnician) {
    dom.mobileSnapshotEyebrow.textContent = "Today";
    dom.mobileSnapshotTitle.textContent = "Today in the field";
    dom.mobileSnapshotChip.textContent = "Live";
    dom.mobileKpiGrid.innerHTML = [
      ["My visits", stats.myAssignedVisits],
      ["Today", stats.todayStops],
      ["Homes", stats.homesServiced],
    ]
      .map(([label, value]) => `
        <article class="mobile-kpi-card">
          <span class="mobile-kpi-label">${escapeHtml(label)}</span>
          <strong class="mobile-kpi-value">${escapeHtml(value)}</strong>
        </article>
      `)
      .join("");

    dom.mobilePriorityList.innerHTML = nextVisit
      ? `
          <article class="mobile-priority-card">
            <p class="visit-title">Next up: ${escapeHtml(nextVisit.property?.name || "Home")}</p>
            <div class="visit-meta">${escapeHtml(nextVisit.title)} · ${escapeHtml(shortDate(routeDateForVisit(nextVisit) || todayIso()))}</div>
            <div class="chip-row">
              ${statusChip(nextVisit.statusLabel)}
              ${nextVisit.assignment?.memberName ? statusChip(nextVisit.assignment.memberName) : ""}
            </div>
            ${visitActionRow(nextVisit, { allowQuote: false })}
          </article>
        `
      : `<p class="card-copy">Assigned field work will appear here once it is routed to you.</p>`;
    wireRequestActionButtons(dom.mobilePriorityList);
    return;
  }

  dom.mobileSnapshotEyebrow.textContent = "Review mode";
  dom.mobileSnapshotTitle.textContent = "Keep the queue moving";
  dom.mobileSnapshotChip.textContent = "Live";
  dom.mobileKpiGrid.innerHTML = [
    ["Queue", stats.requestedVisits],
    ["Unassigned", stats.unassignedVisits],
    ["Quotes", stats.draftQuotes + stats.quotesSent],
  ]
    .map(([label, value]) => `
      <article class="mobile-kpi-card">
        <span class="mobile-kpi-label">${escapeHtml(label)}</span>
        <strong class="mobile-kpi-value">${escapeHtml(value)}</strong>
      </article>
    `)
    .join("");

  const spotlight = openVisits.slice(0, 2);
  dom.mobilePriorityList.innerHTML = spotlight.length
    ? spotlight.map((visit) => `
        <article class="mobile-priority-card">
          <p class="visit-title">${escapeHtml(visit.property?.name || "Home")} · ${escapeHtml(visit.title)}</p>
          <div class="visit-meta">${escapeHtml(visit.statusLabel)} · ${escapeHtml(routeDateForVisit(visit) ? shortDate(routeDateForVisit(visit)) : "Needs timing")}</div>
          <div class="chip-row">
            ${visit.assignment?.memberName ? statusChip(visit.assignment.memberName) : statusChip("Unassigned", "warning")}
            ${visit.quote?.statusLabel ? statusChip(visit.quote.statusLabel, "success") : ""}
          </div>
        </article>
      `).join("")
    : `<p class="card-copy">The live queue will show here once homeowners start routing work to this company.</p>`;
  wireRequestActionButtons(dom.mobilePriorityList);
}

function requestById(requestId) {
  return state.dashboard?.visits.find((visit) => visit.requestId === requestId) || null;
}

function quoteById(quoteId) {
  return state.dashboard?.quotes.find((quote) => quote.id === quoteId) || null;
}

function threadByRequestId(requestId) {
  return state.dashboard?.messages.find((thread) => thread.requestId === requestId) || null;
}

function isClosedRequestStatus(status) {
  return ["completed", "cancelled", "declined"].includes(status);
}

function relatedVisitsForProperty(propertyId) {
  if (!propertyId) return [];
  return (state.dashboard?.visits || []).filter((visit) => visit.property?.id === propertyId);
}

function buildQuoteContexts() {
  return [...(state.dashboard?.visits || [])]
    .sort((lhs, rhs) => {
      const leftClosed = isClosedRequestStatus(lhs.status);
      const rightClosed = isClosedRequestStatus(rhs.status);
      if (leftClosed !== rightClosed) return leftClosed ? 1 : -1;
      return String(rhs.updatedAt || "").localeCompare(String(lhs.updatedAt || ""));
    })
    .map((visit) => ({
      id: visit.requestId,
      requestId: visit.requestId,
      propertyName: visit.property?.name || "Home",
      propertyAddress: visit.property?.address || "",
      title: visit.title || "Handyman work",
      status: visit.status,
      statusLabel: visit.statusLabel,
      preferredTiming: visit.preferredTiming || visit.visit?.scheduledDate || visit.visit?.dueDate || "",
      assignmentName: visit.assignment?.memberName || "",
      quoteStatus: visit.quote?.statusLabel || "",
      quoteTotal: visit.quote?.total || 0,
      householdId: visit.householdId || "",
      propertyId: visit.property?.id || visit.propertyId || "",
      contractorId: visit.contractorId || "",
      visitTaskId: visit.visit?.id || null,
      lastMessage: visit.latestMessage?.body || "",
      lastMessageAt: visit.latestMessage?.createdAt || "",
      fieldWorkspaceUrl: visit.fieldWorkspace?.url || "",
    }));
}

function defaultQuoteContextId(explicitRequestId = null) {
  const contexts = buildQuoteContexts();
  if (!contexts.length) return null;
  if (explicitRequestId && contexts.some((context) => context.id === explicitRequestId)) {
    return explicitRequestId;
  }
  if (state.selectedRequestId && contexts.some((context) => context.id === state.selectedRequestId)) {
    return state.selectedRequestId;
  }
  return contexts.find((context) => !isClosedRequestStatus(context.status))?.id || contexts[0].id;
}

function quoteTitleForContext(context) {
  if (!context) return "Handyman quote";
  return `Quote for ${context.title || context.propertyName || "handyman work"}`;
}

function quoteTitleForProspect(name, address) {
  if (name) return `Quote for ${name}`;
  if (address) return `Quote for ${address}`;
  return "Handyman quote";
}

function currentQuoteKind() {
  return state.quoteDraft?.recipientKind || "linked_home";
}

function quoteCanSend() {
  if (!state.quoteDraft) return false;
  const hasLineItems = Boolean(state.quoteDraft.lineItems?.some((item) => item.name));
  if (!hasLineItems) return false;
  if (currentQuoteKind() === "linked_home") {
    return Boolean(state.quoteDraft.householdId && state.quoteDraft.requestId);
  }
  return Boolean((state.quoteDraft.prospectEmail || "").trim());
}

function activeTeamMembers() {
  return (state.dashboard?.teamMembers || []).filter((member) => member.status === "active");
}

function visitActionRow(visit, { allowQuote = true } = {}) {
  const buttons = [];
  if (visit.fieldWorkspace?.url) {
    buttons.push(
      `<a class="visit-link primary" href="${escapeHtml(visit.fieldWorkspace.url)}" target="_blank" rel="noreferrer">Open field workspace</a>`,
    );
  }
  buttons.push(
    `<button class="visit-link open-thread" data-request-id="${escapeHtml(visit.requestId)}" type="button">Message homeowner</button>`,
  );
  if (allowQuote && providerPermissions().canBuildQuotes) {
    buttons.push(
      `<button class="visit-link accent open-quote" data-request-id="${escapeHtml(visit.requestId)}" type="button">Build quote</button>`,
    );
  }
  return `<div class="visit-actions">${buttons.join("")}</div>`;
}

function visitSummaryMarkup(visit, { compact = false } = {}) {
  const assignmentChips = [];
  if (visit.assignment?.memberName) assignmentChips.push(statusChip(visit.assignment.memberName));
  if (visit.statusLabel) assignmentChips.push(statusChip(visit.statusLabel, visit.status === "completed" ? "success" : ""));
  if (visit.quote?.statusLabel) assignmentChips.push(statusChip(`${visit.quote.statusLabel} · ${money(visit.quote.total)}`, "success"));
  const routeLabel = routeDateForVisit(visit) ? shortDate(routeDateForVisit(visit)) : "Unscheduled";
  const routeWindow = routeWindowLabel(visit);

  return `
    <div class="${compact ? "stack-card" : "visit-card"}">
      <div class="visit-head">
        <div>
          <p class="visit-title">${escapeHtml(visit.title)}</p>
          <div class="visit-meta">${escapeHtml(visit.property?.name || "Home")} · ${escapeHtml(routeLabel)}${routeWindow ? ` · ${escapeHtml(routeWindow)}` : ""}</div>
          <div class="visit-meta">${escapeHtml(visit.property?.address || "")}</div>
        </div>
        <div class="chip-row">${assignmentChips.join("")}</div>
      </div>
      ${visit.latestMessage ? `<div class="visit-meta">${escapeHtml(visit.latestMessage.senderRole)} · ${escapeHtml(shortDateTime(visit.latestMessage.createdAt))} · ${escapeHtml(visit.latestMessage.body)}</div>` : ""}
      ${visitActionRow(visit)}
    </div>
  `;
}

function renderTodayBoard() {
  const visits = state.dashboard.visits;
  const today = todayIso();
  const todayVisits = visits.filter((visit) => routeDateForVisit(visit) === today);
  const visible = (todayVisits.length ? todayVisits : visits).slice(0, 6);
  if (!visible.length) {
    dom.todayBoard.innerHTML = `<p class="card-copy">No visits are queued yet. As homeowners route work to your company, this becomes the day board for routing and execution.</p>`;
    return;
  }
  dom.todayBoard.innerHTML = visible.map((visit) => visitSummaryMarkup(visit, { compact: true })).join("");
  wireRequestActionButtons(dom.todayBoard);
}

function renderCrewWorkload() {
  const members = state.dashboard.teamMembers || [];
  if (!members.length) {
    dom.crewWorkload.innerHTML = `<p class="card-copy">Crew assignments will show up here once the company starts inviting technicians and routing jobs.</p>`;
    return;
  }
  dom.crewWorkload.innerHTML = members
    .slice(0, 6)
    .map((member) => `
      <article class="crew-card">
        <div class="crew-head">
          <div>
            <p class="visit-title">${escapeHtml(member.fullName)}</p>
            <div class="visit-meta">${escapeHtml(member.title)} · ${escapeHtml(member.roleLabel)}</div>
          </div>
          <div class="chip-row">
            ${statusChip(member.status === "invited" ? "Invited" : "Active", member.status === "invited" ? "warning" : "success")}
            ${member.mobileFocus ? statusChip("Field-first") : ""}
          </div>
        </div>
        <div class="chip-row">
          ${statusChip(`${member.todayStops} today`)}
          ${statusChip(`${member.openVisits} open visits`)}
          ${statusChip(`${member.completedCount} completed`, "success")}
        </div>
        <div class="visit-meta">${escapeHtml(member.email || "No email on file")}${member.phone ? ` · ${escapeHtml(member.phone)}` : ""}</div>
      </article>
    `)
    .join("");
}

function renderQuotePipeline() {
  if (!providerPermissions().canBuildQuotes) {
    dom.quotePipeline.innerHTML = `<p class="card-copy">Quote building is hidden for your role. Use the field workspace to execute assigned visits and send homeowner updates.</p>`;
    return;
  }

  const quotes = state.dashboard.quotes || [];
  const groups = [
    ["Draft", quotes.filter((quote) => quote.status === "draft").length, "Scopes still being priced"],
    ["Sent", quotes.filter((quote) => quote.status === "sent").length, "Already delivered to homeowners"],
    ["Viewed", quotes.filter((quote) => quote.status === "viewed").length, "Opened by homeowners and waiting on a final response"],
    ["Approved", quotes.filter((quote) => quote.status === "approved").length, "Ready to schedule"],
    ["Declined", quotes.filter((quote) => quote.status === "declined").length, "Lost or deferred"],
  ];

  dom.quotePipeline.innerHTML = groups
    .map(([label, value, note]) => `
      <article class="stack-card">
        <p class="visit-title">${escapeHtml(label)}</p>
        <div class="chip-row">${statusChip(String(value), value ? "success" : "")}</div>
        <div class="visit-meta">${escapeHtml(note)}</div>
      </article>
    `)
    .join("");
}

function renderThreads(container, threads, emptyCopy) {
  if (!threads.length) {
    container.innerHTML = `<p class="card-copy">${emptyCopy}</p>`;
    return;
  }

  container.innerHTML = threads
    .map((thread) => `
      <article class="thread-card${thread.requestId === state.selectedRequestId ? " active" : ""}">
        <div class="thread-head">
          <div class="thread-title">${escapeHtml(thread.title)}</div>
          <div class="chip-row">
            ${statusChip(thread.statusLabel)}
            ${thread.quote?.statusLabel ? statusChip(`${thread.quote.statusLabel}${thread.quote.total ? ` · ${money(thread.quote.total)}` : ""}`, "success") : ""}
          </div>
        </div>
        <div class="thread-meta">${escapeHtml(thread.propertyName)} · ${escapeHtml(shortDateTime(thread.latestMessageAt))}${thread.assignedMemberName ? ` · ${escapeHtml(thread.assignedMemberName)}` : ""}</div>
        <div class="thread-meta">${escapeHtml(thread.senderRole)} · ${escapeHtml(thread.latestMessage)}</div>
        <div class="thread-actions">
          <button class="visit-link open-thread" data-request-id="${escapeHtml(thread.requestId)}" type="button">Reply</button>
          ${providerPermissions().canBuildQuotes ? `<button class="visit-link accent open-quote" data-request-id="${escapeHtml(thread.requestId)}" type="button">Build quote</button>` : ""}
        </div>
      </article>
    `)
    .join("");
  wireRequestActionButtons(container);
}

function renderDispatchBoard() {
  const visits = state.dashboard.visits || [];
  dom.dispatchSummary.textContent = `${state.dashboard.stats.unassignedVisits} unassigned · ${state.dashboard.stats.todayStops} on today's board`;

  if (!visits.length) {
    dom.dispatchBoard.innerHTML = `<p class="card-copy">No visible visits yet. When homeowners route work to this company, dispatch will light up here.</p>`;
    return;
  }

  const teamOptions = activeTeamMembers()
    .map((member) => `<option value="${escapeHtml(member.id)}">${escapeHtml(member.fullName)} · ${escapeHtml(member.roleLabel)}</option>`)
    .join("");

  dom.dispatchBoard.innerHTML = visits
    .map((visit) => {
      const routeDate = routeDateForVisit(visit);
      const windowStart = visit.assignment?.windowStartTime || "";
      const windowEnd = visit.assignment?.windowEndTime || "";
      const stopOrder = visit.assignment?.stopOrder || "";
      const routeNotes = visit.assignment?.routeNotes || "";
      const assignmentControls = providerPermissions().canAssignWork
        ? `
            <div class="dispatch-grid">
              <label>
                <span>Assign to</span>
                <select data-assignment-field="member" data-request-id="${escapeHtml(visit.requestId)}">
                  <option value="">Unassigned</option>
                  ${teamOptions}
                </select>
              </label>
              <label>
                <span>Route date</span>
                <input data-assignment-field="routeDate" data-request-id="${escapeHtml(visit.requestId)}" type="date" value="${escapeHtml(isoDate(routeDate))}">
              </label>
              <label>
                <span>Start</span>
                <input data-assignment-field="windowStartTime" data-request-id="${escapeHtml(visit.requestId)}" type="time" value="${escapeHtml(windowStart)}">
              </label>
              <label>
                <span>End</span>
                <input data-assignment-field="windowEndTime" data-request-id="${escapeHtml(visit.requestId)}" type="time" value="${escapeHtml(windowEnd)}">
              </label>
            </div>
            <div class="dispatch-grid compact">
              <label>
                <span>Stop order</span>
                <input data-assignment-field="stopOrder" data-request-id="${escapeHtml(visit.requestId)}" type="number" min="1" step="1" value="${escapeHtml(stopOrder)}">
              </label>
              <label class="dispatch-grid-note">
                <span>Route notes</span>
                <input data-assignment-field="routeNotes" data-request-id="${escapeHtml(visit.requestId)}" type="text" value="${escapeHtml(routeNotes)}" placeholder="Gate code, parking, bring ladder">
              </label>
            </div>
          `
        : "";

      return `
        <article class="dispatch-card">
          <div class="dispatch-head">
            <div>
              <p class="dispatch-title">${escapeHtml(visit.title)}</p>
              <div class="visit-meta">${escapeHtml(visit.property?.name || "Home")} · ${escapeHtml(visit.property?.address || "")}</div>
              <div class="visit-meta">${escapeHtml(visit.preferredTiming || visit.visit?.scheduledDate || visit.visit?.dueDate || "Timing TBD")}</div>
            </div>
            <div class="chip-row">
              ${statusChip(visit.statusLabel, visit.status === "completed" ? "success" : "")}
              ${visit.assignment?.memberName ? statusChip(visit.assignment.memberName) : statusChip("Unassigned", "warning")}
            </div>
          </div>
          ${assignmentControls}
          ${routeNotes && !providerPermissions().canAssignWork ? `<p class="dispatch-note">${escapeHtml(routeNotes)}</p>` : ""}
          <div class="dispatch-actions">
            ${visitActionRow(visit)}
            ${providerPermissions().canAssignWork ? `<button class="secondary-button save-assignment" data-request-id="${escapeHtml(visit.requestId)}" type="button">Save routing</button>` : ""}
          </div>
        </article>
      `;
    })
    .join("");

  dom.dispatchBoard.querySelectorAll('[data-assignment-field="member"]').forEach((select) => {
    const requestId = select.dataset.requestId;
    const current = requestById(requestId)?.assignment?.memberId || "";
    select.value = current;
  });
  wireRequestActionButtons(dom.dispatchBoard);
  wireDispatchButtons();
}

function renderCalendar() {
  const visits = state.dashboard.visits || [];
  const groups = new Map();

  visits.forEach((visit) => {
    const day = routeDateForVisit(visit) || "Unscheduled";
    if (!groups.has(day)) groups.set(day, []);
    groups.get(day).push(visit);
  });

  const entries = Array.from(groups.entries()).sort(([lhs], [rhs]) => {
    if (lhs === "Unscheduled") return 1;
    if (rhs === "Unscheduled") return -1;
    return lhs.localeCompare(rhs);
  });

  if (!entries.length) {
    dom.calendarList.innerHTML = `<p class="card-copy">No visits are scheduled yet.</p>`;
    return;
  }

  dom.calendarList.innerHTML = entries
    .map(([day, dayVisits]) => `
      <article class="calendar-day">
        <div class="calendar-day-header">
          <div>
            <p class="visit-title">${escapeHtml(day === "Unscheduled" ? "Unscheduled work" : shortDate(day))}</p>
            <div class="visit-meta">${dayVisits.length} stop${dayVisits.length === 1 ? "" : "s"}</div>
          </div>
          <div class="chip-row">
            ${statusChip(`${dayVisits.filter((visit) => visit.assignment?.memberId).length} assigned`)}
          </div>
        </div>
        <div class="day-visit-list">
          ${dayVisits
            .map((visit) => `
              <div class="day-visit">
                <div class="visit-title">${escapeHtml(visit.property?.name || "Home")} · ${escapeHtml(visit.title)}</div>
                <div class="visit-meta">${escapeHtml(visit.assignment?.memberName || "Unassigned")}${routeWindowLabel(visit) ? ` · ${escapeHtml(routeWindowLabel(visit))}` : ""}</div>
              </div>
            `)
            .join("")}
        </div>
      </article>
    `)
    .join("");
}

function renderRoutes() {
  const visits = (state.dashboard.visits || []).filter((visit) => visit.assignment?.memberId || routeDateForVisit(visit));
  if (!visits.length) {
    dom.routesList.innerHTML = `<p class="card-copy">Once visits are assigned and dated, the route board groups stops by day and technician here.</p>`;
    return;
  }

  const groupedDays = new Map();
  visits.forEach((visit) => {
    const day = routeDateForVisit(visit) || "Unscheduled";
    if (!groupedDays.has(day)) groupedDays.set(day, new Map());
    const memberName = visit.assignment?.memberName || "Unassigned";
    const dayMap = groupedDays.get(day);
    if (!dayMap.has(memberName)) dayMap.set(memberName, []);
    dayMap.get(memberName).push(visit);
  });

  dom.routesList.innerHTML = Array.from(groupedDays.entries())
    .sort(([lhs], [rhs]) => {
      if (lhs === "Unscheduled") return 1;
      if (rhs === "Unscheduled") return -1;
      return lhs.localeCompare(rhs);
    })
    .map(([day, memberMap]) => `
      <article class="route-day">
        <div class="route-day-header">
          <div>
            <p class="visit-title">${escapeHtml(day === "Unscheduled" ? "Unscheduled route board" : shortDate(day))}</p>
            <div class="visit-meta">${Array.from(memberMap.values()).reduce((sum, items) => sum + items.length, 0)} total stop${Array.from(memberMap.values()).reduce((sum, items) => sum + items.length, 0) === 1 ? "" : "s"}</div>
          </div>
        </div>
        ${Array.from(memberMap.entries())
          .map(([memberName, memberVisits]) => `
            <article class="route-member">
              <div class="crew-head">
                <div>
                  <p class="visit-title">${escapeHtml(memberName)}</p>
                  <div class="visit-meta">${memberVisits.length} stop${memberVisits.length === 1 ? "" : "s"}</div>
                </div>
              </div>
              <div class="route-stop-list">
                ${memberVisits
                  .sort((lhs, rhs) => (lhs.assignment?.stopOrder || 999) - (rhs.assignment?.stopOrder || 999))
                  .map((visit) => `
                    <div class="route-stop">
                      <div class="visit-title">${visit.assignment?.stopOrder ? `Stop ${escapeHtml(visit.assignment.stopOrder)} · ` : ""}${escapeHtml(visit.property?.name || "Home")}</div>
                      <div class="visit-meta">${escapeHtml(visit.title)}${routeWindowLabel(visit) ? ` · ${escapeHtml(routeWindowLabel(visit))}` : ""}</div>
                      <div class="visit-meta">${escapeHtml(visit.property?.address || "")}</div>
                    </div>
                  `)
                  .join("")}
              </div>
            </article>
          `)
          .join("")}
      </article>
    `)
    .join("");
}

function renderCrew() {
  const permissions = providerPermissions();
  const members = state.dashboard.teamMembers || [];

  if (!permissions.canManageCrew) {
    dom.teamForm.classList.add("hidden");
    dom.teamFeedback.textContent = "";
  } else {
    dom.teamForm.classList.remove("hidden");
  }

  if (!members.length) {
    dom.crewList.innerHTML = `<p class="card-copy">Invite teammates and route visits to them here.</p>`;
    return;
  }

  dom.crewList.innerHTML = members
    .map((member) => `
      <article class="crew-card">
        <div class="crew-head">
          <div>
            <p class="visit-title">${escapeHtml(member.fullName)}</p>
            <div class="visit-meta">${escapeHtml(member.title)} · ${escapeHtml(member.roleLabel)}</div>
          </div>
          <div class="chip-row">
            ${statusChip(member.status === "invited" ? "Invited" : "Active", member.status === "invited" ? "warning" : "success")}
            ${member.mobileFocus ? statusChip("Field") : statusChip("Desk")}
          </div>
        </div>
        <div class="member-detail-grid">
          <div class="visit-meta">${escapeHtml(member.email || "No email")}</div>
          <div class="visit-meta">${escapeHtml(member.phone || "No phone")}</div>
          <div class="visit-meta">${member.todayStops} today</div>
          <div class="visit-meta">${member.openVisits} open</div>
        </div>
        ${permissions.canManageCrew ? `
          <div class="dispatch-grid">
            <label>
              <span>Role</span>
              <select data-member-field="role" data-member-id="${escapeHtml(member.id)}">
                <option value="owner">Owner</option>
                <option value="admin">Administrator</option>
                <option value="dispatcher">Dispatcher</option>
                <option value="technician">Field technician</option>
              </select>
            </label>
            <label>
              <span>Status</span>
              <select data-member-field="status" data-member-id="${escapeHtml(member.id)}">
                <option value="active">Active</option>
                <option value="invited">Invited</option>
                <option value="disabled">Disabled</option>
              </select>
            </label>
            <label>
              <span>Title</span>
              <input data-member-field="title" data-member-id="${escapeHtml(member.id)}" type="text" value="${escapeHtml(member.title || "")}">
            </label>
            <label>
              <span>Phone</span>
              <input data-member-field="phone" data-member-id="${escapeHtml(member.id)}" type="text" value="${escapeHtml(member.phone || "")}">
            </label>
          </div>
          <div class="crew-actions">
            <button class="secondary-button save-member" data-member-id="${escapeHtml(member.id)}" type="button">Save access</button>
            ${member.inviteUrl ? `<button class="ghost-button copy-invite" data-invite-url="${escapeHtml(member.inviteUrl)}" type="button">Copy invite</button>` : ""}
          </div>
        ` : member.inviteUrl ? `
          <div class="crew-actions">
            <button class="ghost-button copy-invite" data-invite-url="${escapeHtml(member.inviteUrl)}" type="button">Copy invite</button>
          </div>
        ` : ""}
      </article>
    `)
    .join("");

  dom.crewList.querySelectorAll('[data-member-field="role"]').forEach((select) => {
    const member = members.find((item) => item.id === select.dataset.memberId);
    if (member) select.value = member.role;
  });
  dom.crewList.querySelectorAll('[data-member-field="status"]').forEach((select) => {
    const member = members.find((item) => item.id === select.dataset.memberId);
    if (member) select.value = member.status === "disabled" ? "disabled" : member.status;
  });
}

function renderHomes() {
  const homes = state.dashboard.homes || [];
  if (!homes.length) {
    dom.homesList.innerHTML = `<p class="card-copy">Homes appear here once work is routed to your workspace.</p>`;
    return;
  }

  dom.homesList.innerHTML = homes
    .map((home) => {
      const homeVisits = relatedVisitsForProperty(home.propertyId)
        .sort((lhs, rhs) => String(rhs.updatedAt || "").localeCompare(String(lhs.updatedAt || "")));
      const openItems = homeVisits
        .filter((visit) => !isClosedRequestStatus(visit.status))
        .slice(0, 3);
      const recentVisits = homeVisits
        .filter((visit) => visit.fieldWorkspace?.reportStatus === "completed" || visit.status === "completed")
        .sort((lhs, rhs) => String(rhs.fieldWorkspace?.completedAt || rhs.updatedAt || "").localeCompare(String(lhs.fieldWorkspace?.completedAt || lhs.updatedAt || "")))
        .slice(0, 3);
      const latestThreadVisit = homeVisits.find((visit) => visit.latestMessage);
      const primaryRequestId = openItems[0]?.requestId || homeVisits[0]?.requestId || "";
      const latestFieldWorkspaceUrl = openItems[0]?.fieldWorkspace?.url || recentVisits[0]?.fieldWorkspace?.url || "";

      return `
        <article class="home-card">
          <div class="home-head">
            <div>
              <div class="home-title">${escapeHtml(home.name)}</div>
              <div class="home-meta">${escapeHtml(home.address)}</div>
            </div>
            <div class="chip-row">
              ${statusChip(`${home.systemCount} systems`)}
              ${statusChip(`${home.openRequests} open requests`)}
              ${home.lastCompletedVisit ? statusChip(`Last visit ${shortDate(home.lastCompletedVisit)}`, "success") : statusChip("No completed Chez visit yet", "warning")}
            </div>
          </div>
          ${home.assignedMembers?.length ? `<div class="chip-row">${home.assignedMembers.map((name) => statusChip(name)).join("")}</div>` : ""}
          <div class="home-detail-grid">
            <section class="home-detail-card">
              <p class="section-eyebrow">Open work</p>
              ${openItems.length ? `
                <div class="summary-list">
                  ${openItems
                    .map((visit) => `
                      <button class="summary-list-item open-thread" data-request-id="${escapeHtml(visit.requestId)}" type="button">
                        <strong>${escapeHtml(visit.title)}</strong>
                        <span>${escapeHtml(visit.statusLabel)}${visit.assignment?.memberName ? ` · ${escapeHtml(visit.assignment.memberName)}` : ""}</span>
                      </button>
                    `)
                    .join("")}
                </div>
              ` : `<p class="card-copy">No open work at this home right now.</p>`}
            </section>
            <section class="home-detail-card">
              <p class="section-eyebrow">Recent visits</p>
              ${recentVisits.length ? `
                <div class="summary-list">
                  ${recentVisits
                    .map((visit) => `
                      <div class="summary-list-item static">
                        <strong>${escapeHtml(visit.title)}</strong>
                        <span>${escapeHtml(shortDate(visit.fieldWorkspace?.completedAt || visit.updatedAt))}${visit.assignment?.memberName ? ` · ${escapeHtml(visit.assignment.memberName)}` : ""}</span>
                      </div>
                    `)
                    .join("")}
                </div>
              ` : `<p class="card-copy">Completed Chez visits at this home will show up here.</p>`}
            </section>
          </div>
          ${latestThreadVisit ? `
            <div class="message-preview-card">
              <p class="section-eyebrow">Latest homeowner communication</p>
              <p class="visit-title">${escapeHtml(latestThreadVisit.title)}</p>
              <div class="visit-meta">${escapeHtml(shortDateTime(latestThreadVisit.latestMessage.createdAt))} · ${escapeHtml(latestThreadVisit.latestMessage.senderRole)}</div>
              <p class="card-copy">${escapeHtml(latestThreadVisit.latestMessage.body)}</p>
            </div>
          ` : ""}
          <div class="system-chip-row">
            ${(home.systems || []).length
              ? home.systems.map((system) => statusChip(`${system.name}${system.manufacturer ? ` · ${system.manufacturer}` : ""}${system.modelNumber ? ` · ${system.modelNumber}` : ""}`)).join("")
              : statusChip("No systems mapped yet", "alert")}
          </div>
          <div class="thread-actions">
            ${primaryRequestId ? `<button class="visit-link open-thread" data-request-id="${escapeHtml(primaryRequestId)}" type="button">Message homeowner</button>` : ""}
            ${providerPermissions().canBuildQuotes && primaryRequestId ? `<button class="visit-link accent open-quote" data-request-id="${escapeHtml(primaryRequestId)}" type="button">Build quote</button>` : ""}
            ${latestFieldWorkspaceUrl ? `<a class="visit-link primary" href="${escapeHtml(latestFieldWorkspaceUrl)}" target="_blank" rel="noreferrer">Open latest visit</a>` : ""}
          </div>
        </article>
      `;
    })
    .join("");

  wireRequestActionButtons(dom.homesList);
}

function renderQuotes() {
  if (!providerPermissions().canBuildQuotes) {
    dom.quotesList.innerHTML = `<p class="card-copy">Quote creation is hidden for your role. If that should change, an owner or administrator can adjust your workspace access.</p>`;
    return;
  }

  const quotes = state.dashboard.quotes || [];
  if (!quotes.length) {
    dom.quotesList.innerHTML = `<p class="card-copy">Build a quote from any visit request and it will show up here with status, totals, and homeowner communication.</p>`;
    return;
  }

  dom.quotesList.innerHTML = quotes
    .map((quote) => `
      <article class="quote-card">
        <div class="quote-head">
          <div>
            <p class="quote-title">${escapeHtml(quote.title)}</p>
            <div class="quote-meta">${escapeHtml(quote.audienceLabel || quote.propertyName || "Client")} · ${escapeHtml(quote.statusLabel)} · ${escapeHtml(money(quote.total))}</div>
            ${quote.recipientEmail || quote.recipientPhone ? `<div class="visit-meta">${escapeHtml([quote.recipientEmail, quote.recipientPhone].filter(Boolean).join(" · "))}</div>` : ""}
          </div>
          <div class="chip-row">
            ${statusChip(`${quote.itemCount} line item${quote.itemCount === 1 ? "" : "s"}`)}
            ${quote.lastSentAt ? statusChip(`Sent ${shortDate(quote.lastSentAt)}`, "success") : statusChip(`Updated ${shortDate(quote.updatedAt)}`)}
            ${quote.recipientKind === "prospect" ? statusChip("Prospect", "warning") : statusChip("Chez home")}
          </div>
        </div>
        ${quote.latestMessage ? `
          <div class="message-preview-card">
            <p class="section-eyebrow">Latest collaboration</p>
            <div class="visit-meta">${escapeHtml(shortDateTime(quote.latestMessage.createdAt))} · ${escapeHtml(quote.latestMessage.senderName || quote.latestMessage.senderRole)}</div>
            <p class="card-copy">${escapeHtml(quote.latestMessage.body)}</p>
          </div>
        ` : ""}
        <div class="thread-actions">
          ${quote.requestId ? `<button class="visit-link open-thread" data-request-id="${escapeHtml(quote.requestId)}" type="button">Open homeowner thread</button>` : ""}
          ${quote.publicShareUrl ? `<a class="visit-link primary" href="${escapeHtml(quote.publicShareUrl)}" target="_blank" rel="noreferrer">Open quote link</a>` : ""}
          ${quote.publicShareUrl ? `<button class="visit-link copy-quote-link" data-quote-link="${escapeHtml(quote.publicShareUrl)}" type="button">Copy share link</button>` : ""}
          <button class="visit-link open-quote-edit" data-quote-id="${escapeHtml(quote.id)}" type="button">Edit quote</button>
        </div>
      </article>
    `)
    .join("");

  dom.quotesList.querySelectorAll(".copy-quote-link").forEach((button) => {
    button.addEventListener("click", () => {
      copyText(button.dataset.quoteLink);
      setFeedback(dom.authFeedback, "Quote link copied.");
    });
  });
}

function renderSavedItems() {
  const savedItems = state.dashboard.savedQuoteItems || [];
  dom.savedItemsList.innerHTML = savedItems
    .map((item) => `
      <article class="saved-item-card">
        <div class="saved-item-title">${escapeHtml(item.name)}</div>
        <div class="saved-item-meta">${escapeHtml(item.description || "No description")} · ${escapeHtml(String(item.defaultQuantity))} ${escapeHtml(item.unit)} · ${escapeHtml(money(item.defaultUnitPrice))}</div>
      </article>
    `)
    .join("");
}

function renderRecentWork() {
  const recentWork = state.dashboard.recentWork || [];
  if (!recentWork.length) {
    dom.recentWorkList.innerHTML = `<div class="mini-row">Completed Chez visits will show up here.</div>`;
    return;
  }
  dom.recentWorkList.innerHTML = recentWork
    .map((visit) => `
      <div class="mini-row">
        <strong>${escapeHtml(visit.title)}</strong>
        <span>${escapeHtml(visit.property?.name || "Home")} · ${escapeHtml(shortDate(visit.fieldWorkspace?.completedAt))}</span>
      </div>
    `)
    .join("");
}

function hydrateQuotePicker() {
  dom.savedItemPicker.innerHTML = `<option value="">Insert saved line item</option>`;
  (state.dashboard.savedQuoteItems || []).forEach((item) => {
    const option = document.createElement("option");
    option.value = item.id;
    option.textContent = `${item.name} · ${money(item.defaultUnitPrice)}`;
    dom.savedItemPicker.appendChild(option);
  });
}

function syncSelectedThreadCards() {
  document.querySelectorAll(".thread-card").forEach((card) => {
    const requestId = card.querySelector(".open-thread")?.dataset.requestId || "";
    card.classList.toggle("active", Boolean(state.selectedRequestId) && requestId === state.selectedRequestId);
  });
}

function renderMessageThreadDetail() {
  const visit = state.selectedRequestId ? requestById(state.selectedRequestId) : null;
  const thread = state.selectedRequestId ? threadByRequestId(state.selectedRequestId) : null;

  if (!visit) {
    dom.messageThreadDetail.innerHTML = `<div class="empty-state-panel"><p class="card-copy">Choose a homeowner thread to see the home, latest updates, recent visits, and the best next actions before you reply.</p></div>`;
    dom.messageThreadHistory.innerHTML = "";
    return;
  }

  const homeVisits = relatedVisitsForProperty(visit.property?.id)
    .sort((lhs, rhs) => String(rhs.fieldWorkspace?.completedAt || rhs.updatedAt || "").localeCompare(String(lhs.fieldWorkspace?.completedAt || lhs.updatedAt || "")));
  const recentVisits = homeVisits.slice(0, 3);
  const history = thread?.recentMessages || [];

  dom.messageThreadDetail.innerHTML = `
    <article class="message-thread-card">
      <div class="section-row compact-row">
        <div>
          <p class="section-eyebrow">Client + home</p>
          <h3>${escapeHtml(visit.property?.name || "Home")} · ${escapeHtml(visit.title)}</h3>
          <p class="card-copy">${escapeHtml(visit.property?.address || "")}</p>
        </div>
        <div class="chip-row">
          ${statusChip(visit.statusLabel)}
          ${visit.assignment?.memberName ? statusChip(visit.assignment.memberName) : statusChip("Unassigned", "warning")}
          ${quoteStatusChip(visit.quote)}
        </div>
      </div>
      ${schedulingBlockMarkup(visit)}
      ${quoteCounterAlertMarkup(visit)}
      ${quoteSignedAlertMarkup(visit)}
      <div class="message-thread-actions">
        ${visit.fieldWorkspace?.url ? `<a class="visit-link primary" href="${escapeHtml(visit.fieldWorkspace.url)}" target="_blank" rel="noreferrer">Open field workspace</a>` : ""}
        ${providerPermissions().canBuildQuotes ? `<button class="visit-link accent open-quote" data-request-id="${escapeHtml(visit.requestId)}" type="button">${visit.quote?.status === "countered_by_homeowner" ? "Open counter and re-quote" : "Build quote"}</button>` : ""}
      </div>
    </article>
  `;

  dom.messageThreadHistory.innerHTML = `
    <div class="message-thread-history-grid">
      <section class="detail-block">
        <p class="section-eyebrow">Recent conversation</p>
        ${history.length ? `
          <div class="timeline-list">
            ${history.map(threadMessageMarkup).join("")}
          </div>
        ` : `<p class="card-copy">No messages have been sent yet. Your update here will start the Chez thread for this home.</p>`}
      </section>
      <section class="detail-block">
        <p class="section-eyebrow">Recent visits at this home</p>
        ${recentVisits.length ? `
          <div class="summary-list">
            ${recentVisits
              .map((homeVisit) => `
                <div class="summary-list-item static">
                  <strong>${escapeHtml(homeVisit.title)}</strong>
                  <span>${escapeHtml(homeVisit.statusLabel)} · ${escapeHtml(shortDate(homeVisit.fieldWorkspace?.completedAt || homeVisit.updatedAt || ""))}</span>
                </div>
              `)
              .join("")}
          </div>
        ` : `<p class="card-copy">Once work is completed at this home, recent visit history will show up here.</p>`}
      </section>
    </div>
  `;

  wireRequestActionButtons(dom.messageThreadDetail);
}

function syncMessageComposer() {
  const visit = state.selectedRequestId ? requestById(state.selectedRequestId) : null;
  dom.messageRequestTitle.value = visit ? `${visit.property?.name || "Home"} · ${visit.title}` : "";
  dom.messageStatus.disabled = !visit;
  dom.messageBody.disabled = !visit;
  dom.sendMessageButton.disabled = !visit;
  renderMessageThreadDetail();
  syncSelectedThreadCards();
}

function selectRequest(requestId) {
  state.selectedRequestId = requestId;
  syncMessageComposer();
}

function wireRequestActionButtons(container) {
  container.querySelectorAll(".open-thread").forEach((button) => {
    button.addEventListener("click", () => {
      selectRequest(button.dataset.requestId);
      showTab("messages");
    });
  });
  container.querySelectorAll(".open-quote").forEach((button) => {
    button.addEventListener("click", () => {
      openQuoteBuilder(button.dataset.requestId);
      showTab("quotes");
    });
  });
  container.querySelectorAll(".open-quote-edit").forEach((button) => {
    button.addEventListener("click", () => {
      openQuoteBuilder(null, button.dataset.quoteId);
      showTab("quotes");
    });
  });
  wireSchedulingControls(container);
}

// Phase 73 sub-phase A: bidirectional scheduling controls.
//
// Renders a single "Visit scheduling" block above the message-thread
// actions. Four states drive the markup:
//
//   1. Confirmed (visit.confirmedVisitAt non-null) — green readout, no
//      buttons.
//   2. Awaiting handyman (visit.proposedByRole === 'homeowner', not yet
//      confirmed) — "Homeowner suggested {date}" + Accept + Counter.
//   3. Awaiting homeowner (visit.proposedByRole === 'handyman', not yet
//      confirmed) — "You suggested {date}, waiting on homeowner" +
//      Update suggestion.
//   4. No proposal yet — "Propose a visit time" form revealed inline.
function schedulingBlockMarkup(visit) {
  const requestId = visit.requestId;
  if (!requestId) return "";

  if (visit.confirmedVisitAt) {
    return `
      <div class="scheduling-block scheduling-confirmed" data-scheduling-block="${escapeHtml(requestId)}">
        <p class="section-eyebrow">Visit scheduling</p>
        <p class="scheduling-status"><strong>Confirmed</strong> · ${escapeHtml(formatScheduleDateTime(visit.confirmedVisitAt))}</p>
      </div>
    `;
  }

  if (visit.proposedVisitAt && visit.proposedByRole === "homeowner") {
    return `
      <div class="scheduling-block scheduling-awaiting-handyman" data-scheduling-block="${escapeHtml(requestId)}">
        <p class="section-eyebrow">Visit scheduling</p>
        <p class="scheduling-status">Homeowner suggested <strong>${escapeHtml(formatScheduleDateTime(visit.proposedVisitAt))}</strong>.</p>
        <div class="scheduling-actions">
          <button class="visit-link primary scheduling-accept" data-request-id="${escapeHtml(requestId)}" type="button">Accept</button>
          <button class="visit-link scheduling-counter" data-request-id="${escapeHtml(requestId)}" data-existing="${escapeHtml(toDatetimeLocalValue(visit.proposedVisitAt))}" type="button">Counter</button>
        </div>
        ${schedulingFormMarkup(requestId, "")}
      </div>
    `;
  }

  if (visit.proposedVisitAt && visit.proposedByRole === "handyman") {
    return `
      <div class="scheduling-block scheduling-awaiting-homeowner" data-scheduling-block="${escapeHtml(requestId)}">
        <p class="section-eyebrow">Visit scheduling</p>
        <p class="scheduling-status">You suggested <strong>${escapeHtml(formatScheduleDateTime(visit.proposedVisitAt))}</strong>. Waiting on the homeowner.</p>
        <div class="scheduling-actions">
          <button class="visit-link scheduling-counter" data-request-id="${escapeHtml(requestId)}" data-existing="${escapeHtml(toDatetimeLocalValue(visit.proposedVisitAt))}" type="button">Update suggestion</button>
        </div>
        ${schedulingFormMarkup(requestId, toDatetimeLocalValue(visit.proposedVisitAt))}
      </div>
    `;
  }

  return `
    <div class="scheduling-block scheduling-empty" data-scheduling-block="${escapeHtml(requestId)}">
      <p class="section-eyebrow">Visit scheduling</p>
      <p class="scheduling-status">No date proposed yet. Propose a window — the homeowner will accept or counter.</p>
      <div class="scheduling-actions">
        <button class="visit-link primary scheduling-counter" data-request-id="${escapeHtml(requestId)}" data-existing="${escapeHtml(toDatetimeLocalValue(defaultScheduleStart()))}" type="button">Propose a date</button>
      </div>
      ${schedulingFormMarkup(requestId, toDatetimeLocalValue(defaultScheduleStart()))}
    </div>
  `;
}

function schedulingFormMarkup(requestId, defaultValue) {
  return `
    <form class="scheduling-form hidden" data-scheduling-form="${escapeHtml(requestId)}">
      <label>
        <span>Date and time</span>
        <input type="datetime-local" name="scheduledAt" value="${escapeHtml(defaultValue || "")}" required>
      </label>
      <label>
        <span>Note (optional)</span>
        <input type="text" name="note" placeholder="What does the homeowner need to know?">
      </label>
      <div class="scheduling-form-actions">
        <button class="visit-link" type="button" data-scheduling-cancel="${escapeHtml(requestId)}">Cancel</button>
        <button class="visit-link primary" type="submit">Send</button>
      </div>
      <p class="scheduling-feedback hidden" data-scheduling-feedback="${escapeHtml(requestId)}"></p>
    </form>
  `;
}

function wireSchedulingControls(container) {
  container.querySelectorAll(".scheduling-counter").forEach((button) => {
    button.addEventListener("click", () => {
      const requestId = button.dataset.requestId;
      const form = container.querySelector(`[data-scheduling-form="${requestId}"]`);
      if (!form) return;
      const existing = button.dataset.existing;
      const input = form.querySelector('input[name="scheduledAt"]');
      if (input && existing) input.value = existing;
      form.classList.remove("hidden");
      input?.focus();
    });
  });

  container.querySelectorAll("[data-scheduling-cancel]").forEach((button) => {
    button.addEventListener("click", () => {
      const requestId = button.dataset.schedulingCancel;
      const form = container.querySelector(`[data-scheduling-form="${requestId}"]`);
      form?.classList.add("hidden");
      const feedback = container.querySelector(`[data-scheduling-feedback="${requestId}"]`);
      if (feedback) {
        feedback.textContent = "";
        feedback.classList.add("hidden");
      }
    });
  });

  container.querySelectorAll("[data-scheduling-form]").forEach((form) => {
    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      const requestId = form.dataset.schedulingForm;
      const scheduledAtValue = form.querySelector('input[name="scheduledAt"]')?.value;
      const note = form.querySelector('input[name="note"]')?.value || "";
      const feedback = container.querySelector(`[data-scheduling-feedback="${requestId}"]`);
      if (!scheduledAtValue) {
        if (feedback) {
          feedback.textContent = "Pick a date and time.";
          feedback.classList.remove("hidden");
        }
        return;
      }
      try {
        await providerRequest("POST", {
          action: "propose_visit_time",
          workspaceId: state.dashboard.workspace.id,
          requestId,
          proposedAt: new Date(scheduledAtValue).toISOString(),
          note,
        });
        await refreshWorkspace();
        renderMessageThreadDetail();
        setFeedback(dom.authFeedback, "Time proposed. Homeowner will accept or counter.");
      } catch (error) {
        if (feedback) {
          feedback.textContent = error?.message || "Couldn't send the proposal. Try again.";
          feedback.classList.remove("hidden");
        }
      }
    });
  });

  container.querySelectorAll(".scheduling-accept").forEach((button) => {
    button.addEventListener("click", async () => {
      const requestId = button.dataset.requestId;
      try {
        button.disabled = true;
        button.textContent = "Confirming…";
        await providerRequest("POST", {
          action: "accept_visit_time",
          workspaceId: state.dashboard.workspace.id,
          requestId,
        });
        await refreshWorkspace();
        renderMessageThreadDetail();
        setFeedback(dom.authFeedback, "Confirmed. The homeowner will see the locked-in time.");
      } catch (error) {
        button.disabled = false;
        button.textContent = "Accept";
        setFeedback(dom.authFeedback, error?.message || "Couldn't accept the time. Try again.", true);
      }
    });
  });
}

// Phase 73: render a single thread message. Schedule events
// (`metadata.kind` of "propose_time" / "accept_time") get distinct
// system-event styling — calendar icon and contextual headline — so
// they don't visually blend with free-text replies. Unknown kinds and
// legacy messages with empty metadata fall back to the text shape.
function threadMessageMarkup(message) {
  const kind = (message?.metadata && message.metadata.kind) || "text";
  const senderLabel = providerSenderLabel(message?.senderRole);
  const time = shortDateTime(message?.createdAt);

  if (kind === "propose_time") {
    const proposedAt = message?.metadata?.proposed_at ? formatScheduleDateTime(message.metadata.proposed_at) : "";
    const headline = proposedAt
      ? `${senderLabel} proposed ${proposedAt}`
      : `${senderLabel} proposed a new visit time`;
    const noteIsRedundant = !message?.body || /^proposed /i.test(String(message.body).trim());
    return `
      <article class="timeline-entry timeline-system timeline-system-proposal">
        <div class="timeline-system-row">
          <span class="timeline-system-icon" aria-hidden="true">📅</span>
          <div>
            <strong>${escapeHtml(headline)}</strong>
            <div class="timeline-meta">${escapeHtml(senderLabel)} · ${escapeHtml(time)}</div>
          </div>
        </div>
        ${!noteIsRedundant ? `<p class="card-copy">${escapeHtml(message.body)}</p>` : ""}
      </article>
    `;
  }

  if (kind === "accept_time") {
    const confirmedAt = message?.metadata?.confirmed_at ? formatScheduleDateTime(message.metadata.confirmed_at) : "";
    const headline = confirmedAt
      ? `${senderLabel} confirmed ${confirmedAt}`
      : `${senderLabel} confirmed the visit time`;
    return `
      <article class="timeline-entry timeline-system timeline-system-confirmation">
        <div class="timeline-system-row">
          <span class="timeline-system-icon" aria-hidden="true">✅</span>
          <div>
            <strong>${escapeHtml(headline)}</strong>
            <div class="timeline-meta">${escapeHtml(senderLabel)} · ${escapeHtml(time)}</div>
          </div>
        </div>
      </article>
    `;
  }

  if (kind === "decline_time") {
    return `
      <article class="timeline-entry timeline-system timeline-system-decline">
        <div class="timeline-system-row">
          <span class="timeline-system-icon" aria-hidden="true">⛔</span>
          <div>
            <strong>${escapeHtml(senderLabel)} declined the proposed time</strong>
            <div class="timeline-meta">${escapeHtml(senderLabel)} · ${escapeHtml(time)}</div>
          </div>
        </div>
        ${message?.body ? `<p class="card-copy">${escapeHtml(message.body)}</p>` : ""}
      </article>
    `;
  }

  return `
    <article class="timeline-entry">
      <div class="timeline-meta">${escapeHtml(senderLabel)} · ${escapeHtml(time)}</div>
      <p class="card-copy">${escapeHtml(message?.body || "")}</p>
    </article>
  `;
}

function providerSenderLabel(role) {
  switch ((role || "").toLowerCase()) {
    case "homeowner":
      return "Homeowner";
    case "vendor":
      return "You";
    case "haven":
      return "Chez";
    default:
      return role ? role.charAt(0).toUpperCase() + role.slice(1) : "Update";
  }
}

// Phase 73 sub-phase B: surface a colored chip for the quote status.
// Countered quotes pop in salmon to draw the provider's eye; signed
// (approved) quotes stay green. Other states fall back to the legacy
// success chip so existing screenshots / muscle memory don't shift.
function quoteStatusChip(quote) {
  if (!quote || !quote.statusLabel) return "";
  const label = `${quote.statusLabel} · ${money(quote.total || 0)}`;
  if (quote.status === "countered_by_homeowner") {
    return statusChip(label, "warning");
  }
  if (quote.status === "approved" || quote.signedName) {
    return statusChip(label, "success");
  }
  return statusChip(label, "success");
}

// Phase 73 sub-phase B: when the homeowner countered, show a callout
// summarizing what they changed so the provider doesn't have to open
// the builder to see the new total.
function quoteCounterAlertMarkup(visit) {
  if (!visit.quote || visit.quote.status !== "countered_by_homeowner") return "";
  const newTotal = money(visit.quote.total || 0);
  const note = compactQuoteNote(visit.quote.homeownerMessage);
  const revisedAt = visit.quote.homeownerRevisedAt
    ? formatScheduleDateTime(visit.quote.homeownerRevisedAt)
    : "";
  return `
    <div class="quote-alert quote-alert-counter">
      <div class="quote-alert-row">
        <span class="quote-alert-icon" aria-hidden="true">📝</span>
        <div>
          <strong>Homeowner countered with ${escapeHtml(newTotal)}</strong>
          ${revisedAt ? `<div class="timeline-meta">${escapeHtml(revisedAt)}</div>` : ""}
        </div>
      </div>
      ${note ? `<p class="card-copy">${escapeHtml(note)}</p>` : ""}
      <p class="quote-alert-helper">Open the counter to accept it as-is, or edit the line items and send a revised quote back.</p>
    </div>
  `;
}

// Phase 73 sub-phase B: signed-and-approved confirmation. Lets the
// provider see who signed and when without leaving the thread.
function quoteSignedAlertMarkup(visit) {
  if (!visit.quote || !visit.quote.signedName) return "";
  const total = money(visit.quote.total || 0);
  const when = visit.quote.signedAt ? formatScheduleDateTime(visit.quote.signedAt) : "";
  return `
    <div class="quote-alert quote-alert-signed">
      <div class="quote-alert-row">
        <span class="quote-alert-icon" aria-hidden="true">✍️</span>
        <div>
          <strong>${escapeHtml(visit.quote.signedName)} signed for ${escapeHtml(total)}</strong>
          ${when ? `<div class="timeline-meta">${escapeHtml(when)}</div>` : ""}
        </div>
      </div>
    </div>
  `;
}

function compactQuoteNote(text) {
  if (!text || typeof text !== "string") return "";
  return text.trim();
}

function formatScheduleDateTime(value) {
  if (!value) return "";
  try {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return value;
    return date.toLocaleString(undefined, {
      weekday: "short",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit",
    });
  } catch {
    return value;
  }
}

function toDatetimeLocalValue(value) {
  if (!value) return "";
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  // datetime-local expects YYYY-MM-DDTHH:MM in local time, no timezone.
  const offset = date.getTimezoneOffset();
  const local = new Date(date.getTime() - offset * 60000);
  return local.toISOString().slice(0, 16);
}

function defaultScheduleStart() {
  const date = new Date();
  date.setDate(date.getDate() + 2);
  date.setHours(10, 0, 0, 0);
  return date;
}

function wireDispatchButtons() {
  dom.dispatchBoard.querySelectorAll(".save-assignment").forEach((button) => {
    button.addEventListener("click", async () => {
      const requestId = button.dataset.requestId;
      const field = (name) => dom.dispatchBoard.querySelector(`[data-request-id="${requestId}"][data-assignment-field="${name}"]`);
      try {
        await providerRequest("POST", {
          action: "assign_visit",
          workspaceId: state.dashboard.workspace.id,
          requestId,
          assignedMemberId: field("member")?.value || "",
          routeDate: field("routeDate")?.value || "",
          windowStartTime: field("windowStartTime")?.value || "",
          windowEndTime: field("windowEndTime")?.value || "",
          stopOrder: field("stopOrder")?.value || "",
          routeNotes: field("routeNotes")?.value || "",
        });
        setFeedback(dom.authFeedback, "Routing updated.");
        await refreshWorkspace();
      } catch (error) {
        setFeedback(dom.authFeedback, error.message, true);
      }
    });
  });
}

function wireCrewButtons() {
  dom.crewList.querySelectorAll(".copy-invite").forEach((button) => {
    button.addEventListener("click", () => {
      copyText(button.dataset.inviteUrl);
      setFeedback(dom.teamFeedback, "Invite link copied.");
    });
  });

  dom.crewList.querySelectorAll(".save-member").forEach((button) => {
    button.addEventListener("click", async () => {
      const memberId = button.dataset.memberId;
      const field = (name) => dom.crewList.querySelector(`[data-member-id="${memberId}"][data-member-field="${name}"]`);
      try {
        await providerRequest("POST", {
          action: "update_team_member",
          workspaceId: state.dashboard.workspace.id,
          memberId,
          role: field("role")?.value,
          status: field("status")?.value,
          title: field("title")?.value,
          phone: field("phone")?.value,
        });
        setFeedback(dom.teamFeedback, "Team member updated.");
        await refreshWorkspace();
      } catch (error) {
        setFeedback(dom.teamFeedback, error.message, true);
      }
    });
  });
}

function syncQuoteContextPicker() {
  const contexts = buildQuoteContexts();
  dom.quoteContextSelect.innerHTML = "";

  if (!contexts.length) {
    const option = document.createElement("option");
    option.value = "";
    option.textContent = "No client requests in this workspace yet";
    dom.quoteContextSelect.appendChild(option);
    dom.quoteContextSelect.disabled = true;
    return;
  }

  const placeholder = document.createElement("option");
  placeholder.value = "";
  placeholder.textContent = "Choose a homeowner request";
  dom.quoteContextSelect.appendChild(placeholder);

  contexts.forEach((context) => {
    const option = document.createElement("option");
    option.value = context.id;
    option.textContent = `${context.propertyName} · ${context.title}`;
    dom.quoteContextSelect.appendChild(option);
  });

  dom.quoteContextSelect.disabled = false;
  dom.quoteContextSelect.value = state.quoteDraft?.selectedContextId || "";
}

function syncQuoteContextUI(existingQuote = null) {
  if (!state.quoteDraft) return;

  const contexts = buildQuoteContexts();
  const selectedContext = contexts.find((context) => context.id === state.quoteDraft?.selectedContextId) || null;
  const hasLineItems = Boolean(state.quoteDraft?.lineItems?.some((item) => item.name));
  const linkedMode = currentQuoteKind() === "linked_home";

  dom.quoteKindLinked.classList.toggle("active", linkedMode);
  dom.quoteKindProspect.classList.toggle("active", !linkedMode);
  dom.quoteLinkedMode.classList.toggle("hidden", !linkedMode);
  dom.quoteProspectMode.classList.toggle("hidden", linkedMode);

  if (linkedMode && selectedContext) {
    dom.quoteRequestTitle.value = `${selectedContext.propertyName} · ${selectedContext.title}`;
    dom.quoteContextSummary.innerHTML = `
      <article class="quote-context-card">
        <div class="section-row compact-row">
          <div>
            <p class="section-eyebrow">Quote context</p>
            <h3>${escapeHtml(selectedContext.propertyName)} · ${escapeHtml(selectedContext.title)}</h3>
            <p class="card-copy">${escapeHtml(selectedContext.propertyAddress || "")}</p>
          </div>
          <div class="chip-row">
            ${statusChip(selectedContext.statusLabel)}
            ${selectedContext.assignmentName ? statusChip(selectedContext.assignmentName) : ""}
            ${selectedContext.quoteStatus ? statusChip(`${selectedContext.quoteStatus}${selectedContext.quoteTotal ? ` · ${money(selectedContext.quoteTotal)}` : ""}`, "success") : ""}
          </div>
        </div>
        <div class="quote-context-actions">
          <button class="visit-link open-thread" data-request-id="${escapeHtml(selectedContext.requestId)}" type="button">Open homeowner thread</button>
          ${selectedContext.fieldWorkspaceUrl ? `<a class="visit-link primary" href="${escapeHtml(selectedContext.fieldWorkspaceUrl)}" target="_blank" rel="noreferrer">Open field workspace</a>` : ""}
        </div>
      </article>
    `;
    dom.quoteContextHelper.textContent = selectedContext.quoteStatus
      ? "This request already has quote activity. Updating and sending here will refresh the homeowner's Chez thread."
      : "Tie the quote to the homeowner request so messaging, approvals, visit planning, and follow-up stay in one clean thread.";
    wireRequestActionButtons(dom.quoteContextSummary);
  } else if (linkedMode && existingQuote && state.quoteDraft?.householdId) {
    dom.quoteRequestTitle.value = `${existingQuote.propertyName || "Home"} · ${existingQuote.title || "Quote"}`;
    dom.quoteContextSummary.innerHTML = `
      <article class="quote-context-card">
        <div class="section-row compact-row">
          <div>
            <p class="section-eyebrow">Quote context</p>
            <h3>${escapeHtml(existingQuote.propertyName || "Standalone home quote")}</h3>
            <p class="card-copy">This quote is saved in the workspace, but it is not tied to an active homeowner request.</p>
          </div>
          <div class="chip-row">${statusChip(existingQuote.statusLabel || "Draft")}</div>
        </div>
      </article>
    `;
    dom.quoteContextHelper.textContent = "Drafts without a homeowner request can still be saved here. To send through Chez messaging, choose an active client request.";
  } else if (linkedMode) {
    dom.quoteRequestTitle.value = "";
    dom.quoteContextSummary.innerHTML = `
      <article class="empty-state-panel">
        <p class="visit-title">No client request selected yet</p>
        <p class="card-copy">Pick the homeowner request you are pricing. Chez will keep the quote, the communication thread, and the related visit history together.</p>
      </article>
    `;
    dom.quoteContextHelper.textContent = contexts.length
      ? "Choose a request above to start building the quote."
      : "No homes have routed a handyman request into this workspace yet. Once they do, quotes can be built and sent from here.";
  } else {
    const name = (state.quoteDraft.prospectName || "").trim();
    const email = (state.quoteDraft.prospectEmail || "").trim();
    const address = (state.quoteDraft.prospectAddress || "").trim();
    const phone = (state.quoteDraft.prospectPhone || "").trim();
    dom.quoteRequestTitle.value = "";
    dom.quoteProspectSummary.innerHTML = name || email || address || phone
      ? `
        <article class="quote-context-card">
          <div class="section-row compact-row">
            <div>
              <p class="section-eyebrow">Recipient</p>
              <h3>${escapeHtml(name || email || "Prospect quote")}</h3>
              <p class="card-copy">${escapeHtml([email, phone].filter(Boolean).join(" · "))}</p>
            </div>
            <div class="chip-row">
              ${address ? statusChip(address) : ""}
              ${state.quoteDraft.quoteId && state.quoteDraft.publicShareUrl ? statusChip("Share link ready", "success") : statusChip("Draft", "warning")}
            </div>
          </div>
          <div class="quote-context-actions">
            ${state.quoteDraft.publicShareUrl ? `<a class="visit-link primary" href="${escapeHtml(state.quoteDraft.publicShareUrl)}" target="_blank" rel="noreferrer">Open quote link</a>` : ""}
            ${state.quoteDraft.publicShareUrl ? `<button class="visit-link copy-quote-link" data-quote-link="${escapeHtml(state.quoteDraft.publicShareUrl)}" type="button">Copy share link</button>` : ""}
          </div>
        </article>
      `
      : `
        <article class="empty-state-panel">
          <p class="visit-title">Standalone prospect quote</p>
          <p class="card-copy">Use this for a quick walk-up quote, an inbound lead, or a client who is not set up in Chez yet. Save the draft or send it by email with a secure share link.</p>
        </article>
      `;
    dom.quoteContextHelper.textContent = "Standalone quotes can be saved without a Chez home. Add an email when you are ready to send a secure share link.";
    dom.quoteProspectSummary.querySelectorAll(".copy-quote-link").forEach((button) => {
      button.addEventListener("click", () => {
        copyText(button.dataset.quoteLink);
        setFeedback(dom.quoteFeedback, "Share link copied.");
      });
    });
  }

  dom.saveQuoteButton.disabled = !hasLineItems;
  dom.sendQuoteButton.disabled = !quoteCanSend();
}

function applyQuoteContext(contextId, { preserveTitle = false } = {}) {
  if (!state.quoteDraft) return;
  const context = buildQuoteContexts().find((item) => item.id === contextId) || null;

  state.quoteDraft.recipientKind = "linked_home";
  state.quoteDraft.selectedContextId = context?.id || "";
  state.quoteDraft.requestId = context?.requestId || null;
  state.quoteDraft.visitTaskId = context?.visitTaskId || null;
  state.quoteDraft.contractorId = context?.contractorId || state.quoteDraft.contractorId || null;
  state.quoteDraft.householdId = context?.householdId || null;
  state.quoteDraft.propertyId = context?.propertyId || null;

  if (!preserveTitle) {
    state.quoteDraft.title = quoteTitleForContext(context);
    dom.quoteTitle.value = state.quoteDraft.title;
  }

  syncQuoteContextPicker();
  syncQuoteContextUI();
}

function setQuoteRecipientKind(kind, { preserveTitle = false } = {}) {
  if (!state.quoteDraft) return;
  state.quoteDraft.recipientKind = kind;

  if (kind === "prospect") {
    state.quoteDraft.selectedContextId = "";
    state.quoteDraft.requestId = null;
    state.quoteDraft.visitTaskId = null;
    state.quoteDraft.householdId = null;
    state.quoteDraft.propertyId = null;
    if (!preserveTitle) {
      state.quoteDraft.title = quoteTitleForProspect(state.quoteDraft.prospectName, state.quoteDraft.prospectAddress);
      dom.quoteTitle.value = state.quoteDraft.title;
    }
  } else if (kind === "linked_home") {
    const defaultContextId = defaultQuoteContextId(state.quoteDraft.requestId);
    if (defaultContextId) {
      applyQuoteContext(defaultContextId, { preserveTitle });
      return;
    }
    if (!preserveTitle) {
      state.quoteDraft.title = "Handyman quote";
      dom.quoteTitle.value = state.quoteDraft.title;
    }
  }

  syncQuoteContextPicker();
  syncQuoteContextUI(state.quoteDraft.quoteId ? quoteById(state.quoteDraft.quoteId) : null);
}

function renderWorkspace() {
  const dashboard = state.dashboard;
  if (!dashboard || dashboard.needsWorkspace) return;

  syncExperienceMode();
  dom.authPanel.classList.add("hidden");
  dom.workspacePanel.classList.remove("hidden");

  if (!state.tabInitialized) {
    state.activeTab = providerPermissions().isFieldTechnician ? "dispatch" : "overview";
    state.tabInitialized = true;
  }

  renderWorkspaceHeader();
  applyContextualNav();
  renderMobileSnapshot();
  renderStats();
  renderTodayBoard();
  renderCrewWorkload();
  renderQuotePipeline();
  renderThreads(dom.overviewMessages, dashboard.messages.slice(0, 6), "When homeowners message your company through Chez, the latest threads will show up here.");
  renderDispatchBoard();
  renderCalendar();
  renderRoutes();
  renderCrew();
  renderHomes();
  renderQuotes();
  renderSavedItems();
  renderRecentWork();
  renderThreads(dom.messagesList, dashboard.messages, "Homeowner threads will show up here as soon as they start messaging your team.");
  hydrateQuotePicker();
  loadDirectoryForm();

  if (!state.selectedRequestId && dashboard.messages.length) {
    selectRequest(dashboard.messages[0].requestId);
  } else if (!state.selectedRequestId && dashboard.visits.length) {
    selectRequest(dashboard.visits[0].requestId);
  } else {
    syncMessageComposer();
  }

  wireCrewButtons();
  wireRequestActionButtons(dom.quotesList);
}

function openQuoteBuilder(requestId = null, quoteId = null) {
  if (!providerPermissions().canBuildQuotes) {
    setFeedback(dom.quoteFeedback, "Quote access is disabled for this role.", true);
    return;
  }

  const existingQuote = quoteId ? quoteById(quoteId) : null;
  const defaultContextId = existingQuote?.requestId || defaultQuoteContextId(requestId);
  const defaultContext = buildQuoteContexts().find((context) => context.id === defaultContextId) || null;
  const recipientKind = existingQuote?.recipientKind || (defaultContext ? "linked_home" : "prospect");

  const lineItems = existingQuote?.lineItems?.length
    ? existingQuote.lineItems.map((item) => ({
        id: item.id || crypto.randomUUID(),
        name: item.name || "",
        description: item.description || "",
        unit: item.unit || "ea",
        quantity: Number(item.quantity || 1),
        unitPrice: Number(item.unit_price || item.unitPrice || 0),
      }))
    : [
        {
          id: crypto.randomUUID(),
          name: "",
          description: "",
          unit: "ea",
          quantity: 1,
          unitPrice: 0,
        },
      ];

  state.quoteDraft = {
    quoteId: existingQuote?.id || null,
    publicShareUrl: existingQuote?.publicShareUrl || "",
    recipientKind,
    selectedContextId: defaultContext?.id || "",
    requestId: defaultContext?.requestId || existingQuote?.requestId || null,
    visitTaskId: defaultContext?.visitTaskId || existingQuote?.visitTaskId || null,
    contractorId: defaultContext?.contractorId || existingQuote?.contractorId || state.dashboard?.linkedContractors?.[0]?.contractorId || null,
    householdId: defaultContext?.householdId || existingQuote?.householdId || null,
    propertyId: defaultContext?.propertyId || existingQuote?.propertyId || null,
    prospectName: existingQuote?.recipientKind === "prospect" ? (existingQuote?.recipientName || "") : "",
    prospectEmail: existingQuote?.recipientKind === "prospect" ? (existingQuote?.recipientEmail || "") : "",
    prospectPhone: existingQuote?.recipientKind === "prospect" ? (existingQuote?.recipientPhone || "") : "",
    prospectAddress: existingQuote?.recipientKind === "prospect" ? (existingQuote?.recipientAddress || "") : "",
    title: existingQuote?.title || quoteTitleForContext(defaultContext),
    homeownerMessage: existingQuote?.homeownerMessage || "",
    scopeNotes: existingQuote?.scopeNotes || "",
    lineItems,
  };

  if (!defaultContext && recipientKind === "prospect" && !state.quoteDraft.title) {
    state.quoteDraft.title = quoteTitleForProspect(state.quoteDraft.prospectName, state.quoteDraft.prospectAddress);
  }

  dom.quoteModalTitle.textContent = existingQuote ? "Edit quote" : "New quote";
  dom.quoteTitle.value = state.quoteDraft.title;
  dom.quoteHomeownerMessage.value = state.quoteDraft.homeownerMessage;
  dom.quoteScopeNotes.value = state.quoteDraft.scopeNotes;
  dom.quoteProspectName.value = state.quoteDraft.prospectName || "";
  dom.quoteProspectEmail.value = state.quoteDraft.prospectEmail || "";
  dom.quoteProspectPhone.value = state.quoteDraft.prospectPhone || "";
  dom.quoteProspectAddress.value = state.quoteDraft.prospectAddress || "";
  syncQuoteContextPicker();
  renderQuoteDraft();
  syncQuoteContextUI(existingQuote);
  setFeedback(dom.quoteFeedback, "");
  dom.quoteModal.classList.remove("hidden");
}

function renderQuoteDraft() {
  if (!state.quoteDraft) return;
  dom.quoteLineItems.innerHTML = "";
  state.quoteDraft.lineItems.forEach((item) => {
    const row = document.createElement("div");
    row.className = "line-item-row";
    row.innerHTML = `
      <label><span>Name</span><input data-field="name" data-id="${escapeHtml(item.id)}" type="text" value="${escapeHtml(item.name)}"></label>
      <label><span>Description</span><input data-field="description" data-id="${escapeHtml(item.id)}" type="text" value="${escapeHtml(item.description)}"></label>
      <label><span>Unit</span><input data-field="unit" data-id="${escapeHtml(item.id)}" type="text" value="${escapeHtml(item.unit)}"></label>
      <label><span>Qty</span><input data-field="quantity" data-id="${escapeHtml(item.id)}" type="number" min="0" step="0.25" value="${escapeHtml(item.quantity)}"></label>
      <label><span>Unit price</span><input data-field="unitPrice" data-id="${escapeHtml(item.id)}" type="number" min="0" step="0.01" value="${escapeHtml(item.unitPrice)}"></label>
      <div class="line-total">${escapeHtml(money(Number(item.quantity || 0) * Number(item.unitPrice || 0)))}</div>
      <button class="ghost-button remove-line-item" data-id="${escapeHtml(item.id)}" type="button">Remove</button>
    `;
    dom.quoteLineItems.appendChild(row);
  });

  dom.quoteLineItems.querySelectorAll("input").forEach((input) => {
    input.addEventListener("input", (event) => {
      const id = event.target.dataset.id;
      const field = event.target.dataset.field;
      const draftItem = state.quoteDraft.lineItems.find((item) => item.id === id);
      if (!draftItem) return;
      draftItem[field] = field === "quantity" || field === "unitPrice" ? Number(event.target.value || 0) : event.target.value;
      renderQuoteDraft();
    });
  });

  dom.quoteLineItems.querySelectorAll(".remove-line-item").forEach((button) => {
    button.addEventListener("click", () => {
      state.quoteDraft.lineItems = state.quoteDraft.lineItems.filter((item) => item.id !== button.dataset.id);
      if (!state.quoteDraft.lineItems.length) {
        state.quoteDraft.lineItems.push({
          id: crypto.randomUUID(),
          name: "",
          description: "",
          unit: "ea",
          quantity: 1,
          unitPrice: 0,
        });
      }
      renderQuoteDraft();
    });
  });

  dom.quoteSubtotal.textContent = money(quoteTotals(state.quoteDraft.lineItems));
  syncQuoteContextUI(state.quoteDraft.quoteId ? quoteById(state.quoteDraft.quoteId) : null);
}

function closeQuoteBuilder() {
  state.quoteDraft = null;
  dom.quoteModal.classList.add("hidden");
  setFeedback(dom.quoteFeedback, "");
}

async function submitQuote(sendNow) {
  if (!state.quoteDraft) return;
  state.quoteDraft.title = dom.quoteTitle.value.trim();
  state.quoteDraft.homeownerMessage = dom.quoteHomeownerMessage.value.trim();
  state.quoteDraft.scopeNotes = dom.quoteScopeNotes.value.trim();
  state.quoteDraft.prospectName = dom.quoteProspectName.value.trim();
  state.quoteDraft.prospectEmail = dom.quoteProspectEmail.value.trim();
  state.quoteDraft.prospectPhone = dom.quoteProspectPhone.value.trim();
  state.quoteDraft.prospectAddress = dom.quoteProspectAddress.value.trim();

  try {
    const payload = await providerRequest("POST", {
      action: sendNow ? "send_quote" : "save_quote",
      workspaceId: state.dashboard.workspace.id,
      quoteId: state.quoteDraft.quoteId,
      requestId: state.quoteDraft.requestId,
      visitTaskId: state.quoteDraft.visitTaskId,
      contractorId: state.quoteDraft.contractorId,
      householdId: state.quoteDraft.householdId,
      propertyId: state.quoteDraft.propertyId,
      recipientKind: state.quoteDraft.recipientKind,
      prospectName: state.quoteDraft.prospectName,
      prospectEmail: state.quoteDraft.prospectEmail,
      prospectPhone: state.quoteDraft.prospectPhone,
      prospectAddress: state.quoteDraft.prospectAddress,
      title: state.quoteDraft.title,
      homeownerMessage: state.quoteDraft.homeownerMessage,
      scopeNotes: state.quoteDraft.scopeNotes,
      lineItems: state.quoteDraft.lineItems,
    });
    if (payload.quote?.id) {
      state.quoteDraft.quoteId = payload.quote.id;
      state.quoteDraft.publicShareUrl = payload.quote.public_share_token
        ? `https://www.getchez.com/handyman-quote?quote=${encodeURIComponent(payload.quote.public_share_token)}`
        : state.quoteDraft.publicShareUrl;
    }
    const deliveryMessage = sendNow
      ? (payload.delivery?.sent
          ? `Quote sent by ${payload.delivery.channel}.`
          : `Quote saved, but delivery still needs attention: ${payload.delivery?.error || "No outbound email was sent."}`)
      : "Quote draft saved.";
    setFeedback(dom.quoteFeedback, deliveryMessage, Boolean(sendNow && payload.delivery && payload.delivery.sent === false));
    await refreshWorkspace();
    if (payload.quote && (!sendNow || payload.delivery?.sent)) closeQuoteBuilder();
  } catch (error) {
    setFeedback(dom.quoteFeedback, error.message, true);
  }
}

async function saveLineItem(event) {
  event.preventDefault();
  try {
    await providerRequest("POST", {
      action: "save_quote_item",
      workspaceId: state.dashboard.workspace.id,
      name: dom.savedItemName.value.trim(),
      description: dom.savedItemDescription.value.trim(),
      unit: dom.savedItemUnit.value.trim(),
      defaultQuantity: dom.savedItemQuantity.value,
      defaultUnitPrice: dom.savedItemPrice.value,
    });
    dom.savedItemForm.reset();
    dom.savedItemUnit.value = "ea";
    dom.savedItemQuantity.value = "1";
    dom.savedItemPrice.value = "0";
    await refreshWorkspace();
    setFeedback(dom.authFeedback, "Saved line item added to your library.");
  } catch (error) {
    setFeedback(dom.authFeedback, error.message, true);
  }
}

async function sendMessage(event) {
  event.preventDefault();
  if (!state.selectedRequestId) {
    setFeedback(dom.authFeedback, "Choose a request first so the message lands in the right homeowner thread.", true);
    return;
  }
  try {
    const payload = await providerRequest("POST", {
      action: "send_message",
      workspaceId: state.dashboard.workspace.id,
      requestId: state.selectedRequestId,
      status: dom.messageStatus.value,
      body: dom.messageBody.value.trim(),
    });
    dom.messageBody.value = "";
    dom.messageStatus.value = "";
    await refreshWorkspace();
    setFeedback(
      dom.authFeedback,
      payload.delivery?.sent
        ? "Update sent to the homeowner."
        : `Update saved in Chez, but outbound delivery needs attention: ${payload.delivery?.error || "No email was sent."}`,
      Boolean(payload.delivery && payload.delivery.sent === false),
    );
  } catch (error) {
    setFeedback(dom.authFeedback, error.message, true);
  }
}

async function inviteTeamMember(event) {
  event.preventDefault();
  try {
    const payload = await providerRequest("POST", {
      action: "invite_team_member",
      workspaceId: state.dashboard.workspace.id,
      fullName: dom.teamName.value.trim(),
      email: dom.teamEmail.value.trim(),
      phone: dom.teamPhone.value.trim(),
      role: dom.teamRole.value,
      title: dom.teamTitle.value.trim(),
    });
    dom.teamForm.reset();
    dom.teamRole.value = "technician";
    setFeedback(dom.teamFeedback, payload.member?.inviteUrl ? "Secure invite created. The link is ready to share." : "Team member saved.");
    if (payload.member?.inviteUrl) copyText(payload.member.inviteUrl);
    await refreshWorkspace();
  } catch (error) {
    setFeedback(dom.teamFeedback, error.message, true);
  }
}

// Chez v1: directory listing — homeowner-side find-a-handyman discovery.
// Reads the current values directly from `provider_workspaces` via the
// user's RLS-scoped session (members can SELECT their workspace).
// Saves go through `update_workspace_directory` on handyman-provider so
// service-role writes happen with workspace-membership verification.
async function loadDirectoryForm() {
  if (!dom.directoryForm || !state.dashboard?.workspace?.id) return;
  try {
    const { data, error } = await supabase
      .from("provider_workspaces")
      .select(
        "is_listed_in_directory, service_state, service_city, service_zip_codes, categories, display_blurb, headshot_url",
      )
      .eq("id", state.dashboard.workspace.id)
      .maybeSingle();
    if (error) throw error;
    const row = data || {};
    dom.directoryListed.checked = Boolean(row.is_listed_in_directory);
    dom.directoryState.value = row.service_state || "";
    dom.directoryCity.value = row.service_city || "";
    dom.directoryZips.value = Array.isArray(row.service_zip_codes)
      ? row.service_zip_codes.join(", ")
      : "";
    const cats = Array.isArray(row.categories) && row.categories.length > 0 ? row.categories : ["handyman"];
    dom.directoryCategories.value = cats.join(", ");
    dom.directoryBlurb.value = row.display_blurb || "";
    dom.directoryHeadshot.value = row.headshot_url || "";
    if (dom.directoryStatusPill) {
      dom.directoryStatusPill.textContent = row.is_listed_in_directory ? "Listed" : "Hidden";
    }
    setFeedback(dom.directoryFeedback, "");
  } catch (error) {
    setFeedback(dom.directoryFeedback, error.message || "Could not load directory settings.", true);
  }
}

async function saveDirectoryListing(event) {
  event.preventDefault();
  if (!state.dashboard?.workspace?.id) return;
  setFeedback(dom.directoryFeedback, "Saving…");
  dom.directorySaveButton.disabled = true;
  try {
    const payload = await providerRequest("POST", {
      action: "update_workspace_directory",
      workspaceId: state.dashboard.workspace.id,
      isListedInDirectory: dom.directoryListed.checked,
      serviceState: dom.directoryState.value.trim(),
      serviceCity: dom.directoryCity.value.trim(),
      serviceZipCodes: dom.directoryZips.value.trim(),
      categories: dom.directoryCategories.value.trim(),
      displayBlurb: dom.directoryBlurb.value.trim(),
      headshotUrl: dom.directoryHeadshot.value.trim(),
    });
    const ws = payload.workspace || {};
    if (dom.directoryStatusPill) {
      dom.directoryStatusPill.textContent = ws.is_listed_in_directory ? "Listed" : "Hidden";
    }
    setFeedback(
      dom.directoryFeedback,
      ws.is_listed_in_directory
        ? "Saved. Homeowners in your service area can now find you in the Chez app."
        : "Saved. Listing is hidden from homeowners.",
    );
  } catch (error) {
    setFeedback(dom.directoryFeedback, error.message || "Save failed.", true);
  } finally {
    dom.directorySaveButton.disabled = false;
  }
}

async function signIn(event) {
  event.preventDefault();
  setFeedback(dom.authFeedback, "");
  const { error } = await supabase.auth.signInWithPassword({
    email: dom.signInEmail.value.trim(),
    password: dom.signInPassword.value,
  });
  if (error) {
    setFeedback(dom.authFeedback, error.message, true);
    return;
  }
  setFeedback(dom.authFeedback, "Signed in. Loading your workspace.");
  await refreshWorkspace();
}

async function signUp(event) {
  event.preventDefault();
  setFeedback(dom.authFeedback, "");

  const payload = workspaceSeed();
  const { data, error } = await supabase.auth.signUp({
    email: dom.signUpEmail.value.trim(),
    password: dom.signUpPassword.value,
    options: {
      data: {
        full_name: payload.fullName,
      },
    },
  });

  if (error) {
    setFeedback(dom.authFeedback, error.message, true);
    return;
  }

  state.session = data.session || null;
  if (!state.session) {
    setFeedback(dom.authFeedback, "Account created. Check your email to confirm the account, then sign in here.");
    showAuthMode("sign-in");
    dom.signInEmail.value = dom.signUpEmail.value.trim();
    return;
  }

  await providerRequest("POST", {
    action: "bootstrap_workspace",
    ...payload,
  });
  setFeedback(dom.authFeedback, "Account created. Loading your Chez Handyman workspace.");
  await refreshWorkspace();
}

function applySavedItem(itemId) {
  const item = state.dashboard?.savedQuoteItems.find((saved) => saved.id === itemId);
  if (!item || !state.quoteDraft) return;
  state.quoteDraft.lineItems.push({
    id: crypto.randomUUID(),
    name: item.name,
    description: item.description || "",
    unit: item.unit || "ea",
    quantity: item.defaultQuantity || 1,
    unitPrice: item.defaultUnitPrice || 0,
  });
  renderQuoteDraft();
}

function bindEvents() {
  dom.showSignIn.addEventListener("click", () => showAuthMode("sign-in"));
  dom.showSignUp.addEventListener("click", () => showAuthMode("sign-up"));
  dom.signInForm.addEventListener("submit", signIn);
  dom.signUpForm.addEventListener("submit", signUp);
  dom.signOutButton.addEventListener("click", async () => {
    await supabase.auth.signOut();
    state.dashboard = null;
    state.session = null;
    state.inviteLinked = false;
    state.tabInitialized = false;
    state.activeTab = "overview";
    await refreshWorkspace();
  });
  dom.navButtons.forEach((button) => {
    button.addEventListener("click", () => showTab(button.dataset.tab));
  });
  dom.messageForm.addEventListener("submit", sendMessage);
  dom.savedItemForm.addEventListener("submit", saveLineItem);
  dom.teamForm.addEventListener("submit", inviteTeamMember);
  dom.directoryForm.addEventListener("submit", saveDirectoryListing);
  dom.newQuoteButton.addEventListener("click", () => {
    showTab("quotes");
    openQuoteBuilder();
  });
  dom.quickNewQuote.addEventListener("click", () => {
    showTab("quotes");
    openQuoteBuilder();
  });
  dom.quickOpenMyDay.addEventListener("click", () => showTab("dispatch"));
  dom.closeQuoteModal.addEventListener("click", closeQuoteBuilder);
  dom.quoteKindLinked.addEventListener("click", () => setQuoteRecipientKind("linked_home"));
  dom.quoteKindProspect.addEventListener("click", () => setQuoteRecipientKind("prospect"));
  dom.quoteContextSelect.addEventListener("change", (event) => {
    applyQuoteContext(event.target.value);
  });
  [dom.quoteProspectName, dom.quoteProspectEmail, dom.quoteProspectPhone, dom.quoteProspectAddress].forEach((field) => {
    field.addEventListener("input", () => {
      if (!state.quoteDraft) return;
      state.quoteDraft.prospectName = dom.quoteProspectName.value.trim();
      state.quoteDraft.prospectEmail = dom.quoteProspectEmail.value.trim();
      state.quoteDraft.prospectPhone = dom.quoteProspectPhone.value.trim();
      state.quoteDraft.prospectAddress = dom.quoteProspectAddress.value.trim();
      if (currentQuoteKind() === "prospect" && (!dom.quoteTitle.value.trim() || dom.quoteTitle.value.trim().startsWith("Quote for"))) {
        state.quoteDraft.title = quoteTitleForProspect(state.quoteDraft.prospectName, state.quoteDraft.prospectAddress);
        dom.quoteTitle.value = state.quoteDraft.title;
      }
      syncQuoteContextUI(state.quoteDraft.quoteId ? quoteById(state.quoteDraft.quoteId) : null);
    });
  });
  dom.addLineItemButton.addEventListener("click", () => {
    if (!state.quoteDraft) return;
    state.quoteDraft.lineItems.push({
      id: crypto.randomUUID(),
      name: "",
      description: "",
      unit: "ea",
      quantity: 1,
      unitPrice: 0,
    });
    renderQuoteDraft();
  });
  dom.savedItemPicker.addEventListener("change", (event) => {
    if (!event.target.value) return;
    applySavedItem(event.target.value);
    event.target.value = "";
  });
  dom.saveQuoteButton.addEventListener("click", () => submitQuote(false));
  dom.sendQuoteButton.addEventListener("click", () => submitQuote(true));
  dom.quoteModal.addEventListener("click", (event) => {
    if (event.target === dom.quoteModal) closeQuoteBuilder();
  });
  window.addEventListener("resize", () => {
    if (state.dashboard) renderWorkspace();
  });
}

async function init() {
  syncExperienceMode();
  bindEvents();
  await loadInvitePreview();
  await refreshWorkspace();

  supabase.auth.onAuthStateChange(async (_event, session) => {
    state.session = session;
    await refreshWorkspace();
  });
}

init();

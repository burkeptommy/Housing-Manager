import SwiftUI

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
    static let openScenarioStudio = Notification.Name("openScenarioStudio")
    static let openAlfredWithContext = Notification.Name("openAlfredWithContext")
    static let popToRoot = Notification.Name("popToRoot")

    // Cross-tab data sync notifications
    static let maintenanceTaskChanged = Notification.Name("maintenanceTaskChanged")
    /// Phase 70 (Tasks v2): Deep-link contract. Posted to navigate to a
    /// specific task / routine / routine occurrence + briefly highlight
    /// its row in the unified MaintenanceTabView feed.
    ///
    /// Caller responsibility: post `.switchToTab` (tab 2) first to make
    /// sure the Tasks tab is foreground, then post this notification.
    ///
    /// `userInfo` schema (all keys optional but at least one must be set):
    ///   - "task_id": String UUID of a `maintenance_tasks` row (bundle
    ///     parent OR standalone task). When matched, scrolls the season
    ///     feed to the row and renders the highlight overlay for ~1.5s.
    ///   - "routine_id": String UUID of a `routines` row. Routes to the
    ///     "Your active programs" section; expands the routine card.
    ///   - "occurrence_date": ISO yyyy-MM-dd. Combined with routine_id,
    ///     picks the specific routine occurrence in the season feed.
    ///   - "property_id": String UUID. Sets `activePropertyId` so
    ///     multi-property households jump to the right property.
    ///   - "season": "Spring" | "Summer" | "Fall" | "Winter". Override
    ///     the auto-detected season filter so the feed scrolls to where
    ///     the linked item actually lives (e.g. a Fall task deep-linked
    ///     in mid-July still routes to the Fall scope).
    ///
    /// Used by `HavenApp.userNotificationCenter` (push handler), the
    /// inbox item detail action menu, the activity feed "view task"
    /// link, and the email forwarding pipeline.
    static let openMaintenanceTask = Notification.Name("openMaintenanceTask")
    /// Phase H — opens the Tasks v2 TasksTimelineSheet (18-month linear
    /// scrub) on the Maintenance tab. Used by Dashboard's "View full
    /// schedule" link as a direct replacement for the retired
    /// MaintenanceScheduleView Calendar destination.
    ///
    /// Caller responsibility: post `.switchToTab` (tab 2) first so the
    /// Tasks tab is foreground; this notification asks MaintenanceTabView
    /// to open the year overview sheet.
    static let openTasksYearOverview = Notification.Name("openTasksYearOverview")
    static let homeSystemChanged = Notification.Name("homeSystemChanged")
    static let contractorChanged = Notification.Name("contractorChanged")
    /// Phase 19l: Posted when a NEW contractor is created (not edited).
    /// Listeners use this to re-fire the post-quiz delegation sheet for any
    /// 'either' tasks that the new vendor's category could take over.
    /// `userInfo["contractorId"]` carries the new row's UUID.
    static let contractorAdded = Notification.Name("contractorAdded")
    static let advisorChanged = Notification.Name("advisorChanged")
    static let documentChanged = Notification.Name("documentChanged")
    static let propertyChanged = Notification.Name("propertyChanged")
    static let projectChanged = Notification.Name("projectChanged")
    /// Phase 51: Posted when a standing appointment is created, updated, paused, or archived.
    static let standingAppointmentChanged = Notification.Name("standingAppointmentChanged")
    /// Phase 54E: Posted when a household cadence is created, updated, or deleted.
    /// Property and Maintenance surfaces listen for this to refresh count badges
    /// and virtual-occurrence rows without manual pull-to-refresh.
    static let householdCadenceChanged = Notification.Name("householdCadenceChanged")
    /// Phase 55: Posted when a routine is created, updated, archived, or deleted.
    /// Replaces `.householdCadenceChanged` once Section 55.3 repoints the last
    /// legacy writer; for 55.1/55.2 both names coexist so readers don't miss
    /// updates during the transition.
    static let routineChanged = Notification.Name("routineChanged")
    static let inboxItemUpdated = Notification.Name("inboxItemUpdated")
    static let navigateToVehicle = Notification.Name("navigateToVehicle")
    /// Phase 95 audit: posted whenever a vehicle row is created, updated,
    /// or archived. PropertyListView's "Your Garage" + the Maintenance
    /// hub's Vehicles section both observe this so the homeowner doesn't
    /// have to kill the app to see a freshly-added or sold vehicle.
    /// `userInfo["vehicle_id"]` carries the row's UUID when applicable.
    static let vehicleChanged = Notification.Name("vehicleChanged")
    /// Phase 95 audit: posted whenever a family member or staff row is
    /// created, updated, or removed (Settings → Household Staff,
    /// Settings → Family Members, Q28 quiz steps, accept invitation).
    /// Dashboard's HouseholdStrip + HouseholdStaffStrip both observe
    /// this so newly-invited spouses / kids / home managers appear
    /// without a tab switch.
    static let householdMemberChanged = Notification.Name("householdMemberChanged")
    /// Phase 95 audit: posted by Dashboard when the homeowner taps
    /// "Hand off everything" on the ChezOwnershipHeroCard. Picked up
    /// by ChezOwnershipView once it mounts, which auto-arms the
    /// "hand off everything" confirmation dialog so the user lands on
    /// a confirmation modal rather than the explainer screen.
    static let triggerChezFullMode = Notification.Name("triggerChezFullMode")
    static let navigateToInboxItem = Notification.Name("navigateToInboxItem")
    static let navigateToPropertySection = Notification.Name("navigateToPropertySection")

    // Invite + onboarding
    static let inviteCodeReceived = Notification.Name("inviteCodeReceived")
    /// Posted by AddPropertyFlow's confirmation step when the user taps
    /// "Take House Quiz". `object` carries the new `PropertyRow`.
    static let startHouseQuiz = Notification.Name("startHouseQuiz")

    /// Phase 50: Posted by `InvoiceProcessingViewModel` after it detects an
    /// explicit recurring service cadence on an invoice (>0.8 confidence).
    /// The Dashboard listens for this and renders a confirmation card so
    /// the user can accept the new interval and update the system row.
    static let invoiceCadenceDetected = Notification.Name("invoiceCadenceDetected")

    /// Chez v1: Posted by the new Property → Projects empty-state starter
    /// rows so PropertyProjectsView can open its "Add Project" dialog
    /// without requiring a custom binding handoff. `userInfo["mode"]` is
    /// "plan" (open NewProjectView), "log" (open LogHistoricalProjectView),
    /// or "import" (defer to inbox import flow).
    static let propertyProjectsRequestAdd = Notification.Name("propertyProjectsRequestAdd")

    /// Phase 67: Sent by the push handler when a `handyman_*` notification fires.
    /// `TasksHubView` listens and flips its title-switcher to Handyman mode so the
    /// user lands where the notification expects.
    static let handymanModeRequested = Notification.Name("handymanModeRequested")

    /// Phase 67: Sent by the push handler with `userInfo: ["request_id": String,
    /// "presentation": "visit" | "quote"]`. `HandymanTabView` listens and presents
    /// the visit detail sheet (or jumps straight to the quote review when the event
    /// was quote-related).
    static let openHandymanVisit = Notification.Name("openHandymanVisit")

    /// Phase 67E/F: Posted whenever a `handyman_punch_items` row is
    /// inserted, archived, or completed. Cleaner refresh signal than
    /// `.maintenanceTaskChanged` because the punch-list rail no longer
    /// shares state with the task table. Listeners include
    /// `HandymanPunchListView`, `HandymanTabView`, and the dashboard's
    /// punch-count reads. Both events post when a single action affects
    /// both rails (e.g. promote-to-task, demote-to-punch).
    static let handymanPunchListChanged = Notification.Name("handymanPunchListChanged")

    // MARK: - Phase 80 — Chez Concierge

    /// Posted whenever a Chez request is created, replied to, or
    /// status-transitioned. Listeners (Inbox tab badge, ChezRequestsList,
    /// ChezRequestDetail) reload counts + thread.
    static let chezRequestChanged = Notification.Name("chezRequestChanged")

    /// Posted by the push handler when a `chez_*` notification fires.
    /// `userInfo["request_id"]` carries the target request UUID.
    /// `InboxView` listens and switches to the Chez sub-tab + pushes
    /// `ChezRequestDetailView` for that id.
    static let openChezRequest = Notification.Name("openChezRequest")

    /// Posted by entry-point buttons throughout the app. The
    /// `userInfo["context"]` payload carries the prefilled
    /// `[String: String]` plus `"category"` so the composer auto-fills.
    /// MainTabView listens and presents `ChezRequestComposeSheet` as a
    /// global sheet so any entry point can fire it without owning the
    /// sheet state itself.
    static let openChezRequestComposer = Notification.Name("openChezRequestComposer")
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var uploadManager = DocumentUploadManager.shared
    @State private var selectedTab = 0
    @State private var showScenarioStudio = false
    @State private var scenarioInitialQuery: String?
    @State private var isKeyboardVisible = false

    // Phase 80 — Chez Concierge composer presentation. Any entry point
    // (FindLocalVendorSheet, MaintenanceTaskDetailSheet, HandymanPunchListView,
    // QuoteAnalysisView, DashboardView pill) posts
    // `.openChezRequestComposer` with category + context payload; we own
    // the sheet here so callers don't have to thread a binding through.
    @State private var chezComposerInput: ChezComposerInput?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Processing banner — visible across all tabs
                ProcessingBanner { documentId in
                    selectedTab = 0
                    NotificationCenter.default.post(
                        name: .navigateToInboxItem,
                        object: nil,
                        userInfo: ["documentId": documentId]
                    )
                }

                TabView(selection: $selectedTab) {
                DashboardView()
                    .environmentObject(appState)
                    .tag(0)

                PropertyListView()
                    .tag(1)

                // Phase 95 (gap #41): wrap the Tasks hub render in a
                // feature-flag check so we have a rollback path if the
                // V5 redesign hits an issue post-launch. The flag
                // defaults to true (V5 is the shipping path) and can be
                // flipped to false via UserDefaults to fall back to the
                // pre-V5 MaintenanceHubView. Reads at view init time so
                // the first launch after a flag flip picks up the
                // change without an app restart.
                Group {
                    if UserDefaults.standard.object(forKey: "tasksHubV5Enabled") as? Bool ?? true {
                        TasksHubView()
                    } else {
                        // Pre-V5 fallback: route directly into
                        // MaintenanceHubView the same way PropertyDetailView
                        // does. Keeps the surface usable while we debug
                        // any V5-specific regressions.
                        NavigationStack {
                            MaintenanceHubView(filterPropertyId: nil)
                        }
                    }
                }
                .environmentObject(appState)
                .tag(2)

                ChatView()
                    .tag(3)
            }
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                customTabBar
            }
            } // end VStack

            // (Floating "What If?" FAB removed — Scenarios now lives in
            // the Alfred tab toolbar, so the AI surface area is in one
            // place. ScenarioStudioView still presents from MainTabView
            // via the .openScenarioStudio notification path below.)
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: selectedTab) { _, newTab in
            Haptics.selection()
            let tabNames = ["Dashboard", "Property", "Tasks", "Alfred"]
            let name = newTab < tabNames.count ? tabNames[newTab] : "Unknown"
            Analytics.track(.tabSelected, ["tab": name, "tab_index": newTab])
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { notification in
            if let tab = notification.userInfo?["tab"] as? Int {
                selectedTab = tab
                // Also pop to root on the target tab to clear any stale navigation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    NotificationCenter.default.post(name: .popToRoot, object: nil, userInfo: ["tab": tab])
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAlfredWithContext)) { notification in
            // Switch to Alfred tab when "Ask Alfred about this project" is tapped
            selectedTab = 3
        }
        .onReceive(NotificationCenter.default.publisher(for: .openScenarioStudio)) { notification in
            if let query = notification.userInfo?["query"] as? String {
                scenarioInitialQuery = query
            }
            // Switch to Alfred tab so scenarios always feel like they
            // live "in Alfred" — the FAB used to present from any tab
            // but the experience is now anchored on tab 3.
            selectedTab = 3
            showScenarioStudio = true
        }
        .fullScreenCover(isPresented: $showScenarioStudio) {
            scenarioInitialQuery = nil
        } content: {
            ScenarioStudioView(initialQuery: scenarioInitialQuery)
        }
        .sheet(isPresented: $uploadManager.showInvoiceChoiceSheet) {
            if let review = uploadManager.currentInvoiceReview {
                InvoiceChoiceSheet(review: review) {
                    uploadManager.dismissCurrentInvoiceReview()
                }
            }
        }
        .sheet(isPresented: $uploadManager.showDuplicateSheet) {
            if let resolution = uploadManager.currentDuplicateResolution {
                DuplicateResolutionSheet(resolution: resolution, manager: uploadManager)
            }
        }
        // Phase 80 — Chez composer. Presented globally so any entry-point
        // button can fire `.openChezRequestComposer` without owning sheet
        // state. `ChezComposerInput` is the small `Identifiable` payload
        // the notification carries: category + context dict + whether the
        // category should be locked (true for everything except .general).
        .sheet(item: $chezComposerInput) { input in
            ChezRequestComposeSheet(
                category: input.category,
                contextHints: input.contextHints,
                isCategoryFixed: input.isCategoryFixed
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .openChezRequestComposer)) { notification in
            guard let info = notification.userInfo else { return }
            let categoryRaw = info["category"] as? String ?? ChezCategory.general.rawValue
            let category = ChezCategory(rawValue: categoryRaw) ?? .general
            let rawContext = info["context"] as? [String: String] ?? [:]
            let context = normalizedChezContext(rawContext, category: category)
            // Lock the picker for every category except `.general` — the
            // user landed there from a specific surface, so flipping the
            // category mid-compose breaks the prefilled context.
            let isFixed = category != .general
            chezComposerInput = ChezComposerInput(
                category: category,
                contextHints: context,
                isCategoryFixed: isFixed
            )
            Analytics.track(.chezEntryButtonTapped, [
                "category": category.rawValue,
                "context_keys": context.keys.sorted().joined(separator: ","),
            ])
        }
    }

    /// Phase 80 — Identifiable wrapper so SwiftUI's `.sheet(item:)` can
    /// present + dismiss a fresh composer per notification.
    private struct ChezComposerInput: Identifiable {
        let id = UUID()
        let category: ChezCategory
        let contextHints: [String: String]
        let isCategoryFixed: Bool
    }

    private func normalizedChezContext(_ rawContext: [String: String], category: ChezCategory) -> [String: String] {
        var context = rawContext
        if context["source_entity_type"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            context["source_entity_type"] = inferredSourceEntityType(from: context, category: category)
        }
        if context["source_entity_label"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            context["source_entity_label"] = inferredSourceEntityLabel(from: context, category: category)
        }
        return context
    }

    private func inferredSourceEntityType(from context: [String: String], category: ChezCategory) -> String {
        if context["task_id"] != nil { return "task" }
        if context["routine_id"] != nil { return "routine" }
        if context["contractor_id"] != nil || context["vendor"] != nil || context["vendor_name"] != nil { return "vendor" }
        if context["system_id"] != nil || context["system_category"] != nil { return "system" }
        if context["project_id"] != nil { return "project" }
        if context["property_id"] != nil { return "property" }
        if context["vehicle_id"] != nil { return "vehicle" }
        if context["document_id"] != nil { return "document" }
        if context["inbox_item_id"] != nil { return "inbox_item" }
        if let source = context["_source"], !source.isEmpty { return source }
        return category.rawValue
    }

    private func inferredSourceEntityLabel(from context: [String: String], category: ChezCategory) -> String {
        for key in [
            "task_title",
            "routine_label",
            "contractor_name",
            "vendor_name",
            "vendor",
            "system_name",
            "system_category",
            "project_name",
            "property_name",
            "vehicle",
            "title",
            "_alfred_context_name",
        ] {
            if let value = context[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty {
                return value
            }
        }
        switch category {
        case .findVendor: return "Vendor search"
        case .getQuote: return "Quote request"
        case .scheduleVisit: return "Visit scheduling"
        case .coordinateTask: return "Task coordination"
        case .findHandyman: return "Handyman request"
        case .general: return "General Chez request"
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(icon: "square.grid.2x2.fill", label: "Dashboard", tag: 0)
            tabButton(icon: "building.columns.fill", label: "Property", tag: 1)
            tabButton(icon: "checklist", label: "Tasks", tag: 2)
            alfredTabButton
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            HavenColors.creamLight
                .shadow(color: HavenColors.beige300.opacity(0.5), radius: 4, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        Button {
            if selectedTab == tag {
                NotificationCenter.default.post(name: .popToRoot, object: nil, userInfo: ["tab": tag])
            } else {
                selectedTab = tag
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    NotificationCenter.default.post(name: .popToRoot, object: nil, userInfo: ["tab": tag])
                }
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(height: 22)
                Text(label)
                    .font(.system(size: 10, weight: selectedTab == tag ? .semibold : .medium))
            }
            .foregroundStyle(selectedTab == tag ? HavenColors.action : HavenColors.tabInactive)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // Alfred gets a branded monogram icon
    private var alfredTabButton: some View {
        Button {
            if selectedTab == 3 {
                NotificationCenter.default.post(name: .popToRoot, object: nil, userInfo: ["tab": 3])
            } else {
                selectedTab = 3
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    NotificationCenter.default.post(name: .popToRoot, object: nil, userInfo: ["tab": 3])
                }
            }
        } label: {
            VStack(spacing: 3) {
                alfredIcon
                    .frame(height: 22)
                Text("Alfred")
                    .font(.system(size: 10, weight: selectedTab == 3 ? .semibold : .medium))
            }
            .foregroundStyle(selectedTab == 3 ? HavenColors.action : HavenColors.tabInactive)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Alfred")
    }

    private var alfredIcon: some View {
        ZStack {
            Circle()
                .fill(selectedTab == 3 ? HavenColors.action : HavenColors.tabInactive)
                .frame(width: 22, height: 22)
            AlfredMark(tint: HavenColors.creamLight, knotOverride: HavenColors.creamLight)
                .frame(width: 18, height: 18)
        }
    }
}

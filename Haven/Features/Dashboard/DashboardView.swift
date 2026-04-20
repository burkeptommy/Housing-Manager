import SwiftUI

/// Identifiable wrapper so sheet(item:) carries the system name atomically.
struct VendorActionItem: Identifiable {
    let id = UUID()
    let systemName: String
}

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var vaultViewModel = DocumentVaultViewModel()
    @State private var showSettings = false
    @State private var showUploadDocument = false
    @State private var showAddProperty = false
    @State private var showSecurityDashboard = false
    @State private var navigationPath = NavigationPath()
    @State private var showScenarioStudio = false
    @State private var hasAppeared = false
    @State private var selectedDashboardTask: MaintenanceTaskDBRow?
    @AppStorage("hasSeenSecurityBadge") private var hasSeenSecurityBadge = false
    @State private var gettingStartedExpanded = false
    @State private var showServiceContractSheet = false
    @State private var serviceContractType: String = ""
    @State private var showApplianceSetup = false
    @State private var pendingMergeRequest: [String: Any]?
    @State private var showEstateIntake = false
    @State private var showVendorCoverage = false
    @State private var findVendorSystemName: String?
    @State private var findVendorItem: VendorActionItem?
    @State private var addVendorItem: VendorActionItem?
    @State private var isAcceptingMerge = false
    @State private var showMergeResolution = false
    @State private var mergePreviewResponse: MergePreviewResponse?
    @State private var showQuickProjectEntry = false
    @State private var quickProjectPrefill: String = ""
    @AppStorage("hasSeenEmailCallout") private var hasSeenEmailCallout = false
    @State private var showFamilyMemberChooser = false
    @State private var familyMemberFormMode: AddFamilyMemberMode?
    @State private var selectedMemberForProfile: FamilyMemberRow?
    @State private var showAddressCompletion = false
    @State private var activeQuizProperty: PropertyRow?
    @State private var showQuizSkipDialog = false
    @AppStorage("hasSkippedHouseQuizForever") private var hasSkippedHouseQuizForever = false
    @AppStorage(PendingInviteKeys.needsPersonalQuiz) private var needsPersonalQuiz = false
    @State private var showPersonalQuiz = false

    /// Phase 61: Presents the LegacyTasksView in a sheet. Opened from the
    /// "View details" button on LegacyTasksNotificationCard.
    @State private var showLegacyTasks = false

    /// Phase 56.4: Session-only dismissal flag for the
    /// HandymanSuggestionCard. Intentionally not persisted — the punch
    /// list is real work that needs scheduling, so "Not now" comes back
    /// next launch. Matches the Maintenance tab's behavior.
    @State private var handymanSuggestionDismissedThisSession = false

    /// Phase 19l — re-fire path for the post-quiz vendor delegation sheet.
    /// When a new contractor is added mid-app (via ContractorDirectoryView
    /// or any other path that posts `.contractorAdded`), the dashboard
    /// computes whether the new vendor's category has any 'either' tasks
    /// the household could delegate. Non-empty `dashboardDelegationCandidates`
    /// triggers the sheet automatically.
    @State private var dashboardDelegationCandidates: [VendorDelegationCandidate] = []
    @State private var showDashboardDelegationSheet: Bool = false

    /// Phase 50 — Cadence suggestion coordinator. Holds the most recent
    /// invoice cadence suggestion until the user accepts or dismisses it.
    /// Lives at app scope so the suggestion survives the InvoiceReviewSheet
    /// dismissal that publishes it. Using @ObservedObject on the singleton
    /// (not @StateObject) so the dashboard observes the shared instance
    /// rather than owning a fresh copy.
    @ObservedObject private var cadenceCoordinator = InvoiceCadenceCoordinator.shared

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: HavenTheme.spacing16) {
                    // Phase 56.2: the 32pt in-content "Haven" title was
                    // removed so the hero/greeting sit higher in the
                    // viewport. Brand identity lives in the nav bar's
                    // principal toolbar item below.

                    if viewModel.isLoading && !hasAppeared {
                        SkeletonScorecard()
                        SkeletonCard(lineCount: 2)
                        SkeletonCard(lineCount: 3)
                    } else {
                        // 0. Optional update banner (Phase 13). Session-only
                        // dismissal so it reappears on next launch until the
                        // user actually updates.
                        if !appState.optionalUpdateDismissedThisSession,
                           let latest = appState.optionalUpdateLatestVersion,
                           let message = appState.optionalUpdateMessage {
                            OptionalUpdateBanner(
                                latestVersion: latest,
                                message: message,
                                appStoreURL: appState.forceUpdateAppStoreURL
                                    ?? URL(string: "https://apps.apple.com/app/id6757167606")!,
                                onDismiss: {
                                    appState.optionalUpdateDismissedThisSession = true
                                }
                            )
                        }

                        // Phase 56.2: compact greeting — single line
                        // + optional seasonal context tip. Replaces
                        // the two-line "Good evening" / weekday-date
                        // view. Saves ~32pt vertical.
                        compactGreeting

                        // Phase 66: One-time "We reorganized your
                        // maintenance" card for existing TestFlight
                        // users. Dismisses permanently via @AppStorage.
                        // Gated on hasCompletedAnyQuiz so fresh signups
                        // (who land on the new hub from the start) don't
                        // see a "we reorganized" message about a tab
                        // they've never seen the old version of.
                        if viewModel.hasCompletedAnyQuiz {
                            MaintenanceReorganizedCard(
                                onLearnMore: {
                                    NotificationCenter.default.post(
                                        name: .switchToTab,
                                        object: nil,
                                        userInfo: ["tab": 1]
                                    )
                                },
                                onDismiss: {}
                            )
                        }

                        // 2. Getting Started / Quiz hero — Day 0 focal point.
                        // Phase 50 (sub-phase B first-login): only renders
                        // when no property exists OR no property's quiz is
                        // complete. Once any quiz finishes, this disappears
                        // entirely and the YOUR HOME section below takes
                        // over as the primary CTA.
                        if viewModel.showGettingStarted {
                            gettingStartedCard
                        }

                        // 2.5 Incomplete address banner
                        if let property = viewModel.propertyNeedsAddress {
                            incompleteAddressBanner(property)
                        }

                        // 2.6 Pending merge request banner
                        if let merge = pendingMergeRequest {
                            mergeRequestBanner(merge)
                        }

                        // ── Build 90 / Phase 56.2: Focused Dashboard ──
                        //
                        // Scroll order tightened: Hero → Quick Actions →
                        // UP NEXT (conditional) → View full schedule →
                        // event banners → Recent → Foundation. Quick
                        // Actions promoted above UP NEXT so the primary
                        // 4 actions are visible without scrolling.

                        // 2 + 3. Hero + Quick Actions — conceptually one
                        // unit ("your home status + what you can do").
                        // Phase 56.2 Addendum Fix 6: VStack(spacing: 8)
                        // couples them tightly so the actions sit right
                        // below the hero without the default 16pt gap.
                        if viewModel.hasCompletedAnyQuiz {
                            VStack(spacing: 4) {
                                HomeCoverageHero(
                                    coveredCount: viewModel.coveredCoverageItems.count,
                                    totalCount: viewModel.coveredCoverageItems.count + viewModel.uncoveredCoverageItems.count,
                                    activeVendorCount: viewModel.activeVendorCount,
                                    nextVisit: viewModel.nextScheduledService,
                                    uncoveredSystemNames: viewModel.uncoveredCoverageItems.map(\.systemName),
                                    onTap: {
                                        Haptics.light()
                                        // Phase 56.4: the segmented filter is gone;
                                        // route to the Maintenance list directly and
                                        // let the user tap stats pills to scope.
                                        navigationPath.append("maintenance")
                                    },
                                    onFindVendor: {
                                        Haptics.medium()
                                        showVendorCoverage = true
                                    }
                                )

                                QuickActionsRow(
                                onAskAlfred: {
                                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 3])
                                },
                                onUploadDoc: {
                                    showUploadDocument = true
                                },
                                onScenarioStudio: {
                                    showScenarioStudio = true
                                    Analytics.track(.scenarioStudioOpened, ["source": "dashboard_quick_action"])
                                },
                                onAddVendor: {
                                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
                                }
                            )
                            } // end hero + quick actions VStack
                        }

                        // Phase 56.4: Proactive handyman scheduling
                        // suggestion. Surfaces when ≥3 punch items
                        // accumulate with no upcoming handyman task
                        // scheduled in the next 30 days and no recent
                        // completion. Session-dismissible.
                        if viewModel.hasCompletedAnyQuiz,
                           viewModel.shouldShowHandymanSuggestion,
                           !handymanSuggestionDismissedThisSession {
                            HandymanSuggestionCard(
                                punchItemCount: viewModel.handymanPunchItemCount,
                                onSchedule: {
                                    NotificationCenter.default.post(
                                        name: .switchToTab,
                                        object: nil,
                                        userInfo: ["tab": 1]
                                    )
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        NotificationCenter.default.post(
                                            name: .navigateToPropertySection,
                                            object: nil,
                                            userInfo: ["section": "handyman_punch_list"]
                                        )
                                    }
                                },
                                onDismiss: {
                                    handymanSuggestionDismissedThisSession = true
                                }
                            )
                        }

                        // Phase 57: "What's New" card surfaces the new
                        // HNW routines to existing users. Only renders for
                        // properties created before the release cutoff and
                        // stays dismissed once the user closes it. Opens
                        // `UpdateHomeDetailsSheet` for opt-in review.
                        if viewModel.hasCompletedAnyQuiz,
                           let primaryProperty = viewModel.properties.first(where: { $0.id == viewModel.primaryPropertyId }) {
                            WhatsNewPhase57Card(
                                property: primaryProperty,
                                onReviewComplete: {
                                    Task { await viewModel.refresh() }
                                }
                            )
                        }

                        // Phase 61: Legacy task cleanup notification.
                        // Renders only when the household has archived tasks
                        // AND the user hasn't dismissed. Tapping opens the
                        // LegacyTasksView sheet directly from the Dashboard.
                        if viewModel.hasCompletedAnyQuiz {
                            LegacyTasksNotificationCard(
                                legacyCount: viewModel.legacyTaskCount,
                                onViewDetails: { showLegacyTasks = true }
                            )
                        }

                        // Phase 63: FindHandymanCard surfaces for users whose
                        // Q15b answer captured "I need help finding a handyman"
                        // AND the household still doesn't have a handyman
                        // contractor on file. Tap opens Alfred with a vetting
                        // prompt. Snoozes 30 days on "Later".
                        if viewModel.hasCompletedAnyQuiz,
                           viewModel.propertyAttributes["handyman_preference"]?.stringValue == "needs_help",
                           !viewModel.dashboardContractors.contains(where: {
                               $0.category?.caseInsensitiveCompare("Handyman") == .orderedSame
                           }) {
                            FindHandymanCard(
                                onFindOptions: {
                                    // ChatView.onReceive reads "message" from
                                    // the userInfo — use the same key.
                                    NotificationCenter.default.post(
                                        name: .openAlfredWithContext,
                                        object: nil,
                                        userInfo: [
                                            "message": "I need help finding a reliable handyman for routine small-fixes work around the house. What should I look for and what questions should I ask when vetting candidates?"
                                        ]
                                    )
                                    Analytics.track(.findHandymanCardTapped)
                                }
                            )
                        }

                        // 4. YOUR TO-DOS — Phase 56.2 conditional.
                        //   0 items: section absent, just "View full schedule"
                        //   1 item:  compact inline strip, no titled section
                        //   2+:      existing full titled section
                        if viewModel.hasCompletedAnyQuiz {
                            let itemCount = viewModel.thisWeekItems.count
                            if itemCount == 0 {
                                viewFullScheduleLink
                            } else if itemCount == 1 {
                                singleUpNextStrip
                                viewFullScheduleLink
                            } else {
                                thisWeekSection
                                viewFullScheduleLink
                            }
                        }

                        // 3.5 Cadence suggestion (inline, event-driven)
                        if let suggestion = cadenceCoordinator.current {
                            CadenceSuggestionCard(
                                suggestion: suggestion,
                                onAccept: {
                                    Task {
                                        let ok = await cadenceCoordinator.apply(suggestion)
                                        if ok {
                                            Haptics.success()
                                            await viewModel.refresh()
                                        } else {
                                            Haptics.error()
                                        }
                                    }
                                },
                                onDismiss: {
                                    cadenceCoordinator.dismiss()
                                    Haptics.light()
                                }
                            )
                        }

                        // 3.4 Phase 54D.3: Pickup day banner (trash /
                        // recycling / school dropoff). Renders only
                        // inside the banner's own surfacing window
                        // (after 6pm for tomorrow, before 10am for
                        // today) so the dashboard stays quiet the
                        // rest of the day.
                        if viewModel.hasCompletedAnyQuiz,
                           let householdId = viewModel.primaryHouseholdId {
                            PickupDayBanner(
                                householdId: householdId,
                                onTap: {
                                    navigationPath.append("routines")
                                },
                                onEdit: {
                                    navigationPath.append("routines")
                                }
                            )
                        }

                        // 5. Recent Activity feed — Phase 56.2: feed
                        // uses `dashboardActivityEvents`, which filters
                        // onboarding "X added" noise after Day 7 so the
                        // card stays useful beyond the setup week. The
                        // full unfiltered list is still reachable via
                        // "View all activity" → ActivityLogView.
                        if viewModel.hasCompletedAnyQuiz && !viewModel.dashboardActivityEvents.isEmpty {
                            RecentActivityFeed(
                                events: viewModel.dashboardActivityEvents,
                                totalEventCount: viewModel.allActivityEvents.count,
                                onTap: { event in
                                    handleActivityTap(event)
                                },
                                onViewAll: {
                                    navigationPath.append("activity_log")
                                }
                            )
                        }

                        // Phase 56.2: "Discover more services for your
                        // home" orphan link removed. Accessible from
                        // Property → Maintenance → Recommended row and
                        // from Contacts → Add or discover, so three
                        // entry points remain without the dashboard
                        // clutter.

                        // 5. Foundation (contextual estate card)
                        if viewModel.shouldShowFoundation {
                            FoundationCard(
                                message: viewModel.foundationMessage,
                                icon: viewModel.foundationIcon,
                                onTap: {
                                    Haptics.light()
                                    let hasStartedIntake = viewModel.estateState?.intakeState?.startedAt != nil
                                    let isStale = viewModel.estateState?.stalenessTier == "critical" || viewModel.estateState?.stalenessTier == "amber"
                                    if hasStartedIntake || isStale {
                                        showEstateIntake = true
                                    } else {
                                        NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
                                    }
                                }
                            )
                        }

                        // ── Conditional sections ──

                        // "Make it Yours" hero card for invitees
                        if needsPersonalQuiz {
                            makeItYoursHeroCard
                        }

                        // Expecting members
                        ForEach(viewModel.expectingMembers) { member in
                            NavigationLink(value: "expecting_\(member.id.uuidString)") {
                                expectingCard(member: member)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.top, HavenTheme.spacing4)
                .padding(.bottom, 100)
            }
            .background(HavenColors.background)
            .navigationTitle("Haven")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Phase 56.2: small brand wordmark in the nav bar
                    // replaces the 32pt in-content title. Serif, navy,
                    // never competing with the hero for vertical space.
                    Text("Haven")
                        .font(HavenTypography.fraunces(size: 18, weight: 700))
                        .foregroundStyle(HavenColors.navy800)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.light()
                        Analytics.track(.dashboardSecurityTapped)
                        navigationPath.append("security")
                    } label: {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.navy800)
                    }
                    .accessibilityLabel("Security")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // (Quick-add "+" menu removed — Upload Document was a
                        // duplicate entry point, View Tasks is reachable from
                        // the Needs Your Attention list and the Maintenance
                        // tab. Trailing toolbar collapses to Inbox + Settings.)

                        NavigationLink(value: "inbox") {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(HavenColors.navy800)

                                let pendingCount = viewModel.inboxItems.filter { $0.isPending }.count
                                if pendingCount > 0 {
                                    Text("\(pendingCount)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 16, height: 16)
                                        .background(HavenColors.warning)
                                        .clipShape(Circle())
                                        .offset(x: 6, y: -6)
                                }
                            }
                        }
                        .accessibilityLabel("Inbox")
                        .accessibilityHint("View forwarded emails")

                        Button {
                            Haptics.light()
                            Analytics.track(.settingsViewed)
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(HavenColors.navy800)
                        }
                        .accessibilityLabel("Settings")
                        .accessibilityHint("Open app settings")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showLegacyTasks) {
                NavigationStack {
                    LegacyTasksView()
                }
            }
            .sheet(isPresented: $showUploadDocument) {
                DocumentUploadView(onComplete: {
                    Task { await viewModel.refresh() }
                })
            }
            .sheet(isPresented: $showAddProperty) {
                AddPropertyFlow(onComplete: { _ in
                    // Immediately mark property as existing to avoid stale UI
                    viewModel.hasProperty = true
                    Task { await viewModel.refresh() }
                })
            }
            .sheet(item: $selectedDashboardTask) { task in
                NavigationStack {
                    MaintenanceTaskDetailSheet(task: task, onTaskCompleted: {
                        Task { await viewModel.refresh() }
                    })
                }
                .presentationDetents([.medium, .large])
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "inbox" {
                    InboxView()
                } else if destination == "security" {
                    SecurityDashboardView()
                } else if destination == "maintenance" {
                    // Phase 66: Default Maintenance tab lands on the new
                    // 5-section hub (Your Services / Handyman / Vehicles /
                    // This Season / Upcoming Scheduled). The older
                    // MaintenanceScheduleView is the Timeline push
                    // destination accessed via "See full year ↗" inside
                    // the hub.
                    MaintenanceHubView()
                } else if destination == "maintenance_calendar" {
                    // Phase 54A: "View full schedule" on the dashboard
                    // lands users in the Calendar layout of the canonical
                    // maintenance view — no more parallel ScheduleCalendarView.
                    // Phase 66: kept as the Timeline push destination.
                    MaintenanceScheduleView(initialLayout: .calendar)
                } else if destination == "recommended_services" {
                    // Phase 54C.3: Dashboard "Discover more" link.
                    if let property = viewModel.properties.first {
                        RecommendedServicesView(
                            householdId: property.householdId,
                            propertyId: property.id
                        )
                    }
                } else if destination == "routines" {
                    // Phase 55.3: Pickup day banner tap / edit opens
                    // the unified routines list. Replaces the
                    // Phase 54D.3 "household_cadences" destination.
                    if let householdId = viewModel.primaryHouseholdId {
                        RoutinesListView(
                            householdId: householdId,
                            propertyId: viewModel.properties.first?.id
                        )
                    }
                } else if destination == "estate_readiness" {
                    ReadinessDetailView()
                        .environmentObject(vaultViewModel)
                } else if destination == "email_forwarding" {
                    ProjectEmailView()
                } else if destination == "vehicles" {
                    if let firstVehicle = viewModel.vehicles.first {
                        VehicleDetailView(vehicleID: firstVehicle.id)
                    } else {
                        PropertyListView()
                    }
                } else if destination.hasPrefix("inbox_item_"),
                          let itemId = UUID(uuidString: String(destination.dropFirst("inbox_item_".count))),
                          let item = viewModel.inboxItems.first(where: { $0.id == itemId }) {
                    InboxItemDetailView(
                        item: item,
                        properties: viewModel.properties,
                        onProcess: { propertyId, action, category, vehicleId in
                            Task {
                                await viewModel.processInboxItem(item, propertyId: propertyId, action: action, category: category)
                            }
                        },
                        onDismiss: {
                            viewModel.dismissInboxItem(item)
                        },
                        onDelete: {
                            viewModel.inboxItems.removeAll { $0.id == item.id }
                            Haptics.success()
                            Task {
                                try? await DatabaseService.shared.deleteInboxItem(id: item.id)
                            }
                        }
                    )
                } else if destination == "activity_log" {
                    ActivityLogView(
                        events: viewModel.allActivityEvents,
                        onTap: { event in
                            handleActivityTap(event)
                        }
                    )
                } else if destination.hasPrefix("expecting_"),
                          let memberId = UUID(uuidString: String(destination.dropFirst("expecting_".count))),
                          let member = viewModel.expectingMembers.first(where: { $0.id == memberId }) {
                    NewArrivalChecklistView(member: member, documents: viewModel.allDocuments)
                } else {
                    EmptyView()
                }
            }
            .sheet(isPresented: $showVendorCoverage) {
                vendorCoverageSheetContent
            }
            .sheet(item: $findVendorItem) { item in
                // Phase 56.1: Find-a-Pro must always open the local vendor
                // recommender, even when there's no "Find a contractor for:"
                // task row yet (common for covered-but-gap-flagged systems
                // or Tier 1 gaps that don't have a DB system row).
                // FindLocalVendorSheet now accepts an optional task + an
                // explicit household id so it can render and adopt without
                // a triggering task.
                if let property = viewModel.properties.first,
                   let context = resolveFindVendorContext(for: item.systemName, property: property) {
                    FindLocalVendorSheet(
                        task: context.task,
                        householdId: property.householdId,
                        town: property.city ?? "",
                        state: property.state ?? "",
                        systemCategory: context.category,
                        categoryDisplayName: context.category.lowercased(),
                        onComplete: {
                            Task { await viewModel.refresh() }
                        }
                    )
                } else {
                    // No property or household available — defensive
                    // fallback so the sheet never dead-ends.
                    AddVendorSheet(onComplete: {
                        Task { await viewModel.refresh() }
                    })
                }
            }
            .sheet(item: $addVendorItem) { action in
                // Tapping "I have one" on a Vendor Coverage gap card
                // opens the pick-or-add picker so the user can link an
                // existing vendor (e.g. the water softener shares a
                // provider with water & well services) or add a new
                // one. Both paths link the contractor to the system
                // via `preferredContractorId`.
                if let coverageItem = viewModel.uncoveredCoverageItems.first(where: { $0.systemName == action.systemName }),
                   let householdId = viewModel.primaryHouseholdId {
                    VendorCoveragePickerSheet(
                        coverageItem: coverageItem,
                        householdId: householdId,
                        propertyId: viewModel.primaryPropertyId,
                        onComplete: {
                            Task { await viewModel.refresh() }
                        }
                    )
                } else {
                    // Fallback when the coverage item isn't available
                    // (coverage data refreshed between tap and sheet
                    // presentation, or no household resolved yet).
                    AddVendorSheet(onComplete: {
                        Task { await viewModel.refresh() }
                    })
                }
            }
            // Phase 56.1: BrowseSpecialty / AddRecurringService /
            // AddSystemFromCoverage / AddCustomVendorFromCoverage sheets
            // were removed with the Vendor Coverage discovery footer —
            // those entry points now live on Property → Contacts.
            .sheet(isPresented: $showServiceContractSheet) {
                ServiceContractSheet(
                    serviceType: serviceContractType,
                    propertyId: viewModel.primaryPropertyId ?? UUID(),
                    householdId: viewModel.primaryHouseholdId ?? UUID(),
                    onComplete: {
                        Task { await viewModel.refresh() }
                    }
                )
            }
            .sheet(isPresented: $showApplianceSetup) {
                ApplianceSetupSheet(
                    propertyId: viewModel.primaryPropertyId ?? UUID(),
                    householdId: viewModel.primaryHouseholdId ?? UUID(),
                    existingSystems: viewModel.homeSystems,
                    onComplete: { newSystems in
                        viewModel.homeSystems.append(contentsOf: newSystems)
                        Task { await viewModel.refresh() }
                    }
                )
            }
            .sheet(isPresented: $showQuickProjectEntry) {
                if let propId = viewModel.primaryPropertyId,
                   let hhId = viewModel.primaryHouseholdId {
                    NewProjectView(
                        propertyID: propId,
                        householdId: hhId,
                        viewModel: ProjectsViewModel()
                    )
                }
            }
            .sheet(isPresented: $showFamilyMemberChooser) {
                AddFamilyMemberChooserSheet { mode in
                    familyMemberFormMode = mode
                }
                .presentationDetents([.medium])
            }
            .sheet(item: $familyMemberFormMode) { mode in
                NavigationStack {
                    FamilyMemberFormView(initialMode: mode, onSave: {
                        Task { await viewModel.refresh() }
                    })
                }
            }
            .sheet(item: $selectedMemberForProfile) { member in
                NavigationStack {
                    FamilyMemberProfileView(member: member)
                }
                .presentationDetents([.large])
            }
            .fullScreenCover(isPresented: $showScenarioStudio) {
                ScenarioStudioView()
            }
            .fullScreenCover(item: $activeQuizProperty) { property in
                HouseQuizView(property: property)
            }
            .sheet(isPresented: $showPersonalQuiz) {
                PersonalQuizView()
            }
            .sheet(isPresented: $showEstateIntake) {
                if let hid = viewModel.primaryHouseholdId ?? viewModel.properties.first?.householdId {
                    EstateIntakeFormView(householdId: hid)
                }
            }
            .confirmationDialog("Skip the House Quiz?", isPresented: $showQuizSkipDialog, titleVisibility: .visible) {
                Button("Skip for now") {
                    // Just dismisses the card for this session — re-shows next launch.
                }
                Button("Skip forever", role: .destructive) {
                    hasSkippedHouseQuizForever = true
                    Analytics.track(.quizDismissed, ["scope": "forever"])
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Skip for now will resurface the quiz on next launch. Skip forever means you'll add this data manually.")
            }
            .trackScreen("Dashboard")
            .refreshable {
                Haptics.light()
                Analytics.track(.dashboardRefreshed)
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadDashboard()
                await vaultViewModel.loadData()
                hasAppeared = true
                // Check for pending merge requests
                do {
                    let data = try await HavenSupabase.mergeHouseholds(action: "check_pending_merges")
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let hasPending = json["has_pending"] as? Bool, hasPending,
                       let request = json["merge_request"] as? [String: Any] {
                        pendingMergeRequest = request
                    }
                } catch {
                    print("[Dashboard] Failed to check merge requests: \(error)")
                }

                // Phase 20b — when a brand-new user just finished
                // AccountCreationStep, OnboardingViewModel.complete() stamps
                // the freshly-created property on appState. Pick it up here
                // and auto-launch HouseQuizView. Cleared after consumption
                // so it never re-fires on subsequent dashboard appearances.
                if let pending = appState.pendingQuizProperty {
                    activeQuizProperty = pending
                    appState.pendingQuizProperty = nil
                    Analytics.track(.quizStarted, [
                        "source": "post_account_creation_auto",
                        "property_id": pending.id.uuidString
                    ])
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .popToRoot)) { notification in
                if let tab = notification.userInfo?["tab"] as? Int, tab == 0 {
                    navigationPath = NavigationPath()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .startHouseQuiz)) { notification in
                // AddPropertyFlow's confirmation step posts this with the
                // freshly created PropertyRow when the user taps "Take House
                // Quiz". Refresh first so the new property is in the list,
                // then open HouseQuizView for it.
                if let property = notification.object as? PropertyRow {
                    Task {
                        await viewModel.refresh()
                        activeQuizProperty = property
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToInboxItem)) { notification in
                if let documentId = notification.userInfo?["documentId"] as? UUID {
                    // Find the inbox item for this document
                    if let item = viewModel.inboxItems.first(where: { $0.relatedDocumentId == documentId }) {
                        navigationPath.append("inbox_item_\(item.id.uuidString)")
                    } else {
                        // Item may not be loaded yet -- reload and retry
                        Task {
                            await viewModel.loadInboxItems()
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            let matchedItem = viewModel.inboxItems.first(where: { $0.relatedDocumentId == documentId })
                            if let item = matchedItem {
                                navigationPath.append("inbox_item_\(item.id.uuidString)")
                            }
                        }
                    }
                }
            }
            // Phase 19l — when a new contractor is added mid-app, recompute
            // delegation candidates limited to that one vendor and surface
            // the same sheet the post-quiz path uses. The userInfo carries
            // the new contractor's UUID so we don't fire for unrelated
            // contractors that happened to already exist.
            .onReceive(NotificationCenter.default.publisher(for: .contractorAdded)) { notification in
                guard
                    let idString = notification.userInfo?["contractorId"] as? String,
                    let contractorId = UUID(uuidString: idString)
                else { return }
                Task {
                    await loadDelegationCandidatesForContractor(contractorId)
                }
            }
            .sheet(isPresented: $showDashboardDelegationSheet) {
                PostQuizVendorDelegationSheet(
                    candidates: dashboardDelegationCandidates,
                    onApply: { selected in
                        for candidate in selected {
                            for task in candidate.tasks {
                                await MaintenanceViewModel.shared.convertToVendorManaged(
                                    taskId: task.id,
                                    contractor: candidate.contractor
                                )
                            }
                        }
                        Haptics.success()
                        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                        await viewModel.refresh()
                    },
                    onSkip: {
                        // No persistence needed on the re-fire path — the
                        // sheet only resurfaces when a brand-new contractor
                        // is added, which is already user-initiated.
                    }
                )
                .presentationDetents([.large])
            }
            .fullScreenCover(isPresented: $showMergeResolution) {
                if let preview = mergePreviewResponse,
                   let requestId = pendingMergeRequest?["id"] as? String {
                    MergeResolutionView(
                        preview: preview.preview,
                        summary: preview.summary,
                        mergeRequestId: requestId,
                        sourceHouseholdName: preview.sourceHouseholdName,
                        targetHouseholdName: preview.targetHouseholdName
                    ) {
                        pendingMergeRequest = nil
                        mergePreviewResponse = nil
                        Task { await viewModel.refresh() }
                    }
                }
            }
        }
    }

    // MARK: - Greeting

    // MARK: - Inbox Section

    private var vehicleAlertsCard: some View {
        NavigationLink(value: "vehicles") {
            HavenCard {
                HStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(viewModel.unresolvedVehicleRecalls > 0 ? HavenColors.critical : HavenColors.warning)
                        .frame(width: 36, height: 36)
                        .background((viewModel.unresolvedVehicleRecalls > 0 ? HavenColors.critical : HavenColors.warning).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        if viewModel.unresolvedVehicleRecalls > 0 {
                            Text("\(viewModel.unresolvedVehicleRecalls) Open Vehicle Recall\(viewModel.unresolvedVehicleRecalls == 1 ? "" : "s")")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                        } else {
                            Text("Vehicle Attention Needed")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        Text("Tap to view details")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var inboxSection: some View {
        VStack(spacing: HavenTheme.spacing8) {
            // Section header with "View All" link
            HStack {
                let pendingCount = viewModel.inboxItems.filter { $0.isPending }.count
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 12))
                    Text("INBOX")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                    if pendingCount > 0 {
                        Text("\(pendingCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(HavenColors.warning)
                            .clipShape(Circle())
                    }
                }
                .foregroundStyle(HavenColors.textTertiary)

                Spacer()

                NavigationLink(value: "inbox") {
                    Text("View All")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy)
                }
            }

            ForEach(viewModel.inboxItems.prefix(5)) { item in
                NavigationLink(value: "inbox_item_\(item.id.uuidString)") {
                    inboxBanner(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func inboxBanner(_ item: DatabaseService.InboxItemRow) -> some View {
        HStack(spacing: 12) {
            Group {
                if item.isProcessing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: item.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 30, height: 30)
            .background(item.isProcessing ? HavenColors.navy500 : item.isPending ? HavenColors.warning : HavenColors.success)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy800)
                        .lineLimit(1)
                    if item.isProcessing {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.mini)
                            Text("Processing")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(HavenColors.navy500)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                    } else if item.isPending {
                        Text("Action needed")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(HavenColors.warning)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(HavenColors.warning.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                if let summary = item.summary {
                    Text(summary)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if !item.isPending {
                Button {
                    withAnimation { viewModel.dismissInboxItem(item) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                        .padding(6)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(HavenTheme.spacing12)
        .background(item.isProcessing ? HavenColors.navy.opacity(0.04) : item.isPending ? HavenColors.warning.opacity(0.06) : HavenColors.success.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke((item.isProcessing ? HavenColors.navy : item.isPending ? HavenColors.warning : HavenColors.success).opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var greetingView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greetingText)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Phase 56.2 / Addendum Fix 4: Bold greeting + lighter date + icon-
    /// anchored seasonal tip. "**Good evening, Tom**  ·  Wednesday,
    /// April 15" reads as two semantically distinct items via weight
    /// contrast. The seasonal tip gains a month-driven icon (leaf, sun,
    /// wind, snowflake) so it doesn't float as a footnote.
    private var compactGreeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text(greetingText)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("  \u{00B7}  ")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            if let tip = viewModel.seasonalContextTip {
                HStack(spacing: 6) {
                    Image(systemName: seasonalIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(tip)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var seasonalIcon: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3, 4, 5: return "leaf.fill"
        case 6, 7, 8: return "sun.max.fill"
        case 9, 10, 11: return "wind"
        case 12, 1, 2: return "snowflake"
        default: return "calendar"
        }
    }

    /// Phase 56.2: trailing "View full schedule →" link. Extracted from
    /// the inline block inside `body` so the 0/1/2+ conditional UP NEXT
    /// branches can all reuse it.
    private var viewFullScheduleLink: some View {
        Button {
            Haptics.light()
            navigationPath.append("maintenance_calendar")
        } label: {
            HStack(spacing: 4) {
                Text("View full schedule")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.navy700)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .buttonStyle(.plain)
    }

    /// Phase 56.2: Type-aware caption for the single-item strip so the
    /// label reflects what the row actually is. Keeps the strip clearly
    /// distinct from the hero's "Next visit:" vendor schedule.
    private func singleStripCaption(for item: ThisWeekItem) -> String {
        switch item.kind {
        case .overdue:
            return "Overdue"
        case .vendorVisit:
            return "Also coming up"
        case .diyTask:
            return "Your to-do"
        case .inboxReview:
            return "To review"
        }
    }

    /// Phase 56.2: Compact one-row strip for when UP NEXT has exactly
    /// one item. Reads as hero context, not as a titled section.
    @ViewBuilder
    private var singleUpNextStrip: some View {
        if let item = viewModel.thisWeekItems.first {
            Button {
                Haptics.light()
                if case .inboxReview = item.kind {
                    navigationPath.append("inbox")
                } else if let task = item.task {
                    selectedDashboardTask = task
                }
            } label: {
                HStack(spacing: HavenTheme.spacing12) {
                    // Addendum Fix 7: lighter icon so the strip reads
                    // as ambient context beneath the bolder quick actions.
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 28, height: 28)
                        .background(HavenColors.beige200.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 7))

                    VStack(alignment: .leading, spacing: 1) {
                        // Phase 56.2: "Your to-do" distinguishes a
                        // personal action item from the hero's
                        // "Next visit:" vendor-schedule label above.
                        Text(singleStripCaption(for: item))
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(item.title)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .stroke(HavenColors.beige200, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    /// Build 90: Up Next section extracted to stay under SwiftUI's
    /// expression type-check budget.
    @ViewBuilder
    private var thisWeekSection: some View {
        ThisWeekSection(
            items: viewModel.thisWeekItems,
            totalTaskCount: viewModel.overdueMaintenanceTasks.count + viewModel.dueThisWeekTasks.count,
            onItemTapped: { item in
                Haptics.light()
                if case .inboxReview = item.kind {
                    navigationPath.append("inbox")
                } else if let task = item.task {
                    selectedDashboardTask = task
                }
            },
            onSeeAll: {
                // TODO: Navigate to MaintenanceScheduleView with .mine filter
                navigationPath.append("maintenance")
            },
            onSnooze: { item in
                Task {
                    await viewModel.snoozeTask(item)
                }
            }
        )
    }

    /// Phase 56.1: Resolves the context FindLocalVendorSheet needs when
    /// entered from the dashboard Vendor Coverage sheet. Uses the
    /// matching coverage item's category key (stable across
    /// system-backed and Tier 1 gap rows) so "Find a Pro" works even
    /// when no `needs_vendor` task exists yet. When a task does exist,
    /// we pass it through so the adoption pass has a concrete anchor.
    private func resolveFindVendorContext(
        for systemName: String,
        property: PropertyRow
    ) -> (task: MaintenanceTaskDBRow?, category: String)? {
        let candidate = (viewModel.uncoveredCoverageItems + viewModel.coveredCoverageItems)
            .first(where: { $0.systemName == systemName })

        // Prefer the category key from the coverage item — it's the
        // canonical token used across the registry + reconciler.
        let category: String? = {
            if let c = candidate, !c.id.isEmpty { return c.id }
            return viewModel.homeSystems
                .first(where: { $0.name == systemName })?.category
        }()

        guard let resolvedCategory = category else { return nil }

        let task: MaintenanceTaskDBRow? = {
            // Exact match by systemId first (strongest signal).
            if let systemId = candidate?.systemId ?? viewModel.homeSystems
                .first(where: { $0.name == systemName })?.id {
                if let t = MaintenanceViewModel.shared.tasks.first(where: {
                    $0.systemId == systemId && $0.needsVendor == true
                }) {
                    return t
                }
            }
            // Otherwise fall through — no triggering task, but the sheet
            // will still render because `task` is optional and the
            // adoption pass walks matching category tasks.
            return nil
        }()

        return (task: task, category: resolvedCategory)
    }

    private var vendorCoverageSheetContent: some View {
        // Phase 56.1: Vendor Coverage is now a focused gap-resolution
        // surface. Discovery actions (add vendor / browse specialty /
        // add routine / see recommended) moved to Property → Contacts.
        let uncovered = viewModel.uncoveredCoverageItems
        let total = uncovered.count + viewModel.coveredCoverageItems.count
        return VendorCoverageSheet(
            uncoveredItems: uncovered,
            totalSystemCount: total,
            onFindVendor: { systemName in
                showVendorCoverage = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    findVendorItem = VendorActionItem(systemName: systemName)
                }
            },
            onAddVendor: { systemName in
                showVendorCoverage = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    addVendorItem = VendorActionItem(systemName: systemName)
                }
            },
            onDismissItem: { item in
                guard let householdId = viewModel.primaryHouseholdId else { return }
                Task {
                    try? await DatabaseService.shared.dismissCategory(
                        householdId: householdId,
                        category: item.id
                    )
                    Analytics.track(.coverageItemDismissed, ["category": item.id])
                    await viewModel.refresh()
                }
            },
            onManageVendors: {
                // Phase 56.1: dismiss the sheet, switch to the Property
                // tab, and land on the Contacts sub-tab. Matches the
                // rest of the app's cross-tab navigation pattern
                // (switchToTab + navigateToPropertySection).
                showVendorCoverage = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    NotificationCenter.default.post(
                        name: .switchToTab,
                        object: nil,
                        userInfo: ["tab": 1]
                    )
                    NotificationCenter.default.post(
                        name: .navigateToPropertySection,
                        object: nil,
                        userInfo: ["section": "contacts"]
                    )
                }
            }
        )
    }

    /// Phase 50: Vendor schedule strip (kept for reference, no longer
    /// rendered on the dashboard body as of Build 90).
    @ViewBuilder
    private var vendorScheduleSection: some View {
        VendorScheduleStrip(
            visits: viewModel.upcomingVendorVisits,
            overdueCount: viewModel.overdueMaintenanceTasks.count,
            dueThisWeekCount: viewModel.dueThisWeekTaskCount,
            forwardingEmail: viewModel.householdForwardingEmail,
            onTapVisit: { task in
                selectedDashboardTask = task
            },
            onSeeAll: {
                navigationPath.append("maintenance")
            },
            onUploadInvoice: {
                showUploadDocument = true
            },
            onAddVendor: {
                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
            }
        )

        if let suggestion = cadenceCoordinator.current {
            CadenceSuggestionCard(
                suggestion: suggestion,
                onAccept: {
                    Task {
                        let ok = await cadenceCoordinator.apply(suggestion)
                        if ok {
                            Haptics.success()
                            await viewModel.refresh()
                        } else {
                            Haptics.error()
                        }
                    }
                },
                onDismiss: {
                    cadenceCoordinator.dismiss()
                    Haptics.light()
                }
            )
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        if hour < 12 { timeOfDay = "Good morning" }
        else if hour < 17 { timeOfDay = "Good afternoon" }
        else { timeOfDay = "Good evening" }

        if let firstName = viewModel.userFirstName, !firstName.isEmpty {
            return "\(timeOfDay), \(firstName)"
        }
        return timeOfDay
    }

    // MARK: - What If Card

    // MARK: - Email Forwarding Callout

    private var emailForwardingCallout: some View {
        NavigationLink(value: "email_forwarding") {
            HStack(spacing: 12) {
                Image(systemName: "envelope.arrow.triangle.branch.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(HavenColors.navy)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text("You have a forwarding email")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy800)
                    Text("Forward quotes, documents, school emails & more to Haven")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.navy.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button {
                hasSeenEmailCallout = true
                Haptics.light()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(6)
                    .background(HavenColors.surface)
                    .clipShape(Circle())
            }
            .offset(x: 4, y: -4)
        }
    }

    private var whatIfCard: some View {
        Button {
            Haptics.light()
            Analytics.track(.scenarioStudioOpened, ["source": "dashboard_what_if_card"])
            showScenarioStudio = true
        } label: {
            HavenCard {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(
                                colors: [HavenColors.navy.opacity(0.08), HavenColors.navy.opacity(0.15)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scenario Planning")
                            .font(HavenTypography.fraunces(size: 18, weight: 700))
                            .foregroundStyle(HavenColors.navy800)
                        Text("Explore what-if questions with your real data — estate, taxes, home, wealth")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Make it Yours (personal quiz hero for invitees)

    private var makeItYoursHeroCard: some View {
        Button {
            Haptics.medium()
            showPersonalQuiz = true
        } label: {
            HavenCard {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HavenColors.navy)
                        .frame(width: 44, height: 44)
                        .background(HavenColors.creamLight)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MAKE IT YOURS")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.2)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("Add your profile (optional)")
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("5 quick questions about you and your vehicles. Takes about 2 minutes.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }

                HStack(spacing: HavenTheme.spacing8) {
                    HavenButton(title: "Start", action: {
                        Haptics.medium()
                        showPersonalQuiz = true
                    })
                    HavenButton(
                        title: "Not now",
                        action: {
                            UserDefaults.standard.set(false, forKey: PendingInviteKeys.needsPersonalQuiz)
                            needsPersonalQuiz = false
                        },
                        style: .secondary
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Getting Started

    @ViewBuilder
    private var gettingStartedCard: some View {
        // Phase 50 (sub-phase B first-login): `showGettingStarted` collapses
        // to (!hasProperty || !hasCompletedAnyQuiz), so this view only ever
        // renders when the user is on Day 0 OR mid-onboarding without a
        // completed quiz. The Quiz hero is the singular CTA in that state —
        // the legacy "Upload your first document" / "Ask Alfred" branches
        // are now handled post-quiz by `VendorScheduleStrip` (which absorbs
        // Step 2) and the Alfred tab toolbar (which absorbs Step 3).
        if viewModel.hasProperty {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(spacing: 8) {
                    Text("GETTING STARTED")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                }
                houseQuizHeroCardStack
            }
        } else {
            // Full getting started checklist (no property yet)
            HavenCard {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { gettingStartedExpanded.toggle() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.wave.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(HavenColors.navy700)
                            Text("Getting Started")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.navy800)

                            let completed = [viewModel.hasProperty, viewModel.hasDocuments, viewModel.hasUsedAlfred].filter { $0 }.count
                            Text("\(completed)/3")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(HavenColors.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(HavenColors.beige200)
                                .clipShape(Capsule())

                            Spacer()

                            Image(systemName: gettingStartedExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if gettingStartedExpanded {
                        gettingStartedRow(step: 1, title: "Add your home", subtitle: "We'll set up maintenance tracking automatically", icon: "house.fill", done: viewModel.hasProperty, action: { showAddProperty = true })
                        gettingStartedRow(step: 2, title: "Upload your first document", subtitle: "A deed, insurance policy, or will — Alfred analyzes it instantly", icon: "doc.badge.plus", done: viewModel.hasDocuments, action: { showUploadDocument = true })
                        gettingStartedRow(step: 3, title: "Ask Alfred a question", subtitle: "Try \"What documents am I missing?\"", icon: "sparkles", done: viewModel.hasUsedAlfred, action: { NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 3]) })
                    } else {
                        gettingStartedRow(step: 1, title: "Add your home", subtitle: "We'll set up maintenance tracking automatically", icon: "house.fill", done: false, action: { showAddProperty = true })
                    }
                }
            }
        }
    }

    /// One House Quiz hero card per property that hasn't completed the quiz.
    /// Cards stack vertically; each property's progress is tracked independently.
    @ViewBuilder
    private var houseQuizHeroCardStack: some View {
        let incomplete = viewModel.properties.filter { property in
            (property.houseQuizState?.completedAt) == nil
        }
        ForEach(incomplete) { property in
            houseQuizHeroCard(for: property)
        }
    }

    private func houseQuizHeroCard(for property: PropertyRow) -> some View {
        let state = property.houseQuizState ?? HouseQuizState()
        let total = HouseQuizQuestionLibrary.allQuestions.count
        let answered = state.answers.count
        let saved = state.savedForLater.count
        let completion = total > 0 ? Double(answered) / Double(total) : 0
        let isResume = answered > 0
        let title = "Start Quiz for \(property.name)"
        let progressLabel = isResume
            ? "\(answered) of \(total) done · \(saved) saved for later"
            : "\(total) quick questions, about 5 minutes."

        return HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: 8) {
                    AlfredLogoView(size: 24)
                    Text(title)
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.navy800)
                        .lineLimit(2)
                }

                Text("Help us tailor your maintenance plan, systems, and recommendations to your home.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                Text(progressLabel)
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textTertiary)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HavenColors.beige200)
                        .frame(height: 6)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(HavenColors.action)
                            .frame(width: max(0, geo.size.width * completion), height: 6)
                    }
                    .frame(height: 6)
                }

                HavenButton(title: isResume ? "Continue Quiz" : "Start Quiz") {
                    activeQuizProperty = property
                }

                Button("Skip for now") {
                    showQuizSkipDialog = true
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textTertiary)
                .frame(maxWidth: .infinity)
            }
            // Apr 7, 2026 (build 80): make the entire card body tappable,
            // not just the "Start Quiz" / "Continue Quiz" button. The
            // inner HavenButton and "Skip for now" Button still consume
            // their own taps (SwiftUI suppresses the outer tap gesture
            // when an inner Button receives it), so the explicit CTAs
            // keep their distinct touch targets — this just adds the
            // empty card space + title + progress bar as additional
            // tap surface.
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.light()
                activeQuizProperty = property
            }
        }
        .havenShadow()
    }

    // Phase 50 (sub-phase B first-login): `gettingStartedHeader` was used by
    // the legacy "Step 1/2/3" Quiz hero + Alfred prompt branches and the
    // expanded checklist. With the simplified two-state model (Quiz hero
    // when hasProperty, full checklist when !hasProperty) those branches
    // are gone, and the Quiz section header is now inline in
    // `gettingStartedCard`. The expanded checklist still has its own
    // header rendered inline below.

    private func gettingStartedRow(step: Int, title: String, subtitle: String, icon: String, done: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.light()
            Analytics.track(.dashboardGettingStartedItemTapped, ["step": step, "title": title])
            action()
        }) {
            HStack(spacing: 12) {
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(HavenColors.success)
                } else {
                    Text("\(step)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(HavenColors.navy800))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(done ? HavenColors.textTertiary : HavenColors.textPrimary)
                        .strikethrough(done)
                    Text(subtitle)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Spacer()

                if !done {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(done)
    }

    // MARK: - Expecting Card

    private func expectingCard(member: FamilyMemberRow) -> some View {
        let progress = viewModel.checklistProgress(for: member)
        let progressPct = progress.total > 0 ? Double(progress.completed) / Double(progress.total) : 0

        return VStack(spacing: 0) {
            HStack(spacing: 14) {
                FamilyAvatarView(member: member, size: 48, showName: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Preparing for \(member.firstName)")
                        .font(HavenTypography.title3)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let expectedDate = member.expectedDate {
                            let f = DateFormatter()
                            let _ = f.dateFormat = "yyyy-MM-dd"
                            if let date = f.date(from: expectedDate) {
                                let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
                                if days > 0 {
                                    Text("\(days) days to go")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(Color.white.opacity(0.8))
                                } else if days == 0 {
                                    Text("Due today!")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(Color.white.opacity(0.9))
                                } else {
                                    Text("Born \(abs(days)) days ago")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(Color.white.opacity(0.8))
                                }
                            }
                        }

                        Text("\(progress.completed)/\(progress.total) ready")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }

                Spacer()

                // Mini progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: progressPct)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progressPct * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(HavenTheme.spacing16)
        }
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        AvatarColor.rose.color,
                        AvatarColor.rose.color.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .offset(x: 50, y: -20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    // MARK: - Smart Recommendations

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("RECOMMENDED")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.id) { index, rec in
                    Button {
                        Haptics.light()
                        Analytics.track(.dashboardRecommendationTapped, ["recommendation_id": rec.id, "title": rec.title])
                        handleRecommendationAction(rec.action)
                    } label: {
                        HStack(spacing: HavenTheme.spacing12) {
                            Image(systemName: rec.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(rec.iconColor)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.title)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Text(rec.subtitle)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Button {
                                Haptics.light()
                                Analytics.track(.dashboardRecommendationDismissed, ["recommendation_id": rec.id])
                                withAnimation { viewModel.dismissRecommendation(rec.id) }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(HavenColors.textTertiary)
                                    .padding(6)
                            }
                            .buttonStyle(.plain)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, HavenTheme.spacing12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < viewModel.recommendations.count - 1 {
                        Divider()
                            .padding(.leading, 48)
                            .overlay(HavenColors.beige200)
                    }
                }
            }
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()
        }
    }

    // (Enrichment cards section removed — replaced by the House Quiz hero card.)

    // MARK: - Activity Tap Handler

    private func handleActivityTap(_ event: RecentActivityEvent) {
        switch event.eventType {
        case .taskCompleted:
            if let id = event.entityId,
               let task = viewModel.allUpcomingTasks.first(where: { $0.id == id })
                  ?? viewModel.overdueMaintenanceTasks.first(where: { $0.id == id })
                  ?? viewModel.recentlyCompletedTasks.first(where: { $0.id == id }) {
                selectedDashboardTask = task
            }
        case .documentProcessed, .invoiceProcessed, .estateDocumentExtracted:
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
        case .vendorLinked, .systemAdded, .propertyAdded, .projectCreated:
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
        case .vehicleAdded:
            if event.entityId != nil {
                navigationPath.append("vehicles")
            } else {
                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
            }
        case .familyMemberJoined:
            if let id = event.entityId,
               let member = viewModel.familyMembers.first(where: { $0.id == id }) {
                selectedMemberForProfile = member
            }
        case .inboxItemReceived:
            if let id = event.entityId {
                navigationPath.append("inbox_item_\(id.uuidString)")
            } else {
                navigationPath.append("inbox")
            }
        case .recallDetected:
            navigationPath.append("vehicles")
        case .scenarioRun:
            NotificationCenter.default.post(name: .openScenarioStudio, object: nil)
        case .gapAnalysisRun:
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
        }
    }

    private func handleRecommendationAction(_ action: RecommendationAction) {
        switch action {
        case .navigate(let tab):
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": tab])
        case .navigateToProperty(let section):
            // Switch to Property tab and tell PropertyDetailView which section to open
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .navigateToPropertySection, object: nil, userInfo: ["section": section])
            }
        case .addProperty:
            showAddProperty = true
        case .uploadDocument:
            showUploadDocument = true
        case .addVendor:
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
        case .addFamilyMember:
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
        case .runGapAnalysis:
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
        case .setReminders:
            showSettings = true
        case .runScenario:
            showScenarioStudio = true
        case .openSettings:
            showSettings = true
        }
    }

    // MARK: - Phase 19l: Re-fire delegation sheet for new contractors

    /// Compute delegation candidates filtered to a single newly-added
    /// contractor. Mirrors the post-quiz loader in HouseQuizView but only
    /// considers tasks whose system category matches the new vendor — that
    /// way the sheet only fires when there's actually something to delegate.
    private func loadDelegationCandidatesForContractor(_ contractorId: UUID) async {
        let db = DatabaseService.shared
        do {
            let contractors = try await db.fetchContractors()
            guard let contractor = contractors.first(where: { $0.id == contractorId }) else { return }

            // Walk every property the household owns so a contractor added
            // for one home gets considered against tasks on every home.
            let properties = try await db.fetchProperties()
            var matchingTasks: [MaintenanceTaskDBRow] = []

            for property in properties {
                let tasks = (try? await db.fetchMaintenanceTasks(propertyId: property.id)) ?? []
                let systems = (try? await db.fetchHomeSystems(propertyId: property.id)) ?? []
                let systemsById = Dictionary(uniqueKeysWithValues: systems.map { ($0.id, $0) })

                for task in tasks {
                    guard task.vehicleId == nil else { continue }
                    guard task.assignmentType?.lowercased() == "either" else { continue }
                    guard let systemId = task.systemId, let system = systemsById[systemId] else { continue }
                    let category = system.category.lowercased()
                    let matchesCategory = (contractor.category?.lowercased() == category)
                        || (contractor.specialties?.contains(where: { $0.lowercased() == category }) ?? false)
                    if matchesCategory {
                        matchingTasks.append(task)
                    }
                }
            }

            guard !matchingTasks.isEmpty else { return }

            await MainActor.run {
                self.dashboardDelegationCandidates = [
                    VendorDelegationCandidate(contractor: contractor, tasks: matchingTasks)
                ]
                // Brief delay so the contractor add sheet has time to dismiss
                // before the delegation sheet slides up over the dashboard.
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    showDashboardDelegationSheet = true
                }
            }
        } catch {
            print("[Phase19l] Failed to load delegation candidates for new contractor: \(error)")
        }
    }

    // MARK: - Merge Request Banner

    private func mergeRequestBanner(_ request: [String: Any]) -> some View {
        let requesterName = request["requester_name"] as? String ?? "Someone"
        let householdName = request["target_household_name"] as? String ?? "their household"
        let requestId = request["id"] as? String ?? ""

        return HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(HavenColors.navy700)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(requesterName) wants to share a household")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Join \"\(householdName)\" to share documents, properties, and maintenance.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await acceptMerge(requestId: requestId) }
                    } label: {
                        Text(isAcceptingMerge ? "Joining..." : "Accept & Join")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.textOnNavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(HavenColors.navy)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .disabled(isAcceptingMerge)

                    Button {
                        Task { await declineMerge(requestId: requestId) }
                    } label: {
                        Text("Decline")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(HavenColors.beige200)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                }
            }
        }
    }

    private func acceptMerge(requestId: String) async {
        isAcceptingMerge = true
        do {
            let data = try await HavenSupabase.mergeHouseholds(
                action: "preview_merge",
                mergeRequestId: requestId
            )

            let decoder = JSONDecoder()
            let previewResponse = try decoder.decode(MergePreviewResponse.self, from: data)
            mergePreviewResponse = previewResponse
            showMergeResolution = true
        } catch {
            print("[Dashboard] Preview merge failed: \(error)")
            Haptics.error()
        }
        isAcceptingMerge = false
    }

    private func declineMerge(requestId: String) async {
        do {
            _ = try await HavenSupabase.mergeHouseholds(
                action: "decline_merge",
                mergeRequestId: requestId
            )
            pendingMergeRequest = nil
        } catch {
            print("[Dashboard] Decline failed: \(error)")
        }
    }

    // MARK: - Incomplete Address Banner

    private func incompleteAddressBanner(_ property: PropertyRow) -> some View {
        Button {
            Haptics.light()
            showAddressCompletion = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.warning)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Complete your address")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("\(property.name) needs a street address for property data and maintenance tracking.")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.warning.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.warning.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAddressCompletion) {
            NavigationStack {
                AddressCompletionSheet(property: property, onComplete: {
                    Task { await viewModel.refresh() }
                })
            }
        }
    }

    // MARK: - Compact Estate Scorecard

    private var compactEstateScorecard: some View {
        let level = vaultViewModel.currentLevel
        let progress = vaultViewModel.levelProgress
        let levelColor: Color = level.id == 1 ? HavenColors.beige300 : level.color.color

        return HStack(spacing: 12) {
            Image(systemName: level.icon)
                .font(.system(size: 18))
                .foregroundStyle(levelColor)
                .frame(width: 36, height: 36)
                .background(levelColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(level.name)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textOnNavy)
                if let next = vaultViewModel.nextLevel {
                    Text("\(Int(progress * 100))% to \(next.name)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.beige300)
                } else {
                    Text("Max Level!")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.beige300)
                }
            }

            Spacer()

            // Compact progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 6)
                    Capsule()
                        .fill(levelColor)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(width: 60, height: 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(HavenColors.beige300)
        }
        .padding(.horizontal, HavenTheme.spacing16)
        .padding(.vertical, 14)
        .background(HavenColors.navy)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    // MARK: - Compact Scenario Card

    private var compactScenarioCard: some View {
        Button {
            Haptics.light()
            Analytics.track(.scenarioStudioOpened, ["source": "dashboard_compact_card"])
            showScenarioStudio = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 32, height: 32)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Scenario Planning")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    if viewModel.documentCount < 3 {
                        Text("Upload more documents to unlock simulations")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    } else {
                        Text("Explore what-if questions with your real data")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.horizontal, HavenTheme.spacing16)
            .padding(.vertical, 12)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.beige200, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Security Trust Badge

    private var securityBadge: some View {
        Button {
            Analytics.track(.dashboardSecurityTapped, ["source": "trust_badge"])
            navigationPath.append("security")
        } label: {
            HStack(spacing: HavenTheme.spacing8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.navy700)

                Text("Your documents are encrypted and protected")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textSecondary)

                Spacer()

                Text("Learn more")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.navy500)
            }
            .padding(.horizontal, HavenTheme.spacing16)
            .padding(.vertical, 12)
            .background(HavenColors.creamLight)
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}

import SwiftUI

/// V5 Maintenance screen — the focused six-section narrative that lives
/// behind the title-switcher in `TasksHubView`. Replaces the embedded
/// `MaintenanceHubView` (Phase 66) for the Tasks tab. PropertyDetailView's
/// property-scoped push of `MaintenanceHubView(filterPropertyId:)` is
/// untouched.
///
/// Sections (top-down):
///   1. HeaderSwitcher (title + mode chevron + "+" button)
///   2. YearRibbon (Spring/Summer/Fall/Winter — tap scopes the screen)
///   3. MiniHero (% covered + 3 stats)
///   4. Needs your decision (salmon-wash rows)
///   5. Active programs (white rows + ON pill)
///   6. Vehicles (white rows + Set up → on shop-less)
///   7. BrowseBand (indigo end-of-feed CTA)
struct MaintenanceTabView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var maintenanceVM = MaintenanceViewModel.shared
    @StateObject private var viewModel = MaintenanceTabViewModel()

    @State private var activeSeason: Season = .current()
    @State private var showAddMenu = false
    @State private var pushTarget: MaintenancePush?
    @State private var pickerForRoutine: RoutineRow?

    /// Phase 70 (Tasks v2): The task currently being scheduled via the
    /// inline QuickSchedulingSheet. Non-nil while the half-detent sheet
    /// is open; set back to nil after the user picks a date or cancels.
    @State private var quickScheduleTask: MaintenanceTaskDBRow?
    /// Phase 70.A1.x: full bundle / task detail sheet. Tapping a bundle
    /// parent card body or a standalone task row presents this sheet
    /// inline — no more deferring to `MaintenanceScheduleView` (the
    /// heavy Phase 56.4 timeline) just to re-tap the same row from
    /// inside that view.
    @State private var detailTask: MaintenanceTaskDBRow?
    /// Phase F3: MaintenanceScheduleView parity — duplicate banner.
    /// `DuplicateDetector` scans routines + tasks for high-confidence
    /// match pairs (same vendor + category family + title similarity);
    /// dismissed pairs are filtered for 30 days. Banner renders above
    /// the season banner; tap presents the queue review sheet.
    @State private var detectedDuplicates: [DuplicateDetector.Match] = []
    @State private var duplicateBannerDismissedThisSession: Bool = false
    @State private var reviewingMatch: DuplicateDetector.Match?
    /// Phase F4: bulk-select mode. Toggled via the Add menu "Select
    /// tasks" action or via long-press on any row. While selectionMode
    /// is true, row taps toggle selection instead of opening detail.
    /// Session-only (not persisted) matching MaintenanceScheduleView.
    @State private var selectionMode: Bool = false
    @State private var selectedTaskIds: Set<UUID> = []
    @State private var bulkBusy: Bool = false
    /// Phase G1: source data for the Year-at-a-glance card. Loaded
    /// once on appear + refreshed on .maintenanceTaskChanged. Empty by
    /// default — the card hides itself until data arrives.
    @State private var vendorDocumentsForYear: [DocumentRow] = []
    @State private var serviceRecordsForYear: [ServiceRecordRow] = []
    /// Phase G2: Year overview / Timeline scrub. Opens as a
    /// fullScreenCover so the 18-month linear list reads as a
    /// "different mode" without losing scroll context in the parent.
    @State private var showYearOverview: Bool = false
    /// Phase H: AddMaintenanceTaskSheet presented inline from the Add
    /// menu. Replaces the old "punt to MaintenanceScheduleView and
    /// open from its toolbar" path.
    @State private var showAddTaskSheet: Bool = false

    /// Phase 70 (Tasks v2): Task id whose row should pulse a salmon
    /// highlight ring after a deep-link arrival (`.openMaintenanceTask`).
    /// Cleared automatically ~1.5s later by `handleDeepLink`.
    @State private var highlightedTaskId: UUID?

    /// Phase 70.A1 follow-on F4: in-view confirmation pill that appears
    /// at the top of the screen ~3s after a QuickSchedulingSheet commit.
    /// Independent of layout so it works whether the just-scheduled task
    /// stays in the season feed or jumps to a different month/season.
    /// Tap routes through `detailTask` so the user can verify the write
    /// landed where they expect.
    @State private var lastScheduledToast: ScheduledToast?

    /// Phase 70.A1 follow-on G3: presents the Completed view sheet.
    /// Reached from the new clock-counterclockwise icon in HeaderSwitcher.
    @State private var showCompletedSheet: Bool = false

    /// Phase 70.A1 follow-on I3: undo toast for accidental swipe gestures.
    /// Auto-dismisses after 5s. Tap "Undo" calls the matching undo method
    /// on MaintenanceViewModel to reverse the archive / completion.
    @State private var lastSwipeToast: SwipeToast?

    // Phase 70.A1.x removed the full-year mode state — the season feed
    // is always scoped to one season tile, and the new "Active Routines
    // This Season" card surfaces the routine density that the old
    // full-year toggle was used to discover.

    /// Caller passes a closure so the title-switcher can swap modes
    /// without owning navigation state.
    let onSwitchMode: () -> Void

    private var currentSeason: Season { Season.current() }

    private var householdId: UUID? {
        appState.primaryProperty?.householdId ?? maintenanceVM.properties.first?.householdId
    }

    private var propertyId: UUID? {
        appState.primaryProperty?.id ?? maintenanceVM.properties.first?.id
    }

    private var isScopedToYear: Bool {
        activeSeason == currentSeason
    }

    private var scopeLabel: String {
        isScopedToYear ? "this year" : "this \(activeSeason.displayName.lowercased())"
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HeaderSwitcher(
                    title: "Maintenance",
                    onSwitchMode: onSwitchMode,
                    onAdd: { showAddMenu = true },
                    selectionMode: selectionMode,
                    selectionCount: selectedTaskIds.count,
                    onDoneSelection: {
                        withAnimation(HavenTheme.animationStandard) {
                            selectionMode = false
                            selectedTaskIds.removeAll()
                        }
                    },
                    // Phase 70.A1 follow-on G3 — Completed view entry.
                    // Only on Maintenance mode; HandymanTabView has its
                    // own visit-history surface.
                    onShowCompleted: {
                        showCompletedSheet = true
                    }
                )

                YearRibbon(
                    activeSeason: $activeSeason,
                    summaries: viewModel.seasonSummaries(activeSeason: currentSeason),
                    currentSeason: currentSeason,
                    onTap: { season in
                        // Phase 70 (Tasks v2): Tap = filter the screen
                        // to that season. The binding update already
                        // re-renders the feed via `activeFeed`.
                        // Phase F1: clear stats filter on season swap
                        // so the user isn't trapped in "Overdue" when
                        // jumping forward to a different season.
                        withAnimation(HavenTheme.animationStandard) {
                            activeSeason = season
                            viewModel.activeStatsFilter = nil
                        }
                        Haptics.selection()
                        Analytics.track(.tasksV2SeasonTapped, [
                            "season": season.rawValue,
                            "source": "ribbon"
                        ])
                    }
                )

                miniHeroSection

                // Phase 70.A1 follow-on F3 — Up Next 14-day strip.
                // Ignores season scope so scheduled work that crosses
                // a season boundary (book "Next week" from Spring → row
                // lands in June → Summer tile, but UP NEXT still shows
                // it) never disappears.
                upNextSection

                // Phase 70 (Tasks v2): unified view sections.
                //
                // Replaces the prior decisionsSection / programsSection /
                // chezHandlingSection trio. Single source of truth via
                // `viewModel.seasonFeed(activeSeason)` so the YearRibbon
                // count == the rendered row count. The old section
                // helpers are kept below for safety + rollback.
                duplicateBannerSection

                yearAtAGlanceSection

                seasonScopeBannerSection

                statsFilterStripSection

                needsAttentionSection

                flexibleTasksSection

                thisSeasonTasksSection

                activeRoutinesSeasonCard

                combinedProgramsSection

                vehiclesSection

                BrowseBand(
                    title: "Browse additional services",
                    subtitle: "\(viewModel.browseCatalogCount) seasonal & on-demand services"
                ) {
                    pushTarget = .recommendedServices
                }
                .padding(.horizontal, TasksV5.pageMargin)
                .padding(.bottom, TasksV5.bottomTabInset)
            }
        }
        .background(HavenColors.background)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            bulkActionBar
        }
        // Phase 70.A1 follow-on F4 — toast pill anchored to the top safe
        // area. Auto-dismisses after 3s; tapping routes through detailTask
        // so the homeowner can verify the write landed.
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                if let toast = lastScheduledToast {
                    scheduledConfirmationToast(toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if let toast = lastSwipeToast {
                    swipeUndoToast(toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.top, 8)
        }
        .animation(HavenTheme.animationStandard, value: lastScheduledToast)
        .animation(HavenTheme.animationStandard, value: lastSwipeToast)
        .task {
            if let householdId {
                await viewModel.load(householdId: householdId)
            }
            await maintenanceVM.loadTasks()
            await loadDuplicates()
            await loadYearStats()

            // Phase 70.A1 (Summer/Winter library expansion v3): seed
            // the 8 new templates onto existing households once. The
            // AppState-level migration was firing too early (before
            // primaryProperty resolved) so the inflated user-facing
            // chip counts never updated. Moving the trigger to the
            // Tasks tab's `.task` block guarantees the household
            // context is loaded — the user is literally looking at
            // the Maintenance tab — so the reconciler has everything
            // it needs.
            //
            // Gate: UserDefaults `hasSeededPhase70A1LibraryExpansion_v3`.
            // Idempotent — reconciler skips templates already on file.
            if let householdId,
               !UserDefaults.standard.bool(forKey: "hasSeededPhase70A1LibraryExpansion_v3") {
                _ = await MaintenanceTaskReconciler.reconcileAllForHousehold(householdId: householdId)
                UserDefaults.standard.set(true, forKey: "hasSeededPhase70A1LibraryExpansion_v3")
                await maintenanceVM.loadTasks()
                NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            }
        }
        .refreshable {
            if let householdId { await viewModel.load(householdId: householdId) }
            await maintenanceVM.loadTasks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .routineChanged)) { _ in
            Task {
                if let householdId { await viewModel.load(householdId: householdId) }
                await loadDuplicates()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task {
                await maintenanceVM.loadTasks()
                await loadDuplicates()
                await loadYearStats()
            }
        }
        // Phase 70 (Tasks v2) — deep-link contract. Push handlers, inbox
        // action menus, and activity-feed "view task" links all post this
        // notification. The handler applies property + season scope and
        // briefly highlights the matching row.
        .onReceive(NotificationCenter.default.publisher(for: .openMaintenanceTask)) { notification in
            handleDeepLink(notification)
        }
        // Phase H — Dashboard's "View full schedule" posts this after
        // switching to the Tasks tab. Auto-opens the Year overview /
        // Timeline scrub fullScreenCover, replacing the old route into
        // MaintenanceScheduleView's Calendar layout.
        .onReceive(NotificationCenter.default.publisher(for: .openTasksYearOverview)) { _ in
            showYearOverview = true
        }
        // Phase 70 (Tasks v2) — inline 1-tap scheduler. Presented when
        // the homeowner taps the "Book it" CTA on a bundle parent card.
        // Half-detent so the user keeps scroll context behind it.
        .sheet(item: $quickScheduleTask) { task in
            QuickSchedulingSheet(
                taskTitle: task.title,
                vendorName: contractorFor(task: task).map { MaintenanceViewModel.vendorDisplayName($0.companyName) },
                onSchedule: { date in
                    Task {
                        await commitQuickSchedule(task: task, date: date)
                    }
                    quickScheduleTask = nil
                },
                onCancel: {
                    quickScheduleTask = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // Phase H — "Add a one-off task" presents AddMaintenanceTaskSheet
        // inline. Replaces the old route through MaintenanceScheduleView's
        // toolbar; same props pulled from maintenanceVM directly.
        .sheet(isPresented: $showAddTaskSheet) {
            AddMaintenanceTaskSheet(
                properties: maintenanceVM.properties,
                systems: maintenanceVM.systems,
                vehicles: maintenanceVM.vehicles,
                contractors: maintenanceVM.contractors,
                householdUsers: maintenanceVM.users,
                householdFamilyMembers: maintenanceVM.familyMembers,
                viewModel: maintenanceVM
            )
        }
        // Phase G2 — Year overview / Timeline scrub. fullScreenCover
        // so the 18-month list reads as a distinct mode. Tap any row
        // → swap to detailTask sheet (existing path); tap a routine
        // occurrence → push RoutineDetailView via pushTarget. Done
        // button + drag indicator dismisses.
        .fullScreenCover(isPresented: $showYearOverview) {
            TasksTimelineSheet(
                tasks: maintenanceVM.tasks,
                routines: viewModel.routines,
                contractor: { id in
                    guard let id else { return nil }
                    return maintenanceVM.contractors.first { $0.id == id }
                },
                childrenFor: { task in childrenFor(task: task) },
                isChezOwned: { $0.isChezOwned },
                onTapTask: { task in
                    showYearOverview = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        detailTask = task
                    }
                },
                onTapRoutine: { routine in
                    showYearOverview = false
                    if let householdId {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            pushTarget = .routineDetail(routine, householdId)
                        }
                    }
                }
            )
        }
        // Phase F3: duplicate-resolution sheet. Parent-driven lifecycle
        // (see MaintenanceDuplicateSheet docs): after each `onResolve`
        // we swap to the next match in the queue, or set nil to
        // dismiss. Matches Apple Photos' Review Duplicates pagination.
        .sheet(item: $reviewingMatch) { match in
            MaintenanceDuplicateSheet(
                match: match,
                currentIndex: detectedDuplicates.firstIndex(where: { $0.id == match.id }) ?? 0,
                totalCount: detectedDuplicates.count,
                onResolve: { resolution in
                    await handleDuplicateResolution(match: match, resolution: resolution)
                },
                onCancel: {
                    reviewingMatch = nil
                }
            )
        }
        // Phase 70.A1.x: full bundle/task detail sheet. Replaces the
        // earlier "punt to MaintenanceScheduleView and re-tap" path,
        // which was slow (full timeline + duplicate-detection on
        // appear) AND awful UX (two taps to see the bundle's coord
        // surface). MaintenanceTaskDetailSheet already handles bundle
        // parents (custom subitems / vendor reframing / scheduling /
        // snooze / complete / Chez delegation).
        .sheet(item: $detailTask) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(
                    task: task,
                    onTaskCompleted: {
                        detailTask = nil
                    },
                    onDeleteTask: {
                        // Friend feedback (May 2026): callback used to only
                        // dismiss the sheet — the DB delete never fired.
                        // Capture the id before dismiss so the Task closure
                        // survives the sheet teardown. Analytics already
                        // fires inside MaintenanceTaskDetailSheet.actionsSection.
                        let taskId = task.id
                        detailTask = nil
                        Task {
                            try? await DatabaseService.shared.deleteMaintenanceTask(id: taskId)
                            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                        }
                    }
                )
            }
        }
        // Phase 70.A1 follow-on G3 — Completed sheet.
        .sheet(isPresented: $showCompletedSheet) {
            if let householdId {
                CompletedTasksSheet(householdId: householdId)
            }
        }
        .confirmationDialog("Add", isPresented: $showAddMenu, titleVisibility: .hidden) {
            Button("Add a routine") { pushTarget = .routinesList }
            Button("Add a one-off task") { showAddTaskSheet = true }
            Button("Browse all services") { pushTarget = .recommendedServices }
            // Phase F4: bulk-select entry. Tapping enters selection mode
            // with no rows selected. User taps rows to select then chooses
            // a bulk action from the bottom action bar.
            Button("Select tasks") {
                withAnimation(HavenTheme.animationStandard) {
                    selectionMode = true
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .navigationDestination(item: $pushTarget) { target in
            destination(for: target)
        }
        .sheet(item: $pickerForRoutine) { routine in
            DecisionVendorPicker(routine: routine) {
                pickerForRoutine = nil
                Task { if let householdId { await viewModel.load(householdId: householdId) } }
            }
        }
    }

    // MARK: - Sections

    private var miniHeroSection: some View {
        IndigoGradientCard(variant: .hero) {
            MiniHeroContent(
                scopeLabel: scopeLabel,
                coveredCount: viewModel.coveredCount(for: activeSeason, currentSeason: currentSeason),
                totalCount: viewModel.totalCount(for: activeSeason, currentSeason: currentSeason),
                programCount: viewModel.activePrograms().count,
                decisionCount: viewModel.pendingDecisions().count,
                bundleReadyCount: viewModel.bundleReadyCount
            )
        }
        .padding(.horizontal, TasksV5.pageMargin)
        .padding(.bottom, 18)
    }

    @ViewBuilder
    private var decisionsSection: some View {
        let decisions = viewModel.pendingDecisions(scopedTo: scopedSeasonOrNil)
        if !decisions.isEmpty {
            SectionLabel(
                eyebrow: "Needs your decision",
                sub: viewModel.dueLabel(),
                action: decisions.count > 3 ? .init(title: "See all", perform: {
                    showYearOverview = true
                }) : nil
            )
            .padding(.bottom, TasksV5.sectionLabelGap)

            VStack(spacing: TasksV5.rowGap) {
                ForEach(decisions.prefix(3)) { routine in
                    DecisionRow(
                        icon: routine.resolvedIcon,
                        title: routine.presentationLabel,
                        meta: viewModel.decisionMeta(for: routine),
                        ctaTitle: "Choose vendor"
                    ) {
                        pickerForRoutine = routine
                    }
                }
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, TasksV5.sectionGap)
        }
    }

    @ViewBuilder
    private var programsSection: some View {
        let programs = viewModel.activePrograms(scopedTo: scopedSeasonOrNil)
        if programs.isEmpty {
            SectionLabel(
                eyebrow: "Active programs",
                sub: "On autopilot"
            )
            .padding(.bottom, TasksV5.sectionLabelGap)

            emptyProgramsCard
                .padding(.horizontal, TasksV5.pageMargin)
                .padding(.bottom, TasksV5.sectionGap)
        } else {
            SectionLabel(
                eyebrow: "Active programs",
                sub: "On autopilot",
                action: programs.count > 4 ? .init(title: "See all", perform: {
                    pushTarget = .routinesList
                }) : nil
            )
            .padding(.bottom, TasksV5.sectionLabelGap)

            VStack(spacing: TasksV5.rowGap) {
                ForEach(programs.prefix(4)) { routine in
                    ProgramRow(
                        icon: routine.resolvedIcon,
                        name: routine.presentationLabel,
                        nextEventLabel: viewModel.nextEventLabel(for: routine),
                        chezOwned: routine.chezOwned
                    ) {
                        if let householdId {
                            pushTarget = .routineDetail(routine, householdId)
                        }
                    }
                }
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, TasksV5.sectionGap)
        }
    }

    /// Phase 85 — Chez handling section. Renders below "Active programs"
    /// when any chez_owned routines exist. Visually distinct from the
    /// homeowner's own programs: passive observational tone, salmon
    /// accent, "Chez is handling" subtitle. Tapping still opens the
    /// routine detail so the homeowner can revoke or review.
    @ViewBuilder
    private var chezHandlingSection: some View {
        let chezPrograms = viewModel.chezHandlingPrograms(scopedTo: scopedSeasonOrNil)
        if !chezPrograms.isEmpty {
            SectionLabel(
                eyebrow: "Chez is handling",
                sub: "On autopilot · We've got it",
                action: chezPrograms.count > 4 ? .init(title: "See all", perform: {
                    pushTarget = .routinesList
                }) : nil
            )
            .padding(.bottom, TasksV5.sectionLabelGap)

            VStack(spacing: TasksV5.rowGap) {
                ForEach(chezPrograms.prefix(4)) { routine in
                    ProgramRow(
                        icon: routine.resolvedIcon,
                        name: routine.presentationLabel,
                        nextEventLabel: viewModel.nextEventLabel(for: routine),
                        chezOwned: true
                    ) {
                        if let householdId {
                            pushTarget = .routineDetail(routine, householdId)
                        }
                    }
                }
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, TasksV5.sectionGap)
        }
    }

    @ViewBuilder
    private var vehiclesSection: some View {
        let vehicles = maintenanceVM.vehicles
        if !vehicles.isEmpty {
            SectionLabel(eyebrow: "Vehicles")
                .padding(.bottom, TasksV5.sectionLabelGap)

            VStack(spacing: TasksV5.rowGap) {
                ForEach(vehicles) { vehicle in
                    VehicleProgramRow(
                        name: vehicleDisplayName(vehicle),
                        meta: viewModel.vehicleMeta(for: vehicle),
                        needsSetup: viewModel.vehicleNeedsShop(vehicle)
                    ) {
                        // Round C Wave C-2 REDO finding: routing through
                        // pushTarget = .vehicle here briefly rendered the
                        // EmptyView() destination as a blank white screen
                        // before the .onAppear handler fired the
                        // switchToTab + navigateToVehicle notifications.
                        // Post the notifications directly from the tap
                        // closure so the navigation is immediate.
                        NotificationCenter.default.post(
                            name: .navigateToVehicle,
                            object: nil,
                            userInfo: ["vehicleId": vehicle.id.uuidString]
                        )
                        NotificationCenter.default.post(
                            name: .switchToTab,
                            object: nil,
                            userInfo: ["tab": 1]
                        )
                    }
                }
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, 20)
        }
    }

    private var emptyProgramsCard: some View {
        Button {
            pushTarget = .routinesList
        } label: {
            IndigoGradientCard(variant: .band) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(Color.white.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(HavenColors.actionLight)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set up your first program")
                            .font(HavenTypography.fraunces(size: 16, weight: 600))
                            .foregroundStyle(.white)
                        Text("Recurring services on autopilot.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Phase 70 (Tasks v2) — new section helpers

    /// Cached feed for the active season. Computed once per body re-render.
    /// Phase 70 single source of truth for everything below MiniHero.
    /// All Phase 70 sections read from this so the user can't see a count
    /// (ribbon) that disagrees with the rows (sections).
    ///
    /// Phase 70.A1.x: full-year aggregation removed — the season feed is
    /// always scoped to one season tile. "Active Routines This Season"
    /// card surfaces the routine density that the old full-year toggle
    /// was used to discover.
    private var activeFeed: SeasonFeed {
        viewModel.seasonFeed(activeSeason)
    }

    /// SeasonScopeBanner — the 44pt pill below MiniHero that names the
    /// active scope + exposes search. Full-year toggle removed in 70.A1.x.
    /// Phase G1: annual coordination rollup card between the duplicate
    /// banner and the season scope banner. Auto-hides on a fresh
    /// install where there's nothing tracked yet (no service records,
    /// no upcoming visits) so Day-0 doesn't read as an empty "0
    /// visits" card.
    @ViewBuilder
    private var yearAtAGlanceSection: some View {
        let summary = yearSummary
        TasksV2YearSummaryCard(
            yearVisitCount: summary.yearVisitCount,
            yearSpendDollars: summary.yearSpend,
            next30VisitCount: summary.next30VisitCount,
            next30EstimateDollars: summary.next30Estimate,
            onTap: {
                // Future: open a focused breakdown sheet. Defer until
                // there's enough data to make the breakdown valuable —
                // for now the tap is a discoverability hint.
                Analytics.track(.tasksV2YearGlanceTapped, [
                    "year_visits": summary.yearVisitCount,
                    "next_30_visits": summary.next30VisitCount
                ])
            }
        )
        .padding(.horizontal, TasksV5.pageMargin)
        .padding(.bottom, TasksV5.sectionGap)
    }

    /// Phase F3: surfaces detected duplicates (same vendor + category
    /// family + similar title) at the top of Tasks v2. Apple Contacts
    /// "Duplicates Found" pattern. Banner is session-dismissible — the
    /// underlying data persists for 30 days via DuplicateDismissalStore
    /// when the user explicitly chose "Keep both" on a match.
    @ViewBuilder
    private var duplicateBannerSection: some View {
        if !detectedDuplicates.isEmpty, !duplicateBannerDismissedThisSession {
            DuplicateReviewBanner(
                duplicateCount: detectedDuplicates.count,
                onReview: {
                    reviewingMatch = detectedDuplicates.first
                },
                onDismiss: {
                    withAnimation(HavenTheme.animationStandard) {
                        duplicateBannerDismissedThisSession = true
                    }
                }
            )
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, TasksV5.sectionGap)
        }
    }

    private var seasonScopeBannerSection: some View {
        SeasonScopeBanner(
            season: activeSeason,
            totalItems: activeFeed.totalItems,
            actionItems: activeFeed.actionItems,
            onSearch: {
                // Search overlay ships in 70.A1.10; for now no-op so the
                // affordance is present and discoverable but inert.
                Analytics.track(.tasksV2SearchTapped, [:])
            },
            onYearOverview: {
                showYearOverview = true
                Analytics.track(.tasksV2YearOverviewOpened, [
                    "season": activeSeason.rawValue
                ])
            }
        )
        .padding(.horizontal, TasksV5.pageMargin)
        .padding(.bottom, TasksV5.sectionGap)
    }

    /// Phase F1: time-window filter chips between the banner and the
    /// decisions section. Tap a pill (Overdue / This Week / This Month /
    /// Later) to scope the feed to that window. Tap an active pill or
    /// the Clear chip to reset. Always rendered so the affordance is
    /// discoverable. Counts come from `viewModel.statsFilterCounts(...)`
    /// against the active season + Flexible bucket.
    @ViewBuilder
    private var statsFilterStripSection: some View {
        let counts = viewModel.statsFilterCounts(for: activeSeason)
        let totalAvailable = counts.values.reduce(0, +)
        if totalAvailable > 0 || viewModel.activeStatsFilter != nil {
            StatsFilterStrip(
                active: Binding(
                    get: { viewModel.activeStatsFilter },
                    set: { newValue in
                        withAnimation(HavenTheme.animationStandard) {
                            viewModel.activeStatsFilter = newValue
                        }
                        if let value = newValue {
                            Analytics.track(.tasksV2StatsFilterApplied, [
                                "filter": value.rawValue,
                                "season": activeSeason.rawValue
                            ])
                        }
                    }
                ),
                counts: counts
            )
            .padding(.bottom, TasksV5.sectionGap)
        }
    }

    /// Phase 70 "Needs your attention" — combined section that surfaces
    /// pending-vendor routines AND standalone tasks needing a contractor.
    /// Pre-Phase-70 the latter were invisible (only the routine half
    /// rendered). Capped at 5 visible with a "See all" link to the
    /// full schedule view.
    @ViewBuilder
    private var needsAttentionSection: some View {
        let decisions = activeFeed.decisions
        if !decisions.isEmpty {
            SectionLabel(
                eyebrow: "Needs your attention",
                sub: viewModel.dueLabel(),
                action: decisions.count > 5 ? .init(title: "See all", perform: {
                    showYearOverview = true
                }) : nil
            )
            .padding(.bottom, TasksV5.sectionLabelGap)

            VStack(spacing: TasksV5.rowGap) {
                ForEach(decisions.prefix(5)) { entry in
                    decisionRow(for: entry)
                }
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, TasksV5.sectionGap)
        }
    }

    @ViewBuilder
    private func decisionRow(for entry: DecisionEntry) -> some View {
        switch entry {
        case .routinePendingVendor(let routine):
            DecisionRow(
                icon: routine.resolvedIcon,
                title: routine.presentationLabel,
                meta: viewModel.decisionMeta(for: routine),
                ctaTitle: "Choose vendor",
                // Phase 70.A1.x: Chez pill renders when the underlying
                // routine is `chez_owned`. Today this never fires —
                // pendingDecisions() filters chez_owned routines out
                // ("Chez is making the call, not the homeowner") — but
                // wiring stays in place so future Chez-pending flows
                // surface the badge consistently.
                chezOwned: routine.chezOwned
            ) {
                pickerForRoutine = routine
            }
        case .taskNeedsVendor(let task):
            // Standalone tasks needing a vendor render like a routine
            // decision row visually, but the CTA pushes the existing
            // schedule view so the user can pick a contractor or convert
            // back to personal. Same affordance as the route the v5
            // "needs vendor" tasks already use today.
            DecisionRow(
                icon: decisionIconFor(task: task),
                title: task.title,
                meta: standaloneDecisionMeta(for: task),
                ctaTitle: "Find a pro",
                // Phase 70.A1.x: tasks delegated to Chez via the
                // ChezOwnsToggle expose isChezOwned even before a
                // vendor is assigned. Surface the pill so the
                // homeowner sees the delegation status at a glance.
                chezOwned: task.isChezOwned
            ) {
                // Phase H: open the task detail sheet inline so the
                // homeowner picks a vendor from the existing path
                // (FindLocalVendorSheet / ContractorDirectoryView).
                // Previously this pushed MaintenanceScheduleView which
                // dumped them into a full-tab list — confusing for a
                // single-task action.
                detailTask = task
            }
        }
    }

    /// Phase 70.A1 follow-on F3 — Up Next 14-day horizontal strip. Sits
    /// directly under MiniHero so it's the first thing the homeowner
    /// sees after the season ribbon. Empty when the next 14 days have
    /// nothing in them (newly-onboarded households / DIY-only flows).
    @ViewBuilder
    private var upNextSection: some View {
        let entries = viewModel.upNext()
        if !entries.isEmpty {
            UpNextStripSection(
                entries: entries,
                contractor: { entry in
                    guard let id = entry.assignedContractorId else { return nil }
                    return maintenanceVM.contractors.first { $0.id == id }
                },
                onTap: { entry in
                    let daysOut = Calendar.current.dateComponents(
                        [.day],
                        from: Calendar.current.startOfDay(for: Date()),
                        to: entry.date
                    ).day ?? 0
                    Analytics.track(.tasksV2UpNextRowTapped, [
                        "entry_type": entry.analyticsType,
                        "days_out": String(daysOut)
                    ])
                    if let task = entry.taskRow {
                        detailTask = task
                    } else if let occ = entry.occurrence,
                              let householdId {
                        pushTarget = .routineDetail(occ.routine, householdId)
                    }
                },
                onSeeAll: {
                    showYearOverview = true
                }
            )
            .onAppear {
                Analytics.track(.tasksV2UpNextRendered, [
                    "entry_count": String(entries.count),
                    "days_window": "14"
                ])
            }
        }
    }

    /// Phase 70.A1.x: Flexible-task section. Renders between "Needs
    /// your attention" and "This Season's Tasks" — Flexible items have
    /// no seasonal anchor by design (EV charger inspection, drain
    /// cleaning, electrical panel check), so they belong in their own
    /// list regardless of which season tile is active. Tap → opens
    /// QuickSchedulingSheet, then the task drops into the picked
    /// month's bucket on save.
    @ViewBuilder
    private var flexibleTasksSection: some View {
        let flexible = viewModel.flexibleTasks()
        if !flexible.isEmpty {
            FlexibleTasksSection(
                tasks: flexible,
                contractor: { task in
                    guard let id = task.assignedContractorId else { return nil }
                    return maintenanceVM.contractors.first { $0.id == id }
                },
                onTap: { task in
                    quickScheduleTask = task
                },
                onSeeAll: { showYearOverview = true },
                onComplete: { task in Task { await maintenanceVM.completeTask(task) } },
                onArchive: { task in
                    Analytics.track(.tasksV2SwipedArchive, ["source": "flexible_row"])
                    Task { await maintenanceVM.archiveTask(task) }
                }
            )
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, TasksV5.sectionGap)
        }
    }

    /// Phase 70 "This Season's Tasks" — bundle parents (with children
    /// inline), standalone tasks, and routine occurrences with scheduled
    /// visits this season. Grouped by MonthSubheader. The section the
    /// "I have 30 tasks but only see 5 rows" complaint was pointed at.
    @ViewBuilder
    private var thisSeasonTasksSection: some View {
        let monthSections = activeFeed.monthSections
        if !monthSections.isEmpty {
            SectionLabel(
                eyebrow: "This season",
                sub: "What's coming up"
            )
            .padding(.bottom, TasksV5.sectionLabelGap)

            VStack(spacing: 0) {
                ForEach(monthSections) { monthSection in
                    MonthSubheader(month: monthSection.month)
                    VStack(spacing: TasksV5.rowGap) {
                        ForEach(monthSection.entries) { entry in
                            seasonEntryRow(for: entry)
                        }
                    }
                    .padding(.horizontal, TasksV5.pageMargin)
                }
            }
            .padding(.bottom, TasksV5.sectionGap)
        } else if activeFeed.decisions.isEmpty {
            // Friend feedback (May 2026): when the year-aware filter
            // strips a tile down to zero rows, surface a graceful
            // "wrapped" empty state instead of silently rendering
            // nothing under the previous section's footer.
            seasonWrappedEmptyCard
                .padding(.horizontal, TasksV5.pageMargin)
                .padding(.bottom, TasksV5.sectionGap)
        }
    }

    /// Empty-state for season tiles with no work left for the current
    /// calendar instance. Nudges the homeowner toward the next season's
    /// tile rather than leaving them on a blank screen.
    private var seasonWrappedEmptyCard: some View {
        let nextSeason = activeSeason.next
        return HStack(alignment: .center, spacing: 12) {
            Image(systemName: activeSeason.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(HavenColors.action)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(HavenColors.action.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("\(activeSeason.rawValue) is wrapped")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Nothing left to schedule this season. Tap \(nextSeason.rawValue) →")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer(minLength: 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.creamLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.selection()
            withAnimation(HavenTheme.animationStandard) {
                activeSeason = nextSeason
            }
        }
    }

    @ViewBuilder
    private func seasonEntryRow(for entry: SeasonEntry) -> some View {
        switch entry {
        case .bundle(let task):
            selectionWrap(task: task) {
                BundleParentCard(
                    task: task,
                    contractor: contractorFor(task: task),
                    children: childrenFor(task: task),
                    isChezOwned: task.isChezOwned,
                    isHighlighted: highlightedTaskId == task.id,
                    onTap: {
                        Analytics.track(.tasksV2BundleExpanded, [
                            "bundle_id": task.templateId ?? "",
                            "child_count": String(childrenFor(task: task).count)
                        ])
                        // Phase 70.A1.x: open the bundle's full coordination
                        // surface inline — vendor reframing, child line
                        // items, scheduling, snooze, Chez delegation. The
                        // earlier "punt to MaintenanceScheduleView" pattern
                        // was slow + confusing (re-render the old timeline
                        // just to re-tap the same row).
                        detailTask = task
                    },
                    onBookIt: {
                        quickScheduleTask = task
                    }
                )
                // Phase F2 + 70.A1 follow-on F5: leading swipe = complete,
                // trailing = archive (was snooze pre-follow-on; snooze
                // relocated to MaintenanceTaskDetailSheet menu).
                // Phase 70.A1 follow-on I3: each commit lands an
                // undo toast so accidental swipes are recoverable.
                .swipeRowActions(
                    archiveLabel: "Archive",
                    onComplete: {
                        Task {
                            await maintenanceVM.completeTask(task)
                            lastSwipeToast = SwipeToast(taskId: task.id, action: .completed, taskTitle: task.title)
                        }
                    },
                    onArchive: {
                        Analytics.track(.tasksV2SwipedArchive, ["source": "bundle_card"])
                        Task {
                            await maintenanceVM.archiveTask(task)
                            lastSwipeToast = SwipeToast(taskId: task.id, action: .archived, taskTitle: task.title)
                        }
                    }
                )
            }

        case .standaloneTask(let task):
            // Reuse the existing UnifiedTaskCard via a row helper. Task
            // 70.A1.9 polishes the variants; for 70.A1's visibility ship
            // a basic row is enough to surface the row as VISIBLE.
            selectionWrap(task: task) {
                StandaloneTaskRow(
                    task: task,
                    contractor: contractorFor(task: task),
                    isHighlighted: highlightedTaskId == task.id,
                    onTap: {
                        // Phase 70.A1.x: standalone task tap opens
                        // MaintenanceTaskDetailSheet inline. Same fix as
                        // the bundle parent above — no more deferring to
                        // MaintenanceScheduleView.
                        detailTask = task
                    }
                )
                .swipeRowActions(
                    archiveLabel: "Archive",
                    onComplete: {
                        Task {
                            await maintenanceVM.completeTask(task)
                            lastSwipeToast = SwipeToast(taskId: task.id, action: .completed, taskTitle: task.title)
                        }
                    },
                    onArchive: {
                        Analytics.track(.tasksV2SwipedArchive, ["source": "standalone_row"])
                        Task {
                            await maintenanceVM.archiveTask(task)
                            lastSwipeToast = SwipeToast(taskId: task.id, action: .archived, taskTitle: task.title)
                        }
                    }
                )
            }

        case .routineOccurrence(let occurrence):
            // Routine occurrences don't carry an underlying maintenance_task
            // row so they can't be selected for bulk actions OR swipe-
            // completed. They still tap into RoutineDetailView.
            TasksV2RoutineOccurrenceRow(
                occurrence: occurrence,
                routine: routineFor(occurrence: occurrence),
                contractor: contractorForOccurrence(occurrence),
                onTap: {
                    if !selectionMode,
                       let routine = routineFor(occurrence: occurrence),
                       let householdId {
                        pushTarget = .routineDetail(routine, householdId)
                    }
                }
            )
            .opacity(selectionMode ? 0.5 : 1.0)
        }
    }

    /// Phase F4: wrap a row in the selection-mode overlay when
    /// `selectionMode == true`. Disables the underlying card's hit
    /// testing so taps don't open detail sheets / scheduling sheets,
    /// renders a leading 22pt circle / checkmark, and routes whole-row
    /// taps to toggle membership in `selectedTaskIds`.
    @ViewBuilder
    private func selectionWrap<Content: View>(
        task: MaintenanceTaskDBRow,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if selectionMode {
            HStack(spacing: 10) {
                Image(systemName: selectedTaskIds.contains(task.id)
                      ? "checkmark.circle.fill"
                      : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(selectedTaskIds.contains(task.id)
                                     ? HavenColors.action
                                     : HavenColors.beige300)
                    .frame(width: 24)
                content()
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.selection()
                withAnimation(HavenTheme.animationStandard) {
                    if selectedTaskIds.contains(task.id) {
                        selectedTaskIds.remove(task.id)
                    } else {
                        selectedTaskIds.insert(task.id)
                    }
                }
            }
        } else {
            content()
                .contextMenu {
                    // Phase 70.A1 follow-on J1 — long-press actions match
                    // the swipe gestures (Done = right-swipe, Archive =
                    // left-swipe) so power users have a discoverable
                    // alternative when the swipe is awkward (small touch
                    // targets, accessibility settings, etc.). All three
                    // committal actions land an Undo toast via I3 so
                    // accidents recover the same way.
                    Button {
                        Task {
                            await maintenanceVM.completeTask(task)
                            lastSwipeToast = SwipeToast(taskId: task.id, action: .completed, taskTitle: task.title)
                        }
                    } label: {
                        Label("Mark done", systemImage: "checkmark.circle")
                    }

                    Button {
                        quickScheduleTask = task
                    } label: {
                        Label("Reschedule", systemImage: "calendar")
                    }

                    Divider()

                    Button {
                        withAnimation(HavenTheme.animationStandard) {
                            selectionMode = true
                            selectedTaskIds = [task.id]
                        }
                    } label: {
                        Label("Select", systemImage: "checkmark.circle.dashed")
                    }

                    Divider()

                    Button(role: .destructive) {
                        Analytics.track(.tasksV2SwipedArchive, ["source": "context_menu"])
                        Task {
                            await maintenanceVM.archiveTask(task)
                            lastSwipeToast = SwipeToast(taskId: task.id, action: .archived, taskTitle: task.title)
                        }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                }
        }
    }

    /// Phase 70 "Your active programs" — REPLACES the prior pair of
    /// `programsSection` + `chezHandlingSection`. Chez-owned routines
    /// render inline with a salmon CHEZ pill via `ChezOwnedPill` instead
    /// Phase 70.A1.x: "Active Routines This Season" card. Sits above
    /// the Active Programs section header. Surfaces season-scoped
    /// routine density (count + visit count) and routes to the full
    /// RoutinesListView for management. Replaces the Full Year toggle's
    /// discoverability role — instead of dumping every season's work
    /// into one flat feed, the user clicks through to see all routines
    /// in one focused list.
    @ViewBuilder
    private var activeRoutinesSeasonCard: some View {
        let programs = activeFeed.programs
        let visits = activeFeed.routineVisitCount
        if !programs.isEmpty {
            Button {
                Haptics.selection()
                pushTarget = .routinesList
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.navy800)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(HavenColors.navy800.opacity(0.08))
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active routines this \(activeSeason.displayName.lowercased())")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                        Text(activeRoutinesCardSubtitle(programCount: programs.count, visitCount: visits))
                            .font(.system(size: 12))
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(14)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                .havenShadow()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, TasksV5.sectionLabelGap)
        }
    }

    private func activeRoutinesCardSubtitle(programCount: Int, visitCount: Int) -> String {
        let progPart = "\(programCount) routine\(programCount == 1 ? "" : "s")"
        if visitCount > 0 {
            return "\(progPart) · \(visitCount) visit\(visitCount == 1 ? "" : "s") expected"
        }
        return "\(progPart) on autopilot"
    }

    /// of being split into a second section. Single source of truth per
    /// routine; no duplicate rows.
    @ViewBuilder
    private var combinedProgramsSection: some View {
        let programs = activeFeed.programs
        let chezTasks = activeFeed.chezTasks
        if programs.isEmpty && chezTasks.isEmpty {
            SectionLabel(
                eyebrow: "Your active programs",
                sub: "On autopilot"
            )
            .padding(.bottom, TasksV5.sectionLabelGap)

            emptyProgramsCard
                .padding(.horizontal, TasksV5.pageMargin)
                .padding(.bottom, TasksV5.sectionGap)
        } else {
            SectionLabel(
                eyebrow: "Your active programs",
                sub: programsSubtitle(programs, chezTasks: chezTasks),
                action: (programs.count + chezTasks.count) > 4 ? .init(title: "See all", perform: {
                    pushTarget = .routinesList
                }) : nil
            )
            .padding(.bottom, TasksV5.sectionLabelGap)

            VStack(spacing: TasksV5.rowGap) {
                ForEach(programs.prefix(4)) { routine in
                    ProgramRow(
                        icon: routine.resolvedIcon,
                        name: routine.presentationLabel,
                        nextEventLabel: viewModel.nextEventLabel(for: routine),
                        chezOwned: routine.chezOwned
                    ) {
                        if let householdId {
                            pushTarget = .routineDetail(routine, householdId)
                        }
                    }
                }
                // Friend feedback (May 2026): chez-owned standalone tasks
                // render below the routine rows in the same section so
                // the homeowner sees them with the Chez pill instead of
                // them nagging from "Needs your attention." Tap → opens
                // the task detail sheet, where the ChezTaskActivityCard
                // surfaces request status + recent messages.
                ForEach(Array(chezTasks.prefix(max(0, 4 - programs.count)))) { task in
                    ProgramRow(
                        icon: chezTaskIcon(task: task),
                        name: task.title,
                        nextEventLabel: chezTaskNextEventLabel(task: task),
                        chezOwned: true
                    ) {
                        detailTask = task
                    }
                }
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, TasksV5.sectionGap)
        }
    }

    /// Resolve a category-derived SF Symbol for a chez-owned task row
    /// in the Active Programs section. Routes through the existing
    /// template lookup → SystemCategoryRegistry icon so the row reads
    /// at a glance (handyman wrench, plumbing droplet, etc.).
    private func chezTaskIcon(task: MaintenanceTaskDBRow) -> String {
        if let templateKey = task.templateId,
           let colon = templateKey.firstIndex(of: ":") {
            let category = String(templateKey[..<colon])
            if let meta = SystemCategoryRegistry.metaForCategory(category) {
                return meta.icon
            }
        }
        return "checkmark.seal"
    }

    /// "Chez is on it" caption for a chez-owned task row. Falls back to
    /// the task's scheduled / due date if Chez hasn't proposed anything
    /// yet.
    private func chezTaskNextEventLabel(task: MaintenanceTaskDBRow) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = task.scheduledDate ?? task.nextDueDate
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateStyle = .medium
            display.timeStyle = .none
            return "Chez is on it · Due \(display.string(from: date))"
        }
        return "Chez is on it"
    }

    private func programsSubtitle(_ programs: [RoutineRow], chezTasks: [MaintenanceTaskDBRow] = []) -> String {
        let chezCount = programs.filter { $0.chezOwned }.count + chezTasks.count
        let totalCount = programs.count + chezTasks.count
        let visits = activeFeed.routineVisitCount
        let visitsPart: String? = visits > 0
            ? "\(visits) visit\(visits == 1 ? "" : "s") this \(activeSeason.displayName.lowercased())"
            : nil
        let chezPart: String?
        if chezCount == 0 { chezPart = nil }
        else if chezCount == totalCount { chezPart = "Chez is handling these" }
        else { chezPart = "\(chezCount) handled by Chez" }

        let parts = [visitsPart, chezPart, "On autopilot"].compactMap { $0 }
        return parts.joined(separator: " · ")
    }

    // MARK: - Phase 70 lookups (contractor / bundle children / routines)

    /// Look up the contractor linked to a task. Resolves through the
    /// shared `MaintenanceViewModel.contractors` cache so we don't hit
    /// the DB on every render.
    private func contractorFor(task: MaintenanceTaskDBRow) -> ContractorRow? {
        guard let contractorId = task.assignedContractorId else { return nil }
        return maintenanceVM.contractors.first { $0.id == contractorId }
    }

    /// Resolve the bundle's child line items. Pre-Phase-70 the bundle
    /// notes were a frozen snapshot; this reads from the current template
    /// library so Section C additions surface on existing installs.
    ///
    /// 70.A1 ships with empty activeSubtypes (universal children only).
    /// Subtype-gated children (wood vs gas chimney, etc.) are added in
    /// a follow-up when the home_system + property lookup wires through
    /// to this helper.
    private func childrenFor(task: MaintenanceTaskDBRow) -> [MaintenanceTemplate] {
        guard let templateId = task.templateId else { return [] }
        let pack = appState.primaryProperty?.regionalPack.flatMap { RegionalPack(rawValue: $0) }
        return MaintenanceTemplates.bundleChildren(
            forTemplateId: templateId,
            activeSubtypes: [],
            regionalPack: pack
        )
    }

    private func routineFor(occurrence: RoutineOccurrence) -> RoutineRow? {
        viewModel.routines.first { $0.id == occurrence.routineId }
    }

    private func contractorForOccurrence(_ occurrence: RoutineOccurrence) -> ContractorRow? {
        guard let routine = routineFor(occurrence: occurrence),
              let vendorId = routine.vendorId else { return nil }
        return maintenanceVM.contractors.first { $0.id == vendorId }
    }

    /// Decision-row icon for a standalone task. Derives from the task's
    /// system category (parsed from templateId) so the user sees a
    /// category-relevant symbol even before a vendor is linked.
    private func decisionIconFor(task: MaintenanceTaskDBRow) -> String {
        guard let templateId = task.templateId,
              let colonRange = templateId.range(of: ":") else {
            return "wrench.and.screwdriver"
        }
        let category = String(templateId[..<colonRange.lowerBound]).lowercased()
        switch category {
        case "roofing":              return "house.fill"
        case "plumbing":             return "drop.fill"
        case "hvac":                 return "thermometer"
        case "chimney":              return "flame.fill"
        case "electrical":           return "bolt.fill"
        case "septic system":        return "drop.triangle.fill"
        case "landscaping":          return "leaf.fill"
        case "pool/spa", "hot tub":  return "drop.circle.fill"
        case "generator":            return "bolt.batteryblock.fill"
        case "water heater":         return "drop.degreesign.fill"
        case "appliance":            return "oven.fill"
        case "pest control":         return "ladybug.fill"
        case "security system":     return "lock.shield.fill"
        case "snow removal":         return "snowflake"
        default:                     return "wrench.and.screwdriver"
        }
    }

    /// Concrete-date meta for a standalone task in the Needs Attention
    /// section. "Due Tue, Sept 20" — homeowner voice. Year-aware per
    /// Phase 70.A1 follow-on F2 so a 2027-anchored Spring task reads as
    /// "Due Thu, Feb 4, 2027" instead of looking past-dated next to a
    /// 2026 May row.
    private func standaloneDecisionMeta(for task: MaintenanceTaskDBRow) -> String {
        let dateString = task.scheduledDate ?? task.nextDueDate
        if let date = TasksV2DateFormatting.parseRowDate(dateString) {
            return "Due \(TasksV2DateFormatting.longDay(date)) · Pick a vendor."
        }
        return "Pick a vendor."
    }

    // MARK: - Phase 70.A1 follow-on F4 — scheduling-confirmation toast

    @ViewBuilder
    private func scheduledConfirmationToast(_ toast: ScheduledToast) -> some View {
        Button {
            // Open the task detail inline so the user can verify where
            // the row landed. Tasks-tab patterns elsewhere route through
            // detailTask for the same reason.
            if let task = maintenanceVM.tasks.first(where: { $0.id == toast.taskId }) {
                detailTask = task
            }
            lastScheduledToast = nil
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(HavenColors.success.opacity(0.18))
                        .frame(width: 28, height: 28)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(HavenColors.success)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Scheduled for \(TasksV2DateFormatting.longDay(toast.scheduledFor))")
                        .font(HavenTypography.uiLabel.weight(.semibold))
                        .foregroundColor(HavenColors.textPrimary)
                        .lineLimit(1)
                    Text("Tap to view")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundColor(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HavenColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(HavenColors.success.opacity(0.3), lineWidth: 1)
            )
            .havenShadow(HavenTheme.shadowElevated)
        }
        .buttonStyle(.plain)
        .task(id: toast.id) {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            // Only clear if this toast is still the live one (avoids
            // racing a newer toast that just replaced this one).
            if lastScheduledToast?.id == toast.id {
                lastScheduledToast = nil
            }
        }
        .accessibilityLabel("Scheduled for \(TasksV2DateFormatting.longDay(toast.scheduledFor)). Tap to view.")
    }

    // MARK: - Phase 70.A1 follow-on I3 — swipe undo toast

    @ViewBuilder
    private func swipeUndoToast(_ toast: SwipeToast) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(toastTint(toast).opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: toastIcon(toast))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(toastTint(toast))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(toast.headline)
                    .font(HavenTypography.uiLabel.weight(.semibold))
                    .foregroundColor(HavenColors.textPrimary)
                    .lineLimit(1)
                Text(toast.taskTitle)
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundColor(HavenColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Button {
                Task { await undoSwipe(toast) }
            } label: {
                Text("Undo")
                    .font(HavenTypography.uiLabel.weight(.bold))
                    .foregroundColor(HavenColors.action)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        Capsule().stroke(HavenColors.action.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(toastTint(toast).opacity(0.3), lineWidth: 1)
        )
        .havenShadow(HavenTheme.shadowElevated)
        .task(id: toast.id) {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if lastSwipeToast?.id == toast.id {
                lastSwipeToast = nil
            }
        }
        .accessibilityLabel("\(toast.headline) \(toast.taskTitle). Tap Undo to restore.")
    }

    private func toastTint(_ toast: SwipeToast) -> Color {
        switch toast.action {
        case .completed: return HavenColors.success
        case .archived:  return HavenColors.textSecondary
        }
    }

    private func toastIcon(_ toast: SwipeToast) -> String {
        switch toast.action {
        case .completed: return "checkmark"
        case .archived:  return "archivebox.fill"
        }
    }

    @MainActor
    private func undoSwipe(_ toast: SwipeToast) async {
        // Reverse the archive write either way — completed and archived
        // both flip `is_archived=true`. Completion additionally clears
        // the `last_completed_date` stamp the G1 path wrote.
        switch toast.action {
        case .completed:
            await maintenanceVM.undoCompletion(taskId: toast.taskId)
        case .archived:
            await maintenanceVM.undoArchive(taskId: toast.taskId)
        }
        lastSwipeToast = nil
    }

    // MARK: - Phase 70 inline scheduling

    /// Persist a date chosen from `QuickSchedulingSheet`. Writes
    /// `scheduled_date` on the task row + posts the standard
    /// `.maintenanceTaskChanged` so other surfaces (Dashboard,
    /// MaintenanceScheduleView) refresh.
    @MainActor
    private func commitQuickSchedule(task: MaintenanceTaskDBRow, date: Date) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        var update = MaintenanceTaskUpdate()
        update.scheduledDate = dateString
        do {
            _ = try await DatabaseService.shared.updateMaintenanceTask(id: task.id, update)
            Haptics.success()
            // Phase 70.A1 follow-on F4 — confirmation toast. Independent
            // of where the row lands after the write (same-month "this
            // week" → stays put; cross-season "next week" → moves to a
            // different bucket but the toast is still visible).
            lastScheduledToast = ScheduledToast(taskId: task.id, taskTitle: task.title, scheduledFor: date)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            await maintenanceVM.loadTasks()

            let daysOut = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            Analytics.track(.tasksV2QuickScheduled, [
                "task_id": task.id.uuidString,
                "days_out": String(daysOut)
            ])
        } catch {
            print("[MaintenanceTabView] commitQuickSchedule failed: \(error)")
        }
    }

    // MARK: - Phase F4 bulk-select

    /// Bottom action bar shown via safeAreaInset when selectionMode is
    /// on. Apple Mail pattern — surfaces "N selected" + a single Menu
    /// of bulk actions (Snooze 7d / Snooze 30d / Mark complete). When
    /// idle, renders an empty view so the safe-area inset is zero.
    @ViewBuilder
    private var bulkActionBar: some View {
        if selectionMode {
            HStack(spacing: HavenTheme.spacing12) {
                Text("\(selectedTaskIds.count) selected")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Menu {
                    Button {
                        Task { await bulkSnooze(days: 7) }
                    } label: {
                        Label("Snooze 7 days", systemImage: "moon.zzz")
                    }
                    Button {
                        Task { await bulkSnooze(days: 30) }
                    } label: {
                        Label("Snooze 30 days", systemImage: "moon.zzz.fill")
                    }
                    Divider()
                    Button {
                        Task { await bulkComplete() }
                    } label: {
                        Label("Mark complete", systemImage: "checkmark.circle.fill")
                    }
                } label: {
                    HStack(spacing: HavenTheme.spacing8) {
                        if bulkBusy {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text("Actions")
                            .font(HavenTypography.uiButton)
                    }
                    .padding(.horizontal, HavenTheme.spacing20)
                    .padding(.vertical, HavenTheme.spacing12)
                    .frame(minHeight: 44)
                    .background(selectedTaskIds.isEmpty ? HavenColors.beige200 : HavenColors.action)
                    .foregroundStyle(selectedTaskIds.isEmpty ? HavenColors.textTertiary : HavenColors.textOnAction)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton, style: .continuous))
                }
                .disabled(selectedTaskIds.isEmpty || bulkBusy)
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.vertical, HavenTheme.spacing12)
            .background(HavenColors.surface)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(HavenColors.beige200)
                    .frame(height: 0.5)
            }
            .transition(.move(edge: .bottom))
        }
    }

    @MainActor
    private func bulkSnooze(days: Int) async {
        guard !selectedTaskIds.isEmpty else { return }
        bulkBusy = true
        defer { bulkBusy = false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        let calendar = Calendar(identifier: .gregorian)

        let taskMap = Dictionary(uniqueKeysWithValues: maintenanceVM.tasks.map { ($0.id, $0) })
        var changed = 0
        for id in selectedTaskIds {
            guard let task = taskMap[id] else { continue }
            // Anchor against the existing nextDueDate so chained snoozes
            // accumulate rather than collapsing to today + N. Matches
            // MaintenanceScheduleView semantics.
            let anchor = formatter.date(from: task.nextDueDate) ?? Date()
            let pushed = calendar.date(byAdding: .day, value: days, to: anchor) ?? anchor
            do {
                _ = try await DatabaseService.shared.updateMaintenanceTask(
                    id: id,
                    MaintenanceTaskUpdate(nextDueDate: formatter.string(from: pushed))
                )
                changed += 1
            } catch { continue }
        }

        Analytics.track(.bulkTasksSnoozed, [
            "count": changed,
            "days": days
        ])
        Haptics.success()
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        withAnimation(HavenTheme.animationStandard) {
            selectionMode = false
            selectedTaskIds.removeAll()
        }
        await maintenanceVM.loadTasks()
    }

    @MainActor
    private func bulkComplete() async {
        guard !selectedTaskIds.isEmpty else { return }
        bulkBusy = true
        defer { bulkBusy = false }

        let taskMap = Dictionary(uniqueKeysWithValues: maintenanceVM.tasks.map { ($0.id, $0) })
        var changed = 0
        for id in selectedTaskIds {
            guard let task = taskMap[id] else { continue }
            await maintenanceVM.completeTask(task)
            changed += 1
        }
        Analytics.track(.bulkTasksCompleted, ["count": changed])
        Haptics.success()
        withAnimation(HavenTheme.animationStandard) {
            selectionMode = false
            selectedTaskIds.removeAll()
        }
    }

    // MARK: - Phase F3 duplicate detection

    /// Scan routines + tasks for high-confidence duplicate pairs. Uses
    /// the already-loaded viewModel state so zero additional DB hits.
    /// Filters out pairs the user explicitly dismissed (keep-both) in
    /// the last 30 days via DuplicateDismissalStore.
    @MainActor
    private func loadDuplicates() async {
        let matches = DuplicateDetector.scan(
            routines: viewModel.routines,
            tasks: maintenanceVM.tasks,
            systems: maintenanceVM.systems,
            contractors: maintenanceVM.contractors
        )
        let dismissed = DuplicateDismissalStore.recentlyDismissedPairs()
        detectedDuplicates = matches.filter { match in
            !dismissed.contains(PairKey(match: match))
        }
    }

    /// Apply the homeowner's resolution to a match. Mirrors
    /// MaintenanceScheduleView's `handleDuplicateResolution` so behavior
    /// is consistent: keep-both records a 30-day dismissal, keep-X
    /// archives the loser. After write, refresh + auto-open the next
    /// queued match so the user can resolve the whole queue without
    /// closing + reopening the sheet.
    @MainActor
    private func handleDuplicateResolution(
        match: DuplicateDetector.Match,
        resolution: MaintenanceDuplicateSheet.Resolution
    ) async {
        do {
            switch resolution {
            case .keepBoth:
                DuplicateDismissalStore.recordDismissal(PairKey(match: match))
            case .keepPrimary:
                try await archiveDuplicateEntity(kind: match.secondaryKind, id: match.secondary.id)
            case .keepSecondary:
                try await archiveDuplicateEntity(kind: match.primaryKind, id: match.primary.id)
            }
        } catch {
            print("[MaintenanceTabView] duplicate resolution failed: \(error)")
            Haptics.error()
            reviewingMatch = nil
            return
        }
        // Pull a fresh scan to drop the resolved match from the queue.
        await loadDuplicates()
        // Auto-advance: if more matches remain, swap to the next one
        // (Apple Photos Review Duplicates pattern). Otherwise dismiss.
        if let next = detectedDuplicates.first {
            reviewingMatch = next
        } else {
            reviewingMatch = nil
        }
        NotificationCenter.default.post(name: .routineChanged, object: nil)
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
    }

    // MARK: - Phase G1 year-at-a-glance

    private struct YearSummary {
        let yearVisitCount: Int
        let yearSpend: Double
        let next30VisitCount: Int
        let next30Estimate: Double
    }

    private var yearSummary: YearSummary {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current
        let now = Date()
        let yearStart = cal.date(from: cal.dateComponents([.year], from: now)) ?? Date.distantPast
        let yearEnd = cal.date(byAdding: .year, value: 1, to: yearStart) ?? now
        let next30End = cal.date(byAdding: .day, value: 30, to: now) ?? now
        let yearStartStr = fmt.string(from: yearStart)
        let yearEndStr = fmt.string(from: yearEnd)
        let nowStr = fmt.string(from: now)
        let next30EndStr = fmt.string(from: next30End)

        // Completed visits this year = service_records this year +
        // completed tasks this year (dedup via invoice_document_id when
        // present; matches MaintenanceScheduleView's yearSummary).
        var completedVisits = serviceRecordsForYear.count
        for task in maintenanceVM.tasks {
            guard let last = task.lastCompletedDate, !last.isEmpty, last >= yearStartStr else { continue }
            completedVisits += 1
        }

        // Upcoming visits = scheduled-or-due tasks (not archived, not
        // routine-parented) in the remainder of the year, plus routine
        // occurrences from the expander.
        var upcomingVisits = 0
        for task in maintenanceVM.tasks where task.isArchived != true {
            let target = task.scheduledDate ?? task.nextDueDate
            guard target >= nowStr, target <= yearEndStr else { continue }
            upcomingVisits += 1
        }
        let routineOccsThisYear = RoutineOccurrenceExpander.occurrences(
            routines: viewModel.routines,
            from: now,
            through: yearEnd
        )
        upcomingVisits += routineOccsThisYear.count

        // Spend YTD: sum vendor invoice_amount on documents this year,
        // plus service_record.cost when not double-counted via the doc
        // link.
        var spend: Double = 0
        var docIdsWithInvoiceAmount: Set<UUID> = []
        for doc in vendorDocumentsForYear {
            if let amount = doc.invoiceAmount, amount > 0 {
                spend += amount
                docIdsWithInvoiceAmount.insert(doc.id)
            }
        }
        for record in serviceRecordsForYear {
            if let linkedId = record.invoiceDocumentId,
               docIdsWithInvoiceAmount.contains(linkedId) { continue }
            if let cost = record.cost, cost > 0 { spend += cost }
        }

        // Next-30 horizon: vendor tasks in the window + their estimated
        // cost (parsed from the `estimated_cost` column when set).
        var next30Visits = 0
        var next30Estimate: Double = 0
        for task in maintenanceVM.tasks where task.isArchived != true {
            let target = task.scheduledDate ?? task.nextDueDate
            guard target >= nowStr, target <= next30EndStr else { continue }
            next30Visits += 1
            if let cost = task.estimatedCost, cost > 0 {
                next30Estimate += cost
            }
        }
        let next30RoutineOccs = RoutineOccurrenceExpander.occurrences(
            routines: viewModel.routines,
            from: now,
            through: next30End
        )
        next30Visits += next30RoutineOccs.count

        return YearSummary(
            yearVisitCount: completedVisits + upcomingVisits,
            yearSpend: spend,
            next30VisitCount: next30Visits,
            next30Estimate: next30Estimate
        )
    }

    /// One-shot fetch of documents + service_records in the current
    /// year so the YearAtAGlanceCard has data to render. Parallel
    /// fetches; runs in `.task` block and refreshes on
    /// .maintenanceTaskChanged.
    @MainActor
    private func loadYearStats() async {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current
        let yearStart = cal.date(from: cal.dateComponents([.year], from: Date())) ?? Date.distantPast
        let yearStartStr = fmt.string(from: yearStart)

        async let docs: [DocumentRow] = {
            (try? await DatabaseService.shared.fetchDocuments()) ?? []
        }()
        async let records: [ServiceRecordRow] = {
            (try? await DatabaseService.shared.fetchServiceRecords()) ?? []
        }()

        let allDocs = await docs
        let allRecords = await records

        vendorDocumentsForYear = allDocs.filter {
            guard let dateStr = $0.invoiceDate else { return false }
            return dateStr >= yearStartStr
        }
        serviceRecordsForYear = allRecords.filter {
            $0.serviceDate >= yearStartStr
        }
    }

    private func archiveDuplicateEntity(kind: DuplicateDetector.EntityKind, id: UUID) async throws {
        switch kind {
        case .routine:
            try await DatabaseService.shared.archiveRoutine(id: id)
        case .task:
            try await DatabaseService.shared.deleteMaintenanceTask(id: id)
        }
    }

    // MARK: - Phase 70 deep-link handler

    /// Handle a `.openMaintenanceTask` notification posted by the push
    /// handler / inbox / activity feed. Sets the season filter, scrolls
    /// to the row (TODO: ScrollViewReader wire-up), and renders the
    /// highlight overlay for ~1.5 seconds.
    private func handleDeepLink(_ notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        // Apply property scope first so multi-property households jump
        // to the right property's feed.
        if let propString = userInfo["property_id"] as? String,
           let propUUID = UUID(uuidString: propString) {
            viewModel.activePropertyId = propUUID
        }
        // Apply season override.
        if let seasonRaw = userInfo["season"] as? String,
           let season = Season(rawValue: seasonRaw) {
            withAnimation(HavenTheme.animationStandard) {
                activeSeason = season
            }
        }
        // Apply highlight.
        if let taskString = userInfo["task_id"] as? String,
           let taskUUID = UUID(uuidString: taskString) {
            highlightedTaskId = taskUUID
            // Clear the highlight after ~1.5s so the ring fades.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if highlightedTaskId == taskUUID {
                    withAnimation(HavenTheme.animationStandard) {
                        highlightedTaskId = nil
                    }
                }
            }
        }
        Analytics.track(.tasksV2DeepLinkOpened, [
            "has_task_id": userInfo["task_id"] != nil ? "true" : "false",
            "has_routine_id": userInfo["routine_id"] != nil ? "true" : "false",
            "has_season": userInfo["season"] != nil ? "true" : "false"
        ])
    }

    // MARK: - Phase 70.A1 follow-on F4 — ScheduledToast model

    /// Backs the in-view confirmation pill. Identifiable so SwiftUI's
    /// diffing replaces the toast cleanly when a second schedule lands
    /// before the first toast auto-dismisses.
    struct ScheduledToast: Identifiable, Equatable {
        let id = UUID()
        let taskId: UUID
        let taskTitle: String
        let scheduledFor: Date
    }

    // MARK: - Phase 70.A1 follow-on I3 — SwipeToast model

    /// Tom flagged accidental swipe-complete losing tasks. SwipeToast
    /// surfaces a 5-second "Undo" affordance right after a swipe so
    /// the user can recover before having to hunt through Archived.
    /// Mirrors Apple Mail / Notes — post-action undo, not pre-action
    /// confirmation.
    struct SwipeToast: Identifiable, Equatable {
        enum Action: Equatable { case completed, archived }

        let id = UUID()
        let taskId: UUID
        let action: Action
        let taskTitle: String

        var headline: String {
            switch action {
            case .completed: return "Marked done"
            case .archived:  return "Archived"
            }
        }
    }

    // MARK: - Navigation destinations

    enum MaintenancePush: Hashable, Identifiable {
        case routinesList
        case recommendedServices
        case vehicle(UUID)
        case routineDetail(RoutineRow, UUID)

        var id: String {
            switch self {
            case .routinesList: return "routines"
            case .recommendedServices: return "recommended"
            case .vehicle(let id): return "vehicle-\(id.uuidString)"
            case .routineDetail(let r, _): return "routine-\(r.id.uuidString)"
            }
        }

        static func == (lhs: MaintenancePush, rhs: MaintenancePush) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    @ViewBuilder
    private func destination(for push: MaintenancePush) -> some View {
        switch push {
        case .routinesList:
            if let householdId {
                RoutinesListView(householdId: householdId, propertyId: propertyId)
            }
        case .recommendedServices:
            if let householdId, let propertyId {
                RecommendedServicesView(householdId: householdId, propertyId: propertyId)
            }
        case .vehicle(let vehicleId):
            // PropertyListView's existing vehicle navigation; route via notification.
            EmptyView()
                .onAppear {
                    NotificationCenter.default.post(
                        name: .navigateToVehicle,
                        object: nil,
                        userInfo: ["vehicleId": vehicleId.uuidString]
                    )
                    NotificationCenter.default.post(
                        name: .switchToTab,
                        object: nil,
                        userInfo: ["tab": 1]
                    )
                    pushTarget = nil
                }
        case .routineDetail(let routine, let householdId):
            RoutineDetailView(routine: routine, householdId: householdId)
        }
    }

    // MARK: - Helpers

    private var scopedSeasonOrNil: Season? {
        // When the current season is active, show everything (year-wide).
        // When a non-current season is active, scope to that season.
        activeSeason == currentSeason ? nil : activeSeason
    }

    private func vehicleDisplayName(_ vehicle: VehicleRow) -> String {
        let parts: [String?] = [
            vehicle.year.map { String($0) },
            vehicle.make?.uppercased(),
            vehicle.model,
        ]
        let composed = parts.compactMap { $0 }.joined(separator: " ")
        return composed.isEmpty ? vehicle.name : composed
    }
}

// MARK: - DecisionVendorPicker (one-tap "Choose vendor" sheet)

/// Light wrapper around the existing `ContractorPickerSheet` that, on
/// selection, attaches the vendor to the routine and flips its
/// `setup_state` from `pending_vendor` → `active`. Mirrors the existing
/// PostQuizVendorDelegationSheet completion handler.
private struct DecisionVendorPicker: View {
    let routine: RoutineRow
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ContractorPickerSheet(
            systemCategory: routine.typedKind?.displayLabel ?? "Service"
        ) { contractor in
            Task {
                do {
                    let updates = RoutineUpdate(
                        vendorId: contractor.id,
                        setupState: RoutineSetupState.active.rawValue
                    )
                    _ = try await DatabaseService.shared.updateRoutine(id: routine.id, updates)
                    NotificationCenter.default.post(name: .routineChanged, object: nil)
                } catch {
                    print("[MaintenanceTabView] attach vendor failed: \(error)")
                }
                await MainActor.run {
                    onComplete()
                    dismiss()
                }
            }
        }
    }
}

// MARK: - View Model

// MARK: - Phase 70 (Tasks v2) SeasonFeed types

/// Phase 70 (Tasks v2): the single source of truth for one season of the
/// Tasks tab. Every consumer — YearRibbon tile counts, MiniHero % covered,
/// "Needs your attention" section, "This Season's Tasks" feed, "Your active
/// programs" section — derives from a `SeasonFeed` instance. Avoids the
/// pre-Phase-70 bug class where the ribbon claimed 30 items but the screen
/// rendered 5; with this struct, count and rows can't diverge.
struct SeasonFeed {
    let season: Season

    /// Routines + standalone tasks that need user action this season.
    /// Sorted by urgency (overdue first, then within-7-days, then by date).
    let decisions: [DecisionEntry]

    /// All in-season TASK work organized chronologically by month. Bundle
    /// parents and standalone tasks. Routine occurrences are deliberately
    /// EXCLUDED here — they were flooding the summer feed with 10+ rows
    /// per month of weekly Blue Fox / Doody Calls / Mosquito & Tick.
    /// Active Programs section is their canonical home; the season
    /// visit-count caption there carries the density signal.
    let monthSections: [MonthSection]

    /// Active routines for the "Your active programs" section. Includes
    /// Chez-owned routines (no separate section in Tasks v2) — the row
    /// renders a salmon Chez pill inline. Collapsed by default in the UI.
    let programs: [RoutineRow]

    /// Friend feedback (May 2026) — chez-owned tasks for this season.
    /// Rendered in the same Active Programs section as `programs`, just
    /// below the routine rows with a Chez pill. Keeps chez-managed work
    /// visible without it nagging from "Needs your attention."
    let chezTasks: [MaintenanceTaskDBRow]

    /// Total recurring-visit count for this season's active routines.
    /// Surfaces in the Active Programs section subtitle ("12 visits this
    /// summer · On autopilot") so the user knows the routine cadence
    /// without seeing every Wednesday-Blue-Fox row in the season feed.
    let routineVisitCount: Int

    /// Convenience: chip + ribbon tile counts. Counts decisions + tasks
    /// the user actually scrolls through in the main feed. Programs are
    /// EXCLUDED — they're autopilot, already surfaced via the Active
    /// Programs section's "N visits this season · On autopilot" subtitle.
    /// Including them in `totalItems` made the chip claim 26 items in
    /// Spring while the user only saw ~9 task rows in the main feed
    /// (the other 17 were either decisions hidden behind a 5-item cap
    /// or programs in the collapsed bottom section). Now the count
    /// maps directly to user mental model: "things I need to read or do
    /// in this season's feed."
    var totalItems: Int {
        decisions.count + monthSections.reduce(0) { $0 + $1.entries.count }
    }

    var actionItems: Int { decisions.count }

    /// Total task entries in the main feed (excludes decisions and
    /// programs). Used by the SeasonScopeBanner subtitle when it wants
    /// to distinguish "to-do tasks" from "decisions to make."
    var taskEntryCount: Int {
        monthSections.reduce(0) { $0 + $1.entries.count }
    }
}

/// One row in the "Needs your attention" section. Backed by either a
/// pending-vendor routine (the existing model) or a standalone task that
/// needs a contractor picked. D-HNW will add a third case for time-
/// sensitive financial renewals.
enum DecisionEntry: Identifiable {
    case routinePendingVendor(RoutineRow)
    case taskNeedsVendor(MaintenanceTaskDBRow)

    var id: String {
        switch self {
        case .routinePendingVendor(let r): return "routine:\(r.id.uuidString)"
        case .taskNeedsVendor(let t): return "task:\(t.id.uuidString)"
        }
    }

    var sortDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        switch self {
        case .routinePendingVendor(let r): return formatter.date(from: r.nextExpectedDate)
        case .taskNeedsVendor(let t):
            let s = t.scheduledDate ?? t.nextDueDate
            return formatter.date(from: s)
        }
    }
}

/// One month within the active season. Months without entries are omitted
/// from the SeasonFeed (no empty subheaders for May when nothing's there).
struct MonthSection: Identifiable {
    /// 1-indexed month number (1 = January, 12 = December).
    let month: Int
    /// Bundle parents + standalone tasks + routine occurrences within
    /// this month, sorted by date.
    let entries: [SeasonEntry]

    var id: Int { month }
}

/// One row inside a `MonthSection`. The case discriminator drives which
/// card variant the view renders: `BundleParentCard` for `.bundle`,
/// the existing `UnifiedTaskCard` for `.standaloneTask`, and a routine-
/// occurrence-specific variant for `.routineOccurrence`.
enum SeasonEntry: Identifiable {
    case bundle(MaintenanceTaskDBRow)
    case standaloneTask(MaintenanceTaskDBRow)
    case routineOccurrence(RoutineOccurrence)

    var id: String {
        switch self {
        case .bundle(let t): return "bundle:\(t.id.uuidString)"
        case .standaloneTask(let t): return "task:\(t.id.uuidString)"
        case .routineOccurrence(let o): return "occurrence:\(o.id)"
        }
    }

    /// The date that drives sort order within a month.
    var sortDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        switch self {
        case .bundle(let t), .standaloneTask(let t):
            let s = t.scheduledDate ?? t.nextDueDate
            return formatter.date(from: s)
        case .routineOccurrence(let o):
            return o.date
        }
    }
}

/// Phase 70.A1 follow-on F3 — single entry in the Up Next 14-day strip.
/// The strip ignores season scope so users never lose track of a
/// scheduled task that crossed a season boundary.
enum UpNextEntry: Identifiable {
    case task(MaintenanceTaskDBRow)
    case routineOccurrence(RoutineOccurrence)

    var id: String {
        switch self {
        case .task(let t): return "upnext:task:\(t.id.uuidString)"
        case .routineOccurrence(let o): return "upnext:occurrence:\(o.id)"
        }
    }

    var title: String {
        switch self {
        case .task(let t): return t.title
        case .routineOccurrence(let o):
            return o.routine.presentationLabel.isEmpty ? o.routine.label : o.routine.presentationLabel
        }
    }

    var date: Date {
        switch self {
        case .task(let t):
            let s = t.scheduledDate ?? t.nextDueDate
            return TasksV2DateFormatting.parseRowDate(s) ?? Date.distantFuture
        case .routineOccurrence(let o):
            return o.date
        }
    }

    /// Drives the badge tint + label on the card. Scheduled-tomorrow
    /// reads softer than scheduled-3-weeks-out, overdue reads loudest.
    var status: UpNextCard.Status {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .task(let t):
            let isScheduled = !(t.scheduledDate ?? "").isEmpty
            if date < cal.startOfDay(for: now) { return .overdue }
            if cal.isDateInToday(date)    { return .today }
            if cal.isDateInTomorrow(date) { return .tomorrow }
            return isScheduled ? .scheduled : .due
        case .routineOccurrence:
            if cal.isDateInToday(date)    { return .today }
            if cal.isDateInTomorrow(date) { return .tomorrow }
            return .scheduled
        }
    }

    var taskRow: MaintenanceTaskDBRow? {
        if case .task(let t) = self { return t }
        return nil
    }

    var occurrence: RoutineOccurrence? {
        if case .routineOccurrence(let o) = self { return o }
        return nil
    }

    /// SF Symbol used in the "no vendor on file" fallback avatar.
    var categoryIcon: String {
        switch self {
        case .task(let t):
            if let templateId = t.templateId,
               let colonRange = templateId.range(of: ":") {
                let category = String(templateId[..<colonRange.lowerBound])
                return SystemCategoryRegistry.metaForCategory(category)?.icon
                    ?? "wrench.and.screwdriver"
            }
            return "wrench.and.screwdriver"
        case .routineOccurrence(let o):
            return o.routine.resolvedIcon
        }
    }

    var assignedContractorId: UUID? {
        switch self {
        case .task(let t): return t.assignedContractorId
        case .routineOccurrence(let o): return o.routine.vendorId
        }
    }

    /// Analytics property — task or routine_occurrence, no PII.
    var analyticsType: String {
        switch self {
        case .task: return "task"
        case .routineOccurrence: return "routine_occurrence"
        }
    }
}

@MainActor
final class MaintenanceTabViewModel: ObservableObject {
    @Published private(set) var routines: [RoutineRow] = []
    @Published private(set) var isLoading = false

    /// Phase 70 (Tasks v2): per-session active property scope. When non-nil,
    /// `seasonFeed(_:)` filters everything to this property. When nil
    /// (single-property household or fresh launch), no property filtering
    /// happens — the feed shows all household work. The multi-property
    /// switcher UI lands in 70.D-HNW; the state model lands now so we
    /// don't migrate stored values when the switcher ships.
    @Published var activePropertyId: UUID?

    /// Phase F1 (MaintenanceScheduleView parity): active time-window
    /// filter. Nil = "show everything." When set, `seasonFeed(_:)` +
    /// `flexibleTasks(propertyId:)` apply the predicate so only tasks
    /// matching the window render. Carried from MaintenanceScheduleView's
    /// Phase 56.4 stats-pill filter — same enum semantics, owned by
    /// Tasks v2 now. Not persisted; resets each session.
    @Published var activeStatsFilter: TasksStatsFilter?

    /// Catalog count for the BrowseBand subtitle. Computed from
    /// `RecommendedServicesView`'s underlying templates list — but we don't
    /// want to hard-couple to that surface, so we ship a static "15 seasonal
    /// & on-demand services" copy that matches the V5 spec.
    let browseCatalogCount = 15

    /// Bundle-ready stat for MiniHero. Computed from MaintenanceViewModel
    /// once that gains a `bundleReadyCount` published property; for now,
    /// derive from contractors who have ≥3 pending tasks (heuristic).
    var bundleReadyCount: Int {
        let vm = MaintenanceViewModel.shared
        let pending = vm.tasks.filter { task in
            task.lastCompletedDate == nil && (task.isArchived ?? false) == false
        }
        let groupedByContractor = Dictionary(grouping: pending) { $0.assignedContractorId ?? UUID() }
        return groupedByContractor.values.filter { $0.count >= 3 }.count
    }

    func load(householdId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await DatabaseService.shared.fetchRoutines(householdId: householdId)
            self.routines = fetched.filter { $0.isVisible }
        } catch {
            print("[MaintenanceTabViewModel] load failed: \(error)")
        }
    }

    // MARK: Section data

    func pendingDecisions(scopedTo season: Season? = nil) -> [RoutineRow] {
        routines.filter { routine in
            routine.typedScope == .property &&
            routine.typedSetupState == .pendingVendor &&
            // Phase 85 — hide Chez-owned routines from "Needs your decision".
            // If Chez owns the routine, Chez is making the call, not the
            // homeowner. They surface in `chezHandlingPrograms` below
            // instead, in a more passive observational tone.
            !routine.chezOwned &&
            (season.map { routine.activeMonths.contains(anyOf: $0.months) } ?? true)
        }
    }

    func activePrograms(scopedTo season: Season? = nil) -> [RoutineRow] {
        routines.filter { routine in
            routine.typedScope == .property &&
            routine.typedSetupState == .active &&
            (season.map { routine.activeMonths.contains(anyOf: $0.months) } ?? true)
        }
        .sorted { lhs, rhs in
            (lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending)
        }
    }

    /// Phase 85 — Chez-handling section. Surfaces routines that Chez owns
    /// (whether they're pendingVendor / active / paused) in a passive
    /// "we're handling this" tone, separate from the homeowner's own
    /// decision queue. Sorted by label.
    func chezHandlingPrograms(scopedTo season: Season? = nil) -> [RoutineRow] {
        routines.filter { routine in
            routine.typedScope == .property &&
            routine.chezOwned &&
            routine.typedSetupState != .archived &&
            (season.map { routine.activeMonths.contains(anyOf: $0.months) } ?? true)
        }
        .sorted { lhs, rhs in
            (lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending)
        }
    }

    /// Friend feedback (May 2026) — chez-owned TASK rows (per-task
    /// delegations) the homeowner has handed off. Parallel to
    /// `chezHandlingPrograms` but scoped to maintenance tasks rather
    /// than routines. Surfaces in the Active Programs section with a
    /// Chez pill so the homeowner sees active status without the row
    /// nagging from "Needs your attention."
    func chezHandlingTasks(scopedTo season: Season? = nil) -> [MaintenanceTaskDBRow] {
        MaintenanceViewModel.shared.tasks.filter { task in
            if let scope = activePropertyId, task.propertyId != scope { return false }
            guard task.vehicleId == nil else { return false }
            if (task.isArchived ?? false) == true { return false }
            if let last = task.lastCompletedDate, !last.isEmpty { return false }
            guard task.isChezOwned == true else { return false }
            if task.parentRoutineId != nil { return false }
            // Hide bundle children — they live inline under the parent
            // card, not as their own rows (same predicate seasonFeed uses).
            if let templateKey = task.templateId,
               let template = MaintenanceTemplates.template(forKey: templateKey),
               template.bundleId != nil {
                return false
            }
            if let season { return isTask(task, in: season) }
            return true
        }
        .sorted { lhs, rhs in
            lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    /// Phase 70.A1 follow-on F3 — Up Next 14-day strip data source.
    /// Surfaces tasks and routine occurrences in the next N days
    /// (default 14) regardless of which season tile the user has
    /// active. Solves the "scheduled into next season → invisible"
    /// problem because the window crosses season boundaries.
    ///
    /// Includes:
    ///  - Maintenance tasks where `scheduled_date OR next_due_date`
    ///    falls in [now, now+windowDays], `parent_routine_id == nil`
    ///    (routine-parented tasks render under their routine card),
    ///    not archived, not completed, not vehicle-scoped (the vehicle
    ///    program section owns vehicle visits).
    ///  - Routine occurrences from RoutineOccurrenceExpander over the
    ///    same window. Paused / archived routines short-circuit there.
    ///
    /// Sorted ascending by date. No filtering by activeStatsFilter —
    /// the whole point is a season-agnostic "what's coming up" surface.
    func upNext(
        now: Date = Date(),
        windowDays: Int = 14
    ) -> [UpNextEntry] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: windowDays, to: startOfToday) else { return [] }
        let propScope = self.activePropertyId

        // Tasks in the window
        let allTasks = MaintenanceViewModel.shared.tasks.filter { task in
            if let scope = propScope, task.propertyId != scope { return false }
            guard task.vehicleId == nil else { return false }
            if task.parentRoutineId != nil { return false }
            if let last = task.lastCompletedDate, !last.isEmpty { return false }
            if (task.isArchived ?? false) == true { return false }
            // Bundle children are inline line items in the parent card,
            // never standalone — same exclusion as `seasonFeed`.
            if let templateKey = task.templateId,
               let template = MaintenanceTemplates.template(forKey: templateKey),
               template.bundleId != nil {
                return false
            }
            let s = task.scheduledDate ?? task.nextDueDate
            guard let date = TasksV2DateFormatting.parseRowDate(s) else { return false }
            return date >= startOfToday && date <= end
        }
        let taskEntries: [UpNextEntry] = allTasks.map { .task($0) }

        // Routine occurrences in the window
        let occurrences = RoutineOccurrenceExpander.occurrences(
            routines: routines.filter { propScope == nil || $0.propertyId == propScope },
            from: startOfToday,
            through: end,
            calendar: calendar
        )
        let occurrenceEntries: [UpNextEntry] = occurrences.map { .routineOccurrence($0) }

        return (taskEntries + occurrenceEntries).sorted { $0.date < $1.date }
    }

    func dueLabel() -> String? {
        // Pick the earliest due date across pending decisions; fall back to nil.
        // Phase 70.A1 follow-on F2: year-aware so cross-year dates read
        // unambiguously in the section subheader.
        let dates = pendingDecisions().compactMap {
            TasksV2DateFormatting.parseRowDate($0.nextExpectedDate)
        }
        guard let soonest = dates.min() else { return nil }
        return "Due \(TasksV2DateFormatting.shortDay(soonest))"
    }

    func decisionMeta(for routine: RoutineRow) -> String {
        // Phase 70.A1 follow-on F2 — year-aware caption.
        if let date = TasksV2DateFormatting.parseRowDate(routine.nextExpectedDate) {
            return "Due \(TasksV2DateFormatting.shortDay(date)) · Pick a vendor before service can start."
        }
        return "Pick a vendor before service can start."
    }

    func nextEventLabel(for routine: RoutineRow) -> String? {
        // Phase 70.A1 follow-on F2 — year-aware caption.
        guard let date = TasksV2DateFormatting.parseRowDate(routine.nextExpectedDate) else {
            return routine.activeMonthsSummary
        }
        return TasksV2DateFormatting.shortDay(date)
    }

    // MARK: Vehicle helpers

    func vehicleMeta(for vehicle: VehicleRow) -> String {
        let vm = MaintenanceViewModel.shared
        let pending = vm.tasks.filter {
            $0.vehicleId == vehicle.id &&
            $0.lastCompletedDate == nil &&
            ($0.isArchived ?? false) == false
        }
        let count = pending.count
        let needsShop = vehicleNeedsShop(vehicle)
        if count == 0 {
            return needsShop ? "needs shop" : "all caught up"
        }
        let itemLabel = "\(count) item\(count == 1 ? "" : "s")"
        return needsShop ? "\(itemLabel) · needs shop" : itemLabel
    }

    func vehicleNeedsShop(_ vehicle: VehicleRow) -> Bool {
        // Vehicle-scoped routine missing → needs shop. Phase 66 routines
        // table has scope=='vehicle' rows tied via vehicle_id.
        let hasShopRoutine = routines.contains { routine in
            routine.typedScope == .vehicle &&
            routine.vehicleId == vehicle.id &&
            routine.vendorId != nil
        }
        return !hasShopRoutine
    }

    // MARK: Phase 70 (Tasks v2) — SeasonFeed (single source of truth)

    /// Compose a `SeasonFeed` for the given season + active property scope.
    /// Every Tasks-v2 surface (YearRibbon counts, MiniHero stats, Needs
    /// Your Attention section, This Season's Tasks feed, Active Programs)
    /// reads from a SeasonFeed instance. Ribbon count == row count by
    /// construction — they share the same backing arrays.
    ///
    /// Filtering:
    /// - Property scope: `activePropertyId` (or this method's explicit
    ///   override) restricts to one property; nil means all properties
    ///   in the household (single-property fallback).
    /// - Vehicles excluded: vehicle tasks have their own section, not
    ///   the season feed (different mental model — mileage vs season).
    /// - Active only: lastCompletedDate == nil, isArchived != true.
    ///
    /// Decisions ordering: pending-vendor routines come first (they're
    /// the user's primary "pick a vendor" prompts), then needs-vendor
    /// standalone tasks, then sorted within each bucket by date
    /// (overdue first).
    ///
    /// Programs include both regular active routines AND chez-owned
    /// routines — the v2 design merges them with a salmon Chez pill
    /// rendered inline.
    func seasonFeed(_ season: Season, propertyId: UUID? = nil) -> SeasonFeed {
        let propScope = propertyId ?? self.activePropertyId
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Filter raw tasks once. All subsequent filtering layers on top.
        let allTasks = MaintenanceViewModel.shared.tasks.filter { task in
            if let scope = propScope, task.propertyId != scope { return false }
            guard task.vehicleId == nil else { return false }
            if let last = task.lastCompletedDate, !last.isEmpty { return false }
            if (task.isArchived ?? false) == true { return false }
            // Phase 70.A1 fix: hide bundle children from the standalone
            // feed. Phase 67's reconciler creates child task rows for
            // bundle members (one row per member) — but the children
            // live as inline line items inside the bundle parent card
            // (rendered by `BundleChildList`), never as their own
            // standalone row. Without this filter the verifier sees
            // ghost duplicate rows below every Generator / Water Heater
            // / Garage Door / Painting bundle parent.
            //
            // Detection: lookup the task's template, check if the
            // template has a `bundleId` set. `bundle_parent_task_id`
            // exists on the schema but is never populated by the
            // reconciler — the canonical signal is the template's
            // `bundleId` field. We separately keep the bundle PARENT
            // task itself (its templateId IS the bundleId, so it has
            // no template lookup match in the standard library, but
            // `isBundleId(templateId)` returns true).
            if let templateKey = task.templateId,
               let template = MaintenanceTemplates.template(forKey: templateKey),
               template.bundleId != nil {
                return false
            }
            return true
        }

        // ── Decisions ──────────────────────────────────────────────
        // (a) pending-vendor routines for this season (no Chez routines)
        let routineDecisions = pendingDecisions(scopedTo: season)
            .map { DecisionEntry.routinePendingVendor($0) }
        // (b) standalone tasks needing a vendor pick (find-a-pro variants)
        // Friend feedback (May 2026): exclude chez-owned tasks from the
        // decision queue — once delegated, Chez is making the call, not
        // the homeowner. They surface in `chezHandlingTasks` below and
        // render in the Active Programs section with a Chez pill.
        let taskDecisions = allTasks
            .filter { task in
                task.parentRoutineId == nil &&
                task.assignmentType == "vendor" &&
                task.assignedContractorId == nil &&
                task.isChezOwned != true &&
                isTask(task, in: season) &&
                taskMatchesActiveStatsFilter(task)
            }
            .map { DecisionEntry.taskNeedsVendor($0) }
        let combinedDecisions = (routineDecisions + taskDecisions)
            .sorted { lhs, rhs in
                let lhsDate = lhs.sortDate ?? .distantFuture
                let rhsDate = rhs.sortDate ?? .distantFuture
                return lhsDate < rhsDate
            }

        // ── Programs (active + Chez-owned merged) ──────────────────
        let regularPrograms = activePrograms(scopedTo: season)
        let chezPrograms = chezHandlingPrograms(scopedTo: season)
        let mergedPrograms: [RoutineRow] = {
            var seen: Set<UUID> = []
            var result: [RoutineRow] = []
            for routine in regularPrograms + chezPrograms where !seen.contains(routine.id) {
                seen.insert(routine.id)
                result.append(routine)
            }
            return result
        }()

        // ── This Season's Tasks feed (grouped by month) ─────────────
        // Phase F1: also gate on the active time-window filter so the
        // monthly buckets honor "show only overdue / this week / …"
        let seasonStandaloneTasks = allTasks.filter { task in
            task.parentRoutineId == nil &&
                isTask(task, in: season) &&
                taskMatchesActiveStatsFilter(task)
        }
        // Routine occurrences inside the season's month range.
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let sortedSeasonMonths = season.months.sorted()
        let firstMonth = sortedSeasonMonths.first ?? 1
        let lastMonth = sortedSeasonMonths.last ?? 12
        // Winter spans Dec-Feb (months {12,1,2}). Build a window that
        // covers all of them — for Winter, start in current year's Dec
        // and end the following Feb. Other seasons stay within one year.
        let isWinter = sortedSeasonMonths == [1, 2, 12]
        var startComps = DateComponents()
        var endComps = DateComponents()
        if isWinter {
            startComps.year = currentYear
            startComps.month = 12
            startComps.day = 1
            endComps.year = currentYear + 1
            endComps.month = 3   // exclusive
            endComps.day = 1
        } else {
            startComps.year = currentYear
            startComps.month = firstMonth
            startComps.day = 1
            endComps.year = currentYear
            endComps.month = lastMonth + 1
            endComps.day = 1
        }
        let windowStart = calendar.date(from: startComps) ?? now
        let windowEnd = calendar.date(from: endComps) ?? now
        let occurrences = RoutineOccurrenceExpander.occurrences(
            routines: routines.filter { propScope == nil || $0.propertyId == propScope },
            from: windowStart,
            through: windowEnd.addingTimeInterval(-1),
            calendar: calendar
        )

        // Bucket entries by month.
        var monthBuckets: [Int: [SeasonEntry]] = [:]
        for task in seasonStandaloneTasks {
            let dateString = task.scheduledDate ?? task.nextDueDate
            guard let date = formatter.date(from: dateString) else { continue }
            let month = calendar.component(.month, from: date)
            // Constrain to season's months — isTask already enforces this
            // for tasks with seasonalTiming, but custom user tasks fall
            // through to month bucketing where the date might land outside.
            guard season.months.contains(month) else { continue }
            let entry: SeasonEntry = MaintenanceTemplates.isBundleId(task.templateId)
                ? .bundle(task)
                : .standaloneTask(task)
            monthBuckets[month, default: []].append(entry)
        }
        // Phase 70.A1 fix: routine occurrences are NOT appended to the
        // monthly feed. The summer screenshot showed Blue Fox /
        // Doody Calls / Mosquito & Tick weekly visits flooding June,
        // July, August with 10+ rows per month — burying the actual
        // task work. The Active Programs section at the bottom of the
        // screen lists every active routine ONCE with a "N visits this
        // <season>" caption that communicates the cadence density.
        // Tapping a program row drills into RoutineDetailView where
        // the per-occurrence schedule is visible. The Up Next 14-day
        // strip (planned for 70.A2) will surface the nearest
        // occurrences as a separate forward-looking signal.
        let routineVisitCountInSeason = occurrences.filter { occ in
            season.months.contains(calendar.component(.month, from: occ.date))
        }.count

        // Build sorted MonthSection list. Winter's chronological order is
        // Dec → Jan → Feb (December comes first within the season window);
        // other seasons are simple ascending.
        let monthOrder: [Int] = isWinter ? [12, 1, 2] : sortedSeasonMonths
        let monthSections = monthOrder.compactMap { month -> MonthSection? in
            guard var entries = monthBuckets[month], !entries.isEmpty else { return nil }
            entries.sort { lhs, rhs in
                let lhsDate = lhs.sortDate ?? .distantFuture
                let rhsDate = rhs.sortDate ?? .distantFuture
                return lhsDate < rhsDate
            }
            return MonthSection(month: month, entries: entries)
        }

        let chezTasksInSeason = chezHandlingTasks(scopedTo: season)

        return SeasonFeed(
            season: season,
            decisions: combinedDecisions,
            monthSections: monthSections,
            programs: mergedPrograms,
            chezTasks: chezTasksInSeason,
            routineVisitCount: routineVisitCountInSeason
        )
    }

    // Phase 70.A1.x dropped the `fullYearFeed()` aggregator. The "Show
    // full year" toggle proved noisy in practice — year-round routines
    // dominated the combined view and the user couldn't tell what was
    // truly upcoming vs. ambient. The "Active Routines This Season"
    // card surfaces routine density without flooding the season feed.

    // MARK: Season summaries (for YearRibbon)

    func seasonSummaries(activeSeason: Season) -> [Season: YearRibbonSummary] {
        // Phase 70 (Tasks v2): derive ribbon tile counts from `seasonFeed(_:)`
        // so they MUST match the count of rendered rows. The legacy
        // implementation maintained its own filter logic which diverged from
        // the rendered sections — that's the source of the "ribbon says 30,
        // screen shows 5" bug Phase 70 fixes.
        var result: [Season: YearRibbonSummary] = [:]
        for season in Season.allCases {
            let feed = seasonFeed(season)
            result[season] = YearRibbonSummary(
                totalItems: feed.totalItems,
                actionItems: feed.actionItems
            )
        }
        return result
    }

    func coveredCount(for season: Season, currentSeason: Season) -> Int {
        let scope = (season == currentSeason) ? nil : season
        let total = totalCount(for: season, currentSeason: currentSeason)
        let actions = pendingDecisions(scopedTo: scope).count
        return max(total - actions, 0)
    }

    func totalCount(for season: Season, currentSeason: Season) -> Int {
        let scope = (season == currentSeason) ? nil : season
        let activeProgs = activePrograms(scopedTo: scope).count
        let decisions = pendingDecisions(scopedTo: scope).count
        return activeProgs + decisions
    }

    // MARK: Internal

    /// Decide whether a task belongs in `season`'s tile count.
    ///
    /// Two semantic rules layered on top of the original month bucket:
    ///
    ///   1. Tasks with `parentRoutineId != nil` are routine-managed —
    ///      the routine itself already contributes to the season's
    ///      count, and double-counting both the routine and each of
    ///      its child tasks blew Spring up post-quiz when many monthly
    ///      cadences seeded fresh tasks dated today.
    ///   2. When the template's `seasonalTiming` is set ("Spring",
    ///      "Fall", "Spring/Fall", etc.), prefer it over the raw
    ///      `scheduledDate` month. Sub-annual cadences anchor at
    ///      `today + interval`, so right after a quiz they all land
    ///      in the current season regardless of intent. The seasonal
    ///      timing is what the template author meant.
    ///
    /// Tasks with no template (custom user tasks, AI-generated
    /// follow-ups) fall through to the original month-based bucket.
    private func isTask(_ task: MaintenanceTaskDBRow, in season: Season) -> Bool {
        if task.parentRoutineId != nil { return false }

        // Friend feedback (May 2026) reverses the prior L1 reversion.
        // L1 dropped the year cap so May-2026 Spring tile wouldn't read
        // empty, but the side effect is that March-2027-anchored
        // recurring tasks render under Spring 2026 — confusing
        // ("why is 2027 in This Season?"). Restore the year-aware cap
        // via the existing `dateBelongsTo(season:on:)` helper so each
        // tile shows the CURRENT calendar instance of the season.
        // Empty active tile is handled gracefully by the
        // "Season is wrapped" empty-state copy in the view body.
        let dateString = task.scheduledDate ?? task.nextDueDate
        guard let date = TasksV2DateFormatting.parseRowDate(dateString) else { return false }

        let timingTag = task.seasonalTiming?.trimmingCharacters(in: .whitespacesAndNewlines)
        if timingTag?.lowercased() == "flexible" {
            // Flexible tasks render in their own section, not in a
            // season tile.
            return false
        }

        let tagMatches: Bool = {
            if let timing = timingTag, !timing.isEmpty {
                let labels = timing.split(whereSeparator: { $0 == "/" || $0 == "," })
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                return labels.contains(season.rawValue)
            }
            return season.months.contains(Calendar.current.component(.month, from: date))
        }()
        guard tagMatches else { return false }

        return Self.dateBelongsTo(season: season, on: date)
    }

    /// Phase 70.A1 follow-on H1 — single source of truth for "does this
    /// date belong to THIS year's instance of `season`?" Winter spans
    /// year boundaries (Dec[currentYear] + Jan/Feb[currentYear+1]), so
    /// we treat the Dec→Feb stretch as one continuous Winter window.
    /// Spring/Summer/Fall stay within one calendar year.
    static func dateBelongsTo(
        season: Season,
        on date: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        let currentYear = calendar.component(.year, from: now)
        let dateYear = calendar.component(.year, from: date)
        let dateMonth = calendar.component(.month, from: date)
        let isWinterSeason = season.months.sorted() == [1, 2, 12]
        if isWinterSeason {
            // This winter = Dec of currentYear + Jan/Feb of currentYear+1.
            // Pre-Dec we look back at Jan/Feb of currentYear (winter has
            // half-arrived); from Dec onward we look forward.
            let currentMonth = calendar.component(.month, from: now)
            if currentMonth >= 12 {
                // Dec of current → Feb of next
                if dateMonth == 12 { return dateYear == currentYear }
                if dateMonth == 1 || dateMonth == 2 { return dateYear == currentYear + 1 }
                return false
            } else {
                // Jan-Nov current → "this winter" = the upcoming Dec[currentYear] + Jan/Feb[currentYear+1]
                if dateMonth == 12 { return dateYear == currentYear }
                if dateMonth == 1 || dateMonth == 2 { return dateYear == currentYear + 1 }
                return false
            }
        }
        guard dateYear == currentYear else { return false }
        return season.months.contains(dateMonth)
    }

    /// Phase 70.A1.x: Flexible tasks are season-independent. They render
    /// in a dedicated section between "Needs your attention" and "This
    /// Season's Tasks", regardless of which season tile is active.
    /// Tapping a Flexible row opens QuickSchedulingSheet; once the user
    /// picks a date the row drops out of Flexible and into its picked
    /// month's bucket of the season feed (via the existing seasonalTiming-
    /// vs-scheduledDate filtering in `seasonFeed`).
    ///
    /// Tasks qualify when:
    ///   - `seasonalTiming` equals "Flexible" (case-insensitive)
    ///   - `scheduledDate` is nil (user hasn't placed it yet)
    ///   - `lastCompletedDate` is nil + not archived + not vehicle-scoped
    ///   - not a child of a routine
    ///   - not a bundle child (matches the same template.bundleId !=
    ///     nil check `seasonFeed` uses).
    func flexibleTasks(propertyId: UUID? = nil) -> [MaintenanceTaskDBRow] {
        let propScope = propertyId ?? self.activePropertyId
        return MaintenanceViewModel.shared.tasks.filter { task in
            if let scope = propScope, task.propertyId != scope { return false }
            guard task.vehicleId == nil else { return false }
            if let last = task.lastCompletedDate, !last.isEmpty { return false }
            if (task.isArchived ?? false) == true { return false }
            if task.parentRoutineId != nil { return false }
            if task.scheduledDate != nil { return false }
            // Bundle children are hidden — they live inline under the
            // parent card, not as their own rows. Same predicate the
            // season feed uses for consistency.
            if let templateKey = task.templateId,
               let template = MaintenanceTemplates.template(forKey: templateKey),
               template.bundleId != nil {
                return false
            }
            guard let timing = task.seasonalTiming?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
                  timing == "flexible" else { return false }
            // Phase F1: respect the active time-window filter.
            guard taskMatchesActiveStatsFilter(task) else { return false }
            return true
        }
        .sorted { lhs, rhs in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let lhsDate = formatter.date(from: lhs.nextDueDate) ?? .distantFuture
            let rhsDate = formatter.date(from: rhs.nextDueDate) ?? .distantFuture
            return lhsDate < rhsDate
        }
    }

    /// Phase F1: time-window filter predicate. When no filter is
    /// active, every task passes. When a filter is set, the task's
    /// scheduledDate (preferred) or nextDueDate must fall in the
    /// filter's window. Applied inside `seasonFeed(_:)` (decisions +
    /// monthly buckets) and `flexibleTasks(propertyId:)`.
    func taskMatchesActiveStatsFilter(_ task: MaintenanceTaskDBRow) -> Bool {
        guard let filter = activeStatsFilter else { return true }
        let dateString = task.scheduledDate ?? task.nextDueDate
        return filter.matches(taskDateString: dateString)
    }

    /// Phase F1: per-pill count for the StatsFilterStrip. Counts every
    /// in-season, non-bundle-child, non-vehicle, active task whose
    /// scheduledDate/nextDueDate falls in the pill's window, plus the
    /// Flexible section's tasks. Computed against the active season
    /// scope so the pills move when the user changes seasons.
    func statsFilterCounts(for season: Season, propertyId: UUID? = nil) -> [TasksStatsFilter: Int] {
        let propScope = propertyId ?? self.activePropertyId
        let candidates = MaintenanceViewModel.shared.tasks.filter { task in
            if let scope = propScope, task.propertyId != scope { return false }
            guard task.vehicleId == nil else { return false }
            if let last = task.lastCompletedDate, !last.isEmpty { return false }
            if (task.isArchived ?? false) == true { return false }
            if task.parentRoutineId != nil { return false }
            if let templateKey = task.templateId,
               let template = MaintenanceTemplates.template(forKey: templateKey),
               template.bundleId != nil {
                return false
            }
            // Either a season-anchored task or a Flexible task — both
            // surface in the Tasks v2 feed.
            let timing = task.seasonalTiming?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() ?? ""
            if timing == "flexible" { return true }
            return isTask(task, in: season)
        }

        var counts: [TasksStatsFilter: Int] = [:]
        for filter in TasksStatsFilter.allCases {
            counts[filter] = candidates.filter { task in
                filter.matches(taskDateString: task.scheduledDate ?? task.nextDueDate)
            }.count
        }
        return counts
    }
}

// MARK: - Array helpers

private extension Array where Element == Int {
    /// Does this array contain ANY of the elements in the other set?
    func contains(anyOf other: Set<Int>) -> Bool {
        for element in self where other.contains(element) { return true }
        return false
    }
}

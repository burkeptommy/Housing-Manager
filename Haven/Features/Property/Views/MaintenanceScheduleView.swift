import SwiftUI

/// Phase 66: The legacy `MaintenanceViewMode` enum (timeline / bySystem /
/// byType) is retired — it was never actually read by the view after
/// Phase 56.4 replaced the top-level segmented filter with stats pills,
/// and Phase 56.5 consolidated buckets into state-based "Scheduled" /
/// "To Schedule". Kept as a deprecated shim with only `.timeline` so
/// any stale references still compile while we migrate callers.
@available(*, deprecated, message: "Use MaintenanceLayout or the stats-pill filter instead (Phase 66).")
enum MaintenanceViewMode: String, CaseIterable {
    case timeline = "Timeline"
}

/// Phase 54A: Two top-level layouts for the Maintenance tab. Replaces the
/// separate `ScheduleCalendarView` sheet — "View full schedule" on the
/// dashboard now pushes `MaintenanceScheduleView(initialLayout: .calendar)`
/// instead of a parallel screen with weaker task cards.
///
/// - `list`     — the bucketed UnifiedTaskCard list (existing default).
/// - `calendar` — month-grouped agenda using the same UnifiedTaskCard.
///                Phase 56.4 renames the user-facing label to "Timeline"
///                because this is an agenda, not a grid — the raw value
///                stays `"calendar"` so persisted UserDefaults don't need
///                a migration.
///
/// Phase 55.2: The Phase 54B `.waves` layout was dropped. It never
/// shipped a rendering that paid its own complexity and tended to
/// fight the collapsed-row pattern Phase 55 introduces. Persisted
/// `"waves"` values fall back to `.list` on load.
enum MaintenanceLayout: String, CaseIterable, Identifiable {
    case list = "list"
    case calendar = "calendar"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .list:     return "List"
        case .calendar: return "Timeline"
        }
    }

    var icon: String {
        switch self {
        case .list:     return "list.bullet"
        case .calendar: return "calendar.day.timeline.leading"
        }
    }
}

/// Phase 56.4: Time-window filter applied via tap on the summary pills.
/// Replaces the old All / Mine / Vendor segmented filter — premium task
/// apps (Things 3, Todoist, Apple Reminders, Linear) universally filter
/// by time window, not assignee. Not persisted: resets per session so
/// the default "show all" state is always the starting point.
private enum StatsPillFilter: String, CaseIterable, Identifiable {
    case overdue
    case thisWeek
    case thisMonth
    case later

    var id: String { rawValue }
    var label: String {
        switch self {
        case .overdue: return "Overdue"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .later: return "Later"
        }
    }
}

struct MaintenanceScheduleView: View {
    let prefilterPropertyId: UUID?
    /// Phase 54A: Callers landing users in a specific layout (e.g. the
    /// dashboard "View full schedule" link always jumps into Calendar)
    /// pass the layout up front. Nil means honor the per-property
    /// persisted choice, falling back to `.list`.
    let initialLayout: MaintenanceLayout?
    /// Phase 67 follow-up: when the YearRibbon's season tile pushes
    /// into this view, scroll-anchor the Calendar layout to the first
    /// month of the requested season on appear. Nil leaves the scroll
    /// position alone.
    let scrollToSeason: Season?

    init(
        filterPropertyId: UUID? = nil,
        initialLayout: MaintenanceLayout? = nil,
        scrollToSeason: Season? = nil
    ) {
        self.prefilterPropertyId = filterPropertyId
        self.initialLayout = initialLayout
        self.scrollToSeason = scrollToSeason
    }

    @StateObject private var viewModel = MaintenanceViewModel.shared
    @State private var taskToDelete: MaintenanceTaskDBRow?
    @State private var selectedTask: MaintenanceTaskDBRow?
    @State private var showDeleteConfirm = false
    @State private var showSnooze = false
    @State private var taskToSnooze: MaintenanceTaskDBRow?
    @State private var snoozeDate = Date()
    @State private var showAddTask = false
    @State private var showAddRecurringService = false

    /// Phase 78: structured punch items keyed by `assigned_visit_task_id`.
    /// Loaded once when the schedule view appears + on `.maintenanceTaskChanged`
    /// notifications. Lets `HandymanVisitCard` render its sub-checklist
    /// without N+1 fetches per visit row.
    @State private var punchItemsByVisitTaskId: [UUID: [HandymanPunchItemRow]] = [:]
    @State private var isPerformingHandymanAction = false

    /// Phase 54E: Add cadence sheet state — opens the same CadenceEditSheet
    /// the Property tab uses, so users can create trash day / recycling
    /// Phase 55.3: Add-routine sheet state. Opens `RoutineEditSheet`
    /// natively on the routines table, replacing the Phase 54E
    /// `showAddCadence` / 55.2.9 bridge path through the legacy
    /// cadence sheet.
    @State private var showAddRoutine = false

    /// Phase 55.2/55.3: Routines for the active household. Replaces
    /// the Phase 54E `householdCadences` state. Loaded on appear and
    /// kept in sync via `.routineChanged`.
    @State private var routines: [RoutineRow] = []
    /// Phase 60: loaded once for the year-at-a-glance card so we can
    /// aggregate actual spend + bill counts without re-fetching every
    /// render pass.
    @State private var vendorDocumentsForYear: [DocumentRow] = []
    @State private var serviceRecordsForYear: [ServiceRecordRow] = []

    /// Phase 55.2: Per-routine expansion state for the collapsed-row
    /// pattern. Keyed by `"{routineId}_{yyyy-MM}"` so toggling Trash
    /// for April only affects April, not May. Default: collapsed.
    @State private var expandedRoutineMonths: Set<String> = []

    /// Phase 55.2: Edit sheet routing for a routine. Wired to a no-op
    /// in 55.2 (tap on routine expands or is a no-op on children);
    /// Section 55.3 introduces `RoutineEditSheet` and wires this up.
    @State private var editingRoutine: RoutineRow?

    /// Phase 19l: Per-property collapsed state for the two new buckets.
    /// Defaults to expanded; persisted in UserDefaults under keys
    /// `maintenance.bucket.<propertyId>.personal.collapsed` and
    /// `maintenance.bucket.<propertyId>.vendor.collapsed`.
    @State private var personalBucketCollapsed: Bool = false
    @State private var vendorBucketCollapsed: Bool = false
    /// Phase 95 (gap #42) — bulk-select state. Toggled via the toolbar
    /// "Select" button. While `selectionMode == true`, tapping a task
    /// row toggles its membership in `selectedTaskIds` and opens
    /// nothing. The bottom inset action bar surfaces actions
    /// (Snooze 7d, Snooze 30d, Mark complete) that fan out across
    /// the set. Selection state is session-only — exiting the view
    /// resets it.
    @State private var selectionMode: Bool = false
    @State private var selectedTaskIds: Set<UUID> = []
    @State private var bulkBusy: Bool = false

    /// Phase 56.4: Time-window filter applied by tapping a stats pill.
    /// Nil = no filter (full list). Not persisted — resets per session so
    /// the default is always "show everything." Replaces Build 87's
    /// segmented viewFilter which duplicated the bucket structure.
    @State private var activeStatsPillFilter: StatsPillFilter?

    /// Phase 56.4: Expansion state for the "LATER · N" subsection inside
    /// To Schedule. Collapsed by default when the bucket has 5+
    /// items; the first 7 days of tasks render above it in "TODAY & THIS
    /// WEEK" so users aren't hit with 34 rows at once.
    @State private var laterSubsectionExpanded: Bool = false

    /// Phase 56.4: Routines list sheet — presented when the user taps the
    /// "+ N recurring" footnote under the stats pills. MaintenanceScheduleView
    /// doesn't own a navigationPath, so we present via sheet rather than
    /// pushing onto the enclosing NavigationStack.
    @State private var showRoutinesList: Bool = false

    /// Phase 56.6: Whether the Timeline layout's "ONGOING ROUTINES"
    /// section is rendered as a compact horizontal pill strip (default)
    /// or as full-height routine rows. The compact strip reclaims
    /// ~380pt of viewport — critical for the Timeline reading as "what's
    /// changing month to month" rather than "same 7 items every scroll."
    /// Session-only; resets to collapsed on next launch to match how
    /// Apple Calendar's all-day strip behaves.
    @State private var routineStripExpanded: Bool = false

    /// Phase 56.4: Session dismissal of the HandymanSuggestionCard at the
    /// top of the maintenance tab. Intentionally not persisted — the punch
    /// list is real work that needs scheduling, so "Not now" returns the
    /// card next launch.
    @State private var handymanSuggestionDismissedThisSession: Bool = false

    /// Phase 56.4: Pending punch item count for the active household.
    /// Loaded on appear and refreshed when tasks change. Drives the
    /// HandymanSuggestionCard gate at the top of the tab.
    @State private var handymanPunchItemCount: Int = 0

    /// Phase 56.5: Detected duplicates for the current household.
    /// Loaded in `.task` alongside routines and punch count, refreshed
    /// on `.routineChanged` / `.maintenanceTaskChanged`. Filtered by
    /// the 30-day dismissal store so pairs the user already reviewed
    /// don't re-nag.
    @State private var detectedDuplicates: [DuplicateDetector.Match] = []

    /// Phase 56.5: Session dismissal of the DuplicateReviewBanner.
    /// Intentionally not persisted — duplicates are real work that
    /// needs resolution, so "Not now" returns the banner next launch.
    @State private var duplicateBannerDismissedThisSession: Bool = false

    /// Phase 56.5: Currently-being-reviewed match. When non-nil the
    /// `MaintenanceDuplicateSheet` is presented via `.sheet(item:)`.
    @State private var reviewingMatch: DuplicateDetector.Match?

    /// Phase 55.2: List ↔ Calendar two-state toggle. The dashboard's
    /// "View full schedule" pushes this view with
    /// `initialLayout: .calendar`; everything else picks up the
    /// persisted per-property value and falls through to `.list` for
    /// users who haven't chosen. Persisted under
    /// `maintenance_layout_<propertyId>`. Legacy `"waves"` values are
    /// migrated to `.list` in `loadPersistedLayout`.
    @State private var layout: MaintenanceLayout = .list

    /// Phase 51: Standing appointments (used for recurring task metadata)
    @StateObject private var standingAppointmentVM = StandingAppointmentViewModel.shared
    @State private var showPauseSheet = false
    @State private var appointmentToPause: StandingAppointmentRow?

    /// Phase 19l: Delegate flow state — when the user taps "Have someone
    /// else do it" on a personal card, this captures the task so we can
    /// open a contractor picker sheet.
    @State private var delegatingTask: MaintenanceTaskDBRow?

    /// Phase 19l: Personal → vendor flow uses the same ContractorDirectoryView
    /// the task detail sheet uses, so users don't have to learn a new picker.
    @State private var showDelegateContractorPicker = false

    /// Phase 19n: Find-a-contractor flow state. When the user taps "Find →"
    /// on a needs_vendor task card, this captures the task so we can open
    /// FindLocalVendorSheet with the right (town, state, category) inputs.
    @State private var findVendorTask: MaintenanceTaskDBRow?

    /// Phase 19n: Set when the user opts out of the local vendor flow via
    /// "Add my own instead" — fires the existing ContractorDirectoryView
    /// add sheet so they can type a contractor manually.
    @State private var showManualAddFromFindVendor = false

    /// Build 88: "Add Your Own" flow from the no-vendor card's dual CTA.
    /// Captures the task so the contractor selection can link back to it.
    @State private var addOwnVendorTask: MaintenanceTaskDBRow?

    /// Phase 56.6: Lightweight toast for the card-level "Add to handyman
    /// list" quick action. Uses its own string + overlay rather than
    /// the `viewModel.completionToast` channel because that toast's
    /// template copy ("Next due: …") doesn't fit a punch-list add.
    /// Auto-clears after 2 seconds; no persistence needed.
    @State private var handymanPunchToast: String?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.tasks.isEmpty {
                ProgressView("Loading tasks...")
            } else if viewModel.tasks.isEmpty {
                ContentUnavailableView {
                    Label("Your Maintenance Schedule", systemImage: "wrench.and.screwdriver")
                } description: {
                    VStack(spacing: 8) {
                        Text("Add systems to your property and Chez will create a maintenance schedule for you.")
                        // Phase 55.2: surface routines for users who
                        // land here with zero tasks but could still
                        // configure trash / recycling / school pickup.
                        if routines.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Tip: Set up routines for trash day, recycling, or school pickup")
                                    .font(HavenTypography.uiCaption)
                            }
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(.top, 8)
                        }
                        // Phase 80 — Chez Concierge entry from the
                        // empty schedule. When the user lands here with
                        // nothing on the calendar, the right next step
                        // isn't always "add a system" — sometimes it's
                        // "I don't know what I need, help me." Tom takes
                        // it from there.
                        ChezEntryButton(
                            category: .general,
                            label: "Not sure where to start? Ask Chez",
                            caption: "Chez maps your home, sets up vendors, and builds your schedule.",
                            context: ["_source": "maintenance_schedule_empty"]
                        )
                        .padding(.top, 12)
                    }
                }
            } else {
                // Phase 55.2: Layout is a two-state toggle — List uses
                // bucket grouping, Calendar uses continuous 18-month
                // grouping. The Phase 54B Waves layout was dropped.
                taskContent
            }
        }
        .navigationTitle("Maintenance")
        .toolbar { toolbarContent }
        .refreshable {
            await viewModel.loadTasks()
        }
        // Phase 95 (gap #42): bulk-action bar pinned to bottom while
        // in selection mode. `safeAreaInset` pushes content above the
        // bar so nothing overlaps and the system tab bar stays visible.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bulkActionBar
        }
        .overlay(alignment: .bottom) {
            if let toast = viewModel.completionToast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.success)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(toast.taskTitle) · done!")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Next due: \(toast.nextDueDate)")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    Button {
                        withAnimation { viewModel.completionToast = nil }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                .padding()
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let message = handymanPunchToast {
                // Phase 56.6: Dedicated toast for the card-level
                // "Add to handyman list" quick action. Separate from
                // the completion toast because the "Next due:" second
                // line doesn't fit a punch-list add.
                HStack(spacing: 10) {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(HavenColors.navy700)
                    Text(message)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                }
                .padding()
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: viewModel.completionToast?.id)
        .animation(.easeInOut, value: handymanPunchToast)
        .trackScreen("MaintenanceScheduleView")
        .task {
            viewModel.subscribeToExternalChanges()
            if viewModel.tasks.isEmpty {
                await viewModel.loadTasks()
            }
            if let id = prefilterPropertyId {
                viewModel.filterPropertyId = id
            }
            // Phase 56.4: the Build 87 `initialFilter` parameter was
            // dropped alongside the segmented filter. Tap-to-filter stats
            // pills replace it; callers that previously passed `.vendor`
            // now land users on the full list and let them tap what they
            // want.
            // Phase 19l: load saved collapsed state for the per-property
            // bucket headers. Defaults are false (expanded) when no key
            // exists yet, which matches the plan's default.
            loadBucketCollapsedState()
            // Phase 54A: honor the caller's explicit layout first, then
            // the per-property persisted choice, finally `.list`.
            if let explicit = initialLayout {
                layout = explicit
            } else {
                layout = loadPersistedLayout()
            }
            // Phase 51: Load standing appointments
            if let householdId = viewModel.tasks.first?.householdId {
                await standingAppointmentVM.loadAppointments(householdId: householdId)
            }
            // Phase 55.2: load routines for the active household so
            // virtual occurrences can render in the List and Calendar
            // layouts. Standing appointments continue to drive the
            // existing vendor-card task flow until Section 55.3
            // consolidates everything.
            await loadRoutines()
            // Phase 56.4: load punch item count so the
            // HandymanSuggestionCard has the data it needs to decide
            // whether to surface.
            await loadHandymanPunchCount()
            // Phase 60: load year-to-date stats so the summary card
            // can render.
            await loadYearStats()
            // Phase 56.5: run duplicate detection after routines +
            // tasks are loaded so the banner surfaces on first view.
            await loadDuplicates()
            // Phase 78: load structured punch items so handyman visit
            // rows can render their checklist as subitems instead of a
            // notes blob. One round-trip; bucketed by visit task id.
            await loadHandymanPunchItems()
        }
        .onReceive(NotificationCenter.default.publisher(for: .standingAppointmentChanged)) { _ in
            Task {
                if let householdId = viewModel.tasks.first?.householdId {
                    await standingAppointmentVM.loadAppointments(householdId: householdId)
                }
                await loadRoutines()
            }
        }
        // Phase 55.3: Refresh routine occurrences on any write.
        // `.householdCadenceChanged` was dropped alongside the legacy
        // sheet — the native writer posts `.routineChanged` only.
        //
        // Phase 56.5: Also re-run duplicate detection, since creating
        // or archiving a routine can open/close a duplicate pair.
        .onReceive(NotificationCenter.default.publisher(for: .routineChanged)) { _ in
            Task {
                await loadRoutines()
                await loadDuplicates()
            }
        }
        // Phase 56.5: Re-run duplicate detection when tasks change so
        // the banner reflects new/edited/deleted rows immediately. The
        // viewModel refreshes its own `tasks` array off the same
        // notification, so we wait a tick before reading to avoid a
        // stale scan.
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await loadDuplicates()
                // Phase 78: refresh structured punch items so handyman
                // visit cards reflect newly delegated / completed items.
                await loadHandymanPunchItems()
            }
        }
        // Phase 56.5: dropped the per-property bucket-state reload.
        // Collapse is session-only now, so switching properties keeps
        // the current expand/collapse state rather than reading from
        // a per-property UserDefaults key that no longer exists.
        // Phase 19l: contractor picker sheet for the personal-card delegate
        // tap. Uses the existing ContractorDirectoryView so users get the
        // same picker UX they already know from the task detail sheet.
        //
        // Build 87: when a task is being delegated, pass a DelegationContext
        // so the picker renders the new "FIND A PRO" section above the
        // existing contractor list (Find local pros + Ask Alfred). The
        // legacy onSelect path still works for non-delegation entry points.
        .sheet(isPresented: $showDelegateContractorPicker) {
            NavigationStack {
                ContractorDirectoryView(
                    delegationContext: delegatingTask.map { task in
                        DelegationContext(
                            task: task,
                            systemCategory: viewModel.systems.first(where: { $0.id == task.systemId })?.category,
                            onVendorSelected: { contractor in
                                if let delegatingId = delegatingTask?.id {
                                    Task {
                                        await viewModel.convertToVendorManaged(taskId: delegatingId, contractor: contractor)
                                        await viewModel.loadTasks()
                                    }
                                }
                                showDelegateContractorPicker = false
                                delegatingTask = nil
                            },
                            onFindLocalVendors: {
                                // Dismiss the contractor picker first, then
                                // open FindLocalVendorSheet via the existing
                                // `findVendorTask` plumbing. The .sheet(item:)
                                // binding lower in this view tree will
                                // present FindLocalVendorSheet with the
                                // resolved town/state/category.
                                let task = delegatingTask
                                showDelegateContractorPicker = false
                                delegatingTask = nil
                                if let task {
                                    findVendorTask = task
                                }
                            }
                        )
                    }
                )
            }
        }
        // Phase 19n: find-a-contractor sheet — opens FindLocalVendorSheet
        // with the triggering task's town/state/category. The sheet handles
        // contractor creation + bulk task conversion internally.
        .sheet(item: $findVendorTask) { task in
            findVendorSheet(for: task)
        }
        // Phase 19n: when the user taps "Add my own instead" inside
        // FindLocalVendorSheet, that sheet posts .openManualContractorAdd
        // and dismisses. We catch the notification here and present the
        // existing manual contractor add flow as the next sheet.
        .onReceive(NotificationCenter.default.publisher(for: .openManualContractorAdd)) { _ in
            showManualAddFromFindVendor = true
        }
        .sheet(isPresented: $showManualAddFromFindVendor) {
            NavigationStack {
                ContractorDirectoryView(onSelect: { contractor in
                    // Build 88: if triggered from a no-vendor card's "Add Your Own"
                    // CTA, link the contractor to the task and reframe it.
                    if let task = addOwnVendorTask {
                        Task {
                            await viewModel.convertToVendorManaged(
                                taskId: task.id,
                                contractor: contractor
                            )
                            await viewModel.loadTasks()
                            Haptics.success()
                        }
                        addOwnVendorTask = nil
                    }
                    showManualAddFromFindVendor = false
                })
            }
        }
    }

    /// Phase 19n: Resolve the system category for the triggering task and
    /// present FindLocalVendorSheet. We need: town + state from the property,
    /// system category from the linked home_systems row, and a
    /// human-readable display name for the sheet header copy.
    @ViewBuilder
    private func findVendorSheet(for task: MaintenanceTaskDBRow) -> some View {
        let property = task.propertyId.flatMap { id in
            viewModel.properties.first(where: { $0.id == id })
        }
        let system = task.systemId.flatMap { id in
            viewModel.systems.first(where: { $0.id == id })
        }
        let town = property?.city ?? ""
        let state = property?.state ?? ""
        let category = system?.category ?? "general"
        let display = (system?.category ?? "Local").lowercased()

        if town.isEmpty || state.isEmpty {
            // Defensive fallback — without a town/state we can't search.
            // Fall through to the existing manual add path so the user
            // still has a way forward.
            VStack(spacing: HavenTheme.spacing16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(HavenColors.warning)
                Text("Add a city and state to your property to search local vendors.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                HavenButton(title: "Add my own vendor") {
                    findVendorTask = nil
                    showManualAddFromFindVendor = true
                }
            }
            .padding(HavenTheme.spacing24)
            .presentationDetents([.medium])
        } else {
            FindLocalVendorSheet(
                task: task,
                householdId: task.householdId,
                town: town,
                state: state,
                systemCategory: category,
                categoryDisplayName: display,
                onComplete: {
                    Task { await viewModel.loadTasks() }
                }
            )
        }
    }

    // MARK: - Toolbar (extracted Phase 56.4)
    //
    // Extracted from `body` to keep the parent view tree shallow enough
    // for Swift's type-checker. The three "+" menu actions mirror the
    // three top-level writes in this view (task / recurring service /
    // routine) plus a divider-separated navigation to the handyman
    // punch list flow.

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 16) {
                if selectionMode {
                    Button("Done") {
                        Haptics.light()
                        withAnimation(HavenTheme.animationStandard) {
                            selectionMode = false
                            selectedTaskIds.removeAll()
                        }
                    }
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textPrimary)
                } else {
                    layoutMenu
                    filterMenu
                    selectButton
                    addMenu
                }
            }
        }
    }

    /// Phase 95 (gap #42) — toolbar entry point for bulk-select mode.
    /// Hidden when there are zero tasks (nothing to select).
    private var selectButton: some View {
        Button {
            Haptics.light()
            withAnimation(HavenTheme.animationStandard) {
                selectionMode = true
            }
        } label: {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(HavenColors.textPrimary)
        }
        .disabled(viewModel.tasks.isEmpty)
    }

    /// Phase 95 (gap #42) — bottom action bar for bulk operations.
    /// Renders only in selection mode. Each action loops the
    /// selected set on the existing single-task DatabaseService API
    /// — no new backend surface needed.
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
                    // Min touch target: 44pt (HIG). 12+12 vertical
                    // padding plus the 18pt label font lands ~42pt;
                    // .frame(minHeight: 44) bumps to spec.
                    .padding(.vertical, HavenTheme.spacing12)
                    .frame(minHeight: 44)
                    .background(selectedTaskIds.isEmpty ? HavenColors.beige200 : HavenColors.action)
                    .foregroundStyle(selectedTaskIds.isEmpty ? HavenColors.textTertiary : HavenColors.textOnAction)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton, style: .continuous))
                }
                .disabled(selectedTaskIds.isEmpty || bulkBusy)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, HavenTheme.spacing12)
            .background(HavenColors.surface)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(HavenColors.beige200)
                    .frame(height: 0.5)
            }
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

        let taskMap = Dictionary(uniqueKeysWithValues: viewModel.tasks.map { ($0.id, $0) })
        var changed = 0
        for id in selectedTaskIds {
            guard let task = taskMap[id] else { continue }
            // Anchor against the existing nextDueDate so chained
            // snoozes accumulate rather than collapsing to today + N.
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
        await viewModel.loadTasks()
    }

    @MainActor
    private func bulkComplete() async {
        guard !selectedTaskIds.isEmpty else { return }
        bulkBusy = true
        defer { bulkBusy = false }

        let taskMap = Dictionary(uniqueKeysWithValues: viewModel.tasks.map { ($0.id, $0) })
        var changed = 0
        for id in selectedTaskIds {
            guard let task = taskMap[id] else { continue }
            await viewModel.completeTask(task)
            changed += 1
        }
        Analytics.track(.bulkTasksCompleted, ["count": changed])
        Haptics.success()
        withAnimation(HavenTheme.animationStandard) {
            selectionMode = false
            selectedTaskIds.removeAll()
        }
    }

    /// Phase 95 (gap #42) — overlay applied to every task card
    /// renderer in selection mode. When `selectionMode == true`:
    ///   • Disables the underlying card's hit testing so taps don't
    ///     open detail sheets, sub-flows, or contractor pickers.
    ///   • Renders a 22pt circle / filled-checkmark on the leading
    ///     edge that visually reflects membership.
    ///   • A whole-row tap toggles membership in `selectedTaskIds`.
    /// No-op when selection mode is off.
    @ViewBuilder
    private func selectionOverlay<Content: View>(
        for task: MaintenanceTaskDBRow,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if selectionMode {
            HStack(spacing: HavenTheme.spacing8) {
                Image(systemName: selectedTaskIds.contains(task.id)
                      ? "checkmark.circle.fill"
                      : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(selectedTaskIds.contains(task.id)
                                     ? HavenColors.action
                                     : HavenColors.beige300)
                content()
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.selection()
                if selectedTaskIds.contains(task.id) {
                    selectedTaskIds.remove(task.id)
                } else {
                    selectedTaskIds.insert(task.id)
                }
            }
        } else {
            content()
        }
    }

    private var addMenu: some View {
        Menu {
            Button {
                Haptics.light()
                showAddTask = true
            } label: {
                Label("Add task", systemImage: "checklist")
            }
            Button {
                Haptics.light()
                showAddRecurringService = true
            } label: {
                Label("Add recurring service", systemImage: "calendar.badge.plus")
            }
            Button {
                Haptics.light()
                showAddRoutine = true
            } label: {
                Label("Add custom program", systemImage: "calendar.badge.clock")
            }
            // Phase 56.4: separate "create a thing" actions
            // from the "navigate to a flow" action.
            Divider()
            Button {
                Haptics.light()
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
            } label: {
                Label("Schedule handyman visit", systemImage: "hammer.fill")
            }
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    // MARK: - Property Filter Pills

    private var propertyFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" pill
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.filterPropertyId = nil
                    }
                } label: {
                    HStack(spacing: 5) {
                        if viewModel.properties.count <= 4 {
                            HStack(spacing: 3) {
                                ForEach(viewModel.propertiesWithColors, id: \.property.id) { item in
                                    Circle().fill(item.color).frame(width: 6, height: 6)
                                }
                            }
                        }
                        Text("All")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(viewModel.filterPropertyId == nil ? HavenColors.navy : HavenColors.creamLight)
                    .foregroundStyle(viewModel.filterPropertyId == nil ? .white : HavenColors.textPrimary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            viewModel.filterPropertyId == nil ? Color.clear : HavenColors.beige300,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)

                // One pill per property
                ForEach(viewModel.propertiesWithColors, id: \.property.id) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if viewModel.filterPropertyId == item.property.id {
                                viewModel.filterPropertyId = nil
                            } else {
                                viewModel.filterPropertyId = item.property.id
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            Text(item.property.name)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(viewModel.filterPropertyId == item.property.id ? item.color.opacity(0.15) : HavenColors.creamLight)
                        .foregroundStyle(viewModel.filterPropertyId == item.property.id ? item.color : HavenColors.textPrimary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                viewModel.filterPropertyId == item.property.id ? item.color.opacity(0.4) : HavenColors.beige300,
                                lineWidth: 1
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Layout Menu (Phase 54A)

    /// Phase 54A: Layout toggle for List / Calendar. Waves (Phase 54B)
    /// is intentionally omitted from this menu until the view ships so
    /// users never land on an empty screen. Icon reflects the active
    /// layout so the user can tell which mode they're in without
    /// opening the menu.
    private var layoutMenu: some View {
        // Phase 55.2: Two-state toggle. Tapping swaps between List and
        // Calendar; the icon reflects the OTHER mode so the tap reads
        // as "switch to X". Accessibility label spells out the switch
        // destination for the same reason.
        Button {
            Haptics.selection()
            layout = (layout == .list) ? .calendar : .list
            savePersistedLayout()
        } label: {
            Image(systemName: layout == .list ? "calendar" : "list.bullet")
                .foregroundStyle(HavenColors.textPrimary)
        }
        .accessibilityLabel(layout == .list ? "Switch to calendar view" : "Switch to list view")
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            // Property filter
            if viewModel.properties.count > 1 {
                Picker("Property", selection: $viewModel.filterPropertyId) {
                    Text("All Properties").tag(nil as UUID?)
                    ForEach(viewModel.properties) { p in
                        Text(p.name).tag(p.id as UUID?)
                    }
                }
            }

            // Category filter
            if !viewModel.availableCategories.isEmpty {
                Picker("Category", selection: $viewModel.filterCategory) {
                    Text("All Categories").tag(nil as String?)
                    ForEach(viewModel.availableCategories, id: \.self) { cat in
                        Text(cat).tag(cat as String?)
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    // MARK: - Task Content

    private var taskContent: some View {
        ScrollViewReader { proxy in
        List {
            Section {
                // Property filter pills (only when 2+ properties)
                if viewModel.properties.count > 1 {
                    propertyFilterBar

                    // Color legend when "All" is selected
                    if viewModel.filterPropertyId == nil {
                        HStack(spacing: 16) {
                            ForEach(viewModel.propertiesWithColors, id: \.property.id) { item in
                                HStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(item.color)
                                        .frame(width: 12, height: 3)
                                    Text(item.property.name)
                                        .font(.system(size: 10))
                                        .foregroundStyle(HavenColors.textTertiary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                    }
                }

                // Chez v1: HandymanSuggestionCard removed — Tasks → Handyman
                // is now the canonical destination for the punch list, so
                // surfacing the prompt here too just creates two front doors
                // for the same flow.

                // Phase 56.5: Duplicate review banner. Surfaces when
                // detection found one or more high-confidence matches
                // (same vendor + related category family) that the
                // user hasn't dismissed in the last 30 days. Banner
                // presents the first match; handler auto-opens the
                // next match after each resolution.
                if !detectedDuplicates.isEmpty, !duplicateBannerDismissedThisSession {
                    DuplicateReviewBanner(
                        duplicateCount: detectedDuplicates.count,
                        onReview: {
                            reviewingMatch = detectedDuplicates.first
                        },
                        onDismiss: {
                            duplicateBannerDismissedThisSession = true
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                }

                // Phase 60: Year-at-a-glance card. Surfaces the real
                // scope of vendor coordination Haven is running for
                // the user so the Maintenance tab doesn't read as a
                // sparse to-do list when routines are doing most of
                // the work. Hidden when nothing is tracked yet.
                yearAtAGlanceCard

                // Summary bar (Phase 56.4: the segmented filter is gone —
                // the four stats pills are the primary filter control now.)
                summaryBar

                // Active filters indicator
                if viewModel.filterStatus != .all || viewModel.filterPropertyId != nil || viewModel.filterCategory != nil {
                    activeFiltersBar
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            // Phase 54A/B: swap the inner content based on the layout
            // toggle. List is the existing bucketed view; Calendar
            // groups every visible task by month. Waves is rendered
            // OUTSIDE this List scaffold (see the outer switch in
            // `body`) so it gets a hero-card layout.
            switch layout {
            case .list:
                timelineContent
            case .calendar:
                calendarContent
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(HavenColors.background)
        .sheet(item: $selectedTask, onDismiss: {
            Task { await viewModel.loadTasks() }
        }) { task in
            // Phase 67: Handyman bundle parents (Handyman:spring /
            // Handyman:fall) open the dedicated HandymanVisitDetailView
            // so users land on the full visit surface — what's included,
            // DIY claims, upsells, scheduling. Every other task opens
            // the generic detail sheet.
            Group {
                if let templateId = task.templateId,
                   templateId.hasPrefix("Handyman:") {
                    NavigationStack {
                        HandymanVisitDetailView(
                            parentTask: task,
                            onDismiss: {
                                Task { await viewModel.loadTasks() }
                            }
                        )
                    }
                } else {
                    NavigationStack {
                        MaintenanceTaskDetailSheet(
                            task: task,
                            onTaskCompleted: {
                                viewModel.recentlyCompletedIds.insert(task.id)
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                let nextDate = viewModel.tasks.first(where: { $0.id == task.id })?.nextDueDate ?? ""
                                let displayFormatter = DateFormatter()
                                displayFormatter.dateStyle = .medium
                                if let d = formatter.date(from: nextDate) {
                                    viewModel.completionToast = MaintenanceViewModel.CompletionToast(
                                        taskTitle: task.title,
                                        nextDueDate: displayFormatter.string(from: d)
                                    )
                                }
                                Task { await viewModel.loadTasks() }
                            },
                            onDeleteTask: {
                                taskToDelete = task
                                showDeleteConfirm = true
                            }
                        )
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Not Applicable?", isPresented: $showDeleteConfirm) {
            Button("Remove This Task", role: .destructive) {
                if let task = taskToDelete {
                    Task {
                        await viewModel.deleteTask(task)
                        Haptics.success()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let task = taskToDelete {
                Text("Remove \"\(task.title)\" from your maintenance schedule? Future recurring tasks are not affected.")
            }
        }
        .sheet(isPresented: $showSnooze) {
            NavigationStack {
                DatePicker("Snooze Until", selection: $snoozeDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(HavenColors.navy800)
                    .padding()
                    .navigationTitle("Snooze Task")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showSnooze = false }
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save") {
                                guard let task = taskToSnooze else { return }
                                Task {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd"
                                    _ = try? await DatabaseService.shared.updateMaintenanceTask(
                                        id: task.id,
                                        MaintenanceTaskUpdate(nextDueDate: formatter.string(from: snoozeDate))
                                    )
                                    Haptics.success()
                                    showSnooze = false
                                    await viewModel.loadTasks()
                                }
                            }
                            .foregroundStyle(HavenColors.textPrimary)
                            .fontWeight(.semibold)
                        }
                    }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAddTask) {
            AddMaintenanceTaskSheet(
                properties: viewModel.properties,
                systems: viewModel.systems,
                vehicles: viewModel.vehicles,
                contractors: viewModel.contractors,
                householdUsers: viewModel.users,
                // Build 87 (Home Manager expansion): pass the merged
                // family + staff list so the picker can append the
                // "· Home Manager" suffix to staff users.
                householdFamilyMembers: viewModel.familyMembers,
                viewModel: viewModel
            )
        }
        // Phase 51B: Add Recurring Service sheet
        .sheet(isPresented: $showAddRecurringService) {
            if let property = viewModel.properties.first {
                AddRecurringServiceSheet(
                    propertyId: property.id,
                    householdId: property.householdId,
                    onComplete: {
                        Task { await viewModel.loadTasks() }
                    }
                )
            }
        }
        // Phase 54E: Add cadence sheet — mirrors the Property tab's
        // entry point but reachable from the Maintenance toolbar so
        // users don't have to bounce between tabs to set up weekly
        // cadences. householdId resolution falls back across known
        // sources (tasks → properties) so Day-0 users still get a
        // usable sheet.
        // Phase 55.3: Add-routine sheet. Native writes to the
        // `routines` table — the 55.2.9 legacy write bridge is
        // retired in this release.
        .sheet(isPresented: $showAddRoutine) {
            if let householdId = resolveRoutineHouseholdId() {
                NavigationStack {
                    RoutineEditSheet(
                        householdId: householdId,
                        propertyId: viewModel.filterPropertyId,
                        onSaved: {
                            Task { await loadRoutines() }
                        }
                    )
                }
            } else {
                NavigationStack {
                    ContentUnavailableView {
                        Label("No household yet", systemImage: "house")
                    } description: {
                        Text("Add a property first to set up active programs.")
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showAddRoutine = false }
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                    }
                }
            }
        }
        // Phase 55.3+: routine detail sheet. Tapping a routine should
        // show the program itself first; edit now lives inside the
        // detail screen so every surface behaves consistently.
        .sheet(item: $editingRoutine) { routine in
            if let householdId = resolveRoutineHouseholdId() {
                NavigationStack {
                    RoutineDetailView(
                        routine: routine,
                        householdId: householdId
                    )
                }
            }
        }
        // Phase 56.4: Routines list sheet — presented when the user taps
        // the "+ N recurring" footnote under the stats pills. Uses the
        // same RoutinesListView the Property tab pushes via its
        // dedicated row, so every surface leads to the same place.
        .sheet(isPresented: $showRoutinesList) {
            if let householdId = resolveRoutineHouseholdId() {
                NavigationStack {
                    RoutinesListView(
                        householdId: householdId,
                        propertyId: viewModel.filterPropertyId
                    )
                }
            }
        }
        // Phase 56.5: Duplicate resolution sheet. Presented when the
        // user taps Review on the banner OR when chaining through
        // multiple matches (each resolve auto-opens the next match if
        // any remain).
        .sheet(item: $reviewingMatch) { match in
            // Phase 56.5 patch: pass the current index + total so the
            // sheet shows "2 of 5" in its principal toolbar. The
            // parent owns queue advancement — when the user resolves
            // a match, `handleDuplicateResolution` either swaps
            // `reviewingMatch` to the next match (in-place content
            // change, no dismiss flash) or sets it to nil (sheet
            // dismisses, queue complete).
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
        // Phase 51B: Pause sheet for recurring vendor tasks (via context menu)
        .sheet(isPresented: $showPauseSheet) {
            if let appointment = appointmentToPause {
                PauseAppointmentSheet(
                    appointment: appointment,
                    contractor: contractorFor(appointment),
                    categoryDefault: nil,
                    onPause: { reason, resumeDate in
                        Task {
                            try? await standingAppointmentVM.pauseAppointment(
                                id: appointment.id,
                                reason: reason,
                                autoResumeDate: resumeDate
                            )
                        }
                    }
                )
            }
        }
        // Phase 67 follow-up: when a YearRibbon season tile pushed us
        // here, anchor the calendar to the requested season's first
        // month once the List has rendered. Re-runs whenever the task
        // count changes so a still-loading list doesn't cause a no-op
        // scroll on the first attempt.
        .onChange(of: viewModel.tasks.count) { _, _ in
            scrollToSeasonAnchorIfNeeded(proxy: proxy)
        }
        .onAppear {
            scrollToSeasonAnchorIfNeeded(proxy: proxy)
        }
        }
    }

    /// Phase 67 follow-up: scroll the Calendar layout to the first
    /// month of `scrollToSeason`. No-op when the layout isn't `.calendar`,
    /// when no season was passed in, or when the target month isn't in
    /// the calendar window. Wrapped in a small delay because List has to
    /// finish laying out its sections before the proxy can find the id.
    private func scrollToSeasonAnchorIfNeeded(proxy: ScrollViewProxy) {
        guard let season = scrollToSeason, layout == .calendar else { return }
        guard let key = seasonAnchorMonthKey(for: season) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(HavenTheme.animationStandard) {
                proxy.scrollTo("month-\(key)", anchor: .top)
            }
        }
    }

    /// First month of the requested season WITHIN the calendar's
    /// 18-month window. If we're already inside the season, anchor on
    /// today's month; otherwise walk forward to the next occurrence
    /// of any month in the season. Returns `yyyy-MM` matching
    /// `calendarMonths.key`.
    private func seasonAnchorMonthKey(for season: Season) -> String? {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)
        var anchor = today
        if !season.months.contains(currentMonth) {
            for offset in 1...18 {
                guard let candidate = calendar.date(byAdding: .month, value: offset, to: today) else { continue }
                let m = calendar.component(.month, from: candidate)
                if season.months.contains(m) {
                    anchor = candidate
                    break
                }
            }
        }
        let comps = calendar.dateComponents([.year, .month], from: anchor)
        guard let year = comps.year, let month = comps.month else { return nil }
        return String(format: "%04d-%02d", year, month)
    }

    // MARK: - Phase 51B: Action-based bucket routing

    /// Helper: whether a vendor task is confirmed (scheduled or recurring).
    /// Confirmed tasks need no homeowner action — they're awareness only.
    private func isVendorTaskConfirmed(_ task: MaintenanceTaskDBRow) -> Bool {
        task.scheduledDate != nil || task.standingAppointmentId != nil
    }

    /// YOUR ACTION ITEMS: everything the homeowner needs to act on.
    /// - Personal/either/DIY tasks (unchanged)
    /// - Vendor tasks that need a pro (needsVendor)
    /// - Vendor tasks with a contractor but NOT yet scheduled
    ///
    /// Phase 56.4: Applies the active stats pill filter (Overdue /
    /// This Week / This Month / Later) before returning.
    ///
    /// Phase 66: Tasks whose `parent_routine_id` is set are hidden from
    /// this bucket — they render under their parent routine on the
    /// Maintenance hub instead. Keeps the "one task, one home" invariant
    /// when the user drills down into the Timeline from the hub.
    private var personalBucketTasks: [MaintenanceTaskDBRow] {
        let base = viewModel.filteredTasks.filter { task in
            if task.parentRoutineId != nil { return false }
            let isVendor = task.assignmentType?.lowercased() == "vendor"
            if !isVendor { return true }  // personal/either/DIY → always yours
            // Vendor task: yours only if NOT confirmed
            return !isVendorTaskConfirmed(task)
        }
        return applyStatsFilter(base)
    }

    /// VENDOR-MANAGED: confirmed scheduled visits where no action is needed.
    /// Only includes vendor tasks that have a scheduledDate or
    /// standingAppointmentId.
    ///
    /// Phase 56.4: Applies the active stats pill filter alongside the
    /// personal bucket so both sections respond to a single tap.
    ///
    /// Phase 66: Tasks whose `parent_routine_id` is set are filtered out
    /// for the same reason as the personal bucket — they live under their
    /// parent routine now.
    private var vendorBucketTasks: [MaintenanceTaskDBRow] {
        let base = viewModel.filteredTasks.filter { task in
            if task.parentRoutineId != nil { return false }
            let isVendor = task.assignmentType?.lowercased() == "vendor"
            guard isVendor else { return false }
            return isVendorTaskConfirmed(task)
        }
        return applyStatsFilter(base)
    }

    /// Phase 56.4: Apply the active stats pill filter (if any) to a task
    /// list. Filters by `nextDueDate` against the appropriate time window.
    /// Phase 95 (gap #14): footnote text under the stats pills. Surfaces
    /// the routine-owned task count so users discover where Phase 66
    /// hiding sent their tasks ("they're on the routine — tap to view").
    /// Falls back to the legacy `+ N recurring` shape when there are no
    /// child tasks to expose.
    private func footnoteText(activeRoutineCount: Int, hiddenTaskCount: Int) -> String {
        let routineWord = activeRoutineCount == 1 ? "recurring" : "recurring"
        let routinePart = "+ \(activeRoutineCount) \(routineWord)"
        guard hiddenTaskCount > 0 else { return routinePart }
        let taskWord = hiddenTaskCount == 1 ? "task" : "tasks"
        return "\(routinePart) · \(hiddenTaskCount) \(taskWord) inside"
    }

    private func applyStatsFilter(_ tasks: [MaintenanceTaskDBRow]) -> [MaintenanceTaskDBRow] {
        guard let filter = activeStatsPillFilter else { return tasks }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Calendar.current.startOfDay(for: Date())
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
        let monthEnd = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today

        return tasks.filter { task in
            let dateString = task.scheduledDate ?? task.nextDueDate
            guard let due = formatter.date(from: dateString) else { return false }
            switch filter {
            case .overdue:   return due < today
            case .thisWeek:  return due >= today && due <= weekEnd
            case .thisMonth: return due >= today && due <= monthEnd
            case .later:     return due > monthEnd
            }
        }
    }

    /// Phase 56.4: Tasks in `personalBucketTasks` whose due/scheduled
    /// date lands in the next 7 days. The "TODAY & THIS WEEK" subsection
    /// renders this list inline above a collapsed "LATER · N →" drawer
    /// when the bucket has 5+ items.
    private var personalBucketTodayThisWeek: [MaintenanceTaskDBRow] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Calendar.current.startOfDay(for: Date())
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
        return personalBucketTasks.filter { task in
            let dateString = task.scheduledDate ?? task.nextDueDate
            guard let due = formatter.date(from: dateString) else { return false }
            return due <= weekEnd
        }
    }

    /// Phase 56.4: Tasks in `personalBucketTasks` that fall outside the
    /// next-7-days window. Rendered behind the "LATER · N →" collapsed
    /// subsection header when the bucket has 5+ items.
    private var personalBucketLater: [MaintenanceTaskDBRow] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Calendar.current.startOfDay(for: Date())
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
        return personalBucketTasks.filter { task in
            let dateString = task.scheduledDate ?? task.nextDueDate
            guard let due = formatter.date(from: dateString) else { return true }
            return due > weekEnd
        }
    }

    // Phase 56.5: per-property bucket storage keys are gone — collapse
    // is session-only now. Users who open the tab see their tasks; the
    // prior UserDefaults-backed collapse caused "34 tasks, 0 visible
    // rows" when an accidental or cross-session collapse persisted.
    // Every premium task app resets to expanded on launch.

    /// Phase 54A: per-property persistence key for the List / Timeline
    /// layout toggle. Phase 56.4 dropped the Build 87 viewFilterStorageKey
    /// alongside the segmented filter.
    private var layoutStorageKey: String {
        "maintenance_layout_\(viewModel.filterPropertyId?.uuidString ?? "all")"
    }

    private func loadPersistedLayout() -> MaintenanceLayout {
        // Phase 55.2: Waves dropped. Users who persisted `"waves"` in
        // 54B testing fall forward to List — the closest conceptual
        // match. Explicit `.list` / `.calendar` picks are honored.
        if let raw = UserDefaults.standard.string(forKey: layoutStorageKey) {
            if raw == "waves" { return .list }
            if let stored = MaintenanceLayout(rawValue: raw) {
                return stored
            }
        }
        return .list
    }

    private func savePersistedLayout() {
        UserDefaults.standard.set(layout.rawValue, forKey: layoutStorageKey)
    }

    // MARK: - Phase 55.2: Routine loading + routing

    /// Resolve the householdId for routine routing. Task list is the
    /// primary source; falls back to the properties collection and the
    /// already-loaded routines themselves so Day-0 users or filtered
    /// views still land on a usable sheet.
    private func resolveRoutineHouseholdId() -> UUID? {
        if let id = viewModel.tasks.first?.householdId { return id }
        if let id = viewModel.properties.first?.householdId { return id }
        if let id = routines.first?.householdId { return id }
        return nil
    }

    /// Pull routines for the active household.
    private func loadRoutines() async {
        guard let id = resolveRoutineHouseholdId() else {
            routines = []
            return
        }
        do {
            routines = try await DatabaseService.shared.fetchRoutines(householdId: id)
        } catch {
            routines = []
        }
    }

    /// Phase 60: one-shot fetch of documents + service_records in the
    /// current year so `yearAtAGlanceCard` can show actual coordinated
    /// volume and spend without another round-trip. Runs in parallel
    /// with the rest of the `.task` block.
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

    /// Phase 56.4: Load pending punch item count so the
    /// HandymanSuggestionCard knows whether to surface. Called from the
    /// view's `.task` block alongside `loadRoutines`.
    private func loadHandymanPunchCount() async {
        guard let id = resolveRoutineHouseholdId() else {
            handymanPunchItemCount = 0
            return
        }
        do {
            let items = try await DatabaseService.shared.fetchPendingHandymanPunchItems(householdId: id)
            handymanPunchItemCount = items.count
        } catch {
            handymanPunchItemCount = 0
        }
    }

    /// Phase 56.6: Whether a task is eligible for the inline handyman
    /// quick-add link on its card. Uses the shared routing helper so
    /// maintenance cards, task detail, and system detail all surface
    /// the same handyman-appropriate work.
    private func isHandymanEligible(_ task: MaintenanceTaskDBRow) -> Bool {
        MaintenanceTaskRoutingSupport.isInlineHandymanEligible(task, systems: viewModel.systems)
    }

    /// Phase 78: a task renders as a `HandymanVisitCard` (instead of
    /// the generic `UnifiedTaskCard`) when its `serviceKey == "handyman"`
    /// OR when its `templateId` starts with "Handyman:" (covers ad-hoc
    /// visits created via `create_ad_hoc_visit` on the field side, which
    /// don't carry a template_id but DO surface a punch list).
    private func isHandymanVisit(_ task: MaintenanceTaskDBRow) -> Bool {
        if task.serviceKey == "handyman" { return true }
        if (task.templateId ?? "").hasPrefix("Handyman:") { return true }
        // Backfill heuristic — Phase 78 backfill seeded
        // `assigned_visit_task_id` on items pulled from notes blocks; if
        // any structured punch items reference this task, treat it as a
        // visit.
        return punchItemsByVisitTaskId[task.id]?.isEmpty == false
    }

    /// Phase 78: load all of the household's handyman punch items once
    /// and bucket them by `assigned_visit_task_id`. Called from `.task`
    /// + on `.maintenanceTaskChanged`. One round-trip per refresh.
    /// Resolves the household id from any task in the schedule view —
    /// the maintenance view model doesn't track a single canonical
    /// household, so this avoids threading a new prop through.
    private func loadHandymanPunchItems() async {
        guard let householdId = viewModel.tasks.first?.householdId else { return }
        do {
            let items = try await DatabaseService.shared.fetchAllHandymanPunchItems(householdId: householdId)
            var bucket: [UUID: [HandymanPunchItemRow]] = [:]
            for item in items {
                guard let visitId = item.assignedVisitTaskId else { continue }
                bucket[visitId, default: []].append(item)
            }
            await MainActor.run { punchItemsByVisitTaskId = bucket }
        } catch {
            print("[MaintenanceScheduleView] loadHandymanPunchItems failed: \(error)")
        }
    }

    /// Phase 78: toggles a punch item between pending and done. Hits
    /// the `update_punch_item_status` edge action; on success the
    /// server-side trigger bumps `home_systems.last_service_date` if
    /// the item is system-linked. Optimistically updates the local
    /// bucket so the visit card re-renders immediately.
    private func toggleHandymanPunchItem(_ item: HandymanPunchItemRow) async {
        guard !isPerformingHandymanAction else { return }
        let newStatus = item.isDone ? "pending" : "done"
        await MainActor.run { isPerformingHandymanAction = true }
        defer { Task { await MainActor.run { isPerformingHandymanAction = false } } }
        do {
            _ = try await HavenSupabase.updatePunchItemStatus(itemId: item.id.uuidString, status: newStatus)
            Haptics.light()
            await loadHandymanPunchItems()
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        } catch {
            print("[MaintenanceScheduleView] toggleHandymanPunchItem failed: \(error)")
            Haptics.error()
        }
    }

    /// Phase 56.6: Quick-add a task to the handyman punch list from
    /// its card, bypassing the detail sheet. Checks for a pre-existing
    /// punch item with the same `sourceTaskId` first — if one exists,
    /// surfaces an "Already on handyman list" toast instead of
    /// inserting a duplicate (matches the `HandymanPunchListView`
    /// load-time dedup).
    ///
    /// Does NOT complete the task. Unlike the detail sheet's "just
    /// this time" flow, this card-level action intentionally keeps the
    /// task visible on the schedule — the user hasn't committed to the
    /// handyman handling it yet (the handyman might defer back).
    private func addTaskToHandymanPunchList(_ task: MaintenanceTaskDBRow) async {
        let db = DatabaseService.shared

        // Check for an existing pending punch item with the same
        // source task so a double-tap, or a re-surface across the
        // dashboard + maintenance tab, never produces a duplicate.
        let existing = (try? await db.fetchPendingHandymanPunchItems(householdId: task.householdId)) ?? []
        if existing.contains(where: { $0.sourceTaskId == task.id }) {
            Haptics.light()
            presentHandymanPunchToast("Already on handyman list")
            return
        }

        let insert = MaintenanceTaskRoutingSupport.buildPunchItemInsert(for: task)

        do {
            _ = try await db.createHandymanPunchItem(insert)
            Analytics.track(.handymanPunchItemAdded, [
                "source": "maintenance_task",
                "task_id": task.id.uuidString,
                "entry_point": "card_inline",
            ])
            Haptics.success()
            // Bump the suggestion card's count so the dashboard
            // nudge stays in sync without another fetch.
            handymanPunchItemCount += 1
            presentHandymanPunchToast("Added to handyman list")
        } catch {
            print("[MaintenanceScheduleView] addTaskToHandymanPunchList failed: \(error)")
            Haptics.error()
        }
    }

    /// Phase 56.6: Show a short-lived toast for the card-level handyman
    /// quick-add action. Auto-clears after 2 seconds so we don't need
    /// to manage a separate dismissal button.
    @MainActor
    private func presentHandymanPunchToast(_ message: String) {
        withAnimation { handymanPunchToast = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation { handymanPunchToast = nil }
            }
        }
    }

    /// Phase 56.5: Run duplicate detection on the current household's
    /// routines + tasks. Called from the view's `.task` block and
    /// refreshed on `.routineChanged` / `.maintenanceTaskChanged`.
    /// Uses already-loaded routines, viewModel.tasks, viewModel.systems,
    /// and viewModel.contractors — zero additional DB hits.
    private func loadDuplicates() async {
        let matches = DuplicateDetector.scan(
            routines: routines,
            tasks: viewModel.tasks,
            systems: viewModel.systems,
            contractors: viewModel.contractors
        )
        // Filter out pairs the user dismissed as "not duplicates"
        // within the last 30 days so we don't re-nag.
        let dismissed = DuplicateDismissalStore.recentlyDismissedPairs()
        let filtered = matches.filter { match in
            !dismissed.contains(PairKey(match: match))
        }
        detectedDuplicates = filtered
    }

    /// Phase 56.5: Apply the user's resolution choice for a match.
    /// `keepBoth` records a 30-day dismissal; the keep-variants
    /// archive the losing entity (routines soft-archive via
    /// `archived_at`, tasks hard-delete because the schema has no
    /// soft-delete flag for them). After any write we refresh and
    /// auto-open the next match so the user resolves through the
    /// whole list without closing + reopening the sheet.
    private func handleDuplicateResolution(
        match: DuplicateDetector.Match,
        resolution: MaintenanceDuplicateSheet.Resolution
    ) async {
        do {
            switch resolution {
            case .keepBoth:
                DuplicateDismissalStore.recordDismissal(PairKey(match: match))
                Analytics.track(.duplicateResolved, [
                    "resolution": "keep_both",
                    "confidence": confidenceString(match.confidence),
                ])
            case .keepPrimary:
                try await archiveEntity(kind: match.secondaryKind, id: match.secondary.id)
                Analytics.track(.duplicateResolved, [
                    "resolution": "keep_primary_archive_secondary",
                    "confidence": confidenceString(match.confidence),
                    "archived_kind": match.secondaryKind.rawValue,
                ])
            case .keepSecondary:
                try await archiveEntity(kind: match.primaryKind, id: match.primary.id)
                Analytics.track(.duplicateResolved, [
                    "resolution": "keep_secondary_archive_primary",
                    "confidence": confidenceString(match.confidence),
                    "archived_kind": match.primaryKind.rawValue,
                ])
            }
            Haptics.success()

            // Refresh the underlying data + re-run detection so the
            // banner count reflects the new state.
            await loadRoutines()
            await viewModel.loadTasks()
            await loadDuplicates()

            // Phase 56.5 patch: swap `reviewingMatch` to the next
            // match OR to nil. The sheet never dismisses itself now,
            // so SwiftUI treats this as a content swap on the same
            // sheet (no dismiss/re-present race). Setting nil is
            // what actually closes the sheet when the queue empties.
            await MainActor.run {
                if let next = detectedDuplicates.first {
                    reviewingMatch = next
                } else {
                    reviewingMatch = nil
                }
            }
        } catch {
            print("[DuplicateResolution] failed: \(error)")
            Haptics.error()
        }
    }

    private func archiveEntity(kind: DuplicateDetector.EntityKind, id: UUID) async throws {
        let db = DatabaseService.shared
        switch kind {
        case .routine:
            try await db.archiveRoutine(id: id)
            NotificationCenter.default.post(name: .routineChanged, object: nil)
        case .task:
            // Tasks don't carry an `archived_at` column — hard delete
            // via the existing path. Parent views refresh on the
            // maintenanceTaskChanged notification posted below.
            try await db.deleteMaintenanceTask(id: id)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }
    }

    private func confidenceString(_ confidence: DuplicateDetector.Confidence) -> String {
        switch confidence {
        case .high: return "high"
        case .medium: return "medium"
        case .low: return "low"
        }
    }

    /// Phase 56.4: Whether to show the proactive "Schedule handyman
    /// visit" suggestion. Gates on ≥1 pending punch item, no Handyman
    /// task scheduled in the next 30 days, and no Handyman task
    /// completed in the last 90 days. Mirrors the same logic on
    /// DashboardViewModel so both surfaces stay in sync.
    private var shouldShowHandymanSuggestion: Bool {
        guard handymanPunchItemCount >= 1 else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date()
        let in30Days = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: now) ?? now

        // Any handyman task scheduled in the next 30 days?
        let upcomingHandyman = viewModel.tasks.contains { task in
            guard task.templateId?.hasPrefix("Handyman:") == true else { return false }
            let dateString = task.scheduledDate ?? task.nextDueDate
            guard let due = formatter.date(from: dateString) else { return false }
            return due >= now && due <= in30Days
        }
        if upcomingHandyman { return false }

        // Any handyman task completed in the last 90 days?
        let recentHandyman = viewModel.tasks.contains { task in
            guard task.templateId?.hasPrefix("Handyman:") == true else { return false }
            guard let completed = task.lastCompletedDate.flatMap({ formatter.date(from: $0) }) else { return false }
            return completed > ninetyDaysAgo
        }
        if recentHandyman { return false }

        return true
    }

    /// Phase 55.2: Routine occurrences from today through end of the
    /// current week (Sunday end-of-day). Used by the List layout's
    /// This Week bucket. Honors cadence_type + active_months via
    /// `RoutineOccurrenceExpander`.
    private var thisWeekRoutineOccurrences: [RoutineOccurrence] {
        guard !routines.isEmpty else { return [] }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: start)
        let daysUntilSunday = weekday == 1 ? 0 : (8 - weekday)
        let end = cal.date(byAdding: .day, value: daysUntilSunday, to: start) ?? start
        return RoutineOccurrenceExpander.occurrences(
            routines: routines,
            from: start,
            through: end
        )
    }

    /// Phase 55.2: Resolves the contractor linked to a routine so the
    /// row can render the vendor's logo and company name. Looks up
    /// against `viewModel.contractors` (already loaded), zero extra DB
    /// hits.
    private func contractor(for routine: RoutineRow) -> ContractorRow? {
        guard let id = routine.vendorId else { return nil }
        return viewModel.contractors.first(where: { $0.id == id })
    }

    /// Phase 55.2: Routine occurrences inside a specific month. Used
    /// by the Calendar layout so each visible month shows routine
    /// rows inline with task rows.
    private func routineOccurrences(inMonthKey key: String) -> [RoutineOccurrence] {
        guard !routines.isEmpty else { return [] }
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]) else { return [] }
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let monthStart = cal.date(from: comps),
              let monthRange = cal.range(of: .day, in: .month, for: monthStart) else {
            return []
        }
        comps.day = monthRange.count
        guard let monthEnd = cal.date(from: comps) else { return [] }
        return RoutineOccurrenceExpander.occurrences(
            routines: routines,
            from: monthStart,
            through: monthEnd
        )
    }

    /// Phase 55.2: expansion-state key per routine per month.
    private func routineExpansionKey(routineId: UUID, monthKey: String) -> String {
        "\(routineId.uuidString)_\(monthKey)"
    }

    private func toggleRoutineExpansion(_ key: String) {
        if expandedRoutineMonths.contains(key) {
            expandedRoutineMonths.remove(key)
        } else {
            expandedRoutineMonths.insert(key)
        }
        Haptics.selection()
    }

    /// Phase 56.5: Reset collapse state to expanded on every view
    /// lifecycle entry. Session-only collapse — persisted collapse
    /// across launches caused the "34 tasks, 0 visible rows" bug.
    /// Every premium task app (Things 3, Todoist, Apple Reminders,
    /// Linear, Apple Mail) resets to expanded on launch; collapse is
    /// for within-session navigation, not a permanent preference.
    private func loadBucketCollapsedState() {
        personalBucketCollapsed = false
        vendorBucketCollapsed = false
    }

    private func togglePersonalBucket() {
        withAnimation(HavenTheme.animationStandard) {
            personalBucketCollapsed.toggle()
        }
        // Phase 56.5: session-only — no UserDefaults write
        Haptics.selection()
    }

    private func toggleVendorBucket() {
        withAnimation(HavenTheme.animationStandard) {
            vendorBucketCollapsed.toggle()
        }
        // Phase 56.5: session-only — no UserDefaults write
        Haptics.selection()
    }

    // MARK: - Timeline Content

    /// Phase 55.2: Pinned routines section at the top of the List
    /// layout. Collapses each routine into a single summary row
    /// ("Trash · Weekly · 1x this week ›") instead of one row per
    /// occurrence — fixes the Phase 54E noise where an annual week
    /// of trash + recycling + compost stacked five rows. Tap a
    /// collapsed row to expand into individual-day children.
    /// Skipped on `.vendor` filter because routines aren't
    /// vendor-scheduled in the task sense.
    @ViewBuilder
    private var thisWeekRoutinesSection: some View {
        let occurrences = thisWeekRoutineOccurrences
        let grouped = Dictionary(grouping: occurrences, by: { $0.routineId })
        let visibleRoutines = routines
            .filter { grouped[$0.id] != nil }
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
        if !visibleRoutines.isEmpty {
            Section {
                VStack(spacing: 6) {
                    ForEach(visibleRoutines) { routine in
                        routineCollapsedBlock(
                            routine: routine,
                            occurrences: grouped[routine.id] ?? [],
                            monthKey: currentWeekKey(),
                            windowLabel: "this week"
                        )
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            } header: {
                HStack(spacing: 8) {
                    Text("THIS WEEK'S ROUTINES")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .tracking(1.5)
                    Text("\u{00B7}")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("\(visibleRoutines.count)")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                }
            }
        }
    }

    /// Phase 55.2: Renders a single routine as a collapsed summary
    /// row + optional expanded children beneath it. Shared between
    /// the List layout's This Week bucket and the Calendar layout's
    /// per-month sections.
    @ViewBuilder
    private func routineCollapsedBlock(
        routine: RoutineRow,
        occurrences: [RoutineOccurrence],
        monthKey: String,
        windowLabel: String
    ) -> some View {
        let key = routineExpansionKey(routineId: routine.id, monthKey: monthKey)
        let isExpanded = expandedRoutineMonths.contains(key)
        let linkedContractor = contractor(for: routine)
        VStack(spacing: 4) {
            RoutineOccurrenceRow(
                routine: routine,
                display: .collapsedMonth(
                    occurrenceCount: occurrences.count,
                    windowLabel: windowLabel
                ),
                contractor: linkedContractor,
                onTap: { editingRoutine = routine },
                onExpandToggle: { toggleRoutineExpansion(key) }
            )
            if isExpanded {
                ForEach(occurrences) { occurrence in
                    RoutineOccurrenceRow(
                        routine: routine,
                        display: .expandedChild(date: occurrence.date),
                        contractor: linkedContractor,
                        onTap: { editingRoutine = routine }
                    )
                    .padding(.leading, 24)
                }
            }
        }
    }

    /// "yyyy-MM" key for the current calendar month. Used as the
    /// expansion-state partition for the This Week routine section.
    private func currentWeekKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.timeZone = Calendar.current.timeZone
        return "thisweek_" + f.string(from: Date())
    }

    @ViewBuilder
    private var timelineContent: some View {
        // Phase 60: Next 30 days agenda. Mixes upcoming vendor tasks
        // with routine occurrences in one chronological list so the
        // user sees "Blue Fox Wed · Renata Fri · Tyler Heating Apr 23"
        // as a concrete weekly drumbeat instead of seven invisible
        // routines tucked behind a strip. Pinned above the routines
        // section because "what's happening this week/month" is more
        // actionable than "what routines exist."
        nextThirtyDaysSection

        // Phase 59: swap `thisWeekRoutinesSection` (which only surfaced
        // routines whose occurrences happened to land in the current
        // week) for the Timeline view's pinned pill strip. Users reported
        // that a household with 7 standing routines might only see 2 of
        // them because the other 5 were biweekly / monthly / inactive
        // this week — which made routines feel hidden. The pill strip
        // shows every active routine as a compact capsule that taps into
        // the edit sheet; the chevron header expands the strip into the
        // full-card treatment for a more detailed read. Same component
        // used by the Calendar layout so the two layouts feel aligned.
        timelineRoutinesPinnedSection

        if viewModel.filterStatus == .all {
            // Phase 19l: two-bucket grouping. Personal/either tasks first,
            // then vendor-managed. Tasks within each group keep their date
            // sort (overdue floats to the top because earlier dates sort
            // first).
            //
            // Phase 56.4: the Build 87 `.mine`/`.vendor` collapse modes
            // are gone — tap a stats pill for a time-window filter
            // instead. Both buckets render unconditionally, both stay
            // collapsible.
            //
            // Phase 50: Vendor schedule leads — even DIY users see
            // their service visits at the top of the screen so the
            // list functions as a coordination dashboard first.
            bucketSection(
                title: "Scheduled",
                count: vendorBucketTasks.count,
                isCollapsed: vendorBucketCollapsed,
                onToggle: toggleVendorBucket,
                tasks: vendorBucketTasks,
                emptyCopy: "Nothing on the calendar yet.",
                showChevron: true,
                subtitle: vendorBucketTasks.contains(where: { $0.needsVendor == true })
                    ? "Tap a card to assign a vendor or find a local pro."
                    : nil
            )
            personalBucketBody
        } else {
            Section {
                ForEach(viewModel.filteredTasks) { task in
                    // Build 91: outer .swipeActions removed — the inner
                    // swipe inside `maintenanceRow` already provides the
                    // canonical Delete + Snooze (or Skip for standing
                    // appointments) actions. Stacking modifiers caused
                    // SwiftUI to render two Delete buttons.
                    maintenanceRow(task)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
        }
    }

    // MARK: - Calendar Content (Phase 55.2)

    /// Phase 56.4: Timeline (née "Calendar") agenda. Routines no longer
    /// repeat in every month — they sit in one pinned "ONGOING ROUTINES"
    /// section at the top so scanning forward actually shows what's
    /// changing month to month. Months with no task rows are hidden
    /// entirely (the pre-56.4 behavior of surfacing empty months for
    /// routine occurrences is gone alongside the per-month repetition).
    ///
    /// Each task month uses the same `maintenanceRow` as the List layout
    /// so vendor logos, priority pills, and Schedule / Skip actions stay
    /// identical across layouts.
    @ViewBuilder
    private var calendarContent: some View {
        timelineRoutinesPinnedSection

        let months = calendarMonths

        ForEach(months, id: \.key) { month in
            if !month.tasks.isEmpty {
                Section {
                    ForEach(month.tasks) { task in
                        maintenanceRow(task)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                } header: {
                    monthHeader(month)
                        .id("month-\(month.key)")
                }
            }
        }

        // Empty-state only fires when no month has tasks AND no routines
        // are active. Pinned routines prevent this in practice for
        // quiz-completed households; the safety net remains for edge
        // cases (filtered-by-pill scopes with zero matches).
        let anyTasks = months.contains { !$0.tasks.isEmpty }
        let anyRoutines = !routines.contains { !$0.isPaused && $0.archivedAt == nil } ? false : true
        if !anyTasks && !anyRoutines {
            Section {
                ContentUnavailableView(
                    "Nothing scheduled",
                    systemImage: "calendar",
                    description: Text("Your maintenance calendar is clear for the tasks matching this filter.")
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
    }

    /// Phase 56.6: Pinned routines block at the top of the Timeline
    /// layout. Default rendering is a compact horizontal scroll strip
    /// (~44pt tall) — Apple Calendar and Google Calendar Schedule both
    /// treat recurring / all-day items as compressed strips in
    /// chronological views. A pre-56.6 full-card list consumed ~380pt
    /// of viewport before the first actionable task, inverting the
    /// hierarchy of a view meant for scanning upcoming work.
    ///
    /// The section header doubles as an expand toggle — tap anywhere on
    /// the header to swap between strip (compact pills) and expanded
    /// (full `RoutineOccurrenceRow` cards) treatments. Session-only,
    /// so the next Maintenance-tab appearance starts compact.
    @ViewBuilder
    private var timelineRoutinesPinnedSection: some View {
        let active = routines
            .filter { !$0.isPaused && $0.archivedAt == nil }
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
        if !active.isEmpty {
            Section {
                if routineStripExpanded {
                    // Expanded — full-card rows, same treatment the
                    // 56.4 section used. Only shows after the user
                    // opts in via the header chevron so the default
                    // viewport stays tight.
                    VStack(spacing: 6) {
                        ForEach(active) { routine in
                            let linkedContractor = contractor(for: routine)
                            let nextDate = RoutineOccurrenceExpander.nextOccurrence(routine: routine) ?? Date()
                            RoutineOccurrenceRow(
                                routine: routine,
                                display: .singleOccurrence(date: nextDate),
                                contractor: linkedContractor,
                                onTap: { editingRoutine = routine }
                            )
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                } else {
                    // Compact — horizontal pill strip. Tap a pill to
                    // edit that routine; tap the header chevron to
                    // expand into full rows.
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(active) { routine in
                                routineStripPill(routine)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                }
            } header: {
                Button {
                    withAnimation(HavenTheme.animationStandard) {
                        routineStripExpanded.toggle()
                    }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 8) {
                        Text("ONGOING ROUTINES")
                            .font(HavenTypography.uiSectionHeader)
                            .foregroundStyle(HavenColors.textTertiary)
                            .tracking(1.5)
                        Text("\u{00B7}")
                            .font(HavenTypography.uiSectionHeader)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("\(active.count)")
                            .font(HavenTypography.uiSectionHeader)
                            .foregroundStyle(HavenColors.textTertiary)
                        Spacer()
                        Image(systemName: routineStripExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Phase 56.6: A single routine rendered as a compact pill in the
    /// Timeline layout's horizontal scroll strip. ~44pt tall, shows
    /// the routine icon (`routine.resolvedIcon`, same source
    /// `RoutineOccurrenceRow` uses) + the routine label + a small
    /// vendor-initial circle when a contractor is linked. Tapping opens
    /// the edit sheet — matches the full-row behavior so the user
    /// doesn't have to learn two gestures.
    ///
    /// Visual reference: Apple Calendar's all-day event strip rendered
    /// in Haven's cream/navy palette rather than the category color
    /// wash iOS uses.
    private func routineStripPill(_ routine: RoutineRow) -> some View {
        let linkedContractor = contractor(for: routine)
        return Button {
            editingRoutine = routine
        } label: {
            HStack(spacing: 6) {
                Image(systemName: routine.resolvedIcon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                // BUG-014 fix: `.truncationMode(.tail)` forces ellipsis
                // on overflow instead of mid-word cutoff. Prior render
                // showed "Pick a pro for mosquito and tick sprayir"
                // with no indication the label was truncated. Also caps
                // the pill's width so long routine labels don't push
                // subsequent pills off-screen.
                Text(routine.presentationLabel)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 180, alignment: .leading)
                if let contractor = linkedContractor {
                    Text(contractor.companyName.prefix(1).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(HavenColors.navy)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(HavenColors.creamLight)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(HavenColors.beige300, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    /// Phase 56.4: Timeline month header. Hides the "X tasks" count
    /// label when only one task renders below — with a single card in
    /// view the count is self-evident and reading "1 task" on six
    /// consecutive month headers turns into boilerplate.
    private func monthHeader(_ month: (key: String, label: String, tasks: [MaintenanceTaskDBRow])) -> some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(HavenColors.navy700)
                .font(.caption)
            Text(month.label)
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
                .textCase(.uppercase)
                .tracking(1.5)
            Spacer()
            if month.tasks.count >= 2 {
                Text("\(month.tasks.count) tasks")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.navy700)
            }
        }
    }

    /// Phase 55.2: Continuous month window for the Calendar layout.
    /// Renders the current month plus the next 17 (18 total) so
    /// seasonal routines like snow removal in January stay visible
    /// from April. Each month entry includes the tasks that land in
    /// it; routines are fetched separately at render time because
    /// they don't have a stored date.
    private var calendarMonths: [(key: String, label: String, tasks: [MaintenanceTaskDBRow])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let monthLabel = DateFormatter()
        monthLabel.dateFormat = "LLLL yyyy"

        // Phase 56.4: calendar uses stats-pill-filtered data so tapping
        // "This Month" in the summary bar scopes the Timeline view the
        // same way it scopes the List view.
        let base = applyStatsFilter(viewModel.filteredTasks)
        var tasksByKey: [String: [MaintenanceTaskDBRow]] = [:]
        for task in base {
            let dateString = task.scheduledDate ?? task.nextDueDate
            guard let date = formatter.date(from: dateString) else { continue }
            let comps = Calendar.current.dateComponents([.year, .month], from: date)
            guard let year = comps.year, let month = comps.month else { continue }
            let key = String(format: "%04d-%02d", year, month)
            tasksByKey[key, default: []].append(task)
        }

        let calendar = Calendar.current
        let today = Date()
        var monthsOut: [(key: String, label: String, tasks: [MaintenanceTaskDBRow])] = []
        for offset in 0..<18 {
            guard let monthAnchor = calendar.date(byAdding: .month, value: offset, to: today) else { continue }
            let comps = calendar.dateComponents([.year, .month], from: monthAnchor)
            guard let year = comps.year, let month = comps.month else { continue }
            let key = String(format: "%04d-%02d", year, month)
            let label = monthLabel.string(from: calendar.date(from: comps) ?? monthAnchor)
            let tasks = (tasksByKey[key] ?? []).sorted { lhs, rhs in
                let lhsDate = formatter.date(from: lhs.scheduledDate ?? lhs.nextDueDate) ?? .distantFuture
                let rhsDate = formatter.date(from: rhs.scheduledDate ?? rhs.nextDueDate) ?? .distantFuture
                return lhsDate < rhsDate
            }
            monthsOut.append((key: key, label: label, tasks: tasks))
        }
        return monthsOut
    }

    // MARK: - By System Content

    @ViewBuilder
    private var bySystemContent: some View {
        ForEach(viewModel.tasksBySystem, id: \.systemName) { group in
            Section {
                ForEach(group.tasks) { task in
                    // Build 91: outer .swipeActions removed (see filteredTasks
                    // section above). The inner swipe in `maintenanceRow`
                    // is the single source of trailing actions.
                    maintenanceRow(task)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            } header: {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(HavenColors.navy700)
                        .font(.caption)
                    Text(group.systemName)
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(1.5)

                    if viewModel.properties.count > 1, let firstTask = group.tasks.first, let propId = firstTask.propertyId {
                        Circle()
                            .fill(viewModel.propertyColor(for: propId))
                            .frame(width: 6, height: 6)
                        Text(viewModel.propertyName(for: propId))
                            .font(.system(size: 10))
                            .foregroundStyle(viewModel.propertyColor(for: propId))
                    }

                    Spacer()
                    Text("\(group.tasks.count)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.navy700)
                }
            }
        }
    }

    // MARK: - By Type Content

    @ViewBuilder
    private var byTypeContent: some View {
        ForEach(viewModel.tasksByType, id: \.type) { group in
            Section {
                ForEach(group.tasks) { task in
                    // Build 91: outer .swipeActions removed (single source
                    // of trailing actions lives inside `maintenanceRow`).
                    maintenanceRow(task)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            } header: {
                HStack {
                    Image(systemName: group.type.icon)
                        .foregroundStyle(group.type.color)
                        .font(.caption)
                    Text(group.type.rawValue)
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    Spacer()
                    Text("\(group.tasks.count)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(group.type.color)
                }
            }
        }
    }

    // MARK: - Summary Bar (Phase 56.4)

    // MARK: - Phase 60 Year Summary + Next 30 Days

    /// Scope of work Haven is coordinating year-to-date. Not a guess —
    /// rolls up real completed tasks, service_records, and document
    /// invoices. Future visits come from routine expansion over the
    /// remaining year window.
    private struct YearSummary {
        let completedVisits: Int
        let upcomingVisits: Int
        let spendYTD: Double
        let billsReceived: Int
    }

    private var yearSummary: YearSummary {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current
        let now = Date()
        let yearStart = cal.date(from: cal.dateComponents([.year], from: now)) ?? Date.distantPast
        let yearEnd = cal.date(byAdding: .year, value: 1, to: yearStart) ?? now

        // Completed: service_records this year + completed tasks this year
        // (dedup: a task with last_completed_date tied to a service_record
        // via invoice_document_id shouldn't double-count).
        var completedVisits = serviceRecordsForYear.count
        let recordDocIds = Set(serviceRecordsForYear.compactMap { $0.invoiceDocumentId })
        for task in viewModel.tasks {
            guard let last = task.lastCompletedDate,
                  !last.isEmpty,
                  last >= fmt.string(from: yearStart) else { continue }
            // Don't double-count if this task is already represented by
            // a service record row.
            if let linkedDoc = recordDocIds.first(where: { _ in false }) {
                _ = linkedDoc
            }
            completedVisits += 1
        }

        // Upcoming: scheduled tasks in remainder of year + routine
        // occurrences from now through year-end.
        var upcomingVisits = 0
        for task in viewModel.tasks where task.isArchived != true {
            let target = task.scheduledDate ?? task.nextDueDate
            guard target >= fmt.string(from: now),
                  target <= fmt.string(from: yearEnd) else { continue }
            upcomingVisits += 1
        }
        let routineOccurrences = RoutineOccurrenceExpander.occurrences(
            routines: routines,
            from: now,
            through: yearEnd
        )
        upcomingVisits += routineOccurrences.count

        // Spend YTD: sum of invoice_amount on vendorDocumentsForYear,
        // plus service_record.cost for records whose invoice isn't in
        // that set (dedup).
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

        let bills = vendorDocumentsForYear.filter { $0.invoiceAmount != nil }.count

        return YearSummary(
            completedVisits: completedVisits,
            upcomingVisits: upcomingVisits,
            spendYTD: spend,
            billsReceived: bills
        )
    }

    /// Compact currency string ("$450" / "$4.3k" / "$12k").
    private func compactCurrency(_ value: Double) -> String {
        if value >= 1000 {
            let thousands = value / 1000
            if thousands >= 10 {
                return String(format: "$%.0fk", thousands)
            }
            return String(format: "$%.1fk", thousands)
        }
        return String(format: "$%.0f", value)
    }

    /// Phase 60: surfaces the coordinated scope at the top of the tab
    /// so the Maintenance surface reads as "Chez is running 220+
    /// interactions/year for you" instead of a sparse to-do list.
    /// Hidden when the user has nothing tracked yet.
    private var yearAtAGlanceCard: some View {
        let summary = yearSummary
        let totalTracked = summary.completedVisits + summary.upcomingVisits
        return Group {
            if totalTracked > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(totalTracked)")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("vendor visits this year")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    HStack(spacing: 6) {
                        if summary.completedVisits > 0 {
                            statChip(label: "\(summary.completedVisits) completed", color: HavenColors.success)
                        }
                        if summary.upcomingVisits > 0 {
                            statChip(label: "\(summary.upcomingVisits) upcoming", color: HavenColors.navy700)
                        }
                        if summary.spendYTD > 0 {
                            statChip(label: "\(compactCurrency(summary.spendYTD)) spent", color: HavenColors.navy700)
                        }
                        if summary.billsReceived > 0 {
                            statChip(label: "\(summary.billsReceived) bill\(summary.billsReceived == 1 ? "" : "s")", color: HavenColors.navy700)
                        }
                    }
                }
                .padding(HavenTheme.spacing12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
        }
    }

    private func statChip(label: String, color: Color) -> some View {
        Text(label)
            .font(HavenTypography.uiCaption)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.08))
            .clipShape(Capsule())
    }

    // --- Next 30 days agenda ---

    private enum AgendaItem: Identifiable {
        case task(MaintenanceTaskDBRow)
        case routineOccurrence(RoutineOccurrence, RoutineRow)

        var id: String {
            switch self {
            case .task(let t): return "task-\(t.id.uuidString)"
            case .routineOccurrence(let o, _): return "routine-\(o.id)"
            }
        }

        var date: Date {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            switch self {
            case .task(let t):
                let s = t.scheduledDate ?? t.nextDueDate
                return fmt.date(from: s) ?? Date.distantFuture
            case .routineOccurrence(let o, _):
                return o.date
            }
        }
    }

    private var thirtyDayAgenda: [AgendaItem] {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        guard let end = cal.date(byAdding: .day, value: 30, to: now) else { return [] }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let nowStr = fmt.string(from: now)
        let endStr = fmt.string(from: end)

        var items: [AgendaItem] = []

        for task in viewModel.tasks where task.isArchived != true {
            let target = task.scheduledDate ?? task.nextDueDate
            guard target >= nowStr, target <= endStr else { continue }
            items.append(.task(task))
        }

        let occurrences = RoutineOccurrenceExpander.occurrences(
            routines: routines,
            from: now,
            through: end
        )
        let routineById = Dictionary(uniqueKeysWithValues: routines.map { ($0.id, $0) })
        for occ in occurrences {
            guard let routine = routineById[occ.routineId] else { continue }
            items.append(.routineOccurrence(occ, routine))
        }

        return items.sorted { $0.date < $1.date }
    }

    @ViewBuilder
    private var nextThirtyDaysSection: some View {
        let agenda = thirtyDayAgenda
        if !agenda.isEmpty {
            Section {
                VStack(spacing: 6) {
                    ForEach(agenda) { item in
                        agendaRow(item)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            } header: {
                HStack(spacing: 8) {
                    Text("NEXT 30 DAYS")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .tracking(1.5)
                    Text("\u{00B7}")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("\(agenda.count)")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private func agendaRow(_ item: AgendaItem) -> some View {
        let dayFmt: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "EEE MMM d"
            return f
        }()
        switch item {
        case .task(let task):
            Button {
                selectedTask = task
            } label: {
                HStack(spacing: 10) {
                    Text(dayFmt.string(from: item.date))
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(width: 90, alignment: .leading)
                    let contractor = viewModel.contractors.first { $0.id == task.assignedContractorId }
                    if let contractor {
                        VendorLogoView(contractor: contractor, size: 22)
                    } else {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 22, height: 22)
                            .background(HavenColors.beige200)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    Text(task.title)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if task.scheduledDate != nil {
                        Text("booked")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.success)
                    }
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        case .routineOccurrence(_, let routine):
            Button {
                editingRoutine = routine
            } label: {
                HStack(spacing: 10) {
                    Text(dayFmt.string(from: item.date))
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(width: 90, alignment: .leading)
                    let contractor = contractor(for: routine)
                    if let contractor {
                        VendorLogoView(contractor: contractor, size: 22)
                    } else {
                        Image(systemName: routine.resolvedIcon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 22, height: 22)
                            .background(HavenColors.beige200)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    Text(routine.presentationLabel)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text("routine")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var summaryBar: some View {
        // Phase 56.4: Stats pills are now the primary filter control for
        // the screen. Counts are raw (no segmented-filter overlay) — the
        // user sees the true total overdue/upcoming load and taps a pill
        // to zoom in. The pre-56.4 "respect viewFilter" math was dropped
        // with the segmented filter.
        let overdue = viewModel.overdueTasks
        let thisWeek = viewModel.dueThisWeekTasks
        let thisMonth = viewModel.dueThisMonthTasks
        let later = viewModel.upcomingTasks
        // Phase 55.2: count active routines (not occurrences) so the
        // footnote reads "8 recurring" regardless of how many times
        // they fire. Paused/archived rows excluded for consistency
        // with what the schedule actually renders.
        let activeRoutineCount = routines.filter { !$0.isPaused && $0.archivedAt == nil }.count
        // Phase 95 (gap #14): count tasks the Phase 66 hiding rule pulls
        // out of the bucket so users understand the delta. "Why don't
        // I see my Petro tune-up here? It moved into the routine."
        let routineOwnedTaskCount = viewModel.tasks.filter { task in
            task.parentRoutineId != nil && task.archivedAt == nil
        }.count

        return VStack(spacing: 8) {
            // Phase 56.4: Tap-to-filter stats pills. Count = 0 pills are
            // disabled; tapping the active pill clears the filter.
            HStack(spacing: 0) {
                summaryPill(
                    filter: .overdue,
                    count: overdue.count,
                    accentColor: overdue.count > 0 ? HavenColors.critical : HavenColors.textPrimary
                )
                summaryPill(
                    filter: .thisWeek,
                    count: thisWeek.count,
                    accentColor: HavenColors.textPrimary
                )
                summaryPill(
                    filter: .thisMonth,
                    count: thisMonth.count,
                    accentColor: HavenColors.textPrimary
                )
                summaryPill(
                    filter: .later,
                    count: later.count,
                    accentColor: HavenColors.textPrimary
                )
            }
            .padding(4)
            .background(HavenColors.cream)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))

            // Phase 56.4: Active filter caption with a Clear affordance.
            // Lives right below the pills so the user can tell at a glance
            // that the list is scoped and how to return to the full view.
            if let active = activeStatsPillFilter {
                HStack {
                    Text("Showing \(active.label.lowercased())")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                    Button {
                        Haptics.light()
                        activeStatsPillFilter = nil
                    } label: {
                        Text("Clear")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.navy700)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.top, 2)
            }

            // Phase 55.2 / 56.4: "+ X recurring" footnote is now
            // tappable — opens the routines list. Hidden when the
            // user has no routines configured.
            //
            // Phase 95 (gap #14): when there are tasks parented to a
            // routine (and therefore filtered out of the buckets above),
            // append the count to the footnote so users understand
            // where those tasks went. "+ 4 recurring · 12 tasks managed
            // by your routines" reads as a discovery breadcrumb instead
            // of a vague footnote.
            if activeRoutineCount > 0 {
                Button {
                    Haptics.light()
                    showRoutinesList = true
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 11, weight: .semibold))
                        Text(footnoteText(activeRoutineCount: activeRoutineCount, hiddenTaskCount: routineOwnedTaskCount))
                            .font(HavenTypography.uiCaption)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                        Spacer()
                    }
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Per-property overdue counts (only when multiple properties
            // and some are overdue). Phase 56.4: uses raw overdue data —
            // the segmented-filter overlay was dropped with the picker.
            if viewModel.properties.count > 1 && viewModel.overdueTasks.count > 0 {
                HStack(spacing: 12) {
                    ForEach(viewModel.propertiesWithColors, id: \.property.id) { item in
                        let count = viewModel.overdueTasks.filter { $0.propertyId == item.property.id }.count
                        if count > 0 {
                            HStack(spacing: 4) {
                                Circle().fill(item.color).frame(width: 6, height: 6)
                                Text("\(count) overdue")
                                    .font(.system(size: 10))
                                    .foregroundStyle(item.color)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
            }
        }
    }

    /// Phase 56.4: Tappable stats pill. Tap swaps between active /
    /// inactive; count-zero pills are disabled so the user can't land
    /// on an empty filtered view. Active pill renders with navy fill
    /// and white text (same selected style as the property filter row).
    private func summaryPill(filter: StatsPillFilter, count: Int, accentColor: Color) -> some View {
        let isActive = activeStatsPillFilter == filter
        let isDisabled = count == 0

        return Button {
            guard !isDisabled else { return }
            Haptics.selection()
            if isActive {
                activeStatsPillFilter = nil
            } else {
                activeStatsPillFilter = filter
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(count)")
                    .font(HavenTypography.headline)
                    .foregroundStyle(
                        isActive
                            ? HavenColors.textOnNavy
                            : (count > 0 ? accentColor : HavenColors.textTertiary)
                    )
                Text(filter.label)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(isActive ? HavenColors.textOnNavy : HavenColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isActive ? HavenColors.navy : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }

    private var activeFiltersBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.navy700)

            if viewModel.filterStatus != .all {
                filterChip(viewModel.filterStatus.rawValue) {
                    viewModel.filterStatus = .all
                }
            }
            if let propId = viewModel.filterPropertyId {
                filterChip(viewModel.propertyName(for: propId)) {
                    viewModel.filterPropertyId = nil
                }
            }
            if let cat = viewModel.filterCategory {
                filterChip(cat) {
                    viewModel.filterCategory = nil
                }
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func filterChip(_ label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.navy700)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(HavenColors.navy.opacity(0.08))
        .clipShape(Capsule())
    }

    // MARK: - Phase 56.4: YOUR ACTION ITEMS body with today/later split

    /// Phase 56.4/5: "TO SCHEDULE" bucket with an optional TODAY & THIS
    /// WEEK / LATER inner split. The split only kicks in when both
    /// subsections have content AND the bucket has ≥5 rows. Any other
    /// shape (one subsection empty, bucket under 5 items, etc.) falls
    /// through to the flat `bucketSection` — a split with one empty
    /// half renders as an empty header + a collapsed drawer, which
    /// hides content from the user.
    @ViewBuilder
    private var personalBucketBody: some View {
        let hasToday = !personalBucketTodayThisWeek.isEmpty
        let hasLater = !personalBucketLater.isEmpty
        let shouldSplit = personalBucketTasks.count >= 5 && hasToday && hasLater

        if shouldSplit {
            personalBucketSplitSection
        } else {
            bucketSection(
                title: "To Schedule",
                count: personalBucketTasks.count,
                isCollapsed: personalBucketCollapsed,
                onToggle: togglePersonalBucket,
                tasks: personalBucketTasks,
                emptyCopy: "Nothing to schedule right now.",
                showChevron: true,
                subtitle: personalBucketTasks.isEmpty ? nil : "Book a visit, DIY, or delegate."
            )
        }
    }

    /// Phase 56.4: Split rendering for the personal bucket. The outer
    /// section header still toggles the full bucket (matches the
    /// existing collapse semantics users know); inside, a "TODAY & THIS
    /// WEEK" block always expands and a "LATER · N →" inner row
    /// collapses by default.
    @ViewBuilder
    private var personalBucketSplitSection: some View {
        Section {
            if personalBucketCollapsed {
                EmptyView()
            } else {
                // Today & This Week — always expanded
                if !personalBucketTodayThisWeek.isEmpty {
                    Text("TODAY & THIS WEEK")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 2, trailing: 16))

                    ForEach(personalBucketTodayThisWeek) { task in
                        maintenanceRow(task)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                if task.standingAppointmentId != nil {
                                    Button {
                                        confirmStandingVisit(for: task)
                                    } label: {
                                        Label("Confirm", systemImage: "checkmark")
                                    }
                                    .tint(HavenColors.success)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }

                // Later — collapsed drawer
                if !personalBucketLater.isEmpty {
                    Button {
                        withAnimation(HavenTheme.animationStandard) {
                            laterSubsectionExpanded.toggle()
                        }
                        Haptics.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Text("LATER")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("\u{00B7}")
                                .font(HavenTypography.uiSectionHeader)
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("\(personalBucketLater.count)")
                                .font(HavenTypography.uiSectionHeader)
                                .foregroundStyle(HavenColors.textTertiary)
                            Spacer()
                            Image(systemName: laterSubsectionExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 2, trailing: 16))

                    if laterSubsectionExpanded {
                        ForEach(personalBucketLater) { task in
                            maintenanceRow(task)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    if task.standingAppointmentId != nil {
                                        Button {
                                            confirmStandingVisit(for: task)
                                        } label: {
                                            Label("Confirm", systemImage: "checkmark")
                                        }
                                        .tint(HavenColors.success)
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                }
            }
        } header: {
            Button {
                togglePersonalBucket()
            } label: {
                bucketHeaderRow(
                    title: "To Schedule",
                    count: personalBucketTasks.count,
                    isCollapsed: personalBucketCollapsed,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            // Phase 56.5: When TODAY has ≤3 items, auto-expand LATER
            // so the user doesn't hit "THIS WEEK: 1" followed by a
            // collapsed "LATER · 12" drawer that feels like empty
            // stacked headers.
            if personalBucketTodayThisWeek.count <= 3 && !laterSubsectionExpanded {
                laterSubsectionExpanded = true
            }
        }
    }

    // MARK: - Phase 19l: Bucket section

    @ViewBuilder
    private func bucketSection(
        title: String,
        count: Int,
        isCollapsed: Bool,
        onToggle: @escaping () -> Void,
        tasks: [MaintenanceTaskDBRow],
        emptyCopy: String,
        showChevron: Bool = true,
        subtitle: String? = nil
    ) -> some View {
        // Build 87: `showChevron == false` is the segmented-filter mode
        // where only one bucket is on screen — render a plain header (no
        // tap target) since collapsing the only visible section would leave
        // the user staring at an empty list.
        Section {
            if isCollapsed {
                EmptyView()
            } else if tasks.isEmpty {
                Text(emptyCopy)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.vertical, HavenTheme.spacing12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            } else {
                ForEach(tasks) { task in
                    maintenanceRow(task)
                        // Phase 51: Leading-edge swipe to confirm (standing appointment tasks only).
                        // Build 91: trailing-edge swipe is no longer applied here —
                        // `maintenanceRow` owns the canonical Delete + Snooze
                        // (or Skip when `task.standingAppointmentId != nil`).
                        // Stacking trailing modifiers caused two Delete buttons
                        // to render side-by-side.
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if task.standingAppointmentId != nil {
                                Button {
                                    confirmStandingVisit(for: task)
                                } label: {
                                    Label("Confirm", systemImage: "checkmark")
                                }
                                .tint(HavenColors.success)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
        } header: {
            VStack(alignment: .leading, spacing: 2) {
                if showChevron {
                    Button {
                        onToggle()
                    } label: {
                        bucketHeaderRow(title: title, count: count, isCollapsed: isCollapsed, showChevron: true)
                    }
                    .buttonStyle(.plain)
                } else {
                    bucketHeaderRow(title: title, count: count, isCollapsed: false, showChevron: false)
                }

                // Phase 47: section-level explanatory copy (once, not per-card)
                if let subtitle, !isCollapsed {
                    Text(subtitle)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .padding(.top, 2)
                }
            }
        }
    }

    private func bucketHeaderRow(title: String, count: Int, isCollapsed: Bool, showChevron: Bool) -> some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
                .tracking(1.5)
            Text("\u{00B7}")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
            Text("\(count) \(count == 1 ? "task" : "tasks")")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
            Spacer()
            if showChevron {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Task Section

    @ViewBuilder
    private func taskSection(_ title: String, tasks: [MaintenanceTaskDBRow], accentColor: Color) -> some View {
        if !tasks.isEmpty {
            Section {
                ForEach(tasks) { task in
                    // Build 91: outer .swipeActions removed. Inner swipe in
                    // `maintenanceRow` is the single source of trailing actions.
                    maintenanceRow(task)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            } header: {
                HStack {
                    Circle().fill(accentColor).frame(width: 8, height: 8)
                    Text(title)
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    Spacer()
                    Text("\(tasks.count)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(accentColor)
                }
            }
        }
    }

    // MARK: - Task Row

    @ViewBuilder
    private func maintenanceRow(_ task: MaintenanceTaskDBRow) -> some View {
        // Phase 78: handyman visits render via the dedicated visit card
        // (vendor + date + status + checkable punch list as subitems).
        // Bypasses the generic UnifiedTaskCard so the homeowner stops
        // seeing "two tasks with super long notes" and starts seeing
        // the underlying visit as a first-class entity.
        //
        // Phase 95 (gap #42): wrapped in `selectionOverlay` so bulk-
        // select mode renders a leading checkmark + intercepts taps
        // to toggle membership instead of opening detail / firing
        // the visit checklist.
        selectionOverlay(for: task) {
            if isHandymanVisit(task) {
                handymanVisitRow(task)
            } else {
                standardMaintenanceRow(task)
            }
        }
    }

    /// Phase 78: visit-shaped row for handyman bundles. Reads the
    /// structured punch items from `punchItemsByVisitTaskId` (loaded
    /// once on appear). Tap a subitem to mark it done — the server
    /// trigger bumps the linked system's last-serviced date.
    @ViewBuilder
    private func handymanVisitRow(_ task: MaintenanceTaskDBRow) -> some View {
        let items = punchItemsByVisitTaskId[task.id] ?? []
        let cardItems: [HandymanVisitPunchItem] = items.map { row in
            HandymanVisitPunchItem(
                id: row.id.uuidString,
                title: row.title,
                isDone: row.isDone,
                estimatedMinutes: row.estimatedMinutes,
                systemLabel: row.systemLabelSnapshot,
                addedAfterLock: row.addedAfterLock ?? false
            )
        }
        let doneCount = cardItems.filter(\.isDone).count
        let scheduledDate: Date? = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: task.nextDueDate)
        }()
        let vendorName = viewModel.contractors.first(where: { $0.id == task.assignedContractorId })?.companyName

        let hasVendor = task.assignedContractorId != nil
        let statusLabel: String = hasVendor ? "Confirmed" : "Pending vendor"
        let isStatusActive: Bool = hasVendor

        HandymanVisitCard(
            title: task.title,
            vendorName: vendorName,
            scheduledDate: scheduledDate,
            statusLabel: statusLabel,
            isStatusActive: isStatusActive,
            totalItems: cardItems.count,
            doneItems: doneCount,
            punchItems: cardItems,
            hasNeedsAttentionItem: cardItems.contains(where: \.addedAfterLock),
            onTap: {
                Analytics.track(.maintenanceTaskViewed, [
                    "task_id": task.id.uuidString,
                    "task_title": task.title,
                    "render": "handyman_visit_card"
                ])
                selectedTask = task
            },
            onToggleItem: { itemId in
                guard let item = items.first(where: { $0.id.uuidString == itemId }) else { return }
                Task { await toggleHandymanPunchItem(item) }
            },
            onMessage: nil,
            onAddItem: nil
        )
    }

    @ViewBuilder
    private func standardMaintenanceRow(_ task: MaintenanceTaskDBRow) -> some View {
        // Phase 19l: resolve the contractor row when one is linked, so the
        // vendor-managed card variant can render the brand logo and color.
        let linkedContractor: ContractorRow? = {
            guard let id = task.assignedContractorId else { return nil }
            return viewModel.contractors.first(where: { $0.id == id })
        }()
        let assignment = task.assignmentType?.lowercased()
        let isPersonal = assignment != "vendor"

        Button {
            Analytics.track(.maintenanceTaskViewed, ["task_id": task.id.uuidString, "task_title": task.title])
            selectedTask = task
        } label: {
            UnifiedTaskCard(
                task: task,
                // Phase 56.4: only surface property name when the user
                // actually has multiple properties — single-property
                // households would see redundant "146 Putnam Park Road"
                // on every card.
                propertyName: (viewModel.properties.count > 1)
                    ? task.propertyId.map { viewModel.propertyName(for: $0) }
                    : nil,
                vehicleName: viewModel.vehicleName(for: task.vehicleId),
                systemName: viewModel.systemName(for: task.systemId),
                systemCategory: viewModel.systemCategory(for: task.systemId),
                assigneeName: viewModel.assignedUserName(for: task),
                assigneeAvatarColor: viewModel.assignedUserAvatarColor(for: task),
                contractorName: viewModel.assignedContractorName(for: task),
                contractor: linkedContractor,
                // Phase 56.4: the "Have someone else do it →" footer
                // fires only when there's no vendor linked yet —
                // showing a delegation link on a task that's already
                // assigned to Tyler Heating reads as contradictory.
                onDelegate: (isPersonal && task.assignedContractorId == nil) ? {
                    delegatingTask = task
                    showDelegateContractorPicker = true
                } : nil,
                onFindVendor: {
                    findVendorTask = task
                },
                onAddOwnVendor: {
                    addOwnVendorTask = task
                    showManualAddFromFindVendor = true
                },
                // Phase 56.6: Handyman quick-add below the "Find a pro"
                // pill on no-vendor cards. Nil hides the link — only
                // handyman-eligible tasks (≤60 min DIY effort, template
                // match, no vendor, not a vehicle task) surface it.
                onAddToHandyman: isHandymanEligible(task) ? {
                    Task { await addTaskToHandymanPunchList(task) }
                } : nil,
                onMarkDone: (task.assignedContractorId != nil && task.standingAppointmentId == nil) ? {
                    Task { await viewModel.completeTask(task) }
                    Haptics.success()
                } : nil,
                onReschedule: (task.assignedContractorId != nil && task.standingAppointmentId == nil) ? {
                    taskToSnooze = task
                    snoozeDate = {
                        let f = DateFormatter()
                        f.dateFormat = "yyyy-MM-dd"
                        let dueDate = f.date(from: task.nextDueDate) ?? Date()
                        let baseDate = max(dueDate, Date())
                        return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? baseDate
                    }()
                    showSnooze = true
                } : nil,
                // Phase 51B: Recurring vendor service metadata
                standingAppointment: {
                    guard let id = task.standingAppointmentId else { return nil }
                    return standingAppointmentVM.appointments.first { $0.id == id }
                }(),
                isPaused: {
                    guard let id = task.standingAppointmentId else { return false }
                    return standingAppointmentVM.appointments.first { $0.id == id }?.isPaused ?? false
                }(),
                onConfirmVisit: task.standingAppointmentId != nil ? {
                    Task {
                        guard let apptId = task.standingAppointmentId else { return }
                        // Find the next upcoming visit for this appointment
                        if let visit = try? await DatabaseService.shared.fetchUpcomingVisit(appointmentId: apptId) {
                            try? await standingAppointmentVM.confirmVisit(appointmentId: apptId, visitId: visit.id)
                        }
                    }
                } : nil,
                onSkipVisit: task.standingAppointmentId != nil ? {
                    Task {
                        guard let apptId = task.standingAppointmentId else { return }
                        if let visit = try? await DatabaseService.shared.fetchUpcomingVisit(appointmentId: apptId) {
                            try? await standingAppointmentVM.skipVisit(appointmentId: apptId, visitId: visit.id)
                        }
                    }
                } : nil,
                onResumeService: task.standingAppointmentId != nil ? {
                    Task {
                        guard let apptId = task.standingAppointmentId else { return }
                        try? await standingAppointmentVM.resumeAppointment(id: apptId)
                    }
                } : nil
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                taskToDelete = task
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }

            // Build 91: for standing-appointment tasks, the right-hand
            // action is Skip (skip this one visit) rather than Snooze,
            // matching the prior bucketSection behavior that was removed
            // when the duplicate outer swipe was deleted. Regular tasks
            // keep the Snooze action that pushes next_due_date +1 week.
            if task.standingAppointmentId != nil {
                Button {
                    skipStandingVisit(for: task)
                } label: {
                    Label("Skip", systemImage: "forward")
                }
                .tint(HavenColors.warning)
            } else {
                Button {
                    taskToSnooze = task
                    snoozeDate = {
                        let f = DateFormatter()
                        f.dateFormat = "yyyy-MM-dd"
                        let dueDate = f.date(from: task.nextDueDate) ?? Date()
                        let baseDate = max(dueDate, Date())
                        return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? baseDate
                    }()
                    showSnooze = true
                } label: {
                    Label("Snooze", systemImage: "moon.fill")
                }
                .tint(HavenColors.warning)
            }
        }
        .contextMenu {
            Button {
                taskToSnooze = task
                snoozeDate = {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd"
                    let dueDate = f.date(from: task.nextDueDate) ?? Date()
                    let baseDate = max(dueDate, Date())
                    return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? baseDate
                }()
                showSnooze = true
                Haptics.light()
            } label: {
                Label("Snooze", systemImage: "moon.fill")
            }

            Button {
                selectedTask = task
            } label: {
                Label("Mark Complete", systemImage: "checkmark.circle")
            }

            // Phase 51B: Pause/Resume for recurring services
            if task.standingAppointmentId != nil {
                if let appt = standingAppointmentVM.appointments.first(where: { $0.id == task.standingAppointmentId }),
                   !appt.isPaused {
                    Button {
                        appointmentToPause = appt
                        showPauseSheet = true
                    } label: {
                        Label("Pause Service", systemImage: "pause.circle")
                    }
                }
            }

            Divider()

            Button(role: .destructive) {
                taskToDelete = task
                showDeleteConfirm = true
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }

    private func metadataBadge(_ label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(label)
                .lineLimit(1)
        }
        .font(HavenTypography.uiCaption)
        .foregroundStyle(color)
    }

    // Phase 51B: Pause sheet is now attached to the List via .sheet(isPresented:)
    // in the body. The `appointmentToPause` + `showPauseSheet` state drives it.

    private func contractorFor(_ appointment: StandingAppointmentRow) -> ContractorRow? {
        guard let vendorId = appointment.vendorId else { return nil }
        return viewModel.contractors.first { $0.id == vendorId }
    }

    // MARK: - Phase 51: Swipe Gesture Helpers

    private func confirmStandingVisit(for task: MaintenanceTaskDBRow) {
        guard let appointmentId = task.standingAppointmentId else { return }
        Task {
            if let visit = try? await DatabaseService.shared.fetchUpcomingVisit(appointmentId: appointmentId) {
                try? await standingAppointmentVM.confirmVisit(appointmentId: appointmentId, visitId: visit.id)
            }
        }
    }

    private func skipStandingVisit(for task: MaintenanceTaskDBRow) {
        guard let appointmentId = task.standingAppointmentId else { return }
        Task {
            if let visit = try? await DatabaseService.shared.fetchUpcomingVisit(appointmentId: appointmentId) {
                try? await standingAppointmentVM.skipVisit(appointmentId: appointmentId, visitId: visit.id)
            }
        }
    }
}

// Phase 55.2: The Phase 54E `CadenceOccurrenceRow` fileprivate view
// was removed. Replacement is `RoutineOccurrenceRow` at the file
// `Haven/Features/Property/Views/RoutineOccurrenceRow.swift`.

#Preview {
    NavigationStack {
        MaintenanceScheduleView()
    }
}

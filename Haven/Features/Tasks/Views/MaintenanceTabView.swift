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
                    onAdd: { showAddMenu = true }
                )

                YearRibbon(
                    activeSeason: $activeSeason,
                    summaries: viewModel.seasonSummaries(activeSeason: currentSeason),
                    currentSeason: currentSeason,
                    onTap: { season in
                        // Tap any tile → push into the Calendar layout
                        // anchored to that season's first month so the
                        // homeowner can see the actual items behind the
                        // count. The MiniHero scoping was a side effect
                        // that doesn't show the items themselves.
                        pushTarget = .scheduleViewForSeason(season)
                    }
                )

                miniHeroSection

                decisionsSection

                programsSection

                // Phase 85 — Chez-handling section. Renders below the
                // homeowner's own programs and only when chez_owned
                // routines exist. Empty by default for DIY-default users.
                chezHandlingSection

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
        .task {
            if let householdId {
                await viewModel.load(householdId: householdId)
            }
            await maintenanceVM.loadTasks()
        }
        .refreshable {
            if let householdId { await viewModel.load(householdId: householdId) }
            await maintenanceVM.loadTasks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .routineChanged)) { _ in
            Task { if let householdId { await viewModel.load(householdId: householdId) } }
        }
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task { await maintenanceVM.loadTasks() }
        }
        .confirmationDialog("Add", isPresented: $showAddMenu, titleVisibility: .hidden) {
            Button("Add a routine") { pushTarget = .routinesList }
            Button("Add a one-off task") { pushTarget = .scheduleView }
            Button("Browse all services") { pushTarget = .recommendedServices }
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
                    pushTarget = .scheduleView
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

    // MARK: - Navigation destinations

    enum MaintenancePush: Hashable, Identifiable {
        case routinesList
        case scheduleView
        case scheduleViewForSeason(Season)
        case recommendedServices
        case vehicle(UUID)
        case routineDetail(RoutineRow, UUID)

        var id: String {
            switch self {
            case .routinesList: return "routines"
            case .scheduleView: return "schedule"
            case .scheduleViewForSeason(let season): return "schedule-\(season.rawValue)"
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
        case .scheduleView:
            MaintenanceScheduleView(filterPropertyId: propertyId)
        case .scheduleViewForSeason(let season):
            MaintenanceScheduleView(
                filterPropertyId: propertyId,
                initialLayout: .calendar,
                scrollToSeason: season
            )
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

    /// All in-season work organized chronologically by month. Bundle parents,
    /// standalone tasks, and routine occurrences mixed together within each
    /// month, sorted by anchor date within the month.
    let monthSections: [MonthSection]

    /// Active routines for the "Your active programs" section. Includes
    /// Chez-owned routines (no separate section in Tasks v2) — the row
    /// renders a salmon Chez pill inline. Collapsed by default in the UI.
    let programs: [RoutineRow]

    /// Convenience: ribbon tile counts. Excludes vehicle work (Vehicles
    /// section owns its own count).
    var totalItems: Int {
        decisions.count + monthSections.reduce(0) { $0 + $1.entries.count } + programs.count
    }

    var actionItems: Int { decisions.count }
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

    func dueLabel() -> String? {
        // Pick the earliest due date across pending decisions; fall back to nil.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dates = pendingDecisions().compactMap { formatter.date(from: $0.nextExpectedDate) }
        guard let soonest = dates.min() else { return nil }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return "Due \(display.string(from: soonest))"
    }

    func decisionMeta(for routine: RoutineRow) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: routine.nextExpectedDate) {
            let display = DateFormatter()
            display.dateFormat = "MMM d"
            return "Due \(display.string(from: date)) · Pick a vendor before service can start."
        }
        return "Pick a vendor before service can start."
    }

    func nextEventLabel(for routine: RoutineRow) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: routine.nextExpectedDate) else {
            return routine.activeMonthsSummary
        }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
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
            return true
        }

        // ── Decisions ──────────────────────────────────────────────
        // (a) pending-vendor routines for this season (no Chez routines)
        let routineDecisions = pendingDecisions(scopedTo: season)
            .map { DecisionEntry.routinePendingVendor($0) }
        // (b) standalone tasks needing a vendor pick (find-a-pro variants)
        let taskDecisions = allTasks
            .filter { task in
                task.parentRoutineId == nil &&
                task.assignmentType == "vendor" &&
                task.assignedContractorId == nil &&
                isTask(task, in: season)
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
        let seasonStandaloneTasks = allTasks.filter { task in
            task.parentRoutineId == nil && isTask(task, in: season)
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
        for occurrence in occurrences {
            let month = calendar.component(.month, from: occurrence.date)
            guard season.months.contains(month) else { continue }
            monthBuckets[month, default: []].append(.routineOccurrence(occurrence))
        }

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

        return SeasonFeed(
            season: season,
            decisions: combinedDecisions,
            monthSections: monthSections,
            programs: mergedPrograms
        )
    }

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

        if let timing = task.seasonalTiming?.trimmingCharacters(in: .whitespacesAndNewlines),
           !timing.isEmpty {
            let labels = timing.split(whereSeparator: { $0 == "/" || $0 == "," })
                .map { $0.trimmingCharacters(in: .whitespaces) }
            return labels.contains(season.rawValue)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = task.scheduledDate ?? task.nextDueDate
        guard let date = formatter.date(from: dateString) else { return false }
        let month = Calendar.current.component(.month, from: date)
        return season.months.contains(month)
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

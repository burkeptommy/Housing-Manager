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

@MainActor
final class MaintenanceTabViewModel: ObservableObject {
    @Published private(set) var routines: [RoutineRow] = []
    @Published private(set) var isLoading = false

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

    // MARK: Season summaries (for YearRibbon)

    func seasonSummaries(activeSeason: Season) -> [Season: YearRibbonSummary] {
        var result: [Season: YearRibbonSummary] = [:]
        for season in Season.allCases {
            let totalRoutines = routines.filter {
                $0.activeMonths.contains(anyOf: season.months)
            }.count
            let actionRoutines = pendingDecisions(scopedTo: season).count
            let totalTasks = MaintenanceViewModel.shared.tasks.filter {
                $0.lastCompletedDate == nil &&
                ($0.isArchived ?? false) == false &&
                isTask($0, in: season)
            }.count
            let actionTasks = MaintenanceViewModel.shared.tasks.filter {
                $0.lastCompletedDate == nil &&
                ($0.isArchived ?? false) == false &&
                ($0.assignmentType == "vendor" && $0.assignedContractorId == nil) &&
                isTask($0, in: season)
            }.count
            result[season] = YearRibbonSummary(
                totalItems: totalRoutines + totalTasks,
                actionItems: actionRoutines + actionTasks
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

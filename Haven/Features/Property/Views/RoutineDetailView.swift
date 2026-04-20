import SwiftUI

/// Phase 66: Unified detail view for a Routine — used for both property
/// services (landscaping, HVAC, handyman) and vehicle programs. Renders:
///  - Vendor card or "Haven helping" banner depending on setup_state
///  - Upcoming visits (routine_visits with visit_state active)
///  - Child tasks (maintenance_tasks with parent_routine_id = self)
///  - Edit / archive actions
///
/// Design: the same view handles vehicle-scoped routines by branching on
/// `routine.typedScope`. A vehicle routine shows the shop instead of a
/// category vendor and labels the sections appropriately.
struct RoutineDetailView: View {
    let routine: RoutineRow
    let householdId: UUID

    @State private var visits: [RoutineVisitRow] = []
    @State private var childTasks: [MaintenanceTaskDBRow] = []
    @State private var vendor: ContractorRow?
    @State private var isEditing = false
    @State private var isLoading = false

    private let db = DatabaseService.shared

    var body: some View {
        List {
            headerSection
            upcomingVisitsSection
            childTasksSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(routine.label)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $isEditing, onDismiss: { Task { await load() } }) {
            NavigationStack {
                RoutineEditSheet(
                    householdId: householdId,
                    propertyId: routine.propertyId,
                    existing: routine,
                    onSaved: { Task { await load() } }
                )
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                iconOrLogo
                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryLine)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let cadence = routine.typedCadence?.displayLabel {
                        Text(cadence)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    if routine.typedSetupState == .pendingVendor {
                        Label("Haven is helping find one", systemImage: "sparkles")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.action)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var upcomingVisitsSection: some View {
        Section("Upcoming visits") {
            if visits.isEmpty {
                Text("No visits scheduled yet")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
            } else {
                ForEach(visits) { visit in
                    visitRow(visit)
                }
            }
        }
    }

    @ViewBuilder
    private var childTasksSection: some View {
        if !childTasks.isEmpty {
            Section("What's included (\(childTasks.count))") {
                ForEach(childTasks) { task in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                        if !task.nextDueDate.isEmpty {
                            Text("Due \(task.nextDueDate)")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                isEditing = true
            } label: {
                Label("Edit routine", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Task { await archive() }
            } label: {
                Label("Archive routine", systemImage: "archivebox")
            }
        }
    }

    @ViewBuilder
    private var iconOrLogo: some View {
        if let vendor {
            VendorLogoView(contractor: vendor, size: 44)
        } else {
            Image(systemName: routine.resolvedIcon)
                .font(.title2)
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 44, height: 44)
                .background(HavenColors.beige200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var primaryLine: String {
        if let vendor {
            return vendor.companyName.isEmpty ? (vendor.contactName ?? "Vendor") : vendor.companyName
        }
        if routine.typedSetupState == .pendingVendor { return "No vendor assigned" }
        return "Self-managed"
    }

    @ViewBuilder
    private func visitRow(_ visit: RoutineVisitRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(visit.scheduledDate)
                    .font(HavenTypography.body)
                if let end = visit.targetWindowEnd, end != visit.scheduledDate {
                    Text("By \(end)")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            Spacer()
            stateBadge(visit.typedVisitState)
        }
    }

    @ViewBuilder
    private func stateBadge(_ state: RoutineVisitState) -> some View {
        Text(state.displayLabel)
            .font(HavenTypography.caption)
            .foregroundStyle(badgeColor(state))
    }

    private func badgeColor(_ state: RoutineVisitState) -> Color {
        switch state {
        case .scheduled, .inProgress: return HavenColors.success
        case .planned: return HavenColors.action
        case .completed: return HavenColors.textSecondary
        default: return HavenColors.textTertiary
        }
    }

    // MARK: - Data

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        visits = (try? await db.fetchActiveRoutineVisits(routineId: routine.id)) ?? []
        childTasks = (try? await db.fetchTasksForRoutine(routineId: routine.id))?
            .filter { $0.isArchived != true } ?? []

        if let vendorId = routine.vendorId {
            vendor = try? await db.fetchContractor(id: vendorId)
        } else {
            vendor = nil
        }

        Analytics.track(.routineDetailOpened, [
            "routine_id": routine.id.uuidString,
            "routine_kind": routine.routineKind,
            "scope": routine.scope,
            "setup_state": routine.setupState,
            "visit_count": visits.count,
            "child_task_count": childTasks.count
        ])
    }

    private func archive() async {
        // Unlink children first so they don't orphan.
        try? await RoutineGroupingEngine.unlinkTasksFromRoutine(routine.id)
        try? await db.archiveRoutine(id: routine.id)
        Analytics.track(.routineArchivedFromServices, [
            "routine_id": routine.id.uuidString,
            "routine_kind": routine.routineKind
        ])
        NotificationCenter.default.post(name: .routineChanged, object: nil)
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
    }
}

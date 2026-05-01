import SwiftUI

/// Phase 80.2 — Single screen showing everything the homeowner has
/// handed off to Chez: routines, contractors, AND individual tasks.
/// Renders three sections, each with quick-revoke affordances and a
/// tap-into-detail path for context.
///
/// Reachable from the Chez profile's "Standing engagements" section.
/// One place to see what's delegated; one place to revoke.
struct ChezDelegationsListView: View {
    @StateObject private var viewModel = ChezDelegationsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.isEmpty {
                ProgressView().padding(.top, 80)
            } else if viewModel.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .navigationTitle("Standing engagements")
        .navigationBarTitleDisplayMode(.inline)
        .background(HavenColors.background.ignoresSafeArea())
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .chezDelegationChanged)) { _ in
            Task { await viewModel.load() }
        }
        .trackScreen("ChezDelegationsListView")
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                if !viewModel.delegatedRoutines.isEmpty {
                    routinesSection
                }
                if !viewModel.delegatedContractors.isEmpty {
                    contractorsSection
                }
                if !viewModel.delegatedTasks.isEmpty {
                    tasksSection
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, 16)
        }
    }

    private var hero: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.totalCount) handed to Chez")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Each one is being handled end-to-end. Tap to revoke.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.action.opacity(0.06))
        )
    }

    // MARK: - Sections

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("RECURRING ROUTINES · \(viewModel.delegatedRoutines.count)")
            ForEach(viewModel.delegatedRoutines, id: \.id) { routine in
                row(
                    icon: "calendar.badge.clock",
                    title: routine.label,
                    subtitle: "Chez owns scheduling",
                    onRevoke: { Task { await viewModel.revokeRoutine(routine) } }
                )
            }
        }
    }

    private var contractorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("VENDOR RELATIONSHIPS · \(viewModel.delegatedContractors.count)")
            ForEach(viewModel.delegatedContractors, id: \.id) { contractor in
                row(
                    icon: "wrench.and.screwdriver.fill",
                    title: contractor.companyName,
                    subtitle: "Chez is point of contact",
                    onRevoke: { Task { await viewModel.revokeContractor(contractor) } }
                )
            }
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("INDIVIDUAL TASKS · \(viewModel.delegatedTasks.count)")
            ForEach(viewModel.delegatedTasks, id: \.id) { task in
                row(
                    icon: "checkmark.circle",
                    title: task.title,
                    subtitle: subtitleForTask(task),
                    onRevoke: { Task { await viewModel.revokeTask(task) } }
                )
            }
        }
    }

    private func subtitleForTask(_ task: MaintenanceTaskDBRow) -> String {
        if task.assignedContractorId != nil && task.needsVendor != true {
            return "Chez coordinating with vendor"
        }
        return "Chez sourcing a vendor"
    }

    private func row(
        icon: String,
        title: String,
        subtitle: String,
        onRevoke: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                Text(subtitle)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
            Button {
                Haptics.light()
                onRevoke()
            } label: {
                Text("Revoke")
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(HavenColors.beige200.opacity(0.6))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(HavenTypography.uiSectionHeader)
            .foregroundStyle(HavenColors.textSecondary)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(spacing: 8) {
                Text("Nothing handed off yet")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Tap \"Have Chez own this\" on any routine, vendor, or task to delegate it. Anything you hand off lives here so you can see (and revoke) at a glance.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - View model

@MainActor
final class ChezDelegationsViewModel: ObservableObject {
    @Published var delegatedRoutines: [RoutineRow] = []
    @Published var delegatedContractors: [ContractorRow] = []
    @Published var delegatedTasks: [MaintenanceTaskDBRow] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var totalCount: Int {
        delegatedRoutines.count + delegatedContractors.count + delegatedTasks.count
    }
    var isEmpty: Bool { totalCount == 0 }

    func load() async {
        if totalCount == 0 { isLoading = true }
        defer { isLoading = false }
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                delegatedRoutines = []
                delegatedContractors = []
                delegatedTasks = []
                return
            }
            // Routines + contractors come straight off the table reads;
            // both row types now carry the chez_owned column. Tasks
            // require a household-scoped read since we don't have a
            // dedicated fetch helper for delegation-only.
            async let routinesReq = DatabaseService.shared.fetchRoutines(householdId: householdId)
            async let contractorsReq = DatabaseService.shared.fetchContractors()
            async let tasksReq = DatabaseService.shared.fetchMaintenanceTasks()
            let (routines, contractors, tasks) = try await (routinesReq, contractorsReq, tasksReq)
            delegatedRoutines = routines.filter { $0.chezOwned }
                .sorted(by: { ($0.chezOwnedAt ?? .distantPast) > ($1.chezOwnedAt ?? .distantPast) })
            delegatedContractors = contractors.filter { $0.isChezOwned }
                .sorted(by: { ($0.chezOwnedAt ?? .distantPast) > ($1.chezOwnedAt ?? .distantPast) })
            delegatedTasks = tasks.filter { $0.isChezOwned }
                .sorted(by: { ($0.chezOwnedAt ?? .distantPast) > ($1.chezOwnedAt ?? .distantPast) })
        } catch {
            errorMessage = error.localizedDescription
            print("[ChezDelegationsVM] load failed: \(error)")
        }
    }

    func revokeRoutine(_ routine: RoutineRow) async {
        do {
            try await HavenSupabase.delegateRoutineToChez(
                routineId: routine.id, delegated: false, notes: nil
            )
            Haptics.success()
            NotificationCenter.default.post(name: .chezDelegationChanged, object: nil)
            await load()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    func revokeContractor(_ contractor: ContractorRow) async {
        do {
            try await HavenSupabase.delegateContractorToChez(
                contractorId: contractor.id, delegated: false, notes: nil
            )
            Haptics.success()
            NotificationCenter.default.post(name: .chezDelegationChanged, object: nil)
            await load()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    func revokeTask(_ task: MaintenanceTaskDBRow) async {
        do {
            try await HavenSupabase.delegateTaskToChez(
                taskId: task.id, delegated: false, notes: nil
            )
            Haptics.success()
            NotificationCenter.default.post(name: .chezDelegationChanged, object: nil)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            await load()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
}

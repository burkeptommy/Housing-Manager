import SwiftUI

/// Phase 70.A1 follow-on G3 + I2 — Activity sheet (Completed + Archived).
///
/// Tom's request (Series G): "When we mark something as done it should
/// go into an archived 'Completed' list where I can always go look at
/// what has been completed and by who."
///
/// Tom's follow-on (Series I): swipe-dismissed tasks and completed
/// tasks need separate surfaces — "archived tasks go where completed
/// tasks go" was the wrong mental model. I2 splits them into two tabs
/// on the same sheet, with an inline "Restore" action on archived
/// rows so accidental swipes are one-tap reversible.
///
/// Two tabs, two queries:
/// - **Completed**: `archived_reason = "completed"` — work that got
///   done. Read-only chronological log grouped by month.
/// - **Archived**: `archived_reason != "completed"` — swipe-dismissed,
///   reconciler-pruned, or otherwise removed. Each row has a Restore
///   button that calls `unarchiveMaintenanceTask(id:)`.
///
/// Reached from the Tasks-tab toolbar (clock.arrow.circlepath icon
/// next to + in `HeaderSwitcher`). The struct keeps the legacy name
/// `CompletedTasksSheet` for backward compatibility with the single
/// existing call site — I2 didn't rename the file to avoid the
/// XcodeGen churn for a single ref.
struct CompletedTasksSheet: View {
    let householdId: UUID

    @Environment(\.dismiss) private var dismiss

    enum Tab: String, CaseIterable, Identifiable {
        case completed = "Completed"
        case archived = "Archived"
        var id: String { rawValue }
    }

    @State private var selectedTab: Tab = .completed
    @State private var completedRows: [MaintenanceTaskDBRow] = []
    @State private var archivedRows: [MaintenanceTaskDBRow] = []
    @State private var contractorsById: [UUID: ContractorRow] = [:]
    @State private var systemsById: [UUID: HomeSystemRow] = [:]
    @State private var usersById: [UUID: UserRow] = [:]
    @State private var isLoading = false
    @State private var restoringTaskId: UUID?

    private static let monthHeader: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabPicker
                content
            }
            .background(HavenColors.background)
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(HavenColors.beige200)
                            .clipShape(Circle())
                    }
                }
            }
            .task { await load() }
            .refreshable { await load() }
            .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
                Task { await load() }
            }
        }
    }

    private var tabPicker: some View {
        Picker("View", selection: $selectedTab) {
            ForEach(Tab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && currentRows.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if currentRows.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedRows, id: \.month) { group in
                        sectionHeader(group)
                        VStack(spacing: 8) {
                            ForEach(group.rows) { row in
                                rowCell(row)
                            }
                        }
                        .padding(.horizontal, HavenTheme.pageMargin)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedTab == .completed ? "checkmark.seal" : "archivebox")
                .font(.system(size: 40))
                .foregroundStyle(HavenColors.textTertiary)
            Text(emptyTitle)
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
            Text(emptyCaption)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }

    private var emptyTitle: String {
        selectedTab == .completed ? "No completed tasks yet" : "Nothing archived"
    }

    private var emptyCaption: String {
        switch selectedTab {
        case .completed:
            return "Mark a task done and it'll show up here so you can see who handled what, and when."
        case .archived:
            return "Swipe left on a task to dismiss it. It'll show up here so you can restore it later."
        }
    }

    private func sectionHeader(_ group: ActivityGroup) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(Self.monthHeader.string(from: group.anchor).uppercased())
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
                .tracking(0.6)
            Text("·")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
            Text(group.subtitle(for: selectedTab))
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func rowCell(_ row: MaintenanceTaskDBRow) -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconPlate(for: row)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.title)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let dateLabel = formattedDate(row) {
                        Text(dateLabel)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    if let systemName = systemLabel(row) {
                        Text("·")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(systemName)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                if selectedTab == .completed {
                    Text(creditLabel(row))
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(1)
                } else if let reason = archiveReasonLabel(row) {
                    Text(reason)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if selectedTab == .archived {
                restoreButton(for: row)
            }
        }
        .padding(12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.border.opacity(0.4), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func iconPlate(for row: MaintenanceTaskDBRow) -> some View {
        ZStack {
            Circle()
                .fill(selectedTab == .completed
                      ? HavenColors.success.opacity(0.16)
                      : HavenColors.beige200)
                .frame(width: 32, height: 32)
            Image(systemName: selectedTab == .completed ? "checkmark" : "archivebox.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(selectedTab == .completed
                                 ? HavenColors.success
                                 : HavenColors.textSecondary)
        }
    }

    @ViewBuilder
    private func restoreButton(for row: MaintenanceTaskDBRow) -> some View {
        Button {
            Task { await restore(row) }
        } label: {
            HStack(spacing: 4) {
                if restoringTaskId == row.id {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .semibold))
                }
                Text("Restore")
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
            }
            .foregroundStyle(HavenColors.navy800)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .overlay(
                Capsule().stroke(HavenColors.navy.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(restoringTaskId != nil)
        .accessibilityLabel("Restore \(row.title)")
    }

    // MARK: - Helpers

    private struct ActivityGroup {
        let month: String   // "MMMM yyyy" — also the ForEach id
        let anchor: Date
        let rows: [MaintenanceTaskDBRow]

        func subtitle(for tab: Tab) -> String {
            switch tab {
            case .completed: return "\(rows.count) completed"
            case .archived:  return "\(rows.count) archived"
            }
        }
    }

    private var currentRows: [MaintenanceTaskDBRow] {
        selectedTab == .completed ? completedRows : archivedRows
    }

    private var groupedRows: [ActivityGroup] {
        let calendar = Calendar.current
        var bucket: [String: (anchor: Date, rows: [MaintenanceTaskDBRow])] = [:]
        for row in currentRows {
            let anchorDate = groupingDate(row)
            guard let date = anchorDate else { continue }
            let comps = calendar.dateComponents([.year, .month], from: date)
            guard let monthAnchor = calendar.date(from: comps) else { continue }
            let key = Self.monthHeader.string(from: monthAnchor)
            var existing = bucket[key] ?? (anchor: monthAnchor, rows: [])
            existing.rows.append(row)
            bucket[key] = existing
        }
        return bucket
            .map { ActivityGroup(month: $0.key, anchor: $0.value.anchor, rows: $0.value.rows) }
            .sorted { $0.anchor > $1.anchor }
    }

    /// Completed rows group by `last_completed_date` (the day the work
    /// happened); archived rows group by `archived_at` (the day the
    /// homeowner dismissed it).
    private func groupingDate(_ row: MaintenanceTaskDBRow) -> Date? {
        switch selectedTab {
        case .completed:
            return TasksV2DateFormatting.parseRowDate(row.lastCompletedDate ?? "")
        case .archived:
            return row.archivedAt
        }
    }

    private func formattedDate(_ row: MaintenanceTaskDBRow) -> String? {
        guard let date = groupingDate(row) else { return nil }
        return TasksV2DateFormatting.longDay(date)
    }

    private func systemLabel(_ row: MaintenanceTaskDBRow) -> String? {
        guard let id = row.systemId, let system = systemsById[id] else { return nil }
        return system.name
    }

    private func creditLabel(_ row: MaintenanceTaskDBRow) -> String {
        if let id = row.assignedContractorId, let contractor = contractorsById[id] {
            return "Handled by \(MaintenanceViewModel.vendorDisplayName(contractor.companyName))"
        }
        if let userId = row.assignedToUserId, let user = usersById[userId] {
            let fullName = user.fullName ?? ""
            let firstName = fullName.components(separatedBy: " ").first ?? fullName
            if !firstName.isEmpty {
                return "Marked done by \(firstName)"
            }
        }
        return "Marked done"
    }

    /// Short, user-friendly translation of the archive reason stamps.
    /// Internal reason codes ("swiped_archive_from_tasks_tab",
    /// "migrated_to_handyman_punch", etc.) get a friendly equivalent;
    /// unknown reasons fall back to "Archived".
    private func archiveReasonLabel(_ row: MaintenanceTaskDBRow) -> String? {
        guard let reason = row.archivedReason else { return "Archived" }
        switch reason {
        case "swiped_archive_from_tasks_tab":
            return "Swiped to dismiss"
        case "migrated_to_handyman_punch":
            return "Moved to handyman punch list"
        case "migrated_to_seasonal_reminder":
            return "Replaced by seasonal reminder"
        case "moved_to_handyman_punch":
            return "Moved to handyman punch list"
        default:
            return "Archived"
        }
    }

    @MainActor
    private func restore(_ row: MaintenanceTaskDBRow) async {
        restoringTaskId = row.id
        defer { restoringTaskId = nil }
        do {
            try await DatabaseService.shared.unarchiveMaintenanceTask(id: row.id)
            Haptics.success()
            archivedRows.removeAll { $0.id == row.id }
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        } catch {
            print("[ActivitySheet] restore failed: \(error)")
            Haptics.error()
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let db = DatabaseService.shared
            async let completedTask = db.fetchCompletedMaintenanceTasks(householdId: householdId)
            async let archivedTask = db.fetchArchivedMaintenanceTasks(householdId: householdId)
            async let contractorsTask = db.fetchContractors()
            async let systemsTask = db.fetchHomeSystems()
            async let usersTask = db.fetchHouseholdUsers()

            let fetchedCompleted = try await completedTask
            let fetchedArchived = (try? await archivedTask) ?? []
            let fetchedContractors = (try? await contractorsTask) ?? []
            let fetchedSystems = (try? await systemsTask) ?? []
            let fetchedUsers = (try? await usersTask) ?? []

            self.completedRows = fetchedCompleted
            self.archivedRows = fetchedArchived
            self.contractorsById = Dictionary(uniqueKeysWithValues: fetchedContractors.map { ($0.id, $0) })
            self.systemsById = Dictionary(uniqueKeysWithValues: fetchedSystems.map { ($0.id, $0) })
            self.usersById = Dictionary(uniqueKeysWithValues: fetchedUsers.map { ($0.id, $0) })
        } catch {
            print("[ActivitySheet] load failed: \(error)")
        }
    }
}

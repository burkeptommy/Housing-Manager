import SwiftUI

/// Phase 61: Simple read-only surface that lists every archived maintenance
/// task for the household, so the user can confirm what Haven cleaned up in
/// a library-retirement or reconciler pass. Opens from the
/// `LegacyTasksNotificationCard` "View details" button on the dashboard.
///
/// Preserves user history — nothing in this view writes to the DB. Users
/// can tap through to a read-only detail sheet but cannot un-archive (by
/// design; if they want a specific task back, they should re-create it from
/// the recommended library or the custom task sheet).
struct LegacyTasksView: View {
    @State private var archivedTasks: [MaintenanceTaskDBRow] = []
    @State private var isLoading = true
    @State private var selectedTask: MaintenanceTaskDBRow?

    /// Archive-reason groupings so the user sees WHY a task was tidied.
    /// Grouped-by-reason keeps the list scannable when multiple passes
    /// have touched a household.
    private var groupedByReason: [(reason: String, title: String, tasks: [MaintenanceTaskDBRow])] {
        let grouped = Dictionary(grouping: archivedTasks) { task in
            LegacyTasksView.reasonCategory(for: task.archivedReason)
        }
        return grouped
            .map { (key, value) in
                (reason: key, title: LegacyTasksView.groupTitle(for: key), tasks: value.sorted { $0.title < $1.title })
            }
            .sorted { $0.title < $1.title }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if archivedTasks.isEmpty {
                ContentUnavailableView {
                    Label("Nothing archived", systemImage: "archivebox")
                } description: {
                    Text("Chez hasn't tidied any tasks in your household yet.")
                }
            } else {
                List {
                    ForEach(groupedByReason, id: \.reason) { group in
                        Section {
                            ForEach(group.tasks) { task in
                                Button {
                                    selectedTask = task
                                } label: {
                                    legacyRow(task)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text(group.title.uppercased())
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Tidied Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(item: $selectedTask) { task in
            NavigationStack {
                LegacyTaskDetailView(task: task)
            }
            .presentationDetents([.medium])
        }
    }

    private func legacyRow(_ task: MaintenanceTaskDBRow) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "archivebox.fill")
                .foregroundStyle(HavenColors.textTertiary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                if let archivedAt = task.archivedAt {
                    Text("Archived \(archivedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.vertical, 4)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        guard let all = try? await DatabaseService.shared.fetchAllMaintenanceTasks(includeArchived: true) else {
            archivedTasks = []
            return
        }
        archivedTasks = all.filter { $0.isArchived == true }
    }

    /// Maps an archive reason to a coarse category so grouped sections read
    /// naturally. Reasons are authored by the reconciler + ad-hoc migrations
    /// across Phases 17b / 52 / 54A / 58 / 61 — this collapses them into
    /// user-facing buckets.
    private static func reasonCategory(for reason: String?) -> String {
        guard let reason = reason?.lowercased() else { return "general" }
        if reason.hasPrefix("subtype_mismatch") { return "subtype_mismatch" }
        if reason.hasPrefix("backfilled_to_bundle") { return "bundle_consolidation" }
        if reason.hasPrefix("template_retired") { return "library_retirement" }
        if reason.contains("consolidated") || reason.contains("phase 52") { return "bundle_consolidation" }
        return "general"
    }

    private static func groupTitle(for category: String) -> String {
        switch category {
        case "subtype_mismatch": return "Doesn't apply to your home"
        case "bundle_consolidation": return "Rolled into a service visit"
        case "library_retirement": return "Retired from Chez's library"
        default: return "Tidied up"
        }
    }
}

/// BUG-020 fix: Detail view now exposes a "Bring it back" action when
/// the user says the reconciler was wrong (e.g. they added a hot tub
/// later and want the hot-tub tasks surfaced again). Un-archive lives
/// as a visible button in the body — not buried in a toolbar menu — so
/// the recourse is obvious.
private struct LegacyTaskDetailView: View {
    let task: MaintenanceTaskDBRow

    @Environment(\.dismiss) private var dismiss
    @State private var isUnarchiving = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                Text(task.title)
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)

                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("WHY IT WAS ARCHIVED")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(LegacyTaskDetailView.humanReason(for: task.archivedReason))
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textPrimary)
                }

                if let archivedAt = task.archivedAt {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ARCHIVED ON")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(archivedAt.formatted(date: .complete, time: .shortened))
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    Button {
                        Task { await unarchive() }
                    } label: {
                        HStack(spacing: 8) {
                            if isUnarchiving {
                                ProgressView()
                                    .tint(HavenColors.textOnAction)
                            } else {
                                Image(systemName: "arrow.uturn.backward")
                            }
                            Text(isUnarchiving ? "Restoring…" : "Bring it back")
                                .font(HavenTypography.uiButton)
                        }
                        .foregroundStyle(HavenColors.textOnAction)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(HavenColors.action)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(.plain)
                    .disabled(isUnarchiving)

                    Text("Not right for your home? Leave it archived. You can come back anytime.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }
            }
            .padding()
        }
        .navigationTitle("Tidied Task")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func unarchive() async {
        guard !isUnarchiving else { return }
        isUnarchiving = true
        errorMessage = nil
        defer { isUnarchiving = false }

        do {
            try await DatabaseService.shared.unarchiveMaintenanceTask(id: task.id)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            Haptics.success()
            dismiss()
        } catch {
            errorMessage = "Couldn't restore this task. Try again in a moment."
        }
    }

    /// BUG-019 fix: translate the reconciler's raw archive-reason codes
    /// (e.g. "subtype_mismatch:Pool/Spa:pool_inground_salt") into human
    /// copy a premium HNW audience expects. Never expose raw keys.
    static func humanReason(for raw: String?) -> String {
        guard let raw = raw, !raw.isEmpty else {
            return "Chez tidied this task during a recent library refresh."
        }

        let lower = raw.lowercased()

        if lower.hasPrefix("subtype_mismatch") {
            let parts = raw.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
            let category = parts.count > 1 ? parts[1] : ""
            if category.isEmpty {
                return "This task doesn't match the systems you have set up. If that changes, we can bring it back."
            }
            return "This task was for a \(category) setup your home doesn't currently have. If you add one later, we'll bring this back."
        }

        if lower.hasPrefix("backfilled_to_bundle") {
            let parts = raw.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
            if parts.count >= 2 {
                let bundle = parts[1].replacingOccurrences(of: "_", with: " ")
                return "Consolidated into your \(bundle) service visit so your schedule stays clean."
            }
            return "Consolidated into a larger service visit so your schedule stays clean."
        }

        if lower.hasPrefix("template_retired") || lower.contains("retired") {
            return "Removed when Chez refined its task library. Nothing you need to do."
        }

        if lower.contains("consolidated") || lower.contains("phase 52") {
            return "Rolled into a seasonal service visit to reduce calendar noise."
        }

        // Fallback: show a friendly generic message rather than the raw code.
        return "Chez tidied this task during a recent library refresh."
    }
}

import SwiftUI

/// Chez v1: full-list sheets for the Overview "Needs your decision"
/// cards. Replaces the old behavior where the multi-task vendor card
/// jumped straight into the first task's detail (confusing) and the
/// systems-missing card just switched tabs (lost the list).
///
/// Both sheets are dumb presenters — the parent passes in the data and
/// the row taps fire a callback so PropertyDetailView keeps owning the
/// downstream sheet presentations (find-a-pro, system detail).

// MARK: - Needs-vendor tasks sheet

/// Chez v1: groups vendor-needing tasks by canonical vendor specialty
/// (HVAC, Plumbing, Roofing, Handyman, …) so the user sees "1 HVAC pro
/// covers 4 tasks" instead of 50 individual rows. The category-level
/// "Find a pro" CTA hits FindLocalVendorSheet which adopts ONE vendor
/// + auto-converts every needs-vendor task in that category in one
/// shot.
struct NeedsVendorTasksSheet: View {
    let tasks: [MaintenanceTaskDBRow]
    let systems: [HomeSystemRow]
    /// Tap an individual task → drill into detail (existing behavior).
    let onSelectTask: (MaintenanceTaskDBRow) -> Void
    /// Tap the section "Find a pro" → opens FindLocalVendorSheet with
    /// the canonical category. Parent owns the sheet presentation so
    /// the find-a-pro UX stays in PropertyDetailView's hierarchy.
    let onFindProForCategory: (VendorTaskGrouping.Group) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var expandedCategoryIds: Set<String> = []

    private var groups: [VendorTaskGrouping.Group] {
        VendorTaskGrouping.group(tasks: tasks, systems: systems)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    headerCopy

                    LazyVStack(spacing: HavenTheme.spacing12) {
                        ForEach(groups) { group in
                            categoryCard(group)
                        }
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                }
                .padding(.bottom, HavenTheme.spacing32)
            }
            .background(HavenColors.background)
            .navigationTitle("Tasks needing a vendor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var headerCopy: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(groups.count) vendor\(groups.count == 1 ? "" : "s") cover all of these")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("One pro per category covers every task in that group. Tap Find a pro to handle them all in one shot. Or tap a task to drill in.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, HavenTheme.spacing8)
    }

    private func categoryCard(_ group: VendorTaskGrouping.Group) -> some View {
        let isExpanded = expandedCategoryIds.contains(group.id)
        return HavenCard(padding: HavenTheme.spacing16) {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                // Header — icon + title + count + Find a pro pill
                Button {
                    Haptics.light()
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        if isExpanded {
                            expandedCategoryIds.remove(group.id)
                        } else {
                            expandedCategoryIds.insert(group.id)
                        }
                    }
                } label: {
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: group.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .fill(HavenColors.navy.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .strokeBorder(HavenColors.navy.opacity(0.08), lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.displayName)
                                .font(HavenTypography.title3)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("\(group.count) task\(group.count == 1 ? "" : "s") need a pro")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                .buttonStyle(.plain)

                // Primary CTA — adopts a vendor for the whole bucket.
                Button {
                    Haptics.medium()
                    onFindProForCategory(group)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Find a pro")
                            .font(HavenTypography.uiButton)
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HavenTheme.spacing12)
                    .background(HavenColors.action)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(.plain)

                // Task list — expanded inline so the user can verify
                // what's in the bucket before adopting. Truncated to
                // 3 by default with a "+N more" footer when collapsed.
                if isExpanded {
                    Divider().background(HavenColors.beige200)
                    ForEach(group.tasks) { task in
                        taskRow(task)
                    }
                } else {
                    let preview = Array(group.tasks.prefix(3))
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(preview) { task in
                            HStack(spacing: 6) {
                                Text("•")
                                    .foregroundStyle(HavenColors.textTertiary)
                                Text(task.title)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        if group.tasks.count > preview.count {
                            Text("+ \(group.tasks.count - preview.count) more. Tap to see all")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                                .padding(.top, 2)
                        }
                    }
                }
            }
        }
    }

    private func taskRow(_ task: MaintenanceTaskDBRow) -> some View {
        Button {
            Haptics.light()
            onSelectTask(task)
        } label: {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusSmall)
                            .fill(HavenColors.actionPale)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(rowSubtitle(for: task))
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func rowSubtitle(for task: MaintenanceTaskDBRow) -> String {
        let due = MaintenanceDateFormatting.dueLabel(for: task.scheduledDate ?? task.nextDueDate)
        let systemsLookup = Dictionary(uniqueKeysWithValues: systems.map { ($0.id, $0) })
        if let systemId = task.systemId, let system = systemsLookup[systemId] {
            return "\(system.displayName) · \(due)"
        }
        return due
    }
}

// MARK: - Systems missing profile sheet

struct SystemsMissingProfileSheet: View {
    /// Each entry pairs a system with the human-readable list of fields
    /// it's missing — pre-computed by the parent so this sheet stays
    /// stateless.
    struct Entry: Identifiable {
        let system: HomeSystemRow
        let missingTitles: [String]
        var id: UUID { system.id }
    }

    let entries: [Entry]
    let onSelect: (HomeSystemRow) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    Text("Each system below is missing a few details Chez needs to plan service. Tap one to fill it in. We only ask for fields that make sense for that system.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .padding(.horizontal, HavenTheme.pageMargin)
                        .padding(.top, HavenTheme.spacing8)

                    LazyVStack(spacing: HavenTheme.spacing8) {
                        ForEach(entries) { entry in
                            Button {
                                Haptics.light()
                                onSelect(entry.system)
                            } label: {
                                systemRow(entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                }
                .padding(.bottom, HavenTheme.spacing32)
            }
            .background(HavenColors.background)
            .navigationTitle("Systems needing details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func systemRow(_ entry: Entry) -> some View {
        HavenCard(padding: HavenTheme.spacing12) {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: "checklist")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.warning)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .fill(HavenColors.warning.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.system.displayName)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    Text(entry.system.category)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                    if !entry.missingTitles.isEmpty {
                        Text("Needs: " + entry.missingTitles.prefix(3).joined(separator: " · "))
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }
}

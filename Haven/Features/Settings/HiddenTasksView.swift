import SwiftUI

/// Phase 80 (discovery study): restore UI for templates the user has
/// dismissed via "Not for my home" on a task detail sheet. Lists every
/// `dismissed_templates` row across the user's properties with a one-tap
/// Restore button per row. Restoring deletes the row and the reconciler
/// re-seeds the template on its next pass.
struct HiddenTasksView: View {
    @EnvironmentObject private var appState: AppState

    @State private var dismissals: [DismissedTemplateRow] = []
    @State private var properties: [PropertyRow] = []
    @State private var isLoading = true
    @State private var restoring: Set<UUID> = []

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if dismissals.isEmpty {
                emptyState
            } else {
                listView
            }
        }
        .navigationTitle("Hidden Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .background(HavenColors.background)
        .task { await load() }
        .trackScreen("HiddenTasksView")
    }

    private var loadingView: some View {
        ProgressView()
            .tint(HavenColors.navy800)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(HavenColors.textTertiary)
            Text("No hidden tasks")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
            Text("When you tap “Not for my home” on a task, it will land here so you can restore it later.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listView: some View {
        List {
            ForEach(groupedByProperty, id: \.propertyId) { group in
                Section {
                    ForEach(group.rows, id: \.id) { row in
                        rowView(row)
                    }
                } header: {
                    Text(propertyName(group.propertyId))
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(HavenColors.background)
    }

    private func rowView(_ row: DismissedTemplateRow) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle(row.templateKey))
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                if let category = category(row.templateKey) {
                    Text(category)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            Spacer(minLength: 8)
            Button {
                Task { await restore(row) }
            } label: {
                if restoring.contains(row.id) {
                    ProgressView()
                        .tint(HavenColors.action)
                        .scaleEffect(0.8)
                } else {
                    Text("Restore")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.action)
                }
            }
            .buttonStyle(.plain)
            .disabled(restoring.contains(row.id))
        }
        .padding(.vertical, 6)
    }

    private struct PropertyGroup {
        let propertyId: UUID
        let rows: [DismissedTemplateRow]
    }

    private var groupedByProperty: [PropertyGroup] {
        let byProperty = Dictionary(grouping: dismissals, by: { $0.propertyId })
        return byProperty
            .map { PropertyGroup(propertyId: $0.key, rows: $0.value.sorted { ($0.dismissedAt ?? .distantPast) > ($1.dismissedAt ?? .distantPast) }) }
            .sorted { propertyName($0.propertyId) < propertyName($1.propertyId) }
    }

    private func propertyName(_ id: UUID) -> String {
        properties.first(where: { $0.id == id })?.name ?? "Property"
    }

    /// `templateKey` is "Category:Title" — extract the title portion for
    /// display. Falls back to the full key if no colon.
    private func displayTitle(_ templateKey: String) -> String {
        guard let colonIndex = templateKey.firstIndex(of: ":") else {
            return templateKey
        }
        return String(templateKey[templateKey.index(after: colonIndex)...])
    }

    private func category(_ templateKey: String) -> String? {
        guard let colonIndex = templateKey.firstIndex(of: ":") else { return nil }
        return String(templateKey[..<colonIndex])
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        let db = DatabaseService.shared
        let fetchedProperties = (try? await db.fetchProperties()) ?? []
        properties = fetchedProperties
        var all: [DismissedTemplateRow] = []
        for property in fetchedProperties {
            let rows = (try? await db.fetchDismissedTemplates(propertyId: property.id)) ?? []
            all.append(contentsOf: rows)
        }
        dismissals = all
    }

    @MainActor
    private func restore(_ row: DismissedTemplateRow) async {
        restoring.insert(row.id)
        defer { restoring.remove(row.id) }
        do {
            try await DatabaseService.shared.restoreTemplate(propertyId: row.propertyId, templateKey: row.templateKey)
            let category = self.category(row.templateKey) ?? "unknown"
            Analytics.track(.templateRestored, [
                "template_key": row.templateKey,
                "category": category
            ])
            // Re-seed by re-running reconciler for the property. Since we
            // don't know exact systemId/category mapping here, fire the
            // broader reconcileAll so all templates re-evaluate.
            Task.detached {
                _ = await MaintenanceTaskReconciler.reconcileAll(
                    propertyId: row.propertyId,
                    householdId: row.householdId
                )
                NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            }
            dismissals.removeAll { $0.id == row.id }
        } catch {
            // Silent failure — user can retry.
        }
    }
}

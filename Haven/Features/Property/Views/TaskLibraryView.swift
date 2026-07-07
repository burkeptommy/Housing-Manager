import SwiftUI

/// Phase 80 (discovery study, Tom's prevention pass): the user-visible
/// escape hatch for everything they've ever hidden or snoozed. Three
/// sources roll up here:
///
///   1. `dismissed_categories` — household-level "Not for my home" on
///      a whole SystemCategory (e.g. they tapped Not applicable on
///      Tree Service in the vendor coverage gap dialog). Permanent if
///      `snoozedUntil` is nil; time-bounded if set + still in the future.
///
///   2. `dismissed_templates` — per-property "Not for my home" on a
///      specific template (Phase 80 discovery study). Permanent.
///
///   3. `dismissed_recommendations` — pre-Phase-80 dismissal table for
///      the Recommended-for-your-home library. Permanent.
///
/// One restore action per row. Restoring kicks
/// `MaintenanceTaskReconciler.reconcileAllForHousehold` so the next
/// reconcile re-seeds whatever just came back into scope.
///
/// Why a dedicated surface instead of folding into RecommendedServicesView:
/// the recommended view's mental model is "what could I add" — already
/// crowded with discovery affordances. The library's mental model is
/// "what did I say no to" — different decision frame. Apple Settings →
/// Notifications → Allowed Notifications is the design reference: a
/// flat list of explicit opt-outs.
struct TaskLibraryView: View {
    let householdId: UUID
    let propertyId: UUID

    @StateObject private var viewModel = TaskLibraryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var restoredToast: String?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                        if !viewModel.dismissedCategories.isEmpty {
                            section(
                                header: "HIDDEN CATEGORIES",
                                subtitle: "Marked 'Not for my home'",
                                rows: viewModel.dismissedCategories.map { row in
                                    LibraryRowData(
                                        title: row.category,
                                        subtitle: row.snoozedUntil.map {
                                            "Snoozed until \(Self.dateFormatter.string(from: $0))"
                                        } ?? "Permanent",
                                        accent: row.isActiveSnooze() ? HavenColors.warning : HavenColors.textSecondary,
                                        badge: row.isActiveSnooze() ? "SNOOZED" : "HIDDEN",
                                        onRestore: {
                                            await viewModel.restoreCategory(row.category, householdId: householdId)
                                            showRestoredToast(row.category)
                                        }
                                    )
                                }
                            )
                        }
                        if !viewModel.dismissedTemplates.isEmpty {
                            section(
                                header: "HIDDEN TASKS",
                                subtitle: "Specific tasks marked 'Not for my home'",
                                rows: viewModel.dismissedTemplates.map { row in
                                    LibraryRowData(
                                        title: prettyLabel(forTemplateKey: row.templateKey),
                                        subtitle: (row.reason ?? "not_applicable").replacingOccurrences(of: "_", with: " "),
                                        accent: HavenColors.textSecondary,
                                        badge: "HIDDEN",
                                        onRestore: {
                                            await viewModel.restoreTemplate(row.templateKey, propertyId: propertyId)
                                            showRestoredToast(prettyLabel(forTemplateKey: row.templateKey))
                                        }
                                    )
                                }
                            )
                        }
                        if !viewModel.dismissedRecommendations.isEmpty {
                            section(
                                header: "HIDDEN RECOMMENDATIONS",
                                subtitle: "Opt-in services you hid from Recommended for You",
                                rows: viewModel.dismissedRecommendations.map { templateKey in
                                    LibraryRowData(
                                        title: prettyLabel(forTemplateKey: templateKey),
                                        subtitle: "From Recommended for You",
                                        accent: HavenColors.textSecondary,
                                        badge: "HIDDEN",
                                        onRestore: {
                                            await viewModel.restoreRecommendation(templateKey, householdId: householdId)
                                            showRestoredToast(prettyLabel(forTemplateKey: templateKey))
                                        }
                                    )
                                }
                            )
                        }
                    }
                    .padding(HavenTheme.pageMargin)
                }
            }
        }
        .background(HavenColors.background)
        .navigationTitle("Hidden Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(householdId: householdId, propertyId: propertyId)
        }
        .overlay(alignment: .top) {
            if let restoredToast {
                Text(restoredToast)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .padding(.horizontal, HavenTheme.spacing16)
                    .padding(.vertical, HavenTheme.spacing8)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .havenShadow()
                    .padding(.top, HavenTheme.spacing8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: restoredToast)
    }

    private var emptyState: some View {
        VStack(spacing: HavenTheme.spacing16) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.success)
            Text("Nothing hidden")
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)
            Text("When you tap \"Not for my home\" on a task or category, it'll land here so you can bring it back later.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HavenTheme.spacing24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(HavenTheme.pageMargin)
    }

    @ViewBuilder
    private func section(header: String, subtitle: String, rows: [LibraryRowData]) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text(header)
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            Text(subtitle)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textSecondary)
            VStack(spacing: HavenTheme.spacing8) {
                ForEach(rows, id: \.title) { row in
                    libraryRow(row)
                }
            }
        }
    }

    @ViewBuilder
    private func libraryRow(_ row: LibraryRowData) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: HavenTheme.spacing8) {
                    Text(row.title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    Text(row.badge)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(row.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(row.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                Text(row.subtitle)
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                Haptics.light()
                Task { await row.onRestore() }
            } label: {
                Text("Restore")
                    .font(HavenTypography.uiLabel.weight(.semibold))
                    .foregroundStyle(HavenColors.action)
                    .padding(.horizontal, HavenTheme.spacing12)
                    .padding(.vertical, HavenTheme.spacing8)
                    .overlay(
                        Capsule().stroke(HavenColors.action.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.border, lineWidth: 1)
        )
    }

    private func showRestoredToast(_ name: String) {
        restoredToast = "\(name) restored"
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { self.restoredToast = nil }
        }
    }

    /// Convert a template_id like `HVAC:Air duct cleaning` into a human
    /// label for display. Library is the user-facing surface so we
    /// don't want raw colon-separated keys.
    private func prettyLabel(forTemplateKey key: String) -> String {
        guard let colon = key.firstIndex(of: ":") else { return key }
        return String(key[key.index(after: colon)...])
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
}

/// Phase 80 — thin wrapper that resolves householdId + propertyId from
/// the current AppState environment so the Settings entry can navigate
/// to TaskLibraryView without the caller plumbing IDs in by hand.
/// Mirrors the pattern MaintenancePreferencesView uses.
struct TaskLibrarySettingsLoader: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if let property = appState.primaryProperty {
            TaskLibraryView(householdId: property.householdId, propertyId: property.id)
        } else {
            VStack(spacing: HavenTheme.spacing16) {
                Image(systemName: "house.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(HavenColors.textSecondary)
                Text("No property loaded")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Add a property first, then come back here to see anything you've hidden.")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.spacing24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HavenColors.background)
            .navigationTitle("Hidden Tasks")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct LibraryRowData {
    let title: String
    let subtitle: String
    let accent: Color
    let badge: String
    let onRestore: () async -> Void
}

@MainActor
final class TaskLibraryViewModel: ObservableObject {
    @Published private(set) var dismissedCategories: [DismissedCategoryRow] = []
    @Published private(set) var dismissedTemplates: [DismissedTemplateRow] = []
    /// Recommendation table stores templateKeys only, not full rows.
    @Published private(set) var dismissedRecommendations: [String] = []
    @Published private(set) var isLoading = false

    var isEmpty: Bool {
        dismissedCategories.isEmpty
            && dismissedTemplates.isEmpty
            && dismissedRecommendations.isEmpty
    }

    private let db = DatabaseService.shared

    func load(householdId: UUID, propertyId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        // Three independent fetches. Run in parallel — they touch
        // different tables and the load shouldn't take longer than the
        // slowest one.
        async let categoriesReq = (try? db.fetchDismissedCategories()) ?? []
        async let templatesReq = (try? db.fetchDismissedTemplates(propertyId: propertyId)) ?? []
        async let recsReq = (try? db.fetchDismissedRecommendations(householdId: householdId)) ?? []
        let (categories, templates, recs) = await (categoriesReq, templatesReq, recsReq)
        // Filter expired snoozes (snoozedUntil <= now AND not nil) —
        // those rows aren't actively suppressing anything.
        let now = Date()
        dismissedCategories = categories.filter { row in
            if row.snoozedUntil == nil { return true }
            return row.isActiveSnooze(now: now)
        }
        dismissedTemplates = templates
        dismissedRecommendations = Array(recs)
    }

    func restoreCategory(_ category: String, householdId: UUID) async {
        do {
            try await db.undismissCategory(category: category)
            dismissedCategories.removeAll { $0.category == category }
            Analytics.track(.taskLibraryItemRestored, [
                "type": "category",
                "value": category
            ])
            await triggerReconcile(householdId: householdId)
        } catch {
            print("[TaskLibrary] restoreCategory failed: \(error)")
        }
    }

    func restoreTemplate(_ templateKey: String, propertyId: UUID) async {
        do {
            try await db.restoreTemplate(propertyId: propertyId, templateKey: templateKey)
            dismissedTemplates.removeAll { $0.templateKey == templateKey }
            Analytics.track(.taskLibraryItemRestored, [
                "type": "template",
                "value": templateKey
            ])
            if let user = try? await db.fetchCurrentUser(), let hid = user.householdId {
                await triggerReconcile(householdId: hid)
            }
        } catch {
            print("[TaskLibrary] restoreTemplate failed: \(error)")
        }
    }

    func restoreRecommendation(_ templateKey: String, householdId: UUID) async {
        do {
            try await db.restoreRecommendation(householdId: householdId, templateKey: templateKey)
            dismissedRecommendations.removeAll { $0 == templateKey }
            Analytics.track(.taskLibraryItemRestored, [
                "type": "recommendation",
                "value": templateKey
            ])
        } catch {
            print("[TaskLibrary] restoreRecommendation failed: \(error)")
        }
    }

    private func triggerReconcile(householdId: UUID) async {
        // Fire the household-wide reconcile so anything that just came
        // back into scope gets re-seeded. Don't await the result —
        // reconciler will post `.maintenanceTaskChanged` when done.
        Task.detached {
            _ = await MaintenanceTaskReconciler.reconcileAllForHousehold(householdId: householdId)
        }
    }
}

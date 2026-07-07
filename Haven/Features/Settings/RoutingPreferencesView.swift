import SwiftUI

/// Phase 65: Settings view listing every routing preference the household
/// has set. Edit to change the route for a category; swipe to delete to
/// return to the Q36 tier default. "Reset all preferences" button
/// removes every row for the household.
struct RoutingPreferencesView: View {
    @State private var preferences: [RoutingPreferenceRow] = []
    @State private var isLoading = true
    @State private var householdId: UUID?
    @State private var loadError: String?
    @State private var showResetConfirmation = false

    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if preferences.isEmpty {
                emptyStateSection
            } else {
                preferencesSection
                resetSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Task Routing")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .confirmationDialog(
            "Reset all task routing preferences?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                Task { await resetAll() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your Q36 preference tier (DIY / Mix of both / Hire it out) stays in place. Only per-category overrides will be cleared.")
        }
    }

    private var emptyStateSection: some View {
        Section {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("No per-category preferences yet")
                    .font(HavenTypography.headline)
                Text("Your global preference tier (from Settings → Maintenance Preferences) is driving every task. Once you start routing individual tasks from the Maintenance tab, your per-category defaults will appear here.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
        }
    }

    private var preferencesSection: some View {
        Section {
            ForEach(preferences) { pref in
                HStack(spacing: HavenTheme.spacing12) {
                    Image(systemName: Self.icon(for: pref.preferredRoute))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pref.taskCategory)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Route: \(Self.label(for: pref.preferredRoute))\(pref.scopeType == "template" ? " · template override" : "")")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await delete(pref) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        } header: {
            Text("\(preferences.count) preference\(preferences.count == 1 ? "" : "s")")
        } footer: {
            Text("Category-level rows apply to every task in that category. Template-level rows override a single template without touching the category default.")
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Reset all preferences")
                    Spacer()
                }
            }
        }
    }

    private static func icon(for route: String) -> String {
        switch route {
        case "vendor": return "person.fill.checkmark"
        case "handyman": return "wrench.adjustable.fill"
        case "diy": return "hand.raised.fill"
        default: return "questionmark.circle"
        }
    }

    private static func label(for route: String) -> String {
        switch route {
        case "vendor": return "Vendor"
        case "handyman": return "Handyman"
        case "diy": return "DIY"
        default: return route.capitalized
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let hId = user.householdId else {
                loadError = "No household found."
                return
            }
            householdId = hId
            preferences = try await DatabaseService.shared.fetchRoutingPreferences(householdId: hId)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func delete(_ pref: RoutingPreferenceRow) async {
        do {
            try await DatabaseService.shared.deleteRoutingPreference(id: pref.id)
            preferences.removeAll { $0.id == pref.id }
            Haptics.success()
            Analytics.track(.routingPreferenceResetAll, ["count": 1, "category": pref.taskCategory])
        } catch {
            Haptics.error()
        }
    }

    private func resetAll() async {
        guard let householdId else { return }
        // Delete row-by-row and only drop the rows that actually
        // deleted — the old version cleared the whole local array and
        // fired a success haptic even when some deletes failed, so
        // "reset" preferences came back on the next load.
        var succeeded: Set<UUID> = []
        var failedCount = 0
        for pref in preferences {
            do {
                try await DatabaseService.shared.deleteRoutingPreference(id: pref.id)
                succeeded.insert(pref.id)
            } catch {
                failedCount += 1
            }
        }
        preferences.removeAll { succeeded.contains($0.id) }
        if failedCount == 0 {
            Haptics.success()
        } else {
            Haptics.error()
            loadError = "Couldn't reset \(failedCount) preference\(failedCount == 1 ? "" : "s"). Pull to refresh and try again."
        }
        Analytics.track(.routingPreferenceResetAll, ["count": succeeded.count])
        _ = householdId
    }
}

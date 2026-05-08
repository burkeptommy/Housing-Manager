import SwiftUI

/// Phase 54C: "Recommended for your home" browseable library of
/// value-preservation services. Populated from every
/// `MaintenanceTemplate` where `isEssential == false`, filtered by:
///
/// 1. Already-scheduled tasks (no point re-offering something that's
///    already on the schedule).
/// 2. `dismissed_recommendations` rows (user tapped "Hide").
/// 3. Template `requiredSubtypes` not satisfied by the user's home
///    (e.g. synthetic-turf templates on a natural-lawn property).
///
/// Reference apps: Apple Health "Browse" tab (separate-surface
/// discovery), Spotify "Made for You" (opt-in recommendations in a
/// parallel library), Notion templates gallery (additions, not
/// auto-applied).
struct RecommendedServicesView: View {
    let householdId: UUID
    let propertyId: UUID
    /// Optional dismissal callback for callers that want to react to
    /// dismissals (e.g. refresh the dashboard's count).
    var onDismiss: (() -> Void)? = nil

    @StateObject private var viewModel = RecommendedServicesViewModel()
    @State private var showResetConfirm = false
    @State private var scheduledToastMessage: String?
    // Phase 59: lazy-fetched property so we can present UpdateHomeDetailsSheet.
    @State private var property: PropertyRow?
    @State private var showUpdateHomeDetails = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.groups.isEmpty {
                ProgressView("Loading recommendations...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.groups.isEmpty {
                emptyState
            } else {
                mainList
            }
        }
        .background(HavenColors.background)
        .navigationTitle("Recommended for You")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(
                householdId: householdId,
                propertyId: propertyId
            )
        }
        .overlay(alignment: .top) {
            if let message = scheduledToastMessage {
                Text(message)
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
        .animation(.easeInOut, value: scheduledToastMessage)
        .alert("Show hidden recommendations?", isPresented: $showResetConfirm) {
            Button("Show all") {
                Task {
                    await viewModel.resetDismissals(householdId: householdId)
                    onDismiss?()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every recommendation you've dismissed will come back.")
        }
        .sheet(isPresented: $showUpdateHomeDetails) {
            if let property {
                UpdateHomeDetailsSheet(property: property) {
                    Task {
                        await viewModel.load(householdId: householdId, propertyId: propertyId)
                    }
                }
            }
        }
        .task(id: propertyId) {
            // Phase 59: fetch the property once so the Update Home Details
            // cross-link can present its sheet without lazily fetching on tap.
            if property == nil {
                property = try? await DatabaseService.shared.fetchProperty(id: propertyId)
            }
        }
        .trackScreen("RecommendedServicesView")
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("You're all set", systemImage: "sparkles")
        } description: {
            Text("Everything Chez would suggest for your home is either on your schedule or dismissed. Check back after a season change.")
        } actions: {
            if viewModel.hasDismissals {
                Button {
                    showResetConfirm = true
                } label: {
                    Text("Show all hidden recommendations")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.navy700)
                }
            }
        }
    }

    private var mainList: some View {
        List {
            Section {
                Text("Browse services Chez thinks your home could benefit from. Schedule any that fit, or drop them on your contractor's punch list.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))

                // Phase 59: cross-link to Update Home Details. Tapping here
                // opens the toggle sheet so a user browsing recommendations
                // can flip on "I have a whole-home filter" / "I have an EV
                // charger" and see related services unlock.
                updateHomeDetailsRow
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
            }

            ForEach(viewModel.groups, id: \.category) { group in
                Section {
                    ForEach(group.items, id: \.templateKey) { item in
                        recommendationCard(item)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                } header: {
                    HStack {
                        Image(systemName: group.icon)
                            .foregroundStyle(HavenColors.navy700)
                            .font(.caption)
                        Text(group.category.uppercased())
                            .font(HavenTypography.uiSectionHeader)
                            .foregroundStyle(HavenColors.textTertiary)
                            .tracking(1.5)
                    }
                }
            }

            if viewModel.hasDismissals {
                Section {
                    Button {
                        showResetConfirm = true
                    } label: {
                        Text("Show all hidden recommendations")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy700)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(HavenColors.background)
        .refreshable {
            await viewModel.load(householdId: householdId, propertyId: propertyId)
        }
    }

    /// Phase 59: entry point into UpdateHomeDetailsSheet. Only renders
    /// once the property has been fetched so the sheet can present
    /// without a loading state.
    @ViewBuilder
    private var updateHomeDetailsRow: some View {
        if property != nil {
            Button {
                Haptics.selection()
                showUpdateHomeDetails = true
            } label: {
                HavenCard {
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: "house.lodge.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 36, height: 36)
                            .background(HavenColors.beige200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Update what's in your home")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Toggle systems you have so Chez can recommend the right services.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func recommendationCard(_ item: RecommendedItem) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 36, height: 36)
                        .background(HavenColors.beige200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.template.title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(item.metadataLine)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer(minLength: 0)
                }

                Text(item.template.description)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)

                if let notes = item.template.notes, !notes.isEmpty {
                    Text(notes)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                HStack(spacing: HavenTheme.spacing8) {
                    Button {
                        Haptics.medium()
                        Task {
                            await scheduleItem(item)
                        }
                    } label: {
                        Text("Schedule it")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textOnAction)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .frame(maxWidth: .infinity)
                            .background(HavenColors.action)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.scheduling.contains(item.templateKey))

                    if item.canGoToHandyman {
                        Button {
                            Haptics.light()
                            Task { await addToHandyman(item) }
                        } label: {
                            Text("Add to contractor")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                                .padding(.horizontal, 12)
                                .frame(height: 36)
                                .frame(maxWidth: .infinity)
                                .background(HavenColors.creamLight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(HavenColors.beige300, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        Haptics.light()
                        Task { await hide(item) }
                    } label: {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                            .frame(width: 36, height: 36)
                            .background(HavenColors.creamLight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(HavenColors.beige300, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Hide this recommendation")
                }
            }
        }
    }

    // MARK: - Actions

    private func scheduleItem(_ item: RecommendedItem) async {
        let taskId = await viewModel.schedule(
            item: item,
            propertyId: propertyId,
            householdId: householdId
        )
        if taskId != nil {
            Haptics.success()
            showToast("Added to your schedule")
            Analytics.track(.recommendedServiceScheduled, [
                "template": item.templateKey,
            ])
        } else {
            Haptics.error()
            showToast("Couldn't schedule. Please try again")
        }
    }

    private func addToHandyman(_ item: RecommendedItem) async {
        let ok = await viewModel.addToHandyman(
            item: item,
            propertyId: propertyId,
            householdId: householdId
        )
        if ok {
            Haptics.success()
            showToast("Added to your handyman punch list")
            Analytics.track(.handymanPunchItemAdded, [
                "source": "recommended",
                "template": item.templateKey,
            ])
        }
    }

    private func hide(_ item: RecommendedItem) async {
        await viewModel.hide(item: item, householdId: householdId)
        Analytics.track(.recommendedServiceDismissed, [
            "template": item.templateKey,
        ])
    }

    private func showToast(_ message: String) {
        scheduledToastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { self.scheduledToastMessage = nil }
        }
    }
}

// MARK: - View model

@MainActor
final class RecommendedServicesViewModel: ObservableObject {
    struct Group {
        let category: String
        let icon: String
        let items: [RecommendedItem]
    }

    @Published private(set) var groups: [Group] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasDismissals = false
    @Published private(set) var scheduling: Set<String> = []

    private let db = DatabaseService.shared

    func load(householdId: UUID, propertyId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        let dismissed = (try? await db.fetchDismissedRecommendations(householdId: householdId)) ?? []
        hasDismissals = !dismissed.isEmpty

        let existingTasks = (try? await db.fetchMaintenanceTasks(propertyId: propertyId)) ?? []
        let scheduledKeys = Set(
            existingTasks
                .filter { $0.isArchived != true }
                .compactMap { $0.templateId }
        )
        let systems = (try? await db.fetchHomeSystems(propertyId: propertyId, topLevelOnly: false)) ?? []

        // Flatten every non-essential template from the library.
        var items: [RecommendedItem] = []
        for (_, templates) in MaintenanceTemplates.allTemplates {
            for template in templates where template.isEssential == false {
                let key = template.templateKey

                // Skip if already on the schedule.
                if scheduledKeys.contains(key) { continue }
                // Skip if the household has dismissed it.
                if dismissed.contains(key) { continue }
                // Skip when requiredSubtypes gate isn't met — we use the
                // household's existing home_systems subtype tokens as a
                // proxy so synthetic-turf templates don't show up in
                // natural-lawn homes.
                if !isApplicable(template: template, systems: systems) { continue }

                items.append(RecommendedItem(template: template))
            }
        }

        // Group by registry category.
        let grouped = Dictionary(grouping: items) { $0.template.systemCategory }
        let sortedGroups: [Group] = grouped
            .sorted { $0.key < $1.key }
            .map { (category, items) in
                let meta = SystemCategoryRegistry.metaForCategory(category)
                return Group(
                    category: meta?.displayName ?? category,
                    icon: meta?.icon ?? "sparkles",
                    items: items.sorted { $0.template.title < $1.template.title }
                )
            }
        groups = sortedGroups
    }

    func schedule(item: RecommendedItem, propertyId: UUID, householdId: UUID) async -> UUID? {
        scheduling.insert(item.templateKey)
        defer { scheduling.remove(item.templateKey) }
        let taskId = await MaintenanceTaskReconciler.scheduleOptInTemplate(
            item.template,
            propertyId: propertyId,
            householdId: householdId
        )
        if taskId != nil {
            // Remove from the browse list — it's now on the schedule.
            removeItemLocally(item)
        }
        return taskId
    }

    func addToHandyman(item: RecommendedItem, propertyId: UUID, householdId: UUID) async -> Bool {
        var insert = HandymanPunchItemInsert(
            householdId: householdId,
            propertyId: propertyId,
            title: item.template.title
        )
        insert.description = item.template.description
        insert.source = "recommended"
        insert.estimatedMinutes = item.template.diyEffortMinutes
        if let session = await HavenSupabase.safeSession(timeout: 1.0) {
            insert.addedByUserId = session.user.id
        }
        do {
            _ = try await db.createHandymanPunchItem(insert)
            removeItemLocally(item)
            return true
        } catch {
            print("[RecommendedServicesVM] addToHandyman failed: \(error)")
            return false
        }
    }

    func hide(item: RecommendedItem, householdId: UUID) async {
        let session = await HavenSupabase.safeSession(timeout: 1.0)
        do {
            try await db.dismissRecommendation(
                householdId: householdId,
                templateId: item.templateKey,
                userId: session?.user.id
            )
            removeItemLocally(item)
            hasDismissals = true
        } catch {
            print("[RecommendedServicesVM] dismissRecommendation failed: \(error)")
        }
    }

    func resetDismissals(householdId: UUID) async {
        do {
            try await db.resetDismissedRecommendations(householdId: householdId)
            hasDismissals = false
            // Caller is expected to refetch; groups won't re-populate
            // until a subsequent `load` call.
        } catch {
            print("[RecommendedServicesVM] resetDismissals failed: \(error)")
        }
    }

    // MARK: - Helpers

    private func removeItemLocally(_ item: RecommendedItem) {
        groups = groups.compactMap { group in
            let filtered = group.items.filter { $0.templateKey != item.templateKey }
            if filtered.isEmpty { return nil }
            return Group(category: group.category, icon: group.icon, items: filtered)
        }
    }

    /// Phase 54C: Approximate subtype match — a template passes when
    /// every required subtype is present on any top-level system row
    /// in the household. Templates with empty `requiredSubtypes` always
    /// pass. Exact subtype tokens aren't expanded here (we don't run
    /// the reconciler's `activeSubtypes(category:)` mapping) — the
    /// recommended surface is a browsing affordance and users can
    /// dismiss anything they don't actually want.
    private func isApplicable(template: MaintenanceTemplate, systems: [HomeSystemRow]) -> Bool {
        guard !template.requiredSubtypes.isEmpty else { return true }
        let allTokens = Set(systems.compactMap { $0.subtype?.lowercased() })
        let required = Set(template.requiredSubtypes.map { $0.lowercased() })
        return required.isSubset(of: allTokens)
    }
}

// MARK: - Item model

struct RecommendedItem {
    let template: MaintenanceTemplate

    var templateKey: String { template.templateKey }

    var icon: String {
        SystemCategoryRegistry.metaForCategory(template.systemCategory)?.icon
            ?? "sparkles"
    }

    /// Compact metadata line under the title: cost, frequency, and
    /// seasonal timing if present. Pattern matches the Maintenance
    /// tab's card metadata so the visual language carries over.
    var metadataLine: String {
        var parts: [String] = []
        if !template.estimatedCostRange.isEmpty {
            parts.append(template.estimatedCostRange)
        }
        parts.append(template.frequency)
        if let season = template.seasonalTiming, !season.isEmpty {
            parts.append("Best in \(season.lowercased())")
        }
        return parts.joined(separator: " · ")
    }

    /// Only small handyman-suitable templates get the "Add to handyman"
    /// button. Vendor-only / safety-floored templates get the primary
    /// "Schedule it" CTA plus the Hide affordance.
    var canGoToHandyman: Bool {
        if template.safetyFloor { return false }
        guard let minutes = template.diyEffortMinutes else { return false }
        return minutes <= 60
    }
}

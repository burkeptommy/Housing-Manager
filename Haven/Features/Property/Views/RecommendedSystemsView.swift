import SwiftUI

/// Phase 95 (audit gap #40) — discoverability surface for adding
/// systems the homeowner hasn't captured yet.
///
/// The quiz only captures ~10 of the 30+ category templates in
/// `SystemCategoryRegistry`. Specialty systems (wine cellar, sauna,
/// elevator, generator, EV charger, snow melt, irrigation, etc.)
/// frequently come up later when the homeowner remembers they have
/// one. Without a browse surface they had to hunt through the "Add
/// system" form's category dropdown — which is alphabetized and
/// dense.
///
/// This view groups categories by tier (universal / conditional /
/// specialty), filters out anything the household already has on
/// `home_systems`, and one-tap routes into AddSystemView with the
/// right category preselected.
struct RecommendedSystemsView: View {
    let propertyId: UUID
    var onSystemAdded: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var existingCategories: Set<String> = []
    @State private var selectedCategory: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                    headerCard
                    section(title: "Universal", subtitle: "Every home has these.", metas: filtered(SystemCategoryRegistry.universal))
                    section(title: "Conditional", subtitle: "Depends on your property.", metas: filtered(SystemCategoryRegistry.conditional))
                    section(title: "Specialty", subtitle: "High-end systems we see in HNW homes.", metas: filtered(SystemCategoryRegistry.specialty))
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("Recommended systems")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await load()
            }
            .sheet(item: Binding(
                get: { selectedCategory.map(SelectedCategoryWrapper.init) },
                set: { selectedCategory = $0?.value }
            )) { wrapper in
                AddSystemView(
                    propertyID: propertyId,
                    prefilledCategory: wrapper.value,
                    onComplete: { _ in
                        existingCategories.insert(wrapper.value)
                        onSystemAdded?()
                    }
                )
            }
        }
    }

    private struct SelectedCategoryWrapper: Identifiable {
        let value: String
        var id: String { value }
    }

    private var headerCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("Add what we missed")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Tap any category we don't already have on file. Chez seeds the right maintenance schedule once the system is added.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func section(title: String, subtitle: String, metas: [SystemCategoryMeta]) -> some View {
        if !metas.isEmpty {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(subtitle)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(metas, id: \.categoryKey) { meta in
                        Button {
                            Haptics.selection()
                            Analytics.track(.recommendedSystemTapped, [
                                "category": meta.categoryKey,
                                "tier": title.lowercased()
                            ])
                            selectedCategory = meta.categoryKey
                        } label: {
                            HStack(spacing: HavenTheme.spacing12) {
                                Image(systemName: meta.icon)
                                    .frame(width: 28)
                                    .foregroundStyle(HavenColors.navy700)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(meta.displayName)
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    if let cadence = meta.defaultCadence {
                                        Text(cadence)
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(HavenColors.action)
                            }
                            .padding(HavenTheme.spacing12)
                            .frame(minHeight: 56)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                            .overlay(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .strokeBorder(HavenColors.border, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    /// Drops categories the household already has on file so the
    /// user only sees "what's missing." Compares case-insensitively
    /// against `existingCategories` populated from `home_systems`.
    private func filtered(_ source: [SystemCategoryMeta]) -> [SystemCategoryMeta] {
        let existingLowered = Set(existingCategories.map { $0.lowercased() })
        return source.filter { !existingLowered.contains($0.categoryKey.lowercased()) }
    }

    @MainActor
    private func load() async {
        defer { isLoading = false }
        do {
            let systems = try await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId)
            existingCategories = Set(systems.map { $0.category })
        } catch {
            existingCategories = []
        }
    }
}

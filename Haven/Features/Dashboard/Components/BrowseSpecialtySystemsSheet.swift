import SwiftUI

/// Browse Tier 3 specialty systems that the user's property doesn't have yet.
/// Grouped by category (Outdoor Amenities, Smart Home & Energy, etc.).
/// Tapping "Add" creates a home_systems row in "needs a vendor" state.
struct BrowseSpecialtySystemsSheet: View {
    let propertyId: UUID
    let householdId: UUID
    let existingCategories: Set<String>
    var onSystemAdded: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var addedCategories: Set<String> = []
    @State private var isAdding: String?

    private var groups: [(group: String, items: [SystemCategoryMeta])] {
        SystemCategoryRegistry.specialtyGroups(excluding: existingCategories.union(addedCategories))
    }

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    emptyState
                } else {
                    systemList
                }
            }
            .background(HavenColors.background)
            .navigationTitle("Specialty Systems")
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
        }
    }

    private var emptyState: some View {
        VStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(HavenColors.success)
            Text("All specialty systems added")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("You can always add a custom system from the coverage screen.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, 60)
    }

    private var systemList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                Text("Tap to add systems your home has. They'll appear in your coverage list.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.top, HavenTheme.spacing8)

                ForEach(groups, id: \.group) { group in
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        Text(group.group.uppercased())
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(.bottom, 4)

                        ForEach(group.items) { meta in
                            specialtyRow(meta)
                        }
                    }
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing16)
            .padding(.bottom, HavenTheme.spacing48)
        }
    }

    private func specialtyRow(_ meta: SystemCategoryMeta) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: meta.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(HavenColors.textPrimary)
                .frame(width: 36, height: 36)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(meta.displayName)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                if let cadence = meta.defaultCadence {
                    Text("Typical: \(cadence)")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            Spacer()

            Button {
                addSystem(meta)
            } label: {
                if isAdding == meta.categoryKey {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 60, height: 32)
                } else {
                    Text("Add")
                        .font(.custom("Inter", size: 13).weight(.semibold))
                        .foregroundStyle(HavenColors.textOnAction)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(HavenColors.navy800)
                        .clipShape(Capsule())
                }
            }
            .buttonStyle(.plain)
            .disabled(isAdding != nil)
        }
        .padding(.vertical, HavenTheme.spacing8)
        .padding(.horizontal, HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.border, lineWidth: 1)
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private func addSystem(_ meta: SystemCategoryMeta) {
        isAdding = meta.categoryKey
        Haptics.medium()

        Task {
            let insert = HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: meta.displayName,
                category: meta.categoryKey
            )
            do {
                _ = try await DatabaseService.shared.createHomeSystem(insert)
                await MainActor.run {
                    _ = withAnimation(.easeInOut(duration: 0.3)) {
                        addedCategories.insert(meta.categoryKey)
                    }
                    isAdding = nil
                    Haptics.success()
                    Analytics.track(.specialtySystemAdded, ["category": meta.categoryKey])
                    NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
                    onSystemAdded?()
                }
            } catch {
                await MainActor.run {
                    isAdding = nil
                    Haptics.error()
                }
            }
        }
    }
}

import SwiftUI

/// Settings entry for the vendor preference tier. Lets users adjust their
/// hands-on / hands-off preference without retaking the quiz. Saving fires
/// the same household-wide reconciler pass Q36 fires, with a confirmation
/// dialog up front so the user doesn't accidentally rebalance their whole
/// task list. Build 88: replaced the 1-10 slider with a 3-chip picker.
struct MaintenancePreferencesView: View {
    @State private var selectedTier: VendorPreferenceTier = .mixed
    @State private var initialLoadCompleted = false
    @State private var primaryPropertyId: UUID?
    @State private var householdId: UUID?
    @State private var showConfirmDialog = false
    @State private var isSaving = false
    @State private var toastMessage: String?
    @State private var loadError: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                Text("Tasks that could go either way get assigned based on this setting. Personal-only tasks (replace air filters) stay personal. Vendor-only tasks (chimney sweep) stay vendor.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // 3-tier picker cards
                VStack(spacing: HavenTheme.spacing12) {
                    ForEach(VendorPreferenceTier.allCases) { tier in
                        tierCard(tier)
                    }
                }

                DisclosureGroup("How this works") {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        howItWorksRow(
                            icon: "1.circle.fill",
                            text: "\"I handle it\" keeps everything personal except licensed-pro work."
                        )
                        howItWorksRow(
                            icon: "2.circle.fill",
                            text: "\"Mix of both\" sends bigger jobs (over 30 minutes) to vendors."
                        )
                        howItWorksRow(
                            icon: "3.circle.fill",
                            text: "\"Hire it out\" routes nearly everything to a vendor. Your list becomes a coordination dashboard."
                        )
                        howItWorksRow(
                            icon: "checkmark.shield.fill",
                            text: "Tasks you've already assigned to a contractor are never touched."
                        )
                    }
                    .padding(.top, HavenTheme.spacing8)
                }
                .tint(HavenColors.navy)
                .font(HavenTypography.uiLabel)

                if let loadError {
                    Text(loadError)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }

                HavenButton(
                    title: isSaving ? "Saving..." : "Save",
                    action: {
                        Haptics.medium()
                        showConfirmDialog = true
                    }
                )
                .disabled(isSaving || primaryPropertyId == nil)
            }
            .padding(HavenTheme.spacing20)
        }
        .background(HavenColors.cream)
        .navigationTitle("Maintenance Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("MaintenancePreferencesView")
        .task {
            await loadInitialState()
        }
        .confirmationDialog(
            "This will rebalance your maintenance tasks. Continue?",
            isPresented: $showConfirmDialog,
            titleVisibility: .visible
        ) {
            Button("Save and rebalance") {
                Task { await save() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Tasks you've already assigned to a contractor stay put. Personal-only and vendor-only tasks aren't affected.")
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.success)
                    Text(toastMessage)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                }
                .padding()
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: toastMessage)
    }

    // MARK: - Tier Card

    @ViewBuilder
    private func tierCard(_ tier: VendorPreferenceTier) -> some View {
        let isSelected = selectedTier == tier
        Button {
            Haptics.selection()
            withAnimation(HavenTheme.animationQuick) {
                selectedTier = tier
            }
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                let icon: String = {
                    switch tier {
                    case .diy: return "wrench.and.screwdriver.fill"
                    case .mixed: return "person.2.fill"
                    case .hireOut: return "briefcase.fill"
                    }
                }()

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? HavenColors.textOnNavy : HavenColors.navy)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.label)
                        .font(HavenTypography.headline)
                        .foregroundStyle(isSelected ? HavenColors.textOnNavy : HavenColors.textPrimary)
                    Text(tier.subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(isSelected ? HavenColors.textOnNavy.opacity(0.8) : HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(HavenColors.textOnNavy)
                }
            }
            .padding(HavenTheme.spacing16)
            .background(isSelected ? HavenColors.navy : HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .strokeBorder(
                        isSelected ? Color.clear : HavenColors.border,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func howItWorksRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.navy)
                .frame(width: 18)
            Text(text)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func loadInitialState() async {
        guard !initialLoadCompleted else { return }
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                loadError = "No household found. Please sign in again."
                return
            }
            self.householdId = householdId
            let properties = try await DatabaseService.shared.fetchProperties()
            guard let primary = properties.first(where: { $0.householdId == householdId }) else {
                loadError = "Add a property before setting preferences."
                return
            }
            primaryPropertyId = primary.id
            selectedTier = MaintenanceTaskReconciler.preferenceTierFromProperty(primary)
            initialLoadCompleted = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func save() async {
        guard let propertyId = primaryPropertyId,
              let householdId = householdId else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            var update = PropertyUpdate()
            var attrs = (try? await DatabaseService.shared.fetchProperty(id: propertyId))?.attributes ?? [:]
            attrs["vendor_preference_tier"] = .string(selectedTier.attributeValue)
            update.attributes = attrs
            _ = try await DatabaseService.shared.updateProperty(id: propertyId, update)
        } catch {
            loadError = error.localizedDescription
            Haptics.error()
            return
        }

        let result = await MaintenanceTaskReconciler.reconcileAllForHousehold(householdId: householdId)
        let flippedCount = result.added.count + result.removed.count

        Haptics.success()
        toastMessage = flippedCount == 0
            ? "Saved. No task changes needed."
            : "Saved. Updated \(flippedCount) task\(flippedCount == 1 ? "" : "s")."
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)

        try? await Task.sleep(nanoseconds: 2_500_000_000)
        toastMessage = nil
    }
}

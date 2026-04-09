import SwiftUI

/// Build 87: Settings entry for the DIY vs Vendor preference slider that
/// the House Quiz captures at Q36. Lets users adjust their hands-on /
/// hands-off preference later without retaking the quiz. Saving fires the
/// same household-wide reconciler pass Q36 fires, with a confirmation
/// dialog up front so the user doesn't accidentally rebalance their whole
/// task list.
struct MaintenancePreferencesView: View {
    @State private var sliderValue: Int = 5
    @State private var initialLoadCompleted = false
    @State private var primaryPropertyId: UUID?
    @State private var householdId: UUID?
    @State private var showConfirmDialog = false
    @State private var isSaving = false
    @State private var toastMessage: String?
    @State private var loadError: String?
    @State private var eitherTaskEfforts: [Int] = []

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                Text("Tasks that could go either way get assigned based on this setting. Personal-only tasks (replace air filters) stay personal. Vendor-only tasks (chimney sweep) stay vendor.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VendorPreferenceSlider(
                    value: $sliderValue,
                    leftLabel: "DIY everything",
                    rightLabel: "Let pros handle it",
                    minValue: 1,
                    maxValue: 10,
                    previewLabel: { value in
                        previewText(forValue: value)
                    }
                )

                DisclosureGroup("How this works") {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        howItWorksRow(
                            icon: "1.circle.fill",
                            text: "Quick tasks (under 30 minutes) almost always stay personal."
                        )
                        howItWorksRow(
                            icon: "2.circle.fill",
                            text: "Bigger jobs flip to a vendor as you slide right."
                        )
                        howItWorksRow(
                            icon: "3.circle.fill",
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
            // Hydrate slider from the existing attribute (default 5).
            sliderValue = MaintenanceTaskReconciler.preferenceLevelFromProperty(primary)

            // Build the cached either-task efforts so the live preview
            // shows real numbers as the user drags the slider.
            await loadEitherEfforts(propertyId: primary.id)
            initialLoadCompleted = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func loadEitherEfforts(propertyId: UUID) async {
        guard let tasks = try? await DatabaseService.shared.fetchMaintenanceTasks(propertyId: propertyId) else {
            return
        }
        var efforts: [String: Int] = [:]
        for (_, sectionTemplates) in MaintenanceTemplates.allTemplates {
            for template in sectionTemplates where template.assignmentType == .either {
                efforts[template.templateKey] = template.diyEffortMinutes ?? 60
            }
        }
        let matched = tasks.compactMap { task -> Int? in
            guard let key = task.templateId, let effort = efforts[key] else { return nil }
            return effort
        }
        eitherTaskEfforts = matched
    }

    private func previewText(forValue value: Int) -> String {
        let total = eitherTaskEfforts.count
        guard total > 0 else {
            switch value {
            case 1...3:  return "You'll handle most maintenance tasks yourself."
            case 4...6:  return "Quick tasks stay personal. Bigger jobs route to vendors."
            default:     return "We'll route every task we can to a vendor."
            }
        }
        let threshold = max(0, (11 - value) * 30)
        let flipCount = eitherTaskEfforts.filter { $0 > threshold }.count
        if flipCount == 0 {
            return "At this setting, none of your flexible tasks will be vendor-managed."
        }
        if flipCount == 1 {
            return "At this setting, 1 of your flexible tasks will be vendor-managed."
        }
        return "At this setting, roughly \(flipCount) of your flexible tasks will be vendor-managed."
    }

    private func save() async {
        guard let propertyId = primaryPropertyId,
              let householdId = householdId else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            // Persist the new value to the property attribute.
            var update = PropertyUpdate()
            var attrs = (try? await DatabaseService.shared.fetchProperty(id: propertyId))?.attributes ?? [:]
            attrs["vendor_preference_level"] = .string(String(sliderValue))
            update.attributes = attrs
            _ = try await DatabaseService.shared.updateProperty(id: propertyId, update)
        } catch {
            loadError = error.localizedDescription
            Haptics.error()
            return
        }

        // Reconcile the household. The result tells us how many tasks the
        // pass actually flipped — surfaced in the success toast.
        let result = await MaintenanceTaskReconciler.reconcileAllForHousehold(householdId: householdId)
        let flippedCount = result.added.count + result.removed.count

        Haptics.success()
        toastMessage = flippedCount == 0
            ? "Saved. No task changes needed."
            : "Saved. Updated \(flippedCount) task\(flippedCount == 1 ? "" : "s")."
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)

        // Auto-dismiss the toast after a few seconds.
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        toastMessage = nil
    }
}

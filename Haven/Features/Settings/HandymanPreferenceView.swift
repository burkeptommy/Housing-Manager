import SwiftUI

/// Phase 63: Settings screen for changing the handyman preference that Q15b
/// captured during onboarding. Mirrors the MaintenancePreferencesView 3-chip
/// pattern but writes `properties.attributes.handyman_preference`. Switching
/// away from `has_one` also clears `households.preferred_handyman_contractor_id`
/// (the contractor row itself stays intact — users can re-pick later).
enum HandymanPreference: String, CaseIterable, Identifiable {
    case hasOne = "has_one"
    case doesDiy = "does_diy"
    case needsHelp = "needs_help"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hasOne: return "I have one I use regularly"
        case .doesDiy: return "I prefer to handle things myself"
        case .needsHelp: return "I need help finding one"
        }
    }

    var subtitle: String {
        switch self {
        case .hasOne: return "We'll route small tasks to them"
        case .doesDiy: return "We'll keep small tasks on your list"
        case .needsHelp: return "Haven will help you vet options"
        }
    }

    var icon: String {
        switch self {
        case .hasOne: return "person.fill.checkmark"
        case .doesDiy: return "hammer.fill"
        case .needsHelp: return "magnifyingglass"
        }
    }
}

struct HandymanPreferenceView: View {
    @State private var selection: HandymanPreference = .doesDiy
    @State private var primaryPropertyId: UUID?
    @State private var householdId: UUID?
    @State private var hadHandymanContractor: Bool = false
    @State private var isSaving = false
    @State private var toastMessage: String?
    @State private var loadError: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                Text("How do you typically handle small fixes and repairs around the house?")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("This helps Haven decide whether to route routine small-fix tasks to your handyman, keep them on your personal list, or offer to help you find someone.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: HavenTheme.spacing12) {
                    ForEach(HandymanPreference.allCases) { pref in
                        preferenceCard(pref)
                    }
                }

                if let loadError {
                    Text(loadError)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }

                HavenButton(
                    title: isSaving ? "Saving..." : "Save",
                    action: {
                        Haptics.medium()
                        Task { await save() }
                    }
                )
                .disabled(isSaving || primaryPropertyId == nil)
            }
            .padding(HavenTheme.spacing20)
        }
        .background(HavenColors.cream)
        .navigationTitle("Handyman Preference")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadInitialState() }
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
    private func preferenceCard(_ pref: HandymanPreference) -> some View {
        let isSelected = selection == pref
        Button {
            Haptics.selection()
            withAnimation(HavenTheme.animationQuick) {
                selection = pref
            }
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: pref.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? HavenColors.textOnNavy : HavenColors.navy)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pref.label)
                        .font(HavenTypography.headline)
                        .foregroundStyle(isSelected ? HavenColors.textOnNavy : HavenColors.textPrimary)
                    Text(pref.subtitle)
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
                    .strokeBorder(isSelected ? Color.clear : HavenColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func loadInitialState() async {
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                loadError = "No household found."
                return
            }
            self.householdId = householdId
            let properties = try await DatabaseService.shared.fetchProperties()
            guard let primary = properties.first(where: { $0.householdId == householdId }) else {
                loadError = "Add a property first."
                return
            }
            primaryPropertyId = primary.id
            let contractors = (try? await DatabaseService.shared.fetchContractors()) ?? []
            hadHandymanContractor = contractors.contains {
                $0.category?.caseInsensitiveCompare("Handyman") == .orderedSame
            }
            // Bug B5 fix: if the attribute isn't set (existing TestFlight
            // users pre-Phase-63) AND a Handyman-category contractor is
            // already in the household, default the picker to "has_one"
            // instead of "does_diy". The attribute-present case takes
            // priority so user's explicit choice is always respected.
            if let raw = primary.attributes?["handyman_preference"]?.stringValue,
               let parsed = HandymanPreference(rawValue: raw) {
                selection = parsed
            } else if hadHandymanContractor {
                selection = .hasOne
            }
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
            var attrs = (try? await DatabaseService.shared.fetchProperty(id: propertyId))?.attributes ?? [:]
            attrs["handyman_preference"] = .string(selection.rawValue)
            var update = PropertyUpdate()
            update.attributes = attrs
            _ = try await DatabaseService.shared.updateProperty(id: propertyId, update)

            // Switching away from has_one clears the household FK. The
            // contractor row itself is preserved so users who toggle back
            // later can re-link (or pick a different handyman from their
            // directory).
            if selection != .hasOne {
                var hUpdate = HouseholdUpdate()
                hUpdate.preferredHandymanContractorId = nil
                _ = try? await DatabaseService.shared.updateHousehold(id: householdId, hUpdate)
            }

            Haptics.success()
            toastMessage = "Saved"
            Analytics.track(.handymanPreferenceChanged, ["preference": selection.rawValue])
            NotificationCenter.default.post(name: .propertyChanged, object: nil)
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            toastMessage = nil
            dismiss()
        } catch {
            loadError = error.localizedDescription
            Haptics.error()
        }
    }
}

import SwiftUI

/// Single-step intercept shown after auth when the household has zero
/// properties (or the property has no street address). Used by:
/// - New users who somehow ended up authenticated without a property
/// - Soft-purged TestFlight users (their property was wiped)
///
/// All ATTOM enrichment + system + task creation goes through the shared
/// `PropertyCreationService` so this view stays in lockstep with the
/// in-app `AddPropertyFlow` and any future entry point.
struct AddressConfirmationIntercept: View {
    @EnvironmentObject var appState: AppState

    @State private var street: String = ""
    @State private var unit: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing24) {
                    Spacer().frame(height: 20)

                    // Branding
                    VStack(spacing: HavenTheme.spacing8) {
                        ChezBrandView(width: 104)
                        Text("Welcome back")
                            .font(HavenTypography.title)
                    }

                    VStack(spacing: HavenTheme.spacing8) {
                        Text("Where's your home?")
                            .font(HavenTypography.title2)
                        Text("We need an address to set up your household. We'll auto-detect systems and build your maintenance plan.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)

                    VStack(spacing: HavenTheme.spacing12) {
                        AddressAutocompleteField(
                            street: $street,
                            unit: $unit,
                            city: $city,
                            state: $state,
                            zipCode: $zipCode
                        )
                    }
                    .padding(HavenTheme.spacing16)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                    .padding(.horizontal, HavenTheme.pageMargin)

                    if let error = errorMessage {
                        Text(error)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.critical)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, HavenTheme.pageMargin)
                    }

                    Spacer()
                }
            }
            .background(HavenColors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                VStack {
                    HavenButton(title: isSubmitting ? "Setting up..." : "Continue") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting || !canSubmit)
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.bottom, HavenTheme.spacing16)
                .background(HavenColors.background)
            }
            .trackScreen("AddressConfirmationIntercept")
        }
    }

    private var canSubmit: Bool {
        !street.trimmingCharacters(in: .whitespaces).isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
            && !state.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @MainActor
    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                errorMessage = "Couldn't find your household. Try signing out and in."
                return
            }

            let address = AddressInput(
                street: street,
                unit: unit,
                city: city,
                state: state,
                zipCode: zipCode
            )

            _ = try await PropertyCreationService.shared.createProperty(
                address: address,
                householdId: householdId,
                propertyType: "Primary Residence"
            )

            // Refresh AppState so MainTabView appears.
            await appState.refreshPrimaryProperty()
            NotificationCenter.default.post(name: .propertyChanged, object: nil)
            Haptics.success()
        } catch {
            errorMessage = "Setup failed: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}

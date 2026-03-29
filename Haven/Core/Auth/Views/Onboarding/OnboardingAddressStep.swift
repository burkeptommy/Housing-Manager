import SwiftUI

/// Step 1 of onboarding: Enter your home address.
/// Uses the existing AddressAutocompleteField with Google Places.
struct OnboardingAddressStep: View {
    @Binding var street: String
    @Binding var unit: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing24) {
                VStack(spacing: HavenTheme.spacing8) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.navy)
                    Text("Where's your home?")
                        .font(HavenTypography.title2)
                    Text("We'll build a personalized maintenance plan for your home in seconds.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

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
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding(.horizontal, HavenTheme.pageMargin)
        }
    }
}

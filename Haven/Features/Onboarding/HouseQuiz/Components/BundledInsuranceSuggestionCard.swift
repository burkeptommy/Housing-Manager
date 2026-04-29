import SwiftUI

/// Phase 16c — pre-fill prompt rendered above the auto/home insurance picker
/// when the user already picked a bundled carrier on the partner question.
/// Three actions: accept (auto-answers the current question), reject (collapses
/// the card and reveals the regular search picker), or "not sure" (treated as
/// reject — same effect, friendlier label).
///
/// This card sits ABOVE the existing UtilityProviderSearchPicker. If the user
/// rejects, the picker takes over as if the suggestion never appeared.
struct BundledInsuranceSuggestionCard: View {
    let provider: UtilityProviderRow
    /// "home insurance" or "auto insurance" — substituted into the prompt copy
    /// without leaking the underlying provider_type token.
    let partnerLineLabel: String
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: HavenTheme.spacing12) {
                logoView
                VStack(alignment: .leading, spacing: 2) {
                    Text("LOOKS LIKE A BUNDLE")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.2)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("Is \(provider.name) your \(partnerLineLabel) too?")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            Text("Most homeowners bundle home and auto with the same carrier for the discount. Tap Yes to skip this question.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: HavenTheme.spacing12) {
                HavenButton(
                    title: "Yes, that's it",
                    action: {
                        Haptics.success()
                        onAccept()
                    }
                )
                HavenButton(
                    title: "No, different carrier",
                    action: {
                        Haptics.light()
                        onReject()
                    },
                    style: .secondary
                )
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.navy.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var logoView: some View {
        if let urlString = provider.logoUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(6)
                default:
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 22))
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
            .frame(width: 56, height: 56)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        } else {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 22))
                .foregroundStyle(HavenColors.textPrimary)
                .frame(width: 56, height: 56)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
    }
}

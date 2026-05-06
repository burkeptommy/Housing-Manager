import SwiftUI

/// Phase 95 (audit gap #9) — re-book button for the homeowner who
/// previously cancelled their Chez handyman onboarding visit (or who
/// originally chose the DIY path and has now changed their mind).
///
/// Tom's feedback during the audit was that re-booking after a cancel
/// required re-running onboarding, which is awkward. This card lives
/// on the dashboard right under the quiz hero so it's the natural
/// next step if the homeowner decides "actually, can someone handle
/// this for me?"
///
/// Gated visibility (decided by the parent):
///   • homeAssessment is nil (no active visit pending)
///   • the household has at least one property (otherwise the
///     getting-started flow is the right path, not this card)
///   • Chez covers the homeowner's area
struct ReBookChezHandymanCard: View {
    let onRequest: () -> Void

    var body: some View {
        Button {
            Haptics.medium()
            onRequest()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(HavenColors.action)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Want Chez to handle setup instead?")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text("Free 90-minute visit. We walk every system, photograph equipment, and capture your existing vendors so the rest of the app fills itself in.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing16)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(HavenColors.action.opacity(0.35), lineWidth: 1)
            )
            .havenShadow()
        }
        .buttonStyle(.plain)
    }
}

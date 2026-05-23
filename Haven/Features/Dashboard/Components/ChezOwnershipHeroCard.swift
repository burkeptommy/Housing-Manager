import SwiftUI

/// Phase 84 — Dashboard at-a-glance entry to "what Chez is running for me."
/// Tapping opens `ChezOwnershipView` where the homeowner adjusts delegation
/// level (DIY → Blend → Full) and browses delegated entities.
///
/// Dashboard noise audit — Round 2 (May 2026): rebuilt to the
/// `ChezActivityCard` visual signature (subtle purple linear-gradient
/// wash + purple stroke + purple icon in tinted circle + `title3`
/// headline + `bodySmall` subtitle) so this card reads as a sibling
/// to the other Chez-branded surfaces on the dashboard instead of a
/// generic cream/beige row. Round 1 collapsed the original card to a
/// one-line row and removed the salmon "Hand off everything" button;
/// Round 2 corrects the typography weight, sizing, and brand
/// signature Tom called out.
///
/// Three headline states (unchanged from Round 1):
///   • DIY (no group toggles on, no items delegated):
///     "Chez can run your house"
///   • Blend (some delegation):
///     "Chez handles N categor(y|ies) for you"
///   • Full (every group on):
///     "Chez is running your home"
struct ChezOwnershipHeroCard: View {
    let activeGroupCount: Int
    let delegatedItemCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            onTap()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(HavenColors.action.opacity(0.16))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(headline)
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge, style: .continuous)
                    .stroke(HavenColors.action.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, HavenTheme.spacing20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(headline). \(subtitle).")
    }

    /// Matches `ChezActivityCard.cardBackground` exactly so the two cards
    /// read as a visual family on the dashboard.
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: HavenTheme.radiusLarge, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        HavenColors.action.opacity(0.08),
                        HavenColors.action.opacity(0.02),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var headline: String {
        if activeGroupCount == 0 && delegatedItemCount == 0 {
            return "Chez can run your house"
        }
        if activeGroupCount >= 8 {
            return "Chez is running your home"
        }
        if activeGroupCount > 0 {
            return "Chez handles \(activeGroupCount) categor\(activeGroupCount == 1 ? "y" : "ies") for you"
        }
        return "Chez handles \(delegatedItemCount) thing\(delegatedItemCount == 1 ? "" : "s") for you"
    }

    private var subtitle: String {
        if activeGroupCount == 0 && delegatedItemCount == 0 {
            return "Free Home Manager service"
        }
        if activeGroupCount >= 8 {
            return "Tap to review what's covered"
        }
        return "Tap to adjust what's covered"
    }
}

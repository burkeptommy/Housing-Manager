import SwiftUI

/// Phase 84 — Dashboard hero card showing how much of the home Chez is
/// currently managing. Tapping opens `ChezOwnershipView` where the
/// homeowner can adjust delegation level (DIY → Blend → Full) or browse
/// what Chez is handling for them today.
///
/// Three rendering states:
///   • DIY (no group toggles on, no individual entities delegated):
///     "You're running your house yourself. Tap any item to hand it off."
///   • Blend (some delegation): "Chez handles X · You handle the rest."
///   • Full (every group toggle on): "Chez is running your home."
struct ChezOwnershipHeroCard: View {
    let activeGroupCount: Int
    let delegatedItemCount: Int
    let onTap: () -> Void
    /// Phase 95 audit fix — direct shortcut into Full Mode when the user
    /// has zero delegation today. Renders alongside the existing tap-
    /// the-card affordance; lets a homeowner one-tap "have Chez run my
    /// entire home" without first having to read the explainer.
    var onHandOffEverything: (() -> Void)? = nil

    private var isFreshDIY: Bool {
        activeGroupCount == 0 && delegatedItemCount == 0
    }

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(HavenColors.action.opacity(0.14))
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(HavenColors.action)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(headline)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                            .multilineTextAlignment(.leading)
                        Text(subtitle)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if isFreshDIY, let onHandOffEverything {
                Button {
                    Haptics.medium()
                    onHandOffEverything()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Hand off everything")
                            .font(HavenTypography.uiButton)
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(HavenColors.action)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.action.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(HavenColors.action.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal, HavenTheme.spacing20)
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
            return "Free Home Manager service. Hand off as much or as little as you want. Anytime."
        }
        if activeGroupCount >= 8 {
            return "Chez is managing your routines, systems, vendors, projects, bills, documents, insurance, and vehicles."
        }
        return "Tap to adjust what Chez handles or hand off more."
    }
}

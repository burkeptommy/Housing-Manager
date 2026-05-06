import SwiftUI

/// Phase 84.5 — Three-mode onboarding chooser. Inserted into the
/// `OnboardingView` flow after the auto-setup chain finishes (household,
/// family member, property, ATTOM-driven systems) but before the final
/// `authService.needsOnboarding = false` flip that drops the user on
/// the dashboard. Each mode routes the homeowner to a different next
/// step:
///
///   • **DIY**       → quiz auto-launches (existing behavior)
///   • **Blend**     → quiz auto-launches with a more aggressive
///                     post-quiz delegation sweep
///   • **Have Chez handle it** → skips the quiz, dispatches a free
///                     handyman home assessment, lands on the Pending
///                     Assessment dashboard card
///
/// The chosen mode is stamped on `properties.attributes['assessment_mode']`
/// so subsequent surfaces (Dashboard, post-quiz delegation sheet) can
/// branch on it.
struct OnboardingModeChooserStep: View {
    /// Currently-chosen mode (sticky preview while the user reads the
    /// sub-text — final commit happens on the Continue button).
    @Binding var selection: AssessmentMode?

    /// Continue handler — fired when the user taps Continue with a
    /// non-nil selection.
    let onContinue: (AssessmentMode) -> Void

    /// True while the network call to apply the choice is in flight
    /// (e.g. `request_home_assessment` for the handyman branch).
    let isApplying: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(spacing: 12) {
                    modeCard(.diy,
                             emoji: "🛠️",
                             title: "Manage it yourself",
                             tagline: "DIY",
                             body: "You take the wheel. We'll set up your maintenance schedule based on a quick 5-minute quiz. You stay in charge of every system, vendor, and project.")
                    modeCard(.blended,
                             emoji: "🤝",
                             title: "Blend",
                             tagline: "Mix & match",
                             body: "Take care of what you know. Let Chez handle the rest. After your quick quiz, we'll suggest categories worth handing off (vendors, scheduling, bill audits).")
                    modeCard(.handyman,
                             emoji: "✨",
                             title: "Have Chez handle it",
                             tagline: "Free handyman setup",
                             body: "Skip the quiz. A Chez handyman comes to your home. Free. And captures your systems, vendors, routines, and documents. You wake up to a fully-set-up home.")
                }

                continueButton

                Text("You can change this anytime in Settings.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, HavenTheme.padding)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(HavenColors.action)
                .padding(.top, 24)
            Text("How do you want to use Chez?")
                .font(HavenTypography.title2)
                .multilineTextAlignment(.center)
            Text("Pick the experience that matches how hands-on you want to be. You can switch anytime.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private func modeCard(
        _ mode: AssessmentMode,
        emoji: String,
        title: String,
        tagline: String,
        body: String
    ) -> some View {
        let isSelected = selection == mode
        return Button {
            withAnimation(HavenTheme.animationStandard) {
                selection = mode
            }
            Haptics.selection()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Text(emoji)
                    .font(.system(size: 30))
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? HavenColors.action.opacity(0.12) : HavenColors.creamLight)
                    )
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(tagline)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(isSelected ? HavenColors.action : HavenColors.textTertiary)
                    }
                    Text(body)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? HavenColors.action : HavenColors.textTertiary)
                    .font(.system(size: 22))
                    .padding(.top, 4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .fill(HavenColors.creamLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(isSelected ? HavenColors.action : HavenColors.beige300, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var continueButton: some View {
        Button {
            guard let mode = selection else { return }
            onContinue(mode)
        } label: {
            HStack {
                if isApplying {
                    ProgressView()
                        .tint(HavenColors.textOnAction)
                        .padding(.trailing, 6)
                }
                Text(continueLabel)
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textOnAction)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                    .fill(selection == nil ? HavenColors.action.opacity(0.4) : HavenColors.action)
            )
        }
        .buttonStyle(.plain)
        .disabled(selection == nil || isApplying)
    }

    private var continueLabel: String {
        guard let mode = selection else { return "Pick one to continue" }
        switch mode {
        case .diy: return "Continue → take the quiz"
        case .blended: return "Continue → take the quiz"
        case .handyman: return "Continue → request my free assessment"
        }
    }
}

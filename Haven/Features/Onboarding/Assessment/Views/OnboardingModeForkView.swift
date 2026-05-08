import SwiftUI

/// Phase 84.5 — the binary fork after the foundational 7-question form.
///
/// "Continue the quiz yourself" → existing HouseQuizView resumes at the
/// first unanswered question (foundational answers are auto-skipped via
/// `firstUnresolvedIndex()`).
///
/// "Send a Chez handyman" → property gets `assessment_mode = 'handyman'`,
/// pending visit assignment created, Dashboard pending card shows up.
///
/// Coverage gating (G11): if no provider workspace serves this address,
/// the handyman card is replaced with a waitlist tile. The quiz card
/// remains available so the homeowner can still self-onboard.
struct OnboardingModeForkView: View {
    /// True when we have at least one provider_workspace serving the
    /// homeowner's location. ViewModel pre-checks before rendering so the
    /// card layout is stable.
    let coverageAvailable: Bool

    /// True in Dec / Jan / Feb so the seasonality hint (G41) renders.
    let inWinterMonths: Bool

    let onSelectQuiz: () -> Void
    let onSelectHandyman: () -> Void
    let onJoinWaitlist: () -> Void
    /// Phase 95 — optional escape hatch. When non-nil, a "Decide later"
    /// link renders below the footer copy; tapping drops the user on the
    /// Dashboard with a banner offering to finish setup later. Pass nil
    /// to keep the fork mandatory (e.g. when the address-to-zip matcher
    /// genuinely needs a path picked before it can render anything else).
    var onDecideLater: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                header

                quizCard

                if coverageAvailable {
                    handymanCard
                    if inWinterMonths {
                        seasonalityHint
                    }
                } else {
                    waitlistCard
                }

                footerCopy
            }
            .padding(.horizontal, HavenTheme.spacing20)
            .padding(.vertical, HavenTheme.spacing24)
        }
        .background(HavenColors.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How should we set up the rest?")
                .font(HavenTypography.title)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Same fully-set-up app either way. Pick the path that fits your time.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    private var quizCard: some View {
        Button(action: onSelectQuiz) {
            modeCard(
                icon: "🛠️",
                title: "I'll finish setting up myself",
                timeEstimate: "About 30 questions, ~10 min",
                description: "Walk through every system in your home. You'll have full control over every detail and stay self-managed afterward.",
                cta: "Continue the quiz",
                ctaIsPrimary: false
            )
        }
        .buttonStyle(.plain)
    }

    private var handymanCard: some View {
        Button(action: onSelectHandyman) {
            modeCard(
                icon: "✨",
                title: "Send a Chez Contractor to set up",
                timeEstimate: "Free 90-min visit · we handle everything",
                description: "A Chez Contractor comes to your home. They'll walk every system, photograph equipment, flag what needs work, and capture your existing vendors. Then Chez can start handling the recommended work.",
                cta: "Schedule a free visit",
                ctaIsPrimary: true
            )
        }
        .buttonStyle(.plain)
    }

    private var seasonalityHint: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "snowflake")
                .foregroundStyle(HavenColors.textSecondary)
            Text("Tip: a partial assessment now and a follow-up exterior visit in spring at no charge.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(.horizontal, 12)
    }

    private var waitlistCard: some View {
        Button(action: onJoinWaitlist) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text("📋")
                        .font(.system(size: 32))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chez Contractor isn't in your area yet")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Join the waitlist. We'll notify you when we expand.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                HStack {
                    Spacer()
                    Text("Add me to the waitlist →")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.action)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(HavenColors.border, lineWidth: 1)
            )
            .havenShadow()
        }
        .buttonStyle(.plain)
    }

    private var footerCopy: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You can always change your mind later in Settings. Both paths land at the same Chez app, with the same Tasks, Routines, Vendors, and Projects.")
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let onDecideLater {
                Button {
                    Haptics.light()
                    onDecideLater()
                } label: {
                    Text("Decide later. Let me explore the app first")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func modeCard(
        icon: String,
        title: String,
        timeEstimate: String,
        description: String,
        cta: String,
        ctaIsPrimary: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            HStack(alignment: .top, spacing: 12) {
                Text(icon)
                    .font(.system(size: 36))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(timeEstimate)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.action)
                }
            }
            Text(description)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.leading)
            HStack {
                Spacer()
                Text(cta)
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(ctaIsPrimary ? HavenColors.textOnAction : HavenColors.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .fill(ctaIsPrimary ? HavenColors.action : HavenColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .stroke(ctaIsPrimary ? .clear : HavenColors.action, lineWidth: 1)
                    )
            }
        }
        .padding(HavenTheme.spacing20)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.border, lineWidth: 1)
        )
        .havenShadow()
    }
}

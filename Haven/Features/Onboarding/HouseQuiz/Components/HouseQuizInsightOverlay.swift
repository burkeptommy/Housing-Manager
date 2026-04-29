import SwiftUI

/// Apr 7, 2026 (build 82): replaces the previous inline feedback card.
///
/// When the user picks an answer that has an associated insight, the entire
/// quiz screen dims and the insight floats in the center for ~4 seconds,
/// then auto-dismisses and advances to the next question. The user can also
/// tap anywhere on the overlay (or the explicit "Got it" button) to skip
/// the wait and advance immediately.
///
/// This avoids the previous UX where the inline card was rendered BELOW
/// the answer chips and required the user to scroll down + manually tap
/// "Continue" to read the insight and advance.
struct HouseQuizInsightOverlay: View {
    let feedback: AnswerFeedback
    let city: String?
    let state: String?
    /// Called when the overlay is dismissed (either by the auto-advance
    /// timer or the user tapping). The view model's `dismissFeedback()`
    /// hook lives behind this so the same advance path runs in both cases.
    let onDismiss: () -> Void

    /// Total auto-advance duration. Originally 4.0s, bumped to 6.0s on
    /// 2026-04-20 after Tom flagged the milestone copy felt too quick to
    /// read — full-screen overlays carry more text than inline pills
    /// (title + subhead + body paragraph + citation on some) and HNW
    /// users want to absorb the number, not watch it blink.
    private let autoDismissAfter: TimeInterval = 6.0

    @State private var hasAppeared = false
    @State private var didDismiss = false
    @State private var secondsRemaining: Int = 6

    var body: some View {
        ZStack {
            // Dimmed backdrop. Tap-anywhere advances early.
            Rectangle()
                .fill(Color.black.opacity(0.55))
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }

            VStack(spacing: HavenTheme.spacing16) {
                Spacer()

                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    // Sparkles + INSIGHT badge
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(feedback.badge.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(HavenColors.textPrimary)
                    }

                    // Bold one-line takeaway
                    Text(feedback.renderedTitle(city: city, state: state))
                        .font(HavenTypography.fraunces(size: 22, weight: 600))
                        .foregroundStyle(HavenColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    // Optional supporting line
                    if let subhead = feedback.renderedSubhead(city: city, state: state) {
                        Text(subhead)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }

                    // Source citation — Phase 60.2: optional now, some
                    // feedback entries legitimately have no cited study.
                    if let citation = feedback.citationName, !citation.isEmpty {
                        Text("Source: \(citation)")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    // Divider before the auto-advance row
                    Rectangle()
                        .fill(HavenColors.beige200)
                        .frame(height: 1)
                        .padding(.top, HavenTheme.spacing8)

                    // Auto-advance hint + Got it button
                    HStack(spacing: HavenTheme.spacing12) {
                        Text("Continuing in \(secondsRemaining)…")
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textTertiary)
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Text("Got it")
                                .font(HavenTypography.uiButton)
                                .foregroundStyle(HavenColors.creamLight)
                                .padding(.horizontal, HavenTheme.spacing16)
                                .padding(.vertical, HavenTheme.spacing8)
                                .background(HavenColors.navy800)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(HavenTheme.spacing20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                        .stroke(HavenColors.beige200, lineWidth: 1)
                )
                .havenShadow(HavenTheme.shadowElevated)
                .padding(.horizontal, HavenTheme.pageMargin)
                .scaleEffect(hasAppeared ? 1.0 : 0.92)
                .opacity(hasAppeared ? 1 : 0)

                Spacer()
            }
        }
        .transition(.opacity)
        .task {
            // Animate in
            withAnimation(HavenTheme.animationStandard) {
                hasAppeared = true
            }

            // Countdown ticker — updates the visible "Continuing in N…" text
            // and fires the dismiss when it reaches zero.
            for i in stride(from: Int(autoDismissAfter) - 1, through: 0, by: -1) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if didDismiss { return }
                secondsRemaining = i
            }
            // Final tick — advance.
            if !didDismiss {
                dismiss()
            }
        }
    }

    private func dismiss() {
        guard !didDismiss else { return }
        didDismiss = true
        Haptics.light()
        onDismiss()
    }
}

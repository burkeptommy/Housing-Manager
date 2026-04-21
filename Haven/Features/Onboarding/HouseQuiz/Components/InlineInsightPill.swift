import SwiftUI

/// Phase 60.4: Micro-feedback pill that replaces the full-screen
/// `HouseQuizInsightOverlay` for the 95% of quiz answers that don't
/// warrant a stop. Slides up, displays for 2.2s, fades. Never blocks
/// the quiz from advancing.
///
/// Full-screen `HouseQuizInsightOverlay` is reserved for the milestone
/// allowlist (see `HouseQuizView.isMilestoneFeedbackQuestion`). The
/// gold-standard reference is the forwarding-email milestone card (the
/// Q17 reveal after Q15b) — every other insight is a pill.
///
/// Reference pattern: Duolingo inline XP floats for routine answers,
/// Robinhood per-tap micro-feedback pulse.
struct InlineInsightPill: View {
    let feedback: AnswerFeedback
    let city: String?
    let state: String?
    let onDismiss: () -> Void

    /// Total visible time before auto-dismiss fires. Tuned for Haven's
    /// HNW audience — a typical insight runs 15-25 words (badge + title
    /// + subhead), which at a reading speed of 240 WPM needs ~4 seconds
    /// to absorb. Duolingo's 1.5s XP float works for "+5 XP" strings but
    /// reads as a blink for actual prose. Tom flagged this 2026-04-20:
    /// "feels like they are too quick."
    private let autoDismissAfter: TimeInterval = 4.0

    @State private var hasAppeared: Bool = false
    @State private var didDismiss: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                Text(feedback.badge.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.navy700)
            }
            Text(feedback.renderedTitle(city: city, state: state))
                .font(HavenTypography.bodySmall.weight(.semibold))
                .foregroundStyle(HavenColors.navy800)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            if let subhead = feedback.renderedSubhead(city: city, state: state) {
                Text(subhead)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, HavenTheme.spacing12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .fill(HavenColors.creamLight)
                .shadow(color: HavenColors.navy.opacity(0.1), radius: 10, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.navy.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, HavenTheme.pageMargin)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 14)
        .onTapGesture { dismiss() }
        .task {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                hasAppeared = true
            }
            Haptics.light()
            try? await Task.sleep(nanoseconds: UInt64(autoDismissAfter * 1_000_000_000))
            if !didDismiss {
                dismiss()
            }
        }
    }

    private func dismiss() {
        guard !didDismiss else { return }
        didDismiss = true
        withAnimation(.easeOut(duration: 0.25)) {
            hasAppeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

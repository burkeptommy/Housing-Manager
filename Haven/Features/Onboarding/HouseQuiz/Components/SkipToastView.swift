import SwiftUI

/// Phase 60.3: Small toast pill shown at the top of the next visible
/// question when the quiz auto-skips one or more questions. Makes the
/// jump feel like "Haven respected my time" rather than "the quiz
/// glitched." Auto-dismissed by the view after ~3 seconds.
///
/// Reference: Noom's "we're not wasting your time" skip acknowledgments.
struct SkipToastView: View {
    let payload: HouseQuizViewModel.SkipToastPayload

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HavenColors.navy700)
            Text(payload.message)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, HavenTheme.spacing12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(HavenColors.creamLight)
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(HavenColors.beige200, lineWidth: 0.5)
        )
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, HavenTheme.spacing12)
    }
}

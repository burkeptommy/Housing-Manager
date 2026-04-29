import SwiftUI

/// Inline insight card shown after a single-answer pick. The user reads the
/// localized takeaway, then taps "Continue" to advance.
struct HouseQuizAnswerFeedbackCard: View {
    let feedback: AnswerFeedback
    let city: String?
    let state: String?
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                Text(feedback.badge.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.textPrimary)
            }

            Text(feedback.renderedTitle(city: city, state: state))
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let subhead = feedback.renderedSubhead(city: city, state: state) {
                Text(subhead)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Phase 60.2: citation is optional now.
            if let citation = feedback.citationName, !citation.isEmpty {
                Text("Source: \(citation)")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            HavenButton(title: "Continue") {
                onContinue()
            }
            .padding(.top, HavenTheme.spacing8)
        }
        .padding(HavenTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

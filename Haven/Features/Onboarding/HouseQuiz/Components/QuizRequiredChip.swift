import SwiftUI

/// Build 83 (Apr 7, 2026): Inline "required" suffix appended to a quiz
/// section header to signal that the field below gates the Continue button.
/// Pairs with `QuizContinueButton`'s disabledReason hint so users always know
/// which fields they need to fill in before they can move on.
///
/// Polish pass: the original red-pill treatment read as an error state. The
/// muted navy `· required` suffix sits inline on the same baseline as the
/// section header so it feels like part of the label, not a warning sign.
/// Renders the leading separator (` · `) itself so callers don't have to
/// add their own spacing.
struct QuizRequiredChip: View {
    var body: some View {
        Text(" · required")
            .font(HavenTypography.uiSectionHeader)
            .foregroundStyle(HavenColors.navy700)
            .accessibilityLabel("Required field")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 0) {
            Text("WHAT FUEL DOES IT RUN ON?")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
            QuizRequiredChip()
        }
        HStack(spacing: 0) {
            Text("PROPANE PROVIDER")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
            QuizRequiredChip()
        }
    }
    .padding()
    .background(HavenColors.background)
}

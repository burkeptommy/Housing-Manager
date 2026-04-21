import SwiftUI

/// One-time educational disclaimer shown before first Scenario Studio use.
struct ScenarioDisclaimerView: View {
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()

            Image(systemName: "info.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.navy)

            VStack(spacing: HavenTheme.spacing12) {
                Text("Before You Begin")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)

                Text("The Scenario Studio uses AI to simulate financial, estate, and home-related scenarios based on the data you've provided.\n\nThese analyses are **for educational and informational purposes only** and do not constitute legal, financial, or tax advice.\n\nAlways consult qualified professionals (an estate attorney, financial advisor, or CPA) before making decisions based on these results.")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.spacing16)
            }

            Spacer()

            HavenButton(title: "I Understand", action: onAcknowledge)
                .padding(.horizontal, HavenTheme.pageMargin)
        }
        .padding(.vertical, HavenTheme.spacing24)
        .background(HavenColors.background)
        .interactiveDismissDisabled(true)
        .presentationDetents([.medium])
        .trackScreen("ScenarioDisclaimerView")
    }
}

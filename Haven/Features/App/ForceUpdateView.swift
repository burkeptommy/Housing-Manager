import SwiftUI
import UIKit

/// Blocking full-screen view shown when the running build is below
/// `app_config.minimum_required_version` (or build). The user cannot dismiss
/// this view. The only action is "Update Now", which opens the App Store.
struct ForceUpdateView: View {
    let message: String
    let appStoreURL: URL

    var body: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(HavenColors.creamLight)
                    .frame(width: 120, height: 120)
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 72, weight: .regular))
                    .foregroundStyle(HavenColors.textPrimary)
            }

            VStack(spacing: HavenTheme.spacing12) {
                Text("Please update Chez")
                    .font(HavenTypography.title)
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.pageMargin)
            }

            Spacer()

            VStack(spacing: HavenTheme.spacing12) {
                HavenButton(title: "Update Now") {
                    UIApplication.shared.open(appStoreURL)
                }

                Text("Current version: \(Bundle.main.versionDisplay)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.bottom, HavenTheme.spacing24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HavenColors.background.ignoresSafeArea())
        .trackScreen("ForceUpdateView")
    }
}

#Preview {
    ForceUpdateView(
        message: "We made important updates to keep your household data safe and your experience smooth. Please update Chez to continue.",
        appStoreURL: URL(string: "https://apps.apple.com/app/id6757167606")!
    )
}

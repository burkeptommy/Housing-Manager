import SwiftUI
import UIKit

/// Non-blocking dashboard banner shown when `app_config.latest_version` is
/// ahead of the running build but the build is still at or above
/// `minimum_required_version`. The user can dismiss it for the rest of the
/// session by tapping "Later" — the dismissal does NOT persist across
/// launches, so the banner will reappear after a relaunch until the user
/// updates.
struct OptionalUpdateBanner: View {
    let latestVersion: String
    let message: String
    let appStoreURL: URL
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
            ZStack {
                Circle()
                    .fill(HavenColors.creamLight)
                    .frame(width: 36, height: 36)
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
                Text("Chez \(latestVersion) is available")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)

                Text(message)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: HavenTheme.spacing12) {
                    Button {
                        Haptics.medium()
                        UIApplication.shared.open(appStoreURL)
                    } label: {
                        Text("Update")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.textOnNavy)
                            .padding(.horizontal, HavenTheme.spacing16)
                            .padding(.vertical, HavenTheme.spacing8)
                            .background(HavenColors.navy800)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.light()
                        onDismiss()
                    } label: {
                        Text("Later")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.textPrimary)
                            .padding(.horizontal, HavenTheme.spacing16)
                            .padding(.vertical, HavenTheme.spacing8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, HavenTheme.spacing4)
            }

            Spacer(minLength: 0)
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.beige300, lineWidth: 1)
        }
        .havenShadow()
    }
}

#Preview {
    OptionalUpdateBanner(
        latestVersion: "1.0.4",
        message: "A new version of Chez is available. Update anytime to get the latest features.",
        appStoreURL: URL(string: "https://apps.apple.com/app/id6757167606")!,
        onDismiss: {}
    )
    .padding()
    .background(HavenColors.background)
}

import SwiftUI

/// Phase 61: Dashboard card that surfaces when Haven has archived any of the
/// user's tasks during a library-cleanup or template-retirement pass. Explains
/// the cleanup gently and routes the user to the Maintenance tab's `.legacy`
/// filter so they can see what changed. One-time, @AppStorage-gated dismissal.
///
/// The card only renders when `legacyCount > 0` AND the user hasn't dismissed
/// it yet. Count is derived from archived task rows in the household (surfaced
/// via `DashboardViewModel.legacyTaskCount`). Tapping the card posts a
/// `.switchToTab` to the Maintenance tab with filter state `.legacy`.
struct LegacyTasksNotificationCard: View {
    let legacyCount: Int
    var onViewDetails: (() -> Void)? = nil

    @AppStorage("hasSeenLegacyTasksCleanupP61") private var dismissed = false

    private var shouldShow: Bool {
        !dismissed && legacyCount > 0
    }

    var body: some View {
        if shouldShow {
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(HavenColors.navy800)
                        Text("WE TIDIED YOUR LIST")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Spacer()
                        Button {
                            dismissed = true
                            Haptics.light()
                            Analytics.track(.legacyTasksCleanupCardDismissed, ["legacy_count": legacyCount])
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .accessibilityLabel("Dismiss")
                    }

                    Text("\(legacyCount) low-value recurring task\(legacyCount == 1 ? "" : "s") \(legacyCount == 1 ? "has" : "have") been archived as Haven refined the task library. You can still see them from the Maintenance tab.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textPrimary)

                    HStack {
                        Spacer()
                        Button {
                            Haptics.light()
                            Analytics.track(.legacyTasksCleanupCardOpened, ["legacy_count": legacyCount])
                            onViewDetails?()
                            dismissed = true
                        } label: {
                            Text("View details")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.navy700)
                        }
                    }
                }
            }
            .onAppear {
                Analytics.track(.legacyTasksCleanupCardViewed, ["legacy_count": legacyCount])
            }
        }
    }
}

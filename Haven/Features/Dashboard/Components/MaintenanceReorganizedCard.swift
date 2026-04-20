import SwiftUI

/// Phase 66: One-time dashboard card for existing TestFlight users after
/// the maintenance tab restructure. Explains what changed and where to
/// find things. Dismissible; persisted via @AppStorage so it only ever
/// renders once per user.
///
/// Design: stays off the screen for users who haven't interacted with
/// the old Scheduled/To-Schedule buckets yet (e.g. fresh signups
/// landing on the new layout cold). A `shouldShow` predicate gates
/// rendering on (a) user has at least one existing routine or task AND
/// (b) the dismissal key is still false.
struct MaintenanceReorganizedCard: View {
    let onLearnMore: () -> Void
    let onDismiss: () -> Void

    @AppStorage("maintenanceReorganizedCardDismissed_v1")
    private var dismissed: Bool = false

    var body: some View {
        if dismissed {
            EmptyView()
        } else {
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title2)
                            .foregroundStyle(HavenColors.navy700)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("We reorganized your maintenance")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Your recurring work is now grouped by the service that handles it. Tap any card to see what's inside, or scroll down to \"This Season\" for the short list of decisions waiting.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    HStack {
                        Button {
                            Analytics.track(.maintenanceReorganizedCardViewed, ["action": "learn_more"])
                            onLearnMore()
                        } label: {
                            Text("Learn more")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy700)
                        }
                        Spacer()
                        Button {
                            Analytics.track(.maintenanceReorganizedCardDismissed, [:])
                            dismissed = true
                            onDismiss()
                        } label: {
                            Text("Got it")
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                .foregroundStyle(HavenColors.textOnNavy)
                                .padding(.horizontal, HavenTheme.spacing16)
                                .padding(.vertical, HavenTheme.spacing8)
                                .background(HavenColors.navy)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .onAppear {
                Analytics.track(.maintenanceReorganizedCardViewed, ["action": "viewed"])
            }
        }
    }
}

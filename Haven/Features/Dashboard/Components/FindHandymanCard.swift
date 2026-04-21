import SwiftUI

/// Phase 63: Dashboard "Getting Started" card for users whose Q15b answer
/// signaled "I need help finding a reliable handyman" (property attribute
/// `handyman_preference == "needs_help"`). Surfaces once the quiz is complete
/// AND the household still has no handyman contractor. Tap opens Alfred with
/// a pre-filled vetting prompt — we don't ship a vendor-matching engine yet
/// (Phase 67+ territory) so Alfred bridges the gap.
///
/// Dismissal is "soft" — persisted for 30 days, then re-surfaces if the user
/// still hasn't captured a handyman. Matches the EstateIntakeDripCard snooze
/// pattern from Phase 48.
struct FindHandymanCard: View {
    var onFindOptions: () -> Void

    @AppStorage("findHandymanCardSnoozedUntilP63") private var snoozedUntilInterval: Double = 0

    private var isSnoozed: Bool {
        let until = Date(timeIntervalSince1970: snoozedUntilInterval)
        return until > Date()
    }

    var body: some View {
        if !isSnoozed {
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(HavenColors.navy700)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Find a handyman")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("We'll help you vet options for the routine small-fixes work. No commitment.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }

                        Spacer()
                    }

                    HStack(spacing: HavenTheme.spacing8) {
                        Button {
                            // Snooze 30 days — card reappears after that if
                            // no handyman has been captured.
                            let until = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
                            snoozedUntilInterval = until.timeIntervalSince1970
                            Haptics.light()
                        } label: {
                            Text("Later")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .padding(.horizontal, HavenTheme.spacing12)
                                .padding(.vertical, HavenTheme.spacing8)
                        }

                        Spacer()

                        Button {
                            Haptics.medium()
                            onFindOptions()
                        } label: {
                            Text("Find options")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textOnNavy)
                                .padding(.horizontal, HavenTheme.spacing16)
                                .padding(.vertical, HavenTheme.spacing8)
                                .background(HavenColors.navy800)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
}

import SwiftUI

/// Phase 56.4: Proactive suggestion to schedule a handyman visit when
/// the user's punch list has accumulated enough items to be worth a
/// dedicated visit. Surfaces on the dashboard and the top of the
/// Maintenance tab when conditions are met — punch list ≥ 3, no
/// Handyman task scheduled in the next 30 days, no Handyman completion
/// in the last 90 days.
///
/// HNW voice: "Bundle them into a visit" — frames batched small work
/// as a coordination move, not a chore reminder.
struct HandymanSuggestionCard: View {
    let punchItemCount: Int
    let onSchedule: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HavenCard {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.beige200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text("You have \(punchItemCount) things for your handyman")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Bundle them into a visit and we'll hand the whole list to your handyman.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: HavenTheme.spacing8) {
                        Button {
                            Haptics.medium()
                            onSchedule()
                        } label: {
                            HStack(spacing: 4) {
                                Text("Schedule visit")
                                    .font(HavenTypography.uiLabel.weight(.semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(HavenColors.textOnNavy)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(HavenColors.navy)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            Haptics.light()
                            onDismiss()
                        } label: {
                            Text("Not now")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

import SwiftUI

/// Phase 56.5: Non-destructive banner shown on the Maintenance tab
/// when duplicate routines/tasks are detected. Never auto-merges —
/// always routes to `DuplicateResolutionSheet` for user review.
///
/// Reference: Apple Contacts' "Duplicates Found · Review" card. Sits
/// at the top of the list, one-tap review, never forces merge.
/// Session-dismissible; resurfaces next launch if duplicates remain.
///
/// Visual treatment mirrors `HandymanSuggestionCard` — same HavenCard
/// chrome, same CTA + dismiss button pattern — differentiated by the
/// warning-tinted icon well and the "two squares" iconography.
struct DuplicateReviewBanner: View {
    let duplicateCount: Int
    let onReview: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HavenCard {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: "square.on.square.dashed")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.warning)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.warning.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(headline)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Two entries appear to cover the same service. Tap to review. Nothing changes until you decide.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: HavenTheme.spacing8) {
                        Button {
                            Haptics.medium()
                            onReview()
                        } label: {
                            HStack(spacing: 4) {
                                Text("Review")
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

    private var headline: String {
        duplicateCount == 1
            ? "We noticed a possible duplicate"
            : "We noticed \(duplicateCount) possible duplicates"
    }
}

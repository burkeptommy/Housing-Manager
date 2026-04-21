import SwiftUI

/// Build 90: Compact "UP NEXT" section showing max 5 smart-filtered
/// items. Replaces both RECOMMENDED and NEEDS YOUR ATTENTION with a
/// focused, vendor-oriented list.
struct ThisWeekSection: View {
    let items: [ThisWeekItem]
    let totalTaskCount: Int
    let onItemTapped: (ThisWeekItem) -> Void
    let onSeeAll: () -> Void
    let onSnooze: (ThisWeekItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                // Phase 56.2: "YOUR TO-DOS" disambiguates this action
                // queue from the hero's "Next visit" vendor schedule —
                // one is what's on your plate, the other is what's
                // happening to your home.
                Text("YOUR TO-DOS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                Spacer()

                if totalTaskCount > items.count {
                    Button(action: onSeeAll) {
                        Text("See all (\(totalTaskCount))")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy)
                    }
                    .buttonStyle(.plain)
                }
            }

            if items.isEmpty {
                emptyState
            } else {
                HavenCard {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            Button {
                                Haptics.light()
                                onItemTapped(item)
                            } label: {
                                itemRow(item)
                            }
                            .buttonStyle(.plain)

                            if index < items.count - 1 {
                                Divider()
                                    .background(HavenColors.beige200)
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.green)

            Text("Nothing to schedule in the next 60 days.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)

            Spacer()
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
        }
    }

    private func itemRow(_ item: ThisWeekItem) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: item.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(item.urgencyColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if item.task != nil {
                Button {
                    onSnooze(item)
                } label: {
                    Image(systemName: "zzz")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.vertical, HavenTheme.spacing12)
    }
}

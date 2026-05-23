import SwiftUI

/// Dashboard action queue focused on what still needs the homeowner.
struct ThisWeekSection: View {
    let items: [ThisWeekItem]
    let totalTaskCount: Int
    let onItemTapped: (ThisWeekItem) -> Void
    let onSeeAll: () -> Void
    let onSnooze: (ThisWeekItem) -> Void

    var body: some View {
        // Dashboard noise audit (May 2026): hide the entire section
        // (header + card) when there's nothing to surface. Premium
        // convention — silence reads as "all good" without a
        // comfort card eating viewport.
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("NEEDS YOUR ATTENTION")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)

                    Spacer()

                    if totalTaskCount > items.count {
                        Button(action: onSeeAll) {
                            Text("See all (\(totalTaskCount))")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HavenCard {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            itemRow(item)

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

    private func itemRow(_ item: ThisWeekItem) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Button {
                Haptics.light()
                onItemTapped(item)
            } label: {
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
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

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

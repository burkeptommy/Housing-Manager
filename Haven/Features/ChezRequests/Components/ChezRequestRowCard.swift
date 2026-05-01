import SwiftUI

/// Phase 80 — Row in the Chez sub-tab list. Modeled on InboxItemCard:
/// category icon on the left, summary + caption in the middle, status
/// pill + relative timestamp on the right. Unread dot when the
/// homeowner has new content from Tom.
struct ChezRequestRowCard: View {
    let request: ChezRequestRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(HavenColors.action.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: request.typedCategory.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                }
                if request.unreadForUser {
                    Circle()
                        .fill(HavenColors.action)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle().stroke(HavenColors.surface, lineWidth: 2)
                        )
                        .offset(x: 4, y: -4)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(request.summary)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                Text(request.typedCategory.displayName)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                HStack(spacing: 8) {
                    ChezStatusBadge(status: request.typedStatus)
                    Text(request.homeownerSlaCaption)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(relativeTimestamp)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        )
    }

    private var relativeTimestamp: String {
        ChezRequestRow.relativeFormatter.localizedString(
            for: request.lastMessageAt,
            relativeTo: Date()
        )
    }
}

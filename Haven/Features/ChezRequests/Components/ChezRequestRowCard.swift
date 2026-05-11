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
                Text(displaySummary)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
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

    /// Wave C-5 #3 fix: auto-generated request titles often lead with
    /// "Find a vendor for: ..." or "Get a quote for: ..." — the category
    /// icon on the left already implies that action, so the prefix
    /// burns ~20 chars of the user's lineLimit(3) budget on signal
    /// they already see. Strip the known prefixes when present and
    /// title-case the surviving fragment so it reads as a real title,
    /// not a fragment. The raw `request.summary` is unchanged in the
    /// database — this is render-time only.
    private var displaySummary: String {
        let raw = request.summary
        let knownPrefixes = [
            "Find a vendor for: ",
            "Find a vendor for ",
            "Get a quote for: ",
            "Get a quote for ",
            "Schedule a visit for: ",
            "Schedule a visit for ",
            "Coordinate task: ",
            "Coordinate this task: ",
        ]
        for prefix in knownPrefixes {
            if raw.lowercased().hasPrefix(prefix.lowercased()) {
                let stripped = String(raw.dropFirst(prefix.count))
                // Capitalize first letter of the stripped fragment so it
                // reads as a sentence opener ("Sanitize pet areas...")
                // not a mid-sentence fragment.
                guard let first = stripped.first else { return raw }
                return String(first).uppercased() + stripped.dropFirst()
            }
        }
        return raw
    }
}

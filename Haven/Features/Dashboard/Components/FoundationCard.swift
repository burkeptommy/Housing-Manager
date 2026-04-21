import SwiftUI

/// Build 90: Compact contextual estate card that replaces both the
/// estate drip card and the estate scorecard. Shows only when there's
/// something actionable (intake not started, partial, stale docs).
/// Hidden when estate is healthy.
struct FoundationCard: View {
    let message: String
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.navy)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("FOUNDATION")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.2)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(message)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .strokeBorder(HavenColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

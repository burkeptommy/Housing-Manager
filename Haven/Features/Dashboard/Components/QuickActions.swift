import SwiftUI

struct QuickActions: View {
    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            quickActionButton(
                "Upload\nDocument",
                icon: "doc.badge.plus",
                color: .havenAccent
            )
            quickActionButton(
                "Add\nProperty",
                icon: "house.badge.plus",
                color: .havenSuccess
            )
            quickActionButton(
                "Ask\nHaven AI",
                icon: "sparkles",
                color: .havenWarning
            )
        }
    }

    private func quickActionButton(_ title: String, icon: String, color: Color) -> some View {
        Button {
            Haptics.light()
        } label: {
            VStack(spacing: HavenTheme.spacing8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: HavenTheme.minTouchTarget, height: HavenTheme.minTouchTarget)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))

                Text(title)
                    .font(HavenTypography.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, HavenTheme.spacing12)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title.replacingOccurrences(of: "\n", with: " "))
    }
}

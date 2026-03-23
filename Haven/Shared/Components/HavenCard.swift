import SwiftUI

/// Elevated card container with consistent padding, corner radius, border, and shadow.
/// Light: white background with beige200 border. Dark: darkElevated with darkBorder.
struct HavenCard<Content: View>: View {
    var padding: CGFloat = HavenTheme.spacing16
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.border, lineWidth: 1)
        }
        .havenShadow()
    }
}

#Preview {
    VStack(spacing: 16) {
        HavenCard {
            Text("Standard Card")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("With consistent theming and shadow")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
        }
        HavenCard(padding: HavenTheme.spacing12) {
            Text("Compact Card")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }
    .padding()
    .background(HavenColors.background)
}

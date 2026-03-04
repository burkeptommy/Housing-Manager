import SwiftUI

/// Elevated card container with consistent padding, corner radius, and shadow.
/// Used as the standard container for all list items, detail sections, and dashboard cards.
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
        .havenShadow()
    }
}

#Preview {
    VStack(spacing: 16) {
        HavenCard {
            Text("Standard Card")
                .font(HavenTypography.headline)
            Text("With consistent theming and shadow")
                .font(HavenTypography.callout)
                .foregroundStyle(.secondary)
        }
        HavenCard(padding: HavenTheme.spacing12) {
            Text("Compact Card")
                .font(HavenTypography.subheadline)
        }
    }
    .padding()
    .background(HavenColors.background)
}

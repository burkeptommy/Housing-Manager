import SwiftUI

struct PropertyCard: View {
    let property: PropertyRow

    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            // Property image placeholder: beige200 bg with building.2 in beige400
            Image(systemName: "building.2")
                .font(.title2)
                .foregroundStyle(HavenColors.beige400)
                .frame(width: HavenTheme.minTouchTarget, height: HavenTheme.minTouchTarget)
                .background(HavenColors.beige200)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
                Text(property.name)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                if let street = property.street {
                    Text(street)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
        .padding(.vertical, HavenTheme.spacing4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(property.name), \(property.propertyType)")
    }
}

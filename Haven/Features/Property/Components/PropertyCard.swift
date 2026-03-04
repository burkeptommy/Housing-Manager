import SwiftUI

struct PropertyCard: View {
    let property: PropertyRow

    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "house.fill")
                .font(.title2)
                .foregroundStyle(Color.havenAccent)
                .frame(width: HavenTheme.minTouchTarget, height: HavenTheme.minTouchTarget)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
                Text(property.name)
                    .font(HavenTypography.headline)
                if let street = property.street {
                    Text(street)
                        .font(HavenTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, HavenTheme.spacing4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(property.name), \(property.propertyType)")
    }
}

import SwiftUI

struct WarrantyExpirationAlert: View {
    let warranty: WarrantyRow

    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(Color.havenWarning)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(warranty.provider)
                    .font(HavenTypography.subheadline)
                    .fontWeight(.bold)
                Text("Expires \(warranty.endDate)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(HavenTheme.spacing16)
        .background(Color.havenWarning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(warranty.provider) warranty expires \(warranty.endDate)")
    }
}

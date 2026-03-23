import SwiftUI

struct WarrantyExpirationAlert: View {
    let warranty: WarrantyRow

    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(HavenColors.warning)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(warranty.provider)
                    .font(HavenTypography.bodySmall)
                    .fontWeight(.bold)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Expires \(warranty.endDate)")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(warranty.provider) warranty expires \(warranty.endDate)")
    }
}

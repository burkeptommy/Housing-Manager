import SwiftUI

struct SystemStatusIndicator: View {
    let status: String?

    private var statusColor: Color {
        switch (status ?? "good").lowercased() {
        case "good": return HavenColors.success
        case "needs maintenance": return HavenColors.warning
        case "needs repair", "needs replacement": return HavenColors.critical
        case "under warranty": return HavenColors.info
        case "out of service": return HavenColors.textTertiary
        default: return HavenColors.success
        }
    }

    private var statusLabel: String {
        (status ?? "Good").capitalized
    }

    var body: some View {
        HStack(spacing: HavenTheme.spacing4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusLabel)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(statusColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("System status: \(statusLabel)")
    }
}

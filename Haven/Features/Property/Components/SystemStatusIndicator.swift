import SwiftUI

struct SystemStatusIndicator: View {
    let status: String?

    private var statusColor: Color {
        switch (status ?? "good").lowercased() {
        case "good": return Color.havenSuccess
        case "needs maintenance": return Color.havenWarning
        case "needs repair", "needs replacement": return Color.havenCritical
        case "under warranty": return Color.havenInfo
        case "out of service": return .gray
        default: return Color.havenSuccess
        }
    }

    private var statusLabel: String {
        (status ?? "Good").capitalized
    }

    var body: some View {
        HStack(spacing: HavenTheme.spacing4) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            Text(statusLabel)
                .font(HavenTypography.caption)
                .foregroundStyle(statusColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("System status: \(statusLabel)")
    }
}

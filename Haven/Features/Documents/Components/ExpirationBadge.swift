import SwiftUI

struct ExpirationBadge: View {
    let date: Date

    private var daysUntilExpiration: Int {
        Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
    }

    private var color: Color {
        if daysUntilExpiration < 0 { return Color.havenCritical }
        if daysUntilExpiration < 30 { return Color.havenWarning }
        return Color.havenSuccess
    }

    private var label: String {
        if daysUntilExpiration < 0 { return "Expired" }
        if daysUntilExpiration == 0 { return "Today" }
        if daysUntilExpiration == 1 { return "1 day" }
        return "\(daysUntilExpiration)d"
    }

    var body: some View {
        Text(label)
            .font(HavenTypography.badgeLabel)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel(daysUntilExpiration < 0 ? "Expired" : "Expires in \(daysUntilExpiration) days")
    }
}

#Preview {
    VStack(spacing: 8) {
        ExpirationBadge(date: .now.addingTimeInterval(-86400))
        ExpirationBadge(date: .now.addingTimeInterval(86400 * 15))
        ExpirationBadge(date: .now.addingTimeInterval(86400 * 60))
    }
}

import SwiftUI

struct UpcomingExpirations: View {
    let items: [ExpirationItem]

    var body: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.havenWarning)
                    Text("Upcoming Expirations")
                        .font(HavenTypography.headline)
                    Spacer()
                    Text("\(items.count)")
                        .font(HavenTypography.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.havenWarning.opacity(0.12))
                        .foregroundStyle(Color.havenWarning)
                        .clipShape(Capsule())
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Upcoming expirations, \(items.count) items")

                ForEach(items.prefix(5)) { item in
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: item.icon)
                            .foregroundStyle(item.urgencyColor)
                            .frame(width: 24)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(HavenTypography.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text(item.type.capitalized)
                                .font(HavenTypography.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(urgencyLabel(item.daysRemaining))
                            .font(HavenTypography.badgeLabel)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(item.urgencyColor.opacity(0.12))
                            .foregroundStyle(item.urgencyColor)
                            .clipShape(Capsule())
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.title), \(item.type), \(urgencyLabel(item.daysRemaining))")
                }

                if items.count > 5 {
                    Text("+\(items.count - 5) more")
                        .font(HavenTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func urgencyLabel(_ days: Int) -> String {
        if days < 0 { return "Overdue" }
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "\(days) days"
    }
}

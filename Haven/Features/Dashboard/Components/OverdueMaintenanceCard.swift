import SwiftUI

struct OverdueMaintenanceCard: View {
    let tasks: [MaintenanceTaskDBRow]

    var body: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundStyle(Color.havenCritical)
                    Text("Overdue Maintenance")
                        .font(HavenTypography.headline)
                    Spacer()
                    Text("\(tasks.count)")
                        .font(HavenTypography.badgeLabel)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.havenCritical.opacity(0.12))
                        .foregroundStyle(Color.havenCritical)
                        .clipShape(Capsule())
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Overdue maintenance, \(tasks.count) items")

                ForEach(tasks.prefix(5)) { task in
                    HStack(spacing: HavenTheme.spacing12) {
                        Circle()
                            .fill(Color.havenCritical)
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(HavenTypography.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text("Due: \(task.nextDueDate)")
                                .font(HavenTypography.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let priority = task.priority {
                            Text(priority.capitalized)
                                .font(HavenTypography.badgeLabel)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HavenColors.priorityColor(priority).opacity(0.12))
                                .foregroundStyle(HavenColors.priorityColor(priority))
                                .clipShape(Capsule())
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(task.title), due \(task.nextDueDate)")
                }
            }
        }
    }
}

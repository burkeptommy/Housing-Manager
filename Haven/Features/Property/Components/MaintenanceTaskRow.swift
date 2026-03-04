import SwiftUI

struct MaintenanceTaskRow: View {
    let task: MaintenanceTaskDBRow

    private var isOverdue: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: task.nextDueDate) else { return false }
        return date < .now
    }

    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "circle")
                .foregroundStyle(isOverdue ? Color.havenCritical : .secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(HavenTypography.subheadline)
                Text("Due: \(task.nextDueDate)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let priority = task.priority {
                Text(priority.capitalized)
                    .font(HavenTypography.badgeLabel)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(HavenColors.priorityColor(priority).opacity(0.12))
                    .foregroundStyle(HavenColors.priorityColor(priority))
                    .clipShape(Capsule())
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title), due \(task.nextDueDate)\(isOverdue ? ", overdue" : "")")
    }
}

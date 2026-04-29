import SwiftUI

struct MaintenanceTaskRow: View {
    let task: MaintenanceTaskDBRow
    var assignedUserName: String? = nil

    private var isOverdue: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: task.nextDueDate) else { return false }
        return date < .now
    }

    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "circle")
                .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.textSecondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
                HStack(spacing: 4) {
                    Text("Due: \(task.nextDueDate.havenDateShort)")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    if let name = assignedUserName {
                        Text("·")
                            .foregroundStyle(HavenColors.textTertiary)
                        Image(systemName: "person.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(name)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }
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
        .accessibilityLabel("\(task.title), due \(task.nextDueDate.havenDateShort)\(isOverdue ? ", overdue" : "")\(assignedUserName.map { ", assigned to \($0)" } ?? "")")
    }
}

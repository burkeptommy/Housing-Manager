import SwiftUI

struct OverdueMaintenanceCard: View {
    let tasks: [MaintenanceTaskDBRow]
    @State private var selectedTask: MaintenanceTaskDBRow?

    var body: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundStyle(HavenColors.critical)
                    Text("Overdue Maintenance")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Text("\(tasks.count)")
                        .font(HavenTypography.badgeLabel)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(HavenColors.critical.opacity(0.12))
                        .foregroundStyle(HavenColors.critical)
                        .clipShape(Capsule())
                }

                ForEach(tasks.prefix(5)) { task in
                    Button {
                        Haptics.light()
                        Analytics.track(.dashboardMaintenanceCardTapped, ["task_title": task.title, "task_id": task.id.uuidString])
                        selectedTask = task
                    } label: {
                        HStack(spacing: HavenTheme.spacing12) {
                            Circle()
                                .fill(HavenColors.critical)
                                .frame(width: 8, height: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(HavenTypography.bodySmall)
                                    .fontWeight(.medium)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Text("Due: \(task.nextDueDate.havenDateShort)")
                                    .font(HavenTypography.uiLabelMedium)
                                    .foregroundStyle(HavenColors.textSecondary)
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

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(task: task)
            }
            .presentationDetents([.medium, .large])
        }
    }
}

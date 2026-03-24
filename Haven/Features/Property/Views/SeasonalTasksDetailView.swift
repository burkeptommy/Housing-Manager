import SwiftUI

struct SeasonalTasksDetailView: View {
    let season: String
    let tasks: [MaintenanceTaskDBRow]
    let completedCount: Int
    let nextSeason: String
    let nextSeasonTasks: [MaintenanceTaskDBRow]
    let systemNameLookup: (UUID?) -> String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Progress header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(completedCount) of \(tasks.count) complete")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(progressColor)
                    }

                    ProgressView(value: progress)
                        .tint(progressColor)
                }
                .padding()
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                .havenShadow()

                // Current season tasks
                if !tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(season.uppercased())
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        ForEach(tasks) { task in
                            taskRow(task: task, isCompleted: task.lastCompletedDate != nil)
                        }
                    }
                }

                // Next season preview
                if !nextSeasonTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COMING UP: \(nextSeason.uppercased())")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        ForEach(nextSeasonTasks) { task in
                            taskRow(task: task, isCompleted: false)
                        }
                    }
                }
            }
            .padding()
        }
        .background(HavenColors.background)
        .navigationTitle("\(season) Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("SeasonalTasksDetailView", properties: ["season": season])
    }

    private var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }

    private var progressColor: Color {
        if progress >= 0.75 { return HavenColors.success }
        if progress >= 0.4 { return HavenColors.warning }
        return HavenColors.critical
    }

    private func taskRow(task: MaintenanceTaskDBRow, isCompleted: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundStyle(isCompleted ? HavenColors.success : HavenColors.textTertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(isCompleted ? HavenColors.textTertiary : HavenColors.textPrimary)
                    .strikethrough(isCompleted)

                HStack(spacing: 8) {
                    if let systemName = systemNameLookup(task.systemId) {
                        Text(systemName)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    Text(task.frequency)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            Spacer()

            if let costRange = task.costRange {
                Text(costRange)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

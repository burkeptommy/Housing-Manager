import SwiftUI

/// Phase 67C: Drill-down sheet for a single season, reached by tapping
/// a Year-at-a-Glance tile. Shows the full list of tasks + routines
/// that fall in that season so the user can see everything Haven is
/// tracking for that window.
struct SeasonTasksSheet: View {
    let season: YearAtAGlanceCard.Season
    let tasks: [MaintenanceTaskDBRow]
    let routines: [RoutineRow]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if !routines.isEmpty {
                Section("Routines active in \(season.displayLabel)") {
                    ForEach(routines) { routine in
                        routineRow(routine)
                    }
                }
            }

            if !tasks.isEmpty {
                Section("\(season.displayLabel) tasks (\(tasks.count))") {
                    ForEach(tasks) { task in
                        taskRow(task)
                    }
                }
            }

            if tasks.isEmpty && routines.isEmpty {
                ContentUnavailableView {
                    Label("Nothing in \(season.displayLabel.lowercased()) yet", systemImage: season.icon)
                } description: {
                    Text("Haven will surface \(season.displayLabel.lowercased()) work as it comes up. Anything that needs a vendor you haven't added yet will appear in Your Services when it does.")
                }
            }
        }
        // BUG-007 fix: sheet header now shows the season icon (leaf /
        // sun / tree / snowflake) + label so the sheet reads as a
        // continuation of the Year-at-a-Glance tile the user tapped.
        // Before, the header was just "Spring" text with no icon and
        // felt disconnected from the tile's visual language.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: season.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(season.iconColor)
                    Text(season.displayLabel)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func routineRow(_ routine: RoutineRow) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: routine.resolvedIcon)
                .font(.body)
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.label)
                    .font(HavenTypography.body)
                Text(routine.typedCadence?.displayLabel ?? "Recurring")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func taskRow(_ task: MaintenanceTaskDBRow) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(task.title)
                .font(HavenTypography.body)
            Text("Due \(task.nextDueDate)")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }
}

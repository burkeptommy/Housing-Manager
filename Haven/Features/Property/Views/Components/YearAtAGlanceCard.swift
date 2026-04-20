import SwiftUI

/// Phase 67C: Year-at-a-Glance card at the top of MaintenanceHubView.
/// Solves the "This Season looks empty" symptom — even when Phase 66
/// correctly routed most tasks into routines + the handyman visit, the
/// user needs to SEE the full year's maintenance load to trust the app.
///
/// Shows four season tiles (Spring / Summer / Fall / Winter) with task
/// counts + top-3 previews. Tap a season to expand. Counts include:
///  - Unparented tasks with `seasonalTiming` in that season
///  - Tasks linked to routines (grouped under the routine's seasonal
///    anchor from its `active_months`)
///  - Template-based tasks across all sources (no double-counting via
///    task id)
///
/// The card renders at the TOP of MaintenanceHubView so it's the first
/// thing a user sees after the "See full year ↗" header link. Think of
/// this as the "trust the app covers the whole year" moment.
struct YearAtAGlanceCard: View {
    let seasons: [SeasonSummary]
    let onTapSeason: (Season) -> Void

    enum Season: String, CaseIterable, Identifiable {
        case spring
        case summer
        case fall
        case winter

        var id: String { rawValue }

        var displayLabel: String {
            switch self {
            case .spring: return "Spring"
            case .summer: return "Summer"
            case .fall:   return "Fall"
            case .winter: return "Winter"
            }
        }

        var icon: String {
            switch self {
            case .spring: return "leaf.fill"
            case .summer: return "sun.max.fill"
            case .fall:   return "tree.fill"
            case .winter: return "snowflake"
            }
        }

        var iconColor: Color {
            switch self {
            case .spring: return Color.green
            case .summer: return Color.orange
            case .fall:   return Color.brown
            case .winter: return Color.blue
            }
        }

        /// Months that belong to this season in Haven's convention —
        /// matches `MaintenanceTemplates` and `RoutineSeeder` seasonal
        /// anchor logic.
        var months: Set<Int> {
            switch self {
            case .spring: return [3, 4, 5]
            case .summer: return [6, 7, 8]
            case .fall:   return [9, 10, 11]
            case .winter: return [12, 1, 2]
            }
        }

        /// Which season the current date falls in. Drives the "current"
        /// highlight so users see where they are in the year.
        static var current: Season {
            let month = Calendar.current.component(.month, from: Date())
            return allCases.first { $0.months.contains(month) } ?? .spring
        }
    }

    struct SeasonSummary: Identifiable {
        let season: Season
        let count: Int
        let previewTitles: [String]

        var id: String { season.rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack {
                Text("YEAR AT A GLANCE")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Text("\(totalCount) across the year")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            HStack(spacing: HavenTheme.spacing8) {
                ForEach(seasons) { summary in
                    seasonTile(summary)
                }
            }
        }
    }

    private var totalCount: Int {
        seasons.reduce(0) { $0 + $1.count }
    }

    @ViewBuilder
    private func seasonTile(_ summary: SeasonSummary) -> some View {
        let isCurrent = summary.season == Season.current
        Button {
            onTapSeason(summary.season)
        } label: {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(spacing: 6) {
                    Image(systemName: summary.season.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(summary.season.iconColor)
                    Text(summary.season.displayLabel.uppercased())
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(isCurrent ? HavenColors.navy800 : HavenColors.textSecondary)
                    Spacer(minLength: 0)
                }
                Text("\(summary.count)")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
                    .contentTransition(.numericText(value: Double(summary.count)))

                if summary.previewTitles.isEmpty {
                    Text("Nothing planned")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(summary.previewTitles.prefix(2), id: \.self) { title in
                            Text(title)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(1)
                        }
                        if summary.previewTitles.count > 2 {
                            Text("+ \(summary.count - 2) more")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(HavenTheme.spacing12)
            .background(
                isCurrent
                ? HavenColors.action.opacity(0.06)
                : HavenColors.creamLight
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(
                        isCurrent ? HavenColors.action.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }
}

/// Phase 67C: Pure helper that rolls up tasks into a `YearAtAGlanceCard.SeasonSummary`
/// array ready to pass to the card. Centralized here so the view model
/// doesn't have to compute seasonal math in-place.
enum YearAtAGlanceAggregator {
    /// Aggregate every task + routine occurrence into four season buckets.
    /// Each task counts exactly once.
    static func summarize(
        tasks: [MaintenanceTaskDBRow],
        routines: [RoutineRow],
        routineTasks: [UUID: [MaintenanceTaskDBRow]]
    ) -> [YearAtAGlanceCard.SeasonSummary] {
        // Build one flat list of (season, title) pairs. Dedupe by task id.
        var seenTaskIds: Set<UUID> = []
        var seasonTitles: [YearAtAGlanceCard.Season: [String]] = [
            .spring: [], .summer: [], .fall: [], .winter: []
        ]

        // 1. Tasks linked to routines inherit the routine's season(s)
        for (routineId, linkedTasks) in routineTasks {
            guard let routine = routines.first(where: { $0.id == routineId }) else { continue }
            let seasons = seasonsFor(routine: routine)
            for task in linkedTasks {
                guard !seenTaskIds.contains(task.id) else { continue }
                seenTaskIds.insert(task.id)
                for season in seasons {
                    seasonTitles[season]?.append(task.title)
                }
            }
        }

        // 2. Unparented tasks fall back to their seasonalTiming or nextDueDate
        for task in tasks {
            guard !seenTaskIds.contains(task.id) else { continue }
            if task.isArchived == true { continue }
            seenTaskIds.insert(task.id)
            let season = seasonFor(task: task)
            seasonTitles[season]?.append(task.title)
        }

        return YearAtAGlanceCard.Season.allCases.map { season in
            let titles = seasonTitles[season] ?? []
            return YearAtAGlanceCard.SeasonSummary(
                season: season,
                count: titles.count,
                previewTitles: titles
            )
        }
    }

    /// A routine contributes to every season its `active_months` overlaps.
    /// A year-round routine (active_months = 1...12) shows up in all four.
    /// Seasonal routines (snow removal: Dec-Apr, lawn: Apr-Nov) only
    /// show up in the seasons they cover.
    private static func seasonsFor(routine: RoutineRow) -> Set<YearAtAGlanceCard.Season> {
        let activeMonths = Set(routine.activeMonths)
        var result: Set<YearAtAGlanceCard.Season> = []
        for season in YearAtAGlanceCard.Season.allCases {
            if !activeMonths.isDisjoint(with: season.months) {
                result.insert(season)
            }
        }
        return result.isEmpty ? [YearAtAGlanceCard.Season.current] : result
    }

    /// Fall through from `seasonalTiming` (template) → `nextDueDate`
    /// (ISO `yyyy-MM-dd`) → current season.
    private static func seasonFor(task: MaintenanceTaskDBRow) -> YearAtAGlanceCard.Season {
        if let timing = task.seasonalTiming?.lowercased() {
            if timing.contains("spring") { return .spring }
            if timing.contains("summer") { return .summer }
            if timing.contains("fall") { return .fall }
            if timing.contains("winter") { return .winter }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: task.nextDueDate) {
            let month = Calendar.current.component(.month, from: date)
            for season in YearAtAGlanceCard.Season.allCases where season.months.contains(month) {
                return season
            }
        }
        return .current
    }
}

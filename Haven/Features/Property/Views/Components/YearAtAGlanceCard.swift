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
        let actionCount: Int
        let coveredCount: Int
        let previewTitles: [String]

        var id: String { season.rawValue }

        var statusLine: String {
            if count == 0 {
                return "Not started"
            }
            if actionCount > 0 {
                return "\(actionCount) need action"
            }
            if coveredCount >= count {
                return "All covered"
            }
            return "\(coveredCount) covered"
        }

        var itemsLine: String {
            "\(count) item\(count == 1 ? "" : "s")"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack {
                Text("Year at a glance")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                if seasonsWithOpenWork > 0 {
                    Text("\(seasonsWithOpenWork) need review")
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.action)
                }
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

    private var seasonsWithOpenWork: Int {
        seasons.filter { $0.actionCount > 0 }.count
    }

    @ViewBuilder
    private func seasonTile(_ summary: SeasonSummary) -> some View {
        let isCurrent = summary.season == Season.current
        Button {
            onTapSeason(summary.season)
        } label: {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(alignment: .center) {
                    Image(systemName: summary.season.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(summary.season.iconColor)
                    Spacer(minLength: 6)
                    if isCurrent {
                        Text("Now")
                            .font(HavenTypography.uiCaption.weight(.semibold))
                            .foregroundStyle(HavenColors.action)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(HavenColors.action.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.season.displayLabel)
                        .font(HavenTypography.uiLabel.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    Text(summary.itemsLine)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Text(summary.statusLine)
                    .font(HavenTypography.bodySmall.weight(.semibold))
                    .foregroundStyle(summary.actionCount > 0 ? HavenColors.action : HavenColors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .fixedSize(horizontal: false, vertical: true)

                if !summary.previewTitles.isEmpty {
                    Text(summary.previewTitles.prefix(2).joined(separator: " · "))
                        .font(HavenTypography.caption2)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .leading)
            .padding(HavenTheme.spacing12)
            .background(
                isCurrent
                ? HavenColors.action.opacity(0.14)
                : HavenColors.creamLight
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(
                        isCurrent ? HavenColors.action.opacity(0.6) : HavenColors.beige200,
                        lineWidth: isCurrent ? 1.5 : 1
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

        // BUG-008 second-pass fix: every task (parented or not) lands in
        // exactly ONE bucket — the season of its `nextDueDate`. Previously
        // routine-parented tasks inherited EVERY season their routine was
        // active in (`seasonsFor(routine:)`), which bled snow-removal
        // tasks into Summer. Summer showed "Renew snow plowing contract
        // — Due 2026-10-01" because the parent routine was (incorrectly)
        // marked active year-round. Using the task's own due-date month
        // sidesteps any routine-level active_months data bugs and matches
        // the user's mental model: "what's happening this season?" = "what
        // will I actually do in these three months?"
        for task in tasks {
            guard !seenTaskIds.contains(task.id) else { continue }
            if task.isArchived == true { continue }
            seenTaskIds.insert(task.id)
            let season = seasonFor(task: task)
            seasonTitles[season]?.append(task.title)
        }

        // Also fold in routine-linked tasks that weren't in the main
        // `tasks` list (defensive — parented tasks normally also appear
        // in the flat list, but RoutineGroupingEngine edge cases can
        // leave them out).
        for (_, linkedTasks) in routineTasks {
            for task in linkedTasks {
                guard !seenTaskIds.contains(task.id) else { continue }
                if task.isArchived == true { continue }
                seenTaskIds.insert(task.id)
                let season = seasonFor(task: task)
                seasonTitles[season]?.append(task.title)
            }
        }

        // BUG-012 fix: sort titles alphabetically per season so preview
        // order is stable across re-renders. Dictionary iteration is
        // nondeterministic; without a deterministic sort the tile flickered
        // between "Renew s... / Termite i..." and "Termite i... / Sign up f..."
        // every time the view reloaded.
        return YearAtAGlanceCard.Season.allCases.map { season in
            let titles = (seasonTitles[season] ?? []).sorted()
            return YearAtAGlanceCard.SeasonSummary(
                season: season,
                count: titles.count,
                actionCount: 0,
                coveredCount: titles.count,
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

    /// BUG-008 fix: use `nextDueDate` month → season as the PRIMARY
    /// signal. The old logic preferred `seasonalTiming`, which caused
    /// tasks with `seasonal_timing = "spring"` but a July due date to
    /// land in Spring's bucket — confusing because the user asks "what's
    /// happening in spring?" and expects tasks actually due in spring,
    /// not tasks whose ideal timing is spring but were rescheduled.
    /// Falls back to `seasonalTiming` only when no due date parses, and
    /// to `.current` as a final catch.
    private static func seasonFor(task: MaintenanceTaskDBRow) -> YearAtAGlanceCard.Season {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: task.nextDueDate) {
            let month = Calendar.current.component(.month, from: date)
            for season in YearAtAGlanceCard.Season.allCases where season.months.contains(month) {
                return season
            }
        }
        if let timing = task.seasonalTiming?.lowercased() {
            if timing.contains("spring") { return .spring }
            if timing.contains("summer") { return .summer }
            if timing.contains("fall") { return .fall }
            if timing.contains("winter") { return .winter }
        }
        return .current
    }
}

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
        // BUG-001/002/003 fix: redesigned tile.
        // - Icon+label in vertical stack (label gets full tile width — no
        //   more "SPRIN G" wrap).
        // - Mixed case "Spring" not SHOUTING UPPERCASE — reads cleaner.
        // - Dropped the cryptic 12-char task previews ("Renew s...",
        //   "Termite i...") in favor of a "Today" badge on the current
        //   tile + an inviting "Tap to see" caption. The full task list
        //   lives inside SeasonTasksSheet where it has room to breathe.
        // - Current-season highlight bumped from opacity 0.06→0.14 +
        //   stroke 0.3→0.6 so the coral tint actually reads as "active"
        //   instead of a barely-there tint.
        let isCurrent = summary.season == Season.current
        Button {
            onTapSeason(summary.season)
        } label: {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Image(systemName: summary.season.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(summary.season.iconColor)
                    .frame(width: 24, height: 20, alignment: .leading)

                Text(summary.season.displayLabel)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(isCurrent ? HavenColors.navy800 : HavenColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(summary.count)")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
                    .contentTransition(.numericText(value: Double(summary.count)))

                // Short caption that fits in ~8 chars of the tile's
                // content width. Longer alternatives like "Tap to view"
                // or "You're here" still truncated after the BUG-001
                // label redesign. Keeping captions short is the
                // compromise for tile-width math on iPhone 17 Pro.
                if summary.count == 0 {
                    Text("Empty")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                } else if isCurrent {
                    Text("Now")
                        .font(HavenTypography.caption.weight(.semibold))
                        .foregroundStyle(HavenColors.action)
                        .lineLimit(1)
                } else {
                    Text("View")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

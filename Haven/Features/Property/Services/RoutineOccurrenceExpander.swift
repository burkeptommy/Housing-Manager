import Foundation

/// Phase 55: Virtual occurrence of a routine on a specific date.
/// Generated at render time from the routine's recurrence rule —
/// never persisted. Same pattern as Apple Calendar's repeating-event
/// expansion.
///
/// Replaces `CadenceOccurrence` from Phase 54E. The old file stays
/// alive in 55.2 because the legacy `HouseholdCadencesView` still
/// uses it; Section 55.3 deletes both the legacy view and the old
/// expander.
struct RoutineOccurrence: Identifiable {
    /// Stable id of the form `"routine_{routineId}_{yyyy-MM-dd}"` so
    /// SwiftUI's diffing keeps each row stable across re-renders.
    let id: String
    let routineId: UUID
    let date: Date
    let routine: RoutineRow
}

/// Pure stateless expander that materializes routine occurrences
/// within a date window. Honors `cadence_type`, `days_of_week`,
/// `active_months`, `start_date`, `next_expected_date`, and
/// `cadence_interval_days` without hitting the DB.
enum RoutineOccurrenceExpander {

    /// Expand routines into occurrences within [start, end].
    /// Paused and archived routines never emit occurrences.
    /// `active_months` filters the month of every candidate — a snow
    /// removal routine with `active_months == {12,1,2,3}` won't
    /// produce rows in July regardless of cadence.
    static func occurrences(
        routines: [RoutineRow],
        from start: Date,
        through end: Date,
        calendar: Calendar = .current
    ) -> [RoutineOccurrence] {
        guard end >= start, !routines.isEmpty else { return [] }

        let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.timeZone = calendar.timeZone
            return f
        }()

        var results: [RoutineOccurrence] = []

        for routine in routines where routine.archivedAt == nil && !routine.isPaused {
            let routineOccurrences = expandSingle(
                routine: routine,
                from: start,
                through: end,
                calendar: calendar,
                dateFormatter: dateFormatter
            )
            results.append(contentsOf: routineOccurrences)
        }

        return results.sorted { $0.date < $1.date }
    }

    /// The first upcoming occurrence for a routine at or after `start`.
    /// Used by pinned rows and hero cards that need a single "next
    /// expected" date without materializing the full occurrence list.
    /// Returns nil when the routine has no valid cadence config (e.g.
    /// weekly with empty `days_of_week`, or custom_days with no
    /// interval) — callers should fall back to a sensible default.
    static func nextOccurrence(
        routine: RoutineRow,
        from start: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        // 400 days covers annual cadences plus any seasonal gap (e.g.
        // a snow-removal routine asked in April for its next December
        // fire). Paused / archived routines short-circuit inside
        // `occurrences(...)`.
        let end = calendar.date(byAdding: .day, value: 400, to: start) ?? start
        return occurrences(
            routines: [routine],
            from: start,
            through: end,
            calendar: calendar
        ).first?.date
    }

    /// Expansion for a single routine. Dispatches by cadence_type.
    private static func expandSingle(
        routine: RoutineRow,
        from start: Date,
        through end: Date,
        calendar: Calendar,
        dateFormatter: DateFormatter
    ) -> [RoutineOccurrence] {
        guard let cadence = routine.typedCadence else { return [] }

        switch cadence {
        case .weekly:
            return weeklyOccurrences(routine: routine, from: start, through: end, calendar: calendar, dateFormatter: dateFormatter, weekInterval: 1)
        case .biweekly:
            return weeklyOccurrences(routine: routine, from: start, through: end, calendar: calendar, dateFormatter: dateFormatter, weekInterval: 2)
        case .triweekly:
            return weeklyOccurrences(routine: routine, from: start, through: end, calendar: calendar, dateFormatter: dateFormatter, weekInterval: 3)
        case .monthly:
            return intervalOccurrences(routine: routine, from: start, through: end, calendar: calendar, intervalDays: 30, dateFormatter: dateFormatter)
        case .bimonthly:
            return intervalOccurrences(routine: routine, from: start, through: end, calendar: calendar, intervalDays: 60, dateFormatter: dateFormatter)
        case .quarterly:
            return intervalOccurrences(routine: routine, from: start, through: end, calendar: calendar, intervalDays: 91, dateFormatter: dateFormatter)
        case .semiannual:
            return intervalOccurrences(routine: routine, from: start, through: end, calendar: calendar, intervalDays: 182, dateFormatter: dateFormatter)
        case .annual:
            return intervalOccurrences(routine: routine, from: start, through: end, calendar: calendar, intervalDays: 365, dateFormatter: dateFormatter)
        case .customDays:
            guard let interval = routine.cadenceIntervalDays, interval > 0 else { return [] }
            return intervalOccurrences(routine: routine, from: start, through: end, calendar: calendar, intervalDays: interval, dateFormatter: dateFormatter)
        }
    }

    /// Weekly / biweekly / triweekly: walk day-by-day, emit when (a) the
    /// weekday matches `days_of_week`, (b) the week index respects the
    /// week interval, and (c) the month falls in `active_months`.
    private static func weeklyOccurrences(
        routine: RoutineRow,
        from start: Date,
        through end: Date,
        calendar: Calendar,
        dateFormatter: DateFormatter,
        weekInterval: Int
    ) -> [RoutineOccurrence] {
        guard let daysOfWeek = routine.daysOfWeek, !daysOfWeek.isEmpty else { return [] }
        let anchor = dateFormatter.date(from: routine.startDate) ?? start
        let anchorDay = calendar.startOfDay(for: anchor)

        var results: [RoutineOccurrence] = []
        var cursor = calendar.startOfDay(for: start)
        let lastDay = calendar.startOfDay(for: end)

        while cursor <= lastDay {
            let weekday = calendar.component(.weekday, from: cursor)
            let month = calendar.component(.month, from: cursor)

            if daysOfWeek.contains(weekday), routine.isActiveInMonth(month), cursor >= anchorDay {
                if weekInterval == 1 {
                    append(&results, routine: routine, date: cursor, dateFormatter: dateFormatter)
                } else {
                    // Week-interval check: how many whole weeks since anchor?
                    let comps = calendar.dateComponents([.day], from: anchorDay, to: cursor)
                    let days = comps.day ?? 0
                    let weeks = days / 7
                    if weeks % weekInterval == 0 {
                        append(&results, routine: routine, date: cursor, dateFormatter: dateFormatter)
                    }
                }
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return results
    }

    /// Monthly+ cadences: walk forward by intervalDays from
    /// `next_expected_date`, emit occurrences that fall in [start, end]
    /// and `active_months`. Fast-forwards past the start when the
    /// anchor is deep in the past.
    private static func intervalOccurrences(
        routine: RoutineRow,
        from start: Date,
        through end: Date,
        calendar: Calendar,
        intervalDays: Int,
        dateFormatter: DateFormatter
    ) -> [RoutineOccurrence] {
        let nextAnchor = dateFormatter.date(from: routine.nextExpectedDate)
            ?? dateFormatter.date(from: routine.startDate)
            ?? start
        var cursor = calendar.startOfDay(for: nextAnchor)

        // Fast-forward when the anchor is in the past relative to start.
        while cursor < calendar.startOfDay(for: start) {
            guard let next = calendar.date(byAdding: .day, value: intervalDays, to: cursor) else { return [] }
            cursor = next
        }

        var results: [RoutineOccurrence] = []
        let lastDay = calendar.startOfDay(for: end)
        while cursor <= lastDay {
            let month = calendar.component(.month, from: cursor)
            if routine.isActiveInMonth(month) {
                append(&results, routine: routine, date: cursor, dateFormatter: dateFormatter)
            }
            guard let next = calendar.date(byAdding: .day, value: intervalDays, to: cursor) else { break }
            cursor = next
        }

        return results
    }

    private static func append(
        _ results: inout [RoutineOccurrence],
        routine: RoutineRow,
        date: Date,
        dateFormatter: DateFormatter
    ) {
        let dateString = dateFormatter.string(from: date)
        results.append(RoutineOccurrence(
            id: "routine_\(routine.id.uuidString)_\(dateString)",
            routineId: routine.id,
            date: date,
            routine: routine
        ))
    }
}

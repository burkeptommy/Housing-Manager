import Foundation

/// Phase 70.A1 follow-on F2 — single source of truth for Tasks v2 row
/// date captions. Renders "EEE, MMM d" for dates in the CURRENT calendar
/// year and "EEE, MMM d, yyyy" for any other year so the homeowner can
/// tell at a glance that a row dated "Feb 4" is actually NEXT February.
///
/// Phase 54A's `reseedSeasonalTasksOnceIfNeeded` pushes seasonal tasks
/// forward when the anchor passes — so by late spring, untouched
/// February / March anchors point to the NEXT year's spring. The sort
/// is correct (full `yyyy-MM-dd` strings compare as expected) but the
/// display had no way to communicate "2027 vs 2026" and read as
/// out-of-order to the user.
///
/// Used by:
/// - `MaintenanceTabView.standaloneDecisionMeta` + viewModel.dueLabel /
///   decisionMeta / nextEventLabel
/// - `BundleParentCard` due-date caption
/// - `StandaloneTaskRow` due-date caption
/// - `TasksV2RoutineOccurrenceRow` occurrence-date caption
/// - `QuickSchedulingSheet` preset preview rows (so the picker preview
///   matches the row caption the homeowner just read)
enum TasksV2DateFormatting {

    /// "EEE, MMM d" or "EEE, MMM d, yyyy". Used on row captions where
    /// the weekday adds scanability ("Sat, May 30" reads as a date
    /// faster than "May 30").
    static func longDay(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        formatter(includesWeekday: true, includesYear: needsYear(date, now: now, calendar: calendar))
            .string(from: date)
    }

    /// "MMM d" or "MMM d, yyyy". Used on compact section subheaders
    /// like dueLabel where the day-of-week would be visual noise.
    static func shortDay(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        formatter(includesWeekday: false, includesYear: needsYear(date, now: now, calendar: calendar))
            .string(from: date)
    }

    /// Reusable parse for the canonical `yyyy-MM-dd` strings stored on
    /// every task / routine row. Returns nil on empty or malformed.
    static func parseRowDate(_ string: String) -> Date? {
        guard !string.isEmpty else { return nil }
        return rowDateParser.date(from: string)
    }

    // MARK: - Internals

    private static func needsYear(_ date: Date, now: Date, calendar: Calendar) -> Bool {
        calendar.component(.year, from: date) != calendar.component(.year, from: now)
    }

    private static func formatter(includesWeekday: Bool, includesYear: Bool) -> DateFormatter {
        let f = DateFormatter()
        switch (includesWeekday, includesYear) {
        case (true, true):   f.dateFormat = "EEE, MMM d, yyyy"
        case (true, false):  f.dateFormat = "EEE, MMM d"
        case (false, true):  f.dateFormat = "MMM d, yyyy"
        case (false, false): f.dateFormat = "MMM d"
        }
        return f
    }

    private static let rowDateParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

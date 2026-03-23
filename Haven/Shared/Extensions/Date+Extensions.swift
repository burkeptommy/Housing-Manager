import Foundation

extension Date {
    var isExpired: Bool { self < .now }

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: .now, to: self).day ?? 0
    }

    var formatted_short: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    /// "March 15, 2026"
    var havenFull: String {
        self.formatted(.dateTime.month(.wide).day().year())
    }

    /// "Mar 15, 2026"
    var havenShort: String {
        self.formatted(.dateTime.month(.abbreviated).day().year())
    }

    /// "Mar 9, 2026 at 4:49 PM"
    var havenDateTime: String {
        self.formatted(.dateTime.month(.abbreviated).day().year().hour().minute())
    }
}

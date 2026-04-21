import Foundation

extension Date {
    /// Compact relative format for list rows.
    /// Past: "3d ago", "2w ago"
    /// Today/Tomorrow/Yesterday: "Today", "Tomorrow", "Yesterday"
    /// This week (future): day name ("Sat")
    /// This year: "May 11"
    /// Future years: "May '27"
    var havenCompact: String {
        let cal = Calendar.current
        let now = Date()

        if cal.isDateInToday(self) { return "Today" }
        if cal.isDateInTomorrow(self) { return "Tomorrow" }
        if cal.isDateInYesterday(self) { return "Yesterday" }

        let days = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: self)).day ?? 0

        // Past dates
        if days < 0 {
            let ago = abs(days)
            if ago < 7 { return "\(ago)d ago" }
            if ago < 30 { return "\(ago / 7)w ago" }
        }

        // Future dates within the week
        if days > 0 && days < 7 {
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE" // "Sat"
            return fmt.string(from: self)
        }

        let fmt = DateFormatter()
        if cal.component(.year, from: self) == cal.component(.year, from: now) {
            fmt.dateFormat = "MMM d" // "May 11"
        } else {
            fmt.dateFormat = "MMM ''yy" // "May '27"
        }
        return fmt.string(from: self)
    }
}

extension String {
    /// Convert "yyyy-MM-dd" to compact format for list rows.
    var havenDateCompact: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: self) else { return self }
        return date.havenCompact
    }
}

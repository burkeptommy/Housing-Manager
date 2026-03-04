import Foundation

extension Date {
    var isExpired: Bool { self < .now }

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: .now, to: self).day ?? 0
    }

    var formatted_short: String {
        formatted(date: .abbreviated, time: .omitted)
    }
}

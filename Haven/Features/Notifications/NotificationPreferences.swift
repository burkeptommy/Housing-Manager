import Foundation

struct NotificationPreferences: Codable {
    var isEnabled: Bool = true
    var documentExpirations: Bool = true
    var warrantyExpirations: Bool = true
    var maintenanceDue: Bool = true
    var overdueItems: Bool = true
    var morningDigest: Bool = false
    var insuranceRenewals: Bool = true
    /// Phase 95 (gap #30) — push reminders for upcoming visits with a
    /// confirmed `scheduled_date` (vendor or handyman). Defaults on.
    /// Separate from `maintenanceDue` because the cadence is different
    /// (T-7 / T-1 / day-of at 8am) and the reminder is for a confirmed
    /// appointment, not a generic due-date.
    var visitReminders: Bool = true

    private static let key = "notification_preferences"

    static func load() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: key),
              let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return NotificationPreferences()
        }
        return prefs
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: NotificationPreferences.key)
        }
    }
}

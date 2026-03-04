import Foundation

struct NotificationPreferences: Codable {
    var isEnabled: Bool = true
    var documentExpirations: Bool = true
    var warrantyExpirations: Bool = true
    var maintenanceDue: Bool = true
    var overdueItems: Bool = true
    var morningDigest: Bool = false
    var insuranceRenewals: Bool = true

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

import Foundation
import UserNotifications

final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()
    private let db = DatabaseService.shared

    private init() {}

    /// Reschedule all notifications based on current database state.
    func rescheduleAll() async {
        // Clear existing Haven notifications
        center.removeAllPendingNotificationRequests()

        let prefs = NotificationPreferences.load()
        guard prefs.isEnabled else { return }

        do {
            // Document expirations
            if prefs.documentExpirations {
                let docs = try await db.fetchDocuments()
                for doc in docs {
                    guard let expStr = doc.expirationDate else { continue }
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    guard let expDate = formatter.date(from: expStr) else { continue }
                    guard expDate > .now else { continue }

                    for daysBefore in [90, 60, 30, 7] {
                        guard let alertDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: expDate),
                              alertDate > .now else { continue }

                        scheduleNotification(
                            id: "doc-exp-\(doc.id)-\(daysBefore)",
                            title: "Document Expiring",
                            body: "\(doc.title) expires in \(daysBefore) days",
                            date: alertDate,
                            category: "document_expiration"
                        )
                    }
                }
            }

            // Warranty expirations
            if prefs.warrantyExpirations {
                let warranties = try await db.fetchWarranties()
                for warranty in warranties {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    guard let endDate = formatter.date(from: warranty.endDate),
                          endDate > .now else { continue }

                    for daysBefore in [90, 30, 7] {
                        guard let alertDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: endDate),
                              alertDate > .now else { continue }

                        scheduleNotification(
                            id: "warranty-exp-\(warranty.id)-\(daysBefore)",
                            title: "Warranty Expiring",
                            body: "\(warranty.provider) warranty expires in \(daysBefore) days",
                            date: alertDate,
                            category: "warranty_expiration"
                        )
                    }
                }
            }

            // Maintenance tasks — frequency-based reminder schedule
            if prefs.maintenanceDue {
                let tasks = try await db.fetchMaintenanceTasks()
                let properties = try await db.fetchProperties()
                let propNames = Dictionary(uniqueKeysWithValues: properties.map { ($0.id, $0.name) })

                for task in tasks {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    guard let dueDate = formatter.date(from: task.nextDueDate) else { continue }
                    let propertyName = task.propertyId.flatMap { propNames[$0] } ?? "Your Property"

                    if dueDate > .now {
                        // Schedule reminders based on frequency
                        let reminderDays = reminderDaysBefore(frequency: task.frequency)
                        for daysBefore in reminderDays {
                            guard let alertDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: dueDate),
                                  alertDate > .now else { continue }

                            let daysText = daysBefore == 0 ? "today" :
                                           daysBefore == 1 ? "tomorrow" : "in \(daysBefore) days"

                            scheduleNotification(
                                id: "maint-\(task.id)-\(daysBefore)",
                                title: "Maintenance Due — \(propertyName)",
                                body: "\(task.title) is due \(daysText).\(task.isDiy == true ? " This is a DIY task." : "")",
                                date: alertDate,
                                category: "maintenance_due"
                            )
                        }

                        // Day-of notification at 9am
                        var dayOfComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
                        dayOfComponents.hour = 9
                        dayOfComponents.minute = 0
                        scheduleNotification(
                            id: "maint-dayof-\(task.id)",
                            title: "Maintenance Due — \(propertyName)",
                            body: "\(task.title) is due today.",
                            dateComponents: dayOfComponents,
                            category: "maintenance_due"
                        )
                    }

                    // Overdue notification (if overdue, notify tomorrow at 9am)
                    if dueDate < .now {
                        var tomorrow = Calendar.current.dateComponents([.year, .month, .day], from: .now)
                        tomorrow.day! += 1
                        tomorrow.hour = 9
                        tomorrow.minute = 0

                        scheduleNotification(
                            id: "maint-overdue-\(task.id)",
                            title: "Overdue — \(propertyName)",
                            body: "\(task.title) is overdue. Mark complete or reschedule.",
                            dateComponents: tomorrow,
                            category: "maintenance_overdue"
                        )
                    }
                }
            }

            // Morning digest
            if prefs.morningDigest {
                scheduleMorningDigest()
            }

            // Seasonal reminders
            if prefs.maintenanceDue {
                scheduleSeasonalReminders()
            }

        } catch {
            // silently handle — notifications are best-effort
        }
    }

    /// Schedule notifications for a single newly-created maintenance task
    func scheduleForTask(_ task: MaintenanceTaskDBRow, propertyName: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let dueDate = formatter.date(from: task.nextDueDate), dueDate > .now else { return }

        let reminderDays = reminderDaysBefore(frequency: task.frequency)
        for daysBefore in reminderDays {
            guard let alertDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: dueDate),
                  alertDate > .now else { continue }

            let daysText = daysBefore == 0 ? "today" :
                           daysBefore == 1 ? "tomorrow" : "in \(daysBefore) days"

            scheduleNotification(
                id: "maint-\(task.id)-\(daysBefore)",
                title: "Maintenance Due — \(propertyName)",
                body: "\(task.title) is due \(daysText).",
                date: alertDate,
                category: "maintenance_due"
            )
        }
    }

    // MARK: - Reminder Schedule by Frequency

    private func reminderDaysBefore(frequency: String) -> [Int] {
        switch frequency.lowercased() {
        case "monthly":
            return [3]
        case "quarterly":
            return [7]
        case "semi-annually":
            return [14]
        case "annually":
            return [30, 7]
        case "every 2 years", "every 3 years", "every 5 years", "every 10 years":
            return [30, 7]
        case "seasonal":
            return [14, 7]
        default:
            return [7]
        }
    }

    // MARK: - Seasonal Reminders

    private func scheduleSeasonalReminders() {
        let cal = Calendar.current
        let year = cal.component(.year, from: .now)

        let seasons: [(name: String, month: Int, day: Int, message: String)] = [
            ("Spring", 3, 15, "Spring maintenance season is here! Time to prep your home."),
            ("Summer", 6, 15, "Summer maintenance check — keep your home running cool."),
            ("Fall", 9, 15, "Time to prepare for winter. Check your fall maintenance tasks."),
            ("Winter", 12, 15, "Winter maintenance check — protect your home from the cold."),
        ]

        for season in seasons {
            var components = DateComponents()
            components.year = year
            components.month = season.month
            components.day = season.day
            components.hour = 9
            components.minute = 0

            guard let date = cal.date(from: components), date > .now else {
                // Try next year
                components.year = year + 1
                guard let nextDate = cal.date(from: components), nextDate > .now else { continue }
                scheduleNotification(
                    id: "seasonal-\(season.name.lowercased())-\(year + 1)",
                    title: "\(season.name) Home Maintenance",
                    body: season.message,
                    dateComponents: components,
                    category: "seasonal_reminder"
                )
                continue
            }

            scheduleNotification(
                id: "seasonal-\(season.name.lowercased())-\(year)",
                title: "\(season.name) Home Maintenance",
                body: season.message,
                dateComponents: components,
                category: "seasonal_reminder"
            )
        }
    }

    // MARK: - Private

    private func scheduleNotification(id: String, title: String, body: String, date: Date, category: String) {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        scheduleNotification(id: id, title: title, body: body, dateComponents: components, category: category)
    }

    private func scheduleNotification(id: String, title: String, body: String, dateComponents: DateComponents, category: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private func scheduleMorningDigest() {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Chez Daily Summary"
        content.body = "Check what needs your attention today."
        content.sound = .default
        content.categoryIdentifier = "morning_digest"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morning-digest", content: content, trigger: trigger)
        center.add(request)
    }
}

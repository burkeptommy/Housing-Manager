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

            // Maintenance tasks
            if prefs.maintenanceDue {
                let tasks = try await db.fetchMaintenanceTasks()
                for task in tasks {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    guard let dueDate = formatter.date(from: task.nextDueDate) else { continue }

                    // Due date notification
                    if dueDate > .now {
                        scheduleNotification(
                            id: "maint-due-\(task.id)",
                            title: "Maintenance Due",
                            body: task.title,
                            date: dueDate,
                            category: "maintenance_due"
                        )

                        // 7-day warning
                        if let weekBefore = Calendar.current.date(byAdding: .day, value: -7, to: dueDate),
                           weekBefore > .now {
                            scheduleNotification(
                                id: "maint-warn-\(task.id)",
                                title: "Maintenance Due Soon",
                                body: "\(task.title) is due in 7 days",
                                date: weekBefore,
                                category: "maintenance_due"
                            )
                        }
                    }

                    // Overdue notification (if overdue, notify tomorrow at 9am)
                    if dueDate < .now {
                        var tomorrow = Calendar.current.dateComponents([.year, .month, .day], from: .now)
                        tomorrow.day! += 1
                        tomorrow.hour = 9
                        tomorrow.minute = 0

                        scheduleNotification(
                            id: "maint-overdue-\(task.id)",
                            title: "Overdue Maintenance",
                            body: "\(task.title) is overdue",
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

        } catch {
            // silently handle — notifications are best-effort
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
        content.title = "Haven Daily Summary"
        content.body = "Check what needs your attention today."
        content.sound = .default
        content.categoryIdentifier = "morning_digest"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morning-digest", content: content, trigger: trigger)
        center.add(request)
    }
}

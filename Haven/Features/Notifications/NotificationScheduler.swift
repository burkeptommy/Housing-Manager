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
                                title: "Maintenance Due. \(propertyName)",
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
                            title: "Maintenance Due. \(propertyName)",
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
                            title: "Overdue. \(propertyName)",
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

            // Phase 67E/F: handyman seasonal reminders (Mar 1 / Sep 1).
            // Lead time is intentionally a month before the dashboard's
            // HandymanSeasonalReminderCard window opens (Apr 1 / Oct 1
            // ±14d) so users have runway to book the visit before the
            // calendar lights up.
            if prefs.maintenanceDue {
                scheduleHandymanSeasonalReminders()
            }

            // Phase 95 (gap #30): visit reminders for confirmed
            // appointments. Distinct from generic maintenance-due
            // notifications because `scheduled_date` represents a
            // booked vendor / handyman visit, not a flexible due
            // window. Three pings per visit: T-7, T-1, day-of at 8am.
            if prefs.visitReminders {
                await scheduleVisitReminders()
            }

        } catch {
            // silently handle — notifications are best-effort
        }
    }

    /// Phase 95 (gap #30) — schedule push reminders for tasks with a
    /// `scheduled_date` set (i.e. a confirmed visit, not just a due
    /// window). Three reminders per visit:
    ///   • T-7 days at 9am — "Don't forget Tyler Heating next week"
    ///   • T-1 day at 6pm — "Reminder: Tyler Heating tomorrow"
    ///   • Day-of at 8am — "Tyler Heating arrives today"
    /// Idempotent — `rescheduleAll` clears all pending notifications
    /// before this runs, so the same visit is re-scheduled on every
    /// pass without piling up.
    private func scheduleVisitReminders() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let tasks: [MaintenanceTaskDBRow]
        do {
            tasks = try await db.fetchMaintenanceTasks(includeArchived: false)
        } catch {
            return
        }

        let contractors = (try? await db.fetchContractors()) ?? []
        let contractorById: [UUID: ContractorRow] = Dictionary(
            uniqueKeysWithValues: contractors.map { ($0.id, $0) }
        )

        for task in tasks {
            guard let scheduledDateStr = task.scheduledDate,
                  let scheduledDate = formatter.date(from: scheduledDateStr),
                  scheduledDate > .now else { continue }
            // Skip already-completed tasks even if scheduled_date is
            // still set — they shouldn't ping the user post-completion.
            if let completed = task.lastCompletedDate, !completed.isEmpty { continue }

            let vendorName = task.assignedContractorId
                .flatMap { contractorById[$0]?.companyName }
            let visitLabel: String = vendorName ?? task.title

            // T-7 at 9am
            if let oneWeek = Calendar.current.date(byAdding: .day, value: -7, to: scheduledDate),
               let alert = combineDate(oneWeek, hour: 9, minute: 0),
               alert > .now {
                scheduleNotification(
                    id: "visit-t7-\(task.id)",
                    title: "Visit next week",
                    body: "\(visitLabel) is scheduled for \(formatVisitDate(scheduledDate)).",
                    date: alert,
                    category: "visit_reminder"
                )
            }

            // T-1 at 6pm
            if let oneDay = Calendar.current.date(byAdding: .day, value: -1, to: scheduledDate),
               let alert = combineDate(oneDay, hour: 18, minute: 0),
               alert > .now {
                scheduleNotification(
                    id: "visit-t1-\(task.id)",
                    title: "Visit tomorrow",
                    body: "Reminder: \(visitLabel) tomorrow. Be ready to greet them.",
                    date: alert,
                    category: "visit_reminder"
                )
            }

            // Day-of at 8am
            if let alert = combineDate(scheduledDate, hour: 8, minute: 0),
               alert > .now {
                scheduleNotification(
                    id: "visit-dayof-\(task.id)",
                    title: "Visit today",
                    body: "\(visitLabel) is on the calendar for today.",
                    date: alert,
                    category: "visit_reminder"
                )
            }
        }
    }

    /// Helper to combine a calendar day with a specific hour/minute.
    private func combineDate(_ day: Date, hour: Int, minute: Int) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }

    /// Short visit-date label for notification body copy
    /// ("Tuesday, May 13").
    private func formatVisitDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
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
                title: "Maintenance Due. \(propertyName)",
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
            ("Summer", 6, 15, "Summer maintenance check. Keep your home running cool."),
            ("Fall", 9, 15, "Time to prepare for winter. Check your fall maintenance tasks."),
            ("Winter", 12, 15, "Winter maintenance check. Protect your home from the cold."),
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

    // MARK: - Handyman Seasonal Reminders (Phase 67E/F)

    /// Recurring Mar 1 / Sep 1 push reminders that lead the dashboard's
    /// HandymanSeasonalReminderCard by one month. Body steers users into
    /// the Handyman tab to review the punch list and book the next
    /// visit. Tap routes via the `handyman_seasonal_reminder` type case
    /// in `AppDelegate.userNotificationCenter(_:didReceive:)`.
    private func scheduleHandymanSeasonalReminders() {
        let cal = Calendar.current
        let year = cal.component(.year, from: .now)

        let anchors: [(season: String, month: Int, day: Int, headline: String)] = [
            ("spring", 3, 1, "Time to book your spring handyman visit"),
            ("fall", 9, 1, "Time to book your fall handyman visit"),
        ]

        for anchor in anchors {
            var components = DateComponents()
            components.month = anchor.month
            components.day = anchor.day
            components.hour = 9
            components.minute = 0

            // Pick the soonest future occurrence (this year if still
            // ahead, else next year). Once the date passes, iOS won't
            // refire the registered notification, so we re-register on
            // every `rescheduleAll` pass.
            components.year = year
            let thisYear = cal.date(from: components)
            let useDate: Date
            let useYear: Int
            if let d = thisYear, d > .now {
                useDate = d
                useYear = year
            } else {
                components.year = year + 1
                guard let d = cal.date(from: components) else { continue }
                useDate = d
                useYear = year + 1
            }

            scheduleHandymanReminder(
                id: "handyman-seasonal-\(anchor.season)-\(useYear)",
                title: anchor.headline,
                body: "Your punch list is ready. Tap to schedule the next visit.",
                fireDate: useDate,
                season: anchor.season
            )
        }
    }

    // MARK: - Phase 95 / gap #5+#6 — Booking confirmation reminder

    /// Local notification scheduled when a homeowner books their free
    /// Chez handyman onboarding visit. Two-fold purpose:
    ///   1. Persistent reminder of the upcoming visit (gap #6 — homeowner
    ///      no longer has to re-open the dashboard to verify their
    ///      request landed).
    ///   2. Confirmation surface (gap #5 — pairs with the SendGrid email
    ///      backstop fired server-side).
    ///
    /// If the user picked a preferred-window-start date, fire the reminder
    /// the morning before. Otherwise, fire 24 hours from now as a
    /// generic "Chez is on it" follow-up.
    static func scheduleHomeAssessmentBookingConfirmation(
        preferredWindowStart: String?,
        preferredTimeOfDay: String?
    ) {
        let center = UNUserNotificationCenter.current()
        let identifier = "chez-handyman-booking-confirmation"

        // Replace any existing pending reminder so re-booking after a
        // cancel doesn't fire two notifications.
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let cal = Calendar.current

        // Resolve the fire-date. Prefer "morning before windowStart at
        // 9 AM"; fall back to "tomorrow at 9 AM" if no window was picked.
        var fireDate: Date
        if let raw = preferredWindowStart {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            if let parsed = formatter.date(from: raw),
               let dayBefore = cal.date(byAdding: .day, value: -1, to: parsed),
               let morning = cal.date(bySettingHour: 9, minute: 0, second: 0, of: dayBefore),
               morning > .now {
                fireDate = morning
            } else if let tomorrow = cal.date(byAdding: .day, value: 1, to: .now),
                      let morning = cal.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) {
                fireDate = morning
            } else {
                fireDate = .now.addingTimeInterval(60 * 60 * 24)
            }
        } else if let tomorrow = cal.date(byAdding: .day, value: 1, to: .now),
                  let morning = cal.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) {
            fireDate = morning
        } else {
            fireDate = .now.addingTimeInterval(60 * 60 * 24)
        }

        let content = UNMutableNotificationContent()
        content.title = "Your Chez handyman visit is on the calendar"
        if let preferredTimeOfDay, !preferredTimeOfDay.isEmpty {
            content.body = "We'll confirm a \(preferredTimeOfDay) slot. Tap to see your booking status."
        } else {
            content.body = "We'll confirm a window with you shortly. Tap to see your booking status."
        }
        content.sound = .default
        content.categoryIdentifier = "chez_assessment_booking_confirmation"
        content.userInfo = [
            "type": "chez_assessment_booking_confirmation"
        ]

        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    private func scheduleHandymanReminder(id: String, title: String, body: String, fireDate: Date, season: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "handyman_seasonal_reminder"
        // userInfo `type` is matched in AppDelegate to route taps into
        // the Handyman tab.
        content.userInfo = [
            "type": "handyman_seasonal_reminder",
            "season": season,
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { _ in }
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

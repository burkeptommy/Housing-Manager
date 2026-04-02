import EventKit
import Foundation

/// Manages bi-directional sync between iOS calendars and Haven family events.
/// - Reads events from selected iOS calendars → inserts into family_events
/// - Deletes from Haven → removes from iOS calendar
/// - Tracks which calendars are synced via synced_calendars table
@MainActor
final class CalendarSyncService: ObservableObject {
    static let shared = CalendarSyncService()

    private let store = EKEventStore()
    private let db = DatabaseService.shared

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var availableCalendars: [EKCalendar] = []
    @Published var syncedCalendarIds: Set<String> = []
    @Published var isSyncing = false

    private init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToEvents()
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            if granted {
                loadAvailableCalendars()
            }
            return granted
        } catch {
            print("[CalendarSync] Access request failed: \(error)")
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return false
        }
    }

    // MARK: - Calendar Discovery

    func loadAvailableCalendars() {
        availableCalendars = store.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    /// Load which calendars the current user has synced from DB
    func loadSyncedCalendars() async {
        do {
            let rows = try await db.fetchSyncedCalendars()
            syncedCalendarIds = Set(rows.filter(\.isActive).map(\.calendarIdentifier))
        } catch {
            print("[CalendarSync] Failed to load synced calendars: \(error)")
        }
    }

    // MARK: - Calendar Selection & Sync

    /// Toggle a calendar for sync. If enabling, immediately imports its events.
    func toggleCalendar(_ calendar: EKCalendar, enabled: Bool) async throws {
        let user = try await db.fetchCurrentUser()
        guard let householdId = user.householdId else { return }

        if enabled {
            // Save to synced_calendars
            try await db.upsertSyncedCalendar(
                householdId: householdId,
                userId: user.id,
                calendarIdentifier: calendar.calendarIdentifier,
                calendarTitle: calendar.title,
                calendarColor: calendar.cgColor?.hexString,
                isActive: true
            )
            syncedCalendarIds.insert(calendar.calendarIdentifier)

            // Import events from this calendar
            await importEvents(from: calendar, householdId: householdId)
        } else {
            // Deactivate (don't delete — preserves history)
            try await db.deactivateSyncedCalendar(
                userId: user.id,
                calendarIdentifier: calendar.calendarIdentifier
            )
            syncedCalendarIds.remove(calendar.calendarIdentifier)

            // Remove synced events from Haven that came from this calendar
            try await db.deleteFamilyEvents(
                householdId: householdId,
                externalCalendarId: calendar.calendarIdentifier
            )
        }
    }

    /// Full sync of all active calendars
    func syncAll() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else { return }

            let syncedRows = try await db.fetchSyncedCalendars()
            let activeIds = Set(syncedRows.filter(\.isActive).map(\.calendarIdentifier))

            for calendar in store.calendars(for: .event) where activeIds.contains(calendar.calendarIdentifier) {
                await importEvents(from: calendar, householdId: householdId)
            }

            // Update last_synced_at for all active calendars
            for row in syncedRows where row.isActive {
                try? await db.updateSyncedCalendarLastSync(id: row.id)
            }
        } catch {
            print("[CalendarSync] Sync failed: \(error)")
        }
    }

    // MARK: - Event Import

    /// Import events from a single iOS calendar into family_events
    private func importEvents(from calendar: EKCalendar, householdId: UUID) async {
        // Look back 30 days, forward 365 days
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let end = Calendar.current.date(byAdding: .day, value: 365, to: Date())!

        let predicate = store.predicateForEvents(
            withStart: start,
            end: end,
            calendars: [calendar]
        )
        let ekEvents = store.events(matching: predicate)

        // Fetch existing synced event IDs to avoid duplicates
        let existingIds = try? await db.fetchFamilyEventExternalIds(
            householdId: householdId,
            calendarId: calendar.calendarIdentifier
        )
        let existingSet = Set(existingIds ?? [])

        var newEvents: [FamilyEventInsert] = []
        var seenEventIds: Set<String> = []

        for event in ekEvents {
            let eventId = event.eventIdentifier ?? UUID().uuidString
            guard !existingSet.contains(eventId), !seenEventIds.contains(eventId) else { continue }
            seenEventIds.insert(eventId)

            newEvents.append(FamilyEventInsert(
                householdId: householdId,
                title: event.title ?? "Untitled",
                startDate: event.startDate,
                endDate: event.endDate,
                allDay: event.isAllDay,
                location: event.location,
                notes: event.notes,
                source: "ios_calendar",
                externalCalendarId: calendar.calendarIdentifier,
                externalEventId: eventId,
                recurrenceRule: event.recurrenceRules?.first?.icalString
            ))
        }

        if !newEvents.isEmpty {
            do {
                try await db.insertFamilyEvents(newEvents)
                print("[CalendarSync] Imported \(newEvents.count) events from '\(calendar.title)'")
            } catch {
                print("[CalendarSync] Failed to import events: \(error)")
            }
        }
    }

    // MARK: - Bi-directional Delete

    /// Delete a family event from Haven AND from the iOS calendar if it was synced
    func deleteEvent(_ event: FamilyEventRow) async throws {
        // If this event came from iOS calendar, remove it there too
        if let externalEventId = event.externalEventId,
           let ekEvent = store.event(withIdentifier: externalEventId) {
            try store.remove(ekEvent, span: .thisEvent)
            print("[CalendarSync] Removed event from iOS calendar: \(event.title)")
        }

        // Delete from Haven DB
        try await db.deleteFamilyEvent(id: event.id)
    }

    /// Create a Haven event and optionally push to an iOS calendar
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date?,
        allDay: Bool = false,
        location: String? = nil,
        notes: String? = nil,
        pushToCalendar: EKCalendar? = nil
    ) async throws -> FamilyEventRow {
        let user = try await db.fetchCurrentUser()
        guard let householdId = user.householdId else {
            throw CalendarSyncError.noHousehold
        }

        var externalCalendarId: String?
        var externalEventId: String?

        // Push to iOS calendar if requested
        if let calendar = pushToCalendar {
            let ekEvent = EKEvent(eventStore: store)
            ekEvent.title = title
            ekEvent.startDate = startDate
            ekEvent.endDate = endDate ?? startDate.addingTimeInterval(3600)
            ekEvent.isAllDay = allDay
            ekEvent.location = location
            ekEvent.notes = notes
            ekEvent.calendar = calendar
            try store.save(ekEvent, span: .thisEvent)
            externalCalendarId = calendar.calendarIdentifier
            externalEventId = ekEvent.eventIdentifier
        }

        let insert = FamilyEventInsert(
            householdId: householdId,
            title: title,
            startDate: startDate,
            endDate: endDate,
            allDay: allDay,
            location: location,
            notes: notes,
            source: pushToCalendar != nil ? "ios_calendar" : "manual",
            externalCalendarId: externalCalendarId,
            externalEventId: externalEventId,
            recurrenceRule: nil
        )

        return try await db.insertFamilyEvent(insert)
    }

    enum CalendarSyncError: LocalizedError {
        case noHousehold
        case accessDenied

        var errorDescription: String? {
            switch self {
            case .noHousehold: return "No household found"
            case .accessDenied: return "Calendar access denied"
            }
        }
    }
}

// MARK: - EKRecurrenceRule → iCal string

private extension EKRecurrenceRule {
    var icalString: String? {
        // Simple RRULE generation for common patterns
        var parts: [String] = []
        switch frequency {
        case .daily: parts.append("FREQ=DAILY")
        case .weekly: parts.append("FREQ=WEEKLY")
        case .monthly: parts.append("FREQ=MONTHLY")
        case .yearly: parts.append("FREQ=YEARLY")
        @unknown default: return nil
        }
        if interval > 1 {
            parts.append("INTERVAL=\(interval)")
        }
        if let end = recurrenceEnd {
            if let date = end.endDate {
                let formatter = ISO8601DateFormatter()
                parts.append("UNTIL=\(formatter.string(from: date))")
            } else if end.occurrenceCount > 0 {
                parts.append("COUNT=\(end.occurrenceCount)")
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: ";")
    }
}

// MARK: - CGColor → hex

extension CGColor {
    var hexString: String? {
        guard let components = components, numberOfComponents >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

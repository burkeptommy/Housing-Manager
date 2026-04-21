import Foundation
import SwiftUI

/// Phase 51: Manages standing appointment lifecycle — confirm, skip, pause, resume, archive.
/// Shared between StandingAppointmentCardView buttons and swipe gestures on recurring-visit task cards.
@MainActor
final class StandingAppointmentViewModel: ObservableObject {
    static let shared = StandingAppointmentViewModel()

    @Published var appointments: [StandingAppointmentRow] = []
    @Published var isLoading = false

    private let db = DatabaseService.shared

    // MARK: - Fetch

    func loadAppointments(householdId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            appointments = try await db.fetchStandingAppointments(householdId: householdId)
        } catch {
            print("[StandingAppointmentVM] Failed to load appointments: \(error)")
        }
    }

    var activeAppointments: [StandingAppointmentRow] {
        appointments.filter { !$0.isPaused && $0.archivedAt == nil }
    }

    var pausedAppointments: [StandingAppointmentRow] {
        appointments.filter { $0.isPaused && $0.archivedAt == nil }
    }

    // MARK: - Confirm Visit

    /// Confirms a visit happened. Updates the visit status, sets last_confirmed_date,
    /// calculates next_expected_date, and creates the next upcoming visit row.
    func confirmVisit(appointmentId: UUID, visitId: UUID) async throws {
        let appointment = try await db.fetchStandingAppointment(id: appointmentId)
        let visit = try await db.updateVisit(id: visitId, StandingAppointmentVisitUpdate(
            status: "confirmed",
            confirmedAt: Date(),
            confirmedBy: "user"
        ))

        // Update the appointment's tracking dates.
        // Don't create a new visit here — maintainVisitWindow handles
        // all visit generation to avoid double-counting.
        let nextUpcoming = try? await db.fetchUpcomingVisit(appointmentId: appointmentId)
        let nextDate = nextUpcoming?.scheduledDate
            ?? calculateNextDate(from: visit.scheduledDate, appointment: appointment)

        _ = try await db.updateStandingAppointment(id: appointmentId, StandingAppointmentUpdate(
            nextExpectedDate: nextDate,
            lastConfirmedDate: visit.scheduledDate
        ))

        Haptics.success()
        postChangeNotification()
        await maintainVisitWindow(appointmentId: appointmentId)
        await refreshAppointment(id: appointmentId)
    }

    // MARK: - Skip Visit

    /// Skips the next visit. Advances to the following one based on the scheduled date
    /// (not the current date) to keep the cadence anchored.
    func skipVisit(appointmentId: UUID, visitId: UUID) async throws {
        _ = try await db.updateVisit(id: visitId, StandingAppointmentVisitUpdate(
            status: "skipped"
        ))

        // Update nextExpectedDate to the next remaining upcoming visit.
        // Don't create a new visit — maintainVisitWindow handles generation.
        let nextUpcoming = try? await db.fetchUpcomingVisit(appointmentId: appointmentId)
        if let nextDate = nextUpcoming?.scheduledDate {
            _ = try await db.updateStandingAppointment(id: appointmentId, StandingAppointmentUpdate(
                nextExpectedDate: nextDate
            ))
        }

        Haptics.medium()
        postChangeNotification()
        await maintainVisitWindow(appointmentId: appointmentId)
        await refreshAppointment(id: appointmentId)
    }

    // MARK: - Pause

    /// Pauses the appointment. Marks the current upcoming visit as skipped.
    func pauseAppointment(id: UUID, reason: String?, autoResumeDate: String?) async throws {
        _ = try await db.updateStandingAppointment(id: id, StandingAppointmentUpdate(
            isPaused: true,
            pausedAt: Date(),
            pauseReason: reason,
            autoResumeDate: autoResumeDate
        ))

        // Mark current upcoming visit as skipped
        if let upcoming = try await db.fetchUpcomingVisit(appointmentId: id) {
            _ = try await db.updateVisit(id: upcoming.id, StandingAppointmentVisitUpdate(
                status: "skipped",
                notes: "Paused: \(reason ?? "no reason")"
            ))
        }

        Haptics.medium()
        postChangeNotification()
        await refreshAppointment(id: id)
    }

    // MARK: - Resume

    /// Resumes a paused appointment. Creates a new upcoming visit starting from today
    /// or the auto-resume date, whichever is later.
    func resumeAppointment(id: UUID) async throws {
        let appointment = try await db.fetchStandingAppointment(id: id)
        let resumeDate: String
        if let autoResume = appointment.autoResumeDate, autoResume > todayString() {
            resumeDate = autoResume
        } else {
            resumeDate = todayString()
        }

        _ = try await db.updateStandingAppointment(id: id, StandingAppointmentUpdate(
            nextExpectedDate: resumeDate,
            isPaused: false,
            pausedAt: nil,
            pauseReason: nil,
            autoResumeDate: nil
        ))

        _ = try await db.createVisit(StandingAppointmentVisitInsert(
            standingAppointmentId: id,
            scheduledDate: resumeDate,
            status: "upcoming"
        ))

        Haptics.success()
        postChangeNotification()
        await refreshAppointment(id: id)
    }

    // MARK: - Archive (End Relationship)

    func archiveAppointment(id: UUID) async throws {
        _ = try await db.updateStandingAppointment(id: id, StandingAppointmentUpdate(
            archivedAt: Date()
        ))

        // Mark any upcoming visits as skipped
        if let upcoming = try await db.fetchUpcomingVisit(appointmentId: id) {
            _ = try await db.updateVisit(id: upcoming.id, StandingAppointmentVisitUpdate(
                status: "skipped",
                notes: "Relationship ended"
            ))
        }

        Haptics.medium()
        postChangeNotification()
        // Remove from local list
        appointments.removeAll { $0.id == id }
    }

    // MARK: - Create Standing Appointment

    /// The number of upcoming visit rows to maintain at all times.
    /// When visits are confirmed/skipped or roll forward, new visits
    /// are generated to keep this many in the pipeline.
    static let visitWindowSize = 4

    /// Creates a new standing appointment with a rolling window of upcoming visits.
    func createAppointment(
        householdId: UUID,
        propertyId: UUID?,
        vendorId: UUID?,
        systemId: UUID,
        cadenceType: String,
        cadenceIntervalDays: Int?,
        cadenceSource: String,
        confidenceScore: Double? = nil,
        serviceDescription: String? = nil,
        startDate: String? = nil,
        seasonalPauseMonths: [Int]? = nil
    ) async throws -> StandingAppointmentRow {
        let effectiveStartDate = startDate ?? todayString()
        let intervalDays = cadenceIntervalDays ?? intervalForCadenceType(cadenceType)
        let firstVisitDate = effectiveStartDate

        let appointment = try await db.createStandingAppointment(StandingAppointmentInsert(
            householdId: householdId,
            propertyId: propertyId,
            vendorId: vendorId,
            systemId: systemId,
            cadenceType: cadenceType,
            cadenceIntervalDays: cadenceType == "custom_days" ? cadenceIntervalDays : nil,
            startDate: effectiveStartDate,
            nextExpectedDate: firstVisitDate,
            cadenceSource: cadenceSource,
            confidenceScore: confidenceScore,
            serviceDescription: serviceDescription
        ))

        // Generate the rolling visit window (4 upcoming visits)
        var visitDate = firstVisitDate
        for _ in 0..<Self.visitWindowSize {
            // Skip dates that fall in seasonal pause months
            if let pauseMonths = seasonalPauseMonths {
                visitDate = skipPausedMonths(date: visitDate, pauseMonths: pauseMonths, interval: intervalDays)
            }

            _ = try await db.createVisit(StandingAppointmentVisitInsert(
                standingAppointmentId: appointment.id,
                scheduledDate: visitDate,
                status: "upcoming"
            ))
            visitDate = dateByAdding(days: intervalDays, to: visitDate)
        }

        postChangeNotification()
        return appointment
    }

    /// Ensures the rolling visit window has enough upcoming visits.
    /// Called after confirm/skip to refill the pipeline.
    func maintainVisitWindow(appointmentId: UUID) async {
        do {
            let visits = try await db.fetchVisits(appointmentId: appointmentId, limit: 20)
            let upcomingCount = visits.filter { $0.status == "upcoming" }.count

            guard upcomingCount < Self.visitWindowSize,
                  let appointment = try? await db.fetchStandingAppointment(id: appointmentId),
                  !appointment.isPaused,
                  appointment.archivedAt == nil
            else { return }

            // Find the latest scheduled date among all visits to continue from
            let latestDate = visits
                .map(\.scheduledDate)
                .sorted()
                .last ?? appointment.nextExpectedDate

            let intervalDays = appointment.effectiveIntervalDays
            var nextDate = dateByAdding(days: intervalDays, to: latestDate)
            let toGenerate = Self.visitWindowSize - upcomingCount

            for _ in 0..<toGenerate {
                _ = try await db.createVisit(StandingAppointmentVisitInsert(
                    standingAppointmentId: appointmentId,
                    scheduledDate: nextDate,
                    status: "upcoming"
                ))
                nextDate = dateByAdding(days: intervalDays, to: nextDate)
            }
        } catch {
            print("[StandingAppointment] Failed to maintain visit window: \(error)")
        }
    }

    // MARK: - Invoice Auto-Confirmation

    /// Checks if a processed invoice's service date matches a scheduled or assumed visit
    /// for the given vendor (within +/- 3 days). If so, auto-confirms it.
    func autoConfirmFromInvoice(vendorId: UUID, serviceDate: String) async {
        do {
            let appointments = try await db.fetchStandingAppointmentsForVendor(vendorId: vendorId)
            for appointment in appointments {
                let visits = try await db.fetchVisits(appointmentId: appointment.id, limit: 5)
                for visit in visits where visit.status == "upcoming" || visit.status == "assumed" {
                    if datesWithinRange(visit.scheduledDate, serviceDate, days: 3) {
                        _ = try await db.updateVisit(id: visit.id, StandingAppointmentVisitUpdate(
                            status: "confirmed",
                            confirmedAt: Date(),
                            confirmedBy: "invoice_auto"
                        ))
                        _ = try await db.updateStandingAppointment(id: appointment.id, StandingAppointmentUpdate(
                            lastConfirmedDate: visit.scheduledDate
                        ))
                        print("[StandingAppointmentVM] Invoice auto-confirmed visit \(visit.id) for vendor \(vendorId)")
                        postChangeNotification()
                        break
                    }
                }
            }
        } catch {
            print("[StandingAppointmentVM] Invoice auto-confirm failed: \(error)")
        }
    }

    // MARK: - Seasonal Suppression (Step 11)

    /// Returns the set of system IDs covered by active (non-paused, non-archived) standing appointments.
    /// Seasonal task views can use this to suppress redundant suggestions for categories already
    /// handled by a recurring vendor relationship.
    var coveredSystemIds: Set<UUID> {
        Set(activeAppointments.map(\.systemId))
    }

    /// Checks whether a given system is covered by an active standing appointment.
    func isSystemCovered(_ systemId: UUID) -> Bool {
        coveredSystemIds.contains(systemId)
    }

    // MARK: - Helpers

    private func calculateNextDate(from dateString: String, appointment: StandingAppointmentRow) -> String {
        dateByAdding(days: appointment.effectiveIntervalDays, to: dateString)
    }

    private func intervalForCadenceType(_ type: String) -> Int {
        switch type {
        case "weekly": return 7
        case "biweekly": return 14
        case "triweekly": return 21
        case "monthly": return 30
        case "bimonthly": return 60
        case "quarterly": return 91
        case "semiannual": return 182
        case "annual": return 365
        default: return 30
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func dateByAdding(days: Int, to dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        let newDate = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
        return formatter.string(from: newDate)
    }

    private func datesWithinRange(_ date1: String, _ date2: String, days: Int) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let d1 = formatter.date(from: date1),
              let d2 = formatter.date(from: date2) else { return false }
        let diff = abs(Calendar.current.dateComponents([.day], from: d1, to: d2).day ?? Int.max)
        return diff <= days
    }

    /// Advances a date past any months in the seasonal pause set.
    /// Used during visit generation to skip winter/off-season dates.
    private func skipPausedMonths(date: String, pauseMonths: [Int], interval: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard var d = formatter.date(from: date) else { return date }
        let cal = Calendar.current
        let pauseSet = Set(pauseMonths)

        // Advance day-by-day until we're in a non-paused month (max 365 safety)
        var attempts = 0
        while pauseSet.contains(cal.component(.month, from: d)) && attempts < 365 {
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
            attempts += 1
        }
        return formatter.string(from: d)
    }

    private func postChangeNotification() {
        NotificationCenter.default.post(name: .standingAppointmentChanged, object: nil)
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
    }

    private func refreshAppointment(id: UUID) async {
        guard let index = appointments.firstIndex(where: { $0.id == id }) else { return }
        do {
            appointments[index] = try await db.fetchStandingAppointment(id: id)
        } catch {
            print("[StandingAppointmentVM] Failed to refresh appointment \(id): \(error)")
        }
    }
}

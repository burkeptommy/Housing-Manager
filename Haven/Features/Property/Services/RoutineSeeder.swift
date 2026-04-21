import Foundation

/// Phase 58: Seeds routines in the `routines` table when a contractor
/// matching one of the seven archetypal recurring-service categories is
/// added to a household. Runs on contractor-add and as a one-time
/// backfill at app launch.
///
/// Philosophy: Haven is a vendor orchestration product. Weekly cleaners,
/// weekly landscapers, weekly pool service, quarterly pest, etc. are
/// standing rhythms — not tasks the user ticks off. The template library
/// (Phase 58) no longer generates these as maintenance tasks; the seeder
/// creates the corresponding Routine so the vendor's cadence appears on
/// the dashboard + maintenance surfaces without the user having to set
/// it up manually.
@MainActor
final class RoutineSeeder {
    static let shared = RoutineSeeder()

    private init() {}

    /// Category string → matching RoutineKind + defaults. Lowercased for
    /// case-insensitive matching against `ContractorRow.category`.
    private struct SeedDefaults {
        let kind: RoutineKind
        let label: String
        let cadenceType: RoutineCadenceType
        let daysOfWeek: [Int]?
        let timeOfDay: String?
        let activeMonths: [Int]
        let eveningBeforeReminder: Bool
        let morningOfReminder: Bool
        let cadenceIntervalDays: Int?
    }

    private func defaults(for category: String) -> SeedDefaults? {
        let lower = category.lowercased()

        // Cleaning / housekeeping — biweekly year-round, morning reminder.
        if lower.contains("clean") || lower.contains("housekeep") || lower.contains("maid") {
            return SeedDefaults(
                kind: .cleaning,
                label: "cleaning service",
                cadenceType: .biweekly,
                daysOfWeek: [4], // Wednesday
                timeOfDay: "09:00",
                activeMonths: Array(1...12),
                eveningBeforeReminder: false,
                morningOfReminder: true,
                cadenceIntervalDays: nil
            )
        }

        // Landscaping — weekly Apr-Nov.
        if lower.contains("landscap") || lower.contains("lawn") || lower.contains("mow") {
            return SeedDefaults(
                kind: .landscaping,
                label: "landscaping service",
                cadenceType: .weekly,
                daysOfWeek: [4], // Wednesday
                timeOfDay: "08:00",
                activeMonths: Array(4...11),
                eveningBeforeReminder: false,
                morningOfReminder: false,
                cadenceIntervalDays: nil
            )
        }

        // Pool service — weekly May-Sep.
        if lower.contains("pool") {
            return SeedDefaults(
                kind: .poolService,
                label: "pool service",
                cadenceType: .weekly,
                daysOfWeek: [3], // Tuesday
                timeOfDay: "10:00",
                activeMonths: Array(5...9),
                eveningBeforeReminder: false,
                morningOfReminder: false,
                cadenceIntervalDays: nil
            )
        }

        // Pest control — quarterly year-round.
        if lower.contains("pest") || lower.contains("exterminat") {
            return SeedDefaults(
                kind: .pestControl,
                label: "pest control service",
                cadenceType: .customDays,
                daysOfWeek: nil,
                timeOfDay: nil,
                activeMonths: Array(1...12),
                eveningBeforeReminder: false,
                morningOfReminder: false,
                cadenceIntervalDays: 90
            )
        }

        // Pet waste — weekly year-round, morning reminder.
        if lower.contains("pet waste") || lower.contains("poop") || lower.contains("dog waste") {
            return SeedDefaults(
                kind: .petWaste,
                label: "pet waste pickup",
                cadenceType: .weekly,
                daysOfWeek: [4], // Wednesday
                timeOfDay: "08:00",
                activeMonths: Array(1...12),
                eveningBeforeReminder: false,
                morningOfReminder: true,
                cadenceIntervalDays: nil
            )
        }

        // Mosquito & Tick — triweekly Apr-Oct.
        if lower.contains("mosquito") || lower.contains("tick") {
            return SeedDefaults(
                kind: .mosquitoTick,
                label: "mosquito and tick spraying",
                cadenceType: .triweekly,
                daysOfWeek: [3], // Tuesday
                timeOfDay: nil,
                activeMonths: Array(4...10),
                eveningBeforeReminder: false,
                morningOfReminder: false,
                cadenceIntervalDays: nil
            )
        }

        // Phase 60.2 (F5): Snow Removal — on-call contract during Dec-Apr.
        // Not a weekly visit (storms dictate frequency), so there's no
        // daysOfWeek — the routine is mostly a reminder that a vendor is
        // on contract for the season. `customDays` cadenceIntervalDays of
        // 90 creates a quarterly check-in; the actual plow happens per
        // storm and is tracked as vendor-invoice activity.
        if lower.contains("snow") || lower.contains("plow") {
            return SeedDefaults(
                kind: .snowRemoval,
                label: "snow removal contract",
                cadenceType: .customDays,
                daysOfWeek: nil,
                timeOfDay: nil,
                activeMonths: [12, 1, 2, 3, 4],
                eveningBeforeReminder: false,
                morningOfReminder: false,
                cadenceIntervalDays: 90
            )
        }

        return nil
    }

    /// Seeds a routine for a newly-added or newly-matched contractor. If a
    /// routine already exists for this household + kind (either vendor-
    /// linked OR independently-created), skips — idempotent.
    func seedIfNeeded(for contractor: ContractorRow) async {
        guard let category = contractor.category,
              let defaults = defaults(for: category) else { return }

        let db = DatabaseService.shared

        // Dedup: skip if a routine of this kind already exists for the
        // household, vendor-linked or not. We'd rather let the user
        // manually tie the contractor to an existing routine than create
        // a duplicate.
        do {
            let existing = try await db.fetchRoutines(householdId: contractor.householdId)
            let match = existing.first {
                $0.routineKind == defaults.kind.rawValue
            }
            if match != nil { return }
        } catch {
            // Fetch failure isn't fatal — still try to insert, and the
            // DB can surface any genuine constraint violations.
            Secure.warn("[RoutineSeeder] fetchRoutines failed: \(error.localizedDescription)")
        }

        let label = "\(contractor.companyName) \(defaults.label)"

        var insert = RoutineInsert(
            householdId: contractor.householdId,
            propertyId: nil,
            label: label,
            routineKind: defaults.kind.rawValue,
            cadenceType: defaults.cadenceType.rawValue
        )
        insert.icon = defaults.kind.icon
        insert.vendorId = contractor.id
        insert.cadenceIntervalDays = defaults.cadenceIntervalDays
        insert.daysOfWeek = defaults.daysOfWeek
        insert.timeOfDay = defaults.timeOfDay
        insert.activeMonths = defaults.activeMonths
        insert.eveningBeforeReminder = defaults.eveningBeforeReminder
        insert.morningOfReminder = defaults.morningOfReminder
        insert.cadenceSource = "auto_seeded"

        do {
            _ = try await db.createRoutine(insert)
            Analytics.track(.routineSeededFromContractor, [
                "kind": defaults.kind.rawValue,
                "vendor_id": contractor.id.uuidString
            ])
            NotificationCenter.default.post(name: .routineChanged, object: nil)
        } catch {
            Secure.warn("[RoutineSeeder] createRoutine failed: \(error.localizedDescription)")
        }
    }

    /// One-time backfill for existing households. Walks every contractor
    /// and calls `seedIfNeeded`. Safe to re-run — dedup prevents
    /// duplicates. Gate callers with a UserDefaults flag to avoid
    /// hitting on every launch.
    func backfillAllContractors(householdId: UUID) async {
        let db = DatabaseService.shared
        guard let contractors = try? await db.fetchContractors() else { return }
        // fetchContractors() returns household-scoped rows via RLS.
        for contractor in contractors where contractor.householdId == householdId {
            await seedIfNeeded(for: contractor)
        }
    }
}

// MARK: - Secure logging shim (matches the rest of the codebase's pattern)

private enum Secure {
    static func warn(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}

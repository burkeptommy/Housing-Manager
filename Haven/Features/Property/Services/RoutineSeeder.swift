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
    struct SeedDefaults {
        let kind: RoutineKind
        let serviceKey: String
        let label: String
        let cadenceType: RoutineCadenceType
        let daysOfWeek: [Int]?
        let timeOfDay: String?
        let activeMonths: [Int]
        let eveningBeforeReminder: Bool
        let morningOfReminder: Bool
        let cadenceIntervalDays: Int?
    }

    func defaults(for category: String) -> SeedDefaults? {
        let lower = category.lowercased()

        // Cleaning / housekeeping — biweekly year-round, morning reminder.
        if lower.contains("clean") || lower.contains("housekeep") || lower.contains("maid") {
            return SeedDefaults(
                kind: .cleaning,
                serviceKey: "housekeeping_program",
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
                serviceKey: "landscaping_program",
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

        // Waste hauling / pickup — weekly year-round with an evening-before
        // reminder because the homeowner usually needs to roll bins out.
        if lower.contains("trash")
            || lower.contains("recycling")
            || lower.contains("waste")
            || lower.contains("sanitation")
            || lower.contains("hauler")
            || lower.contains("compost")
            || lower.contains("yard waste") {
            return SeedDefaults(
                kind: .trash,
                serviceKey: "waste_program",
                label: "trash and recycling program",
                cadenceType: .weekly,
                daysOfWeek: [4], // Wednesday
                timeOfDay: "19:00",
                activeMonths: Array(1...12),
                eveningBeforeReminder: true,
                morningOfReminder: false,
                cadenceIntervalDays: nil
            )
        }

        // Pool service — weekly May-Sep.
        if lower.contains("pool") {
            return SeedDefaults(
                kind: .poolService,
                serviceKey: "pool_program",
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
                serviceKey: "pest_and_termite_program",
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
                serviceKey: "custom_routine_program",
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
                serviceKey: "mosquito_and_tick_program",
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
                serviceKey: "snow_and_ice_management_program",
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

        // Irrigation programs — startup + winterization live under one routine.
        if lower.contains("irrigation") || lower.contains("sprinkler") {
            return SeedDefaults(
                kind: .otherService,
                serviceKey: "irrigation_program",
                label: "irrigation program",
                cadenceType: .annual,
                daysOfWeek: nil,
                timeOfDay: nil,
                activeMonths: Array(3...11),
                eveningBeforeReminder: false,
                morningOfReminder: false,
                cadenceIntervalDays: nil
            )
        }

        // Security and smart-home service — typically an annual walkthrough.
        if lower.contains("security") || lower.contains("alarm") || lower.contains("smart home") {
            return SeedDefaults(
                kind: .otherService,
                serviceKey: "security_and_smart_home_program",
                label: "security and smart home program",
                cadenceType: .annual,
                daysOfWeek: nil,
                timeOfDay: nil,
                activeMonths: Array(1...12),
                eveningBeforeReminder: false,
                morningOfReminder: false,
                cadenceIntervalDays: nil
            )
        }

        // HVAC / boiler service — two seasonal visits rolled into one program.
        if lower.contains("hvac")
            || lower.contains("boiler")
            || lower.contains("furnace")
            || lower.contains("heating")
            || lower.contains("air condition") {
            return SeedDefaults(
                kind: .otherService,
                serviceKey: "hvac_program",
                label: "hvac program",
                cadenceType: .annual,
                daysOfWeek: nil,
                timeOfDay: nil,
                activeMonths: Array(1...12),
                eveningBeforeReminder: false,
                morningOfReminder: false,
                cadenceIntervalDays: nil
            )
        }

        if lower.contains("generator") {
            return SeedDefaults(
                kind: .otherService,
                serviceKey: "generator_program",
                label: "generator program",
                cadenceType: .annual,
                daysOfWeek: nil,
                timeOfDay: nil,
                activeMonths: Array(1...12),
                eveningBeforeReminder: false,
                morningOfReminder: false,
                cadenceIntervalDays: nil
            )
        }

        return nil
    }

    func defaults(forProviderType providerType: String) -> SeedDefaults? {
        let normalized = providerType.lowercased()
        if let category = UtilityContractorMirror.serviceCategory(forProviderType: normalized),
           let defaults = defaults(for: category) {
            return defaults
        }
        return defaults(for: normalized)
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
                $0.resolvedServiceKey == defaults.serviceKey
                    || ($0.routineKind == defaults.kind.rawValue && defaults.kind != .otherService)
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
        insert.serviceKey = defaults.serviceKey
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

    /// Chez v1: creates pending-vendor routines for the service-shaped
    /// categories the quiz used to auto-create as `home_systems` rows
    /// (Pet Waste, Mosquito & Tick, Trash & Recycling, Snow Removal,
    /// Handyman). These have no install date / brand / model — they're
    /// just recurring vendor visits — so they belong in the routines
    /// table, not home_systems.
    ///
    /// Idempotent: skips any kind for which a routine already exists in
    /// this household. Safe to call from quiz completion AND from the
    /// legacy backfill in `AppState.runServiceSystemArchiveOnceIfNeeded`.
    ///
    /// Each routine is created with `setupState = "pending_vendor"` so
    /// it surfaces as "Pick a pro for X" in Property → Systems →
    /// Services until the user captures a contractor (which then flows
    /// through `seedIfNeeded` to upgrade the routine to active +
    /// vendor-linked).
    func ensureSystemlessRoutines(
        propertyId: UUID,
        householdId: UUID,
        hasPets: Bool,
        isSnowState: Bool
    ) async {
        let db = DatabaseService.shared

        // Build the rule list using the existing `defaults(for:)` so
        // cadence + active months + reminders stay in lockstep with
        // contractor-seeded routines. Only include service-shaped
        // categories that the quiz USED to write as home_systems.
        struct Rule {
            let category: String
            let label: String
            let shouldCreate: Bool
        }
        let rules: [Rule] = [
            Rule(category: "handyman", label: "handyman visits", shouldCreate: true),
            Rule(category: "trash", label: "trash and recycling", shouldCreate: true),
            Rule(category: "mosquito", label: "mosquito & tick spraying", shouldCreate: true),
            Rule(category: "pet waste", label: "pet waste pickup", shouldCreate: hasPets),
            Rule(category: "snow", label: "snow removal", shouldCreate: isSnowState),
        ]

        let existing = (try? await db.fetchRoutines(householdId: householdId)) ?? []

        for rule in rules {
            guard rule.shouldCreate else { continue }
            guard let defaults = defaults(for: rule.category) else { continue }

            // Skip if a routine of this kind already exists. Matches
            // `seedIfNeeded`'s dedup so contractor-seeded and quiz-
            // seeded routines never duplicate.
            let alreadyExists = existing.contains { row in
                row.archivedAt == nil
                    && (row.routineKind == defaults.kind.rawValue
                        || row.resolvedServiceKey == defaults.serviceKey)
            }
            if alreadyExists { continue }

            let label = "Pick a pro for \(rule.label)"
            var insert = RoutineInsert(
                householdId: householdId,
                propertyId: propertyId,
                label: label,
                routineKind: defaults.kind.rawValue,
                cadenceType: defaults.cadenceType.rawValue
            )
            insert.serviceKey = defaults.serviceKey
            insert.icon = defaults.kind.icon
            insert.cadenceIntervalDays = defaults.cadenceIntervalDays
            insert.daysOfWeek = defaults.daysOfWeek
            insert.timeOfDay = defaults.timeOfDay
            insert.activeMonths = defaults.activeMonths
            insert.eveningBeforeReminder = defaults.eveningBeforeReminder
            insert.morningOfReminder = defaults.morningOfReminder
            insert.cadenceSource = "auto_seeded"
            insert.setupState = "pending_vendor"

            do {
                _ = try await db.createRoutine(insert)
                Analytics.track(.routineSeededFromContractor, [
                    "kind": defaults.kind.rawValue,
                    "source": "quiz_systemless"
                ])
            } catch {
                Secure.warn("[RoutineSeeder] ensureSystemlessRoutines createRoutine failed: \(error.localizedDescription)")
            }
        }

        NotificationCenter.default.post(name: .routineChanged, object: nil)
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

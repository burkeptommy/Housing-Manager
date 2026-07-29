import Foundation

/// Phase 66: Runtime task → routine grouping. When a Routine transitions
/// to `setup_state = 'active'` (vendor picked, Q15b answered, or user
/// explicitly set up the service), this engine links matching vendor
/// tasks to that routine via `parent_routine_id`, which hides them from
/// the Maintenance tab's "This Season" section and surfaces them under
/// the routine's detail view instead.
///
/// This promotes the Phase 54A template-authoring-time `bundleId`
/// pattern to runtime. Existing bundles (Roofing:spring, Handyman:spring,
/// Landscaping:spring, Generator:annual, etc.) continue to work via
/// `templateId` matching in the reconciler. New vendor routines that
/// don't have a pre-authored bundle group their matching tasks
/// dynamically via this engine.
///
/// Design choices (locked in the plan evaluation):
///  - Hide only `assignment_type = 'vendor'` tasks. DIY-default and
///    safetyFloor=false DIY-capable tasks are NOT hidden here — the
///    Day1TaskCurator routes those to the handyman routine instead.
///  - User-touched tasks (lastCompletedDate set, assignedToUserId set,
///    custom notes) are never re-parented. The user's explicit state
///    always wins over reconciler inference.
///  - Paused / draft routines don't hide. Only `.active` (and not
///    `is_paused`) routines trigger hiding.
enum RoutineGroupingEngine {

    /// Link every vendor-routed task in the routine's category to the
    /// routine via `parent_routine_id`. Called when a routine is activated
    /// or its vendor changes. Returns the count of tasks linked.
    ///
    /// Categories map routines to `home_systems.category` strings via
    /// `systemCategoriesFor(routineKind:)`. A cleaning routine matches
    /// no home_system categories (cleaning isn't tied to a system); a
    /// landscaping routine matches "Landscaping" + "Irrigation" (child
    /// systems under Landscaping via the related-categories map).
    @discardableResult
    static func linkVendorTasksToRoutine(
        _ routine: RoutineRow,
        in householdId: UUID,
        propertyId: UUID
    ) async throws -> Int {
        guard routine.hidesChildTasks else { return 0 }
        guard routine.scope == RoutineScope.property.rawValue else {
            // Vehicle routines use a different code path
            // (linkVehicleTasksToRoutine below).
            return 0
        }
        let matchingCategories = systemCategoriesFor(routine: routine)
        guard !matchingCategories.isEmpty else { return 0 }

        let db = DatabaseService.shared
        let allTasks = try await db.fetchMaintenanceTasks(propertyId: propertyId)
        let allSystems = try await db.fetchHomeSystems(propertyId: propertyId)
        let systemsById = Dictionary(uniqueKeysWithValues: allSystems.map { ($0.id, $0) })

        let canonicalMatchingKeys: Set<String> = Set(
            matchingCategories.compactMap {
                SystemCategoryRegistry.canonical(category: $0)
            }
        )

        let taskIds = allTasks.compactMap { task -> UUID? in
            // Skip user-touched tasks. Never re-parent an explicit
            // assignment (user chose to do this themselves or assigned a
            // specific person).
            if task.assignedToUserId != nil { return nil }
            if task.lastCompletedDate != nil { return nil }
            // Skip tasks already parented to a routine (don't re-route).
            if task.parentRoutineId != nil { return nil }
            // Skip archived.
            if task.isArchived == true { return nil }
            // Hide only vendor-routed. DIY-default stays visible here —
            // Day1TaskCurator handles the handyman routing separately.
            guard task.assignmentType == "vendor" else { return nil }
            // Match by home_systems.category → canonical.
            guard let systemId = task.systemId,
                  let system = systemsById[systemId],
                  let canonicalSystemCategory = SystemCategoryRegistry.canonical(category: system.category)
            else { return nil }
            guard canonicalMatchingKeys.contains(canonicalSystemCategory) else { return nil }
            return task.id
        }

        var count = 0
        for taskId in taskIds {
            var update = MaintenanceTaskUpdate()
            update.parentRoutineId = routine.id
            // Preserve any existing assignedRoute (vendor / handyman).
            if let _ = try? await db.updateMaintenanceTask(id: taskId, update) {
                count += 1
            }
        }

        if count > 0 {
            Analytics.track(.routineVendorTasksLinked, [
                "routine_id": routine.id.uuidString,
                "routine_kind": routine.routineKind,
                "tasks_linked": count
            ])
        }
        return count
    }

    /// Link all tasks on a specific vehicle to the vehicle routine.
    /// Called when a vehicle routine activates in shop_managed mode.
    /// Self_managed mode doesn't link — tasks stay visible as a compact
    /// per-vehicle checklist in the Vehicles section.
    @discardableResult
    static func linkVehicleTasksToRoutine(
        _ routine: RoutineRow,
        in householdId: UUID
    ) async throws -> Int {
        guard routine.scope == RoutineScope.vehicle.rawValue,
              let vehicleId = routine.vehicleId,
              routine.typedProgramMode == .shopManaged,
              routine.hidesChildTasks
        else { return 0 }

        let db = DatabaseService.shared
        let vehicleTasks = try await db.fetchMaintenanceTasks(vehicleId: vehicleId)

        var count = 0
        for task in vehicleTasks {
            if task.parentRoutineId != nil { continue }
            if task.isArchived == true { continue }
            if task.lastCompletedDate != nil { continue }

            var update = MaintenanceTaskUpdate()
            update.parentRoutineId = routine.id
            if let _ = try? await db.updateMaintenanceTask(id: task.id, update) {
                count += 1
            }
        }

        if count > 0 {
            Analytics.track(.vehicleRoutineTasksLinked, [
                "routine_id": routine.id.uuidString,
                "vehicle_id": vehicleId.uuidString,
                "tasks_linked": count
            ])
        }
        return count
    }

    /// Reverse operation — called when a routine is archived or switched
    /// from shop_managed to self_managed. Clears parent_routine_id on
    /// every task that currently points at this routine.
    ///
    /// July 2026 (audit F6): the old implementation set
    /// `update.parentRoutineId = nil` on the synthesized MaintenanceTaskUpdate
    /// encoder — nil fields are OMITTED from the PATCH, so this never
    /// actually unlinked anything. Routes through the explicit-null helper.
    static func unlinkTasksFromRoutine(_ routineId: UUID) async throws {
        try await DatabaseService.shared.clearTasksParentRoutine(routineId: routineId)
    }

    // MARK: - Category mapping

    static func systemCategoriesFor(routine: RoutineRow) -> [String] {
        if let serviceKey = routine.resolvedServiceKey {
            switch serviceKey {
            case "hvac_program":
                return ["HVAC"]
            case "security_and_smart_home_program":
                return ["Security System"]
            case "irrigation_program":
                return ["Irrigation"]
            case "landscaping_program":
                return ["Landscaping"]
            case "pool_program":
                return ["Pool/Spa", "Hot Tub"]
            case "pest_and_termite_program":
                return ["Pest Control"]
            case "mosquito_and_tick_program":
                return ["Mosquito & Tick"]
            case "snow_and_ice_management_program":
                return ["Snow Removal"]
            case "housekeeping_program":
                return ["Cleaning Service"]
            case "waste_program":
                return ["Trash & Recycling"]
            case "generator_program":
                return ["Generator"]
            case "handyman_program":
                return ["Handyman"]
            default:
                break
            }
        }

        guard let kind = routine.typedKind else { return [] }
        return systemCategoriesFor(routineKind: kind)
    }

    /// Phase 66: Map a RoutineKind to the `home_systems.category` strings
    /// whose tasks should hide under an active routine of that kind.
    /// Includes related categories (HVAC → Water Heater, Landscaping →
    /// Irrigation) so a single vendor can cover multiple system rows.
    static func systemCategoriesFor(routineKind: RoutineKind) -> [String] {
        switch routineKind {
        case .landscaping:
            return ["Landscaping", "Irrigation"]
        case .poolService:
            return ["Pool/Spa", "Hot Tub"]
        case .pestControl:
            return ["Pest Control"]
        case .petWaste:
            return ["Pet Waste"]
        case .mosquitoTick:
            return ["Mosquito & Tick"]
        case .snowRemoval:
            return ["Snow Removal"]
        case .gutterCleaning:
            return ["Gutter Cleaning", "Roofing"]
        case .windowCleaning:
            return ["Window Cleaning"]
        case .treeService:
            return ["Tree Service"]
        case .handymanRecurring:
            return ["Handyman"]
        case .cleaning:
            return ["Cleaning Service"]
        case .trash, .recycling, .compost, .yardWaste:
            return ["Trash & Recycling"]
        case .recurringDelivery, .schoolDropoff, .schoolPickup,
             .otherService, .otherCadence:
            return []
        }
    }

    /// Phase 66: Reverse mapping — when the curator needs to figure out
    /// which RoutineKind a system category should map to (e.g. "what
    /// vendor routine should cover HVAC tasks"), this gives the
    /// canonical routine_kind. Returns nil for categories that don't
    /// have a vendor-routine equivalent (Roofing isn't "you pay someone
    /// monthly" — it's project work).
    static func routineKindFor(systemCategory: String) -> RoutineKind? {
        let canonical = SystemCategoryRegistry.canonical(category: systemCategory) ?? systemCategory
        switch canonical {
        case "Landscaping", "Irrigation": return .landscaping
        case "Pool/Spa", "Hot Tub": return .poolService
        case "Pest Control": return .pestControl
        case "Pet Waste": return .petWaste
        case "Mosquito & Tick": return .mosquitoTick
        case "Snow Removal": return .snowRemoval
        case "Gutter Cleaning": return .gutterCleaning
        case "Window Cleaning": return .windowCleaning
        case "Tree Service": return .treeService
        case "Cleaning Service": return .cleaning
        case "Handyman": return .handymanRecurring
        // Phase 1.1: Painting reuses .otherService — no enum change
        // needed. RoutineSeeder.defaults(for:) maps the painter chip
        // onto serviceKey="painting_program" with annual cadence.
        case "Painting": return .otherService
        default: return nil
        }
    }

    /// Phase 67: Default cadence + active months per routine kind. Single
    /// source of truth shared by the Q15b vendor capture in
    /// `HouseQuizAnswerMapper.ensureVendorRoutineForCategory` and by the
    /// reconciler v2 path in
    /// `MaintenanceTaskReconciler.ensureRoutineForRoutineTierTemplate`.
    /// The user can refine cadence later via Q37 or the routine edit sheet.
    ///
    /// Returns `(cadenceType, intervalDays, activeMonths)` matching the
    /// `RoutineInsert` columns. `intervalDays` is only consumed when
    /// `cadenceType == .customDays`; for the other cadences the column
    /// stays nil and the cadence_type alone determines the period.
    static func defaultCadenceForRoutineKind(
        _ kind: RoutineKind
    ) -> (RoutineCadenceType, Int, [Int]) {
        let yearRound = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        switch kind {
        case .cleaning: return (.biweekly, 14, yearRound)
        case .landscaping: return (.weekly, 7, [4, 5, 6, 7, 8, 9, 10, 11])
        case .poolService: return (.weekly, 7, [5, 6, 7, 8, 9])
        case .pestControl: return (.quarterly, 91, yearRound)
        case .petWaste: return (.weekly, 7, yearRound)
        case .mosquitoTick: return (.monthly, 30, [4, 5, 6, 7, 8, 9, 10])
        case .snowRemoval: return (.annual, 365, [12, 1, 2, 3, 4])
        case .gutterCleaning: return (.semiannual, 182, yearRound)
        case .windowCleaning: return (.semiannual, 182, yearRound)
        case .treeService: return (.annual, 365, yearRound)
        // Phase 67: handyman_recurring is a singleton on-demand routine —
        // most callers go through `DatabaseService.fetchOrCreateHandymanRoutine`
        // which uses customDays/9999 to keep the routine "always present"
        // without firing on a calendar. The G1 seasonal reminder does its
        // own April/October anchor check independent of activeMonths. The
        // values returned here are the spec-aligned spring/fall semantics
        // for any future caller that creates a handyman routine through
        // this shared path (e.g. a manual "create routine" affordance for
        // a household whose preferences want a fixed cadence).
        case .handymanRecurring: return (.semiannual, 182, [4, 10])
        default: return (.annual, 365, yearRound)
        }
    }
}

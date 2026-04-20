import Foundation

/// Phase 66: Post-quiz task curator. Runs ONCE per property right after
/// `MaintenanceTaskReconciler.reconcileAll` finishes seeding the template
/// library's tasks. Walks every freshly-created template-based task and
/// routes it into one of four homes so the user's Day 1 maintenance tab
/// shows a populated handyman visit + 2-3 active vendor routines + a
/// short list of genuine decisions instead of a 49-task wall.
///
/// The four destinations (see the plan evaluation for rationale):
///
///  1. **Vendor routine (hidden)** — `assignment_type='vendor'` with a
///     matching Q15b contractor active routine. Task gets
///     `parent_routine_id = <routine.id>`. Hides from "This Season."
///
///  2. **Pending-vendor routine (hidden, surfaces as "Pick a pro")** —
///     `assignment_type='vendor'` with no matching active routine yet.
///     Creates a `setup_state='pending_vendor'` routine on the fly,
///     links the task under it. The routine renders as a "Pick a pro
///     for X" card in Your Services; the tasks inside it hide.
///
///  3. **Handyman routine (hidden, surfaces under Next Handyman Visit)**
///     — DIY-default / DIY-capable templates with
///     `diy_effort_minutes <= 60`, `!safetyFloor`, and preference tier
///     in {.mixed, .hireOut}. Routes to the singleton handyman routine.
///     `.diy` preference bypasses this — those users expect DIY tasks
///     as tasks.
///
///  4. **This Season (visible)** — everything else. Seasonal renewals,
///     one-off decisions, non-routine tasks. Typically ≤3 items on
///     Day 1 for an HNW user.
///
/// Gated on a `hasRunDay1Curator_<propertyId>_v1` UserDefaults flag so
/// it runs exactly once per property. Safe to delete the flag and re-run
/// if the user's situation materially changes (we don't today, but the
/// shape is ready for that).
enum Day1TaskCurator {

    static let storagePrefix = "hasRunDay1Curator_"
    static let storageSuffix = "_v1"

    struct Result: Equatable {
        var vendorRouted: Int = 0
        var pendingVendorRouted: Int = 0
        var handymanRouted: Int = 0
        var remainingInThisSeason: Int = 0
        var routinesCreated: Int = 0

        var isEmpty: Bool {
            vendorRouted == 0 && pendingVendorRouted == 0 && handymanRouted == 0
                && remainingInThisSeason == 0 && routinesCreated == 0
        }
    }

    /// Phase 66: Run the curator for a specific property. Idempotent via
    /// UserDefaults gate. Returns the Result so callers can surface a
    /// summary toast / analytics payload.
    @discardableResult
    @MainActor
    static func runIfNeeded(
        propertyId: UUID,
        householdId: UUID
    ) async -> Result {
        let flagKey = storagePrefix + propertyId.uuidString + storageSuffix
        if UserDefaults.standard.bool(forKey: flagKey) {
            return Result()
        }
        let result = await run(propertyId: propertyId, householdId: householdId)
        UserDefaults.standard.set(true, forKey: flagKey)
        Analytics.track(.day1CuratorRan, [
            "property_id": propertyId.uuidString,
            "vendor_routed": result.vendorRouted,
            "pending_vendor_routed": result.pendingVendorRouted,
            "handyman_routed": result.handymanRouted,
            "this_season_count": result.remainingInThisSeason,
            "routines_created": result.routinesCreated
        ])
        return result
    }

    /// Phase 66: The raw runner — call this directly from a debug Settings
    /// button / future re-trigger. `runIfNeeded` is the normal entry point.
    ///
    /// @MainActor because the reconciler's `preferenceTierFromProperty` is
    /// MainActor-isolated. Every DB call is already async; doing the work
    /// on main is fine because there's no heavy computation here — we
    /// await DB round trips.
    @MainActor
    static func run(
        propertyId: UUID,
        householdId: UUID
    ) async -> Result {
        let db = DatabaseService.shared
        var result = Result()

        // Gather context: property (for preference tier), routines,
        // contractors, tasks, systems, preferred handyman.
        guard let property = try? await db.fetchProperty(id: propertyId) else {
            return result
        }
        let preferenceTier = MaintenanceTaskReconciler.preferenceTierFromProperty(property)

        // Only auto-route when the user has signaled they want to hire out
        // at least some work. `.diy` users see DIY tasks — the curator
        // STILL routes explicit vendor tasks but leaves DIY-defaults
        // visible in This Season per their preference.
        let shouldRouteDIYToHandyman: Bool = {
            switch preferenceTier {
            case .diy: return false
            case .mixed, .hireOut: return true
            }
        }()

        let allRoutines = (try? await db.fetchRoutines(householdId: householdId)) ?? []
        let propertyRoutines = allRoutines.filter {
            $0.typedScope == .property && ($0.propertyId == propertyId || $0.propertyId == nil)
        }
        let activeVendorRoutinesByCategory: [String: RoutineRow] = Dictionary(
            uniqueKeysWithValues: propertyRoutines.compactMap { routine -> (String, RoutineRow)? in
                guard routine.typedSetupState == .active,
                      let kind = routine.typedKind,
                      kind.isVendorBased,
                      routine.vendorId != nil
                else { return nil }
                // Use the first matching system category as the key. Most
                // routines have one. Pool + Hot Tub are handled separately
                // below by checking both kinds at lookup time.
                let categories = RoutineGroupingEngine.systemCategoriesFor(routineKind: kind)
                guard let primary = categories.first else { return nil }
                return (primary, routine)
            }
        )
        var pendingVendorRoutinesByCategory: [String: RoutineRow] = Dictionary(
            uniqueKeysWithValues: propertyRoutines.compactMap { routine -> (String, RoutineRow)? in
                guard routine.typedSetupState == .pendingVendor,
                      let kind = routine.typedKind
                else { return nil }
                let categories = RoutineGroupingEngine.systemCategoriesFor(routineKind: kind)
                guard let primary = categories.first else { return nil }
                return (primary, routine)
            }
        )

        let preferredHandymanId = (try? await db.fetchHousehold(id: householdId))?
            .preferredHandymanContractorId

        let allTasks = (try? await db.fetchMaintenanceTasks(propertyId: propertyId)) ?? []
        let allSystems = (try? await db.fetchHomeSystems(propertyId: propertyId)) ?? []
        let systemsById = Dictionary(uniqueKeysWithValues: allSystems.map { ($0.id, $0) })

        // Lazily create the handyman routine only when we need it. Skip
        // the DB write when the user is a .diy purist (no handyman routing).
        var handymanRoutine: RoutineRow? = nil
        if shouldRouteDIYToHandyman {
            handymanRoutine = try? await db.fetchOrCreateHandymanRoutine(
                householdId: householdId,
                propertyId: propertyId,
                preferredHandymanContractorId: preferredHandymanId
            )
            if handymanRoutine != nil
                && !propertyRoutines.contains(where: { $0.typedKind == .handymanRecurring }) {
                result.routinesCreated += 1
            }
        }

        // Walk each task and route it.
        for task in allTasks {
            // Never re-parent user-touched tasks.
            if task.assignedToUserId != nil { continue }
            if task.lastCompletedDate != nil { continue }
            if task.parentRoutineId != nil { continue }
            if task.isArchived == true { continue }
            // Non-template tasks (custom user tasks) stay in This Season.
            guard task.isTemplateBased == true, let templateKey = task.templateId else {
                result.remainingInThisSeason += 1
                continue
            }

            // Resolve category via home_system. If the task has no
            // system (rare — should not happen for template-seeded tasks)
            // fall back to parsing the templateKey prefix.
            let category: String? = {
                if let systemId = task.systemId,
                   let system = systemsById[systemId] {
                    return SystemCategoryRegistry.canonical(category: system.category)
                        ?? system.category
                }
                // templateKey shape is "<Category>:<title>"; grab prefix
                if let prefix = templateKey.split(separator: ":").first {
                    return SystemCategoryRegistry.canonical(category: String(prefix))
                        ?? String(prefix)
                }
                return nil
            }()

            let template = MaintenanceTemplates.template(forKey: templateKey)
            let isVendor = (task.assignmentType == "vendor")
            let isDIY = (task.assignmentType == "personal")

            // --- 1. Vendor routes ---
            if isVendor, let category {
                // Check for an active vendor routine whose categories include this.
                if let routine = routine(matching: category, in: activeVendorRoutinesByCategory) {
                    if await linkTask(task.id, to: routine, db: db) {
                        result.vendorRouted += 1
                        Analytics.track(.day1CuratorTaskRoutedVendor, [
                            "task_id": task.id.uuidString,
                            "routine_id": routine.id.uuidString,
                            "category": category
                        ])
                        continue
                    }
                }

                // Otherwise, create-or-find a pending-vendor routine.
                if let kind = RoutineGroupingEngine.routineKindFor(systemCategory: category) {
                    let existing = routine(matching: category, in: pendingVendorRoutinesByCategory)
                    let pendingRoutine: RoutineRow?
                    if let existing {
                        pendingRoutine = existing
                    } else {
                        let created = try? await createPendingVendorRoutine(
                            kind: kind,
                            category: category,
                            propertyId: propertyId,
                            householdId: householdId,
                            db: db
                        )
                        if let created {
                            pendingVendorRoutinesByCategory[category] = created
                            result.routinesCreated += 1
                        }
                        pendingRoutine = created
                    }

                    if let pendingRoutine,
                       await linkTask(task.id, to: pendingRoutine, db: db) {
                        result.pendingVendorRouted += 1
                        Analytics.track(.day1CuratorTaskRoutedPendingVendor, [
                            "task_id": task.id.uuidString,
                            "routine_id": pendingRoutine.id.uuidString,
                            "category": category
                        ])
                        continue
                    }
                }

                // Fall-through: vendor task with no viable routine.
                // Stays visible in This Season with the existing
                // "Find a contractor for: X" UI from Phase 19l.
                result.remainingInThisSeason += 1
                continue
            }

            // --- 2. DIY / handyman routes ---
            if isDIY, shouldRouteDIYToHandyman, let handyman = handymanRoutine {
                let shouldRoute = shouldRouteToHandyman(
                    template: template,
                    task: task,
                    preferenceTier: preferenceTier
                )
                if shouldRoute {
                    if await linkTask(task.id, to: handyman, db: db, markHandymanRoute: true) {
                        result.handymanRouted += 1
                        Analytics.track(.day1CuratorTaskRoutedHandyman, [
                            "task_id": task.id.uuidString,
                            "routine_id": handyman.id.uuidString,
                            "template_id": templateKey
                        ])
                        continue
                    }
                }
            }

            // --- 3. Fallback: stays in This Season ---
            result.remainingInThisSeason += 1
        }

        // Ping the dashboard so the maintenance tab / Up Next cache
        // refreshes after the curator rearranges things.
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(name: .routineChanged, object: nil)

        return result
    }

    // MARK: - Helpers

    /// Decide whether a DIY/either task should route to the handyman
    /// routine. Low-effort, non-safety-floor, and the template must
    /// genuinely be handyman-appropriate (DIY-default or DIY-capable).
    /// `.diy` preference is filtered at the caller; this only runs for
    /// `.mixed` / `.hireOut`.
    private static func shouldRouteToHandyman(
        template: MaintenanceTemplate?,
        task: MaintenanceTaskDBRow,
        preferenceTier: VendorPreferenceTier
    ) -> Bool {
        guard let template else {
            // No template match — can't reason about effort. Leave
            // visible rather than silently routing.
            return false
        }
        if template.safetyFloor { return false }
        // Only route templates that are genuinely handyman-appropriate.
        // `.diyDefault` (monthly filter swaps, weatherstripping walks)
        // and `.diyCapable` (deck staining, paint touch-up) are both
        // in scope; `.vendorDefault` never routes to handyman — if the
        // reconciler produced a `.personal` task out of a
        // `.vendorDefault` template it's an edge case we shouldn't
        // silently re-parent.
        switch template.routing {
        case .diyDefault, .diyCapable:
            break
        case .vendorDefault, .bundledIntoParent:
            return false
        @unknown default:
            return false
        }
        // Effort cap: 60 minutes for `.hireOut`, 30 for `.mixed`. These
        // match MaintenanceTaskReconciler.resolveAssignment's internal
        // threshold so Day 1 routing stays consistent with subsequent
        // quiz answer reconciles.
        let effort = template.diyEffortMinutes ?? 60
        let cap: Int = preferenceTier == .hireOut ? 60 : 30
        return effort <= cap
    }

    /// Find the routine whose categories include `category`. The
    /// dictionary is keyed on the primary category per routine, but a
    /// routine like `.landscaping` covers both "Landscaping" and
    /// "Irrigation" — so we fall back to a kind-level check if the
    /// direct key misses.
    private static func routine(
        matching category: String,
        in byCategory: [String: RoutineRow]
    ) -> RoutineRow? {
        if let direct = byCategory[category] { return direct }
        // Kind-level match: find a routine whose kind's category list
        // includes `category`.
        for routine in byCategory.values {
            guard let kind = routine.typedKind else { continue }
            let categories = RoutineGroupingEngine.systemCategoriesFor(routineKind: kind)
            if categories.contains(category) { return routine }
        }
        return nil
    }

    /// Link a task to a routine via `parent_routine_id`. Optionally
    /// stamps `assigned_route = 'handyman'` when routing to the
    /// handyman container so the detail sheet's routing picker surfaces
    /// the right state on open.
    private static func linkTask(
        _ taskId: UUID,
        to routine: RoutineRow,
        db: DatabaseService,
        markHandymanRoute: Bool = false
    ) async -> Bool {
        var update = MaintenanceTaskUpdate()
        update.parentRoutineId = routine.id
        if markHandymanRoute {
            update.assignedRoute = "handyman"
        }
        do {
            _ = try await db.updateMaintenanceTask(id: taskId, update)
            return true
        } catch {
            print("[Day1Curator] linkTask failed: \(error)")
            return false
        }
    }

    /// Phase 66: Create a `setup_state='pending_vendor'` routine so the
    /// category gets a "Pick a pro for X" card in Your Services. Cadence
    /// pulls from the registry's default when available; falls back to
    /// annual.
    private static func createPendingVendorRoutine(
        kind: RoutineKind,
        category: String,
        propertyId: UUID,
        householdId: UUID,
        db: DatabaseService
    ) async throws -> RoutineRow {
        let (cadenceType, cadenceInterval) = defaultCadence(for: kind)
        var insert = RoutineInsert(
            householdId: householdId,
            propertyId: propertyId,
            label: "Pick a pro for \(kind.displayLabel.lowercased())",
            routineKind: kind.rawValue,
            cadenceType: cadenceType.rawValue
        )
        if cadenceType == .customDays {
            insert.cadenceIntervalDays = cadenceInterval
        }
        insert.icon = kind.icon
        insert.setupState = "pending_vendor"
        insert.notes = "Auto-created so Day 1 tasks in this category have a home. Assign a vendor from Your Services to activate."

        let created = try await db.createRoutine(insert)
        Analytics.track(.pendingVendorRoutineCreated, [
            "category": category,
            "routine_kind": kind.rawValue
        ])
        return created
    }

    /// Default cadence per routine kind for auto-created pending-vendor
    /// routines. User can edit via the setup sheet later.
    private static func defaultCadence(for kind: RoutineKind) -> (RoutineCadenceType, Int) {
        switch kind {
        case .cleaning: return (.biweekly, 14)
        case .landscaping: return (.weekly, 7)
        case .poolService: return (.weekly, 7)
        case .pestControl: return (.quarterly, 91)
        case .petWaste: return (.weekly, 7)
        case .mosquitoTick: return (.monthly, 30)
        case .snowRemoval: return (.annual, 365)  // Seasonal contract — renewed annually
        case .gutterCleaning: return (.semiannual, 182)
        case .windowCleaning: return (.semiannual, 182)
        case .treeService: return (.annual, 365)
        case .handymanRecurring: return (.customDays, 9999)  // On-demand
        default: return (.annual, 365)
        }
    }
}

import Foundation

@MainActor
enum ServiceOrchestrator {
    private static let db = DatabaseService.shared

    @discardableResult
    static func syncPropertyServices(
        propertyId: UUID,
        householdId: UUID
    ) async -> MaintenanceTaskReconciler.ReconciliationResult {
        let result = await MaintenanceTaskReconciler.reconcileAll(
            propertyId: propertyId,
            householdId: householdId
        )
        return result
    }

    static func backfillServiceMetadata(
        propertyId: UUID,
        householdId: UUID
    ) async {
        let tasks = (try? await db.fetchMaintenanceTasks(propertyId: propertyId)) ?? []
        for task in tasks {
            guard let expected = ServiceLibrary.serviceKey(for: task),
                  task.serviceKey != expected else { continue }
            var update = MaintenanceTaskUpdate()
            update.serviceKey = expected
            _ = try? await db.updateMaintenanceTask(id: task.id, update)
        }

        let routines = (try? await db.fetchRoutines(householdId: householdId)) ?? []
        for routine in routines {
            guard let expected = ServiceLibrary.serviceKey(for: routine),
                  routine.serviceKey != expected else { continue }
            var update = RoutineUpdate()
            update.serviceKey = expected
            _ = try? await db.updateRoutine(id: routine.id, update)
        }

        for routine in routines {
            let visits = (try? await db.fetchRoutineVisits(routineId: routine.id)) ?? []
            for visit in visits {
                guard let expected = ServiceLibrary.visitTypeKey(
                    for: routine,
                    scheduledDate: visit.scheduledDate,
                    notes: visit.notes
                ),
                visit.visitTypeKey != expected else { continue }

                var update = RoutineVisitUpdate()
                update.visitTypeKey = expected
                _ = try? await db.updateRoutineVisit(id: visit.id, update)
            }
        }
    }

    static func createCustomService(
        _ insert: MaintenanceTaskInsert
    ) async throws -> MaintenanceTaskDBRow {
        var insert = insert
        if insert.serviceKey == nil {
            insert.serviceKey = ServiceLibrary.serviceKey(for: insert) ?? "custom_seasonal_service"
        }
        return try await db.createMaintenanceTask(insert)
    }

    static func createCustomRoutine(
        _ insert: RoutineInsert
    ) async throws -> RoutineRow {
        var insert = insert
        if insert.serviceKey == nil {
            insert.serviceKey = ServiceLibrary.serviceKey(for: insert) ?? "custom_routine_program"
        }
        return try await db.createRoutine(insert)
    }

    static func createHandymanItem(
        householdId: UUID,
        propertyId: UUID?,
        title: String,
        description: String? = nil,
        notes: String? = nil
    ) async throws -> HandymanPunchItemRow {
        if let propertyId {
            _ = try? await db.fetchOrCreateHandymanRoutine(
                householdId: householdId,
                propertyId: propertyId
            )
        }

        var insert = HandymanPunchItemInsert(
            householdId: householdId,
            propertyId: propertyId,
            title: title
        )
        insert.description = description
        insert.notes = notes
        insert.source = "service_orchestrator"
        return try await db.createHandymanPunchItem(insert)
    }

    static func routeService(
        task: MaintenanceTaskDBRow,
        route: String,
        category: String?,
        routine: RoutineRow? = nil,
        persistPreference: Bool = true
    ) async throws {
        switch route {
        case "handyman":
            _ = try await db.assignTaskToHandymanRoutine(task: task)
            if persistPreference {
                try await saveStickyPreference(task: task, category: category, route: route, vendorId: nil)
            }
        case "vendor":
            guard let routine else {
                throw NSError(
                    domain: "ServiceOrchestrator",
                    code: 68,
                    userInfo: [NSLocalizedDescriptionKey: "Vendor route requires a routine"]
                )
            }
            var update = MaintenanceTaskUpdate()
            update.parentRoutineId = routine.id
            update.assignedRoute = "vendor"
            update.assignedContractorId = routine.vendorId
            _ = try await db.updateMaintenanceTask(id: task.id, update)
            if persistPreference {
                try await saveStickyPreference(
                    task: task,
                    category: category,
                    route: route,
                    vendorId: routine.vendorId
                )
            }
        case "diy":
            var update = MaintenanceTaskUpdate()
            update.parentRoutineId = nil
            update.assignedRoute = "diy"
            _ = try await db.updateMaintenanceTask(id: task.id, update)
            if persistPreference {
                try await saveStickyPreference(task: task, category: category, route: route, vendorId: nil)
            }
        default:
            break
        }

        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(name: .routineChanged, object: nil)
    }

    static func recordVisit(
        routine: RoutineRow,
        scheduledDate: String,
        notes: String? = nil,
        actualCostCents: Int? = nil,
        visitState: RoutineVisitState = .scheduled,
        confirmedBy: String? = nil
    ) async throws -> RoutineVisitRow {
        var insert = RoutineVisitInsert(
            routineId: routine.id,
            scheduledDate: scheduledDate
        )
        insert.status = visitState == .completed ? "confirmed" : "upcoming"
        insert.visitState = visitState.rawValue
        insert.notes = notes
        insert.actualCostCents = actualCostCents
        insert.confirmedBy = confirmedBy
        insert.visitTypeKey = ServiceLibrary.visitTypeKey(
            for: routine,
            scheduledDate: scheduledDate,
            notes: notes
        )
        return try await db.createRoutineVisit(insert)
    }

    private static func saveStickyPreference(
        task: MaintenanceTaskDBRow,
        category: String?,
        route: String,
        vendorId: UUID?
    ) async throws {
        guard let propertyId = task.propertyId else { return }
        let taskCategory = category
            ?? task.templateId?.split(separator: ":").first.map(String.init)
            ?? task.resolvedServiceKey
            ?? "General"

        let insert = RoutingPreferenceInsert(
            householdId: task.householdId,
            propertyId: propertyId,
            taskCategory: taskCategory,
            scopeType: task.templateId != nil ? "template" : "category",
            preferredRoute: route,
            preferredVendorId: vendorId
        )
        _ = try? await db.upsertRoutingPreference(insert)
    }
}

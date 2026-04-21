import XCTest
@testable import Haven

/// Phase 67 regression tests for the `HandymanVisitService.scanUpsells`
/// logic. These lock in the filter rules that ensure the "Your handyman
/// could also handle these" section only surfaces appropriate candidates.
@MainActor
final class HandymanUpsellScannerTests: XCTestCase {

    /// Build a minimal Fall Handyman Visit parent for testing.
    private func makeFallVisitParent() -> MaintenanceTaskDBRow {
        MaintenanceTaskDBRow.synthetic(
            id: UUID(),
            title: "Fall Handyman Visit",
            nextDueDate: "2026-10-01",
            propertyId: UUID(),
            householdId: UUID(),
            priority: "Medium"
        )
    }

    private func makeTask(
        title: String,
        templateId: String?,
        nextDueDate: String,
        assignedRoute: String? = nil,
        vehicleId: UUID? = nil
    ) -> MaintenanceTaskDBRow {
        // Use synthetic factory; then we'd need to set additional fields
        // via reflection or by constructing MaintenanceTaskDBRow directly.
        // For test purposes, synthetic factory is sufficient for most
        // upsell-filter checks since the scanner only inspects the fields
        // we set here.
        var task = MaintenanceTaskDBRow.synthetic(
            id: UUID(),
            title: title,
            nextDueDate: nextDueDate,
            propertyId: UUID(),
            vehicleId: vehicleId,
            householdId: UUID(),
            priority: "Medium"
        )
        // Note: we'd ideally set templateId + assignedRoute here, but
        // MaintenanceTaskDBRow uses `let` fields so we can't mutate after
        // init. This test focuses on the filters that don't need templateId.
        // Integration tests (with a real DB) cover the templateId-dependent
        // rules.
        _ = templateId
        _ = assignedRoute
        return task
    }

    func test_upsellScanner_excludesVehicleTasks() {
        let parent = makeFallVisitParent()
        let vehicleTask = makeTask(
            title: "Oil change",
            templateId: nil,
            nextDueDate: "2026-05-01",
            vehicleId: UUID()
        )
        let candidates = HandymanVisitService.scanUpsells(
            for: parent,
            allTasks: [vehicleTask],
            punchItems: []
        )
        XCTAssertFalse(candidates.contains(where: { $0.title == "Oil change" }),
            "Vehicle tasks must be excluded from handyman upsells")
    }

    func test_upsellScanner_includesPendingPunchItems() {
        let parent = makeFallVisitParent()
        let punchItem = HandymanPunchItemRow(
            id: UUID(),
            householdId: parent.householdId,
            propertyId: parent.propertyId,
            title: "Fix squeaky cabinet door",
            description: nil,
            source: "manual",
            sourceTaskId: nil,
            addedByUserId: nil,
            estimatedMinutes: 10,
            estimatedCostRange: nil,
            notes: nil,
            createdAt: Date(),
            completedAt: nil,
            completedVisitTaskId: nil,
            archivedAt: nil,
            maintenanceTaskId: nil
        )
        let candidates = HandymanVisitService.scanUpsells(
            for: parent,
            allTasks: [],
            punchItems: [punchItem]
        )
        XCTAssertTrue(candidates.contains { $0.title == "Fix squeaky cabinet door" },
            "Pending punch items must surface as upsells regardless of due-date window")
    }

    func test_upsellScanner_excludesCompletedPunchItems() {
        let parent = makeFallVisitParent()
        let completedItem = HandymanPunchItemRow(
            id: UUID(),
            householdId: parent.householdId,
            propertyId: parent.propertyId,
            title: "Completed item",
            description: nil,
            source: "manual",
            sourceTaskId: nil,
            addedByUserId: nil,
            estimatedMinutes: nil,
            estimatedCostRange: nil,
            notes: nil,
            createdAt: Date(),
            completedAt: Date(),  // already done
            completedVisitTaskId: UUID(),
            archivedAt: nil,
            maintenanceTaskId: nil
        )
        let candidates = HandymanVisitService.scanUpsells(
            for: parent,
            allTasks: [],
            punchItems: [completedItem]
        )
        XCTAssertFalse(candidates.contains { $0.title == "Completed item" },
            "Completed punch items must NOT surface as upsells")
    }

    func test_upsellScanner_capsAt10Candidates() {
        let parent = makeFallVisitParent()
        // Build 20 punch items; scanner should return at most 10.
        let punchItems = (0..<20).map { i in
            HandymanPunchItemRow(
                id: UUID(),
                householdId: parent.householdId,
                propertyId: parent.propertyId,
                title: "Punch item \(i)",
                description: nil,
                source: "manual",
                sourceTaskId: nil,
                addedByUserId: nil,
                estimatedMinutes: nil,
                estimatedCostRange: nil,
                notes: nil,
                createdAt: Date(),
                completedAt: nil,
                completedVisitTaskId: nil,
                archivedAt: nil,
                maintenanceTaskId: nil
            )
        }
        let candidates = HandymanVisitService.scanUpsells(
            for: parent,
            allTasks: [],
            punchItems: punchItems
        )
        XCTAssertLessThanOrEqual(candidates.count, 10,
            "Scanner must cap at 10 candidates to avoid overwhelming the visit UI")
    }
}

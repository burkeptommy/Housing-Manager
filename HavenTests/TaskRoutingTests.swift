import XCTest
@testable import Haven

/// Phase 64/65 regression tests — the routing enum + preference
/// precedence is load-bearing for every task the user sees. These
/// tests lock in the contract.
@MainActor
final class TaskRoutingTests: XCTestCase {

    // MARK: - Bucket model derivation

    func test_bucketDerivation_vendorOnly_fromExplicitRouting() {
        let mode = TaskRoutingMode.derive(
            templateRouting: .vendorOnly,
            safetyFloor: false,
            hasActiveContract: false
        )
        XCTAssertEqual(mode, .vendorOnly, "Explicit .vendorOnly routing must map to single-option picker mode")
    }

    func test_bucketDerivation_vendorOnly_fromSafetyFloor() {
        // Phase 64 preserves the safety_floor bool as a shortcut to
        // vendorOnly — any template marked safetyFloor = true should
        // always show vendor-only picker regardless of its primary routing.
        let mode = TaskRoutingMode.derive(
            templateRouting: .diyCapable,
            safetyFloor: true,
            hasActiveContract: false
        )
        XCTAssertEqual(mode, .vendorOnly, "safetyFloor must force vendorOnly mode")
    }

    func test_bucketDerivation_readOnly_fromActiveContract() {
        // Active service contract collapses the picker to read-only
        // display ("Scheduled with {vendor} based on your service contract").
        let mode = TaskRoutingMode.derive(
            templateRouting: .diyCapable,
            safetyFloor: false,
            hasActiveContract: true
        )
        XCTAssertEqual(mode, .readOnly, "Active contract must force readOnly mode")
    }

    func test_bucketDerivation_handymanOrDIY_fromDiyDefault() {
        let mode = TaskRoutingMode.derive(
            templateRouting: .diyDefault,
            safetyFloor: false,
            hasActiveContract: false
        )
        XCTAssertEqual(mode, .handymanOrDIY, ".diyDefault maps to 2-option (handyman/DIY) picker")
    }

    func test_bucketDerivation_threeOption_fromDiyCapable() {
        let mode = TaskRoutingMode.derive(
            templateRouting: .diyCapable,
            safetyFloor: false,
            hasActiveContract: false
        )
        XCTAssertEqual(mode, .vendorOrHandymanOrDIY, ".diyCapable maps to 3-option picker")
    }

    func test_bucketDerivation_threeOption_fromNilTemplate() {
        // Custom tasks (no template) default to three-option so user
        // can pick however they want.
        let mode = TaskRoutingMode.derive(
            templateRouting: nil,
            safetyFloor: false,
            hasActiveContract: false
        )
        XCTAssertEqual(mode, .vendorOrHandymanOrDIY, "nil template maps to 3-option")
    }

    // MARK: - Routing preference precedence
    //
    // These tests pass minimal template objects + preference rows into
    // `resolveAssignedRoute` and assert the returned route matches the
    // precedence ladder documented in MaintenanceTaskReconciler:
    //   template override > category pref > active contract >
    //   handyman preference default > template assignment type > nil.

    /// Builds a minimal template with just enough fields for the route
    /// resolver to function. The resolver only reads `routing` and
    /// `safetyFloor` so other fields can be defaulted.
    private func makeTemplate(
        category: String = "Plumbing",
        title: String = "Test task",
        routing: TaskRouting? = nil,
        safetyFloor: Bool = false,
        stableId: String? = nil
    ) -> MaintenanceTemplate {
        MaintenanceTemplate(
            systemCategory: category,
            title: title,
            description: "",
            frequency: "Annually",
            priority: "Medium",
            estimatedCostRange: "",
            isDIY: false,
            seasonalTiming: nil,
            professionalRequired: false,
            notes: nil,
            stableId: stableId,
            routingOverride: routing,
            safetyFloor: safetyFloor
        )
    }

    private func makePref(
        category: String,
        scope: String,
        route: String
    ) -> RoutingPreferenceRow {
        RoutingPreferenceRow(
            id: UUID(),
            householdId: UUID(),
            propertyId: UUID(),
            taskCategory: category,
            scopeType: scope,
            preferredRoute: route,
            preferredVendorId: nil,
            createdAt: nil,
            updatedAt: nil,
            lastConfirmedAt: nil
        )
    }

    func test_preferencePrecedence_templateOverride_beatsCategory() {
        let template = makeTemplate(
            category: "Plumbing",
            title: "Drain cleaning",
            stableId: "Plumbing:Drain cleaning"
        )
        let categoryPref = makePref(category: "Plumbing", scope: "category", route: "vendor")
        let templatePref = makePref(category: template.templateKey, scope: "template", route: "diy")
        let route = MaintenanceTaskReconciler.resolveAssignedRoute(
            template: template,
            templateKey: template.templateKey,
            category: "Plumbing",
            preferences: [categoryPref, templatePref],
            matchingContractor: nil,
            handymanPreference: nil,
            assignmentType: "either"
        )
        XCTAssertEqual(route, "diy", "Template-level override must beat category-level preference")
    }

    func test_preferencePrecedence_categoryPref_beatsHandymanDefault() {
        let template = makeTemplate(
            category: "Plumbing",
            title: "Test sump pump battery backup",
            routing: .diyDefault
        )
        let categoryPref = makePref(category: "Plumbing", scope: "category", route: "handyman")
        let route = MaintenanceTaskReconciler.resolveAssignedRoute(
            template: template,
            templateKey: template.templateKey,
            category: "Plumbing",
            preferences: [categoryPref],
            matchingContractor: nil,
            handymanPreference: "does_diy",
            assignmentType: "either"
        )
        XCTAssertEqual(route, "handyman", "Category preference must beat handyman-preference default")
    }

    func test_preferencePrecedence_handymanDefault_forDiyDefaultTemplate() {
        let template = makeTemplate(
            category: "Plumbing",
            title: "Test sump pump battery backup",
            routing: .diyDefault
        )
        let routeHasOne = MaintenanceTaskReconciler.resolveAssignedRoute(
            template: template,
            templateKey: template.templateKey,
            category: "Plumbing",
            preferences: [],
            matchingContractor: nil,
            handymanPreference: "has_one",
            assignmentType: "either"
        )
        XCTAssertEqual(routeHasOne, "handyman", "has_one preference routes .diyDefault tasks to handyman")

        let routeDIY = MaintenanceTaskReconciler.resolveAssignedRoute(
            template: template,
            templateKey: template.templateKey,
            category: "Plumbing",
            preferences: [],
            matchingContractor: nil,
            handymanPreference: "does_diy",
            assignmentType: "either"
        )
        XCTAssertEqual(routeDIY, "diy", "does_diy preference routes .diyDefault tasks to DIY")
    }

    func test_preferencePrecedence_nilForEitherWithNoSignal() {
        // Either-assignment template with no preferences + no handyman
        // context returns nil so the picker surfaces on the task.
        let template = makeTemplate(
            category: "Landscaping",
            title: "Pressure wash patio and walkways",
            routing: .diyCapable
        )
        let route = MaintenanceTaskReconciler.resolveAssignedRoute(
            template: template,
            templateKey: template.templateKey,
            category: "Landscaping",
            preferences: [],
            matchingContractor: nil,
            handymanPreference: nil,
            assignmentType: "either"
        )
        XCTAssertNil(route, "Either template with no signals must return nil (picker shows)")
    }
}

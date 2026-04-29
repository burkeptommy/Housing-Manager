import XCTest
@testable import Haven

final class ServiceLibraryTests: XCTestCase {

    func test_hvacTemplatesCollapseIntoSingleProgram() {
        XCTAssertEqual(
            ServiceLibrary.serviceKey(forLegacyTemplateKey: "HVAC:HVAC tune-up (cooling)"),
            "hvac_program"
        )
        XCTAssertEqual(
            ServiceLibrary.serviceKey(forLegacyTemplateKey: "HVAC:Annual boiler service"),
            "hvac_program"
        )
        XCTAssertEqual(
            ServiceLibrary.visitTypeKey(forLegacyTemplateKey: "HVAC:HVAC tune-up (cooling)"),
            "cooling_service"
        )
        XCTAssertEqual(
            ServiceLibrary.visitTypeKey(forLegacyTemplateKey: "HVAC:Annual boiler service"),
            "heating_service"
        )
    }

    func test_poolAndIrrigationVariantsCollapseIntoPrograms() {
        XCTAssertEqual(
            ServiceLibrary.serviceKey(forLegacyTemplateKey: "Irrigation:Backflow preventer test"),
            "irrigation_program"
        )
        XCTAssertEqual(
            ServiceLibrary.visitTypeKey(forLegacyTemplateKey: "Irrigation:Winterize irrigation system"),
            "winterization"
        )
        XCTAssertEqual(
            ServiceLibrary.serviceKey(forLegacyTemplateKey: "Pool/Spa:Pool closing and winterization"),
            "pool_program"
        )
        XCTAssertEqual(
            ServiceLibrary.visitTypeKey(forLegacyTemplateKey: "Pool/Spa:Pool closing and winterization"),
            "closing"
        )
    }

    func test_genericRoutineKindsUseLabelHeuristicsBeforeCustomFallback() {
        XCTAssertEqual(
            ServiceLibrary.serviceKey(forRoutineKind: RoutineKind.otherService.rawValue, label: "Generator Service"),
            "generator_program"
        )
        XCTAssertEqual(
            ServiceLibrary.serviceKey(forRoutineKind: RoutineKind.otherService.rawValue, label: "Elevator Service"),
            "elevator_program"
        )
        XCTAssertEqual(
            ServiceLibrary.serviceKey(forRoutineKind: RoutineKind.otherService.rawValue, label: "Family Office Rhythm"),
            "custom_routine_program"
        )
    }

    func test_customTaskInsertDefaultsToCustomSeasonalService() {
        let insert = MaintenanceTaskInsert(
            householdId: UUID(),
            title: "Follow up on masonry quote",
            frequency: "once",
            nextDueDate: "2026-05-01"
        )
        XCTAssertEqual(insert.resolvedServiceKey, "custom_seasonal_service")
    }

    func test_libraryContainsHandymanAndConciergeDefinitions() {
        XCTAssertEqual(
            ServiceLibrary.serviceDefinition(forKey: "handyman_program")?.serviceKind,
            .handymanProgram
        )
        XCTAssertEqual(
            ServiceLibrary.serviceDefinition(forKey: "concierge_tune_up")?.serviceKind,
            .conciergeAddOn
        )
        XCTAssertFalse(
            ServiceLibrary.serviceDefinition(forKey: "concierge_tune_up")?.homeownerVisibleByDefault ?? true
        )
    }

    @MainActor
    func test_wasteProgramExistsAndSeedsAsRecurringRoutine() {
        let definition = ServiceLibrary.serviceDefinition(forKey: "waste_program")
        XCTAssertEqual(definition?.serviceKind, .routineProgram)
        XCTAssertEqual(definition?.homeownerTitle, "Trash, Recycling & Organics Program")

        let defaults = RoutineSeeder.shared.defaults(for: "Trash & Recycling")
        XCTAssertEqual(defaults?.kind, .trash)
        XCTAssertEqual(defaults?.cadenceType, .weekly)
        XCTAssertEqual(defaults?.daysOfWeek, [4])
        XCTAssertEqual(defaults?.activeMonths, Array(1...12))
        XCTAssertEqual(defaults?.eveningBeforeReminder, true)
        XCTAssertTrue(RoutineKind.trash.supportsVendorLink)
    }

    @MainActor
    func test_providerTypesResolveToCanonicalRecurringPrograms() {
        XCTAssertEqual(
            RoutineSeeder.shared.defaults(forProviderType: "trash")?.serviceKey,
            "waste_program"
        )
        XCTAssertEqual(
            RoutineSeeder.shared.defaults(forProviderType: "security")?.serviceKey,
            "security_and_smart_home_program"
        )
        XCTAssertEqual(
            RoutineSeeder.shared.defaults(forProviderType: "irrigation")?.serviceKey,
            "irrigation_program"
        )
        XCTAssertEqual(
            RoutineSeeder.shared.defaults(for: "HVAC")?.serviceKey,
            "hvac_program"
        )
    }

    func test_routinePresentationLabelNormalizesPendingCopyWhenVendorIsAttached() {
        let routine = try? makeRoutineRow(
            label: "Pick a pro for mosquito and tick spraying",
            serviceKey: "mosquito_and_tick_program",
            routineKind: RoutineKind.mosquitoTick.rawValue,
            vendorId: UUID(),
            cadenceType: RoutineCadenceType.monthly.rawValue
        )

        XCTAssertEqual(routine?.presentationLabel, "Mosquito & Tick Program")
    }

    func test_landscapingRoutineForecastsUpcomingVisits() {
        let referenceDate = ISO8601DateFormatter().date(from: "2026-01-15T12:00:00Z") ?? Date()
        let routine = try? makeRoutineRow(
            label: "Landscaping Program",
            serviceKey: "landscaping_program",
            routineKind: RoutineKind.landscaping.rawValue,
            cadenceType: RoutineCadenceType.weekly.rawValue,
            daysOfWeek: [4],
            activeMonths: [4, 5, 6, 7, 8, 9, 10, 11],
            startDate: "2026-04-01",
            nextExpectedDate: "2026-04-01"
        )

        let previews = routine?.upcomingVisitPreviews(existingVisits: [], limit: 5, from: referenceDate) ?? []

        XCTAssertFalse(previews.isEmpty)
        XCTAssertTrue(previews.contains(where: { $0.visitTypeKey == "spring_cleanup" && $0.isProjected }))
        XCTAssertTrue(previews.contains(where: { $0.visitTypeKey == "routine_grounds" && $0.isProjected }))
    }

    private func makeRoutineRow(
        label: String,
        serviceKey: String?,
        routineKind: String,
        vendorId: UUID? = nil,
        cadenceType: String,
        daysOfWeek: [Int]? = nil,
        activeMonths: [Int] = Array(1...12),
        startDate: String = "2026-04-01",
        nextExpectedDate: String = "2026-04-01"
    ) throws -> RoutineRow {
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        let json: [String: Any] = [
            "id": UUID().uuidString,
            "household_id": UUID().uuidString,
            "property_id": UUID().uuidString,
            "label": label,
            "service_key": serviceKey ?? NSNull(),
            "source_utility_account_id": NSNull(),
            "routine_kind": routineKind,
            "icon": NSNull(),
            "notes": NSNull(),
            "vendor_id": vendorId?.uuidString ?? NSNull(),
            "system_id": NSNull(),
            "cadence_type": cadenceType,
            "cadence_interval_days": NSNull(),
            "days_of_week": daysOfWeek ?? NSNull(),
            "time_of_day": NSNull(),
            "start_date": startDate,
            "next_expected_date": nextExpectedDate,
            "last_confirmed_date": NSNull(),
            "last_assumed_date": NSNull(),
            "active_months": activeMonths,
            "evening_before_reminder": false,
            "morning_of_reminder": false,
            "estimated_cost_per_visit_cents": NSNull(),
            "cost_notes": NSNull(),
            "is_paused": false,
            "paused_at": NSNull(),
            "pause_reason": NSNull(),
            "auto_resume_date": NSNull(),
            "archived_at": NSNull(),
            "migrated_from_cadence_id": NSNull(),
            "migrated_from_standing_appointment_id": NSNull(),
            "cadence_source": "smart_setup",
            "confidence_score": NSNull(),
            "setup_state": "active",
            "service_contract_id": NSNull(),
            "scope": "property",
            "vehicle_id": NSNull(),
            "program_mode": NSNull(),
            "created_at": now,
            "updated_at": now
        ]

        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(RoutineRow.self, from: data)
    }
}

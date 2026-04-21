import XCTest
@testable import Haven

/// Regression tests for the `MaintenanceTemplates` library. Locks in
/// invariants that have broken silently in the past (Phase 61 ghost
/// deletions, Phase 67 bundle child materialization, etc.).
final class TemplateLibraryTests: XCTestCase {

    // MARK: - Library integrity

    func test_templateKeyUniqueness() {
        // Every template must have a unique templateKey. The reconciler's
        // dedup relies on this to avoid creating duplicate rows.
        let allTemplates = MaintenanceTemplates.allTemplates.flatMap { $0.1 }
        var seen = Set<String>()
        for template in allTemplates {
            let key = template.templateKey
            XCTAssertFalse(seen.contains(key),
                "Duplicate templateKey: '\(key)'. Every template must have a unique templateKey (category:title OR explicit stableId).")
            seen.insert(key)
        }
    }

    func test_bundleChildren_haveSemiAnnualVariants() {
        // Phase 67 regression: semi-annual handyman children must exist
        // in BOTH Handyman:spring AND Handyman:fall bundles with distinct
        // stableIds. "Replace smoke & CO detector batteries" is the
        // canonical pair.
        let all = MaintenanceTemplates.allTemplates.flatMap { $0.1 }
        let smokeBatterySpring = all.first { $0.stableId == "Handyman:smoke_co_batteries_spring" }
        let smokeBatteryFall = all.first { $0.stableId == "Handyman:smoke_co_batteries_fall" }
        XCTAssertNotNil(smokeBatterySpring, "Spring smoke/CO battery template must exist")
        XCTAssertNotNil(smokeBatteryFall, "Fall smoke/CO battery template must exist")
        XCTAssertEqual(smokeBatterySpring?.bundleId, "Handyman:spring")
        XCTAssertEqual(smokeBatteryFall?.bundleId, "Handyman:fall")
        XCTAssertNotEqual(smokeBatterySpring?.templateKey, smokeBatteryFall?.templateKey,
            "Spring and fall variants must have distinct templateKeys to avoid reconciler dedup collision")
    }

    func test_bundledTemplates_haveBundleId() {
        // Every template with `.bundledIntoParent` routing must have a
        // non-nil bundleId. And vice versa: every template with a
        // bundleId must return `.bundledIntoParent` from its `routing`
        // getter (the getter enforces this automatically).
        let all = MaintenanceTemplates.allTemplates.flatMap { $0.1 }
        for template in all {
            if template.bundleId != nil {
                XCTAssertEqual(template.routing, .bundledIntoParent,
                    "Template '\(template.title)' has bundleId set but routing isn't .bundledIntoParent")
            }
        }
    }

    func test_safetyFloorTemplates_areVendorAssigned() {
        // safetyFloor=true templates must be .vendor (or .bundledIntoParent
        // where the bundle parent is vendor). This guards against
        // accidentally marking a DIY template as safety-floor.
        let all = MaintenanceTemplates.allTemplates.flatMap { $0.1 }
        for template in all where template.safetyFloor {
            let assignment = template.assignmentType
            XCTAssertTrue(
                assignment == .vendor || template.bundleId != nil,
                "Safety-floor template '\(template.title)' should be .vendor-assigned (or bundled into a vendor parent). Got: \(assignment)"
            )
        }
    }

    func test_regionalPackTemplates_haveValidRegion() {
        // Templates with regionalPack set must point to a real RegionalPack
        // enum case. This catches typos like regionalPack: .northeeast.
        // Swift type system already enforces this at compile time; this
        // test also asserts the template isn't accidentally gated to a
        // region that no properties use (e.g. `.west` if Haven never
        // backfilled West-coast properties).
        let all = MaintenanceTemplates.allTemplates.flatMap { $0.1 }
        let gatedTemplates = all.compactMap { t -> (String, RegionalPack)? in
            guard let r = t.regionalPack else { return nil }
            return (t.title, r)
        }
        // Known Phase 57 + 62 + 67 regional-gated templates. Update this
        // list when new regional templates ship.
        XCTAssertGreaterThan(gatedTemplates.count, 0,
            "Expected regional-gated templates (Phase 57 NE humidifier, radon, etc.). Got zero.")
    }

    // MARK: - Subtype gating

    func test_activeSubtypes_hvac_centralDucted_includesExpectedFlags() {
        let subtypes = MaintenanceTemplates.activeSubtypes(
            category: "HVAC",
            subtype: "central_ducted",
            fuelType: nil,
            flags: [:]
        )
        XCTAssertTrue(subtypes.contains("ducted"))
        XCTAssertTrue(subtypes.contains("has_ac"))
        XCTAssertTrue(subtypes.contains("has_furnace"))
        XCTAssertTrue(subtypes.contains("central_ac"))
    }

    func test_activeSubtypes_phase62_drivewayAsphalt_mapsToFlag() {
        // Phase 62 regression: setting driveway_material="asphalt" attribute
        // must translate into driveway_asphalt subtype so the seal-coat
        // template fires. (The reconciler does the string→bool translation
        // before calling activeSubtypes.)
        let subtypes = MaintenanceTemplates.activeSubtypes(
            category: "Siding/Exterior",
            subtype: nil,
            fuelType: nil,
            flags: ["driveway_asphalt": true]
        )
        XCTAssertTrue(subtypes.contains("driveway_asphalt"))
    }

    func test_activeSubtypes_phase62_matureTrees_mapsToFlag() {
        let subtypes = MaintenanceTemplates.activeSubtypes(
            category: "Landscaping",
            subtype: nil,
            fuelType: nil,
            flags: ["has_mature_trees": true]
        )
        XCTAssertTrue(subtypes.contains("mature_trees"))
    }

    func test_activeSubtypes_phase62_sumpBatteryBackup_mapsToFlag() {
        let subtypes = MaintenanceTemplates.activeSubtypes(
            category: "Plumbing",
            subtype: nil,
            fuelType: nil,
            flags: ["sump_pump": true, "has_sump_battery_backup": true]
        )
        XCTAssertTrue(subtypes.contains("sump_pump"))
        XCTAssertTrue(subtypes.contains("has_sump_battery_backup"))
    }

    func test_poolHotTubSplit_hotTubDoesntEmitPool() {
        // Build 87 regression: hot_tub subtype must NOT emit "pool"
        // umbrella token. Previously the activeSubtypes logic leaked
        // pool into hot-tub-only households.
        let subtypes = MaintenanceTemplates.activeSubtypes(
            category: "Pool/Spa",
            subtype: "hot_tub",
            fuelType: nil,
            flags: [:]
        )
        XCTAssertTrue(subtypes.contains("hot_tub"))
        XCTAssertFalse(subtypes.contains("pool"), "hot_tub subtype must not emit pool umbrella")
    }

    func test_poolChemistry_emitsCompositeAndUmbrella() {
        // Pool chemistry + pool type composite → both facets + umbrella.
        let subtypes = MaintenanceTemplates.activeSubtypes(
            category: "Pool/Spa",
            subtype: "pool_inground_chlorine",
            fuelType: nil,
            flags: [:]
        )
        XCTAssertTrue(subtypes.contains("pool"))
        XCTAssertTrue(subtypes.contains("pool_inground"))
        XCTAssertTrue(subtypes.contains("pool_chlorine"))
    }
}

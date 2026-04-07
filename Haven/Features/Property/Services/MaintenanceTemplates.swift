import Foundation

struct MaintenanceTemplate: Identifiable {
    let id = UUID()
    let systemCategory: String
    let title: String
    let description: String
    let frequency: String
    let priority: String
    let estimatedCostRange: String
    let isDIY: Bool
    let seasonalTiming: String?
    let professionalRequired: Bool
    let notes: String?
    /// Tags that mark this template as requiring a specific subtype.
    /// e.g. ["lawn"] means only for natural lawns, ["ducted"] means only for ducted HVAC, ["tank"] for tank water heaters.
    var requiredSubtypes: Set<String> = []
    /// Whether this task is essential (created during setup) vs recommended (available to add later).
    var isEssential: Bool = true
    /// Keywords identifying which specific equipment this task applies to.
    /// When a child system matching these keywords is added, this task migrates from parent to child.
    var equipmentKeywords: [String] = []

    /// DateComponents interval for calculating next due date from frequency string.
    var interval: DateComponents {
        switch frequency.lowercased() {
        case "weekly":
            return DateComponents(weekOfYear: 1)
        case "monthly":
            return DateComponents(month: 1)
        case "every 2 months":
            return DateComponents(month: 2)
        case "quarterly":
            return DateComponents(month: 3)
        case "every 4 months":
            return DateComponents(month: 4)
        case "semi-annually", "twice yearly":
            return DateComponents(month: 6)
        case "annually", "annually (spring)", "annually (fall)":
            return DateComponents(year: 1)
        case "every 2 years":
            return DateComponents(year: 2)
        case "every 2-3 years":
            return DateComponents(year: 2)
        case "every 3 years":
            return DateComponents(year: 3)
        case "every 3-5 years":
            return DateComponents(year: 3)
        case "every 5 years":
            return DateComponents(year: 5)
        case "every 5-7 years":
            return DateComponents(year: 5)
        case "every 10 years":
            return DateComponents(year: 10)
        case "every 10-15 years":
            return DateComponents(year: 10)
        default:
            return DateComponents(year: 1) // Default to annual
        }
    }
}

// MARK: - Template Library

enum MaintenanceTemplates {

    /// Returns only essential templates for setup. Non-essential tasks are available to add later.
    static func essentialTemplates(for category: String, activeSubtypes: Set<String> = []) -> [MaintenanceTemplate] {
        templates(for: category, activeSubtypes: activeSubtypes).filter(\.isEssential)
    }

    /// Builds the set of active subtype tokens for a system, given its persisted subtype string,
    /// optional catalog fuel type, and any extra boolean flags from the onboarding wizard.
    /// Single source of truth shared by AddSystemView and EditSystemSheet.
    static func activeSubtypes(
        category: String,
        subtype: String?,
        fuelType: String? = nil,
        flags: [String: Bool] = [:]
    ) -> Set<String> {
        var s: Set<String> = []
        let sub = (subtype ?? "").lowercased()
        let cat = category.lowercased()

        switch cat {
        case "landscaping":
            if sub == "lawn" { s.insert("lawn") }
            // turf / xeriscape / none → no subtype-tagged templates apply
        case "hvac":
            // Phase 19b: HVAC subtypes are now driven by q3b_hvac_type which
            // captures the user's actual configuration directly. The new flags
            // (`central_ac`, `window_ac`, `boiler`, `mini_split`, `heat_pump`,
            // `geothermal`) let templates target a specific configuration
            // without overlapping with the older `ducted` / `has_ac` / `has_furnace`
            // flags that universal templates rely on.
            switch sub {
            case "central_ducted", "ducted":
                s.formUnion(["ducted", "has_ac", "has_furnace", "central_ac"])
            case "mini_split", "ductless_mini_split":
                s.formUnion(["has_ac", "has_furnace", "mini_split"])
            case "boiler_radiant":
                s.formUnion(["has_furnace", "boiler"])
            case "boiler_with_central_ac":
                s.formUnion(["has_furnace", "boiler", "has_ac", "central_ac", "ducted"])
            case "boiler_with_window_ac":
                s.formUnion(["has_furnace", "boiler", "has_ac", "window_ac"])
            case "window_units":
                s.formUnion(["has_ac", "window_ac"])
            case "heat_pump":
                s.formUnion(["has_ac", "has_furnace", "heat_pump"])
            case "geothermal":
                s.formUnion(["has_ac", "has_furnace", "geothermal"])
            case "not_sure":
                // Phase 19c: user picked "Not sure" in q3b. Assume the most
                // common US configuration (some form of heating + some form
                // of cooling) so universal tune-up templates land. Do NOT
                // add topology-specific flags like `ducted` / `mini_split` /
                // `boiler` / `window_ac` — those stay hidden until the user
                // confirms a real type from Property → Maintenance.
                s.formUnion(["has_ac", "has_furnace"])
            default:
                // Unknown / unset — wait for the House Quiz to confirm what
                // the user actually has. Assuming ducted HVAC up front meant
                // tankless / ducted tasks leaked into homes that don't have
                // them, breaking trust before the quiz could even run.
                break
            }
        case "water heater":
            if sub == "tank" || sub.isEmpty { s.insert("tank") }
            if sub == "tankless" { s.insert("tankless") }
            if sub == "hybrid_heat_pump" { s.insert("hybrid_heat_pump") }
            if sub == "solar" { s.insert("solar") }
        case "pool/spa", "pool":
            if sub == "saltwater" { s.insert("pool_salt") }
            if sub == "chlorine" || sub.isEmpty { s.insert("pool_chlorine") }
        case "roofing":
            switch sub {
            case "flat_membrane": s.insert("roof_flat")
            case "asphalt_shingle", "": s.insert("roof_asphalt")
            case "wood_shake": s.insert("roof_wood")
            default: break
            }
        case "plumbing":
            if flags["sump_pump"] == true { s.insert("sump_pump") }
        case "fire protection":
            if flags["fireplace"] == true { s.insert("fireplace") }
        case "appliance":
            if flags["garbage_disposal"] == true { s.insert("garbage_disposal") }
        default:
            break
        }

        // Catalog-driven hint: electric Water Heater fuel type often implies tankless when keyword present
        if cat == "water heater", let fuel = fuelType?.lowercased(), fuel.contains("electric"), sub.isEmpty {
            s.insert("tank")
        }
        return s
    }

    /// Returns templates matching a system category string (case-insensitive partial match).
    /// `activeSubtypes` is the set of subtypes the user's home has (e.g. ["lawn", "ducted", "tank", "sump_pump"]).
    /// Templates whose `requiredSubtypes` are not a subset of `activeSubtypes` are excluded.
    ///
    /// Pre-quiz (empty activeSubtypes): only universal templates pass. This
    /// prevents subtype-specific tasks like "Descale tankless heater" or
    /// "Inspect ductwork for leaks" from showing up before the user confirms
    /// what they actually have in the House Quiz.
    static func templates(for category: String, activeSubtypes: Set<String> = []) -> [MaintenanceTemplate] {
        let lower = category.lowercased()
        let matched = allTemplates.first { sectionName, _ in
            sectionName.lowercased() == lower
            || lower.contains(sectionName.lowercased())
            || sectionName.lowercased().contains(lower)
        }?.1 ?? []
        return matched.filter { template in
            template.requiredSubtypes.isEmpty || template.requiredSubtypes.isSubset(of: activeSubtypes)
        }
    }

    /// Returns ALL templates for a category, regardless of `requiredSubtypes`.
    /// Used by `MaintenanceTaskReconciler` to recognise template-managed tasks
    /// (so legacy "Descale tankless heater" rows can be matched and pruned even
    /// when their subtype doesn't apply anymore). Do NOT use this for the
    /// initial setup task list — that path must respect `activeSubtypes`.
    static func allTemplates(forCategory category: String) -> [MaintenanceTemplate] {
        let lower = category.lowercased()
        return allTemplates.first { sectionName, _ in
            sectionName.lowercased() == lower
            || lower.contains(sectionName.lowercased())
            || sectionName.lowercased().contains(lower)
        }?.1 ?? []
    }

    /// Lowercased titles of every template Haven knows about for a category.
    /// Used by the reconciler as a quick "is this a template-managed title?"
    /// check before considering a task for soft-deletion.
    static func knownTemplateTitles(forCategory category: String) -> Set<String> {
        Set(allTemplates(forCategory: category).map { $0.title.lowercased() })
    }

    // MARK: - Master Template Database

    static let allTemplates: [(String, [MaintenanceTemplate])] = [

        // ──────────────────────────────────────────────
        // ROOF & EXTERIOR
        // ──────────────────────────────────────────────
        ("Roofing", [
            MaintenanceTemplate(systemCategory: "Roofing", title: "Professional roof inspection", description: "Hire a roofing professional to inspect for damage, wear, and potential leaks.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Check for damaged shingles", description: "Visual ground-level inspection for missing, curled, or cracked shingles.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Also check after major storms", requiredSubtypes: ["roof_asphalt"]),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Reseal flashing and seams", description: "Inspect and reseal flashing, seams, and penetrations on flat/membrane roof.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: false, notes: "Critical on flat roofs to prevent ponding leaks", requiredSubtypes: ["roof_flat"]),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Treat moss and algae", description: "Apply moss/algae treatment to prevent shingle damage and discoloration.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$50–$200", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, requiredSubtypes: ["roof_wood"], isEssential: false),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Clean gutters and downspouts", description: "Remove debris from gutters and ensure downspouts drain away from foundation.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Spring and fall"),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Inspect flashing around chimney/vents", description: "Check flashing around chimneys, vents, and skylights for gaps or deterioration.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, isEssential: false),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Check attic for leaks after heavy rain", description: "Inspect attic for water stains, mold, or daylight coming through roof.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Check after any major storm", isEssential: false),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Trim tree branches away from roof", description: "Cut back branches within 10 feet of the roof to prevent damage.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$200–$600", isDIY: false, seasonalTiming: "Fall", professionalRequired: false, notes: "May need arborist for large trees", isEssential: false),
        ]),

        // ──────────────────────────────────────────────
        // SIDING / EXTERIOR
        // ──────────────────────────────────────────────
        ("Siding/Exterior", [
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Power wash exterior siding", description: "Clean siding to remove dirt, mildew, and algae buildup.", frequency: "Annually", priority: "Low", estimatedCostRange: "$200–$400", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Inspect/repair caulking around windows and doors", description: "Check exterior caulking for cracks or gaps and re-caulk as needed.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$50 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Critical for energy efficiency", isEssential: false),
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Check and repair deck/patio", description: "Inspect deck boards, railings, and stairs for rot, loose fasteners, or damage.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$200", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Seal or stain every 2-3 years", isEssential: false),
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Inspect/repair driveway cracks", description: "Fill cracks in concrete or asphalt driveway to prevent water infiltration.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0–$100 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Seal coat asphalt every 2-3 years", isEssential: false),
        ]),

        // ──────────────────────────────────────────────
        // HVAC
        // ──────────────────────────────────────────────
        ("HVAC", [
            MaintenanceTemplate(systemCategory: "HVAC", title: "Replace air filters", description: "Replace or clean HVAC air filters for optimal airflow and indoor air quality.", frequency: "Monthly", priority: "High", estimatedCostRange: "$10–$40", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Every 1-3 months depending on filter type"),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Professional HVAC tune-up (cooling)", description: "Professional inspection and service of air conditioning system before summer.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Schedule before summer heat", requiredSubtypes: ["has_ac"]),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Professional HVAC tune-up (heating)", description: "Professional inspection and service of heating system before winter.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Schedule before cold weather", requiredSubtypes: ["has_furnace"]),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Clean air vents and returns", description: "Remove vent covers and vacuum dust from supply and return vents.", frequency: "Quarterly", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Check thermostat calibration", description: "Verify thermostat reads accurate temperature and programs are correct.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Inspect ductwork for leaks", description: "Professional inspection of ductwork for air leaks that reduce efficiency.", frequency: "Every 2-3 years", priority: "Medium", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, requiredSubtypes: ["ducted"], isEssential: false),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Clean condensate drain line", description: "Flush AC condensate drain with vinegar to prevent clogs and water damage.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Especially important in humid climates", requiredSubtypes: ["has_ac"], isEssential: false),
            // Phase 19b: subtype-specific templates for the new q3b HVAC types.
            MaintenanceTemplate(systemCategory: "HVAC", title: "Clean mini-split indoor unit filters", description: "Pop the filters out of each indoor head and rinse with warm water. Skip dust buildup or you'll lose 20% of cooling efficiency.", frequency: "Every 2 months", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, requiredSubtypes: ["mini_split"]),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Inspect mini-split outdoor unit", description: "Clear leaves and debris from the condenser, check for refrigerant line damage, hose down the coil.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, requiredSubtypes: ["mini_split"]),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Clean window AC filters", description: "Remove the front grille and slide the filter out. Vacuum dust, then rinse and air dry. Reinstall.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Summer", professionalRequired: false, notes: "Monthly during cooling season", requiredSubtypes: ["window_ac"]),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Store window AC units for winter", description: "Pull units out of windows, clean coils, store covered. Or if leaving in place, install an exterior cover to prevent cold drafts.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, requiredSubtypes: ["window_ac"]),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Bleed radiators", description: "Open the bleed valve on each radiator to release trapped air. Catch the drip with a small towel. Boiler performance drops if any radiator has air in it.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, requiredSubtypes: ["boiler"]),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Annual boiler service", description: "Combustion check, clean burners, inspect heat exchanger, check pressure relief valve, verify exhaust draft.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Required for warranty on most boilers", requiredSubtypes: ["boiler"]),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Heat pump defrost cycle check", description: "In cold weather, listen for the defrost cycle (about every 30-90 min when icy). If you don't hear it cycling, schedule service before the coil freezes solid.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Winter", professionalRequired: false, notes: nil, requiredSubtypes: ["heat_pump"]),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Geothermal loop pressure check", description: "Have your installer verify the ground loop pressure and antifreeze concentration. A drop of more than 5 PSI/year indicates a leak.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, requiredSubtypes: ["geothermal"]),
        ]),

        // ──────────────────────────────────────────────
        // PLUMBING
        // ──────────────────────────────────────────────
        ("Plumbing", [
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Check for leaks under sinks", description: "Inspect under all sinks for drips, moisture, or water damage.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Test water pressure", description: "Use a gauge to test water pressure; ideal is 40-60 PSI.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "High pressure can damage fixtures", isEssential: false),
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Check toilets for running/leaks", description: "Listen for running toilets and check around base for moisture.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "A running toilet can waste 200+ gallons/day"),
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Clean faucet aerators", description: "Remove and soak aerators in vinegar to clear mineral buildup.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false),
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Inspect washing machine supply hoses", description: "Check hoses for bulges, cracks, or kinks. Replace every 5 years.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Burst hoses are a top insurance claim", equipmentKeywords: ["washing machine", "clothes washer", "washtower", "laundry"]),
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Test sump pump", description: "Pour water into sump pit to verify pump activates and drains properly.", frequency: "Quarterly", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Critical before spring rains", requiredSubtypes: ["sump_pump"], isEssential: false, equipmentKeywords: ["sump pump", "sump"]),
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Professional drain cleaning", description: "Professional clearing of main drains to prevent backups.", frequency: "Every 2 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil),
        ]),

        // ──────────────────────────────────────────────
        // WATER HEATER
        // ──────────────────────────────────────────────
        ("Water Heater", [
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Flush water heater", description: "Drain and flush sediment from the tank to maintain heating efficiency.", frequency: "Annually", priority: "High", estimatedCostRange: "$0–$200", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "DIY possible but professional recommended for older units", requiredSubtypes: ["tank"], equipmentKeywords: ["water heater"]),
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Inspect anode rod", description: "Check and replace sacrificial anode rod to prevent tank corrosion.", frequency: "Every 3 years", priority: "Medium", estimatedCostRange: "$20–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Replace if more than 50% depleted", requiredSubtypes: ["tank"], isEssential: false, equipmentKeywords: ["water heater"]),
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Test T&P relief valve", description: "Test temperature and pressure relief valve for proper operation.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Safety critical — valve should release water when lifted", equipmentKeywords: ["water heater"]),
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Descale tankless heater", description: "Flush vinegar/descaler through the tankless unit to remove mineral buildup.", frequency: "Annually", priority: "High", estimatedCostRange: "$0–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Hard water areas may need every 6 months", requiredSubtypes: ["tankless"], equipmentKeywords: ["water heater"]),
        ]),

        // ──────────────────────────────────────────────
        // SEPTIC SYSTEM
        // ──────────────────────────────────────────────
        ("Septic System", [
            MaintenanceTemplate(systemCategory: "Septic System", title: "Septic tank pumping", description: "Professional pumping of septic tank to remove accumulated solids.", frequency: "Every 3-5 years", priority: "High", estimatedCostRange: "$300–$600", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Frequency depends on household size and tank size"),
            MaintenanceTemplate(systemCategory: "Septic System", title: "Inspect septic baffles", description: "Have baffles inspected during pumping to ensure they're intact.", frequency: "Every 3-5 years", priority: "Medium", estimatedCostRange: "Included with pumping", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Done during pumping"),
            MaintenanceTemplate(systemCategory: "Septic System", title: "Check drain field for wet spots", description: "Walk the drain field looking for soggy areas, odors, or unusually green grass.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Wet spots may indicate system failure"),
        ]),

        // ──────────────────────────────────────────────
        // WELL SYSTEM
        // ──────────────────────────────────────────────
        ("Well System", [
            MaintenanceTemplate(systemCategory: "Well System", title: "Test water quality", description: "Lab test for bacteria, nitrates, pH, and other contaminants.", frequency: "Annually", priority: "High", estimatedCostRange: "$50–$200", isDIY: false, seasonalTiming: "Spring", professionalRequired: false, notes: "Test more frequently if you notice taste/odor changes"),
            MaintenanceTemplate(systemCategory: "Well System", title: "Inspect well cap and casing", description: "Check well cap is secure and casing is intact above ground.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Well System", title: "Check pressure tank", description: "Verify pressure tank air charge and check for waterlogging.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, equipmentKeywords: ["pressure tank", "well tank"]),
            MaintenanceTemplate(systemCategory: "Well System", title: "Professional well inspection", description: "Comprehensive inspection of well pump, casing, and water flow.", frequency: "Every 3-5 years", priority: "High", estimatedCostRange: "$300–$500", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil),
        ]),

        // ──────────────────────────────────────────────
        // ELECTRICAL
        // ──────────────────────────────────────────────
        ("Electrical", [
            MaintenanceTemplate(systemCategory: "Electrical", title: "Test GFCI outlets", description: "Press test/reset buttons on all GFCI outlets to verify protection. Modern GFCI outlets have self-test features, but an annual manual check is good practice.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Modern GFCI outlets self-test — this is your annual manual confirmation", isEssential: false),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Verify smoke detectors", description: "Press test button on each smoke detector to confirm it's working. Most modern detectors self-test, but an annual manual check ensures nothing has been disconnected or failed silently.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Modern detectors self-test — this is your annual manual confirmation"),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Replace smoke detector batteries", description: "Replace batteries in all smoke detectors. Test after replacing.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$10–$20 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Change at daylight saving time"),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Replace smoke detectors", description: "Smoke detectors expire after 10 years. Check manufacture date and replace.", frequency: "Every 10 years", priority: "High", estimatedCostRange: "$15–$40 each", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Verify carbon monoxide detectors", description: "Press test button on each CO detector to confirm it's working. Most modern units self-test, but an annual manual check ensures nothing has failed.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Modern detectors self-test — this is your annual manual confirmation"),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Inspect electrical panel", description: "Professional inspection of main breaker panel for wear or overheating.", frequency: "Every 3 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, isEssential: false),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Check outdoor lighting", description: "Test all exterior and security lights, replace burned-out bulbs.", frequency: "Quarterly", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false),
        ]),

        // ──────────────────────────────────────────────
        // FIRE PROTECTION (Smoke/CO — also used for fireplace)
        // ──────────────────────────────────────────────
        ("Fire Protection", [
            MaintenanceTemplate(systemCategory: "Fire Protection", title: "Verify smoke detectors", description: "Press test button on each smoke detector to confirm it's working. Most modern detectors self-test, but an annual manual check ensures nothing has been disconnected or failed silently.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Modern detectors self-test — this is your annual manual confirmation"),
            MaintenanceTemplate(systemCategory: "Fire Protection", title: "Replace smoke detector batteries", description: "Replace batteries in all smoke and CO detectors.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$10–$20 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Change at daylight saving time"),
            MaintenanceTemplate(systemCategory: "Fire Protection", title: "Check fire extinguishers", description: "Verify gauge is in green zone, check expiration date, ensure accessible.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Professional recharge every 6 years"),
            MaintenanceTemplate(systemCategory: "Fire Protection", title: "Professional chimney sweep", description: "Professional cleaning and inspection of chimney and flue.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Before first use each season", requiredSubtypes: ["fireplace"], isEssential: false, equipmentKeywords: ["chimney", "fireplace"]),
            MaintenanceTemplate(systemCategory: "Fire Protection", title: "Inspect firebox and damper", description: "Check firebox for cracks and verify damper opens/closes properly.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Before first use each season", requiredSubtypes: ["fireplace"], isEssential: false, equipmentKeywords: ["chimney", "fireplace"]),
        ]),

        // ──────────────────────────────────────────────
        // WINDOWS & DOORS
        // ──────────────────────────────────────────────
        ("Windows", [
            MaintenanceTemplate(systemCategory: "Windows", title: "Inspect weatherstripping", description: "Check weatherstripping on all windows for wear, gaps, or damage.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Replace worn strips for $20–$50"),
            MaintenanceTemplate(systemCategory: "Windows", title: "Check window locks and operation", description: "Test all window locks, hinges, and opening mechanisms.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false),
            MaintenanceTemplate(systemCategory: "Windows", title: "Clean window tracks and weep holes", description: "Vacuum tracks and clear weep holes to ensure proper drainage.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false),
            MaintenanceTemplate(systemCategory: "Windows", title: "Re-caulk exterior windows", description: "Remove old caulk and apply fresh exterior-grade caulk around windows.", frequency: "Every 2-3 years", priority: "Medium", estimatedCostRange: "$0–$50 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, isEssential: false),
        ]),

        ("Doors", [
            MaintenanceTemplate(systemCategory: "Doors", title: "Lubricate door hinges and locks", description: "Apply lubricant to all door hinges, locks, and deadbolts.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false),
            MaintenanceTemplate(systemCategory: "Doors", title: "Inspect weatherstripping on exterior doors", description: "Check door sweeps and weatherstripping for gaps that allow drafts.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Doors", title: "Check door alignment and operation", description: "Verify doors open, close, and latch properly. Adjust hinges if needed.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false),
        ]),

        // ──────────────────────────────────────────────
        // GARAGE DOOR
        // ──────────────────────────────────────────────
        ("Garage Door", [
            MaintenanceTemplate(systemCategory: "Garage Door", title: "Test garage door auto-reverse", description: "Place an object in the door path to verify the auto-reverse safety feature works. Modern openers have sensors that handle this automatically, but an annual manual test confirms everything is aligned and responsive.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Modern openers self-monitor — this is your annual safety confirmation"),
            MaintenanceTemplate(systemCategory: "Garage Door", title: "Lubricate garage door tracks and hardware", description: "Apply garage door lubricant to tracks, rollers, hinges, and springs.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Do NOT lubricate with WD-40; use silicone spray"),
            MaintenanceTemplate(systemCategory: "Garage Door", title: "Professional garage door tune-up", description: "Professional inspection of springs, cables, rollers, and opener.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Never attempt spring repair yourself"),
        ]),

        // ──────────────────────────────────────────────
        // LANDSCAPING
        // ──────────────────────────────────────────────
        ("Landscaping", [
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Fertilize lawn", description: "Apply seasonal fertilizer appropriate for grass type and season.", frequency: "Quarterly", priority: "Low", estimatedCostRange: "$50–$150", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Spring, early summer, fall applications", requiredSubtypes: ["lawn"]),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Aerate lawn", description: "Core aeration to reduce soil compaction and improve root growth.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$100–$200", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, requiredSubtypes: ["lawn"], isEssential: false),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Mulch garden beds", description: "Add 2-3 inches of fresh mulch to garden beds to retain moisture and suppress weeds.", frequency: "Annually", priority: "Low", estimatedCostRange: "$200–$500", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, isEssential: false),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Prune shrubs and hedges", description: "Trim overgrown shrubs and hedges for health and appearance.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$0–$200", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Spring and fall"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Grade check — drainage away from foundation", description: "Ensure soil slopes away from foundation to prevent water intrusion.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Critical for foundation health"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Inspect retaining walls", description: "Check retaining walls for leaning, bulging, or cracking.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, isEssential: false),
        ]),

        // ──────────────────────────────────────────────
        // IRRIGATION
        // ──────────────────────────────────────────────
        ("Irrigation", [
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Winterize irrigation system", description: "Professional blow-out of irrigation lines to prevent freeze damage.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Must be done before first freeze"),
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Spring startup irrigation", description: "Gradually pressurize system, check for leaks, and adjust heads.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Check irrigation heads and adjust", description: "Walk each zone checking for broken, clogged, or misaligned heads.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "During irrigation season only"),
        ]),

        // ──────────────────────────────────────────────
        // POOL / SPA
        // ──────────────────────────────────────────────
        ("Pool/Spa", [
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Test and balance water chemistry", description: "Test and adjust pH, chlorine, alkalinity, and calcium hardness.", frequency: "Weekly", priority: "High", estimatedCostRange: "$20–$50/month", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "During swimming season"),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Clean pool filter", description: "Backwash or clean pool filter cartridge to maintain proper filtration.", frequency: "Monthly", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "During swimming season"),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Professional pool opening", description: "Remove cover, start up equipment, balance chemicals, and inspect.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Professional pool closing/winterization", description: "Chemical treatment, lower water level, blow out lines, install cover.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Inspect pool equipment", description: "Check pump, heater, filter, and automation for proper operation.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$100", isDIY: false, seasonalTiming: "Spring", professionalRequired: false, notes: "During opening"),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Clean salt cell", description: "Inspect and clean the salt chlorine generator cell to maintain output.", frequency: "Quarterly", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Soak in muriatic acid solution if calcified", requiredSubtypes: ["pool_salt"]),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Shock pool", description: "Super-chlorinate to eliminate chloramines and algae growth.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$15–$40", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "More frequently after heavy use or storms", requiredSubtypes: ["pool_chlorine"]),
        ]),

        // ──────────────────────────────────────────────
        // APPLIANCES
        // ──────────────────────────────────────────────
        ("Appliance", [
            MaintenanceTemplate(systemCategory: "Appliance", title: "Clean dishwasher filter and spray arms", description: "Remove and clean dishwasher filter and check spray arms for clogs.", frequency: "Monthly", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["dishwasher"]),
            MaintenanceTemplate(systemCategory: "Appliance", title: "Clean washing machine", description: "Run cleaning cycle with machine cleaner or vinegar to prevent mold and odor.", frequency: "Monthly", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["washing machine", "clothes washer", "washtower", "laundry"]),
            MaintenanceTemplate(systemCategory: "Appliance", title: "Deep clean dryer vent duct", description: "Professional cleaning of full dryer vent duct to prevent fire hazard.", frequency: "Annually", priority: "High", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Lint buildup is a top cause of house fires", equipmentKeywords: ["dryer", "clothes dryer", "washtower"]),
            MaintenanceTemplate(systemCategory: "Appliance", title: "Clean range hood filter", description: "Remove and clean/replace range hood grease filter.", frequency: "Quarterly", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["range hood", "vent hood", "cooktop", "stove", "induction cooktop"]),
            MaintenanceTemplate(systemCategory: "Appliance", title: "Clean refrigerator coils", description: "Vacuum dust from condenser coils behind or under the refrigerator.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Improves efficiency and extends life", equipmentKeywords: ["refrigerator", "fridge"]),
            MaintenanceTemplate(systemCategory: "Appliance", title: "Inspect refrigerator door seals", description: "Check door gaskets for cracks or gaps. Clean with mild soap.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Dollar bill test: close door on bill, should hold tight", isEssential: false, equipmentKeywords: ["refrigerator", "fridge"]),
            MaintenanceTemplate(systemCategory: "Appliance", title: "Check and clean garbage disposal", description: "Clean disposal with ice cubes and lemon, check for leaks underneath.", frequency: "Monthly", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, requiredSubtypes: ["garbage_disposal"], isEssential: false, equipmentKeywords: ["garbage disposal", "disposal"]),
        ]),

        // ──────────────────────────────────────────────
        // PEST CONTROL
        // ──────────────────────────────────────────────
        ("Pest Control", [
            MaintenanceTemplate(systemCategory: "Pest Control", title: "Inspect foundation for entry points", description: "Walk perimeter checking for gaps, cracks, or holes where pests can enter.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Spring and fall", isEssential: false),
            MaintenanceTemplate(systemCategory: "Pest Control", title: "Professional termite inspection", description: "Annual professional inspection for termite and wood-destroying insect activity.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Required for many home warranties"),
            MaintenanceTemplate(systemCategory: "Pest Control", title: "Seal gaps around pipes and utility entries", description: "Use caulk or steel wool to seal gaps around pipes, wires, and vents.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$20 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, isEssential: false),
            MaintenanceTemplate(systemCategory: "Pest Control", title: "Professional pest treatment", description: "Quarterly or as-needed professional pest control treatment.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$100–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil),
        ]),

        // ──────────────────────────────────────────────
        // GENERATOR
        // ──────────────────────────────────────────────
        ("Generator", [
            MaintenanceTemplate(systemCategory: "Generator", title: "Verify generator test cycle", description: "Confirm your generator is running its automatic weekly exercise cycle. Most standby generators auto-exercise — just verify it ran by checking the hour meter or app.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Most standby generators auto-exercise weekly — this is your periodic check that it's working"),
            MaintenanceTemplate(systemCategory: "Generator", title: "Check generator oil level", description: "Verify oil level is within the proper range on dipstick.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Check more frequently during heavy use"),
            MaintenanceTemplate(systemCategory: "Generator", title: "Change generator oil", description: "Drain and replace oil per manufacturer schedule.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$20–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Every 200 hours or annually"),
            MaintenanceTemplate(systemCategory: "Generator", title: "Replace spark plugs", description: "Replace spark plugs per manufacturer recommendations.", frequency: "Annually", priority: "Low", estimatedCostRange: "$10–$30 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Generator", title: "Professional generator service", description: "Full professional service including all fluids, filters, and electrical check.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Before winter storm season"),
            MaintenanceTemplate(systemCategory: "Generator", title: "Test automatic transfer switch", description: "Professional test of transfer switch operation.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil),
        ]),

        // ──────────────────────────────────────────────
        // SECURITY SYSTEM
        // ──────────────────────────────────────────────
        ("Security System", [
            MaintenanceTemplate(systemCategory: "Security System", title: "Verify alarm system", description: "Walk-test each sensor to confirm it registers with the panel. Monitoring services like ADT run regular automated checks, but an annual manual walk-test catches sensors that may have shifted or lost signal.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Monitored systems self-test — this is your annual manual confirmation"),
            MaintenanceTemplate(systemCategory: "Security System", title: "Replace sensor batteries", description: "Replace batteries in door/window sensors and motion detectors.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$20–$50 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Security System", title: "Clean camera lenses", description: "Wipe camera lenses clean and verify camera angles and recording.", frequency: "Quarterly", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Security System", title: "Update alarm codes", description: "Change alarm codes and review authorized user list.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Also change when personnel changes"),
        ]),

        // ──────────────────────────────────────────────
        // SOLAR PANELS
        // ──────────────────────────────────────────────
        ("Solar", [
            MaintenanceTemplate(systemCategory: "Solar", title: "Visual inspection from ground", description: "Look for debris, damage, bird nests, or shading issues on panels.", frequency: "Quarterly", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Solar", title: "Professional panel cleaning", description: "Professional cleaning to remove dirt, pollen, and bird droppings.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: "Can significantly improve output"),
            MaintenanceTemplate(systemCategory: "Solar", title: "Monitor output for performance drop", description: "Check inverter app or meter for unexpected drops in power production.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Solar", title: "Professional inspection", description: "Comprehensive inspection of panels, wiring, inverter, and mounting.", frequency: "Every 3-5 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil),
            MaintenanceTemplate(systemCategory: "Solar", title: "Check inverter operation", description: "Verify inverter shows green/normal status and no error codes.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
        ]),

        // ──────────────────────────────────────────────
        // CRAWL SPACE / BASEMENT
        // ──────────────────────────────────────────────
        ("Crawl Space", [
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Inspect for moisture or water intrusion", description: "Check for standing water, damp walls, or moisture on surfaces.", frequency: "Quarterly", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Check vapor barrier condition", description: "Inspect plastic vapor barrier for tears, displacement, or gaps.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Inspect for mold or mildew", description: "Visual inspection for mold growth on joists, insulation, and walls.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Professional remediation if found"),
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Check foundation for cracks", description: "Inspect foundation walls for new or expanding cracks.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Mark and monitor cracks over time"),
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Test dehumidifier operation", description: "Verify dehumidifier is working and draining properly.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil),
        ]),

        // ──────────────────────────────────────────────
        // WATER TREATMENT
        // ──────────────────────────────────────────────
        ("Water Treatment", [
            MaintenanceTemplate(systemCategory: "Water Treatment", title: "Replace water softener salt", description: "Check and refill salt in water softener brine tank.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$10–$20 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Water Treatment", title: "Clean water softener brine tank", description: "Drain, clean, and refill the brine tank to prevent salt bridging.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil),
            MaintenanceTemplate(systemCategory: "Water Treatment", title: "Replace whole-house water filter", description: "Replace filter cartridge per manufacturer schedule.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$20–$80 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Frequency varies by filter type and water quality"),
            MaintenanceTemplate(systemCategory: "Water Treatment", title: "Test water after filter replacement", description: "Test water quality to verify filter is working properly.", frequency: "Annually", priority: "Low", estimatedCostRange: "$50–$100", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil),
        ]),
    ]

    /// All system categories that have templates available.
    static var availableCategories: [String] {
        allTemplates.map(\.0)
    }

    /// Total count of all maintenance templates across all categories.
    static var totalTemplateCount: Int {
        allTemplates.reduce(0) { $0 + $1.1.count }
    }

    // MARK: - One-Time Task Migration

    /// V3: Moves equipment-specific tasks to correct systems, removes misassigned general tasks.
    /// Matches by templateId OR title. Handles category-based siblings (not just parent-child).
    @MainActor
    static func migrateExistingTaskAssignments() async {
        let migrationKey = "hasRunTaskMigrationV4"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let db = DatabaseService.shared
        let taggedTemplates = allTemplates.flatMap(\.1).filter { !$0.equipmentKeywords.isEmpty }
        let allTemplatesList = allTemplates.flatMap(\.1)

        /// Word-boundary match: "washer" must NOT match "dishwasher"
        func nameContainsKeyword(_ name: String, _ keyword: String) -> Bool {
            let lower = name.lowercased()
            let kw = keyword.lowercased()
            if lower == kw { return true }
            if kw.contains(" ") { return lower.contains(kw) }
            return lower.components(separatedBy: CharacterSet.alphanumerics.inverted).contains(kw)
        }

        let categoryParentNames: Set<String> = [
            "kitchen & laundry appliances", "plumbing system", "central hvac",
            "electrical system", "well system", "smoke & fire protection",
            "crawl space / basement"
        ]

        func findTaggedTemplate(for task: MaintenanceTaskDBRow) -> MaintenanceTemplate? {
            if let tid = task.templateId,
               let m = taggedTemplates.first(where: { ($0.systemCategory + ":" + $0.title) == tid }) { return m }
            return taggedTemplates.first { $0.title.lowercased() == task.title.lowercased() }
        }

        func templateCategory(for title: String) -> String? {
            allTemplatesList.first { $0.title.lowercased() == title.lowercased() }?.systemCategory
        }

        let parentMap: [String: String] = [
            "Plumbing": "plumbing system",
            "Appliance": "kitchen & laundry appliances",
            "HVAC": "central hvac",
            "Electrical": "electrical system",
            "Water Heater": "water heater",
            "Well System": "well system",
            "Fire Protection": "smoke & fire protection",
        ]

        do {
            let properties = try await db.fetchProperties()

            for property in properties {
                let systems = try await db.fetchHomeSystems(propertyId: property.id)
                let allTasks = try await db.fetchMaintenanceTasks(propertyId: property.id)

                // PHASE 1: Move equipment-specific tasks from category parents to matching systems
                for system in systems where categoryParentNames.contains(system.name.lowercased()) {
                    let parentTasks = allTasks.filter { $0.systemId == system.id }
                    let candidates = systems.filter { $0.id != system.id }

                    for task in parentTasks {
                        guard let template = findTaggedTemplate(for: task) else { continue }
                        if let match = candidates.first(where: { c in
                            let lower = c.name.lowercased()
                            let catLower = c.category.lowercased()
                            return template.equipmentKeywords.contains { kw in
                                nameContainsKeyword(lower, kw) || nameContainsKeyword(catLower, kw)
                            }
                        }) {
                            _ = try? await db.updateMaintenanceTask(id: task.id, MaintenanceTaskUpdate(systemId: match.id))
                        }
                    }
                }

                // PHASE 2: Remove wrong tasks from specific equipment
                let specificKeywords = ["sump", "dishwasher", "refrigerator", "fridge", "washer",
                                         "dryer", "cooktop", "range", "stove", "water heater", "furnace"]

                for system in systems {
                    let nameLower = system.name.lowercased()
                    guard specificKeywords.contains(where: { nameLower.contains($0) }) else { continue }
                    guard !categoryParentNames.contains(nameLower) else { continue }

                    let systemTasks = allTasks.filter { $0.systemId == system.id }

                    for task in systemTasks {
                        // Tagged template for DIFFERENT equipment?
                        if let template = findTaggedTemplate(for: task) {
                            let belongsHere = template.equipmentKeywords.contains { nameContainsKeyword(nameLower, $0) }
                            if !belongsHere {
                                let correct = systems.first { c in
                                    template.equipmentKeywords.contains { nameContainsKeyword(c.name.lowercased(), $0) }
                                }
                                if let correct {
                                    _ = try? await db.updateMaintenanceTask(id: task.id, MaintenanceTaskUpdate(systemId: correct.id))
                                } else if let cat = templateCategory(for: task.title),
                                          let parentName = parentMap[cat],
                                          let parent = systems.first(where: { $0.name.lowercased() == parentName }) {
                                    _ = try? await db.updateMaintenanceTask(id: task.id, MaintenanceTaskUpdate(systemId: parent.id))
                                }
                                continue
                            }
                        }

                        // Untagged general task on specific equipment — move to category parent
                        if findTaggedTemplate(for: task) == nil,
                           let cat = templateCategory(for: task.title),
                           let parentName = parentMap[cat],
                           let parent = systems.first(where: { $0.name.lowercased() == parentName }),
                           parent.id != system.id {
                            _ = try? await db.updateMaintenanceTask(id: task.id, MaintenanceTaskUpdate(systemId: parent.id))
                        }
                    }
                }
            }

            // PHASE 3: Rename systems with brand strings to functional names
            let functionalNames: [(keywords: [String], cleanName: String)] = [
                (["induction cooktop"], "Induction Cooktop"),
                (["gas cooktop"], "Gas Cooktop"),
                (["electric cooktop"], "Electric Cooktop"),
                (["cooktop"], "Cooktop"),
                (["french door refrigerator", "side-by-side refrigerator"], "Refrigerator"),
                (["refrigerator", "fridge"], "Refrigerator"),
                (["dishwasher"], "Dishwasher"),
                (["front load washer", "top load washer", "washing machine"], "Washing Machine"),
                (["washer"], "Washing Machine"),
                (["dryer"], "Dryer"),
                (["range hood", "hood"], "Range Hood"),
                (["gas range", "electric range"], "Range"),
                (["range", "stove"], "Range"),
                (["wall oven", "double oven"], "Wall Oven"),
                (["oven"], "Oven"),
                (["microwave"], "Microwave"),
                (["freezer"], "Freezer"),
                (["garbage disposal", "disposal"], "Garbage Disposal"),
                (["sump pump"], "Sump Pump"),
                (["well pump"], "Well Pump"),
                (["pressure tank", "well tank"], "Pressure Tank"),
                (["water softener", "softener"], "Water Softener"),
                (["acid neutralizer", "neutralizer"], "Acid Neutralizer"),
            ]

            for property in properties {
                let systems = try await db.fetchHomeSystems(propertyId: property.id)
                for system in systems {
                    guard let mfr = system.manufacturer, !mfr.isEmpty else { continue }
                    let nameLower = system.name.lowercased()
                    guard nameLower.contains(mfr.lowercased()) else { continue }

                    if let match = functionalNames.first(where: { entry in
                        entry.keywords.contains(where: { nameLower.contains($0) })
                    }), match.cleanName != system.name {
                        _ = try? await db.updateHomeSystem(id: system.id, HomeSystemUpdate(name: match.cleanName))
                    }
                }
            }

            // PHASE 4: Deduplicate tasks — keep one per (systemId, title)
            for property in properties {
                let current = try await db.fetchMaintenanceTasks(propertyId: property.id)
                var seen: Set<String> = []
                for task in current.sorted(by: { ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast) }) {
                    let key = "\(task.systemId?.uuidString ?? "nil"):\(task.title.lowercased())"
                    if seen.contains(key) {
                        try? await db.deleteMaintenanceTask(id: task.id)
                    } else {
                        seen.insert(key)
                    }
                }
            }

            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            print("[TaskMigration] Failed: \(error)")
        }
    }
}

import Foundation

enum ServiceKind: String, Codable, CaseIterable {
    case routineProgram = "routine_program"
    case seasonalService = "seasonal_service"
    case handymanProgram = "handyman_program"
    case conciergeAddOn = "concierge_add_on"
}

enum ServiceRoutingStrategy: String, Codable, CaseIterable {
    case vendorProgram = "vendor_program"
    case vendorOnly = "vendor_only"
    case vendorOrDIY = "vendor_or_diy"
    case handymanDefault = "handyman_default"
    case conciergeOnly = "concierge_only"
}

struct ServiceVisitType: Codable, Hashable, Identifiable {
    let key: String
    let label: String
    let cadence: String?
    let trigger: String?

    var id: String { key }
}

struct ServiceChecklistItem: Codable, Hashable, Identifiable {
    let key: String
    let label: String
    let homeownerVisible: Bool

    var id: String { key }
}

struct ServiceProofRequirement: Codable, Hashable, Identifiable {
    let key: String
    let label: String

    var id: String { key }
}

struct ServiceExceptionRule: Codable, Hashable, Identifiable {
    let key: String
    let trigger: String
    let outcome: String

    var id: String { key }
}

struct LegacyTaskMapping: Codable, Hashable, Identifiable {
    let legacyIdentifier: String
    let serviceKey: String
    let visitTypeKey: String?
    let shouldHideFromHomeowner: Bool

    var id: String { legacyIdentifier }
}

struct ServiceDefinition: Codable, Hashable, Identifiable {
    let serviceKey: String
    let serviceKind: ServiceKind
    let homeownerTitle: String
    let defaultRoutingStrategy: ServiceRoutingStrategy
    let vendorCategory: String
    let cadenceOrTrigger: String
    let subtypeGates: [String]
    let regionalGates: [String]
    let visitTypes: [ServiceVisitType]
    let checklistItems: [ServiceChecklistItem]
    let proofRequirements: [ServiceProofRequirement]
    let exceptionRules: [ServiceExceptionRule]
    let absorbedLegacyTemplateKeys: [String]
    let supportedRoutineKinds: [String]
    let homeownerVisibleByDefault: Bool

    var id: String { serviceKey }
}

enum ServiceLibrary {
    private struct ServiceContext {
        let serviceKey: String
        let visitTypeKey: String?
    }

    static let definitions: [ServiceDefinition] = [
        seasonal(
            key: "roof_and_gutter_service",
            title: "Roof & Gutter Service",
            vendor: "Roofer / gutter service",
            cadence: "Annual; after major storms",
            legacy: [
                "Check for damaged shingles",
                "Clean gutters and downspouts",
                "Inspect flashing around chimney/vents",
                "Reseal flashing and seams",
                "Treat moss and algae",
                "Annual roof inspection"
            ],
            checklist: [
                "Inspect roof surface and vulnerable penetrations",
                "Clear gutters and confirm downspout flow",
                "Document flashing, sealant, and storm damage"
            ],
            proof: ["Photo summary", "Storm-risk notes"],
            exceptions: ["Escalate leaks or failing flashing into a project/quote"]
        ),
        seasonal(
            key: "exterior_envelope_and_sealant_service",
            title: "Exterior Envelope & Sealant Service",
            vendor: "Painter / exterior handyman / envelope contractor",
            cadence: "Annual walkthrough; targeted caulk / repaint cycles",
            legacy: [
                "Exterior painting refresh",
                "Schedule exterior window re-caulking"
            ],
            checklist: [
                "Inspect siding, trim, and exterior sealant lines",
                "Flag failed caulk, peeling paint, and exposed wood",
                "Document areas that need targeted protection work"
            ],
            proof: ["Before/after photos", "Priority notes"],
            exceptions: ["Create a repaint / envelope repair project when field failure is widespread"]
        ),
        seasonal(
            key: "exterior_wash_and_facade_care",
            title: "Exterior Wash & Facade Care",
            vendor: "Soft-wash / pressure-wash vendor",
            cadence: "Annual spring wash",
            legacy: [
                "Pressure wash patio and walkways",
                "Annual exterior power washing",
                "Power wash exterior siding"
            ],
            checklist: [
                "Wash facade, hardscape, and mildew-prone surfaces",
                "Protect delicate finishes and landscaping",
                "Flag facade damage that cleaning exposes"
            ],
            proof: ["Before/after photos"],
            exceptions: ["Escalate damaged finishes into a repair project"]
        ),
        seasonal(
            key: "deck_fence_and_hardscape_preservation",
            title: "Deck, Fence & Hardscape Preservation",
            vendor: "Deck / fence contractor or hardscape vendor",
            cadence: "Annual inspection; seasonal stain / seal cadence",
            legacy: [
                "Top up joint sand in pavers",
                "Treat weeds between pavers",
                "Deck and patio annual service",
                "Deck or fence staining"
            ],
            checklist: [
                "Inspect wood and hardscape surfaces for wear",
                "Refresh protective finishes and joint stability",
                "Document trip hazards, rot, and drainage issues"
            ],
            proof: ["Condition photos", "Finish renewal notes"],
            exceptions: ["Create repair project for failing boards, rails, or settling hardscape"]
        ),
        seasonal(
            key: "driveway_preservation_service",
            title: "Driveway Preservation Service",
            vendor: "Driveway / asphalt contractor",
            cadence: "Every 2-3 years in warm weather",
            legacy: ["Asphalt driveway sealcoat", "Driveway seal coat"],
            checklist: [
                "Inspect driveway surface and edge integrity",
                "Sealcoat or preserve the finished surface",
                "Flag cracking, ponding, and base failure"
            ],
            proof: ["Surface photos"],
            exceptions: ["Escalate major cracking or drainage failure into a project"]
        ),
        seasonal(
            key: "plumbing_risk_inspection",
            title: "Plumbing Risk Inspection",
            vendor: "Plumber",
            cadence: "Annual spring-preferred inspection",
            legacy: [
                "Check washing machine supply hoses",
                "Drain cleaning",
                "Exercise and label the main water shutoff",
                "Check pressure-reducing valve / house pressure",
                "Inspect under-sink shutoffs, traps, and visible active leaks"
            ],
            checklist: [
                "Inspect visible leak points and supply lines",
                "Verify shutoffs, pressure control, and drainage behavior",
                "Document risk items before they become failures"
            ],
            proof: ["Risk summary", "Leak photos if found"],
            exceptions: ["Create leak-mitigation project when structural drainage work is required"]
        ),
        seasonal(
            key: "water_heater_service",
            title: "Water Heater Service",
            vendor: "Plumber",
            cadence: "Annual service",
            legacy: [
                "Descale tankless heater",
                "Inspect anode rod",
                "Test T&P relief valve",
                "Flush water heater"
            ],
            checklist: [
                "Service tank or tankless maintenance points",
                "Verify safety components and sediment condition",
                "Document age, corrosion, and replacement risk"
            ],
            proof: ["Service report"],
            exceptions: ["Create replacement project when age / corrosion risk is high"]
        ),
        routine(
            key: "hvac_program",
            title: "HVAC Program",
            vendor: "HVAC / boiler contractor",
            cadence: "Seasonal cooling and heating service",
            visitTypes: [
                visit("cooling_service", "Cooling service", cadence: "Annual", trigger: "Spring before heat"),
                visit("heating_service", "Heating / boiler service", cadence: "Annual", trigger: "Fall before heat"),
                visit("filter_refresh", "Filter refresh", cadence: "As needed", trigger: "Handyman / consumables fallback")
            ],
            routineKinds: [],
            legacy: [
                "Flush HVAC condensate drain line",
                "Geothermal loop pressure check",
                "Inspect mini-split outdoor unit",
                "HVAC tune-up (cooling)",
                "Annual boiler service",
                "Bleed radiators",
                "Whole-home humidifier service",
                "HVAC tune-up (heating)"
            ],
            checklist: [
                "Seasonal equipment service based on system type",
                "Condensate, combustion, airflow, and control checks",
                "Escalate component failure or comfort risk"
            ],
            proof: ["Service report", "Photo of model / serial when relevant"],
            exceptions: ["Create repair / replacement project when performance or safety fails"]
        ),
        seasonal(
            key: "indoor_air_duct_and_humidity_service",
            title: "Indoor Air, Duct & Humidity Service",
            vendor: "HVAC / IAQ specialist",
            cadence: "Every 1-5 years depending on scope",
            legacy: [
                "Air duct cleaning",
                "Inspect ductwork for leaks"
            ],
            checklist: [
                "Inspect IAQ equipment, ducts, and humidity control",
                "Recommend cleaning or balancing only when indicated",
                "Document leaks, contamination, or chronic humidity issues"
            ],
            proof: ["IAQ summary"],
            exceptions: ["Escalate air sealing / duct repair / dehumidification projects as needed"]
        ),
        seasonal(
            key: "water_treatment_service",
            title: "Water Treatment Service",
            vendor: "Plumber / water-treatment specialist",
            cadence: "Annual plus consumable cycles",
            legacy: [
                "Replace whole-home filter cartridges",
                "Inspect and clean water-softener brine tank",
                "Service reverse-osmosis system and replace cartridges",
                "Inspect UV sterilization lamp / sleeve where installed"
            ],
            checklist: [
                "Service filtration, softening, RO, and UV gear as installed",
                "Replace consumables and inspect performance",
                "Document water quality or treatment concerns"
            ],
            proof: ["Filter / lamp service notes"],
            exceptions: ["Create project when treatment equipment is undersized or failing"]
        ),
        seasonal(
            key: "water_protection_and_drainage_service",
            title: "Water Protection & Drainage Service",
            vendor: "Plumber / waterproofing / drainage contractor",
            cadence: "Annual; before wet season",
            legacy: [
                "Check hardscape drainage and grading",
                "Test sump pump battery backup",
                "Clean sump basin and confirm float movement",
                "Inspect buried downspout discharge points",
                "Clean catch basins, trench drains, and area drains"
            ],
            checklist: [
                "Inspect pumps, discharge paths, grading, and site drainage",
                "Service drainage components that need cleaning",
                "Document ponding, seepage, and foundation-risk conditions"
            ],
            proof: ["Drainage photos", "Risk notes"],
            exceptions: ["Create drainage correction project when water management is inadequate"]
        ),
        seasonal(
            key: "septic_service",
            title: "Septic Service",
            vendor: "Septic vendor",
            cadence: "Inspection annual to triennial; pumping every 3-5 years",
            legacy: ["Inspect septic baffles", "Septic tank pumping"],
            checklist: [
                "Inspect system health and required pumping interval",
                "Document sludge level, alarms, and drain-field concerns",
                "Escalate failures before service interruption"
            ],
            proof: ["Service report"],
            exceptions: ["Create repair / field remediation project when inspection fails"]
        ),
        seasonal(
            key: "well_water_and_pump_service",
            title: "Well Water & Pump Service",
            vendor: "Well service / water lab",
            cadence: "Annual water test; periodic mechanical inspection",
            legacy: ["Test water quality", "Well system inspection"],
            checklist: [
                "Test water quality and inspect pump / pressure equipment",
                "Verify controls, tank behavior, and protective components",
                "Document treatment or reliability concerns"
            ],
            proof: ["Water test result", "Pump service notes"],
            exceptions: ["Create project for failing pressure / pump / treatment systems"]
        ),
        seasonal(
            key: "electrical_safety_service",
            title: "Electrical Safety Service",
            vendor: "Licensed electrician",
            cadence: "Annual to every 3 years depending on item",
            legacy: [
                "EV charger inspection",
                "Heat cable inspection",
                "IR scan of main electrical panel",
                "Inspect electrical panel",
                "Replace smoke detectors"
            ],
            checklist: [
                "Inspect panel, protective devices, and high-risk circuits",
                "Validate specialty equipment and safety devices",
                "Document unsafe findings clearly"
            ],
            proof: ["Inspection summary", "Thermal / panel photos"],
            exceptions: ["Create repair project immediately for unsafe findings"]
        ),
        routine(
            key: "generator_program",
            title: "Generator Program",
            vendor: "Generator vendor",
            cadence: "Annual service with seasonal checks",
            visitTypes: [
                visit("generator_service", "Generator service", cadence: "Annual", trigger: "Spring or fall"),
                visit("generator_alert_follow_up", "Generator issue follow-up", cadence: "As needed", trigger: "After failed self-test")
            ],
            routineKinds: [RoutineKind.otherService.rawValue],
            legacy: [
                "Change generator oil",
                "Replace spark plugs",
                "Test automatic transfer switch",
                "Annual generator service"
            ],
            checklist: [
                "Service engine and transfer components",
                "Verify test cycle and backup readiness",
                "Document load, battery, and controller issues"
            ],
            proof: ["Service report"],
            exceptions: ["Create repair project when reliability or ATS safety is compromised"]
        ),
        seasonal(
            key: "garage_door_tune_up",
            title: "Garage Door Tune-Up",
            vendor: "Garage door vendor",
            cadence: "Annual service",
            legacy: [
                "Lubricate garage door tracks and hardware",
                "Test garage door auto-reverse",
                "Annual garage door tune-up"
            ],
            checklist: [
                "Tune mechanical components and openers",
                "Verify safety reverse and sensor function",
                "Document wear, noise, or balance issues"
            ],
            proof: ["Safety-check notes"],
            exceptions: ["Create repair project for failing springs / operators / safety hardware"]
        ),
        seasonal(
            key: "fireplace_and_chimney_service",
            title: "Fireplace & Chimney Service",
            vendor: "Chimney sweep / fireplace tech",
            cadence: "Annual before heating season",
            legacy: [
                "Annual gas fireplace service",
                "Inspect chimney cap and crown",
                "Annual chimney sweep"
            ],
            checklist: [
                "Service venting, firebox, and combustion-related components",
                "Inspect exterior crown, cap, and masonry condition",
                "Document creosote, venting, or safety concerns"
            ],
            proof: ["Inspection / sweep report"],
            exceptions: ["Create repair project for venting, liner, or masonry failure"]
        ),
        routine(
            key: "security_and_smart_home_program",
            title: "Security & Smart Home Program",
            vendor: "Security integrator / smart home vendor",
            cadence: "Annual service with battery / device follow-up",
            visitTypes: [
                visit("security_system_service", "Security system service", cadence: "Annual", trigger: "Anytime"),
                visit("battery_refresh", "Battery refresh", cadence: "As needed", trigger: "Low-battery alerts")
            ],
            routineKinds: [],
            legacy: [
                "Replace sensor batteries",
                "Annual security system check"
            ],
            checklist: [
                "Inspect core security and automation devices",
                "Refresh batteries and confirm alert paths",
                "Document offline or unsupported equipment"
            ],
            proof: ["Service notes"],
            exceptions: ["Create project when major device refresh or system redesign is needed"]
        ),
        seasonal(
            key: "solar_service",
            title: "Solar Service",
            vendor: "Solar vendor",
            cadence: "Annual review window",
            legacy: ["Solar panel cleaning", "Solar system inspection"],
            checklist: [
                "Inspect production, panels, and visible system health",
                "Recommend cleaning or repair only when warranted",
                "Document inverter / roof / mounting issues"
            ],
            proof: ["Production summary"],
            exceptions: ["Create repair project when output or mounting issues are significant"]
        ),
        routine(
            key: "elevator_program",
            title: "Elevator Program",
            vendor: "Elevator vendor",
            cadence: "Quarterly service plus annual inspection",
            visitTypes: [
                visit("elevator_service", "Quarterly service", cadence: "Quarterly", trigger: "Scheduled by contract"),
                visit("elevator_inspection", "Annual inspection", cadence: "Annual", trigger: "Scheduled by contract")
            ],
            routineKinds: [RoutineKind.otherService.rawValue],
            legacy: ["Annual elevator inspection", "Quarterly elevator service"],
            checklist: [
                "Perform contracted service and required inspection",
                "Document safety, performance, and code issues"
            ],
            proof: ["Inspection report"],
            exceptions: ["Create project for code-mandated upgrades or component failure"]
        ),
        seasonal(
            key: "attic_crawl_space_and_foundation_inspection",
            title: "Attic, Crawl Space & Foundation Inspection",
            vendor: "Foundation / crawl space / insulation contractor",
            cadence: "Annual dry-season / fall inspection",
            legacy: [
                "Check foundation for cracks",
                "Check vapor barrier condition",
                "Inspect for mold or mildew",
                "Inspect attic ventilation and insulation",
                "Annual attic inspection"
            ],
            checklist: [
                "Inspect structural envelope, insulation, and moisture controls",
                "Document settlement, moisture, pest, or ventilation issues",
                "Highlight anything that requires specialist follow-up"
            ],
            proof: ["Condition photos"],
            exceptions: ["Create project for structural, encapsulation, or insulation remediation"]
        ),
        seasonal(
            key: "radon_and_moisture_control_service",
            title: "Radon & Moisture Control Service",
            vendor: "Radon / IAQ specialist",
            cadence: "Annual to every 2 years",
            legacy: [
                "Service whole-home or basement dehumidifier",
                "Verify radon mitigation fan",
                "Annual radon test"
            ],
            checklist: [
                "Test radon / moisture control equipment and readings",
                "Service mitigation-adjacent equipment where installed",
                "Document unhealthy readings or control failures"
            ],
            proof: ["Testing result"],
            exceptions: ["Create project when mitigation or dehumidification is inadequate"]
        ),
        routine(
            key: "wine_cellar_program",
            title: "Wine Cellar Cooling Program",
            vendor: "Wine cellar / refrigeration vendor",
            cadence: "Annual before hottest months",
            visitTypes: [
                visit("wine_cellar_service", "Cooling unit service", cadence: "Annual", trigger: "Before hottest months")
            ],
            routineKinds: [],
            legacy: ["Annual cooling unit service"],
            checklist: [
                "Service refrigeration unit and environmental controls",
                "Document vibration, drainage, and alarm issues"
            ],
            proof: ["Service report"],
            exceptions: ["Create repair / replacement project for unstable cellar conditions"]
        ),
        seasonal(
            key: "appliance_safety_and_outdoor_kitchen_service",
            title: "Appliance Safety & Outdoor Kitchen Service",
            vendor: "Appliance / outdoor-kitchen vendor",
            cadence: "Annual spring service",
            legacy: ["Built-in grill service", "Clean dryer vent duct"],
            checklist: [
                "Service installed appliances that warrant pro maintenance",
                "Clean venting and inspect outdoor kitchen components",
                "Document unsafe or failing equipment"
            ],
            proof: ["Service notes"],
            exceptions: ["Create repair / replacement project for unsafe appliance findings"]
        ),
        routine(
            key: "landscaping_program",
            title: "Landscaping Program",
            vendor: "Landscaper",
            cadence: "Weekly / biweekly maintenance plus seasonal packages",
            visitTypes: [
                visit("routine_grounds", "Routine grounds maintenance", cadence: "Weekly / biweekly", trigger: "Growing season"),
                visit("spring_cleanup", "Spring cleanup", cadence: "Annual", trigger: "Spring"),
                visit("fall_cleanup", "Fall cleanup", cadence: "Annual", trigger: "Fall")
            ],
            routineKinds: [RoutineKind.landscaping.rawValue],
            legacy: [
                "Core aerate natural lawn",
                "Dethatch lawn",
                "Fall leaf cleanup",
                "Fertilize natural lawn",
                "Mulch garden beds",
                "Overseed bare patches",
                "Pre-emergent weed control",
                "Prune shrubs and hedges"
            ],
            checklist: [
                "Maintain grounds on recurring cadence",
                "Layer in seasonal cleanup and treatment packs",
                "Document drainage, turf, or plant health issues"
            ],
            proof: ["Visit notes", "Before/after grounds photos"],
            exceptions: ["Create drainage, hardscape, or replanting project when appropriate"]
        ),
        routine(
            key: "synthetic_turf_program",
            title: "Synthetic Turf Program",
            vendor: "Synthetic turf vendor",
            cadence: "Annual to semiannual depending on use",
            visitTypes: [
                visit("turf_grooming", "Turf grooming", cadence: "Semiannual", trigger: "Spring / high-use season")
            ],
            routineKinds: [],
            legacy: [
                "Deep clean synthetic turf",
                "Power rake and groom turf",
                "Top up turf infill"
            ],
            checklist: [
                "Groom turf fibers and rebalance infill",
                "Deep clean as needed based on use",
                "Document seam or drainage problems"
            ],
            proof: ["Condition photos"],
            exceptions: ["Create repair project for seam failure or drainage issues"]
        ),
        seasonal(
            key: "arborist_and_tree_risk_service",
            title: "Arborist & Tree Risk Service",
            vendor: "Certified arborist / tree service",
            cadence: "Annual plus storm response as needed",
            legacy: [
                "Arborist tree health inspection",
                "Pruning and crown thinning",
                "Trim trees away from roof",
                "Annual tree assessment"
            ],
            checklist: [
                "Assess tree health and structural risk",
                "Plan pruning or mitigation work where needed",
                "Document roof, powerline, or safety hazards"
            ],
            proof: ["Inspection notes", "Hazard photos"],
            exceptions: ["Create project for major removals or hazard mitigation work"]
        ),
        routine(
            key: "outdoor_lighting_program",
            title: "Outdoor Lighting Program",
            vendor: "Outdoor lighting vendor",
            cadence: "Annual spring service",
            visitTypes: [
                visit("lighting_service", "Outdoor lighting service", cadence: "Annual", trigger: "Spring")
            ],
            routineKinds: [],
            legacy: [
                "Outdoor lighting system service",
                "Outdoor lighting service"
            ],
            checklist: [
                "Inspect fixtures, transformers, and controls",
                "Refresh bulbs and aim where needed",
                "Document wiring or fixture issues"
            ],
            proof: ["Night-test notes"],
            exceptions: ["Create repair project for wiring or fixture replacement needs"]
        ),
        routine(
            key: "irrigation_program",
            title: "Irrigation Program",
            vendor: "Irrigation vendor",
            cadence: "Seasonal startup and winterization",
            visitTypes: [
                visit("startup_backflow", "Startup & backflow service", cadence: "Annual", trigger: "Spring"),
                visit("winterization", "Winterization", cadence: "Annual", trigger: "Fall before freeze")
            ],
            routineKinds: [],
            legacy: [
                "Backflow preventer test",
                "Spring startup irrigation",
                "Winterize irrigation system"
            ],
            checklist: [
                "Open, test, and close the system seasonally",
                "Handle backflow testing and zone adjustments",
                "Document leaks, pressure issues, or controller problems"
            ],
            proof: ["Service notes", "Backflow record"],
            exceptions: ["Create repair project for leaks, controls, or zone coverage issues"]
        ),
        routine(
            key: "pool_program",
            title: "Pool Program",
            vendor: "Pool vendor",
            cadence: "Opening, weekly care, and closing",
            visitTypes: [
                visit("opening", "Pool opening", cadence: "Annual", trigger: "Spring"),
                visit("weekly_care", "Weekly care", cadence: "Weekly", trigger: "Open-pool season"),
                visit("closing", "Pool closing", cadence: "Annual", trigger: "Fall"),
                visit("equipment_service", "Equipment service", cadence: "As needed", trigger: "Issue found during visit")
            ],
            routineKinds: [RoutineKind.poolService.rawValue],
            legacy: [
                "Inspect pool equipment",
                "Pool heater service",
                "Pool safety fence inspection",
                "Pool opening service",
                "Pool closing and winterization"
            ],
            checklist: [
                "Handle seasonal open / close work and recurring water care",
                "Inspect core equipment, safety elements, and chemistry",
                "Document repair items discovered during service"
            ],
            proof: ["Chemistry log", "Equipment notes"],
            exceptions: ["Create repair project for major equipment, coping, or safety failures"]
        ),
        routine(
            key: "hot_tub_program",
            title: "Hot Tub Service Program",
            vendor: "Spa vendor or pool vendor",
            cadence: "Weekly / monthly water care plus drain / refill cadence",
            visitTypes: [
                visit("water_care", "Water care", cadence: "Weekly / monthly", trigger: "Year-round"),
                visit("drain_refill", "Drain & refill", cadence: "Periodic", trigger: "Use-based")
            ],
            routineKinds: [],
            legacy: [
                "Drain and refill hot tub",
                "Inspect hot tub cover and jets",
                "Test and sanitize hot tub water"
            ],
            checklist: [
                "Maintain chemistry and recurring sanitation",
                "Inspect jets, cover, and heating components",
                "Document leaks or mechanical risk"
            ],
            proof: ["Water-care notes"],
            exceptions: ["Create repair project for heating, shell, or leak issues"]
        ),
        routine(
            key: "pest_and_termite_program",
            title: "Pest & Termite Program",
            vendor: "Pest-control vendor",
            cadence: "Quarterly with annual termite review",
            visitTypes: [
                visit("routine_pest_service", "Routine pest service", cadence: "Quarterly", trigger: "Year-round"),
                visit("termite_review", "Termite review", cadence: "Annual", trigger: "Year-round")
            ],
            routineKinds: [RoutineKind.pestControl.rawValue],
            legacy: ["Termite inspection"],
            checklist: [
                "Handle recurring perimeter / interior pest control",
                "Layer termite inspection where applicable",
                "Document intrusion or damage concerns"
            ],
            proof: ["Service report"],
            exceptions: ["Create remediation project for structural damage or infestation"]
        ),
        routine(
            key: "mosquito_and_tick_program",
            title: "Mosquito & Tick Program",
            vendor: "Mosquito / tick vendor",
            cadence: "Seasonal recurring program",
            visitTypes: [
                visit("mosquito_tick_service", "Mosquito & tick treatment", cadence: "Recurring", trigger: "Warm months")
            ],
            routineKinds: [RoutineKind.mosquitoTick.rawValue],
            legacy: ["Sign up for mosquito and tick season"],
            checklist: [
                "Apply seasonal treatment on recurring cadence",
                "Document treatment timing and hotspot areas"
            ],
            proof: ["Service notes"],
            exceptions: ["Escalate standing-water or habitat issues into a property project"]
        ),
        routine(
            key: "snow_and_ice_management_program",
            title: "Snow & Ice Management Program",
            vendor: "Snow-removal vendor",
            cadence: "Seasonal recurring program",
            visitTypes: [
                visit("storm_response", "Storm response", cadence: "As needed", trigger: "Snow events"),
                visit("season_setup", "Season setup", cadence: "Annual", trigger: "Before first snow")
            ],
            routineKinds: [RoutineKind.snowRemoval.rawValue],
            legacy: ["Renew snow plowing contract"],
            checklist: [
                "Cover seasonal contract setup and storm response",
                "Document access or ice-risk issues"
            ],
            proof: ["Storm response notes"],
            exceptions: ["Create project for drainage / melt / surface hazards that need capital work"]
        ),
        routine(
            key: "exterior_window_cleaning_program",
            title: "Exterior Window Cleaning",
            vendor: "Window-cleaning vendor",
            cadence: "Annual or semiannual",
            visitTypes: [
                visit("window_cleaning", "Exterior window cleaning", cadence: "Annual / semiannual", trigger: "Spring / fall")
            ],
            routineKinds: [RoutineKind.windowCleaning.rawValue],
            legacy: ["Exterior window washing"],
            checklist: [
                "Clean exterior glazing and accessible exterior glass",
                "Document failed seals or damaged hardware noticed during service"
            ],
            proof: ["Before/after photos"],
            exceptions: ["Create repair project for failed glazing or damaged openings"]
        ),
        routine(
            key: "housekeeping_program",
            title: "Housekeeping & Deep Clean Program",
            vendor: "Housekeeper / cleaning service",
            cadence: "Weekly / biweekly with deep-clean overlays",
            visitTypes: [
                visit("routine_cleaning", "Routine cleaning", cadence: "Weekly / biweekly", trigger: "Always-on"),
                visit("deep_clean", "Deep clean", cadence: "Quarterly / semiannual", trigger: "Always-on")
            ],
            routineKinds: [RoutineKind.cleaning.rawValue],
            legacy: [],
            checklist: [
                "Track routine cleaning cadence and periodic deep clean scope",
                "Document special requests or missed areas when relevant"
            ],
            proof: ["Visit notes"],
            exceptions: ["Escalate staffing or vendor change needs rather than cluttering maintenance"]
        ),
        routine(
            key: "waste_program",
            title: "Trash, Recycling & Organics Program",
            vendor: "Municipal / private hauler / estate staff",
            cadence: "Weekly or municipality-based",
            visitTypes: [
                visit("trash_pickup", "Trash pickup", cadence: "Weekly", trigger: "Municipality-based"),
                visit("recycling_pickup", "Recycling pickup", cadence: "Weekly / biweekly", trigger: "Municipality-based"),
                visit("organics_pickup", "Organics pickup", cadence: "Weekly", trigger: "Municipality-based")
            ],
            routineKinds: [
                RoutineKind.trash.rawValue,
                RoutineKind.recycling.rawValue,
                RoutineKind.compost.rawValue,
                RoutineKind.yardWaste.rawValue
            ],
            legacy: [],
            checklist: [
                "Track household pickup rhythm and reminders",
                "Surface exceptions only when service breaks down"
            ],
            proof: ["Exception notes only"],
            exceptions: ["Create alert when pickup is missed or service changes materially"]
        ),
        handyman(
            key: "handyman_program",
            title: "Handyman Program",
            legacy: [
                "Fire extinguisher annual check",
                "Foundation walkaround: cracks and grading",
                "Inspect exterior caulking around windows & doors",
                "Reopen exterior faucets post-winter",
                "Replace HVAC filter (cooling season)",
                "Replace smoke & CO detector batteries",
                "Test GFCI outlets throughout house",
                "Check attic insulation coverage",
                "Drain and store exterior hoses",
                "Inspect weatherstripping pre-heating season",
                "Pipe insulation check in unheated spaces",
                "Winterize outdoor faucets and hose bibs"
            ],
            checklist: [
                "Accumulate low-risk punch-list work into a single visit",
                "Mix seasonal prep, filters, caulk touch-ups, and small repairs",
                "Escalate specialist-only or safety-floor items out of the bundle"
            ],
            proof: ["Visit notes", "Before/after photos when useful"],
            exceptions: ["Create specialist task or project when scope exceeds handyman lane"]
        ),
        concierge(
            key: "concierge_tune_up",
            title: "Home Concierge Tune-Up",
            vendor: "Handyman / painter / smart-home support",
            cadence: "Semiannual or annual as desired",
            legacy: [
                "Replace refrigerator water filter",
                "Cabinet and door hardware tune-up",
                "Ceiling fan cleaning and balancing",
                "Ceiling fan direction switch (summer)",
                "Ceiling fan direction switch (winter)",
                "Interior paint touch-up walkaround",
                "Smart home battery sweep",
                "Whole-house relamping"
            ],
            checklist: [
                "Optional white-glove convenience work",
                "Keep cosmetic items out of the core preservation flow"
            ]
        ),
        seasonal(
            key: "custom_seasonal_service",
            title: "Custom Seasonal Service",
            vendor: "Custom vendor",
            cadence: "User-defined",
            legacy: [],
            checklist: ["User-authored scope"],
            proof: ["Optional notes / attachments"],
            exceptions: ["User may turn this into a project if scope expands"]
        ),
        routine(
            key: "custom_routine_program",
            title: "Custom Routine Program",
            vendor: "Custom vendor",
            cadence: "User-defined recurring program",
            visitTypes: [visit("custom_visit", "Custom visit", cadence: "User-defined", trigger: "User-defined cadence")],
            routineKinds: [RoutineKind.otherService.rawValue, RoutineKind.otherCadence.rawValue],
            legacy: [],
            checklist: ["User-authored recurring scope"],
            proof: ["Optional notes / attachments"],
            exceptions: ["User may convert this into a project when the work changes"]
        )
    ]

    private static let definitionsByKey = Dictionary(uniqueKeysWithValues: definitions.map { ($0.serviceKey, $0) })
    private static let routineKindToServiceKey: [String: String] = {
        var result: [String: String] = [:]
        for definition in definitions {
            for kind in definition.supportedRoutineKinds {
                result[kind] = definition.serviceKey
            }
        }
        return result
    }()

    static let legacyMappings: [LegacyTaskMapping] = definitions.flatMap { definition in
        definition.absorbedLegacyTemplateKeys.map {
            LegacyTaskMapping(
                legacyIdentifier: $0,
                serviceKey: definition.serviceKey,
                visitTypeKey: visitTypeKey(forLegacyTemplateKey: $0),
                shouldHideFromHomeowner: definition.serviceKind != .seasonalService
            )
        }
    }

    static func serviceDefinition(forKey key: String?) -> ServiceDefinition? {
        guard let key else { return nil }
        return definitionsByKey[key]
    }

    static func serviceDefinition(for task: MaintenanceTaskDBRow) -> ServiceDefinition? {
        serviceDefinition(forKey: task.resolvedServiceKey)
    }

    static func serviceDefinition(for routine: RoutineRow) -> ServiceDefinition? {
        serviceDefinition(forKey: routine.resolvedServiceKey)
    }

    static func serviceKey(forLegacyTemplateKey templateKey: String?) -> String? {
        guard let templateKey else { return nil }
        return legacyContext(for: templateKey).serviceKey
    }

    static func visitTypeKey(forLegacyTemplateKey templateKey: String?) -> String? {
        guard let templateKey else { return nil }
        return legacyContext(for: templateKey).visitTypeKey
    }

    static func serviceKey(for task: MaintenanceTaskDBRow) -> String? {
        if let existing = task.serviceKey { return existing }
        if let templateId = task.templateId,
           let mapped = serviceKey(forLegacyTemplateKey: templateId) {
            return mapped
        }
        return serviceKey(forTitle: task.title, notes: task.notes, systemCategory: nil)
            ?? "custom_seasonal_service"
    }

    static func serviceKey(for insert: MaintenanceTaskInsert) -> String? {
        if let existing = insert.serviceKey { return existing }
        if let templateId = insert.templateId,
           let mapped = serviceKey(forLegacyTemplateKey: templateId) {
            return mapped
        }
        return serviceKey(forTitle: insert.title, notes: insert.notes, systemCategory: nil)
            ?? "custom_seasonal_service"
    }

    static func serviceKey(for routine: RoutineRow) -> String? {
        if let existing = routine.serviceKey { return existing }
        return serviceKey(forRoutineKind: routine.routineKind, label: routine.label)
    }

    static func serviceKey(for insert: RoutineInsert) -> String? {
        if let existing = insert.serviceKey { return existing }
        return serviceKey(forRoutineKind: insert.routineKind, label: insert.label)
    }

    static func serviceKey(forRoutineKind kind: String, label: String?) -> String? {
        if kind == RoutineKind.otherService.rawValue || kind == RoutineKind.otherCadence.rawValue {
            return serviceKey(forTitle: label, notes: nil, systemCategory: kind) ?? "custom_routine_program"
        }
        if let mapped = routineKindToServiceKey[kind] {
            return mapped
        }
        return serviceKey(forTitle: label, notes: nil, systemCategory: kind)
    }

    static func visitTypeKey(
        for routine: RoutineRow,
        scheduledDate: String? = nil,
        notes: String? = nil
    ) -> String? {
        let normalized = [routine.label, notes].compactMap { $0?.lowercased() }.joined(separator: " ")
        switch routine.resolvedServiceKey {
        case "hvac_program":
            if normalized.contains("heat") || normalized.contains("boiler") || normalized.contains("furnace") {
                return "heating_service"
            }
            if normalized.contains("filter") { return "filter_refresh" }
            return "cooling_service"
        case "irrigation_program":
            return normalized.contains("winter") ? "winterization" : "startup_backflow"
        case "pool_program":
            if normalized.contains("close") || normalized.contains("winter") { return "closing" }
            if normalized.contains("weekly") || normalized.contains("chem") { return "weekly_care" }
            if normalized.contains("equipment") || normalized.contains("heater") { return "equipment_service" }
            return "opening"
        case "hot_tub_program":
            return normalized.contains("drain") ? "drain_refill" : "water_care"
        case "landscaping_program":
            if normalized.contains("fall") { return "fall_cleanup" }
            if normalized.contains("spring") { return "spring_cleanup" }
            return "routine_grounds"
        case "waste_program":
            if normalized.contains("recycl") { return "recycling_pickup" }
            if normalized.contains("compost") || normalized.contains("organic") || normalized.contains("yard waste") {
                return "organics_pickup"
            }
            return "trash_pickup"
        case "handyman_program":
            if normalized.contains("fall") { return "fall_prep" }
            if normalized.contains("spring") { return "spring_prep" }
            return "ad_hoc_visit"
        default:
            return serviceDefinition(forKey: routine.resolvedServiceKey)?.visitTypes.first?.key
        }
    }

    static func homeownerTitle(for task: MaintenanceTaskDBRow) -> String {
        switch task.resolvedServiceKey {
        case "custom_seasonal_service", "concierge_tune_up":
            return task.title
        default:
            return serviceDefinition(for: task)?.homeownerTitle ?? task.title
        }
    }

    static func homeownerTitle(for routine: RoutineRow) -> String {
        switch routine.resolvedServiceKey {
        case "custom_routine_program":
            return routine.label
        default:
            return serviceDefinition(for: routine)?.homeownerTitle ?? routine.label
        }
    }

    static func serviceKind(for task: MaintenanceTaskDBRow) -> ServiceKind? {
        serviceDefinition(for: task)?.serviceKind
    }

    static func serviceKind(for routine: RoutineRow) -> ServiceKind? {
        serviceDefinition(for: routine)?.serviceKind
    }

    private static func serviceKey(
        forTitle title: String?,
        notes: String?,
        systemCategory: String?
    ) -> String? {
        let haystack = [systemCategory, title, notes]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")
        let tokens = Set(
            haystack.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)
        )

        if haystack.contains("handyman") ||
            haystack.contains("gfci") ||
            haystack.contains("weatherstripping") ||
            haystack.contains("hose bib") ||
            haystack.contains("smoke & co") ||
            haystack.contains("smoke and co") ||
            haystack.contains("relamping") ||
            haystack.contains("caulk touch") ||
            haystack.contains("filter") && haystack.contains("hvac") {
            return "handyman_program"
        }
        if haystack.contains("hot tub") || haystack.contains("hot_tub") {
            return "hot_tub_program"
        }
        if haystack.contains("pool") {
            return "pool_program"
        }
        if haystack.contains("irrigation") || haystack.contains("backflow") {
            return "irrigation_program"
        }
        if haystack.contains("hvac") || haystack.contains("boiler") || haystack.contains("furnace") || haystack.contains("mini-split") || haystack.contains("heat pump") {
            return "hvac_program"
        }
        if haystack.contains("housekeeping") || haystack.contains("deep clean") || haystack.contains("cleaning service") {
            return "housekeeping_program"
        }
        if haystack.contains("trash") || haystack.contains("recycling") || haystack.contains("organics") || haystack.contains("compost") || haystack.contains("yard waste") {
            return "waste_program"
        }
        if haystack.contains("generator") { return "generator_program" }
        if haystack.contains("security") || haystack.contains("smart home") { return "security_and_smart_home_program" }
        if haystack.contains("elevator") { return "elevator_program" }
        if haystack.contains("wine cellar") || haystack.contains("refrigeration") { return "wine_cellar_program" }
        if haystack.contains("landscap") || haystack.contains("lawn") || haystack.contains("mulch") || haystack.contains("shrub") {
            return "landscaping_program"
        }
        if haystack.contains("synthetic turf") || haystack.contains("turf") {
            return "synthetic_turf_program"
        }
        if haystack.contains("outdoor lighting") { return "outdoor_lighting_program" }
        if haystack.contains("pest") || haystack.contains("termite") { return "pest_and_termite_program" }
        if haystack.contains("mosquito") || haystack.contains("tick") { return "mosquito_and_tick_program" }
        if tokens.contains("snow") || tokens.contains("ice") || haystack.contains("plow") {
            return "snow_and_ice_management_program"
        }
        if haystack.contains("window washing") || haystack.contains("window cleaning") {
            return "exterior_window_cleaning_program"
        }
        if haystack.contains("roof") || haystack.contains("gutter") || haystack.contains("flashing") {
            return "roof_and_gutter_service"
        }
        if haystack.contains("sealant") || haystack.contains("caulk") || haystack.contains("exterior paint") {
            return "exterior_envelope_and_sealant_service"
        }
        if haystack.contains("pressure wash") || haystack.contains("power wash") || haystack.contains("facade care") {
            return "exterior_wash_and_facade_care"
        }
        if haystack.contains("deck") || haystack.contains("fence") || haystack.contains("hardscape") || haystack.contains("paver") {
            return "deck_fence_and_hardscape_preservation"
        }
        if haystack.contains("driveway") || haystack.contains("sealcoat") {
            return "driveway_preservation_service"
        }
        if haystack.contains("plumbing") || haystack.contains("supply hose") || haystack.contains("shutoff") || haystack.contains("drain cleaning") {
            return "plumbing_risk_inspection"
        }
        if haystack.contains("water heater") || haystack.contains("tankless") || haystack.contains("anode") || haystack.contains("t&p") {
            return "water_heater_service"
        }
        if haystack.contains("duct") || haystack.contains("humidity") || haystack.contains("iaq") {
            return "indoor_air_duct_and_humidity_service"
        }
        if haystack.contains("water treatment") || haystack.contains("softener") || haystack.contains("reverse osmosis") || haystack.contains("uv sterilization") {
            return "water_treatment_service"
        }
        if haystack.contains("sump") || haystack.contains("drainage") || haystack.contains("grading") || haystack.contains("window well") {
            return "water_protection_and_drainage_service"
        }
        if haystack.contains("septic") { return "septic_service" }
        if haystack.contains("well") || haystack.contains("water quality") {
            return "well_water_and_pump_service"
        }
        if haystack.contains("electrical") || haystack.contains("panel") || haystack.contains("ev charger") {
            return "electrical_safety_service"
        }
        if haystack.contains("garage door") { return "garage_door_tune_up" }
        if haystack.contains("chimney") || haystack.contains("fireplace") {
            return "fireplace_and_chimney_service"
        }
        if haystack.contains("solar") { return "solar_service" }
        if haystack.contains("attic") || haystack.contains("crawl space") || haystack.contains("foundation") || haystack.contains("vapor barrier") {
            return "attic_crawl_space_and_foundation_inspection"
        }
        if haystack.contains("radon") || haystack.contains("dehumidifier") || haystack.contains("moisture control") {
            return "radon_and_moisture_control_service"
        }
        if haystack.contains("appliance") || haystack.contains("dryer vent") || haystack.contains("outdoor kitchen") || haystack.contains("grill") {
            return "appliance_safety_and_outdoor_kitchen_service"
        }
        if haystack.contains("arborist") || haystack.contains("tree") {
            return "arborist_and_tree_risk_service"
        }
        if haystack.contains("concierge") || haystack.contains("paint touch") || haystack.contains("hardware tune-up") {
            return "concierge_tune_up"
        }
        if haystack.contains("follow-up") || haystack.contains("vendor follow-up") || haystack.contains("custom vendor visit") {
            return "custom_seasonal_service"
        }
        return nil
    }

    private static func legacyContext(for templateKey: String?) -> ServiceContext {
        guard let templateKey else {
            return ServiceContext(serviceKey: "custom_seasonal_service", visitTypeKey: nil)
        }

        let normalized = templateKey.lowercased()
        if normalized.contains("hot_tub") || normalized.contains("hot tub") {
            return ServiceContext(
                serviceKey: "hot_tub_program",
                visitTypeKey: normalized.contains("drain") ? "drain_refill" : "water_care"
            )
        }
        if normalized.contains("pool") {
            if normalized.contains("closing") || normalized.contains("winterization") {
                return ServiceContext(serviceKey: "pool_program", visitTypeKey: "closing")
            }
            if normalized.contains("weekly") {
                return ServiceContext(serviceKey: "pool_program", visitTypeKey: "weekly_care")
            }
            return ServiceContext(serviceKey: "pool_program", visitTypeKey: "opening")
        }
        if normalized.contains("spa") {
            return ServiceContext(
                serviceKey: "hot_tub_program",
                visitTypeKey: normalized.contains("drain") ? "drain_refill" : "water_care"
            )
        }
        if normalized.contains("irrigation") || normalized.contains("backflow") {
            return ServiceContext(
                serviceKey: "irrigation_program",
                visitTypeKey: normalized.contains("winter") ? "winterization" : "startup_backflow"
            )
        }
        if normalized.contains("hvac") || normalized.contains("boiler") || normalized.contains("furnace") || normalized.contains("mini-split") || normalized.contains("geothermal") {
            let visitType: String
            if normalized.contains("heat") || normalized.contains("boiler") || normalized.contains("furnace") {
                visitType = "heating_service"
            } else if normalized.contains("filter") {
                visitType = "filter_refresh"
            } else {
                visitType = "cooling_service"
            }
            return ServiceContext(serviceKey: "hvac_program", visitTypeKey: visitType)
        }
        if normalized.contains("handyman") ||
            normalized.contains("gfci") ||
            normalized.contains("weatherstripping") ||
            normalized.contains("hose") ||
            normalized.contains("smoke_co") ||
            normalized.contains("smoke & co") ||
            normalized.contains("caulking") ||
            normalized.contains("filter") {
            let visitType: String? = normalized.contains("fall") ? "fall_prep" : (normalized.contains("spring") ? "spring_prep" : "ad_hoc_visit")
            return ServiceContext(serviceKey: "handyman_program", visitTypeKey: visitType)
        }
        if normalized.contains("roof") || normalized.contains("gutter") || normalized.contains("flashing") {
            return ServiceContext(serviceKey: "roof_and_gutter_service", visitTypeKey: nil)
        }
        if normalized.contains("sealant") || normalized.contains("caulk") || normalized.contains("paint") {
            return ServiceContext(serviceKey: "exterior_envelope_and_sealant_service", visitTypeKey: nil)
        }
        if normalized.contains("power wash") || normalized.contains("pressure wash") {
            return ServiceContext(serviceKey: "exterior_wash_and_facade_care", visitTypeKey: nil)
        }
        if normalized.contains("deck") || normalized.contains("fence") || normalized.contains("hardscape") || normalized.contains("paver") {
            return ServiceContext(serviceKey: "deck_fence_and_hardscape_preservation", visitTypeKey: nil)
        }
        if normalized.contains("driveway") || normalized.contains("sealcoat") {
            return ServiceContext(serviceKey: "driveway_preservation_service", visitTypeKey: nil)
        }
        if normalized.contains("plumbing") || normalized.contains("shutoff") || normalized.contains("supply hose") || normalized.contains("drain cleaning") {
            return ServiceContext(serviceKey: "plumbing_risk_inspection", visitTypeKey: nil)
        }
        if normalized.contains("water heater") || normalized.contains("tankless") || normalized.contains("anode") {
            return ServiceContext(serviceKey: "water_heater_service", visitTypeKey: nil)
        }
        if normalized.contains("duct") || normalized.contains("iaq") || normalized.contains("humidity") {
            return ServiceContext(serviceKey: "indoor_air_duct_and_humidity_service", visitTypeKey: nil)
        }
        if normalized.contains("water treatment") || normalized.contains("reverse osmosis") || normalized.contains("softener") || normalized.contains("uv") {
            return ServiceContext(serviceKey: "water_treatment_service", visitTypeKey: nil)
        }
        if normalized.contains("sump") || normalized.contains("drainage") || normalized.contains("grading") {
            return ServiceContext(serviceKey: "water_protection_and_drainage_service", visitTypeKey: nil)
        }
        if normalized.contains("septic") {
            return ServiceContext(serviceKey: "septic_service", visitTypeKey: nil)
        }
        if normalized.contains("well") {
            return ServiceContext(serviceKey: "well_water_and_pump_service", visitTypeKey: nil)
        }
        if normalized.contains("electrical") || normalized.contains("panel") || normalized.contains("ev charger") {
            return ServiceContext(serviceKey: "electrical_safety_service", visitTypeKey: nil)
        }
        if normalized.contains("generator") {
            return ServiceContext(serviceKey: "generator_program", visitTypeKey: "generator_service")
        }
        if normalized.contains("garage door") {
            return ServiceContext(serviceKey: "garage_door_tune_up", visitTypeKey: nil)
        }
        if normalized.contains("fireplace") || normalized.contains("chimney") {
            return ServiceContext(serviceKey: "fireplace_and_chimney_service", visitTypeKey: nil)
        }
        if normalized.contains("security") || normalized.contains("sensor batteries") || normalized.contains("smart home") {
            return ServiceContext(serviceKey: "security_and_smart_home_program", visitTypeKey: normalized.contains("battery") ? "battery_refresh" : "security_system_service")
        }
        if normalized.contains("solar") {
            return ServiceContext(serviceKey: "solar_service", visitTypeKey: nil)
        }
        if normalized.contains("elevator") {
            return ServiceContext(serviceKey: "elevator_program", visitTypeKey: normalized.contains("inspection") ? "elevator_inspection" : "elevator_service")
        }
        if normalized.contains("attic") || normalized.contains("crawl space") || normalized.contains("foundation") {
            return ServiceContext(serviceKey: "attic_crawl_space_and_foundation_inspection", visitTypeKey: nil)
        }
        if normalized.contains("radon") || normalized.contains("dehumidifier") {
            return ServiceContext(serviceKey: "radon_and_moisture_control_service", visitTypeKey: nil)
        }
        if normalized.contains("wine cellar") || normalized.contains("refrigeration") {
            return ServiceContext(serviceKey: "wine_cellar_program", visitTypeKey: "wine_cellar_service")
        }
        if normalized.contains("dryer vent") || normalized.contains("outdoor kitchen") || normalized.contains("grill") || normalized.contains("appliance") {
            return ServiceContext(serviceKey: "appliance_safety_and_outdoor_kitchen_service", visitTypeKey: nil)
        }
        if normalized.contains("landscap") || normalized.contains("lawn") || normalized.contains("mulch") || normalized.contains("shrub") {
            let visitType: String = normalized.contains("fall") ? "fall_cleanup" : (normalized.contains("spring") ? "spring_cleanup" : "routine_grounds")
            return ServiceContext(serviceKey: "landscaping_program", visitTypeKey: visitType)
        }
        if normalized.contains("synthetic_turf") || normalized.contains("turf") {
            return ServiceContext(serviceKey: "synthetic_turf_program", visitTypeKey: "turf_grooming")
        }
        if normalized.contains("tree") || normalized.contains("arborist") {
            return ServiceContext(serviceKey: "arborist_and_tree_risk_service", visitTypeKey: nil)
        }
        if normalized.contains("outdoor lighting") {
            return ServiceContext(serviceKey: "outdoor_lighting_program", visitTypeKey: "lighting_service")
        }
        if normalized.contains("pest") || normalized.contains("termite") {
            return ServiceContext(serviceKey: "pest_and_termite_program", visitTypeKey: normalized.contains("termite") ? "termite_review" : "routine_pest_service")
        }
        if normalized.contains("mosquito") || normalized.contains("tick") {
            return ServiceContext(serviceKey: "mosquito_and_tick_program", visitTypeKey: "mosquito_tick_service")
        }
        if normalized.contains("snow") || normalized.contains("plowing") {
            return ServiceContext(serviceKey: "snow_and_ice_management_program", visitTypeKey: normalized.contains("renew") ? "season_setup" : "storm_response")
        }
        if normalized.contains("window washing") || normalized.contains("window cleaning") {
            return ServiceContext(serviceKey: "exterior_window_cleaning_program", visitTypeKey: "window_cleaning")
        }
        if normalized.contains("cleaning service") {
            return ServiceContext(serviceKey: "housekeeping_program", visitTypeKey: "routine_cleaning")
        }
        if normalized.contains("trash") || normalized.contains("recycling") || normalized.contains("compost") || normalized.contains("yard_waste") {
            let visitType: String = normalized.contains("recycl") ? "recycling_pickup" : (normalized.contains("compost") || normalized.contains("yard_waste") ? "organics_pickup" : "trash_pickup")
            return ServiceContext(serviceKey: "waste_program", visitTypeKey: visitType)
        }
        if normalized.contains("relamping") || normalized.contains("touch-up") || normalized.contains("hardware tune-up") {
            return ServiceContext(serviceKey: "concierge_tune_up", visitTypeKey: nil)
        }
        return ServiceContext(serviceKey: "custom_seasonal_service", visitTypeKey: nil)
    }

    private static func seasonal(
        key: String,
        title: String,
        vendor: String,
        cadence: String,
        legacy: [String],
        checklist: [String],
        proof: [String],
        exceptions: [String]
    ) -> ServiceDefinition {
        ServiceDefinition(
            serviceKey: key,
            serviceKind: .seasonalService,
            homeownerTitle: title,
            defaultRoutingStrategy: .vendorOnly,
            vendorCategory: vendor,
            cadenceOrTrigger: cadence,
            subtypeGates: [],
            regionalGates: [],
            visitTypes: [],
            checklistItems: checklist.enumerated().map { index, label in
                ServiceChecklistItem(key: "\(key)_check_\(index + 1)", label: label, homeownerVisible: false)
            },
            proofRequirements: proof.enumerated().map { index, label in
                ServiceProofRequirement(key: "\(key)_proof_\(index + 1)", label: label)
            },
            exceptionRules: exceptions.enumerated().map { index, label in
                ServiceExceptionRule(key: "\(key)_exception_\(index + 1)", trigger: label, outcome: "project_quote")
            },
            absorbedLegacyTemplateKeys: legacy,
            supportedRoutineKinds: [],
            homeownerVisibleByDefault: true
        )
    }

    private static func routine(
        key: String,
        title: String,
        vendor: String,
        cadence: String,
        visitTypes: [ServiceVisitType],
        routineKinds: [String],
        legacy: [String],
        checklist: [String],
        proof: [String],
        exceptions: [String]
    ) -> ServiceDefinition {
        ServiceDefinition(
            serviceKey: key,
            serviceKind: .routineProgram,
            homeownerTitle: title,
            defaultRoutingStrategy: .vendorProgram,
            vendorCategory: vendor,
            cadenceOrTrigger: cadence,
            subtypeGates: [],
            regionalGates: [],
            visitTypes: visitTypes,
            checklistItems: checklist.enumerated().map { index, label in
                ServiceChecklistItem(key: "\(key)_check_\(index + 1)", label: label, homeownerVisible: false)
            },
            proofRequirements: proof.enumerated().map { index, label in
                ServiceProofRequirement(key: "\(key)_proof_\(index + 1)", label: label)
            },
            exceptionRules: exceptions.enumerated().map { index, label in
                ServiceExceptionRule(key: "\(key)_exception_\(index + 1)", trigger: label, outcome: "project_quote")
            },
            absorbedLegacyTemplateKeys: legacy,
            supportedRoutineKinds: routineKinds,
            homeownerVisibleByDefault: true
        )
    }

    private static func handyman(
        key: String,
        title: String,
        legacy: [String],
        checklist: [String],
        proof: [String],
        exceptions: [String]
    ) -> ServiceDefinition {
        ServiceDefinition(
            serviceKey: key,
            serviceKind: .handymanProgram,
            homeownerTitle: title,
            defaultRoutingStrategy: .handymanDefault,
            vendorCategory: "Handyman",
            cadenceOrTrigger: "On-demand when one or more low-risk items are queued",
            subtypeGates: [],
            regionalGates: [],
            visitTypes: [
                visit("spring_prep", "Spring prep", cadence: "Annual", trigger: "Spring"),
                visit("fall_prep", "Fall prep", cadence: "Annual", trigger: "Fall"),
                visit("ad_hoc_visit", "Ad hoc visit", cadence: "On demand", trigger: "Whenever work accumulates")
            ],
            checklistItems: checklist.enumerated().map { index, label in
                ServiceChecklistItem(key: "\(key)_check_\(index + 1)", label: label, homeownerVisible: false)
            },
            proofRequirements: proof.enumerated().map { index, label in
                ServiceProofRequirement(key: "\(key)_proof_\(index + 1)", label: label)
            },
            exceptionRules: exceptions.enumerated().map { index, label in
                ServiceExceptionRule(key: "\(key)_exception_\(index + 1)", trigger: label, outcome: "re-route_or_project")
            },
            absorbedLegacyTemplateKeys: legacy,
            supportedRoutineKinds: [RoutineKind.handymanRecurring.rawValue],
            homeownerVisibleByDefault: true
        )
    }

    private static func concierge(
        key: String,
        title: String,
        vendor: String,
        cadence: String,
        legacy: [String],
        checklist: [String]
    ) -> ServiceDefinition {
        ServiceDefinition(
            serviceKey: key,
            serviceKind: .conciergeAddOn,
            homeownerTitle: title,
            defaultRoutingStrategy: .conciergeOnly,
            vendorCategory: vendor,
            cadenceOrTrigger: cadence,
            subtypeGates: [],
            regionalGates: [],
            visitTypes: [],
            checklistItems: checklist.enumerated().map { index, label in
                ServiceChecklistItem(key: "\(key)_check_\(index + 1)", label: label, homeownerVisible: false)
            },
            proofRequirements: [],
            exceptionRules: [],
            absorbedLegacyTemplateKeys: legacy,
            supportedRoutineKinds: [],
            homeownerVisibleByDefault: false
        )
    }

    private static func visit(
        _ key: String,
        _ label: String,
        cadence: String,
        trigger: String
    ) -> ServiceVisitType {
        ServiceVisitType(key: key, label: label, cadence: cadence, trigger: trigger)
    }
}

extension MaintenanceTaskDBRow {
    var resolvedServiceKey: String? {
        serviceKey ?? ServiceLibrary.serviceKey(for: self)
    }
}

extension MaintenanceTaskInsert {
    var resolvedServiceKey: String? {
        serviceKey ?? ServiceLibrary.serviceKey(for: self)
    }
}

extension RoutineRow {
    var resolvedServiceKey: String? {
        serviceKey ?? ServiceLibrary.serviceKey(for: self)
    }
}

extension RoutineInsert {
    var resolvedServiceKey: String? {
        serviceKey ?? ServiceLibrary.serviceKey(for: self)
    }
}

/// Shared maintenance-task routing helpers so Systems, task detail, and
/// maintenance views stay aligned about what belongs on the handyman list
/// and how service work should be recorded.
enum MaintenanceTaskRoutingSupport {
    private static func template(for task: MaintenanceTaskDBRow) -> MaintenanceTemplate? {
        guard let templateKey = task.templateId else { return nil }
        return MaintenanceTemplates.template(forKey: templateKey)
    }

    static func prefersVendorCoverage(_ task: MaintenanceTaskDBRow) -> Bool {
        if task.professionalRequired == true || task.needsVendor == true {
            return true
        }

        if task.assignmentType?.lowercased() == TaskAssignmentType.vendor.rawValue {
            return true
        }

        if let template = template(for: task) {
            if template.professionalRequired || template.assignmentType == .vendor || template.safetyFloor {
                return true
            }

            switch template.routing {
            case .vendorOnly, .vendorDefault, .bundledIntoParent:
                return true
            case .diyCapable, .diyDefault:
                break
            }
        }

        if let strategy = ServiceLibrary.serviceDefinition(for: task)?.defaultRoutingStrategy {
            switch strategy {
            case .vendorOnly, .vendorProgram, .conciergeOnly:
                return true
            case .vendorOrDIY, .handymanDefault:
                break
            }
        }

        let normalized = [task.title, task.notes, task.description]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        let vendorSignals = [
            "annual service",
            "service visit",
            "tune-up",
            "tune up",
            "inspection",
            "plumber",
            "electrician",
            "roofer",
            "hvac tech",
            "flush water heater",
            "t&p",
            "anode rod",
            "generator service",
            "chimney sweep",
            "well system"
        ]

        return vendorSignals.contains(where: normalized.contains)
    }

    static func isHandymanEligible(_ task: MaintenanceTaskDBRow) -> Bool {
        guard task.vehicleId == nil else { return false }
        guard !prefersVendorCoverage(task) else { return false }

        if ServiceLibrary.serviceDefinition(for: task)?.defaultRoutingStrategy == .handymanDefault {
            return true
        }

        let normalized = [task.title, task.notes, task.description]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        let keywordMatches = [
            "sensor batter",
            "smoke and co",
            "smoke & co",
            "gfci",
            "weatherstrip",
            "weather stripping",
            "caulk",
            "recaulk",
            "re-caulk",
            "touch-up",
            "touch up",
            "touch up paint",
            "hose bib",
            "door hardware",
            "door sweep",
            "window screen",
            "screen repair",
            "filter replacement",
            "replace filter",
            "light bulb",
            "outlet cover"
        ]
        if keywordMatches.contains(where: normalized.contains) {
            return true
        }

        if task.isDiy == true {
            return true
        }

        guard let template = template(for: task),
              let minutes = template.diyEffortMinutes else { return false }
        return minutes <= 90
    }

    static func isInlineHandymanEligible(_ task: MaintenanceTaskDBRow, systems: [HomeSystemRow]) -> Bool {
        guard isHandymanEligible(task) else { return false }
        guard task.assignedRoute != "handyman" else { return false }
        return resolvedContractorId(for: task, systems: systems) == nil
    }

    static func resolvedContractorId(for task: MaintenanceTaskDBRow, systems: [HomeSystemRow]) -> UUID? {
        if let assigned = task.assignedContractorId {
            return assigned
        }
        guard let systemId = task.systemId else { return nil }
        return systems.first(where: { $0.id == systemId })?.preferredContractorId
    }

    static func resolvedContractorId(for task: MaintenanceTaskDBRow, preferredContractorId: UUID?) -> UUID? {
        task.assignedContractorId ?? preferredContractorId
    }

    static func buildPunchItemInsert(for task: MaintenanceTaskDBRow) -> HandymanPunchItemInsert {
        var insert = HandymanPunchItemInsert(
            householdId: task.householdId,
            propertyId: task.propertyId,
            title: task.title
        )
        insert.description = task.description
        insert.source = "maintenance_task"
        insert.sourceTaskId = task.id
        if let templateKey = task.templateId,
           let template = MaintenanceTemplates.template(forKey: templateKey) {
            insert.estimatedMinutes = template.diyEffortMinutes
        }
        return insert
    }
}

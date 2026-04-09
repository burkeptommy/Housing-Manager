import Foundation

/// The 37-question House Quiz library, organized into 6 sections.
/// Phase 19b inserted q3b_hvac_type into section 1.
/// Phase 19j inserted q11b_lawn_type into section 3 and q28b_pets into section 6.
/// Phase 19m inserted q15b_household_contractors into section 3.
/// Build 87 inserted q12b_pool_chemistry into section 3 (right after q12_pool).
/// Build 86 inserted q25b_ev_charger into section 5 (right after q25_garage_ev)
/// and dropped the 1-car / 2-car granularity from q25 in favor of a single
/// "Attached" option plus a new "Semi-attached" option.
/// Build 87 (Edit 2) appended q36_diy_vs_vendor to section 6 — the new
/// `.slider` question kind that captures a 1-10 DIY vs vendor preference
/// and triggers a household-wide reconciler pass on commit.
/// Tom can edit copy here without touching view code.
enum HouseQuizQuestionLibrary {

    static let allQuestions: [HouseQuizQuestion] = section1 + section2 + section3 + section4 + section5 + section6

    static func question(byId id: String) -> HouseQuizQuestion? {
        allQuestions.first { $0.id == id }
    }

    /// Indices in `allQuestions` after which a milestone fun-fact card should appear.
    /// Triggered after the cumulative end-of-section index.
    /// Phase 19b: shifted by one for q3b_hvac_type in section 1.
    /// Phase 19j: shifted twice — once for q11b_lawn_type in section 3,
    /// and once for q28b_pets in section 6.
    /// Phase 19m: shifted again for q15b_household_contractors in section 3.
    /// Build 87: shifted once more for q12b_pool_chemistry in section 3,
    /// which adds one question to section 3 and bumps every subsequent
    /// milestone by +1.
    /// Build 86: shifted once more for q25b_ev_charger in section 5, which
    /// adds one question to section 5 and bumps the section 5 / section 6
    /// milestones by +1.
    /// Build 87 (Edit 2): appended q36_diy_vs_vendor to section 6, which
    /// adds one question to section 6 and bumps only the final milestone
    /// by +1 (every prior section is unaffected because the question lands
    /// at the end of the quiz).
    ///   Section 1: 6 questions → milestone after index 5
    ///   Section 2: 5 → cumulative 11 → milestone after index 10
    ///   Section 3: 8 → cumulative 19 → milestone after index 18
    ///   Section 4: 5 → cumulative 24 → milestone after index 23
    ///   Section 5: 6 → cumulative 30 → milestone after index 29
    ///   Section 6: 7 → cumulative 37 → milestone after index 36
    static let milestoneIndices: Set<Int> = [5, 10, 18, 23, 29, 36]

    // MARK: - Section 1 — Your Home Basics

    static let section1: [HouseQuizQuestion] = [
        HouseQuizQuestion(
            id: "q1_roof_material",
            section: .homeBasics,
            title: "What kind of roof do you have?",
            subtitle: "We'll set the right inspection cadence for your material.",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "asphalt", label: "Asphalt Shingle", icon: "house.fill"),
                AnswerOption(id: "metal", label: "Metal", icon: "square.grid.3x3.fill"),
                AnswerOption(id: "tile", label: "Tile", icon: "square.fill"),
                AnswerOption(id: "slate", label: "Slate", icon: "rectangle.fill"),
                AnswerOption(id: "wood_shake", label: "Wood Shake", icon: "leaf.fill"),
                AnswerOption(id: "flat_membrane", label: "Flat Membrane", icon: "rectangle.fill"),
                AnswerOption(id: "not_sure", label: "Not sure", icon: "questionmark.circle"),
            ]
        ),
        HouseQuizQuestion(
            id: "q2_siding",
            section: .homeBasics,
            title: "What's your exterior siding?",
            subtitle: "Some materials need yearly attention, others just once a decade.",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "vinyl", label: "Vinyl"),
                AnswerOption(id: "wood", label: "Wood"),
                AnswerOption(id: "brick", label: "Brick"),
                AnswerOption(id: "stucco", label: "Stucco"),
                AnswerOption(id: "fiber_cement", label: "Fiber Cement"),
                AnswerOption(id: "stone", label: "Stone"),
                AnswerOption(id: "mixed", label: "Mixed"),
            ]
        ),
        HouseQuizQuestion(
            id: "q3_heating_fuel",
            section: .homeBasics,
            title: "How do you heat your home?",
            subtitle: "We use this to schedule fuel deliveries and tank inspections.",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "natural_gas", label: "Natural Gas", icon: "flame.fill"),
                AnswerOption(id: "oil", label: "Oil", icon: "fuelpump.fill"),
                AnswerOption(id: "electric", label: "Electric", icon: "bolt.fill"),
                AnswerOption(id: "propane", label: "Propane", icon: "flame"),
                AnswerOption(id: "geothermal", label: "Geothermal", icon: "thermometer.sun.fill"),
                AnswerOption(id: "not_sure", label: "Not sure"),
            ]
        ),
        // Phase 19b: dedicated HVAC system-type question. The fuel answer in q3
        // does not uniquely determine HVAC configuration (a gas home can have
        // central + mini-split, an oil home can have boiler + window units),
        // so we ask directly here and let the answer drive the maintenance
        // template selection instead of guessing from the fuel.
        HouseQuizQuestion(
            id: "q3b_hvac_type",
            section: .homeBasics,
            title: "What kind of HVAC system?",
            subtitle: "We use this to set the right maintenance schedule for your specific setup.",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "central_ducted", label: "Central AC + furnace", icon: "wind"),
                AnswerOption(id: "mini_split", label: "Mini-split / ductless", icon: "fan"),
                AnswerOption(id: "boiler_with_central_ac", label: "Boiler + central AC", icon: "thermometer.snowflake"),
                AnswerOption(id: "boiler_radiant", label: "Boiler / radiators (no AC)", icon: "drop.degreesign"),
                AnswerOption(id: "boiler_with_window_ac", label: "Boiler + window AC units", icon: "wind"),
                AnswerOption(id: "heat_pump", label: "Heat pump (one system)", icon: "thermometer.medium"),
                AnswerOption(id: "geothermal", label: "Geothermal", icon: "leaf"),
                AnswerOption(id: "not_sure", label: "Not sure"),
            ]
        ),
        HouseQuizQuestion(
            id: "q4_purchase",
            section: .homeBasics,
            title: "How did you get this home?",
            subtitle: "Add a purchase price if you have it. We'll use it for your investment dashboard.",
            kind: .currency,
            answerOptions: [
                AnswerOption(id: "bought", label: "Bought existing"),
                AnswerOption(id: "custom_build", label: "Custom build"),
                AnswerOption(id: "inherited", label: "Inherited"),
                AnswerOption(id: "other", label: "Other"),
            ],
            documentUploadCategory: .mortgage
        ),
        HouseQuizQuestion(
            id: "q5_mortgage",
            section: .homeBasics,
            title: "Do you have a mortgage on this home?",
            subtitle: "We'll surface refinance opportunities when rates move.",
            kind: .yesNoLender,
            answerOptions: [
                AnswerOption(id: "yes", label: "Yes"),
                AnswerOption(id: "no", label: "No, paid off"),
                AnswerOption(id: "skip", label: "Prefer not to say"),
            ]
        ),
    ]

    // MARK: - Section 2 — Inside Your Home

    static let section2: [HouseQuizQuestion] = [
        HouseQuizQuestion(
            id: "q6_water_source",
            section: .inside,
            title: "Where does your water come from?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "municipal", label: "Municipal", icon: "drop.fill"),
                AnswerOption(id: "private_well", label: "Private well", icon: "drop.triangle.fill"),
                AnswerOption(id: "shared_well", label: "Shared well", icon: "drop.circle.fill"),
                AnswerOption(id: "not_sure", label: "Not sure", icon: "questionmark.circle"),
            ]
        ),
        HouseQuizQuestion(
            id: "q7_sewer_septic",
            section: .inside,
            title: "Sewer or septic?",
            subtitle: "Septic systems need pumping every 3-5 years.",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "sewer", label: "Municipal sewer"),
                AnswerOption(id: "septic", label: "Septic", icon: "arrow.down.to.line"),
                AnswerOption(id: "not_sure", label: "Not sure"),
            ]
        ),
        HouseQuizQuestion(
            id: "q8_water_heater",
            section: .inside,
            title: "What kind of water heater do you have?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "tank_gas", label: "Tank, gas"),
                AnswerOption(id: "tank_electric", label: "Tank, electric"),
                AnswerOption(id: "tankless_gas", label: "Tankless, gas"),
                AnswerOption(id: "tankless_electric", label: "Tankless, electric"),
                AnswerOption(id: "heat_pump", label: "Heat pump"),
                AnswerOption(id: "not_sure", label: "Not sure"),
            ]
        ),
        HouseQuizQuestion(
            id: "q9_basement",
            section: .inside,
            title: "Do you have a basement or crawl space?",
            subtitle: "Pick all that apply.",
            kind: .multiSelect,
            answerOptions: [
                AnswerOption(id: "finished_basement", label: "Finished basement"),
                AnswerOption(id: "unfinished_basement", label: "Unfinished basement"),
                AnswerOption(id: "crawl_space", label: "Crawl space"),
                AnswerOption(id: "slab", label: "Slab"),
                AnswerOption(id: "not_sure", label: "Not sure"),
            ]
        ),
        HouseQuizQuestion(
            id: "q10_appliances",
            section: .inside,
            title: "Which major appliances do you have?",
            subtitle: "We'll track manuals, maintenance, and recalls for each, and let you know when anything is still under warranty.",
            kind: .multiSelect,
            answerOptions: [
                AnswerOption(id: "refrigerator", label: "Refrigerator", icon: "refrigerator.fill"),
                AnswerOption(id: "dishwasher", label: "Dishwasher"),
                AnswerOption(id: "range", label: "Range / cooktop"),
                AnswerOption(id: "wall_oven", label: "Wall oven", icon: "oven.fill"),
                AnswerOption(id: "washer", label: "Washer", icon: "washer.fill"),
                AnswerOption(id: "dryer", label: "Dryer"),
                AnswerOption(id: "microwave", label: "Microwave"),
                AnswerOption(id: "wine_fridge", label: "Wine fridge"),
                AnswerOption(id: "other", label: "Other", icon: "plus.circle", acceptsCustomInput: true),
                AnswerOption(id: "none", label: "None of these"),
            ],
            documentUploadCategory: .applianceManual,
            supportsSelectAll: true
        ),
    ]

    // MARK: - Section 3 — Outside & Landscaping

    static let section3: [HouseQuizQuestion] = [
        HouseQuizQuestion(
            id: "q11_lawn",
            section: .outside,
            title: "Do you have a lawn?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "diy", label: "Yes, I maintain it"),
                AnswerOption(id: "pro", label: "Yes, pro service"),
                AnswerOption(id: "no_lawn", label: "No"),
                AnswerOption(id: "garden", label: "Mostly garden"),
                AnswerOption(id: "hardscape", label: "Mostly hardscape (patio, gravel, pavers)", icon: "square.grid.3x3.fill"),
            ],
            providerFollowUpAnswerIds: ["pro"],
            providerTypes: ["landscaping"]
        ),
        // Phase 19j — lawn type. Inserted right after q11_lawn so a turf
        // homeowner gets the right maintenance schedule (brushing, infill,
        // drainage) instead of a natural-grass schedule (aerate, overseed,
        // fertilize). Mixed yards get both.
        //
        // Skipped when Q11 said "no_lawn" or "garden" — there's no lawn to
        // ask about the type of.
        HouseQuizQuestion(
            id: "q11b_lawn_type",
            section: .outside,
            title: "Natural grass, turf, or both?",
            subtitle: "We'll set up the right care schedule for what you actually have.",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "natural", label: "Natural grass", icon: "leaf.fill"),
                AnswerOption(id: "turf", label: "Synthetic turf", icon: "square.grid.3x3.fill"),
                AnswerOption(id: "mixed", label: "Mixed (both)", icon: "circle.lefthalf.filled"),
                AnswerOption(id: "not_sure", label: "Not sure"),
            ],
            dynamicSkip: { state in
                let q11 = state.answers["q11_lawn"]?.answerId
                return q11 == "no_lawn" || q11 == "garden" || q11 == "hardscape"
            }
        ),
        HouseQuizQuestion(
            id: "q12_pool",
            section: .outside,
            title: "Pool or hot tub?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "in_ground", label: "In-ground pool"),
                AnswerOption(id: "above_ground", label: "Above-ground"),
                AnswerOption(id: "hot_tub", label: "Hot tub only"),
                AnswerOption(id: "both", label: "Both"),
                AnswerOption(id: "none", label: "None"),
            ],
            providerFollowUpAnswerIds: ["in_ground", "above_ground", "hot_tub", "both"],
            providerTypes: ["pool_service"]
        ),
        // Build 87: pool chemistry follow-up. Mirrors the Q11/Q11b pattern:
        // Q12 captures the pool TYPE, Q12b captures the chemistry. This
        // fixes the pre-existing dead-code bug in the q12_pool handler
        // where the `poolSubtype` switch was looking for "saltwater" /
        // "chlorine" answer IDs that Q12 never produced (its actual IDs
        // are in_ground / above_ground / hot_tub / both / none). Now the
        // reconciler gets a real subtype so templates gated on
        // `requiredSubtypes: ["pool_salt"]` or `["pool_chlorine"]`
        // actually land.
        HouseQuizQuestion(
            id: "q12b_pool_chemistry",
            section: .outside,
            title: "Saltwater or chlorine?",
            subtitle: "We'll set up the right care schedule for your pool's chemistry.",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "saltwater", label: "Saltwater", icon: "drop.circle.fill"),
                AnswerOption(id: "chlorine", label: "Chlorine", icon: "testtube.2"),
                AnswerOption(id: "not_sure", label: "Not sure"),
            ],
            dynamicSkip: { state in
                // Skip for pool answers that don't have meaningful chemistry
                // choices: hot_tub (different chemistry entirely) and none
                // (no pool). Only in_ground, above_ground, and both have
                // saltwater-vs-chlorine as a real decision.
                let q12 = state.answers["q12_pool"]?.answerId
                return q12 != "in_ground"
                    && q12 != "above_ground"
                    && q12 != "both"
            }
        ),
        HouseQuizQuestion(
            id: "q13_pest",
            section: .outside,
            title: "Pest control?",
            kind: .singleChoice,
            answerOptions: [
                // Build 86: label changed from "Quarterly pro service" to
                // "Recurring pro service" since real pest-control contracts
                // range from monthly to quarterly depending on region/
                // vendor. The `id` stays "quarterly_pro" so persisted
                // answers and back-navigation continue to round-trip.
                AnswerOption(id: "quarterly_pro", label: "Recurring pro service"),
                AnswerOption(id: "termite_bond", label: "Termite bond"),
                AnswerOption(id: "diy", label: "DIY"),
                AnswerOption(id: "none", label: "None"),
            ],
            providerFollowUpAnswerIds: ["quarterly_pro", "termite_bond"],
            providerTypes: ["pest_control"]
        ),
        HouseQuizQuestion(
            id: "q14_irrigation",
            section: .outside,
            title: "Sprinkler or irrigation?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "full", label: "Yes, full system"),
                AnswerOption(id: "drip", label: "Drip only"),
                AnswerOption(id: "no", label: "No"),
            ],
            providerFollowUpAnswerIds: ["full", "drip"],
            providerTypes: ["irrigation"],
            // Phase 19j — skip irrigation entirely when the user has no
            // lawn AND their lawn (if any) is pure synthetic turf. A
            // turf-only home with no garden has nothing to water. Mixed,
            // natural, and garden households still see the question.
            dynamicSkip: { state in
                let q11 = state.answers["q11_lawn"]?.answerId
                let q11b = state.answers["q11b_lawn_type"]?.answerId
                if q11 == "no_lawn" { return true }
                // Lawn = "diy" or "pro" but it's pure synthetic turf and
                // the user explicitly said no garden in Q11 — skip.
                if q11b == "turf" && (q11 == "diy" || q11 == "pro") {
                    // Conservative: still ask in case they have garden beds
                    // separate from the lawn area. Only auto-skip when q11
                    // was explicitly no_lawn.
                    return false
                }
                return false
            }
        ),
        HouseQuizQuestion(
            id: "q15_security",
            section: .outside,
            title: "Security or alarm system?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "monitored", label: "Yes, monitored"),
                AnswerOption(id: "self_monitored", label: "Yes, self-monitored"),
                AnswerOption(id: "cameras_only", label: "Cameras only"),
                AnswerOption(id: "none", label: "None"),
            ],
            providerFollowUpAnswerIds: ["monitored"],
            providerTypes: ["security"]
        ),
        // Phase 19m — household contractors. One screen captures the user's
        // existing pros (HVAC, plumber, electrician, etc.) so future task
        // creation can route to the right vendor up front instead of falling
        // back to "find a contractor" placeholders. The view filters chips
        // dynamically: septic only when q7 said septic, well only when q6
        // said well, chimney only when fireplace/wood/propane fireplace
        // appears in q10 or q20. Skipping the question entirely is allowed.
        HouseQuizQuestion(
            id: "q15b_household_contractors",
            section: .outside,
            title: "Got any pros on speed dial?",
            subtitle: "Tell us who handles your HVAC, plumbing, electrical, and other home services so we can plan tasks around their schedule, not yours.",
            kind: .householdContractors,
            answerOptions: [
                AnswerOption(id: "hvac_service", label: "HVAC service", icon: "thermometer.medium"),
                AnswerOption(id: "plumber", label: "Plumber", icon: "drop.fill"),
                AnswerOption(id: "electrician", label: "Electrician", icon: "bolt.fill"),
                AnswerOption(id: "roofer", label: "Roofer", icon: "house.fill"),
                AnswerOption(id: "septic_pumper", label: "Septic pumper", icon: "circle.dashed"),
                AnswerOption(id: "well_water_service", label: "Well water service", icon: "drop.degreesign"),
                AnswerOption(id: "chimney_sweep", label: "Chimney sweep", icon: "flame.fill"),
                AnswerOption(id: "tree_service", label: "Tree service", icon: "tree.fill"),
                AnswerOption(id: "handyman", label: "Handyman", icon: "wrench.fill"),
            ],
            dynamicSkip: { _ in false }  // never skip — empty answers are allowed
        ),
    ]

    // MARK: - Section 4 — Energy & Services

    static let section4: [HouseQuizQuestion] = [
        HouseQuizQuestion(
            id: "q16_electric",
            section: .energyServices,
            title: "Who's your electric provider?",
            kind: .providerSearch,
            documentUploadCategory: .utilityBill,
            providerTypes: ["electric"]
        ),
        HouseQuizQuestion(
            id: "q17_internet",
            section: .energyServices,
            title: "Internet provider?",
            kind: .providerSearch,
            documentUploadCategory: .utilityBill,
            providerTypes: ["internet_cable"]
        ),
        HouseQuizQuestion(
            id: "q18_trash",
            section: .energyServices,
            title: "Trash & recycling?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "municipal", label: "Municipal"),
                AnswerOption(id: "private", label: "Private hauler"),
                AnswerOption(id: "not_sure", label: "Not sure"),
            ],
            providerFollowUpAnswerIds: ["private"],
            providerTypes: ["trash"]
        ),
        HouseQuizQuestion(
            id: "q19_heating_provider",
            section: .energyServices,
            title: "Heating fuel provider?",
            subtitle: "We'll match this to your refill cadence.",
            kind: .providerSearch,
            documentUploadCategory: .utilityBill,
            providerTypes: ["oil", "propane", "natural_gas"],
            // Phase 18b: narrow the picker to just the fuel type the user
            // confirmed in Q3. Returning [] tells the view model to skip the
            // question entirely (electric / geothermal homes have no fuel
            // delivery contract — they're already covered by Q16 electric).
            dynamicProviderTypes: { state in
                guard let fuel = state.answers["q3_heating_fuel"]?.answerId else {
                    // Q3 unanswered — keep the original three-type behavior so
                    // a forward-resumed quiz still shows something useful.
                    return ["oil", "propane", "natural_gas"]
                }
                switch fuel {
                case "oil":         return ["oil"]
                case "propane":     return ["propane"]
                case "natural_gas": return ["natural_gas"]
                // electric, geothermal, not_sure — no separate fuel provider
                default:            return []
                }
            }
        ),
        HouseQuizQuestion(
            id: "q20_other_fuels",
            section: .energyServices,
            title: "Any other fuel sources?",
            // Phase 19i: generator moved to Q22's dedicated inline form so
            // we can capture its fuel type and provider separately. Q20 now
            // covers fireplace + stove + wood + pellets only.
            subtitle: "Propane for the fireplace or stove? Wood or pellets? If it's only for a generator, skip it here, we'll ask next.",
            kind: .multiSelect,
            answerOptions: [
                AnswerOption(id: "propane_fireplace", label: "Propane (fireplace)"),
                AnswerOption(id: "propane_stove", label: "Propane (stove)"),
                AnswerOption(id: "wood_logs", label: "Wood (cordwood)"),
                AnswerOption(id: "wood_pellets", label: "Wood pellets"),
                AnswerOption(id: "none", label: "None"),
            ]
        ),
    ]

    // MARK: - Section 5 — Backup, Vehicles & Garage

    static let section5: [HouseQuizQuestion] = [
        HouseQuizQuestion(
            id: "q21_solar",
            section: .backupEnergy,
            title: "Solar panels?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "owned", label: "Yes, owned", icon: "sun.max.fill"),
                AnswerOption(id: "leased", label: "Yes, leased"),
                AnswerOption(id: "no", label: "No"),
                AnswerOption(id: "considering", label: "Considering"),
            ]
        ),
        HouseQuizQuestion(
            id: "q22_generator",
            section: .backupEnergy,
            title: "Whole-home generator?",
            // Phase 19i: dedicated inline form. Captures generator type +
            // fuel + provider in one screen so we can correctly model
            // households with a different fuel/provider for backup vs HVAC.
            subtitle: "Tell us the type, fuel, and supplier so we can plan refills and load tests. Separate from your home heating fuel, so we track it as its own account.",
            kind: .generatorAdd,
            answerOptions: [
                AnswerOption(id: "whole_home", label: "Whole-home", icon: "powerplug.fill"),
                AnswerOption(id: "portable", label: "Portable", icon: "bolt.fill"),
                AnswerOption(id: "none", label: "None", icon: "minus.circle"),
            ]
        ),
        HouseQuizQuestion(
            id: "q23_vehicle_count",
            section: .vehicles,
            title: "How many cars do you own?",
            kind: .vehicleCount,
            answerOptions: [
                AnswerOption(id: "0", label: "0"),
                AnswerOption(id: "1", label: "1"),
                AnswerOption(id: "2", label: "2"),
                AnswerOption(id: "3", label: "3"),
                AnswerOption(id: "4_plus", label: "4+"),
            ]
        ),
        HouseQuizQuestion(
            id: "q24_vehicle_add",
            section: .vehicles,
            title: "Add your primary car",
            subtitle: "Type, scan, or upload an insurance card.",
            kind: .vehicleAdd,
            documentUploadCategory: .autoInsurance
        ),
        HouseQuizQuestion(
            id: "q25_garage_ev",
            section: .vehicles,
            title: "What kind of garage do you have?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "attached", label: "Attached", icon: "house.fill"),
                AnswerOption(id: "semi_attached", label: "Semi-attached", icon: "house.lodge.fill"),
                AnswerOption(id: "detached", label: "Detached", icon: "building.2.fill"),
                AnswerOption(id: "carport", label: "Carport", icon: "car.side.fill"),
                AnswerOption(id: "none", label: "No garage", icon: "minus.circle"),
            ]
        ),
        // Build 86: split EV charger into its own yes/no question. Tom's
        // feedback was that the prior single-question structure made garage
        // type and EV charger mutually exclusive — a user with an attached
        // garage AND an L2 charger had to pick one. The dynamicSkip closure
        // hides this question entirely when the user said "No garage" in Q25.
        HouseQuizQuestion(
            id: "q25b_ev_charger",
            section: .vehicles,
            title: "Do you have a Level 2 EV charger?",
            subtitle: "We'll track your charger and any EV-related maintenance.",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "yes", label: "Yes, I have an L2 charger", icon: "bolt.car.fill"),
                AnswerOption(id: "no", label: "No EV charger", icon: "minus.circle"),
            ],
            dynamicSkip: { state in
                state.answers["q25_garage_ev"]?.answerId == "none"
            }
        ),
    ]

    // MARK: - Section 6 — Protection & People

    static let section6: [HouseQuizQuestion] = [
        HouseQuizQuestion(
            id: "q26_auto_insurance",
            section: .protectionPeople,
            title: "Auto insurance provider?",
            kind: .providerSearch,
            documentUploadCategory: .autoInsurance,
            providerTypes: ["auto_insurance"]
        ),
        HouseQuizQuestion(
            id: "q27_homeowners_insurance",
            section: .protectionPeople,
            title: "Homeowners insurance provider?",
            kind: .providerSearch,
            documentUploadCategory: .homeownersInsurance,
            // Phase 16b: standardize on "home_insurance" so the token lines up
            // with the seeded utility_providers rows from Phase 16a.
            providerTypes: ["home_insurance"]
        ),
        HouseQuizQuestion(
            id: "q28_household",
            section: .protectionPeople,
            title: "Who lives here, and who else helps?",
            subtitle: "Tell us about residents and any caretakers in the household.",
            kind: .caretakers,
            answerOptions: [
                AnswerOption(id: "just_me", label: "Just me"),
                AnswerOption(id: "couple", label: "Couple"),
                AnswerOption(id: "family_with_kids", label: "Family with kids"),
                AnswerOption(id: "multi_generational", label: "Multi-generational"),
                AnswerOption(id: "other", label: "Other"),
            ]
        ),
        // Phase 19j — pets in the household. Drives subtype-specific tasks
        // like the synthetic-turf "Sanitize pet areas" template (only fires
        // for households with pets) and future pet-aware features (pet door
        // installation, allergen filters, fenced-yard reminders).
        HouseQuizQuestion(
            id: "q28b_pets",
            section: .protectionPeople,
            title: "Any pets in the household?",
            subtitle: "We tune some maintenance tasks (like turf sanitization and HVAC filter swaps) based on this.",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "dogs", label: "Dogs", icon: "pawprint.fill"),
                AnswerOption(id: "cats", label: "Cats", icon: "cat.fill"),
                AnswerOption(id: "both", label: "Dogs and cats", icon: "pawprint.circle.fill"),
                AnswerOption(id: "other_pets", label: "Other pets"),
                AnswerOption(id: "no_pets", label: "No pets"),
            ]
        ),
        HouseQuizQuestion(
            id: "q29_estate_docs",
            section: .protectionPeople,
            title: "Estate documents you have on hand?",
            kind: .multiSelect,
            answerOptions: [
                AnswerOption(id: "will", label: "Will"),
                AnswerOption(id: "trust", label: "Trust"),
                AnswerOption(id: "poa", label: "Power of attorney"),
                AnswerOption(id: "healthcare", label: "Healthcare directive"),
                AnswerOption(id: "none", label: "None yet"),
            ],
            documentUploadCategory: .will
        ),
        HouseQuizQuestion(
            id: "q30_priorities",
            section: .protectionPeople,
            title: "What matters most? What worries you most?",
            kind: .multiSelect,
            answerOptions: [
                AnswerOption(id: "save_money", label: "Saving money"),
                AnswerOption(id: "avoid_emergencies", label: "Avoiding emergencies"),
                AnswerOption(id: "resale", label: "Resale value"),
                AnswerOption(id: "sustainability", label: "Sustainability"),
                AnswerOption(id: "family_safety", label: "Family safety"),
                AnswerOption(id: "hidden_problems", label: "Hidden problems"),
                AnswerOption(id: "surprise_costs", label: "Surprise costs"),
                AnswerOption(id: "good_contractors", label: "Finding good contractors"),
            ]
        ),
        // Build 87: Q36 DIY vs Vendor preference slider. Sits at the very
        // end of the quiz so the reconciler can re-balance every existing
        // `either`-tagged task in one shot when the user commits. Settings
        // → Preferences exposes the same control via a shared component
        // (`VendorPreferenceSlider`) so the user can change it later
        // without retaking the quiz.
        HouseQuizQuestion(
            id: "q36_diy_vs_vendor",
            section: .protectionPeople,
            title: "How hands-on do you want to be?",
            subtitle: "Slide right to let us manage more with vendors. Slide left to do more yourself. You can change this anytime in Settings.",
            kind: .slider,
            sliderMin: 1,
            sliderMax: 10,
            sliderLeftLabel: "DIY everything",
            sliderRightLabel: "Let pros handle it"
        ),
    ]
}

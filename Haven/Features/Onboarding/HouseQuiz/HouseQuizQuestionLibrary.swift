import Foundation

/// The 30-question House Quiz library, organized into 6 sections of 5.
/// Tom can edit copy here without touching view code.
enum HouseQuizQuestionLibrary {

    static let allQuestions: [HouseQuizQuestion] = section1 + section2 + section3 + section4 + section5 + section6

    static func question(byId id: String) -> HouseQuizQuestion? {
        allQuestions.first { $0.id == id }
    }

    /// Indices in `allQuestions` after which a milestone fun-fact card should appear.
    /// Triggered after questions 5, 10, 15, 20, 25, 30 — the section boundaries.
    static let milestoneIndices: Set<Int> = [4, 9, 14, 19, 24, 29]

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
                AnswerOption(id: "shared_well", label: "Shared well"),
                AnswerOption(id: "not_sure", label: "Not sure"),
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
                AnswerOption(id: "tank_gas", label: "Tank — gas"),
                AnswerOption(id: "tank_electric", label: "Tank — electric"),
                AnswerOption(id: "tankless_gas", label: "Tankless — gas"),
                AnswerOption(id: "tankless_electric", label: "Tankless — electric"),
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
            title: "Which appliances are under 5 years old?",
            subtitle: "Pick any that still have warranties we should track.",
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
            documentUploadCategory: .applianceManual
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
                AnswerOption(id: "diy", label: "Yes — I maintain it"),
                AnswerOption(id: "pro", label: "Yes — pro service"),
                AnswerOption(id: "no_lawn", label: "No"),
                AnswerOption(id: "garden", label: "Mostly garden"),
            ],
            providerFollowUpAnswerIds: ["pro"],
            providerTypes: ["landscaping"]
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
        HouseQuizQuestion(
            id: "q13_pest",
            section: .outside,
            title: "Pest control?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "quarterly_pro", label: "Quarterly pro service"),
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
                AnswerOption(id: "full", label: "Yes — full system"),
                AnswerOption(id: "drip", label: "Drip only"),
                AnswerOption(id: "no", label: "No"),
            ],
            providerFollowUpAnswerIds: ["full", "drip"],
            providerTypes: ["irrigation"]
        ),
        HouseQuizQuestion(
            id: "q15_security",
            section: .outside,
            title: "Security or alarm system?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "monitored", label: "Yes — monitored"),
                AnswerOption(id: "self_monitored", label: "Yes — self-monitored"),
                AnswerOption(id: "cameras_only", label: "Cameras only"),
                AnswerOption(id: "none", label: "None"),
            ],
            providerFollowUpAnswerIds: ["monitored"],
            providerTypes: ["security"]
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
            providerTypes: ["oil", "propane", "natural_gas"]
        ),
        HouseQuizQuestion(
            id: "q20_other_fuels",
            section: .energyServices,
            title: "Any other fuel sources?",
            subtitle: "Propane for the generator, the fireplace, the stove?",
            kind: .multiSelect,
            answerOptions: [
                AnswerOption(id: "propane_generator", label: "Propane (generator)"),
                AnswerOption(id: "propane_fireplace", label: "Propane (fireplace)"),
                AnswerOption(id: "propane_stove", label: "Propane (stove)"),
                AnswerOption(id: "wood", label: "Wood"),
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
                AnswerOption(id: "owned", label: "Yes — owned", icon: "sun.max.fill"),
                AnswerOption(id: "leased", label: "Yes — leased"),
                AnswerOption(id: "no", label: "No"),
                AnswerOption(id: "considering", label: "Considering"),
            ]
        ),
        HouseQuizQuestion(
            id: "q22_generator",
            section: .backupEnergy,
            title: "Whole-home generator?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "whole_home", label: "Whole-home", icon: "powerplug.fill"),
                AnswerOption(id: "portable", label: "Portable"),
                AnswerOption(id: "none", label: "None"),
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
            title: "Garage type? EV charger?",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "attached_2", label: "Attached 2-car"),
                AnswerOption(id: "attached_1", label: "Attached 1-car"),
                AnswerOption(id: "detached", label: "Detached"),
                AnswerOption(id: "carport", label: "Carport"),
                AnswerOption(id: "none", label: "No garage"),
                AnswerOption(id: "ev_l2", label: "I have an EV charger (L2)", icon: "bolt.car.fill"),
            ]
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
            providerTypes: ["homeowners_insurance"]
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
    ]
}

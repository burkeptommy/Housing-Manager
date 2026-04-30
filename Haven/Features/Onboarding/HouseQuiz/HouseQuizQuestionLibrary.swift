import Foundation

/// The 37-question House Quiz library, organized into 6 sections.
/// Phase 19b inserted q3b_hvac_type into section 1.
/// Phase 19j inserted q11b_lawn_type into section 3 and q28b_pets into section 6.
/// Phase 19m inserted q15b_household_contractors into section 3.
/// Build 87 inserted q12b_pool_chemistry into section 3 (right after q12_pool).
/// Build 86 inserted q25b_ev_charger into section 5 (right after q25_garage_ev)
/// and dropped the 1-car / 2-car granularity from q25 in favor of a single
/// "Attached" option plus a new "Semi-attached" option.
/// Build 87 (Edit 2) appended q36_diy_vs_vendor to section 6.
/// Build 88 converted q36_diy_vs_vendor from `.slider` to `.singleChoice`
/// with 3 tiers (diy / mixed / hire_out) replacing the 1-10 slider.
/// Tom can edit copy here without touching view code.
enum HouseQuizQuestionLibrary {
    private static let monthSelectionOptions: [AnswerOption] = [
        AnswerOption(id: "jan", label: "January"),
        AnswerOption(id: "feb", label: "February"),
        AnswerOption(id: "mar", label: "March"),
        AnswerOption(id: "apr", label: "April"),
        AnswerOption(id: "may", label: "May"),
        AnswerOption(id: "jun", label: "June"),
        AnswerOption(id: "jul", label: "July"),
        AnswerOption(id: "aug", label: "August"),
        AnswerOption(id: "sep", label: "September"),
        AnswerOption(id: "oct", label: "October"),
        AnswerOption(id: "nov", label: "November"),
        AnswerOption(id: "dec", label: "December"),
    ]

    private static func hasProviderContext(_ answer: HouseQuizAnswer?) -> Bool {
        guard let answer else { return false }
        if answer.selectedProviderId != nil {
            return true
        }
        let trimmed = answer.customText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !trimmed.isEmpty
    }

    /// Phase 60.3: quiz now renders in chapter order rather than section
    /// order. The chapter grouping was introduced in Phase 60.3 as a
    /// higher-order abstraction above section — sections still exist for
    /// legacy reasons (UI section-header rendering in older flows), but
    /// `allQuestions` reflects the chapter flow.
    ///
    /// Chapter 1 "Your Home" (14 questions):
    ///   Section 1 (Q1-Q5) + Section 2 (Q6-Q10) + homeSystemsQuestions (Q20, Q21, Q22)
    ///
    /// Chapter 2 "Your Pros" (9 questions):
    ///   Q36 preference tier (MOVED from end of quiz to chapter opener so
    ///   it runs BEFORE Q11/Q13/Q14/Q15 vendor branches — reconciler
    ///   needs the tier set before those questions persist `.either`
    ///   tasks) + Section 3 (Q11-Q15b)
    ///
    /// Chapter 3 "Your People" (14 questions):
    ///   providerQuestions (Q16-Q19) + vehiclesQuestions (Q23-Q25b) +
    ///   insuranceQuestions (Q26-Q27) + peopleQuestions (Q28-Q30 minus Q36)
    static let allQuestions: [HouseQuizQuestion] = {
        // Carve the original section 4 / 5 / 6 into chapter-aligned
        // sub-arrays without mutating the legacy static definitions —
        // the lookup `question(byId:)` keeps working on the whole set.
        let section4Providers = section4.filter { $0.id != "q20_other_fuels" }
        let section4HomeSystems = section4.filter { $0.id == "q20_other_fuels" }
        let section5HomeSystems = section5.filter {
            $0.id == "q21_solar" || $0.id == "q22_generator"
        }
        let section5Vehicles = section5.filter {
            $0.id != "q21_solar" && $0.id != "q22_generator"
        }
        let section6Tier = section6.filter { $0.id == "q36_diy_vs_vendor" }
        let section6Insurance = section6.filter {
            $0.id == "q26_auto_insurance" || $0.id == "q27_homeowners_insurance"
        }
        let section6People = section6.filter {
            $0.id != "q36_diy_vs_vendor"
                && $0.id != "q26_auto_insurance"
                && $0.id != "q27_homeowners_insurance"
        }

        return section1
            + section2
            + section4HomeSystems       // Q20 fits Chapter 1 — home systems
            + section5HomeSystems       // Q21/Q22 — solar + generator
            + section6Tier              // Q36 MOVED: opens Chapter 2
            + section3                  // Q11-Q15b outside pros
            + section4Providers         // Q16-Q19 utility providers
            + section5Vehicles          // Q23-Q25b
            + section6Insurance         // Q26-Q27
            + section6People            // Q28-Q30
    }()

    static func question(byId id: String) -> HouseQuizQuestion? {
        allQuestions.first { $0.id == id }
    }

    /// Phase 60.3: All questions in a given chapter, preserving the
    /// `allQuestions` order.
    static func questions(in chapter: HouseQuizChapter) -> [HouseQuizQuestion] {
        allQuestions.filter { $0.chapter == chapter }
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
    ///
    /// Phase 60.3: These indices refer to POSITIONS in `allQuestions` as
    /// it was before the chapter restructure. The chapter intro card now
    /// carries the section-transition moment (intro appears at chapter
    /// boundaries) so these legacy milestones are NO LONGER consulted —
    /// the set is kept for backward-compat with any persisted state that
    /// still references them. `HouseQuizViewModel.isAtMilestone` now
    /// returns false for every index so the old milestone card never
    /// fires alongside the new chapter intros.
    static let milestoneIndices: Set<Int> = []

    // MARK: - Section 1 — Your Home Basics

    static let section1: [HouseQuizQuestion] = [
        HouseQuizQuestion(
            id: "q1_roof_material",
            section: .homeBasics,
            title: "Your {yearBuilt} {street} roof: what's on top?",
            fallbackTitle: "What kind of roof do you have?",
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
        // Phase 67D (A3): Q3 + Q3b merged into a single fuel+system combo
        // picker. Eliminates the "fuel only" → "what kind of system" two-step
        // and uses the 12 combinations that cover ~95% of HNW homes. The
        // mapper stamps both `heating_fuel` and `hvac_type` attributes from
        // the chosen combo so existing template gating continues to fire.
        HouseQuizQuestion(
            id: "q3_heating_system",
            section: .homeBasics,
            title: "Heat in a {state} home: what's yours?",
            fallbackTitle: "How do you heat your home?",
            subtitle: "Pick whichever sounds closest. We'll use this to schedule HVAC service, fuel deliveries, and tank inspections.",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "gas_furnace_central_ac", label: "Natural gas furnace + central AC", icon: "wind"),
                AnswerOption(id: "gas_boiler_radiators", label: "Natural gas boiler (radiators)", icon: "drop.degreesign"),
                AnswerOption(id: "gas_boiler_central_ac", label: "Natural gas boiler + central AC", icon: "thermometer.snowflake"),
                AnswerOption(id: "oil_boiler_radiators", label: "Oil boiler (radiators)", icon: "fuelpump.fill"),
                AnswerOption(id: "oil_boiler_central_ac", label: "Oil boiler + central AC", icon: "thermometer.snowflake"),
                AnswerOption(id: "heat_pump_ducted", label: "Heat pump (central ducted)", icon: "thermometer.medium"),
                AnswerOption(id: "heat_pump_mini_split", label: "Heat pump (mini-splits)", icon: "fan"),
                AnswerOption(id: "geothermal", label: "Geothermal", icon: "leaf"),
                AnswerOption(id: "propane_boiler", label: "Propane boiler", icon: "flame"),
                AnswerOption(id: "propane_furnace_central_ac", label: "Propane furnace + central AC", icon: "flame"),
                AnswerOption(id: "electric_baseboard", label: "Electric baseboard (no central system)", icon: "bolt.fill"),
                AnswerOption(id: "not_sure", label: "Not sure / other", icon: "questionmark.circle"),
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
            ],
            // Phase 67D (A1): only ask about a mortgage when the home was
            // bought (Q4 = "bought"). Inherited / family pass-down / custom
            // build paths skip this — they don't have a fresh-purchase
            // mortgage to upload. Cash buyers fall through and pick "no".
            // When Q4 is unanswered, fall back to showing Q5 (guard returns
            // false) so a saved-for-later quiz doesn't lose the prompt.
            dynamicSkip: { state in
                guard let q4 = state.answers["q4_purchase"]?.answerId else { return false }
                return q4 == "inherited" || q4 == "custom_build" || q4 == "other"
            }
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
            title: "What's in your {street} kitchen and laundry?",
            fallbackTitle: "Which major appliances do you have?",
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
        // Phase 67D (A4): Q11 progressive disclosure — handler chips up top,
        // lawn-type chips revealed below when handler is not no_lawn /
        // garden / hardscape. Months capture (old Q11c) was moved out —
        // landscaping_active_months now lives in Phase C3's AnnualRhythmScreen.
        // The kind discriminates dispatch in HouseQuizView; the mapper reads
        // `answer.payload?["lawnType"]` for the secondary choice.
        HouseQuizQuestion(
            id: "q11_lawn",
            section: .outside,
            title: "Keeping up the {street} yard: you or a pro?",
            fallbackTitle: "Do you have a lawn?",
            kind: .progressiveLawn,
            answerOptions: [
                AnswerOption(id: "diy", label: "Yes, I maintain it"),
                AnswerOption(id: "pro", label: "Yes, pro service"),
                AnswerOption(id: "no_lawn", label: "No"),
                AnswerOption(id: "garden", label: "Mostly garden"),
                AnswerOption(id: "hardscape", label: "Mostly hardscape (patio, gravel, pavers)", icon: "square.grid.3x3.fill"),
            ],
            providerFollowUpAnswerIds: ["pro"],
            providerTypes: ["landscaping"],
            providerSearchPlaceholder: "TruGreen, BrightView, your local crew..."
        ),
        // Phase 67D (A5): Q12 progressive disclosure — pool kind + chemistry
        // on one screen. Hot-tub-only and none paths skip chemistry. The
        // mapper reads `answer.payload?["chemistry"]` for the saltwater /
        // chlorine choice. Pool months capture moved to Phase C3.
        HouseQuizQuestion(
            id: "q12_pool",
            section: .outside,
            title: "Pool or hot tub?",
            kind: .progressivePool,
            answerOptions: [
                AnswerOption(id: "in_ground", label: "In-ground pool"),
                AnswerOption(id: "above_ground", label: "Above-ground"),
                AnswerOption(id: "hot_tub", label: "Hot tub only"),
                AnswerOption(id: "both", label: "Both"),
                AnswerOption(id: "none", label: "None"),
            ],
            providerFollowUpAnswerIds: ["in_ground", "above_ground", "hot_tub", "both"],
            providerTypes: ["pool_service"],
            providerSearchPlaceholder: "Leslie's, Pinch A Penny, your pool company..."
        ),
        HouseQuizQuestion(
            id: "q13_pest",
            section: .outside,
            title: "Pest pressure in {state}: who's on it?",
            fallbackTitle: "Pest control?",
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
            providerTypes: ["pest_control"],
            providerSearchPlaceholder: "Terminix, Orkin, your local exterminator..."
        ),
        // Phase 67D (A6): Q14 stays as singleChoice; the months follow-up
        // (old Q14b) is gone. Active months for irrigation move to Phase
        // C3's AnnualRhythmScreen. The `q11b_lawn_type` reference inside the
        // dynamicSkip below stays alive for the migration window — Phase A's
        // migration writes lawnType into Q11's payload, so the closure now
        // reads `q11_lawn.payload?["lawnType"]` instead.
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
            dynamicSkip: { state in
                let q11 = state.answers["q11_lawn"]?.answerId
                if q11 == "no_lawn" { return true }
                return false
            },
            providerSearchPlaceholder: "Your sprinkler company..."
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
            providerTypes: ["security"],
            providerSearchPlaceholder: "ADT, SimpliSafe, Ring, Vivint..."
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
            // Phase 60.3 (F3): reordered so Handyman is first. Post-Phase-58
            // Handyman is the "catcher" category for DIY-delegators with
            // spring/fall punch-list bundles; putting it first in the grid
            // reflects its primacy in the vendor-orchestration model rather
            // than burying it at position 9.
            answerOptions: [
                AnswerOption(id: "handyman", label: "Handyman", icon: "wrench.fill"),
                AnswerOption(id: "cleaning", label: "House cleaner", icon: "sparkles"),
                AnswerOption(id: "hvac_service", label: "HVAC service", icon: "thermometer.medium"),
                AnswerOption(id: "plumber", label: "Plumber", icon: "drop.fill"),
                AnswerOption(id: "electrician", label: "Electrician", icon: "bolt.fill"),
                AnswerOption(id: "roofer", label: "Roofer", icon: "house.fill"),
                AnswerOption(id: "tree_service", label: "Tree service", icon: "tree.fill"),
                AnswerOption(id: "mosquito_tick", label: "Mosquito & tick", icon: "ladybug.fill"),
                AnswerOption(id: "snow_removal", label: "Snow removal", icon: "snowflake"),
                AnswerOption(id: "pet_waste", label: "Pet waste", icon: "pawprint.circle.fill"),
                AnswerOption(id: "septic_pumper", label: "Septic pumper", icon: "circle.dashed"),
                AnswerOption(id: "well_water_service", label: "Well water service", icon: "drop.degreesign"),
                AnswerOption(id: "chimney_sweep", label: "Chimney sweep", icon: "flame.fill"),
                // Phase 60.6: new chips to close the Q15b coverage gap Tom
                // flagged on Build 93. `hardscape` surfaces only for
                // properties whose Q11 answer was "hardscape" — the pro
                // is a masonry/paver contractor, mirrored to the
                // Landscaping category. `generator_service` surfaces only
                // when Q22 confirmed a whole-home or portable generator —
                // the annual load-test vendor is separate from the fuel
                // supplier captured inline on Q22.
                AnswerOption(id: "hardscape", label: "Hardscape / masonry", icon: "square.grid.2x2.fill"),
                AnswerOption(id: "generator_service", label: "Generator service", icon: "bolt.batteryblock.fill"),
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
        // Phase 67D (A7): Q18 + Q18b merged into one screen. Service kind
        // chips up top; pickup-day chips revealed below when service is
        // municipal or private. Private hauler name captured via inline
        // free-text. `selectedIds` carries the day chips (sun…sat);
        // `customText` carries the optional hauler name.
        HouseQuizQuestion(
            id: "q18_trash",
            section: .energyServices,
            title: "Trash & recycling?",
            subtitle: "Pick every day bins go out if trash and recycling happen separately.",
            kind: .trashWithDays,
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
            // Phase 18b → 67D (A3): Q3 was renamed `q3_heating_system` and
            // the answer IDs changed from raw fuel tokens to fuel+system
            // combos. Derive the underlying fuel by mapping the combo.
            // Returning [] tells the view model to skip Q19 entirely
            // (electric / geothermal homes have no fuel delivery contract).
            dynamicProviderTypes: { state in
                let comboId = state.answers["q3_heating_system"]?.answerId
                let fuel = HouseQuizFuelDerivation.heatingFuel(from: comboId)
                switch fuel {
                case "oil":         return ["oil"]
                case "propane":     return ["propane"]
                case "natural_gas": return ["natural_gas"]
                case "electric", "geothermal", "not_sure":
                    return []
                default:
                    // Q3 unanswered or unknown answer id — keep the original
                    // three-type behavior so a forward-resumed quiz still
                    // shows something useful.
                    return ["oil", "propane", "natural_gas"]
                }
            }
        ),
        HouseQuizQuestion(
            id: "q20_other_fuels",
            section: .energyServices,
            // Phase 60.3: overridden to yourHome — Q20 is "what fuel do
            // you use in your house" (fireplace, stove, wood, pellets),
            // which is a structural home fact, not a vendor-service
            // question.
            chapter: .yourHome,
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
            title: "Power outages in {state}: are you ready?",
            fallbackTitle: "Whole-home generator?",
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
            // Phase 60.2 (F7): rewritten subtitle. The previous copy
            // ("We tune some maintenance tasks like turf sanitization and
            // HVAC filter swaps based on this") referenced templates that
            // were deleted in Phase 58. Today the pet flag powers (a) the
            // pet_waste chip on Q15b and (b) gating recurring services so
            // vendors know when the household has animals on-site.
            subtitle: "So your vendors know, and so we can suggest recurring services that keep pets safe.",
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
        // Build 88: 3-tier vendor preference picker. Replaces the old 1-10
        // slider that users found confusing. Three clear options that match
        // how users actually think about maintenance delegation. The answer
        // mapper persists the tier string to `vendor_preference_tier` and
        // triggers a household-wide reconciler pass.
        HouseQuizQuestion(
            id: "q36_diy_vs_vendor",
            section: .protectionPeople,
            // Phase 60.3: overridden to yourPros and repositioned to the
            // FIRST question of Chapter 2 so the tier is captured before
            // Q11/Q13/Q14/Q15 vendor branches run. The reconciler's
            // `.either` flip logic depends on the tier being set.
            chapter: .yourPros,
            title: "How do you want to handle home maintenance?",
            subtitle: "This shapes your entire task list. You can change it anytime in Settings.",
            kind: .singleChoice,
            answerOptions: [
                AnswerOption(id: "diy", label: "I handle it", icon: "wrench.and.screwdriver.fill"),
                AnswerOption(id: "mixed", label: "Mix of both", icon: "person.2.fill"),
                AnswerOption(id: "hire_out", label: "Hire it out", icon: "briefcase.fill"),
            ]
        ),

        // Phase 67 (C2): Q37 — routines grid. Single screen with three
        // sections: pre-filled (auto from Q11/Q12/Q13/Q15b vendor captures),
        // common (universal/regional recurring services like window cleaning
        // and mosquito spraying), and anything-else (collapsible groups for
        // HNW lifestyle routines). Each card lets the homeowner confirm
        // cadence + days/months without re-entering the vendor.
        HouseQuizQuestion(
            id: "q37_routines",
            section: .protectionPeople,
            chapter: .yourPeople,
            title: "Your weekly rhythm",
            subtitle: "Pick the routines that come on a schedule. We've pre-filled vendors you already named.",
            kind: .routinesGrid,
            answerOptions: []
        ),

        // Phase 67 (C3): Q38 — handyman punch list. Ten universal default
        // items pre-checked + a "Browse more" library + a custom-add row.
        // Saves create handyman_punch_items rows. The handyman bundle
        // tasks that pre-Phase-67 reconciler seeded as maintenance_tasks
        // are gone — Q38 is the new entry point for these items.
        HouseQuizQuestion(
            id: "q38_handyman_punchlist",
            section: .protectionPeople,
            chapter: .yourPeople,
            title: "Your handyman list",
            subtitle: "These are small jobs your handyman can knock out in a single visit. We've pre-checked the most common — uncheck any that don't apply.",
            kind: .handymanPunchList,
            answerOptions: []
        ),
    ]
}

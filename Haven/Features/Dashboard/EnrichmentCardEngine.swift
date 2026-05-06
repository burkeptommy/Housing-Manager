import SwiftUI

// MARK: - Data Types

struct ChoiceOption: Identifiable {
    let id: String
    let label: String
    let icon: String?

    init(_ id: String, label: String, icon: String? = nil) {
        self.id = id
        self.label = label
        self.icon = icon
    }
}

enum EnrichmentInputType {
    case singleChoice([ChoiceOption])
    case yesNo
    case serviceSetup(serviceType: String)
    case applianceChecklist
    case projectSuggestion(estimatedCost: String, roiLabel: String, roiDetail: String)
}

struct EnrichmentQuestion: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let priority: Int
    let inputType: EnrichmentInputType
    /// The property attribute key this question writes to (for singleChoice/yesNo types)
    let attributeKey: String?

    init(id: String, title: String, subtitle: String, icon: String, iconColor: Color = HavenColors.navy700, priority: Int, inputType: EnrichmentInputType, attributeKey: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.priority = priority
        self.inputType = inputType
        self.attributeKey = attributeKey ?? id
    }
}

// MARK: - Enrichment Engine

struct EnrichmentEngine {

    static func evaluate(
        propertyAttributes: [String: FlexibleValue],
        serviceContracts: [ServiceContractRow],
        homeSystems: [HomeSystemRow],
        dismissedIds: Set<String>,
        yearBuilt: Int? = nil,
        hasProjects: Bool = false
    ) -> [EnrichmentQuestion] {
        var questions: [EnrichmentQuestion] = []

        // Only show enrichment if user has at least one property with systems set up
        guard !homeSystems.isEmpty else { return [] }

        // 1. Roof material
        if propertyAttributes["roof_material"] == nil {
            questions.append(EnrichmentQuestion(
                id: "roof_material",
                title: "What's your roof made of?",
                subtitle: "Helps set the right inspection schedule and lifespan estimate",
                icon: "house.fill",
                priority: 10,
                inputType: .singleChoice([
                    ChoiceOption("asphalt_shingle", label: "Asphalt Shingle"),
                    ChoiceOption("metal", label: "Metal"),
                    ChoiceOption("tile", label: "Tile / Clay"),
                    ChoiceOption("slate", label: "Slate"),
                    ChoiceOption("flat_membrane", label: "Flat / Membrane"),
                    ChoiceOption("wood_shake", label: "Wood Shake"),
                    ChoiceOption("not_sure", label: "Not sure"),
                ])
            ))
        }

        // 2. Pest control service
        let hasPestContract = serviceContracts.contains { $0.serviceType == "pest_control" }
        if !hasPestContract {
            questions.append(EnrichmentQuestion(
                id: "pest_control",
                title: "Do you have pest control service?",
                subtitle: "Track your termite bond, quarterly treatments, and provider",
                icon: "ant.fill",
                iconColor: HavenColors.navy700,
                priority: 15,
                inputType: .serviceSetup(serviceType: "pest_control")
            ))
        }

        // 3. Siding material
        if propertyAttributes["siding_material"] == nil {
            questions.append(EnrichmentQuestion(
                id: "siding_material",
                title: "What's your exterior siding?",
                subtitle: "Affects your painting and washing schedule",
                icon: "building.2.fill",
                priority: 20,
                inputType: .singleChoice([
                    ChoiceOption("vinyl", label: "Vinyl"),
                    ChoiceOption("wood", label: "Wood"),
                    ChoiceOption("brick", label: "Brick"),
                    ChoiceOption("stucco", label: "Stucco"),
                    ChoiceOption("fiber_cement", label: "Fiber Cement"),
                    ChoiceOption("stone", label: "Stone"),
                    ChoiceOption("mixed", label: "Mixed"),
                    ChoiceOption("not_sure", label: "Not sure"),
                ])
            ))
        }

        // 4. Appliance inventory
        let individualAppliances = homeSystems.filter {
            $0.category == "Appliance" && $0.name != "Kitchen & Laundry Appliances"
        }
        if individualAppliances.count < 3 {
            questions.append(EnrichmentQuestion(
                id: "appliance_inventory",
                title: "Track your appliances individually",
                subtitle: "Get warranty reminders for each one",
                icon: "refrigerator.fill",
                priority: 25,
                inputType: .applianceChecklist
            ))
        }

        // 5. Landscaping service
        let hasLandscapingContract = serviceContracts.contains { $0.serviceType == "landscaping" }
        if !hasLandscapingContract {
            questions.append(EnrichmentQuestion(
                id: "landscaping",
                title: "Do you have lawn care service?",
                subtitle: "Track your mowing, fertilization, and tree care providers",
                icon: "leaf.fill",
                iconColor: HavenColors.navy700,
                priority: 30,
                inputType: .serviceSetup(serviceType: "landscaping")
            ))
        }

        // 6. Water source
        if propertyAttributes["water_source"] == nil {
            questions.append(EnrichmentQuestion(
                id: "water_source",
                title: "What's your water source?",
                subtitle: "Well water needs different maintenance than municipal",
                icon: "drop.fill",
                priority: 35,
                inputType: .singleChoice([
                    ChoiceOption("municipal", label: "City / Municipal"),
                    ChoiceOption("well", label: "Well Water"),
                    ChoiceOption("not_sure", label: "Not sure"),
                ])
            ))
        }

        // 7. Water softener
        if propertyAttributes["has_water_softener"] == nil {
            questions.append(EnrichmentQuestion(
                id: "has_water_softener",
                title: "Do you have a water softener?",
                subtitle: "We'll add salt refill and filter change reminders",
                icon: "water.waves",
                priority: 36,
                inputType: .yesNo
            ))
        }

        // 8. Deck material
        if propertyAttributes["deck_material"] == nil {
            questions.append(EnrichmentQuestion(
                id: "deck_material",
                title: "Do you have a deck or patio?",
                subtitle: "Wood decks need regular staining. We'll track it",
                icon: "rectangle.split.3x3",
                priority: 40,
                inputType: .singleChoice([
                    ChoiceOption("wood", label: "Wood"),
                    ChoiceOption("composite", label: "Composite"),
                    ChoiceOption("concrete", label: "Concrete / Paver"),
                    ChoiceOption("none", label: "No deck"),
                ])
            ))
        }

        // 9. Fence material
        if propertyAttributes["fence_material"] == nil {
            questions.append(EnrichmentQuestion(
                id: "fence_material",
                title: "Do you have a fence?",
                subtitle: "Wood fences need staining. Metal and vinyl don't",
                icon: "square.grid.3x3.topleft.filled",
                priority: 41,
                inputType: .singleChoice([
                    ChoiceOption("wood", label: "Wood"),
                    ChoiceOption("vinyl", label: "Vinyl"),
                    ChoiceOption("chain_link", label: "Chain Link"),
                    ChoiceOption("metal", label: "Wrought Iron"),
                    ChoiceOption("none", label: "No fence"),
                ])
            ))
        }

        // 10. Electrical panel
        if propertyAttributes["has_ev_charger"] == nil {
            questions.append(EnrichmentQuestion(
                id: "has_ev_charger",
                title: "Do you have an EV charger?",
                subtitle: "We'll add annual inspection reminders",
                icon: "bolt.car.fill",
                priority: 45,
                inputType: .yesNo
            ))
        }

        // Phase 62 — 4 new enrichment questions driving new HNW templates.

        // 11. Mature trees near the house (drives arborist inspection).
        if propertyAttributes["has_mature_trees"] == nil {
            questions.append(EnrichmentQuestion(
                id: "has_mature_trees",
                title: "Do you have large trees near the house?",
                subtitle: "We'll add annual arborist check reminders",
                icon: "tree.fill",
                priority: 42,
                inputType: .yesNo
            ))
        }

        // 12. Driveway material (asphalt drives biennial seal coat).
        if propertyAttributes["driveway_material"] == nil {
            questions.append(EnrichmentQuestion(
                id: "driveway_material",
                title: "What's your driveway made of?",
                subtitle: "Asphalt driveways need sealing every few years",
                icon: "road.lanes",
                priority: 43,
                inputType: .singleChoice([
                    ChoiceOption("asphalt", label: "Asphalt"),
                    ChoiceOption("concrete", label: "Concrete"),
                    ChoiceOption("paver", label: "Paver / Stone"),
                    ChoiceOption("gravel", label: "Gravel"),
                    ChoiceOption("other", label: "Other"),
                ])
            ))
        }

        // 13. Fridge water / ice dispenser (drives semi-annual filter swap).
        if propertyAttributes["has_fridge_water_dispenser"] == nil {
            questions.append(EnrichmentQuestion(
                id: "has_fridge_water_dispenser",
                title: "Does your fridge have a water or ice dispenser?",
                subtitle: "We'll remind you to swap the filter every 6 months",
                icon: "refrigerator.fill",
                priority: 44,
                inputType: .yesNo
            ))
        }

        // 14. Sump battery backup (conditional on existing sump pump system).
        let hasSumpPump = homeSystems.contains { system in
            system.category == "Plumbing" && (system.subtype?.lowercased().contains("sump") ?? false)
        }
        if hasSumpPump && propertyAttributes["has_sump_battery_backup"] == nil {
            questions.append(EnrichmentQuestion(
                id: "has_sump_battery_backup",
                title: "Does your sump pump have a battery backup?",
                subtitle: "We'll add semi-annual backup battery tests",
                icon: "battery.100",
                priority: 46,
                inputType: .yesNo
            ))
        }

        // MARK: - Project Suggestions (ROI-based)

        // Suggest projects based on property age and systems
        if !hasProjects {
            let homeAge = yearBuilt.map { Calendar.current.component(.year, from: Date()) - $0 }

            // Old roof suggestion (15+ years)
            let roofSystem = homeSystems.first { $0.category.lowercased().contains("roof") }
            let roofAge: Int? = {
                if let installDate = roofSystem?.installDate,
                   let date = ISO8601DateFormatter().date(from: installDate) {
                    return Calendar.current.dateComponents([.year], from: date, to: Date()).year
                }
                return homeAge
            }()
            if let age = roofAge, age >= 15, propertyAttributes["dismissed_project_roof"] == nil {
                questions.append(EnrichmentQuestion(
                    id: "project_suggest_roof",
                    title: "Time for a roof assessment?",
                    subtitle: "Homes that replace aging roofs see strong returns at resale",
                    icon: "house.lodge.fill",
                    iconColor: HavenColors.success,
                    priority: 50,
                    inputType: .projectSuggestion(
                        estimatedCost: "$8,000 - $15,000",
                        roiLabel: "High ROI",
                        roiDetail: "Spend ~$12K, typical return ~$8K at resale. Buyers pay more for a new roof."
                    )
                ))
            }

            // Generator suggestion (all homes)
            if propertyAttributes["has_generator"] == nil, propertyAttributes["dismissed_project_generator"] == nil {
                questions.append(EnrichmentQuestion(
                    id: "project_suggest_generator",
                    title: "Backup generator?",
                    subtitle: "Homes with generators see higher resale value and faster sales",
                    icon: "bolt.shield.fill",
                    iconColor: HavenColors.warning,
                    priority: 55,
                    inputType: .projectSuggestion(
                        estimatedCost: "$3,000 - $12,000",
                        roiLabel: "Moderate ROI",
                        roiDetail: "Spend ~$7K, adds ~$5K in resale value. Sells 3-5% faster."
                    )
                ))
            }

            // Smart home / energy efficiency for newer homes
            if let age = homeAge, age <= 20, propertyAttributes["dismissed_project_smart_home"] == nil {
                questions.append(EnrichmentQuestion(
                    id: "project_suggest_smart_home",
                    title: "Smart home upgrades?",
                    subtitle: "Smart thermostats, locks, and lighting pay for themselves in energy savings",
                    icon: "homekit",
                    iconColor: HavenColors.navy500,
                    priority: 60,
                    inputType: .projectSuggestion(
                        estimatedCost: "$500 - $3,000",
                        roiLabel: "High ROI",
                        roiDetail: "Spend ~$1.5K, save $300/year on energy. Pays for itself in 5 years."
                    )
                ))
            }

            // Kitchen remodel for older homes (20+ years)
            if let age = homeAge, age >= 20, propertyAttributes["dismissed_project_kitchen"] == nil {
                questions.append(EnrichmentQuestion(
                    id: "project_suggest_kitchen",
                    title: "Kitchen refresh?",
                    subtitle: "Minor kitchen remodels consistently deliver the highest ROI of any home project",
                    icon: "fork.knife",
                    iconColor: HavenColors.navy700,
                    priority: 52,
                    inputType: .projectSuggestion(
                        estimatedCost: "$15,000 - $35,000",
                        roiLabel: "High ROI",
                        roiDetail: "Spend ~$25K, typical return ~$20K at resale. #1 ROI project nationwide."
                    )
                ))
            }

            // Deck/patio for homes without one
            if propertyAttributes["has_deck"] == nil, propertyAttributes["dismissed_project_deck"] == nil {
                questions.append(EnrichmentQuestion(
                    id: "project_suggest_deck",
                    title: "Add a deck or patio?",
                    subtitle: "Outdoor living space is one of the most requested features by buyers",
                    icon: "sun.and.horizon.fill",
                    iconColor: HavenColors.warning,
                    priority: 58,
                    inputType: .projectSuggestion(
                        estimatedCost: "$4,000 - $15,000",
                        roiLabel: "Moderate ROI",
                        roiDetail: "Spend ~$10K, typical return ~$7K at resale. High buyer appeal."
                    )
                ))
            }
        }

        let result = questions
            .filter { !dismissedIds.contains($0.id) }
            .filter { question in
                // Only show High ROI project suggestions — skip Moderate ones
                if case .projectSuggestion(_, let roiLabel, _) = question.inputType {
                    return roiLabel.lowercased().contains("high")
                }
                return true // Always show property questions
            }
            .sorted { $0.priority < $1.priority }
            .prefix(2)
            .map { $0 }

        if !result.isEmpty {
            Analytics.track(.enrichmentCardViewed, ["card_count": result.count, "card_ids": result.map(\.id).joined(separator: ",")])
        }

        return result
    }
}

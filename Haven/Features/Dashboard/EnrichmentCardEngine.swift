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
        dismissedIds: Set<String>
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
                subtitle: "Wood decks need regular staining — we'll track it",
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
                subtitle: "Wood fences need staining — metal and vinyl don't",
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

        let result = questions
            .filter { !dismissedIds.contains($0.id) }
            .sorted { $0.priority < $1.priority }
            .prefix(2)
            .map { $0 }

        if !result.isEmpty {
            Analytics.track(.enrichmentCardViewed, ["card_count": result.count, "card_ids": result.map(\.id).joined(separator: ",")])
        }

        return result
    }
}

import Foundation

// MARK: - Scenario Section (for custom/freeform results)

struct ScenarioSection: Identifiable {
    let id = UUID()
    let heading: String
    let icon: String?
    let content: String
    let highlight: String?
    let flag: String?
}

// MARK: - Financial Detail (for custom results)

struct FinancialDetail: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let flag: String?
}

// MARK: - Scenario Result

struct ScenarioResult {
    let title: String
    let severity: String
    let summary: String
    let timeline: [TimelineStep]
    let financialImpact: FinancialImpact?
    let guardianChain: [GuardianEntry]
    let actionItems: [ActionItem]
    let recommendations: [String]
    let didYouKnow: String?
    let disclaimer: String

    // Custom/freeform scenario fields
    let sections: [ScenarioSection]
    let confidenceLevel: String?
    let confidenceNote: String?
    let relatedScenarios: [String]
    let financialSummaryLine: String?
    let financialDetails: [FinancialDetail]

    // Tax scenario fields
    let currentSituation: [String: String]?
    let proposedSituation: [String: String]?
    let savingsBreakdown: SavingsBreakdown?
    let stepsToImplement: [String]?
    let risksAndConsiderations: [String]?

    // Home scenario fields
    let netProceeds: String?
    let capitalGains: String?
    let currentValueEstimate: String?
    let purchasePrice: String?
    let mortgageBalance: String?
    let closingCostsEstimate: String?
    let exclusionAvailable: String?
    let taxImplications: [String]?

    // Personalization
    let documentsUsed: [String]?
    let documentsMissing: [String]?

    init(from json: [String: Any]) {
        title = json["title"] as? String ?? "Scenario Analysis"
        severity = json["severity"] as? String ?? "informational"
        summary = json["summary"] as? String ?? ""

        // Timeline
        if let timelineArray = json["timeline"] as? [[String: Any]] {
            timeline = timelineArray.enumerated().map { index, dict in
                TimelineStep(
                    step: dict["step"] as? Int ?? (index + 1),
                    title: dict["title"] as? String ?? "",
                    description: dict["description"] as? String ?? "",
                    details: dict["details"] as? [String] ?? [],
                    flag: dict["flag"] as? String
                )
            }
        } else {
            timeline = []
        }

        // Financial impact (pre-built scenario format)
        if let fi = json["financial_impact"] as? [String: Any] {
            var breakdownItems: [FinancialItem] = []
            if let breakdown = fi["breakdown"] as? [[String: Any]] {
                breakdownItems = breakdown.map { dict in
                    FinancialItem(
                        item: dict["item"] as? String ?? "",
                        amount: dict["amount"] as? String ?? "$0",
                        status: dict["status"] as? String ?? "unknown",
                        goesTo: dict["goes_to"] as? String,
                        flag: dict["flag"] as? String
                    )
                }
            }
            financialImpact = FinancialImpact(
                assetsProtected: fi["assets_protected"] as? String ?? "$0",
                assetsAtRisk: fi["assets_at_risk"] as? String ?? "$0",
                taxExposure: fi["tax_exposure"] as? String ?? "$0",
                insurancePayouts: fi["insurance_payouts"] as? String,
                breakdown: breakdownItems
            )

            // Also parse custom financial_impact format
            financialSummaryLine = fi["summary_line"] as? String
            if let details = fi["details"] as? [[String: Any]] {
                financialDetails = details.map { dict in
                    FinancialDetail(
                        label: dict["label"] as? String ?? "",
                        value: dict["value"] as? String ?? "",
                        flag: dict["flag"] as? String
                    )
                }
            } else {
                financialDetails = []
            }
        } else {
            financialImpact = nil
            financialSummaryLine = nil
            financialDetails = []
        }

        // Guardian chain
        if let guardians = json["guardian_chain"] as? [[String: Any]] {
            guardianChain = guardians.map { dict in
                GuardianEntry(
                    name: dict["name"] as? String ?? "",
                    relationship: dict["relationship"] as? String ?? "",
                    status: dict["status"] as? String ?? "primary"
                )
            }
        } else {
            guardianChain = []
        }

        // Action items
        if let actions = json["action_items"] as? [[String: Any]] {
            actionItems = actions.map { dict in
                ActionItem(
                    priority: dict["priority"] as? String ?? "medium",
                    title: dict["title"] as? String ?? "",
                    description: dict["description"] as? String ?? "",
                    effort: dict["effort"] as? String
                )
            }
        } else {
            actionItems = []
        }

        // Recommendations
        recommendations = json["recommendations"] as? [String] ?? []

        // Did you know
        didYouKnow = json["did_you_know"] as? String

        // Disclaimer
        disclaimer = json["disclaimer"] as? String
            ?? "This analysis is for planning purposes only and does not constitute legal, tax, or financial advice. Consult qualified professionals before making decisions."

        // Sections (custom/freeform)
        if let sectionsArray = json["sections"] as? [[String: Any]] {
            sections = sectionsArray.map { dict in
                ScenarioSection(
                    heading: dict["heading"] as? String ?? "",
                    icon: dict["icon"] as? String,
                    content: dict["content"] as? String ?? "",
                    highlight: dict["highlight"] as? String,
                    flag: dict["flag"] as? String
                )
            }
        } else {
            sections = []
        }

        // Confidence
        confidenceLevel = json["confidence_level"] as? String
        confidenceNote = json["confidence_note"] as? String

        // Related scenarios
        relatedScenarios = json["related_scenarios"] as? [String] ?? []

        // Risks
        risksAndConsiderations = json["risks_and_considerations"] as? [String]

        // Tax fields
        currentSituation = json["current_situation"] as? [String: String]
        proposedSituation = json["proposed_situation"] as? [String: String]
        stepsToImplement = json["steps_to_implement"] as? [String]

        if let sb = json["savings_breakdown"] as? [String: Any] {
            savingsBreakdown = SavingsBreakdown(
                annualSavings: sb["annual_tax_savings"] as? String ?? sb["annual_savings"] as? String ?? "$0",
                details: sb["details"] as? [String] ?? []
            )
        } else {
            savingsBreakdown = nil
        }

        // Home fields
        netProceeds = json["net_proceeds"] as? String
        capitalGains = json["capital_gains"] as? String
        currentValueEstimate = json["current_value_estimate"] as? String
        purchasePrice = json["purchase_price"] as? String
        mortgageBalance = json["mortgage_balance"] as? String
        closingCostsEstimate = json["closing_costs_estimate"] as? String
        exclusionAvailable = json["exclusion_available"] as? String
        taxImplications = json["tax_implications"] as? [String]

        // Personalization
        documentsUsed = json["documents_used"] as? [String]
        documentsMissing = json["documents_missing"] as? [String]
    }

    var personalizationScore: Double {
        let used = Double(documentsUsed?.count ?? 0)
        let missing = Double(documentsMissing?.count ?? 0)
        let total = used + missing
        guard total > 0 else { return 0.5 }
        return used / total
    }
}

// MARK: - Timeline Step

struct TimelineStep: Identifiable {
    let id = UUID()
    let step: Int
    let title: String
    let description: String
    let details: [String]
    let flag: String?
}

// MARK: - Financial Impact

struct FinancialImpact {
    let assetsProtected: String
    let assetsAtRisk: String
    let taxExposure: String
    let insurancePayouts: String?
    let breakdown: [FinancialItem]
}

// MARK: - Financial Item

struct FinancialItem: Identifiable {
    let id = UUID()
    let item: String
    let amount: String
    let status: String
    let goesTo: String?
    let flag: String?
}

// MARK: - Guardian Entry

struct GuardianEntry: Identifiable {
    let id = UUID()
    let name: String
    let relationship: String
    let status: String
}

// MARK: - Action Item

struct ActionItem: Identifiable {
    let id = UUID()
    let priority: String
    let title: String
    let description: String
    let effort: String?
}

// MARK: - Savings Breakdown

struct SavingsBreakdown {
    let annualSavings: String
    let details: [String]
}

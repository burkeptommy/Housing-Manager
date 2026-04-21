import Foundation

enum EnrichmentActions {

    /// Applies post-answer side effects: updates system notes, creates/adjusts maintenance tasks.
    static func applyEnrichment(
        questionId: String,
        answer: String,
        propertyId: UUID,
        householdId: UUID,
        homeSystems: [HomeSystemRow]
    ) async {
        Analytics.track(.enrichmentCardCompleted, ["question_id": questionId, "answer": answer])

        switch questionId {

        case "roof_material":
            await updateSystemNotes(category: "Roofing", note: "Material: \(formatAnswer(answer))", systems: homeSystems)
            if let system = homeSystems.first(where: { $0.category == "Roofing" }) {
                let lifespan = roofLifespan(for: answer)
                _ = try? await DatabaseService.shared.updateHomeSystem(
                    id: system.id,
                    HomeSystemUpdate(expectedLifespanYears: lifespan)
                )
            }

        case "siding_material":
            await updateSystemNotes(category: "Siding/Exterior", note: "Material: \(formatAnswer(answer))", systems: homeSystems)
            if answer == "wood" {
                await addMaintenanceTask(
                    title: "Repaint/restain wood siding",
                    description: "Wood siding needs repainting or restaining to prevent rot and weather damage.",
                    frequency: "Every 5-7 years",
                    priority: "Medium",
                    costRange: "$3,000–$8,000",
                    isDIY: false,
                    professionalRequired: true,
                    category: "Siding/Exterior",
                    propertyId: propertyId,
                    householdId: householdId,
                    systems: homeSystems
                )
            }

        case "deck_material":
            if answer == "wood" {
                await addMaintenanceTask(
                    title: "Stain/seal wood deck",
                    description: "Apply stain or sealant to protect wood from moisture, UV, and wear.",
                    frequency: "Every 2-3 years",
                    priority: "Medium",
                    costRange: "$500–$1,500",
                    isDIY: true,
                    professionalRequired: false,
                    category: "Siding/Exterior",
                    propertyId: propertyId,
                    householdId: householdId,
                    systems: homeSystems
                )
            }

        case "fence_material":
            if answer == "wood" {
                await addMaintenanceTask(
                    title: "Stain/seal wood fence",
                    description: "Apply stain or sealant to protect the fence from rot and weather damage.",
                    frequency: "Every 3-5 years",
                    priority: "Low",
                    costRange: "$400–$1,200",
                    isDIY: true,
                    professionalRequired: false,
                    category: "Siding/Exterior",
                    propertyId: propertyId,
                    householdId: householdId,
                    systems: homeSystems
                )
            }

        case "has_water_softener":
            if answer == "true" {
                await addMaintenanceTask(
                    title: "Refill water softener salt",
                    description: "Check salt level and add salt as needed to maintain water softening.",
                    frequency: "Monthly",
                    priority: "Medium",
                    costRange: "$5–$15",
                    isDIY: true,
                    professionalRequired: false,
                    category: "Plumbing",
                    propertyId: propertyId,
                    householdId: householdId,
                    systems: homeSystems
                )
                await addMaintenanceTask(
                    title: "Service water softener",
                    description: "Professional inspection, clean resin bed, check settings and valves.",
                    frequency: "Annually",
                    priority: "Low",
                    costRange: "$100–$200",
                    isDIY: false,
                    professionalRequired: true,
                    category: "Plumbing",
                    propertyId: propertyId,
                    householdId: householdId,
                    systems: homeSystems
                )
            }

        case "has_ev_charger":
            if answer == "true" {
                await addMaintenanceTask(
                    title: "Inspect EV charger",
                    description: "Check cables, connectors, and mounting for wear or damage. Verify charging performance.",
                    frequency: "Annually",
                    priority: "Low",
                    costRange: "$0 (DIY)",
                    isDIY: true,
                    professionalRequired: false,
                    category: "Electrical",
                    propertyId: propertyId,
                    householdId: householdId,
                    systems: homeSystems
                )
            }

        case "water_source":
            if answer == "well" {
                await addMaintenanceTask(
                    title: "Test well water quality",
                    description: "Annual testing for bacteria, nitrates, pH, and other contaminants.",
                    frequency: "Annually",
                    priority: "High",
                    costRange: "$50–$200",
                    isDIY: false,
                    professionalRequired: true,
                    category: "Plumbing",
                    propertyId: propertyId,
                    householdId: householdId,
                    systems: homeSystems
                )
            }

        // Phase 62 — four new enrichment answers that each drive a
        // template via the reconciler. The attribute itself has already
        // been written by the dashboard answer handler before this
        // switch fires. All we do here is re-run the reconciler so the
        // activeSubtypes recomputation picks up the new flag and seeds
        // the matching gated template. Per CLAUDE.md: "Template library
        // is the single source of truth for task shape" — no inline
        // task creation in answer handlers.
        case "has_mature_trees",
             "driveway_material",
             "has_fridge_water_dispenser",
             "has_sump_battery_backup":
            _ = await MaintenanceTaskReconciler.reconcileAll(
                propertyId: propertyId,
                householdId: householdId
            )
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)

        default:
            break
        }
    }

    // MARK: - Helpers

    private static func formatAnswer(_ answer: String) -> String {
        answer.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private static func roofLifespan(for material: String) -> Int {
        switch material {
        case "asphalt_shingle": return 25
        case "metal": return 50
        case "tile": return 75
        case "slate": return 100
        case "flat_membrane": return 20
        case "wood_shake": return 30
        default: return 25
        }
    }

    private static func updateSystemNotes(category: String, note: String, systems: [HomeSystemRow]) async {
        guard let system = systems.first(where: { $0.category == category }) else { return }
        let existing = system.notes ?? ""
        let updated = existing.isEmpty ? note : "\(existing)\n\(note)"
        _ = try? await DatabaseService.shared.updateHomeSystem(id: system.id, HomeSystemUpdate(notes: updated))
    }

    private static func addMaintenanceTask(
        title: String,
        description: String,
        frequency: String,
        priority: String,
        costRange: String,
        isDIY: Bool,
        professionalRequired: Bool,
        category: String,
        propertyId: UUID,
        householdId: UUID,
        systems: [HomeSystemRow]
    ) async {
        let systemId = systems.first(where: { $0.category == category })?.id
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let nextDue = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now

        let insert = MaintenanceTaskInsert(
            propertyId: propertyId,
            householdId: householdId,
            title: title,
            frequency: frequency,
            nextDueDate: formatter.string(from: nextDue),
            systemId: systemId,
            description: description,
            priority: priority,
            isTemplateBased: true,
            templateId: "enrichment:\(title)",
            isDiy: isDIY,
            professionalRequired: professionalRequired,
            costRange: costRange
        )

        _ = try? await DatabaseService.shared.createMaintenanceTask(insert)
    }
}

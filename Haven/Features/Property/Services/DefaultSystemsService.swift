import Foundation

/// Auto-creates a comprehensive set of home systems and maintenance tasks when a property is added.
enum DefaultSystemsService {

    struct SystemTemplate {
        let name: String
        let category: String
    }

    /// Returns the default systems appropriate for a given property type.
    static func defaultSystems(for propertyType: String) -> [SystemTemplate] {
        var systems: [SystemTemplate] = [
            SystemTemplate(name: "Central HVAC", category: "HVAC"),
            SystemTemplate(name: "Plumbing System", category: "Plumbing"),
            SystemTemplate(name: "Electrical System", category: "Electrical"),
            SystemTemplate(name: "Water Heater", category: "Water Heater"),
            SystemTemplate(name: "Roof", category: "Roofing"),
            SystemTemplate(name: "Windows", category: "Windows"),
            SystemTemplate(name: "Exterior Doors", category: "Doors"),
            SystemTemplate(name: "Kitchen & Laundry Appliances", category: "Appliance"),
            SystemTemplate(name: "Garage Door", category: "Garage Door"),
            SystemTemplate(name: "Smoke & Fire Protection", category: "Fire Protection"),
            SystemTemplate(name: "Landscaping", category: "Landscaping"),
            SystemTemplate(name: "Pest Control", category: "Pest Control"),
            SystemTemplate(name: "Siding & Exterior", category: "Siding/Exterior"),
        ]

        let lowerType = propertyType.lowercased()
        let isRuralOrLand = lowerType.contains("land") || lowerType.contains("rural")

        if isRuralOrLand {
            systems.append(contentsOf: [
                SystemTemplate(name: "Well System", category: "Well System"),
                SystemTemplate(name: "Septic System", category: "Septic System"),
                SystemTemplate(name: "Irrigation System", category: "Irrigation"),
                SystemTemplate(name: "Backup Generator", category: "Generator"),
            ])
        }

        return systems
    }

    /// Creates default systems and their maintenance tasks for a newly created property.
    static func createDefaultSystems(propertyId: UUID, householdId: UUID, propertyType: String) async {
        let templates = defaultSystems(for: propertyType)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for template in templates {
            do {
                let insert = HomeSystemInsert(
                    propertyId: propertyId,
                    householdId: householdId,
                    name: template.name,
                    category: template.category,
                    status: "Good"
                )
                let system = try await DatabaseService.shared.createHomeSystem(insert)

                // Create maintenance tasks from templates
                let maintenanceTemplates = MaintenanceTemplates.templates(for: template.category)
                for mt in maintenanceTemplates {
                    let nextDue = Calendar.current.date(byAdding: mt.interval, to: .now) ?? .now
                    let taskInsert = MaintenanceTaskInsert(
                        propertyId: propertyId,
                        householdId: householdId,
                        title: mt.title,
                        frequency: mt.frequency,
                        nextDueDate: formatter.string(from: nextDue),
                        systemId: system.id,
                        description: mt.description,
                        priority: mt.priority,
                        isTemplateBased: true,
                        templateId: mt.systemCategory + ":" + mt.title,
                        seasonalTiming: mt.seasonalTiming,
                        isDiy: mt.isDIY,
                        professionalRequired: mt.professionalRequired,
                        costRange: mt.estimatedCostRange,
                        recurrenceRule: mt.frequency
                    )
                    _ = try await DatabaseService.shared.createMaintenanceTask(taskInsert)
                }
            } catch {
                // Continue creating remaining systems even if one fails
                print("DefaultSystemsService: Failed to create \(template.name): \(error.localizedDescription)")
            }
        }
    }
}

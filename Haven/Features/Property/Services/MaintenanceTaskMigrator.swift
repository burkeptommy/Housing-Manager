import Foundation

/// Adds maintenance tasks that become applicable when the user confirms a
/// system subtype in the House Quiz. Pre-quiz, `PropertyCreationService`
/// only creates tasks whose templates have no `requiredSubtypes` (so we
/// never suggest "Descale tankless heater" before the user confirms they
/// have a tankless heater). When the quiz lands a subtype answer (e.g.
/// "Tank gas" water heater, "Central ducted" HVAC, "Asphalt shingle" roof),
/// the mapper calls this helper to add the newly-matching essential tasks.
///
/// Dedup is delegated to `DatabaseService.createMaintenanceTask`, which
/// skips inserts whose title already exists for the same household /
/// property / system.
@MainActor
enum MaintenanceTaskMigrator {
    /// Creates maintenance tasks that become applicable when a subtype is
    /// added to a system.
    ///
    /// - Parameters:
    ///   - propertyId: The property these tasks belong to.
    ///   - householdId: Owning household.
    ///   - systemCategory: The `HomeSystem.category` string this applies to.
    ///   - systemId: Optional system to attach the new tasks to so they
    ///     show up under the right system detail view.
    ///   - previousSubtype: The subtype that was active before (usually `nil`
    ///     pre-quiz). Used to compute which templates are *newly* applicable.
    ///   - newSubtype: The subtype the user just confirmed.
    ///   - fuelType: Optional catalog fuel type, forwarded to activeSubtypes.
    ///   - flags: Optional extra flags (sump_pump, fireplace, etc.).
    static func addSubtypeTasks(
        propertyId: UUID,
        householdId: UUID,
        systemCategory: String,
        systemId: UUID? = nil,
        previousSubtype: String? = nil,
        newSubtype: String?,
        fuelType: String? = nil,
        flags: [String: Bool] = [:]
    ) async {
        guard let newSubtype, !newSubtype.isEmpty else { return }

        let oldActive = MaintenanceTemplates.activeSubtypes(
            category: systemCategory,
            subtype: previousSubtype,
            fuelType: fuelType,
            flags: flags
        )
        let newActive = MaintenanceTemplates.activeSubtypes(
            category: systemCategory,
            subtype: newSubtype,
            fuelType: fuelType,
            flags: flags
        )

        // Nothing to do if the new subtype doesn't unlock any new subtype
        // tokens (e.g. the quiz answer didn't map to a known subtype).
        guard !newActive.subtracting(oldActive).isEmpty else { return }

        let oldTemplates = MaintenanceTemplates.essentialTemplates(
            for: systemCategory,
            activeSubtypes: oldActive
        )
        let newTemplates = MaintenanceTemplates.essentialTemplates(
            for: systemCategory,
            activeSubtypes: newActive
        )

        let oldTitles = Set(oldTemplates.map { $0.title.lowercased() })
        let added = newTemplates.filter { !oldTitles.contains($0.title.lowercased()) }
        guard !added.isEmpty else { return }

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for template in added {
            let nextDue = calendar.date(byAdding: template.interval, to: Date()) ?? Date()
            var task = MaintenanceTaskInsert(
                householdId: householdId,
                title: template.title,
                frequency: template.frequency,
                nextDueDate: formatter.string(from: nextDue)
            )
            task.propertyId = propertyId
            task.systemId = systemId
            task.description = template.description
            task.priority = template.priority
            task.isTemplateBased = true
            task.templateId = "\(template.systemCategory):\(template.title)"
            task.seasonalTiming = template.seasonalTiming
            task.isDiy = template.isDIY
            task.professionalRequired = template.professionalRequired
            task.costRange = template.estimatedCostRange

            _ = try? await DatabaseService.shared.createMaintenanceTask(task)
        }
    }
}

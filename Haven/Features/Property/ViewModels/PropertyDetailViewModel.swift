import SwiftUI
import UserNotifications

@MainActor
final class PropertyDetailViewModel: ObservableObject {
    @Published var property: PropertyRow?
    @Published var systems: [HomeSystemRow] = []
    @Published var maintenanceTasks: [MaintenanceTaskDBRow] = []
    @Published var warranties: [WarrantyRow] = []
    @Published var serviceRecords: [ServiceRecordRow] = []
    @Published var linkedDocuments: [DocumentRow] = []
    @Published var contractors: [ContractorRow] = []
    @Published var utilityAccounts: [UtilityAccountRow] = []
    @Published var completedProjects: [PropertyProjectRow] = []
    @Published var allProjects: [PropertyProjectRow] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var justCompletedTaskId: UUID?
    @Published var isRefreshingValue = false

    private let db = DatabaseService.shared

    var systemsByCategory: [(String, [HomeSystemRow])] {
        let groups = Dictionary(grouping: systems) { $0.category }
        return groups.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    var overdueTasks: [MaintenanceTaskDBRow] {
        maintenanceTasks.filter { task in
            guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
            return date < .now
        }
    }

    var dueThisMonthTasks: [MaintenanceTaskDBRow] {
        let cal = Calendar.current
        let now = Date.now
        let endOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: cal.startOfDay(for: now)) ?? now
        return maintenanceTasks.filter { task in
            guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
            return date >= now && date <= endOfMonth
        }
    }

    var upcomingTasks: [MaintenanceTaskDBRow] {
        let cal = Calendar.current
        let thirtyDays = cal.date(byAdding: .day, value: 30, to: .now) ?? .now
        return maintenanceTasks
            .filter { task in
                guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
                return date >= .now && date <= thirtyDays
            }
            .sorted { a, b in a.nextDueDate < b.nextDueDate }
    }

    var totalServiceCost: Double {
        serviceRecords.compactMap(\.cost).reduce(0, +)
    }

    var activeWarranties: [WarrantyRow] {
        warranties.filter { w in
            guard let end = dateFormatter.date(from: w.endDate) else { return false }
            return end > .now
        }
    }

    func systemName(for systemId: UUID?) -> String? {
        guard let id = systemId else { return nil }
        return systems.first { $0.id == id }?.name
    }

    /// Contractors assigned to systems on this property
    var assignedContractors: [(ContractorRow, [String])] {
        let contractorIds = Set(systems.compactMap(\.preferredContractorId))
        return contractors
            .filter { contractorIds.contains($0.id) }
            .map { contractor in
                let systemNames = systems
                    .filter { $0.preferredContractorId == contractor.id }
                    .map(\.name)
                return (contractor, systemNames)
            }
    }

    /// Common property documents that are missing
    var missingPropertyDocTypes: [(String, String)] {
        let existingCategories = Set(linkedDocuments.map(\.category))
        var missing: [(String, String)] = []
        if !existingCategories.contains("Deed") {
            missing.append(("Deed", "Add your deed"))
        }
        if !existingCategories.contains("Homeowners Insurance") {
            missing.append(("Homeowners Insurance", "Add your homeowners insurance"))
        }
        if !existingCategories.contains("Mortgage") {
            missing.append(("Mortgage", "Add your mortgage"))
        }
        if !existingCategories.contains("Title Insurance") {
            missing.append(("Title Insurance", "Add your title insurance"))
        }
        return missing
    }

    // MARK: - Vendor Helpers

    func vendorName(for systemId: UUID?) -> String? {
        guard let systemId,
              let system = systems.first(where: { $0.id == systemId }),
              let contractorId = system.preferredContractorId else { return nil }
        return contractors.first(where: { $0.id == contractorId })?.companyName
    }

    func vendorPhone(for systemId: UUID?) -> String? {
        guard let systemId,
              let system = systems.first(where: { $0.id == systemId }),
              let contractorId = system.preferredContractorId else { return nil }
        return contractors.first(where: { $0.id == contractorId })?.phone
    }

    func vendorEmail(for systemId: UUID?) -> String? {
        guard let systemId,
              let system = systems.first(where: { $0.id == systemId }),
              let contractorId = system.preferredContractorId else { return nil }
        return contractors.first(where: { $0.id == contractorId })?.email
    }

    // MARK: - Task Actions

    func snoozeTask(_ task: MaintenanceTaskDBRow, days: Int) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let newDate = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        do {
            _ = try await db.updateMaintenanceTask(
                id: task.id,
                MaintenanceTaskUpdate(nextDueDate: formatter.string(from: newDate))
            )
            Haptics.success()
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "updated", "id": task.id.uuidString])
            guard let prop = property else { return }
            await loadProperty(id: prop.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func setReminder(for task: MaintenanceTaskDBRow?, option: String) async {
        guard let task else { return }
        let calendar = Calendar.current
        let reminderDate: Date
        switch option {
        case "Tomorrow": reminderDate = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        case "In 3 Days": reminderDate = calendar.date(byAdding: .day, value: 3, to: .now) ?? .now
        case "Next Week": reminderDate = calendar.date(byAdding: .weekOfYear, value: 1, to: .now) ?? .now
        case "Next Month": reminderDate = calendar.date(byAdding: .month, value: 1, to: .now) ?? .now
        default: reminderDate = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        }
        let content = UNMutableNotificationContent()
        content.title = "Maintenance Reminder"
        content.body = "\(task.title) needs attention."
        content.sound = .default
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "task-\(task.id.uuidString)", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
        Haptics.success()
    }

    // MARK: - Seasonal

    /// Total actual spend on COMPLETED projects only (for investment dashboard cost basis).
    /// In-flight projects are excluded because their budgets are speculative.
    var totalProjectSpend: Double {
        completedProjects.reduce(0.0) { $0 + (($1.actualSpend ?? 0) > 0 ? $1.actualSpend! : 0) }
    }

    /// Estimated spend on active/in-flight projects (planning + in_progress).
    /// Used for "what if" analysis but not included in totalProjectSpend.
    var inFlightProjectSpend: Double {
        allProjects
            .filter { $0.status == "planning" || $0.status == "in_progress" }
            .reduce(0.0) { $0 + (($1.actualSpend ?? 0) > 0 ? $1.actualSpend! : ($1.estimatedBudget ?? 0)) }
    }

    var currentSeason: String {
        let month = Calendar.current.component(.month, from: .now)
        switch month {
        case 3...5: return "Spring"
        case 6...8: return "Summer"
        case 9...11: return "Fall"
        default: return "Winter"
        }
    }

    var nextSeason: String {
        switch currentSeason {
        case "Spring": return "Summer"
        case "Summer": return "Fall"
        case "Fall": return "Winter"
        default: return "Spring"
        }
    }

    var currentSeasonTasks: [MaintenanceTaskDBRow] {
        maintenanceTasks.filter { task in
            guard let timing = task.seasonalTiming?.lowercased() else { return false }
            return timing.contains(currentSeason.lowercased())
        }
    }

    var nextSeasonTasks: [MaintenanceTaskDBRow] {
        maintenanceTasks.filter { task in
            guard let timing = task.seasonalTiming?.lowercased() else { return false }
            return timing.contains(nextSeason.lowercased())
        }
    }

    var currentSeasonCompletedCount: Int {
        currentSeasonTasks.filter { $0.lastCompletedDate != nil }.count
    }

    /// Refresh the property's estimated value via ATTOM/RentCast lookup
    /// Apply a freeform PropertyUpdate (used by InvestmentSummaryCard's
    /// inline-edit sheet) and refresh local state.
    func applyPropertyUpdate(_ update: PropertyUpdate) async {
        guard let prop = property else { return }
        do {
            let updated = try await db.updateProperty(id: prop.id, update)
            property = updated
            Haptics.success()
            NotificationCenter.default.post(name: .propertyChanged, object: nil)
            Analytics.track(.investmentValuesEdited, [
                "has_purchase_price": update.purchasePrice != nil,
                "has_estimated_value": update.currentEstimatedValue != nil,
            ])
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    func refreshPropertyValue() async {
        guard let prop = property else { return }
        let address = [prop.street, prop.city, prop.state, prop.zipCode]
            .compactMap { $0 }
            .joined(separator: ", ")
        guard !address.isEmpty else { return }

        isRefreshingValue = true
        defer { isRefreshingValue = false }

        do {
            let data = try await HavenSupabase.propertyLookup(address: address)
            struct LookupResponse: Decodable {
                let success: Bool
                let property: PropertyLookupResult?
            }
            let response = try JSONDecoder().decode(LookupResponse.self, from: data)
            if let result = response.property, let newValue = result.estimatedValue {
                let updated = try await db.updateProperty(id: prop.id, PropertyUpdate(
                    currentEstimatedValue: newValue
                ))
                property = updated
                Haptics.success()
                NotificationCenter.default.post(name: .propertyChanged, object: nil)
            }
        } catch {
            print("[PropertyDetail] Value refresh failed: \(error)")
        }
    }

    /// Build 84 — Re-fires the ATTOM property lookup and walks the same
    /// fallback ladder as `OnboardingViewModel.runComplete` so retroactive
    /// fixes use one path. Used by the "Refresh from public records" button
    /// on `InvestmentSummaryCard`'s empty state when a user's property row
    /// was created before the Build 84 ladder landed (or when ATTOM only
    /// returned a range without a canonical value).
    ///
    /// Walks: canonical estimatedValue → midpoint of range → high → low →
    /// taxAssessment.assessedValue. Persists `currentEstimatedValue`,
    /// `purchasePrice`, and `estimatedValueSource` in one PropertyUpdate
    /// call. On success: refreshes `property`, posts `.propertyChanged` so
    /// other tabs update, and fires a success haptic.
    func refreshFromPublicRecords(appState: AppState? = nil) async {
        guard let prop = property else { return }
        let address = [prop.street, prop.city, prop.state, prop.zipCode]
            .compactMap { $0 }
            .joined(separator: ", ")
        guard !address.isEmpty else { return }

        isRefreshingValue = true
        defer { isRefreshingValue = false }

        do {
            let data = try await HavenSupabase.propertyLookup(address: address)
            struct LookupResponse: Decodable {
                let success: Bool
                let property: PropertyLookupResult?
            }
            let response = try JSONDecoder().decode(LookupResponse.self, from: data)
            guard let result = response.property else {
                print("[PropertyDetail] refreshFromPublicRecords: lookup returned no property")
                return
            }

            // Same fallback ladder as OnboardingViewModel.runComplete.
            let attomEstimatedValue: Double? = {
                if let canonical = result.estimatedValue { return canonical }
                if let low = result.estimatedValueLow,
                   let high = result.estimatedValueHigh {
                    return (low + high) / 2
                }
                if let high = result.estimatedValueHigh { return high }
                if let low = result.estimatedValueLow { return low }
                if let assessed = result.taxAssessment?.assessedValue { return assessed }
                return nil
            }()

            print("[PropertyDetail] refreshFromPublicRecords: estValue=\(attomEstimatedValue?.description ?? "nil") lastSale=\(result.lastSalePrice?.description ?? "nil") range=\(result.estimatedValueLow?.description ?? "nil")-\(result.estimatedValueHigh?.description ?? "nil") taxAssessed=\(result.taxAssessment?.assessedValue?.description ?? "nil") source=\(result.estimatedValueSource ?? "nil")")

            guard attomEstimatedValue != nil || result.lastSalePrice != nil else {
                // Nothing to write — surface to caller via the existing
                // `error` channel so the empty state can show "no public
                // records found for this address".
                self.error = "Public records didn't return a value for this address."
                Haptics.error()
                return
            }

            var update = PropertyUpdate()
            update.currentEstimatedValue = attomEstimatedValue
            update.estimatedValueSource = result.estimatedValueSource
                ?? (attomEstimatedValue != nil ? "computed" : nil)
            update.purchasePrice = result.lastSalePrice

            let updated = try await db.updateProperty(id: prop.id, update)
            property = updated
            if let appState, appState.primaryProperty?.id == updated.id {
                appState.primaryProperty = updated
            }
            Haptics.success()
            NotificationCenter.default.post(name: .propertyChanged, object: nil)
        } catch {
            print("[PropertyDetail] refreshFromPublicRecords failed: \(error)")
            self.error = "Couldn't refresh from public records. \(error.localizedDescription)"
            Haptics.error()
        }
    }

    func loadProperty(id: UUID) async {
        isLoading = true
        error = nil
        do {
            property = try await db.fetchProperty(id: id)

            async let systemsTask = db.fetchHomeSystems(propertyId: id)
            async let tasksTask = db.fetchMaintenanceTasks(propertyId: id)
            async let recordsTask = db.fetchServiceRecords(propertyId: id)

            let (sys, tasks, records) = try await (systemsTask, tasksTask, recordsTask)
            systems = sys
            maintenanceTasks = tasks
            serviceRecords = records

            // Fetch warranties for all systems
            var allWarranties: [WarrantyRow] = []
            for system in sys {
                let sysWarranties = try await db.fetchWarranties(systemId: system.id)
                allWarranties.append(contentsOf: sysWarranties)
            }
            warranties = allWarranties

            // Fetch linked documents
            linkedDocuments = try await db.fetchDocuments()
                .filter { $0.propertyId == id }

            // Fetch contractors
            contractors = try await db.fetchContractors()

            // Fetch utility accounts
            utilityAccounts = (try? await db.fetchUtilityAccounts(propertyId: id)) ?? []

            // Fetch projects for investment dashboard
            allProjects = (try? await db.fetchProjects(propertyId: id)) ?? []
            completedProjects = allProjects.filter { $0.status == "completed" }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteSystem(_ system: HomeSystemRow) async {
        let snapshot = systems
        systems.removeAll { $0.id == system.id }
        Haptics.success()

        do {
            try await db.deleteHomeSystem(id: system.id)
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil,
                userInfo: ["action": "deleted", "id": system.id.uuidString])
        } catch {
            systems = snapshot
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    func completeMaintenanceTask(_ task: MaintenanceTaskDBRow) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Optimistic: show completion animation immediately
        justCompletedTaskId = task.id
        Haptics.success()

        do {
            let nextDate = calculateNextDueDate(frequency: task.frequency, from: .now)
            _ = try await db.updateMaintenanceTask(
                id: task.id,
                MaintenanceTaskUpdate(
                    lastCompletedDate: formatter.string(from: .now),
                    nextDueDate: formatter.string(from: nextDate)
                )
            )

            // Update system's last_service_date and next_service_due
            if let systemId = task.systemId {
                let systemTasks = maintenanceTasks.filter { $0.systemId == systemId && $0.id != task.id }
                let nextSystemDue = systemTasks
                    .compactMap { formatter.date(from: $0.nextDueDate) }
                    .filter { $0 > .now }
                    .min()
                let nextDueStr = nextSystemDue.map { formatter.string(from: $0) } ?? formatter.string(from: nextDate)

                _ = try await db.updateHomeSystem(
                    id: systemId,
                    HomeSystemUpdate(
                        lastServiceDate: formatter.string(from: .now),
                        nextServiceDue: nextDueStr
                    )
                )
            }

            // Log service record
            guard let prop = property else { return }
            _ = try await db.createServiceRecord(ServiceRecordInsert(
                propertyId: prop.id,
                householdId: prop.householdId,
                serviceDate: formatter.string(from: .now),
                serviceType: "maintenance",
                description: task.title,
                systemId: task.systemId
            ))

            // Reschedule notifications
            Task { await NotificationScheduler.shared.rescheduleAll() }

            // Notify other tabs
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "completed", "id": task.id.uuidString])

            // Clear animation after delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            justCompletedTaskId = nil

            // Reload
            await loadProperty(id: prop.id)
        } catch {
            justCompletedTaskId = nil
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    private func calculateNextDueDate(frequency: String, from date: Date) -> Date {
        let cal = Calendar.current
        switch frequency.lowercased() {
        case "monthly": return cal.date(byAdding: .month, value: 1, to: date)!
        case "quarterly": return cal.date(byAdding: .month, value: 3, to: date)!
        case "semi-annually": return cal.date(byAdding: .month, value: 6, to: date)!
        case "annually": return cal.date(byAdding: .year, value: 1, to: date)!
        case "every 2 years": return cal.date(byAdding: .year, value: 2, to: date)!
        case "seasonal": return cal.date(byAdding: .month, value: 3, to: date)!
        default: return cal.date(byAdding: .year, value: 1, to: date)!
        }
    }
}

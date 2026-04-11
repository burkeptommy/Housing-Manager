import SwiftUI
import UserNotifications
import Combine

struct ExpirationItem: Identifiable {
    let id = UUID()
    let sourceId: UUID  // the actual document or warranty ID
    let title: String
    let type: String // "document", "warranty", "insurance", "maintenance"
    let date: Date
    let icon: String
    let daysRemaining: Int

    var urgencyColor: Color {
        if daysRemaining < 0 { return .red }
        if daysRemaining <= 7 { return .red }
        if daysRemaining <= 30 { return .orange }
        if daysRemaining <= 90 { return .yellow }
        return .green
    }
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let date: Date
}

struct CategoryScore: Identifiable {
    let id = UUID()
    let category: String
    let percentage: Double
    let actual: Int
    let expected: Int
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var overallReadiness: Double = 0
    @Published var categoryScores: [CategoryScore] = []
    @Published var uploadedCount: Int = 0
    @Published var missingCount: Int = 0
    @Published var expiringCount: Int = 0
    @Published var upcomingExpirations: [ExpirationItem] = []
    @Published var overdueMaintenanceTasks: [MaintenanceTaskDBRow] = []
    @Published var dueThisWeekTasks: [MaintenanceTaskDBRow] = []
    @Published var dueThisMonthTasks: [MaintenanceTaskDBRow] = []
    @Published var nextUpcomingTask: MaintenanceTaskDBRow?
    @Published var allUpcomingTasks: [MaintenanceTaskDBRow] = []

    /// Phase 19l: Active personal/either property tasks (excludes vehicles
    /// and archived rows). Drives the "X to do" half of the home hero card.
    @Published var personalTaskCount: Int = 0
    /// Phase 19l: Active vendor-managed property tasks — both linked to a
    /// contractor and "needs vendor" find-a-contractor placeholders. Drives
    /// the "Y vendor-managed" half of the home hero card.
    @Published var vendorManagedTaskCount: Int = 0

    /// Phase 50: Hydrated vendor visit cards for the dashboard's
    /// `VendorScheduleStrip`. Each entry already has its vendor name,
    /// logo URL, brand color, and last service cost resolved so the
    /// strip stays presentation-only and doesn't trigger per-card
    /// network lookups while scrolling. Built in `loadVendorVisits()`
    /// from the joined contractor + service-record snapshot.
    @Published var upcomingVendorVisits: [DashboardVendorVisit] = []
    /// Phase 50: Tasks counted toward the "X tasks this week" line that
    /// sits below the vendor schedule strip. Includes both personal and
    /// vendor tasks due in the next 7 days.
    @Published var dueThisWeekTaskCount: Int = 0
    @Published var recentDocuments: [DocumentRow] = []
    @Published var userFirstName: String?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: String?

    // Getting Started tracking
    @Published var hasProperty = false
    @Published var hasDocuments = false
    @Published var hasUsedAlfred = false
    @Published var documentCount: Int = 0

    // Smart Recommendations tracking
    @Published var vendorCount: Int = 0
    @Published var systemCount: Int = 0
    @Published var familyMemberCount: Int = 0
    @Published var hasRunGapAnalysis = false
    @Published var hasRunScenario = false
    @Published var hasRemindersEnabled = false
    @Published var overBudgetProjectCount = 0
    @Published var approachingDeadlineProjectCount = 0
    @Published var seasonalTasksIncomplete = 0
    @Published var seasonalTasksTotal = 0
    @Published var currentSeasonName = ""
    @Published var systemsNeedingServiceCount = 0
    @Published var hasIncompleteProperty = false
    @Published var dismissedRecommendationIds: Set<String> = []

    // Family members
    @Published var familyMembers: [FamilyMemberRow] = []
    @Published var expectingMembers: [FamilyMemberRow] = []
    @Published var allDocuments: [DocumentRow] = []

    // Build 87: paid household staff (home managers, future role types).
    // Loaded alongside familyMembers in `refresh()` via the new
    // `DatabaseService.fetchHouseholdStaff()` helper. Empty by default —
    // the dashboard hides the strip entirely when this is empty.
    @Published var householdStaff: [FamilyMemberRow] = []

    // Enrichment cards
    @Published var propertyAttributes: [String: FlexibleValue] = [:]
    @Published var serviceContracts: [ServiceContractRow] = []
    @Published var homeSystems: [HomeSystemRow] = []
    @Published var dismissedEnrichmentIds: Set<String> = []
    @Published var primaryPropertyId: UUID?
    @Published var primaryYearBuilt: Int?
    @Published var primaryPropertyLocation: String?
    @Published var primaryHouseholdId: UUID?
    @Published var inboxItems: [DatabaseService.InboxItemRow] = []
    @Published var properties: [PropertyRow] = []
    @Published var hasActiveProjects = false
    @Published var vehicles: [VehicleRow] = []
    @Published var unresolvedVehicleRecalls: Int = 0
    @Published var propertyNeedsAddress: PropertyRow?

    // Estate drip card (Phase 48)
    @Published var estateState: EstateStateRow?

    /// Phase 50 (sub-phase B first-login): the household's
    /// `*@alfred.havenhome.dev` forwarding address. Loaded by
    /// `loadHouseholdEmail()` in `fetchAll()` and surfaced inside the
    /// `VendorScheduleStrip` empty state as a subtle copy-to-clipboard
    /// caption ("Or forward invoices to … and we'll automatically
    /// build this out"). Nil while loading or if the household hasn't
    /// been provisioned an address yet.
    @Published var householdForwardingEmail: String?

    var shouldShowEstateDripCard: Bool {
        // Don't show during onboarding -- wait until all house quizzes are done
        let allQuizzesDone = !properties.isEmpty && properties.allSatisfy { $0.houseQuizState?.completedAt != nil }
        guard allQuizzesDone else { return false }
        return EstateIntakeDripCard.shouldShow(estateState: estateState)
    }

    func dismissEstateDrip(tier: EstateIntakeDripCard.DismissTier) {
        EstateIntakeDripCard.dismiss(tier: tier)
        objectWillChange.send()
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe immediately so push notifications trigger inbox refresh
        // even before loadDashboard() completes
        subscribeToChanges()
    }

    /// Phase 50 (sub-phase B first-login): collapses to "no property" or
    /// "no completed quiz" so the Quiz card is the single Day-0 CTA. Once
    /// any property's quiz is done, Getting Started disappears entirely
    /// and the VendorScheduleStrip ("Your maintenance plan is ready")
    /// takes over as the primary action surface, absorbing the role of
    /// the old Step 2 ("Upload your first document").
    var showGettingStarted: Bool {
        !hasProperty || !hasCompletedAnyQuiz
    }

    /// True once any property in the household has completed the house quiz.
    /// Day 0 cleanup uses this as the gate for hiding advanced cards
    /// (Foundation, Scenario, Unified Attention, Security badge) and the
    /// vendor schedule section until the user has at least one property
    /// worth of real data to power them.
    var hasCompletedAnyQuiz: Bool {
        properties.contains { $0.houseQuizState?.completedAt != nil }
    }

    var recommendations: [Recommendation] {
        RecommendationEngine.evaluate(
            hasProperty: hasProperty,
            propertyCount: hasProperty ? 1 : 0,
            documentCount: documentCount,
            familyMemberCount: familyMemberCount,
            vendorCount: vendorCount,
            systemCount: systemCount,
            overdueCount: overdueMaintenanceTasks.count,
            hasRunGapAnalysis: hasRunGapAnalysis,
            hasRunScenario: hasRunScenario,
            expiringCount: upcomingExpirations.count,
            estateReadiness: overallReadiness,
            hasRemindersEnabled: hasRemindersEnabled,
            overBudgetProjectCount: overBudgetProjectCount,
            approachingDeadlineProjectCount: approachingDeadlineProjectCount,
            seasonalTasksIncomplete: seasonalTasksIncomplete,
            seasonalTasksTotal: seasonalTasksTotal,
            currentSeasonName: currentSeasonName,
            systemsNeedingServiceCount: systemsNeedingServiceCount,
            hasIncompleteProperty: hasIncompleteProperty,
            estateState: estateState,
            dismissedIds: dismissedRecommendationIds
        )
    }

    var enrichmentQuestions: [EnrichmentQuestion] {
        EnrichmentEngine.evaluate(
            propertyAttributes: propertyAttributes,
            serviceContracts: serviceContracts,
            homeSystems: homeSystems,
            dismissedIds: dismissedEnrichmentIds,
            yearBuilt: primaryYearBuilt,
            hasProjects: hasActiveProjects
        )
    }

    func dismissRecommendation(_ id: String) {
        dismissedRecommendationIds.insert(id)
        UserDefaults.standard.set(Array(dismissedRecommendationIds), forKey: "dismissedRecommendations")
    }

    func dismissEnrichmentCard(_ id: String) {
        dismissedEnrichmentIds.insert(id)
        UserDefaults.standard.set(Array(dismissedEnrichmentIds), forKey: "dismissedEnrichmentCards")
    }

    func loadDismissedRecommendations() {
        let saved = UserDefaults.standard.stringArray(forKey: "dismissedRecommendations") ?? []
        dismissedRecommendationIds = Set(saved)
    }

    func loadDismissedEnrichmentCards() {
        let saved = UserDefaults.standard.stringArray(forKey: "dismissedEnrichmentCards") ?? []
        dismissedEnrichmentIds = Set(saved)
    }

    func checklistProgress(for member: FamilyMemberRow) -> (completed: Int, total: Int) {
        let items = NewArrivalChecklist.items(babyName: member.firstName)
        let key = "arrivalChecklist_\(member.id.uuidString)"
        let saved = UserDefaults.standard.string(forKey: key) ?? ""
        let completedIds = Set(saved.split(separator: ",").map(String.init))
        let existingCategories = Set(allDocuments.map(\.category))

        let completed = items.filter { item in
            if let cat = item.documentCategory, existingCategories.contains(cat) { return true }
            return completedIds.contains(item.id)
        }.count

        return (completed, items.count)
    }

    /// Resolve assignee name from user ID by checking family members with linked accounts
    private func assigneeName(for userId: UUID?) -> String? {
        guard let userId else { return nil }
        return familyMembers.first { $0.linkedUserId == userId }?.firstName
    }

    var unifiedAttentionItems: [AttentionItem] {
        var items: [AttentionItem] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date.now

        // Exclude the task shown in the hero card ("Next: ...")
        let heroTaskId = nextUpcomingTask?.id

        // 1. Overdue maintenance tasks (highest priority)
        for task in overdueMaintenanceTasks where task.id != heroTaskId {
            let days = formatter.date(from: task.nextDueDate).flatMap {
                Calendar.current.dateComponents([.day], from: now, to: $0).day
            } ?? -1
            items.append(AttentionItem(
                id: UUID(),
                sourceId: nil,
                title: task.title,
                subtitle: "Overdue",
                icon: "wrench.and.screwdriver.fill",
                urgencyColor: HavenColors.critical,
                daysRemaining: days,
                kind: .maintenance(task),
                priority: task.priority,
                assignedName: assigneeName(for: task.assignedToUserId)
            ))
        }

        // 2. Vehicle alerts (recalls, registration, inspection)
        if unresolvedVehicleRecalls > 0 {
            items.append(AttentionItem(
                id: UUID(),
                sourceId: nil,
                title: "\(unresolvedVehicleRecalls) Open Recall\(unresolvedVehicleRecalls == 1 ? "" : "s")",
                subtitle: "Vehicle safety",
                icon: "car.fill",
                urgencyColor: HavenColors.critical,
                daysRemaining: 0,
                kind: .vehicleAlert
            ))
        }
        let vehicleLabel: (VehicleRow) -> String = { v in
            "\(v.year.map { String($0) } ?? "") \(v.make ?? "")".trimmed
        }
        // Collect all task IDs we've already added (overdue) to avoid duplicates
        var addedTaskIds = Set(overdueMaintenanceTasks.map(\.id))

        for vehicle in vehicles {
            // Registration expiry (within 60 days)
            if let exp = vehicle.registrationExpiry, let date = formatter.date(from: exp) {
                let days = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 99
                if days <= 60 {
                    // Try to find a matching stored task for this vehicle
                    if let task = allUpcomingTasks.first(where: { $0.vehicleId == vehicle.id && ($0.templateId == "registration_renewal" || $0.title.lowercased().contains("registration")) }) {
                        if !addedTaskIds.contains(task.id) {
                            addedTaskIds.insert(task.id)
                            items.append(AttentionItem(
                                id: UUID(), sourceId: nil,
                                title: "\(vehicleLabel(vehicle)) Registration",
                                subtitle: days < 0 ? "Expired" : "Renewal coming up",
                                icon: "doc.badge.clock.fill",
                                urgencyColor: days < 0 ? HavenColors.critical : days <= 30 ? HavenColors.warning : HavenColors.info,
                                daysRemaining: days,
                                kind: .maintenance(task),
                                priority: task.priority,
                                assignedName: assigneeName(for: task.assignedToUserId)
                            ))
                        }
                    } else {
                        // No stored task - create a synthetic one so the detail sheet can still open
                        let syntheticTask = MaintenanceTaskDBRow.synthetic(
                            title: "\(vehicleLabel(vehicle)) Registration Renewal",
                            nextDueDate: exp,
                            vehicleId: vehicle.id,
                            householdId: vehicle.householdId,
                            priority: days <= 30 ? "high" : "medium",
                            templateId: "registration_renewal"
                        )
                        items.append(AttentionItem(
                            id: UUID(), sourceId: nil,
                            title: "\(vehicleLabel(vehicle)) Registration",
                            subtitle: days < 0 ? "Expired" : "Renewal coming up",
                            icon: "doc.badge.clock.fill",
                            urgencyColor: days < 0 ? HavenColors.critical : days <= 30 ? HavenColors.warning : HavenColors.info,
                            daysRemaining: days,
                            kind: .maintenance(syntheticTask),
                            priority: syntheticTask.priority
                        ))
                    }
                }
            }
            // Inspection expiry (within 60 days)
            if let exp = vehicle.inspectionExpiry, let date = formatter.date(from: exp) {
                let days = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 99
                if days <= 60 {
                    if let task = allUpcomingTasks.first(where: { $0.vehicleId == vehicle.id && ($0.templateId == "inspection" || $0.title.lowercased().contains("inspection")) }) {
                        if !addedTaskIds.contains(task.id) {
                            addedTaskIds.insert(task.id)
                            items.append(AttentionItem(
                                id: UUID(), sourceId: nil,
                                title: "\(vehicleLabel(vehicle)) Inspection",
                                subtitle: days < 0 ? "Expired" : "Due soon",
                                icon: "checkmark.shield.fill",
                                urgencyColor: days < 0 ? HavenColors.critical : days <= 30 ? HavenColors.warning : HavenColors.info,
                                daysRemaining: days,
                                kind: .maintenance(task),
                                priority: task.priority,
                                assignedName: assigneeName(for: task.assignedToUserId)
                            ))
                        }
                    } else {
                        let syntheticTask = MaintenanceTaskDBRow.synthetic(
                            title: "\(vehicleLabel(vehicle)) Inspection",
                            nextDueDate: exp,
                            vehicleId: vehicle.id,
                            householdId: vehicle.householdId,
                            priority: days <= 30 ? "high" : "medium",
                            templateId: "inspection"
                        )
                        items.append(AttentionItem(
                            id: UUID(), sourceId: nil,
                            title: "\(vehicleLabel(vehicle)) Inspection",
                            subtitle: days < 0 ? "Expired" : "Due soon",
                            icon: "checkmark.shield.fill",
                            urgencyColor: days < 0 ? HavenColors.critical : days <= 30 ? HavenColors.warning : HavenColors.info,
                            daysRemaining: days,
                            kind: .maintenance(syntheticTask),
                            priority: syntheticTask.priority
                        ))
                    }
                }
            }
        }

        // 3. Expiring documents (within 30 days)
        for exp in upcomingExpirations where exp.daysRemaining <= 30 && exp.type == "document" {
            items.append(AttentionItem(
                id: exp.id,
                sourceId: exp.sourceId,
                title: exp.title,
                subtitle: "Document expiring",
                icon: "doc.text.fill",
                urgencyColor: exp.urgencyColor,
                daysRemaining: exp.daysRemaining,
                kind: .expiration("document")
            ))
        }

        // 4. Expiring warranties (within 30 days)
        for exp in upcomingExpirations where exp.daysRemaining <= 30 && exp.type == "warranty" {
            items.append(AttentionItem(
                id: exp.id,
                sourceId: exp.sourceId,
                title: exp.title,
                subtitle: "Warranty expiring",
                icon: "shield.fill",
                urgencyColor: exp.urgencyColor,
                daysRemaining: exp.daysRemaining,
                kind: .expiration("warranty")
            ))
        }

        // 5. Upcoming maintenance tasks (not already shown as overdue, vehicle alerts, or hero card)
        for task in allUpcomingTasks {
            guard task.id != heroTaskId,
                  !addedTaskIds.contains(task.id),
                  let date = formatter.date(from: task.nextDueDate),
                  date >= now else { continue }
            let days = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
            items.append(AttentionItem(
                id: UUID(),
                sourceId: nil,
                title: task.title,
                subtitle: "Upcoming maintenance",
                icon: "wrench.and.screwdriver.fill",
                urgencyColor: days <= 3 ? HavenColors.critical : days <= 7 ? HavenColors.warning : days <= 30 ? HavenColors.info : Color(red: 0.40, green: 0.55, blue: 0.42),
                daysRemaining: days,
                kind: .maintenance(task),
                priority: task.priority,
                assignedName: assigneeName(for: task.assignedToUserId)
            ))
        }

        // 6. Estate readiness nudge (if score < 20% and getting started is complete)
        if !showGettingStarted && overallReadiness < 20 {
            items.append(AttentionItem(
                id: UUID(),
                sourceId: nil,
                title: "Upload estate documents",
                subtitle: "Protect your family's future",
                icon: "doc.badge.plus",
                urgencyColor: HavenColors.navy800,
                daysRemaining: 999,
                kind: .estateNudge
            ))
        }

        return items.sorted { $0.daysRemaining < $1.daysRemaining }
    }

    func subscribeToChanges() {
        guard cancellables.isEmpty else { return }
        let names: [Notification.Name] = [
            .maintenanceTaskChanged, .homeSystemChanged, .contractorChanged,
            .documentChanged, .propertyChanged, .projectChanged,
            .estateStateChanged
        ]
        for name in names {
            NotificationCenter.default.publisher(for: name)
                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    Task { [weak self] in await self?.refresh() }
                }
                .store(in: &cancellables)
        }
        // Inbox updates only refresh inbox items, not the whole dashboard
        NotificationCenter.default.publisher(for: .inboxItemUpdated)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { [weak self] in await self?.loadInboxItems() }
            }
            .store(in: &cancellables)
    }

    func loadDashboard() async {
        subscribeToChanges()
        loadDismissedRecommendations()
        loadDismissedEnrichmentCards()
        isLoading = true
        defer { isLoading = false }
        await fetchAll()
        Analytics.track(.dashboardRefreshed, ["type": "initial_load", "overdue_count": overdueMaintenanceTasks.count, "document_count": documentCount])
    }

    private var isRefreshingInternal = false

    func refresh() async {
        guard !isRefreshingInternal else { return }
        isRefreshingInternal = true
        isRefreshing = true
        defer { isRefreshing = false; isRefreshingInternal = false }
        await fetchAll()
    }

    private func fetchAll() async {
        // Fire each load in its own unstructured Task so SwiftUI task cancellation
        // (from pull-to-refresh or view lifecycle) doesn't cascade-cancel all requests.
        // Each task updates @Published properties on MainActor independently.
        await withTaskGroup(of: Void.self) { group in
            let methods: [() async -> Void] = [
                loadCompletionScores, loadExpirations, loadOverdueMaintenance,
                loadRecentDocuments, loadUserName, loadGettingStartedState,
                loadRecommendationData, loadEnrichmentData, loadInboxItems, loadVehicleAlerts,
                loadEstateState, loadVendorVisits, loadHouseholdEmail
            ]
            for method in methods {
                group.addTask { @MainActor in
                    // Ignore cancellation — we want these to complete
                    await Task { await method() }.value
                }
            }
        }
    }

    private func loadUserName() async {
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            if let fullName = user.fullName, !fullName.isEmpty {
                userFirstName = fullName.components(separatedBy: " ").first
            }
        } catch {}
    }

    /// Phase 50 (sub-phase B first-login): fetch the household's
    /// `*@alfred.havenhome.dev` forwarding address so the
    /// `VendorScheduleStrip` empty state can show a copy-to-clipboard
    /// caption alongside the Upload invoice / Add vendor buttons. Same
    /// helper used by the Q17 quiz milestone and `ProjectEmailView`.
    /// Errors are swallowed — the caption silently hides when nil.
    private func loadHouseholdEmail() async {
        householdForwardingEmail = try? await DatabaseService.shared.fetchHouseholdEmailAddress()
    }

    private func loadCompletionScores() async {
        do {
            let readiness = try await DatabaseService.shared.calculateEstateReadiness()
            overallReadiness = readiness.overallPercentage
            categoryScores = readiness.sectionScores.map { score in
                CategoryScore(
                    category: score.section,
                    percentage: score.percentage,
                    actual: score.filledCategories,
                    expected: score.totalCategories
                )
            }
            uploadedCount = readiness.uploadedCount
            missingCount = readiness.missingCount
            expiringCount = readiness.expiringCount
        } catch {
            print("[Dashboard] Failed to calculate readiness: \(error)")
        }
    }

    private func loadExpirations() async {
        var items: [ExpirationItem] = []
        let calendar = Calendar.current
        let now = Date()

        // Expiring documents
        do {
            let docs = try await DatabaseService.shared.fetchDocuments()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            for doc in docs {
                guard let dateStr = doc.expirationDate, let date = dateFormatter.date(from: dateStr) else { continue }
                let days = calendar.dateComponents([.day], from: now, to: date).day ?? 0
                if days <= 90 {
                    items.append(ExpirationItem(
                        sourceId: doc.id,
                        title: doc.title,
                        type: "document",
                        date: date,
                        icon: "doc.text.fill",
                        daysRemaining: days
                    ))
                }
            }
        } catch {}

        // Expiring warranties
        do {
            let warranties = try await DatabaseService.shared.fetchWarranties()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            for w in warranties {
                guard let date = dateFormatter.date(from: w.endDate) else { continue }
                let days = calendar.dateComponents([.day], from: now, to: date).day ?? 0
                if days <= 90 {
                    items.append(ExpirationItem(
                        sourceId: w.id,
                        title: w.provider,
                        type: "warranty",
                        date: date,
                        icon: "shield.fill",
                        daysRemaining: days
                    ))
                }
            }
        } catch {}

        upcomingExpirations = items.sorted { $0.daysRemaining < $1.daysRemaining }
    }

    private func loadOverdueMaintenance() async {
        do {
            let tasks = try await DatabaseService.shared.fetchMaintenanceTasks()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let now = Date()

            overdueMaintenanceTasks = tasks.filter { task in
                guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
                return date < now
            }

            let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
            dueThisWeekTasks = tasks.filter { task in
                guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
                return date >= now && date <= endOfWeek
            }

            let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: now) ?? now
            dueThisMonthTasks = tasks.filter { task in
                guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
                return date >= now && date <= endOfMonth
            }

            let futureTasks = tasks
                .filter { task in
                    guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
                    return date >= now
                }
                .sorted(by: { $0.nextDueDate < $1.nextDueDate })

            nextUpcomingTask = futureTasks.first
            allUpcomingTasks = futureTasks

            // Phase 19l: split the active property task list into personal +
            // vendor-managed buckets so the dashboard hero can show both.
            // Vehicle tasks are excluded (this is the home card). Archived
            // rows are already filtered out at the DB layer.
            let propertyTasks = tasks.filter { $0.vehicleId == nil }
            personalTaskCount = propertyTasks.filter { task in
                let assignment = task.assignmentType?.lowercased()
                return assignment != "vendor"
            }.count
            vendorManagedTaskCount = propertyTasks.filter { task in
                task.assignmentType?.lowercased() == "vendor"
            }.count

            // Phase 50: count of tasks due in the next 7 days for the
            // VendorScheduleStrip's summary line. Mirrors the existing
            // dueThisWeekTasks list but covers both personal and vendor
            // assignments since the strip shows the whole household load.
            dueThisWeekTaskCount = dueThisWeekTasks.filter { $0.vehicleId == nil }.count
        } catch {}
    }

    /// Phase 50: Resolve the next vendor visits, hydrating each task with
    /// its linked contractor's name, logo URL, brand color, and most
    /// recent service cost. The dashboard's `VendorScheduleStrip` calls
    /// the result hot — we do all the joins up front so scrolling stays
    /// 60fps and the strip never spawns its own network lookups.
    private func loadVendorVisits() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date()

        // Pull only future vendor-assigned tasks. The reconciler tags
        // these via assignment_type = "vendor" both for linked-contractor
        // ("Schedule X: Y") and find-a-contractor ("Find a contractor for: Y")
        // shapes, so this catches both flavors. Vehicle tasks are excluded
        // because the strip is a HOME service schedule.
        guard let allTasks = try? await DatabaseService.shared.fetchMaintenanceTasks() else {
            upcomingVendorVisits = []
            return
        }
        let vendorTasks: [MaintenanceTaskDBRow] = allTasks
            .filter { task in
                guard task.vehicleId == nil else { return false }
                guard task.assignmentType?.lowercased() == "vendor" else { return false }
                guard let date = formatter.date(from: task.nextDueDate) else { return false }
                return date >= now
            }
            .sorted { $0.nextDueDate < $1.nextDueDate }

        let nextVisits = Array(vendorTasks.prefix(6))
        guard !nextVisits.isEmpty else {
            upcomingVendorVisits = []
            return
        }

        // Side-load contractors and the most recent service records once
        // so we can resolve each visit's metadata in one pass.
        let contractors = (try? await DatabaseService.shared.fetchContractors()) ?? []
        let contractorById = Dictionary(uniqueKeysWithValues: contractors.map { ($0.id, $0) })

        // Most recent service record per (system_id, contractor_id) pair —
        // used to surface "Last: $340" on each card. Falls back to system-only
        // and contractor-only matches when the joined pair has no history yet.
        let serviceRecords: [ServiceRecordRow] = (try? await DatabaseService.shared.fetchServiceRecords()) ?? []
        let sortedRecords = serviceRecords.sorted { $0.serviceDate > $1.serviceDate }
        func recentCost(systemId: UUID?, contractorId: UUID?) -> Double? {
            if let systemId, let contractorId,
               let row = sortedRecords.first(where: { $0.systemId == systemId && $0.contractorId == contractorId && $0.cost != nil }) {
                return row.cost
            }
            if let systemId,
               let row = sortedRecords.first(where: { $0.systemId == systemId && $0.cost != nil }) {
                return row.cost
            }
            if let contractorId,
               let row = sortedRecords.first(where: { $0.contractorId == contractorId && $0.cost != nil }) {
                return row.cost
            }
            return nil
        }

        upcomingVendorVisits = nextVisits.map { task in
            let contractor = task.assignedContractorId.flatMap { contractorById[$0] }
            let logoURL = contractor?.logoUrl.flatMap { URL(string: $0) }
            return DashboardVendorVisit(
                task: task,
                vendorName: contractor?.companyName,
                logoURL: logoURL,
                brandColorHex: contractor?.brandColor,
                lastCost: recentCost(systemId: task.systemId, contractorId: contractor?.id)
            )
        }
    }

    private func loadRecentDocuments() async {
        do {
            let docs = try await DatabaseService.shared.fetchDocuments()
            recentDocuments = Array(docs.prefix(5))
            documentCount = docs.count
            hasDocuments = !docs.isEmpty
            allDocuments = docs
        } catch {}
    }

    private func loadGettingStartedState() async {
        let properties = try? await DatabaseService.shared.fetchProperties()
        let foundProperties = !(properties?.isEmpty ?? true)
        // Only update to false if we didn't already optimistically set it to true
        if foundProperties || !hasProperty {
            hasProperty = foundProperties
        }
        let chatMessages = try? await DatabaseService.shared.fetchChatMessages(limit: 1)
        hasUsedAlfred = !(chatMessages?.isEmpty ?? true)

        // Retry once after a short delay if no properties found (RLS propagation)
        if !hasProperty {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            let retryProperties = try? await DatabaseService.shared.fetchProperties()
            if !(retryProperties?.isEmpty ?? true) {
                hasProperty = true
            }
        }
    }

    private func loadRecommendationData() async {
        let vendors = try? await DatabaseService.shared.fetchContractors()
        vendorCount = vendors?.count ?? 0

        let systems = try? await DatabaseService.shared.fetchHomeSystems()
        systemCount = systems?.count ?? 0

        let members = try? await DatabaseService.shared.fetchFamilyMembers()
        familyMembers = members ?? []
        familyMemberCount = familyMembers.count
        expectingMembers = familyMembers.filter { $0.isExpecting == true }

        // Build 87: load paid household staff (home managers etc.) for the
        // new dashboard HouseholdStaffStrip. Filtered server-side via the
        // member_type column added in migration 20260437.
        let staff = try? await DatabaseService.shared.fetchHouseholdStaff()
        householdStaff = staff ?? []

        // Check if user has ever run scenarios
        struct IdRow: Codable { let id: UUID }
        let scenarios: [IdRow]? = try? await HavenSupabase.from("scenario_history")
            .select("id")
            .limit(1)
            .execute()
            .value
        hasRunScenario = !(scenarios?.isEmpty ?? true)

        // Check for pending notifications (proxy for "has reminders enabled")
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        hasRemindersEnabled = !pending.isEmpty

        // Project budget & deadline tracking
        let projects = try? await DatabaseService.shared.fetchAllProjects()
        let activeProjects = projects?.filter { $0.status == "planning" || $0.status == "in_progress" } ?? []
        overBudgetProjectCount = activeProjects.filter { p in
            guard let budget = p.estimatedBudget, let spend = p.actualSpend else { return false }
            return spend > budget
        }.count
        approachingDeadlineProjectCount = activeProjects.filter { p in
            guard let endDate = p.targetEndDate else { return false }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date = formatter.date(from: endDate) else { return false }
            let daysLeft = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 99
            return daysLeft <= 7 && daysLeft >= 0
        }.count

        // Seasonal tasks for current season
        let month = Calendar.current.component(.month, from: .now)
        let season: String = switch month {
        case 3...5: "Spring"
        case 6...8: "Summer"
        case 9...11: "Fall"
        default: "Winter"
        }
        currentSeasonName = season

        let allTasks = try? await DatabaseService.shared.fetchAllMaintenanceTasks()
        let seasonTasks = (allTasks ?? []).filter { task in
            guard let timing = task.seasonalTiming?.lowercased() else { return false }
            return timing.contains(season.lowercased())
        }
        if !seasonTasks.isEmpty {
            let groups = SeasonalTaskGrouper.group(seasonTasks, systemNameLookup: { _ in nil })
            seasonalTasksTotal = groups.count
            seasonalTasksIncomplete = groups.filter { !$0.isComplete }.count
        }

        // Systems without recent service (lastServiceDate nil or > 12 months ago)
        let allSystems = (systems ?? []).filter { $0.parentSystemId == nil } // top-level only
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
        let sdf = DateFormatter()
        sdf.dateFormat = "yyyy-MM-dd"
        systemsNeedingServiceCount = allSystems.filter { sys in
            guard let dateStr = sys.lastServiceDate, let date = sdf.date(from: dateStr) else {
                return true // no service date at all
            }
            return date < oneYearAgo
        }.count

        // Incomplete property data
        if let props = try? await DatabaseService.shared.fetchProperties(), let first = props.first {
            hasIncompleteProperty = first.squareFootage == nil || first.yearBuilt == nil || first.purchasePrice == nil
        }
    }

    private var inboxPollingTask: Task<Void, Never>?

    private func loadVehicleAlerts() async {
        do {
            vehicles = try await DatabaseService.shared.fetchVehicles()
            // Count unresolved recalls across all vehicles
            var totalRecalls = 0
            for vehicle in vehicles {
                let recalls = try await DatabaseService.shared.fetchVehicleRecalls(vehicleId: vehicle.id)
                totalRecalls += recalls.filter { !$0.isResolved }.count
            }
            unresolvedVehicleRecalls = totalRecalls
        } catch {
            print("[Dashboard] Failed to load vehicle alerts: \(error)")
        }
    }

    private func loadEstateState() async {
        guard let householdId = primaryHouseholdId else {
            // Try to get it from properties
            let props = (try? await DatabaseService.shared.fetchProperties()) ?? []
            guard let hid = props.first?.householdId else { return }
            estateState = try? await EstateStateService.shared.fetch(householdId: hid)
            return
        }
        estateState = try? await EstateStateService.shared.fetch(householdId: householdId)
    }

    func loadInboxItems() async {
        do {
            let items = try await DatabaseService.shared.fetchUnseenInboxItems()
            inboxItems = items
            startInboxPollingIfNeeded()
        } catch {
            print("[Dashboard] Failed to load inbox items: \(error)")
        }
    }

    private func startInboxPollingIfNeeded() {
        let hasProcessing = inboxItems.contains { $0.status == "processing" }
        guard hasProcessing, inboxPollingTask == nil else { return }

        inboxPollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                do {
                    let items = try await DatabaseService.shared.fetchUnseenInboxItems()
                    await MainActor.run { inboxItems = items }
                    let stillProcessing = items.contains { $0.status == "processing" }
                    if !stillProcessing { break }
                } catch { break }
            }
            await MainActor.run { inboxPollingTask = nil }
        }
    }

    func stopPolling() {
        inboxPollingTask?.cancel()
        inboxPollingTask = nil
    }

    func dismissInboxItem(_ item: DatabaseService.InboxItemRow) {
        inboxItems.removeAll { $0.id == item.id }
        Task {
            try? await DatabaseService.shared.markInboxItemsSeen(ids: [item.id])
            await loadInboxItems()
        }
    }

    func processInboxItem(_ item: DatabaseService.InboxItemRow, propertyId: UUID?, action: String, category: String?) async {
        do {
            _ = try await HavenSupabase.processInboxItem(
                inboxItemId: item.id.uuidString,
                propertyId: propertyId?.uuidString,
                action: action,
                documentCategory: category
            )
            Haptics.success()
            await loadInboxItems()
        } catch {
            print("[Dashboard] Process inbox item failed: \(error)")
        }
    }

    private func loadEnrichmentData() async {
        do {
            let fetchedProperties = try await DatabaseService.shared.fetchProperties()
            properties = fetchedProperties

            // Check for properties with incomplete addresses
            propertyNeedsAddress = fetchedProperties.first { p in
                (p.street == nil || p.street?.isEmpty == true) &&
                (p.city == nil || p.city?.isEmpty == true)
            }

            if let primary = fetchedProperties.first {
                primaryPropertyId = primary.id
                primaryHouseholdId = primary.householdId
                primaryYearBuilt = primary.yearBuilt
                primaryPropertyLocation = [primary.city, primary.state].compactMap { $0 }.joined(separator: ", ")
                propertyAttributes = primary.attributes ?? [:]

                let contracts = try await DatabaseService.shared.fetchServiceContracts(propertyId: primary.id)
                serviceContracts = contracts

                let systems = try await DatabaseService.shared.fetchHomeSystems(propertyId: primary.id)
                homeSystems = systems

                // Check if user has any projects (to suppress ROI suggestions if they do)
                let projects = try? await DatabaseService.shared.fetchProjects(propertyId: primary.id)
                hasActiveProjects = !(projects?.isEmpty ?? true)
            }
        } catch {
            print("[Dashboard] Failed to load enrichment data: \(error)")
        }
    }
}

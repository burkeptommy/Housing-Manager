import SwiftUI
import UserNotifications

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
    @Published var dismissedRecommendationIds: Set<String> = []

    // Expecting members
    @Published var expectingMembers: [FamilyMemberRow] = []
    @Published var allDocuments: [DocumentRow] = []

    // Enrichment cards
    @Published var propertyAttributes: [String: FlexibleValue] = [:]
    @Published var serviceContracts: [ServiceContractRow] = []
    @Published var homeSystems: [HomeSystemRow] = []
    @Published var dismissedEnrichmentIds: Set<String> = []
    @Published var primaryPropertyId: UUID?
    @Published var primaryHouseholdId: UUID?

    var showGettingStarted: Bool {
        !hasProperty || !hasDocuments || !hasUsedAlfred
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
            dismissedIds: dismissedRecommendationIds
        )
    }

    var enrichmentQuestions: [EnrichmentQuestion] {
        EnrichmentEngine.evaluate(
            propertyAttributes: propertyAttributes,
            serviceContracts: serviceContracts,
            homeSystems: homeSystems,
            dismissedIds: dismissedEnrichmentIds
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

    func loadDashboard() async {
        loadDismissedRecommendations()
        loadDismissedEnrichmentCards()
        isLoading = true
        defer { isLoading = false }
        await fetchAll()
        Analytics.track(.dashboardRefreshed, ["type": "initial_load", "overdue_count": overdueMaintenanceTasks.count, "document_count": documentCount])
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await fetchAll()
    }

    private func fetchAll() async {
        async let scoresTask: Void = loadCompletionScores()
        async let expirationsTask: Void = loadExpirations()
        async let maintenanceTask: Void = loadOverdueMaintenance()
        async let recentTask: Void = loadRecentDocuments()
        async let userTask: Void = loadUserName()
        async let gettingStartedTask: Void = loadGettingStartedState()
        async let recommendationTask: Void = loadRecommendationData()
        async let enrichmentTask: Void = loadEnrichmentData()
        _ = await (scoresTask, expirationsTask, maintenanceTask, recentTask, userTask, gettingStartedTask, recommendationTask, enrichmentTask)
    }

    private func loadUserName() async {
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            if let fullName = user.fullName, !fullName.isEmpty {
                userFirstName = fullName.components(separatedBy: " ").first
            }
        } catch {}
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
        } catch {}
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
        familyMemberCount = members?.count ?? 0
        expectingMembers = (members ?? []).filter { $0.isExpecting == true }

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
    }

    private func loadEnrichmentData() async {
        do {
            let properties = try await DatabaseService.shared.fetchProperties()
            if let primary = properties.first {
                primaryPropertyId = primary.id
                primaryHouseholdId = primary.householdId
                propertyAttributes = primary.attributes ?? [:]

                let contracts = try await DatabaseService.shared.fetchServiceContracts(propertyId: primary.id)
                serviceContracts = contracts

                let systems = try await DatabaseService.shared.fetchHomeSystems(propertyId: primary.id)
                homeSystems = systems
            }
        } catch {
            print("[Dashboard] Failed to load enrichment data: \(error)")
        }
    }
}

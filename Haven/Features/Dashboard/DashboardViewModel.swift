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

    // MARK: - Build 90: Focused Dashboard

    /// Coverage Hero: systems that have a vendor (contractor linked or
    /// category-matched) vs systems that SHOULD have a vendor.
    @Published var coveredSystemCount: Int = 0
    @Published var totalVendorSystemCount: Int = 0
    @Published var activeVendorCount: Int = 0
    @Published var nextScheduledService: (vendorName: String, date: String, taskTitle: String)?
    @Published var uncoveredSystemNames: [String] = []
    @Published var coveredSystemSummaries: [(systemName: String, vendorName: String, cadence: String?)] = []

    /// Phase 84: Chez ownership counts for the Dashboard hero card.
    /// `chezActiveGroupCount` is how many of the 8 group toggles are on
    /// (e.g., "all routines", "all systems"). `chezDelegatedItemCount`
    /// is the per-entity delegated count (individual routines /
    /// contractors / tasks the homeowner toggled directly).
    @Published var chezActiveGroupCount: Int = 0
    @Published var chezDelegatedItemCount: Int = 0

    /// Phase 85 — "This week with Chez" digest fed by chez_activity_log.
    /// `chezActivityWeeklyTally` powers the Dashboard ChezActivityCard's
    /// glanceable counts; `recentChezActivity` is the most-recent N rows
    /// for the preview line on the same card. Loaded lazily on first
    /// dashboard load and refreshed when the homeowner pulls to refresh.
    @Published var chezActivityWeeklyTally: ChezActivityWeeklyTally = .empty
    @Published var recentChezActivity: [ChezActivityLogRow] = []

    /// Phase 84.5 — Active home_assessments row for the primary
    /// property. Non-nil when the homeowner picked "Have Chez handle it"
    /// at signup AND status NOT IN (completed, cancelled). The dashboard
    /// renders `HomeAssessmentPendingCard` + `HomeAssessmentPrepCard`
    /// based on this.
    @Published var homeAssessment: HomeAssessmentRow? = nil

    // Phase 50: Registry-aware coverage items for the redesigned sheet
    @Published var uncoveredCoverageItems: [VendorCoverageItem] = []
    @Published var coveredCoverageItems: [VendorCoverageItem] = []

    // Phase 50: Recent activity events for the dashboard feed
    @Published var recentActivityEvents: [RecentActivityEvent] = []
    /// Phase 52: Full (un-truncated) activity event list for ActivityLogView.
    @Published var allActivityEvents: [RecentActivityEvent] = []
    /// Phase 52: Projects snapshot for activity feed assembly.
    @Published var dashboardProjects: [PropertyProjectRow] = []

    /// Up Next: max 5 smart-filtered items replacing the 38-item
    /// NEEDS YOUR ATTENTION list. Excludes "find a contractor" items
    /// (handled by Coverage Hero nudge) and tasks > 60 days out.
    @Published var thisWeekItems: [ThisWeekItem] = []

    /// Current authenticated user ID, loaded in fetchAll for
    /// user-assignment filtering in computeThisWeekItems.
    private var currentUserId: UUID?

    /// Foundation: contextual estate card that only shows when actionable.
    @Published var shouldShowFoundation: Bool = false
    @Published var foundationMessage: String = ""
    @Published var foundationIcon: String = "doc.text.fill"

    var vendorCoverageRatio: Double {
        guard totalVendorSystemCount > 0 else { return 1.0 }
        return Double(coveredSystemCount) / Double(totalVendorSystemCount)
    }

    /// Phase 56.2: One-liner seasonal context tip for the compact
    /// greeting. Surfaces the next upcoming vendor visit when one is
    /// within 7 days (highest signal), otherwise falls back to
    /// month-driven Northeast-climate copy. Returns nil when there's
    /// nothing contextually relevant to say — the greeting renders
    /// without it, which is fine.
    var seasonalContextTip: String? {
        let calendar = Calendar.current
        let now = Date()

        // Upcoming vendor visit in the next week takes precedence.
        if let next = upcomingVendorVisits.first,
           let scheduled = Self.havenDateParser.date(from: next.task.nextDueDate) {
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: scheduled)).day ?? 99
            if days >= 0 && days <= 7, let vendor = next.vendorName {
                let when: String
                switch days {
                case 0: when = "today"
                case 1: when = "tomorrow"
                default: when = "in \(days) days"
                }
                return "\(vendor) visit coming up \(when)."
            }
        }

        // Northeast-climate seasonal fallbacks. Static copy for v1;
        // future iteration can make these data-driven from the user's
        // actual systems and climate zone.
        switch calendar.component(.month, from: now) {
        case 3, 4:
            return "Spring prep season. Time to schedule HVAC tune-ups and lawn care startup."
        case 5:
            return "Pool opening season. Irrigation systems should be checked before Memorial Day."
        case 6, 7, 8:
            return "Peak maintenance season. Most of your vendors are running."
        case 9:
            return "Fall prep. Gutter cleaning, HVAC heating check, and snow contracts ahead."
        case 10:
            return "Snow removal contracts close soon. Generator service before first frost."
        case 11:
            return "Winterization window. Irrigation blowout, exterior paint touch-up."
        case 12, 1, 2:
            return "Winter mode. Indoor maintenance only. Good time to review estate documents."
        default:
            return nil
        }
    }

    /// Phase 56.2: Shared date parser for `nextDueDate` strings (stored
    /// as `yyyy-MM-dd`). Lives as a static on the view model so it
    /// doesn't get rebuilt on every accessor call.
    private static let havenDateParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    /// Phase 56.2: Filtered activity feed for the dashboard. After the
    /// first week of account age, the "X added" entries from the quiz
    /// / mirror flows are suppressed so Recent surfaces real activity
    /// (invoices, completions, visits) instead of a log of what the
    /// quiz built. The unfiltered list is still available via
    /// `allActivityEvents` for the full ActivityLogView.
    ///
    /// Events are kept when:
    ///   - Account is ≤7 days old (the onboarding celebration moment)
    ///   - The event type isn't one of the noisy onboarding types
    ///   - OR the event happened >48h after account creation (genuine
    ///     user-initiated additions, not quiz artifacts)
    var dashboardActivityEvents: [RecentActivityEvent] {
        guard let createdAt = accountCreatedAt else {
            return recentActivityEvents
        }
        let calendar = Calendar.current
        let now = Date()
        let userAgeDays = calendar.dateComponents([.day], from: createdAt, to: now).day ?? 0
        if userAgeDays <= 7 {
            return recentActivityEvents
        }

        let onboardingNoiseTypes: Set<ActivityEventType> = [.vendorLinked, .systemAdded]
        return recentActivityEvents.filter { event in
            if !onboardingNoiseTypes.contains(event.eventType) { return true }
            let hoursSinceCreation = calendar.dateComponents(
                [.hour], from: createdAt, to: event.occurredAt
            ).hour ?? 0
            return hoursSinceCreation > 48
        }
    }
    @Published var recentDocuments: [DocumentRow] = []
    /// Phase 50: Tasks completed in the last 30 days, for the Recent Activity feed.
    @Published var recentlyCompletedTasks: [MaintenanceTaskDBRow] = []
    /// Phase 51B: Household contractors for the Recent Activity feed.
    @Published var dashboardContractors: [ContractorRow] = []
    /// Phase 51B: Earliest standing appointment visit date for dashboard hero.
    @Published var nextStandingVisit: (vendor: String, date: String, title: String)?
    @Published var userFirstName: String?

    /// Phase 56.2: Account creation timestamp, sourced from the
    /// authenticated user's `created_at`. Used by `dashboardActivityEvents`
    /// to suppress onboarding "X added" entries from the Recent feed
    /// after the first week.
    @Published var accountCreatedAt: Date?

    /// Phase 56.4: Pending handyman punch item count for the active
    /// household. Loaded alongside other dashboard data; gates the
    /// `HandymanSuggestionCard` at the top of the dashboard.
    @Published private(set) var handymanPunchItemCount: Int = 0

    /// Phase 67 (G1): Seasonal "time to book your handyman" reminder.
    /// Computed from the singleton `handyman_recurring` routine's anchor
    /// months (April + October) and the current date. Surfaces in
    /// Dashboard above Up Next when:
    ///   * a handyman_recurring routine exists for the property,
    ///   * pending punch items > 0,
    ///   * today is within ±14 days of an April 1 / October 1 anchor.
    /// Tap routes the user into the Tasks → Handyman flow via the
    /// existing `.handymanModeRequested` notification.
    @Published private(set) var handymanSeasonalReminder: HandymanSeasonalReminder?

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

    /// Phase 61: Count of archived maintenance tasks for the household. Drives
    /// `LegacyTasksNotificationCard` visibility on the dashboard. Archived rows
    /// originate from any reconciler pass (subtype mismatch, bundle backfill,
    /// Phase 58 orphan prune, future retirement cycles) — the user's mental
    /// model is "Chez tidied my list," so one count covers every source.
    @Published var legacyTaskCount: Int = 0

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

    /// Build 91 — dismissed coverage categories for the Vendor Coverage
    /// sheet. Loaded once per refresh from `dismissed_categories` and
    /// applied inside `computeCoverage` so swiped rows stay hidden across
    /// dashboard reloads.
    @Published var dismissedCoverageCategories: Set<String> = []

    // Chez v1: shouldShowEstateDripCard + dismissEstateDrip removed —
    // estate management is out of v1 scope. estateState property kept
    // as @Published var for now since RecommendationEngine + edge
    // function context still reference it; SmartRecommendations cleanup
    // and estateState removal land in the same Phase 3 sweep.

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
            hasRemindersEnabled: hasRemindersEnabled,
            overBudgetProjectCount: overBudgetProjectCount,
            approachingDeadlineProjectCount: approachingDeadlineProjectCount,
            seasonalTasksIncomplete: seasonalTasksIncomplete,
            seasonalTasksTotal: seasonalTasksTotal,
            currentSeasonName: currentSeasonName,
            systemsNeedingServiceCount: systemsNeedingServiceCount,
            hasIncompleteProperty: hasIncompleteProperty,
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
                loadEstateState, loadVendorVisits, loadHouseholdEmail,
                loadHandymanPunchCount,
                loadHandymanSeasonalReminder,
                loadChezOwnershipCounts,
                // Phase 85 — "This week with Chez" digest powering the
                // Dashboard ChezActivityCard. Empty for DIY-default
                // users; populated as ingestion + chez_owned task
                // completion fire chez_activity_log inserts.
                loadChezActivity,
                // Phase 84.5 — fetch the active home_assessments row
                // (or nil when not in handyman mode). Drives the
                // HomeAssessmentPendingCard + HomeAssessmentPrepCard.
                loadHomeAssessment,
            ]
            for method in methods {
                group.addTask { @MainActor in
                    // Ignore cancellation — we want these to complete
                    await Task { await method() }.value
                }
            }
        }

        // Build 90: compute derived dashboard state after all data is loaded
        computeThisWeekItems()
        computeFoundationState()
        computeRecentActivity()
    }

    private func loadUserName() async {
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            currentUserId = user.id
            // Phase 56.2: capture the account creation date so the
            // Recent feed can filter "X added" onboarding events after
            // the user's first week.
            accountCreatedAt = user.createdAt
            if let fullName = user.fullName, !fullName.isEmpty {
                userFirstName = fullName.components(separatedBy: " ").first
            } else {
                // Fallback for users who onboarded before the fix that writes
                // fullName to the users table. Read from the Primary Client
                // family member instead.
                let members = try await DatabaseService.shared.fetchFamilyMembers()
                if let primary = members.first(where: { $0.relationship == "Primary Client" }) {
                    userFirstName = primary.firstName
                }
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

    /// Phase 56.4: Load pending handyman punch item count alongside
    /// the rest of the dashboard's data. `shouldShowHandymanSuggestion`
    /// reads from this value plus the already-loaded `allUpcomingTasks`
    /// and `recentlyCompletedTasks` to decide whether to surface the
    /// proactive scheduling card.
    private func loadHandymanPunchCount() async {
        guard let householdId = primaryHouseholdId else {
            handymanPunchItemCount = 0
            return
        }
        do {
            let items = try await DatabaseService.shared.fetchPendingHandymanPunchItems(householdId: householdId)
            handymanPunchItemCount = items.count
        } catch {
            handymanPunchItemCount = 0
        }
    }

    /// Phase 67 (G1): Compute the seasonal handyman reminder. Surfaces
    /// the "Time to book your handyman" card on Dashboard above Up Next
    /// when an April / October anchor is within ±14 days AND the user
    /// has a handyman_recurring routine + at least one pending punch item.
    /// Vendor name (if linked) drives a personalized subtitle ("Mike's
    /// Handyman crew · 8 items ready").
    private func loadHandymanSeasonalReminder() async {
        guard let householdId = primaryHouseholdId,
              let propertyId = primaryPropertyId else {
            handymanSeasonalReminder = nil
            return
        }
        // Window check first — cheap, avoids DB calls outside the seasonal window.
        guard let window = HandymanSeasonalReminder.currentWindow() else {
            handymanSeasonalReminder = nil
            return
        }

        // Punch items + routine + optional vendor name. All three required
        // for the card to render.
        let punchCount: Int
        do {
            let items = try await DatabaseService.shared.fetchPendingHandymanPunchItems(householdId: householdId)
            punchCount = items.filter { $0.propertyId == propertyId }.count
        } catch {
            punchCount = 0
        }
        guard punchCount > 0 else {
            handymanSeasonalReminder = nil
            return
        }

        let routine: RoutineRow?
        do {
            routine = try await DatabaseService.shared.fetchHandymanRoutine(
                householdId: householdId,
                propertyId: propertyId
            )
        } catch {
            routine = nil
        }
        guard let routine, routine.archivedAt == nil else {
            handymanSeasonalReminder = nil
            return
        }

        var vendorName: String?
        if let vendorId = routine.vendorId {
            vendorName = (try? await DatabaseService.shared.fetchContractor(id: vendorId))?.companyName
        }

        handymanSeasonalReminder = HandymanSeasonalReminder(
            season: window.season,
            daysAway: window.daysAway,
            pendingItemCount: punchCount,
            vendorName: vendorName
        )
    }

    /// Phase 56.4: Whether to surface the proactive "Schedule handyman
    /// visit" suggestion. Triggered when:
    /// - Punch list has ≥1 pending item
    /// - AND no Handyman task is scheduled in the next 30 days
    /// - AND no Handyman task completed in the last 90 days
    var shouldShowHandymanSuggestion: Bool {
        guard handymanPunchItemCount >= 1 else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date()
        let in30Days = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: now) ?? now

        let upcomingHandyman = allUpcomingTasks.contains { task in
            guard task.templateId?.hasPrefix("Handyman:") == true else { return false }
            let dateString = task.scheduledDate ?? task.nextDueDate
            guard let due = formatter.date(from: dateString) else { return false }
            return due >= now && due <= in30Days
        }
        if upcomingHandyman { return false }

        let recentHandyman = recentlyCompletedTasks.contains { task in
            guard task.templateId?.hasPrefix("Handyman:") == true else { return false }
            guard let completed = task.lastCompletedDate.flatMap({ formatter.date(from: $0) }) else { return false }
            return completed > ninetyDaysAgo
        }
        if recentHandyman { return false }

        return true
    }

    /// Phase 84 — Count what's currently delegated to Chez. Drives the
    /// Dashboard hero card's "Chez handles N for you" copy + the
    /// 3-mode visual state (DIY / Blend / Full).
    private func loadChezOwnershipCounts() async {
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                chezActiveGroupCount = 0
                chezDelegatedItemCount = 0
                return
            }
            async let householdReq = DatabaseService.shared.fetchHousehold(id: householdId)
            async let routinesReq = DatabaseService.shared.fetchRoutines(householdId: householdId)
            async let contractorsReq = DatabaseService.shared.fetchContractors()
            async let tasksReq = DatabaseService.shared.fetchMaintenanceTasks()
            let (household, routines, contractors, tasks) = try await (householdReq, routinesReq, contractorsReq, tasksReq)
            let groups = ["all_routines", "all_systems", "all_vendors", "all_projects",
                          "all_bills", "all_documents", "all_insurance", "all_vehicles"]
            chezActiveGroupCount = groups.filter { household.isOwnershipGroupOn($0) }.count
            let routineDel = routines.filter { $0.chezOwned }.count
            let contractorDel = contractors.filter { $0.isChezOwned }.count
            let taskDel = tasks.filter { $0.isChezOwned }.count
            chezDelegatedItemCount = routineDel + contractorDel + taskDel
        } catch {
            print("[Dashboard] loadChezOwnershipCounts failed: \(error)")
        }
    }

    /// Phase 85 — Load the last 7 days of chez_activity_log for the
    /// "This week with Chez" Dashboard card. Sets the tally + a
    /// preview slice for the bottom of the card. Soft-fails: empty
    /// tally on error so the card simply hides.
    func loadChezActivity() async {
        guard let householdId = primaryHouseholdId else {
            chezActivityWeeklyTally = .empty
            recentChezActivity = []
            return
        }
        do {
            let rows = try await DatabaseService.shared.fetchChezActivity(
                householdId: householdId,
                daysBack: 7,
                dashboardOnly: true,
                limit: 50
            )
            chezActivityWeeklyTally = ChezActivityWeeklyTally.from(rows)
            recentChezActivity = Array(rows.prefix(3))
        } catch {
            print("[Dashboard] loadChezActivity failed: \(error)")
            chezActivityWeeklyTally = .empty
            recentChezActivity = []
        }
    }

    /// Phase 84.5 — Load the active home_assessments row for the
    /// primary property. Called from `fetchAll`. Sets `homeAssessment`
    /// to nil when no active row exists; the dashboard then suppresses
    /// the pending + prep cards.
    func loadHomeAssessment() async {
        guard let propertyId = primaryPropertyId else {
            homeAssessment = nil
            return
        }
        do {
            let row = try await HavenSupabase.fetchHomeAssessment(
                assessmentId: nil,
                propertyId: propertyId
            )
            // Suppress on completed/cancelled — those are terminal and
            // the dashboard shouldn't show the card after the homeowner
            // reviewed.
            if let r = row, !r.status.isActive {
                homeAssessment = nil
            } else {
                homeAssessment = row
            }
        } catch {
            print("[Dashboard] loadHomeAssessment failed: \(error)")
            homeAssessment = nil
        }
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

            // Phase 61: also count archived tasks for the LegacyTasksNotificationCard.
            // Separate fetch so the main list stays filtered to active rows.
            if let allIncludingArchived = try? await DatabaseService.shared.fetchAllMaintenanceTasks(includeArchived: true) {
                legacyTaskCount = allIncludingArchived.filter { $0.isArchived == true }.count
            }

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

            // Phase 50: Completed tasks in the last 30 days for Recent Activity
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
            recentlyCompletedTasks = tasks.filter { task in
                guard let dateStr = task.lastCompletedDate,
                      let date = dateFormatter.date(from: dateStr)
                else { return false }
                return date >= thirtyDaysAgo
            }
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
        dashboardContractors = contractors
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

        // Phase 51B: Check standing appointments for the earliest upcoming visit
        if let householdId = primaryHouseholdId {
            let appointments = (try? await DatabaseService.shared.fetchStandingAppointments(householdId: householdId)) ?? []
            let contractorById = Dictionary(uniqueKeysWithValues: contractors.map { ($0.id, $0) })
            var earliest: (vendor: String, date: String, title: String)?
            for appt in appointments where !appt.isPaused && appt.archivedAt == nil {
                let name = appt.vendorId.flatMap({ contractorById[$0]?.companyName }) ?? "Vendor"
                if earliest == nil || appt.nextExpectedDate < (earliest?.date ?? "9999") {
                    earliest = (vendor: name, date: appt.nextExpectedDate, title: appt.serviceDescription ?? name)
                }
            }
            nextStandingVisit = earliest
        }

        // Build 90: compute coverage ratio using the same data we just fetched.
        // Build 91: also fetch dismissed_categories so the coverage sheet
        // respects prior user "Hide" swipes on rows they don't want to see.
        let systems = (try? await DatabaseService.shared.fetchHomeSystems()) ?? []
        let dismissed = (try? await DatabaseService.shared.fetchDismissedCategories()) ?? []
        dismissedCoverageCategories = Set(dismissed.map(\.category))
        computeCoverage(allTasks: allTasks, contractors: contractors, systems: systems)
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
        dashboardProjects = projects ?? []
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
        // Chez v1: estate state fetch is a no-op. The property is kept on
        // the view model so RecommendationEngine + activity feed can still
        // pass it through, but it always reads as nil and nothing in the
        // UI depends on it any more.
        estateState = nil
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

    // MARK: - Build 90: Coverage + This Week + Foundation

    /// Compute vendor coverage ratio by cross-referencing systems with
    /// vendor-type tasks against the household's contractor directory.
    /// Called from `loadVendorVisits()` to reuse the already-fetched
    /// tasks and contractors arrays.
    private func computeCoverage(
        allTasks: [MaintenanceTaskDBRow],
        contractors: [ContractorRow],
        systems: [HomeSystemRow]
    ) {
        let vendorTasks = allTasks.filter {
            $0.vehicleId == nil && $0.assignmentType?.lowercased() == "vendor"
        }

        // Only count top-level systems (exclude children like individual HVAC
        // components) so "Water Heater" under HVAC doesn't inflate the count.
        let topLevelSystemIds = Set(systems.filter { $0.parentSystemId == nil }.map(\.id))

        // Unique top-level system IDs that have vendor-type tasks (denominator)
        let systemIdsWithVendorTasks = Set(vendorTasks.compactMap(\.systemId)).intersection(topLevelSystemIds)

        // Systems that have at least one contractor linked via tasks
        let coveredByTask = Set(
            vendorTasks
                .filter { $0.assignedContractorId != nil }
                .compactMap(\.systemId)
        ).intersection(topLevelSystemIds)

        // Systems that have a preferred contractor assigned directly
        let coveredByPreferredContractor = Set(
            systems
                .filter { $0.preferredContractorId != nil }
                .map(\.id)
        ).intersection(topLevelSystemIds)

        // Related categories: when a contractor covers one category,
        // they likely cover related systems (landscaper handles irrigation, etc.)
        let relatedCategories: [String: Set<String>] = [
            "Landscaping": ["Irrigation"],
            "HVAC": ["Ductwork", "Water Heater", "Heating", "Air Conditioning"],
            "Plumbing": ["Water Heater"],
            "Electrical": ["Generator", "EV Charger"],
            "Roofing": ["Gutters"],
        ]
        // Build expanded contractor categories including related ones
        let directCategories = Set(contractors.compactMap(\.category))
        var contractorCategories = directCategories
        for cat in directCategories {
            if let related = relatedCategories[cat] {
                contractorCategories.formUnion(related)
            }
        }

        // Systems covered by category match (contractor exists in household
        // whose category matches the system's category or a related one)
        let systemById = Dictionary(uniqueKeysWithValues: systems.map { ($0.id, $0) })
        let coveredByCategory = Set(
            systemIdsWithVendorTasks.filter { sysId in
                guard let sys = systemById[sysId] else { return false }
                return contractorCategories.contains(sys.category)
            }
        )

        let allCovered = coveredByTask.union(coveredByCategory).union(coveredByPreferredContractor)
        coveredSystemCount = allCovered.count
        totalVendorSystemCount = systemIdsWithVendorTasks.count
        activeVendorCount = Set(vendorTasks.compactMap(\.assignedContractorId)).count

        // Uncovered system names for the nudge — deduplicate by category
        // so "HVAC" and "Water Heater" don't both appear
        let uncoveredIds = systemIdsWithVendorTasks.subtracting(allCovered)
        var seenCategories = Set<String>()
        var dedupedNames: [String] = []
        for sysId in uncoveredIds.sorted(by: { ($0.uuidString) < ($1.uuidString) }) {
            guard let sys = systemById[sysId] else { continue }
            if seenCategories.contains(sys.category) { continue }
            seenCategories.insert(sys.category)
            dedupedNames.append(sys.name)
        }
        uncoveredSystemNames = dedupedNames.sorted()

        // Covered systems with their vendor name for the coverage sheet
        let contractorById = Dictionary(uniqueKeysWithValues: contractors.map { ($0.id, $0) })
        // Build covered summaries with cadence, then deduplicate by (name, vendor)
        let rawCovered: [(systemName: String, vendorName: String, cadence: String?)] = allCovered.compactMap { sysId in
            guard let sys = systemById[sysId] else { return nil }
            let vendorName: String
            if let task = vendorTasks.first(where: { $0.systemId == sysId && $0.assignedContractorId != nil }),
               let cId = task.assignedContractorId,
               let contractor = contractorById[cId] {
                vendorName = contractor.companyName
            } else if let contractor = contractors.first(where: { $0.category == sys.category }) {
                vendorName = contractor.companyName
            } else {
                vendorName = "Covered"
            }
            // Cadence from system interval or first vendor task frequency
            let cadence: String?
            if let days = sys.serviceIntervalDays, days > 0 {
                cadence = Self.humanCadence(days: days)
            } else if let task = vendorTasks.first(where: { $0.systemId == sysId }),
                      !task.frequency.isEmpty, task.frequency.lowercased() != "once" {
                cadence = task.frequency
            } else {
                cadence = nil
            }
            return (systemName: sys.name, vendorName: vendorName, cadence: cadence)
        }
        // Deduplicate by (systemName, vendorName)
        var seen = Set<String>()
        coveredSystemSummaries = rawCovered
            .sorted { $0.systemName < $1.systemName }
            .filter { seen.insert("\($0.systemName)|\($0.vendorName)").inserted }

        // Phase 50: Registry-aware coverage items for the redesigned sheet.
        // Build 91: filter out categories the user has previously swiped
        // "Hide" on (persisted in `dismissed_categories`) so the row
        // doesn't reappear on every refresh.
        let registryCoverage = SystemCategoryRegistry.vendorCoverageItems(
            existingSystems: systems,
            contractors: contractors,
            vendorTasks: vendorTasks
        )
        uncoveredCoverageItems = registryCoverage.uncovered.filter {
            !dismissedCoverageCategories.contains($0.id)
        }
        coveredCoverageItems = registryCoverage.covered

        // Next scheduled service — check both vendor tasks AND standing
        // appointment visits (pre-loaded in loadVendorVisits), use the earlier.
        let taskNext: (vendor: String, date: String, title: String)? = upcomingVendorVisits.first.map {
            (vendor: $0.vendorName ?? "Vendor", date: $0.task.nextDueDate, title: $0.task.title)
        }
        let apptNext = nextStandingVisit

        if let fromAppts = apptNext, let fromTasks = taskNext {
            nextScheduledService = fromAppts.date < fromTasks.date
                ? (vendorName: fromAppts.vendor, date: fromAppts.date, taskTitle: fromAppts.title)
                : (vendorName: fromTasks.vendor, date: fromTasks.date, taskTitle: fromTasks.title)
        } else if let fromAppts = apptNext {
            nextScheduledService = (vendorName: fromAppts.vendor, date: fromAppts.date, taskTitle: fromAppts.title)
        } else if let next = upcomingVendorVisits.first {
            nextScheduledService = (
                vendorName: next.vendorName ?? "Vendor",
                date: next.task.nextDueDate,
                taskTitle: next.task.title
            )
        } else {
            nextScheduledService = nil
        }
    }

    private static func humanCadence(days: Int) -> String {
        switch days {
        case 1...6: return "Every \(days) day\(days == 1 ? "" : "s")"
        case 7: return "Weekly"
        case 8...13: return "Every \(days) days"
        case 14: return "Every 2 weeks"
        case 15...27: return "Every \(days) days"
        case 28...31: return "Monthly"
        case 32...59: return "Every \(days) days"
        case 60...62: return "Every 2 months"
        case 83...97: return "Quarterly"
        case 150...210: return "Every 6 months"
        case 335...395: return "Annually"
        case 700...740: return "Every 2 years"
        default: return "Every \(days) days"
        }
    }

    /// Build the "This Week" list: max 3 items, smart-filtered.
    /// Excludes "find a contractor" tasks (handled by Coverage Hero)
    /// and anything > 7 days out.
    func computeThisWeekItems() {
        var items: [ThisWeekItem] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date()
        let endOfWindow = Calendar.current.date(byAdding: .day, value: 60, to: now) ?? now

        // Helper to look up contractor name for a task
        func contractorName(for task: MaintenanceTaskDBRow) -> String? {
            upcomingVendorVisits.first(where: { $0.task.id == task.id })?.vendorName
        }

        // User-assignment filter: only show tasks assigned to the current
        // user or unassigned tasks.
        func isAssignedToCurrentUser(_ task: MaintenanceTaskDBRow) -> Bool {
            guard let assignee = task.assignedToUserId else { return true }
            return assignee == currentUserId
        }

        // 60-day window tasks for sections 2 and 3
        let dueInWindowTasks = allUpcomingTasks.filter { task in
            guard let date = formatter.date(from: task.nextDueDate) else { return false }
            return date >= now && date <= endOfWindow
        }

        // 1. Overdue tasks (highest priority)
        for task in overdueMaintenanceTasks where task.vehicleId == nil {
            guard !(task.needsVendor == true && task.assignedContractorId == nil) else { continue }
            guard isAssignedToCurrentUser(task) else { continue }
            let name = contractorName(for: task)
            let title = name != nil ? "\(name!) -- overdue" : task.title
            items.append(ThisWeekItem(
                id: task.id,
                title: title,
                subtitle: "Overdue",
                icon: "exclamationmark.triangle.fill",
                urgencyColor: HavenColors.critical,
                kind: .overdue(task)
            ))
            if items.count >= 5 { break }
        }

        guard items.count < 5 else {
            thisWeekItems = Array(items.prefix(5))
            return
        }

        // 2. Vendor visits due in window
        let addedIds = Set(items.map(\.id))
        for task in dueInWindowTasks where task.vehicleId == nil {
            guard !addedIds.contains(task.id) else { continue }
            guard task.assignmentType?.lowercased() == "vendor" else { continue }
            guard task.assignedContractorId != nil else { continue }
            guard isAssignedToCurrentUser(task) else { continue }
            let name = contractorName(for: task) ?? "Vendor"
            let dateStr = formatShortDate(task.nextDueDate)
            items.append(ThisWeekItem(
                id: task.id,
                title: "\(name) visit \(dateStr)",
                subtitle: task.title.capitalized,
                icon: "calendar.badge.clock",
                urgencyColor: HavenColors.info,
                kind: .vendorVisit(task)
            ))
            if items.count >= 5 { break }
        }

        guard items.count < 5 else {
            thisWeekItems = Array(items.prefix(5))
            return
        }

        // 3. Personal DIY tasks due in window
        let addedIds2 = Set(items.map(\.id))
        for task in dueInWindowTasks where task.vehicleId == nil {
            guard !addedIds2.contains(task.id) else { continue }
            guard task.assignmentType?.lowercased() != "vendor" else { continue }
            guard !(task.needsVendor == true) else { continue }
            guard isAssignedToCurrentUser(task) else { continue }
            items.append(ThisWeekItem(
                id: task.id,
                title: task.title,
                subtitle: nil,
                icon: "wrench.and.screwdriver.fill",
                urgencyColor: HavenColors.navy800,
                kind: .diyTask(task)
            ))
            if items.count >= 5 { break }
        }

        guard items.count < 5 else {
            thisWeekItems = Array(items.prefix(5))
            return
        }

        // 4. Inbox items needing review
        let pendingInbox = inboxItems.filter { $0.isPending }.count
        if pendingInbox > 0 {
            items.append(ThisWeekItem(
                id: UUID(),
                title: "\(pendingInbox) forwarded email\(pendingInbox == 1 ? "" : "s") need\(pendingInbox == 1 ? "s" : "") review",
                subtitle: nil,
                icon: "envelope.badge.fill",
                urgencyColor: HavenColors.warning,
                kind: .inboxReview(count: pendingInbox)
            ))
        }

        thisWeekItems = Array(items.prefix(5))
    }

    /// Phase 52: Snooze a task by pushing its due date forward 7 days.
    func snoozeTask(_ item: ThisWeekItem) async {
        guard let task = item.task else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let currentDue = formatter.date(from: task.nextDueDate),
              let newDue = Calendar.current.date(byAdding: .day, value: 7, to: currentDue)
        else { return }
        var update = MaintenanceTaskUpdate()
        update.nextDueDate = formatter.string(from: newDue)
        _ = try? await DatabaseService.shared.updateMaintenanceTask(id: task.id, update)
        Haptics.light()
        await refresh()
    }

    /// Chez v1: estate-driven foundation card removed from the Dashboard.
    /// The function is now a no-op so existing call sites keep compiling
    /// while the published flags stay false. The properties themselves
    /// (`shouldShowFoundation`, `foundationMessage`, `foundationIcon`)
    /// stay declared so anything observing them doesn't crash; they
    /// can be removed alongside the SmartRecommendations estate sweep.
    func computeFoundationState() {
        shouldShowFoundation = false
    }

    // MARK: - Phase 50: Recent Activity

    func computeRecentActivity() {
        let result = RecentActivityFeed.assembleEvents(
            tasks: recentlyCompletedTasks,
            documents: recentDocuments,
            systems: homeSystems,
            contractors: dashboardContractors,
            vehicles: vehicles,
            inboxItems: inboxItems,
            properties: properties,
            familyMembers: familyMembers,
            projects: dashboardProjects
        )
        recentActivityEvents = result.displayEvents
        allActivityEvents = result.allEvents
    }

    private func formatShortDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        return dayFormatter.string(from: date)
    }
}

// MARK: - This Week Item Model

struct ThisWeekItem: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String?
    let icon: String
    let urgencyColor: Color

    enum ThisWeekKind {
        case overdue(MaintenanceTaskDBRow)
        case vendorVisit(MaintenanceTaskDBRow)
        case diyTask(MaintenanceTaskDBRow)
        case inboxReview(count: Int)
    }

    let kind: ThisWeekKind

    var task: MaintenanceTaskDBRow? {
        switch kind {
        case .overdue(let t), .vendorVisit(let t), .diyTask(let t): return t
        case .inboxReview: return nil
        }
    }
}

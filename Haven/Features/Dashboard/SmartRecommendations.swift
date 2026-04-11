import SwiftUI

struct Recommendation: Identifiable {
    let id: String // stable key for dismissal tracking
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let priority: Int // lower = higher priority
    let action: RecommendationAction
}

enum RecommendationAction {
    case navigate(tab: Int)
    case navigateToProperty(section: String) // "maintenance", "projects", "systems", "contacts"
    case addProperty
    case uploadDocument
    case addVendor
    case addFamilyMember
    case runGapAnalysis
    case setReminders
    case runScenario
    case openSettings
}

/// Evaluates the user's data and returns prioritized recommendations.
/// Priority order: Home management first, estate second.
struct RecommendationEngine {

    static func evaluate(
        hasProperty: Bool,
        propertyCount: Int,
        documentCount: Int,
        familyMemberCount: Int,
        vendorCount: Int,
        systemCount: Int,
        overdueCount: Int,
        hasRunGapAnalysis: Bool,
        hasRunScenario: Bool,
        expiringCount: Int,
        estateReadiness: Double,
        hasRemindersEnabled: Bool,
        overBudgetProjectCount: Int = 0,
        approachingDeadlineProjectCount: Int = 0,
        seasonalTasksIncomplete: Int = 0,
        seasonalTasksTotal: Int = 0,
        currentSeasonName: String = "",
        systemsNeedingServiceCount: Int = 0,
        hasIncompleteProperty: Bool = false,
        estateState: EstateStateRow? = nil,
        dismissedIds: Set<String>
    ) -> [Recommendation] {
        var recs: [Recommendation] = []

        // ============================================================
        // HOME MANAGEMENT (highest priority -- this is Haven's core)
        // ============================================================

        // Seasonal tasks -- most timely, changes with the season
        if seasonalTasksIncomplete > 0 && seasonalTasksTotal > 0 {
            let done = seasonalTasksTotal - seasonalTasksIncomplete
            recs.append(Recommendation(
                id: "seasonal_tasks",
                title: "\(currentSeasonName) tasks: \(done) of \(seasonalTasksTotal) groups done",
                subtitle: "Review seasonal maintenance before the season ends",
                icon: "leaf.fill",
                iconColor: HavenColors.navy700,
                priority: 8,
                action: .navigateToProperty(section: "maintenance")
            ))
        }

        // Active project alerts
        if overBudgetProjectCount > 0 {
            recs.append(Recommendation(
                id: "over_budget_projects",
                title: "\(overBudgetProjectCount) project\(overBudgetProjectCount == 1 ? " is" : "s are") over budget",
                subtitle: "Review your spending to stay on track",
                icon: "exclamationmark.triangle.fill",
                iconColor: HavenColors.critical,
                priority: 10,
                action: .navigateToProperty(section: "projects")
            ))
        }

        if approachingDeadlineProjectCount > 0 {
            recs.append(Recommendation(
                id: "approaching_deadline_projects",
                title: "\(approachingDeadlineProjectCount) project\(approachingDeadlineProjectCount == 1 ? "" : "s") approaching deadline",
                subtitle: "Check your timeline and remaining tasks",
                icon: "calendar.badge.exclamationmark",
                iconColor: HavenColors.warning,
                priority: 12,
                action: .navigateToProperty(section: "projects")
            ))
        }

        // Core home setup
        if hasProperty && systemCount == 0 {
            recs.append(Recommendation(
                id: "add_systems",
                title: "Add home systems",
                subtitle: "HVAC, plumbing, electrical -- Haven tracks maintenance for you",
                icon: "gearshape.2.fill",
                iconColor: HavenColors.navy700,
                priority: 15,
                action: .navigateToProperty(section: "overview")
            ))
        }

        // Systems needing service
        if systemsNeedingServiceCount > 0 {
            recs.append(Recommendation(
                id: "systems_need_service",
                title: "\(systemsNeedingServiceCount) system\(systemsNeedingServiceCount == 1 ? " hasn't" : "s haven't") been serviced recently",
                subtitle: "Schedule maintenance to avoid costly repairs",
                icon: "exclamationmark.triangle",
                iconColor: HavenColors.warning,
                priority: 18,
                action: .navigateToProperty(section: "maintenance")
            ))
        }

        if hasProperty && vendorCount == 0 {
            recs.append(Recommendation(
                id: "add_vendor",
                title: "Add your first vendor",
                subtitle: "Build your trusted contractor network",
                icon: "person.crop.rectangle.badge.plus",
                iconColor: HavenColors.navy700,
                priority: 20,
                action: .navigateToProperty(section: "contacts")
            ))
        }

        // Expiring documents (warranties, insurance, registrations)
        if expiringCount > 0 {
            recs.append(Recommendation(
                id: "expiring_docs",
                title: "\(expiringCount) document\(expiringCount == 1 ? "" : "s") expiring soon",
                subtitle: "Review and upload renewals before they expire",
                icon: "clock.badge.exclamationmark",
                iconColor: HavenColors.warning,
                priority: 25,
                action: .navigate(tab: 2)
            ))
        }

        // Incomplete property details
        if hasIncompleteProperty {
            recs.append(Recommendation(
                id: "incomplete_property",
                title: "Complete your property details",
                subtitle: "Add square footage, year built, and purchase price for better insights",
                icon: "house.fill",
                iconColor: HavenColors.navy700,
                priority: 28,
                action: .navigateToProperty(section: "overview")
            ))
        }

        // Family setup
        if familyMemberCount <= 1 {
            recs.append(Recommendation(
                id: "add_family",
                title: "Add family members",
                subtitle: "Track documents and coverage for each person",
                icon: "person.3.fill",
                iconColor: HavenColors.navy700,
                priority: 30,
                action: .addFamilyMember
            ))
        }

        // Reminders
        if propertyCount > 0 && documentCount >= 3 && !hasRemindersEnabled {
            recs.append(Recommendation(
                id: "enable_reminders",
                title: "Set up reminders",
                subtitle: "Get notified before documents expire and maintenance is due",
                icon: "bell.badge.fill",
                iconColor: HavenColors.warning,
                priority: 35,
                action: .openSettings
            ))
        }

        // ============================================================
        // ESTATE (lower priority -- shown after home management is handled)
        // ============================================================

        if documentCount > 0 && estateReadiness < 30 {
            recs.append(Recommendation(
                id: "low_readiness",
                title: "Improve your estate readiness",
                subtitle: "You're at \(Int(estateReadiness))% -- upload key documents to protect your family",
                icon: "shield.lefthalf.filled",
                iconColor: HavenColors.info,
                priority: 70,
                action: .navigate(tab: 2)
            ))
        }

        if documentCount >= 5 && !hasRunGapAnalysis {
            recs.append(Recommendation(
                id: "run_gap_analysis",
                title: "Run AI Gap Analysis",
                subtitle: "Let Alfred find blind spots in your estate plan",
                icon: "chart.bar.doc.horizontal.fill",
                iconColor: HavenColors.info,
                priority: 75,
                action: .runGapAnalysis
            ))
        }

        if documentCount >= 3 && !hasRunScenario {
            recs.append(Recommendation(
                id: "try_scenarios",
                title: "Try Scenario Planning",
                subtitle: "Ask \"What if?\" questions with your real data",
                icon: "sparkles",
                iconColor: HavenColors.navy700,
                priority: 80,
                action: .runScenario
            ))
        }

        if documentCount >= 10 && estateReadiness >= 50 && estateReadiness < 80 {
            recs.append(Recommendation(
                id: "push_readiness",
                title: "You're halfway there",
                subtitle: "Upload a few more key documents to reach 80% readiness",
                icon: "arrow.up.circle.fill",
                iconColor: HavenColors.success,
                priority: 85,
                action: .navigate(tab: 2)
            ))
        }

        // Phase 48: Estate staleness from estate_state
        if let estate = estateState {
            if estate.stalenessTier == "critical" {
                recs.append(Recommendation(
                    id: "estate_staleness_critical",
                    title: "Your estate plan needs urgent review",
                    subtitle: estate.stalenessReasons?.first ?? "Key documents are outdated or major life changes detected",
                    icon: "exclamationmark.shield.fill",
                    iconColor: HavenColors.critical,
                    priority: 5,
                    action: .navigate(tab: 2)
                ))
            } else if estate.stalenessTier == "amber" {
                recs.append(Recommendation(
                    id: "estate_staleness_amber",
                    title: "Time to review your estate plan",
                    subtitle: estate.stalenessReasons?.first ?? "Some documents are getting older",
                    icon: "exclamationmark.shield",
                    iconColor: HavenColors.warning,
                    priority: 65,
                    action: .navigate(tab: 2)
                ))
            }
        }

        // Filter out dismissed recommendations, sort by priority, take top 2
        return recs
            .filter { !dismissedIds.contains($0.id) }
            .sorted { $0.priority < $1.priority }
            .prefix(2)
            .map { $0 }
    }
}

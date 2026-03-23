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
        dismissedIds: Set<String>
    ) -> [Recommendation] {
        var recs: [Recommendation] = []

        // --- SECURITY & COVERAGE (highest priority) ---

        if documentCount > 0 && estateReadiness < 30 {
            recs.append(Recommendation(
                id: "low_readiness",
                title: "Improve your estate readiness",
                subtitle: "You're at \(Int(estateReadiness))% — upload key documents to protect your family",
                icon: "shield.lefthalf.filled",
                iconColor: HavenColors.critical,
                priority: 10,
                action: .navigate(tab: 2)
            ))
        }

        if expiringCount > 0 {
            recs.append(Recommendation(
                id: "expiring_docs",
                title: "\(expiringCount) document\(expiringCount == 1 ? "" : "s") expiring soon",
                subtitle: "Review and upload renewals before they expire",
                icon: "clock.badge.exclamationmark",
                iconColor: HavenColors.warning,
                priority: 15,
                action: .navigate(tab: 2)
            ))
        }

        // --- HOME MANAGEMENT ---

        if hasProperty && systemCount == 0 {
            recs.append(Recommendation(
                id: "add_systems",
                title: "Add home systems",
                subtitle: "HVAC, plumbing, electrical — Haven tracks maintenance for you",
                icon: "gearshape.2.fill",
                iconColor: HavenColors.navy700,
                priority: 20,
                action: .navigate(tab: 1)
            ))
        }

        if hasProperty && vendorCount == 0 {
            recs.append(Recommendation(
                id: "add_vendor",
                title: "Add your first vendor",
                subtitle: "Build your trusted contractor network",
                icon: "person.crop.rectangle.badge.plus",
                iconColor: HavenColors.navy700,
                priority: 30,
                action: .addVendor
            ))
        }

        if overdueCount > 0 {
            recs.append(Recommendation(
                id: "overdue_maintenance",
                title: "\(overdueCount) overdue maintenance task\(overdueCount == 1 ? "" : "s")",
                subtitle: "Don't let small issues become expensive repairs",
                icon: "wrench.and.screwdriver.fill",
                iconColor: HavenColors.critical,
                priority: 12,
                action: .navigate(tab: 1)
            ))
        }

        // --- FAMILY & ESTATE ---

        if familyMemberCount <= 1 {
            recs.append(Recommendation(
                id: "add_family",
                title: "Add family members",
                subtitle: "Track documents and coverage for each person",
                icon: "person.3.fill",
                iconColor: HavenColors.navy700,
                priority: 25,
                action: .addFamilyMember
            ))
        }

        if documentCount >= 5 && !hasRunGapAnalysis {
            recs.append(Recommendation(
                id: "run_gap_analysis",
                title: "Run AI Gap Analysis",
                subtitle: "Let Alfred find blind spots in your estate plan",
                icon: "chart.bar.doc.horizontal.fill",
                iconColor: HavenColors.info,
                priority: 35,
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
                priority: 40,
                action: .runScenario
            ))
        }

        // --- OPTIMIZATION ---

        if propertyCount > 0 && documentCount >= 3 && !hasRemindersEnabled {
            recs.append(Recommendation(
                id: "enable_reminders",
                title: "Set up reminders",
                subtitle: "Get notified before documents expire and maintenance is due",
                icon: "bell.badge.fill",
                iconColor: HavenColors.warning,
                priority: 45,
                action: .openSettings
            ))
        }

        if documentCount >= 10 && estateReadiness >= 50 && estateReadiness < 80 {
            recs.append(Recommendation(
                id: "push_readiness",
                title: "You're halfway there",
                subtitle: "Upload a few more key documents to reach 80% readiness",
                icon: "arrow.up.circle.fill",
                iconColor: HavenColors.success,
                priority: 50,
                action: .navigate(tab: 2)
            ))
        }

        // Filter out dismissed recommendations, sort by priority, take top 2
        return recs
            .filter { !dismissedIds.contains($0.id) }
            .sorted { $0.priority < $1.priority }
            .prefix(2)
            .map { $0 }
    }
}

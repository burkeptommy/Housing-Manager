import Foundation
import UIKit
import UserNotifications

/// Singleton that runs project cost research in the background,
/// allowing the user to navigate away while Claude processes.
/// Follows the same pattern as ScenarioRunnerService.
@MainActor
final class ProjectResearchService: ObservableObject {
    static let shared = ProjectResearchService()

    @Published var isResearching = false
    @Published var pendingProjectName: String?
    @Published var completedProjectId: UUID?
    @Published var completedError: String?
    @Published var hasUnviewedResult = false

    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    // MARK: - Run Research (background)

    func research(project: PropertyProjectRow, location: String?) {
        guard !isResearching else { return }

        isResearching = true
        pendingProjectName = project.name
        completedProjectId = nil
        completedError = nil

        beginBackgroundTask()

        Task {
            await executeResearch(project: project, location: location)
        }
    }

    // MARK: - Core Execution

    private func executeResearch(project: PropertyProjectRow, location: String?) async {
        do {
            let data = try await HavenSupabase.researchProject(
                projectName: project.name,
                category: project.category,
                description: project.description,
                propertyLocation: location,
                projectId: project.id.uuidString
            )

            // Debug log
            if let rawString = String(data: data, encoding: .utf8) {
                print("[ProjectResearch] Raw response: \(rawString.prefix(1000))")
            }

            // Decode the response
            struct ResearchResponse: Decodable {
                let research: ProjectAIResearch?
            }

            let response: ResearchResponse
            do {
                response = try JSONDecoder().decode(ResearchResponse.self, from: data)
            } catch {
                print("[ProjectResearch] Decoding error: \(error)")
                completedError = "Research completed but couldn't be read. The data is saved — try refreshing."
                sendErrorNotification()
                isResearching = false
                pendingProjectName = nil
                endBackgroundTask()
                return
            }

            guard let research = response.research else {
                completedError = "No research data in response."
                sendErrorNotification()
                isResearching = false
                pendingProjectName = nil
                endBackgroundTask()
                return
            }

            // Insert AI-suggested line items
            let items = (research.typicalItems ?? []).enumerated().map { index, item in
                ProjectLineItemInsert(
                    projectId: project.id,
                    householdId: project.householdId,
                    name: item.name,
                    category: item.category ?? "materials",
                    quantity: item.resolvedQuantity,
                    unit: item.unit ?? "each",
                    estimatedUnitPrice: item.resolvedPrice,
                    suggestedStore: item.resolvedStore,
                    isAiSuggested: true,
                    notes: item.notes,
                    sortOrder: index
                )
            }
            if !items.isEmpty {
                try await DatabaseService.shared.createLineItems(items)
            }

            completedProjectId = project.id
            hasUnviewedResult = true
            sendCompletionNotification(projectName: project.name)
            Analytics.track(.enrichmentCardCompleted, ["type": "project_research", "project": project.name])

        } catch {
            print("[ProjectResearch] Failed: \(error.localizedDescription)")
            completedError = "Research failed: \(error.localizedDescription)"
            sendErrorNotification()
        }

        isResearching = false
        pendingProjectName = nil
        endBackgroundTask()
    }

    // MARK: - View Result

    func clearResult() {
        completedProjectId = nil
        completedError = nil
        hasUnviewedResult = false
    }

    // MARK: - Background Task Management

    private func beginBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "ProjectResearch") { [weak self] in
            Task { @MainActor in
                self?.isResearching = false
                self?.completedError = "Research was interrupted. The project was saved — you can re-research later."
                self?.endBackgroundTask()
            }
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    // MARK: - Notifications

    private func sendCompletionNotification(projectName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Research Complete"
        content.body = "Cost estimates are ready for \(projectName)"
        content.sound = .default
        content.userInfo = ["type": "project_research_complete"]

        let request = UNNotificationRequest(
            identifier: "project-research-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func sendErrorNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Research Failed"
        content.body = "Couldn't complete cost research. Tap to try again."
        content.sound = .default
        content.userInfo = ["type": "project_research_error"]

        let request = UNNotificationRequest(
            identifier: "project-research-error-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

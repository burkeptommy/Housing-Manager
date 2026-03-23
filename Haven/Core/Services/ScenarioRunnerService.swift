import Foundation
import UIKit
import UserNotifications

/// Singleton that runs scenario simulations in the background,
/// allowing the user to navigate away while the AI processes.
@MainActor
final class ScenarioRunnerService: ObservableObject {
    static let shared = ScenarioRunnerService()

    /// The currently running scenario (nil if idle)
    @Published var pendingQuery: String?
    @Published var pendingScenarioId: String?
    @Published var isRunning = false

    /// The most recently completed result (not yet viewed)
    @Published var completedResult: ScenarioResult?
    @Published var completedError: String?

    /// Badge count for unviewed results
    @Published var hasUnviewedResult = false

    private var householdId: UUID?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    func setHouseholdId(_ id: UUID) {
        householdId = id
    }

    // MARK: - Run Custom Scenario (background)

    func runCustomScenario(query: String) {
        guard let householdId else {
            completedError = "No household found. Please complete onboarding first."
            return
        }
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isRunning else { return } // Don't double-run

        pendingQuery = query
        pendingScenarioId = nil
        isRunning = true
        completedResult = nil
        completedError = nil

        // Request background execution time from iOS
        beginBackgroundTask()

        Task {
            await executeScenario(
                scenarioId: nil,
                customQuery: query,
                householdId: householdId
            )
        }
    }

    // MARK: - Run Preset Scenario (background)

    func runScenario(id: String, params: [String: String]? = nil) {
        guard let householdId else {
            completedError = "No household found. Please complete onboarding first."
            return
        }
        guard !isRunning else { return }

        pendingScenarioId = id
        pendingQuery = nil
        isRunning = true
        completedResult = nil
        completedError = nil

        beginBackgroundTask()

        Task {
            await executeScenario(
                scenarioId: id,
                customQuery: nil,
                householdId: householdId,
                params: params
            )
        }
    }

    // MARK: - Core Execution

    private func executeScenario(
        scenarioId: String?,
        customQuery: String?,
        householdId: UUID,
        params: [String: String]? = nil
    ) async {
        do {
            let data = try await HavenSupabase.simulateScenario(
                scenarioId: scenarioId,
                customQuery: customQuery,
                householdId: householdId.uuidString,
                params: params
            )

            if let parsed = parseResultData(data) {
                completedResult = parsed
                hasUnviewedResult = true

                // Save to history
                await saveScenarioHistory(
                    scenarioId: scenarioId,
                    query: customQuery,
                    result: data,
                    householdId: householdId
                )

                // Send local notification
                sendCompletionNotification(title: parsed.title)
            } else {
                let raw = String(data: data, encoding: .utf8) ?? "(empty)"
                print("[ScenarioRunner] Parse failed. Raw: \(raw.prefix(500))")
                completedError = "We received a response but couldn't display it. Please try again."
                sendErrorNotification()
            }
        } catch {
            let nsErr = error as NSError
            print("[ScenarioRunner] Failed: domain=\(nsErr.domain) code=\(nsErr.code) desc=\(error.localizedDescription)")
            completedError = friendlyError(error)
            sendErrorNotification()
        }

        isRunning = false
        pendingQuery = nil
        pendingScenarioId = nil
        endBackgroundTask()
    }

    // MARK: - Background Task Management

    private func beginBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "ScenarioSimulation") { [weak self] in
            // iOS is about to kill our time — clean up
            Task { @MainActor in
                self?.isRunning = false
                self?.completedError = "The analysis was interrupted because the app was in the background too long. Please try again."
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

    private func sendCompletionNotification(title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Scenario Complete"
        content.body = title
        content.sound = .default
        content.userInfo = ["type": "scenario_complete"]

        let request = UNNotificationRequest(
            identifier: "scenario-complete-\(UUID().uuidString)",
            content: content,
            trigger: nil // Fire immediately
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func sendErrorNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Scenario Planning"
        content.body = "Your scenario couldn't be completed. Tap to try again."
        content.sound = .default
        content.userInfo = ["type": "scenario_error"]

        let request = UNNotificationRequest(
            identifier: "scenario-error-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - View Result (clears unviewed flag)

    func viewResult() -> ScenarioResult? {
        hasUnviewedResult = false
        return completedResult
    }

    func clearResult() {
        completedResult = nil
        completedError = nil
        hasUnviewedResult = false
    }

    // MARK: - Parse / Error Helpers

    private func parseResultData(_ data: Data) -> ScenarioResult? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if json["error"] != nil && json["title"] == nil {
                return nil
            }
            return ScenarioResult(from: json)
        }
        if let responseStr = String(data: data, encoding: .utf8),
           let jsonStart = responseStr.firstIndex(of: "{"),
           let jsonEnd = responseStr.lastIndex(of: "}") {
            let jsonStr = String(responseStr[jsonStart...jsonEnd])
            if let jsonData = jsonStr.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                if json["error"] != nil && json["title"] == nil { return nil }
                return ScenarioResult(from: json)
            }
        }
        return nil
    }

    private func friendlyError(_ error: Error) -> String {
        let desc = error.localizedDescription.lowercased()
        let nsError = error as NSError

        if desc.contains("timed out") || desc.contains("timeout") || nsError.code == NSURLErrorTimedOut {
            return "The analysis took too long. Please try again."
        }
        if desc.contains("network") || desc.contains("offline") || desc.contains("internet")
            || nsError.code == NSURLErrorNotConnectedToInternet {
            return "No internet connection. Please check your network and try again."
        }
        if nsError.domain == "EdgeFunction" {
            if desc.contains("rate limit") {
                return "Our AI service is temporarily busy. Please wait 30 seconds and try again."
            }
            if nsError.code == 502 {
                return "Our AI service encountered an error. Please try again in a moment."
            }
            if nsError.code == 500 {
                return "Our server encountered an error. Please try again in a moment."
            }
        }
        return "Something went wrong. Please try again, or try a different question."
    }

    private func saveScenarioHistory(scenarioId: String?, query: String?, result: Data, householdId: UUID) async {
        do {
            var record: [String: String] = ["household_id": householdId.uuidString]
            if let scenarioId { record["scenario_id"] = scenarioId }
            if let query { record["custom_query"] = query }
            if let jsonStr = String(data: result, encoding: .utf8) {
                record["result_json"] = jsonStr
            }
            try await HavenSupabase.from("scenario_history")
                .insert(record)
                .execute()
        } catch {
            print("[ScenarioRunner] Failed to save history: \(error)")
        }
    }
}

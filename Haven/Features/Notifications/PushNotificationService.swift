import Foundation
import UIKit

final class PushNotificationService {
    static let shared = PushNotificationService()

    private let db = DatabaseService.shared
    private var currentToken: String?
    private var tokenStoredSuccessfully = false

    private init() {}

    // MARK: - Token Management

    func registerForPushNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func handleDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        currentToken = token
        tokenStoredSuccessfully = false
        print("[Push] Device token received: \(token.prefix(16))...")

        Task { await storeTokenWithRetry() }
    }

    /// Called when user signs in or auth state changes — ensures token is stored
    func ensureTokenStored() {
        guard currentToken != nil, !tokenStoredSuccessfully else { return }
        Task { await storeTokenWithRetry() }
    }

    private func storeTokenWithRetry() async {
        guard let token = currentToken else { return }

        // Try up to 3 times with increasing delay (auth session may not be ready yet)
        for attempt in 1...3 {
            do {
                let session = try await HavenSupabase.auth.session
                print("[Push] Storing token for auth user: \(session.user.id), token prefix: \(token.prefix(16))...")
                try await db.upsertDeviceToken(userId: session.user.id, token: token)
                tokenStoredSuccessfully = true
                print("[Push] Device token stored successfully (attempt \(attempt))")
                return
            } catch {
                print("[Push] Failed to store device token (attempt \(attempt)): \(error)")
                if attempt < 3 {
                    try? await Task.sleep(for: .seconds(Double(attempt) * 2))
                }
            }
        }
    }

    func handleRegistrationError(_ error: Error) {
        print("[Push] Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func clearToken() {
        guard let token = currentToken else { return }
        Task {
            try? await db.deleteDeviceToken(token: token)
        }
        currentToken = nil
        tokenStoredSuccessfully = false
    }

    // MARK: - Send Notifications

    func sendTaskAssignmentNotification(
        taskTitle: String,
        assigneeName: String,
        recipientUserIds: [UUID],
        taskId: UUID
    ) async {
        print("[Push] Sending task assignment to \(recipientUserIds.count) recipient(s): \(recipientUserIds.map(\.uuidString))")
        do {
            try await HavenSupabase.sendPushNotification(
                recipientUserIds: recipientUserIds.map(\.uuidString),
                title: "Task Assigned",
                body: "\(assigneeName) has been assigned: \(taskTitle)",
                data: ["type": "task_assignment", "task_id": taskId.uuidString]
            )
            print("[Push] Task assignment notification sent successfully")
        } catch {
            print("[Push] Failed to send task assignment notification: \(error)")
        }
    }
}

import Foundation
import UIKit

final class PushNotificationService {
    static let shared = PushNotificationService()

    private let db = DatabaseService.shared
    private var currentToken: String?

    private init() {}

    // MARK: - Token Management

    func registerForPushNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func handleDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        currentToken = token
        print("[Push] Device token: \(token)")

        Task {
            do {
                let session = try await HavenSupabase.auth.session
                try await db.upsertDeviceToken(userId: session.user.id, token: token)
                print("[Push] Device token stored successfully")
            } catch {
                print("[Push] Failed to store device token: \(error)")
            }
        }
    }

    func handleRegistrationError(_ error: Error) {
        print("[Push] Failed to register: \(error.localizedDescription)")
    }

    func clearToken() {
        guard let token = currentToken else { return }
        Task {
            try? await db.deleteDeviceToken(token: token)
        }
        currentToken = nil
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

import SwiftUI

@MainActor
final class SecurityDashboardViewModel: ObservableObject {
    @Published var accessLogs: [AccessLogRow] = []
    @Published var documentCount = 0
    @Published var vaultLockedDocuments: [DocumentRow] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedFilter: AccessLogFilter = .all
    @Published var showAllLogs = false
    @Published var householdUsers: [UserRow] = []
    @Published var currentUserId: UUID?

    private let db = DatabaseService.shared

    enum AccessLogFilter: String, CaseIterable {
        case all = "All"
        case documents = "Documents"
        case ai = "AI Activity"
        case scans = "Scans"

        var actions: [String]? {
            switch self {
            case .all: return nil
            case .documents: return ["document_uploaded", "document_viewed", "document_downloaded", "document_deleted"]
            case .ai: return ["document_ai_analyzed", "document_ai_reanalyzed", "ai_chat_query", "ai_gap_analysis"]
            case .scans: return ["ai_proactive_scan"]
            }
        }
    }

    func load() async {
        isLoading = true
        do {
            async let logsTask = db.fetchAccessLogs(limit: 200)
            async let countTask = db.fetchDocumentCount()
            async let vaultTask = db.fetchVaultLockedDocuments()
            async let usersTask = db.fetchHouseholdUsers()
            async let currentUserTask = db.fetchCurrentUser()

            let (logs, count, vault, users, currentUser) = try await (logsTask, countTask, vaultTask, usersTask, currentUserTask)
            accessLogs = logs
            documentCount = count
            vaultLockedDocuments = vault
            householdUsers = users
            currentUserId = currentUser.id
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    var filteredLogs: [AccessLogRow] {
        guard let actions = selectedFilter.actions else { return accessLogs }
        return accessLogs.filter { actions.contains($0.action) }
    }

    /// Returns first name for a user ID — always uses name, never "You", so both household members see clear attribution
    func displayName(for userId: UUID?) -> String {
        guard let userId else { return "System" }
        if let user = householdUsers.first(where: { $0.id == userId }) {
            return user.fullName?.components(separatedBy: " ").first ?? user.fullName ?? "Someone"
        }
        return "Someone"
    }
}

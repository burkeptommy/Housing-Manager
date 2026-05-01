import Foundation
import SwiftUI

/// Phase 80 — Chez sub-tab list view model. Owns the active + past
/// request list, refreshes on `.chezRequestChanged`, and exposes derived
/// "active" / "past" arrays so the view can render two sections.

@MainActor
final class ChezRequestsViewModel: ObservableObject {
    @Published var requests: [ChezRequestRow] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    /// Open / waiting-on-customer requests, newest activity first.
    var activeRequests: [ChezRequestRow] {
        requests
            .filter { $0.typedStatus != .resolved }
            .sorted(by: { $0.lastMessageAt > $1.lastMessageAt })
    }

    /// Resolved requests, most-recently-resolved first.
    var pastRequests: [ChezRequestRow] {
        requests
            .filter { $0.typedStatus == .resolved }
            .sorted(by: {
                ($0.resolvedAt ?? $0.lastMessageAt) > ($1.resolvedAt ?? $1.lastMessageAt)
            })
    }

    /// Unread count from Tom (drives the badge dot on the Chez sub-tab).
    var unreadCount: Int {
        requests.filter { $0.unreadForUser && $0.typedStatus != .resolved }.count
    }

    func load() async {
        if requests.isEmpty {
            isLoading = true
        }
        defer { isLoading = false }
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                requests = []
                return
            }
            requests = try await DatabaseService.shared.fetchChezRequests(householdId: householdId)
        } catch {
            errorMessage = error.localizedDescription
            print("[ChezRequestsVM] load failed: \(error)")
        }
    }
}

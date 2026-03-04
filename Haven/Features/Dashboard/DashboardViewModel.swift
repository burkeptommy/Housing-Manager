import SwiftUI

struct ExpirationItem: Identifiable {
    let id = UUID()
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
    @Published var upcomingExpirations: [ExpirationItem] = []
    @Published var overdueMaintenanceTasks: [MaintenanceTaskDBRow] = []
    @Published var recentDocuments: [DocumentRow] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: String?

    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }
        await fetchAll()
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
        _ = await (scoresTask, expirationsTask, maintenanceTask, recentTask)
    }

    private func loadCompletionScores() async {
        do {
            let scores = try await DatabaseService.shared.fetchCompletionScores()
            categoryScores = scores.map { row in
                CategoryScore(
                    category: row.category,
                    percentage: row.completionPercentage ?? 0,
                    actual: row.actualCount ?? 0,
                    expected: row.expectedCount ?? 0
                )
            }
            if !categoryScores.isEmpty {
                overallReadiness = categoryScores.reduce(0) { $0 + $1.percentage } / Double(categoryScores.count)
            }
        } catch {
            // Scores not yet calculated — show 0
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
        } catch {}
    }

    private func loadRecentDocuments() async {
        do {
            let docs = try await DatabaseService.shared.fetchDocuments()
            recentDocuments = Array(docs.prefix(5))
        } catch {}
    }
}

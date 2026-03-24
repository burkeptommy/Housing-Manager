import Foundation

@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published var projects: [PropertyProjectRow] = []
    @Published var lineItems: [ProjectLineItemRow] = []
    @Published var isLoading = false
    @Published var isResearching = false
    @Published var error: String?

    private let db = DatabaseService.shared

    // Grouped projects
    var activeProjects: [PropertyProjectRow] {
        projects.filter { $0.status == "planning" || $0.status == "in_progress" }
    }
    var completedProjects: [PropertyProjectRow] {
        projects.filter { $0.status == "completed" }
    }
    var onHoldProjects: [PropertyProjectRow] {
        projects.filter { $0.status == "on_hold" }
    }

    func loadProjects(propertyId: UUID) async {
        isLoading = true
        error = nil
        do {
            projects = try await db.fetchProjects(propertyId: propertyId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadLineItems(projectId: UUID) async {
        do {
            lineItems = try await db.fetchLineItems(projectId: projectId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createProject(_ insert: PropertyProjectInsert) async throws -> PropertyProjectRow {
        let project = try await db.createProject(insert)
        projects.insert(project, at: 0)
        return project
    }

    func updateProject(id: UUID, _ updates: PropertyProjectUpdate) async throws {
        let updated = try await db.updateProject(id: id, updates)
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx] = updated
        }
    }

    func deleteProject(id: UUID) async throws {
        try await db.deleteProject(id: id)
        projects.removeAll { $0.id == id }
    }

    func researchProject(_ project: PropertyProjectRow, location: String?) async throws -> ProjectAIResearch {
        isResearching = true
        defer { isResearching = false }

        let data = try await HavenSupabase.researchProject(
            projectName: project.name,
            category: project.category,
            description: project.description,
            propertyLocation: location,
            projectId: project.id.uuidString
        )

        // Debug: log raw response
        if let rawString = String(data: data, encoding: .utf8) {
            print("[ResearchProject] Raw response: \(rawString.prefix(1000))")
        }

        struct ResearchResponse: Decodable {
            let research: ProjectAIResearch?
        }

        let response: ResearchResponse
        do {
            response = try JSONDecoder().decode(ResearchResponse.self, from: data)
        } catch let decodingError {
            print("[ResearchProject] Decoding error: \(decodingError)")
            throw decodingError
        }
        guard let research = response.research else {
            throw NSError(domain: "Haven", code: 0, userInfo: [NSLocalizedDescriptionKey: "No research data in response"])
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
            try await db.createLineItems(items)
        }

        // Reload the project to get updated AI fields
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            let refreshed = try await db.fetchProjects(propertyId: project.propertyId)
            if let updated = refreshed.first(where: { $0.id == project.id }) {
                projects[idx] = updated
            }
        }

        // Reload line items
        lineItems = try await db.fetchLineItems(projectId: project.id)

        return research
    }

    func recalculateActualSpend(projectId: UUID) async throws {
        let items = try await db.fetchLineItems(projectId: projectId)
        let total = items
            .filter { $0.isPurchased && !($0.isOwned ?? false) }
            .reduce(0.0) { sum, item in
                sum + (item.actualUnitPrice ?? item.estimatedUnitPrice ?? 0) * (item.quantity ?? 1)
            }
        try await db.updateProject(id: projectId, PropertyProjectUpdate(actualSpend: total))
        // Update local state
        if let idx = projects.firstIndex(where: { $0.id == projectId }) {
            let refreshed = try await db.fetchProjects(propertyId: projects[idx].propertyId)
            if let updated = refreshed.first(where: { $0.id == projectId }) {
                projects[idx] = updated
            }
        }
    }

    func addLineItem(_ insert: ProjectLineItemInsert) async throws {
        let item = try await db.createLineItem(insert)
        lineItems.append(item)
    }

    func updateLineItem(id: UUID, _ updates: ProjectLineItemUpdate) async throws {
        let updated = try await db.updateLineItem(id: id, updates)
        if let idx = lineItems.firstIndex(where: { $0.id == id }) {
            lineItems[idx] = updated
        }
    }

    func deleteLineItem(id: UUID) async throws {
        try await db.deleteLineItem(id: id)
        lineItems.removeAll { $0.id == id }
    }
}

import Foundation

@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published var projects: [PropertyProjectRow] = []
    @Published var lineItems: [ProjectLineItemRow] = []
    @Published var toolkit: [HouseholdToolkitRow] = []
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

    // MARK: - Toolkit

    func loadToolkit(householdId: UUID) async {
        toolkit = (try? await db.fetchToolkit(householdId: householdId)) ?? []
    }

    func addToolToToolkit(name: String, householdId: UUID, projectId: UUID?) async {
        let normalized = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // Skip if already in toolkit
        guard !toolkit.contains(where: { $0.normalizedName == normalized }) else { return }
        let insert = HouseholdToolkitInsert(
            householdId: householdId,
            toolName: name,
            normalizedName: normalized,
            addedFromProjectId: projectId
        )
        if let added = try? await db.addToToolkit(insert) {
            toolkit.append(added)
        }
    }

    func removeToolFromToolkit(id: UUID) async {
        try? await db.removeFromToolkit(id: id)
        toolkit.removeAll { $0.id == id }
    }

    /// Check toolkit and auto-mark matching line items as owned
    func autoMarkToolkitItems(projectId: UUID, householdId: UUID) async {
        let toolkitNames = Set(toolkit.map { $0.normalizedName })
        guard !toolkitNames.isEmpty else { return }

        let items = try? await db.fetchLineItems(projectId: projectId)
        for item in (items ?? []) {
            let isToolCategory = ["tools", "hardware", "safety"].contains(item.category?.lowercased() ?? "")
            guard isToolCategory, !(item.isOwned ?? false) else { continue }
            let normalized = item.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            // Fuzzy match: toolkit name contained in item name or vice versa
            let matches = toolkitNames.contains(where: { normalized.contains($0) || $0.contains(normalized) })
            if matches {
                _ = try? await db.updateLineItem(id: item.id, ProjectLineItemUpdate(isOwned: true))
            }
        }
    }

    // MARK: - Project CRUD

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

        // Pass toolkit to exclude owned tools from suggestions
        let toolkitNames = toolkit.isEmpty ? nil : toolkit.map { $0.toolName }

        let data = try await HavenSupabase.researchProject(
            projectName: project.name,
            category: project.category,
            description: project.description,
            propertyLocation: location,
            projectId: project.id.uuidString,
            userToolkit: toolkitNames
        )

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

        // Insert AI-suggested line items with necessity/multiProjectUseful
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
                necessity: item.necessity ?? "required",
                multiProjectUseful: item.multiProjectUseful ?? false,
                notes: item.notes,
                sortOrder: index
            )
        }
        if !items.isEmpty {
            try await db.createLineItems(items)
        }

        // Auto-mark toolkit matches as owned
        await autoMarkToolkitItems(projectId: project.id, householdId: project.householdId)

        // Recalculate totals
        try? await recalculateProjectTotals(projectId: project.id)

        // Reload
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            let refreshed = try await db.fetchProjects(propertyId: project.propertyId)
            if let updated = refreshed.first(where: { $0.id == project.id }) {
                projects[idx] = updated
            }
        }
        lineItems = try await db.fetchLineItems(projectId: project.id)

        return research
    }

    // MARK: - Budget Calculations

    /// Recalculate both actual spend and estimated total for a project.
    func recalculateProjectTotals(projectId: UUID) async throws {
        let items = try await db.fetchLineItems(projectId: projectId)

        let actualSpend = items
            .filter { $0.isPurchased && !($0.isOwned ?? false) }
            .reduce(0.0) { $0 + ($1.actualUnitPrice ?? $1.estimatedUnitPrice ?? 0) * ($1.quantity ?? 1) }

        let estimatedTotal = items
            .filter { !($0.isOwned ?? false) }
            .reduce(0.0) { $0 + ($1.estimatedUnitPrice ?? 0) * ($1.quantity ?? 1) }

        _ = try await db.updateProject(id: projectId, PropertyProjectUpdate(
            actualSpend: actualSpend,
            estimatedTotal: estimatedTotal
        ))

        // Update local state
        if let idx = projects.firstIndex(where: { $0.id == projectId }) {
            let refreshed = try await db.fetchProjects(propertyId: projects[idx].propertyId)
            if let updated = refreshed.first(where: { $0.id == projectId }) {
                projects[idx] = updated
            }
        }
    }

    /// Legacy alias — calls recalculateProjectTotals
    func recalculateActualSpend(projectId: UUID) async throws {
        try await recalculateProjectTotals(projectId: projectId)
    }

    // MARK: - Line Item CRUD

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

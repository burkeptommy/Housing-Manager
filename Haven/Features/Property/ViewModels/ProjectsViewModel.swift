import Foundation

@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published var projects: [PropertyProjectRow] = []
    @Published var quotes: [ProjectQuoteRow] = []
    @Published var projectFiles: [ProjectFileRow] = []
    @Published var feasibility: ProjectFeasibility?
    @Published var isLoading = false
    @Published var isLoadingFeasibility = false
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

    // MARK: - Project Quotes

    func loadQuotes(projectId: UUID) async {
        quotes = (try? await db.fetchProjectQuotes(projectId: projectId)) ?? []
    }

    func addQuote(_ insert: ProjectQuoteInsert) async throws -> ProjectQuoteRow {
        let quote = try await db.createProjectQuote(insert)
        quotes.insert(quote, at: 0)
        return quote
    }

    func deleteQuote(id: UUID) async throws {
        try await db.deleteProjectQuote(id: id)
        quotes.removeAll { $0.id == id }
    }

    /// Find an existing project that matches a quote's detected category.
    func findMatchingProject(category: String, propertyId: UUID) -> PropertyProjectRow? {
        let normalized = category.lowercased()
        return projects.first { project in
            project.propertyId == propertyId &&
            project.status != "completed" &&
            (project.category.lowercased() == normalized ||
             project.category.lowercased().contains(normalized) ||
             normalized.contains(project.category.lowercased()) ||
             project.name.lowercased().contains(normalized) ||
             normalized.contains(project.name.lowercased()))
        }
    }

    /// Find or create a contractor from quote vendor info, avoiding duplicates.
    func findOrCreateContractor(vendor: QuoteVendor, householdId: UUID) async -> UUID? {
        guard let vendorName = vendor.name, !vendorName.isEmpty else { return nil }

        if let existing = try? await db.findContractorByName(householdId: householdId, name: vendorName) {
            return existing.id
        }

        let insert = ContractorInsert(
            householdId: householdId,
            companyName: vendorName,
            phone: vendor.phone ?? "Not provided",
            contactName: nil,
            email: vendor.email,
            address: vendor.address,
            licenseNumber: vendor.license
        )
        if let contractor = try? await db.createContractor(insert) {
            return contractor.id
        }
        return nil
    }

    // MARK: - Project CRUD

    func createProject(_ insert: PropertyProjectInsert) async throws -> PropertyProjectRow {
        let project = try await db.createProject(insert)
        projects.insert(project, at: 0)
        NotificationCenter.default.post(name: .projectChanged, object: nil,
            userInfo: ["action": "created", "id": project.id.uuidString])
        return project
    }

    func updateProject(id: UUID, _ updates: PropertyProjectUpdate) async throws {
        let updated = try await db.updateProject(id: id, updates)
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx] = updated
        }
        NotificationCenter.default.post(name: .projectChanged, object: nil,
            userInfo: ["action": "updated", "id": id.uuidString])
    }

    func deleteProject(id: UUID) async throws {
        let snapshot = projects
        projects.removeAll { $0.id == id }
        do {
            try await db.deleteProject(id: id)
            NotificationCenter.default.post(name: .projectChanged, object: nil,
                userInfo: ["action": "deleted", "id": id.uuidString])
        } catch {
            projects = snapshot
            throw error
        }
    }

    // MARK: - Project Contacts

    @Published var projectContacts: [ProjectContactRow] = []

    func loadProjectContacts(projectId: UUID) async {
        projectContacts = (try? await db.fetchProjectContacts(projectId: projectId)) ?? []
    }

    func removeProjectContact(id: UUID) async {
        try? await db.deleteProjectContact(id: id)
        projectContacts.removeAll { $0.id == id }
    }

    // MARK: - Sub-Projects (Insurance Claims)

    @Published var subProjects: [PropertyProjectRow] = []

    func loadSubProjects(parentId: UUID) async {
        // Filter from already-loaded projects, or fetch all if needed
        subProjects = projects.filter { $0.parentProjectId == parentId }
    }

    /// Available projects that can be linked to a claim (not already linked, not the claim itself)
    func linkableProjects(excludingClaimId claimId: UUID) -> [PropertyProjectRow] {
        projects.filter { $0.id != claimId && $0.parentProjectId == nil && !$0.isInsuranceClaim }
    }

    func linkProjectToClaim(projectId: UUID, claimId: UUID) async {
        // Optimistic: move to sub-projects immediately
        if let project = projects.first(where: { $0.id == projectId }) {
            subProjects.append(project)
        }
        Haptics.success()

        do {
            var updates = PropertyProjectUpdate()
            updates.parentProjectId = claimId
            _ = try await db.updateProject(id: projectId, updates)
            // Reload to get fresh data with parentProjectId set
            if let idx = projects.firstIndex(where: { $0.id == projectId }) {
                projects[idx] = try await db.fetchProject(id: projectId)
            }
            NotificationCenter.default.post(name: .projectChanged, object: nil,
                userInfo: ["action": "updated", "id": projectId.uuidString])
        } catch {
            subProjects.removeAll { $0.id == projectId }
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    func unlinkProjectFromClaim(projectId: UUID) async {
        let snapshot = subProjects
        subProjects.removeAll { $0.id == projectId }
        Haptics.success()

        do {
            try await db.clearParentProject(id: projectId)
            if let idx = projects.firstIndex(where: { $0.id == projectId }) {
                projects[idx] = try await db.fetchProject(id: projectId)
            }
            NotificationCenter.default.post(name: .projectChanged, object: nil,
                userInfo: ["action": "updated", "id": projectId.uuidString])
        } catch {
            subProjects = snapshot
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    /// Total claim amount from all sub-project quotes
    /// Total claim = linked project costs + personal property amount
    func claimTotal(for claim: PropertyProjectRow) -> Double {
        let projectCosts = subProjects.compactMap { project in
            project.aiEstimatedProCost ?? project.estimatedBudget ?? project.actualSpend
        }.reduce(0, +)
        return projectCosts + (claim.personalPropertyAmount ?? 0)
    }

    /// Legacy computed property for backward compatibility
    var claimTotal: Double {
        subProjects.compactMap { project in
            project.aiEstimatedProCost ?? project.estimatedBudget ?? project.actualSpend
        }.reduce(0, +)
    }

    // MARK: - Project Files (DIY)

    func loadProjectFiles(projectId: UUID) async {
        projectFiles = (try? await db.fetchProjectFiles(projectId: projectId)) ?? []
    }

    func uploadProjectFile(projectId: UUID, householdId: UUID, data: Data, filename: String, contentType: String) async throws {
        let storagePath = "\(householdId.uuidString)/projects/\(projectId.uuidString)/\(UUID().uuidString)_\(filename)"
        _ = try await db.uploadDocumentFile(householdId: householdId, fileName: storagePath, data: data, contentType: contentType)

        let insert = ProjectFileInsert(
            projectId: projectId,
            householdId: householdId,
            filePath: storagePath,
            filename: filename,
            contentType: contentType,
            fileSize: data.count
        )
        let file = try await db.createProjectFile(insert)
        projectFiles.insert(file, at: 0)
    }

    func deleteProjectFile(id: UUID) async throws {
        try await db.deleteProjectFile(id: id)
        projectFiles.removeAll { $0.id == id }
    }

    // MARK: - Feasibility / ROI

    func loadFeasibility(projectName: String, category: String, description: String?, location: String?) async {
        isLoadingFeasibility = true
        defer { isLoadingFeasibility = false }

        do {
            // When category is "Other", send the project name + description
            // so the AI has real context for the ROI estimate
            let projectType: String
            if category == "Other" || category.lowercased() == "other" {
                let parts = [projectName, description].compactMap { $0 }.filter { !$0.isEmpty }
                projectType = parts.joined(separator: " — ")
            } else {
                projectType = "\(category): \(projectName)"
            }

            let data = try await HavenSupabase.projectFeasibility(
                projectType: projectType,
                propertyLocation: location
            )

            struct FeasibilityResponse: Decodable {
                let feasibility: ProjectFeasibility?
            }

            let response = try JSONDecoder().decode(FeasibilityResponse.self, from: data)
            feasibility = response.feasibility
        } catch {
            print("[ProjectsVM] Feasibility error: \(error)")
        }
    }
}

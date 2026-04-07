import Foundation

@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published var projects: [PropertyProjectRow] = []
    @Published var quotes: [ProjectQuoteRow] = []
    @Published var projectFiles: [ProjectFileRow] = []
    @Published var feasibilityByProject: [UUID: ProjectFeasibility] = [:]
    @Published var projectDocuments: [DocumentRow] = []
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
            .sorted { ($0.actualEndDate ?? "") > ($1.actualEndDate ?? "") }
    }

    var completedProjectsTotal: Double {
        completedProjects.compactMap(\.actualSpend).filter { $0 > 0 }.reduce(0, +)
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

        // Auto-activate first quote if none is active
        if let project = projects.first(where: { $0.id == projectId }),
           project.activeQuoteId == nil,
           let firstQuote = quotes.first,
           firstQuote.quoteTotal != nil {
            try? await activateQuote(firstQuote, for: projectId)
        }
    }

    func addQuote(_ insert: ProjectQuoteInsert) async throws -> ProjectQuoteRow {
        let quote = try await db.createProjectQuote(insert)
        quotes.insert(quote, at: 0)

        // Auto-activate if it's the only quote with a total
        let quotesWithTotal = quotes.filter { $0.quoteTotal != nil }
        if quotesWithTotal.count == 1, let only = quotesWithTotal.first {
            try? await activateQuote(only, for: insert.projectId)
        }

        return quote
    }

    func activateQuote(_ quote: ProjectQuoteRow, for projectId: UUID) async throws {
        _ = try await db.updateProject(id: projectId, PropertyProjectUpdate(
            estimatedBudget: quote.quoteTotal,
            activeQuoteId: quote.id
        ))
        if let idx = projects.firstIndex(where: { $0.id == projectId }) {
            await loadProjects(propertyId: projects[idx].propertyId)
        }
        NotificationCenter.default.post(name: .projectChanged, object: nil)
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

    func loadSubProjects(parentId: UUID, propertyId: UUID? = nil) async {
        // Fetch fresh from DB to get up-to-date estimatedBudget values
        do {
            let freshProjects: [PropertyProjectRow]
            if let propertyId {
                freshProjects = try await db.fetchProjects(propertyId: propertyId)
            } else if let firstProject = projects.first {
                freshProjects = try await db.fetchProjects(propertyId: firstProject.propertyId)
            } else {
                subProjects = []
                return
            }
            // Update our local projects array with fresh data
            for fresh in freshProjects {
                if let idx = projects.firstIndex(where: { $0.id == fresh.id }) {
                    projects[idx] = fresh
                }
            }
            var subs = freshProjects.filter { $0.parentProjectId == parentId }

            // Backfill: if a sub-project has an active quote but no estimatedBudget,
            // fetch the quote total and write it to the project so this only happens once.
            for i in subs.indices {
                let sub = subs[i]
                if sub.activeQuoteId != nil && sub.estimatedBudget == nil {
                    if let quoteRows = try? await db.fetchProjectQuotes(projectId: sub.id),
                       let activeQuote = quoteRows.first(where: { $0.id == sub.activeQuoteId }),
                       let total = activeQuote.quoteTotal {
                        let updated = try? await db.updateProject(id: sub.id, PropertyProjectUpdate(estimatedBudget: total))
                        if let updated {
                            subs[i] = updated
                            if let idx = projects.firstIndex(where: { $0.id == sub.id }) {
                                projects[idx] = updated
                            }
                        }
                    }
                }
            }

            subProjects = subs
        } catch {
            // Fallback to in-memory filter
            subProjects = projects.filter { $0.parentProjectId == parentId }
        }
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
            // Reload all sub-projects fresh from DB to get accurate costs
            await loadSubProjects(parentId: claimId)
            NotificationCenter.default.post(name: .projectChanged, object: nil,
                userInfo: ["action": "updated", "id": projectId.uuidString])
        } catch {
            subProjects.removeAll { $0.id == projectId }
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    func unlinkProjectFromClaim(projectId: UUID, claimId: UUID) async {
        let snapshot = subProjects
        subProjects.removeAll { $0.id == projectId }
        Haptics.success()

        do {
            try await db.clearParentProject(id: projectId)
            // Refresh sub-projects and main projects list from DB
            await loadSubProjects(parentId: claimId)
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
    /// Best available cost for a project: prefers actual spend (if >0), then budget, then AI estimate.
    private func projectCost(_ project: PropertyProjectRow) -> Double? {
        if let s = project.actualSpend, s > 0 { return s }
        if let b = project.estimatedBudget, b > 0 { return b }
        if let a = project.aiEstimatedProCost, a > 0 { return a }
        return nil
    }

    func claimTotal(for claim: PropertyProjectRow) -> Double {
        let projectCosts = subProjects.compactMap { projectCost($0) }.reduce(0, +)
        return projectCosts + (claim.personalPropertyAmount ?? 0)
    }

    /// Legacy computed property for backward compatibility
    var claimTotal: Double {
        subProjects.compactMap { projectCost($0) }.reduce(0, +)
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

    // MARK: - Project Documents

    func loadProjectDocuments(projectId: UUID) async {
        projectDocuments = (try? await db.fetchDocuments(projectId: projectId)) ?? []
    }

    func linkDocumentToProject(documentId: UUID, projectId: UUID) async {
        do {
            try await db.linkDocumentToProject(documentId: documentId, projectId: projectId)
            await loadProjectDocuments(projectId: projectId)
            Haptics.success()
        } catch {
            print("[ProjectsVM] Link document failed: \(error)")
        }
    }

    func unlinkDocumentFromProject(documentId: UUID, projectId: UUID) async {
        do {
            try await db.unlinkDocumentFromProject(documentId: documentId)
            projectDocuments.removeAll { $0.id == documentId }
            Haptics.success()
        } catch {
            print("[ProjectsVM] Unlink document failed: \(error)")
        }
    }

    // MARK: - Feasibility / ROI

    func loadFeasibility(projectId: UUID, projectName: String, category: String, description: String?, location: String?) async {
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
            feasibilityByProject[projectId] = response.feasibility
        } catch {
            print("[ProjectsVM] Feasibility error: \(error)")
        }
    }
}

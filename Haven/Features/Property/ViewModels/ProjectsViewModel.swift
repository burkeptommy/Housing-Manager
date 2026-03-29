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

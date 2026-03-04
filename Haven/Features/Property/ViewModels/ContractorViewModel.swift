import SwiftUI

@MainActor
final class ContractorViewModel: ObservableObject {
    @Published var contractors: [ContractorRow] = []
    @Published var serviceRecords: [ServiceRecordRow] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText = ""

    private let db = DatabaseService.shared

    var filteredContractors: [ContractorRow] {
        guard !searchText.isEmpty else { return contractors }
        return contractors.filter {
            $0.companyName.localizedCaseInsensitiveContains(searchText) ||
            ($0.contactName ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.specialties ?? []).joined(separator: " ").localizedCaseInsensitiveContains(searchText)
        }
    }

    func loadContractors() async {
        isLoading = true
        do {
            contractors = try await db.fetchContractors()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteContractor(_ contractor: ContractorRow) async {
        do {
            try await db.deleteContractor(id: contractor.id)
            contractors.removeAll { $0.id == contractor.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadServiceRecords(for contractorId: UUID) async {
        do {
            let allRecords = try await db.fetchServiceRecords()
            serviceRecords = allRecords.filter { $0.contractorId == contractorId }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

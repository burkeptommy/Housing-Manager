import SwiftUI

@MainActor
final class ContractorViewModel: ObservableObject {
    @Published var contractors: [ContractorRow] = []
    @Published var serviceRecords: [ServiceRecordRow] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText = ""
    @Published var filterSpecialty: String?
    @Published var sortBy: SortOption = .name

    enum SortOption: String, CaseIterable {
        case name = "Name"
        case rating = "Rating"
    }

    private let db = DatabaseService.shared

    var filteredContractors: [ContractorRow] {
        var result = contractors

        if !searchText.isEmpty {
            result = result.filter {
                $0.companyName.localizedCaseInsensitiveContains(searchText) ||
                ($0.contactName ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.specialties ?? []).joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }

        if let specialty = filterSpecialty {
            result = result.filter {
                $0.specialties?.contains(specialty) ?? false
            }
        }

        switch sortBy {
        case .name:
            result.sort { $0.companyName < $1.companyName }
        case .rating:
            result.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        }

        return result
    }

    var availableSpecialties: [String] {
        Array(Set(contractors.flatMap { $0.specialties ?? [] })).sorted()
    }

    func totalSpent(for contractorId: UUID) -> Double {
        serviceRecords.filter { $0.contractorId == contractorId }
            .compactMap(\.cost)
            .reduce(0, +)
    }

    func loadContractors() async {
        isLoading = true
        do {
            async let contractorsResult = db.fetchContractors()
            async let recordsResult = db.fetchServiceRecords()
            let (c, r) = try await (contractorsResult, recordsResult)
            contractors = c
            serviceRecords = r
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteContractor(_ contractor: ContractorRow) async {
        let snapshot = contractors
        contractors.removeAll { $0.id == contractor.id }
        Haptics.success()

        do {
            try await db.deleteContractor(id: contractor.id)
            NotificationCenter.default.post(name: .contractorChanged, object: nil,
                userInfo: ["action": "deleted", "id": contractor.id.uuidString])
        } catch {
            contractors = snapshot
            self.error = error.localizedDescription
            Haptics.error()
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

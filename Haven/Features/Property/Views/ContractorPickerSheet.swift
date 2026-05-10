import SwiftUI

struct ContractorPickerSheet: View {
    let systemCategory: String
    var onSelect: (ContractorRow) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var contractors: [ContractorRow] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var showAddContractor = false

    private var filteredContractors: [ContractorRow] {
        let categoryScoped = categoryFilteredContractors
        if searchText.isEmpty { return categoryScoped }
        let query = searchText.lowercased()
        return categoryScoped.filter {
            $0.companyName.lowercased().contains(query) ||
            ($0.contactName?.lowercased().contains(query) ?? false) ||
            ($0.category?.lowercased().contains(query) ?? false) ||
            ($0.specialties?.contains { $0.lowercased().contains(query) } ?? false)
        }
    }

    private var categoryFilteredContractors: [ContractorRow] {
        guard let target = Self.canonicalContractorCategory(systemCategory) else {
            return contractors
        }
        let matches = contractors.filter { contractor in
            Self.contractor(contractor, matchesCategory: target)
        }
        return matches
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if contractors.isEmpty {
                    ContentUnavailableView {
                        Label("No Contractors", systemImage: "person.crop.circle.badge.questionmark")
                    } description: {
                        Text("Add a contractor to your directory first.")
                    } actions: {
                        Button("Add Contractor") { showAddContractor = true }
                            .buttonStyle(.bordered)
                    }
                } else if filteredContractors.isEmpty {
                    ContentUnavailableView {
                        Label("No Matching Contractors", systemImage: "person.crop.circle.badge.questionmark")
                    } description: {
                        Text("Try another search or add a contractor.")
                    } actions: {
                        Button("Add Contractor") { showAddContractor = true }
                            .buttonStyle(.bordered)
                    }
                } else {
                    List {
                        ForEach(filteredContractors) { contractor in
                            Button {
                                Analytics.track(.systemContractorAssigned, ["contractor_id": contractor.id.uuidString, "system_category": systemCategory])
                                onSelect(contractor)
                                dismiss()
                            } label: {
                                contractorRow(contractor)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search contractors")
                }
            }
            .navigationTitle("Select Contractor")
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("ContractorPickerSheet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddContractor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await loadContractors()
            }
            .sheet(isPresented: $showAddContractor) {
                // Phase 56.1: direct to AddVendorSheet so the "+" button
                // inside the picker lands the user on the add form
                // immediately instead of routing through the directory.
                AddVendorSheet(onComplete: {
                    Task { await loadContractors() }
                })
            }
        }
    }

    private static func contractor(_ contractor: ContractorRow, matchesCategory target: String) -> Bool {
        var candidates: [String?] = [contractor.category]
        candidates.append(contentsOf: (contractor.specialties ?? []).map { Optional.some($0) })
        return candidates
            .compactMap { canonicalContractorCategory($0) }
            .contains(target)
    }

    private static func canonicalContractorCategory(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let displayReady = raw
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if displayReady.caseInsensitiveCompare("mosquito tick") == .orderedSame {
            return "Mosquito & Tick"
        }
        return SystemCategoryRegistry.canonical(category: displayReady)
    }

    private func contractorRow(_ contractor: ContractorRow) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(contractor.companyName)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)

                if let contact = contractor.contactName {
                    Text(contact)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if let specialties = contractor.specialties, !specialties.isEmpty {
                    Text(specialties.joined(separator: ", "))
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let rating = contractor.rating, rating > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(HavenColors.warning)
                    Text("\(rating)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
    }

    private func loadContractors() async {
        do {
            contractors = try await DatabaseService.shared.fetchContractors()
        } catch {
            // silently handle
        }
        isLoading = false
    }
}

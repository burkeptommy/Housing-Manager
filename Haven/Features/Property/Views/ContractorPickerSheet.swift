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
        if searchText.isEmpty { return contractors }
        let query = searchText.lowercased()
        return contractors.filter {
            $0.companyName.lowercased().contains(query) ||
            ($0.contactName?.lowercased().contains(query) ?? false) ||
            ($0.specialties?.contains { $0.lowercased().contains(query) } ?? false)
        }
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

import SwiftUI

/// Pick-or-add vendor sheet shown when the user taps "I have one" on a
/// Vendor Coverage gap card. Lets them either link an existing vendor
/// in their directory (the common case when one vendor covers multiple
/// systems — e.g. a Water & Well Services provider who also handles
/// the water softener) or add a brand-new one via `AddVendorSheet`.
///
/// In both paths the selected contractor is linked to the gap's home
/// system via `preferredContractorId`, which is the signal that
/// `SystemCategoryRegistry.vendorCoverageItems` reads to mark the
/// system as covered. For Tier 1 gaps that don't have a `home_systems`
/// row yet, the row is created first and then the contractor is
/// linked.
struct VendorCoveragePickerSheet: View {
    let coverageItem: VendorCoverageItem
    let householdId: UUID
    let propertyId: UUID?
    var onComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var contractors: [ContractorRow] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var isLinking = false
    @State private var showAddVendor = false
    /// Snapshot of contractor IDs before we opened AddVendorSheet so
    /// we can find the newly-created vendor by set difference on
    /// return and auto-link it. Avoids a second tap for the common
    /// "add new + immediately pick" flow.
    @State private var contractorIdsBeforeAdd: Set<UUID> = []
    @State private var errorMessage: String?

    private var filteredContractors: [ContractorRow] {
        guard !searchText.isEmpty else { return contractors }
        let query = searchText.lowercased()
        return contractors.filter { c in
            c.companyName.lowercased().contains(query)
                || (c.contactName?.lowercased().contains(query) ?? false)
                || (c.specialties?.contains { $0.lowercased().contains(query) } ?? false)
                || (c.category?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    contentList
                }
            }
            .background(HavenColors.background)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
            .task { await loadContractors() }
            .sheet(isPresented: $showAddVendor) {
                // Feed the gap's canonical category (which IS the
                // SystemCategoryRegistry key per `vendorCoverageItems`)
                // through so AddVendorSheet's downstream import paths
                // (website + contacts) can auto-stamp the specialty
                // picker and pre-select category-matching home systems
                // on the assignment sheet. Skips ~2 manual taps for
                // the common gap-resolution flow.
                AddVendorSheet(
                    onComplete: { Task { await autoSelectNewlyAdded() } },
                    prefilledCategory: coverageItem.id
                )
            }
            .trackScreen("VendorCoveragePickerSheet", properties: [
                "system_category": coverageItem.id
            ])
        }
    }

    private var navigationTitle: String {
        "Who handles \(coverageItem.systemName)?"
    }

    @ViewBuilder
    private var contentList: some View {
        List {
            Section {
                Text("Pick a vendor you already have, or add a new one.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
            }

            if !filteredContractors.isEmpty {
                Section {
                    ForEach(filteredContractors) { contractor in
                        Button {
                            link(to: contractor)
                        } label: {
                            contractorRow(contractor)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLinking)
                    }
                } header: {
                    Text("Your vendors")
                }
            } else if contractors.isEmpty {
                Section {
                    Text("You haven't added any vendors yet.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            } else {
                Section {
                    Text("No matches for \"\(searchText)\".")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            Section {
                Button {
                    Haptics.light()
                    contractorIdsBeforeAdd = Set(contractors.map(\.id))
                    showAddVendor = true
                } label: {
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add a new vendor")
                                .font(HavenTypography.uiLabel.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Import from Contacts, a website, or type in the details.")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .disabled(isLinking)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search your vendors")
    }

    private func contractorRow(_ contractor: ContractorRow) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            VendorLogoView(contractor: contractor, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(contractor.companyName)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                if let subtitle = rowSubtitle(for: contractor) {
                    Text(subtitle)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if isLinking {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func rowSubtitle(for contractor: ContractorRow) -> String? {
        if let category = contractor.category, !category.isEmpty {
            return category
        }
        if let specialties = contractor.specialties, !specialties.isEmpty {
            return specialties.joined(separator: ", ")
        }
        return contractor.contactName
    }

    // MARK: - Data

    private func loadContractors() async {
        do {
            let rows = try await DatabaseService.shared.fetchContractors()
            await MainActor.run {
                contractors = rows.sorted {
                    $0.companyName.localizedCaseInsensitiveCompare($1.companyName) == .orderedAscending
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Couldn't load your vendors: \(error.localizedDescription)"
            }
        }
    }

    /// Reload contractors after AddVendorSheet completes; if a brand-
    /// new vendor was created we immediately link it to the gap system
    /// so the user doesn't have to tap back through the list.
    private func autoSelectNewlyAdded() async {
        await loadContractors()
        let currentIds = Set(contractors.map(\.id))
        let newIds = currentIds.subtracting(contractorIdsBeforeAdd)
        guard let newId = newIds.first,
              let newContractor = contractors.first(where: { $0.id == newId }) else {
            // No diff (user cancelled or it was a dedupe). Stay on
            // the picker so the user can pick manually.
            return
        }
        link(to: newContractor)
    }

    // MARK: - Link

    private func link(to contractor: ContractorRow) {
        guard !isLinking else { return }
        isLinking = true
        errorMessage = nil
        Task {
            do {
                try await linkToSystem(contractor: contractor)
                await MainActor.run {
                    Haptics.success()
                    onComplete?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLinking = false
                    errorMessage = "Couldn't link \(contractor.companyName): \(error.localizedDescription)"
                    Haptics.error()
                }
            }
        }
    }

    private func linkToSystem(contractor: ContractorRow) async throws {
        let db = DatabaseService.shared
        let targetSystemId: UUID
        if let existing = coverageItem.systemId {
            targetSystemId = existing
        } else {
            // Tier 1 gap — no home_systems row yet. Create one so the
            // coverage read can resolve the link via the system's
            // preferredContractorId field.
            guard let propertyId else {
                throw NSError(
                    domain: "VendorCoveragePicker",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No property available to add this system to."]
                )
            }
            let insert = HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: coverageItem.systemName,
                category: coverageItem.id
            )
            let created = try await db.createHomeSystem(insert)
            targetSystemId = created.id
        }

        var update = HomeSystemUpdate()
        update.preferredContractorId = contractor.id
        _ = try await db.updateHomeSystem(id: targetSystemId, update)

        NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
        NotificationCenter.default.post(name: .contractorChanged, object: nil)
        Analytics.track(.systemContractorAssigned, [
            "source": "vendor_coverage_pick",
            "system_category": coverageItem.id,
            "contractor_id": contractor.id.uuidString,
            "was_existing_contractor": contractorIdsBeforeAdd.contains(contractor.id) || contractorIdsBeforeAdd.isEmpty
                ? "existing"
                : "newly_added",
        ])
    }
}

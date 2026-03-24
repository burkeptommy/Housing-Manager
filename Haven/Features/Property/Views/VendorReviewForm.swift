import SwiftUI

struct VendorReviewForm: View {
    @Binding var vendor: ImportedVendorData
    var onSave: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var isSaving = false
    @State private var error: String?
    @State private var showSystemAssignment = false
    @State private var savedContractorId: UUID?

    // System assignment after save
    @State private var systems: [HomeSystemRow] = []
    @State private var selectedSystemIds: Set<UUID> = []

    private let contactTypes = [
        "Contractor / Service Provider",
        "Attorney",
        "Financial Advisor / CPA",
        "Insurance Agent",
        "Property Manager",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Source badge
                if vendor.source != .manual {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: vendor.source == .contacts ? "person.crop.circle.fill" : "globe")
                                .foregroundStyle(HavenColors.success)
                            Text(vendor.source == .contacts ? "Imported from Contacts" : "Imported from Website")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.success)
                            Spacer()
                            Text("Review & save")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }

                Section("Type") {
                    Picker("Vendor Type", selection: $vendor.contactType) {
                        ForEach(contactTypes, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section("Contact Information") {
                    TextField("Company / Business Name", text: $vendor.companyName)
                    TextField("Contact Person", text: Binding(
                        get: { vendor.contactName ?? "" },
                        set: { vendor.contactName = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Phone", text: $vendor.phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $vendor.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Address", text: $vendor.address)
                    if !vendor.website.isEmpty {
                        HStack {
                            Text("Website")
                                .foregroundStyle(HavenColors.textSecondary)
                            Spacer()
                            Text(vendor.website)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.navy700)
                                .lineLimit(1)
                        }
                    }
                }

                // Services / Specialties
                if vendor.contactType == "Contractor / Service Provider" {
                    Section("Services") {
                        // Show AI-detected services first (from website)
                        if !vendor.detectedServices.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Detected from website:")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                FlowLayout(spacing: 6) {
                                    ForEach(vendor.detectedServices, id: \.self) { service in
                                        let isSelected = vendor.specialties.contains(service) ||
                                            vendor.specialties.contains(where: { matchServiceToCategory(service) == $0 })
                                        Text(service)
                                            .font(.system(size: 12, weight: .medium))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(isSelected ? HavenColors.navy.opacity(0.12) : HavenColors.beige200)
                                            .foregroundStyle(isSelected ? HavenColors.navy : HavenColors.textSecondary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // Standard category picker
                        ForEach(allServiceCategories, id: \.self) { cat in
                            Button {
                                if vendor.specialties.contains(cat) {
                                    vendor.specialties.remove(cat)
                                } else {
                                    vendor.specialties.insert(cat)
                                }
                            } label: {
                                HStack {
                                    Text(cat)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Spacer()
                                    if vendor.specialties.contains(cat) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(HavenColors.navy)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("License (Optional)") {
                    TextField("License Number", text: $vendor.licenseNumber)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(HavenColors.critical)
                            .font(HavenTypography.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HavenColors.cream)
            .navigationTitle(vendor.source == .manual ? "Add Vendor" : "Review & Save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView().tint(HavenColors.navy)
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(vendor.companyName.isEmpty || vendor.phone.isEmpty)
                    }
                }
            }
            .tint(HavenColors.navy)
            .trackScreen("VendorReviewForm")
            .sheet(isPresented: $showSystemAssignment) {
                SystemAssignmentSheet(
                    systems: systems,
                    selectedIds: $selectedSystemIds,
                    vendorName: vendor.companyName,
                    onDone: {
                        Task { await assignSystems() }
                    }
                )
            }
        }
    }

    private var allServiceCategories: [String] {
        ["HVAC", "Plumbing", "Electrical", "Roofing", "Landscaping", "Pest Control",
         "Siding/Exterior", "Pool/Spa", "Septic System", "Well System", "Generator",
         "Security System", "Solar", "Fire Protection", "Garage Door", "Windows",
         "Appliance", "Flooring", "Insulation", "Crawl Space", "General Handyman", "Other"]
    }

    private func matchServiceToCategory(_ service: String) -> String? {
        let lower = service.lowercased()
        if lower.contains("hvac") || lower.contains("heating") || lower.contains("cooling") { return "HVAC" }
        if lower.contains("plumb") { return "Plumbing" }
        if lower.contains("electric") { return "Electrical" }
        if lower.contains("roof") { return "Roofing" }
        if lower.contains("landscap") || lower.contains("lawn") { return "Landscaping" }
        return nil
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        error = nil

        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                error = "No household found"
                isSaving = false
                return
            }

            var allSpecialties = Array(vendor.specialties)
            if vendor.contactType != "Contractor / Service Provider" && !allSpecialties.contains(vendor.contactType) {
                allSpecialties.insert(vendor.contactType, at: 0)
            }

            let insert = ContractorInsert(
                householdId: householdId,
                companyName: vendor.companyName,
                phone: vendor.phone,
                contactName: vendor.contactName,
                email: vendor.email.isEmpty ? nil : vendor.email,
                specialties: allSpecialties.isEmpty ? nil : allSpecialties,
                address: vendor.address.isEmpty ? nil : vendor.address,
                licenseNumber: vendor.licenseNumber.isEmpty ? nil : vendor.licenseNumber
            )

            let contractor = try await DatabaseService.shared.createContractor(insert)
            savedContractorId = contractor.id
            Analytics.track(.contractorCreated, ["contractor_id": contractor.id.uuidString, "source": vendor.source == .manual ? "manual" : vendor.source == .contacts ? "contacts" : "website"])
            Haptics.success()

            // Load systems for assignment
            let allSystems = (try? await DatabaseService.shared.fetchHomeSystems()) ?? []
            if !allSystems.isEmpty {
                systems = allSystems
                showSystemAssignment = true
            } else {
                // No systems — just complete
                onSave?()
                dismiss()
            }
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isSaving = false
    }

    private func assignSystems() async {
        guard let contractorId = savedContractorId else { return }
        for systemId in selectedSystemIds {
            _ = try? await DatabaseService.shared.updateHomeSystem(
                id: systemId,
                HomeSystemUpdate(preferredContractorId: contractorId)
            )
        }
        onSave?()
        dismiss()
    }
}

// MARK: - System Assignment Sheet

struct SystemAssignmentSheet: View {
    let systems: [HomeSystemRow]
    @Binding var selectedIds: Set<UUID>
    let vendorName: String
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("Assign to Home Systems")
                        .font(HavenTypography.title2)
                    Text("Which systems does \(vendorName) service?")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(.top, 16)

                List(systems) { system in
                    Button {
                        if selectedIds.contains(system.id) {
                            selectedIds.remove(system.id)
                        } else {
                            selectedIds.insert(system.id)
                        }
                    } label: {
                        HStack {
                            Text(system.name)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                            if selectedIds.contains(system.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(HavenColors.navy)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Assign Systems")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        selectedIds.removeAll()
                        onDone()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// FlowLayout is defined in DocumentDetailView.swift and shared across the app

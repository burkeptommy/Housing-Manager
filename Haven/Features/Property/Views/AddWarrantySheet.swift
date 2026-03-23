import SwiftUI

struct AddWarrantySheet: View {
    let systemId: UUID
    var householdId: UUID?
    var onComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var provider = ""
    @State private var warrantyType = "Manufacturer"
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var coverageDetails = ""
    @State private var claimPhone = ""
    @State private var policyNumber = ""
    @State private var isSaving = false
    @State private var error: String?

    private let warrantyTypes = ["Manufacturer", "Extended", "Home Warranty", "Labor Warranty"]

    var body: some View {
        Form {
            Section {
                TextField("Provider Name", text: $provider)
                Picker("Warranty Type", selection: $warrantyType) {
                    ForEach(warrantyTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
            } header: {
                Text("WARRANTY INFO")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
            }

            Section {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            } header: {
                Text("COVERAGE PERIOD")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
            }

            Section {
                TextField("Claim Phone", text: $claimPhone)
                    .keyboardType(.phonePad)
                TextField("Policy Number", text: $policyNumber)
                TextEditor(text: $coverageDetails)
                    .frame(minHeight: 60)
                    .overlay(alignment: .topLeading) {
                        if coverageDetails.isEmpty {
                            Text("Coverage details...")
                                .foregroundStyle(HavenColors.textTertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
            } header: {
                Text("CONTACT & COVERAGE")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
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
        .navigationTitle("Add Warranty")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(provider.isEmpty || isSaving)
            }
        }
        .tint(HavenColors.navy)
    }

    private func save() async {
        isSaving = true
        error = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        do {
            var resolvedHouseholdId = householdId
            if resolvedHouseholdId == nil {
                let user = try await DatabaseService.shared.fetchCurrentUser()
                resolvedHouseholdId = user.householdId
            }
            guard let hid = resolvedHouseholdId else {
                error = "No household found"
                isSaving = false
                return
            }

            let insert = WarrantyInsert(
                householdId: hid,
                provider: provider,
                warrantyType: warrantyType,
                startDate: formatter.string(from: startDate),
                endDate: formatter.string(from: endDate),
                systemId: systemId,
                coverageDetails: coverageDetails.isEmpty ? nil : coverageDetails,
                claimPhone: claimPhone.isEmpty ? nil : claimPhone,
                policyNumber: policyNumber.isEmpty ? nil : policyNumber
            )
            _ = try await DatabaseService.shared.createWarranty(insert)

            Haptics.success()
            onComplete?()
            dismiss()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isSaving = false
    }
}

#Preview {
    NavigationStack {
        AddWarrantySheet(systemId: UUID())
    }
}

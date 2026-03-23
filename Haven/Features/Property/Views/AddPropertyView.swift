import SwiftUI

struct AddPropertyView: View {
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var propertyType = "Primary Residence"
    @State private var street = ""
    @State private var unit = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var ownershipEntity = ""
    @State private var purchasePrice = ""
    @State private var yearBuilt = ""
    @State private var squareFootage = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var error: String?
    @State private var showSystemSetup = false
    @State private var savedPropertyId: UUID?
    @State private var savedHouseholdId: UUID?

    private let propertyTypes = ["Primary Residence", "Vacation Home", "Rental Property", "Commercial", "Land"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Property Info") {
                    TextField("Property Name", text: $name)
                    Picker("Type", selection: $propertyType) {
                        ForEach(propertyTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                Section("Address") {
                    AddressAutocompleteField(
                        street: $street,
                        unit: $unit,
                        city: $city,
                        state: $state,
                        zipCode: $zipCode
                    )
                }

                Section("Details (Optional)") {
                    TextField("Purchase Price", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                    TextField("Year Built", text: $yearBuilt)
                        .keyboardType(.numberPad)
                    TextField("Square Footage", text: $squareFootage)
                        .keyboardType(.numberPad)
                    TextField("Ownership Entity", text: $ownershipEntity)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
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
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                            .tint(HavenColors.navy)
                    } else {
                        Button("Save") {
                            Task { await save() }
                        }
                        .disabled(name.isEmpty)
                    }
                }
            }
            .tint(HavenColors.navy)
            .fullScreenCover(isPresented: $showSystemSetup) {
                if let propId = savedPropertyId, let hhId = savedHouseholdId {
                    HomeSystemsSetupView(
                        propertyId: propId,
                        householdId: hhId,
                        propertyType: propertyType
                    ) {
                        onComplete?()
                        dismiss()
                    }
                }
            }
        }
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

            let insert = PropertyInsert(
                householdId: householdId,
                name: name,
                propertyType: propertyType,
                street: street.isEmpty ? nil : street,
                unit: unit.isEmpty ? nil : unit,
                city: city.isEmpty ? nil : city,
                state: state.isEmpty ? nil : state,
                zipCode: zipCode.isEmpty ? nil : zipCode,
                purchasePrice: Double(purchasePrice),
                squareFootage: Int(squareFootage),
                yearBuilt: Int(yearBuilt),
                ownershipEntity: ownershipEntity.isEmpty ? nil : ownershipEntity,
                notes: notes.isEmpty ? nil : notes
            )

            let property = try await DatabaseService.shared.createProperty(insert)

            Haptics.success()
            savedPropertyId = property.id
            savedHouseholdId = householdId

            // Brief visual confirmation before transitioning
            try? await Task.sleep(nanoseconds: 300_000_000)
            showSystemSetup = true
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isSaving = false
    }
}

#Preview {
    AddPropertyView()
}

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
                    TextField("Street", text: $street)
                    TextField("Unit/Apt (optional)", text: $unit)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
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
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() async {
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

            _ = try await DatabaseService.shared.createProperty(insert)
            onComplete?()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    AddPropertyView()
}

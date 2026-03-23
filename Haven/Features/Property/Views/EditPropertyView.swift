import SwiftUI

struct EditPropertyView: View {
    let property: PropertyRow
    var onSave: ((PropertyRow) -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var propertyType: String
    @State private var street: String
    @State private var unit: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String
    @State private var purchasePrice: String
    @State private var yearBuilt: String
    @State private var squareFootage: String
    @State private var ownershipEntity: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var error: String?

    private let propertyTypes = ["Primary Residence", "Vacation Home", "Rental Property", "Commercial", "Land"]

    init(property: PropertyRow, onSave: ((PropertyRow) -> Void)? = nil) {
        self.property = property
        self.onSave = onSave
        _name = State(initialValue: property.name)
        _propertyType = State(initialValue: property.propertyType)
        _street = State(initialValue: property.street ?? "")
        _unit = State(initialValue: property.unit ?? "")
        _city = State(initialValue: property.city ?? "")
        _state = State(initialValue: property.state ?? "")
        _zipCode = State(initialValue: property.zipCode ?? "")
        _purchasePrice = State(initialValue: property.purchasePrice.map { String(format: "%.0f", $0) } ?? "")
        _yearBuilt = State(initialValue: property.yearBuilt.map { String($0) } ?? "")
        _squareFootage = State(initialValue: property.squareFootage.map { String($0) } ?? "")
        _ownershipEntity = State(initialValue: property.ownershipEntity ?? "")
        _notes = State(initialValue: property.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Property Info") {
                    TextField("Property Name", text: $name)
                    Picker("Type", selection: $propertyType) {
                        ForEach(propertyTypes, id: \.self) { Text($0).tag($0) }
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

                Section("Details") {
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
            .navigationTitle("Edit Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(name.isEmpty || isSaving)
                }
            }
            .tint(HavenColors.navy)
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        do {
            let update = PropertyUpdate(
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
            let updated = try await DatabaseService.shared.updateProperty(id: property.id, update)
            onSave?(updated)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}

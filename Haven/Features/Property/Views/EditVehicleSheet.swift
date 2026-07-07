import SwiftUI

struct EditVehicleSheet: View {
    let vehicle: VehicleRow
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var licensePlate: String
    @State private var color: String
    @State private var currentMileage: String
    @State private var ownershipType: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var error: String?

    init(vehicle: VehicleRow, onSave: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.onSave = onSave
        _name = State(initialValue: vehicle.name)
        _licensePlate = State(initialValue: vehicle.licensePlate ?? "")
        _color = State(initialValue: vehicle.color ?? "")
        _currentMileage = State(initialValue: vehicle.currentMileage.map { String($0) } ?? "")
        _ownershipType = State(initialValue: vehicle.ownershipType ?? "owned")
        _notes = State(initialValue: vehicle.notes ?? "")
    }

    var body: some View {
        Form {
            Section {
                TextField("Vehicle Name", text: $name)
                    .textInputAutocapitalization(.words)
            } header: {
                Text("NAME").font(HavenTypography.uiSectionHeader).tracking(1.5)
            }

            Section {
                LabeledContent("License Plate") {
                    TextField("Optional", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Color") {
                    TextField("Optional", text: $color)
                        .textInputAutocapitalization(.words)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Mileage") {
                    TextField("Optional", text: $currentMileage)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                Picker("Ownership", selection: $ownershipType) {
                    Text("Owned").tag("owned")
                    Text("Leased").tag("leased")
                    Text("Financed").tag("financed")
                }
            } header: {
                Text("DETAILS").font(HavenTypography.uiSectionHeader).tracking(1.5)
            }

            Section {
                TextEditor(text: $notes)
                    .frame(minHeight: 60)
            } header: {
                Text("NOTES").font(HavenTypography.uiSectionHeader).tracking(1.5)
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
        .navigationTitle("Edit Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving..." : "Save") {
                    Task { await save() }
                }
                .disabled(isSaving || name.isEmpty)
            }
        }
        .tint(HavenColors.navy)
    }

    private func save() async {
        isSaving = true
        error = nil
        do {
            _ = try await DatabaseService.shared.updateVehicle(id: vehicle.id, VehicleUpdate(
                name: name,
                color: color.isEmpty ? nil : color,
                licensePlate: licensePlate.isEmpty ? nil : licensePlate,
                currentMileage: Int(currentMileage),
                ownershipType: ownershipType,
                notes: notes.isEmpty ? nil : notes
            ))

            // July 2026 (audit F4): nil fields are OMITTED from the PATCH —
            // deleting a wrong plate/color/note and saving silently kept the
            // old value. Explicit SQL NULLs for cleared fields.
            var clearedColumns: [String] = []
            if color.isEmpty, vehicle.color?.isEmpty == false { clearedColumns.append("color") }
            if licensePlate.isEmpty, vehicle.licensePlate?.isEmpty == false { clearedColumns.append("license_plate") }
            if notes.isEmpty, vehicle.notes?.isEmpty == false { clearedColumns.append("notes") }
            try? await DatabaseService.shared.clearColumns(
                table: "vehicles", id: vehicle.id, columns: clearedColumns
            )
            Haptics.success()
            onSave?()
            dismiss()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isSaving = false
    }
}

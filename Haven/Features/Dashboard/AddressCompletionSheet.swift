import SwiftUI

/// Simple sheet to collect a missing property address.
/// Shown when an existing user has a property without street/city data.
struct AddressCompletionSheet: View {
    let property: PropertyRow
    var onComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                Text("Help Chez give you better property data, home values, and maintenance recommendations by adding your address.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .listRowBackground(Color.clear)
            }

            Section {
                TextField("Street Address", text: $street)
                    .textContentType(.streetAddressLine1)
                    .textInputAutocapitalization(.words)
                TextField("City", text: $city)
                    .textContentType(.addressCity)
                    .textInputAutocapitalization(.words)
                HStack {
                    TextField("State", text: $state)
                        .textContentType(.addressState)
                        .textInputAutocapitalization(.characters)
                    TextField("ZIP Code", text: $zipCode)
                        .textContentType(.postalCode)
                        .keyboardType(.numberPad)
                }
            } header: {
                Text("ADDRESS FOR \(property.name.uppercased())")
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
        .navigationTitle("Complete Address")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Skip") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving..." : "Save") {
                    Task { await save() }
                }
                .disabled(isSaving || (street.isEmpty && city.isEmpty))
            }
        }
        .tint(HavenColors.navy)
        .onAppear {
            // Pre-fill any existing partial data
            street = property.street ?? ""
            city = property.city ?? ""
            state = property.state ?? ""
            zipCode = property.zipCode ?? ""
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        do {
            _ = try await DatabaseService.shared.updateProperty(
                id: property.id,
                PropertyUpdate(
                    street: street.isEmpty ? nil : street,
                    city: city.isEmpty ? nil : city,
                    state: state.isEmpty ? nil : state,
                    zipCode: zipCode.isEmpty ? nil : zipCode
                )
            )
            Haptics.success()
            NotificationCenter.default.post(name: .propertyChanged, object: nil)
            onComplete?()
            dismiss()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isSaving = false
    }
}

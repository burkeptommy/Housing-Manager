import SwiftUI

/// Phase 95 (audit gap #78) — explicit insurance policy editor.
///
/// Mirrors the registration_expiry pattern: the homeowner can
/// stamp policy expiry, policy number, and carrier directly on
/// the vehicle row without uploading a document. When a document
/// IS on file, this sheet complements it — the homeowner can have
/// both the scanned PDF and the structured fields, and the
/// insurance card surfaces the structured fields when set.
///
/// All three fields are optional; saving with everything blank
/// clears the columns (lets the user undo a previous stamp). The
/// sheet posts no notification; VehicleDetailView reloads on
/// dismiss via the onSave callback.
struct EditInsuranceSheet: View {
    let vehicle: VehicleRow
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var carrier: String
    @State private var policyNumber: String
    @State private var hasExpiry: Bool
    @State private var expiryDate: Date
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(vehicle: VehicleRow, onSave: @escaping () -> Void) {
        self.vehicle = vehicle
        self.onSave = onSave
        _carrier = State(initialValue: vehicle.insuranceCarrier ?? "")
        _policyNumber = State(initialValue: vehicle.insurancePolicyNum ?? "")
        _hasExpiry = State(initialValue: vehicle.insuranceExpiry != nil)
        if let raw = vehicle.insuranceExpiry,
           let parsed = Self.dateFormatter.date(from: raw) {
            _expiryDate = State(initialValue: parsed)
        } else {
            _expiryDate = State(
                initialValue: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            )
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Carrier") {
                    TextField("e.g. Chubb, GEICO, Travelers", text: $carrier)
                        .textInputAutocapitalization(.words)
                }
                Section("Policy number") {
                    TextField("Policy number", text: $policyNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                Section {
                    Toggle("Track expiration", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Expires", selection: $expiryDate, displayedComponents: .date)
                    }
                } footer: {
                    if hasExpiry {
                        Text("Chez will remind you 60 / 30 / 7 days before this date.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
            }
            .navigationTitle("Insurance policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    @MainActor
    private func save() async {
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        let trimmedCarrier = carrier.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPolicy = policyNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let expiryString = hasExpiry ? Self.dateFormatter.string(from: expiryDate) : nil

        var update = VehicleUpdate()
        update.insuranceCarrier = trimmedCarrier.isEmpty ? nil : trimmedCarrier
        update.insurancePolicyNum = trimmedPolicy.isEmpty ? nil : trimmedPolicy
        update.insuranceExpiry = expiryString

        do {
            _ = try await DatabaseService.shared.updateVehicle(id: vehicle.id, update)
            Analytics.track(.vehicleInsuranceEdited, [
                "vehicle_id": vehicle.id.uuidString,
                "has_carrier": String(!trimmedCarrier.isEmpty),
                "has_policy_num": String(!trimmedPolicy.isEmpty),
                "has_expiry": String(hasExpiry)
            ])
            Haptics.success()
            onSave()
            dismiss()
        } catch {
            errorMessage = "Couldn't save right now. Try again in a moment."
            Haptics.error()
        }
    }
}

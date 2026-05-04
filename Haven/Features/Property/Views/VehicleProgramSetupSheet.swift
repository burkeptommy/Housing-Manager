import SwiftUI

/// Phase 66 / BUG-013 fix: Sheet that sets up a shop-managed or
/// self-managed routine for a vehicle. Wires the previously-dead
/// "Set up shop →" link on the MaintenanceHubView vehicle card.
struct VehicleProgramSetupSheet: View {
    let vehicle: VehicleRow
    let householdId: UUID
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedShop: ContractorRow?
    @State private var programMode: RoutineProgramMode = .shopManaged
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showContractorPicker = false

    private var vehicleTitle: String {
        var parts: [String] = []
        if let year = vehicle.year { parts.append("\(year)") }
        if let make = vehicle.make, !make.isEmpty { parts.append(make) }
        if let model = vehicle.model, !model.isEmpty { parts.append(model) }
        return parts.isEmpty ? "This vehicle" : parts.joined(separator: " ")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vehicleTitle)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Set up how Chez tracks service for this vehicle.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(.vertical, 6)
                }

                Section("Who handles service?") {
                    Picker("Mode", selection: $programMode) {
                        Text("Shop-managed").tag(RoutineProgramMode.shopManaged)
                        Text("Self-managed").tag(RoutineProgramMode.selfManaged)
                    }
                    .pickerStyle(.segmented)

                    Text(programMode == .shopManaged
                         ? "Your shop handles everything. Individual service items hide under the shop."
                         : "You manage service yourself. Individual tasks stay visible on your schedule.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if programMode == .shopManaged {
                    Section {
                        Button {
                            showContractorPicker = true
                        } label: {
                            HStack {
                                if let shop = selectedShop {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(shop.companyName)
                                            .font(HavenTypography.body)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        if let contact = shop.contactName, !contact.isEmpty {
                                            Text(contact)
                                                .font(HavenTypography.caption)
                                                .foregroundStyle(HavenColors.textSecondary)
                                        }
                                    }
                                } else {
                                    Text("Pick a shop (optional)")
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                        if selectedShop != nil {
                            Button(role: .destructive) {
                                Haptics.light()
                                selectedShop = nil
                            } label: {
                                Label("Remove shop", systemImage: "xmark.circle")
                            }
                        }
                    } header: {
                        Text("Shop")
                    } footer: {
                        Text("You can add a shop later if you don't have one yet.")
                            .font(HavenTypography.caption)
                    }
                }

                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }

                if let message = errorMessage {
                    Section {
                        Text(message)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
            }
            .navigationTitle("Set up shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .foregroundStyle(HavenColors.action)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .sheet(isPresented: $showContractorPicker) {
                ContractorPickerSheet(systemCategory: "Automotive") { contractor in
                    selectedShop = contractor
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let routine = try await DatabaseService.shared.createVehicleRoutine(
                vehicle: vehicle,
                householdId: householdId,
                shopContractorId: selectedShop?.id,
                programMode: programMode,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : notes
            )

            // Phase 95 (audit gaps #87/#88) — when the user activates a
            // shop-managed program, run the grouping engine so the
            // vehicle's existing oil-change / tire-rotation tasks get
            // `parent_routine_id` set and stop rendering individually.
            // Without this the user sees the program card AND every
            // single task it's supposed to subsume — confusing because
            // the routine card says "the shop handles this" while the
            // task list still surfaces every line item. Self-managed
            // mode skips the link by design (linkVehicleTasksToRoutine
            // is a no-op when programMode != .shopManaged).
            if routine.typedSetupState == .active {
                _ = try? await RoutineGroupingEngine.linkVehicleTasksToRoutine(
                    routine,
                    in: householdId
                )
                NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            }

            Analytics.track(.routineActivated, [
                "routine_id": routine.id.uuidString,
                "scope": "vehicle",
                "program_mode": programMode.rawValue,
                "has_vendor": selectedShop != nil ? "true" : "false"
            ])
            NotificationCenter.default.post(name: .routineChanged, object: nil)
            Haptics.success()
            onSaved()
            dismiss()
        } catch {
            errorMessage = "Couldn't save. Try again in a moment."
        }
    }
}

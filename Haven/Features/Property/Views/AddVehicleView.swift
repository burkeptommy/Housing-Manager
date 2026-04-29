import SwiftUI
import PhotosUI

struct AddVehicleView: View {
    var onComplete: ((VehicleRow) -> Void)?
    @Environment(\.dismiss) private var dismiss

    // VIN lookup state
    @State private var vinInput = ""
    @State private var isLookingUp = false
    @State private var lookupError: String?
    @State private var lookupResult: VehicleLookupService.VehicleLookupResponse?
    @State private var showCamera = false
    @State private var showManualEntry = false

    // Form fields
    @State private var name = ""
    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var trim = ""
    @State private var color = ""
    @State private var vin = ""
    @State private var licensePlate = ""
    @State private var currentMileage = ""
    @State private var ownershipType = "owned"
    @State private var registrationExpiry = Date()
    @State private var hasRegistrationExpiry = false
    @State private var inspectionExpiry = Date()
    @State private var hasInspectionExpiry = false
    @State private var notes = ""

    // Relationships
    @State private var familyMembers: [FamilyMemberRow] = []
    @State private var selectedDriverId: UUID?
    @State private var contractors: [ContractorRow] = []
    @State private var selectedMechanicId: UUID?

    // Save state
    @State private var isSaving = false
    @State private var recallsToSave: [VehicleLookupService.DecodedRecall] = []
    @State private var maintenanceSchedule: [VehicleMaintenanceInterval] = []

    private let db = DatabaseService.shared
    private let ownershipTypes = ["owned", "leased", "financed"]

    var body: some View {
        NavigationStack {
            Group {
                if !showManualEntry && lookupResult == nil {
                    vinEntryView
                } else {
                    vehicleForm
                }
            }
            .navigationTitle(lookupResult != nil ? "Review Vehicle" : "Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if showManualEntry || lookupResult != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { Task { await save() } }
                            .disabled(name.isEmpty || isSaving)
                    }
                }
            }
            .task {
                familyMembers = (try? await db.fetchFamilyMembers()) ?? []
                contractors = (try? await db.fetchContractors()) ?? []
            }
            .fullScreenCover(isPresented: $showCamera) {
                VINScannerView { imageBase64 in
                    Task { await lookupVIN(imageBase64: imageBase64) }
                }
            }
        }
    }

    // MARK: - VIN Entry

    private var vinEntryView: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing24) {
                VStack(spacing: HavenTheme.spacing8) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Add a Vehicle")
                        .font(HavenTypography.title)
                    Text("Scan or enter your VIN to auto-fill vehicle details, check for recalls, and generate a maintenance schedule.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 32)

                VStack(spacing: 12) {
                    Button {
                        Haptics.light()
                        showCamera = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundStyle(HavenColors.textPrimary)
                                .frame(width: 48, height: 48)
                                .background(HavenColors.navy.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scan VIN")
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("Take a photo of your VIN plate")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding()
                        .background(HavenColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                        .havenShadow()
                    }
                    .buttonStyle(.plain)

                    HavenCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Enter VIN")
                                .font(HavenTypography.headline)
                            TextField("17-character VIN", text: $vinInput)
                                .font(HavenTypography.body)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(12)
                                .background(HavenColors.beige200)
                                .cornerRadius(HavenTheme.radiusMedium)
                            HavenButton(
                                title: isLookingUp ? "Looking up..." : "Decode VIN",
                                action: { Task { await lookupVIN(vin: vinInput) } },
                                isLoading: isLookingUp,
                                isDisabled: vinInput.count != 17 || isLookingUp
                            )
                        }
                    }
                }
                .padding(.horizontal)

                if let error = lookupError {
                    Text(error)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.critical)
                        .padding(.horizontal)
                }

                Button {
                    showManualEntry = true
                } label: {
                    Text("Add Manually")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy700)
                }
                .padding(.top, 8)
            }
        }
        .background(HavenColors.background)
    }

    // MARK: - Vehicle Form

    private var vehicleForm: some View {
        Form {
            if let result = lookupResult, let recallCount = result.recallCount, recallCount > 0 {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HavenColors.warning)
                        Text("\(recallCount) Open Recall\(recallCount == 1 ? "" : "s")")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }
            }

            Section("Vehicle Details") {
                TextField("Name (e.g., Tom's Q5)", text: $name)
                TextField("Year", text: $year)
                    .keyboardType(.numberPad)
                TextField("Make", text: $make)
                TextField("Model", text: $model)
                TextField("Trim", text: $trim)
                TextField("Color", text: $color)
                TextField("VIN", text: $vin)
                    .textInputAutocapitalization(.characters)
                TextField("License Plate", text: $licensePlate)
                    .textInputAutocapitalization(.characters)
            }

            Section("Status") {
                TextField("Current Mileage", text: $currentMileage)
                    .keyboardType(.numberPad)
                Picker("Ownership", selection: $ownershipType) {
                    ForEach(ownershipTypes, id: \.self) { type in
                        Text(type.capitalized).tag(type)
                    }
                }
            }

            Section("Key Dates") {
                Toggle("Registration Expiry", isOn: $hasRegistrationExpiry)
                if hasRegistrationExpiry {
                    DatePicker("Expires", selection: $registrationExpiry, displayedComponents: .date)
                }
                Toggle("Inspection Expiry", isOn: $hasInspectionExpiry)
                if hasInspectionExpiry {
                    DatePicker("Expires", selection: $inspectionExpiry, displayedComponents: .date)
                }
            }

            Section("People") {
                Picker("Primary Driver", selection: $selectedDriverId) {
                    Text("None").tag(nil as UUID?)
                    ForEach(familyMembers) { member in
                        Text("\(member.firstName) \(member.lastName)").tag(member.id as UUID?)
                    }
                }
                Picker("Preferred Mechanic", selection: $selectedMechanicId) {
                    Text("None").tag(nil as UUID?)
                    ForEach(contractors) { contractor in
                        Text(contractor.companyName).tag(contractor.id as UUID?)
                    }
                }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 60)
            }
        }
        .scrollContentBackground(.hidden)
        .background(HavenColors.background)
    }

    // MARK: - VIN Lookup

    private func lookupVIN(vin: String? = nil, imageBase64: String? = nil) async {
        isLookingUp = true
        lookupError = nil

        do {
            let response: VehicleLookupService.VehicleLookupResponse
            if let imageBase64 {
                response = try await VehicleLookupService.shared.lookup(imageBase64: imageBase64)
            } else if let vin {
                response = try await VehicleLookupService.shared.lookup(vin: vin)
            } else { return }

            lookupResult = response

            if let v = response.vehicle {
                year = v.year.map { String($0) } ?? ""
                make = v.make ?? ""
                model = v.model ?? ""
                trim = v.trim ?? ""
                self.vin = v.vin ?? vinInput
                name = [v.make, v.model].compactMap { $0 }.joined(separator: " ")
                if name.isEmpty { name = "My Vehicle" }
            }
            recallsToSave = response.recalls ?? []
            maintenanceSchedule = response.maintenanceSchedule ?? []
        } catch {
            lookupError = error.localizedDescription
        }

        isLookingUp = false
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else { return }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            var insert = VehicleInsert(
                householdId: householdId,
                name: name
            )
            insert.year = Int(year)
            insert.make = make.isEmpty ? nil : make
            insert.model = model.isEmpty ? nil : model
            insert.trim = trim.isEmpty ? nil : trim
            insert.color = color.isEmpty ? nil : color
            insert.vin = vin.isEmpty ? nil : vin
            insert.licensePlate = licensePlate.isEmpty ? nil : licensePlate
            insert.currentMileage = Int(currentMileage)
            insert.ownershipType = ownershipType
            insert.registrationExpiry = hasRegistrationExpiry ? dateFormatter.string(from: registrationExpiry) : nil
            insert.inspectionExpiry = hasInspectionExpiry ? dateFormatter.string(from: inspectionExpiry) : nil
            insert.primaryDriverId = selectedDriverId
            insert.preferredMechanicId = selectedMechanicId
            insert.maintenanceSchedule = maintenanceSchedule.isEmpty ? nil : maintenanceSchedule
            insert.notes = notes.isEmpty ? nil : notes

            let vehicle = try await db.createVehicle(insert)

            // Save recalls
            for recall in recallsToSave {
                _ = try? await db.createVehicleRecall(VehicleRecallInsert(
                    vehicleId: vehicle.id,
                    householdId: householdId,
                    nhtsaCampaignNumber: recall.nhtsaCampaignNumber,
                    component: recall.component,
                    summary: recall.summary,
                    consequence: recall.consequence,
                    remedy: recall.remedy,
                    recallDate: recall.reportDate
                ))
            }

            // Create maintenance tasks from AI-generated schedule
            let taskDateFormatter = DateFormatter()
            taskDateFormatter.dateFormat = "yyyy-MM-dd"
            for interval in maintenanceSchedule {
                guard interval.intervalMiles != nil || interval.intervalMonths != nil else { continue }
                let monthsOut = interval.intervalMonths ?? 12
                let nextDue = Calendar.current.date(byAdding: .month, value: monthsOut, to: Date()) ?? Date()
                _ = try? await db.createMaintenanceTask(MaintenanceTaskInsert(
                    vehicleId: vehicle.id,
                    householdId: householdId,
                    title: interval.type.replacingOccurrences(of: "_", with: " ").capitalized,
                    frequency: interval.intervalMonths.map { "Every \($0) months" } ?? (interval.intervalMiles.map { "Every \($0.formatted()) miles" } ?? "As needed"),
                    nextDueDate: taskDateFormatter.string(from: nextDue),
                    description: interval.description,
                    estimatedCost: interval.estimatedCost,
                    priority: "medium",
                    templateId: interval.type
                ))
            }
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)

            Analytics.track(.vehicleCreated, [
                "has_vin": !vin.isEmpty,
                "recall_count": recallsToSave.count,
                "maintenance_items": maintenanceSchedule.count
            ])
            Haptics.success()
            onComplete?(vehicle)
            dismiss()
        } catch {
            lookupError = error.localizedDescription
            Haptics.error()
        }
    }
}

// MARK: - VIN Scanner (Camera)

struct VINScannerView: UIViewControllerRepresentable {
    let onCapture: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VINScannerView
        init(_ parent: VINScannerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                let base64 = data.base64EncodedString()
                parent.onCapture(base64)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

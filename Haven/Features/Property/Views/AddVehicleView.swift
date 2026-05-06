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

    // Phase 95 — optional vehicle photo. Captured at create time so the
    // brand hero on VehicleDetailView has imagery as soon as the row
    // saves. Uploaded post-create so the path can include vehicle.id.
    @State private var photoItem: PhotosPickerItem?
    @State private var photoImage: UIImage?

    // Phase 95 (gap #91) — EV-specific fields. The toggle gates whether
    // the battery + connector inputs render; ICE / hybrid / unsure flows
    // see neither so the form stays compact for the common case. Unsure
    // = leave the toggle off; we'll persist nil.
    @State private var isEv = false
    @State private var batteryCapacityKwhInput = ""
    @State private var chargerType = "tesla"
    private let chargerTypes = ["tesla", "nacs", "ccs", "j1772", "chademo"]

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

            Section("Photo") {
                HStack(spacing: 12) {
                    if let photoImage {
                        Image(uiImage: photoImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(HavenColors.beige200)
                                .frame(width: 64, height: 48)
                            Image(systemName: "car.side.fill")
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                        Text(photoImage == nil ? "Add a photo" : "Change photo")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.action)
                    }

                    Spacer()

                    if photoImage != nil {
                        Button {
                            photoItem = nil
                            photoImage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
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

            // Phase 95 (gap #91) — EV section. Toggle defaults off for
            // the ICE/hybrid common case; flipping on reveals battery
            // capacity + connector type so the rest of the app can
            // skip ICE-only maintenance templates and surface the
            // charger compatibility check on properties with
            // `has_ev_charger`.
            Section {
                Toggle("Electric vehicle", isOn: $isEv)
                if isEv {
                    HStack {
                        Text("Battery (kWh)")
                        Spacer()
                        TextField("e.g. 75", text: $batteryCapacityKwhInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Connector", selection: $chargerType) {
                        Text("Tesla / NACS").tag("tesla")
                        Text("CCS").tag("ccs")
                        Text("J1772").tag("j1772")
                        Text("CHAdeMO").tag("chademo")
                    }
                }
            } header: {
                Text("Powertrain")
            } footer: {
                if isEv {
                    Text("We'll skip oil changes and other ICE-only items from your maintenance schedule.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
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
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let item = newItem,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    photoImage = nil
                    return
                }
                photoImage = image
            }
        }
    }

    /// Phase 95 (gap #91) — interval types that don't apply to
    /// fully-electric vehicles. EVs have no engine oil, transmission
    /// fluid (single-speed reduction gearbox), spark plugs, fuel
    /// filter, or timing belt. Brake fluid, coolant (battery loop),
    /// tire rotation, and cabin air filter still apply, so we keep
    /// those.
    private static let iceOnlyIntervalTypes: Set<String> = [
        "oil_change",
        "transmission_fluid",
        "transmission_flush",
        "differential_fluid",
        "fuel_filter",
        "spark_plugs",
        "timing_belt",
        "engine_air_filter",
    ]

    private static func isIceOnlyIntervalType(_ type: String) -> Bool {
        iceOnlyIntervalTypes.contains(type.lowercased())
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
            // Phase 95 (gap #76) — license-plate carry-through from the
            // vision pass. Pre-fill the plate field whenever the edge
            // function captured one, but only when the user hasn't
            // already typed one to avoid clobbering manual input.
            if let scannedPlate = response.plate, licensePlate.isEmpty {
                licensePlate = scannedPlate
            }
            recallsToSave = response.recalls ?? []
            maintenanceSchedule = response.maintenanceSchedule ?? []
            // Plate-only scan: surface a friendly hint so the user knows
            // why the make/model fields didn't populate. Without this,
            // the picker silently lands on the manual-entry form with no
            // explanation when only the plate was visible.
            if response.vinDecoded == false, response.plate != nil {
                lookupError = "Got the plate. Type the VIN to pull year/make/model from NHTSA."
            }
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
            // Phase 95 (gap #91) — only persist EV signals when the
            // toggle is on. Off means "ICE / hybrid / not sure" and
            // we leave the columns null so the regional EV gate fails
            // closed rather than mis-classifying ICE vehicles.
            if isEv {
                insert.isEv = true
                insert.batteryCapacityKwh = Double(batteryCapacityKwhInput.trimmingCharacters(in: .whitespaces))
                insert.chargerType = chargerType
            }

            let vehicle = try await db.createVehicle(insert)

            // Phase 95 — upload optional vehicle photo. Fire-and-forget;
            // if the upload fails the vehicle row still saves with no
            // photo and the brand-color gradient covers the hero. The
            // upload service writes `photo_url` back to the row on success.
            if let photoImage {
                _ = try? await AvatarPhotoService.shared.uploadVehiclePhoto(
                    image: photoImage,
                    vehicleId: vehicle.id,
                    householdId: householdId
                )
            }

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

            // Create maintenance tasks from AI-generated schedule.
            //
            // Due-date math (Phase 95 / audit gap #77): months interval wins
            // when present. Otherwise we convert the mileage interval to a
            // days estimate using the user's current mileage as the
            // baseline and ~33 mi/day (12K mi/year) as the average driving
            // rate. Without this, a "every 5,000 miles" task with no
            // months interval would silently land 12 months out — wrong
            // for both heavy and light drivers. The MileageUpdateSheet
            // also re-runs this math via VehicleMileageScheduler whenever
            // the odometer changes.
            let taskDateFormatter = DateFormatter()
            taskDateFormatter.dateFormat = "yyyy-MM-dd"
            taskDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            taskDateFormatter.timeZone = TimeZone(identifier: "UTC")
            for interval in maintenanceSchedule {
                guard interval.intervalMiles != nil || interval.intervalMonths != nil else { continue }
                // Phase 95 (gap #91) — drop ICE-only intervals for
                // electric vehicles. The AI schedule emits these by
                // default whether or not the vehicle is electric;
                // without this filter an EV homeowner sees "Oil change"
                // and "Transmission flush" tasks they can't action.
                if isEv && Self.isIceOnlyIntervalType(interval.type) {
                    continue
                }
                let nextDue: Date
                if let months = interval.intervalMonths {
                    nextDue = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
                } else if let intervalMiles = interval.intervalMiles, intervalMiles > 0 {
                    let daysOut = max(0, Int(ceil(Double(intervalMiles) / 33.0)))
                    nextDue = Calendar.current.date(byAdding: .day, value: daysOut, to: Date()) ?? Date()
                } else {
                    nextDue = Date()
                }
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
            // Phase 95 audit fix — fresh vehicles need to surface in the
            // Garage strip + Maintenance hub Vehicles section without
            // forcing a tab switch / app restart.
            NotificationCenter.default.post(
                name: .vehicleChanged,
                object: nil,
                userInfo: ["vehicle_id": vehicle.id.uuidString]
            )

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

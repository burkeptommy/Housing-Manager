import SwiftUI

struct AddSystemView: View {
    let propertyID: UUID
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "HVAC"
    @State private var manufacturer = ""
    @State private var modelNumber = ""
    @State private var serialNumber = ""
    @State private var installDate = Date()
    @State private var hasInstallDate = false
    @State private var expectedLifespan = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var error: String?
    @State private var addMaintenanceTemplates = true

    // Warranty fields
    @State private var addWarranty = false
    @State private var warrantyProvider = ""
    @State private var warrantyType: WarrantyType = .manufacturer
    @State private var warrantyStartDate = Date()
    @State private var warrantyEndDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var warrantyCoverage = ""
    @State private var warrantyClaimPhone = ""
    @State private var warrantyPolicyNumber = ""

    private let categories = SystemCategory.allCases.map(\.rawValue)

    var body: some View {
        NavigationStack {
            Form {
                Section("System Info") {
                    TextField("Name (e.g. Main HVAC Unit)", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section("Details") {
                    TextField("Manufacturer", text: $manufacturer)
                    TextField("Model Number", text: $modelNumber)
                    TextField("Serial Number", text: $serialNumber)
                }

                Section("Installation") {
                    Toggle("Has Install Date", isOn: $hasInstallDate)
                        .tint(HavenColors.navy800)
                    if hasInstallDate {
                        DatePicker("Install Date", selection: $installDate, displayedComponents: .date)
                    }
                    TextField("Expected Lifespan (years)", text: $expectedLifespan)
                        .keyboardType(.numberPad)
                }

                Section {
                    Toggle("Add Maintenance Templates", isOn: $addMaintenanceTemplates)
                        .tint(HavenColors.navy800)
                } footer: {
                    Text("Automatically create maintenance tasks based on the system category.")
                }

                Section {
                    Toggle("Add Warranty", isOn: $addWarranty.animation())
                        .tint(HavenColors.navy800)
                } footer: {
                    Text("Track warranty coverage, expiration, and claim information.")
                }

                if addWarranty {
                    Section("Warranty Details") {
                        TextField("Provider Name", text: $warrantyProvider)
                        Picker("Warranty Type", selection: $warrantyType) {
                            ForEach([WarrantyType.manufacturer, .extended, .homeWarranty, .laborWarranty], id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        DatePicker("Start Date", selection: $warrantyStartDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $warrantyEndDate, displayedComponents: .date)
                    }

                    Section("Warranty Contact & Coverage") {
                        TextField("Claim Phone", text: $warrantyClaimPhone)
                            .keyboardType(.phonePad)
                        TextField("Policy Number", text: $warrantyPolicyNumber)
                        TextEditor(text: $warrantyCoverage)
                            .frame(minHeight: 60)
                            .overlay(alignment: .topLeading) {
                                if warrantyCoverage.isEmpty {
                                    Text("Coverage details...")
                                        .foregroundStyle(HavenColors.textTertiary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
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
            .navigationTitle("Add System")
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
            .tint(HavenColors.navy)
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                error = "No household found"
                isSaving = false
                return
            }

            let insert = HomeSystemInsert(
                propertyId: propertyID,
                householdId: householdId,
                name: name,
                category: category,
                manufacturer: manufacturer.isEmpty ? nil : manufacturer,
                modelNumber: modelNumber.isEmpty ? nil : modelNumber,
                serialNumber: serialNumber.isEmpty ? nil : serialNumber,
                installDate: hasInstallDate ? formatter.string(from: installDate) : nil,
                expectedLifespanYears: Int(expectedLifespan),
                status: "Good",
                notes: notes.isEmpty ? nil : notes
            )

            let system = try await DatabaseService.shared.createHomeSystem(insert)

            // Add warranty if specified
            if addWarranty && !warrantyProvider.isEmpty {
                let warrantyInsert = WarrantyInsert(
                    householdId: householdId,
                    provider: warrantyProvider,
                    warrantyType: warrantyType.rawValue,
                    startDate: formatter.string(from: warrantyStartDate),
                    endDate: formatter.string(from: warrantyEndDate),
                    systemId: system.id,
                    coverageDetails: warrantyCoverage.isEmpty ? nil : warrantyCoverage,
                    claimPhone: warrantyClaimPhone.isEmpty ? nil : warrantyClaimPhone,
                    policyNumber: warrantyPolicyNumber.isEmpty ? nil : warrantyPolicyNumber
                )
                _ = try await DatabaseService.shared.createWarranty(warrantyInsert)
            }

            // Add maintenance templates
            if addMaintenanceTemplates {
                let templates = MaintenanceTemplates.templates(for: category)
                for template in templates {
                    let nextDue = Calendar.current.date(byAdding: template.interval, to: .now)!
                    let taskInsert = MaintenanceTaskInsert(
                        propertyId: propertyID,
                        householdId: householdId,
                        title: template.title,
                        frequency: template.frequency,
                        nextDueDate: formatter.string(from: nextDue),
                        systemId: system.id,
                        description: template.description,
                        priority: template.priority,
                        isTemplateBased: true,
                        templateId: template.systemCategory + ":" + template.title,
                        seasonalTiming: template.seasonalTiming,
                        isDiy: template.isDIY,
                        professionalRequired: template.professionalRequired,
                        costRange: template.estimatedCostRange,
                        recurrenceRule: template.frequency
                    )
                    _ = try await DatabaseService.shared.createMaintenanceTask(taskInsert)
                }
            }

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

// MARK: - Maintenance Templates

// MaintenanceTemplates enum is defined in Haven/Features/Property/Services/MaintenanceTemplates.swift

#Preview {
    AddSystemView(propertyID: UUID())
}

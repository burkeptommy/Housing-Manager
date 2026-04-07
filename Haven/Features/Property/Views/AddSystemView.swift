import SwiftUI

struct AddSystemView: View {
    let propertyID: UUID
    var onComplete: ((HomeSystemRow) -> Void)?
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
    @State private var showEquipmentSearch = false
    @State private var catalogEntryId: UUID?
    @State private var selectedCatalogResult: EquipmentSearchResult?
    @State private var subtype: String? = nil
    @State private var customCategoryName: String = ""

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
                    SystemSubtypePicker(category: category, subtype: $subtype)
                    if category == "Other" {
                        TextField("Custom category name (e.g. Wine Cellar Cooling)", text: $customCategoryName)
                    }
                }

                Section {
                    Button {
                        Haptics.light()
                        showEquipmentSearch = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkle.magnifyingglass")
                                .foregroundStyle(HavenColors.navy700)
                            Text("Find in Equipment Catalog")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy700)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                } footer: {
                    Text("Search by brand or product type to auto-fill details, or enter manually below.")
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
            .trackScreen("AddSystemView", properties: ["property_id": propertyID.uuidString])
            .sheet(isPresented: $showEquipmentSearch) {
                EquipmentIdentifySheet(systemCategory: category) { result, detectedSerial in
                    // Pre-fill from catalog selection
                    catalogEntryId = result.id
                    name = result.displayName
                    manufacturer = result.manufacturer.name
                    modelNumber = result.modelNumber
                    if let serial = detectedSerial { serialNumber = serial }
                    if let lifespan = result.specs.expectedLifespanYears {
                        expectedLifespan = "\(lifespan)"
                    }
                    // Cache catalog enrichment data for the selected result
                    selectedCatalogResult = result
                    // Map catalog category to our SystemCategory
                    if let catName = SystemCategory.allCases.first(where: { $0.rawValue.lowercased().contains(result.category.name.lowercased()) })?.rawValue {
                        category = catName
                    }
                }
            }
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

            var insert = HomeSystemInsert(
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
            insert.catalogEntryId = catalogEntryId
            insert.subtype = subtype
            if category == "Other" {
                let trimmed = customCategoryName.trimmingCharacters(in: .whitespaces)
                insert.customCategoryName = trimmed.isEmpty ? nil : trimmed
            }

            let system = try await DatabaseService.shared.createHomeSystem(insert)

            // Cache catalog enrichment data so it's instant on next load
            if let result = selectedCatalogResult {
                _ = try? await DatabaseService.shared.updateHomeSystem(
                    id: system.id,
                    HomeSystemUpdate(
                        catalogSeries: result.specs.series,
                        catalogModelName: result.modelName ?? result.displayName,
                        catalogFeatures: result.specs.keyFeatures,
                        reliabilityScore: result.scores?.reliability,
                        scoreSummary: result.scores?.summary,
                        catalogFuelType: result.specs.fuelType,
                        catalogEnrichedAt: Date()
                    )
                )
            }

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
                let activeSubs = MaintenanceTemplates.activeSubtypes(
                    category: category,
                    subtype: subtype,
                    fuelType: selectedCatalogResult?.specs.fuelType
                )
                let templates = MaintenanceTemplates.templates(for: category, activeSubtypes: activeSubs)
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

            // Migrate equipment-specific tasks from parent to this new child system
            if let parentId = insert.parentSystemId {
                let parentTasks = (try? await DatabaseService.shared.fetchMaintenanceTasks(systemId: parentId)) ?? []
                let systemNameLower = name.lowercased()
                let kwMatch: (String, String) -> Bool = { n, kw in
                    let lower = kw.lowercased()
                    if lower.contains(" ") { return n.contains(lower) }
                    return Set(n.components(separatedBy: CharacterSet.alphanumerics.inverted)).contains(lower)
                }
                let allTemplates = MaintenanceTemplates.allTemplates.flatMap(\.1)
                let matchingTemplateIds = Set(allTemplates
                    .filter { t in !t.equipmentKeywords.isEmpty && t.equipmentKeywords.contains { kwMatch(systemNameLower, $0) } }
                    .map { $0.systemCategory + ":" + $0.title })
                for task in parentTasks {
                    if let templateId = task.templateId, matchingTemplateIds.contains(templateId) {
                        _ = try? await DatabaseService.shared.updateMaintenanceTask(id: task.id, MaintenanceTaskUpdate(systemId: system.id))
                    }
                }
            }

            Haptics.success()
            Analytics.track(.systemCreated, ["category": category, "system_id": system.id.uuidString, "has_warranty": addWarranty])
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil,
                userInfo: ["action": "created", "id": system.id.uuidString])
            onComplete?(system)
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

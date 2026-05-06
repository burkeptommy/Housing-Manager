import SwiftUI

struct AddSystemView: View {
    let propertyID: UUID
    /// Phase 95 (gap #40) — when set, the form opens with this
    /// category preselected. Used by `RecommendedSystemsView` so a
    /// user tapping "Pool" lands on the form already on the right
    /// category instead of needing to pick from the dropdown.
    var prefilledCategory: String? = nil
    var onComplete: ((HomeSystemRow) -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: String
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

    // Standing appointment prompt (after vendor match)
    @State private var showRecurringPrompt = false
    @State private var showVendorInfoNote = false
    @State private var matchedContractorName: String?
    @State private var matchedContractor: ContractorRow?
    @State private var createdSystemForRecurring: HomeSystemRow?
    @State private var showRecurringServiceSheet = false

    // Warranty fields
    @State private var addWarranty = false
    @State private var warrantyProvider = ""
    @State private var warrantyType: WarrantyType = .manufacturer
    @State private var warrantyStartDate = Date()
    @State private var warrantyEndDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var warrantyCoverage = ""
    @State private var warrantyClaimPhone = ""
    @State private var warrantyPolicyNumber = ""

    init(
        propertyID: UUID,
        prefilledCategory: String? = nil,
        onComplete: ((HomeSystemRow) -> Void)? = nil
    ) {
        self.propertyID = propertyID
        self.prefilledCategory = prefilledCategory
        self.onComplete = onComplete
        // Phase 95 (gap #40) — open the picker on the prefilled
        // category when one was passed, otherwise keep the legacy
        // "HVAC" default so the standalone "+ Add System" entry
        // opens unchanged.
        self._category = State(initialValue: prefilledCategory ?? "HVAC")
    }

    /// Alphabetized for the picker, with "Other" pinned to the bottom as the
    /// catch-all so it never lands between real categories. The default
    /// `category` state is still "HVAC" so the picker opens with HVAC selected.
    private let categories: [String] = {
        let raw = SystemCategory.allCases.map(\.rawValue)
        let sorted = raw.filter { $0 != "Other" }.sorted()
        return sorted + ["Other"]
    }()

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
                    // See EditSystemSheet for the rationale — the legacy
                    // "Has Install Date" toggle was easy to miss. The
                    // value sits next to the toggle so the user can read
                    // current state at a glance, and the picker is
                    // graphical (always visible when on).
                    Toggle(isOn: $hasInstallDate.animation()) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Install date")
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(hasInstallDate
                                ? addSystemDisplayDateFormatter.string(from: installDate)
                                : "Add the install date")
                                .font(HavenTypography.caption)
                                .foregroundStyle(hasInstallDate
                                    ? HavenColors.textSecondary
                                    : HavenColors.textTertiary)
                        }
                    }
                    .tint(HavenColors.navy800)
                    if hasInstallDate {
                        DatePicker(
                            "Pick a date",
                            selection: $installDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
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
                    // Build 94: Stamp the catalog category as the system
                    // subtype so "Refrigerator" / "Dishwasher" / "Wall
                    // Oven" survive on the list + detail surfaces. Before
                    // this the subtype stayed nil for photo/catalog adds
                    // and the list row fell back to the parent category
                    // ("Appliance"), leaving the user no way to tell a
                    // fridge from an oven at a glance.
                    let trimmedCategory = result.category.name.trimmingCharacters(in: .whitespaces)
                    if !trimmedCategory.isEmpty {
                        subtype = trimmedCategory
                    }
                    // Map catalog category to our SystemCategory
                    if let catName = SystemCategory.allCases.first(where: { $0.rawValue.lowercased().contains(result.category.name.lowercased()) })?.rawValue {
                        category = catName
                    }
                }
            }
            .confirmationDialog(
                "\(matchedContractorName ?? "Your vendor") handles this",
                isPresented: $showRecurringPrompt,
                titleVisibility: .visible
            ) {
                Button("Set up recurring visits") {
                    showRecurringServiceSheet = true
                }
                Button("Not now", role: .cancel) {
                    completeAndDismiss()
                }
            } message: {
                Text("Want to set up recurring visits so you can track when they come?")
            }
            .alert(
                "\(matchedContractorName ?? "Your vendor") is linked",
                isPresented: $showVendorInfoNote
            ) {
                Button("Got it") {
                    completeAndDismiss()
                }
            } message: {
                Text("They already manage visits for your \(category). The new system's tasks are assigned to them.")
            }
            .sheet(isPresented: $showRecurringServiceSheet) {
                if let system = createdSystemForRecurring {
                    AddRecurringServiceSheet(
                        propertyId: propertyID,
                        householdId: system.householdId,
                        preselectedSystem: system,
                        preselectedContractor: matchedContractor,
                        onComplete: {
                            completeAndDismiss()
                        }
                    )
                }
            }
        }
    }

    /// Stable formatter for the persisted ISO date string (`yyyy-MM-dd`).
    /// Locked to `en_US_POSIX` + UTC so the persisted value never shifts
    /// based on the user's locale or time zone — Postgres expects ISO.
    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    /// Locale-aware display formatter — used for the row label so the
    /// chosen date reads naturally to the user.
    fileprivate var addSystemDisplayDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    private func save() async {
        isSaving = true
        error = nil
        let formatter = Self.isoDateFormatter
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

            // Route through the reconciler so tasks get proper vendor
            // matching, bundle grouping, and preference tier resolution.
            // This matches the pattern used by EditSystemSheet (line 285)
            // and the quiz path (HouseQuizAnswerMapper).
            if addMaintenanceTemplates {
                let result = await MaintenanceTaskReconciler.reconcile(
                    propertyId: propertyID,
                    householdId: householdId,
                    systemId: system.id,
                    systemCategory: category,
                    confirmedSubtype: subtype,
                    fuelType: selectedCatalogResult?.specs.fuelType
                )
                // Phase 95 audit fix — always post the notification when
                // the user opted into templates, even if the reconciler
                // returned 0 changes. Without this, a system add where
                // every template was already covered (dedupe hit) skipped
                // the post and downstream surfaces could miss adjacent
                // updates (e.g. the system row itself appearing).
                NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                if result.totalChanged == 0 {
                    print("[AddSystem] Reconciler returned 0 changes for \(category) — already covered or no matching templates.")
                }

                // Check if the reconciler linked a vendor — if so, offer
                // to set up recurring visits (standing appointment).
                let newTasks = (try? await DatabaseService.shared.fetchMaintenanceTasks(systemId: system.id)) ?? []
                if let vendorTask = newTasks.first(where: { $0.assignedContractorId != nil }),
                   let contractorId = vendorTask.assignedContractorId {
                    let appointments = (try? await DatabaseService.shared.fetchStandingAppointments(householdId: householdId)) ?? []
                    let hasCoverage = appointments.contains { $0.systemId == system.id && $0.archivedAt == nil }
                    let hasSameVendorAppointment = appointments.contains {
                        $0.vendorId == contractorId && $0.archivedAt == nil
                    }

                    if !hasCoverage {
                        let contractors = (try? await DatabaseService.shared.fetchContractors()) ?? []
                        let contractor = contractors.first { $0.id == contractorId }

                        if hasSameVendorAppointment {
                            // Part C: Same vendor already has visits on a different system
                            matchedContractorName = contractor?.companyName
                            showVendorInfoNote = true
                        } else {
                            // Part B: Offer to set up recurring visits
                            matchedContractorName = contractor?.companyName
                            matchedContractor = contractor
                            createdSystemForRecurring = system
                            showRecurringPrompt = true
                            return // Don't dismiss yet — wait for user response
                        }
                    }
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

    /// Finishes the save flow after the user responds to the recurring
    /// service prompt (or the info note). Posts notifications and dismisses.
    private func completeAndDismiss() {
        if let system = createdSystemForRecurring {
            Haptics.success()
            Analytics.track(.systemCreated, ["category": category, "system_id": system.id.uuidString, "has_warranty": addWarranty])
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil,
                userInfo: ["action": "created", "id": system.id.uuidString])
            onComplete?(system)
        }
        dismiss()
    }
}

// MARK: - Maintenance Templates

// MaintenanceTemplates enum is defined in Haven/Features/Property/Services/MaintenanceTemplates.swift

#Preview {
    AddSystemView(propertyID: UUID())
}

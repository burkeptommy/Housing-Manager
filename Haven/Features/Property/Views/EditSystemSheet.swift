import SwiftUI

struct EditSystemSheet: View {
    let system: HomeSystemRow
    var onComplete: ((HomeSystemRow) -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var category: String
    @State private var manufacturer: String
    @State private var modelNumber: String
    @State private var serialNumber: String
    @State private var installDate: Date
    @State private var hasInstallDate: Bool
    @State private var expectedLifespan: String
    @State private var status: String
    @State private var notes: String
    @State private var catalogEntryId: UUID?
    @State private var subtype: String?
    @State private var customCategoryName: String
    @State private var isSaving = false
    @State private var error: String?
    @State private var showEquipmentSearch = false
    @State private var pendingOrphanTaskIds: [UUID] = []
    @State private var pendingOrphanTitles: [String] = []
    @State private var showOrphanConfirm = false

    private let categories = SystemCategory.allCases.map(\.rawValue)
    private let statuses = ["Good", "Needs Maintenance", "Needs Repair", "Replace Soon"]

    private let db = DatabaseService.shared
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init(system: HomeSystemRow, onComplete: ((HomeSystemRow) -> Void)? = nil) {
        self.system = system
        self.onComplete = onComplete
        _name = State(initialValue: system.name)
        _category = State(initialValue: system.category)
        _manufacturer = State(initialValue: system.manufacturer ?? "")
        _modelNumber = State(initialValue: system.modelNumber ?? "")
        _serialNumber = State(initialValue: system.serialNumber ?? "")
        _notes = State(initialValue: system.notes ?? "")
        _status = State(initialValue: system.status ?? "Good")
        _expectedLifespan = State(initialValue: system.expectedLifespanYears.map { "\($0)" } ?? "")
        _catalogEntryId = State(initialValue: system.catalogEntryId)
        _subtype = State(initialValue: system.subtype)
        _customCategoryName = State(initialValue: system.customCategoryName ?? "")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let dateStr = system.installDate, let date = formatter.date(from: dateStr) {
            _installDate = State(initialValue: date)
            _hasInstallDate = State(initialValue: true)
        } else {
            _installDate = State(initialValue: Date())
            _hasInstallDate = State(initialValue: false)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Equipment catalog search
                Section {
                    Button {
                        Haptics.light()
                        showEquipmentSearch = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkle.magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundStyle(HavenColors.navy700)
                            Text("Find in Equipment Catalog")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy800)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }

                Section("System Info") {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(statuses, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    SystemSubtypePicker(category: category, subtype: $subtype)
                    if category == "Other" {
                        TextField("Custom category name", text: $customCategoryName)
                    }
                }

                Section("Details") {
                    TextField("Manufacturer", text: $manufacturer)
                    TextField("Model Number", text: $modelNumber)
                    TextField("Serial Number", text: $serialNumber)
                }

                Section("Installation") {
                    Toggle("Has Install Date", isOn: $hasInstallDate)
                    if hasInstallDate {
                        DatePicker("Install Date", selection: $installDate, displayedComponents: .date)
                    }
                    TextField("Expected Lifespan (years)", text: $expectedLifespan)
                        .keyboardType(.numberPad)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(HavenTypography.bodySmall)
                    }
                }
            }
            .navigationTitle("Edit System")
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
            .confirmationDialog(
                pendingOrphanTitles.isEmpty
                    ? "Subtype changed"
                    : "Remove \(pendingOrphanTitles.count) task\(pendingOrphanTitles.count == 1 ? "" : "s") that no longer apply?",
                isPresented: $showOrphanConfirm,
                titleVisibility: .visible
            ) {
                Button("Remove tasks", role: .destructive) {
                    Task { await commitSave(deleteOrphanIds: pendingOrphanTaskIds) }
                }
                Button("Keep tasks") {
                    Task { await commitSave(deleteOrphanIds: []) }
                }
                Button("Cancel", role: .cancel) {
                    isSaving = false
                }
            } message: {
                if !pendingOrphanTitles.isEmpty {
                    Text(pendingOrphanTitles.prefix(6).joined(separator: "\n"))
                }
            }
            .sheet(isPresented: $showEquipmentSearch) {
                EquipmentIdentifySheet(systemCategory: category) { result, detectedSerial in
                    catalogEntryId = result.id
                    name = result.displayName
                    manufacturer = result.manufacturer.name
                    modelNumber = result.modelNumber
                    if let serial = detectedSerial { serialNumber = serial }
                    if let lifespan = result.specs.expectedLifespanYears {
                        expectedLifespan = "\(lifespan)"
                    }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        error = nil

        // If subtype changed, find template-based tasks that no longer match the new subtype
        // and ask the user whether to delete them.
        if subtype != system.subtype {
            let oldSubs = MaintenanceTemplates.activeSubtypes(category: system.category, subtype: system.subtype, fuelType: system.catalogFuelType)
            let newSubs = MaintenanceTemplates.activeSubtypes(category: category, subtype: subtype, fuelType: system.catalogFuelType)
            let removedTags = oldSubs.subtracting(newSubs)
            if !removedTags.isEmpty {
                let allTemplates = MaintenanceTemplates.allTemplates.flatMap(\.1)
                let nowOrphanedIds: Set<String> = Set(
                    allTemplates
                        .filter { !$0.requiredSubtypes.isEmpty && !$0.requiredSubtypes.isSubset(of: newSubs) }
                        .map { $0.systemCategory + ":" + $0.title }
                )
                let tasks = (try? await db.fetchMaintenanceTasks(systemId: system.id)) ?? []
                let orphans = tasks.filter { t in
                    guard let tid = t.templateId else { return false }
                    return nowOrphanedIds.contains(tid)
                }
                if !orphans.isEmpty {
                    pendingOrphanTaskIds = orphans.map(\.id)
                    pendingOrphanTitles = orphans.map(\.title)
                    showOrphanConfirm = true
                    return // wait for user choice
                }
            }
        }

        await commitSave(deleteOrphanIds: [])
    }

    private func commitSave(deleteOrphanIds: [UUID]) async {
        do {
            var updates = HomeSystemUpdate()
            updates.name = name
            updates.category = category
            updates.status = status
            updates.manufacturer = manufacturer.isEmpty ? nil : manufacturer
            updates.modelNumber = modelNumber.isEmpty ? nil : modelNumber
            updates.serialNumber = serialNumber.isEmpty ? nil : serialNumber
            updates.installDate = hasInstallDate ? dateFormatter.string(from: installDate) : nil
            updates.expectedLifespanYears = Int(expectedLifespan)
            updates.notes = notes.isEmpty ? nil : notes
            updates.catalogEntryId = catalogEntryId
            updates.subtype = subtype
            if category == "Other" {
                let trimmed = customCategoryName.trimmingCharacters(in: .whitespaces)
                updates.customCategoryName = trimmed.isEmpty ? nil : trimmed
            } else {
                updates.customCategoryName = nil
            }

            let updated = try await db.updateHomeSystem(id: system.id, updates)

            if !deleteOrphanIds.isEmpty {
                try? await db.deleteMaintenanceTasks(ids: deleteOrphanIds)
                NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            }

            await MainActor.run {
                Haptics.success()
                NotificationCenter.default.post(name: .homeSystemChanged, object: nil,
                    userInfo: ["action": "updated", "id": system.id.uuidString])
                onComplete?(updated)
                dismiss()
            }
        } catch {
            self.error = error.localizedDescription
            isSaving = false
        }
    }
}

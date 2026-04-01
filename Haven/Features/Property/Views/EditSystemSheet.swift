import SwiftUI

struct EditSystemSheet: View {
    let system: HomeSystemRow
    var onComplete: (() -> Void)?
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
    @State private var isSaving = false
    @State private var error: String?
    @State private var showEquipmentSearch = false

    private let categories = SystemCategory.allCases.map(\.rawValue)
    private let statuses = ["Good", "Needs Maintenance", "Needs Repair", "Replace Soon"]

    private let db = DatabaseService.shared
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init(system: HomeSystemRow, onComplete: (() -> Void)? = nil) {
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

            _ = try await db.updateHomeSystem(id: system.id, updates)
            await MainActor.run {
                Haptics.success()
                dismiss()
                // Delay to let dismiss animate, then refresh parent
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    onComplete?()
                }
            }
        } catch {
            self.error = error.localizedDescription
            isSaving = false
        }
    }
}

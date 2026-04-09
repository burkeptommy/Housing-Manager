import SwiftUI

/// Sheet for creating a custom maintenance task.
/// Supports assigning to a property OR vehicle, plus system, vendor, person, due date, frequency, priority, notes.
/// Saves optimistically -- the task appears in the list immediately while the DB write happens in the background.
struct AddMaintenanceTaskSheet: View {
    let properties: [PropertyRow]
    let systems: [HomeSystemRow]
    var vehicles: [VehicleRow] = []
    var contractors: [ContractorRow] = []
    var householdUsers: [UserRow] = []
    /// If provided, the new task is added optimistically through this view model.
    var viewModel: MaintenanceViewModel?
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    enum TargetType: String, CaseIterable, Identifiable {
        case property = "Property"
        case vehicle = "Vehicle"
        var id: String { rawValue }
    }

    @State private var title = ""
    @State private var targetType: TargetType = .property
    @State private var selectedPropertyId: UUID?
    @State private var selectedVehicleId: UUID?
    @State private var selectedSystemId: UUID?
    @State private var selectedContractorId: UUID?
    @State private var assignedUserId: UUID?
    @State private var frequency = "Annually"
    @State private var dueDate = Date()
    @State private var priority = "medium"
    @State private var notes = ""
    @State private var isSaving = false

    private let db = DatabaseService.shared

    private let frequencies = [
        "Once", "Monthly", "Quarterly", "Semi-Annually", "Annually",
        "Every 2 Years", "Every 5 Years", "Seasonal"
    ]

    private let priorities = ["low", "medium", "high", "urgent"]

    private var availableSystems: [HomeSystemRow] {
        guard let propId = selectedPropertyId else { return [] }
        return systems.filter { $0.propertyId == propId }
    }

    private var canSave: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespaces).isEmpty
        let hasTarget = (targetType == .property && selectedPropertyId != nil)
            || (targetType == .vehicle && selectedVehicleId != nil)
        return hasTitle && hasTarget && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task name", text: $title)

                    if !vehicles.isEmpty {
                        Picker("Type", selection: $targetType) {
                            ForEach(TargetType.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if targetType == .property {
                        if properties.count > 1 {
                            Picker("Property", selection: $selectedPropertyId) {
                                ForEach(properties) { p in
                                    Text(p.name).tag(p.id as UUID?)
                                }
                            }
                        }
                        if !availableSystems.isEmpty {
                            Picker("System", selection: $selectedSystemId) {
                                Text("None").tag(nil as UUID?)
                                ForEach(availableSystems) { s in
                                    Text(s.name).tag(s.id as UUID?)
                                }
                            }
                        }
                    } else {
                        Picker("Vehicle", selection: $selectedVehicleId) {
                            Text("Select").tag(nil as UUID?)
                            ForEach(vehicles) { v in
                                Text(v.displayName.isEmpty ? v.name : v.displayName).tag(v.id as UUID?)
                            }
                        }
                    }
                }

                Section("Schedule") {
                    // Build 86: no date-range constraint. Users can add a
                    // task with a past due date (overdue backfill) or any
                    // future date. Validation happens at save time, not
                    // on the picker.
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        .tint(HavenColors.navy800)

                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { f in
                            Text(f).tag(f)
                        }
                    }

                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { p in
                            Text(p.capitalized).tag(p)
                        }
                    }
                }

                if householdUsers.count > 0 {
                    Section("Assign To Person") {
                        Picker("Person", selection: $assignedUserId) {
                            Text("Unassigned").tag(nil as UUID?)
                            ForEach(householdUsers, id: \.id) { user in
                                Text(user.fullName?.components(separatedBy: " ").first ?? user.fullName ?? "Member")
                                    .tag(user.id as UUID?)
                            }
                        }
                    }
                }

                if !contractors.isEmpty {
                    Section("Assign Vendor") {
                        Picker("Vendor", selection: $selectedContractorId) {
                            Text("None").tag(nil as UUID?)
                            ForEach(contractors) { c in
                                Text(c.companyName).tag(c.id as UUID?)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.navy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await saveTask() }
                    }
                    .foregroundStyle(HavenColors.navy)
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .task {
                if selectedPropertyId == nil {
                    selectedPropertyId = properties.first?.id
                }
            }
        }
    }

    private func saveTask() async {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Determine household ID -- prefer one already loaded
        let householdId: UUID
        if let propId = selectedPropertyId, let prop = properties.first(where: { $0.id == propId }) {
            householdId = prop.householdId
        } else if let vid = selectedVehicleId, let veh = vehicles.first(where: { $0.id == vid }) {
            householdId = veh.householdId
        } else {
            do {
                let user = try await db.fetchCurrentUser()
                guard let hid = user.householdId else { return }
                householdId = hid
            } catch {
                return
            }
        }

        var insert = MaintenanceTaskInsert(
            householdId: householdId,
            title: trimmed,
            frequency: frequency.lowercased(),
            nextDueDate: formatter.string(from: dueDate)
        )
        if targetType == .property {
            insert.propertyId = selectedPropertyId
            insert.systemId = selectedSystemId
        } else {
            insert.vehicleId = selectedVehicleId
        }
        insert.priority = priority
        insert.assignedToUserId = assignedUserId
        insert.assignedContractorId = selectedContractorId
        insert.notes = notes.isEmpty ? nil : notes

        // Optimistic save through view model if available
        if let vm = viewModel {
            await vm.createTask(insert)
            onSave?()
            dismiss()
        } else {
            // Fallback: direct save
            isSaving = true
            do {
                _ = try await db.createMaintenanceTask(insert)
                Haptics.success()
                onSave?()
                dismiss()
            } catch {
                print("[AddTask] Failed to create task: \(error)")
                Haptics.error()
                isSaving = false
            }
        }
    }
}

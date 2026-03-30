import SwiftUI

struct AddMaintenanceTaskSheet: View {
    let properties: [PropertyRow]
    let systems: [HomeSystemRow]
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedPropertyId: UUID?
    @State private var selectedSystemId: UUID?
    @State private var frequency = "Annually"
    @State private var dueDate = Date()
    @State private var priority = "medium"
    @State private var notes = ""
    @State private var assignedUserId: UUID?
    @State private var householdUsers: [UserRow] = []
    @State private var isSaving = false

    private let db = DatabaseService.shared

    private let frequencies = [
        "Monthly", "Quarterly", "Semi-Annually", "Annually",
        "Every 2 Years", "Every 5 Years", "Seasonal"
    ]

    private let priorities = ["low", "medium", "high", "urgent"]

    private var availableSystems: [HomeSystemRow] {
        guard let propId = selectedPropertyId else { return systems }
        return systems.filter { $0.propertyId == propId }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task name", text: $title)

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
                }

                Section("Schedule") {
                    DatePicker("Due Date", selection: $dueDate, in: Date()..., displayedComponents: .date)
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

                if householdUsers.count > 1 {
                    Section("Assign To") {
                        Picker("Person", selection: $assignedUserId) {
                            Text("Unassigned").tag(nil as UUID?)
                            ForEach(householdUsers, id: \.id) { user in
                                Text(user.fullName?.components(separatedBy: " ").first ?? user.fullName ?? "Member")
                                    .tag(user.id as UUID?)
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
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .task {
                if selectedPropertyId == nil {
                    selectedPropertyId = properties.first?.id
                }
                householdUsers = (try? await db.fetchHouseholdUsers()) ?? []
            }
        }
    }

    private func saveTask() async {
        guard let propertyId = selectedPropertyId else { return }
        isSaving = true

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let householdId: UUID
        do {
            let user = try await db.fetchCurrentUser()
            guard let hid = user.householdId else {
                isSaving = false
                return
            }
            householdId = hid
        } catch {
            isSaving = false
            return
        }

        do {
            let task = try await db.createMaintenanceTask(MaintenanceTaskInsert(
                propertyId: propertyId,
                householdId: householdId,
                title: title.trimmingCharacters(in: .whitespaces),
                frequency: frequency.lowercased(),
                nextDueDate: formatter.string(from: dueDate),
                systemId: selectedSystemId,
                priority: priority,
                notes: notes.isEmpty ? nil : notes
            ))

            // Set assignment if a person was selected
            if let userId = assignedUserId {
                _ = try? await db.clearMaintenanceTaskAssignment(id: task.id, userId: userId)
            }

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

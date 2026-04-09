import SwiftUI

/// Multi-select task curation sheet for a single home system.
/// Lets the user trim the task list directly without going to the global maintenance view.
/// Phase 19 polish: also exposes an "Add custom task" path so users can create
/// system-specific tasks without leaving this sheet — critical for systems
/// where the template library doesn't cover their actual maintenance needs.
struct ManageSystemTasksSheet: View {
    let system: HomeSystemRow
    let initialTasks: [MaintenanceTaskDBRow]
    var onDelete: (([UUID]) async -> Void)
    var onTaskAdded: ((MaintenanceTaskDBRow) async -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<UUID> = []
    @State private var showAddCustomTask = false
    /// Phase 19 polish: locally-tracked task list so newly-created custom tasks
    /// appear immediately in the sheet without waiting for the parent view to
    /// refetch. Initialized from `initialTasks` and appended-to when the inline
    /// AddCustomSystemTaskSheet successfully creates a row. The parent view
    /// gets the same row via the `onTaskAdded` callback so its own state stays
    /// in sync.
    @State private var tasks: [MaintenanceTaskDBRow] = []

    init(
        system: HomeSystemRow,
        tasks: [MaintenanceTaskDBRow],
        onDelete: @escaping (([UUID]) async -> Void),
        onTaskAdded: ((MaintenanceTaskDBRow) async -> Void)? = nil
    ) {
        self.system = system
        self.initialTasks = tasks
        self.onDelete = onDelete
        self.onTaskAdded = onTaskAdded
        self._tasks = State(initialValue: tasks)
    }

    var body: some View {
        NavigationStack {
            List {
                if tasks.isEmpty {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        Text("No tasks for this system yet.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        Button {
                            Haptics.light()
                            showAddCustomTask = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("Add a custom task")
                                    .font(HavenTypography.uiButton)
                            }
                            .foregroundStyle(HavenColors.navy800)
                            .padding(.vertical, HavenTheme.spacing12)
                            .padding(.horizontal, HavenTheme.spacing16)
                            .background(HavenColors.beige200)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(tasks, id: \.id) { task in
                        Button {
                            if selected.contains(task.id) {
                                selected.remove(task.id)
                            } else {
                                selected.insert(task.id)
                            }
                            Haptics.selection()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selected.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(selected.contains(task.id) ? HavenColors.navy800 : HavenColors.textTertiary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    HStack(spacing: 6) {
                                        Text(task.frequency)
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                        if task.isTemplateBased == true {
                                            Text("Template")
                                                .font(HavenTypography.uiLabelSmall)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(HavenColors.beige200)
                                                .clipShape(Capsule())
                                                .foregroundStyle(HavenColors.navy700)
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                        .listRowBackground(HavenColors.creamLight)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HavenColors.cream)
            .navigationTitle("Manage Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: HavenTheme.spacing12) {
                        Button {
                            Haptics.light()
                            showAddCustomTask = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        if !tasks.isEmpty {
                            Button(selected.count == tasks.count ? "Clear" : "All") {
                                selected = selected.count == tasks.count ? [] : Set(tasks.map(\.id))
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !selected.isEmpty {
                    Button(role: .destructive) {
                        let ids = Array(selected)
                        Task {
                            await onDelete(ids)
                            dismiss()
                        }
                    } label: {
                        Text("Delete selected (\(selected.count))")
                            .font(HavenTypography.uiButton)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(HavenColors.critical)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.bottom, HavenTheme.spacing12)
                }
            }
            .sheet(isPresented: $showAddCustomTask) {
                AddCustomSystemTaskSheet(
                    system: system,
                    onCreated: { newTask in
                        // Append locally so the sheet renders the new task
                        // immediately without waiting for a parent refetch.
                        tasks.append(newTask)
                        if let onTaskAdded {
                            await onTaskAdded(newTask)
                        }
                        showAddCustomTask = false
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
}

/// Inline form for creating a one-off custom maintenance task tied to a
/// specific home system. Bypasses the template system entirely so users can
/// capture system-specific work that Haven's catalog doesn't cover (e.g.
/// "Refill water softener salt", "Inspect gutter guards on east wing").
private struct AddCustomSystemTaskSheet: View {
    let system: HomeSystemRow
    var onCreated: (MaintenanceTaskDBRow) async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var frequency: String = "Annually"
    @State private var priority: String = "Medium"
    @State private var notes: String = ""
    @State private var isDIY: Bool = true
    @State private var nextDueDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var isSaving: Bool = false
    @State private var error: String?

    private let frequencies = [
        "Weekly", "Monthly", "Every 2 months", "Quarterly",
        "Semi-annually", "Annually", "Every 2 years", "Every 3 years",
        "Every 5 years", "As needed"
    ]
    private let priorities = ["Low", "Medium", "High"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("What needs doing?", text: $title)
                        .autocorrectionDisabled(false)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { f in
                            Text(f).tag(f)
                        }
                    }
                    DatePicker("First due", selection: $nextDueDate, displayedComponents: .date)
                }

                Section("Details") {
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { p in
                            Text(p).tag(p)
                        }
                    }
                    Toggle("I'll do this myself", isOn: $isDIY)
                        .tint(HavenColors.navy800)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Anything we should remember about this task?")
                                    .foregroundStyle(HavenColors.textTertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
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
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .tint(HavenColors.navy)
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        defer { isSaving = false }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var insert = MaintenanceTaskInsert(
            householdId: system.householdId,
            title: trimmedTitle,
            frequency: frequency,
            nextDueDate: formatter.string(from: nextDueDate)
        )
        insert.propertyId = system.propertyId
        insert.systemId = system.id
        insert.priority = priority
        insert.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        insert.isTemplateBased = false
        insert.isDiy = isDIY
        insert.professionalRequired = !isDIY
        insert.assignmentType = isDIY ? "personal" : "vendor"
        insert.needsVendor = !isDIY

        do {
            let saved = try await DatabaseService.shared.createMaintenanceTask(insert)
            Haptics.success()
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            await onCreated(saved)
            dismiss()
        } catch {
            self.error = "Couldn't save the task. Try again."
            Haptics.error()
        }
    }
}

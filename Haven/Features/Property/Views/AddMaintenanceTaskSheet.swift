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
    /// Build 87 (Home Manager expansion): family_members rows for the
    /// current household, supplied by the parent (usually
    /// `MaintenanceScheduleView`) so the assignee picker can label home
    /// managers without re-fetching. Optional so existing call sites
    /// keep working unchanged — when nil, the picker falls back to the
    /// previous label-only render.
    var householdFamilyMembers: [FamilyMemberRow] = []
    /// If provided, the new task is added optimistically through this view model.
    var viewModel: MaintenanceViewModel?
    var onSave: (() -> Void)?
    /// Optional hub-driven presets so the sheet can open directly into
    /// the user's intended creation flow.
    var initialEntryMode: EntryMode? = nil
    var initialPropertyId: UUID? = nil
    var initialVehicleId: UUID? = nil

    @Environment(\.dismiss) private var dismiss

    enum TargetType: String, CaseIterable, Identifiable {
        case property = "Property"
        case vehicle = "Vehicle"
        var id: String { rawValue }
    }

    enum EntryMode: String, CaseIterable, Identifiable {
        case seasonalService = "Service"
        case routineProgram = "Routine"
        case handymanItem = "Handyman"

        var id: String { rawValue }

        var helperText: String {
            switch self {
            case .seasonalService:
                return "A one-time or seasonal service card for work like an AC check, a water-heater flush, or a spring inspection."
            case .routineProgram:
                return "A recurring program that lives in Your Services. Choose All or tap the active months for things like landscaping, trash, cleaning, or pool care."
            case .handymanItem:
                return "A small repair or punch-list item to batch into the next handyman visit."
            }
        }
    }

    /// Phase 50: Top-of-form task kind picker. Each kind pre-fills
    /// frequency and assignment defaults so users don't have to manually
    /// flip "vendor-managed" + "once" for things like estimate
    /// appointments and invoice follow-ups. The kind also stamps a
    /// metadata prefix in the notes field so the maintenance UI can
    /// route the task to the right section.
    enum TaskKind: String, CaseIterable, Identifiable {
        case maintenance = "Maintenance"
        case vendorAppointment = "Vendor visit"
        case followUp = "Follow-up"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .maintenance: return "wrench.and.screwdriver.fill"
            case .vendorAppointment: return "calendar.badge.plus"
            case .followUp: return "clock.badge.exclamationmark"
            }
        }

        var helperText: String {
            switch self {
            case .maintenance: return "A standard maintenance task on a recurring schedule."
            case .vendorAppointment: return "A one-time vendor visit (estimate, install, repair). Defaults to vendor-managed."
            case .followUp: return "A vendor follow-up — extra check-in tied to a recent service visit."
            }
        }
    }

    @State private var title = ""
    @State private var entryMode: EntryMode = .seasonalService
    @State private var taskKind: TaskKind = .maintenance
    @State private var targetType: TargetType = .property
    @State private var selectedPropertyId: UUID?
    @State private var selectedVehicleId: UUID?
    @State private var selectedSystemId: UUID?
    @State private var selectedContractorId: UUID?
    @State private var assignedUserId: UUID?
    @State private var frequency = "Annually"
    @State private var dueDate = Date()
    @State private var activeMonths: Set<Int> = Set(1...12)
    @State private var priority = "medium"
    @State private var notes = ""
    @State private var followUpReason = ""
    @State private var isSaving = false
    /// Phase 60: optional confirmed visit date. When the user ticks
    /// "Visit already scheduled" we stamp `scheduled_date` on the task
    /// so it lands in the Maintenance tab's "Scheduled" bucket instead
    /// of "To Schedule". The due-date field stays the reminder anchor
    /// (e.g. "remind me 3 days before the visit").
    @State private var hasScheduledVisit = false
    @State private var scheduledVisitDate = Date()

    /// Phase 56.5: Duplicate-prevention context. Loaded on appear so
    /// we can surface an inline warning when the user picks a vendor
    /// + system combination that matches an existing routine. Falls
    /// silent on failure so the form never breaks over detection.
    @State private var loadedRoutines: [RoutineRow] = []
    @State private var preventionMatch: (kind: DuplicateDetector.EntityKind, ref: DuplicateDetector.EntityRef)?
    @State private var didApplyInitialContext = false

    private let db = DatabaseService.shared

    private let frequencies = [
        "Once", "Weekly", "Every 2 Weeks", "Monthly", "Quarterly",
        "Semi-Annually", "Annually", "Every 2 Years", "Every 5 Years", "Seasonal"
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

    private var titlePlaceholder: String {
        switch entryMode {
        case .seasonalService:
            return "Service name"
        case .routineProgram:
            return "Routine name"
        case .handymanItem:
            return "Handyman item"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Phase 50: task kind picker — drives the rest of the
                // form's defaults (frequency, assignment, notes prefix).
                Section {
                    Picker("Create", selection: $entryMode) {
                        ForEach(EntryMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: entryMode) { _, newValue in
                        if newValue != .seasonalService {
                            targetType = .property
                        }
                    }
                    Text(entryMode.helperText)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)

                    if entryMode == .seasonalService {
                        Picker("Service type", selection: $taskKind) {
                            ForEach(TaskKind.allCases) { kind in
                                Text(kind.rawValue).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: taskKind) { _, newValue in
                            applyDefaults(for: newValue)
                        }
                        Text(taskKind.helperText)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Section {
                    TextField(titlePlaceholder, text: $title)

                    if entryMode == .seasonalService && taskKind == .followUp {
                        TextField("Reason (optional)", text: $followUpReason, axis: .vertical)
                            .lineLimit(2...4)
                    }

                    if entryMode == .seasonalService && !vehicles.isEmpty {
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

                Section(entryMode == .routineProgram ? "Cadence" : "Schedule") {
                    // Build 86: no date-range constraint. Users can add a
                    // task with a past due date (overdue backfill) or any
                    // future date. Validation happens at save time, not
                    // on the picker.
                    if entryMode != .handymanItem {
                        DatePicker(
                            entryMode == .routineProgram ? "Next expected date" : "Due date",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                        .tint(HavenColors.navy800)
                    }

                    // Phase 60: optional confirmed visit date. Keeps
                    // Due Date as the reminder anchor while letting
                    // the user mark a visit as already booked — the
                    // task then lands in the Maintenance tab's
                    // "Scheduled" bucket instead of "To Schedule".
                    if entryMode == .seasonalService {
                        Toggle("Visit already scheduled", isOn: $hasScheduledVisit.animation())
                            .tint(HavenColors.action)

                        if hasScheduledVisit {
                            DatePicker(
                                "Visit date",
                                selection: $scheduledVisitDate,
                                displayedComponents: .date
                            )
                            .tint(HavenColors.navy800)
                            Text("The task will show up under \"Scheduled\" on the Maintenance tab. Your due date remains the reminder anchor.")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    if entryMode != .handymanItem {
                        Picker(entryMode == .routineProgram ? "Cadence" : "Frequency", selection: $frequency) {
                            ForEach(frequencies, id: \.self) { f in
                                Text(f).tag(f)
                            }
                        }
                    }

                    if entryMode != .routineProgram {
                        Picker("Priority", selection: $priority) {
                            ForEach(priorities, id: \.self) { p in
                                Text(p.capitalized).tag(p)
                            }
                        }
                    }
                }

                if entryMode == .routineProgram {
                    Section("Active months") {
                        Text("Tap All for year-round programs, or choose just the months this routine actually runs.")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                        ActiveMonthsPicker(selectedMonths: $activeMonths)
                    }
                }

                if householdUsers.count > 0 {
                    Section("Assign To Person") {
                        Picker("Person", selection: $assignedUserId) {
                            Text("Unassigned").tag(nil as UUID?)
                            ForEach(householdUsers, id: \.id) { user in
                                Text(personLabel(for: user))
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

                // Phase 56.5: Duplicate-prevention inline warning.
                // Surfaces when the vendor + system category combo
                // already has a matching routine. Non-blocking — save
                // still works, the warning just asks the user to
                // consider editing the existing entity first.
                if let match = preventionMatch {
                    Section {
                        HStack(alignment: .top, spacing: HavenTheme.spacing8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HavenColors.warning)
                                .font(.system(size: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("You already have \"\(match.ref.displayName)\"")
                                    .font(HavenTypography.uiLabel.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("Edit the existing \(match.kind == .routine ? "routine" : "task") instead of creating a duplicate?")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(HavenTheme.spacing12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(HavenColors.warning.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(
                entryMode == .routineProgram
                    ? "Add Routine"
                    : entryMode == .handymanItem
                        ? "Add Handyman Item"
                        : "Add Service"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await saveTask() }
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .task {
                applyInitialContextIfNeeded()
                await loadDuplicateContext()
            }
            .onChange(of: selectedContractorId) { _, _ in checkForDuplicates() }
            .onChange(of: selectedSystemId) { _, _ in checkForDuplicates() }
            // Phase 56.5 patch: title similarity is part of the gate
            // now, so re-evaluate when the user edits the task title.
            .onChange(of: title) { _, _ in checkForDuplicates() }
        }
    }

    private func applyInitialContextIfNeeded() {
        guard !didApplyInitialContext else { return }
        didApplyInitialContext = true

        if let initialEntryMode {
            entryMode = initialEntryMode
        }

        if let initialPropertyId {
            targetType = .property
            selectedPropertyId = initialPropertyId
        } else if selectedPropertyId == nil {
            selectedPropertyId = properties.first?.id
        }

        if let initialVehicleId {
            targetType = .vehicle
            selectedVehicleId = initialVehicleId
        }
    }

    /// Phase 56.5: Hydrate the routines list for prevention checks.
    /// We already have `systems` + `contractors` from the parent so
    /// the only fetch needed is routines scoped to the active
    /// household. Silent failure → no warning (fail open).
    private func loadDuplicateContext() async {
        guard let propertyId = selectedPropertyId,
              let prop = properties.first(where: { $0.id == propertyId }) else {
            loadedRoutines = []
            return
        }
        let routines = (try? await DatabaseService.shared.fetchRoutines(householdId: prop.householdId)) ?? []
        await MainActor.run {
            self.loadedRoutines = routines
            self.checkForDuplicates()
        }
    }

    /// Phase 56.5: Run the prevention check when vendor or system
    /// changes. No-op for vehicle tasks (vehicles don't have
    /// routine-kind families).
    private func checkForDuplicates() {
        guard targetType == .property else { preventionMatch = nil; return }
        guard let vendorId = selectedContractorId else { preventionMatch = nil; return }

        let systemCategory = selectedSystemId.flatMap { sid in
            systems.first(where: { $0.id == sid })?.category
        }

        let match = DuplicateDetector.preventionCheckForTask(
            newSystemCategory: systemCategory,
            newTemplateId: nil,
            newTitle: title,
            newVendorId: vendorId,
            existingRoutines: loadedRoutines,
            contractors: contractors
        )
        preventionMatch = match
        if match != nil {
            Analytics.track(.duplicatePreventionWarned, [
                "surface": "add_task_sheet",
                "system_category": systemCategory ?? "",
            ])
        }
    }

    /// Phase 50: pre-fill defaults when the task kind picker changes.
    /// Vendor visit and follow-up both default to one-time vendor-managed
    /// tasks; switching back to maintenance restores the legacy
    /// per-frequency defaults so the user doesn't lose their selections.
    private func applyDefaults(for kind: TaskKind) {
        switch kind {
        case .maintenance:
            if frequency.lowercased() == "once" {
                frequency = "Annually"
            }
        case .vendorAppointment:
            frequency = "Once"
            if priority == "low" { priority = "medium" }
        case .followUp:
            frequency = "Once"
            priority = "high"
        }
    }

    /// Build 87 (Home Manager expansion): renders the picker label for a
    /// household user. Plain family members get just their first name (or
    /// full name fallback). Linked home managers get "Maria · Home Manager",
    /// linked staff get "Maria · Staff" — the suffix flows in via the
    /// `householdFamilyMembers` prop. Built as a single string here because
    /// SwiftUI's `Picker` row labels render best as one Text per option.
    private func personLabel(for user: UserRow) -> String {
        let base = user.fullName?.components(separatedBy: " ").first ?? user.fullName ?? "Member"
        guard let match = householdFamilyMembers.first(where: { $0.linkedUserId == user.id }) else {
            return base
        }
        switch match.memberType {
        case "home_manager": return "\(base) · Home Manager"
        case "staff": return "\(base) · Staff"
        default: return base
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

        switch entryMode {
        case .seasonalService:
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
            insert.serviceKey = "custom_seasonal_service"

            if hasScheduledVisit {
                insert.scheduledDate = formatter.string(from: scheduledVisitDate)
            }

            switch taskKind {
            case .maintenance:
                insert.notes = notes.isEmpty ? nil : notes
            case .vendorAppointment:
                insert.assignmentType = "vendor"
                insert.needsVendor = selectedContractorId == nil
                let trailing = notes.isEmpty ? "" : "\n\n\(notes)"
                insert.notes = "Custom vendor visit added by user.\(trailing)"
            case .followUp:
                insert.assignmentType = "vendor"
                insert.needsVendor = selectedContractorId == nil
                let reasonText = followUpReason.isEmpty ? trimmed : followUpReason
                let trailing = notes.isEmpty ? "" : "\n\n\(notes)"
                insert.notes = "Vendor follow-up: \(reasonText)\(trailing)"
            }

            if let vm = viewModel {
                await vm.createTask(insert)
                onSave?()
                dismiss()
            } else {
                isSaving = true
                do {
                    _ = try await ServiceOrchestrator.createCustomService(insert)
                    Haptics.success()
                    onSave?()
                    dismiss()
                } catch {
                    print("[AddTask] Failed to create task: \(error)")
                    Haptics.error()
                    isSaving = false
                }
            }

        case .routineProgram:
            guard let propertyId = selectedPropertyId else { return }
            isSaving = true
            do {
                let cadence = routineCadence(for: frequency)
                var insert = RoutineInsert(
                    householdId: householdId,
                    propertyId: propertyId,
                    label: trimmed,
                    routineKind: RoutineKind.otherService.rawValue,
                    cadenceType: cadence.type
                )
                insert.cadenceIntervalDays = cadence.intervalDays
                insert.vendorId = selectedContractorId
                insert.notes = notes.isEmpty ? nil : notes
                insert.nextExpectedDate = formatter.string(from: dueDate)
                insert.activeMonths = Array(activeMonths).sorted()
                insert.serviceKey = "custom_routine_program"
                _ = try await ServiceOrchestrator.createCustomRoutine(insert)
                Haptics.success()
                NotificationCenter.default.post(name: .routineChanged, object: nil)
                onSave?()
                dismiss()
            } catch {
                print("[AddTask] Failed to create routine: \(error)")
                Haptics.error()
                isSaving = false
            }

        case .handymanItem:
            guard let propertyId = selectedPropertyId else { return }
            isSaving = true
            do {
                _ = try await ServiceOrchestrator.createHandymanItem(
                    householdId: householdId,
                    propertyId: propertyId,
                    title: trimmed,
                    description: nil,
                    notes: notes.isEmpty ? nil : notes
                )
                Haptics.success()
                NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                NotificationCenter.default.post(name: .routineChanged, object: nil)
                onSave?()
                dismiss()
            } catch {
                print("[AddTask] Failed to create handyman item: \(error)")
                Haptics.error()
                isSaving = false
            }
        }
    }

    private func routineCadence(for frequency: String) -> (type: String, intervalDays: Int?) {
        switch frequency.lowercased() {
        case "weekly":
            return (RoutineCadenceType.weekly.rawValue, nil)
        case "every 2 weeks":
            return (RoutineCadenceType.biweekly.rawValue, nil)
        case "monthly":
            return (RoutineCadenceType.monthly.rawValue, nil)
        case "quarterly":
            return (RoutineCadenceType.quarterly.rawValue, nil)
        case "semi-annually":
            return (RoutineCadenceType.semiannual.rawValue, nil)
        case "annually":
            return (RoutineCadenceType.annual.rawValue, nil)
        case "seasonal":
            return (RoutineCadenceType.customDays.rawValue, 90)
        default:
            return (RoutineCadenceType.monthly.rawValue, nil)
        }
    }
}

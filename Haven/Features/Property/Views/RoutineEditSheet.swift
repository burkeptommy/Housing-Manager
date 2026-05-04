import SwiftUI

struct RoutineDraftPreset {
    let routineKind: RoutineKind
    let label: String
    let cadenceType: RoutineCadenceType
    let customIntervalDays: Int?
    let selectedWeekdays: Set<Int>
    let hasTimeOfDay: Bool
    let timeOfDay: Date
    let activeMonths: Set<Int>
    let startDate: Date
    let selectedVendor: ContractorRow?
    let notes: String
}

/// Phase 55.3: Unified Routine config sheet. Replaces both the Phase
/// 54D `CadenceEditSheet` and the standing-appointment edit flow.
/// Same form handles both service-based routines (Renata's biweekly
/// cleaning) and cadence-based routines (trash day on Wednesday) —
/// the vendor + cost sections surface only for service-based kinds.
///
/// Writes natively to the `routines` table via
/// `DatabaseService.createRoutine` / `updateRoutine` — no legacy
/// table involvement. The Phase 55.2.9 write-bridge is retired
/// alongside this ship because nothing routes through the legacy
/// sheet anymore.
struct RoutineEditSheet: View {
    let householdId: UUID
    let propertyId: UUID?
    let existing: RoutineRow?
    let preset: RoutineDraftPreset?
    let onSaved: () -> Void

    init(
        householdId: UUID,
        propertyId: UUID?,
        existing: RoutineRow? = nil,
        preset: RoutineDraftPreset? = nil,
        onSaved: @escaping () -> Void
    ) {
        self.householdId = householdId
        self.propertyId = propertyId
        self.existing = existing
        self.preset = preset
        self.onSaved = onSaved
    }

    @Environment(\.dismiss) private var dismiss

    @State private var routineKind: RoutineKind = .trash
    @State private var label: String = ""
    @State private var cadenceType: RoutineCadenceType = .weekly
    @State private var customIntervalDays: Int = 7
    @State private var selectedWeekdays: Set<Int> = []
    @State private var hasTimeOfDay: Bool = false
    @State private var timeOfDay: Date = Calendar.current.date(
        from: DateComponents(hour: 7, minute: 0)
    ) ?? Date()
    @State private var activeMonths: Set<Int> = Set(1...12)
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedVendor: ContractorRow?
    @State private var showVendorPicker: Bool = false
    @State private var eveningBefore: Bool = false
    @State private var morningOf: Bool = false
    @State private var estimatedCostDollars: String = ""
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm: Bool = false
    @State private var isDeleting: Bool = false
    @State private var isPaused: Bool = false
    /// Phase 80.1 — Local mirror of `existing.chezOwned`. Bound to the
    /// ChezOwnsToggle so the user sees an immediate flip; the toggle
    /// itself talks to the chez-concierge edge function.
    @State private var chezOwned: Bool = false

    /// Phase 56.5: Duplicate-prevention data pulled in alongside the
    /// existing contractors hydration. Loaded on appear; re-scanned
    /// whenever the vendor or routine kind changes.
    @State private var loadedRoutines: [RoutineRow] = []
    @State private var loadedTasks: [MaintenanceTaskDBRow] = []
    @State private var loadedSystems: [HomeSystemRow] = []
    @State private var loadedContractors: [ContractorRow] = []
    @State private var preventionMatch: (kind: DuplicateDetector.EntityKind, ref: DuplicateDetector.EntityRef)?

    var body: some View {
        Form {
            Section("Type") {
                Picker("Type", selection: $routineKind) {
                    ForEach(RoutineKind.allCases) { kind in
                        Label(kind.displayLabel, systemImage: kind.icon).tag(kind)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: routineKind) { _, newValue in
                    // Auto-populate label when the user hasn't typed
                    // something custom (or the current label is just
                    // the prior kind's default) — keeps the form fast.
                    if label.trimmingCharacters(in: .whitespaces).isEmpty
                        || RoutineKind.allCases.contains(where: { $0.displayLabel == label }) {
                        label = newValue.displayLabel
                    }
                }
                TextField("Label", text: $label)
            }

            // Vendor link — only for service-based kinds. Cadence
            // kinds (trash, recycling, school pickup) don't normally
            // have a linked contractor.
            if routineKind.supportsVendorLink {
                Section {
                    vendorRow
                    if selectedVendor != nil {
                        Button(role: .destructive) {
                            Haptics.light()
                            selectedVendor = nil
                        } label: {
                            Label("Remove vendor", systemImage: "xmark.circle")
                        }
                    }
                } header: {
                    Text("Service provider (optional)")
                } footer: {
                    if selectedVendor == nil {
                        Text("Link your \(routineKind.displayLabel.lowercased()) provider to see their logo and visit rhythm on the schedule.")
                            .font(HavenTypography.caption)
                    }
                }
            }

            Section("Cadence") {
                Picker("How often", selection: $cadenceType) {
                    ForEach(RoutineCadenceType.allCases, id: \.self) { type in
                        Text(type.displayLabel).tag(type)
                    }
                }

                if cadenceType == .customDays {
                    Stepper("Every \(customIntervalDays) days", value: $customIntervalDays, in: 1...365)
                }

                if [.weekly, .biweekly, .triweekly].contains(cadenceType) {
                    weekdayPicker
                }

                if cadenceType != .weekly && cadenceType != .customDays {
                    // Monthly+ cadences need an anchor date so the
                    // expander knows which specific day each month.
                    // Weekly cadences use `days_of_week`; custom_days
                    // uses `next_expected_date` set server-side.
                    DatePicker("Next occurrence", selection: $startDate, displayedComponents: .date)
                }

                if [.biweekly, .triweekly].contains(cadenceType) {
                    DatePicker("Reference week", selection: $startDate, displayedComponents: .date)
                }
            }

            Section {
                Toggle("Set a specific time", isOn: $hasTimeOfDay)
                if hasTimeOfDay {
                    DatePicker("Time", selection: $timeOfDay, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Time of day (optional)")
            } footer: {
                Text("e.g. \"Set out by 7am\" for trash. Leave off for any-time routines.")
                    .font(HavenTypography.caption)
            }

            Section {
                ActiveMonthsPicker(selectedMonths: $activeMonths)
            } header: {
                Text("Active months")
            }

            Section("Reminders") {
                Toggle("Evening before", isOn: $eveningBefore)
                Toggle("Morning of", isOn: $morningOf)
            }

            if routineKind.isVendorBased {
                Section("Cost per visit (optional)") {
                    HStack {
                        Text("$")
                            .foregroundStyle(HavenColors.textSecondary)
                        TextField("0", text: $estimatedCostDollars)
                            .keyboardType(.numberPad)
                    }
                }
            }

            // Phase 56.5: Inline duplicate-prevention warning. Surfaces
            // when a vendor + routine_kind combination matches an
            // existing routine or task. Non-blocking — user can still
            // save. "Edit existing" dismisses this sheet; the user can
            // re-open from the Routines list.
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

            Section("Notes (optional)") {
                TextField("Anything extra", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }

            // Phase 80.1 — Recurring delegation. Only on EXISTING
            // routines (you can't delegate something not yet saved).
            // Posts to the chez-concierge edge function which creates
            // a parent "Standing engagement" thread server-side.
            if let routine = existing {
                Section {
                    ChezOwnsToggle(
                        target: .routine(id: routine.id, label: routine.label),
                        isOwned: $chezOwned,
                        onChange: nil
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    .listRowBackground(Color.clear)
                }
            }

            // Phase 95: pause toggle. Paused routines stop seeding visit
            // occurrences (RoutineOccurrenceExpander filters paused rows
            // out) but stay on the list with a muted badge so the user
            // can resume without re-creating. Schema column is
            // `routines.is_paused` — already in place since Phase 55.1.
            if existing != nil {
                Section {
                    Toggle(isOn: $isPaused) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isPaused ? "Routine is paused" : "Pause routine")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(isPaused
                                 ? "Visits won't appear on schedules until you resume."
                                 : "Stop generating visits temporarily without losing the routine.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    .tint(HavenColors.action)
                }
            }

            // Phase 55.3: Delete affordance inside the edit sheet so
            // users always have a reliable path — the list swipe can
            // be flaky on rows that wrap a Button. Hidden on the add
            // flow because there's nothing to delete yet. Goes through
            // archiveRoutine (soft-delete via archived_at) so
            // maintenance_tasks.routine_id FKs don't block the action
            // and visit history is preserved.
            if existing != nil {
                Section {
                    Button(role: .destructive) {
                        Haptics.light()
                        showDeleteConfirm = true
                    } label: {
                        if isDeleting {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Deleting...")
                            }
                        } else {
                            Label("Delete routine", systemImage: "trash")
                        }
                    }
                    .disabled(isDeleting || isSaving)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }
            }
        }
        .confirmationDialog(
            "Delete this routine?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await delete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes the routine from every schedule. Visit history is preserved.")
        }
        .navigationTitle(existing == nil ? "Add program" : "Edit program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(HavenColors.textPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving { ProgressView() } else { Text("Save").fontWeight(.semibold) }
                }
                .foregroundStyle(HavenColors.textPrimary)
                .disabled(isDisabled || isSaving)
            }
        }
        .onAppear {
            loadExisting()
            Task { await loadDuplicateContext() }
        }
        .onChange(of: selectedVendor?.id) { _, _ in checkForDuplicates() }
        .onChange(of: routineKind) { _, _ in checkForDuplicates() }
        // Phase 56.5 patch: title similarity is part of the gate now,
        // so re-run the check when the user edits the label.
        .onChange(of: label) { _, _ in checkForDuplicates() }
        .sheet(isPresented: $showVendorPicker) {
            ContractorPickerSheet(
                systemCategory: vendorPickerCategory(for: routineKind),
                onSelect: { contractor in
                    selectedVendor = contractor
                    Haptics.light()
                }
            )
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var vendorRow: some View {
        Button {
            Haptics.light()
            showVendorPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedVendor == nil ? "person.crop.circle.badge.plus" : "person.crop.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(HavenColors.navy700)
                VStack(alignment: .leading, spacing: 2) {
                    if let vendor = selectedVendor {
                        Text(vendor.companyName)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        if let contact = vendor.contactName, !contact.isEmpty {
                            Text(contact)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    } else {
                        Text("Link a vendor")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Pulls the company's logo onto this routine")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var weekdayPicker: some View {
        HStack(spacing: 6) {
            ForEach(weekdayOptions, id: \.weekday) { option in
                Button {
                    Haptics.selection()
                    if selectedWeekdays.contains(option.weekday) {
                        selectedWeekdays.remove(option.weekday)
                    } else {
                        selectedWeekdays.insert(option.weekday)
                    }
                } label: {
                    Text(option.label)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(selectedWeekdays.contains(option.weekday) ? HavenColors.textOnNavy : HavenColors.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(selectedWeekdays.contains(option.weekday) ? HavenColors.navy : HavenColors.beige200)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Static helpers

    private var weekdayOptions: [(weekday: Int, label: String)] {
        [(1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")]
    }

    private var isDisabled: Bool {
        if label.trimmingCharacters(in: .whitespaces).isEmpty { return true }
        if [.weekly, .biweekly, .triweekly].contains(cadenceType) && selectedWeekdays.isEmpty { return true }
        if activeMonths.isEmpty { return true }
        return false
    }

    /// Maps a routine kind to a ContractorPickerSheet category token
    /// so the picker's existing analytics event has a meaningful tag.
    /// Matches the mapping in the 54E.2 CadenceEditSheet so
    /// vendor-category stats stay continuous.
    private func vendorPickerCategory(for kind: RoutineKind) -> String {
        switch kind {
        case .cleaning: return "cleaning"
        case .landscaping: return "landscaping"
        case .poolService: return "pool_service"
        case .pestControl: return "pest_control"
        case .petWaste: return "pet_waste"
        case .mosquitoTick: return "mosquito_tick"
        case .snowRemoval: return "snow_removal"
        case .gutterCleaning: return "gutter_cleaning"
        case .windowCleaning: return "window_cleaning"
        case .treeService: return "tree_service"
        case .handymanRecurring: return "handyman"
        case .trash, .recycling, .compost, .yardWaste: return "trash"
        default: return "routine_\(kind.rawValue)"
        }
    }

    // MARK: - Load + save

    private func loadExisting() {
        if let existing {
            routineKind = existing.typedKind ?? .otherCadence
            label = existing.presentationLabel
            cadenceType = existing.typedCadence ?? .weekly
            customIntervalDays = existing.cadenceIntervalDays ?? 7
            selectedWeekdays = Set(existing.daysOfWeek ?? [])
            if let timeString = existing.timeOfDay {
                let parts = timeString.split(separator: ":")
                if parts.count >= 2,
                   let hour = Int(parts[0]),
                   let minute = Int(parts[1]) {
                    var comps = DateComponents()
                    comps.hour = hour
                    comps.minute = minute
                    if let date = Calendar.current.date(from: comps) {
                        timeOfDay = date
                        hasTimeOfDay = true
                    }
                }
            }
            activeMonths = Set(existing.activeMonths)
            let startFormatter = DateFormatter()
            startFormatter.dateFormat = "yyyy-MM-dd"
            if let start = startFormatter.date(from: existing.startDate) {
                startDate = start
            }
            eveningBefore = existing.eveningBeforeReminder
            morningOf = existing.morningOfReminder
            if let cents = existing.estimatedCostPerVisitCents, cents > 0 {
                estimatedCostDollars = String(cents / 100)
            }
            notes = existing.notes ?? ""
            chezOwned = existing.chezOwned
            isPaused = existing.isPaused
            if let vendorId = existing.vendorId {
                Task { await hydrateVendor(id: vendorId) }
            }
        } else if let preset {
            routineKind = preset.routineKind
            label = preset.label
            cadenceType = preset.cadenceType
            customIntervalDays = preset.customIntervalDays ?? 7
            selectedWeekdays = preset.selectedWeekdays
            hasTimeOfDay = preset.hasTimeOfDay
            timeOfDay = preset.timeOfDay
            activeMonths = preset.activeMonths
            startDate = preset.startDate
            selectedVendor = preset.selectedVendor
            notes = preset.notes
        } else {
            label = routineKind.displayLabel
            selectedWeekdays = [4]  // Wednesday — default trash day
            startDate = Calendar.current.startOfDay(for: Date())
        }
    }

    private func hydrateVendor(id: UUID) async {
        let contractors = (try? await DatabaseService.shared.fetchContractors()) ?? []
        if let match = contractors.first(where: { $0.id == id }) {
            await MainActor.run { selectedVendor = match }
        }
    }

    /// Phase 56.5: Hydrate the lists DuplicateDetector needs for its
    /// prevention check. Ignored during edits (user can always edit an
    /// existing routine without flagging itself as a duplicate) but
    /// runs on every add flow. Each list load uses `try?` so a failure
    /// degrades to "no warning shown" rather than blocking the form.
    private func loadDuplicateContext() async {
        guard existing == nil else { return }
        async let routinesTask = DatabaseService.shared.fetchRoutines(householdId: householdId)
        async let tasksTask = DatabaseService.shared.fetchMaintenanceTasks()
        async let contractorsTask = DatabaseService.shared.fetchContractors()
        let routines = (try? await routinesTask) ?? []
        let tasks = (try? await tasksTask) ?? []
        let contractors = (try? await contractorsTask) ?? []
        // Home systems are needed for task category resolution. Load
        // scoped to the property if we have one, otherwise skip —
        // without a propertyId we don't have enough context to match
        // on system category anyway.
        var systems: [HomeSystemRow] = []
        if let propertyId {
            systems = (try? await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId)) ?? []
        }
        await MainActor.run {
            self.loadedRoutines = routines
            self.loadedTasks = tasks
            self.loadedSystems = systems
            self.loadedContractors = contractors
            checkForDuplicates()
        }
    }

    /// Phase 56.5: Run the prevention check against the loaded lists.
    /// No-op on edits; runs every time the vendor or routine kind
    /// changes during an add flow.
    private func checkForDuplicates() {
        guard existing == nil else { preventionMatch = nil; return }
        guard let vendorId = selectedVendor?.id else { preventionMatch = nil; return }

        let match = DuplicateDetector.preventionCheck(
            newRoutineKind: routineKind.rawValue,
            newTitle: label,
            newVendorId: vendorId,
            existingRoutines: loadedRoutines,
            existingTasks: loadedTasks,
            systems: loadedSystems,
            contractors: loadedContractors
        )
        preventionMatch = match
        if match != nil {
            Analytics.track(.duplicatePreventionWarned, [
                "surface": "routine_edit_sheet",
                "routine_kind": routineKind.rawValue,
            ])
        }
    }

    /// Phase 55.3: Soft-delete via archive. Archived routines are
    /// filtered out of `fetchRoutines` so the row disappears from
    /// every surface immediately; `routine_visits` and any
    /// `maintenance_tasks.routine_id` references stay intact, so
    /// history is preserved and FK constraints don't block the
    /// action. Users can restore manually via a future admin
    /// surface if needed.
    private func delete() async {
        guard let existing else { return }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await DatabaseService.shared.archiveRoutine(id: existing.id)
            Haptics.success()
            Analytics.track(.householdCadenceDeleted, [
                "routine_kind": existing.routineKind,
                "cadence_type": existing.cadenceType,
            ])
            NotificationCenter.default.post(name: .routineChanged, object: nil)
            onSaved()
            dismiss()
        } catch {
            errorMessage = "Couldn't delete: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let timeString: String? = {
            guard hasTimeOfDay else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter.string(from: timeOfDay)
        }()
        let costCents: Int? = {
            guard let dollars = Int(estimatedCostDollars), dollars > 0 else { return nil }
            return dollars * 100
        }()
        let startString: String = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: startDate)
        }()
        let daysOut: [Int]? = [.weekly, .biweekly, .triweekly].contains(cadenceType)
            ? Array(selectedWeekdays).sorted()
            : nil
        let intervalDaysOut: Int? = cadenceType == .customDays ? customIntervalDays : nil
        let activeMonthsOut = Array(activeMonths).sorted()
        let vendorIdOut = routineKind.supportsVendorLink ? selectedVendor?.id : nil

        do {
            // Phase 66: If a vendor is now attached, the routine should
            // be `active` (so it hides child tasks). If no vendor and
            // the routine is service-based, leave it in `pending_vendor`
            // so the "Chez helping" card surfaces in Your Services.
            // Non-vendor routines (trash, recycling) stay `active` —
            // they don't need a vendor.
            let derivedSetupState: String = {
                if !routineKind.isVendorBased { return "active" }
                if vendorIdOut != nil { return "active" }
                return existing?.setupState ?? "pending_vendor"
            }()

            var savedRoutine: RoutineRow?

            if let existing {
                var update = RoutineUpdate()
                update.label = trimmedLabel
                update.cadenceType = cadenceType.rawValue
                update.cadenceIntervalDays = intervalDaysOut
                update.daysOfWeek = daysOut
                update.timeOfDay = timeString
                update.vendorId = vendorIdOut
                update.activeMonths = activeMonthsOut
                update.startDate = startString
                update.nextExpectedDate = startString
                update.eveningBeforeReminder = eveningBefore
                update.morningOfReminder = morningOf
                update.estimatedCostPerVisitCents = costCents
                update.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
                update.setupState = derivedSetupState
                update.isPaused = isPaused
                savedRoutine = try await DatabaseService.shared.updateRoutine(id: existing.id, update)
            } else {
                var insert = RoutineInsert(
                    householdId: householdId,
                    propertyId: propertyId,
                    label: trimmedLabel,
                    routineKind: routineKind.rawValue,
                    cadenceType: cadenceType.rawValue
                )
                insert.vendorId = vendorIdOut
                insert.cadenceIntervalDays = intervalDaysOut
                insert.daysOfWeek = daysOut
                insert.timeOfDay = timeString
                insert.startDate = startString
                insert.nextExpectedDate = startString
                insert.activeMonths = activeMonthsOut
                insert.eveningBeforeReminder = eveningBefore
                insert.morningOfReminder = morningOf
                insert.estimatedCostPerVisitCents = costCents
                insert.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
                insert.cadenceSource = "user_set"
                insert.setupState = derivedSetupState
                savedRoutine = try await DatabaseService.shared.createRoutine(insert)
            }

            // Phase 66: If the saved routine is active AND property-scoped,
            // run the grouping engine to link matching vendor tasks under it.
            // No-op for cadence-based routines (trash etc.) and
            // pending-vendor / paused routines (don't hide until active).
            if let routine = savedRoutine,
               let propertyId,
               routine.typedSetupState == .active,
               routine.typedScope == .property {
                _ = try? await RoutineGroupingEngine.linkVendorTasksToRoutine(
                    routine,
                    in: householdId,
                    propertyId: propertyId
                )
            }

            // Phase 66: If saved routine transitioned AWAY from active
            // (e.g. user paused it or switched to pending_vendor), unlink
            // its child tasks so they resurface in the main list.
            if let existing,
               let routine = savedRoutine,
               existing.typedSetupState == .active,
               routine.typedSetupState != .active {
                _ = try? await RoutineGroupingEngine.unlinkTasksFromRoutine(routine.id)
            }

            Haptics.success()
            Analytics.track(.householdCadenceSaved, [
                "cadence_type": cadenceType.rawValue,
                "routine_kind": routineKind.rawValue,
                "is_new": existing == nil,
                "has_vendor": selectedVendor != nil,
                "active_months_count": activeMonthsOut.count,
                "setup_state": derivedSetupState,
            ])
            NotificationCenter.default.post(name: .routineChanged, object: nil)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            onSaved()
            dismiss()
        } catch {
            errorMessage = "Couldn't save: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}

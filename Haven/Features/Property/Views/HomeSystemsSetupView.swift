import SwiftUI

/// Interactive "What does your home have?" checklist shown after creating a property.
/// Creates home systems + maintenance tasks for selected categories in one tap.
struct HomeSystemsSetupView: View {
    let propertyId: UUID
    let householdId: UUID
    let propertyType: String
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    // MARK: - System Subtype Enums

    enum YardType: String, CaseIterable {
        case naturalLawn = "Natural Lawn"
        case turf = "Artificial Turf"
        case xeriscape = "Xeriscape / Desert"
        case noYard = "No Yard"
    }

    enum HVACType: String, CaseIterable {
        case centralDucted = "Central / Ducted"
        case miniSplit = "Mini-Split / Ductless"
        case boilerRadiant = "Boiler / Radiant"
        case windowUnits = "Window Units"
    }

    enum WaterHeaterType: String, CaseIterable {
        case tank = "Tank"
        case tankless = "Tankless"
    }

    enum SetupStep {
        case checklist, taskReview, serviceDates, completion
    }

    @State private var selections: [SystemOption] = SystemOption.defaultOptions()
    @State private var showAllStandard = false
    @State private var isSaving = false
    @State private var savedCount = 0
    @State private var savingProgress: Double = 0
    @State private var savingTotal: Int = 0
    @State private var savingCurrentName: String = ""
    @State private var currentStep: SetupStep = .checklist
    @State private var createdTasks: [MaintenanceTaskDBRow] = []
    @State private var systemsAlreadyCreated = false
    @State private var taskServiceDates: [UUID: ServiceDateEntry] = [:]
    @State private var expandedSections: Set<String> = []

    // System subtype selections
    @State private var yardType: YardType = .naturalLawn
    @State private var hvacType: HVACType = .centralDucted
    @State private var waterHeaterType: WaterHeaterType = .tank
    @State private var hasSumpPump = false
    @State private var hasFireplace = false
    @State private var hasGarbageDisposal = true

    enum ServiceDateOption: String {
        case date = "date"
        case dontKnow = "dont_know"
        case never = "never"
    }

    struct ServiceDateEntry {
        var option: ServiceDateOption = .dontKnow
        var date: Date = .now
    }

    var body: some View {
        NavigationStack {
            Group {
                switch currentStep {
                case .completion:
                    completionView
                case .serviceDates:
                    serviceDatesView
                case .taskReview:
                    taskReviewView
                case .checklist:
                    checklistView
                }
            }
            .navigationTitle("Set Up Home Systems")
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("HomeSystemsSetupView")
            .toolbar {
                if currentStep != .completion {
                    ToolbarItem(placement: .cancellationAction) {
                        if currentStep == .checklist {
                            Button("Skip") {
                                onComplete?()
                                dismiss()
                            }
                        } else {
                            Button {
                                withAnimation {
                                    switch currentStep {
                                    case .taskReview: currentStep = .checklist
                                    case .serviceDates: currentStep = .taskReview
                                    default: break
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Back")
                                }
                            }
                        }
                    }
                }
            }
            .tint(HavenColors.navy)
        }
    }

    // MARK: - Checklist

    private var standardSystems: [SystemOption] {
        selections.filter(\.isCommon)
    }

    private var checklistView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Set Up Home Systems")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("We'll create a maintenance schedule based on your home's systems.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Standard systems — always included
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(HavenColors.success)
                            Text("ALWAYS INCLUDED")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                        }

                        Text("Every home has these — we'll set them up for you automatically.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)

                        // Show first 3 systems as preview
                        ForEach(standardSystems.prefix(3)) { system in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(HavenColors.success)
                                    .font(.caption)
                                Text(system.name)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                            .padding(.vertical, 2)
                        }

                        // Expandable "view all" section
                        if standardSystems.count > 3 {
                            if showAllStandard {
                                ForEach(standardSystems.dropFirst(3)) { system in
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(HavenColors.success)
                                            .font(.caption)
                                        Text(system.name)
                                            .font(HavenTypography.bodySmall)
                                            .foregroundStyle(HavenColors.textPrimary)
                                    }
                                    .padding(.vertical, 2)
                                }

                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showAllStandard = false
                                    }
                                } label: {
                                    Text("Show less")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.navy700)
                                }
                                .padding(.top, 4)
                            } else {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showAllStandard = true
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text("and \(standardSystems.count - 3) more included")
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundStyle(HavenColors.navy700)
                                        Image(systemName: "chevron.down")
                                            .font(.caption2)
                                            .foregroundStyle(HavenColors.navy700)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding()
                    .background(HavenColors.success.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // System customization — tell us about your home
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(HavenColors.navy600)
                            Text("TELL US ABOUT YOUR HOME")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                        }

                        Text("We'll tailor maintenance tasks to match your setup.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)

                        subtypePicker(label: "HVAC Type", icon: "thermometer.medium") {
                            Picker("HVAC", selection: $hvacType) {
                                ForEach(HVACType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.menu)
                        }

                        subtypePicker(label: "Water Heater", icon: "flame.fill") {
                            Picker("Water Heater", selection: $waterHeaterType) {
                                ForEach(WaterHeaterType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.menu)
                        }

                        subtypePicker(label: "Yard", icon: "leaf.fill") {
                            Picker("Yard", selection: $yardType) {
                                ForEach(YardType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.menu)
                        }

                        subtypeToggle(label: "Sump Pump", icon: "arrow.up.and.down.circle", isOn: $hasSumpPump)
                        subtypeToggle(label: "Fireplace / Chimney", icon: "fireplace.fill", isOn: $hasFireplace)
                        subtypeToggle(label: "Garbage Disposal", icon: "arrow.3.trianglepath", isOn: $hasGarbageDisposal)
                    }
                    .padding()
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Additional systems — toggleable
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DOES YOUR HOME HAVE THESE?")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        ForEach($selections.filter { !$0.wrappedValue.isCommon }) { $option in
                            Toggle(isOn: $option.isSelected) {
                                HStack(spacing: 8) {
                                    Image(systemName: option.icon)
                                        .font(.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                        .frame(width: 20)
                                    Text(option.name)
                                        .font(HavenTypography.bodySmall)
                                }
                            }
                            .tint(HavenColors.navy800)
                        }
                    }
                    .padding()
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .padding(.bottom, 80)
            }

            // Bottom button
            VStack(spacing: 0) {
                Divider()
                if isSaving {
                    VStack(spacing: 10) {
                        ProgressView(value: savingProgress, total: Double(max(savingTotal, 1)))
                            .tint(HavenColors.navy)
                            .animation(.easeInOut(duration: 0.3), value: savingProgress)

                        HStack(spacing: 6) {
                            Text("Setting up \(savingCurrentName)...")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                            Spacer()
                            Text("\(Int(savingProgress))/\(savingTotal)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                    .padding()
                } else {
                    Button {
                        Task { await createSystems() }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Set Up \(selectedCount) Systems")
                        }
                        .font(HavenTypography.uiButton)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedCount > 0 ? HavenColors.navy : HavenColors.navy.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                    .disabled(selectedCount == 0)
                    .padding()
                }
            }
            .background(HavenColors.cream)
        }
        .background(HavenColors.background)
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(HavenColors.success)

            Text("Home Setup Complete!")
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)

            Text("\(savedCount) systems created with \(taskCountEstimate) maintenance tasks. Haven will remind you when things are due.")
                .font(HavenTypography.subheadline)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                onComplete?()
                dismiss()
            } label: {
                Text("Done")
                    .font(HavenTypography.uiButton)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HavenColors.navy)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .padding()
        }
        .background(HavenColors.background)
    }

    // MARK: - Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(HavenTypography.uiSectionHeader)
            .tracking(1.5)
            .foregroundStyle(HavenColors.textTertiary)
            .padding(.horizontal)
            .padding(.top, 8)
    }

    private func systemToggleRow(option: Binding<SystemOption>) -> some View {
        Button {
            option.wrappedValue.isSelected.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: option.wrappedValue.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(option.wrappedValue.isSelected ? HavenColors.navy : HavenColors.textTertiary)

                Image(systemName: option.wrappedValue.icon)
                    .font(.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.wrappedValue.name)
                        .font(HavenTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("\(option.wrappedValue.taskCount) maintenance tasks")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed

    private var selectedCount: Int {
        selections.filter(\.isSelected).count
    }

    private var templateCount: Int {
        selections.filter(\.isSelected).reduce(0) { $0 + $1.taskCount }
    }

    private var taskCountEstimate: Int {
        savedCount * 4 // rough estimate
    }

    // MARK: - Subtype UI Components

    private func subtypePicker<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(HavenColors.navy600)
                .frame(width: 20)
            Text(label)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer()
            content()
                .tint(HavenColors.navy800)
        }
    }

    private func subtypeToggle(label: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(HavenColors.navy600)
                .frame(width: 20)
            Toggle(label, isOn: isOn)
                .font(HavenTypography.bodySmall)
                .tint(HavenColors.navy800)
        }
    }

    // MARK: - Subtype Helpers

    /// Builds the set of active subtypes based on user selections, used to filter templates.
    private func activeSubtypes(for category: String) -> Set<String> {
        switch category {
        case "Landscaping":
            var s: Set<String> = []
            if yardType == .naturalLawn { s.insert("lawn") }
            return s
        case "HVAC":
            var s: Set<String> = []
            switch hvacType {
            case .centralDucted:
                s.formUnion(["ducted", "has_ac", "has_furnace"])
            case .miniSplit:
                s.formUnion(["has_ac", "has_furnace"]) // no ducts
            case .boilerRadiant:
                s.insert("has_furnace") // no AC, no ducts
            case .windowUnits:
                s.insert("has_ac") // no furnace, no ducts
            }
            return s
        case "Water Heater":
            return waterHeaterType == .tank ? ["tank"] : []
        case "Plumbing":
            var s: Set<String> = []
            if hasSumpPump { s.insert("sump_pump") }
            return s
        case "Fire Protection":
            var s: Set<String> = []
            if hasFireplace { s.insert("fireplace") }
            return s
        case "Appliance":
            var s: Set<String> = []
            if hasGarbageDisposal { s.insert("garbage_disposal") }
            return s
        default:
            return []
        }
    }

    // MARK: - Actions

    private func createSystems() async {
        // Prevent duplicate creation on back-navigation + re-tap
        guard !systemsAlreadyCreated else {
            withAnimation { currentStep = .taskReview }
            return
        }

        let selected = selections.filter(\.isSelected)
        Analytics.track(.homeSystemsSetupStarted, ["system_count": selected.count, "property_id": propertyId.uuidString])
        savingTotal = selected.count
        savingProgress = 0
        savingCurrentName = selected.first?.name ?? ""
        isSaving = true

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var count = 0
        var allCreatedTasks: [MaintenanceTaskDBRow] = []

        // Fetch existing systems for this property to avoid duplicates
        let existingSystems = (try? await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId)) ?? []
        let existingNames = Set(existingSystems.map { $0.name.lowercased() })

        for option in selected {
            savingCurrentName = option.name

            // Skip if a system with this name already exists on this property
            if existingNames.contains(option.systemName.lowercased()) {
                count += 1
                savingProgress = Double(count)
                continue
            }

            do {
                let insert = HomeSystemInsert(
                    propertyId: propertyId,
                    householdId: householdId,
                    name: option.systemName,
                    category: option.category,
                    status: "Good"
                )
                let system = try await DatabaseService.shared.createHomeSystem(insert)

                let subtypes = activeSubtypes(for: option.category)
                let templates = MaintenanceTemplates.essentialTemplates(for: option.category, activeSubtypes: subtypes)
                for mt in templates {
                    let nextDue = Calendar.current.date(byAdding: mt.interval, to: .now) ?? .now
                    let taskInsert = MaintenanceTaskInsert(
                        propertyId: propertyId,
                        householdId: householdId,
                        title: mt.title,
                        frequency: mt.frequency,
                        nextDueDate: formatter.string(from: nextDue),
                        systemId: system.id,
                        description: mt.description,
                        priority: mt.priority,
                        isTemplateBased: true,
                        templateId: mt.systemCategory + ":" + mt.title,
                        seasonalTiming: mt.seasonalTiming,
                        isDiy: mt.isDIY,
                        professionalRequired: mt.professionalRequired,
                        costRange: mt.estimatedCostRange,
                        recurrenceRule: mt.frequency
                    )
                    let task = try await DatabaseService.shared.createMaintenanceTask(taskInsert)
                    allCreatedTasks.append(task)
                }
                count += 1
                savingProgress = Double(count)
            } catch {
                print("[HomeSystemsSetup] Failed to create \(option.name): \(error.localizedDescription)")
                savingProgress = Double(count + 1) // still advance progress on failure
            }
        }

        savedCount = count
        createdTasks = allCreatedTasks
        systemsAlreadyCreated = count > 0
        isSaving = false
        Analytics.track(.homeSystemsSetupCompleted, ["systems_created": count, "tasks_created": allCreatedTasks.count])
        Haptics.success()

        // Show task review step if we have tasks, otherwise go to completion
        if allCreatedTasks.isEmpty {
            withAnimation { currentStep = .completion }
        } else {
            withAnimation { currentStep = .taskReview }
        }
    }

    /// Select representative tasks to ask about (avoid overwhelming with 40+ tasks)
    private func pickKeyTasks(from tasks: [MaintenanceTaskDBRow]) -> [MaintenanceTaskDBRow] {
        // Group by system, pick the most frequent task per system
        var bySystem: [UUID: [MaintenanceTaskDBRow]] = [:]
        for task in tasks {
            let key = task.systemId ?? UUID()
            bySystem[key, default: []].append(task)
        }

        let frequencyOrder = ["monthly", "quarterly", "semi-annually", "annually"]
        return bySystem.values.compactMap { systemTasks in
            systemTasks.min { a, b in
                let aIdx = frequencyOrder.firstIndex(of: a.frequency.lowercased()) ?? 99
                let bIdx = frequencyOrder.firstIndex(of: b.frequency.lowercased()) ?? 99
                return aIdx < bIdx
            }
        }.sorted { $0.title < $1.title }
    }

    private func applyServiceDates() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for (taskId, entry) in taskServiceDates {
            guard let task = createdTasks.first(where: { $0.id == taskId }) else { continue }

            switch entry.option {
            case .date:
                // Recalculate nextDueDate from the user-provided last service date
                let nextDue = calculateNextDueDate(frequency: task.frequency, from: entry.date)
                _ = try? await DatabaseService.shared.updateMaintenanceTask(
                    id: taskId,
                    MaintenanceTaskUpdate(
                        lastCompletedDate: formatter.string(from: entry.date),
                        nextDueDate: formatter.string(from: nextDue)
                    )
                )
            case .never:
                // Never done — set due date to today so it shows as urgent
                _ = try? await DatabaseService.shared.updateMaintenanceTask(
                    id: taskId,
                    MaintenanceTaskUpdate(
                        nextDueDate: formatter.string(from: .now)
                    )
                )
            case .dontKnow:
                // Leave as-is (default: now + interval)
                break
            }
        }
    }

    private func calculateNextDueDate(frequency: String, from date: Date) -> Date {
        let cal = Calendar.current
        switch frequency.lowercased() {
        case "monthly": return cal.date(byAdding: .month, value: 1, to: date)!
        case "every 2 months": return cal.date(byAdding: .month, value: 2, to: date)!
        case "quarterly": return cal.date(byAdding: .month, value: 3, to: date)!
        case "every 4 months": return cal.date(byAdding: .month, value: 4, to: date)!
        case "semi-annually": return cal.date(byAdding: .month, value: 6, to: date)!
        case "annually": return cal.date(byAdding: .year, value: 1, to: date)!
        case "every 2 years": return cal.date(byAdding: .year, value: 2, to: date)!
        case "every 3 years": return cal.date(byAdding: .year, value: 3, to: date)!
        case "every 5 years": return cal.date(byAdding: .year, value: 5, to: date)!
        case "every 10 years": return cal.date(byAdding: .year, value: 10, to: date)!
        case "seasonal": return cal.date(byAdding: .month, value: 3, to: date)!
        default: return cal.date(byAdding: .year, value: 1, to: date)!
        }
    }

    // MARK: - Task Review

    /// Groups tasks by system name for display
    private var tasksBySystem: [(systemName: String, tasks: [MaintenanceTaskDBRow])] {
        var groups: [String: [MaintenanceTaskDBRow]] = [:]
        for task in createdTasks {
            let systemName = task.templateId?.components(separatedBy: ":").first ?? "Other"
            groups[systemName, default: []].append(task)
        }
        return groups.sorted { $0.key < $1.key }.map { (systemName: $0.key, tasks: $0.value) }
    }

    private var taskReviewView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Review Your Tasks")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Tap a section to expand and remove tasks that don't apply.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Text("\(createdTasks.count) tasks across \(tasksBySystem.count) systems")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textTertiary)

                    ForEach(tasksBySystem, id: \.systemName) { group in
                        let isExpanded = expandedSections.contains(group.systemName)

                        VStack(spacing: 0) {
                            // Section header — tappable
                            Button {
                                Haptics.light()
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    if isExpanded {
                                        expandedSections.remove(group.systemName)
                                    } else {
                                        expandedSections.insert(group.systemName)
                                    }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: iconForCategory(group.systemName))
                                        .font(.system(size: 14))
                                        .foregroundStyle(HavenColors.navy700)
                                        .frame(width: 24)

                                    Text(group.systemName.uppercased())
                                        .font(HavenTypography.uiSectionHeader)
                                        .tracking(1.5)
                                        .foregroundStyle(HavenColors.textPrimary)

                                    Spacer()

                                    Text("\(group.tasks.count)")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(HavenColors.navy700)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(HavenColors.navy.opacity(0.08))
                                        .clipShape(Capsule())

                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            // Expanded task list
                            if isExpanded {
                                Divider().padding(.leading, 48)

                                ForEach(group.tasks) { task in
                                    HStack(spacing: 10) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(task.title)
                                                .font(HavenTypography.bodySmall)
                                                .foregroundStyle(HavenColors.textPrimary)
                                            Text(task.frequency)
                                                .font(HavenTypography.caption)
                                                .foregroundStyle(HavenColors.textTertiary)
                                        }
                                        Spacer()
                                        Button {
                                            removeTaskDuringReview(task)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(HavenColors.textTertiary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 14)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                        .background(HavenColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .havenShadow()
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }

            // Bottom buttons
            VStack(spacing: 0) {
                Divider()
                VStack(spacing: 8) {
                    Button {
                        proceedToServiceDates()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Looks Good")
                        }
                        .font(HavenTypography.uiButton)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(HavenColors.navy)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }

                    Button {
                        proceedToServiceDates()
                    } label: {
                        Text("Skip review")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                .padding()
            }
            .background(HavenColors.cream)
        }
        .background(HavenColors.background)
    }

    private func iconForCategory(_ category: String) -> String {
        let map: [String: String] = [
            "HVAC": "thermometer.medium",
            "Plumbing": "drop.fill",
            "Roofing": "house.fill",
            "Electrical": "bolt.fill",
            "Water Heater": "flame.fill",
            "Siding/Exterior": "building.2.fill",
            "Windows": "window.vertical.open",
            "Doors": "door.left.hand.closed",
            "Appliance": "refrigerator.fill",
            "Fire Protection": "sensor.fill",
            "Landscaping": "leaf.fill",
            "Pest Control": "ant.fill",
            "Garage Door": "door.garage.closed",
            "Pool/Spa": "figure.pool.swim",
            "Septic System": "arrow.down.to.line",
            "Well System": "drop.circle.fill",
            "Generator": "bolt.batteryblock.fill",
            "Security System": "lock.shield.fill",
            "Solar": "sun.max.fill",
            "Crawl Space": "square.stack.3d.down.forward.fill",
            "Irrigation": "sprinkler.and.droplets.fill",
            "Water Treatment": "water.waves",
        ]
        return map[category] ?? "gearshape"
    }

    private func removeTaskDuringReview(_ task: MaintenanceTaskDBRow) {
        Haptics.light()
        createdTasks.removeAll { $0.id == task.id }
        Task {
            try? await DatabaseService.shared.deleteMaintenanceTask(id: task.id)
        }
    }

    private func proceedToServiceDates() {
        if createdTasks.isEmpty {
            withAnimation { currentStep = .completion }
        } else {
            let keyTasks = pickKeyTasks(from: createdTasks)
            for task in keyTasks {
                taskServiceDates[task.id] = ServiceDateEntry()
            }
            withAnimation { currentStep = .serviceDates }
        }
    }

    // MARK: - Service Dates

    private var serviceDatesView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 8) {
                        Text("When Were Things Last Done?")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("This helps us set accurate maintenance reminders. You can skip any you're not sure about.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    ForEach(Array(taskServiceDates.keys.sorted(by: { a, b in
                        let nameA = createdTasks.first(where: { $0.id == a })?.title ?? ""
                        let nameB = createdTasks.first(where: { $0.id == b })?.title ?? ""
                        return nameA < nameB
                    })), id: \.self) { taskId in
                        if let task = createdTasks.first(where: { $0.id == taskId }),
                           let entry = Binding(
                               get: { taskServiceDates[taskId] ?? ServiceDateEntry() },
                               set: { taskServiceDates[taskId] = $0 }
                           ) as Binding<ServiceDateEntry>? {
                            serviceDateRow(task: task, entry: entry)
                        }
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }

            // Bottom buttons
            VStack(spacing: 0) {
                Divider()
                VStack(spacing: 8) {
                    Button {
                        Task {
                            isSaving = true
                            await applyServiceDates()
                            isSaving = false
                            Haptics.success()
                            withAnimation { currentStep = .completion }
                        }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white)
                                Text("Saving...")
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save & Continue")
                            }
                        }
                        .font(HavenTypography.uiButton)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(HavenColors.navy)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                    .disabled(isSaving)

                    Button {
                        withAnimation { currentStep = .completion }
                    } label: {
                        Text("Skip — I'll update these later")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                .padding()
            }
            .background(HavenColors.cream)
        }
        .background(HavenColors.background)
    }

    private func serviceDateRow(task: MaintenanceTaskDBRow, entry: Binding<ServiceDateEntry>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(task.title)
                .font(HavenTypography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(HavenColors.textPrimary)

            Text("How often: \(task.frequency)")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)

            // Option picker
            HStack(spacing: 8) {
                serviceDateOptionButton(
                    label: "Enter date",
                    icon: "calendar",
                    isSelected: entry.wrappedValue.option == .date,
                    action: { entry.wrappedValue.option = .date }
                )
                serviceDateOptionButton(
                    label: "Don't know",
                    icon: "questionmark.circle",
                    isSelected: entry.wrappedValue.option == .dontKnow,
                    action: { entry.wrappedValue.option = .dontKnow }
                )
                serviceDateOptionButton(
                    label: "Never done",
                    icon: "exclamationmark.triangle",
                    isSelected: entry.wrappedValue.option == .never,
                    action: { entry.wrappedValue.option = .never }
                )
            }

            if entry.wrappedValue.option == .date {
                DatePicker(
                    "Last done",
                    selection: entry.date,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .font(HavenTypography.bodySmall)
            }
        }
        .padding()
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func serviceDateOptionButton(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.light()
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? HavenColors.navy.opacity(0.1) : Color.clear)
            .foregroundStyle(isSelected ? HavenColors.navy800 : HavenColors.textTertiary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? HavenColors.navy : HavenColors.beige300, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - System Option Model

struct SystemOption: Identifiable {
    let id = UUID()
    let name: String
    let systemName: String
    let category: String
    let icon: String
    let isCommon: Bool
    var isSelected: Bool

    var taskCount: Int {
        MaintenanceTemplates.essentialTemplates(for: category).count
    }

    static func defaultOptions() -> [SystemOption] {
        [
            // Common (pre-checked)
            SystemOption(name: "HVAC (Heating & Cooling)", systemName: "Central HVAC", category: "HVAC", icon: "thermometer.medium", isCommon: true, isSelected: true),
            SystemOption(name: "Plumbing", systemName: "Plumbing System", category: "Plumbing", icon: "drop.fill", isCommon: true, isSelected: true),
            SystemOption(name: "Roof & Gutters", systemName: "Roof", category: "Roofing", icon: "house.fill", isCommon: true, isSelected: true),
            SystemOption(name: "Electrical", systemName: "Electrical System", category: "Electrical", icon: "bolt.fill", isCommon: true, isSelected: true),
            SystemOption(name: "Water Heater", systemName: "Water Heater", category: "Water Heater", icon: "flame.fill", isCommon: true, isSelected: true),
            SystemOption(name: "Exterior & Siding", systemName: "Siding & Exterior", category: "Siding/Exterior", icon: "building.2.fill", isCommon: true, isSelected: true),
            SystemOption(name: "Windows", systemName: "Windows", category: "Windows", icon: "window.vertical.open", isCommon: true, isSelected: true),
            SystemOption(name: "Doors", systemName: "Exterior Doors", category: "Doors", icon: "door.left.hand.closed", isCommon: true, isSelected: true),
            SystemOption(name: "Appliances", systemName: "Kitchen & Laundry Appliances", category: "Appliance", icon: "refrigerator.fill", isCommon: true, isSelected: true),
            SystemOption(name: "Smoke & CO Detectors", systemName: "Smoke & Fire Protection", category: "Fire Protection", icon: "sensor.fill", isCommon: true, isSelected: true),
            SystemOption(name: "Landscaping", systemName: "Landscaping", category: "Landscaping", icon: "leaf.fill", isCommon: true, isSelected: true),
            SystemOption(name: "Pest Control", systemName: "Pest Control", category: "Pest Control", icon: "ant.fill", isCommon: true, isSelected: true),

            // Optional (unchecked)
            SystemOption(name: "Garage Door", systemName: "Garage Door", category: "Garage Door", icon: "door.garage.closed", isCommon: false, isSelected: false),
            SystemOption(name: "Pool / Spa", systemName: "Pool/Spa", category: "Pool/Spa", icon: "figure.pool.swim", isCommon: false, isSelected: false),
            SystemOption(name: "Septic System", systemName: "Septic System", category: "Septic System", icon: "arrow.down.to.line", isCommon: false, isSelected: false),
            SystemOption(name: "Well System", systemName: "Well System", category: "Well System", icon: "drop.circle.fill", isCommon: false, isSelected: false),
            SystemOption(name: "Generator", systemName: "Backup Generator", category: "Generator", icon: "bolt.batteryblock.fill", isCommon: false, isSelected: false),
            SystemOption(name: "Security System", systemName: "Security System", category: "Security System", icon: "lock.shield.fill", isCommon: false, isSelected: false),
            SystemOption(name: "Solar Panels", systemName: "Solar Panel System", category: "Solar", icon: "sun.max.fill", isCommon: false, isSelected: false),
            SystemOption(name: "Crawl Space / Basement", systemName: "Crawl Space / Basement", category: "Crawl Space", icon: "square.stack.3d.down.forward.fill", isCommon: false, isSelected: false),
            SystemOption(name: "Irrigation System", systemName: "Irrigation System", category: "Irrigation", icon: "sprinkler.and.droplets.fill", isCommon: false, isSelected: false),
            SystemOption(name: "Water Treatment / Softener", systemName: "Water Treatment System", category: "Water Treatment", icon: "water.waves", isCommon: false, isSelected: false),
        ]
    }
}

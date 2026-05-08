import SwiftUI

struct PropertySystemsInventoryView: View {
    let topLevelSystems: [HomeSystemRow]
    let highPrioritySystems: [HomeSystemRow]
    let groupedSystems: [SystemGroup]
    let completeProfileCount: Int
    let maintenanceLinkedCount: Int
    let recordStateLabel: String
    let recordSummary: String
    let recordSupportingSummary: String
    @Binding var searchText: String
    let searchResults: [HomeSystemRow]
    let groupSummary: (SystemGroup) -> String
    let priorityDetail: (HomeSystemRow) -> String
    let systemSummary: (HomeSystemRow) -> String
    let systemStatus: (HomeSystemRow) -> (title: String, color: Color)
    let iconForSystem: (HomeSystemRow) -> String
    let onAddSystem: () -> Void
    let onIdentifyPrioritySystems: () -> Void
    let onSelectSystem: (HomeSystemRow) -> Void
    let onSelectGroup: (SystemGroup) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HavenCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Systems")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("Home systems record")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(recordSummary)
                                .font(HavenTypography.body.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                        }

                        Spacer(minLength: 0)

                        systemsSummaryChip(
                            recordStateLabel,
                            color: !highPrioritySystems.isEmpty ? HavenColors.warning : HavenColors.navy700,
                            tint: !highPrioritySystems.isEmpty ? HavenColors.warning.opacity(0.12) : HavenColors.navy.opacity(0.08)
                        )
                    }

                    Text(
                        topLevelSystems.isEmpty
                            ? recordSupportingSummary
                            : "\(recordSupportingSummary). Chez uses these profiles to keep manuals, recalls, parts, warranties, and maintenance connected."
                    )
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                    if !topLevelSystems.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                systemsSummaryChip("\(topLevelSystems.count) mapped", color: HavenColors.navy700, tint: HavenColors.navy.opacity(0.08))
                                if !highPrioritySystems.isEmpty {
                                    systemsSummaryChip(
                                        "\(highPrioritySystems.count) priority setup",
                                        color: HavenColors.warning,
                                        tint: HavenColors.warning.opacity(0.12)
                                    )
                                }
                                if maintenanceLinkedCount > 0 {
                                    systemsSummaryChip(
                                        "\(maintenanceLinkedCount) linked to maintenance",
                                        color: HavenColors.navy700,
                                        tint: HavenColors.navy.opacity(0.08)
                                    )
                                }
                                if completeProfileCount > 0 {
                                    systemsSummaryChip(
                                        "\(completeProfileCount) profiles complete",
                                        color: HavenColors.success,
                                        tint: HavenColors.success.opacity(0.12)
                                    )
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        if topLevelSystems.isEmpty {
                            actionPill(title: "Add first system", filled: true, action: onAddSystem)
                        } else {
                            if !highPrioritySystems.isEmpty {
                                actionPill(title: "Identify priority systems", filled: true, action: onIdentifyPrioritySystems)
                            }
                            actionPill(title: "Add system", filled: false, action: onAddSystem)
                        }
                    }
                }
            }

            if !topLevelSystems.isEmpty {
                systemsSearchField
            }

            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    Text("Search results")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)

                    if searchResults.isEmpty {
                        HavenCard {
                            Text("No systems matched that search. Try a brand, model number, manual, part, or room name.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    } else {
                        ForEach(searchResults) { system in
                            systemRecordRow(
                                system,
                                subtitle: systemSummary(system),
                                status: systemStatus(system)
                            )
                        }
                    }
                }
            } else {
                if !highPrioritySystems.isEmpty {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        Text("Priority setup")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Start with the equipment that is expensive, safety-critical, or tied to upcoming service.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        ForEach(highPrioritySystems.prefix(3)) { system in
                            systemRecordRow(
                                system,
                                subtitle: priorityDetail(system),
                                status: ("Profile to finish", HavenColors.warning)
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    Text("Browse by category")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)

                    if groupedSystems.isEmpty {
                        HavenCard {
                            Text("Add HVAC, water systems, appliances, safety equipment, and more so Chez can build a complete equipment record for this home.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    } else {
                        ForEach(groupedSystems) { group in
                            categoryRow(group)
                        }
                    }
                }
            }
        }
    }

    private var systemsSearchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)

            TextField("Search systems, manuals, model numbers, parts...", text: $searchText)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
    }

    private func actionPill(title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(HavenTypography.uiLabel.weight(.semibold))
                .foregroundStyle(filled ? HavenColors.textOnNavy : HavenColors.navy700)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(filled ? HavenColors.navy800 : HavenColors.navy.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func systemsSummaryChip(_ title: String, color: Color, tint: Color) -> some View {
        Text(title)
            .font(HavenTypography.uiCaption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint)
            .clipShape(Capsule())
    }

    private func systemRecordRow(
        _ system: HomeSystemRow,
        subtitle: String,
        status: (title: String, color: Color)
    ) -> some View {
        Button {
            Haptics.light()
            onSelectSystem(system)
        } label: {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: iconForSystem(system))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 34, height: 34)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 5) {
                    Text(system.displayName)
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                    statusBadge(title: status.title, color: status.color)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func categoryRow(_ group: SystemGroup) -> some View {
        Button {
            Haptics.light()
            onSelectGroup(group)
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: group.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 34, height: 34)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(group.name)
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(groupSummary(group))
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func statusBadge(title: String, color: Color) -> some View {
        Text(title)
            .font(HavenTypography.uiCaption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct SmartRoutineSetupSheet: View {
    let context: SmartRoutineSetupContext
    let householdId: UUID
    let propertyId: UUID?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cadenceType: RoutineCadenceType
    @State private var customIntervalDays: Int
    @State private var selectedWeekdays: Set<Int>
    @State private var activeMonths: Set<Int>
    @State private var eveningBefore: Bool
    @State private var morningOf: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        context: SmartRoutineSetupContext,
        householdId: UUID,
        propertyId: UUID?,
        onSaved: @escaping () -> Void
    ) {
        self.context = context
        self.householdId = householdId
        self.propertyId = propertyId
        self.onSaved = onSaved
        _cadenceType = State(initialValue: context.draftPreset.cadenceType)
        _customIntervalDays = State(initialValue: context.draftPreset.customIntervalDays ?? 7)
        _selectedWeekdays = State(initialValue: context.draftPreset.selectedWeekdays)
        _activeMonths = State(initialValue: context.draftPreset.activeMonths)
        _eveningBefore = State(initialValue: context.defaultEveningBeforeReminder)
        _morningOf = State(initialValue: context.defaultMorningOfReminder)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        HStack(spacing: HavenTheme.spacing12) {
                            providerIcon

                            VStack(alignment: .leading, spacing: 4) {
                                Text(context.title)
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(context.subtitle)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Text(context.promptTitle)
                                .font(HavenTypography.uiLabel.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(context.promptBody)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if context.showsCadencePicker {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        operationalSectionHeader("CADENCE")

                        HavenCard {
                            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                                Picker("Cadence", selection: $cadenceType) {
                                    ForEach(context.allowedCadenceTypes, id: \.self) { cadence in
                                        Text(cadence.displayLabel).tag(cadence)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if cadenceType == .customDays {
                                    Stepper("Every \(customIntervalDays) days", value: $customIntervalDays, in: 7...120)
                                }
                            }
                        }
                    }
                }

                if showsWeekdayPicker {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        operationalSectionHeader(context.weekdaySectionTitle)

                        HavenCard {
                            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                                weekdayPicker
                                Text(context.weekdayHelperText)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                if context.showsActiveMonths {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        operationalSectionHeader("ACTIVE MONTHS")

                        HavenCard {
                            ActiveMonthsPicker(selectedMonths: $activeMonths)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    operationalSectionHeader("REMINDERS")

                    HavenCard {
                        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                            Toggle("Evening before", isOn: $eveningBefore)
                                .tint(HavenColors.action)
                            Toggle("Morning of", isOn: $morningOf)
                                .tint(HavenColors.action)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }
            }
            .padding(HavenTheme.spacing20)
        }
        .background(HavenColors.background)
        .navigationTitle(context.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text(context.ctaTitle).fontWeight(.semibold)
                    }
                }
                .disabled(isSaveDisabled || isSaving)
            }
        }
    }

    @ViewBuilder
    private var providerIcon: some View {
        if let vendor = context.draftPreset.selectedVendor {
            VendorLogoView(contractor: vendor, size: 44)
        } else if let utilityAccount = context.sourceUtilityAccount {
            VendorLogoView(
                logoUrl: utilityAccount.logoUrl,
                category: utilityAccount.providerType,
                vendorName: utilityAccount.providerName,
                size: 44
            )
        } else {
            Image(systemName: context.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(HavenColors.action)
                .frame(width: 44, height: 44)
                .background(HavenColors.action.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var showsWeekdayPicker: Bool {
        context.showsWeekdayPicker
            || [.weekly, .biweekly, .triweekly].contains(cadenceType)
    }

    private var isSaveDisabled: Bool {
        if showsWeekdayPicker && selectedWeekdays.isEmpty {
            return true
        }
        if context.showsActiveMonths && activeMonths.isEmpty {
            return true
        }
        return false
    }

    private var weekdayOptions: [(weekday: Int, label: String)] {
        [(1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")]
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
                        .foregroundStyle(
                            selectedWeekdays.contains(option.weekday)
                                ? HavenColors.textOnNavy
                                : HavenColors.textPrimary
                        )
                        .frame(width: 36, height: 36)
                        .background(
                            selectedWeekdays.contains(option.weekday)
                                ? HavenColors.navy
                                : HavenColors.beige200
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let anchorDate = formatter.string(from: context.draftPreset.startDate)

        var insert = RoutineInsert(
            householdId: householdId,
            propertyId: propertyId,
            label: context.title,
            routineKind: context.draftPreset.routineKind.rawValue,
            cadenceType: cadenceType.rawValue
        )
        insert.serviceKey = context.serviceKey
        insert.sourceUtilityAccountId = context.sourceUtilityAccount?.id
        insert.vendorId = context.draftPreset.selectedVendor?.id
        insert.icon = context.draftPreset.routineKind == .otherService
            ? MaintenanceHubIcon.icon(for: context.serviceKey)
            : context.draftPreset.routineKind.icon
        insert.cadenceIntervalDays = cadenceType == .customDays ? customIntervalDays : context.draftPreset.customIntervalDays
        insert.daysOfWeek = showsWeekdayPicker ? Array(selectedWeekdays).sorted() : nil
        insert.timeOfDay = context.draftPreset.hasTimeOfDay
            ? {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                return timeFormatter.string(from: context.draftPreset.timeOfDay)
            }()
            : nil
        insert.startDate = anchorDate
        insert.nextExpectedDate = anchorDate
        insert.activeMonths = Array(activeMonths).sorted()
        insert.eveningBeforeReminder = eveningBefore
        insert.morningOfReminder = morningOf
        insert.notes = context.draftPreset.notes.isEmpty ? nil : context.draftPreset.notes
        insert.cadenceSource = "smart_setup"
        insert.setupState = (context.sourceUtilityAccount != nil || insert.vendorId != nil || !context.draftPreset.routineKind.isVendorBased)
            ? RoutineSetupState.active.rawValue
            : RoutineSetupState.pendingVendor.rawValue

        do {
            let routine = try await DatabaseService.shared.createRoutine(insert)
            if let propertyId,
               routine.typedSetupState == .active,
               routine.typedScope == .property {
                _ = try? await RoutineGroupingEngine.linkVendorTasksToRoutine(
                    routine,
                    in: householdId,
                    propertyId: propertyId
                )
            }

            NotificationCenter.default.post(name: .routineChanged, object: nil)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            Haptics.success()
            onSaved()
            dismiss()
        } catch {
            errorMessage = "Couldn't save this setup: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}

struct PendingProgramSetupSheet: View {
    let bundle: PendingProgramBundleSummary
    let property: PropertyRow?
    let vendors: [ContractorRow]
    let onAssignedVendor: (ContractorRow, Bool) -> Void
    let onSearchLocally: (Bool) -> Void
    let onHandleMyself: (Bool) -> Void
    let onAskAlfred: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showVendorDirectory = false
    @State private var applyToRelatedPrograms = true

    private var hasPropertyLocation: Bool {
        guard let property else { return false }
        return !(property.city ?? "").isEmpty && !(property.state ?? "").isEmpty
    }

    private var locationLabel: String {
        guard let property else { return "near you" }
        let city = property.city ?? ""
        let state = property.state ?? ""
        if city.isEmpty || state.isEmpty { return "near you" }
        return "in \(city), \(state)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        HStack(spacing: HavenTheme.spacing12) {
                            Image(systemName: MaintenanceHubIcon.icon(for: bundle.primaryRoutine.resolvedServiceKey))
                                .font(.title2)
                                .foregroundStyle(HavenColors.action)
                                .frame(width: 44, height: 44)
                                .background(HavenColors.action.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(bundle.title)
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(bundle.subtitle)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        if bundle.routines.count > 1 {
                            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                                Toggle(isOn: $applyToRelatedPrograms) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Apply the same vendor to all \(bundle.routines.count) programs")
                                            .font(HavenTypography.uiLabel.weight(.semibold))
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Text("Good for pest + mosquito style programs that the same company often handles together.")
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                }
                                .tint(HavenColors.action)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    operationalSectionHeader("Programs you're setting up")

                    HavenCard {
                        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                            ForEach(bundle.routines) { routine in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(HavenColors.textTertiary)
                                        .frame(width: 5, height: 5)
                                        .offset(y: 7)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ServiceLibrary.homeownerTitle(for: routine))
                                            .font(HavenTypography.body)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        if !routine.nextExpectedDate.isEmpty {
                                            Text("Next up \(MaintenanceDateFormatting.shortDate(routine.nextExpectedDate))")
                                                .font(HavenTypography.caption)
                                                .foregroundStyle(HavenColors.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    operationalSectionHeader("Choose how to handle this")

                    actionCard(
                        icon: "person.2.fill",
                        title: "Choose from my contacts",
                        subtitle: vendors.isEmpty
                            ? "You can add a vendor from there too."
                            : "Pick someone you already use, or tap + there to add a new one.",
                        tint: HavenColors.navy700
                    ) {
                        showVendorDirectory = true
                    }

                    actionCard(
                        icon: "magnifyingglass.circle.fill",
                        title: "Search local pros",
                        subtitle: hasPropertyLocation
                            ? "Use our local search for \(bundle.vendorSearchCategory.lowercased()) \(locationLabel)."
                            : "Add a city and state to your property first, then search nearby pros.",
                        tint: HavenColors.action,
                        disabled: !hasPropertyLocation
                    ) {
                        dismissThen { onSearchLocally(applyToRelatedPrograms) }
                    }

                    actionCard(
                        icon: "person.fill",
                        title: "Handle it myself for now",
                        subtitle: "Keep the program active without putting a vendor on it yet.",
                        tint: HavenColors.success
                    ) {
                        dismissThen { onHandleMyself(applyToRelatedPrograms) }
                    }

                    actionCard(
                        icon: "sparkles",
                        title: "Ask Alfred",
                        subtitle: "Get advice on whether one vendor can cover the whole setup.",
                        tint: HavenColors.warning
                    ) {
                        dismissThen(onAskAlfred)
                    }
                }
            }
            .padding(HavenTheme.spacing20)
        }
        .background(HavenColors.background)
        .navigationTitle("Choose a vendor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showVendorDirectory) {
            NavigationStack {
                ContractorDirectoryView(onSelect: { contractor in
                    showVendorDirectory = false
                    dismissThen {
                        onAssignedVendor(contractor, applyToRelatedPrograms)
                    }
                })
            }
        }
        .onAppear {
            if bundle.routines.count <= 1 {
                applyToRelatedPrograms = false
            }
        }
    }

    private func actionCard(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.creamLight)
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .opacity(disabled ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func dismissThen(_ action: @escaping () -> Void) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            action()
        }
    }
}

struct MaintenanceYearPlanView: View {
    let seasons: [YearAtAGlanceCard.Season]
    let planForSeason: (YearAtAGlanceCard.Season) -> MaintenanceSeasonPlan
    let onTapPendingProgram: (PendingProgramBundleSummary) -> Void
    let onTapRoutine: (RoutineRow) -> Void
    let onTapService: (SeasonalServiceSummary) -> Void
    let onTapRoute: (SeasonalServiceSummary) -> Void
    let onOpenHandymanQueue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing32) {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        Text("Year plan")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Browse every season as a readiness plan, with what needs your decision, what Chez can bundle, and what is already covered.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                ForEach(seasons, id: \.self) { season in
                    let plan = planForSeason(season)
                    if !plan.pendingProgramBundles.isEmpty || !plan.activeRoutines.isEmpty || !plan.services.isEmpty {
                        seasonBlock(season: season, plan: plan)
                    }
                }
            }
            .padding(HavenTheme.spacing20)
        }
        .background(HavenColors.background)
        .navigationTitle("Year Plan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func seasonBlock(
        season: YearAtAGlanceCard.Season,
        plan: MaintenanceSeasonPlan
    ) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            HStack(spacing: 8) {
                Image(systemName: season.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(season.iconColor)
                Text(season.displayLabel)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Text("\(plan.pendingProgramBundles.count + plan.activeRoutines.count + plan.services.count)")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            if !plan.pendingProgramBundles.isEmpty {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    operationalSectionHeader("Needs a vendor")
                    VStack(spacing: HavenTheme.spacing8) {
                        ForEach(plan.pendingProgramBundles) { bundle in
                            pendingBundleRow(bundle)
                        }
                    }
                }
            }

            if !plan.activeRoutines.isEmpty {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    operationalSectionHeader("Covered programs")
                    VStack(spacing: HavenTheme.spacing8) {
                        ForEach(plan.activeRoutines) { routine in
                            routineRow(routine, accent: HavenColors.beige200)
                        }
                    }
                }
            }

            if !plan.services.isEmpty {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    operationalSectionHeader("Seasonal tasks")
                    VStack(spacing: HavenTheme.spacing12) {
                        ForEach(plan.services) { service in
                            serviceRow(service)
                        }
                    }
                }
            }

            if plan.services.contains(where: { if case .handymanRecommended = $0.status { return true } else { return false } }) {
                Button {
                    onOpenHandymanQueue()
                } label: {
                    Text("Review contractor bundle")
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(HavenColors.navy700.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func routineRow(_ routine: RoutineRow, accent: Color) -> some View {
        Button {
            onTapRoutine(routine)
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: routine.resolvedIcon)
                    .font(.title3)
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 36, height: 36)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(ServiceLibrary.homeownerTitle(for: routine))
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(routine.nextExpectedDate.isEmpty ? "Recurring program" : "Next \(MaintenanceDateFormatting.shortDate(routine.nextExpectedDate))")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    private func pendingBundleRow(_ bundle: PendingProgramBundleSummary) -> some View {
        Button {
            onTapPendingProgram(bundle)
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: MaintenanceHubIcon.icon(for: bundle.primaryRoutine.resolvedServiceKey))
                    .font(.title3)
                    .foregroundStyle(HavenColors.action)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.action.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(bundle.title)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(bundle.subtitle.replacingOccurrences(of: "Pick a pro", with: "Choose a vendor"))
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    private func serviceRow(_ service: SeasonalServiceSummary) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Button {
                    onTapService(service)
                } label: {
                    HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                        Image(systemName: MaintenanceHubIcon.icon(for: service.serviceKey))
                            .font(.title3)
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 38, height: 38)
                            .background(HavenColors.beige200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(service.title)
                                .font(HavenTypography.body.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                                .multilineTextAlignment(.leading)
                            Text(service.dueLabel)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                            Text(service.ownershipSummary)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                            if service.includedCount > 1 {
                                Text("\(service.includedCount) tasks included")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }

                        Spacer(minLength: 0)

                        Text(service.statusLabel)
                            .font(HavenTypography.uiCaption.weight(.semibold))
                            .foregroundStyle(serviceTint(for: service.status))
                    }
                }
                .buttonStyle(.plain)

                if service.needsAttention {
                    HStack {
                        Spacer()
                        Button {
                            onTapRoute(service)
                        } label: {
                            Text(service.ctaTitle)
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                .foregroundStyle(HavenColors.navy700)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .overlay(
                                    Capsule()
                                        .stroke(HavenColors.navy.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

@ViewBuilder
private func operationalSectionHeader(_ title: String) -> some View {
    Text(title)
        .font(HavenTypography.uiSectionHeader)
        .tracking(1.5)
        .foregroundStyle(HavenColors.textTertiary)
}

private func serviceTint(for status: SeasonalServiceSummary.Status) -> Color {
    switch status {
    case .needsRouting:
        return HavenColors.action
    case .handymanRecommended:
        return HavenColors.navy700
    case .vendorAssigned:
        return HavenColors.success
    case .diy:
        return HavenColors.textSecondary
    }
}

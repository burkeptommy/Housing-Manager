import SwiftUI

/// 3-step flow to create a recurring vendor service (standing appointment).
/// Step 1: Pick or create a service (home system)
/// Step 2: Pick or add a vendor (contractor)
/// Step 3: Set frequency, start date, seasonal toggle
struct AddRecurringServiceSheet: View {
    let propertyId: UUID
    let householdId: UUID
    var preselectedSystem: HomeSystemRow?
    var preselectedContractor: ContractorRow?
    var onComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var standingVM = StandingAppointmentViewModel()

    // Data loaded on appear
    @State private var loadedSystems: [HomeSystemRow] = []
    @State private var loadedContractors: [ContractorRow] = []

    // Navigation state
    @State private var currentStep = 1

    // Step 1: Service
    @State private var selectedSystem: HomeSystemRow?
    @State private var isCreatingNewSystem = false
    @State private var newSystemName = ""
    @State private var newSystemCategory = "Other"

    // Step 2: Vendor
    @State private var selectedContractor: ContractorRow?
    @State private var showAddVendorSheet = false

    /// Deduped top-level systems (one per category, preferring named ones)
    private var dedupedSystems: [HomeSystemRow] {
        var seen = Set<String>()
        return loadedSystems
            .filter { $0.parentSystemId == nil }
            .sorted { $0.name < $1.name }
            .filter { seen.insert($0.category).inserted }
    }

    // Step 3: Schedule
    @State private var selectedCadence = "biweekly"
    @State private var customIntervalDays = 14
    @State private var startDate = Date()
    @State private var isSeasonal = false
    @State private var seasonalPauseMonths: Set<Int> = []
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var serviceDescription = ""

    // State
    @State private var isSaving = false
    @State private var error: String?

    private let cadenceOptions: [(label: String, value: String)] = [
        ("Weekly", "weekly"),
        ("Every 2 weeks", "biweekly"),
        ("Monthly", "monthly"),
        ("Every 2 months", "bimonthly"),
        ("Quarterly", "quarterly"),
        ("Semi-annually", "semiannual"),
        ("Annually", "annual"),
        ("Custom", "custom_days"),
    ]

    private let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                              "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressBar

                ScrollView {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                        switch currentStep {
                        case 1: step1Service
                        case 2: step2Vendor
                        case 3: step3Schedule
                        default: EmptyView()
                        }
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.top, HavenTheme.spacing16)
                    .padding(.bottom, HavenTheme.spacing48)
                }

                // Bottom bar
                bottomBar
            }
            .background(HavenColors.background)
            .navigationTitle("Add Recurring Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if currentStep > 1 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                                    .font(HavenTypography.uiLabel)
                            }
                            .foregroundStyle(HavenColors.navy800)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(HavenColors.beige200)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showAddVendorSheet) {
                AddVendorSheet(onComplete: {
                    // Reload contractors to pick up the newly added one
                    Task { await loadData() }
                })
            }
            .task { await loadData() }
        }
    }

    private func loadData() async {
        do {
            loadedSystems = try await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId)
            loadedContractors = (try? await DatabaseService.shared.fetchContractors()) ?? []

            // If preselected, auto-fill steps 1-2 and jump to step 3
            if let system = preselectedSystem {
                selectedSystem = system
                if let contractor = preselectedContractor {
                    selectedContractor = contractor
                }
                currentStep = 3
            }
        } catch {
            print("[AddRecurringService] Failed to load data: \(error)")
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? HavenColors.navy800 : HavenColors.beige200)
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.vertical, 8)
    }

    // MARK: - Step 1: Service

    private var step1Service: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            Text("What service is this for?")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)

            // Existing systems (deduped by category)
            if !dedupedSystems.isEmpty {
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(dedupedSystems) { system in
                        Button {
                            Haptics.light()
                            selectedSystem = system
                            isCreatingNewSystem = false
                        } label: {
                            systemChip(system)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Create new
            Divider().foregroundStyle(HavenColors.beige200)

            Button {
                Haptics.light()
                isCreatingNewSystem = true
                selectedSystem = nil
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(HavenColors.navy700)
                    Text("Add new service")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy700)
                    Spacer()
                    if isCreatingNewSystem {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HavenColors.navy800)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if isCreatingNewSystem {
                VStack(spacing: HavenTheme.spacing12) {
                    HavenTextField(title: "Service name", text: $newSystemName)
                    Picker("Category", selection: $newSystemCategory) {
                        ForEach(SystemCategory.allCases.map(\.rawValue).sorted(), id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(HavenColors.navy800)
                }
                .padding(.leading, 26)
                .transition(.opacity)
            }
        }
    }

    private func systemChip(_ system: HomeSystemRow) -> some View {
        let isSelected = selectedSystem?.id == system.id
        return HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: VendorLogoView.categorySymbol(for: system.category) ?? "wrench.and.screwdriver")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isSelected ? HavenColors.textOnNavy : HavenColors.navy)
                .frame(width: 32, height: 32)
                .background(isSelected ? HavenColors.navy800 : HavenColors.navy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(system.name)
                .font(HavenTypography.headline)
                .foregroundStyle(isSelected ? HavenColors.navy800 : HavenColors.textPrimary)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.navy800)
            }
        }
        .padding(.vertical, HavenTheme.spacing8)
        .padding(.horizontal, HavenTheme.spacing12)
        .background(isSelected ? HavenColors.navy.opacity(0.06) : HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(isSelected ? HavenColors.navy800 : HavenColors.border, lineWidth: isSelected ? 2 : 1)
        )
    }

    // MARK: - Step 2: Vendor

    private var step2Vendor: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            Text("Who provides this service?")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)

            if !loadedContractors.isEmpty {
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(loadedContractors) { contractor in
                        Button {
                            Haptics.light()
                            selectedContractor = contractor
                        } label: {
                            vendorChip(contractor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().foregroundStyle(HavenColors.beige200)

            Button {
                Haptics.light()
                showAddVendorSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(HavenColors.navy700)
                    Text("Add a vendor")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy700)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            Button {
                Haptics.light()
                selectedContractor = nil
                withAnimation { currentStep = 3 }
            } label: {
                Text("Skip for now")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private func vendorChip(_ contractor: ContractorRow) -> some View {
        let isSelected = selectedContractor?.id == contractor.id
        return HStack(spacing: HavenTheme.spacing12) {
            VendorLogoView(contractor: contractor, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(contractor.companyName)
                    .font(HavenTypography.headline)
                    .foregroundStyle(isSelected ? HavenColors.navy800 : HavenColors.textPrimary)
                if let category = contractor.category {
                    Text(category)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.navy800)
            }
        }
        .padding(.vertical, HavenTheme.spacing8)
        .padding(.horizontal, HavenTheme.spacing12)
        .background(isSelected ? HavenColors.navy.opacity(0.06) : HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(isSelected ? HavenColors.navy800 : HavenColors.border, lineWidth: isSelected ? 2 : 1)
        )
    }

    // MARK: - Step 3: Schedule

    private var step3Schedule: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
            Text("How often do they come?")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)

            // Cadence chips (2-column grid)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HavenTheme.spacing8) {
                ForEach(cadenceOptions, id: \.value) { option in
                    Button {
                        Haptics.light()
                        selectedCadence = option.value
                    } label: {
                        Text(option.label)
                            .font(.custom("Inter", size: 13).weight(.semibold))
                            .foregroundStyle(selectedCadence == option.value ? HavenColors.textOnNavy : HavenColors.navy800)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedCadence == option.value ? HavenColors.navy800 : HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                            .overlay(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                    .stroke(selectedCadence == option.value ? HavenColors.navy800 : HavenColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Custom interval stepper (when Custom selected)
            if selectedCadence == "custom_days" {
                HStack {
                    Text("Every")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Stepper("\(customIntervalDays) days", value: $customIntervalDays, in: 1...365)
                        .font(HavenTypography.body)
                }
                .padding(.horizontal, HavenTheme.spacing12)
            }

            // Start date
            VStack(alignment: .leading, spacing: 4) {
                Text("START DATE")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            // Seasonal toggle
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Toggle(isOn: $isSeasonal) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Seasonal service")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Pauses during off-season months")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                .tint(HavenColors.navy800)
                .onChange(of: isSeasonal) { _, newVal in
                    if newVal && seasonalPauseMonths.isEmpty {
                        loadDefaultPauseMonths()
                    }
                }

                if isSeasonal {
                    // Month chips
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 6) {
                        ForEach(1...12, id: \.self) { month in
                            Button {
                                if seasonalPauseMonths.contains(month) {
                                    seasonalPauseMonths.remove(month)
                                } else {
                                    seasonalPauseMonths.insert(month)
                                }
                            } label: {
                                Text(monthNames[month - 1])
                                    .font(.custom("Inter", size: 11).weight(.semibold))
                                    .foregroundStyle(seasonalPauseMonths.contains(month) ? HavenColors.textOnAction : HavenColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(seasonalPauseMonths.contains(month) ? HavenColors.navy800.opacity(0.7) : HavenColors.beige200)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("Highlighted months are paused")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            // Optional end date
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Toggle("Service has an end date", isOn: $hasEndDate)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .tint(HavenColors.navy800)

                if hasEndDate {
                    DatePicker("Ends on", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .font(HavenTypography.body)
                        .datePickerStyle(.compact)
                }
            }

            // Optional description
            VStack(alignment: .leading, spacing: 4) {
                Text("DESCRIPTION (OPTIONAL)")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                HavenTextField(title: "e.g., Blue Fox biweekly landscaping", text: $serviceDescription)
            }

            if let error {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().foregroundStyle(HavenColors.beige200)
            HStack {
                if currentStep < 3 {
                    Button {
                        Haptics.medium()
                        withAnimation { currentStep += 1 }
                    } label: {
                        Text("Continue")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.textOnNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canProceed ? HavenColors.navy800 : HavenColors.beige300)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canProceed)
                } else {
                    Button {
                        Haptics.medium()
                        saveService()
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView().controlSize(.small).tint(.white)
                            }
                            Text("Start Service")
                                .font(HavenTypography.uiButton)
                        }
                        .foregroundStyle(HavenColors.textOnNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(HavenColors.navy800)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, HavenTheme.spacing12)
        }
        .background(HavenColors.surface)
    }

    // MARK: - Logic

    private var canProceed: Bool {
        switch currentStep {
        case 1: return selectedSystem != nil || (isCreatingNewSystem && !newSystemName.isEmpty)
        case 2: return true // Vendor is optional (skip for now)
        default: return true
        }
    }

    private func loadDefaultPauseMonths() {
        let category = selectedSystem?.category ?? newSystemCategory
        Task {
            if let defaults = try? await DatabaseService.shared.fetchCadenceDefault(category: category.lowercased()) {
                if let months = defaults.seasonalPauseMonths {
                    seasonalPauseMonths = Set(months)
                }
            }
        }
    }

    private func saveService() {
        isSaving = true
        error = nil

        Task {
            do {
                // Step 1: Ensure system exists
                let systemId: UUID
                if let existing = selectedSystem {
                    systemId = existing.id
                } else {
                    let newSystem = try await DatabaseService.shared.createHomeSystem(HomeSystemInsert(
                        propertyId: propertyId,
                        householdId: householdId,
                        name: newSystemName,
                        category: newSystemCategory
                    ))
                    systemId = newSystem.id
                }

                // Step 2: Build description
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let startDateStr = formatter.string(from: startDate)

                let cadenceLabel = cadenceOptions.first(where: { $0.value == selectedCadence })?.label ?? selectedCadence
                let vendorName = selectedContractor?.companyName
                let systemName = selectedSystem?.name ?? newSystemName
                let autoDescription = serviceDescription.isEmpty
                    ? [vendorName, cadenceLabel.lowercased(), systemName].compactMap { $0 }.joined(separator: " ")
                    : serviceDescription

                // Step 3: Determine interval
                let intervalDays: Int?
                if selectedCadence == "custom_days" {
                    intervalDays = customIntervalDays
                } else {
                    intervalDays = nil
                }

                // Step 4: Create standing appointment with visits
                _ = try await standingVM.createAppointment(
                    householdId: householdId,
                    propertyId: propertyId,
                    vendorId: selectedContractor?.id,
                    systemId: systemId,
                    cadenceType: selectedCadence,
                    cadenceIntervalDays: intervalDays,
                    cadenceSource: "user_set",
                    serviceDescription: autoDescription,
                    startDate: startDateStr,
                    seasonalPauseMonths: isSeasonal ? Array(seasonalPauseMonths) : nil
                )

                // Step 5: Link vendor to system if selected
                if let contractorId = selectedContractor?.id {
                    _ = try? await DatabaseService.shared.updateHomeSystem(
                        id: systemId,
                        HomeSystemUpdate(preferredContractorId: contractorId)
                    )
                }

                // Step 6: Link existing vendor tasks to the standing appointment,
                // or create a task if none exist. This ensures the recurring service
                // appears in the Scheduled bucket.
                let appointments = (try? await DatabaseService.shared.fetchStandingAppointments(householdId: householdId)) ?? []
                if let appt = appointments.first(where: { $0.systemId == systemId && $0.archivedAt == nil }) {
                    let existingTasks = (try? await DatabaseService.shared.fetchMaintenanceTasks(systemId: systemId)) ?? []
                    let vendorTasks = existingTasks.filter { $0.assignmentType?.lowercased() == "vendor" && $0.isArchived != true }

                    // Filter to only link ONGOING tasks, not seasonal one-offs
                    // (spring cleanup, fall cleanup, etc. are one-time, not recurring).
                    let seasonalKeywords = ["spring", "fall", "winter", "summer",
                                            "startup", "opening", "closing", "winteriz"]
                    let ongoingTasks = vendorTasks.filter { task in
                        let titleLower = task.title.lowercased()
                        return !seasonalKeywords.contains(where: { titleLower.contains($0) })
                    }

                    if ongoingTasks.isEmpty {
                        // No ongoing vendor task exists — create one as the recurring anchor
                        let taskInsert = MaintenanceTaskInsert(
                            propertyId: propertyId,
                            householdId: householdId,
                            title: autoDescription,
                            frequency: cadenceLabel,
                            nextDueDate: startDateStr,
                            systemId: systemId,
                            description: "Recurring \(cadenceLabel.lowercased()) service",
                            priority: "Medium",
                            assignedContractorId: selectedContractor?.id,
                            assignmentType: "vendor",
                            scheduledDate: startDateStr,
                            standingAppointmentId: appt.id
                        )
                        _ = try? await DatabaseService.shared.createMaintenanceTask(taskInsert)
                    } else {
                        // Link ongoing vendor tasks to the appointment + sync dates
                        for task in ongoingTasks {
                            _ = try? await DatabaseService.shared.updateMaintenanceTask(
                                id: task.id,
                                MaintenanceTaskUpdate(
                                    nextDueDate: startDateStr,
                                    scheduledDate: startDateStr,
                                    standingAppointmentId: appt.id
                                )
                            )
                        }
                    }
                }

                await MainActor.run {
                    isSaving = false
                    Haptics.success()
                    Analytics.track(.specialtySystemAdded, ["source": "recurring_service_sheet", "cadence": selectedCadence])
                    onComplete?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    self.error = "Failed to create service. Please try again."
                    Haptics.error()
                }
            }
        }
    }
}

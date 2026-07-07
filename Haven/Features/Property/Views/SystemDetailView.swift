import SwiftUI

/// Detail view for a HomeSystemRow from the database.
struct SystemDetailRowView: View {
    private struct ProfileChecklistItem: Identifiable {
        let id: String
        let title: String
        let detail: String
    }

    let initialSystem: HomeSystemRow
    @State private var system: HomeSystemRow
    @State private var warranties: [WarrantyRow] = []

    init(system: HomeSystemRow) {
        self.initialSystem = system
        _system = State(initialValue: system)
    }
    @State private var tasks: [MaintenanceTaskDBRow] = []
    @State private var records: [ServiceRecordRow] = []
    @State private var preferredContractor: ContractorRow?
    @State private var isLoading = true
    @State private var selectedTask: MaintenanceTaskDBRow?
    @State private var showContractorPicker = false
    @State private var showAlfredChat = false
    @State private var showAlfredSystemChat = false
    @State private var isAddingQuickTask = false
    @State private var linkedDocuments: [DocumentRow] = []
    @State private var showDocumentUpload = false
    @State private var showAddWarranty = false
    @State private var showEquipmentIdentify = false
    @State private var catalogLinked = false
    @State private var showEditSystem = false
    @State private var showDeleteConfirm = false
    @State private var showManageTasks = false
    @State private var showHandymanPunchList = false
    @State private var showResetTemplatesConfirm = false
    @State private var manualLinks: [ManualLink] = []
    @State private var childSystems: [HomeSystemRow] = []
    @State private var contractorsById: [UUID: ContractorRow] = [:]
    @State private var systemStatusToast: String?
    @State private var isAddingTaskToHandyman = false
    @State private var equipmentScore: EquipmentDetailScore?
    @State private var catalogDetails: CatalogDetails?
    /// Phase 50: Toggles the FrequencyPickerSheet.
    @State private var showFrequencyPicker = false
    /// Phase 84 — local mirror for ChezOwnsToggle's Binding. Seeded from
    /// the system on first appear; flips before the network call so the
    /// UI feels immediate.
    @State private var chezOwnedLocal: Bool = false
    @Environment(\.dismiss) private var dismiss

    private let db = DatabaseService.shared
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var hasBasicSystemIdentity: Bool {
        !(system.manufacturer?.isEmpty ?? true)
            || !(system.modelNumber?.isEmpty ?? true)
            || !(system.serialNumber?.isEmpty ?? true)
    }

    private var shouldShowIdentifyPrompt: Bool {
        !catalogLinked || (system.serialNumber?.isEmpty ?? true) || (system.installDate?.isEmpty ?? true)
    }

    private var hasProfileSetupNeeds: Bool {
        !missingProfileChecklist.isEmpty
    }

    /// Service-typed rows (pet waste, snow removal, pest control, etc.)
    /// are recurring vendor visits, not equipment. They have no brand,
    /// model, serial, install date, manuals, or label photo. The detail
    /// page suppresses every equipment-shaped card and surfaces only
    /// the vendor + tasks + history. New service rows are created as
    /// routines in the Services section; legacy `home_systems` rows
    /// from earlier builds may still resolve here via deep links, so
    /// the gate below is defensive.
    private var isServiceCategory: Bool {
        SystemGroup.isServiceCategory(system.category)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                if !isServiceCategory && hasProfileSetupNeeds {
                    profileSetupCard
                }
                if !isServiceCategory {
                    if system.manufacturer != nil {
                        brandCard
                            .onTapGesture {
                                Haptics.light()
                                showEditSystem = true
                            }
                    } else {
                        systemInfoCard
                    }
                }
                if !isServiceCategory && equipmentScore != nil && system.manufacturer == nil { reliabilityCard }
                if !isServiceCategory && !hasProfileSetupNeeds && shouldShowIdentifyPrompt {
                    identifyEquipmentCard
                }
                if !isServiceCategory && !manualLinks.isEmpty { manualsCard }
                if !isServiceCategory { componentsCard }
                preferredVendorCard
                chezOwnsCard
                askAlfredCard
                maintenanceCard
                serviceRecordsCard
                warrantiesCard
                documentsCard
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, HavenTheme.spacing16)
        }
        .background(HavenColors.background)
        .overlay(alignment: .top) {
            if let systemStatusToast {
                Text(systemStatusToast)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(.white)
                    .padding(.horizontal, HavenTheme.spacing16)
                    .padding(.vertical, HavenTheme.spacing8)
                    .background(HavenColors.navy800)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle(system.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditSystem = true } label: {
                        Label("Edit System", systemImage: "pencil")
                    }
                    Button { showManageTasks = true } label: {
                        Label("Manage Tasks", systemImage: "checklist")
                    }
                    Button { showResetTemplatesConfirm = true } label: {
                        Label("Reset Templates", systemImage: "arrow.clockwise")
                    }
                    Divider()
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete System", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(HavenColors.navy700)
                }
            }
        }
        .alert("Delete System", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await deleteSystem() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(system.name)\" and all its maintenance tasks, warranties, and service records.")
        }
        .sheet(isPresented: $showManageTasks) {
            ManageSystemTasksSheet(
                system: system,
                tasks: tasks,
                onDelete: { ids in
                    await bulkDeleteTasks(ids: ids)
                },
                onTaskAdded: { newTask in
                    // Phase 19 polish: keep the parent's task list in sync
                    // when a custom task is added inside the sheet so the
                    // SystemDetailView's task list reflects the addition
                    // without needing a full reload.
                    await MainActor.run {
                        tasks.append(newTask)
                    }
                }
            )
        }
        .confirmationDialog(
            "Reset templates for this system?",
            isPresented: $showResetTemplatesConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                Task { await resetTemplates() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes template-based tasks and re-creates them from the catalog using this system's current settings. Custom tasks are kept.")
        }
        .trackScreen("SystemDetailView", properties: ["system_id": system.id.uuidString, "category": system.category])
        .task {
            await loadDetails()
        }
        .sheet(item: $selectedTask, onDismiss: {
            Task { await loadDetails() }
        }) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(
                    task: task,
                    onTaskCompleted: {
                        Task { await loadDetails() }
                    },
                    onDeleteTask: {
                        Task { await loadDetails() }
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showContractorPicker) {
            ContractorPickerSheet(systemCategory: system.category) { contractor in
                Task { await assignContractor(contractor) }
            }
        }
        .sheet(isPresented: $showHandymanPunchList) {
            NavigationStack {
                HandymanPunchListView(
                    householdId: system.householdId,
                    propertyId: system.propertyId
                )
            }
        }
        .sheet(isPresented: $showAlfredChat) {
            NavigationStack {
                ChatView(
                    contextType: "property",
                    contextId: system.propertyId,
                    initialPrompt: "I need a \(system.category) contractor. Can you help me find one?"
                )
            }
        }
        .sheet(isPresented: $showAlfredSystemChat) {
            NavigationStack {
                ChatView(
                    contextType: "system",
                    contextId: system.id,
                    systemContext: buildSystemContext()
                )
            }
        }
        .sheet(isPresented: $showDocumentUpload) {
            DocumentUploadView(preselectedPropertyId: system.propertyId) {
                Task { await loadDetails() }
            }
        }
        .sheet(isPresented: $showAddWarranty) {
            NavigationStack {
                AddWarrantySheet(systemId: system.id, householdId: nil, onComplete: { newWarranty in
                    warranties.append(newWarranty)
                    Analytics.track(.warrantyCreated, ["system_id": system.id.uuidString, "source": "system_detail"])
                    Task { await loadDetails() }
                })
            }
        }
        .sheet(isPresented: $showEquipmentIdentify) {
            EquipmentIdentifySheet(systemCategory: system.category) { result, serialNumber in
                Task { await linkEquipment(result, serialNumber: serialNumber) }
            }
        }
        .sheet(isPresented: $showEditSystem) {
            EditSystemSheet(system: system) { updatedSystem in
                system = updatedSystem
                Task { await reloadSystem() }
            }
        }
        // Phase 50: System frequency editor sheet.
        .sheet(isPresented: $showFrequencyPicker) {
            FrequencyPickerSheet(
                system: system,
                initialInterval: system.serviceIntervalDays,
                initialSource: system.serviceIntervalSource,
                onSave: { intervalDays, applyToAll in
                    Task { await applyServiceInterval(days: intervalDays, applyToExistingTasks: applyToAll) }
                },
                onClearOverride: {
                    Task { await clearServiceIntervalOverride() }
                }
            )
        }
    }

    // MARK: - Identify Equipment Card

    private var profileSetupCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.warning)
                        .frame(width: 36, height: 36)
                        .background(HavenColors.warning.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profile to finish")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(profileSetupHeadline)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Text("Setup in progress")
                        .font(HavenTypography.uiCaption.weight(.semibold))
                        .foregroundStyle(HavenColors.warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(HavenColors.warning.opacity(0.12))
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(missingProfileChecklist.prefix(4)) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(HavenColors.warning)
                                .padding(.top, 7)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(HavenTypography.uiLabel.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(item.detail)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    if missingProfileChecklist.count > 4 {
                        Text("+ \(missingProfileChecklist.count - 4) more detail\(missingProfileChecklist.count - 4 == 1 ? "" : "s") to add")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                Text(profileSetupHelperText)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button {
                        Haptics.light()
                        if shouldLeadWithPhotoCapture {
                            showEquipmentIdentify = true
                        } else {
                            showEditSystem = true
                        }
                    } label: {
                        Text(primaryProfileActionTitle)
                            .font(HavenTypography.uiLabel.weight(.semibold))
                            .foregroundStyle(HavenColors.textOnNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(HavenColors.navy800)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.light()
                        if shouldLeadWithPhotoCapture {
                            showEditSystem = true
                        } else {
                            showEquipmentIdentify = true
                        }
                    } label: {
                        Text(secondaryProfileActionTitle)
                            .font(HavenTypography.uiLabel.weight(.semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(HavenColors.navy.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var identifyEquipmentCard: some View {
        Button {
            Haptics.light()
            showEquipmentIdentify = true
        } label: {
            HavenCard {
                HStack(spacing: 12) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 44, height: 44)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(identifyEquipmentTitle)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(identifyEquipmentSubtitle)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var identifyEquipmentTitle: String {
        if !hasBasicSystemIdentity {
            return "Identify this equipment"
        }
        if (system.serialNumber?.isEmpty ?? true) || (system.installDate?.isEmpty ?? true) {
            return "Finish identifying this system"
        }
        return "Update system info"
    }

    private var identifyEquipmentSubtitle: String {
        if !hasBasicSystemIdentity {
            return "Take a label photo to find manuals, specs, lifespan, and maintenance tips."
        }
        if (system.serialNumber?.isEmpty ?? true) || (system.installDate?.isEmpty ?? true) {
            return "We still need details like the serial number or install date."
        }
        return "Retake the label photo or edit details if anything changed."
    }

    private var primaryProfileActionTitle: String {
        shouldLeadWithPhotoCapture ? "Take label photo" : "Enter details"
    }

    private var secondaryProfileActionTitle: String {
        shouldLeadWithPhotoCapture ? "Enter details" : "Take label photo"
    }

    private var profileSetupHeadline: String {
        "Chez still needs \(missingProfileChecklist.count) detail\(missingProfileChecklist.count == 1 ? "" : "s") before this system record is complete."
    }

    private var profileSetupHelperText: String {
        if shouldLeadWithPhotoCapture {
            return "Fastest path: take a label photo. Chez can usually fill in brand, model, manuals, parts, and other key specs automatically."
        }
        return "Manual entry is the fastest path for this system. Add the missing details and Chez will keep maintenance, manuals, and service history connected."
    }

    private var shouldLeadWithPhotoCapture: Bool {
        missingProfileChecklist.contains { item in
            ["brand", "model", "serial", "fuel-type", "catalog-match", "panel-brand"].contains(item.id)
        }
    }

    /// Delegates to `SystemProfileAudit.missingItems` so the SAME
    /// per-category logic drives both the in-page "Profile to finish"
    /// checklist and the Overview "Systems missing profile" sheet.
    /// One source of truth — adding a new category means editing
    /// `SystemProfileAudit` once.
    private var missingProfileChecklist: [ProfileChecklistItem] {
        SystemProfileAudit.missingItems(
            for: system,
            warranties: warranties,
            serviceRecords: records,
            catalogLinked: catalogLinked,
            manualLinkCount: manualLinks.count
        ).map { ProfileChecklistItem(id: $0.id, title: $0.title, detail: $0.detail) }
    }

    private func containsAny(_ source: String, _ keywords: [String]) -> Bool {
        keywords.contains { source.contains($0) }
    }

    // MARK: - Link Equipment to Catalog

    private func linkEquipment(_ result: EquipmentSearchResult, serialNumber: String?) async {
        do {
            var updates = HomeSystemUpdate()
            updates.catalogEntryId = result.id
            updates.manufacturer = result.manufacturer.name
            updates.modelNumber = result.modelNumber
            if let serial = serialNumber { updates.serialNumber = serial }
            if let lifespan = result.specs.expectedLifespanYears { updates.expectedLifespanYears = lifespan }
            // Also update the name to include the proper display name
            updates.name = result.displayName
            _ = try await db.updateHomeSystem(id: system.id, updates)
            Haptics.success()
            Analytics.track(.systemIdentified, [
                "system_id": system.id.uuidString,
                "catalog_model": result.modelNumber,
                "manufacturer": result.manufacturer.name,
                "method": serialNumber != nil ? "photo" : "search",
            ])
            // Reload system data to show updated brand card immediately
            await reloadSystem()
            await MainActor.run { catalogLinked = true }
        } catch {
            print("[SystemDetail] Failed to link equipment: \(error)")
        }
    }

    // MARK: - Delete System

    private func deleteSystem() async {
        do {
            try await db.deleteHomeSystem(id: system.id)
            await MainActor.run {
                Haptics.success()
                dismiss()
            }
        } catch {
            print("[SystemDetail] Failed to delete system: \(error)")
        }
    }

    // MARK: - Brand Card (enhanced with series, features, website)

    private var brandCard: some View {
        let brand = system.manufacturer ?? ""
        let brandColor = BrandTheme.color(for: brand) ?? HavenColors.navy700
        let score = equipmentScore?.reliability
        let series = catalogDetails?.series ?? deriveSeries()
        let features = catalogDetails?.keyFeatures ?? []

        return VStack(spacing: 0) {
            ZStack {
                // Gradient background with brand accent
                LinearGradient(
                    colors: [brandColor.opacity(0.10), HavenColors.creamLight.opacity(0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: HavenTheme.spacing16) {
                    // Top: Logo + Brand + Series + Score
                    HStack(spacing: 14) {
                        AppliancesListView.brandLogoView(brand, size: 48)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(brand)
                                .font(HavenTypography.title2)
                                .foregroundStyle(HavenColors.textPrimary)
                            HStack(spacing: 6) {
                                // Build 94: Surface the appliance type
                                // ("Refrigerator" / "Dishwasher" / "Wall
                                // Oven") right under the brand name. The
                                // nav-bar title is the model number, so
                                // without this caption the user has no
                                // way to tell a fridge from an oven at a
                                // glance on the detail screen either.
                                if let subtype = system.subtype?.trimmingCharacters(in: .whitespaces), !subtype.isEmpty {
                                    Text(subtype.capitalized)
                                        .font(HavenTypography.uiLabelMedium)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                                if let series {
                                    Text(series)
                                        .font(HavenTypography.uiLabelMedium)
                                        .foregroundStyle(brandColor)
                                }
                                if let fuelType = catalogDetails?.fuelType {
                                    Text(fuelType.capitalized)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(brandColor)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(brandColor.opacity(0.10))
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        Spacer()

                        if let score {
                            // Score in a circular ring
                            ZStack {
                                Circle()
                                    .stroke(scoreColor(score).opacity(0.15), lineWidth: 3)
                                    .frame(width: 50, height: 50)
                                Circle()
                                    .trim(from: 0, to: Double(score) / 100)
                                    .stroke(scoreColor(score), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .frame(width: 50, height: 50)
                                    .rotationEffect(.degrees(-90))
                                VStack(spacing: 0) {
                                    Text("\(score)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(scoreColor(score))
                                    Text("score")
                                        .font(.system(size: 7, weight: .medium))
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                            }
                        }
                    }

                    // Model name (descriptive)
                    if let modelName = catalogDetails?.modelName, modelName != system.name {
                        Text(modelName)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(2)
                    }

                    // Key features chips
                    if !features.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(features.prefix(5), id: \.self) { feature in
                                    Text(feature)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(brandColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(brandColor.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle()
                        .fill(brandColor.opacity(0.2))
                        .frame(height: 1)

                    // Details row: Model | Fuel | Serial | Lifespan
                    HStack(spacing: 0) {
                        if let model = system.modelNumber {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Model")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                Text(model)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                        }
                        Spacer()
                        if let fuelType = catalogDetails?.fuelType {
                            VStack(alignment: .center, spacing: 1) {
                                Text("Fuel")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                Text(fuelType.capitalized)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                            Spacer()
                        }
                        if let serial = system.serialNumber {
                            VStack(alignment: .center, spacing: 1) {
                                Text("Serial")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                Text(serial)
                                    .font(.system(size: 10))
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        if let lifespan = system.expectedLifespanYears {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("Lifespan")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                Text("\(lifespan) yrs")
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                        }
                    }

                    // Edit hint
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 9))
                            Text("Tap to edit")
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                .padding(HavenTheme.spacing16)
            }
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(brandColor.opacity(0.15), lineWidth: 1)
            )
        }
    }

    private func deriveSeries() -> String? {
        let model = (system.modelNumber ?? "").uppercased()
        let name = system.name.lowercased()

        if model.hasPrefix("SH") && model.contains("78") { return "800 Series" }
        if model.hasPrefix("SH") && model.contains("65") { return "500 Series" }
        if model.hasPrefix("SH") && model.contains("41") { return "100 Series" }
        if model.hasPrefix("SHX89") || model.hasPrefix("SHP9") { return "Benchmark" }
        if model.hasPrefix("RF29") { return "Bespoke" }
        if name.contains("profile") { return "Profile" }
        if name.contains("cafe") || name.contains("café") { return "Café" }
        if name.contains("monogram") { return "Monogram" }

        let patterns = ["100 series", "200 series", "300 series", "500 series", "800 series",
                        "benchmark", "profile", "bespoke", "café"]
        for pattern in patterns {
            if name.contains(pattern) { return pattern.capitalized }
        }
        return nil
    }

    // MARK: - System Info

    private var systemInfoCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(system.name.humanizedSystemName)
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(system.category)
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    statusBadge
                }

                Divider().overlay(HavenColors.beige200)

                if let mfr = system.manufacturer {
                    infoRow("Manufacturer", value: mfr)
                }
                if let model = system.modelNumber {
                    infoRow("Model", value: model)
                }
                if let serial = system.serialNumber {
                    infoRow("Serial Number", value: serial)
                }
                if let install = system.installDate {
                    infoRow("Installed", value: install)
                }
                if let lifespan = system.expectedLifespanYears {
                    let installYear = system.installDate.flatMap { dateFormatter.date(from: $0) }
                        .map { Calendar.current.component(.year, from: $0) }
                    let replacementYear = installYear.map { $0 + lifespan }
                    infoRow("Expected Lifespan", value: "\(lifespan) years" + (replacementYear.map { " (replace ~\($0))" } ?? ""))
                }
                if let notes = system.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(notes)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }

                if let lastService = system.lastServiceDate {
                    infoRow("Last Serviced", value: lastService.havenDateFormatted)
                }
                if let nextDue = system.nextServiceDue {
                    infoRow("Next Service Due", value: nextDue.havenDateFormatted)
                }

                // Phase 50: Service frequency editor row. Tappable, shows
                // current cadence + provenance caption when overridden.
                serviceFrequencyRow
            }
        }
    }

    // MARK: - Phase 50: Service Frequency Row

    /// Tappable row that shows the system's service frequency. When the
    /// user has set a per-system override, the value reads "Every 2
    /// weeks" + a small "Set from invoice on Apr 15" caption underneath.
    /// Tapping opens FrequencyPickerSheet.
    private var serviceFrequencyRow: some View {
        Button {
            Haptics.light()
            showFrequencyPicker = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Service frequency")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(serviceFrequencyDisplay)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                    Spacer()
                    Text("Change")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.navy700)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                if let caption = serviceFrequencyCaption {
                    Text(caption)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Pretty-formatted current cadence. Honors `service_interval_days`
    /// when set, otherwise pulls a one-line description from the most
    /// frequent template attached to this system's category.
    private var serviceFrequencyDisplay: String {
        if let days = system.serviceIntervalDays {
            return Self.humanCadence(days: days)
        }
        return "Default (template-driven)"
    }

    private var serviceFrequencyCaption: String? {
        guard let source = system.serviceIntervalSource, source != "default", !source.isEmpty else { return nil }
        switch source {
        case "onboarding": return "Set during House Quiz"
        case "vendor_invoice": return "Set from invoice"
        case "manual": return "Manually set"
        default: return nil
        }
    }

    private static func humanCadence(days: Int) -> String {
        switch days {
        case 7: return "Weekly"
        case 14: return "Every 2 weeks"
        case 21: return "Every 3 weeks"
        case 28, 30, 31: return "Monthly"
        case 60, 61, 62: return "Every 2 months"
        case 90, 91, 92: return "Quarterly"
        case 180, 181, 182, 183: return "Semi-annually"
        case 364, 365, 366: return "Annually"
        default:
            if days % 7 == 0 {
                return "Every \(days / 7) weeks"
            }
            return "Every \(days) days"
        }
    }

    // MARK: - Reliability Score Card

    private var reliabilityCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 16))
                        .foregroundStyle(scoreColor(equipmentScore?.reliability ?? 0))
                    Text("Model reliability")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    if let score = equipmentScore?.reliability {
                        Text("\(score)/100")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(scoreColor(score))
                    }
                }
                if let summary = equipmentScore?.summary {
                    Text(summary)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Text("This reflects known repair frequency and expected performance for this model. It is not an inspection of this specific unit.")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        score >= 85 ? .green : score >= 70 ? .blue : score >= 55 ? .orange : .red
    }

    // MARK: - Manuals Card

    private var manualsCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "book.closed")
                        .font(.system(size: 16))
                        .foregroundStyle(HavenColors.navy700)
                    Text("Manuals & Guides")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                }
                ForEach(manualLinks) { manual in
                    if let url = URL(string: manual.url) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: manual.cached ? "doc.fill" : "link")
                                    .font(.system(size: 14))
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .frame(width: 24)
                                Text(manual.displayName)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.navy700)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 12))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    private var statusBadge: some View {
        let status = system.status ?? "Good"
        let color = statusColor(status)
        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(status)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Warranties

    private var warrantiesCard: some View {
        Group {
            if warranties.isEmpty {
                Button {
                    Haptics.light()
                    showAddWarranty = true
                } label: {
                    HavenCard {
                        HStack(spacing: HavenTheme.spacing12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(HavenColors.navy700)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Warranty")
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("Tap to add warranty information")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        HStack {
                            Image(systemName: "shield.fill")
                                .foregroundStyle(HavenColors.info)
                            Text("Warranties")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                        }

                        ForEach(warranties) { warranty in
                            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(warranty.provider)
                                            .font(HavenTypography.body)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Text(warranty.warrantyType)
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                    Spacer()
                                    warrantyExpirationBadge(endDate: warranty.endDate)
                                }

                                HStack(spacing: HavenTheme.spacing16) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("START")
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                        Text(warranty.startDate)
                                            .font(HavenTypography.uiLabelMedium)
                                            .foregroundStyle(HavenColors.textPrimary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("END")
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                        Text(warranty.endDate)
                                            .font(HavenTypography.uiLabelMedium)
                                            .foregroundStyle(HavenColors.textPrimary)
                                    }
                                    Spacer()
                                    if let phone = warranty.claimPhone {
                                        let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                                        if let url = URL(string: "tel:\(cleaned)") {
                                            Link(destination: url) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "phone.fill")
                                                    Text("Claim")
                                                        .font(HavenTypography.uiLabelSmall)
                                                }
                                                .foregroundStyle(HavenColors.navy700)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(HavenColors.navy.opacity(0.08))
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.background)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                    }
                }
            }
        }
    }

    private func warrantyExpirationBadge(endDate: String) -> some View {
        let daysRemaining = daysUntil(endDate)
        let color: Color = {
            if daysRemaining < 0 { return HavenColors.critical }
            if daysRemaining <= 30 { return HavenColors.critical }
            if daysRemaining <= 90 { return HavenColors.warning }
            return HavenColors.success
        }()
        let text: String = {
            if daysRemaining < 0 { return "Expired" }
            return "\(daysRemaining)d left"
        }()

        return Text(text)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Components (Sub-Systems)

    @ViewBuilder
    private var componentsCard: some View {
        if !childSystems.isEmpty {
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack {
                        Label("Components", systemImage: "square.stack.3d.up")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                        Text("\(childSystems.count)")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    ForEach(childSystems) { child in
                        NavigationLink {
                            SystemDetailRowView(system: child)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(HavenColors.navy.opacity(0.3))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(child.name)
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.textPrimary)

                                    HStack(spacing: 8) {
                                        if let mfr = child.manufacturer {
                                            Text(mfr)
                                                .font(HavenTypography.uiCaption)
                                                .foregroundStyle(HavenColors.textTertiary)
                                        }
                                        if let model = child.modelNumber {
                                            Text(model)
                                                .font(HavenTypography.uiCaption)
                                                .foregroundStyle(HavenColors.textTertiary)
                                        }
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)

                        if child.id != childSystems.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Documents

    private var documentsCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(HavenColors.navy700)
                    Text("Documents")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Button {
                        Haptics.light()
                        showDocumentUpload = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(HavenColors.navy700)
                                .imageScale(.medium)
                            Text("Add")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(HavenColors.navy700)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }

                if linkedDocuments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upload service reports, quotes, invoices, and other documents for this system.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        VStack(spacing: 8) {
                            ForEach(systemDocumentTypes, id: \.self) { docType in
                                Button {
                                    Haptics.light()
                                    showDocumentUpload = true
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "circle")
                                            .foregroundStyle(HavenColors.textTertiary.opacity(0.5))
                                            .font(.body)
                                        Text(docType)
                                            .font(HavenTypography.subheadline)
                                            .foregroundStyle(HavenColors.textTertiary)
                                        Spacer()
                                        Text("Upload")
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.navy700.opacity(0.6))
                                    }
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else {
                    ForEach(linkedDocuments) { doc in
                        NavigationLink {
                            DocumentDetailView(documentID: doc.id)
                        } label: {
                            HStack(spacing: HavenTheme.spacing12) {
                                Image(systemName: fileIcon(for: doc.filePath))
                                    .font(.system(size: 16))
                                    .foregroundStyle(HavenColors.navy700)
                                    .frame(width: 36, height: 36)
                                    .background(HavenColors.navy.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(doc.title)
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                        .lineLimit(1)

                                    HStack(spacing: 6) {
                                        Text(doc.category)
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textSecondary)

                                        if let status = doc.status as String? {
                                            Text("•")
                                                .font(HavenTypography.uiCaption)
                                                .foregroundStyle(HavenColors.textTertiary)
                                            Text(status.capitalized)
                                                .font(HavenTypography.uiCaption)
                                                .foregroundStyle(HavenColors.statusColor(status))
                                        }
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)

                        if doc.id != linkedDocuments.last?.id {
                            Divider()
                                .padding(.leading, 48)
                                .overlay(HavenColors.beige200)
                        }
                    }
                }
            }
        }
    }

    private var systemDocumentTypes: [String] {
        ["Service Report", "Invoice", "Quote", "Inspection Report", "Owner's Manual", "Warranty Document"]
    }

    private func fileIcon(for path: String) -> String {
        if path.hasSuffix(".pdf") { return "doc.richtext.fill" }
        if path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") || path.hasSuffix(".png") { return "photo.fill" }
        return "doc.fill"
    }

    // MARK: - Maintenance

    // MARK: - Chez ownership (Phase 84)

    /// Universal entity-level delegation toggle. The toggle component
    /// handles the prompt-for-notes flow, the optimistic-state binding,
    /// and the cross-surface refresh notifications — we just need to
    /// pass the right Target. ChezOwnsBadge.chezOwnedSection() already
    /// renders a section card around it; we wrap in a HavenCard for
    /// visual consistency with the surrounding cards.
    private var chezOwnsCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            ChezOwnsToggle(
                target: .system(id: system.id, name: system.displayName),
                isOwned: $chezOwnedLocal,
                onChange: { _ in
                    NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
                }
            )
            Text("Chez logs service, schedules maintenance visits, links warranty docs, and orders parts when something fails.")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.surface)
        .cornerRadius(HavenTheme.radiusMedium)
        .onAppear {
            chezOwnedLocal = system.isChezOwned
        }
    }

    // MARK: - Ask Alfred

    private var askAlfredCard: some View {
        Button {
            Haptics.light()
            showAlfredSystemChat = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundStyle(HavenColors.navy700)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ask Alfred")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Questions about your \(system.name)")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .cornerRadius(HavenTheme.radiusMedium)
        }
        .buttonStyle(.plain)
    }

    private func buildSystemContext() -> String {
        var context = "The user is viewing their \(system.name)."
        if let mfr = system.manufacturer { context += " Manufacturer: \(mfr)." }
        if let model = system.modelNumber { context += " Model: \(model)." }
        if let serial = system.serialNumber { context += " Serial: \(serial)." }
        if let installDate = system.installDate { context += " Installed: \(installDate)." }
        if let notes = system.notes, !notes.isEmpty { context += " Notes: \(notes)." }
        if !linkedDocuments.isEmpty {
            let manuals = linkedDocuments.filter { $0.category.lowercased().contains("manual") || $0.title.lowercased().contains("manual") }
            if !manuals.isEmpty {
                context += " Owner's manual(s) available: \(manuals.map(\.title).joined(separator: ", "))."
            }
        }
        if !manualLinks.isEmpty {
            context += " Online manuals: \(manualLinks.map(\.url).joined(separator: ", "))."
        }
        if !warranties.isEmpty {
            for w in warranties { context += " Warranty: \(w.provider), expires \(w.endDate)." }
        }
        context += " Reference this specific make and model in answers. If an owner's manual is linked, reference it."
        return context
    }

    private var maintenanceCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "wrench.fill")
                        .foregroundStyle(HavenColors.warning)
                    Text("Maintenance Schedule")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                }

                if tasks.isEmpty {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        Text("What needs attention?")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        let templates = MaintenanceTemplates.templates(for: system.category).prefix(5)
                        if !templates.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(Array(templates)) { template in
                                    Button {
                                        Haptics.light()
                                        Task { await quickAddTask(template) }
                                    } label: {
                                        Text(template.title)
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundStyle(HavenColors.textPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(HavenColors.navy.opacity(0.08))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isAddingQuickTask)
                                }
                            }
                        } else {
                            Text("Set up your maintenance schedule and Chez will make sure nothing falls through the cracks.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                    .padding(.vertical, HavenTheme.spacing4)
                } else {
                    ForEach(tasks) { task in
                        systemTaskRow(task)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func systemTaskRow(_ task: MaintenanceTaskDBRow) -> some View {
        let contractorId = MaintenanceTaskRoutingSupport.resolvedContractorId(for: task, systems: [system])
        let prefersVendorCoverage = MaintenanceTaskRoutingSupport.prefersVendorCoverage(task)
        let handymanEligible = MaintenanceTaskRoutingSupport.isInlineHandymanEligible(task, systems: [system])
        let activeRoute = task.assignedRoute?.lowercased()

        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Button {
                Haptics.light()
                selectedTask = task
            } label: {
                HStack(spacing: HavenTheme.spacing12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)

                        HStack(spacing: HavenTheme.spacing8) {
                            Text(task.frequency)
                                .font(HavenTypography.uiCaption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(HavenColors.beige300.opacity(0.5))
                                .clipShape(Capsule())
                                .foregroundStyle(HavenColors.textSecondary)

                            dueDateBadge(task.nextDueDate)
                        }

                        if let cost = task.estimatedCost {
                            Text("Est. $\(cost, specifier: "%.0f")")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    Spacer()

                    if let priority = task.priority {
                        Text(priority)
                            .font(HavenTypography.uiCaption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(HavenColors.priorityColor(priority).opacity(0.12))
                            .foregroundStyle(HavenColors.priorityColor(priority))
                            .clipShape(Capsule())
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            .buttonStyle(.plain)

            HStack(alignment: .center, spacing: HavenTheme.spacing12) {
                let status = serviceStatus(for: task)
                Label(status.text, systemImage: status.icon)
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(status.color)
                    .lineLimit(2)

                Spacer(minLength: HavenTheme.spacing8)

                if activeRoute == "handyman" {
                    Button {
                        Haptics.light()
                        showHandymanPunchList = true
                    } label: {
                        Text("View list")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(HavenColors.creamLight)
                            .overlay(
                                Capsule()
                                    .stroke(HavenColors.beige300, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                } else if prefersVendorCoverage && contractorId == nil {
                    Button {
                        Haptics.light()
                        Task { await addTaskToHandymanPunchList(task) }
                    } label: {
                        Text("Try contractor")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(HavenColors.creamLight)
                            .overlay(
                                Capsule()
                                    .stroke(HavenColors.beige300, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                } else if handymanEligible {
                    Button {
                        Haptics.light()
                        Task { await addTaskToHandymanPunchList(task) }
                    } label: {
                        HStack(spacing: 6) {
                            if isAddingTaskToHandyman {
                                ProgressView()
                                    .scaleEffect(0.75)
                                    .tint(HavenColors.navy700)
                            } else {
                                Image(systemName: "hammer.fill")
                            }
                            Text("Add to contractor")
                        }
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.navy700)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(HavenColors.creamLight)
                        .overlay(
                            Capsule()
                                .stroke(HavenColors.beige300, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isAddingTaskToHandyman)
                }
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.background)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private func serviceStatus(for task: MaintenanceTaskDBRow) -> (text: String, icon: String, color: Color) {
        if let contractorId = MaintenanceTaskRoutingSupport.resolvedContractorId(for: task, systems: [system]),
           let contractor = contractorsById[contractorId] {
            return ("Handled by \(contractor.companyName)", "person.crop.circle", HavenColors.textSecondary)
        }

        if task.assignedRoute == "handyman" {
            return ("On the handyman list", "hammer.fill", HavenColors.navy700)
        }

        if MaintenanceTaskRoutingSupport.prefersVendorCoverage(task) {
            return ("Coverage recommended", "wrench.and.screwdriver", HavenColors.warning)
        }

        if MaintenanceTaskRoutingSupport.isInlineHandymanEligible(task, systems: [system]) {
            return ("Good for a handyman visit", "hammer.fill", HavenColors.warning)
        }

        return ("Open task", "calendar", HavenColors.textSecondary)
    }

    @MainActor
    private func addTaskToHandymanPunchList(_ task: MaintenanceTaskDBRow) async {
        guard !isAddingTaskToHandyman else { return }
        isAddingTaskToHandyman = true
        defer { isAddingTaskToHandyman = false }

        let existing = (try? await db.fetchPendingHandymanPunchItems(householdId: task.householdId)) ?? []
        if existing.contains(where: { $0.sourceTaskId == task.id }) {
            Haptics.light()
            await presentSystemToast("Already on the handyman list")
            return
        }

        do {
            let insert = MaintenanceTaskRoutingSupport.buildPunchItemInsert(for: task)
            _ = try await db.createHandymanPunchItem(insert)
            _ = try? await db.assignTaskToHandymanRoutine(task: task)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "routed", "id": task.id.uuidString, "route": "handyman"])
            NotificationCenter.default.post(name: .routineChanged, object: nil)
            Haptics.success()
            await loadDetails()
            await presentSystemToast("Added to the handyman list")
        } catch {
            print("[SystemDetail] Failed to add task to handyman list: \(error)")
            Haptics.error()
            await presentSystemToast("Couldn't add this task right now")
        }
    }

    @MainActor
    private func presentSystemToast(_ message: String) async {
        withAnimation { systemStatusToast = message }
        try? await Task.sleep(for: .seconds(2))
        withAnimation { systemStatusToast = nil }
    }

    private func dueDateBadge(_ dateStr: String) -> some View {
        let days = daysUntil(dateStr)
        let color: Color = {
            if days < 0 { return HavenColors.critical }
            if days <= 7 { return HavenColors.critical }
            if days <= 30 { return HavenColors.warning }
            return HavenColors.textSecondary
        }()
        let text: String = {
            if days < 0 { return "Overdue \(-days)d" }
            if days == 0 { return "Due today" }
            return "Due in \(days)d"
        }()

        return Text(text)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(color)
    }

    // MARK: - Recent Services

    private var serviceRecordsCard: some View {
        let latestRecord = records.first
        let latestVendorName: String? = {
            guard let contractorId = latestRecord?.contractorId else { return nil }
            return contractorsById[contractorId]?.companyName
        }()

        return Group {
            if records.isEmpty {
                HavenCard {
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: "clock")
                            .font(.title3)
                            .foregroundStyle(HavenColors.textTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recent Services")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(system.lastServiceDate.map { "Last recorded service \($0.havenDateShort). Future visits will show up here." }
                                 ?? "Completed vendor visits and logged work for this system will show up here.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        Spacer()
                    }
                }
            } else {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(HavenColors.textSecondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Recent Services")
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(
                                    latestRecord.map {
                                        if let latestVendorName {
                                            return "Last visit \($0.serviceDate.havenDateShort) by \(latestVendorName)"
                                        }
                                        return "Last visit \($0.serviceDate.havenDateShort)"
                                    } ?? "Latest work and vendor visits for this system"
                                )
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Spacer()
                            if totalSpentAmount > 0 {
                                Text("$\(totalSpentAmount, specifier: "%.0f") total")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }

                        ForEach(Array(records.prefix(3))) { record in
                            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                                // Timeline dot
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(HavenColors.navy)
                                        .frame(width: 8, height: 8)
                                    if record.id != Array(records.prefix(3)).last?.id {
                                        Rectangle()
                                            .fill(HavenColors.beige300)
                                            .frame(width: 1)
                                            .frame(maxHeight: .infinity)
                                    }
                                }
                                .frame(width: 8)
                                .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(record.description)
                                            .font(HavenTypography.bodySmall)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Spacer()
                                        if let cost = record.cost {
                                            Text("$\(cost, specifier: "%.0f")")
                                                .font(HavenTypography.uiLabel)
                                                .foregroundStyle(HavenColors.textPrimary)
                                        }
                                    }
                                    HStack(spacing: HavenTheme.spacing8) {
                                        Text(record.serviceDate.havenDateShort)
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundStyle(HavenColors.textSecondary)
                                        if let contractorId = record.contractorId,
                                           let contractor = contractorsById[contractorId] {
                                            Text(contractor.companyName)
                                                .font(HavenTypography.uiCaption)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(HavenColors.navy.opacity(0.08))
                                                .clipShape(Capsule())
                                                .foregroundStyle(HavenColors.navy700)
                                        }
                                        Text(record.serviceType.capitalized)
                                            .font(HavenTypography.uiCaption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(HavenColors.beige200)
                                            .clipShape(Capsule())
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        if records.count > 3 {
                            NavigationLink {
                                ServiceHistoryView(systemId: system.id)
                            } label: {
                                HStack(spacing: 6) {
                                    Text("View full service history")
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy700)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Preferred Vendor

    private var preferredVendorCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .foregroundStyle(HavenColors.navy700)
                    Text("Preferred Vendor")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    if preferredContractor != nil {
                        Button("Change") { showContractorPicker = true }
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }

                if let contractor = preferredContractor {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(contractor.companyName)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)

                        if let contact = contractor.contactName {
                            Text(contact)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }

                        HStack(spacing: 12) {
                            let cleaned = contractor.phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            if let url = URL(string: "tel:\(cleaned)") {
                                Link(destination: url) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone.fill")
                                        Text(contractor.phone)
                                    }
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy700)
                                }
                            }

                            if let email = contractor.email,
                               let url = URL(string: "mailto:\(email.trimmingCharacters(in: .whitespaces))") {
                                Link(destination: url) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "envelope.fill")
                                        Text("Email")
                                    }
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy700)
                                }
                            }
                        }

                        if let rating = contractor.rating, rating > 0 {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: Double(star) <= rating ? "star.fill" : "star")
                                        .font(.caption2)
                                        .foregroundStyle(Double(star) <= rating ? HavenColors.warning : HavenColors.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                } else {
                    VStack(spacing: 8) {
                        Button {
                            showContractorPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(HavenColors.navy700)
                                Text("Choose from Directory")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(HavenColors.navy.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                        .buttonStyle(.plain)

                        Button {
                            showAlfredChat = true
                        } label: {
                            HStack {
                                Image(systemName: "bubble.left.fill")
                                    .foregroundStyle(HavenColors.textSecondary)
                                Text("Ask Alfred to Find One")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(HavenColors.beige200.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func assignContractor(_ contractor: ContractorRow) async {
        do {
            _ = try await db.updateHomeSystem(
                id: system.id,
                HomeSystemUpdate(preferredContractorId: contractor.id)
            )
            preferredContractor = contractor
            Analytics.track(.systemContractorAssigned, ["system_id": system.id.uuidString, "contractor_id": contractor.id.uuidString])
            Haptics.success()
        } catch {
            // silently handle
        }
    }

    // MARK: - Total Spent

    private var totalSpentAmount: Double {
        records.compactMap(\.cost).reduce(0, +)
    }

    // MARK: - Helpers

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.uiLabelMedium)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "good": return HavenColors.success
        case "needs maintenance": return HavenColors.warning
        case "needs repair", "needs replacement": return HavenColors.critical
        case "under warranty": return HavenColors.info
        case "out of service": return HavenColors.textTertiary
        default: return HavenColors.success
        }
    }

    private func daysUntil(_ dateStr: String) -> Int {
        guard let date = dateFormatter.date(from: dateStr) else { return 0 }
        return Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
    }

    private func bulkDeleteTasks(ids: [UUID]) async {
        let snapshot = tasks
        let idSet = Set(ids)
        tasks.removeAll { idSet.contains($0.id) }
        Haptics.success()
        do {
            try await db.deleteMaintenanceTasks(ids: ids)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "bulk_deleted", "count": ids.count])
        } catch {
            tasks = snapshot
            Haptics.error()
        }
    }

    private func resetTemplates() async {
        let activeSubs = MaintenanceTemplates.activeSubtypes(
            category: system.category,
            subtype: system.subtype,
            fuelType: system.catalogFuelType
        )
        let templates = MaintenanceTemplates.templates(for: system.category, activeSubtypes: activeSubs)
        let templateTaskIds = tasks.filter { $0.systemId == system.id && $0.isTemplateBased == true }.map(\.id)

        do {
            if !templateTaskIds.isEmpty {
                try await db.deleteMaintenanceTasks(ids: templateTaskIds)
                let removeSet = Set(templateTaskIds)
                tasks.removeAll { removeSet.contains($0.id) }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            for t in templates {
                let nextDue = Calendar.current.date(byAdding: t.interval, to: .now) ?? .now
                let insert = MaintenanceTaskInsert(
                    propertyId: system.propertyId,
                    householdId: system.householdId,
                    title: t.title,
                    frequency: t.frequency,
                    nextDueDate: formatter.string(from: nextDue),
                    systemId: system.id,
                    description: t.description,
                    priority: t.priority,
                    notes: t.notes,
                    isTemplateBased: true,
                    templateId: t.systemCategory + ":" + t.title,
                    seasonalTiming: t.seasonalTiming,
                    isDiy: t.isDIY,
                    professionalRequired: t.professionalRequired,
                    costRange: t.estimatedCostRange,
                    recurrenceRule: t.frequency
                )
                if let saved = try? await db.createMaintenanceTask(insert) {
                    tasks.append(saved)
                }
            }
            Haptics.success()
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        } catch {
            Haptics.error()
        }
    }

    private func quickAddTask(_ template: MaintenanceTemplate) async {
        isAddingQuickTask = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let nextDue = Calendar.current.date(byAdding: template.interval, to: .now) ?? .now

        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else { return }

            _ = try await db.createMaintenanceTask(MaintenanceTaskInsert(
                propertyId: system.propertyId,
                householdId: householdId,
                title: template.title,
                frequency: template.frequency,
                nextDueDate: formatter.string(from: nextDue),
                systemId: system.id,
                description: template.description,
                priority: template.priority,
                notes: template.notes,
                isTemplateBased: true,
                templateId: template.systemCategory + ":" + template.title,
                seasonalTiming: template.seasonalTiming,
                isDiy: template.isDIY,
                professionalRequired: template.professionalRequired,
                costRange: template.estimatedCostRange
            ))
            Haptics.success()
            await loadDetails()
        } catch {
            // silently handle
        }
        isAddingQuickTask = false
    }

    private func reloadSystem() async {
        // Reload the system from DB to get updated fields
        do {
            let allSystems = try await db.fetchHomeSystems(propertyId: system.propertyId)
            if let updated = allSystems.first(where: { $0.id == system.id }) {
                await MainActor.run { system = updated }
            }
        } catch { }
        await loadDetails()
    }

    /// Phase 50: Persist a new service interval on this system. When
    /// `applyToExistingTasks` is true, walks every task on the system
    /// and rewrites its `next_due_date` from the most recent
    /// `last_completed_date` plus the new interval (or from today when
    /// no completion exists yet). Source is stamped as "manual" because
    /// this path is only invoked from the system detail editor — the
    /// invoice and onboarding paths use their own source labels.
    private func applyServiceInterval(days: Int, applyToExistingTasks: Bool) async {
        var update = HomeSystemUpdate()
        update.serviceIntervalDays = days
        update.serviceIntervalSource = "manual"
        do {
            let updated = try await db.updateHomeSystem(id: system.id, update)
            await MainActor.run { system = updated }
            if applyToExistingTasks {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let now = Date()
                for task in tasks {
                    let baseline = task.lastCompletedDate.flatMap { formatter.date(from: $0) } ?? now
                    if let nextDate = Calendar.current.date(byAdding: .day, value: days, to: baseline) {
                        var taskUpdate = MaintenanceTaskUpdate()
                        taskUpdate.nextDueDate = formatter.string(from: nextDate)
                        _ = try? await db.updateMaintenanceTask(id: task.id, taskUpdate)
                    }
                }
            }
            Haptics.success()
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            await loadDetails()
        } catch {
            print("[SystemDetail] Failed to apply service interval: \(error)")
            Haptics.error()
        }
    }

    /// Phase 50: Clear the per-system override and revert to the
    /// template default. Sets the column back to NULL by sending the
    /// sentinel "default" source string and a nil interval.
    private func clearServiceIntervalOverride() async {
        var update = HomeSystemUpdate()
        update.serviceIntervalDays = nil
        update.serviceIntervalSource = "default"
        do {
            let updated = try await db.updateHomeSystem(id: system.id, update)
            await MainActor.run { system = updated }
            Haptics.success()
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
        } catch {
            print("[SystemDetail] Failed to clear interval override: \(error)")
            Haptics.error()
        }
    }

    private func loadDetails() async {
        isLoading = true
        await MainActor.run {
            catalogLinked = system.catalogEntryId != nil
        }

        // Start equipment intelligence in parallel with main data
        let modelNum = system.modelNumber
        let mfr = system.manufacturer
        async let intelligenceTask: () = loadEquipmentIntelligence(modelNumber: modelNum, manufacturer: mfr)

        do {
            async let w = db.fetchWarranties(systemId: system.id)
            async let t = db.fetchMaintenanceTasks(propertyId: system.propertyId)
            async let r = db.fetchServiceRecords(systemId: system.id)
            async let docs = db.fetchDocuments()
            async let contractors = db.fetchContractors()

            async let children = db.fetchChildSystems(parentId: system.id)
            let (wResult, tResult, rResult, allDocs, contractorList, childResult) = try await (w, t, r, docs, contractors, children)
            await MainActor.run {
                warranties = wResult
                tasks = tResult.filter { $0.systemId == system.id }
                records = rResult
                childSystems = childResult
                contractorsById = Dictionary(uniqueKeysWithValues: contractorList.map { ($0.id, $0) })
                if let contractorId = system.preferredContractorId {
                    preferredContractor = contractorList.first { $0.id == contractorId }
                } else {
                    preferredContractor = nil
                }
                linkedDocuments = allDocs.filter { doc in
                    guard doc.propertyId == system.propertyId else { return false }
                    let searchTerms = [system.name.lowercased(), system.category.lowercased()]
                    let docText = "\(doc.title) \(doc.category) \(doc.notes ?? "")".lowercased()
                    return searchTerms.contains(where: { docText.contains($0) })
                }
            }
        } catch { }

        isLoading = false
        await intelligenceTask
    }

    private func loadEquipmentIntelligence(modelNumber: String?, manufacturer: String?) async {
        guard let modelNum = modelNumber, !modelNum.isEmpty else { return }

        // Run manual lookup and catalog search in parallel
        async let manualTask: () = loadManuals(modelNumber: modelNum)
        async let catalogTask: () = loadCatalogDetails(modelNumber: modelNum, manufacturer: manufacturer)
        _ = await (manualTask, catalogTask)
    }

    private func loadManuals(modelNumber: String) async {
        // Use cached manual links if available
        if let cached = system.cachedManualLinks, !cached.isEmpty {
            await MainActor.run {
                self.manualLinks = cached.map {
                    ManualLink(type: $0.type, url: $0.url, cached: $0.cached ?? false)
                }.sorted { $0.type < $1.type }
            }
            return
        }

        // No cache — fetch from API and persist
        do {
            let data = try await HavenSupabase.lookupManual(modelNumber: modelNumber)
            if let manuals = data["manuals"] as? [String: Any] {
                var links: [ManualLink] = []
                for (type, info) in manuals {
                    if let dict = info as? [String: Any],
                       let url = dict["url"] as? String, !url.isEmpty {
                        let cached = dict["cached"] as? Bool ?? false
                        links.append(ManualLink(type: type, url: url, cached: cached))
                    }
                }
                let sorted = links.sorted { $0.type < $1.type }
                await MainActor.run { self.manualLinks = sorted }

                // Persist to DB for instant load next time
                let cachePayload = sorted.map { CachedManualLink(type: $0.type, url: $0.url, cached: $0.cached) }
                try? await DatabaseService.shared.updateHomeSystemManualCache(
                    id: system.id,
                    links: cachePayload
                )
            }
        } catch { }
    }

    private func loadCatalogDetails(modelNumber: String, manufacturer: String?) async {
        guard let mfr = manufacturer else { return }

        // Use cached catalog data if available (no network call needed)
        if let cached = system.catalogSeries ?? system.catalogModelName ?? (system.catalogFeatures?.isEmpty == false ? "" : nil),
           !cached.isEmpty || system.reliabilityScore != nil {
            await MainActor.run {
                self.catalogDetails = CatalogDetails(
                    series: system.catalogSeries,
                    modelName: system.catalogModelName ?? system.name,
                    keyFeatures: system.catalogFeatures ?? [],
                    websiteUrl: nil,
                    fuelType: system.catalogFuelType
                )
                if let score = system.reliabilityScore {
                    self.equipmentScore = EquipmentDetailScore(
                        reliability: score,
                        summary: system.scoreSummary
                    )
                }
            }

            // Refresh in background if cache is stale, incomplete, or missing score
            let needsRefresh = system.catalogEnrichedAt == nil
                || system.reliabilityScore == nil
                || Date().timeIntervalSince(system.catalogEnrichedAt ?? .distantPast) > 30 * 24 * 3600
            if needsRefresh {
                Task { await refreshCatalogCache(modelNumber: modelNumber, manufacturer: mfr) }
            }
            return
        }

        // No cache — fetch from API and persist
        await refreshCatalogCache(modelNumber: modelNumber, manufacturer: mfr)
    }

    private func refreshCatalogCache(modelNumber: String, manufacturer: String) async {
        do {
            // Search by model number first for exact match, then fall back to brand+model
            var searchResult = try await HavenSupabase.searchEquipment(query: modelNumber, limit: 5)
            if searchResult.results.isEmpty {
                searchResult = try await HavenSupabase.searchEquipment(query: "\(manufacturer) \(modelNumber)", limit: 15)
            }

            // Normalize for comparison: strip hyphens, underscores, spaces
            let normalizedInput = modelNumber.replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "_", with: "")
                .replacingOccurrences(of: " ", with: "")
                .lowercased()

            // Priority 1: Exact model number match
            let match = searchResult.results.first(where: {
                $0.modelNumber.lowercased() == modelNumber.lowercased()
            })
            // Priority 2: Delimiter-normalized match
            ?? searchResult.results.first(where: {
                $0.modelNumber.replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: "_", with: "")
                    .replacingOccurrences(of: " ", with: "")
                    .lowercased() == normalizedInput
            })
            // Priority 3: Same category match (don't show dishwasher data for a fridge)
            ?? searchResult.results.first(where: {
                $0.category.name.lowercased().contains(system.category.lowercased())
                || system.category.lowercased().contains($0.category.name.lowercased())
            })

            if let match {
                // Exact or category-matched model — show full enrichment
                let series = match.specs.series
                let modelName = match.modelName ?? match.displayName
                let features = match.specs.keyFeatures ?? []
                let fuelType = match.specs.fuelType
                let reliability = match.scores?.reliability
                let summary = match.scores?.summary

                await MainActor.run {
                    self.catalogDetails = CatalogDetails(
                        series: series,
                        modelName: modelName,
                        keyFeatures: features,
                        websiteUrl: nil,
                        fuelType: fuelType
                    )
                    if let reliability {
                        self.equipmentScore = EquipmentDetailScore(
                            reliability: reliability,
                            summary: summary
                        )
                    }
                }

                // Persist to DB so next load is instant
                _ = try? await db.updateHomeSystem(
                    id: system.id,
                    HomeSystemUpdate(
                        catalogSeries: series,
                        catalogModelName: modelName,
                        catalogFeatures: features,
                        reliabilityScore: reliability,
                        scoreSummary: summary,
                        catalogFuelType: fuelType,
                        catalogEnrichedAt: Date()
                    )
                )
            } else if let anyResult = searchResult.results.first,
                      let score = anyResult.scores?.reliability {
                // No model match, but we have the brand — show brand-level score only
                await MainActor.run {
                    self.equipmentScore = EquipmentDetailScore(
                        reliability: score,
                        summary: anyResult.scores?.summary
                    )
                }
                // Cache just the score (not wrong model details)
                _ = try? await db.updateHomeSystem(
                    id: system.id,
                    HomeSystemUpdate(
                        reliabilityScore: score,
                        scoreSummary: anyResult.scores?.summary,
                        catalogEnrichedAt: Date()
                    )
                )
            }
        } catch { }
    }
}

// MARK: - Equipment Intelligence Models

struct ManualLink: Identifiable {
    let id = UUID()
    let type: String
    let url: String
    let cached: Bool

    var displayName: String {
        type.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

struct EquipmentDetailScore {
    let reliability: Int
    let summary: String?
}

struct CatalogDetails {
    let series: String?
    let modelName: String?
    let keyFeatures: [String]
    let websiteUrl: String?
    let fuelType: String?
}

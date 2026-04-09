import SwiftUI

enum MaintenanceViewMode: String, CaseIterable {
    case timeline = "Timeline"
    case bySystem = "By System"
    case byType = "By Type"
}

/// Build 87: top-level filter that lets users zoom into a single bucket of
/// the two-bucket maintenance list (personal vs vendor-managed). HNW users
/// with many personal tasks were scrolling past the YOUR TO-DOS section to
/// reach VENDOR-MANAGED, so this picker collapses one of the two buckets
/// per the user's intent. `.all` is the default — both buckets visible
/// using their existing collapse state.
enum MaintenanceViewFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case mine = "Mine"
    case vendor = "Vendor"

    var id: String { rawValue }
}

struct MaintenanceScheduleView: View {
    let prefilterPropertyId: UUID?

    init(filterPropertyId: UUID? = nil) {
        self.prefilterPropertyId = filterPropertyId
    }

    @StateObject private var viewModel = MaintenanceViewModel.shared
    @State private var viewMode: MaintenanceViewMode = .timeline
    @State private var taskToDelete: MaintenanceTaskDBRow?
    @State private var selectedTask: MaintenanceTaskDBRow?
    @State private var showDeleteConfirm = false
    @State private var showSnooze = false
    @State private var taskToSnooze: MaintenanceTaskDBRow?
    @State private var snoozeDate = Date()
    @State private var showAddTask = false

    /// Phase 19l: Per-property collapsed state for the two new buckets.
    /// Defaults to expanded; persisted in UserDefaults under keys
    /// `maintenance.bucket.<propertyId>.personal.collapsed` and
    /// `maintenance.bucket.<propertyId>.vendor.collapsed`.
    @State private var personalBucketCollapsed: Bool = false
    @State private var vendorBucketCollapsed: Bool = false

    /// Build 87: top-of-list All / Mine / Vendor segmented filter. Persisted
    /// per-property in UserDefaults under `maintenance_view_filter_<propertyId>`
    /// using the same load-on-property-change pattern as the bucket collapse
    /// state above. `.all` shows both buckets stacked; `.mine` and `.vendor`
    /// show one bucket fully expanded and recompute the stats chips so the
    /// header counts match what the user is looking at.
    @State private var viewFilter: MaintenanceViewFilter = .all

    /// Phase 19l: Delegate flow state — when the user taps "Have someone
    /// else do it" on a personal card, this captures the task so we can
    /// open a contractor picker sheet.
    @State private var delegatingTask: MaintenanceTaskDBRow?

    /// Phase 19l: Personal → vendor flow uses the same ContractorDirectoryView
    /// the task detail sheet uses, so users don't have to learn a new picker.
    @State private var showDelegateContractorPicker = false

    /// Phase 19n: Find-a-contractor flow state. When the user taps "Find →"
    /// on a needs_vendor task card, this captures the task so we can open
    /// FindLocalVendorSheet with the right (town, state, category) inputs.
    @State private var findVendorTask: MaintenanceTaskDBRow?

    /// Phase 19n: Set when the user opts out of the local vendor flow via
    /// "Add my own instead" — fires the existing ContractorDirectoryView
    /// add sheet so they can type a contractor manually.
    @State private var showManualAddFromFindVendor = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.tasks.isEmpty {
                ProgressView("Loading tasks...")
            } else if viewModel.tasks.isEmpty {
                ContentUnavailableView {
                    Label("Your Maintenance Schedule", systemImage: "wrench.and.screwdriver")
                } description: {
                    Text("Add systems to your property and Haven will create a maintenance schedule for you.")
                }
            } else {
                taskContent
            }
        }
        .navigationTitle("Maintenance")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    filterMenu
                    Button {
                        Haptics.light()
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(HavenColors.navy)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadTasks()
        }
        .overlay(alignment: .bottom) {
            if let toast = viewModel.completionToast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.success)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(toast.taskTitle) — done!")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Next due: \(toast.nextDueDate)")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    Button {
                        withAnimation { viewModel.completionToast = nil }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                .padding()
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: viewModel.completionToast?.id)
        .trackScreen("MaintenanceScheduleView")
        .task {
            viewModel.subscribeToExternalChanges()
            if viewModel.tasks.isEmpty {
                await viewModel.loadTasks()
            }
            if let id = prefilterPropertyId {
                viewModel.filterPropertyId = id
            }
            // Phase 19l: load saved collapsed state for the per-property
            // bucket headers. Defaults are false (expanded) when no key
            // exists yet, which matches the plan's default.
            loadBucketCollapsedState()
        }
        .onChange(of: viewModel.filterPropertyId) { _, _ in
            // Switching properties resets to that property's saved state.
            loadBucketCollapsedState()
        }
        // Phase 19l: contractor picker sheet for the personal-card delegate
        // tap. Uses the existing ContractorDirectoryView so users get the
        // same picker UX they already know from the task detail sheet.
        //
        // Build 87: when a task is being delegated, pass a DelegationContext
        // so the picker renders the new "FIND A PRO" section above the
        // existing contractor list (Find local pros + Ask Alfred). The
        // legacy onSelect path still works for non-delegation entry points.
        .sheet(isPresented: $showDelegateContractorPicker) {
            NavigationStack {
                ContractorDirectoryView(
                    delegationContext: delegatingTask.map { task in
                        DelegationContext(
                            task: task,
                            systemCategory: viewModel.systems.first(where: { $0.id == task.systemId })?.category,
                            onVendorSelected: { contractor in
                                if let delegatingId = delegatingTask?.id {
                                    Task {
                                        await viewModel.convertToVendorManaged(taskId: delegatingId, contractor: contractor)
                                        await viewModel.loadTasks()
                                    }
                                }
                                showDelegateContractorPicker = false
                                delegatingTask = nil
                            },
                            onFindLocalVendors: {
                                // Dismiss the contractor picker first, then
                                // open FindLocalVendorSheet via the existing
                                // `findVendorTask` plumbing. The .sheet(item:)
                                // binding lower in this view tree will
                                // present FindLocalVendorSheet with the
                                // resolved town/state/category.
                                let task = delegatingTask
                                showDelegateContractorPicker = false
                                delegatingTask = nil
                                if let task {
                                    findVendorTask = task
                                }
                            }
                        )
                    }
                )
            }
        }
        // Phase 19n: find-a-contractor sheet — opens FindLocalVendorSheet
        // with the triggering task's town/state/category. The sheet handles
        // contractor creation + bulk task conversion internally.
        .sheet(item: $findVendorTask) { task in
            findVendorSheet(for: task)
        }
        // Phase 19n: when the user taps "Add my own instead" inside
        // FindLocalVendorSheet, that sheet posts .openManualContractorAdd
        // and dismisses. We catch the notification here and present the
        // existing manual contractor add flow as the next sheet.
        .onReceive(NotificationCenter.default.publisher(for: .openManualContractorAdd)) { _ in
            showManualAddFromFindVendor = true
        }
        .sheet(isPresented: $showManualAddFromFindVendor) {
            NavigationStack {
                ContractorDirectoryView(onSelect: { _ in
                    showManualAddFromFindVendor = false
                })
            }
        }
    }

    /// Phase 19n: Resolve the system category for the triggering task and
    /// present FindLocalVendorSheet. We need: town + state from the property,
    /// system category from the linked home_systems row, and a
    /// human-readable display name for the sheet header copy.
    @ViewBuilder
    private func findVendorSheet(for task: MaintenanceTaskDBRow) -> some View {
        let property = task.propertyId.flatMap { id in
            viewModel.properties.first(where: { $0.id == id })
        }
        let system = task.systemId.flatMap { id in
            viewModel.systems.first(where: { $0.id == id })
        }
        let town = property?.city ?? ""
        let state = property?.state ?? ""
        let category = system?.category ?? "general"
        let display = (system?.category ?? "Local").lowercased()

        if town.isEmpty || state.isEmpty {
            // Defensive fallback — without a town/state we can't search.
            // Fall through to the existing manual add path so the user
            // still has a way forward.
            VStack(spacing: HavenTheme.spacing16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(HavenColors.warning)
                Text("Add a city and state to your property to search local vendors.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                HavenButton(title: "Add my own vendor") {
                    findVendorTask = nil
                    showManualAddFromFindVendor = true
                }
            }
            .padding(HavenTheme.spacing24)
            .presentationDetents([.medium])
        } else {
            FindLocalVendorSheet(
                task: task,
                town: town,
                state: state,
                systemCategory: category,
                categoryDisplayName: display,
                onComplete: {
                    Task { await viewModel.loadTasks() }
                }
            )
        }
    }

    // MARK: - Property Filter Pills

    private var propertyFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" pill
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.filterPropertyId = nil
                    }
                } label: {
                    HStack(spacing: 5) {
                        if viewModel.properties.count <= 4 {
                            HStack(spacing: 3) {
                                ForEach(viewModel.propertiesWithColors, id: \.property.id) { item in
                                    Circle().fill(item.color).frame(width: 6, height: 6)
                                }
                            }
                        }
                        Text("All")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(viewModel.filterPropertyId == nil ? HavenColors.navy : HavenColors.creamLight)
                    .foregroundStyle(viewModel.filterPropertyId == nil ? .white : HavenColors.textPrimary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            viewModel.filterPropertyId == nil ? Color.clear : HavenColors.beige300,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)

                // One pill per property
                ForEach(viewModel.propertiesWithColors, id: \.property.id) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if viewModel.filterPropertyId == item.property.id {
                                viewModel.filterPropertyId = nil
                            } else {
                                viewModel.filterPropertyId = item.property.id
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            Text(item.property.name)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(viewModel.filterPropertyId == item.property.id ? item.color.opacity(0.15) : HavenColors.creamLight)
                        .foregroundStyle(viewModel.filterPropertyId == item.property.id ? item.color : HavenColors.textPrimary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                viewModel.filterPropertyId == item.property.id ? item.color.opacity(0.4) : HavenColors.beige300,
                                lineWidth: 1
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            // Property filter
            if viewModel.properties.count > 1 {
                Picker("Property", selection: $viewModel.filterPropertyId) {
                    Text("All Properties").tag(nil as UUID?)
                    ForEach(viewModel.properties) { p in
                        Text(p.name).tag(p.id as UUID?)
                    }
                }
            }

            // Category filter
            if !viewModel.availableCategories.isEmpty {
                Picker("Category", selection: $viewModel.filterCategory) {
                    Text("All Categories").tag(nil as String?)
                    ForEach(viewModel.availableCategories, id: \.self) { cat in
                        Text(cat).tag(cat as String?)
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(HavenColors.navy)
        }
    }

    // MARK: - Task Content

    private var taskContent: some View {
        List {
            Section {
                // Property filter pills (only when 2+ properties)
                if viewModel.properties.count > 1 {
                    propertyFilterBar

                    // Color legend when "All" is selected
                    if viewModel.filterPropertyId == nil {
                        HStack(spacing: 16) {
                            ForEach(viewModel.propertiesWithColors, id: \.property.id) { item in
                                HStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(item.color)
                                        .frame(width: 12, height: 3)
                                    Text(item.property.name)
                                        .font(.system(size: 10))
                                        .foregroundStyle(HavenColors.textTertiary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                    }
                }

                // Build 87: All / Mine / Vendor segmented filter sits above
                // the stats chips so it frames everything below it. Tap on
                // the segments fires haptic feedback and persists per-property
                // via the `viewFilterStorageKey` so the choice carries across
                // sessions.
                viewFilterPicker

                // Summary bar
                summaryBar

                // Active filters indicator
                if viewModel.filterStatus != .all || viewModel.filterPropertyId != nil || viewModel.filterCategory != nil {
                    activeFiltersBar
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            timelineContent
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(HavenColors.background)
        .sheet(item: $selectedTask, onDismiss: {
            Task { await viewModel.loadTasks() }
        }) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(
                    task: task,
                    onTaskCompleted: {
                        viewModel.recentlyCompletedIds.insert(task.id)
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        let nextDate = viewModel.tasks.first(where: { $0.id == task.id })?.nextDueDate ?? ""
                        let displayFormatter = DateFormatter()
                        displayFormatter.dateStyle = .medium
                        if let d = formatter.date(from: nextDate) {
                            viewModel.completionToast = MaintenanceViewModel.CompletionToast(
                                taskTitle: task.title,
                                nextDueDate: displayFormatter.string(from: d)
                            )
                        }
                        Task { await viewModel.loadTasks() }
                    },
                    onDeleteTask: {
                        taskToDelete = task
                        showDeleteConfirm = true
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Not Applicable?", isPresented: $showDeleteConfirm) {
            Button("Remove This Task", role: .destructive) {
                if let task = taskToDelete {
                    Task {
                        await viewModel.deleteTask(task)
                        Haptics.success()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let task = taskToDelete {
                Text("Remove \"\(task.title)\" from your maintenance schedule? Future recurring tasks are not affected.")
            }
        }
        .sheet(isPresented: $showSnooze) {
            NavigationStack {
                DatePicker("Snooze Until", selection: $snoozeDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(HavenColors.navy800)
                    .padding()
                    .navigationTitle("Snooze Task")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showSnooze = false }
                                .foregroundStyle(HavenColors.navy)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save") {
                                guard let task = taskToSnooze else { return }
                                Task {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd"
                                    _ = try? await DatabaseService.shared.updateMaintenanceTask(
                                        id: task.id,
                                        MaintenanceTaskUpdate(nextDueDate: formatter.string(from: snoozeDate))
                                    )
                                    Haptics.success()
                                    showSnooze = false
                                    await viewModel.loadTasks()
                                }
                            }
                            .foregroundStyle(HavenColors.navy)
                            .fontWeight(.semibold)
                        }
                    }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAddTask) {
            AddMaintenanceTaskSheet(
                properties: viewModel.properties,
                systems: viewModel.systems,
                vehicles: viewModel.vehicles,
                contractors: viewModel.contractors,
                householdUsers: viewModel.users,
                viewModel: viewModel
            )
        }
    }

    // MARK: - Phase 19l: Two-bucket grouping (Personal vs Vendor-Managed)

    /// Tasks the household handles themselves: assignmentType == personal,
    /// either, or nil/legacy. Existing date sort is preserved.
    private var personalBucketTasks: [MaintenanceTaskDBRow] {
        viewModel.filteredTasks.filter { task in
            let assignment = task.assignmentType?.lowercased()
            return assignment != "vendor"
        }
    }

    /// Tasks a contractor handles. Includes both linked and "needs vendor"
    /// rows so the user sees the full delegation picture in one place.
    private var vendorBucketTasks: [MaintenanceTaskDBRow] {
        viewModel.filteredTasks.filter { task in
            task.assignmentType?.lowercased() == "vendor"
        }
    }

    private var personalBucketStorageKey: String {
        "maintenance.bucket.\(viewModel.filterPropertyId?.uuidString ?? "all").personal.collapsed"
    }

    private var vendorBucketStorageKey: String {
        "maintenance.bucket.\(viewModel.filterPropertyId?.uuidString ?? "all").vendor.collapsed"
    }

    /// Build 87: per-property persistence key for the All / Mine / Vendor
    /// segmented filter. Mirrors the bucket-collapse storage key pattern.
    private var viewFilterStorageKey: String {
        "maintenance_view_filter_\(viewModel.filterPropertyId?.uuidString ?? "all")"
    }

    private func loadBucketCollapsedState() {
        personalBucketCollapsed = UserDefaults.standard.bool(forKey: personalBucketStorageKey)
        vendorBucketCollapsed = UserDefaults.standard.bool(forKey: vendorBucketStorageKey)
        // Build 87: rehydrate the segmented filter for the active property.
        // Default to .all when nothing has been saved.
        if let raw = UserDefaults.standard.string(forKey: viewFilterStorageKey),
           let stored = MaintenanceViewFilter(rawValue: raw) {
            viewFilter = stored
        } else {
            viewFilter = .all
        }
    }

    private func saveViewFilter() {
        UserDefaults.standard.set(viewFilter.rawValue, forKey: viewFilterStorageKey)
    }

    /// Build 87: applies the segmented filter to a task list. `.all` is a
    /// pass-through; `.mine` returns personal/either tasks (anything not
    /// explicitly assignmentType vendor); `.vendor` returns the vendor-managed
    /// rows. Centralizing the predicate keeps the bucket sections, the stats
    /// chips, and any future call sites in lockstep.
    private func tasksMatchingViewFilter(_ tasks: [MaintenanceTaskDBRow]) -> [MaintenanceTaskDBRow] {
        switch viewFilter {
        case .all:
            return tasks
        case .mine:
            return tasks.filter { ($0.assignmentType?.lowercased() ?? "") != "vendor" }
        case .vendor:
            return tasks.filter { ($0.assignmentType?.lowercased() ?? "") == "vendor" }
        }
    }

    private func togglePersonalBucket() {
        withAnimation(HavenTheme.animationStandard) {
            personalBucketCollapsed.toggle()
        }
        UserDefaults.standard.set(personalBucketCollapsed, forKey: personalBucketStorageKey)
        Haptics.selection()
    }

    private func toggleVendorBucket() {
        withAnimation(HavenTheme.animationStandard) {
            vendorBucketCollapsed.toggle()
        }
        UserDefaults.standard.set(vendorBucketCollapsed, forKey: vendorBucketStorageKey)
        Haptics.selection()
    }

    // MARK: - Timeline Content

    @ViewBuilder
    private var timelineContent: some View {
        if viewModel.filterStatus == .all {
            // Phase 19l: two-bucket grouping replaces the four time-buckets
            // when no filter is active. Personal/either tasks first, then
            // vendor-managed. Tasks within each group keep their date sort
            // (overdue floats to the top because earlier dates sort first).
            //
            // Build 87: the segmented `viewFilter` collapses to a single
            // bucket (force-expanded, no chevron) when not `.all`. The
            // per-bucket collapse state is intentionally bypassed in this
            // mode because hiding the only visible section would leave the
            // screen empty.
            switch viewFilter {
            case .all:
                bucketSection(
                    title: "Your To-Dos",
                    count: personalBucketTasks.count,
                    isCollapsed: personalBucketCollapsed,
                    onToggle: togglePersonalBucket,
                    tasks: personalBucketTasks,
                    emptyCopy: "No personal tasks right now.",
                    showChevron: true
                )
                bucketSection(
                    title: "Vendor-Managed",
                    count: vendorBucketTasks.count,
                    isCollapsed: vendorBucketCollapsed,
                    onToggle: toggleVendorBucket,
                    tasks: vendorBucketTasks,
                    emptyCopy: "No vendor-managed tasks yet.",
                    showChevron: true
                )
            case .mine:
                bucketSection(
                    title: "Your To-Dos",
                    count: personalBucketTasks.count,
                    isCollapsed: false,
                    onToggle: {},
                    tasks: personalBucketTasks,
                    emptyCopy: "No personal tasks right now.",
                    showChevron: false
                )
            case .vendor:
                bucketSection(
                    title: "Vendor-Managed",
                    count: vendorBucketTasks.count,
                    isCollapsed: false,
                    onToggle: {},
                    tasks: vendorBucketTasks,
                    emptyCopy: "No vendor-managed tasks yet.",
                    showChevron: false
                )
            }
        } else {
            Section {
                ForEach(viewModel.filteredTasks) { task in
                    maintenanceRow(task)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                taskToDelete = task
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
        }
    }

    // MARK: - By System Content

    @ViewBuilder
    private var bySystemContent: some View {
        ForEach(viewModel.tasksBySystem, id: \.systemName) { group in
            Section {
                ForEach(group.tasks) { task in
                    maintenanceRow(task)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                taskToDelete = task
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            } header: {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(HavenColors.navy700)
                        .font(.caption)
                    Text(group.systemName)
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(1.5)

                    if viewModel.properties.count > 1, let firstTask = group.tasks.first, let propId = firstTask.propertyId {
                        Circle()
                            .fill(viewModel.propertyColor(for: propId))
                            .frame(width: 6, height: 6)
                        Text(viewModel.propertyName(for: propId))
                            .font(.system(size: 10))
                            .foregroundStyle(viewModel.propertyColor(for: propId))
                    }

                    Spacer()
                    Text("\(group.tasks.count)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.navy700)
                }
            }
        }
    }

    // MARK: - By Type Content

    @ViewBuilder
    private var byTypeContent: some View {
        ForEach(viewModel.tasksByType, id: \.type) { group in
            Section {
                ForEach(group.tasks) { task in
                    maintenanceRow(task)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                taskToDelete = task
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            } header: {
                HStack {
                    Image(systemName: group.type.icon)
                        .foregroundStyle(group.type.color)
                        .font(.caption)
                    Text(group.type.rawValue)
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    Spacer()
                    Text("\(group.tasks.count)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(group.type.color)
                }
            }
        }
    }

    // MARK: - View Filter Picker (Build 87)

    private var viewFilterPicker: some View {
        Picker("Filter", selection: Binding(
            get: { viewFilter },
            set: { newValue in
                Haptics.selection()
                withAnimation(.smooth(duration: 0.25)) {
                    viewFilter = newValue
                }
                saveViewFilter()
            }
        )) {
            ForEach(MaintenanceViewFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.bottom, 4)
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        // Build 87: respect the segmented filter so the four stats chips
        // (Overdue / This Week / This Month / Later) reflect what the user
        // is actually looking at. The viewModel's per-bucket arrays stay
        // unfiltered for use elsewhere (e.g. dashboard); we filter them
        // in-place via `tasksMatchingViewFilter`.
        let overdue = tasksMatchingViewFilter(viewModel.overdueTasks)
        let thisWeek = tasksMatchingViewFilter(viewModel.dueThisWeekTasks)
        let thisMonth = tasksMatchingViewFilter(viewModel.dueThisMonthTasks)
        let later = tasksMatchingViewFilter(viewModel.upcomingTasks)
        return VStack(spacing: 8) {
            // Existing summary pills
            HStack(spacing: 0) {
                summaryPill(count: overdue.count, label: "Overdue", color: HavenColors.critical)
                summaryPill(count: thisWeek.count, label: "This Week", color: HavenColors.warning)
                summaryPill(count: thisMonth.count, label: "This Month", color: HavenColors.info)
                summaryPill(count: later.count, label: "Later", color: HavenColors.success)
            }
            .padding(4)
            .background(HavenColors.cream)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))

            // Per-property overdue counts (only when multiple properties and some are overdue)
            if viewModel.properties.count > 1 && viewModel.overdueTasks.count > 0 {
                HStack(spacing: 12) {
                    ForEach(viewModel.propertiesWithColors, id: \.property.id) { item in
                        // Build 87: also respect the segmented filter so the
                        // per-property overdue chips don't include vendor
                        // tasks when the user is in Mine, etc.
                        let count = tasksMatchingViewFilter(viewModel.overdueTasks).filter { $0.propertyId == item.property.id }.count
                        if count > 0 {
                            HStack(spacing: 4) {
                                Circle().fill(item.color).frame(width: 6, height: 6)
                                Text("\(count) overdue")
                                    .font(.system(size: 10))
                                    .foregroundStyle(item.color)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private func summaryPill(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(HavenTypography.headline)
                .foregroundStyle(count > 0 ? color : HavenColors.textTertiary)
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var activeFiltersBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.navy700)

            if viewModel.filterStatus != .all {
                filterChip(viewModel.filterStatus.rawValue) {
                    viewModel.filterStatus = .all
                }
            }
            if let propId = viewModel.filterPropertyId {
                filterChip(viewModel.propertyName(for: propId)) {
                    viewModel.filterPropertyId = nil
                }
            }
            if let cat = viewModel.filterCategory {
                filterChip(cat) {
                    viewModel.filterCategory = nil
                }
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func filterChip(_ label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.navy700)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(HavenColors.navy.opacity(0.08))
        .clipShape(Capsule())
    }

    // MARK: - Phase 19l: Bucket section

    @ViewBuilder
    private func bucketSection(
        title: String,
        count: Int,
        isCollapsed: Bool,
        onToggle: @escaping () -> Void,
        tasks: [MaintenanceTaskDBRow],
        emptyCopy: String,
        showChevron: Bool = true
    ) -> some View {
        // Build 87: `showChevron == false` is the segmented-filter mode
        // where only one bucket is on screen — render a plain header (no
        // tap target) since collapsing the only visible section would leave
        // the user staring at an empty list.
        Section {
            if isCollapsed {
                EmptyView()
            } else if tasks.isEmpty {
                Text(emptyCopy)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.vertical, HavenTheme.spacing12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            } else {
                ForEach(tasks) { task in
                    maintenanceRow(task)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                taskToDelete = task
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
        } header: {
            if showChevron {
                Button {
                    onToggle()
                } label: {
                    bucketHeaderRow(title: title, count: count, isCollapsed: isCollapsed, showChevron: true)
                }
                .buttonStyle(.plain)
            } else {
                bucketHeaderRow(title: title, count: count, isCollapsed: false, showChevron: false)
            }
        }
    }

    private func bucketHeaderRow(title: String, count: Int, isCollapsed: Bool, showChevron: Bool) -> some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
                .tracking(1.5)
            Text("\u{00B7}")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
            Text("\(count) \(count == 1 ? "task" : "tasks")")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
            Spacer()
            if showChevron {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Task Section

    @ViewBuilder
    private func taskSection(_ title: String, tasks: [MaintenanceTaskDBRow], accentColor: Color) -> some View {
        if !tasks.isEmpty {
            Section {
                ForEach(tasks) { task in
                    maintenanceRow(task)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                taskToDelete = task
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            } header: {
                HStack {
                    Circle().fill(accentColor).frame(width: 8, height: 8)
                    Text(title)
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    Spacer()
                    Text("\(tasks.count)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(accentColor)
                }
            }
        }
    }

    // MARK: - Task Row

    private func maintenanceRow(_ task: MaintenanceTaskDBRow) -> some View {
        // Phase 19l: resolve the contractor row when one is linked, so the
        // vendor-managed card variant can render the brand logo and color.
        let linkedContractor: ContractorRow? = {
            guard let id = task.assignedContractorId else { return nil }
            return viewModel.contractors.first(where: { $0.id == id })
        }()
        let assignment = task.assignmentType?.lowercased()
        let isPersonal = assignment != "vendor"

        return Button {
            Analytics.track(.maintenanceTaskViewed, ["task_id": task.id.uuidString, "task_title": task.title])
            selectedTask = task
        } label: {
            UnifiedTaskCard(
                task: task,
                propertyName: task.propertyId.map { viewModel.propertyName(for: $0) },
                vehicleName: viewModel.vehicleName(for: task.vehicleId),
                systemName: viewModel.systemName(for: task.systemId),
                assigneeName: viewModel.assignedUserName(for: task),
                assigneeAvatarColor: viewModel.assignedUserAvatarColor(for: task),
                contractorName: viewModel.assignedContractorName(for: task),
                contractor: linkedContractor,
                onDelegate: isPersonal ? {
                    delegatingTask = task
                    showDelegateContractorPicker = true
                } : nil,
                onFindVendor: {
                    findVendorTask = task
                }
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                taskToDelete = task
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                taskToSnooze = task
                snoozeDate = {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd"
                    let dueDate = f.date(from: task.nextDueDate) ?? Date()
                    let baseDate = max(dueDate, Date())
                    return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? baseDate
                }()
                showSnooze = true
            } label: {
                Label("Snooze", systemImage: "moon.fill")
            }
            .tint(HavenColors.warning)
        }
        .contextMenu {
            Button {
                taskToSnooze = task
                snoozeDate = {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd"
                    let dueDate = f.date(from: task.nextDueDate) ?? Date()
                    let baseDate = max(dueDate, Date())
                    return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? baseDate
                }()
                showSnooze = true
                Haptics.light()
            } label: {
                Label("Snooze", systemImage: "moon.fill")
            }

            Button {
                selectedTask = task
            } label: {
                Label("Mark Complete", systemImage: "checkmark.circle")
            }

            Divider()

            Button(role: .destructive) {
                taskToDelete = task
                showDeleteConfirm = true
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }

    private func metadataBadge(_ label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(label)
                .lineLimit(1)
        }
        .font(HavenTypography.uiCaption)
        .foregroundStyle(color)
    }
}

#Preview {
    NavigationStack {
        MaintenanceScheduleView()
    }
}

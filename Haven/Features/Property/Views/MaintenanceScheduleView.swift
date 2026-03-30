import SwiftUI

enum MaintenanceViewMode: String, CaseIterable {
    case timeline = "Timeline"
    case bySystem = "By System"
    case byType = "By Type"
}

struct MaintenanceScheduleView: View {
    let prefilterPropertyId: UUID?

    init(filterPropertyId: UUID? = nil) {
        self.prefilterPropertyId = filterPropertyId
    }

    @StateObject private var viewModel = MaintenanceViewModel()
    @State private var viewMode: MaintenanceViewMode = .timeline
    @State private var selectedTask: MaintenanceTaskDBRow?
    @State private var showDeleteConfirm = false
    @State private var taskToDelete: MaintenanceTaskDBRow?
    @State private var showSnooze = false
    @State private var taskToSnooze: MaintenanceTaskDBRow?
    @State private var snoozeDate = Date()
    @State private var showAddTask = false

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
            if viewModel.tasks.isEmpty {
                await viewModel.loadTasks()
            }
            if let id = prefilterPropertyId {
                viewModel.filterPropertyId = id
            }
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
            AddMaintenanceTaskSheet(properties: viewModel.properties, systems: viewModel.systems) {
                Task { await viewModel.loadTasks() }
            }
        }
    }

    // MARK: - Timeline Content

    @ViewBuilder
    private var timelineContent: some View {
        if viewModel.filterStatus == .all {
            taskSection("Overdue", tasks: viewModel.overdueTasks, accentColor: HavenColors.critical)
            taskSection("Due This Week", tasks: viewModel.dueThisWeekTasks, accentColor: HavenColors.warning)
            taskSection("Due This Month", tasks: viewModel.dueThisMonthTasks, accentColor: HavenColors.info)
            taskSection("Upcoming", tasks: viewModel.upcomingTasks, accentColor: HavenColors.success)
        } else {
            Section {
                ForEach(viewModel.filteredTasks) { task in
                    maintenanceRow(task)
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

                    if viewModel.properties.count > 1, let firstTask = group.tasks.first {
                        Circle()
                            .fill(viewModel.propertyColor(for: firstTask.propertyId))
                            .frame(width: 6, height: 6)
                        Text(viewModel.propertyName(for: firstTask.propertyId))
                            .font(.system(size: 10))
                            .foregroundStyle(viewModel.propertyColor(for: firstTask.propertyId))
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

    // MARK: - Summary Bar

    private var summaryBar: some View {
        VStack(spacing: 8) {
            // Existing summary pills
            HStack(spacing: 0) {
                summaryPill(count: viewModel.overdueTasks.count, label: "Overdue", color: HavenColors.critical)
                summaryPill(count: viewModel.dueThisWeekTasks.count, label: "This Week", color: HavenColors.warning)
                summaryPill(count: viewModel.dueThisMonthTasks.count, label: "This Month", color: HavenColors.info)
                summaryPill(count: viewModel.upcomingTasks.count, label: "Later", color: HavenColors.success)
            }
            .padding(4)
            .background(HavenColors.cream)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))

            // Per-property overdue counts (only when multiple properties and some are overdue)
            if viewModel.properties.count > 1 && viewModel.overdueTasks.count > 0 {
                HStack(spacing: 12) {
                    ForEach(viewModel.propertiesWithColors, id: \.property.id) { item in
                        let count = viewModel.overdueTasks.filter { $0.propertyId == item.property.id }.count
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

    // MARK: - Task Section

    @ViewBuilder
    private func taskSection(_ title: String, tasks: [MaintenanceTaskDBRow], accentColor: Color) -> some View {
        if !tasks.isEmpty {
            Section {
                ForEach(tasks) { task in
                    maintenanceRow(task)
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
        let isOverdue: Bool = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            guard let date = f.date(from: task.nextDueDate) else { return false }
            return date < .now
        }()

        let propColor = viewModel.propertyColor(for: task.propertyId)
        let showPropertyLabel = viewModel.properties.count > 1

        return Button {
            Analytics.track(.maintenanceTaskViewed, ["task_id": task.id.uuidString, "task_title": task.title])
            selectedTask = task
        } label: {
            HavenCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        // Status indicator
                        Circle()
                            .fill(isOverdue ? HavenColors.critical : HavenColors.warning)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)

                            HStack(spacing: 6) {
                                // Property name (always shown; color dot only for multi-property)
                                HStack(spacing: 4) {
                                    if showPropertyLabel {
                                        Circle()
                                            .fill(propColor)
                                            .frame(width: 6, height: 6)
                                    }
                                    Text(viewModel.propertyName(for: task.propertyId))
                                        .foregroundStyle(showPropertyLabel ? propColor : HavenColors.textSecondary)
                                }

                                if let sysName = viewModel.systemName(for: task.systemId) {
                                    Text("\u{00B7}")
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text(sysName)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                            }
                            .font(HavenTypography.uiLabelSmall)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            if let priority = task.priority {
                                Text(priority)
                                    .font(HavenTypography.uiCaption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(HavenColors.priorityColor(priority).opacity(0.12))
                                    .foregroundStyle(HavenColors.priorityColor(priority))
                                    .clipShape(Capsule())
                            }

                            Text(task.nextDueDate.havenDateShort)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.textSecondary)
                        }
                    }

                    // Metadata row
                    HStack(spacing: 12) {
                        if let userName = viewModel.assignedUserName(for: task) {
                            metadataBadge(userName, icon: "person.fill", color: HavenColors.navy)
                        }
                        if let vendorName = viewModel.assignedContractorName(for: task) {
                            metadataBadge(vendorName, icon: "wrench.and.screwdriver", color: HavenColors.info)
                        }
                        if task.isDiy == true {
                            metadataBadge("DIY", icon: "hand.raised.fill", color: HavenColors.success)
                        }
                        if task.professionalRequired == true {
                            metadataBadge("Professional", icon: "person.badge.key.fill", color: HavenColors.info)
                        }
                        if let costRange = task.costRange, !costRange.isEmpty {
                            metadataBadge(costRange, icon: "dollarsign.circle", color: HavenColors.textSecondary)
                        }
                        if let season = task.seasonalTiming, !season.isEmpty {
                            metadataBadge(season, icon: "leaf", color: HavenColors.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
            // Color accent bar on the left edge
            .overlay(alignment: .leading) {
                if showPropertyLabel {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(propColor)
                        .frame(width: 3)
                        .padding(.vertical, 6)
                }
            }
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
                Label("Not Applicable", systemImage: "xmark.circle")
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

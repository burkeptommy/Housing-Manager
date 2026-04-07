import SwiftUI

enum PropertyDetailTab: String, CaseIterable {
    case overview
    case maintenance
    case projects
    case contacts

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .maintenance: return "Maintenance"
        case .projects: return "Projects"
        case .contacts: return "Contacts"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "house.fill"
        case .maintenance: return "calendar.badge.clock"
        case .projects: return "hammer.fill"
        case .contacts: return "person.2.fill"
        }
    }
}

struct PropertyDetailView: View {
    let propertyID: UUID
    @StateObject private var viewModel = PropertyDetailViewModel()
    @State private var activeTab: PropertyDetailTab = .maintenance
    @State private var showAddSystem = false
    @State private var showEditProperty = false
    @State private var showDeleteConfirmation = false
    @State private var showDocumentUpload = false
    @State private var showFullSchedule = false
    @State private var showAlfredChat = false
    @State private var selectedTaskForReminder: MaintenanceTaskDBRow?
    @State private var showReminderPicker = false
    @State private var showVendorAssignment = false
    @State private var selectedTaskForVendor: MaintenanceTaskDBRow?
    @State private var taskForDateEdit: MaintenanceTaskDBRow?
    @State private var taskForLastServiced: MaintenanceTaskDBRow?
    @State private var editedTaskDueDate = Date()
    @State private var selectedMaintenanceTask: MaintenanceTaskDBRow?
    @AppStorage("dismissedSeasonalOverview") private var dismissedSeasonalOverview = ""
    @State private var lastServicedTaskDate = Date()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.property == nil {
                ProgressView("Loading property...")
            } else if let property = viewModel.property {
                propertyContent(property)
            } else {
                ContentUnavailableView("Property not found", systemImage: "house")
            }
        }
        .navigationTitle(viewModel.property?.name ?? "Property")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Analytics.track(.propertyEdited, ["property_id": propertyID.uuidString, "source": "menu"])
                        showEditProperty = true
                    } label: {
                        Label("Edit Property", systemImage: "pencil")
                    }
                    Button {
                        Analytics.track(.systemCreated, ["property_id": propertyID.uuidString, "source": "menu"])
                        showAddSystem = true
                    } label: {
                        Label("Add System", systemImage: "plus.circle.fill")
                    }
                    Divider()
                    Button(role: .destructive) {
                        Analytics.track(.propertyDeleted, ["property_id": propertyID.uuidString])
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Property", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(HavenColors.navy)
                }
            }
        }
        .trackScreen("PropertyDetailView", properties: ["property_id": propertyID.uuidString])
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPropertySection)) { notification in
            if let section = notification.userInfo?["section"] as? String {
                withAnimation {
                    switch section {
                    case "overview": activeTab = .overview
                    case "maintenance": activeTab = .maintenance
                    case "projects": activeTab = .projects
                    case "contacts": activeTab = .contacts
                    default: break
                    }
                }
            }
        }
        .task {
            await viewModel.loadProperty(id: propertyID)
        }
        .onAppear {
            // Refresh when returning from detail views so edits reflect immediately
            if viewModel.property != nil {
                Task { await viewModel.loadProperty(id: propertyID) }
            }
        }
        .refreshable {
            Analytics.track(.propertyRefreshed, ["property_id": propertyID.uuidString])
            await viewModel.loadProperty(id: propertyID)
        }
        .sheet(isPresented: $showEditProperty) {
            if let property = viewModel.property {
                EditPropertyView(property: property) { updatedProperty in
                    viewModel.property = updatedProperty
                    NotificationCenter.default.post(name: .propertyChanged, object: nil,
                        userInfo: ["action": "updated", "id": propertyID.uuidString])
                    Task { await viewModel.loadProperty(id: propertyID) }
                }
            }
        }
        .sheet(isPresented: $showDocumentUpload) {
            DocumentUploadView(preselectedPropertyId: propertyID) {
                Task { await viewModel.loadProperty(id: propertyID) }
            }
        }
        .sheet(isPresented: $showAddSystem) {
            AddSystemView(propertyID: propertyID, onComplete: { newSystem in
                viewModel.systems.append(newSystem)
                Task { await viewModel.loadProperty(id: propertyID) }
            })
        }
        .sheet(isPresented: $showAlfredChat) {
            NavigationStack {
                ChatView(contextType: "property", contextId: propertyID)
            }
        }
        .sheet(isPresented: $showReminderPicker) {
            reminderSheet
        }
        .sheet(item: $taskForDateEdit) { task in
            NavigationStack {
                VStack(spacing: 16) {
                    Text("When is \(task.title) actually due?")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)

                    DatePicker("Due Date", selection: $editedTaskDueDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(HavenColors.navy)

                    Spacer()
                }
                .padding()
                .navigationTitle("Edit Due Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { taskForDateEdit = nil }
                            .foregroundStyle(HavenColors.navy)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                let f = DateFormatter()
                                f.dateFormat = "yyyy-MM-dd"
                                _ = try? await DatabaseService.shared.updateMaintenanceTask(
                                    id: task.id,
                                    MaintenanceTaskUpdate(nextDueDate: f.string(from: editedTaskDueDate))
                                )
                                Task { await NotificationScheduler.shared.rescheduleAll() }
                                Haptics.success()
                                taskForDateEdit = nil
                                await viewModel.loadProperty(id: propertyID)
                            }
                        }
                        .foregroundStyle(HavenColors.navy)
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $taskForLastServiced) { task in
            NavigationStack {
                VStack(spacing: 16) {
                    Text("When did you last do \(task.title)?")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("Haven will recalculate the next due date based on the task frequency (\(task.frequency)).")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .multilineTextAlignment(.center)

                    DatePicker("Date Completed", selection: $lastServicedTaskDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(HavenColors.navy)

                    Spacer()
                }
                .padding()
                .navigationTitle("Log Past Service")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { taskForLastServiced = nil }
                            .foregroundStyle(HavenColors.navy)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                let f = DateFormatter()
                                f.dateFormat = "yyyy-MM-dd"
                                let completedStr = f.string(from: lastServicedTaskDate)
                                let nextDate = MaintenanceTaskDetailSheet.calculateNextDue(frequency: task.frequency, from: lastServicedTaskDate)
                                let nextDueStr = f.string(from: nextDate)

                                _ = try? await DatabaseService.shared.updateMaintenanceTask(
                                    id: task.id,
                                    MaintenanceTaskUpdate(lastCompletedDate: completedStr, nextDueDate: nextDueStr)
                                )
                                if let systemId = task.systemId {
                                    _ = try? await DatabaseService.shared.updateHomeSystem(
                                        id: systemId,
                                        HomeSystemUpdate(lastServiceDate: completedStr, nextServiceDue: nextDueStr)
                                    )
                                }
                                Task { await NotificationScheduler.shared.rescheduleAll() }
                                Haptics.success()
                                taskForLastServiced = nil
                                await viewModel.loadProperty(id: propertyID)
                            }
                        }
                        .foregroundStyle(HavenColors.navy)
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .navigationDestination(isPresented: $showFullSchedule) {
            MaintenanceScheduleView(filterPropertyId: propertyID)
        }
        .sheet(item: $selectedMaintenanceTask) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(task: task, onTaskCompleted: {
                    Task { await viewModel.loadProperty(id: propertyID) }
                })
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Delete Property?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await DatabaseService.shared.deleteProperty(id: propertyID)
                        Haptics.success()
                        dismiss()
                    } catch {
                        viewModel.error = "Failed to delete property: \(error.localizedDescription)"
                        Haptics.error()
                    }
                }
            }
        } message: {
            Text("This will delete the property and all associated systems, maintenance tasks, and service records.")
        }
    }

    // MARK: - Main Content

    private func propertyContent(_ property: PropertyRow) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                propertyHeader(property)

                HStack(spacing: 0) {
                    ForEach(PropertyDetailTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeTab = tab
                            }
                            Analytics.track(.propertyTabSelected, ["tab": tab.title, "property_id": propertyID.uuidString])
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16))
                                    .symbolRenderingMode(.hierarchical)
                                Text(tab.title)
                                    .font(HavenTypography.uiCaption)
                            }
                            .foregroundStyle(activeTab == tab ? HavenColors.navy800 : HavenColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                activeTab == tab
                                    ? HavenColors.navy.opacity(0.08)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)

                switch activeTab {
                case .overview:
                    if let prop = viewModel.property {
                        InvestmentSummaryCard(
                            property: prop,
                            totalProjectSpend: viewModel.totalProjectSpend,
                            onValuesUpdated: { update in
                                await viewModel.applyPropertyUpdate(update)
                            }
                        )
                    }
                    UtilityAccountsSection(
                        propertyId: property.id,
                        householdId: property.householdId,
                        accounts: $viewModel.utilityAccounts
                    )
                    propertyDocumentsSection
                    propertyMaintenanceCard
                    if !viewModel.serviceRecords.isEmpty { recentServiceHistoryCard }
                    if !viewModel.activeWarranties.isEmpty { warrantiesSection }

                case .maintenance:
                    if (!viewModel.currentSeasonTasks.isEmpty || !viewModel.nextSeasonTasks.isEmpty),
                       dismissedSeasonalOverview != "\(viewModel.currentSeason) \(Calendar.current.component(.year, from: Date()))" {
                        seasonalOverviewCard
                    }
                    if !viewModel.overdueTasks.isEmpty { overdueSection }
                    systemsSection
                    if !viewModel.upcomingTasks.isEmpty { upcomingMaintenanceSection }
                    if !viewModel.serviceRecords.isEmpty { serviceHistorySection }

                case .projects:
                    PropertyProjectsView(
                        propertyID: propertyID,
                        householdId: viewModel.property?.householdId,
                        propertyLocation: [viewModel.property?.city, viewModel.property?.state].compactMap { $0 }.joined(separator: ", ")
                    )

                case .contacts:
                    vendorsSection
                    if !viewModel.serviceRecords.isEmpty { serviceHistorySection }
                }
            }
            .padding()
        }
        .background(HavenColors.background)
    }

    // MARK: - Header

    private func propertyHeader(_ property: PropertyRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.name)
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(property.propertyType)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "house.fill")
                        .font(.title)
                        .foregroundStyle(HavenColors.navy)
                }

                if let street = property.street {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(street)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        if let city = property.city, let state = property.state {
                            Text("\(city), \(state) \(property.zipCode ?? "")")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }

                HStack(spacing: 20) {
                    if let sqft = property.squareFootage {
                        propertyDetail(label: "Sq Ft", value: "\(sqft.formatted())")
                    }
                    if let year = property.yearBuilt {
                        propertyDetail(label: "Built", value: "\(year)")
                    }
                    if let value = property.currentEstimatedValue, value > 0 {
                        let formatter: NumberFormatter = {
                            let f = NumberFormatter()
                            f.numberStyle = .currency
                            f.maximumFractionDigits = 0
                            return f
                        }()
                        propertyDetail(label: "Est. Value", value: formatter.string(from: NSNumber(value: value)) ?? "")
                    }
                    if let entity = property.ownershipEntity, !entity.isEmpty {
                        propertyDetail(label: "Entity", value: entity)
                    }
                }

                // Ask Alfred — contextual chat
                Button {
                    showAlfredChat = true
                } label: {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(HavenColors.navy800)
                                .frame(width: 20, height: 20)
                            Text("A")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundStyle(HavenColors.creamLight)
                        }
                        Text("Ask Alfred about this property")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .padding(HavenTheme.spacing8)
                    .background(HavenColors.navy.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func propertyDetail(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            quickActionButton(icon: "bubble.left.fill", label: "Chat") {
                showAlfredChat = true
            }
            quickActionButton(icon: "clock.fill", label: "Service History") {
                showFullSchedule = true
            }
            quickActionButton(icon: "plus.circle.fill", label: "Add System") {
                showAddSystem = true
            }
        }
    }

    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(HavenColors.navy700)
                Text(label)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(HavenColors.cream)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Maintenance Summary

    private var propertyMaintenanceCard: some View {
        NavigationLink {
            MaintenanceScheduleView(filterPropertyId: propertyID)
        } label: {
            HavenCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundStyle(HavenColors.navy700)
                        Text("HOME MAINTENANCE")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    HStack(spacing: 16) {
                        maintenanceStat(
                            count: viewModel.overdueTasks.count,
                            label: "Overdue",
                            color: HavenColors.critical
                        )
                        maintenanceStat(
                            count: viewModel.dueThisMonthTasks.count,
                            label: "This Month",
                            color: HavenColors.warning
                        )
                        maintenanceStat(
                            count: viewModel.upcomingTasks.count,
                            label: "Upcoming",
                            color: HavenColors.success
                        )
                    }

                    if let next = viewModel.upcomingTasks.first {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("Next: \(next.title)")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSecondary)
                            Spacer()
                            Text(next.nextDueDate.havenDateShort)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    if viewModel.maintenanceTasks.isEmpty {
                        Text("Add home systems to start tracking maintenance.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func maintenanceStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(max(0, count))")
                .font(HavenTypography.title2)
                .foregroundStyle(count > 0 ? color : HavenColors.textTertiary)
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Seasonal Overview

    private var seasonalOverviewCard: some View {
        let season = viewModel.currentSeason

        return NavigationLink {
            SeasonalTasksDetailView(
                season: season,
                tasks: viewModel.currentSeasonTasks,
                completedCount: viewModel.currentSeasonCompletedCount,
                nextSeason: viewModel.nextSeason,
                nextSeasonTasks: viewModel.nextSeasonTasks,
                systemNameLookup: { viewModel.systemName(for: $0) }
            )
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: seasonIcon(season))
                        .foregroundStyle(seasonColor(season))
                    Text("Seasonal Overview")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    let groups = SeasonalTaskGrouper.group(viewModel.currentSeasonTasks, systemNameLookup: { viewModel.systemName(for: $0) })
                    let groupsDone = groups.filter(\.isComplete).count
                    HStack {
                        Text(season)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                        Text("\(groupsDone) of \(groups.count) done")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    if !viewModel.currentSeasonTasks.isEmpty {
                        ProgressView(
                            value: Double(viewModel.currentSeasonCompletedCount),
                            total: Double(viewModel.currentSeasonTasks.count)
                        )
                        .tint(seasonColor(season))
                    }
                }

                if !viewModel.nextSeasonTasks.isEmpty {
                    let nextGroups = SeasonalTaskGrouper.group(viewModel.nextSeasonTasks, systemNameLookup: { viewModel.systemName(for: $0) })
                    HStack(spacing: 6) {
                        Image(systemName: seasonIcon(viewModel.nextSeason))
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("Coming up in \(viewModel.nextSeason): \(nextGroups.count) areas")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
            .padding(HavenTheme.spacing16)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .fill(seasonColor(season).opacity(0.08))
            )
            .overlay {
                let icons = seasonBackgroundIcons(season)
                let color = seasonColor(season).opacity(0.07)
                ZStack {
                    Image(systemName: icons[0])
                        .font(.system(size: 20)).rotationEffect(.degrees(-15)).offset(x: -100, y: -10)
                    Image(systemName: icons.count > 1 ? icons[1] : icons[0])
                        .font(.system(size: 14)).rotationEffect(.degrees(20)).offset(x: -60, y: 8)
                    Image(systemName: icons[0])
                        .font(.system(size: 24)).rotationEffect(.degrees(10)).offset(x: 40, y: -5)
                    Image(systemName: icons.count > 1 ? icons[1] : icons[0])
                        .font(.system(size: 18)).rotationEffect(.degrees(-25)).offset(x: 110, y: 5)
                    Image(systemName: icons.count > 2 ? icons[2] : icons[0])
                        .font(.system(size: 16)).rotationEffect(.degrees(35)).offset(x: 80, y: -15)
                    Image(systemName: icons[0])
                        .font(.system(size: 12)).rotationEffect(.degrees(-10)).offset(x: -20, y: 15)
                    Image(systemName: icons.count > 1 ? icons[1] : icons[0])
                        .font(.system(size: 22)).rotationEffect(.degrees(15)).offset(x: 140, y: 0)
                }
                .foregroundStyle(color)
                .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                dismissedSeasonalOverview = "\(season) \(Calendar.current.component(.year, from: Date()))"
            } label: {
                Label("Dismiss for \(season)", systemImage: "xmark.circle")
            }
        }
    }

    private func seasonColor(_ season: String) -> Color {
        switch season {
        case "Spring": return .green
        case "Summer": return .yellow
        case "Fall": return .orange
        case "Winter": return .blue
        default: return HavenColors.navy
        }
    }

    private func seasonIcon(_ season: String) -> String {
        switch season {
        case "Spring": return "leaf.fill"
        case "Summer": return "sun.max.fill"
        case "Fall": return "wind"
        case "Winter": return "snowflake"
        default: return "calendar"
        }
    }

    private func seasonBackgroundIcons(_ season: String) -> [String] {
        switch season {
        case "Spring": return ["leaf.fill", "cloud.rain.fill", "drop.fill"]
        case "Summer": return ["sun.max.fill", "cloud.sun.fill", "drop.fill"]
        case "Fall": return ["leaf.fill", "wind", "cloud.fill"]
        case "Winter": return ["snowflake", "wind", "cloud.snow.fill"]
        default: return ["leaf.fill"]
        }
    }

    // MARK: - Overdue

    private var overdueSection: some View {
        NavigationLink {
            OverdueTasksDetailView(
                tasks: viewModel.overdueTasks,
                systemNameLookup: { viewModel.systemName(for: $0) },
                propertyAddress: viewModel.property?.street ?? "my property"
            )
        } label: {
            HavenCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HavenColors.critical)
                        Text("Overdue Maintenance")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                        Text("\(viewModel.overdueTasks.count)")
                            .font(HavenTypography.uiLabelSmall)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(HavenColors.critical.opacity(0.12))
                            .foregroundStyle(HavenColors.critical)
                            .clipShape(Capsule())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    ForEach(viewModel.overdueTasks.prefix(3)) { task in
                        Button {
                            selectedMaintenanceTask = task
                        } label: {
                            HStack {
                                Circle().fill(HavenColors.critical).frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(HavenTypography.bodySmall)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    if let systemName = viewModel.systemName(for: task.systemId) {
                                        Text(systemName)
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    if viewModel.overdueTasks.count > 3 {
                        Text("+ \(viewModel.overdueTasks.count - 3) more")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Systems

    private var systemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Home Systems")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Button {
                    Haptics.light()
                    showAddSystem = true
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

            if viewModel.systems.isEmpty {
                HavenCard {
                    VStack(spacing: 10) {
                        Image(systemName: "gearshape.2")
                            .font(.title2)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("What systems does your home have?")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("Add your HVAC, plumbing, electrical and more — Haven will track maintenance for you.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .multilineTextAlignment(.center)

                        Button {
                            Haptics.light()
                            showAddSystem = true
                        } label: {
                            Text("Add a Home System")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy800)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } else {
                let groups = SystemGroup.group(viewModel.systems).sorted { $0.systems.count > $1.systems.count }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(groups) { group in
                            if group.systems.count == 1, group.id != "other" {
                                NavigationLink {
                                    SystemDetailRowView(system: group.systems[0])
                                } label: {
                                    compactSystemChip(icon: group.icon, name: shortGroupName(group.name), count: group.systems.count)
                                }
                                .buttonStyle(.plain)
                            } else if !group.systems.isEmpty {
                                NavigationLink {
                                    SystemGroupListView(
                                        group: group,
                                        propertyId: propertyID,
                                        householdId: viewModel.property?.householdId ?? UUID()
                                    )
                                } label: {
                                    compactSystemChip(icon: group.icon, name: shortGroupName(group.name), count: group.systems.count)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    // MARK: - Upcoming Maintenance (Next 30 Days)

    private var upcomingMaintenanceSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(HavenColors.warning)
                    Text("Upcoming Maintenance")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Text("Next 30 days")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                let upcomingSlice = Array(viewModel.upcomingTasks.prefix(5))
                ForEach(Array(upcomingSlice.enumerated()), id: \.element.id) { index, task in
                    Button {
                        selectedMaintenanceTask = task
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                HStack(spacing: 8) {
                                    Text("Due: \(task.nextDueDate.havenDateShort)")
                                        .font(HavenTypography.uiLabelSmall)
                                        .foregroundStyle(HavenColors.textSecondary)
                                    if let systemName = viewModel.systemName(for: task.systemId) {
                                        Text(systemName)
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                    }
                                }
                            }
                            Spacer()
                            taskActionMenu(task)
                        }
                    }
                    .buttonStyle(.plain)

                    if index < upcomingSlice.count - 1 {
                        Divider().padding(.horizontal, 4)
                    }
                }

                if viewModel.upcomingTasks.count > 5 {
                    Button {
                        showFullSchedule = true
                    } label: {
                        Text("View All (\(viewModel.upcomingTasks.count))")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }
            }
        }
    }

    // MARK: - Warranties

    private var warrantiesSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(HavenColors.info)
                    Text("Active Warranties")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                }

                ForEach(viewModel.activeWarranties) { warranty in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(warranty.provider)
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Expires: \(warranty.endDate)")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        if let phone = warranty.claimPhone,
                           let url = sanitizedPhoneURL(phone) {
                            Link(destination: url) {
                                Image(systemName: "phone.fill")
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Property Documents (moved higher in layout)

    private var propertyDocumentsSection: some View {
        VStack(spacing: HavenTheme.spacing8) {
        NavigationLink {
            PropertyDocumentsView(propertyId: propertyID, propertyName: viewModel.property?.name ?? "Property")
        } label: {
            HavenCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(HavenColors.navy700)
                        Text("Property Documents")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()

                        Text("\(viewModel.linkedDocuments.count)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(HavenColors.beige200)
                            .clipShape(Capsule())

                        Image(systemName: "chevron.right")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    if viewModel.linkedDocuments.isEmpty {
                        Text("Upload deeds, insurance, blueprints, quotes, and more")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else {
                        // Show first 3 docs as preview
                        ForEach(viewModel.linkedDocuments.prefix(3)) { doc in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.havenSuccess)
                                    .font(.caption)
                                Text(doc.title)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text(doc.category)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                        }

                        if viewModel.linkedDocuments.count > 3 {
                            Text("+ \(viewModel.linkedDocuments.count - 3) more")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.navy700)
                        }
                    }

                    // Missing doc prompts
                    let missingCount = viewModel.missingPropertyDocTypes.count
                    if missingCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundStyle(HavenColors.warning)
                            Text("\(missingCount) suggested document\(missingCount == 1 ? "" : "s") to upload")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)

        // Quick upload button
        Button {
            showDocumentUpload = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.doc.fill")
                    .font(.caption)
                Text("Upload Property Document")
                    .font(HavenTypography.uiLabel)
            }
            .foregroundStyle(HavenColors.navy700)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(HavenColors.navy.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        } // end VStack wrapper
    }

    // MARK: - Vendors

    private var vendorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Home & Estate Contacts")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                NavigationLink {
                    ContractorDirectoryView()
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

            // Show ALL household contractors (not just system-assigned)
            if viewModel.contractors.isEmpty {
                HavenCard {
                    VStack(spacing: 10) {
                        Image(systemName: "person.2")
                            .font(.title2)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("Add your trusted contractors and service providers here.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 12) {
                            NavigationLink {
                                ContractorDirectoryView()
                            } label: {
                                Text("Add a Vendor")
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy800)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(HavenColors.navy.opacity(0.08))
                                    .clipShape(Capsule())
                            }

                            Button {
                                Haptics.light()
                                showAlfredChat = true
                            } label: {
                                Text("Ask Alfred to Find One")
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy700)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .overlay(Capsule().stroke(HavenColors.navy.opacity(0.2), lineWidth: 1))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } else {
                ForEach(viewModel.contractors) { contractor in
                    NavigationLink {
                        ContractorDetailView(contractor: contractor)
                    } label: {
                        contractorCardInline(contractor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func contractorCardInline(_ contractor: ContractorRow) -> some View {
        HavenCard(padding: HavenTheme.spacing12) {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title3)
                    .foregroundStyle(HavenColors.navy)

                VStack(alignment: .leading, spacing: 2) {
                    Text(contractor.companyName)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let specialties = contractor.specialties, !specialties.isEmpty {
                        Text(specialties.joined(separator: ", "))
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    } else if let contact = contractor.contactName {
                        Text(contact)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Spacer()

                if let rating = contractor.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(HavenColors.warning)
                        Text("\(rating)")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    // MARK: - Service History

    /// Compact service history for the Overview tab — last 3 records.
    private var recentServiceHistoryCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(HavenColors.textSecondary)
                    Text("Recent Service")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                }

                let overviewServiceSlice = Array(viewModel.serviceRecords.prefix(3))
                ForEach(Array(overviewServiceSlice.enumerated()), id: \.element.id) { index, record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.description)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(1)
                            Text(record.serviceDate)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        Spacer()
                        if let cost = record.cost {
                            Text("$\(cost, specifier: "%.0f")")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                    }

                    if index < overviewServiceSlice.count - 1 {
                        Divider().padding(.horizontal, 4)
                    }
                }

                if viewModel.serviceRecords.count > 3 {
                    NavigationLink {
                        ServiceHistoryView()
                    } label: {
                        Text("View All (\(viewModel.serviceRecords.count))")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }
            }
        }
    }

    private var serviceHistorySection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(HavenColors.textSecondary)
                    Text("Recent Service History")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    if viewModel.totalServiceCost > 0 {
                        Text("$\(viewModel.totalServiceCost, specifier: "%.0f") total")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                let serviceSlice = Array(viewModel.serviceRecords.prefix(5))
                ForEach(Array(serviceSlice.enumerated()), id: \.element.id) { index, record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.description)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(2)
                            Text(record.serviceDate)
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        if let cost = record.cost {
                            Text("$\(cost, specifier: "%.0f")")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                    }

                    if index < serviceSlice.count - 1 {
                        Divider().padding(.horizontal, 4)
                    }
                }

                if viewModel.serviceRecords.count > 5 {
                    NavigationLink {
                        ServiceHistoryView()
                    } label: {
                        Text("View All (\(viewModel.serviceRecords.count))")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }
            }
        }
    }

    // MARK: - Task Action Menu

    private func taskActionMenu(_ task: MaintenanceTaskDBRow) -> some View {
        Menu {
            Button {
                Task { await viewModel.completeMaintenanceTask(task) }
            } label: {
                Label("Mark Complete", systemImage: "checkmark.circle")
            }

            if let vendorName = viewModel.vendorName(for: task.systemId),
               let vendorPhone = viewModel.vendorPhone(for: task.systemId) {
                Button {
                    if let url = sanitizedPhoneURL(vendorPhone) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Call \(vendorName)", systemImage: "phone")
                }

                if let vendorEmail = viewModel.vendorEmail(for: task.systemId) {
                    Button {
                        if let url = sanitizedEmailURL(vendorEmail) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Email \(vendorName)", systemImage: "envelope")
                    }
                }
            }

            if viewModel.vendorName(for: task.systemId) == nil {
                NavigationLink {
                    ContractorDirectoryView()
                } label: {
                    Label("Assign a Vendor", systemImage: "person.badge.plus")
                }
            }

            Button {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                editedTaskDueDate = f.date(from: task.nextDueDate) ?? Date()
                taskForDateEdit = task
            } label: {
                Label("Edit Due Date", systemImage: "calendar.badge.clock")
            }

            Button {
                taskForLastServiced = task
            } label: {
                Label("I Already Did This", systemImage: "checkmark.circle.badge.questionmark")
            }

            Button {
                selectedTaskForReminder = task
                showReminderPicker = true
            } label: {
                Label("Set Reminder", systemImage: "bell")
            }

            Button {
                showAlfredChat = true
            } label: {
                Label("Ask Alfred for Help", systemImage: "bubble.left")
            }

            Divider()

            Menu("Snooze") {
                Button("1 Week") { Task { await viewModel.snoozeTask(task, days: 7) } }
                Button("2 Weeks") { Task { await viewModel.snoozeTask(task, days: 14) } }
                Button("1 Month") { Task { await viewModel.snoozeTask(task, days: 30) } }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body)
                .foregroundStyle(HavenColors.navy700)
        }
    }

    // MARK: - Reminder Sheet

    private var reminderSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("When should we remind you?")
                    .font(HavenTypography.headline)

                ForEach(["Tomorrow", "In 3 Days", "Next Week", "Next Month"], id: \.self) { option in
                    Button {
                        Task {
                            await viewModel.setReminder(for: selectedTaskForReminder, option: option)
                        }
                        showReminderPicker = false
                    } label: {
                        Text(option)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(HavenColors.creamLight)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .presentationDetents([.height(300)])
            .navigationTitle("Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showReminderPicker = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func compactSystemChip(icon: String, name: String, count: Int) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(HavenColors.navy700)
            Text(name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(HavenColors.navy800)
                .lineLimit(1)
            Text("\(count)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(HavenColors.navy.opacity(0.06))
                .cornerRadius(8)
        }
        .frame(width: 80, height: 75)
        .background(HavenColors.surface)
        .cornerRadius(HavenTheme.radiusMedium)
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.border.opacity(0.5), lineWidth: 0.5)
        }
    }

    private func shortGroupName(_ name: String) -> String {
        switch name {
        case "Climate & Energy": return "Climate"
        case "Structure & Exterior": return "Exterior"
        case "Plumbing & Water": return "Plumbing"
        case "Smoke & Fire Protection": return "Safety"
        case "Other Systems": return "Other"
        default: return name
        }
    }

    private func systemGroupCard(_ group: SystemGroup) -> some View {
        VStack(spacing: 8) {
            Image(systemName: group.icon)
                .font(.system(size: 22))
                .foregroundStyle(HavenColors.navy700)

            Text(group.name)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.navy800)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text("\(group.systems.count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(HavenColors.navy)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(HavenColors.navy.opacity(0.1))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .padding(12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(HavenColors.beige300, lineWidth: 0.5)
        )
    }

    private func systemGridCard(_ system: HomeSystemRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(systemStatusColor(system.status))
                    .frame(width: 8, height: 8)
                Text(system.name)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
            }
            if let mfr = system.manufacturer {
                HStack(spacing: 4) {
                    Text(mfr)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(1)
                    if let model = system.modelNumber {
                        Text("·")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(model)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            if let nextDue = system.nextServiceDue {
                Text("Due: \(nextDue)")
                    .font(.system(size: 10))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(HavenColors.beige300, lineWidth: 0.5)
        )
    }

    private func systemStatusColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "good": return HavenColors.success
        case "needs maintenance": return HavenColors.warning
        case "needs repair", "needs replacement": return HavenColors.critical
        case "under warranty": return HavenColors.info
        case "out of service": return HavenColors.textTertiary
        default: return HavenColors.success
        }
    }

    private func sanitizedPhoneURL(_ phone: String) -> URL? {
        let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return URL(string: "tel:\(cleaned)")
    }

    private func sanitizedEmailURL(_ email: String) -> URL? {
        URL(string: "mailto:\(email.trimmingCharacters(in: .whitespaces))")
    }
}

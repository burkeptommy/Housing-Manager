import SwiftUI
import UserNotifications

struct MaintenanceTaskDetailSheet: View {
    let task: MaintenanceTaskDBRow
    var onTaskCompleted: (() -> Void)?
    var onDeleteTask: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var showCompleteForm = false
    @State private var showSnooze = false
    @State private var snoozeDate = Date()
    @State private var showScheduleChat = false
    @State private var showContractorDirectory = false
    @State private var showEditDueDate = false
    @State private var editedDueDate = Date()
    @State private var showLastServicedPicker = false
    @State private var lastServicedDate = Date()
    @State private var showEditFrequency = false
    @State private var editedFrequency: String = ""
    @State private var showScheduledPicker = false
    @State private var scheduledPickerDate = Date()

    // Vendor state
    @State private var assignedContractor: ContractorRow?
    @State private var systemCategory: String?
    @State private var vendorLoaded = false
    @State private var showVendorAssignedToast = false

    // User assignment state
    @State private var householdUsers: [UserRow] = []
    @State private var assignedUserId: UUID?
    @State private var originalAssignedUserId: UUID?

    // Reminder state
    @State private var reminder1Day = false
    @State private var reminder3Days = false
    @State private var reminder1Week = false
    @State private var reminder2Weeks = false
    @State private var reminder1Month = false

    private let db = DatabaseService.shared
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var daysUntilDue: Int {
        guard let date = dateFormatter.date(from: task.nextDueDate) else { return 0 }
        return Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
    }

    private var dueColor: Color {
        if daysUntilDue < 0 { return HavenColors.critical }
        if daysUntilDue <= 7 { return HavenColors.critical }
        if daysUntilDue <= 30 { return HavenColors.warning }
        return HavenColors.success
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                // Header
                headerSection

                // Details
                detailsSection

                // Assign to household member
                if householdUsers.count > 1 {
                    assignToSection
                }

                // Vendor / Scheduling
                if vendorLoaded {
                    vendorSection
                }

                // Reminders
                remindersSection

                // Actions
                actionsSection
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, HavenTheme.spacing16)
        }
        .background(HavenColors.background)
        .overlay(alignment: .bottom) {
            if showVendorAssignedToast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.success)
                    Text("\(assignedContractor?.companyName ?? "Vendor") assigned")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                }
                .padding()
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showVendorAssignedToast)
        .onChange(of: showVendorAssignedToast) { _, showing in
            if showing {
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation { showVendorAssignedToast = false }
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    // Send push notification if assignment changed
                    if assignedUserId != originalAssignedUserId, let userId = assignedUserId {
                        let assigneeName = householdUsers.first(where: { $0.id == userId })?.fullName?.components(separatedBy: " ").first ?? "Someone"
                        let recipientIds = householdUsers.map(\.id)
                        Task {
                            await PushNotificationService.shared.sendTaskAssignmentNotification(
                                taskTitle: task.title,
                                assigneeName: assigneeName,
                                recipientUserIds: recipientIds,
                                taskId: task.id
                            )
                        }
                    }
                    dismiss()
                }
                    .foregroundStyle(HavenColors.navy)
            }
        }
        .trackScreen("MaintenanceTaskDetailSheet", properties: ["task_id": task.id.uuidString, "task_title": task.title])
        .sheet(isPresented: $showCompleteForm) {
            NavigationStack {
                MarkCompleteForm(task: task, onComplete: {
                    Analytics.track(.maintenanceTaskCompleted, ["task_id": task.id.uuidString, "task_title": task.title])
                    onTaskCompleted?()
                    dismiss()
                })
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showScheduleChat) {
            NavigationStack {
                ChatView(
                    contextType: "property",
                    contextId: task.propertyId,
                    initialPrompt: "Please schedule \(task.title) with \(assignedContractor?.companyName ?? "my vendor"). It's due \(task.nextDueDate.havenDateFormatted)."
                )
            }
        }
        .sheet(isPresented: $showContractorDirectory) {
            NavigationStack {
                ContractorDirectoryView(onSelect: { contractor in
                    showContractorDirectory = false
                    Task { await assignContractorToTask(contractor) }
                })
            }
        }
        .task {
            await loadVendorInfo()
            await loadExistingReminders()
            await loadHouseholdUsers()
        }
    }

    // MARK: - Vendor Loading

    private func loadVendorInfo() async {
        do {
            let contractors = try await db.fetchContractors()

            // Check for directly assigned contractor
            if let contractorId = task.assignedContractorId {
                assignedContractor = contractors.first { $0.id == contractorId }
            }

            // If no direct assignment, check the system's preferred contractor
            if assignedContractor == nil, let systemId = task.systemId {
                let systems = try await db.fetchHomeSystems(propertyId: task.propertyId)
                if let system = systems.first(where: { $0.id == systemId }) {
                    systemCategory = system.category
                    if let prefId = system.preferredContractorId {
                        assignedContractor = contractors.first { $0.id == prefId }
                    }
                }
            }

            // Extract category from templateId if we don't have it yet (e.g., "HVAC:Filter Change")
            if systemCategory == nil, let templateId = task.templateId {
                systemCategory = templateId.components(separatedBy: ":").first
            }
        } catch {
            print("[TaskDetail] Failed to load vendor info: \(error.localizedDescription)")
        }
        vendorLoaded = true
    }

    private func assignContractorToTask(_ contractor: ContractorRow) async {
        do {
            _ = try await db.updateMaintenanceTask(
                id: task.id,
                MaintenanceTaskUpdate(assignedContractorId: contractor.id)
            )
            await MainActor.run {
                assignedContractor = contractor
                withAnimation { showVendorAssignedToast = true }
            }
            Haptics.success()
            Analytics.track(.maintenanceTaskAssigned, [
                "task_id": task.id.uuidString,
                "contractor_id": contractor.id.uuidString,
                "contractor_name": contractor.companyName
            ])

            // Remember this vendor as the system's preferred contractor for future suggestions
            if let systemId = task.systemId {
                _ = try? await db.updateHomeSystem(
                    id: systemId,
                    HomeSystemUpdate(preferredContractorId: contractor.id)
                )
            }
        } catch {
            print("[TaskDetail] Failed to assign contractor: \(error)")
            Haptics.error()
        }
    }

    private func unassignContractor() async {
        do {
            try await db.clearMaintenanceTaskContractor(id: task.id)
            await MainActor.run { assignedContractor = nil }
            Haptics.success()
            Analytics.track(.maintenanceTaskAssigned, [
                "task_id": task.id.uuidString,
                "contractor_id": "unassigned"
            ])
        } catch {
            print("[TaskDetail] Failed to unassign contractor: \(error)")
            Haptics.error()
        }
    }

    private func loadExistingReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let taskPrefix = "task-reminder-\(task.id.uuidString)-"
        let ids = Set(pending.filter { $0.identifier.hasPrefix(taskPrefix) }.map(\.identifier))

        reminder1Day = ids.contains("\(taskPrefix)1d")
        reminder3Days = ids.contains("\(taskPrefix)3d")
        reminder1Week = ids.contains("\(taskPrefix)7d")
        reminder2Weeks = ids.contains("\(taskPrefix)14d")
        reminder1Month = ids.contains("\(taskPrefix)30d")
    }

    private func toggleReminder(daysBefore: Int, isEnabled: Bool) {
        guard let dueDate = dateFormatter.date(from: task.nextDueDate) else { return }
        Analytics.track(.maintenanceTaskReminderSet, ["task_id": task.id.uuidString, "days_before": daysBefore, "enabled": isEnabled])

        let center = UNUserNotificationCenter.current()
        let notificationId = "task-reminder-\(task.id.uuidString)-\(daysBefore)d"

        if isEnabled {
            guard let alertDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: dueDate),
                  alertDate > .now else { return }

            let content = UNMutableNotificationContent()
            content.title = "Maintenance Reminder"
            content.body = "\(task.title) is due in \(daysBefore) day\(daysBefore == 1 ? "" : "s")."
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
            center.add(request)
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text(task.title)
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)

            HStack(spacing: HavenTheme.spacing12) {
                Button {
                    editedFrequency = task.frequency
                    showEditFrequency = true
                } label: {
                    HStack(spacing: 4) {
                        Text(task.frequency)
                        Image(systemName: "pencil")
                            .font(.system(size: 9))
                    }
                    .font(HavenTypography.uiLabelSmall)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(HavenColors.beige300.opacity(0.5))
                    .clipShape(Capsule())
                    .foregroundStyle(HavenColors.textSecondary)
                }
                .buttonStyle(.plain)

                if let priority = task.priority {
                    Text(priority)
                        .font(HavenTypography.uiLabelSmall)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(HavenColors.priorityColor(priority).opacity(0.12))
                        .foregroundStyle(HavenColors.priorityColor(priority))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                // Due date — tappable to edit
                Button {
                    if let date = dateFormatter.date(from: task.nextDueDate) {
                        editedDueDate = date
                    }
                    showEditDueDate = true
                } label: {
                    HStack {
                        Text("Next Due")
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                        HStack(spacing: 6) {
                            Text(task.nextDueDate.havenDateFormatted)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(daysUntilDue < 0 ? "(\(-daysUntilDue)d overdue)" : "(\(daysUntilDue)d)")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(dueColor)
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                                .foregroundStyle(HavenColors.navy700)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if let lastCompleted = task.lastCompletedDate {
                    HStack {
                        Text("Last Completed")
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                        Text(lastCompleted.havenDateFormatted)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }

                if let scheduled = task.scheduledDate {
                    HStack {
                        Text("Scheduled")
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 12))
                                .foregroundStyle(HavenColors.success)
                            Text(scheduled.havenDateFormatted)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.success)
                        }
                    }
                }

                // "I already did this" — log a past service and recalculate due date
                Button {
                    showLastServicedPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 13))
                        Text("I already did this")
                            .font(HavenTypography.uiLabelSmall)
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if let cost = task.estimatedCost {
                    HStack {
                        Text("Estimated Cost")
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                        Text("$\(cost, specifier: "%.0f")")
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }

                if let desc = task.description, !desc.isEmpty {
                    Divider().overlay(HavenColors.beige200)
                    Text(desc)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if let notes = task.notes, !notes.isEmpty {
                    Divider().overlay(HavenColors.beige200)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NOTES")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(notes)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditDueDate) {
            editDueDateSheet
        }
        .sheet(isPresented: $showLastServicedPicker) {
            lastServicedSheet
        }
        .sheet(isPresented: $showEditFrequency) {
            editFrequencySheet
        }
    }

    // MARK: - Edit Due Date Sheet

    private var editDueDateSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("When is this actually due?")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)

                DatePicker("Due Date", selection: $editedDueDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(HavenColors.navy)

                Spacer()
            }
            .padding()
            .navigationTitle("Edit Due Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditDueDate = false }
                        .foregroundStyle(HavenColors.navy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            do {
                                _ = try await DatabaseService.shared.updateMaintenanceTask(
                                    id: task.id,
                                    MaintenanceTaskUpdate(nextDueDate: formatter.string(from: editedDueDate))
                                )
                                Analytics.track(.maintenanceTaskDueDateEdited, ["task_id": task.id.uuidString])
                                Task { await NotificationScheduler.shared.rescheduleAll() }
                                Haptics.success()
                                showEditDueDate = false
                                dismiss()
                            } catch {
                                Haptics.error()
                            }
                        }
                    }
                    .foregroundStyle(HavenColors.navy)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - "I Already Did This" Sheet

    private var lastServicedSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("When did you last do this?")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)

                Text("Haven will recalculate the next due date based on the task frequency (\(task.frequency)).")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .multilineTextAlignment(.center)

                DatePicker("Date Completed", selection: $lastServicedDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(HavenColors.navy)

                Spacer()
            }
            .padding()
            .navigationTitle("Log Past Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showLastServicedPicker = false }
                        .foregroundStyle(HavenColors.navy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveLastServiced() }
                    }
                    .foregroundStyle(HavenColors.navy)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveLastServiced() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let completedStr = formatter.string(from: lastServicedDate)

        // Calculate next due date from the service date + frequency
        let nextDate = Self.calculateNextDue(frequency: task.frequency, from: lastServicedDate)
        let nextDueStr = formatter.string(from: nextDate)

        do {
            _ = try await DatabaseService.shared.updateMaintenanceTask(
                id: task.id,
                MaintenanceTaskUpdate(
                    lastCompletedDate: completedStr,
                    nextDueDate: nextDueStr
                )
            )

            // Also update the parent system's dates if applicable
            if let systemId = task.systemId {
                _ = try? await DatabaseService.shared.updateHomeSystem(
                    id: systemId,
                    HomeSystemUpdate(
                        lastServiceDate: completedStr,
                        nextServiceDue: nextDueStr
                    )
                )
            }

            Task { await NotificationScheduler.shared.rescheduleAll() }
            Haptics.success()
            onTaskCompleted?()
            showLastServicedPicker = false
            dismiss()
        } catch {
            Haptics.error()
        }
    }

    // MARK: - Edit Frequency Sheet

    private static let frequencyOptions = [
        "Monthly", "Every 2 Months", "Quarterly", "Every 4 Months",
        "Semi-Annually", "Annually", "Every 2 Years", "Every 3 Years", "Every 5 Years"
    ]

    private var editFrequencySheet: some View {
        NavigationStack {
            List {
                ForEach(Self.frequencyOptions, id: \.self) { option in
                    Button {
                        editedFrequency = option
                    } label: {
                        HStack {
                            Text(option)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                            if editedFrequency == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(HavenColors.navy)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Change Frequency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditFrequency = false }
                        .foregroundStyle(HavenColors.navy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveFrequency() }
                    }
                    .foregroundStyle(HavenColors.navy)
                    .fontWeight(.semibold)
                    .disabled(editedFrequency == task.frequency)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveFrequency() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Recalculate next due date from last completed (or now) + new frequency
        let baseDate: Date
        if let lastCompleted = task.lastCompletedDate, let parsed = formatter.date(from: lastCompleted) {
            baseDate = parsed
        } else {
            baseDate = .now
        }
        let nextDate = Self.calculateNextDue(frequency: editedFrequency, from: baseDate)

        do {
            _ = try await DatabaseService.shared.updateMaintenanceTask(
                id: task.id,
                MaintenanceTaskUpdate(
                    frequency: editedFrequency,
                    nextDueDate: formatter.string(from: nextDate)
                )
            )
            Analytics.track(.maintenanceTaskFrequencyEdited, ["task_id": task.id.uuidString, "new_frequency": editedFrequency])
            Task { await NotificationScheduler.shared.rescheduleAll() }
            Haptics.success()
            showEditFrequency = false
            dismiss()
        } catch {
            Haptics.error()
        }
    }

    static func calculateNextDue(frequency: String, from date: Date) -> Date {
        let cal = Calendar.current
        switch frequency.lowercased() {
        case "weekly":
            return cal.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case "biweekly", "bi-weekly":
            return cal.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case "monthly":
            return cal.date(byAdding: .month, value: 1, to: date) ?? date
        case "every 2 months":
            return cal.date(byAdding: .month, value: 2, to: date) ?? date
        case "quarterly", "every 3 months":
            return cal.date(byAdding: .month, value: 3, to: date) ?? date
        case "every 4 months":
            return cal.date(byAdding: .month, value: 4, to: date) ?? date
        case "semi-annually", "biannually", "every 6 months", "twice a year":
            return cal.date(byAdding: .month, value: 6, to: date) ?? date
        case "annually", "yearly", "every year":
            return cal.date(byAdding: .year, value: 1, to: date) ?? date
        case "every 2 years":
            return cal.date(byAdding: .year, value: 2, to: date) ?? date
        case "every 5 years":
            return cal.date(byAdding: .year, value: 5, to: date) ?? date
        default:
            // Try to parse "every X months" pattern
            let lower = frequency.lowercased()
            if lower.contains("month"), let num = Int(lower.filter(\.isNumber)) {
                return cal.date(byAdding: .month, value: num, to: date) ?? date
            }
            if lower.contains("year"), let num = Int(lower.filter(\.isNumber)) {
                return cal.date(byAdding: .year, value: num, to: date) ?? date
            }
            // Default: 3 months
            return cal.date(byAdding: .month, value: 3, to: date) ?? date
        }
    }

    // MARK: - Vendor / Scheduling

    private var vendorSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Text("SCHEDULING")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                if let contractor = assignedContractor {
                    // Vendor is assigned — show info + Call button
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(HavenColors.navy600)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(contractor.companyName)
                                .font(HavenTypography.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(HavenColors.textPrimary)
                            if let contact = contractor.contactName, !contact.isEmpty {
                                Text(contact)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Text(contractor.phone)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        Spacer()
                    }

                    Button {
                        Haptics.light()
                        let digits = contractor.phone.filter(\.isNumber)
                        if let url = URL(string: "tel://\(digits)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Call \(contractor.companyName)")
                        }
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textOnNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: HavenTheme.buttonHeight)
                        .background(HavenColors.navy)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }

                    HStack {
                        Spacer()
                        Button {
                            Haptics.light()
                            Task { await unassignContractor() }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle")
                                Text("Remove Vendor")
                            }
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.critical)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                } else {
                    // No vendor — prompt to set one up
                    let categoryLabel = systemCategory ?? "this system"

                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        HStack(spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver")
                                .foregroundStyle(HavenColors.navy600)
                            Text("No vendor assigned")
                                .font(HavenTypography.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(HavenColors.textPrimary)
                        }

                        Text("Add a \(categoryLabel) vendor and Alfred can automatically schedule your maintenance tasks.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)

                        Button {
                            Haptics.light()
                            showContractorDirectory = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add a Vendor")
                            }
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy800)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    // MARK: - Reminders

    private var remindersSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Text("REMINDERS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                Toggle("1 day before", isOn: $reminder1Day)
                    .font(HavenTypography.bodySmall)
                    .tint(HavenColors.navy800)
                    .onChange(of: reminder1Day) { _, newValue in
                        toggleReminder(daysBefore: 1, isEnabled: newValue)
                    }
                Toggle("3 days before", isOn: $reminder3Days)
                    .font(HavenTypography.bodySmall)
                    .tint(HavenColors.navy800)
                    .onChange(of: reminder3Days) { _, newValue in
                        toggleReminder(daysBefore: 3, isEnabled: newValue)
                    }
                Toggle("1 week before", isOn: $reminder1Week)
                    .font(HavenTypography.bodySmall)
                    .tint(HavenColors.navy800)
                    .onChange(of: reminder1Week) { _, newValue in
                        toggleReminder(daysBefore: 7, isEnabled: newValue)
                    }
                Toggle("2 weeks before", isOn: $reminder2Weeks)
                    .font(HavenTypography.bodySmall)
                    .tint(HavenColors.navy800)
                    .onChange(of: reminder2Weeks) { _, newValue in
                        toggleReminder(daysBefore: 14, isEnabled: newValue)
                    }
                Toggle("1 month before", isOn: $reminder1Month)
                    .font(HavenTypography.bodySmall)
                    .tint(HavenColors.navy800)
                    .onChange(of: reminder1Month) { _, newValue in
                        toggleReminder(daysBefore: 30, isEnabled: newValue)
                    }
            }
        }
    }

    // MARK: - Assign To

    private var assignToSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 16))
                        .foregroundStyle(HavenColors.navy700)
                    Text("Assign To")
                        .font(HavenTypography.headline)
                }

                ForEach(householdUsers, id: \.id) { user in
                    Button {
                        Haptics.light()
                        let previousId = assignedUserId
                        let newId = assignedUserId == user.id ? nil : user.id
                        assignedUserId = newId
                        Task { await updateAssignment(userId: newId, previousUserId: previousId) }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: assignedUserId == user.id ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(assignedUserId == user.id ? HavenColors.navy : HavenColors.beige300)

                            Text(user.fullName?.components(separatedBy: " ").first ?? user.fullName ?? "Member")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)

                            Spacer()

                            if assignedUserId == user.id {
                                Text("Assigned")
                                    .font(HavenTypography.badgeLabel)
                                    .foregroundStyle(HavenColors.navy)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(HavenColors.navy.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func loadHouseholdUsers() async {
        householdUsers = (try? await db.fetchHouseholdUsers()) ?? []
        assignedUserId = task.assignedToUserId
        originalAssignedUserId = task.assignedToUserId
    }

    private func updateAssignment(userId: UUID?, previousUserId: UUID?) async {
        do {
            _ = try await db.clearMaintenanceTaskAssignment(id: task.id, userId: userId)
            Haptics.success()
            Analytics.track(.maintenanceTaskAssigned, ["task_id": task.id.uuidString, "assigned_user_id": userId?.uuidString ?? "unassigned"])
        } catch {
            print("[TaskDetail] Failed to update assignment: \(error)")
            // Revert UI to previous state on failure
            await MainActor.run { assignedUserId = previousUserId }
            Haptics.error()
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: HavenTheme.spacing12) {
            Button {
                Haptics.light()
                Analytics.track(.maintenanceTaskCompleted, ["task_id": task.id.uuidString, "source": "button"])
                showCompleteForm = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Mark as Complete")
                }
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.textOnNavy)
                .frame(maxWidth: .infinity)
                .frame(height: HavenTheme.buttonHeight)
                .background(HavenColors.navy)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }

            Button {
                Haptics.light()
                if let scheduled = task.scheduledDate, let date = dateFormatter.date(from: scheduled) {
                    scheduledPickerDate = date
                }
                showScheduledPicker = true
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.checkmark")
                    Text(task.scheduledDate != nil ? "Reschedule" : "Scheduled")
                }
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.navy800)
                .frame(maxWidth: .infinity)
                .frame(height: HavenTheme.buttonHeight)
                .background(HavenColors.creamLight)
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                        .stroke(HavenColors.beige300, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }

            Button {
                Haptics.light()
                Analytics.track(.maintenanceTaskSnoozed, ["task_id": task.id.uuidString])
                showSnooze = true
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Snooze")
                }
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.navy800)
                .frame(maxWidth: .infinity)
                .frame(height: HavenTheme.buttonHeight)
                .background(HavenColors.creamLight)
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                        .stroke(HavenColors.beige300, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }

            Button {
                Haptics.light()
                Analytics.track(.maintenanceTaskDeleted, ["task_id": task.id.uuidString])
                onDeleteTask?()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Not Relevant to My Home")
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: HavenTheme.buttonHeight)
            }
            .sheet(isPresented: $showSnooze) {
                NavigationStack {
                    DatePicker("New Due Date", selection: $snoozeDate, displayedComponents: .date)
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
                                    Task {
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "yyyy-MM-dd"
                                        do {
                                            _ = try await DatabaseService.shared.updateMaintenanceTask(
                                                id: task.id,
                                                MaintenanceTaskUpdate(
                                                    nextDueDate: formatter.string(from: snoozeDate)
                                                )
                                            )
                                            Task { await NotificationScheduler.shared.rescheduleAll() }
                                            Haptics.success()
                                            showSnooze = false
                                            dismiss()
                                        } catch {
                                            print("[Snooze] Failed: \(error.localizedDescription)")
                                            Haptics.error()
                                        }
                                    }
                                }
                                .foregroundStyle(HavenColors.navy)
                                .fontWeight(.semibold)
                            }
                        }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showScheduledPicker) {
                NavigationStack {
                    DatePicker("Scheduled Date", selection: $scheduledPickerDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(HavenColors.navy800)
                        .padding()
                        .navigationTitle("Schedule Task")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Cancel") { showScheduledPicker = false }
                                    .foregroundStyle(HavenColors.navy)
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Save") {
                                    Task {
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "yyyy-MM-dd"
                                        do {
                                            _ = try await DatabaseService.shared.updateMaintenanceTask(
                                                id: task.id,
                                                MaintenanceTaskUpdate(
                                                    scheduledDate: formatter.string(from: scheduledPickerDate)
                                                )
                                            )
                                            Task { await NotificationScheduler.shared.rescheduleAll() }
                                            Haptics.success()
                                            showScheduledPicker = false
                                        } catch {
                                            print("[Schedule] Failed: \(error.localizedDescription)")
                                            Haptics.error()
                                        }
                                    }
                                }
                                .foregroundStyle(HavenColors.navy)
                                .fontWeight(.semibold)
                            }
                        }
                }
                .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Mark Complete Form

struct MarkCompleteForm: View {
    let task: MaintenanceTaskDBRow
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var completionDate = Date()
    @State private var cost = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        Form {
            Section {
                DatePicker("Date Completed", selection: $completionDate, displayedComponents: .date)
                    .tint(HavenColors.navy800)
                    .font(HavenTypography.body)
            } header: {
                Text("COMPLETION DATE")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
            }

            Section {
                TextField("Cost", text: $cost)
                    .font(HavenTypography.body)
                    .keyboardType(.decimalPad)
            } header: {
                Text("COST")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
            }

            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .font(HavenTypography.body)
                    .lineLimit(3...6)
            } header: {
                Text("NOTES")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
            }

            if let saveError {
                Section {
                    Text(saveError)
                        .foregroundStyle(HavenColors.critical)
                        .font(HavenTypography.caption)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(HavenColors.background)
        .navigationTitle("Mark Complete")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(HavenColors.navy)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task { await saveCompletion() }
                }
                .disabled(isSaving)
                .foregroundStyle(HavenColors.navy)
                .fontWeight(.semibold)
            }
        }
    }

    private func saveCompletion() async {
        isSaving = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        do {
            let db = DatabaseService.shared

            let nextDate = calculateNextDueDate(frequency: task.frequency, from: completionDate)

            // 1. Update the task
            _ = try await db.updateMaintenanceTask(
                id: task.id,
                MaintenanceTaskUpdate(
                    lastCompletedDate: formatter.string(from: completionDate),
                    nextDueDate: formatter.string(from: nextDate),
                    notes: notes.isEmpty ? task.notes : notes
                )
            )

            // 2. Create service record
            _ = try await db.createServiceRecord(ServiceRecordInsert(
                propertyId: task.propertyId,
                householdId: task.householdId,
                serviceDate: formatter.string(from: completionDate),
                serviceType: "maintenance",
                description: task.title,
                systemId: task.systemId,
                cost: Double(cost),
                notes: notes.isEmpty ? nil : notes
            ))

            // 3. Update parent system dates
            if let systemId = task.systemId {
                _ = try await db.updateHomeSystem(
                    id: systemId,
                    HomeSystemUpdate(
                        lastServiceDate: formatter.string(from: completionDate),
                        nextServiceDue: formatter.string(from: nextDate)
                    )
                )
            }

            // 4. Reschedule notifications
            Task { await NotificationScheduler.shared.rescheduleAll() }

            Haptics.success()
            dismiss()
            onComplete()
        } catch {
            saveError = error.localizedDescription
            Haptics.error()
            isSaving = false
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
}

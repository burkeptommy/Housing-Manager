import SwiftUI
import UserNotifications

/// Time-of-day slot for scheduling vendor visits.
/// Matches how real vendor calls end: "We'll come Thursday morning."
enum ScheduleTimeSlot: String, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case allDay = "All Day"

    var label: String { rawValue }
}

/// Phase 56.4: Reminder offset options. Replaces the 5 separate `@State`
/// bools (`reminder1Day`, `reminder3Days`, etc.) so the summary + expand
/// UI can read from a single source. Raw value serializes to the
/// user-facing label; `daysBefore` is the offset used for scheduling.
enum ReminderTiming: String, CaseIterable {
    case oneDay = "1 day before"
    case threeDays = "3 days before"
    case oneWeek = "1 week before"
    case twoWeeks = "2 weeks before"
    case oneMonth = "1 month before"

    var daysBefore: Int {
        switch self {
        case .oneDay: return 1
        case .threeDays: return 3
        case .oneWeek: return 7
        case .twoWeeks: return 14
        case .oneMonth: return 30
        }
    }

    var sortOrder: Int { daysBefore }
}

struct MaintenanceTaskDetailSheet: View {
    let task: MaintenanceTaskDBRow
    var onTaskCompleted: (() -> Void)?
    var onDeleteTask: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var showCompleteForm = false
    @State private var showSnooze = false
    @State private var snoozeDate = Date()
    /// Phase 80.2 — Local mirror of `task.chezOwned` for the
    /// `ChezOwnsToggle` Binding. Seeded from the task on first appear.
    @State private var localChezOwned: Bool = false
    /// Phase 95 audit (Wave 5c) — drives the "Request a window" sheet
    /// for Chez-owned tasks.
    @State private var showRequestSlotSheet: Bool = false
    /// Friend feedback (May 2026) — when the homeowner taps "View full
    /// thread →" inside the ChezTaskActivityCard, drive the navigation
    /// destination from this binding. The detail sheet is already
    /// wrapped in a NavigationStack by every presenter, so push works.
    @State private var chezThreadToOpen: UUID?
    @State private var showScheduleChat = false
    @State private var showContractorDirectory = false
    @State private var showHandymanPunchList = false
    @State private var showFindLocalVendor = false
    @State private var showManualAddFromFindVendor = false
    /// Phase X feedback: carries the canonical picker category from
    /// FindLocalVendorSheet's "Add my own" notification, forwarded to
    /// ContractorDirectoryView's inner AddVendorSheet so it pre-selects
    /// the specialty.
    @State private var manualAddFromFindVendorCategory: String? = nil
    @State private var showEditDueDate = false
    @State private var editedDueDate = Date()
    @State private var showLastServicedPicker = false
    @State private var lastServicedDate = Date()
    @State private var showEditFrequency = false
    @State private var editedFrequency: String = ""
    @State private var showScheduledPicker = false
    @State private var scheduledPickerDate = Date()

    /// Phase 56.3+: Inline rename state. Tap the title → TextField takes
    /// over in place; Return / outside tap commits, empty / unchanged
    /// reverts. Vendor-reframed titles ("Schedule Tyler Heating: …")
    /// drop the prefix when the user starts typing so they edit the
    /// real task, not the reframing.
    @State private var isEditingTitle = false
    @State private var editedTitle: String = ""
    @FocusState private var titleFieldFocused: Bool

    // Phase 51B: Inline schedule visit
    @State private var showScheduleVisit = false
    @State private var scheduleDate = Date()
    @State private var scheduleTimeSlot: ScheduleTimeSlot = .allDay
    @State private var makeRecurring = false
    @State private var recurringCadence = "monthly"
    @State private var isScheduling = false

    // Phase 67H: bundle custom subitems (homeowner additions to a
    // bundle parent's "What's included" list). Loaded on-appear when
    // the task is a bundle parent. The "Once" subitems attached to
    // this specific task render alongside the always-recurring ones.
    @State private var customSubitems: [BundleCustomSubitemRow] = []
    @State private var showAddSubitemSheet = false

    // Vendor state
    @State private var assignedContractor: ContractorRow?
    @State private var systemCategory: String?
    @State private var vendorLoaded = false
    @State private var showVendorAssignedToast = false

    // Phase 64: routing picker state. currentRoute mirrors task.assignedRoute
    // so the picker re-renders after a tap without waiting for a DB round-trip.
    @State private var currentRoute: String?
    @State private var preferredHandyman: ContractorRow?
    @State private var propertyTown = ""
    @State private var propertyState = ""
    // Phase 65: toast shown after the first pick per category ("We'll remember
    // this for future Plumbing tasks").
    @State private var showRoutingRememberedToast = false
    @State private var rememberedToastCategory: String?

    // User assignment state
    @State private var householdUsers: [UserRow] = []
    /// Build 87 (Home Manager expansion): family_members rows for the
    /// current household. Used to look up `linkedUserId` → `memberType` so
    /// the assignee picker can append "· Home Manager" / "· Staff" to
    /// each user's first name.
    @State private var householdFamilyMembersForRoles: [FamilyMemberRow] = []
    @State private var assignedUserId: UUID?
    @State private var originalAssignedUserId: UUID?

    /// Phase 19l: Bidirectional toggle confirmation. Set true when the user
    /// taps "I'll do this myself" on a vendor-managed task.
    @State private var showConvertToPersonalConfirm = false

    // Phase 56.4: Reminder state consolidated into `activeReminders` above.

    /// Phase 54B.3: Add-to-handyman-punch-list flow. The "Add to handyman
    /// list" button appears for personal/either tasks where the matched
    /// template's DIY effort is under an hour — bigger jobs aren't a fit
    /// for a handyman punch list.
    @State private var showAddedToPunchListToast = false
    @State private var isAddingToPunchList = false
    /// Phase 78: separate spinner for the new "Have my handyman do
    /// this →" delegate action. Distinct from `isAddingToPunchList`
    /// so the two CTAs can co-exist without one disabling the other.
    @State private var isDelegatingToHandyman = false

    /// Phase 56.4: Confirmation dialog for "Add to handyman list" when
    /// the task is already vendor-assigned. Offers Just this time /
    /// From now on / Cancel so the user can choose whether the vendor
    /// keeps future instances or the series flips back to flexible
    /// assignment.
    @State private var showHandymanReassignConfirm = false

    /// Phase 56.4: Smart reminder state. Replaces the 5-toggle block
    /// with a single summary row + "Adjust" expansion. `remindersLoaded`
    /// prevents the smart default from overwriting user-set values.
    @State private var remindersExpanded = false
    @State private var remindersLoaded = false

    /// Phase 56.4: Unified reminder set. Replaces the 5 @State bools —
    /// one set of active timings means the view can render either the
    /// summary row ("Reminding you 1 week before") or the expanded
    /// 5-toggle grid without splitting state across two sources.
    @State private var activeReminders: Set<ReminderTiming> = []

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

    /// Phase 67H: true when this task is a bundle parent — has a
    /// "What's included" block AND a templateId we can use as the
    /// bundleId for new custom subitems. Drives the Custom Additions
    /// section + Add button visibility.
    private var isBundleParent: Bool {
        !bundledChecklistItems.isEmpty && task.templateId != nil
    }

    /// Bundled maintenance tasks often store their generated checklist in
    /// `notes`, and some legacy rows also duplicated that same checklist in
    /// `description`. We split that block out so it renders once as
    /// "What's included" instead of showing up again under Notes.
    private var bundledChecklistBlock: String? {
        if let notes = task.notes,
           let block = extractBundledChecklist(from: notes) {
            return block
        }
        if let description = task.description,
           let block = extractBundledChecklist(from: description) {
            return block
        }
        return nil
    }

    private var bundledChecklistItems: [String] {
        guard let bundledChecklistBlock else { return [] }
        return bundledChecklistBlock
            .components(separatedBy: .newlines)
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("- ") }
            .map { String($0.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var visibleDescription: String? {
        cleanedTaskCopy(task.description)
    }

    private var visibleNotes: String? {
        guard let cleaned = cleanedTaskCopy(task.notes) else { return nil }
        if let visibleDescription,
           cleaned.caseInsensitiveCompare(visibleDescription) == .orderedSame {
            return nil
        }
        return cleaned
    }

    private func cleanedTaskCopy(_ raw: String?) -> String? {
        guard var text = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return nil }

        if let bundledChecklistBlock {
            text = text.replacingOccurrences(of: bundledChecklistBlock, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return text.isEmpty ? nil : text
    }

    private func extractBundledChecklist(from text: String) -> String? {
        guard let range = text.range(of: "What's included:") else { return nil }

        let trailing = String(text[range.lowerBound...])
        let firstParagraph = trailing
            .components(separatedBy: "\n\n")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let bulletCount = firstParagraph
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("- ") }
            .count

        return bulletCount > 0 ? firstParagraph : nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                // Header
                headerSection

                // Phase 80.2 — "Have Chez handle this task" delegation
                // toggle. Lives right under the header so it's the first
                // option the user sees on any task, vendor or no vendor.
                // Smart copy: tasks without a vendor frame as "Chez
                // sources one"; tasks with a vendor frame as "Chez
                // coordinates with your vendor."
                if task.vehicleId == nil {
                    ChezOwnsToggle(
                        target: .task(
                            id: task.id,
                            title: task.title,
                            hasVendor: task.assignedContractorId != nil
                                && (task.needsVendor != true)
                        ),
                        isOwned: $localChezOwned,
                        onChange: { _ in
                            // Refresh the maintenance list so the badge
                            // appears on cards immediately.
                            NotificationCenter.default.post(
                                name: .maintenanceTaskChanged,
                                object: nil
                            )
                        }
                    )

                    // Phase 95 audit (Wave 5c) — when the task IS chez-
                    // owned, surface a "Request a window" CTA. Without
                    // this, the homeowner has zero agency in WHEN Chez
                    // schedules the work — Chez just proposes dates.
                    // This sheet captures preferred date + time-of-day
                    // and posts a coordinate_task request thread that
                    // the operator picks up on the cockpit.
                    if localChezOwned {
                        Button {
                            Haptics.medium()
                            showRequestSlotSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Request a window")
                                    .font(HavenTypography.uiButton)
                            }
                            .foregroundStyle(HavenColors.action)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(HavenColors.action.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                        }
                        .buttonStyle(.plain)

                        // Friend feedback (May 2026) — surface what Chez
                        // has actually done. Renders the parent request's
                        // status pill, SLA caption, and the most recent
                        // concierge/system messages so the homeowner can
                        // see the work in motion without leaving the
                        // detail sheet.
                        if let requestId = task.chezRequestId {
                            ChezTaskActivityCard(
                                taskTitle: task.title,
                                chezRequestId: requestId,
                                onOpenThread: { id in
                                    chezThreadToOpen = id
                                }
                            )
                        }
                    }
                }

                // Details
                detailsSection

                // Assign to household member
                if householdUsers.count > 1 {
                    assignToSection
                }

                // Phase 64: Routing picker surfaces ONLY when a routing
                // decision is genuinely outstanding — task.assignedRoute
                // is nil AND no contractor is assigned. In any other case
                // the existing vendorSection below already shows the
                // vendor / "I'll do this myself" controls, so a second
                // picker would be redundant chrome. Vehicle tasks use
                // a separate vehicle-side flow, so they're skipped too.
                if task.vehicleId == nil
                    && task.assignedRoute == nil
                    && task.assignedContractorId == nil {
                    routingPickerSection
                }

                // Vendor / Scheduling
                if vendorLoaded {
                    vendorSection
                }

                // Schedule Visit (when vendor assigned but not yet scheduled)
                scheduleVisitSection

                // Recurring service details (Phase 51B)
                recurringServiceSection

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
            } else if showAddedToPunchListToast {
                HStack(spacing: 10) {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(HavenColors.navy700)
                    Text("Added to your contractor punch list")
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
        .animation(.easeInOut, value: showAddedToPunchListToast)
        .onChange(of: showVendorAssignedToast) { _, showing in
            if showing {
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation { showVendorAssignedToast = false }
                }
            }
        }
        // Phase 56.4: Confirmation dialog for "Add to handyman list" on
        // a vendor-assigned task. Offers the user a choice between
        // Just this time (leave vendor on future instances) and From
        // now on (strip vendor from the series). DIY tasks never
        // trigger this — they add directly.
        .confirmationDialog(
            "\(assignedContractor?.companyName ?? "Your vendor") usually does this.",
            isPresented: $showHandymanReassignConfirm,
            titleVisibility: .visible
        ) {
            Button("Just this time") {
                Task { await addToPunchListJustThisTime() }
            }
            Button("From now on, handyman does this") {
                Task { await addToPunchListReassignSeries() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What should happen with future visits?")
        }
        // Phase 19l: confirmation before flipping a vendor-managed task back
        // to personal. Restoring the original template title is irreversible
        // from the UI side, so we ask once before mutating the row.
        .alert("Take this back from your vendor?", isPresented: $showConvertToPersonalConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("I'll do it myself") {
                Task {
                    await MaintenanceViewModel.shared.convertToPersonal(taskId: task.id)
                    NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                    dismiss()
                }
            }
        } message: {
            Text("We'll move this task back to your to-do list and restore the original instructions.")
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        // Friend feedback (May 2026) — ChezTaskActivityCard's "View
        // full thread →" pushes the full Chez request thread without
        // leaving this NavigationStack.
        .navigationDestination(item: $chezThreadToOpen) { requestId in
            ChezRequestDetailView(requestId: requestId)
        }
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
                    // Notify parent views to refresh task data
                    NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                    dismiss()
                }
                    .foregroundStyle(HavenColors.textPrimary)
            }
        }
        .trackScreen("MaintenanceTaskDetailSheet", properties: ["task_id": task.id.uuidString, "task_title": task.title])
        .sheet(isPresented: $showCompleteForm) {
            NavigationStack {
                MarkCompleteForm(
                    task: task,
                    contractorId: assignedContractor?.id,
                    onComplete: {
                        Analytics.track(.maintenanceTaskCompleted, ["task_id": task.id.uuidString, "task_title": task.title])
                        onTaskCompleted?()
                        dismiss()
                    }
                )
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
        // Phase 95 audit (Wave 5c) — homeowner-initiated slot request
        // for a Chez-owned task. Captures preferred date + time-of-day
        // and posts a coordinate_task chez_request thread.
        .sheet(isPresented: $showRequestSlotSheet) {
            RequestChezSlotSheet(
                source: .task(task),
                householdId: task.householdId,
                onSubmitted: {
                    showRequestSlotSheet = false
                }
            )
        }
        .sheet(isPresented: $showContractorDirectory) {
            NavigationStack {
                ContractorDirectoryView(
                    delegationContext: DelegationContext(
                        task: task,
                        systemCategory: vendorSearchCategory,
                        onVendorSelected: { contractor in
                            showContractorDirectory = false
                            Task { await assignContractorToTask(contractor) }
                        },
                        onFindLocalVendors: {
                            showContractorDirectory = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showFindLocalVendor = true
                            }
                        }
                    )
                )
            }
        }
        .sheet(isPresented: $showHandymanPunchList) {
            NavigationStack {
                HandymanPunchListView(
                    householdId: task.householdId,
                    propertyId: task.propertyId
                )
            }
        }
        .sheet(isPresented: $showFindLocalVendor) {
            vendorSearchSheet
        }
        .task {
            // Seed the Chez delegation toggle from the task's persisted
            // state so the switch reflects truth on first paint.
            localChezOwned = task.isChezOwned
            await loadVendorInfo()
            await loadRoutingContext()
            await loadExistingReminders()
            await loadHouseholdUsers()
            await loadUpcomingVisits()
            await loadPropertyContext()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openManualContractorAdd)) { notification in
            // Phase X feedback: propagate FindLocalVendorSheet's category
            // through to the inner AddVendorSheet so the user doesn't hit
            // the "Pick a category" picker when they hit "+" inside the
            // contractor directory.
            manualAddFromFindVendorCategory = notification.userInfo?["system_category"] as? String
            showManualAddFromFindVendor = true
        }
        .sheet(isPresented: $showManualAddFromFindVendor) {
            NavigationStack {
                ContractorDirectoryView(
                    onSelect: { contractor in
                        showManualAddFromFindVendor = false
                        Task { await assignContractorToTask(contractor) }
                    },
                    prefilledCategoryOnAdd: manualAddFromFindVendorCategory
                )
            }
        }
        .sheet(isPresented: $showPauseFromDetail) {
            if let appointment = appointmentToPauseFromDetail {
                PauseAppointmentSheet(
                    appointment: appointment,
                    contractor: assignedContractor,
                    categoryDefault: nil,
                    onPause: { reason, resumeDate in
                        Task {
                            try? await StandingAppointmentViewModel.shared.pauseAppointment(
                                id: appointment.id,
                                reason: reason,
                                autoResumeDate: resumeDate
                            )
                        }
                    }
                )
            }
        }
        // Phase 67H: bundle custom subitem add sheet. Only relevant for
        // bundle parents — the Add button is gated on `isBundleParent`
        // so this sheet is unreachable for standalone tasks even if the
        // state flag accidentally flips.
        .sheet(isPresented: $showAddSubitemSheet) {
            if let bundleId = task.templateId,
               let propertyId = task.propertyId {
                AddBundleSubitemSheet(
                    bundleId: bundleId,
                    bundleDisplayName: task.title,
                    propertyId: propertyId,
                    householdId: task.householdId,
                    onCreated: { newRow in
                        // Optimistic insert so the section refreshes
                        // without an extra DB round-trip.
                        customSubitems.append(newRow)
                    }
                )
            }
        }
        .task {
            await loadCustomSubitems()
        }
    }

    // MARK: - Phase 67H: Bundle Custom Subitems

    /// Loads pending custom subitems (always + once) for this bundle
    /// parent. No-op when the task isn't a bundle parent. Called from
    /// the view's `.task` block on appear.
    private func loadCustomSubitems() async {
        guard isBundleParent,
              let bundleId = task.templateId,
              let propertyId = task.propertyId else { return }
        do {
            let rows = try await db.fetchBundleCustomSubitems(
                householdId: task.householdId,
                propertyId: propertyId,
                bundleId: bundleId
            )
            // Render the rows that will appear on THIS bundle parent
            // task: every always-recurring row (regardless of
            // scope_task_id) + once rows that are either pending
            // (scope_task_id == nil) or already attached to this task.
            // Filters out once rows attached to a different bundle
            // parent so we don't show another visit's queued items.
            let visible = rows.filter { row in
                if row.recurrence == "always" { return true }
                if row.scopeTaskId == nil { return true }
                return row.scopeTaskId == task.id
            }
            await MainActor.run {
                self.customSubitems = visible
            }
        } catch {
            print("[MaintenanceTaskDetailSheet] loadCustomSubitems failed: \(error)")
        }
    }

    /// Soft-delete a subitem from the homeowner's list. Always rows
    /// stop firing on future bundles; once rows just clear from this
    /// task's notes block on next refresh.
    private func archiveCustomSubitem(_ item: BundleCustomSubitemRow) async {
        do {
            try await db.archiveBundleCustomSubitem(id: item.id)
            Haptics.light()
            await MainActor.run {
                self.customSubitems.removeAll { $0.id == item.id }
            }
            Analytics.track(.bundleCustomSubitemArchived, [
                "bundle_id": item.bundleId,
                "recurrence": item.recurrence,
            ])
        } catch {
            print("[MaintenanceTaskDetailSheet] archiveCustomSubitem failed: \(error)")
            Haptics.error()
        }
    }

    // MARK: - Phase 54B.3 / 56.4: Add-to-handyman helpers

    /// Task detail should always let the homeowner try the handyman path
    /// unless the task is already on the handyman list or belongs to a
    /// vehicle workflow. Coverage can still be recommended, but it should
    /// never block the "ask my handyman first" path.
    private var showAddToHandymanButton: Bool {
        guard task.vehicleId == nil else { return false }
        return !isOnHandymanList
    }

    private var activeRoute: String? {
        currentRoute ?? task.assignedRoute
    }

    private var isOnHandymanList: Bool {
        activeRoute?.lowercased() == "handyman"
    }

    private var prefersVendorCoverage: Bool {
        MaintenanceTaskRoutingSupport.prefersVendorCoverage(task)
    }

    /// Phase 56.4: Entry point for the handyman add flow. Vendor-assigned
    /// tasks route through a confirmation dialog so the user can
    /// choose whether THIS instance or the WHOLE series moves. DIY
    /// tasks skip the dialog and add directly.
    private func handleAddToHandymanList() {
        if assignedContractor != nil {
            showHandymanReassignConfirm = true
        } else {
            Task { await addToPunchListJustThisTime() }
        }
    }

    /// Phase 78: stronger commitment than "Add to handyman list".
    /// Atomically:
    ///   1. inserts a `handyman_punch_items` row delegated to the next
    ///      upcoming handyman visit (or wishlist if none exists),
    ///   2. stamps `delegated_to_punch_item_id` on this task so it
    ///      stops appearing in primary task lists.
    /// The visit card now represents this work; the source task lives
    /// on for service-history purposes but isn't user-facing anymore.
    private func handleDelegateToHandyman() async {
        guard !isDelegatingToHandyman else { return }
        await MainActor.run { isDelegatingToHandyman = true }
        defer { Task { await MainActor.run { isDelegatingToHandyman = false } } }
        do {
            _ = try await HavenSupabase.delegateTaskToPunchList(taskId: task.id.uuidString)
            Analytics.track(.handymanPunchItemAdded, [
                "source": "delegate_to_handyman",
                "task_id": task.id.uuidString,
                "entry_point": "task_detail_sheet",
            ])
            Haptics.success()
            // Refresh the schedule + handyman tab so the visit card
            // picks up the new item and the source task disappears.
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            await MainActor.run { dismiss() }
        } catch {
            print("[MaintenanceTaskDetailSheet] handleDelegateToHandyman failed: \(error)")
            Haptics.error()
        }
    }

    /// Phase 56.4: Handyman add — this instance only. Creates the punch
    /// item, marks the current instance complete (so it stops surfacing
    /// for the original vendor), and leaves the recurring series
    /// assigned to the vendor for future instances.
    private func addToPunchListJustThisTime() async {
        guard !isAddingToPunchList else { return }
        isAddingToPunchList = true
        defer { isAddingToPunchList = false }

        // Phase 56.6: Guard against double-add. If a pending punch item
        // already exists for this source task (user tapped the card's
        // inline quick-add, then opened the detail sheet and tapped
        // again), surface the toast and exit rather than inserting a
        // duplicate. Matches the `HandymanPunchListView` load-time
        // dedup by sourceTaskId.
        let existing = (try? await db.fetchPendingHandymanPunchItems(householdId: task.householdId)) ?? []
        if existing.contains(where: { $0.sourceTaskId == task.id }) {
            Haptics.light()
            await MainActor.run { currentRoute = "handyman" }
            withAnimation { showAddedToPunchListToast = true }
            Task {
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    withAnimation { showAddedToPunchListToast = false }
                }
            }
            return
        }

        let insert = buildPunchItemInsert()
        do {
            _ = try await db.createHandymanPunchItem(insert)
            // Phase 67E/F: handyman work lives on a single rail —
            // `handyman_punch_items`. The source task is archived with
            // reason "moved_to_handyman_punch" so it stops appearing
            // on the maintenance rail. Replaces the prior dual-rail
            // approach (parent_routine_id + the task still alive on
            // maintenance_tasks) which made completion semantics
            // confusing.
            try? await db.archiveMaintenanceTask(id: task.id, reason: "moved_to_handyman_punch")
            await MainActor.run { currentRoute = "handyman" }
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "routed", "id": task.id.uuidString, "route": "handyman"])
            NotificationCenter.default.post(name: .handymanPunchListChanged, object: nil)
            Analytics.track(.handymanPunchItemAdded, [
                "source": "promoted_from_task",
                "task_id": task.id.uuidString,
                "vendor_was_assigned": assignedContractor != nil,
                "intent": "just_this_time",
            ])
            Haptics.success()
            withAnimation { showAddedToPunchListToast = true }
            Task {
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    withAnimation { showAddedToPunchListToast = false }
                }
            }
        } catch {
            print("[MaintenanceTaskDetailSheet] addToPunchListJustThisTime failed: \(error)")
            Haptics.error()
        }
    }

    /// Phase 56.4: Handyman add — reassign the whole series. Strips the
    /// vendor from the task, flips `assignmentType` to "either", creates
    /// the punch item, and completes this instance. Future instances
    /// won't auto-assign back to the vendor.
    ///
    /// Bug fix: the contractor clear has to go through
    /// `clearMaintenanceTaskContractor` rather than a
    /// `MaintenanceTaskUpdate` with `assignedContractorId = nil`.
    /// Swift's Codable encodes optional fields with `encodeIfPresent`,
    /// so a `nil` on an Optional field gets dropped from the PATCH
    /// body entirely — Supabase treats the missing column as "don't
    /// touch" and the vendor stays linked. The dedicated helper writes
    /// an explicit `{"assigned_contractor_id": null}` which actually
    /// clears the column.
    private func addToPunchListReassignSeries() async {
        guard !isAddingToPunchList else { return }
        isAddingToPunchList = true
        defer { isAddingToPunchList = false }

        do {
            // 1. Clear the contractor explicitly (the Optional.nil
            // trick doesn't survive Codable's encodeIfPresent).
            try await db.clearMaintenanceTaskContractor(id: task.id)

            // 2. Flip the assignment type so future instances don't
            // auto-assign back to the vendor.
            var update = MaintenanceTaskUpdate()
            update.assignmentType = "either"
            _ = try await db.updateMaintenanceTask(id: task.id, update)

            // 3. Create the punch item.
            // Phase 56.6: skip the insert when one already exists for
            // this source task. The user explicitly chose "from now
            // on" so we still run step 4 (archive) regardless.
            let existing = (try? await db.fetchPendingHandymanPunchItems(householdId: task.householdId)) ?? []
            if !existing.contains(where: { $0.sourceTaskId == task.id }) {
                let insert = buildPunchItemInsert()
                _ = try await db.createHandymanPunchItem(insert)
            }

            // 4. Phase 67E/F: archive the source task so the whole
            // recurring series moves off the maintenance rail. Reason
            // "moved_to_handyman_punch" mirrors the just-this-time
            // path. (Previously we completed the task here, but
            // completion advanced the recurrence schedule and the next
            // instance kept reappearing — exactly the dual-rail
            // behavior Phase 67E/F is unwinding.)
            try? await db.archiveMaintenanceTask(id: task.id, reason: "moved_to_handyman_punch")

            // 5. Reflect the change in local UI state so the vendor
            // section disappears immediately instead of waiting for
            // the next sheet presentation.
            await MainActor.run {
                assignedContractor = nil
                currentRoute = "handyman"
            }

            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "routed", "id": task.id.uuidString, "route": "handyman"])
            NotificationCenter.default.post(name: .handymanPunchListChanged, object: nil)

            Analytics.track(.handymanPunchItemAdded, [
                "source": "promoted_from_task",
                "task_id": task.id.uuidString,
                "vendor_was_assigned": true,
                "intent": "reassign_series",
            ])
            Haptics.success()
            withAnimation { showAddedToPunchListToast = true }
            Task {
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    withAnimation { showAddedToPunchListToast = false }
                    dismiss()
                }
            }
        } catch {
            print("[MaintenanceTaskDetailSheet] addToPunchListReassignSeries failed: \(error)")
            Haptics.error()
        }
    }

    /// Shared builder — same insert body whether the user chose Just
    /// this time or From now on.
    private func buildPunchItemInsert() -> HandymanPunchItemInsert {
        MaintenanceTaskRoutingSupport.buildPunchItemInsert(for: task)
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
            if assignedContractor == nil, let systemId = task.systemId, let propertyId = task.propertyId {
                let systems = try await db.fetchHomeSystems(propertyId: propertyId)
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

    private func loadPropertyContext() async {
        guard let propertyId = task.propertyId else { return }
        let properties = (try? await db.fetchProperties()) ?? []
        guard let property = properties.first(where: { $0.id == propertyId }) else { return }
        propertyTown = property.city ?? ""
        propertyState = property.state ?? ""
    }

    private func loadUpcomingVisits() async {
        guard let appointmentId = task.standingAppointmentId else { return }
        let visits = (try? await db.fetchVisits(appointmentId: appointmentId, limit: 10)) ?? []
        upcomingVisits = visits.filter { $0.status == "upcoming" }.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    private func assignContractorToTask(_ contractor: ContractorRow) async {
        do {
            // Clear needsVendor flag alongside setting the contractor
            _ = try await db.updateMaintenanceTask(
                id: task.id,
                MaintenanceTaskUpdate(
                    assignedContractorId: contractor.id,
                    needsVendor: false
                )
            )
            _ = try? await db.setTaskRoute(taskId: task.id, route: "vendor", task: task)
            await MainActor.run {
                assignedContractor = contractor
                currentRoute = "vendor"
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

            // Notify dashboard and other views to refresh coverage
            NotificationCenter.default.post(name: .contractorChanged, object: nil)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
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

    private var vendorSearchCategory: String {
        if let serviceVendor = ServiceLibrary.serviceDefinition(for: task)?.vendorCategory,
           !serviceVendor.isEmpty {
            return serviceVendor
        }
        // July 2026 (audit F16): canonicalize so a sub-system key resolves to
        // a registry category for both the Places search and the eventual
        // contractor stamp. FindLocalVendorSheet also canonicalizes at stamp
        // time as a defensive layer.
        if let systemCategory, !systemCategory.isEmpty {
            return SystemCategoryRegistry.canonical(category: systemCategory) ?? systemCategory
        }
        if let resolvedCategory, !resolvedCategory.isEmpty {
            return SystemCategoryRegistry.canonical(category: resolvedCategory) ?? resolvedCategory
        }
        return "Handyman"
    }

    @ViewBuilder
    private var vendorSearchSheet: some View {
        if propertyTown.isEmpty || propertyState.isEmpty {
            NavigationStack {
                VStack(spacing: HavenTheme.spacing16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(HavenColors.warning)
                    Text("Add a city and state to this property before searching local pros.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                    HavenButton(title: "Choose from my contacts") {
                        showFindLocalVendor = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showManualAddFromFindVendor = true
                        }
                    }
                }
                .padding(HavenTheme.spacing24)
            }
            .presentationDetents([.medium])
        } else {
            FindLocalVendorSheet(
                task: task,
                householdId: task.householdId,
                town: propertyTown,
                state: propertyState,
                systemCategory: vendorSearchCategory,
                categoryDisplayName: vendorSearchCategory.lowercased(),
                onComplete: {
                    Task { await loadVendorInfo() }
                },
                onAdoptedVendor: { contractor in
                    Task { await assignContractorToTask(contractor) }
                }
            )
        }
    }

    /// Phase 56.4: Load existing scheduled reminders into the unified
    /// `activeReminders` set. If nothing is scheduled yet, seed with the
    /// smart default for the task's frequency so the summary row
    /// renders "Reminding you 1 week before" instead of "No reminders
    /// set" on first open.
    private func loadExistingReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let taskPrefix = "task-reminder-\(task.id.uuidString)-"
        let ids = Set(pending.filter { $0.identifier.hasPrefix(taskPrefix) }.map(\.identifier))

        var timings: Set<ReminderTiming> = []
        for timing in ReminderTiming.allCases {
            if ids.contains("\(taskPrefix)\(timing.daysBefore)d") {
                timings.insert(timing)
            }
        }
        // Phase 56.4: If the user has no scheduled reminders yet, seed
        // the smart default and schedule it so the list arrives
        // non-empty. Respects existing user selections — we only seed
        // when the set is truly empty.
        if timings.isEmpty, let smart = defaultReminderForFrequency {
            timings.insert(smart)
            setReminder(timing: smart, isEnabled: true)
        }
        await MainActor.run {
            activeReminders = timings
            remindersLoaded = true
        }
    }

    /// Phase 56.4: Reminder timing default based on the task's
    /// frequency. Annual/semi-annual → 1 week. Monthly/quarterly →
    /// 3 days. Weekly/biweekly → 1 day. Falls back to 3 days for any
    /// frequency we can't parse.
    private var defaultReminderForFrequency: ReminderTiming? {
        let freq = task.frequency.lowercased()
        if freq.contains("annual") || freq.contains("yearly")
            || freq.contains("semi") || freq.contains("twice") {
            return .oneWeek
        }
        if freq.contains("monthly") || freq.contains("quarterly") {
            return .threeDays
        }
        if freq.contains("weekly") {
            return .oneDay
        }
        return .threeDays
    }

    /// Phase 56.4: Schedule or cancel a single reminder. Replaces the
    /// raw-int `toggleReminder(daysBefore:isEnabled:)` — callers pass
    /// the strongly-typed `ReminderTiming`.
    private func setReminder(timing: ReminderTiming, isEnabled: Bool) {
        guard let dueDate = dateFormatter.date(from: task.nextDueDate) else { return }
        Analytics.track(.maintenanceTaskReminderSet, [
            "task_id": task.id.uuidString,
            "days_before": timing.daysBefore,
            "enabled": isEnabled,
        ])

        let center = UNUserNotificationCenter.current()
        let notificationId = "task-reminder-\(task.id.uuidString)-\(timing.daysBefore)d"

        if isEnabled {
            guard let alertDate = Calendar.current.date(byAdding: .day, value: -timing.daysBefore, to: dueDate),
                  alertDate > .now else { return }

            let content = UNMutableNotificationContent()
            content.title = "Maintenance Reminder"
            content.body = "\(task.title) is due in \(timing.daysBefore) day\(timing.daysBefore == 1 ? "" : "s")."
            content.sound = .default
            // Round 5 routing audit: stamp task_id so the tap routes
            // through `.openTask` to this specific task's detail sheet
            // instead of falling through to the default Tasks tab.
            content.userInfo = [
                "type": "task_reminder",
                "task_id": task.id.uuidString,
            ]

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
            center.add(request)
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
    }

    // MARK: - Header

    /// Phase 56.3+: inline-editable title. Tap the text → turns into a
    /// TextField in the same spot; Return or outside-tap commits. No
    /// modal sheet, no edit-mode toggle button — matches the rest of
    /// the app's direct-manipulation feel.
    @ViewBuilder
    private var editableTitle: some View {
        if isEditingTitle {
            TextField("Task title", text: $editedTitle, axis: .vertical)
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)
                .lineLimit(1...3)
                .focused($titleFieldFocused)
                .submitLabel(.done)
                .onSubmit { commitTitleEdit() }
                .onChange(of: titleFieldFocused) { _, focused in
                    if !focused { commitTitleEdit() }
                }
        } else {
            Button {
                editedTitle = task.title
                isEditingTitle = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    titleFieldFocused = true
                }
            } label: {
                HStack(alignment: .top, spacing: 6) {
                    Text(task.title)
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                        .padding(.top, 6)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func commitTitleEdit() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        isEditingTitle = false
        titleFieldFocused = false
        guard !trimmed.isEmpty, trimmed != task.title else { return }
        Task {
            do {
                _ = try await DatabaseService.shared.updateMaintenanceTask(
                    id: task.id,
                    MaintenanceTaskUpdate(title: trimmed)
                )
                Haptics.success()
                NotificationCenter.default.post(
                    name: .maintenanceTaskChanged,
                    object: nil,
                    userInfo: ["action": "title_updated", "id": task.id.uuidString]
                )
            } catch {
                Haptics.error()
            }
        }
    }

    /// Phase 56.4: Single contextual date line. Scheduled takes precedence
    /// (that's the actual next event); otherwise the next-due date is
    /// what surfaces. Uses relative time so "in 15 days" or "3 days
    /// overdue" reads naturally. Pencil affordance for inline editing.
    @ViewBuilder
    private var nextActionLine: some View {
        let displayFormatter = DateFormatter()
        let _ = (displayFormatter.dateStyle = .long)

        Button {
            if let date = dateFormatter.date(from: task.nextDueDate) {
                editedDueDate = date
            }
            showEditDueDate = true
        } label: {
            HStack {
                if let scheduled = task.scheduledDate,
                   let date = dateFormatter.date(from: scheduled) {
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
                    let relative = relativeTimeLabel(days: days, overdue: false)
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.success)
                    Text("Next visit:")
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                    Text(displayFormatter.string(from: date))
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("(\(relative))")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundStyle(HavenColors.navy700)
                } else if let date = dateFormatter.date(from: task.nextDueDate) {
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
                    let isOverdue = days < 0
                    let relative = relativeTimeLabel(days: days, overdue: isOverdue)
                    Image(systemName: isOverdue ? "exclamationmark.circle" : "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.textSecondary)
                    Text("Due:")
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                    Text(displayFormatter.string(from: date))
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("(\(relative))")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.textTertiary)
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundStyle(HavenColors.navy700)
                } else {
                    Text("Due:")
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                    Text(task.nextDueDate.havenDateFormatted)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Phase 56.4: Relative-time label matching the rest of Haven's
    /// voice — "today", "tomorrow", "in 15 days", or "3 days overdue".
    private func relativeTimeLabel(days: Int, overdue: Bool) -> String {
        if overdue {
            return "\(abs(days)) days overdue"
        }
        if days == 0 { return "today" }
        if days == 1 { return "tomorrow" }
        return "in \(days) days"
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            editableTitle

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
                // Phase 56.4: Single contextual date line replaces the
                // old "Next Due" + "Scheduled" dual rows. When both
                // dates existed and disagreed (scheduled April 30 /
                // next due May 11), users read the cards as "am I
                // overdue?" This collapses to one line: the scheduled
                // date when a visit is booked, otherwise the next-due
                // date.
                nextActionLine

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

                if let desc = visibleDescription {
                    Divider().overlay(HavenColors.beige200)
                    Text(desc)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if !bundledChecklistItems.isEmpty {
                    Divider().overlay(HavenColors.beige200)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WHAT'S INCLUDED")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        ForEach(Array(bundledChecklistItems.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("-")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(item)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                // Phase 67H: Custom additions section. Only renders for
                // bundle parents (signal: bundledChecklistItems.isEmpty
                // == false AND task.templateId is set to a bundleId).
                // Lists the homeowner's existing always/once subitems
                // and surfaces an "Add to this visit" button so they
                // can extend the bundle without leaving the detail sheet.
                if isBundleParent {
                    Divider().overlay(HavenColors.beige200)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CUSTOM ADDITIONS")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        if customSubitems.isEmpty {
                            Text("Add anything you've been meaning to flag for this visit.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            ForEach(customSubitems, id: \.id) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("-")
                                        .font(HavenTypography.bodySmall)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(HavenTypography.bodySmall)
                                            .foregroundStyle(HavenColors.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        if item.recurrence == "always" {
                                            Text("Every visit")
                                                .font(HavenTypography.uiLabelSmall)
                                                .foregroundStyle(HavenColors.textTertiary)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                    Button {
                                        Task { await archiveCustomSubitem(item) }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(HavenColors.textTertiary)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Remove \(item.title)")
                                }
                            }
                        }

                        Button {
                            Haptics.light()
                            showAddSubitemSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                Text("Add to this visit")
                                    .font(HavenTypography.uiLabel)
                            }
                            .foregroundStyle(HavenColors.action)
                        }
                        .padding(.top, 4)
                    }
                }

                if let notes = visibleNotes {
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
                        .foregroundStyle(HavenColors.textSecondary)
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
                    .foregroundStyle(HavenColors.textPrimary)
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

                Text("Chez will recalculate the next due date based on the task frequency (\(task.frequency)).")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .multilineTextAlignment(.center)

                // Build 86: no date-range constraint. Users can log a task
                // as completed on ANY date (past or future) — they might be
                // backdating a gutter cleaning from months ago, or recording
                // a pro visit that's already on the calendar next week.
                DatePicker("Date Completed", selection: $lastServicedDate, displayedComponents: .date)
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
                        .foregroundStyle(HavenColors.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveLastServiced() }
                    }
                    .foregroundStyle(HavenColors.textPrimary)
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

            // Also update the parent system's dates if applicable.
            // No `try?`: a silently failed system update leaves
            // last_service_date stale, which skews every future
            // due-date computed off the system override.
            if let systemId = task.systemId {
                _ = try await DatabaseService.shared.updateHomeSystem(
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
                                    .foregroundStyle(HavenColors.textPrimary)
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
                        .foregroundStyle(HavenColors.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveFrequency() }
                    }
                    .foregroundStyle(HavenColors.textPrimary)
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

    // MARK: - Routing Picker (Phase 64 + 65)

    /// Resolve the picker mode from the task's template + active contract.
    /// Uses `TaskRoutingMode.derive(...)` from TaskRoutingPicker.swift.
    private var routingPickerMode: TaskRoutingMode {
        // Active service contract → readOnly. We treat a linked contractor on
        // the task as the proxy for "contract active" since ServiceContractRow
        // has no is_active column.
        if assignedContractor != nil && task.assignmentType?.lowercased() == "vendor" {
            return .readOnly
        }
        let template = task.templateId.flatMap { MaintenanceTemplates.template(forKey: $0) }
        return TaskRoutingMode.derive(
            templateRouting: template?.routing,
            safetyFloor: template?.safetyFloor ?? false,
            hasActiveContract: false
        )
    }

    @ViewBuilder
    private var routingPickerSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                TaskRoutingPicker(
                    mode: routingPickerMode,
                    currentRoute: currentRoute.flatMap { TaskAssignedRoute(rawValue: $0) },
                    safetyFloor: task.templateId
                        .flatMap { MaintenanceTemplates.template(forKey: $0) }?
                        .safetyFloor ?? false,
                    assignedVendorName: assignedContractor?.companyName,
                    preferredHandymanName: preferredHandyman?.contactName ?? preferredHandyman?.companyName,
                    onSelectVendor: { Task { await selectRoute("vendor") } },
                    onSelectHandyman: { Task { await selectRoute("handyman") } },
                    onSelectDIY: { Task { await selectRoute("diy") } }
                )

                if showRoutingRememberedToast, let cat = rememberedToastCategory {
                    HStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(HavenColors.navy700)
                        Text("We'll remember this for future \(cat) tasks.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                    }
                    .padding(HavenTheme.spacing8)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                    .transition(.opacity)
                }
            }
        }
        .task(id: task.id) {
            await loadRoutingContext()
        }
    }

    /// Loads the household's preferred handyman once so the picker can
    /// render "Add to [Name]'s next visit" without an extra fetch per tap.
    private func loadRoutingContext() async {
        currentRoute = task.assignedRoute
        guard preferredHandyman == nil else { return }
        if let household = try? await DatabaseService.shared.fetchHousehold(id: task.householdId),
           let handymanId = household.preferredHandymanContractorId {
            let contractors = (try? await DatabaseService.shared.fetchContractors()) ?? []
            preferredHandyman = contractors.first { $0.id == handymanId }
        }
    }

    /// Phase 64 + 65 write path:
    /// 1. Persist `assigned_route` via `setTaskRoute` (handles punch-list sync).
    /// 2. Stamp / upsert a category-level `routing_preferences` row on first
    ///    pick per category; stamp a template-level override when the user
    ///    deviates from an existing category preference.
    /// 3. Show the "we'll remember this" toast on first-pick.
    private func selectRoute(_ route: String) async {
        let previous = currentRoute
        currentRoute = route
        Haptics.light()

        let category = resolvedCategory ?? "Other"
        Analytics.track(.taskRouteChanged, [
            "task_id": task.id.uuidString,
            "from": previous ?? "unset",
            "to": route,
            "category": category,
            "picker_mode": String(describing: routingPickerMode)
        ])

        do {
            _ = try await DatabaseService.shared.setTaskRoute(
                taskId: task.id,
                route: route,
                task: task
            )
        } catch {
            Haptics.error()
            currentRoute = previous
            return
        }

        await persistRoutingPreference(route: route, category: category)
        Haptics.success()
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
    }

    /// Category for the current task — resolves via the system if present,
    /// otherwise from the template key prefix ("HVAC:Replace air filters" →
    /// "HVAC"). Falls back to "Other" upstream.
    private var resolvedCategory: String? {
        if let category = systemCategory { return category }
        if let key = task.templateId, let colon = key.firstIndex(of: ":") {
            return String(key[..<colon])
        }
        return nil
    }

    private func persistRoutingPreference(route: String, category: String) async {
        guard let propertyId = task.propertyId else { return }
        let householdId = task.householdId
        let existing = (try? await DatabaseService.shared.fetchRoutingPreferences(
            householdId: householdId,
            propertyId: propertyId
        )) ?? []

        if let templateId = task.templateId,
           let categoryPref = existing.first(where: {
               $0.scopeType == "category" && $0.taskCategory == category
           }),
           categoryPref.preferredRoute != route {
            // Deviating from the category preference → template-level override.
            let insert = RoutingPreferenceInsert(
                householdId: householdId,
                propertyId: propertyId,
                taskCategory: templateId,
                scopeType: "template",
                preferredRoute: route,
                preferredVendorId: route == "vendor" ? assignedContractor?.id : nil
            )
            do {
                _ = try await DatabaseService.shared.upsertRoutingPreference(insert)
                Analytics.track(.routingPreferenceUpdated, [
                    "category": category,
                    "from_route": categoryPref.preferredRoute,
                    "to_route": route
                ])
            } catch {
                // The route itself already applied (setTaskRoute succeeded
                // upstream) — only the remembered override was lost.
                print("[MaintenanceTaskDetailSheet] template routing preference upsert failed: \(error)")
                Haptics.error()
            }
            return
        }

        if existing.first(where: {
            $0.scopeType == "category" && $0.taskCategory == category
        }) == nil {
            // First pick in this category → create category preference + toast.
            let insert = RoutingPreferenceInsert(
                householdId: householdId,
                propertyId: propertyId,
                taskCategory: category,
                scopeType: "category",
                preferredRoute: route,
                preferredVendorId: route == "vendor" ? assignedContractor?.id : nil
            )
            do {
                _ = try await DatabaseService.shared.upsertRoutingPreference(insert)
            } catch {
                // Don't show "we'll remember this" for a preference that
                // never persisted — the old `try?` version toasted anyway.
                print("[MaintenanceTaskDetailSheet] category routing preference upsert failed: \(error)")
                Haptics.error()
                return
            }
            Analytics.track(.routingPreferenceSet, [
                "category": category,
                "route": route,
                "scope": "category"
            ])
            await MainActor.run {
                rememberedToastCategory = category
                withAnimation { showRoutingRememberedToast = true }
            }
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run {
                withAnimation { showRoutingRememberedToast = false }
            }
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

                if isOnHandymanList {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        HStack(spacing: 8) {
                            Image(systemName: "hammer.fill")
                                .foregroundStyle(HavenColors.navy600)
                            Text("On the contractor list")
                                .font(HavenTypography.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(HavenColors.textPrimary)

                            if prefersVendorCoverage {
                                Text("Coverage recommended")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.warning)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(HavenColors.warning.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }

                        Text(
                            prefersVendorCoverage
                            ? "Your contractor can review this first. Add service coverage if you want Chez to schedule it automatically in the future."
                            : "We’ll keep this with your contractor bundle so it still gets serviced without getting lost inside the system record."
                        )
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)

                        HStack(spacing: HavenTheme.spacing12) {
                            Button {
                                Haptics.light()
                                showHandymanPunchList = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "hammer.fill")
                                    Text("View contractor list")
                                }
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                            }
                            .buttonStyle(.plain)

                            if prefersVendorCoverage {
                                Button {
                                    Haptics.light()
                                    showContractorDirectory = true
                                } label: {
                                    Text("Set service coverage")
                                        .font(HavenTypography.uiLabelSmall)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else if let contractor = assignedContractor {
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

                    // Phase 19l: bidirectional toggle. Lets the user reclaim
                    // a vendor-managed task back to their personal list. Only
                    // surfaces when the row is actually vendor-managed (i.e.
                    // `assignmentType == "vendor"`); the existing "Remove
                    // Vendor" button above just unlinks the contractor without
                    // changing the assignment.
                    if (task.assignmentType?.lowercased() == "vendor") {
                        Button {
                            Haptics.light()
                            showConvertToPersonalConfirm = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 11))
                                Text("I'll do this myself")
                                    .font(HavenTypography.uiLabel)
                            }
                            .foregroundStyle(HavenColors.navy700)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, HavenTheme.spacing8)
                        }
                        .buttonStyle(.plain)
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

                        Text("Add a vendor for this \(categoryLabel) and Chez can automatically schedule your maintenance tasks.")
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
                            .foregroundStyle(HavenColors.textPrimary)
                        }
                        .padding(.top, 4)

                        if showAddToHandymanButton {
                            Button {
                                Haptics.light()
                                handleAddToHandymanList()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "hammer.fill")
                                    Text("Or batch this with your contractor")
                                }
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy700)
                            }
                            .buttonStyle(.plain)

                            Text("Good for smaller tune-ups, lubrication, batteries, touch-ups, and other quick upkeep items.")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }

                        // Phase 80 — Chez Concierge entry. The user is on
                        // a vendorless task and doesn't want to add their
                        // own contractor or batch into the handyman list;
                        // tapping this hands off the whole coordination
                        // job to Tom (find a pro, schedule, follow up).
                        ChezEntryButton(
                            category: .coordinateTask,
                            label: "Have Chez handle this for me",
                            caption: "Chez finds the pro, schedules, and follows up.",
                            context: chezTaskContext
                        )
                        .padding(.top, HavenTheme.spacing8)
                    }
                }
            }
        }
    }

    /// Phase 80 — context dict handed to the Chez composer when delegating
    /// a maintenance task. Includes everything Tom needs to triage without
    /// asking follow-ups.
    private var chezTaskContext: [String: String] {
        var c: [String: String] = [
            "task_id": task.id.uuidString,
            "task_title": task.title,
            "source_entity_type": "task",
            "source_entity_label": task.title,
        ]
        if let cat = systemCategory, !cat.isEmpty {
            c["system_category"] = cat
        }
        if let sysId = task.systemId?.uuidString { c["system_id"] = sysId }
        if let propId = task.propertyId?.uuidString { c["property_id"] = propId }
        // Both scheduled and next-due dates are stored as ISO strings;
        // pass through the first non-empty one as a plain text date.
        if let scheduled = task.scheduledDate, !scheduled.isEmpty {
            c["due"] = scheduled
        } else if !task.nextDueDate.isEmpty {
            c["due"] = task.nextDueDate
        }
        if let notes = task.notes, !notes.isEmpty {
            // Wave 4: no truncation. The old 400-char cap silently
            // dropped bundle checklists and vendor follow-up context;
            // the preview_snapshot pipeline carries full truth now and
            // the composer's "Re:" card renders an allowlisted subset,
            // so the full notes ride along for Chez's triage.
            c["notes"] = notes
        }
        return c
    }

    // MARK: - Phase 51B: Schedule Visit (inline on detail sheet)

    /// Shows when vendor is assigned but no scheduledDate or standingAppointment.
    /// This is the "on the phone with vendor" workflow.
    @ViewBuilder
    private var scheduleVisitSection: some View {
        let isVendor = task.assignmentType?.lowercased() == "vendor"
        let hasContractor = task.assignedContractorId != nil
        let notScheduled = task.scheduledDate == nil && task.standingAppointmentId == nil

        if isVendor && hasContractor && notScheduled {
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    // Header with expand toggle
                    Button {
                        withAnimation(HavenTheme.animationStandard) {
                            showScheduleVisit.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(HavenColors.navy700)
                            Text("Schedule Visit")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                            Image(systemName: showScheduleVisit ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    if showScheduleVisit {
                        Divider().foregroundStyle(HavenColors.beige200)

                        // Date picker
                        DatePicker("Date", selection: $scheduleDate, displayedComponents: .date)
                            .font(HavenTypography.body)
                            .tint(HavenColors.navy800)

                        // Time slot
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TIME")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                            Picker("Time", selection: $scheduleTimeSlot) {
                                ForEach(ScheduleTimeSlot.allCases, id: \.self) { slot in
                                    Text(slot.label).tag(slot)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Make recurring toggle
                        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                            Toggle(isOn: $makeRecurring) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Make this recurring")
                                        .font(HavenTypography.headline)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Text("Set up a regular schedule with this vendor")
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                            }
                            .tint(HavenColors.navy800)

                            if makeRecurring {
                                Picker("Frequency", selection: $recurringCadence) {
                                    Text("Weekly").tag("weekly")
                                    Text("Every 2 weeks").tag("biweekly")
                                    Text("Monthly").tag("monthly")
                                    Text("Quarterly").tag("quarterly")
                                    Text("Semi-annually").tag("semiannual")
                                    Text("Annually").tag("annual")
                                }
                                .pickerStyle(.menu)
                                .tint(HavenColors.navy800)
                            }
                        }

                        // Confirm button
                        Button {
                            confirmScheduledVisit()
                        } label: {
                            HStack {
                                if isScheduling {
                                    ProgressView().controlSize(.small).tint(.white)
                                }
                                Text("Confirm Visit")
                                    .font(HavenTypography.uiButton)
                            }
                            .foregroundStyle(HavenColors.textOnNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(HavenColors.navy800)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                        }
                        .buttonStyle(.plain)
                        .disabled(isScheduling)
                    }
                }
            }
        }
    }

    private func confirmScheduledVisit() {
        isScheduling = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: scheduleDate)

        Task {
            do {
                // 1. Set scheduledDate on the task → moves to the "Scheduled" bucket
                _ = try await db.updateMaintenanceTask(
                    id: task.id,
                    MaintenanceTaskUpdate(scheduledDate: dateStr)
                )

                // 2. If recurring, create a standing appointment
                if makeRecurring, let systemId = task.systemId {
                    let user = try await db.fetchCurrentUser()
                    if let householdId = user.householdId {
                        _ = try await StandingAppointmentViewModel.shared.createAppointment(
                            householdId: householdId,
                            propertyId: task.propertyId,
                            vendorId: task.assignedContractorId,
                            systemId: systemId,
                            cadenceType: recurringCadence,
                            cadenceIntervalDays: nil,
                            cadenceSource: "user_set",
                            serviceDescription: "\(assignedContractor?.companyName ?? "Vendor") \(recurringCadence) \(systemCategory ?? "service")",
                            startDate: dateStr
                        )

                        // Link the task to the standing appointment
                        let appointments = try await db.fetchStandingAppointments(householdId: householdId)
                        if let appt = appointments.first(where: { $0.systemId == systemId && $0.archivedAt == nil }) {
                            _ = try await db.updateMaintenanceTask(
                                id: task.id,
                                MaintenanceTaskUpdate(standingAppointmentId: appt.id)
                            )
                        }
                    }
                }

                await MainActor.run {
                    isScheduling = false
                    Haptics.success()
                    NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                    NotificationCenter.default.post(name: .standingAppointmentChanged, object: nil)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isScheduling = false
                    Haptics.error()
                }
            }
        }
    }

    // MARK: - Phase 51B: Recurring Service Section

    @ViewBuilder
    private var recurringServiceSection: some View {
        if task.standingAppointmentId != nil {
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    Text("RECURRING SERVICE")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)

                    // Cadence + status
                    if let appt = linkedAppointment {
                        HStack(spacing: HavenTheme.spacing8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(HavenColors.navy700)
                            Text(appt.cadenceLabel)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                            if appt.isPaused {
                                Text("Paused")
                                    .font(HavenTypography.badgeLabel)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(HavenColors.warning.opacity(0.12))
                                    .foregroundStyle(HavenColors.warning)
                                    .clipShape(Capsule())
                            }
                        }

                        // Next 4 upcoming visits
                        if !upcomingVisits.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("UPCOMING VISITS")
                                    .font(HavenTypography.uiSectionHeader)
                                    .tracking(1.5)
                                    .foregroundStyle(HavenColors.textTertiary)
                                    .padding(.top, 4)

                                ForEach(upcomingVisits, id: \.id) { visit in
                                    HStack(spacing: HavenTheme.spacing8) {
                                        Circle()
                                            .fill(visitStatusColor(visit.status))
                                            .frame(width: 6, height: 6)
                                        Text(visit.scheduledDate.havenDateCompact)
                                            .font(HavenTypography.bodySmall)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Text(visit.status.capitalized)
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                        Spacer()
                                    }
                                }
                            }
                        }

                        // Last confirmed
                        if let lastDate = appt.lastConfirmedDate {
                            HStack(spacing: HavenTheme.spacing8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(HavenColors.success)
                                Text("Last confirmed: \(lastDate.havenDateCompact)")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .padding(.top, 4)
                        }

                        Divider().foregroundStyle(HavenColors.beige200)

                        // Actions
                        if appt.isPaused {
                            Button {
                                Task { try? await StandingAppointmentViewModel.shared.resumeAppointment(id: appt.id) }
                                Haptics.medium()
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Resume Service")
                                }
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                appointmentToPauseFromDetail = appt
                                showPauseFromDetail = true
                            } label: {
                                HStack {
                                    Image(systemName: "pause.circle")
                                    Text("Pause Service")
                                }
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            Task {
                                try? await StandingAppointmentViewModel.shared.archiveAppointment(id: appt.id)
                                Haptics.medium()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("End Service")
                            }
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.critical)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var linkedAppointment: StandingAppointmentRow? {
        guard let id = task.standingAppointmentId else { return nil }
        return StandingAppointmentViewModel.shared.appointments.first { $0.id == id }
    }

    @State private var upcomingVisits: [StandingAppointmentVisitRow] = []
    @State private var appointmentToPauseFromDetail: StandingAppointmentRow?
    @State private var showPauseFromDetail = false

    private func visitStatusColor(_ status: String) -> Color {
        switch status {
        case "confirmed": return HavenColors.success
        case "upcoming": return HavenColors.navy800
        case "skipped": return HavenColors.textTertiary
        case "assumed": return HavenColors.warning
        default: return HavenColors.textTertiary
        }
    }

    // MARK: - Reminders

    /// Phase 56.4: Smart reminder defaults. Collapsed summary row shows
    /// the active reminder(s); "Adjust" expands into the full 5-toggle
    /// grid. Replaces the pre-56.4 always-visible toggle block which
    /// made the user choose between 5 options with zero guidance.
    private var remindersSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Text("REMINDERS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                if remindersExpanded {
                    expandedRemindersBody
                } else {
                    collapsedRemindersRow
                }
            }
        }
    }

    /// Summary row: either "Reminding you X before" (when at least one
    /// is set) or "No reminders set" with an Add affordance.
    @ViewBuilder
    private var collapsedRemindersRow: some View {
        let earliest = activeReminders.sorted { $0.sortOrder < $1.sortOrder }.first
        if let primary = earliest {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(HavenColors.navy700)
                Text("Reminding you \(primary.rawValue.lowercased())")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                if activeReminders.count > 1 {
                    Text("+\(activeReminders.count - 1)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                Spacer()
                Button("Adjust") {
                    Haptics.light()
                    withAnimation(HavenTheme.animationStandard) {
                        remindersExpanded = true
                    }
                }
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.navy700)
            }
        } else {
            HStack {
                Image(systemName: "bell.slash")
                    .font(.system(size: 14))
                    .foregroundStyle(HavenColors.textTertiary)
                Text("No reminders set")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Button("Add") {
                    Haptics.light()
                    withAnimation(HavenTheme.animationStandard) {
                        remindersExpanded = true
                    }
                }
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.navy700)
            }
        }
    }

    /// Expanded 5-toggle grid. Same reminders the pre-56.4 UI exposed
    /// but hidden by default behind the summary row.
    @ViewBuilder
    private var expandedRemindersBody: some View {
        ForEach(ReminderTiming.allCases, id: \.self) { timing in
            Toggle(timing.rawValue, isOn: Binding(
                get: { activeReminders.contains(timing) },
                set: { isOn in
                    if isOn {
                        activeReminders.insert(timing)
                    } else {
                        activeReminders.remove(timing)
                    }
                    setReminder(timing: timing, isEnabled: isOn)
                }
            ))
            .font(HavenTypography.bodySmall)
            .tint(HavenColors.navy800)
        }

        Button("Done adjusting") {
            Haptics.light()
            withAnimation(HavenTheme.animationStandard) {
                remindersExpanded = false
            }
        }
        .font(HavenTypography.uiCaption)
        .foregroundStyle(HavenColors.navy700)
        .padding(.top, 4)
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

                            // Build 87 (Home Manager expansion): name +
                            // optional role suffix so the homeowner can see
                            // they're assigning to a home manager / staff
                            // before tapping. The suffix is rendered as a
                            // separate Text in textTertiary so it reads as
                            // metadata, not name.
                            HStack(spacing: 0) {
                                Text(user.fullName?.components(separatedBy: " ").first ?? user.fullName ?? "Member")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                if let suffix = roleSuffix(for: user) {
                                    Text(suffix)
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                            }

                            Spacer()

                            if assignedUserId == user.id {
                                Text("Assigned")
                                    .font(HavenTypography.badgeLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
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
        // Augmented load: includes linked family members whose users
        // row has a stale household_id, so the wife sees Tom even if
        // his auth-side household linkage is mismatched. The role-suffix
        // arrays (family + staff) still load separately because we
        // need them for the home-manager label rendering.
        householdUsers = (try? await db.fetchHouseholdUsersAugmented()) ?? []
        let family = (try? await db.fetchFamilyMembers()) ?? []
        let staff = (try? await db.fetchHouseholdStaff()) ?? []
        householdFamilyMembersForRoles = family + staff
        assignedUserId = task.assignedToUserId
        originalAssignedUserId = task.assignedToUserId
    }

    /// Build 87 (Home Manager expansion): returns " · Home Manager" or
    /// " · Staff" when the user matches a family_member with that
    /// member_type. Returns nil for plain family members so the picker
    /// keeps the existing single-name layout for them.
    private func roleSuffix(for user: UserRow) -> String? {
        guard let match = householdFamilyMembersForRoles.first(where: { $0.linkedUserId == user.id }) else {
            return nil
        }
        switch match.memberType {
        case "home_manager": return " · Home Manager"
        case "staff": return " · Staff"
        default: return nil
        }
    }

    private func updateAssignment(userId: UUID?, previousUserId: UUID?) async {
        do {
            // If this is a synthetic task (not yet in DB), create it first
            if task.createdAt == nil {
                _ = try await db.createMaintenanceTask(MaintenanceTaskInsert(
                    vehicleId: task.vehicleId,
                    householdId: task.householdId,
                    title: task.title,
                    frequency: task.frequency,
                    nextDueDate: task.nextDueDate,
                    description: task.description,
                    priority: task.priority,
                    assignedToUserId: userId,
                    templateId: task.templateId
                ))
            } else {
                _ = try await db.clearMaintenanceTaskAssignment(id: task.id, userId: userId)
            }
            Haptics.success()
            Analytics.track(.maintenanceTaskAssigned, ["task_id": task.id.uuidString, "assigned_user_id": userId?.uuidString ?? "unassigned"])
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        } catch {
            print("[TaskDetail] Failed to update assignment: \(error)")
            await MainActor.run { assignedUserId = previousUserId }
            Haptics.error()
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: HavenTheme.spacing12) {
            // Phase 56.4: "Mark as Complete" removed — "I already did
            // this" under the date line is the friendlier HNW-voice
            // equivalent and handles the common case (user did it
            // off-app) more naturally.

            if isOnHandymanList {
                Button {
                    Haptics.light()
                    showHandymanPunchList = true
                } label: {
                    HStack {
                        Image(systemName: "hammer.fill")
                        Text("Open contractor list")
                    }
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: HavenTheme.buttonHeight)
                    .background(HavenColors.creamLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .stroke(HavenColors.beige300, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
            } else {
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
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: HavenTheme.buttonHeight)
                    .background(HavenColors.creamLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .stroke(HavenColors.beige300, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
            }

            Button {
                Haptics.light()
                Analytics.track(.maintenanceTaskSnoozed, ["task_id": task.id.uuidString])
                // Phase 70.A1 follow-on F5 — Snooze's only entry point
                // is now this detail-sheet button (was leading-swipe pre-
                // follow-on; the swipe slot was repurposed for Archive).
                Analytics.track(.tasksV2SnoozeFromDetailSheet, ["source": "detail_sheet"])
                showSnooze = true
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Snooze")
                }
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: HavenTheme.buttonHeight)
                .background(HavenColors.creamLight)
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                        .stroke(HavenColors.beige300, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }

            // Phase 54B.3 / 56.4: Add-to-handyman entry point. Visible
            // when the matched template has DIY effort under an hour.
            // Vendor-assigned tasks route through the "Just this time /
            // From now on" confirmation dialog attached to `body`.
            if showAddToHandymanButton {
                Button {
                    Haptics.light()
                    handleAddToHandymanList()
                } label: {
                    HStack {
                        if isAddingToPunchList {
                            ProgressView()
                                .tint(HavenColors.navy800)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "hammer.fill")
                        }
                        Text("Add to contractor list")
                    }
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: HavenTheme.buttonHeight)
                    .background(HavenColors.creamLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .stroke(HavenColors.beige300, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .disabled(isAddingToPunchList)

                // Phase 78: "Have my handyman do this →" — stronger
                // commitment than "Add to handyman list". Atomically
                // inserts a punch item linked to the next handyman visit
                // AND stamps `delegated_to_punch_item_id` on this task
                // so the homeowner stops seeing it in their primary
                // task list (the visit card represents it now). Calls
                // the `delegate_task_to_punch_list` edge function so
                // both writes happen in one transaction.
                Button {
                    Haptics.light()
                    Task { await handleDelegateToHandyman() }
                } label: {
                    HStack {
                        if isDelegatingToHandyman {
                            ProgressView()
                                .tint(HavenColors.textOnAction)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        Text("Have my contractor do this")
                    }
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .frame(height: HavenTheme.buttonHeight)
                    .background(HavenColors.action)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .disabled(isDelegatingToHandyman)
            }

            // Phase 80 (discovery study): "Not for my home" — template-
            // level dismissal. Disappears the task AND prevents future
            // re-seeding of the same template via the reconciler. Distinct
            // from Delete (per-instance) and Archive (per-instance, kept
            // for history). Restore via Settings → Hidden Tasks.
            // Only shown for template-driven tasks (has templateId).
            if let templateKey = task.templateId, !templateKey.isEmpty,
               let propertyId = task.propertyId {
                Button {
                    Haptics.light()
                    let category = templateKey.split(separator: ":").first.map(String.init) ?? "unknown"
                    Analytics.track(.templateDismissed, [
                        "template_key": templateKey,
                        "category": category,
                        "reason": "not_applicable"
                    ])
                    Task {
                        try? await DatabaseService.shared.dismissTemplate(
                            propertyId: propertyId,
                            householdId: task.householdId,
                            templateKey: templateKey,
                            reason: "not_applicable"
                        )
                        // Archive this task instance — the template
                        // dismissal prevents future seeding, but the
                        // currently-scheduled row also needs to disappear.
                        await MaintenanceViewModel.shared.archiveTask(task)
                        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                        await MainActor.run { dismiss() }
                    }
                } label: {
                    HStack {
                        Image(systemName: "eye.slash")
                        Text("Not for my home")
                    }
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: HavenTheme.buttonHeight)
                    .background(HavenColors.creamLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .stroke(HavenColors.beige300, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
            }

            Button {
                Haptics.light()
                Analytics.track(.maintenanceTaskDeleted, ["task_id": task.id.uuidString])
                // July 2026 (audit F7): when a presenter wires onDeleteTask
                // it owns the delete + its own refresh. But 4 presenters
                // (dashboard cards, the push deep-link sheet) pass no
                // callback, so the button used to fire analytics + dismiss
                // and delete NOTHING — the task reappeared on next load.
                // Default to a real delete + cross-tab refresh.
                if let onDeleteTask {
                    onDeleteTask()
                } else {
                    let taskId = task.id
                    Task {
                        try? await db.deleteMaintenanceTask(id: taskId)
                        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                    }
                }
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Task")
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.critical.opacity(0.8))
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
                                    .foregroundStyle(HavenColors.textPrimary)
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
                                .foregroundStyle(HavenColors.textPrimary)
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
                                    .foregroundStyle(HavenColors.textPrimary)
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
                                .foregroundStyle(HavenColors.textPrimary)
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
    let contractorId: UUID?
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
                    .foregroundStyle(HavenColors.textPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task { await saveCompletion() }
                }
                .disabled(isSaving)
                .foregroundStyle(HavenColors.textPrimary)
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

            // 2. Create service record (only for property-linked tasks)
            if let propertyId = task.propertyId {
                _ = try await db.createServiceRecord(ServiceRecordInsert(
                    propertyId: propertyId,
                    householdId: task.householdId,
                    serviceDate: formatter.string(from: completionDate),
                    serviceType: "maintenance",
                    description: task.title,
                    systemId: task.systemId,
                    contractorId: contractorId,
                    cost: Double(cost),
                    notes: notes.isEmpty ? nil : notes
                ))
            }

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

            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil,
                userInfo: ["action": "completed", "id": task.id.uuidString])

            // 5. Push notification to all household members
            Task {
                let users = try? await db.fetchHouseholdUsers()
                let currentUser = try? await db.fetchCurrentUser()
                let completedBy = currentUser?.fullName?.components(separatedBy: " ").first ?? "Someone"
                let recipientIds = (users ?? []).map(\.id)
                await PushNotificationService.shared.sendTaskCompletedNotification(
                    taskTitle: task.title,
                    completedByName: completedBy,
                    recipientUserIds: recipientIds,
                    taskId: task.id
                )
            }

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

import SwiftUI

/// Phase 67: Primary surface for a Handyman seasonal visit.
///
/// Renders:
/// 1. Header — visit title, property, scheduled date, handyman contact.
/// 2. What's included — bundle children with `assigned_route == "handyman"`.
///    Each row has a claim-as-DIY toggle.
/// 3. Your DIY claims — children the user claimed (route = "diy").
///    Each row has a "Move back to handyman" action.
/// 4. Suggested additions — upsells pulled by HandymanUpsellScanner from
///    overdue / due-soon tasks + pending punch items. One-tap add per row.
/// 5. Add custom — opens AddMaintenanceTaskSheet pre-filled with handyman route.
/// 6. Footer — Schedule visit + Complete + Skip.
struct HandymanVisitDetailView: View {
    let parentTask: MaintenanceTaskDBRow
    var onDismiss: (() -> Void)? = nil

    @State private var allTasksForProperty: [MaintenanceTaskDBRow] = []
    @State private var punchItems: [HandymanPunchItemRow] = []
    @State private var preferredHandyman: ContractorRow?
    @State private var isLoading = true
    @State private var error: String?
    @State private var showSchedulePicker = false
    @State private var pickedScheduledDate = Date()
    @State private var showCompleteConfirm = false
    @State private var showSkipConfirm = false
    @State private var showAddCustom = false
    @State private var statusToast: String?

    // Inputs needed for AddMaintenanceTaskSheet — loaded in `load()`.
    @State private var addSheetProperties: [PropertyRow] = []
    @State private var addSheetSystems: [HomeSystemRow] = []
    @State private var addSheetContractors: [ContractorRow] = []

    @Environment(\.dismiss) private var dismiss

    // MARK: - Derived collections

    /// Bundle children = tasks whose template's bundleId matches this
    /// parent's templateId (the bundleId is encoded in the parent's
    /// templateId, e.g. "Handyman:spring").
    private var bundleChildren: [MaintenanceTaskDBRow] {
        guard let bundleKey = parentTask.templateId else { return [] }
        return allTasksForProperty.filter { task in
            guard task.id != parentTask.id else { return false }
            guard let templateId = task.templateId,
                  let template = MaintenanceTemplates.template(forKey: templateId) else {
                return false
            }
            return template.bundleId == bundleKey && task.isArchived != true
        }
    }

    private var whatsIncludedChildren: [MaintenanceTaskDBRow] {
        bundleChildren.filter { $0.assignedRoute != "diy" }
    }

    private var diyClaimedChildren: [MaintenanceTaskDBRow] {
        bundleChildren.filter { $0.assignedRoute == "diy" }
    }

    private var upsellCandidates: [HandymanVisitService.UpsellCandidate] {
        HandymanVisitService.scanUpsells(
            for: parentTask,
            allTasks: allTasksForProperty,
            punchItems: punchItems
        )
    }

    private var bundleKey: String {
        parentTask.templateId ?? ""
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                        headerCard

                        if whatsIncludedChildren.isEmpty {
                            emptyIncludedCard
                        } else {
                            whatsIncludedSection
                        }

                        if !diyClaimedChildren.isEmpty {
                            diyClaimsSection
                        }

                        if !upsellCandidates.isEmpty {
                            upsellsSection
                        }

                        addCustomButton

                        footerActions
                    }
                    .padding(HavenTheme.spacing20)
                }
            }
        }
        .navigationTitle(parentTask.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showSchedulePicker) {
            schedulePickerSheet
        }
        .sheet(isPresented: $showAddCustom) {
            AddMaintenanceTaskSheet(
                properties: addSheetProperties,
                systems: addSheetSystems,
                contractors: addSheetContractors,
                onSave: {
                    Task { await load() }
                    Analytics.track(.handymanVisitCustomAdded, [
                        "bundle_id": bundleKey
                    ])
                }
            )
        }
        .confirmationDialog(
            "Mark this visit complete?",
            isPresented: $showCompleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Mark complete") {
                Task { await complete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This completes every handyman-routed item on the list. DIY-claimed items stay on your personal list.")
        }
        .confirmationDialog(
            "Skip this visit?",
            isPresented: $showSkipConfirm,
            titleVisibility: .visible
        ) {
            Button("Skip this season", role: .destructive) {
                Task { await skip() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The visit will archive for this season. It'll come back next year.")
        }
        .overlay(alignment: .bottom) {
            if let toast = statusToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.success)
                    Text(toast)
                        .font(HavenTypography.uiLabel)
                }
                .padding()
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: statusToast)
        .onAppear {
            Analytics.track(.handymanVisitOpened, [
                "bundle_id": bundleKey,
                "source": "maintenance"
            ])
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: HavenTheme.spacing12) {
                    Image(systemName: "wrench.adjustable.fill")
                        .font(.title2)
                        .foregroundStyle(HavenColors.navy700)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(bundleKey.hasSuffix(":spring") ? "Spring Handyman Visit" : "Fall Handyman Visit")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        if let scheduled = parentTask.scheduledDate, !scheduled.isEmpty {
                            Text("Scheduled: \(scheduled)")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        } else {
                            Text("Due: \(parentTask.nextDueDate) · Not yet scheduled")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    Spacer()
                }

                Divider()

                if let handyman = preferredHandyman {
                    HStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "person.fill.checkmark")
                            .foregroundStyle(HavenColors.success)
                        Text(handyman.companyName)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                        Text(handyman.phone)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                } else {
                    HStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(HavenColors.warning)
                        Text("Add a handyman to schedule this visit")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                    }
                }
            }
        }
    }

    private var emptyIncludedCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("Nothing for the handyman this visit")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("You've claimed everything on your own list. You can still add custom items or skip this visit entirely.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    private var whatsIncludedSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("WHAT'S INCLUDED · \(whatsIncludedChildren.count)")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            ForEach(whatsIncludedChildren) { child in
                HavenCard {
                    HStack(alignment: .center, spacing: HavenTheme.spacing12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(child.title)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                                .multilineTextAlignment(.leading)
                            Text(child.frequency)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        Button {
                            Task { await claim(child) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.caption)
                                Text("I'll do this")
                                    .font(HavenTypography.uiLabelSmall)
                            }
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .overlay {
                                Capsule().strokeBorder(HavenColors.navy700, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var diyClaimsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("YOU'LL HANDLE · \(diyClaimedChildren.count)")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            ForEach(diyClaimedChildren) { child in
                HavenCard {
                    HStack(alignment: .center, spacing: HavenTheme.spacing12) {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(child.title)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Also on your personal task list")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        Button {
                            Task { await unclaim(child) }
                        } label: {
                            Text("Give back")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var upsellsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("YOUR HANDYMAN COULD ALSO HANDLE THESE · \(upsellCandidates.count)")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            ForEach(upsellCandidates) { candidate in
                HavenCard {
                    HStack(alignment: .center, spacing: HavenTheme.spacing12) {
                        Image(systemName: (candidate.urgencyDays ?? 0) < 0 ? "exclamationmark.circle.fill" : "clock.fill")
                            .foregroundStyle((candidate.urgencyDays ?? 0) < 0 ? HavenColors.critical : HavenColors.navy700)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(candidate.title)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(candidate.subtitle)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        Button {
                            Task { await addUpsell(candidate) }
                        } label: {
                            Text("Add to visit")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textOnNavy)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(HavenColors.navy800)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var addCustomButton: some View {
        Button {
            showAddCustom = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                Text("Add something custom to this visit")
                    .font(HavenTypography.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .foregroundStyle(HavenColors.navy700)
            .padding(HavenTheme.spacing16)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var footerActions: some View {
        VStack(spacing: HavenTheme.spacing8) {
            if preferredHandyman != nil {
                HavenButton(
                    title: parentTask.scheduledDate == nil ? "Schedule visit" : "Reschedule",
                    action: {
                        if let existing = parentTask.scheduledDate {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            pickedScheduledDate = formatter.date(from: existing) ?? Date()
                        }
                        showSchedulePicker = true
                    }
                )
            }

            Button {
                showCompleteConfirm = true
            } label: {
                Text("Mark visit complete")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.success)
                    .frame(maxWidth: .infinity)
                    .frame(height: HavenTheme.buttonHeight)
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .strokeBorder(HavenColors.success, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Button {
                showSkipConfirm = true
            } label: {
                Text("Skip this visit")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private var schedulePickerSheet: some View {
        NavigationStack {
            Form {
                Section("When?") {
                    DatePicker("Visit date", selection: $pickedScheduledDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("Schedule Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSchedulePicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            try? await HandymanVisitService.scheduleVisit(
                                parentId: parentTask.id,
                                date: pickedScheduledDate
                            )
                            showSchedulePicker = false
                            statusToast = "Visit scheduled"
                            await load()
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            statusToast = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            if let propertyId = parentTask.propertyId {
                allTasksForProperty = try await DatabaseService.shared.fetchMaintenanceTasks(propertyId: propertyId)
                addSheetSystems = (try? await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId)) ?? []
            }
            addSheetProperties = (try? await DatabaseService.shared.fetchProperties()) ?? []
            addSheetContractors = (try? await DatabaseService.shared.fetchContractors()) ?? []

            punchItems = (try? await DatabaseService.shared.fetchPendingHandymanPunchItems(
                householdId: parentTask.householdId
            )) ?? []

            // Resolve preferred handyman with three-tier fallback:
            //   1. households.preferred_handyman_contractor_id (Phase 63)
            //   2. parent task's assigned_contractor_id (existing link)
            //   3. any contractor in the household with category="Handyman"
            // (Phase 67). Covers TestFlight users whose household FK was
            // never set but whose Handyman:spring/fall parent is already
            // linked to a handyman via the old vendor-reconcile path.
            if let household = try? await DatabaseService.shared.fetchHousehold(id: parentTask.householdId),
               let handymanId = household.preferredHandymanContractorId,
               let match = addSheetContractors.first(where: { $0.id == handymanId }) {
                preferredHandyman = match
            } else if let assignedId = parentTask.assignedContractorId,
                      let match = addSheetContractors.first(where: { $0.id == assignedId }) {
                preferredHandyman = match
            } else {
                preferredHandyman = addSheetContractors.first { contractor in
                    contractor.category?.caseInsensitiveCompare("Handyman") == .orderedSame
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func claim(_ child: MaintenanceTaskDBRow) async {
        Haptics.light()
        try? await HandymanVisitService.reassignChild(
            taskId: child.id,
            toRoute: "diy",
            task: child
        )
        await load()
    }

    private func unclaim(_ child: MaintenanceTaskDBRow) async {
        Haptics.light()
        try? await HandymanVisitService.reassignChild(
            taskId: child.id,
            toRoute: "handyman",
            task: child
        )
        await load()
    }

    private func addUpsell(_ candidate: HandymanVisitService.UpsellCandidate) async {
        Haptics.light()
        try? await HandymanVisitService.addUpsellToVisit(candidate, bundleParent: parentTask)
        await load()
    }

    private func complete() async {
        Haptics.success()
        try? await HandymanVisitService.completeVisit(parent: parentTask)
        statusToast = "Visit complete"
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        onDismiss?()
        dismiss()
    }

    private func skip() async {
        Haptics.medium()
        try? await HandymanVisitService.skipVisit(parent: parentTask)
        statusToast = "Visit skipped"
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        onDismiss?()
        dismiss()
    }
}

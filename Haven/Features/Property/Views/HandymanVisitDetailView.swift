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

    private struct RequestMessageComposerConfiguration {
        var title: String = "Reply to handyman"
        var introText: String? = nil
        var placeholder: String = "What do you want the handyman to know?"
        var defaultStatusOnReply: HandymanRequestStatus? = nil
        var metadataEvent: String = "homeowner_reply"
    }

    @State private var allTasksForProperty: [MaintenanceTaskDBRow] = []
    @State private var punchItems: [HandymanPunchItemRow] = []
    @State private var preferredHandyman: ContractorRow?
    @State private var property: PropertyRow?
    @State private var systems: [HomeSystemRow] = []
    @State private var recentRequests: [HandymanRequestRow] = []
    @State private var coordinationRequest: HandymanRequestRow?
    @State private var requestMessages: [HandymanRequestMessageRow] = []
    @State private var latestQuote: ProviderQuoteRow?
    @State private var portalSession: HandymanPortalSessionRow?
    @State private var isLoading = true
    @State private var error: String?
    @State private var showSchedulePicker = false
    @State private var pickedScheduledDate = Date()
    @State private var showCompleteConfirm = false
    @State private var showSkipConfirm = false
    @State private var showAddCustom = false
    @State private var showRequestComposer = false
    @State private var showRequestMessageComposer = false
    @State private var showInviteSMSComposer = false
    @State private var showInviteMailComposer = false
    @State private var selectedRequestKind: HandymanRequestKind = .standardVisit
    @State private var statusToast: String?
    @State private var isPreparingMicrosite = false
    @State private var pendingQuoteResponse: ProviderQuoteStatus?
    @State private var resolvedParentTask: MaintenanceTaskDBRow?
    @State private var requestMessageComposerConfiguration = RequestMessageComposerConfiguration()

    /// Phase 73 sub-phase A: bidirectional scheduling state. The picker
    /// sheet is shared by "Suggest a date" (no proposal yet) and
    /// "Counter" (a proposal exists from the other side and homeowner
    /// wants to propose a different time). `proposedDate` tracks the
    /// picker's selection so the Send button submits the right moment.
    @State private var showSchedulingPicker = false
    @State private var schedulingPickerDate = Date().addingTimeInterval(60 * 60 * 48)
    @State private var schedulingNote: String = ""
    @State private var isSubmittingSchedule = false
    @State private var schedulingError: String?

    /// Phase 73 sub-phase B: quote negotiation state. Sign sheet captures
    /// the homeowner's typed name before approving. Counter sheet lets
    /// them edit line items + add a note before sending back.
    @State private var showSignQuoteSheet = false
    @State private var showCounterQuoteSheet = false
    @State private var signedNameInput: String = ""
    @State private var counterDraftLineItems: [ProviderQuoteLineItem] = []
    @State private var counterNoteInput: String = ""
    @State private var isSubmittingQuoteAction = false
    @State private var quoteActionError: String?

    // Inputs needed for AddMaintenanceTaskSheet — loaded in `load()`.
    @State private var addSheetProperties: [PropertyRow] = []
    @State private var addSheetSystems: [HomeSystemRow] = []
    @State private var addSheetContractors: [ContractorRow] = []

    @Environment(\.dismiss) private var dismiss

    // MARK: - Derived collections

    private var activeParentTask: MaintenanceTaskDBRow {
        resolvedParentTask ?? parentTask
    }

    /// Bundle children = tasks whose template's bundleId matches this
    /// parent's templateId (the bundleId is encoded in the parent's
    /// templateId, e.g. "Handyman:spring").
    private var bundleChildren: [MaintenanceTaskDBRow] {
        guard let bundleKey = activeParentTask.templateId else { return [] }
        return allTasksForProperty.filter { task in
            guard task.id != activeParentTask.id else { return false }
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
        activeParentTask.templateId ?? ""
    }

    private var shouldPromptFirstVisitSetup: Bool {
        HandymanVisitService.isFirstVisitSetupRecommended(
            systems: systems,
            property: property
        )
    }

    private var setupPrompts: [HandymanPortalSetupPrompt] {
        HandymanVisitService.setupPrompts(
            systems: systems,
            property: property
        )
    }

    private var scheduledLabel: String? {
        activeParentTask.scheduledDate
    }

    private var providerInviteURL: URL? {
        guard let portalSession else { return nil }
        return HandymanVisitService.providerWorkspaceURL(for: portalSession.portalToken)
    }

    private var preferredTimingLabel: String {
        if let scheduledLabel {
            return scheduledLabel
        }
        return activeParentTask.nextDueDate
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
                            premierProgramCard

                            if shouldPromptFirstVisitSetup {
                                firstVisitSetupCard
                            }

                            coordinationSection
                            visitSchedulingCard
                            if shouldShowAfterVisitReport {
                                afterVisitReportSection
                            }
                            if let latestQuote {
                                quoteSummarySection(latestQuote)
                            }
                            requestActionsSection

                            if !recentRequests.isEmpty {
                                recentRequestsSection
                            }

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
        .navigationTitle(activeParentTask.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showSchedulePicker) {
            schedulePickerSheet
        }
        .sheet(isPresented: $showSchedulingPicker) {
            visitSchedulingPickerSheet
        }
        .sheet(isPresented: $showSignQuoteSheet) {
            signQuoteSheet
        }
        .sheet(isPresented: $showCounterQuoteSheet) {
            counterQuoteSheet
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
        .sheet(isPresented: $showRequestComposer) {
            NavigationStack {
                HandymanRequestComposerSheet(
                    householdId: parentTask.householdId,
                    propertyId: parentTask.propertyId,
                    contractor: preferredHandyman,
                    visitTaskId: activeParentTask.id,
                    initialKind: selectedRequestKind,
                    defaultFirstVisitSetup: shouldPromptFirstVisitSetup,
                    quickUpsellTitles: Array(upsellCandidates.prefix(3)).map(\.title),
                    onSaved: {
                        Task { await load() }
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showRequestMessageComposer) {
            if let coordinationRequest {
                NavigationStack {
                    HandymanRequestMessageComposerSheet(
                        request: coordinationRequest,
                        navigationTitle: requestMessageComposerConfiguration.title,
                        introText: requestMessageComposerConfiguration.introText,
                        placeholder: requestMessageComposerConfiguration.placeholder,
                        defaultStatusOnReply: requestMessageComposerConfiguration.defaultStatusOnReply,
                        metadataEvent: requestMessageComposerConfiguration.metadataEvent,
                        onSaved: {
                            Task { await load() }
                        }
                    )
                }
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showInviteSMSComposer) {
            if let recipient = invitePhoneRecipient,
               let providerInviteURL {
                MessageComposeView(
                    recipients: [recipient],
                    body: HandymanVisitService.inviteSMSBody(
                        parentTask: activeParentTask,
                        property: property,
                        preferredTiming: preferredTimingLabel,
                        portalURL: providerInviteURL
                    ),
                    onFinish: { _ in
                        showInviteSMSComposer = false
                    }
                )
            }
        }
        .sheet(isPresented: $showInviteMailComposer) {
            if let recipient = preferredHandyman?.email,
               let providerInviteURL {
                MailComposeView(
                    recipients: [recipient],
                    subject: HandymanVisitService.inviteEmailSubject(
                        parentTask: activeParentTask,
                        property: property,
                        preferredTiming: preferredTimingLabel
                    ),
                    body: HandymanVisitService.inviteEmailBody(
                        parentTask: activeParentTask,
                        property: property,
                        preferredTiming: preferredTimingLabel,
                        portalURL: providerInviteURL
                    ),
                    attachmentData: nil,
                    attachmentMimeType: nil,
                    attachmentFileName: nil,
                    onDismiss: { _ in
                        showInviteMailComposer = false
                    }
                )
            }
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
                        if let scheduled = scheduledLabel, !scheduled.isEmpty {
                            Text("Scheduled: \(scheduled)")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        } else {
                            Text("Due: \(activeParentTask.nextDueDate) · Not yet scheduled")
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

    private var coordinationSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("VISIT COORDINATION")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    if let coordinationRequest {
                        HStack(spacing: 8) {
                            Text(coordinationRequest.typedStatus.displayLabel)
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                .foregroundStyle(
                                    coordinationRequest.typedStatus.actionRequiredByHomeowner
                                        ? HavenColors.action
                                        : HavenColors.navy700
                                )
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    (
                                        coordinationRequest.typedStatus.actionRequiredByHomeowner
                                            ? HavenColors.action
                                            : HavenColors.navy700
                                    ).opacity(0.08)
                                )
                                .clipShape(Capsule())

                            if portalSession != nil {
                                Text("Provider link ready")
                                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                    .foregroundStyle(HavenColors.success)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(HavenColors.success.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }

                        Text(coordinationRequest.typedStatus.homeownerSummary)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if !requestMessages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(requestMessages.suffix(4))) { message in
                                    coordinationMessageRow(message)
                                }
                            }
                        }

                        HStack(spacing: HavenTheme.spacing8) {
                            if providerInviteURL != nil, preferredHandyman != nil {
                                Button {
                                    sendInviteText()
                                } label: {
                                    labelPill("Text invite", color: HavenColors.action)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    sendInviteEmail()
                                } label: {
                                    labelPill("Email invite", color: HavenColors.navy700)
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                configureStandardMessageComposer(for: coordinationRequest)
                                showRequestMessageComposer = true
                            } label: {
                                labelPill(
                                    coordinationRequest.typedStatus.actionRequiredByHomeowner ? "Reply" : "Message",
                                    color: HavenColors.textSecondary
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    } else if preferredHandyman == nil {
                        Text("Choose a preferred handyman first. Once a date is set, Chez will prepare the secure provider link so they can confirm the visit, ask questions, or start the job.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else {
                        Text("Pick the visit date and Chez will prepare the secure provider link so the handyman can confirm or propose another date before the visit begins.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Phase 73: visit scheduling card

    /// Renders the bidirectional scheduling round-trip on top of the
    /// existing coordination request. Four states:
    ///
    /// 1. No coordinationRequest yet → don't render (homeowner hasn't
    ///    sent a request to the provider).
    /// 2. Confirmed (confirmedVisitAt != nil) → green "Confirmed for X"
    ///    pill, no buttons.
    /// 3. Awaiting homeowner (handyman just proposed) → "Provider
    ///    suggested {date}" + Accept / Counter buttons.
    /// 4. Awaiting handyman (homeowner just proposed) → "You suggested
    ///    {date} — waiting on Provider" + Counter button (resend with
    ///    new time).
    /// 5. No proposal yet but request exists → "Suggest a visit date"
    ///    button.
    @ViewBuilder
    private var visitSchedulingCard: some View {
        if let request = coordinationRequest {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("VISIT SCHEDULING")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        if let confirmed = request.confirmedVisitAt {
                            schedulingConfirmedRow(confirmed)
                        } else if let proposed = request.proposedVisitAt {
                            schedulingProposalRow(
                                proposed: proposed,
                                proposer: request.proposedByActor ?? .handyman
                            )
                        } else {
                            schedulingEmptyRow
                        }

                        if let schedulingError {
                            Text(schedulingError)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.critical)
                        }
                    }
                }
            }
        }
    }

    private func schedulingConfirmedRow(_ confirmed: Date) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(HavenColors.success)
            VStack(alignment: .leading, spacing: 4) {
                Text("Confirmed visit")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(Self.scheduleDisplayFormatter.string(from: confirmed))
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    private func schedulingProposalRow(proposed: Date, proposer: HandymanScheduleActor) -> some View {
        let providerName = preferredHandyman?.companyName ?? "Provider"
        let isHandymanProposal = proposer == .handyman

        return VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(isHandymanProposal ? HavenColors.action : HavenColors.navy700)
                VStack(alignment: .leading, spacing: 4) {
                    Text(isHandymanProposal ? "\(providerName) suggested" : "You suggested")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(Self.scheduleDisplayFormatter.string(from: proposed))
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    if !isHandymanProposal {
                        Text("Waiting on \(providerName) to confirm or counter.")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }

            HStack(spacing: HavenTheme.spacing8) {
                if isHandymanProposal {
                    Button {
                        Task { await acceptScheduling() }
                    } label: {
                        Text("Accept")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.textOnAction)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, HavenTheme.spacing8)
                            .background(HavenColors.action)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmittingSchedule)
                }

                Button {
                    schedulingPickerDate = proposed
                    schedulingNote = ""
                    schedulingError = nil
                    showSchedulingPicker = true
                } label: {
                    Text(isHandymanProposal ? "Counter" : "Update suggestion")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.navy700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HavenTheme.spacing8)
                        .background(HavenColors.navy700.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(.plain)
                .disabled(isSubmittingSchedule)
            }
        }
    }

    private var schedulingEmptyRow: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Suggest a visit date")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Pick a window that works for you. Your handyman will accept it or counter with another time.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                schedulingPickerDate = Date().addingTimeInterval(60 * 60 * 48)
                schedulingNote = ""
                schedulingError = nil
                showSchedulingPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Suggest a date")
                        .font(HavenTypography.uiButton)
                }
                .foregroundStyle(HavenColors.textOnAction)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HavenTheme.spacing8)
                .background(HavenColors.action)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }
            .buttonStyle(.plain)
            .disabled(isSubmittingSchedule)
            .padding(.top, HavenTheme.spacing4)
        }
    }

    /// Sheet body for the propose / counter date picker. Used by both
    /// the empty-state "Suggest a date" CTA and the existing-proposal
    /// "Counter" CTA. Note field is optional.
    private var visitSchedulingPickerSheet: some View {
        NavigationStack {
            Form {
                Section("Pick a date and time") {
                    DatePicker(
                        "",
                        selection: $schedulingPickerDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }
                Section("Note (optional)") {
                    TextField("Anything they should know?", text: $schedulingNote, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Suggest a visit time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showSchedulingPicker = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSubmittingSchedule ? "Sending…" : "Send") {
                        Task { await proposeScheduling() }
                    }
                    .disabled(isSubmittingSchedule)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Phase 73 actions

    private func proposeScheduling() async {
        guard let request = coordinationRequest else {
            schedulingError = "No active request to schedule against."
            return
        }
        isSubmittingSchedule = true
        defer { isSubmittingSchedule = false }
        do {
            _ = try await DatabaseService.shared.proposeVisitTime(
                requestId: request.id,
                proposedAt: schedulingPickerDate,
                proposedBy: .homeowner,
                note: schedulingNote
            )
            Haptics.success()
            schedulingError = nil
            showSchedulingPicker = false
            schedulingNote = ""
            await load()
            Analytics.track(.handymanVisitTimeProposed, [
                "request_id": request.id.uuidString,
                "proposed_by": "homeowner"
            ])
        } catch {
            schedulingError = error.localizedDescription
        }
    }

    private func acceptScheduling() async {
        guard let request = coordinationRequest else { return }
        isSubmittingSchedule = true
        defer { isSubmittingSchedule = false }
        do {
            _ = try await DatabaseService.shared.acceptVisitTime(
                requestId: request.id,
                acceptedBy: .homeowner,
                note: nil
            )
            Haptics.success()
            schedulingError = nil
            await load()
            Analytics.track(.handymanVisitTimeAccepted, [
                "request_id": request.id.uuidString,
                "accepted_by": "homeowner"
            ])
        } catch {
            schedulingError = error.localizedDescription
        }
    }

    private static let scheduleDisplayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d 'at' h:mm a"
        return f
    }()

    // MARK: - Phase 73 sub-phase E: after-visit report

    /// Renders the homeowner's after-visit report inline once the
    /// coordinationRequest reflects a completed (or follow-up-recommended)
    /// state. The view component itself fetches `handyman_visit_reports`
    /// by visit_task_id and renders a graceful empty state if the
    /// technician hasn't finalized the report yet.
    private var shouldShowAfterVisitReport: Bool {
        guard let request = coordinationRequest else { return false }
        let status = request.status.lowercased()
        return status == "completed" || status == "follow_up_recommended"
    }

    private var afterVisitReportSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("AFTER-VISIT REPORT")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            HandymanVisitReportView(
                visitTaskId: activeParentTask.id,
                parentVisitTitle: activeParentTask.title,
                providerName: preferredHandyman?.companyName
            )
        }
    }

    // MARK: - Phase 73 sub-phase B: sign + counter sheets

    /// Sheet body for signing a quote. Captures the homeowner's typed
    /// name before approving so we have a signed-agreement record on
    /// the quote row.
    private var signQuoteSheet: some View {
        NavigationStack {
            Form {
                Section {
                    if let total = latestQuote?.total, let currency = latestQuote?.currency {
                        Text(total.formatted(.currency(code: currency)))
                            .font(HavenTypography.fraunces(size: 28, weight: 600))
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                    Text("Type your full name to sign and approve. Your handyman will see this as your authorization to start work on the agreed scope.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Section("Your full name") {
                    TextField("e.g. Tom Burke", text: $signedNameInput)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                }
                if let quoteActionError {
                    Section {
                        Text(quoteActionError)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
            }
            .navigationTitle("Sign & approve")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showSignQuoteSheet = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSubmittingQuoteAction ? "Signing…" : "Sign") {
                        Task { await submitSignQuote() }
                    }
                    .disabled(
                        isSubmittingQuoteAction
                        || signedNameInput.trimmingCharacters(in: .whitespacesAndNewlines).count < 2
                    )
                }
            }
        }
        .presentationDetents([.medium])
    }

    /// Sheet body for countering a quote — line items become editable,
    /// totals recompute live, and the homeowner can attach a note
    /// explaining the change. Send routes through `counterProviderQuote`.
    private var counterQuoteSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Adjust quantities or remove items, then send your counter back. Your handyman will either accept it or come back with a revised quote.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Section("Line items") {
                    ForEach($counterDraftLineItems) { $item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.name)
                                .font(HavenTypography.body.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            if let description = item.description, !description.isEmpty {
                                Text(description)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            HStack(spacing: HavenTheme.spacing8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Qty")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    TextField("0", value: $item.quantity, format: .number)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Unit price")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    TextField("0", value: $item.unitPrice, format: .number)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                            HStack {
                                Spacer()
                                Text("Line total: \((item.quantity * item.unitPrice).formatted(.currency(code: latestQuote?.currency ?? "USD")))")
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        counterDraftLineItems.remove(atOffsets: offsets)
                    }
                }

                Section {
                    HStack {
                        Text("New total")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                        Text(counterTotal.formatted(.currency(code: latestQuote?.currency ?? "USD")))
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.action)
                    }
                }

                Section("Note to your handyman (optional)") {
                    TextField("Why these changes?", text: $counterNoteInput, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let quoteActionError {
                    Section {
                        Text(quoteActionError)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
            }
            .navigationTitle("Counter the quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showCounterQuoteSheet = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSubmittingQuoteAction ? "Sending…" : "Send counter") {
                        Task { await submitCounterQuote() }
                    }
                    .disabled(isSubmittingQuoteAction || counterDraftLineItems.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var counterTotal: Double {
        counterDraftLineItems.reduce(0) { partial, item in
            partial + (item.quantity * item.unitPrice)
        }
    }

    private func submitSignQuote() async {
        guard let quote = latestQuote else { return }
        let trimmed = signedNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSubmittingQuoteAction = true
        defer { isSubmittingQuoteAction = false }
        do {
            _ = try await DatabaseService.shared.signProviderQuote(
                id: quote.id,
                signedName: trimmed
            )
            Haptics.success()
            showSignQuoteSheet = false
            quoteActionError = nil
            await load()
            Analytics.track(.handymanQuoteSigned, [
                "quote_id": quote.id.uuidString
            ])
        } catch {
            quoteActionError = error.localizedDescription
        }
    }

    private func submitCounterQuote() async {
        guard let quote = latestQuote else { return }
        guard !counterDraftLineItems.isEmpty else { return }

        isSubmittingQuoteAction = true
        defer { isSubmittingQuoteAction = false }
        do {
            _ = try await DatabaseService.shared.counterProviderQuote(
                id: quote.id,
                revisedLineItems: counterDraftLineItems,
                note: counterNoteInput
            )
            Haptics.success()
            showCounterQuoteSheet = false
            quoteActionError = nil
            await load()
            Analytics.track(.handymanQuoteCountered, [
                "quote_id": quote.id.uuidString,
                "line_items": String(counterDraftLineItems.count)
            ])
        } catch {
            quoteActionError = error.localizedDescription
        }
    }

    private var premierProgramCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: "star.circle.fill")
                        .font(.title3)
                        .foregroundStyle(HavenColors.warning)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Premier handyman program")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("This is the house operator lane: standard visits, direct requests, and cleaner future service because Chez and your handyman keep the home record sharper together.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: HavenTheme.spacing8) {
                    micrositePill("2 standard visits")
                    micrositePill("Quotes and messages")
                    micrositePill("Home profile updates")
                }
            }
        }
    }

    private var firstVisitSetupCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: "house.and.flag.fill")
                        .font(.title3)
                        .foregroundStyle(HavenColors.navy700)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Use this first visit to set the house up")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Chez already has strong system records. The missing piece is prompting the handyman to capture the context that makes future service smoother.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(setupPrompts.prefix(4))) { prompt in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: prompt.isRequired ? "checkmark.seal.fill" : "circle")
                                .font(.caption)
                                .foregroundStyle(prompt.isRequired ? HavenColors.navy700 : HavenColors.textTertiary)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(prompt.title)
                                    .font(HavenTypography.body.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(prompt.detail)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private var requestActionsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("REQUESTS & QUOTES")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: HavenTheme.spacing8),
                GridItem(.flexible(), spacing: HavenTheme.spacing8),
            ], spacing: HavenTheme.spacing8) {
                ForEach(requestKindsForSurface) { kind in
                    Button {
                        selectedRequestKind = kind
                        showRequestComposer = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: kind.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.white)
                            Text(kind.title)
                                .font(HavenTypography.body.weight(.semibold))
                                .foregroundStyle(Color.white)
                                .multilineTextAlignment(.leading)
                            Text(kind.helperText)
                                .font(HavenTypography.caption)
                                .foregroundStyle(Color.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 168, alignment: .topLeading)
                        .padding(HavenTheme.spacing16)
                        .background(
                            LinearGradient(
                                colors: [HavenColors.navy900, HavenColors.navy700],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        .overlay {
                            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quoteSummarySection(_ quote: ProviderQuoteRow) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("LATEST QUOTE")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(quote.title)
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(quoteStatusSubtitle(quote))
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            Text(quote.total.formatted(.currency(code: quote.currency)))
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.navy700)
                            quoteStatusPill(quote)
                        }
                    }

                    Text(quoteStatusSummary(quote))
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if quote.typedStatus.allowsSign {
                        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                            ViewThatFits {
                                HStack(spacing: HavenTheme.spacing8) {
                                    signAndApproveButton(for: quote)
                                    if quote.typedStatus.allowsCounter {
                                        counterQuoteButton(for: quote)
                                    }
                                    quoteQuestionButton
                                    declineQuoteButton
                                }

                                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                                    signAndApproveButton(for: quote)
                                    HStack(spacing: HavenTheme.spacing8) {
                                        if quote.typedStatus.allowsCounter {
                                            counterQuoteButton(for: quote)
                                        }
                                        quoteQuestionButton
                                        declineQuoteButton
                                    }
                                }
                            }

                            Text("Sign to lock in this scope, propose changes line-by-line, or ask a question. Your handyman sees the response in Chez right away.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let signedName = quote.signedName,
                       let signedAt = quote.signedAt {
                        HStack(alignment: .center, spacing: HavenTheme.spacing8) {
                            Image(systemName: "signature")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(HavenColors.success)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Signed by \(signedName)")
                                    .font(HavenTypography.uiLabel.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(signedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            Spacer()
                        }
                        .padding(HavenTheme.spacing12)
                        .background(HavenColors.success.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }

                    ForEach(Array(quote.lineItems.prefix(4))) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(HavenColors.textTertiary)
                                .frame(width: 5, height: 5)
                                .padding(.top, 7)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(HavenTypography.body.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("\(item.quantity.formatted()) \(item.unit) · \(item.unitPrice.formatted(.currency(code: quote.currency))) each")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                        }
                    }

                    if let scopeNotes = quote.scopeNotes, !scopeNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scope notes")
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(scopeNotes)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let homeownerMessage = quote.homeownerMessage, !homeownerMessage.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Note from your handyman")
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(homeownerMessage)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func quoteStatusPill(_ quote: ProviderQuoteRow) -> some View {
        Text(quote.typedStatus.displayLabel)
            .font(HavenTypography.uiLabelSmall.weight(.semibold))
            .foregroundStyle(quoteStatusColor(quote))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(quoteStatusColor(quote).opacity(0.09))
            .clipShape(Capsule())
    }

    private func quoteStatusColor(_ quote: ProviderQuoteRow) -> Color {
        switch quote.typedStatus {
        case .approved:
            return HavenColors.success
        case .declined:
            return HavenColors.critical
        case .sent, .viewed:
            return HavenColors.action
        case .withdrawn, .superseded:
            return HavenColors.warning
        case .counteredByHomeowner:
            return HavenColors.action
        case .draft:
            return HavenColors.textSecondary
        }
    }

    private func quoteStatusSubtitle(_ quote: ProviderQuoteRow) -> String {
        let lineItemCopy = "\(quote.lineItems.count) line item\(quote.lineItems.count == 1 ? "" : "s")"
        switch quote.typedStatus {
        case .approved:
            if let approvedAt = quote.approvedAt {
                return "\(lineItemCopy) · Approved \(approvedAt.formatted(date: .abbreviated, time: .omitted))"
            }
        case .declined:
            if let declinedAt = quote.declinedAt {
                return "\(lineItemCopy) · Declined \(declinedAt.formatted(date: .abbreviated, time: .omitted))"
            }
        case .viewed:
            if let viewedAt = quote.viewedAt {
                return "\(lineItemCopy) · Opened \(viewedAt.formatted(date: .abbreviated, time: .omitted))"
            }
        case .sent:
            if let sentAt = quote.sentAt {
                return "\(lineItemCopy) · Sent \(sentAt.formatted(date: .abbreviated, time: .omitted))"
            }
        case .withdrawn:
            return "\(lineItemCopy) · Withdrawn"
        case .draft:
            return "\(lineItemCopy) · Draft"
        case .counteredByHomeowner:
            if let revisedAt = quote.homeownerRevisedAt {
                return "\(lineItemCopy) · Countered \(revisedAt.formatted(date: .abbreviated, time: .omitted))"
            }
            return "\(lineItemCopy) · Countered"
        case .superseded:
            return "\(lineItemCopy) · Superseded"
        }

        return lineItemCopy
    }

    private func quoteStatusSummary(_ quote: ProviderQuoteRow) -> String {
        switch quote.typedStatus {
        case .sent:
            return "Your handyman priced this scope and is waiting for your response so they can plan the next step."
        case .viewed:
            return "You've opened the quote. Approve it, ask a question, or decline it without leaving Chez."
        case .approved:
            return "You've approved this scope. Your handyman now sees that response inside Chez and can move the work forward."
        case .declined:
            return "You've declined this quote. The thread stays open if you want to send more context or ask for a revised scope."
        case .withdrawn:
            return "This quote is no longer active."
        case .draft:
            return "This quote is still being prepared."
        case .counteredByHomeowner:
            return "Your counter has been sent. Your handyman will accept it as-is or come back with a revised quote."
        case .superseded:
            return "An updated version of this quote took its place. Open the latest version to respond."
        }
    }

    private var approveQuoteButton: some View {
        Button {
            Task { await respondToLatestQuote(.approved) }
        } label: {
            HStack(spacing: 6) {
                if pendingQuoteResponse == .approved {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                }
                Text("Approve quote")
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
            }
            .foregroundStyle(HavenColors.textOnAction)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(HavenColors.action)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(pendingQuoteResponse != nil)
    }

    /// Phase 73 sub-phase B: replaces the bare approve button. Opens
    /// the sign sheet so the homeowner types their name before the
    /// quote flips to approved + signed.
    private func signAndApproveButton(for quote: ProviderQuoteRow) -> some View {
        Button {
            signedNameInput = ""
            quoteActionError = nil
            showSignQuoteSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "signature")
                    .font(.caption)
                Text("Sign & approve")
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
            }
            .foregroundStyle(HavenColors.textOnAction)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(HavenColors.action)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(pendingQuoteResponse != nil || isSubmittingQuoteAction)
    }

    /// Phase 73 sub-phase B: opens the counter sheet pre-populated with
    /// the current quote's line items. Homeowner edits qty/price/scope
    /// and sends back; provider sees a `countered_by_homeowner` row.
    private func counterQuoteButton(for quote: ProviderQuoteRow) -> some View {
        Button {
            counterDraftLineItems = quote.lineItems
            counterNoteInput = ""
            quoteActionError = nil
            showCounterQuoteSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "pencil.line")
                    .font(.caption)
                Text("Counter")
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
            }
            .foregroundStyle(HavenColors.navy700)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(HavenColors.navy700.opacity(0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(pendingQuoteResponse != nil || isSubmittingQuoteAction)
    }

    private var quoteQuestionButton: some View {
        Button {
            openQuoteQuestionComposer()
        } label: {
            labelPill("Ask question", color: HavenColors.navy700)
        }
        .buttonStyle(.plain)
        .disabled(pendingQuoteResponse != nil)
    }

    private var declineQuoteButton: some View {
        Button {
            Task { await respondToLatestQuote(.declined) }
        } label: {
            labelPill("Decline", color: HavenColors.textSecondary)
        }
        .buttonStyle(.plain)
        .disabled(pendingQuoteResponse != nil)
    }

    private var recentRequestsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("RECENT HANDYMAN REQUESTS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            ForEach(recentRequests.prefix(4)) { request in
                HavenCard {
                    HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(request.title)
                                .font(HavenTypography.body.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(requestStatusSubtitle(request))
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        Text(request.typedStatus.displayLabel)
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(HavenColors.beige200)
                            .clipShape(Capsule())
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

    private var requestKindsForSurface: [HandymanRequestKind] {
        var kinds: [HandymanRequestKind] = [.standardVisit, .quote, .repair, .install, .assembly, .question]
        if shouldPromptFirstVisitSetup {
            kinds.append(.setup)
        }
        return kinds
    }

    private var footerActions: some View {
        VStack(spacing: HavenTheme.spacing8) {
            if preferredHandyman != nil {
                HavenButton(
                    title: scheduledLabel == nil ? "Schedule visit" : "Reschedule",
                    action: {
                        if let existing = scheduledLabel {
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

    private func micrositePill(_ title: String) -> some View {
        Text(title)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(HavenColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(HavenColors.beige200)
            .clipShape(Capsule())
    }

    private func micrositeChecklistRow(_ title: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(HavenColors.success)
            Text(title)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    private func labelPill(_ title: String, color: Color) -> some View {
        Text(title)
            .font(HavenTypography.uiLabelSmall.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.08))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func coordinationMessageRow(_ message: HandymanRequestMessageRow) -> some View {
        switch message.typedKind {
        case .proposeTime:
            scheduleSystemEventRow(
                message: message,
                icon: "calendar.badge.clock",
                tint: HavenColors.action,
                headline: scheduleProposedHeadline(for: message)
            )
        case .acceptTime:
            scheduleSystemEventRow(
                message: message,
                icon: "checkmark.seal.fill",
                tint: HavenColors.success,
                headline: scheduleConfirmedHeadline(for: message)
            )
        case .declineTime:
            scheduleSystemEventRow(
                message: message,
                icon: "xmark.octagon.fill",
                tint: HavenColors.critical,
                headline: "Declined the proposed time"
            )
        case .quoteSent:
            scheduleSystemEventRow(
                message: message,
                icon: "doc.text.fill",
                tint: HavenColors.action,
                headline: "Sent a quote — open the chat to review"
            )
        case .text:
            coordinationTextMessageRow(message)
        }
    }

    private func coordinationTextMessageRow(_ message: HandymanRequestMessageRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(senderDisplayName(for: message.senderRole))
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                    .foregroundStyle(HavenColors.navy700)
                Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            Text(message.body)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    /// Renders propose / accept / decline events as styled system rows
    /// rather than plain text — calendar icon + headline + author/time
    /// caption + optional note (the message body when it's distinct from
    /// the auto-generated headline).
    private func scheduleSystemEventRow(
        message: HandymanRequestMessageRow,
        icon: String,
        tint: Color,
        headline: String
    ) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(headline)
                    .font(HavenTypography.uiLabel.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)

                Text("\(senderDisplayName(for: message.senderRole)) · \(message.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)

                if shouldShowSystemEventBody(for: message, headline: headline) {
                    Text(message.body)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing12)
        .background(tint.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(tint.opacity(0.25), lineWidth: 1)
        )
    }

    private func scheduleProposedHeadline(for message: HandymanRequestMessageRow) -> String {
        let actor = senderDisplayName(for: message.senderRole)
        if let proposed = message.proposedTime {
            return "\(actor) proposed \(Self.scheduleDisplayFormatter.string(from: proposed))"
        }
        return "\(actor) proposed a new visit time"
    }

    private func scheduleConfirmedHeadline(for message: HandymanRequestMessageRow) -> String {
        let actor = senderDisplayName(for: message.senderRole)
        if let confirmed = message.confirmedTime {
            return "\(actor) confirmed \(Self.scheduleDisplayFormatter.string(from: confirmed))"
        }
        return "\(actor) confirmed the visit time"
    }

    /// True when the body has more to say than the auto-generated
    /// headline (e.g. an accompanying free-text note). The RPCs default
    /// the body to a sentence containing the timestamp, so a
    /// substring-of-headline match suppresses redundant rendering.
    private func shouldShowSystemEventBody(
        for message: HandymanRequestMessageRow,
        headline: String
    ) -> Bool {
        let trimmed = message.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        // The default body for both RPCs starts with "Proposed " or
        // "Confirmed" — anything substantively longer than that is a
        // user-supplied note worth surfacing.
        if trimmed == "Confirmed." { return false }
        if trimmed.hasPrefix("Proposed ") && trimmed.count <= 60 { return false }
        return true
    }

    private func senderDisplayName(for role: String) -> String {
        switch role.lowercased() {
        case "homeowner": return "You"
        case "vendor": return preferredHandyman?.companyName ?? "Provider"
        case "haven": return "Chez"
        default: return role.capitalized
        }
    }

    private func requestStatusSubtitle(_ request: HandymanRequestRow) -> String {
        let parts = [
            HandymanRequestKind(rawValue: request.requestType)?.title,
            request.preferredTiming,
            request.createdAt.formatted(date: .abbreviated, time: .omitted)
        ].compactMap { value -> String? in
            guard let value, !value.isEmpty else { return nil }
            return value
        }
        return parts.joined(separator: " · ")
    }

    private var invitePhoneRecipient: String? {
        preferredHandyman?.phone.filter(\.isNumber)
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
                            if let preferredHandyman {
                                let prepared = try? await HandymanVisitService.prepareVisitCoordination(
                                    parentTask: activeParentTask,
                                    scheduledDate: pickedScheduledDate,
                                    property: property,
                                    systems: systems,
                                    checklistTasks: whatsIncludedChildren,
                                    diyClaims: diyClaimedChildren,
                                    punchItems: punchItems,
                                    upsellCandidates: upsellCandidates,
                                    preferredHandyman: preferredHandyman
                                )
                                coordinationRequest = prepared?.request
                                portalSession = prepared?.portalSession
                            } else {
                                try? await HandymanVisitService.scheduleVisit(
                                    parentId: activeParentTask.id,
                                    date: pickedScheduledDate
                                )
                            }
                            showSchedulePicker = false
                            statusToast = preferredHandyman == nil
                                ? "Visit scheduled"
                                : "Visit scheduled. Send the invite link."
                            await load()
                            if preferredHandyman != nil {
                                sendInviteText()
                            }
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
                resolvedParentTask = allTasksForProperty.first(where: { $0.id == parentTask.id }) ?? parentTask
                systems = (try? await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId)) ?? []
                addSheetSystems = systems
                property = try? await DatabaseService.shared.fetchProperty(id: propertyId)
                portalSession = try? await DatabaseService.shared.fetchHandymanPortalSession(visitTaskId: activeParentTask.id)
            }
            addSheetProperties = (try? await DatabaseService.shared.fetchProperties()) ?? []
            addSheetContractors = (try? await DatabaseService.shared.fetchContractors()) ?? []

            punchItems = (try? await DatabaseService.shared.fetchPendingHandymanPunchItems(
                householdId: parentTask.householdId
            )) ?? []
            await refreshCollaborationData(markQuoteViewed: true)

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

    @MainActor
    private func configureStandardMessageComposer(for request: HandymanRequestRow) {
        requestMessageComposerConfiguration = RequestMessageComposerConfiguration(
            title: "Reply to handyman",
            introText: request.typedStatus.homeownerSummary,
            placeholder: "What do you want the handyman to know?",
            defaultStatusOnReply: request.typedStatus.actionRequiredByHomeowner ? .sentToHandyman : nil,
            metadataEvent: "homeowner_reply"
        )
    }

    @MainActor
    private func openQuoteQuestionComposer() {
        guard coordinationRequest != nil else { return }
        requestMessageComposerConfiguration = RequestMessageComposerConfiguration(
            title: "Ask about this quote",
            introText: "Send a quick question back to the handyman about this scope, timing, or pricing.",
            placeholder: "Ask about a line item, timing, or any detail you want clarified.",
            defaultStatusOnReply: .sentToHandyman,
            metadataEvent: "quote_question"
        )
        showRequestMessageComposer = true
    }

    private func refreshCollaborationData(markQuoteViewed: Bool) async {
        recentRequests = (try? await DatabaseService.shared.fetchHandymanRequests(
            householdId: parentTask.householdId,
            propertyId: parentTask.propertyId,
            limit: 6
        )) ?? []
        coordinationRequest = (try? await DatabaseService.shared.fetchLatestHandymanRequest(visitTaskId: activeParentTask.id))
        if let coordinationRequest {
            requestMessages = (try? await DatabaseService.shared.fetchHandymanRequestMessages(requestId: coordinationRequest.id)) ?? []
            let quotes = (try? await DatabaseService.shared.fetchProviderQuotes(requestId: coordinationRequest.id)) ?? []
            latestQuote = quotes.first(where: { quote in
                [.sent, .viewed, .approved, .declined].contains(quote.typedStatus)
            }) ?? quotes.first

            if markQuoteViewed,
               let latestQuote,
               latestQuote.typedStatus == .sent,
               let viewedQuote = try? await DatabaseService.shared.respondToProviderQuote(
                   id: latestQuote.id,
                   status: .viewed
               ) {
                self.latestQuote = viewedQuote
            }
        } else {
            requestMessages = []
            latestQuote = nil
        }
    }

    private func respondToLatestQuote(_ response: ProviderQuoteStatus) async {
        guard let latestQuote else { return }
        pendingQuoteResponse = response
        defer { pendingQuoteResponse = nil }

        do {
            self.latestQuote = try await DatabaseService.shared.respondToProviderQuote(
                id: latestQuote.id,
                status: response
            )
            if let coordinationRequest {
                requestMessages = (try? await DatabaseService.shared.fetchHandymanRequestMessages(requestId: coordinationRequest.id)) ?? requestMessages
            }
            Haptics.success()
            statusToast = response == .approved ? "Quote approved" : "Quote declined"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                statusToast = nil
            }
        } catch {
            Haptics.error()
            statusToast = "Couldn't update the quote right now"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                statusToast = nil
            }
        }
    }

    private func sendInviteText() {
        guard preferredHandyman != nil, providerInviteURL != nil else { return }
        if MessageComposeView.canSend, invitePhoneRecipient != nil {
            showInviteSMSComposer = true
        } else {
            statusToast = "Text invite isn't available on this device."
        }
    }

    private func sendInviteEmail() {
        guard preferredHandyman != nil, providerInviteURL != nil else { return }
        if MailComposeView.canSend, preferredHandyman?.email?.isEmpty == false {
            showInviteMailComposer = true
        } else {
            statusToast = "Email invite isn't available on this device."
        }
    }

    private func claim(_ child: MaintenanceTaskDBRow) async {
        Haptics.light()
        _ = try? await HandymanVisitService.reassignChild(
            taskId: child.id,
            toRoute: "diy",
            task: child
        )
        await load()
    }

    private func unclaim(_ child: MaintenanceTaskDBRow) async {
        Haptics.light()
        _ = try? await HandymanVisitService.reassignChild(
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

    private func openMicrosite() async {
        guard preferredHandyman != nil else { return }
        isPreparingMicrosite = true
        defer { isPreparingMicrosite = false }

        do {
            let session = try await HandymanVisitService.ensurePortalSession(
                parentTask: activeParentTask,
                property: property,
                systems: systems,
                checklistTasks: whatsIncludedChildren,
                diyClaims: diyClaimedChildren,
                punchItems: punchItems,
                upsellCandidates: upsellCandidates,
                preferredHandyman: preferredHandyman
            )
            portalSession = session
            if let url = HandymanVisitService.portalURL(for: session.portalToken, visitId: activeParentTask.id) {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
                statusToast = "Microsite ready"
            }
        } catch {
            statusToast = "Couldn't prepare microsite"
        }
    }

    private func regenerateMicrosite() async {
        guard preferredHandyman != nil else { return }
        isPreparingMicrosite = true
        defer { isPreparingMicrosite = false }

        do {
            let session = try await HandymanVisitService.ensurePortalSession(
                parentTask: activeParentTask,
                property: property,
                systems: systems,
                checklistTasks: whatsIncludedChildren,
                diyClaims: diyClaimedChildren,
                punchItems: punchItems,
                upsellCandidates: upsellCandidates,
                preferredHandyman: preferredHandyman,
                rotateAccessToken: true
            )
            portalSession = session
            if let url = HandymanVisitService.portalURL(for: session.portalToken, visitId: activeParentTask.id) {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
                statusToast = "Microsite link refreshed"
            }
        } catch {
            statusToast = "Couldn't refresh microsite"
        }
    }

    private func complete() async {
        Haptics.success()
        try? await HandymanVisitService.completeVisit(parent: activeParentTask)
        statusToast = "Visit complete"
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        onDismiss?()
        dismiss()
    }

    private func skip() async {
        Haptics.medium()
        try? await HandymanVisitService.skipVisit(parent: activeParentTask)
        statusToast = "Visit skipped"
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        onDismiss?()
        dismiss()
    }
}

struct HandymanRequestComposerSheet: View {
    let householdId: UUID
    let propertyId: UUID?
    let contractor: ContractorRow?
    let visitTaskId: UUID?
    let initialKind: HandymanRequestKind
    let defaultFirstVisitSetup: Bool
    let quickUpsellTitles: [String]
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedKind: HandymanRequestKind
    @State private var title: String
    @State private var details = ""
    @State private var preferredTiming = ""
    @State private var urgency = "routine"
    @State private var firstVisitSetupRequested: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        householdId: UUID,
        propertyId: UUID?,
        contractor: ContractorRow?,
        visitTaskId: UUID?,
        initialKind: HandymanRequestKind,
        defaultFirstVisitSetup: Bool,
        quickUpsellTitles: [String],
        onSaved: @escaping () -> Void
    ) {
        self.householdId = householdId
        self.propertyId = propertyId
        self.contractor = contractor
        self.visitTaskId = visitTaskId
        self.initialKind = initialKind
        self.defaultFirstVisitSetup = defaultFirstVisitSetup
        self.quickUpsellTitles = quickUpsellTitles
        self.onSaved = onSaved
        _selectedKind = State(initialValue: initialKind)
        _title = State(initialValue: initialKind.defaultTitle)
        _firstVisitSetupRequested = State(initialValue: defaultFirstVisitSetup || initialKind == .setup)
    }

    var body: some View {
        Form {
            Section {
                Picker("Request type", selection: $selectedKind) {
                    ForEach(HandymanRequestKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .onChange(of: selectedKind) { _, newValue in
                    if title == initialKind.defaultTitle || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        title = newValue.defaultTitle
                    }
                    if newValue == .setup {
                        firstVisitSetupRequested = true
                    }
                }

                Text(selectedKind.helperText)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            Section("Request") {
                TextField("Title", text: $title)
                TextField("What should the handyman know?", text: $details, axis: .vertical)
                    .lineLimit(3...8)
                TextField("Preferred timing (optional)", text: $preferredTiming)
            }

            Section("Priority") {
                Picker("Urgency", selection: $urgency) {
                    Text("Routine").tag("routine")
                    Text("Soon").tag("soon")
                    Text("Urgent").tag("urgent")
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle("Ask the handyman to help finish house setup on this visit", isOn: $firstVisitSetupRequested)
                    .tint(HavenColors.action)
                if let contractor {
                    Text("This request will be linked to \(contractor.companyName).")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    Text("No preferred handyman yet. Chez can still save the request so it’s ready when you pick one.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }

            if !quickUpsellTitles.isEmpty {
                Section("Quick upsells already on Chez’s radar") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickUpsellTitles, id: \.self) { title in
                                Text(title)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(HavenColors.beige200)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }
            }
        }
        .navigationTitle("New handyman request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(HavenColors.textPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Send")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(HavenColors.textPrimary)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        var insert = HandymanRequestInsert(
            householdId: householdId,
            requestType: selectedKind.rawValue,
            title: trimmedTitle
        )
        insert.propertyId = propertyId
        insert.contractorId = contractor?.id
        insert.visitTaskId = visitTaskId
        insert.createdByUserId = await HavenSupabase.safeSession(timeout: 1.0)?.user.id
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        insert.details = trimmedDetails.isEmpty ? nil : trimmedDetails
        let trimmedTiming = preferredTiming.trimmingCharacters(in: .whitespacesAndNewlines)
        insert.preferredTiming = trimmedTiming.isEmpty ? nil : trimmedTiming
        insert.urgency = urgency
        insert.firstVisitSetupRequested = firstVisitSetupRequested
        insert.recommendedLane = selectedKind.recommendedLane
        insert.quickUpsellTitles = quickUpsellTitles

        do {
            _ = try await DatabaseService.shared.createHandymanRequest(insert)
            Haptics.success()
            onSaved()
            dismiss()
        } catch {
            Haptics.error()
            errorMessage = "Couldn't save the request right now."
        }
    }
}

struct HandymanRequestMessageComposerSheet: View {
    let request: HandymanRequestRow
    let navigationTitle: String
    let introText: String?
    let placeholder: String
    let defaultStatusOnReply: HandymanRequestStatus?
    let metadataEvent: String
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var messageBody = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var bodyView: some View {
        Form {
            Section {
                Text(introText ?? request.typedStatus.homeownerSummary)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            Section("Message") {
                TextField(placeholder, text: $messageBody, axis: .vertical)
                    .lineLimit(4...10)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(HavenColors.textPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Send")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(HavenColors.textPrimary)
                .disabled(messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
    }

    var body: some View {
        bodyView
    }

    private func save() async {
        let trimmed = messageBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            _ = try await DatabaseService.shared.createHandymanRequestMessage(
                HandymanRequestMessageInsert(
                    requestId: request.id,
                    householdId: request.householdId,
                    senderRole: "homeowner",
                    body: trimmed,
                    metadata: [
                        "event": metadataEvent
                    ]
                )
            )

            if let defaultStatusOnReply {
                var update = HandymanRequestUpdate()
                update.status = defaultStatusOnReply.rawValue
                _ = try? await DatabaseService.shared.updateHandymanRequest(id: request.id, update)
            }

            Haptics.success()
            onSaved()
            dismiss()
        } catch {
            Haptics.error()
            errorMessage = "Couldn't send the message right now."
        }
    }
}

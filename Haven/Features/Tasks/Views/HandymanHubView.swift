import SwiftUI

/// Chez v1: Fully built-out Handyman page. Single source of truth that
/// consolidates three previously-scattered surfaces:
///   - HandymanPunchListView (was pushed from Property → Maintenance)
///   - HandymanSuggestionCard (was on Dashboard)
///   - MaintenanceHubView "Next Handyman Visit" section
///
/// Sections render in order:
///   1. Hero — linked handyman or "Find a handyman" CTA
///   2. Visit coordination — when a visit is scheduled (date, items,
///      message + portal-link affordances, full-detail link)
///   3. Punch list — pending items + inline add + "schedule visit"
///   4. Recommended — handyman-eligible tasks the curator has earmarked
///      that aren't already on the punch list (one-tap add)
///   5. Find-a-handyman discovery — when no handyman linked
///   6. Field-app handoff — Chez Field card when linked + visit scheduled
///   7. Visit history — completed visits with the linked handyman
struct HandymanHubView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var maintenanceVM = MaintenanceViewModel.shared
    @StateObject private var punchListVM = HandymanPunchListViewModel()

    @State private var showScheduleVisit = false
    @State private var showFindHandyman = false
    @State private var showFullPunchList = false
    @State private var showAddPunchItem = false
    @State private var visitDetailTask: MaintenanceTaskDBRow?
    @State private var showMessageComposer = false
    @State private var messageBody: String = ""
    @State private var messageRecipients: [String] = []
    @State private var addingTaskId: UUID?
    /// Tap-thru from FindLocalVendorSheet's "Add my own instead" button —
    /// that sheet posts `.openManualContractorAdd` and dismisses, and we
    /// catch the notification here to open the manual add form. Without
    /// this, the dismiss reads as a cancellation because no listener
    /// was wired in the Tasks tab (only MaintenanceScheduleView listens).
    @State private var showManualHandymanAdd = false

    // Phase 73 follow-up: load the coordination state for the next
    // scheduled visit so the Handyman tab can surface scheduling
    // status, chat preview, and quote total inline — without making
    // the user open the detail sheet for everything. The detail sheet
    // is still where Accept / Counter / Sign / Decline actions live.
    @State private var coordinationRequest: HandymanRequestRow?
    @State private var coordinationMessages: [HandymanRequestMessageRow] = []
    @State private var coordinationQuote: ProviderQuoteRow?
    @State private var coordinationLoadedForTaskId: UUID?

    private var householdId: UUID? {
        maintenanceVM.properties.first?.householdId ?? appState.primaryProperty?.householdId
    }

    private var propertyId: UUID? {
        appState.primaryProperty?.id ?? maintenanceVM.properties.first?.id
    }

    private var linkedHandyman: ContractorRow? {
        maintenanceVM.preferredHandyman ?? maintenanceVM.contractors.first {
            $0.category?.caseInsensitiveCompare("Handyman") == .orderedSame
        }
    }

    private var nextScheduledVisit: MaintenanceTaskDBRow? {
        guard let handyman = linkedHandyman else { return nil }
        let candidates = maintenanceVM.tasks.filter { task in
            task.assignedContractorId == handyman.id &&
            task.lastCompletedDate == nil &&
            (task.isArchived ?? false) == false
        }
        return candidates.min { lhs, rhs in
            let l = MaintenanceDateFormatting.date(from: lhs.scheduledDate ?? lhs.nextDueDate) ?? .distantFuture
            let r = MaintenanceDateFormatting.date(from: rhs.scheduledDate ?? rhs.nextDueDate) ?? .distantFuture
            return l < r
        }
    }

    private var pastVisits: [MaintenanceTaskDBRow] {
        guard let handyman = linkedHandyman else { return [] }
        return maintenanceVM.tasks
            .filter { $0.assignedContractorId == handyman.id && $0.lastCompletedDate != nil }
            .sorted { lhs, rhs in
                let l = MaintenanceDateFormatting.date(from: lhs.lastCompletedDate ?? "") ?? .distantPast
                let r = MaintenanceDateFormatting.date(from: rhs.lastCompletedDate ?? "") ?? .distantPast
                return l > r
            }
    }

    /// Tasks the household already has that fit a handyman visit:
    ///   - non-vendor assignment (personal or either)
    ///   - not archived, not completed, no contractor assigned
    ///   - not already on the punch list (dedup by `sourceTaskId`)
    /// Day1TaskCurator (Phase 66) tags handyman-eligible tasks with
    /// `assignedRoute == "handyman"`; we surface those first, then fall
    /// back to any DIY tasks without a vendor.
    private var recommendedTasks: [MaintenanceTaskDBRow] {
        // Chez v1: dedup recommended tasks against the unified entries
        // list — covers both manual punch_items (sourceTaskId on the
        // punch_item) AND routine-parented task entries (whose id ==
        // sourceTaskId per HandymanPunchEntry.task case).
        let punchListSourceIds = Set(punchListVM.entries.compactMap { $0.sourceTaskId })
        let candidates = maintenanceVM.tasks.filter { task in
            guard !punchListSourceIds.contains(task.id) else { return false }
            guard task.lastCompletedDate == nil else { return false }
            guard !(task.isArchived ?? false) else { return false }
            guard task.assignedContractorId == nil else { return false }
            return (task.assignmentType ?? "either") != "vendor"
        }

        // Sort: handyman-routed first, then by due date.
        return candidates.sorted { lhs, rhs in
            let lhsRouted = lhs.assignedRoute == "handyman"
            let rhsRouted = rhs.assignedRoute == "handyman"
            if lhsRouted != rhsRouted { return lhsRouted }
            let lhsDate = MaintenanceDateFormatting.date(from: lhs.scheduledDate ?? lhs.nextDueDate) ?? .distantFuture
            let rhsDate = MaintenanceDateFormatting.date(from: rhs.scheduledDate ?? rhs.nextDueDate) ?? .distantFuture
            return lhsDate < rhsDate
        }
        .prefix(5)
        .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing16) {
                heroSection

                if nextScheduledVisit != nil {
                    visitCoordinationSection
                }

                punchListSection

                // Recommended is always visible — falls back to a curated
                // list of common handyman items when the household has no
                // routed eligible tasks yet, so first-time users still see
                // value-protecting suggestions.
                recommendedSection

                whatHandymenHandleTipCard

                // Note: the top hero already carries the "Find a handyman"
                // CTA when no handyman is linked, and morphs into the
                // linked-vendor card once one is added. A separate "Find
                // a Pro" section here would be a duplicate front door.

                if nextScheduledVisit != nil, linkedHandyman != nil {
                    fieldAppHandoffSection
                }

                visitHistorySection
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing12)
            .padding(.bottom, HavenTheme.spacing48)
        }
        .background(HavenColors.background)
        .navigationTitle("Contractor")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let hid = householdId {
                await punchListVM.load(householdId: hid, propertyId: propertyId)
            }
        }
        .refreshable {
            // Pull-to-refresh reloads BOTH the punch list and the
            // global maintenance cache. Without the maintenance reload
            // a freshly scheduled visit (created from this same view)
            // won't surface in `nextScheduledVisit` until the user
            // backgrounds + reopens the app.
            if let hid = householdId {
                await punchListVM.load(householdId: hid, propertyId: propertyId)
            }
            await maintenanceVM.loadTasks()
        }
        .task {
            // Same reload on appear — defensive against the case
            // where a visit was created from a different surface and
            // the user navigates here. The pre-existing
            // `.maintenanceTaskChanged` listener handles the same
            // scenario but races view re-renders; the explicit task
            // closes that gap.
            if let hid = householdId {
                await punchListVM.load(householdId: hid, propertyId: propertyId)
            }
            await maintenanceVM.loadTasks()
        }
        .sheet(isPresented: $showScheduleVisit) {
            if let hid = householdId {
                ScheduleHandymanVisitSheet(
                    itemCount: punchListVM.entries.count,
                    householdId: hid,
                    propertyId: propertyId,
                    onSchedule: { date, contractor in
                        Task {
                            await punchListVM.scheduleAdHocVisit(
                                householdId: hid,
                                propertyId: propertyId,
                                scheduledDate: date,
                                contractor: contractor
                            )
                            Haptics.success()
                        }
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showFindHandyman) {
            if let hid = householdId {
                FindLocalVendorSheet(
                    task: nil,
                    householdId: hid,
                    town: appState.primaryProperty?.city ?? "",
                    state: appState.primaryProperty?.state ?? "",
                    systemCategory: "Handyman",
                    categoryDisplayName: "Handyman",
                    onComplete: {
                        Task { await maintenanceVM.loadTasks() }
                    }
                )
            }
        }
        .sheet(isPresented: $showFullPunchList) {
            if let hid = householdId {
                NavigationStack {
                    HandymanPunchListView(householdId: hid, propertyId: propertyId)
                }
            }
        }
        .sheet(isPresented: $showAddPunchItem) {
            if let hid = householdId {
                NavigationStack {
                    AddHandymanPunchItemSheet(
                        householdId: hid,
                        propertyId: propertyId,
                        onAdded: {
                            Task { await punchListVM.load(householdId: hid, propertyId: propertyId) }
                        }
                    )
                }
            }
        }
        .sheet(item: $punchListVM.justScheduledTask) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(
                    task: task,
                    onDeleteTask: {
                        let taskId = task.id
                        Task {
                            try? await DatabaseService.shared.deleteMaintenanceTask(id: taskId)
                            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                        }
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $visitDetailTask) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(
                    task: task,
                    onDeleteTask: {
                        let taskId = task.id
                        Task {
                            try? await DatabaseService.shared.deleteMaintenanceTask(id: taskId)
                            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                        }
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showMessageComposer) {
            MessageComposeView(
                recipients: messageRecipients,
                body: messageBody,
                onFinish: { _ in }
            )
        }
        .sheet(isPresented: $showManualHandymanAdd) {
            NavigationStack {
                AddVendorSheet(
                    onComplete: {
                        Task { await maintenanceVM.loadTasks() }
                        NotificationCenter.default.post(name: .contractorAdded, object: nil)
                    },
                    prefilledCategory: "Handyman"
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openManualContractorAdd)) { _ in
            // Defer one runloop tick so FindLocalVendorSheet's dismiss
            // animation completes before we present the next sheet on top
            // of the same hierarchy. Without the delay SwiftUI silently
            // collapses the second presentation.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showManualHandymanAdd = true
            }
        }
        .trackScreen("HandymanHubView")
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        if let handyman = linkedHandyman {
            linkedHandymanHero(handyman)
        } else {
            unlinkedHandymanHero
        }
    }

    private func linkedHandymanHero(_ handyman: ContractorRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: HavenTheme.spacing12) {
                    VendorLogoView(contractor: handyman, size: 48)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your contractor")
                            .font(HavenTypography.uiSectionHeader)
                            .foregroundStyle(HavenColors.textSoft)
                        Text(handyman.companyName)
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                    }
                    Spacer()

                    let trimmedPhone = handyman.phone.filter { $0.isNumber || $0 == "+" }
                    if !trimmedPhone.isEmpty,
                       let url = URL(string: "tel://\(trimmedPhone)") {
                        Link(destination: url) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(HavenColors.navy)
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                        .stroke(HavenColors.beige300, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }

    private var unlinkedHandymanHero: some View {
        HavenCard(style: .decision) {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: HavenTheme.spacing12) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(HavenColors.action)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                .fill(HavenColors.actionPale)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No contractor yet")
                            .font(HavenTypography.title3)
                        Text("Find a vetted local pro you trust.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                }

                HavenButton(
                    title: "Find a contractor",
                    action: {
                        Haptics.medium()
                        showFindHandyman = true
                    },
                    icon: "magnifyingglass",
                    isFullWidth: true
                )
            }
        }
    }

    // MARK: - Visit coordination (when a visit is scheduled)

    @ViewBuilder
    private var visitCoordinationSection: some View {
        if let visit = nextScheduledVisit {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("NEXT VISIT")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSoft)

                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        visitCoordinationHeader(for: visit)

                        if let request = coordinationRequest, request.hasOpenProposal {
                            visitProposalRow(request: request)
                        }

                        if !coordinationMessages.isEmpty {
                            visitChatPreviewRow
                        }

                        if let quote = coordinationQuote {
                            visitQuotePreviewRow(quote)
                        }

                        visitCoordinationActions(for: visit)
                    }
                }
            }
            .task(id: visit.id) {
                await loadVisitCoordinationState(for: visit)
            }
            .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
                Task { await loadVisitCoordinationState(for: visit) }
            }
        }
    }

    private func visitCoordinationHeader(for visit: MaintenanceTaskDBRow) -> some View {
        HStack(spacing: HavenTheme.spacing8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HavenColors.action)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .fill(HavenColors.actionPale)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(visitDateLabel(for: visit))
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(visitStatusSubtitle)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            if let label = visitStatusPillLabel {
                HavenPill(
                    label: label,
                    tone: visitStatusPillTone,
                    showsDot: false
                )
            }
        }
    }

    private func visitProposalRow(request: HandymanRequestRow) -> some View {
        let provider = linkedHandyman?.companyName ?? "Provider"
        let proposer = request.proposedByActor ?? .handyman
        let label: String = {
            if let proposed = request.proposedVisitAt {
                if proposer == .handyman {
                    return "\(provider) proposed \(Self.proposalFormatter.string(from: proposed))"
                }
                return "You proposed \(Self.proposalFormatter.string(from: proposed))"
            }
            return "Awaiting confirmation"
        }()

        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.action)
                .padding(.top, 1)
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(HavenTheme.spacing8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.action.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var visitChatPreviewRow: some View {
        let recent = coordinationMessages.suffix(2)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(HavenColors.navy500)
                Text("RECENT MESSAGES")
                    .font(HavenTypography.uiCaption.weight(.semibold))
                    .foregroundStyle(HavenColors.textTertiary)
                    .tracking(1.2)
            }
            ForEach(Array(recent), id: \.id) { message in
                let sender = senderDisplayLabel(for: message.senderRole)
                Text("\(sender): \(message.body)")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(HavenTheme.spacing8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private func visitQuotePreviewRow(_ quote: ProviderQuoteRow) -> some View {
        let amount = quote.total.formatted(.currency(code: quote.currency))
        let icon: String = {
            switch quote.typedStatus {
            case .approved: return "checkmark.seal.fill"
            case .counteredByHomeowner: return "arrow.left.arrow.right"
            case .declined, .superseded: return "xmark.octagon.fill"
            default: return "doc.text.fill"
            }
        }()
        let tint: Color = {
            switch quote.typedStatus {
            case .approved: return HavenColors.success
            case .declined, .superseded: return HavenColors.critical
            case .counteredByHomeowner: return HavenColors.action
            default: return HavenColors.navy500
            }
        }()

        return HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Quote · \(amount)")
                    .font(HavenTypography.uiLabel.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                Text(quote.typedStatus.displayLabel)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
        .padding(HavenTheme.spacing8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private func visitCoordinationActions(for visit: MaintenanceTaskDBRow) -> some View {
        HStack(spacing: HavenTheme.spacing8) {
            HavenButton(
                title: "Open visit",
                action: {
                    Haptics.light()
                    visitDetailTask = visit
                },
                style: .primary,
                size: .compact,
                icon: "calendar.badge.clock",
                isFullWidth: true
            )

            if let handyman = linkedHandyman,
               !handyman.phone.isEmpty {
                HavenButton(
                    title: "Text",
                    action: { sendVisitMessage(for: visit, to: handyman) },
                    style: .secondary,
                    size: .compact,
                    icon: "message.fill",
                    isFullWidth: true
                )
            }
        }
    }

    private func visitDateLabel(for visit: MaintenanceTaskDBRow) -> String {
        if let confirmed = coordinationRequest?.confirmedVisitAt {
            return "Confirmed for \(Self.proposalFormatter.string(from: confirmed))"
        }
        if let proposed = coordinationRequest?.proposedVisitAt,
           coordinationRequest?.confirmedVisitAt == nil {
            return Self.proposalFormatter.string(from: proposed)
        }
        return MaintenanceDateFormatting.dueLabel(for: visit.scheduledDate ?? visit.nextDueDate)
    }

    private var visitStatusSubtitle: String {
        guard let request = coordinationRequest else {
            return nextScheduledVisit?.title ?? "Visit"
        }
        if request.confirmedVisitAt != nil {
            let item = punchListVM.entries.count
            if item > 0 {
                return "\(item) item\(item == 1 ? "" : "s") in this visit"
            }
            return "Visit confirmed"
        }
        if request.hasOpenProposal {
            return "Tap Open visit to accept or counter"
        }
        return nextScheduledVisit?.title ?? "Visit"
    }

    private var visitStatusPillLabel: String? {
        guard let request = coordinationRequest else { return nil }
        return request.typedStatus.displayLabel
    }

    private var visitStatusPillTone: HavenPill.Tone {
        guard let request = coordinationRequest else { return .indigo }
        switch request.typedStatus {
        case .confirmed, .completed:
            return .success
        case .alternateDatesProposed, .awaitingHomeowner, .followUpRecommended:
            return .warning
        case .quoted:
            return .info
        case .cancelled, .declined:
            return .critical
        default:
            return .indigo
        }
    }

    private func senderDisplayLabel(for role: String) -> String {
        switch role.lowercased() {
        case "homeowner": return "You"
        case "vendor": return linkedHandyman?.companyName ?? "Provider"
        case "haven": return "Chez"
        default: return role.capitalized
        }
    }

    private static let proposalFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d 'at' h:mm a"
        return f
    }()

    /// Loads the coordination request, recent chat messages, and the
    /// latest active quote for the visit. Idempotent — re-runs on visit
    /// id change and on `.maintenanceTaskChanged` so the card refreshes
    /// after Schedule/Open visit/etc. interactions.
    private func loadVisitCoordinationState(for visit: MaintenanceTaskDBRow) async {
        let db = DatabaseService.shared
        let request = (try? await db.fetchLatestHandymanRequest(visitTaskId: visit.id))
        coordinationRequest = request

        if let request {
            let messages = (try? await db.fetchHandymanRequestMessages(requestId: request.id)) ?? []
            coordinationMessages = messages
            let quotes = (try? await db.fetchProviderQuotes(requestId: request.id)) ?? []
            // Skip superseded/withdrawn — they'd otherwise show as the
            // "latest" because the table sorts by updated_at DESC.
            coordinationQuote = quotes.first { quote in
                let status = quote.typedStatus
                return status != .superseded && status != .withdrawn
            }
        } else {
            coordinationMessages = []
            coordinationQuote = nil
        }
        coordinationLoadedForTaskId = visit.id
    }

    private func sendVisitMessage(for visit: MaintenanceTaskDBRow, to handyman: ContractorRow) {
        let date = MaintenanceDateFormatting.dueLabel(for: visit.scheduledDate ?? visit.nextDueDate)
        let preview = punchListVM.entries.prefix(5).map { "• \($0.title)" }.joined(separator: "\n")
        let extra = punchListVM.entries.count > 5 ? "\n…and \(punchListVM.entries.count - 5) more" : ""
        messageBody = """
        Hi — confirming our visit \(date).

        Punch list:
        \(preview)\(extra)

        Thanks!
        """
        messageRecipients = [handyman.phone]
        Haptics.medium()
        showMessageComposer = true
    }

    // MARK: - Punch list

    private var punchListSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text("PUNCH LIST")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSoft)
                Spacer()
                if !punchListVM.entries.isEmpty {
                    Button("View all") {
                        Haptics.light()
                        showFullPunchList = true
                    }
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.navy500)
                }
            }

            if punchListVM.entries.isEmpty {
                emptyPunchListCard
            } else {
                punchListPreview
            }
        }
    }

    private var emptyPunchListCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("Anything been bugging you?")
                    .font(HavenTypography.headline)
                Text("Add small repairs, dryer-vent cleaning, a squeaky door. We'll hand the whole list to your contractor on the next visit.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                HavenButton(
                    title: "Add your first item",
                    action: {
                        Haptics.light()
                        showAddPunchItem = true
                    },
                    icon: "plus",
                    isFullWidth: true
                )
            }
        }
    }

    private var punchListPreview: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                ForEach(punchListVM.entries.prefix(4)) { entry in
                    HStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(HavenColors.textSoft)
                        Text(entry.title)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        if let mins = entry.estimatedMinutes {
                            Text("\(mins) min")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSoft)
                        }
                    }
                }

                if punchListVM.entries.count > 4 {
                    Text("+ \(punchListVM.entries.count - 4) more")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSoft)
                        .padding(.top, 2)
                }

                Divider()
                    .padding(.vertical, 4)

                HStack(spacing: HavenTheme.spacing8) {
                    HavenButton(
                        title: "Add item",
                        action: {
                            Haptics.light()
                            showAddPunchItem = true
                        },
                        style: .secondary,
                        size: .compact,
                        icon: "plus",
                        isFullWidth: true
                    )
                    HavenButton(
                        title: nextScheduledVisit == nil ? "Schedule visit" : "Reschedule",
                        action: {
                            Haptics.medium()
                            showScheduleVisit = true
                        },
                        size: .compact,
                        isFullWidth: true
                    )
                }
            }
        }
    }

    // MARK: - Recommended punch items

    /// Curated handyman items shown when the household has no routed
    /// eligible tasks (fresh property, pre-quiz, etc.). These are the
    /// small jobs that protect home value across most properties — the
    /// list a thoughtful handyman would suggest at a first visit.
    private struct CuratedHandymanIdea: Identifiable {
        let id: String
        let title: String
        let estimatedMinutes: Int

        static let common: [CuratedHandymanIdea] = [
            .init(id: "weatherstripping", title: "Inspect weatherstripping on exterior doors", estimatedMinutes: 15),
            .init(id: "caulk_baths", title: "Re-caulk bath and shower seams", estimatedMinutes: 45),
            .init(id: "smoke_co", title: "Test smoke + CO detectors and replace batteries", estimatedMinutes: 20),
            .init(id: "door_hinges", title: "Lubricate squeaky door hinges", estimatedMinutes: 15),
            .init(id: "exterior_paint", title: "Touch up exterior paint chips", estimatedMinutes: 60),
            .init(id: "gutter_walk", title: "Walk + clear gutters and downspouts", estimatedMinutes: 60),
            .init(id: "leak_walk", title: "Walk attic + foundation for leaks", estimatedMinutes: 30),
        ]
    }

    /// Filters the curated ideas down to ones not already on the punch
    /// list (matched by title, case-insensitive). Caps at 5 visible
    /// rows so the section doesn't overwhelm the page. Chez v1: matches
    /// against the unified `entries` so curated ideas don't duplicate
    /// titles that came from routine-parented maintenance tasks.
    private var visibleCuratedIdeas: [CuratedHandymanIdea] {
        let existing = Set(punchListVM.entries.map { $0.title.lowercased() })
        return CuratedHandymanIdea.common
            .filter { !existing.contains($0.title.lowercased()) }
            .prefix(5)
            .map { $0 }
    }

    @ViewBuilder
    private var recommendedSection: some View {
        let routedTasks = recommendedTasks
        // If the household has zero routed handyman-eligible tasks AND
        // every curated idea is already on the list, hide the whole
        // section — there's nothing to suggest.
        if !routedTasks.isEmpty || !visibleCuratedIdeas.isEmpty {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack {
                    Text("RECOMMENDED")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textSoft)
                    Spacer()
                    Text(routedTasks.isEmpty ? "Common starting points" : "Could fold into a visit")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSoft)
                }

                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(routedTasks) { task in
                        recommendedRow(task)
                    }
                    if routedTasks.isEmpty {
                        // Pure-curated mode for fresh properties — looks
                        // identical to the routed-task rows so the user
                        // can't tell the difference, just gets value.
                        ForEach(visibleCuratedIdeas) { idea in
                            curatedRecommendedRow(idea)
                        }
                    }
                }
            }
        }
    }

    private func recommendedRow(_ task: MaintenanceTaskDBRow) -> some View {
        let isAdding = addingTaskId == task.id
        return HavenCard(padding: HavenTheme.spacing12) {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(HavenColors.action)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusSmall)
                            .fill(HavenColors.actionPale)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                    if let due = MaintenanceDateFormatting.date(from: task.scheduledDate ?? task.nextDueDate) {
                        Text(due.formatted(.relative(presentation: .named)))
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSoft)
                    }
                }
                Spacer()

                Button {
                    addRecommendedToPunchList(task)
                } label: {
                    if isAdding {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(HavenColors.action)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isAdding)
            }
        }
    }

    private func curatedRecommendedRow(_ idea: CuratedHandymanIdea) -> some View {
        let isAdding = addingTaskId?.uuidString == idea.id
        return HavenCard(padding: HavenTheme.spacing12) {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(HavenColors.action)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusSmall)
                            .fill(HavenColors.actionPale)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(idea.title)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                    Text("\(idea.estimatedMinutes) min")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSoft)
                }
                Spacer()

                Button {
                    addCuratedIdeaToPunchList(idea)
                } label: {
                    if isAdding {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(HavenColors.action)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isAdding)
            }
        }
    }

    private func addCuratedIdeaToPunchList(_ idea: CuratedHandymanIdea) {
        guard let hid = householdId else { return }
        Haptics.light()
        Task {
            var insert = HandymanPunchItemInsert(
                householdId: hid,
                propertyId: propertyId,
                title: idea.title
            )
            insert.source = "recommended"
            insert.estimatedMinutes = idea.estimatedMinutes
            do {
                _ = try await DatabaseService.shared.createHandymanPunchItem(insert)
                Haptics.success()
                await punchListVM.load(householdId: hid, propertyId: propertyId)
            } catch {
                Haptics.error()
            }
        }
    }

    // MARK: - What handymen handle tip card

    /// Educational tip card that anchors the lane: shows homeowners the
    /// kind of work a good handyman absorbs so they don't try to bundle
    /// the wrong things (specialty trades) into a visit, or skip the
    /// lane entirely thinking they don't need one.
    private var whatHandymenHandleTipCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("WHAT HANDYMEN HANDLE")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSoft)

            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: "lightbulb.max.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(HavenColors.navy)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .fill(HavenColors.indigo50)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Small jobs that protect value")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Bundle them into a single visit.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        whatHandymenRow(icon: "scribble", label: "Caulking + grout touch-ups")
                        whatHandymenRow(icon: "wrench.adjustable.fill", label: "Door + cabinet alignment")
                        whatHandymenRow(icon: "sensor", label: "Filter, battery, weatherstrip swaps")
                        whatHandymenRow(icon: "paintbrush.fill", label: "Drywall + paint touch-ups")
                        whatHandymenRow(icon: "lightbulb.fill", label: "Mounting, hanging, fixture installs")
                        whatHandymenRow(icon: "leaf.fill", label: "Gutter, attic, exterior walk-downs")
                    }
                }
            }
        }
    }

    private func whatHandymenRow(icon: String, label: String) -> some View {
        HStack(spacing: HavenTheme.spacing8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(HavenColors.navy500)
                .frame(width: 18)
            Text(label)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer(minLength: 0)
        }
    }

    private func addRecommendedToPunchList(_ task: MaintenanceTaskDBRow) {
        guard let hid = householdId, addingTaskId == nil else { return }
        addingTaskId = task.id
        Haptics.light()
        Task {
            var insert = HandymanPunchItemInsert(
                householdId: hid,
                propertyId: propertyId ?? task.propertyId,
                title: task.title
            )
            insert.source = "recommended"
            insert.sourceTaskId = task.id
            insert.maintenanceTaskId = task.id
            do {
                _ = try await DatabaseService.shared.createHandymanPunchItem(insert)
                Haptics.success()
                await punchListVM.load(householdId: hid, propertyId: propertyId)
            } catch {
                Haptics.error()
            }
            addingTaskId = nil
        }
    }

    // MARK: - Field-app handoff

    private var fieldAppHandoffSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("FOR YOUR HANDYMAN")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSoft)

            HavenCard(style: .hero) {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    HStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 18))
                        Text("Chez Field")
                            .font(HavenTypography.title3)
                        Spacer()
                        HavenPill(label: "Companion app", tone: .salmon, showsDot: false)
                    }
                    Text("Your contractor can use the Chez Field app to see your punch list, system details, and visit notes before they arrive.")
                        .font(HavenTypography.bodySmall)
                        .opacity(0.85)
                }
            }
        }
    }

    // MARK: - Visit history

    private var visitHistorySection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("VISIT HISTORY")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSoft)

            if pastVisits.isEmpty {
                HavenCard {
                    Text(linkedHandyman == nil
                         ? "Visit history will appear here after your first scheduled visit is completed."
                         : "No completed visits yet. Once your contractor finishes a visit it shows up here.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            } else {
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(pastVisits.prefix(5)) { visit in
                        visitHistoryRow(visit)
                    }
                }
            }
        }
    }

    private func visitHistoryRow(_ task: MaintenanceTaskDBRow) -> some View {
        let label = task.lastCompletedDate.map { MaintenanceDateFormatting.dueLabel(for: $0) }
        return HavenCard(padding: HavenTheme.spacing12) {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                    if let label {
                        Text(label)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSoft)
                    }
                }
                Spacer()
            }
        }
    }
}

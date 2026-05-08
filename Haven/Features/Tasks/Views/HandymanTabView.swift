import SwiftUI
import Supabase

/// V5 Handyman screen — focused punch-list-and-vendor surface that lives
/// behind the title-switcher in `TasksHubView`.
///
/// A handyman visit is a PARENT (the scheduled visit) containing CHILD
/// punch-list items the handyman will work through. When an upcoming
/// visit is on the books, the screen reframes around it:
///   • Visit hero shows the date, vendor, and item count from the visit's
///     parsed punch list (children parsed from the task's notes).
///   • Punch list card shows those parsed children (read-only — the
///     handyman owns them).
///   • Tap the hero → opens HandymanVisitDetailSheet (chat, reschedule,
///     full punch list, real-time status).
///
/// When NO visit is scheduled, falls back to the user's accumulating
/// draft punch list (the legacy behavior).
struct HandymanTabView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var maintenanceVM = MaintenanceViewModel.shared
    @StateObject private var punchListVM = HandymanPunchListViewModel()
    @ObservedObject private var coordinator = HandymanRequestCoordinator.shared

    @State private var pendingChecked: Set<String> = []
    @State private var addingRecommendedIds: Set<UUID> = []
    @State private var showAddMenu = false
    @State private var pushTarget: HandymanPush?
    @State private var showFindHandyman = false
    @State private var showScheduleSheet = false
    @State private var presentedVisit: MaintenanceTaskDBRow? = nil
    @State private var presentChat = false
    @State private var presentQuote = false

    // Phase 78: proposals inbox state. Pending tasks (handyman flagged
    // a "you need a roofer" item) + pending requests (handyman suggested
    // a follow-up visit) + pending punch items (homeowner added after
    // visit lock). Loaded on appear + refreshed on every relevant
    // notification. `respondingProposalId` tracks the inflight call so
    // the row dims while a decision is being recorded.
    @State private var proposalTasks: [MaintenanceTaskDBRow] = []
    @State private var proposalPunchItems: [HandymanPunchItemRow] = []
    @State private var respondingProposalId: String? = nil
    @State private var proposalErrorMessage: String? = nil

    // Phase 78: structured punch items for the upcoming visit. Replaces
    // the regex-parsed-from-notes path so the canonical handyman surface
    // reads from `handyman_punch_items` (the same table the field app
    // writes to). Falls back to `VisitNotesParser` for legacy visits the
    // backfill missed (notes intact, no structured rows yet).
    @State private var structuredVisitItems: [HandymanPunchItemRow] = []
    @State private var togglingItemIds: Set<UUID> = []

    let onSwitchMode: () -> Void

    private var householdId: UUID? {
        appState.primaryProperty?.householdId ?? maintenanceVM.properties.first?.householdId
    }

    private var propertyId: UUID? {
        appState.primaryProperty?.id ?? maintenanceVM.properties.first?.id
    }

    private var primaryProperty: PropertyRow? {
        appState.primaryProperty ?? maintenanceVM.properties.first
    }

    private var linkedHandyman: ContractorRow? {
        maintenanceVM.preferredHandyman ?? maintenanceVM.contractors.first {
            $0.category?.caseInsensitiveCompare("Handyman") == .orderedSame
        }
    }

    /// All upcoming visits from this handyman, sorted by scheduled date.
    /// A handyman visit is a parent `maintenance_task` row whose notes
    /// contain a punch list (or whose service_key marks it as a
    /// handyman visit). Standalone vendor tasks assigned to the
    /// handyman are intentionally excluded — they belong INSIDE a
    /// visit's punch list, not as siblings to it. Without this filter
    /// every individual punch item rendered as its own "upcoming visit"
    /// row, which made the post-split state unreadable.
    private var upcomingVisits: [MaintenanceTaskDBRow] {
        guard let handyman = linkedHandyman else { return [] }
        return maintenanceVM.tasks
            .filter { task in
                task.assignedContractorId == handyman.id &&
                task.lastCompletedDate == nil &&
                (task.isArchived ?? false) == false &&
                Self.isHandymanVisitParent(task)
            }
            .sorted { lhs, rhs in
                let l = MaintenanceDateFormatting.date(from: lhs.scheduledDate ?? lhs.nextDueDate) ?? .distantFuture
                let r = MaintenanceDateFormatting.date(from: rhs.scheduledDate ?? rhs.nextDueDate) ?? .distantFuture
                return l < r
            }
    }

    /// Distinguishes a parent visit-task from a standalone item. A
    /// parent visit either:
    ///   - has a handyman-visit service_key (field-ad-hoc, visit-split,
    ///     or any handyman:* tag the seeder produces), OR
    ///   - carries a canonical visit-notes header ("Punch list:" /
    ///     "What's included") in its notes
    /// We deliberately don't fall through to "any task with bulleted
    /// notes" — a regular vendor task's AI-generated description can
    /// contain bullets without being a real visit, and we don't want
    /// those leaking into the upcoming-visits list.
    private static func isHandymanVisitParent(_ task: MaintenanceTaskDBRow) -> Bool {
        if let key = task.serviceKey, key.hasPrefix("handyman:") {
            return true
        }
        if let notes = task.notes, !notes.isEmpty {
            let lower = notes.lowercased()
            if lower.contains("punch list:") || lower.contains("what's included") {
                return true
            }
        }
        return false
    }

    /// The soonest upcoming visit. Used for the hero card; the rest
    /// render in the "Also upcoming" rail below.
    private var nextScheduledVisit: MaintenanceTaskDBRow? {
        upcomingVisits.first
    }

    /// Visits beyond the hero — split follow-ups, additional bookings.
    private var additionalUpcomingVisits: [MaintenanceTaskDBRow] {
        Array(upcomingVisits.dropFirst())
    }

    /// Punch list items for the upcoming visit. Phase 78: prefers
    /// structured rows from `handyman_punch_items` (the canonical
    /// source — same table the field app writes to). Falls back to
    /// regex-parsing the visit's notes for legacy visits the Phase 1
    /// backfill missed.
    private var visitChildren: [VisitChildItem] {
        if !structuredVisitItems.isEmpty {
            return structuredVisitItems.map { row in
                VisitChildItem(
                    id: row.id.uuidString,
                    title: row.title,
                    estimatedMinutes: row.estimatedMinutes
                )
            }
        }
        guard let notes = nextScheduledVisit?.notes, !notes.isEmpty else { return [] }
        return VisitNotesParser.parsePunchList(from: notes)
    }

    /// True when the upcoming visit's punch list is backed by
    /// structured rows (vs. the legacy regex-parsed fallback). Drives
    /// whether the punch list section renders interactive checkboxes
    /// or read-only display rows.
    private var hasStructuredVisitItems: Bool {
        !structuredVisitItems.isEmpty
    }

    private var totalPunchCount: Int { punchListVM.entries.count }

    private var extraPunchCount: Int {
        max(totalPunchCount - visiblePunchItems.count - pendingChecked.count, 0)
    }

    /// Visible punch list items (not yet checked in this session).
    /// Only used when no scheduled visit exists.
    private var visiblePunchItems: [PunchListItem] {
        Array(
            punchListVM.entries
                .filter { !pendingChecked.contains($0.id) }
                .prefix(4)
                .map { entry in
                    PunchListItem(
                        id: entry.id,
                        title: entry.title,
                        duration: durationLabel(for: entry),
                        isChecked: false
                    )
                }
        )
    }

    private var recommendedTasks: [MaintenanceTaskDBRow] {
        let punchSourceIds = Set(punchListVM.entries.compactMap { $0.sourceTaskId })
        let visitId = nextScheduledVisit?.id
        let candidates = maintenanceVM.tasks.filter { task in
            guard !punchSourceIds.contains(task.id) else { return false }
            guard task.id != visitId else { return false }                // exclude the visit itself
            guard task.lastCompletedDate == nil else { return false }
            guard !(task.isArchived ?? false) else { return false }
            guard task.assignedContractorId == nil else { return false }
            return (task.assignmentType ?? "either") != "vendor"
        }
        return candidates
            .sorted { lhs, rhs in
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

    private var hasFirstVisitOpportunity: Bool {
        // First-visit prompt: surface when there's an upcoming visit and
        // no past completed visits — i.e. this is the homeowner's first
        // time working with their handyman.
        nextScheduledVisit != nil && pastVisits.isEmpty
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HeaderSwitcher(
                    title: "Contractor",
                    onSwitchMode: onSwitchMode,
                    onAdd: { showAddMenu = true }
                )

                visitHeroSection
                vendorCardSection
                quotesSection

                // Phase 78: pending proposals (handyman-flagged tasks,
                // suggested follow-up visits, after-lock punch items)
                // need explicit homeowner accept/decline. Pin above the
                // punch list so they're impossible to miss.
                proposalsInboxSection

                if hasFirstVisitOpportunity {
                    firstVisitPromptSection
                }

                punchListSection
                recommendedSection

                WhatWeHandleBand()
                    .padding(.horizontal, TasksV5.pageMargin)
                    .padding(.bottom, TasksV5.sectionGap)

                visitHistorySection
                    .padding(.bottom, TasksV5.bottomTabInset)
            }
        }
        .background(HavenColors.background)
        .scrollContentBackground(.hidden)
        .task {
            if let householdId {
                await punchListVM.load(householdId: householdId, propertyId: propertyId)
            }
            await maintenanceVM.loadTasks()
            await reloadCoordination()
            await loadProposals()
            await loadStructuredVisitItems()
        }
        .refreshable {
            if let householdId {
                await punchListVM.load(householdId: householdId, propertyId: propertyId)
            }
            await maintenanceVM.loadTasks()
            await reloadCoordination()
            await loadProposals()
            await loadStructuredVisitItems()
        }
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task {
                if let householdId {
                    await punchListVM.load(householdId: householdId, propertyId: propertyId)
                }
                await maintenanceVM.loadTasks()
                await reloadCoordination()
                await loadProposals()
                await loadStructuredVisitItems()
            }
        }
        // Push notification deep-link arrived. Present the right sheet
        // for the visit referenced by the payload. The sheet defaults
        // to the visit detail; quote-related events jump straight to
        // the quote review sheet.
        .onReceive(NotificationCenter.default.publisher(for: .openHandymanVisit)) { notification in
            Task {
                await maintenanceVM.loadTasks()

                let presentation = notification.userInfo?["presentation"] as? String ?? "visit"
                let quoteIdRaw = notification.userInfo?["quote_id"] as? String
                let quoteId = quoteIdRaw.flatMap(UUID.init(uuidString:))
                let requestIdRaw = notification.userInfo?["request_id"] as? String
                let requestId = requestIdRaw.flatMap { $0.isEmpty ? nil : UUID(uuidString: $0) }

                // Route to the SPECIFIC visit identified by request_id.
                // Without this, a reschedule push for a follow-up
                // visit silently opened the soonest visit instead and
                // the propose_time message never surfaced for the
                // homeowner. When request_id matches a known task,
                // pin that task as the presented visit + switch the
                // coordinator to its request so Realtime + chat
                // load the right thread.
                var routedVisit: MaintenanceTaskDBRow?
                if let rid = requestId {
                    if let req = await coordinator.loadByRequestId(rid),
                       let taskId = req.visitTaskId,
                       let task = maintenanceVM.tasks.first(where: { $0.id == taskId }) {
                        routedVisit = task
                    }
                }
                if routedVisit == nil {
                    await reloadCoordination()
                }

                // Quote deep-link: pin the specific quote by id (push
                // payload carries it from saveQuote) so we don't have
                // to find it via request_id matching — quotes built
                // without a visit linkage would otherwise never load.
                if presentation == "quote", let qid = quoteId {
                    let ok = await coordinator.loadAndPinQuote(quoteId: qid)
                    if ok {
                        await MainActor.run {
                            presentChat = false
                            presentedVisit = nil
                            presentQuote = true
                        }
                        return
                    }
                }

                await MainActor.run {
                    if presentation == "quote" && coordinator.quote != nil {
                        presentChat = false
                        presentedVisit = nil
                        presentQuote = true
                    } else if let visit = routedVisit ?? nextScheduledVisit {
                        presentChat = false
                        presentQuote = false
                        presentedVisit = visit
                    }
                }
            }
        }
        .confirmationDialog("Add", isPresented: $showAddMenu, titleVisibility: .hidden) {
            Button("Add a punch-list item") { pushTarget = .punchListFull }
            Button("Schedule a visit") { showScheduleSheet = true }
            Button("Cancel", role: .cancel) {}
        }
        .navigationDestination(item: $pushTarget) { target in
            destination(for: target)
        }
        .sheet(isPresented: $showFindHandyman) {
            if let householdId {
                FindLocalVendorSheet(
                    task: nil,
                    householdId: householdId,
                    town: primaryProperty?.city ?? "",
                    state: primaryProperty?.state ?? "",
                    systemCategory: "Handyman",
                    categoryDisplayName: "Handyman"
                )
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            if let householdId {
                HandymanPunchListView(householdId: householdId, propertyId: propertyId)
            }
        }
        .sheet(item: $presentedVisit) { visit in
            HandymanVisitDetailSheet(
                visit: visit,
                vendor: linkedHandyman,
                onMessage: {
                    presentedVisit = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        presentChat = true
                    }
                },
                onReviewQuote: {
                    presentedVisit = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        presentQuote = true
                    }
                }
            )
        }
        .sheet(isPresented: $presentChat) {
            HandymanChatSheet(
                visit: nextScheduledVisit,
                vendor: linkedHandyman,
                householdId: householdId,
                propertyId: propertyId
            )
        }
        .sheet(isPresented: $presentQuote) {
            HandymanQuoteReviewSheet(
                vendor: linkedHandyman,
                onMessage: {
                    presentQuote = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        presentChat = true
                    }
                }
            )
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var visitHeroSection: some View {
        if let visit = nextScheduledVisit {
            // Live upcoming-visit hero — replaces the "nothing on the
            // punch list yet" empty state.
            VStack(spacing: 12) {
                Button {
                    Haptics.selection()
                    presentedVisit = visit
                } label: {
                    IndigoGradientCard(variant: .hero) {
                        UpcomingVisitHero(
                            visit: visit,
                            vendor: linkedHandyman,
                            itemCount: visitChildren.count,
                            coordinationRequest: coordinator.request,
                            onSchedule: {
                                Haptics.selection()
                                presentedVisit = visit
                            },
                            onMessage: {
                                Haptics.light()
                                presentChat = true
                            },
                            onCall: handymanCallAction
                        )
                    }
                }
                .buttonStyle(.plain)

                // "Upcoming visits" rail — surfaces every other booked
                // visit from this handyman (e.g. a follow-up created
                // by Split Visit). Without this the homeowner only
                // sees the soonest visit and would never realize the
                // second one exists.
                if !additionalUpcomingVisits.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("UPCOMING VISITS")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.32)
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 8) {
                            ForEach(additionalUpcomingVisits, id: \.id) { extra in
                                Button {
                                    Haptics.selection()
                                    presentedVisit = extra
                                } label: {
                                    AdditionalVisitRow(visit: extra)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, 18)
        } else {
            IndigoGradientCard(variant: .hero) {
                VisitHeroContent(
                    itemCount: totalPunchCount,
                    vendorName: linkedHandyman?.companyName,
                    estimateLabel: estimateLabel,
                    onSchedule: { showScheduleSheet = true },
                    onCall: handymanCallAction
                )
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, 18)
        }
    }

    /// Top-level Quotes section. Single source of truth for active
    /// provider quotes — surfaces every quote (visit-linked or not) so
    /// the homeowner has one consistent entry point into the review
    /// sheet.
    @ViewBuilder
    private var quotesSection: some View {
        let active = coordinator.quoteHistory.filter { q in
            let s = q.typedStatus
            return s != .superseded && s != .withdrawn && s != .draft
        }
        if !active.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("QUOTES")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.32)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.horizontal, 4)

                VStack(spacing: 8) {
                    ForEach(active, id: \.id) { q in
                        Button {
                            Haptics.selection()
                            Task {
                                _ = await coordinator.loadAndPinQuote(quoteId: q.id)
                                presentQuote = true
                            }
                        } label: {
                            HandymanQuoteRow(quote: q, vendorName: linkedHandyman?.companyName)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, 20)
        }
    }

    private var vendorCardSection: some View {
        VStack(spacing: 12) {
            if let handyman = linkedHandyman {
                VendorCard(
                    state: .linked(
                        name: handyman.companyName,
                        phoneURL: handymanPhoneURL
                    ),
                    chezOwned: handyman.isChezOwned,
                    onTap: { presentChat = true },
                    onCall: nil
                )
            } else {
                VendorCard(state: .empty, onTap: { showFindHandyman = true })
                // Phase 80 — when no handyman is linked, surface Chez as
                // the assisted-discovery option below the empty card.
                ChezEntryButton(
                    category: .findHandyman,
                    label: "Have Chez find me a contractor",
                    caption: "Chez finds a vetted local pro and books the visit.",
                    context: chezHandymanContext
                )
            }
        }
        .padding(.horizontal, TasksV5.pageMargin)
        .padding(.bottom, 20)
    }

    private var chezHandymanContext: [String: String] {
        var c: [String: String] = [:]
        if let propertyId { c["property_id"] = propertyId.uuidString }
        c["punch_item_count"] = String(punchListVM.entries.count)
        if !punchListVM.entries.isEmpty {
            let titles = punchListVM.entries.prefix(20).map { "• \($0.title)" }.joined(separator: "\n")
            c["punch_list_preview"] = titles
        }
        return c
    }

    private var firstVisitPromptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.actionPressed)
                Text("FIRST VISIT")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(HavenColors.actionPressed)
            }
            Text("Your contractor will help build out your home profile")
                .font(HavenTypography.fraunces(size: 16, weight: 600))
                .tracking(-0.2)
                .foregroundStyle(HavenColors.navy900)
                .fixedSize(horizontal: false, vertical: true)
            Text("On your first visit, they'll capture make + model on systems we don't have details for yet (e.g. \"Bosch 800 refrigerator\" instead of just \"refrigerator\"). It syncs back here automatically so future suggestions get sharper.")
                .font(.system(size: 12.5))
                .foregroundStyle(HavenColors.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TasksV5.decisionRowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TasksV5.decisionRowBorder, lineWidth: 1)
        )
        .padding(.horizontal, TasksV5.pageMargin)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private var punchListSection: some View {
        if let visit = nextScheduledVisit {
            // Punch list = parsed children of the upcoming visit
            visitChildrenPunchList(visit: visit)
        } else {
            // Fallback to the user's accumulating draft list
            draftPunchListSection
        }
    }

    // MARK: - Proposals Inbox (Phase 78)
    //
    // Renders pending proposals from the handyman side that need a
    // homeowner accept/decline. Two row types:
    //   1. Tasks where the handyman flagged something for the homeowner
    //      (e.g. "you need a roofer"). proposed_by_role='handyman' AND
    //      proposal_status='pending'.
    //   2. Punch items the homeowner added AFTER the visit was confirmed
    //      ("added_after_lock"). The visit is locked, so the handyman
    //      needs to confirm scope creep before doing the work.
    // Plus follow-up visit proposals (handyman_requests rows) — not
    // wired in v1; will land in a later sub-phase once the request
    // shape stabilizes.
    @ViewBuilder
    private var proposalsInboxSection: some View {
        let pendingTasks = proposalTasks
        let pendingItems = proposalPunchItems.filter { $0.addedAfterLock == true && $0.archivedAt == nil && ($0.completedAt == nil) }
        let total = pendingTasks.count + pendingItems.count

        if total > 0 {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("NEEDS YOUR DECISION")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.32)
                        .foregroundStyle(HavenColors.action)
                    Text("·")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                    Text("\(total)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                }
                .padding(.horizontal, 4)

                VStack(spacing: 8) {
                    ForEach(pendingTasks, id: \.id) { task in
                        proposalTaskRow(task)
                    }
                    ForEach(pendingItems, id: \.id) { item in
                        proposalPunchItemRow(item)
                    }
                }

                if let msg = proposalErrorMessage {
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.critical)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, 20)
        }
    }

    private func proposalTaskRow(_ task: MaintenanceTaskDBRow) -> some View {
        let proposalId = task.id.uuidString
        let isResponding = respondingProposalId == proposalId
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.navy900)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Suggested by your contractor")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textSecondary)
                    if let desc = task.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 12.5))
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
            }
            proposalActionRow(
                proposalId: proposalId,
                isResponding: isResponding,
                onAccept: { Task { await respondToProposal(kind: "task", id: proposalId, decision: "accept") } },
                onDecline: { Task { await respondToProposal(kind: "task", id: proposalId, decision: "decline") } }
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TasksV5.decisionRowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TasksV5.decisionRowBorder, lineWidth: 1)
        )
        .opacity(isResponding ? 0.5 : 1.0)
    }

    private func proposalPunchItemRow(_ item: HandymanPunchItemRow) -> some View {
        let proposalId = item.id.uuidString
        let isResponding = respondingProposalId == proposalId
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.navy900)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Added after the visit was locked. Contractor needs to confirm")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let desc = item.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 12.5))
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
            }
            proposalActionRow(
                proposalId: proposalId,
                isResponding: isResponding,
                onAccept: { Task { await respondToProposal(kind: "punch_item", id: proposalId, decision: "accept") } },
                onDecline: { Task { await respondToProposal(kind: "punch_item", id: proposalId, decision: "decline") } }
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TasksV5.decisionRowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TasksV5.decisionRowBorder, lineWidth: 1)
        )
        .opacity(isResponding ? 0.5 : 1.0)
    }

    private func proposalActionRow(
        proposalId: String,
        isResponding: Bool,
        onAccept: @escaping () -> Void,
        onDecline: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Button(action: onAccept) {
                Text("Accept")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(HavenColors.action)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isResponding)

            Button(action: onDecline) {
                Text("Decline")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.navy900)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(HavenColors.beige300, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isResponding)
        }
    }

    @ViewBuilder
    private func visitChildrenPunchList(visit: MaintenanceTaskDBRow) -> some View {
        if hasStructuredVisitItems {
            structuredVisitChildrenPunchList(visit: visit)
        } else {
            legacyVisitChildrenPunchList(visit: visit)
        }
    }

    /// Phase 78: structured children path. Each row is a real
    /// `handyman_punch_items` row — tap the checkbox to mark done,
    /// which fires `update_punch_item_status` and bumps the linked
    /// system's last-serviced date via the DB trigger.
    private func structuredVisitChildrenPunchList(visit: MaintenanceTaskDBRow) -> some View {
        let items = structuredVisitItems
        let visibleItems = Array(items.prefix(4))
        return VStack(alignment: .leading, spacing: 0) {
            SectionLabel(
                eyebrow: punchListEyebrow(for: visit),
                sub: "\(items.count) item\(items.count == 1 ? "" : "s")",
                action: .init(title: "View all", tone: .indigo, perform: {
                    presentedVisit = visit
                })
            )
            .padding(.bottom, TasksV5.sectionLabelGap)

            if items.isEmpty {
                emptyVisitChildrenCard
                    .padding(.horizontal, TasksV5.pageMargin)
                    .padding(.bottom, TasksV5.sectionGap)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                        VisitStructuredChildRow(
                            item: item,
                            isLast: index >= min(items.count, 4) - 1 && items.count <= 4,
                            isToggling: togglingItemIds.contains(item.id),
                            onToggle: { Task { await togglePunchItem(item) } }
                        )
                    }
                    if items.count > 4 {
                        Button {
                            presentedVisit = visit
                        } label: {
                            HStack {
                                Text("+ \(items.count - 4) more")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(HavenColors.textTertiary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .padding(.top, 10)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HavenColors.beige200, lineWidth: 1)
                )
                .padding(.horizontal, TasksV5.pageMargin)
                .padding(.bottom, TasksV5.sectionGap)
            }
        }
    }

    /// Legacy fallback path used only when there are no structured
    /// punch items for the visit (pre-Phase-78 visits the backfill
    /// missed). Read-only — the only way to "complete" these is to
    /// migrate the visit through the Phase 1 backfill or have the
    /// handyman re-add items via the field app.
    private func legacyVisitChildrenPunchList(visit: MaintenanceTaskDBRow) -> some View {
        let children = visitChildren
        return VStack(alignment: .leading, spacing: 0) {
            SectionLabel(
                eyebrow: punchListEyebrow(for: visit),
                sub: "\(children.count) item\(children.count == 1 ? "" : "s")",
                action: .init(title: "View all", tone: .indigo, perform: {
                    presentedVisit = visit
                })
            )
            .padding(.bottom, TasksV5.sectionLabelGap)

            if children.isEmpty {
                emptyVisitChildrenCard
                    .padding(.horizontal, TasksV5.pageMargin)
                    .padding(.bottom, TasksV5.sectionGap)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(children.prefix(4).enumerated()), id: \.element.id) { index, child in
                        VisitChildRow(
                            child: child,
                            isLast: index >= min(children.count, 4) - 1 && children.count <= 4
                        )
                    }
                    if children.count > 4 {
                        Button {
                            presentedVisit = visit
                        } label: {
                            HStack {
                                Text("+ \(children.count - 4) more")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(HavenColors.textTertiary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .padding(.top, 10)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HavenColors.beige200, lineWidth: 1)
                )
                .padding(.horizontal, TasksV5.pageMargin)
                .padding(.bottom, TasksV5.sectionGap)
            }
        }
    }

    private var emptyVisitChildrenCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No items on this visit yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.navy900)
            Text("Add items so your contractor knows exactly what's on the docket.")
                .font(.system(size: 12.5))
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var draftPunchListSection: some View {
        SectionLabel(
            eyebrow: "Punch list",
            sub: totalPunchCount > 0 ? "\(totalPunchCount) item\(totalPunchCount == 1 ? "" : "s")" : nil,
            action: totalPunchCount > 0 ? .init(title: "View all", perform: {
                pushTarget = .punchListFull
            }) : nil
        )
        .padding(.bottom, TasksV5.sectionLabelGap)

        if totalPunchCount == 0 {
            emptyPunchListCard
                .padding(.horizontal, TasksV5.pageMargin)
                .padding(.bottom, TasksV5.sectionGap)
        } else {
            PunchListCard(
                items: .constant(visiblePunchItems),
                extraCount: extraPunchCount,
                onToggle: handleToggle,
                onTapItem: { _ in pushTarget = .punchListFull },
                onShowMore: { pushTarget = .punchListFull }
            )
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, TasksV5.sectionGap)
        }
    }

    @ViewBuilder
    private var recommendedSection: some View {
        let items = recommendedTasks
        if !items.isEmpty {
            SectionLabel(eyebrow: "Recommended", sub: "Could fold into a visit")
                .padding(.bottom, TasksV5.sectionLabelGap)

            VStack(spacing: TasksV5.rowGap) {
                ForEach(items) { task in
                    RecommendedRow(
                        title: task.title,
                        due: dueLabel(for: task),
                        isAdding: addingRecommendedIds.contains(task.id),
                        onTap: { pushTarget = .punchListFull },
                        onAdd: { addToPunchList(task: task) }
                    )
                }
            }
            .padding(.horizontal, TasksV5.pageMargin)
            .padding(.bottom, TasksV5.sectionGap)
        }
    }

    private var visitHistorySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(eyebrow: "Visit history")
                .padding(.bottom, TasksV5.sectionLabelGap)

            if pastVisits.isEmpty {
                VisitHistoryEmptyCard()
                    .padding(.horizontal, TasksV5.pageMargin)
            } else {
                VStack(spacing: TasksV5.rowGap) {
                    ForEach(pastVisits.prefix(4)) { visit in
                        pastVisitRow(visit)
                    }
                }
                .padding(.horizontal, TasksV5.pageMargin)
            }
        }
    }

    private func pastVisitRow(_ visit: MaintenanceTaskDBRow) -> some View {
        Button {
            presentedVisit = visit
        } label: {
            HStack(spacing: 12) {
                IconTile(symbol: "checkmark.circle.fill", tone: .indigo)
                VStack(alignment: .leading, spacing: 2) {
                    Text(visit.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.navy900)
                        .lineLimit(1)
                    Text(visit.lastCompletedDate ?? "")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyPunchListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inbox zero. Nothing on your contractor's plate")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.navy900)
            Text("As Chez learns your home, small jobs land here. Add one yourself any time.")
                .font(.system(size: 12.5))
                .foregroundStyle(HavenColors.textSecondary)
                .lineSpacing(2)
            Button {
                pushTarget = .punchListFull
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Add an item")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(HavenColors.actionPressed)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func handleToggle(_ id: String) {
        guard !pendingChecked.contains(id) else { return }
        _ = withAnimation(.easeInOut(duration: 0.15)) {
            pendingChecked.insert(id)
        }
        guard let entry = punchListVM.entries.first(where: { $0.id == id }) else { return }
        let task = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await punchListVM.archive(entry: entry)
            _ = await MainActor.run { pendingChecked.remove(id) }
        }
        _ = task
    }

    private func addToPunchList(task: MaintenanceTaskDBRow) {
        guard let householdId, let propertyId else { return }
        addingRecommendedIds.insert(task.id)
        let work = Task {
            do {
                let item = HandymanPunchItemInsert(
                    householdId: householdId,
                    propertyId: propertyId,
                    title: task.title,
                    source: "recommended",
                    sourceTaskId: task.id
                )
                _ = try await DatabaseService.shared.createHandymanPunchItem(item)
                Analytics.track(.handymanPunchItemAdded, ["source": "recommended_v5"])
                NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                await punchListVM.load(householdId: householdId, propertyId: propertyId)
            } catch {
                print("[HandymanTabView] addToPunchList failed: \(error)")
            }
            _ = await MainActor.run { addingRecommendedIds.remove(task.id) }
        }
        _ = work
    }

    private func reloadCoordination() async {
        guard let visit = nextScheduledVisit else {
            await MainActor.run { coordinator.clear() }
            return
        }
        await coordinator.load(visit: visit, vendor: linkedHandyman)
    }

    /// Phase 78: load structured punch items for the upcoming visit.
    /// Reads from `handyman_punch_items WHERE assigned_visit_task_id =
    /// visit.id` — the same table the field app writes to. Empty
    /// result means we should fall back to the legacy notes parser
    /// (pre-Phase-78 visits that the backfill missed).
    private func loadStructuredVisitItems() async {
        guard let visit = nextScheduledVisit else {
            await MainActor.run { self.structuredVisitItems = [] }
            return
        }
        let items = (try? await DatabaseService.shared.fetchHandymanPunchItemsForVisit(visitTaskId: visit.id)) ?? []
        let active = items.filter { $0.archivedAt == nil }
            .sorted { lhs, rhs in
                // Pending items first (so unchecked work is at the top),
                // then chronological.
                if lhs.isDone != rhs.isDone {
                    return !lhs.isDone
                }
                return lhs.createdAt < rhs.createdAt
            }
        await MainActor.run {
            self.structuredVisitItems = active
        }
    }

    /// Phase 78: toggle a structured punch item between pending and
    /// done. Routes through `update_punch_item_status` so the DB
    /// trigger bumps the linked system's last-serviced date when an
    /// item flips to done. Optimistic UI: dim the row while the call
    /// is in flight so two rapid taps don't double-fire.
    private func togglePunchItem(_ item: HandymanPunchItemRow) async {
        guard !togglingItemIds.contains(item.id) else { return }
        let nextStatus = item.isDone ? "pending" : "done"
        await MainActor.run { _ = togglingItemIds.insert(item.id) }
        do {
            _ = try await HavenSupabase.updatePunchItemStatus(
                itemId: item.id.uuidString,
                status: nextStatus
            )
            Haptics.success()
            await loadStructuredVisitItems()
            // Bumping a system's last-serviced date may surface in the
            // homeowner's system detail / dashboard, so refresh the
            // wider task list too.
            await maintenanceVM.loadTasks()
        } catch {
            Haptics.error()
        }
        await MainActor.run { _ = togglingItemIds.remove(item.id) }
    }

    /// Phase 78: refresh the proposals inbox. Pulls handyman-flagged
    /// pending tasks (proposed_by_role='handyman' AND
    /// proposal_status='pending') and the household's punch items so we
    /// can pick out the after-lock additions. Both queries are RLS-
    /// scoped to the caller's household so this is safe to call
    /// liberally on any data-change notification.
    private func loadProposals() async {
        guard let householdId else { return }
        let db = DatabaseService.shared
        async let tasksTask: [MaintenanceTaskDBRow] = (try? db.fetchHandymanProposalTasks(householdId: householdId)) ?? []
        async let itemsTask: [HandymanPunchItemRow] = (try? db.fetchAllHandymanPunchItems(householdId: householdId)) ?? []
        let (tasks, items) = await (tasksTask, itemsTask)
        await MainActor.run {
            self.proposalTasks = tasks
            self.proposalPunchItems = items
        }
    }

    /// Phase 78: accept or decline a proposal. Server enforces
    /// no-double-accept via DB unique partial index — if a spouse beats
    /// us to it, the call returns a 409 and we surface the conflict
    /// inline. Refreshes both the inbox and the underlying task list
    /// so accepted handyman-flagged tasks immediately graduate into
    /// the homeowner's regular maintenance list.
    private func respondToProposal(kind: String, id: String, decision: String) async {
        await MainActor.run {
            self.respondingProposalId = id
            self.proposalErrorMessage = nil
        }
        do {
            _ = try await HavenSupabase.respondToProposal(kind: kind, id: id, decision: decision)
            Haptics.success()
            await loadProposals()
            await maintenanceVM.loadTasks()
            if let householdId {
                await punchListVM.load(householdId: householdId, propertyId: propertyId)
            }
            Analytics.track(.handymanProposalResponded, [
                "kind": kind,
                "decision": decision
            ])
        } catch {
            Haptics.error()
            await MainActor.run {
                self.proposalErrorMessage = "Couldn't record your decision. Try again in a moment."
            }
        }
        await MainActor.run {
            self.respondingProposalId = nil
        }
    }

    // MARK: - Navigation

    enum HandymanPush: Hashable, Identifiable {
        case punchListFull

        var id: String { "punchListFull" }
        static func == (lhs: HandymanPush, rhs: HandymanPush) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    @ViewBuilder
    private func destination(for push: HandymanPush) -> some View {
        switch push {
        case .punchListFull:
            if let householdId {
                HandymanPunchListView(householdId: householdId, propertyId: propertyId)
            }
        }
    }

    // MARK: - Helpers

    private func durationLabel(for entry: HandymanPunchEntry) -> String? {
        guard let mins = entry.estimatedMinutes else { return nil }
        if mins >= 60 {
            let hours = Double(mins) / 60.0
            if hours == hours.rounded() {
                return "\(Int(hours)) hr"
            }
            return String(format: "%.1f hr", hours)
        }
        return "\(mins) min"
    }

    private func dueLabel(for task: MaintenanceTaskDBRow) -> String {
        let dateString = task.scheduledDate ?? task.nextDueDate
        guard let date = MaintenanceDateFormatting.date(from: dateString) else {
            return "Soon"
        }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days <= 0 { return "Now" }
        if days < 14 { return "in \(days) day\(days == 1 ? "" : "s")" }
        if days < 60 { return "in \(days / 7) weeks" }
        if days < 365 { return "in \(days / 30) months" }
        return "next year"
    }

    /// Punch list section eyebrow. With one upcoming visit it's just
    /// "Punch list for this visit"; with multiple, name the date so
    /// the homeowner knows which visit owns these items vs. the others
    /// in the UPCOMING VISITS rail.
    private func punchListEyebrow(for visit: MaintenanceTaskDBRow) -> String {
        guard !additionalUpcomingVisits.isEmpty else {
            return "Punch list for this visit"
        }
        let dateString = visit.scheduledDate ?? visit.nextDueDate
        guard let date = MaintenanceDateFormatting.date(from: dateString) else {
            return "Punch list for this visit"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Punch list for \(formatter.string(from: date)) visit"
    }

    private var estimateLabel: String? {
        let totalMinutes = punchListVM.entries.compactMap { $0.estimatedMinutes }.reduce(0, +)
        guard totalMinutes > 0 else { return nil }
        let hours = Double(totalMinutes) / 60.0
        if hours < 1 { return "~\(totalMinutes) min" }
        if hours == hours.rounded() { return "~\(Int(hours)) hrs" }
        return String(format: "~%.1f hrs", hours)
    }

    private var handymanPhoneURL: URL? {
        guard let phone = linkedHandyman?.phone else { return nil }
        let digits = phone.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }

    private var handymanCallAction: (() -> Void)? {
        guard let url = handymanPhoneURL else { return nil }
        return { UIApplication.shared.open(url) }
    }
}

// MARK: - Upcoming visit hero

private struct UpcomingVisitHero: View {
    let visit: MaintenanceTaskDBRow
    let vendor: ContractorRow?
    let itemCount: Int
    let coordinationRequest: HandymanRequestRow?
    let onSchedule: () -> Void
    let onMessage: () -> Void
    let onCall: (() -> Void)?

    private var dateLabel: String {
        // 1. Confirmed time on the linked request — source of truth.
        if let confirmed = coordinationRequest?.confirmedVisitAt {
            return confirmed.formatted(date: .abbreviated, time: .shortened)
        }
        // 2. The task's own scheduled_date / next_due_date — set when
        //    the visit is on the books, even if no proposal cycle ran.
        //    This was previously LOWER priority than proposedVisitAt
        //    which left stale proposals showing up after the visit
        //    had already been auto-assigned.
        let dateString = visit.scheduledDate ?? visit.nextDueDate
        if let parsed = MaintenanceDateFormatting.date(from: dateString) {
            return parsed.formatted(date: .complete, time: .omitted)
        }
        // 3. Active proposal still negotiating.
        if let proposed = coordinationRequest?.proposedVisitAt {
            return "Proposed: \(proposed.formatted(date: .abbreviated, time: .shortened))"
        }
        return "Date pending"
    }

    private var statusLabel: String {
        if let request = coordinationRequest {
            switch request.typedStatus {
            case .scheduled, .confirmed: return "Confirmed"
            case .alternateDatesProposed: return "Time being discussed"
            case .awaitingHomeowner: return "Awaiting your reply"
            case .onMyWay: return "Contractor on the way"
            case .checkedIn, .inProgress: return "Visit in progress"
            case .completed: return "Wrapped up"
            case .submitted, .sentToHandyman: return "Request sent"
            default: break
            }
        }
        return "Scheduled"
    }

    private var headline: String {
        if itemCount > 0 {
            return "\(itemCount) item\(itemCount == 1 ? "" : "s") on the punch list"
        }
        return "Visit on the books"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEXT VISIT")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.32)
                .foregroundStyle(HavenColors.actionLight)
                .padding(.bottom, 6)

            Text(headline)
                .font(HavenTypography.fraunces(size: 19, weight: 500))
                .tracking(-0.3)
                .lineSpacing(2)
                .foregroundStyle(.white)
                .padding(.bottom, 4)
                .multilineTextAlignment(.leading)

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))
                Text(dateLabel)
                    .font(.system(size: 12.5, weight: .medium))
            }
            .foregroundStyle(Color.white.opacity(0.85))
            .padding(.bottom, 4)

            HStack(spacing: 6) {
                Image(systemName: statusIcon)
                    .font(.system(size: 11, weight: .semibold))
                Text("\(vendor?.companyName ?? "Your contractor") · \(statusLabel)")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(Color.white.opacity(0.7))
            .padding(.bottom, 14)

            HStack(spacing: 8) {
                Button(action: {
                    Haptics.medium()
                    onSchedule()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 14, weight: .semibold))
                        Text("View visit")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(HavenColors.action)
                    )
                    .shadow(
                        color: TasksV5.salmonGlowColor,
                        radius: TasksV5.salmonGlowRadius,
                        x: 0,
                        y: TasksV5.salmonGlowY
                    )
                }
                .buttonStyle(.plain)

                Button(action: onMessage) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.14))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Message contractor")

                if let onCall {
                    Button(action: {
                        Haptics.light()
                        onCall()
                    }) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.14))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Call contractor")
                }
            }
        }
    }

    private var statusIcon: String {
        guard let request = coordinationRequest else { return "wrench.and.screwdriver.fill" }
        switch request.typedStatus {
        case .onMyWay, .checkedIn, .inProgress: return "location.fill"
        case .awaitingHomeowner, .alternateDatesProposed: return "clock.fill"
        default: return "wrench.and.screwdriver.fill"
        }
    }
}

// MARK: - Additional visit row

/// Compact row used in the "Also upcoming" rail when the homeowner
/// has more than one booked visit with this handyman (e.g. after the
/// provider used Split Visit to peel items off into a follow-up).
/// Tap → opens the HandymanVisitDetailSheet for that visit.
private struct AdditionalVisitRow: View {
    let visit: MaintenanceTaskDBRow

    private var dateLabel: String {
        let raw = visit.scheduledDate ?? visit.nextDueDate
        if let parsed = MaintenanceDateFormatting.date(from: raw) {
            return parsed.formatted(date: .abbreviated, time: .omitted)
        }
        return "Date pending"
    }

    private var itemCount: Int {
        guard let notes = visit.notes else { return 0 }
        return VisitNotesParser.parsePunchList(from: notes).count
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HavenColors.actionPale)
                    .frame(width: 38, height: 38)
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HavenColors.actionPressed)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(visit.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.navy900)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(dateLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textSecondary)
                    if itemCount > 0 {
                        Text("·")
                            .font(.system(size: 12))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
    }
}

// MARK: - Visit child row

private struct VisitChildRow: View {
    let child: VisitChildItem
    let isLast: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(HavenColors.beige400)
            VStack(alignment: .leading, spacing: 2) {
                Text(child.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(HavenColors.navy900)
                    .multilineTextAlignment(.leading)
                if let duration = child.estimatedMinutes {
                    Text("~\(duration) min")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(TasksV5.punchListDivider)
                    .frame(height: 1)
                    .padding(.horizontal, 14)
            }
        }
    }
}

/// Phase 78: structured punch item row. Tap the checkbox to flip
/// between pending and done — server fires `update_punch_item_status`
/// and the DB trigger bumps the linked system's last-serviced date
/// when status='done' takes effect.
private struct VisitStructuredChildRow: View {
    let item: HandymanPunchItemRow
    let isLast: Bool
    let isToggling: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: item.isDone ? .semibold : .regular))
                    .foregroundStyle(item.isDone ? HavenColors.success : HavenColors.beige400)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(item.isDone ? HavenColors.textTertiary : HavenColors.navy900)
                        .strikethrough(item.isDone, color: HavenColors.textTertiary)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        if let mins = item.estimatedMinutes {
                            Text("~\(mins) min")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        if let label = item.systemLabelSnapshot, !label.isEmpty {
                            Text("·")
                                .font(.system(size: 11.5))
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("Linked: \(label)")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        if item.addedAfterLock == true && !item.isDone {
                            Text("·")
                                .font(.system(size: 11.5))
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("Awaiting contractor confirmation")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(HavenColors.action)
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .opacity(isToggling ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isToggling)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(TasksV5.punchListDivider)
                    .frame(height: 1)
                    .padding(.horizontal, 14)
            }
        }
    }
}

// MARK: - Quote row (top-level Quotes section)

/// Compact tappable row used in the Handyman tab's Quotes section.
/// Surfaces every active quote regardless of whether it's linked to a
/// visit, so the homeowner can always reach the review sheet.
private struct HandymanQuoteRow: View {
    let quote: ProviderQuoteRow
    let vendorName: String?

    private var totalLabel: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = quote.total.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: quote.total)) ?? "$\(Int(quote.total))"
    }

    private var statusStyle: (label: String, color: Color) {
        switch quote.typedStatus {
        case .draft:                return ("Draft", HavenColors.textSecondary)
        case .sent:                 return ("New", HavenColors.action)
        case .viewed:               return ("Viewed", HavenColors.action)
        case .approved:             return ("Approved", HavenColors.success)
        case .declined:             return ("Declined", HavenColors.critical)
        case .counteredByHomeowner: return ("Countered", HavenColors.warning)
        case .superseded:           return ("Superseded", HavenColors.textTertiary)
        case .withdrawn:            return ("Withdrawn", HavenColors.textTertiary)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HavenColors.actionPale)
                    .frame(width: 38, height: 38)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HavenColors.actionPressed)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(quote.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.navy900)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(totalLabel)
                        .font(HavenTypography.fraunces(size: 14, weight: 600))
                        .foregroundStyle(HavenColors.navy900)
                    Text("·")
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("\(quote.lineItems.count) item\(quote.lineItems.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textSecondary)
                    if let vendor = vendorName {
                        Text("·")
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(vendor)
                            .font(.system(size: 12))
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Text(statusStyle.label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(statusStyle.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(statusStyle.color.opacity(0.12)))

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
    }
}

// MARK: - Coordinator (shared state for visit + chat)

@MainActor
final class HandymanRequestCoordinator: ObservableObject {
    static let shared = HandymanRequestCoordinator()

    @Published private(set) var request: HandymanRequestRow?
    @Published private(set) var messages: [HandymanRequestMessageRow] = []
    @Published private(set) var quote: ProviderQuoteRow?
    /// Every quote ever attached to this request, newest first. The
    /// current `quote` is always quoteHistory.first (or the freshest
    /// non-superseded one). Used to render version history on the
    /// review sheet so the homeowner can see how a counter chain
    /// evolved (Provider $1,725 → Counter $1,200 → Provider $1,400 → …).
    @Published private(set) var quoteHistory: [ProviderQuoteRow] = []
    /// Phase 75h Q&A: per-line-item comment threads on the active
    /// quote. Loaded alongside the quote; refreshed when comments
    /// are submitted. Always ordered oldest → newest.
    @Published private(set) var quoteComments: [ProviderQuoteCommentRow] = []

    private var loadedVisitId: UUID?
    private var realtimeChannel: RealtimeChannelV2?
    private var realtimeListenerTask: Task<Void, Never>?
    private var subscribedRequestId: UUID?

    func clear() {
        request = nil
        messages = []
        quote = nil
        quoteHistory = []
        quoteComments = []
        loadedVisitId = nil
        unsubscribeRealtime()
    }

    /// Loads the handyman_request for a visit task. Tries the explicit
    /// `visit_task_id` link first; falls back to finding any active
    /// handyman_request for the same household + contractor (the common
    /// case for legacy visits that were created without the link), and
    /// backfills `visit_task_id` so future loads are O(1).
    func load(visit: MaintenanceTaskDBRow, vendor: ContractorRow?) async {
        if loadedVisitId == visit.id, request != nil { return }
        loadedVisitId = visit.id

        do {
            // Path A: direct visit_task_id link
            if let direct = try await DatabaseService.shared.fetchLatestHandymanRequest(visitTaskId: visit.id) {
                await applyRequest(direct)
                return
            }

            // Path B: fall back to household + contractor lookup. The
            // Operations Desk-side request might exist without the
            // visit_task_id stamped on it — surface it anyway so the
            // homeowner can see the same conversation thread.
            if let vendor {
                let candidates = try await DatabaseService.shared.fetchHandymanRequests(
                    householdId: visit.householdId,
                    propertyId: nil,
                    limit: 25
                )
                // Wave Y2: Drop the terminal-state filter so completed /
                // cancelled / declined threads still surface here. The
                // homeowner needs to see the audit trail when the
                // contractor marks a visit complete from the Operations
                // Desk — Apple Mail / Linear / GitHub all keep
                // terminal-state threads visible. The status badge in
                // the chat sheet header reflects the lifecycle state.
                let match = candidates
                    .filter { $0.contractorId == vendor.id }
                    .sorted { $0.updatedAt > $1.updatedAt }
                    .first
                if let match {
                    // Backfill visit_task_id so the cheap path wins next time.
                    if match.visitTaskId == nil {
                        var update = HandymanRequestUpdate()
                        update.visitTaskId = visit.id
                        _ = try? await DatabaseService.shared.updateHandymanRequest(id: match.id, update)
                    }
                    await applyRequest(match)
                    return
                }
            }

            // Nothing found — leave nil so chat shows empty state.
            request = nil
            messages = []
            unsubscribeRealtime()
        } catch {
            print("[HandymanRequestCoordinator] load failed: \(error)")
        }
    }

    private func applyRequest(_ req: HandymanRequestRow) async {
        request = req
        messages = (try? await DatabaseService.shared.fetchHandymanRequestMessages(requestId: req.id)) ?? []
        await reloadQuote(requestId: req.id)
        subscribeRealtime(requestId: req.id)
    }

    func reload() async {
        guard let req = request else { return }
        messages = (try? await DatabaseService.shared.fetchHandymanRequestMessages(requestId: req.id)) ?? []
        await reloadQuote(requestId: req.id)
    }

    private func reloadQuote(requestId: UUID) async {
        // Fetch by request first (canonical link), then fall back to
        // the property's full quote list so we don't miss quotes the
        // provider built without picking a visit. Dedup by id and
        // keep newest first.
        let byRequest = (try? await DatabaseService.shared.fetchProviderQuotes(requestId: requestId)) ?? []
        var combined = byRequest
        if let propId = request?.propertyId {
            let byProperty = (try? await DatabaseService.shared.fetchProviderQuotesForProperty(propertyId: propId)) ?? []
            let existingIds = Set(combined.map(\.id))
            combined.append(contentsOf: byProperty.filter { !existingIds.contains($0.id) })
        }
        quoteHistory = combined
        // Pick the most recent quote that's still in play. Skip
        // superseded/withdrawn — they'd otherwise show as the "latest"
        // because the table sorts updated_at DESC.
        quote = combined.first { q in
            let s = q.typedStatus
            return s != .superseded && s != .withdrawn
        }
        await reloadQuoteComments()
    }

    /// Refresh the Q&A comment thread for the active quote.
    func reloadQuoteComments() async {
        guard let q = quote else {
            quoteComments = []
            return
        }
        quoteComments = (try? await DatabaseService.shared.fetchProviderQuoteComments(quoteId: q.id)) ?? []
    }

    /// Submit a batch of homeowner-authored questions for the active
    /// quote, then push the provider so they see them on the
    /// operations desk. `pending` is the local array of (lineItemId,
    /// body) tuples the user added before tapping "Send to handyman".
    func submitQuoteQuestions(_ pending: [(lineItemId: String?, body: String)]) async -> Bool {
        guard let q = quote, let req = request else { return false }
        guard !pending.isEmpty else { return true }
        do {
            for entry in pending {
                let trimmed = entry.body.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                let insert = ProviderQuoteCommentInsert(
                    quoteId: q.id,
                    lineItemId: entry.lineItemId,
                    body: trimmed,
                    authorRole: "homeowner"
                )
                _ = try await DatabaseService.shared.createProviderQuoteComment(insert)
            }
            await reloadQuoteComments()
            // Push the provider so they see the questions without
            // having to refresh the operations desk.
            await notifyProvider(
                requestId: req.id,
                eventType: "homeowner_quote_questions",
                title: "New questions on your quote",
                body: "\(pending.count) question\(pending.count == 1 ? "" : "s") on \"\(q.title)\". Tap to review."
            )
            return true
        } catch {
            print("[HandymanRequestCoordinator] submitQuoteQuestions failed: \(error)")
            return false
        }
    }

    /// Push-driven deep link: load a specific quote by id and pin it as
    /// the active quote so the review sheet opens straight to it. Used
    /// when the user taps a `handyman_quote_sent` push that carried
    /// `quote_id` in the payload.
    func loadAndPinQuote(quoteId: UUID) async -> Bool {
        let fetched = try? await DatabaseService.shared.fetchProviderQuote(id: quoteId)
        guard let row = fetched ?? nil else { return false }
        if !quoteHistory.contains(where: { $0.id == row.id }) {
            quoteHistory.insert(row, at: 0)
        }
        quote = row
        return true
    }

    /// Push-driven deep link: when a handyman_* push arrives carrying
    /// a `request_id`, load that specific request (and its linked
    /// visit task). Without this, the push handler always opened the
    /// soonest scheduled visit — which meant a reschedule on a
    /// follow-up visit silently rerouted the homeowner to the MAIN
    /// visit and the propose_time message never surfaced. Returns
    /// the matching task (so the caller can pin it as `presentedVisit`)
    /// or nil when the request can't be found.
    func loadByRequestId(_ requestId: UUID) async -> HandymanRequestRow? {
        let fetched = try? await DatabaseService.shared.fetchHandymanRequest(id: requestId)
        guard let req = fetched ?? nil else { return nil }
        // Apply the request directly (this also reloads messages,
        // quote, and switches the Realtime subscription).
        loadedVisitId = req.visitTaskId
        await applyRequest(req)
        return req
    }

    /// Mark the homeowner's response on the latest quote.
    /// Goes through the SECURITY DEFINER respond_to_provider_quote RPC.
    func respondToQuote(status: ProviderQuoteStatus, signedName: String? = nil) async -> Bool {
        guard let q = quote else { return false }
        do {
            let updated = try await DatabaseService.shared.respondToProviderQuote(
                id: q.id,
                status: status,
                homeownerNote: signedName
            )
            quote = updated
            return true
        } catch {
            print("[HandymanRequestCoordinator] respondToQuote failed: \(error)")
            return false
        }
    }

    /// Homeowner accepts the most recent vendor-proposed visit time.
    /// Returns true on success. The RPC stamps `confirmed_visit_at`,
    /// walks status to `confirmed`, and inserts an `accept_time`
    /// message — Realtime brings the new message into the thread
    /// automatically.
    func acceptProposedTime(note: String? = nil) async -> Bool {
        guard let req = request else { return false }
        do {
            let updated = try await DatabaseService.shared.acceptVisitTime(
                requestId: req.id,
                acceptedBy: .homeowner,
                note: note
            )
            await applyRequest(updated)
            await notifyProvider(
                requestId: req.id,
                eventType: "homeowner_accepted_time",
                title: "Visit time confirmed",
                body: "The homeowner accepted your proposed time."
            )
            return true
        } catch {
            print("[HandymanRequestCoordinator] acceptProposedTime failed: \(error)")
            return false
        }
    }

    /// Homeowner proposes a counter time. The RPC inserts a
    /// `propose_time` message with the new timestamp in metadata,
    /// resets `confirmed_visit_at` to null, walks status to
    /// `alternate_dates_proposed`. Realtime picks up the new message
    /// so the thread updates without a manual refresh.
    func proposeCounterTime(_ at: Date, note: String? = nil) async -> Bool {
        guard let req = request else { return false }
        do {
            let updated = try await DatabaseService.shared.proposeVisitTime(
                requestId: req.id,
                proposedAt: at,
                proposedBy: .homeowner,
                note: note
            )
            await applyRequest(updated)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            await notifyProvider(
                requestId: req.id,
                eventType: "homeowner_proposed_time",
                title: "Homeowner proposed a new time",
                body: "Tap to review and accept or counter: \(formatter.string(from: at))"
            )
            return true
        } catch {
            print("[HandymanRequestCoordinator] proposeCounterTime failed: \(error)")
            return false
        }
    }

    /// Fire-and-forget push to the provider workspace serving this
    /// request. Without this the operations desk has no signal that
    /// the homeowner just acted on a proposal — they'd only find out
    /// next time they manually refreshed.
    private func notifyProvider(
        requestId: UUID,
        eventType: String,
        title: String,
        body: String
    ) async {
        do {
            try await HavenSupabase.notifyProviderForRequest(
                requestId: requestId,
                eventType: eventType,
                title: title,
                body: body
            )
        } catch {
            // Non-fatal — the DB state is already correct, this is just
            // the push channel.
            print("[HandymanRequestCoordinator] notifyProvider failed: \(error)")
        }
    }

    /// Lazy-create a handyman_request for a visit task that doesn't yet
    /// have one. Only fires when the user types their first message AND
    /// the load path couldn't find an existing request.
    func ensureRequest(
        visit: MaintenanceTaskDBRow,
        vendor: ContractorRow?,
        householdId: UUID,
        propertyId: UUID?
    ) async -> HandymanRequestRow? {
        if let existing = request { return existing }
        let insert = HandymanRequestInsert(
            householdId: householdId,
            propertyId: propertyId,
            contractorId: vendor?.id,
            visitTaskId: visit.id,
            createdByUserId: nil,
            requestType: "standard_visit",
            source: "homeowner",
            title: visit.title,
            details: visit.notes,
            preferredTiming: visit.scheduledDate,
            urgency: "routine",
            status: "submitted",
            firstVisitSetupRequested: false,
            recommendedLane: "handyman",
            quickUpsellTitles: []
        )
        do {
            let created = try await DatabaseService.shared.createHandymanRequest(insert)
            await applyRequest(created)
            return created
        } catch {
            print("[HandymanRequestCoordinator] ensureRequest failed: \(error)")
            return nil
        }
    }

    /// Send a homeowner-side message. Optimistically appends the message
    /// to the local thread (Realtime echo dedupes by id), then writes
    /// the row.
    func sendMessage(
        text: String,
        visit: MaintenanceTaskDBRow,
        vendor: ContractorRow?,
        householdId: UUID,
        propertyId: UUID?
    ) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let req = await ensureRequest(visit: visit, vendor: vendor, householdId: householdId, propertyId: propertyId)
        guard let req else { return false }
        let insert = HandymanRequestMessageInsert(
            requestId: req.id,
            householdId: req.householdId,
            senderRole: "homeowner",
            body: trimmed
        )
        do {
            let inserted = try await DatabaseService.shared.createHandymanRequestMessage(insert)
            // Append immediately if not already in the list (Realtime
            // may or may not have echoed yet).
            if !messages.contains(where: { $0.id == inserted.id }) {
                messages.append(inserted)
            }
            // Phase 95 (gaps #29 / #68): email-fallback path. The
            // function self-rate-limits and short-circuits when the
            // handyman has been active recently — fire-and-forget.
            Task.detached { [requestId = req.id] in
                _ = try? await HavenSupabase.notifyHandymanMessageFallback(requestId: requestId)
            }
            return true
        } catch {
            print("[HandymanRequestCoordinator] sendMessage failed: \(error)")
            return false
        }
    }

    // MARK: Realtime

    /// Subscribes to INSERT events on `handyman_request_messages` filtered
    /// to this request. New messages from either side land in real time.
    private func subscribeRealtime(requestId: UUID) {
        if subscribedRequestId == requestId { return }
        unsubscribeRealtime()
        subscribedRequestId = requestId

        let channel = HavenSupabase.client.realtimeV2.channel("handyman-msg-\(requestId.uuidString)")
        let inserts = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "handyman_request_messages",
            filter: .eq("request_id", value: requestId.uuidString)
        )
        realtimeChannel = channel

        realtimeListenerTask = Task { [weak self] in
            try? await channel.subscribeWithError()
            for await action in inserts {
                guard let self else { return }
                // `action.record` is [String: AnyJSON] — a Swift enum
                // tree from the Supabase SDK. JSONSerialization can't
                // walk it (the inner enum cases are __SwiftValue, not
                // Foundation NSDictionary/NSArray), which crashed the
                // app with "Invalid type in JSON write (__SwiftValue)".
                // AnyJSON is Codable, so JSONEncoder handles it.
                guard
                    let data = try? Self.payloadEncoder.encode(action.record),
                    let decoded = try? Self.messageDecoder.decode(HandymanRequestMessageRow.self, from: data)
                else {
                    continue
                }
                await MainActor.run {
                    if !self.messages.contains(where: { $0.id == decoded.id }) {
                        self.messages.append(decoded)
                    }
                }
                // When a quote_sent message lands, reload the quote so
                // the chat's rich quote bubble has live data behind its
                // "Review quote" button. Without this, the message
                // shows up but `coordinator.quote` stays nil until
                // the user manually re-opens the visit.
                if decoded.typedKind == .quoteSent {
                    await self.reloadQuote(requestId: requestId)
                }
            }
        }
    }

    private static let payloadEncoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    private func unsubscribeRealtime() {
        realtimeListenerTask?.cancel()
        realtimeListenerTask = nil
        let channel = realtimeChannel
        realtimeChannel = nil
        subscribedRequestId = nil
        if let channel {
            Task { await channel.unsubscribe() }
        }
    }

    private static let messageDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return d
    }()
}

/// Phase 95 (gap #94) — promoted from `private` to `internal` so
/// the new `MaintenanceRealtimeSubscription` can share the same
/// fractional-seconds decoder strategy as the handyman-message
/// path. Both paths receive Postgres timestamps with microsecond
/// precision in their Realtime payloads.
extension JSONDecoder.DateDecodingStrategy {
    /// Postgres timestamps in Realtime payloads come back with microsecond
    /// precision (e.g. `2026-04-27T15:42:01.123456+00:00`). The default
    /// `.iso8601` strategy only handles seconds. This decoder accepts
    /// either.
    static var iso8601WithFractionalSeconds: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = withFraction.date(from: raw) { return d }
            let withoutFraction = ISO8601DateFormatter()
            withoutFraction.formatOptions = [.withInternetDateTime]
            if let d = withoutFraction.date(from: raw) { return d }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Bad date: \(raw)")
        }
    }
}

// MARK: - Notes parser

struct VisitChildItem: Identifiable, Hashable {
    let id: String
    let title: String
    let estimatedMinutes: Int?
}

enum VisitNotesParser {
    /// Extracts bullet-list items from a visit task's notes block.
    /// Recognises lines starting with `-`, `•`, `*`, or numeric `1.` /
    /// `1)` markers. Strips the duration marker (`~15 min`, `(15 min)`,
    /// `15 min`) into a separate field. Skips any header line that
    /// contains "Punch list" / "What's included" / "Tasks" headers.
    static func parsePunchList(from notes: String) -> [VisitChildItem] {
        let lines = notes.components(separatedBy: .newlines)
        var items: [VisitChildItem] = []
        for raw in lines {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            // Skip header-style lines
            let lower = trimmed.lowercased()
            if lower.contains("what's included") || lower.contains("punch list:") || lower.contains("tasks:") || lower.hasSuffix(":") {
                continue
            }
            // Strip leading bullet markers
            var working = trimmed
            for prefix in ["- ", "• ", "* "] {
                if working.hasPrefix(prefix) {
                    working = String(working.dropFirst(prefix.count))
                    break
                }
            }
            // Numeric "1. " / "1) " prefixes
            if let firstSpace = working.firstIndex(of: " ") {
                let head = working[..<firstSpace]
                if head.hasSuffix(".") || head.hasSuffix(")") {
                    let numericPart = head.dropLast()
                    if Int(numericPart) != nil {
                        working = String(working[working.index(after: firstSpace)...])
                    }
                }
            }
            // Skip if it doesn't look like a real item
            guard !working.isEmpty, working.count > 2 else { continue }

            // Extract minutes
            let minutes = extractMinutes(from: working)
            let cleaned = stripMinuteSuffix(from: working)

            let id = "\(items.count)-\(cleaned.prefix(40))"
            items.append(VisitChildItem(id: id, title: cleaned, estimatedMinutes: minutes))
        }
        return items
    }

    private static func extractMinutes(from text: String) -> Int? {
        // Look for "~15 min" or "(15 min)" or "15 min" patterns near the end.
        let lower = text.lowercased()
        let candidates = ["~", "(", "•", "·"]
        for marker in candidates {
            if let idx = lower.range(of: marker)?.lowerBound,
               let mins = parseMinutes(in: String(lower[idx...])) {
                return mins
            }
        }
        return parseMinutes(in: lower)
    }

    private static func parseMinutes(in text: String) -> Int? {
        // Find a digit run followed by " min"
        var digits = ""
        var sawMin = false
        for char in text {
            if char.isNumber {
                digits.append(char)
            } else if !digits.isEmpty {
                if char == " " || char == "~" || char == "(" { continue }
                if text.lowercased().contains("\(digits) min") {
                    sawMin = true
                    break
                }
                digits = ""
            }
        }
        if sawMin || (text.contains("min") && !digits.isEmpty) {
            return Int(digits)
        }
        return nil
    }

    private static func stripMinuteSuffix(from text: String) -> String {
        // Remove trailing "(15 min)", "~15 min", "· 15 min", "- 15 min" etc.
        var result = text
        let patterns: [String] = [
            #"\s*\(~?\d+\s*min\)\s*$"#,
            #"\s*~\d+\s*min\s*$"#,
            #"\s*[·•\-]\s*~?\d+\s*min\s*$"#,
            #"\s*\d+\s*min\s*$"#,
        ]
        for pattern in patterns {
            if let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..., in: result)
                result = re.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }
}

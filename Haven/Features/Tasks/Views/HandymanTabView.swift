import SwiftUI

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

    /// Punch list items parsed from the visit's notes block. Each `-` /
    /// `•` / `*` bullet becomes a child item. Strips the parent header
    /// line ("What's included", "Punch list", etc).
    private var visitChildren: [VisitChildItem] {
        guard let notes = nextScheduledVisit?.notes, !notes.isEmpty else { return [] }
        return VisitNotesParser.parsePunchList(from: notes)
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
                    title: "Handyman",
                    onSwitchMode: onSwitchMode,
                    onAdd: { showAddMenu = true }
                )

                visitHeroSection
                vendorCardSection

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
        }
        .refreshable {
            if let householdId {
                await punchListVM.load(householdId: householdId, propertyId: propertyId)
            }
            await maintenanceVM.loadTasks()
            await reloadCoordination()
        }
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task {
                if let householdId {
                    await punchListVM.load(householdId: householdId, propertyId: propertyId)
                }
                await maintenanceVM.loadTasks()
                await reloadCoordination()
            }
        }
        // Push notification deep-link arrived. Present the right sheet
        // for the visit referenced by the payload. The sheet defaults
        // to the visit detail; quote-related events jump straight to
        // the quote review sheet.
        .onReceive(NotificationCenter.default.publisher(for: .openHandymanVisit)) { notification in
            // Refresh tasks first so the next-scheduled-visit picker
            // picks up the request that's being deep-linked to.
            Task {
                await maintenanceVM.loadTasks()
                await reloadCoordination()
                let presentation = notification.userInfo?["presentation"] as? String ?? "visit"
                await MainActor.run {
                    if presentation == "quote" && coordinator.quote != nil {
                        presentChat = false
                        presentedVisit = nil
                        presentQuote = true
                    } else if let visit = nextScheduledVisit {
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
                children: VisitNotesParser.parsePunchList(from: visit.notes ?? ""),
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

                // Inline quote nudge when a quote is attached to this
                // visit. Tap → opens HandymanQuoteReviewSheet so the
                // homeowner can scan line items and approve / decline /
                // open chat.
                if let q = coordinator.quote {
                    QuoteNudgeCard(quote: q, onTap: {
                        Haptics.selection()
                        presentQuote = true
                    })
                }

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

    private var vendorCardSection: some View {
        Group {
            if let handyman = linkedHandyman {
                VendorCard(
                    state: .linked(
                        name: handyman.companyName,
                        phoneURL: handymanPhoneURL
                    ),
                    onTap: { presentChat = true },
                    onCall: nil
                )
            } else {
                VendorCard(state: .empty, onTap: { showFindHandyman = true })
            }
        }
        .padding(.horizontal, TasksV5.pageMargin)
        .padding(.bottom, 20)
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
            Text("Your handyman will help build out your home profile")
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

    private func visitChildrenPunchList(visit: MaintenanceTaskDBRow) -> some View {
        let children = visitChildren
        return VStack(alignment: .leading, spacing: 0) {
            SectionLabel(
                eyebrow: "Punch list for this visit",
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
            Text("Add items so your handyman knows exactly what's on the docket.")
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
            Text("Inbox zero — nothing on your handyman's plate")
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
            await MainActor.run { pendingChecked.remove(id) }
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
            await MainActor.run { addingRecommendedIds.remove(task.id) }
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
            case .onMyWay: return "Handyman on the way"
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
                Text("\(vendor?.companyName ?? "Your handyman") · \(statusLabel)")
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
                .accessibilityLabel("Message handyman")

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
                    .accessibilityLabel("Call handyman")
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

// MARK: - Quote nudge card

/// Small card that surfaces an attached quote on the visit hero. Tap →
/// opens the HandymanQuoteReviewSheet for full line items + approve /
/// decline. Status pill mirrors the provider-side language.
private struct QuoteNudgeCard: View {
    let quote: ProviderQuoteRow
    let onTap: () -> Void

    private var statusPillTone: (background: Color, foreground: Color) {
        switch quote.typedStatus {
        case .sent, .viewed: return (HavenColors.actionPale, HavenColors.actionPressed)
        case .approved:      return (HavenColors.success.opacity(0.12), HavenColors.success)
        case .declined:      return (HavenColors.critical.opacity(0.12), HavenColors.critical)
        default:             return (HavenColors.indigo50, HavenColors.navy800)
        }
    }

    private var statusLabel: String {
        switch quote.typedStatus {
        case .sent, .viewed: return "Awaiting your review"
        case .approved:      return "Approved"
        case .declined:      return "Declined"
        case .draft:         return "Draft"
        default:             return quote.status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(HavenColors.actionPale)
                        .frame(width: 44, height: 44)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(HavenColors.actionPressed)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("QUOTE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(formatCurrency(quote.total))
                        .font(HavenTypography.fraunces(size: 22, weight: 700))
                        .tracking(-0.4)
                        .foregroundStyle(HavenColors.navy900)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(statusLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(statusPillTone.foreground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(statusPillTone.background)
                        )
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            .padding(14)
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

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
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

// MARK: - Coordinator (shared state for visit + chat)

import Supabase

@MainActor
final class HandymanRequestCoordinator: ObservableObject {
    static let shared = HandymanRequestCoordinator()

    @Published private(set) var request: HandymanRequestRow?
    @Published private(set) var messages: [HandymanRequestMessageRow] = []
    @Published private(set) var quote: ProviderQuoteRow?

    private var loadedVisitId: UUID?
    private var realtimeChannel: RealtimeChannelV2?
    private var realtimeListenerTask: Task<Void, Never>?
    private var subscribedRequestId: UUID?

    func clear() {
        request = nil
        messages = []
        quote = nil
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
                let match = candidates
                    .filter { $0.contractorId == vendor.id }
                    .filter { !["completed", "cancelled", "declined"].contains($0.status) }
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
        let quotes = (try? await DatabaseService.shared.fetchProviderQuotes(requestId: requestId)) ?? []
        // Pick the most recent quote that's still in play. Skip
        // superseded/withdrawn — they'd otherwise show as the "latest"
        // because the table sorts updated_at DESC.
        quote = quotes.first { q in
            let s = q.typedStatus
            return s != .superseded && s != .withdrawn
        }
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
                // the visit hero's QuoteNudgeCard appears + the
                // chat's rich quote bubble has live data behind its
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

private extension JSONDecoder.DateDecodingStrategy {
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

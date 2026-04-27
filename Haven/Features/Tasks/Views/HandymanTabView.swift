import SwiftUI

/// V5 Handyman screen — focused punch-list-and-vendor surface that lives
/// behind the title-switcher in `TasksHubView`. Replaces the embedded
/// `HandymanHubView` for the Tasks tab. Property-scoped and the legacy
/// HandymanHubView are untouched.
///
/// Sections (top-down):
///   1. HeaderSwitcher (title + mode chevron + "+" button)
///   2. VisitHero (indigo gradient + Schedule visit CTA + phone shortcut)
///   3. VendorCard (linked handyman or empty-state Find a handyman)
///   4. PunchList (checkboxes + durations + "+ N more")
///   5. Recommended (salmon-icon rows with "+" to add to punch list)
///   6. WhatWeHandleBand (explainer band — bulleted list)
///   7. VisitHistory (dashed empty card or list)
struct HandymanTabView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var maintenanceVM = MaintenanceViewModel.shared
    @StateObject private var punchListVM = HandymanPunchListViewModel()

    @State private var pendingChecked: Set<String> = []
    @State private var addingRecommendedIds: Set<UUID> = []
    @State private var showAddMenu = false
    @State private var pushTarget: HandymanPush?
    @State private var showFindHandyman = false
    @State private var showScheduleSheet = false

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

    /// Visible punch list items (not yet checked in this session).
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

    private var totalPunchCount: Int { punchListVM.entries.count }

    private var extraPunchCount: Int {
        max(totalPunchCount - visiblePunchItems.count - pendingChecked.count, 0)
    }

    private var recommendedTasks: [MaintenanceTaskDBRow] {
        let punchSourceIds = Set(punchListVM.entries.compactMap { $0.sourceTaskId })
        let candidates = maintenanceVM.tasks.filter { task in
            guard !punchSourceIds.contains(task.id) else { return false }
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
        }
        .refreshable {
            if let householdId {
                await punchListVM.load(householdId: householdId, propertyId: propertyId)
            }
            await maintenanceVM.loadTasks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task {
                if let householdId {
                    await punchListVM.load(householdId: householdId, propertyId: propertyId)
                }
                await maintenanceVM.loadTasks()
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
    }

    // MARK: - Sections

    private var visitHeroSection: some View {
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

    private var vendorCardSection: some View {
        Group {
            if let handyman = linkedHandyman {
                VendorCard(
                    state: .linked(
                        name: handyman.companyName,
                        phoneURL: handymanPhoneURL
                    ),
                    onTap: { pushTarget = .vendorDetail(handyman) }
                )
            } else {
                VendorCard(state: .empty) { showFindHandyman = true }
            }
        }
        .padding(.horizontal, TasksV5.pageMargin)
        .padding(.bottom, 20)
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

    @ViewBuilder
    private var punchListSection: some View {
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
            pushTarget = .punchListFull
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
        // Optimistic check — show the green-fill animation, then archive.
        withAnimation(.easeInOut(duration: 0.15)) {
            pendingChecked.insert(id)
        }
        guard let entry = punchListVM.entries.first(where: { $0.id == id }) else { return }
        Task {
            // Hold the green check for ~500ms so the state transition reads.
            try? await Task.sleep(nanoseconds: 500_000_000)
            await punchListVM.archive(entry: entry)
            await MainActor.run { pendingChecked.remove(id) }
        }
    }

    private func addToPunchList(task: MaintenanceTaskDBRow) {
        guard let householdId, let propertyId else { return }
        addingRecommendedIds.insert(task.id)
        Task {
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
    }

    // MARK: - Navigation

    enum HandymanPush: Hashable, Identifiable {
        case punchListFull
        case vendorDetail(ContractorRow)

        var id: String {
            switch self {
            case .punchListFull: return "punchListFull"
            case .vendorDetail(let c): return "vendor-\(c.id.uuidString)"
            }
        }

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
        case .vendorDetail:
            // Push the existing contractor detail flow. Notification routing
            // keeps this screen out of the contractors-detail import graph.
            EmptyView()
                .onAppear { pushTarget = nil }
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
}

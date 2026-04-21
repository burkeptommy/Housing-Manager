import SwiftUI

/// Phase 54B: Handyman punch list. Accumulating list of small items the
/// homeowner wants the handyman to handle on the next visit. Items sit
/// indefinitely (Things-3-"Anytime" model) until the user schedules a
/// visit — at which point they're rolled into the existing
/// Handyman:spring / Handyman:fall bundled task.
///
/// Entry points (Phase 54B.3): Property tab section; Maintenance task
/// detail sheet ("Add to handyman list" action); Recommended for your
/// home (Phase 54C).
struct HandymanPunchListView: View {
    let householdId: UUID
    let propertyId: UUID?

    @StateObject private var viewModel = HandymanPunchListViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showAddSheet = false
    @State private var showScheduleSheet = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView("Loading punch list...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                emptyState
            } else {
                itemList
            }
        }
        .background(HavenColors.background)
        .navigationTitle("Handyman Punch List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.light()
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(HavenColors.navy)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !viewModel.items.isEmpty {
                bottomActionBar
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                AddHandymanPunchItemSheet(
                    householdId: householdId,
                    propertyId: propertyId,
                    onAdded: {
                        Task { await viewModel.load(householdId: householdId) }
                    }
                )
            }
        }
        // Phase 60: replaced the seasonal auto-fold alert with a proper
        // scheduling sheet. Auto-folding into the NEXT Handyman:spring
        // or Handyman:fall task (Oct 1 this year, Apr 2027, etc.)
        // was bad UX — if someone has 6 items accumulated in April and
        // wants them handled THIS WEEK, forcing them into a bundle
        // 5 months out is wrong. Now the user picks a visit date and
        // optionally selects a handyman contractor. Seasonal bundles
        // keep rolling (reconciler-seeded) as standing rhythm cards,
        // but ad-hoc visits are first-class.
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleHandymanVisitSheet(
                itemCount: viewModel.items.count,
                householdId: householdId,
                propertyId: propertyId,
                onSchedule: { scheduledDate, contractor in
                    Task {
                        await viewModel.scheduleAdHocVisit(
                            householdId: householdId,
                            propertyId: propertyId,
                            scheduledDate: scheduledDate,
                            contractor: contractor
                        )
                        Haptics.success()
                    }
                }
            )
            .presentationDetents([.medium])
        }
        // Phase 60: after `scheduleNextVisit` appends the punch items to
        // an existing handyman task, open that task's detail sheet so
        // the user actually sees where their items went and can call
        // the handyman from the card's quick-action row. Without this
        // the items silently disappeared into a task buried months
        // ahead on the schedule, with no feedback beyond a fleeting
        // toast.
        .sheet(item: $viewModel.justScheduledTask) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(task: task)
            }
            .presentationDetents([.medium, .large])
        }
        .overlay(alignment: .top) {
            if let toast = viewModel.toast {
                Text(toast)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .padding(.horizontal, HavenTheme.spacing16)
                    .padding(.vertical, HavenTheme.spacing8)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .havenShadow()
                    .padding(.top, HavenTheme.spacing8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: viewModel.toast != nil)
        .task {
            await viewModel.load(householdId: householdId)
        }
        .trackScreen("HandymanPunchListView")
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Your punch list is empty", systemImage: "hammer.fill")
        } description: {
            Text("Add anything you've been meaning to ask your handyman about. Small repairs, dryer vent cleaning, sump pump testing, a squeaky door. We'll hand the whole list to them on the next visit.")
        } actions: {
            HavenButton(
                title: "Add your first item",
                action: { showAddSheet = true },
                icon: "plus",
                isFullWidth: false
            )
        }
    }

    // MARK: - Item list

    private var itemList: some View {
        List {
            Section {
                Text("Items to fold into your next visit")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
            }

            ForEach(viewModel.items) { item in
                punchItemCard(item)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(HavenColors.background)
        .refreshable {
            await viewModel.load(householdId: householdId)
        }
    }

    private func punchItemCard(_ item: HandymanPunchItemRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 32, height: 32)
                        .background(HavenColors.beige200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        if let description = item.description, !description.isEmpty {
                            Text(description)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: 0)

                    Button {
                        Haptics.light()
                        Task {
                            await viewModel.archive(item: item)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(item.title) from punch list")
                }

                if !item.metadataChips.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(item.metadataChips, id: \.self) { chip in
                            Text(chip)
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(HavenColors.beige200)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bottom action bar

    private var bottomActionBar: some View {
        VStack(spacing: HavenTheme.spacing8) {
            HavenButton(
                title: "Schedule next handyman visit",
                action: {
                    showScheduleSheet = true
                },
                style: .primary,
                icon: "calendar.badge.plus",
                isLoading: viewModel.isScheduling
            )

            HavenButton(
                title: "Add another item",
                action: {
                    showAddSheet = true
                },
                style: .secondary,
                icon: "plus"
            )
        }
        .padding(.horizontal, HavenTheme.spacing16)
        .padding(.vertical, HavenTheme.spacing12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Add sheet

private struct AddHandymanPunchItemSheet: View {
    let householdId: UUID
    let propertyId: UUID?
    let onAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var notes = ""
    @State private var estimatedMinutes: Int? = nil
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let effortPresets: [(label: String, minutes: Int)] = [
        ("5 min", 5),
        ("15 min", 15),
        ("30 min", 30),
        ("1 hr", 60),
    ]

    var body: some View {
        Form {
            Section {
                TextField("What needs fixing?", text: $title)
                    .font(HavenTypography.body)
            } header: {
                Text("Title")
            } footer: {
                Text("e.g. \"Dryer vent is clogged\" or \"Front porch light is flickering\"")
                    .font(HavenTypography.caption)
            }

            Section("Details (optional)") {
                TextField("Describe the issue", text: $description, axis: .vertical)
                    .lineLimit(2...5)
            }

            Section {
                HStack {
                    ForEach(effortPresets, id: \.minutes) { preset in
                        Button {
                            Haptics.selection()
                            estimatedMinutes = (estimatedMinutes == preset.minutes) ? nil : preset.minutes
                        } label: {
                            Text(preset.label)
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(estimatedMinutes == preset.minutes ? HavenColors.textOnNavy : HavenColors.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(estimatedMinutes == preset.minutes ? HavenColors.navy : HavenColors.beige200)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Rough effort (optional)")
            } footer: {
                Text("Helps your handyman quote the visit.")
                    .font(HavenTypography.caption)
            }

            Section("Notes (optional)") {
                TextField("Anything else they should know?", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }
            }
        }
        .navigationTitle("Add to punch list")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(HavenColors.navy)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Add")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(HavenColors.navy)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        var insert = HandymanPunchItemInsert(
            householdId: householdId,
            propertyId: propertyId,
            title: trimmedTitle
        )
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        insert.description = trimmedDescription.isEmpty ? nil : trimmedDescription
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        insert.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        insert.estimatedMinutes = estimatedMinutes
        // Stamp the creator when we can resolve the session quickly.
        // RLS enforces household membership, so nil `addedByUserId` is
        // safe — it just means audit history is incomplete for this row.
        if let session = await HavenSupabase.safeSession(timeout: 1.0) {
            insert.addedByUserId = session.user.id
        }

        do {
            _ = try await DatabaseService.shared.createHandymanPunchItem(insert)
            Analytics.track(.handymanPunchItemAdded, [
                "source": "manual",
                "has_effort_estimate": estimatedMinutes != nil,
            ])
            Haptics.success()
            onAdded()
            dismiss()
        } catch {
            errorMessage = "Couldn't save: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}

// MARK: - View model

@MainActor
final class HandymanPunchListViewModel: ObservableObject {
    @Published private(set) var items: [HandymanPunchItemRow] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isScheduling = false
    @Published var toast: String?
    /// Phase 60: the handyman visit task that `scheduleNextVisit` most
    /// recently appended items to. The view presents this via a sheet
    /// so the user sees the bundled task instead of the confusing
    /// "punch list empty" state with no follow-up path.
    @Published var justScheduledTask: MaintenanceTaskDBRow?

    private let db = DatabaseService.shared

    /// Season label displayed in the schedule-confirmation copy. Spring
    /// Mar-Aug, Fall Sep-Feb. When the reconciler-created Handyman
    /// bundle exists for both seasons, the scheduler uses whichever
    /// has the earlier due date anyway.
    var nextVisitSeasonLabel: String {
        let month = Calendar.current.component(.month, from: Date())
        return (3...8).contains(month) ? "Spring" : "Fall"
    }

    private var nextVisitBundleId: String {
        "Handyman:" + (nextVisitSeasonLabel.lowercased())
    }

    private var nextVisitBundleTitle: String {
        "\(nextVisitSeasonLabel) Handyman Visit"
    }

    func load(householdId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let raw = try await db.fetchPendingHandymanPunchItems(householdId: householdId)
            items = Self.deduplicated(raw)
        } catch {
            print("[HandymanPunchListViewModel] load failed: \(error)")
            items = []
        }
    }

    /// Phase 56.6: Dedup pending punch items that share the same
    /// `sourceTaskId` — a side effect of the pre-56.6 card + detail
    /// sheet both allowing insert without checking for existing rows.
    /// Keeps the newest item per source task (by `createdAt` desc) so
    /// anything the user added most recently stays visible. Items
    /// without a `sourceTaskId` (manual entries, recommendation adds)
    /// are never dedup'd — each one represents a distinct decision.
    ///
    /// Paired with the create-time guards in `MaintenanceScheduleView.
    /// addTaskToHandymanPunchList` and `MaintenanceTaskDetailSheet.
    /// addToPunchListJustThisTime` so duplicates don't accumulate in
    /// the first place, but this is the belt to that suspenders —
    /// cleans up anything that slipped through, including pre-56.6
    /// rows still on the table from earlier testing.
    static func deduplicated(_ items: [HandymanPunchItemRow]) -> [HandymanPunchItemRow] {
        var seen: Set<UUID> = []
        var result: [HandymanPunchItemRow] = []
        let sorted = items.sorted { $0.createdAt > $1.createdAt }
        for item in sorted {
            if let sourceId = item.sourceTaskId {
                if !seen.contains(sourceId) {
                    seen.insert(sourceId)
                    result.append(item)
                }
            } else {
                result.append(item)
            }
        }
        // Preserve the pre-dedup ordering so the UI doesn't visibly
        // resort items — this keeps "oldest at top" if that was the
        // original order.
        let resultIds = Set(result.map(\.id))
        return items.filter { resultIds.contains($0.id) }
    }

    func archive(item: HandymanPunchItemRow) async {
        do {
            try await db.archiveHandymanPunchItem(id: item.id)
            items.removeAll { $0.id == item.id }
            Analytics.track(.handymanPunchItemRemoved, ["source": item.source])
        } catch {
            print("[HandymanPunchListViewModel] archive failed: \(error)")
        }
    }

    /// Phase 60: schedule an ad-hoc handyman visit on a user-chosen date.
    /// Creates a fresh `maintenance_tasks` row with `scheduled_date` set
    /// (so it lands in the Maintenance tab's "Scheduled" bucket) and
    /// the punch list bundled into the notes as a "What's included"
    /// checklist. Optionally assigns a handyman contractor so the task
    /// card shows their Call/Email quick actions.
    ///
    /// This replaces the pre-Phase-60 seasonal auto-fold: users with
    /// 6 items accumulated in April don't want them forced into the
    /// October seasonal bundle — they want a visit this week.
    func scheduleAdHocVisit(
        householdId: UUID,
        propertyId: UUID?,
        scheduledDate: Date,
        contractor: ContractorRow?
    ) async {
        guard !items.isEmpty else { return }
        guard let propertyId else {
            showToast("Select a property to schedule a handyman visit.")
            return
        }
        isScheduling = true
        defer { isScheduling = false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: scheduledDate)

        // Build the bundled notes so the handyman task reads like a
        // work order: what's included + who requested when.
        let bullets = items.map { item -> String in
            var line = "- " + item.title
            if let mins = item.estimatedMinutes {
                line += " (~\(mins) min)"
            }
            return line
        }.joined(separator: "\n")
        let notes = "What's included:\n\(bullets)"

        var insert = MaintenanceTaskInsert(
            householdId: householdId,
            title: "Handyman visit",
            frequency: "Once",
            nextDueDate: dateStr
        )
        insert.propertyId = propertyId
        insert.scheduledDate = dateStr
        insert.description = "The handyman will work through this visit's punch list."
        insert.priority = "medium"
        insert.isTemplateBased = false
        insert.seasonalTiming = nil
        insert.isDiy = false
        insert.professionalRequired = true
        insert.costRange = "$200-600"
        insert.assignmentType = "vendor"
        insert.assignedContractorId = contractor?.id
        insert.needsVendor = contractor == nil
        insert.notes = notes

        do {
            let created = try await db.createMaintenanceTask(insert)
            let ids = items.map { $0.id }
            try await db.completePunchItems(ids: ids, visitTaskId: created.id)

            Analytics.track(.handymanPunchListScheduled, [
                "item_count": items.count,
                "mode": "ad_hoc",
                "vendor_assigned": contractor != nil
            ])

            items.removeAll()
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            try? await Task.sleep(nanoseconds: 150_000_000)
            justScheduledTask = created
        } catch {
            print("[HandymanPunchListViewModel] ad-hoc schedule failed: \(error)")
            showToast("Couldn't schedule — please try again.")
        }
    }

    /// Phase 54B (retained for seasonal-bundle callers — e.g. the Dashboard
    /// Handyman suggestion card that intentionally targets the seasonal
    /// task). Finds or creates the Handyman:spring / Handyman:fall bundle,
    /// appends the punch items, marks them completed.
    func scheduleNextVisit(householdId: UUID, propertyId: UUID?) async {
        guard !items.isEmpty else { return }
        isScheduling = true
        defer { isScheduling = false }

        do {
            let targetBundleId = nextVisitBundleId
            let targetTitle = nextVisitBundleTitle
            let taskId = try await findOrCreateHandymanVisit(
                householdId: householdId,
                propertyId: propertyId,
                bundleId: targetBundleId,
                bundleTitle: targetTitle
            )

            try await appendItemsToVisitNotes(taskId: taskId)

            let ids = items.map { $0.id }
            try await db.completePunchItems(ids: ids, visitTaskId: taskId)

            Analytics.track(.handymanPunchListScheduled, [
                "item_count": items.count,
                "bundle_id": targetBundleId,
            ])

            // Phase 60: fetch the updated task so we can present its
            // detail sheet — the user needs to SEE the bundled list and
            // reach the handyman's contact info, otherwise the punch
            // list just vanishes with nowhere to go. Without this the
            // "schedule" action feels silent and confusing.
            let refreshedList = (try? await db.fetchMaintenanceTasks(propertyId: propertyId)) ?? []
            let refreshed = refreshedList.first { $0.id == taskId }

            items.removeAll()
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            // Wait a tick so the dismiss of the parent sheet animation
            // doesn't fight with the follow-on sheet presentation.
            try? await Task.sleep(nanoseconds: 150_000_000)
            justScheduledTask = refreshed
            if refreshed == nil {
                showToast("Added to your \(targetTitle)")
            }
        } catch {
            print("[HandymanPunchListViewModel] schedule failed: \(error)")
            showToast("Couldn't schedule — please try again.")
        }
    }

    /// Returns an existing active Handyman:[season] task id for the
    /// given property, or creates a fresh one at the seasonal-correct
    /// anchor date if none exists. Filters on `templateId == bundleId`
    /// and the Phase-17b archive flag so rows that got soft-deleted
    /// don't get re-used.
    private func findOrCreateHandymanVisit(
        householdId: UUID,
        propertyId: UUID?,
        bundleId: String,
        bundleTitle: String
    ) async throws -> UUID {
        let tasks = try await db.fetchMaintenanceTasks(propertyId: propertyId)
        if let match = tasks.first(where: { task in
            task.templateId == bundleId
                && task.isArchived != true
                && task.lastCompletedDate == nil
        }) {
            return match.id
        }

        // Fallback: create the bundle task from scratch.
        guard let propertyId else {
            // Without a property we can't create a maintenance_task row —
            // the schema requires property_id OR vehicle_id. Signal the
            // caller to stop.
            throw NSError(
                domain: "HandymanPunchList",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Select a property to schedule a handyman visit."]
            )
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let month = Calendar.current.component(.month, from: Date())
        let anchorMonth = (3...8).contains(month) ? 4 : 10
        var comps = DateComponents()
        comps.year = Calendar.current.component(.year, from: Date())
        comps.month = anchorMonth
        comps.day = 1
        let baseAnchor = Calendar.current.date(from: comps) ?? Date()
        let anchor: Date
        if baseAnchor < Date() {
            // Push to next year if this year's anchor already passed.
            comps.year = comps.year! + 1
            anchor = Calendar.current.date(from: comps) ?? baseAnchor
        } else {
            anchor = baseAnchor
        }

        var insert = MaintenanceTaskInsert(
            householdId: householdId,
            title: bundleTitle,
            frequency: "Annually",
            nextDueDate: formatter.string(from: anchor)
        )
        insert.propertyId = propertyId
        insert.description = "The handyman will work through this visit's punch list."
        insert.priority = "Medium"
        insert.isTemplateBased = true
        insert.templateId = bundleId
        insert.seasonalTiming = anchorMonth == 4 ? "Spring" : "Fall"
        insert.isDiy = false
        insert.professionalRequired = true
        insert.costRange = "$200-600"
        insert.assignmentType = "vendor"
        insert.needsVendor = true
        insert.notes = "What's included:\n"

        let created = try await db.createMaintenanceTask(insert)
        return created.id
    }

    /// Appends the pending punch items to the visit task's notes so
    /// they render inside the Maintenance card as a checklist. We
    /// preserve any existing "What's included:" template content above
    /// the "Punch list:" block and avoid duplicating items if the user
    /// schedules twice.
    private func appendItemsToVisitNotes(taskId: UUID) async throws {
        let all = try await db.fetchMaintenanceTasks()
        guard let task = all.first(where: { $0.id == taskId }) else { return }

        let bullets = items.map { item -> String in
            var line = "- " + item.title
            if let mins = item.estimatedMinutes {
                line += " (~\(mins) min)"
            }
            return line
        }.joined(separator: "\n")

        let existingNotes = task.notes ?? ""
        let separator = "\n\nPunch list (added \(shortDateString())):\n"
        let newNotes: String
        if existingNotes.isEmpty {
            newNotes = "Punch list (added \(shortDateString())):\n" + bullets
        } else {
            newNotes = existingNotes + separator + bullets
        }

        var update = MaintenanceTaskUpdate()
        update.notes = newNotes
        _ = try await db.updateMaintenanceTask(id: taskId, update)
    }

    private func shortDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }

    private func showToast(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { self.toast = nil }
        }
    }
}

// MARK: - Schedule Handyman Visit Sheet (Phase 60)

/// Presents a compact date + vendor picker so the user can schedule an
/// ad-hoc handyman visit tied to their punch list. Replaces the
/// pre-60 "fold into seasonal bundle" alert — users wanted visits
/// handled NOW (or on a date they picked), not in five months.
struct ScheduleHandymanVisitSheet: View {
    let itemCount: Int
    let householdId: UUID
    let propertyId: UUID?
    let onSchedule: (Date, ContractorRow?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scheduledDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var selectedContractorId: UUID?
    @State private var contractors: [ContractorRow] = []

    private var handymanContractors: [ContractorRow] {
        contractors.filter { c in
            if let category = c.category,
               category.localizedCaseInsensitiveContains("handy") { return true }
            if let specialties = c.specialties,
               specialties.contains(where: { $0.localizedCaseInsensitiveContains("handy") }) {
                return true
            }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Haven will create a scheduled visit for \(itemCount) item\(itemCount == 1 ? "" : "s"). Your handyman gets the full punch list in the task notes.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Section("When") {
                    DatePicker(
                        "Visit date",
                        selection: $scheduledDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .tint(HavenColors.navy800)
                }

                if !contractors.isEmpty {
                    Section("Handyman (optional)") {
                        Picker("Vendor", selection: $selectedContractorId) {
                            Text("Pick later").tag(nil as UUID?)
                            let pickerOptions = handymanContractors.isEmpty
                                ? contractors
                                : handymanContractors
                            ForEach(pickerOptions) { contractor in
                                Text(contractor.companyName).tag(contractor.id as UUID?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Schedule handyman visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.action)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        let contractor = contractors.first { $0.id == selectedContractorId }
                        onSchedule(scheduledDate, contractor)
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.action)
                    .fontWeight(.semibold)
                }
            }
            .task {
                contractors = (try? await DatabaseService.shared.fetchContractors()) ?? []
                if selectedContractorId == nil, let first = handymanContractors.first {
                    selectedContractorId = first.id
                }
            }
        }
    }
}

// MARK: - Display helpers

private extension HandymanPunchItemRow {
    /// Compact metadata chips rendered at the bottom of each card:
    /// effort estimate, cost estimate, and a source badge when the
    /// item came from somewhere other than manual entry.
    var metadataChips: [String] {
        var chips: [String] = []
        if let mins = estimatedMinutes {
            chips.append("~\(mins) min")
        }
        if let cost = estimatedCostRange, !cost.isEmpty {
            chips.append(cost)
        }
        switch source {
        case "maintenance_task": chips.append("From task")
        case "recommended":      chips.append("From recommendations")
        default:                 break
        }
        return chips
    }
}

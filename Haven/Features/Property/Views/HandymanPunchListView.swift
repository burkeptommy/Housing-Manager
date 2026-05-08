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
    /// Phase 67E/F: Punch → Task promotion. When set, presents
    /// `PromotePunchItemSheet` for the user to pick a date. Only
    /// `.manual` entries are promotable — `.task` rows are already on
    /// the maintenance rail.
    @State private var promotingEntry: HandymanPunchItemRow?
    /// Phase 95 — inline title editing. Holds the punch item being
    /// edited; its title is bound to `editedTitle` while the alert is
    /// open. Only `.manual` items are editable (template-seeded items
    /// derive their title from the catalog and shouldn't drift).
    @State private var editingItem: HandymanPunchItemRow?
    @State private var editedTitle: String = ""

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                ProgressView("Loading punch list...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.entries.isEmpty {
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
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !viewModel.entries.isEmpty {
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
                itemCount: viewModel.entries.count,
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
        // Phase 67E/F: Punch → Task promotion. The sheet builds a
        // `MaintenanceTaskInsert` from the punch item + a user-picked
        // date, archives the punch item with reason "promoted_to_task",
        // and refreshes both surfaces.
        .sheet(item: $promotingEntry) { item in
            PromotePunchItemSheet(item: item) { scheduledDate in
                Task {
                    await viewModel.promoteToTask(
                        item: item,
                        scheduledDate: scheduledDate,
                        householdId: householdId,
                        propertyId: propertyId
                    )
                    Haptics.success()
                }
            }
            .presentationDetents([.medium])
        }
        // Phase 95 — inline title edit alert. Bound to `editingItem` so a
        // long-press on a manual punch row opens this with the current
        // title prefilled. Saves through the view model's update helper.
        .alert("Edit punch item", isPresented: Binding(
            get: { editingItem != nil },
            set: { if !$0 { editingItem = nil } }
        )) {
            TextField("Title", text: $editedTitle)
            Button("Save") {
                if let item = editingItem {
                    let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty, trimmed != item.title {
                        Task {
                            await viewModel.updateTitle(item: item, title: trimmed, householdId: householdId, propertyId: propertyId)
                        }
                    }
                }
                editingItem = nil
            }
            Button("Cancel", role: .cancel) {
                editingItem = nil
            }
        } message: {
            Text("What needs fixing? Keep it short. The contractor reads this on the day of the visit.")
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
            await viewModel.load(householdId: householdId, propertyId: propertyId)
        }
        .trackScreen("HandymanPunchListView")
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Your punch list is empty", systemImage: "hammer.fill")
        } description: {
            Text("Add anything you've been meaning to ask your contractor about. Small repairs, dryer vent cleaning, sump pump testing, a squeaky door. We'll hand the whole list to them on the next visit.")
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

            ForEach(viewModel.entries) { entry in
                punchItemCard(entry)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(HavenColors.background)
        .refreshable {
            await viewModel.load(householdId: householdId, propertyId: propertyId)
        }
    }

    private func punchItemCard(_ entry: HandymanPunchEntry) -> some View {
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
                        Text(entry.title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        if let description = entry.description, !description.isEmpty {
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
                            await viewModel.archive(entry: entry)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(entry.title) from punch list")
                }

                if !entry.metadataChips.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(entry.metadataChips, id: \.self) { chip in
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
            // Phase 95 — context-menu edit + remove. The X-button stays as
            // the primary remove affordance; this gives long-press users
            // an explicit Edit + Remove pair without crowding the row.
            .contextMenu {
                if let manual = entry.manualPunchItem {
                    Button {
                        Haptics.light()
                        editedTitle = manual.title
                        editingItem = manual
                    } label: {
                        Label("Edit title", systemImage: "pencil")
                    }
                }
                Button(role: .destructive) {
                    Haptics.medium()
                    Task { await viewModel.archive(entry: entry) }
                } label: {
                    Label("Remove from punch list", systemImage: "trash")
                }
            }
        }
        // Phase 67E/F: long-press to promote a manual punch item back to
        // a scheduled maintenance_tasks row. Hidden for `.task` entries
        // because those are already on the maintenance rail.
        .contextMenu {
            if let manual = entry.manualPunchItem {
                Button {
                    Haptics.light()
                    promotingEntry = manual
                } label: {
                    Label("Schedule as task", systemImage: "calendar.badge.plus")
                }
            }
        }
    }

    // MARK: - Bottom action bar

    private var bottomActionBar: some View {
        VStack(spacing: HavenTheme.spacing8) {
            HavenButton(
                title: "Schedule next contractor visit",
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

            // Phase 80 — Chez Concierge entry. When the user has a punch
            // list assembled but no handyman to call, hand the whole job
            // off to Tom — he'll find a vetted handyman, share the list,
            // and book the visit.
            ChezEntryButton(
                category: .findHandyman,
                label: "Have Chez find me a contractor",
                caption: "Chez finds a vetted local pro and books the visit.",
                context: chezPunchContext
            )
            .padding(.top, HavenTheme.spacing4)
        }
        .padding(.horizontal, HavenTheme.spacing16)
        .padding(.vertical, HavenTheme.spacing12)
        .background(.ultraThinMaterial)
    }

    /// Phase 80 — context for the Chez handyman handoff. Sends the full
    /// punch list as a newline-joined string plus the count, so Tom has
    /// the visible inventory at a glance without opening another tab.
    /// `viewModel.entries` is already the visible (non-archived /
    /// non-completed) set, so no extra filtering is needed.
    private var chezPunchContext: [String: String] {
        let pending = viewModel.entries
        var c: [String: String] = [
            "punch_item_count": String(pending.count),
            "property_id": propertyId?.uuidString ?? "",
        ]
        if !pending.isEmpty {
            let titles = pending.prefix(20).map { "• \($0.title)" }.joined(separator: "\n")
            c["punch_list_preview"] = titles
        }
        return c
    }
}

// MARK: - Add sheet

/// Used directly by `HandymanHubView` from the Tasks tab in addition to
/// the legacy `HandymanPunchListView` route.
struct AddHandymanPunchItemSheet: View {
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

    /// Phase 95 (gap #43): library of typical handyman items so the user
    /// doesn't start at a blank text field every time. Tapping a chip
    /// prefills title / description / effort estimate; the user can
    /// then tweak before saving. Items chosen for HNW Westchester
    /// audience: not-quite-emergency annoyances that pile up between
    /// seasonal visits. Keep the list ~12 long so the chip strip fits
    /// without scrolling for ages.
    private struct LibraryItem: Hashable {
        let title: String
        let description: String
        let minutes: Int
    }
    private let library: [LibraryItem] = [
        LibraryItem(title: "Replace porch light bulb", description: "Standard replacement, no fixture work.", minutes: 15),
        LibraryItem(title: "Fix dripping faucet", description: "Sink or tub. Likely a worn washer or cartridge.", minutes: 30),
        LibraryItem(title: "Caulk around tub or shower", description: "Old caulk pulled, surface dried, fresh bead applied.", minutes: 60),
        LibraryItem(title: "Tighten loose cabinet door / drawer", description: "Hinge realignment or replacement.", minutes: 15),
        LibraryItem(title: "Patch and paint nail hole", description: "Spackle, sand, touch-up paint.", minutes: 30),
        LibraryItem(title: "Re-hang fallen curtain rod", description: "Re-anchor with proper hardware.", minutes: 30),
        LibraryItem(title: "Replace HVAC filters", description: "All return registers. Bring sizes.", minutes: 30),
        LibraryItem(title: "Test and replace smoke detector batteries", description: "Every floor + bedroom area.", minutes: 30),
        LibraryItem(title: "Adjust sticking interior door", description: "Plane the edge or shim the hinges.", minutes: 30),
        LibraryItem(title: "Tighten loose toilet seat / handle", description: "Bolts, brackets, or replacement.", minutes: 15),
        LibraryItem(title: "Reseat loose deck board / handrail screw", description: "Visual check and tighten loose hardware.", minutes: 30),
        LibraryItem(title: "Replace dryer vent hood / lint screen", description: "External flap or interior screen as needed.", minutes: 30),
    ]

    var body: some View {
        Form {
            // Phase 95 (gap #43) — library chip rail. Hidden once the
            // user starts typing so it doesn't compete with their words.
            if title.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(library, id: \.self) { item in
                                Button {
                                    Haptics.selection()
                                    title = item.title
                                    description = item.description
                                    estimatedMinutes = item.minutes
                                } label: {
                                    Text(item.title)
                                        .font(HavenTypography.uiLabelSmall)
                                        .foregroundStyle(HavenColors.textPrimary)
                                        .lineLimit(1)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(HavenColors.beige200)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                } header: {
                    Text("Common items")
                } footer: {
                    Text("Tap to prefill. You can edit before saving.")
                        .font(HavenTypography.caption)
                }
            }

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
                Text("Helps your contractor quote the visit.")
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
                    .foregroundStyle(HavenColors.textPrimary)
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
                .foregroundStyle(HavenColors.textPrimary)
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

// MARK: - Promote sheet (Phase 67E/F)

/// Punch → Task promotion. The user picks a date for the new task; we
/// create a `maintenance_tasks` row with `scheduled_date` set and
/// archive the source punch item. Inverse of the existing
/// `MaintenanceTaskDetailSheet.addToPunchListJustThisTime` flow —
/// gives the user a way to take a long-tail punch-list item and pin
/// it to a specific date when they want to handle it themselves.
struct PromotePunchItemSheet: View {
    let item: HandymanPunchItemRow
    let onConfirm: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scheduledDate: Date = Self.defaultDate()

    private static func defaultDate() -> Date {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: .now)
        let daysUntilMonday = (9 - weekday) % 7
        let offset = daysUntilMonday == 0 ? 7 : daysUntilMonday
        return cal.date(byAdding: .day, value: offset, to: .now) ?? .now
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        if let description = item.description, !description.isEmpty {
                            Text(description)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                } footer: {
                    Text("This moves the item off your punch list and onto your schedule for the date you pick.")
                        .font(HavenTypography.caption)
                }

                Section {
                    DatePicker(
                        "Schedule for",
                        selection: $scheduledDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                }
            }
            .navigationTitle("Schedule as task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schedule") {
                        onConfirm(scheduledDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Unified punch list entry (Chez v1)

/// Wraps the two data sources that compose the handyman punch list:
///
///   1. `manual` — explicit `handyman_punch_items` rows the user added
///      (or that came from "Add to handyman" on a task / a recommended
///      service). These have effort estimates, descriptions, and the
///      legacy archive path.
///   2. `task` — routine-parented `maintenance_tasks` rows that
///      Day1TaskCurator routed onto the handyman routine. Day1Curator
///      sets `parent_routine_id` so they're hidden from the regular
///      maintenance buckets and surface here as work to bundle into
///      the next visit.
///
/// Both render through the same card. The display layer doesn't care
/// which side a row came from — only the source pill differs.
enum HandymanPunchEntry: Identifiable {
    case manual(HandymanPunchItemRow)
    case task(MaintenanceTaskDBRow)

    /// Stable, namespaced id so SwiftUI's diff doesn't collide a
    /// punch_item with a maintenance_task that happen to share a
    /// UUID (defensive — they're separate tables, but better safe).
    var id: String {
        switch self {
        case .manual(let row): return "punch_" + row.id.uuidString
        case .task(let row): return "task_" + row.id.uuidString
        }
    }

    var title: String {
        switch self {
        case .manual(let row): return row.title
        case .task(let row): return row.title
        }
    }

    var description: String? {
        switch self {
        case .manual(let row): return row.description
        case .task(let row): return row.description
        }
    }

    var estimatedMinutes: Int? {
        switch self {
        case .manual(let row): return row.estimatedMinutes
        case .task: return nil
        }
    }

    /// Used by HandymanHubView to dedup recommended-task suggestions
    /// against punch list entries. Manual rows expose `sourceTaskId`;
    /// task rows ARE their own source — return their `id`.
    var sourceTaskId: UUID? {
        switch self {
        case .manual(let row): return row.sourceTaskId
        case .task(let row): return row.id
        }
    }

    /// Legacy callsites compare against `.manual(...).id` (UUID).
    /// Keeps the existing archive route working without leaking the
    /// enum shape into call sites that only care about the punch_item.
    var manualPunchItem: HandymanPunchItemRow? {
        if case .manual(let row) = self { return row }
        return nil
    }

    var taskRow: MaintenanceTaskDBRow? {
        if case .task(let row) = self { return row }
        return nil
    }

    /// Compact metadata chips rendered at the bottom of each card.
    var metadataChips: [String] {
        var chips: [String] = []
        if let mins = estimatedMinutes {
            chips.append("~\(mins) min")
        }
        switch self {
        case .manual(let row):
            switch row.source {
            case "maintenance_task": chips.append("From task")
            case "recommended": chips.append("From recommendations")
            default: break
            }
        case .task:
            chips.append("From maintenance")
        }
        return chips
    }
}

// MARK: - View model

@MainActor
final class HandymanPunchListViewModel: ObservableObject {
    /// Combined unified list of every entry — manual punch_items + Day1-
    /// curator-routed maintenance tasks. Display-layer source of truth.
    @Published private(set) var entries: [HandymanPunchEntry] = []
    /// Manual-punch-items-only — preserved for back-compat with code
    /// paths that need the punch_item-specific shape (e.g. dedup against
    /// recommended tasks via `sourceTaskId`).
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

    func load(householdId: UUID, propertyId: UUID? = nil) async {
        isLoading = true
        defer { isLoading = false }

        // Chez v1 unified load — fetch BOTH manual punch_items AND any
        // maintenance_tasks that should belong on the handyman list.
        // "Should belong" is broader than just "parent_routine_id ==
        // handyman_recurring" because the user has handyman tasks
        // pre-Day1Curator that don't carry that linkage. The full
        // eligibility set:
        //   1. parent_routine_id matches the household's handyman_recurring routine
        //   2. category resolves to "Handyman" via VendorTaskGrouping
        //   3. templateId starts with "Handyman:" (catches handyman
        //      bundle children even when their parent_routine_id is
        //      null — pre-Phase-66 data)
        // Excludes:
        //   - The bundle PARENT tasks themselves (Spring/Fall Handyman
        //     Visit). Those represent the visit slot, not punch items.
        //   - Completed / archived tasks
        //   - Tasks already assigned to a vendor with a scheduled date
        //     (the user has acted on them via Maintenance)
        async let punchItemsTask = db.fetchPendingHandymanPunchItems(householdId: householdId)
        async let allTasksTask = db.fetchMaintenanceTasks(propertyId: propertyId)
        async let systemsTask: [HomeSystemRow] = {
            guard let propertyId else { return [] }
            return try await db.fetchHomeSystems(propertyId: propertyId)
        }()
        async let handymanRoutineTask: RoutineRow? = {
            let routines = try await db.fetchRoutines(householdId: householdId)
            return routines.first(where: {
                $0.routineKind == "handyman_recurring" && $0.archivedAt == nil
            })
        }()

        let punchItemsRaw: [HandymanPunchItemRow]
        do {
            punchItemsRaw = try await punchItemsTask
        } catch {
            if Self.isCancellation(error) { return }
            print("[HandymanPunchListViewModel] punch items load failed: \(error)")
            punchItemsRaw = []
        }

        let allTasks: [MaintenanceTaskDBRow]
        do {
            allTasks = try await allTasksTask
        } catch {
            if Self.isCancellation(error) { return }
            print("[HandymanPunchListViewModel] tasks load failed: \(error)")
            allTasks = []
        }

        let systems: [HomeSystemRow]
        do {
            systems = try await systemsTask
        } catch {
            if Self.isCancellation(error) { return }
            systems = []
        }

        let handymanRoutine: RoutineRow?
        do {
            handymanRoutine = try await handymanRoutineTask
        } catch {
            if Self.isCancellation(error) { return }
            handymanRoutine = nil
        }

        guard !Task.isCancelled else { return }

        let systemsLookup = Dictionary(uniqueKeysWithValues: systems.map { ($0.id, $0) })
        let bundleParentTemplateIds: Set<String> = ["Handyman:spring", "Handyman:fall"]

        // Eligibility filter — see top-of-function comment for rules.
        let eligibleTasks = allTasks.filter { task in
            guard task.lastCompletedDate == nil else { return false }
            guard task.isArchived != true else { return false }
            // Skip the bundle parent visit slots themselves.
            if let templateId = task.templateId,
               bundleParentTemplateIds.contains(templateId) { return false }
            // Skip tasks that have already been vendor-assigned AND
            // scheduled (the user has acted on them via Maintenance).
            if task.assignedContractorId != nil,
               let scheduled = task.scheduledDate, !scheduled.isEmpty {
                return false
            }
            // Now check eligibility — any of these qualifies.
            if let routineId = handymanRoutine?.id, task.parentRoutineId == routineId {
                return true
            }
            if let templateId = task.templateId, templateId.hasPrefix("Handyman:") {
                return true
            }
            let canonical = VendorTaskGrouping.resolveCanonicalCategory(
                for: task,
                systemsLookup: systemsLookup
            )
            return canonical == "Handyman"
        }

        let dedupPunchItems = Self.deduplicated(punchItemsRaw)
        // Dedup: if a punch_item already references a maintenance task
        // (`sourceTaskId`), drop the task entry — the manual row is the
        // authoritative version.
        let punchSourceTaskIds = Set(dedupPunchItems.compactMap { $0.sourceTaskId })
        let filteredTasks = eligibleTasks.filter { !punchSourceTaskIds.contains($0.id) }

        guard !Task.isCancelled else { return }
        items = dedupPunchItems
        var combined: [HandymanPunchEntry] = dedupPunchItems.map(HandymanPunchEntry.manual)
        let sortedTasks = filteredTasks.sorted { lhs, rhs in
            let l = MaintenanceDateFormatting.date(from: lhs.scheduledDate ?? lhs.nextDueDate) ?? .distantFuture
            let r = MaintenanceDateFormatting.date(from: rhs.scheduledDate ?? rhs.nextDueDate) ?? .distantFuture
            return l < r
        }
        combined.append(contentsOf: sortedTasks.map(HandymanPunchEntry.task))
        entries = combined

        print("[HandymanPunchListViewModel] load complete. Manual=\(dedupPunchItems.count) tasks=\(filteredTasks.count) total=\(combined.count)")
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
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
            entries.removeAll {
                if case .manual(let row) = $0 { return row.id == item.id }
                return false
            }
            Analytics.track(.handymanPunchItemRemoved, ["source": item.source])
        } catch {
            print("[HandymanPunchListViewModel] archive failed: \(error)")
        }
    }

    /// Phase 95 — inline title edit. Writes the new title to Supabase
    /// and re-loads the punch list so the UI reflects the change. Posts
    /// the punch-list-changed notification so any other surface that's
    /// observing (Tasks tab handyman row count, Maintenance hub) refreshes.
    /// `HandymanPunchItemRow.title` is immutable, so we re-fetch rather
    /// than mutating the local cache.
    func updateTitle(item: HandymanPunchItemRow, title: String, householdId: UUID, propertyId: UUID? = nil) async {
        do {
            try await db.updateHandymanPunchItemTitle(id: item.id, title: title)
            await load(householdId: householdId, propertyId: propertyId)
            NotificationCenter.default.post(name: .handymanPunchListChanged, object: nil)
        } catch {
            print("[HandymanPunchListViewModel] update title failed: \(error)")
        }
    }

    /// Chez v1: dispatches on entry type. Manual items archive via the
    /// existing punch_items soft-delete; task entries get unrouted from
    /// the handyman routine (their `parent_routine_id` clears) so they
    /// fall back into the regular maintenance flow — the user is saying
    /// "this isn't handyman work" rather than "delete this task."
    func archive(entry: HandymanPunchEntry) async {
        switch entry {
        case .manual(let row):
            await archive(item: row)
        case .task(let task):
            do {
                var update = MaintenanceTaskUpdate()
                update.parentRoutineId = nil
                update.assignedRoute = nil
                _ = try await db.updateMaintenanceTask(id: task.id, update)
                entries.removeAll {
                    if case .task(let t) = $0 { return t.id == task.id }
                    return false
                }
                NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                Analytics.track(.handymanPunchItemRemoved, ["source": "task_unrouted"])
            } catch {
                print("[HandymanPunchListViewModel] task unroute failed: \(error)")
            }
        }
    }

    /// Phase 67E/F: Punch → Task promotion. Inverse of the existing
    /// "Add to handyman list" action. Builds a fresh maintenance_tasks
    /// row with `scheduled_date` set to the user's pick, then archives
    /// the source punch item with reason "promoted_to_task" so it stops
    /// appearing on the punch list. Posts both
    /// `.maintenanceTaskChanged` and `.handymanPunchListChanged` so
    /// every listening surface refreshes in one pass.
    func promoteToTask(
        item: HandymanPunchItemRow,
        scheduledDate: Date,
        householdId: UUID,
        propertyId: UUID?
    ) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: scheduledDate)

        // Frequency "Once" matches the AddMaintenanceTaskSheet
        // convention for one-shot user-created tasks. Keeps the
        // promoted item from getting auto-rescheduled.
        var insert = MaintenanceTaskInsert(
            householdId: householdId,
            title: item.title,
            frequency: "Once",
            nextDueDate: dateString
        )
        insert.propertyId = propertyId
        insert.description = item.description
        insert.notes = item.notes
        insert.scheduledDate = dateString
        insert.assignmentType = "personal"
        insert.assignedRoute = "diy"
        insert.priority = item.priority
        // Carry over the in-app templateKey if the punch item came
        // from the reconciler / migration. Lets the maintenance side
        // re-link to template metadata for future reframing.
        insert.templateId = item.sourceTemplateKey
        insert.isTemplateBased = item.sourceTemplateKey != nil

        do {
            _ = try await db.createMaintenanceTask(insert)
            try await db.archiveHandymanPunchItem(id: item.id, reason: "promoted_to_task")
            await load(householdId: householdId, propertyId: propertyId)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            NotificationCenter.default.post(name: .handymanPunchListChanged, object: nil)
            showToast("Scheduled for \(formattedShortDate(scheduledDate))")
            Analytics.track(.handymanPunchItemRemoved, [
                "source": "promoted_to_task",
                "punch_item_id": item.id.uuidString,
            ])
        } catch {
            print("[HandymanPunchListViewModel] promoteToTask failed: \(error)")
            Haptics.error()
        }
    }

    private func formattedShortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
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
        // Chez v1: schedule when EITHER manual items or routed tasks
        // are present. Pre-Chez-v1 this short-circuited on `items`
        // empty, but with the unified list a user can have 0 manual
        // items and 18 routed tasks.
        guard !entries.isEmpty else { return }
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
        // work order: what's included + who requested when. Includes
        // both manual punch items AND routed tasks so the handyman
        // gets the full picture in one place.
        let bullets = entries.map { entry -> String in
            var line = "- " + entry.title
            if let mins = entry.estimatedMinutes {
                line += " (~\(mins) min)"
            }
            return line
        }.joined(separator: "\n")
        let notes = "What's included:\n\(bullets)"

        var insert = MaintenanceTaskInsert(
            householdId: householdId,
            title: "Contractor visit",
            frequency: "Once",
            nextDueDate: dateStr
        )
        insert.propertyId = propertyId
        insert.scheduledDate = dateStr
        insert.description = "The contractor will work through this visit's punch list."
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

            // Chez v1: also stamp scheduled_date + contractor on every
            // task entry that was on the unified list. The user's
            // mental model is "this whole list is part of this visit"
            // — the routed maintenance tasks need the same scheduling
            // metadata so they appear in the Scheduled bucket and the
            // Maintenance / Dashboard surfaces show them as covered.
            let routedTasks = entries.compactMap { $0.taskRow }
            for task in routedTasks {
                var update = MaintenanceTaskUpdate()
                update.scheduledDate = dateStr
                if let contractor {
                    update.assignedContractorId = contractor.id
                    update.assignmentType = "vendor"
                    update.needsVendor = false
                }
                _ = try? await db.updateMaintenanceTask(id: task.id, update)
            }

            // Phase 73 follow-up: every visit on the Handyman tab needs
            // a `handyman_request` row so the provider's dispatch board
            // (handyman.html) and the iOS coordination surfaces (chat,
            // scheduling round-trip, quote review) all have something
            // to hang off. Without this the visit lives only as a
            // maintenance_task and the provider never sees it.
            //
            // Best-effort — a request-create failure shouldn't block
            // the visit itself. The homeowner can still see the
            // scheduled task; the provider just won't surface it
            // until we backfill on next sync.
            await Self.bridgeVisitToHandymanRequest(
                visitTask: created,
                householdId: householdId,
                propertyId: propertyId,
                contractor: contractor,
                scheduledDateStr: dateStr,
                bullets: bullets
            )

            Analytics.track(.handymanPunchListScheduled, [
                "item_count": items.count + routedTasks.count,
                "manual_count": items.count,
                "task_count": routedTasks.count,
                "mode": "ad_hoc",
                "vendor_assigned": contractor != nil
            ])

            items.removeAll()
            entries.removeAll()
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            // Force the global maintenance cache to pick up the new
            // task immediately so HandymanHubView's `nextScheduledVisit`
            // resolves on the very next render. Without this the user
            // saw a stale punch-list-empty state with no visit card,
            // because the notification-driven reload was racing the
            // view's re-render and arriving too late.
            await MaintenanceViewModel.shared.loadTasks()
            try? await Task.sleep(nanoseconds: 150_000_000)
            justScheduledTask = created
        } catch {
            print("[HandymanPunchListViewModel] ad-hoc schedule failed: \(error)")
            showToast("Couldn't schedule. Please try again.")
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
            showToast("Couldn't schedule. Please try again.")
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

    /// Phase 73 follow-up: every Handyman-tab visit also creates a
    /// `handyman_request` so the provider's dispatch board picks it
    /// up and the iOS coordination surfaces (chat, scheduling round
    /// trip, quote review) have something to hang off. Idempotent —
    /// if a request already exists for this visit_task_id we skip.
    static func bridgeVisitToHandymanRequest(
        visitTask: MaintenanceTaskDBRow,
        householdId: UUID,
        propertyId: UUID,
        contractor: ContractorRow?,
        scheduledDateStr: String,
        bullets: String
    ) async {
        let db = DatabaseService.shared
        if let existing = try? await db.fetchLatestHandymanRequest(visitTaskId: visitTask.id),
           existing.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
            // A request already covers this visit — leave it alone.
            // Future scheduling edits can update it via the existing
            // handyman_provider/handyman-portal coordination paths.
            _ = existing
            return
        }

        var insert = HandymanRequestInsert(
            householdId: householdId,
            requestType: "standard_visit",
            title: "Contractor visit"
        )
        insert.propertyId = propertyId
        insert.contractorId = contractor?.id
        insert.visitTaskId = visitTask.id
        insert.source = "homeowner"
        insert.preferredTiming = scheduledDateStr
        insert.urgency = "routine"
        // Status branches on whether a contractor is locked in. With a
        // contractor we can mark the visit `scheduled`; without one we
        // start at `submitted` so the homeowner sees "find a handyman"
        // affordances on the coordination card.
        insert.status = contractor == nil ? "submitted" : "scheduled"
        insert.firstVisitSetupRequested = false
        insert.details = bullets.isEmpty
            ? "Punch list visit scheduled from the Handyman tab."
            : "What's included:\n\(bullets)"

        do {
            _ = try await db.createHandymanRequest(insert)
        } catch {
            print("[HandymanPunchListViewModel] Couldn't bridge visit \(visitTask.id) → handyman_request: \(error)")
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
                    Text(scheduleSummary)
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

    private var scheduleSummary: String {
        if itemCount > 0 {
            return "Chez will create a scheduled visit for \(itemCount) item\(itemCount == 1 ? "" : "s"). Your handyman gets the full punch list in the task notes."
        }
        return "Schedule the next handyman walkthrough now. Chez will keep the default spring and fall checklist in view, and you can keep adding odd jobs before the visit."
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

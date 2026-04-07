import SwiftUI
import PhotosUI
import UserNotifications

/// Family tab: upcoming events hero, category filters, items with event dates, reminders, tagging.
struct FamilyInboxView: View {
    @State private var items: [DatabaseService.InboxItemRow] = []
    @State private var calendarEvents: [FamilyEventRow] = []
    @State private var familyMembers: [FamilyMemberRow] = []
    @State private var hasLoaded = false
    @State private var expandedItem: UUID?
    @State private var selectedCategory: String? = nil
    // File upload
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploading = false
    // Delete
    @State private var showDeleteConfirm = false
    @State private var itemToDelete: DatabaseService.InboxItemRow?
    @State private var showDeleteCalendarEventConfirm = false
    @State private var calendarEventToDelete: FamilyEventRow?
    // Reschedule
    @State private var showReschedule = false
    @State private var itemToReschedule: DatabaseService.InboxItemRow?
    @State private var rescheduleDate = Date()
    // Tagging
    @State private var showTagging = false
    @State private var itemToTag: DatabaseService.InboxItemRow?
    @State private var selectedMemberIds: Set<UUID> = []
    // Reminders
    @State private var activeReminders: Set<String> = []
    // Calendar sync
    @State private var showCalendarSync = false
    @State private var selectedCalendarEvent: FamilyEventRow?

    private let db = DatabaseService.shared

    // MARK: - Unified Event Type

    /// Wraps both inbox items (email events) and calendar-synced events for unified display
    enum UnifiedEvent: Identifiable {
        case inbox(DatabaseService.InboxItemRow)
        case calendar(FamilyEventRow)

        var id: UUID {
            switch self {
            case .inbox(let item): return item.id
            case .calendar(let event): return event.id
            }
        }

        var title: String {
            switch self {
            case .inbox(let item): return item.title
            case .calendar(let event): return event.title
            }
        }

        var eventDate: Date? {
            switch self {
            case .inbox(let item): return item.eventDate
            case .calendar(let event): return event.startDate
            }
        }

        var location: String? {
            switch self {
            case .inbox: return nil
            case .calendar(let event): return event.location
            }
        }

        var familyCategory: String? {
            switch self {
            case .inbox(let item): return item.familyCategory
            case .calendar: return "events"
            }
        }

        var taggedMemberIds: [UUID]? {
            switch self {
            case .inbox(let item): return item.taggedMemberIds
            case .calendar(let event): return event.taggedMemberIds
            }
        }

        var isCalendarEvent: Bool {
            if case .calendar = self { return true }
            return false
        }

        var isAllDay: Bool {
            switch self {
            case .inbox: return false
            case .calendar(let event): return event.allDay
            }
        }

        var source: String? {
            if case .calendar(let event) = self { return event.source }
            return nil
        }
    }

    // MARK: - Filtered items

    private var filteredItems: [DatabaseService.InboxItemRow] {
        guard let cat = selectedCategory else { return items }
        return items.filter { $0.familyCategory?.lowercased() == cat.lowercased() }
    }

    private var allUpcomingEvents: [UnifiedEvent] {
        let startOfToday = Calendar.current.startOfDay(for: Date())

        // Email-sourced events from inbox_items
        let inboxEvents: [UnifiedEvent] = items
            .filter { $0.eventDate != nil && $0.eventDate! >= startOfToday }
            .map { .inbox($0) }

        // Calendar-synced events from family_events
        let calEvents: [UnifiedEvent] = calendarEvents
            .filter { $0.startDate >= startOfToday }
            .map { .calendar($0) }

        return (inboxEvents + calEvents)
            .sorted { ($0.eventDate ?? .distantFuture) < ($1.eventDate ?? .distantFuture) }
    }

    /// Events this week (today through end of week)
    private var thisWeekEvents: [UnifiedEvent] {
        let calendar = Calendar.current
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: Date()))!
        return allUpcomingEvents.filter { ($0.eventDate ?? .distantFuture) < endOfWeek }
    }

    /// Events after this week
    private var laterEvents: [UnifiedEvent] {
        let calendar = Calendar.current
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: Date()))!
        return allUpcomingEvents.filter { ($0.eventDate ?? .distantFuture) >= endOfWeek }
    }

    /// Combined this week + upcoming, capped at 5 for the main view
    private var visibleEvents: [UnifiedEvent] {
        Array(allUpcomingEvents.prefix(5))
    }

    private var upcomingEventIds: Set<UUID> {
        Set(allUpcomingEvents.map { $0.id })
    }

    private var availableCategories: [String] {
        let cats = Set(items.compactMap { $0.familyCategory?.lowercased() })
        let order = ["school", "events", "medical", "activities", "travel", "bills", "personal", "other"]
        return order.filter { cats.contains($0) }
    }

    // MARK: - Body

    @State private var selectedItem: DatabaseService.InboxItemRow?
    @State private var showAllUpcoming = false

    var body: some View {
        Group {
        if !hasLoaded {
            VStack(spacing: HavenTheme.spacing16) {
                SkeletonCard(lineCount: 2)
                SkeletonCard(lineCount: 2)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
        } else if items.isEmpty {
            emptyState
                .padding(.horizontal, HavenTheme.pageMargin)
                .modifier(FamilyFilePickerModifiers(showPhotoPicker: $showPhotoPicker, showFilePicker: $showFilePicker, selectedPhoto: $selectedPhoto, onPhoto: handlePhotoSelection, onFile: handleFileSelection))
        } else {
            List {
                // This Week + Upcoming events (max 5, with "View More")
                if !visibleEvents.isEmpty {
                    // This Week section
                    let visibleThisWeek = thisWeekEvents.filter { event in visibleEvents.contains(where: { $0.id == event.id }) }
                    let visibleLater = laterEvents.filter { event in visibleEvents.contains(where: { $0.id == event.id }) }

                    if !visibleThisWeek.isEmpty {
                        Section {
                            Text("THIS WEEK")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                            ForEach(visibleThisWeek) { event in
                                upcomingEventRow(event)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                            }
                        }
                    }

                    // Upcoming (beyond this week)
                    if !visibleLater.isEmpty {
                        Section {
                            Text("UPCOMING")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                            ForEach(visibleLater) { event in
                                upcomingEventRow(event)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                            }
                        }
                    }

                    // View More button if there are more than 5 total
                    if allUpcomingEvents.count > 5 {
                        Section {
                            Button {
                                showAllUpcoming = true
                                Analytics.track(.familyAllUpcomingViewed, ["total_events": allUpcomingEvents.count])
                            } label: {
                                HStack {
                                    Text("View More (\(allUpcomingEvents.count - 5) more)")
                                        .font(HavenTypography.uiLabel)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundStyle(HavenColors.navy700)
                                .padding(.vertical, 4)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                        }
                    }

                    // Add Events From Calendar button
                    Section {
                        addEventsFromCalendarButton
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }

                // Add Events From Calendar (shown when no events yet)
                if visibleEvents.isEmpty {
                    Section {
                        addEventsFromCalendarButton
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }

                // Category filter chips
                if availableCategories.count > 1 {
                    Section {
                        categoryChips
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }

                // All items grouped by date
                ForEach(groupedItems, id: \.label) { group in
                    Section {
                        Text(group.label)
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        ForEach(group.items) { item in
                            familyItemCard(item)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        itemToDelete = item
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                }

                // Upload buttons + suggestions
                Section {
                    uploadButtons
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    if items.count < 5 {
                        suggestedForwardsCard
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .modifier(FamilyFilePickerModifiers(showPhotoPicker: $showPhotoPicker, showFilePicker: $showFilePicker, selectedPhoto: $selectedPhoto, onPhoto: handlePhotoSelection, onFile: handleFileSelection))
        }
        } // end Group
        .trackScreen("FamilyInboxView")
        .task {
            await loadItems()
            await loadCalendarEvents()
            await loadFamilyMembers()
            await loadActiveReminders()
        }
        .onAppear {
            // Refresh without resetting hasLoaded (no flicker)
            if hasLoaded {
                Task {
                    await refreshItems()
                    await loadCalendarEvents()
                }
            }
        }
        .alert("Delete this item?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    Task {
                        try? await db.deleteInboxItem(id: item.id)
                        items.removeAll { $0.id == item.id }
                        Haptics.success()
                        Analytics.track(.familyItemDeleted, ["item_id": item.id.uuidString, "category": item.familyCategory ?? "unknown"])
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showReschedule) { rescheduleSheet }
        .sheet(isPresented: $showTagging) { taggingSheet }
        .sheet(isPresented: $showAllUpcoming) {
            NavigationStack {
                upcomingEventsFullView
                .background(HavenColors.background)
                .navigationTitle("Upcoming Events")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { showAllUpcoming = false }
                            .foregroundStyle(HavenColors.navy)
                    }
                }
            }
        }
        .sheet(isPresented: $showCalendarSync) {
            CalendarSyncSheet {
                Task { await loadCalendarEvents() }
            }
        }
        .onChange(of: selectedCalendarEvent) { _, newValue in
            // Dismiss View More sheet first, then present detail
            if newValue != nil && showAllUpcoming {
                showAllUpcoming = false
            }
        }
        .sheet(item: $selectedCalendarEvent) { event in
            NavigationStack {
                CalendarEventDetailView(
                    event: event,
                    familyMembers: familyMembers,
                    onUpdate: { Task { await loadCalendarEvents() } },
                    onDelete: {
                        calendarEvents.removeAll { $0.id == event.id }
                    }
                )
            }
            .presentationDetents([.large])
        }
        .alert("Delete this event?", isPresented: $showDeleteCalendarEventConfirm) {
            Button("Delete from Haven & Calendar", role: .destructive) {
                if let event = calendarEventToDelete {
                    Task {
                        try? await CalendarSyncService.shared.deleteEvent(event)
                        calendarEvents.removeAll { $0.id == event.id }
                        Haptics.success()
                        Analytics.track(.calendarEventDeleted, ["event_title": event.title, "source": event.source])
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will also remove the event from your iPhone calendar.")
        }
        .sheet(item: $selectedItem) { item in
            NavigationStack {
                FamilyItemDetailView(item: item, onDelete: {
                    items.removeAll { $0.id == item.id }
                    selectedItem = nil
                }, onUpdate: {
                    Task { await refreshItems() }
                    selectedItem = nil
                })
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Upcoming Event Row

    private func upcomingEventRow(_ event: UnifiedEvent) -> some View {
        Button {
            switch event {
            case .inbox(let item): selectedItem = item
            case .calendar(let calEvent): selectedCalendarEvent = calEvent
            }
        } label: {
            HStack(spacing: 12) {
                // Date badge
                if let date = event.eventDate {
                    VStack(spacing: 0) {
                        Text(date.formatted(.dateTime.month(.abbreviated)).uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(HavenColors.critical)
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(HavenColors.navy800)
                    }
                    .frame(width: 44, height: 44)
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(HavenColors.navy.opacity(0.12), lineWidth: 1)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)

                    if let date = event.eventDate {
                        HStack(spacing: 4) {
                            if event.isAllDay {
                                Text("\(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())) — All Day")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            } else {
                                Text(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().hour().minute()))
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            // Show calendar source badge for synced events
                            if event.isCalendarEvent {
                                Image(systemName: "calendar.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(HavenColors.info)
                            }
                        }
                    }

                    // Location for calendar events
                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin")
                                .font(.system(size: 9))
                            Text(location)
                                .lineLimit(1)
                        }
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                    }

                    // Tagged members (with avatar colors, oldest first)
                    if let ids = event.taggedMemberIds, !ids.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(sortedTagIds(ids), id: \.self) { memberId in
                                if let member = familyMembers.first(where: { $0.id == memberId }) {
                                    let tagColor = memberColor(member.avatarColor)
                                    Text(member.firstName)
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(tagColor)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(tagColor.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: familyCategoryIcon(event.familyCategory))
                    .font(.caption)
                    .foregroundStyle(familyCategoryColor(event.familyCategory))
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.navy.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton("All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(availableCategories, id: \.self) { cat in
                    chipButton(cat.capitalized, isSelected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
        }
    }

    private func chipButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Text(label)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(isSelected ? .white : HavenColors.navy700)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? HavenColors.navy : HavenColors.navy.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing16) {
                Spacer().frame(height: 24)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(HavenColors.textTertiary)
                VStack(spacing: HavenTheme.spacing8) {
                    Text("Your family hub")
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Forward emails or upload documents for anything family-related. Haven keeps it all organized.")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                    Text("Switch to Documents above to see estate and home paperwork.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, HavenTheme.pageMargin)

                addEventsFromCalendarButton
                    .padding(.horizontal, HavenTheme.pageMargin)

                uploadButtons

                suggestedForwardsCard

                Spacer().frame(height: 80)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Suggested Forwards

    private var suggestedForwardsCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("THINGS TO FORWARD OR UPLOAD")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            VStack(spacing: 0) {
                suggestionRow(icon: "graduationcap.fill", title: "School Info", detail: "Curriculum, report cards, teacher contacts, school calendars", color: HavenColors.info)
                Divider().padding(.leading, 40)
                suggestionRow(icon: "party.popper.fill", title: "Events & Invitations", detail: "Birthday parties, playdates, family gatherings", color: HavenColors.warning)
                Divider().padding(.leading, 40)
                suggestionRow(icon: "tent.fill", title: "Camps & Programs", detail: "Summer camps, after-school programs, sports leagues", color: HavenColors.success)
                Divider().padding(.leading, 40)
                suggestionRow(icon: "cross.case.fill", title: "Medical & Dental", detail: "Appointment confirmations, vaccination records, insurance cards", color: HavenColors.critical)
                Divider().padding(.leading, 40)
                suggestionRow(icon: "figure.run", title: "Activities & Sports", detail: "Practice schedules, game times, registration info", color: .orange)
                Divider().padding(.leading, 40)
                suggestionRow(icon: "airplane", title: "Travel", detail: "Flight confirmations, hotel bookings, itineraries", color: HavenColors.navy)
                Divider().padding(.leading, 40)
                suggestionRow(icon: "briefcase.fill", title: "Work & Employment", detail: "Pay stubs, benefits info, HR documents", color: HavenColors.textSecondary)
                Divider().padding(.leading, 40)
                suggestionRow(icon: "doc.text.fill", title: "Memberships", detail: "Gym, library, organizations, loyalty programs", color: .purple)
            }
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
    }

    private func suggestionRow(icon: String, title: String, detail: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(detail)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, HavenTheme.spacing12)
        .padding(.vertical, 10)
    }

    // MARK: - Item Card

    private func familyItemCard(_ item: DatabaseService.InboxItemRow) -> some View {
        Button {
            selectedItem = item
        } label: {
            HavenCard(padding: HavenTheme.spacing12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: familyCategoryIcon(item.familyCategory))
                            .font(.title3)
                            .foregroundStyle(familyCategoryColor(item.familyCategory))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(2)

                            // Event date + category row
                            HStack(spacing: 6) {
                                if let eventDate = item.eventDate {
                                    HStack(spacing: 3) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 9))
                                        Text(eventDate.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                    }
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(eventDate > Date() ? HavenColors.navy700 : HavenColors.textTertiary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(HavenColors.navy.opacity(0.06))
                                    .clipShape(Capsule())
                                }

                                if let cat = item.familyCategory, cat != "other" {
                                    Text(cat.capitalized)
                                        .font(HavenTypography.uiLabelSmall)
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                            }

                            // Tagged members (own row, wraps naturally, oldest first)
                            if let ids = item.taggedMemberIds, !ids.isEmpty {
                                WrappingHStack(spacing: 4) {
                                    ForEach(sortedTagIds(ids), id: \.self) { memberId in
                                        if let member = familyMembers.first(where: { $0.id == memberId }) {
                                            let tagColor = memberColor(member.avatarColor)
                                            Text(member.firstName)
                                                .font(.system(size: 9, weight: .semibold))
                                                .foregroundStyle(tagColor)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(tagColor.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }

                            if let date = item.createdAt {
                                Text(date, style: .relative)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                selectedItem = item
            } label: {
                Label("View Details", systemImage: "info.circle")
            }

            Button {
                itemToReschedule = item
                rescheduleDate = item.eventDate ?? Date()
                showReschedule = true
            } label: {
                Label("Set / Change Date", systemImage: "calendar.badge.clock")
            }

            Button {
                itemToTag = item
                selectedMemberIds = Set(item.taggedMemberIds ?? [])
                showTagging = true
            } label: {
                Label("Tag Family Members", systemImage: "tag")
            }

            Divider()

            Button(role: .destructive) {
                itemToDelete = item
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Reminder Toggles

    private func reminderToggles(item: DatabaseService.InboxItemRow, eventDate: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("REMINDERS")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
                .fontWeight(.semibold)
                .tracking(0.5)

            HStack(spacing: 8) {
                reminderChip("1hr", id: "family-\(item.id)-1h", item: item, eventDate: eventDate, offset: -3600)
                reminderChip("1 day", id: "family-\(item.id)-1d", item: item, eventDate: eventDate, offset: -86400)
                reminderChip("1 week", id: "family-\(item.id)-7d", item: item, eventDate: eventDate, offset: -604800)
                reminderChip("1 month", id: "family-\(item.id)-30d", item: item, eventDate: eventDate, offset: -2592000)
            }
        }
    }

    private func reminderChip(_ label: String, id: String, item: DatabaseService.InboxItemRow, eventDate: Date, offset: TimeInterval) -> some View {
        let isSet = activeReminders.contains(id)
        return Button {
            Haptics.light()
            toggleReminder(id: id, title: item.title, eventDate: eventDate, offset: offset, isEnabled: !isSet)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: isSet ? "bell.fill" : "bell")
                    .font(.system(size: 9))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSet ? .white : HavenColors.navy700)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isSet ? HavenColors.navy : HavenColors.navy.opacity(0.06))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func toggleReminder(id: String, title: String, eventDate: Date, offset: TimeInterval, isEnabled: Bool) {
        let center = UNUserNotificationCenter.current()

        if isEnabled {
            let alertDate = eventDate.addingTimeInterval(offset)
            guard alertDate > Date() else { return }

            let content = UNMutableNotificationContent()
            content.title = "Family Event Reminder"
            content.body = title
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
            activeReminders.insert(id)
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [id])
            activeReminders.remove(id)
        }
    }

    // MARK: - Reschedule Sheet

    private var rescheduleSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker("Date", selection: $rescheduleDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(HavenColors.navy800)
                    .padding(.horizontal)

                Divider().padding(.horizontal)

                DatePicker("Time", selection: $rescheduleDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 100)
                    .clipped()
                    .padding(.horizontal)
            }
            .navigationTitle("Set Event Date & Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showReschedule = false }
                        .foregroundStyle(HavenColors.navy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard let item = itemToReschedule else { return }
                        Task {
                            try? await db.updateInboxItemEventDate(id: item.id, eventDate: rescheduleDate)
                            Haptics.success()
                            showReschedule = false
                            await loadItems()
                        }
                    }
                    .foregroundStyle(HavenColors.navy)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Tagging Sheet

    private var taggingSheet: some View {
        NavigationStack {
            List {
                ForEach(familyMembers) { member in
                    Button {
                        if selectedMemberIds.contains(member.id) {
                            selectedMemberIds.remove(member.id)
                        } else {
                            selectedMemberIds.insert(member.id)
                        }
                        Haptics.light()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(member.firstName) \(member.lastName)")
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(member.relationship.capitalized)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            Spacer()
                            if selectedMemberIds.contains(member.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(HavenColors.navy)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Tag Family Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showTagging = false }
                        .foregroundStyle(HavenColors.navy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard let item = itemToTag else { return }
                        Task {
                            let ids = Array(selectedMemberIds)
                            try? await db.updateInboxItemTags(id: item.id, memberIds: ids)
                            Haptics.success()
                            showTagging = false
                            await loadItems()
                        }
                    }
                    .foregroundStyle(HavenColors.navy)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Grouping

    private struct ItemGroup {
        let label: String
        let items: [DatabaseService.InboxItemRow]
    }

    private var groupedItems: [ItemGroup] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday)!

        var today: [DatabaseService.InboxItemRow] = []
        var thisWeek: [DatabaseService.InboxItemRow] = []
        var earlier: [DatabaseService.InboxItemRow] = []

        // Exclude items already shown in the upcoming events hero section
        let nonUpcoming = filteredItems.filter { !upcomingEventIds.contains($0.id) }

        for item in nonUpcoming {
            let date = item.createdAt ?? .distantPast
            if date >= startOfToday {
                today.append(item)
            } else if date >= startOfWeek {
                thisWeek.append(item)
            } else {
                earlier.append(item)
            }
        }

        var groups: [ItemGroup] = []
        if !today.isEmpty { groups.append(ItemGroup(label: "TODAY", items: today)) }
        if !thisWeek.isEmpty { groups.append(ItemGroup(label: "THIS WEEK", items: thisWeek)) }
        if !earlier.isEmpty { groups.append(ItemGroup(label: "EARLIER", items: earlier)) }
        return groups
    }

    // MARK: - Helpers

    private func familyCategoryIcon(_ category: String?) -> String {
        switch category?.lowercased() {
        case "school": return "graduationcap.fill"
        case "events": return "party.popper.fill"
        case "medical": return "cross.case.fill"
        case "activities": return "figure.run"
        case "travel": return "airplane"
        case "personal": return "person.fill"
        case "bills": return "dollarsign.circle.fill"
        default: return "envelope.fill"
        }
    }

    /// Sort tagged member IDs by date of birth (oldest first), nil DOB at end
    private func sortedTagIds(_ ids: [UUID]) -> [UUID] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return ids.sorted { a, b in
            let memberA = familyMembers.first(where: { $0.id == a })
            let memberB = familyMembers.first(where: { $0.id == b })
            let dateA = memberA?.dateOfBirth.flatMap { df.date(from: $0) }
            let dateB = memberB?.dateOfBirth.flatMap { df.date(from: $0) }
            switch (dateA, dateB) {
            case let (a?, b?): return a < b  // older (earlier date) first
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return false
            }
        }
    }

    private func memberColor(_ avatarColor: String?) -> Color {
        guard let key = avatarColor, let ac = AvatarColor(rawValue: key) else { return HavenColors.navy }
        return ac.color
    }

    private func familyCategoryColor(_ category: String?) -> Color {
        switch category?.lowercased() {
        case "school": return HavenColors.info
        case "events": return HavenColors.warning
        case "medical": return HavenColors.critical
        case "activities": return HavenColors.success
        case "travel": return HavenColors.navy
        case "personal": return HavenColors.textSecondary
        case "bills": return .orange
        default: return HavenColors.navy
        }
    }

    // MARK: - Data

    private func loadItems() async {
        do {
            items = try await db.fetchFamilyInboxItems()
            print("[FamilyInbox] Loaded \(items.count) items")
        } catch {
            print("[FamilyInbox] Load FAILED: \(error)")
            items = []
        }
        hasLoaded = true
    }

    private func refreshItems() async {
        do {
            items = try await db.fetchFamilyInboxItems()
        } catch {
            print("[FamilyInbox] Refresh FAILED: \(error)")
        }
    }

    private func loadCalendarEvents() async {
        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else { return }
            calendarEvents = try await db.fetchUpcomingFamilyEvents(householdId: householdId)
            // Also trigger background sync if calendars are linked
            await CalendarSyncService.shared.syncAll()
            // Reload after sync
            calendarEvents = try await db.fetchUpcomingFamilyEvents(householdId: householdId)
        } catch {
            print("[FamilyInbox] Calendar events load failed: \(error)")
        }
    }

    private func loadFamilyMembers() async {
        familyMembers = (try? await db.fetchFamilyMembers()) ?? []
        print("[FamilyInbox] Loaded \(familyMembers.count) family members: \(familyMembers.map { $0.firstName })")
    }

    private func loadActiveReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        activeReminders = Set(pending.filter { $0.identifier.hasPrefix("family-") }.map { $0.identifier })
    }

    // MARK: - Full Upcoming Events View (3-day swipable + list)

    @State private var dayOffset = 0

    private var upcomingEventsFullView: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return ScrollView {
            VStack(spacing: 0) {
                // 3-day swipable header
                TabView(selection: $dayOffset) {
                    ForEach(0..<30, id: \.self) { offset in
                        dayColumnsView(startingOffset: offset)
                            .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 140)
                .padding(.bottom, 8)

                Divider().padding(.horizontal)

                // Full list below
                LazyVStack(spacing: 8) {
                    let eventsFromOffset = allUpcomingEvents.filter { event in
                        guard let date = event.eventDate else { return false }
                        let offsetDate = calendar.date(byAdding: .day, value: dayOffset, to: today)!
                        return date >= offsetDate
                    }

                    ForEach(eventsFromOffset) { event in
                        upcomingEventRow(event)
                            .padding(.horizontal, HavenTheme.pageMargin)
                    }
                }
                .padding(.top, 12)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func dayColumnsView(startingOffset: Int) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { col in
                let dayDate = calendar.date(byAdding: .day, value: startingOffset + col, to: today)!
                let dayEvents = allUpcomingEvents.filter { event in
                    guard let date = event.eventDate else { return false }
                    return calendar.isDate(date, inSameDayAs: dayDate)
                }

                VStack(spacing: 6) {
                    // Day header
                    VStack(spacing: 2) {
                        Text(dayDate.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(calendar.isDateInToday(dayDate) ? HavenColors.critical : HavenColors.textTertiary)
                        Text(dayDate.formatted(.dateTime.day()))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(calendar.isDateInToday(dayDate) ? HavenColors.navy800 : HavenColors.textPrimary)
                    }

                    // Event dots/previews
                    if dayEvents.isEmpty {
                        Text("No events")
                            .font(.system(size: 9))
                            .foregroundStyle(HavenColors.textTertiary)
                    } else {
                        VStack(spacing: 3) {
                            ForEach(dayEvents.prefix(3)) { event in
                                Text(event.title)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(HavenColors.navy700)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(HavenColors.navy.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            if dayEvents.count > 3 {
                                Text("+\(dayEvents.count - 3) more")
                                    .font(.system(size: 8))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(calendar.isDateInToday(dayDate) ? HavenColors.navy.opacity(0.04) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
    }

    // MARK: - Add Events From Calendar

    private var addEventsFromCalendarButton: some View {
        Button {
            Haptics.light()
            showCalendarSync = true
            Analytics.track(.calendarSyncOpened)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(HavenColors.navy)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Add Events From Calendar")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy700)
                    if !CalendarSyncService.shared.syncedCalendarIds.isEmpty {
                        Text("\(CalendarSyncService.shared.syncedCalendarIds.count) calendar(s) synced")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    } else {
                        Text("Sync your iPhone calendars")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.navy.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.navy.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Upload Buttons

    private var uploadButtons: some View {
        VStack(spacing: HavenTheme.spacing8) {
            if isUploading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Uploading...")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(.vertical, HavenTheme.spacing8)
            }
            HStack(spacing: HavenTheme.spacing8) {
                Button { showPhotoPicker = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle").font(.caption)
                        Text("Upload Photo").font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(HavenColors.navy.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button { showFilePicker = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill").font(.caption)
                        Text("Upload File").font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(HavenColors.navy.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - File Upload

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        await uploadFamilyDocument(data: data, filename: "photo_\(Date().timeIntervalSince1970).jpg", contentType: "image/jpeg")
        selectedPhoto = nil
    }

    private func handleFileSelection(_ result: Result<URL, Error>) async {
        guard case .success(let url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }
        let filename = url.lastPathComponent
        let contentType = url.pathExtension.lowercased() == "pdf" ? "application/pdf" : "image/jpeg"
        await uploadFamilyDocument(data: data, filename: filename, contentType: contentType)
    }

    private func uploadFamilyDocument(data: Data, filename: String, contentType: String) async {
        isUploading = true
        defer { isUploading = false }
        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else { return }
            let storagePath = "\(householdId.uuidString)/family/\(UUID().uuidString)_\(filename)"
            try await db.uploadInboxAttachment(path: storagePath, data: data, contentType: contentType)

            struct FamilyItemInsert: Encodable {
                let householdId: UUID; let type: String; let title: String; let summary: String?
                let attachmentPath: String; let attachmentContentType: String?; let attachmentFilename: String?; let status: String
                enum CodingKeys: String, CodingKey {
                    case type, title, summary, status
                    case householdId = "household_id"; case attachmentPath = "attachment_path"
                    case attachmentContentType = "attachment_content_type"; case attachmentFilename = "attachment_filename"
                }
            }
            try await DatabaseService.shared.insertFamilyInboxItem(FamilyItemInsert(
                householdId: householdId, type: "family", title: filename,
                summary: "Uploaded document", attachmentPath: storagePath,
                attachmentContentType: contentType, attachmentFilename: filename, status: "ready"
            ))
            Haptics.success()
            await loadItems()
        } catch {
            print("[FamilyInbox] Upload failed: \(error)")
            Haptics.error()
        }
    }
}

// MARK: - Wrapping HStack Layout

private struct WrappingHStack: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, pos) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxW = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > maxW && x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            positions.append(CGPoint(x: x, y: y))
            rowH = max(rowH, s.height)
            x += s.width + spacing
        }
        return (CGSize(width: maxW, height: y + rowH), positions)
    }
}

// MARK: - File Picker Modifiers

private struct FamilyFilePickerModifiers: ViewModifier {
    @Binding var showPhotoPicker: Bool
    @Binding var showFilePicker: Bool
    @Binding var selectedPhoto: PhotosPickerItem?
    let onPhoto: (PhotosPickerItem) async -> Void
    let onFile: (Result<URL, Error>) async -> Void

    func body(content: Content) -> some View {
        content
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .any(of: [.images]))
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.image, .pdf]) { result in
                Task { await onFile(result) }
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task { await onPhoto(item) }
            }
    }
}

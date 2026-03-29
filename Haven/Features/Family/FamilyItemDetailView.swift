import SwiftUI
import UserNotifications

/// Detail view for a family inbox item — shows full info, edit capabilities, reminders.
struct FamilyItemDetailView: View {
    let item: DatabaseService.InboxItemRow
    let onDelete: () -> Void
    let onUpdate: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var familyMembers: [FamilyMemberRow] = []
    @State private var editedTitle: String
    @State private var editedSummary: String
    @State private var isEditing = false
    @State private var showDeleteConfirm = false
    @State private var showReschedule = false
    @State private var rescheduleDate: Date
    @State private var showTagging = false
    @State private var selectedMemberIds: Set<UUID>
    @State private var activeReminders: Set<String> = []
    @State private var showRawEmail = false

    private let db = DatabaseService.shared

    init(item: DatabaseService.InboxItemRow, onDelete: @escaping () -> Void, onUpdate: @escaping () -> Void) {
        self.item = item
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        _editedTitle = State(initialValue: item.title)
        _editedSummary = State(initialValue: item.summary ?? "")
        _rescheduleDate = State(initialValue: item.eventDate ?? Date())
        _selectedMemberIds = State(initialValue: Set(item.taggedMemberIds ?? []))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                // Category + date header
                HStack {
                    Image(systemName: categoryIcon)
                        .font(.title2)
                        .foregroundStyle(categoryColor)
                    if let cat = item.familyCategory, cat != "other" {
                        Text(cat.capitalized)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(categoryColor)
                    }
                    Spacer()
                    if let date = item.createdAt {
                        Text(date, style: .relative)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                // Title
                if isEditing {
                    TextField("Title", text: $editedTitle)
                        .font(HavenTypography.title2)
                        .padding(HavenTheme.spacing8)
                        .background(HavenColors.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Text(item.title)
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.textPrimary)
                }

                // Event date
                if let eventDate = item.eventDate {
                    HavenCard(padding: HavenTheme.spacing12) {
                        HStack(spacing: 10) {
                            VStack(spacing: 0) {
                                Text(eventDate.formatted(.dateTime.month(.abbreviated)).uppercased())
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(HavenColors.critical)
                                Text(eventDate.formatted(.dateTime.day()))
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(HavenColors.navy800)
                            }
                            .frame(width: 44, height: 44)
                            .background(HavenColors.navy.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(eventDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(eventDate.formatted(.dateTime.hour().minute()))
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }

                            Spacer()

                            Button {
                                rescheduleDate = eventDate
                                showReschedule = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                        }
                    }
                } else {
                    Button {
                        showReschedule = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.caption)
                            Text("Add Event Date")
                                .font(HavenTypography.uiLabel)
                        }
                        .foregroundStyle(HavenColors.navy700)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(HavenColors.navy.opacity(0.06))
                        .clipShape(Capsule())
                    }
                }

                // Attachment
                if let filename = item.attachmentFilename {
                    HavenCard(padding: HavenTheme.spacing12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ATTACHMENT")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                                .fontWeight(.semibold)
                                .tracking(0.5)

                            HStack(spacing: 10) {
                                Image(systemName: item.attachmentContentType?.hasPrefix("image") == true ? "photo.fill" : "doc.fill")
                                    .font(.title3)
                                    .foregroundStyle(HavenColors.navy)
                                    .frame(width: 36, height: 36)
                                    .background(HavenColors.navy.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(filename)
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                        .lineLimit(1)
                                    if let ct = item.attachmentContentType {
                                        Text(ct)
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }

                // Tagged members
                HavenCard(padding: HavenTheme.spacing12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("TAGGED")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                                .fontWeight(.semibold)
                                .tracking(0.5)
                            Spacer()
                            Button {
                                selectedMemberIds = Set(item.taggedMemberIds ?? [])
                                showTagging = true
                            } label: {
                                Text("Edit")
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy)
                            }
                        }

                        if let ids = item.taggedMemberIds, !ids.isEmpty {
                            FamilyTagFlowLayout(spacing: 6) {
                                ForEach(ids, id: \.self) { memberId in
                                    if let member = familyMembers.first(where: { $0.id == memberId }) {
                                        Text("\(member.firstName) \(member.lastName)")
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundStyle(HavenColors.navy700)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(HavenColors.navy.opacity(0.08))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        } else {
                            Text("No one tagged yet")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }

                // Summary / Description
                HavenCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DETAILS")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .fontWeight(.semibold)
                            .tracking(0.5)

                        if isEditing {
                            TextEditor(text: $editedSummary)
                                .font(HavenTypography.body)
                                .frame(minHeight: 100)
                        } else if let summary = item.summary, !summary.isEmpty {
                            Text(summary)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textSecondary)
                        } else {
                            Text("No details available")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }

                // Raw email
                if let rawBody = item.rawEmailBody, !rawBody.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Button {
                            withAnimation { showRawEmail.toggle() }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: showRawEmail ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 9))
                                Text("View Raw Email")
                                    .font(HavenTypography.uiCaption)
                            }
                            .foregroundStyle(HavenColors.textTertiary)
                        }
                        .buttonStyle(.plain)

                        if showRawEmail {
                            Text(rawBody)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(HavenColors.textSecondary)
                                .padding(HavenTheme.spacing8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(HavenColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .textSelection(.enabled)
                        }
                    }
                }

                // From email
                if let from = item.fromEmail {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                            .font(.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(from)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                // Reminders (if has event date in the future)
                if let eventDate = item.eventDate, eventDate > Date() {
                    HavenCard(padding: HavenTheme.spacing12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("REMINDERS")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                                .fontWeight(.semibold)
                                .tracking(0.5)

                            HStack(spacing: 8) {
                                reminderChip("1 hr", id: "family-\(item.id)-1h", eventDate: eventDate, offset: -3600)
                                reminderChip("1 day", id: "family-\(item.id)-1d", eventDate: eventDate, offset: -86400)
                                reminderChip("1 week", id: "family-\(item.id)-7d", eventDate: eventDate, offset: -604800)
                                reminderChip("1 month", id: "family-\(item.id)-30d", eventDate: eventDate, offset: -2592000)
                            }
                        }
                    }
                }
            }
            .padding(HavenTheme.pageMargin)
        }
        .background(HavenColors.background)
        .navigationTitle(isEditing ? "Edit" : "Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundStyle(HavenColors.navy)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showReschedule = true
                    } label: {
                        Label("Set / Change Date", systemImage: "calendar")
                    }
                    Button {
                        selectedMemberIds = Set(item.taggedMemberIds ?? [])
                        showTagging = true
                    } label: {
                        Label("Tag Members", systemImage: "tag")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(HavenColors.navy)
                }
            }
        }
        .task {
            familyMembers = (try? await db.fetchFamilyMembers()) ?? []
            await loadReminders()
        }
        .alert("Delete this item?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await db.deleteInboxItem(id: item.id)
                    Haptics.success()
                    onDelete()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showReschedule) {
            NavigationStack {
                DatePicker("Event Date", selection: $rescheduleDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .tint(HavenColors.navy800)
                    .padding()
                    .navigationTitle("Set Event Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showReschedule = false }
                                .foregroundStyle(HavenColors.navy)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save") {
                                Task {
                                    try? await db.updateInboxItemEventDate(id: item.id, eventDate: rescheduleDate)
                                    Haptics.success()
                                    showReschedule = false
                                    onUpdate()
                                }
                            }
                            .foregroundStyle(HavenColors.navy)
                            .fontWeight(.semibold)
                        }
                    }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showTagging) {
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
                                Text("\(member.firstName) \(member.lastName)")
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Spacer()
                                Image(systemName: selectedMemberIds.contains(member.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedMemberIds.contains(member.id) ? HavenColors.navy : HavenColors.textTertiary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Tag Members")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { showTagging = false }
                            .foregroundStyle(HavenColors.navy)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            Task {
                                try? await db.updateInboxItemTags(id: item.id, memberIds: Array(selectedMemberIds))
                                Haptics.success()
                                showTagging = false
                                onUpdate()
                            }
                        }
                        .foregroundStyle(HavenColors.navy)
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Reminders

    private func reminderChip(_ label: String, id: String, eventDate: Date, offset: TimeInterval) -> some View {
        let isSet = activeReminders.contains(id)
        return Button {
            Haptics.light()
            let center = UNUserNotificationCenter.current()
            if isSet {
                center.removePendingNotificationRequests(withIdentifiers: [id])
                activeReminders.remove(id)
            } else {
                let alertDate = eventDate.addingTimeInterval(offset)
                guard alertDate > Date() else { return }
                let content = UNMutableNotificationContent()
                content.title = "Family Event Reminder"
                content.body = item.title
                content.sound = .default
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
                activeReminders.insert(id)
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: isSet ? "bell.fill" : "bell")
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isSet ? .white : HavenColors.navy700)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSet ? HavenColors.navy : HavenColors.navy.opacity(0.06))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func loadReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        activeReminders = Set(pending.filter { $0.identifier.hasPrefix("family-\(item.id)") }.map { $0.identifier })
    }

    // MARK: - Helpers

    private var categoryIcon: String {
        switch item.familyCategory?.lowercased() {
        case "school": return "graduationcap.fill"
        case "events": return "party.popper.fill"
        case "medical": return "cross.case.fill"
        case "activities": return "figure.run"
        case "travel": return "airplane"
        case "personal": return "person.fill"
        default: return "envelope.fill"
        }
    }

    private var categoryColor: Color {
        switch item.familyCategory?.lowercased() {
        case "school": return HavenColors.info
        case "events": return HavenColors.warning
        case "medical": return HavenColors.critical
        case "activities": return HavenColors.success
        case "travel": return HavenColors.navy
        case "personal": return HavenColors.textSecondary
        default: return HavenColors.navy
        }
    }
}

// Simple flow layout for tags
private struct FamilyTagFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

import SwiftUI

/// Detail/edit view for a calendar-synced family event.
/// Allows editing title, date, time, all-day toggle, and tagging family members.
struct CalendarEventDetailView: View {
    let event: FamilyEventRow
    let familyMembers: [FamilyMemberRow]
    var onUpdate: (() -> Void)?
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isAllDay: Bool
    @State private var selectedMemberIds: Set<UUID>
    @State private var isSaving = false
    @State private var showDeleteConfirm = false

    private let db = DatabaseService.shared

    init(event: FamilyEventRow, familyMembers: [FamilyMemberRow], onUpdate: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.event = event
        self.familyMembers = familyMembers
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _title = State(initialValue: event.title)
        _startDate = State(initialValue: event.startDate)
        _endDate = State(initialValue: event.endDate ?? event.startDate.addingTimeInterval(3600))
        _isAllDay = State(initialValue: event.allDay)
        _selectedMemberIds = State(initialValue: Set(event.taggedMemberIds ?? []))
    }

    var body: some View {
        Form {
            // Event info
            Section {
                TextField("Event title", text: $title)
                    .font(HavenTypography.body)

                Toggle("All Day", isOn: $isAllDay)

                DatePicker("Starts", selection: $startDate, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])

                if !isAllDay {
                    DatePicker("Ends", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                }
            }

            // Location
            if let location = event.location, !location.isEmpty {
                Section("Location") {
                    HStack {
                        Image(systemName: "mappin")
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(location)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }

            // Tag family members
            if !familyMembers.isEmpty {
                Section("Tag Family Members") {
                    ForEach(familyMembers) { member in
                        Button {
                            if selectedMemberIds.contains(member.id) {
                                selectedMemberIds.remove(member.id)
                            } else {
                                selectedMemberIds.insert(member.id)
                            }
                        } label: {
                            HStack {
                                Text(member.firstName)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Spacer()
                                if selectedMemberIds.contains(member.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(HavenColors.navy)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(HavenColors.navy.opacity(0.2))
                                }
                            }
                        }
                    }
                }
            }

            // Source info
            Section {
                HStack {
                    Text("Source")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                    Text(sourceLabel)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if event.source == "ios_calendar" {
                    Text("Changes here won't sync back to your iPhone calendar.")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            // Delete
            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Delete Event", systemImage: "trash")
                            .font(HavenTypography.uiLabel)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(HavenColors.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    save()
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save").fontWeight(.semibold)
                    }
                }
                .disabled(title.isEmpty || isSaving)
            }
        }
        .alert("Delete this event?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await CalendarSyncService.shared.deleteEvent(event)
                    onDelete?()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if event.source == "ios_calendar" {
                Text("This will also remove it from your iPhone calendar.")
            }
        }
    }

    private var sourceLabel: String {
        switch event.source {
        case "ios_calendar": return "iPhone Calendar"
        case "email_invite": return "Calendar Invite"
        case "email_parsed": return "Email"
        case "manual": return "Added Manually"
        default: return event.source.capitalized
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                try await db.updateFamilyEvent(
                    id: event.id,
                    title: title,
                    startDate: startDate,
                    endDate: isAllDay ? nil : endDate,
                    allDay: isAllDay,
                    taggedMemberIds: Array(selectedMemberIds)
                )
                Haptics.success()
                onUpdate?()
                dismiss()
            } catch {
                print("[CalendarEvent] Save failed: \(error)")
                Haptics.error()
                isSaving = false
            }
        }
    }
}

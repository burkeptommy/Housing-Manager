import SwiftUI

struct FamilyMemberProfileView: View {
    let member: FamilyMemberRow

    @StateObject private var viewModel: FamilyMemberProfileViewModel
    @State private var showEditForm = false
    @State private var showAllTasks = false
    @State private var showAllEvents = false
    @State private var selectedTask: MaintenanceTaskDBRow?

    init(member: FamilyMemberRow) {
        self.member = member
        _viewModel = StateObject(wrappedValue: FamilyMemberProfileViewModel.cached(for: member))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing16) {
                heroSection
                documentsSection
                tasksSection
                eventsSection

                if !viewModel.vehicles.isEmpty {
                    vehiclesSection
                }

                estateReadinessSection
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.bottom, 40)
        }
        .background(HavenColors.background)
        .navigationTitle("\(member.firstName)'s Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    Haptics.light()
                    showEditForm = true
                }
                .foregroundStyle(HavenColors.textPrimary)
            }
        }
        .sheet(isPresented: $showEditForm) {
            NavigationStack {
                FamilyMemberFormView(existingMember: member, onSave: {
                    Task { await viewModel.refresh() }
                })
            }
        }
        .sheet(item: $selectedTask) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(task: task, onTaskCompleted: {
                    Task { await viewModel.refresh() }
                })
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            Analytics.track(.memberProfileViewed, ["member_id": member.id.uuidString, "relationship": member.relationship])
            await viewModel.loadData()
        }
        .trackScreen("FamilyMemberProfile")
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            FamilyAvatarView(member: member, size: 88, showName: false)

            Text("\(member.firstName) \(member.lastName)")
                .font(HavenTypography.fraunces(size: 20, weight: 700))
                .foregroundStyle(HavenColors.textPrimary)

            Text(member.relationship)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)

            if let age = computeAge(member.dateOfBirth) {
                Text("\(age) years old")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            if let school = member.school, !school.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 10))
                    Text(school)
                        .font(HavenTypography.caption)
                }
                .foregroundStyle(HavenColors.textSecondary)
            }

            if member.isExpecting == true {
                Text("Arriving Soon")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AvatarColor.rose.color)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, HavenTheme.spacing16)
    }

    // MARK: - Documents

    @ViewBuilder
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            sectionHeader("DOCUMENTS", count: viewModel.documents.count)

            if viewModel.documents.isEmpty {
                emptyCard(icon: "doc.text.fill", text: "No documents linked to \(member.firstName)")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.documents.prefix(3).enumerated()), id: \.element.id) { index, doc in
                        NavigationLink {
                            DocumentDetailView(documentID: doc.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(HavenColors.navy700)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(doc.title)
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                        .lineLimit(1)
                                    Text(doc.category)
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, HavenTheme.spacing12)
                        }
                        .buttonStyle(.plain)

                        if index < min(viewModel.documents.count, 3) - 1 {
                            Divider().padding(.leading, 48).overlay(HavenColors.beige200)
                        }
                    }
                }
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                .havenShadow()

                if viewModel.documents.count > 3 {
                    viewMoreButton("View All \(viewModel.documents.count) Documents") {
                        NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
                    }
                }
            }
        }
    }

    // MARK: - Tasks

    @ViewBuilder
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            sectionHeader("TASKS", count: viewModel.assignedTasks.count)

            if viewModel.assignedTasks.isEmpty {
                emptyCard(icon: "checkmark.circle.fill", text: "No tasks assigned to \(member.firstName)", iconColor: HavenColors.success)
            } else {
                let visibleTasks = showAllTasks ? viewModel.assignedTasks : Array(viewModel.assignedTasks.prefix(3))

                VStack(spacing: 0) {
                    ForEach(Array(visibleTasks.enumerated()), id: \.element.id) { index, task in
                        let isOverdue = taskIsOverdue(task)

                        Button {
                            Haptics.light()
                            selectedTask = task
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: MaintenanceTaskIcon.icon(for: task))
                                    .font(.system(size: 14))
                                    .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.navy700)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                        .lineLimit(1)
                                    Text(isOverdue ? "Overdue" : "Due: \(task.nextDueDate.havenDateShort)")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.textSecondary)
                                }

                                Spacer()

                                if let priority = task.priority {
                                    Text(priority.capitalized)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(priorityColor(priority))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(priorityColor(priority).opacity(0.12))
                                        .clipShape(Capsule())
                                }

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, HavenTheme.spacing12)
                        }
                        .buttonStyle(.plain)

                        if index < visibleTasks.count - 1 {
                            Divider().padding(.leading, 48).overlay(HavenColors.beige200)
                        }
                    }
                }
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                .havenShadow()

                if viewModel.assignedTasks.count > 3 && !showAllTasks {
                    viewMoreButton("View All \(viewModel.assignedTasks.count) Tasks") {
                        withAnimation(HavenTheme.animationStandard) { showAllTasks = true }
                    }
                }
            }
        }
    }

    // MARK: - Events

    @ViewBuilder
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            sectionHeader("UPCOMING EVENTS", count: viewModel.upcomingEvents.count)

            if viewModel.upcomingEvents.isEmpty {
                emptyCard(icon: "calendar", text: "No upcoming events for \(member.firstName)")
            } else {
                let visibleEvents = showAllEvents ? viewModel.upcomingEvents : Array(viewModel.upcomingEvents.prefix(3))

                VStack(spacing: 0) {
                    ForEach(Array(visibleEvents.enumerated()), id: \.element.id) { index, event in
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundStyle(HavenColors.navy700)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Text(event.startDate.havenFull)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }

                            Spacer()

                            let days = Calendar.current.dateComponents([.day], from: Date(), to: event.startDate).day ?? 0
                            Text(days == 0 ? "Today" : days == 1 ? "Tomorrow" : "\(days)d")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, HavenTheme.spacing12)

                        if index < visibleEvents.count - 1 {
                            Divider().padding(.leading, 48).overlay(HavenColors.beige200)
                        }
                    }
                }
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                .havenShadow()

                if viewModel.upcomingEvents.count > 3 && !showAllEvents {
                    viewMoreButton("View All \(viewModel.upcomingEvents.count) Events") {
                        withAnimation(HavenTheme.animationStandard) { showAllEvents = true }
                    }
                }
            }
        }
    }

    // MARK: - Vehicles

    @ViewBuilder
    private var vehiclesSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            sectionHeader("VEHICLES", count: viewModel.vehicles.count)

            VStack(spacing: 0) {
                ForEach(viewModel.vehicles) { vehicle in
                    HStack(spacing: 12) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 24)
                        Text(vehicle.displayName)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, HavenTheme.spacing12)
                }
            }
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()
        }
    }

    // MARK: - Estate Readiness

    private var estateReadinessSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("ESTATE READINESS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            HStack(spacing: 12) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.navy700)

                Text("\(member.firstName) is covered by \(viewModel.documents.count) document\(viewModel.documents.count == 1 ? "" : "s")")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)

                Spacer()

                Button {
                    Haptics.light()
                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
                } label: {
                    Text("View")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.navy500)
                }
                .buttonStyle(.plain)
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        }
    }

    // MARK: - Shared Components

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(HavenColors.navy800)
                    .clipShape(Circle())
            }
            Spacer()
        }
    }

    private func emptyCard(icon: String, text: String, iconColor: Color = HavenColors.textTertiary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)
            Text(text)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(HavenTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    private func viewMoreButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Text(text)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.navy500)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func taskIsOverdue(_ task: MaintenanceTaskDBRow) -> Bool {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: task.nextDueDate) else { return false }
        return d < Date()
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return HavenColors.critical
        case "medium": return HavenColors.warning
        case "low": return Color(red: 0.40, green: 0.55, blue: 0.42)
        default: return HavenColors.textTertiary
        }
    }

    private func computeAge(_ dateOfBirth: String?) -> Int? {
        guard let dobStr = dateOfBirth else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let dob = formatter.date(from: dobStr) else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }
}

// MARK: - View Model

@MainActor
final class FamilyMemberProfileViewModel: ObservableObject {
    let member: FamilyMemberRow

    @Published var documents: [DocumentRow] = []
    @Published var vehicles: [VehicleRow] = []
    @Published var assignedTasks: [MaintenanceTaskDBRow] = []
    @Published var upcomingEvents: [FamilyEventRow] = []
    @Published var isLoading = false
    private var hasLoadedOnce = false

    /// Per-member cache so re-entering a profile reuses the hydrated VM
    /// (tasks/events/docs/vehicles render instantly) instead of refetching.
    private static var cache: [UUID: FamilyMemberProfileViewModel] = [:]

    static func cached(for member: FamilyMemberRow) -> FamilyMemberProfileViewModel {
        if let existing = cache[member.id] { return existing }
        let vm = FamilyMemberProfileViewModel(member: member)
        cache[member.id] = vm
        return vm
    }

    static func invalidateCache(memberId: UUID? = nil) {
        if let id = memberId { cache.removeValue(forKey: id) }
        else { cache.removeAll() }
    }

    init(member: FamilyMemberRow) {
        self.member = member
    }

    func loadData() async {
        // Skip reload if already loaded (use refresh() for manual refresh)
        guard !hasLoadedOnce else { return }
        isLoading = true
        defer { isLoading = false; hasLoadedOnce = true }

        let db = DatabaseService.shared

        // Resolve the user ID for this member (either linkedUserId or current user match)
        let resolvedUserId: UUID? = await resolveUserId()

        // Fetch documents linked to this member
        do {
            struct DocLink: Codable {
                let documentId: UUID
                enum CodingKeys: String, CodingKey { case documentId = "document_id" }
            }
            let links: [DocLink] = try await HavenSupabase.from("document_family_members")
                .select("document_id")
                .eq("family_member_id", value: member.id.uuidString)
                .execute()
                .value

            if !links.isEmpty {
                let docIds = links.map(\.documentId)
                let allDocs = try await db.fetchDocuments()
                documents = allDocs.filter { docIds.contains($0.id) }
            }
        } catch {
            print("[MemberProfile] Failed to load documents: \(error)")
        }

        // Fetch vehicles where this member is a covered driver
        do {
            let allVehicles = try await db.fetchVehicles()
            vehicles = allVehicles.filter { vehicle in
                // Show if member is the primary driver OR a covered driver
                if vehicle.primaryDriverId == member.id { return true }
                if let covered = vehicle.coveredDriverIds, covered.contains(member.id) { return true }
                return false
            }
        } catch {
            print("[MemberProfile] Failed to load vehicles: \(error)")
        }

        // Fetch tasks assigned to this member
        if let userId = resolvedUserId {
            do {
                let allTasks = try await db.fetchMaintenanceTasks()
                assignedTasks = allTasks
                    .filter { $0.assignedToUserId == userId }
                    .sorted { $0.nextDueDate < $1.nextDueDate }
            } catch {
                print("[MemberProfile] Failed to load tasks: \(error)")
            }
        }

        // Fetch upcoming events tagged to this member
        do {
            let user = try? await db.fetchCurrentUser()
            if let householdId = user?.householdId {
                let allEvents = try await db.fetchUpcomingFamilyEvents(householdId: householdId)
                upcomingEvents = allEvents.filter { event in
                    // Only show events explicitly tagged to this member
                    guard let tagged = event.taggedMemberIds, !tagged.isEmpty else { return false }
                    return tagged.contains(member.id)
                }
            }
        } catch {
            print("[MemberProfile] Failed to load events: \(error)")
        }
    }

    /// Resolve the user ID for task assignment lookup.
    /// Searches all household users to find a match for this family member.
    func refresh() async {
        hasLoadedOnce = false
        await loadData()
    }

    private func resolveUserId() async -> UUID? {
        // Direct link is the most reliable
        if let linkedId = member.linkedUserId {
            return linkedId
        }
        // Search all household users for a match by email or name
        do {
            let allUsers = try await DatabaseService.shared.fetchHouseholdUsers()
            let memberFullName = "\(member.firstName) \(member.lastName)".lowercased()
            let memberFirst = member.firstName.lowercased()
            let memberEmail = member.email?.lowercased()

            for user in allUsers {
                // Match by email
                if let memberEmail, !memberEmail.isEmpty,
                   user.email.lowercased() == memberEmail {
                    return user.id
                }
                // Match by full name
                if let fullName = user.fullName?.lowercased() {
                    if fullName == memberFullName { return user.id }
                    // First name match (handles last name differences)
                    if let userFirst = fullName.components(separatedBy: " ").first,
                       userFirst == memberFirst { return user.id }
                }
            }
        } catch {}
        return nil
    }
}

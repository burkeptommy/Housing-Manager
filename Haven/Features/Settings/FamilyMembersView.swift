import SwiftUI

struct FamilyMembersView: View {
    @State private var members: [FamilyMemberRow] = []
    @State private var documents: [DocumentRow] = []
    @State private var isLoading = true
    @State private var showAddChooser = false
    @State private var addMemberMode: AddFamilyMemberMode?
    @State private var editingMember: FamilyMemberRow?
    @State private var invitingMember: FamilyMemberRow?
    @State private var navigationPath = NavigationPath()

    private let db = DatabaseService.shared

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if isLoading {
                    ProgressView("Loading family members...")
                } else if members.isEmpty {
                    ContentUnavailableView {
                        Label("Your Family", systemImage: "person.3.fill")
                    } description: {
                        Text("Add family members to track documents, estate planning, and readiness for each person.")
                    } actions: {
                        Button("Add Family Member") { showAddChooser = true }
                            .buttonStyle(.borderedProminent)
                            .tint(HavenColors.navy)
                    }
                } else {
                    membersList
                }
            }
            .navigationTitle("Family Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddChooser = true } label: {
                        Image(systemName: "plus").foregroundStyle(HavenColors.navy)
                    }
                }
            }
            .trackScreen("FamilyMembersView")
            .onAppear { Task { await loadData() } }
            .sheet(isPresented: $showAddChooser) {
                AddFamilyMemberChooserSheet { mode in
                    addMemberMode = mode
                }
                .presentationDetents([.medium])
            }
            .sheet(item: $addMemberMode) { mode in
                NavigationStack {
                    FamilyMemberFormView(initialMode: mode, onSave: { await loadData() })
                }
            }
            .sheet(item: $editingMember) { member in
                NavigationStack {
                    FamilyMemberFormView(existingMember: member, onSave: { await loadData() })
                }
            }
            .sheet(item: $invitingMember) { member in
                InviteToHavenSheet(familyMember: member, onInviteSent: {
                    Task { await loadData() }
                })
            }
            .navigationDestination(for: FamilyMemberRow.self) { member in
                NewArrivalChecklistView(member: member, documents: documents)
            }
        }
    }

    private var membersList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Expecting members — prominent section
                let expecting = members.filter { $0.isExpecting == true }
                if !expecting.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "stroller.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(AvatarColor.rose.color)
                            Text("EXPECTING")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                        }

                        ForEach(expecting) { member in
                            expectingMemberCard(member)
                        }
                    }

                    if !members.filter({ $0.isExpecting != true }).isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                    }
                }

                // Regular members
                let active = members.filter { $0.isExpecting != true }
                ForEach(active) { member in memberRow(member) }
            }
            .padding()
        }
        .background(HavenColors.background)
    }

    // MARK: - Expecting Member Card

    private func expectingMemberCard(_ member: FamilyMemberRow) -> some View {
        VStack(spacing: 0) {
            // Main row — taps to edit
            Button { editingMember = member } label: {
                HavenCard {
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            FamilyAvatarView(member: member, size: 48, showName: false)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(member.firstName.isEmpty ? "Baby" : "\(member.firstName) \(member.lastName)")
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)

                                HStack(spacing: 6) {
                                    if let expectedDate = member.expectedDate {
                                        let daysLeft = daysUntilDate(expectedDate)
                                        if let days = daysLeft {
                                            if days > 0 {
                                                Text("Due \(expectedDate.havenDateShort)")
                                                    .font(HavenTypography.uiCaption)
                                                    .foregroundStyle(AvatarColor.rose.color)
                                                Text("•")
                                                    .foregroundStyle(HavenColors.textTertiary)
                                                Text("\(days) days")
                                                    .font(HavenTypography.uiCaption)
                                                    .foregroundStyle(HavenColors.textTertiary)
                                            } else if days == 0 {
                                                Text("Due today!")
                                                    .font(HavenTypography.uiCaption)
                                                    .foregroundStyle(AvatarColor.rose.color)
                                            } else {
                                                Text("Born \(abs(days)) days ago")
                                                    .font(HavenTypography.uiCaption)
                                                    .foregroundStyle(HavenColors.success)
                                            }
                                        }
                                    }
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(HavenColors.textTertiary)
                        }

                        // Checklist shortcut
                        Button {
                            Haptics.light()
                            navigationPath.append(member)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AvatarColor.rose.color)
                                Text("View Preparation Checklist")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.navy)

                                Spacer()

                                let progress = checklistProgress(for: member)
                                Text("\(progress.completed)/\(progress.total)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(HavenColors.textTertiary)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AvatarColor.rose.color.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Regular Member Row

    private func memberRow(_ member: FamilyMemberRow) -> some View {
        Button { editingMember = member } label: {
            HavenCard {
                HStack(spacing: 14) {
                    FamilyAvatarView(member: member, size: 48, showName: false)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("\(member.firstName) \(member.lastName)")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                            if member.isLinkedUser {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(HavenColors.success)
                                    .accessibilityLabel("Connected Haven user")
                            }
                        }
                        HStack(spacing: 6) {
                            Text(member.relationship)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                            if let dob = member.dateOfBirth, let age = calculateAge(dob) {
                                Text("•").foregroundStyle(HavenColors.textTertiary)
                                Text("Age \(age)")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            if member.isLinkedUser {
                                Text("•").foregroundStyle(HavenColors.textTertiary)
                                Text("Active on Haven")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.success)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if member.isMinor != true && !member.isLinkedUser {
                Button {
                    invitingMember = member
                } label: {
                    Label("Invite to Haven", systemImage: "person.badge.plus")
                }
            }
        }
    }

    // MARK: - Helpers

    private func calculateAge(_ dobString: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let dob = formatter.date(from: dobString) else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }

    private func daysUntilDate(_ dateString: String) -> Int? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: dateString) else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }

    private func checklistProgress(for member: FamilyMemberRow) -> (completed: Int, total: Int) {
        let items = NewArrivalChecklist.items(babyName: member.firstName)
        let key = "arrivalChecklist_\(member.id.uuidString)"
        let saved = UserDefaults.standard.string(forKey: key) ?? ""
        let completedIds = Set(saved.split(separator: ",").map(String.init))
        let existingCategories = Set(documents.map(\.category))

        let completed = items.filter { item in
            if let cat = item.documentCategory, existingCategories.contains(cat) { return true }
            return completedIds.contains(item.id)
        }.count

        return (completed, items.count)
    }

    private func loadData() async {
        isLoading = true
        async let membersTask = db.fetchFamilyMembers()
        async let docsTask = db.fetchDocuments()
        members = (try? await membersTask) ?? []
        documents = (try? await docsTask) ?? []
        isLoading = false
    }
}

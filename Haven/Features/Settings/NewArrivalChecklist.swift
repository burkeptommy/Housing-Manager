import SwiftUI

// MARK: - Checklist Data Model

struct NewArrivalChecklistItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let phase: ArrivalPhase
    let documentCategory: String? // maps to document vault category
    var isCompleted: Bool = false
}

enum ArrivalPhase: String, CaseIterable {
    case beforeBirth = "Before Birth"
    case firstWeek = "First Week"
    case firstMonth = "First Month"
    case firstYear = "First Year"

    var icon: String {
        switch self {
        case .beforeBirth: return "calendar.badge.clock"
        case .firstWeek: return "heart.fill"
        case .firstMonth: return "moon.stars.fill"
        case .firstYear: return "birthday.cake.fill"
        }
    }

    var color: Color {
        switch self {
        case .beforeBirth: return AvatarColor.rose.color
        case .firstWeek: return HavenColors.critical
        case .firstMonth: return HavenColors.warning
        case .firstYear: return HavenColors.info
        }
    }
}

struct NewArrivalChecklist {
    static func items(babyName: String) -> [NewArrivalChecklistItem] {
        let name = babyName.isEmpty ? "Baby" : babyName
        return [
            // BEFORE BIRTH
            NewArrivalChecklistItem(
                id: "update_will",
                title: "Update your will",
                subtitle: "Add \(name) as a beneficiary and designate a guardian",
                icon: "doc.text.fill",
                phase: .beforeBirth,
                documentCategory: "Will"
            ),
            NewArrivalChecklistItem(
                id: "update_trust",
                title: "Update your trust",
                subtitle: "Add \(name) as a beneficiary of your living trust",
                icon: "building.columns.fill",
                phase: .beforeBirth,
                documentCategory: "Trust"
            ),
            NewArrivalChecklistItem(
                id: "guardianship",
                title: "Designate a guardian",
                subtitle: "Choose who will care for \(name) if something happens to you",
                icon: "person.2.fill",
                phase: .beforeBirth,
                documentCategory: "Guardianship Designation"
            ),
            NewArrivalChecklistItem(
                id: "life_insurance",
                title: "Review life insurance",
                subtitle: "Ensure coverage is adequate for a growing family",
                icon: "shield.fill",
                phase: .beforeBirth,
                documentCategory: "Life Insurance"
            ),
            NewArrivalChecklistItem(
                id: "health_insurance",
                title: "Notify health insurance",
                subtitle: "Understand your plan's newborn coverage and enrollment window",
                icon: "cross.case.fill",
                phase: .beforeBirth,
                documentCategory: nil
            ),
            NewArrivalChecklistItem(
                id: "hospital_bag_docs",
                title: "Prepare hospital documents",
                subtitle: "Insurance cards, IDs, birth plan, pre-registration forms",
                icon: "bag.fill",
                phase: .beforeBirth,
                documentCategory: nil
            ),

            // FIRST WEEK
            NewArrivalChecklistItem(
                id: "birth_certificate",
                title: "Apply for birth certificate",
                subtitle: "Usually started at the hospital — upload when received",
                icon: "doc.text.fill",
                phase: .firstWeek,
                documentCategory: "Birth Certificate"
            ),
            NewArrivalChecklistItem(
                id: "ssn_application",
                title: "Apply for Social Security number",
                subtitle: "Can be done at the hospital alongside the birth certificate",
                icon: "creditcard.fill",
                phase: .firstWeek,
                documentCategory: "Social Security Card"
            ),
            NewArrivalChecklistItem(
                id: "add_to_health",
                title: "Add \(name) to health insurance",
                subtitle: "Most plans require enrollment within 30 days of birth",
                icon: "cross.fill",
                phase: .firstWeek,
                documentCategory: nil
            ),

            // FIRST MONTH
            NewArrivalChecklistItem(
                id: "beneficiary_update",
                title: "Update beneficiary designations",
                subtitle: "401k, IRA, life insurance, bank accounts",
                icon: "person.badge.plus",
                phase: .firstMonth,
                documentCategory: "Beneficiary Designation"
            ),
            NewArrivalChecklistItem(
                id: "open_529",
                title: "Open a 529 college savings plan",
                subtitle: "Start saving for education with tax advantages",
                icon: "graduationcap.fill",
                phase: .firstMonth,
                documentCategory: "529 Plan"
            ),
            NewArrivalChecklistItem(
                id: "healthcare_directive",
                title: "Review healthcare directives",
                subtitle: "Update your advance directive now that you have a dependent",
                icon: "heart.text.clipboard.fill",
                phase: .firstMonth,
                documentCategory: "Healthcare Directive"
            ),

            // FIRST YEAR
            NewArrivalChecklistItem(
                id: "passport",
                title: "Get \(name)'s passport",
                subtitle: "Required for international travel — both parents must be present",
                icon: "airplane",
                phase: .firstYear,
                documentCategory: "Passport"
            ),
            NewArrivalChecklistItem(
                id: "umbrella_insurance",
                title: "Review umbrella insurance",
                subtitle: "Consider increasing coverage with a growing family",
                icon: "umbrella.fill",
                phase: .firstYear,
                documentCategory: "Umbrella Insurance"
            ),
            NewArrivalChecklistItem(
                id: "disability_insurance",
                title: "Review disability insurance",
                subtitle: "Protect your family's income if you can't work",
                icon: "figure.roll",
                phase: .firstYear,
                documentCategory: "Disability Insurance"
            ),
        ]
    }
}

// MARK: - Checklist Detail View

struct NewArrivalChecklistView: View {
    let member: FamilyMemberRow
    let documents: [DocumentRow]

    @AppStorage private var completedItemIds: String
    @State private var expandedPhases: Set<String>

    init(member: FamilyMemberRow, documents: [DocumentRow] = []) {
        self.member = member
        self.documents = documents
        let key = "arrivalChecklist_\(member.id.uuidString)"
        self._completedItemIds = AppStorage(wrappedValue: "", key)
        self._expandedPhases = State(initialValue: Set(ArrivalPhase.allCases.map(\.rawValue)))
    }

    private var completedIds: Set<String> {
        Set(completedItemIds.split(separator: ",").map(String.init))
    }

    private var allItems: [NewArrivalChecklistItem] {
        let raw = NewArrivalChecklist.items(babyName: member.firstName)
        let existingCategories = Set(documents.map(\.category))
        return raw.map { item in
            var mutableItem = item
            // Auto-complete if the document category exists in the vault
            if let cat = item.documentCategory, existingCategories.contains(cat) {
                mutableItem.isCompleted = true
            } else if completedIds.contains(item.id) {
                mutableItem.isCompleted = true
            }
            return mutableItem
        }
    }

    private var totalCount: Int { allItems.count }
    private var completedCount: Int { allItems.filter(\.isCompleted).count }
    private var progress: Double { totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0 }

    private var dueDate: Date? {
        guard let dateStr = member.expectedDate else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: dateStr)
    }

    private var daysUntilDue: Int? {
        guard let due = dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: due).day
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing16) {
                // Hero header
                heroHeader

                // Phase sections
                ForEach(ArrivalPhase.allCases, id: \.rawValue) { phase in
                    let phaseItems = allItems.filter { $0.phase == phase }
                    if !phaseItems.isEmpty {
                        phaseSection(phase: phase, items: phaseItems)
                    }
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.bottom, 100)
        }
        .background(HavenColors.background)
        .navigationTitle("New Arrival Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("NewArrivalChecklistView")
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: HavenTheme.spacing16) {
            HStack(spacing: HavenTheme.spacing16) {
                // Avatar
                FamilyAvatarView(member: member, size: 64, showName: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Preparing for \(member.firstName)")
                        .font(HavenTypography.fraunces(size: 20, weight: 700))
                        .foregroundStyle(HavenColors.textPrimary)

                    if let days = daysUntilDue {
                        if days > 0 {
                            Text("\(days) days until due date")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(AvatarColor.rose.color)
                        } else if days == 0 {
                            Text("Due today!")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(AvatarColor.rose.color)
                        } else {
                            Text("Born \(abs(days)) days ago")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.success)
                        }
                    }
                }

                Spacer()
            }

            // Progress bar
            VStack(spacing: 6) {
                HStack {
                    Text("\(completedCount) of \(totalCount) complete")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AvatarColor.rose.color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(HavenColors.beige200)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [AvatarColor.rose.color.opacity(0.7), AvatarColor.rose.color],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 8)
                            .animation(.easeInOut, value: progress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(HavenTheme.spacing20)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .havenShadow()
    }

    // MARK: - Phase Section

    private func phaseSection(phase: ArrivalPhase, items: [NewArrivalChecklistItem]) -> some View {
        let isExpanded = expandedPhases.contains(phase.rawValue)
        let phaseCompleted = items.filter(\.isCompleted).count
        let allDone = phaseCompleted == items.count

        return VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Button {
                Haptics.light()
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedPhases.contains(phase.rawValue) {
                        expandedPhases.remove(phase.rawValue)
                    } else {
                        expandedPhases.insert(phase.rawValue)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: phase.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(phase.color)

                    Text(phase.rawValue.uppercased())
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)

                    if allDone {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(HavenColors.success)
                    } else {
                        Text("\(phaseCompleted)/\(items.count)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(HavenColors.beige200)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        checklistRow(item: item)

                        if index < items.count - 1 {
                            Divider()
                                .padding(.leading, 44)
                                .overlay(HavenColors.beige200)
                        }
                    }
                }
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                .havenShadow()
            }
        }
    }

    // MARK: - Checklist Row

    private func checklistRow(item: NewArrivalChecklistItem) -> some View {
        Button {
            Haptics.light()
            toggleItem(item)
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.isCompleted ? HavenColors.success : HavenColors.beige400)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(item.isCompleted ? HavenColors.textTertiary : HavenColors.textPrimary)
                        .strikethrough(item.isCompleted)

                    Text(item.subtitle)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(2)
                }

                Spacer()

                if item.documentCategory != nil {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, HavenTheme.spacing12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toggle Logic

    private func toggleItem(_ item: NewArrivalChecklistItem) {
        var ids = completedIds
        if ids.contains(item.id) {
            ids.remove(item.id)
        } else {
            ids.insert(item.id)
        }
        Analytics.track(.newArrivalChecklistItemToggled, ["item_id": item.id, "completed": !completedIds.contains(item.id)])
        completedItemIds = ids.joined(separator: ",")
    }
}

// MARK: - Compact Summary Card (for Dashboard & Life tab)

struct NewArrivalSummaryCard: View {
    let member: FamilyMemberRow
    let completedCount: Int
    let totalCount: Int

    private var progress: Double { totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0 }

    private var daysUntilDue: Int? {
        guard let dateStr = member.expectedDate else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let due = f.date(from: dateStr) else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: due).day
    }

    var body: some View {
        HStack(spacing: 14) {
            FamilyAvatarView(member: member, size: 48, showName: false)

            VStack(alignment: .leading, spacing: 4) {
                Text("Preparing for \(member.firstName)")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let days = daysUntilDue {
                        if days > 0 {
                            Text("\(days) days to go")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(AvatarColor.rose.color)
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
                    Text("\(completedCount)/\(totalCount) ready")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            Spacer()

            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(HavenColors.beige200, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AvatarColor.rose.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .frame(width: 36, height: 36)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
    }
}

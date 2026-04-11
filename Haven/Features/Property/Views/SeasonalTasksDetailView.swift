import SwiftUI

// MARK: - Seasonal Task Group

struct SeasonalTaskGroup: Identifiable {
    var id: String { name }
    let name: String
    let icon: String
    let tasks: [MaintenanceTaskDBRow]

    var completedCount: Int {
        tasks.filter { $0.lastCompletedDate != nil }.count
    }

    var isComplete: Bool {
        !tasks.isEmpty && completedCount == tasks.count
    }

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }

    // Build 89: vendor scheduling metrics
    var vendorTasks: [MaintenanceTaskDBRow] {
        tasks.filter { $0.assignmentType?.lowercased() == "vendor" || $0.needsVendor == true }
    }

    var personalTasks: [MaintenanceTaskDBRow] {
        tasks.filter { ($0.assignmentType?.lowercased() ?? "personal") != "vendor" && $0.needsVendor != true }
    }

    var vendorAssignedCount: Int {
        vendorTasks.filter { $0.assignedContractorId != nil }.count
    }

    var vendorCoverage: Double {
        guard !vendorTasks.isEmpty else { return 1.0 }
        return Double(vendorAssignedCount) / Double(vendorTasks.count)
    }

    var isFullyCovered: Bool {
        vendorTasks.isEmpty || vendorAssignedCount == vendorTasks.count
    }

    /// Primary contractor name for this group (most common assigned contractor)
    func primaryContractorName(lookup: (UUID?) -> String?) -> String? {
        let assigned = vendorTasks.compactMap { $0.assignedContractorId }
        guard let first = assigned.first else { return nil }
        return lookup(first)
    }
}

// MARK: - Grouping Logic

enum SeasonalTaskGrouper {

    /// Groups seasonal tasks into 4-5 homeowner-friendly categories.
    /// Tasks that don't match a known group get folded into the closest match.
    static func group(_ tasks: [MaintenanceTaskDBRow], systemNameLookup: @escaping (UUID?) -> String?) -> [SeasonalTaskGroup] {
        // Classify each task by examining its system name, title, and category
        var landscaping: [MaintenanceTaskDBRow] = []
        var exterior: [MaintenanceTaskDBRow] = []
        var safety: [MaintenanceTaskDBRow] = []
        var hvacMechanical: [MaintenanceTaskDBRow] = []
        var waterFoundation: [MaintenanceTaskDBRow] = []

        for task in tasks {
            let title = task.title.lowercased()
            let system = (systemNameLookup(task.systemId) ?? "").lowercased()

            if matchesLandscaping(title: title, system: system) {
                landscaping.append(task)
            } else if matchesExterior(title: title, system: system) {
                exterior.append(task)
            } else if matchesSafety(title: title, system: system) {
                safety.append(task)
            } else if matchesHVAC(title: title, system: system) {
                hvacMechanical.append(task)
            } else {
                waterFoundation.append(task)
            }
        }

        var groups: [SeasonalTaskGroup] = []

        if !landscaping.isEmpty {
            groups.append(SeasonalTaskGroup(name: "Landscaping", icon: "leaf.fill", tasks: landscaping))
        }
        if !exterior.isEmpty {
            groups.append(SeasonalTaskGroup(name: "Exterior", icon: "house.fill", tasks: exterior))
        }
        if !safety.isEmpty {
            groups.append(SeasonalTaskGroup(name: "Safety", icon: "shield.checkered", tasks: safety))
        }
        if !hvacMechanical.isEmpty {
            groups.append(SeasonalTaskGroup(name: "HVAC & Mechanical", icon: "fan.fill", tasks: hvacMechanical))
        }
        if !waterFoundation.isEmpty {
            groups.append(SeasonalTaskGroup(name: "Water & Foundation", icon: "drop.fill", tasks: waterFoundation))
        }

        return groups
    }

    private static func matchesLandscaping(title: String, system: String) -> Bool {
        let keywords = ["fertiliz", "lawn", "mulch", "prune", "shrub", "hedge", "aerat", "grade check",
                        "drainage", "retaining wall", "landscap", "irrigation", "startup irrigation",
                        "winterize irrigation", "tree branch", "leaf", "leaves"]
        return keywords.contains { title.contains($0) || system.contains($0) }
    }

    private static func matchesExterior(title: String, system: String) -> Bool {
        let keywords = ["power wash", "siding", "shingle", "gutter", "downspout", "deck", "patio",
                        "driveway", "caulk", "window", "door", "weatherstrip", "roof", "flashing",
                        "exterior"]
        return keywords.contains { title.contains($0) || system.contains($0) }
    }

    private static func matchesSafety(title: String, system: String) -> Bool {
        let keywords = ["smoke", "carbon monoxide", "fire ext", "detector", "battery", "batteries",
                        "pest", "termite", "entry point", "seal gap", "chimney", "firebox"]
        return keywords.contains { title.contains($0) || system.contains($0) }
    }

    private static func matchesHVAC(title: String, system: String) -> Bool {
        let keywords = ["hvac", "tune-up", "cooling", "heating", "furnace", "air condition",
                        "generator", "pool open", "pool clos", "pool equip", "winteriz"]
        return keywords.contains { title.contains($0) || system.contains($0) }
    }
}

// MARK: - Detail View

struct SeasonalTasksDetailView: View {
    let season: String
    let tasks: [MaintenanceTaskDBRow]
    let completedCount: Int
    let nextSeason: String
    let nextSeasonTasks: [MaintenanceTaskDBRow]
    let systemNameLookup: (UUID?) -> String?
    var contractorNameLookup: ((UUID?) -> String?)? = nil
    var onFindVendor: ((MaintenanceTaskDBRow) -> Void)? = nil

    @State private var expandedGroupId: String?
    @State private var selectedTask: MaintenanceTaskDBRow?

    private var groups: [SeasonalTaskGroup] {
        SeasonalTaskGrouper.group(tasks, systemNameLookup: systemNameLookup)
    }

    private var nextGroups: [SeasonalTaskGroup] {
        SeasonalTaskGrouper.group(nextSeasonTasks, systemNameLookup: systemNameLookup)
    }

    private var vendorCoveredCount: Int {
        groups.filter(\.isFullyCovered).count
    }

    private var totalVendorTasks: Int {
        groups.reduce(0) { $0 + $1.vendorTasks.count }
    }

    private var assignedVendorTasks: Int {
        groups.reduce(0) { $0 + $1.vendorAssignedCount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Progress header — vendor assignment focus
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if totalVendorTasks > 0 {
                            Text("\(assignedVendorTasks) of \(totalVendorTasks) vendors assigned")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(HavenColors.textSecondary)
                        } else {
                            Text("\(completedCount) of \(tasks.count) done")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        Text("\(vendorCoveredCount)/\(groups.count) groups ready")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    if totalVendorTasks > 0 {
                        ProgressView(value: Double(assignedVendorTasks), total: Double(max(totalVendorTasks, 1)))
                            .tint(vendorProgressColor)
                    } else {
                        ProgressView(value: Double(completedCount), total: Double(max(tasks.count, 1)))
                            .tint(progressColor)
                    }
                }
                .padding()
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                .havenShadow()

                // Current season groups
                if !groups.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(season.uppercased())
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        ForEach(groups) { group in
                            groupCard(group)
                        }
                    }
                }

                // Next season preview
                if !nextGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COMING UP: \(nextSeason.uppercased())")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        ForEach(nextGroups) { group in
                            groupCardPreview(group)
                        }
                    }
                }
            }
            .padding()
        }
        .background(HavenColors.background)
        .navigationTitle("\(season) Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("SeasonalTasksDetailView", properties: ["season": season])
        .sheet(item: $selectedTask) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(
                    task: task,
                    onTaskCompleted: {
                        let currentExpanded = expandedGroupId
                        expandedGroupId = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            expandedGroupId = currentExpanded
                        }
                    },
                    onDeleteTask: {
                        let currentExpanded = expandedGroupId
                        expandedGroupId = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            expandedGroupId = currentExpanded
                        }
                    }
                )
            }
            .presentationDetents([.large])
        }
    }

    private var progressColor: Color {
        let progress = tasks.isEmpty ? 0.0 : Double(completedCount) / Double(tasks.count)
        if progress >= 0.75 { return HavenColors.success }
        if progress >= 0.4 { return HavenColors.warning }
        return HavenColors.critical
    }

    private var vendorProgressColor: Color {
        if totalVendorTasks == 0 { return HavenColors.success }
        let ratio = Double(assignedVendorTasks) / Double(totalVendorTasks)
        if ratio >= 0.75 { return HavenColors.success }
        if ratio >= 0.4 { return HavenColors.warning }
        return HavenColors.critical
    }

    // MARK: - Group Card

    private func groupCard(_ group: SeasonalTaskGroup) -> some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 12) {
                Image(systemName: group.isFullyCovered ? "checkmark.circle.fill" : group.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(group.isFullyCovered ? HavenColors.success : HavenColors.navy800)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(HavenTypography.body)
                        .foregroundStyle(group.isFullyCovered ? HavenColors.textTertiary : HavenColors.textPrimary)

                    // Vendor status subtitle
                    if !group.vendorTasks.isEmpty {
                        if group.isFullyCovered {
                            if let contractorName = group.primaryContractorName(lookup: contractorNameLookup ?? { _ in nil }) {
                                Text(contractorName)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.success)
                            } else {
                                Text("Vendor assigned")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.success)
                            }
                        } else {
                            Text("Needs vendor")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.warning)
                        }
                    } else {
                        Text("\(group.completedCount) of \(group.tasks.count) done")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                Spacer()

                // Status badge
                if !group.vendorTasks.isEmpty && !group.isFullyCovered {
                    Text("\(group.vendorTasks.count - group.vendorAssignedCount) needed")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(HavenColors.warning.opacity(0.12))
                        .clipShape(Capsule())
                } else if !group.vendorTasks.isEmpty && group.isFullyCovered {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(HavenColors.success)
                }

                Image(systemName: expandedGroupId == group.id ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(HavenTheme.animationStandard) {
                    if expandedGroupId == group.id {
                        expandedGroupId = nil
                    } else {
                        expandedGroupId = group.id
                    }
                }
                Haptics.selection()
            }

            // Expanded subtasks
            if expandedGroupId == group.id {
                Divider().overlay(HavenColors.beige200)
                    .padding(.horizontal, 14)

                VStack(spacing: 0) {
                    ForEach(group.tasks) { task in
                        subtaskRow(task)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func subtaskRow(_ task: MaintenanceTaskDBRow) -> some View {
        let isVendor = task.assignmentType?.lowercased() == "vendor" || task.needsVendor == true
        let hasVendor = task.assignedContractorId != nil
        let isCompleted = task.lastCompletedDate != nil

        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Status icon
                if isVendor {
                    Image(systemName: hasVendor ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.questionmark")
                        .font(.system(size: 14))
                        .foregroundStyle(hasVendor ? HavenColors.success : HavenColors.warning)
                } else {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(isCompleted ? HavenColors.success : HavenColors.textTertiary)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(task.title)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(isCompleted ? HavenColors.textTertiary : HavenColors.textPrimary)
                        .strikethrough(isCompleted)
                        .lineLimit(2)

                    if isVendor, hasVendor, let name = contractorNameLookup?(task.assignedContractorId) {
                        Text(name)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.success)
                    } else if let systemName = systemNameLookup(task.systemId) {
                        Text(systemName)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                Spacer()

                // Find a Pro CTA for unassigned vendor tasks
                if isVendor && !hasVendor {
                    Button {
                        onFindVendor?(task)
                    } label: {
                        Text("Find a Pro")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(HavenColors.navy800)
                            .clipShape(Capsule())
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedTask = task
                Haptics.selection()
            }
        }
    }

    // MARK: - Preview Card (next season)

    private func groupCardPreview(_ group: SeasonalTaskGroup) -> some View {
        HStack(spacing: 12) {
            Image(systemName: group.icon)
                .font(.system(size: 16))
                .foregroundStyle(HavenColors.textTertiary)
                .frame(width: 28)

            Text(group.name)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            Spacer()

            Text("\(group.tasks.count) tasks")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Circular Progress

private struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(HavenColors.beige200, lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }

    private var progressColor: Color {
        if progress >= 0.75 { return HavenColors.success }
        if progress >= 0.4 { return HavenColors.warning }
        return HavenColors.critical
    }
}

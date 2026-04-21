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
        // Deduplicate by templateId first (bundled tasks share the same key),
        // then by title for tasks without a templateId. Keeps the first
        // occurrence (which is the vendor-assigned one if it exists, since
        // assigned tasks sort before unassigned in the fetch).
        var seenTemplateIds = Set<String>()
        var seenTitles = Set<String>()
        let dedupedTasks = tasks.filter { task in
            if let templateId = task.templateId, !templateId.isEmpty {
                return seenTemplateIds.insert(templateId).inserted
            }
            let normalizedTitle = task.title.lowercased()
                .replacingOccurrences(of: "schedule ", with: "")
            return seenTitles.insert(normalizedTitle).inserted
        }

        // Classify each task by examining its system name, title, and category
        var landscaping: [MaintenanceTaskDBRow] = []
        var exterior: [MaintenanceTaskDBRow] = []
        var safety: [MaintenanceTaskDBRow] = []
        var hvacMechanical: [MaintenanceTaskDBRow] = []
        var waterFoundation: [MaintenanceTaskDBRow] = []

        for task in dedupedTasks {
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
    var contractorLookup: ((UUID?) -> ContractorRow?)? = nil
    var onFindVendor: ((MaintenanceTaskDBRow) -> Void)? = nil
    var propertyId: UUID? = nil
    var serviceRecords: [ServiceRecordRow] = []

    @State private var expandedGroupId: String?
    @State private var selectedTask: MaintenanceTaskDBRow?
    @State private var liveTasks: [MaintenanceTaskDBRow]?
    @State private var liveNextTasks: [MaintenanceTaskDBRow]?

    private var effectiveTasks: [MaintenanceTaskDBRow] { liveTasks ?? tasks }
    private var effectiveNextTasks: [MaintenanceTaskDBRow] { liveNextTasks ?? nextSeasonTasks }

    private var groups: [SeasonalTaskGroup] {
        SeasonalTaskGrouper.group(effectiveTasks, systemNameLookup: systemNameLookup)
    }

    private var nextGroups: [SeasonalTaskGroup] {
        SeasonalTaskGrouper.group(effectiveNextTasks, systemNameLookup: systemNameLookup)
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

    /// Season is fully complete when all vendor tasks have assigned contractors.
    private var isSeasonComplete: Bool {
        totalVendorTasks > 0 && assignedVendorTasks == totalVendorTasks
    }

    private var seasonYear: Int {
        Season(rawValue: season).map { Season.year(for: $0) } ?? Calendar.current.component(.year, from: .now)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if effectiveTasks.isEmpty {
                    emptySeasonContent
                } else {
                    // Progress header
                    progressHeader

                    if isSeasonComplete {
                        completedSeasonContent
                    } else {
                        activeSeasonContent
                    }
                }
            }
            .padding()
        }
        .background(HavenColors.background)
        .navigationTitle(isSeasonComplete ? "\(season) \(String(seasonYear)) \u{00B7} Complete" : "\(season) \(String(seasonYear))")
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
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task { await reloadTasks() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .contractorChanged)) { _ in
            Task { await reloadTasks() }
        }
    }

    private var progressColor: Color { HavenColors.navy }
    private var vendorProgressColor: Color { HavenColors.navy }

    private func reloadTasks() async {
        guard let propertyId else { return }
        guard let allTasks = try? await DatabaseService.shared.fetchMaintenanceTasks(propertyId: propertyId) else { return }
        let seasonLower = season.lowercased()
        let nextSeasonLower = nextSeason.lowercased()
        liveTasks = allTasks.filter { $0.seasonalTiming?.lowercased().contains(seasonLower) == true }
        liveNextTasks = allTasks.filter { $0.seasonalTiming?.lowercased().contains(nextSeasonLower) == true }
    }

    // MARK: - Progress Header

    @ViewBuilder
    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isSeasonComplete {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.success)
                    Text("All \(assignedVendorTasks) vendors handled")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                        
                }
                ProgressView(value: 1.0)
                    .tint(HavenColors.success)
            } else {
                HStack {
                    if totalVendorTasks > 0 {
                        Text("\(assignedVendorTasks) of \(totalVendorTasks) vendors assigned")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else {
                        Text("\(completedCount) of \(effectiveTasks.count) done")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                }
                if totalVendorTasks > 0 {
                    ProgressView(value: Double(assignedVendorTasks), total: Double(max(totalVendorTasks, 1)))
                        .tint(vendorProgressColor)
                } else {
                    ProgressView(value: Double(completedCount), total: Double(max(effectiveTasks.count, 1)))
                        .tint(progressColor)
                }
            }
        }
        .padding()
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .havenShadow()
    }

    // MARK: - Empty Season Content

    @ViewBuilder
    private var emptySeasonContent: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            Image(systemName: Season(rawValue: season)?.icon ?? "calendar")
                .font(.system(size: 36))
                .foregroundStyle(HavenColors.textTertiary)

            Text("No tasks scheduled for \(season) yet")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
                
                .multilineTextAlignment(.center)

            Text("Seasonal tasks will appear here as your maintenance plan builds out through the quiz, invoices, and vendor assignments.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Active Season Content

    @ViewBuilder
    private var activeSeasonContent: some View {
        // Current season groups
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("CATEGORIES")
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

    // MARK: - Completed Season Content

    @ViewBuilder
    private var completedSeasonContent: some View {
        // Season Summary
        if !serviceRecords.isEmpty {
            seasonSummarySection
        }

        // Categories (all complete)
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("CATEGORIES")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                ForEach(groups) { group in
                    groupCard(group)
                }
            }
        }

        // Next Up CTA
        nextUpSection
    }

    // MARK: - Season Summary (Completed State)

    @ViewBuilder
    private var seasonSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SEASON SUMMARY")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            VStack(spacing: 0) {
                summaryRow(label: "Visits completed", value: "\(serviceRecords.count)")

                if let firstDate = serviceRecords.compactMap({ $0.serviceDate }).sorted().first,
                   let lastDate = serviceRecords.compactMap({ $0.serviceDate }).sorted().last {
                    Divider().overlay(HavenColors.beige200)
                    summaryRow(label: "First visit", value: formatShortDate(firstDate))
                    Divider().overlay(HavenColors.beige200)
                    summaryRow(label: "Last visit", value: formatShortDate(lastDate))
                }

                if let maxTier = maxCostTier {
                    Divider().overlay(HavenColors.beige200)
                    HStack {
                        Text("Estimated cost tier")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                        CostTierView(tier: maxTier)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                }
            }
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
                
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }

    private var maxCostTier: CostTier? {
        effectiveTasks.compactMap { CostTier.from(averageCost: $0.estimatedCost) }.max()
    }

    private func formatShortDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: dateString) else {
            // Try other common formats
            let fallback = DateFormatter()
            fallback.dateFormat = "yyyy-MM-dd"
            guard let d = fallback.date(from: String(dateString.prefix(10))) else { return dateString }
            let display = DateFormatter()
            display.dateFormat = "MMM d"
            return display.string(from: d)
        }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
    }

    // MARK: - Next Up Section

    @ViewBuilder
    private var nextUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEXT UP")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            NavigationLink {
                SeasonalTasksDetailView(
                    season: nextSeason,
                    tasks: effectiveNextTasks,
                    completedCount: 0,
                    nextSeason: Season(rawValue: nextSeason)?.next.displayName ?? "",
                    nextSeasonTasks: [],
                    systemNameLookup: systemNameLookup,
                    contractorNameLookup: contractorNameLookup,
                    contractorLookup: contractorLookup,
                    onFindVendor: onFindVendor,
                    propertyId: propertyId,
                    serviceRecords: []
                )
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(nextSeason) \(String(seasonYear))")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                            
                        if !nextGroups.isEmpty {
                            Text("\(nextGroups.flatMap(\.vendorTasks).count) vendors typically needed")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Plan \(nextSeason)")
                            .font(HavenTypography.uiLabel)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(HavenColors.action)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .padding(14)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Group Card

    private func groupCard(_ group: SeasonalTaskGroup) -> some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 12) {
                Image(systemName: groupStatusIcon(group))
                    .font(.system(size: 18))
                    .foregroundStyle(groupStatusColor(group))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)

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
                // Status icon: VendorLogoView for assigned vendors, SF Symbols for others
                if isVendor, hasVendor, let contractor = contractorLookup?(task.assignedContractorId) {
                    VendorLogoView(contractor: contractor, size: 24)
                } else if isVendor {
                    Image(systemName: "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(HavenColors.warning)
                } else {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(isCompleted ? HavenColors.success : HavenColors.textTertiary)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(task.title)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)

                    if isVendor, hasVendor, let name = contractorNameLookup?(task.assignedContractorId) {
                        Text(name)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
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

    // MARK: - Group Status Helpers

    /// 3-state icon for category row: complete, partial, or empty
    private func groupStatusIcon(_ group: SeasonalTaskGroup) -> String {
        if group.isFullyCovered {
            return "checkmark.circle.fill"
        } else if group.vendorAssignedCount > 0 || group.completedCount > 0 {
            return "circle.lefthalf.filled"
        } else {
            return "circle"
        }
    }

    /// Color matching the 3-state icon
    private func groupStatusColor(_ group: SeasonalTaskGroup) -> Color {
        if group.isFullyCovered {
            return HavenColors.success
        } else if group.vendorAssignedCount > 0 || group.completedCount > 0 {
            return HavenColors.navy500
        } else {
            return HavenColors.textTertiary
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

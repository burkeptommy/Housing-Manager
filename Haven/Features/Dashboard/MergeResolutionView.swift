import SwiftUI

struct MergeResolutionView: View {
    let preview: MergePreview
    let summary: MergeSummary
    let mergeRequestId: String
    let sourceHouseholdName: String
    let targetHouseholdName: String
    var onMergeComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var resolutions = MergeResolutions()
    @State private var isMerging = false
    @State private var error: String?
    @State private var mergeComplete = false

    // Per-category bulk vs individual mode
    @State private var reviewIndividually: Set<String> = []

    // Per-category bulk choices: "keep_source" or "keep_target"
    @State private var bulkChoices: [String: String] = [:]

    // Per-item individual choices: [sourceItemId: "keep_source" | "keep_target"]
    @State private var itemChoices: [String: String] = [:]

    private var hasConflicts: Bool { summary.totalDuplicates > 0 }

    private var allConflictsResolved: Bool {
        let categories = conflictCategories
        for cat in categories {
            let dups = duplicatesForCategory(cat)
            if reviewIndividually.contains(cat) {
                for dup in dups {
                    if itemChoices[dup.sourceId] == nil { return false }
                }
            } else {
                if bulkChoices[cat] == nil { return false }
            }
        }
        return true
    }

    private var conflictCategories: [String] {
        summary.categoriesWithConflicts
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if mergeComplete {
                        mergeCompleteView
                    } else {
                        headerSection
                        if hasConflicts {
                            conflictSections
                        }
                        summarySection
                        if let error {
                            Text(error)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.critical)
                                .padding(.horizontal)
                        }
                        mergeButton
                    }
                }
                .padding()
            }
            .background(HavenColors.cream)
            .trackScreen("MergeResolution")
            .navigationTitle("Combine Households")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isMerging)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.merge")
                .font(.system(size: 40))
                .foregroundStyle(HavenColors.navy)

            Text("Merging \"\(sourceHouseholdName)\" into \"\(targetHouseholdName)\"")
                .font(HavenTypography.headline)
                .multilineTextAlignment(.center)

            if hasConflicts {
                Text("We found \(summary.totalDuplicates) item\(summary.totalDuplicates == 1 ? "" : "s") that exist in both households. Choose which version to keep for each category.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No duplicates found. All items from both households will be combined.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Conflict Sections

    private var conflictSections: some View {
        VStack(spacing: 16) {
            ForEach(conflictCategories, id: \.self) { category in
                conflictSection(for: category)
            }
        }
    }

    private func conflictSection(for category: String) -> some View {
        let dups = duplicatesForCategory(category)
        let isIndividual = reviewIndividually.contains(category)

        return HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: iconForCategory(category))
                        .font(.system(size: 16))
                        .foregroundStyle(HavenColors.navy700)
                    Text("\(labelForCategory(category)) (\(dups.count) to resolve)")
                        .font(HavenTypography.headline)
                    Spacer()
                }

                // Bulk picker (default mode)
                if !isIndividual {
                    HStack(spacing: 0) {
                        bulkButton(category: category, choice: "keep_target", label: "\(targetHouseholdName)'s")
                        bulkButton(category: category, choice: "keep_source", label: "\(sourceHouseholdName)'s")
                    }
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    .overlay(RoundedRectangle(cornerRadius: HavenTheme.radiusButton).stroke(HavenColors.beige300, lineWidth: 1))
                }

                // Toggle to review individually
                Button {
                    Haptics.light()
                    withAnimation {
                        if isIndividual {
                            reviewIndividually.remove(category)
                        } else {
                            reviewIndividually.insert(category)
                            // Pre-populate individual choices from bulk if set
                            if let bulk = bulkChoices[category] {
                                for dup in dups {
                                    if itemChoices[dup.sourceId] == nil {
                                        itemChoices[dup.sourceId] = bulk
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isIndividual ? "checklist" : "list.bullet")
                            .font(.system(size: 12))
                        Text(isIndividual ? "Use bulk choice" : "Review individually")
                            .font(HavenTypography.caption)
                    }
                    .foregroundStyle(HavenColors.navy)
                }

                // Individual items (expanded mode)
                if isIndividual {
                    ForEach(dups, id: \.sourceId) { dup in
                        individualDuplicateRow(dup: dup, category: category)
                    }
                }
            }
        }
    }

    private func bulkButton(category: String, choice: String, label: String) -> some View {
        let isSelected = bulkChoices[category] == choice
        return Button {
            Haptics.light()
            bulkChoices[category] = choice
        } label: {
            Text("Keep \(label)")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(isSelected ? .white : HavenColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? HavenColors.navy : HavenColors.creamLight)
        }
    }

    private func individualDuplicateRow(dup: DuplicateDisplayItem, category: String) -> some View {
        VStack(spacing: 8) {
            Divider()

            // Source card
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sourceHouseholdName)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(dup.sourceTitle)
                        .font(HavenTypography.uiLabel)
                    if let detail = dup.sourceDetail {
                        Text(detail)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text(targetHouseholdName)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(dup.targetTitle)
                        .font(HavenTypography.uiLabel)
                    if let detail = dup.targetDetail {
                        Text(detail)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }

            // Per-item picker
            HStack(spacing: 0) {
                itemButton(sourceId: dup.sourceId, choice: "keep_target", label: "Keep \(targetHouseholdName)'s")
                itemButton(sourceId: dup.sourceId, choice: "keep_source", label: "Keep \(sourceHouseholdName)'s")
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(HavenColors.beige300, lineWidth: 1))
        }
    }

    private func itemButton(sourceId: String, choice: String, label: String) -> some View {
        let isSelected = itemChoices[sourceId] == choice
        return Button {
            Haptics.light()
            itemChoices[sourceId] = choice
        } label: {
            Text(label)
                .font(HavenTypography.caption)
                .foregroundStyle(isSelected ? .white : HavenColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? HavenColors.navy : HavenColors.creamLight)
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "tray.2.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(HavenColors.navy700)
                    Text("Items Being Combined")
                        .font(HavenTypography.headline)
                }

                let items = autoKeptItems
                if items.isEmpty {
                    Text("No additional items to bring over — everything matched.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                } else {
                    ForEach(items, id: \.label) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(HavenColors.success)
                            Text("\(item.count) \(item.label)")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Merge Button

    private var mergeButton: some View {
        VStack(spacing: 8) {
            HavenButton(title: isMerging ? "Merging..." : "Merge Households") {
                Task { await executeMerge() }
            }
            .disabled(isMerging || (hasConflicts && !allConflictsResolved))

            if hasConflicts && !allConflictsResolved {
                Text("Resolve all conflicts above to continue")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Merge Complete

    private var mergeCompleteView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.success)

            Text("Households Merged!")
                .font(HavenTypography.title2)

            Text("All data has been combined into one household. You're all set!")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)

            HavenButton(title: "Done") {
                onMergeComplete?()
                dismiss()
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Execute Merge

    private func executeMerge() async {
        Analytics.track(.householdMergeStarted, ["merge_request_id": mergeRequestId, "has_conflicts": hasConflicts])
        isMerging = true
        error = nil

        // Build resolutions from user choices
        var finalResolutions = MergeResolutions()

        for category in conflictCategories {
            let dups = duplicatesForCategory(category)
            var categoryResolutions: [String: String] = [:]

            if reviewIndividually.contains(category) {
                for dup in dups {
                    categoryResolutions[dup.sourceId] = itemChoices[dup.sourceId] ?? "keep_target"
                }
            } else {
                let bulk = bulkChoices[category] ?? "keep_target"
                for dup in dups {
                    categoryResolutions[dup.sourceId] = bulk
                }
            }

            switch category {
            case "properties": finalResolutions.properties = categoryResolutions
            case "home_systems": finalResolutions.homeSystems = categoryResolutions
            case "maintenance_tasks": finalResolutions.maintenanceTasks = categoryResolutions
            case "contractors": finalResolutions.contractors = categoryResolutions
            case "documents": finalResolutions.documents = categoryResolutions
            case "family_members": finalResolutions.familyMembers = categoryResolutions
            default: break
            }
        }

        do {
            let data = try await HavenSupabase.mergeHouseholds(
                action: "execute_merge",
                mergeRequestId: mergeRequestId,
                resolutions: finalResolutions
            )

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                Analytics.track(.householdMergeCompleted, ["merge_request_id": mergeRequestId])
                Haptics.success()
                withAnimation { mergeComplete = true }
            } else {
                let errorMsg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                error = errorMsg ?? "Merge failed"
                Haptics.error()
            }
        } catch {
            self.error = "Merge failed: \(error.localizedDescription)"
            Haptics.error()
        }

        isMerging = false
    }

    // MARK: - Helpers

    private struct DuplicateDisplayItem {
        let sourceId: String
        let sourceTitle: String
        let sourceDetail: String?
        let targetTitle: String
        let targetDetail: String?
    }

    private func duplicatesForCategory(_ category: String) -> [DuplicateDisplayItem] {
        switch category {
        case "properties":
            return preview.properties.duplicates.map {
                DuplicateDisplayItem(
                    sourceId: $0.source.id.uuidString,
                    sourceTitle: $0.source.name,
                    sourceDetail: [$0.source.street, $0.source.city, $0.source.state].compactMap { $0 }.joined(separator: ", "),
                    targetTitle: $0.target.name,
                    targetDetail: [$0.target.street, $0.target.city, $0.target.state].compactMap { $0 }.joined(separator: ", ")
                )
            }
        case "home_systems":
            return preview.homeSystems.duplicates.map {
                DuplicateDisplayItem(
                    sourceId: $0.source.id.uuidString,
                    sourceTitle: $0.source.name,
                    sourceDetail: [$0.source.category, $0.source.manufacturer].compactMap { $0 }.joined(separator: " · "),
                    targetTitle: $0.target.name,
                    targetDetail: [$0.target.category, $0.target.manufacturer].compactMap { $0 }.joined(separator: " · ")
                )
            }
        case "maintenance_tasks":
            return preview.maintenanceTasks.duplicates.map {
                DuplicateDisplayItem(
                    sourceId: $0.source.id.uuidString,
                    sourceTitle: $0.source.title,
                    sourceDetail: "\($0.source.frequency) · Due: \($0.source.nextDueDate)",
                    targetTitle: $0.target.title,
                    targetDetail: "\($0.target.frequency) · Due: \($0.target.nextDueDate)"
                )
            }
        case "contractors":
            return preview.contractors.duplicates.map {
                DuplicateDisplayItem(
                    sourceId: $0.source.id.uuidString,
                    sourceTitle: $0.source.companyName,
                    sourceDetail: $0.source.phone,
                    targetTitle: $0.target.companyName,
                    targetDetail: $0.target.phone
                )
            }
        case "documents":
            return preview.documents.duplicates.map {
                DuplicateDisplayItem(
                    sourceId: $0.source.id.uuidString,
                    sourceTitle: $0.source.title,
                    sourceDetail: $0.source.category,
                    targetTitle: $0.target.title,
                    targetDetail: $0.target.category
                )
            }
        case "family_members":
            return preview.familyMembers.duplicates.map {
                DuplicateDisplayItem(
                    sourceId: $0.source.id.uuidString,
                    sourceTitle: "\($0.source.firstName) \($0.source.lastName)",
                    sourceDetail: $0.source.relationship,
                    targetTitle: "\($0.target.firstName) \($0.target.lastName)",
                    targetDetail: $0.target.relationship
                )
            }
        default:
            return []
        }
    }

    private struct AutoKeptItem {
        let label: String
        let count: Int
    }

    private var autoKeptItems: [AutoKeptItem] {
        var items: [AutoKeptItem] = []
        if preview.properties.sourceOnly.count > 0 {
            items.append(AutoKeptItem(label: "properties", count: preview.properties.sourceOnly.count))
        }
        if preview.homeSystems.sourceOnly.count > 0 {
            items.append(AutoKeptItem(label: "home systems", count: preview.homeSystems.sourceOnly.count))
        }
        if preview.maintenanceTasks.sourceOnly.count > 0 {
            items.append(AutoKeptItem(label: "maintenance tasks", count: preview.maintenanceTasks.sourceOnly.count))
        }
        if preview.contractors.sourceOnly.count > 0 {
            items.append(AutoKeptItem(label: "contractors", count: preview.contractors.sourceOnly.count))
        }
        if preview.documents.sourceOnly.count > 0 {
            items.append(AutoKeptItem(label: "documents", count: preview.documents.sourceOnly.count))
        }
        if preview.familyMembers.sourceOnly.count > 0 {
            items.append(AutoKeptItem(label: "family members", count: preview.familyMembers.sourceOnly.count))
        }
        return items
    }

    private func labelForCategory(_ category: String) -> String {
        switch category {
        case "properties": return "Properties"
        case "home_systems": return "Home Systems"
        case "maintenance_tasks": return "Maintenance Tasks"
        case "contractors": return "Contractors"
        case "documents": return "Documents"
        case "family_members": return "Family Members"
        default: return category.capitalized
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "properties": return "house.fill"
        case "home_systems": return "gearshape.2.fill"
        case "maintenance_tasks": return "wrench.and.screwdriver.fill"
        case "contractors": return "person.crop.rectangle.stack.fill"
        case "documents": return "doc.fill"
        case "family_members": return "person.2.fill"
        default: return "questionmark.circle"
        }
    }
}

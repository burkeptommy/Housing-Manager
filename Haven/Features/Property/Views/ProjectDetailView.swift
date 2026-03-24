import SwiftUI

/// Full project detail — status, budget, line items, AI research, tips, videos.
struct ProjectDetailView: View {
    let project: PropertyProjectRow
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showEditLineItem: ProjectLineItemRow?
    @State private var showAddLineItem = false
    @State private var showQuoteAnalysis = false
    @State private var showDeleteConfirmation = false
    @State private var showStatusPicker = false
    @State private var showNotesEditor = false
    @State private var editedNotes = ""

    /// The live project from the viewModel (may have been updated).
    private var liveProject: PropertyProjectRow {
        viewModel.projects.first(where: { $0.id == project.id }) ?? project
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                statusCard
                budgetCard
                quoteUploadButton
                lineItemsSection
                if liveProject.aiResearch != nil {
                    tipsSection
                    learnSection
                    homeValueImpactSection
                }
                notesSection
                reResearchButton
            }
            .padding(HavenTheme.pageMargin)
        }
        .background(HavenColors.background)
        .navigationTitle(liveProject.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showStatusPicker = true
                    } label: {
                        Label("Change Status", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(HavenColors.navy)
                }
            }
        }
        .trackScreen("ProjectDetailView", properties: ["project_id": project.id.uuidString])
        .task {
            await viewModel.loadLineItems(projectId: project.id)
            await viewModel.loadToolkit(householdId: project.householdId)
        }
        .sheet(item: $showEditLineItem) { item in
            EditLineItemView(item: item, householdId: project.householdId, projectId: project.id, viewModel: viewModel)
        }
        .sheet(isPresented: $showAddLineItem) {
            EditLineItemView(item: nil, householdId: project.householdId, projectId: project.id, viewModel: viewModel)
        }
        .sheet(isPresented: $showQuoteAnalysis) {
            QuoteAnalysisView(project: liveProject, viewModel: viewModel)
        }
        .sheet(isPresented: $showNotesEditor) {
            notesEditorSheet
        }
        .confirmationDialog("Change Status", isPresented: $showStatusPicker) {
            ForEach(ProjectStatus.allCases, id: \.self) { status in
                Button(status.displayName) {
                    Task {
                        try? await viewModel.updateProject(id: project.id, PropertyProjectUpdate(status: status.rawValue))
                        Haptics.success()
                    }
                }
            }
        }
        .confirmationDialog("Delete Project?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.deleteProject(id: project.id)
                    Haptics.success()
                    dismiss()
                }
            }
        } message: {
            Text("This will delete the project and all line items.")
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        HavenCard {
            HStack {
                let cat = ProjectCategory(rawValue: liveProject.category)
                Image(systemName: cat?.icon ?? "hammer.fill")
                    .font(.title2)
                    .foregroundStyle(HavenColors.navy)

                VStack(alignment: .leading, spacing: 4) {
                    Text(liveProject.category)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)

                    HStack(spacing: HavenTheme.spacing8) {
                        statusBadge(liveProject.status)
                        approachBadge(liveProject.projectType)
                        if let p = liveProject.priority {
                            priorityBadge(p)
                        }
                    }

                    if let start = liveProject.targetStartDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text("Target: \(start)")
                                .font(HavenTypography.uiCaption)
                            if let end = liveProject.targetEndDate {
                                Text("– \(end)")
                                    .font(HavenTypography.uiCaption)
                            }
                        }
                        .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Budget Card

    /// Total estimated cost from line items (excludes owned items)
    private var lineItemsTotal: Double {
        viewModel.lineItems
            .filter { !($0.isOwned ?? false) }
            .reduce(0) { $0 + ($1.estimatedUnitPrice ?? $1.actualUnitPrice ?? 0) * ($1.quantity ?? 1) }
    }

    private var budgetCard: some View {
        HavenCard {
            Text("BUDGET & COST")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            // Show line items total when we have items
            if !viewModel.lineItems.isEmpty && lineItemsTotal > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Projected Cost")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("$\(Int(lineItemsTotal))")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                    Spacer()
                    Text("\(viewModel.lineItems.filter { !($0.isOwned ?? false) }.count) items")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            // Deal rating
            if let research = liveProject.aiResearch, let rating = research.dealRating {
                let (label, icon, color): (String, String, Color) = {
                    switch rating {
                    case "good_value": return ("Good Value Project", "hand.thumbsup.fill", HavenColors.success)
                    case "premium": return ("Premium Project", "star.fill", HavenColors.warning)
                    default: return ("Fair Value Project", "equal.circle.fill", HavenColors.info)
                    }
                }()
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)
                    Text(label)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(color)
                    if let reason = research.dealRatingReason {
                        Text("— \(reason)")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(2)
                    }
                }
            }

            // Always show median market cost when AI data is available
            if let research = liveProject.aiResearch {
                // Market cost estimates (always visible, primary info)
                HStack(spacing: HavenTheme.spacing16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Typical DIY Cost")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("$\(Int(research.estimatedDiyCost?.resolvedLow ?? 0))–$\(Int(research.estimatedDiyCost?.resolvedHigh ?? 0))")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.success)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Typical Pro Cost")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("$\(Int(research.estimatedProCost?.resolvedLow ?? 0))–$\(Int(research.estimatedProCost?.resolvedHigh ?? 0))")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                    Spacer()
                }

                // Suggested budget (when user has no budget set)
                if liveProject.estimatedBudget == nil || liveProject.estimatedBudget == 0 {
                    let isPro = liveProject.projectType == "professional"
                    let suggestedLow = isPro ? research.estimatedProCost?.resolvedLow : research.estimatedDiyCost?.resolvedLow
                    let suggestedHigh = isPro ? research.estimatedProCost?.resolvedHigh : research.estimatedDiyCost?.resolvedHigh
                    if let low = suggestedLow, let high = suggestedHigh, low > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(HavenColors.warning)
                            Text("Suggested budget: $\(Int(low))–$\(Int(high))")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        .padding(HavenTheme.spacing8)
                        .background(HavenColors.warning.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                    }
                }
            }

            // User budget + spending progress (when set)
            if let budget = liveProject.estimatedBudget, budget > 0 {
                let spent = liveProject.actualSpend ?? 0
                let pct = budget > 0 ? spent / budget : 0
                let barColor: Color = pct > 1.0 ? HavenColors.critical : pct > 0.8 ? HavenColors.warning : HavenColors.success

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Budget")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("$\(Int(spent)) of $\(Int(budget))")
                            .font(HavenTypography.headline)
                            .foregroundStyle(pct > 1.0 ? HavenColors.critical : HavenColors.textPrimary)
                    }
                    Spacer()
                    if pct > 1.0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("$\(Int(spent - budget)) over")
                        }
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.critical)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(HavenColors.beige200).frame(height: 8)
                        Capsule().fill(barColor)
                            .frame(width: geo.size.width * min(pct, 1.0), height: 8)
                            .animation(HavenTheme.animationProgress, value: pct)
                    }
                }
                .frame(height: 8)

                // Budget adequacy (compare to median market cost)
                if let research = liveProject.aiResearch {
                    let isPro = liveProject.projectType == "professional"
                    let medianLow = isPro ? (research.estimatedProCost?.resolvedLow ?? 0) : (research.estimatedDiyCost?.resolvedLow ?? 0)
                    let medianHigh = isPro ? (research.estimatedProCost?.resolvedHigh ?? 0) : (research.estimatedDiyCost?.resolvedHigh ?? 0)
                    let median = (medianLow + medianHigh) / 2
                    if median > 0 {
                        let ratio = budget / median
                        let (label, icon, color): (String, String, Color) = {
                            if ratio < 0.7 { return ("Budget is below typical cost — may need to adjust", "exclamationmark.triangle.fill", HavenColors.critical) }
                            if ratio < 0.9 { return ("Budget is a bit tight for this project", "exclamationmark.circle.fill", HavenColors.warning) }
                            if ratio > 1.5 { return ("Budget is generous — plenty of room", "checkmark.seal.fill", HavenColors.success) }
                            return ("Budget is realistic for this project", "checkmark.circle.fill", HavenColors.success)
                        }()
                        HStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.caption)
                                .foregroundStyle(color)
                            Text(label)
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(color)
                        }
                    }
                }
            }

            // No data at all
            if liveProject.aiResearch == nil && (liveProject.estimatedBudget == nil || liveProject.estimatedBudget == 0) {
                Text("Tap Re-Research to get AI cost estimates, or set a budget manually.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    // MARK: - Line Items

    // MARK: - Upload Quote

    private var quoteUploadButton: some View {
        Button {
            showQuoteAnalysis = true
            Analytics.track(.documentUploadStarted, ["type": "quote", "project_id": project.id.uuidString])
        } label: {
            HavenCard(padding: HavenTheme.spacing12) {
                HStack(spacing: HavenTheme.spacing8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title3)
                        .foregroundStyle(HavenColors.navy)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upload a Contractor Quote")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy800)
                        Text("Get a line-by-line deal analysis")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text("MATERIALS & SUPPLIES")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Button {
                    showAddLineItem = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Item")
                    }
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.navy)
                }
                .buttonStyle(.plain)
            }

            if viewModel.lineItems.isEmpty {
                HavenCard {
                    Text("No items yet. Add materials manually or use AI research to populate.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            } else {
                // Group by necessity first
                ForEach(NecessityGroup.allCases, id: \.self) { group in
                    let groupItems = viewModel.lineItems.filter { ($0.necessity ?? "required") == group.rawValue }
                    if !groupItems.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: group.icon)
                                    .font(.caption)
                                Text(group.displayName)
                                    .font(HavenTypography.uiSectionHeader)
                                    .tracking(1.5)
                            }
                            .foregroundStyle(group.color)
                            .padding(.top, 4)

                            // Sub-group by category within each necessity group
                            let catGrouped = Dictionary(grouping: groupItems, by: { $0.category ?? "other" })
                            ForEach(catGrouped.keys.sorted(), id: \.self) { key in
                                let cat = LineItemCategory(rawValue: key)
                                if catGrouped.keys.count > 1 {
                                    Text((cat?.displayName ?? key).uppercased())
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(HavenColors.textTertiary)
                                        .padding(.top, 2)
                                }
                                ForEach(catGrouped[key] ?? []) { item in
                                    lineItemRow(item)
                                }
                            }
                        }
                    }
                }

                // Multi-project tools callout
                let multiProjectItems = viewModel.lineItems.filter { $0.multiProjectUseful ?? false }
                if !multiProjectItems.isEmpty {
                    HavenCard {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(HavenColors.warning)
                            Text("USEFUL FOR FUTURE PROJECTS")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        ForEach(multiProjectItems) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "wrench.fill")
                                    .font(.caption)
                                    .foregroundStyle(HavenColors.navy)
                                Text(item.name.count > 40 ? String(item.name.prefix(37)) + "..." : item.name)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Spacer()
                                if let price = item.estimatedUnitPrice {
                                    Text("$\(price, specifier: "%.0f")")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                            }
                        }
                        Text("These tools will be saved to your toolkit when marked as owned, so Haven won't suggest buying them again.")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
        }
    }

    private func lineItemRow(_ item: ProjectLineItemRow) -> some View {
        let isOwned = item.isOwned ?? false
        return Button {
            showEditLineItem = item
        } label: {
            HavenCard(padding: HavenTheme.spacing12) {
                HStack(spacing: HavenTheme.spacing8) {
                    // Status toggle: owned → purchased → unchecked
                    Button {
                        Task {
                            if isOwned {
                                // Owned → uncheck
                                try? await viewModel.updateLineItem(id: item.id, ProjectLineItemUpdate(isOwned: false))
                            } else if item.isPurchased {
                                // Purchased → uncheck
                                try? await viewModel.updateLineItem(id: item.id, ProjectLineItemUpdate(isPurchased: false))
                            } else {
                                // Unchecked → purchased
                                try? await viewModel.updateLineItem(id: item.id, ProjectLineItemUpdate(isPurchased: true))
                            }
                            try? await viewModel.recalculateActualSpend(projectId: project.id)
                            // Save tools to toolkit when marked as owned
                            if !isOwned {
                                let isToolCategory = ["tools", "hardware", "safety"].contains(item.category?.lowercased() ?? "")
                                if isToolCategory {
                                    await viewModel.addToolToToolkit(name: item.name, householdId: project.householdId, projectId: project.id)
                                }
                            }
                            Haptics.light()
                        }
                    } label: {
                        Image(systemName: isOwned ? "house.circle.fill" : item.isPurchased ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isOwned ? HavenColors.info : item.isPurchased ? HavenColors.success : HavenColors.textTertiary)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            // Truncate long AI names — show first ~40 chars
                            Text(item.name.count > 45 ? String(item.name.prefix(42)) + "..." : item.name)
                                .font(HavenTypography.body)
                                .foregroundStyle(isOwned ? HavenColors.textTertiary : HavenColors.textPrimary)
                                .strikethrough(item.isPurchased || isOwned)
                                .lineLimit(1)
                            if isOwned {
                                Text("OWNED")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(HavenColors.info)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(HavenColors.info.opacity(0.1))
                                    .clipShape(Capsule())
                            } else if item.isAiSuggested {
                                Text("AI")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(HavenColors.navy)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(HavenColors.navy.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        HStack(spacing: 8) {
                            if let qty = item.quantity, let unit = item.unit {
                                Text("\(qty.formatted()) \(unit)")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            if let store = item.suggestedStore, !store.isEmpty {
                                Text(store)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if let actual = item.actualUnitPrice {
                            Text("$\(actual, specifier: "%.2f")")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        } else if let est = item.estimatedUnitPrice {
                            Text("~$\(est, specifier: "%.2f")")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !(item.isOwned ?? false) {
                Button {
                    Task {
                        try? await viewModel.updateLineItem(id: item.id, ProjectLineItemUpdate(isOwned: true))
                        try? await viewModel.recalculateActualSpend(projectId: project.id)
                        let isToolCategory = ["tools", "hardware", "safety"].contains(item.category?.lowercased() ?? "")
                        if isToolCategory {
                            await viewModel.addToolToToolkit(name: item.name, householdId: project.householdId, projectId: project.id)
                        }
                        Haptics.success()
                    }
                } label: {
                    Label("I Already Own This", systemImage: "house.circle.fill")
                }
            }
            Button(role: .destructive) {
                Task {
                    try? await viewModel.deleteLineItem(id: item.id)
                    try? await viewModel.recalculateActualSpend(projectId: project.id)
                    Haptics.light()
                }
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    // MARK: - Tips & Warnings

    @ViewBuilder
    private var tipsSection: some View {
        if let research = liveProject.aiResearch, !(research.tipsAndWarnings ?? []).isEmpty {
            HavenCard {
                Text("TIPS & WARNINGS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                ForEach(Array((research.tipsAndWarnings ?? []).enumerated()), id: \.offset) { _, tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: tip.lowercased().contains("warn") || tip.lowercased().contains("careful") || tip.lowercased().contains("danger")
                              ? "exclamationmark.triangle.fill"
                              : "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(HavenColors.warning)
                            .frame(width: 16)
                        Text(tip)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                if let permit = research.permitNotes, !permit.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.caption)
                            .foregroundStyle(HavenColors.info)
                            .frame(width: 16)
                        Text(permit)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Learn How (YouTube)

    @ViewBuilder
    private var learnSection: some View {
        if let research = liveProject.aiResearch, !(research.suggestedVideoTopics ?? []).isEmpty {
            HavenCard {
                Text("LEARN HOW")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                ForEach(research.suggestedVideoTopics ?? [], id: \.self) { topic in
                    Button {
                        let query = topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic
                        if let url = URL(string: "https://www.youtube.com/results?search_query=\(query)") {
                            UIApplication.shared.open(url)
                            Analytics.track(.screenViewed, ["screen": "YouTube", "query": topic])
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(HavenColors.critical)
                            Text(topic)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.navy)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Home Value Impact

    @ViewBuilder
    private var homeValueImpactSection: some View {
        if let research = liveProject.aiResearch, let impact = research.homeValueImpact, let score = impact.score {
            HavenCard {
                Text("HOME VALUE IMPACT")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                // Score bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(impact.label ?? "Unknown")
                            .font(HavenTypography.headline)
                            .foregroundStyle(scoreColor(score))
                        Spacer()
                        Text("\(score)/100")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                        if let roi = impact.typicalRoi {
                            Text("(\(roi) ROI)")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Track with gradient markers
                            Capsule()
                                .fill(HavenColors.beige200)
                                .frame(height: 10)
                            // Fill
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [HavenColors.critical.opacity(0.6), HavenColors.warning, HavenColors.success],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * (Double(score) / 100.0), height: 10)
                                .animation(HavenTheme.animationProgress, value: score)
                        }
                    }
                    .frame(height: 10)

                    // Scale labels
                    HStack {
                        Text("Lifestyle")
                            .font(.system(size: 9))
                            .foregroundStyle(HavenColors.textTertiary)
                        Spacer()
                        Text("High ROI")
                            .font(.system(size: 9))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                if let explanation = impact.explanation {
                    Text(explanation)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 70 { return HavenColors.success }
        if score >= 40 { return HavenColors.warning }
        return HavenColors.textTertiary
    }

    // MARK: - Notes

    private var notesSection: some View {
        HavenCard {
            HStack {
                Text("NOTES")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Button {
                    editedNotes = liveProject.notes ?? ""
                    showNotesEditor = true
                } label: {
                    Text("Edit")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.navy)
                }
                .buttonStyle(.plain)
            }

            if let notes = liveProject.notes, !notes.isEmpty {
                Text(notes)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            } else {
                Text("No notes yet.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    private var notesEditorSheet: some View {
        NavigationStack {
            TextEditor(text: $editedNotes)
                .font(HavenTypography.body)
                .padding()
                .navigationTitle("Edit Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showNotesEditor = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                try? await viewModel.updateProject(id: project.id, PropertyProjectUpdate(notes: editedNotes))
                                Haptics.success()
                                showNotesEditor = false
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
                .tint(HavenColors.navy)
        }
    }

    // MARK: - Re-Research

    @ObservedObject private var researchService = ProjectResearchService.shared

    private var reResearchButton: some View {
        VStack(spacing: 4) {
            HavenButton(
                title: researchService.isResearching ? "Researching..." : "Re-Research Costs",
                action: {
                    researchService.research(project: liveProject, location: nil)
                    Haptics.medium()
                },
                style: .secondary,
                icon: "sparkle.magnifyingglass",
                isLoading: researchService.isResearching
            )

            if let date = liveProject.aiResearchUpdatedAt {
                Text("Last researched: \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    // MARK: - Badges

    private func statusBadge(_ status: String) -> some View {
        let ps = ProjectStatus(rawValue: status) ?? .planning
        return HStack(spacing: 4) {
            Image(systemName: ps.icon)
                .font(.caption2)
            Text(ps.displayName)
        }
        .font(HavenTypography.uiLabelSmall)
        .foregroundStyle(ps.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(ps.color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func approachBadge(_ type: String) -> some View {
        let a = ProjectApproach(rawValue: type) ?? .undecided
        return Text(a.displayName)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(HavenColors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(HavenColors.beige200)
            .clipShape(Capsule())
    }

    private func priorityBadge(_ priority: String) -> some View {
        let color: Color = priority == "high" ? HavenColors.critical : priority == "low" ? HavenColors.textTertiary : HavenColors.warning
        return Text(priority.capitalized)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

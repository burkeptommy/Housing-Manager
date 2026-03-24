import SwiftUI

struct ReadinessDetailView: View {
    @EnvironmentObject var viewModel: DocumentVaultViewModel
    @State private var showUpload = false

    private var level: DocumentVaultViewModel.ReadinessLevel { viewModel.currentLevel }
    private var levelColor: Color { level.color.color }

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing16) {
                // Level hero
                levelHeroCard

                // Next level roadmap
                if viewModel.nextLevel != nil {
                    nextLevelCard
                }

                // Highest impact actions
                if !viewModel.highestImpactMissing.isEmpty {
                    biggestImpactCard
                }

                // All levels journey
                levelsJourneyCard

                // Category breakdown
                categoryBreakdownSection

                // Dismiss categories
                dismissCategoriesSection
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, HavenTheme.spacing16)
        }
        .background(HavenColors.background)
        .trackScreen("ReadinessDetail")
        .navigationTitle("Your Progress")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showUpload) {
            DocumentUploadView(onComplete: {
                Task { await viewModel.loadData() }
            })
        }
    }

    // MARK: - Level Hero

    private var levelHeroCard: some View {
        VStack(spacing: 16) {
            // Badge
            ZStack {
                Circle()
                    .fill(levelColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: level.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(levelColor)
            }

            Text(level.name)
                .font(Font.custom("Georgia-Bold", size: 22))
                .foregroundStyle(HavenColors.textPrimary)

            Text(level.description)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)

            // Level progress
            if let next = viewModel.nextLevel {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(HavenColors.beige200)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(levelColor)
                                .frame(width: geo.size.width * viewModel.levelProgress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(viewModel.levelProgress * 100))% to \(next.name)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(levelColor)
                }
            } else {
                Text("You've reached the highest level!")
                    .font(HavenTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AvatarColor.sage.color)
            }
        }
        .padding(HavenTheme.spacing20)
        .frame(maxWidth: .infinity)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .havenShadow()
    }

    // MARK: - Next Level Card

    private var nextLevelCard: some View {
        guard let next = viewModel.nextLevel else { return AnyView(EmptyView()) }
        let nextColor = next.color.color

        return AnyView(
            HavenCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: next.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(nextColor)
                        Text("Next: \(next.name)")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                    }

                    Text("Upload these high-impact documents to level up fastest:")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)

                    ForEach(viewModel.highestImpactMissing.prefix(3), id: \.category) { item in
                        Button { showUpload = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(nextColor)
                                Text(item.category)
                                    .font(HavenTypography.subheadline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Spacer()
                                impactBadge(weight: item.weight)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        )
    }

    // MARK: - Biggest Impact

    private var biggestImpactCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(AvatarColor.coral.color)
                    Text("BIGGEST IMPACT")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                ForEach(viewModel.highestImpactMissing, id: \.category) { item in
                    Button { showUpload = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 14))
                                .foregroundStyle(HavenColors.navy700)
                            Text(item.category)
                                .font(HavenTypography.subheadline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                            impactBadge(weight: item.weight)
                        }
                        .padding(.vertical, 3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func impactBadge(weight: Double) -> some View {
        let label = weight >= 8 ? "Critical" : weight >= 5 ? "High" : "Medium"
        let color = weight >= 8 ? AvatarColor.coral.color : weight >= 5 ? AvatarColor.amber.color : HavenColors.textTertiary

        return Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Levels Journey

    private var levelsJourneyCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("YOUR JOURNEY")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                ForEach(DocumentVaultViewModel.levels) { lvl in
                    let isReached = viewModel.completionPercentage >= lvl.threshold
                    let isCurrent = lvl.id == level.id

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(isReached ? lvl.color.color.opacity(0.15) : HavenColors.beige200)
                                .frame(width: 36, height: 36)
                            Image(systemName: lvl.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(isReached ? lvl.color.color : HavenColors.textTertiary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(lvl.name)
                                    .font(HavenTypography.subheadline)
                                    .fontWeight(isCurrent ? .bold : .medium)
                                    .foregroundStyle(isReached ? HavenColors.textPrimary : HavenColors.textTertiary)
                                if isCurrent {
                                    Text("Current")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(lvl.color.color)
                                        .clipShape(Capsule())
                                }
                            }
                            Text(Int(lvl.threshold * 100) == 0 ? "Starting point" : "Reach \(Int(lvl.threshold * 100))% readiness")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }

                        Spacer()

                        if isReached {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(lvl.color.color)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("CATEGORY BREAKDOWN")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                ForEach(viewModel.categoryScores) { score in
                    if score.expected > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(score.category)
                                    .font(HavenTypography.subheadline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Spacer()
                                Text("\(score.actual)/\(score.expected)")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            ProgressView(value: min(score.percentage, 100), total: 100)
                                .tint(score.percentage >= 100 ? HavenColors.success : score.percentage > 0 ? AvatarColor.amber.color : HavenColors.beige300)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: - Dismiss Categories

    private var dismissCategoriesSection: some View {
        let existingCategories = Set(viewModel.documents.map(\.category))
        let dismissable = DocumentCategory.allCases.filter {
            !existingCategories.contains($0.rawValue) && !viewModel.dismissedCategories.contains($0.rawValue)
        }

        return Group {
            if !dismissable.isEmpty || !viewModel.dismissedCategories.isEmpty {
                HavenCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "eye.slash")
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("NOT APPLICABLE")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                        }

                        Text("Mark categories you'll never need. They won't count against your score.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)

                        // Already dismissed — tap to restore
                        ForEach(Array(viewModel.dismissedCategories).sorted(), id: \.self) { cat in
                            Button {
                                Task { await viewModel.undismissCategory(cat) }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text(cat)
                                        .font(HavenTypography.subheadline)
                                        .foregroundStyle(HavenColors.textTertiary)
                                        .strikethrough()
                                    Spacer()
                                    Text("Restore")
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.navy)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // Top dismissable categories (by lowest weight)
                        let topDismissable = dismissable
                            .sorted { (DocumentVaultViewModel.categoryWeights[$0.rawValue] ?? 1) < (DocumentVaultViewModel.categoryWeights[$1.rawValue] ?? 1) }
                            .prefix(8)

                        if !topDismissable.isEmpty {
                            Divider()
                            Text("Tap to hide from your score:")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)

                            DismissChipFlowLayout(spacing: 8) {
                                ForEach(Array(topDismissable), id: \.rawValue) { cat in
                                    Button {
                                        Haptics.light()
                                        Task { await viewModel.dismissCategory(cat.rawValue) }
                                    } label: {
                                        Text(cat.rawValue)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(HavenColors.textSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(HavenColors.beige200)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// Simple flow layout for dismiss chips
private struct DismissChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(bounds.size), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
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

// Keep the old view name as a redirect for backwards compatibility
struct EstateReadinessDetailView: View {
    let overallReadiness: Double
    let categoryScores: [CategoryScore]

    var body: some View {
        Text("Redirecting...")
            .onAppear {
                // This view is no longer used directly — ReadinessDetailView replaces it
            }
    }
}

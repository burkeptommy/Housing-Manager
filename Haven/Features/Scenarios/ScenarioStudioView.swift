import SwiftUI

struct ScenarioStudioView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ScenarioStudioViewModel()
    @ObservedObject private var runner = ScenarioRunnerService.shared
    @State private var selectedCategory: ScenarioCategory?
    @State private var selectedScenario: ScenarioDefinition?
    @State private var showInput = false
    @State private var showResult = false
    @State private var showSubmittedBanner = false
    @State private var customQuery = ""
    @State private var activeTab: ScenarioTab = .explore
    @AppStorage("hasAcknowledgedScenarioDisclaimer") private var hasAcknowledgedDisclaimer = false
    @State private var showDisclaimer = false

    enum ScenarioTab: String, CaseIterable {
        case explore = "Explore"
        case history = "History"
    }

    var initialQuery: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker (only show when not in a category drill-down)
                if selectedCategory == nil {
                    Picker("", selection: $activeTab) {
                        ForEach(ScenarioTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                        // Show banner when a scenario is running in background
                        if runner.isRunning {
                            runningBanner
                                .padding(.horizontal, HavenTheme.pageMargin)
                        }

                        if activeTab == .history && selectedCategory == nil {
                            historyTabView
                        } else if let category = selectedCategory {
                            scenarioListView(category: category)
                        } else {
                            // Custom input area — the star
                            customInputArea
                                .padding(.horizontal, HavenTheme.pageMargin)

                            // Popular Scenarios header
                            Text("POPULAR SCENARIOS")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                                .padding(.horizontal, HavenTheme.pageMargin)
                                .padding(.top, HavenTheme.spacing8)

                            // Category cards
                            categoryGridView

                            // Recently Explored
                            if !viewModel.recentScenarios.isEmpty {
                                recentlyExploredSection
                            }
                        }
                    }
                    .padding(.top, HavenTheme.spacing8)
                    .padding(.bottom, HavenTheme.spacing32)
                }
            }
            .background(HavenColors.background)
            .navigationTitle(selectedCategory?.rawValue ?? "Scenario Planning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(selectedCategory?.rawValue ?? "Scenario Planning")
                        .font(HavenTypography.fraunces(size: 18, weight: 700))
                        .foregroundStyle(HavenColors.navy800)
                }
                ToolbarItem(placement: .topBarLeading) {
                    if selectedCategory != nil {
                        Button {
                            Haptics.light()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Categories")
                                    .font(HavenTypography.uiLabel)
                            }
                            .foregroundStyle(HavenColors.navy800)
                        }
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy800)
                    }
                }
            }
            .navigationDestination(isPresented: $showInput) {
                if let scenario = selectedScenario {
                    ScenarioInputView(
                        scenario: scenario,
                        onSubmit: { params in
                            showInput = false
                            viewModel.runScenario(id: scenario.id, params: params)
                            showSubmittedBanner(andDismiss: true)
                        }
                    )
                }
            }
            .navigationDestination(isPresented: $showResult) {
                if let result = runner.completedResult {
                    ScenarioResultView(
                        result: result,
                        scenario: selectedScenario,
                        onRunRelated: { query in
                            showResult = false
                            customQuery = query
                            runner.clearResult()
                            viewModel.runCustomScenario(query: query)
                            showSubmittedBanner(andDismiss: false)
                        },
                        onDone: {
                            runner.clearResult()
                            dismiss()
                        }
                    )
                }
            }
            .trackScreen("ScenarioStudioView")
            .sheet(isPresented: $showDisclaimer) {
                ScenarioDisclaimerView {
                    hasAcknowledgedDisclaimer = true
                    showDisclaimer = false
                }
            }
            .task {
                Analytics.track(.scenarioStudioOpened)
                await viewModel.loadHousehold()
                await viewModel.loadRecentScenarios()
                if !hasAcknowledgedDisclaimer {
                    showDisclaimer = true
                }
                // Handle initial query from contextual trigger
                if let query = initialQuery, !query.isEmpty {
                    customQuery = query
                    viewModel.runCustomScenario(query: query)
                    showSubmittedBanner(andDismiss: false)
                }
            }
            .onReceive(runner.$completedResult) { newResult in
                // When a result arrives while the studio is open, show it
                if newResult != nil && !showResult {
                    showResult = true
                }
            }
            .overlay {
                if showSubmittedBanner {
                    submittedToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Running Banner

    private var runningBanner: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(HavenColors.navy700)

            VStack(alignment: .leading, spacing: 2) {
                Text("Analyzing your scenario...")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.navy800)
                Text(runner.pendingQuery ?? runner.pendingScenarioId ?? "")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("We'll notify you")
                .font(.system(size: 11))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(14)
        .background(HavenColors.navy.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Submitted Toast

    private var submittedToast: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(HavenColors.navy700)
                Text("Scenario submitted — we'll notify you when it's ready")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.navy800)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(HavenColors.cream)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            .padding(.top, 8)
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - Custom Input Area

    private var customInputArea: some View {
        VStack(spacing: 12) {
            Text("Explore any scenario about your finances, estate, home, or family")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(alignment: .bottom, spacing: 10) {
                TextField("What if I...", text: $customQuery, axis: .vertical)
                    .font(HavenTypography.bodySmall)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(HavenColors.beige300, lineWidth: 1)
                    )

                Button {
                    submitCustomQuery()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            customQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || runner.isRunning
                                ? HavenColors.textTertiary
                                : HavenColors.navy800
                        )
                }
                .disabled(customQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || runner.isRunning)
            }

            // Inspiration chips — tap to run immediately
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.inspirationChips, id: \.self) { chip in
                        Button {
                            Haptics.medium()
                            Analytics.track(.scenarioSubmitted, ["type": "inspiration_chip", "query": String(chip.prefix(100))])
                            customQuery = chip
                            selectedScenario = nil
                            viewModel.runCustomScenario(query: chip)
                            showSubmittedBanner(andDismiss: true)
                        } label: {
                            Text(chip)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(HavenColors.navy700)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(HavenColors.navy.opacity(0.06))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(runner.isRunning)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(HavenColors.cream)
                .shadow(color: HavenColors.navy800.opacity(0.06), radius: 8, y: 2)
        )
    }

    // MARK: - Category Grid

    private var categoryGridView: some View {
        LazyVStack(spacing: HavenTheme.spacing12) {
            ForEach(ScenarioCategory.allCases) { category in
                Button {
                    Haptics.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                } label: {
                    categoryCard(category)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
    }

    private func categoryCard(_ category: ScenarioCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.emoji)
                    .font(.title)
                Text(category.rawValue)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.navy800)
                Spacer()
                Text("\(category.scenarios.count)")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textTertiary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            Text(category.teaser)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(HavenColors.beige300, lineWidth: 0.5)
        )
    }

    // MARK: - Scenario List

    private func scenarioListView(category: ScenarioCategory) -> some View {
        LazyVStack(spacing: HavenTheme.spacing12) {
            ForEach(category.scenarios) { scenario in
                Button {
                    Haptics.light()
                    Analytics.track(.scenarioPresetSelected, ["scenario_id": scenario.id])
                    selectedScenario = scenario
                    if scenario.requiresParams {
                        showInput = true
                    } else {
                        Analytics.track(.scenarioSubmitted, ["type": "preset", "scenario_id": scenario.id])
                        viewModel.runScenario(id: scenario.id)
                        showSubmittedBanner(andDismiss: true)
                    }
                } label: {
                    scenarioRow(scenario)
                }
                .buttonStyle(.plain)
                .disabled(runner.isRunning)
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
    }

    private func scenarioRow(_ scenario: ScenarioDefinition) -> some View {
        HStack(spacing: 14) {
            Image(systemName: scenario.icon)
                .font(.system(size: 20))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 44, height: 44)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.title)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.navy800)
                    .multilineTextAlignment(.leading)
                Text(scenario.teaser)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(14)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(HavenColors.beige300, lineWidth: 0.5)
        )
    }

    // MARK: - Recently Explored

    private var recentlyExploredSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENTLY EXPLORED")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.horizontal, HavenTheme.pageMargin)

            LazyVStack(spacing: 8) {
                ForEach(viewModel.recentScenarios) { recent in
                    Button {
                        Haptics.light()
                        selectedScenario = nil
                        runner.completedResult = recent.cachedResult
                        runner.hasUnviewedResult = false
                        showResult = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(recent.title)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Text(recent.timestamp.formatted(.relative(presentation: .named)))
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(12)
                        .background(HavenColors.creamLight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
        }
        .padding(.top, HavenTheme.spacing8)
    }

    // MARK: - History Tab

    private var historyTabView: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            if viewModel.allScenarios.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                        .frame(height: 60)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundStyle(HavenColors.textTertiary)

                    Text("No scenarios yet")
                        .font(HavenTypography.fraunces(size: 18, weight: 700))
                        .foregroundStyle(HavenColors.navy800)

                    Text("Run your first scenario from the Explore tab to see your history here.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button {
                        activeTab = .explore
                    } label: {
                        Text("Explore Scenarios")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(HavenColors.navy.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                ForEach(viewModel.allScenarios) { scenario in
                    Button {
                        Haptics.light()
                        selectedScenario = nil
                        runner.completedResult = scenario.cachedResult
                        runner.hasUnviewedResult = false
                        showResult = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: severityIcon(scenario.cachedResult.severity))
                                .font(.system(size: 16))
                                .foregroundStyle(severityColor(scenario.cachedResult.severity))
                                .frame(width: 36, height: 36)
                                .background(severityColor(scenario.cachedResult.severity).opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(scenario.title)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                HStack(spacing: 6) {
                                    Text(scenario.timestamp.formatted(.relative(presentation: .named)))
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)

                                    if let score = scenario.cachedResult.documentsUsed?.count,
                                       let total = scenario.cachedResult.documentsMissing?.count {
                                        Text("\(score)/\(score + total) docs")
                                            .font(.system(size: 10))
                                            .foregroundStyle(HavenColors.textTertiary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1)
                                            .background(HavenColors.navy.opacity(0.06))
                                            .clipShape(Capsule())
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(14)
                        .background(HavenColors.creamLight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(HavenColors.beige300, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
    }

    private func severityIcon(_ severity: String) -> String {
        switch severity {
        case "critical": return "exclamationmark.triangle.fill"
        case "important": return "exclamationmark.circle.fill"
        case "opportunity": return "arrow.up.right.circle.fill"
        default: return "info.circle.fill"
        }
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return Color.red
        case "important": return HavenColors.warning
        case "opportunity": return HavenColors.success
        default: return HavenColors.navy700
        }
    }

    // MARK: - Helpers

    private func submitCustomQuery() {
        Haptics.medium()
        Analytics.track(.scenarioSubmitted, ["type": "custom", "query": String(customQuery.prefix(100))])
        selectedScenario = nil
        viewModel.runCustomScenario(query: customQuery)
        showSubmittedBanner(andDismiss: true)
    }

    private func showSubmittedBanner(andDismiss: Bool) {
        withAnimation(.spring(duration: 0.3)) {
            showSubmittedBanner = true
        }

        // Auto-hide banner and optionally dismiss
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                showSubmittedBanner = false
            }
            if andDismiss {
                try? await Task.sleep(for: .milliseconds(300))
                dismiss()
            }
        }
    }
}

#Preview {
    ScenarioStudioView()
}

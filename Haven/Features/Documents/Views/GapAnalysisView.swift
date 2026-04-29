import SwiftUI

struct GapAnalysisView: View {
    @State private var isAnalyzing = false
    @State private var analysisResult: GapAnalysisResult?
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if isAnalyzing {
                analyzingView
            } else if let result = analysisResult {
                resultView(result)
            } else {
                promptView
            }
        }
        .navigationTitle("Gap Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("GapAnalysisView")
        .screenshotProtected()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var promptView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()

            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.textPrimary)
                .accessibilityHidden(true)

            VStack(spacing: HavenTheme.spacing8) {
                Text("AI Gap Analysis")
                    .font(HavenTypography.title2)
                    .fontWeight(.bold)
                Text("Alfred will analyze your document vault to identify:")
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                gapFeatureRow(icon: "person.2", text: "Beneficiary mismatches across documents")
                gapFeatureRow(icon: "clock", text: "Expired or expiring documents")
                gapFeatureRow(icon: "doc.badge.ellipsis", text: "Missing critical documents")
                gapFeatureRow(icon: "building.columns", text: "Trust funding gaps")
                gapFeatureRow(icon: "shield", text: "Insurance coverage gaps")
            }
            .padding(.horizontal, HavenTheme.spacing24)

            HavenButton(title: "Run Analysis", action: {
                Task { await runAnalysis() }
            }, icon: "sparkles")
            .padding(.horizontal, HavenTheme.spacing24)

            if let error {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(Color.havenCritical)
            }

            Spacer()
        }
    }

    private func gapFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: icon)
                .foregroundStyle(HavenColors.textPrimary)
                .frame(width: 24)
            Text(text)
                .font(HavenTypography.subheadline)
        }
    }

    private var analyzingView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing your document vault...")
                .font(HavenTypography.headline)
            Text("Alfred is reviewing your entire portfolio against best practices for estate readiness.")
                .font(HavenTypography.subheadline)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HavenTheme.spacing32)
            Spacer()
        }
    }

    private func resultView(_ result: GapAnalysisResult) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                // Readiness Score Hero
                readinessScoreCard(result)

                // Summary
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Analysis Complete")
                                .font(HavenTypography.headline)
                        }
                        Text(result.summary)
                            .font(HavenTypography.subheadline)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                // Critical gaps
                if !result.criticalGaps.isEmpty {
                    gapSection(
                        title: "Critical Gaps",
                        icon: "exclamationmark.circle.fill",
                        color: Color.havenCritical,
                        items: result.criticalGaps
                    )
                }

                // Warnings
                if !result.warnings.isEmpty {
                    gapSection(
                        title: "Warnings",
                        icon: "exclamationmark.triangle.fill",
                        color: Color.havenWarning,
                        items: result.warnings
                    )
                }

                // Recommendations
                if !result.recommendations.isEmpty {
                    gapSection(
                        title: "Recommendations",
                        icon: "lightbulb.fill",
                        color: Color.havenInfo,
                        items: result.recommendations
                    )
                }

                // Re-run button
                Button {
                    Haptics.light()
                    analysisResult = nil
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Run Again")
                    }
                    .font(HavenTypography.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HavenTheme.spacing12)
                    .background(HavenColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                }
            }
            .padding()
        }
        .background(HavenColors.background)
    }

    private func readinessScoreCard(_ result: GapAnalysisResult) -> some View {
        HavenCard {
            VStack(spacing: HavenTheme.spacing12) {
                Text("Estate Readiness")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fontWeight(.semibold)

                ZStack {
                    Circle()
                        .stroke(HavenColors.beige200, lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: Double(result.overallReadinessScore) / 100.0)
                        .stroke(
                            scoreColor(result.overallReadinessScore),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(result.overallReadinessScore)")
                            .font(HavenTypography.heroNumber)
                            .fontWeight(.bold)
                        Text("/ 100")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                .frame(width: 120, height: 120)

                Text(scoreLabel(result.overallReadinessScore))
                    .font(HavenTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(scoreColor(result.overallReadinessScore))
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Estate readiness score: \(result.overallReadinessScore) out of 100")
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return Color.havenSuccess }
        if score >= 60 { return Color.havenWarning }
        return Color.havenCritical
    }

    private func scoreLabel(_ score: Int) -> String {
        if score >= 80 { return "Well Organized" }
        if score >= 60 { return "Needs Attention" }
        if score >= 40 { return "Significant Gaps" }
        return "Getting Started"
    }

    private func gapSection(title: String, icon: String, color: Color, items: [GapItem]) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    Text(title)
                        .font(HavenTypography.headline)
                    Spacer()
                    Text("\(items.count)")
                        .font(HavenTypography.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, HavenTheme.spacing8)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.12))
                        .foregroundStyle(color)
                        .clipShape(Capsule())
                }

                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
                        Text(item.title)
                            .font(HavenTypography.subheadline)
                            .fontWeight(.medium)
                        Text(item.description)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(.vertical, HavenTheme.spacing4)
                }
            }
        }
    }

    // MARK: - Analysis

    private func runAnalysis() async {
        Haptics.medium()
        Analytics.track(.gapAnalysisRequested, ["source": "gap_analysis_view"])
        isAnalyzing = true
        error = nil
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                error = "No household found"
                isAnalyzing = false
                return
            }

            let data = try await HavenSupabase.gapAnalysis(householdId: householdId.uuidString)
            let result = try JSONDecoder().decode(GapAnalysisResult.self, from: data)
            analysisResult = result
            Analytics.track(.gapAnalysisCompleted, [
                "readiness_score": result.overallReadinessScore,
                "critical_gaps": result.criticalGaps.count,
                "warnings": result.warnings.count,
                "recommendations": result.recommendations.count
            ])
            Haptics.success()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isAnalyzing = false
    }
}

// MARK: - Models

struct GapAnalysisResult: Codable {
    let summary: String
    let overallReadinessScore: Int
    let criticalGaps: [GapItem]
    let warnings: [GapItem]
    let recommendations: [GapItem]

    enum CodingKeys: String, CodingKey {
        case summary
        case overallReadinessScore = "overall_readiness_score"
        case criticalGaps = "critical_gaps"
        case warnings
        case recommendations
    }
}

struct GapItem: Codable, Identifiable {
    var id: String { title + description }
    let title: String
    let description: String
}

#Preview {
    NavigationStack {
        GapAnalysisView()
    }
}

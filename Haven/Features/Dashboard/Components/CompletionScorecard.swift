import SwiftUI

struct CompletionScorecard: View {
    let overallReadiness: Double
    let categoryScores: [CategoryScore]

    @State private var animatedReadiness: Double = 0
    @State private var hasAppeared = false

    var body: some View {
        HavenCard {
            VStack(spacing: HavenTheme.spacing16) {
                // Hero ring chart
                HStack(spacing: HavenTheme.spacing24) {
                    // Animated ring
                    ZStack {
                        // Track
                        Circle()
                            .stroke(Color.havenAccent.opacity(0.12), lineWidth: 10)

                        // Fill
                        Circle()
                            .trim(from: 0, to: animatedReadiness / 100)
                            .stroke(
                                readinessColor,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        // Center percentage
                        VStack(spacing: 0) {
                            Text("\(Int(animatedReadiness))%")
                                .font(HavenTypography.statNumber)
                                .foregroundStyle(readinessColor)
                                .contentTransition(.numericText(value: animatedReadiness))
                        }
                    }
                    .frame(width: 100, height: 100)
                    .accessibilityElement()
                    .accessibilityLabel("Estate readiness \(Int(overallReadiness)) percent")
                    .accessibilityValue(readinessLabel)

                    // Summary text
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        Text("Estate Readiness")
                            .font(HavenTypography.subheadline)
                            .foregroundStyle(.secondary)

                        Text(readinessLabel)
                            .font(HavenTypography.headline)
                            .foregroundStyle(readinessColor)

                        if categoryScores.isEmpty {
                            Text("Upload documents to track your progress")
                                .font(HavenTypography.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            let filled = categoryScores.filter { $0.percentage >= 100 }.count
                            Text("\(filled) of \(categoryScores.count) categories complete")
                                .font(HavenTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Category breakdown
                if !categoryScores.isEmpty {
                    Divider()
                        .padding(.horizontal, -HavenTheme.spacing16)

                    VStack(spacing: HavenTheme.spacing8) {
                        ForEach(categoryScores) { score in
                            categoryRow(score)
                        }
                    }
                }
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedReadiness = overallReadiness
            }
        }
        .onChange(of: overallReadiness) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedReadiness = newValue
            }
        }
    }

    private func categoryRow(_ score: CategoryScore) -> some View {
        HStack(spacing: HavenTheme.spacing8) {
            // Status icon
            Image(systemName: score.percentage >= 100 ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(score.percentage >= 100 ? Color.havenSuccess : .secondary)
                .frame(width: 16)

            Text(score.category)
                .font(HavenTypography.caption)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(progressColor(for: score.percentage))
                        .frame(width: max(0, geo.size.width * min(score.percentage / 100, 1)))
                }
            }
            .frame(height: 6)

            Text("\(score.actual)/\(score.expected)")
                .font(HavenTypography.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(score.category), \(score.actual) of \(score.expected)")
    }

    private var readinessColor: Color {
        if overallReadiness >= 80 { return .havenSuccess }
        if overallReadiness >= 50 { return .havenWarning }
        return .havenAccent
    }

    private var readinessLabel: String {
        if overallReadiness >= 80 { return "Well Prepared" }
        if overallReadiness >= 50 { return "Getting There" }
        if overallReadiness > 0 { return "Needs Attention" }
        return "Get Started"
    }

    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 100 { return .havenSuccess }
        if percentage >= 50 { return .havenWarning }
        return .havenCritical
    }
}

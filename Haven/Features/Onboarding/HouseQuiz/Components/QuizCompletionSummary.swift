import SwiftUI

/// Phase 60.5: Scrollable summary that follows the cinematic reveal.
/// Four cards — tasks scheduled, vendors on file, systems confirmed,
/// gaps closed — populated from `QuizFinaleTotals`. No estimation,
/// no rounding. The receipt the user scrolls through to confirm the
/// machinery did what was promised.
///
/// Reference pattern: TurboTax end-of-return summary, Stripe Dashboard
/// receipt-style per-category totals, Apple Health monthly summary
/// card stack.
struct QuizCompletionSummary: View {
    let totals: QuizFinaleTotals
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: HavenTheme.spacing20) {
            header

            tasksSection
            vendorsSection
            systemsSection
            if totals.gapsClosed > 0 {
                gapsSection
            }

            primaryCTA
                .padding(.top, HavenTheme.spacing16)
                .padding(.bottom, HavenTheme.spacing32)
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, HavenTheme.spacing24)
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Here's what we set up")
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Every item below is ready for you. Tap into your dashboard to dive deeper.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tasksSection: some View {
        summaryCard(
            icon: "calendar.badge.checkmark",
            count: totals.tasksScheduled,
            countLabel: totals.tasksScheduled == 1 ? "maintenance task scheduled" : "maintenance tasks scheduled",
            examples: totals.taskExamples,
            subtitle: "Each is a vendor visit to coordinate or a check to run yourself. Nothing is DIY cheerleading."
        )
    }

    private var vendorsSection: some View {
        summaryCard(
            icon: "person.2.wave.2.fill",
            count: totals.vendorsOnFile,
            countLabel: totals.vendorsOnFile == 1 ? "vendor on file" : "vendors on file",
            examples: totals.vendorExamples,
            subtitle: "Call, text, or email any of them from your dashboard. Chez will draft the message."
        )
    }

    private var systemsSection: some View {
        summaryCard(
            icon: "house.fill",
            count: totals.systemsConfirmed,
            countLabel: totals.systemsConfirmed == 1 ? "home system confirmed" : "home systems confirmed",
            examples: totals.systemExamples,
            subtitle: "Each tracks warranties, service history, and expected lifespan. Tap any for the full record."
        )
    }

    private var gapsSection: some View {
        summaryCard(
            icon: "checkmark.shield.fill",
            count: totals.gapsClosed,
            countLabel: totals.gapsClosed == 1 ? "item preserved" : "items preserved",
            examples: totals.gapExamples,
            subtitle: "Tasks you already had in-flight. We kept them exactly as they were."
        )
    }

    @ViewBuilder
    private func summaryCard(
        icon: String,
        count: Int,
        countLabel: String,
        examples: [String],
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(alignment: .center, spacing: HavenTheme.spacing12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 44, height: 44)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(count)")
                        .font(HavenTypography.fraunces(size: 32, weight: 700))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(countLabel)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !examples.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(examples.enumerated()), id: \.offset) { _, example in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(HavenColors.navy.opacity(0.3))
                                .frame(width: 4, height: 4)
                                .padding(.top, 7)
                            Text(example)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.leading, HavenTheme.spacing8)
            }

            Text(subtitle)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
    }

    private var primaryCTA: some View {
        Button {
            Haptics.success()
            onContinue()
        } label: {
            Text("Take me to my dashboard")
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.textOnNavy)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(HavenColors.navy800)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
        }
        .buttonStyle(.plain)
    }
}

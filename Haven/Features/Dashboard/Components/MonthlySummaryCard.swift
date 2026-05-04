import SwiftUI

// MARK: - MonthlySummaryCard (Phase 85 PR 5d)
//
// Dashboard card surfacing last month's Chez activity rollup — pre-
// aggregated by the chez-monthly-summary scheduled function on the
// 1st of each month and stored in `chez_monthly_summaries`.
//
// Renders only when there's an unviewed summary for the household.
// On tap, marks the row as viewed (auto-dismisses after the user
// has seen it once) and opens MonthlyReportView with the full
// breakdown.
//
// Visual style: indigo gradient (premium / month-end / "look back"
// tone), distinct from the salmon ChezActivityCard's "this week"
// energy.

struct MonthlySummaryCard: View {
    let summary: ChezMonthlySummaryRow
    var onTap: () -> Void = {}
    var onDismiss: () -> Void = {}

    var body: some View {
        Button(action: {
            Haptics.selection()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 14) {
                header
                tallyGrid
                if let headline = summary.headline, !headline.isEmpty {
                    headlineRow(headline)
                }
            }
            .padding(20)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .havenShadow(HavenTheme.shadowElevated)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: header

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 32, height: 32)
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(periodLabel.uppercased())
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(Color.white.opacity(0.78))
                    .tracking(1.0)
                Text("Your month with Chez")
                    .font(HavenTypography.title3)
                    .foregroundStyle(Color.white)
            }
            Spacer(minLength: 0)
            Button {
                Haptics.light()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss summary")
        }
    }

    // MARK: tally grid

    private var tallyGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            tallyRow(symbol: "checkmark.circle.fill",
                     label: "Tasks completed",
                     value: "\(summary.tasksCompleted)",
                     show: summary.tasksCompleted > 0)
            tallyRow(symbol: "calendar.badge.plus",
                     label: "Visits coordinated",
                     value: "\(summary.visitsCoordinated)",
                     show: summary.visitsCoordinated > 0)
            tallyRow(symbol: "lightbulb.fill",
                     label: "Recommendations",
                     value: "\(summary.recommendationsApproved)/\(summary.recommendationsLogged)",
                     show: summary.recommendationsLogged > 0)
            tallyRow(symbol: "dollarsign.circle.fill",
                     label: "Spent",
                     value: formattedSpend,
                     show: summary.totalSpendCents > 0)
        }
    }

    @ViewBuilder
    private func tallyRow(symbol: String, label: String, value: String, show: Bool) -> some View {
        if show {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 0) {
                    Text(value)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white)
                    Text(label)
                        .font(HavenTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.78))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        } else {
            Color.clear.frame(height: 0)
        }
    }

    // MARK: headline

    private func headlineRow(_ headline: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.action)
            Text(headline)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(Color.white)
                .lineLimit(2)
        }
        .padding(.top, 4)
    }

    // MARK: helpers

    private var periodLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: summary.periodStart)
    }

    private var formattedSpend: String {
        let dollars = Double(summary.totalSpendCents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = dollars >= 100 ? 0 : 2
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0"
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        HavenColors.navy800,
                        HavenColors.navy700,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                HavenColors.action.opacity(0.18),
                                Color.clear,
                            ],
                            center: .topTrailing,
                            startRadius: 0,
                            endRadius: 220
                        )
                    )
            )
    }

    private var accessibilityLabel: String {
        var parts: [String] = ["Your month with Chez", periodLabel]
        if summary.tasksCompleted > 0 { parts.append("\(summary.tasksCompleted) tasks completed") }
        if summary.visitsCoordinated > 0 { parts.append("\(summary.visitsCoordinated) visits coordinated") }
        if summary.totalSpendCents > 0 { parts.append("\(formattedSpend) spent") }
        if let headline = summary.headline { parts.append(headline) }
        return parts.joined(separator: ", ")
    }
}

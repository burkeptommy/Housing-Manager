import SwiftUI

/// Phase G1 (MaintenanceScheduleView parity): annual coordination
/// rollup at the top of Tasks v2.
///
/// Two stat blocks separated by a hairline divider:
///   - "This year" — total vendor visits to date (completed + upcoming
///     this calendar year) + total YTD spend
///   - "Next 30 days" — count of upcoming vendor visits in the next 30
///     days + estimated cost (sum of `estimatedCost` on tasks, fallback
///     to compact range)
///
/// Apple Health "Summary" card pattern: dense, scannable, low chrome.
/// Tap routes to a focused breakdown sheet (deferred — chevron present
/// to communicate tappability, the action is wired by the parent).
struct TasksV2YearSummaryCard: View {
    let yearVisitCount: Int
    let yearSpendDollars: Double
    let next30VisitCount: Int
    let next30EstimateDollars: Double
    var onTap: () -> Void = {}

    /// Hidden when the user has nothing tracked — surfaces only when
    /// there's actual coordinated volume to display. Avoids reading as
    /// a "0 visits this year" empty state on Day 1.
    private var shouldRender: Bool {
        yearVisitCount > 0 || next30VisitCount > 0
    }

    var body: some View {
        if shouldRender {
            Button(action: {
                Haptics.selection()
                onTap()
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    yearBlock
                    Divider()
                        .background(HavenColors.beige200)
                    next30Block
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                .havenShadow()
            }
            .buttonStyle(.plain)
        }
    }

    private var yearBlock: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("THIS YEAR")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(HavenColors.textTertiary)
                Text(yearHeadline)
                    .font(HavenTypography.fraunces(size: 18, weight: 600))
                    .tracking(-0.2)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            Spacer(minLength: 8)
        }
    }

    private var next30Block: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("NEXT 30 DAYS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(HavenColors.textTertiary)
                Text(next30Headline)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(HavenColors.textPrimary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    private var yearHeadline: String {
        let visitsPart = "\(yearVisitCount) vendor visit\(yearVisitCount == 1 ? "" : "s")"
        if yearSpendDollars > 0 {
            return "\(visitsPart) · \(compactCurrency(yearSpendDollars)) spent"
        }
        return visitsPart
    }

    private var next30Headline: String {
        if next30VisitCount == 0 {
            return "Nothing booked yet"
        }
        let visitsPart = "\(next30VisitCount) visit\(next30VisitCount == 1 ? "" : "s")"
        if next30EstimateDollars > 0 {
            return "\(visitsPart) · ~\(compactCurrency(next30EstimateDollars)) estimated"
        }
        return visitsPart
    }

    private func compactCurrency(_ value: Double) -> String {
        if value >= 1000 {
            let thousands = value / 1000
            if thousands >= 10 {
                return String(format: "$%.0fk", thousands)
            }
            return String(format: "$%.1fk", thousands)
        }
        return String(format: "$%.0f", value)
    }
}

import SwiftUI

// MARK: - ChezActivityCard (Phase 85 PR 5c)
//
// Dashboard card surfacing "this week with Chez" — a glanceable digest
// of what Chez has been doing on the homeowner's behalf in the last 7
// days. Renders only when there's something to show; DIY-default users
// never see it.
//
// Tally rows (most-impactful four):
//   ✓ Tasks completed
//   📅 Visits scheduled
//   💬 Quotes received
//   $ Spent
//
// Tap → ChezActivityView (full chronological list, paginated).
//
// Background salmon-tinted gradient anchors it visually as a Chez surface,
// distinct from the homeowner's own DIY task lists.

struct ChezActivityCard: View {
    let tally: ChezActivityWeeklyTally
    let recentItems: [ChezActivityLogRow]
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: {
            Haptics.selection()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                header
                tallyGrid
                if let preview = recentItems.first {
                    divider
                    previewRow(preview)
                }
            }
            .padding(20)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(HavenColors.action.opacity(0.18), lineWidth: 1)
            )
            .havenShadow()
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
                    .fill(HavenColors.action.opacity(0.16))
                    .frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("THIS WEEK WITH CHEZ")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.action)
                    .tracking(1.0)
                Text(headline)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.textSecondary)
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
                     label: "Tasks done",
                     value: "\(tally.tasksCompleted)",
                     show: tally.tasksCompleted > 0)
            tallyRow(symbol: "calendar.badge.plus",
                     label: "Visits scheduled",
                     value: "\(tally.visitsScheduled)",
                     show: tally.visitsScheduled > 0)
            tallyRow(symbol: "phone.fill",
                     label: "Quotes received",
                     value: "\(tally.quotesReceived)",
                     show: tally.quotesReceived > 0)
            tallyRow(symbol: "dollarsign.circle.fill",
                     label: "Spent",
                     value: formattedSpend,
                     show: tally.totalSpendCents > 0)
        }
    }

    @ViewBuilder
    private func tallyRow(symbol: String, label: String, value: String, show: Bool) -> some View {
        if show {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 0) {
                    Text(value)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(label)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        } else {
            // Empty placeholder keeps grid aligned without rendering.
            Color.clear.frame(height: 0)
        }
    }

    // MARK: preview row (most-recent activity)

    private var divider: some View {
        Rectangle()
            .fill(HavenColors.action.opacity(0.14))
            .frame(height: 1)
    }

    private func previewRow(_ row: ChezActivityLogRow) -> some View {
        HStack(spacing: 10) {
            Image(systemName: row.activityType.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.action)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(row.title)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                Text(row.occurredAt, style: .relative)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: helpers

    private var headline: String {
        let total = tally.totalEvents
        if total == 0 { return "Quiet week" }
        if total == 1 { return "1 thing handled" }
        return "\(total) things handled"
    }

    private var formattedSpend: String {
        let dollars = Double(tally.totalSpendCents) / 100.0
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
                        HavenColors.action.opacity(0.08),
                        HavenColors.action.opacity(0.02),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var accessibilityLabel: String {
        var parts: [String] = ["This week with Chez", headline]
        if tally.tasksCompleted > 0 { parts.append("\(tally.tasksCompleted) tasks completed") }
        if tally.visitsScheduled > 0 { parts.append("\(tally.visitsScheduled) visits scheduled") }
        if tally.quotesReceived > 0 { parts.append("\(tally.quotesReceived) quotes received") }
        if tally.totalSpendCents > 0 { parts.append("\(formattedSpend) spent") }
        return parts.joined(separator: ", ")
    }
}

import SwiftUI

/// Phase 55.2: Render mode for a routine on the schedule surface.
///
/// - `singleOccurrence`: one routine firing on one specific date. Used
///   in the Calendar layout's per-month section when a routine has
///   only one occurrence in that month.
/// - `collapsedMonth`: multiple occurrences for the same routine
///   collapsed into a single summary row ("Trash · 5x this week").
///   Used in List (This Week bucket) and Calendar (per month) to
///   prevent the 50-trash-icon-per-year noise. Tap toggles expansion.
/// - `expandedChild`: an individual date rendered under its collapsed
///   parent once the user taps to expand. Visually indented.
enum RoutineRowDisplay {
    case singleOccurrence(date: Date)
    case collapsedMonth(occurrenceCount: Int, windowLabel: String)
    case expandedChild(date: Date)
}

/// Phase 55.2: Compact ambient row for a routine on the maintenance
/// schedule. Deliberately light treatment — ~52pt single line, small
/// SF Symbol icon, no cost dots, no priority pill, no action buttons.
/// Routines hum along; they shouldn't compete with vendor task cards
/// for attention.
///
/// The View struct is named `RoutineOccurrenceRow` to avoid colliding
/// with the `RoutineRow` data model in `Routine.swift`.
struct RoutineOccurrenceRow: View {
    let routine: RoutineRow
    let display: RoutineRowDisplay
    let contractor: ContractorRow?
    let onTap: () -> Void
    let onExpandToggle: (() -> Void)?

    init(
        routine: RoutineRow,
        display: RoutineRowDisplay,
        contractor: ContractorRow? = nil,
        onTap: @escaping () -> Void,
        onExpandToggle: (() -> Void)? = nil
    ) {
        self.routine = routine
        self.display = display
        self.contractor = contractor
        self.onTap = onTap
        self.onExpandToggle = onExpandToggle
    }

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: HavenTheme.spacing12) {
                iconView
                contentView
                Spacer(minLength: 0)
                trailingView
            }
            .padding(.horizontal, HavenTheme.spacing12)
            .padding(.vertical, isCollapsed ? 12 : 10)
            .background(HavenColors.creamLight.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    private var isCollapsed: Bool {
        if case .collapsedMonth = display { return true }
        return false
    }

    @ViewBuilder
    private var iconView: some View {
        if let contractor, contractor.logoUrl != nil {
            // Vendor logo wins when present (Renata's biweekly cleaning
            // reads better with the company logo than a sparkles icon).
            VendorLogoView(contractor: contractor, size: isCollapsed ? 32 : 28)
        } else {
            Image(systemName: routine.resolvedIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: isCollapsed ? 32 : 28, height: isCollapsed ? 32 : 28)
                .background(HavenColors.beige200.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(routine.label)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
                .lineLimit(1)

            switch display {
            case .singleOccurrence(let date):
                singleOccurrenceSubtitle(date: date)
            case .collapsedMonth(let count, let windowLabel):
                Text("\(cadenceSummary) · \(count)x \(windowLabel)")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            case .expandedChild(let date):
                singleOccurrenceSubtitle(date: date)
            }
        }
    }

    @ViewBuilder
    private func singleOccurrenceSubtitle(date: Date) -> some View {
        let dateText = Self.weekdayFormatter.string(from: date)
        HStack(spacing: 4) {
            Text(dateText)
            if let contractor {
                Text("·")
                Text(contractor.companyName).lineLimit(1)
            }
            if let time = routine.formattedTimeOfDay {
                Text("·")
                Text(time)
            }
        }
        .font(HavenTypography.uiCaption)
        .foregroundStyle(HavenColors.textTertiary)
    }

    private var cadenceSummary: String {
        routine.typedCadence?.displayLabel ?? "Recurring"
    }

    @ViewBuilder
    private var trailingView: some View {
        switch display {
        case .collapsedMonth:
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary.opacity(0.6))
        case .singleOccurrence, .expandedChild:
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary.opacity(0.6))
        }
    }

    private func handleTap() {
        if case .collapsedMonth = display, let onExpandToggle {
            onExpandToggle()
        } else {
            onTap()
        }
    }
}

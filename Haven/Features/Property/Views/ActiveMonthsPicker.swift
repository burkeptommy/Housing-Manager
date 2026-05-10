import SwiftUI

/// Phase 55.3: Active-months picker for Routine configuration. Months
/// in `selectedMonths` (1=Jan..12=Dec) render as bold filled chips.
/// Months not in the selection render as strikethrough greyed chips.
/// Tap any chip to toggle. Below the chip row, a live summary
/// updates in natural language ("Active April through November",
/// "Active year-round", "Active March-May, September-November").
///
/// Visual reference: Apple Calendar's repeat picker and Fantastical's
/// recurrence editor. Both use this exact pattern for date-of-month
/// repeat rules. Quick-select presets below the summary match the
/// seasonal defaults the 55.1 backfill applies (Apr-Nov for
/// landscaping, May-Sep for pool, Dec-Mar for snow).
struct ActiveMonthsPicker: View {
    @Binding var selectedMonths: Set<Int>

    private let allMonths = Array(1...12)
    /// Apple Calendar uses single-letter labels for the 12 chips so
    /// the row fits on standard-width devices. Duplicates (J / J, M /
    /// M) read fine in context because they're ordered and adjacent.
    private let monthLabels = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
    private let monthFullNames = Calendar.current.shortMonthSymbols

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            // BUG-009 fix: chips now expand equally to fit available width
            // instead of using a fixed 28pt width that overflowed on
            // narrow viewports (clipping January on the left and December
            // on the right). Each chip takes (contentWidth - gaps) / 12.
            HStack(spacing: 4) {
                ForEach(allMonths, id: \.self) { month in
                    monthChip(month: month)
                }
            }
            .frame(maxWidth: .infinity)

            // Live summary — updates on every toggle.
            Text(Self.summary(for: Array(selectedMonths).sorted()))
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            // Quick presets — taps replace the full selection.
            // BUG-010 fix: horizontal scroll fallback so preset labels
            // can't clip on narrow screens ("Year-round" used to truncate
            // to "ear-round").
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    presetButton("All", months: Set(1...12))
                    presetButton("Apr-Nov", months: Set(4...11))
                    presetButton("May-Sep", months: Set(5...9))
                    presetButton("Dec-Mar", months: Set([12, 1, 2, 3]))
                }
            }
        }
    }

    private func monthChip(month: Int) -> some View {
        let isSelected = selectedMonths.contains(month)
        return Button {
            Haptics.selection()
            if isSelected {
                selectedMonths.remove(month)
            } else {
                selectedMonths.insert(month)
            }
        } label: {
            Text(monthLabels[month - 1])
                .font(.system(
                    size: 12,
                    weight: isSelected ? .bold : .regular,
                    design: .rounded
                ))
                .foregroundStyle(isSelected ? HavenColors.textOnNavy : HavenColors.textTertiary)
                .strikethrough(!isSelected, color: HavenColors.textTertiary.opacity(0.6))
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(isSelected ? HavenColors.navy : HavenColors.beige200.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("\(monthFullNames[month - 1]) \(isSelected ? "active" : "inactive")")
        }
        .buttonStyle(.plain)
    }

    private func presetButton(_ label: String, months: Set<Int>) -> some View {
        Button {
            Haptics.light()
            selectedMonths = months
        } label: {
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.navy700)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(HavenColors.navy.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Produces the natural-language summary for a sorted list of
    /// active months. Exposed as a static helper so RoutineEditSheet
    /// can bind it to the picker without duplicating the logic. Matches
    /// `RoutineRow.activeMonthsSummary` — if you update one, update the
    /// other.
    static func summary(for sortedMonths: [Int]) -> String {
        if sortedMonths == Array(1...12) { return "Active year-round" }
        if sortedMonths.isEmpty { return "Inactive. Nothing will fire." }

        var ranges: [(Int, Int)] = []
        var currentStart = sortedMonths[0]
        var currentEnd = sortedMonths[0]
        for m in sortedMonths.dropFirst() {
            if m == currentEnd + 1 {
                currentEnd = m
            } else {
                ranges.append((currentStart, currentEnd))
                currentStart = m
                currentEnd = m
            }
        }
        ranges.append((currentStart, currentEnd))

        if ranges.count > 1,
           let first = ranges.first,
           let last = ranges.last,
           first.0 == 1,
           last.1 == 12 {
            ranges.removeLast()
            ranges.removeFirst()
            ranges.insert((last.0, first.1), at: 0)
        }

        let monthNames = Calendar.current.monthSymbols
        let formatted = ranges.map { (start, end) -> String in
            if start == end { return monthNames[start - 1] }
            if start > end { return "\(monthNames[start - 1]) through \(monthNames[end - 1])" }
            return "\(monthNames[start - 1]) through \(monthNames[end - 1])"
        }
        return "Active " + formatted.joined(separator: ", ")
    }
}

import SwiftUI

/// Phase 70 (Tasks v2): Lightweight section subheader that splits the
/// "This Season's Tasks" feed into months. Renders the month name in
/// uppercase tracking, with a "TODAY" pill on the current month so the
/// user's eye anchors immediately to "where am I right now."
///
/// Visual:
///
///   APRIL   TODAY
///   _______________
///
///   MAY
///   _______________
struct MonthSubheader: View {
    /// 1-indexed month number (1 = January, 12 = December).
    let month: Int

    /// Phase 70.A2: calendar year. nil = current year (season-scoped feed,
    /// no label suffix). When set and not the current year, the label reads
    /// "JANUARY 2027" so the all-upcoming feed reads unambiguously across a
    /// year boundary.
    var year: Int? = nil

    /// When true, renders the salmon "TODAY" pill on the trailing edge of
    /// the header text. Computed at render time against `Calendar.current`
    /// so the pill appears on whatever month is the active "now." Only the
    /// CURRENT year's instance of the month gets the badge.
    var showsTodayBadge: Bool {
        let cal = Calendar.current
        let nowMonth = cal.component(.month, from: Date())
        let nowYear = cal.component(.year, from: Date())
        return nowMonth == month && (year == nil || year == nowYear)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(monthLabel.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textTertiary)
                .accessibilityAddTraits(.isHeader)

            if showsTodayBadge {
                Text("TODAY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(HavenColors.textOnAction)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(HavenColors.action))
                    .accessibilityLabel("Today")
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 6)
    }

    /// Long-form month name from the numeric month. Matches the iOS
    /// system locale so non-English installs read naturally.
    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"  // standalone month name
        let currentYear = Calendar.current.component(.year, from: Date())
        var comps = DateComponents()
        comps.year = year ?? currentYear
        comps.month = month
        comps.day = 1
        guard let date = Calendar.current.date(from: comps) else {
            return ""
        }
        let base = formatter.string(from: date)
        // Append the year only when it differs from the current year, so
        // the all-upcoming feed disambiguates "January 2027" from this
        // year's January without cluttering same-year headers.
        if let year, year != currentYear {
            return "\(base) \(year)"
        }
        return base
    }
}

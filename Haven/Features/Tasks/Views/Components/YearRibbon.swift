import SwiftUI

/// V5 YearRibbon — the season scoping device at the top of the Maintenance
/// screen. 4 horizontal tiles (Spring/Summer/Fall/Winter). Active tile is
/// 50% wider (flex 1.5 vs 1). NOW chip on the current-season tile when
/// it's the active one. Tinted bg per season when inactive; white when
/// active (with shadow + border).
///
/// Tap a tile to scope the rest of the Maintenance screen to that season.
struct YearRibbonSummary {
    /// Total items associated with this season (programs + decisions + tasks).
    let totalItems: Int
    /// Items requiring action (decisions + overdue + needs-vendor).
    let actionItems: Int
}

struct YearRibbon: View {
    @Binding var activeSeason: Season
    let summaries: [Season: YearRibbonSummary]
    let currentSeason: Season

    /// Year to display in the eyebrow. Defaults to the calendar year of
    /// the active season's reference period (Winter Dec/Jan straddles).
    var year: Int = Season.year(for: .current(), referenceDate: .now)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Eyebrow: "2026 · YEAR AT A GLANCE"
            Text("\(verbatimYear) · YEAR AT A GLANCE")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundStyle(HavenColors.textTertiary)

            HStack(spacing: 6) {
                ForEach(Season.allCases, id: \.rawValue) { season in
                    SeasonTile(
                        season: season,
                        summary: summaries[season] ?? YearRibbonSummary(totalItems: 0, actionItems: 0),
                        isActive: season == activeSeason,
                        isCurrent: season == currentSeason
                    )
                    .onTapGesture {
                        guard activeSeason != season else { return }
                        Haptics.selection()
                        withAnimation(TasksV5.easeRibbon) {
                            activeSeason = season
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilityLabel(for: season))
                    .accessibilityAddTraits(season == activeSeason ? .isSelected : [])
                }
            }
        }
        .padding(.horizontal, TasksV5.pageMargin)
        .padding(.bottom, 16)
    }

    private var verbatimYear: String {
        // Tabular nums to keep glyph spacing tight.
        String(year)
    }

    private func accessibilityLabel(for season: Season) -> String {
        let summary = summaries[season] ?? YearRibbonSummary(totalItems: 0, actionItems: 0)
        let action = summary.actionItems > 0 ? "\(summary.actionItems) need attention" : "all covered"
        let current = season == currentSeason ? ", current season" : ""
        return "\(season.displayName), \(summary.totalItems) items, \(action)\(current)"
    }
}

// MARK: - SeasonTile

private struct SeasonTile: View {
    let season: Season
    let summary: YearRibbonSummary
    let isActive: Bool
    let isCurrent: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(season.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isActive ? HavenColors.navy900 : season.v5Ink)
                    .padding(.bottom, 4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("\(summary.totalItems)")
                    .font(HavenTypography.fraunces(size: 20, weight: 700))
                    .tracking(-0.4)
                    .foregroundStyle(isActive ? HavenColors.navy900 : season.v5Ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(actionLine)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(actionColor)
                    .padding(.top, 4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isActive ? HavenColors.surface : season.v5Tint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isActive ? HavenColors.beige200 : Color.clear, lineWidth: 1)
            )
            .shadow(
                color: isActive ? HavenColors.navy800.opacity(0.08) : .clear,
                radius: isActive ? 8 : 0,
                x: 0,
                y: isActive ? 3 : 0
            )

            // NOW chip on current-season tile when active
            if isCurrent && isActive {
                Text("NOW")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(HavenColors.action)
                    )
                    .offset(x: 8, y: -6)
            }
        }
        // Tom: equal-sized pills, not active=50%-wider. The previous
        // layoutPriority(isActive ? 1.5 : 1) caused inactive tiles to
        // collapse to slivers that hid all their content.
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private var actionLine: String {
        summary.actionItems > 0 ? "\(summary.actionItems) action" : "covered"
    }

    private var actionColor: Color {
        summary.actionItems > 0 ? HavenColors.actionPressed : HavenColors.success
    }
}

#Preview {
    @Previewable @State var season: Season = .spring

    VStack {
        YearRibbon(
            activeSeason: $season,
            summaries: [
                .spring: .init(totalItems: 16, actionItems: 9),
                .summer: .init(totalItems: 7, actionItems: 0),
                .fall:   .init(totalItems: 9, actionItems: 2),
                .winter: .init(totalItems: 4, actionItems: 1),
            ],
            currentSeason: .spring
        )
        Spacer()
    }
    .padding(.top, 40)
    .background(HavenColors.background)
}

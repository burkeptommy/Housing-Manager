import SwiftUI

/// Phase 70 (Tasks v2): The 44pt scope banner that sits between the
/// YearRibbon and the season feed. Communicates the active scope at a
/// glance + exposes a search affordance on the trailing edge.
///
/// Phase 70.A1.x dropped the "Full year" toggle — the "Active Routines
/// This Season" card replaces its discoverability function, and the
/// full-year aggregator added more noise than signal (routines spanning
/// the year flooded into one combined feed).
///
/// Example state:
///
///   ┌─────────────────────────────────────────────────────────┐
///   │ Spring · 27 items · 4 need a decision                ⌕  │
///   └─────────────────────────────────────────────────────────┘
struct SeasonScopeBanner: View {
    /// Active season scope. Phase 70.A2: nil = "All upcoming" (the new
    /// default) — the ribbon is a filter, and the banner reads
    /// "All upcoming · N items" until the user narrows to a season.
    var season: Season? = nil

    /// Total items shown under the active scope (from `SeasonFeed.totalItems`).
    let totalItems: Int

    /// Items needing user action (from `SeasonFeed.actionItems`).
    let actionItems: Int

    /// Tap on the search icon. Opens a full-screen overlay (task 70.A1.10).
    var onSearch: () -> Void = {}
    /// Phase G2 — opens the 18-month linear timeline scrub.
    /// fullScreenCover, dismisses to return to the season feed.
    var onYearOverview: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Scope summary — left-aligned, single line, truncates middle on overflow.
            Text(scopeSummary)
                .font(HavenTypography.uiLabel)
                .foregroundColor(HavenColors.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 8)

            // Search icon button.
            Button {
                Haptics.selection()
                onSearch()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HavenColors.navy800)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search tasks, routines, and bundle items")

            // Phase G2 — Year overview (Timeline scrub).
            Button {
                Haptics.selection()
                onYearOverview()
            } label: {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HavenColors.navy800)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open year overview — 18-month timeline")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .havenShadow()
    }

    // MARK: - Derived strings

    /// Scope summary in homeowner voice. "Spring · 27 items · 4 need a decision"
    /// (singular pluralization handled below).
    private var scopeSummary: String {
        let head: String = season?.displayName ?? "All upcoming"
        let totalPart = "\(totalItems) item\(totalItems == 1 ? "" : "s")"
        if actionItems > 0 {
            let actionPart = actionItems == 1
                ? "1 needs a decision"
                : "\(actionItems) need a decision"
            return "\(head) · \(totalPart) · \(actionPart)"
        }
        return "\(head) · \(totalPart)"
    }
}

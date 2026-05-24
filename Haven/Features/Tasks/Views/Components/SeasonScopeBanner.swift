import SwiftUI

/// Phase 70 (Tasks v2): The 44pt scope banner that sits between the
/// YearRibbon and the season feed. Communicates the active scope at a
/// glance + exposes two affordances on the trailing edge:
///
/// - Search icon → opens `TasksSearchOverlay` (task 70.A1.10)
/// - "Show full year" / "Filter to season" toggle → clears or applies the
///   season filter
///
/// Example states:
///
///   ┌─────────────────────────────────────────────────────────┐
///   │ Spring · 27 items · 4 need a decision      ⌕  Full year │
///   └─────────────────────────────────────────────────────────┘
///
///   ┌─────────────────────────────────────────────────────────┐
///   │ All seasons · 84 items · 11 need attention   ⌕  Filter  │
///   └─────────────────────────────────────────────────────────┘
struct SeasonScopeBanner: View {
    /// Active season scope. Nil means "Show full year" (all seasons).
    let season: Season?

    /// Total items shown under the active scope (from `SeasonFeed.totalItems`,
    /// summed across all seasons when scope is full-year).
    let totalItems: Int

    /// Items needing user action (from `SeasonFeed.actionItems`).
    let actionItems: Int

    /// Tap on the search icon. Opens a full-screen overlay (task 70.A1.10).
    var onSearch: () -> Void = {}

    /// Tap on the trailing "Full year" / "Filter" link. Toggles scope.
    var onToggleScope: () -> Void = {}

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

            // Scope toggle link.
            Button {
                Haptics.selection()
                onToggleScope()
            } label: {
                HStack(spacing: 4) {
                    Text(toggleLabel)
                        .font(HavenTypography.uiLabel)
                        .foregroundColor(HavenColors.action)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(HavenColors.action)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(toggleAccessibilityLabel)
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
        let head: String = season?.displayName ?? "All seasons"
        let totalPart = "\(totalItems) item\(totalItems == 1 ? "" : "s")"
        if actionItems > 0 {
            let actionPart = actionItems == 1
                ? "1 needs a decision"
                : "\(actionItems) need a decision"
            return "\(head) · \(totalPart) · \(actionPart)"
        }
        return "\(head) · \(totalPart)"
    }

    private var toggleLabel: String {
        season == nil ? "Filter" : "Full year"
    }

    private var toggleAccessibilityLabel: String {
        season == nil
            ? "Filter back to the current season"
            : "Show items from the full year"
    }
}

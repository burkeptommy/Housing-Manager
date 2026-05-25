import SwiftUI

/// Phase 70.A1.x: Dedicated section for tasks tagged
/// `seasonalTiming: "Flexible"`. These are year-agnostic homeowner asks
/// (EV charger inspection, drain cleaning, electrical panel inspection)
/// that don't belong to a single season — they sit in their own list
/// until the homeowner picks a date.
///
/// Renders between "Needs your attention" and "This Season's Tasks" in
/// `MaintenanceTabView`. Surfaces regardless of which season tile is
/// active — Flexible tasks aren't seasonal by design.
///
/// Tap → opens `QuickSchedulingSheet`. Once the user picks a date the
/// task drops out of the flexible list (it now has a `scheduledDate`)
/// and into the picked month's bucket in the season feed.
///
/// Cap: 5 visible with "See all" link to the full schedule view.
struct FlexibleTasksSection: View {
    let tasks: [MaintenanceTaskDBRow]
    let contractor: (MaintenanceTaskDBRow) -> ContractorRow?
    let onTap: (MaintenanceTaskDBRow) -> Void
    let onSeeAll: () -> Void

    private static let visibleCap = 5

    var body: some View {
        guardEmpty {
            VStack(alignment: .leading, spacing: 12) {
                header
                ForEach(visibleTasks) { task in
                    StandaloneTaskRow(
                        task: task,
                        contractor: contractor(task),
                        onTap: { onTap(task) }
                    )
                }
                if tasks.count > Self.visibleCap {
                    seeAllLink
                }
            }
        }
    }

    private var visibleTasks: [MaintenanceTaskDBRow] {
        Array(tasks.prefix(Self.visibleCap))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("FLEXIBLE")
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textTertiary)
                .tracking(0.6)
            Text("·")
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textTertiary)
            Text("Pick a time when this works for you")
                .font(HavenTypography.uiLabel)
                .foregroundColor(HavenColors.textSecondary)
            Spacer(minLength: 0)
        }
    }

    private var seeAllLink: some View {
        Button(action: onSeeAll) {
            HStack(spacing: 4) {
                Text("See all \(tasks.count) flexible items")
                    .font(HavenTypography.uiLabel)
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(HavenColors.navy800)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    @ViewBuilder
    private func guardEmpty<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if tasks.isEmpty {
            EmptyView()
        } else {
            content()
        }
    }
}

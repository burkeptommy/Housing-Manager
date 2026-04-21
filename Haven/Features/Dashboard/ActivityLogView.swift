import SwiftUI

/// Full-screen list of all activity events grouped by calendar date.
/// Navigable from the "View all activity" link on the dashboard's
/// `RecentActivityFeed`.
struct ActivityLogView: View {
    let events: [RecentActivityEvent]
    var onTap: ((RecentActivityEvent) -> Void)?

    // MARK: - Grouped Data

    private var groupedByDay: [(key: String, events: [RecentActivityEvent])] {
        let calendar = Calendar.current

        let groups = Dictionary(grouping: events) { event -> String in
            if calendar.isDateInToday(event.occurredAt) {
                return "Today"
            } else if calendar.isDateInYesterday(event.occurredAt) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy"
                return formatter.string(from: event.occurredAt)
            }
        }

        // Sort groups by the earliest event date in each group (most recent first).
        return groups
            .map { (key: $0.key, events: $0.value.sorted { $0.occurredAt > $1.occurredAt }) }
            .sorted { lhs, rhs in
                guard let lhsDate = lhs.events.first?.occurredAt,
                      let rhsDate = rhs.events.first?.occurredAt
                else { return false }
                return lhsDate > rhsDate
            }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if events.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(groupedByDay, id: \.key) { section in
                        Section {
                            ForEach(section.events) { event in
                                Button {
                                    Haptics.light()
                                    onTap?(event)
                                } label: {
                                    eventRow(event)
                                }
                                .listRowBackground(HavenColors.surface)
                                .listRowInsets(EdgeInsets(
                                    top: HavenTheme.spacing8,
                                    leading: HavenTheme.spacing16,
                                    bottom: HavenTheme.spacing8,
                                    trailing: HavenTheme.spacing16
                                ))
                            }
                        } header: {
                            Text(section.key.uppercased())
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
                .listStyle(.grouped)
                .scrollContentBackground(.hidden)
                .background(HavenColors.background)
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Row

    private func eventRow(_ event: RecentActivityEvent) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: event.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(event.iconColor)
                .frame(width: 28, height: 28)
                .background(event.iconColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(HavenTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                Text(event.subtitle)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: HavenTheme.spacing16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 36))
                .foregroundStyle(HavenColors.textTertiary)
            Text("No activity yet")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Completed tasks, uploaded documents, and other updates will appear here.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HavenTheme.spacing24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HavenColors.background)
    }
}

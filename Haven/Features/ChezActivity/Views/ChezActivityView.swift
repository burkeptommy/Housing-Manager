import SwiftUI

// MARK: - ChezActivityView (Phase 85 PR 5c)
//
// Full chronological list of every Chez action for a household. Reached
// from the Dashboard ChezActivityCard's tap target. Defaults to a 30-day
// window with a "Load more" CTA at the bottom that bumps the window.

@MainActor
final class ChezActivityViewModel: ObservableObject {
    @Published var rows: [ChezActivityLogRow] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var daysBack: Int = 30

    private let householdId: UUID

    init(householdId: UUID) {
        self.householdId = householdId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            rows = try await DatabaseService.shared.fetchChezActivity(
                householdId: householdId,
                daysBack: daysBack,
                dashboardOnly: false,
                limit: 200
            )
        } catch {
            print("[ChezActivityView] load failed: \(error)")
            errorMessage = "We couldn't load your activity log. Pull to retry."
        }
    }

    func loadMore() async {
        daysBack = min(daysBack + 30, 365)
        await load()
    }
}

struct ChezActivityView: View {
    @StateObject private var viewModel: ChezActivityViewModel

    init(householdId: UUID) {
        _viewModel = StateObject(wrappedValue: ChezActivityViewModel(householdId: householdId))
    }

    var body: some View {
        List {
            if viewModel.rows.isEmpty && !viewModel.isLoading {
                emptyState
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(grouped(viewModel.rows), id: \.title) { group in
                    Section(header:
                        Text(group.title)
                            .font(HavenTypography.uiSectionHeader)
                            .foregroundStyle(HavenColors.textSecondary)
                    ) {
                        ForEach(group.rows) { row in
                            activityRow(row)
                        }
                    }
                }
                if viewModel.daysBack < 365 {
                    Button {
                        Task { await viewModel.loadMore() }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Load more (\(viewModel.daysBack + 30) days)")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.action)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.action)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(HavenColors.background.ignoresSafeArea())
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }

    // MARK: row

    @ViewBuilder
    private func activityRow(_ row: ChezActivityLogRow) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.14))
                    .frame(width: 32, height: 32)
                Image(systemName: row.activityType.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(row.title)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
                if let description = row.description, !description.isEmpty {
                    Text(description)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(3)
                }
                HStack(spacing: 6) {
                    Text(row.occurredAt, style: .relative)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                    if let cost = row.costCents, cost > 0 {
                        Text("·")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(formatCents(cost))
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .listRowSeparatorTint(HavenColors.beige200)
    }

    // MARK: empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(HavenColors.action.opacity(0.4))
            Text("No Chez activity yet")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
            Text("As Chez handles tasks, schedules visits, and gathers quotes for you, they'll show up here.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: helpers

    private struct DayGroup {
        let title: String
        let rows: [ChezActivityLogRow]
    }

    private func grouped(_ rows: [ChezActivityLogRow]) -> [DayGroup] {
        let cal = Calendar.current
        var buckets: [String: [ChezActivityLogRow]] = [:]
        var order: [String] = []
        for row in rows {
            let label = relativeDayLabel(for: row.occurredAt, calendar: cal)
            if buckets[label] == nil {
                buckets[label] = []
                order.append(label)
            }
            buckets[label]?.append(row)
        }
        return order.map { DayGroup(title: $0, rows: buckets[$0] ?? []) }
    }

    private func relativeDayLabel(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let now = Date()
        let daysAgo = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func formatCents(_ cents: Int64) -> String {
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = dollars >= 100 ? 0 : 2
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0"
    }
}

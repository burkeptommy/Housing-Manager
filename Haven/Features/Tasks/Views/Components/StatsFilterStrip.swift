import SwiftUI

/// Phase F1 (MaintenanceScheduleView parity): time-window filter strip.
/// Four pills (Overdue / This Week / This Month / Later) sit below the
/// SeasonScopeBanner. Tap a pill → feed shows only tasks matching that
/// window. Tap the active pill again (or the "Clear" caption) → exits
/// filter mode.
///
/// Pattern: Apple Mail folders / Linear filter chips / Reminders smart
/// lists. Research-supported decision: no premium task app uses
/// assignee as a top-level filter — every mature surface filters by
/// time window. Carried over from MaintenanceScheduleView Phase 56.4.
///
/// Not persisted — resets per session so the default "show everything"
/// state is always the starting point.

/// Time-window filter applied across the season feed + Flexible section.
enum TasksStatsFilter: String, CaseIterable, Identifiable {
    case overdue
    case thisWeek
    case thisMonth
    case later

    var id: String { rawValue }

    var label: String {
        switch self {
        case .overdue: return "Overdue"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .later: return "Later"
        }
    }

    /// Whether the task's nextDueDate falls in this filter's window.
    /// Uses scheduledDate when present, else nextDueDate. Tasks with
    /// unparseable dates fall through and never match (treated as
    /// distant-future).
    func matches(taskDateString: String?) -> Bool {
        guard let dateString = taskDateString else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return false }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: today),
              let monthEnd = calendar.date(byAdding: .day, value: 30, to: today)
        else { return false }

        switch self {
        case .overdue:
            return date < today
        case .thisWeek:
            return date >= today && date < weekEnd
        case .thisMonth:
            return date >= today && date < monthEnd
        case .later:
            return date >= monthEnd
        }
    }
}

/// Horizontally scrollable strip of 4 filter chips. Shows count per
/// pill in subscript form ("Overdue 3"). Active pill is navy-filled
/// with white text. Tapping the active pill toggles it off.
struct StatsFilterStrip: View {
    @Binding var active: TasksStatsFilter?
    /// Count by filter. Computed by the parent against the current
    /// active season + flexible tasks.
    let counts: [TasksStatsFilter: Int]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TasksStatsFilter.allCases) { filter in
                    chip(for: filter)
                }
                if active != nil {
                    clearChip
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func chip(for filter: TasksStatsFilter) -> some View {
        let count = counts[filter] ?? 0
        let isActive = active == filter
        let isDisabled = count == 0 && !isActive

        return Button {
            Haptics.selection()
            if isActive {
                active = nil
            } else {
                active = filter
            }
        } label: {
            HStack(spacing: 6) {
                Text(filter.label)
                    .font(.system(size: 13, weight: .semibold))
                Text("\(count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isActive ? Color.white.opacity(0.85) : HavenColors.textSecondary)
            }
            .foregroundStyle(isActive ? HavenColors.textOnNavy : HavenColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? HavenColors.navy800 : HavenColors.surface)
            )
            .overlay(
                Capsule()
                    .stroke(HavenColors.beige300, lineWidth: isActive ? 0 : 1)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var clearChip: some View {
        Button {
            Haptics.selection()
            active = nil
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                Text("Clear")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(HavenColors.action)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

import Foundation

// MARK: - Season Enum

/// Centralized season model. Replaces hardcoded string-based season logic
/// previously scattered across PropertyDetailViewModel and PropertyDetailView.
enum Season: String, CaseIterable, Equatable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"

    /// Current season based on simple month ranges.
    /// Mar-May = Spring, Jun-Aug = Summer, Sep-Nov = Fall, Dec-Feb = Winter.
    static func current(date: Date = .now) -> Season {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }

    var next: Season {
        switch self {
        case .spring: return .summer
        case .summer: return .fall
        case .fall: return .winter
        case .winter: return .spring
        }
    }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .fall: return "wind"
        case .winter: return "snowflake"
        }
    }

    /// Calendar year for this season instance. Winter straddles Dec/Jan,
    /// so we label by the January-February portion: Dec 2025 + Jan-Mar 2026 = "Winter 2026".
    static func year(for season: Season, referenceDate: Date = .now) -> Int {
        let cal = Calendar.current
        let year = cal.component(.year, from: referenceDate)
        let month = cal.component(.month, from: referenceDate)

        if season == .winter && month == 12 {
            // December: this winter belongs to next year's label
            return year + 1
        }
        return year
    }
}

// MARK: - Season Completion State

/// Tracks vendor assignment completion for a given season + year.
/// A season is "complete" when every vendor-type task across all groups
/// has an assigned contractor.
struct SeasonCompletionState: Equatable, Hashable, Identifiable {
    var id: String { completionKey }
    let season: Season
    let year: Int
    let groups: [SeasonalTaskGroup]

    var totalVendorTasks: Int {
        groups.reduce(0) { $0 + $1.vendorTasks.count }
    }

    var assignedVendorTasks: Int {
        groups.reduce(0) { $0 + $1.vendorAssignedCount }
    }

    /// Season is complete when ALL vendor tasks have an assigned contractor.
    /// Seasons with zero vendor tasks are considered complete (nothing to assign).
    var isComplete: Bool {
        totalVendorTasks == 0 || assignedVendorTasks == totalVendorTasks
    }

    var vendorCount: Int { assignedVendorTasks }

    var progress: Double {
        guard totalVendorTasks > 0 else { return 1.0 }
        return Double(assignedVendorTasks) / Double(totalVendorTasks)
    }

    /// Key for @AppStorage persistence, e.g. "spring_2026"
    var completionKey: String {
        "\(season.rawValue.lowercased())_\(year)"
    }

    static func == (lhs: SeasonCompletionState, rhs: SeasonCompletionState) -> Bool {
        lhs.season == rhs.season
            && lhs.year == rhs.year
            && lhs.totalVendorTasks == rhs.totalVendorTasks
            && lhs.assignedVendorTasks == rhs.assignedVendorTasks
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(season)
        hasher.combine(year)
        hasher.combine(totalVendorTasks)
        hasher.combine(assignedVendorTasks)
    }
}

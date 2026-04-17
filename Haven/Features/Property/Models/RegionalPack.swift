import Foundation

/// Phase 57: Regional maintenance pack derived from a property's state. Drives
/// which templates surface during setup and during whole-property reconciles.
/// `nil` (universal) is the default — only templates with an explicit regional
/// gate filter on this value.
///
/// Regions are grouped by broad climate/compliance similarity, not by ZIP
/// precision. DC is folded into Southeast. States unknown at migration time
/// stay `nil` so the filter defaults to universal-only.
enum RegionalPack: String, Codable, CaseIterable {
    case northeast
    case southeast
    case midwest
    case southwest
    case west

    /// Infer the regional pack from a two-letter state code. Returns `nil`
    /// for unrecognized or missing state values so callers can fall back to
    /// universal-only template gating.
    init?(state: String?) {
        guard let state, !state.isEmpty else { return nil }
        switch state.uppercased() {
        case "CT", "ME", "MA", "NH", "NJ", "NY", "PA", "RI", "VT":
            self = .northeast
        case "AL", "AR", "DE", "FL", "GA", "KY", "LA", "MD", "MS", "NC", "SC", "TN", "VA", "WV", "DC":
            self = .southeast
        case "IL", "IN", "IA", "KS", "MI", "MN", "MO", "NE", "ND", "OH", "SD", "WI":
            self = .midwest
        case "AZ", "NM", "OK", "TX":
            self = .southwest
        case "AK", "CA", "CO", "HI", "ID", "MT", "NV", "OR", "UT", "WA", "WY":
            self = .west
        default:
            return nil
        }
    }

    /// User-facing label for the regional recommendations block.
    var displayLabel: String {
        switch self {
        case .northeast: return "Northeast"
        case .southeast: return "Southeast"
        case .midwest:   return "Midwest"
        case .southwest: return "Southwest"
        case .west:      return "West"
        }
    }
}

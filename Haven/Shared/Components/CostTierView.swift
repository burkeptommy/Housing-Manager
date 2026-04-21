import SwiftUI

/// Four-tier cost indicator ($-$$$$) replacing numeric cost range strings.
/// Tier boundaries: $ < $50, $$ $50-$250, $$$ $250-$1,000, $$$$ $1,000+.
enum CostTier: Int, Comparable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4

    static func < (lhs: CostTier, rhs: CostTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Derive tier from an average dollar estimate.
    static func from(averageCost: Double?) -> CostTier? {
        guard let cost = averageCost, cost > 0 else { return nil }
        switch cost {
        case ..<50:      return .one
        case 50..<250:   return .two
        case 250..<1000: return .three
        default:         return .four
        }
    }

    /// Derive tier from a low/high range (uses midpoint).
    static func from(lowEstimate: Double?, highEstimate: Double?) -> CostTier? {
        guard let low = lowEstimate, let high = highEstimate, high >= low else {
            return from(averageCost: lowEstimate ?? highEstimate)
        }
        return from(averageCost: (low + high) / 2)
    }

    /// Parse a legacy string like "$10–$40", "$200–$400", "$0 (DIY)", "$3,000–$8,000".
    /// Handles both en-dash (U+2013) and hyphen (U+002D).
    static func fromLegacyString(_ s: String?) -> CostTier? {
        guard let s = s?.replacingOccurrences(of: ",", with: "") else { return nil }
        // Extract all dollar amounts
        let pattern = #"\$(\d+(?:\.\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(s.startIndex..., in: s)
        let matches = regex.matches(in: s, range: range)
        let numbers = matches.compactMap { match -> Double? in
            guard let numRange = Range(match.range(at: 1), in: s) else { return nil }
            return Double(s[numRange])
        }
        guard let low = numbers.first else { return nil }
        let high = numbers.count > 1 ? numbers[1] : low
        // $0 with no range = free/DIY, skip tier
        if low == 0 && high == 0 { return nil }
        return from(lowEstimate: low, highEstimate: high)
    }

    var accessibilityLabel: String {
        switch self {
        case .one:   return "Estimated cost: low"
        case .two:   return "Estimated cost: moderate"
        case .three: return "Estimated cost: high"
        case .four:  return "Estimated cost: premium"
        }
    }
}

/// Visual $-$$$$ tier indicator. Active signs in coral, inactive in textTertiary.
/// DESIGN_RULES.md Rule #3 exception: coral is approved for CostTierView.
struct CostTierView: View {
    let tier: CostTier?

    var body: some View {
        if let tier {
            HStack(spacing: 1) {
                ForEach(1...4, id: \.self) { index in
                    Text("$")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(
                            index <= tier.rawValue
                                ? HavenColors.action
                                : HavenColors.textTertiary.opacity(0.5)
                        )
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(tier.accessibilityLabel)
        }
    }
}

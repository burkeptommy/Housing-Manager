import Foundation

extension Double {
    /// Banded compact currency formatter for hero numbers and dashboards.
    ///
    /// Bands:
    /// - `< $1,000` → `$XYZ` (whole dollars, grouped)
    /// - `$1,000–$999,999` → `$XK` (rounded thousands, e.g. `$425K`)
    /// - `$1,000,000–$999,999,999` → `$X.YM` (one decimal, e.g. `$2.3M`, `$1.0M`)
    /// - `≥ $1,000,000,000` → `$X.YB` (one decimal, e.g. `$1.2B`)
    ///
    /// Negative values keep their sign (`-$2.3M`).
    func formattedCompactCurrency() -> String {
        let sign = self < 0 ? "-" : ""
        let abs = Swift.abs(self)

        if abs >= 1_000_000_000 {
            return "\(sign)$\(String(format: "%.1f", abs / 1_000_000_000))B"
        }
        if abs >= 1_000_000 {
            return "\(sign)$\(String(format: "%.1f", abs / 1_000_000))M"
        }
        if abs >= 1_000 {
            return "\(sign)$\(Int((abs / 1_000).rounded()))K"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "$\(Int(self))"
    }
}

extension Int {
    /// Convenience overload so call sites with `Int` values stay clean.
    func formattedCompactCurrency() -> String {
        Double(self).formattedCompactCurrency()
    }
}

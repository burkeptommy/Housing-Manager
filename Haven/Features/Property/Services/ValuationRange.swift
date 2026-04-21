import Foundation

/// Phase 20d: Optimistic valuation range helper.
///
/// The underlying valuation chain (ATTOM → RentCast → Claude AI comps →
/// computed → square-footage fallback) is unchanged. This helper only
/// changes the *display* layer so iOS surfaces a range with the high end
/// as the visual anchor instead of a single conservative number.
///
/// Two input paths:
/// 1. `compute(for property:)` — used after a property has been saved to
///    the DB. `PropertyRow` only persists `currentEstimatedValue`, so the
///    range is synthesized from that single number, widened by confidence.
/// 2. `compute(from lookup:)` — used at hook-screen render time when we
///    still have the live `PropertyLookupResult` in memory. When the
///    Phase 18g Claude AI fallback fired, the lookup carries an actual
///    `estimatedValueLow`/`estimatedValueHigh` pair we can show verbatim.
struct ValuationRange {
    let low: Double
    let high: Double
    /// True when the range was widened from a single number rather than
    /// returned by the data source. Manual overrides set this to false so
    /// the display layer can hide the range and show only the user's value.
    let isSynthesized: Bool
    /// True when the source explicitly told us "the user set this" and the
    /// display layer should not second-guess them with a range or caption.
    let isManual: Bool

    var midpoint: Double { (low + high) / 2 }

    /// Phase 20a Page 1: equity Haven helps protect, computed as 7.4% of
    /// the midpoint per the NAR Remodeling Impact Report. Rounded to the
    /// nearest $1,000 so the number reads cleanly in the hero card.
    var equityProtected: Double {
        let raw = midpoint * 0.074
        return (raw / 1_000).rounded() * 1_000
    }

    // MARK: - Compute from PropertyRow (post-save path)

    /// Build a range from a saved property row. Phase 56.2: when the
    /// ATTOM fallback ladder persisted a real AVM band
    /// (`currentEstimatedValueLow` / `currentEstimatedValueHigh`), return
    /// it verbatim — no more synthesizing. Only fall back to the
    /// confidence-widened synthesis when the band is missing (legacy
    /// rows, or sources that didn't supply a range).
    static func compute(for property: PropertyRow) -> ValuationRange? {
        // Manual override: respect the user's value verbatim. The
        // persisted band (if any) is ignored so we never bracket a
        // user-typed number with a stale machine range.
        if property.estimatedValueSource == "manual",
           let value = property.currentEstimatedValue, value > 0 {
            return ValuationRange(low: value, high: value, isSynthesized: false, isManual: true)
        }

        // Phase 56.2: real ATTOM band persisted — use it. Honest range,
        // no synthesis. Guard against sentinel / degenerate values.
        if let low = property.currentEstimatedValueLow,
           let high = property.currentEstimatedValueHigh,
           low > 0, high > low {
            return ValuationRange(low: low, high: high, isSynthesized: false, isManual: false)
        }

        guard let value = property.currentEstimatedValue, value > 0 else { return nil }

        let widening = wideningMultiplier(
            source: property.estimatedValueSource,
            confidence: property.estimatedValueConfidence
        )
        // Phase 56.2: centered synthesis. The stored `currentEstimatedValue`
        // is the midpoint (from the Build 84 ATTOM ladder), so treating it
        // as the low end and widening upward made "$955K" look like a
        // floor instead of a center. Now we spread ±halfBand around the
        // midpoint so "$860K to $1.05M" reads correctly as a confidence
        // interval around a $955K best guess.
        let halfBand = max(0, (widening - 1.0) / 2)
        return ValuationRange(
            low: max(0, value * (1 - halfBand)),
            high: value * (1 + halfBand),
            isSynthesized: true,
            isManual: false
        )
    }

    // MARK: - Compute from PropertyLookupResult (pre-save / hook path)

    /// Build a range from a fresh property lookup. When Phase 18g's
    /// Claude AI comps layer fired, the lookup carries an actual
    /// `estimatedValueLow`/`estimatedValueHigh` pair — use those verbatim.
    /// Otherwise widen the single value by the confidence multiplier.
    static func compute(from lookup: PropertyLookupResult?) -> ValuationRange? {
        guard let lookup else { return nil }

        // Phase 18g AI comps already gave us a precise range.
        if let low = lookup.estimatedValueLow, low > 0,
           let high = lookup.estimatedValueHigh, high > low {
            return ValuationRange(low: low, high: high, isSynthesized: false, isManual: false)
        }

        guard let value = lookup.estimatedValue, value > 0 else { return nil }

        let widening = wideningMultiplier(
            source: lookup.estimatedValueSource,
            confidence: lookup.estimatedValueConfidence
        )
        // Phase 56.2: centered synthesis around the midpoint — see the
        // matching comment in `compute(for:)`. Keeps hook-screen and
        // saved-card rendering consistent when no actual AVM band is
        // available.
        let halfBand = max(0, (widening - 1.0) / 2)
        return ValuationRange(
            low: max(0, value * (1 - halfBand)),
            high: value * (1 + halfBand),
            isSynthesized: true,
            isManual: false
        )
    }

    // MARK: - Helpers

    /// Pick how aggressively to widen a single value into a range. The
    /// rule of thumb: low-confidence sources get a wider band so the
    /// optimistic anchor isn't a guess at the high end of a guess.
    private static func wideningMultiplier(source: String?, confidence: Int?) -> Double {
        // Square-footage fallback ("estimated") is the weakest path.
        if source == "estimated" {
            return 1.30
        }
        // Computed fallback ("computed") is also weak — last sale plus
        // a fixed appreciation curve.
        if source == "computed" {
            return 1.25
        }
        // Otherwise let confidence pick: under 50 = wider, otherwise the
        // standard 20% optimistic widening.
        if let confidence, confidence > 0, confidence < 50 {
            return 1.25
        }
        return 1.20
    }

    // MARK: - Display formatting

    /// "$875,000" — the conservative low end formatted as full currency.
    var formattedLow: String { Self.formatFull(low) }

    /// "$1,050,000" — the optimistic high end formatted as full currency.
    var formattedHigh: String { Self.formatFull(high) }

    /// "$962,500" — the midpoint of the range, formatted as full currency.
    /// Phase 60.1 trust fix: used by PropertyHookView Page 1 AND
    /// PropertyRecapCard as the shared hero value so both surfaces agree.
    /// Previously Page 1 used `formattedHigh` while the recap used the
    /// persisted midpoint, which made the same property appear to change
    /// value mid-funnel (a $570K swing on HNW homes, HNW users notice).
    var formattedMidpoint: String { Self.formatFull(midpoint) }

    /// "$875K" — the low end in compact form for caption rows.
    var formattedLowCompact: String { low.formattedCompactCurrency() }

    /// "$1.05M" — the high end in compact form for caption rows.
    var formattedHighCompact: String { high.formattedCompactCurrency() }

    /// "$875,000 to $1,050,000" — the full range with the connecting
    /// preposition (no em dash, per CLAUDE.md).
    var formattedFullRange: String {
        "\(formattedLow) to \(formattedHigh)"
    }

    /// "$875K to $1.05M" — the compact range for tight captions.
    var formattedCompactRange: String {
        "\(formattedLowCompact) to \(formattedHighCompact)"
    }

    /// "$71,000" — the equity-protected midpoint times 7.4%, rounded to
    /// the nearest $1,000 and formatted as full currency.
    var formattedEquityProtected: String { Self.formatFull(equityProtected) }

    private static func formatFull(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

import Foundation

/// Phase 20: All user-facing copy for the PropertyHookView lives here so Tom
/// can edit copy without touching view code.
///
/// String tokens like `{city}`, `{state}`, `{address1}`, `{equityProtected}`,
/// `{yearBuilt}`, and `{fuelType}` are interpolated at render time via
/// `HookContent.interpolate(_:with:)`.
///
/// CLAUDE.md rule reminder: NO em dashes in user-facing copy. Use commas,
/// periods, or restructure.
enum HookContent {

    enum Page1 {
        // Hero
        static let titleTemplate = "Your home in {city}, {state}"
        static let valueRangeCaption = "We estimate optimistically. Most property apps undervalue."

        // Equity-protected anchor
        static let equityHeadline = "Homes maintained well sell for ~7.4% more."
        static let equityCitation = "Source: NAR Remodeling Impact Report"
        static let equityTemplate = "That's roughly {equityProtected} in equity Haven helps you protect."

        // Three preview cards
        static let previewSectionLabel = "WHAT HAVEN MANAGES"

        // Phase 20 polish: Home systems leads the preview cards on Page 1
        // because system management + maintenance is what protects the
        // asset value the equity card just promised. Vendor coordination,
        // documents, and Alfred all support this primary value driver.
        static let previewSystemsTitle = "Home systems & maintenance"
        static let previewSystemsBody = "HVAC, plumbing, roof, water heater. Tracked end to end with the right service cadence so nothing slips."
        static let previewSystemsIcon = "gauge.with.dots.needle.bottom.50percent"

        static let previewVendorsTitle = "Vendor coordination"
        static let previewVendorsBody = "Lawn, pool, HVAC, plumber, electrician, oil delivery. One place for all of them."
        static let previewVendorsIcon = "person.2.wave.2.fill"

        static let previewDocumentsTitle = "Document vault"
        static let previewDocumentsBody = "Deeds, warranties, inspections, insurance. Encrypted, organized, instant."
        static let previewDocumentsIcon = "lock.doc.fill"

        static let previewAlfredTitle = "Alfred, your concierge"
        static let previewAlfredBody = "Ask anything about your home. Get answers grounded in your actual data."
        static let previewAlfredIcon = "sparkles"

        // CTA
        static let ctaLabel = "See what we know about your home"
    }

    enum Page2 {
        // Personalization (top half)
        static let findingsHeader = "HERE'S WHAT WE ALREADY KNOW"
        static let findingsHeaderEmpty = "WE'RE STILL PULLING PUBLIC RECORDS"

        // Property-specific findings — render only when the underlying ATTOM
        // or RentCast field is present. The view picks the strongest signals
        // first (size, bedrooms, last sale) and falls back to year-built and
        // fuel hints. When NO real data is available the view shows the
        // empty-state copy below.
        static let findingsBuiltTemplate = "Built in {yearBuilt}."
        static let findingsSizeTemplate = "{squareFootage} square feet on a {lotSize} lot."
        static let findingsBedsBathsTemplate = "{bedrooms} bedrooms, {bathrooms} bathrooms."
        static let findingsLastSaleTemplate = "Last sold in {lastSaleYear} for {lastSalePrice}."
        static let findingsFuelTemplate = "Heated with {fuelType}, so you'll need a delivery contract on file."
        static let findingsRoofTemplate = "{roofType} roof, typically inspected every 1 to 2 years."
        static let findingsPoolTemplate = "In-ground pool detected, which adds about $200 to $400 per month in season."
        static let findingsMoreLine = "We'll surface more once you finish setup."
        static let findingsEmptyLine = "We couldn't pull public records for this address yet. Haven will keep trying."

        // Bridge to home management frame
        static let bridgeText = "And here's why all of it matters."

        // Phase 20 polish: Page 2 stat replaces the duplicated 7.4% from
        // Page 1 with a coordination/scale stat that gives users a NEW
        // reason to commit. The frame: HNW homeowners aren't worried about
        // cost, they're worried about KEEPING TRACK and not having things
        // fall through the cracks. The stat names the operational scale
        // of running a home and positions Haven as the source of truth.
        // Variable names retained for backward compat with the view code.
        static let equityReminderHeadline = "A typical home has 14+ vendors and 200+ documents tied to it."
        static let equityReminderBody = "Most homeowners can't find half of them when they need to. Haven keeps every name, visit, and invoice in one place, instantly searchable."
        static let equityReminderCitation = "Source: Houzz Home Services Industry Report"

        // Home management frame (bottom half) — reframed from estate-only
        // to home-system + asset-protection language. The card stack below
        // emphasizes day-to-day home operations, not just inheritance docs.
        static let estateHeadline = "Your home is your largest asset."
        static let estateBody = "Haven tracks every system, vendor, and dollar so you can protect what it's worth."

        // Phase 20 polish: 4-card 2×2 grid for visual uniformity. Removed
        // the "Value & equity" card because the optimistic valuation +
        // equity-protected card on Page 1 already covers that ground;
        // Page 2 stays focused on operational home management. The four
        // remaining categories are the day-to-day jobs Haven actually does.
        static let estateCards: [(icon: String, label: String, subtitle: String)] = [
            ("gauge.with.dots.needle.bottom.50percent", "Home systems", "HVAC, plumbing, roof, water heater"),
            ("person.2.fill", "Vendor coordination", "Lawn, pool, HVAC, plumber, oil"),
            ("calendar.badge.checkmark", "Maintenance plan", "Seasonal tasks, refills, service visits"),
            ("doc.text.fill", "Docs & warranties", "Deeds, manuals, inspections, claims"),
        ]

        static let legacyLine = "Stay on top of every dollar your home is worth."

        // CTAs differ based on auth state — pick at render time.
        static let ctaUnauthenticatedTemplate = "Get Started with {address1}"
        static let ctaAuthenticated = "Continue to your home quiz"
    }

    // MARK: - Token interpolation

    /// Replace `{key}` placeholders in `template` with the corresponding
    /// values from `tokens`. Unknown tokens are left in place so missing
    /// data is obvious during development.
    static func interpolate(_ template: String, with tokens: [String: String]) -> String {
        var result = template
        for (key, value) in tokens {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}

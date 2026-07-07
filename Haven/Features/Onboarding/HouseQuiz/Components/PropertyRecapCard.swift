import SwiftUI

/// Phase 60.1: The first screen of the House Quiz. Shows every field Haven
/// pulled from ATTOM alongside the detected systems, with an inline edit
/// affordance on every row. This is the single most important trust moment
/// in onboarding — HNW homeowners need to see that Haven knows about their
/// specific house before they invest 5 minutes answering questions about it.
///
/// Reference patterns: Zillow's post-address landing card (shows the property
/// the moment you type an address), Betterment's net-worth anchor before
/// goal-setting, TurboTax's prior-year return summary as a trust anchor
/// before the new-year data entry.
struct PropertyRecapCard: View {
    let property: PropertyRow
    let detectedSystems: [HomeSystemRow]
    let lookupSource: String?
    let onEdit: (PropertyEditField) -> Void
    let onConfirm: () -> Void

    /// Phase 60.1: Identifiable so `.sheet(item:)` can route edits to the
    /// right editor without losing state between presentations.
    ///
    /// Phase 67D (B1): Extended with `bedrooms`, `bathrooms`, `lotSize`,
    /// `purchaseDate` to round out the ATTOM data surface. Each new row
    /// reads from `property.attributes` (JSONB) or the dedicated column,
    /// and the edit sheet writes through `PropertyUpdate`. Q4 and Q5
    /// were removed from the quiz in `0367137f`, so purchase price +
    /// purchase date both live here now.
    enum PropertyEditField: String, Identifiable {
        case yearBuilt
        case squareFootage
        case purchasePrice
        case estimatedValue
        case bedrooms
        case bathrooms
        case lotSize
        case purchaseDate
        /// Phase 80 — fireplace count + type capture. Backed by
        /// `properties.attributes['has_wood_fireplace']`,
        /// `['wood_fireplace_count']`, and `['has_gas_fireplace']`.
        /// `HouseQuizAnswerMapper.resolveChimneyRule` reads these
        /// attributes as a second source of truth so the user can
        /// correct an ATTOM miss OR an ambiguous Q20 answer without
        /// retaking the quiz. Tom hit this — ATTOM didn't return
        /// fireplace data for 146 Putnam, Q20 read as "fuel SOURCES"
        /// not "do you have fireplaces", his chimney got tagged
        /// `furnace_flue` and the sweep / creosote / spring wood
        /// inspection tasks silently went missing.
        case fireplaces

        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing20) {
                header

                if let value = property.currentEstimatedValue, value > 0 {
                    valuationHero(value: value)
                }

                addressBlock
                facts

                if !detectedSystems.isEmpty {
                    systemsBlock
                }

                HavenButton(
                    title: "Looks right, start the quiz",
                    action: {
                        Haptics.medium()
                        onConfirm()
                    },
                    icon: "arrow.right",
                    // Phase 80 — block the CTA until the user has
                    // explicitly answered the fireplaces row. The
                    // `.missing` accent on the row is a strong visual
                    // nudge, but Tom flagged that we need a hard gate
                    // here because his missed fireplaces were the
                    // root cause of his chimney sweep being silently
                    // dropped. Cheap insurance: one extra tap to
                    // confirm "None / Wood / Gas" before quiz starts.
                    isDisabled: !fireplacesAnswered
                )
                .padding(.top, HavenTheme.spacing8)

                if !fireplacesAnswered {
                    // Phase 80 — explanatory caption replacing the
                    // generic "change later" line until the user
                    // resolves the fireplaces row. Salmon-accent so
                    // it draws the eye in the same way the row itself
                    // does.
                    Text("Tap the Fireplaces row above to confirm. Wood-burning fireplaces need a chimney sweep that we'd otherwise miss.")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.action)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                } else {
                    Text("You can change any of this later from your property detail page.")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                Spacer(minLength: HavenTheme.spacing24)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, HavenTheme.spacing24)
        }
        .background(HavenColors.background)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Here's what we found")
                .font(HavenTypography.title)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Tap any field to correct it before we build your plan.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Valuation Hero

    @ViewBuilder
    private func valuationHero(value: Double) -> some View {
        Button {
            Haptics.light()
            onEdit(.estimatedValue)
        } label: {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(spacing: 6) {
                    Text("CURRENT VALUE")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.creamLight.opacity(0.8))
                        .tracking(1.2)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.creamLight.opacity(0.8))
                }

                Text(formattedCurrency(value))
                    .font(HavenTypography.fraunces(size: 32, weight: 700))
                    .foregroundStyle(HavenColors.creamLight)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let source = lookupSource {
                    Text(sourceCaption(source))
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.creamLight.opacity(0.85))
                }

                if let low = property.currentEstimatedValueLow,
                   let high = property.currentEstimatedValueHigh {
                    Text("Range \(formattedCompactCurrency(low)) – \(formattedCompactCurrency(high))")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.creamLight.opacity(0.75))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(HavenTheme.spacing16)
            .background(
                LinearGradient(
                    colors: [HavenColors.navy800, HavenColors.navy700],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Address

    private var addressBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(streetLine)
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            if let cityLine {
                Text(cityLine)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var streetLine: String {
        [property.street, property.unit]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
            .ifEmpty(property.name)
    }

    private var cityLine: String? {
        let parts = [
            property.city?.trimmingCharacters(in: .whitespaces),
            property.state?.trimmingCharacters(in: .whitespaces)
        ].compactMap { $0 }.filter { !$0.isEmpty }
        let cityState = parts.joined(separator: ", ")
        let zip = property.zipCode?.trimmingCharacters(in: .whitespaces) ?? ""
        let combined = [cityState, zip].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? nil : combined
    }

    // MARK: - Facts

    private var facts: some View {
        VStack(spacing: HavenTheme.spacing8) {
            factRow(
                label: "Year built",
                value: property.yearBuilt.map(String.init) ?? "Not on file",
                accent: property.yearBuilt == nil ? .missing : .normal,
                field: .yearBuilt
            )
            factRow(
                label: "Square footage",
                value: property.squareFootage.map { "\(Int($0).formatted()) sqft" } ?? "Not on file",
                accent: property.squareFootage == nil ? .missing : .normal,
                field: .squareFootage
            )
            // Phase 67D (B1): bedrooms / bathrooms / lot size from
            // `attributes` JSONB. ATTOM stamps these at property
            // creation; user taps to correct any field.
            factRow(
                label: "Bedrooms",
                value: bedroomsDisplay,
                accent: bedroomsValue == nil ? .missing : .normal,
                field: .bedrooms
            )
            factRow(
                label: "Bathrooms",
                value: bathroomsDisplay,
                accent: bathroomsValue == nil ? .missing : .normal,
                field: .bathrooms
            )
            factRow(
                label: "Lot size",
                value: lotSizeDisplay,
                accent: lotSizeValue == nil ? .missing : .normal,
                field: .lotSize
            )
            factRow(
                label: "Purchase price",
                value: purchasePriceDisplay,
                accent: purchasePriceAccent,
                field: .purchasePrice
            )
            // Phase 67D (B1): Q4/Q5 dropped from quiz (commit 0367137f);
            // purchase date now lives here so years-owned analytics
            // still has a source. ATTOM stamps `last_sale_date` at
            // creation; user can correct or fill via tap.
            factRow(
                label: "Purchased on",
                value: purchaseDateDisplay,
                accent: property.purchaseDate == nil ? .missing : .normal,
                field: .purchaseDate
            )
            // Phase 80 — fireplace prompt. The Q20 fuel-sources question
            // is ambiguous and ATTOM misses fireplaces for many suburban
            // NE addresses (this is how Tom's 2 wood-burning fireplaces
            // got missed). Surfacing it as a recap row gives every new
            // homeowner an explicit confirmation step before the quiz.
            factRow(
                label: "Fireplaces",
                value: fireplacesDisplay,
                accent: fireplacesAccent,
                field: .fireplaces
            )
        }
    }

    /// Phase 80 — formatted display for the fireplaces row. Reads three
    /// attributes set by `PropertyRecapEditSheet`'s fireplace editor:
    /// `has_wood_fireplace`, `wood_fireplace_count`, `has_gas_fireplace`.
    /// Returns the most-specific summary available; falls through to a
    /// "tap to confirm" prompt when nothing's on file.
    private var fireplacesDisplay: String {
        let attrs = property.attributes ?? [:]
        let hasWood = attrs["has_wood_fireplace"]?.stringValue.lowercased() == "true"
        let hasGas = attrs["has_gas_fireplace"]?.stringValue.lowercased() == "true"
        let count = Int(attrs["wood_fireplace_count"]?.stringValue ?? "")
        if hasWood, let count, count > 0 {
            return count == 1
                ? "1 wood-burning fireplace"
                : "\(count) wood-burning fireplaces"
        }
        if hasWood { return "Wood-burning fireplace" }
        if hasGas { return "Gas fireplace" }
        // Explicit "no fireplace" answer captured (different from
        // missing). The picker writes `has_wood_fireplace=false` +
        // `has_gas_fireplace=false` when the user picks "None".
        let answeredNo = attrs["has_wood_fireplace"]?.stringValue.lowercased() == "false"
            && attrs["has_gas_fireplace"]?.stringValue.lowercased() == "false"
        if answeredNo { return "None" }
        return "Tap to confirm"
    }

    private var fireplacesAccent: FactAccent {
        fireplacesAnswered ? .normal : .missing
    }

    /// Phase 80 — bool gate for the "start the quiz" CTA. True when
    /// the user has explicitly resolved the fireplaces row (either
    /// answered wood, gas, or "None"). False when nothing's on file —
    /// blocks the CTA so the homeowner can't bypass the prompt and
    /// land in the same chimney-sweep-missing hole Tom did.
    private var fireplacesAnswered: Bool {
        let attrs = property.attributes ?? [:]
        let wood = attrs["has_wood_fireplace"]?.stringValue.lowercased()
        let gas = attrs["has_gas_fireplace"]?.stringValue.lowercased()
        // "true" on either OR explicit "false" on both (the "None"
        // selection) — both count as answered. Anything else is
        // missing.
        if wood == "true" || gas == "true" { return true }
        if wood == "false" && gas == "false" { return true }
        return false
    }

    private var purchaseDateDisplay: String {
        // PropertyRow.purchaseDate is String? (ISO yyyy-MM-dd) per
        // DatabaseModels. Parse and re-format to "MMM d, yyyy" for the
        // recap card display. Falls back gracefully if parsing fails.
        guard let raw = property.purchaseDate else { return "Not on file" }
        if let parsed = Self.isoDateFormatter.date(from: raw) {
            return Self.displayDateFormatter.string(from: parsed)
        }
        return raw  // best-effort fallback for non-ISO strings
    }

    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    // MARK: - Phase 67D (B1): attribute-backed fact accessors

    private var bedroomsValue: Int? {
        guard let raw = property.attributes?["bedrooms"]?.stringValue,
              let count = Int(raw) else { return nil }
        return count
    }

    private var bedroomsDisplay: String {
        guard let count = bedroomsValue else { return "Not on file" }
        return count == 1 ? "1 bedroom" : "\(count) bedrooms"
    }

    private var bathroomsValue: Double? {
        guard let raw = property.attributes?["bathrooms"]?.stringValue,
              let count = Double(raw) else { return nil }
        return count
    }

    private var bathroomsDisplay: String {
        guard let count = bathroomsValue else { return "Not on file" }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        let str = formatter.string(from: NSNumber(value: count)) ?? "\(count)"
        return count == 1 ? "1 bathroom" : "\(str) bathrooms"
    }

    private var lotSizeValue: Double? {
        guard let raw = property.attributes?["lot_size"]?.stringValue,
              let size = Double(raw) else { return nil }
        return size
    }

    private var lotSizeDisplay: String {
        guard let size = lotSizeValue else { return "Not on file" }
        // ATTOM lot_size is in square feet — show acreage when > 0.5
        // acres (21,780 sqft) since acres reads more naturally for
        // suburban/HNW lots.
        if size > 21_780 {
            let acres = size / 43_560
            return String(format: "%.2f acres", acres)
        }
        return "\(Int(size).formatted()) sqft"
    }

    private var purchasePriceDisplay: String {
        if let price = property.purchasePrice, price > 0 {
            return formattedCurrency(price)
        }
        return "No sale on record"
    }

    private var purchasePriceAccent: FactAccent {
        if let price = property.purchasePrice, price > 0 {
            return .normal
        }
        return .warning
    }

    @ViewBuilder
    private func factRow(
        label: String,
        value: String,
        accent: FactAccent,
        field: PropertyEditField
    ) -> some View {
        Button {
            Haptics.light()
            onEdit(field)
        } label: {
            HStack {
                Text(label)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Text(value)
                    .font(HavenTypography.body.weight(.medium))
                    .foregroundStyle(accent.textColor)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    enum FactAccent {
        case normal
        case missing
        case warning

        var textColor: Color {
            switch self {
            case .normal: return HavenColors.textPrimary
            case .missing: return HavenColors.textTertiary
            case .warning: return HavenColors.warning
            }
        }
    }

    // MARK: - Systems Block

    private var systemsBlock: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("WHAT WE DETECTED AT YOUR HOME")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.2)
                .foregroundStyle(HavenColors.textTertiary)

            VStack(spacing: 0) {
                ForEach(detectedSystems) { system in
                    HStack(spacing: 10) {
                        Image(systemName: iconFor(category: system.category))
                            .font(.system(size: 14))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 22)
                        Text(system.name)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    if system.id != detectedSystems.last?.id {
                        Divider()
                            .background(HavenColors.beige200)
                    }
                }
            }
            .padding(.horizontal, HavenTheme.spacing12)
            .padding(.vertical, 4)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private func iconFor(category: String) -> String {
        switch category {
        case "HVAC":              return "fan.fill"
        case "Roofing":           return "house.fill"
        case "Water Heater":      return "flame.fill"
        case "Electrical":        return "bolt.fill"
        case "Pool/Spa":          return "figure.pool.swim"
        case "Garage Door":       return "door.garage.closed"
        case "Fire Protection":   return "flame.circle.fill"
        case "Foundation":        return "square.stack.3d.up.fill"
        case "Crawl Space":       return "rectangle.split.1x2.fill"
        case "Basement":          return "stairs"
        case "Plumbing":          return "drop.fill"
        default:                  return "wrench.fill"
        }
    }

    private func sourceCaption(_ source: String) -> String {
        switch source {
        case "attom":     return "Estimated from public records (ATTOM)"
        case "rentcast":  return "Estimated from market data (RentCast)"
        case "ai_comps":  return "Estimated from recent comparable sales"
        case "computed":  return "Projected from last sale price"
        case "estimated": return "Rough estimate. Tap to correct."
        case "manual":    return "You set this manually"
        default:          return "Estimated value"
        }
    }

    private func formattedCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private func formattedCompactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            let millions = value / 1_000_000
            return String(format: "$%.1fM", millions)
        }
        if value >= 1_000 {
            let thousands = value / 1_000
            return String(format: "$%.0fK", thousands)
        }
        return "$\(Int(value))"
    }
}

// MARK: - String helper

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespaces).isEmpty ? fallback : self
    }
}

import Foundation

/// Phase 60.4: Token source for personalized House Quiz titles. Built
/// once per question render from the `PropertyRow` (ATTOM-enriched)
/// and any captured answers that factor into downstream questions
/// (currently only the roof answer).
///
/// The rule: every token either resolves to real user data or falls
/// through to the question's `fallbackTitle`. The renderer never ships
/// literal braces (e.g. `"Your {yearBuilt} roof"`) to the UI — if the
/// fallback is also missing, we strip the token and any surrounding
/// whitespace so the title still reads as a normal English sentence.
struct PropertyFactBundle {
    var yearBuilt: Int?
    var street: String?
    var city: String?
    var state: String?
    var squareFootage: Int?
    /// Roof material slug from Q1. Resolved to a display label via the
    /// static map so tokens like `{roofType}` read as "asphalt shingle"
    /// rather than the raw `asphalt` answer id.
    var roofType: String?

    init(property: PropertyRow, roofAnswerId: String? = nil) {
        self.yearBuilt = property.yearBuilt
        self.street = Self.shortenedStreet(property.street)
        self.city = property.city
        self.state = property.state
        self.squareFootage = property.squareFootage
        self.roofType = roofAnswerId.flatMap(Self.roofDisplayLabel)
    }

    /// Trim leading house number and common street-name suffixes so
    /// `"146 Putnam Park Road"` renders as `"Putnam Park"` in a
    /// conversational title ("your Putnam Park roof" reads warmer
    /// than "your 146 Putnam Park Road roof"). If the raw street is
    /// nil/empty, we return nil so the token fallback path fires.
    ///
    /// Phase 60.1 trust fix (2026-04-20): preserve the suffix on
    /// single-word street names. "Sarles kitchen" reads as a typo; "Sarles
    /// Street kitchen" reads as a location. Multi-word streets (Putnam
    /// Park, Bedford Hills, Round Hill) are long enough to stand alone
    /// without the suffix.
    private static func shortenedStreet(_ raw: String?) -> String? {
        guard var result = raw?.trimmingCharacters(in: .whitespaces), !result.isEmpty else {
            return nil
        }
        // Strip leading numeric house number.
        let parts = result.split(separator: " ", maxSplits: 1)
        if parts.count == 2, Int(parts[0]) != nil {
            result = String(parts[1])
        }
        // Strip a single trailing street-type suffix. Match longest-first
        // so "Terrace" doesn't get partially stripped as "Ter". But only
        // when the remaining street has multiple words — a bare
        // single-word street (Sarles, Elm, Oak) needs the suffix for
        // context.
        let suffixes = [
            " Boulevard", " Terrace", " Avenue", " Street", " Circle",
            " Court", " Drive", " Place", " Lane", " Road",
            " Blvd", " Ave", " Ct", " Dr", " Ln", " Pl", " Rd",
            " St", " Ter"
        ]
        let lowered = result.lowercased()
        for suffix in suffixes {
            if lowered.hasSuffix(suffix.lowercased()) {
                let stripped = String(result.dropLast(suffix.count))
                    .trimmingCharacters(in: .whitespaces)
                let wordCount = stripped.split(separator: " ").count
                if wordCount >= 2 {
                    result = stripped
                }
                break
            }
        }
        let trimmed = result.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func roofDisplayLabel(_ answerId: String) -> String? {
        switch answerId {
        case "asphalt":        return "asphalt shingle"
        case "metal":          return "metal"
        case "tile":           return "tile"
        case "slate":          return "slate"
        case "wood_shake":     return "wood shake"
        case "flat_membrane":  return "flat membrane"
        default:               return nil
        }
    }
}

extension HouseQuizQuestion {
    /// Phase 60.4: Token-substituted question title. Pulls from the
    /// `PropertyFactBundle` at render time. Tokens that can't be
    /// resolved fall back to `fallbackTitle` when set, or to a
    /// brace-stripped version of the original when not.
    func personalizedTitle(using facts: PropertyFactBundle) -> String {
        guard title.contains("{") else { return title }
        let tokenValues: [(String, String?)] = [
            ("{yearBuilt}",      facts.yearBuilt.map(String.init)),
            ("{street}",         facts.street),
            ("{city}",           facts.city),
            ("{state}",          facts.state),
            ("{squareFootage}",  facts.squareFootage.map { "\($0.formatted()) sqft" }),
            ("{roofType}",       facts.roofType),
        ]
        var result = title
        for (token, value) in tokenValues where result.contains(token) {
            if let v = value, !v.isEmpty {
                result = result.replacingOccurrences(of: token, with: v)
            } else {
                // Token is unresolvable. Prefer the explicit fallback;
                // if none is provided, strip the token from the current
                // result and return what remains (defensive — every
                // token-using question SHOULD provide a fallbackTitle).
                if let fallback = fallbackTitle, !fallback.isEmpty {
                    return fallback
                }
                result = result.replacingOccurrences(of: token, with: "")
                    .replacingOccurrences(of: "  ", with: " ")
                    .trimmingCharacters(in: .whitespaces)
            }
        }
        return result
    }
}

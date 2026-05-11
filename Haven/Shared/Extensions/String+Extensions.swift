import Foundation

extension String {
    var isValidEmail: Bool {
        let regex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/
        return wholeMatch(of: regex.ignoresCase()) != nil
    }

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Convert "yyyy-MM-dd" to "March 15, 2026"
    var havenDateFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: self) else { return self }
        return date.havenFull
    }

    /// Convert "yyyy-MM-dd" to "Mar 15, 2026"
    var havenDateShort: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: self) else { return self }
        return date.havenShort
    }

    /// Truncate to a max character length, cutting at the last word boundary.
    func summarized(maxLength: Int) -> String {
        guard count > maxLength else { return self }
        let trimmed = prefix(maxLength)
        // Cut at last space so we don't chop mid-word
        if let lastSpace = trimmed.lastIndex(of: " ") {
            return String(trimmed[trimmed.startIndex..<lastSpace]).appending("...")
        }
        return String(trimmed).appending("...")
    }

    /// Humanize a system / contractor name that may contain snake_case or
    /// kebab-case subtype slugs. Splits on underscore + hyphen-between-letters,
    /// title-cases each word, and preserves a known set of acronyms so
    /// "boiler_with_central_ac" becomes "Boiler With Central AC" instead of
    /// "Boiler With Central Ac".
    ///
    /// Caught by Round C Waves C-4 REDO + C-9 + C-12 (compound finding):
    /// home_systems.name values like "A4 HVAC subtype boiler_with_central_ac"
    /// and "Crawl Space finished_basement-sump_pump-crawl_space" leaked into
    /// the user-facing UI. Apply this at render time to defensively humanize.
    var humanizedSystemName: String {
        // Known acronyms to upcase after title-casing.
        let acronyms: Set<String> = [
            "Hvac", "Ac", "Ev", "Hoa", "Hvac", "Diy", "Tv", "Llc",
            "Pdf", "Ssn", "Url", "Api", "Pin", "Ftc", "Faq",
        ]
        // Replace underscores + slug-style hyphens-between-letters with spaces.
        // Keep hyphens that look like compound modifiers ("12-month"," " spans).
        var working = self.replacingOccurrences(of: "_", with: " ")
        // Replace hyphen between two lowercase letters with space.
        working = working.replacingOccurrences(
            of: "(?<=[a-z])-(?=[a-z])",
            with: " ",
            options: .regularExpression
        )
        // Collapse multiple spaces.
        working = working.replacingOccurrences(
            of: " {2,}",
            with: " ",
            options: .regularExpression
        )
        // Title-case each word, then upcase known acronyms.
        let parts = working.split(separator: " ").map { word -> String in
            let titled = word.prefix(1).uppercased() + word.dropFirst().lowercased()
            return acronyms.contains(titled) ? titled.uppercased() : titled
        }
        return parts.joined(separator: " ")
    }
}

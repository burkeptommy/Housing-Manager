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
}

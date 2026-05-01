import SwiftUI

/// Side-by-side comparison of all quotes for a project.
/// Shows pricing differences, gaps (items one contractor includes that another doesn't),
/// and identifies the best deal.
struct QuoteComparisonView: View {
    let quotes: [ProjectQuoteRow]
    let projectName: String

    /// All unique line item descriptions across all quotes, normalized.
    private var allLineItems: [String] {
        var seen = Set<String>()
        var items: [String] = []
        for quote in quotes {
            for item in quote.analysis.lineItems ?? [] {
                let desc = item.description ?? ""
                let key = desc.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if !key.isEmpty && seen.insert(key).inserted {
                    items.append(desc)
                }
            }
        }
        return items
    }

    /// Whether all quotes have itemized line items
    private var allQuotesItemized: Bool {
        quotes.allSatisfy { ($0.analysis.lineItems ?? []).count > 1 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing20) {
                summaryCards

                if allQuotesItemized {
                    comparisonTable
                    gapAnalysis
                } else {
                    needItemizedCard
                }

                // Phase 80 — Chez Concierge entry below the comparison.
                // Two quotes is the classic "tiebreaker needed" moment;
                // Tom can grab a third comparable bid + sanity-check the
                // existing two against fair-market data.
                ChezEntryButton(
                    category: .getQuote,
                    label: "Have Chez get a third quote",
                    caption: "Chez finds a comparable pro for a tiebreaker bid and sanity-checks pricing.",
                    context: chezQuoteComparisonContext
                )
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing12)
            .padding(.bottom, 40)
        }
        .background(HavenColors.background)
        .navigationTitle("Compare Quotes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chezQuoteComparisonContext: [String: String] {
        var c: [String: String] = [
            "_source": "quote_comparison",
            "quote_count": String(quotes.count),
        ]
        let names = quotes.compactMap { $0.vendorName }.joined(separator: ", ")
        if !names.isEmpty { c["existing_vendors"] = names }
        let totals = quotes.compactMap { quote -> String? in
            guard let vendor = quote.vendorName,
                  let total = quote.analysis.overallAssessment?.totalQuoted else { return nil }
            return "\(vendor): $\(Int(total))"
        }.joined(separator: " · ")
        if !totals.isEmpty { c["totals"] = totals }
        return c
    }

    // MARK: - Need Itemized Quotes

    private var needItemizedCard: some View {
        HavenCard {
            VStack(spacing: HavenTheme.spacing12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundStyle(HavenColors.warning)

                Text("Itemized Quotes Needed")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)

                Text("To compare quotes line-by-line, both vendors need to provide itemized breakdowns. Ask your contractors for a detailed quote showing each item with its price.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)

                // Show which quotes are missing itemization
                ForEach(quotes) { quote in
                    let hasItems = (quote.analysis.lineItems ?? []).count > 1
                    HStack(spacing: 8) {
                        Image(systemName: hasItems ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(hasItems ? HavenColors.success : HavenColors.critical)
                        Text(quote.vendorName ?? "Contractor")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                        Text(hasItems ? "Itemized" : "Lump sum")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(hasItems ? HavenColors.success : HavenColors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("SUMMARY")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
                .fontWeight(.semibold)
                .tracking(1)

            // Sort quotes by total
            let sorted = quotes.sorted { ($0.quoteTotal ?? .infinity) < ($1.quoteTotal ?? .infinity) }

            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, quote in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(quote.vendorName ?? "Contractor \(index + 1)")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            if index == 0 && sorted.count > 1 {
                                Text("LOWEST")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(HavenColors.success)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(HavenColors.success.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        if let rating = quote.overallRating {
                            ratingBadge(rating)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if let total = quote.quoteTotal {
                            Text("$\(Int(total).formatted())")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        if let fair = quote.estimatedFairTotal {
                            Text("Fair: $\(Int(fair).formatted())")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
                .padding(HavenTheme.spacing12)
                .background(index == 0 ? HavenColors.success.opacity(0.03) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Haven's estimate
            let fairEstimates = quotes.compactMap { $0.estimatedFairTotal }
            if let avgFair = fairEstimates.isEmpty ? nil : fairEstimates.reduce(0, +) / Double(fairEstimates.count) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.checkered")
                            .foregroundStyle(HavenColors.navy700)
                        Text("Chez's Fair Estimate")
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.navy700)
                    }
                    Spacer()
                    Text("~$\(Int(avgFair).formatted())")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.navy700)
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.navy.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Comparison Table

    private var comparisonTable: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("LINE-BY-LINE COMPARISON")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
                .fontWeight(.semibold)
                .tracking(1)

            // Header row
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Column headers
                    HStack(spacing: 0) {
                        Text("Item")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .frame(width: 140, alignment: .leading)

                        ForEach(quotes) { quote in
                            Text(quote.vendorName ?? "Contractor")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(HavenColors.navy700)
                                .frame(width: 90)
                                .lineLimit(1)
                        }

                        Text("Fair Est.")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(HavenColors.navy.opacity(0.6))
                            .frame(width: 80)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(HavenColors.navy.opacity(0.04))

                    // Data rows
                    ForEach(Array(allLineItems.enumerated()), id: \.offset) { _, itemDesc in
                        comparisonRow(itemDesc: itemDesc)
                    }

                    // Totals row
                    HStack(spacing: 0) {
                        Text("TOTAL")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(HavenColors.textPrimary)
                            .frame(width: 140, alignment: .leading)

                        ForEach(quotes) { quote in
                            let total = quote.quoteTotal ?? 0
                            Text("$\(Int(total).formatted())")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(HavenColors.textPrimary)
                                .frame(width: 90)
                        }

                        let fairAvg = quotes.compactMap { $0.estimatedFairTotal }.reduce(0, +) / max(Double(quotes.count), 1)
                        Text("$\(Int(fairAvg).formatted())")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 80)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(HavenColors.navy.opacity(0.06))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(HavenColors.beige300, lineWidth: 1))
        }
    }

    private func comparisonRow(itemDesc: String) -> some View {
        let key = itemDesc.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        return HStack(spacing: 0) {
            Text(itemDesc)
                .font(.system(size: 10))
                .foregroundStyle(HavenColors.textPrimary)
                .frame(width: 140, alignment: .leading)
                .lineLimit(2)

            ForEach(quotes) { quote in
                let match = findItem(key: key, in: quote)
                if let item = match {
                    let price = item.displayPrice ?? item.marketMedianPrice ?? 0
                    Text("$\(Int(price).formatted())")
                        .font(.system(size: 10))
                        .foregroundStyle(HavenColors.textPrimary)
                        .frame(width: 90)
                } else {
                    Text("Not incl.")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(HavenColors.critical.opacity(0.7))
                        .frame(width: 90)
                }
            }

            // Haven's fair estimate (avg across quotes that have this item)
            let fairPrices = quotes.compactMap { q -> Double? in
                findItem(key: key, in: q)?.marketMedianPrice
            }
            if let avg = fairPrices.isEmpty ? nil : fairPrices.reduce(0, +) / Double(fairPrices.count) {
                Text("$\(Int(avg).formatted())")
                    .font(.system(size: 10))
                    .foregroundStyle(HavenColors.navy.opacity(0.6))
                    .frame(width: 80)
            } else {
                Text("—")
                    .font(.system(size: 10))
                    .foregroundStyle(HavenColors.textTertiary)
                    .frame(width: 80)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white)
    }

    private func findItem(key: String, in quote: ProjectQuoteRow) -> QuoteLineItem? {
        (quote.analysis.lineItems ?? []).first { item in
            let desc = (item.description ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return desc == key || desc.contains(key) || key.contains(desc)
        }
    }

    // MARK: - Gap Analysis

    private var gapAnalysis: some View {
        let gaps = findGaps()

        return Group {
            if !gaps.isEmpty {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    Text("SCOPE GAPS")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .fontWeight(.semibold)
                        .tracking(1)

                    Text("Items included by some contractors but not others. Ask missing contractors to clarify whether these are included in their price or excluded from scope.")
                        .font(.system(size: 11))
                        .foregroundStyle(HavenColors.textSecondary)

                    ForEach(Array(gaps.enumerated()), id: \.offset) { _, gap in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(HavenColors.warning)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(gap.itemDescription)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("Included by: \(gap.includedBy.joined(separator: ", "))")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.success)
                                Text("Missing from: \(gap.missingFrom.joined(separator: ", "))")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.critical)
                            }
                        }
                        .padding(HavenTheme.spacing12)
                        .background(HavenColors.warning.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private struct ScopeGap {
        let itemDescription: String
        let includedBy: [String]
        let missingFrom: [String]
    }

    private func findGaps() -> [ScopeGap] {
        guard quotes.count >= 2 else { return [] }
        var gaps: [ScopeGap] = []

        for itemDesc in allLineItems {
            let key = itemDesc.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            var included: [String] = []
            var missing: [String] = []

            for quote in quotes {
                let name = quote.vendorName ?? "Contractor"
                if findItem(key: key, in: quote) != nil {
                    included.append(name)
                } else {
                    missing.append(name)
                }
            }

            if !missing.isEmpty && !included.isEmpty {
                gaps.append(ScopeGap(itemDescription: itemDesc, includedBy: included, missingFrom: missing))
            }
        }
        return gaps
    }

    // MARK: - Helpers

    private func ratingBadge(_ rating: String) -> some View {
        let (label, color): (String, Color) = {
            switch rating.lowercased() {
            case "good_deal": return ("Good Deal", HavenColors.success)
            case "overpriced": return ("Overpriced", HavenColors.critical)
            default: return ("Fair", HavenColors.warning)
            }
        }()

        return Text(label)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

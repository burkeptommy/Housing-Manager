import SwiftUI

/// Displays a saved quote's full analysis — vendor, line items, ratings, negotiation tips.
struct QuoteDetailView: View {
    let quote: ProjectQuoteRow
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss

    private var analysis: QuoteAnalysis { quote.analysis }

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing20) {
                vendorCard
                overallAssessmentCard
                lineItemsSection
                if let diy = analysis.suggestedDiyAlternative, diy.feasible == true {
                    diyAlternativeCard(diy)
                }
                negotiationTipsSection
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing12)
            .padding(.bottom, 40)
        }
        .background(HavenColors.background)
        .navigationTitle(quote.vendorName ?? "Quote Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Menu {
                    Button(role: .destructive) {
                        Task {
                            try? await viewModel.deleteQuote(id: quote.id)
                            dismiss()
                        }
                    } label: {
                        Label("Delete Quote", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(HavenColors.navy700)
                }
            }
        }
    }

    // MARK: - Vendor Card

    private var vendorCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            if let name = analysis.vendor?.name {
                Text(name)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.navy800)
            }

            let details = [analysis.vendor?.phone, analysis.vendor?.email, analysis.vendor?.address].compactMap { $0 }
            ForEach(details, id: \.self) { detail in
                Text(detail)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            if let license = analysis.vendor?.license {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundStyle(HavenColors.success)
                    Text("License: \(license)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            if let date = quote.quoteDate {
                Text("Quote date: \(date)")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Overall Assessment

    private var overallAssessmentCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            if let rating = analysis.overallAssessment?.rating {
                ratingBadge(rating)
            }

            if let summary = analysis.overallAssessment?.summary {
                Text(summary)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
            }

            HStack(spacing: HavenTheme.spacing24) {
                costColumn(label: "Quoted", value: analysis.overallAssessment?.totalQuoted)
                costColumn(label: "Fair Estimate", value: analysis.overallAssessment?.estimatedFairTotal)
                if let savings = analysis.overallAssessment?.potentialSavings, savings > 0 {
                    costColumn(label: "Potential Savings", value: savings, color: HavenColors.success)
                }
            }

            if let materials = analysis.overallAssessment?.estimatedMaterials,
               let labor = analysis.overallAssessment?.estimatedLabor {
                HStack(spacing: HavenTheme.spacing16) {
                    HStack(spacing: 4) {
                        Circle().fill(HavenColors.navy.opacity(0.3)).frame(width: 8, height: 8)
                        Text("Materials: $\(Int(materials).formatted())")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(HavenColors.navy).frame(width: 8, height: 8)
                        Text("Labor: $\(Int(labor).formatted())")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func costColumn(label: String, value: Double?, color: Color = HavenColors.navy800) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
            if let v = value {
                Text("$\(Int(v).formatted())")
                    .font(HavenTypography.headline)
                    .foregroundStyle(color)
            } else {
                Text("—")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    // MARK: - Line Items

    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("LINE ITEMS (\(analysis.lineItems?.count ?? 0))")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
                .fontWeight(.semibold)
                .tracking(1)

            ForEach(analysis.lineItems ?? []) { item in
                lineItemRow(item)
            }
        }
    }

    private func lineItemRow(_ item: QuoteLineItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.description ?? "Unknown item")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                if let rating = item.rating {
                    ratingBadge(rating)
                }
            }

            // Local price range bar
            if let range = item.localPriceRange, let low = range.low, let high = range.high, high > low {
                localRangeBar(item: item, low: low, high: high, countyName: range.countyName, costIndex: range.costIndex)
            } else {
                // Fallback to simple stats if no range data
                HStack(spacing: HavenTheme.spacing16) {
                    if let materials = item.estimatedMaterialsCost {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Materials")
                                .font(.system(size: 9))
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("$\(Int(materials).formatted())")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    if let labor = item.estimatedLaborCost {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Labor")
                                .font(.system(size: 9))
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("$\(Int(labor).formatted())")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    if let fair = item.marketMedianPrice {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Fair Price")
                                .font(.system(size: 9))
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("$\(Int(fair).formatted())")
                                .font(HavenTypography.uiCaption)
                                .fontWeight(.semibold)
                                .foregroundStyle(HavenColors.navy700)
                        }
                    }
                }
            }

            if let reason = item.ratingReason, !reason.isEmpty {
                Text(reason)
                    .font(.system(size: 11))
                    .foregroundStyle(HavenColors.textTertiary)
                    .lineLimit(3)
            }
        }
        .padding(HavenTheme.spacing12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - DIY Alternative

    private func diyAlternativeCard(_ diy: QuoteDiyAlternative) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundStyle(HavenColors.navy700)
                Text("DIY Alternative")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.navy800)
            }

            if let cost = diy.estimatedDiyCost {
                Text("Estimated DIY cost: $\(Int(cost).formatted())")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.success)
            }

            if let notes = diy.notes {
                Text(notes)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(HavenColors.success.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Negotiation Tips

    private var negotiationTipsSection: some View {
        let tips = analysis.overallAssessment?.negotiationTips ?? []
        return Group {
            if !tips.isEmpty {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    Text("NEGOTIATION TIPS")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .fontWeight(.semibold)
                        .tracking(1)

                    ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(HavenColors.warning)
                            Text(tip)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        .padding(HavenTheme.spacing12)
                        .background(HavenColors.warning.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Visual range bar showing where the quoted price falls within the local county range.
    private func localRangeBar(item: QuoteLineItem, low: Double, high: Double, countyName: String?, costIndex: String?) -> some View {
        let quoted = item.displayPrice
        let fair = item.marketMedianPrice

        return VStack(alignment: .leading, spacing: 6) {
            // County label with cost index
            HStack(spacing: 4) {
                if let county = countyName {
                    Text(county)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                if let idx = costIndex {
                    let idxLabel = switch idx {
                    case "very_high": "Very High Cost Area"
                    case "high": "High Cost Area"
                    case "low": "Low Cost Area"
                    default: ""
                    }
                    if !idxLabel.isEmpty {
                        Text("·")
                            .font(.system(size: 9))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(idxLabel)
                            .font(.system(size: 9))
                            .foregroundStyle(idx == "very_high" || idx == "high" ? HavenColors.warning : HavenColors.success)
                    }
                }
            }

            // Range numbers above bar
            HStack {
                Text("$\(Int(low).formatted())")
                    .font(.system(size: 10))
                    .foregroundStyle(HavenColors.success)
                Spacer()
                if let f = fair {
                    Text("Fair: $\(Int(f).formatted())")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                }
                Spacer()
                Text("$\(Int(high).formatted())")
                    .font(.system(size: 10))
                    .foregroundStyle(HavenColors.critical)
            }

            // The bar
            GeometryReader { geo in
                let barWidth = geo.size.width
                let range = high - low

                ZStack(alignment: .leading) {
                    // Gradient background bar
                    LinearGradient(
                        colors: [HavenColors.success.opacity(0.3), HavenColors.warning.opacity(0.3), HavenColors.critical.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .clipShape(Capsule())

                    // Fair price marker (thin line)
                    if let f = fair, range > 0 {
                        let fairPos = max(0, min(barWidth, CGFloat((f - low) / range) * barWidth))
                        Rectangle()
                            .fill(HavenColors.navy700)
                            .frame(width: 2, height: 14)
                            .offset(x: fairPos - 1)
                    }

                    // Quoted price marker (dot)
                    if let q = quoted, range > 0 {
                        let pos = max(0, min(barWidth - 12, CGFloat((q - low) / range) * barWidth - 6))
                        Circle()
                            .fill(q > high ? HavenColors.critical : q < low ? HavenColors.success : HavenColors.navy700)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .offset(x: pos)
                    }
                }
            }
            .frame(height: 14)

            // Quoted price label below
            if let q = quoted {
                HStack(spacing: 4) {
                    Text("Quoted:")
                        .font(.system(size: 10))
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("$\(Int(q).formatted())")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(q > high ? HavenColors.critical : q < low ? HavenColors.success : HavenColors.textPrimary)
                    if q > high {
                        Text("above range")
                            .font(.system(size: 9))
                            .foregroundStyle(HavenColors.critical)
                    } else if q < low {
                        Text("below range")
                            .font(.system(size: 9))
                            .foregroundStyle(HavenColors.success)
                    }
                }
            }
        }
    }

    private func ratingBadge(_ rating: String) -> some View {
        let (label, color): (String, Color) = {
            switch rating.lowercased() {
            case "good_deal": return ("Good Deal", HavenColors.success)
            case "overpriced": return ("Overpriced", HavenColors.critical)
            default: return ("Fair", HavenColors.warning)
            }
        }()

        return Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

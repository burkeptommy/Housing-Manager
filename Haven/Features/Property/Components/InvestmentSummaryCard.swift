import SwiftUI

/// Investment summary dashboard for a property's Overview tab.
/// Shows estimated value hero, stacked investment bar, expandable waterfall breakdown,
/// and a "What if I sold for..." sale simulator. Renders an editable empty state
/// when purchase price and/or estimated value are missing.
struct InvestmentSummaryCard: View {
    let property: PropertyRow
    let totalProjectSpend: Double
    var onValuesUpdated: ((PropertyUpdate) async -> Void)? = nil

    @State private var showBreakdown = false
    @State private var showSaleSimulator = false
    @State private var sheetMode: PurchasePriceInputSheet.Mode?

    // Computed values
    private var purchasePrice: Double { property.purchasePrice ?? 0 }
    private var estimatedValue: Double { property.currentEstimatedValue ?? 0 }
    private var totalInvested: Double { purchasePrice + totalProjectSpend }
    private var sellingCosts: Double { estimatedValue * 0.08 }
    private var netAfterSale: Double { estimatedValue - sellingCosts }
    private var gainLoss: Double { netAfterSale - totalInvested }
    private var gainLossPercent: Double { totalInvested > 0 ? (gainLoss / totalInvested) : 0 }
    private var hasEstimatedValue: Bool { property.currentEstimatedValue != nil && estimatedValue > 0 }
    private var hasPurchasePrice: Bool { property.purchasePrice != nil && purchasePrice > 0 }

    /// Phase 16e — surface *why* the estimated value looks the way it does for
    /// the lower-confidence fallback paths. ATTOM/RentCast values speak for
    /// themselves; the computed and square-footage paths need a soft reminder
    /// so the user knows it's a directional number, not an appraisal.
    private var estimatedValueSourceCaption: String? {
        switch property.estimatedValueSource {
        case "computed":
            return "Estimated from last sale, adjusted for time"
        case "estimated":
            return "Based on square footage average"
        case "rentcast":
            return "From public market data"
        case "manual":
            return "You set this value"
        default:
            return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("INVESTMENT SUMMARY")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            HavenCard {
                VStack(spacing: HavenTheme.spacing12) {
                    heroSection
                    if hasPurchasePrice {
                        stackedBarSection
                        if hasEstimatedValue {
                            bottomSummary
                        }
                        expandToggle

                        if showBreakdown {
                            waterfallBreakdown
                        }

                        saleSimulatorButton
                    } else {
                        addPurchasePricePrompt
                    }
                }
            }
        }
        .sheet(isPresented: $showSaleSimulator) {
            SaleSimulatorSheet(property: property, totalProjectSpend: totalProjectSpend)
        }
        .sheet(item: $sheetMode) { mode in
            PurchasePriceInputSheet(mode: mode, property: property) { update in
                await onValuesUpdated?(update)
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text("Estimated value")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textSecondary)

                if hasEstimatedValue {
                    Button {
                        Haptics.light()
                        sheetMode = .estimatedValue
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                    }
                    .buttonStyle(.plain)
                }
            }

            if hasEstimatedValue {
                Text(estimatedValue.formattedCompactCurrency())
                    .font(.custom("Georgia", size: 26).weight(.bold))
                    .foregroundStyle(HavenColors.textPrimary)

                if let caption = estimatedValueSourceCaption {
                    Text(caption)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .multilineTextAlignment(.center)
                }

                if totalInvested > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: gainLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10))
                            .foregroundStyle(gainLoss >= 0 ? HavenColors.success : HavenColors.critical)
                        Text(String(format: "%+.1f%%", gainLossPercent * 100))
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(gainLoss >= 0 ? HavenColors.success : HavenColors.critical)
                        Text("vs. total invested")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            } else {
                Button {
                    Haptics.light()
                    sheetMode = .estimatedValue
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add estimated value")
                            .font(HavenTypography.uiButton)
                    }
                    .foregroundStyle(HavenColors.navy800)
                    .padding(.horizontal, HavenTheme.spacing16)
                    .padding(.vertical, HavenTheme.spacing8)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
    }

    // MARK: - Add Purchase Price Prompt (empty state)

    private var addPurchasePricePrompt: some View {
        VStack(spacing: HavenTheme.spacing12) {
            Text("Track your investment")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)

            Text("Add what you paid to unlock gain/loss tracking, the sale simulator, and your investment dashboard.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HavenTheme.spacing12)

            Button {
                Haptics.light()
                sheetMode = .purchasePrice
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add purchase price")
                        .font(HavenTypography.uiButton)
                }
                .foregroundStyle(HavenColors.textOnNavy)
                .padding(.horizontal, HavenTheme.spacing16)
                .padding(.vertical, HavenTheme.spacing12)
                .background(HavenColors.navy800)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing16)
    }

    // MARK: - Stacked Bar

    private var stackedBarSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Total invested")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Text(formatCurrency(totalInvested))
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textPrimary)
            }

            if totalInvested > 0 {
                GeometryReader { geo in
                    let width = geo.size.width
                    let purchaseFrac = purchasePrice / totalInvested
                    let projectFrac = totalProjectSpend / totalInvested
                    let gapFrac = hasEstimatedValue ? min(abs(gainLoss) / totalInvested, max(0, 1 - purchaseFrac - projectFrac)) : 0

                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(HavenColors.success)
                            .frame(width: width * purchaseFrac)
                        if totalProjectSpend > 0 {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(HavenColors.success.opacity(0.4))
                                .frame(width: width * projectFrac)
                        }
                        if hasEstimatedValue && gapFrac > 0 {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(gainLoss >= 0 ? HavenColors.success.opacity(0.3) : HavenColors.critical.opacity(0.3))
                                .frame(width: width * gapFrac)
                        }
                    }
                    .frame(height: 24)
                    .background(HavenColors.beige200)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                }
                .frame(height: 24)

                // Legend
                HStack(spacing: HavenTheme.spacing12) {
                    legendItem(color: HavenColors.success, label: "Purchase \(formatCurrencyCompact(purchasePrice))")
                    if totalProjectSpend > 0 {
                        legendItem(color: HavenColors.success.opacity(0.4), label: "Projects \(formatCurrencyCompact(totalProjectSpend))")
                    }
                    if hasEstimatedValue {
                        legendItem(
                            color: gainLoss >= 0 ? HavenColors.success.opacity(0.3) : HavenColors.critical.opacity(0.3),
                            label: gainLoss >= 0 ? "Surplus \(formatCurrencyCompact(abs(gainLoss)))" : "Gap \(formatCurrencyCompact(abs(gainLoss)))"
                        )
                    }
                }
            }
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    // MARK: - Bottom Summary

    private var bottomSummary: some View {
        VStack(spacing: HavenTheme.spacing8) {
            Divider().overlay(HavenColors.beige200)

            HStack {
                HStack(spacing: 2) {
                    Text("Net after sale")
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.textSecondary)
                    Text("(8% fees)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                Spacer()
                Text(formatCurrency(netAfterSale))
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textPrimary)
            }

            HStack {
                Text(gainLoss >= 0 ? "Unrealized gain" : "Unrealized loss")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Text(formatCurrency(abs(gainLoss)))
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(gainLoss >= 0 ? HavenColors.success : HavenColors.critical)
            }
        }
    }

    // MARK: - Expand Toggle

    private var expandToggle: some View {
        HStack(spacing: 4) {
            Text(showBreakdown ? "Hide breakdown" : "See breakdown")
                .font(HavenTypography.uiCaption)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .semibold))
                .rotationEffect(.degrees(showBreakdown ? 180 : 0))
        }
        .foregroundStyle(HavenColors.textTertiary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showBreakdown.toggle()
            }
            Haptics.light()
            Analytics.track(.investmentBreakdownToggled, ["expanded": showBreakdown])
        }
    }

    // MARK: - Waterfall Breakdown

    private var waterfallBreakdown: some View {
        VStack(spacing: 0) {
            flowItem(label: "Purchase price", value: formatCurrency(purchasePrice), barColor: HavenColors.success)

            if totalProjectSpend > 0 {
                dashedConnector
                flowItem(label: "+ Project spend", value: formatCurrency(totalProjectSpend), barColor: HavenColors.success.opacity(0.5))
            }

            dashedConnector
            subtotalPill(label: "Total invested", value: formatCurrency(totalInvested))

            if hasEstimatedValue {
                dashedConnector
                flowItem(label: "Estimated value", value: formatCurrency(estimatedValue), barColor: HavenColors.info)

                dashedConnector
                flowItem(label: "- Selling costs (8%)", value: "-\(formatCurrency(sellingCosts))", barColor: HavenColors.textTertiary)

                dashedConnector
                resultCard
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func flowItem(label: String, value: String, barColor: Color) -> some View {
        HStack(spacing: HavenTheme.spacing8) {
            RoundedRectangle(cornerRadius: HavenTheme.radiusSmall)
                .fill(barColor)
                .frame(width: 3, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(value)
                    .font(.custom("Georgia", size: 16).weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
            }
            Spacer()
        }
    }

    private var dashedConnector: some View {
        HStack {
            Rectangle()
                .fill(HavenColors.beige300)
                .frame(width: 1, height: 8)
                .padding(.leading, 1)
            Spacer()
        }
    }

    private func subtotalPill(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.uiLabelMedium)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(HavenTypography.uiLabelMedium)
                .foregroundStyle(HavenColors.textPrimary)
        }
        .padding(HavenTheme.spacing8)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
    }

    private var resultCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Net after sale")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(formatCurrency(netAfterSale))
                    .font(.custom("Georgia", size: 16).weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(gainLoss >= 0 ? "Unrealized gain" : "Unrealized loss")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(formatCurrency(abs(gainLoss)))
                    .font(.custom("Georgia", size: 16).weight(.semibold))
                    .foregroundStyle(gainLoss >= 0 ? HavenColors.success : HavenColors.critical)
            }
        }
        .padding(HavenTheme.spacing12)
        .background((gainLoss >= 0 ? HavenColors.success : HavenColors.critical).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
    }

    // MARK: - Sale Simulator Button

    private var saleSimulatorButton: some View {
        Button {
            showSaleSimulator = true
            Analytics.track(.saleSimulatorOpened, ["property_id": property.id.uuidString])
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                Text("What if I sold for...")
                    .font(HavenTypography.uiLabel)
            }
            .foregroundStyle(HavenColors.navy700)
            .frame(maxWidth: .infinity)
            .padding(.vertical, HavenTheme.spacing12)
            .background(HavenColors.navy.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Formatting

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    private func formatCurrencyCompact(_ value: Double) -> String {
        value.formattedCompactCurrency()
    }
}

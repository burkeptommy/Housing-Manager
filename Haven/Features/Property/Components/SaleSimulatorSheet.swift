import SwiftUI

/// "What if I sold for..." interactive sale price simulator.
struct SaleSimulatorSheet: View {
    let property: PropertyRow
    let totalProjectSpend: Double
    @Environment(\.dismiss) private var dismiss

    @State private var salePrice: Double
    @State private var feeRate: Double

    init(property: PropertyRow, totalProjectSpend: Double) {
        self.property = property
        self.totalProjectSpend = totalProjectSpend
        _salePrice = State(initialValue: property.currentEstimatedValue ?? property.purchasePrice ?? 0)
        // Phase 95 — initialize from persisted attribute (set last time the
        // user moved the slider). Falls back to the historical 8% default.
        let persisted = property.attributes?["selling_fee_rate"]?.stringValue
        let parsed = persisted.flatMap(Double.init)
        _feeRate = State(initialValue: parsed ?? 0.08)
    }

    // Computed in realtime
    private var sellingCosts: Double { salePrice * feeRate }
    private var netProceeds: Double { salePrice - sellingCosts }
    private var totalInvested: Double { (property.purchasePrice ?? 0) + totalProjectSpend }
    private var gainLoss: Double { netProceeds - totalInvested }
    private var gainLossPercent: Double { totalInvested > 0 ? (gainLoss / totalInvested) : 0 }
    /// Capital gains uses cost basis = purchase price + project spend (capital improvements).
    /// This is the IRS-style calculation for a primary residence with documented improvements.
    private var capitalGains: Double { salePrice - totalInvested }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                    // 1. Sale price input
                    salePriceInput

                    // 2. Fee adjustment
                    feeAdjustment

                    // 3. Results card
                    resultsCard

                    // 4. Capital gains note
                    if capitalGains > 0 {
                        capitalGainsNote
                    }

                    // 5. Disclaimer
                    Text("This is an estimate for planning purposes only. It does not account for mortgage payoff, taxes, or other obligations. Consult your financial advisor before making decisions.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, HavenTheme.spacing16)
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.cream)
            .navigationTitle("Sale Simulator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sale Price Input

    private var salePriceInput: some View {
        VStack(spacing: HavenTheme.spacing8) {
            Text("What would you sell for?")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)

            TextField("$0", value: $salePrice, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(HavenTypography.fraunces(size: 32, weight: 700))
                .foregroundStyle(HavenColors.textPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)

            if let est = property.currentEstimatedValue, est > 0 {
                Text("Current estimate: \(formatCurrency(est))")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Fee Adjustment

    private var feeAdjustment: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Selling costs")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)

            HStack {
                Slider(value: $feeRate, in: 0.03...0.12, step: 0.005)
                    .tint(HavenColors.navy)
                Text(String(format: "%.1f%%", feeRate * 100))
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(width: 44)
            }
            .onChange(of: feeRate) { _, newValue in
                // Phase 95 — persist on every step so the InvestmentSummaryCard
                // waterfall reflects the user's negotiated rate next time
                // they open the property. Fire-and-forget; the card already
                // defaults to 8% if the attribute is missing or malformed.
                Task {
                    _ = try? await DatabaseService.shared.updatePropertyAttribute(
                        propertyId: property.id,
                        key: "selling_fee_rate",
                        value: FlexibleValue.string(String(format: "%.4f", newValue))
                    )
                }
            }

            Text("Typical: 5-6% (agent), 1-3% (FSBO), 8-10% (with repairs/staging). Saved for this property.")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    // MARK: - Results Card

    private var resultsCard: some View {
        HavenCard {
            VStack(spacing: HavenTheme.spacing12) {
                // Hero result
                VStack(spacing: 4) {
                    Text("Net proceeds")
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.textSecondary)
                    Text(formatCurrency(netProceeds))
                        .font(HavenTypography.largeTitle)
                        .foregroundStyle(netProceeds >= 0 ? HavenColors.success : HavenColors.critical)

                    // Gain/loss badge
                    HStack(spacing: 4) {
                        Text(String(format: "%+.1f%%", gainLossPercent * 100))
                        Text(gainLoss >= 0 ? "gain" : "loss")
                    }
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(gainLoss >= 0 ? HavenColors.success : HavenColors.critical)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((gainLoss >= 0 ? HavenColors.success : HavenColors.critical).opacity(0.1))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)

                Divider().overlay(HavenColors.beige200)

                // Breakdown rows
                breakdownRow(label: "Sale price", value: formatCurrency(salePrice))
                breakdownRow(label: "Selling costs (\(String(format: "%.1f", feeRate * 100))%)", value: "-\(formatCurrency(sellingCosts))", valueColor: HavenColors.textSecondary)
                breakdownRow(label: "Net proceeds", value: formatCurrency(netProceeds), bold: true)

                Divider().overlay(HavenColors.beige200)

                breakdownRow(label: "Total invested", value: formatCurrency(totalInvested))
                breakdownRow(
                    label: gainLoss >= 0 ? "Gain" : "Loss",
                    value: formatCurrency(abs(gainLoss)),
                    valueColor: gainLoss >= 0 ? HavenColors.success : HavenColors.critical,
                    bold: true
                )
            }
        }
    }

    private func breakdownRow(label: String, value: String, valueColor: Color = HavenColors.textPrimary, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(bold ? HavenTypography.uiLabel : HavenTypography.uiLabelMedium)
                .fontWeight(bold ? .semibold : .regular)
                .foregroundStyle(valueColor)
        }
    }

    // MARK: - Capital Gains Note

    private var capitalGainsNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(HavenColors.info)
            Text("Estimated capital gain: \(formatCurrency(capitalGains)) (sale price minus cost basis of \(formatCurrency(totalInvested)), which includes purchase price + documented improvements). Primary residence exclusions may apply ($250K single / $500K married). Consult your tax advisor.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.info.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
    }

    // MARK: - Formatting

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

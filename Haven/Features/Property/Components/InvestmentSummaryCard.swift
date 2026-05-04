import SwiftUI

/// Investment summary dashboard for a property's Overview tab.
/// Shows estimated value hero, stacked investment bar, expandable waterfall breakdown,
/// and a "What if I sold for..." sale simulator. Renders an editable empty state
/// when purchase price and/or estimated value are missing.
struct InvestmentSummaryCard: View {
    let property: PropertyRow
    let totalProjectSpend: Double
    /// Phase 95 (gap #50) — estimated spend on in-flight projects
    /// (planning / in_progress with budget but no actualSpend).
    /// Surfaces in the waterfall as a secondary line so users
    /// see the FULL picture, not just completed projects. Defaults
    /// 0 so existing callers compile without change.
    var inFlightProjectSpend: Double = 0
    var onValuesUpdated: ((PropertyUpdate) async -> Void)? = nil
    /// Build 84 — async callback wired to
    /// `PropertyDetailViewModel.refreshFromPublicRecords` so the empty-state
    /// "Refresh from public records" button can re-fire the ATTOM lookup
    /// and walk the same fallback ladder Onboarding uses. Optional so the
    /// button hides cleanly when no callback is provided (preview, etc.).
    var onRefreshFromPublicRecords: (() async -> Void)? = nil

    @State private var showBreakdown = false
    @State private var showSaleSimulator = false
    @State private var sheetMode: PurchasePriceInputSheet.Mode?
    /// Phase 18g — when the source is `ai_comps`, tapping the info icon
    /// beneath the value reveals Claude's reasoning paragraph in a sheet.
    @State private var showAIReasoning = false
    /// Build 84 — drives the inline loading state on the "Refresh from
    /// public records" empty-state button while the ATTOM lookup is in flight.
    @State private var isRefreshingPublicRecords: Bool = false

    // Computed values
    private var purchasePrice: Double { property.purchasePrice ?? 0 }

    /// Phase 20d / Build 88 — optimistic valuation range kept for the
    /// informational "Range: $X to $Y" caption beneath the hero, but no
    /// longer drives either the hero number or the math. Before Build 88
    /// the hero rendered `range.high`, the waterfall/gain-loss math used
    /// `range.midpoint`, and the Property hero card above this component
    /// showed raw `property.currentEstimatedValue` — three different
    /// numbers for the same field on the same screen, which was a trust
    /// killer. Build 88 pins every value on this card to the property's
    /// canonical `currentEstimatedValue` so all three locations agree.
    private var valuationRange: ValuationRange? {
        ValuationRange.compute(for: property)
    }

    /// The number Haven shows as the headline. Build 88: pinned to the
    /// canonical `property.currentEstimatedValue` so it matches the
    /// Property hero card above and the waterfall breakdown below.
    private var heroValue: Double {
        property.currentEstimatedValue ?? 0
    }

    /// The number Haven uses for math (gain/loss, sale simulator, waterfall).
    /// Build 88: pinned to the canonical `property.currentEstimatedValue` so
    /// the hero, waterfall, net-after-sale, and gain/loss calculations all
    /// share one baseline.
    private var estimatedValue: Double {
        property.currentEstimatedValue ?? 0
    }

    private var totalInvested: Double { purchasePrice + totalProjectSpend }
    /// Phase 95 — selling-fee rate is read from `properties.attributes`
    /// when the user has set one in `SaleSimulatorSheet`, otherwise
    /// defaults to 8% (the historical national average). Westchester /
    /// Fairfield negotiate down to 5–6% routinely; making this editable
    /// + persisted unblocks honest math.
    private var sellingFeeRate: Double {
        guard let raw = property.attributes?["selling_fee_rate"]?.stringValue,
              let rate = Double(raw),
              rate > 0, rate < 1 else { return 0.08 }
        return rate
    }
    private var sellingCosts: Double { estimatedValue * sellingFeeRate }
    private var netAfterSale: Double { estimatedValue - sellingCosts }
    private var gainLoss: Double { netAfterSale - totalInvested }
    private var gainLossPercent: Double { totalInvested > 0 ? (gainLoss / totalInvested) : 0 }
    private var hasEstimatedValue: Bool { property.currentEstimatedValue != nil && estimatedValue > 0 }
    private var hasPurchasePrice: Bool { property.purchasePrice != nil && purchasePrice > 0 }

    /// Phase 16e + 18g — surface *why* the estimated value looks the way it
    /// does for the fallback paths. ATTOM values speak for themselves; the
    /// other paths need a soft reminder so the user knows it's a
    /// directional number, not an appraisal. The AI comps path also gets a
    /// tappable info icon next to the caption that reveals Claude's full
    /// reasoning paragraph.
    private var estimatedValueSourceCaption: String? {
        switch property.estimatedValueSource {
        case "ai_comps":
            return "AI estimate from recent comps"
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

    private var hasAIReasoning: Bool {
        property.estimatedValueSource == "ai_comps"
            && (property.estimatedValueReasoning?.isEmpty == false)
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

                        // Build 84 — protected-equity upsell. Anchors the
                        // 7.4% maintenance premium to the user's actual
                        // estimated value so every visit reinforces the
                        // "maintained homes hold value" pitch. Only renders
                        // when we have a value to multiply by.
                        if hasEstimatedValue {
                            equityUpsellCard
                                .padding(.top, HavenTheme.spacing16)
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
        // Phase 18g — Claude reasoning detail sheet for the ai_comps source.
        .sheet(isPresented: $showAIReasoning) {
            aiReasoningSheet
        }
    }

    // Phase 18g — sheet that explains how the AI value was derived. Shows
    // the value, range, confidence, and Claude's full methodology paragraph.
    private var aiReasoningSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
                        Text("Estimated value")
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(estimatedValue.formattedCompactCurrency())
                            .font(HavenTypography.largeTitle)
                            .foregroundStyle(HavenColors.textPrimary)
                        if let confidence = property.estimatedValueConfidence {
                            Text("Confidence: \(confidence)/100")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    Divider().overlay(HavenColors.beige300)

                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        Text("HOW WE GOT THIS NUMBER")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(property.estimatedValueReasoning ?? "")
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text("This is an AI estimate based on recent comparable sales in your area. It is not an appraisal and should not be used for legal, tax, or insurance purposes. For an exact value, consult a licensed real estate appraiser.")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .padding(.top, HavenTheme.spacing8)
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("AI Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showAIReasoning = false }
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
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
                // Phase 20d — show the optimistic high end as the hero
                // anchor with a compact range caption beneath. Manual
                // overrides display the single value with no range.
                Text(heroValue.formattedCompactCurrency())
                    .font(HavenTypography.fraunces(size: 26, weight: 700))
                    .foregroundStyle(HavenColors.textPrimary)

                if let range = valuationRange, !range.isManual {
                    Text("Range: \(range.formattedCompactRange)")
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.textSecondary)

                    Text("Range based on comparable sales and public market data.")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let caption = estimatedValueSourceCaption {
                    HStack(spacing: 4) {
                        Text(caption)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .multilineTextAlignment(.center)
                        // Phase 18g — info icon reveals Claude's reasoning
                        // paragraph for the ai_comps source. Other sources
                        // don't need it because their captions speak for
                        // themselves.
                        if hasAIReasoning {
                            Button {
                                Haptics.light()
                                showAIReasoning = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 11))
                                    .foregroundStyle(HavenColors.navy700)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    // Phase 95 — confidence chip directly under the source
                    // caption so the user reads value + confidence together.
                    // Previously confidence only showed inside the AI
                    // reasoning sheet (one tap removed).
                    if let confidence = property.estimatedValueConfidence {
                        Text("\(confidence)% confidence")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(confidenceColor(for: confidence))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(confidenceColor(for: confidence).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if totalInvested > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: gainLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10))
                            .foregroundStyle(gainLoss >= 0 ? HavenColors.success : HavenColors.critical)
                        Text(String(format: "%+.1f%%", gainLossPercent * 100))
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("vs. total invested")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            } else {
                VStack(spacing: HavenTheme.spacing8) {
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
                        .foregroundStyle(HavenColors.textPrimary)
                        .padding(.horizontal, HavenTheme.spacing16)
                        .padding(.vertical, HavenTheme.spacing8)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    // Build 84 — re-fires the ATTOM lookup and walks the
                    // fallback ladder so users whose property row was created
                    // before the Build 84 ladder landed (or where ATTOM only
                    // returned a range without a canonical value) can recover
                    // without re-onboarding. Hidden when no callback is wired.
                    if onRefreshFromPublicRecords != nil {
                        Button {
                            Haptics.light()
                            Task {
                                isRefreshingPublicRecords = true
                                await onRefreshFromPublicRecords?()
                                isRefreshingPublicRecords = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if isRefreshingPublicRecords {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(HavenColors.navy700)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                Text(isRefreshingPublicRecords ? "Refreshing..." : "Refresh from public records")
                                    .font(HavenTypography.uiCaption)
                            }
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, HavenTheme.spacing12)
                            .padding(.vertical, HavenTheme.spacing4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isRefreshingPublicRecords)
                    }
                }
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
                            .fill(HavenColors.navy800)
                            .frame(width: width * purchaseFrac)
                        if totalProjectSpend > 0 {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(HavenColors.navy800.opacity(0.4))
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
                    legendItem(color: HavenColors.navy800, label: "Purchase \(formatCurrencyCompact(purchasePrice))")
                    if totalProjectSpend > 0 {
                        legendItem(color: HavenColors.navy800.opacity(0.4), label: "Projects \(formatCurrencyCompact(totalProjectSpend))")
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
                    .foregroundStyle(HavenColors.textPrimary)
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
            flowItem(label: "Purchase price", value: formatCurrency(purchasePrice), barColor: HavenColors.navy800)

            if totalProjectSpend > 0 {
                dashedConnector
                flowItem(label: "+ Project spend", value: formatCurrency(totalProjectSpend), barColor: HavenColors.navy800.opacity(0.5))
            }

            // Phase 95 (gap #50) — in-flight project estimates as a
            // secondary line. Excluded from `totalInvested` because
            // budgets aren't actual spend yet, but the homeowner
            // wants to see what's coming. Color-tinted differently
            // (warning amber) so it reads as "estimated" not
            // "actual."
            if inFlightProjectSpend > 0 {
                dashedConnector
                flowItem(
                    label: "+ In-flight estimates",
                    value: formatCurrency(inFlightProjectSpend),
                    barColor: HavenColors.warning.opacity(0.6)
                )
            }

            dashedConnector
            subtotalPill(label: "Total invested", value: formatCurrency(totalInvested))

            if hasEstimatedValue {
                dashedConnector
                flowItem(label: "Estimated value", value: formatCurrency(estimatedValue), barColor: HavenColors.info)

                dashedConnector
                flowItem(label: "- Selling costs (\(String(format: "%.1f%%", sellingFeeRate * 100)))", value: "-\(formatCurrency(sellingCosts))", barColor: HavenColors.textTertiary)

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
                    .font(HavenTypography.title3)
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
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(gainLoss >= 0 ? "Unrealized gain" : "Unrealized loss")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(formatCurrency(abs(gainLoss)))
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.navy.opacity(0.06))
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

    // MARK: - Equity Upsell (Build 84)

    /// Inline navy-gradient sub-card that anchors the 7.4% NAR Remodeling
    /// Impact Report stat to the user's actual estimated value. Sourced
    /// from `HookContent.Page1.equityHeadline` / `equityCitation` so the
    /// copy stays in sync with the PropertyHook hero card the user saw at
    /// onboarding. Only renders when `hasEstimatedValue == true` (otherwise
    /// the multiplication has nothing to anchor to).
    private var equityUpsellCard: some View {
        let equityProtected = estimatedValue * 0.074
        let formattedEquity = formatCurrencyCompact(equityProtected)

        return VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: 6) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.creamLight)
                Text("PROTECTED EQUITY")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.4)
                    .foregroundStyle(HavenColors.creamLight)
            }

            Text(HookContent.Page1.equityHeadline)
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.creamLight)
                .fixedSize(horizontal: false, vertical: true)

            Text("At your estimated value, that's about \(formattedEquity) in equity Chez helps you protect.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.creamLight.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            Text(HookContent.Page1.equityCitation)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.creamLight.opacity(0.6))
        }
        .padding(HavenTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [HavenColors.navy800, HavenColors.navy700],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .havenShadow(HavenTheme.shadowElevated)
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

    /// Phase 95 — confidence chip color tiers. ≥80 reads as solid
    /// (greenish), 60–79 as nominal (info), <60 as caution (warning) so
    /// the user can read the tier at a glance without doing the math.
    private func confidenceColor(for confidence: Int) -> Color {
        if confidence >= 80 { return HavenColors.success }
        if confidence >= 60 { return HavenColors.info }
        return HavenColors.warning
    }
}

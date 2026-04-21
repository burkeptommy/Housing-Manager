import SwiftUI

/// Phase 20a: Two-page hook screen shown after a property is set up and
/// before the quiz starts.
///
/// **Page 1 — Value anchor.** Optimistic valuation range, equity-protected
/// framing, three preview cards (vendors / documents / Alfred). NO mention
/// of estate, NO maintenance task list, NO "$X annual cost."
///
/// **Page 2 — Personalization + estate frame.** Top half: 3-4 specific
/// findings about the user's home. Bridge sentence. Bottom half: estate
/// vault as a 5-card stack with the legacy line ("Your family will know
/// exactly where to look").
///
/// On Continue, fires the appropriate callback based on auth state:
/// - Unauthenticated → `onContinueToAccountGate` (Phase 20b routes to AccountCreationStep)
/// - Authenticated   → `onContinueToQuiz` (routes directly to the quiz)
struct PropertyHookView: View {
    let address1: String
    let city: String
    let state: String
    let yearBuilt: Int?
    /// Optional fuel type pulled from the lookup result, used for the
    /// third Page 2 finding row. Nil rows are skipped, not rendered empty.
    let fuelType: String?
    /// Live property lookup carrying the optimistic valuation range when
    /// Phase 18g's Claude AI fallback fired. Used by Page 1 to compute
    /// the value range and equity-protected number.
    let lookupResult: PropertyLookupResult?
    let isAuthenticated: Bool
    var onContinueToAccountGate: () -> Void
    var onContinueToQuiz: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var currentPage: Int = 0
    @State private var pageOneCardsVisible: Bool = false
    // Phase 20 polish: default to true so Page 2 content is always visible.
    // The previous false-default caused the cards to render invisible until
    // the .onChange(of: currentPage) handler fired, which wasn't reliable
    // for users who landed directly on Page 2 or whose first swipe didn't
    // trigger SwiftUI's onChange callback. Cards now appear immediately;
    // the staggered fade-in is preserved via the page-1 first-appear animation.
    @State private var pageTwoCardsVisible: Bool = true

    private var valuation: ValuationRange? {
        ValuationRange.compute(from: lookupResult)
    }

    private var page1TitleTokens: [String: String] {
        ["city": city, "state": state]
    }

    var body: some View {
        TabView(selection: $currentPage) {
            page1ValueAnchor
                .tag(0)
            page2PersonalizationAndEstate
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(HavenColors.background.ignoresSafeArea())
        .onAppear {
            // Slight delay so the screen settles before cards begin to
            // stagger in.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.45)) {
                    pageOneCardsVisible = true
                }
            }
            // Tint the page indicator dots so they read against the cream
            // canvas. SwiftUI's index display uses the UIKit appearance
            // proxy under the hood.
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(HavenColors.navy800)
            UIPageControl.appearance().pageIndicatorTintColor = UIColor(HavenColors.navy800).withAlphaComponent(0.25)
        }
        .onChange(of: currentPage) { _, newValue in
            if newValue == 1 && !pageTwoCardsVisible {
                withAnimation(.easeOut(duration: 0.45)) {
                    pageTwoCardsVisible = true
                }
            }
        }
        // Phase 20 polish: removed the toolbar X button entirely. The hook
        // is the moment we earn account creation and we don't want users
        // bailing out before they see the value. There's no swipe-to-dismiss
        // on a fullScreenCover, so users have to walk through Page 1 → Page
        // 2 → AccountCreationStep, which is exactly the commit we want.
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("PropertyHookView")
    }

    // MARK: - Page 1: Value Anchor

    private var page1ValueAnchor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                Spacer().frame(height: HavenTheme.spacing12)

                // Hero title + value range
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    Text(HookContent.interpolate(HookContent.Page1.titleTemplate, with: page1TitleTokens))
                        .font(HavenTypography.title)
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let valuation {
                        // Phase 60.1 trust fix (2026-04-20): use midpoint
                        // so Page 1 agrees with PropertyRecapCard + every
                        // dashboard card. Previously `formattedHigh` here
                        // and `currentEstimatedValue` (midpoint) on the
                        // recap card disagreed by ~$570K on HNW homes —
                        // the same property appeared to change value
                        // mid-funnel.
                        Text(valuation.formattedMidpoint)
                            .font(HavenTypography.fraunces(size: 38, weight: 700))
                            .foregroundStyle(HavenColors.navy800)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text("Range: \(valuation.formattedCompactRange)")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)

                        Text(HookContent.Page1.valueRangeCaption)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("We're still pulling public records.")
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Equity-protected anchor card
                if let valuation {
                    equityCard(for: valuation)
                        .opacity(pageOneCardsVisible ? 1 : 0)
                        .offset(y: pageOneCardsVisible ? 0 : 12)
                }

                // Section header
                Text(HookContent.Page1.previewSectionLabel)
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.top, HavenTheme.spacing4)

                // Phase 20 polish: Four preview cards, with Home systems &
                // maintenance leading the stack. System management is the
                // primary value driver behind the equity card above, so it
                // anchors the "what Haven manages" section. Vendor coordination,
                // documents, and Alfred follow as supporting capabilities.
                VStack(spacing: HavenTheme.spacing12) {
                    previewCard(
                        icon: HookContent.Page1.previewSystemsIcon,
                        title: HookContent.Page1.previewSystemsTitle,
                        body: HookContent.Page1.previewSystemsBody
                    )
                    .opacity(pageOneCardsVisible ? 1 : 0)
                    .offset(y: pageOneCardsVisible ? 0 : 16)
                    .animation(.easeOut(duration: 0.45).delay(0.05), value: pageOneCardsVisible)

                    previewCard(
                        icon: HookContent.Page1.previewVendorsIcon,
                        title: HookContent.Page1.previewVendorsTitle,
                        body: HookContent.Page1.previewVendorsBody
                    )
                    .opacity(pageOneCardsVisible ? 1 : 0)
                    .offset(y: pageOneCardsVisible ? 0 : 16)
                    .animation(.easeOut(duration: 0.45).delay(0.13), value: pageOneCardsVisible)

                    previewCard(
                        icon: HookContent.Page1.previewDocumentsIcon,
                        title: HookContent.Page1.previewDocumentsTitle,
                        body: HookContent.Page1.previewDocumentsBody
                    )
                    .opacity(pageOneCardsVisible ? 1 : 0)
                    .offset(y: pageOneCardsVisible ? 0 : 16)
                    .animation(.easeOut(duration: 0.45).delay(0.21), value: pageOneCardsVisible)

                    previewCard(
                        icon: HookContent.Page1.previewAlfredIcon,
                        title: HookContent.Page1.previewAlfredTitle,
                        body: HookContent.Page1.previewAlfredBody
                    )
                    .opacity(pageOneCardsVisible ? 1 : 0)
                    .offset(y: pageOneCardsVisible ? 0 : 16)
                    .animation(.easeOut(duration: 0.45).delay(0.29), value: pageOneCardsVisible)
                }

                // CTA: scroll to Page 2
                HavenButton(title: HookContent.Page1.ctaLabel, action: {
                    Haptics.light()
                    withAnimation(HavenTheme.animationStandard) {
                        currentPage = 1
                    }
                }, icon: "arrow.right")
                .padding(.top, HavenTheme.spacing4)

                Spacer().frame(height: HavenTheme.spacing32)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
        }
    }

    private func equityCard(for valuation: ValuationRange) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(alignment: .firstTextBaseline, spacing: HavenTheme.spacing8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.creamLight)
                Text(HookContent.Page1.equityHeadline)
                    .font(HavenTypography.fraunces(size: 17, weight: 600))
                    .foregroundStyle(HavenColors.creamLight)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(HookContent.interpolate(
                HookContent.Page1.equityTemplate,
                with: ["equityProtected": valuation.formattedEquityProtected]
            ))
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

    private func previewCard(icon: String, title: String, body: String) -> some View {
        HavenCard {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.navy800)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(body)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Page 2: Personalization + Estate Frame

    private var page2PersonalizationAndEstate: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                Spacer().frame(height: HavenTheme.spacing12)

                // Findings header
                Text(HookContent.Page2.findingsHeader)
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                // Findings rows
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    ForEach(Array(findingRows.enumerated()), id: \.offset) { index, row in
                        findingRow(icon: row.icon, text: row.text, isMuted: row.isMuted)
                    }
                }

                // Phase 20 polish: 7.4% equity reminder anchored just below
                // the findings. This is the value-add proof that ties the
                // home-management cards below to a real dollar outcome.
                equityReminderCard

                // Bridge text
                Text(HookContent.Page2.bridgeText)
                    .font(Font.system(size: 16).italic())
                    .foregroundStyle(HavenColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, HavenTheme.spacing8)

                // Estate frame headline + body
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    Text(HookContent.Page2.estateHeadline)
                        .font(HavenTypography.title)
                        .foregroundStyle(HavenColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(HookContent.Page2.estateBody)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Estate vault card stack (5 cards)
                estateCardStack

                // Legacy line
                Text(HookContent.Page2.legacyLine)
                    .font(Font.system(size: 15).italic())
                    .foregroundStyle(HavenColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, HavenTheme.spacing4)

                // CTA
                HavenButton(
                    title: page2CTALabel,
                    action: {
                        Haptics.medium()
                        if isAuthenticated {
                            onContinueToQuiz()
                        } else {
                            onContinueToAccountGate()
                        }
                    },
                    icon: "arrow.right"
                )
                .padding(.top, HavenTheme.spacing12)

                // Phase 20 polish: extra bottom padding so the legacy line
                // and CTA don't collide with the TabView page indicator dots
                // that float at the bottom of the screen.
                Spacer().frame(height: HavenTheme.spacing48)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
        }
    }

    private struct FindingRow {
        let icon: String
        let text: String
        let isMuted: Bool
    }

    /// Phase 20 polish: pull real ATTOM/RentCast property facts when the
    /// lookup returned data. Falls back to the empty-state line when the
    /// lookup is nil OR every individual field is missing. Tom's audience
    /// expects PROPERTY-SPECIFIC facts here, not generic state-level
    /// statements about septic service.
    private var findingRows: [FindingRow] {
        var rows: [FindingRow] = []

        let result = lookupResult

        // Year built (highest priority — sets the mental model for system age)
        if let year = result?.yearBuilt ?? yearBuilt {
            rows.append(FindingRow(
                icon: "hammer.fill",
                text: HookContent.interpolate(
                    HookContent.Page2.findingsBuiltTemplate,
                    with: ["yearBuilt": "\(year)"]
                ),
                isMuted: false
            ))
        }

        // Size + lot (very tangible)
        if let sqft = result?.squareFootage, let lot = result?.lotSize {
            rows.append(FindingRow(
                icon: "ruler.fill",
                text: HookContent.interpolate(
                    HookContent.Page2.findingsSizeTemplate,
                    with: [
                        "squareFootage": Self.formatThousands(sqft),
                        "lotSize": Self.formatLotSize(lot),
                    ]
                ),
                isMuted: false
            ))
        }

        // Bedrooms + bathrooms (bathrooms is a Double to support half-baths
        // like 3.5, which ATTOM returns for "3 full + 1 half").
        if let beds = result?.bedrooms, let baths = result?.bathrooms {
            rows.append(FindingRow(
                icon: "bed.double.fill",
                text: HookContent.interpolate(
                    HookContent.Page2.findingsBedsBathsTemplate,
                    with: [
                        "bedrooms": "\(beds)",
                        "bathrooms": Self.formatBathrooms(baths),
                    ]
                ),
                isMuted: false
            ))
        }

        // Last sale price + date
        if let salePrice = result?.lastSalePrice,
           let saleDate = result?.lastSaleDate,
           let saleYear = saleDate.split(separator: "-").first.map(String.init) {
            rows.append(FindingRow(
                icon: "dollarsign.circle.fill",
                text: HookContent.interpolate(
                    HookContent.Page2.findingsLastSaleTemplate,
                    with: [
                        "lastSaleYear": saleYear,
                        "lastSalePrice": Self.formatCurrency(salePrice),
                    ]
                ),
                isMuted: false
            ))
        }

        // Heating fuel (winter delivery context)
        if let heatingFuel = result?.features?.heatingFuel ?? fuelType, !heatingFuel.isEmpty {
            rows.append(FindingRow(
                icon: "flame.fill",
                text: HookContent.interpolate(
                    HookContent.Page2.findingsFuelTemplate,
                    with: ["fuelType": heatingFuel.capitalized]
                ),
                isMuted: false
            ))
        }

        // Roof type
        if let roof = result?.features?.roofType, !roof.isEmpty {
            rows.append(FindingRow(
                icon: "house.fill",
                text: HookContent.interpolate(
                    HookContent.Page2.findingsRoofTemplate,
                    with: ["roofType": roof.capitalized]
                ),
                isMuted: false
            ))
        }

        // Pool
        if result?.features?.pool == true {
            rows.append(FindingRow(
                icon: "drop.fill",
                text: HookContent.Page2.findingsPoolTemplate,
                isMuted: false
            ))
        }

        // Empty state OR more-line trailer
        if rows.isEmpty {
            rows.append(FindingRow(
                icon: "magnifyingglass",
                text: HookContent.Page2.findingsEmptyLine,
                isMuted: true
            ))
        } else {
            rows.append(FindingRow(
                icon: "sparkles",
                text: HookContent.Page2.findingsMoreLine,
                isMuted: true
            ))
        }

        return rows
    }

    /// Render bathrooms as a Double, dropping ".0" for whole numbers and
    /// keeping ".5" for half-baths so the user sees "3" or "3.5" — never
    /// "3.0" or "3.500000".
    private static func formatBathrooms(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }

    private static func formatThousands(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static func formatLotSize(_ sqft: Int) -> String {
        // ATTOM returns lot size in square feet. Convert to acres for any
        // lot over 10,000 sq ft (which is how Westchester/Fairfield buyers
        // think about lot sizes). Below that, render as square feet.
        if sqft >= 10000 {
            let acres = Double(sqft) / 43560.0
            return String(format: "%.2f-acre", acres)
        }
        return "\(formatThousands(sqft))-sq-ft"
    }

    private static func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private func findingRow(icon: String, text: String, isMuted: Bool) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isMuted ? HavenColors.textTertiary : HavenColors.navy700)
                .frame(width: 24, height: 24)
                .background(
                    Circle().fill(
                        isMuted ? HavenColors.beige200 : HavenColors.navy.opacity(0.08)
                    )
                )
                .padding(.top, 1)
            Text(text)
                .font(HavenTypography.body)
                .foregroundStyle(isMuted ? HavenColors.textTertiary : HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    /// Phase 20 polish: Page 2 coordination card (variable kept as
    /// `equityReminderCard` for backward compat with the call site, but
    /// the content is now a vendor/document SCALE stat instead of the
    /// duplicated 7.4% from Page 1). Mirrors the equity card on Page 1
    /// visually (navy gradient, cream text) but reframes the message
    /// from value-preservation to operational scale and source-of-truth.
    private var equityReminderCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(alignment: .firstTextBaseline, spacing: HavenTheme.spacing8) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.creamLight)
                Text(HookContent.Page2.equityReminderHeadline)
                    .font(HavenTypography.fraunces(size: 17, weight: 600))
                    .foregroundStyle(HavenColors.creamLight)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(HookContent.Page2.equityReminderBody)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.creamLight.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
            Text(HookContent.Page2.equityReminderCitation)
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

    private var estateCardStack: some View {
        // Phase 20 polish: 2-column grid showing the 5 home-management cards.
        // Reframed from estate-only ("Will & trust") to home-system + asset
        // protection language. Each card now carries a subtitle that explains
        // what Haven actually tracks for that category.
        let cards = HookContent.Page2.estateCards
        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: HavenTheme.spacing12),
                GridItem(.flexible(), spacing: HavenTheme.spacing12),
            ],
            spacing: HavenTheme.spacing12
        ) {
            ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                estateCard(icon: card.icon, label: card.label, subtitle: card.subtitle)
            }
        }
    }

    private func estateCard(icon: String, label: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(HavenColors.navy800)
                .frame(width: 32, height: 32)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
            Text(label)
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        }
    }

    private var page2CTALabel: String {
        if isAuthenticated {
            return HookContent.Page2.ctaAuthenticated
        }
        let display = address1.trimmingCharacters(in: .whitespaces).isEmpty
            ? "your home"
            : address1
        return HookContent.interpolate(
            HookContent.Page2.ctaUnauthenticatedTemplate,
            with: ["address1": display]
        )
    }
}

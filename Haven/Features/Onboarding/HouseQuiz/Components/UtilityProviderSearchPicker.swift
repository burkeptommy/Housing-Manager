import SwiftUI

/// Trust-first provider picker for the quiz utility-search questions
/// (Q16 electric, Q17 internet, Q19 heating fuel, Q26 auto insurance,
/// Q27 homeowners insurance). Pre-loads the seeded list for the user's
/// state, surfaces logos for visual scanning, and offers a "didn't find
/// yours? Add it" path that creates a custom utility provider with a live
/// Brandfetch logo preview.
///
/// `providerTypes` is an array because some questions span multiple
/// provider_type values in the catalog (e.g. heating fuel covers oil +
/// propane + natural_gas). The first entry is treated as the canonical
/// type written when the user creates a brand-new provider.
///
/// Caller usage:
///
///     UtilityProviderSearchPicker(
///         providerTypes: ["electric"],
///         state: viewModel.property.state,
///         onSelect: { provider in
///             Task { await viewModel.recordAnswer("entered", customText: provider.name) }
///         }
///     )
struct UtilityProviderSearchPicker: View {
    let providerTypes: [String]
    let state: String?
    let city: String?
    /// Build 83 (Apr 7, 2026): Optional context-appropriate placeholder for
    /// the search field. Defaults to the legacy "ConEd, Verizon, Optimum..."
    /// hint so existing call sites that haven't been updated still render
    /// something. Pass a question-specific list (e.g. "GEICO, Progressive,
    /// State Farm..." for auto insurance) so users see brand names that
    /// actually match the catalog they're searching.
    let searchPlaceholder: String?
    /// Build 85: when non-nil, the picker fetches this provider on appear
    /// (or whenever the id changes) and renders it pinned at the top of
    /// the list with a navy-tinted "CURRENTLY SELECTED" pill. Tapping the
    /// pinned row fires `onDeselect` so the parent can clear its prior
    /// answer and the picker re-renders with the full alphabetical list.
    let preSelectedProviderId: UUID?
    /// Build 88 redesign: when true, the picker manages its own horizontal
    /// page-margin padding internally and pins a compact "Can't find yours?
    /// Add it" footer to the bottom of its container, with a top border
    /// separator and bottom safe-area padding so it doesn't clash with the
    /// home indicator. Pass true when the picker is the root content of a
    /// `.sheet()` (Estate intake / advisors directory). Leave false when
    /// embedded in another scroll container that already provides
    /// horizontal padding (the House Quiz inline provider questions) — the
    /// picker then renders as a flat VStack with the custom-add card as a
    /// bordered card after the provider list.
    let renderAsStandaloneSheet: Bool
    let onSelect: (UtilityProviderRow) -> Void
    let onCustomCreated: ((UtilityProviderRow) -> Void)?
    /// Build 85: fired when the user taps the pinned "Currently selected"
    /// row to start over. Parents wire this to a viewmodel `clearAnswer`
    /// helper that drops the prior `HouseQuizAnswer` from `state.answers`.
    let onDeselect: (() -> Void)?
    /// Build 90: When non-nil, the picker shows a "Find vetted pros near
    /// you" button so users can discover local advisors via Google Places
    /// without leaving the picker flow.
    let onFindNearMe: (() -> Void)?

    init(
        providerTypes: [String],
        state: String?,
        city: String? = nil,
        searchPlaceholder: String? = nil,
        preSelectedProviderId: UUID? = nil,
        renderAsStandaloneSheet: Bool = false,
        onSelect: @escaping (UtilityProviderRow) -> Void,
        onCustomCreated: ((UtilityProviderRow) -> Void)? = nil,
        onDeselect: (() -> Void)? = nil,
        onFindNearMe: (() -> Void)? = nil
    ) {
        self.providerTypes = providerTypes
        self.state = state
        self.city = city
        self.searchPlaceholder = searchPlaceholder
        self.preSelectedProviderId = preSelectedProviderId
        self.renderAsStandaloneSheet = renderAsStandaloneSheet
        self.onSelect = onSelect
        self.onCustomCreated = onCustomCreated
        self.onDeselect = onDeselect
        self.onFindNearMe = onFindNearMe
    }

    /// Canonical "primary" type the custom-add sheet uses when persisting a
    /// brand-new provider. Defaults to the first declared type, or "other"
    /// when none was provided (defensive fallback).
    private var primaryProviderType: String {
        providerTypes.first ?? "other"
    }

    @State private var allProviders: [UtilityProviderRow] = []
    @State private var isLoading: Bool = true
    @State private var searchText: String = ""
    @State private var loadError: String? = nil
    @State private var showCustomAdd: Bool = false
    /// Build 85: resolved provider row for `preSelectedProviderId`. Fetched
    /// in a `.task(id:)` keyed on the prop so navigation between questions
    /// (or a swap to a different prior answer) re-runs the lookup. Cleared
    /// when the user taps the pinned card to deselect.
    @State private var pinnedProvider: UtilityProviderRow? = nil
    /// Build 86 — id of the row the user just tapped. Drives the navy tint
    /// + checkmark + dim-others visual feedback that mirrors `singleChoiceBody`
    /// from Build 81. Tom's wife reported tapping a provider produced no
    /// visual change at all (only haptic), so she thought her tap hadn't
    /// registered. Reset naturally when the picker re-renders for a new
    /// question (the picker is keyed on `q.id` from the parent so SwiftUI
    /// tears it down between questions).
    @State private var tappedProviderId: UUID? = nil

    var body: some View {
        Group {
            if renderAsStandaloneSheet {
                standaloneSheetBody
            } else {
                embeddedBody
            }
        }
        .task(id: providerTypes) {
            await load()
        }
        .task(id: preSelectedProviderId) {
            await loadPinnedProvider()
        }
        .sheet(isPresented: $showCustomAdd) {
            UtilityProviderCustomAddSheet(
                providerType: primaryProviderType,
                initialName: searchText,
                onAdded: { provider in
                    showCustomAdd = false
                    allProviders.insert(provider, at: 0)
                    onCustomCreated?(provider)
                    onSelect(provider)
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Body variants

    /// Build 88 redesign: layout used when the picker is the root content of
    /// a `.sheet()` (estate intake / advisors directory). Internal layout:
    ///
    ///   ┌─────────────────────────────┐
    ///   │  pinned card (optional)     │   <- fixed header, scrolls with the
    ///   │  search bar                 │      sheet's nav bar but not the
    ///   │  "{N} providers" header     │      provider list
    ///   ├─────────────────────────────┤
    ///   │  provider rows (scrolls)    │   <- inner ScrollView; the list is
    ///   │  ...                        │      the only thing that scrolls
    ///   ├─────────────────────────────┤
    ///   │  ✨ Can't find yours? Add it │   <- sticky footer with top border
    ///   └─────────────────────────────┘      and bottom safe-area padding
    ///
    /// Page-margin horizontal padding is applied internally so the picker
    /// can be dropped into a `NavigationStack { }` inside a `.sheet { }`
    /// without the caller having to wrap it in another padded container.
    private var standaloneSheetBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed header. The pinned-card / search field / section header
            // group stays anchored above the scrolling provider list so the
            // user can always type and re-search without scrolling back up.
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                if let pinned = pinnedProvider {
                    pinnedSelectionCard(pinned)
                }
                searchBar
                if !isLoading {
                    sectionHeader
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing16)
            .padding(.bottom, HavenTheme.spacing16)

            // Scrolling provider list. The inner ScrollView only renders the
            // list itself so the fixed header above + sticky footer below
            // both stay visible regardless of scroll position.
            ScrollView {
                listContent
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.bottom, HavenTheme.spacing16)
            }

            // Sticky footer with optional "Find near me" + "Can't find yours?"
            stickyFooter
        }
    }

    /// Build 88 redesign: layout used when the picker is embedded in a parent
    /// scroll container that already provides horizontal page-margin padding
    /// (the House Quiz inline provider questions). The picker renders as a
    /// flat VStack — no inner ScrollView, no sticky footer — so the outer
    /// container handles all scrolling and the picker's content lines up
    /// horizontally with the rest of the page.
    private var embeddedBody: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            if let pinned = pinnedProvider {
                pinnedSelectionCard(pinned)
            }
            searchBar
            if !isLoading {
                sectionHeader
            }
            listContent
            inlineCustomAddCard
        }
    }

    /// Shared between both body variants — the loading spinner, empty-state
    /// card, or the actual provider list. The caller wraps this in whatever
    /// padding/scroll container is appropriate for the body variant.
    @ViewBuilder
    private var listContent: some View {
        if isLoading {
            ProgressView()
                .controlSize(.regular)
                .tint(HavenColors.navy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HavenTheme.spacing16)
        } else if filteredProviders.isEmpty && !searchText.isEmpty {
            emptyStateView
        } else {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                // Phase 50 (advisor picker fix): advisors get a 30-row cap
                // so the three-bucket sort (national → closest →
                // alphabetical) can render all three tiers. Utilities keep
                // the existing 20-row cap because they only have one bucket.
                ForEach(filteredProviders.prefix(isAdvisorPicker ? 30 : 20)) { provider in
                    providerRow(provider)
                }
            }
        }
    }

    // MARK: - Subviews

    /// Build 85: navy-tinted pinned card showing the user's prior pick.
    /// Tapping it fires `onDeselect` and clears the local pinned state so
    /// the picker re-renders with the full list.
    private func pinnedSelectionCard(_ provider: UtilityProviderRow) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.navy)
                Text("CURRENTLY SELECTED")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.navy700)
            }

            Button {
                Haptics.selection()
                pinnedProvider = nil
                // Build 86: also clear any in-flight tapped row id so the
                // re-rendered list starts in a clean visual state instead
                // of inheriting a faded sibling from the previous render.
                tappedProviderId = nil
                onDeselect?()
            } label: {
                HStack(spacing: HavenTheme.spacing12) {
                    logoView(for: provider)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(provider.name)
                            .font(HavenTypography.body.weight(.semibold))
                            .foregroundStyle(HavenColors.navy800)
                        Text("Tap to change")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.navy)
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .strokeBorder(HavenColors.navy.opacity(0.4), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
    }

    /// Build 88 redesign: removed the standalone "Search by provider name or
    /// website" label that used to sit above the input. The label was
    /// redundant with the placeholder text and added vertical noise above
    /// the search field. The placeholder now defaults to "Search name or
    /// website..." so the input still tells the user what to search by.
    private var searchBar: some View {
        HStack(spacing: HavenTheme.spacing8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.textTertiary)
            TextField(searchPlaceholder ?? "Search name or website...", text: $searchText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    /// Build 88 redesign: simple count-only header above the provider list.
    /// Reads "{N} PROVIDERS" by default and "{N} MATCHES" once the user has
    /// typed a search query. The previous "POPULAR IN NY" / "POPULAR" copy
    /// felt patronizing on advisor categories where there's no regional
    /// curation, and the count is what the user actually wants to know
    /// (am I looking at 4 providers or 40?).
    private var sectionHeader: some View {
        let count = filteredProviders.prefix(20).count
        let label: String
        if searchText.isEmpty {
            label = count == 1 ? "1 PROVIDER" : "\(count) PROVIDERS"
        } else {
            label = count == 1 ? "1 MATCH" : "\(count) MATCHES"
        }
        return Text(label)
            .font(HavenTypography.uiSectionHeader)
            .foregroundStyle(HavenColors.textTertiary)
    }

    private func providerRow(_ provider: UtilityProviderRow) -> some View {
        // Build 86: visual feedback parity with `singleChoiceBody`. The user
        // sees the row turn navy, gain a checkmark, and the unselected
        // siblings dim to 55% opacity. The 0.35s pause inside
        // `recordProviderAnswer` (build 82 pattern) gives this feedback time
        // to register before the quiz advances.
        //
        // Build 88 redesign: removed the secondary "Estate Attorney" / "CPA /
        // Tax Advisor" / "Life Insurance" subtitle that used to sit under the
        // provider name. The sheet's nav title already tells the user what
        // category they're browsing, so the subtitle was pure repetition and
        // made every row taller than it needed to be. Just the logo + name
        // now, vertically centered.
        let isTapped = (tappedProviderId == provider.id)
        let anyTapped = (tappedProviderId != nil)
        return Button {
            Haptics.selection()
            withAnimation(HavenTheme.animationStandard) {
                tappedProviderId = provider.id
            }
            onSelect(provider)
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                logoView(for: provider)
                Text(provider.name)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: isTapped ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: isTapped ? 18 : 12, weight: .semibold))
                    .foregroundStyle(isTapped ? HavenColors.navy : HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(isTapped ? HavenColors.navy.opacity(0.08) : HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(
                        isTapped ? HavenColors.navy.opacity(0.4) : HavenColors.beige300,
                        lineWidth: isTapped ? 1.5 : 1
                    )
            )
            .opacity((anyTapped && !isTapped) ? 0.55 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(HavenTheme.animationStandard, value: tappedProviderId)
    }

    @ViewBuilder
    private func logoView(for provider: UtilityProviderRow) -> some View {
        if let urlString = provider.logoUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(5)
                default:
                    fallbackIcon(for: provider.providerType)
                }
            }
            .frame(width: 48, height: 48)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            fallbackIcon(for: provider.providerType)
                .frame(width: 48, height: 48)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    /// Phase 16b: pick a category-appropriate SF Symbol when there's no logo
    /// available yet. Insurance categories used to share the default power-plug
    /// icon, which made the picker look like Tom was searching for an electric
    /// company instead of a carrier.
    private func fallbackIcon(for providerType: String) -> some View {
        Image(systemName: Self.fallbackIconName(for: providerType))
            .font(.system(size: 18))
            .foregroundStyle(HavenColors.navy)
    }

    private static func fallbackIconName(for providerType: String) -> String {
        switch providerType {
        case "auto_insurance": return "car.fill"
        case "home_insurance": return "house.fill"
        case "landscaping": return "leaf.fill"
        case "pool_service": return "figure.pool.swim"
        case "pest_control": return "ant.fill"
        case "irrigation": return "sprinkler.and.droplets.fill"
        case "security": return "shield.checkered"
        case "estate_attorney": return "building.columns.fill"
        case "cpa_tax": return "dollarsign.circle.fill"
        case "financial_advisor": return "chart.line.uptrend.xyaxis"
        case "life_insurance": return "heart.text.square.fill"
        default: return "bolt.fill"
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: HavenTheme.spacing8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(HavenColors.textTertiary)
            Text("No matches yet")
                .font(HavenTypography.bodySmall.weight(.semibold))
                .foregroundStyle(HavenColors.textPrimary)
            Text("Try a shorter spelling, or add it below.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing16)
    }

    /// Build 88 redesign: shared button content for both the inline custom-add
    /// card (embedded body) and the sticky footer (standalone sheet body).
    /// Compact single line: sparkles icon + "Can't find yours? Add it" copy +
    /// plus.circle.fill on the trailing edge. The wrapper view supplies its
    /// own background and padding so the same content renders correctly as
    /// either a card or a sticky footer.
    @ViewBuilder
    private var customAddButtonContent: some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.navy)
            Text("Can't find yours? Add it")
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer(minLength: 0)
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(HavenColors.navy)
        }
    }

    /// Build 88 redesign: card-style custom-add button used in the embedded
    /// (House Quiz) body. Same compact single-line content as the sticky
    /// footer, but rendered as a bordered cream-light card so it matches
    /// the rest of the picker's content within the quiz scroll context.
    private var inlineCustomAddCard: some View {
        Button {
            showCustomAdd = true
        } label: {
            customAddButtonContent
                .padding(HavenTheme.spacing12)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .strokeBorder(HavenColors.navy.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
        }
        .buttonStyle(.plain)
    }

    /// Build 90: combined sticky footer with prominent action buttons.
    private var stickyFooter: some View {
        VStack(spacing: HavenTheme.spacing12) {
            if onFindNearMe != nil {
                Button {
                    Haptics.light()
                    onFindNearMe?()
                } label: {
                    HStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Find vetted pros near you")
                            .font(HavenTypography.uiButton)
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(HavenColors.action)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(.plain)
            }

            Button {
                showCustomAdd = true
            } label: {
                HStack(spacing: HavenTheme.spacing8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Add your own")
                        .font(HavenTypography.uiButton)
                }
                .foregroundStyle(HavenColors.navy800)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                        .strokeBorder(HavenColors.beige300, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, HavenTheme.spacing16)
        .padding(.bottom, HavenTheme.spacing8)
        .background(
            HavenColors.cream
                .ignoresSafeArea(.container, edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(HavenColors.border)
                .frame(height: 0.5)
        }
    }

    /// Legacy alias kept so the embedded-body variant (House Quiz) still
    /// compiles unchanged. The embedded layout never shows the find-near-me
    /// button since it is only used for utility pickers, not advisor pickers.
    private var stickyCustomAddFooter: some View {
        stickyFooter
    }

    // MARK: - Computed

    /// Phase 19h: Rank providers by how well they match the user's location
    /// before applying the visible-list cap. Score:
    ///   3 = town/city match (Bedford, Greenwich, Sherman, etc.)
    ///   2 = state match (NY, CT) OR national 'US' carrier
    ///   0 = no regional signal
    /// Within the same score, fall back to alphabetical by name.
    ///
    /// State regionals and US nationals are intentionally tied so users see
    /// both major national carriers AND local regionals mixed together. For
    /// hyper-local services (trash, water, etc.) the town tag dominates, so
    /// picking the right provider is still one tap away.
    private func relevanceScore(for provider: UtilityProviderRow) -> Int {
        let regions = provider.regions ?? []
        if let town = city, !town.isEmpty,
           regions.contains(where: { $0.caseInsensitiveCompare(town) == .orderedSame }) {
            return 3
        }
        if let st = state, !st.isEmpty,
           regions.contains(where: { $0.caseInsensitiveCompare(st) == .orderedSame }) {
            return 2
        }
        if regions.contains(where: { $0.caseInsensitiveCompare("US") == .orderedSame }) {
            return 2
        }
        return 0
    }

    /// Phase 50 (advisor picker fix): The Life tab advisor picker needs a
    /// different ordering than utilities — users want the biggest national
    /// brands at the top, then the closest local firms, then everything
    /// else alphabetical. Detect the advisor categories so we can branch
    /// the sort logic in `filteredProviders` without disturbing the
    /// existing utility flow.
    private static let advisorProviderTypes: Set<String> = [
        "estate_attorney",
        "cpa_tax",
        "financial_advisor",
        "life_insurance"
    ]

    private var isAdvisorPicker: Bool {
        providerTypes.contains(where: { Self.advisorProviderTypes.contains($0) })
    }

    /// Phase 50: Proximity score for advisor sorting. Returns a small
    /// integer where lower = closer. Town hit beats state hit beats
    /// nothing. Used to pick the "10 closest to me" bucket — distinct
    /// from `relevanceScore` which conflates US-national with state
    /// match (intentional for utilities, wrong for advisors).
    ///   0 = exact town match
    ///   1 = exact state match
    ///   2 = no proximity signal
    private func proximityScore(for provider: UtilityProviderRow) -> Int {
        let regions = provider.regions ?? []
        if let town = city, !town.isEmpty,
           regions.contains(where: { $0.caseInsensitiveCompare(town) == .orderedSame }) {
            return 0
        }
        if let st = state, !st.isEmpty,
           regions.contains(where: { $0.caseInsensitiveCompare(st) == .orderedSame }) {
            return 1
        }
        return 2
    }

    private var filteredProviders: [UtilityProviderRow] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base: [UtilityProviderRow]
        if needle.isEmpty {
            base = allProviders
        } else {
            // Build 88 redesign: strip protocol + www. prefixes from the
            // stored website before comparing so a user typing "ml.com"
            // matches a provider whose website is "https://www.ml.com".
            // The unstripped contains() check is kept as a fallback so
            // searches that include "https://" still resolve.
            base = allProviders.filter { provider in
                provider.name.lowercased().contains(needle)
                    || {
                        guard let website = provider.website?.lowercased() else { return false }
                        let cleaned = website
                            .replacingOccurrences(of: "https://", with: "")
                            .replacingOccurrences(of: "http://", with: "")
                            .replacingOccurrences(of: "www.", with: "")
                        return cleaned.contains(needle) || website.contains(needle)
                    }()
            }
        }

        // Phase 50 (advisor picker fix): when the picker is rendering an
        // advisor category AND the user hasn't typed a search query, use
        // the three-bucket sort: top 10 by prominence_rank ascending,
        // then top 10 closest to the user, then top 10 alphabetical.
        // Active search queries fall through to the existing relevance
        // sort so name matches still surface immediately regardless of
        // bucket.
        if isAdvisorPicker && needle.isEmpty {
            return advisorBucketedSort(base)
        }

        // Stable sort: relevance score descending, then alphabetical.
        return base.sorted { a, b in
            let sa = relevanceScore(for: a)
            let sb = relevanceScore(for: b)
            if sa != sb { return sa > sb }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    /// Phase 50 (advisor picker fix): three-bucket sort for the Life tab
    /// advisor picker. Returns up to 30 rows in this order:
    ///   1. Top 10 by `prominence_rank` ascending (the biggest national
    ///      brands — MetLife, Morgan Stanley, Deloitte, Day Pitney, etc.)
    ///   2. Top 10 by proximity to the user's primary property (town hit
    ///      beats state hit; alphabetical tiebreak within the same tier)
    ///   3. Top 10 alphabetical from whatever's left
    /// Each bucket is deduped against the previous ones so a row never
    /// appears twice. If a bucket runs short, the next bucket pulls from
    /// its own remaining pool — buckets don't backfill from above so the
    /// "national" bucket stays purely national.
    private func advisorBucketedSort(_ pool: [UtilityProviderRow]) -> [UtilityProviderRow] {
        var seen: Set<UUID> = []
        var result: [UtilityProviderRow] = []
        result.reserveCapacity(30)

        // Bucket 1 — top 10 by prominence_rank ascending. Rows without a
        // rank are skipped here and picked up by the alphabetical bucket
        // below if proximity didn't grab them first.
        let nationals = pool
            .filter { $0.prominenceRank != nil }
            .sorted { a, b in
                let ra = a.prominenceRank ?? Int.max
                let rb = b.prominenceRank ?? Int.max
                if ra != rb { return ra < rb }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        for provider in nationals.prefix(10) {
            if seen.insert(provider.id).inserted {
                result.append(provider)
            }
        }

        // Bucket 2 — top 10 closest to the user's primary property. Skip
        // anything already in the nationals bucket. Any provider with a
        // proximity score of 2 (no town or state hit) is excluded from
        // this bucket — those land in alphabetical instead so the
        // "closest" tier is honest about being local matches only.
        let locals = pool
            .filter { !seen.contains($0.id) }
            .filter { proximityScore(for: $0) < 2 }
            .sorted { a, b in
                let pa = proximityScore(for: a)
                let pb = proximityScore(for: b)
                if pa != pb { return pa < pb }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        for provider in locals.prefix(10) {
            if seen.insert(provider.id).inserted {
                result.append(provider)
            }
        }

        // Bucket 3 — top 10 alphabetical from the remainder. Includes
        // any provider that didn't make it into the first two buckets,
        // sorted by name. This catches the long tail of mid-size firms
        // and out-of-region brands so users still have a meaningful
        // backup before they reach for the custom-add path.
        let remainder = pool
            .filter { !seen.contains($0.id) }
            .sorted { a, b in
                a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        for provider in remainder.prefix(10) {
            if seen.insert(provider.id).inserted {
                result.append(provider)
            }
        }

        return result
    }

    // MARK: - Loading

    private func load() async {
        // Phase 18a: Reset stale state on every load so users don't briefly
        // see results from a previous question while the new fetch is in
        // flight. The .task(id:) modifier above guarantees this runs whenever
        // providerTypes changes.
        isLoading = true
        allProviders = []
        searchText = ""
        loadError = nil
        defer { isLoading = false }
        do {
            let providers = try await DatabaseService.shared.fetchUtilityProviders(types: providerTypes)
            allProviders = providers
            // Phase 18d: lazy logo enrichment. Any provider in this category
            // that's still missing a logo gets a background Brandfetch lookup
            // so the next picker render shows it. Capped at 6 concurrent
            // lookups to be polite to Brandfetch's rate limit; one fire-and
            // -forget pass per .task(id:) load is more than enough since the
            // server-side enrich-provider-logos function handles bulk catch
            // up via ops.
            Task.detached { [providers] in
                await Self.enrichMissingLogos(providers: providers)
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    /// Build 85: fetches the resolved row for `preSelectedProviderId` so
    /// the pinned card has full data (logo, brand, type) without forcing
    /// the parent to thread a `UtilityProviderRow` through. Silent fail —
    /// a missing or deleted catalog row just hides the pinned card.
    private func loadPinnedProvider() async {
        guard let id = preSelectedProviderId else {
            pinnedProvider = nil
            return
        }
        do {
            pinnedProvider = try await DatabaseService.shared.fetchUtilityProvider(id: id)
        } catch {
            print("[UtilityProviderSearchPicker] Failed to fetch pinned provider: \(error)")
            pinnedProvider = nil
        }
    }

    /// Phase 18d: Background enrichment for any provider in the loaded list
    /// that's missing a logo. Runs detached so it doesn't block the picker
    /// from rendering. Patches the catalog row directly so subsequent users
    /// (and the next render of this picker) see the brand identity. Failures
    /// are silent — Brandfetch downtime should never break the quiz.
    ///
    /// Build 90: Prioritise national/statewide brands so recognisable
    /// logos (Fidelity, Schwab, MetLife, etc.) resolve on the very first
    /// picker visit instead of losing their slot to random local firms.
    /// Sorting: US-tagged first, then state-tagged, then local. Within
    /// each tier, providers WITH a website sort before those without
    /// (defensive, since the filter already requires a website).
    /// Batch bumped from 20 → 60 and concurrency from 12 → 15 so a
    /// fresh 500-row advisor catalog makes real progress on the first
    /// render. Each subsequent visit enriches another 60 until the
    /// backlog is drained.
    private static func enrichMissingLogos(providers: [UtilityProviderRow]) async {
        let needsLogo = providers.filter { $0.logoUrl == nil && $0.website != nil }
        guard !needsLogo.isEmpty else { return }

        // Prioritise nationals (regions contains 'US') then state-level,
        // then local so the most recognisable brands get logos first.
        let sorted = needsLogo.sorted { a, b in
            let aRegions = a.regions ?? []
            let bRegions = b.regions ?? []
            let aIsUS = aRegions.contains(where: { $0.caseInsensitiveCompare("US") == .orderedSame })
            let bIsUS = bRegions.contains(where: { $0.caseInsensitiveCompare("US") == .orderedSame })
            if aIsUS != bIsUS { return aIsUS }
            // Fewer region tags → broader coverage → higher priority
            return aRegions.count < bRegions.count
        }
        let batch = Array(sorted.prefix(60))
        await withTaskGroup(of: Void.self) { group in
            var inFlight = 0
            for provider in batch {
                if inFlight >= 15 {
                    await group.next()
                    inFlight -= 1
                }
                group.addTask {
                    await enrichOne(provider)
                }
                inFlight += 1
            }
        }
    }

    private static func enrichOne(_ provider: UtilityProviderRow) async {
        guard let website = provider.website else { return }
        let domain = website
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .components(separatedBy: "/")
            .first?
            .replacingOccurrences(of: "www.", with: "") ?? ""
        guard !domain.isEmpty else { return }

        do {
            let response = try await HavenSupabase.fetchBrandLogo(domain: domain)
            let resolvedLogo = response.logoUrl ?? response.iconUrl
            // Only patch when Brandfetch returned at least one signal worth
            // snapshotting; otherwise leave the row alone so the next pass
            // can try again later.
            guard resolvedLogo != nil || response.brandColor != nil else { return }
            try await DatabaseService.shared.updateUtilityProviderLogo(
                id: provider.id,
                logoUrl: resolvedLogo,
                brandColor: response.brandColor
            )
        } catch {
            // Silent failure — never block the quiz on Brandfetch downtime.
        }
    }
}

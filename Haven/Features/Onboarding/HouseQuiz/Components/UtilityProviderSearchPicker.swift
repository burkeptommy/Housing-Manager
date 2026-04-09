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
    let onSelect: (UtilityProviderRow) -> Void
    let onCustomCreated: ((UtilityProviderRow) -> Void)?
    /// Build 85: fired when the user taps the pinned "Currently selected"
    /// row to start over. Parents wire this to a viewmodel `clearAnswer`
    /// helper that drops the prior `HouseQuizAnswer` from `state.answers`.
    let onDeselect: (() -> Void)?

    init(
        providerTypes: [String],
        state: String?,
        city: String? = nil,
        searchPlaceholder: String? = nil,
        preSelectedProviderId: UUID? = nil,
        onSelect: @escaping (UtilityProviderRow) -> Void,
        onCustomCreated: ((UtilityProviderRow) -> Void)? = nil,
        onDeselect: (() -> Void)? = nil
    ) {
        self.providerTypes = providerTypes
        self.state = state
        self.city = city
        self.searchPlaceholder = searchPlaceholder
        self.preSelectedProviderId = preSelectedProviderId
        self.onSelect = onSelect
        self.onCustomCreated = onCustomCreated
        self.onDeselect = onDeselect
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
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            // Build 85: pinned "Currently selected" card. Renders above
            // the search field so back-navigated users see their prior
            // pick before they start typing. Hidden when no prior answer
            // is on file.
            if let pinned = pinnedProvider {
                pinnedSelectionCard(pinned)
            }

            searchBar

            if isLoading {
                ProgressView()
                    .controlSize(.regular)
                    .tint(HavenColors.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HavenTheme.spacing16)
            } else {
                if filteredProviders.isEmpty && !searchText.isEmpty {
                    emptyStateView
                } else {
                    providerList
                }

                customAddCard
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

    private var searchBar: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Search by provider name or website")
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textTertiary)
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(HavenColors.textTertiary)
                TextField(searchPlaceholder ?? "ConEd, Verizon, Optimum...", text: $searchText)
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
    }

    private var providerList: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            if !searchText.isEmpty {
                Text("MATCHES")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textTertiary)
            } else {
                if let state, !state.isEmpty {
                    Text("POPULAR IN \(state.uppercased()) · \(filteredProviders.count) provider\(filteredProviders.count == 1 ? "" : "s")")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                } else {
                    Text("POPULAR")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            VStack(spacing: HavenTheme.spacing8) {
                ForEach(filteredProviders.prefix(20)) { provider in
                    providerRow(provider)
                }
            }
        }
    }

    private func providerRow(_ provider: UtilityProviderRow) -> some View {
        // Build 86: visual feedback parity with `singleChoiceBody`. The user
        // sees the row turn navy, gain a checkmark, and the unselected
        // siblings dim to 55% opacity. The 0.35s pause inside
        // `recordProviderAnswer` (build 82 pattern) gives this feedback time
        // to register before the quiz advances.
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.name)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(provider.providerType.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
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
                        .padding(4)
                default:
                    fallbackIcon(for: provider.providerType)
                }
            }
            .frame(width: 40, height: 40)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        } else {
            fallbackIcon(for: provider.providerType)
                .frame(width: 40, height: 40)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
    }

    /// Phase 16b: pick a category-appropriate SF Symbol when there's no logo
    /// available yet. Insurance categories used to share the default power-plug
    /// icon, which made the picker look like Tom was searching for an electric
    /// company instead of a carrier.
    private func fallbackIcon(for providerType: String) -> some View {
        Image(systemName: Self.fallbackIconName(for: providerType))
            .font(.system(size: 16))
            .foregroundStyle(HavenColors.navy)
    }

    private static func fallbackIconName(for providerType: String) -> String {
        switch providerType {
        case "auto_insurance": return "car.fill"
        case "home_insurance": return "house.fill"
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
            Text("Try a shorter spelling, or scroll down to add it.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing16)
    }

    private var customAddCard: some View {
        Button {
            showCustomAdd = true
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.navy)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Didn't find yours? Add it")
                        .font(HavenTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("We'll fetch their logo and add them for everyone.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.navy)
            }
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

    private var filteredProviders: [UtilityProviderRow] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base: [UtilityProviderRow]
        if needle.isEmpty {
            base = allProviders
        } else {
            base = allProviders.filter { provider in
                provider.name.lowercased().contains(needle)
                    || (provider.website?.lowercased().contains(needle) ?? false)
            }
        }
        // Stable sort: relevance score descending, then alphabetical.
        return base.sorted { a, b in
            let sa = relevanceScore(for: a)
            let sb = relevanceScore(for: b)
            if sa != sb { return sa > sb }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
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
    private static func enrichMissingLogos(providers: [UtilityProviderRow]) async {
        let needsLogo = providers.filter { $0.logoUrl == nil && $0.website != nil }
        guard !needsLogo.isEmpty else { return }

        // Cap concurrency at 6 so we don't drown Brandfetch's rate limit.
        // Take the first 20 to bound work per render — repeat picker visits
        // gradually backfill the rest.
        let batch = Array(needsLogo.prefix(20))
        await withTaskGroup(of: Void.self) { group in
            var inFlight = 0
            for provider in batch {
                if inFlight >= 6 {
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

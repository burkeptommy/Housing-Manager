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
    let onSelect: (UtilityProviderRow) -> Void
    let onCustomCreated: ((UtilityProviderRow) -> Void)?

    init(
        providerTypes: [String],
        state: String?,
        onSelect: @escaping (UtilityProviderRow) -> Void,
        onCustomCreated: ((UtilityProviderRow) -> Void)? = nil
    ) {
        self.providerTypes = providerTypes
        self.state = state
        self.onSelect = onSelect
        self.onCustomCreated = onCustomCreated
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

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
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

    private var searchBar: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Search by provider name or website")
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textTertiary)
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(HavenColors.textTertiary)
                TextField("ConEd, Verizon, Optimum...", text: $searchText)
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
        Button {
            Haptics.selection()
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
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.beige300, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

    private var filteredProviders: [UtilityProviderRow] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else {
            return allProviders
        }
        return allProviders.filter { provider in
            provider.name.lowercased().contains(needle)
                || (provider.website?.lowercased().contains(needle) ?? false)
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

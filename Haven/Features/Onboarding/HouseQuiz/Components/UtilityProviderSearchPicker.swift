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
        } catch {
            loadError = error.localizedDescription
        }
    }
}

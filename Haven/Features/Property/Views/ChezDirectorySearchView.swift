import SwiftUI

/// Full-screen browse + search view for the Chez Field directory of
/// handymen. Pushed from `FindLocalVendorSheet` via the "Browse all Chez
/// handymen" CTA when `systemCategory == "handyman"`.
///
/// Loads state-scoped results on appear, debounces ILIKE searches as the
/// user types, and exposes a "Show pros nationwide" toggle that drops the
/// state filter for users in low-coverage regions. Adoption flows through
/// `ChezDirectoryService.shared.adopt(...)` so behavior matches the
/// auto-match path one-for-one.
struct ChezDirectorySearchView: View {
    let householdId: UUID
    let systemCategory: String
    let categoryDisplayName: String
    let defaultState: String
    var onAdoptedVendor: ((ContractorRow) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var providers: [HavenSupabase.ChezFieldProvider] = []
    @State private var searchQuery: String = ""
    @State private var debouncedQuery: String = ""
    @State private var nationwide: Bool = false
    @State private var isLoading: Bool = true
    @State private var loadError: String? = nil
    @State private var pendingAdoption: HavenSupabase.ChezFieldProvider? = nil
    @State private var isAdding: Bool = false
    @State private var hasLoadedOnce: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchField
                    nationwideToggle

                    ScrollView {
                        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                            header

                            if isLoading {
                                loadingState
                            } else if let error = loadError {
                                errorState(error)
                            } else if providers.isEmpty {
                                emptyState
                            } else {
                                providerList
                            }
                        }
                        .padding(.horizontal, HavenTheme.pageMargin)
                        .padding(.top, HavenTheme.spacing16)
                        .padding(.bottom, HavenTheme.spacing48)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Chez Directory")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
            .alert(
                "Add this Chez Field provider?",
                isPresented: Binding(
                    get: { pendingAdoption != nil },
                    set: { if !$0 { pendingAdoption = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) { pendingAdoption = nil }
                Button("Add") {
                    if let provider = pendingAdoption {
                        Task { await adopt(provider) }
                    }
                }
            } message: {
                if let provider = pendingAdoption {
                    Text("Add \(provider.name) as your \(categoryDisplayName) contractor? They use Chez Field, so they'll get your punch list and home details when you schedule a visit.")
                }
            }
        }
        .task {
            // Initial load. The empty searchQuery still triggers
            // directory-search mode on the edge function (we explicitly
            // pass `searchQuery: ""`), which skips the zip/city filter
            // and returns up to 25 statewide results.
            guard !hasLoadedOnce else { return }
            hasLoadedOnce = true
            await load()
        }
        .onChange(of: searchQuery) { _, newValue in
            Task { await debounceSearch(newValue) }
        }
        .onChange(of: nationwide) { _, _ in
            Task { await load() }
        }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: HavenTheme.spacing8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.textTertiary)

            TextField("Search by name or specialty", text: $searchQuery)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchQuery.isEmpty {
                Button {
                    Haptics.light()
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HavenTheme.spacing12)
        .padding(.vertical, HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        )
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, HavenTheme.spacing12)
    }

    private var nationwideToggle: some View {
        HStack(spacing: HavenTheme.spacing8) {
            Toggle(isOn: $nationwide) {
                Text("Show pros nationwide")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .tint(HavenColors.action)
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, HavenTheme.spacing8)
        .padding(.bottom, HavenTheme.spacing4)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
            Text(scopeLabel)
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.4)
                .foregroundStyle(HavenColors.textTertiary)

            Text(headerTitle)
                .font(HavenTypography.fraunces(size: 20, weight: 600))
                .foregroundStyle(HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var scopeLabel: String {
        nationwide ? "ON CHEZ · NATIONWIDE" : "ON CHEZ · \(defaultState.uppercased())"
    }

    private var headerTitle: String {
        if !providers.isEmpty {
            let count = providers.count
            let plural = count == 1 ? "pro" : "pros"
            if nationwide {
                return "\(count) \(categoryDisplayName.lowercased()) \(plural) on Chez."
            }
            return "\(count) \(categoryDisplayName.lowercased()) \(plural) in \(defaultState)."
        }
        return "Chez \(categoryDisplayName) directory"
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: HavenTheme.spacing12) {
            ProgressView()
                .tint(HavenColors.navy)
            Text("Loading the directory...")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing32)
    }

    private func errorState(_ error: String) -> some View {
        VStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(HavenColors.warning)
            Text("Couldn't load the directory")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text(error)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await load() }
            } label: {
                Text("Try again")
                    .font(HavenTypography.uiLabel.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
            }
            .padding(.top, HavenTheme.spacing4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing32)
    }

    private var emptyState: some View {
        VStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(HavenColors.textTertiary)
            Text(emptyTitle)
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
                .multilineTextAlignment(.center)
            Text(emptySubtitle)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)

            if !nationwide && debouncedQuery.isEmpty {
                Button {
                    Haptics.light()
                    nationwide = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 13))
                        Text("Show pros nationwide")
                            .font(HavenTypography.uiLabel.weight(.semibold))
                    }
                    .foregroundStyle(HavenColors.action)
                    .padding(.vertical, HavenTheme.spacing8)
                    .padding(.horizontal, HavenTheme.spacing16)
                    .background(HavenColors.actionPale)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, HavenTheme.spacing8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing32)
    }

    private var emptyTitle: String {
        if !debouncedQuery.isEmpty {
            return "No matches for \"\(debouncedQuery)\""
        }
        if nationwide {
            return "No \(categoryDisplayName.lowercased())s on Chez yet"
        }
        return "No \(categoryDisplayName.lowercased())s in \(defaultState) yet"
    }

    private var emptySubtitle: String {
        if !debouncedQuery.isEmpty {
            return "Try a different search term, or clear the search to see everyone in \(nationwide ? "the directory" : defaultState)."
        }
        if nationwide {
            return "We're still onboarding pros to the Chez network. Check back soon."
        }
        return "Try expanding to nationwide to see pros from the rest of the network."
    }

    // MARK: - Provider list

    private var providerList: some View {
        VStack(spacing: HavenTheme.spacing12) {
            ForEach(providers) { provider in
                ChezFieldProviderCard(
                    provider: provider,
                    isDisabled: isAdding
                ) {
                    pendingAdoption = provider
                }
            }
        }
    }

    // MARK: - Networking

    private func load() async {
        await MainActor.run {
            isLoading = true
            loadError = nil
        }
        do {
            let response = try await HavenSupabase.findNetworkHandymen(
                state: defaultState,
                category: systemCategory,
                searchQuery: debouncedQuery,
                nationwide: nationwide
            )
            await MainActor.run {
                providers = response.providers
                isLoading = false
            }
        } catch {
            let isCancel = (error as? URLError)?.code == .cancelled || error is CancellationError
            if isCancel { return }
            await MainActor.run {
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func debounceSearch(_ value: String) async {
        // 400ms debounce. If a newer change arrives before the sleep
        // completes, the local snapshot won't match the live searchQuery
        // and we abort.
        let snapshot = value
        try? await Task.sleep(nanoseconds: 400_000_000)
        guard snapshot == searchQuery else { return }
        debouncedQuery = snapshot
        await load()
    }

    // MARK: - Adopt

    private func adopt(_ provider: HavenSupabase.ChezFieldProvider) async {
        isAdding = true
        defer { isAdding = false }

        let result = await ChezDirectoryService.shared.adopt(
            provider,
            householdId: householdId,
            systemCategory: systemCategory,
            triggeringTaskId: nil
        )

        switch result {
        case .success(let contractor):
            onAdoptedVendor?(contractor)
            dismiss()
        case .failure(let message):
            loadError = message
        }
    }
}

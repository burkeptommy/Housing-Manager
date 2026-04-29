import SwiftUI

/// Phase 19n: Local vendor picker that fires when the user taps a
/// "Find a contractor for: X" task. Calls the `find-local-vendors` edge
/// function with the task's town/state/category, displays up to 4 ranked
/// businesses (2 Haven Certified + 2 Suggested), and lets the user adopt
/// one with a single tap. Adopting a vendor:
///
///   1. Creates a `contractors` row with `source: "find_vendor"` and the
///      matching system category.
///   2. Walks every needs_vendor task in this household for the same
///      category and converts each via `MaintenanceViewModel.convertToVendorManaged`,
///      reframing the title from "Find a contractor for: X" to
///      "Schedule [Vendor]: X" and clearing the needs_vendor flag.
///   3. Posts `.contractorAdded` so the dashboard can re-fire the
///      delegation sheet for any 'either' tasks the new vendor could also
///      take over.
struct FindLocalVendorSheet: View {
    /// Phase 56.1: task is now optional so the Vendor Coverage sheet can
    /// present this view directly even when no "Find a contractor for:"
    /// task exists yet. When nil, the adoption pass walks every matching
    /// `needs_vendor` task in the household and converts each.
    let task: MaintenanceTaskDBRow?
    /// Phase 56.1: required so we can create the contractor without a
    /// triggering task. Pass the current property or household's id.
    let householdId: UUID
    let town: String
    let state: String
    let systemCategory: String
    let categoryDisplayName: String
    var onComplete: (() -> Void)?
    var onAdoptedVendor: ((ContractorRow) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var vendors: [HavenSupabase.LocalVendorResult] = []
    @State private var chezFieldProviders: [HavenSupabase.ChezFieldProvider] = []
    @State private var isLoading: Bool = true
    @State private var loadError: String? = nil
    /// Inline directory-search query for the ON CHEZ section. Empty
    /// string falls back to the auto-match (near-me) results — that's
    /// the default discovery surface. Typing kicks the same search
    /// path the full-screen `ChezDirectorySearchView` uses, with a
    /// 400ms debounce so we don't fire the edge function on every
    /// keystroke. Only ever non-nil when category is handyman.
    @State private var chezSearchQuery: String = ""
    @State private var chezSearchDebounced: String = ""
    @State private var isSearchingChez: Bool = false
    @State private var pendingAdoption: HavenSupabase.LocalVendorResult? = nil
    @State private var pendingChezFieldAdoption: HavenSupabase.ChezFieldProvider? = nil
    @State private var isAdding: Bool = false
    /// Drives the full-screen browse / search view. Only ever set when
    /// `systemCategory == "handyman"` because the Chez Field directory
    /// is handyman-only today.
    @State private var showDirectorySearch: Bool = false
    /// Inline error shown above the action area when an adopt call
    /// fails. Without this the sheet just sits there silently when
    /// the network call or RLS blocks the contractor insert, which
    /// looks identical to "the button didn't fire" from a user's
    /// perspective.
    @State private var adoptError: String? = nil

    /// Guard against `.onAppear` firing twice (which SwiftUI can do during
    /// sheet presentation animations) from triggering two network calls.
    /// Reset only by the explicit "Try again" path.
    @State private var hasStartedLoading: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                        header

                        if isLoading {
                            loadingState
                        } else if let error = loadError {
                            errorState(error)
                        } else if shouldRenderVendorList {
                            // The ON CHEZ section has its own empty-state
                            // card with the Browse CTA, so we route through
                            // `vendorList` for handyman even when both
                            // result sets came back empty. For non-handyman
                            // categories with no results, fall back to the
                            // generic empty state.
                            vendorList
                        } else {
                            emptyState
                        }

                        if let adoptError {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(HavenColors.critical)
                                    .font(.system(size: 14))
                                    .padding(.top, 1)
                                Text(adoptError)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(HavenTheme.spacing12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(HavenColors.critical.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                            .padding(.top, HavenTheme.spacing12)
                        }

                        addMyOwnButton
                            .padding(.top, HavenTheme.spacing16)
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.top, HavenTheme.spacing16)
                    .padding(.bottom, HavenTheme.spacing48)
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
            }
            .alert(
                "Add this vendor?",
                isPresented: Binding(
                    get: { pendingAdoption != nil },
                    set: { if !$0 { pendingAdoption = nil } }
                ),
                presenting: pendingAdoption
            ) { vendor in
                Button("Cancel", role: .cancel) { pendingAdoption = nil }
                Button("Add") {
                    Task { await adoptVendor(vendor) }
                }
            } message: { vendor in
                Text("Add \(vendor.name) as your \(categoryDisplayName) contractor? We'll move your matching tasks over.")
            }
            .alert(
                "Add this Chez Field provider?",
                isPresented: Binding(
                    get: { pendingChezFieldAdoption != nil },
                    set: { if !$0 { pendingChezFieldAdoption = nil } }
                ),
                presenting: pendingChezFieldAdoption
            ) { provider in
                // `presenting:` hands the unwrapped provider to both
                // closures so we don't read `pendingChezFieldAdoption`
                // again at action time. That avoids a SwiftUI race
                // where the binding setter clears the state before the
                // Button action's `if let` evaluates, which on some iOS
                // versions made "Add" a silent no-op.
                Button("Cancel", role: .cancel) { pendingChezFieldAdoption = nil }
                Button("Add") {
                    Task { await adoptChezFieldProvider(provider) }
                }
            } message: { provider in
                Text("Add \(provider.name) as your \(categoryDisplayName) contractor? They use Chez Field, so they'll get your punch list and home details when you schedule a visit.")
            }
            .fullScreenCover(isPresented: $showDirectorySearch) {
                ChezDirectorySearchView(
                    householdId: householdId,
                    systemCategory: systemCategory,
                    categoryDisplayName: categoryDisplayName,
                    defaultState: state
                ) { contractor in
                    // Bubble the same outputs the auto-match adoption path
                    // would deliver, then dismiss this sheet too. The
                    // directory view dismisses itself first.
                    onAdoptedVendor?(contractor)
                    onComplete?()
                    dismiss()
                }
            }
        }
        .onAppear {
            // Fire the load off of the view's Task lifecycle so the
            // request isn't cancelled mid-flight by SwiftUI's sheet
            // presentation transition (the old `.task` pattern
            // consistently surfaced "cancelled" as an error state on
            // first open, forcing the user to tap "Try again"). The
            // unstructured Task survives view churn; the
            // `hasStartedLoading` guard prevents a double fire on a
            // second `.onAppear`.
            guard !hasStartedLoading else { return }
            hasStartedLoading = true
            Task { await loadVendors() }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("LOCAL VENDORS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.4)
                .foregroundStyle(HavenColors.textTertiary)

            Text("Top \(categoryDisplayName) pros in \(town), \(state).")
                .font(HavenTypography.fraunces(size: 24, weight: 600))
                .foregroundStyle(HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("We screen for high ratings, real reviews, and local independents. Tap a card to add them as your contractor.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: HavenTheme.spacing12) {
            ProgressView()
                .tint(HavenColors.navy)
            Text("Searching for vendors near you...")
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
            Text("Couldn't load vendors")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text(error)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await loadVendors() }
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
            Text("No vendors found yet")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("We couldn't surface a strong local match. Add your own vendor below and Chez will use it for future tasks.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing32)
    }

    // MARK: - Vendor List

    /// True when there's any content for `vendorList` to render. For the
    /// handyman category we render even when both Google Places and Chez
    /// Field returned zero, because the ON CHEZ section's empty-state
    /// card hosts the "Browse all Chez handymen" CTA.
    private var shouldRenderVendorList: Bool {
        if !vendors.isEmpty || !chezFieldProviders.isEmpty {
            return true
        }
        return systemCategory.lowercased() == "handyman"
    }

    private var vendorList: some View {
        let havenCertified = vendors.filter { $0.isHavenCertified }
        let suggested = vendors.filter { !$0.isHavenCertified }
        let isHandyman = systemCategory.lowercased() == "handyman"
        let chezSectionVisible = isHandyman || !chezFieldProviders.isEmpty

        return VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            // Chez Field providers — registered via the desktop command
            // center, opted into the homeowner directory. Render at the
            // top because they're already in the network and have
            // verified workspace identity. For handyman category we
            // always render the section so the user can discover the
            // directory and browse it actively, even when no providers
            // auto-match in their area.
            if chezSectionVisible {
                Text("ON CHEZ")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.action)

                if isHandyman {
                    chezSearchField
                }

                if isSearchingChez {
                    chezSearchLoadingRow
                } else if chezFieldProviders.isEmpty {
                    if chezSearchDebounced.isEmpty {
                        chezDirectoryEmptyCard
                    } else {
                        chezSearchEmptyResultsCard
                    }
                } else {
                    VStack(spacing: HavenTheme.spacing12) {
                        ForEach(chezFieldProviders) { provider in
                            ChezFieldProviderCard(
                                provider: provider,
                                isDisabled: isAdding
                            ) {
                                pendingChezFieldAdoption = provider
                            }
                        }
                    }
                    if isHandyman {
                        browseDirectoryFooterLink
                    }
                }
            }

            if !havenCertified.isEmpty {
                Text("CHEZ CERTIFIED")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.success)
                    .padding(.top, chezSectionVisible ? HavenTheme.spacing8 : 0)
                VStack(spacing: HavenTheme.spacing12) {
                    ForEach(havenCertified) { vendor in
                        vendorCard(vendor)
                    }
                }
            }

            if !suggested.isEmpty {
                Text("SUGGESTED")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.top, havenCertified.isEmpty ? 0 : HavenTheme.spacing8)
                VStack(spacing: HavenTheme.spacing12) {
                    ForEach(suggested) { vendor in
                        vendorCard(vendor)
                    }
                }
            }
        }
    }

    /// Phase 73 follow-up: inline search field for the ON CHEZ section.
    /// Live-filters the directory by company name + display blurb so
    /// homeowners can narrow a growing handyman list without leaving
    /// the sheet. When empty, the list falls back to the auto-match
    /// (near-me) result set so social-proof remains the default.
    private var chezSearchField: some View {
        HStack(spacing: HavenTheme.spacing8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(HavenColors.textTertiary)

            TextField(
                "Search Chez handymen by name or specialty",
                text: $chezSearchQuery
            )
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textPrimary)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            if !chezSearchQuery.isEmpty {
                Button {
                    Haptics.light()
                    chezSearchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HavenTheme.spacing12)
        .padding(.vertical, HavenTheme.spacing8)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        )
        .onChange(of: chezSearchQuery) { _, newValue in
            Task { await debounceChezSearch(newValue) }
        }
    }

    private var chezSearchLoadingRow: some View {
        HStack(spacing: HavenTheme.spacing8) {
            ProgressView().controlSize(.small)
            Text("Searching the Chez directory…")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var chezSearchEmptyResultsCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("No matches for \"\(chezSearchDebounced)\"")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Try a different search term, clear the search to see who's nearby, or browse the full directory.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Haptics.light()
                showDirectorySearch = true
            } label: {
                Text("Browse all Chez handymen")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HavenTheme.spacing12)
                    .background(HavenColors.action)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }
            .buttonStyle(.plain)
            .disabled(isAdding)
            .padding(.top, HavenTheme.spacing4)
        }
        .padding(HavenTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        )
    }

    /// 400ms debounce so we don't fire the edge function on every
    /// keystroke. Snapshot the value, sleep, then verify the query
    /// hasn't been overtaken by a later keystroke before kicking
    /// the search.
    private func debounceChezSearch(_ value: String) async {
        let snapshot = value
        try? await Task.sleep(nanoseconds: 400_000_000)
        guard snapshot == chezSearchQuery else { return }
        chezSearchDebounced = snapshot
        await searchChezDirectory(query: snapshot)
    }

    /// Hits the network-handymen edge function in directory-search
    /// mode (presence of `searchQuery` triggers it). For an empty
    /// query, falls back to the original auto-match (near_me) call so
    /// the section reverts to the social-proof default.
    private func searchChezDirectory(query: String) async {
        guard systemCategory.lowercased() == "handyman" else { return }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        await MainActor.run { isSearchingChez = true }
        defer {
            Task { @MainActor in isSearchingChez = false }
        }

        do {
            if trimmed.isEmpty {
                let response = try await HavenSupabase.findNetworkHandymen(
                    town: town,
                    state: state,
                    category: "handyman"
                )
                await MainActor.run {
                    chezFieldProviders = response.providers
                }
            } else {
                let response = try await HavenSupabase.findNetworkHandymen(
                    state: state,
                    category: "handyman",
                    searchQuery: trimmed,
                    nationwide: false
                )
                await MainActor.run {
                    chezFieldProviders = response.providers
                }
            }
        } catch {
            // Cancellation or transient errors: leave the existing
            // results in place so the user keeps a working list.
            print("[FindLocalVendor] chez directory search error: \(error)")
        }
    }

    /// Inline card rendered inside the ON CHEZ section when the auto-match
    /// query returned zero providers near the homeowner. Promotes the
    /// browse path so the user understands the Chez directory exists and
    /// is searchable.
    private var chezDirectoryEmptyCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("No Chez pros in your area yet")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)

            Text("Browse the full Chez \(categoryDisplayName.lowercased()) directory or expand to nationwide.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Haptics.light()
                showDirectorySearch = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Browse all Chez \(categoryDisplayName.lowercased())s")
                        .font(HavenTypography.uiButton)
                }
                .foregroundStyle(HavenColors.textOnAction)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HavenTheme.spacing12)
                .background(HavenColors.action)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }
            .buttonStyle(.plain)
            .disabled(isAdding)
            .padding(.top, HavenTheme.spacing4)
        }
        .padding(HavenTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.action.opacity(0.4), lineWidth: 1.5)
        }
    }

    /// Footer "Browse all" link rendered below the auto-matched Chez
    /// providers. Lets the user reach the full directory without giving
    /// up the cards already in front of them.
    private var browseDirectoryFooterLink: some View {
        Button {
            Haptics.light()
            showDirectorySearch = true
        } label: {
            HStack(spacing: 6) {
                Text("Browse all in \(state)")
                    .font(HavenTypography.uiLabel.weight(.semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(HavenColors.action)
            .padding(.top, HavenTheme.spacing4)
        }
        .buttonStyle(.plain)
        .disabled(isAdding)
    }

    private func vendorCard(_ vendor: HavenSupabase.LocalVendorResult) -> some View {
        Button {
            Haptics.selection()
            pendingAdoption = vendor
        } label: {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vendor.name)
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                            .multilineTextAlignment(.leading)

                        if let rating = vendor.rating {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(HavenColors.warning)
                                Text(String(format: "%.1f", rating))
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                if let reviews = vendor.reviewCount {
                                    Text("\u{00B7}")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text("\(reviews) reviews")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 4)
                    if vendor.isHavenCertified {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                            Text("Certified")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(HavenColors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(HavenColors.success.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }

                if let address = vendor.address, !address.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(address)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                if let phone = vendor.phone, !phone.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(phone)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                if let website = vendor.website, !website.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 10))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(website)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.navy700)
                            .lineLimit(1)
                    }
                }
            }
            .padding(HavenTheme.spacing16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .strokeBorder(
                        vendor.isHavenCertified
                            ? HavenColors.success.opacity(0.4)
                            : HavenColors.beige200,
                        lineWidth: vendor.isHavenCertified ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isAdding)
    }

    private var addMyOwnButton: some View {
        Button {
            Haptics.light()
            // Phase 19n: opening the manual contractor add path stays as a
            // separate sheet on top of this one. We dismiss first so the
            // navigation stack is clean.
            NotificationCenter.default.post(name: .openManualContractorAdd, object: nil)
            dismiss()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14))
                Text("Add my own instead")
                    .font(HavenTypography.uiLabel.weight(.semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(HavenColors.navy700)
            .frame(maxWidth: .infinity)
            .padding(.vertical, HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.navy.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
        .disabled(isAdding)
    }

    // MARK: - Loading

    private func loadVendors() async {
        await MainActor.run {
            isLoading = true
            loadError = nil
        }
        do {
            // Chez v1: query both directories in parallel. The Chez Field
            // call is fast (Supabase index lookup) and the Google Places
            // call is the long pole. We don't gate one on the other —
            // either result lighting up is enough to render the list.
            async let googlePlaces = HavenSupabase.findLocalVendors(
                town: town,
                state: state,
                category: systemCategory
            )
            async let chezField: HavenSupabase.ChezFieldProviderResponse? = {
                // Chez Field directory only knows about handyman today.
                // Skip the call entirely for other categories so we don't
                // burn round-trips on guaranteed-empty results.
                let normalized = systemCategory.lowercased()
                guard normalized == "handyman" else { return nil }
                return try? await HavenSupabase.findNetworkHandymen(
                    town: town,
                    state: state,
                    category: "handyman"
                )
            }()

            let response = try await googlePlaces
            let chezFieldResponse = await chezField

            await MainActor.run {
                vendors = response.vendors
                chezFieldProviders = chezFieldResponse?.providers ?? []
                isLoading = false
            }
        } catch {
            // Cancellation (`URLError.cancelled` / Swift
            // `CancellationError`) never happens because of user
            // intent here — it's either sheet-transition churn or the
            // user dismissing. Don't paint it as an error. We clear
            // the guard so the "Try again" button can re-fire if the
            // view is still on screen; if the view is truly gone, the
            // state writes become no-ops on a torn-down view.
            let isCancel = (error as? URLError)?.code == .cancelled || error is CancellationError
            if isCancel {
                await MainActor.run {
                    hasStartedLoading = false
                }
                return
            }
            await MainActor.run {
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }

    // MARK: - Adopt — Chez Field provider

    /// Adopts a Chez Field directory provider as a household contractor.
    /// Delegates the contractor insert + matching-task sweep to
    /// `ChezDirectoryService` so the same logic powers both the auto-match
    /// path and the directory-search path. The view stays responsible for
    /// presentation: the `isAdding` flag, the `onAdoptedVendor` /
    /// `onComplete` callbacks, and dismiss.
    private func adoptChezFieldProvider(_ provider: HavenSupabase.ChezFieldProvider) async {
        isAdding = true
        adoptError = nil
        defer { isAdding = false }

        let result = await ChezDirectoryService.shared.adopt(
            provider,
            householdId: householdId,
            systemCategory: systemCategory,
            triggeringTaskId: task?.id
        )

        switch result {
        case .success(let createdContractor):
            onAdoptedVendor?(createdContractor)
            onComplete?()
            dismiss()
        case .failure(let message):
            adoptError = message
        }
    }

    // MARK: - Adopt — Google Places vendor

    private func adoptVendor(_ vendor: HavenSupabase.LocalVendorResult) async {
        isAdding = true
        defer { isAdding = false }

        let db = DatabaseService.shared

        // 1. Create the contractor row, marked as find_vendor sourced.
        var insert = ContractorInsert(
            householdId: householdId,
            companyName: vendor.name,
            phone: vendor.phone ?? "Not provided"
        )
        insert.address = vendor.address
        insert.website = vendor.website
        insert.category = systemCategory
        insert.specialties = [systemCategory]
        insert.source = "find_vendor"

        let createdContractor: ContractorRow
        do {
            createdContractor = try await db.createContractor(insert)
        } catch {
            print("[FindLocalVendor] Failed to create contractor: \(error)")
            isAdding = false
            return
        }

        // 2. Walk every needs_vendor task whose system matches this category
        // and convert each via the existing viewmodel path. We refresh the
        // viewmodel first so its in-memory tasks are current; otherwise the
        // conversion would only see whatever was loaded earlier.
        await MaintenanceViewModel.shared.loadTasks()
        let triggeringTaskId = task?.id
        let candidates = MaintenanceViewModel.shared.tasks.filter { row in
            guard row.vehicleId == nil else { return false }
            guard row.assignmentType?.lowercased() == "vendor" else { return false }
            guard row.needsVendor == true else { return false }
            // Match the task's system category against the contractor's
            // category. Use the in-memory systems list maintained by the VM.
            guard let systemId = row.systemId,
                  let system = MaintenanceViewModel.shared.systems.first(where: { $0.id == systemId })
            else {
                // Fall back to the triggering task's systemId so the user
                // always sees at least the task they tapped get converted.
                // Phase 56.1: skip this fallback when no triggering task
                // exists (Vendor Coverage entry point).
                if let triggeringTaskId {
                    return row.id == triggeringTaskId
                }
                return false
            }
            return system.category.lowercased() == systemCategory.lowercased()
        }

        for candidate in candidates {
            await MaintenanceViewModel.shared.convertToVendorManaged(
                taskId: candidate.id,
                contractor: createdContractor
            )
        }

        // 3. Notify everyone. The contractorAdded post fires the dashboard
        // delegation sheet for any 'either' tasks the new vendor could also
        // take over (Phase 19l re-fire path).
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(
            name: .contractorAdded,
            object: nil,
            userInfo: ["contractorId": createdContractor.id.uuidString]
        )
        Haptics.success()

        onAdoptedVendor?(createdContractor)
        onComplete?()
        dismiss()
    }
}

extension Notification.Name {
    /// Phase 19n: posted by FindLocalVendorSheet when the user taps "Add my
    /// own instead". The maintenance list view (or any other host) listens
    /// for this and presents the manual ContractorDirectoryView add sheet.
    static let openManualContractorAdd = Notification.Name("openManualContractorAdd")
}

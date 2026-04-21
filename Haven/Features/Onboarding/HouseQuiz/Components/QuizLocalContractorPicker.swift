import SwiftUI

/// Build 85 polish: lightweight value type for the previously-picked vendor
/// surfaced as a pinned card at the top of the Q15b expanded picker. Built
/// from any of the three Q15b state dictionaries (`contractorChipsVendors`,
/// `contractorChipsManualNames`, `contractorChipsProviders`) so the picker
/// doesn't have to know which source the prior pick came from. Optional
/// fields are nil for manual / legacy catalog entries; only Places-sourced
/// vendors carry rating + reviewCount + isHavenCertified.
struct PreSelectedContractor {
    let name: String
    let rating: Double?
    let reviewCount: Int?
    let phone: String?
    let website: String?
    let isHavenCertified: Bool
}

/// Build 83 (Apr 7, 2026): Inline picker that fires from each Q15b contractor
/// chip when the user expands it. Replaces the old `UtilityProviderSearchPicker`
/// path that hard-coded `providerTypes: ["landscaping"]` for every chip and
/// surfaced wrong-category results (tree services for plumbers, etc.).
///
/// Mirrors the `FindLocalVendorSheet` flow used by the post-quiz "Find a
/// contractor" task path but lives inline so the user never leaves the quiz.
/// Calls `HavenSupabase.findLocalVendors(town:state:category:)` on appear,
/// renders up to 4 vendors ranked Haven Certified > Suggested > rating, and
/// always shows a manual "Didn't find yours? Add it" row at the bottom so
/// users in low-coverage areas have a path forward.
struct QuizLocalContractorPicker: View {
    /// Q15b chip id (e.g. "plumber", "hvac_service"). Translated into the
    /// edge function's category vocabulary by `categoryParam`.
    let chipId: String
    let chipLabel: String
    let town: String
    let state: String
    let onSelect: (HavenSupabase.LocalVendorResult) -> Void
    let onManualAdd: (String) -> Void
    /// Build 85 polish: when non-nil, render a navy-tinted pinned card at
    /// the top of the picker showing the user's prior pick. Tapping it
    /// fires `onDeselect` so the parent can clear the chip's vendor /
    /// manual / provider state and the picker re-renders with the full
    /// Google Places list. Mirrors the
    /// `UtilityProviderSearchPicker` pinned-card pattern from Build 85
    /// Fix 4. Optional so existing call sites that don't care still work.
    let preSelected: PreSelectedContractor?
    let onDeselect: (() -> Void)?
    /// Build 87: When `true`, the picker shows a prominent search bar and
    /// hides results until the user types 2+ characters. Results are loaded
    /// from Google Places on appear (same as the default mode) but filtered
    /// locally and rendered as a flat list without "Haven Certified" /
    /// "Suggested" section headers. Used by Q15b ("Got any pros on speed
    /// dial?") where the intent is for the user to search for THEIR
    /// existing contractor, not see our recommendations. Other callers
    /// (like "Find a contractor for: X" on the maintenance task detail)
    /// keep `searchFirst: false` and get the auto-loading behavior with
    /// ranked sections.
    let searchFirst: Bool

    init(
        chipId: String,
        chipLabel: String,
        town: String,
        state: String,
        searchFirst: Bool = false,
        preSelected: PreSelectedContractor? = nil,
        onSelect: @escaping (HavenSupabase.LocalVendorResult) -> Void,
        onManualAdd: @escaping (String) -> Void,
        onDeselect: (() -> Void)? = nil
    ) {
        self.chipId = chipId
        self.chipLabel = chipLabel
        self.town = town
        self.state = state
        self.searchFirst = searchFirst
        self.preSelected = preSelected
        self.onSelect = onSelect
        self.onManualAdd = onManualAdd
        self.onDeselect = onDeselect
    }

    @State private var vendors: [HavenSupabase.LocalVendorResult] = []
    @State private var isLoading: Bool = true
    @State private var loadError: String? = nil
    @State private var manualName: String = ""
    @State private var showManualField: Bool = false
    /// Build 87: search text for the `searchFirst` mode. Results are
    /// filtered locally against the pre-loaded Google Places list once
    /// the user types 2+ characters.
    @State private var searchText: String = ""
    /// Phase 60.1 trust fix (2026-04-20): ALSO search the persisted
    /// utility_providers catalog so regional brands the user has heard
    /// of (Tyler Heating, Petro Home Services, Hocon Gas, etc.) show up
    /// in the Q15b chip search even when Google Places hasn't returned
    /// them for the current town. Previously the picker only filtered
    /// `vendors` (Google Places results) — users typing "Tyler" or
    /// "Petro" on HVAC hit "No matches" despite the catalog carrying
    /// both providers tagged for HVAC. Merged into the filtered results
    /// so a single row can come from either source.
    @State private var catalogProviders: [UtilityProviderRow] = []
    /// Build 86 — id of the vendor row the user just tapped. Drives the
    /// navy tint + checkmark + dim-others visual feedback that mirrors
    /// `singleChoiceBody` from Build 81 and the parallel pattern in
    /// `UtilityProviderSearchPicker`. Tom's wife reported tapping a vendor
    /// produced no visual change (only haptic), so she thought her tap
    /// hadn't registered. The picker tears down naturally when the chip
    /// collapses after `onSelect`, so this state clears for free on the
    /// next expand. The manual-add row is intentionally NOT subject to
    /// dimming — it should always stay tappable.
    @State private var tappedVendorId: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            // Build 85 polish: pinned "CURRENTLY SELECTED" card showing
            // the user's prior pick. Renders only when the parent passes
            // a `preSelected` value. The manual-add row stays visible
            // below as always so the user can switch to a custom name
            // after deselecting.
            if let pinned = preSelected {
                pinnedSelectionCard(pinned)
            }

            if searchFirst {
                // Build 87: search-first mode for Q15b. Shows a prominent
                // search bar; results only appear once the user types 2+
                // characters. Filtering is local against the pre-loaded
                // Google Places results so there's zero network latency
                // after the initial load.
                searchFirstHeader
                searchBar
                searchFirstResults
            } else {
                header

                if isLoading {
                    loadingState
                } else if let error = loadError {
                    errorState(error)
                } else if vendors.isEmpty {
                    emptyState
                } else {
                    vendorList
                }
            }

            manualAddRow
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .task(id: chipId) {
            // In both modes, load vendors from Google Places on appear.
            // In searchFirst mode the results are hidden until the user
            // types 2+ characters; the local filter handles the rest so
            // there's no second network call.
            await loadVendors()
        }
    }

    // MARK: - Pinned selection (Build 85 polish)

    /// Navy-tinted card showing the previously-picked vendor at the top
    /// of the expanded picker. Tap fires `onDeselect` so the parent can
    /// clear the chip's stored vendor/manual/provider state. Visual
    /// treatment mirrors `UtilityProviderSearchPicker.pinnedSelectionCard`.
    private func pinnedSelectionCard(_ pinned: PreSelectedContractor) -> some View {
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
                // Build 86: also clear any in-flight tapped vendor id so
                // the re-rendered list starts in a clean visual state.
                tappedVendorId = nil
                onDeselect?()
            } label: {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: pinned.isHavenCertified ? "checkmark.seal.fill" : "building.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(pinned.isHavenCertified ? HavenColors.success : HavenColors.navy700)
                        .frame(width: 32, height: 32)
                        .background(pinned.isHavenCertified ? HavenColors.success.opacity(0.12) : HavenColors.navy.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pinned.name)
                            .font(HavenTypography.body.weight(.semibold))
                            .foregroundStyle(HavenColors.navy800)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        if let rating = pinned.rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(HavenColors.warning)
                                Text(String(format: "%.1f", rating))
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textPrimary)
                                if let reviews = pinned.reviewCount {
                                    Text("\u{00B7} \(reviews) reviews")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                                if pinned.isHavenCertified {
                                    Text("\u{00B7} Haven Certified")
                                        .font(HavenTypography.uiCaption.weight(.semibold))
                                        .foregroundStyle(HavenColors.success)
                                }
                            }
                        }

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
                .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LOCAL \(chipLabel.uppercased()) PROS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.2)
                .foregroundStyle(HavenColors.textTertiary)
            if !town.isEmpty {
                Text("Top picks near \(town).")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    // MARK: - Search-first mode (Build 87)

    /// Build 87: header for search-first mode. Prompts the user to search
    /// for their own contractor instead of browsing recommendations.
    private var searchFirstHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("YOUR \(chipLabel.uppercased())")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.2)
                .foregroundStyle(HavenColors.textTertiary)
            Text("Search for the company you already use.")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    /// Build 87: prominent search bar for search-first mode.
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.textTertiary)
            TextField("Search for your \(chipLabel.lowercased())...", text: $searchText)
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
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.beige300, lineWidth: 1)
        )
    }

    /// Build 87: empty state for search-first mode when no results found.
    private var searchFirstEmptyState: some View {
        VStack(spacing: HavenTheme.spacing8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundStyle(HavenColors.textTertiary)
            Text("No matches for \"\(searchText)\"")
                .font(HavenTypography.bodySmall.weight(.semibold))
                .foregroundStyle(HavenColors.textPrimary)
            Text("Try a different spelling, or add them manually below.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing12)
    }

    /// Build 87: trimmed search text needle. Computed property avoids
    /// `let` bindings inside the `@ViewBuilder` result builder.
    private var searchNeedle: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Build 87: locally filtered vendor results for search-first mode.
    /// Phase 60.1 trust fix (2026-04-20): merge in catalog matches from
    /// `utility_providers` so household-name regional brands (Tyler,
    /// Petro, Hocon) show up even when Google Places misses them. Catalog
    /// rows are converted to `LocalVendorResult` on the fly so the UI
    /// only has to render one row shape. De-duped by lowercased name so a
    /// provider in both sources doesn't appear twice.
    private var searchFilteredVendors: [HavenSupabase.LocalVendorResult] {
        let needle = searchNeedle
        guard needle.count >= 2 else { return [] }
        let placesMatches = vendors.filter { $0.name.localizedCaseInsensitiveContains(needle) }
        let catalogMatches = catalogProviders
            .filter { $0.name.localizedCaseInsensitiveContains(needle) }
            .map { Self.catalogToLocalVendor($0) }

        var seen = Set<String>()
        var merged: [HavenSupabase.LocalVendorResult] = []
        for vendor in placesMatches + catalogMatches {
            let key = vendor.name.lowercased()
            if seen.insert(key).inserted {
                merged.append(vendor)
            }
        }
        return merged
    }

    /// Converts a persisted `UtilityProviderRow` into a `LocalVendorResult`
    /// so the search-first list can render it alongside Google Places
    /// rows without a second UI path. Rating / reviewCount are nil for
    /// catalog rows since utility_providers doesn't persist those. The
    /// `googlePlaceId` is salted with a `catalog_` prefix so the downstream
    /// identifier never collides with a real Places id.
    private static func catalogToLocalVendor(
        _ row: UtilityProviderRow
    ) -> HavenSupabase.LocalVendorResult {
        HavenSupabase.LocalVendorResult(
            name: row.name,
            address: nil,
            phone: row.phone,
            website: row.website,
            rating: nil,
            reviewCount: nil,
            googlePlaceId: "catalog_\(row.id.uuidString)",
            isHavenCertified: false,
            rankPosition: 999
        )
    }

    /// Build 87: computed results view for search-first mode. Shows loading,
    /// empty, or flat results based on the search text length and vendor list.
    @ViewBuilder
    private var searchFirstResults: some View {
        if isLoading && searchNeedle.count >= 2 {
            loadingState
        } else if searchNeedle.count >= 2 {
            if searchFilteredVendors.isEmpty {
                searchFirstEmptyState
            } else {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    ForEach(searchFilteredVendors) { vendor in
                        vendorRow(vendor, certified: false)
                    }
                }
            }
        }
        // When < 2 chars: show nothing, just the search bar + manual add.
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: HavenTheme.spacing8) {
            ForEach(0..<3, id: \.self) { _ in
                skeletonRow
            }
        }
    }

    private var skeletonRow: some View {
        HStack(spacing: HavenTheme.spacing12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(HavenColors.beige200)
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(HavenColors.beige200)
                    .frame(width: 140, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(HavenColors.beige200)
                    .frame(width: 90, height: 10)
            }
            Spacer(minLength: 0)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private func errorState(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.warning)
                Text("Couldn't load local vendors. Add yours manually below.")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textTertiary)
                Text("No local \(chipLabel.lowercased()) pros on record yet. Add yours below.")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Vendor list

    private var vendorList: some View {
        let havenCertified = vendors.filter { $0.isHavenCertified }
        let suggested = vendors.filter { !$0.isHavenCertified }

        return VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            if !havenCertified.isEmpty {
                Text("HAVEN CERTIFIED")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.success)
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(havenCertified) { vendor in
                        vendorRow(vendor, certified: true)
                    }
                }
            }

            if !suggested.isEmpty {
                Text("SUGGESTED")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.top, havenCertified.isEmpty ? 0 : 4)
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(suggested) { vendor in
                        vendorRow(vendor, certified: false)
                    }
                }
            }
        }
    }

    private func vendorRow(_ vendor: HavenSupabase.LocalVendorResult, certified: Bool) -> some View {
        // Build 86: visual feedback parity with `singleChoiceBody` and the
        // `UtilityProviderSearchPicker` row treatment. Once the user taps a
        // vendor row, this row turns navy + gains a checkmark, and the
        // sibling rows fade to 55% opacity. The chip collapses immediately
        // after `onSelect` (parent sets `contractorChipsExpanded = nil`),
        // so this state clears for free on the next expand. Manual-add row
        // is intentionally exempt — it should always stay tappable.
        let isTapped = (tappedVendorId == vendor.googlePlaceId)
        let anyTapped = (tappedVendorId != nil)
        return Button {
            Haptics.selection()
            withAnimation(HavenTheme.animationStandard) {
                tappedVendorId = vendor.googlePlaceId
            }
            onSelect(vendor)
        } label: {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: certified ? "checkmark.seal.fill" : "building.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(certified ? HavenColors.success : HavenColors.navy700)
                    .frame(width: 32, height: 32)
                    .background(certified ? HavenColors.success.opacity(0.12) : HavenColors.navy.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(vendor.name)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    if let rating = vendor.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(HavenColors.warning)
                            Text(String(format: "%.1f", rating))
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textPrimary)
                            if let reviews = vendor.reviewCount {
                                Text("\u{00B7} \(reviews) reviews")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            if certified {
                                Text("\u{00B7} Haven Certified")
                                    .font(HavenTypography.uiCaption.weight(.semibold))
                                    .foregroundStyle(HavenColors.success)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
                Image(systemName: isTapped ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: isTapped ? 18 : 12, weight: .semibold))
                    .foregroundStyle(isTapped ? HavenColors.navy : HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isTapped ? HavenColors.navy.opacity(0.08) : HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(
                        isTapped
                            ? HavenColors.navy.opacity(0.4)
                            : (certified ? HavenColors.success.opacity(0.4) : HavenColors.beige200),
                        lineWidth: isTapped ? 1.5 : (certified ? 1.5 : 1)
                    )
            )
            .opacity((anyTapped && !isTapped) ? 0.55 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(HavenTheme.animationStandard, value: tappedVendorId)
    }

    // MARK: - Manual add

    private var manualAddRow: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            if showManualField {
                HStack(spacing: HavenTheme.spacing8) {
                    TextField("Vendor name", text: $manualName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                        .padding(HavenTheme.spacing12)
                        .background(HavenColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                .strokeBorder(HavenColors.beige300, lineWidth: 1)
                        )
                        .submitLabel(.done)
                        .onSubmit { commitManual() }
                    Button {
                        commitManual()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(canCommitManual ? HavenColors.navy : HavenColors.textTertiary)
                    }
                    .disabled(!canCommitManual)
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    Haptics.light()
                    withAnimation(HavenTheme.animationStandard) {
                        showManualField = true
                    }
                } label: {
                    HStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.navy)
                        Text("Didn't find yours? Add it")
                            .font(HavenTypography.uiLabel.weight(.semibold))
                            .foregroundStyle(HavenColors.navy700)
                        Spacer(minLength: 0)
                    }
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .strokeBorder(
                                HavenColors.navy.opacity(0.15),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var canCommitManual: Bool {
        !manualName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func commitManual() {
        let trimmed = manualName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Haptics.success()
        onManualAdd(trimmed)
        manualName = ""
        showManualField = false
    }

    // MARK: - Loading

    /// Translate a Q15b chip id into the edge function's category vocabulary.
    /// `find-local-vendors`'s `CATEGORY_SEARCH_TERMS` table accepts these
    /// canonical category strings.
    private var categoryParam: String {
        switch chipId {
        case "hvac_service":       return "HVAC"
        case "plumber":            return "Plumbing"
        case "electrician":        return "Electrical"
        case "roofer":             return "Roofing"
        case "septic_pumper":      return "Septic System"
        case "well_water_service": return "Well System"
        // Phase 60.6: aligned with HouseQuizAnswerMapper.householdContractorCategoryFor
        // so the find-local-vendors Google Places filter searches the
        // same trade vocabulary the contractor mirror stamps. "Chimney"
        // replaces "Fire Protection" (which was an unrelated sub-system
        // key); "Tree Service" replaces "Landscaping" so arborist
        // searches aren't diluted by lawn-mower results.
        case "chimney_sweep":      return "Chimney"
        case "tree_service":       return "Tree Service"
        case "handyman":           return "Handyman"
        // Phase 60.6: match the chip additions in HouseQuizQuestionLibrary.
        case "hardscape":          return "Landscaping"
        case "generator_service":  return "Generator"
        // Phase 60.2 (F5): four new chip types. Category strings match
        // SystemCategoryRegistry keys so find-local-vendors can filter
        // Google Places results by the right trade.
        case "cleaning":           return "Cleaning Service"
        case "snow_removal":       return "Snow Removal"
        case "mosquito_tick":      return "Mosquito & Tick"
        case "pet_waste":          return "Pet Waste"
        default:                   return chipId
        }
    }

    private func loadVendors() async {
        guard !town.isEmpty, !state.isEmpty else {
            isLoading = false
            loadError = nil
            // Phase 60.1 trust fix: still load the catalog even without
            // a town — the catalog search doesn't depend on location.
            await loadCatalogProviders()
            return
        }
        isLoading = true
        loadError = nil
        async let placesTask: Void = {
            do {
                let response = try await HavenSupabase.findLocalVendors(
                    town: town,
                    state: state,
                    category: categoryParam
                )
                await MainActor.run { vendors = response.vendors }
            } catch {
                await MainActor.run {
                    loadError = error.localizedDescription
                    vendors = []
                }
            }
        }()
        async let catalogTask: Void = loadCatalogProviders()
        _ = await (placesTask, catalogTask)
        isLoading = false
    }

    /// Phase 60.1 trust fix (2026-04-20): load utility_providers rows
    /// matching the chip category so regional HNW brands (Tyler, Petro,
    /// Hocon) show up in the Q15b search even when Google Places misses
    /// them. Includes adjacent types (heating-fuel providers often also
    /// do HVAC work) so brands tagged under `oil` / `propane` still
    /// surface on the HVAC chip. Silent on failure — the Google Places
    /// path is still the primary source and a catalog miss shouldn't
    /// block the picker.
    private func loadCatalogProviders() async {
        let types = catalogProviderTypes
        guard !types.isEmpty else { return }
        do {
            // Load the category-scoped slice first (fast, narrows the
            // search to plausible candidates for this chip).
            let scoped = try await DatabaseService.shared.fetchUtilityProviders(types: types)
            await MainActor.run { catalogProviders = scoped }
        } catch {
            // Intentional silent fallback — Google Places already populated.
        }
    }

    /// Maps Q15b chip ids to `utility_providers.provider_type` values so
    /// the catalog fetch returns the right slice. Values match the
    /// `provider_type` column verbatim (verified against the live
    /// catalog 2026-04-20): the DB uses `chimney_sweep`, `septic_pumper`,
    /// `well_water_service`, `tree_service` as the full tokens, not the
    /// shortened forms. Multiple types per chip are allowed — HVAC
    /// legitimately covers heating-fuel brands that also install systems
    /// (Petro Home Services), and Tree Service covers general landscaping
    /// companies that do arborist work. Chips with no catalog analog
    /// (handyman / cleaning / pet_waste) return [] and fall through to
    /// Google Places only, which is how it used to work for all chips.
    private var catalogProviderTypes: [String] {
        switch chipId {
        case "hvac_service":       return ["hvac", "oil", "propane", "natural_gas"]
        case "plumber":            return ["plumbing"]
        case "electrician":        return ["electrical"]
        case "roofer":             return ["roofing"]
        case "septic_pumper":      return ["septic_pumper"]
        case "well_water_service": return ["well_water_service"]
        case "chimney_sweep":      return ["chimney_sweep"]
        case "tree_service":       return ["tree_service", "landscaping"]
        case "handyman":           return []
        case "cleaning":           return []
        case "snow_removal":       return ["landscaping"]
        case "mosquito_tick":      return ["pest_control"]
        case "pet_waste":          return []
        default:                   return []
        }
    }
}

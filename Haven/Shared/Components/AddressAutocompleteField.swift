import SwiftUI

/// Address input with Google Places autocomplete suggestions.
/// Shows a single search field. On selection, auto-fills and reveals
/// structured address fields (street, city, state, zip) for confirmation.
struct AddressAutocompleteField: View {
    @Binding var street: String
    @Binding var unit: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String

    @State private var searchText = ""
    @State private var suggestions: [PlaceSuggestion] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var hasSelectedPlace = false
    @State private var errorMessage: String?
    @State private var isEditing = false

    private let placesService = GooglePlacesService.shared

    /// Whether address details should be visible (selected from autocomplete or pre-filled).
    private var showDetails: Bool {
        !street.isEmpty
    }

    var body: some View {
        if showDetails && !isEditing {
            // Confirmed address — show summary with edit option
            confirmedAddressView
        } else {
            // Search mode
            searchView
        }
    }

    // MARK: - Search Mode

    @ViewBuilder
    private var searchView: some View {
        // Phase 20 polish: hide the raw search TextField once the user has
        // picked a suggestion AND we're showing the structured address detail
        // fields below. Otherwise the search input + the street field both
        // render the same address and the screen looks duplicated.
        if !(showDetails && isEditing) {
            TextField("Search for your address...", text: $searchText)
                .font(HavenTypography.body)
                .textContentType(.fullStreetAddress)
                .autocorrectionDisabled()
                .onChange(of: searchText) { _, newValue in
                    if hasSelectedPlace {
                        hasSelectedPlace = false
                        return
                    }
                    debounceSearch(newValue)
                }

            if !suggestions.isEmpty {
                ForEach(suggestions) { suggestion in
                    Button {
                        selectSuggestion(suggestion)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.mainText)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(suggestion.secondaryText)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }

            if isSearching {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Searching...")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.warning)
            }
        }

        // Show detail fields while editing (after autocomplete fills them)
        if showDetails && isEditing {
            addressDetailFields
            doneEditingButton
        }
    }

    // MARK: - Confirmed Address View

    private var confirmedAddressView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(street)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Text(cityStateZip)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Button {
                    isEditing = true
                    searchText = street
                } label: {
                    Text("Change")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.navy700)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Detail Fields (editable after autocomplete)

    @ViewBuilder
    private var addressDetailFields: some View {
        TextField("Street", text: $street)
            .textContentType(.streetAddressLine1)
        TextField("Unit/Apt (optional)", text: $unit)
            .textContentType(.streetAddressLine2)
        TextField("City", text: $city)
            .textContentType(.addressCity)
        TextField("State", text: $state)
            .textContentType(.addressState)
        TextField("ZIP Code", text: $zipCode)
            .textContentType(.postalCode)
            .keyboardType(.numberPad)
    }

    private var doneEditingButton: some View {
        // Phase 60.1 trust fix (2026-04-20): renamed "Confirm Address" to
        // "Done" so users don't mistake the mode-exit toggle for the
        // primary CTA. The salmon "Find My Home" / "Continue" button below
        // is the real submit — this one just collapses the detailed
        // fields back to the compact search row.
        Button {
            isEditing = false
            suggestions = []
        } label: {
            Text("Done")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .disabled(street.isEmpty || city.isEmpty || state.isEmpty)
    }

    // MARK: - Helpers

    private var cityStateZip: String {
        [city, state, zipCode].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private func debounceSearch(_ query: String) {
        searchTask?.cancel()
        errorMessage = nil

        guard query.count >= 3 else {
            suggestions = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            do {
                let results = try await placesService.autocomplete(query: query)
                guard !Task.isCancelled else { return }
                suggestions = results
                if results.isEmpty {
                    errorMessage = "No addresses found"
                }
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = "Address lookup unavailable"
                print("[GooglePlaces] autocomplete error: \(error)")
            }
            isSearching = false
        }
    }

    private func selectSuggestion(_ suggestion: PlaceSuggestion) {
        searchTask?.cancel()
        suggestions = []
        isSearching = false
        errorMessage = nil

        Task {
            do {
                let address = try await placesService.placeDetails(placeId: suggestion.placeId)
                hasSelectedPlace = true
                searchText = suggestion.mainText
                street = address.street
                unit = address.unit
                city = address.city
                state = address.state
                zipCode = address.zipCode
                // Keep editing mode so user can see/tweak the filled fields
                isEditing = true
            } catch {
                hasSelectedPlace = true
                searchText = suggestion.mainText
                street = suggestion.mainText
                isEditing = true
                print("[GooglePlaces] placeDetails error: \(error)")
            }
        }
    }
}

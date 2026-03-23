import SwiftUI

/// Address input with Google Places autocomplete suggestions.
/// On selection, auto-fills structured address bindings (street, city, state, zip).
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

    private let placesService = GooglePlacesService.shared

    var body: some View {
        // Search field
        TextField("Start typing an address...", text: $searchText)
            .textContentType(.fullStreetAddress)
            .autocorrectionDisabled()
            .onChange(of: searchText) { _, newValue in
                if hasSelectedPlace {
                    hasSelectedPlace = false
                    return
                }
                debounceSearch(newValue)
            }

        // Suggestions list — rendered as regular Form rows
        if !suggestions.isEmpty {
            ForEach(suggestions) { suggestion in
                Button {
                    selectSuggestion(suggestion)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.mainText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.primary)
                        Text(suggestion.secondaryText)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }

        if isSearching {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Searching...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        if let errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.orange)
        }

        // Filled address fields (editable)
        if !street.isEmpty {
            TextField("Street", text: $street)
            TextField("Unit/Apt (optional)", text: $unit)
            TextField("City", text: $city)
            TextField("State", text: $state)
            TextField("ZIP Code", text: $zipCode)
                .keyboardType(.numberPad)
        }
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
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
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
            } catch {
                // Fall back to just setting the main text as street
                hasSelectedPlace = true
                searchText = suggestion.mainText
                street = suggestion.mainText
                print("[GooglePlaces] placeDetails error: \(error)")
            }
        }
    }
}

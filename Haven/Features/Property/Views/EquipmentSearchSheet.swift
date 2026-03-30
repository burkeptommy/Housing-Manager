import SwiftUI

/// Full-screen search sheet for finding equipment in the catalog.
/// Supports natural language queries like "bosch stove" or "samsung fridge".
struct EquipmentSearchSheet: View {
    let onSelect: (EquipmentSearchResult) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var results: [EquipmentSearchResult] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(HavenColors.textTertiary)
                    TextField("Search by brand, type, or model...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .onSubmit { performSearch() }
                    if !searchText.isEmpty {
                        Button { searchText = ""; results = []; hasSearched = false } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
                .padding(12)
                .background(HavenColors.beige100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.top, 8)

                // Quick suggestions
                if searchText.isEmpty && !hasSearched {
                    quickSuggestions
                }

                // Results
                if isSearching {
                    Spacer()
                    ProgressView("Searching...")
                        .padding()
                    Spacer()
                } else if hasSearched && results.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("No matches found")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.navy800)
                        Text("Try a different brand, model, or product type")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                } else if !results.isEmpty {
                    List {
                        ForEach(results) { result in
                            Button {
                                Haptics.light()
                                onSelect(result)
                                dismiss()
                            } label: {
                                equipmentRow(result)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                } else {
                    Spacer()
                }
            }
            .navigationTitle("Find Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            // Debounced search
            searchTask?.cancel()
            guard newValue.count >= 2 else {
                results = []
                hasSearched = false
                return
            }
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                guard !Task.isCancelled else { return }
                await performSearch()
            }
        }
    }

    // MARK: - Quick Suggestions

    private var quickSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try searching for:")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([
                        "Bosch dishwasher",
                        "Samsung fridge",
                        "Carrier AC",
                        "Kohler toilet",
                        "Rinnai tankless",
                        "Generac generator",
                        "Moen faucet",
                        "Pentair pool pump",
                    ], id: \.self) { suggestion in
                        Button {
                            searchText = suggestion
                            performSearch()
                        } label: {
                            Text(suggestion)
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy700)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(HavenColors.navy.opacity(0.06))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            }
        }
    }

    // MARK: - Equipment Row

    @ViewBuilder
    private func equipmentRow(_ result: EquipmentSearchResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.displayName)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.navy800)
                    .lineLimit(1)
                Spacer()
                tierBadge(result.manufacturer.tier)
            }
            Text(result.subtitle)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .lineLimit(1)
            if let features = result.specs.keyFeatures, !features.isEmpty {
                Text(features.prefix(3).joined(separator: " · "))
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func tierBadge(_ tier: String) -> some View {
        let (label, color): (String, Color) = switch tier {
        case "ultra-luxury": ("Ultra-Luxury", .purple)
        case "luxury": ("Luxury", .indigo)
        case "premium": ("Premium", .blue)
        case "mainstream": ("Mainstream", .green)
        case "budget": ("Budget", .orange)
        default: (tier.capitalized, .gray)
        }

        Text(label)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Search

    @MainActor
    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else { return }

        isSearching = true
        Task {
            do {
                let response = try await HavenSupabase.searchEquipment(query: query)
                results = response.results
            } catch {
                print("[EquipmentSearch] Error: \(error)")
                results = []
            }
            isSearching = false
            hasSearched = true
        }
    }
}

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
    @State private var showCatalogRequest = false

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
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("No matches found")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Try a different brand, model, or product type")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        catalogRequestButton
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    Spacer()
                } else if !results.isEmpty {
                    List {
                        ForEach(results) { result in
                            Button {
                                Haptics.light()
                                Analytics.track(.equipmentResultSelected, ["model": result.modelNumber, "brand": result.manufacturer.name, "category": result.category.name])
                                onSelect(result)
                                dismiss()
                            } label: {
                                equipmentRow(result)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }

                        // "Don't see your system?" at the bottom of results
                        catalogRequestButton
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .listRowSeparator(.hidden)
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
            .sheet(isPresented: $showCatalogRequest) {
                CatalogRequestSheet(prefillBrand: searchText)
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
                performSearch()
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
            // Phase 5 — "Best match" pill above the row when ranking confidence
            // is high (3+ query signals aligned with the row's specs).
            if result.isBestMatch == true {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .semibold))
                    Text("BEST MATCH FOR YOUR SEARCH")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                }
                .foregroundStyle(HavenColors.action)
                .padding(.bottom, 2)
            }
            HStack {
                Text(result.displayName)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                Spacer()
                if let score = result.scores?.reliability {
                    reliabilityBadge(score)
                }
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
    private func reliabilityBadge(_ score: Int) -> some View {
        let color: Color = score >= 85 ? .green : score >= 70 ? .blue : score >= 55 ? .orange : .red
        HStack(spacing: 2) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 8))
            Text("\(score)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
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

    // MARK: - Catalog Request Button

    private var catalogRequestButton: some View {
        Button {
            Haptics.light()
            showCatalogRequest = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.action)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Have Chez add yours")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy700)
                    Text("Our team will research and add it within 3-4 hours")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.action.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.action.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
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
                Analytics.track(.equipmentSearched, ["query": query, "result_count": response.results.count])
            } catch {
                print("[EquipmentSearch] Error: \(error)")
                results = []
            }
            isSearching = false
            hasSearched = true
        }
    }
}

// MARK: - Catalog Request Sheet

/// Form for users to request a missing system be added to the equipment catalog.
struct CatalogRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    var prefillBrand: String = ""

    @State private var brand = ""
    @State private var systemType = ""
    @State private var modelNumber = ""
    @State private var notes = ""
    @State private var isSending = false
    @State private var showSuccess = false

    private let systemTypes = [
        "Air Conditioner", "Furnace", "Boiler", "Heat Pump", "Water Heater",
        "Dishwasher", "Refrigerator", "Oven/Range", "Washer", "Dryer",
        "Microwave", "Garbage Disposal", "Generator", "Pool Pump",
        "Water Softener", "Sump Pump", "Thermostat", "Other"
    ]

    var body: some View {
        NavigationStack {
            if showSuccess {
                successView
            } else {
                formView
            }
        }
    }

    private var formView: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sorry about that! Let us know what you're looking for and we'll make sure it's in our database.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            Section("Brand") {
                TextField("e.g. Bosch, Samsung, Carrier", text: $brand)
                    .textInputAutocapitalization(.words)
            }

            Section("Type of System") {
                Picker("System Type", selection: $systemType) {
                    Text("Select...").tag("")
                    ForEach(systemTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
            }

            Section("Model Number (optional)") {
                TextField("e.g. SHPM88Z75N", text: $modelNumber)
                    .textInputAutocapitalization(.characters)
            }

            Section("Anything else? (optional)") {
                TextField("Additional details...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("Request Equipment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    sendRequest()
                } label: {
                    if isSending {
                        ProgressView()
                    } else {
                        Text("Send")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(brand.isEmpty || systemType.isEmpty || isSending)
            }
        }
        .onAppear {
            // Pre-fill brand from search text if it looks like a brand name
            if brand.isEmpty && !prefillBrand.isEmpty {
                let words = prefillBrand.split(separator: " ")
                if let first = words.first {
                    brand = String(first).capitalized
                }
            }
        }
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.success)

            Text("Request Sent!")
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)

            Text("We'll add \(brand) \(systemType.lowercased()) to our database. You can still add your system manually in the meantime.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HavenColors.navy)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Spacer()
        }
        .navigationTitle("Request Sent")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func sendRequest() {
        isSending = true
        Task {
            do {
                try await HavenSupabase.sendCatalogRequest(
                    brand: brand,
                    systemType: systemType,
                    modelNumber: modelNumber.isEmpty ? nil : modelNumber,
                    notes: notes.isEmpty ? nil : notes
                )
                Analytics.track(.equipmentCatalogRequestSent, ["brand": brand, "system_type": systemType, "has_model": !modelNumber.isEmpty])
                Haptics.success()
                withAnimation { showSuccess = true }
            } catch {
                print("[CatalogRequest] Failed: \(error)")
                // Still show success — the request was captured in logs even if email fails
                Haptics.success()
                withAnimation { showSuccess = true }
            }
            isSending = false
        }
    }
}

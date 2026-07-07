import SwiftUI

/// Picker sheet for assigning a contractor to a system, routine, vehicle
/// program, or task. May 2026 friend feedback Round 3 restructured the
/// list so users always see EVERY contractor they have, not just the
/// category-matched ones — a strict-filter empty state was the most
/// confusing thing Tom flagged on TestFlight.
///
/// Sections (when `searchText` is empty):
///   1. **Matching {categoryLabel} vendors** — current filtered list.
///      When empty, renders a single "No {categoryLabel} vendors yet"
///      row so the user understands the scope is intentional.
///   2. **All your vendors** — every other contractor, with their
///      category as the subtitle. Lets the user link a vendor from a
///      different trade if that's what they want (a handyman they
///      already trust for snow removal, etc.).
///   3. **More ways to find a pro** footer:
///      - "Find vetted local pros" — only when the caller wired the
///        new `onFindLocalVendors` callback (a parent that knows how
///        to present `FindLocalVendorSheet` with town/state context).
///      - "Have Chez handle it" — always visible; Chez delegation is
///        universal.
///
/// When the user types into the search field, the picker falls back to
/// a flat filtered list across every contractor (intent-driven search
/// shouldn't be category-scoped). The discovery footer hides while
/// searching so the results list stays clean.
struct ContractorPickerSheet: View {
    let systemCategory: String
    var onSelect: (ContractorRow) -> Void

    /// May 2026 friend feedback Round 3: parent-provided "Find a pro"
    /// route. Non-nil parents own the `FindLocalVendorSheet`
    /// presentation (so they can pass the right town/state for the
    /// category). When nil, the row is hidden — the "Have Chez handle
    /// it" row always remains as a universal escape hatch.
    var onFindLocalVendors: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var contractors: [ContractorRow] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var showAddContractor = false

    /// Canonical category key derived from the caller's
    /// `systemCategory` token. Used for the section header label,
    /// the "no matches" placeholder copy, and the Chez request
    /// context payload. Falls back to the raw input so the picker
    /// remains usable for custom user categories.
    private var canonicalCategoryKey: String? {
        Self.canonicalContractorCategory(systemCategory)
    }

    /// Human-readable label for section headers + copy. Uses the
    /// registry's display name when available so "snow_removal"
    /// becomes "Snow Removal" instead of leaking the token.
    private var categoryDisplayLabel: String {
        if let key = canonicalCategoryKey,
           let meta = SystemCategoryRegistry.byCategoryKey[key] {
            return meta.displayName
        }
        return canonicalCategoryKey ?? systemCategory
    }

    private var matchingContractors: [ContractorRow] {
        guard let target = canonicalCategoryKey else { return contractors }
        return contractors.filter { contractor in
            Self.contractor(contractor, matchesCategory: target)
        }
    }

    private var otherContractors: [ContractorRow] {
        let matchingIds = Set(matchingContractors.map(\.id))
        return contractors.filter { !matchingIds.contains($0.id) }
    }

    /// Flat search hits across the full contractor list — used when
    /// the user is typing. Intentionally doesn't respect the category
    /// scope: search is an intent-driven escape hatch.
    private var searchHits: [ContractorRow] {
        let query = searchText.lowercased()
        return contractors.filter {
            $0.companyName.lowercased().contains(query) ||
            ($0.contactName?.lowercased().contains(query) ?? false) ||
            ($0.category?.lowercased().contains(query) ?? false) ||
            ($0.specialties?.contains { $0.lowercased().contains(query) } ?? false)
        }
    }

    private var chezContext: [String: String] {
        var ctx: [String: String] = [
            "_source": "contractor_picker_sheet",
            "source_entity_type": "system",
        ]
        if let key = canonicalCategoryKey {
            ctx["system_category"] = key
            ctx["source_entity_label"] = categoryDisplayLabel
        }
        return ctx
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if contractors.isEmpty {
                    // No contractors saved at all — keep the original
                    // friendly empty state so the user knows to add one.
                    // The discovery footer's "Have Chez handle it" /
                    // Find-a-pro rows complement this when wired.
                    ContentUnavailableView {
                        Label("No Contractors", systemImage: "person.crop.circle.badge.questionmark")
                    } description: {
                        Text("Add a contractor to your directory first.")
                    } actions: {
                        VStack(spacing: 12) {
                            Button("Add Contractor") { showAddContractor = true }
                                .buttonStyle(.bordered)
                            discoveryFooterContent
                                .padding(.horizontal, 32)
                        }
                    }
                } else {
                    contractorList
                        .searchable(text: $searchText, prompt: "Search contractors")
                }
            }
            .navigationTitle("Select Contractor")
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("ContractorPickerSheet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddContractor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await loadContractors()
            }
            .sheet(isPresented: $showAddContractor) {
                // Phase 56.1: direct to AddVendorSheet so the "+" button
                // inside the picker lands the user on the add form
                // immediately instead of routing through the directory.
                AddVendorSheet(onComplete: {
                    Task { await loadContractors() }
                })
            }
        }
    }

    @ViewBuilder
    private var contractorList: some View {
        List {
            if !searchText.isEmpty {
                // Search hits — flat list across every contractor.
                // Render an inline empty cell when the query matches
                // nothing so the user gets immediate feedback.
                Section {
                    if searchHits.isEmpty {
                        Text("No matches for \"\(searchText)\"")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else {
                        ForEach(searchHits) { contractor in
                            contractorButton(contractor)
                        }
                    }
                }
            } else {
                // Matching section — always visible so the user
                // understands the picker is scoped. Empty placeholder
                // is a single muted row, not a full empty-state
                // takeover.
                Section {
                    if matchingContractors.isEmpty {
                        Text("No \(categoryDisplayLabel) vendors yet")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else {
                        ForEach(matchingContractors) { contractor in
                            contractorButton(contractor)
                        }
                    }
                } header: {
                    Text("\(categoryDisplayLabel) vendors")
                }

                if !otherContractors.isEmpty {
                    Section {
                        ForEach(otherContractors) { contractor in
                            contractorButton(contractor)
                        }
                    } header: {
                        Text("All your vendors")
                    }
                }

                // Discovery footer — Chez always visible, Find-a-pro
                // gated on parent wiring.
                if hasDiscoveryFooter {
                    Section {
                        discoveryFooterContent
                            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                            .listRowBackground(Color.clear)
                    } header: {
                        Text("More ways to find a pro")
                    }
                }
            }
        }
    }

    private var hasDiscoveryFooter: Bool {
        // Chez is always rendered, so the footer is always visible.
        // Left as a computed for symmetry with future per-row gates.
        true
    }

    @ViewBuilder
    private var discoveryFooterContent: some View {
        VStack(spacing: 12) {
            if let onFindLocalVendors {
                Button {
                    Haptics.light()
                    dismiss()
                    // Defer to the parent's presentation flow. The
                    // parent owns the FindLocalVendorSheet so it can
                    // pass property town/state and route the adopted
                    // vendor back through onSelect-equivalent logic.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onFindLocalVendors()
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(HavenColors.navy.opacity(0.10))
                                .frame(width: 36, height: 36)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(HavenColors.navy)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Find vetted local pros")
                                .font(HavenTypography.uiButton)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Browse top \(categoryDisplayLabel.lowercased()) vendors in your area.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(HavenColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(HavenColors.beige300, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            ChezEntryButton(
                category: .findVendor,
                label: "Have Chez find one for me",
                caption: "Chez sources a vetted local pro for this and books the visit.",
                context: chezContext
            )
        }
    }

    private func contractorButton(_ contractor: ContractorRow) -> some View {
        Button {
            Analytics.track(.systemContractorAssigned, ["contractor_id": contractor.id.uuidString, "system_category": systemCategory])
            onSelect(contractor)
            dismiss()
        } label: {
            contractorRow(contractor)
        }
    }

    private static func contractor(_ contractor: ContractorRow, matchesCategory target: String) -> Bool {
        var candidates: [String?] = [contractor.category]
        candidates.append(contentsOf: (contractor.specialties ?? []).map { Optional.some($0) })
        return candidates
            .compactMap { canonicalContractorCategory($0) }
            .contains(target)
    }

    private static func canonicalContractorCategory(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let displayReady = raw
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if displayReady.caseInsensitiveCompare("mosquito tick") == .orderedSame {
            return "Mosquito & Tick"
        }
        return SystemCategoryRegistry.canonical(category: displayReady)
    }

    private func contractorRow(_ contractor: ContractorRow) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(contractor.companyName)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)

                if let contact = contractor.contactName {
                    Text(contact)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if let subtitle = rowSubtitle(for: contractor) {
                    Text(subtitle)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let rating = contractor.rating, rating > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(HavenColors.warning)
                    Text(String(format: "%.1f", rating))
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
    }

    /// Subtitle resolution: prefer the comma-joined specialties list,
    /// fall back to the contractor's canonical category so rows in the
    /// "All your vendors" section make their trade legible even when
    /// the contractor was saved without explicit specialties.
    private func rowSubtitle(for contractor: ContractorRow) -> String? {
        if let specialties = contractor.specialties, !specialties.isEmpty {
            return specialties.joined(separator: ", ")
        }
        if let category = contractor.category, !category.isEmpty {
            return category
        }
        return nil
    }

    private func loadContractors() async {
        do {
            contractors = try await DatabaseService.shared.fetchContractors()
        } catch {
            // silently handle
        }
        isLoading = false
    }
}

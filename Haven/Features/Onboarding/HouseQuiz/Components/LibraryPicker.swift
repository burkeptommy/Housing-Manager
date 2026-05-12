import SwiftUI

/// Phase 1.2: Generic searchable library picker.
///
/// Used by Q15b "Anything else?" and Q10 "Anything else?" affordances
/// to surface categories from SystemCategoryRegistry (or any registry)
/// that aren't already on the question's static chip list.
///
/// Forward-compatible: any new category added to the source registry
/// flows through automatically.
struct LibraryEntry: Identifiable, Hashable {
    let id: String              // canonical key (e.g. "Wine Cellar")
    let label: String           // human-readable display name
    let icon: String            // SF Symbol name
    let category: String        // category key (often same as id)
    let tier: String?           // optional tier/grouping label for sort
    let subtitle: String?       // optional secondary label

    init(
        id: String,
        label: String,
        icon: String,
        category: String,
        tier: String? = nil,
        subtitle: String? = nil
    ) {
        self.id = id
        self.label = label
        self.icon = icon
        self.category = category
        self.tier = tier
        self.subtitle = subtitle
    }
}

struct LibraryPicker: View {
    let entries: [LibraryEntry]
    let title: String
    let searchPlaceholder: String
    let onSelect: (LibraryEntry) -> Void
    let onDismiss: () -> Void

    @State private var query: String = ""
    @FocusState private var searchFocused: Bool

    private var filtered: [LibraryEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries }
        let needle = trimmed.lowercased()
        return entries.filter { entry in
            entry.label.lowercased().contains(needle)
                || entry.id.lowercased().contains(needle)
                || (entry.subtitle?.lowercased().contains(needle) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                Divider()
                if filtered.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Haptics.light()
                        onDismiss()
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
        .onAppear {
            searchFocused = true
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(HavenColors.textSecondary)
            TextField(searchPlaceholder, text: $query)
                .focused($searchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.vertical, 12)
        .background(HavenColors.surface)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(HavenColors.textTertiary)
            Text("Nothing matches that yet.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filtered) { entry in
                    Button {
                        Haptics.light()
                        onSelect(entry)
                    } label: {
                        row(for: entry)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 56)
                }
            }
            .padding(.bottom, 24)
        }
    }

    private func row(for entry: LibraryEntry) -> some View {
        HStack(spacing: 14) {
            Image(systemName: entry.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(HavenColors.navy800)
                .frame(width: 28, height: 28)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.label)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                if let subtitle = entry.subtitle {
                    Text(subtitle)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#if DEBUG
#Preview {
    LibraryPicker(
        entries: [
            LibraryEntry(id: "Wine Cellar", label: "Wine cellar", icon: "wineglass.fill", category: "Wine Cellar"),
            LibraryEntry(id: "Pressure Washing", label: "Pressure washing", icon: "drop.fill", category: "Pressure Washing"),
            LibraryEntry(id: "Driveway Sealcoating", label: "Driveway sealcoating", icon: "road.lanes", category: "Driveway Sealcoating"),
            LibraryEntry(id: "Window Cleaning", label: "Window cleaning", icon: "window.casement", category: "Window Cleaning"),
            LibraryEntry(id: "Tree Service", label: "Tree service", icon: "tree.fill", category: "Tree Service"),
        ],
        title: "Add another vendor",
        searchPlaceholder: "Search categories",
        onSelect: { entry in print("Selected: \(entry.label)") },
        onDismiss: { print("Cancelled") }
    )
}
#endif

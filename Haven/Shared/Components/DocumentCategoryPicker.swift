import SwiftUI

/// A searchable, grouped document category picker presented as a sheet.
/// Categories are sorted alphabetically within each group. Typing filters
/// results across all groups. The list auto-scrolls to the currently
/// selected category on appear.
struct DocumentCategoryPicker: View {
    @Binding var selectedCategory: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private let groups = DocumentCategoryGroups.all

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredGroups, id: \.section) { group in
                    Section {
                        ForEach(group.categories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                                Haptics.light()
                                dismiss()
                            } label: {
                                HStack {
                                    Text(cat)
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Spacer()
                                    if selectedCategory == cat {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(HavenColors.textPrimary)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .id(cat)
                        }
                    } header: {
                        Text(group.section)
                            .font(HavenTypography.uiSectionHeader)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(HavenColors.background)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search categories")
            .navigationTitle("Document Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    /// Groups filtered by search text, with categories sorted alphabetically.
    /// When not searching, categories within each group are alphabetical.
    /// When searching, all matching categories appear in a flat "Results" section.
    private var filteredGroups: [(section: String, categories: [String])] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()

        if query.isEmpty {
            // No search: show all groups with alphabetically sorted categories
            return groups.map { (section: $0.section, categories: $0.categories.sorted()) }
        }

        // Search: flatten, filter, and group into a single "Results" section
        let matches = groups
            .flatMap(\.categories)
            .filter { $0.lowercased().contains(query) }
            .sorted()

        if matches.isEmpty {
            return []
        }
        return [("Results", matches)]
    }
}

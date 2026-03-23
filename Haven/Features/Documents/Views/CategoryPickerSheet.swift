import SwiftUI

struct CategoryPickerSheet: View {
    @Binding var selectedCategory: DocumentCategory
    var onSelect: ((DocumentCategory) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredGroups: [(String, [DocumentCategory])] {
        if searchText.isEmpty {
            return DocumentCategory.groupedCategories
        }
        let query = searchText.lowercased()
        return DocumentCategory.groupedCategories.compactMap { group, categories in
            let filtered = categories.filter { $0.rawValue.lowercased().contains(query) }
            return filtered.isEmpty ? nil : (group, filtered)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredGroups, id: \.0) { group, categories in
                    Section(group) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                                onSelect?(cat)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(cat.rawValue)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Spacer()
                                    if cat == selectedCategory {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(HavenColors.navy)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search categories")
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

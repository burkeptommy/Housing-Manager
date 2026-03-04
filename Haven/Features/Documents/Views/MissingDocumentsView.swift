import SwiftUI

struct MissingDocumentsView: View {
    let missingCategories: [DocumentCategory]
    var onUpload: ((DocumentCategory) -> Void)?
    @Environment(\.dismiss) private var dismiss

    private var groupedMissing: [(String, [DocumentCategory])] {
        let groups = Dictionary(grouping: missingCategories) { $0.sectionGroup }
        let order = ["Estate Planning", "Entity Documents", "Real Estate", "Insurance",
                     "Financial Accounts", "Tax Records", "Personal Property",
                     "Digital Assets", "Personal Identification", "Professional & Business"]
        return order.compactMap { key in
            guard let values = groups[key], !values.isEmpty else { return nil }
            return (key, values)
        }
    }

    var body: some View {
        Group {
            if missingCategories.isEmpty {
                ContentUnavailableView {
                    Label("All Categories Covered", systemImage: "checkmark.seal.fill")
                } description: {
                    Text("You have at least one document in every category. Great work!")
                }
            } else {
                List {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(missingCategories.count) categories without documents")
                                    .font(.headline)
                                Text("Upload documents to improve your estate readiness score.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    ForEach(groupedMissing, id: \.0) { group, categories in
                        Section(group) {
                            ForEach(categories, id: \.self) { cat in
                                HStack {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.red.opacity(0.6))
                                    Text(cat.rawValue)
                                        .font(.subheadline)
                                    Spacer()
                                    Button {
                                        onUpload?(cat)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(Color.havenAccent)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Missing Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MissingDocumentsView(missingCategories: [.will, .trust, .passport])
    }
}

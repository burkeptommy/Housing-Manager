import SwiftUI

/// Sheet for linking an existing document from the vault to a project.
struct LinkDocumentToProjectSheet: View {
    let projectId: UUID
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var documents: [DocumentRow] = []
    @State private var isLoading = true
    @State private var searchText = ""

    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if filteredDocuments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("No unlinked documents found")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredDocuments) { doc in
                    Button {
                        Task {
                            await viewModel.linkDocumentToProject(documentId: doc.id, projectId: projectId)
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(HavenColors.navy)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.title)
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Text(doc.category)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            Spacer()
                            Image(systemName: "link.badge.plus")
                                .font(.caption)
                                .foregroundStyle(HavenColors.navy)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search documents")
        .navigationTitle("Link Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .task {
            do {
                // Fetch all documents without a project link
                let allDocs = try await DatabaseService.shared.fetchDocuments()
                documents = allDocs.filter { $0.projectId == nil && $0.deletedAt == nil }
            } catch {
                print("[LinkDoc] Failed to load documents: \(error)")
            }
            isLoading = false
        }
    }

    private var filteredDocuments: [DocumentRow] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty { return documents }
        return documents.filter {
            $0.title.lowercased().contains(query) || $0.category.lowercased().contains(query)
        }
    }
}

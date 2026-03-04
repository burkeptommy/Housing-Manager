import SwiftUI

struct DocumentCategoryView: View {
    let category: DocumentCategory
    @EnvironmentObject var vaultViewModel: DocumentVaultViewModel
    @State private var showUpload = false

    private var documents: [DocumentRow] {
        vaultViewModel.documentsForCategory(category)
    }

    var body: some View {
        Group {
            if documents.isEmpty {
                ContentUnavailableView {
                    Label("No \(category.rawValue)", systemImage: "doc")
                } description: {
                    Text("Upload a \(category.rawValue.lowercased()) document to track it in your vault.")
                } actions: {
                    Button {
                        showUpload = true
                    } label: {
                        Text("Upload Document")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    Section {
                        ForEach(documents) { doc in
                            NavigationLink {
                                DocumentDetailView(documentID: doc.id)
                            } label: {
                                DocumentCard(document: doc)
                            }
                        }
                    } header: {
                        HStack {
                            Text("\(documents.count) document\(documents.count == 1 ? "" : "s")")
                            Spacer()
                            Text(category.sectionGroup)
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(category.rawValue)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showUpload = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showUpload) {
            DocumentUploadView(
                preselectedCategory: category,
                onComplete: {
                    Task { await vaultViewModel.loadData() }
                }
            )
        }
    }
}

#Preview {
    NavigationStack {
        DocumentCategoryView(category: .will)
            .environmentObject(DocumentVaultViewModel())
    }
}

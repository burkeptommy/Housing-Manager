import SwiftUI

struct PropertyDocumentsView: View {
    let propertyId: UUID
    let propertyName: String

    @State private var documents: [DocumentRow] = []
    @State private var isLoading = true
    @State private var showUpload = false
    @State private var searchText = ""

    private let db = DatabaseService.shared

    private var filteredDocuments: [DocumentRow] {
        if searchText.isEmpty { return documents }
        return documents.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText) ||
            ($0.notes ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedDocuments: [(String, [DocumentRow])] {
        let grouped = Dictionary(grouping: filteredDocuments) { $0.category }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading documents...")
            } else if documents.isEmpty {
                emptyState
            } else {
                documentList
            }
        }
        .navigationTitle("\(propertyName) Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.light()
                    showUpload = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(HavenColors.navy)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search documents...")
        .task { await loadDocuments() }
        .refreshable { await loadDocuments() }
        .sheet(isPresented: $showUpload) {
            DocumentUploadView(preselectedPropertyId: propertyId) {
                Task { await loadDocuments() }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Button {
                Haptics.light()
                showUpload = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.textTertiary)

                    Text("No Documents Yet")
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.textPrimary)

                    Text("Upload deeds, insurance policies, blueprints, renovation quotes, inspection reports, and anything else related to your home.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 13))
                        Text("Tap to upload")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.navy)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 32)
            }
            .buttonStyle(.plain)

            // Suggested categories
            VStack(alignment: .leading, spacing: 8) {
                Text("SUGGESTED")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                let suggestions = [
                    ("Deed", "doc.text.fill"),
                    ("Homeowners Insurance", "shield.fill"),
                    ("Mortgage", "building.columns.fill"),
                    ("Home Inspection", "magnifyingglass"),
                    ("Blueprints / Floor Plans", "ruler.fill"),
                    ("Renovation Quotes", "hammer.fill"),
                    ("HOA Documents", "building.2.fill"),
                ]

                ForEach(suggestions, id: \.0) { title, icon in
                    Button {
                        Haptics.light()
                        showUpload = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .font(.system(size: 14))
                                .foregroundStyle(HavenColors.navy700)
                                .frame(width: 24)
                            Text(title)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                            Image(systemName: "plus.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .padding(.horizontal)

            Spacer()
        }
    }

    private var documentList: some View {
        ScrollView {
            LazyVStack(spacing: HavenTheme.spacing16) {
                // Summary
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(documents.count)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(HavenColors.navy800)
                        Text("Documents")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    Spacer()

                    Button {
                        Haptics.light()
                        showUpload = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Upload")
                                .font(HavenTypography.uiLabel)
                        }
                        .foregroundStyle(HavenColors.textOnNavy)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(HavenColors.navy)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                }
                .padding(.horizontal, HavenTheme.spacing16)

                // Grouped by category
                ForEach(groupedDocuments, id: \.0) { category, docs in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.uppercased())
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(.horizontal, HavenTheme.spacing16)

                        ForEach(docs) { doc in
                            NavigationLink {
                                DocumentDetailView(documentID: doc.id)
                            } label: {
                                HavenCard {
                                    HStack(spacing: 12) {
                                        Image(systemName: documentIcon(for: doc.category))
                                            .font(.system(size: 16))
                                            .foregroundStyle(HavenColors.navy700)
                                            .frame(width: 32, height: 32)
                                            .background(HavenColors.navy.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(doc.title)
                                                .font(HavenTypography.uiLabel)
                                                .foregroundStyle(HavenColors.textPrimary)
                                                .lineLimit(1)
                                            HStack(spacing: 6) {
                                                if let date = doc.uploadedAt {
                                                    Text("Added \(date, style: .date)")
                                                        .font(HavenTypography.uiCaption)
                                                        .foregroundStyle(HavenColors.textTertiary)
                                                }
                                                if let exp = doc.expirationDate {
                                                    Text("Expires \(exp.havenDateShort)")
                                                        .font(HavenTypography.uiCaption)
                                                        .foregroundStyle(HavenColors.warning)
                                                }
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(HavenColors.textTertiary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, HavenTheme.spacing16)
                        }
                    }
                }
            }
            .padding(.vertical, HavenTheme.spacing16)
        }
        .background(HavenColors.background)
    }

    private func documentIcon(for category: String) -> String {
        switch category.lowercased() {
        case let c where c.contains("deed"): return "doc.text.fill"
        case let c where c.contains("insurance"): return "shield.fill"
        case let c where c.contains("mortgage"): return "building.columns.fill"
        case let c where c.contains("blueprint"), let c where c.contains("floor plan"): return "ruler.fill"
        case let c where c.contains("inspection"): return "magnifyingglass"
        case let c where c.contains("tax"): return "dollarsign.circle.fill"
        case let c where c.contains("hoa"): return "building.2.fill"
        case let c where c.contains("quote"): return "hammer.fill"
        case let c where c.contains("warranty"): return "shield.lefthalf.filled"
        case let c where c.contains("permit"): return "checkmark.seal.fill"
        default: return "doc.fill"
        }
    }

    private func loadDocuments() async {
        isLoading = true
        documents = ((try? await db.fetchDocuments()) ?? []).filter { $0.propertyId == propertyId }
        isLoading = false
    }
}

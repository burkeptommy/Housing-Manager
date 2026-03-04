import SwiftUI

struct DocumentVaultView: View {
    @StateObject private var viewModel = DocumentVaultViewModel()
    @State private var showUpload = false
    @State private var showMissing = false
    @State private var showGapAnalysis = false
    @State private var expandedSections: Set<String> = []

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.documents.isEmpty {
                    ScrollView {
                        VStack(spacing: HavenTheme.spacing16) {
                            SkeletonScorecard()
                            SkeletonCard()
                            SkeletonCard(lineCount: 4)
                            SkeletonCard(lineCount: 4)
                        }
                        .padding()
                    }
                    .background(HavenColors.background)
                } else if viewModel.documents.isEmpty && viewModel.searchText.isEmpty {
                    EmptyStateView(
                        title: "No Documents Yet",
                        message: "Upload your first document to start building your estate vault. We'll help you identify what's missing.",
                        icon: "doc.badge.plus",
                        actionTitle: "Upload Document",
                        action: { showUpload = true }
                    )
                } else {
                    documentList
                }
            }
            .navigationTitle("Document Vault")
            .searchable(text: $viewModel.searchText, prompt: "Search documents...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Haptics.light()
                            showUpload = true
                        } label: {
                            Label("Upload Document", systemImage: "doc.badge.plus")
                        }
                        Button {
                            Haptics.light()
                            showMissing = true
                        } label: {
                            Label("Missing Documents", systemImage: "exclamationmark.triangle")
                        }
                        Button {
                            Haptics.light()
                            showGapAnalysis = true
                        } label: {
                            Label("Gap Analysis", systemImage: "chart.bar.doc.horizontal")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Document actions")
                }
            }
            .refreshable {
                Haptics.light()
                await viewModel.loadData()
            }
            .task {
                if viewModel.documents.isEmpty {
                    await viewModel.loadData()
                }
            }
            .sheet(isPresented: $showUpload) {
                DocumentUploadView(onComplete: {
                    Haptics.success()
                    Task { await viewModel.loadData() }
                })
            }
            .sheet(isPresented: $showMissing) {
                NavigationStack {
                    MissingDocumentsView(
                        missingCategories: viewModel.missingCategories,
                        onUpload: { _ in
                            showMissing = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showUpload = true
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showGapAnalysis) {
                NavigationStack {
                    GapAnalysisView()
                }
            }
        }
    }

    // MARK: - Document List

    private var documentList: some View {
        ScrollView {
            LazyVStack(spacing: HavenTheme.spacing16) {
                completionHeader

                if !viewModel.expiringDocuments.isEmpty {
                    expiringAlert
                }

                if viewModel.filterStatus != nil || viewModel.filterCategory != nil {
                    filterBar
                }

                ForEach(viewModel.sectionGroups, id: \.0) { groupName, categories in
                    sectionGroupView(groupName: groupName, categories: categories)
                }
            }
            .padding(.horizontal, HavenTheme.spacing16)
            .padding(.top, HavenTheme.spacing8)
            .padding(.bottom, HavenTheme.spacing32)
        }
        .background(HavenColors.background)
    }

    // MARK: - Completion Header

    private var completionHeader: some View {
        HavenCard {
            HStack {
                VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
                    Text("Estate Readiness")
                        .font(HavenTypography.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(Int(viewModel.completionPercentage * 100))%")
                        .font(HavenTypography.statNumber)
                        .foregroundStyle(Color.havenAccent)
                        .contentTransition(.numericText(value: viewModel.completionPercentage))
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.havenAccent.opacity(0.12), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: viewModel.completionPercentage)
                        .stroke(Color.havenAccent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: viewModel.completionPercentage)
                    Text("\(viewModel.totalDocumentCount)")
                        .font(HavenTypography.title3)
                }
                .frame(width: 64, height: 64)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Estate readiness \(Int(viewModel.completionPercentage * 100)) percent, \(viewModel.totalDocumentCount) documents uploaded")

            HStack(spacing: HavenTheme.spacing16) {
                statPill(icon: "doc.fill", value: "\(viewModel.totalDocumentCount)", label: "Uploaded")
                statPill(icon: "exclamationmark.triangle", value: "\(viewModel.missingCategories.count)", label: "Missing")
                statPill(icon: "clock", value: "\(viewModel.expiringDocuments.count)", label: "Expiring")
            }
        }
    }

    private func statPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(HavenTypography.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(HavenTypography.subheadline)
                    .fontWeight(.bold)
                    .monospacedDigit()
                Text(label)
                    .font(HavenTypography.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Expiring Alert

    private var expiringAlert: some View {
        HavenCard {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(Color.havenWarning)
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.expiringDocuments.count) document\(viewModel.expiringDocuments.count == 1 ? "" : "s") expiring soon")
                        .font(HavenTypography.subheadline)
                        .fontWeight(.medium)
                    Text("Review and renew before they expire")
                        .font(HavenTypography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.expiringDocuments.count) documents expiring soon")
    }

    // MARK: - Filters

    private var filterBar: some View {
        HStack {
            if viewModel.filterCategory != nil {
                filterChip(label: viewModel.filterCategory!.rawValue) {
                    Haptics.light()
                    viewModel.filterCategory = nil
                }
            }
            if let status = viewModel.filterStatus {
                filterChip(label: status.capitalized) {
                    Haptics.light()
                    viewModel.filterStatus = nil
                }
            }
            Spacer()
            Button("Clear All") {
                Haptics.light()
                viewModel.clearFilters()
            }
            .font(HavenTypography.caption)
        }
    }

    private func filterChip(label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: HavenTheme.spacing4) {
            Text(label)
                .font(HavenTypography.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
            .accessibilityLabel("Remove \(label) filter")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.havenAccent.opacity(0.12))
        .foregroundStyle(Color.havenAccent)
        .clipShape(Capsule())
    }

    // MARK: - Section Groups

    private func sectionGroupView(groupName: String, categories: [(DocumentCategory, [DocumentRow])]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                Haptics.light()
                withAnimation(HavenTheme.animationStandard) {
                    if expandedSections.contains(groupName) {
                        expandedSections.remove(groupName)
                    } else {
                        expandedSections.insert(groupName)
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(groupName)
                            .font(HavenTypography.headline)
                            .foregroundStyle(.primary)
                        let totalDocs = categories.reduce(0) { $0 + $1.1.count }
                        let filledCats = categories.filter { !$0.1.isEmpty }.count
                        Text("\(totalDocs) doc\(totalDocs == 1 ? "" : "s") \u{2022} \(filledCats)/\(categories.count) categories")
                            .font(HavenTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(expandedSections.contains(groupName) ? 90 : 0))
                }
                .padding(.vertical, HavenTheme.spacing8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(groupName)
            .accessibilityHint(expandedSections.contains(groupName) ? "Collapse section" : "Expand section")

            if expandedSections.contains(groupName) {
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(categories, id: \.0) { category, docs in
                        NavigationLink {
                            DocumentCategoryView(category: category)
                                .environmentObject(viewModel)
                        } label: {
                            categoryRow(category: category, docs: docs)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, HavenTheme.spacing4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .havenShadow()
    }

    private func categoryRow(category: DocumentCategory, docs: [DocumentRow]) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: docs.isEmpty ? "circle" : "checkmark.circle.fill")
                .foregroundStyle(docs.isEmpty ? Color.secondary : Color.havenSuccess)
                .font(.body)
                .accessibilityHidden(true)

            Text(category.rawValue)
                .font(HavenTypography.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            if !docs.isEmpty {
                Text("\(docs.count)")
                    .font(HavenTypography.badgeLabel)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.havenAccent.opacity(0.12))
                    .foregroundStyle(Color.havenAccent)
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue), \(docs.count) documents")
    }
}

#Preview {
    DocumentVaultView()
}

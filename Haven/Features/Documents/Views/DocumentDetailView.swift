import SwiftUI
import PDFKit
import QuickLook

struct DocumentDetailView: View {
    let documentID: UUID
    @StateObject private var viewModel = DocumentDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showPreview = false
    @State private var editingNotes = false
    @State private var notesText = ""

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading document...")
            } else if let doc = viewModel.document {
                documentContent(doc)
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
            }
        }
        .navigationTitle(viewModel.document?.title ?? "Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task { await viewModel.markReviewed() }
                    } label: {
                        Label("Mark Reviewed", systemImage: "checkmark.circle")
                    }
                    Button {
                        Task { await viewModel.requestAIAnalysis() }
                    } label: {
                        Label("Run AI Analysis", systemImage: "sparkles")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadDocument(id: documentID)
        }
        .confirmationDialog("Delete Document?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deleteDocument() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This will permanently delete this document and its file. This cannot be undone.")
        }
        .quickLookPreview($viewModel.signedURL)
        .screenshotProtected()
        .alert("Critical Issue Detected", isPresented: $viewModel.showCriticalFlagAlert) {
            Button("OK") {}
        } message: {
            if let flags = viewModel.analysisResult?.criticalFlags, let first = flags.first {
                Text(first.message)
            } else {
                Text("AI analysis found a critical issue with this document. Review the flags below.")
            }
        }
    }

    private func documentContent(_ doc: DocumentRow) -> some View {
        ScrollView {

            LazyVStack(alignment: .leading, spacing: 16) {
                // File preview thumbnail
                filePreviewCard(doc)

                // Status and dates
                metadataCard(doc)

                // AI Summary
                if let summary = doc.aiSummary, !summary.isEmpty {
                    aiSummaryCard(summary)
                } else {
                    aiPromptCard
                }

                // AI Flags
                if let flags = doc.aiFlags, !flags.isEmpty {
                    aiFlagsCard(flags)
                }

                // Family members
                if !viewModel.familyMembers.isEmpty {
                    familyMembersCard
                }

                // Linked property
                if let property = viewModel.property {
                    propertyCard(property)
                }

                // Notes
                notesCard(doc)

                // Tags
                if let tags = doc.tags, !tags.isEmpty {
                    tagsCard(tags)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func filePreviewCard(_ doc: DocumentRow) -> some View {
        HavenCard {
            Button {
                showPreview = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: fileIcon(for: doc.filePath))
                        .font(.largeTitle)
                        .foregroundStyle(Color.havenAccent)
                        .frame(width: 60, height: 60)
                        .background(Color.havenAccent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(doc.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(doc.category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Tap to preview")
                            .font(.caption)
                            .foregroundStyle(Color.havenAccent)
                    }
                    Spacer()
                    Image(systemName: "eye.fill")
                        .foregroundStyle(Color.havenAccent)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func metadataCard(_ doc: DocumentRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.secondary)
                    Text("Details")
                        .font(.headline)
                }

                metadataRow("Status", value: doc.status.capitalized, color: statusColor(doc.status))
                metadataRow("Category", value: doc.category)

                if let inst = doc.issuingInstitution, !inst.isEmpty {
                    metadataRow("Issuing Institution", value: inst)
                }
                if let acct = doc.accountNumberLast4, !acct.isEmpty {
                    metadataRow("Account", value: "****\(acct)")
                }
                if let eff = doc.effectiveDate {
                    metadataRow("Effective Date", value: formatDateString(eff))
                }
                if let exp = doc.expirationDate {
                    metadataRow("Expiration", value: formatDateString(exp))
                }
                if let ren = doc.renewalDate {
                    metadataRow("Renewal Date", value: formatDateString(ren))
                }
                if let uploaded = doc.uploadedAt {
                    metadataRow("Uploaded", value: uploaded.formatted(date: .abbreviated, time: .shortened))
                }
                if let reviewed = doc.lastReviewedAt {
                    metadataRow("Last Reviewed", value: reviewed.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
    }

    private func metadataRow(_ label: String, value: String, color: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if let color {
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(color)
            } else {
                Text(value)
                    .font(.subheadline)
            }
        }
    }

    private func aiSummaryCard(_ summary: String) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text("AI Summary")
                        .font(.headline)
                    Spacer()
                    if viewModel.isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await viewModel.requestAIAnalysis() }
                } label: {
                    Label("Re-analyze", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
            }
        }
    }

    private var aiPromptCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text("AI Analysis")
                        .font(.headline)
                }

                Text("Run AI analysis to get a summary, detect issues, and identify cross-references with other documents.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await viewModel.requestAIAnalysis() }
                } label: {
                    HStack {
                        if viewModel.isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Analyzing...")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Analyze Document")
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.purple.opacity(0.12))
                    .foregroundStyle(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.isAnalyzing)
            }
        }
    }

    private func aiFlagsCard(_ flags: [AIFlag]) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.havenWarning)
                    Text("AI Flags")
                        .font(HavenTypography.headline)
                }

                ForEach(flags) { flag in
                    HStack(alignment: .top, spacing: HavenTheme.spacing8) {
                        Image(systemName: flagIcon(flag.severity))
                            .foregroundStyle(flagColor(flag.severity))
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(flag.severity.capitalized)
                                .font(HavenTypography.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(flagColor(flag.severity))
                            Text(flag.message)
                                .font(HavenTypography.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, HavenTheme.spacing4)
                }
            }
        }
    }

    private func flagIcon(_ severity: String) -> String {
        switch severity {
        case "critical": return "xmark.circle.fill"
        case "warning": return "exclamationmark.triangle.fill"
        default: return "info.circle.fill"
        }
    }

    private func flagColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return Color.havenCritical
        case "warning": return Color.havenWarning
        default: return Color.havenInfo
        }
    }

    private var familyMembersCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.blue)
                    Text("Family Members")
                        .font(.headline)
                }

                ForEach(viewModel.familyMembers) { member in
                    HStack(spacing: 10) {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text("\(member.firstName) \(member.lastName)")
                                .font(.subheadline.weight(.medium))
                            Text(member.relationship)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func propertyCard(_ property: PropertyRow) -> some View {
        HavenCard {
            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Linked Property")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(property.name)
                        .font(.subheadline.weight(.medium))
                    if let street = property.street {
                        Text(street)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
    }

    private func notesCard(_ doc: DocumentRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundStyle(.secondary)
                    Text("Notes")
                        .font(.headline)
                    Spacer()
                    Button(editingNotes ? "Save" : "Edit") {
                        if editingNotes {
                            Task { await viewModel.updateNotes(notesText) }
                        } else {
                            notesText = doc.notes ?? ""
                        }
                        editingNotes.toggle()
                    }
                    .font(.subheadline)
                }

                if editingNotes {
                    TextEditor(text: $notesText)
                        .frame(minHeight: 80)
                        .font(.subheadline)
                } else {
                    Text(doc.notes?.isEmpty == false ? doc.notes! : "No notes added.")
                        .font(.subheadline)
                        .foregroundStyle(doc.notes?.isEmpty == false ? .primary : .secondary)
                }
            }
        }
    }

    private func tagsCard(_ tags: [String]) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(.orange)
                    Text("Tags")
                        .font(.headline)
                }

                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.12))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func fileIcon(for path: String) -> String {
        if path.hasSuffix(".pdf") { return "doc.richtext.fill" }
        if path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") || path.hasSuffix(".png") { return "photo.fill" }
        return "doc.fill"
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "active": return .green
        case "expired": return .red
        case "expiringSoon": return .orange
        case "needsReview": return .yellow
        default: return .secondary
        }
    }

    private func formatDateString(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < result.positions.count else { break }
            subview.place(at: CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            ), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}

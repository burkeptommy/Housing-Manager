import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    var preselectedCategory: DocumentCategory?
    var preselectedPropertyId: UUID?
    var onComplete: (() -> Void)?

    @StateObject private var viewModel = DocumentUploadViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showFileImporter = false
    @State private var showCategoryPicker = false
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isBatchMode && !viewModel.isUploading {
                    batchResultsView
                } else if viewModel.isUploading && viewModel.isBatchMode {
                    batchUploadingView
                } else if viewModel.isUploading {
                    uploadingView
                } else if let result = viewModel.analysisResult {
                    resultsView(result)
                } else {
                    sourceSelectionView
                }
            }
            .navigationTitle("Upload Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .trackScreen("DocumentUploadView")
            .task {
                Analytics.track(.documentUploadStarted, ["has_preselected_category": preselectedCategory != nil])
                await viewModel.loadReferenceData()
                if let cat = preselectedCategory {
                    viewModel.setCategory(cat)
                }
                if let propId = preselectedPropertyId {
                    viewModel.selectedPropertyId = propId
                }
            }
            .sheet(isPresented: $viewModel.showScanner) {
                DocumentScannerView { images in
                    viewModel.handleScannedImages(images)
                    startAutoUpload()
                }
            }
            .photosPicker(
                isPresented: $viewModel.showPhotoPicker,
                selection: $selectedPhotoItems,
                maxSelectionCount: 20,
                matching: .images
            )
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf, .image, .jpeg, .png],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .onChange(of: selectedPhotoItems) { _, items in
                guard !items.isEmpty else { return }

                if items.count == 1, let item = items.first {
                    // Single photo — use existing flow
                    handlePhotoSelection(item)
                } else {
                    // Multiple photos — background upload
                    Task {
                        var files: [PendingUploadFile] = []
                        for item in items {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                let preview = UIImage(data: data)
                                files.append(PendingUploadFile(
                                    data: data,
                                    fileName: "photo_\(UUID().uuidString).jpg",
                                    contentType: "image/jpeg",
                                    previewImage: preview
                                ))
                            }
                        }
                        if !files.isEmpty {
                            DocumentUploadManager.shared.enqueueFiles(files, propertyId: viewModel.selectedPropertyId)
                            Haptics.success()
                            onComplete?()
                            dismiss()
                        }
                    }
                }
                selectedPhotoItems = []
            }
            .onChange(of: viewModel.error) { _, newValue in
                showErrorAlert = newValue != nil
            }
            .alert("Upload Issue", isPresented: $showErrorAlert) {
                Button("Try Again") {
                    viewModel.error = nil
                    viewModel.isUploading = false
                }
                Button("Dismiss", role: .cancel) {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error ?? "An unexpected error occurred.")
            }
            .sheet(isPresented: $viewModel.showPartyReview) {
                partyReviewSheet
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(selectedCategory: $viewModel.category) { newCategory in
                    Analytics.track(.documentCategorySelected, ["category": newCategory.rawValue, "source": "upload_results"])
                    Task { await viewModel.updateCategory(newCategory) }
                }
            }
            .alert("Duplicate Document", isPresented: $viewModel.showDuplicateAlert) {
                Button("Replace", role: .destructive) {
                    Analytics.track(.documentDuplicateResolved, ["resolution": "replace"])
                    Task { await viewModel.replaceDuplicate() }
                }
                Button("Keep Both", role: .cancel) {
                    Analytics.track(.documentDuplicateResolved, ["resolution": "keep_both"])
                    viewModel.keepBoth()
                }
            } message: {
                if let existing = viewModel.duplicateExistingDoc {
                    Text("You already have a \"\(existing.category)\" document (\(existing.title)). Replace it or keep both?")
                }
            }
        }
        .alert("Not a Critical Document", isPresented: $viewModel.showOtherDocumentNotice) {
            Button("OK") {}
        } message: {
            Text("This doesn't appear to be a critical home or estate document. We've stored it under \"Other Personal Documents\" for safekeeping.")
        }
        .alert("Are You Sure?", isPresented: $viewModel.showIrrelevantWarning) {
            Button("Upload Anyway") {
                Task { await viewModel.confirmUploadAnyway() }
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelIrrelevantUpload()
            }
        } message: {
            Text(viewModel.irrelevantWarningMessage + "\n\nWould you like to upload it anyway?")
        }
    }

    // MARK: - Source Selection (only step the user sees)

    private var sourceSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.navy)
                    Text("Upload a Document")
                        .font(HavenTypography.title)
                    Text("Just pick your file — Alfred will automatically categorize it, extract dates, identify people, and fill everything in for you.")
                        .font(HavenTypography.subheadline)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 32)

                VStack(spacing: 12) {
                    sourceButton(
                        icon: "doc.viewfinder",
                        title: "Scan Document",
                        subtitle: "Use your camera to scan pages",
                        color: HavenColors.navy
                    ) {
                        Haptics.light()
                        Analytics.track(.documentUploadSourceSelected, ["source": "scanner"])
                        viewModel.showScanner = true
                    }

                    sourceButton(
                        icon: "photo.on.rectangle",
                        title: "Photo Library",
                        subtitle: "Choose one or more photos",
                        color: HavenColors.navy700
                    ) {
                        Haptics.light()
                        Analytics.track(.documentUploadSourceSelected, ["source": "photo_library"])
                        viewModel.showPhotoPicker = true
                    }

                    sourceButton(
                        icon: "folder",
                        title: "Browse Files",
                        subtitle: "Select one or multiple PDFs and images",
                        color: HavenColors.navy600
                    ) {
                        Haptics.light()
                        Analytics.track(.documentUploadSourceSelected, ["source": "file_browser"])
                        showFileImporter = true
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func sourceButton(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding()
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Uploading View

    private var uploadingView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Preview thumbnail
            if let image = viewModel.previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            }

            VStack(spacing: 12) {
                ProgressView(value: viewModel.uploadProgress)
                    .progressViewStyle(.linear)
                    .tint(HavenColors.navy)
                    .padding(.horizontal, 40)

                Text(uploadStatusText)
                    .font(HavenTypography.subheadline)
                    .fontWeight(.medium)

                Text("Alfred is analyzing your document and extracting all important information automatically.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    private var uploadStatusText: String {
        switch viewModel.uploadProgress {
        case 0..<0.3: return "Uploading file..."
        case 0.3..<0.5: return "Creating record..."
        case 0.5..<0.8: return "AI is reading your document..."
        case 0.8..<0.95: return "Extracting dates, people & metadata..."
        case 0.95..<1.0: return "Linking family members & properties..."
        default: return "Complete!"
        }
    }

    // MARK: - Results View

    private func resultsView(_ analysis: DocumentAnalysisResult) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Success header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.havenSuccess)
                    Text("Document Processed!")
                        .font(HavenTypography.title)
                    Text("Alfred analyzed your document and filled in everything automatically.")
                        .font(HavenTypography.subheadline)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 16)

                // Card 1: Summary
                HavenCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Summary", systemImage: "sparkles")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.navy)

                        resultRow("Title", value: viewModel.title)

                        HStack {
                            Text("Category")
                                .font(HavenTypography.subheadline)
                                .foregroundStyle(HavenColors.textSecondary)
                            Spacer()
                            Button {
                                showCategoryPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(viewModel.category.rawValue)
                                        .font(HavenTypography.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(HavenColors.textPrimary)
                                        .lineLimit(1)
                                    Text("Change")
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.navy)
                                }
                            }
                        }

                        if !analysis.summary.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Summary")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                                Text(analysis.summary)
                                    .font(HavenTypography.subheadline)
                            }
                        }
                    }
                }

                // Card 2: Details (dates, parties, links)
                if !analysis.keyDates.isEmpty || !analysis.keyParties.isEmpty || !viewModel.autoLinkedMemberNames.isEmpty || viewModel.autoLinkedPropertyName != nil {
                    HavenCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Details", systemImage: "doc.text.magnifyingglass")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.navy)

                            if !analysis.keyDates.isEmpty {
                                ForEach(analysis.keyDates) { date in
                                    resultRow(date.label, value: date.date)
                                }
                            }

                            if !analysis.keyParties.isEmpty {
                                if !analysis.keyDates.isEmpty { Divider() }
                                Text("People Identified")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                                ForEach(analysis.keyParties) { party in
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(HavenColors.textSecondary)
                                        Text(party.name)
                                            .font(HavenTypography.subheadline)
                                        Text("(\(party.role))")
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                }
                            }

                            if !viewModel.autoLinkedMemberNames.isEmpty {
                                Divider()
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.caption)
                                        .foregroundStyle(HavenColors.navy)
                                    Text("Auto-linked: \(viewModel.autoLinkedMemberNames.joined(separator: ", "))")
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.navy)
                                }
                            }

                            if let propName = viewModel.autoLinkedPropertyName {
                                HStack(spacing: 4) {
                                    Image(systemName: "house.fill")
                                        .font(.caption)
                                        .foregroundStyle(HavenColors.navy)
                                    Text("Linked to: \(propName)")
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.navy)
                                }
                            }
                        }
                    }
                }

                // Card 3: Action Items (only if flags exist)
                if !analysis.flags.isEmpty {
                    HavenCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Action Items", systemImage: "exclamationmark.triangle")
                                .font(HavenTypography.headline)
                                .foregroundStyle(Color.havenWarning)

                            ForEach(analysis.flags) { flag in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(flagColor(flag.severity))
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 5)
                                    Text(flag.message)
                                        .font(HavenTypography.subheadline)
                                }
                            }
                        }
                    }
                }

                // Action buttons
                HStack(spacing: 12) {
                    if let docId = viewModel.uploadedDocumentId {
                        NavigationLink {
                            DocumentDetailView(documentID: docId)
                        } label: {
                            Text("View Document")
                                .font(HavenTypography.uiButton)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(HavenColors.navy)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                    }

                    Button {
                        Haptics.success()
                        onComplete?()
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(HavenTypography.uiButton)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(HavenColors.creamLight)
                            .foregroundStyle(HavenColors.navy800)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                            .overlay(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .stroke(HavenColors.beige300, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Batch Uploading View

    private var batchUploadingView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.on.doc")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.navy)

            VStack(spacing: 12) {
                ProgressView(value: viewModel.batchProgress)
                    .progressViewStyle(.linear)
                    .tint(HavenColors.navy)
                    .padding(.horizontal, 40)

                Text("Processing document \(viewModel.currentBatchIndex + 1) of \(viewModel.uploadItems.count)")
                    .font(HavenTypography.subheadline)
                    .fontWeight(.medium)

                if viewModel.currentBatchIndex < viewModel.uploadItems.count {
                    Text(viewModel.uploadItems[viewModel.currentBatchIndex].fileName)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
    }

    // MARK: - Batch Results View

    private var batchResultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Success header
                VStack(spacing: 8) {
                    let successCount = viewModel.uploadItems.filter({ $0.error == nil && $0.isComplete }).count
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.havenSuccess)
                    Text("\(successCount) Documents Processed")
                        .font(HavenTypography.title)
                    if viewModel.uploadItems.contains(where: { $0.error != nil }) {
                        let errorCount = viewModel.uploadItems.filter({ $0.error != nil }).count
                        Text("\(errorCount) failed")
                            .font(HavenTypography.subheadline)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
                .padding(.top, 16)

                // Document list
                ForEach(viewModel.uploadItems) { item in
                    batchItemRow(item)
                }

                HavenButton(title: "Done") {
                    Haptics.success()
                    onComplete?()
                    dismiss()
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding()
        }
    }

    private func batchItemRow(_ item: UploadItem) -> some View {
        HavenCard {
            HStack(spacing: 12) {
                if let preview = item.previewImage {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "doc.fill")
                        .font(.title3)
                        .foregroundStyle(HavenColors.navy)
                        .frame(width: 44, height: 44)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title.isEmpty ? item.fileName : item.title)
                        .font(HavenTypography.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if let error = item.error {
                        Text(error)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                            .lineLimit(2)
                    } else if let cat = item.matchedCategory {
                        Text(cat.rawValue)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Spacer()

                if item.error != nil {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(HavenColors.critical)
                } else if item.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.havenSuccess)
                }
            }
        }
    }

    private func resultRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.subheadline)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(HavenTypography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(HavenColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }

    private func flagColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return Color.havenCritical
        case "warning": return Color.havenWarning
        default: return HavenColors.navy
        }
    }

    // MARK: - Party Review Sheet

    private var partyReviewSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("People Identified")
                            .font(HavenTypography.title2)
                        Text("Alfred found these people in your document. Would you like to add any of them as trusted contacts?")
                            .font(HavenTypography.subheadline)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(.top, 8)

                    ForEach(viewModel.unlinkedParties) { party in
                        HavenCard {
                            HStack(spacing: 12) {
                                Image(systemName: "person.circle")
                                    .font(.title2)
                                    .foregroundStyle(HavenColors.textSecondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(party.name)
                                        .font(HavenTypography.subheadline)
                                        .fontWeight(.medium)
                                    Text(party.role.capitalized)
                                        .font(HavenTypography.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(HavenColors.navy.opacity(0.12))
                                        .foregroundStyle(HavenColors.navy)
                                        .clipShape(Capsule())
                                }

                                Spacer()

                                Button {
                                    Task {
                                        await addPartyAsTrustedContact(party)
                                    }
                                } label: {
                                    Text("Add Contact")
                                        .font(HavenTypography.uiLabelMedium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(HavenColors.navy)
                                        .foregroundStyle(HavenColors.textOnNavy)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(HavenColors.background)
            .navigationTitle("Review People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.showPartyReview = false
                    }
                }
            }
        }
    }

    private func addPartyAsTrustedContact(_ party: DocumentPartyRow) async {
        let db = DatabaseService.shared
        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else { return }

            let contact = try await db.createTrustedContact(TrustedContactInsert(
                householdId: householdId,
                name: party.name,
                email: "",
                role: party.role
            ))

            try await db.updateDocumentParty(id: party.id, DocumentPartyUpdate(
                trustedContactId: contact.id
            ))

            if let docId = viewModel.uploadedDocumentId {
                try await db.grantDocumentAccess(contactId: contact.id, documentId: docId)
            }

            viewModel.unlinkedParties.removeAll { $0.id == party.id }
            Haptics.success()

            if viewModel.unlinkedParties.isEmpty {
                viewModel.showPartyReview = false
            }
        } catch {
            viewModel.error = error.localizedDescription
        }
    }

    // MARK: - Auto Upload

    private func startAutoUpload() {
        guard viewModel.selectedData != nil else { return }
        Task {
            await viewModel.preScreenAndUpload()
        }
    }

    // MARK: - File Handling

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                viewModel.handlePhotoSelection(data, fileName: "photo_\(Date().timeIntervalSince1970).jpg")
                startAutoUpload()
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }

            if urls.count == 1, let url = urls.first {
                // Single file — use existing flow
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url) {
                    let contentType = url.pathExtension.lowercased() == "pdf" ? "application/pdf" : "image/jpeg"
                    viewModel.handleFileSelection(data, fileName: url.lastPathComponent, contentType: contentType)
                    startAutoUpload()
                }
            } else {
                // MULTIPLE files — hand off to background manager and dismiss
                var files: [PendingUploadFile] = []
                for url in urls {
                    guard url.startAccessingSecurityScopedResource() else { continue }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        let contentType = url.pathExtension.lowercased() == "pdf" ? "application/pdf" : "image/jpeg"
                        var preview: UIImage?
                        if contentType.hasPrefix("image/") {
                            preview = UIImage(data: data)
                        }
                        files.append(PendingUploadFile(
                            data: data,
                            fileName: url.lastPathComponent,
                            contentType: contentType,
                            previewImage: preview
                        ))
                    }
                }

                if !files.isEmpty {
                    // Hand off to background manager
                    DocumentUploadManager.shared.enqueueFiles(
                        files,
                        propertyId: viewModel.selectedPropertyId
                    )

                    Haptics.success()

                    // Dismiss the upload sheet — processing continues in background
                    onComplete?()
                    dismiss()
                }
            }
        case .failure(let error):
            viewModel.error = DocumentUploadViewModel.userFriendlyError(error)
        }
    }
}

#Preview {
    DocumentUploadView()
}

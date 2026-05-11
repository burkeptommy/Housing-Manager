import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Phase 80 — Compose sheet for a new Chez Concierge request. Single-screen
/// scrollable form (NOT a multi-step wizard — keeps v1 friction low). The
/// caller posts `.openChezRequestComposer` with category + context payload;
/// `MainTabView` owns the sheet presentation.
///
/// Layout:
///  • Hero: serif "Ask Chez" + 1-business-day caption + concierge avatar
///  • Read-only context card (auto-built from prefilled context, hidden if empty)
///  • Category picker (only when `isCategoryFixed == false`, i.e. .general)
///  • Summary field (one-line)
///  • Description editor (multi-line)
///  • Attachment tray (PhotosPicker + file importer; documents bucket)
///  • Salmon "Send to Chez" submit button
struct ChezRequestComposeSheet: View {
    @StateObject private var viewModel: ChezRequestComposeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showFileImporter = false
    @State private var showDismissConfirm = false

    init(category: ChezCategory, contextHints: [String: String], isCategoryFixed: Bool) {
        _viewModel = StateObject(
            wrappedValue: ChezRequestComposeViewModel(
                category: category,
                contextHints: contextHints,
                isCategoryFixed: isCategoryFixed
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard
                    if viewModel.hasContextCard {
                        contextCard
                    }
                    if !viewModel.isCategoryFixed {
                        categorySection
                    } else {
                        fixedCategoryHeader
                    }
                    summarySection
                    descriptionSection
                    attachmentSection
                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(HavenColors.critical.opacity(0.08))
                            )
                    }
                    submitButton
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.vertical, 20)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedContent {
                            showDismissConfirm = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundStyle(HavenColors.textSecondary)
                }
            }
            .photosPicker(
                isPresented: .constant(false),  // Picker is opened via button below; this hidden binding is a no-op
                selection: $viewModel.pickedPhotoItems,
                maxSelectionCount: 5,
                matching: .images
            )
            .onChange(of: viewModel.pickedPhotoItems) { _, items in
                guard !items.isEmpty else { return }
                Task { await viewModel.ingestPickedPhotos() }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf, .image, .jpeg, .png],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .onChange(of: viewModel.didSucceed) { _, succeeded in
                if succeeded {
                    Haptics.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Discard this request?",
                isPresented: $showDismissConfirm,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            } message: {
                Text("Your draft and any uploaded attachments will be cleared.")
            }
            .interactiveDismissDisabled(hasUnsavedContent || viewModel.isSubmitting)
        }
        .trackScreen("ChezRequestComposeSheet")
    }

    // MARK: - Hero

    private var heroCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Ask Chez")
                    .font(HavenTypography.title)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Chez replies within 1 business day.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }

    // MARK: - Context (read-only)

    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RE:")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
            if let sourceEntityTitle = viewModel.sourceEntityTitle {
                Text(sourceEntityTitle)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(viewModel.contextLines, id: \.key) { pair in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(pair.key)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(width: 110, alignment: .leading)
                    Text(pair.value)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                    Spacer()
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.beige200.opacity(0.5))
        )
    }

    // MARK: - Category

    private var fixedCategoryHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.category.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.action)
            Text(viewModel.category.displayName)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(HavenColors.action.opacity(0.08))
        )
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("WHAT DO YOU NEED?")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(ChezCategory.allCases) { cat in
                    Button {
                        Haptics.selection()
                        viewModel.category = cat
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: cat.iconName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(viewModel.category == cat ? Color.white : HavenColors.action)
                            Text(cat.displayName)
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(viewModel.category == cat ? Color.white : HavenColors.textPrimary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(viewModel.category == cat ? HavenColors.action : HavenColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(
                                    viewModel.category == cat ? HavenColors.action : HavenColors.beige200,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(viewModel.category.promptCaption)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
                .padding(.top, 2)
        }
    }

    // MARK: - Summary + Description

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("ONE-LINE SUMMARY")
            TextField(summaryPlaceholder, text: $viewModel.summary, axis: .horizontal)
                .font(HavenTypography.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(HavenColors.beige200, lineWidth: 1)
                )
                .submitLabel(.next)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("DETAILS")
            TextEditor(text: $viewModel.description)
                .font(HavenTypography.body)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(HavenColors.beige200, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.description.isEmpty {
                        Text(descriptionPlaceholder)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textSecondary.opacity(0.7))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    // MARK: - Attachments

    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("ATTACHMENTS · OPTIONAL")
            HStack(spacing: 8) {
                attachmentButton(label: "Photos", icon: "photo.fill") {
                    // PhotosPicker presents via menu rather than .photosPicker(isPresented:)
                    // because we want side-by-side with the document button. Wrap inside.
                }
                attachmentButton(label: "File", icon: "doc.fill") {
                    showFileImporter = true
                }
                if viewModel.isUploading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(HavenColors.action)
                        .padding(.leading, 4)
                }
                Spacer()
            }
            // The photosButton needs to wrap PhotosPicker so the system sheet
            // appears on tap. We render an invisible PhotosPicker with overlay.
            photosPickerButton
            if !viewModel.pendingAttachments.isEmpty {
                attachmentChips
            }
            Text("Up to 5 files. Photos, PDFs, and screenshots all work.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    /// Renders as a normal-looking button but the underlying PhotosPicker
    /// is what actually fires the system sheet — wrapping keeps the button
    /// row visually consistent (vs. the .photosPicker(isPresented:) pattern,
    /// which doesn't pair well with two buttons on one row).
    private var photosPickerButton: some View {
        PhotosPicker(
            selection: $viewModel.pickedPhotoItems,
            maxSelectionCount: max(1, 5 - viewModel.pendingAttachments.count),
            matching: .images
        ) {
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 14, weight: .semibold))
                Text("Add photos")
                    .font(HavenTypography.uiButton)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .foregroundStyle(HavenColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(HavenColors.beige200, lineWidth: 1)
            )
        }
        .disabled(viewModel.pendingAttachments.count >= 5 || viewModel.isUploading)
    }

    private func attachmentButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        // Re-purposed for the file (PDF) button only. Photos uses a real PhotosPicker.
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(HavenTypography.uiLabelSmall)
            }
            .foregroundStyle(HavenColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(HavenColors.beige200.opacity(0.6))
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.pendingAttachments.count >= 5 || viewModel.isUploading)
        .opacity((viewModel.pendingAttachments.count >= 5 || viewModel.isUploading) ? 0.5 : 1)
        // Hide the "Photos" no-op button — Photos picker is rendered via
        // `photosPickerButton`. Only the PDF button is exposed here.
        .opacity(label == "Photos" ? 0 : 1)
        .frame(width: label == "Photos" ? 0 : nil)
    }

    private var attachmentChips: some View {
        VStack(spacing: 6) {
            ForEach(viewModel.pendingAttachments, id: \.path) { meta in
                HStack(spacing: 10) {
                    Image(systemName: meta.isImage ? "photo.fill" : "doc.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(meta.filename)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                        Text(byteSizeString(meta.sizeBytes))
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    Button {
                        viewModel.removeAttachment(meta)
                        Haptics.light()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(HavenColors.beige200.opacity(0.4))
                )
            }
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            Task {
                Haptics.medium()
                await viewModel.submit()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Text(viewModel.didSucceed ? "Sent · Chez is on it" : "Send to Chez")
                    .font(HavenTypography.uiButton)
                Image(systemName: viewModel.didSucceed ? "checkmark.circle.fill" : "paperplane.fill")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(viewModel.canSubmit || viewModel.didSucceed ? HavenColors.action : HavenColors.action.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit || viewModel.didSucceed)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private var summaryPlaceholder: String {
        switch viewModel.category {
        case .findVendor: return "e.g. Need a tree service in Bedford"
        case .getQuote: return "e.g. Quote for new gutters on the carriage house"
        case .scheduleVisit: return "e.g. Pre-summer pool opening"
        case .coordinateTask: return "e.g. Coordinate roof leak follow-up with Hank"
        case .findHandyman: return "e.g. Handyman for picture hanging + caulking"
        case .general: return "What can Chez help with?"
        }
    }

    private var descriptionPlaceholder: String {
        switch viewModel.category {
        case .findVendor:
            return "Share what's going on, your timing, and any preferences (price-sensitive, prefers female-owned shops, etc.)."
        case .getQuote:
            return "Describe the scope. If you've got existing quotes attached, mention how they compare."
        case .scheduleVisit:
            return "Tell Chez what needs scheduling and your preferred dates / windows."
        case .coordinateTask:
            return "Hand off context. Chez runs the back-and-forth with the vendor."
        case .findHandyman:
            return "Walk through what's on the punch list. Photos help."
        case .general:
            return "The more detail, the better Chez can help."
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(HavenTypography.uiSectionHeader)
            .foregroundStyle(HavenColors.textSecondary)
    }

    private var hasUnsavedContent: Bool {
        !viewModel.summary.isEmpty
            || !viewModel.description.isEmpty
            || !viewModel.pendingAttachments.isEmpty
    }

    private func byteSizeString(_ bytes: Int) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB, .useMB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(bytes))
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                let didStart = url.startAccessingSecurityScopedResource()
                defer {
                    if didStart {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                guard let data = try? Data(contentsOf: url) else {
                    viewModel.errorMessage = "Couldn't read \(url.lastPathComponent)."
                    continue
                }
                let mimeType = mimeTypeForURL(url)
                Task {
                    await viewModel.ingestFile(
                        data: data,
                        filename: url.lastPathComponent,
                        mimeType: mimeType
                    )
                }
            }
        case .failure(let err):
            viewModel.errorMessage = err.localizedDescription
        }
    }

    private func mimeTypeForURL(_ url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "application/pdf"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic": return "image/heic"
        default:
            return UTType(filenameExtension: ext)?.preferredMIMEType ?? "application/octet-stream"
        }
    }
}

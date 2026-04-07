import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool

    var contextType: String?
    var contextId: UUID?
    var initialPrompt: String?
    var systemContext: String?

    @State private var contextName: String?
    @State private var scrollProxy: ScrollViewProxy?

    // Attachment state
    @State private var showAttachmentMenu = false
    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                alfredTab
            }
            .trackScreen("ChatView")
            .screenshotProtected()
            .navigationTitle("Alfred")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Haptics.medium()
                            Analytics.track(.chatCleared)
                            Task {
                                await viewModel.clearChat()
                                contextName = nil
                            }
                        } label: {
                            Label("Clear Chat", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(HavenColors.navy700)
                    }
                    .accessibilityLabel("Chat options")
                }
            }
            .task {
                viewModel.contextType = contextType
                viewModel.contextId = contextId
                viewModel.systemContext = systemContext
                await viewModel.loadHistory()
                if let contextId, let contextType {
                    await loadContextName(type: contextType, id: contextId)
                }
                if let initialPrompt, !initialPrompt.isEmpty {
                    viewModel.inputText = initialPrompt
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await viewModel.sendMessage()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openAlfredWithContext)) { notification in
                guard let userInfo = notification.userInfo,
                      let ctxType = userInfo["contextType"] as? String,
                      let ctxIdStr = userInfo["contextId"] as? String,
                      let ctxId = UUID(uuidString: ctxIdStr) else { return }
                let message = userInfo["message"] as? String

                viewModel.contextType = ctxType
                viewModel.contextId = ctxId

                Task {
                    await loadContextName(type: ctxType, id: ctxId)
                    if let message, !message.isEmpty {
                        viewModel.inputText = message
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        await viewModel.sendMessage()
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                DocumentScannerView { images in
                    handleScannedImages(images)
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        let fileName = "photo_\(Date().timeIntervalSince1970).jpg"
                        await viewModel.uploadAndAnalyzeDocument(
                            data: data,
                            fileName: fileName,
                            contentType: "image/jpeg",
                            previewImage: UIImage(data: data)
                        )
                        scrollToBottom()
                    }
                    selectedPhotoItem = nil
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Duplicate Document", isPresented: $viewModel.showDuplicateAlert) {
                Button("Replace Existing", role: .destructive) {
                    Task { await viewModel.replaceDuplicate() }
                }
                Button("Save Both Copies") {
                    Task { await viewModel.saveBoth() }
                }
                Button("Delete This Document", role: .cancel) {
                    viewModel.discardDuplicate()
                }
            } message: {
                if let existing = viewModel.duplicateExistingDoc {
                    Text("This document already exists as \"\(existing.title)\" (\(existing.category)).")
                }
            }
        }
    }

    // MARK: - Alfred Tab

    private var alfredTab: some View {
        VStack(spacing: 0) {
            // Context banner
            if let contextName, let contextType {
                HStack(spacing: 8) {
                    Image(systemName: contextType == "document" ? "doc.fill" : "house.fill")
                        .font(.caption)
                        .foregroundStyle(HavenColors.navy)
                    Text("Chatting about: \(contextName)")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Button {
                        self.contextName = nil
                        viewModel.contextType = nil
                        viewModel.contextId = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                .padding(.horizontal, HavenTheme.spacing16)
                .padding(.vertical, 8)
                .background(HavenColors.creamLight)
            }

            if viewModel.messages.isEmpty && !viewModel.isTyping && !viewModel.isUploadingDocument {
                emptyState
            } else {
                messageList
            }

            inputBar
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing24) {
                Spacer().frame(height: 40)

                AlfredLogoCircle(logoSize: 64, circleSize: 80)
                    .accessibilityHidden(true)

                VStack(spacing: HavenTheme.spacing8) {
                    Text("Alfred")
                        .font(HavenTypography.title)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Ask me about your documents, estate plan, home maintenance, or anything about your household.")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HavenTheme.spacing24)
                }

                // Horizontal scrollable chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HavenTheme.spacing8) {
                        ForEach(suggestedChips, id: \.self) { chip in
                            Button {
                                Haptics.light()
                                Analytics.track(.chatSuggestedPromptTapped, ["prompt": chip])
                                Task { await viewModel.sendSuggestedPrompt(chip) }
                            } label: {
                                Text(chip)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .padding(.horizontal, HavenTheme.spacing12)
                                    .padding(.vertical, HavenTheme.spacing8)
                                    .background(HavenColors.creamLight)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: HavenTheme.radiusSmall)
                                            .stroke(HavenColors.beige300, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Ask: \(chip)")
                        }
                    }
                    .padding(.horizontal, HavenTheme.spacing16)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(HavenColors.background)
    }

    private var suggestedChips: [String] {
        ["What documents am I missing?", "Summarize my estate plan", "What maintenance is overdue?", "Find me a plumber near Bethel, CT", "Help me schedule a home service", "Connect me with my concierge"]
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: HavenTheme.spacing12) {
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        let showAvatar = message.role == .assistant && (index == 0 || viewModel.messages[index - 1].role != .assistant)
                        ChatBubble(message: message, showAvatar: message.role == .user ? true : showAvatar)
                            .id(message.id)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // Document upload card
                    if let docResult = viewModel.uploadedDocumentResult {
                        ChatDocumentCard(result: docResult)
                            .id("document-card")
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // Upload progress
                    if viewModel.isUploadingDocument {
                        uploadProgressView
                            .id("uploading")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if viewModel.isTyping {
                        typingIndicator
                            .id("typing")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(HavenTheme.spacing16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isInputFocused = false
            }
            .background(HavenColors.background)
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(HavenTheme.animationStandard) {
                    scrollToLatest(proxy: proxy)
                }
            }
            .onChange(of: viewModel.isUploadingDocument) { _, _ in
                withAnimation(HavenTheme.animationStandard) {
                    scrollToLatest(proxy: proxy)
                }
            }
            .onChange(of: isInputFocused) { _, focused in
                if focused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(HavenTheme.animationStandard) {
                            scrollToLatest(proxy: proxy)
                        }
                    }
                }
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
    }

    private func scrollToLatest(proxy: ScrollViewProxy) {
        if viewModel.isTyping {
            proxy.scrollTo("typing", anchor: .bottom)
        } else if viewModel.isUploadingDocument {
            proxy.scrollTo("uploading", anchor: .bottom)
        } else if viewModel.uploadedDocumentResult != nil {
            proxy.scrollTo("document-card", anchor: .bottom)
        } else if let last = viewModel.messages.last {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private func scrollToBottom() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let proxy = scrollProxy {
                withAnimation(HavenTheme.animationStandard) {
                    scrollToLatest(proxy: proxy)
                }
            }
        }
    }

    private var uploadProgressView: some View {
        HStack {
            HStack(spacing: HavenTheme.spacing12) {
                ProgressView()
                    .controlSize(.small)
                    .tint(HavenColors.navy)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Uploading & analyzing document...")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(viewModel.uploadStatusMessage)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(HavenColors.beige300, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            Spacer()
        }
        .accessibilityLabel("Uploading document")
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    TypingDot(delay: Double(i) * 0.2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(HavenColors.creamLight)
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(HavenColors.beige300, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            Spacer()
        }
        .accessibilityLabel("Alfred is typing")
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(HavenColors.beige300)
            HStack(alignment: .bottom, spacing: HavenTheme.spacing8) {
                // Attachment button
                Menu {
                    Button {
                        Haptics.light()
                        Analytics.track(.chatAttachmentAdded, ["source": "scanner"])
                        showScanner = true
                    } label: {
                        Label("Scan Document", systemImage: "doc.text.viewfinder")
                    }
                    Button {
                        Haptics.light()
                        Analytics.track(.chatAttachmentAdded, ["source": "photo_library"])
                        showPhotoPicker = true
                    } label: {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                    }
                    Button {
                        Haptics.light()
                        Analytics.track(.chatAttachmentAdded, ["source": "file_picker"])
                        showFilePicker = true
                    } label: {
                        Label("Choose File", systemImage: "folder")
                    }
                } label: {
                    Image(systemName: "paperclip.circle.fill")
                        .font(.title2)
                        .foregroundStyle(HavenColors.navy)
                }
                .disabled(viewModel.isUploadingDocument)
                .accessibilityLabel("Attach document")

                TextField("Ask Alfred...", text: $viewModel.inputText, axis: .vertical)
                    .font(HavenTypography.bodySmall)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(HavenColors.beige200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(HavenColors.beige300, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .onSubmit {
                        Task { await sendMessage() }
                    }
                    .accessibilityLabel("Message input")
                    .accessibilityHint("Type your question for Alfred")

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canSend ? HavenColors.textOnNavy : HavenColors.textTertiary)
                        .frame(width: 36, height: 36)
                        .background(canSend ? HavenColors.navy : HavenColors.beige200)
                        .clipShape(Circle())
                }
                .disabled(!canSend)
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, HavenTheme.spacing16)
            .padding(.vertical, 10)
            .background(HavenColors.creamLight)
        }
    }

    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isTyping
    }

    private func sendMessage() async {
        Haptics.light()
        await viewModel.sendMessage()
    }

    private func loadContextName(type: String, id: UUID) async {
        do {
            if type == "document" {
                let doc = try await DatabaseService.shared.fetchDocument(id: id)
                contextName = doc.title
            } else if type == "property" {
                let prop = try await DatabaseService.shared.fetchProperty(id: id)
                contextName = prop.name
            } else if type == "project" {
                let allProjects = try await DatabaseService.shared.fetchAllProjects()
                contextName = allProjects.first(where: { $0.id == id })?.name
            }
        } catch {}
    }

    // MARK: - File Handling

    private func handleScannedImages(_ images: [UIImage]) {
        guard let firstImage = images.first else { return }
        let pdfData = imagesToPDF(images)
        guard let data = pdfData else { return }
        let fileName = "scan_\(Date().timeIntervalSince1970).pdf"
        Task {
            await viewModel.uploadAndAnalyzeDocument(
                data: data,
                fileName: fileName,
                contentType: "application/pdf",
                previewImage: firstImage
            )
            scrollToBottom()
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else { return }
        let fileName = url.lastPathComponent
        let contentType = url.pathExtension.lowercased() == "pdf" ? "application/pdf" : "image/jpeg"
        let previewImage: UIImage? = contentType.starts(with: "image") ? UIImage(data: data) : nil

        Task {
            await viewModel.uploadAndAnalyzeDocument(
                data: data,
                fileName: fileName,
                contentType: contentType,
                previewImage: previewImage
            )
            scrollToBottom()
        }
    }

    private func imagesToPDF(_ images: [UIImage]) -> Data? {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return nil }

        guard let context = CGContext(consumer: consumer, mediaBox: nil, nil) else { return nil }

        for image in images {
            let pageSize = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            context.beginPDFPage([kCGPDFContextMediaBox as String: pageSize] as CFDictionary)
            if let cgImage = image.cgImage {
                context.draw(cgImage, in: pageSize)
            }
            context.endPDFPage()
        }

        context.closePDF()
        return pdfData as Data
    }
}

// MARK: - Typing Dot Animation

struct TypingDot: View {
    let delay: Double
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(HavenColors.navy600)
            .frame(width: 8, height: 8)
            .offset(y: isAnimating ? -4 : 0)
            .animation(
                .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

#Preview {
    ChatView()
}

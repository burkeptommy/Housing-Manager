import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Phase 80 — Detail screen for a single Chez request. Header card with
/// status / SLA, optional context recap, scrolling thread of messages,
/// sticky bottom reply composer (paperclip attach + send). Resolved
/// requests show a "Reopen" pill instead of the composer.
struct ChezRequestDetailView: View {
    @StateObject private var viewModel: ChezRequestDetailViewModel
    @State private var showFileImporter = false
    @State private var contextExpanded: Bool = false

    init(requestId: UUID) {
        _viewModel = StateObject(wrappedValue: ChezRequestDetailViewModel(requestId: requestId))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let req = viewModel.request {
                            headerCard(for: req)
                            if let context = req.context, !context.isEmpty {
                                detailsCard(context: context)
                            }
                            messagesSection
                            // Anchor at the very bottom so we can scroll-to-end on appear / new message.
                            Color.clear.frame(height: 1).id("bottom")
                        } else if viewModel.isLoading {
                            loadingState
                        } else {
                            errorState
                        }
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            // Composer bar OR reopen affordance
            if let req = viewModel.request {
                if req.typedStatus == .resolved {
                    reopenBar
                } else {
                    composerBar
                }
            }
        }
        .background(HavenColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.request?.summary ?? "Request")
        .task { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .chezRequestChanged)) { _ in
            Task { await viewModel.load() }
        }
        .photosPicker(
            isPresented: .constant(false),
            selection: $viewModel.replyPickedItems,
            maxSelectionCount: 5,
            matching: .images
        )
        .onChange(of: viewModel.replyPickedItems) { _, items in
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
        .trackScreen("ChezRequestDetailView")
    }

    // MARK: - Header

    private func headerCard(for req: ChezRequestRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(HavenColors.action.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: req.typedCategory.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(req.typedCategory.displayName)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    Text(req.summary)
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(3)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                ChezStatusBadge(status: req.typedStatus)
                Text(req.homeownerSlaCaption)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        )
    }

    // MARK: - Context recap

    private func detailsCard(context: [String: String]) -> some View {
        DisclosureGroup(isExpanded: $contextExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(prettyContextLines(context), id: \.key) { pair in
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
            .padding(.top, 8)
        } label: {
            Text("Details you sent")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(HavenColors.beige200.opacity(0.5))
        )
        .accentColor(HavenColors.textSecondary)
    }

    private func prettyContextLines(_ context: [String: String]) -> [(key: String, value: String)] {
        context
            .filter { !$0.key.hasPrefix("_") }
            .sorted(by: { $0.key < $1.key })
            .map { ($0.key.replacingOccurrences(of: "_", with: " ").capitalized, $0.value) }
    }

    // MARK: - Thread

    private var messagesSection: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.messages) { msg in
                ChezMessageBubble(
                    message: msg,
                    attachmentURLResolver: { meta in
                        await viewModel.attachmentURL(for: meta)
                    },
                    onProposalCounter: { proposal in
                        // Phase 80.1 — Counter prefills the reply
                        // composer with a template. The user fills in
                        // the specific change they want and sends; Chez
                        // takes it from there.
                        let template: String = {
                            switch proposal.typedKind {
                            case .vendor:
                                return "I'd rather not go with \(proposal.vendor?.name ?? "this vendor"). Can you propose another option?"
                            case .dateSlot:
                                return "These times don't work — could we look at "
                            case .cost:
                                return "That cost is higher than I expected. Is there room to negotiate or a leaner scope?"
                            case .quote:
                                return "A few line items on this quote feel off. Can you push back on "
                            }
                        }()
                        viewModel.replyText = template
                    }
                )
            }
        }
    }

    // MARK: - Composer

    private var composerBar: some View {
        VStack(spacing: 8) {
            if !viewModel.replyAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.replyAttachments, id: \.path) { meta in
                            HStack(spacing: 6) {
                                Image(systemName: meta.isImage ? "photo.fill" : "doc.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(HavenColors.action)
                                Text(meta.filename)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Button {
                                    viewModel.removeAttachment(meta)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(HavenColors.beige200.opacity(0.6))
                            )
                        }
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                }
            }
            HStack(alignment: .bottom, spacing: 10) {
                attachmentMenu
                composerField
                sendButton
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, 10)
        }
        .background(
            HavenColors.surface
                .shadow(color: HavenColors.beige300.opacity(0.4), radius: 4, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var attachmentMenu: some View {
        Menu {
            Button {
                // No-op — PhotosPicker is wrapped below as the actual button when needed
            } label: {
                Label("Photos", systemImage: "photo.on.rectangle.angled")
            }
            Button {
                showFileImporter = true
            } label: {
                Label("File", systemImage: "doc.fill")
            }
        } label: {
            // Replaced with a real PhotosPicker stack so Photos works directly.
            // See `attachmentButtonStack` below.
            EmptyView()
        }
        .opacity(0)  // Hidden — real UI is below
        .frame(width: 0, height: 0)
        .overlay(attachmentButtonStack)
    }

    /// Visible attachment-button stack. The Menu above only exists to
    /// keep keyboard focus consistent; real interaction goes through
    /// these two views.
    private var attachmentButtonStack: some View {
        HStack(spacing: 4) {
            PhotosPicker(
                selection: $viewModel.replyPickedItems,
                maxSelectionCount: max(1, 5 - viewModel.replyAttachments.count),
                matching: .images
            ) {
                Image(systemName: "photo")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(8)
                    .background(Circle().fill(HavenColors.beige200.opacity(0.5)))
            }
            .disabled(viewModel.replyAttachments.count >= 5 || viewModel.isReplyUploading)
            Button {
                showFileImporter = true
            } label: {
                Image(systemName: "paperclip")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(8)
                    .background(Circle().fill(HavenColors.beige200.opacity(0.5)))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.replyAttachments.count >= 5 || viewModel.isReplyUploading)
        }
    }

    private var composerField: some View {
        TextField("Reply to Tom…", text: $viewModel.replyText, axis: .vertical)
            .font(HavenTypography.body)
            .lineLimit(1...5)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(HavenColors.beige200.opacity(0.5))
            )
    }

    private var sendButton: some View {
        Button {
            Task {
                Haptics.medium()
                await viewModel.sendReply()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(viewModel.canSend ? HavenColors.action : HavenColors.action.opacity(0.4))
                    .frame(width: 38, height: 38)
                if viewModel.isReplySending {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSend)
    }

    // MARK: - Reopen

    private var reopenBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("This request is resolved.")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Reopen if you need to follow up.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
            Button {
                Task {
                    Haptics.medium()
                    await viewModel.reopenFromResolved()
                }
            } label: {
                Text("Reopen")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(HavenColors.action)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.vertical, 10)
        .background(HavenColors.surface)
    }

    // MARK: - Loading + Error

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView().padding(.top, 80)
            Text("Loading…")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(HavenColors.critical)
            Text("Couldn't load this request.")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
            if let err = viewModel.errorMessage {
                Text(err)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - File import

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
                guard let data = try? Data(contentsOf: url) else { continue }
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

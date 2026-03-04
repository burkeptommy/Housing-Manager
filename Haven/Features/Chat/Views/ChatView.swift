import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool

    var contextType: String?
    var contextId: UUID?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.messages.isEmpty && !viewModel.isTyping {
                    emptyState
                } else {
                    messageList
                }

                inputBar
            }
            .navigationTitle("Haven AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            Haptics.medium()
                            Task { await viewModel.clearChat() }
                        } label: {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Chat options")
                }
            }
            .task {
                viewModel.contextType = contextType
                viewModel.contextId = contextId
                await viewModel.loadHistory()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing24) {
                Spacer().frame(height: 40)

                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.havenAccent)
                    .accessibilityHidden(true)

                VStack(spacing: HavenTheme.spacing8) {
                    Text("Haven AI Assistant")
                        .font(HavenTypography.title2)
                    Text("Ask me about your documents, estate plan, home maintenance, or anything about your household.")
                        .font(HavenTypography.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HavenTheme.spacing32)
                }

                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    Text("Suggested questions:")
                        .font(HavenTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.leading, HavenTheme.spacing4)

                    ForEach(viewModel.suggestedPrompts, id: \.self) { prompt in
                        Button {
                            Haptics.light()
                            Task { await viewModel.sendSuggestedPrompt(prompt) }
                        } label: {
                            HStack {
                                Text(prompt)
                                    .font(HavenTypography.subheadline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundStyle(Color.havenAccent)
                            }
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                            .havenShadow()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Ask: \(prompt)")
                    }
                }
                .padding(.horizontal, HavenTheme.spacing16)
            }
        }
        .background(HavenColors.background)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: HavenTheme.spacing12) {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    if viewModel.isTyping {
                        typingIndicator
                            .id("typing")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(HavenTheme.spacing16)
            }
            .background(HavenColors.background)
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(HavenTheme.animationStandard) {
                    if viewModel.isTyping {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
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
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            Spacer()
        }
        .accessibilityLabel("Haven AI is typing")
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: HavenTheme.spacing12) {
                TextField("Ask Haven AI...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .onSubmit {
                        Task { await sendMessage() }
                    }
                    .accessibilityLabel("Message input")
                    .accessibilityHint("Type your question for Haven AI")

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSend ? Color.havenAccent : .secondary)
                }
                .disabled(!canSend)
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, HavenTheme.spacing16)
            .padding(.vertical, 10)
            .background(HavenColors.surface)
        }
    }

    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isTyping
    }

    private func sendMessage() async {
        Haptics.light()
        await viewModel.sendMessage()
    }
}

// MARK: - Typing Dot Animation

struct TypingDot: View {
    let delay: Double
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color.secondary)
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

// Wave M7 — Crew chat tab for the Chez Field iOS app.
//
// Lives outside `Haven/App/HavenFieldView.swift` (which is already 16k+
// lines) so this surface can evolve without colliding with the rest of
// the field-app monolith and so subagents working in parallel waves
// don't fight over the same merge surface.
//
// The companion model + service additions still live in
// `Haven/App/HavenFieldView.swift`:
//   • `HavenFieldCrewChatThread` / `HavenFieldCrewChatMessage` /
//     `HavenFieldCrewChatLastMessage` / `HavenFieldCrewChatMember`
//     Codable types
//   • `HavenFieldService.{listCrewChatThreads, sendCrewChatMessage,
//     markCrewChatThreadRead, createCrewChatThread,
//     fetchCrewChatMessages, fetchWorkspaceMemberDirectory}`
//   • `HavenFieldViewModel.RootTab.crew`
//
// This file owns the SwiftUI surface only.

import SwiftUI
import Supabase

extension Notification.Name {
    /// Posted whenever a crew thread is created, a message is sent,
    /// or a thread is marked read — anything any surface (Crew tab
    /// thread list, in-thread view, future widget) cares about as a
    /// "refresh me" signal.
    static let havenFieldCrewChatChanged = Notification.Name("havenFieldCrewChatChanged")
}

/// Wave M7 — Crew tab. Intra-workspace messaging surface, distinct
/// from the customer-facing Messages tab.
///
/// Tab shape: thread list (left/top) → tap to push the per-thread
/// view → composer at the bottom of that view. Toolbar `+` opens
/// `HavenFieldCrewNewThreadSheet` for ad-hoc tech-pair conversations.
///
/// Realtime is best-effort: a Supabase Realtime channel scoped to
/// `crew_chat_messages` filtered by `workspace_id` re-fires the list
/// load on insert. If the subscription fails, the list still refreshes
/// on `.task`, on navigation back from a thread (via the parent view's
/// `.onAppear` which calls `viewModel.refresh()`), and on
/// `Notification.Name.havenFieldCrewChatChanged`.
struct HavenFieldCrewTab: View {
    @ObservedObject var viewModel: HavenFieldViewModel
    @StateObject private var chatModel = HavenFieldCrewChatModel()
    @State private var showNewThread = false

    var body: some View {
        Group {
            if let workspaceId = viewModel.dashboard?.workspace?.id {
                content(workspaceId: workspaceId)
            } else {
                EmptyView()
            }
        }
        .background(HavenColors.cream.ignoresSafeArea())
        .navigationTitle("Crew")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func content(workspaceId: String) -> some View {
        ZStack {
            HavenColors.cream.ignoresSafeArea()

            if chatModel.isLoading && chatModel.threads.isEmpty {
                // D1 — skeleton loaders, never spinners on blank screens.
                threadListSkeleton
            } else if chatModel.threads.isEmpty {
                // B9 — empty state with explicit "create thread" CTA.
                emptyState
            } else {
                threadList
            }

            if let error = chatModel.error {
                // C7 — surfaced inline at the top so the user can dismiss
                // and retry without losing context.
                VStack {
                    HavenFieldCrewErrorBanner(message: error) {
                        chatModel.error = nil
                        Task { await chatModel.load(workspaceId: workspaceId) }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewThread = true
                } label: {
                    Image(systemName: "plus.bubble.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                }
                .accessibilityLabel("New thread")
                // B6 — 44pt min touch target via the toolbar default.
            }
        }
        .sheet(isPresented: $showNewThread) {
            HavenFieldCrewNewThreadSheet(
                workspaceId: workspaceId,
                roster: chatModel.roster,
                onCreated: { newThread in
                    showNewThread = false
                    chatModel.upsertThread(newThread)
                    // Auto-select the new thread so the user lands in
                    // the composer immediately. Same pattern as M11's
                    // end-of-day sheet.
                    chatModel.selectedThread = newThread
                }
            )
        }
        .navigationDestination(isPresented: threadOpenBinding) {
            if let selected = chatModel.selectedThread {
                HavenFieldCrewChatThreadView(
                    workspaceId: workspaceId,
                    thread: selected,
                    chatModel: chatModel,
                    rootViewModel: viewModel
                )
            } else {
                EmptyView()
            }
        }
        .task(id: workspaceId) {
            await chatModel.load(workspaceId: workspaceId)
            await chatModel.subscribeRealtime(workspaceId: workspaceId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .havenFieldCrewChatChanged)) { _ in
            Task { await chatModel.load(workspaceId: workspaceId) }
        }
    }

    /// Bridges `chatModel.selectedThread` (optional) to the
    /// `navigationDestination(isPresented:)` Bool binding. Reading
    /// returns `selectedThread != nil`; writing `false` clears it.
    private var threadOpenBinding: Binding<Bool> {
        Binding(
            get: { chatModel.selectedThread != nil },
            set: { isActive in
                if !isActive {
                    chatModel.selectedThread = nil
                }
            }
        )
    }

    private var threadList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(chatModel.sortedThreads) { thread in
                    Button {
                        chatModel.selectedThread = thread
                    } label: {
                        HavenFieldCrewThreadRow(thread: thread)
                    }
                    .buttonStyle(.plain)
                    // B6 — entire row is the touch target, well above 44pt.
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .refreshable {
            await chatModel.load(workspaceId: viewModel.dashboard?.workspace?.id ?? "")
        }
    }

    private var threadListSkeleton: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(HavenColors.creamLight)
                    .frame(height: 76)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(HavenColors.border, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
            }
            Spacer()
        }
        .padding(.top, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 60)
            Image(systemName: "person.2.wave.2")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(HavenColors.textSecondary.opacity(0.6))
            Text("No crew threads yet")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Start a conversation with the rest of the workspace. Coordinate routes, swap stops, share quick updates from the field.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showNewThread = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Start a thread")
                        .font(HavenTypography.uiButton)
                }
                .foregroundStyle(HavenColors.textOnAction)
                .padding(.horizontal, 22)
                .padding(.vertical, 13)
                .background(HavenColors.action)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// View model for the Crew tab. Holds the thread list, the currently
/// selected thread, the loaded message history per thread (in-memory,
/// keyed by thread id), workspace member roster, loading + error
/// state, and the Realtime channel subscription.
@MainActor
final class HavenFieldCrewChatModel: ObservableObject {
    @Published var threads: [HavenFieldCrewChatThread] = []
    @Published var roster: [HavenFieldCrewChatMember] = []
    @Published var selectedThread: HavenFieldCrewChatThread?
    @Published var isLoading = false
    @Published var error: String?
    /// Per-thread message buffer keyed by thread id. Avoids round-trip
    /// flash when the user re-enters a thread they just visited.
    @Published var messagesByThread: [String: [HavenFieldCrewChatMessage]] = [:]

    private var realtimeSubscriptionTask: Task<Void, Never>?
    private var lastSubscribedWorkspaceId: String?

    deinit {
        realtimeSubscriptionTask?.cancel()
    }

    /// Sort by most-recent-activity descending: threads with no
    /// messages fall back to created_at. Mirrors what every chat app
    /// does.
    var sortedThreads: [HavenFieldCrewChatThread] {
        threads.sorted { lhs, rhs in
            sortKey(for: lhs) > sortKey(for: rhs)
        }
    }

    private func sortKey(for thread: HavenFieldCrewChatThread) -> String {
        thread.lastMessage?.createdAt ?? thread.createdAt ?? ""
    }

    func load(workspaceId: String) async {
        guard !workspaceId.isEmpty else { return }
        isLoading = true
        error = nil
        do {
            async let threadsTask = HavenFieldService.shared.listCrewChatThreads(workspaceId: workspaceId)
            async let rosterTask = HavenFieldService.shared.fetchWorkspaceMemberDirectory(workspaceId: workspaceId)
            let (loadedThreads, loadedRoster) = try await (threadsTask, rosterTask)
            self.threads = loadedThreads
            self.roster = loadedRoster
            // If a thread is currently selected, refresh its row so
            // the badge / preview reflects the latest data.
            if let selected = selectedThread,
               let updated = loadedThreads.first(where: { $0.id == selected.id }) {
                self.selectedThread = updated
            }
        } catch {
            self.error = "Couldn't load crew chat. Pull to retry."
            print("[HavenFieldCrewChatModel] load failed: \(error)")
        }
        isLoading = false
    }

    func upsertThread(_ thread: HavenFieldCrewChatThread) {
        if let idx = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[idx] = thread
        } else {
            threads.insert(thread, at: 0)
        }
    }

    func appendMessage(_ message: HavenFieldCrewChatMessage) {
        var current = messagesByThread[message.threadId] ?? []
        // Dedup by id — Realtime + manual-send round-trip can
        // double-fire for our own outbound messages.
        if !current.contains(where: { $0.id == message.id }) {
            current.append(message)
        }
        messagesByThread[message.threadId] = current
    }

    func setMessages(_ messages: [HavenFieldCrewChatMessage], for threadId: String) {
        messagesByThread[threadId] = messages
    }

    /// Subscribe to a Realtime channel scoped to this workspace's
    /// `crew_chat_messages` rows. On each insert, refresh the thread
    /// list AND, if the message is for the currently-open thread,
    /// pull the new message in. Best-effort — silently degrades to
    /// the polling refresh on `.task` and on tab return.
    func subscribeRealtime(workspaceId: String) async {
        // Skip re-subscribing if we already have a live channel for
        // this workspace.
        if lastSubscribedWorkspaceId == workspaceId, realtimeSubscriptionTask != nil {
            return
        }
        realtimeSubscriptionTask?.cancel()
        lastSubscribedWorkspaceId = workspaceId

        realtimeSubscriptionTask = Task { [weak self] in
            let channelName = "crew-chat-\(workspaceId)"
            let channel = HavenSupabase.client.realtimeV2.channel(channelName)
            let inserts = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "crew_chat_messages",
                filter: .eq("workspace_id", value: workspaceId)
            )
            do {
                try await channel.subscribeWithError()
            } catch {
                print("[HavenFieldCrewChatModel] Realtime subscribe failed: \(error)")
                return
            }
            defer {
                Task { await channel.unsubscribe() }
            }
            for await _ in inserts {
                guard let self else { return }
                let snapshot = await MainActor.run { self.selectedThread }
                await self.load(workspaceId: workspaceId)
                if let selected = snapshot {
                    let messages = try? await HavenFieldService.shared.fetchCrewChatMessages(
                        workspaceId: workspaceId,
                        threadId: selected.id
                    )
                    if let messages {
                        await MainActor.run {
                            self.setMessages(messages, for: selected.id)
                        }
                    }
                }
            }
        }
    }

    /// Cancel + clear realtime state. Called when the tab disappears
    /// in case SwiftUI rebuilds the model.
    func cancelRealtime() {
        realtimeSubscriptionTask?.cancel()
        realtimeSubscriptionTask = nil
        lastSubscribedWorkspaceId = nil
    }
}

private struct HavenFieldCrewThreadRow: View {
    let thread: HavenFieldCrewChatThread

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(HavenColors.navy700.opacity(0.10))
                Image(systemName: thread.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(thread.displayName)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if let createdAt = thread.lastMessage?.createdAt {
                        Text(crewChatRelativeShort(createdAt))
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                if let preview = thread.lastMessage {
                    Text("\(preview.senderName): \(preview.body)")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                } else {
                    Text("No messages yet. Start the conversation.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary.opacity(0.7))
                        .italic()
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if thread.unreadCount > 0 {
                // B1 — salmon used here as the "needs attention" pill,
                // which matches the Section 22 SLA-critical / unread
                // pattern.
                Text("\(thread.unreadCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(minWidth: 22, minHeight: 22)
                    .padding(.horizontal, 6)
                    .background(HavenColors.action)
                    .clipShape(Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(HavenColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(HavenColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Wave M7 — per-thread chat view. Bubbles flow chronologically with
/// the composer at the bottom. Marks the thread read on first appear.
private struct HavenFieldCrewChatThreadView: View {
    let workspaceId: String
    let thread: HavenFieldCrewChatThread
    @ObservedObject var chatModel: HavenFieldCrewChatModel
    var rootViewModel: HavenFieldViewModel? = nil

    @State private var composerBody = ""
    @State private var isSending = false
    @State private var loadError: String?
    @State private var hasMarkedRead = false
    /// Captured at .onAppear so the chat model's current member id
    /// can be inferred from the most recent message they sent. This
    /// is a heuristic — for a perfect right/left alignment we'd carry
    /// the caller's `member_id` on the workspace dashboard payload,
    /// but that requires a server change we'll batch with M9.
    @State private var inferredCurrentMemberId: String?

    private var orderedMessages: [HavenFieldCrewChatMessage] {
        (chatModel.messagesByThread[thread.id] ?? []).sorted { lhs, rhs in
            let l = lhs.createdAt.flatMap(crewChatParseISO) ?? .distantPast
            let r = rhs.createdAt.flatMap(crewChatParseISO) ?? .distantPast
            return l < r
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if orderedMessages.isEmpty && !chatModel.isLoading {
                            VStack(spacing: 10) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundStyle(HavenColors.textSecondary.opacity(0.6))
                                Text("No messages yet")
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("Send the first message to start the thread.")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            ForEach(orderedMessages) { message in
                                HavenFieldCrewChatBubble(
                                    message: message,
                                    isFromMe: isMine(message)
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                }
                .onAppear {
                    if let lastId = orderedMessages.last?.id {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                        }
                    }
                }
                .onChange(of: orderedMessages.count) { _, _ in
                    if let lastId = orderedMessages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }

            composer
        }
        .background(HavenColors.cream.ignoresSafeArea())
        .navigationTitle(thread.displayName)
        .navigationBarTitleDisplayMode(.inline)
        // Hide the floating tab bar while in a thread — the composer
        // safe-area inset overlaps the tab bar otherwise. Same pattern
        // as `HavenFieldMessageThreadView`.
        .toolbar(.hidden, for: .tabBar)
        .onAppear { rootViewModel?.bottomTabBarHidden = true }
        .onDisappear { rootViewModel?.bottomTabBarHidden = false }
        .task {
            await loadMessages()
            // Mark read AFTER the messages land so we can infer the
            // current user's member id from the read_by arrays the
            // server already stamped on previous outbound messages.
            await markReadIfNeeded()
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if let loadError {
                Text(loadError)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            HStack(alignment: .bottom, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    if composerBody.isEmpty {
                        Text("Send a message…")
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textSecondary.opacity(0.7))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                    }
                    TextField("", text: $composerBody, axis: .vertical)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .lineLimit(1...5)
                }
                .background(HavenColors.creamLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(HavenColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))

                Button {
                    Task { await send() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(canSend ? HavenColors.action : HavenColors.action.opacity(0.4))
                        Image(systemName: isSending ? "hourglass" : "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(HavenColors.textOnAction)
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(!canSend || isSending)
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .padding(.top, 10)
        .background(HavenColors.surface.ignoresSafeArea(edges: .bottom))
        .overlay(
            Rectangle()
                .fill(HavenColors.border)
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .top)
        )
    }

    private var canSend: Bool {
        !composerBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadMessages() async {
        do {
            let messages = try await HavenFieldService.shared.fetchCrewChatMessages(
                workspaceId: workspaceId,
                threadId: thread.id
            )
            chatModel.setMessages(messages, for: thread.id)
            // Heuristic — every message in `read_by` whose sender is
            // the only one to mark it read at insertion time is, by
            // construction, the caller's own message. We pick the
            // most recently sent message and treat its sender as us.
            if let mine = messages.last(where: { $0.readBy.count == 1 && !$0.senderMemberId.isEmpty }) {
                inferredCurrentMemberId = mine.senderMemberId
            }
        } catch {
            loadError = "Couldn't load this conversation. Tap Send to retry."
            print("[HavenFieldCrewChatThreadView] loadMessages failed: \(error)")
        }
    }

    private func markReadIfNeeded() async {
        guard !hasMarkedRead else { return }
        hasMarkedRead = true
        do {
            try await HavenFieldService.shared.markCrewChatThreadRead(
                workspaceId: workspaceId,
                threadId: thread.id
            )
            // Refresh the parent list so the badge clears immediately
            // on tab return.
            await chatModel.load(workspaceId: workspaceId)
        } catch {
            // Non-fatal — the badge will clear on next list refresh.
            print("[HavenFieldCrewChatThreadView] mark_read failed: \(error)")
        }
    }

    private func send() async {
        let body = composerBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        isSending = true
        loadError = nil
        defer { isSending = false }
        do {
            let message = try await HavenFieldService.shared.sendCrewChatMessage(
                workspaceId: workspaceId,
                threadId: thread.id,
                body: body
            )
            // Optimistic-style append so the bubble lands instantly.
            chatModel.appendMessage(message)
            inferredCurrentMemberId = message.senderMemberId
            composerBody = ""
            // Refresh the thread list so this thread floats up + the
            // last-message preview updates.
            await chatModel.load(workspaceId: workspaceId)
            NotificationCenter.default.post(name: .havenFieldCrewChatChanged, object: nil)
        } catch {
            loadError = "Couldn't send the message. Tap Send to retry."
            print("[HavenFieldCrewChatThreadView] send failed: \(error)")
        }
    }

    /// Best-effort right/left alignment. We don't carry the caller's
    /// `member_id` on the dashboard payload yet, so we infer it from
    /// the first message we successfully send (or from the
    /// loadMessages heuristic above). Until we have that signal,
    /// every message renders left-aligned — preferable to flipping
    /// the wrong side which would mislead.
    private func isMine(_ message: HavenFieldCrewChatMessage) -> Bool {
        guard let me = inferredCurrentMemberId else { return false }
        return message.senderMemberId == me
    }
}

private struct HavenFieldCrewChatBubble: View {
    let message: HavenFieldCrewChatMessage
    let isFromMe: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isFromMe { Spacer(minLength: 40) }

            if !isFromMe {
                Circle()
                    .fill(HavenColors.navy700.opacity(0.12))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(initials(for: message.senderName))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(HavenColors.navy700)
                    )
                    .padding(.top, 18)
            }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.senderName)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(message.body)
                    .font(HavenTypography.body)
                    .foregroundStyle(isFromMe ? HavenColors.textOnAction : HavenColors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(isFromMe ? HavenColors.action : HavenColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isFromMe ? Color.clear : HavenColors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(maxWidth: .infinity, alignment: isFromMe ? .trailing : .leading)
                if let createdAt = message.createdAt {
                    Text(crewChatRelativeShort(createdAt))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(HavenColors.textSecondary.opacity(0.7))
                }
            }

            if !isFromMe { Spacer(minLength: 40) }
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ").compactMap { $0.first }
        if parts.count >= 2 {
            return String([parts.first!, parts.last!]).uppercased()
        }
        if let first = parts.first {
            return String(first).uppercased()
        }
        return "?"
    }
}

/// Wave M7 — sheet for creating an ad-hoc tech-pair thread or a
/// general workspace channel. Captures optional name + kind chip +
/// member multi-select. Active members only — invited rows can't be
/// added until they accept.
private struct HavenFieldCrewNewThreadSheet: View {
    let workspaceId: String
    let roster: [HavenFieldCrewChatMember]
    let onCreated: (HavenFieldCrewChatThread) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kind = "general"
    @State private var selectedMemberIds: Set<String> = []
    @State private var isCreating = false
    @State private var error: String?

    private let kindOptions: [(kind: String, label: String, icon: String)] = [
        ("general", "General", "bubble.left.and.bubble.right.fill"),
        ("tech_pair", "Direct chat", "person.2.fill"),
        ("route_day", "Route day", "calendar.badge.clock"),
    ]

    private var activeMembers: [HavenFieldCrewChatMember] {
        roster.filter { $0.status == "active" }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Kind", selection: $kind) {
                        ForEach(kindOptions, id: \.kind) { option in
                            Label(option.label, systemImage: option.icon).tag(option.kind)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Thread type")
                }

                Section {
                    TextField("Name (optional)", text: $name)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Title")
                } footer: {
                    Text("Skip for a quick chat. Add a name for routes (e.g. \"Tuesday route\") so it's easy to find later.")
                }

                Section {
                    if activeMembers.isEmpty {
                        Text("No active workspace members yet. Invite teammates from the Crew screen first.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else {
                        ForEach(activeMembers) { member in
                            Button {
                                toggleMember(member.id)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(HavenColors.navy700.opacity(0.12))
                                        Text(member.initials)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(HavenColors.navy700)
                                    }
                                    .frame(width: 32, height: 32)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.displayName)
                                            .font(HavenTypography.body)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Text(member.role.capitalized)
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                    Spacer()
                                    if selectedMemberIds.contains(member.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(HavenColors.action)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(HavenColors.textSecondary.opacity(0.4))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Participants (optional)")
                } footer: {
                    Text("All active workspace members can see every thread. Selecting members today is a hint for future participant scoping.")
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(HavenColors.critical)
                            .font(HavenTypography.bodySmall)
                    }
                }
            }
            .navigationTitle("New thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await create() }
                    } label: {
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("Create").fontWeight(.semibold)
                        }
                    }
                    .disabled(isCreating)
                }
            }
        }
    }

    private func toggleMember(_ id: String) {
        if selectedMemberIds.contains(id) {
            selectedMemberIds.remove(id)
        } else {
            selectedMemberIds.insert(id)
        }
    }

    private func create() async {
        isCreating = true
        error = nil
        defer { isCreating = false }
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let thread = try await HavenFieldService.shared.createCrewChatThread(
                workspaceId: workspaceId,
                name: trimmedName.isEmpty ? nil : trimmedName,
                kind: kind,
                memberIds: Array(selectedMemberIds)
            )
            NotificationCenter.default.post(name: .havenFieldCrewChatChanged, object: nil)
            onCreated(thread)
        } catch {
            self.error = "Couldn't create the thread. Try again."
            print("[HavenFieldCrewNewThreadSheet] create failed: \(error)")
        }
    }
}

private struct HavenFieldCrewErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(HavenColors.critical)
                .font(.system(size: 14, weight: .semibold))
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
                Button("Retry") { onDismiss() }
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.action)
            }
            Spacer(minLength: 8)
        }
        .padding(12)
        .background(HavenColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(HavenColors.critical.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Date helpers (file-private)
//
// `HavenFieldView.swift`'s `HavenFieldDateParser` is `private`-scoped
// to that file and we don't want to widen its access modifier as a
// side effect of M7 (concurrent waves M9 / M10 are touching the same
// file). Inline a tiny equivalent here so this surface compiles
// independently. Same parse strategy: ISO 8601 with + without
// fractional seconds. Same render: relative for ≤ 7 days, short
// month-day past that.

/// Parse an ISO 8601 timestamp the server returns. Tolerates both
/// fractional-seconds (`2026-05-09T03:53:42.417658+00:00`) and
/// integer-second (`2026-05-09T03:53:42+00:00`) shapes.
private func crewChatParseISO(_ string: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let parsed = formatter.date(from: string) { return parsed }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: string)
}

/// Compact relative-time label for chat rows. "now" / "12m" / "3h" /
/// "2d" for sub-week ranges, falling back to "May 5" for older.
/// Intentionally narrow — the row UI only has ~50pt of real estate
/// for the right-hand timestamp.
private func crewChatRelativeShort(_ iso: String) -> String {
    guard let date = crewChatParseISO(iso) else { return "" }
    let elapsed = Date().timeIntervalSince(date)
    if elapsed < 60 { return "now" }
    let minutes = Int(elapsed / 60)
    if minutes < 60 { return "\(minutes)m" }
    let hours = minutes / 60
    if hours < 24 { return "\(hours)h" }
    let days = hours / 24
    if days < 7 { return "\(days)d" }
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
}

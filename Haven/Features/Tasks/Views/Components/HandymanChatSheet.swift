import SwiftUI

/// Chat thread between the homeowner and their handyman, scoped to a
/// specific visit (`HandymanRequestRow`). Lazy-creates the request row
/// when the user types their first message on a maintenance-task-only
/// visit (the legacy data shape from before Phase 71).
struct HandymanChatSheet: View {
    let visit: MaintenanceTaskDBRow?
    let vendor: ContractorRow?
    let householdId: UUID?
    let propertyId: UUID?

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = HandymanRequestCoordinator.shared
    @State private var draft: String = ""
    @State private var sending = false

    private var orderedMessages: [HandymanRequestMessageRow] {
        coordinator.messages.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if orderedMessages.isEmpty {
                    emptyState
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(orderedMessages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        }
                        .onAppear {
                            if let last = orderedMessages.last?.id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                                }
                            }
                        }
                        .onChange(of: orderedMessages.count) { _, _ in
                            if let last = orderedMessages.last?.id {
                                withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                            }
                        }
                    }
                }

                composer
            }
            .background(HavenColors.background)
            .navigationTitle(vendor?.companyName ?? "Handyman")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .task {
                if let visit { await coordinator.load(visit: visit, vendor: vendor) }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            ZStack {
                Circle()
                    .fill(HavenColors.actionPale)
                    .frame(width: 72, height: 72)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(HavenColors.actionPressed)
            }
            Text("Start a conversation")
                .font(HavenTypography.fraunces(size: 19, weight: 600))
                .foregroundStyle(HavenColors.navy900)
            Text("Ask a question, request a change, or share a photo. Your handyman gets it in their app right away.")
                .font(.system(size: 13))
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                TextField("Message your handyman…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(HavenColors.beige200)
                    )

                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: sending ? "ellipsis" : "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(canSend ? HavenColors.action : HavenColors.beige400)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(HavenColors.surface)
        }
    }

    private var canSend: Bool {
        !sending && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() async {
        guard let visit, let householdId, !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let text = draft
        sending = true
        let ok = await coordinator.sendMessage(
            text: text,
            visit: visit,
            vendor: vendor,
            householdId: householdId,
            propertyId: propertyId
        )
        await MainActor.run {
            sending = false
            if ok {
                draft = ""
                Haptics.success()
            } else {
                Haptics.error()
            }
        }
    }
}

// MARK: - Message bubble

private struct MessageBubble: View {
    let message: HandymanRequestMessageRow

    private var isFromHomeowner: Bool { message.senderRole == "homeowner" }
    private var isSystemEvent: Bool {
        message.typedKind == .proposeTime || message.typedKind == .acceptTime || message.typedKind == .declineTime
    }

    var body: some View {
        if isSystemEvent {
            systemEventRow
        } else if isFromHomeowner {
            HStack {
                Spacer(minLength: 40)
                bubble(background: HavenColors.action, foreground: .white, alignment: .trailing)
            }
        } else {
            HStack {
                bubble(background: HavenColors.surface, foreground: HavenColors.navy900, alignment: .leading)
                Spacer(minLength: 40)
            }
        }
    }

    private func bubble(background: Color, foreground: Color, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(message.body)
                .font(.system(size: 14))
                .foregroundStyle(foreground)
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
            Text(message.createdAt, format: .relative(presentation: .named))
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(foreground.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(background == HavenColors.surface ? HavenColors.beige200 : Color.clear, lineWidth: 1)
        )
    }

    private var systemEventRow: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: iconForEvent)
                    .font(.system(size: 11, weight: .semibold))
                Text(message.body.isEmpty ? defaultEventLabel : message.body)
                    .font(.system(size: 11.5, weight: .semibold))
            }
            .foregroundStyle(HavenColors.success)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(HavenColors.success.opacity(0.12))
            )
            Spacer()
        }
    }

    private var iconForEvent: String {
        switch message.typedKind {
        case .proposeTime: return "calendar.badge.plus"
        case .acceptTime: return "checkmark.seal.fill"
        case .declineTime: return "xmark.circle"
        default: return "info.circle"
        }
    }

    private var defaultEventLabel: String {
        switch message.typedKind {
        case .proposeTime: return "Time proposed"
        case .acceptTime: return "Time confirmed"
        case .declineTime: return "Time declined"
        default: return ""
        }
    }
}

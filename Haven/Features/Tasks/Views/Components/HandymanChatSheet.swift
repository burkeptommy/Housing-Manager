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
    @State private var counterDate: Date = Date().addingTimeInterval(60 * 60 * 24)
    @State private var showingCounterSheet = false
    @State private var counteringMessageId: UUID?
    @State private var actingOnProposalId: UUID?
    @State private var presentingQuoteReview = false

    private var orderedMessages: [HandymanRequestMessageRow] {
        coordinator.messages.sorted { $0.createdAt < $1.createdAt }
    }

    /// The id of the most recent vendor-side propose_time event that
    /// hasn't been resolved by a later accept_time or homeowner-side
    /// propose_time. Only this card shows live action buttons —
    /// older proposals render as historical context.
    private var liveProposalId: UUID? {
        let sorted = orderedMessages
        guard let lastVendorPropose = sorted.last(where: {
            $0.typedKind == .proposeTime && $0.senderRole != "homeowner"
        }) else { return nil }
        // Anything more recent than the vendor proposal that resolves it
        // (accept, or our own counter) means the proposal is stale.
        let resolvers = sorted.drop { $0.id != lastVendorPropose.id }.dropFirst()
        let resolved = resolvers.contains {
            $0.typedKind == .acceptTime ||
            ($0.typedKind == .proposeTime && $0.senderRole == "homeowner")
        }
        return resolved ? nil : lastVendorPropose.id
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
                                    bubble(for: message)
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
            .sheet(isPresented: $showingCounterSheet) {
                counterSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $presentingQuoteReview) {
                HandymanQuoteReviewSheet(
                    vendor: vendor,
                    onMessage: { presentingQuoteReview = false }
                )
            }
        }
    }

    // MARK: - Counter-time sheet

    private var counterSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PROPOSE A DIFFERENT TIME")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.32)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("When works for you?")
                        .font(HavenTypography.fraunces(size: 22, weight: 600))
                        .foregroundStyle(HavenColors.navy900)
                    Text("\(vendor?.companyName ?? "Your handyman") will see this in their app right away.")
                        .font(.system(size: 13))
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineSpacing(2)
                }

                DatePicker(
                    "Proposed time",
                    selection: $counterDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(HavenColors.action)

                Spacer()

                Button {
                    Task { await submitCounter() }
                } label: {
                    HStack {
                        if actingOnProposalId != nil {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send proposal")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(HavenColors.action)
                    )
                }
                .buttonStyle(.plain)
                .disabled(actingOnProposalId != nil)
            }
            .padding(20)
            .navigationTitle("Counter-propose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showingCounterSheet = false
                        counteringMessageId = nil
                    }
                }
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

    @ViewBuilder
    private func bubble(for message: HandymanRequestMessageRow) -> some View {
        MessageBubble(
            message: message,
            isLive: message.id == liveProposalId,
            isActing: message.id == actingOnProposalId,
            vendorName: vendor?.companyName,
            onApprove: { await approveProposal(messageId: message.id) },
            onCounter: { startCounter(for: message) },
            onReviewQuote: { presentingQuoteReview = true }
        )
    }

    private func startCounter(for message: HandymanRequestMessageRow) {
        counteringMessageId = message.id
        // Default the picker to the proposed time shifted +1 day so the
        // user nudges instead of retyping from scratch.
        counterDate = (message.proposedTime ?? Date()).addingTimeInterval(60 * 60 * 24)
        showingCounterSheet = true
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

    private func approveProposal(messageId: UUID) async {
        actingOnProposalId = messageId
        let ok = await coordinator.acceptProposedTime()
        await MainActor.run {
            actingOnProposalId = nil
            if ok { Haptics.success() } else { Haptics.error() }
        }
    }

    private func submitCounter() async {
        actingOnProposalId = counteringMessageId
        let ok = await coordinator.proposeCounterTime(counterDate)
        await MainActor.run {
            actingOnProposalId = nil
            counteringMessageId = nil
            if ok {
                Haptics.success()
                showingCounterSheet = false
            } else {
                Haptics.error()
            }
        }
    }
}

// MARK: - Message bubble

private struct MessageBubble: View {
    let message: HandymanRequestMessageRow
    /// True when this is the most recent unresolved vendor proposal —
    /// shows live Approve/Counter buttons. Older or already-resolved
    /// proposals render historically without buttons.
    let isLive: Bool
    /// True while an Approve/Counter request is in flight for this card.
    let isActing: Bool
    let vendorName: String?
    let onApprove: () async -> Void
    let onCounter: () -> Void
    let onReviewQuote: () -> Void

    private var isFromHomeowner: Bool { message.senderRole == "homeowner" }

    var body: some View {
        switch message.typedKind {
        case .proposeTime:
            proposalCard
        case .quoteSent:
            quoteCard
        case .acceptTime, .declineTime:
            systemEventRow
        case .text:
            if isFromHomeowner {
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
    }

    // MARK: - Quote card (rich, with Review CTA)

    private var quoteCard: some View {
        let total = message.quoteTotal ?? 0
        let count = message.quoteLineItemCount ?? 0
        let totalLabel = "$" + (Int(total)).formatted(.number.grouping(.automatic))

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                Text("QUOTE READY TO REVIEW")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Text(message.createdAt, format: .relative(presentation: .named))
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(HavenColors.textTertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(totalLabel)
                    .font(HavenTypography.fraunces(size: 28, weight: 600))
                    .foregroundStyle(HavenColors.navy900)
                if count > 0 {
                    Text("\(count) line item\(count == 1 ? "" : "s") from \(vendorName ?? "your handyman")")
                        .font(.system(size: 13))
                        .foregroundStyle(HavenColors.textSecondary)
                } else if let vendor = vendorName {
                    Text("From \(vendor)")
                        .font(.system(size: 13))
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }

            Button {
                onReviewQuote()
            } label: {
                HStack(spacing: 6) {
                    Text("Review quote")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(HavenColors.action)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HavenColors.action.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Text bubble

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

    // MARK: - Proposal card (rich, with actions)

    private var proposalCard: some View {
        let proposed = message.proposedTime
        let proposedBy: String = isFromHomeowner ? "You" : (vendorName ?? "Your handyman")
        let isLiveVendorProposal = isLive && !isFromHomeowner

        return VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                Text(isFromHomeowner ? "YOU PROPOSED A TIME" : "TIME PROPOSAL")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Text(message.createdAt, format: .relative(presentation: .named))
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(HavenColors.textTertiary)
            }

            // Headline + proposed date
            VStack(alignment: .leading, spacing: 6) {
                Text("\(proposedBy) suggested:")
                    .font(.system(size: 13))
                    .foregroundStyle(HavenColors.textSecondary)
                if let proposed {
                    Text(proposed.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(HavenTypography.fraunces(size: 19, weight: 600))
                        .foregroundStyle(HavenColors.navy900)
                    Text(proposed.formatted(date: .omitted, time: .shortened))
                        .font(HavenTypography.fraunces(size: 17, weight: 500))
                        .foregroundStyle(HavenColors.navy700)
                } else {
                    Text("A new visit time")
                        .font(HavenTypography.fraunces(size: 17, weight: 500))
                        .foregroundStyle(HavenColors.navy900)
                }
            }

            // Optional vendor note
            if !message.body.isEmpty, message.body != defaultProposalBody {
                Text(message.body)
                    .font(.system(size: 13))
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineSpacing(2)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(HavenColors.beige200.opacity(0.6))
                    )
            }

            // Actions — only on the most recent unresolved vendor proposal
            if isLiveVendorProposal {
                HStack(spacing: 8) {
                    Button {
                        Task { await onApprove() }
                    } label: {
                        HStack(spacing: 6) {
                            if isActing {
                                ProgressView().tint(.white).controlSize(.small)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            Text("Approve")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(HavenColors.action)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isActing)

                    Button {
                        onCounter()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Counter")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(HavenColors.navy700)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(HavenColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(HavenColors.beige300, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isActing)
                }
            } else if !isFromHomeowner {
                // Vendor proposal that's been resolved — show subtle status
                Text("Resolved")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(HavenColors.beige200)
                    )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isLiveVendorProposal ? HavenColors.action.opacity(0.35) : HavenColors.beige200, lineWidth: 1)
        )
    }

    // MARK: - Accept/decline event row (compact pill)

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

    /// The default body the RPC stamps on a propose_time message. We
    /// suppress the "Optional vendor note" block when the body matches
    /// this so we don't render the same string twice.
    private var defaultProposalBody: String {
        isFromHomeowner ? "Counter time proposed" : "New time proposed"
    }
}

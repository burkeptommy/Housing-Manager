import SwiftUI

/// Friend feedback (May 2026) — surfaces the active state of a Chez-
/// owned task inside the task detail sheet. Without this, the homeowner
/// only saw the toggle "Chez owns this" with no read on what Chez has
/// actually done. The card pulls the parent `chez_requests` row + the
/// most-recent messages so the homeowner can see "Chez is on it",
/// "Chez replies by Tue, May 27", and the last system / concierge
/// message in the thread — no extra navigation required.
///
/// Tap "View full thread →" to push `ChezRequestDetailView` and reach
/// the full message + composer surface.
struct ChezTaskActivityCard: View {
    let taskTitle: String
    let chezRequestId: UUID
    var onOpenThread: ((UUID) -> Void)?

    @State private var request: ChezRequestRow?
    @State private var messages: [ChezMessageRow] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    private let maxMessages: Int = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if isLoading {
                loadingRow
            } else if let request {
                if !slaCaption(for: request).isEmpty {
                    Text(slaCaption(for: request))
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                if !relevantMessages.isEmpty {
                    Divider()
                        .background(HavenColors.action.opacity(0.15))
                    activityFeed
                }
                openThreadButton(requestId: request.id)
            } else if let errorMessage {
                Text(errorMessage)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            } else {
                Text("Chez activity will appear here once available.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.action.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(HavenColors.action.opacity(0.2), lineWidth: 1)
        )
        .task(id: chezRequestId) {
            await load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .chezRequestChanged)) { _ in
            Task { await load() }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.14))
                    .frame(width: 28, height: 28)
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            Text("Chez is on it")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer(minLength: 8)
            if let request {
                ChezStatusBadge(status: request.typedStatus)
            }
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 8) {
            ProgressView().scaleEffect(0.8).tint(HavenColors.action)
            Text("Loading activity…")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
        }
    }

    private var activityFeed: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(relevantMessages) { message in
                messageRow(message)
            }
        }
    }

    private func messageRow(_ message: ChezMessageRow) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconFor(role: message.typedRole))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(roleColor(for: message.typedRole))
                .frame(width: 16, alignment: .center)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(message.content)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(timestamp(for: message.createdAt))
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            Spacer(minLength: 0)
        }
    }

    private func openThreadButton(requestId: UUID) -> some View {
        Button {
            Haptics.light()
            onOpenThread?(requestId)
        } label: {
            HStack(spacing: 6) {
                Text("View full thread")
                    .font(HavenTypography.uiLabel)
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(HavenColors.action)
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    // MARK: - Data

    private var relevantMessages: [ChezMessageRow] {
        // Surface chez + system messages first — they're the "Chez did
        // something" beats. Customer-authored messages are visible in
        // the full thread; the card stays focused on Chez activity.
        messages
            .filter { row in
                row.typedRole == .concierge || row.typedRole == .system
            }
            .sorted { lhs, rhs in lhs.createdAt > rhs.createdAt }
            .prefix(maxMessages)
            .map { $0 }
    }

    @MainActor
    private func load() async {
        isLoading = request == nil
        defer { isLoading = false }
        do {
            async let req = DatabaseService.shared.fetchChezRequest(id: chezRequestId)
            async let msgs = DatabaseService.shared.fetchChezMessages(requestId: chezRequestId)
            let (loadedRequest, loadedMessages) = try await (req, msgs)
            self.request = loadedRequest
            self.messages = loadedMessages
            self.errorMessage = nil
        } catch {
            self.errorMessage = "Couldn't load Chez activity right now."
        }
    }

    private func slaCaption(for request: ChezRequestRow) -> String {
        request.homeownerSlaCaption
    }

    private func iconFor(role: ChezMessageRole) -> String {
        switch role {
        case .concierge: return "person.fill.questionmark"
        case .system: return "info.circle"
        case .user: return "person.fill"
        }
    }

    private func roleColor(for role: ChezMessageRole) -> Color {
        switch role {
        case .concierge: return HavenColors.action
        case .system: return HavenColors.textSecondary
        case .user: return HavenColors.navy700
        }
    }

    private func timestamp(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

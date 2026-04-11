import SwiftUI

struct SecurityDashboardView: View {
    @StateObject private var viewModel = SecurityDashboardViewModel()
    @State private var showDeleteChatConfirmation = false
    @State private var chatDeleteComplete = false

    private var otherHouseholdUsers: [UserRow] {
        viewModel.householdUsers.filter { $0.id != viewModel.currentUserId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                encryptionStatusSection
                accessLogSection
                dataMapSection
                whoCanAccessSection
                vaultLockSection
                aiDataSection
                privacyCommitmentSection
            }
            .padding()
        }
        .background(HavenColors.background)
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.large)
        .trackScreen("SecurityDashboardView")
        .task { await viewModel.load() }
    }

    // MARK: - Section 1: Encryption Status

    private var encryptionStatusSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 32))
                    .foregroundStyle(HavenColors.success)
                    .frame(width: 48, height: 48)
                    .background(HavenColors.success.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("All \(viewModel.documentCount) Documents Encrypted")
                        .font(HavenTypography.fraunces(size: 14, weight: 600))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("AES-256 encryption at rest. TLS 1.3 in transit.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 2: Access Log

    private var accessLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(HavenColors.navy)
                Text("ACCESS LOG")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
            }

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SecurityDashboardViewModel.AccessLogFilter.allCases, id: \.self) { filter in
                        Button {
                            viewModel.selectedFilter = filter
                        } label: {
                            Text(filter.rawValue)
                                .font(HavenTypography.uiLabelMedium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    viewModel.selectedFilter == filter
                                        ? HavenColors.navy
                                        : HavenColors.surfaceSecondary
                                )
                                .foregroundStyle(
                                    viewModel.selectedFilter == filter
                                        ? HavenColors.textOnNavy
                                        : HavenColors.textPrimary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            if viewModel.filteredLogs.isEmpty {
                Text("Activity will appear here as you use Haven")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.filteredLogs.prefix(viewModel.showAllLogs ? 200 : 5).enumerated()), id: \.element.id) { index, log in
                        AccessLogEntryRow(
                            log: log,
                            actorName: viewModel.displayName(for: log.userId),
                            isEvenRow: index % 2 == 0
                        )
                    }
                }

                if viewModel.filteredLogs.count > 5 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.showAllLogs.toggle()
                        }
                    } label: {
                        HStack {
                            Text(viewModel.showAllLogs ? "Show Less" : "View All Activity (\(viewModel.filteredLogs.count))")
                                .font(HavenTypography.uiLabelSmall)
                            Image(systemName: viewModel.showAllLogs ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(HavenColors.navy700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .padding()
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 3: Data Map

    private var dataMapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "map")
                    .foregroundStyle(HavenColors.navy)
                Text("WHERE YOUR DATA LIVES")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
            }

            DataMapRow(
                icon: "doc.fill",
                title: "Documents",
                detail: "Encrypted on secure cloud servers (US)"
            )
            DataMapRow(
                icon: "key.fill",
                title: "Encryption Keys",
                detail: "Isolated vault, never exposed to app or API"
            )
            DataMapRow(
                icon: "brain",
                title: "AI Processing",
                detail: "Temporary, in-memory only, no persistent storage of raw content"
            )
            DataMapRow(
                icon: "text.book.closed",
                title: "Access Logs",
                detail: "Immutable, append-only, visible to you at all times"
            )
        }
        .padding()
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 4: Who Can Access

    private var whoCanAccessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(HavenColors.navy)
                Text("WHO CAN ACCESS YOUR DOCUMENTS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
            }

            AccessActorRow(
                icon: "person.fill.checkmark",
                iconColor: HavenColors.success,
                title: "You",
                detail: "Full access. Every document, every time. Authenticated with \(AuthService.biometricName)."
            )

            // Show other linked household members
            if otherHouseholdUsers.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.system(size: 16))
                        .foregroundStyle(HavenColors.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(HavenColors.surfaceSecondary)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No other linked accounts")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("Invite your spouse or family from Settings \u{2192} Family Members to share full access.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            } else {
                ForEach(otherHouseholdUsers, id: \.id) { user in
                    AccessActorRow(
                        icon: "person.fill.checkmark",
                        iconColor: HavenColors.success,
                        title: user.fullName ?? "Household Member",
                        detail: "Full access as a linked household member. All activity is logged."
                    )
                }
            }

            AccessActorRow(
                icon: "brain.head.profile",
                iconColor: HavenColors.info,
                title: "Alfred",
                detail: "Analyzes your documents in isolated environments to provide summaries, flag issues, and answer your questions. Cannot share your data with other users. Every AI interaction is logged above."
            )

            AccessActorRow(
                icon: "person.fill.xmark",
                iconColor: HavenColors.critical,
                title: "Haven Staff",
                detail: "Cannot open, read, view, or download your documents. Can see account-level information (how many documents you have, your subscription status) to provide customer support. Cannot access document content under any circumstances."
            )

            // Trust callout
            VStack(alignment: .leading, spacing: 8) {
                Text("This isn't a promise \u{2014} it's how Haven is built. Your encryption keys are stored in an isolated vault with no human access. There is no admin panel to view your files. There is no back door. If you want to verify this, your access log above shows every single interaction with your data, and it cannot be edited or deleted by anyone \u{2014} including us.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .italic()
            }
            .padding()
            .background(HavenColors.navy.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 5: Vault Lock

    private var vaultLockSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(HavenColors.warning)
                Text("VAULT LOCK")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
            }

            Text("The Nuclear Option")
                .font(HavenTypography.fraunces(size: 14, weight: 600))
                .foregroundStyle(HavenColors.textPrimary)

            Text("For documents you consider too sensitive for any system to touch, Vault Lock adds device-only encryption that even Haven's servers can't break. Vault Locked documents are invisible to the AI \u{2014} they can't be analyzed, summarized, or referenced in chat. They exist in your inventory and nowhere else.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            HStack {
                Image(systemName: "lock.doc.fill")
                    .foregroundStyle(HavenColors.warning)
                Text("\(viewModel.vaultLockedDocuments.count) documents currently Vault Locked")
                    .font(Font.custom("Inter", size: 13).weight(.medium))
                Spacer()
                if !viewModel.vaultLockedDocuments.isEmpty {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            .padding()
            .background(HavenColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 5b: AI Data Management

    private var aiDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain")
                    .foregroundStyle(HavenColors.critical)
                Text("AI DATA")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
            }

            Text("Delete All Chat History")
                .font(HavenTypography.fraunces(size: 14, weight: 600))
                .foregroundStyle(HavenColors.textPrimary)

            Text("This permanently deletes every message between you and Alfred. Alfred will lose all memory and context of your previous conversations. This cannot be undone.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            Button {
                Haptics.warning()
                showDeleteChatConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text(chatDeleteComplete ? "Chat History Deleted" : "Delete All Chat History")
                        .font(Font.custom("Inter", size: 13).weight(.medium))
                }
                .foregroundStyle(chatDeleteComplete ? HavenColors.success : HavenColors.critical)
                .frame(maxWidth: .infinity)
                .padding()
                .background(chatDeleteComplete ? HavenColors.success.opacity(0.08) : HavenColors.critical.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(chatDeleteComplete)
            .confirmationDialog("Delete All Chat History?", isPresented: $showDeleteChatConfirmation) {
                Button("Delete Everything", role: .destructive) {
                    Task {
                        try? await DatabaseService.shared.deleteAllChatMessages()
                        Haptics.success()
                        chatDeleteComplete = true
                    }
                }
            } message: {
                Text("This will permanently delete all conversations with Alfred. He will have no memory of previous chats. This cannot be undone.")
            }
        }
        .padding()
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 6: Privacy Commitment

    private var privacyCommitmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(HavenColors.navy)
                Text("HAVEN SECURITY COMMITMENT")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
            }

            Group {
                Text("Your documents are encrypted at rest using AES-256 encryption. Encryption keys are stored in an isolated vault with no direct human access. Your document content is only decrypted in temporary, sealed processing environments for the purpose of serving your requests and providing AI analysis. Raw document content is never persisted in decrypted form.")

                Text("Every interaction with your data is recorded in a tamper-proof access log visible to you at all times. This log is append-only \u{2014} entries cannot be edited or deleted by anyone, including Haven staff.")

                Text("Haven does not sell, share, license, or monetize your data in any form. Your documents are used exclusively to provide you the Haven service.")

                Text("For documents requiring maximum protection, Vault Lock provides device-only encryption that no server \u{2014} including ours \u{2014} can decrypt.")
            }
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)

            Divider()

            HStack {
                Text("Questions about our security?")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
                Link(AppConfig.supportEmail, destination: URL(string: "mailto:\(AppConfig.supportEmail)")!)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.navy)
            }
        }
        .padding()
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views

private struct AccessLogEntryRow: View {
    let log: AccessLogRow
    let actorName: String
    let isEvenRow: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(humanReadableAction)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(HavenColors.textPrimary)
                if let name = log.resourceName {
                    Text(name)
                        .font(.system(size: 11))
                        .foregroundStyle(HavenColors.textSecondary)
                }
                if let date = log.createdAt {
                    Text(date, style: .relative)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isEvenRow ? HavenColors.cream : HavenColors.creamLight)
    }

    private var humanReadableAction: String {
        switch log.action {
        case "document_uploaded": return "\(actorName) uploaded a document"
        case "document_viewed": return "\(actorName) viewed a document"
        case "document_downloaded": return "\(actorName) downloaded a document"
        case "document_deleted": return "\(actorName) deleted a document"
        case "document_ai_analyzed": return "AI analyzed a document"
        case "document_ai_reanalyzed": return "AI re-analyzed a document"
        case "ai_chat_query": return "\(actorName) asked Alfred a question"
        case "ai_gap_analysis": return "AI ran gap analysis"
        case "ai_proactive_scan": return "AI proactive scan completed"
        default: return log.action.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private var iconName: String {
        switch log.action {
        case "document_uploaded": return "arrow.up.doc.fill"
        case "document_viewed": return "eye.fill"
        case "document_downloaded": return "arrow.down.doc.fill"
        case "document_deleted": return "trash.fill"
        case "document_ai_analyzed", "document_ai_reanalyzed": return "brain"
        case "ai_chat_query": return "bubble.left.fill"
        case "ai_gap_analysis": return "chart.bar.fill"
        case "ai_proactive_scan": return "shield.checkered"
        default: return "circle.fill"
        }
    }

    private var iconColor: Color {
        switch log.actorType {
        case "ai_analysis", "system": return HavenColors.navy
        case "user": return HavenColors.info
        default: return HavenColors.textTertiary
        }
    }
}

private struct DataMapRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.navy)
                .frame(width: 28, height: 28)
                .background(HavenColors.navy.opacity(0.06))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.custom("Inter", size: 13).weight(.medium))
                    .foregroundStyle(HavenColors.textPrimary)
                Text(detail)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
    }
}

private struct AccessActorRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(HavenTypography.fraunces(size: 14, weight: 600))
                    .foregroundStyle(HavenColors.textPrimary)
                Text(detail)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
    }
}

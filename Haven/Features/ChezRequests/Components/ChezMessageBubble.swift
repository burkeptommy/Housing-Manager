import SwiftUI

/// Phase 80 — One bubble in the request thread. Three role variants:
///   - user        — homeowner-authored (right-aligned salmon)
///   - concierge   — Chez-authored (left-aligned cream w/ navy text)
///   - system      — status-change row (centered grey divider)
struct ChezMessageBubble: View {
    let message: ChezMessageRow
    let attachmentURLResolver: ((ChezAttachmentMeta) async -> URL?)?
    /// Phase 80.1 — Called when the user taps "Counter" on a proposal
    /// card. Parent (the detail view) opens the reply composer
    /// prefilled with a counter template. Optional so existing call
    /// sites stay source-compatible.
    var onProposalCounter: ((ChezProposal) -> Void)? = nil

    var body: some View {
        switch message.typedRole {
        case .system:
            systemBody
        case .user:
            userBody
        case .concierge:
            conciergeBody
        }
    }

    // MARK: System (centered)
    private var systemBody: some View {
        HStack {
            Spacer()
            Text(message.content)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(HavenColors.beige200.opacity(0.6))
                )
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: Homeowner (right)
    private var userBody: some View {
        HStack(alignment: .bottom) {
            Spacer(minLength: 48)
            VStack(alignment: .trailing, spacing: 6) {
                attachmentColumn(alignment: .trailing)
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(HavenTypography.body)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(HavenColors.action)
                        )
                        .frame(maxWidth: 320, alignment: .trailing)
                }
                Text(timestampString)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    // MARK: Concierge (left)
    private var conciergeBody: some View {
        HStack(alignment: .bottom) {
            ZStack {
                Circle().fill(HavenColors.navy800)
                    .frame(width: 28, height: 28)
                Text("C")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(Color.white)
            }
            VStack(alignment: .leading, spacing: 6) {
                attachmentColumn(alignment: .leading)
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(HavenColors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(HavenColors.beige200, lineWidth: 1)
                                )
                        )
                        .frame(maxWidth: 320, alignment: .leading)
                }
                // Phase 80.1 — Inline structured proposal card. Renders
                // when the message carries a `proposal` JSONB payload.
                // Sits between the text and the timestamp so it reads
                // as part of the same concierge message.
                if let proposal = message.proposal {
                    ChezProposalCard(
                        proposal: proposal,
                        messageId: message.id,
                        onCounter: onProposalCounter
                    )
                    .frame(maxWidth: 360, alignment: .leading)
                }
                Text(timestampString)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer(minLength: 48)
        }
    }

    // MARK: Attachments
    @ViewBuilder
    private func attachmentColumn(alignment: HorizontalAlignment) -> some View {
        if !message.attachments.isEmpty {
            VStack(alignment: alignment, spacing: 6) {
                ForEach(message.attachments, id: \.path) { att in
                    ChezAttachmentChip(meta: att, resolver: attachmentURLResolver)
                }
            }
        }
    }

    private var timestampString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let cal = Calendar.current
        if cal.isDateInToday(message.createdAt) {
            return formatter.string(from: message.createdAt)
        }
        formatter.dateStyle = .short
        return formatter.string(from: message.createdAt)
    }
}

/// Single attachment chip. For images, renders an inline preview when
/// the resolver returns a usable URL. For other types (PDF, etc.),
/// renders a tappable file chip.
struct ChezAttachmentChip: View {
    let meta: ChezAttachmentMeta
    let resolver: ((ChezAttachmentMeta) async -> URL?)?
    @State private var url: URL?

    var body: some View {
        Group {
            if meta.isImage, let url {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.1)
                }
                .frame(maxWidth: 220, maxHeight: 160)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: meta.isImage ? "photo.fill" : "doc.fill")
                        .foregroundStyle(HavenColors.textSecondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(meta.filename)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                        Text(byteSizeString)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(HavenColors.beige200.opacity(0.5))
                )
            }
        }
        .task {
            if url == nil, let resolver {
                url = await resolver(meta)
            }
        }
    }

    private var byteSizeString: String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB, .useMB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(meta.sizeBytes))
    }
}

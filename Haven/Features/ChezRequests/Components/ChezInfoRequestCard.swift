import SwiftUI
import PhotosUI

/// Wave 6 — Inline info-request card. Renders inside a
/// `ChezMessageBubble` when a concierge-role message carries a
/// `proposal` of kind `info_request`: Chez needs a few specifics from
/// the homeowner (a time window, a budget confirmation, a photo, a
/// choice) before work can continue. One input per field:
///   • date_window / choice → single-select chip rows over `options`
///   • budget_confirm       → "Approve up to $X" / "Not yet" (yes/no)
///   • photo                → photo picker tile (uploads first; the
///                            answer value is the storage path; empty
///                            string when the homeowner skips)
///   • anything else        → plain text field (forward compatible)
///
/// Required fields gate the "Send to Chez" CTA. After a successful
/// send the card flips optimistically to the quiet answered-summary
/// state; the server-side reply lands on the next thread refresh.
struct ChezInfoRequestCard: View {
    let proposal: ChezProposal
    let messageId: UUID

    @State private var answers: [String: String] = [:]
    @State private var uploadedPhotoMetas: [String: ChezAttachmentMeta] = [:]
    @State private var pickedPhotoItems: [String: PhotosPickerItem] = [:]
    @State private var uploadingFields: Set<String> = []
    @State private var isSending: Bool = false
    @State private var localReply: ChezInfoRequestReply?   // optimistic flip
    @State private var errorMessage: String?

    private var fields: [ChezInfoRequestField] {
        proposal.infoRequestFields ?? []
    }

    /// The reply to render in the answered state — the optimistic
    /// local one wins until the server copy arrives on refresh.
    private var effectiveReply: ChezInfoRequestReply? {
        localReply ?? proposal.reply
    }

    private var isAnswered: Bool {
        effectiveReply != nil || proposal.typedStatus == .answered
    }

    var body: some View {
        Group {
            if fields.isEmpty && !isAnswered {
                // Malformed or empty payload: degrade to the quiet
                // caption, same treatment as unknown kinds. The message
                // content above carries whatever Chez wrote.
                quietCaption
            } else if isAnswered {
                answeredBody
            } else {
                pendingBody
            }
        }
    }

    // MARK: - Pending state

    private var pendingBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            ForEach(fields) { field in
                fieldSection(field)
            }
            sendButton
            if let err = errorMessage {
                Text(err)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
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
                .strokeBorder(HavenColors.action.opacity(0.3), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.bubble.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.action)
            Text("Chez needs a few details")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer()
        }
    }

    // MARK: - Per-field rendering

    @ViewBuilder
    private func fieldSection(_ field: ChezInfoRequestField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = field.label, !label.isEmpty {
                HStack(spacing: 6) {
                    Text(label)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if field.isRequired && !hasAnswer(field) {
                        Text("Required")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
            switch field.typedFieldType {
            case .dateWindow, .choice:
                optionChips(field)
            case .budgetConfirm:
                budgetButtons(field)
            case .photo:
                photoTile(field)
            case nil:
                textInput(field)
            }
        }
    }

    /// Single-select chip rows for date_window / choice fields.
    private func optionChips(_ field: ChezInfoRequestField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(field.options ?? [], id: \.self) { option in
                let selected = answers[field.id] == option
                Button {
                    Haptics.selection()
                    answers[field.id] = option
                } label: {
                    HStack(spacing: 8) {
                        Text(option)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(selected ? Color.white : HavenColors.textPrimary)
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.white)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selected ? HavenColors.navy800 : HavenColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(selected ? HavenColors.navy800 : HavenColors.beige300, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSending)
            }
        }
    }

    /// Two-button yes/no for budget_confirm fields.
    private func budgetButtons(_ field: ChezInfoRequestField) -> some View {
        HStack(spacing: 8) {
            let approveSelected = answers[field.id] == "yes"
            let declineSelected = answers[field.id] == "no"
            Button {
                Haptics.selection()
                answers[field.id] = "yes"
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                    Text(approveLabel(for: field))
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(approveSelected ? Color.white : HavenColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(approveSelected ? HavenColors.success : HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(approveSelected ? HavenColors.success : HavenColors.beige300, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isSending)

            Button {
                Haptics.selection()
                answers[field.id] = "no"
            } label: {
                Text("Not yet")
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                    .foregroundStyle(declineSelected ? Color.white : HavenColors.navy700)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(declineSelected ? HavenColors.navy800 : HavenColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(declineSelected ? HavenColors.navy800 : HavenColors.beige300, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isSending)
        }
    }

    private func approveLabel(for field: ChezInfoRequestField) -> String {
        if let cents = field.amountCents, cents > 0 {
            return "Approve up to \(Self.formatCents(cents))"
        }
        return "Approve"
    }

    /// Photo answer tile. Uploads through the same pipeline the reply
    /// composer uses; the answer value is the returned storage path.
    /// Non-required fields can be skipped (answer value = "").
    @ViewBuilder
    private func photoTile(_ field: ChezInfoRequestField) -> some View {
        if let meta = uploadedPhotoMetas[field.id] {
            HStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.success)
                Text(meta.filename)
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                Spacer()
                Button {
                    uploadedPhotoMetas[field.id] = nil
                    pickedPhotoItems[field.id] = nil
                    answers[field.id] = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .buttonStyle(.plain)
                .disabled(isSending)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HavenColors.success.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(HavenColors.success.opacity(0.3), lineWidth: 1)
            )
        } else if uploadingFields.contains(field.id) {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Uploading photo...")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HavenColors.beige200.opacity(0.5))
            )
        } else if answers[field.id] == "" {
            // Explicitly skipped.
            HStack(spacing: 8) {
                Text("Skipped")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Button {
                    answers[field.id] = nil
                } label: {
                    Text("Add photo instead")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.navy700)
                }
                .buttonStyle(.plain)
                .disabled(isSending)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HavenColors.beige200.opacity(0.5))
            )
        } else {
            VStack(alignment: .leading, spacing: 6) {
                PhotosPicker(
                    selection: photoBinding(for: field.id),
                    matching: .images
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                        Text("Add photo")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy700)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(HavenColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(HavenColors.beige300, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    )
                }
                .disabled(isSending)
                if !field.isRequired {
                    Button {
                        Haptics.selection()
                        answers[field.id] = ""
                    } label: {
                        Text("Skip this one")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                }
            }
        }
    }

    /// Forward-compatible fallback for field types this build doesn't
    /// know about: a plain text input.
    private func textInput(_ field: ChezInfoRequestField) -> some View {
        TextField("Your answer", text: textBinding(for: field.id), axis: .vertical)
            .font(HavenTypography.body)
            .lineLimit(1...4)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(HavenColors.beige300, lineWidth: 1)
            )
            .disabled(isSending)
    }

    // MARK: - CTA

    private var canSend: Bool {
        requiredComplete && !isSending && uploadingFields.isEmpty
    }

    private var requiredComplete: Bool {
        fields.filter(\.isRequired).allSatisfy { field in
            let value = answers[field.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !value.isEmpty
        }
    }

    private var sendButton: some View {
        Button {
            Task { await send() }
        } label: {
            HStack(spacing: 8) {
                if isSending {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text("Send to Chez")
                    .font(HavenTypography.uiButton)
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(canSend ? HavenColors.action : HavenColors.action.opacity(0.4))
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
    }

    // MARK: - Answered state

    private var answeredBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.success)
                Text("Details sent to Chez")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
            }
            if let reply = effectiveReply {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(fields) { field in
                        if let value = answeredValue(for: field, in: reply) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(field.label ?? "Answer")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .lineLimit(2)
                                Spacer(minLength: 8)
                                Text(value)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
                Text(answeredCaption(reply.answeredAt))
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            } else {
                Text(answeredCaption(nil))
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
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

    private func answeredValue(for field: ChezInfoRequestField, in reply: ChezInfoRequestReply) -> String? {
        guard let raw = reply.answers[field.id] else { return nil }
        switch field.typedFieldType {
        case .budgetConfirm:
            return raw == "yes" ? "Approved" : "Not yet"
        case .photo:
            return raw.isEmpty ? "Skipped" : "Photo sent"
        default:
            return raw.isEmpty ? nil : raw
        }
    }

    private func answeredCaption(_ date: Date?) -> String {
        guard let date else { return "Answered" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Answered \(formatter.string(from: date))"
    }

    // MARK: - Quiet fallback (empty field payload)

    private var quietCaption: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HavenColors.textSecondary)
            Text("Update from Chez")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(HavenColors.beige200.opacity(0.5))
        )
    }

    // MARK: - Bindings

    private func textBinding(for fieldId: String) -> Binding<String> {
        Binding(
            get: { answers[fieldId] ?? "" },
            set: { answers[fieldId] = $0 }
        )
    }

    private func photoBinding(for fieldId: String) -> Binding<PhotosPickerItem?> {
        Binding(
            get: { pickedPhotoItems[fieldId] },
            set: { item in
                pickedPhotoItems[fieldId] = item
                guard let item else { return }
                Task { await uploadPhoto(item, fieldId: fieldId) }
            }
        )
    }

    private func hasAnswer(_ field: ChezInfoRequestField) -> Bool {
        let value = answers[field.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !value.isEmpty
    }

    // MARK: - Photo upload

    private func uploadPhoto(_ item: PhotosPickerItem, fieldId: String) async {
        uploadingFields.insert(fieldId)
        defer { uploadingFields.remove(fieldId) }
        errorMessage = nil
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            errorMessage = "Couldn't read that photo. Try another one."
            return
        }
        do {
            let meta = try await HavenSupabase.uploadChezAttachment(
                data: data,
                filename: "chez-info-\(UUID().uuidString.prefix(8)).jpg",
                mimeType: "image/jpeg"
            )
            uploadedPhotoMetas[fieldId] = meta
            answers[fieldId] = meta.path
            Haptics.light()
        } catch {
            pickedPhotoItems[fieldId] = nil
            errorMessage = "Photo upload failed: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    // MARK: - Send

    /// Only ship answers the homeowner actually gave. Empty values are
    /// dropped, except photo skips which are an explicit "" per the
    /// server contract.
    private var finalAnswers: [String: String] {
        var out: [String: String] = [:]
        for field in fields {
            guard let raw = answers[field.id] else { continue }
            if field.typedFieldType == .photo {
                out[field.id] = raw
                continue
            }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                out[field.id] = trimmed
            }
        }
        return out
    }

    private func send() async {
        guard canSend else { return }
        isSending = true
        defer { isSending = false }
        errorMessage = nil
        let sentAnswers = finalAnswers
        let sentAttachments = fields.compactMap { uploadedPhotoMetas[$0.id] }
        do {
            try await HavenSupabase.answerChezInfoRequest(
                messageId: messageId,
                answers: sentAnswers,
                attachments: sentAttachments.isEmpty ? nil : sentAttachments
            )
            Haptics.success()
            Analytics.track(.chezInfoRequestAnswered, [
                "field_count": sentAnswers.count,
            ])
            // Optimistic flip — the server copy replaces this on the
            // next thread refresh.
            withAnimation(HavenTheme.animationStandard) {
                localReply = ChezInfoRequestReply(
                    answers: sentAnswers,
                    attachments: sentAttachments,
                    answeredAt: Date()
                )
            }
            NotificationCenter.default.post(name: .chezRequestChanged, object: nil)
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    // MARK: - Formatting

    static func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = cents % 100 == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$\(cents / 100)"
    }
}

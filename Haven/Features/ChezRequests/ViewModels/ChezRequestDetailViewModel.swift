import Foundation
import SwiftUI
import PhotosUI

/// Phase 80 — Chez Request Detail VM. Owns:
///   • the request header (status, sla, context)
///   • the message thread
///   • the inline reply composer (text + attachments)
///   • the reopen-from-resolved transition
///
/// Loads on init via `load(requestId:)` and refreshes from
/// `.chezRequestChanged` notifications. Mark-read fires once on first
/// successful load.

@MainActor
final class ChezRequestDetailViewModel: ObservableObject {
    @Published var request: ChezRequestRow?
    @Published var messages: [ChezMessageRow] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Reply composer state
    @Published var replyText: String = ""
    @Published var replyPickedItems: [PhotosPickerItem] = []
    @Published var replyAttachments: [ChezAttachmentMeta] = []
    @Published var isReplyUploading: Bool = false
    @Published var isReplySending: Bool = false

    private let requestId: UUID
    private var didMarkRead: Bool = false

    init(requestId: UUID) {
        self.requestId = requestId
    }

    var canSend: Bool {
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasAttachments = !replyAttachments.isEmpty
        return (!trimmed.isEmpty || hasAttachments)
            && !isReplySending
            && !isReplyUploading
            && (request?.typedStatus != .resolved)
    }

    func load() async {
        if request == nil {
            isLoading = true
        }
        defer { isLoading = false }
        do {
            async let reqRow = DatabaseService.shared.fetchChezRequest(id: requestId)
            async let messageRows = DatabaseService.shared.fetchChezMessages(requestId: requestId)
            let (req, msgs) = try await (reqRow, messageRows)
            self.request = req
            self.messages = msgs
            // Mark-read once after successful first load (and only when
            // there's something unread to clear).
            if !didMarkRead, let r = req, r.unreadForUser {
                didMarkRead = true
                Task.detached { [requestId] in
                    try? await HavenSupabase.markChezRequestRead(requestId: requestId)
                    NotificationCenter.default.post(name: .chezRequestChanged, object: nil)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            print("[ChezRequestDetailVM] load failed: \(error)")
        }
    }

    // MARK: - Attachments

    func ingestPickedPhotos() async {
        guard !replyPickedItems.isEmpty else { return }
        isReplyUploading = true
        defer { isReplyUploading = false }
        for item in replyPickedItems {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let userId = (try? await HavenSupabase.client.auth.session.user.id.uuidString) else { continue }
            let suggestedName = "chez-photo-\(UUID().uuidString.prefix(8)).jpg"
            do {
                let path = "chez-requests/\(userId)/\(suggestedName)"
                _ = try await HavenSupabase.client.storage
                    .from("documents")
                    .upload(path: path, file: data, options: .init(contentType: "image/jpeg", upsert: false))
                replyAttachments.append(
                    ChezAttachmentMeta(
                        path: path,
                        filename: suggestedName,
                        mimeType: "image/jpeg",
                        sizeBytes: data.count,
                        uploadedAt: Date()
                    )
                )
            } catch {
                errorMessage = "Failed to upload photo: \(error.localizedDescription)"
            }
        }
        replyPickedItems.removeAll()
    }

    func ingestFile(data: Data, filename: String, mimeType: String) async {
        isReplyUploading = true
        defer { isReplyUploading = false }
        guard let userId = (try? await HavenSupabase.client.auth.session.user.id.uuidString) else {
            errorMessage = "Not signed in"
            return
        }
        let path = "chez-requests/\(userId)/\(UUID().uuidString.prefix(8))-\(filename)"
        do {
            _ = try await HavenSupabase.client.storage
                .from("documents")
                .upload(path: path, file: data, options: .init(contentType: mimeType, upsert: false))
            replyAttachments.append(
                ChezAttachmentMeta(
                    path: path,
                    filename: filename,
                    mimeType: mimeType,
                    sizeBytes: data.count,
                    uploadedAt: Date()
                )
            )
        } catch {
            errorMessage = "Failed to upload file: \(error.localizedDescription)"
        }
    }

    func removeAttachment(_ meta: ChezAttachmentMeta) {
        replyAttachments.removeAll { $0.path == meta.path }
    }

    // MARK: - Send

    func sendReply() async {
        guard canSend else { return }
        isReplySending = true
        defer { isReplySending = false }
        do {
            try await HavenSupabase.replyToChezRequest(
                requestId: requestId,
                content: replyText.trimmingCharacters(in: .whitespacesAndNewlines),
                attachments: replyAttachments.isEmpty ? nil : replyAttachments
            )
            replyText = ""
            replyAttachments.removeAll()
            Haptics.success()
            NotificationCenter.default.post(name: .chezRequestChanged, object: nil)
            Analytics.track(.chezRequestReplied, [
                "request_id": requestId.uuidString,
                "has_attachments": String(!replyAttachments.isEmpty),
            ])
            await load()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    // MARK: - Reopen

    func reopenFromResolved() async {
        guard request?.typedStatus == .resolved else { return }
        do {
            try await HavenSupabase.reopenChezRequest(requestId: requestId)
            NotificationCenter.default.post(name: .chezRequestChanged, object: nil)
            Haptics.success()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Attachment URL resolver (for inline image rendering)

    /// Async closure passed to `ChezAttachmentChip` so it can resolve
    /// a signed URL for the documents bucket. 1-hour TTL is plenty for
    /// view duration and Brandfetch-style caching takes over from there.
    func attachmentURL(for meta: ChezAttachmentMeta) async -> URL? {
        do {
            let url = try await HavenSupabase.client.storage
                .from("documents")
                .createSignedURL(path: meta.path, expiresIn: 60 * 60)
            return url
        } catch {
            print("[ChezRequestDetailVM] signed URL failed for \(meta.path): \(error)")
            return nil
        }
    }
}

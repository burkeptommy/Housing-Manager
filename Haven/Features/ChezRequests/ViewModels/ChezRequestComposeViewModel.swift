import Foundation
import SwiftUI
import PhotosUI

/// Phase 80 — Compose Sheet view model. Handles category selection,
/// summary/description editing, attachment uploads (via the existing
/// DocumentUploadManager flow into the documents bucket), and the
/// final submit call to the chez-concierge Edge Function.

@MainActor
final class ChezRequestComposeViewModel: ObservableObject {
    @Published var category: ChezCategory
    @Published var summary: String = ""
    @Published var description: String = ""
    @Published var contextHints: [String: String]
    @Published var pickedPhotoItems: [PhotosPickerItem] = []
    @Published var pendingAttachments: [ChezAttachmentMeta] = []
    @Published var isUploading: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var didSucceed: Bool = false

    /// Set by the entry-point. When non-empty the composer skips the
    /// category picker (treats the prefilled category as fixed).
    let isCategoryFixed: Bool

    init(category: ChezCategory, contextHints: [String: String], isCategoryFixed: Bool) {
        self.category = category
        self.contextHints = contextHints
        self.isCategoryFixed = isCategoryFixed
    }

    var canSubmit: Bool {
        !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSubmitting
            && !isUploading
    }

    /// Pretty-printed context list used inside the read-only "Re:" card.
    var contextLines: [(key: String, value: String)] {
        contextHints
            .filter { !$0.key.hasPrefix("_") }  // hide internal keys
            .filter { $0.key != "source_entity_type" && $0.key != "source_entity_label" }
            .sorted(by: { $0.key < $1.key })
            .map { ($0.key.replacingOccurrences(of: "_", with: " ").capitalized, $0.value) }
    }

    var hasContextCard: Bool {
        sourceEntityTitle != nil || !contextLines.isEmpty
    }

    var sourceEntityTitle: String? {
        guard let label = trimmedContextValue("source_entity_label") else { return nil }
        if let type = trimmedContextValue("source_entity_type") {
            return "\(formattedContextKey(type)): \(label)"
        }
        return label
    }

    private func trimmedContextValue(_ key: String) -> String? {
        guard let value = contextHints[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }
        return value
    }

    private func formattedContextKey(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ").capitalized
    }

    // MARK: - Photo upload pipeline
    func ingestPickedPhotos() async {
        guard !pickedPhotoItems.isEmpty else { return }
        isUploading = true
        defer { isUploading = false }
        for item in pickedPhotoItems {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let userId = (try? await HavenSupabase.client.auth.session.user.id.uuidString) else { continue }
            let suggestedName = "chez-photo-\(UUID().uuidString.prefix(8)).jpg"
            do {
                let path = "chez-requests/\(userId)/\(suggestedName)"
                _ = try await HavenSupabase.client.storage
                    .from("documents")
                    .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: false))
                pendingAttachments.append(
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
        pickedPhotoItems.removeAll()
    }

    /// Add a generic file (used for PDF picker on iOS).
    func ingestFile(data: Data, filename: String, mimeType: String) async {
        isUploading = true
        defer { isUploading = false }
        guard let userId = (try? await HavenSupabase.client.auth.session.user.id.uuidString) else {
            errorMessage = "Not signed in"
            return
        }
        let path = "chez-requests/\(userId)/\(UUID().uuidString.prefix(8))-\(filename)"
        do {
            _ = try await HavenSupabase.client.storage
                .from("documents")
                .upload(path, data: data, options: .init(contentType: mimeType, upsert: false))
            pendingAttachments.append(
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
        pendingAttachments.removeAll { $0.path == meta.path }
    }

    // MARK: - Submit
    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            _ = try await HavenSupabase.submitChezRequest(
                category: category,
                summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                context: contextHints.isEmpty ? nil : contextHints,
                attachments: pendingAttachments.isEmpty ? nil : pendingAttachments
            )
            didSucceed = true
            NotificationCenter.default.post(name: .chezRequestChanged, object: nil)
            Haptics.success()
            Analytics.track(.chezRequestSubmitted, [
                "category": category.rawValue,
                "has_attachments": String(!pendingAttachments.isEmpty),
            ])
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
}

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

    /// Phase 70.A1 follow-on K1 — the new request's id after a
    /// successful submit. ChezRequestComposeSheet reads this on the
    /// `didSucceed` change to post `.openChezRequest`, which lands the
    /// homeowner directly inside the conversation thread instead of
    /// dropping them back at whatever screen they came from.
    @Published var submittedRequestId: UUID?

    // MARK: - Wave 4: snapshot preview + homeowner intake

    /// The "What Chez already knows" preview, loaded on appear whenever
    /// the context hints carry a recognized entity id. Nil on failure or
    /// for general asks — the composer degrades to its pre-Wave-4 shape.
    @Published var snapshotPreview: ChezSnapshotPreview?
    /// Collapsed-by-default disclosure state for the snapshot card.
    @Published var isSnapshotExpanded: Bool = false

    /// Homeowner intake bindings for the "Only you can tell Chez"
    /// section. All optional; an untouched form sends no intake.
    @Published var intakeBudgetBand: ChezBudgetBand?
    @Published var intakeUrgency: ChezUrgency?
    @Published var intakePreferredWindows: Set<ChezPreferredWindow> = []
    @Published var intakeAccessNote: String = ""
    /// The prefill baseline — an unedited access note is NOT an override.
    private var initialAccessNote: String = ""

    /// Set by the entry-point. When non-empty the composer skips the
    /// category picker (treats the prefilled category as fixed).
    let isCategoryFixed: Bool

    init(category: ChezCategory, contextHints: [String: String], isCategoryFixed: Bool) {
        self.category = category
        self.contextHints = contextHints
        self.isCategoryFixed = isCategoryFixed
    }

    var canSubmit: Bool {
        // Friend feedback (May 2026): summary is no longer required.
        // When the user submits blank, we derive a one-line summary
        // from the category + source entity label via `resolvedSummary`.
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSubmitting
            && !isUploading
    }

    /// Friend feedback (May 2026): when the user leaves the summary
    /// blank, derive it from the category + source entity label so
    /// Chez always has a one-line read on the request. Every existing
    /// entry-point populates `source_entity_label` in the context dict.
    var resolvedSummary: String {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let label = contextHints["source_entity_label"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let safeLabel = (label?.isEmpty == false) ? label! : "this task"
        switch category {
        case .findVendor:     return "Find a vendor for \(safeLabel)"
        case .getQuote:       return "Get a quote for \(safeLabel)"
        case .scheduleVisit:  return "Schedule visit for \(safeLabel)"
        case .coordinateTask: return "Coordinate \(safeLabel)"
        case .findHandyman:   return "Handyman for \(safeLabel)"
        case .general:        return "Help with \(safeLabel)"
        }
    }

    /// Friend feedback (May 2026): switched from an open passthrough
    /// to an allowlist of display-safe keys so raw UUIDs (property_id,
    /// system_id, task_id) never leak into the "Re:" card. Any new
    /// context-key from a future entry-point must be added here
    /// explicitly to render.
    private static let displayContextKeys: Set<String> = [
        "task_title", "due", "due_date", "next_due_date", "scheduled_date",
        "frequency", "notes", "system_category", "system_name",
        "town", "state", "vendor_name", "project_name", "vehicle_label",
        "task_route", "estimated_cost",
        // Wave 4 — the server mirrors intake display strings into the
        // context ("budget": "Under $250", "timing": "This week") so the
        // existing "Details you sent" card shows them on the thread.
        "budget", "timing"
    ]

    /// Pretty-printed context list used inside the read-only "Re:" card.
    var contextLines: [(key: String, value: String)] {
        contextHints
            .filter { Self.displayContextKeys.contains($0.key) }
            .filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
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

    // MARK: - Wave 4: snapshot preview

    /// Recognized entity-id context keys → preview_snapshot kinds, in
    /// specificity order. A task context usually also carries system_id
    /// and property_id; the task wins because its snapshot embeds the
    /// system + service history anyway.
    private static let snapshotKindsByContextKey: [(key: String, kind: String)] = [
        ("task_id", "task"),
        ("routine_id", "routine"),
        ("contractor_id", "contractor"),
        ("project_id", "project"),
        ("vehicle_id", "vehicle"),
        ("system_id", "system"),
    ]

    /// The (kind, entityId) pair the composer should preview, if any.
    var recognizedSnapshotEntity: (kind: String, entityId: String)? {
        for entry in Self.snapshotKindsByContextKey {
            if let value = trimmedContextValue(entry.key) {
                return (entry.kind, value)
            }
        }
        return nil
    }

    var hasSnapshot: Bool {
        snapshotPreview?.snapshot != nil
    }

    /// Fires preview_snapshot when the context hints carry a recognized
    /// entity id. Failures are silent — the composer keeps its
    /// pre-Wave-4 shape and the intake form still works.
    func loadSnapshotIfPossible() async {
        guard snapshotPreview == nil,
              let entity = recognizedSnapshotEntity else { return }
        do {
            let result = try await HavenSupabase.previewChezSnapshot(
                kind: entity.kind,
                entityId: entity.entityId,
                propertyId: trimmedContextValue("property_id")
            )
            snapshotPreview = result
            if intakeAccessNote.isEmpty,
               let entry = result.snapshot?.household?.chezProfile?.logistics?.entryInstructions,
               !entry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                intakeAccessNote = entry
                initialAccessNote = entry
            }
            if intakeBudgetBand == nil, let suggestion = result.suggestedBudget {
                intakeBudgetBand = ChezBudgetBand.containing(suggested: suggestion)
            }
            Analytics.track(.chezSnapshotPreviewShown, [
                "kind": entity.kind,
                "source": "composer",
                "has_suggested_budget": String(result.suggestedBudget != nil),
            ])
        } catch {
            print("[ChezRequestCompose] preview_snapshot failed: \(error.localizedDescription)")
        }
    }

    /// Builds the optional intake payload from the form bindings.
    var currentIntake: ChezDelegationIntake? {
        ChezDelegationIntake.make(
            budgetBand: intakeBudgetBand,
            urgency: intakeUrgency,
            preferredWindows: intakePreferredWindows,
            accessNote: intakeAccessNote,
            initialAccessNote: initialAccessNote
        )
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
            let intake = currentIntake
            let request = try await HavenSupabase.submitChezRequest(
                category: category,
                summary: resolvedSummary,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                context: contextHints.isEmpty ? nil : contextHints,
                attachments: pendingAttachments.isEmpty ? nil : pendingAttachments,
                intake: intake
            )
            // K1: capture the id BEFORE flipping didSucceed so the sheet's
            // onChange handler has it available when posting .openChezRequest.
            submittedRequestId = request.id
            didSucceed = true
            NotificationCenter.default.post(name: .chezRequestChanged, object: nil)
            Haptics.success()
            Analytics.track(.chezRequestSubmitted, [
                "category": category.rawValue,
                "has_attachments": String(!pendingAttachments.isEmpty),
                "has_intake": String(intake != nil),
            ])
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
}

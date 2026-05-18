import Foundation

/// Centralized routing for "this document needs a follow-up action" → inbox item.
///
/// Background: until May 2026 two parallel upload paths existed —
/// `DocumentUploadManager` (camera scan + email forwards, background batch)
/// and `DocumentUploadViewModel` (every "+ Upload" button in the iOS app's
/// Property surfaces). The Manager path created inbox items for contractor
/// quotes / invoices / vehicle docs. The ViewModel path did not. Result:
/// users who uploaded a quote from Property → Documents tab saw their doc
/// land in the documents list but got NO inbox prompt to create a project,
/// link to an existing one, etc. The whole "needs action" pipeline was
/// silently bypassed for foreground uploads.
///
/// This helper is the single source of truth for that mapping. Both upload
/// paths now route through it after the document row + AI analysis land.
enum InboxItemFromDocument {

    /// Categories that should land in the inbox with a "review for quote
    /// processing" prompt. Title-cased to match `DocumentCategory.rawValue`.
    static let quoteCategories: Set<String> = [
        "Contractor Quote",
        "Repair Estimate"
    ]

    /// Vehicle-attached documents that need user review to link to the
    /// right vehicle (auto insurance card, vehicle title, registration).
    static let vehicleDocCategories: Set<String> = [
        "Auto Insurance",
        "Vehicle Title"
    ]

    /// Invoice-style documents that should trigger maintenance / system
    /// scanning via `process-invoice`. Mirrors the email pipeline's
    /// invoice detection.
    static let invoiceCategories: Set<String> = [
        "Home Bill/Invoice",
        "Project Invoice",
        "Repair Invoice",
        "Utility Bill"
    ]

    /// Build the inbox-item parameters for a freshly-uploaded document.
    /// Returns `nil` when the document's category doesn't warrant a
    /// needs-action item (e.g. deeds, mortgage statements, photos —
    /// just sit in the vault).
    static func plan(
        categoryValue: String,
        analysisSummary: String?
    ) -> (type: String, summary: String, actionType: String?, needsAction: Bool)? {
        let isQuote = quoteCategories.contains(categoryValue)
        let isVehicleDoc = vehicleDocCategories.contains(categoryValue)
        let isInvoice = invoiceCategories.contains(categoryValue)

        guard isQuote || isVehicleDoc || isInvoice else { return nil }

        if isQuote {
            return (
                type: "contractor_quote",
                summary: "Contractor quote detected. Create a project or add to an existing one.",
                actionType: "quote_received",
                needsAction: true
            )
        }
        if isVehicleDoc {
            return (
                type: "document_stored",
                summary: analysisSummary ?? "Vehicle document detected. Review to link to your vehicles.",
                actionType: "review_vehicle_doc",
                needsAction: true
            )
        }
        // isInvoice
        return (
            type: "document_stored",
            summary: analysisSummary ?? "Invoice detected. Scan to update maintenance tasks and systems.",
            actionType: "review_invoice",
            needsAction: true
        )
    }

    /// Create the inbox item and post the `.inboxItemUpdated` notification
    /// so any visible inbox surface refreshes. Throws on insert failure —
    /// callers should NOT wrap in `try?` because a silent failure is
    /// exactly how the Property-tab upload bug shipped. If a real failure
    /// occurs, the caller is responsible for logging it visibly.
    static func create(
        householdId: UUID,
        documentId: UUID,
        title: String,
        attachmentFilename: String?,
        categoryValue: String,
        analysisSummary: String?,
        db: DatabaseService
    ) async throws {
        guard let plan = plan(categoryValue: categoryValue, analysisSummary: analysisSummary) else {
            return
        }
        try await db.createInboxItem(
            householdId: householdId,
            type: plan.type,
            title: title,
            summary: plan.summary,
            relatedDocumentId: documentId,
            needsAction: plan.needsAction,
            actionType: plan.actionType,
            attachmentFilename: attachmentFilename
        )
        NotificationCenter.default.post(name: .inboxItemUpdated, object: nil)
    }
}

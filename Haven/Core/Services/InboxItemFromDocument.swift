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

    /// Categories that genuinely warrant no ask — a scanned photo, a raw
    /// image with no document semantics. Everything else gets at least a
    /// lightweight "we filed this as X, look right?" confirmation so the
    /// homeowner is never surprised by what landed in their vault. This is
    /// the "always ask" half of Tom's vision (the "unless in a project"
    /// half is enforced at the call sites, which skip this helper entirely
    /// for project-context uploads).
    static let noAskCategories: Set<String> = [
        "Photo",
        "Photos",
        "Image",
        "Before/After Photo",
    ]

    /// Build the inbox-item parameters for a freshly-uploaded document.
    /// Returns `nil` ONLY for categories that need no confirmation at all
    /// (photos). Every real document category returns an ask — quotes,
    /// invoices, and vehicle docs get their specialized follow-up prompt;
    /// everything else (deeds, tax returns, permits, warranties, town docs)
    /// gets a `confirm_document_category` ask, matching what the EMAIL
    /// pipeline already does for every forwarded document.
    static func plan(
        categoryValue: String,
        analysisSummary: String?
    ) -> (type: String, summary: String, actionType: String?, needsAction: Bool)? {
        let isQuote = quoteCategories.contains(categoryValue)
        let isVehicleDoc = vehicleDocCategories.contains(categoryValue)
        let isInvoice = invoiceCategories.contains(categoryValue)

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
        if isInvoice {
            return (
                type: "document_stored",
                summary: analysisSummary ?? "Invoice detected. Scan to update maintenance tasks and systems.",
                actionType: "review_invoice",
                needsAction: true
            )
        }

        // Photos / raw images: no confirmation needed.
        if noAskCategories.contains(categoryValue) { return nil }

        // Everything else — universal category-confirm ask (July 2026).
        // A deed, a tax return, a permit: "Saved as {category}. Looks right?"
        // The user can accept in one tap or reclassify. Mirrors the email
        // pipeline's `confirm_document_category` behavior so both ingest
        // paths feel identical.
        return (
            type: "document_stored",
            summary: analysisSummary ?? "Saved as \(categoryValue). Tap to confirm or change the category.",
            actionType: "confirm_document_category",
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

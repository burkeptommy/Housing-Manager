import XCTest
@testable import Haven

/// Round 2 (May 2026) regression tests for the pure logic introduced
/// by the friend-feedback Round 2 pass. These guard the small handful
/// of branch points that are easy to misroute without coverage:
///
///   • `InboxItemFromDocument.plan` — category → inbox routing.
///     Most of the value of Round 2 Item 8 (Property → Documents
///     pipeline fix) hinges on this map; if a category falls through
///     the wrong branch, the inbox prompt never fires and we're back
///     to the original bug.
///
///   • `DismissedCategoryRow.isActiveSnooze` — snooze expiry. The
///     Round 2 Item 6 ("Circle back" / Remind-me-later) feature is
///     useless if expired snoozes don't resurface. A few timestamp
///     checks lock in the boundary.
final class FriendFeedbackRound2Tests: XCTestCase {

    // MARK: - InboxItemFromDocument.plan

    func test_plan_contractorQuote_routesToContractorQuoteInbox() {
        let plan = InboxItemFromDocument.plan(
            categoryValue: "Contractor Quote",
            analysisSummary: nil
        )
        XCTAssertEqual(plan?.type, "contractor_quote")
        XCTAssertEqual(plan?.actionType, "quote_received")
        XCTAssertEqual(plan?.needsAction, true)
    }

    func test_plan_repairEstimate_routesToContractorQuoteInbox() {
        let plan = InboxItemFromDocument.plan(
            categoryValue: "Repair Estimate",
            analysisSummary: nil
        )
        XCTAssertEqual(plan?.type, "contractor_quote")
        XCTAssertEqual(plan?.actionType, "quote_received")
    }

    func test_plan_autoInsurance_routesToVehicleReview() {
        let plan = InboxItemFromDocument.plan(
            categoryValue: "Auto Insurance",
            analysisSummary: nil
        )
        XCTAssertEqual(plan?.type, "document_stored")
        XCTAssertEqual(plan?.actionType, "review_vehicle_doc")
        XCTAssertEqual(plan?.needsAction, true)
    }

    func test_plan_invoice_routesToInvoiceReview() {
        let plan = InboxItemFromDocument.plan(
            categoryValue: "Project Invoice",
            analysisSummary: nil
        )
        XCTAssertEqual(plan?.actionType, "review_invoice")
        XCTAssertEqual(plan?.needsAction, true)
    }

    func test_plan_utilityBill_routesToInvoiceReview() {
        let plan = InboxItemFromDocument.plan(
            categoryValue: "Utility Bill",
            analysisSummary: nil
        )
        XCTAssertEqual(plan?.actionType, "review_invoice")
    }

    func test_plan_deed_returnsNil() {
        // Deeds, mortgage statements, photos, etc. shouldn't generate
        // a needs-action inbox item — they just sit in the vault.
        let plan = InboxItemFromDocument.plan(
            categoryValue: "Deed",
            analysisSummary: "Property deed"
        )
        XCTAssertNil(plan, "Deeds must not produce an inbox item")
    }

    func test_plan_unknownCategory_returnsNil() {
        let plan = InboxItemFromDocument.plan(
            categoryValue: "Some Made Up Category",
            analysisSummary: nil
        )
        XCTAssertNil(plan)
    }

    func test_plan_prefersAnalysisSummary_whenAvailable_forInvoice() {
        let plan = InboxItemFromDocument.plan(
            categoryValue: "Home Bill/Invoice",
            analysisSummary: "Petro Home Services oil delivery $487"
        )
        XCTAssertEqual(plan?.summary, "Petro Home Services oil delivery $487")
    }

    func test_plan_quoteSummary_usesCannedCopy_notAnalysisSummary() {
        // Contractor quotes intentionally override the analysis summary
        // with a CTA-flavored line so the inbox card reads as action-
        // oriented rather than as a passive description.
        let plan = InboxItemFromDocument.plan(
            categoryValue: "Contractor Quote",
            analysisSummary: "Joe's Roofing quote for $12,000"
        )
        XCTAssertNotEqual(plan?.summary, "Joe's Roofing quote for $12,000")
        XCTAssertTrue(plan?.summary.contains("Create a project") == true)
    }

    // MARK: - DismissedCategoryRow.isActiveSnooze

    func test_isActiveSnooze_permanentDismissal_returnsFalse() {
        let row = makeDismissalRow(snoozedUntil: nil)
        XCTAssertFalse(row.isActiveSnooze(), "Nil snoozedUntil = permanent dismissal, not an active snooze")
    }

    func test_isActiveSnooze_futureSnooze_returnsTrue() {
        let future = Date().addingTimeInterval(60 * 60 * 24 * 30) // +30 days
        let row = makeDismissalRow(snoozedUntil: future)
        XCTAssertTrue(row.isActiveSnooze())
    }

    func test_isActiveSnooze_pastSnooze_returnsFalse() {
        let past = Date().addingTimeInterval(-60 * 60 * 24 * 30) // -30 days
        let row = makeDismissalRow(snoozedUntil: past)
        XCTAssertFalse(row.isActiveSnooze(), "Expired snooze must NOT suppress the gap anymore — that's the whole point of the snooze")
    }

    func test_isActiveSnooze_snoozeExactlyNow_returnsFalse() {
        // Edge case: snoozed_until == now. The friend-feedback semantic
        // is "remind me later" so the moment it hits, the gap should
        // resurface. `> now` (not `>=`) is the right comparison.
        let now = Date()
        let row = makeDismissalRow(snoozedUntil: now)
        XCTAssertFalse(row.isActiveSnooze(now: now))
    }

    // MARK: - Helpers

    private func makeDismissalRow(snoozedUntil: Date?) -> DismissedCategoryRow {
        // Reconstruct via JSON because the struct's resilient init(from:)
        // is the only public path. Mirrors how rows actually arrive from
        // Supabase. JSONDecoder's `.iso8601` strategy uses the strict
        // `withInternetDateTime` shape (no fractional seconds), so we
        // mirror that exactly here — otherwise the decode silently
        // drops to nil via `try?` and the snooze test becomes a no-op.
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let isoSnooze: String? = snoozedUntil.map { isoFormatter.string(from: $0) }
        var dict: [String: Any] = [
            "id": UUID().uuidString,
            "household_id": UUID().uuidString,
            "category": "Roofing",
        ]
        if let isoSnooze {
            dict["snoozed_until"] = isoSnooze
        }
        let data = try! JSONSerialization.data(withJSONObject: dict)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(DismissedCategoryRow.self, from: data)
    }
}

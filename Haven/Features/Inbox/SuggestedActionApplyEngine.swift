import Foundation

/// Phase 7 (Ingestion Intelligence v2) — applies the rows the homeowner
/// selected on `SuggestedActionsReviewCard`, in the HYBRID model:
///
///   • Server-side kinds (task / event / project) go through ONE
///     `process-inbox-item action=apply_suggested_actions` batch — the
///     ±21-day task dedup lives in `_shared/task-ingest.ts` and must not
///     be duplicated here.
///   • iOS-side kinds apply through the existing Swift machinery so the
///     single-sourced rules stay single-sourced:
///       punch_item     → ServiceOrchestrator.createHandymanItem
///       chez_request   → ChezConciergeService.submitChezRequest
///       (M2 adds routine via RoutineSeeder.createFromIngestion and
///        visit_log via ServiceOrchestrator.recordVisit; M3 adds
///        complete_task via the task-completion path.)
///
/// Completion is LEDGER-driven: after applying, the engine reports iOS
/// outcomes via `record_applied_actions`; the server stamps the item
/// complete only when `done: true`. Every step is re-entrant — a crash
/// between the server batch and the ledger call leaves the card showing
/// only the unapplied rows, and re-applying is dedup-safe.
///
/// Destination REMAPPING: the card passes each row's *effective*
/// operation (post-remap). A task row remapped to "Handyman" arrives here
/// as `.punchItem`; remapped to "Ask Chez" as `.chezRequest`. Unselected
/// rows arrive as `.skip` so the final ledger can mark them skipped and
/// complete the item.
@MainActor
final class SuggestedActionApplyEngine: ObservableObject {

    /// What the card resolved each row into after checkbox + destination
    /// remapping + inline edits.
    enum PlannedOperation {
        /// Apply on the server as the row's stored kind (task/event/project),
        /// with optional inline-edit overrides (e.g. adjusted due date).
        case server(payloadOverrides: [String: String?]?)
        /// Add to the handyman punch list (remap destination).
        case punchItem(title: String, description: String?)
        /// Hand off to the concierge (remap destination or the built-in row).
        case chezRequest(category: String?, summary: String, description: String?)
        /// M2 — create a standing routine (evidence + the card's inline
        /// cadence/vendor edits). Applies via RoutineSeeder.createFromIngestion,
        /// the MANDATORY dedup/eligibility wrapper.
        case routine(
            rawCategory: String,
            intervalDays: Int?,
            activeMonths: [Int]?,
            quotedText: String?,
            estimatedCostCents: Int?,
            vendorId: UUID?,
            vendorLabel: String?
        )
        /// M3 — mark an existing maintenance task done through the canonical
        /// completion path (MaintenanceViewModel.completeTask: recurring
        /// fan-out, system last_service_date, service record, notifications).
        case completeTask(taskId: UUID)
        /// M4 — log an invoice as a visit on the vendor's live routine
        /// (ServiceOrchestrator.recordVisit, completed + invoice_auto).
        case visitLog(contractorId: UUID, date: String, costCents: Int?)
        /// User left the row unchecked — record as skipped at completion.
        case skip
    }

    struct PlannedApplication {
        let actionId: String
        let operation: PlannedOperation
    }

    struct Outcome {
        var statusById: [String: String] = [:]
        var anyFailure = false
        var chezRequestCreated = false
    }

    @Published var isApplying = false
    @Published var lastError: String?

    /// Applies the plan. Returns the per-row outcome so the card can
    /// re-render (applied rows collapse into "added" states, failures stay
    /// actionable).
    func apply(
        item: DatabaseService.InboxItemRow,
        plans: [PlannedApplication],
        householdId: UUID,
        propertyId: UUID?,
        confirmedContractorId: UUID? = nil
    ) async -> Outcome {
        var outcome = Outcome()
        guard !isApplying else { return outcome }
        isApplying = true
        lastError = nil
        defer { isApplying = false }

        // Rows the server already resolved (prior partial apply).
        let priorResolved = Set(
            (item.metadata?.appliedActions ?? [])
                .filter { $0.isResolved }
                .map(\.id)
        )

        // 1. Server batch — every .server plan not already resolved.
        let serverPlans = plans.filter {
            if case .server = $0.operation, !priorResolved.contains($0.actionId) { return true }
            return false
        }
        if !serverPlans.isEmpty {
            let selected: [HavenSupabase.SelectedActionPayload] = serverPlans.map { plan in
                if case .server(let overrides) = plan.operation {
                    return HavenSupabase.SelectedActionPayload(id: plan.actionId, payloadOverrides: overrides)
                }
                return HavenSupabase.SelectedActionPayload(id: plan.actionId)
            }
            do {
                let results = try await HavenSupabase.applySuggestedActions(
                    inboxItemId: item.id.uuidString,
                    propertyId: propertyId?.uuidString,
                    selected: selected,
                    confirmedContractorId: confirmedContractorId?.uuidString
                )
                for r in results { outcome.statusById[r.id] = r.status }
            } catch {
                // Nothing was recorded on our side; the server self-records
                // whatever DID land. Surface and stop — retry is safe.
                print("[SuggestedActionApply] server batch failed: \(error)")
                lastError = "Couldn't apply these just now. Please try again."
                outcome.anyFailure = true
                return outcome
            }
        }

        // 2. iOS-side kinds, one at a time; failures don't abort the rest.
        var iosLedger: [HavenSupabase.RecordAppliedEntry] = []
        for plan in plans {
            if priorResolved.contains(plan.actionId) {
                outcome.statusById[plan.actionId] = "duplicate"
                continue
            }
            switch plan.operation {
            case .server, .skip:
                continue
            case .punchItem(let title, let description):
                do {
                    let row = try await ServiceOrchestrator.createHandymanItem(
                        householdId: householdId,
                        propertyId: propertyId,
                        title: title,
                        description: description
                    )
                    outcome.statusById[plan.actionId] = "applied"
                    iosLedger.append(.init(id: plan.actionId, status: "applied", resultRef: row.id.uuidString))
                    NotificationCenter.default.post(name: .handymanPunchListChanged, object: nil)
                } catch {
                    print("[SuggestedActionApply] punch item failed: \(error)")
                    outcome.statusById[plan.actionId] = "failed"
                    outcome.anyFailure = true
                    iosLedger.append(.init(id: plan.actionId, status: "failed"))
                }
            case .completeTask(let taskId):
                do {
                    guard let row = try await DatabaseService.shared.fetchMaintenanceTask(id: taskId) else {
                        outcome.statusById[plan.actionId] = "failed"
                        outcome.anyFailure = true
                        iosLedger.append(.init(id: plan.actionId, status: "failed"))
                        continue
                    }
                    // Already completed (recurring instances archive on
                    // completion; once tasks archive too) → duplicate.
                    if row.isArchived == true || row.lastCompletedDate != nil {
                        outcome.statusById[plan.actionId] = "duplicate"
                        iosLedger.append(.init(id: plan.actionId, status: "duplicate", resultRef: taskId.uuidString))
                        continue
                    }
                    let ok = await MaintenanceViewModel.shared.completeTask(row)
                    if ok {
                        outcome.statusById[plan.actionId] = "applied"
                        iosLedger.append(.init(id: plan.actionId, status: "applied", resultRef: taskId.uuidString))
                    } else {
                        outcome.statusById[plan.actionId] = "failed"
                        outcome.anyFailure = true
                        iosLedger.append(.init(id: plan.actionId, status: "failed"))
                    }
                } catch {
                    print("[SuggestedActionApply] complete task failed: \(error)")
                    outcome.statusById[plan.actionId] = "failed"
                    outcome.anyFailure = true
                    iosLedger.append(.init(id: plan.actionId, status: "failed"))
                }
            case .visitLog(let contractorId, let date, let costCents):
                do {
                    let routines = try await DatabaseService.shared.fetchRoutines(householdId: householdId)
                    guard let routine = routines.first(where: {
                        $0.vendorId == contractorId && $0.setupState == "active"
                    }) else {
                        outcome.statusById[plan.actionId] = "failed"
                        outcome.anyFailure = true
                        iosLedger.append(.init(id: plan.actionId, status: "failed"))
                        continue
                    }
                    // Dedup: one visit per (routine, date) from this path.
                    let visits = (try? await DatabaseService.shared.fetchRoutineVisits(routineId: routine.id)) ?? []
                    if let existing = visits.first(where: { $0.scheduledDate == date }) {
                        outcome.statusById[plan.actionId] = "duplicate"
                        iosLedger.append(.init(id: plan.actionId, status: "duplicate", resultRef: existing.id.uuidString))
                        continue
                    }
                    let visit = try await ServiceOrchestrator.recordVisit(
                        routine: routine,
                        scheduledDate: date,
                        notes: "Logged from a forwarded invoice.",
                        actualCostCents: costCents,
                        visitState: .completed,
                        confirmedBy: "invoice_auto"
                    )
                    outcome.statusById[plan.actionId] = "applied"
                    iosLedger.append(.init(id: plan.actionId, status: "applied", resultRef: visit.id.uuidString))
                    NotificationCenter.default.post(name: .routineChanged, object: nil)
                } catch {
                    print("[SuggestedActionApply] visit log failed: \(error)")
                    outcome.statusById[plan.actionId] = "failed"
                    outcome.anyFailure = true
                    iosLedger.append(.init(id: plan.actionId, status: "failed"))
                }
            case .routine(let rawCategory, let intervalDays, let activeMonths,
                          let quotedText, let estimatedCostCents, let vendorId, let vendorLabel):
                do {
                    let outcome2 = try await RoutineSeeder.shared.createFromIngestion(
                        householdId: householdId,
                        propertyId: propertyId,
                        rawCategory: rawCategory,
                        intervalDays: intervalDays,
                        activeMonthsHint: activeMonths,
                        quotedText: quotedText,
                        estimatedCostCents: estimatedCostCents,
                        vendorId: vendorId,
                        vendorLabel: vendorLabel
                    )
                    switch outcome2 {
                    case .created(let row):
                        outcome.statusById[plan.actionId] = "applied"
                        iosLedger.append(.init(id: plan.actionId, status: "applied", resultRef: row.id.uuidString))
                    case .duplicate(let row):
                        outcome.statusById[plan.actionId] = "duplicate"
                        iosLedger.append(.init(id: plan.actionId, status: "duplicate", resultRef: row.id.uuidString))
                    case .notEligible:
                        // The card downgrades ineligible categories to a task
                        // destination at render — reaching here means the
                        // category resolved differently at apply time. Surface
                        // as failed so the row stays actionable.
                        print("[SuggestedActionApply] routine not eligible: \(rawCategory)")
                        outcome.statusById[plan.actionId] = "failed"
                        outcome.anyFailure = true
                        iosLedger.append(.init(id: plan.actionId, status: "failed"))
                    }
                } catch {
                    print("[SuggestedActionApply] routine failed: \(error)")
                    outcome.statusById[plan.actionId] = "failed"
                    outcome.anyFailure = true
                    iosLedger.append(.init(id: plan.actionId, status: "failed"))
                }
            case .chezRequest(let category, let summary, let description):
                do {
                    let chezCategory = category.flatMap { ChezCategory(rawValue: $0) } ?? .coordinateTask
                    let request = try await HavenSupabase.submitChezRequest(
                        category: chezCategory,
                        summary: summary,
                        description: description ?? summary,
                        context: [
                            "source": "email_ingestion",
                            "inbox_item_id": item.id.uuidString,
                        ]
                    )
                    outcome.statusById[plan.actionId] = "applied"
                    outcome.chezRequestCreated = true
                    iosLedger.append(.init(id: plan.actionId, status: "applied", resultRef: request.id.uuidString))
                    NotificationCenter.default.post(name: .chezRequestChanged, object: nil)
                } catch {
                    print("[SuggestedActionApply] chez request failed: \(error)")
                    outcome.statusById[plan.actionId] = "failed"
                    outcome.anyFailure = true
                    iosLedger.append(.init(id: plan.actionId, status: "failed"))
                }
            }
        }

        // 3. Done when every SELECTED row resolved (applied or duplicate).
        //    Unchecked rows are recorded as skipped in the same call so the
        //    item completes — Apply is the user's final answer for this card.
        let selectedIds = plans.compactMap { plan -> String? in
            if case .skip = plan.operation { return nil }
            return plan.actionId
        }
        let allResolved = selectedIds.allSatisfy { id in
            let status = outcome.statusById[id]
            return status == "applied" || status == "duplicate"
        }
        if allResolved {
            for plan in plans {
                if case .skip = plan.operation, !priorResolved.contains(plan.actionId) {
                    iosLedger.append(.init(id: plan.actionId, status: "skipped"))
                }
            }
        }
        do {
            try await HavenSupabase.recordAppliedActions(
                inboxItemId: item.id.uuidString,
                applied: iosLedger,
                done: allResolved
            )
        } catch {
            // Non-fatal: server-side outcomes are already self-recorded; the
            // iOS outcomes will be re-derived as duplicates on retry.
            print("[SuggestedActionApply] ledger call failed (non-fatal): \(error)")
        }

        if allResolved {
            Haptics.success()
        } else if outcome.anyFailure {
            Haptics.error()
            if lastError == nil {
                lastError = "Some items couldn't be applied. You can retry the rest."
            }
        }
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(name: .inboxItemUpdated, object: nil)
        return outcome
    }
}

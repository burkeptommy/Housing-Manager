import SwiftUI

/// Phase 7 (Ingestion Intelligence v2) — the universal review card.
///
/// Renders `metadata.suggested_actions` rows with per-row checkboxes,
/// destination remapping (Task ⇄ Handyman list ⇄ Ask Chez; Project rows
/// attach; unchecking = "just file"), and inline due-date editing, then
/// applies through `SuggestedActionApplyEngine` (hybrid server/iOS apply
/// with the server-owned ledger).
///
/// Two modes:
///   .compact — inside `InboxItemCard`: checkbox rows + Apply. Remapping
///              lives in the detail view ("Customize" affordance is the
///              existing tap-through to InboxItemDetailView).
///   .full    — inside `InboxItemDetailView`: adds the destination menu
///              per task row + due-date editing.
///
/// Rows whose `typedKind` is nil (a future kind this app version doesn't
/// know) are hidden — forward compatibility per the resilient-decode rule.
/// Rows already resolved in the server ledger render as quiet "added"
/// states and can't be re-applied.
struct SuggestedActionsReviewCard: View {
    enum Mode { case compact, full }

    /// Where a row can be remapped to. Task rows offer Task/Handyman/Chez;
    /// routine rows offer Routine/Task/Chez (a standing program is never a
    /// punch item). Ineligible routine categories (template-backed — HVAC,
    /// Solar, roofer… — where a standing routine would double-surface the
    /// reconciler's vendor bundle) drop the Routine option entirely.
    enum Destination: String, CaseIterable {
        case routine = "Routine"
        case task = "Task"
        case handyman = "Handyman list"
        case chez = "Ask Chez"

        var icon: String {
            switch self {
            case .routine: return "repeat"
            case .task: return "checkmark.circle"
            case .handyman: return "hammer"
            case .chez: return "sparkles"
            }
        }
    }

    private func destinationOptions(for action: DatabaseService.InboxMetadata.SuggestedAction) -> [Destination] {
        switch action.typedKind {
        case .routine:
            return routineEligible(action) ? [.routine, .task, .chez] : [.task, .chez]
        default:
            return [.task, .handyman, .chez]
        }
    }

    /// Mirrors RoutineSeeder.createFromIngestion's eligibility gate so the
    /// card can downgrade ineligible rows at render instead of failing at
    /// apply. Kind derivation stays single-sourced in RoutineGroupingEngine.
    private func routineEligible(_ action: DatabaseService.InboxMetadata.SuggestedAction) -> Bool {
        guard let raw = action.payload.category ?? action.payload.rawCategory, !raw.isEmpty else { return false }
        let canonical = SystemCategoryRegistry.canonical(category: raw) ?? raw
        return RoutineGroupingEngine.routineKindFor(systemCategory: canonical) != nil
    }

    private func defaultDestination(for action: DatabaseService.InboxMetadata.SuggestedAction) -> Destination {
        action.typedKind == .routine
            ? (routineEligible(action) ? .routine : .task)
            : .task
    }

    let item: DatabaseService.InboxItemRow
    let mode: Mode
    /// Called after a fully-successful apply so the host list refreshes.
    var onApplied: (() -> Void)?

    @StateObject private var engine = SuggestedActionApplyEngine()
    @State private var checked: Set<String> = []
    @State private var destinations: [String: Destination] = [:]
    @State private var dueDateOverrides: [String: Date] = [:]
    @State private var localStatuses: [String: String] = [:]
    @State private var didSeedDefaults = false
    // M2 — routine-row inline edits (keyed by action id).
    @State private var routineCadence: [String: CompactCadenceChoice] = [:]
    @State private var routineMonths: [String: Set<Int>] = [:]
    @State private var routineVendorIds: [String: UUID] = [:]
    @State private var routineVendorNames: [String: String] = [:]
    @State private var vendorPickerTarget: VendorPickerTarget?
    // M3 — system_link deep-link into the invoice scanner.
    @State private var invoiceScanVM: InvoiceProcessingViewModel?
    @State private var showInvoiceScan = false
    // M4 — "Is this X?" vendor confirm row. nil = undecided.
    @State private var vendorConfirmed: Bool?

    private struct VendorPickerTarget: Identifiable {
        let id: String        // action id
        let category: String  // canonical-ish category for the picker
    }

    private func openInvoiceScan() {
        guard let documentId = item.relatedDocumentId else { return }
        Haptics.selection()
        Task {
            // Single-property fallback mirrors the server's resolution rule.
            let properties = (try? await DatabaseService.shared.fetchProperties()) ?? []
            guard let propertyId = properties.first?.id else { return }
            let vm = InvoiceProcessingViewModel(
                documentId: documentId,
                propertyId: propertyId,
                householdId: item.householdId
            )
            invoiceScanVM = vm
            showInvoiceScan = true
            await vm.process()
        }
    }

    private var actions: [DatabaseService.InboxMetadata.SuggestedAction] {
        (item.metadata?.suggestedActions ?? []).filter { $0.typedKind != nil }
    }

    private var ledger: [String: DatabaseService.InboxMetadata.AppliedAction] {
        Dictionary(
            (item.metadata?.appliedActions ?? []).map { ($0.id, $0) },
            uniquingKeysWith: { _, new in new }
        )
    }

    private func resolvedStatus(for action: DatabaseService.InboxMetadata.SuggestedAction) -> String? {
        if let local = localStatuses[action.id] { return local }
        if let entry = ledger[action.id], entry.isResolved { return entry.status }
        return nil
    }

    private var pendingActions: [DatabaseService.InboxMetadata.SuggestedAction] {
        actions.filter { resolvedStatus(for: $0) == nil }
    }

    private var confirmedVendorId: UUID? {
        guard vendorConfirmed == true,
              let match = item.metadata?.suggestedVendorMatch else { return nil }
        return UUID(uuidString: match.contractorId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let match = item.metadata?.suggestedVendorMatch, vendorConfirmed == nil,
               !pendingActions.isEmpty {
                vendorConfirmRow(match)
            }
            ForEach(mode == .compact ? Array(actions.prefix(4)) : actions) { action in
                actionRow(action)
            }
            if mode == .compact && actions.count > 4 {
                Text("+ \(actions.count - 4) more — tap to review")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            if let error = engine.lastError {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }

            if !pendingActions.isEmpty {
                HavenButton(
                    title: engine.isApplying
                        ? "Applying…"
                        : applyButtonTitle,
                    action: { Task { await applySelection() } }
                )
                .disabled(engine.isApplying || checked.isEmpty && !allPendingResolvedBySkip)
            }
        }
        .onAppear(perform: seedDefaultsIfNeeded)
        .sheet(item: $vendorPickerTarget) { target in
            ContractorPickerSheet(systemCategory: target.category) { contractor in
                routineVendorIds[target.id] = contractor.id
                routineVendorNames[target.id] = contractor.companyName
                Haptics.selection()
            }
        }
        .sheet(isPresented: $showInvoiceScan) {
            if let vm = invoiceScanVM {
                InvoiceReviewSheet(viewModel: vm)
            }
        }
    }

    private var applyButtonTitle: String {
        let count = checked.count
        if count == 0 { return "Dismiss the rest" }
        return count == 1 ? "Apply 1 item" : "Apply \(count) items"
    }

    private var allPendingResolvedBySkip: Bool {
        // Allow "Apply" with zero checked → records everything skipped and
        // completes the item (the user's explicit "none of these").
        !pendingActions.isEmpty
    }

    // MARK: - Rows

    /// M4 — medium-confidence sender→vendor ladder hit. The homeowner's
    /// answer feeds confirmed_contractor_id into apply; "Not them" just
    /// drops the attribution (nothing is created either way).
    @ViewBuilder
    private func vendorConfirmRow(_ match: DatabaseService.InboxMetadata.SuggestedVendorMatch) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Is this from \(match.name)?")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
            if let evidence = match.evidence, !evidence.isEmpty {
                Text(evidence)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            HStack(spacing: 8) {
                Button {
                    vendorConfirmed = true
                    Haptics.selection()
                } label: {
                    Text("Yes, it's them")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textOnNavy)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(HavenColors.navy800)
                        .clipShape(Capsule())
                }
                Button {
                    vendorConfirmed = false
                    Haptics.selection()
                } label: {
                    Text("Not them")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.navy800)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(HavenColors.beige200.opacity(0.6))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.navy800.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func actionRow(_ action: DatabaseService.InboxMetadata.SuggestedAction) -> some View {
        if action.typedKind == .systemLink {
            systemLinkRow(action)
        } else {
            checkboxRow(action)
        }
    }

    /// M3 — new-systems rows aren't apply rows: they deep-link into the
    /// existing InvoiceReviewSheet, whose system dedup / parent grouping /
    /// task migration is too load-bearing to duplicate on this card.
    @ViewBuilder
    private func systemLinkRow(_ action: DatabaseService.InboxMetadata.SuggestedAction) -> some View {
        Button {
            openInvoiceScan()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.navy800)
                VStack(alignment: .leading, spacing: 3) {
                    Text(action.title)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text("Review in the invoice scanner")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func checkboxRow(_ action: DatabaseService.InboxMetadata.SuggestedAction) -> some View {
        let status = resolvedStatus(for: action)
        HStack(alignment: .top, spacing: 10) {
            if let status {
                Image(systemName: status == "failed" ? "exclamationmark.circle" : "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(status == "failed" ? HavenColors.warning : HavenColors.success)
            } else {
                Button {
                    Haptics.selection()
                    if checked.contains(action.id) { checked.remove(action.id) }
                    else { checked.insert(action.id) }
                } label: {
                    Image(systemName: checked.contains(action.id) ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18))
                        .foregroundStyle(checked.contains(action.id) ? HavenColors.action : HavenColors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(action.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(status == nil ? HavenColors.textPrimary : HavenColors.textTertiary)
                    .strikethrough(status == "duplicate")
                    .lineLimit(2)

                if let reason = action.reason, !reason.isEmpty, mode == .full || status == nil {
                    Text(reason)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(mode == .full ? 3 : 1)
                }

                if let status {
                    Text(statusLabel(status))
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                } else if mode == .full {
                    fullModeControls(action)
                } else if action.typedKind == .chezRequest {
                    Text("A real person coordinates it end to end")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func fullModeControls(_ action: DatabaseService.InboxMetadata.SuggestedAction) -> some View {
        let isRemappable = action.typedKind == .task || action.typedKind == .routine
        if isRemappable, checked.contains(action.id) {
            let currentDest = destinations[action.id] ?? defaultDestination(for: action)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Menu {
                        ForEach(destinationOptions(for: action), id: \.self) { dest in
                            Button {
                                destinations[action.id] = dest
                                Haptics.selection()
                                Analytics.track(.suggestedActionRemapped, [
                                    "from_kind": action.kindRaw,
                                    "to": dest.rawValue,
                                ])
                            } label: {
                                Label(dest.rawValue, systemImage: dest.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: currentDest.icon)
                            Text(currentDest.rawValue)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                        }
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.navy800)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(HavenColors.beige200.opacity(0.6))
                        .clipShape(Capsule())
                    }

                    if action.typedKind == .task, currentDest == .task {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { dueDateOverrides[action.id] ?? parsedDueDate(action) },
                                set: { dueDateOverrides[action.id] = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .scaleEffect(0.85, anchor: .leading)
                    }
                }

                if action.typedKind == .routine, currentDest == .routine {
                    CompactCadenceEditor(
                        choice: Binding(
                            get: { routineCadence[action.id] ?? seededCadence(for: action) },
                            set: { routineCadence[action.id] = $0 }
                        ),
                        activeMonths: Binding(
                            get: { routineMonths[action.id] ?? seededMonths(for: action) },
                            set: { routineMonths[action.id] = $0 }
                        )
                    )
                    vendorRow(action)
                }
            }
        }
    }

    @ViewBuilder
    private func vendorRow(_ action: DatabaseService.InboxMetadata.SuggestedAction) -> some View {
        let pickedName = routineVendorNames[action.id]
        Button {
            let raw = action.payload.category ?? action.payload.rawCategory ?? ""
            vendorPickerTarget = VendorPickerTarget(
                id: action.id,
                category: SystemCategoryRegistry.canonical(category: raw) ?? raw
            )
        } label: {
            HStack(spacing: 4) {
                Image(systemName: pickedName == nil ? "person.crop.circle.badge.plus" : "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 11))
                Text(pickedName ?? (action.payload.contractorId != nil ? "Vendor linked from this email" : "Link a vendor (optional)"))
                    .lineLimit(1)
            }
            .font(HavenTypography.caption)
            .foregroundStyle(pickedName == nil && action.payload.contractorId == nil ? HavenColors.textSecondary : HavenColors.navy800)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(HavenColors.beige200.opacity(0.4))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func seededCadence(for action: DatabaseService.InboxMetadata.SuggestedAction) -> CompactCadenceChoice {
        if let match = CompactCadenceChoice.nearest(toDays: action.payload.intervalDays) {
            return match
        }
        // Category default via the single-sourced kind mapping.
        let raw = action.payload.category ?? action.payload.rawCategory ?? ""
        let canonical = SystemCategoryRegistry.canonical(category: raw) ?? raw
        if let kind = RoutineGroupingEngine.routineKindFor(systemCategory: canonical) {
            let fallback = RoutineGroupingEngine.defaultCadenceForRoutineKind(kind)
            switch fallback.0 {
            case .weekly: return .weekly
            case .biweekly: return .biweekly
            case .triweekly: return .triweekly
            case .monthly, .bimonthly: return .monthly
            case .quarterly: return .quarterly
            case .semiannual: return .semiannual
            case .annual, .customDays: return .annual
            }
        }
        return .monthly
    }

    private func seededMonths(for action: DatabaseService.InboxMetadata.SuggestedAction) -> Set<Int> {
        if let hint = action.payload.activeMonthsHint, !hint.isEmpty {
            return Set(hint.filter { (1...12).contains($0) })
        }
        let raw = action.payload.category ?? action.payload.rawCategory ?? ""
        let canonical = SystemCategoryRegistry.canonical(category: raw) ?? raw
        if let kind = RoutineGroupingEngine.routineKindFor(systemCategory: canonical) {
            return Set(RoutineGroupingEngine.defaultCadenceForRoutineKind(kind).2)
        }
        return Set(1...12)
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "applied": return "Added to your plan"
        case "duplicate": return "Already in your plan"
        case "failed": return "Couldn't apply — tap Apply to retry"
        case "skipped": return "Skipped"
        default: return status
        }
    }

    /// A "set up X routine (every 2 weeks)" title reads wrong as a one-off
    /// task — reframe to a schedule-shaped title for the downgrade path.
    private func routineDowngradeTitle(_ action: DatabaseService.InboxMetadata.SuggestedAction) -> String {
        let raw = action.payload.category ?? action.payload.rawCategory ?? "service"
        return "Schedule \(raw.lowercased()) service"
    }

    private func parsedDueDate(_ action: DatabaseService.InboxMetadata.SuggestedAction) -> Date {
        if let raw = action.payload.dueDate {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            if let d = df.date(from: raw) { return d }
        }
        return Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    }

    // MARK: - Selection defaults + apply

    private func seedDefaultsIfNeeded() {
        guard !didSeedDefaults else { return }
        didSeedDefaults = true
        for action in pendingActions where action.recommended {
            checked.insert(action.id)
        }
        Analytics.track(.suggestedActionsCardShown, [
            "count": actions.count,
            "mode": mode == .compact ? "compact" : "full",
        ])
    }

    private func applySelection() async {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        var plans: [SuggestedActionApplyEngine.PlannedApplication] = []
        for action in pendingActions {
            guard checked.contains(action.id) else {
                plans.append(.init(actionId: action.id, operation: .skip))
                continue
            }
            switch action.typedKind {
            case .task:
                let dest = destinations[action.id] ?? .task
                switch dest {
                case .task, .routine:
                    var overrides: [String: String?]? = nil
                    if let edited = dueDateOverrides[action.id] {
                        overrides = ["due_date": df.string(from: edited)]
                    }
                    plans.append(.init(actionId: action.id, operation: .server(payloadOverrides: overrides)))
                case .handyman:
                    plans.append(.init(actionId: action.id, operation: .punchItem(
                        title: action.title,
                        description: action.reason
                    )))
                case .chez:
                    plans.append(.init(actionId: action.id, operation: .chezRequest(
                        category: "coordinate_task",
                        summary: action.title,
                        description: action.reason
                    )))
                }
            case .routine:
                let dest = destinations[action.id] ?? defaultDestination(for: action)
                switch dest {
                case .routine:
                    let raw = action.payload.category ?? action.payload.rawCategory ?? ""
                    plans.append(.init(actionId: action.id, operation: .routine(
                        rawCategory: raw,
                        intervalDays: (routineCadence[action.id] ?? seededCadence(for: action)).intervalDays,
                        activeMonths: Array(routineMonths[action.id] ?? seededMonths(for: action)).sorted(),
                        quotedText: action.payload.quotedText,
                        estimatedCostCents: action.payload.estimatedCostCents,
                        vendorId: routineVendorIds[action.id]
                            ?? action.payload.contractorId.flatMap(UUID.init(uuidString:))
                            ?? confirmedVendorId,
                        vendorLabel: routineVendorNames[action.id]
                            ?? (routineVendorIds[action.id] == nil && action.payload.contractorId == nil && confirmedVendorId != nil
                                ? item.metadata?.suggestedVendorMatch?.name : nil)
                    )))
                case .task, .handyman:
                    // Template-backed downgrade or explicit choice — applies
                    // through the SERVER task path (apply_as override) so
                    // task dedup stays single-sourced in task-ingest.ts.
                    plans.append(.init(actionId: action.id, operation: .server(payloadOverrides: [
                        "apply_as": "task",
                        "title": routineDowngradeTitle(action),
                    ])))
                case .chez:
                    plans.append(.init(actionId: action.id, operation: .chezRequest(
                        category: "coordinate_task",
                        summary: action.title,
                        description: action.reason
                    )))
                }
            case .completeTask:
                if let raw = action.payload.taskId, let taskId = UUID(uuidString: raw) {
                    plans.append(.init(actionId: action.id, operation: .completeTask(taskId: taskId)))
                }
            case .visitLog:
                if let raw = action.payload.contractorId, let vendorId = UUID(uuidString: raw),
                   let date = action.payload.date {
                    plans.append(.init(actionId: action.id, operation: .visitLog(
                        contractorId: vendorId,
                        date: date,
                        costCents: action.payload.costCents
                    )))
                }
            case .project, .event:
                plans.append(.init(actionId: action.id, operation: .server(payloadOverrides: nil)))
            case .chezRequest:
                plans.append(.init(actionId: action.id, operation: .chezRequest(
                    // The wire key is "category" (shared with task rows);
                    // "chez_category" was the M1 decode assumption — read both.
                    category: action.payload.chezCategory ?? action.payload.category,
                    summary: action.payload.summary ?? action.title,
                    description: action.payload.description
                )))
            default:
                // Kinds this milestone can't apply yet (complete_task /
                // system_link land in M3) — leave pending.
                continue
            }
        }

        let outcome = await engine.apply(
            item: item,
            plans: plans,
            householdId: item.householdId,
            propertyId: nil, // server + orchestrator resolve (single-property fallback)
            confirmedContractorId: confirmedVendorId
        )
        for (id, status) in outcome.statusById {
            localStatuses[id] = status
        }
        for plan in plans {
            if case .skip = plan.operation, !outcome.anyFailure {
                localStatuses[plan.actionId] = "skipped"
            }
        }
        for (id, status) in outcome.statusById where status == "applied" {
            let action = actions.first(where: { $0.id == id })
            Analytics.track(.suggestedActionApplied, [
                "kind": action?.kindRaw ?? "unknown",
                "remapped": (destinations[id] ?? .task) != .task,
            ])
        }
        if !outcome.anyFailure {
            onApplied?()
        }
    }
}

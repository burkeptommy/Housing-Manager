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

    /// Where a task-kind row can be remapped to (M1 set; M2 adds Routine).
    enum Destination: String, CaseIterable {
        case task = "Task"
        case handyman = "Handyman list"
        case chez = "Ask Chez"

        var icon: String {
            switch self {
            case .task: return "checkmark.circle"
            case .handyman: return "hammer"
            case .chez: return "sparkles"
            }
        }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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

    @ViewBuilder
    private func actionRow(_ action: DatabaseService.InboxMetadata.SuggestedAction) -> some View {
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
        if action.typedKind == .task, checked.contains(action.id) {
            HStack(spacing: 10) {
                Menu {
                    ForEach(Destination.allCases, id: \.self) { dest in
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
                        Image(systemName: (destinations[action.id] ?? .task).icon)
                        Text((destinations[action.id] ?? .task).rawValue)
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

                if (destinations[action.id] ?? .task) == .task {
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
        }
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
                case .task:
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
            case .project, .event:
                plans.append(.init(actionId: action.id, operation: .server(payloadOverrides: nil)))
            case .chezRequest:
                plans.append(.init(actionId: action.id, operation: .chezRequest(
                    category: action.payload.chezCategory,
                    summary: action.payload.summary ?? action.title,
                    description: action.payload.description
                )))
            default:
                // Kinds this milestone can't apply yet (routine lands in M2,
                // complete_task/system_link in M3) — leave pending.
                continue
            }
        }

        let outcome = await engine.apply(
            item: item,
            plans: plans,
            householdId: item.householdId,
            propertyId: nil // server + orchestrator resolve (single-property fallback)
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

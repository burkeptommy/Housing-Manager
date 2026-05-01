import SwiftUI

/// Phase 80.1 — Reusable "Chez owns this" toggle. Drops into routine
/// detail / contractor detail / system detail wherever delegation is
/// possible. Talks to the chez-concierge Edge Function under the hood
/// via the appropriate per-target wrapper, so callers just pass a
/// target enum + the current state.
///
/// Visual: salmon-tinted card with a small concierge icon, the toggle,
/// and a one-line caption that adapts to the current state.
struct ChezOwnsToggle: View {
    enum Target {
        case routine(id: UUID, label: String)
        case contractor(id: UUID, name: String)
        /// Phase 80.2 — single-task delegation. `hasVendor` controls
        /// the copy: tasks without a vendor frame the handoff as
        /// "Chez sources one and handles scheduling end-to-end",
        /// tasks with a vendor frame it as "Chez coordinates with
        /// your vendor."
        case task(id: UUID, title: String, hasVendor: Bool)
    }

    let target: Target
    @Binding var isOwned: Bool
    /// Optional callback after a successful flip — typically the parent
    /// reloads the underlying row so its persisted timestamp updates.
    var onChange: ((Bool) -> Void)?

    @State private var isUpdating: Bool = false
    @State private var errorMessage: String?
    @State private var showNotesPrompt: Bool = false
    @State private var pendingNotes: String = ""

    private var label: String {
        switch target {
        case .routine: return "Have Chez own scheduling"
        case .contractor: return "Make Chez point of contact"
        case .task(_, _, let hasVendor):
            return hasVendor ? "Have Chez handle this task" : "Have Chez source a vendor"
        }
    }

    private var caption: String {
        if isOwned {
            switch target {
            case .routine(_, let routineLabel):
                return "Chez owns scheduling for \(routineLabel). Visits land on your calendar without asks."
            case .contractor(_, let name):
                return "Chez handles scheduling and follow-ups with \(name) directly."
            case .task(_, let title, _):
                return "Chez owns coordination for \(title). You'll see updates inside the request thread."
            }
        }
        switch target {
        case .routine:
            return "Chez owns scheduling end-to-end. You'll only see what they did, on the dates it happened."
        case .contractor:
            return "Chez handles all scheduling and follow-ups with this vendor on your behalf."
        case .task(_, _, let hasVendor):
            return hasVendor
                ? "Chez coordinates with your vendor, schedules, and follows up so you don't have to."
                : "Chez finds a vetted local pro, proposes them, and handles scheduling once you approve."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(HavenColors.action.opacity(0.14))
                        .frame(width: 32, height: 32)
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(caption)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if isUpdating {
                    ProgressView().scaleEffect(0.8).tint(HavenColors.action)
                } else {
                    Toggle("", isOn: Binding(
                        get: { isOwned },
                        set: { newVal in
                            // Tap-on flow: prompt for one-line context
                            // before kicking off so Chez has a starting
                            // point. Tap-off flow: revoke immediately.
                            if newVal {
                                showNotesPrompt = true
                            } else {
                                Task { await commit(delegated: false, notes: nil) }
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(HavenColors.action)
                }
            }
            if let err = errorMessage {
                Text(err)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.action.opacity(isOwned ? 0.08 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(HavenColors.action.opacity(isOwned ? 0.3 : 0.15), lineWidth: 1)
        )
        .alert("Hand this off to Chez?", isPresented: $showNotesPrompt) {
            TextField("Anything Chez should know? (optional)", text: $pendingNotes)
            Button("Hand off") {
                Task { await commit(delegated: true, notes: pendingNotes.trimmingCharacters(in: .whitespacesAndNewlines)) }
            }
            Button("Cancel", role: .cancel) {
                pendingNotes = ""
            }
        } message: {
            switch target {
            case .routine(_, let routineLabel):
                Text("Chez will own scheduling for \(routineLabel) from now on.")
            case .contractor(_, let name):
                Text("Chez will be your point of contact for \(name) from now on.")
            case .task(_, let title, let hasVendor):
                if hasVendor {
                    Text("Chez will coordinate with your vendor and schedule this task: \(title).")
                } else {
                    Text("Chez will find a vetted vendor for this task and own coordination: \(title).")
                }
            }
        }
    }

    @MainActor
    private func commit(delegated: Bool, notes: String?) async {
        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }
        let trimmedNotes = (notes?.isEmpty == true ? nil : notes)
        do {
            switch target {
            case .routine(let id, _):
                try await HavenSupabase.delegateRoutineToChez(
                    routineId: id, delegated: delegated, notes: trimmedNotes
                )
            case .contractor(let id, _):
                try await HavenSupabase.delegateContractorToChez(
                    contractorId: id, delegated: delegated, notes: trimmedNotes
                )
            case .task(let id, _, _):
                try await HavenSupabase.delegateTaskToChez(
                    taskId: id, delegated: delegated, notes: trimmedNotes
                )
            }
            isOwned = delegated
            pendingNotes = ""
            Haptics.success()
            Analytics.track(.chezDelegationToggled, [
                "target": targetKindKey,
                "delegated": String(delegated),
                "had_notes": String(trimmedNotes != nil),
            ])
            NotificationCenter.default.post(name: .chezDelegationChanged, object: nil)
            NotificationCenter.default.post(name: .chezRequestChanged, object: nil)
            // Tasks need maintenance refresh too — the delegated task
            // gets a chez_request_id stamped server-side and listeners
            // (the maintenance schedule, the property page) re-fetch
            // to render the new badge.
            if case .task = target {
                NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            }
            onChange?(delegated)
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    private var targetKindKey: String {
        switch target {
        case .routine: return "routine"
        case .contractor: return "contractor"
        case .task: return "task"
        }
    }
}

/// Phase 80.1 — Compact "Chez owns" badge for list rows. Lives next to
/// a routine / contractor title so users at a glance can see what's
/// already delegated.
struct ChezOwnsBadge: View {
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 10, weight: .semibold))
            Text(compact ? "Chez" : "Chez owns")
                .font(HavenTypography.uiLabelSmall.weight(.semibold))
        }
        .foregroundStyle(HavenColors.action)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(HavenColors.action.opacity(0.12))
        )
    }
}

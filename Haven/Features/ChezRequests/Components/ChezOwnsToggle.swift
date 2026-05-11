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

        // Phase 84 — Universal entity-level delegation. Each new case
        // hands one entity off via the generic `delegate_entity` Edge
        // Function action. Copy adapts per type below.
        case system(id: UUID, name: String)
        case project(id: UUID, name: String)
        case document(id: UUID, filename: String)
        case utility(id: UUID, providerName: String)
        case vehicle(id: UUID, label: String)
        /// Phase 84 — Insurance lives as JSONB on `properties`, not its
        /// own table. The id is the policy key (e.g. "homeowners" or
        /// "auto_<vehicle_id>"); propertyId is the parent property.
        case insurance(propertyId: UUID, policyKey: String, label: String)
    }

    let target: Target
    @Binding var isOwned: Bool
    /// Optional callback after a successful flip — typically the parent
    /// reloads the underlying row so its persisted timestamp updates.
    var onChange: ((Bool) -> Void)?

    @State private var isUpdating: Bool = false
    @State private var errorMessage: String?
    @State private var showNotesPrompt: Bool = false
    @State private var showRevokeConfirm: Bool = false
    @State private var pendingNotes: String = ""
    /// Phase 95 — transient confirmation flash so the user gets visible
    /// feedback after a successful flip (haptic alone is too quiet on
    /// the contractor / task detail surfaces). Cleared after 2 seconds.
    @State private var confirmationMessage: String?

    private var label: String {
        switch target {
        case .routine: return "Have Chez own scheduling"
        case .contractor: return "Make Chez point of contact"
        case .task(_, _, let hasVendor):
            return hasVendor ? "Have Chez handle this task" : "Have Chez source a vendor"
        case .system: return "Have Chez manage this system"
        case .project: return "Have Chez manage this project"
        case .document: return "Have Chez file & manage this"
        case .utility: return "Have Chez manage this account"
        case .vehicle: return "Have Chez manage this vehicle"
        case .insurance: return "Have Chez manage this policy"
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
            case .system(_, let name):
                return "Chez owns \(name) end-to-end. Service scheduling, warranty, parts, history."
            case .project(_, let name):
                return "Chez is running \(name): vendor sourcing, negotiation, budget, timeline."
            case .document(_, let filename):
                return "Chez has \(filename) on file. They'll share it with vendors when needed."
            case .utility(_, let providerName):
                return "Chez audits your \(providerName) bills and shops better rates when they appear."
            case .vehicle(_, let label):
                return "Chez owns \(label). Service scheduling, recalls, registration, insurance claims."
            case .insurance(_, _, let label):
                return "Chez handles your \(label). Claims, coverage audits, renewal shopping."
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
        case .system:
            return "Chez schedules maintenance, tracks warranty, orders parts, logs service so you don't think about it."
        case .project:
            return "Chez runs the project end-to-end. Sources vendors, negotiates pricing, tracks budget + timeline."
        case .document:
            return "Chez files this for you, organizes it, and shares with vendors when relevant."
        case .utility:
            return "Chez audits bills for errors, negotiates rates, and switches providers if a better deal appears."
        case .vehicle:
            return "Chez owns the whole vehicle. Service, recalls, registration, insurance. You just drive it."
        case .insurance:
            return "Chez files claims, audits coverage against your home value, and shops renewals."
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
                            // point. Tap-off flow: confirm before revoke
                            // (Round E Wave E-2 finding — revoking active
                            // Chez engagement mid-flight should not be a
                            // one-tap action; mirrors the C-1 REDO
                            // Archive routine confirmation pattern).
                            if newVal {
                                showNotesPrompt = true
                            } else {
                                showRevokeConfirm = true
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
            if let confirmation = confirmationMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.success)
                    Text(confirmation)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textPrimary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
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
            case .system(_, let name):
                Text("Chez will own end-to-end management of \(name).")
            case .project(_, let name):
                Text("Chez will run the project: \(name). Vendor sourcing, negotiation, budget, timeline.")
            case .document(_, let filename):
                Text("Chez will file and manage this document: \(filename).")
            case .utility(_, let providerName):
                Text("Chez will audit \(providerName) bills, negotiate rates, and switch providers if better deals come up.")
            case .vehicle(_, let label):
                Text("Chez will own the whole vehicle (\(label)). Service, recalls, registration, insurance.")
            case .insurance(_, _, let label):
                Text("Chez will manage your \(label). Claims, coverage audits, renewal shopping.")
            }
        }
        .confirmationDialog(
            "Hand this back to you?",
            isPresented: $showRevokeConfirm,
            titleVisibility: .visible
        ) {
            Button("Hand back to me", role: .destructive) {
                Task { await commit(delegated: false, notes: nil) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            switch target {
            case .routine(_, let routineLabel):
                Text("Chez will stop owning scheduling for \(routineLabel). Any in-flight Chez requests stay open, but no new visits will be coordinated automatically.")
            case .contractor(_, let name):
                Text("Chez will stop being your point of contact for \(name). You'll handle scheduling and follow-ups directly.")
            case .task(_, let title, _):
                Text("Chez will stop coordinating this task: \(title). You'll handle it yourself or assign a vendor manually.")
            case .system(_, let name):
                Text("Chez will stop owning end-to-end management of \(name).")
            case .project(_, let name):
                Text("Chez will stop running the project: \(name). Any in-flight quotes and contractor conversations stay where they are.")
            case .document(_, let filename):
                Text("Chez will stop managing this document: \(filename).")
            case .utility(_, let providerName):
                Text("Chez will stop auditing \(providerName) bills and negotiating rates.")
            case .vehicle(_, let label):
                Text("Chez will stop owning the vehicle (\(label)). Service, recalls, registration, and insurance return to you.")
            case .insurance(_, _, let label):
                Text("Chez will stop managing your \(label).")
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
            case .system(let id, _):
                try await HavenSupabase.delegateEntityToChez(
                    entityType: "system", entityId: id.uuidString, delegated: delegated, notes: trimmedNotes
                )
            case .project(let id, _):
                try await HavenSupabase.delegateEntityToChez(
                    entityType: "project", entityId: id.uuidString, delegated: delegated, notes: trimmedNotes
                )
            case .document(let id, _):
                try await HavenSupabase.delegateEntityToChez(
                    entityType: "document", entityId: id.uuidString, delegated: delegated, notes: trimmedNotes
                )
            case .utility(let id, _):
                try await HavenSupabase.delegateEntityToChez(
                    entityType: "utility", entityId: id.uuidString, delegated: delegated, notes: trimmedNotes
                )
            case .vehicle(let id, _):
                try await HavenSupabase.delegateEntityToChez(
                    entityType: "vehicle", entityId: id.uuidString, delegated: delegated, notes: trimmedNotes
                )
            case .insurance(let propertyId, let policyKey, _):
                try await HavenSupabase.delegateEntityToChez(
                    entityType: "insurance", entityId: policyKey, delegated: delegated, notes: trimmedNotes,
                    propertyId: propertyId.uuidString
                )
            }
            isOwned = delegated
            pendingNotes = ""
            Haptics.success()
            confirmationMessage = delegated ? "Chez is on it." : "Returned to you."
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if confirmationMessage != nil {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        confirmationMessage = nil
                    }
                }
            }
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
            // Phase 84 — fire surface-specific refresh notifications
            // so the relevant detail views update after the toggle.
            // Utility / vehicle / insurance don't have dedicated
            // notifications today; piggyback on `propertyChanged`
            // since they're all property-scoped.
            switch target {
            case .system: NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
            case .project: NotificationCenter.default.post(name: .projectChanged, object: nil)
            case .document: NotificationCenter.default.post(name: .documentChanged, object: nil)
            case .utility, .vehicle, .insurance:
                NotificationCenter.default.post(name: .propertyChanged, object: nil)
            default: break
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
        case .system: return "system"
        case .project: return "project"
        case .document: return "document"
        case .utility: return "utility"
        case .vehicle: return "vehicle"
        case .insurance: return "insurance"
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

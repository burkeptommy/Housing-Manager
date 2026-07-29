import SwiftUI

/// Phase 70.A2: the single, type-aware set of actions a homeowner can take
/// on a maintenance task — surfaced identically everywhere (the "⋯" menu on
/// every feed row AND the long-press context menu). Before this, only the
/// find-contractor `UnifiedTaskCard` variant exposed any inline actions;
/// the Tasks-v2 feed rows (`StandaloneTaskRow` / `BundleParentCard`) had
/// none, and the personal-card `onDelegate` footer was dead code.
///
/// The resolver is pure + deterministic, so the same task always offers the
/// same actions regardless of which surface renders it. The dispatcher
/// (`MaintenanceTabView.handleTaskAction`) routes each case to an existing,
/// verified handler — nothing here performs side effects.
enum TaskAction: String, Identifiable, CaseIterable {
    case markDone
    case schedule
    case findVendor
    case pickVendor
    case haveChezHandle
    case addToHandyman
    case doMyself
    case snooze

    var id: String { rawValue }

    var title: String {
        switch self {
        case .markDone:       return "Mark done"
        case .schedule:       return "Schedule…"
        case .findVendor:     return "Find a vendor"
        case .pickVendor:     return "Assign existing vendor"
        case .haveChezHandle: return "Have Chez handle it"
        case .addToHandyman:  return "Add to handyman list"
        case .doMyself:       return "I'll do it myself"
        case .snooze:         return "Snooze 1 week"
        }
    }

    var systemImage: String {
        switch self {
        case .markDone:       return "checkmark.circle"
        case .schedule:       return "calendar"
        case .findVendor:     return "magnifyingglass"
        case .pickVendor:     return "person.crop.circle.badge.plus"
        case .haveChezHandle: return "sparkles"
        case .addToHandyman:  return "hammer"
        case .doMyself:       return "hand.raised"
        case .snooze:         return "zzz"
        }
    }
}

enum TaskActionResolver {
    /// Returns the applicable actions for a task, in display order. The
    /// task's "type" is inferred from assignment + contractor + bundle
    /// membership so no nonsensical action renders (e.g. a bundle visit
    /// never offers "Add to handyman").
    static func actions(for task: MaintenanceTaskDBRow) -> [TaskAction] {
        let isVendor = (task.assignmentType?.lowercased() == "vendor")
        let hasContractor = task.assignedContractorId != nil
        let isBundle = MaintenanceTemplates.isBundleId(task.templateId)
        let handymanOK = isHandymanEligible(task)

        if isBundle {
            // Multi-item vendor visit — book / mark done / assign / Chez.
            // No "Add to handyman" (a bundle is a coordinated pro visit).
            return [
                .markDone,
                .schedule,
                hasContractor ? nil : .findVendor,
                hasContractor ? nil : .pickVendor,
                .haveChezHandle,
                .snooze
            ].compactMap { $0 }
        }

        if isVendor && !hasContractor {
            // Find-a-pro task: the decision is which vendor.
            return [
                .findVendor,
                .pickVendor,
                .haveChezHandle,
                handymanOK ? .addToHandyman : nil,
                .doMyself,
                .snooze
            ].compactMap { $0 }
        }

        if isVendor && hasContractor {
            // Vendor-managed: a pro is on file and scheduled.
            return [.markDone, .schedule, .haveChezHandle, .doMyself, .snooze]
        }

        // Personal / either (DIY-oriented) task.
        return [
            .markDone,
            .schedule,
            .findVendor,
            .pickVendor,
            .haveChezHandle,
            handymanOK ? .addToHandyman : nil,
            .snooze
        ].compactMap { $0 }
    }

    /// Mirror of `MaintenanceScheduleView.isHandymanEligible` — a matched
    /// template with ≤ 60 min DIY effort, no contractor, not a vehicle
    /// task, and not safety-floored. Big or pro-only jobs aren't a fit for
    /// the handyman punch list.
    static func isHandymanEligible(_ task: MaintenanceTaskDBRow) -> Bool {
        guard task.vehicleId == nil, task.assignedContractorId == nil else { return false }
        guard let key = task.templateId,
              let template = MaintenanceTemplates.template(forKey: key) else { return false }
        guard !template.safetyFloor else { return false }
        let minutes = template.diyEffortMinutes ?? 0
        return minutes > 0 && minutes <= 60
    }
}

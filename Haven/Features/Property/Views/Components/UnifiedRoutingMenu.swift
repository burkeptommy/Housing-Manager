import SwiftUI

/// Phase 67B+D: Unified "Who handles this?" action sheet presented from
/// every task surface — task detail sheet, This Season orchestration
/// chip, routing picker. Five options in one place:
///
///  1. **Route to my handyman** — parent_routine_id = handyman routine
///  2. **Route to [existing vendor in this category]** — parent_routine_id = vendor routine
///  3. **Find a different vendor** — opens FindLocalVendorSheet
///  4. **I'll do it myself** — clears parent_routine_id, stays in This Season
///  5. **Ask Alfred for advice** — opens Alfred with task context prefilled
///
/// Every selection writes to `routing_preferences` (Phase 65) so the
/// reconciler honors the choice on subsequent re-reconciles — the user
/// never has to orchestrate the same task twice.
struct UnifiedRoutingMenu: View {
    let task: MaintenanceTaskDBRow
    let taskCategory: String?
    let handymanVendor: ContractorRow?
    let categoryVendorRoutine: RoutineRow?
    let categoryVendor: ContractorRow?

    let onRouteToHandyman: () -> Void
    let onRouteToVendor: () -> Void
    let onFindDifferentVendor: () -> Void
    let onDIYMyself: () -> Void
    let onAskAlfred: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Choose who handles this")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)

            VStack(spacing: HavenTheme.spacing8) {
                if handymanVendor != nil {
                    routingButton(
                        icon: "wrench.adjustable.fill",
                        title: handymanLabel,
                        subtitle: "Adds to next contractor visit",
                        action: {
                            trackChoice("handyman")
                            onRouteToHandyman()
                        }
                    )
                }

                if let vendor = categoryVendor, categoryVendorRoutine != nil {
                    routingButton(
                        icon: "building.2.fill",
                        title: "Assign to \(vendor.companyName.isEmpty ? "your vendor" : vendor.companyName)",
                        subtitle: "Groups under your existing \(taskCategory ?? "service") routine",
                        action: {
                            trackChoice("existing_vendor")
                            onRouteToVendor()
                        }
                    )
                }

                routingButton(
                    icon: "magnifyingglass",
                    title: "Find a different vendor",
                    subtitle: "Chez searches local pros for this task",
                    action: {
                        trackChoice("find_vendor")
                        onFindDifferentVendor()
                    }
                )

                routingButton(
                    icon: "person.fill",
                    title: "I'll do it myself",
                    subtitle: "Stays in This Season as a personal to-do",
                    action: {
                        trackChoice("diy")
                        onDIYMyself()
                    }
                )

                routingButton(
                    icon: "sparkles",
                    title: "Ask Alfred",
                    subtitle: "Get advice on who should handle this",
                    action: {
                        trackChoice("alfred")
                        onAskAlfred()
                    }
                )
            }
        }
    }

    private var handymanLabel: String {
        guard let handyman = handymanVendor else { return "Add to handyman list" }
        if !handyman.companyName.isEmpty { return "Add to \(handyman.companyName)'s bundle" }
        if let contact = handyman.contactName, !contact.isEmpty {
            return "Add to \(contact)'s bundle"
        }
        return "Add to handyman bundle"
    }

    @ViewBuilder
    private func routingButton(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: HavenTheme.spacing12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    private func trackChoice(_ choice: String) {
        Analytics.track(.unifiedRoutingPickerChose, [
            "task_id": task.id.uuidString,
            "category": taskCategory ?? "unknown",
            "choice": choice,
            "had_existing_vendor": categoryVendor != nil,
            "had_handyman": handymanVendor != nil
        ])
        Haptics.selection()
    }
}

/// Phase 67B+D: Coordinates the unified routing actions. Encapsulates the
/// DB writes so call sites (orchestration chip, detail sheet, hub card)
/// only need to present the menu and react to completion via notifications.
@MainActor
enum UnifiedRoutingActions {
    /// Route the task to the singleton handyman routine. Creates the
    /// routine lazily if it doesn't exist yet. Also writes a sticky
    /// `routing_preferences` row so the reconciler honors it next time.
    static func routeToHandyman(
        task: MaintenanceTaskDBRow,
        category: String?
    ) async throws {
        try await ServiceOrchestrator.routeService(
            task: task,
            route: "handyman",
            category: category,
            persistPreference: true
        )
        Analytics.track(.stickyRoutingPreferenceSaved, [
            "task_id": task.id.uuidString,
            "category": category ?? task.templateId?.split(separator: ":").first.map(String.init) ?? "General",
            "route": "handyman",
            "scope": task.templateId != nil ? "template" : "category",
            "has_vendor": false
        ])
    }

    /// Route the task to the user's existing vendor routine in this
    /// category. Sets `parent_routine_id` + `assignedContractorId` and
    /// writes a sticky preference.
    static func routeToVendor(
        task: MaintenanceTaskDBRow,
        routine: RoutineRow,
        category: String?
    ) async throws {
        try await ServiceOrchestrator.routeService(
            task: task,
            route: "vendor",
            category: category,
            routine: routine,
            persistPreference: true
        )
        Analytics.track(.stickyRoutingPreferenceSaved, [
            "task_id": task.id.uuidString,
            "category": category ?? task.templateId?.split(separator: ":").first.map(String.init) ?? "General",
            "route": "vendor",
            "scope": task.templateId != nil ? "template" : "category",
            "has_vendor": routine.vendorId != nil
        ])
    }

    /// Mark this task as user-handled. Clears any parent_routine_id so
    /// the task surfaces in This Season, stamps `assignedRoute='diy'`,
    /// and saves the sticky preference.
    static func markDIY(
        task: MaintenanceTaskDBRow,
        category: String?
    ) async throws {
        try await ServiceOrchestrator.routeService(
            task: task,
            route: "diy",
            category: category,
            persistPreference: true
        )
        Analytics.track(.stickyRoutingPreferenceSaved, [
            "task_id": task.id.uuidString,
            "category": category ?? task.templateId?.split(separator: ":").first.map(String.init) ?? "General",
            "route": "diy",
            "scope": task.templateId != nil ? "template" : "category",
            "has_vendor": false
        ])
    }
}

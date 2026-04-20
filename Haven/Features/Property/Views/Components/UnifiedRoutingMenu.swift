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
            Text("WHO SHOULD HANDLE THIS?")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            VStack(spacing: HavenTheme.spacing8) {
                if handymanVendor != nil {
                    routingButton(
                        icon: "wrench.adjustable.fill",
                        title: handymanLabel,
                        subtitle: "Adds to next handyman visit",
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
                    subtitle: "Haven searches local pros for this task",
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
        if !handyman.companyName.isEmpty { return "Add to \(handyman.companyName)'s list" }
        if let contact = handyman.contactName, !contact.isEmpty {
            return "Add to \(contact)'s list"
        }
        return "Add to handyman list"
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
        let db = DatabaseService.shared
        _ = try await db.assignTaskToHandymanRoutine(task: task)
        try await saveStickyPreference(
            task: task,
            category: category,
            route: "handyman",
            vendorId: nil
        )
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(name: .routineChanged, object: nil)
    }

    /// Route the task to the user's existing vendor routine in this
    /// category. Sets `parent_routine_id` + `assignedContractorId` and
    /// writes a sticky preference.
    static func routeToVendor(
        task: MaintenanceTaskDBRow,
        routine: RoutineRow,
        category: String?
    ) async throws {
        let db = DatabaseService.shared
        var update = MaintenanceTaskUpdate()
        update.parentRoutineId = routine.id
        update.assignedRoute = "vendor"
        update.assignedContractorId = routine.vendorId
        _ = try await db.updateMaintenanceTask(id: task.id, update)
        try await saveStickyPreference(
            task: task,
            category: category,
            route: "vendor",
            vendorId: routine.vendorId
        )
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
    }

    /// Mark this task as user-handled. Clears any parent_routine_id so
    /// the task surfaces in This Season, stamps `assignedRoute='diy'`,
    /// and saves the sticky preference.
    static func markDIY(
        task: MaintenanceTaskDBRow,
        category: String?
    ) async throws {
        let db = DatabaseService.shared
        var update = MaintenanceTaskUpdate()
        update.parentRoutineId = nil
        update.assignedRoute = "diy"
        _ = try await db.updateMaintenanceTask(id: task.id, update)
        try await saveStickyPreference(
            task: task,
            category: category,
            route: "diy",
            vendorId: nil
        )
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
    }

    /// Phase 65: Writes a `routing_preferences` row at template scope so
    /// future reconciles honor the choice. Falls back to category scope
    /// if we don't have a template id. Errors are swallowed — the primary
    /// action (routing the task) already succeeded.
    private static func saveStickyPreference(
        task: MaintenanceTaskDBRow,
        category: String?,
        route: String,
        vendorId: UUID?
    ) async throws {
        guard let propertyId = task.propertyId else { return }
        let db = DatabaseService.shared
        let taskCategory = category ?? task.templateId?.split(separator: ":").first.map(String.init) ?? "General"

        let insert = RoutingPreferenceInsert(
            householdId: task.householdId,
            propertyId: propertyId,
            taskCategory: taskCategory,
            scopeType: task.templateId != nil ? "template" : "category",
            preferredRoute: route,
            preferredVendorId: vendorId
        )
        _ = try? await db.upsertRoutingPreference(insert)
        Analytics.track(.stickyRoutingPreferenceSaved, [
            "task_id": task.id.uuidString,
            "category": taskCategory,
            "route": route,
            "scope": insert.scopeType,
            "has_vendor": vendorId != nil
        ])
    }
}

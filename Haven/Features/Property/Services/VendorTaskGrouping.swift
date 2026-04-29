import Foundation

/// Chez v1: collapses a flat list of vendor-needing tasks into vendor-
/// specialty buckets so the homeowner-side "Tasks needing a vendor"
/// sheet reads as "1 HVAC pro covers 4 tasks" instead of 50 individual
/// rows. One vendor per category. Same data, vastly fewer decisions.
///
/// Resolution order for each task → canonical category:
///   1. `task.systemId` → `home_systems.category` → SystemCategoryRegistry.canonical
///   2. `task.templateId` prefix before `:` (e.g. "HVAC:Annual boiler service")
///      → SystemCategoryRegistry.canonical
///   3. Fallback to "Handyman" — covers the remaining DIY-ish tasks
///      (winterize faucets, foundation walkaround) that a household
///      handyman can knock out.
enum VendorTaskGrouping {

    /// One vendor-specialty bucket. Tasks within share the same
    /// canonical category, so a single "Find a pro" tap can adopt one
    /// vendor for all of them via FindLocalVendorSheet's existing
    /// systemCategory matching.
    struct Group: Identifiable {
        let id: String                              // == categoryKey
        let categoryKey: String                     // canonical, e.g. "HVAC"
        let displayName: String                     // human label
        let icon: String                            // SF Symbol
        let tasks: [MaintenanceTaskDBRow]

        var count: Int { tasks.count }
    }

    /// Groups + sorts. Categories with the most tasks come first
    /// (highest leverage to fix), tasks within sort by due date so
    /// the soonest-due appears at the top of the expanded list.
    static func group(
        tasks: [MaintenanceTaskDBRow],
        systems: [HomeSystemRow]
    ) -> [Group] {
        let systemsLookup = Dictionary(uniqueKeysWithValues: systems.map { ($0.id, $0) })

        var buckets: [String: [MaintenanceTaskDBRow]] = [:]
        for task in tasks {
            let canonical = resolveCanonicalCategory(for: task, systemsLookup: systemsLookup)
                ?? "Handyman"
            buckets[canonical, default: []].append(task)
        }

        return buckets
            .map { (categoryKey, taskList) -> Group in
                let meta = SystemCategoryRegistry.byCategoryKey[categoryKey]
                let displayName = meta?.displayName ?? categoryKey
                let icon = meta?.icon ?? "wrench.and.screwdriver.fill"
                let sortedTasks = taskList.sorted { lhs, rhs in
                    let l = MaintenanceDateFormatting.date(from: lhs.scheduledDate ?? lhs.nextDueDate) ?? .distantFuture
                    let r = MaintenanceDateFormatting.date(from: rhs.scheduledDate ?? rhs.nextDueDate) ?? .distantFuture
                    return l < r
                }
                return Group(
                    id: categoryKey,
                    categoryKey: categoryKey,
                    displayName: displayName,
                    icon: icon,
                    tasks: sortedTasks
                )
            }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.displayName < rhs.displayName
            }
    }

    /// Best-effort canonical category for a single task. Public only
    /// for unit-test friendliness; callers should use `group(tasks:)`.
    static func resolveCanonicalCategory(
        for task: MaintenanceTaskDBRow,
        systemsLookup: [UUID: HomeSystemRow]
    ) -> String? {
        // 1. Linked system gives us the most accurate category.
        if let systemId = task.systemId, let system = systemsLookup[systemId] {
            if let canonical = SystemCategoryRegistry.canonical(category: system.category) {
                return canonical
            }
        }
        // 2. templateId carries the system category as its prefix —
        //    "HVAC:Annual boiler service" → "HVAC". This is the
        //    rescue path for tasks created without a systemId
        //    (handyman bundle children, custom user tasks tagged
        //    with a templateKey).
        if let templateId = task.templateId,
           let prefix = templateId.split(separator: ":").first.map(String.init),
           let canonical = SystemCategoryRegistry.canonical(category: prefix) {
            return canonical
        }
        // 3. No system, no template — heuristic title sniff for the
        //    common DIY-ish tasks that always end up unanchored.
        let lower = task.title.lowercased()
        if lower.contains("handyman") { return "Handyman" }
        if lower.contains("foundation") || lower.contains("crawl") {
            return SystemCategoryRegistry.canonical(category: "Crawl Space") ?? "Handyman"
        }
        if lower.contains("hose") || lower.contains("faucet") || lower.contains("plumb") {
            return "Plumbing"
        }
        if lower.contains("smoke") || lower.contains("co detect") || lower.contains("gfci") {
            return "Electrical"
        }
        if lower.contains("radon") {
            return "Handyman"
        }
        return nil
    }
}

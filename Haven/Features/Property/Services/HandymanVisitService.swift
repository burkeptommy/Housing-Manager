import Foundation

/// Phase 67: Service facade for the Handyman Visit feature. Wraps the
/// low-level `DatabaseService.setTaskRoute(...)` helper with typed
/// entry points tuned to the visit surface, adds cascade-completion
/// for the parent visit task, and hosts the upsell scanner that feeds
/// "Your handyman could also handle these" on `HandymanVisitDetailView`.
///
/// Split from DatabaseService so the Visit view and its ViewModel can
/// depend on a narrow interface rather than the full CRUD surface.
@MainActor
enum HandymanVisitService {

    // MARK: - Claim / unclaim

    /// Flip a bundle child's route between "handyman" (in the bundle) and
    /// "diy" (claimed as personal). The Phase 64 `setTaskRoute` helper
    /// already handles the punch-list sync side effects; this wrapper
    /// exists so the Visit view can call a method whose name matches the
    /// UX verb users see ("claim as DIY").
    @discardableResult
    static func reassignChild(
        taskId: UUID,
        toRoute route: String,
        task: MaintenanceTaskDBRow? = nil
    ) async throws -> MaintenanceTaskDBRow? {
        Analytics.track(
            route == "diy" ? .handymanVisitItemClaimedDIY : .handymanVisitItemUnclaimed,
            [
                "task_id": taskId.uuidString,
                "route": route
            ]
        )
        return try await DatabaseService.shared.setTaskRoute(
            taskId: taskId,
            route: route,
            task: task
        )
    }

    // MARK: - Visit completion

    /// Complete a Handyman visit parent. Cascade-completes every child where
    /// `bundleId == parent.templateId` AND `assigned_route == "handyman"`.
    /// DIY-claimed children are skipped — they live on the user's list with
    /// their own completion cadence.
    ///
    /// Caller passes the already-loaded parent row (Visit view has it); avoids
    /// a round-trip. Next-due is advanced using the reconciler's nextDueDate
    /// helper which reads the template's frequency.
    static func completeVisit(
        parent: MaintenanceTaskDBRow,
        completionDate: Date = Date()
    ) async throws {
        let db = DatabaseService.shared
        guard let bundleKey = parent.templateId else { return }

        // Children in the bundle = other maintenance_tasks whose template
        // references this bundleId. Template lookup gives us the authoritative
        // bundleId for each candidate task.
        let siblings = (try? await db.fetchMaintenanceTasks(propertyId: parent.propertyId)) ?? []
        let children = siblings.filter { task in
            guard task.id != parent.id else { return false }
            guard let templateId = task.templateId,
                  let template = MaintenanceTemplates.template(forKey: templateId) else {
                return false
            }
            return template.bundleId == bundleKey
        }

        let completionFormatter = DateFormatter()
        completionFormatter.dateFormat = "yyyy-MM-dd"
        let completionString = completionFormatter.string(from: completionDate)

        var completedCount = 0
        var claimedDIYCount = 0
        for child in children {
            if child.assignedRoute == "diy" {
                claimedDIYCount += 1
                continue
            }
            // Mark complete and advance the next-due date based on template frequency.
            var update = MaintenanceTaskUpdate()
            update.lastCompletedDate = completionString
            if let nextDue = MaintenanceTaskReconciler.nextDueDate(
                for: child,
                system: nil,
                from: completionDate
            ) {
                update.nextDueDate = completionFormatter.string(from: nextDue)
            }
            _ = try? await db.updateMaintenanceTask(id: child.id, update)
            completedCount += 1
        }

        // Complete the parent itself.
        var parentUpdate = MaintenanceTaskUpdate()
        parentUpdate.lastCompletedDate = completionString
        if let nextDue = MaintenanceTaskReconciler.nextDueDate(
            for: parent,
            system: nil,
            from: completionDate
        ) {
            parentUpdate.nextDueDate = completionFormatter.string(from: nextDue)
        }
        _ = try? await db.updateMaintenanceTask(id: parent.id, parentUpdate)

        Analytics.track(.handymanVisitCompleted, [
            "bundle_id": bundleKey,
            "child_count_completed": completedCount,
            "child_count_claimed_diy": claimedDIYCount
        ])
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
    }

    /// Schedule the visit by setting the parent's `scheduled_date`. Caller
    /// can subsequently open `MessageComposeView` with a pre-filled SMS to
    /// the linked handyman contractor — we deliberately keep the draft
    /// composition outside this service since it depends on UI context.
    static func scheduleVisit(parentId: UUID, date: Date) async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var update = MaintenanceTaskUpdate()
        update.scheduledDate = formatter.string(from: date)
        _ = try await DatabaseService.shared.updateMaintenanceTask(id: parentId, update)

        Analytics.track(.handymanVisitScheduled, [
            "parent_id": parentId.uuidString,
            "scheduled_date": formatter.string(from: date)
        ])
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
    }

    /// Skip this visit entirely — user claimed everything as DIY or the
    /// handyman isn't coming this season. Archives the parent; the reconciler
    /// re-creates it next season.
    static func skipVisit(parent: MaintenanceTaskDBRow) async throws {
        let db = DatabaseService.shared
        let bundleKey = parent.templateId ?? "(unknown)"
        try await db.archiveMaintenanceTask(id: parent.id, reason: "handyman_visit_skipped:\(bundleKey)")
        Analytics.track(.handymanVisitSkipped, ["bundle_id": bundleKey])
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
    }

    // MARK: - Upsell scanner

    /// Candidate for addition to a handyman visit — either a real
    /// maintenance task or a pending punch item. Both are eligible
    /// upsell sources per Phase 67; the handyman visit surface treats
    /// them identically for display.
    struct UpsellCandidate: Identifiable {
        enum Source {
            case task(MaintenanceTaskDBRow)
            case punchItem(HandymanPunchItemRow)
        }
        let id: UUID
        let title: String
        let subtitle: String
        let urgencyDays: Int?  // Days overdue (negative) or days until due (positive); nil for punch items.
        let source: Source
    }

    /// Scan the user's task graph + handyman punch list for items the
    /// handyman could pick up on this visit. See Phase 67 plan for the
    /// full filter pipeline. Explicitly excludes Phase 54C Recommended
    /// library (discovery is a separate surface).
    static func scanUpsells(
        for bundleParent: MaintenanceTaskDBRow,
        allTasks: [MaintenanceTaskDBRow],
        punchItems: [HandymanPunchItemRow]
    ) -> [UpsellCandidate] {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let windowEnd = Calendar.current.date(byAdding: .day, value: 60, to: today) ?? today
        let bundleKey = bundleParent.templateId ?? ""

        // Step 1: task upsells.
        var taskCandidates: [UpsellCandidate] = []
        for task in allTasks {
            // Exclude the parent itself.
            if task.id == bundleParent.id { continue }
            // Exclude vehicle tasks.
            if task.vehicleId != nil { continue }
            // Exclude archived.
            if task.isArchived == true { continue }
            // Exclude tasks already in this bundle.
            if let templateId = task.templateId,
               let template = MaintenanceTemplates.template(forKey: templateId),
               template.bundleId == bundleKey {
                continue
            }
            // Exclude tasks already routed to vendor.
            if task.assignedRoute == "vendor" { continue }
            // Exclude tasks already routed to handyman (would dup on a second visit).
            if task.assignedRoute == "handyman" { continue }

            // Template-side gates.
            guard let templateId = task.templateId,
                  let template = MaintenanceTemplates.template(forKey: templateId) else {
                continue
            }
            // Must be .diyDefault or .diyCapable to be upsell-eligible.
            let routing = template.routing
            guard routing == .diyDefault || routing == .diyCapable else { continue }
            // Exclude safety-floor items.
            if template.safetyFloor { continue }
            // Exclude heavy tasks.
            if let effort = template.diyEffortMinutes, effort > 60 { continue }

            // Window: overdue or due within 60 days.
            guard let dueDate = formatter.date(from: task.nextDueDate) else { continue }
            if dueDate > windowEnd { continue }

            let days = Calendar.current.dateComponents([.day], from: today, to: dueDate).day
            let subtitle: String
            if let d = days, d < 0 {
                subtitle = "Overdue by \(-d) day\(-d == 1 ? "" : "s")"
            } else if let d = days {
                subtitle = "Due in \(d) day\(d == 1 ? "" : "s")"
            } else {
                subtitle = "Due soon"
            }

            taskCandidates.append(UpsellCandidate(
                id: task.id,
                title: task.title,
                subtitle: subtitle,
                urgencyDays: days,
                source: .task(task)
            ))
        }

        // Step 2: pending punch items.
        var punchCandidates: [UpsellCandidate] = punchItems
            .filter { $0.completedAt == nil && $0.archivedAt == nil }
            .map { item in
                UpsellCandidate(
                    id: item.id,
                    title: item.title,
                    subtitle: "Added to your punch list",
                    urgencyDays: nil,
                    source: .punchItem(item)
                )
            }

        // Step 3: sort — overdue first (most negative urgency), then
        // due-soon ascending, then punch items by created_at order.
        let overdue = taskCandidates
            .filter { ($0.urgencyDays ?? 0) < 0 }
            .sorted { ($0.urgencyDays ?? 0) < ($1.urgencyDays ?? 0) }
        let dueSoon = taskCandidates
            .filter { ($0.urgencyDays ?? 0) >= 0 }
            .sorted { ($0.urgencyDays ?? 0) < ($1.urgencyDays ?? 0) }
        let combined = overdue + dueSoon + punchCandidates

        // Cap at 10 — more than that overwhelms the visit UI.
        return Array(combined.prefix(10))
    }

    /// Move a candidate into the visit. For tasks, flips `assigned_route`
    /// to "handyman" (the child dedup relies on template bundleId match,
    /// so the task will surface in "What's included" on next fetch).
    /// For punch items, creates a new maintenance_tasks row under the
    /// parent's property with the punch item's title, then archives the
    /// punch item so it doesn't double-render.
    static func addUpsellToVisit(
        _ candidate: UpsellCandidate,
        bundleParent: MaintenanceTaskDBRow
    ) async throws {
        let db = DatabaseService.shared
        switch candidate.source {
        case .task(let task):
            _ = try await db.setTaskRoute(taskId: task.id, route: "handyman", task: task)
            Analytics.track(.handymanVisitUpsellAdded, [
                "bundle_id": bundleParent.templateId ?? "",
                "source": "overdue_task",
                "source_template_id": task.templateId ?? ""
            ])
        case .punchItem(let item):
            // Materialize as a maintenance_tasks row scoped to the parent's
            // property. Uses Phase 54B item fields; keeps propertyId
            // optional so household-level punch items still work.
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let nextDue = formatter.string(from: bundleParent.scheduledDate.flatMap(formatter.date) ?? Date())
            var insert = MaintenanceTaskInsert(
                householdId: item.householdId,
                title: item.title,
                frequency: "Once",
                nextDueDate: nextDue
            )
            insert.propertyId = item.propertyId ?? bundleParent.propertyId
            insert.description = item.description
            insert.priority = "Medium"
            insert.assignmentType = "vendor"
            insert.needsVendor = false
            insert.assignedRoute = "handyman"
            insert.notes = "Moved from handyman punch list."
            _ = try await db.createMaintenanceTask(insert)
            try await db.archiveHandymanPunchItem(id: item.id)
            Analytics.track(.handymanVisitUpsellAdded, [
                "bundle_id": bundleParent.templateId ?? "",
                "source": "punch_item"
            ])
        }
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
    }
}

import Foundation

enum HandymanRequestKind: String, CaseIterable, Identifiable {
    case standardVisit = "standard_visit"
    case quote = "quote"
    case repair = "repair"
    case install = "install"
    case assembly = "assembly"
    case question = "question"
    case setup = "setup"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standardVisit: return "Standard visit"
        case .quote: return "Quote request"
        case .repair: return "Small repair"
        case .install: return "Install or upgrade"
        case .assembly: return "Assembly or mounting"
        case .question: return "Ask my handyman"
        case .setup: return "First-visit setup"
        }
    }

    var icon: String {
        switch self {
        case .standardVisit: return "calendar.badge.plus"
        case .quote: return "doc.text.magnifyingglass"
        case .repair: return "wrench.and.screwdriver.fill"
        case .install: return "sparkles"
        case .assembly: return "shippingbox.fill"
        case .question: return "message.fill"
        case .setup: return "house.and.flag.fill"
        }
    }

    var helperText: String {
        switch self {
        case .standardVisit:
            return "Book a standard Chez handyman round so small jobs get batched into one profitable stop."
        case .quote:
            return "Ask the handyman to price a repair, install, or a broader punch-list scope."
        case .repair:
            return "Route a quick home repair directly to the handyman instead of creating project overhead."
        case .install:
            return "Use the handyman for swaps, upgrades, and low-risk installs that do not need a specialist."
        case .assembly:
            return "Great for mounting, shelves, mirrors, furniture, blinds, and other high-margin quick wins."
        case .question:
            return "Let the homeowner ask for advice, a look-around, or coordination on a nagging issue."
        case .setup:
            return "Prompt the first visit to capture appliances, systems, manuals, and other future-service context."
        }
    }

    var defaultTitle: String {
        switch self {
        case .standardVisit: return "Schedule our standard handyman visit"
        case .quote: return "Can you quote this work?"
        case .repair: return "Please handle this repair"
        case .install: return "Please install or upgrade this item"
        case .assembly: return "Please assemble or mount this item"
        case .question: return "Can you take a look at this?"
        case .setup: return "Please set this house up in Chez on your first visit"
        }
    }

    var recommendedLane: String {
        switch self {
        case .standardVisit: return "standard_visit"
        case .quote: return "quote"
        case .repair: return "repair"
        case .install: return "install"
        case .assembly: return "assembly"
        case .question: return "question"
        case .setup: return "setup"
        }
    }
}

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

    static func coordinationSummary(for request: HandymanRequestRow?) -> String? {
        guard let request else { return nil }
        return request.typedStatus.homeownerSummary
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
        let punchCandidates: [UpsellCandidate] = punchItems
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

    // MARK: - Premier portal

    static func portalURL(for token: String, visitId: UUID? = nil) -> URL? {
        var components = URLComponents(string: "https://getchez.com/handyman-visit")
        var queryItems = [URLQueryItem(name: "token", value: token)]
        if let visitId {
            queryItems.append(URLQueryItem(name: "visit", value: visitId.uuidString))
        }
        components?.queryItems = queryItems
        return components?.url
    }

    static func providerWorkspaceURL(for token: String) -> URL? {
        var components = URLComponents(string: "https://getchez.com/handyman")
        components?.queryItems = [URLQueryItem(name: "invite", value: token)]
        return components?.url
    }

    static func isFirstVisitSetupRecommended(
        systems: [HomeSystemRow],
        property: PropertyRow?
    ) -> Bool {
        guard let property else { return systems.isEmpty }
        let missingCoreCategories = coreSystemCategories.filter { category in
            !systems.contains(where: { $0.category.localizedCaseInsensitiveContains(category) })
        }
        let systemsMissingIdentity = systems.filter {
            ($0.modelNumber?.isEmpty ?? true)
                && ($0.serialNumber?.isEmpty ?? true)
                && ($0.manufacturer?.isEmpty ?? true)
        }
        return systems.isEmpty
            || missingCoreCategories.count >= 2
            || systemsMissingIdentity.count >= max(2, systems.count / 2)
            || (property.squareFootage ?? 0) > 0 && systems.count <= 2
    }

    static func setupPrompts(
        systems: [HomeSystemRow],
        property: PropertyRow?
    ) -> [HandymanPortalSetupPrompt] {
        var prompts: [HandymanPortalSetupPrompt] = []

        let missingCategories = coreSystemCategories.filter { category in
            !systems.contains(where: { $0.category.localizedCaseInsensitiveContains(category) })
        }

        if systems.isEmpty || !missingCategories.isEmpty {
            prompts.append(HandymanPortalSetupPrompt(
                id: "inventory",
                title: "Inventory major systems and appliances",
                detail: "Walk the house and add the major equipment that future repairs depend on: HVAC, water heater, laundry, kitchen appliances, sump, electrical, and plumbing standouts.",
                category: "inventory",
                isRequired: true
            ))
        }

        let systemsMissingIdentity = systems.filter {
            ($0.modelNumber?.isEmpty ?? true)
                || ($0.serialNumber?.isEmpty ?? true)
                || ($0.manufacturer?.isEmpty ?? true)
        }
        if !systemsMissingIdentity.isEmpty || systems.isEmpty {
            prompts.append(HandymanPortalSetupPrompt(
                id: "labels",
                title: "Capture model and serial labels",
                detail: "Take label photos for the equipment you touch so Chez can preload manuals, service notes, and the right replacement parts next time.",
                category: "labels",
                isRequired: true
            ))
        }

        let systemsMissingInstallDate = systems.filter { $0.installDate?.isEmpty ?? true }
        if !systemsMissingInstallDate.isEmpty || systems.isEmpty {
            prompts.append(HandymanPortalSetupPrompt(
                id: "install_dates",
                title: "Add install date or approximate age",
                detail: "Age is enough if exact paperwork is missing. This helps Chez recommend the right maintenance rhythm and replacement timing.",
                category: "age",
                isRequired: false
            ))
        }

        prompts.append(HandymanPortalSetupPrompt(
            id: "filters_shutoffs",
            title: "Record practical service details",
            detail: "Add filter sizes, shutoff locations, battery types, and any preferred products so the next visit starts with the right materials.",
            category: "service_context",
            isRequired: false
        ))

        if property != nil {
            prompts.append(HandymanPortalSetupPrompt(
                id: "manuals",
                title: "Flag missing manuals or warranty paperwork",
                detail: "When you spot a model label but no manual or install paperwork in Chez, flag it so the homeowner can upload or forward it later.",
                category: "documents",
                isRequired: false
            ))
        }

        return prompts
    }

    static func ensurePortalSession(
        parentTask: MaintenanceTaskDBRow,
        property: PropertyRow?,
        systems: [HomeSystemRow],
        checklistTasks: [MaintenanceTaskDBRow],
        diyClaims: [MaintenanceTaskDBRow],
        punchItems: [HandymanPunchItemRow],
        upsellCandidates: [UpsellCandidate],
        preferredHandyman: ContractorRow?,
        rotateAccessToken: Bool = false
    ) async throws -> HandymanPortalSessionRow {
        let db = DatabaseService.shared
        let latestRequest = try? await db.fetchLatestHandymanRequest(visitTaskId: parentTask.id)
        let requestMessages: [HandymanRequestMessageRow] = if let latestRequest {
            (try? await db.fetchHandymanRequestMessages(requestId: latestRequest.id)) ?? []
        } else {
            []
        }
        let seed = buildPortalSeed(
            parentTask: parentTask,
            property: property,
            systems: systems,
            checklistTasks: checklistTasks,
            diyClaims: diyClaims,
            punchItems: punchItems,
            upsellCandidates: upsellCandidates,
            preferredHandyman: preferredHandyman,
            latestRequest: latestRequest,
            requestMessages: requestMessages
        )

        if let existing = try await db.fetchHandymanPortalSession(visitTaskId: parentTask.id) {
            var update = HandymanPortalSessionUpdate()
            update.status = "active"
            update.seedPayload = seed
            update.lastOpenedAt = Date()
            if rotateAccessToken {
                update.portalToken = generatePortalToken()
            }
            if existing.expiresAt == nil {
                update.expiresAt = Calendar.current.date(byAdding: .day, value: 21, to: Date())
            }
            return try await db.updateHandymanPortalSession(id: existing.id, update)
        }

        let userId = await HavenSupabase.safeSession(timeout: 1.0)?.user.id
        var insert = HandymanPortalSessionInsert(
            householdId: parentTask.householdId,
            title: seed.visitTitle,
            portalToken: generatePortalToken(),
            seedPayload: seed
        )
        insert.propertyId = parentTask.propertyId
        insert.contractorId = preferredHandyman?.id ?? parentTask.assignedContractorId
        insert.visitTaskId = parentTask.id
        insert.createdByUserId = userId
        insert.firstVisit = seed.firstVisit
        insert.expiresAt = Calendar.current.date(byAdding: .day, value: 21, to: Date())
        return try await db.createHandymanPortalSession(insert)
    }

    static func prepareVisitCoordination(
        parentTask: MaintenanceTaskDBRow,
        scheduledDate: Date,
        property: PropertyRow?,
        systems: [HomeSystemRow],
        checklistTasks: [MaintenanceTaskDBRow],
        diyClaims: [MaintenanceTaskDBRow],
        punchItems: [HandymanPunchItemRow],
        upsellCandidates: [UpsellCandidate],
        preferredHandyman: ContractorRow
    ) async throws -> (request: HandymanRequestRow, portalSession: HandymanPortalSessionRow) {
        try await scheduleVisit(parentId: parentTask.id, date: scheduledDate)

        let portalSession = try await ensurePortalSession(
            parentTask: parentTask,
            property: property,
            systems: systems,
            checklistTasks: checklistTasks,
            diyClaims: diyClaims,
            punchItems: punchItems,
            upsellCandidates: upsellCandidates,
            preferredHandyman: preferredHandyman
        )

        let preferredTiming = shortDateString(from: scheduledDate)
        let request = try await ensureVisitRequest(
            parentTask: parentTask,
            contractor: preferredHandyman,
            preferredTiming: preferredTiming,
            firstVisitSetupRequested: isFirstVisitSetupRecommended(systems: systems, property: property),
            quickUpsellTitles: Array(upsellCandidates.prefix(3)).map(\.title)
        )

        try? await appendRequestMessage(
            request: request,
            senderRole: "homeowner",
            body: "Requested \(parentTask.title) for \(preferredTiming).",
            metadata: [
                "event": "requested_visit",
                "scheduled_date": preferredTiming
            ]
        )

        var havenBody = "Chez prepared the visit link for \(preferredTiming)."
        if let providerURL = providerWorkspaceURL(for: portalSession.portalToken) {
            havenBody += " Share this with the handyman so they can confirm the date, suggest another option, or open their Chez Handyman workspace: \(providerURL.absoluteString)"
        }
        try? await appendRequestMessage(
            request: request,
            senderRole: "haven",
            body: havenBody,
            metadata: [
                "event": "invite_ready",
                "scheduled_date": preferredTiming
            ]
        )

        return (request, portalSession)
    }

    private static func generatePortalToken() -> String {
        UUID().uuidString.lowercased() + String(UUID().uuidString.lowercased().prefix(8))
    }

    private static func buildPortalSeed(
        parentTask: MaintenanceTaskDBRow,
        property: PropertyRow?,
        systems: [HomeSystemRow],
        checklistTasks: [MaintenanceTaskDBRow],
        diyClaims: [MaintenanceTaskDBRow],
        punchItems: [HandymanPunchItemRow],
        upsellCandidates: [UpsellCandidate],
        preferredHandyman: ContractorRow?,
        latestRequest: HandymanRequestRow?,
        requestMessages: [HandymanRequestMessageRow]
    ) -> HandymanPortalSeedPayload {
        let addressLine = [property?.street, property?.city, property?.state]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: ", ")
        let knownSystems = systems
            .map(\.category)
            .uniqued()
            .sorted()
        let firstVisit = isFirstVisitSetupRecommended(systems: systems, property: property)

        let checklist: [HandymanPortalChecklistItem] = checklistTasks.map { task in
            HandymanPortalChecklistItem(
                id: task.id.uuidString,
                title: task.title,
                subtitle: task.notes ?? task.description ?? task.frequency,
                category: task.serviceKey ?? task.templateId,
                status: "todo",
                source: "included",
                recommended: false
            )
        } + punchItems.map { item in
            HandymanPortalChecklistItem(
                id: item.id.uuidString,
                title: item.title,
                subtitle: item.notes ?? item.description,
                category: "punch_list",
                status: "todo",
                source: "punch_list",
                recommended: false
            )
        }

        let diyItems = diyClaims.map { task in
            HandymanPortalChecklistItem(
                id: task.id.uuidString,
                title: task.title,
                subtitle: "Homeowner claimed this item.",
                category: task.serviceKey ?? task.templateId,
                status: "claimed_by_owner",
                source: "diy",
                recommended: false
            )
        }

        let quickUpsells = Array(upsellCandidates.prefix(6)).map { candidate in
            let category: String
            let priceHint: String?
            let minutesHint: Int?
            switch candidate.source {
            case .task(let task):
                category = task.serviceKey ?? task.templateId ?? "maintenance"
                priceHint = task.costRange
                minutesHint = nil
            case .punchItem(let item):
                category = "punch_list"
                priceHint = item.estimatedCostRange
                minutesHint = item.estimatedMinutes
            }

            return HandymanPortalUpsell(
                id: candidate.id.uuidString,
                title: candidate.title,
                detail: candidate.subtitle,
                category: category,
                priceHint: priceHint,
                minutesHint: minutesHint
            )
        }

        let propertySnapshot = HandymanPortalPropertySnapshot(
            name: property?.name ?? "Home",
            addressLine: addressLine.isEmpty ? nil : addressLine,
            propertyType: property?.propertyType ?? "Residence",
            squareFootage: property?.squareFootage,
            yearBuilt: property?.yearBuilt,
            systemCount: systems.count,
            knownSystems: knownSystems,
            systems: portalSystems(from: systems)
        )

        return HandymanPortalSeedPayload(
            visitId: parentTask.id,
            visitTitle: parentTask.title,
            scheduledDate: parentTask.scheduledDate,
            dueDate: parentTask.nextDueDate,
            firstVisit: firstVisit,
            property: propertySnapshot,
            contractorName: preferredHandyman?.companyName,
            contractorPhone: preferredHandyman?.phone,
            contractorEmail: preferredHandyman?.email,
            homeownerNotes: parentTask.notes,
            checklist: checklist,
            diyClaims: diyItems,
            quickUpsells: quickUpsells,
            setupPrompts: setupPrompts(systems: systems, property: property),
            coordination: coordinationState(
                request: latestRequest,
                requestMessages: requestMessages,
                scheduledDate: parentTask.scheduledDate ?? parentTask.nextDueDate
            ),
            recommendations: portalRecommendations(from: upsellCandidates)
        )
    }

    static func inviteEmailSubject(
        parentTask: MaintenanceTaskDBRow,
        property: PropertyRow?,
        preferredTiming: String
    ) -> String {
        let propertyName = property?.street ?? property?.name ?? "your Chez home"
        return "Chez visit request: \(parentTask.title) for \(propertyName) on \(preferredTiming)"
    }

    static func inviteEmailBody(
        parentTask: MaintenanceTaskDBRow,
        property: PropertyRow?,
        preferredTiming: String,
        portalURL: URL
    ) -> String {
        let propertyName = property?.street ?? property?.name ?? "the home"
        return """
        Chez would love to route this visit to you.

        Visit: \(parentTask.title)
        Home: \(propertyName)
        Requested date: \(preferredTiming)

        Open Chez Handyman to confirm the date, suggest alternatives, ask a question, or begin the visit once it's confirmed:
        \(portalURL.absoluteString)

        If you create your free provider account, you'll also see every Chez home that wants to work with you, your recent work, upcoming visits, and your quote desk in one place.
        """
    }

    static func inviteSMSBody(
        parentTask: MaintenanceTaskDBRow,
        property: PropertyRow?,
        preferredTiming: String,
        portalURL: URL
    ) -> String {
        let propertyName = property?.street ?? property?.name ?? "the home"
        return "Chez visit request for \(propertyName): \(parentTask.title) on \(preferredTiming). Confirm the date, suggest another option, or create your free Chez Handyman account here: \(portalURL.absoluteString)"
    }

    private static func ensureVisitRequest(
        parentTask: MaintenanceTaskDBRow,
        contractor: ContractorRow,
        preferredTiming: String,
        firstVisitSetupRequested: Bool,
        quickUpsellTitles: [String]
    ) async throws -> HandymanRequestRow {
        let db = DatabaseService.shared
        if let existing = try await db.fetchLatestHandymanRequest(visitTaskId: parentTask.id) {
            var update = HandymanRequestUpdate()
            update.contractorId = contractor.id
            update.visitTaskId = parentTask.id
            update.preferredTiming = preferredTiming
            update.status = HandymanRequestStatus.sentToHandyman.rawValue
            update.firstVisitSetupRequested = firstVisitSetupRequested
            update.quickUpsellTitles = quickUpsellTitles
            return try await db.updateHandymanRequest(id: existing.id, update)
        }

        var insert = HandymanRequestInsert(
            householdId: parentTask.householdId,
            requestType: HandymanRequestKind.standardVisit.rawValue,
            title: "Confirm \(parentTask.title)"
        )
        insert.propertyId = parentTask.propertyId
        insert.contractorId = contractor.id
        insert.visitTaskId = parentTask.id
        insert.createdByUserId = await HavenSupabase.safeSession(timeout: 1.0)?.user.id
        insert.details = "Please confirm the requested date or suggest alternatives through the Chez visit link."
        insert.preferredTiming = preferredTiming
        insert.status = HandymanRequestStatus.sentToHandyman.rawValue
        insert.firstVisitSetupRequested = firstVisitSetupRequested
        insert.recommendedLane = HandymanRequestKind.standardVisit.recommendedLane
        insert.quickUpsellTitles = quickUpsellTitles
        return try await db.createHandymanRequest(insert)
    }

    private static func appendRequestMessage(
        request: HandymanRequestRow,
        senderRole: String,
        body: String,
        metadata: [String: String]? = nil
    ) async throws {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else { return }
        _ = try await DatabaseService.shared.createHandymanRequestMessage(
            HandymanRequestMessageInsert(
                requestId: request.id,
                householdId: request.householdId,
                senderRole: senderRole,
                body: trimmedBody,
                metadata: metadata
            )
        )
        // Phase 95 (gaps #29 / #68): fire the email-fallback path on
        // homeowner messages. The function self-rate-limits to once
        // per request per 24h and short-circuits when the handyman
        // has been active in the portal recently. Fire-and-forget —
        // failures don't block the message that already landed
        // in-app.
        if senderRole == "homeowner" {
            Task.detached {
                _ = try? await HavenSupabase.notifyHandymanMessageFallback(requestId: request.id)
            }
        }
    }

    private static func portalSystems(from systems: [HomeSystemRow]) -> [HandymanPortalSystemRecord] {
        systems
            .sorted { lhs, rhs in
                if lhs.displayCategory != rhs.displayCategory {
                    return lhs.displayCategory.localizedCaseInsensitiveCompare(rhs.displayCategory) == .orderedAscending
                }
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
            .map { system in
                HandymanPortalSystemRecord(
                    id: system.id.uuidString,
                    systemId: system.id,
                    name: system.displayName,
                    category: system.displayCategory,
                    manufacturer: system.manufacturer,
                    modelNumber: system.modelNumber,
                    serialNumber: system.serialNumber,
                    installDate: system.installDate,
                    notes: system.notes,
                    lastServiceDate: system.lastServiceDate,
                    nextServiceDue: system.nextServiceDue,
                    needsSetup: (system.manufacturer?.isEmpty ?? true)
                        || (system.modelNumber?.isEmpty ?? true)
                        || (system.serialNumber?.isEmpty ?? true),
                    serviced: nil
                )
            }
    }

    private static func portalRecommendations(from candidates: [UpsellCandidate]) -> [HandymanPortalRecommendation] {
        Array(candidates.prefix(6)).map { candidate in
            let priority = if let urgency = candidate.urgencyDays, urgency < 0 {
                "high"
            } else {
                "normal"
            }

            return HandymanPortalRecommendation(
                id: candidate.id.uuidString,
                title: candidate.title,
                detail: candidate.subtitle,
                category: recommendationCategory(for: candidate),
                priority: priority,
                createFollowUp: false
            )
        }
    }

    private static func recommendationCategory(for candidate: UpsellCandidate) -> String {
        switch candidate.source {
        case .task(let task):
            return task.serviceKey ?? task.templateId ?? "maintenance"
        case .punchItem:
            return "punch_list"
        }
    }

    private static func coordinationState(
        request: HandymanRequestRow?,
        requestMessages: [HandymanRequestMessageRow],
        scheduledDate: String?
    ) -> HandymanPortalCoordinationState? {
        guard let request else { return nil }
        return HandymanPortalCoordinationState(
            requestId: request.id,
            status: request.status,
            statusLabel: request.typedStatus.displayLabel,
            intro: request.typedStatus.homeownerSummary,
            lastMessage: requestMessages.last?.body,
            scheduledDate: scheduledDate ?? request.preferredTiming,
            requestTitle: request.title,
            needsHomeownerReply: request.typedStatus.actionRequiredByHomeowner
        )
    }

    private static func shortDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private static let coreSystemCategories = [
        "hvac",
        "appliance",
        "water heater",
        "plumbing",
        "electrical"
    ]
}

private extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return self.filter { seen.insert($0).inserted }
    }
}

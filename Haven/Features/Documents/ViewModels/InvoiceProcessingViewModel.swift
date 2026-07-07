import Foundation
import SwiftUI

/// Represents a new system with its resolved parent assignment
struct ResolvedNewSystem: Identifiable {
    var id: String { original.id }
    let original: InvoiceNewSystem
    /// Phase 101 (E5) — when the invoice's new unit looks like a REPLACEMENT
    /// of an existing active system (same equipment family, different or
    /// newer unit), these carry the old system so the review sheet can offer
    /// "Replace [old]" explicitly. Never auto-archived without the toggle.
    var replaceCandidateId: UUID?
    var replaceCandidateName: String?
    var resolvedParentName: String?
    var resolvedParentCategory: String?
    var isAutoMatched: Bool
    var userChoice: ParentChoice = .autoOrNone

    enum ParentChoice {
        case autoOrNone
        case existingParent(UUID, String)
        case newParent(String)
        case independent
    }
}

/// Phase 50: Pending recurring-cadence suggestion surfaced from an
/// invoice. Stored on the view model after `applyChanges()` runs and
/// posted via `.invoiceCadenceDetected` so the Dashboard can render a
/// confirmation card. Accepting writes the new interval to
/// `home_systems.service_interval_days`; dismissing throws it away.
struct InvoiceCadenceSuggestion: Identifiable, Equatable {
    let id = UUID()
    let intervalDays: Int
    let quotedText: String?
    let vendorName: String?
    let systemId: UUID?
    let propertyId: UUID?
    let invoiceDocumentId: UUID
}

@MainActor
class InvoiceProcessingViewModel: ObservableObject {
    let documentId: UUID
    let propertyId: UUID?
    let vehicleId: UUID?
    let householdId: UUID

    @Published var result: InvoiceProcessingResult?
    @Published var isProcessing = false
    @Published var isApplying = false
    @Published var error: String?
    @Published var applySuccess = false

    // Selection state
    @Published var selectedTaskIds: Set<String> = []
    @Published var selectedNewSystemIds: Set<String> = []
    @Published var createServiceRecord = true
    /// Phase 101 (E5) — systems the homeowner explicitly approved as
    /// replacements: the matched old unit gets archived and its open tasks
    /// repoint to the new system at apply time.
    @Published var replaceApprovedIds: Set<String> = []

    // Resolved parent grouping for new systems
    @Published var resolvedSystems: [ResolvedNewSystem] = []
    @Published var existingTopLevelSystems: [HomeSystemRow] = []
    @Published var resolvedParentDisplayNames: [String: String] = [:]

    /// Phase 50: Cadence suggestion captured from the invoice when the
    /// AI extracted an explicit recurring schedule (e.g. "biweekly
    /// service plan"). Posted via NotificationCenter after the user
    /// applies invoice changes so the Dashboard can render a one-tap
    /// confirmation card.
    @Published var pendingCadenceSuggestion: InvoiceCadenceSuggestion?

    /// Phase 59: Tracks whether the user has resolved a medium/low/ambiguous
    /// vendor match (via candidate picker or "None of these" full picker).
    /// Flips to true after selection so the vendor-match section hides.
    @Published var vendorMatchResolved = false
    /// Phase 59: triggers presentation of a full contractor picker when
    /// candidate chips don't include the right vendor.
    @Published var showVendorPicker = false

    /// Phase 95.3 — non-fatal failures accumulated during `applyChanges`.
    /// Each entry is a one-line description of which item failed and a
    /// short reason. Surfaces in `InvoiceReviewSheet` as a "Heads up:
    /// some items didn't save" callout after the success path runs.
    ///
    /// Why this exists: every loop inside `applyChanges` previously
    /// shared one big `do/catch` — a single failure aborted EVERY
    /// subsequent operation. Worse, the user got a generic error with
    /// no idea which items landed or what to retry. We now wrap each
    /// per-item operation in its own try/catch, append the failure to
    /// this array, and keep going. The final UI shows a summary so the
    /// user can decide whether to retry specific things from elsewhere
    /// (system detail, the document, etc.) without losing the items
    /// that DID save.
    @Published var applyWarnings: [String] = []

    init(documentId: UUID, propertyId: UUID, householdId: UUID) {
        self.documentId = documentId
        self.propertyId = propertyId
        self.vehicleId = nil
        self.householdId = householdId
    }

    init(documentId: UUID, vehicleId: UUID, householdId: UUID) {
        self.documentId = documentId
        self.propertyId = nil
        self.vehicleId = vehicleId
        self.householdId = householdId
    }

    func process() async {
        isProcessing = true
        error = nil

        do {
            // Phase 59: if the document was uploaded from a vendor context
            // (ContractorDetailView "Add a bill"), the row already has
            // contractor_id set by DocumentUploadViewModel. Read it here
            // so process-invoice can skip vendor matching and stamp this
            // contractor with "high" confidence.
            var preferredContractorId: String? = nil
            if let doc = try? await DatabaseService.shared.fetchDocument(id: documentId),
               let cid = doc.contractorId {
                preferredContractorId = cid.uuidString
            }

            let response: InvoiceProcessingResult
            if let vehicleId {
                response = try await HavenSupabase.processVehicleInvoice(
                    documentId: documentId.uuidString,
                    vehicleId: vehicleId.uuidString,
                    householdId: householdId.uuidString,
                    preferredContractorId: preferredContractorId
                )
            } else if let propertyId {
                response = try await HavenSupabase.processInvoice(
                    documentId: documentId.uuidString,
                    propertyId: propertyId.uuidString,
                    householdId: householdId.uuidString,
                    preferredContractorId: preferredContractorId
                )
            } else {
                error = "No property or vehicle selected"
                isProcessing = false
                return
            }
            result = response

            // Pre-select high and medium confidence tasks
            selectedTaskIds = Set(
                response.completedTasks
                    .filter { $0.confidence == "high" || $0.confidence == "medium" }
                    .map(\.id)
            )

            // Pre-select all new systems
            selectedNewSystemIds = Set(response.newSystemsDiscovered.map(\.id))

            // Resolve parent groups deterministically via keyword table
            resolvedSystems = response.newSystemsDiscovered.map { system in
                let parentGroup = Self.findParentGroup(for: system.name, category: system.suggestedCategory)
                return ResolvedNewSystem(
                    original: system,
                    resolvedParentName: parentGroup?.parentName ?? system.parentSystemName,
                    resolvedParentCategory: parentGroup?.parentCategory,
                    isAutoMatched: parentGroup != nil
                )
            }

            // Fetch existing top-level systems for user picker (unmatched systems) -- home invoices only
            if let propertyId {
                existingTopLevelSystems = (try? await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId, topLevelOnly: true)) ?? []
            }

            // Phase 101 (E5) — replacement detection. A discovered system that
            // shares an equipment family with an existing active system but
            // carries a DIFFERENT model (or the existing has none) reads as
            // "new unit replacing old" — surface an explicit Replace toggle.
            // An identical model stays a plain duplicate (skipped at apply).
            for idx in resolvedSystems.indices {
                let sys = resolvedSystems[idx].original
                if let match = existingTopLevelSystems.first(where: { existing in
                    guard existing.isActive ?? true else { return false }
                    let sameFamily = Self.isLikelyDuplicate(
                        newName: sys.name, newManufacturer: sys.manufacturer, newModel: nil,
                        existingName: existing.name, existingManufacturer: existing.manufacturer, existingModel: nil
                    )
                    guard sameFamily else { return false }
                    // Identical model = duplicate, not replacement.
                    if let newModel = sys.modelNumber, let oldModel = existing.modelNumber,
                       newModel.caseInsensitiveCompare(oldModel) == .orderedSame {
                        return false
                    }
                    return true
                }) {
                    resolvedSystems[idx].replaceCandidateId = match.id
                    resolvedSystems[idx].replaceCandidateName = match.name
                }
            }

            // Resolve what each parent name will actually map to (alias matching)
            resolvedParentDisplayNames = [:]
            for parentName in Set(resolvedSystems.compactMap(\.resolvedParentName)) {
                var searchNames = [parentName]
                if let aliases = Self.parentAliases[parentName] {
                    searchNames.append(contentsOf: aliases)
                }
                let existingMatch = existingTopLevelSystems.first { sys in
                    searchNames.contains { searchName in
                        sys.name.localizedCaseInsensitiveContains(searchName) ||
                        searchName.localizedCaseInsensitiveContains(sys.name)
                    }
                }
                if let existingMatch, existingMatch.name != parentName {
                    resolvedParentDisplayNames[parentName] = "\(existingMatch.name) (existing)"
                }
            }
        } catch {
            self.error = error.localizedDescription
            print("[InvoiceProcessing] Error: \(error)")
        }

        isProcessing = false
    }

    /// Phase 59: write the selected contractor back to the document row
    /// and flip vendor_match_confidence to "high". Called from the
    /// InvoiceReviewSheet candidate picker (chip tap or full-picker result).
    func assignVendorMatch(contractorId: String) async {
        guard let cid = UUID(uuidString: contractorId) else { return }
        var update = DocumentUpdate()
        update.contractorId = cid
        update.vendorMatchConfidence = "high"
        _ = try? await DatabaseService.shared.updateDocument(id: documentId, update)
        await MainActor.run {
            vendorMatchResolved = true
            showVendorPicker = false
        }
        NotificationCenter.default.post(name: .documentChanged, object: nil)
    }

    func applyChanges() async {
        guard let result else { return }
        isApplying = true
        error = nil
        // Phase 95.3 — reset warnings at the top of every apply pass so
        // a previous run's partial failures don't carry over into the
        // user's view of THIS apply.
        applyWarnings = []

        let db = DatabaseService.shared
        let invoiceDateStr = result.invoiceDate ?? ISO8601DateFormatter().string(from: Date()).prefix(10).description

        do {
            // 1. Complete matched maintenance tasks
            //
            // Phase 95.3: each task completion is now wrapped in its own
            // try/catch so one failed update doesn't abort the rest of
            // the apply flow. The failed task gets a warning entry; the
            // user sees a "couldn't complete X" line in the summary and
            // can retry from the task detail screen.
            for task in result.completedTasks where selectedTaskIds.contains(task.id) {
                guard let taskIdStr = task.matchedMaintenanceTaskId,
                      let taskId = UUID(uuidString: taskIdStr) else { continue }
                do {
                    _ = try await db.updateMaintenanceTask(id: taskId, MaintenanceTaskUpdate(
                        lastCompletedDate: invoiceDateStr
                    ))
                } catch {
                    applyWarnings.append("Couldn't mark \"\(task.description)\" complete (\(Self.friendlyReason(error)))")
                    print("[InvoiceProcessing] Task completion failed: \(error)")
                }
            }

            // For vehicle invoices, the server already handled task completion, mileage,
            // and service records. Skip home-system-specific operations.
            let isVehicleInvoice = vehicleId != nil

            // 1.5 Update last_service_date for ALL systems referenced in the invoice (home only)
            if !isVehicleInvoice {
                var updatedSystemIds: Set<UUID> = []
                for task in result.completedTasks where selectedTaskIds.contains(task.id) {
                    if let systemIdStr = task.matchedSystemId,
                       let systemId = UUID(uuidString: systemIdStr),
                       !updatedSystemIds.contains(systemId) {
                        do {
                            _ = try await db.updateHomeSystem(id: systemId, HomeSystemUpdate(
                                lastServiceDate: invoiceDateStr
                            ))
                            updatedSystemIds.insert(systemId)
                        } catch {
                            // Non-blocking — the service record below will
                            // still capture the visit. Just flag for the
                            // user so they know last-service-date didn't
                            // refresh on the system row.
                            applyWarnings.append("Couldn't update last service date on a system (\(Self.friendlyReason(error)))")
                            print("[InvoiceProcessing] System last_service_date update failed: \(error)")
                        }
                    }
                }
            }

            // 2. Create new discovered systems using resolved parent assignments (home only)
            guard let propertyId, !isVehicleInvoice else {
                // Vehicle invoices: just post notifications and finish
                NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                NotificationCenter.default.post(name: .documentChanged, object: nil)
                applySuccess = true
                isApplying = false
                return
            }
            var existingSystems = try await db.fetchHomeSystems(propertyId: propertyId)
            var parentSystemCache: [String: UUID] = [:]

            for resolved in resolvedSystems where selectedNewSystemIds.contains(resolved.id) {
                let system = resolved.original

                // Phase 101 (E5) — homeowner-approved replacement: the old
                // unit archives and its open tasks repoint to the new system
                // created below. Approval is the explicit toggle in the
                // review sheet; nothing archives silently.
                let approvedReplaceId: UUID? = replaceApprovedIds.contains(resolved.id)
                    ? resolved.replaceCandidateId
                    : nil

                // Duplicate check with fuzzy matching (replacements bypass it:
                // they are SUPPOSED to look like the old unit).
                if approvedReplaceId == nil {
                    let isDuplicate = existingSystems.contains { existing in
                        Self.isLikelyDuplicate(
                            newName: system.name, newManufacturer: system.manufacturer, newModel: system.modelNumber,
                            existingName: existing.name, existingManufacturer: existing.manufacturer, existingModel: existing.modelNumber
                        )
                    }
                    if isDuplicate {
                        print("[InvoiceProcessing] Skipping duplicate: \(system.name)")
                        continue
                    }
                }

                // Resolve parent based on deterministic match or user choice
                var parentId: UUID?
                switch resolved.userChoice {
                case .autoOrNone:
                    if let parentName = resolved.resolvedParentName, !parentName.isEmpty, parentName != "Independent" {
                        parentId = try await resolveOrCreateParent(
                            name: parentName,
                            category: resolved.resolvedParentCategory ?? system.suggestedCategory ?? "Other",
                            existingSystems: &existingSystems,
                            cache: &parentSystemCache,
                            db: db
                        )
                    }
                case .existingParent(let existingId, _):
                    parentId = existingId
                case .newParent(let newParentName):
                    // User explicitly chose this name — don't alias-resolve to a different system
                    parentId = try await resolveOrCreateParent(
                        name: newParentName,
                        category: system.suggestedCategory ?? "Other",
                        existingSystems: &existingSystems,
                        cache: &parentSystemCache,
                        db: db,
                        useAliases: false
                    )
                case .independent:
                    parentId = nil
                }

                // Phase 95.3: per-system try/catch so a single create
                // failure (RLS, duplicate, network) doesn't abort the
                // whole apply. The user sees which system failed in
                // the warning summary and can re-add manually.
                do {
                    let newSystem = try await db.createHomeSystem(HomeSystemInsert(
                        propertyId: propertyId,
                        householdId: householdId,
                        name: system.name,
                        category: system.suggestedCategory ?? "Other",
                        manufacturer: system.manufacturer,
                        modelNumber: system.modelNumber,
                        installDate: system.installDate,
                        status: "good",
                        notes: system.details,
                        parentSystemId: parentId
                    ))
                    existingSystems.append(newSystem)

                    // Phase 101 (E5) — execute the approved replacement: open
                    // tasks move to the new unit, then the old unit archives
                    // (history preserved; completed tasks stay where they were).
                    if let oldId = approvedReplaceId {
                        do {
                            try await db.repointTasksToSystem(from: oldId, to: newSystem.id)
                            try await db.archiveHomeSystem(id: oldId)
                            print("[InvoiceProcessing] Replaced system \(oldId) with \(newSystem.id)")
                        } catch {
                            applyWarnings.append("Added \"\(system.name)\" but couldn't archive the old unit (\(Self.friendlyReason(error)))")
                        }
                    }

                    // Migrate equipment-specific tasks from parent to this new child system
                    if let parentId {
                        await migrateMatchingTasks(newSystem: newSystem, parentId: parentId, db: db)
                    }
                } catch {
                    applyWarnings.append("Couldn't add \"\(system.name)\" (\(Self.friendlyReason(error)))")
                    print("[InvoiceProcessing] System create failed for \(system.name): \(error)")
                }
            }

            // 3. Create service records — one per distinct system referenced in completed tasks
            if createServiceRecord {
                var contractorId: UUID?
                if let matchedId = result.vendor?.matchedContractorId {
                    contractorId = UUID(uuidString: matchedId)
                }

                // Collect all unique systems referenced in selected tasks
                var systemTaskDescriptions: [UUID: [String]] = [:]
                var noSystemDescriptions: [String] = []
                for task in result.completedTasks where selectedTaskIds.contains(task.id) {
                    if let sysIdStr = task.matchedSystemId, let sysId = UUID(uuidString: sysIdStr) {
                        systemTaskDescriptions[sysId, default: []].append(task.description)
                    } else {
                        noSystemDescriptions.append(task.description)
                    }
                }

                if systemTaskDescriptions.isEmpty {
                    // No system matches — create one general service record
                    do {
                        _ = try await db.createServiceRecord(ServiceRecordInsert(
                            propertyId: propertyId,
                            householdId: householdId,
                            serviceDate: invoiceDateStr,
                            serviceType: "Maintenance",
                            description: result.serviceSummary ?? "Service performed per invoice",
                            contractorId: contractorId,
                            cost: result.totalAmount,
                            invoiceDocumentId: documentId
                        ))
                    } catch {
                        applyWarnings.append("Couldn't save the service record (\(Self.friendlyReason(error)))")
                        print("[InvoiceProcessing] Service record create failed: \(error)")
                    }
                } else {
                    // Create one service record per system, split cost proportionally
                    var isFirst = true
                    for (systemId, descriptions) in systemTaskDescriptions {
                        let summary = descriptions.joined(separator: "; ")
                        let truncated = summary.count > 200 ? String(summary.prefix(197)) + "..." : summary
                        do {
                            _ = try await db.createServiceRecord(ServiceRecordInsert(
                                propertyId: propertyId,
                                householdId: householdId,
                                serviceDate: invoiceDateStr,
                                serviceType: "Maintenance",
                                description: truncated,
                                systemId: systemId,
                                contractorId: contractorId,
                                cost: isFirst ? result.totalAmount : nil,
                                invoiceDocumentId: isFirst ? documentId : nil
                            ))
                            isFirst = false
                        } catch {
                            applyWarnings.append("Couldn't save the service record for one system (\(Self.friendlyReason(error)))")
                            print("[InvoiceProcessing] Service record create failed for system \(systemId): \(error)")
                        }
                    }
                }
            }

            // 4. Create new contractor if vendor didn't match
            if let vendor = result.vendor,
               vendor.matchedContractorId == nil,
               let companyName = vendor.companyName,
               !companyName.isEmpty {
                do {
                    _ = try await db.createContractor(ContractorInsert(
                        householdId: householdId,
                        companyName: companyName,
                        phone: vendor.phone ?? "Not provided",
                        email: vendor.email,
                        address: vendor.address,
                        notes: "Auto-added from invoice processing"
                    ))
                } catch {
                    applyWarnings.append("Couldn't add \(companyName) as a contractor (\(Self.friendlyReason(error)))")
                    print("[InvoiceProcessing] Contractor create failed: \(error)")
                }
            }

            // 5. Create follow-up maintenance tasks
            //
            // Phase 50: tag follow-ups with vendor metadata so the
            // PropertyDetailView Maintenance tab can render them in the
            // amber follow-up section. The notes prefix ("Vendor follow-up:")
            // is the lookup key — keep it stable. We also link the task to
            // the matched contractor and stamp `assignment_type = "vendor"`
            // so the vendor schedule + amber tint flow naturally from the
            // existing routing logic.
            if let followUps = result.followUpNeeded {
                // Resolve the vendor name + contractor id once. The vendor
                // either matched an existing contractor (matched_contractor_id)
                // or we just created one above (look it up by name).
                var followUpContractorId: UUID? = result.vendor?.matchedContractorId.flatMap { UUID(uuidString: $0) }
                if followUpContractorId == nil, let companyName = result.vendor?.companyName {
                    let allContractors = (try? await db.fetchContractors()) ?? []
                    followUpContractorId = allContractors.first(where: {
                        $0.companyName.caseInsensitiveCompare(companyName) == .orderedSame
                    })?.id
                }
                let vendorLabel = result.vendor?.companyName ?? "your vendor"

                for followUp in followUps {
                    let dueDate = followUp.suggestedDueDate ?? {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let fallback = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
                        return dateFormatter.string(from: fallback)
                    }()

                    let priority: String = {
                        switch followUp.urgency {
                        case "soon": return "high"
                        case "routine": return "medium"
                        default: return "low"
                        }
                    }()

                    var insert = MaintenanceTaskInsert(
                        propertyId: propertyId,
                        householdId: householdId,
                        title: followUp.description,
                        frequency: "once",
                        nextDueDate: dueDate
                    )
                    insert.priority = priority
                    insert.notes = "Vendor follow-up: \(followUp.description)\n\nSource: invoice from \(vendorLabel), \(invoiceDateStr)"
                    insert.assignmentType = "vendor"
                    insert.assignedContractorId = followUpContractorId
                    insert.needsVendor = followUpContractorId == nil
                    insert.serviceKey = ServiceLibrary.serviceKey(for: insert) ?? "custom_seasonal_service"
                    do {
                        _ = try await ServiceOrchestrator.createCustomService(insert)
                    } catch {
                        applyWarnings.append("Couldn't create the follow-up \"\(followUp.description)\" (\(Self.friendlyReason(error)))")
                        print("[InvoiceProcessing] Follow-up create failed: \(error)")
                    }
                }
            }

            // Phase 50: surface explicit recurring cadence detected on the
            // invoice. We don't auto-apply — the Dashboard renders a prompt
            // card via `pendingCadenceSuggestion` so the user confirms
            // before we rewrite the system's service interval.
            if let cadence = result.cadenceDetected,
               let intervalDays = cadence.intervalDays,
               intervalDays > 0,
               (cadence.confidence ?? 0) > 0.8 {
                // Resolve the linked system from the most-referenced
                // matched_system_id in completed tasks (the one the
                // contractor actually serviced).
                let systemCounts = Dictionary(grouping: result.completedTasks.compactMap {
                    $0.matchedSystemId.flatMap(UUID.init(uuidString:))
                }, by: { $0 })
                .mapValues(\.count)
                let topSystemId = systemCounts.max { $0.value < $1.value }?.key
                pendingCadenceSuggestion = InvoiceCadenceSuggestion(
                    intervalDays: intervalDays,
                    quotedText: cadence.quotedText,
                    vendorName: vendorLabelForCadence(),
                    systemId: topSystemId,
                    propertyId: propertyId,
                    invoiceDocumentId: documentId
                )
            }

            // 6. Reschedule notifications
            await NotificationScheduler.shared.rescheduleAll()

            // 7. Post data sync notifications
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
            NotificationCenter.default.post(name: .contractorChanged, object: nil)
            // Phase 50: broadcast the cadence suggestion so the Dashboard
            // can pick it up and render the prompt card. The Dashboard
            // listens for this notification and pulls the latest
            // suggestion from a shared coordinator.
            if let suggestion = pendingCadenceSuggestion {
                NotificationCenter.default.post(
                    name: .invoiceCadenceDetected,
                    object: nil,
                    userInfo: ["suggestion_id": suggestion.id.uuidString]
                )
                InvoiceCadenceCoordinator.shared.publish(suggestion)
            }

            // Phase 51: Auto-confirm standing appointment visits when invoice
            // service date matches a scheduled visit (within +/- 3 days).
            if let contractorIdStr = result.vendor?.matchedContractorId,
               let vendorUUID = UUID(uuidString: contractorIdStr),
               let serviceDate = result.invoiceDate {
                await StandingAppointmentViewModel.shared.autoConfirmFromInvoice(
                    vendorId: vendorUUID,
                    serviceDate: serviceDate
                )
            }

            applySuccess = true
            Haptics.success()
            Analytics.track(.invoiceProcessed, [
                "tasks_completed": selectedTaskIds.count,
                "systems_added": selectedNewSystemIds.count,
                "service_record_created": createServiceRecord,
                "follow_ups_created": result.followUpNeeded?.count ?? 0
            ])
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
            print("[InvoiceProcessing] Apply error: \(error)")
        }

        isApplying = false
    }

    // MARK: - Phase 95.3 Error Helpers

    /// Convert an error into a short, user-readable reason. Used inside
    /// every per-item try/catch in `applyChanges` so the warning lines
    /// in InvoiceReviewSheet stay scannable. Never leaks raw error
    /// types or stack traces to the user.
    private static func friendlyReason(_ error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return "network error"
        }
        // PostgrestError comes through as a generic description; strip
        // any obvious "Failed to ..." prefix Supabase appends so the
        // line reads tighter inside the parenthesis.
        let message = error.localizedDescription
        if message.count > 60 {
            return "save failed"
        }
        return message
    }

    // MARK: - Task Migration

    /// When a new child system is added, migrate equipment-specific tasks from the parent.
    private func migrateMatchingTasks(newSystem: HomeSystemRow, parentId: UUID, db: DatabaseService) async {
        let parentTasks = (try? await db.fetchMaintenanceTasks(systemId: parentId)) ?? []
        guard !parentTasks.isEmpty else { return }

        let systemNameLower = newSystem.name.lowercased()
        let allTemplates = MaintenanceTemplates.allTemplates.flatMap(\.1)

        // Word-boundary keyword match
        let kwMatch: (String, String) -> Bool = { name, kw in
            let lower = kw.lowercased()
            if lower.contains(" ") { return name.contains(lower) }
            return Set(name.components(separatedBy: CharacterSet.alphanumerics.inverted)).contains(lower)
        }

        // Find template IDs that have equipmentKeywords matching this new system
        let matchingTemplateIds = Set(allTemplates
            .filter { template in
                !template.equipmentKeywords.isEmpty &&
                template.equipmentKeywords.contains { kwMatch(systemNameLower, $0) }
            }
            .map { $0.systemCategory + ":" + $0.title })

        for task in parentTasks {
            if let templateId = task.templateId, matchingTemplateIds.contains(templateId) {
                _ = try? await db.updateMaintenanceTask(id: task.id, MaintenanceTaskUpdate(systemId: newSystem.id))
            }
        }
    }

    // MARK: - Parent Resolution

    /// Aliases for parent system matching — kept minimal.
    /// Most matching should work via exact name since DefaultSystemsService
    /// creates standard parent systems during property onboarding.
    private static let parentAliases: [String: [String]] = [:]

    private func resolveOrCreateParent(
        name: String, category: String,
        existingSystems: inout [HomeSystemRow],
        cache: inout [String: UUID],
        db: DatabaseService,
        useAliases: Bool = true
    ) async throws -> UUID {
        if let cachedId = cache[name] { return cachedId }

        // Build list of names to search for
        // Only use aliases for auto-matched systems, NOT for explicit user choices
        var searchNames = [name]
        if useAliases, let aliases = Self.parentAliases[name] {
            searchNames.append(contentsOf: aliases)
        }

        // Exact name match first (case-insensitive)
        let exactMatch = existingSystems.first { sys in
            sys.parentSystemId == nil && sys.name.lowercased() == name.lowercased()
        }
        if let exactMatch {
            cache[name] = exactMatch.id
            return exactMatch.id
        }

        // Fuzzy match (contains)
        let existing = existingSystems.first { sys in
            sys.parentSystemId == nil && searchNames.contains { searchName in
                sys.name.localizedCaseInsensitiveContains(searchName) ||
                searchName.localizedCaseInsensitiveContains(sys.name)
            }
        }
        if let existing {
            cache[name] = existing.id
            return existing.id
        }

        // Final DB check before creating (race condition prevention)
        let dbCheck = try await db.fetchHomeSystems(propertyId: propertyId!)
        let dbMatch = dbCheck.first { $0.parentSystemId == nil && $0.name.lowercased() == name.lowercased() }
        if let dbMatch {
            cache[name] = dbMatch.id
            existingSystems = dbCheck
            return dbMatch.id
        }

        // Create new parent
        let newParent = try await db.createHomeSystem(HomeSystemInsert(
            propertyId: propertyId!,
            householdId: householdId,
            name: name,
            category: category,
            status: "good",
            notes: "Auto-created as parent system during invoice processing"
        ))
        cache[name] = newParent.id
        existingSystems.append(newParent)
        return newParent.id
    }

    // MARK: - Parent Grouping Keyword Table

    private static let parentGroupings: [(keywords: [String], parentName: String, parentCategory: String)] = [
        // Well / Water Treatment
        (["well pump", "well tank", "pressure tank", "acid neutralizer", "water softener",
          "carbon filter", "radon filter", "radon carbon", "uv water", "uv purification",
          "uv treatment", "uv filter", "uv bulb", "cartridge filter", "sediment filter",
          "calcite", "water treatment", "neutralizing media", "iron filter", "manganese filter",
          "water purification"],
         "Well System", "Well System"),
        // HVAC
        (["air handler", "condenser unit", "compressor", "thermostat", "heat pump", "furnace",
          "evaporator coil", "blower motor", "capacitor", "contactor", "refrigerant",
          "expansion valve", "ductwork", "damper", "zone valve", "mini split", "hvac filter"],
         "Central HVAC", "HVAC"),
        // Pool / Spa
        (["pool pump", "pool filter", "pool heater", "chlorinator", "salt cell",
          "pool light", "skimmer", "pool valve", "spa pump", "spa heater", "hot tub",
          "pool cleaner", "pool cover"],
         "Pool/Spa System", "Pool/Spa"),
        // Electrical
        (["circuit breaker", "electrical panel", "subpanel", "gfci", "arc fault",
          "transfer switch", "surge protector", "whole house surge", "wiring"],
         "Electrical System", "Electrical"),
        // Septic
        (["septic tank", "septic pump", "distribution box", "leach field", "drain field",
          "septic baffle", "septic filter", "effluent filter", "septic aerator"],
         "Septic System", "Septic System"),
        // Security
        (["security camera", "alarm panel", "motion sensor", "door sensor",
          "security keypad", "doorbell camera", "nvr", "dvr", "security sensor"],
         "Security System", "Security System"),
        // Solar
        (["solar panel", "inverter", "solar battery", "microinverter", "power optimizer",
          "solar monitoring"],
         "Solar System", "Solar"),
        // Irrigation
        (["sprinkler head", "irrigation valve", "drip line", "irrigation controller",
          "rain sensor", "backflow preventer irrigation", "sprinkler zone"],
         "Irrigation System", "Irrigation"),
        // Generator
        (["generator transfer", "generator battery", "generator controller",
          "automatic transfer switch", "generator oil", "generator coolant"],
         "Backup Generator", "Generator"),
        // Garage Door
        (["garage door opener", "garage door spring", "garage door sensor",
          "garage door track", "garage door panel", "garage door roller"],
         "Garage Door", "Garage Door"),
        // Fire Protection
        (["smoke detector", "carbon monoxide detector", "fire extinguisher",
          "fire sprinkler"],
         "Smoke & Fire Protection", "Fire Protection"),
        // Roofing
        (["roof shingle", "roof flashing", "gutter", "downspout", "soffit", "fascia",
          "roof vent", "ridge vent", "ice dam", "roof membrane"],
         "Roof", "Roofing"),
    ]

    private static func findParentGroup(for systemName: String, category: String? = nil) -> (parentName: String, parentCategory: String)? {
        let lower = systemName.lowercased()
        let catLower = (category ?? "").lowercased()
        for group in parentGroupings {
            if group.keywords.contains(where: { lower.contains($0) || catLower.contains($0) }) {
                return (group.parentName, group.parentCategory)
            }
        }
        return nil
    }

    // MARK: - Duplicate Detection

    /// Check if two system names likely refer to the same physical system using fuzzy word matching.
    static func isLikelyDuplicate(newName: String, newManufacturer: String?, newModel: String?,
                                   existingName: String, existingManufacturer: String?, existingModel: String?) -> Bool {
        let stopWords: Set<String> = ["the", "and", "for", "with", "system", "unit", "model", "series", "water", "air", "home", "house"]
        let normalize: (String) -> Set<String> = { s in
            Set(s.lowercased()
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "/", with: " ")
                .components(separatedBy: .whitespaces)
                .filter { $0.count > 2 && !stopWords.contains($0) })
        }

        let newWords = normalize(newName)
        let existingWords = normalize(existingName)

        // Significant word overlap — require at least 2 matching words AND >= 60% of shorter set
        // BUT check for conflicting qualifiers first (left vs right = different units)
        let qualifiers = ["left", "right", "primary", "backup", "secondary", "upstairs", "downstairs", "front", "rear", "master", "guest"]
        let newQual = qualifiers.first { newWords.contains($0) }
        let existQual = qualifiers.first { existingWords.contains($0) }
        if let nq = newQual, let eq = existQual, nq != eq {
            return false // Different qualifiers = different units, never a duplicate
        }

        let overlap = newWords.intersection(existingWords).count
        let minCount = min(newWords.count, existingWords.count)
        if overlap >= 2 && minCount > 0 && Double(overlap) / Double(minCount) >= 0.6 {
            return true
        }

        // Model number match (strongest signal)
        if let newModel, !newModel.isEmpty,
           let existingModel, !existingModel.isEmpty {
            let nm = newModel.lowercased().replacingOccurrences(of: "-", with: "")
            let em = existingModel.lowercased().replacingOccurrences(of: "-", with: "")
            if nm == em || nm.contains(em) || em.contains(nm) {
                return true
            }
        }

        // Manufacturer + functional type match
        if let mfr = newManufacturer, !mfr.isEmpty {
            let mfrLower = mfr.lowercased()
            if existingName.lowercased().contains(mfrLower) ||
               existingManufacturer?.lowercased().contains(mfrLower) == true {
                let functionalWords = ["pump", "tank", "filter", "valve", "softener", "heater",
                                       "neutralizer", "purification", "treatment"]
                let newFunc = functionalWords.first { newName.lowercased().contains($0) }
                let existFunc = functionalWords.first { existingName.lowercased().contains($0) }
                if let nf = newFunc, let ef = existFunc, nf == ef {
                    return true
                }
            }
        }

        // Functional type matching — catches different names for the same system type
        let functionalTypes: [(keywords: [String], function: String)] = [
            (["sump pump", "sump", "submersible pump", "submersible"], "sump_pump"),
            (["well pump", "jet pump", "deep well pump"], "well_pump"),
            (["water heater", "hot water heater", "tankless water"], "water_heater"),
            (["softener", "water softener"], "water_softener"),
            (["neutralizer", "acid neutralizer", "calcite"], "acid_neutralizer"),
            (["carbon filter", "radon filter", "radon carbon"], "carbon_filter"),
            (["uv", "ultraviolet", "purification", "germicidal"], "uv_system"),
            (["pressure tank", "well tank", "bladder tank"], "pressure_tank"),
            (["furnace", "gas furnace", "oil furnace"], "furnace"),
            (["air conditioner", "central air", "condenser unit"], "ac_unit"),
            (["pool pump", "pool filter"], "pool_equipment"),
            (["garage door opener", "garage opener"], "garage_opener"),
        ]

        let getFunction: (String) -> String? = { name in
            let lower = name.lowercased()
            return functionalTypes.first { type in type.keywords.contains { lower.contains($0) } }?.function
        }

        let newFunc = getFunction(newName)
        let existingFunc = getFunction(existingName)

        if let nf = newFunc, let ef = existingFunc, nf == ef {
            // Same functional type — check qualifiers (left/right = different units)
            let qualifiers = ["left", "right", "primary", "backup", "secondary",
                              "upstairs", "downstairs", "front", "rear", "master", "guest"]
            let newLower = newName.lowercased()
            let existingLower = existingName.lowercased()
            let newQ = qualifiers.first { newLower.contains($0) }
            let existQ = qualifiers.first { existingLower.contains($0) }
            if let nq = newQ, let eq = existQ, nq != eq { return false }
            return true
        }

        return false
    }

    // MARK: - Phase 50: Cadence helpers

    /// Resolve a friendly vendor display name for the cadence card. Pulls
    /// from the invoice vendor row if available; otherwise falls back to
    /// "your vendor". Mirrored by the Dashboard's CadenceSuggestionCard.
    private func vendorLabelForCadence() -> String? {
        if let name = result?.vendor?.companyName, !name.isEmpty {
            return name
        }
        return nil
    }
}

// MARK: - Phase 50: Cadence Coordinator

/// Phase 50: In-memory holdover so the Dashboard can pick up the most
/// recent cadence suggestion after `InvoiceProcessingViewModel`
/// publishes one. The view model tears down as soon as the
/// InvoiceReviewSheet dismisses, so we can't subscribe directly to its
/// `pendingCadenceSuggestion` from another screen — the coordinator
/// outlives the sheet and persists the suggestion in memory until the
/// dashboard either accepts or dismisses it.
@MainActor
final class InvoiceCadenceCoordinator: ObservableObject {
    static let shared = InvoiceCadenceCoordinator()
    private init() {}

    @Published var current: InvoiceCadenceSuggestion?

    func publish(_ suggestion: InvoiceCadenceSuggestion) {
        current = suggestion
    }

    func dismiss() {
        current = nil
    }

    /// Apply the suggestion to the linked system: write
    /// `service_interval_days` and recompute the next-due dates of any
    /// matching tasks. Returns true on success.
    func apply(_ suggestion: InvoiceCadenceSuggestion) async -> Bool {
        guard let systemId = suggestion.systemId else {
            // No system match — nothing to update at the system level.
            // We still consider this "applied" because the cadence may
            // have been added to a task-only context.
            current = nil
            return true
        }
        var update = HomeSystemUpdate()
        update.serviceIntervalDays = suggestion.intervalDays
        update.serviceIntervalSource = "vendor_invoice"
        do {
            _ = try await DatabaseService.shared.updateHomeSystem(id: systemId, update)
            // Reschedule next-due dates on existing maintenance tasks
            // attached to this system so the Dashboard reflects the new
            // cadence immediately.
            let tasks = (try? await DatabaseService.shared.fetchMaintenanceTasks(systemId: systemId)) ?? []
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let now = Date()
            for task in tasks {
                let last = task.lastCompletedDate.flatMap { formatter.date(from: $0) } ?? now
                if let nextDate = Calendar.current.date(byAdding: .day, value: suggestion.intervalDays, to: last) {
                    var taskUpdate = MaintenanceTaskUpdate()
                    taskUpdate.nextDueDate = formatter.string(from: nextDate)
                    _ = try? await DatabaseService.shared.updateMaintenanceTask(id: task.id, taskUpdate)
                }
            }
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)

            // Phase 51: Also create a standing appointment if one doesn't exist yet
            await createStandingAppointmentIfNeeded(for: suggestion, systemId: systemId)

            current = nil
            return true
        } catch {
            print("[InvoiceCadence] Apply failed: \(error)")
            return false
        }
    }

    // MARK: - Phase 51: Standing Appointment Creation

    /// After a cadence suggestion is accepted, create a standing appointment
    /// for the vendor + system pair if one doesn't already exist.
    private func createStandingAppointmentIfNeeded(for suggestion: InvoiceCadenceSuggestion, systemId: UUID) async {
        let db = DatabaseService.shared
        do {
            // Look up the system to get householdId and propertyId
            let allSystems = try await db.fetchHomeSystems()
            guard let system = allSystems.first(where: { $0.id == systemId }) else {
                print("[InvoiceCadence] System \(systemId) not found")
                return
            }

            // Check if a standing appointment already exists for this system
            let existingAppointments = try await db.fetchStandingAppointments(householdId: system.householdId)
            let alreadyExists = existingAppointments.contains { $0.systemId == systemId && $0.archivedAt == nil }
            guard !alreadyExists else {
                print("[InvoiceCadence] Standing appointment already exists for system \(systemId)")
                return
            }

            // Resolve contractor ID from the suggestion's vendor name
            var vendorId: UUID?
            if let vendorName = suggestion.vendorName {
                let contractors = try await db.fetchContractors()
                vendorId = contractors.first(where: {
                    $0.companyName.localizedCaseInsensitiveCompare(vendorName) == .orderedSame
                })?.id
            }

            let cadenceType = cadenceTypeFromDays(suggestion.intervalDays)
            let score: Double? = nil
            _ = try await StandingAppointmentViewModel.shared.createAppointment(
                householdId: system.householdId,
                propertyId: system.propertyId,
                vendorId: vendorId,
                systemId: systemId,
                cadenceType: cadenceType,
                cadenceIntervalDays: cadenceType == "custom_days" ? suggestion.intervalDays : nil,
                cadenceSource: "ai_inferred",
                confidenceScore: score,
                serviceDescription: suggestion.vendorName.map { "\(cadenceLabelFromDays(suggestion.intervalDays)) service by \($0)" }
            )
            print("[InvoiceCadence] Created standing appointment for system \(systemId)")
        } catch {
            print("[InvoiceCadence] Failed to create standing appointment: \(error)")
        }
    }

    private func cadenceTypeFromDays(_ days: Int) -> String {
        switch days {
        case 5...9: return "weekly"
        case 12...16: return "biweekly"
        case 19...23: return "triweekly"
        case 26...35: return "monthly"
        case 55...65: return "bimonthly"
        case 80...100: return "quarterly"
        case 170...195: return "semiannual"
        case 350...380: return "annual"
        default: return "custom_days"
        }
    }

    private func cadenceLabelFromDays(_ days: Int) -> String {
        switch cadenceTypeFromDays(days) {
        case "weekly": return "Weekly"
        case "biweekly": return "Biweekly"
        case "triweekly": return "Every 3 weeks"
        case "monthly": return "Monthly"
        case "bimonthly": return "Every 2 months"
        case "quarterly": return "Quarterly"
        case "semiannual": return "Semiannual"
        case "annual": return "Annual"
        default: return "Every \(days) days"
        }
    }

    // MARK: - Phase 51: Vendor Cadence Analysis (Soft Migration)

    /// Analyzes a vendor's completed task history to detect a recurring cadence pattern.
    /// Called when user opens vendor detail and no standing appointment exists.
    /// Returns a proposal if 3+ tasks show a consistent interval pattern.
    struct CadenceProposal {
        let intervalDays: Int
        let cadenceType: String
        let confidence: Double
        let taskCount: Int
    }

    func analyzeVendorCadence(vendorId: UUID, householdId: UUID) async -> CadenceProposal? {
        let db = DatabaseService.shared
        do {
            let allTasks = try await db.fetchAllMaintenanceTasks()
            let vendorTasks = allTasks.filter {
                $0.assignedContractorId == vendorId && $0.lastCompletedDate != nil
            }

            guard vendorTasks.count >= 3 else { return nil }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dates = vendorTasks
                .compactMap { $0.lastCompletedDate.flatMap { formatter.date(from: $0) } }
                .sorted()

            guard dates.count >= 3 else { return nil }

            // Compute intervals between consecutive completion dates
            var intervals: [Int] = []
            for i in 1..<dates.count {
                let days = Calendar.current.dateComponents([.day], from: dates[i-1], to: dates[i]).day ?? 0
                if days > 0 { intervals.append(days) }
            }

            guard intervals.count >= 2 else { return nil }

            // Cluster into cadence buckets
            let buckets: [(name: String, center: Int, tolerance: Int)] = [
                ("weekly", 7, 2), ("biweekly", 14, 3), ("monthly", 30, 5),
                ("bimonthly", 60, 8), ("quarterly", 91, 10), ("semiannual", 182, 15),
                ("annual", 365, 20)
            ]

            for bucket in buckets {
                let matching = intervals.filter { abs($0 - bucket.center) <= bucket.tolerance }
                let ratio = Double(matching.count) / Double(intervals.count)
                if ratio >= 0.8 {
                    let confidence = dates.count >= 5 ? min(0.85 + ratio * 0.1, 0.95) : min(0.7 + ratio * 0.15, 0.85)
                    return CadenceProposal(
                        intervalDays: bucket.center,
                        cadenceType: bucket.name,
                        confidence: confidence,
                        taskCount: dates.count
                    )
                }
            }

            return nil
        } catch {
            print("[InvoiceCadence] Vendor cadence analysis failed: \(error)")
            return nil
        }
    }
}

import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var needsOnboarding = false
    @Published var primaryProperty: PropertyRow?
    @Published var hasCheckedPrimaryProperty = false

    /// Phase 20b — when a brand-new user finishes the address-hook flow
    /// and AccountCreationStep auth, OnboardingViewModel.complete() stamps
    /// the freshly-created property here so DashboardView can auto-launch
    /// HouseQuizView on first appearance. Notification posts are too
    /// timing-sensitive (DashboardView may not be mounted yet when post
    /// fires); this state survives the OnboardingView → MainTabView swap.
    /// DashboardView clears it after handing it to its quiz cover.
    @Published var pendingQuizProperty: PropertyRow?

    // Force-update gate (Phase 13). When `requiresUpdate` is true, ContentView
    // renders ForceUpdateView before any other routing. The optional fields
    // hold the message and App Store URL for the blocking screen and the
    // dashboard banner respectively.
    @Published var requiresUpdate = false
    @Published var forceUpdateMessage: String?
    @Published var forceUpdateAppStoreURL: URL?
    @Published var optionalUpdateLatestVersion: String?
    @Published var optionalUpdateMessage: String?
    /// Session-only dismissal flag for the OptionalUpdateBanner. Reset on
    /// every relaunch on purpose so the banner reappears until the user
    /// updates.
    @Published var optionalUpdateDismissedThisSession = false

    let authService = AuthService()
    let sessionManager = SessionManager()

    /// Refresh the cached primary property. Called on auth resolution and
    /// after property mutations so the AddressConfirmationIntercept knows
    /// whether to show.
    func refreshPrimaryProperty() async {
        do {
            let properties = try await DatabaseService.shared.fetchProperties()
            primaryProperty = properties.first { ($0.street?.isEmpty ?? true) == false } ?? properties.first
        } catch {
            primaryProperty = nil
        }
        hasCheckedPrimaryProperty = true
    }

    /// Asks `app_config` whether the running build is at or above the
    /// minimum required version. Runs in parallel with auth resolution so
    /// even unauthenticated users get the force-update gate.
    func checkAppVersion() async {
        let result = await VersionCheckService.shared.check()
        switch result {
        case .forceUpdate(_, _, let message, let url):
            forceUpdateMessage = message
            forceUpdateAppStoreURL = url
            requiresUpdate = true
        case .optionalUpdate(let latest, _, let message):
            optionalUpdateLatestVersion = latest
            optionalUpdateMessage = message
        case .upToDate, .checkFailed:
            break
        }
    }

    func initialize() {
        authService.startListening()

        // Force-update gate runs in parallel with auth resolution. The DB
        // table is publicly readable so it doesn't depend on a session.
        Task { await checkAppVersion() }

        Task {
            // Wait for the initial session to be fully resolved before showing any UI.
            // This prevents the flash of unauthenticated screens while auth is still loading.
            for await resolved in authService.$hasResolvedInitialSession.values {
                if resolved { break }
            }

            // Now we definitively know the auth state
            isAuthenticated = authService.isAuthenticated
            needsOnboarding = authService.needsOnboarding
            isLoading = false

            if isAuthenticated {
                PushNotificationService.shared.ensureTokenStored()
                Task { await MaintenanceTemplates.migrateExistingTaskAssignments() }
                Task { await Self.migrateVehicleMaintenanceTasks() }
                Task { await Self.reconcileAllPropertiesOnce() }
                Task { await Self.backfillUtilityAccountSnapshotsOnce() }
                Task { await Self.refreshPropertyValuesOnce() }
                Task { await Self.purgeDroppedTemplatesOnce() }
                Task { await Self.migratePoolTasksToVendorOnce() }
                Task { await refreshPrimaryProperty() }
            } else {
                hasCheckedPrimaryProperty = true
            }

            // Continue listening for future auth state changes (sign out, sign in, etc.)
            for await isAuth in authService.$isAuthenticated.values {
                isAuthenticated = isAuth
                if isAuth {
                    PushNotificationService.shared.ensureTokenStored()
                    Task { await MaintenanceTemplates.migrateExistingTaskAssignments() }
                    Task { await Self.migrateVehicleMaintenanceTasks() }
                    Task { await Self.reconcileAllPropertiesOnce() }
                    Task { await Self.backfillUtilityAccountSnapshotsOnce() }
                    Task { await Self.refreshPropertyValuesOnce() }
                    Task { await Self.purgeDroppedTemplatesOnce() }
                    Task { await Self.migratePoolTasksToVendorOnce() }
                    Task { await refreshPrimaryProperty() }
                } else {
                    primaryProperty = nil
                    hasCheckedPrimaryProperty = false
                }
            }
        }

        Task {
            for await onboarding in authService.$needsOnboarding.values {
                needsOnboarding = onboarding
            }
        }
    }

    /// Phase 17b — one-time legacy cleanup. Properties created before the
    /// `MaintenanceTemplates.templates(for:activeSubtypes:)` filter fix
    /// shipped (Phase 14) carry stale generic tasks like "Descale tankless
    /// heater" that should never have been created. This pass walks every
    /// property the user has access to and runs the reconciler against each
    /// system, soft-deleting tasks that don't match the confirmed subtype
    /// (preserving anything the user has touched).
    ///
    /// Gated on a UserDefaults key so it only runs once per install. Fires
    /// from `initialize()` in a detached `Task` so it never blocks auth
    /// resolution or first-screen render.
    @MainActor
    static func reconcileAllPropertiesOnce() async {
        let key = "reconcileAllPropertiesV1Done"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            // Don't set the gate on failure — let the next launch retry.
            return
        }
        guard !properties.isEmpty else {
            // No properties to reconcile yet — gate so we don't keep retrying
            // every launch on a fresh install with no property added.
            UserDefaults.standard.set(true, forKey: key)
            return
        }
        for property in properties {
            let result = await MaintenanceTaskReconciler.reconcileAll(
                propertyId: property.id,
                householdId: property.householdId
            )
            if !result.isEmpty {
                print("[reconcileAllPropertiesV1] \(property.name): +\(result.added.count), -\(result.removed.count), kept \(result.preserved.count)")
            }
        }
        // Notify the rest of the app so any open task lists refresh.
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Phase 18g: One-time backfill that re-runs property-lookup against
    /// every property whose `currentEstimatedValue` is nil OR whose source
    /// is unknown (pre-Phase-16e rows). Picks up the new Claude web-search
    /// fallback layer so existing properties stop showing "Add estimated
    /// value" on the Investment Summary card. Gated by a UserDefaults
    /// flag so it only runs once per install. Detached Task so it never
    /// blocks first-screen render.
    @MainActor
    static func refreshPropertyValuesOnce() async {
        let key = "refreshPropertyValuesV1Done"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            return
        }
        guard !properties.isEmpty else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }
        var refreshed = 0
        for property in properties where property.currentEstimatedValue == nil {
            let parts = [property.street, property.city, property.state, property.zipCode]
                .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            guard !parts.isEmpty else { continue }
            let address = parts.joined(separator: ", ")
            do {
                let lookupData = try await HavenSupabase.propertyLookup(address: address)
                struct LookupResponse: Decodable {
                    let success: Bool
                    let property: PropertyLookupResult?
                }
                let response = try JSONDecoder().decode(LookupResponse.self, from: lookupData)
                guard response.success, let lookup = response.property,
                      let value = lookup.estimatedValue else { continue }
                var update = PropertyUpdate()
                update.currentEstimatedValue = value
                update.estimatedValueSource = lookup.estimatedValueSource
                update.estimatedValueConfidence = lookup.estimatedValueConfidence
                update.estimatedValueReasoning = lookup.estimatedValueReasoning
                _ = try? await db.updateProperty(id: property.id, update)
                refreshed += 1
            } catch {
                // Skip silently — don't gate the rest of the backfill on
                // a single lookup failure.
            }
        }
        if refreshed > 0 {
            print("[refreshPropertyValuesV1] refreshed \(refreshed) propert\(refreshed == 1 ? "y" : "ies")")
            NotificationCenter.default.post(name: .propertyChanged, object: nil)
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Phase 18e: One-time backfill that walks every utility_account row on
    /// every property and fuzzy-matches its provider_name against the
    /// utility_providers catalog. Patches logo_url, brand_color, and
    /// provider_id where missing so legacy rows from before the snapshot
    /// columns existed pick up brand identity on next launch. Gated by a
    /// UserDefaults flag so it only runs once per install. Always runs in a
    /// detached Task so it never blocks first-screen render.
    @MainActor
    static func backfillUtilityAccountSnapshotsOnce() async {
        let key = "utilityAccountSnapshotBackfillV1Done"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            // Don't set the gate on failure — let the next launch retry.
            return
        }
        var totalPatched = 0
        for property in properties {
            if let count = try? await db.backfillUtilityAccountSnapshots(propertyId: property.id) {
                totalPatched += count
            }
        }
        if totalPatched > 0 {
            print("[utilityAccountSnapshotBackfillV1] patched \(totalPatched) utility_account row\(totalPatched == 1 ? "" : "s")")
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    /// One-time: create maintenance_tasks for vehicles that have maintenance_schedule JSONB but no stored tasks
    static func migrateVehicleMaintenanceTasks() async {
        let key = "hasRunVehicleTaskMigrationV1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let db = DatabaseService.shared
        do {
            let vehicles = try await db.fetchVehicles()
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            for vehicle in vehicles {
                guard let schedule = vehicle.maintenanceSchedule, !schedule.isEmpty else { continue }
                let existingTasks = (try? await db.fetchVehicleMaintenanceTasks(vehicleId: vehicle.id)) ?? []
                guard existingTasks.isEmpty else { continue }

                for interval in schedule {
                    guard interval.intervalMiles != nil || interval.intervalMonths != nil else { continue }
                    let monthsOut = interval.intervalMonths ?? 12
                    let nextDue = Calendar.current.date(byAdding: .month, value: monthsOut, to: Date()) ?? Date()
                    _ = try? await db.createMaintenanceTask(MaintenanceTaskInsert(
                        vehicleId: vehicle.id,
                        householdId: vehicle.householdId,
                        title: interval.type.replacingOccurrences(of: "_", with: " ").capitalized,
                        frequency: interval.intervalMonths.map { "Every \($0) months" } ?? "As needed",
                        nextDueDate: df.string(from: nextDue),
                        description: interval.description,
                        estimatedCost: interval.estimatedCost,
                        priority: "medium",
                        templateId: interval.type
                    ))
                }
            }
            UserDefaults.standard.set(true, forKey: key)
        } catch {}
    }

    /// Build 87: drops the 7 chore-tracker maintenance templates shipped in
    /// Build 86 and earlier. Soft-archives any existing maintenance_tasks
    /// rows whose templateId matches one of the dropped template keys.
    /// Runs ONCE per device, gated by UserDefaults so the migration is
    /// idempotent. Uses the same `archiveMaintenanceTask` soft-delete path
    /// the reconciler itself uses so Alfred, service records, and audit
    /// logs stay intact.
    ///
    /// Without this, existing test users (Tom's wife, friend) who don't
    /// re-enter the quiz on Build 87 would keep the dropped chore-tracker
    /// tasks on their dashboard forever. The reconciler's normal orphan
    /// handling preserves user-touched tasks, which would leave these as
    /// visible duplicates for anyone who engaged with them — this targeted
    /// pass bypasses the preservation logic just for these 7 keys.
    ///
    /// Runs in a detached Task from `initialize()` so it never blocks first-
    /// screen render. Uses the property-iteration pattern (matching
    /// `reconcileAllPropertiesOnce` and `backfillUtilityAccountSnapshotsOnce`)
    /// instead of adding a new household-scoped DB helper.
    @MainActor
    static func purgeDroppedTemplatesOnce() async {
        let key = "purgedDroppedTemplatesV87Done"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            // Don't set the gate on failure — retry next launch.
            return
        }
        guard !properties.isEmpty else {
            // Fresh install with no properties yet — set gate so we don't
            // keep retrying every launch.
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        let droppedTemplateIds: Set<String> = [
            "HVAC:Clean air vents and returns",
            "Plumbing:Clean faucet aerators",
            "Windows:Clean window tracks and weep holes",
            "Appliance:Clean dishwasher filter and spray arms",
            "Appliance:Clean washing machine",
            "Appliance:Clean range hood filter",
            "Appliance:Check and clean garbage disposal",
        ]

        var purgedCount = 0
        for property in properties {
            let tasks: [MaintenanceTaskDBRow]
            do {
                tasks = try await db.fetchMaintenanceTasks(propertyId: property.id)
            } catch {
                continue
            }
            for task in tasks {
                guard let templateId = task.templateId,
                      droppedTemplateIds.contains(templateId) else { continue }
                do {
                    try await db.archiveMaintenanceTask(
                        id: task.id,
                        reason: "build_87_chore_tracker_drop"
                    )
                    purgedCount += 1
                } catch {
                    // Swallow individual failures — a single failed archive
                    // shouldn't block the rest of the cleanup.
                }
            }
        }
        if purgedCount > 0 {
            print("[purgeDroppedTemplatesV87] archived \(purgedCount) dropped-template task\(purgedCount == 1 ? "" : "s")")
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Build 87: flips existing Pool/Spa maintenance tasks from
    /// .personal/.either to .vendor for existing test users. New users get
    /// `.vendor` automatically via the updated template definitions in
    /// Build 87 Edit 3, but existing users' tasks were created when the
    /// templates were `.either`, so the reconciler's templateKey-based
    /// dedup leaves them in their old state on next launch.
    ///
    /// Targets specifically the two pool templates that were flipped in
    /// Build 87 Edit 3: "Pool/Spa:Clean pool filter" and
    /// "Pool/Spa:Clean salt cell". Other Pool/Spa tasks (Test water
    /// chemistry, Professional pool opening, etc.) were already `.vendor`
    /// and are skipped. Tasks already tagged `vendor` (via the bidirectional
    /// toggle or a previous flip pass) are also skipped.
    ///
    /// When a Pool/Spa contractor is on file for the household, also links
    /// it to the flipped task and reframes title + description via the
    /// same Phase 19l voice used by `MaintenanceViewModel.convertToVendorManaged`
    /// and `HouseQuizAnswerMapper.flipCategoryTasksToVendor`. When no pool
    /// contractor is on file, the task is still flipped to `vendor` but
    /// left unlinked, which mirrors the reconciler's "Find a contractor
    /// for: ..." behavior.
    @MainActor
    static func migratePoolTasksToVendorOnce() async {
        let key = "migratedPoolTasksToVendorV87Done"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            return
        }
        guard !properties.isEmpty else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        let targetTemplateIds: Set<String> = [
            "Pool/Spa:Clean pool filter",
            "Pool/Spa:Clean salt cell",
        ]

        // Fetch contractors once — `fetchContractors()` is RLS-scoped to
        // the current session's household so it covers every property the
        // user can access in a single call.
        let contractors = (try? await db.fetchContractors()) ?? []
        let poolContractor = contractors.first { contractor in
            if let cat = contractor.category,
               cat.caseInsensitiveCompare("Pool/Spa") == .orderedSame {
                return true
            }
            if let specs = contractor.specialties,
               specs.contains(where: { $0.caseInsensitiveCompare("Pool/Spa") == .orderedSame }) {
                return true
            }
            return false
        }

        var migratedCount = 0
        for property in properties {
            let tasks: [MaintenanceTaskDBRow]
            do {
                tasks = try await db.fetchMaintenanceTasks(propertyId: property.id)
            } catch {
                continue
            }
            for task in tasks {
                guard let templateId = task.templateId,
                      targetTemplateIds.contains(templateId),
                      task.assignmentType?.lowercased() != "vendor" else { continue }

                var update = MaintenanceTaskUpdate()
                update.assignmentType = "vendor"
                update.needsVendor = false

                if let contractor = poolContractor {
                    // Reframe via the Phase 19l voice. Source the original
                    // wording from the template catalog rather than the
                    // live row so we don't double-reframe if the row was
                    // previously touched.
                    let template = MaintenanceTemplates.template(forKey: templateId)
                    let originalTitle = template?.title ?? task.title
                    let originalDescription = template?.description ?? task.description ?? ""
                    update.title = "Schedule \(contractor.companyName): \(originalTitle.lowercased())"
                    if originalDescription.isEmpty {
                        update.description = "Your job: book the appointment and be home for it. \(contractor.companyName) will handle the work."
                    } else {
                        update.description = "Your job: book the appointment and be home for it. \(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(originalDescription)"
                    }
                    update.assignedContractorId = contractor.id
                }

                do {
                    _ = try await db.updateMaintenanceTask(id: task.id, update)
                    migratedCount += 1
                } catch {
                    // Swallow individual failures.
                }
            }
        }
        if migratedCount > 0 {
            print("[migratePoolTasksToVendorV87] flipped \(migratedCount) pool task\(migratedCount == 1 ? "" : "s") to vendor")
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }
        UserDefaults.standard.set(true, forKey: key)
    }
}

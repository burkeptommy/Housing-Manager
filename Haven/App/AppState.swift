import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var needsOnboarding = false
    @Published var primaryProperty: PropertyRow?
    @Published var hasCheckedPrimaryProperty = false
    @Published var activeExperience: AppExperience = .homeowner
    @Published var fieldDashboard: HavenFieldDashboard?

    /// Phase 20b — when a brand-new user finishes the address-hook flow
    /// and AccountCreationStep auth, OnboardingViewModel.complete() stamps
    /// the freshly-created property here so DashboardView can auto-launch
    /// HouseQuizView on first appearance. Notification posts are too
    /// timing-sensitive (DashboardView may not be mounted yet when post
    /// fires); this state survives the OnboardingView → MainTabView swap.
    /// DashboardView clears it after handing it to its quiz cover.
    @Published var pendingQuizProperty: PropertyRow?

    /// Phase 95 (gap #55) — cached `family_members.member_type`
    /// for the auth user. Loaded by `refreshCurrentMemberType()`
    /// on auth resolution. Drives UI gating: home managers and
    /// staff don't see destructive actions like Delete Property,
    /// Delete Family Member, or Remove Household Access (RLS
    /// would block them server-side, but hiding the affordances
    /// up-front is friendlier than letting them tap and fail).
    /// Nil = not loaded yet OR user isn't linked to a family_member
    /// row, in which case we treat them as the homeowner (full
    /// rights) so a misconfigured pre-PR-38 install doesn't lose
    /// access to its own controls.
    @Published var currentMemberType: String?

    /// Phase 95 (gap #55) — convenience getter. True when the
    /// signed-in user's member_type is `home_manager` or `staff`.
    /// Defaults to false when nil so legacy / pre-link installs
    /// keep full UI affordances.
    var isStaffUser: Bool {
        let type = currentMemberType ?? "family"
        return type == "home_manager" || type == "staff"
    }

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

    #if DEBUG && targetEnvironment(simulator)
    private var didAttemptE2ELoginBootstrap = false
    #endif

    private var isRunningFieldApp: Bool {
        (Bundle.main.bundleIdentifier ?? "").lowercased() == "com.havenhome.field"
    }

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

    /// Phase 95 (gap #55) — resolves the signed-in user's
    /// `family_members.member_type` and caches it on AppState.
    /// Driven from `resolveExperienceContext` so it runs once per
    /// auth resolution. Failures leave `currentMemberType` nil
    /// (which `isStaffUser` treats as homeowner = full UI).
    func refreshCurrentMemberType() async {
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            // Pull staff first; staff are filtered out of
            // `fetchFamilyMembers` server-side so a homeowner-side
            // call wouldn't see them. `fetchHouseholdStaff` exists
            // exactly for this.
            let staff = (try? await DatabaseService.shared.fetchHouseholdStaff()) ?? []
            if let staffMatch = staff.first(where: { $0.linkedUserId == user.id }) {
                currentMemberType = staffMatch.memberType
                return
            }
            let family = (try? await DatabaseService.shared.fetchFamilyMembers()) ?? []
            currentMemberType = family.first(where: { $0.linkedUserId == user.id })?.memberType
        } catch {
            currentMemberType = nil
        }
    }

    private func resolveExperienceContext() async {
        if !isAuthenticated {
            activeExperience = .homeowner
            fieldDashboard = nil
            primaryProperty = nil
            hasCheckedPrimaryProperty = false
            return
        }

        let currentUser = try? await DatabaseService.shared.fetchCurrentUser()
        let hasHousehold = currentUser?.householdId != nil
        let shouldPrioritizeFieldWorkspace = isRunningFieldApp

        do {
            let dashboard = try await HavenFieldService.shared.fetchDashboard()
            fieldDashboard = dashboard
            if !dashboard.needsWorkspace && (shouldPrioritizeFieldWorkspace || !hasHousehold) {
                HavenFieldCache.saveDashboard(dashboard)
                activeExperience = .field
                needsOnboarding = false
                primaryProperty = nil
                hasCheckedPrimaryProperty = true
                return
            }

            if shouldPrioritizeFieldWorkspace && dashboard.needsWorkspace {
                needsOnboarding = false
                primaryProperty = nil
                hasCheckedPrimaryProperty = true
                return
            }
        } catch {
            if let cached = HavenFieldCache.loadDashboard(), shouldPrioritizeFieldWorkspace || !hasHousehold {
                fieldDashboard = cached
                activeExperience = .field
                needsOnboarding = false
                primaryProperty = nil
                hasCheckedPrimaryProperty = true
                return
            }
        }

        activeExperience = .homeowner
        fieldDashboard = nil

        // Phase 95 (gap #55) — cache the user's member_type now
        // that auth + household state are resolved. Drives UI
        // gating across destructive controls. Failures leave
        // `currentMemberType` nil so the gating treats them as
        // homeowner with full rights.
        await refreshCurrentMemberType()
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
        Task { await AdminCatalogService.shared.refreshPublishedCatalog() }

        Task {
            #if DEBUG && targetEnvironment(simulator)
            let environment = ProcessInfo.processInfo.environment
            let arguments = ProcessInfo.processInfo.arguments
            let shouldAttemptE2ELoginBootstrap = !didAttemptE2ELoginBootstrap &&
                (environment["CHEZ_E2E_LOGIN"] == "1" || arguments.contains("--chez-e2e-login"))
            #else
            let shouldAttemptE2ELoginBootstrap = false
            #endif

            // Wait for the initial session to be fully resolved before showing any UI.
            // This prevents the flash of unauthenticated screens while auth is still loading.
            if !shouldAttemptE2ELoginBootstrap && !authService.hasResolvedInitialSession {
                for await resolved in authService.$hasResolvedInitialSession.values {
                    if resolved { break }
                }
            }

            #if DEBUG && targetEnvironment(simulator)
            if shouldAttemptE2ELoginBootstrap {
                didAttemptE2ELoginBootstrap = true
                let email = environment["CHEZ_E2E_EMAIL"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let password = environment["CHEZ_E2E_PASSWORD"] ?? ""
                if email.isEmpty || password.isEmpty {
                    print("[E2E] CHEZ_E2E_LOGIN requested but email/password were missing.")
                } else {
                    do {
                        try await authService.signIn(email: email, password: password)
                        print("[E2E] Signed in fixture user \(email).")
                    } catch {
                        print("[E2E] Fixture sign-in failed for \(email): \(error)")
                    }
                }
            }
            #endif

            // Now we definitively know the auth state
            isAuthenticated = authService.isAuthenticated
            needsOnboarding = authService.needsOnboarding

            if isAuthenticated {
                PushNotificationService.shared.ensureTokenStored()
                RealtimeService.shared.subscribe()
                Task { await AdminCatalogService.shared.refreshPublishedCatalog() }
                await resolveExperienceContext()
                if activeExperience == .homeowner && !(isRunningFieldApp && fieldDashboard?.needsWorkspace == true) {
                    Task { await MaintenanceTemplates.migrateExistingTaskAssignments() }
                    Task { await MaintenanceTemplates.migrateTaskTitlesToActionFirst() }
                    Task { await MaintenanceTemplates.cleanupTaskTitlesP54A() }
                    Task { await Self.migrateVehicleMaintenanceTasks() }
                    Task { await Self.reconcileAllPropertiesOnce() }
                    Task { await Self.backfillUtilityAccountSnapshotsOnce() }
                    Task { await Self.refreshPropertyValuesOnce() }
                    Task { await Self.purgeDroppedTemplatesOnce() }
                    Task { await Self.migratePoolTasksToVendorOnce() }
                    Task { await Self.removeLeakCheckTasksOnceIfNeeded() }
                    Task { await Self.migrateHotTubSystemsOnceIfNeeded() }
                    Task { await Self.migrateBundleConsolidationOnceIfNeeded() }
                    // Phase 67D Phase A: rewrite legacy quiz answer IDs
                    // so users with mid-quiz JSONB resume into the new
                    // combined-question shape instead of seeing the new
                    // questions as unanswered.
                    Task { await Self.migrateHouseQuizP67DOnceIfNeeded() }
                    Task {
                        // Phase 54A: order matters — reseed first so bundle backfill
                        // lands on seasonally-distributed anchor dates; missing-system
                        // backfill last so the reconciler has somewhere to hang templates.
                        await MaintenanceTaskReconciler.reseedSeasonalTasksOnceIfNeeded()
                        await MaintenanceTaskReconciler.backfillBundlesOnceIfNeeded()
                        await Self.backfillMissingSystemsOnceIfNeeded()
                        // Phase 54E.3: mirror existing waste haulers +
                        // service utilities to the contractors table.
                        await Self.backfillUtilityContractorMirrorOnceIfNeeded()
                        // Phase 60.6: canonicalize `contractors.category`
                        // strings so vendor-coverage matching resolves
                        // legacy rows (e.g. "Plumbing & Heating", "Fire
                        // Protection" from the old chimney_sweep chip).
                        await Self.canonicalizeContractorCategoriesOnceIfNeeded()
                        // Phase 55.2: repair air-filter tasks that
                        // drifted to vendor under the 54A assignment
                        // leak. Runs AFTER the other backfills so any
                        // reconciler-created row lands first.
                        await MaintenanceTaskReconciler.fixAirFilterAssignmentP55()
                        // Phase 58: archive tasks whose templates were
                        // killed or demoted during the task library purge.
                        // Runs LAST so earlier backfills have landed before
                        // the orphan pass evaluates what to prune.
                        await Self.archivePhase58OrphanedTasksOnceIfNeeded()
                        // Phase 67: materialize bundle child rows for
                        // existing Handyman:spring / Handyman:fall parents.
                        // Runs AFTER the orphan pass so new children land
                        // on a clean library. Idempotent.
                        await MaintenanceTaskReconciler.materializeHandymanBundleChildrenOnceIfNeeded()
                        // Phase 66: Day1TaskCurator backfill for existing
                        // TestFlight users. Runs the four-way router (vendor
                        // / pending-vendor / handyman / This Season) for
                        // every property whose curator flag is unset, so
                        // existing installs get the new five-section layout
                        // populated on first launch without re-running the
                        // quiz. Idempotent per-property via the standard
                        // curator UserDefaults gate.
                        await Self.runDay1CuratorForExistingPropertiesOnceIfNeeded()

                        // Phase 67E/F: handyman single-rail migrations.
                        // These converge existing TestFlight households
                        // onto the new "punch items only" handyman model
                        // shipped with Phase 67E/F. Order matters — run
                        // tier-conversion BEFORE visit-archive so the
                        // converted children land before the parents
                        // are gone, and AFTER the Day1Curator pass so
                        // its handyman re-parenting has already
                        // executed (we conservatively skip user-touched
                        // rows in both migrations).
                        await Self.migrateHandymanTierTasksToPunchItemsOnceIfNeeded()
                        await Self.migrateHandymanVisitsToRemindersOnceIfNeeded()

                        // Round 4 (May 2026): one-time backfill that
                        // archives the auto-seeded twin of any duplicate
                        // routine pair created by Q15b before the race
                        // condition fix. Burke household had 3 dupe
                        // pairs (Blue Fox / Orkin / ADT); other quiz
                        // households built before the fix will too.
                        await Self.archiveDuplicateRoutinesOnceIfNeeded()

                        // Round 5 (May 2026): one-time backfill that
                        // links contractors to matching home_systems
                        // rows via `preferred_contractor_id`. The Q15b
                        // mapper used to create the contractor + a
                        // vendor-linked routine but never set the
                        // system's preferred_contractor_id, so the
                        // Systems Needing Details sheet showed
                        // "Landscaping needs a service vendor" even
                        // after the user captured Blue Fox.
                        await Self.linkExistingContractorsToSystemsOnceIfNeeded()

                        // Chez v1: legacy service-row backfill. Archives
                        // any home_systems row whose category is a
                        // service (Pet Waste, Cleaning, Trash, Snow
                        // Removal, Mosquito & Tick, Handyman) and
                        // ensures matching routines exist. Must run
                        // BEFORE the install-date pre-fill so we don't
                        // waste cycles stamping dates onto rows that
                        // are about to be archived.
                        await Self.runServiceSystemArchiveOnceIfNeeded()

                        // Phase 1.5: backfill the universal smoke + CO
                        // detector check routine for pre-existing
                        // households whose quiz completed before the
                        // rule was added. Idempotent via UserDefaults
                        // gate + RoutineSeeder.ensureSystemlessRoutines
                        // dedup.
                        await Self.ensureSmokeCoRoutineOnceIfNeeded()

                        // Chez v1: pre-fill install_date for systems
                        // whose category correlates with year_built
                        // (roof, foundation, structural shells). The
                        // gamified coverage flow then asks the user to
                        // confirm or correct these. Idempotent via
                        // `installDateAttomPrefilled` flag on the row +
                        // a UserDefaults gate inside the helper.
                        await Self.runInstallDatePrefillOnceIfNeeded()
                    }
                    Task { await Self.archivePreQuizChoreTasksOnce() }
                    Task { await Self.backfillUniversalSystemsOnce() }
                    Task { await Self.ensurePropertyValuesAreFresh() }
                    await refreshPrimaryProperty()
                } else {
                    hasCheckedPrimaryProperty = true
                }
            } else {
                hasCheckedPrimaryProperty = true
                activeExperience = .homeowner
                fieldDashboard = nil
            }
            isLoading = false

            // Continue listening for future auth state changes (sign out, sign in, etc.)
            // Phase 60.1 trust fix (2026-04-20): read `needsOnboarding`
            // atomically alongside `isAuthenticated` so ContentView never
            // sees the transient state `isAuthenticated=true,
            // needsOnboarding=false` on a fresh signup. The previous
            // split-observer setup let `$isAuthenticated.values` fire
            // first, route briefly through MainTabView/DashboardView
            // (which kicked off merge-households + property fetches),
            // then re-route to OnboardingView when the separate
            // `$needsOnboarding.values` loop caught up — cancelling all
            // the in-flight requests and tearing down the onboarding
            // `.task` before `runComplete()` could create the property.
            for await isAuth in authService.$isAuthenticated.values {
                isAuthenticated = isAuth
                needsOnboarding = authService.needsOnboarding
                if isAuth {
                    isLoading = true
                    PushNotificationService.shared.ensureTokenStored()
                    RealtimeService.shared.subscribe()
                    Task { await AdminCatalogService.shared.refreshPublishedCatalog() }
                    await resolveExperienceContext()
                    if activeExperience == .homeowner && !(isRunningFieldApp && fieldDashboard?.needsWorkspace == true) {
                        Task { await MaintenanceTemplates.migrateExistingTaskAssignments() }
                        Task { await MaintenanceTemplates.cleanupTaskTitlesP54A() }
                        Task { await Self.migrateVehicleMaintenanceTasks() }
                        Task { await Self.reconcileAllPropertiesOnce() }
                        Task { await Self.backfillUtilityAccountSnapshotsOnce() }
                        Task { await Self.refreshPropertyValuesOnce() }
                        Task { await Self.purgeDroppedTemplatesOnce() }
                        Task { await Self.migratePoolTasksToVendorOnce() }
                        Task { await Self.removeLeakCheckTasksOnceIfNeeded() }
                        Task { await Self.migrateHotTubSystemsOnceIfNeeded() }
                        Task { await Self.migrateBundleConsolidationOnceIfNeeded() }
                        Task { await Self.migrateHouseQuizP67DOnceIfNeeded() }
                        Task {
                            await MaintenanceTaskReconciler.reseedSeasonalTasksOnceIfNeeded()
                            await MaintenanceTaskReconciler.backfillBundlesOnceIfNeeded()
                            await Self.backfillMissingSystemsOnceIfNeeded()
                            // Phase 58 orphan archive pass.
                            await Self.archivePhase58OrphanedTasksOnceIfNeeded()
                        }
                        Task { await Self.archivePreQuizChoreTasksOnce() }
                        Task { await Self.backfillUniversalSystemsOnce() }
                        Task { await Self.ensurePropertyValuesAreFresh() }
                        await refreshPrimaryProperty()
                    } else {
                        primaryProperty = nil
                        hasCheckedPrimaryProperty = true
                    }
                    isLoading = false
                } else {
                    RealtimeService.shared.unsubscribe()
                    primaryProperty = nil
                    hasCheckedPrimaryProperty = false
                    activeExperience = .homeowner
                    fieldDashboard = nil
                    HavenFieldCache.clearDashboard()
                    isLoading = false
                }
            }
        }

        Task {
            for await onboarding in authService.$needsOnboarding.values {
                if activeExperience != .field {
                    needsOnboarding = onboarding
            }
        }
    }

    func applyFieldDashboard(_ dashboard: HavenFieldDashboard) {
        fieldDashboard = dashboard
        if dashboard.needsWorkspace {
            activeExperience = .homeowner
            needsOnboarding = false
            primaryProperty = nil
            hasCheckedPrimaryProperty = true
            return
        }

        HavenFieldCache.saveDashboard(dashboard)
        activeExperience = .field
        needsOnboarding = false
        primaryProperty = nil
        hasCheckedPrimaryProperty = true
    }
}

    /// Phase 54A: One-time backfill that walks every property and creates
    /// the `home_systems` rows the Vendor Coverage registry knows about
    /// but the quiz didn't directly seed for existing TestFlight users —
    /// Handyman, Mosquito & Tick, Pet Waste (if has_pets),
    /// Chimney (if fireplace system exists), Snow Removal (if Northeast
    /// state). Matches `HouseQuizAnswerMapper.ensureAutoCreatedSystems`
    /// so first-launch quiz users and existing users end up with the
    /// same system footprint.
    ///
    /// Runs the reconciler against each property afterward so the new
    /// Phase 67D Phase A: One-shot JSONB migration that walks every
    /// property's `house_quiz_state.answers` and rewrites the legacy
    /// pre-67D keys into the new combined-question shape. Without this,
    /// resumed quizzes would treat the new `q3_heating_system` /
    /// `q11_lawn` / `q12_pool` / `q18_trash` / `q25_garage_ev` /
    /// `q26_insurance` / `q28_household` questions as unanswered (the
    /// IDs no longer match) and re-prompt the user — losing the value
    /// meter accretion they'd already earned.
    ///
    /// Transformations applied per property (all idempotent — re-runs
    /// on already-migrated state are no-ops):
    ///   • `q3_heating_fuel` + `q3b_hvac_type` → `q3_heating_system`
    ///   • `q11b_lawn_type` → folded into `q11_lawn.payload["lawnType"]`
    ///   • `q11c_landscaping_months` → dropped (months attribute alive)
    ///   • `q12b_pool_chemistry` → folded into `q12_pool.payload["chemistry"]`
    ///   • `q12c_pool_months` → dropped
    ///   • `q14b_irrigation_months` → dropped
    ///   • `q18b_trash_day` → `q18_trash.selectedIds`
    ///   • `q23_vehicle_count` → dropped
    ///   • `q25b_ev_charger` → folded into `q25_garage_ev.payload["evCharger"]`
    ///   • `q26_auto_insurance` + `q27_homeowners_insurance` → `q26_insurance` with payload
    ///   • `q28b_pets` → folded into `q28_household.payload["petsAnswerId"]`
    ///
    /// Gated on `hasMigratedHouseQuizP67D_v1` UserDefaults key.
    @MainActor
    static func migrateHouseQuizP67DOnceIfNeeded() async {
        let key = "hasMigratedHouseQuizP67D_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            print("[AppState] Phase 67D migration: fetchProperties failed: \(error)")
            return
        }
        guard !properties.isEmpty else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        for property in properties {
            guard var state = property.houseQuizState else { continue }
            var changed = false

            // 1. Q3 + Q3b → q3_heating_system
            if state.answers["q3_heating_system"] == nil,
               let fuelAnswer = state.answers["q3_heating_fuel"] {
                let fuel = fuelAnswer.answerId
                let hvac = state.answers["q3b_hvac_type"]?.answerId
                let comboId = HouseQuizFuelDerivation.combineHeatingSystem(
                    fuel: fuel,
                    hvacType: hvac
                )
                state.answers["q3_heating_system"] = HouseQuizAnswer(
                    answerId: comboId,
                    answeredAt: fuelAnswer.answeredAt
                )
                state.answers.removeValue(forKey: "q3_heating_fuel")
                state.answers.removeValue(forKey: "q3b_hvac_type")
                changed = true
            } else if state.answers["q3_heating_fuel"] != nil
                       || state.answers["q3b_hvac_type"] != nil {
                // Defensive cleanup — if q3_heating_system is set but
                // legacy keys also exist, drop the stragglers.
                state.answers.removeValue(forKey: "q3_heating_fuel")
                state.answers.removeValue(forKey: "q3b_hvac_type")
                changed = true
            }

            // 2. Q11 + Q11b + Q11c → q11_lawn (payload-extended)
            if let q11 = state.answers["q11_lawn"], q11.payload?["lawnType"] == nil {
                if let lawnType = state.answers["q11b_lawn_type"]?.answerId {
                    var payload = q11.payload ?? [:]
                    payload["lawnType"] = lawnType
                    var updated = q11
                    updated.payload = payload
                    state.answers["q11_lawn"] = updated
                    changed = true
                }
            }
            if state.answers["q11b_lawn_type"] != nil {
                state.answers.removeValue(forKey: "q11b_lawn_type")
                changed = true
            }
            if state.answers["q11c_landscaping_months"] != nil {
                state.answers.removeValue(forKey: "q11c_landscaping_months")
                changed = true
            }

            // 3. Q12 + Q12b + Q12c → q12_pool (payload-extended)
            if let q12 = state.answers["q12_pool"], q12.payload?["chemistry"] == nil {
                if let chemistry = state.answers["q12b_pool_chemistry"]?.answerId {
                    var payload = q12.payload ?? [:]
                    payload["chemistry"] = chemistry
                    var updated = q12
                    updated.payload = payload
                    state.answers["q12_pool"] = updated
                    changed = true
                }
            }
            if state.answers["q12b_pool_chemistry"] != nil {
                state.answers.removeValue(forKey: "q12b_pool_chemistry")
                changed = true
            }
            if state.answers["q12c_pool_months"] != nil {
                state.answers.removeValue(forKey: "q12c_pool_months")
                changed = true
            }

            // 4. Drop Q14b irrigation months
            if state.answers["q14b_irrigation_months"] != nil {
                state.answers.removeValue(forKey: "q14b_irrigation_months")
                changed = true
            }

            // 5. Q18 + Q18b → q18_trash (selectedIds-extended)
            if let q18 = state.answers["q18_trash"], q18.selectedIds == nil {
                if let days = state.answers["q18b_trash_day"]?.selectedIds, !days.isEmpty {
                    var updated = q18
                    updated.selectedIds = days
                    state.answers["q18_trash"] = updated
                    changed = true
                }
            }
            if state.answers["q18b_trash_day"] != nil {
                state.answers.removeValue(forKey: "q18b_trash_day")
                changed = true
            }

            // 6. Drop Q23 vehicle count
            if state.answers["q23_vehicle_count"] != nil {
                state.answers.removeValue(forKey: "q23_vehicle_count")
                changed = true
            }

            // 7. Q25 + Q25b → q25_garage_ev (payload-extended)
            if let q25 = state.answers["q25_garage_ev"], q25.payload?["evCharger"] == nil {
                if let ev = state.answers["q25b_ev_charger"]?.answerId {
                    var payload = q25.payload ?? [:]
                    payload["evCharger"] = ev
                    var updated = q25
                    updated.payload = payload
                    state.answers["q25_garage_ev"] = updated
                    changed = true
                }
            }
            if state.answers["q25b_ev_charger"] != nil {
                state.answers.removeValue(forKey: "q25b_ev_charger")
                changed = true
            }

            // 8. Q26 + Q27 → q26_insurance (payload-extended)
            if state.answers["q26_insurance"] == nil {
                let auto = state.answers["q26_auto_insurance"]
                let home = state.answers["q27_homeowners_insurance"]
                if auto != nil || home != nil {
                    var payload: [String: String] = [:]
                    if let autoId = auto?.selectedProviderId {
                        payload["autoProviderId"] = autoId.uuidString
                    }
                    if let homeId = home?.selectedProviderId {
                        payload["homeProviderId"] = homeId.uuidString
                    }
                    var customEntries: [String] = []
                    if let autoName = auto?.customText, auto?.selectedProviderId == nil, !autoName.isEmpty {
                        customEntries.append("auto:\(autoName)")
                    }
                    if let homeName = home?.customText, home?.selectedProviderId == nil, !homeName.isEmpty {
                        customEntries.append("home:\(homeName)")
                    }
                    state.answers["q26_insurance"] = HouseQuizAnswer(
                        answerId: "selected",
                        customEntries: customEntries.isEmpty ? nil : customEntries,
                        payload: payload.isEmpty ? nil : payload,
                        answeredAt: (auto?.answeredAt ?? home?.answeredAt) ?? Date()
                    )
                    changed = true
                }
            }
            if state.answers["q26_auto_insurance"] != nil {
                state.answers.removeValue(forKey: "q26_auto_insurance")
                changed = true
            }
            if state.answers["q27_homeowners_insurance"] != nil {
                state.answers.removeValue(forKey: "q27_homeowners_insurance")
                changed = true
            }

            // 9. Q28b → folded into q28_household payload
            if let q28 = state.answers["q28_household"], q28.payload?["petsAnswerId"] == nil {
                if let pets = state.answers["q28b_pets"]?.answerId {
                    var payload = q28.payload ?? [:]
                    payload["petsAnswerId"] = pets
                    var updated = q28
                    updated.payload = payload
                    state.answers["q28_household"] = updated
                    changed = true
                }
            }
            if state.answers["q28b_pets"] != nil {
                state.answers.removeValue(forKey: "q28b_pets")
                changed = true
            }

            // Also strip from skipped/savedForLater so the deprecated
            // IDs don't leave dangling references.
            let droppedIds: Set<String> = [
                "q3_heating_fuel", "q3b_hvac_type",
                "q11b_lawn_type", "q11c_landscaping_months",
                "q12b_pool_chemistry", "q12c_pool_months",
                "q14b_irrigation_months",
                "q18b_trash_day",
                "q23_vehicle_count",
                "q25b_ev_charger",
                "q26_auto_insurance", "q27_homeowners_insurance",
                "q28b_pets",
            ]
            let prevSavedCount = state.savedForLater.count
            state.savedForLater.removeAll { droppedIds.contains($0) }
            if state.savedForLater.count != prevSavedCount {
                changed = true
            }
            let prevSkippedCount = state.skipped.count
            state.skipped.removeAll { droppedIds.contains($0) }
            if state.skipped.count != prevSkippedCount {
                changed = true
            }

            guard changed else { continue }
            do {
                var update = PropertyUpdate()
                update.houseQuizState = state
                _ = try await db.updateProperty(id: property.id, update)
            } catch {
                print("[AppState] Phase 67D migration: updateProperty failed for \(property.id): \(error)")
            }
        }

        UserDefaults.standard.set(true, forKey: key)
    }

    /// rows pick up their applicable templates. Gated on a UserDefaults
    /// key so it only runs once per install.
    @MainActor
    static func backfillMissingSystemsOnceIfNeeded() async {
        // Phase 54E.3: bumped to _v2 so TestFlight users whose v1 pass
        // already completed re-run the auto-create rules and pick up
        // the new "Trash & Recycling" universal system. The underlying
        // ensureAutoCreatedSystems is idempotent (dedups by category)
        // so re-running on fully-set-up users is a no-op.
        let key = "hasRunMissingSystemBackfillP54A_v2"
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
        for property in properties {
            await HouseQuizAnswerMapper.ensureAutoCreatedSystems(
                propertyId: property.id,
                householdId: property.householdId
            )
            _ = await MaintenanceTaskReconciler.reconcileAll(
                propertyId: property.id,
                householdId: property.householdId
            )
        }
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Phase 66: One-time Day1TaskCurator backfill for existing
    /// TestFlight users. Walks every property that doesn't have a
    /// curator flag yet and runs the four-way router (vendor routine /
    /// pending-vendor routine / handyman routine / This Season) so the
    /// new Maintenance hub renders correctly on first launch. Existing
    /// properties that already ran the curator inside the quiz-completion
    /// flow skip this pass via the per-property UserDefaults gate.
    ///
    /// Idempotent at both the household-wide and per-property level:
    /// `Day1TaskCurator.runIfNeeded` checks its own gate before doing
    /// any work, and the outer flag here prevents re-walking the
    /// property list unnecessarily.
    @MainActor
    static func runDay1CuratorForExistingPropertiesOnceIfNeeded() async {
        let key = "hasRunDay1CuratorBackfillP66_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            print("[AppState] Day1Curator backfill: fetchProperties failed: \(error)")
            return
        }
        guard !properties.isEmpty else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        for property in properties {
            // Skip properties where the quiz isn't complete yet. Running
            // the curator on an in-progress quiz would route the
            // partially-seeded tasks incorrectly; the quiz-completion
            // flow calls the curator itself when the user finishes.
            guard property.houseQuizState?.completedAt != nil else { continue }
            _ = await Day1TaskCurator.runIfNeeded(
                propertyId: property.id,
                householdId: property.householdId
            )
        }

        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(name: .routineChanged, object: nil)
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Phase 67E/F: one-time migration that converts existing handyman-
    /// tier `maintenance_tasks` rows (DIY-capable, ≤60 min, no
    /// safetyFloor, no bundleId) into `handyman_punch_items` rows so
    /// existing TestFlight households converge onto the single-rail
    /// model the reconciler now seeds against (commit B3).
    ///
    /// Conservative: skips any row with `lastCompletedDate` (preserves
    /// completion history) or `scheduledDate` (user picked a time —
    /// don't yank it). Source task is soft-archived with reason
    /// `migrated_to_handyman_punch`; the new punch item carries
    /// `source = "migrated_from_task"` and `source_task_id` /
    /// `source_template_key` for traceability.
    @MainActor
    static func migrateHandymanTierTasksToPunchItemsOnceIfNeeded() async {
        let key = "hasMigratedHandymanTierToPunchItems_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let db = DatabaseService.shared
        let tasks: [MaintenanceTaskDBRow]
        do {
            tasks = try await db.fetchMaintenanceTasks()
        } catch {
            print("[AppState] HandymanTier migration: fetch failed: \(error)")
            return
        }

        var migrated = 0
        for task in tasks {
            // Preserve any user touchpoints. lastCompletedDate carries
            // service history; scheduledDate means the homeowner picked
            // a date and we shouldn't surprise them.
            if task.lastCompletedDate != nil { continue }
            if task.scheduledDate != nil { continue }
            // Need a templateId to look up the in-app template metadata.
            guard let templateKey = task.templateId,
                  let template = MaintenanceTemplates.template(forKey: templateKey)
            else { continue }

            let isHandymanTier =
                !template.safetyFloor &&
                template.bundleId == nil &&
                (template.routingOverride == .diyDefault || template.routingOverride == .diyCapable) &&
                (template.diyEffortMinutes ?? 0) <= 60
            guard isHandymanTier else { continue }

            var insert = HandymanPunchItemInsert(
                householdId: task.householdId,
                propertyId: task.propertyId,
                title: template.title
            )
            insert.description = template.description
            insert.notes = template.notes
            insert.estimatedMinutes = template.diyEffortMinutes
            insert.estimatedCostRange = template.estimatedCostRange
            insert.source = "migrated_from_task"
            insert.sourceTemplateKey = template.templateKey
            insert.sourceTaskId = task.id

            if (try? await db.createHandymanPunchItem(insert)) != nil {
                try? await db.archiveMaintenanceTask(id: task.id, reason: "migrated_to_handyman_punch")
                migrated += 1
            }
        }

        UserDefaults.standard.set(true, forKey: key)
        if migrated > 0 {
            print("[AppState] HandymanTier migration: converted \(migrated) tasks to punch items")
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            NotificationCenter.default.post(name: .handymanPunchListChanged, object: nil)
        }
    }

    /// Phase 67E/F: one-time migration that archives the legacy
    /// "Spring handyman visit" / "Fall handyman visit" parent
    /// `maintenance_tasks` rows for existing TestFlight households.
    /// Those parent templates were deleted in commit B1; their seasonal
    /// coordination role moved to push reminders + the dashboard's
    /// `HandymanSeasonalReminderCard`.
    ///
    /// Conservative: skips rows with `lastCompletedDate` so completion
    /// history is preserved. Archive reason
    /// `migrated_to_seasonal_reminder` distinguishes from the tier
    /// conversion above.
    @MainActor
    static func migrateHandymanVisitsToRemindersOnceIfNeeded() async {
        let key = "hasMigratedHandymanVisitsToReminders_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let db = DatabaseService.shared
        let tasks: [MaintenanceTaskDBRow]
        do {
            tasks = try await db.fetchMaintenanceTasks()
        } catch {
            print("[AppState] HandymanVisits migration: fetch failed: \(error)")
            return
        }

        // Match what `MaintenanceTemplate.templateKey` emits for the
        // deleted parents — `"\(systemCategory):\(title)"`.
        let visitTemplateKeys: Set<String> = [
            "Handyman:Spring handyman visit",
            "Handyman:Fall handyman visit",
        ]

        var archived = 0
        for task in tasks {
            guard let tid = task.templateId, visitTemplateKeys.contains(tid) else { continue }
            if task.lastCompletedDate != nil { continue }
            try? await db.archiveMaintenanceTask(id: task.id, reason: "migrated_to_seasonal_reminder")
            archived += 1
        }

        UserDefaults.standard.set(true, forKey: key)
        if archived > 0 {
            print("[AppState] HandymanVisits migration: archived \(archived) seasonal visit tasks")
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }
    }

    /// Round 4 (May 2026): one-time backfill that archives the
    /// `cadence_source: "auto_seeded"` twin of duplicate routine pairs
    /// created by the pre-fix Q15b race condition.
    ///
    /// Background: until commit AAA the House Quiz's Q15b answer mapper
    /// fired BOTH `RoutineSeeder.seedIfNeeded` (via
    /// `DatabaseService.createContractor`'s fire-and-forget Task) AND
    /// `HouseQuizAnswerMapper.ensureVendorRoutineForCategory` for each
    /// captured contractor. The two paths raced on their dedup
    /// fetch+insert and BOTH succeeded, producing two active routines
    /// for the same vendor (Burke household had Blue Fox / Orkin / ADT
    /// dupe pairs — same vendor_id, same routine_kind, both
    /// `archived_at: NULL`). The new code passes `skipRoutineSeed: true`
    /// from the quiz so only the explicit path runs — but existing
    /// installs already have the dupes on file.
    ///
    /// This pass groups active routines by `(household_id, vendor_id,
    /// routine_kind)`, and for any group with >1 active row, archives
    /// the one with `cadenceSource == "auto_seeded"` (the older seed)
    /// and keeps the `"quiz"` row (the user's explicit Q15b answer).
    /// Conservative: if BOTH have the same source, neither is "obviously
    /// the duplicate" so we leave both alone — the homeowner can
    /// manually resolve. Idempotent via UserDefaults gate.
    @MainActor
    static func archiveDuplicateRoutinesOnceIfNeeded() async {
        let key = "hasArchivedDuplicateRoutinesRound4_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let db = DatabaseService.shared
        // Need household scope. The fetchRoutines(householdId:) signature
        // requires an explicit household id; pull it from the current user.
        guard let user = try? await db.fetchCurrentUser(),
              let householdId = user.householdId else { return }

        let routines: [RoutineRow]
        do {
            routines = try await db.fetchRoutines(householdId: householdId)
        } catch {
            print("[AppState] DupeRoutines migration: fetch failed: \(error)")
            return
        }

        // Group active routines by (vendor_id, routine_kind). Skip rows
        // without a vendor — handyman-recurring etc. are governed by
        // their own uniqueness rules (the partial unique index in
        // Phase 66's schema).
        struct DupeKey: Hashable {
            let vendorId: UUID
            let routineKind: String
        }
        var groups: [DupeKey: [RoutineRow]] = [:]
        for routine in routines {
            guard routine.archivedAt == nil,
                  let vendorId = routine.vendorId else { continue }
            let dkey = DupeKey(vendorId: vendorId, routineKind: routine.routineKind)
            groups[dkey, default: []].append(routine)
        }

        var archived = 0
        for (_, members) in groups where members.count > 1 {
            // Keep the `quiz` source row; archive the `auto_seeded` one.
            // If the set doesn't look exactly like one of each, leave it
            // alone — we can't safely pick which to drop.
            let autoSeeded = members.filter { $0.cadenceSource == "auto_seeded" }
            let quiz = members.filter { $0.cadenceSource == "quiz" }
            guard !autoSeeded.isEmpty, !quiz.isEmpty else { continue }

            for toArchive in autoSeeded {
                do {
                    try await db.archiveRoutine(id: toArchive.id)
                    archived += 1
                } catch {
                    print("[AppState] DupeRoutines migration: archive failed for \(toArchive.id): \(error)")
                }
            }
        }

        UserDefaults.standard.set(true, forKey: key)
        if archived > 0 {
            print("[AppState] DupeRoutines migration: archived \(archived) auto-seeded duplicates")
            NotificationCenter.default.post(name: .routineChanged, object: nil)
        }
    }

    /// Round 5 (May 2026, friend feedback): one-time backfill that
    /// stamps `home_systems.preferred_contractor_id` with the matching
    /// household contractor when one exists.
    ///
    /// Background: until Round 5's Q15b fix the captured contractor
    /// was linked to its `routines.vendor_id` but never to the
    /// matching home_systems row's `preferred_contractor_id`. Result:
    /// the Systems Needing Details sheet showed "Landscaping —
    /// needs Service vendor" even though Blue Fox was already
    /// captured and surfaced as the routine's vendor.
    ///
    /// Strategy: for every system without `preferred_contractor_id`,
    /// find every contractor in the household whose canonical category
    /// matches the system's canonical category. If EXACTLY one match,
    /// link it. If multiple matches, skip — we can't safely pick
    /// which contractor to designate as preferred. Skips child
    /// systems (parent owns coverage). Idempotent via UserDefaults
    /// gate.
    @MainActor
    static func linkExistingContractorsToSystemsOnceIfNeeded() async {
        let key = "hasLinkedExistingContractorsToSystemsRound5_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let db = DatabaseService.shared
        let systems: [HomeSystemRow]
        let contractors: [ContractorRow]
        do {
            systems = try await db.fetchHomeSystems()
            contractors = try await db.fetchContractors()
        } catch {
            print("[AppState] SystemContractorLink migration: fetch failed: \(error)")
            return
        }

        // Bucket contractors by canonical category (skip rows without one).
        var byCategory: [String: [ContractorRow]] = [:]
        for contractor in contractors {
            guard let canonical = SystemCategoryRegistry.canonical(category: contractor.category) else { continue }
            byCategory[canonical, default: []].append(contractor)
        }

        var linked = 0
        for system in systems {
            guard system.parentSystemId == nil else { continue }
            guard system.preferredContractorId == nil else { continue }
            guard let systemCanonical = SystemCategoryRegistry.canonical(category: system.category) else { continue }
            guard let matches = byCategory[systemCanonical], matches.count == 1 else { continue }
            let contractor = matches[0]

            var update = HomeSystemUpdate()
            update.preferredContractorId = contractor.id
            do {
                _ = try await db.updateHomeSystem(id: system.id, update)
                linked += 1
            } catch {
                print("[AppState] SystemContractorLink migration: link failed for \(system.id): \(error)")
            }
        }

        UserDefaults.standard.set(true, forKey: key)
        if linked > 0 {
            print("[AppState] SystemContractorLink migration: linked \(linked) systems to their household contractors")
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
        }
    }

    /// Chez v1: legacy backfill that retires service-shaped
    /// `home_systems` rows (Pet Waste, Cleaning Service, Trash &
    /// Recycling, Snow Removal, Mosquito & Tick, Handyman) so those
    /// categories live ONLY as routines going forward. Walks every
    /// existing system, archives any row whose lowercased category
    /// is in `SystemGroup.serviceCategories`, and ensures matching
    /// routines exist via `RoutineSeeder.ensureSystemlessRoutines`.
    ///
    /// Idempotent: gated on `UserDefaults` AND the helper itself
    /// skips rows whose category check fails. Once flipped, never
    /// re-runs.
    static func runServiceSystemArchiveOnceIfNeeded() async {
        let key = "hasArchivedServiceSystemsP1_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            print("[AppState] runServiceSystemArchive: fetchProperties failed: \(error)")
            return
        }
        guard !properties.isEmpty else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        var archivedCount = 0
        for property in properties {
            // fetchHomeSystems already filters archived rows via the
            // server-side filter we added — but at first-run all the
            // legacy service rows are still active, so they'll show.
            let systems = (try? await db.fetchHomeSystems(propertyId: property.id)) ?? []
            for system in systems
                where SystemGroup.isServiceCategory(system.category) {
                try? await db.archiveHomeSystem(id: system.id)
                archivedCount += 1
            }

            // Ensure routines exist for the now-archived service
            // categories. The seeder is idempotent so households that
            // already have these routines (e.g. via Day1Curator or
            // contractor seeding) get no-ops.
            // FlexibleValue.bool(true) renders as "Yes" via
            // stringValue while quiz writes commonly persist as
            // "true" — accept both so the snow/pet gate stays robust.
            let petsRaw = property.attributes?["has_pets"]?.stringValue.lowercased() ?? ""
            let hasPets = (petsRaw == "true" || petsRaw == "yes")
            let isSnow = isSnowState(property.state)
            await RoutineSeeder.shared.ensureSystemlessRoutines(
                propertyId: property.id,
                householdId: property.householdId,
                hasPets: hasPets,
                isSnowState: isSnow
            )
        }

        if archivedCount > 0 {
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
        }
        NotificationCenter.default.post(name: .routineChanged, object: nil)
        UserDefaults.standard.set(true, forKey: key)
        print("[AppState] runServiceSystemArchive: archived=\(archivedCount)")
    }

    /// Snow-state lookup for backfill — matches the snow-state set used
    /// in `HouseQuizAnswerMapper.ensureAutoCreatedSystems`. Kept inline
    /// here because the mapper's helper is fileprivate and we don't
    /// want to widen its visibility for a single backfill use.
    private static func isSnowState(_ state: String?) -> Bool {
        guard let s = state?.uppercased(), !s.isEmpty else { return false }
        return [
            "MA", "CT", "RI", "NY", "NH", "VT", "ME", "NJ", "PA",
            "OH", "MI", "WI", "MN", "IA", "IL", "IN",
            "CO", "UT", "WY", "ID", "MT", "ND", "SD", "NE", "AK",
        ].contains(s)
    }

    /// Phase 1.5: One-time backfill that ensures a semi-annual smoke +
    /// CO detector check routine exists for every household whose quiz
    /// has already completed. New-quiz households pick it up naturally
    /// via `HouseQuizAnswerMapper.ensureAutoCreatedSystems` calling
    /// `RoutineSeeder.ensureSystemlessRoutines`; this helper covers
    /// pre-Phase-1.5 households that completed the quiz before the
    /// rule existed. Mid-quiz users (no completion timestamp) are
    /// skipped so the next reminder doesn't appear out of nowhere
    /// while they're still finishing setup.
    ///
    /// Gated on `hasEnsuredSmokeCoRoutine_v1` UserDefaults flag so the
    /// fetchProperties pass fires at most once per install. The seeder
    /// itself is idempotent (skips if a routine for the kind already
    /// exists), so even with the gate bypassed we never double-create.
    static func ensureSmokeCoRoutineOnceIfNeeded() async {
        let key = "hasEnsuredSmokeCoRoutine_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            print("[AppState] smokeCo backfill fetchProperties failed: \(error)")
            return
        }
        guard !properties.isEmpty else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        for property in properties {
            let quizState = property.houseQuizState
            let quizDone = (quizState?.completedAt != nil)
                || (quizState?.walkthroughCompletedAt != nil)
                || (quizState?.intakeCompletedAt != nil)
            guard quizDone else { continue }

            let petsRaw = property.attributes?["has_pets"]?.stringValue.lowercased() ?? ""
            let hasPets = (petsRaw == "true" || petsRaw == "yes")
            let isSnow = isSnowState(property.state)

            await RoutineSeeder.shared.ensureSystemlessRoutines(
                propertyId: property.id,
                householdId: property.householdId,
                hasPets: hasPets,
                isSnowState: isSnow
            )
        }

        NotificationCenter.default.post(name: .routineChanged, object: nil)
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Chez v1: walks every existing property and pre-fills install
    /// dates on systems whose category correlates with the home's age
    /// (roof, foundation, structural shells, original windows, etc.)
    /// using the property's ATTOM-sourced `year_built`. Stamps source
    /// = 'estimated' and a `attom_prefilled = true` flag so the
    /// gamified coverage flow surfaces them as "estimated from public
    /// records — confirm or correct".
    ///
    /// Idempotent two ways: (1) global `UserDefaults` gate so the
    /// fetchProperties pass only fires once per install; (2) the row
    /// helper skips systems where `installDate` is already set OR
    /// `installDateAttomPrefilled` is already true, so even if the
    /// gate were bypassed we never double-stamp.
    static func runInstallDatePrefillOnceIfNeeded() async {
        let key = "hasRunInstallDatePrefill_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            print("[AppState] InstallDatePrefill backfill: fetchProperties failed: \(error)")
            return
        }
        guard !properties.isEmpty else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        var totalUpdated = 0
        for property in properties {
            guard let yearBuilt = property.yearBuilt, yearBuilt > 0 else { continue }
            let count = await InstallDatePrefiller.prefill(
                propertyId: property.id,
                yearBuilt: yearBuilt,
                db: db
            )
            totalUpdated += count
        }

        if totalUpdated > 0 {
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Phase 54E.3: One-time backfill that walks every existing
    /// utility_account with a service-type provider (landscaping, pool,
    /// pest control, trash, recycling, compost, yard waste, etc.) and
    /// creates a matching `contractors` row if one doesn't exist yet.
    /// Fixes the gap where users who added Redding Sanitation before
    /// the 54E.3 mirror shipped couldn't link it from the cadence
    /// vendor picker.
    @MainActor
    static func backfillUtilityContractorMirrorOnceIfNeeded() async {
        // Build 90 fix: bumped to v2 because v1 ran on every install
        // BEFORE the `contractors_source_check` constraint bug was
        // discovered. v1 silently failed every mirror insert (the
        // CHECK only allows manual/quiz/find_vendor and the mirror was
        // sending "utility_mirror"), then flipped the gate to true so
        // it never re-ran. v2 forces a fresh pass on next launch with
        // the fixed source value, healing every existing user's
        // captured-but-unmirrored vendors without re-running the quiz.
        let key = "hasRunUtilityContractorMirrorBackfill_v2"
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

        // Collect every utility account across properties, then resolve
        // each one to a catalog row (when possible) for richer
        // brand-identity snapshotting.
        var accounts: [UtilityAccountRow] = []
        for property in properties {
            if let rows = try? await db.fetchUtilityAccounts(propertyId: property.id) {
                accounts.append(contentsOf: rows)
            }
        }

        for account in accounts {
            let providerType = account.providerType
            guard UtilityContractorMirror.serviceCategory(forProviderType: providerType) != nil else {
                continue
            }
            var catalogProvider: UtilityProviderRow? = nil
            if let providerId = account.providerId {
                catalogProvider = try? await db.fetchUtilityProvider(id: providerId)
            }
            _ = try? await UtilityContractorMirror.mirrorIfNeeded(
                name: account.providerName,
                providerType: providerType,
                catalogProvider: catalogProvider,
                householdId: account.householdId,
                db: db
            )
        }

        UserDefaults.standard.set(true, forKey: key)
    }

    /// Phase 60.6: canonicalize every `contractors.category` value in the
    /// household so the vendor-coverage matcher picks them up. Earlier
    /// save paths (pre-60.6 `VendorReviewForm`, raw manual inserts, quiz
    /// `householdContractorCategoryFor` when it still mapped
    /// `chimney_sweep → "Fire Protection"`) stored non-canonical strings
    /// that the exact-string match in `SystemCategoryRegistry.vendorCoverageItems`
    /// silently skipped. The 60.6 match reads canonical on both sides, so
    /// this backfill is technically optional — but it stops the
    /// `specialties` pill rendering "Fire Protection" when the user meant
    /// a chimney sweep, and it keeps the category column human-readable.
    ///
    /// Walks every contractor row, computes `canonical(category:)`, and
    /// rewrites the column only when it changed. Specialties are
    /// similarly canonicalized if any entry wasn't already canonical.
    /// Gated on a UserDefaults key so it only runs once per install.
    @MainActor
    static func canonicalizeContractorCategoriesOnceIfNeeded() async {
        let key = "hasRunContractorCategoryCanonicalizationP60_6_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let db = DatabaseService.shared
        let contractors: [ContractorRow]
        do {
            contractors = try await db.fetchContractors()
        } catch {
            return
        }
        guard !contractors.isEmpty else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        for contractor in contractors {
            let oldCategory = contractor.category
            let newCategory = SystemCategoryRegistry.canonical(category: oldCategory)

            let oldSpecialties = contractor.specialties ?? []
            // Only canonicalize specialties that round-trip through the
            // registry. Estate-type labels ("Attorney", "Financial Advisor
            // / CPA", etc.) are not registry keys and must pass through
            // untouched so the Contacts filter can still find them.
            let newSpecialties = oldSpecialties.map { s -> String in
                if let canonical = SystemCategoryRegistry.canonical(category: s),
                   SystemCategoryRegistry.byCategoryKey[canonical] != nil {
                    return canonical
                }
                return s
            }

            let categoryChanged = (oldCategory ?? "") != (newCategory ?? "")
            let specialtiesChanged = oldSpecialties != newSpecialties
            guard categoryChanged || specialtiesChanged else { continue }

            var update = ContractorUpdate()
            if categoryChanged { update.category = newCategory }
            if specialtiesChanged { update.specialties = newSpecialties }
            _ = try? await db.updateContractor(id: contractor.id, update)
        }

        UserDefaults.standard.set(true, forKey: key)
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
                // Phase 56.2: stash the ATTOM range alongside the midpoint
                // so the card can render an honest band without synthesizing
                // ±5%. When the lookup didn't supply a range, leave both nil.
                update.currentEstimatedValueLow = lookup.estimatedValueLow
                update.currentEstimatedValueHigh = lookup.estimatedValueHigh
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

    // MARK: - Build 89: Auto-Refresh Property Values

    /// Runs on every login. Refreshes any property whose estimated value is
    /// nil or whose last lookup is older than 30 days. Stores the lookup
    /// timestamp in `properties.attributes["last_value_lookup_at"]` so no
    /// migration is needed. Replaces the need for the manual "Refresh from
    /// public records" button as the primary way values get populated.
    @MainActor
    static func ensurePropertyValuesAreFresh() async {
        let db = DatabaseService.shared
        let properties: [PropertyRow]
        do {
            properties = try await db.fetchProperties()
        } catch {
            return
        }
        guard !properties.isEmpty else { return }

        let staleThreshold: TimeInterval = 30 * 24 * 60 * 60 // 30 days
        let isoFormatter = ISO8601DateFormatter()

        var refreshed = 0
        for property in properties {
            // Check if refresh is needed
            let needsRefresh: Bool
            if property.currentEstimatedValue == nil {
                needsRefresh = true
            } else if let lastLookupValue = property.attributes?["last_value_lookup_at"],
                      case .string(let dateString) = lastLookupValue,
                      let lastDate = isoFormatter.date(from: dateString) {
                needsRefresh = Date().timeIntervalSince(lastDate) > staleThreshold
            } else {
                // Has a value but no timestamp — treat as stale so we
                // stamp it on the next successful refresh.
                needsRefresh = true
            }
            guard needsRefresh else { continue }

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
                guard response.success, let lookup = response.property else { continue }

                // Walk the ATTOM fallback ladder
                let estimatedValue: Double? = {
                    if let canonical = lookup.estimatedValue { return canonical }
                    if let low = lookup.estimatedValueLow,
                       let high = lookup.estimatedValueHigh {
                        return (low + high) / 2
                    }
                    if let high = lookup.estimatedValueHigh { return high }
                    if let low = lookup.estimatedValueLow { return low }
                    if let assessed = lookup.taxAssessment?.assessedValue { return assessed }
                    return nil
                }()

                var update = PropertyUpdate()
                update.currentEstimatedValue = estimatedValue
                // Phase 56.2: preserve the AVM range so the property card
                // can show it instead of a synthetic ±5% band.
                update.currentEstimatedValueLow = lookup.estimatedValueLow
                update.currentEstimatedValueHigh = lookup.estimatedValueHigh
                update.estimatedValueSource = lookup.estimatedValueSource
                    ?? (estimatedValue != nil ? "computed" : nil)
                update.estimatedValueConfidence = lookup.estimatedValueConfidence
                update.estimatedValueReasoning = lookup.estimatedValueReasoning
                if let salePrice = lookup.lastSalePrice {
                    update.purchasePrice = salePrice
                }

                // Stamp the lookup timestamp in attributes
                var attrs = property.attributes ?? [:]
                attrs["last_value_lookup_at"] = .string(isoFormatter.string(from: Date()))
                update.attributes = attrs

                _ = try? await db.updateProperty(id: property.id, update)
                refreshed += 1
            } catch {
                // Skip silently — don't block the rest on one failure.
            }
        }
        if refreshed > 0 {
            print("[ensurePropertyValuesAreFresh] refreshed \(refreshed) propert\(refreshed == 1 ? "y" : "ies")")
            NotificationCenter.default.post(name: .propertyChanged, object: nil)
        }
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
                    update.title = originalTitle
                    if originalDescription.isEmpty {
                        update.description = "\(contractor.companyName) will handle the work."
                    } else {
                        update.description = "\(contractor.companyName) will handle the work.\n\nWhat they'll do:\n\(originalDescription)"
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

    /// Build 87 (Edit 2): one-time legacy cleanup for the Pool vs Hot Tub
    /// split. Build 86 created a single "Pool/Spa" parent system for every
    /// Q12 answer, including hot-tub-only households, with three pool-
    /// specific children (Pool Pump, Pool Filter, Pool Heater) that don't
    /// belong on a hot tub. This pass converges those legacy rows to the
    /// new model:
    ///   - Find properties whose `pool_type` attribute is "hot_tub"
    ///   - Delete the three Pool Pump/Filter/Heater children
    ///   - Archive any incomplete pool-template tasks linked to the parent
    ///     or the deleted children (the user-touched preservation rule
    ///     still wins — completed/edited tasks stay)
    ///   - Rename the parent to "Hot Tub" and set its subtype to "hot_tub"
    ///   - Re-run the reconciler so the four hot tub templates land
    ///
    /// `pool_type == "both"` is intentionally out of scope for V1 — splitting
    /// an existing single row into two new systems with overlapping history
    /// is error-prone and the case is rare. Those users can manually fix
    /// from EditSystemSheet if it ever applies.
    ///
    /// Mirrors the existing one-time migration pattern: detached Task from
    /// `initialize()`, gated on a UserDefaults key, swallows individual row
    /// failures so a single bad property doesn't block the whole pass.
    @MainActor
    static func migrateHotTubSystemsOnceIfNeeded() async {
        let key = "hasMigratedHotTubSystems_v1"
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

        // Pool template titles that should be archived from a hot-tub-only
        // household. Includes the three core templates whose `templateKey`
        // looked like "Pool/Spa:Clean pool filter" and similar — these are
        // the ones the build 86 mapper auto-created for every Q12 answer.
        let droppedPoolTemplateTitles: Set<String> = [
            "Test and balance water chemistry",
            "Clean pool filter",
            "Professional pool opening",
            "Professional pool closing/winterization",
            "Inspect pool equipment",
            "Clean salt cell",
            "Shock pool",
        ]

        var migratedCount = 0
        for property in properties {
            // Only touch hot-tub-only households. "both" is out of scope
            // for V1 (see method docs).
            let poolType = property.attributes?["pool_type"]?.stringValue
            guard poolType == "hot_tub" else { continue }

            // Find the legacy "Pool/Spa" parent system. The build 86 mapper
            // always named it "Pool/Spa", but be defensive and match by
            // category-only since later edits might have renamed it.
            let allSystems: [HomeSystemRow]
            do {
                allSystems = try await db.fetchHomeSystems(propertyId: property.id, topLevelOnly: false)
            } catch {
                continue
            }
            guard let legacyParent = allSystems.first(where: {
                $0.category.lowercased() == "pool/spa"
                && $0.parentSystemId == nil
                && $0.subtype != "hot_tub"  // already migrated, skip
            }) else { continue }

            // Delete the three pool children. The legacy build 86 mapper
            // always created Pool Pump, Pool Filter, Pool Heater — anything
            // else under the parent is user-added and should stay.
            let childNames: Set<String> = ["pool pump", "pool filter", "pool heater"]
            let legacyChildren = allSystems.filter {
                $0.parentSystemId == legacyParent.id
                && childNames.contains($0.name.lowercased())
            }
            for child in legacyChildren {
                try? await db.deleteHomeSystem(id: child.id)
            }

            // Archive any incomplete pool-template tasks linked to the
            // parent OR to the deleted children. Skip completed tasks so
            // the history log stays intact, and skip user-touched tasks
            // (assigned, has notes) so we never stomp on real edits.
            let allTasks: [MaintenanceTaskDBRow]
            do {
                allTasks = try await db.fetchMaintenanceTasks(propertyId: property.id)
            } catch {
                continue
            }
            let deletedChildIds = Set(legacyChildren.map { $0.id })
            for task in allTasks {
                let linkedToParent = task.systemId == legacyParent.id
                let linkedToChild = task.systemId.map { deletedChildIds.contains($0) } ?? false
                guard linkedToParent || linkedToChild else { continue }

                // Only archive pool templates, not anything user-added.
                let isPoolTemplate = droppedPoolTemplateTitles.contains(task.title)
                guard isPoolTemplate else { continue }

                // Preserve user work.
                if task.lastCompletedDate != nil { continue }
                if task.assignedToUserId != nil { continue }
                if let notes = task.notes, !notes.isEmpty { continue }

                try? await db.archiveMaintenanceTask(
                    id: task.id,
                    reason: "build_87_hot_tub_migration"
                )
            }

            // Rename the parent to "Hot Tub" and set the new subtype so
            // the reconciler picks up the hot tub templates on its next
            // pass.
            var update = HomeSystemUpdate()
            update.name = "Hot Tub"
            update.subtype = "hot_tub"
            _ = try? await db.updateHomeSystem(id: legacyParent.id, update)

            // Re-run the reconciler so the four hot tub templates land.
            // The reconciler dedups by templateKey, so any pre-existing
            // hot tub templates from a partial migration won't double up.
            _ = await MaintenanceTaskReconciler.reconcile(
                propertyId: property.id,
                householdId: property.householdId,
                systemId: legacyParent.id,
                systemCategory: "Pool/Spa",
                confirmedSubtype: "hot_tub"
            )
            migratedCount += 1
        }
        if migratedCount > 0 {
            print("[migrateHotTubSystemsV1] migrated \(migratedCount) hot-tub property\(migratedCount == 1 ? "" : "ies")")
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Phase 58 cleanup pass. Users on TestFlight during the Phase 58
    /// ship still have tasks from templates that were killed or demoted
    /// (Check generator oil level, Verify generator test cycle, Check
    /// drain field for wet spots, Inspect washing machine supply hoses,
    /// Crawl Space:quarterly bundle, etc.). The original Phase 58 note
    /// said "don't worry about existing users, we're testing" — but that
    /// left the TestFlight account littered with fossilized rows because
    /// `reconcileAllPropertiesOnce` is already UserDefaults-gated as
    /// `reconcileAllPropertiesV1Done = true`, so it never re-runs.
    ///
    /// This helper walks every property once and re-runs
    /// `MaintenanceTaskReconciler.reconcileAll` in `.full` mode. The
    /// reconciler archives any task whose `template_id` no longer maps
    /// to a current template — and preserves user-touched tasks
    /// (completed, assigned, notes, scheduled_date) untouched, so
    /// history isn't destroyed. Safe to re-run thanks to the gate.
    @MainActor
    static func archivePhase58OrphanedTasksOnceIfNeeded() async {
        // v2 — the v1 run relied on the pre-fix reconciler which wouldn't
        // archive fossils whose titles were no longer in the template
        // library (the "is this template-managed?" guard used title
        // matching, not template_id). After bumping the reconciler to
        // trust is_template_based + template_id first, this needs to
        // re-run on every already-gated install.
        let key = "hasRunPhase58OrphanPass_v2"
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

        var totalRemoved = 0
        var totalAdded = 0
        for property in properties {
            let result = await MaintenanceTaskReconciler.reconcileAll(
                propertyId: property.id,
                householdId: property.householdId
            )
            totalRemoved += result.removed.count
            totalAdded += result.added.count
        }

        if totalRemoved > 0 || totalAdded > 0 {
            print("[Phase58OrphanPass] Archived \(totalRemoved), added \(totalAdded) across \(properties.count) properties")
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Phase 52: Archives orphaned individual tasks that were consolidated
    /// into bundled service visits (Generator:annual, Garage Door:annual,
    /// Septic System:triennial, Pool/Spa:opening, Pool/Spa:closing).
    /// Runs once per install. Marks orphans as completed with a note
    /// explaining the consolidation so service history is preserved.
    @MainActor
    static func migrateBundleConsolidationOnceIfNeeded() async {
        let key = "hasMigratedBundleConsolidation_v1"
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

        // Map of bundleId -> individual templateKeys that were folded in
        let bundleOrphans: [String: Set<String>] = [
            "Generator:annual": [
                "Generator:Change generator oil",
                "Generator:Replace spark plugs",
                "Generator:Professional generator service",
                "Generator:Test automatic transfer switch",
            ],
            "Garage Door:annual": [
                "Garage Door:Test garage door auto-reverse",
                "Garage Door:Lubricate garage door tracks and hardware",
                "Garage Door:Professional garage door tune-up",
            ],
            "Septic System:triennial": [
                "Septic System:Septic tank pumping",
                "Septic System:Inspect septic baffles",
            ],
            "Pool/Spa:opening": [
                "Pool/Spa:Professional pool opening",
                "Pool/Spa:Inspect pool equipment",
            ],
            "Pool/Spa:closing": [
                "Pool/Spa:Professional pool closing/winterization",
            ],
        ]
        let allOrphanKeys = bundleOrphans.values.reduce(into: Set<String>()) { $0.formUnion($1) }

        var archivedCount = 0
        for property in properties {
            let tasks: [MaintenanceTaskDBRow]
            do {
                tasks = try await db.fetchMaintenanceTasks(propertyId: property.id)
            } catch {
                continue
            }

            for task in tasks {
                guard let templateId = task.templateId,
                      allOrphanKeys.contains(templateId),
                      task.lastCompletedDate == nil  // preserve completed tasks
                else { continue }

                var update = MaintenanceTaskUpdate()
                update.isArchived = true
                update.notes = (task.notes ?? "") + "\nConsolidated into bundled service visit (Phase 52)."
                _ = try? await db.updateMaintenanceTask(id: task.id, update)
                archivedCount += 1
            }
        }

        if archivedCount > 0 {
            print("[Phase52] Archived \(archivedCount) orphaned task\(archivedCount == 1 ? "" : "s") after bundle consolidation")
            // Re-run the reconciler on every property so the bundle tasks
            // that replace the archived individuals get created immediately.
            // Without this the Maintenance list reads as sparse until
            // something else (a quiz edit, a system add, etc.) kicks the
            // reconciler. Runs per-property so each household gets the
            // correct list even when a user owns multiple homes.
            for property in properties {
                _ = await MaintenanceTaskReconciler.reconcileAll(
                    propertyId: property.id,
                    householdId: property.householdId
                )
            }
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Build 87: removes existing in-flight "Check for leaks under sinks"
    /// tasks for users who completed the quiz on Build 86 or earlier. The
    /// template was deleted from `MaintenanceTemplates.swift` per Tom's
    /// TestFlight feedback (people notice plumbing leaks naturally; the
    /// quarterly nag added zero value). Completed instances stay so the
    /// historical log is intact — only incomplete tasks are archived.
    ///
    /// Mirrors the `purgeDroppedTemplatesOnce` pattern: per-property
    /// iteration via `fetchProperties()`, archive via `archiveMaintenanceTask`
    /// with a self-documenting reason. Gated on a dedicated UserDefaults
    /// flag so it only runs once per install.
    @MainActor
    static func removeLeakCheckTasksOnceIfNeeded() async {
        let key = "hasRemovedLeakCheckTasks_v1"
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
        let targetTemplateId = "Plumbing:Check for leaks under sinks"
        var removedCount = 0
        for property in properties {
            let tasks: [MaintenanceTaskDBRow]
            do {
                tasks = try await db.fetchMaintenanceTasks(propertyId: property.id)
            } catch {
                continue
            }
            for task in tasks {
                guard task.templateId == targetTemplateId else { continue }
                // Skip already-completed tasks so the history log stays intact.
                if task.lastCompletedDate != nil { continue }
                do {
                    try await db.archiveMaintenanceTask(
                        id: task.id,
                        reason: "build_87_leak_check_removed"
                    )
                    removedCount += 1
                } catch {
                    // Swallow individual failures.
                }
            }
        }
        if removedCount > 0 {
            print("[removeLeakCheckTasksV1] archived \(removedCount) leak-check task\(removedCount == 1 ? "" : "s")")
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    // MARK: - Build 89: Archive HNW chore-tracker tasks

    /// One-time migration that archives the low-value chore-tracker tasks
    /// (smoke detectors, fire extinguishers, weatherstripping, coils) that
    /// were auto-created by the pre-quiz OnboardingScheduleGenerator or the
    /// reconciler's orphan pass. These templates are now `isEssential: false`
    /// so they won't be re-created, but existing rows need cleanup.
    ///
    /// Matches by **title** (case-insensitive) because onboarding-created
    /// tasks have no `templateId`. Skips tasks the user has already completed
    /// to preserve history.
    static func archivePreQuizChoreTasksOnce() async {
        let key = "hasArchivedPreQuizChoreTasks_v1"
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

        let choreTitles: Set<String> = [
            "verify smoke detectors",
            "replace smoke detector batteries",
            "replace smoke detectors",
            "verify carbon monoxide detectors",
            "check fire extinguishers",
            "vacuum refrigerator coils",
            "inspect weatherstripping",
        ]

        var archivedCount = 0
        for property in properties {
            let tasks: [MaintenanceTaskDBRow]
            do {
                tasks = try await db.fetchMaintenanceTasks(propertyId: property.id)
            } catch {
                continue
            }
            for task in tasks {
                guard choreTitles.contains(task.title.lowercased()) else { continue }
                if task.lastCompletedDate != nil { continue }
                do {
                    try await db.archiveMaintenanceTask(
                        id: task.id,
                        reason: "build_89_hnw_chore_noise_removal"
                    )
                    archivedCount += 1
                } catch {
                    // Swallow individual failures.
                }
            }
        }
        if archivedCount > 0 {
            print("[archivePreQuizChoreTasks] archived \(archivedCount) chore-tracker task\(archivedCount == 1 ? "" : "s")")
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    // MARK: - Phase 50: Backfill Universal (Tier 1) Systems

    /// One-time backfill that adds missing Tier 1 systems to properties
    /// that completed the house quiz. Ensures every property has Plumbing,
    /// Electrical, and Cleaning Service even if those weren't part of the
    /// original quiz flow. Systems are added in "needs a vendor" state
    /// (no contractor, no service dates).
    static func backfillUniversalSystemsOnce() async {
        let key = "hasBackfilledUniversalSystems_v2"
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

        var createdCount = 0
        var cleanedCount = 0
        for property in properties {
            // Only backfill properties that completed the quiz
            guard property.houseQuizState?.completedAt != nil else { continue }

            let existingSystems: [HomeSystemRow]
            do {
                existingSystems = try await db.fetchHomeSystems(propertyId: property.id)
            } catch {
                continue
            }

            // V2 cleanup: remove duplicate systems created by v1.
            // Group by category, keep the oldest (quiz-created), delete the backfill duplicate.
            let byCategory = Dictionary(grouping: existingSystems.filter { $0.parentSystemId == nil }) { $0.category }
            for (_, dupes) in byCategory where dupes.count > 1 {
                // Sort by creation date, keep the first (oldest), delete the rest
                let sorted = dupes.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
                for dupe in sorted.dropFirst() {
                    // Only delete if it has no preferred contractor and no service dates
                    // (i.e., it's a bare backfill row, not user-enriched)
                    if dupe.preferredContractorId == nil && dupe.lastServiceDate == nil {
                        try? await db.deleteHomeSystem(id: dupe.id)
                        cleanedCount += 1
                    }
                }
            }

            // Now check what's actually still there after cleanup
            let remainingSystems: [HomeSystemRow]
            do {
                remainingSystems = try await db.fetchHomeSystems(propertyId: property.id)
            } catch {
                continue
            }

            let existingCategories = Set(remainingSystems.map(\.category))
            let existingNames = Set(remainingSystems.map { $0.name.lowercased() })

            for meta in SystemCategoryRegistry.universal {
                // Skip if category OR name already exists
                guard !existingCategories.contains(meta.categoryKey),
                      !existingNames.contains(meta.displayName.lowercased())
                else { continue }

                let insert = HomeSystemInsert(
                    propertyId: property.id,
                    householdId: property.householdId,
                    name: meta.displayName,
                    category: meta.categoryKey
                )
                do {
                    _ = try await db.createHomeSystem(insert)
                    createdCount += 1
                } catch {
                    // Swallow individual failures
                }
            }
        }

        if createdCount > 0 || cleanedCount > 0 {
            print("[backfillUniversalSystems] created \(createdCount), cleaned \(cleanedCount) duplicate(s)")
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
        }
        UserDefaults.standard.set(true, forKey: key)
    }
}

import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var needsOnboarding = false
    @Published var primaryProperty: PropertyRow?
    @Published var hasCheckedPrimaryProperty = false

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
}

import Foundation
import Supabase

/// Manages Supabase Realtime channel subscriptions for dashboard live updates.
/// Subscribes to Postgres changes on documents, maintenance_tasks, home_systems,
/// contractors, AND handyman_punch_items (Round F G-F-1 fix — handyman writes
/// from Chez Field now propagate live to the homeowner punch list). On change
/// events, posts the corresponding NotificationCenter notification so the
/// DashboardViewModel's existing `subscribeToChanges()` handler triggers a
/// refresh.
///
/// Lifecycle: call `subscribe()` after auth, `unsubscribe()` on sign out.
@MainActor
final class RealtimeService {
    static let shared = RealtimeService()

    private var channel: RealtimeChannelV2?
    private var isSubscribed = false
    private var listenerTasks: [Task<Void, Never>] = []

    private init() {}

    /// Subscribe to Postgres changes on activity-relevant tables.
    /// Safe to call multiple times; subsequent calls are no-ops.
    func subscribe() {
        guard !isSubscribed else { return }
        isSubscribed = true

        let channel = HavenSupabase.client.realtimeV2.channel("dashboard-activity")

        // Set up change listeners for each table
        let docInserts = channel.postgresChange(InsertAction.self, schema: "public", table: "documents")
        let docUpdates = channel.postgresChange(UpdateAction.self, schema: "public", table: "documents")
        let taskUpdates = channel.postgresChange(UpdateAction.self, schema: "public", table: "maintenance_tasks")
        let systemInserts = channel.postgresChange(InsertAction.self, schema: "public", table: "home_systems")
        let contractorInserts = channel.postgresChange(InsertAction.self, schema: "public", table: "contractors")
        // Round F G-F-1 fix: subscribe to handyman_punch_items so a handyman
        // writing a punch from Chez Field propagates live to the homeowner's
        // HandymanPunchListView. Previously the table was shared between apps
        // but only HandymanTabView subscribed to handyman_request_messages —
        // the punch list relied entirely on local notification posts triggered
        // by the homeowner's own writes.
        let punchInserts = channel.postgresChange(InsertAction.self, schema: "public", table: "handyman_punch_items")
        let punchUpdates = channel.postgresChange(UpdateAction.self, schema: "public", table: "handyman_punch_items")

        self.channel = channel

        // Subscribe to channel and set up async listeners
        let subscribeTask = Task { [weak self] in
            try? await channel.subscribeWithError()

            guard self != nil else { return }

            // Document changes
            let t1 = Task {
                for await _ in docInserts {
                    NotificationCenter.default.post(name: .documentChanged, object: nil)
                }
            }
            let t2 = Task {
                for await _ in docUpdates {
                    NotificationCenter.default.post(name: .documentChanged, object: nil)
                }
            }
            // Task completions
            let t3 = Task {
                for await _ in taskUpdates {
                    NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                }
            }
            // System additions
            let t4 = Task {
                for await _ in systemInserts {
                    NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
                }
            }
            // Contractor additions
            let t5 = Task {
                for await _ in contractorInserts {
                    NotificationCenter.default.post(name: .contractorChanged, object: nil)
                }
            }
            // Round F G-F-1: handyman punch list inserts (handyman adds a punch
            // from Chez Field mid-visit) + updates (status flip, completion).
            let t6 = Task {
                for await _ in punchInserts {
                    NotificationCenter.default.post(name: .handymanPunchListChanged, object: nil)
                }
            }
            let t7 = Task {
                for await _ in punchUpdates {
                    NotificationCenter.default.post(name: .handymanPunchListChanged, object: nil)
                }
            }

            await MainActor.run { [weak self] in
                self?.listenerTasks = [t1, t2, t3, t4, t5, t6, t7]
            }
        }
        listenerTasks.append(subscribeTask)

        print("[RealtimeService] Subscribed to dashboard-activity channel")
    }

    /// Unsubscribe from all Realtime channels. Call on sign out.
    func unsubscribe() {
        guard isSubscribed else { return }
        isSubscribed = false

        for task in listenerTasks {
            task.cancel()
        }
        listenerTasks.removeAll()

        Task {
            await channel?.unsubscribe()
            channel = nil
        }

        print("[RealtimeService] Unsubscribed from dashboard-activity channel")
    }
}

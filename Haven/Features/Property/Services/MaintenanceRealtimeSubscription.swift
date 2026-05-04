import Foundation
import Supabase

/// Phase 95 (audit gap #94) — Realtime subscription for
/// `maintenance_tasks` filtered by household_id.
///
/// Today the Maintenance tab refreshes on:
///   • app foreground (`.onAppear` / `.task` reloads)
///   • pull-to-refresh
///   • the local-only `.maintenanceTaskChanged` NotificationCenter post
///
/// None of those see writes from a SECOND device — if Spouse A
/// completes "Replace HVAC filter" on their phone, Spouse B's
/// open Maintenance tab still shows it as overdue until B
/// foregrounds the app. For an HNW couple sharing one home, that
/// stale state breaks the "we both manage this house" promise.
///
/// This class owns a single Realtime channel for the household.
/// Callers register insert / update / delete handlers; events
/// fire on the main actor with a decoded `MaintenanceTaskDBRow`.
/// Decode failures are logged and skipped — the SDK surfaces
/// payloads as `[String: AnyJSON]` which JSONEncoder can encode
/// for re-decode. Tested pattern from
/// `HandymanTabView.RequestCoordinator.subscribeRealtime`.
@MainActor
final class MaintenanceRealtimeSubscription {
    private let householdId: UUID
    private var channel: RealtimeChannelV2?
    private var listenerTask: Task<Void, Never>?

    var onInsert: ((MaintenanceTaskDBRow) -> Void)?
    var onUpdate: ((MaintenanceTaskDBRow) -> Void)?
    var onDelete: ((UUID) -> Void)?

    init(householdId: UUID) {
        self.householdId = householdId
    }

    deinit {
        let task = listenerTask
        let ch = channel
        Task.detached {
            task?.cancel()
            if let ch {
                await ch.unsubscribe()
            }
        }
    }

    /// Opens the channel and starts listening. Idempotent —
    /// re-subscribing tears down the prior channel first so the
    /// caller can refresh the household scope after a switch.
    func start() async {
        await stop()

        let topic = "maintenance-tasks-\(householdId.uuidString)"
        let ch = HavenSupabase.client.realtimeV2.channel(topic)
        channel = ch

        let insertStream = ch.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "maintenance_tasks",
            filter: .eq("household_id", value: householdId.uuidString)
        )
        let updateStream = ch.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "maintenance_tasks",
            filter: .eq("household_id", value: householdId.uuidString)
        )
        let deleteStream = ch.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "maintenance_tasks",
            filter: .eq("household_id", value: householdId.uuidString)
        )

        listenerTask = Task { [weak self] in
            do {
                try await ch.subscribeWithError()
            } catch {
                // Subscribe failed; leave state unchanged so the
                // next `start()` call gets a clean retry.
                return
            }

            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await action in insertStream {
                        guard let self else { return }
                        if let row = Self.decode(action.record) {
                            await MainActor.run { self.onInsert?(row) }
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await action in updateStream {
                        guard let self else { return }
                        if let row = Self.decode(action.record) {
                            await MainActor.run { self.onUpdate?(row) }
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await action in deleteStream {
                        guard let self else { return }
                        // DELETE payloads carry the OLD record; the
                        // task `id` is the only field we need so we
                        // pluck it directly to skip a full decode.
                        let raw = action.oldRecord
                        if let idValue = raw["id"], let idString = Self.stringValue(idValue),
                           let uuid = UUID(uuidString: idString) {
                            await MainActor.run { self.onDelete?(uuid) }
                        }
                    }
                }
            }
        }
    }

    /// Tears down the active channel. Safe to call when nothing
    /// is subscribed.
    func stop() async {
        listenerTask?.cancel()
        listenerTask = nil
        if let ch = channel {
            channel = nil
            await ch.unsubscribe()
        }
    }

    /// Decodes a Realtime payload into a `MaintenanceTaskDBRow`.
    /// Routes through JSONEncoder/JSONDecoder because the SDK
    /// surfaces records as `[String: AnyJSON]` (a Swift enum
    /// tree); JSONSerialization can't walk that directly. Tested
    /// pattern from the handyman-message Realtime path.
    nonisolated private static func decode(_ record: [String: AnyJSON]) -> MaintenanceTaskDBRow? {
        guard let data = try? encoder.encode(record) else { return nil }
        return try? decoder.decode(MaintenanceTaskDBRow.self, from: data)
    }

    /// Plucks a string out of an `AnyJSON` value — used for the
    /// DELETE-payload `id` extraction. Defensive across a few
    /// likely shapes (string, raw uuid, etc.).
    nonisolated private static func stringValue(_ value: AnyJSON) -> String? {
        if let data = try? encoder.encode(value),
           let raw = String(data: data, encoding: .utf8) {
            // AnyJSON's Codable encodes a string as `"abc"`; trim
            // the surrounding quotes when present.
            if raw.hasPrefix("\""), raw.hasSuffix("\""), raw.count >= 2 {
                return String(raw.dropFirst().dropLast())
            }
            return raw
        }
        return nil
    }

    nonisolated private static let encoder: JSONEncoder = JSONEncoder()
    nonisolated private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return d
    }()
}

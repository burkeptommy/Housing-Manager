import Foundation
import Supabase

/// Phase 95 (audit gap #94, expansion) — Realtime subscriptions
/// for the secondary household tables that feel "live" to a
/// couple sharing a home: `home_systems` and `contractors`.
///
/// The primary task subscription lives in
/// `MaintenanceRealtimeSubscription`. Pulling the other two
/// out into focused classes mirrors the pattern (one class per
/// table) without forcing a generic abstraction that would
/// leak `[String: AnyJSON]` decoding into the call sites.
///
/// All three classes share the same shape:
///   • init(householdId:)
///   • set onInsert / onUpdate / onDelete handlers
///   • call start() to open the channel
///   • call stop() (or rely on deinit) to tear down
///
/// Decoders use the lifted `iso8601WithFractionalSeconds`
/// strategy from `HandymanTabView.swift` so all four Realtime
/// paths in the app handle Postgres microsecond timestamps
/// the same way.

@MainActor
final class HomeSystemRealtimeSubscription {
    private let householdId: UUID
    private var channel: RealtimeChannelV2?
    private var listenerTask: Task<Void, Never>?

    var onInsert: ((HomeSystemRow) -> Void)?
    var onUpdate: ((HomeSystemRow) -> Void)?
    var onDelete: ((UUID) -> Void)?

    init(householdId: UUID) {
        self.householdId = householdId
    }

    deinit {
        let task = listenerTask
        let ch = channel
        Task.detached {
            task?.cancel()
            if let ch { await ch.unsubscribe() }
        }
    }

    func start() async {
        await stop()
        let topic = "home-systems-\(householdId.uuidString)"
        let ch = HavenSupabase.client.realtimeV2.channel(topic)
        channel = ch

        let inserts = ch.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "home_systems",
            filter: .eq("household_id", value: householdId.uuidString)
        )
        let updates = ch.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "home_systems",
            filter: .eq("household_id", value: householdId.uuidString)
        )
        let deletes = ch.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "home_systems",
            filter: .eq("household_id", value: householdId.uuidString)
        )

        listenerTask = Task { [weak self] in
            do { try await ch.subscribeWithError() } catch { return }
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await action in inserts {
                        guard let self else { return }
                        if let row: HomeSystemRow = HouseholdRealtimeDecoder.decode(action.record) {
                            await MainActor.run { self.onInsert?(row) }
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await action in updates {
                        guard let self else { return }
                        if let row: HomeSystemRow = HouseholdRealtimeDecoder.decode(action.record) {
                            await MainActor.run { self.onUpdate?(row) }
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await action in deletes {
                        guard let self else { return }
                        if let id = HouseholdRealtimeDecoder.idFromOldRecord(action.oldRecord) {
                            await MainActor.run { self.onDelete?(id) }
                        }
                    }
                }
            }
        }
    }

    func stop() async {
        listenerTask?.cancel()
        listenerTask = nil
        if let ch = channel {
            channel = nil
            await ch.unsubscribe()
        }
    }
}

@MainActor
final class ContractorRealtimeSubscription {
    private let householdId: UUID
    private var channel: RealtimeChannelV2?
    private var listenerTask: Task<Void, Never>?

    var onInsert: ((ContractorRow) -> Void)?
    var onUpdate: ((ContractorRow) -> Void)?
    var onDelete: ((UUID) -> Void)?

    init(householdId: UUID) {
        self.householdId = householdId
    }

    deinit {
        let task = listenerTask
        let ch = channel
        Task.detached {
            task?.cancel()
            if let ch { await ch.unsubscribe() }
        }
    }

    func start() async {
        await stop()
        let topic = "contractors-\(householdId.uuidString)"
        let ch = HavenSupabase.client.realtimeV2.channel(topic)
        channel = ch

        let inserts = ch.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "contractors",
            filter: .eq("household_id", value: householdId.uuidString)
        )
        let updates = ch.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "contractors",
            filter: .eq("household_id", value: householdId.uuidString)
        )
        let deletes = ch.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "contractors",
            filter: .eq("household_id", value: householdId.uuidString)
        )

        listenerTask = Task { [weak self] in
            do { try await ch.subscribeWithError() } catch { return }
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await action in inserts {
                        guard let self else { return }
                        if let row: ContractorRow = HouseholdRealtimeDecoder.decode(action.record) {
                            await MainActor.run { self.onInsert?(row) }
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await action in updates {
                        guard let self else { return }
                        if let row: ContractorRow = HouseholdRealtimeDecoder.decode(action.record) {
                            await MainActor.run { self.onUpdate?(row) }
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await action in deletes {
                        guard let self else { return }
                        if let id = HouseholdRealtimeDecoder.idFromOldRecord(action.oldRecord) {
                            await MainActor.run { self.onDelete?(id) }
                        }
                    }
                }
            }
        }
    }

    func stop() async {
        listenerTask?.cancel()
        listenerTask = nil
        if let ch = channel {
            channel = nil
            await ch.unsubscribe()
        }
    }
}

/// Phase 95 (gap #94 expansion) — shared decoder helpers used by
/// `HomeSystemRealtimeSubscription` + `ContractorRealtimeSubscription`.
/// Routes Realtime payloads (`[String: AnyJSON]`) through
/// JSONEncoder/JSONDecoder because JSONSerialization can't walk
/// AnyJSON's enum tree directly. Same pattern the original
/// `MaintenanceRealtimeSubscription` uses; centralized here so the
/// secondary tables don't each need their own copy.
enum HouseholdRealtimeDecoder {
    nonisolated static func decode<Row: Decodable>(_ record: [String: AnyJSON]) -> Row? {
        guard let data = try? encoder.encode(record) else { return nil }
        return try? decoder.decode(Row.self, from: data)
    }

    nonisolated static func idFromOldRecord(_ record: [String: AnyJSON]) -> UUID? {
        guard let value = record["id"],
              let data = try? encoder.encode(value),
              let raw = String(data: data, encoding: .utf8) else {
            return nil
        }
        let trimmed: String
        if raw.hasPrefix("\""), raw.hasSuffix("\""), raw.count >= 2 {
            trimmed = String(raw.dropFirst().dropLast())
        } else {
            trimmed = raw
        }
        return UUID(uuidString: trimmed)
    }

    nonisolated private static let encoder: JSONEncoder = JSONEncoder()
    nonisolated private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return d
    }()
}

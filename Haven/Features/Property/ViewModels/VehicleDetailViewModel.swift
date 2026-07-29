import SwiftUI

// MARK: - Vehicle Alert

struct VehicleAlert: Identifiable {
    let id = UUID()
    let severity: AlertSeverity
    let title: String
    let subtitle: String
    let icon: String
    let type: AlertType

    enum AlertSeverity: String, Comparable {
        case critical, warning, info
        static func < (lhs: Self, rhs: Self) -> Bool {
            let order: [Self] = [.critical, .warning, .info]
            return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
        }
    }

    enum AlertType {
        case recall(VehicleRecallRow)
        case registration
        case inspection
        case maintenance(VehicleMaintenanceInterval)
    }
}

// MARK: - ViewModel

@MainActor
final class VehicleDetailViewModel: ObservableObject {
    @Published var vehicle: VehicleRow?
    @Published var serviceRecords: [VehicleServiceRecordRow] = []
    @Published var recalls: [VehicleRecallRow] = []
    @Published var maintenanceTasks: [MaintenanceTaskDBRow] = []
    @Published var linkedDocuments: [DocumentRow] = []
    @Published var contractors: [ContractorRow] = []
    @Published var familyMembers: [FamilyMemberRow] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isLoadingValue = false

    private let db = DatabaseService.shared
    private var lastLoadedAt: Date?
    private let freshnessWindow: TimeInterval = 60 // seconds

    /// Per-vehicle in-memory cache so re-entering the detail view reuses the
    /// hydrated VM (hero + sections appear instantly) instead of re-fetching
    /// everything from scratch each time.
    private static var cache: [UUID: VehicleDetailViewModel] = [:]

    static func cached(for vehicleId: UUID) -> VehicleDetailViewModel {
        if let existing = cache[vehicleId] { return existing }
        let vm = VehicleDetailViewModel()
        cache[vehicleId] = vm
        return vm
    }

    static func invalidateCache(vehicleId: UUID? = nil) {
        if let id = vehicleId { cache.removeValue(forKey: id) }
        else { cache.removeAll() }
    }

    // July 2026 (audit F8): the 60s freshness window silently swallowed every
    // mutation's refresh — editing mileage / insurance / mechanic within 60s
    // of opening the detail view left the hero + sections stale (the
    // un-forced load early-returned). Fix: every mutation callback in
    // VehicleDetailView now passes force: true; only the .task onAppear load
    // keeps the cache (for instant re-entry).
    func load(vehicleId: UUID, force: Bool = false) async {
        // Skip the full reload if data is fresh enough — view shows cached
        // hero/sections instantly. The estimated-value refresh below still
        // runs (cheap, only re-hits Claude every 30 days).
        if !force, vehicle?.id == vehicleId, let last = lastLoadedAt,
           Date().timeIntervalSince(last) < freshnessWindow {
            Task { await self.refreshEstimatedValueIfStale() }
            return
        }

        // Only show loading spinner on the very first load — re-loads keep the
        // existing UI visible while fetching in the background.
        let isFirstLoad = vehicle == nil
        if isFirstLoad { isLoading = true }
        defer { if isFirstLoad { isLoading = false } }

        // Load vehicle first (critical)
        do {
            vehicle = try await db.fetchVehicle(id: vehicleId)
        } catch {
            self.error = "Failed to load vehicle: \(error.localizedDescription)"
            print("[VehicleDetail] Vehicle load failed: \(error)")
            return
        }

        // Load supplementary data (non-critical -- don't block on failures)
        async let recordsTask: [VehicleServiceRecordRow] = (try? await db.fetchVehicleServiceRecords(vehicleId: vehicleId)) ?? []
        async let recallsTask: [VehicleRecallRow] = (try? await db.fetchVehicleRecalls(vehicleId: vehicleId)) ?? []
        async let tasksTask: [MaintenanceTaskDBRow] = (try? await db.fetchVehicleMaintenanceTasks(vehicleId: vehicleId)) ?? []
        async let docsTask: [DocumentRow] = await Self.fetchVehicleDocsIncludingVinMatches(db: db, vehicleId: vehicleId, vin: vehicle?.vin)
        async let contractorsTask: [ContractorRow] = (try? await db.fetchContractors()) ?? []
        async let membersTask: [FamilyMemberRow] = (try? await db.fetchFamilyMembers()) ?? []

        serviceRecords = await recordsTask
        recalls = await recallsTask
        maintenanceTasks = await tasksTask
        linkedDocuments = await docsTask
        contractors = await contractorsTask
        familyMembers = await membersTask
        lastLoadedAt = Date()

        // Kick off value refresh in the background — non-blocking
        Task { await self.refreshEstimatedValueIfStale() }
    }

    /// Refreshes the cached estimated value if it's missing or older than 30 days.
    /// Persists the result to the vehicle row so subsequent loads are instant.
    func refreshEstimatedValueIfStale() async {
        guard let v = vehicle else { return }
        let stale: Bool = {
            guard let updated = v.estimatedValueUpdatedAt else { return true }
            return Date().timeIntervalSince(updated) > 30 * 24 * 60 * 60
        }()
        guard stale else { return }
        guard let year = v.year, let make = v.make, let model = v.model else { return }

        isLoadingValue = true
        defer { isLoadingValue = false }

        do {
            let estimate = try await HavenSupabase.vehicleValue(
                year: year,
                make: make,
                model: model,
                trim: v.trim,
                mileage: v.currentMileage,
                condition: nil
            )
            var update = VehicleUpdate()
            update.estimatedValue = estimate.mid
            update.estimatedValueLow = estimate.low
            update.estimatedValueHigh = estimate.high
            update.estimatedValueUpdatedAt = Date()
            update.estimatedValueSource = estimate.source
            let updated = try await db.updateVehicle(id: v.id, update)
            self.vehicle = updated
        } catch {
            print("[VehicleDetail] value estimate failed: \(error)")
        }
    }

    var primaryDriverName: String? {
        guard let driverId = vehicle?.primaryDriverId else { return nil }
        return familyMembers.first { $0.id == driverId }.map { "\($0.firstName) \($0.lastName)" }
    }

    var preferredMechanicName: String? {
        guard let mechanicId = vehicle?.preferredMechanicId else { return nil }
        return contractors.first { $0.id == mechanicId }?.companyName
    }

    var unresolvedRecalls: [VehicleRecallRow] {
        recalls.filter { !$0.isResolved }
    }

    func deleteVehicle() async throws {
        guard let id = vehicle?.id else { return }
        try await db.deleteVehicle(id: id)
        Self.invalidateCache(vehicleId: id)
    }

    // MARK: - Computed Alerts

    var alerts: [VehicleAlert] {
        guard let vehicle else { return [] }
        var result: [VehicleAlert] = []
        let calendar = Calendar.current
        let today = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        // 1. Unresolved recalls
        for recall in unresolvedRecalls {
            result.append(VehicleAlert(
                severity: .critical,
                title: "Open Recall: \(recall.component ?? "Unknown Component")",
                subtitle: recall.summary ?? "Contact your dealer for details.",
                icon: "exclamationmark.triangle.fill",
                type: .recall(recall)
            ))
        }

        // 2. Registration expiry
        if let expiryStr = vehicle.registrationExpiry, let expiry = df.date(from: expiryStr) {
            let days = calendar.dateComponents([.day], from: today, to: expiry).day ?? 0
            if days < 0 {
                result.append(VehicleAlert(severity: .critical, title: "Registration Expired", subtitle: "\(abs(days)) days overdue", icon: "doc.badge.clock.fill", type: .registration))
            } else if days <= 30 {
                result.append(VehicleAlert(severity: .warning, title: "Registration Expiring", subtitle: "Due in \(days) days", icon: "doc.badge.clock.fill", type: .registration))
            } else if days <= 60 {
                result.append(VehicleAlert(severity: .info, title: "Registration Renewal Coming", subtitle: "Due in \(days) days", icon: "doc.badge.clock.fill", type: .registration))
            }
        }

        // 3. Inspection expiry
        if let expiryStr = vehicle.inspectionExpiry, let expiry = df.date(from: expiryStr) {
            let days = calendar.dateComponents([.day], from: today, to: expiry).day ?? 0
            if days < 0 {
                result.append(VehicleAlert(severity: .critical, title: "Inspection Expired", subtitle: "\(abs(days)) days overdue", icon: "checkmark.shield.fill", type: .inspection))
            } else if days <= 30 {
                result.append(VehicleAlert(severity: .warning, title: "Inspection Due", subtitle: "Due in \(days) days", icon: "checkmark.shield.fill", type: .inspection))
            } else if days <= 60 {
                result.append(VehicleAlert(severity: .info, title: "Inspection Coming Up", subtitle: "Due in \(days) days", icon: "checkmark.shield.fill", type: .inspection))
            }
        }

        // Maintenance alerts are now stored as tasks -- see maintenanceTasks property

        return result.sorted { $0.severity < $1.severity }
    }

    /// Overdue vehicle maintenance tasks
    var overdueMaintenanceTasks: [MaintenanceTaskDBRow] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return maintenanceTasks.filter { task in
            guard let date = df.date(from: task.nextDueDate) else { return false }
            return date < Date()
        }
    }

    /// Upcoming vehicle maintenance tasks (not overdue)
    var upcomingMaintenanceTasks: [MaintenanceTaskDBRow] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return maintenanceTasks.filter { task in
            guard let date = df.date(from: task.nextDueDate) else { return true }
            return date >= Date()
        }
    }

    /// Fetch documents linked via vehicle_id OR containing this vehicle's VIN in metadata.
    /// This handles multi-vehicle documents like auto insurance.
    static func fetchVehicleDocsIncludingVinMatches(db: DatabaseService, vehicleId: UUID, vin: String?) async -> [DocumentRow] {
        // Direct vehicle_id link
        var docs = (try? await db.fetchVehicleDocuments(vehicleId: vehicleId)) ?? []
        let directIds = Set(docs.map(\.id))

        // Also find docs where this vehicle's VIN appears in metadata.matched_vehicle_ids
        if let vin, !vin.isEmpty {
            let allDocs = (try? await db.fetchDocuments()) ?? []
            let vinUpper = vin.uppercased()
            for doc in allDocs where !directIds.contains(doc.id) {
                if let vins = doc.metadata?.detectedVins, vins.contains(vinUpper) {
                    docs.append(doc)
                } else if let matched = doc.metadata?.matchedVehicleIds, matched.contains(vehicleId.uuidString) {
                    docs.append(doc)
                }
            }
        }

        return docs
    }
}

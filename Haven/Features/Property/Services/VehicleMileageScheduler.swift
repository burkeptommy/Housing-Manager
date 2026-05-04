import Foundation

/// Phase 95 (audit gap #77) — recomputes `next_due_date` on mileage-triggered
/// vehicle maintenance tasks whenever the user updates their odometer.
///
/// Why: Without this, every-N-miles tasks (oil change, tire rotation) keep
/// the date that was stamped at vehicle creation — a 12-month default
/// fallback when the AI maintenance schedule emits only a mileage interval.
/// A user who drives 15K mi/year on a 5K-mi oil change interval should see
/// the task come due roughly every 4 months, not annually. This helper
/// closes that gap by walking the vehicle's incomplete tasks and rewriting
/// the due date against the new mileage.
///
/// We don't try to be clever about per-vehicle driving rate yet; the
/// national average of ~12,000 mi/year (≈33 mi/day) is the divisor used
/// to convert "miles remaining" into "days remaining." A future iteration
/// can derive the rate from the user's own mileage history.
enum VehicleMileageScheduler {
    private static let averageMilesPerDay: Double = 33.0

    @discardableResult
    static func recalculateDueDates(
        vehicleId: UUID,
        newMileage: Int,
        db: DatabaseService = .shared,
        today: Date = Date()
    ) async -> Int {
        let tasks: [MaintenanceTaskDBRow]
        do {
            tasks = try await db.fetchMaintenanceTasks(vehicleId: vehicleId, includeArchived: false)
        } catch {
            return 0
        }
        let serviceRecords = (try? await db.fetchVehicleServiceRecords(vehicleId: vehicleId)) ?? []

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let calendar = Calendar(identifier: .gregorian)

        var updated = 0
        for task in tasks {
            guard let intervalMiles = parseIntervalMiles(from: task.frequency) else {
                continue
            }
            let baselineMileage = baselineMileage(for: task, serviceRecords: serviceRecords)
            let milesUsed = max(0, newMileage - baselineMileage)
            let newDueDate: Date
            if milesUsed >= intervalMiles {
                newDueDate = today
            } else {
                let milesRemaining = Double(intervalMiles - milesUsed)
                let daysRemaining = max(0, Int(ceil(milesRemaining / averageMilesPerDay)))
                newDueDate = calendar.date(byAdding: .day, value: daysRemaining, to: today) ?? today
            }
            let newDueString = formatter.string(from: newDueDate)
            if newDueString == task.nextDueDate { continue }

            do {
                _ = try await db.updateMaintenanceTask(
                    id: task.id,
                    MaintenanceTaskUpdate(nextDueDate: newDueString)
                )
                updated += 1
            } catch {
                continue
            }
        }
        return updated
    }

    /// Parses miles intervals like "Every 5,000 miles", "Every 7500 mi",
    /// "5000 mile". Returns nil for non-mileage cadences ("Every 6 months",
    /// "Annual", etc.) so the recalc skips them entirely.
    static func parseIntervalMiles(from frequency: String) -> Int? {
        let lower = frequency.lowercased()
        guard lower.range(of: #"\bmi(?:le)?s?\b"#, options: .regularExpression) != nil else {
            return nil
        }
        let pattern = #"([0-9][0-9,]*)\s*(?:mile|mi)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(lower.startIndex..<lower.endIndex, in: lower)
        guard let match = regex.firstMatch(in: lower, options: [], range: range),
              match.numberOfRanges >= 2,
              let captureRange = Range(match.range(at: 1), in: lower) else {
            return nil
        }
        let captured = lower[captureRange].replacingOccurrences(of: ",", with: "")
        return Int(captured)
    }

    /// Odometer reading at the most recent matching service record, or 0
    /// when nothing is on file. We match `service_type` against the task's
    /// `template_id` because vehicle-lookup writes the interval type
    /// ("oil_change") as both the templateId and the service_type emitted
    /// by `process-invoice`. Without a record we treat the entire current
    /// mileage as accrued — i.e. assume the work has never been done since
    /// the vehicle was added.
    private static func baselineMileage(
        for task: MaintenanceTaskDBRow,
        serviceRecords: [VehicleServiceRecordRow]
    ) -> Int {
        guard let templateId = task.templateId, !templateId.isEmpty else {
            return 0
        }
        let matching = serviceRecords.filter {
            $0.serviceType.compare(templateId, options: .caseInsensitive) == .orderedSame
                && $0.mileageAtService != nil
        }
        guard let mostRecent = matching.max(by: { $0.serviceDate < $1.serviceDate }) else {
            return 0
        }
        return mostRecent.mileageAtService ?? 0
    }
}

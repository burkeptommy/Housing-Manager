import SwiftUI

enum MaintenanceTaskIcon {
    static func icon(for task: MaintenanceTaskDBRow) -> String {
        // Use templateId first (most reliable for vehicle tasks)
        if let templateId = task.templateId {
            let type = templateId.contains(":") ? String(templateId.split(separator: ":").last ?? "") : templateId
            if let mapped = vehicleTypeIcon(type.lowercased()) { return mapped }
        }
        // Fall back to title keyword matching
        return iconFromTitle(task.title, isVehicle: task.vehicleId != nil)
    }

    static func icon(forType type: String) -> String {
        vehicleTypeIcon(type.lowercased()) ?? "wrench.and.screwdriver"
    }

    private static func vehicleTypeIcon(_ type: String) -> String? {
        switch type {
        case "oil_change", "oil change": return "drop.fill"
        case "tire_rotation", "tire rotation": return "tire"
        case "brake_inspection", "brake inspection", "brake_service", "brake service": return "pedal.brake.fill"
        case "air_filter", "air filter": return "aqi.medium"
        case "cabin_filter", "cabin filter": return "aqi.medium"
        case "transmission_fluid", "transmission fluid": return "gearshape.fill"
        case "coolant_flush", "coolant flush": return "thermometer.medium"
        case "spark_plugs", "spark plugs": return "bolt.fill"
        case "battery_check", "battery check": return "battery.100percent"
        case "wheel_alignment", "wheel alignment": return "arrow.left.and.right"
        case "wiper_blades", "wiper blades": return "drop.degreesign.fill"
        case "serpentine_belt", "serpentine belt", "timing_belt", "timing belt": return "fanblades.fill"
        case "differential_fluid", "differential fluid": return "gearshape.2.fill"
        case "inspection": return "checkmark.shield.fill"
        case "registration_renewal", "registration renewal": return "doc.badge.clock.fill"
        case "emissions", "emissions_test": return "smoke.fill"
        case "recall_repair", "recall repair": return "exclamationmark.triangle.fill"
        default: return nil
        }
    }

    private static func iconFromTitle(_ title: String, isVehicle: Bool) -> String {
        let lower = title.lowercased()
        if lower.contains("oil") { return "drop.fill" }
        if lower.contains("tire") || lower.contains("rotation") { return "tire" }
        if lower.contains("brake") { return "pedal.brake.fill" }
        if lower.contains("filter") { return "aqi.medium" }
        if lower.contains("transmission") { return "gearshape.fill" }
        if lower.contains("coolant") { return "thermometer.medium" }
        if lower.contains("spark") || lower.contains("plug") { return "bolt.fill" }
        if lower.contains("battery") { return "battery.100percent" }
        if lower.contains("alignment") { return "arrow.left.and.right" }
        if lower.contains("wiper") { return "drop.degreesign.fill" }
        if lower.contains("belt") { return "fanblades.fill" }
        if lower.contains("registration") { return "doc.badge.clock.fill" }
        if lower.contains("inspection") { return "checkmark.shield.fill" }
        if lower.contains("recall") { return "exclamationmark.triangle.fill" }
        if isVehicle { return "car.fill" }
        return "wrench.and.screwdriver"
    }

    /// Short label for the task tile (e.g., "Oil", "Tires", "Brakes")
    static func shortLabel(for task: MaintenanceTaskDBRow) -> String {
        if let templateId = task.templateId {
            let type = templateId.contains(":") ? String(templateId.split(separator: ":").last ?? "") : templateId
            if let label = vehicleTypeLabel(type.lowercased()) { return label }
        }
        return labelFromTitle(task.title)
    }

    /// Service interval for display on vehicle tiles. Prefers mileage over time.
    static func intervalLabel(for task: MaintenanceTaskDBRow) -> String? {
        let freq = task.frequency
        let lower = freq.lowercased()
        if lower == "as needed" || lower.isEmpty { return nil }

        // Extract mileage if present in the frequency string
        if lower.contains("mile") {
            // Parse number from strings like "Every 5000 miles"
            if let miles = extractNumber(from: freq) {
                return formatMiles(miles)
            }
        }

        // Extract months and convert to a short label
        if lower.contains("month") {
            if let months = extractNumber(from: freq) {
                return "\(months) mo"
            }
        }

        // Fallback: shorten what we have
        if freq.count <= 10 { return freq }
        return freq
            .replacingOccurrences(of: "Every ", with: "")
            .replacingOccurrences(of: " months", with: " mo")
            .replacingOccurrences(of: " miles", with: " mi")
    }

    /// Format mileage compactly: 5000 -> "5K mi", 30000 -> "30K mi", 750 -> "750 mi"
    private static func formatMiles(_ miles: Int) -> String {
        if miles >= 1000 && miles % 1000 == 0 {
            return "\(miles / 1000)K mi"
        } else if miles >= 1000 {
            let k = Double(miles) / 1000
            return String(format: "%.1fK mi", k)
        }
        return "\(miles) mi"
    }

    private static func extractNumber(from string: String) -> Int? {
        let digits = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digits)
    }

    private static func vehicleTypeLabel(_ type: String) -> String? {
        switch type {
        case "oil_change", "oil change": return "Oil"
        case "tire_rotation", "tire rotation": return "Tires"
        case "brake_inspection", "brake inspection", "brake_service", "brake service": return "Brakes"
        case "air_filter", "air filter": return "Air Filter"
        case "cabin_filter", "cabin filter": return "Cabin Filter"
        case "transmission_fluid", "transmission fluid": return "Trans."
        case "coolant_flush", "coolant flush": return "Coolant"
        case "spark_plugs", "spark plugs": return "Plugs"
        case "battery_check", "battery check": return "Battery"
        case "wheel_alignment", "wheel alignment": return "Alignment"
        case "wiper_blades", "wiper blades": return "Wipers"
        case "serpentine_belt", "serpentine belt": return "Belt"
        case "timing_belt", "timing belt": return "Timing"
        case "differential_fluid", "differential fluid": return "Diff."
        case "inspection": return "Inspection"
        case "registration_renewal", "registration renewal": return "Reg."
        case "emissions", "emissions_test": return "Emissions"
        case "recall_repair", "recall repair": return "Recall"
        default: return nil
        }
    }

    private static func labelFromTitle(_ title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("oil") { return "Oil" }
        if lower.contains("tire") || lower.contains("rotation") { return "Tires" }
        if lower.contains("brake") { return "Brakes" }
        if lower.contains("air filter") { return "Air Filter" }
        if lower.contains("cabin") { return "Cabin Filter" }
        if lower.contains("transmission") { return "Trans." }
        if lower.contains("coolant") { return "Coolant" }
        if lower.contains("spark") || lower.contains("plug") { return "Plugs" }
        if lower.contains("battery") { return "Battery" }
        if lower.contains("alignment") { return "Alignment" }
        if lower.contains("wiper") { return "Wipers" }
        if lower.contains("belt") { return "Belt" }
        if lower.contains("differential") { return "Diff." }
        if lower.contains("inspection") { return "Inspection" }
        if lower.contains("registration") { return "Reg." }
        if lower.contains("emission") { return "Emissions" }
        // Fallback: first two words of title
        let words = title.components(separatedBy: " ")
        return words.prefix(2).joined(separator: " ").summarized(maxLength: 10)
    }

    static func iconColor(for task: MaintenanceTaskDBRow) -> Color {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: task.nextDueDate) else { return HavenColors.textTertiary }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days < 0 { return HavenColors.critical }
        if days <= 7 { return HavenColors.warning }
        return HavenColors.navy700
    }
}

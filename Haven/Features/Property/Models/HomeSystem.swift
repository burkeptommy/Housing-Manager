import Foundation

struct HomeSystem: Identifiable, Codable {
    let id: UUID
    var propertyId: UUID
    var name: String
    var category: SystemCategory
    var manufacturer: String?
    var modelNumber: String?
    var serialNumber: String?
    var installDate: Date?
    var expectedLifespan: Int?
    var warranty: Warranty?
    var serviceHistory: [ServiceRecord]
    var maintenanceSchedule: [MaintenanceTask]
    var contractorId: UUID?
    var status: SystemStatus
    var notes: String?
    var imageURLs: [URL]

    var estimatedReplacementYear: Int? {
        guard let installDate = installDate, let lifespan = expectedLifespan else { return nil }
        return Calendar.current.component(.year, from: installDate) + lifespan
    }
}

enum SystemCategory: String, Codable, CaseIterable {
    case hvac = "HVAC"
    case heating = "Heating"
    case cooling = "Air Conditioning"
    case plumbing = "Plumbing"
    case electrical = "Electrical"
    case roofing = "Roofing"
    case siding = "Siding/Exterior"
    case windows = "Windows"
    case doors = "Doors"
    case flooring = "Flooring"
    case appliance = "Appliance"
    case waterHeater = "Water Heater"
    case septic = "Septic System"
    case well = "Well System"
    case pool = "Pool/Spa"
    case irrigation = "Irrigation"
    case security = "Security System"
    case fireProtection = "Fire Protection"
    case elevator = "Elevator"
    case generator = "Generator"
    case solar = "Solar"
    case garage = "Garage Door"
    case landscaping = "Landscaping"
    case pest = "Pest Control"
    case other = "Other"
}

enum SystemStatus: String, Codable {
    case good = "Good"
    case needsMaintenance = "Needs Maintenance"
    case needsRepair = "Needs Repair"
    case needsReplacement = "Needs Replacement"
    case underWarranty = "Under Warranty"
    case outOfService = "Out of Service"
}

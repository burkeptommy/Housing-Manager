import Foundation

// MARK: - Equipment Search Response

struct EquipmentSearchResponse: Codable {
    let query: String
    let count: Int
    let results: [EquipmentSearchResult]
}

struct EquipmentSearchResult: Codable, Identifiable {
    let id: UUID
    let modelNumber: String
    let modelName: String?
    let displayName: String
    let subtitle: String
    let manufacturer: EquipmentManufacturer
    let category: EquipmentCategory
    let specs: EquipmentSpecs
    let scores: EquipmentScores?

    enum CodingKeys: String, CodingKey {
        case id
        case modelNumber = "model_number"
        case modelName = "model_name"
        case displayName = "display_name"
        case subtitle
        case manufacturer
        case category
        case specs
        case scores
    }
}

struct EquipmentManufacturer: Codable {
    let id: UUID
    let name: String
    let slug: String
    let tier: String
}

struct EquipmentScores: Codable {
    let reliability: Int?
    let summary: String?
    let source: String?
}

struct EquipmentCategory: Codable {
    let id: UUID
    let name: String
    let slug: String
    let room: String
}

struct EquipmentSpecs: Codable {
    let series: String?
    let fuelType: String?
    let installationType: String?
    let widthInches: Double?
    let capacity: String?
    let msrp: Double?
    let expectedLifespanYears: Int?
    let isCurrentModel: Bool?
    let keyFeatures: [String]?
    let details: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case series
        case fuelType = "fuel_type"
        case installationType = "installation_type"
        case widthInches = "width_inches"
        case capacity
        case msrp
        case expectedLifespanYears = "expected_lifespan_years"
        case isCurrentModel = "is_current_model"
        case keyFeatures = "key_features"
        case details
    }
}

// MARK: - Photo Identification Response

struct EquipmentIdentifyResponse: Codable {
    let identified: Bool
    let manufacturer: String?
    let modelNumber: String?
    let serialNumber: String?
    let confidence: String?
    let catalogMatch: EquipmentSearchResult?
    let rawText: String?

    enum CodingKeys: String, CodingKey {
        case identified
        case manufacturer
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case confidence
        case catalogMatch = "catalog_match"
        case rawText = "raw_text"
    }
}

// MARK: - AnyCodable helper for JSONB specs

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let string = try? container.decode(String.self) { value = string }
        else { value = "" }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let int = value as? Int { try container.encode(int) }
        else if let double = value as? Double { try container.encode(double) }
        else if let bool = value as? Bool { try container.encode(bool) }
        else if let string = value as? String { try container.encode(string) }
    }
}

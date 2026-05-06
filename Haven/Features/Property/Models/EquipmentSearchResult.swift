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
    // Phase 5 — search-equipment ranking signals
    let matchScore: Int?           // 0-4: how many query signals (capacity/fuel/install/width) align
    let isBestMatch: Bool?         // true when matchScore >= 3 AND >= 3 signals were extracted
    let popularityRank: Int?       // 1-80, lower = more popular within (brand, category)

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
        case matchScore = "match_score"
        case isBestMatch = "is_best_match"
        case popularityRank = "popularity_rank"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.modelNumber = try c.decode(String.self, forKey: .modelNumber)
        self.modelName = try? c.decodeIfPresent(String.self, forKey: .modelName)
        self.displayName = (try? c.decode(String.self, forKey: .displayName)) ?? self.modelNumber
        self.subtitle = (try? c.decode(String.self, forKey: .subtitle)) ?? ""
        self.manufacturer = try c.decode(EquipmentManufacturer.self, forKey: .manufacturer)
        self.category = try c.decode(EquipmentCategory.self, forKey: .category)
        self.specs = (try? c.decode(EquipmentSpecs.self, forKey: .specs)) ?? EquipmentSpecs(
            series: nil, fuelType: nil, installationType: nil,
            widthInches: nil, capacity: nil, msrp: nil,
            expectedLifespanYears: nil, isCurrentModel: nil,
            keyFeatures: nil, details: nil
        )
        self.scores = try? c.decodeIfPresent(EquipmentScores.self, forKey: .scores)
        self.matchScore = try? c.decodeIfPresent(Int.self, forKey: .matchScore)
        self.isBestMatch = try? c.decodeIfPresent(Bool.self, forKey: .isBestMatch)
        self.popularityRank = try? c.decodeIfPresent(Int.self, forKey: .popularityRank)
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
    let productType: String?    // Phase 4 — Claude Vision returns "water heater", "dishwasher" etc.
    let confidence: String?
    let catalogMatch: EquipmentSearchResult?
    let rawText: String?

    enum CodingKeys: String, CodingKey {
        case identified
        case manufacturer
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case productType = "product_type"
        case confidence
        case catalogMatch = "catalog_match"
        case rawText = "raw_text"
    }

    // Resilient decoder — codebase rule: every externally-fed struct uses
    // try? c.decodeIfPresent so one bad field doesn't take the whole payload down.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.identified = (try? c.decode(Bool.self, forKey: .identified)) ?? false
        self.manufacturer = try? c.decodeIfPresent(String.self, forKey: .manufacturer)
        self.modelNumber = try? c.decodeIfPresent(String.self, forKey: .modelNumber)
        self.serialNumber = try? c.decodeIfPresent(String.self, forKey: .serialNumber)
        self.productType = try? c.decodeIfPresent(String.self, forKey: .productType)
        self.confidence = try? c.decodeIfPresent(String.self, forKey: .confidence)
        self.catalogMatch = try? c.decodeIfPresent(EquipmentSearchResult.self, forKey: .catalogMatch)
        self.rawText = try? c.decodeIfPresent(String.self, forKey: .rawText)
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

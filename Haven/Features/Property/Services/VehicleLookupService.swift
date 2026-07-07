import Foundation

final class VehicleLookupService {
    static let shared = VehicleLookupService()
    private init() {}

    // July 2026 (audit F4/F10 — resilient-decoder sweep): these are decoded
    // from the vehicle-lookup Edge Function's NHTSA + Claude passthrough
    // JSON at `callEdgeFunction`'s success path with a hard `try` (no try?).
    // Before this, ONE malformed field (e.g. an interval_miles Claude
    // returned as "5000") threw the WHOLE decode, so a successful NHTSA
    // lookup surfaced as a raw decoding error. Every field is now try?.
    struct VehicleLookupResponse: Codable {
        let vehicle: DecodedVehicle?
        let recalls: [DecodedRecall]?
        let recallCount: Int?
        let maintenanceSchedule: [VehicleMaintenanceInterval]?
        let vinDecoded: Bool?
        let error: String?
        let extractedText: String?
        /// Phase 95 (gap #76): license plate captured from the same
        /// vision pass that extracts the VIN.
        let plate: String?
        let plateState: String?

        enum CodingKeys: String, CodingKey {
            case vehicle, recalls, error, plate
            case recallCount = "recall_count"
            case maintenanceSchedule = "maintenance_schedule"
            case vinDecoded = "vin_decoded"
            case extractedText = "extracted_text"
            case plateState = "plate_state"
        }

        init(from decoder: Decoder) throws {
            let c = try? decoder.container(keyedBy: CodingKeys.self)
            vehicle = try? c?.decodeIfPresent(DecodedVehicle.self, forKey: .vehicle) ?? nil
            recalls = try? c?.decodeIfPresent([DecodedRecall].self, forKey: .recalls) ?? nil
            recallCount = try? c?.decodeIfPresent(Int.self, forKey: .recallCount) ?? nil
            maintenanceSchedule = try? c?.decodeIfPresent([VehicleMaintenanceInterval].self, forKey: .maintenanceSchedule) ?? nil
            vinDecoded = try? c?.decodeIfPresent(Bool.self, forKey: .vinDecoded) ?? nil
            error = try? c?.decodeIfPresent(String.self, forKey: .error) ?? nil
            extractedText = try? c?.decodeIfPresent(String.self, forKey: .extractedText) ?? nil
            plate = try? c?.decodeIfPresent(String.self, forKey: .plate) ?? nil
            plateState = try? c?.decodeIfPresent(String.self, forKey: .plateState) ?? nil
        }
    }

    struct DecodedVehicle: Codable {
        let vin: String?
        let modelYear: String?
        let make: String?
        let model: String?
        let trim: String?
        let bodyClass: String?
        let driveType: String?
        let engineCylinders: String?
        let displacementL: String?
        let fuelType: String?
        let transmission: String?
        let plantCountry: String?

        var year: Int? { modelYear.flatMap { Int($0) } }

        enum CodingKeys: String, CodingKey {
            case vin, make, model, trim, transmission
            case modelYear = "model_year"
            case bodyClass = "body_class"
            case driveType = "drive_type"
            case engineCylinders = "engine_cylinders"
            case displacementL = "displacement_l"
            case fuelType = "fuel_type"
            case plantCountry = "plant_country"
        }

        init(from decoder: Decoder) throws {
            let c = try? decoder.container(keyedBy: CodingKeys.self)
            vin = try? c?.decodeIfPresent(String.self, forKey: .vin) ?? nil
            modelYear = try? c?.decodeIfPresent(String.self, forKey: .modelYear) ?? nil
            make = try? c?.decodeIfPresent(String.self, forKey: .make) ?? nil
            model = try? c?.decodeIfPresent(String.self, forKey: .model) ?? nil
            trim = try? c?.decodeIfPresent(String.self, forKey: .trim) ?? nil
            bodyClass = try? c?.decodeIfPresent(String.self, forKey: .bodyClass) ?? nil
            driveType = try? c?.decodeIfPresent(String.self, forKey: .driveType) ?? nil
            engineCylinders = try? c?.decodeIfPresent(String.self, forKey: .engineCylinders) ?? nil
            displacementL = try? c?.decodeIfPresent(String.self, forKey: .displacementL) ?? nil
            fuelType = try? c?.decodeIfPresent(String.self, forKey: .fuelType) ?? nil
            transmission = try? c?.decodeIfPresent(String.self, forKey: .transmission) ?? nil
            plantCountry = try? c?.decodeIfPresent(String.self, forKey: .plantCountry) ?? nil
        }
    }

    struct DecodedRecall: Codable {
        let nhtsaCampaignNumber: String?
        let component: String?
        let summary: String?
        let consequence: String?
        let remedy: String?
        let reportDate: String?
        let manufacturer: String?

        enum CodingKeys: String, CodingKey {
            case component, summary, consequence, remedy, manufacturer
            case nhtsaCampaignNumber = "nhtsa_campaign_number"
            case reportDate = "report_date"
        }

        init(from decoder: Decoder) throws {
            let c = try? decoder.container(keyedBy: CodingKeys.self)
            nhtsaCampaignNumber = try? c?.decodeIfPresent(String.self, forKey: .nhtsaCampaignNumber) ?? nil
            component = try? c?.decodeIfPresent(String.self, forKey: .component) ?? nil
            summary = try? c?.decodeIfPresent(String.self, forKey: .summary) ?? nil
            consequence = try? c?.decodeIfPresent(String.self, forKey: .consequence) ?? nil
            remedy = try? c?.decodeIfPresent(String.self, forKey: .remedy) ?? nil
            reportDate = try? c?.decodeIfPresent(String.self, forKey: .reportDate) ?? nil
            manufacturer = try? c?.decodeIfPresent(String.self, forKey: .manufacturer) ?? nil
        }
    }

    /// Look up a vehicle by VIN string
    func lookup(vin: String) async throws -> VehicleLookupResponse {
        try await callEdgeFunction(body: ["vin": vin])
    }

    /// Look up a vehicle from a photo of the VIN (base64 JPEG)
    func lookup(imageBase64: String) async throws -> VehicleLookupResponse {
        try await callEdgeFunction(body: ["image_base64": imageBase64])
    }

    private func callEdgeFunction(body: [String: String]) async throws -> VehicleLookupResponse {
        let url = URL(string: "\(AppConfig.Supabase.url)/functions/v1/vehicle-lookup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "apikey")

        if let accessToken = try? await HavenSupabase.auth.session.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            let decoded = try? JSONDecoder().decode(VehicleLookupResponse.self, from: data)
            throw NSError(domain: "VehicleLookup", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: decoded?.error ?? "Vehicle lookup failed"
            ])
        }

        return try JSONDecoder().decode(VehicleLookupResponse.self, from: data)
    }
}

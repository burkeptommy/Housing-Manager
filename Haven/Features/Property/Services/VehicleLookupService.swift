import Foundation

final class VehicleLookupService {
    static let shared = VehicleLookupService()
    private init() {}

    struct VehicleLookupResponse: Codable {
        let vehicle: DecodedVehicle?
        let recalls: [DecodedRecall]?
        let recallCount: Int?
        let maintenanceSchedule: [VehicleMaintenanceInterval]?
        let vinDecoded: Bool?
        let error: String?
        let extractedText: String?

        enum CodingKeys: String, CodingKey {
            case vehicle, recalls, error
            case recallCount = "recall_count"
            case maintenanceSchedule = "maintenance_schedule"
            case vinDecoded = "vin_decoded"
            case extractedText = "extracted_text"
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

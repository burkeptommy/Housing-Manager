import Foundation

struct PlaceSuggestion: Identifiable {
    let id = UUID()
    let placeId: String
    let mainText: String
    let secondaryText: String
}

struct PlaceAddress {
    var street: String = ""
    var unit: String = ""
    var city: String = ""
    var state: String = ""
    var zipCode: String = ""
    var country: String = ""
}

final class GooglePlacesService {
    static let shared = GooglePlacesService()
    private let apiKey = AppConfig.Google.placesAPIKey
    private let session = URLSession.shared

    private init() {}

    // MARK: - Autocomplete

    func autocomplete(query: String) async throws -> [PlaceSuggestion] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        let url = URL(string: "https://places.googleapis.com/v1/places:autocomplete")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")

        let body: [String: Any] = [
            "input": query,
            "includedPrimaryTypes": ["street_address", "subpremise", "premise"],
            "includedRegionCodes": ["us"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            print("[GooglePlaces] API error \(httpResponse.statusCode): \(body)")
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let suggestions = json?["suggestions"] as? [[String: Any]] else {
            return []
        }

        return suggestions.compactMap { suggestion in
            guard let placePrediction = suggestion["placePrediction"] as? [String: Any],
                  let placeId = placePrediction["placeId"] as? String,
                  let structuredFormat = placePrediction["structuredFormat"] as? [String: Any],
                  let mainText = (structuredFormat["mainText"] as? [String: Any])?["text"] as? String,
                  let secondaryText = (structuredFormat["secondaryText"] as? [String: Any])?["text"] as? String
            else { return nil }

            return PlaceSuggestion(placeId: placeId, mainText: mainText, secondaryText: secondaryText)
        }
    }

    // MARK: - Place Details

    func placeDetails(placeId: String) async throws -> PlaceAddress {
        let url = URL(string: "https://places.googleapis.com/v1/places/\(placeId)")!

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("addressComponents", forHTTPHeaderField: "X-Goog-FieldMask")

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            print("[GooglePlaces] Details API error \(httpResponse.statusCode): \(body)")
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let addressComponents = json?["addressComponents"] as? [[String: Any]] else {
            return PlaceAddress()
        }

        var streetNumber = ""
        var route = ""
        var address = PlaceAddress()

        for component in addressComponents {
            guard let types = component["types"] as? [String],
                  let longText = component["longText"] as? String else { continue }
            let shortText = (component["shortText"] as? String) ?? longText

            for type in types {
                switch type {
                case "street_number":
                    streetNumber = longText
                case "route":
                    route = longText
                case "subpremise":
                    address.unit = longText
                case "locality":
                    address.city = longText
                case "administrative_area_level_1":
                    address.state = shortText
                case "postal_code":
                    address.zipCode = longText
                case "country":
                    address.country = shortText
                default:
                    break
                }
            }
        }

        address.street = [streetNumber, route]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return address
    }
}

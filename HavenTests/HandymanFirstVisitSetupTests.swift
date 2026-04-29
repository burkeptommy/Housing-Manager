import XCTest
@testable import Haven

@MainActor
final class HandymanFirstVisitSetupTests: XCTestCase {

    func test_firstVisitSetupRecommended_whenSystemsAreMissing_returnsTrue() throws {
        let property = try makeProperty(squareFootage: 5200)

        XCTAssertTrue(
            HandymanVisitService.isFirstVisitSetupRecommended(
                systems: [],
                property: property
            )
        )

        let prompts = HandymanVisitService.setupPrompts(
            systems: [],
            property: property
        )

        XCTAssertTrue(prompts.contains(where: { $0.id == "inventory" }))
        XCTAssertTrue(prompts.contains(where: { $0.id == "labels" }))
        XCTAssertTrue(prompts.contains(where: { $0.id == "install_dates" }))
        XCTAssertTrue(prompts.contains(where: { $0.id == "filters_shutoffs" }))
        XCTAssertTrue(prompts.contains(where: { $0.id == "manuals" }))
    }

    func test_firstVisitSetupRecommended_whenCoreSystemsAreDocumented_returnsFalse() throws {
        let property = try makeProperty(squareFootage: 4200)
        let systems = try [
            makeSystem(name: "Main HVAC", category: "HVAC"),
            makeSystem(name: "Kitchen Fridge", category: "Appliance"),
            makeSystem(name: "Water Heater", category: "Water Heater"),
            makeSystem(name: "Main Plumbing", category: "Plumbing"),
            makeSystem(name: "Main Panel", category: "Electrical"),
        ]

        XCTAssertFalse(
            HandymanVisitService.isFirstVisitSetupRecommended(
                systems: systems,
                property: property
            )
        )

        let prompts = HandymanVisitService.setupPrompts(
            systems: systems,
            property: property
        )

        XCTAssertFalse(prompts.contains(where: { $0.id == "inventory" }))
        XCTAssertFalse(prompts.contains(where: { $0.id == "labels" }))
        XCTAssertFalse(prompts.contains(where: { $0.id == "install_dates" }))
        XCTAssertTrue(prompts.contains(where: { $0.id == "filters_shutoffs" }))
        XCTAssertTrue(prompts.contains(where: { $0.id == "manuals" }))
    }

    func test_setupPrompts_requestsLabelCapture_whenIdentityIsIncomplete() throws {
        let property = try makeProperty(squareFootage: 2800)
        let systems = try [
            makeSystem(
                name: "Main HVAC",
                category: "HVAC",
                manufacturer: "Carrier",
                modelNumber: "ABC123",
                serialNumber: nil
            )
        ]

        let prompts = HandymanVisitService.setupPrompts(
            systems: systems,
            property: property
        )

        XCTAssertTrue(prompts.contains(where: { $0.id == "labels" }))
    }

    private func makeProperty(squareFootage: Int) throws -> PropertyRow {
        let json: [String: Any] = [
            "id": UUID().uuidString,
            "household_id": UUID().uuidString,
            "name": "River House",
            "property_type": "Single Family Home",
            "street": "16 Harbor Lane",
            "city": "Greenwich",
            "state": "CT",
            "square_footage": squareFootage,
            "year_built": 2007,
        ]
        return try decode(PropertyRow.self, from: json)
    }

    private func makeSystem(
        name: String,
        category: String,
        manufacturer: String = "Brand",
        modelNumber: String? = "MODEL-1",
        serialNumber: String? = "SERIAL-1",
        installDate: String? = "2021-05-01"
    ) throws -> HomeSystemRow {
        var json: [String: Any] = [
            "id": UUID().uuidString,
            "property_id": UUID().uuidString,
            "household_id": UUID().uuidString,
            "name": name,
            "category": category,
            "manufacturer": manufacturer,
        ]
        if let modelNumber {
            json["model_number"] = modelNumber
        }
        if let serialNumber {
            json["serial_number"] = serialNumber
        }
        if let installDate {
            json["install_date"] = installDate
        }
        return try decode(HomeSystemRow.self, from: json)
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: [String: Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}

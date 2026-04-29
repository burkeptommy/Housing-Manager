import XCTest
@testable import Haven

@MainActor
final class HandymanCoordinationTests: XCTestCase {

    func test_coordinationSummary_flagsHomeownerReplyStatuses() throws {
        let request = try decode(
            HandymanRequestRow.self,
            from: [
                "id": UUID().uuidString,
                "household_id": UUID().uuidString,
                "request_type": "standard_visit",
                "source": "homeowner",
                "title": "Confirm Spring Handyman Visit",
                "urgency": "routine",
                "status": "alternate_dates_proposed",
                "first_visit_setup_requested": true,
                "quick_upsell_titles": [],
                "created_at": "2026-04-23T14:20:00Z",
                "updated_at": "2026-04-23T14:25:00Z",
            ]
        )

        XCTAssertEqual(request.typedStatus, .alternateDatesProposed)
        XCTAssertTrue(request.typedStatus.actionRequiredByHomeowner)
        XCTAssertEqual(
            HandymanVisitService.coordinationSummary(for: request),
            "The handyman asked for different timing."
        )
    }

    func test_portalSeedPayload_decodesLegacyRows_withoutNewFields() throws {
        let payload = try decode(
            HandymanPortalSeedPayload.self,
            from: [
                "visit_id": UUID().uuidString,
                "visit_title": "Spring Handyman Visit",
                "scheduled_date": "2026-04-25",
                "due_date": "2026-04-25",
                "first_visit": true,
                "property": [
                    "name": "River House",
                    "address_line": "16 Harbor Lane",
                    "property_type": "Single Family Home",
                    "square_footage": 6400,
                    "year_built": 2007,
                    "system_count": 2,
                    "known_systems": ["HVAC", "Water Heater"],
                ],
                "contractor_name": "North Shore Handyman Co.",
                "checklist": [],
                "diy_claims": [],
                "quick_upsells": [],
                "setup_prompts": [],
            ]
        )

        XCTAssertNil(payload.coordination)
        XCTAssertNil(payload.recommendations)
        XCTAssertNil(payload.property.systems)
        XCTAssertEqual(payload.property.knownSystems.count, 2)
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: [String: Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}

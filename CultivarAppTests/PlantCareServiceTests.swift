import XCTest

#if canImport(Cultivar)
@testable import Cultivar
#elseif canImport(CultivarApp)
@testable import CultivarApp
#endif

@MainActor
final class PlantCareServiceTests: XCTestCase {
    func testRecordWateringCreatesLogAndUpdatesLastWatered() {
        let plant = Plant(nickname: "Test Plant")
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)

        PlantCareService.recordCare(
            for: plant,
            careType: .watering,
            notes: "Weekly water",
            soilMoisture: .dry,
            amountMl: 250,
            at: timestamp
        )

        XCTAssertEqual(plant.careLogs.count, 1)
        XCTAssertEqual(plant.lastWatered, timestamp)
        XCTAssertEqual(plant.careLogs.first?.careType, .watering)
        XCTAssertEqual(plant.careLogs.first?.soilMoisture, .dry)
        guard let amountMl = plant.careLogs.first?.amountMl else {
            return XCTFail("Expected amountMl to be set")
        }
        XCTAssertEqual(amountMl, 250, accuracy: 0.0001)
    }

    func testRecordFertilizingTrimsProductNameAndUpdatesDate() {
        let plant = Plant(nickname: "Fert Test")
        let timestamp = Date(timeIntervalSince1970: 1_700_100_000)

        PlantCareService.recordCare(
            for: plant,
            careType: .fertilizing,
            fertiliserUsed: "  Fish Emulsion  ",
            at: timestamp
        )

        XCTAssertEqual(plant.careLogs.count, 1)
        XCTAssertEqual(plant.lastFertilized, timestamp)
        XCTAssertEqual(plant.careLogs.first?.fertiliserUsed, "Fish Emulsion")
        XCTAssertNil(plant.careLogs.first?.soilMoisture)
    }
}

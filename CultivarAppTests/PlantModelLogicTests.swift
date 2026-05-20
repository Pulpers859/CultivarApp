import XCTest

#if canImport(Cultivar)
@testable import Cultivar
#elseif canImport(CultivarApp)
@testable import CultivarApp
#endif

final class PlantModelLogicTests: XCTestCase {
    func testDaysUntilWaterWhenNeverWateredDefaultsToDueNow() {
        let plant = Plant(nickname: "Monstera")
        plant.lastWatered = nil

        XCTAssertEqual(plant.daysUntilWater, 0)
        XCTAssertTrue(plant.isDueForWaterToday)
    }

    func testDaysUntilWaterOverdueAfterIntervalPasses() {
        let plant = Plant(nickname: "Pothos", wateringIntervalDays: 7)
        plant.lastWatered = Calendar.current.date(byAdding: .day, value: -10, to: Date())

        XCTAssertTrue(plant.isOverdueForWater)
        XCTAssertTrue((plant.daysUntilWater ?? 0) < 0)
    }

    func testNextWateringDateWhenNeverWateredIsNearNow() {
        let plant = Plant(nickname: "Snake Plant")
        plant.lastWatered = nil

        guard let next = plant.nextWateringDate else {
            return XCTFail("Expected next watering date")
        }

        XCTAssertLessThan(abs(next.timeIntervalSinceNow), 2)
    }

    func testDaysOwnedReflectsAcquisitionDate() {
        let plant = Plant(nickname: "Fiddle Leaf")
        plant.acquisitionDate = Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()

        XCTAssertGreaterThanOrEqual(plant.daysOwned, 9)
        XCTAssertLessThanOrEqual(plant.daysOwned, 11)
    }
}

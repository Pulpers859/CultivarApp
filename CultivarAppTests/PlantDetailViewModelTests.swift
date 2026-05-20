import XCTest

#if canImport(Cultivar)
@testable import Cultivar
#elseif canImport(CultivarApp)
@testable import CultivarApp
#endif

@MainActor
final class PlantDetailViewModelTests: XCTestCase {
    func testToggleFavoriteFlipsFlag() {
        let viewModel = PlantDetailViewModel()
        let plant = Plant(nickname: "Test")
        plant.isFavorite = false

        viewModel.toggleFavorite(for: plant)
        XCTAssertTrue(plant.isFavorite)

        viewModel.toggleFavorite(for: plant)
        XCTAssertFalse(plant.isFavorite)
    }

    func testQuickWaterCreatesLogAndSetsLastWatered() {
        let viewModel = PlantDetailViewModel()
        let plant = Plant(nickname: "Water Test")

        viewModel.quickWater(for: plant)

        XCTAssertEqual(plant.careLogs.count, 1)
        XCTAssertEqual(plant.careLogs.first?.careType, .watering)
        XCTAssertNotNil(plant.lastWatered)
    }

    func testQuickFertilizeCreatesLogAndSetsLastFertilized() {
        let viewModel = PlantDetailViewModel()
        let plant = Plant(nickname: "Fert Test")

        viewModel.quickFertilize(for: plant)

        XCTAssertEqual(plant.careLogs.count, 1)
        XCTAssertEqual(plant.careLogs.first?.careType, .fertilizing)
        XCTAssertNotNil(plant.lastFertilized)
    }
}

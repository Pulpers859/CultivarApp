import XCTest
import SwiftData

#if canImport(Cultivar)
@testable import Cultivar
#elseif canImport(CultivarApp)
@testable import CultivarApp
#endif

@MainActor
final class PlantBackupServiceTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Plant.self,
            CareLog.self,
            GrowthEntry.self,
            PropagationRecord.self,
            EnvironmentReading.self,
            WishlistItem.self,
            PlantTrade.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func testSnapshotRoundTripRestoresPlantsAndRelatedData() throws {
        let sourceContainer = try makeContainer()
        let sourceContext = ModelContext(sourceContainer)

        let plant = Plant(
            nickname: "Monstera",
            species: "Monstera deliciosa",
            commonName: "Swiss Cheese Plant",
            emoji: "🪴",
            roomLocation: "Living Room",
            lightLevel: .indirect,
            wateringIntervalDays: 9
        )
        plant.notes = "Fenestrating nicely"
        plant.careLogs = [
            CareLog(careType: .watering, notes: "Deep watering"),
            CareLog(careType: .fertilizing, notes: "Monthly feed")
        ]
        plant.growthEntries = [
            GrowthEntry(heightCm: 42, leafCount: 8, notes: "New leaf")
        ]
        plant.propagations = [
            PropagationRecord(method: .stemCutting, numberOfCuttings: 2, rootingMedium: "Water")
        ]
        plant.environmentReadings = [
            EnvironmentReading(roomName: "Living Room", temperatureCelsius: 23, humidityPercent: 55, lightLux: 850)
        ]

        let wishlistItem = WishlistItem(plantName: "Alocasia Frydek", species: "Alocasia micholitziana", priority: .high)
        let trade = PlantTrade(tradeType: .purchase, plantName: "Monstera deliciosa")
        trade.counterpartyName = "Plant Shop"

        sourceContext.insert(plant)
        sourceContext.insert(wishlistItem)
        sourceContext.insert(trade)
        try sourceContext.save()

        let snapshot = PlantBackupService.makeSnapshot(
            appName: "Cultivar",
            plants: try sourceContext.fetch(FetchDescriptor<Plant>()),
            wishlistItems: try sourceContext.fetch(FetchDescriptor<WishlistItem>()),
            trades: try sourceContext.fetch(FetchDescriptor<PlantTrade>())
        )

        let destinationContainer = try makeContainer()
        let destinationContext = ModelContext(destinationContainer)
        let result = try PlantBackupService.restore(snapshot: snapshot, modelContext: destinationContext)

        let restoredPlants = try destinationContext.fetch(FetchDescriptor<Plant>())
        let restoredWishlist = try destinationContext.fetch(FetchDescriptor<WishlistItem>())
        let restoredTrades = try destinationContext.fetch(FetchDescriptor<PlantTrade>())

        XCTAssertEqual(result.restoredAppName, "Cultivar")
        XCTAssertEqual(result.plantCount, 1)
        XCTAssertEqual(restoredPlants.count, 1)
        XCTAssertEqual(restoredPlants.first?.nickname, "Monstera")
        XCTAssertEqual(restoredPlants.first?.careLogs.count, 2)
        XCTAssertEqual(restoredPlants.first?.growthEntries.count, 1)
        XCTAssertEqual(restoredPlants.first?.propagations.count, 1)
        XCTAssertEqual(restoredPlants.first?.environmentReadings.count, 1)
        XCTAssertEqual(restoredWishlist.count, 1)
        XCTAssertEqual(restoredWishlist.first?.plantName, "Alocasia Frydek")
        XCTAssertEqual(restoredTrades.count, 1)
        XCTAssertEqual(restoredTrades.first?.counterpartyName, "Plant Shop")
    }
}

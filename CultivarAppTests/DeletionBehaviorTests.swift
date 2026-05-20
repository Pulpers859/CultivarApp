import XCTest
import SwiftData

#if canImport(Cultivar)
@testable import Cultivar
#elseif canImport(CultivarApp)
@testable import CultivarApp
#endif

@MainActor
final class DeletionBehaviorTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Plant.self,
            CareLog.self,
            GrowthEntry.self,
            PropagationRecord.self,
            EnvironmentReading.self,
            WishlistItem.self,
            PlantTrade.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func testDeletingPlantCascadesAllRelatedHistory() throws {
        let plant = Plant(nickname: "Cascade Test")
        plant.careLogs.append(CareLog(careType: .watering, notes: "Watered"))
        plant.growthEntries.append(GrowthEntry(heightCm: 12.5, leafCount: 5, notes: "Growth"))
        plant.propagations.append(PropagationRecord(method: .stemCutting, numberOfCuttings: 2, rootingMedium: "Water"))
        plant.environmentReadings.append(EnvironmentReading(roomName: "Office", temperatureCelsius: 24))

        context.insert(plant)
        try context.save()

        context.delete(plant)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<Plant>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<CareLog>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<GrowthEntry>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<PropagationRecord>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<EnvironmentReading>()).count, 0)
    }

    func testDeletingSingleCareLogKeepsSiblingEntries() throws {
        let plant = Plant(nickname: "Sibling Test")
        let logToDelete = CareLog(careType: .watering, notes: "Delete me")
        let remainingLog = CareLog(careType: .fertilizing, notes: "Keep me")
        let growthEntry = GrowthEntry(heightCm: 22, leafCount: 8, notes: "Keep growth")
        let propagation = PropagationRecord(method: .division, numberOfCuttings: 1, rootingMedium: "Soil")

        plant.careLogs.append(logToDelete)
        plant.careLogs.append(remainingLog)
        plant.growthEntries.append(growthEntry)
        plant.propagations.append(propagation)

        context.insert(plant)
        try context.save()

        context.delete(logToDelete)
        try context.save()

        let careLogs = try context.fetch(FetchDescriptor<CareLog>())
        let growthEntries = try context.fetch(FetchDescriptor<GrowthEntry>())
        let propagations = try context.fetch(FetchDescriptor<PropagationRecord>())

        XCTAssertEqual(careLogs.count, 1)
        XCTAssertEqual(careLogs.first?.id, remainingLog.id)
        XCTAssertEqual(growthEntries.count, 1)
        XCTAssertEqual(growthEntries.first?.id, growthEntry.id)
        XCTAssertEqual(propagations.count, 1)
        XCTAssertEqual(propagations.first?.id, propagation.id)
    }
}

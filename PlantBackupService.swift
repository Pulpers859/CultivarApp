import Foundation
import SwiftData

struct PlantBackupRestoreResult {
    let restoredAppName: String?
    let plantCount: Int
    let wishlistItemCount: Int
    let tradeCount: Int
}

enum PlantBackupService {
    static func snapshotContainsUserData(_ snapshot: PlantBackupSnapshot) -> Bool {
        !snapshot.plants.isEmpty || !snapshot.wishlistItems.isEmpty || !snapshot.trades.isEmpty
    }

    static func makeSnapshot(
        appName: String,
        plants: [Plant],
        wishlistItems: [WishlistItem],
        trades: [PlantTrade]
    ) -> PlantBackupSnapshot {
        PlantBackupSnapshot(
            exportedAt: Date(),
            appName: appName,
            plants: plants.map(PlantBackupPlant.init),
            wishlistItems: wishlistItems.map(PlantBackupWishlistItem.init),
            trades: trades.map(PlantBackupTrade.init)
        )
    }

    @MainActor
    static func restore(
        snapshot: PlantBackupSnapshot,
        modelContext: ModelContext
    ) throws -> PlantBackupRestoreResult {
        let existingPlants = try modelContext.fetch(FetchDescriptor<Plant>())
        let existingWishlistItems = try modelContext.fetch(FetchDescriptor<WishlistItem>())
        let existingTrades = try modelContext.fetch(FetchDescriptor<PlantTrade>())

        for backupPlant in snapshot.plants {
            if let existingPlant = existingPlants.first(where: { $0.id == backupPlant.id }) {
                apply(backupPlant, to: existingPlant, modelContext: modelContext)
            } else {
                let plant = makePlant(from: backupPlant, modelContext: modelContext)
                modelContext.insert(plant)
            }
        }

        for backupWishlistItem in snapshot.wishlistItems {
            if let existingWishlistItem = existingWishlistItems.first(where: { $0.id == backupWishlistItem.id }) {
                apply(backupWishlistItem, to: existingWishlistItem)
            } else {
                let wishlistItem = makeWishlistItem(from: backupWishlistItem)
                modelContext.insert(wishlistItem)
            }
        }

        for backupTrade in snapshot.trades {
            if let existingTrade = existingTrades.first(where: { $0.id == backupTrade.id }) {
                apply(backupTrade, to: existingTrade)
            } else {
                let trade = makeTrade(from: backupTrade)
                modelContext.insert(trade)
            }
        }

        try modelContext.save()

        let normalizedAppName = snapshot.appName.trimmingCharacters(in: .whitespacesAndNewlines)
        return PlantBackupRestoreResult(
            restoredAppName: normalizedAppName.isEmpty ? nil : normalizedAppName,
            plantCount: snapshot.plants.count,
            wishlistItemCount: snapshot.wishlistItems.count,
            tradeCount: snapshot.trades.count
        )
    }

    @MainActor
    static func currentStoreIsEmpty(modelContext: ModelContext) throws -> Bool {
        let plants = try modelContext.fetch(FetchDescriptor<Plant>())
        let wishlistItems = try modelContext.fetch(FetchDescriptor<WishlistItem>())
        let trades = try modelContext.fetch(FetchDescriptor<PlantTrade>())
        return plants.isEmpty && wishlistItems.isEmpty && trades.isEmpty
    }

    private static func apply(_ backupPlant: PlantBackupPlant, to plant: Plant, modelContext: ModelContext) {
        plant.careLogs.forEach { modelContext.delete($0) }
        plant.growthEntries.forEach { modelContext.delete($0) }
        plant.propagations.forEach { modelContext.delete($0) }
        plant.environmentReadings.forEach { modelContext.delete($0) }

        plant.id = backupPlant.id
        plant.nickname = backupPlant.nickname
        plant.species = backupPlant.species
        plant.commonName = backupPlant.commonName
        plant.emoji = backupPlant.emoji
        plant.photoData = backupPlant.photoData
        plant.acquisitionDate = backupPlant.acquisitionDate
        plant.birthdate = backupPlant.birthdate
        plant.roomLocation = backupPlant.roomLocation
        plant.lightLevel = LightLevel(rawValue: backupPlant.lightLevel) ?? .indirect
        plant.isOutdoor = backupPlant.isOutdoor
        plant.wateringIntervalDays = backupPlant.wateringIntervalDays
        plant.fertilizingIntervalDays = backupPlant.fertilizingIntervalDays
        plant.repottingIntervalDays = backupPlant.repottingIntervalDays
        plant.pruningIntervalDays = backupPlant.pruningIntervalDays
        plant.lastWatered = backupPlant.lastWatered
        plant.lastFertilized = backupPlant.lastFertilized
        plant.lastRepotted = backupPlant.lastRepotted
        plant.lastPruned = backupPlant.lastPruned
        plant.currentHeightCm = backupPlant.currentHeightCm
        plant.currentLeafCount = backupPlant.currentLeafCount
        plant.potSizeCm = backupPlant.potSizeCm
        plant.soilType = backupPlant.soilType
        plant.parentPlantID = backupPlant.parentPlantID
        plant.parentPlantNickname = backupPlant.parentPlantNickname
        plant.healthStatus = HealthStatus(rawValue: backupPlant.healthStatus) ?? .healthy
        plant.activeIssues = backupPlant.activeIssues
        plant.notes = backupPlant.notes
        plant.speciesCareSummary = backupPlant.speciesCareSummary
        plant.isFavorite = backupPlant.isFavorite
        plant.tags = backupPlant.tags
        plant.dateAdded = backupPlant.dateAdded

        plant.careLogs = backupPlant.careLogs.map(makeCareLog(from:))
        plant.growthEntries = backupPlant.growthEntries.map(makeGrowthEntry(from:))
        plant.propagations = backupPlant.propagations.map(makePropagation(from:))
        plant.environmentReadings = backupPlant.environmentReadings.map(makeEnvironmentReading(from:))
        plant.refreshTrackedCareDates()
    }

    private static func makePlant(from backupPlant: PlantBackupPlant, modelContext: ModelContext) -> Plant {
        let plant = Plant(
            nickname: backupPlant.nickname,
            species: backupPlant.species,
            commonName: backupPlant.commonName,
            emoji: backupPlant.emoji,
            roomLocation: backupPlant.roomLocation,
            lightLevel: LightLevel(rawValue: backupPlant.lightLevel) ?? .indirect
        )
        apply(backupPlant, to: plant, modelContext: modelContext)
        return plant
    }

    private static func makeCareLog(from backupLog: PlantBackupCareLog) -> CareLog {
        let log = CareLog(
            careType: CareType(rawValue: backupLog.careType) ?? .observation,
            notes: backupLog.notes,
            soilMoisture: backupLog.soilMoisture.flatMap(SoilMoisture.init(rawValue:))
        )
        log.id = backupLog.id
        log.date = backupLog.date
        log.photoData = backupLog.photoData
        log.fertiliserUsed = backupLog.fertiliserUsed
        log.amountMl = backupLog.amountMl
        return log
    }

    private static func makeGrowthEntry(from backupEntry: PlantBackupGrowthEntry) -> GrowthEntry {
        let entry = GrowthEntry(
            heightCm: backupEntry.heightCm,
            leafCount: backupEntry.leafCount,
            notes: backupEntry.notes,
            milestone: backupEntry.milestone
        )
        entry.id = backupEntry.id
        entry.date = backupEntry.date
        entry.stemCount = backupEntry.stemCount
        entry.photoData = backupEntry.photoData
        return entry
    }

    private static func makePropagation(from backupPropagation: PlantBackupPropagation) -> PropagationRecord {
        let record = PropagationRecord(
            method: PropagationMethod(rawValue: backupPropagation.method) ?? .stemCutting,
            numberOfCuttings: backupPropagation.numberOfCuttings,
            rootingMedium: backupPropagation.rootingMedium
        )
        record.id = backupPropagation.id
        record.dateStarted = backupPropagation.dateStarted
        record.rootedDate = backupPropagation.rootedDate
        record.pottedDate = backupPropagation.pottedDate
        record.successCount = backupPropagation.successCount
        record.notes = backupPropagation.notes
        record.photoData = backupPropagation.photoData
        record.childPlantIDs = backupPropagation.childPlantIDs
        return record
    }

    private static func makeEnvironmentReading(from backupReading: PlantBackupEnvironmentReading) -> EnvironmentReading {
        let reading = EnvironmentReading(
            roomName: backupReading.roomName,
            temperatureCelsius: backupReading.temperatureCelsius,
            humidityPercent: backupReading.humidityPercent,
            lightLux: backupReading.lightLux
        )
        reading.id = backupReading.id
        reading.date = backupReading.date
        reading.notes = backupReading.notes
        return reading
    }

    private static func apply(_ backupWishlistItem: PlantBackupWishlistItem, to item: WishlistItem) {
        item.id = backupWishlistItem.id
        item.plantName = backupWishlistItem.plantName
        item.species = backupWishlistItem.species
        item.notes = backupWishlistItem.notes
        item.priority = WishlistPriority(rawValue: backupWishlistItem.priority) ?? .medium
        item.dateAdded = backupWishlistItem.dateAdded
        item.priceTarget = backupWishlistItem.priceTarget
        item.sourceURL = backupWishlistItem.sourceURL
        item.photoData = backupWishlistItem.photoData
        item.isAcquired = backupWishlistItem.isAcquired
        item.acquiredDate = backupWishlistItem.acquiredDate
    }

    private static func makeWishlistItem(from backupWishlistItem: PlantBackupWishlistItem) -> WishlistItem {
        let item = WishlistItem(
            plantName: backupWishlistItem.plantName,
            species: backupWishlistItem.species,
            priority: WishlistPriority(rawValue: backupWishlistItem.priority) ?? .medium
        )
        apply(backupWishlistItem, to: item)
        return item
    }

    private static func apply(_ backupTrade: PlantBackupTrade, to trade: PlantTrade) {
        trade.id = backupTrade.id
        trade.date = backupTrade.date
        trade.tradeType = TradeType(rawValue: backupTrade.tradeType) ?? .purchase
        trade.plantName = backupTrade.plantName
        trade.counterpartyName = backupTrade.counterpartyName
        trade.notes = backupTrade.notes
        trade.pricePaid = backupTrade.pricePaid
        trade.plantOffered = backupTrade.plantOffered
    }

    private static func makeTrade(from backupTrade: PlantBackupTrade) -> PlantTrade {
        let trade = PlantTrade(
            tradeType: TradeType(rawValue: backupTrade.tradeType) ?? .purchase,
            plantName: backupTrade.plantName
        )
        apply(backupTrade, to: trade)
        return trade
    }
}

struct AutomaticBackupMetadata {
    let date: Date
    let plantCount: Int
}

enum AutomaticBackupService {
    private static let lastBackupDateKey = "auto_backup_last_date"
    private static let lastBackupPlantCountKey = "auto_backup_plant_count"

    static func save(snapshot: PlantBackupSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: backupURL(), options: .atomic)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastBackupDateKey)
        UserDefaults.standard.set(snapshot.plants.count, forKey: lastBackupPlantCountKey)
    }

    static func lastBackupMetadata() -> AutomaticBackupMetadata? {
        let timestamp = UserDefaults.standard.double(forKey: lastBackupDateKey)
        guard timestamp > 0 else { return nil }
        return AutomaticBackupMetadata(
            date: Date(timeIntervalSince1970: timestamp),
            plantCount: UserDefaults.standard.integer(forKey: lastBackupPlantCountKey)
        )
    }

    static func loadSnapshot() throws -> PlantBackupSnapshot? {
        let url = try backupURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PlantBackupSnapshot.self, from: data)
    }

    static func deleteBackup() throws {
        let url = try backupURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        try FileManager.default.removeItem(at: url)
    }

    private static func backupURL() throws -> URL {
        let fileManager = FileManager.default
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = applicationSupport.appendingPathComponent("Cultivar", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        return directory.appendingPathComponent("AutomaticBackup.json")
    }
}

// SettingsView.swift

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var plants: [Plant]
    @Query private var wishlistItems: [WishlistItem]
    @Query private var plantTrades: [PlantTrade]

    @AppStorage("use_celsius") private var useCelsius: Bool = true
    @AppStorage("notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("app_name") private var appName: String = "Cultivar"

    @State private var showResetConfirm: Bool = false
    @State private var showBackupExporter: Bool = false
    @State private var showBackupImporter: Bool = false
    @State private var backupDocument: PlantBackupDocument = .empty
    @State private var importMessage: String = ""
    @State private var showImportResult: Bool = false
    @State private var lastBackupMetadata: AutomaticBackupMetadata? = AutomaticBackupService.lastBackupMetadata()

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 4) {
                            Text("🌿")
                                .font(.system(size: 48))
                            Text(appName)
                                .font(CultivarFont.oldGrowth(24))
                                .foregroundColor(.mushroomCream)
                            Text("Your Living Plant Sanctuary")
                                .font(CultivarFont.undergrowth(13))
                                .foregroundColor(.stoneGrey)
                        }
                        .padding(.top, 16)

                        // App Name
                        FormSection(title: "App Name", icon: "pencil") {
                            CultivarFormField(label: "What do you call your grove?", placeholder: "e.g. Cultivar, The Grove, Leafkeep...", text: $appName)
                        }

                        // AI Advisor
                        FormSection(title: "AI Grove Keeper", icon: "waveform.path.ecg") {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Config.hasAnthropicKey ? Color.mossGreen : Color.petalCoral)
                                    .frame(width: 7, height: 7)
                                Text(Config.hasAnthropicKey ? "AI features active" : "API key not configured — AI features disabled")
                                    .font(CultivarFont.undergrowth(11))
                                    .foregroundColor(Config.hasAnthropicKey ? .mossGreen : .petalCoral)
                            }

                            if !Config.hasAnthropicKey {
                                Text("Set your Anthropic API key via the ANTHROPIC_API_KEY environment variable or Info.plist entry.")
                                    .font(CultivarFont.undergrowth(11))
                                    .foregroundColor(.stoneGrey.opacity(0.6))
                            }
                        }

                        // Preferences
                        FormSection(title: "Preferences", icon: "slider.horizontal.3") {
                            Toggle(isOn: $useCelsius) {
                                HStack {
                                    Image(systemName: "thermometer.medium").foregroundColor(.petalCoral)
                                    Text("Temperature in Celsius")
                                        .font(CultivarFont.undergrowth(14))
                                        .foregroundColor(.mushroomCream)
                                }
                            }
                            .tint(.mossGreen)

                            Toggle(isOn: $notificationsEnabled) {
                                HStack {
                                    Image(systemName: "bell.fill").foregroundColor(.goldenPollen)
                                    Text("Watering Reminders")
                                        .font(CultivarFont.undergrowth(14))
                                        .foregroundColor(.mushroomCream)
                                }
                            }
                            .tint(.mossGreen)
                        }

                        // Stats
                        FormSection(title: "Your Grove", icon: "tree.fill") {
                            HStack {
                                Text("Total Plants")
                                    .font(CultivarFont.undergrowth(14))
                                    .foregroundColor(.driedGrass)
                                Spacer()
                                Text("\(plants.count)")
                                    .font(CultivarFont.rings(15))
                                    .foregroundColor(.mossGreen)
                            }
                            HStack {
                                Text("App Version")
                                    .font(CultivarFont.undergrowth(14))
                                    .foregroundColor(.driedGrass)
                                Spacer()
                                Text("1.0.0")
                                    .font(CultivarFont.rings(13))
                                    .foregroundColor(.stoneGrey)
                            }
                            HStack {
                                Text("Schema Version")
                                    .font(CultivarFont.undergrowth(14))
                                    .foregroundColor(.driedGrass)
                                Spacer()
                                Text("V1.0.0")
                                    .font(CultivarFont.rings(13))
                                    .foregroundColor(.stoneGrey)
                            }
                        }

                        // Danger zone
                        FormSection(title: "Data", icon: "externaldrive.fill") {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(lastBackupMetadata != nil ? .mossGreen : .stoneGrey.opacity(0.5))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Automatic Backup")
                                        .font(CultivarFont.undergrowth(14))
                                        .foregroundColor(.mushroomCream)
                                    if let meta = lastBackupMetadata {
                                        Text("\(meta.plantCount) plant\(meta.plantCount == 1 ? "" : "s") · \(meta.date.formatted(.relative(presentation: .named)))")
                                            .font(CultivarFont.undergrowth(11))
                                            .foregroundColor(.stoneGrey)
                                    } else {
                                        Text("No backup yet")
                                            .font(CultivarFont.undergrowth(11))
                                            .foregroundColor(.stoneGrey.opacity(0.6))
                                    }
                                }
                                Spacer()
                            }

                            Button {
                                backupDocument = PlantBackupDocument(snapshot: makeBackupSnapshot())
                                showBackupExporter = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.fill").foregroundColor(.mossGreen)
                                    Text("Export JSON Backup")
                                        .font(CultivarFont.undergrowth(14))
                                        .foregroundColor(.mushroomCream)
                                }
                            }

                            Button {
                                showBackupImporter = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.down.fill").foregroundColor(.sageGreen)
                                    Text("Import JSON Backup")
                                        .font(CultivarFont.undergrowth(14))
                                        .foregroundColor(.mushroomCream)
                                }
                            }

                            Button {
                                showResetConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill").foregroundColor(.petalCoral)
                                    Text("Clear All Plant Data")
                                        .font(CultivarFont.undergrowth(14))
                                        .foregroundColor(.petalCoral)
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .onAppear {
                lastBackupMetadata = AutomaticBackupService.lastBackupMetadata()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.mossGreen)
                }
            }
            .confirmationDialog("Clear all plant data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Delete Everything", role: .destructive) {
                    clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all \(plants.count) plants and their history. This cannot be undone.")
            }
            .fileExporter(
                isPresented: $showBackupExporter,
                document: backupDocument,
                contentType: .json,
                defaultFilename: backupFilename
            ) { _ in }
            .sheet(isPresented: $showBackupImporter) {
                PlantBackupDocumentPicker { pickedURL in
                    showBackupImporter = false
                    handlePickedImportFile(url: pickedURL)
                } onCancel: {
                    showBackupImporter = false
                }
            }
            .alert("Backup Import", isPresented: $showImportResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importMessage)
            }
        }
    }

    private var backupFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "Cultivar-Backup-\(formatter.string(from: Date())).json"
    }

    private func makeBackupSnapshot() -> PlantBackupSnapshot {
        PlantBackupService.makeSnapshot(
            appName: appName,
            plants: plants,
            wishlistItems: wishlistItems,
            trades: plantTrades
        )
    }

    private func handlePickedImportFile(url: URL) {
        do {
            let data = try loadImportData(from: url)
            try importBackupData(data)
        } catch {
            importMessage = "Import failed: \(error.localizedDescription)"
            showImportResult = true
        }
    }

    private func loadImportData(from url: URL) throws -> Data {
        if let data = try? Data(contentsOf: url) {
            return data
        }

        let hasScope = url.startAccessingSecurityScopedResource()
        defer {
            if hasScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        var coordinationError: NSError?
        var readError: Error?
        var coordinatedData: Data?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { coordinatedURL in
            do {
                coordinatedData = try Data(contentsOf: coordinatedURL)
            } catch {
                readError = error
            }
        }

        if let coordinatedData {
            return coordinatedData
        }
        if let readError {
            throw readError
        }
        if let coordinationError {
            throw coordinationError
        }

        throw NSError(
            domain: "Cultivar.Import",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not access selected file."]
        )
    }

    private func importBackupData(_ data: Data) throws {
        do {
            _ = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw NSError(
                domain: "Cultivar.Import",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Selected file is not valid JSON."]
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(PlantBackupSnapshot.self, from: data)
        try restore(from: snapshot)
        importMessage = "Imported \(snapshot.plants.count) plant backup\(snapshot.plants.count == 1 ? "" : "s"). Existing matching plants were updated."
        showImportResult = true
    }

    private func restore(from snapshot: PlantBackupSnapshot) throws {
        let result = try PlantBackupService.restore(snapshot: snapshot, modelContext: modelContext)
        if let restoredAppName = result.restoredAppName {
            appName = restoredAppName
        }
    }

    private func clearAllData() {
        plants.forEach { modelContext.delete($0) }
        wishlistItems.forEach { modelContext.delete($0) }
        plantTrades.forEach { modelContext.delete($0) }

        do {
            try modelContext.save()
            try AutomaticBackupService.deleteBackup()
        } catch {
            #if DEBUG
            print("Failed to clear all data cleanly: \(error)")
            #endif
        }
    }

}

struct PlantBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var snapshot: PlantBackupSnapshot

    static let empty = PlantBackupDocument(
        snapshot: PlantBackupSnapshot(
            exportedAt: Date(),
            appName: "Cultivar",
            plants: [],
            wishlistItems: [],
            trades: []
        )
    )

    init(snapshot: PlantBackupSnapshot) {
        self.snapshot = snapshot
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        snapshot = try decoder.decode(PlantBackupSnapshot.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        return FileWrapper(regularFileWithContents: data)
    }
}

struct PlantBackupDocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onPick: (URL) -> Void
        private let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let firstURL = urls.first else {
                onCancel()
                return
            }
            onPick(firstURL)
        }
    }
}

struct PlantBackupSnapshot: Codable {
    let exportedAt: Date
    let appName: String
    let plants: [PlantBackupPlant]
    let wishlistItems: [PlantBackupWishlistItem]
    let trades: [PlantBackupTrade]

    init(
        exportedAt: Date,
        appName: String,
        plants: [PlantBackupPlant],
        wishlistItems: [PlantBackupWishlistItem],
        trades: [PlantBackupTrade]
    ) {
        self.exportedAt = exportedAt
        self.appName = appName
        self.plants = plants
        self.wishlistItems = wishlistItems
        self.trades = trades
    }

    private enum CodingKeys: String, CodingKey {
        case exportedAt
        case appName
        case plants
        case wishlistItems
        case trades
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        appName = try container.decode(String.self, forKey: .appName)
        plants = try container.decode([PlantBackupPlant].self, forKey: .plants)
        wishlistItems = try container.decodeIfPresent([PlantBackupWishlistItem].self, forKey: .wishlistItems) ?? []
        trades = try container.decodeIfPresent([PlantBackupTrade].self, forKey: .trades) ?? []
    }
}

struct PlantBackupPlant: Codable {
    let id: UUID
    let nickname: String
    let species: String
    let commonName: String
    let emoji: String
    let photoData: Data?
    let acquisitionDate: Date
    let birthdate: Date?
    let roomLocation: String
    let lightLevel: String
    let isOutdoor: Bool
    let wateringIntervalDays: Int
    let fertilizingIntervalDays: Int
    let repottingIntervalDays: Int
    let pruningIntervalDays: Int
    let lastWatered: Date?
    let lastFertilized: Date?
    let lastRepotted: Date?
    let lastPruned: Date?
    let currentHeightCm: Double?
    let currentLeafCount: Int?
    let potSizeCm: Double?
    let soilType: String
    let parentPlantID: UUID?
    let parentPlantNickname: String
    let healthStatus: String
    let activeIssues: [String]
    let notes: String
    let speciesCareSummary: String
    let isFavorite: Bool
    let tags: [String]
    let dateAdded: Date
    let careLogs: [PlantBackupCareLog]
    let growthEntries: [PlantBackupGrowthEntry]
    let propagations: [PlantBackupPropagation]
    let environmentReadings: [PlantBackupEnvironmentReading]

    init(_ plant: Plant) {
        id = plant.id
        nickname = plant.nickname
        species = plant.species
        commonName = plant.commonName
        emoji = plant.emoji
        photoData = plant.photoData
        acquisitionDate = plant.acquisitionDate
        birthdate = plant.birthdate
        roomLocation = plant.roomLocation
        lightLevel = plant.lightLevel.rawValue
        isOutdoor = plant.isOutdoor
        wateringIntervalDays = plant.wateringIntervalDays
        fertilizingIntervalDays = plant.fertilizingIntervalDays
        repottingIntervalDays = plant.repottingIntervalDays
        pruningIntervalDays = plant.pruningIntervalDays
        lastWatered = plant.lastWatered
        lastFertilized = plant.lastFertilized
        lastRepotted = plant.lastRepotted
        lastPruned = plant.lastPruned
        currentHeightCm = plant.currentHeightCm
        currentLeafCount = plant.currentLeafCount
        potSizeCm = plant.potSizeCm
        soilType = plant.soilType
        parentPlantID = plant.parentPlantID
        parentPlantNickname = plant.parentPlantNickname
        healthStatus = plant.healthStatus.rawValue
        activeIssues = plant.activeIssues
        notes = plant.notes
        speciesCareSummary = plant.speciesCareSummary
        isFavorite = plant.isFavorite
        tags = plant.tags
        dateAdded = plant.dateAdded
        careLogs = plant.careLogs.sorted { $0.date > $1.date }.map(PlantBackupCareLog.init)
        growthEntries = plant.growthEntries.sorted { $0.date > $1.date }.map(PlantBackupGrowthEntry.init)
        propagations = plant.propagations.sorted { $0.dateStarted > $1.dateStarted }.map(PlantBackupPropagation.init)
        environmentReadings = plant.environmentReadings.sorted { $0.date > $1.date }.map(PlantBackupEnvironmentReading.init)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case species
        case commonName
        case emoji
        case photoData
        case acquisitionDate
        case birthdate
        case roomLocation
        case lightLevel
        case isOutdoor
        case wateringIntervalDays
        case fertilizingIntervalDays
        case repottingIntervalDays
        case pruningIntervalDays
        case lastWatered
        case lastFertilized
        case lastRepotted
        case lastPruned
        case currentHeightCm
        case currentLeafCount
        case potSizeCm
        case soilType
        case parentPlantID
        case parentPlantNickname
        case healthStatus
        case activeIssues
        case notes
        case speciesCareSummary
        case isFavorite
        case tags
        case dateAdded
        case careLogs
        case growthEntries
        case propagations
        case environmentReadings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        nickname = try container.decode(String.self, forKey: .nickname)
        species = try container.decode(String.self, forKey: .species)
        commonName = try container.decode(String.self, forKey: .commonName)
        emoji = try container.decode(String.self, forKey: .emoji)
        photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)
        acquisitionDate = try container.decode(Date.self, forKey: .acquisitionDate)
        birthdate = try container.decodeIfPresent(Date.self, forKey: .birthdate)
        roomLocation = try container.decode(String.self, forKey: .roomLocation)
        lightLevel = try container.decode(String.self, forKey: .lightLevel)
        isOutdoor = try container.decodeIfPresent(Bool.self, forKey: .isOutdoor) ?? false
        wateringIntervalDays = try container.decodeIfPresent(Int.self, forKey: .wateringIntervalDays) ?? 7
        fertilizingIntervalDays = try container.decodeIfPresent(Int.self, forKey: .fertilizingIntervalDays) ?? 30
        repottingIntervalDays = try container.decodeIfPresent(Int.self, forKey: .repottingIntervalDays) ?? 365
        pruningIntervalDays = try container.decodeIfPresent(Int.self, forKey: .pruningIntervalDays) ?? 90
        lastWatered = try container.decodeIfPresent(Date.self, forKey: .lastWatered)
        lastFertilized = try container.decodeIfPresent(Date.self, forKey: .lastFertilized)
        lastRepotted = try container.decodeIfPresent(Date.self, forKey: .lastRepotted)
        lastPruned = try container.decodeIfPresent(Date.self, forKey: .lastPruned)
        currentHeightCm = try container.decodeIfPresent(Double.self, forKey: .currentHeightCm)
        currentLeafCount = try container.decodeIfPresent(Int.self, forKey: .currentLeafCount)
        potSizeCm = try container.decodeIfPresent(Double.self, forKey: .potSizeCm)
        soilType = try container.decodeIfPresent(String.self, forKey: .soilType) ?? ""
        parentPlantID = try container.decodeIfPresent(UUID.self, forKey: .parentPlantID)
        parentPlantNickname = try container.decodeIfPresent(String.self, forKey: .parentPlantNickname) ?? ""
        healthStatus = try container.decode(String.self, forKey: .healthStatus)
        activeIssues = try container.decodeIfPresent([String].self, forKey: .activeIssues) ?? []
        notes = try container.decode(String.self, forKey: .notes)
        speciesCareSummary = try container.decodeIfPresent(String.self, forKey: .speciesCareSummary) ?? ""
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? acquisitionDate
        careLogs = try container.decodeIfPresent([PlantBackupCareLog].self, forKey: .careLogs) ?? []
        growthEntries = try container.decodeIfPresent([PlantBackupGrowthEntry].self, forKey: .growthEntries) ?? []
        propagations = try container.decodeIfPresent([PlantBackupPropagation].self, forKey: .propagations) ?? []
        environmentReadings = try container.decodeIfPresent([PlantBackupEnvironmentReading].self, forKey: .environmentReadings) ?? []
    }
}

struct PlantBackupCareLog: Codable {
    let id: UUID
    let date: Date
    let careType: String
    let notes: String
    let photoData: Data?
    let soilMoisture: String?
    let fertiliserUsed: String?
    let amountMl: Double?

    init(_ log: CareLog) {
        id = log.id
        date = log.date
        careType = log.careType.rawValue
        notes = log.notes
        photoData = log.photoData
        soilMoisture = log.soilMoisture?.rawValue
        fertiliserUsed = log.fertiliserUsed
        amountMl = log.amountMl
    }
}

struct PlantBackupGrowthEntry: Codable {
    let id: UUID
    let date: Date
    let heightCm: Double?
    let leafCount: Int?
    let stemCount: Int?
    let notes: String
    let photoData: Data?
    let milestone: String?

    init(_ entry: GrowthEntry) {
        id = entry.id
        date = entry.date
        heightCm = entry.heightCm
        leafCount = entry.leafCount
        stemCount = entry.stemCount
        notes = entry.notes
        photoData = entry.photoData
        milestone = entry.milestone
    }
}

struct PlantBackupPropagation: Codable {
    let id: UUID
    let dateStarted: Date
    let method: String
    let numberOfCuttings: Int
    let rootingMedium: String
    let rootedDate: Date?
    let pottedDate: Date?
    let successCount: Int
    let notes: String
    let photoData: Data?
    let childPlantIDs: [UUID]

    init(_ record: PropagationRecord) {
        id = record.id
        dateStarted = record.dateStarted
        method = record.method.rawValue
        numberOfCuttings = record.numberOfCuttings
        rootingMedium = record.rootingMedium
        rootedDate = record.rootedDate
        pottedDate = record.pottedDate
        successCount = record.successCount
        notes = record.notes
        photoData = record.photoData
        childPlantIDs = record.childPlantIDs
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case dateStarted
        case method
        case numberOfCuttings
        case rootingMedium
        case rootedDate
        case pottedDate
        case successCount
        case notes
        case photoData
        case childPlantIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        dateStarted = try container.decode(Date.self, forKey: .dateStarted)
        method = try container.decode(String.self, forKey: .method)
        numberOfCuttings = try container.decode(Int.self, forKey: .numberOfCuttings)
        rootingMedium = try container.decode(String.self, forKey: .rootingMedium)
        rootedDate = try container.decodeIfPresent(Date.self, forKey: .rootedDate)
        pottedDate = try container.decodeIfPresent(Date.self, forKey: .pottedDate)
        successCount = try container.decodeIfPresent(Int.self, forKey: .successCount) ?? 0
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)
        childPlantIDs = try container.decodeIfPresent([UUID].self, forKey: .childPlantIDs) ?? []
    }
}

struct PlantBackupEnvironmentReading: Codable {
    let id: UUID
    let date: Date
    let roomName: String
    let temperatureCelsius: Double?
    let humidityPercent: Double?
    let lightLux: Double?
    let notes: String

    init(_ reading: EnvironmentReading) {
        id = reading.id
        date = reading.date
        roomName = reading.roomName
        temperatureCelsius = reading.temperatureCelsius
        humidityPercent = reading.humidityPercent
        lightLux = reading.lightLux
        notes = reading.notes
    }
}

struct PlantBackupWishlistItem: Codable {
    let id: UUID
    let plantName: String
    let species: String
    let notes: String
    let priority: String
    let dateAdded: Date
    let priceTarget: Double?
    let sourceURL: String?
    let photoData: Data?
    let isAcquired: Bool
    let acquiredDate: Date?

    init(_ item: WishlistItem) {
        id = item.id
        plantName = item.plantName
        species = item.species
        notes = item.notes
        priority = item.priority.rawValue
        dateAdded = item.dateAdded
        priceTarget = item.priceTarget
        sourceURL = item.sourceURL
        photoData = item.photoData
        isAcquired = item.isAcquired
        acquiredDate = item.acquiredDate
    }
}

struct PlantBackupTrade: Codable {
    let id: UUID
    let date: Date
    let tradeType: String
    let plantName: String
    let counterpartyName: String
    let notes: String
    let pricePaid: Double?
    let plantOffered: String?

    init(_ trade: PlantTrade) {
        id = trade.id
        date = trade.date
        tradeType = trade.tradeType.rawValue
        plantName = trade.plantName
        counterpartyName = trade.counterpartyName
        notes = trade.notes
        pricePaid = trade.pricePaid
        plantOffered = trade.plantOffered
    }
}

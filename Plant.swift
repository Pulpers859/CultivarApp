// Plant.swift

import SwiftData
import SwiftUI
import Foundation

@Model
final class Plant {
    
    // MARK: - Identity
    var id: UUID = UUID()
    var nickname: String = ""
    var species: String = ""
    var commonName: String = ""
    var emoji: String = "🌿"
    var photoData: Data? = nil           // Stored as JPEG data
    var acquisitionDate: Date = Date()
    var birthdate: Date? = nil           // If known
    var notes: String = ""
    var speciesCareSummary: String = ""
    
    // MARK: - Location & Environment
    var roomLocation: String = ""        // e.g. "Living Room", "Bathroom"
    var lightLevel: LightLevel = LightLevel.indirect
    var isOutdoor: Bool = false
    
    // MARK: - Care Schedule
    var wateringIntervalDays: Int = 7
    var fertilizingIntervalDays: Int = 30
    var repottingIntervalDays: Int = 365
    var pruningIntervalDays: Int = 90
    var lastWatered: Date? = nil
    var lastFertilized: Date? = nil
    var lastRepotted: Date? = nil
    var lastPruned: Date? = nil
    
    // MARK: - Growth Tracking
    var currentHeightCm: Double? = nil
    var currentLeafCount: Int? = nil
    var potSizeCm: Double? = nil
    var soilType: String = ""
    
    // MARK: - Lineage
    var parentPlantID: UUID? = nil       // UUID of parent if propagated
    var parentPlantNickname: String = "" // Denormalized for display
    
    // MARK: - Health
    var healthStatus: HealthStatus = HealthStatus.thriving
    var activeIssues: [String] = []
    
    // MARK: - Metadata
    var isFavorite: Bool = false
    var tags: [String] = []
    var dateAdded: Date = Date()
    
    // MARK: - Relationships
    @Relationship(deleteRule: .cascade) var careLogs: [CareLog] = []
    @Relationship(deleteRule: .cascade) var growthEntries: [GrowthEntry] = []
    @Relationship(deleteRule: .cascade) var propagations: [PropagationRecord] = []
    @Relationship(deleteRule: .cascade) var environmentReadings: [EnvironmentReading] = []
    
    init(
        nickname: String,
        species: String = "",
        commonName: String = "",
        emoji: String = "🌿",
        roomLocation: String = "",
        lightLevel: LightLevel = .indirect,
        wateringIntervalDays: Int = 7
    ) {
        self.id = UUID()
        self.nickname = nickname
        self.species = species
        self.commonName = commonName
        self.emoji = emoji
        self.roomLocation = roomLocation
        self.lightLevel = lightLevel
        self.wateringIntervalDays = wateringIntervalDays
        self.dateAdded = Date()
    }
    
    // MARK: - Computed Properties
    
    var daysUntilWater: Int? {
        daysUntilWater(relativeTo: Date())
    }
    
    var isOverdueForWater: Bool {
        guard let days = daysUntilWater(relativeTo: Date()) else { return true }
        return days < 0
    }
    
    var isDueForWaterToday: Bool {
        guard let days = daysUntilWater(relativeTo: Date()) else { return true }
        return days <= 0
    }
    
    var daysOwned: Int {
        Calendar.current.dateComponents([.day], from: acquisitionDate, to: Date()).day ?? 0
    }

    func daysUntilWater(relativeTo now: Date, calendar: Calendar = .current) -> Int? {
        WateringSchedule.daysUntilWater(
            lastWatered: lastWatered,
            intervalDays: wateringIntervalDays,
            now: now,
            calendar: calendar
        )
    }

    func nextWateringDate(relativeTo now: Date, calendar: Calendar = .current) -> Date? {
        WateringSchedule.nextWateringDate(
            lastWatered: lastWatered,
            intervalDays: wateringIntervalDays,
            now: now,
            calendar: calendar
        )
    }

    private func ownedDurationComponents(relativeTo now: Date, calendar: Calendar = .current) -> DateComponents {
        let start = calendar.startOfDay(for: acquisitionDate)
        let end = calendar.startOfDay(for: now)
        return calendar.dateComponents([.year, .month, .day], from: start, to: end)
    }

    var ownedDurationString: String {
        let components = ownedDurationComponents(relativeTo: Date())
        let years = max(components.year ?? 0, 0)
        let months = max(components.month ?? 0, 0)
        let days = max(components.day ?? 0, 0)
        return "\(years) year\(years == 1 ? "" : "s"), \(months) month\(months == 1 ? "" : "s"), \(days) day\(days == 1 ? "" : "s")"
    }

    var ownedDurationCompact: String {
        let components = ownedDurationComponents(relativeTo: Date())
        let years = max(components.year ?? 0, 0)
        let months = max(components.month ?? 0, 0)
        let days = max(components.day ?? 0, 0)
        return "\(years)y \(months)m \(days)d"
    }
    
    var profileImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }
    
    var nextWateringDate: Date? {
        nextWateringDate(relativeTo: Date())
    }

    var displayName: String {
        if !trimmedIdentity(nickname).isEmpty {
            return trimmedIdentity(nickname)
        }
        if !trimmedIdentity(commonName).isEmpty {
            return trimmedIdentity(commonName)
        }
        if !trimmedIdentity(species).isEmpty {
            return trimmedIdentity(species)
        }
        return "Unnamed Plant"
    }

    var displaySubtitle: String {
        let trimmedSpecies = trimmedIdentity(species)
        if !trimmedSpecies.isEmpty && !matchesDisplayName(trimmedSpecies) {
            return trimmedSpecies
        }

        let trimmedCommonName = trimmedIdentity(commonName)
        if !trimmedCommonName.isEmpty && !matchesDisplayName(trimmedCommonName) {
            return trimmedCommonName
        }

        return ""
    }

    var detailCommonName: String {
        let trimmedCommonName = trimmedIdentity(commonName)
        guard !trimmedCommonName.isEmpty, !matchesDisplayName(trimmedCommonName) else { return "" }
        return trimmedCommonName
    }

    func normalizeIdentity() {
        species = trimmedIdentity(species)
        commonName = trimmedIdentity(commonName)
        notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let trimmedNickname = trimmedIdentity(nickname)
        if !trimmedNickname.isEmpty {
            nickname = trimmedNickname
        } else if !commonName.isEmpty {
            nickname = commonName
        } else if !species.isEmpty {
            nickname = species
        } else {
            nickname = "Unnamed Plant"
        }
    }

    func refreshTrackedCareDates() {
        lastWatered = latestCareDate(for: .watering)
        lastFertilized = latestCareDate(for: .fertilizing)
        lastRepotted = latestCareDate(for: .repotting)
        lastPruned = latestCareDate(for: .pruning)
    }

    private func latestCareDate(for careType: CareType) -> Date? {
        careLogs
            .filter { $0.careType == careType }
            .map(\.date)
            .max()
    }

    private func matchesDisplayName(_ value: String) -> Bool {
        normalizedIdentityValue(value) == normalizedIdentityValue(displayName)
    }

    private func trimmedIdentity(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedIdentityValue(_ value: String) -> String {
        trimmedIdentity(value)
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }
}

// MARK: - Enums

enum LightLevel: String, Codable, CaseIterable {
    case fullSun = "Full Sun"
    case partialSun = "Partial Sun"
    case indirect = "Indirect Light"
    case lowLight = "Low Light"
    case shade = "Deep Shade"
    
    var icon: String {
        switch self {
        case .fullSun: return "sun.max.fill"
        case .partialSun: return "sun.and.horizon.fill"
        case .indirect: return "cloud.sun.fill"
        case .lowLight: return "cloud.fill"
        case .shade: return "moon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .fullSun: return .orange
        case .partialSun: return .yellow
        case .indirect: return .mossGreen
        case .lowLight: return .barkBrown
        case .shade: return .forestFloor
        }
    }
}

enum HealthStatus: String, Codable, CaseIterable {
    case thriving = "Thriving"
    case healthy = "Healthy"
    case needsAttention = "Needs Attention"
    case struggling = "Struggling"
    case recovering = "Recovering"
    case dormant = "Dormant"
    
    var icon: String {
        switch self {
        case .thriving: return "sparkles"
        case .healthy: return "leaf.fill"
        case .needsAttention: return "exclamationmark.triangle.fill"
        case .struggling: return "heart.slash.fill"
        case .recovering: return "cross.case.fill"
        case .dormant: return "moon.zzz.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .thriving: return .mossGreen
        case .healthy: return .green
        case .needsAttention: return .yellow
        case .struggling: return .red
        case .recovering: return .orange
        case .dormant: return .barkBrown
        }
    }
}

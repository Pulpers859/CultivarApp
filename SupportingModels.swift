// SupportingModels.swift

import SwiftData
import Foundation

// MARK: - Care Log

@Model
final class CareLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var careType: CareType = CareType.watering
    var notes: String = ""
    var photoData: Data? = nil
    var soilMoisture: SoilMoisture? = nil
    var fertiliserUsed: String? = nil
    var amountMl: Double? = nil
    
    init(careType: CareType, notes: String = "", soilMoisture: SoilMoisture? = nil) {
        self.id = UUID()
        self.date = Date()
        self.careType = careType
        self.notes = notes
        self.soilMoisture = soilMoisture
    }
}

enum CareType: String, Codable, CaseIterable {
    case watering = "Watering"
    case fertilizing = "Fertilizing"
    case repotting = "Repotting"
    case pruning = "Pruning"
    case misting = "Misting"
    case pestTreatment = "Pest Treatment"
    case rootCheck = "Root Check"
    case dusting = "Leaf Dusting"
    case staking = "Staking"
    case observation = "Observation"
    
    var icon: String {
        switch self {
        case .watering: return "drop.fill"
        case .fertilizing: return "sparkle"
        case .repotting: return "circle.grid.cross.fill"
        case .pruning: return "scissors"
        case .misting: return "cloud.drizzle.fill"
        case .pestTreatment: return "ant.fill"
        case .rootCheck: return "waveform.path.ecg"
        case .dusting: return "wind"
        case .staking: return "arrow.up.forward"
        case .observation: return "eye.fill"
        }
    }
}

enum SoilMoisture: String, Codable, CaseIterable {
    case boneDry = "Bone Dry"
    case dry = "Dry"
    case slightlyMoist = "Slightly Moist"
    case moist = "Moist"
    case wet = "Wet"
    case waterlogged = "Waterlogged"
}

// MARK: - Growth Entry

@Model
final class GrowthEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var heightCm: Double? = nil
    var leafCount: Int? = nil
    var stemCount: Int? = nil
    var notes: String = ""
    var photoData: Data? = nil
    var milestone: String? = nil  // e.g. "First flower!", "New unfurl"
    
    init(heightCm: Double? = nil, leafCount: Int? = nil, notes: String = "", milestone: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.heightCm = heightCm
        self.leafCount = leafCount
        self.notes = notes
        self.milestone = milestone
    }
}

// MARK: - Propagation Record

@Model
final class PropagationRecord {
    var id: UUID = UUID()
    var dateStarted: Date = Date()
    var method: PropagationMethod = PropagationMethod.stemCutting
    var numberOfCuttings: Int = 1
    var rootingMedium: String = ""
    var rootedDate: Date? = nil
    var pottedDate: Date? = nil
    var successCount: Int = 0
    var notes: String = ""
    var photoData: Data? = nil
    var childPlantIDs: [UUID] = []
    
    init(method: PropagationMethod, numberOfCuttings: Int = 1, rootingMedium: String = "") {
        self.id = UUID()
        self.dateStarted = Date()
        self.method = method
        self.numberOfCuttings = numberOfCuttings
        self.rootingMedium = rootingMedium
    }
    
    var daysInProgress: Int {
        Calendar.current.dateComponents([.day], from: dateStarted, to: rootedDate ?? Date()).day ?? 0
    }
    
    var isRooted: Bool { rootedDate != nil }
    var isPotted: Bool { pottedDate != nil }
}

enum PropagationMethod: String, Codable, CaseIterable {
    case stemCutting = "Stem Cutting"
    case leafCutting = "Leaf Cutting"
    case division = "Division"
    case offset = "Offset / Pup"
    case airLayering = "Air Layering"
    case seed = "Seed"
    case rhizome = "Rhizome Division"
    case bulb = "Bulb Separation"
    
    var icon: String {
        switch self {
        case .stemCutting: return "scissors"
        case .leafCutting: return "leaf"
        case .division: return "arrow.left.and.right"
        case .offset: return "plus.circle.fill"
        case .airLayering: return "cloud.fill"
        case .seed: return "circle.fill"
        case .rhizome: return "waveform"
        case .bulb: return "oval.fill"
        }
    }
}

// MARK: - Environment Reading

@Model
final class EnvironmentReading {
    var id: UUID = UUID()
    var date: Date = Date()
    var roomName: String = ""
    var temperatureCelsius: Double? = nil
    var humidityPercent: Double? = nil
    var lightLux: Double? = nil
    var notes: String = ""
    
    init(roomName: String, temperatureCelsius: Double? = nil, humidityPercent: Double? = nil, lightLux: Double? = nil) {
        self.id = UUID()
        self.date = Date()
        self.roomName = roomName
        self.temperatureCelsius = temperatureCelsius
        self.humidityPercent = humidityPercent
        self.lightLux = lightLux
    }
    
    var temperatureFahrenheit: Double? {
        guard let c = temperatureCelsius else { return nil }
        return (c * 9/5) + 32
    }
}

// MARK: - Wishlist Item

@Model
final class WishlistItem {
    var id: UUID = UUID()
    var plantName: String = ""
    var species: String = ""
    var notes: String = ""
    var priority: WishlistPriority = WishlistPriority.medium
    var dateAdded: Date = Date()
    var priceTarget: Double? = nil
    var sourceURL: String? = nil
    var photoData: Data? = nil
    var isAcquired: Bool = false
    var acquiredDate: Date? = nil
    
    init(plantName: String, species: String = "", priority: WishlistPriority = .medium) {
        self.id = UUID()
        self.plantName = plantName
        self.species = species
        self.priority = priority
        self.dateAdded = Date()
    }
}

enum WishlistPriority: String, Codable, CaseIterable {
    case low = "Someday"
    case medium = "Want It"
    case high = "Need It"
    case grail = "Holy Grail"
    
    var icon: String {
        switch self {
        case .low: return "bookmark"
        case .medium: return "heart"
        case .high: return "heart.fill"
        case .grail: return "crown.fill"
        }
    }
}

// MARK: - Plant Trade Log

@Model
final class PlantTrade {
    var id: UUID = UUID()
    var date: Date = Date()
    var tradeType: TradeType = TradeType.purchase
    var plantName: String = ""
    var counterpartyName: String = ""
    var notes: String = ""
    var pricePaid: Double? = nil
    var plantOffered: String? = nil
    
    init(tradeType: TradeType, plantName: String) {
        self.id = UUID()
        self.date = Date()
        self.tradeType = tradeType
        self.plantName = plantName
    }
}

enum TradeType: String, Codable, CaseIterable {
    case purchase = "Purchased"
    case trade = "Traded"
    case gift = "Gifted"
    case propagationGiven = "Prop Given Away"
    case sold = "Sold"
    
    var icon: String {
        switch self {
        case .purchase: return "bag.fill"
        case .trade: return "arrow.2.squarepath"
        case .gift: return "gift.fill"
        case .propagationGiven: return "leaf.arrow.circlepath"
        case .sold: return "dollarsign.circle.fill"
        }
    }
}

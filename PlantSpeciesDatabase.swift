// PlantSpeciesDatabase.swift

import Foundation
import Combine

// MARK: - Species Info Model

struct PlantSpeciesInfo: Codable, Identifiable {
    var id: String { scientificName.lowercased() }
    
    let scientificName: String
    let commonNames: [String]
    let family: String
    
    // Care requirements
    let wateringFrequency: String          // e.g. "Every 7-10 days"
    let wateringNotes: String              // e.g. "Allow top inch of soil to dry between waterings"
    let lightRequirement: String           // e.g. "Bright indirect light"
    let lightDetails: String               // e.g. "Tolerates low light but grows slower"
    let humidityPreference: String         // e.g. "Medium to high (50-60%)"
    let temperatureRange: String           // e.g. "65-85°F (18-29°C)"
    let soilType: String                   // e.g. "Well-draining aroid mix"
    let fertilizerSchedule: String         // e.g. "Monthly during growing season with balanced liquid fertilizer"
    
    // Additional info
    let toxicity: String                   // e.g. "Toxic to cats and dogs"
    let growthRate: String                 // e.g. "Moderate to fast"
    let matureSize: String                 // e.g. "Up to 8 ft indoors"
    let commonIssues: [String]             // e.g. ["Yellow leaves from overwatering", "Brown tips from low humidity"]
    let propagationMethods: [String]       // e.g. ["Stem cuttings", "Air layering"]
    let quickTips: [String]               // e.g. ["Rotate quarterly for even growth", "Wipe leaves monthly"]
    
    // Metadata
    let source: SpeciesInfoSource
    let dateAdded: Date
    
    enum SpeciesInfoSource: String, Codable {
        case bundled = "bundled"       // Shipped with app
        case claude = "claude"         // Fetched from Claude API
        case userEdited = "user"       // User modified
    }

    var careSummary: String {
        var sections: [String] = []

        if !wateringFrequency.isEmpty {
            sections.append("Water: \(wateringFrequency)")
        }
        if !wateringNotes.isEmpty {
            sections.append(wateringNotes)
        }
        if !lightRequirement.isEmpty {
            sections.append("Light: \(lightRequirement)")
        }
        if !humidityPreference.isEmpty {
            sections.append("Humidity: \(humidityPreference)")
        }
        if !temperatureRange.isEmpty {
            sections.append("Temperature: \(temperatureRange)")
        }
        if !soilType.isEmpty {
            sections.append("Soil: \(soilType)")
        }
        if !fertilizerSchedule.isEmpty {
            sections.append("Fertilizer: \(fertilizerSchedule)")
        }
        if !quickTips.isEmpty {
            sections.append("Tips: \(quickTips.prefix(3).joined(separator: " • "))")
        }

        return sections.joined(separator: "\n")
    }
}

// MARK: - Plant Database Service

@MainActor
class PlantDatabaseService: ObservableObject {
    
    static let shared = PlantDatabaseService()
    
    @Published var isLoading = false
    @Published var lastError: String? = nil
    
    private var speciesDatabase: [String: PlantSpeciesInfo] = [:]

    private var cachedDatabaseURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("PlantSpeciesCache.json")
    }
    
    init() {
        loadBundledDatabase()
        loadCachedDatabase()
    }
    
    // MARK: - Lookup
    
    func lookup(query: String) -> PlantSpeciesInfo? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let q = normalize(trimmed)

        if let exactScientific = speciesDatabase.values.first(where: { normalize($0.scientificName) == q }) {
            return exactScientific
        }

        if let exactCommon = speciesDatabase.values.first(where: { info in
            info.commonNames.contains(where: { normalize($0) == q })
        }) {
            return exactCommon
        }

        return nil
    }

    func lookup(scientificName: String, commonName: String = "") -> PlantSpeciesInfo? {
        let scientificTrimmed = scientificName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !scientificTrimmed.isEmpty, let match = lookup(query: scientificTrimmed) {
            return match
        }

        let commonTrimmed = commonName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !commonTrimmed.isEmpty {
            return lookup(query: commonTrimmed)
        }

        return nil
    }
    
    func search(query: String, limit: Int = 5) -> [PlantSpeciesInfo] {
        let q = normalize(query)
        guard q.count >= 2 else { return [] }

        let ranked = speciesDatabase.values.compactMap { info -> (PlantSpeciesInfo, Int)? in
            let scientific = normalize(info.scientificName)
            let common = info.commonNames.map { normalize($0) }

            if scientific == q { return (info, 0) }
            if common.contains(q) { return (info, 1) }
            if scientific.hasPrefix(q) { return (info, 2) }
            if common.contains(where: { $0.hasPrefix(q) }) { return (info, 3) }
            if scientific.contains(q) { return (info, 4) }
            if common.contains(where: { $0.contains(q) }) { return (info, 5) }

            return nil
        }

        return ranked
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
                let lName = lhs.0.commonNames.first ?? lhs.0.scientificName
                let rName = rhs.0.commonNames.first ?? rhs.0.scientificName
                return lName.localizedCaseInsensitiveCompare(rName) == .orderedAscending
            }
            .map(\.0)
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Claude Fallback
    
    func fetchFromClaude(scientificName: String, commonName: String = "") async -> PlantSpeciesInfo? {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        let scientificTrimmed = scientificName.trimmingCharacters(in: .whitespacesAndNewlines)
        let commonTrimmed = commonName.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchTerm = !scientificTrimmed.isEmpty ? scientificTrimmed : commonTrimmed
        guard !searchTerm.isEmpty else { return nil }

        if let existing = lookup(query: searchTerm) {
            return existing
        }
        
        let systemPrompt = """
        You are a botanical database. Given a plant name, respond with ONLY a JSON object (no markdown, no backticks, no explanation) containing care information. Use this exact structure:
        {
            "scientificName": "Genus species",
            "commonNames": ["Common Name 1", "Common Name 2"],
            "family": "Family Name",
            "wateringFrequency": "Every X-Y days",
            "wateringNotes": "Brief watering guidance",
            "lightRequirement": "Light level summary",
            "lightDetails": "Additional light info",
            "humidityPreference": "Humidity range or description",
            "temperatureRange": "Min-Max°F (Min-Max°C)",
            "soilType": "Recommended soil mix",
            "fertilizerSchedule": "When and what to fertilize with",
            "toxicity": "Toxicity info for pets and children",
            "growthRate": "Slow/Moderate/Fast",
            "matureSize": "Expected indoor size",
            "commonIssues": ["Issue 1", "Issue 2", "Issue 3"],
            "propagationMethods": ["Method 1", "Method 2"],
            "quickTips": ["Tip 1", "Tip 2", "Tip 3"]
        }
        If you don't recognize the plant, respond with: {"error": "unknown"}
        """
        
        let userMessage = "Plant: \(searchTerm)"
        
        do {
            let responseText = try await callClaudeAPI(systemPrompt: systemPrompt, userMessage: userMessage)
            
            // Clean up response — strip any markdown fencing Claude might add
            let cleaned = responseText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let data = cleaned.data(using: .utf8) else {
                lastError = "Could not parse response."
                return nil
            }
            
            // Check for error response
            if let errorObj = try? JSONDecoder().decode([String: String].self, from: data),
               errorObj["error"] == "unknown" {
                lastError = "Plant not recognized. Try a different name."
                return nil
            }
            
            // Parse the Claude response
            let raw = try JSONDecoder().decode(ClaudeSpeciesResponse.self, from: data)

            let scientific = cleanString(raw.scientificName)
            guard !scientific.isEmpty else {
                lastError = "The Grove Keeper response did not include a scientific name."
                return nil
            }

            let commonNames = cleanList(raw.commonNames)
            let info = PlantSpeciesInfo(
                scientificName: scientific,
                commonNames: commonNames.isEmpty ? [scientific] : commonNames,
                family: cleanString(raw.family),
                wateringFrequency: cleanString(raw.wateringFrequency),
                wateringNotes: cleanString(raw.wateringNotes),
                lightRequirement: cleanString(raw.lightRequirement),
                lightDetails: cleanString(raw.lightDetails),
                humidityPreference: cleanString(raw.humidityPreference),
                temperatureRange: cleanString(raw.temperatureRange),
                soilType: cleanString(raw.soilType),
                fertilizerSchedule: cleanString(raw.fertilizerSchedule),
                toxicity: cleanString(raw.toxicity),
                growthRate: cleanString(raw.growthRate),
                matureSize: cleanString(raw.matureSize),
                commonIssues: cleanList(raw.commonIssues),
                propagationMethods: cleanList(raw.propagationMethods),
                quickTips: cleanList(raw.quickTips),
                source: .claude,
                dateAdded: Date()
            )
            
            // Cache it for future use
            cacheSpecies(info)
            
            return info
            
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Caching
    
    private func cacheSpecies(_ info: PlantSpeciesInfo) {
        let key = info.scientificName.lowercased()
        speciesDatabase[key] = info
        saveCachedDatabase()
    }
    
    var totalSpeciesCount: Int { speciesDatabase.count }

    var cachedCount: Int {
        speciesDatabase.values.filter { $0.source == .claude }.count
    }
    
    // MARK: - Persistence
    
    private func loadBundledDatabase() {
        guard let url = Bundle.main.url(forResource: "PlantDatabase", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("PlantDatabase.json not found in bundle")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let entries = try decoder.decode([PlantSpeciesInfo].self, from: data)
            for entry in entries {
                speciesDatabase[entry.scientificName.lowercased()] = entry
            }
            #if DEBUG
            print("Loaded \(entries.count) bundled species")
            #endif
        } catch {
            print("Failed to decode bundled database: \(error)")
        }
    }
    
    private func loadCachedDatabase() {
        guard FileManager.default.fileExists(atPath: cachedDatabaseURL.path),
              let data = try? Data(contentsOf: cachedDatabaseURL) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let cached = try decoder.decode([PlantSpeciesInfo].self, from: data)
            for entry in cached {
                speciesDatabase[entry.scientificName.lowercased()] = entry
            }
            #if DEBUG
            print("Loaded \(cached.count) cached species")
            #endif
        } catch {
            print("Failed to load cached database: \(error)")
        }
    }
    
    private func saveCachedDatabase() {
        let cachedEntries = speciesDatabase.values
            .filter { $0.source == .claude }
            .sorted {
                $0.scientificName.localizedCaseInsensitiveCompare($1.scientificName) == .orderedAscending
            }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(Array(cachedEntries))
            try data.write(to: cachedDatabaseURL, options: .atomic)
        } catch {
            print("Failed to save cached database: \(error)")
        }
    }

    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleanString(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleanList(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values
            .map(cleanString(_:))
            .filter { !$0.isEmpty }
            .filter { value in
                let key = normalize(value)
                guard !key.isEmpty, !seen.contains(key) else { return false }
                seen.insert(key)
                return true
            }
    }
}

// MARK: - Claude Response Parsing Model (private)

private struct ClaudeSpeciesResponse: Codable {
    let scientificName: String
    let commonNames: [String]
    let family: String
    let wateringFrequency: String
    let wateringNotes: String
    let lightRequirement: String
    let lightDetails: String
    let humidityPreference: String
    let temperatureRange: String
    let soilType: String
    let fertilizerSchedule: String
    let toxicity: String
    let growthRate: String
    let matureSize: String
    let commonIssues: [String]
    let propagationMethods: [String]
    let quickTips: [String]
}

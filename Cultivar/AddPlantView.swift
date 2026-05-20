// AddPlantView.swift

import SwiftUI
import SwiftData
import PhotosUI

enum PlantFormConstants {
    static let emojiOptions = ["🌿","🌱","🌵","🌴","🪴","🌺","🌸","🌻","🍀","🌾","🪸","🎋","🎍","🍁","🌳","🌲","🪻","🌷","💐","🍃"]
    static let indoorRoomOptions = ["Living Room", "Bedroom", "Kitchen", "Bathroom", "Office", "Hallway", "Sunroom"]
    static let outdoorRoomOptions = ["Balcony", "Patio", "Garden", "Greenhouse", "Porch", "Deck"]
}

// MARK: - Add Plant View
struct AddPlantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var plantDB = PlantDatabaseService.shared

    @State private var nickname: String = ""
    @State private var species: String = ""
    @State private var commonName: String = ""
    @State private var emoji: String = "🌿"
    @State private var roomLocation: String = ""
    @State private var isOutdoor: Bool = false
    @State private var lightLevel: LightLevel = .indirect
    @State private var wateringInterval: Int = 7
    @State private var fertilizingInterval: Int = 30
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var acquisitionDate: Date = Date()
    @State private var healthStatus: HealthStatus = .healthy

    // Species lookup state
    @State private var matchedSpecies: PlantSpeciesInfo? = nil
    @State private var suggestions: [PlantSpeciesInfo] = []
    @State private var showSuggestions: Bool = false
    @State private var isLookingUp: Bool = false
    @State private var showNotFound: Bool = false
    @State private var hasAppliedDefaults: Bool = false
    @State private var lookupTask: Task<Void, Never>? = nil
    @State private var claudeTask: Task<Void, Never>? = nil

    var isValid: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !commonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !species.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Photo & emoji picker
                        photoSection

                        // Core identity
                        FormSection(title: "Identity", icon: "leaf.fill") {
                            CultivarFormField(label: "Nickname (optional)", placeholder: "Leave blank to use the common name", text: $nickname)
                            CultivarFormField(label: "Common Name", placeholder: "e.g. Monstera", text: $commonName)
                                .onChange(of: commonName) { _, newValue in
                                    handleSpeciesSearch(query: newValue, isScientific: false)
                                }
                            CultivarFormField(label: "Species (scientific)", placeholder: "e.g. Monstera deliciosa", text: $species)
                                .onChange(of: species) { _, newValue in
                                    handleSpeciesSearch(query: newValue, isScientific: true)
                                }

                            // Suggestions dropdown
                            if showSuggestions && !suggestions.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(suggestions) { suggestion in
                                        SpeciesSuggestionRow(info: suggestion) {
                                            selectSuggestion(suggestion)
                                        }
                                        if suggestion.id != suggestions.last?.id {
                                            Divider().background(Color.midForest)
                                        }
                                    }
                                }
                                .background(Color.underbrush)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.mossGreen.opacity(0.2), lineWidth: 1)
                                )
                            }

                            // Emoji picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Choose an emoji")
                                    .font(CultivarFont.undergrowth(13))
                                    .foregroundColor(.driedGrass.opacity(0.7))
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 6) {
                                    ForEach(PlantFormConstants.emojiOptions, id: \.self) { e in
                                        Button {
                                            emoji = e
                                        } label: {
                                            Text(e)
                                                .font(.system(size: 22))
                                                .padding(4)
                                                .background(emoji == e ? Color.mossGreen.opacity(0.3) : Color.clear)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                    }
                                }
                            }
                        }

                        // Species care card — the main feature
                        if let matched = matchedSpecies {
                            SpeciesCareCardView(info: matched)
                                .padding(.horizontal, 16)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else if isLookingUp {
                            SpeciesLookupLoadingView()
                                .padding(.horizontal, 16)
                        } else if showNotFound {
                            let query = !species.isEmpty ? species : commonName
                            SpeciesNotFoundView(
                                query: query,
                                onAskClaude: { askClaudeForSpecies() },
                                hasAPIKey: hasAPIKey
                            )
                            .padding(.horizontal, 16)
                        }

                        // Location
                        FormSection(title: "Habitat", icon: "mappin.circle.fill") {
                            Picker("Placement", selection: $isOutdoor) {
                                Text("Indoor").tag(false)
                                Text("Outdoor").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: isOutdoor) { _, outdoor in
                                if outdoor && roomLocation.isEmpty {
                                    roomLocation = PlantFormConstants.outdoorRoomOptions.first ?? "Garden"
                                }
                                if !outdoor && PlantFormConstants.outdoorRoomOptions.contains(roomLocation) {
                                    roomLocation = ""
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(isOutdoor ? "Outdoor Area" : "Room")
                                    .font(CultivarFont.undergrowth(13))
                                    .foregroundColor(.driedGrass.opacity(0.7))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(isOutdoor ? PlantFormConstants.outdoorRoomOptions : PlantFormConstants.indoorRoomOptions, id: \.self) { room in
                                            Button {
                                                roomLocation = room
                                            } label: {
                                                Text(room)
                                                    .font(CultivarFont.undergrowth(13))
                                                    .foregroundColor(roomLocation == room ? .forestFloor : .sageGreen)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 7)
                                                    .background(roomLocation == room ? Color.mossGreen : Color.midForest.opacity(0.6))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                                TextField(isOutdoor ? "Or type an outdoor spot" : "Or type a room", text: $roomLocation)
                                    .textFieldStyle(GroveTextFieldStyle())
                                Text("Use this so habitat readings and care reminders make sense by location.")
                                    .font(CultivarFont.undergrowth(11))
                                    .foregroundColor(.stoneGrey.opacity(0.75))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Light Level")
                                    .font(CultivarFont.undergrowth(13))
                                    .foregroundColor(.driedGrass.opacity(0.7))
                                ForEach(LightLevel.allCases, id: \.self) { level in
                                    Button {
                                        lightLevel = level
                                    } label: {
                                        HStack {
                                            Image(systemName: level.icon)
                                                .foregroundColor(level.color)
                                                .frame(width: 24)
                                            Text(level.rawValue)
                                                .font(CultivarFont.undergrowth(14))
                                                .foregroundColor(.mushroomCream)
                                            Spacer()
                                            if lightLevel == level {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.mossGreen)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }

                        // Care schedule
                        FormSection(title: "Care Schedule", icon: "drop.fill") {
                            StepperField(label: "Water every", value: $wateringInterval, unit: "days", range: 1...60, color: .rainwaterBlue)
                            StepperField(label: "Fertilize every", value: $fertilizingInterval, unit: "days", range: 7...365, color: .goldenPollen)

                            // Hint if species matched
                            if let matched = matchedSpecies, !hasAppliedDefaults {
                                Button {
                                    applySpeciesDefaults(from: matched)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(size: 12))
                                        Text("Apply \(matched.commonNames.first ?? matched.scientificName) defaults")
                                            .font(CultivarFont.undergrowth(12))
                                    }
                                    .foregroundColor(.goldenPollen)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.goldenPollen.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                        }

                        // Acquisition
                        FormSection(title: "Provenance", icon: "calendar") {
                            DatePicker("Acquired", selection: $acquisitionDate, displayedComponents: .date)
                                .font(CultivarFont.undergrowth(14))
                                .foregroundColor(.mushroomCream)
                                .colorScheme(.dark)
                        }

                        // Notes
                        FormSection(title: "Notes", icon: "note.text") {
                            TextEditor(text: $notes)
                                .font(CultivarFont.undergrowth(14))
                                .foregroundColor(.mushroomCream)
                                .scrollContentBackground(.hidden)
                                .background(Color.richSoil.opacity(0.5))
                                .frame(minHeight: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        CultivarButton("Plant in Grove", icon: "plus.circle.fill") {
                            savePlant()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1 : 0.5)
                        .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("New Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.stoneGrey)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: matchedSpecies?.id)
            .animation(.easeInOut(duration: 0.2), value: showSuggestions)
            .onDisappear {
                lookupTask?.cancel()
                claudeTask?.cancel()
            }
        }
    }

    // MARK: - Species Lookup Logic

    private var hasAPIKey: Bool {
        Config.hasAnthropicKey
    }

    private func handleSpeciesSearch(query: String, isScientific: Bool) {
        lookupTask?.cancel()
        claudeTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        showNotFound = false
        hasAppliedDefaults = false
        isLookingUp = false

        guard trimmed.count >= 2 else {
            suggestions = []
            showSuggestions = false
            matchedSpecies = nil
            return
        }

        lookupTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                performSpeciesSearch(query: trimmed, isScientific: isScientific)
            }
        }
    }

    private func performSpeciesSearch(query: String, isScientific: Bool) {
        if let match = plantDB.lookup(query: query) {
            matchedSpecies = match
            suggestions = []
            showSuggestions = false

            // Auto-fill the other name field if empty
            if isScientific && commonName.isEmpty {
                commonName = match.commonNames.first ?? ""
            } else if !isScientific && species.isEmpty {
                species = match.scientificName
            }
            return
        }

        // Show partial matches as suggestions
        let results = plantDB.search(query: query, limit: 5)
        if !results.isEmpty {
            suggestions = results
            showSuggestions = true
            matchedSpecies = nil
        } else {
            suggestions = []
            showSuggestions = false
            matchedSpecies = nil

            // Show "not found" only if the query is long enough to be a real search
            if query.count >= 4 {
                showNotFound = true
            }
        }
    }

    private func selectSuggestion(_ info: PlantSpeciesInfo) {
        species = info.scientificName
        commonName = info.commonNames.first ?? ""
        matchedSpecies = info
        suggestions = []
        showSuggestions = false
        showNotFound = false
    }

    private func askClaudeForSpecies() {
        guard !isLookingUp else { return }

        let query = !species.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? species : commonName
        guard !query.isEmpty else { return }

        lookupTask?.cancel()
        claudeTask?.cancel()
        isLookingUp = true
        showNotFound = false
        showSuggestions = false

        claudeTask = Task {
            let result = await plantDB.fetchFromClaude(scientificName: species, commonName: commonName)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                isLookingUp = false
                if let info = result {
                    matchedSpecies = info
                    // Fill in names if they came back from Claude
                    if species.isEmpty {
                        species = info.scientificName
                    }
                    if commonName.isEmpty {
                        commonName = info.commonNames.first ?? ""
                    }
                } else {
                    showNotFound = true
                }
            }
        }
    }

    private func applySpeciesDefaults(from info: PlantSpeciesInfo) {
        // Parse watering interval from the species info
        if let interval = parseIntervalDays(from: info.wateringFrequency) {
            wateringInterval = interval
        }

        // Parse light level
        let light = info.lightRequirement.lowercased()
        if light.contains("full sun") || light.contains("bright direct") {
            lightLevel = .fullSun
        } else if light.contains("partial") {
            lightLevel = .partialSun
        } else if light.contains("bright indirect") {
            lightLevel = .indirect
        } else if light.contains("low") {
            lightLevel = .lowLight
        } else if light.contains("shade") {
            lightLevel = .shade
        }

        hasAppliedDefaults = true
    }

    private func parseIntervalDays(from text: String) -> Int? {
        let pattern = #"(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let nsRange = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: nsRange)
        let numbers = matches.compactMap { match -> Int? in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return Int(text[range])
        }

        guard let first = numbers.first else { return nil }
        if numbers.count >= 2 {
            return Int((Double(first + numbers[1]) / 2.0).rounded())
        }
        return first
    }

    var photoSection: some View {
        VStack(spacing: 12) {
            ZStack {
                if let data = photoData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.midForest)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(emoji)
                                .font(.system(size: 48))
                        )
                }
            }
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("Add Photo")
                    .font(CultivarFont.undergrowth(13))
                    .foregroundColor(.rainwaterBlue)
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
        .padding(.top, 16)
    }

    func savePlant() {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSpecies = species.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCommonName = commonName.trimmingCharacters(in: .whitespacesAndNewlines)
        let plant = Plant(
            nickname: trimmedNickname,
            species: trimmedSpecies,
            commonName: trimmedCommonName,
            emoji: emoji,
            roomLocation: roomLocation.trimmingCharacters(in: .whitespacesAndNewlines),
            lightLevel: lightLevel,
            wateringIntervalDays: wateringInterval
        )
        plant.isOutdoor = isOutdoor
        plant.fertilizingIntervalDays = fertilizingInterval
        plant.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.photoData = photoData
        plant.acquisitionDate = acquisitionDate
        plant.healthStatus = healthStatus

        let speciesInfo = matchedSpecies ?? plantDB.lookup(scientificName: trimmedSpecies, commonName: trimmedCommonName)
        if let speciesInfo {
            plant.speciesCareSummary = speciesInfo.careSummary
            if plant.soilType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                plant.soilType = speciesInfo.soilType
            }
        }

        plant.normalizeIdentity()
        modelContext.insert(plant)
        dismiss()
    }
}

// MARK: - Edit Plant View
struct EditPlantView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: Plant

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Identity", icon: "leaf.fill") {
                            CultivarFormField(label: "Nickname (optional)", placeholder: "Leave blank to use the common name", text: $plant.nickname)
                            CultivarFormField(label: "Common Name", placeholder: "", text: $plant.commonName)
                            CultivarFormField(label: "Species", placeholder: "", text: $plant.species)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Icon")
                                    .font(CultivarFont.undergrowth(12))
                                    .foregroundColor(.driedGrass.opacity(0.7))
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 6) {
                                    ForEach(PlantFormConstants.emojiOptions, id: \.self) { e in
                                        Button {
                                            plant.emoji = e
                                        } label: {
                                            Text(e)
                                                .font(.system(size: 22))
                                                .padding(4)
                                                .background(plant.emoji == e ? Color.mossGreen.opacity(0.3) : Color.clear)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                    }
                                }
                            }
                        }

                        FormSection(title: "Habitat", icon: "mappin.circle.fill") {
                            Picker("Placement", selection: $plant.isOutdoor) {
                                Text("Indoor").tag(false)
                                Text("Outdoor").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: plant.isOutdoor) { _, outdoor in
                                if outdoor && plant.roomLocation.isEmpty {
                                    plant.roomLocation = PlantFormConstants.outdoorRoomOptions.first ?? "Garden"
                                }
                                if !outdoor && PlantFormConstants.outdoorRoomOptions.contains(plant.roomLocation) {
                                    plant.roomLocation = ""
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(plant.isOutdoor ? "Outdoor Area" : "Room")
                                    .font(CultivarFont.undergrowth(13))
                                    .foregroundColor(.driedGrass.opacity(0.7))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(plant.isOutdoor ? PlantFormConstants.outdoorRoomOptions : PlantFormConstants.indoorRoomOptions, id: \.self) { room in
                                            Button {
                                                plant.roomLocation = room
                                            } label: {
                                                Text(room)
                                                    .font(CultivarFont.undergrowth(13))
                                                    .foregroundColor(plant.roomLocation == room ? .forestFloor : .sageGreen)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 7)
                                                    .background(plant.roomLocation == room ? Color.mossGreen : Color.midForest.opacity(0.6))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                                TextField(plant.isOutdoor ? "Or type an outdoor spot" : "Or type a room", text: $plant.roomLocation)
                                    .textFieldStyle(GroveTextFieldStyle())
                            }
                            Picker("Light Level", selection: $plant.lightLevel) {
                                ForEach(LightLevel.allCases, id: \.self) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .colorScheme(.dark)
                        }

                        FormSection(title: "Health", icon: "heart.fill") {
                            Picker("Health Status", selection: $plant.healthStatus) {
                                ForEach(HealthStatus.allCases, id: \.self) { s in
                                    Text(s.rawValue).tag(s)
                                }
                            }
                            .colorScheme(.dark)
                        }

                        FormSection(title: "Care Schedule", icon: "drop.fill") {
                            StepperField(label: "Water every", value: $plant.wateringIntervalDays, unit: "days", range: 1...60, color: .rainwaterBlue)
                            StepperField(label: "Fertilize every", value: $plant.fertilizingIntervalDays, unit: "days", range: 7...365, color: .goldenPollen)
                        }

                        FormSection(title: "Notes", icon: "note.text") {
                            TextEditor(text: $plant.notes)
                                .font(CultivarFont.undergrowth(14))
                                .foregroundColor(.mushroomCream)
                                .scrollContentBackground(.hidden)
                                .background(Color.richSoil.opacity(0.5))
                                .frame(minHeight: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        CultivarButton("Save Changes", icon: "checkmark.circle.fill") {
                            plant.normalizeIdentity()
                            dismiss()
                        }
                        .padding(.horizontal, 16)
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .onAppear {
                if PlantFormConstants.outdoorRoomOptions.contains(plant.roomLocation) {
                    plant.isOutdoor = true
                }
            }
            .navigationTitle("Edit \(plant.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.stoneGrey)
                }
            }
        }
    }
}

// MARK: - Form Helpers
struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.mossGreen)
                    .font(.system(size: 13))
                Text(title)
                    .font(CultivarFont.canopy(14, weight: .semibold))
                    .foregroundColor(.sageGreen)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forestCard()
        .padding(.horizontal, 16)
    }
}

struct CultivarFormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(CultivarFont.undergrowth(12))
                .foregroundColor(.driedGrass.opacity(0.7))
            TextField(placeholder, text: $text)
                .textFieldStyle(GroveTextFieldStyle())
        }
    }
}

struct StepperField: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let range: ClosedRange<Int>
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(CultivarFont.undergrowth(13))
                    .foregroundColor(.driedGrass)
                Text("\(value) \(unit)")
                    .font(CultivarFont.rings(15))
                    .foregroundColor(color)
            }
            Spacer()
            HStack(spacing: 16) {
                Button {
                    if value > range.lowerBound { value -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.stoneGrey)
                        .font(.system(size: 22))
                }
                Button {
                    if value < range.upperBound { value += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(color)
                        .font(.system(size: 22))
                }
            }
        }
    }
}

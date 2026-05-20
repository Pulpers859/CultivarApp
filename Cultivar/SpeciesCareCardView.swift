// SpeciesCareCardView.swift

import SwiftUI

// MARK: - Species Care Card (Full)

struct SpeciesCareCardView: View {
    let info: PlantSpeciesInfo
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(.goldenPollen)
                        .font(.system(size: 14))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Field Guide")
                            .font(CultivarFont.canopy(14, weight: .semibold))
                            .foregroundColor(.mushroomCream)
                        
                        Text(info.scientificName)
                            .font(CultivarFont.rings(12))
                            .foregroundColor(.sageGreen)
                            .italic()
                    }
                    
                    Spacer()
                    
                    SpeciesSourceBadge(source: info.source)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.stoneGrey)
                        .font(.system(size: 12))
                }
            }
            .padding(14)
            
            if isExpanded {
                RootDivider()
                    .padding(.horizontal, 14)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Family & common names
                    if !info.family.isEmpty {
                        HStack(spacing: 6) {
                            Text("Family:")
                                .font(CultivarFont.undergrowth(12))
                                .foregroundColor(.stoneGrey)
                            Text(info.family)
                                .font(CultivarFont.undergrowth(12))
                                .foregroundColor(.driedGrass)
                        }
                    }
                    
                    if info.commonNames.count > 1 {
                        HStack(spacing: 6) {
                            Text("Also known as:")
                                .font(CultivarFont.undergrowth(12))
                                .foregroundColor(.stoneGrey)
                            Text(info.commonNames.joined(separator: ", "))
                                .font(CultivarFont.undergrowth(12))
                                .foregroundColor(.driedGrass)
                                .lineLimit(2)
                        }
                    }
                    
                    // Care grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        CareInfoTile(icon: "drop.fill", color: .rainwaterBlue,
                                     title: "Water", value: info.wateringFrequency)
                        CareInfoTile(icon: "sun.max.fill", color: .goldenPollen,
                                     title: "Light", value: info.lightRequirement)
                        CareInfoTile(icon: "humidity.fill", color: .dewDrop,
                                     title: "Humidity", value: info.humidityPreference)
                        CareInfoTile(icon: "thermometer.medium", color: .petalCoral,
                                     title: "Temp", value: info.temperatureRange)
                        CareInfoTile(icon: "leaf.fill", color: .fernGreen,
                                     title: "Soil", value: info.soilType)
                        CareInfoTile(icon: "sparkle", color: .goldenPollen,
                                     title: "Fertilizer", value: info.fertilizerSchedule)
                    }
                    
                    // Growth & toxicity row
                    HStack(spacing: 12) {
                        CareInfoMini(icon: "arrow.up.right", color: .mossGreen,
                                     label: "Growth", value: info.growthRate)
                        CareInfoMini(icon: "ruler", color: .cedarWarm,
                                     label: "Size", value: info.matureSize)
                    }
                    
                    // Toxicity warning
                    if !info.toxicity.isEmpty && info.toxicity.lowercased() != "non-toxic" {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.petalCoral)
                                .font(.system(size: 12))
                            Text(info.toxicity)
                                .font(CultivarFont.undergrowth(12))
                                .foregroundColor(.petalCoral.opacity(0.9))
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.petalCoral.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Common issues
                    if !info.commonIssues.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Watch for")
                                .font(CultivarFont.undergrowth(12))
                                .foregroundColor(.stoneGrey)
                            ForEach(info.commonIssues.prefix(3), id: \.self) { issue in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .foregroundColor(.cedarWarm)
                                        .font(.system(size: 10))
                                    Text(issue)
                                        .font(CultivarFont.undergrowth(12))
                                        .foregroundColor(.driedGrass.opacity(0.8))
                                }
                            }
                        }
                    }
                    
                    // Quick tips
                    if !info.quickTips.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Quick tips")
                                .font(CultivarFont.undergrowth(12))
                                .foregroundColor(.stoneGrey)
                            ForEach(info.quickTips.prefix(3), id: \.self) { tip in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("🌿")
                                        .font(.system(size: 10))
                                    Text(tip)
                                        .font(CultivarFont.undergrowth(12))
                                        .foregroundColor(.driedGrass.opacity(0.8))
                                }
                            }
                        }
                    }
                    
                    // Watering detail note
                    if !info.wateringNotes.isEmpty {
                        Text(info.wateringNotes)
                            .font(CultivarFont.undergrowth(11))
                            .foregroundColor(.stoneGrey)
                            .italic()
                            .padding(.top, 2)
                    }
                    
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.forestDapple.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.mossGreen.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Care Info Tile (2-column grid item)

struct CareInfoTile: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 11))
                Text(title)
                    .font(CultivarFont.undergrowth(11))
                    .foregroundColor(.stoneGrey)
            }
            Text(value)
                .font(CultivarFont.undergrowth(12))
                .foregroundColor(.mushroomCream)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.richSoil.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Inline mini info

struct CareInfoMini: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 11))
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(CultivarFont.undergrowth(10))
                    .foregroundColor(.stoneGrey)
                Text(value)
                    .font(CultivarFont.undergrowth(12))
                    .foregroundColor(.mushroomCream)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.richSoil.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Source Badge

struct SpeciesSourceBadge: View {
    let source: PlantSpeciesInfo.SpeciesInfoSource
    
    var body: some View {
        Text(label)
            .font(CultivarFont.rings(9))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
    
    private var label: String {
        switch source {
        case .bundled: return "FIELD GUIDE"
        case .claude: return "GROVE KEEPER"
        case .userEdited: return "YOUR NOTES"
        }
    }
    
    private var color: Color {
        switch source {
        case .bundled: return .sageGreen
        case .claude: return .goldenPollen
        case .userEdited: return .rainwaterBlue
        }
    }
}

// MARK: - Loading / Error States for Claude Lookup

struct SpeciesLookupLoadingView: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(.mossGreen)
            Text("Asking the Grove Keeper...")
                .font(CultivarFont.undergrowth(13))
                .foregroundColor(.sageGreen)
                .italic()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.forestDapple.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SpeciesNotFoundView: View {
    let query: String
    let onAskClaude: () -> Void
    let hasAPIKey: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.stoneGrey)
                    .font(.system(size: 12))
                Text("Not in the field guide")
                    .font(CultivarFont.undergrowth(13))
                    .foregroundColor(.stoneGrey)
            }
            
            if hasAPIKey {
                Button(action: onAskClaude) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                        Text("Don't see your plant? Ask the Grove Keeper")
                            .font(CultivarFont.undergrowth(12))
                    }
                    .foregroundColor(.goldenPollen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.goldenPollen.opacity(0.12))
                    .clipShape(Capsule())
                }
                Text("Lookup: \"\(query)\"")
                    .font(CultivarFont.undergrowth(11))
                    .foregroundColor(.stoneGrey.opacity(0.8))
            } else {
                Text("Add an API key in Settings to look up unknown plants.")
                    .font(CultivarFont.undergrowth(11))
                    .foregroundColor(.stoneGrey.opacity(0.7))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.forestDapple.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Suggestion Row (for autocomplete)

struct SpeciesSuggestionRow: View {
    let info: PlantSpeciesInfo
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.fernGreen)
                    .font(.system(size: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.commonNames.first ?? info.scientificName)
                        .font(CultivarFont.undergrowth(13))
                        .foregroundColor(.mushroomCream)
                    Text(info.scientificName)
                        .font(CultivarFont.rings(11))
                        .foregroundColor(.sageGreen)
                        .italic()
                }
                Spacer()
                Image(systemName: "arrow.up.left")
                    .foregroundColor(.stoneGrey)
                    .font(.system(size: 10))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
        }
    }
}

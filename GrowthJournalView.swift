import SwiftUI
import SwiftData
import UIKit

// MARK: - Growth Journal View (Tab 3)
struct GrowthJournalView: View {
    @Query(sort: \Plant.nickname) private var plants: [Plant]
    @State private var selectedPlant: Plant? = nil

    var plantsSortedForGrowth: [Plant] {
        plants.sorted {
            let lhs = $0.growthEntries.map(\.date).max() ?? Date.distantPast
            let rhs = $1.growthEntries.map(\.date).max() ?? Date.distantPast
            if lhs == rhs {
                return $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending
            }
            return lhs > rhs
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Growth Journal")
                                .font(CultivarFont.oldGrowth(26))
                                .foregroundColor(.mushroomCream)
                            Text("Watch your grove flourish")
                                .font(CultivarFont.undergrowth(13))
                                .foregroundColor(.stoneGrey)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        Text("Tap any plant to open its Growth timeline with photos, milestones, and measurements.")
                            .font(CultivarFont.undergrowth(11))
                            .foregroundColor(.stoneGrey)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        let allEntries = plants.flatMap { $0.growthEntries }
                            .filter { $0.milestone != nil }
                            .sorted { $0.date > $1.date }
                            .prefix(5)

                        if !allEntries.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                            CultivarSectionHeader(title: "Recent Milestones", icon: "sparkles", color: .goldenPollen)
                                ForEach(Array(allEntries)) { entry in
                                    HStack(spacing: 10) {
                                        Text("🌟")
                                        VStack(alignment: .leading) {
                                            Text(entry.milestone ?? "")
                                                .font(CultivarFont.undergrowth(14))
                                                .foregroundColor(.mushroomCream)
                                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(CultivarFont.rings(11))
                                                .foregroundColor(.stoneGrey)
                                        }
                                        Spacer()
                                    }
                                    .padding(12)
                                    .forestCard()
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            CultivarSectionHeader(title: "All Plants", icon: "leaf.fill", color: .mossGreen)
                            ForEach(plantsSortedForGrowth) { plant in
                                PlantGrowthSummaryRow(plant: plant)
                                    .onTapGesture { selectedPlant = plant }
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedPlant) { plant in
                PlantDetailView(plant: plant, initialTab: .growth)
            }
        }
    }
}

struct PlantGrowthSummaryRow: View {
    let plant: Plant
    @State private var showPhotoPreview: Bool = false

    var latestEntry: GrowthEntry? {
        plant.growthEntries.sorted { $0.date > $1.date }.first
    }

    var body: some View {
        HStack(spacing: 14) {
            if let data = latestEntry?.photoData, let image = UIImage(data: data) {
                Button {
                    showPhotoPreview = true
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 76, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.mossGreen.opacity(0.25), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            } else {
                ZStack {
                    Circle().fill(Color.midForest).frame(width: 76, height: 76)
                    Text(plant.emoji).font(.system(size: 24))
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(plant.nickname)
                    .font(CultivarFont.canopy(14, weight: .semibold))
                    .foregroundColor(.mushroomCream)
                HStack(spacing: 8) {
                    if let h = latestEntry?.heightCm {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10))
                            Text("\(h, specifier: "%.1f")cm")
                                .font(CultivarFont.rings(11))
                        }
                        .foregroundColor(.sageGreen)
                    }
                    if let l = latestEntry?.leafCount {
                        HStack(spacing: 3) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 10))
                            Text("\(l) leaves")
                                .font(CultivarFont.rings(11))
                        }
                        .foregroundColor(.fernGreen)
                    }
                    if latestEntry == nil {
                        Text("No measurements yet")
                            .font(CultivarFont.undergrowth(11))
                            .foregroundColor(.stoneGrey.opacity(0.6))
                    }
                }
                if let latest = latestEntry {
                    Text("Last update \(latest.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(CultivarFont.rings(10))
                        .foregroundColor(.stoneGrey.opacity(0.8))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(plant.growthEntries.count) entries")
                    .font(CultivarFont.rings(11))
                    .foregroundColor(.stoneGrey.opacity(0.6))
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.stoneGrey.opacity(0.6))
            }
        }
        .padding(12)
        .forestCard()
        .sheet(isPresented: $showPhotoPreview) {
            let photoEntries = plant.growthEntries
                .filter { $0.photoData != nil }
                .sorted { $0.date > $1.date }
            if !photoEntries.isEmpty {
                GrowthPhotoGallerySheet(entries: photoEntries, startIndex: 0)
            }
        }
    }
}

struct GrowthPhotoGallerySheet: View {
    let entries: [GrowthEntry]
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    init(entries: [GrowthEntry], startIndex: Int) {
        self.entries = entries
        _currentIndex = State(initialValue: startIndex)
    }

    private var currentEntry: GrowthEntry? {
        guard entries.indices.contains(currentIndex) else { return nil }
        return entries[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                TabView(selection: $currentIndex) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                        VStack(spacing: 12) {
                            if let data = entry.photoData, let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            }
                            if let milestone = entry.milestone {
                                Text("🌟 \(milestone)")
                                    .font(CultivarFont.undergrowth(14))
                                    .foregroundColor(.goldenPollen)
                                    .padding(.horizontal)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: entries.count > 1 ? .automatic : .never))
            }
            .navigationTitle(currentEntry?.date.formatted(date: .abbreviated, time: .omitted) ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if entries.count > 1 {
                        Text("\(currentIndex + 1) of \(entries.count)")
                            .font(CultivarFont.rings(13))
                            .foregroundColor(.stoneGrey)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.mushroomCream)
                }
            }
        }
    }
}

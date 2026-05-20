// GardenView.swift

import SwiftUI
import SwiftData
import Combine

struct GardenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plant.nickname) private var plants: [Plant]

    @State private var searchText: String = ""
    @State private var selectedFilter: PlantFilter = .all
    @State private var selectedPlant: Plant? = nil
    @State private var viewMode: ViewMode = .grid
    @State private var showSettings: Bool = false
    @State private var plantsPendingDeletion: [Plant] = []
    @State private var showDeletePlantConfirm: Bool = false
    @State private var showUndoDeleteBanner: Bool = false
    @State private var undoDeleteMessage: String = ""
    @State private var pendingDeleteWorkItem: DispatchWorkItem? = nil
    @State private var now: Date = Date()
    @State private var isSelectingForDeletion: Bool = false
    @State private var selectedPlantIDs: Set<UUID> = []

    private let clock = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    enum PlantFilter: String, CaseIterable {
        case all = "All"
        case needsWater = "Thirsty"
        case thriving = "Thriving"
        case attention = "Needs Care"
        case favorites = "Favorites"
    }

    enum ViewMode { case grid, list }

    private func matchesThriving(_ plant: Plant) -> Bool {
        let strongHealth = plant.healthStatus == .thriving || plant.healthStatus == .healthy
        return strongHealth && !isOverdueForWater(plant)
    }

    private func matchesNeedsCare(_ plant: Plant) -> Bool {
        isOverdueForWater(plant) || plant.healthStatus == .needsAttention || plant.healthStatus == .struggling
    }

    private func count(for filter: PlantFilter) -> Int {
        switch filter {
        case .all:
            return plants.count
        case .needsWater:
            return plants.filter(isDueForWaterToday(_:)).count
        case .thriving:
            return plants.filter(matchesThriving(_:)).count
        case .attention:
            return plants.filter(matchesNeedsCare(_:)).count
        case .favorites:
            return plants.filter { $0.isFavorite }.count
        }
    }

    private func filterTitle(_ filter: PlantFilter) -> String {
        "\(filter.rawValue) (\(count(for: filter)))"
    }

    private var filterRows: [[PlantFilter]] {
        [
            [.all, .needsWater, .thriving],
            [.attention, .favorites]
        ]
    }

    var filteredPlants: [Plant] {
        let searched = searchText.isEmpty ? plants : plants.filter {
            $0.nickname.localizedCaseInsensitiveContains(searchText) ||
            $0.species.localizedCaseInsensitiveContains(searchText) ||
            $0.commonName.localizedCaseInsensitiveContains(searchText)
        }
        let filtered: [Plant]
        switch selectedFilter {
        case .all:         filtered = searched
        case .needsWater:  filtered = searched.filter(isDueForWaterToday(_:))
        case .thriving:    filtered = searched.filter(matchesThriving(_:))
        case .attention:   filtered = searched.filter(matchesNeedsCare(_:))
        case .favorites:   filtered = searched.filter { $0.isFavorite }
        }
        return filtered.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()

                if viewMode == .list {
                    listModeLayout
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            groveControls

                            if filteredPlants.isEmpty {
                                emptyGroveView
                            } else {
                                plantGrid
                            }

                            Spacer(minLength: 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedPlant) { plant in
                PlantDetailView(plant: plant)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .confirmationDialog(
                deleteConfirmationTitle,
                isPresented: $showDeletePlantConfirm,
                titleVisibility: .visible
            ) {
                Button("Remove from Grove", role: .destructive) {
                    let plantsToDelete = plantsPendingDeletion
                    guard !plantsToDelete.isEmpty else { return }
                    schedulePlantDeletion(plantsToDelete)
                    plantsPendingDeletion = []
                }
                Button("Cancel", role: .cancel) {
                    plantsPendingDeletion = []
                }
            } message: {
                Text(deleteConfirmationMessage)
            }
            .safeAreaInset(edge: .bottom) {
                if showUndoDeleteBanner {
                    UndoDeleteBanner(message: undoDeleteMessage) {
                        cancelPendingDelete()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 90)
                }
            }
            .onReceive(clock) { now = $0 }
            .onChange(of: viewMode) { _, newMode in
                if newMode != .grid {
                    clearDeleteSelection()
                }
            }
        }
    }

    private var deleteConfirmationTitle: String {
        if plantsPendingDeletion.count == 1 {
            return "Remove \(plantsPendingDeletion.first?.displayName ?? "this plant")?"
        }
        return "Remove \(plantsPendingDeletion.count) plants?"
    }

    private var deleteConfirmationMessage: String {
        if plantsPendingDeletion.count == 1 {
            return "This permanently removes the plant and all of its logs."
        }
        return "This permanently removes the selected plants and all of their logs."
    }

    private var overduePlantCount: Int {
        filteredPlants.filter(isOverdueForWater(_:)).count
    }

    private var selectedPlantsForDeletion: [Plant] {
        plants.filter { selectedPlantIDs.contains($0.id) }
    }

    @ViewBuilder
    private var groveControls: some View {
        groveHeader
            .padding(.top, 8)

        searchBar
            .padding(.horizontal, 16)
            .padding(.top, 16)

        filterChips
            .padding(.top, 12)

        if selectedFilter == .thriving || selectedFilter == .attention {
            Text(
                selectedFilter == .thriving
                ? "Thriving = Healthy/Thriving plants that are not overdue for water."
                : "Needs Care = overdue for water or marked Needs Attention/Struggling."
            )
            .font(CultivarFont.undergrowth(11))
            .foregroundColor(.stoneGrey)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 6)
        }

        if overduePlantCount > 0 {
            urgencyBanner
                .padding(.horizontal, 16)
                .padding(.top, 16)
        }
    }

    private var listModeLayout: some View {
        VStack(spacing: 0) {
            groveControls

            if filteredPlants.isEmpty {
                Spacer(minLength: 40)
                emptyGroveView
                Spacer(minLength: 100)
            } else {
                plantList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Header
    var groveHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Grove")
                    .font(CultivarFont.oldGrowth(28))
                    .foregroundColor(.mushroomCream)
                Text(headerSubtitle)
                    .font(CultivarFont.undergrowth(14))
                    .foregroundColor(.sageGreen.opacity(0.8))
            }
            Spacer()
            HStack(spacing: 12) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.stoneGrey)
                        .font(.system(size: 18))
                }
                Button {
                    withAnimation { viewMode = viewMode == .grid ? .list : .grid }
                } label: {
                    Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2.fill")
                        .foregroundColor(.mossGreen)
                        .font(.system(size: 18))
                }
                if viewMode == .grid {
                    if isSelectingForDeletion {
                        Button("Cancel") {
                            clearDeleteSelection()
                        }
                        .font(CultivarFont.undergrowth(12))
                        .foregroundColor(.stoneGrey)

                        Button {
                            promptDeleteSelectedPlants()
                        } label: {
                            Image(systemName: "trash.fill")
                                .foregroundColor(selectedPlantIDs.isEmpty ? .stoneGrey.opacity(0.4) : .petalCoral)
                                .font(.system(size: 18))
                        }
                        .disabled(selectedPlantIDs.isEmpty)
                    } else {
                        Button {
                            isSelectingForDeletion = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.petalCoral)
                                .font(.system(size: 18))
                        }
                        .accessibilityLabel("Select plants to delete")
                    }
                }
                // Season indicator
                SeasonBadge()
            }
        }
        .padding(.horizontal, 20)
    }

    private var headerSubtitle: String {
        if isSelectingForDeletion {
            return selectedPlantIDs.isEmpty
                ? "Select plants to remove"
                : "\(selectedPlantIDs.count) selected"
        }
        return "\(plants.count) plants growing"
    }

    // MARK: - Search Bar
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.stoneGrey)
            TextField("Search your grove...", text: $searchText)
                .foregroundColor(.mushroomCream)
                .font(CultivarFont.undergrowth(15))
        }
        .padding(12)
        .background(Color.richSoil.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mossGreen.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Filter Chips
    var filterChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(filterRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { filter in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedFilter = filter
                            }
                        } label: {
                            Text(filterTitle(filter))
                                .font(CultivarFont.undergrowth(13))
                                .fontWeight(selectedFilter == filter ? .bold : .regular)
                                .foregroundColor(selectedFilter == filter ? .forestFloor : .sageGreen)
                                .lineLimit(1)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    selectedFilter == filter
                                    ? Color.mossGreen
                                    : Color.midForest.opacity(0.8)
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.mossGreen.opacity(selectedFilter == filter ? 0 : 0.4), lineWidth: 1)
                                )
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(filterTitle(filter))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Urgency Banner
    var urgencyBanner: some View {
        return HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundColor(.rainwaterBlue)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(overduePlantCount) \(overduePlantCount == 1 ? "plant needs" : "plants need") water")
                    .font(CultivarFont.undergrowth(14))
                    .fontWeight(.semibold)
                    .foregroundColor(.mushroomCream)
                Text("Tap thirsty plants to log a watering")
                    .font(CultivarFont.undergrowth(12))
                    .foregroundColor(.driedGrass.opacity(0.7))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.stoneGrey)
        }
        .padding(14)
        .forestCard(isUrgent: true)
    }

    // MARK: - Plant Grid
    var plantGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(filteredPlants) { plant in
                PlantGridCard(
                    plant: plant,
                    now: now,
                    isSelectionMode: isSelectingForDeletion,
                    isSelected: selectedPlantIDs.contains(plant.id),
                    onTap: {
                        if isSelectingForDeletion {
                            toggleSelection(for: plant)
                        } else {
                            selectedPlant = plant
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Plant List
    var plantList: some View {
        List {
            ForEach(filteredPlants) { plant in
                PlantListRow(plant: plant, now: now) {
                    selectedPlant = plant
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        promptDelete(for: plant)
                    } label: {
                        Label("Delete Plant", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete \(plant.displayName)")
                    .accessibilityHint("Removes this plant from your grove.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 96)
        }
    }

    // MARK: - Empty State
    var emptyGroveView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            Text("🌱")
                .font(.system(size: 64))
            Text("Your grove awaits")
                .font(CultivarFont.oldGrowth(22))
                .foregroundColor(.mushroomCream)
            Text("Tap + to plant your first seed")
                .font(CultivarFont.undergrowth(15))
                .foregroundColor(.stoneGrey)
            Spacer(minLength: 60)
        }
    }

    private func isDueForWaterToday(_ plant: Plant) -> Bool {
        guard let days = plant.daysUntilWater(relativeTo: now) else { return true }
        return days <= 0
    }

    private func isOverdueForWater(_ plant: Plant) -> Bool {
        guard let days = plant.daysUntilWater(relativeTo: now) else { return true }
        return days < 0
    }

    func promptDelete(for plant: Plant) {
        plantsPendingDeletion = [plant]
        showDeletePlantConfirm = true
    }

    func promptDeleteSelectedPlants() {
        let selectedPlants = selectedPlantsForDeletion
        guard !selectedPlants.isEmpty else { return }
        plantsPendingDeletion = selectedPlants
        showDeletePlantConfirm = true
    }

    func toggleSelection(for plant: Plant) {
        if selectedPlantIDs.contains(plant.id) {
            selectedPlantIDs.remove(plant.id)
        } else {
            selectedPlantIDs.insert(plant.id)
        }
    }

    func clearDeleteSelection() {
        isSelectingForDeletion = false
        selectedPlantIDs.removeAll()
    }

    func schedulePlantDeletion(_ plantsToDelete: [Plant]) {
        finalizePendingDeleteIfNeeded()

        undoDeleteMessage = plantsToDelete.count == 1
            ? "\(plantsToDelete[0].displayName) removed."
            : "\(plantsToDelete.count) plants removed."
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showUndoDeleteBanner = true
        }

        let workItem = DispatchWorkItem {
            let idsToDelete = Set(plantsToDelete.map(\.id))
            if let openPlant = selectedPlant, idsToDelete.contains(openPlant.id) {
                selectedPlant = nil
            }
            plantsToDelete.forEach { modelContext.delete($0) }
            withAnimation(.easeOut(duration: 0.2)) {
                showUndoDeleteBanner = false
            }
            clearDeleteSelection()
            pendingDeleteWorkItem = nil
        }

        pendingDeleteWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: workItem)
    }

    func cancelPendingDelete() {
        pendingDeleteWorkItem?.cancel()
        pendingDeleteWorkItem = nil
        withAnimation(.easeOut(duration: 0.2)) {
            showUndoDeleteBanner = false
        }
    }

    func finalizePendingDeleteIfNeeded() {
        guard let existing = pendingDeleteWorkItem else { return }
        existing.perform()
        pendingDeleteWorkItem = nil
    }
}

// MARK: - Plant Grid Card
struct PlantGridCard: View {
    let plant: Plant
    let now: Date
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 0) {
                    // Photo / emoji top
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if let img = plant.profileImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                ZStack {
                                    ForestGradients.mossCard
                                    Text(plant.emoji)
                                        .font(.system(size: 48))
                                }
                            }
                        }
                        .frame(height: 130)
                        .clipped()

                        if isSelectionMode {
                            HStack {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(isSelected ? .mossGreen : .mushroomCream.opacity(0.8))
                                Spacer()
                            }
                            .padding(8)
                        }

                        if plant.isFavorite {
                            HStack {
                                Spacer()
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.petalCoral)
                            }
                            .padding(8)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plant.displayName)
                            .font(CultivarFont.canopy(15, weight: .semibold))
                            .foregroundColor(.mushroomCream)
                            .lineLimit(1)

                        if !plant.displaySubtitle.isEmpty {
                            Text(plant.displaySubtitle)
                                .font(CultivarFont.undergrowth(11))
                                .foregroundColor(.sageGreen.opacity(0.8))
                                .lineLimit(1)
                        }

                        HStack(spacing: 6) {
                            // Water status
                            HStack(spacing: 3) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(isOverdueForWater ? .rainwaterBlue : .stoneGrey.opacity(0.5))
                                if let days = plant.daysUntilWater(relativeTo: now) {
                                    Text(days <= 0 ? "Now" : "in \(days)d")
                                        .font(CultivarFont.rings(10))
                                        .foregroundColor(isOverdueForWater ? .rainwaterBlue : .stoneGrey.opacity(0.6))
                                }
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.midForest)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    isSelected
                                    ? Color.mossGreen.opacity(0.9)
                                    : Color.mossGreen.opacity(isDueForWaterToday ? 0.5 : 0.2),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )
                .opacity(isSelectionMode && !isSelected ? 0.92 : 1)
                .shadow(color: .richSoil.opacity(0.6), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
    }

    private var isDueForWaterToday: Bool {
        guard let days = plant.daysUntilWater(relativeTo: now) else { return true }
        return days <= 0
    }

    private var isOverdueForWater: Bool {
        guard let days = plant.daysUntilWater(relativeTo: now) else { return true }
        return days < 0
    }
}

// MARK: - Plant List Row
struct PlantListRow: View {
    let plant: Plant
    let now: Date
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                // Thumbnail
                Group {
                    if let img = plant.profileImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            ForestGradients.mossCard
                            Text(plant.emoji)
                                .font(.system(size: 26))
                        }
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(plant.displayName)
                        .font(CultivarFont.canopy(16, weight: .semibold))
                        .foregroundColor(.mushroomCream)
                    if !plant.displaySubtitle.isEmpty {
                        Text(plant.displaySubtitle)
                            .font(CultivarFont.undergrowth(12))
                            .foregroundColor(.sageGreen.opacity(0.8))
                    }
                    HStack(spacing: 6) {
                        CultivarBadge(plant.roomLocation.isEmpty ? "No location" : plant.roomLocation, color: .stoneGrey, icon: "mappin")
                        CultivarBadge(plant.healthStatus.rawValue, color: plant.healthStatus.color, icon: plant.healthStatus.icon)
                    }
                }
                Spacer()

                // Water indicator
                VStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .foregroundColor(isOverdueForWater ? .rainwaterBlue : .stoneGrey.opacity(0.4))
                        .font(.system(size: 16))
                    if let days = plant.daysUntilWater(relativeTo: now) {
                        Text(days <= 0 ? "Now" : "\(days)d")
                            .font(CultivarFont.rings(10))
                            .foregroundColor(isOverdueForWater ? .rainwaterBlue : .stoneGrey.opacity(0.5))
                    }
                }
            }
            .padding(12)
            .forestCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens plant details.")
    }

    private var isOverdueForWater: Bool {
        guard let days = plant.daysUntilWater(relativeTo: now) else { return true }
        return days < 0
    }
}

struct UndoDeleteBanner: View {
    let message: String
    let undoAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.mossGreen)
            Text(message)
                .font(CultivarFont.undergrowth(13))
                .foregroundColor(.mushroomCream)
                .lineLimit(2)
            Spacer()
            Button("Undo", action: undoAction)
                .font(CultivarFont.undergrowth(13))
                .foregroundColor(.goldenPollen)
                .accessibilityLabel("Undo delete")
                .accessibilityHint("Restores the pending deleted item.")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.barkBrown.opacity(0.95))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.mossGreen.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .richSoil.opacity(0.5), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Season Badge
struct SeasonBadge: View {
    var currentSeason: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "🌸 Spring"
        case 6...8: return "☀️ Summer"
        case 9...11: return "🍂 Autumn"
        default: return "❄️ Winter"
        }
    }

    var body: some View {
        Text(currentSeason)
            .font(CultivarFont.undergrowth(12))
            .foregroundColor(.driedGrass)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.barkBrown.opacity(0.4))
            .clipShape(Capsule())
    }
}

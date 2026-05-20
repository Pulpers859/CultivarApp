// PlantDetailView.swift

import SwiftUI
import SwiftData
import PhotosUI

struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: Plant
    @StateObject private var viewModel = PlantDetailViewModel()

    @State private var selectedTab: DetailTab
    @State private var showCareLog: Bool = false
    @State private var showGrowthEntry: Bool = false
    @State private var showEditPlant: Bool = false
    @State private var showDiagnosis: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showUndoDeleteBanner: Bool = false
    @State private var undoDeleteMessage: String = ""
    @State private var pendingDeleteWorkItem: DispatchWorkItem? = nil

    enum DetailTab: String, CaseIterable {
        case profile  = "Profile"
        case care     = "Care Log"
        case growth   = "Growth"
        case propagate = "Propagate"
    }

    init(plant: Plant, initialTab: DetailTab = .profile) {
        self.plant = plant
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        heroSection
                        quickActions
                            .padding(.top, 16)
                        tabSelector
                            .padding(.top, 20)
                        tabContent
                            .padding(.top, 16)
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.mossGreen)
                        .font(CultivarFont.undergrowth(15))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.spring()) {
                                viewModel.toggleFavorite(for: plant)
                            }
                        } label: {
                            Image(systemName: plant.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(plant.isFavorite ? .petalCoral : .stoneGrey)
                        }
                        .accessibilityLabel(plant.isFavorite ? "Unfavorite plant" : "Favorite plant")
                        .accessibilityHint("Toggles this plant as a favorite.")
                        Button {
                            showEditPlant = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(.mossGreen)
                        }
                        .accessibilityLabel("Edit plant")
                        .accessibilityHint("Opens plant profile editor.")
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.petalCoral)
                        }
                        .accessibilityLabel("Delete plant")
                        .accessibilityHint("Removes this plant and all related history.")
                    }
                }
            }
            .sheet(isPresented: $showCareLog) {
                LogCareView(plant: plant)
            }
            .sheet(isPresented: $showGrowthEntry) {
                AddGrowthEntryView(plant: plant)
            }
            .sheet(isPresented: $showEditPlant) {
                EditPlantView(plant: plant)
            }
            .sheet(isPresented: $showDiagnosis) {
                PlantDiagnosisView(plant: plant)
            }
            .confirmationDialog("Remove \(plant.displayName)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Remove from Grove", role: .destructive) {
                    schedulePlantDeletion()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove \(plant.displayName) and all its history.")
            }
            .safeAreaInset(edge: .bottom) {
                if showUndoDeleteBanner {
                    UndoDeleteBanner(message: undoDeleteMessage) {
                        cancelPendingDelete()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - Hero Section
    var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Photo or gradient backdrop
            Group {
                if let img = plant.profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [.canopyGreen, .midForest, .richSoil],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Text(plant.emoji)
                            .font(.system(size: 90))
                            .shadow(color: .richSoil, radius: 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 280, maxHeight: 280)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .forestFloor.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Plant info overlay
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(plant.displayName)
                            .font(CultivarFont.oldGrowth(26))
                            .foregroundColor(.mushroomCream)
                        if !plant.detailCommonName.isEmpty {
                            Text(plant.detailCommonName)
                                .font(CultivarFont.undergrowth(14))
                                .foregroundColor(.sageGreen)
                        }
                        if !plant.species.isEmpty {
                            Text(plant.species)
                                .font(.system(size: 12, weight: .regular, design: .serif))
                                .italic()
                                .foregroundColor(.driedGrass.opacity(0.7))
                        }
                    }
                    Spacer()
                    // Photo picker button
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.mushroomCream.opacity(0.7))
                            .padding(10)
                            .background(Color.richSoil.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            let data = try? await newItem?.loadTransferable(type: Data.self)
                            viewModel.applyPhotoData(data, to: plant)
                        }
                    }
                }

                HStack(spacing: 8) {
                    CultivarBadge(plant.healthStatus.rawValue, color: plant.healthStatus.color, icon: plant.healthStatus.icon)
                    if !plant.roomLocation.isEmpty {
                        CultivarBadge(plant.roomLocation, color: .stoneGrey, icon: "mappin")
                    }
                    CultivarBadge(
                        plant.isOutdoor ? "Outdoor" : "Indoor",
                        color: plant.isOutdoor ? .cedarWarm : .stoneGrey,
                        icon: plant.isOutdoor ? "sun.max.fill" : "house.fill"
                    )
                    CultivarBadge(plant.lightLevel.rawValue, color: plant.lightLevel.color, icon: plant.lightLevel.icon)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Quick Actions
    var quickActions: some View {
        HStack(spacing: 10) {
            QuickActionButton(
                icon: "drop.fill",
                label: "Water",
                color: .rainwaterBlue,
                isUrgent: plant.isOverdueForWater
            ) {
                viewModel.quickWater(for: plant)
            }

            QuickActionButton(
                icon: "sparkle",
                label: "Fertilize",
                color: .goldenPollen,
                isUrgent: false
            ) {
                viewModel.quickFertilize(for: plant)
            }

            QuickActionButton(
                icon: "waveform.path.ecg",
                label: "Diagnose",
                color: .wildBerry,
                isUrgent: plant.healthStatus == .needsAttention || plant.healthStatus == .struggling
            ) {
                showDiagnosis = true
            }

            QuickActionButton(
                icon: "chart.line.uptrend.xyaxis",
                label: "Log Growth",
                color: .mossGreen,
                isUrgent: false
            ) {
                showGrowthEntry = true
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Tab Selector
    var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(CultivarFont.undergrowth(13))
                            .fontWeight(selectedTab == tab ? .bold : .regular)
                            .foregroundColor(selectedTab == tab ? .mossGreen : .stoneGrey.opacity(0.6))
                        Rectangle()
                            .fill(selectedTab == tab ? Color.mossGreen : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .overlay(
            Rectangle()
                .fill(Color.mossGreen.opacity(0.15))
                .frame(height: 2),
            alignment: .bottom
        )
    }

    // MARK: - Tab Content
    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case .profile:
            PlantProfileTab(plant: plant)
        case .care:
            CareHistoryTab(plant: plant, showCareLog: $showCareLog)
        case .growth:
            GrowthHistoryTab(plant: plant)
        case .propagate:
            PropagationTab(plant: plant)
        }
    }

    func schedulePlantDeletion() {
        finalizePendingDeleteIfNeeded()

        undoDeleteMessage = "\(plant.displayName) removed."
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showUndoDeleteBanner = true
        }

        let workItem = DispatchWorkItem {
            modelContext.delete(plant)
            withAnimation(.easeOut(duration: 0.2)) {
                showUndoDeleteBanner = false
            }
            pendingDeleteWorkItem = nil
            dismiss()
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

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let isUrgent: Bool
    let action: () -> Void

    @State private var isPulsing: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle()
                                .stroke(color.opacity(isUrgent ? 0.8 : 0.3), lineWidth: isUrgent ? 2 : 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(CultivarFont.undergrowth(11))
                    .foregroundColor(.driedGrass.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
        }
        .scaleEffect(isPulsing ? 1.03 : 1.0)
        .onAppear(perform: updatePulseState)
        .onChange(of: isUrgent) { _, _ in
            updatePulseState()
        }
    }

    private func updatePulseState() {
        guard isUrgent else {
            isPulsing = false
            return
        }

        isPulsing = false
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}

// MARK: - Profile Tab
struct PlantProfileTab: View {
    let plant: Plant

    private var speciesInfo: PlantSpeciesInfo? {
        PlantDatabaseService.shared.lookup(
            scientificName: plant.species,
            commonName: plant.commonName
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                StatTile(label: "Time Owned", value: plant.ownedDurationCompact, icon: "calendar", color: .sageGreen)
                StatTile(label: "Water Every", value: "\(plant.wateringIntervalDays)d", icon: "drop.fill", color: .rainwaterBlue)
                StatTile(label: "Fertilize", value: "\(plant.fertilizingIntervalDays)d", icon: "sparkle", color: .goldenPollen)
            }

            // Care schedule
            VStack(alignment: .leading, spacing: 12) {
                Text("Care Schedule")
                    .font(CultivarFont.canopy(16, weight: .semibold))
                    .foregroundColor(.mushroomCream)

                CareScheduleRow(
                    icon: "drop.fill",
                    color: .rainwaterBlue,
                    label: "Watering",
                    lastDate: plant.lastWatered,
                    nextDate: plant.nextWateringDate,
                    isOverdue: plant.isOverdueForWater
                )
                RootDivider()
                CareScheduleRow(
                    icon: "sparkle",
                    color: .goldenPollen,
                    label: "Fertilizing",
                    lastDate: plant.lastFertilized,
                    nextDate: nil,
                    isOverdue: false
                )
                RootDivider()
                CareScheduleRow(
                    icon: "circle.grid.cross.fill",
                    color: .cedarWarm,
                    label: "Repotting",
                    lastDate: plant.lastRepotted,
                    nextDate: nil,
                    isOverdue: false
                )
            }
            .padding(16)
            .forestCard()

            if let speciesInfo {
                SpeciesCareCardView(info: speciesInfo)
            } else if !plant.speciesCareSummary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Care Guide")
                        .font(CultivarFont.canopy(14, weight: .semibold))
                        .foregroundColor(.mushroomCream)
                    Text(plant.speciesCareSummary)
                        .font(CultivarFont.undergrowth(13))
                        .foregroundColor(.driedGrass)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .forestCard()
            }

            // Notes
            if !plant.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(CultivarFont.canopy(14, weight: .semibold))
                        .foregroundColor(.mushroomCream)
                    Text(plant.notes)
                        .font(CultivarFont.undergrowth(14))
                        .foregroundColor(.driedGrass)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .forestCard()
            }

            // Lineage
            if !plant.parentPlantNickname.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.turn.up.left")
                        .foregroundColor(.sageGreen)
                    Text("Propagated from ")
                        .font(CultivarFont.undergrowth(13))
                        .foregroundColor(.driedGrass) +
                    Text(plant.parentPlantNickname)
                        .font(CultivarFont.undergrowth(13))
                        .foregroundColor(.sageGreen)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .forestCard()
            }
        }
        .padding(.horizontal, 16)
    }

}

// MARK: - Care History Tab
struct CareHistoryTab: View {
    @Environment(\.modelContext) private var modelContext
    let plant: Plant
    @Binding var showCareLog: Bool
    @State private var logPendingDeletion: CareLog? = nil
    @State private var showDeleteConfirm: Bool = false
    @State private var editingLog: CareLog? = nil
    @State private var showUndoDeleteBanner: Bool = false
    @State private var undoDeleteMessage: String = ""
    @State private var pendingDeleteWorkItem: DispatchWorkItem? = nil

    var sortedLogs: [CareLog] {
        plant.careLogs.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 12) {
            CultivarButton("Log Care", icon: "plus.circle.fill") {
                showCareLog = true
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            if sortedLogs.isEmpty {
                EmptyStateCard(title: "No care logs yet", subtitle: "Start logging to track your plant's history")
            } else {
                ForEach(sortedLogs) { log in
                    CareLogRow(
                        log: log,
                        onEdit: { editingLog = log },
                        onDelete: {
                            logPendingDeletion = log
                            showDeleteConfirm = true
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
        .confirmationDialog(
            "Delete this care entry?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Entry", role: .destructive) {
                guard let log = logPendingDeletion else { return }
                scheduleDelete(log)
                logPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                logPendingDeletion = nil
            }
        } message: {
            Text("This care log item will be permanently deleted.")
        }
        .sheet(item: $editingLog) { log in
            LogCareView(plant: plant, editingLog: log)
        }
        .safeAreaInset(edge: .bottom) {
            if showUndoDeleteBanner {
                UndoDeleteBanner(message: undoDeleteMessage) {
                    cancelPendingDelete()
                }
                .padding(.horizontal, 16)
            }
        }
    }

    func scheduleDelete(_ log: CareLog) {
        finalizePendingDeleteIfNeeded()
        undoDeleteMessage = "Care entry removed."
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showUndoDeleteBanner = true
        }
        let workItem = DispatchWorkItem {
            plant.careLogs.removeAll { $0.id == log.id }
            modelContext.delete(log)
            plant.refreshTrackedCareDates()
            withAnimation(.easeOut(duration: 0.2)) {
                showUndoDeleteBanner = false
            }
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

// MARK: - Growth History Tab
struct GrowthHistoryTab: View {
    @Environment(\.modelContext) private var modelContext
    let plant: Plant
    @State private var entryPendingDeletion: GrowthEntry? = nil
    @State private var showDeleteConfirm: Bool = false
    @State private var editingEntry: GrowthEntry? = nil
    @State private var showAddGrowthEntryEditor: Bool = false
    @State private var showUndoDeleteBanner: Bool = false
    @State private var undoDeleteMessage: String = ""
    @State private var pendingDeleteWorkItem: DispatchWorkItem? = nil

    var sortedEntries: [GrowthEntry] {
        plant.growthEntries.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Track measurements, milestones, and photos over time.")
                .font(CultivarFont.undergrowth(11))
                .foregroundColor(.stoneGrey)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            CultivarButton("Log Growth", icon: "plus.circle.fill") {
                showAddGrowthEntryEditor = true
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            if sortedEntries.isEmpty {
                EmptyStateCard(title: "No growth logged yet", subtitle: "Track height, leaf count, milestones, and progress photos")
                    .padding(.horizontal, 16)
            } else {
                ForEach(sortedEntries) { entry in
                    GrowthEntryRow(
                        entry: entry,
                        onEdit: { editingEntry = entry },
                        onDelete: {
                            entryPendingDeletion = entry
                            showDeleteConfirm = true
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
        .confirmationDialog(
            "Delete this growth entry?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Entry", role: .destructive) {
                guard let entry = entryPendingDeletion else { return }
                scheduleDelete(entry)
                entryPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                entryPendingDeletion = nil
            }
        } message: {
            Text("This growth record will be permanently deleted.")
        }
        .sheet(isPresented: $showAddGrowthEntryEditor) {
            AddGrowthEntryView(plant: plant)
        }
        .sheet(item: $editingEntry) { entry in
            AddGrowthEntryView(plant: plant, editingEntry: entry)
        }
        .safeAreaInset(edge: .bottom) {
            if showUndoDeleteBanner {
                UndoDeleteBanner(message: undoDeleteMessage) {
                    cancelPendingDelete()
                }
                .padding(.horizontal, 16)
            }
        }
    }

    func scheduleDelete(_ entry: GrowthEntry) {
        finalizePendingDeleteIfNeeded()
        undoDeleteMessage = "Growth entry removed."
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showUndoDeleteBanner = true
        }
        let workItem = DispatchWorkItem {
            modelContext.delete(entry)
            withAnimation(.easeOut(duration: 0.2)) {
                showUndoDeleteBanner = false
            }
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

// MARK: - Propagation Tab
struct PropagationTab: View {
    @Environment(\.modelContext) private var modelContext
    let plant: Plant
    @State private var recordPendingDeletion: PropagationRecord? = nil
    @State private var showDeleteConfirm: Bool = false
    @State private var editingRecord: PropagationRecord? = nil
    @State private var showAddPropagationEditor: Bool = false
    @State private var showUndoDeleteBanner: Bool = false
    @State private var undoDeleteMessage: String = ""
    @State private var pendingDeleteWorkItem: DispatchWorkItem? = nil

    var sortedRecords: [PropagationRecord] {
        plant.propagations.sorted { $0.dateStarted > $1.dateStarted }
    }

    var body: some View {
        VStack(spacing: 12) {
            CultivarButton("Add Propagation", icon: "plus.circle.fill") {
                showAddPropagationEditor = true
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            if sortedRecords.isEmpty {
                EmptyStateCard(title: "No propagations yet", subtitle: "Start a cutting or division to expand your grove")
                    .padding(.horizontal, 16)
            } else {
                ForEach(sortedRecords) { prop in
                    PropagationRow(
                        record: prop,
                        onEdit: { editingRecord = prop },
                        onDelete: {
                            recordPendingDeletion = prop
                            showDeleteConfirm = true
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
        .confirmationDialog(
            "Delete this propagation record?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Entry", role: .destructive) {
                guard let record = recordPendingDeletion else { return }
                scheduleDelete(record)
                recordPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                recordPendingDeletion = nil
            }
        } message: {
            Text("This propagation record will be permanently deleted.")
        }
        .sheet(isPresented: $showAddPropagationEditor) {
            PropagationRecordEditorView(plant: plant)
        }
        .sheet(item: $editingRecord) { record in
            PropagationRecordEditorView(plant: plant, editingRecord: record)
        }
        .safeAreaInset(edge: .bottom) {
            if showUndoDeleteBanner {
                UndoDeleteBanner(message: undoDeleteMessage) {
                    cancelPendingDelete()
                }
                .padding(.horizontal, 16)
            }
        }
    }

    func scheduleDelete(_ record: PropagationRecord) {
        finalizePendingDeleteIfNeeded()
        undoDeleteMessage = "Propagation removed."
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showUndoDeleteBanner = true
        }
        let workItem = DispatchWorkItem {
            modelContext.delete(record)
            withAnimation(.easeOut(duration: 0.2)) {
                showUndoDeleteBanner = false
            }
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

// MARK: - Supporting Row Views
struct CareLogRow: View {
    let log: CareLog
    let onEdit: () -> Void
    let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.careType.icon)
                .foregroundColor(.mossGreen)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(log.careType.rawValue)
                    .font(CultivarFont.undergrowth(14))
                    .foregroundColor(.mushroomCream)
                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                    .font(CultivarFont.rings(11))
                    .foregroundColor(.stoneGrey)
                if !log.notes.isEmpty {
                    Text(log.notes)
                        .font(CultivarFont.undergrowth(12))
                        .foregroundColor(.driedGrass.opacity(0.8))
                }
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.mossGreen)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .background(Color.richSoil.opacity(0.35))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Edit care entry")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.petalCoral)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .background(Color.richSoil.opacity(0.35))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Delete care entry")
            }
        }
        .padding(12)
        .forestCard()
    }
}

struct GrowthEntryRow: View {
    let entry: GrowthEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showPhotoPreview: Bool = false

    private var growthPhoto: UIImage? {
        guard let data = entry.photoData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        HStack(spacing: 12) {
            if let image = growthPhoto {
                Button {
                    showPhotoPreview = true
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 84, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.mossGreen.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.midForest)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.sageGreen)
                        .font(.system(size: 18))
                }
                .frame(width: 84, height: 84)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    if let h = entry.heightCm { Text("\(h, specifier: "%.1f") cm") }
                    if let l = entry.leafCount { Text("• \(l) leaves") }
                }
                .font(CultivarFont.rings(13))
                .foregroundColor(.mushroomCream)
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(CultivarFont.rings(11))
                    .foregroundColor(.stoneGrey)
                if let milestone = entry.milestone {
                    Text("🌟 \(milestone)")
                        .font(CultivarFont.undergrowth(12))
                        .foregroundColor(.goldenPollen)
                }
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(CultivarFont.undergrowth(11))
                        .foregroundColor(.driedGrass.opacity(0.8))
                        .lineLimit(2)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.mossGreen)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .background(Color.richSoil.opacity(0.35))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Edit growth entry")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.petalCoral)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .background(Color.richSoil.opacity(0.35))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Delete growth entry")
            }
        }
        .padding(12)
        .forestCard()
        .sheet(isPresented: $showPhotoPreview) {
            if let image = growthPhoto {
                GrowthPhotoPreviewSheet(
                    image: image,
                    title: entry.date.formatted(date: .abbreviated, time: .omitted)
                )
            }
        }
    }
}

struct PropagationRow: View {
    let record: PropagationRecord
    let onEdit: () -> Void
    let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.method.icon)
                .foregroundColor(.fernGreen)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.method.rawValue)
                    .font(CultivarFont.undergrowth(14))
                    .foregroundColor(.mushroomCream)
                Text("Started \(record.dateStarted.formatted(date: .abbreviated, time: .omitted))")
                    .font(CultivarFont.rings(11))
                    .foregroundColor(.stoneGrey)
                HStack(spacing: 6) {
                    CultivarBadge(record.isRooted ? "Rooted ✓" : "Rooting...", color: record.isRooted ? .mossGreen : .goldenPollen)
                    CultivarBadge("\(record.numberOfCuttings) cutting\(record.numberOfCuttings > 1 ? "s" : "")", color: .stoneGrey)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.mossGreen)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .background(Color.richSoil.opacity(0.35))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Edit propagation entry")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.petalCoral)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .background(Color.richSoil.opacity(0.35))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Delete propagation entry")
            }
        }
        .padding(12)
        .forestCard()
    }
}

struct StatTile: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
            Text(value)
                .font(CultivarFont.rings(16))
                .fontWeight(.bold)
                .foregroundColor(.mushroomCream)
            Text(label)
                .font(CultivarFont.undergrowth(10))
                .foregroundColor(.stoneGrey.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .forestCard()
    }
}

struct CareScheduleRow: View {
    let icon: String
    let color: Color
    let label: String
    let lastDate: Date?
    let nextDate: Date?
    let isOverdue: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(CultivarFont.undergrowth(14))
                .foregroundColor(.driedGrass)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let next = nextDate {
                    Text(isOverdue ? "Overdue" : "Due \(next.formatted(date: .abbreviated, time: .omitted))")
                        .font(CultivarFont.rings(12))
                        .foregroundColor(isOverdue ? .petalCoral : .sageGreen)
                }
                if let last = lastDate {
                    Text("Last: \(last.formatted(date: .abbreviated, time: .omitted))")
                        .font(CultivarFont.rings(10))
                        .foregroundColor(.stoneGrey.opacity(0.6))
                }
            }
        }
    }
}

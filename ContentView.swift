// ContentView.swift

import SwiftUI
import SwiftData

struct ContentView: View {
    let launchRecoveryState: LaunchRecoveryState

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \Plant.nickname) private var plants: [Plant]
    @Query private var wishlistItems: [WishlistItem]
    @Query private var plantTrades: [PlantTrade]

    @AppStorage("notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("app_name") private var appName: String = "Cultivar"

    @State private var selectedTab: AppTab = .garden
    @State private var showAddPlant: Bool = false
    @State private var hasAttemptedAutomaticRecovery: Bool = false
    @State private var recoveryAlertMessage: String = ""
    @State private var showRecoveryAlert: Bool = false

    enum AppTab: Int, CaseIterable {
        case garden
        case care
        case growth
        case habitat
        case stats
    }

    init(launchRecoveryState: LaunchRecoveryState = .standard) {
        self.launchRecoveryState = launchRecoveryState
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Deep forest floor background
            Color.forestFloor.ignoresSafeArea()

            currentTabView

            // Custom forest tab bar
            ForestTabBar(selectedTab: $selectedTab, showAddPlant: $showAddPlant)
        }
        .sheet(isPresented: $showAddPlant) {
            AddPlantView()
        }
        .task {
            NotificationService.shared.clearDeliveredReminders()
            await attemptAutomaticRecoveryIfNeeded()
        }
        .task(id: automaticBackupSignature) {
            await persistAutomaticBackup()
        }
        .task(id: reminderScheduleSignature) {
            await refreshNotificationSchedule()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                NotificationService.shared.clearDeliveredReminders()
            case .inactive, .background:
                Task {
                    await persistAutomaticBackup()
                }
            @unknown default:
                break
            }
        }
        .alert("Data Recovery", isPresented: $showRecoveryAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(recoveryAlertMessage)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case .garden:
            GardenView()
        case .care:
            CareScheduleView()
        case .growth:
            GrowthJournalView()
        case .habitat:
            EnvironmentView()
        case .stats:
            CollectionStatsView()
        }
    }

    private var reminderScheduleSignature: String {
        let reminderState = plants.map { plant in
            let nextWaterEpoch = plant.nextWateringDate?.timeIntervalSince1970 ?? 0
            return "\(plant.id.uuidString)-\(plant.wateringIntervalDays)-\(nextWaterEpoch)"
        }
        .joined(separator: ",")
        return "\(notificationsEnabled)-\(reminderState)"
    }

    private var automaticBackupSignature: String {
        let plantState = plants.map(backupSignatureFragment(for:)).joined(separator: ",")
        let wishlistState = wishlistItems.map(backupSignatureFragment(for:)).joined(separator: ",")
        let tradeState = plantTrades.map(backupSignatureFragment(for:)).joined(separator: ",")

        let sections: [String] = [appName, plantState, wishlistState, tradeState]
        return sections.joined(separator: "||")
    }

    private func backupSignatureFragment(for plant: Plant) -> String {
        let components: [String] = [
            plant.id.uuidString,
            plant.nickname,
            plant.species,
            plant.commonName,
            plant.roomLocation,
            String(plant.dateAdded.timeIntervalSince1970),
            String(plant.lastWatered?.timeIntervalSince1970 ?? 0),
            String(plant.careLogs.count),
            String(plant.growthEntries.count),
            String(plant.propagations.count),
            String(plant.environmentReadings.count),
            String(plant.photoData?.count ?? 0)
        ]
        return components.joined(separator: "|")
    }

    private func backupSignatureFragment(for item: WishlistItem) -> String {
        let components: [String] = [
            item.id.uuidString,
            item.plantName,
            item.species,
            item.priority.rawValue,
            String(item.dateAdded.timeIntervalSince1970),
            String(item.isAcquired),
            String(item.photoData?.count ?? 0)
        ]
        return components.joined(separator: "|")
    }

    private func backupSignatureFragment(for trade: PlantTrade) -> String {
        let components: [String] = [
            trade.id.uuidString,
            trade.plantName,
            trade.tradeType.rawValue,
            String(trade.date.timeIntervalSince1970)
        ]
        return components.joined(separator: "|")
    }

    @MainActor
    private func refreshNotificationSchedule() async {
        guard notificationsEnabled else {
            NotificationService.shared.cancelAllReminders()
            return
        }

        let granted = await NotificationService.shared.requestPermission()
        guard granted else {
            NotificationService.shared.cancelAllReminders()
            return
        }

        NotificationService.shared.scheduleAllReminders(plants: plants)
    }

    @MainActor
    private func persistAutomaticBackup() async {
        if let storeIsEmpty = try? PlantBackupService.currentStoreIsEmpty(modelContext: modelContext),
           storeIsEmpty {
            if let existingSnapshot = try? AutomaticBackupService.loadSnapshot(),
               PlantBackupService.snapshotContainsUserData(existingSnapshot) {
                return
            }
        }

        let snapshot = PlantBackupService.makeSnapshot(
            appName: appName,
            plants: plants,
            wishlistItems: wishlistItems,
            trades: plantTrades
        )

        do {
            try AutomaticBackupService.save(snapshot: snapshot)
        } catch {
            #if DEBUG
            print("Automatic backup failed: \(error)")
            #endif
        }
    }

    @MainActor
    private func attemptAutomaticRecoveryIfNeeded() async {
        guard !hasAttemptedAutomaticRecovery else { return }
        hasAttemptedAutomaticRecovery = true

        do {
            guard try PlantBackupService.currentStoreIsEmpty(modelContext: modelContext) else { return }

            guard let snapshot = try AutomaticBackupService.loadSnapshot() else {
                if launchRecoveryState.shouldAttemptAutomaticRecovery {
                    let modeDescription = launchRecoveryState.usedInMemoryFallback
                        ? "temporary recovery mode"
                        : "a recovery database"
                    recoveryAlertMessage = """
                    Cultivar could not open its main plant database and started in \(modeDescription), but no automatic backup was available yet.

                    Existing plants will not reappear until a valid backup is imported or the original database issue is fixed.
                    """
                    showRecoveryAlert = true
                }
                return
            }

            guard PlantBackupService.snapshotContainsUserData(snapshot) else {
                return
            }

            let result = try PlantBackupService.restore(snapshot: snapshot, modelContext: modelContext)
            if let restoredAppName = result.restoredAppName {
                appName = restoredAppName
            }

            let recoveryReason: String
            if let originalStoreErrorDescription = launchRecoveryState.originalStoreErrorDescription,
               !originalStoreErrorDescription.isEmpty {
                recoveryReason = " after the main database failed to open"
            } else {
                recoveryReason = " after it launched with an empty database"
            }

            let durabilityNote = launchRecoveryState.usedInMemoryFallback
                ? " The app is still in temporary in-memory mode, so export a JSON backup from Settings before closing it."
                : ""

            recoveryAlertMessage = """
            Cultivar restored \(result.plantCount) plant\(result.plantCount == 1 ? "" : "s") from its automatic backup\(recoveryReason).\(durabilityNote)
            """
            showRecoveryAlert = true
        } catch {
            recoveryAlertMessage = """
            Cultivar found a backup, but the automatic restore failed: \(error.localizedDescription)
            """
            showRecoveryAlert = true
        }
    }
}

// MARK: - Custom Forest Tab Bar
struct ForestTabBar: View {
    @Binding var selectedTab: ContentView.AppTab
    @Binding var showAddPlant: Bool

    var body: some View {
        HStack(alignment: .bottom) {
            tabButton(for: .garden, icon: "leaf.fill", label: "Grove")
            tabButton(for: .care, icon: "drop.fill", label: "Care")

            // Center action button — Add Plant
            Button {
                showAddPlant = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.mossGreen, .canopyGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: .mossGreen.opacity(0.5), radius: 12, x: 0, y: -4)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.forestFloor)
                }
            }
            .offset(y: -14)
            .frame(maxWidth: .infinity)

            tabButton(for: .growth, icon: "chart.line.uptrend.xyaxis", label: "Growth")
            tabButton(for: .habitat, icon: "thermometer.medium", label: "Habitat")
            tabButton(for: .stats, icon: "tree.fill", label: "Stats")
        }
        .padding(.horizontal, 8)
        .background(
            Rectangle()
                .fill(Color.richSoil.opacity(0.97))
                .overlay(
                    Rectangle()
                        .fill(Color.mossGreen.opacity(0.15))
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(for tab: ContentView.AppTab, icon: String, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: selectedTab == tab ? .bold : .regular))
                    .foregroundColor(selectedTab == tab ? .mossGreen : .stoneGrey.opacity(0.6))
                    .scaleEffect(selectedTab == tab ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3), value: selectedTab)

                Text(label)
                    .font(CultivarFont.undergrowth(10))
                    .foregroundColor(selectedTab == tab ? .mossGreen : .stoneGrey.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

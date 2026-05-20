// CultivarApp.swift

import SwiftUI
import SwiftData

struct LaunchRecoveryState {
    let usedRecoveryStore: Bool
    let usedInMemoryFallback: Bool
    let originalStoreErrorDescription: String?

    static let standard = LaunchRecoveryState(
        usedRecoveryStore: false,
        usedInMemoryFallback: false,
        originalStoreErrorDescription: nil
    )

    var shouldAttemptAutomaticRecovery: Bool {
        usedRecoveryStore || usedInMemoryFallback
    }
}

@main
struct CultivarApp: App {
    
    let modelContainer: ModelContainer
    let launchRecoveryState: LaunchRecoveryState
    
    init() {
        let schema = Schema([
            Plant.self,
            CareLog.self,
            GrowthEntry.self,
            PropagationRecord.self,
            EnvironmentReading.self,
            WishlistItem.self,
            PlantTrade.self
        ])

        do {
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: CultivarMigrationPlan.self,
                configurations: [modelConfiguration]
            )
            launchRecoveryState = .standard
        } catch {
            let originalStoreError = error

            // If the main store becomes unreadable, keep the app on a persistent
            // recovery store so automatic backup restore can repopulate the data.
            do {
                let recoveryConfig = ModelConfiguration(
                    "CultivarRecoveryStore",
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true
                )
                modelContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: CultivarMigrationPlan.self,
                    configurations: [recoveryConfig]
                )
                launchRecoveryState = LaunchRecoveryState(
                    usedRecoveryStore: true,
                    usedInMemoryFallback: false,
                    originalStoreErrorDescription: String(describing: originalStoreError)
                )
            } catch {
                let recoveryStoreError = error

                // Last-resort fallback to avoid launch-time hard crash.
                do {
                    let inMemoryConfig = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: true,
                        allowsSave: true
                    )
                    modelContainer = try ModelContainer(
                        for: schema,
                        migrationPlan: CultivarMigrationPlan.self,
                        configurations: [inMemoryConfig]
                    )
                    launchRecoveryState = LaunchRecoveryState(
                        usedRecoveryStore: false,
                        usedInMemoryFallback: true,
                        originalStoreErrorDescription: """
                        Primary store failed: \(originalStoreError)
                        Recovery store failed: \(recoveryStoreError)
                        """
                    )
                    assertionFailure(
                        "Persistent SwiftData store failed. Running in-memory only. " +
                        "Primary error: \(originalStoreError). Recovery error: \(recoveryStoreError)"
                    )
                } catch {
                    fatalError("Could not create any ModelContainer: \(error)")
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(launchRecoveryState: launchRecoveryState)
                .modelContainer(modelContainer)
        }
    }
}

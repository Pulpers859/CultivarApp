// MigrationPlan.swift

import SwiftData

// MARK: - Migration Plan
// Never remove old versions — only append new ones.

enum CultivarMigrationPlan: SchemaMigrationPlan {
    
    static var schemas: [any VersionedSchema.Type] {
        [CultivarSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
    }
}

// MARK: - Schema V1
enum CultivarSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            Plant.self,
            CareLog.self,
            GrowthEntry.self,
            PropagationRecord.self,
            EnvironmentReading.self,
            WishlistItem.self,
            PlantTrade.self
        ]
    }
}

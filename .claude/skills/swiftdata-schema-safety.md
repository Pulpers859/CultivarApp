# SwiftData Schema Safety

Use this when a task touches `@Model` types, persisted properties, relationships, or `MigrationPlan.swift`.

## Focus Files
- `Plant.swift`
- `SupportingModels.swift`
- `MigrationPlan.swift`
- `SettingsView.swift`
- `PlantBackupService.swift`
- `DATA_SAFETY_CHECKLIST.md`

## Workflow
1. Classify the change: additive field, rename, delete, type change, relationship change, or schema move.
2. Treat rename/delete/type/relationship changes as migration work until proven otherwise.
3. Check whether backup export/import structs also need updates.
4. Check whether recovery-store startup and automatic restore behavior still make sense.
5. Identify the smallest regression test coverage needed.

## Minimum Output
- Risk level: `safe additive`, `needs migration`, or `unsafe as written`
- Files that must change together
- Tests to run or add
- Clear ship/no-ship recommendation for the schema change

## Avoid
- Unrelated view refactors
- Hand-waving around migration safety
- Claiming persistence is safe without checking backup/import compatibility

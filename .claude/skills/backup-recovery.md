# Backup And Recovery

Use this when a task touches export/import, automatic backup, launch recovery, restore behavior, or clear-all data flows.

## Focus Files
- `SettingsView.swift`
- `PlantBackupService.swift`
- `ContentView.swift`
- `CultivarApp.swift`
- `CultivarAppTests/PlantBackupServiceTests.swift`
- `DATA_SAFETY_CHECKLIST.md`

## Workflow
1. Trace the affected path: export, import, automatic save, launch recovery, or clear-all.
2. Check whether the JSON shape changed and whether older backups still decode safely.
3. Check whether restore updates existing records without duplicating or silently dropping related history.
4. Check app-name restore and automatic-backup deletion behavior.
5. Call out any user-data-loss path immediately.

## Minimum Output
- What user data could be lost, duplicated, or become stale
- Whether the change is backward-compatible with existing backups
- Which test proves the fix or reveals the gap

## Avoid
- Treating backup code as “just settings”
- Silent changes to clear-all semantics

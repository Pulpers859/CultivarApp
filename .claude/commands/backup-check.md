---
description: Review backup, import, restore, and launch-recovery changes for regression risk
argument-hint: [change summary or touched files]
---

Use `@.claude/skills/backup-recovery.md` to review this change: $ARGUMENTS

Focus on:
- `@SettingsView.swift`
- `@PlantBackupService.swift`
- `@ContentView.swift`
- `@CultivarApp.swift`
- `@CultivarAppTests/PlantBackupServiceTests.swift`

Return:
1. Possible data-loss or duplication paths
2. Backward-compatibility risks
3. Best proof test for this change
4. Whether the change is safe to ship

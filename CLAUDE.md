# Cultivar AI Workflow

Product quality comes first. Keep the AI layer small, explicit, and useful.

## What This Project Actually Is
- A single-app SwiftUI + SwiftData codebase with most source files at repo root.
- No `.xcodeproj` is checked in here, so do not pretend builds/tests ran unless a real Xcode project is available and used.
- The app's real risk is not styling polish. It is losing plant data, drifting reminder logic, or breaking backup/recovery flows.

## Highest-Risk Surfaces
1. SwiftData schema changes in `Plant.swift`, `SupportingModels.swift`, and `MigrationPlan.swift`
2. Backup, import, automatic recovery, and recovery-store behavior in `SettingsView.swift`, `PlantBackupService.swift`, `ContentView.swift`, and `CultivarApp.swift`
3. Watering date math and reminder scheduling in `WateringSchedule.swift`, `PlantCareService.swift`, `NotificationService.swift`, and `ContentView.swift`
4. AI request/config/parsing behavior in `ClaudeService.swift`, `Config.swift`, `PlantSpeciesDatabase.swift`, `PlantDiagnosisView.swift`, and `AddPlantView.swift`
5. Destructive flows like delete, clear-all, and cascade behavior covered by `DeletionBehaviorTests.swift`

## Default Workflow
- Start by naming the risk surface the task touches.
- Inspect the smallest relevant file set first; do not “review the whole app” unless explicitly asked.
- Make the smallest fix that meaningfully reduces the bug or regression risk.
- Run or specify the smallest relevant test scope. Prefer targeted suites over generic broad sweeps.
- If behavior, operational guidance, or known risks changed, update `HANDOFF.md`.

## Use The Project Skills
- Schema or persistent model change: `@.claude/skills/swiftdata-schema-safety.md`
- Backup/import/recovery change: `@.claude/skills/backup-recovery.md`
- Watering/reminder/date logic change: `@.claude/skills/care-schedule-reminders.md`
- Claude/API/config/parsing change: `@.claude/skills/ai-integration-guardrails.md`

## Hard Rules
- No silent auto-commits, auto-pushes, destructive resets, or broad mutating hooks.
- Do not add “helpful” automation that changes data, files, or app state behind the user's back.
- Do not expand the AI surface area unless it solves a current product problem.
- When schema changes are risky, say so plainly and require migration planning.
- When the repo setup prevents reliable verification, say exactly what could not be verified.

## Low-ROI Ideas To Reject
- Auto-running large review prompts on every change
- Broad “architectural improvement” passes without a concrete bug or product need
- Hooks that auto-format, auto-commit, auto-push, or auto-edit files
- Generic AI summaries that do not identify a concrete regression risk or next action

# Cultivar AI Workflow

Product quality comes first. Keep the AI layer small, explicit, and useful.

## What This Project Actually Is
- A single-app SwiftUI + SwiftData codebase with app sources under `Cultivar/`, tests under `CultivarAppTests/`, and the checked-in Xcode project under `Cultivar.xcodeproj/`.
- Do not pretend Apple builds/tests ran unless a real Xcode environment was used.
- The app's real risk is not styling polish. It is losing plant data, drifting reminder logic, or breaking backup/recovery flows.

## Highest-Risk Surfaces
1. SwiftData schema changes in `Cultivar/Plant.swift`, `Cultivar/SupportingModels.swift`, and `Cultivar/MigrationPlan.swift`
2. Backup, import, automatic recovery, and recovery-store behavior in `Cultivar/SettingsView.swift`, `Cultivar/PlantBackupService.swift`, `Cultivar/ContentView.swift`, and `Cultivar/CultivarApp.swift`
3. Watering date math and reminder scheduling in `Cultivar/WateringSchedule.swift`, `Cultivar/PlantCareService.swift`, `Cultivar/NotificationService.swift`, and `Cultivar/ContentView.swift`
4. AI request/config/parsing behavior in `Cultivar/ClaudeService.swift`, `Cultivar/Config.swift`, `Cultivar/PlantSpeciesDatabase.swift`, `Cultivar/PlantDiagnosisView.swift`, and `Cultivar/AddPlantView.swift`
5. Destructive flows like delete, clear-all, and cascade behavior covered by `DeletionBehaviorTests.swift`

## Default Workflow
- Start by naming the risk surface the task touches.
- Inspect the smallest relevant file set first; do not “review the whole app” unless explicitly asked.
- Make the smallest fix that meaningfully reduces the bug or regression risk.
- Run or specify the smallest relevant test scope. Prefer targeted suites over generic broad sweeps.
- If behavior, operational guidance, or known risks changed, update `HANDOFF.md`.

## Git Workflow Rule
- `main` is the only allowed working branch.
- Commit directly to `main` and push directly to `origin/main`.
- Do not create side branches, feature branches, revive `dev`, or use pull requests.
- Only break this rule if the user explicitly asks for a branch or PR in that session.

## External-Agent Reconciliation Rule
- If the user mentions prior work by another AI agent, another machine, another terminal, or another conversation, do not assume the current diff or latest visible commit tells the full story.
- Before making new edits, rebases, resets, merges, or sync claims, perform an external-agent reconciliation pass.
- Inspect any outside artifact the user provides, such as a transcript, chat export, screenshot, commit list, or claimed fix summary.
- Compare those claims against the current local files, the local Git history, and the current `main` branch on GitHub.
- Tell the user plainly whether each claimed change is present, missing, partially landed, or overwritten.
- Do not call the repo fully assessed or in sync until that reconciliation step is complete whenever outside agent work is part of the context.

## Use The Project Skills
- Schema or persistent model change: `@.claude/skills/swiftdata-schema-safety.md`
- Backup/import/recovery change: `@.claude/skills/backup-recovery.md`
- Watering/reminder/date logic change: `@.claude/skills/care-schedule-reminders.md`
- Claude/API/config/parsing change: `@.claude/skills/ai-integration-guardrails.md`

## Hard Rules
- No silent auto-commits, auto-pushes, destructive resets, or broad mutating hooks.
- No branch workflow, side branches, or PR workflow unless the user explicitly asks for it.
- Do not add “helpful” automation that changes data, files, or app state behind the user's back.
- Do not expand the AI surface area unless it solves a current product problem.
- When schema changes are risky, say so plainly and require migration planning.
- When the repo setup prevents reliable verification, say exactly what could not be verified.

## Low-ROI Ideas To Reject
- Auto-running large review prompts on every change
- Broad “architectural improvement” passes without a concrete bug or product need
- Hooks that auto-format, auto-commit, auto-push, or auto-edit files
- Generic AI summaries that do not identify a concrete regression risk or next action

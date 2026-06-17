# CultivarApp

Cultivar is a single-app SwiftUI + SwiftData iOS project for plant tracking, care schedules, reminders, backups, and AI-assisted diagnosis.

## Source Of Truth
- Repo root: `C:\Dev\CultivarApp`
- App code: `Cultivar/`
- Xcode project: `Cultivar.xcodeproj/`
- Tests: `CultivarAppTests/`

## Repo Layout
- `Cultivar/`: app source, models, services, views, assets, bundled data
- `CultivarAppTests/`: logic-oriented test coverage
- `.claude/`: repo-local AI skills, commands, and settings
- `docs/`: project handoff, safety notes, and reusable templates
- `AGENTS.md`: repo constitution for all future agents
- `CLAUDE.md`: concise repo workflow and risk notes
- `HANDOFF.md`: running session history and decisions

## High-Risk Areas
1. SwiftData schema and migration behavior
2. Backup, import, and recovery flows
3. Watering date math and notification scheduling
4. Destructive delete / clear-all paths
5. AI request/config/parsing behavior

## Verification Reality
- Git, docs, and repo structure can be validated from this Windows workspace.
- Real iOS build, simulator, and runtime validation require macOS/Xcode.

## Docs
- Start with [docs/README.md](C:/Dev/CultivarApp/docs/README.md)
- Repo-specific workflow lives in [docs/agent/PROJECT_HANDOFF.md](C:/Dev/CultivarApp/docs/agent/PROJECT_HANDOFF.md)
- Data safety guidance lives in [docs/safety/DATA_SAFETY_CHECKLIST.md](C:/Dev/CultivarApp/docs/safety/DATA_SAFETY_CHECKLIST.md)

---
description: Review AI request, config, and parsing changes for reliability and safe failure behavior
argument-hint: [change summary or touched files]
---

Use `@.claude/skills/ai-integration-guardrails.md` to review this change: $ARGUMENTS

Focus on:
- `@ClaudeService.swift`
- `@Config.swift`
- `@PlantSpeciesDatabase.swift`
- `@PlantDiagnosisView.swift`
- `@AddPlantView.swift`

Return:
1. Failure modes affected
2. Parsing/config risks
3. User-facing error behavior
4. Whether the change reduces or increases product risk

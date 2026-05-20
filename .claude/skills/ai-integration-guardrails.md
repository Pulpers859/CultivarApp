# AI Integration Guardrails

Use this when a task touches the Anthropic request path, API-key sourcing, species lookup parsing, diagnosis prompts, or AI-driven autofill behavior.

## Focus Files
- `ClaudeService.swift`
- `Config.swift`
- `PlantSpeciesDatabase.swift`
- `PlantDiagnosisView.swift`
- `AddPlantView.swift`
- `SpeciesCareCardView.swift`

## Workflow
1. Check the missing-key path first.
2. Check retry and error handling before changing prompts.
3. If JSON is expected from the model, verify the cleanup and decode path explicitly.
4. Keep user-facing failures helpful but non-destructive.
5. Prefer deterministic parsing and cached fallbacks over prompt cleverness.

## Minimum Output
- What happens with no API key
- What happens on malformed or fenced model output
- Whether the change increases or reduces product risk

## Avoid
- Expanding AI features when the task is really a persistence or UX bug
- Hardcoding secrets
- Treating prompt text as the only failure surface

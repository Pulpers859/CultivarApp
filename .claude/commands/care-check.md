---
description: Review watering schedule or reminder changes for date-math and notification regressions
argument-hint: [change summary or touched files]
---

Use `@.claude/skills/care-schedule-reminders.md` to review this change: $ARGUMENTS

Focus on:
- `@WateringSchedule.swift`
- `@PlantCareService.swift`
- `@NotificationService.swift`
- `@ContentView.swift`
- `@CultivarAppTests/WateringScheduleTests.swift`
- `@CultivarAppTests/PlantCareServiceTests.swift`

Return:
1. Behavior being changed
2. Edge cases at risk
3. Minimal tests to run or add
4. Safe/unsafe assessment

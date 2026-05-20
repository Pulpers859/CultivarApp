# Care Schedule And Reminders

Use this when a task touches watering intervals, next-watering math, notification scheduling, care logging side effects, or scene-based reminder refresh.

## Focus Files
- `WateringSchedule.swift`
- `PlantCareService.swift`
- `NotificationService.swift`
- `ContentView.swift`
- `Plant.swift`
- `CultivarAppTests/WateringScheduleTests.swift`
- `CultivarAppTests/PlantCareServiceTests.swift`

## Workflow
1. Trace the path from user action to persisted date change to next due date to scheduled reminder.
2. Check interval normalization and never-watered behavior.
3. Check that no reminder is scheduled in the past.
4. Check cancel/reschedule behavior after edits, deletes, and notification disablement.
5. Prefer extracting testable date logic over adding UI-only fixes.

## Minimum Output
- Exact rule being preserved or changed
- Edge cases affected
- Smallest tests that cover the change

## Avoid
- Mixing UI polish with scheduling logic review
- Assuming notification bugs are only UI bugs

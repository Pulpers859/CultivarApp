# CultivarAppTests Setup

This workspace currently has source files only (no `.xcodeproj` checked in), so the test target must be added in Xcode:

1. Create an iOS App project (or open your existing one) that uses these source files.
2. Add a new target: `File -> New -> Target -> Unit Testing Bundle`.
3. Name the target `CultivarAppTests`.
4. Add all files in this folder to that test target.
5. Ensure the app module is importable as `Cultivar` or `CultivarApp`.
6. Run tests with `Product -> Test`.

Included suites:
- `ParsingUtilsTests`
- `PlantModelLogicTests`
- `SupportingModelsLogicTests`
- `PlantCareServiceTests`
- `WateringScheduleTests`
- `PlantDetailViewModelTests`

# 🌿 Plant Care App — Project Handoff & Development Guide

> **Rename Note:** The app is currently named "Cultivar" in all files. The owner has not yet finalized the name. Leading candidates include: **Rooted**, **Canopy**, **Grove**, **Sprig**, **Tendril**, **Leafkeep**, **Frond**, **Foliar**, **Lush**, **Mycelium**. Update the app name in `Info.plist → CFBundleDisplayName`, `CultivarApp.swift`, and Settings screen `appName` default. Consider a global find-replace for "Cultivar" across file display strings once decided.

---

## 📁 Project Structure

```
Cultivar/Cultivar/
├── CultivarApp.swift                  ← App entry point, SwiftData container setup
├── Models/
│   ├── Plant.swift                   ← Core plant model (all properties)
│   ├── SupportingModels.swift        ← CareLog, GrowthEntry, PropagationRecord,
│   │                                    EnvironmentReading, WishlistItem, PlantTrade
│   └── MigrationPlan.swift           ← SwiftData versioned schema migration
├── Views/
│   ├── DesignSystem.swift            ← Full forest design system (colors, fonts, components)
│   ├── ContentView.swift             ← Root TabView + custom ForestTabBar
│   ├── GardenView.swift              ← Main plant collection (grid + list modes)
│   ├── PlantDetailView.swift         ← Full plant profile (4 tabs: Profile, Care, Growth, Propagate)
│   ├── AddPlantView.swift            ← Add new plant + EditPlantView
│   ├── SecondaryViews.swift          ← CareScheduleView, GrowthJournalView,
│   │                                    EnvironmentView, CollectionStatsView
│   ├── ActionSheets.swift            ← LogCareView, AddGrowthEntryView, PlantDiagnosisView,
│   │                                    AddEnvironmentReadingView, AddWishlistItemView
│   └── SettingsView.swift            ← API key, preferences, app name customization
├── Services/
│   ├── ClaudeService.swift           ← Anthropic API integration (callClaudeAPI function)
│   └── NotificationService.swift     ← Local notification scheduling for watering
└── Resources/
    └── Info.plist                    ← Camera, photo library, notification permissions
```

---

## 🏗️ Architecture Decisions

### Data Persistence
- **SwiftData** with **versioned schema migration** via `CultivarMigrationPlan`
- Schema version `V1.0.0` is defined in `MigrationPlan.swift`
- **To safely add new model properties in future updates:** add them to the model with default values (required for SwiftData non-breaking migration), then add a new `CultivarSchemaV2` enum and append it to `schemas` array — never remove old versions
- All `@Model` properties have default values at declaration level to prevent SwiftData migration failures
- Photos stored as `Data?` (JPEG) directly on the model — suitable for MVP; consider moving large images to the filesystem for performance at scale

### AI Integration
- Claude API key stored in `UserDefaults` under key `"anthropic_api_key"` (set via Settings screen)
- `callClaudeAPI(systemPrompt:userMessage:)` is a free async function in `ClaudeService.swift`
- Currently used in `PlantDiagnosisView` — the "Grove Keeper" plant health assistant
- Model: `claude-sonnet-4-20250514`

### Design System
- All colors defined as `Color` extensions in `DesignSystem.swift` using hex init
- Forest palette: `forestFloor`, `underbrush`, `midForest`, `forestDapple` (backgrounds), `canopyGreen`, `mossGreen`, `fernGreen`, `sageGreen` (greens), `barkBrown`, `walnutBrown`, `richSoil` (earths), plus accent colors
- Fonts: `CultivarFont.canopy()` (Georgia display), `CultivarFont.undergrowth()` (Georgia body), `CultivarFont.rings()` (Courier New mono for data)
- Reusable components: `CultivarBadge`, `CultivarButton`, `ForestCardStyle` (via `.forestCard()` modifier), `WaterProgressBar`, `RootDivider`, `FormSection`, `CultivarFormField`, `StepperField`

---

## ✅ What's Built (MVP Complete)

- [x] Plant profiles with photo, emoji, species, location, light level, acquisition date
- [x] Care scheduling (watering, fertilizing, repotting, pruning intervals)
- [x] Quick water/fertilize actions from plant detail
- [x] Care log with type, soil moisture, notes, fertiliser used
- [x] Growth journal (height, leaf count, stem count, milestones, photos)
- [x] Propagation tracker (method, cuttings count, rooting/potting dates)
- [x] Plant health diagnosis via Claude API ("Grove Keeper")
- [x] Environment readings (temperature, humidity, light lux) per room
- [x] Room-grouped habitat view
- [x] Collection stats (health distribution, rooms, oldest plant)
- [x] Wishlist with priority tiers
- [x] Plant trade/acquisition log
- [x] Seasonal badge (spring/summer/autumn/winter)
- [x] Watering urgency banner and overdue indicators
- [x] Search and filter (All, Thirsty, Thriving, Needs Care, Favorites)
- [x] Grid + list view toggle
- [x] Favorite plants
- [x] Local watering reminder notifications
- [x] Settings with API key management and app name customization
- [x] Versioned SwiftData migration plan (future-safe)
- [x] Dark forest aesthetic throughout

---

## 🚧 Known Issues / Build Notes

1. **Xcode Project File** — `Cultivar.xcodeproj` is now checked in. The app target uses a filesystem-synchronized `Cultivar/` folder, so if files appear red in Xcode, first verify the app sources actually live under `Cultivar/` rather than at repo root. Minimum deployment should remain **iOS 17**.

2. **Tab Bar Index Logic** — `ContentView.swift` ForestTabBar has a center "+" button that offsets indices. The current tab selection logic uses `index` directly; test and adjust the `selectedTab` mapping if tab switching feels off after the center button insertion.

3. **`SoilMoisture` enum** — Fixed from `case bone dry` (invalid syntax) to `case boneDry`. Verify the fix propagated correctly in `SupportingModels.swift`.

4. **Photo Storage** — Photos saved as `Data?` on the model work for small collections. For >50 plants with photos, consider offloading image data to the Documents directory and storing only file paths in SwiftData.

5. **Notifications** — `NotificationService.scheduleAllReminders()` needs to be called on app launch from `CultivarApp.swift` or a scene delegate. Hook it up after the model container is ready.

6. **Claude API key entry** — Settings screen uses `@AppStorage("anthropic_api_key")` which maps to `UserDefaults`. This is adequate for a personal app but not secure for distribution. Consider using Keychain for production.

---

## 🌱 Next Steps — Priority Order

### Immediate (Phase 2)
- [ ] Hook up `NotificationService.scheduleAllReminders()` on app launch
- [ ] Add AI plant advisor tab — "Ask the Grove Keeper" free chat interface (not just diagnosis)
- [ ] Implement propagation: "Make a Child Plant" button that pre-fills a new plant with parent lineage
- [ ] Export/backup: JSON export of all plant data to Files app
- [ ] App icon — forest/leaf themed

### Short Term (Phase 3)
- [ ] **Seasonal care mode**: auto-adjust watering intervals in winter (less frequent) and summer (more frequent) based on current season
- [ ] **Plant photo timeline**: horizontal scroll of all growth photos for a plant, showing change over time
- [ ] **Care streaks**: gamified streak counter for consecutive on-time waterings
- [ ] **Room overview widget**: iOS home screen widget showing today's thirsty plants
- [ ] **Batch watering mode**: "I just watered everything" button marks all overdue plants as watered
- [ ] **Plant age milestones**: push notification when a plant reaches 6 months, 1 year, etc.
- [ ] **Companion planting suggestions**: AI-powered — "what pairs well with my monstera?"
- [ ] **Fertilizer schedule visualization**: calendar view of all upcoming care tasks

### Longer Term (Phase 4)
- [ ] **iCloud sync** via CloudKit + SwiftData (requires entitlement)
- [ ] **Plant identification via camera**: use Claude vision to identify a plant from a photo
- [ ] **Community features**: share your grove, browse others' plant profiles
- [ ] **Species database integration**: auto-fill care requirements from a plant species lookup
- [ ] **iPad / macOS support**: layout already supports landscape, needs sidebar navigation
- [ ] **Apple Watch complication**: quick "I watered X" logging from wrist
- [ ] **Health app integration**: correlate your mood/sleep with plant care consistency (fun idea)
- [ ] **Marketplace**: buy/sell/trade cuttings and propagations with location-based matching

---

## 🎨 Design Direction

**Aesthetic:** Deep forest floor to canopy — dark, organic, alive. Like your plants are living in their native woodland habitat rather than on a phone screen.

**Color system:** Three-layer background (forest floor → underbrush → mid-forest), two green families (canopy/moss for primary actions, fern/sage for secondary), earth tones (bark/walnut/cedar) for warmth, and botanical accents (gold pollen, coral petal, wild berry) for alerts and highlights.

**Typography:** Georgia serif throughout — botanical journals, field guides, old growth. Courier New for measurements and data (carved wood, ring counts). Never sans-serif system fonts.

**When pruning the aesthetic:** Start by reducing animation complexity, then simplify gradient layers, then fall back to single-weight typography. The color palette itself is the foundation — keep that even if everything else is simplified.

---

## 🔑 Key Technical References

- SwiftData migration: https://developer.apple.com/documentation/swiftdata/migratingpersistentdatausingversionedschema
- Claude API docs: https://docs.anthropic.com/en/api/messages
- PhotosPicker (SwiftUI): https://developer.apple.com/documentation/photokit/photospicker
- UNUserNotificationCenter: https://developer.apple.com/documentation/usernotifications

---

## 📋 Session History

- **Session 1** (initial build): Full project scaffolded. All models, views, services, and design system created. MVP feature set complete. App name TBD — currently "Cultivar" as placeholder throughout codebase.
- **Session 2** (April 6, 2026): Stability hardening pass. Fixed broken custom tab bar mapping so all tabs are reachable, wired reminder scheduling at app runtime, added SwiftData in-memory fallback on persistent store init failure, improved notification date safety (no past triggers), improved numeric/string parsing in modal forms, exposed Settings from Garden header, removed unused state causing warning noise, corrected wishlist priority sorting, and removed unnecessary `UIBackgroundModes` entries from `Info.plist`.
- **Session 3** (April 6, 2026): Refactor pass for maintainability. Split `ActionSheets.swift` into dedicated modal view files (`CareLoggingView.swift`, `GrowthEntryView.swift`, `PlantDiagnosisView.swift`, `AddEnvironmentReadingView.swift`, `AddWishlistItemView.swift`) and split `SecondaryViews.swift` into tab-focused files (`CareScheduleView.swift`, `GrowthJournalView.swift`, `EnvironmentView.swift`, `CollectionStatsView.swift`). Legacy aggregate files are now placeholders only to avoid duplicate type declarations.
- **Session 4** (April 6, 2026): Added a minimal unit-test suite scaffold in `CultivarAppTests/` for parsing (`ParsingUtilsTests`), plant date/model logic (`PlantModelLogicTests`), and supporting model computations (`SupportingModelsLogicTests`). Also extracted decimal parsing into shared `ParsingUtils.parseLocalizedDecimal(_:)` and updated care/environment forms to use it for testable, centralized behavior.
- **Session 5** (April 6, 2026): Centralized care logging side-effects into new `PlantCareService.recordCare(...)` to eliminate duplicated logic across `CareLoggingView`, `CareScheduleView`, and `PlantDetailView` quick actions. Added `PlantCareServiceTests` to verify log creation, date updates, and fertiliser string normalization.
- **Session 6** (April 6, 2026): Centralized watering date math into `WateringSchedule` with safe interval normalization (`>= 1 day`) and updated `Plant` + `NotificationService` to consume it. Added `WateringScheduleTests` to cover normalization, never-watered behavior, and overdue calculations.
- **Session 7** (April 6, 2026): Introduced `PlantDetailViewModel` to move `PlantDetailView` mutation logic out of the view (favorite toggle, quick water/fertilize, selected photo application). Updated `PlantDetailView` to use the view model and removed unused local animation state. Added `PlantDetailViewModelTests` for action-level behavior.
- **Session 8** (April 6, 2026): Added `DATA_SAFETY_CHECKLIST.md` with a release-time data retention checklist (bundle ID stability, SwiftData schema change rules, migration requirements, smoke tests, and recovery guidance) to reduce risk of accidental data loss during future updates.
- **Session 9** (May 11, 2026): Added a lean Claude workflow layer for future AI-assisted development: `CLAUDE.md`, focused project skills in `.claude/skills/`, reusable slash commands in `.claude/commands/`, and minimal `.claude/settings.json` guardrails. Intentionally kept hooks inactive to avoid hidden mutation and unreliable Xcode-dependent automation.
- **Session 10** (June 11, 2026): Simplified Git workflow to a single long-lived branch. `dev` was merged into `main`, `main` became the only normal work branch, and the handoff docs were updated to stop instructing future agents to use both `main` and `dev`.
- **Session 11** (June 13, 2026): Hard-coded a stricter Git rule for this repo: `main` only, direct commits/pushes on `main` only, and no side branches or PR workflow unless the user explicitly requests an exception in that session. Added `AGENTS.md` and updated the handoff/workflow docs so future agents see that rule immediately.
- **Session 12** (June 14, 2026): Added an external-agent reconciliation rule to the repo constitution. When outside agent work is mentioned, future agents must compare claimed changes against local files, local Git history, and the current GitHub `main` branch before making sync claims or deciding on edits, merges, rebases, resets, or pulls.

---

*This document should be updated at the end of each development session. Include what changed, what broke, and what decisions were made.*

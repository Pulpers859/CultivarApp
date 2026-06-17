# Data Safety Checklist

Use this checklist before shipping updates to avoid accidental data loss.

## 1) Before Any Change
- Confirm app **Bundle Identifier** is unchanged.
- Confirm you are **not uninstalling** the app from device/simulator.
- Back up a test dataset (at least a few plants with logs/photos).

## 2) Safe Changes (No Migration Needed)
- UI-only edits (`View` layout/text/colors).
- Service logic changes that do not alter model schema.
- Adding new non-persistent helper files/utilities.
- Adding tests.

## 3) Risky Changes (Require Migration Planning)
- Renaming model properties.
- Deleting model properties.
- Changing property types (for example `String -> Int`).
- Changing relationships.
- Moving/removing model classes from schema.

If any risky change is needed:
1. Add a new schema version in `MigrationPlan.swift` (append only).
2. Add migration stage(s) from previous schema to new schema.
3. Run migration test on existing sample data before release.

## 4) SwiftData Rules for This Project
- Keep old schema versions; do not remove prior versions.
- Prefer additive changes with defaults for new fields.
- Avoid breaking changes without explicit migration logic.

## 5) Launch Safety Checks
- Ensure app is **not** running in in-memory fallback mode in normal use.
- Confirm existing records appear after update.
- Confirm creating/editing/deleting still persists after app restart.

## 6) Pre-Release Smoke Test (On Existing Data)
- Open app and verify plant list count matches pre-update.
- Open several plant detail screens (including photos/log history).
- Log watering/fertilizing and restart app; verify persisted.
- Check environment/wishlist entries remain intact.
- Verify notifications still schedule as expected.

## 7) Recovery Plan
- Keep a dated export/backup strategy for real user data.
- If a migration issue is found, stop release and patch migration first.

---

Owner note: if you are making model/schema changes, treat this checklist as required, not optional.

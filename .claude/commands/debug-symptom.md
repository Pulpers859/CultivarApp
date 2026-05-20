---
description: Triage a bug by mapping it to the smallest likely risk surface and missing regression test
argument-hint: [symptom or failing behavior]
---

Debug this symptom: $ARGUMENTS

Start by mapping it to one of the known project risk surfaces in `@CLAUDE.md`.

Then:
1. Identify the smallest relevant file set.
2. Decide which project skill applies:
   - `@.claude/skills/swiftdata-schema-safety.md`
   - `@.claude/skills/backup-recovery.md`
   - `@.claude/skills/care-schedule-reminders.md`
   - `@.claude/skills/ai-integration-guardrails.md`
3. Explain the most likely root cause candidates.
4. Propose the smallest fix and the smallest useful regression test.

Do not drift into a full-app review.

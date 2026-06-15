This repo-specific handoff follows the workstation-wide standard in [AI_PROJECT_HANDOFF_TEMPLATE.md](C:/Dev/CultivarApp/AI_PROJECT_HANDOFF_TEMPLATE.md:1).

## Project Identity
- Project name: `CultivarApp`
- Project type: `iOS app`
- Source-of-truth repo path: `C:\Dev\CultivarApp`
- Stale/old copies to ignore if applicable: `C:\Users\Patrick's Computer\OneDrive - WV School of Osteopathic Medicine\Desktop\CultivarApp`
- Primary target for normal work if multiple surfaces exist: `Main app`
- GitHub intent/status: `remote attached`
- GitHub remote: `https://github.com/Pulpers859/CultivarApp.git`

## Repo State
- Stable branch: `main`
- Working branch: `main`
- Expected default branch for normal work: `main`
- Sync-first rule: `Before normal work, fetch from the remote first. If the working tree is clean and the active branch tracks the expected upstream, pull with --ff-only before editing. If local changes exist, fetch and reconcile instead of blindly pulling.`
- GitHub workflow rule: `Use only main. Commit directly to main and push directly to origin/main. Do not create side branches, revive dev, or use pull request workflows unless the user explicitly asks for an exception in that session.`
- External-agent reconciliation rule: `If outside agent work is mentioned, do not claim the repo is fully assessed or in sync until claimed changes have been compared against local files, local Git history, and the current main branch on GitHub.`
- If Git is not set up yet for this project, the agent should bootstrap it before doing major feature work.

## If No Git Exists Yet
If `git rev-parse --is-inside-work-tree` fails in the real project root, the agent should help set up the repo using this standard:
1. confirm the real project root
2. migrate the project to `C:\Dev\CultivarApp` if the current location is a weak source of truth
3. initialize local Git
4. create a focused `.gitignore`
5. create `.gitattributes` enforcing LF for code files
6. set repo-local config:
   - `core.autocrlf=false`
   - `core.eol=lf`
   - `pull.ff=only`
   - `fetch.prune=true`
7. add repo-local aliases:
   - `git st` -> `status -sb`
   - `git lg` -> `log --oneline --graph --decorate --all --date=short`
8. create the initial commit
9. run a secret scan and remove any live credentials from tracked files before connecting/pushing GitHub
10. connect the GitHub remote if I want one
11. push `main`
12. push `main`
13. add a local hook blocking direct commits to `main`
14. create a dedicated PowerShell shortcut for this project

If the GitHub remote is unknown, the agent should finish local bootstrap first and only ask for the remote when push/setup is actually needed.

## PowerShell / Terminal Standard
- Do not globally pin every PowerShell session to this project.
- A dedicated shortcut should exist:
  - `CultivarApp PowerShell`
- That shortcut should open directly in the source-of-truth repo path.
- Avoid fragile startup command strings if the path contains apostrophes or quoting hazards.

## How The Agent Should Operate
- Inspect before assuming.
- Work in the source-of-truth repo only.
- Sync from GitHub before normal work so the local repo is not stale.
- Fix root causes, not surface symptoms.
- Be honest and direct.
- Prefer architecture/data-flow fixes over hacks.
- Do not use brittle hardcoded special cases or band-aid fixes unless you explicitly explain why a deeper fix is not practical.
- Be proactive: inspect, diagnose, edit code directly, verify, and then audit nearby weaknesses.
- Do not stop at the first fix if adjacent code is obviously fragile.
- Tell me clearly what is evidence-backed, proven, inferred, or heuristic.
- If validation, linting, or review logic is too rigid and rejects good output, improve the rule when appropriate instead of dumbing down the product.
- Do not silently tolerate poor architecture if it is now a maintenance risk.
- Handle Git operations when appropriate.
- Keep normal work on `main`.
- Do not create or use side branches or PRs unless the user explicitly asks for that exception.
- If prior work by another agent, machine, terminal, or conversation is part of the context, perform an external-agent reconciliation pass before new edits, rebases, resets, merges, or sync claims.
- Before editing on an existing repo, run a fetch and check ahead/behind state; if clean, pull the tracked branch with `--ff-only`.
- Audit adjacent risks after making fixes.
- Run the checks that are realistically available in the current environment.
- Clearly distinguish evidence-backed logic from heuristics.
- Treat secrets as local-only by default: use tracked example files and ignored real config files whenever possible.

## Communication Style
- Warm, collaborative, calm, disciplined
- High-effort and thoughtful
- Short progress updates while working
- Clear reasoning, no fluff, no fake certainty
- If the agent misses something, it should own it directly

## Post-Fix Audit Standard
After making changes, the agent should do another harsh pass focused on:
- root-cause completeness
- adjacent fragility
- architecture quality
- validation or rule correctness
- progression / flow coherence where relevant
- silent failure risk
- wasted retries / wasted cost / wasted work
- maintainability

## What The User Wants By Default
- The user describes the problem in chat.
- The agent syncs from the tracked remote branch first so local files are current before investigation or edits.
- The agent investigates directly.
- The agent makes code changes directly.
- The agent audits adjacent risks.
- The agent runs local checks where possible.
- The agent handles Git steps when appropriate.
- The agent commits and pushes on `main` directly rather than using a side branch or PR flow.
- The user should not need to babysit PowerShell, Git, or GitHub for normal work.

## Before Starting Any New Task
The agent should confirm:
1. current repo path
2. current branch
3. repo status cleanliness
4. remote configuration
5. whether the local branch is behind the remote and needs fetch/pull
6. whether stale copies exist elsewhere
7. whether the active folder is truly the source of truth
8. whether outside-agent work has been mentioned and requires reconciliation before sync or edit decisions

## Architecture / Product Notes
- Main product purpose: `A SwiftUI + SwiftData plant care app for tracking plant profiles, care schedules, growth, environments, wishlist items, AI diagnosis, backups, and reminders.`
- Key modules or directories: `Cultivar/`, `Cultivar.xcodeproj/`, `CultivarAppTests/`, `.claude/`, `Cultivar/Plant.swift`, `Cultivar/SupportingModels.swift`, `Cultivar/MigrationPlan.swift`, `Cultivar/PlantBackupService.swift`, `Cultivar/PlantCareService.swift`, `Cultivar/NotificationService.swift`, `Cultivar/ClaudeService.swift`, `Cultivar/SettingsView.swift`
- Known fragile areas: `SwiftData schema evolution and migration`, `backup/import/recovery flows`, `watering date math and reminder scheduling`, `destructive delete/cascade behavior`, `AI key/config/request handling`, `filesystem/Xcode project path drift between Cultivar.xcodeproj and the Cultivar/ folder`
- Important evidence/product constraints: `This repo now includes Cultivar.xcodeproj and a filesystem-synchronized Cultivar/ app folder. Do not claim Apple build/test verification unless a real Xcode environment was used. iOS 17 is required for the current SwiftData and SwiftUI usage. Data safety matters more than UI polish.`
- Runtime environments that matter: `iOS simulator`, `physical iPhone/iPad`, `Apple build environment with Xcode`, `local Windows repo maintenance for source control only`

## Git / Release Notes
- Preferred everyday flow:
  - `git st`
  - `git diff`
  - `git add .`
  - `git commit -m "..."`
  - `git push`

## Project-Specific Instructions For The Next Agent
```text
Project: CultivarApp
Active repo path: C:\Dev\CultivarApp
GitHub remote: https://github.com/Pulpers859/CultivarApp.git
Stable branch: main
Working branch: main

Important:
- Treat C:\Dev\CultivarApp as the source of truth.
- Do not work in stale copies unless explicitly asked.
- Ignore C:\Users\Patrick's Computer\OneDrive - WV School of Osteopathic Medicine\Desktop\CultivarApp for normal work.
- If Git is not already set up, bootstrap it using the repo standard in this file before major feature work.
- Use the standard workflow: investigate directly, fix root causes, audit adjacent risks, run checks, and handle Git when appropriate.
- Before starting normal work, fetch from origin and sync the active branch first when the working tree is clean. If the repo is dirty, fetch and reconcile instead of pulling blindly.
- Use only `main`. Commit directly to `main` and push directly to `origin/main`. Do not create side branches, revive `dev`, or use PR workflow unless the user explicitly asks for it.
- If prior work by another AI agent, machine, terminal, or conversation is mentioned, reconcile those claims against local files, local Git history, and the current `main` branch on GitHub before making sync claims or deciding on pulls, rebases, merges, resets, or patches.
- The main product risk areas are SwiftData migration safety, backup/recovery, reminder date logic, and destructive data flows.
- If multiple surfaces exist, prioritize the main iOS app before exploring side surfaces.
- If the GitHub remote is unknown, finish local repo setup first and ask for the remote only when needed for push/setup.
- Do not pretend Apple builds/tests ran from Windows without a real Xcode project and Apple toolchain.
```

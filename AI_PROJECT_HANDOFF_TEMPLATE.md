# AI Project Handoff Template

Use this document as the standard handoff and repo/workstation workflow for local app projects on this Windows machine.

## Purpose
This template standardizes:
- local repo setup
- Git and GitHub workflow
- branch discipline
- PowerShell shortcuts
- project-folder placement
- AI-agent expectations
- migration away from OneDrive/Desktop when needed

The goal is to reduce setup friction, avoid path mistakes, and let the AI agent handle most code/Git work directly from chat.

---

## Standard Repo Rules

### 1. Source Of Truth
- The active coding repo should live outside OneDrive.
- Preferred location:
  - `C:\Dev\<ProjectName>`
- Do not treat a Desktop or OneDrive project copy as the long-term source of truth unless explicitly intended.
- If a stale copy exists in OneDrive/Desktop, it should be treated as archival or transitional only.

### 2. Git Setup
Each project should have:
- a local Git repo initialized in the real project folder
- a focused `.gitignore`
- a `.gitattributes` file enforcing `LF` for code files
- repo-local Git config:
  - `core.autocrlf=false`
  - `core.eol=lf`
  - `pull.ff=only`
  - `fetch.prune=true`
- repo-local aliases:
  - `git st` -> `status -sb`
  - `git lg` -> `log --oneline --graph --decorate --all --date=short`

### 3. GitHub Setup
- Attach the real local repo to a GitHub remote.
- Push the real local project history to GitHub.
- Do not allow accidental nested repos to become the remote source of truth.
- If a placeholder GitHub repo exists, replace it carefully with the real project history.
- If the GitHub remote is unknown, finish local bootstrap first and ask for the remote only when push/setup is actually needed.
- Before the first push, run a secret scan and move any live keys/tokens out of tracked files into ignored local config files.
- Before normal work on an existing repo, fetch first so the local repo is not stale. If the working tree is clean, pull the tracked branch with `--ff-only`; if it is dirty, fetch and reconcile before editing.

### 4. Branching Standard
- `main` = stable and default working branch
- normal day-to-day work happens on `main`
- do not use feature branches, side branches, or pull requests unless the user explicitly asks for them
- direct commits to `main` should be blocked locally with a pre-commit hook
- if server-side protection is added later, protect `main` on GitHub too

### 4.5 Secret Handling Standard
- Do not commit live API keys, tokens, private keys, or provider credentials into tracked source files.
- Prefer tracked example files such as `.env.example` or `firebase-config.example.js`.
- Prefer ignored real local files such as `.env.local`, `*.local.*`, `Secrets.xcconfig`, or provider-specific local config files.
- Add a local secret-scan hook before first push so accidental credential commits are blocked early.

### 5. PowerShell / Terminal Standard
- Do not globally force every PowerShell session into one repo using the profile.
- Instead, create a dedicated shortcut per project:
  - `<ProjectName> PowerShell`
- The shortcut should:
  - target `powershell.exe`
  - use the project repo as the working directory
  - avoid fragile startup command strings when the path contains apostrophes or quoting hazards

### 6. Migration Standard
If a project currently lives in OneDrive/Desktop:
- migrate the whole repo to `C:\Dev\<ProjectName>`
- preferred process:
  1. confirm repo status is clean enough to migrate
  2. create target root if needed
  3. move the full repo if unlocked
  4. if locked, copy the full repo to the new location and verify it
  5. update project shortcuts to the new location
  6. verify branch, remote, hooks, and repo-local config in the new location
  7. retire the old copy only after the new one is confirmed good
- do not force-delete a locked old copy while a process still has it open

---

## Default AI Agent Workflow

The AI agent should operate like this by default:
- the user describes the issue in chat
- the agent fetches from the tracked remote branch first so the local repo is current before investigation or edits
- the agent investigates the code directly
- the agent makes root-cause fixes, not surface patches
- the agent audits adjacent risks after the fix
- the agent runs checks it can run locally
- the agent handles Git steps when appropriate
- the user should not need to babysit PowerShell or Git for normal fix cycles

### Agent Standards
- be honest and direct, not agreeable for the sake of pleasing the user
- prefer architecture/data-flow fixes over hacks
- avoid brittle hardcoded prompt tricks unless explicitly justified
- treat evidence-backed training logic differently from heuristics
- protect API credits by reducing wasteful retries/fallbacks
- preserve product quality over merely satisfying rigid validation
- do not silently accept poor architecture if it is now causing risk
- do not assume the repo path or branch without checking
- if prior work by another agent, machine, terminal, or conversation is mentioned, do not assume the current diff or latest visible commit tells the full story

### Before Doing Work
The agent should first confirm:
1. active repo path
2. current branch
3. repo cleanliness/status
4. GitHub remote
5. whether the local branch is behind the remote and needs fetch/pull
6. whether a stale OneDrive/Desktop copy exists
7. whether the active repo is the true source of truth
8. whether outside-agent work has been mentioned and requires reconciliation before sync or edit decisions

### External-Agent Reconciliation
When the user mentions prior work by another AI agent, another machine, another terminal, or another conversation:
- inspect any outside artifact the user provides, such as a transcript, chat export, screenshot, commit list, or claimed fix summary
- compare what that outside agent claimed to change against the current local files, the local Git history, and the current `main` branch on GitHub
- tell the user plainly whether each claimed change is present, missing, partially landed, or overwritten
- only after that comparison decide whether to pull, rebase, merge, patch missing work, or leave newer work intact
- do not say the repo is fully assessed or in sync until this reconciliation step is complete

---

## Standard Commands Reference

### Everyday Work
```powershell
git fetch --prune
git pull --ff-only
git st
git diff
git add .
git commit -m "Describe the change"
git push
```

### Check Current Branch
```powershell
git branch --show-current
```

### Review History
```powershell
git lg
```

## Reusable Handoff Prompt Template

Copy and fill this for a future AI agent:

```text
You are helping with a local app project on my Windows machine.

Project name: <ProjectName>
Active repo path: C:\Dev\<ProjectName>
Primary target this session: <Main app / subproject / surface / both / unknown>
GitHub intent: <none / remote already exists / create a new remote with me>
GitHub remote: <RemoteURLOrUnknown>
Stable branch: main
Working branch: main

Important:
- Treat the active repo path above as the source of truth.
- Do not assume a Desktop or OneDrive copy is the real working repo.
- Inspect the current repo state before making assumptions.
- Fetch first and sync the tracked branch before normal work when the repo is clean.
- Use direct code edits and root-cause fixes.
- Handle Git operations for me when appropriate.
- Keep normal work on `main`.
- Commit and push on `main` directly unless I explicitly ask for a branch or PR.
- Preserve repo-local Git config, line-ending rules, hooks, and shortcuts.
- If duplicate or nested repos exist, resolve that carefully before continuing.
- Prefer dedicated PowerShell shortcuts per project instead of globally pinning PowerShell to one repo.
- If the GitHub remote is unknown, finish local repo setup first and ask for the remote only when needed for push/setup.

Default behavior:
- I describe the issue in chat
- you sync first, then investigate, fix it at the root, audit adjacent risks, run checks you can run, and handle Git when appropriate
- do not make me manually manage PowerShell/Git unless there is a real reason
```

---

## Transform Example

Use this as the filled reference example for the `Transform` app.

### Transform Current State
- Project: `Transform`
- Active repo path:
  - `C:\Dev\Transform`
- GitHub remote:
  - `https://github.com/Pulpers859/Transform.git`
- Stable branch:
  - `main`
- Working branch:
  - `main`
- Dedicated shortcut:
  - `Transform PowerShell`
- Shortcut should open in:
  - `C:\Dev\Transform`
- PowerShell profile:
  - should remain normal, not globally pinned to the project
- Repo-local protections already expected:
  - LF line-ending normalization
  - repo-local aliases
  - repo-local pull/fetch defaults
  - local pre-commit hook blocking direct commits to `main`

### Transform-Specific Handoff Prompt
```text
Project: Transform
Active repo path: C:\Dev\Transform
GitHub remote: https://github.com/Pulpers859/Transform.git
Stable branch: main
Working branch: main

Important:
- `C:\Dev\Transform` is the source of truth.
- Do not use `C:\Users\Patrick's Computer\OneDrive - WV School of Osteopathic Medicine\Desktop\Transform` as the active repo unless explicitly asked to inspect the stale copy.
- A dedicated shortcut named `Transform PowerShell` should open the repo at `C:\Dev\Transform`.
- The PowerShell profile should stay normal; do not globally pin every shell to this project again.
- Repo-local Git setup should remain in place:
  - line ending normalization
  - repo-local aliases
  - repo-local pull/fetch defaults
  - any optional protections must still preserve a `main`-only workflow unless the user explicitly asks for a branch or PR

Default behavior:
- Sync from the tracked remote branch first when the repo is clean
- Investigate issues from chat
- Fix them directly in the codebase
- Audit adjacent risks
- Run local checks where possible
- Handle Git operations when appropriate
- Keep work on `main` by default
```

---

## Notes For Future Standardization Across Apps
When onboarding a new app, follow this sequence:
1. identify the real project folder
2. move it to `C:\Dev\<ProjectName>` if needed
3. initialize/verify Git locally
4. connect GitHub remote
5. run a secret scan and remove any live credentials from tracked files before the first push
6. add main-blocking local hook
7. create dedicated PowerShell shortcut
8. confirm the active working branch is `main`
9. document the app-specific handoff state

This should be the default pattern for all future local app projects unless there is a strong reason to deviate.

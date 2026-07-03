# Cultivar Agent Rules

## Git Policy
- Use `main` as the only working branch for this repository.
- Commit directly to `main` and push directly to `origin/main`.
- Do not create, use, revive, recommend, or depend on side branches, feature branches, `dev`, draft branches, or pull request workflows.
- Do not open or prepare pull requests.
- Do not merge through a PR flow.
- Treat any branch-based workflow as disallowed by default.
- Only use another branch or a PR if the user explicitly asks for it in that session.
- For risky, creative, or parallel agent work, use a detached sandbox worktree via `tools/New-AgentSandbox.ps1`; do not create side branches or commit/push from the sandbox.

## Repo Reality
- Source-of-truth repo path: `C:\Dev\CultivarApp`
- App code: `Cultivar/`
- Xcode project: `Cultivar.xcodeproj/`
- Tests: `CultivarAppTests/`
- Support docs: `docs/`

## Safety
- Do not pretend Apple builds/tests ran unless a real Xcode environment was used.
- Product risk is data loss, reminder drift, and backup/recovery breakage, not cosmetic polish.
- If behavior, workflow rules, or known risks change, update `HANDOFF.md`.
- Repo support docs should live under `docs/` rather than accumulating in the repo root.
- Sandbox workflow docs live at `docs/agent-sandbox-workflow.md`.

## External-Agent Reconciliation
- If the user mentions prior work by another AI agent, another machine, another terminal, or another conversation, do not assume the current diff or latest visible commit tells the full story.
- Before making new edits, rebases, resets, merges, or sync claims, perform an external-agent reconciliation pass.
- Inspect any outside artifact the user provides, such as a transcript, chat export, screenshot, commit list, or claimed fix summary.
- Compare what that outside agent claimed to change against the current local files, the local Git history, and the current `main` branch on GitHub.
- Tell the user plainly whether each claimed change is present, missing, partially landed, or overwritten.
- Only after that comparison should you decide whether to pull, rebase, merge, patch missing work, or leave newer work intact.
- Do not tell the user the repo is fully assessed or in sync until this reconciliation step is complete whenever outside agent work is part of the context.

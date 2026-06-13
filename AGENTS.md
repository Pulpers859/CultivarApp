# Cultivar Agent Rules

## Git Policy
- Use `main` as the only working branch for this repository.
- Commit directly to `main` and push directly to `origin/main`.
- Do not create, use, revive, recommend, or depend on side branches, feature branches, `dev`, draft branches, or pull request workflows.
- Do not open or prepare pull requests.
- Do not merge through a PR flow.
- Treat any branch-based workflow as disallowed by default.
- Only use another branch or a PR if the user explicitly asks for it in that session.

## Repo Reality
- Source-of-truth repo path: `C:\Dev\CultivarApp`
- App code: `Cultivar/`
- Xcode project: `Cultivar.xcodeproj/`
- Tests: `CultivarAppTests/`

## Safety
- Do not pretend Apple builds/tests ran unless a real Xcode environment was used.
- Product risk is data loss, reminder drift, and backup/recovery breakage, not cosmetic polish.
- If behavior, workflow rules, or known risks change, update `HANDOFF.md`.

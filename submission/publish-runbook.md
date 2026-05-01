# Publish Runbook

This project is ready for a public repository push, but the current machine is not authenticated with GitHub CLI.

## Current Git State

```bash
git status --short
git log --oneline --decorate -3
```

Expected:

- Clean working tree.
- Commits:
  - `d038d7c feat: add Kan hackathon prototype`
  - `26026fb` or later docs/update commit, depending on final local edits.

## Secret Audit

```bash
git status --ignored --short | rg "\\.env|submission/dist|submission/live-demo/kan-debug|unsloth/.venv"
git diff --cached --name-only | rg "\\.env$|submission/dist|submission/live-demo/kan-debug|unsloth/.venv|build/"
```

Expected:

- `.env`, APKs, ZIPs, build outputs, and `.venv` are ignored.
- No real `.env` or APK binary is staged.

## Create Public GitHub Repo

After logging in:

```bash
gh auth login
./scripts/publish_submission.sh --check
./scripts/publish_submission.sh
```

Alternative manual push:

```bash
git remote add origin git@github.com:<user>/kan-gemma4-good.git
git push -u origin main
```

## Demo ZIP Upload

Upload the latest local package:

```text
submission/dist/kan-demo-package-20260501T172959Z.zip
```

Use a no-login public location. Kaggle writeup can link to either:

- GitHub Release asset.
- Kaggle Dataset.
- Public Google Drive file with direct no-login access.

Do not upload `.env`.

## Video Upload

Upload the rendered video:

```text
submission/kan-final-demo-video.mp4
```

It is under 3 minutes and uses the narration in `submission/final-video-narration.txt`.

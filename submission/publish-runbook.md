# Publish Runbook

This project has been pushed to a public GitHub repository and published as a GitHub Release. Keep this runbook for repeatable verification or re-uploading changed assets.

Public repository:

```text
https://github.com/Anarpego/zpk-digital-id-gemma4
```

Public release:

```text
https://github.com/Anarpego/zpk-digital-id-gemma4/releases/tag/v2026.05.07-kaggle
```

## Current Git State

```bash
git status --short
git log --oneline --decorate -3
```

Expected:

- Clean working tree.
- Latest commit is tagged `v2026.05.07-kaggle`.
- Latest commits include the submission verifier, upload copy, final audit, and guarded publish helper.

## Secret Audit

```bash
git status --ignored --short | rg "\\.env|submission/dist|submission/live-demo/zpk-local-release|unsloth/.venv"
git diff --cached --name-only | rg "\\.env$|submission/dist|submission/live-demo/zpk-local-release|unsloth/.venv|build/"
```

Expected:

- `.env`, APKs, ZIPs, build outputs, and `.venv` are ignored.
- No real `.env` or APK binary is staged.

## Create Or Refresh Public GitHub Release

After logging in:

```bash
gh auth login
./scripts/publish_submission.sh --check
./scripts/publish_submission.sh
```

Alternative manual push if the remote is missing:

```bash
git remote add origin git@github.com:<user>/zpk-digital-id-gemma4.git
git push -u origin main
git push origin v2026.05.07-kaggle
```

## Demo ZIP Upload

Upload the latest local package:

```text
submission/dist/kan-demo-package-final.zip
submission/dist/kan-demo-package-final.zip.sha256
submission/live-demo/zpk-citizen-gemma4-release.apk
submission/live-demo/zpk-citizen-gemma4-release.apk.sha256
```

Use a no-login public location. Kaggle writeup can link to either:

- GitHub Release asset.
- Kaggle Dataset.
- Public Google Drive file with direct no-login access.

Do not upload `.env`.

## Kaggle Dataset Upload Option

Prepare a dataset upload folder without publishing:

```bash
KAGGLE_USERNAME=<your-kaggle-username> ./scripts/prepare_kaggle_dataset.sh
```

After configuring Kaggle API credentials, run the Kaggle CLI through `uvx`:

```bash
uvx kaggle datasets create -p submission/kaggle-dataset-upload --dir-mode zip
```

## Video Upload

Upload the rendered video:

```text
submission/kan-final-demo-video.mp4
```

It is under 3 minutes and uses the narration in `submission/final-video-narration.txt`.

## Media Gallery Cover

Upload the rendered cover image to Kaggle media gallery:

```text
submission/media-gallery-cover.png
```

It is a 1600x900 PNG rendered from `submission/media-gallery-cover.svg`.

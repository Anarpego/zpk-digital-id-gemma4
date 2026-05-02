#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/kan-app"
LIVE="$ROOT/submission/live-demo"
DIST="$ROOT/submission/dist"
ZIP="$DIST/kan-demo-package-final.zip"
ZIP_SHA="$ZIP.sha256"

mkdir -p "$LIVE" "$DIST"

cd "$APP"
flutter build apk --debug

cp "$APP/build/app/outputs/flutter-apk/app-debug.apk" "$LIVE/kan-debug.apk"

for file in \
  "$APP/kan-embedded-catalog-trace.png" \
  "$APP/kan-gemma-hosted-trace.png" \
  "$APP/kan-cactus-270m-notools-trace.png"; do
  if [[ -f "$file" ]]; then
    cp "$file" "$LIVE/$(basename "$file")"
  fi
done

cd "$ROOT"
shasum -a 256 "$LIVE/kan-debug.apk" > "$LIVE/kan-debug.apk.sha256"
rm -f "$ZIP" "$ZIP_SHA"

zip -r "$ZIP" \
  README.md \
  LICENSE \
  .env.example \
  AGENTS.md \
  SUBMISSION_CHECKLIST.md \
  SUBMIT_NOW.md \
  scripts/package_demo.sh \
  scripts/prepare_kaggle_dataset.sh \
  scripts/publish_submission.sh \
  scripts/verify_release_build.sh \
  scripts/verify_submission.sh \
  docs \
  submission/live-demo \
  submission/demo-runbook.md \
  submission/ARTIFACT_MANIFEST.md \
  submission/KAGGLE_FORM.md \
  submission/YOUTUBE_DESCRIPTION.md \
  submission/GITHUB_RELEASE_NOTES.md \
  submission/KAGGLE_DATASET_README.md \
  submission/final-kaggle-writeup.md \
  submission/kaggle-dataset-metadata.template.json \
  submission/media-gallery-cover.svg \
  submission/media-gallery-cover.png \
  submission/prize-claims.md \
  submission/publish-runbook.md \
  submission/final-video-captions.srt \
  submission/final-video-narration.txt \
  submission/final-video-script.md \
  submission/kan-final-demo-video.mp4 \
  submission/video-raw \
  unsloth \
  -x '*.DS_Store' '*.uiautomator.xml' 'unsloth/.venv/*' '*/__pycache__/*' '*.pyc'

shasum -a 256 "$ZIP" > "$ZIP_SHA"

echo "$ZIP"

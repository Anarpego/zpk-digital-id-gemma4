#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/kan-app"
LIVE="$ROOT/submission/live-demo"
DIST="$ROOT/submission/dist"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ZIP="$DIST/kan-demo-package-$STAMP.zip"

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

zip -r "$ZIP" \
  README.md \
  LICENSE \
  .env.example \
  AGENTS.md \
  SUBMISSION_CHECKLIST.md \
  docs \
  submission/live-demo \
  submission/demo-runbook.md \
  submission/ARTIFACT_MANIFEST.md \
  submission/KAGGLE_FORM.md \
  submission/YOUTUBE_DESCRIPTION.md \
  submission/final-kaggle-writeup.md \
  submission/kaggle-writeup-draft.md \
  submission/media-gallery-cover.svg \
  submission/prize-claims.md \
  submission/publish-runbook.md \
  submission/final-video-captions.srt \
  submission/final-video-narration.txt \
  submission/final-video-script.md \
  submission/kan-final-demo-video.mp4 \
  submission/video-raw \
  submission/video-script-draft.md \
  unsloth \
  -x '*.DS_Store' 'unsloth/.venv/*' '*/__pycache__/*' '*.pyc'

echo "$ZIP"

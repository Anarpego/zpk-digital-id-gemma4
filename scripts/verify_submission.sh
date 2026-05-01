#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP="$ROOT/submission/dist/kan-demo-package-final.zip"
ZIP_SHA="$ZIP.sha256"
APK="$ROOT/submission/live-demo/kan-debug.apk"
VIDEO="$ROOT/submission/kan-final-demo-video.mp4"
COVER="$ROOT/submission/media-gallery-cover.png"
WRITEUP="$ROOT/submission/final-kaggle-writeup.md"
DATASET_TEMPLATE="$ROOT/submission/kaggle-dataset-metadata.template.json"
DATASET_UPLOAD="$ROOT/submission/kaggle-dataset-upload"

EXPECTED_APK_SHA="e65033655d713cd53f3612565a62efd3b5f5d1af170323a6db0bf634609f97b2"
EXPECTED_VIDEO_SHA="a01f26b7c8ef747415d7bb51280d1fabc82f0f27a6c7749b01494674ded6c5e1"
EXPECTED_COVER_SHA="882f32b3e35b8b73fcf7b32dda46f021fe82bfdcad33b44a5a707aa7de265875"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

need_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

sha_only() {
  shasum -a 256 "$1" | awk '{print $1}'
}

video_duration_seconds() {
  afinfo "$1" | awk '/estimated duration:/ {print int($3 + 0)}'
}

image_dimension() {
  sips -g "$2" "$1" 2>/dev/null | awk -v key="$2" '$1 == key ":" {print $2}'
}

need_file "$ZIP"
need_file "$ZIP_SHA"
need_file "$APK"
need_file "$VIDEO"
need_file "$COVER"
need_file "$WRITEUP"

shasum -a 256 -c "$ZIP_SHA" >/dev/null || fail "ZIP checksum mismatch"
[[ "$(sha_only "$APK")" == "$EXPECTED_APK_SHA" ]] || fail "APK checksum mismatch"
[[ "$(sha_only "$VIDEO")" == "$EXPECTED_VIDEO_SHA" ]] || fail "video checksum mismatch"
[[ "$(sha_only "$COVER")" == "$EXPECTED_COVER_SHA" ]] || fail "cover checksum mismatch"

writeup_words="$(wc -w < "$WRITEUP" | tr -d ' ')"
[[ "$writeup_words" -le 1500 ]] || fail "writeup is over 1500 words: $writeup_words"

video_seconds="$(video_duration_seconds "$VIDEO")"
[[ -n "$video_seconds" ]] || fail "could not read video duration"
[[ "$video_seconds" -lt 180 ]] || fail "video is 180 seconds or longer: ${video_seconds}s"

cover_width="$(image_dimension "$COVER" pixelWidth)"
cover_height="$(image_dimension "$COVER" pixelHeight)"
[[ "$cover_width" == "1600" && "$cover_height" == "900" ]] || fail "cover dimensions must be 1600x900, got ${cover_width:-?}x${cover_height:-?}"

zip_listing="$(mktemp)"
trap 'rm -f "$zip_listing"' EXIT
unzip -l "$ZIP" > "$zip_listing"

grep -q ' \.env\.example$' "$zip_listing" || fail "ZIP missing .env.example"
if grep -q ' \.env$' "$zip_listing"; then
  fail "ZIP contains .env"
fi

for required in \
  'SUBMIT_NOW.md' \
  'scripts/prepare_kaggle_dataset.sh' \
  'scripts/publish_submission.sh' \
  'scripts/verify_submission.sh' \
  'submission/ARTIFACT_MANIFEST.md' \
  'submission/GITHUB_RELEASE_NOTES.md' \
  'submission/KAGGLE_DATASET_README.md' \
  'submission/KAGGLE_FORM.md' \
  'submission/YOUTUBE_DESCRIPTION.md' \
  'submission/kaggle-dataset-metadata.template.json' \
  'submission/kan-final-demo-video.mp4' \
  'submission/media-gallery-cover.png' \
  'submission/media-gallery-cover.svg' \
  'submission/live-demo/kan-debug.apk' \
  'submission/final-kaggle-writeup.md' \
  'unsloth/outputs/training_attempt_2026-05-01.md'; do
  grep -q " $required$" "$zip_listing" || fail "ZIP missing $required"
done

jq . "$DATASET_TEMPLATE" >/dev/null || fail "invalid Kaggle Dataset metadata template"

if [[ -d "$DATASET_UPLOAD" ]]; then
  while IFS= read -r resource_path; do
    [[ -f "$DATASET_UPLOAD/$resource_path" ]] || fail "Kaggle Dataset upload missing resource: $resource_path"
  done < <(jq -r '.resources[].path' "$DATASET_UPLOAD/dataset-metadata.json")
fi

echo "PASS: submission artifacts verified"
echo "ZIP: $ZIP"
echo "ZIP SHA-256: $(sha_only "$ZIP")"
echo "APK SHA-256: $EXPECTED_APK_SHA"
echo "Video SHA-256: $EXPECTED_VIDEO_SHA"
echo "Cover SHA-256: $EXPECTED_COVER_SHA"
echo "Video seconds: $video_seconds"
echo "Cover dimensions: ${cover_width}x${cover_height}"
echo "Writeup words: $writeup_words"

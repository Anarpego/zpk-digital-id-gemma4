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

EXPECTED_APK_SHA="97f46a47ac06bbdd232e70e98cec6a7d03b4093ca7a43e38ebb391f63ce97138"
EXPECTED_VIDEO_SHA="42774441b15dd69af421c2f76d6e59b71203b4c27effb810b0b011da040bce34"
EXPECTED_COVER_SHA="3c1039c1843ee8763439b1be6fb27151056770e33f4f0e7e7a5d04f9ada16db3"

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

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP="$ROOT/submission/dist/kan-demo-package-final.zip"
APK="$ROOT/submission/live-demo/kan-debug.apk"
VIDEO="$ROOT/submission/kan-final-demo-video.mp4"
WRITEUP="$ROOT/submission/final-kaggle-writeup.md"

EXPECTED_APK_SHA="97f46a47ac06bbdd232e70e98cec6a7d03b4093ca7a43e38ebb391f63ce97138"
EXPECTED_VIDEO_SHA="42774441b15dd69af421c2f76d6e59b71203b4c27effb810b0b011da040bce34"

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

need_file "$ZIP"
need_file "$APK"
need_file "$VIDEO"
need_file "$WRITEUP"

[[ "$(sha_only "$APK")" == "$EXPECTED_APK_SHA" ]] || fail "APK checksum mismatch"
[[ "$(sha_only "$VIDEO")" == "$EXPECTED_VIDEO_SHA" ]] || fail "video checksum mismatch"

writeup_words="$(wc -w < "$WRITEUP" | tr -d ' ')"
[[ "$writeup_words" -le 1500 ]] || fail "writeup is over 1500 words: $writeup_words"

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
  'submission/live-demo/kan-debug.apk' \
  'submission/final-kaggle-writeup.md' \
  'unsloth/outputs/training_attempt_2026-05-01.md'; do
  grep -q " $required$" "$zip_listing" || fail "ZIP missing $required"
done

jq . "$ROOT/submission/kaggle-dataset-metadata.template.json" >/dev/null || fail "invalid Kaggle Dataset metadata template"

echo "PASS: submission artifacts verified"
echo "ZIP: $ZIP"
echo "APK SHA-256: $EXPECTED_APK_SHA"
echo "Video SHA-256: $EXPECTED_VIDEO_SHA"
echo "Writeup words: $writeup_words"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP="$ROOT/submission/dist/kan-demo-package-final.zip"
ZIP_SHA="$ZIP.sha256"
APK="$ROOT/submission/live-demo/kan-debug.apk"
VIDEO="$ROOT/submission/kan-final-demo-video.mp4"
COVER="$ROOT/submission/media-gallery-cover.png"
WRITEUP="$ROOT/submission/final-kaggle-writeup.md"
KAGGLE_FORM="$ROOT/submission/KAGGLE_FORM.md"
PRIZE_CLAIMS="$ROOT/submission/prize-claims.md"
DATASET_TEMPLATE="$ROOT/submission/kaggle-dataset-metadata.template.json"
DATASET_UPLOAD="$ROOT/submission/kaggle-dataset-upload"

EXPECTED_VIDEO_SHA="e33a3a93d1d86da8a091a3435509e09f4ffd8d944a8ff811d49735ebd03fe3e6"
EXPECTED_COVER_SHA="15ba1a8f5037973ce6b0c76defdfd05bee438d2f8ddf15393cc75070e4a6f2b6"

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
need_file "$APK.sha256"
need_file "$VIDEO"
need_file "$COVER"
need_file "$WRITEUP"
need_file "$KAGGLE_FORM"
need_file "$PRIZE_CLAIMS"

shasum -a 256 -c "$ZIP_SHA" >/dev/null || fail "ZIP checksum mismatch"
shasum -a 256 -c "$APK.sha256" >/dev/null || fail "APK checksum mismatch"
[[ "$(sha_only "$VIDEO")" == "$EXPECTED_VIDEO_SHA" ]] || fail "video checksum mismatch"
[[ "$(sha_only "$COVER")" == "$EXPECTED_COVER_SHA" ]] || fail "cover checksum mismatch"

writeup_words="$(wc -w < "$WRITEUP" | tr -d ' ')"
[[ "$writeup_words" -le 1500 ]] || fail "writeup is over 1500 words: $writeup_words"

for public_copy in "$WRITEUP" "$KAGGLE_FORM" "$PRIZE_CLAIMS" "$ROOT/SUBMIT_NOW.md"; do
  if grep -Eiq 'TODO_PUBLIC|placeholder|working social-impact prototype' "$public_copy"; then
    fail "public copy contains stale placeholder/prototype claim: $public_copy"
  fi
done

for claim in \
  'allowlisted expiring signed local authentication proof' \
  'citizen-clearable app-internal audit archive sealed with AES-GCM and Android Keystore' \
  'hosted Gemma 4 mode verified with `gemma-4-31b-it`' \
  'fails closed on the Mac emulator'; do
  grep -Fq "$claim" "$KAGGLE_FORM" || fail "Kaggle form missing claim: $claim"
done

for trace in \
  'auth.verify(local) -> ok' \
  'auth.relying_party(local_allowlist) -> approved' \
  'auth.valid_until(local) ->' \
  'auth.blocked(revocation) -> credential_revoked' \
  'audit_archive.encrypt(AES-GCM-256, android-keystore) -> sealed' \
  'privacy_guard.raw_cui -> absent' \
  'reasoner_mode(mlkit-gemma:aicore) -> fallback'; do
  grep -Fq "$trace" "$WRITEUP" "$ROOT/docs/evidence"/*.md || fail "missing evidence trace: $trace"
done

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
  'docs/evidence/local-authentication-proof-2026-05-01.md' \
  'docs/evidence/local-audit-archive-sealed-runtime-2026-05-01.json' \
  'docs/evidence/mlkit-gemma-ondevice-2026-05-01.md' \
  'docs/evidence/gemma4-api-smoke-2026-05-01.md' \
  'docs/evidence/cactus-local-inference-2026-05-01.md' \
  'unsloth/outputs/training_attempt_2026-05-01.md'; do
  grep -q " $required$" "$zip_listing" || fail "ZIP missing $required"
done

unzip -p "$ZIP" docs/evidence/local-authentication-proof-2026-05-01.md \
  | grep -Fq 'auth.verify(local) -> ok' \
  || fail "ZIP local authentication evidence missing verification trace"
unzip -p "$ZIP" docs/evidence/local-authentication-proof-2026-05-01.md \
  | grep -Fq 'auth.relying_party(local_allowlist) -> approved' \
  || fail "ZIP local authentication evidence missing relying-party trace"
unzip -p "$ZIP" docs/evidence/local-authentication-proof-2026-05-01.md \
  | grep -Fq 'auth.valid_until(local) ->' \
  || fail "ZIP local authentication evidence missing expiry trace"
unzip -p "$ZIP" docs/evidence/local-authentication-proof-2026-05-01.md \
  | grep -Fq 'auth.blocked(revocation) -> credential_revoked' \
  || fail "ZIP local authentication evidence missing revocation block trace"
unzip -p "$ZIP" docs/evidence/local-audit-archive-sealed-runtime-2026-05-01.json \
  | grep -Fq '"cipherSuite":"AES-GCM-256"' \
  || fail "ZIP sealed audit evidence missing AES-GCM envelope"
if unzip -p "$ZIP" docs/evidence/local-audit-archive-sealed-runtime-2026-05-01.json \
  | grep -Eq 'citizenPseudonym|zpk-gt-|1234567890101|recoveryPacketSignature'; then
  fail "ZIP sealed audit evidence leaks readable identity fields"
fi

jq . "$DATASET_TEMPLATE" >/dev/null || fail "invalid Kaggle Dataset metadata template"

if [[ -d "$DATASET_UPLOAD" ]]; then
  need_file "$DATASET_UPLOAD/dataset-metadata.json"
  while IFS= read -r resource_path; do
    [[ -f "$DATASET_UPLOAD/$resource_path" ]] || fail "Kaggle Dataset upload missing resource: $resource_path"
  done < <(jq -r '.resources[].path' "$DATASET_UPLOAD/dataset-metadata.json")

  grep -Fq 'allowlisted expiring signed local authentication proof' "$DATASET_UPLOAD/KAGGLE_FORM.md" \
    || fail "Kaggle Dataset upload form missing authentication proof claim"
  grep -Fq 'auth.verify(local) -> ok' "$DATASET_UPLOAD/final-kaggle-writeup.md" \
    || fail "Kaggle Dataset upload writeup missing authentication trace"
  grep -Fq 'auth.blocked(revocation) -> credential_revoked' "$DATASET_UPLOAD/final-kaggle-writeup.md" \
    || fail "Kaggle Dataset upload writeup missing revocation block trace"
fi

echo "PASS: submission artifacts verified"
echo "ZIP: $ZIP"
echo "ZIP SHA-256: $(sha_only "$ZIP")"
echo "APK SHA-256: $(sha_only "$APK")"
echo "Video SHA-256: $EXPECTED_VIDEO_SHA"
echo "Cover SHA-256: $EXPECTED_COVER_SHA"
echo "Video seconds: $video_seconds"
echo "Cover dimensions: ${cover_width}x${cover_height}"
echo "Writeup words: $writeup_words"

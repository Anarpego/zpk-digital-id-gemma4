#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/submission/kaggle-dataset-upload"
ZIP="$ROOT/submission/dist/kan-demo-package-final.zip"
ZIP_SHA="$ZIP.sha256"
VIDEO="$ROOT/submission/kan-final-demo-video.mp4"
USERNAME="${KAGGLE_USERNAME:-}"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[[ -n "$USERNAME" ]] || fail "set KAGGLE_USERNAME before preparing dataset metadata"

cd "$ROOT"
rm -rf "$OUT"
./scripts/verify_submission.sh

mkdir -p "$OUT"

cp "$ZIP" "$OUT/$(basename "$ZIP")"
zip_hash="$(shasum -a 256 "$ZIP" | awk '{print $1}')"
printf '%s  %s\n' "$zip_hash" "$(basename "$ZIP")" > "$OUT/$(basename "$ZIP_SHA")"
cp "$VIDEO" "$OUT/kan-final-demo-video.mp4"
cp submission/media-gallery-cover.png "$OUT/media-gallery-cover.png"
cp submission/ARTIFACT_MANIFEST.md "$OUT/ARTIFACT_MANIFEST.md"
cp submission/final-kaggle-writeup.md "$OUT/final-kaggle-writeup.md"
cp submission/KAGGLE_FORM.md "$OUT/KAGGLE_FORM.md"
cp submission/KAGGLE_DATASET_README.md "$OUT/README.md"
sed "s/KAGGLE_USERNAME/$USERNAME/g" submission/kaggle-dataset-metadata.template.json > "$OUT/dataset-metadata.json"

./scripts/verify_submission.sh

echo "Prepared Kaggle Dataset upload folder:"
echo "$OUT"
echo ""
echo "After configuring Kaggle API credentials, create it with uvx:"
echo "  uvx kaggle datasets create -p $OUT --dir-mode zip"

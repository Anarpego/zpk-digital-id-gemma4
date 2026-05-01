#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_NAME="${REPO_NAME:-kan-gemma4-good}"
ZIP="$ROOT/submission/dist/kan-demo-package-final.zip"
VIDEO="$ROOT/submission/kan-final-demo-video.mp4"

cd "$ROOT"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

if [[ "${1:-}" == "--check" ]]; then
  ./scripts/verify_submission.sh
  [[ -z "$(git status --short)" ]] || fail "working tree is not clean"
  git status --ignored --short | rg "\\.env|submission/dist|submission/live-demo/kan-debug|unsloth/.venv" >/dev/null
  git diff --cached --name-only | rg "\\.env$|submission/dist|submission/live-demo/kan-debug|unsloth/.venv|build/" && fail "generated or secret file is staged"
  gh auth status
  echo "PASS: publish prerequisites checked"
  exit 0
fi

./scripts/verify_submission.sh

[[ -f "$ZIP" ]] || fail "missing ZIP: $ZIP"
[[ -f "$VIDEO" ]] || fail "missing video: $VIDEO"
[[ -z "$(git status --short)" ]] || fail "working tree is not clean"

gh auth status >/dev/null || fail "GitHub CLI is not authenticated. Run: gh auth login"

if ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create "$REPO_NAME" --public --source . --remote origin --push
else
  git push -u origin main
fi

tag="submission-2026-05-01"
if ! gh release view "$tag" >/dev/null 2>&1; then
  gh release create "$tag" \
    "$ZIP" \
    "$VIDEO" \
    --title "Kan Gemma 4 Good submission package" \
    --notes-file submission/GITHUB_RELEASE_NOTES.md
else
  gh release upload "$tag" "$ZIP" "$VIDEO" --clobber
fi

echo "Published repository and release assets."

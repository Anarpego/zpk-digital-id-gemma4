#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/kan-app"
APK="$APP/build/app/outputs/flutter-apk/app-release.apk"
APKSIGNER="${APKSIGNER:-$HOME/Library/Android/sdk/build-tools/36.1.0/apksigner}"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

need_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

cd "$APP"
flutter build apk --release

need_file "$APK"
need_file "$APKSIGNER"

signed_output="$("$APKSIGNER" verify --verbose --print-certs "$APK" 2>&1 || true)"
if [[ -n "${ZPK_RELEASE_KEYSTORE:-}" ]]; then
  grep -Fq 'Verified using v' <<<"$signed_output" \
    || fail "release signing variables were provided but APK did not verify as signed"
  if grep -Fq 'CN=Android Debug' <<<"$signed_output"; then
    fail "release APK is signed with Android debug certificate"
  fi
  echo "PASS: release APK is signed and not using Android debug certificate"
else
  if grep -Fq 'DOES NOT VERIFY' <<<"$signed_output"; then
    echo "PASS: release APK is intentionally unsigned without ZPK_RELEASE_* credentials"
  else
    fail "release APK unexpectedly verifies without ZPK_RELEASE_* credentials"
  fi
fi

echo "APK: $APK"
shasum -a 256 "$APK"

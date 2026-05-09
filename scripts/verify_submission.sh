#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP="$ROOT/submission/dist/kan-demo-package-final.zip"
ZIP_SHA="$ZIP.sha256"
APK="$ROOT/submission/live-demo/zpk-local-release.apk"
LITERT_APK="$ROOT/submission/live-demo/zpk-litert-release.apk"
CITIZEN_APK="$ROOT/submission/live-demo/zpk-citizen-gemma4-release.apk"
MOTOROLA_APK="$ROOT/motorola/zpk-litert-persona-institucion-release.apk"
MOTOROLA_APK_SHA="$MOTOROLA_APK.sha256"
VIDEO="$ROOT/submission/kan-final-demo-video.mp4"
COVER="$ROOT/submission/media-gallery-cover.png"
WRITEUP="$ROOT/submission/final-kaggle-writeup.md"
KAGGLE_FORM="$ROOT/submission/KAGGLE_FORM.md"
PRIZE_CLAIMS="$ROOT/submission/prize-claims.md"
DATASET_TEMPLATE="$ROOT/submission/kaggle-dataset-metadata.template.json"
DATASET_UPLOAD="$ROOT/submission/kaggle-dataset-upload"
APKSIGNER="${APKSIGNER:-$HOME/Library/Android/sdk/build-tools/36.1.0/apksigner}"
AAPT2="${AAPT2:-$HOME/Library/Android/sdk/build-tools/36.1.0/aapt2}"

EXPECTED_VIDEO_SHA="e06f903f2bafdd50ed635ef280d8b6923dd4841157087189c7d8e72ebfa662cf"
EXPECTED_COVER_SHA="bf8cefade54d486c626b9b4b5b95cffff9e6e589870f09735a0f5ff38569d947"

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

verify_apk_manifest() {
  local apk="$1"
  local label="$2"
  local badging
  local manifest

  badging="$("$AAPT2" dump badging "$apk")"
  grep -Fq "package: name='gt.kan.kan_app'" <<<"$badging" \
    || fail "$label APK package name changed"
  grep -Fq "application-label:'ZPK Digital ID'" <<<"$badging" \
    || fail "$label APK application label changed"

  manifest="$("$AAPT2" dump xmltree --file AndroidManifest.xml "$apk")"
  grep -Eq 'allowBackup.*=false' <<<"$manifest" \
    || fail "$label APK allowBackup is not false"
  grep -Eq 'usesCleartextTraffic.*=false' <<<"$manifest" \
    || fail "$label APK usesCleartextTraffic is not false"
  grep -Fq ':fullBackupContent' <<<"$manifest" \
    || fail "$label APK missing fullBackupContent policy"
  grep -Fq ':dataExtractionRules' <<<"$manifest" \
    || fail "$label APK missing dataExtractionRules policy"
}

need_file "$ZIP"
need_file "$ZIP_SHA"
need_file "$APK"
need_file "$APK.sha256"
need_file "$LITERT_APK"
need_file "$LITERT_APK.sha256"
need_file "$CITIZEN_APK"
need_file "$CITIZEN_APK.sha256"
need_file "$MOTOROLA_APK"
need_file "$MOTOROLA_APK_SHA"
need_file "$VIDEO"
need_file "$COVER"
need_file "$WRITEUP"
need_file "$KAGGLE_FORM"
need_file "$PRIZE_CLAIMS"
need_file "$APKSIGNER"
need_file "$AAPT2"

(
  cd "$(dirname "$ZIP")"
  shasum -a 256 -c "$(basename "$ZIP_SHA")" >/dev/null
) || fail "ZIP checksum mismatch"
(
  cd "$(dirname "$APK")"
  shasum -a 256 -c "$(basename "$APK").sha256" >/dev/null
) || fail "APK checksum mismatch"
(
  cd "$(dirname "$LITERT_APK")"
  shasum -a 256 -c "$(basename "$LITERT_APK").sha256" >/dev/null
) || fail "LiteRT APK checksum mismatch"
(
  cd "$(dirname "$CITIZEN_APK")"
  shasum -a 256 -c "$(basename "$CITIZEN_APK").sha256" >/dev/null
) || fail "Citizen Gemma APK checksum mismatch"
(
  cd "$ROOT/motorola"
  shasum -a 256 -c "$(basename "$MOTOROLA_APK_SHA")" >/dev/null
) || fail "Motorola APK checksum mismatch"
[[ "$(sha_only "$MOTOROLA_APK")" == "$(sha_only "$LITERT_APK")" ]] \
  || fail "Motorola APK and packaged LiteRT APK differ"
[[ "$(sha_only "$VIDEO")" == "$EXPECTED_VIDEO_SHA" ]] || fail "video checksum mismatch"
[[ "$(sha_only "$COVER")" == "$EXPECTED_COVER_SHA" ]] || fail "cover checksum mismatch"
grep -Fq "$EXPECTED_COVER_SHA" "$ROOT/submission/ARTIFACT_MANIFEST.md" \
  || fail "artifact manifest has stale media cover checksum"
grep -Fq "$EXPECTED_COVER_SHA" "$ROOT/submission/GITHUB_RELEASE_NOTES.md" \
  || fail "release notes have stale media cover checksum"

local_signed_output="$("$APKSIGNER" verify --verbose --print-certs "$APK" 2>&1 || true)"
grep -Fq 'Verifies' <<<"$local_signed_output" \
  || fail "Local APK does not verify as signed"
if grep -Fq 'CN=Android Debug' <<<"$local_signed_output"; then
  fail "Local APK is signed with Android debug certificate"
fi

litert_signed_output="$("$APKSIGNER" verify --verbose --print-certs "$LITERT_APK" 2>&1 || true)"
grep -Fq 'Verifies' <<<"$litert_signed_output" \
  || fail "LiteRT APK does not verify as signed"
if grep -Fq 'CN=Android Debug' <<<"$litert_signed_output"; then
  fail "LiteRT APK is signed with Android debug certificate"
fi
citizen_signed_output="$("$APKSIGNER" verify --verbose --print-certs "$CITIZEN_APK" 2>&1 || true)"
grep -Fq 'Verifies' <<<"$citizen_signed_output" \
  || fail "Citizen Gemma APK does not verify as signed"
if grep -Fq 'CN=Android Debug' <<<"$citizen_signed_output"; then
  fail "Citizen Gemma APK is signed with Android debug certificate"
fi
verify_apk_manifest "$APK" "Local"
verify_apk_manifest "$LITERT_APK" "LiteRT"
verify_apk_manifest "$CITIZEN_APK" "Citizen Gemma"
litert_apk_listing="$(unzip -l "$LITERT_APK")"
grep -Fq 'lib/arm64-v8a/liblitertlm_jni.so' <<<"$litert_apk_listing" \
  || fail "LiteRT APK missing ARM64 LiteRT-LM native library"
grep -Fq 'lib/arm64-v8a/libLiteRtLm.so' <<<"$litert_apk_listing" \
  || fail "LiteRT APK missing FlutterGemma LiteRT-LM FFI library"
grep -Fq 'lib/arm64-v8a/libGemmaModelConstraintProvider.so' <<<"$litert_apk_listing" \
  || fail "LiteRT APK missing FlutterGemma Gemma constraint provider"
citizen_apk_listing="$(unzip -l "$CITIZEN_APK")"
grep -Fq 'lib/arm64-v8a/liblitertlm_jni.so' <<<"$citizen_apk_listing" \
  || fail "Citizen Gemma APK missing ARM64 LiteRT-LM native library"
grep -Fq 'lib/arm64-v8a/libLiteRtLm.so' <<<"$citizen_apk_listing" \
  || fail "Citizen Gemma APK missing FlutterGemma LiteRT-LM FFI library"
grep -Fq 'lib/arm64-v8a/libGemmaModelConstraintProvider.so' <<<"$citizen_apk_listing" \
  || fail "Citizen Gemma APK missing FlutterGemma Gemma constraint provider"

writeup_words="$(wc -w < "$WRITEUP" | tr -d ' ')"
[[ "$writeup_words" -le 1500 ]] || fail "writeup is over 1500 words: $writeup_words"

for public_copy in "$ROOT/README.md" "$ROOT/kan-app/README.md" "$WRITEUP" "$KAGGLE_FORM" "$PRIZE_CLAIMS" "$ROOT/SUBMIT_NOW.md" "$ROOT/SUBMISSION_CHECKLIST.md" "$ROOT/docs/routing-calibration.md" "$ROOT/submission/demo-runbook.md" "$ROOT/kan-app/pubspec.yaml"; do
  if grep -Eiq 'TODO_PUBLIC|placeholder|mobile-first prototype|working social-impact prototype|working prototype|current prototype|\bmock mode\b|deterministic mock|Mock local' "$public_copy"; then
    fail "public copy contains stale placeholder/prototype claim: $public_copy"
  fi
done

for product_copy in \
  "$ROOT/kan-app/lib/features/identity_wallet/home_screen.dart" \
  "$WRITEUP" \
  "$KAGGLE_FORM" \
  "$PRIZE_CLAIMS" \
  "$ROOT/submission/kaggle-dataset-upload/final-kaggle-writeup.md" \
  "$ROOT/submission/kaggle-dataset-upload/KAGGLE_FORM.md" \
  "$ROOT/motorola/README.md"; do
  [[ -f "$product_copy" ]] || continue
  if grep -Eiq 'simulad[oa]|simulated administrator|administrator intake|admin_intake|Vista administrador|Decision simulada|Respaldo local por hardware|intake admin|admin copiado' "$product_copy"; then
    fail "product-facing copy contains stale simulated/admin wording: $product_copy"
  fi
done

if grep -Eiq 'DID \+ VC demo|demo</text>|prototype</text>|placeholder</text>' "$ROOT/submission/media-gallery-cover.svg"; then
  fail "media-gallery cover contains prototype/demo wording"
fi

if grep -R -Eiq 'MockReasoner|ReasonerMode\.mock|mock_reasoner|mock-local' "$ROOT/kan-app/lib" "$ROOT/kan-app/test"; then
  fail "runtime source still contains prototype mock reasoner naming"
fi

if grep -Eq '(^|/)(gradlew|gradlew\.bat)$|gradle-wrapper\.jar' "$ROOT/kan-app/android/.gitignore"; then
  fail "Android Gradle wrapper is ignored; public source repo would not be reconstructible"
fi

if grep -R --include='*.md' -Fq 'KAN_REASONER_MODE' \
  "$ROOT/docs" \
  "$ROOT/README.md" \
  "$ROOT/submission" \
  "$ROOT/motorola"; then
  fail "public docs contain stale KAN_REASONER_MODE; use KAN_REASONER"
fi

if grep -R --include='*.md' -Fq 'Only the Mac Android emulator is attached' \
  "$ROOT/docs" \
  "$ROOT/README.md" \
  "$ROOT/submission" \
  "$ROOT/motorola"; then
  fail "public docs contain stale emulator-only blocker; document Motorola G15 low-memory state"
fi

if grep -R --include='*.md' -Fq 'shasum -a 256 -c submission/dist/kan-demo-package-final.zip.sha256' \
  "$ROOT/docs" \
  "$ROOT/submission" \
  "$ROOT/README.md" \
  "$ROOT/SUBMIT_NOW.md" \
  "$ROOT/SUBMISSION_CHECKLIST.md"; then
  fail "public docs contain root-relative ZIP checksum command; use cd submission/dist first"
fi

if grep -R --include='*.md' -Fq 'kan-debug.apk' \
  "$ROOT/docs" \
  "$ROOT/submission" \
  "$ROOT/README.md" \
  "$ROOT/SUBMIT_NOW.md" \
  "$ROOT/SUBMISSION_CHECKLIST.md"; then
  fail "public docs still reference the retired kan-debug.apk artifact"
fi

if rg -n 'kan-app/lib/features/demo|lib/features/demo|features/demo/home_screen.dart' \
  "$ROOT/kan-app/lib" \
  "$ROOT/kan-app/test" \
  "$ROOT/docs" \
  "$ROOT/submission" >/dev/null; then
  fail "source or public docs still reference the old features/demo module"
fi

if grep -R --include='*.md' -Fq '46 tests' \
  "$ROOT/docs" \
  "$ROOT/README.md" \
  "$ROOT/SUBMISSION_CHECKLIST.md" \
  "$ROOT/submission" \
  "$ROOT/motorola"; then
  fail "public docs contain stale Flutter test count; current suite has 142 tests"
fi

if grep -R --include='*.md' -Fq '58 tests' \
  "$ROOT/docs" \
  "$ROOT/README.md" \
  "$ROOT/SUBMISSION_CHECKLIST.md" \
  "$ROOT/submission" \
  "$ROOT/motorola"; then
  fail "public docs contain stale Flutter test count; current suite has 142 tests"
fi

if grep -R --include='*.md' -Fq '73 tests' \
  "$ROOT/docs" \
  "$ROOT/README.md" \
  "$ROOT/SUBMISSION_CHECKLIST.md" \
  "$ROOT/submission" \
  "$ROOT/motorola"; then
  fail "public docs contain stale Flutter test count; current suite has 142 tests"
fi

if grep -R --include='*.md' -Fq '74 tests' \
  "$ROOT/docs" \
  "$ROOT/README.md" \
  "$ROOT/SUBMISSION_CHECKLIST.md" \
  "$ROOT/submission" \
  "$ROOT/motorola"; then
  fail "public docs contain stale Flutter test count; current suite has 142 tests"
fi

for source_guard in \
  "$ROOT/kan-app/android/app/src/main/kotlin/gt/kan/kan_app/MainActivity.kt:verifyLiteRtModelHashIfNeeded" \
  "$ROOT/kan-app/android/app/src/main/kotlin/gt/kan/kan_app/MainActivity.kt:LiteRT-LM model hash mismatch" \
  "$ROOT/kan-app/lib/features/identity_wallet/home_screen.dart:Prueba agente local" \
  "$ROOT/kan-app/lib/features/identity_wallet/home_screen.dart:PII bloqueada" \
  "$ROOT/kan-app/lib/features/identity_wallet/home_screen.dart:JSON validado" \
  "$ROOT/kan-app/lib/features/identity_wallet/home_screen.dart:ledger firmado" \
  "$ROOT/kan-app/lib/services/litert_gemma_reasoner.dart:litert_gemma.install.warmup.hash ->" \
  "$ROOT/kan-app/lib/services/litert_gemma_reasoner.dart:litert_gemma.generate.hash ->" \
  "$ROOT/kan-app/test/widget_test.dart:Prueba agente local" \
  "$ROOT/kan-app/test/widget_test.dart:Gemma 4 ejecuto la guia" \
  "$ROOT/kan-app/test/widget_test.dart:JSON validado" \
  "$ROOT/kan-app/test/widget_test.dart:ledger firmado" \
  "$ROOT/kan-app/test/services/litert_gemma_reasoner_test.dart:warms and hash-verifies when model is already installed" \
  "$ROOT/scripts/package_demo.sh:kan-app/lib" \
  "$ROOT/scripts/package_demo.sh:kan-app/android/.gitignore" \
  "$ROOT/scripts/package_demo.sh:All ZPK_RELEASE_* variables are required to build public APKs." \
  "$ROOT/scripts/package_demo.sh:ZPK_RELEASE_STORE_PASSWORD" \
  "$ROOT/scripts/package_demo.sh:MOTOROLA_APK" \
  "$ROOT/scripts/publish_submission.sh:motorola/.*" \
  "$ROOT/scripts/run_physical_litert_proof.sh:MIN_RAM_BYTES" \
  "$ROOT/scripts/run_physical_litert_proof.sh:Refusing low-RAM device"; do
  guard_file="${source_guard%%:*}"
  guard_text="${source_guard#*:}"
  grep -Fq "$guard_text" "$guard_file" || fail "missing LiteRT production guard: $guard_text"
done

for claim in \
  'final release APK runs a local ReAct-style Gemma 4 E2B agent through a native Android LiteRT-LM bridge' \
  'verified physical-device flow on an Honor Android phone' \
  '7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb' \
  '2,583,085,056-byte `gemma-4-E2B-it.litertlm` artifact' \
  'privacy guard that blocks raw CUI and 13-digit identifiers before model calls' \
  'no trained adapter is claimed'; do
  grep -Fq "$claim" "$KAGGLE_FORM" || fail "Kaggle form missing claim: $claim"
done

for trace in \
  'Gemma 4 E2B local' \
  'zpk-android-keystore-issuer-key-2026-05' \
  'El ciudadano ha sido víctima de amenazas por WhatsApp' \
  'auth.verify(local) -> ok' \
  'auth.relying_party(local_allowlist) -> approved' \
  'auth.device_presence(' \
  'auth.valid_until(local) ->' \
  'auth.blocked(revocation) -> credential_revoked' \
  'agent_contract.schema(json) -> ok' \
  'agent_contract.safety_review(raw_cui=false) -> ok' \
  'audit_archive.encrypt(AES-GCM-256, android-keystore) -> sealed' \
  'privacy_guard.raw_cui -> absent' \
  'threat_bulletin.verify(offline_hash_pack) -> 8/8_hash_ok' \
  'threat_bulletin.match(CUI+correo+nombre+telefono) -> gt-dpi-fraud-ngo-2026-04,latam-sim-swap-cui-2026-04' \
  'litert_gemma.generate(gemma-4-E2B-it, HF_HUB_OFFLINE=1) -> ok' \
  'recovery_packet.verify(local) -> ok' \
  'reasoner_mode(mlkit-gemma:aicore) -> fallback'; do
  grep -Fq "$trace" "$WRITEUP" "$ROOT/docs/evidence"/*.md "$ROOT/docs/evidence"/*.xml || fail "missing evidence trace: $trace"
done

for flutter_gemma_trace in \
  'flutter_gemma4_smoke.used_local_only -> true' \
  'flutter_gemma4.generate(gemma-4-E2B-it.litertlm) -> ok' \
  'trust_fabric.keystore(ios-keychain)' \
  'agent_ledger.verify(local) -> ok'; do
  grep -Fq "$flutter_gemma_trace" "$ROOT/docs/evidence/ios-flutter-gemma4-smoke-2026-05-02.md" \
    || fail "missing FlutterGemma iOS Gemma 4 evidence trace: $flutter_gemma_trace"
done

for adaptation_trace in \
  'Train examples: 9840' \
  'Validation examples: 1080' \
  'Test examples: 1080' \
  'Status: PASS' \
  'safety_review.raw_cui_included` is false'; do
  grep -Fq "$adaptation_trace" "$ROOT/unsloth/data/DATASET_CARD.md" "$ROOT/unsloth/outputs/dataset_quality_report.md" \
    || fail "missing adaptation evidence: $adaptation_trace"
done

for adaptation_file in \
  "$ROOT/unsloth/data/zpk_gt_latam_sft_train.jsonl" \
  "$ROOT/unsloth/data/zpk_gt_latam_sft_validation.jsonl" \
  "$ROOT/unsloth/data/zpk_gt_latam_sft_test.jsonl" \
  "$ROOT/unsloth/data/zpk_gt_latam_rlkd_teacher.jsonl" \
  "$ROOT/unsloth/train_lora.py" \
  "$ROOT/unsloth/train_grpo.py" \
  "$ROOT/unsloth/zpk_rewards.py"; do
  need_file "$adaptation_file"
done

video_seconds="$(video_duration_seconds "$VIDEO")"
[[ -n "$video_seconds" ]] || fail "could not read video duration"
[[ "$video_seconds" -lt 180 ]] || fail "video is 180 seconds or longer: ${video_seconds}s"

cover_width="$(image_dimension "$COVER" pixelWidth)"
cover_height="$(image_dimension "$COVER" pixelHeight)"
[[ "$cover_width" == "1600" && "$cover_height" == "900" ]] || fail "cover dimensions must be 1600x900, got ${cover_width:-?}x${cover_height:-?}"

zip_listing="$(mktemp)"
zip_markdown_text="$(mktemp)"
trap 'rm -f "$zip_listing" "$zip_markdown_text"' EXIT
unzip -l "$ZIP" > "$zip_listing"
while IFS= read -r zip_md; do
  unzip -p "$ZIP" "$zip_md" >> "$zip_markdown_text"
  printf '\n' >> "$zip_markdown_text"
done < <(unzip -Z1 "$ZIP" | grep -E '\.md$' || true)
if grep -Fq 'KAN_REASONER_MODE' "$zip_markdown_text"; then
  fail "ZIP markdown contains stale KAN_REASONER_MODE; use KAN_REASONER"
fi

grep -q ' \.env\.example$' "$zip_listing" || fail "ZIP missing .env.example"
if grep -q ' \.env$' "$zip_listing"; then
  fail "ZIP contains .env"
fi
if grep -Eq '\.uiautomator\.xml$' "$zip_listing"; then
  fail "ZIP contains raw UIAutomator XML evidence"
fi
for forbidden_zip_entry in \
  'kan-app/.dart_tool/' \
  'kan-app/build/' \
  'kan-app/.idea/' \
  'kan-app/android/.gradle/' \
  'kan-app/android/local.properties' \
  'kan-app/android/app/src/main/java/' \
  'kan-app/ios/Pods/' \
  'kan-app/ios/Flutter/Generated.xcconfig' \
  'kan-app/ios/Flutter/flutter_export_environment.sh' \
  'kan-app/ios/Runner/GeneratedPluginRegistrant.h' \
  'kan-app/ios/Runner/GeneratedPluginRegistrant.m'; do
  if grep -Fq "$forbidden_zip_entry" "$zip_listing"; then
    fail "ZIP contains generated/local source artifact: $forbidden_zip_entry"
  fi
done
if grep -Eq 'submission/(kaggle-writeup-draft|video-script-draft)\.md$' "$zip_listing"; then
  fail "ZIP contains draft submission copy"
fi
if grep -Eq 'submission/live-demo/zpk-litert-debug\.apk(\.sha256)?$' "$zip_listing"; then
  fail "ZIP contains stale debug-named LiteRT APK"
fi
if grep -Eq 'submission/live-demo/kan-debug\.apk(\.sha256)?$' "$zip_listing"; then
  fail "ZIP contains stale local debug APK"
fi
if strings "$APK" | grep -Eiq 'AIza[0-9A-Za-z_-]{20,}|KAN_GEMINI_API_KEY|GEMINI_API_KEY|x-goog-api-key'; then
  fail "APK appears to contain an embedded Gemini API key or key marker"
fi
if strings "$LITERT_APK" | grep -Eiq 'AIza[0-9A-Za-z_-]{20,}|KAN_GEMINI_API_KEY|GEMINI_API_KEY|x-goog-api-key'; then
  fail "LiteRT APK appears to contain an embedded Gemini API key or key marker"
fi
if strings "$CITIZEN_APK" | grep -Eiq 'AIza[0-9A-Za-z_-]{20,}|KAN_GEMINI_API_KEY|GEMINI_API_KEY|x-goog-api-key'; then
  fail "Citizen Gemma APK appears to contain an embedded Gemini API key or key marker"
fi
if unzip -p "$ZIP" | strings | grep -Eq 'AIza[0-9A-Za-z_-]{20,}'; then
  fail "ZIP appears to contain a Gemini API key"
fi

for required in \
  'SUBMIT_NOW.md' \
  '.github/workflows/android-ci.yml' \
  'kan-app/README.md' \
  'kan-app/.gitignore' \
  'kan-app/pubspec.yaml' \
  'kan-app/lib/main.dart' \
  'kan-app/lib/features/identity_wallet/home_screen.dart' \
  'kan-app/lib/services/litert_gemma_reasoner.dart' \
  'kan-app/android/app/src/main/kotlin/gt/kan/kan_app/MainActivity.kt' \
  'kan-app/android/.gitignore' \
  'kan-app/android/gradlew' \
  'kan-app/android/gradlew.bat' \
  'kan-app/android/gradle/wrapper/gradle-wrapper.jar' \
  'kan-app/ios/.gitignore' \
  'kan-app/ios/Flutter/AppFrameworkInfo.plist' \
  'kan-app/ios/Flutter/Debug.xcconfig' \
  'kan-app/ios/Flutter/Release.xcconfig' \
  'kan-app/ios/RunnerTests/RunnerTests.swift' \
  'kan-app/test/widget_test.dart' \
  'kan-app/assets/breach_catalog.json' \
  'scripts/prepare_kaggle_dataset.sh' \
  'scripts/litert_gemma4_smoke.sh' \
  'scripts/test_litert_agent_harness.sh' \
  'scripts/run_physical_litert_proof.sh' \
  'scripts/verify_motorola_physical_flow.sh' \
  'scripts/wireless_installer.sh' \
  'scripts/publish_submission.sh' \
  'scripts/verify_release_build.sh' \
  'scripts/verify_submission.sh' \
  'submission/ARTIFACT_MANIFEST.md' \
  'submission/GITHUB_RELEASE_NOTES.md' \
  'submission/KAGGLE_DATASET_README.md' \
  'submission/KAGGLE_FORM.md' \
  'submission/YOUTUBE_DESCRIPTION.md' \
  'installer/package.json' \
  'installer/package-lock.json' \
  'installer/server.mjs' \
  'submission/kaggle-dataset-metadata.template.json' \
  'submission/kan-final-demo-video.mp4' \
  'submission/media-gallery-cover.png' \
  'submission/media-gallery-cover.svg' \
  'submission/live-demo/zpk-local-release.apk' \
  'submission/live-demo/zpk-litert-release.apk' \
  'submission/live-demo/zpk-citizen-gemma4-release.apk' \
  'submission/final-kaggle-writeup.md' \
  'docs/evidence/local-authentication-proof-2026-05-01.md' \
  'docs/evidence/local-audit-archive-sealed-runtime-2026-05-01.json' \
  'docs/evidence/mlkit-gemma-ondevice-2026-05-01.md' \
  'docs/evidence/litert-gemma4-offline-2026-05-01.md' \
  'docs/evidence/litert-gemma4-app-agent-harness-2026-05-01.md' \
  'docs/evidence/litert-gemma4-phone-self-test-2026-05-02.md' \
  'docs/evidence/litert-gemma4-physical-device-runbook-2026-05-01.md' \
  'docs/evidence/honor-release-citizen-gemma-final-2026-05-07.xml' \
  'docs/evidence/ios-flutter-gemma4-smoke-2026-05-02.md' \
  'docs/evidence/ios-flutter-gemma4-smoke-2026-05-02.png' \
  'docs/evidence/litert-lm-dependency-version-2026-05-02.md' \
  'docs/evidence/goal-completion-audit-2026-05-02.md' \
  'docs/evidence/production-readiness-audit-2026-05-01.md' \
  'docs/evidence/wireless-installer-2026-05-01.md' \
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
  need_file "$DATASET_UPLOAD/kan-demo-package-final.zip"
  need_file "$DATASET_UPLOAD/kan-demo-package-final.zip.sha256"
  (
    cd "$DATASET_UPLOAD"
    shasum -a 256 -c kan-demo-package-final.zip.sha256 >/dev/null
  ) || fail "Kaggle Dataset upload ZIP checksum mismatch"
  while IFS= read -r resource_path; do
    [[ -f "$DATASET_UPLOAD/$resource_path" ]] || fail "Kaggle Dataset upload missing resource: $resource_path"
  done < <(jq -r '.resources[].path' "$DATASET_UPLOAD/dataset-metadata.json")

  grep -Fq 'verified physical-device flow on an Honor Android phone' "$DATASET_UPLOAD/KAGGLE_FORM.md" \
    || fail "Kaggle Dataset upload form missing Honor physical-device claim"
  grep -Fq 'Gemma 4 E2B local' "$DATASET_UPLOAD/final-kaggle-writeup.md" \
    || fail "Kaggle Dataset upload writeup missing local Gemma 4 claim"
  grep -Fq '7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb' "$DATASET_UPLOAD/final-kaggle-writeup.md" \
    || fail "Kaggle Dataset upload writeup missing final APK hash"
fi

echo "PASS: submission artifacts verified"
echo "ZIP: $ZIP"
echo "ZIP SHA-256: $(sha_only "$ZIP")"
echo "APK SHA-256: $(sha_only "$APK")"
echo "LiteRT APK SHA-256: $(sha_only "$LITERT_APK")"
echo "Citizen Gemma APK SHA-256: $(sha_only "$CITIZEN_APK")"
echo "Video SHA-256: $EXPECTED_VIDEO_SHA"
echo "Cover SHA-256: $EXPECTED_COVER_SHA"
echo "Video seconds: $video_seconds"
echo "Cover dimensions: ${cover_width}x${cover_height}"
echo "Writeup words: $writeup_words"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/kan-app"
LIVE="$ROOT/submission/live-demo"
DIST="$ROOT/submission/dist"
MOTOROLA="$ROOT/motorola"
ZIP="$DIST/kan-demo-package-final.zip"
ZIP_SHA="$ZIP.sha256"
LOCAL_APK="$LIVE/zpk-local-release.apk"
LITERT_APK="$LIVE/zpk-litert-release.apk"
CITIZEN_APK="$LIVE/zpk-citizen-gemma4-release.apk"
MOTOROLA_APK="$MOTOROLA/zpk-litert-persona-institucion-release.apk"
LITERT_MODEL_PATH="/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm"
CITIZEN_MODEL_PATH="${CITIZEN_MODEL_PATH:-/sdcard/Android/data/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm}"
LITERT_MODEL_SHA="${LITERT_MODEL_SHA:-ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42}"
LITERT_PUBLIC_URL="${LITERT_PUBLIC_URL:-}"
LITERT_MODEL_URL=""
if [[ -n "$LITERT_PUBLIC_URL" ]]; then
  LITERT_MODEL_URL="${LITERT_PUBLIC_URL%/}/models/gemma-4-E2B-it.litertlm"
fi

mkdir -p "$LIVE" "$DIST" "$MOTOROLA"

missing_signing_vars=()
for signing_var in \
  ZPK_RELEASE_KEYSTORE \
  ZPK_RELEASE_STORE_PASSWORD \
  ZPK_RELEASE_KEY_ALIAS \
  ZPK_RELEASE_KEY_PASSWORD; do
  if [[ -z "${!signing_var:-}" ]]; then
    missing_signing_vars+=("$signing_var")
  fi
done
if [[ "${#missing_signing_vars[@]}" -gt 0 ]]; then
  echo "Missing release signing variables: ${missing_signing_vars[*]}" >&2
  echo "All ZPK_RELEASE_* variables are required to build public APKs." >&2
  exit 1
fi
if [[ ! -f "$ZPK_RELEASE_KEYSTORE" ]]; then
  echo "ZPK_RELEASE_KEYSTORE does not exist: $ZPK_RELEASE_KEYSTORE" >&2
  exit 1
fi

cd "$APP"

flutter build apk --release --split-per-abi
cp "$APP/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" "$LOCAL_APK"

flutter build apk --release \
  --split-per-abi \
  --dart-define=KAN_REASONER=litert-gemma \
  --dart-define=KAN_LITERT_MODEL_PATH="$LITERT_MODEL_PATH" \
  --dart-define=KAN_LITERT_MODEL_URL="$LITERT_MODEL_URL" \
  --dart-define=KAN_LITERT_MODEL_SHA256="$LITERT_MODEL_SHA" \
  --dart-define=KAN_LITERT_TIMEOUT_SECONDS=240

rm -f \
  "$LIVE/kan-debug.apk" \
  "$LIVE/kan-debug.apk.sha256" \
  "$LIVE/zpk-litert-debug.apk" \
  "$LIVE/zpk-litert-debug.apk.sha256"
cp "$APP/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" "$LITERT_APK"

flutter build apk --release \
  --split-per-abi \
  --dart-define=KAN_HOME=citizen \
  --dart-define=KAN_REASONER=litert-gemma \
  --dart-define=KAN_LITERT_MODEL_PATH="$CITIZEN_MODEL_PATH" \
  --dart-define=KAN_LITERT_MODEL_URL="$LITERT_MODEL_URL" \
  --dart-define=KAN_LITERT_MODEL_SHA256="$LITERT_MODEL_SHA" \
  --dart-define=KAN_LITERT_TIMEOUT_SECONDS=240

cp "$APP/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" "$CITIZEN_APK"

for file in \
  "$APP/kan-embedded-catalog-trace.png" \
  "$APP/kan-gemma-hosted-trace.png" \
  "$APP/kan-cactus-270m-notools-trace.png"; do
  if [[ -f "$file" ]]; then
    cp "$file" "$LIVE/$(basename "$file")"
  fi
done

cd "$ROOT"
(
  cd "$LIVE"
  shasum -a 256 "$(basename "$LOCAL_APK")" > "$(basename "$LOCAL_APK").sha256"
  shasum -a 256 "$(basename "$LITERT_APK")" > "$(basename "$LITERT_APK").sha256"
  shasum -a 256 "$(basename "$CITIZEN_APK")" > "$(basename "$CITIZEN_APK").sha256"
)
cp "$LITERT_APK" "$MOTOROLA_APK"
(
  cd "$MOTOROLA"
  shasum -a 256 "$(basename "$MOTOROLA_APK")" > "$(basename "$MOTOROLA_APK").sha256"
)
rm -f "$ZIP" "$ZIP_SHA"

zip -r "$ZIP" \
  README.md \
  LICENSE \
  .env.example \
  .github/workflows/android-ci.yml \
  AGENTS.md \
  SUBMISSION_CHECKLIST.md \
  SUBMIT_NOW.md \
  kan-app/README.md \
  kan-app/.gitignore \
  kan-app/analysis_options.yaml \
  kan-app/pubspec.yaml \
  kan-app/pubspec.lock \
  kan-app/lib \
  kan-app/test \
  kan-app/assets \
  kan-app/android/app/build.gradle.kts \
  kan-app/android/app/proguard-rules.pro \
  kan-app/android/app/src \
  kan-app/android/.gitignore \
  kan-app/android/build.gradle.kts \
  kan-app/android/gradle.properties \
  kan-app/android/gradle/wrapper/gradle-wrapper.jar \
  kan-app/android/gradle/wrapper/gradle-wrapper.properties \
  kan-app/android/gradlew \
  kan-app/android/gradlew.bat \
  kan-app/android/settings.gradle.kts \
  kan-app/ios/.gitignore \
  kan-app/ios/Flutter/AppFrameworkInfo.plist \
  kan-app/ios/Flutter/Debug.xcconfig \
  kan-app/ios/Flutter/Release.xcconfig \
  kan-app/ios/Podfile \
  kan-app/ios/Podfile.lock \
  kan-app/ios/Runner \
  kan-app/ios/RunnerTests \
  kan-app/ios/Runner.xcodeproj \
  kan-app/ios/Runner.xcworkspace \
  scripts/package_demo.sh \
  scripts/prepare_kaggle_dataset.sh \
  scripts/litert_gemma4_smoke.sh \
  scripts/test_litert_agent_harness.sh \
  scripts/run_physical_litert_proof.sh \
  scripts/verify_motorola_physical_flow.sh \
  scripts/wireless_installer.sh \
  scripts/publish_submission.sh \
  scripts/verify_release_build.sh \
  scripts/verify_submission.sh \
  docs \
  installer/package.json \
  installer/package-lock.json \
  installer/server.mjs \
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
  -x '*.DS_Store' '*.uiautomator.xml' 'kan-app/.dart_tool/*' 'kan-app/build/*' 'kan-app/.idea/*' 'kan-app/android/.gradle/*' 'kan-app/android/local.properties' 'kan-app/android/app/src/main/java/*' 'kan-app/ios/Pods/*' 'kan-app/ios/Flutter/Generated.xcconfig' 'kan-app/ios/Flutter/flutter_export_environment.sh' 'kan-app/ios/Runner/GeneratedPluginRegistrant.h' 'kan-app/ios/Runner/GeneratedPluginRegistrant.m' 'installer/node_modules/*' 'installer/dist/*' 'unsloth/.venv/*' '*/__pycache__/*' '*.pyc'

(
  cd "$DIST"
  shasum -a 256 "$(basename "$ZIP")" > "$(basename "$ZIP_SHA")"
)

echo "$ZIP"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL="${MODEL:-$HOME/.cache/huggingface/hub/models--litert-community--gemma-4-E2B-it-litert-lm/blobs/ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42}"
PORT="${PORT:-3333}"
PUBLIC_URL="${PUBLIC_URL:-}"
APP_MODEL_PATH="/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm"
DIST="$ROOT/installer/dist"
APK="$DIST/zpk-litert.apk"

if [[ ! -f "$MODEL" ]]; then
  echo "Gemma 4 LiteRT-LM model missing at $MODEL"
  echo "Run ./scripts/litert_gemma4_smoke.sh once after setting LITERT_LM_BIN."
  exit 1
fi

if [[ -z "$PUBLIC_URL" ]]; then
  LAN_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo 127.0.0.1)"
  PUBLIC_URL="http://$LAN_IP:$PORT"
fi
PUBLIC_URL="${PUBLIC_URL%/}"
if [[ "$PUBLIC_URL" == http://* ]]; then
  echo "Warning: APK download can use local HTTP, but Android model download needs HTTPS."
  echo "For full LiteRT install, run: cloudflared tunnel --url http://127.0.0.1:$PORT"
  echo "Then rerun with: PUBLIC_URL=https://<trycloudflare-url> $0"
fi
MODEL_SHA="$(shasum -a 256 "$MODEL" | awk '{print $1}')"
MODEL_URL="$PUBLIC_URL/models/gemma-4-E2B-it.litertlm"

mkdir -p "$DIST"
cd "$ROOT/kan-app"
LITERT_BUILD_MODE="profile"
LITERT_SPLIT_ARGS=()
LITERT_APK_SOURCE="$ROOT/kan-app/build/app/outputs/flutter-apk/app-profile.apk"
if [[ -n "${ZPK_RELEASE_KEYSTORE:-}" ]]; then
  LITERT_BUILD_MODE="release"
  LITERT_SPLIT_ARGS=(--split-per-abi)
  LITERT_APK_SOURCE="$ROOT/kan-app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
fi

flutter build apk --"$LITERT_BUILD_MODE" \
  "${LITERT_SPLIT_ARGS[@]}" \
  --dart-define=KAN_REASONER=litert-gemma \
  --dart-define=KAN_LITERT_MODEL_PATH="$APP_MODEL_PATH" \
  --dart-define=KAN_LITERT_MODEL_URL="$MODEL_URL" \
  --dart-define=KAN_LITERT_MODEL_SHA256="$MODEL_SHA" \
  --dart-define=KAN_LITERT_TIMEOUT_SECONDS=240
cp "$LITERT_APK_SOURCE" "$APK"
shasum -a 256 "$APK" > "$APK.sha256"

cd "$ROOT/installer"
npm install
APK="$APK" MODEL="$MODEL" PORT="$PORT" PUBLIC_URL="$PUBLIC_URL" npm start

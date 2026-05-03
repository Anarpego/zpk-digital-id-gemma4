#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADB="${ADB_PATH:-adb}"
APK="${APK_PATH:-$ROOT/submission/live-demo/zpk-litert-release.apk}"
OUT_DIR="${OUT_DIR:-$ROOT/docs/evidence}"
WATCH_SECONDS="${WATCH_SECONDS:-240}"
MIN_RAM_BYTES="${MIN_RAM_BYTES:-6000000000}"
ALLOW_LOW_RAM="${ALLOW_LOW_RAM:-0}"
INSTALL=1

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/run_physical_litert_proof.sh [--no-install] [--watch-seconds N]

Environment:
  DEVICE_SERIAL=<adb serial>   Select a phone when more than one device exists.
  ADB_PATH=/path/to/adb        Override adb binary.
  APK_PATH=/path/to/apk        Override APK path.
  OUT_DIR=docs/evidence        Override output directory.
  MIN_RAM_BYTES=6000000000     Minimum physical RAM required for proof.
  ALLOW_LOW_RAM=1              Continue even below RAM gate for diagnosis only.

This script refuses Android emulators. It is only for the final ARM64 phone
proof of in-app LiteRT/Flutter Gemma 4 generation.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-install)
      INSTALL=0
      shift
      ;;
    --watch-seconds)
      WATCH_SECONDS="${2:?missing seconds}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -f "$APK" ]] || {
  echo "Missing APK: $APK" >&2
  exit 1
}

DEVICES=()
while IFS= read -r device; do
  DEVICES+=("$device")
done < <("$ADB" devices -l | awk 'NR > 1 && $2 == "device" {print $1}')
SERIAL="${DEVICE_SERIAL:-}"
if [[ -z "$SERIAL" ]]; then
  if [[ "${#DEVICES[@]}" -ne 1 ]]; then
    echo "Expected exactly one ADB device, found ${#DEVICES[@]}." >&2
    printf 'Devices: %s\n' "${DEVICES[@]:-none}" >&2
    echo "Set DEVICE_SERIAL=<serial> when a phone is connected." >&2
    exit 1
  fi
  SERIAL="${DEVICES[0]}"
fi

QEMU="$("$ADB" -s "$SERIAL" shell getprop ro.kernel.qemu | tr -d '\r')"
MODEL="$("$ADB" -s "$SERIAL" shell getprop ro.product.model | tr -d '\r')"
ABI="$("$ADB" -s "$SERIAL" shell getprop ro.product.cpu.abi | tr -d '\r')"
MEM_TOTAL_KB="$("$ADB" -s "$SERIAL" shell cat /proc/meminfo | awk '/MemTotal:/ {print $2; exit}' | tr -d '\r')"
if [[ -z "$MEM_TOTAL_KB" || ! "$MEM_TOTAL_KB" =~ ^[0-9]+$ ]]; then
  echo "Could not read MemTotal from $SERIAL ($MODEL)." >&2
  exit 1
fi
MEM_TOTAL_BYTES=$((MEM_TOTAL_KB * 1024))

if [[ "$QEMU" == "1" ]]; then
  echo "Refusing emulator $SERIAL ($MODEL). Physical ARM64 phone required." >&2
  exit 1
fi
if [[ "$ABI" != "arm64-v8a" ]]; then
  echo "Refusing non-ARM64 device $SERIAL ($MODEL, ABI=$ABI)." >&2
  exit 1
fi
if [[ "$ALLOW_LOW_RAM" != "1" && "$MEM_TOTAL_BYTES" -lt "$MIN_RAM_BYTES" ]]; then
  echo "Refusing low-RAM device $SERIAL ($MODEL)." >&2
  echo "Device RAM: $MEM_TOTAL_BYTES bytes; required for Gemma proof: $MIN_RAM_BYTES bytes." >&2
  echo "Use ./scripts/verify_motorola_physical_flow.sh for the G15 low-memory fallback proof." >&2
  echo "Set ALLOW_LOW_RAM=1 only for diagnosis; it will not count as generation proof." >&2
  exit 4
fi

mkdir -p "$OUT_DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="$OUT_DIR/litert-gemma4-physical-adb-$STAMP.log"

echo "Device: $SERIAL ($MODEL, $ABI, ram=${MEM_TOTAL_BYTES}B)"
echo "APK: $APK"
echo "Log: $LOG"

if [[ "$INSTALL" -eq 1 ]]; then
  "$ADB" -s "$SERIAL" install -r "$APK"
fi

"$ADB" -s "$SERIAL" logcat -c || true
"$ADB" -s "$SERIAL" shell am start -n gt.kan.kan_app/.MainActivity >/dev/null

cat <<'NEXT'

On the phone:
  1. Open Motor agente offline.
  2. Install/update Gemma if needed.
  3. Tap Probar Gemma offline.
  4. Tap Copiar diagnostico after the self-test finishes.

The script is now collecting logcat. A strong successful proof includes:
  litert_gemma.generate(gemma-4-E2B-it-litertlm) -> ok
  agent_contract.schema(json) -> ok
  agent_contract.safety_review(raw_cui=false) -> ok
  privacy_guard.self_test_raw_cui -> absent
NEXT

"$ADB" -s "$SERIAL" logcat -v time > "$LOG" &
LOG_PID=$!
sleep "$WATCH_SECONDS"
kill "$LOG_PID" 2>/dev/null || true
wait "$LOG_PID" 2>/dev/null || true

if grep -Fq 'litert_gemma.generate(gemma-4-E2B-it-litertlm) -> ok' "$LOG"; then
  echo "PASS: Android physical-device Gemma 4 generation trace found."
else
  echo "No final generation trace found in logcat." >&2
  echo "Use the copied in-app diagnostic as the source of truth if logcat is quiet." >&2
  exit 3
fi

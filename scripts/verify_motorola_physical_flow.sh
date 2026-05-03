#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADB="${ADB_PATH:-adb}"
APK="${APK_PATH:-$ROOT/motorola/zpk-litert-persona-institucion-release.apk}"
INSTALL=1

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/verify_motorola_physical_flow.sh [--no-install]

Environment:
  DEVICE_SERIAL=<adb serial>   Select a phone when more than one device exists.
  ADB_PATH=/path/to/adb        Override adb binary.
  APK_PATH=/path/to/apk        Override APK path.

Verifies the Motorola G15 physical flow with ADB/UIAutomator:
  Persona -> IGSS -> Continuar sin CUI -> Mesa institucional
  Motor -> DEVICE_LOW_MEMORY + deterministic offline fallback

This is not a Gemma generation proof. It verifies the honest low-memory state
and the usable offline institutional workflow on the available G15.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-install)
      INSTALL=0
      shift
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
    echo "Set DEVICE_SERIAL=<serial> when more than one phone is connected." >&2
    exit 1
  fi
  SERIAL="${DEVICES[0]}"
fi

QEMU="$("$ADB" -s "$SERIAL" shell getprop ro.kernel.qemu | tr -d '\r')"
MODEL="$("$ADB" -s "$SERIAL" shell getprop ro.product.model | tr -d '\r')"
ABI="$("$ADB" -s "$SERIAL" shell getprop ro.product.cpu.abi | tr -d '\r')"

if [[ "$QEMU" == "1" ]]; then
  echo "Refusing emulator $SERIAL ($MODEL). Physical ARM64 phone required." >&2
  exit 1
fi
if [[ "$ABI" != "arm64-v8a" ]]; then
  echo "Refusing non-ARM64 device $SERIAL ($MODEL, ABI=$ABI)." >&2
  exit 1
fi

SIZE="$("$ADB" -s "$SERIAL" shell wm size | awk -F: '/Physical size/ {gsub(/ /, "", $2); print $2}' | tr -d '\r')"
WIDTH="${SIZE%x*}"
HEIGHT="${SIZE#*x}"
if [[ -z "$WIDTH" || -z "$HEIGHT" || "$WIDTH" == "$HEIGHT" ]]; then
  echo "Could not parse physical screen size from: $SIZE" >&2
  exit 1
fi

TMP_XML="$(mktemp "${TMPDIR:-/tmp}/zpk-window.XXXXXX.xml")"
trap 'rm -f "$TMP_XML"' EXIT

tap_pct() {
  local px="$1"
  local py="$2"
  local x=$((WIDTH * px / 1000))
  local y=$((HEIGHT * py / 1000))
  "$ADB" -s "$SERIAL" shell input tap "$x" "$y"
  sleep 1
}

dump_ui() {
  "$ADB" -s "$SERIAL" shell uiautomator dump /sdcard/zpk-window.xml >/dev/null
  "$ADB" -s "$SERIAL" exec-out cat /sdcard/zpk-window.xml > "$TMP_XML"
}

current_window_size() {
  perl -0ne 'if (/bounds="\[0,0\]\[(\d+),(\d+)\]"/) { print "$1 $2"; exit }' "$TMP_XML"
}

swipe_forward() {
  local bounds
  bounds="$(current_window_size)"
  local current_width="${bounds%% *}"
  local current_height="${bounds#* }"
  if [[ -z "$current_width" || -z "$current_height" || "$current_width" == "$current_height" ]]; then
    current_width="$WIDTH"
    current_height="$HEIGHT"
  fi
  local x=$((current_width / 2))
  local y1=$((current_height * 80 / 100))
  local y2=$((current_height * 35 / 100))
  "$ADB" -s "$SERIAL" shell input swipe "$x" "$y1" "$x" "$y2" 250
  sleep 1
}

tap_ui() {
  local label="$1"
  local bounds=""
  for _ in 1 2 3 4 5 6; do
    dump_ui
    bounds="$(
      LABEL="$label" perl -0ne '
        my $label = $ENV{"LABEL"};
        while (/<node\b[^>]*>/g) {
          my $node = $&;
          next unless $node =~ /(?:text|content-desc)="([^"]*\Q$label\E[^"]*)"/;
          if ($node =~ /bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"/) {
            print "$1 $2 $3 $4";
            exit;
          }
        }
      ' "$TMP_XML"
    )"
    if [[ -n "$bounds" ]]; then
      read -r x1 y1 x2 y2 <<<"$bounds"
      "$ADB" -s "$SERIAL" shell input tap "$(((x1 + x2) / 2))" "$(((y1 + y2) / 2))"
      sleep 1
      return 0
    fi
    swipe_forward
  done
  echo "Could not find tappable UI label: $label" >&2
  echo "Current UI dump excerpt:" >&2
  sed -n '1,40p' "$TMP_XML" >&2
  exit 1
}

assert_ui() {
  local expected="$1"
  if ! grep -Fq "$expected" "$TMP_XML"; then
    echo "Missing UI text: $expected" >&2
    echo "Current UI dump excerpt:" >&2
    sed -n '1,40p' "$TMP_XML" >&2
    exit 1
  fi
}

echo "Device: $SERIAL ($MODEL, $ABI, ${WIDTH}x${HEIGHT})"
echo "APK: $APK"

"$ADB" -s "$SERIAL" shell settings put system accelerometer_rotation 0 >/dev/null || true
"$ADB" -s "$SERIAL" shell settings put system user_rotation 0 >/dev/null || true
sleep 1

if [[ "$INSTALL" -eq 1 ]]; then
  "$ADB" -s "$SERIAL" install -r "$APK"
fi

"$ADB" -s "$SERIAL" shell am force-stop gt.kan.kan_app >/dev/null
"$ADB" -s "$SERIAL" shell monkey -p gt.kan.kan_app 1 >/dev/null
sleep 2

dump_ui
assert_ui "Persona"
tap_ui "IGSS"
dump_ui
assert_ui "Necesito registrarme o recuperar IGSS"

tap_ui "Continuar sin CUI"
dump_ui
assert_ui "Bandeja IGSS"
assert_ui "Ruta de atencion"
assert_ui "Atender como intake presencial sin credencial"
assert_ui "Pseudonimo:"
assert_ui "Hash paquete:"

tap_ui "Motor"
dump_ui
assert_ui "Motor offline"
assert_ui "DEVICE_LOW_MEMORY"
assert_ui "Respaldo offline disponible"
assert_ui "runtime.local_deterministic -&gt; ready"
assert_ui "runtime.network_required -&gt; false"

echo "PASS: Motorola physical flow verified."

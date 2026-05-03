#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
shasum -a 256 -c zpk-litert-persona-institucion-release.apk.sha256

echo ""
echo "APK listo para copiar al Motorola:"
echo "$(pwd)/zpk-litert-persona-institucion-release.apk"

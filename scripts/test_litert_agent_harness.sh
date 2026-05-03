#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/kan-app"
flutter test test/services/litert_gemma_reasoner_test.dart test/widget_test.dart

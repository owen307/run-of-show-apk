#!/usr/bin/env bash
# Debug APK for current Android phones (arm64). Uses the debug keystore.
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is not on PATH" >&2
  exit 1
fi
flutter pub get
flutter build apk --debug --split-per-abi
mkdir -p dist
cp -f build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk \
  dist/run-of-show-arm64-debug.apk
echo "Wrote dist/run-of-show-arm64-debug.apk"

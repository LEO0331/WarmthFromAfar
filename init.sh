#!/bin/bash
set -e

echo "=== Harness Initialization ==="

echo "=== flutter pub get ==="
flutter pub get

echo "=== flutter analyze ==="
flutter analyze

echo "=== flutter test ==="
flutter test

echo "=== flutter build web ==="
flutter build web

echo "=== Verification Complete ==="
echo ""
echo "Next steps:"
echo "1. Read feature_list.json to see current feature state"
echo "2. Pick ONE unfinished feature to work on"
echo "3. Implement only that feature"
echo "4. Re-run verification before claiming done"

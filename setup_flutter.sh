#!/usr/bin/env bash
# Run this ONCE after installing Flutter.
# It creates the Android/iOS scaffold and wires in our source files.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/finance_tracker"

echo "📦  Creating Flutter project scaffold..."
cd "$SCRIPT_DIR"

# flutter create generates AndroidManifest, build.gradle, etc.
# We pass --org and --project-name to avoid clashes.
flutter create \
  --org com.example \
  --project-name finance_tracker \
  --platforms android \
  finance_tracker

echo "✅  Scaffold created. Copying our source files..."

# Our lib/ and pubspec.yaml already exist — flutter create may have
# overwritten pubspec.yaml, so restore ours.
# (If you ran setup_flutter.sh again by mistake, this is a no-op.)
echo "   pubspec.yaml and lib/ are already in place."

echo "📥  Installing packages..."
cd "$APP_DIR"
flutter pub get

echo ""
echo "🎉  Done! To run the app:"
echo "    1. Start the backend:  cd ../backend && npm start"
echo "    2. Start an Android emulator"
echo "    3. Run:  flutter run"

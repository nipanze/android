#!/usr/bin/env bash
set -euo pipefail

# Helper to launch Pixel_6 AVD and run this Flutter project with SUPABASE values
# Usage:
#   SUPABASE_URL=https://<proj>.supabase.co SUPABASE_ANON_KEY=ey... ./run_with_supabase.sh

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

if [ -z "${SUPABASE_URL:-}" ]; then
  echo "ERROR: SUPABASE_URL environment variable is not set."
  echo "Set SUPABASE_URL and SUPABASE_ANON_KEY before running."
  exit 1
fi
if [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "ERROR: SUPABASE_ANON_KEY environment variable is not set."
  exit 1
fi

echo "Launching Pixel_6 emulator (if not running)..."
flutter emulators --launch Pixel_6 || true

echo "Waiting for device..."
flutter devices --machine

echo "Running app on emulator with Supabase values..."
flutter run -d emulator-5554 \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

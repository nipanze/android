#!/usr/bin/env bash
# Run Nipanze against the Supabase cloud project.
# Usage: ./run_cloud.sh [chrome|web|linux|android] [--clean] [--build]
set -e

if [ -f .env.local ]; then
  export $(grep -v '^#' .env.local | xargs)
fi

URL="${SUPABASE_URL}"
KEY="${SUPABASE_ANON_KEY}"

if [ -z "$URL" ] || [ -z "$KEY" ]; then
  echo "❌  SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env.local"
  exit 1
fi

TARGET="chrome"
DO_CLEAN=false
DO_BUILD=false
EXTRA_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --clean)
      DO_CLEAN=true
      ;;
    --build|--gen|-b)
      DO_BUILD=true
      ;;
    chrome|web|linux|android|edge)
      TARGET="$arg"
      ;;
    *)
      EXTRA_ARGS+=("$arg")
      ;;
  esac
done

if [ "$DO_CLEAN" = true ]; then
  echo "🧹 Cleaning Flutter build cache..."
  flutter clean
  flutter pub get
fi

if [ "$DO_BUILD" = true ] || [ ! -f lib/core/di/injection.config.dart ]; then
  echo "🔧 Generating dependency injection code..."
  dart run build_runner build --delete-conflicting-outputs
fi

echo "🚀 Starting on $TARGET → $URL"
WEB_RESOURCE_ARGS=()
if [[ "$TARGET" == "chrome" || "$TARGET" == "web" ]]; then
  # Avoid requiring www.gstatic.com for CanvasKit during local development.
  WEB_RESOURCE_ARGS+=(--no-web-resources-cdn)
  # Disable HTTP disk cache in Chrome so newly compiled code is fetched
  WEB_RESOURCE_ARGS+=(--web-browser-flag="--disable-cache")
fi

flutter run -d "$TARGET" "${WEB_RESOURCE_ARGS[@]}" \
  --dart-define=SUPABASE_URL="$URL" \
  --dart-define=SUPABASE_ANON_KEY="$KEY" \
  "${EXTRA_ARGS[@]}"
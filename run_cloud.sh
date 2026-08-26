#!/usr/bin/env bash
# Run Nipanze against the Supabase cloud project.
# Usage: ./run_cloud.sh [web|linux|android]
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

TARGET="${1:-chrome}"

echo "🚀 Starting on $TARGET → $URL"
WEB_RESOURCE_ARGS=()
if [[ "$TARGET" == "chrome" || "$TARGET" == "web" ]]; then
  # Avoid requiring www.gstatic.com for CanvasKit during local development.
  WEB_RESOURCE_ARGS+=(--no-web-resources-cdn)
fi

flutter run -d "$TARGET" "${WEB_RESOURCE_ARGS[@]}" \
  --dart-define=SUPABASE_URL="$URL" \
  --dart-define=SUPABASE_ANON_KEY="$KEY"
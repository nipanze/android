#\!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")" && pwd)"
rm -f outputs/*.apk
printf "Old APKs removed.\n"

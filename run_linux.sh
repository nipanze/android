#!/bin/bash
set -a
source .env.local
set +a

flutter run -d linux \
  --dart-define=SUPABASE_URL=$LOCAL_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$LOCAL_ANON_KEY

#!/bin/bash
# Deploys the free push sender (Supabase Edge Function `send-push`).
# Usage: bash deploy_push.sh        (see docs/PUSH_NOTIFICATIONS.md)
set -e
cd "$(dirname "$0")"

PROJECT_REF="dvmqgwosltkmtltwfvpp"
KEY_FILE="service-account.json"
SUPABASE="npx -y supabase@latest"

if [ ! -f "$KEY_FILE" ]; then
  # Firebase may save it with a long name in Downloads; pick the newest one.
  FOUND=$(ls -t ~/Downloads/skill-swapx-ac361-firebase-adminsdk-*.json 2>/dev/null | head -1 || true)
  if [ -n "$FOUND" ]; then
    mv "$FOUND" "$KEY_FILE"
    echo "Using key from $FOUND"
  else
    echo "Firebase key nahi mili."
    echo "Browser khul raha hai: 'Generate new private key' dabayein, phir yeh script dobara chalayein."
    open "https://console.firebase.google.com/project/skill-swapx-ac361/settings/serviceaccounts/adminsdk"
    exit 1
  fi
fi

echo "1/3 Supabase login (browser khulega, wahan approve karein)..."
$SUPABASE projects list >/dev/null 2>&1 || $SUPABASE login

echo "2/3 Firebase key ko Supabase secret mein save kar rahe hain..."
$SUPABASE secrets set --project-ref "$PROJECT_REF" FIREBASE_SERVICE_ACCOUNT="$(cat "$KEY_FILE")"

echo "3/3 send-push function deploy ho raha hai..."
$SUPABASE functions deploy send-push --project-ref "$PROJECT_REF" --no-verify-jwt --use-api

echo "Done. Push notifications ready hain."

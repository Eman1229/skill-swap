# Push notifications (free setup)

Pushes are sent by a Supabase Edge Function through FCM, so the Firebase
project can stay on the free Spark plan.

```
App action (chat msg, swap request, session, asset...)
  -> writes notifications/{id} in Firestore      (in-app list + foreground banner)
  -> PushNotificationService.dispatch(id)
  -> Supabase function `send-push`                (supabase/functions/send-push)
  -> FCM HTTP v1 -> receiver's phone              (works with app closed)
```

## One-time setup

1. Firebase console -> Project settings -> Service accounts ->
   **Generate new private key**. Save it as `service-account.json`
   (never commit it).
2. Install the Supabase CLI and log in with the account that owns the
   Supabase project:
   ```bash
   brew install supabase/tap/supabase
   supabase login
   ```
3. From the repo root:
   ```bash
   supabase secrets set --project-ref dvmqgwosltkmtltwfvpp \
     FIREBASE_SERVICE_ACCOUNT="$(cat service-account.json)"
   supabase functions deploy send-push --project-ref dvmqgwosltkmtltwfvpp --no-verify-jwt
   ```
4. `flutter pub get`, then run the app on a real Android phone (or emulator
   with Google Play).

## Testing

Two phones/accounts: log in on both, send a chat message or swap request from
A, with B's app in background or closed -> B gets the push. Logs:
Supabase dashboard -> Edge Functions -> send-push -> Logs.

## Notes

- iOS remote push needs an APNs key uploaded to Firebase (paid Apple
  developer account). Without it iOS still gets in-app banners and session
  reminders.
- Web: no system notifications (in-app list only).
- Do **not** also deploy the old Cloud Functions in `functions/`
  (`swapProposalNotifier`, `directMessageNotifier`, `generalNotifier`), or
  every push would arrive twice.

# Google Sign-In setup

The Flutter implementation is ready, but the Firebase project must authorize
the app before Google can issue credentials.

1. In Firebase Console for `skill-swapx-ac361`, open **Authentication → Sign-in
   method** and enable **Google**.
2. Add this Android app's debug and release SHA-1/SHA-256 fingerprints in
   **Project settings → Your apps → Android** (`com.example.skill_swap`).
3. Download the refreshed `google-services.json` and replace
   `android/app/google-services.json`. The current file has no OAuth clients,
   so Android Google sign-in cannot succeed until this is done.
4. Under **Authentication → Settings → Authorized domains**, add every web
   deployment domain (for example the Vercel production and preview domains).

After changing Firebase configuration, run `flutter pub get` and rebuild the
Android app. Web uses Firebase Auth's Google popup and needs no client ID in
`index.html`.

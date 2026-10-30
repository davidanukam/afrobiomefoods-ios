# Igbo Food Heritage for iPhone

SwiftUI version of the Igbo Food Heritage app. It includes the same onboarding, home screen, 49 recipes, cooking mode, community posts, London ingredient shops, nutrition guides, settings, and the Supabase admin recipe editor.

This folder is an Xcode project. iPhone apps are built on a Mac.

## Run it on your iPhone

1. Copy this folder to a Mac, or open it from a shared drive the Mac can see.
2. Install Xcode 16 or newer from the Mac App Store.
3. Open `IgboFoodHeritage.xcodeproj`.
4. Connect the iPhone with a cable and tap Trust on the phone.
5. In Xcode, select the IgboFoodHeritage target, open Signing & Capabilities, and choose your Apple ID team. A free Apple ID can install the app for about 7 days.
6. Choose your iPhone in the run destination menu, then press Run.

The first launch asks for a language, text size, and guest or account sign-in. Guest mode opens the full local app.

## Supabase

Guest mode works with no keys. Email sign-in, Google sign-in, live community posts, shop updates, and the admin editor need the same project the Android app uses.

In `IgboFoodHeritage/Info.plist`, set:

- `SUPABASE_URL` to the project URL
- `SUPABASE_ANON_KEY` to the anon key

For Google sign-in, add this redirect URL in the Supabase dashboard under Authentication:

`igbo-food-heritage://auth-callback`

Admin recipe editing appears in Settings after you sign in with a user whose `app_metadata.admin` is true.

## Refresh the bundled recipes

From this folder, after the Expo project’s recipe data changes:

```bash
node scripts/export-catalog.mjs
```

That rewrites `IgboFoodHeritage/Resources/catalog.json` and the photos in `IgboFoodHeritage/Resources/Images`.

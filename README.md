# Igbo Food Heritage for iPhone

SwiftUI version of the Igbo Food Heritage app. It includes the same onboarding, home screen, 49 recipes, cooking mode, community posts, London ingredient shops, nutrition guides, settings, and the Supabase admin recipe editor.

This folder is an Xcode project for Xcode 14.2 on macOS Monterey 12.7.6 (Intel). The app targets iOS 16. Building and installing happen on the Mac.

## Run it on your iPhone

These steps match Xcode 14.2. The menus say Preferences, and the run button is the triangle in the top-left of the window.

### 1. Put this folder on the Mac

Copy the whole `afrobiomefoods-ios` folder. The Mac needs the updated copy from after the Xcode 14.2 build fixes. An older copy still shows the 43 issues in the Issue navigator.

Keep this layout. Both items sit next to each other:

```
afrobiomefoods-ios/
  IgboFoodHeritage.xcodeproj
  IgboFoodHeritage/
  README.md
```

Ways that work:

1. Zip the folder on the Windows PC.
2. Move the zip with a USB drive, AirDrop, or a cloud folder.
3. On the Mac, double-click the zip so Finder extracts it.
4. Put the extracted folder somewhere stable, such as `Documents`. Leave it there while you work. Moving it later makes Xcode lose the file references.

Open the extracted folder. Confirm you can see `IgboFoodHeritage.xcodeproj` (a white blueprint icon) and a folder named `IgboFoodHeritage`.

### 2. Open the project

1. Double-click `IgboFoodHeritage.xcodeproj`.
2. If macOS asks whether to open it, click Open.
3. Wait until the top progress bar finishes. The first open indexes every Swift file and the recipe photos. That can take a few minutes.
4. In the left sidebar, the blue project icon at the top should read `IgboFoodHeritage`. Under it you should see a yellow folder group also named `IgboFoodHeritage`, with the Swift files inside.

If the sidebar is hidden, press Command-1, or choose View > Navigators > Project.

If Xcode says the project is damaged, you opened an older copy. Close Xcode and open the `.xcodeproj` from this updated folder.

### 3. Add your Apple ID

A free Apple ID is enough. The app stays on the phone for about 7 days, then Xcode has to install it again.

1. In the menu bar, click Xcode > Preferences.
2. Click the Accounts tab.
3. Click the + button at the bottom left.
4. Choose Apple ID and click Continue.
5. Sign in with the Apple ID you use on the iPhone.
6. After it appears in the list, close Preferences.

### 4. Turn on signing

1. Click the blue `IgboFoodHeritage` project icon at the top of the left sidebar.
2. In the center pane, under TARGETS, click `IgboFoodHeritage`. There is also a PROJECT row with the same name. The target is the one under TARGETS.
3. Click the Signing & Capabilities tab.
4. Check Automatically manage signing.
5. In the Team menu, choose the personal team. It looks like `Your Name (Personal Team)`.
6. Leave Bundle Identifier as `com.afrobiomefoods.igbofoodheritage`.
7. Wait until the signing spinner stops. A successful setup shows a Signing Certificate line, usually `Apple Development: your@email`.

If Team stays empty, go back to step 3 and confirm the Apple ID is listed under Accounts.

### 5. Choose where the app runs

The destination menu is in the toolbar, to the right of the scheme name `IgboFoodHeritage`. It currently may say `Any iOS Device`.

Xcode 14.2 can install this app on an iPhone running iOS 16. Use that phone when you have one.

If the iPhone is on iOS 17 or later, Xcode 14.2 cannot install onto it. Use the simulator instead:

1. Click the destination menu.
2. Under iOS Simulators, choose iPhone 14, or any other iPhone listed there.
3. The first simulator launch downloads nothing extra when the iOS 16 simulator is already installed with Xcode 14.2. If the list is empty, open Xcode > Preferences > Platforms and confirm an iOS 16 simulator runtime is installed. Then use Window > Devices and Simulators > Simulators, click +, and add an iPhone 14 with that runtime.

### 6. Prepare an iOS 16 iPhone

Skip this section when you are using the simulator.

1. Unlock the iPhone.
2. Connect it with a cable that carries data. A charge-only cable will not show the phone in Xcode.
3. If the phone asks to Trust This Computer, tap Trust and enter the passcode.
4. On iOS 16, turn on Developer Mode: Settings > Privacy & Security > Developer Mode. Turn it on, restart the phone when asked, and confirm the prompt after restart.
5. In Xcode, open Window > Devices and Simulators. The phone should appear in the left list with a green dot once it is ready. If it says the device is busy, wait until that message clears.
6. Click the destination menu in the toolbar and choose that iPhone. Its name replaces `Any iOS Device`.

### 7. Build, then run

1. Choose Product > Clean Build Folder. The menu item appears when you hold the Option key while the Product menu is open. You can also press Shift-Command-K.
2. Choose Product > Build, or press Command-B.
3. Watch the status bar at the top. A successful build ends with `Build Succeeded`.
4. Open the Issue navigator with the triangle icon in the left sidebar, or press Command-5. It should say `No Issues`.
5. Press the triangular Run button in the toolbar, or press Command-R.

Xcode compiles, installs, and launches the app. The first build is the slow one. Later builds are shorter.

### 8. Trust the developer on the phone

The first time a free Apple ID installs an app, iOS blocks the icon until you trust it.

1. On the iPhone, open Settings > General > VPN & Device Management.
2. Under Developer App, tap the entry for your Apple ID.
3. Tap Trust, then Trust again.

Go back to the home screen and open Igbo Food Heritage.

The simulator does not ask for this trust step.

### 9. What the first launch does

The app opens on the language screen.

1. Choose English, Igbo, or Français, then tap Continue.
2. On the next screen, pick a text size and the contrast and audio switches, then tap Continue.
3. On the sign-in screen, tap Continue as guest.

Guest mode opens the full local app: home, all 49 recipes, cooking mode, the bundled community posts, the London shop list, nutrition, and settings. Email, Google, live posts, and the admin editor stay off until the Supabase keys below are filled in.

### 10. If signing fails

Read the red text under Signing & Capabilities and match it to one of these:

- **Signing for IgboFoodHeritage requires a development team.** The Team menu is still empty. Repeat step 3 and step 4.
- **Failed to register bundle identifier.** Another Apple account already owns `com.afrobiomefoods.igbofoodheritage`. In Signing & Capabilities, change Bundle Identifier to something only you use, such as `com.yourname.igbofoodheritage`. Use letters, numbers, and dots. Then wait for the signing spinner to finish.
- **The maximum number of apps for free development profiles has been reached.** A free Apple ID can only have a few installed development apps. Delete one of those apps from the iPhone, then press Run again.
- **Provisioning profile has expired**, or the app opens and then closes after about a week. Connect the phone and press Run again. Free signing lasts about 7 days.

### 11. If the phone never appears, or Xcode refuses to run on it

- Unlock the phone and tap Trust This Computer again.
- Try another cable and another USB port. Avoid a charge-only cable.
- In Window > Devices and Simulators, select the phone and read the status line.
- A message that the iPhone is running a version of iOS this Xcode does not support means the phone is on iOS 17 or later. Switch the destination menu to an iPhone simulator, as in step 5, and press Run.
- If the destination still says `Any iOS Device`, the Run button stays disabled. Pick either the connected iPhone or a simulator.

### 12. If the Issue navigator still lists errors

1. Confirm Finder is showing the updated folder, the one that contains this README.
2. Quit Xcode.
3. Open `IgboFoodHeritage.xcodeproj` from that folder again.
4. Product > Clean Build Folder, then Product > Build.

The errors from the earlier build were Swift 5.7 limits in Xcode 14.2: `switch` cases that needed an explicit `return`, screens with more than 10 views in one stack, and the Supabase sign-in helper being tied to the main actor. Those are fixed in this copy.

## Supabase

Guest mode works with the empty keys that ship in the project. Email sign-in, Google sign-in, live community posts, shop updates, and the admin editor use the same Supabase project as the Android app.

1. In Xcode’s left sidebar, open the `IgboFoodHeritage` group.
2. Click `Info.plist`.
3. Find the rows `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
4. Double-click the empty Value cell for `SUPABASE_URL` and paste the project URL. It looks like `https://your-project.supabase.co`.
5. Paste the anon key into `SUPABASE_ANON_KEY`. Use the anon public key. Leave the service role key out of the app.
6. Save with Command-S.
7. Press Run again.

For Google sign-in, open the Supabase dashboard, go to Authentication, and add this redirect URL:

`igbo-food-heritage://auth-callback`

Google sign-in uses that address to return to the app. Email and password sign-in work once the two plist values are set, even before the redirect is added.

Admin recipe editing appears in Settings after you sign in with a user whose `app_metadata.admin` is true.

## Refresh the bundled recipes

From this folder, after the Expo project’s recipe data changes:

```bash
node scripts/export-catalog.mjs
```

That rewrites `IgboFoodHeritage/Resources/catalog.json` and the photos in `IgboFoodHeritage/Resources/Images`. Run it on a machine that has the Expo project next to this folder, then copy the updated iOS folder to the Mac and build again.

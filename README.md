# Skeleton

A reusable Flutter + Firebase starter. Clone it, rename it, and start building your app's real features on top of a working foundation.

## What is included

Only the features every app needs:

| Feature | What it does |
|---|---|
| **Auth** | Register, verify email before app access, login, logout, forgot password (Firebase Auth, email/password) |
| **Home** | Dashboard for existing features, with navigation through the drawer |
| **Profile** | Edit your name, change your password, and request an email change with verification |
| **Settings** | Theme, language, app version, and logout in the navigation drawer |

Also included: theme, router with an auth redirect, global error handling with Crashlytics (release builds), form validators, reusable widgets, and a test baseline.

### Optional feature modules

Enable or disable modules in
[`lib/core/config/feature_config.dart`](lib/core/config/feature_config.dart)
by changing `AppFeatures.current`. Rebuild the app after changing a flag.

| Module | Independent behavior | Dependency |
|---|---|---|
| Authentication | Email/password sign-in, registration, verification, password reset | Firebase Auth |
| Home | Anonymous or authenticated landing screen | None |
| Profile | Account details and account-security actions | Authentication and Firestore |
| Settings: appearance | Theme selection | Local preferences |
| Settings: language | Language selection | Local preferences |
| Settings: device authentication | App lock after launch/background | Authentication, Settings, and device authentication support |
| Push notifications | Firebase Cloud Messaging; foreground notifications are displayed by the platform | Firebase Messaging |
| Notification inbox | Per-user in-app security notifications with read status | Authentication and Firestore |
| Crash reporting | Release crash reports | Firebase |

Profile and device authentication are automatically unavailable when
Authentication is disabled. Authentication can run without Profile or
Firestore. When Authentication is disabled, Home or at least one Settings
module must remain enabled. When Authentication is enabled, Home, Profile, or
at least one Settings module must remain enabled as the post-login destination.
The app validates these combinations at startup.

For an anonymous build that does not initialize Firebase, disable
`authentication`, `crashReporting`, and `pushNotifications`, and keep Home or
a Settings module enabled. Home and local Settings then run independently of
Firebase.

Push notifications are enabled by default and ask for permission from Settings,
not at app startup. Signed-in devices register their FCM token through an
owner-scoped Firestore document; tokens are stored privately. Password-change
notifications are created in the same owner's inbox, then a Firestore trigger
sends the native push. Stale tokens are removed.
Android and iOS pushes use the default sound, and
Android uses the `push_notifications` channel. Tapping a push opens the matching
in-app notification. A signed-out user is sent through sign-in and email
verification first, then returned to the requested notification. Signing out
removes the current device token before ending the session.

#### Enable remote push delivery

The sender is defined in `functions/` and runs with the Firebase Admin SDK, so
no service-account credential is stored in the app or repository. Device
tokens and inbox entries are stored in per-user Firestore paths with
owner-scoped security rules. Deploy only the new push function to the app's Firebase project
(`whatsapp-bot-f57a8`):

```
firebase login
firebase deploy --only functions:sendInboxPush --project whatsapp-bot-f57a8
```

Cloud Functions deployment requires a Firebase project on the Blaze billing
plan, a supported Node.js runtime (Node 22), and a Firebase account with
permission to deploy Functions. The command targets only these new functions;
it does not deploy Firestore rules or replace the existing `messageOnCreate`
and `whatsappWebhook` functions in this project. Notification and token writes
are restricted by the user-scoped rules. The app's profile and notification
inbox still need user-scoped Firestore permissions.
Because this project already has existing rules, review and merge the relevant
paths rather than deploying this repository's standalone rules file wholesale.

#### Configure iOS/APNs and release signing

1. In Apple Developer, open the App ID matching the app's bundle identifier
   (`com.yourname.skeleton`) and enable **Push Notifications**.
2. Create an APNs authentication key (`.p8`) with Apple Push Notifications
   enabled. In Firebase Console → Project settings → Cloud Messaging, upload the
   key with its Key ID and Team ID for the iOS Firebase app. Keep the `.p8`
   private; do not commit it or add it to Codemagic environment variables.
3. Regenerate the App Store provisioning profile after enabling the capability.
   It must match the bundle ID and include the `aps-environment` entitlement.
4. In Codemagic, update/select that profile and a matching Apple distribution
   certificate for the `ios-release` workflow. The workflow now checks the
   selected profile for the entitlement before archiving and fails with a
   targeted message if it is absent.

Android/iOS configuration files are generated by FlutterFire. If the Firebase
project or app identifiers change, rerun `flutterfire configure` and commit the
regenerated non-secret configuration files. Changing the configured Firebase
project does not migrate Authentication users, Firestore data, or FCM tokens;
those must be migrated separately if existing accounts/data need to be kept.

Password and email changes require the current password to reauthenticate.
Firebase sends a verification link for email changes; the account continues
using its current address until that link is confirmed.
New accounts must verify their email address before accessing app screens.
The verification screen lets users resend the link or refresh the verification
status after opening it.
After a password change, the app records an in-app security notification in
the user's Firestore notification inbox. Open the inbox from the Home app-bar
bell. Selecting an item opens its detail and marks it as read; close on either
the inbox or detail returns Home. Existing Firestore rules must allow signed-in
users to read only their own profile and notification documents. This
server-created inbox entry is a user-facing
confirmation, not a server-authoritative security audit log; password changes
made outside this app are not recorded here.
Device authentication can optionally be enabled in Settings. When enabled,
the app requires the device's biometric or screen-lock credential on launch
and when it returns from the background.

## Stack

- **Flutter** (Material 3)
- **Riverpod** for state management
- **go_router** for navigation
- **Firebase**: Auth, Firestore, Crashlytics, Analytics
- **shared_preferences** for local settings

## Project structure

```
lib/
  main.dart                 App entry point (Firebase init, providers)
  app.dart                  MaterialApp.router, theme mode
  firebase_options.dart     Generated by FlutterFire (per Firebase project)
  core/
    config/app_config.dart  App name, version, seed color, collection names
    firebase/               Firebase init + shared providers
    router/                 Routes and the auth redirect
    theme/                  Light and dark themes
    utils/                  Validators
  features/
    auth/                   presentation/  application/  data/
    home/
    profile/
    settings/
  shared/widgets/           Reusable widgets (button, text field, snackbar)
test/                       Unit and widget tests (fake repositories, no Firebase)
```

Each feature follows the same three layers:

- `presentation/`: screens and widgets
- `application/`: Riverpod providers and controllers (state)
- `data/`: repositories and models (Firebase access lives here only)

## Getting started

### Prerequisites

- Flutter SDK (run `flutter doctor` and fix anything red)
- Node.js and the Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### Setup

1. Clone the repo and install packages:
   ```
   flutter pub get
   ```
2. Create a Firebase project. Enable **Authentication → Email/Password** and create a **Firestore** database.
3. Connect the app to your Firebase project (this regenerates `lib/firebase_options.dart`):
   ```
   firebase login
   flutterfire configure --project=<your-project-id>
   ```
4. For a dedicated, empty project, deploy the Firestore rules from this repository:
   ```
   firebase deploy --only firestore:rules --project <your-project-id>
   ```
   These rules let each signed-in user read and write only their own
   `users/{uid}` profile and notification documents. Do not replace rules on a
   project that already hosts other services; merge the required user-scoped
   paths with its existing rules.
5. Run the app:
   ```
   flutter run
   ```

### Run the checks

```
flutter analyze
flutter test
```

## Codemagic CI/CD

The repository includes [`codemagic.yaml`](codemagic.yaml) with separate release
workflows for Android and iOS. Both workflows install dependencies, run
analysis and tests, and build a signed release artifact.

Before running a workflow, configure these items in Codemagic:

1. Add an environment variable group named `app_secrets` containing:
   - `API_BASE_URL` (optional; leave empty if the app does not use the API)
   - `API_KEY` (optional; use a Codemagic secret variable)
   - `CM_PUBLISH_EMAIL` (the address that receives build notifications)
2. Add or select an Android keystore with the Codemagic credential/reference
   name `medsalem`. If your keystore uses a different reference, update the
   `android_signing` value in `codemagic.yaml` to match it exactly. The release
   Gradle configuration consumes Codemagic's `CM_KEYSTORE_PATH`,
   `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, and `CM_KEY_PASSWORD` variables.
3. In Apple Developer, register the App ID `com.yourname.skeleton` under
   **Certificates, Identifiers & Profiles → Identifiers**. Enable the
   capabilities used by the app, then create an App Store provisioning profile
   for this App ID.
4. Create an App Store Connect API-key integration named `codemagic`. The key
   must have access to the Apple Developer signing resources, not only
   App Store Connect metadata.
5. In Codemagic, upload/select the Apple distribution certificate and the
   provisioning profile for `com.yourname.skeleton`, or enable automatic
   provisioning with the `codemagic` integration. The profile's bundle ID and
   distribution type must exactly match the workflow.
6. Update the bundle identifier in `codemagic.yaml` after following
   [`RENAME.md`](RENAME.md) for a new app.

The Firebase configuration files are already committed as generated by
FlutterFire. If the Firebase project changes, rerun `flutterfire configure`
locally and commit the regenerated files before triggering a release build.

## Using the skeleton for a new project

1. Follow [RENAME.md](RENAME.md) to rename the package, app name and bundle id, and to connect a new Firebase project.
2. Add your own features by following [HOW_TO_ADD_A_FEATURE.md](HOW_TO_ADD_A_FEATURE.md).

## Rules for keeping the skeleton reusable

- Keep project-specific values in `lib/core/config/app_config.dart` and
  optional module switches in `lib/core/config/feature_config.dart`.
- Use relative imports inside `lib/` so renaming needs no code changes.
- Only Firebase-facing code goes in `data/`. UI never calls Firebase directly.
- Keep the app runnable at all times, and add tests when you add logic.

## Roadmap

- [x] Auth, home, profile, settings
- [x] Test baseline
- [ ] Localization (English plus a language picker in the navigation drawer)
- [ ] CI with GitHub Actions (analyze, test, build)
- [ ] Dev and prod Firebase projects with flavors

# Skeleton

A reusable Flutter + Firebase starter. Clone it, rename it, and start building your app's real features on top of a working foundation.

## What is included

Only the features every app needs:

| Feature | What it does |
|---|---|
| **Auth** | Register, verify email before app access, login, logout, forgot password (Firebase Auth, email/password) |
| **Home** | Dashboard for existing features, with navigation through the drawer |
| **Profile** | Edit personal details |
| **Settings** | Appearance, language, notifications, and account security |

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
sends the native push. Each signed-in account can turn push delivery on or off
in Settings; the preference is stored with the user's Firestore profile and
checked by both token registration and the push sender. Stale tokens are
removed.
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

#### Configure legal/support destinations and account actions

Privacy, terms, and support destinations are supplied at build time. Blank or
invalid values are not shown in Settings; the placeholder support address is
not published as a real contact:

```
flutter build appbundle --dart-define=PRIVACY_POLICY_URL=https://example.com/privacy --dart-define=TERMS_OF_SERVICE_URL=https://example.com/terms --dart-define=SUPPORT_EMAIL=help@example.com
```

Replace the example destinations with the cloned app's published policy, terms,
and monitored support address. The app opens configured web links in the
browser and support through the device's email app.

Account deletion and **Sign out all devices** use authenticated callable
functions in `functions/`. Both require recent password reauthentication.
Account deletion recursively removes `users/{uid}` and its subcollections
before deleting the Firebase Authentication user. If more user-owned data is
added outside that path, extend the callable cleanup before shipping it.
Session revocation uses Firebase Admin `revokeRefreshTokens`; Firebase applies
this to all refresh tokens, so the current device is signed out too. Other
devices' existing ID tokens can remain valid until they expire (up to about one
hour); they cannot renew their sessions after that. The app also removes the
account's stored FCM tokens and clears its local session. Deploy these functions
to the target Firebase project on Blaze:

```
firebase deploy --only functions:deleteAccount,functions:revokeAllSessions --project whatsapp-bot-f57a8
```

Deploy the callable functions before exposing these actions in a release build.

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
The **Settings → Account security** section manages app lock and password,
email, and mobile-number changes; the Profile screen is reserved for personal
details.
Appearance and language are presented as compact settings rows; selecting one
opens a picker with the available choices.
Changing a mobile number verifies the new number with SMS and reauthenticates
with the current password before updating the Firebase phone credential.
New accounts must verify their email address before accessing app screens.
The verification screen lets users resend the link or refresh the verification
status after opening it.
Registration requires a phone number in E.164 format (for example
`+14155552671`) and SMS verification. After the code is verified, the phone
credential is linked to the new email/password account. Users continue to sign
in with their email and password, and must still verify their email before
accessing app screens. Configure Firebase's Phone provider, allowed SMS
regions, Android SHA fingerprints, and the iOS APNs/reCAPTCHA setup before
testing with real phone numbers. Use Firebase test phone numbers during
development to avoid sending real SMS.
After a password change, the app records an in-app security notification in
the user's Firestore notification inbox. Open the inbox from the Home app-bar
bell. Selecting an item opens its detail and marks it as read; close on either
the inbox or detail returns Home. Existing Firestore rules must allow signed-in
users to read only their own profile and notification documents. This
server-created inbox entry is a user-facing
confirmation, not a server-authoritative security audit log; password changes
made outside this app are not recorded here.
Device authentication can optionally be enabled in Settings → Account
security. When enabled, the app requires the device's biometric or screen-lock
credential on launch and when it returns from the background.
Account security also supports password, email, and verified mobile-number
changes, account deletion, and revoking refresh-token sessions. Destructive
actions require current-password reauthentication; deleting an account removes
its profile and nested notification/token data.

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
2. Create a Firebase project. Enable **Authentication → Email/Password** and **Authentication → Phone**, and create a **Firestore** database. Phone Auth is used to verify phone numbers during registration; login remains email/password. Configure allowed SMS regions in Firebase Authentication.
3. For Android phone auth, add the app's SHA-1 and SHA-256 signing fingerprints in Firebase Project Settings → Android app. For iOS, configure APNs for Firebase Messaging; phone auth may use APNs or a reCAPTCHA fallback.
4. Connect the app to your Firebase project (this regenerates `lib/firebase_options.dart`):
   ```
   firebase login
   flutterfire configure --project=<your-project-id>
   ```
5. For a dedicated, empty project, deploy the Firestore rules from this repository:
   ```
   firebase deploy --only firestore:rules --project <your-project-id>
   ```
   These rules let each signed-in user read and write only their own
   `users/{uid}` profile and notification documents. Do not replace rules on a
   project that already hosts other services; merge the required user-scoped
   paths with its existing rules.
6. Run the app:
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

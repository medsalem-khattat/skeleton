# Skeleton

A reusable Flutter + Firebase starter. Clone it, rename it, and start building your app's real features on top of a working foundation.

## What is included

Only the features every app needs:

| Feature | What it does |
|---|---|
| **Auth** | Register, verify email before app access, login, logout, forgot password, and in-app email action links |
| **Home** | Dashboard for existing features, with navigation through the drawer |
| **Profile** | Edit personal details and manage a profile photo |
| **Settings** | Appearance, language, notifications, account security, and data export |
| **Onboarding** | Localized first-run introduction with persistent skip/finish |

Also included: theme, router with an auth redirect, a Firebase Remote Config
minimum-version gate for mobile releases, global error handling with
Crashlytics (release builds), form validators, reusable widgets, and a test
baseline.

Architecture and requirements:

- [Functional Detailed Specifications (FSD)](FSD.md) — user-visible behaviors,
  rules, and acceptance criteria.
- [Technical Detailed Specifications (TSD)](TSD.md) — architecture, integrations,
  data boundaries, security, validation, and the feature-extension contract.
- [Customer Deployment and Bug-Fix Guide](CUSTOMER_DEPLOYMENT.md) — dedicated
  customer deployments, support triage, customer-only versus shared fixes, and
  release/rollback procedures.

### Optional feature modules

Enable or disable modules in
[`frontend/lib/core/config/feature_config.dart`](../frontend/lib/core/config/feature_config.dart)
by changing `AppFeatures.current`. Rebuild the app after changing a flag.

| Module | Independent behavior | Dependency |
|---|---|---|
| Authentication | Email/password sign-in, registration, verification, password reset | Firebase Auth |
| Email action links | In-app email verification, recovery, and password reset | Authentication and verified Android/iOS app-link domains |
| Home | Anonymous or authenticated landing screen | None |
| Onboarding | First-run introduction | Local preferences |
| Profile | Account details and photos | Authentication, Firestore, and Firebase Storage |
| Account-data export | Share/save a JSON export of account and inbox data | Authentication and Firestore |
| Settings: appearance | Theme selection | Local preferences |
| Settings: language | Language selection | Local preferences |
| Settings: device authentication | App lock after launch/background | Authentication, Settings, and device authentication support |
| Push notifications | Firebase Cloud Messaging; foreground notifications are displayed by the platform | Firebase Messaging |
| Notification inbox | Per-user in-app security notifications with read status | Authentication and Firestore |
| Required app updates | Blocks unsupported Android/iOS versions and opens the configured store | Firebase Remote Config |
| Crash reporting | Release crash reports | Firebase |
| App Check | Debug provider for development; Play Integrity/App Attest for releases | Firebase App Check configuration |

Profile and device authentication are automatically unavailable when
Authentication is disabled. Authentication can run without Profile or
Firestore. When Authentication is disabled, Home or at least one Settings
module must remain enabled. When Authentication is enabled, Home, Profile, or
at least one Settings module must remain enabled as the post-login destination.
The app validates these combinations at startup.

For an anonymous build that does not initialize Firebase, disable
`authentication`, `crashReporting`, and `pushNotifications`, and keep Home or
a Settings module enabled. Home and local Settings then run independently of
Firebase; the Remote Config update gate is also skipped.

#### Configure required app updates

Firebase-enabled Android and iOS builds check the minimum supported version
with Firebase Remote Config at startup. If the installed version is below the
configured minimum, the app blocks navigation until the user opens the
platform's store page and updates. Configure and publish these Remote Config
parameters in the Firebase project:

| Parameter | Type | Example/default |
|---|---|---|
| `minimum_app_version` | String | `0.0.0` (no minimum; update gate disabled) |
| `android_store_url` | String | `https://play.google.com/store/apps/details?id=<android-application-id>` |
| `ios_store_url` | String | `https://apps.apple.com/app/id<app-store-id>` |

Use semantic version values such as `1.4.0` for the minimum; a prerelease
version such as `1.4.0-beta.1` is also supported. An installed version below
the minimum is blocked; the minimum itself is allowed. Configure a valid HTTPS
store URL for each platform before raising the minimum above a released
version. Release builds check Remote Config at most once per hour, so policy
changes may take up to an hour to reach an installation. Refresh failures are
logged and the last activated configuration is used, allowing cached update
requirements to work offline. If the app has never activated a Remote Config
policy, its default `0.0.0` minimum allows startup until Firebase provides the
published values.
An invalid version or missing/invalid store URL is shown as a blocking
configuration-check error with a retry action rather than allowing a
potentially unsupported app version to continue.

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
removes the current device token before ending the session; if token removal
fails, sign-out reports the error and does not proceed.

#### Enable remote push delivery

The sender is defined in `backend/functions/` and runs with the Firebase Admin SDK, so
no service-account credential is stored in the app or repository. Device
tokens and inbox entries are stored in per-user Firestore paths with
owner-scoped security rules. Deploy only the new push function to the app's Firebase project
(`whatsapp-bot-f57a8`):

```
firebase login
firebase deploy --config backend/firebase.json --only functions:sendInboxPush --project whatsapp-bot-f57a8
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
cd frontend
flutter build appbundle --dart-define=PRIVACY_POLICY_URL=https://example.com/privacy --dart-define=TERMS_OF_SERVICE_URL=https://example.com/terms --dart-define=SUPPORT_EMAIL=help@example.com
```

Replace the example destinations with the cloned app's published policy, terms,
and monitored support address. The app opens configured web links in the
browser and support through the device's email app.

Account deletion and **Sign out all devices** use authenticated callable
functions in `backend/functions/` with App Check enforcement. Both require recent
password reauthentication. Register debug tokens and set up production App
Check providers before enabling these callables.
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
firebase deploy --config backend/firebase.json --only functions:deleteAccount,functions:revokeAllSessions --project whatsapp-bot-f57a8
```

Deploy the callable functions before exposing these actions in a release build.

#### Configure iOS/APNs and release signing

1. In Apple Developer, open the App ID matching the app's bundle identifier
   (`com.yourname.skeleton`) and enable **Push Notifications** and
   **Associated Domains**. The app uses
   `applinks:whatsapp-bot-f57a8.firebaseapp.com` for Firebase email action links.
2. Create an APNs authentication key (`.p8`) with Apple Push Notifications
   enabled. In Firebase Console → Project settings → Cloud Messaging, upload the
   key with its Key ID and Team ID for the iOS Firebase app. Keep the `.p8`
   private; do not commit it or add it to Codemagic environment variables.
3. Regenerate the App Store provisioning profile after enabling both
   capabilities. It must match the bundle ID and include the `aps-environment`
   entitlement and the `com.apple.developer.associated-domains` entitlement
   authorizing `applinks:whatsapp-bot-f57a8.firebaseapp.com`. Apple profiles
   may represent this capability with the wildcard value `*`.
4. In Codemagic, update/select that profile and a matching Apple distribution
   certificate for the `ios-release` workflow. The workflow verifies that the
   profile includes both entitlements before archiving and reports which one is
   missing.

#### App Check, Firebase emulators, and rules tests

The app initializes App Check before Firebase-backed services. Debug Android
and iOS builds use Firebase's debug provider; register each printed debug token
in Firebase Console → App Check → Manage debug tokens. Release builds use
Play Integrity on Android and App Attest with DeviceCheck fallback on iOS.
Register the production apps/providers in Firebase Console and validate traffic
before enforcing App Check for Authentication, Firestore, Storage, or Functions.
Do not ship a debug token or enforce App Check before the production app has
obtained valid tokens.

The repository configures local Auth, Firestore, Functions, and Storage
emulators. Install the Functions tooling and start them from the repository
root with:

```
cd backend/functions
npm ci
npm exec firebase -- emulators:start --config ../firebase.json --only auth,firestore,functions,storage
```

For the Android emulator, set `FIREBASE_EMULATOR_HOST=10.0.2.2` with
`--dart-define`; use `localhost` for iOS simulators or desktop clients:

```
cd frontend
flutter run --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

Firestore and Storage rules tests run through the emulator suite and use a
non-production demo project:

```
cd backend/functions
npm ci
npm run test:rules
```

The tests verify owner-only Firestore access and profile-image type/ownership
restrictions. Never point rules tests at a production project. Install a
supported JDK (21 or later recommended) before starting the emulators.

#### Authentication email links

Firebase email action links are routed to the app's email-action screen for
verification, email recovery, and password reset. Android app links default to
`whatsapp-bot-f57a8.firebaseapp.com`; for a cloned Firebase project, pass
`AUTH_ACTION_HOST=<project-id>.firebaseapp.com` to the Android build
environment (or set the Gradle property `authActionHost`) and replace the
placeholder in `frontend/ios/Runner/Runner.entitlements` with the matching Firebase
domain. Use the matching Firebase Auth domain in Firebase Console and register
it as an authorized domain.
To send action links back to a custom HTTPS path, set
`--dart-define=AUTH_ACTION_CONTINUE_URL=https://<verified-domain>/auth/action`
and configure that domain's Android asset links and iOS Apple App Site
Association file for this app's package/bundle identifiers. Add this host to
the Android `authActionHost` property and iOS associated domains. Until those
domain associations are served and verified, links will continue to work in
the Firebase-hosted web handler instead of reopening the app.

#### Account data export and profile photos

Settings → Export your account data creates a JSON file containing the current
Firebase Auth account fields, the user's Firestore profile, and notification
records, then opens the platform share sheet so the user can save or share it.
FCM tokens are intentionally excluded. Profile photos can be changed or
removed from Profile; images are resized before upload and Storage rules allow
only the signed-in owner to access their JPEG/PNG/WebP image up to 5 MB.
Configure Firebase Storage and deploy `backend/storage.rules` alongside Firestore rules
when setting up a cloned project.

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
the user's Firestore notification inbox from the signed-in client; a Firestore
trigger sends the associated push notification. Open the inbox from the Home app-bar
bell. Selecting an item opens its detail and marks it as read; close on either
the inbox or detail returns Home. Existing Firestore rules must allow signed-in
users to read only their own profile and notification documents. This
inbox entry is a user-facing
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
- **Riverpod** for dependency injection and state management
- **go_router** for feature-aware navigation and authentication redirects
- **Firebase**: Core, Authentication, Firestore, Storage, Cloud Functions,
  Cloud Messaging, Remote Config, App Check, and Crashlytics
- **Local persistence and platform services**: Shared Preferences, secure
  storage, local authentication, notifications, image picker, sharing, and URL
  launching

## Project structure

```
frontend/
  android/  ios/              Native mobile projects
  lib/                         Flutter application source
    core/                      Shared app infrastructure
    features/<feature>/        Feature vertical slices
    shared/widgets/             Reusable UI components
  test/                         Unit and widget tests
  pubspec.yaml                  Flutter package manifest
  firebase.json                 FlutterFire project metadata
backend/
  firebase.json                 Firebase CLI configuration
  functions/                     Cloud Functions and rules tests
  firestore.rules                Firestore authorization boundary
  storage.rules                  Storage authorization boundary
docs/                            Setup, specifications, and operations guides
codemagic.yaml                   Root-level release workflows
```

Each feature follows the same three layers:

- `presentation/`: screens and widgets
- `application/`: Riverpod providers and controllers (state)
- `data/`: repositories and models (Firebase access lives here only)

Feature folders may omit a layer when it is not needed. Keep shared
infrastructure in `core/` only when it is genuinely used across modules;
feature-specific models, providers, and UI stay with their feature.

## Getting started

### Prerequisites

- Flutter SDK (run `flutter doctor` and fix anything red)
- Node.js and the Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### Setup

1. Clone the repo and install packages from the Flutter app directory:
   ```
   cd frontend
   flutter pub get
   ```
2. Create a Firebase project. Enable **Authentication → Email/Password** and **Authentication → Phone**, and create a **Firestore** database. Phone Auth is used to verify phone numbers during registration; login remains email/password. Configure allowed SMS regions in Firebase Authentication.
3. For Android phone auth, add the app's SHA-1 and SHA-256 signing fingerprints in Firebase Project Settings → Android app. For iOS, configure APNs for Firebase Messaging; phone auth may use APNs or a reCAPTCHA fallback.
4. Connect the app to your Firebase project from `frontend/` (this regenerates
   `frontend/lib/firebase_options.dart` and its FlutterFire metadata):
   ```
   cd frontend
   firebase login
   flutterfire configure --project=<your-project-id>
   ```
5. For a dedicated, empty project, deploy the Firestore rules from this repository:
   ```
   firebase deploy --config backend/firebase.json --only firestore:rules --project <your-project-id>
   ```
   These rules let each signed-in user access only their own profile,
   notification, and device-token data. Do not replace rules on a
   project that already hosts other services; merge the required user-scoped
   paths with its existing rules.
   Deploy Storage rules as a separate step when profile-photo storage is used:
   `firebase deploy --config backend/firebase.json --only storage --project <your-project-id>`.
6. Run the app:
   ```
   cd frontend
   flutter run
   ```

### Run the checks

```
cd frontend
flutter analyze
flutter test
```

## Codemagic CI/CD

The repository includes the root [`codemagic.yaml`](../codemagic.yaml) with separate release
workflows for Android and iOS. Both workflows install dependencies, run
analysis and tests, and build a signed release artifact.

Before running a workflow, configure these items in Codemagic:

1. Add an environment variable group named `app_secrets` containing:
   - `API_BASE_URL` (optional; leave empty if the app does not use the API)
   - `API_KEY` (optional; use a Codemagic secret variable)
   - `CM_PUBLISH_EMAIL` (the address that receives build notifications)
2. Add or select an Android keystore with the Codemagic credential/reference
   name `medsalem`. If your keystore uses a different reference, update the
   `android_signing` value in the root `codemagic.yaml` to match it exactly. The release
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
6. Update the bundle identifier in the root `codemagic.yaml` after following
   [`RENAME.md`](RENAME.md) for a new app.

The Firebase configuration files are already committed as generated by
FlutterFire. If the Firebase project changes, rerun `flutterfire configure`
locally and commit the regenerated files before triggering a release build.

### Backend workflows

Two Linux workflows cover `backend/`. Both run only when a commit changes
files under `backend/`:

- `backend-ci` runs on every push and pull request: `npm ci`, the TypeScript
  build, and the Firestore/Storage rules tests in the emulator. It needs no
  credentials.
- `backend-deploy` runs on pushes to `main`: the same checks, then
  `firebase deploy --only functions,firestore:rules,storage`.

Before the first automatic deploy:

1. In Google Cloud Console → **IAM & Admin → Service Accounts** for the
   Firebase project, create a deploy service account and grant it
   **Firebase Admin**, **Cloud Functions Admin**, **Service Account User**,
   and **Artifact Registry Administrator**. Create a JSON key for it.
2. In Codemagic, add an environment variable group named `firebase_deploy`
   containing:
   - `FIREBASE_SERVICE_ACCOUNT` (secure): the full contents of the JSON key
   - `FIREBASE_PROJECT_ID`: the Firebase project ID
   - `CM_PUBLISH_EMAIL`: the address that receives deploy notifications
3. Delete the downloaded key file from your machine; never commit it.

The project's Cloud Functions, Eventarc, and Artifact Registry APIs must
already be enabled, which is the case after one successful manual deploy.
For local deploys, `backend/.firebaserc` sets the default project, so
`npm run deploy` in `backend/functions` works without `firebase use`.

## Using the skeleton for a new project

1. Follow [RENAME.md](RENAME.md) to rename the package, app name and bundle id, and to connect a new Firebase project.
2. Add your own features by following [HOW_TO_ADD_A_FEATURE.md](HOW_TO_ADD_A_FEATURE.md).

## Rules for keeping the skeleton reusable

- Keep project-specific values in `frontend/lib/core/config/app_config.dart`
  and optional module switches in
  `frontend/lib/core/config/feature_config.dart`.
- Use relative imports inside `frontend/lib/` so renaming needs no code changes.
- Firebase data reads and writes go through repositories in `data/`. UI never
  calls Firebase directly; application providers may use Firebase Auth types at
  the integration boundary.
- Keep cross-cutting startup and routing behavior in `core/`; keep feature
  behavior within its feature module.
- For each feature, define dependencies and disabled behavior, wire routes and
  navigation consistently, localize user-facing text, and add tests for success,
  loading, error, and configuration cases that apply.
- Update Firestore/Storage rules, Cloud Functions, export/deletion paths,
  platform entitlements, and setup documentation when the feature changes
  those boundaries.
- Keep the app runnable at all times, and validate with `flutter analyze`,
  `flutter test`, and applicable Functions/rules tests.

## Roadmap

- [x] Auth, home, profile, settings
- [x] English and French localization with a Settings language picker
- [x] Unit/widget tests and Codemagic Android/iOS release workflows
- [x] Firebase emulator setup and Firestore/Storage rules tests
- [ ] GitHub Actions CI (analyze, test, build)
- [ ] Separate development and production Firebase projects with flavors

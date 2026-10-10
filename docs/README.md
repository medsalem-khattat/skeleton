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
- [Deployment Guide](DEPLOYMENT.md) — the deployment file, secrets strategy,
  step-by-step customer setup, and testing.
- [Customer Deployment and Bug-Fix Guide](CUSTOMER_DEPLOYMENT.md) — dedicated
  customer deployments, support triage, code versus configuration fixes, and
  release/rollback procedures.
- [Customer Prerequisites and Readiness Check](CUSTOMER_PREREQUISITES.md) —
  what to collect from a customer (accounts, access, app content) and how to
  validate it before a deployment starts.
- [Release, Upgrade, and Support Policy](RELEASE_AND_SUPPORT.md) — version
  numbers, upgrading every customer to each release, supported versions, and
  end of support.
- [Product Roadmap](ROADMAP.md) — current gaps and the plan for the next
  versions.

### Optional feature modules

Enable or disable modules in the `features` section of the deployment's
`deployments/<id>/deployment.json` (see [DEPLOYMENT.md](DEPLOYMENT.md)), then
run `node tool/deployment.mjs use <id>` and rebuild.

| Module | Independent behavior | Dependency |
|---|---|---|
| Authentication | Email/password sign-in, registration, verification, password reset | Firebase Auth |
| Phone verification | SMS-verified phone number at registration and in Account security | Authentication, Firebase Phone Auth (Blaze plan) |
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
owner-scoped Firestore document; tokens are stored privately. After a password
change the app calls the `recordPasswordChange` function, which writes the
inbox record (clients cannot create inbox records); a Firestore trigger then
sends the native push in the user's app language (English or French). Each
signed-in account can turn push delivery on or off
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
owner-scoped security rules.

Every deployment has its own dedicated Firebase project, owned and paid for by
the customer (see [CUSTOMER_DEPLOYMENT.md](CUSTOMER_DEPLOYMENT.md)). Because
the project hosts nothing else, deploy all Functions and both rulesets
together, always naming the project explicitly:

```
firebase login
cd backend/functions
npm run deploy -- --project <customer-project-id>
```

There is no default project in the repository, so a deploy without
`--project` fails instead of reaching the wrong customer. Cloud Functions
deployment requires the Blaze billing plan on the customer's billing account,
Node.js 22, and an account with permission to deploy Functions.

#### Configure legal/support destinations and account actions

Privacy, terms, and support destinations are set in the `links` section of
the deployment file. Blank or invalid values are not shown in Settings. The
app opens configured web links in the browser and support through the
device's email app.

Account deletion and **Sign out all devices** use authenticated callable
functions in `backend/functions/` with App Check enforcement. Both require recent
password reauthentication. Register debug tokens and set up production App
Check providers before enabling these callables.
Account deletion recursively removes `users/{uid}` and its subcollections
before deleting the Firebase Authentication user; a retry after a partial
failure is safe. The `cleanupDeletedUser` Auth trigger removes the same data
when a user is deleted outside the app, for example from the Firebase console.
If more user-owned data is added outside that path, extend `deleteUserData`
in `backend/functions/src/index.ts` before shipping it.
Session revocation uses Firebase Admin `revokeRefreshTokens`; Firebase applies
this to all refresh tokens, so the current device is signed out too. Other
devices' existing ID tokens can remain valid until they expire (up to about one
hour); they cannot renew their sessions after that. The app also removes the
account's stored FCM tokens and clears its local session. These functions are
part of the deploy above; deploy them before exposing these actions in a
release build.

#### Configure iOS/APNs and release signing

1. In the customer's Apple Developer account, open the App ID equal to the
   deployment's `appId` and enable **Push Notifications** and **Associated
   Domains**. The app uses `applinks:<firebase.authActionHost>` for Firebase
   email action links.
2. Create an APNs authentication key (`.p8`) with Apple Push Notifications
   enabled. In Firebase Console → Project settings → Cloud Messaging, upload the
   key with its Key ID and Team ID for the iOS Firebase app. Keep the `.p8`
   private; do not commit it or add it to Codemagic environment variables.
3. The `ios-release` workflow fetches or creates the App Store certificate and
   provisioning profile for `appId`, then verifies that the profile includes
   the `aps-environment` entitlement and `applinks:<firebase.authActionHost>`
   (Apple may show the wildcard `*`). It reports which one is missing. After
   enabling a capability, rerun the workflow.

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
npm exec firebase -- emulators:start --config ../firebase.json --project demo-skeleton --only auth,firestore,functions,storage
```

Run the app against them with the `example` deployment. For the Android
emulator, set `FIREBASE_EMULATOR_HOST=10.0.2.2`; use `localhost` for iOS
simulators or desktop clients:

```
node tool/deployment.mjs use example
cd frontend
flutter run --dart-define-from-file=deployment.g.json --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
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
verification, email recovery, and password reset. Android App Links and the
iOS associated domain both use the deployment's `firebase.authActionHost`
(default `<projectId>.firebaseapp.com`). Register that host as an authorized
domain in the customer's Firebase Auth settings.
To send action links back to a custom HTTPS path, set
`links.authActionContinueUrl` to `https://<verified-domain>/auth/action` and
`firebase.authActionHost` to `<verified-domain>`, and serve that domain's
Android asset links and iOS Apple App Site Association files for the
deployment's `appId`. Until those associations are verified, links keep
working in the Firebase-hosted web handler instead of reopening the app.

#### Account data export and profile photos

Settings → Export your account data creates a JSON file containing the current
Firebase Auth account fields, the user's Firestore profile, and notification
records, then opens the platform share sheet so the user can save or share it.
FCM tokens are intentionally excluded. Profile photos can be changed or
removed from Profile; images are resized before upload and Storage rules allow
only the signed-in owner to access their JPEG/PNG/WebP image up to 5 MB.
Configure Firebase Storage and deploy `backend/storage.rules` alongside Firestore rules
when setting up a cloned project.

Android/iOS Firebase configuration files are generated by FlutterFire and
kept per deployment in `deployments/<id>/firebase/` (see
[DEPLOYMENT.md](DEPLOYMENT.md)). Changing the configured Firebase
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
When `phoneVerification` is enabled, registration requires a phone number in
E.164 format (for example
`+14155552671`) and SMS verification. After the code is verified, the phone
credential is linked to the new email/password account. Users continue to sign
in with their email and password, and must still verify their email before
accessing app screens. Configure Firebase's Phone provider, allowed SMS
regions, Android SHA fingerprints, and the iOS APNs/reCAPTCHA setup before
testing with real phone numbers. Use Firebase test phone numbers during
development to avoid sending real SMS.
After a password change, the app asks the `recordPasswordChange` function to
record an in-app security notification in the user's Firestore notification
inbox; a Firestore trigger sends the associated push notification. Open the inbox from the Home app-bar
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

1. Select a deployment. `example` uses placeholder Firebase values and works
   with the local emulators; real deployments live in `deployments/<id>/`:
   ```
   node tool/deployment.mjs use example
   ```
2. Install packages and run the app with the deployment's values:
   ```
   cd frontend
   flutter pub get
   flutter run --dart-define-from-file=deployment.g.json
   ```

To create a deployment for a customer (Firebase project, app ID, secrets, CI,
backend deploy, and store releases), follow [DEPLOYMENT.md](DEPLOYMENT.md).
Each deployment has its own customer-owned Firebase project. Enable
**Authentication → Email/Password** there (plus **Authentication → Phone** when
`phoneVerification` is on), and create a **Firestore** database. Phone Auth
verifies phone numbers during registration; login remains email/password. Configure allowed SMS regions,
the Android SHA-1/SHA-256 signing fingerprints, and APNs for iOS phone auth.

### Run the checks

```
node tool/deployment.mjs use example
cd frontend
flutter analyze
flutter test
cd ../backend/functions
npm ci
npm test
npm run test:rules
```

## Codemagic CI/CD

The root [`codemagic.yaml`](../codemagic.yaml) serves every deployment:

| Workflow | Runs | Does |
| --- | --- | --- |
| `frontend-ci` | Every push/PR that changes `frontend/`, `deployments/`, or `tool/` | Checks every deployment file, then analyze and tests with `example` |
| `backend-ci` | Every push/PR that changes `backend/` | Functions build, unit tests, and rules tests in the emulator |
| `backend-deploy` | Manually, in the customer's Codemagic team | Checks the deployment and that the deploy credential belongs to its project, runs the tests, then deploys Functions and rules |
| `android-release` | Manually, in the customer's Codemagic team | Signed App Bundle, uploaded to the Play Console internal testing track |
| `ios-release` | Manually, in the customer's Codemagic team | Signed IPA, uploaded to TestFlight |

The deployment is chosen by `DEPLOYMENT_ID`. The version comes only from
`frontend/pubspec.yaml`; Codemagic supplies the build number. Environment
groups, signing identities, and the secrets strategy are described in
[DEPLOYMENT.md](DEPLOYMENT.md). If a group lacks `CM_PUBLISH_EMAIL`, Codemagic
rejects the configuration with `recipients -> 0 none is not an allowed value`.

The deploy service account in the customer's project needs **Firebase
Admin**, **Cloud Functions Admin**, **Service Account User**, and **Artifact
Registry Administrator**. The project's Cloud Functions, Eventarc, and
Artifact Registry APIs must be enabled, which is the case after one
successful deploy.

## Using the skeleton for a new project

1. Create a deployment for each customer by following
   [DEPLOYMENT.md](DEPLOYMENT.md); app name, app ID, Firebase project, links,
   color, and modules all live in its `deployment.json`.
2. Add your own features by following [HOW_TO_ADD_A_FEATURE.md](HOW_TO_ADD_A_FEATURE.md).

## Rules for keeping the skeleton reusable

- Keep deployment-specific values in `deployments/<id>/deployment.json`, never
  in code. A new value goes into that file, `tool/deployment.mjs`, and
  `frontend/lib/core/config/app_config.dart` (as a `fromEnvironment` default).
- Never put a secret in the repository, a deployment file, or a
  `--dart-define`; secrets stay in the customer's accounts.
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

Next versions (v1.1, v1.2, v2.0) are planned in [ROADMAP.md](ROADMAP.md).

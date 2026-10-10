# Technical Detailed Specifications (TSD)

## 1. Document purpose

This document describes the current technical architecture and the constraints
for extending the Flutter + Firebase skeleton. It is intended for developers
maintaining the starter or adding a product feature.

The specifications describe the checked-in implementation. Firebase Console,
Apple Developer, Google Play, App Store Connect, and Codemagic settings are
external dependencies and must be configured independently.

## 2. Technology baseline

| Concern | Current implementation |
|---|---|
| Client | Flutter / Dart, Material 3 |
| State and dependency injection | Riverpod |
| Navigation | `go_router` |
| Local preferences | `shared_preferences` |
| Sensitive local data | `flutter_secure_storage` |
| Identity/data/services | Firebase Authentication, Firestore, Storage, Cloud Functions |
| Notifications | Firebase Cloud Messaging and local notifications |
| Remote policy | Firebase Remote Config |
| Runtime protection/diagnostics | Firebase App Check and Crashlytics |
| Server | Firebase Functions v2, TypeScript, Firebase Admin SDK, Node.js 22 |
| CI/release | Codemagic Android and iOS workflows |

Use the versions pinned by `frontend/pubspec.lock` and
`backend/functions/package-lock.json`;
upgrade dependencies as a deliberate change with analysis and tests.

## 3. Architectural principles

### 3.1 Feature vertical slices

Each feature owns its relevant code under
`frontend/lib/features/<feature>/`:

- `data/`: models and repositories that interact with Firebase, platform
  services, or other external systems.
- `application/`: Riverpod providers, controllers, and state transitions.
- `presentation/`: screens and feature-specific widgets.

A feature may omit a layer that adds no value. Keep UI free of direct Firebase
data access. Use `core/` for cross-feature infrastructure only; do not move a
model or business rule into `core/` merely to make it globally visible.

### 3.2 Dependency direction

Presentation consumes application providers/controllers. Application code
coordinates use cases and should depend on repository/service abstractions.
Data implementations depend on SDKs. The current authentication provider and
repository expose Firebase Auth user/credential types at their boundary; avoid
spreading SDK types further into presentation or unrelated features.
Cross-feature dependencies should be explicit and minimal; avoid importing
another feature's presentation layer.

### 3.3 Composition and configuration

- `deployments/<id>/deployment.json` is the single source of deployment
  values. `tool/deployment.mjs use <id>` validates it and generates
  `frontend/deployment.g.json` (Dart defines), the Firebase client files,
  `frontend/android/deployment.properties` (application ID, label, App Links
  host), and `frontend/ios/Flutter/Deployment.xcconfig` (bundle ID, display
  name, associated domain). The generated files are git-ignored.
- `frontend/lib/core/config/app_config.dart` reads deployment values with
  `String.fromEnvironment`; its defaults apply only without a define file.
- `frontend/lib/core/config/feature_config.dart` reads the `FEATURE_*`
  defines and holds derived dependencies.
- `frontend/lib/main.dart` initializes required services and creates `ProviderScope`
  overrides.
- `frontend/lib/app.dart` composes root-level gates, localization, themes, and the router.
- `frontend/lib/core/router/app_router.dart` conditionally registers feature routes and wires auth,
  onboarding, and notification navigation.

Feature flags are build-time configuration, not remote authorization. Removing
a UI route does not secure backend data; Firebase rules and server functions
remain the authorization boundary.

## 4. Startup and runtime flow

1. `main()` ensures Flutter bindings are initialized.
2. It reads the compile-time feature set and validates required landing
   destinations.
3. Firebase is initialized only if a Firebase-backed feature is active.
   App Check is activated on native Android/iOS; configured local emulators are
   then attached.
4. Global Flutter/platform error handlers are connected. Crashlytics records
   fatal errors only when crash reporting is enabled in a release build.
5. The push client is initialized when push is enabled.
6. Shared Preferences is opened; services and preferences are injected through
   Riverpod overrides.
7. `App` builds `MaterialApp.router`, wrapped by the required app-update gate
   and optional device-authentication gate. `SessionGuard` is added when
   Authentication is enabled.
8. Router redirects enforce onboarding, sign-in, and email-verification
   requirements. Feature routes are included only when enabled.

The update gate is skipped when Firebase is not initialized and on targets
other than Android/iOS. Remote Config's fetch failure is logged; activated
cached values remain available. Malformed activated version values or invalid
required store URLs surface as a blocking configuration error.

## 5. Module dependency matrix

| Module | Required capabilities | Current dependency behavior |
|---|---|---|
| Authentication | Firebase Auth | Enables Firebase bootstrap; verified email required for normal authenticated routes. |
| Profile | Authentication, Firestore, Storage for photos | Automatically disabled when Authentication is off. |
| Device authentication | Authentication, Settings, platform authenticator | Automatically disabled when Authentication or Settings is off. |
| Notification inbox | Authentication, Firestore | Automatically disabled when Authentication is off. |
| Push notifications | Firebase Messaging, Firestore token storage, platform permission | Can make Firebase required independently of Authentication. |
| Remote app updates | Firebase Remote Config, package metadata | Runs only when Firebase is enabled and target is Android/iOS. |
| Crash reporting | Firebase Crashlytics | Reporting active only in release mode and when enabled. |
| Home | Flutter UI | No Firebase dependency. |
| Appearance/language | Shared Preferences | May be enabled without Authentication. |
| Account administration | Auth, callable Functions, App Check | Operations require recent password authentication; server enforces App Check. |

Update `AppFeatures` derived getters and validation tests under `frontend/test/` when adding a
dependency. Do not infer backend security from this matrix.

## 6. Navigation and authentication

- Route paths are centralized in `AppRoutes`.
- `routerProvider` registers common and feature routes conditionally.
- The indexed shell branches are added in the same order as their navigation
  destinations.
- Router refreshes are driven by Firebase auth state, auth controller state,
  and onboarding completion.
- Authentication redirects preserve validated internal destinations through
  login and email verification.
- Email action paths bypass the onboarding redirect so inbound Firebase links
  can be processed.
- Push taps are routed to a notification detail if the inbox module is enabled;
  otherwise they fall back to the authenticated landing location.

When adding a route, register it conditionally with its module and test direct
navigation and authentication redirects. Keep deep-link validation internal;
never accept arbitrary external redirect URLs.

## 7. Firebase data and services

### 7.1 Firestore layout

```text
users/{uid}
  profile fields and preferences
  notifications/{notificationId}
  fcmTokens/{token}
```

The profile document is owner-readable. The owner may write only the
app-owned fields `name`, `email`, `photoStoragePath` (inside their own profile
prefix), and `notificationsEnabled`; updates check only the changed keys, so
legacy fields survive. Server-trusted fields (roles, plans, entitlements) must
never be added to that allowlist. Clients cannot delete the profile or create
inbox records; users can mark their own notification read. Device token
documents are private and owner-managed. Unknown paths default to denied.

Each deployment has its own dedicated, customer-owned Firebase project, so
`backend/firestore.rules` and `backend/storage.rules` are deployed as the
project's complete rulesets.

### 7.2 Storage

Profile photos use user-scoped paths under `users/{uid}/profile/`; the current
repository writes uniquely named `avatar_<timestamp>.jpg` objects. Rules require
the authenticated owner and restrict upload size/content type. All paths
outside the profile subtree are denied. Account deletion removes objects under
that user's profile prefix.

### 7.3 Cloud Functions

`backend/functions/src/index.ts` contains the deployed functions; pure logic
lives in `auth.ts` (recent-authentication check) and `push.ts` (push text and
stale-token selection) and is unit-tested by `npm test`.

- `recordPasswordChange`: App Check-enforced callable requiring recent
  authentication. It writes the password-change inbox record with the
  caller's app language (`en` or `fr`, default `en`).
- `sendInboxPush`: Firestore `onDocumentCreated` trigger for
  `users/{userId}/notifications/{notificationId}`. It sends only the supported
  password-change notification type in the record's language, respects the
  user's notification preference, batches FCM sends, and removes invalid
  tokens.
- `deleteAccount`: App Check-enforced callable requiring a recent authenticated
  session. It removes the user Firestore subtree and profile Storage objects,
  then deletes the Authentication account. A retry after partial failure is
  safe.
- `cleanupDeletedUser`: Auth `onDelete` trigger that removes the same data when
  a user is deleted outside the app, such as from the Firebase console.
- `revokeAllSessions`: App Check-enforced callable requiring recent
  authentication. It removes FCM token documents and revokes refresh tokens,
  which also signs out the current device.

Inbox records are written only by trusted functions. Firebase has no
password-change trigger, so the app still reports that the change happened;
the record is a user-facing confirmation, not an authoritative audit trail.
Add future security events through trusted functions.

### 7.4 Firebase App Check and diagnostics

- Native debug builds use the Firebase debug providers; register generated
  debug tokens in Firebase Console.
- Native release builds use Play Integrity for Android and App Attest with
  DeviceCheck fallback for iOS.
- Callable account-administration functions require App Check.
- Firebase App Check enforcement for each product must be configured and
  monitored in Firebase Console; app initialization alone does not enable
  backend enforcement.
- Crashlytics reporting is limited to enabled release builds.

## 8. Configuration and secrets

- Set app name, app ID, Firebase project, links, seed color, and modules in
  `deployments/<id>/deployment.json`; keep the deployment's FlutterFire
  output in `deployments/<id>/firebase/`. See [DEPLOYMENT.md](DEPLOYMENT.md).
- Every value compiled into the app is public. Secrets (deploy credential,
  signing keys, App Store Connect key, APNs key) are created in and stay in
  the customer's accounts and Codemagic team; `tool/deployment.mjs` rejects a
  deployment folder that contains one.
- Configure `minimum_app_version`, `android_store_url`, and `ios_store_url` in
  Firebase Remote Config. Keep the minimum at `0.0.0` until store URLs are
  verified.
- Use the platform-specific settings and signing instructions in
  `README.md` in this directory.
  for email action domains, APNs, Associated Domains, and Codemagic.

Changing Firebase project IDs does not migrate identity, documents, storage
objects, or push tokens.

## 9. Feature extension procedure

1. Write the feature's functional requirements, failure behavior, and
   acceptance tests. Every feature is part of the product and is enabled per
   deployment with a module switch; there are no customer-specific modules.
2. Create `frontend/lib/features/<name>/` and add only the layers required by the
   feature.
3. Define typed models and a repository/service interface. Keep SDK details in
   its implementation and inject dependencies through providers.
4. Add application providers/controllers for state and actions. Surface
   failures as errors; do not silently convert failures into success-shaped
   defaults.
5. Add localized presentation and explicit loading, empty, data, and error
   states where relevant.
6. Add routes and navigation conditionally using the shared feature
   configuration. Validate route behavior for signed-out, unverified, and
   signed-in users as applicable.
7. Add or update feature dependency getters and configuration validation tests.
8. If persistent data is added, define schema, owner rules, indexes, migration
   requirements, export behavior, and account-deletion cleanup.
9. If the feature requires trusted work, use Cloud Functions/Admin SDK; document
   App Check, IAM, region, quotas, retries, and deployment requirements.
10. Update FSD/TSD, `docs/README.md`, and `HOW_TO_ADD_A_FEATURE.md` as affected.
11. Run analysis and targeted tests, then platform/Firebase tests relevant to
    the change.

See [HOW_TO_ADD_A_FEATURE.md](HOW_TO_ADD_A_FEATURE.md) for a small end-to-end
example.

For the operational lifecycle of dedicated customer configurations, bug
triage, customer-only/shared fixes, releases, and recovery, see
[CUSTOMER_DEPLOYMENT.md](CUSTOMER_DEPLOYMENT.md); for versions, upgrades, and
end of support, see [RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md). Each
deployment is configured by `deployments/<id>/deployment.json`; a build matrix
over module combinations is not implemented yet.

## 10. Quality and verification

### Flutter client

```text
cd frontend
flutter pub get
flutter analyze
flutter test
```

Run platform builds when native configuration, plugins, entitlements, or
release setup changes. iOS signing and App Store profile validation require
macOS/Xcode and valid Apple Developer credentials; they cannot be fully
validated by Dart tests.

### Firebase Functions and rules

```text
cd backend/functions
npm ci
npm run build
npm test
npm run test:rules
```

Rules tests use Firebase emulators and a demo project. Never direct rules tests
at production. See `docs/README.md` for emulator startup and JDK requirements.

### Test design

- Unit-test pure policy and transformation logic.
- Override providers or inject fakes in widget tests; avoid live Firebase in
  ordinary test suites.
- Cover permissions, dependency combinations, empty data, errors, retries,
  authentication state, and cleanup paths when relevant.
- Rules and callable behavior require emulator or dedicated integration tests.

## 11. Operational and design limitations

- Remote Config policy propagation is subject to the fetch interval and cached
  configuration.
- FCM delivery is best effort and platform permission/settings may prevent
  delivery.
- Apple provisioning profiles must include capabilities matching the
  entitlements declared by the app. Codemagic's preflight reports a missing
  entitlement; it cannot enable the capability or regenerate the Apple profile
  on the developer's behalf.
- Account deletion spans multiple services and cannot be assumed to be a
  transaction across Firestore, Storage, and Firebase Authentication. Failures
  are logged and returned as callable errors; operational recovery may be
  necessary.
- Firebase project changes require explicit configuration and data migration.
- Feature flags do not provide staged rollout, remote kill switches, or access
  control. Those require separate product and security design.

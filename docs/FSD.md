# Functional Detailed Specifications (FSD)

## 1. Document purpose

This document describes the user-facing behavior and functional boundaries of
the reusable Flutter + Firebase skeleton. It is a baseline for validating the
existing starter and for deciding whether a future feature belongs in the
shared foundation or in an app-specific module.

The skeleton provides common application capabilities. It does not define a
business domain, such as groceries, shopping baskets, or category-specific
workflows. Those are product features to be added to a clone.

## 2. Product scope

### 2.1 Goals

- Provide a maintainable Android/iOS foundation that can be renamed and
  connected to a Firebase project.
- Deliver common identity, profile, settings, navigation, update, and
  notification capabilities as independently configurable modules.
- Enforce user-owned data boundaries and provide a testable extension pattern.
- Keep setup, release signing, and operational requirements documented.

### 2.2 In scope

- First-run onboarding.
- Email/password account registration and login, including phone verification
  during registration and email verification before normal app access.
- Password recovery and supported Firebase email action links.
- Optional profile, home, settings, push notification, notification inbox,
  app lock, app update policy, crash reporting, and App Check modules.
- Account security actions, data export, profile photo management, and
  localized English/French interface text.
- Firebase-backed data and security rules for the included user-owned records.
- Android and iOS release workflows through Codemagic.

### 2.3 Out of scope

- Domain-specific product flows, such as grocery categories, stores, shopping
  lists, baskets, inventory, or checkout.
- A web/desktop product experience; some Flutter dependencies may support
  other targets, but the configured release workflows and major capabilities
  are mobile-oriented.
- A server-authoritative audit history of security events.
- Migration of existing users or data when changing Firebase projects.
- Guaranteed delivery of push notifications or availability of third-party
  Firebase/Apple/Google services.

## 3. Actors

| Actor | Purpose |
|---|---|
| Guest | Completes onboarding, registers, signs in, or requests password reset. |
| Signed-in user | Uses enabled app modules after satisfying email verification. |
| App owner/developer | Selects enabled modules, configures Firebase/platform services, and adds product features. |
| Release operator | Configures signing credentials and runs the Android/iOS release workflow. |

## 4. Functional requirements

### 4.1 Module configuration and navigation

| ID | Requirement |
|---|---|
| F-001 | The app owner can enable or disable supported modules per deployment through the `features` section of `deployments/<id>/deployment.json`, applied at build time. |
| F-002 | The app validates module combinations before startup and fails with a clear configuration error if there is no valid landing screen. |
| F-003 | A disabled module must not be reachable through normal navigation or a direct route. |
| F-004 | Authentication-dependent modules, including Profile, Notification Inbox, and Device Authentication, are unavailable when Authentication is disabled. |
| F-005 | The app must provide a usable landing destination: Home or an enabled Settings module for anonymous builds; Home, Profile, Notification Inbox, or enabled Settings after authentication. |
| F-006 | Navigation destinations and router branches must stay consistent when optional destinations are added or removed. |

### 4.2 Onboarding

| ID | Requirement |
|---|---|
| F-010 | A first-run user sees the localized onboarding flow before normal app routes. |
| F-011 | Completing or skipping onboarding persists completion locally. |
| F-012 | Email action links can be handled without onboarding redirect interfering with the link flow. |

### 4.3 Authentication and account lifecycle

| ID | Requirement |
|---|---|
| F-020 | A guest can register with a name, email, password, and an SMS-verified phone number. |
| F-021 | Phone numbers used for verification are expected in E.164 format. |
| F-022 | A newly registered account must verify its email before accessing authenticated app destinations. |
| F-023 | A guest can sign in with email and password, or request a password reset link. |
| F-024 | A user can resend email verification and refresh verification status in the app. |
| F-025 | Firebase email action links support verification, email recovery, and password reset through the app's action screen when the platform domain association is configured. |
| F-026 | A signed-in user can sign out. If push is enabled, the app removes the current device token before ending the session; if token removal fails, the operation reports failure and does not complete sign-out. |
| F-027 | A revoked, disabled, deleted, or expired Firebase session is checked at launch and on resume; known invalid sessions are signed out locally. Transient validation failures are logged and do not silently sign out the user. |

### 4.4 Home and profile

| ID | Requirement |
|---|---|
| F-030 | Home acts as a landing/dashboard for app-specific features and exposes navigation to enabled common modules. |
| F-031 | A signed-in user can view and update personal profile details. |
| F-032 | A user can upload, replace, load, and remove a profile photo subject to image size, format, and ownership rules. |
| F-033 | A missing Firestore profile document does not prevent profile display; available Firebase Authentication fields can be used as fallback values. |

### 4.5 Settings and account security

| ID | Requirement |
|---|---|
| F-040 | A user can select system/light/dark appearance and system/English/French language when those modules are enabled. Preferences persist locally. |
| F-041 | A user can enable device authentication where supported. When enabled, the app locks on launch and after returning from the background beyond the configured grace period. |
| F-042 | A user can change a password after reauthenticating with the current password. |
| F-043 | A user can request an email change after reauthentication; the new address is not active until Firebase confirms the verification link. |
| F-044 | A user can update a mobile number after SMS verification and current-password reauthentication. |
| F-045 | A user can request account deletion or sign-out from all refresh-token sessions. Both actions require recent authentication and server-side App Check. Session revocation also invalidates the current device session. |
| F-046 | A user can export account, profile, and notification data as a JSON file through the platform share sheet. Device push tokens are excluded. |
| F-047 | Configured privacy-policy and terms URLs, and a configured support email, are shown as external actions. Missing or invalid values are not presented as real destinations. |

### 4.6 Push notifications and inbox

| ID | Requirement |
|---|---|
| F-050 | Push permission is requested from Settings rather than at app startup. |
| F-051 | A signed-in device with permission and enabled preferences can register an FCM token under that user's private Firestore path. |
| F-052 | A user can enable or disable push delivery through their notification preference. |
| F-053 | A password change performed through the app is recorded in the user's inbox by a trusted Cloud Function; clients cannot create inbox records. A Cloud Function trigger sends a push in the user's app language (English or French) to eligible registered devices and removes invalid tokens. |
| F-054 | The inbox lists a bounded set of the user's newest notifications. Opening an item marks it read and displays its detail. |
| F-055 | Opening a push routes to the matching inbox item when the inbox module is enabled. If the user is signed out, login and email verification occur before the requested notification destination is restored. |
| F-056 | A push notification is not guaranteed to arrive. The inbox record is the in-app confirmation; the current implementation is not a security audit log. Password changes performed outside this app are not recorded. |

### 4.7 Required app updates

| ID | Requirement |
|---|---|
| F-060 | Firebase-enabled Android/iOS builds fetch a minimum supported app version from Firebase Remote Config during startup. |
| F-061 | An installed version below the configured minimum is blocked from normal navigation and shown an action to open the platform store. |
| F-062 | A version equal to or above the configured minimum continues normally. |
| F-063 | If the minimum is not activated, the default minimum `0.0.0` does not block the app. |
| F-064 | Invalid version or required store URL configuration is shown as a blocking check error with retry; a refresh failure is logged and the last activated configuration is used. |
| F-065 | Release builds limit Remote Config fetches to at most once per hour; policy updates may not be immediate on devices with an activated cache. |

### 4.8 Localization and errors

| ID | Requirement |
|---|---|
| F-070 | User-facing text is localized through Flutter localization resources. English and French are currently supported. |
| F-071 | Recoverable failures show an appropriate user-facing error and, where practical, a retry action. Technical details are logged without displaying raw stack traces to users. |
| F-072 | Error paths must not report success after an operation fails. |

## 5. Data and authorization requirements

- A signed-in user may access only their own `users/{uid}` profile, notification,
  and device-token records.
- No catch-all Firestore or Storage rule may grant access to unrecognized paths.
- Profile images are limited to 5 MiB and supported image content types by
  Storage rules; application-side image processing may further constrain data.
- Server-only actions use callable Cloud Functions and Admin SDK credentials
  that are not embedded in the mobile app.
- Account deletion removes the user's Firestore subtree, profile storage
  objects, and Firebase Authentication record.
- Data export must not include FCM registration tokens or credentials.

## 6. Non-functional requirements

| Area | Requirement |
|---|---|
| Maintainability | New product features should be isolated as vertical slices with explicit dependencies and ownership. |
| Reliability | Async screens must represent loading, success, and error states. Retry is offered where a safe retry is possible. |
| Security | Enforce authorization in Firebase rules and trusted server functions, not only in UI visibility or client checks. |
| Privacy | Collect/store only fields required by an enabled capability; keep tokens private and exclude them from export. |
| Accessibility | Use platform semantic controls, readable text, and localized labels for interactive controls. |
| Testability | Logic should be testable without live Firebase by injecting or overriding repositories/services. |
| Portability | Avoid project-specific identifiers in feature logic; keep renameable identity and Firebase configuration at explicit configuration boundaries. |
| Operations | Signing, App Check, Firebase providers, Remote Config values, and release requirements must be documented before enabling production behavior. |

## 7. Acceptance checklist for a new feature

1. A user story and observable acceptance criteria exist.
2. The feature's authentication, Firebase, permission, and platform dependencies
   are explicit.
3. Enabled and disabled behavior is defined, including startup/landing behavior.
4. Success, empty, loading, error, and retry states are implemented as
   applicable.
5. User-facing text is localized.
6. Authorization rules and any server-side behavior are reviewed.
7. Unit/widget tests cover the feature's important behavior and dependency
   combinations.
8. The feature guide and relevant operational documentation are updated.
9. From `frontend/`, `flutter analyze` and `flutter test` pass; any impacted
   Firebase/Functions tests pass from `backend/functions/`.

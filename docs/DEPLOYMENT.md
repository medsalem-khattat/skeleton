# Deployment Guide

Every deployment is described by **one file**, `deployment.json`, plus two
public Firebase files. One command checks it and switches the app to it, and
the same `codemagic.yaml` builds every deployment. Customers own every secret
and all user data; deployment folders hold only public values.

Before a customer deployment starts, collect and validate its prerequisites:
[CUSTOMER_PREREQUISITES.md](CUSTOMER_PREREQUISITES.md). For contracts,
support, and bug-fix policy, see
[CUSTOMER_DEPLOYMENT.md](CUSTOMER_DEPLOYMENT.md). For upgrading deployments to
a new version and end of support, see
[RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md).

## 1. What a deployment is

| Piece | Where it lives | Owner |
| --- | --- | --- |
| Deployment folder (`deployment.json` and two public Firebase files) | Ours: `deployments/<id>/` in this repository. A customer's: its own private repository `deployment-<customer-id>`, fetched into `deployments/<id>/` at build time | Us (public values only) |
| Firebase project: Auth users, Firestore data, Storage files, billing | Customer's Google account | Customer |
| Apple Developer account, App Store listing, signing certificates | Customer's Apple account | Customer |
| Google Play listing, upload keystore | Customer's Play Console and Codemagic team | Customer |
| Build secrets and the deploy credential | Customer's Codemagic team | Customer |

A customer's deployment folder is never committed here: this repository is
cloned by every customer's Codemagic team, and no customer may see another
customer's deployment. `.gitignore` ignores every folder in `deployments/`
except ours.

### Our three environments

Besides customer deployments, we always run three environments of our own.
Each is a deployment with its own Firebase project, owned and paid for by us,
in our own Google, Apple, Google Play, and Codemagic accounts.

| Deployment | Used by | Built from | Modules | Distribution |
| --- | --- | --- | --- | --- |
| `dev` | Developers | Any commit (`"internal": true`) | What is being developed | Debug builds, Play internal track, TestFlight internal |
| `test` | QA team | The release candidate on `main` before it is tagged, and fixes (`"internal": true`) | Same as the deployment under test | Play internal track, TestFlight internal |
| `demo` | Sales, and any customer or prospect | **Only the latest release tag** (not internal) | **All modules on** | Play open or closed testing, TestFlight public link |

- `demo` shows exactly what customers get, so `release-check` applies to it
  as to a customer. Its data is synthetic: demo accounts only, reset when
  needed. Never put real customer data in it.
- On `test`, QA signs off a release candidate before it is tagged
  ([RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md) §3).
- All modules on means `demo` needs Firebase phone sign-in, so its project
  is on the Blaze plan.

The repository also has `example`: placeholder Firebase values
(`demo-skeleton`) for tests, CI, and local runs against the Firebase
emulators. It never reaches a real backend.

Current state: `dev` still uses the shared `whatsapp-bot-f57a8` project, and
`demo` does not exist yet ([ROADMAP.md](ROADMAP.md) v1.1).

## 2. The deployment file

```json
{
  "deploymentId": "acme",
  "appName": "Acme",
  "appId": "com.ourcompany.acme",
  "firebase": {
    "projectId": "acme-prod",
    "authActionHost": "acme-prod.firebaseapp.com",
    "functionsRegion": "europe-west1"
  },
  "links": {
    "privacyPolicyUrl": "https://acme.example/privacy",
    "termsOfServiceUrl": "https://acme.example/terms",
    "supportEmail": "support@acme.example",
    "authActionContinueUrl": ""
  },
  "api": { "baseUrl": "" },
  "seedColor": "#3F51B5",
  "features": {
    "authentication": true,
    "phoneVerification": true,
    "home": true,
    "profile": true,
    "settings": true,
    "appearanceSettings": true,
    "languageSettings": true,
    "deviceAuthentication": true,
    "pushNotifications": true,
    "notificationInbox": true,
    "crashReporting": true
  }
}
```

| Field | Required | Used for |
| --- | --- | --- |
| `deploymentId` | Yes | Must equal the folder name. Lowercase letters, digits, `-`. |
| `internal` | No | `true` only for `dev`, `test`, and `example`, which may be built from any commit. Customer deployments and `demo` leave it out: their release workflows run only on the release tag. Default `false`. |
| `appName` | Yes | Home-screen name on Android and iOS, and the in-app title. 1-30 characters. |
| `appId` | Yes | Android application ID **and** iOS bundle ID. Chosen by us, permanent after the first store release. |
| `firebase.projectId` | Yes | The customer's Firebase project. Backend deploys go only here. |
| `firebase.authActionHost` | No | Host for email action links (Android App Links, iOS Associated Domains). Defaults to `<projectId>.firebaseapp.com`. |
| `firebase.functionsRegion` | No | Region of the Cloud Functions, used by the backend deploy and the app's callable calls. Default `us-central1`. |
| `links.*` | No | Privacy policy, terms, support email, and a custom email-action URL. Empty values are hidden in the app. |
| `api.baseUrl` | No | Optional REST API used by `core/network/api_client.dart`. |
| `seedColor` | No | Material 3 color seed, `#RRGGBB`. Default `#3F51B5`. |
| `features.*` | No | Module switches; missing ones default to `true`. Invalid combinations are rejected. `phoneVerification: false` registers with email only (phone sign-in needs the Firebase Blaze plan). |

The `firebase/` folder next to it holds the two files that the Firebase
console offers when an app is registered: `google-services.json` (Android)
and `GoogleService-Info.plist` (iOS). `use` generates
`frontend/lib/firebase_options.dart` and FlutterFire's `frontend/firebase.json`
from them, so the FlutterFire CLI is not needed. They identify the app to
Firebase and ship inside the app, so they are public; they are not secrets.

## 3. Secrets and sensitive data

**Rule: every secret is created in the customer's own accounts and goes
straight into the customer's Codemagic team** (the APNs key: straight into
the customer's Firebase project). It is never sent by email, chat, ticket, or
shared folder, and we never keep a copy. Codemagic hides a secret once it is
saved. Deployment folders hold no secret, and `tool/deployment.mjs` stops if
it finds a private key, a service-account key, or a keystore, profile, or
certificate file in one. `.gitignore` blocks the same files.

| Secret or sensitive data | Created in | Stored in | Used by |
| --- | --- | --- | --- |
| End-user data (accounts, profiles, photos, notifications, tokens) | The app | Customer's Firebase project only | The app and the Cloud Functions |
| Firebase deploy credential (`FIREBASE_SERVICE_ACCOUNT`) | Customer's Google Cloud project | Customer's Codemagic team, group `firebase_deploy` | `backend-deploy`, `readiness-check` |
| Android upload keystore + passwords | A terminal (`keytool`), then deleted or kept in the customer's password manager | Customer's Codemagic team, reference `upload_keystore` | `android-release`, `readiness-check` |
| Android app-signing key | Google Play App Signing | Customer's Play Console | Google Play |
| Google Play upload credential (`GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`) | Customer's Google Cloud project, granted access in the customer's Play Console | Customer's Codemagic team, group `google_play` | `android-release`, `readiness-check` |
| App Store Connect API key | Customer's App Store Connect | Customer's Codemagic team, group `ios_signing` | `ios-release`, `readiness-check` |
| iOS distribution certificate private key (`CERTIFICATE_PRIVATE_KEY`) | A terminal (`ssh-keygen`), then deleted | Customer's Codemagic team, group `ios_signing` | `ios-release`, `readiness-check` |
| APNs authentication key (`.p8`) | Customer's Apple account | Uploaded directly to the customer's Firebase project | Firebase Cloud Messaging |
| Deployment repository deploy key (`DEPLOYMENT_REPO_SSH_KEY`) | Us, read-only on `deployment-<customer-id>` | Customer's Codemagic team, group `deployment` | `tool/deployment.mjs fetch` |

Practices:

- **A downloaded secret lives only minutes.** Paste or upload it into
  Codemagic, then delete the file. The only copies kept outside Codemagic are
  the customer's own, in the customer's password manager.
- **Least privilege.** The deploy service account gets only Firebase Admin,
  Cloud Functions Admin, Service Account User, and Artifact Registry
  Administrator. Our people get the narrowest roles that let them work; the
  customer stays Owner everywhere.
- **No production data outside production.** Test with synthetic accounts in
  `example` (emulators) or a customer staging project. Never copy production
  data to another project or machine.
- **Values compiled into the app are public.** Everything in
  `deployment.json`, the Firebase client files, and `API_KEY` can be read
  from the app binary. `API_KEY` only identifies the app to an API; it must
  not grant privileged access.
- **Offboarding.** When support ends, the customer removes our IAM roles and
  our memberships, and rotates the deploy key. We delete the read-only
  deploy keys of the customer's Codemagic team. Nothing else needs to be
  deleted on our side, because we hold no copies.

## 4. Deploy a new customer

Build a new customer from the latest release tag
([RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md)).

**Do not start until the readiness check has passed.** The customer prepares
their accounts with the step-by-step guides in
[customer-setup/](customer-setup/README.md), choosing per platform to give us
access (Option A) or to do the setup themselves (Option B). We validate
everything as described in
[CUSTOMER_PREREQUISITES.md](CUSTOMER_PREREQUISITES.md).

### Step 1: Accounts and access (readiness check)

At the end of the readiness check:

- the customer's Codemagic team exists, we are Admin, and every secret is in
  it (groups below);
- the Firebase project exists on Blaze, with the two apps registered;
- the Apple App ID (Push Notifications, Associated Domains) and App Store
  Connect app exist, and the APNs key is in Firebase;
- the Play Console app exists, with the publishing service account invited;
- the `readiness-check` workflow passes.

| Group | Variables |
| --- | --- |
| `deployment` | `DEPLOYMENT_ID` = `<id>`, `DEPLOYMENT_REPO` = SSH URL of `deployment-<customer-id>`, `DEPLOYMENT_REPO_SSH_KEY` (secure), `CM_PUBLISH_EMAIL` = address for build emails, optional `API_KEY` |
| `firebase_deploy` | `FIREBASE_SERVICE_ACCOUNT` (secure) |
| `ios_signing` | `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_PRIVATE_KEY`, `CERTIFICATE_PRIVATE_KEY` (all secure) |
| `google_play` | `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` (secure) |

Plus the Android keystore under **Code signing identities** with the
reference name `upload_keystore`.

### Step 2: The customer's deployment repository

Done during the readiness check
([CUSTOMER_PREREQUISITES.md](CUSTOMER_PREREQUISITES.md) §4):

1. Create the private repository `deployment-<customer-id>` with
   `deployment.json` (start from `deployments/example/deployment.json`
   without `internal`) and the two Firebase files in `firebase/`.
2. Check it locally, cloned into `deployments/<id>/` (git-ignored here):

   ```sh
   node tool/deployment.mjs check <id>
   ```

A configuration change for the customer is a commit to that repository,
followed by a rebuild on the customer's current tag
([RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md) §6).

### Step 3: Deploy the backend

Run the `backend-deploy` workflow in the customer's Codemagic team, on the
release tag. It fetches the deployment, checks it, and refuses to run unless
the service account belongs to `firebase.projectId` and the build is on the
release tag. It then runs the backend tests and deploys the Cloud Functions,
Firestore rules, and Storage rules.

Locally, signed in with an account the customer granted access to, and with
the deployment folder in place:

```sh
node tool/deployment.mjs deploy-backend <id>
```

Then, in the customer's Firebase console (Option A, or the customer with
[guide 2, Part 3](customer-setup/2-google-cloud-firebase.md#part-3-after-the-first-store-release-option-b-only)
in Option B), set the Remote Config values (`minimum_app_version`,
`android_store_url`, `ios_store_url`), register the App Check providers, and
authorize `firebase.authActionHost` for Auth when it is a custom domain.

### Step 4: Release the apps

Run `android-release` and `ios-release` in the customer's Codemagic team, on
the release tag. Both fetch and select the deployment, run analysis and
tests, and build with `--dart-define-from-file=deployment.g.json`. The
version comes from `frontend/pubspec.yaml`, and the build number from
Codemagic. iOS signing files are created on the first `ios-release` run.

`android-release` uploads the App Bundle to the Play Console **internal
testing** track, and `ios-release` uploads the IPA to TestFlight for internal
testers. Neither goes further on its own: for external TestFlight testers,
submit the build for beta review in App Store Connect; for wider Play testing
or production, promote the release in the Play Console.

Play accepts API uploads only for an app that already has one bundle: the
first `android-release` run's publishing step fails, and its `.aab` is
uploaded by hand ([guide 4, Part 3](customer-setup/4-google-play.md#part-3-first-upload-everyone-about-10-minutes)).
While the app has never been published, Play accepts only draft releases:
add `submit_as_draft: true` under `google_play` in `codemagic.yaml` until the
first release is rolled out.

## 5. Test

| What | How |
| --- | --- |
| Deployment files | `node tool/deployment.mjs check <id>`, or `list` to check all. CI checks every deployment in this repository on each push. |
| A customer's accounts and secrets | The `readiness-check` workflow in the customer's Codemagic team |
| App logic | `node tool/deployment.mjs use example`, then `cd frontend && flutter analyze && flutter test` |
| Backend logic and rules | `cd backend/functions && npm ci && npm test && npm run test:rules` |
| Full app without a real backend | Start the emulators (`cd backend/functions && npm exec firebase -- emulators:start --config ../firebase.json --project demo-skeleton --only auth,firestore,functions,storage`), then `node tool/deployment.mjs use example` and `cd frontend && flutter run --dart-define-from-file=deployment.g.json --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2` (`localhost` for iOS simulators) |
| A release candidate | The `test` deployment, by the QA team, before the release is tagged |
| A customer's real setup | A customer staging project as its own deployment (for example `acme-staging`), with synthetic accounts only, before `acme-prod` |

## 6. Command reference

Run from the repository root:

| Command | Does |
| --- | --- |
| `node tool/deployment.mjs list` | Lists the deployments in `deployments/` and whether each one is valid |
| `node tool/deployment.mjs check <id>` | Validates the file, the Firebase files, and the secret scan |
| `node tool/deployment.mjs fetch <id>` | With `DEPLOYMENT_REPO` (and `DEPLOYMENT_REPO_SSH_KEY`), clones the customer's deployment repository into `deployments/<id>/` and checks it. Without it, confirms the deployment is one of ours |
| `node tool/deployment.mjs use <id>` | Checks, then writes the app's generated files (`frontend/deployment.g.json`, Firebase files and options, Android `deployment.properties`, iOS `Deployment.xcconfig`) |
| `node tool/deployment.mjs deploy-backend <id>` | Checks, runs `release-check`, then deploys Functions and rules to `firebase.projectId` |
| `node tool/deployment.mjs release-check <id>` | For a customer deployment, stops unless the commit has the tag `v<version>` of `frontend/pubspec.yaml` and no uncommitted changes. Internal deployments pass |

The generated files are git-ignored. Switch deployments by running `use`
again; never edit the generated files.

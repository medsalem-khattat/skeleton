# Deployment Guide

Every deployment is described by **one file**,
`deployments/<id>/deployment.json`. One command checks it and switches the
app to it, and the same `codemagic.yaml` builds every deployment. Customers
own every secret and all user data; this repository holds only public values.

For contracts, support, and bug-fix policy, see
[CUSTOMER_DEPLOYMENT.md](CUSTOMER_DEPLOYMENT.md). For upgrading deployments to
a new version and end of support, see
[RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md).

## 1. What a deployment is

| Piece | Where it lives | Owner |
| --- | --- | --- |
| Deployment file (`deployment.json`) | `deployments/<id>/` in this repository | Us (public values only) |
| Public Firebase client files | `deployments/<id>/firebase/` in this repository | Us (generated from the customer's project) |
| Firebase project: Auth users, Firestore data, Storage files, billing | Customer's Google account | Customer |
| Apple Developer account, App Store listing, signing certificates | Customer's Apple account | Customer |
| Google Play listing, upload keystore | Customer's Play Console and Codemagic team | Customer |
| Build secrets and the deploy credential | Customer's Codemagic team | Customer |

The repository includes three deployments:

- `example`: placeholder Firebase values (`demo-skeleton`). Use it for tests,
  CI, and local runs against the Firebase emulators. It never reaches a real
  backend.
- `dev`: our development deployment (`whatsapp-bot-f57a8`).
- `test`: our test deployment (`medsalem-skeleton-test`), the first wave of
  every release rollout; phone verification is off.

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
| `appName` | Yes | Home-screen name on Android and iOS, and the in-app title. 1-30 characters. |
| `appId` | Yes | Android application ID **and** iOS bundle ID. Chosen by us, permanent after the first store release. |
| `firebase.projectId` | Yes | The customer's Firebase project. Backend deploys go only here. |
| `firebase.authActionHost` | No | Host for email action links (Android App Links, iOS Associated Domains). Defaults to `<projectId>.firebaseapp.com`. |
| `firebase.functionsRegion` | No | Region of the Cloud Functions, used by the backend deploy and the app's callable calls. Default `us-central1`. |
| `links.*` | No | Privacy policy, terms, support email, and a custom email-action URL. Empty values are hidden in the app. |
| `api.baseUrl` | No | Optional REST API used by `core/network/api_client.dart`. |
| `seedColor` | No | Material 3 color seed, `#RRGGBB`. Default `#3F51B5`. |
| `features.*` | No | Module switches; missing ones default to `true`. Invalid combinations are rejected. `phoneVerification: false` registers with email only (phone sign-in needs the Firebase Blaze plan). |

The `firebase/` folder next to it holds the four files that
`flutterfire configure` generates for the customer's project:
`firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`,
and `firebase.json`. They identify the app to Firebase and ship inside the
app, so they are public; they are not secrets.

## 3. Secrets and sensitive data

**Rule: every secret is created in, and stays in, the customer's own
accounts.** We use secrets through access the customer grants; we never keep a
copy. The repository holds no secret, and `tool/deployment.mjs` stops if it
finds a private key, a service-account key, or a keystore, profile, or
certificate file in a deployment folder. `.gitignore` blocks the same files.

| Secret or sensitive data | Created in | Stored in | Used by |
| --- | --- | --- | --- |
| End-user data (accounts, profiles, photos, notifications, tokens) | The app | Customer's Firebase project only | The app and the Cloud Functions |
| Firebase deploy credential (`FIREBASE_SERVICE_ACCOUNT`) | Customer's Google Cloud project | Customer's Codemagic team, group `firebase_deploy` | `backend-deploy` |
| Android upload keystore + passwords | Customer's Codemagic team (generated or uploaded there) | Customer's Codemagic team, reference `upload_keystore` | `android-release` |
| Android app-signing key | Google Play App Signing | Customer's Play Console | Google Play |
| Google Play upload credential (`GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`) | Customer's Google Cloud project, granted access in the customer's Play Console | Customer's Codemagic team, group `google_play` | `android-release` (upload to the internal testing track) |
| App Store Connect API key | Customer's App Store Connect | Customer's Codemagic team, group `ios_signing` | `ios-release` (signing and TestFlight upload) |
| iOS distribution certificate private key (`CERTIFICATE_PRIVATE_KEY`) | Customer's Codemagic team | Customer's Codemagic team, group `ios_signing` | `ios-release` |
| APNs authentication key (`.p8`) | Customer's Apple account | Uploaded directly to the customer's Firebase project | Firebase Cloud Messaging |

Practices:

- **Never download a secret to a personal machine.** Create keys in the
  customer's console and paste them straight into the customer's Codemagic
  team as secure variables. If a file must be downloaded (a JSON key, a
  `.p8`), delete it right after uploading it.
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
  Codemagic membership and rotates the deploy key. Nothing needs to be
  deleted on our side, because we hold no copies.

## 4. Deploy a new customer

Build a new customer from the latest release tag
([RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md)).

### Step 1: Customer accounts (customer owns them, we help set them up)

1. **Google account and billing.** The customer provides a Google account or
   Google Cloud organization and a Cloud Billing account with their own
   payment method (Firebase Blaze plan). Suggest a budget alert.
2. **Firebase project.** Create it under the customer's account (project ID
   such as `<customer-id>-prod`), link the customer's billing account, and
   have the customer grant us Firebase Admin.
3. **Apple Developer** and **Google Play Console** accounts in the customer's
   name, with us invited as members.
4. **Codemagic team** owned by the customer, with us invited as members, and
   this repository added as an application.

### Step 2: Choose the identity and create the deployment file

1. Choose the app ID: `<our-reverse-domain>.<customer-id>`. It is the same for
   Android and iOS and permanent after the first release.
2. In the customer's Firebase project, register the Android and iOS apps with
   that ID and enable Authentication (Email/Password, and Phone when
   `phoneVerification` is on), Firestore, Storage, and Remote Config.
3. Generate the public Firebase files, then move them into the deployment
   folder (the app locations are git-ignored and rewritten by `use`):

   ```sh
   cd frontend
   flutterfire configure --project=<customer-project-id> \
     --platforms=android,ios \
     --android-package-name=<app-id> --ios-bundle-id=<app-id> --yes
   mkdir -p ../deployments/<id>/firebase
   cp lib/firebase_options.dart android/app/google-services.json \
     ios/Runner/GoogleService-Info.plist firebase.json \
     ../deployments/<id>/firebase/
   cd .. && git status   # only deployments/<id>/ should be new
   ```

4. Copy `deployments/example/deployment.json` to `deployments/<id>/` and fill
   it in.
5. Check it:

   ```sh
   node tool/deployment.mjs check <id>
   ```

6. Commit `deployments/<id>/`.

### Step 3: Customer's Codemagic team

Create these environment groups in the **customer's** team:

| Group | Variables |
| --- | --- |
| `deployment` | `DEPLOYMENT_ID` = `<id>`, `CM_PUBLISH_EMAIL` = address for build emails, optional `API_KEY` |
| `firebase_deploy` | `FIREBASE_SERVICE_ACCOUNT` (secure): JSON key of the deploy service account, created in the customer's Google Cloud console |
| `ios_signing` | `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_PRIVATE_KEY`, `CERTIFICATE_PRIVATE_KEY` (all secure) |
| `google_play` | `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` (secure): JSON key of a service account invited in the customer's Play Console with release permissions for the app |

Under **Code signing identities**, add the Android upload keystore with the
reference name `upload_keystore`. `CERTIFICATE_PRIVATE_KEY` is an RSA private
key generated for this customer (`ssh-keygen -t rsa -b 2048 -m PEM -f key -q -N ""`).
Paste it and delete the local file.

### Step 4: Apple capabilities and APNs

1. In the customer's Apple Developer account, register the App ID `<app-id>`
   and enable **Push Notifications** and **Associated Domains**.
2. Create an APNs key and upload it in the customer's Firebase console
   (Project settings → Cloud Messaging). Delete the local `.p8`.
3. Signing files are created automatically on the first `ios-release` run.

### Step 5: Deploy the backend

Run the `backend-deploy` workflow in the customer's Codemagic team. It checks
the deployment and refuses to run unless the service account belongs to
`firebase.projectId`. It then runs the backend tests and deploys the Cloud
Functions, Firestore rules, and Storage rules.

Locally, signed in with an account the customer granted access to:

```sh
node tool/deployment.mjs deploy-backend <id>
```

Then, in the customer's Firebase console, set the Remote Config values
(`minimum_app_version`, `android_store_url`, `ios_store_url`), register the
App Check providers, and authorize `firebase.authActionHost` for Auth.

### Step 6: Release the apps

Run `android-release` and `ios-release` in the customer's Codemagic team, on
the release tag. Both
select the deployment, run analysis and tests, and build with
`--dart-define-from-file=deployment.g.json`. The version comes from
`frontend/pubspec.yaml`, and the build number from Codemagic.

`android-release` uploads the App Bundle to the Play Console **internal
testing** track, and `ios-release` uploads the IPA to TestFlight for internal
testers. Neither goes further on its own: for external TestFlight testers,
submit the build for beta review in App Store Connect; for wider Play testing
or production, promote the release in the Play Console. Before the first
Android upload:

1. In the customer's Play Console, create the app and upload the first App
   Bundle by hand: Play accepts API uploads only for an app that already has
   one. Take the `.aab` from the artifacts of an `android-release` run; that
   run's publishing step fails until this is done.
2. In the customer's Google Cloud project, enable the Google Play Android
   Developer API, then create a service account and a JSON key.
3. In the Play Console (Users and permissions), invite the service account's
   email with release permissions for the app. Paste the JSON key into the
   `google_play` group and delete the local file.

While the app has never been published, Play accepts only draft releases:
add `submit_as_draft: true` under `google_play` in `codemagic.yaml` until the
first release is rolled out.

## 5. Test

| What | How |
| --- | --- |
| Deployment files | `node tool/deployment.mjs check <id>`, or `list` to check all. CI checks every deployment on each push. |
| App logic | `node tool/deployment.mjs use example`, then `cd frontend && flutter analyze && flutter test` |
| Backend logic and rules | `cd backend/functions && npm ci && npm test && npm run test:rules` |
| Full app without a real backend | Start the emulators (`cd backend/functions && npm exec firebase -- emulators:start --config ../firebase.json --project demo-skeleton --only auth,firestore,functions,storage`), then `node tool/deployment.mjs use example` and `cd frontend && flutter run --dart-define-from-file=deployment.g.json --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2` (`localhost` for iOS simulators) |
| A customer's real setup | A customer staging project as its own deployment (for example `acme-staging`), with synthetic accounts only, before `acme-prod` |

## 6. Command reference

Run from the repository root:

| Command | Does |
| --- | --- |
| `node tool/deployment.mjs list` | Lists deployments and whether each one is valid |
| `node tool/deployment.mjs check <id>` | Validates the file, the Firebase files, and the secret scan |
| `node tool/deployment.mjs use <id>` | Checks, then writes the app's generated files (`frontend/deployment.g.json`, Firebase files, Android `deployment.properties`, iOS `Deployment.xcconfig`) |
| `node tool/deployment.mjs deploy-backend <id>` | Checks, then deploys Functions and rules to `firebase.projectId` |

The generated files are git-ignored. Switch deployments by running `use`
again; never edit the generated files.

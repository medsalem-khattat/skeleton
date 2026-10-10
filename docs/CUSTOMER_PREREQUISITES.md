# Customer Prerequisites and Readiness Check

This guide is for the deployment team. A customer deployment
([DEPLOYMENT.md](DEPLOYMENT.md) §4) **does not start** until everything in
this guide has been collected from the customer and validated (§5). This
avoids starting work that then stops for weeks on a missing account or an
access request.

Every account below belongs to the customer: Google Cloud and Firebase,
Apple, Google Play, and Codemagic. The customer pays for them and stays their
owner. We only get access, and the customer can remove that access at any
time.

The customer follows the step-by-step guides in
[customer-setup/](customer-setup/README.md). Send them that link, with the
values listed there, when the contract is signed.

## 1. Two options per platform

For Google Cloud and Firebase, Apple, and Google Play, the customer chooses,
per platform:

| | Option A: give us access | Option B: the customer does the setup |
| --- | --- | --- |
| Customer | Creates and pays for the account, invites our team | Follows the guide's Part 2B |
| Us | Do the whole setup in the customer's account | Check screenshots and the readiness check workflow |
| How we validate | Signed in with our own account | Screenshots and the `readiness-check` workflow (§5) |

**Codemagic is required in both options**: the customer creates the team and
invites us as Admin, because we run the builds there.

**Secrets in both options.** Whoever creates a secret pastes or uploads it
straight into the customer's Codemagic team; the Apple push key goes straight
into the customer's Firebase project. Secrets are never sent by email, chat,
ticket, or shared folder, to us or to anyone. Codemagic hides a secret once
it is saved, so even as Admin we cannot read it. If a customer sends us a
secret by mistake, delete it, tell the customer, and have it replaced.

| Secret | Created in | Goes to | Guide |
| --- | --- | --- | --- |
| Firebase deploy key | Customer's Google Cloud project | Codemagic `firebase_deploy` / `FIREBASE_SERVICE_ACCOUNT` | [2](customer-setup/2-google-cloud-firebase.md), Part 2B Step 7 |
| APNs push key (`.p8`) | Customer's Apple account | Customer's Firebase project (Cloud Messaging) | [3](customer-setup/3-apple.md), Part 2B Step 3 |
| App Store Connect API key | Customer's App Store Connect | Codemagic `ios_signing` (three variables) | [3](customer-setup/3-apple.md), Part 2B Step 4 |
| Certificate private key | A terminal, by whoever sets up Apple | Codemagic `ios_signing` / `CERTIFICATE_PRIVATE_KEY` | [3](customer-setup/3-apple.md), Part 2B Step 5 |
| Google Play publishing key | Customer's Google Cloud project | Codemagic `google_play` / `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | [4](customer-setup/4-google-play.md), Part 2B Step 3 |
| Android upload keystore | A terminal, by whoever sets up Play | Codemagic code signing identity `upload_keystore` | [4](customer-setup/4-google-play.md), Part 2B Step 5 |
| Deployment repository key | Us | Codemagic `deployment` / `DEPLOYMENT_REPO_SSH_KEY` | §4 |

## 2. Start early: lead times

| Item | Typical delay | Why |
| --- | --- | --- |
| Apple Developer Program, organization membership | 1–3 weeks | Apple checks the organization; it needs a D-U-N-S number, which can itself take days to obtain |
| Google Play Console, organization account | Several days | Google verifies the organization's identity |
| Google Play Console, **personal** account | Do not use | New personal accounts must run a closed test with at least 12 testers for 14 days before they can publish to production. Ask for an organization account |
| Google Cloud organization blocking service account keys | Depends on the customer's IT team | Organizations created since 2024 block key creation by default; their administrator must allow it for the project ([guide 2](customer-setup/2-google-cloud-firebase.md), Step 7) |
| Firebase, Google Cloud billing, Codemagic | Same day | — |
| Custom email-link domain (optional) | Depends on the customer's IT team | They must host files on the domain and change DNS |

## 3. Before sending the guides

### Permanent choices

Confirm these in writing. They cannot be changed later without a new app or
a data migration:

| Choice | Why it is permanent |
| --- | --- |
| App ID (`appId`), for example `<our-reverse-domain>.<customer-id>` | Android and iOS bind the store listing to it after the first release |
| Firestore location and Cloud Functions region (`firebase.functionsRegion`) | The Firestore location cannot be changed after the database is created; choose it to match the customer's data-residency needs |
| Firebase project ID | Fixed when the project is created |

### Values to send the customer

Customer ID, App ID, app name, Firebase project ID, data location, our team's
email address, and whether phone verification is on (see
[customer-setup/README.md](customer-setup/README.md)).

### Contract, people, and app content

| Item | Provided by | How we validate |
| --- | --- | --- |
| Signed contract, including support level and acceptance of the release and support policy ([RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md)) | Customer + us | Copy filed; reference in the deployment register |
| Business owner, technical contact, acceptance approver, billing contact | Customer | Recorded in the register |
| App name (1–30 characters), brand color, modules | Customer, with us | `node tool/deployment.mjs check` passes |
| App icon: 1024×1024 PNG, no transparency | Customer | Opened and checked |
| Privacy policy URL, public HTTPS. **Required by both stores** | Customer | Opens in a private browser window |
| Terms of service URL (optional), support email | Customer | URL opens; a test email arrives |
| Store texts and images; answers to the Play content rating and Data safety and the Apple App Privacy questions (we prepare them for the enabled modules) | Customer confirms | Written confirmation |
| Custom email-link domain (optional) | Customer | They can host `/.well-known/` files and change DNS on it |

## 4. Our part: the customer's deployment repository

A customer's deployment folder never lives in this repository. Each customer
has its own **private** repository in our GitHub organization, named
`deployment-<customer-id>`, containing only:

```
deployment.json
firebase/google-services.json
firebase/GoogleService-Info.plist
```

The release workflows fetch it at build time (`node tool/deployment.mjs
fetch`). This way a customer's Codemagic team can read only its own
deployment, never another customer's.

1. Create the private repository and add the three files. The Firebase files
   come from the customer (Option B) or from the Firebase console (Option A).
   Check locally: clone it to `deployments/<customer-id>/` (git-ignored here)
   and run `node tool/deployment.mjs check <customer-id>`.
2. Create a key pair for the customer's Codemagic team:
   `ssh-keygen -t ed25519 -f deploy_key -q -N "" -C codemagic-<customer-id>`.
3. Add `deploy_key.pub` to the repository as a **read-only** deploy key
   (GitHub → repository → Settings → Deploy keys).
4. Paste `deploy_key` into the customer's Codemagic team, group `deployment`,
   variable `DEPLOYMENT_REPO_SSH_KEY`, Secret on. Add `DEPLOYMENT_REPO` (the
   repository's SSH URL), `DEPLOYMENT_ID`, and `CM_PUBLISH_EMAIL` to the same
   group.
5. Delete both key files.
6. Add the application to the customer's Codemagic team from this
   repository, with its own read-only deploy key on this repository, created
   the same way.

## 5. Readiness check (go / no-go)

The release operator runs this check before
[DEPLOYMENT.md](DEPLOYMENT.md) §4 starts.

1. **Collected:** every item of §3 is received, and the customer has sent the
   **Send us** items of each guide.
2. **Platform checks:** for each platform, do every line of the guide's
   **Check** list:
   - Option A: yourself, signed in with our own account. "The customer said it
     is done" does not count.
   - Option B: from the customer's screenshots.
3. **Secrets work:** in the customer's Codemagic team, run the
   **Readiness check** workflow (`readiness-check`) on the latest release
   tag. It fetches the deployment, validates it and its Firebase files, and
   proves each secret works without showing it:

   | Check | Proves |
   | --- | --- |
   | Firebase deploy key | It belongs to the deployment's project and can access it |
   | App Store Connect key | It works, and the app with the App ID exists |
   | Certificate private key | It is an RSA private key |
   | Google Play key | It is a service account key; after the first manual upload, that it can access the app (before, it only shows **WAIT**) |
   | Android keystore | `upload_keystore` exists and opens with its password and alias |
   | `CM_PUBLISH_EMAIL` | It is set |

   Any **FAIL** line names the guide step to fix.
4. Record the result in the deployment register: date, operator, option per
   platform, and every item as ✅ or ❌.
5. Decide:
   - **Go**: every item is ✅ and the workflow passes. The product owner
     approves, and the deployment starts.
   - **No-go**: send the customer the list of ❌ items, each with the guide
     step that fixes it and who must do it. Run the check again when they
     report it is done.

There are no partial starts. A deployment that starts without Apple access,
for example, stops later at the iOS release and leaves a half-configured
customer.

## 6. After the deployment

Once the deployment is released:

- With Google Cloud Option A, ask the customer to remove the setup-only roles
  (Project IAM Admin, Service Account Admin, Service Account Key Admin).
- With Option B, send the customer the reminder for
  [guide 2, Part 3](customer-setup/2-google-cloud-firebase.md#part-3-after-the-first-store-release-option-b-only)
  (fingerprints, App Check, store links).
- Record in the register the access we keep. When support ends, the customer
  removes all of it ([DEPLOYMENT.md](DEPLOYMENT.md) §3, "Offboarding"), and
  we delete the read-only deploy keys.

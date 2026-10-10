# Deployment Runbook and Timings

This runbook is for the deployment team. It lists every step of a
deployment, who or what does it, and how long it takes, and it records
measured times so each deployment can be faster than the last. The detailed
instructions are in [DEPLOYMENT.md](DEPLOYMENT.md) and
[customer-setup/](customer-setup/README.md).

It assumes the shared accounts already exist (Codemagic team, Apple Developer,
Google Play, an open Cloud Billing account). For a customer, the readiness
check ([CUSTOMER_PREREQUISITES.md](CUSTOMER_PREREQUISITES.md)) comes first.

## 1. Steps

**Auto** = a command or Codemagic workflow does it. **Manual** = a person in a
console. Times are hands-on time; machine time is listed separately.

| # | Step | How | Estimate |
| --- | --- | --- | --- |
| 1 | Write `deployment.json` (ID, name, app ID, project, region, modules) | Manual, from `deployments/example/` | 3 min |
| 2 | Create the Firebase project | Auto: `node tool/provision.mjs <id> --create` | 0.5 min |
| 3 | Link billing (Blaze) | Auto: `--billing-account <ID>` | 0.5 min |
| 4 | Turn on Authentication | Manual, only if `provision` asks: Firebase console → Authentication → **Get started** (one click) | 0–0.5 min |
| 5 | APIs, sign-in methods, Firestore, Storage bucket, Android and iOS apps, config files, Remote Config, deploy service account and roles | Auto: `node tool/provision.mjs <id>` (rerun after step 4) | 3 min |
| 6 | Deploy key into Codemagic (`firebase_deploy`) | Manual: create the JSON key, paste it, delete the file | 2 min |
| 7 | APNs key into Firebase | Manual: upload the team's `.p8` (the same key serves every app of the Apple team) | 1 min |
| 8 | Commit the deployment folder (ours) or push it to `deployment-<customer-id>` (customer) | Manual | 1 min |
| 9 | Apple: App ID with Push Notifications and Associated Domains | Manual (developer.apple.com) | 3 min |
| 10 | Apple: app record in App Store Connect | Manual (Apple offers no API for this) | 3 min |
| 11 | Google Play: create the app | Manual (Google offers no API for this) | 3 min |
| 12 | Codemagic: application and its `deployment` / `firebase_deploy` groups | Manual | 5 min |
| 13 | Backend | Auto: `backend-deploy` workflow | 0.5 min to start; ~8 min machine |
| 14 | Android | Auto: `android-release` workflow | 0.5 min to start; ~15 min machine |
| 15 | First Play upload of the `.aab` (first release only) | Manual | 5 min |
| 16 | iOS | Auto: `ios-release` workflow | 0.5 min to start; ~20 min machine |
| 17 | Smoke test on a device; record in the register | Manual | 10 min |

Estimated total for one environment: **about 40 minutes hands-on**, and about
**1 hour elapsed** when steps 13, 14, and 16 run in parallel.

## 2. Measured times

Fill in one column per deployment. "—" means the step was already done.

| # | Step | `dev` | `test` | `demo` |
| --- | --- | --- | --- | --- |
| 1 | `deployment.json` | 2 min | | |
| 2 | Create project | 25 s | — | |
| 3 | Billing | blocked: no open billing account | | |
| 4 | Authentication Get started | not needed | | |
| 5 | Provision | 33 s (Storage waits for billing) | | |
| 6 | Deploy key | | | |
| 7 | APNs key | | | |
| 8 | Commit | | | |
| 9 | App ID | | | |
| 10 | App Store Connect app | | | |
| 11 | Play app | | | |
| 12 | Codemagic | | | |
| 13 | Backend | | | |
| 14 | Android | | | |
| 15 | First Play upload | | | |
| 16 | iOS | | | |
| 17 | Smoke test | | | |
| | **Total hands-on** | | | |

## 3. Improvements

Apply them between deployments, then measure again.

| # | Improvement | Saves | Status |
| --- | --- | --- | --- |
| I1 | `tool/provision.mjs`: Firebase setup by command instead of console (steps 2–5) | ~40 min → under 1 min | Done: 33 s on `dev` |
| I2 | Our Codemagic team: `ios_signing`, `google_play`, and the keystore as **team** groups shared by all our applications, so each new environment only needs `deployment` and `firebase_deploy` | ~5 min per environment | To do in the Codemagic console |
| I3 | Create Codemagic groups and variables with the Codemagic API (step 12), so secrets are pushed from where they are created | ~5 min | Needs a Codemagic API token to try |
| I4 | Register the App ID and its capabilities from Codemagic with the `app-store-connect` CLI (step 9) | ~3 min | To do |
| I5 | One trigger instead of three: start backend, Android, and iOS together, or trigger our environments automatically (`dev` on push to `main`, `demo` on a release tag) | ~2 min per release, and no forgotten workflow | To do |

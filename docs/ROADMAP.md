# Skeleton — Product Roadmap

As of 2026-10-10.

## Deployment model (decided)

**One deployment = one Firebase project = one backend.** Each deployment gets
its own Firebase project, owned by the customer and billed to the customer's
own Firebase/Cloud Billing account. As part of each deployment we create that
project under the customer's account and choose the app identifier. Each
deployment is one file, `deployments/<id>/deployment.json`, and every secret
stays in the customer's accounts and Codemagic team. The procedure is in
[DEPLOYMENT.md](DEPLOYMENT.md).

**One version line (decided).** No customer forks, branches, or
customer-specific code. Every customer is upgraded to every release; only the
current and previous versions are supported. See
[RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md).

## Where the skeleton stands today

Skeleton is a reusable Flutter + Firebase starter. Its foundation is complete.
The repository holds three deployments: `example` (placeholder values, local
emulators, CI), `test` (`medsalem-skeleton-test`), and `dev` (`whatsapp-bot-f57a8`, `com.yourname.skeleton`).

| Area | What ships today |
| --- | --- |
| Client | Flutter (Material 3), Riverpod, go_router; feature slices with data / application / presentation layers |
| Modules | Auth (email/password + SMS-verified phone, email verification, action links), Home, Profile + photo, Settings, Onboarding, Push + inbox, app lock, required-update gate, Crashlytics, App Check |
| Configuration | One `deployment.json` per deployment (identity, Firebase project, links, color, modules), applied by `tool/deployment.mjs` |
| Backend | 5 Cloud Functions (`recordPasswordChange`, `sendInboxPush`, `deleteAccount`, `cleanupDeletedUser`, `revokeAllSessions`), Node 22; owner-only Firestore and Storage rules with a profile field allowlist |
| Data | `users/{uid}` with `notifications` and `fcmTokens` subcollections; avatars under `users/{uid}/profile/` |
| Localization | English and French, including push text |
| Tests | 96 Flutter tests; 5 Functions unit tests; 5 emulator rules tests |
| CI/CD | One `codemagic.yaml` for every deployment: `frontend-ci`, `backend-ci` (automatic, our team); `backend-deploy`, `android-release`, `ios-release` (manual, customer's team) |
| Docs | README, FSD, TSD, feature guide, rename guide, deployment guide, customer deployment guide, release and support policy, this roadmap, `CHANGELOG.md` |

## Gaps and risks

| # | Finding | Status |
| --- | --- | --- |
| G1 | `backend-deploy` ran automatically on `main` against a shared project (`whatsapp-bot-f57a8`) that hosts other functions and rules. | **Fixed.** Manual only, with a guard that stops unless `FIREBASE_PROJECT_ID` matches `frontend/firebase.json`. The default project in `backend/.firebaserc` is removed, so every deploy must name its project. |
| G2 | Workflows fail validation when `CM_PUBLISH_EMAIL` is missing from their environment group. | **Needs Codemagic console setup.** All workflows now read it from one group, `deployment`; see `docs/DEPLOYMENT.md`. |
| G3 | The app version was set in three places that could drift. | **Fixed.** `pubspec.yaml` is the only source (now `1.1.0+1`); the drawer reads it with `package_info_plus`; `--build-name` is removed from Codemagic. |
| G4 | No CI ran `flutter analyze` / `flutter test` on push or PR. | **Fixed.** New `frontend-ci` Codemagic workflow. |
| G5 | Dev and prod shared one Firebase project; no flavors. | **Superseded by the deployment model.** Each deployment has its own project; per-customer dev/prod projects are created as needed. Building several customers from one checkout is v2.0 work. |
| G6 | The client wrote the password-change inbox record; push text was English only. | **Fixed.** The `recordPasswordChange` function writes the record; clients cannot create inbox records; push text follows the user's app language. |
| G7 | The owner could write any field on `users/{uid}`. | **Fixed.** Field allowlist (`name`, `email`, `photoStoragePath`, `notificationsEnabled`) with type checks; clients cannot delete the profile. |
| G8 | No Functions tests; no cleanup for data left after deletion. | **Fixed.** Unit tests (`npm test`) run in `backend-ci`; `deleteAccount` tolerates retries; `cleanupDeletedUser` removes data when a user is deleted outside the app. |
| G9 | `firebase_analytics` was never imported; the `dio` API client is unused. | **Partly fixed.** `firebase_analytics` removed. `dio` stays as the template's optional REST client. |
| G10 | `account_security_screen.dart` is 799 lines; few semantics labels. | Open (v1.2). |
| G11 | Customer automation is specified but not built. | **Mostly fixed.** Deployment file, `tool/deployment.mjs` (check, use, deploy-backend, secret scan), parameterized Android/iOS identity, one Codemagic file with customer-owned secrets. Build matrix, provenance, and staging promotion remain (v2.0). |

## v1.1 — Safe pipeline and release hygiene

Done when all workflows validate, a PR gets an automatic analyze and test run,
and the first release is tagged `v1.1.0`.

- [x] Make `backend-deploy` manual and guarded against the wrong project (G1)
- [x] Add `frontend-ci` on push and PR (G4)
- [x] Use one version source (G3)
- [x] Add `CHANGELOG.md`
- [x] Remove `firebase_analytics` (G9)
- [x] Server-written password-change record, localized push, profile field allowlist, Functions tests, deletion cleanup (G6–G8, pulled forward from v1.2)
- [x] One deployment file per deployment, generated native identity, customer-owned secrets (G11, pulled forward)
- [ ] Verify the new CLI-based iOS signing on the first `ios-release` run
- [ ] Add `CM_PUBLISH_EMAIL` to each customer's `deployment` group (G2)
- [ ] Move the `dev` deployment from `whatsapp-bot-f57a8` to a dedicated project: regenerate `deployments/dev/firebase/` and update `deployments/dev/deployment.json`
- [ ] Create the `demo` deployment: its own Firebase project on Blaze, all modules on, not internal; distribute through Play open/closed testing and a TestFlight public link
- [ ] Prepare our own accounts for the three environments (Google Cloud billing, Apple Developer, Play Console, Codemagic), see [DEPLOYMENT.md](DEPLOYMENT.md) §1
- [ ] Deploy the new functions and rules to that project, then release the app (the new app needs `recordPasswordChange` deployed first)
- [ ] Tag `v1.1.0`

## v1.2 — Quality

Done when the large settings screens are split and the accessibility pass is
complete.

- [ ] Split `account_security_screen.dart` into per-action widgets (G10)
- [ ] Accessibility pass on semantics labels (G10)
- [ ] Add emulator integration tests for the callable functions

## v2.0 — Multi-customer platform

v2.0 turns the manual process in [CUSTOMER_DEPLOYMENT.md](CUSTOMER_DEPLOYMENT.md)
into automation, so one codebase can ship many customer apps safely. Done when
a new customer can be built and deployed from a manifest, with no hand edits
to shared files.

- [x] Validated deployment file driving `AppConfig`, `AppFeatures`, and native identity (G11)
- [x] One Codemagic file for every deployment, with a project guard
- [ ] Add a build matrix for the supported module combinations, reusing the `AppFeatures.validate()` rules
- [ ] Record artifact provenance (commit SHA, manifest version, lockfiles, build number) and keep a deployment register of versions per customer
- [ ] Add staging promotion with human approval before production deploys
- [ ] Design first, then build: remote kill switches and staged rollout ([TSD](TSD.md) §11), and server-side entitlements for licensed modules ([CUSTOMER_DEPLOYMENT.md](CUSTOMER_DEPLOYMENT.md) §9)

## Open questions

- [x] Shared or dedicated Firebase project? Dedicated, customer-owned, one per deployment.
- [ ] Each customer's Codemagic team clones this repository, which contains every customer's deployment folder (public values only, but it shows who our customers are). Is that acceptable, or should customer deployment files live somewhere separate per customer?
- [ ] Which reverse domain do we use for app identifiers (`<our-reverse-domain>.<customer-id>`)?
- [ ] Is the first real customer expected before v2.0? If so, which parts of the manifest work move earlier?
- [ ] Which languages beyond EN/FR are needed, and are they in scope for the shared skeleton?
- [ ] Target dates per version: none are set yet.

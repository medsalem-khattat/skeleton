# Skeleton

Reusable Flutter + Firebase application foundation. Each customer deployment
is one file, `deployments/<id>/deployment.json`, with its own customer-owned
Firebase project; customers own every secret and all user data.

## Repository layout

- [`frontend/`](frontend/) — Flutter application, platform projects, and
  client tests.
- [`backend/`](backend/) — Firebase Functions, Firestore/Storage rules,
  emulator and deployment configuration.
- [`deployments/`](deployments/) — one folder per deployment: the deployment
  file and its public Firebase client files. No secrets.
- [`tool/deployment.mjs`](tool/deployment.mjs) — checks, selects, and deploys
  a deployment.
- [`docs/`](docs/) — setup, architecture, functional/technical specifications,
  feature development, and deployment guides.
- [`codemagic.yaml`](codemagic.yaml) — CI and release workflows for every
  deployment.

## Quick start

Select a deployment, then run the app with its values (`example` uses the
local Firebase emulators and placeholder values):

```sh
node tool/deployment.mjs use example
cd frontend
flutter pub get
flutter run --dart-define-from-file=deployment.g.json
```

Run the checks:

```sh
node tool/deployment.mjs list
cd frontend && flutter analyze && flutter test
cd ../backend/functions && npm ci && npm test && npm run test:rules
```

To deploy for a customer, follow [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md):
parameters, secrets strategy, step-by-step setup, and testing. Ownership,
support, and bug-fix policy are in
[docs/CUSTOMER_DEPLOYMENT.md](docs/CUSTOMER_DEPLOYMENT.md); upgrades and end of
support in [docs/RELEASE_AND_SUPPORT.md](docs/RELEASE_AND_SUPPORT.md). See
[`docs/README.md`](docs/README.md) for feature details, the
[FSD](docs/FSD.md), [TSD](docs/TSD.md), and
[feature guide](docs/HOW_TO_ADD_A_FEATURE.md) for architecture, and
[docs/ROADMAP.md](docs/ROADMAP.md) for upcoming versions.

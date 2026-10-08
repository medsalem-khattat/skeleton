# Skeleton

Reusable Flutter + Firebase application foundation, currently configured as a
single-customer deployment.

## Repository layout

- [`frontend/`](frontend/) — Flutter application, platform projects, and
  client tests.
- [`backend/`](backend/) — Firebase Functions, Firestore/Storage rules,
  emulator and deployment configuration.
- [`docs/`](docs/) — setup, architecture, functional/technical specifications,
  feature development, and customer deployment guides.
- [`codemagic.yaml`](codemagic.yaml) — repository-level Android/iOS release
  workflows.

## Quick start

Install and run the Flutter app:

```sh
cd frontend
flutter pub get
flutter run
```

Run client checks:

```sh
cd frontend
flutter analyze
flutter test
```

Build and test Firebase Functions/rules:

```sh
cd backend/functions
npm ci
npm run build
npm run test:rules
```

See [`docs/README.md`](docs/README.md) for Firebase setup, emulator usage,
signing, and release configuration. For architecture and extension guidance,
see the [FSD](docs/FSD.md), [TSD](docs/TSD.md), and
[feature guide](docs/HOW_TO_ADD_A_FEATURE.md). Customer-specific deployment and
fix procedures are documented in
[docs/CUSTOMER_DEPLOYMENT.md](docs/CUSTOMER_DEPLOYMENT.md).

This repository is not yet a multi-customer build system: Firebase project,
app identifiers, and Codemagic signing values are currently configured for one
deployment.

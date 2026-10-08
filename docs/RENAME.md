# Renaming the skeleton for a new customer or product

The repository is organized as a small monorepo:

- `frontend/` contains the Flutter app and platform projects.
- `backend/` contains Firebase Functions, rules, and Firebase CLI config.
- `docs/` contains the project and operational guides.
- `codemagic.yaml` stays at the repository root for CI discovery.

Perform these steps on a clean branch, then review the complete diff before
building.

1. **Flutter package**: update `frontend/pubspec.yaml` `name:` to a lowercase
   underscore package name. Update package imports in `frontend/test/` from
   `package:skeleton/` to `package:<new_name>/`.
2. **Application identity**: edit
   `frontend/lib/core/config/app_config.dart` and set `appName`, `bundleId`,
   `appVersion`, and `seedColor`.
3. **Native app identity**: update Android application ID and iOS bundle ID
   under `frontend/android/` and `frontend/ios/`. Optionally use the `rename`
   package, but inspect all generated native changes before accepting them.
4. **Firebase**: create or select the customer's Firebase project and register
   its Android/iOS apps. From the Flutter project directory, regenerate the
   client configuration:

   ```sh
   cd frontend
   flutterfire configure --project=<customer-project-id>
   ```

   This updates `frontend/lib/firebase_options.dart`,
   `frontend/android/app/google-services.json`,
   `frontend/ios/Runner/GoogleService-Info.plist`, and FlutterFire metadata in
   `frontend/firebase.json`. It does not migrate user accounts or data.
5. **Backend target**: verify `backend/firebase.json` deploys only the intended
   customer resources. Firebase CLI commands from the repository root must
   pass `--config backend/firebase.json` and the explicit project ID.
6. **Rules and services**: review `backend/firestore.rules` and
   `backend/storage.rules` against the customer's data model. Merge rules into
   an existing project; do not overwrite unrelated production rules. Deploy
   only the required backend services.
7. **Email links and push**: update Android/iOS Associated Domains, Android
   App Links, APNs, signing entitlements, and Firebase providers as required by
   enabled modules. Keep provisioning profiles synchronized with the
   entitlements.
8. **Release workflow**: update the root `codemagic.yaml`, including the iOS
   bundle identifier, signing references, and any customer-owned distribution
   configuration. Keep secrets in Codemagic, not in this repository.
9. **Verify from the correct project directories**:

   ```sh
   cd frontend
   flutter pub get
   flutter analyze
   flutter test
   cd ../backend/functions
   npm ci
   npm run build
   npm run test:rules
   ```

10. Run the Android/iOS release workflows with the customer's staging
    configuration before production. See
    [Customer Deployment and Bug-Fix Guide](CUSTOMER_DEPLOYMENT.md).

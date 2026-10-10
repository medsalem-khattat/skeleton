# Renaming the skeleton

A new customer does **not** need a rename. The app name, Android application
ID, iOS bundle ID, Firebase project, links, color, and modules all come from
the deployment file; follow [DEPLOYMENT.md](DEPLOYMENT.md).

Rename only when you fork the skeleton into a separate product with its own
codebase. Do it on a clean branch and review the complete diff:

1. **Flutter package**: update `frontend/pubspec.yaml` `name:` to a lowercase
   underscore package name. Update package imports in `frontend/test/` from
   `package:skeleton/` to `package:<new_name>/`.
2. **Android code namespace** (optional): `namespace` in
   `frontend/android/app/build.gradle.kts` and the Kotlin package of
   `MainActivity.kt`. This is the code package only; the installed app ID
   still comes from the deployment file.
3. **Defaults for builds without a deployment**: the `fromEnvironment`
   defaults in `frontend/lib/core/config/app_config.dart`.
4. **Verify**:

   ```sh
   node tool/deployment.mjs use example
   cd frontend
   flutter pub get
   flutter analyze
   flutter test
   ```

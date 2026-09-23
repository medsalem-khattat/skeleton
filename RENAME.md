# Renaming the skeleton for a new project

Every file in `lib/` uses relative imports, so no code changes are needed for the rename itself.

1. **pubspec.yaml**: change `name:` to the new package name (lowercase, underscores).
2. **test/**: replace `package:skeleton/` with `package:new_name/` (VS Code: Ctrl+Shift+H).
3. **lib/core/config/app_config.dart**: set `appName`, `appVersion`, `seedColor`.
4. **App display name and bundle id**
   - `dart pub global activate rename`
   - `rename setAppName --targets android,ios --value "New App"`
   - `rename setBundleId --targets android,ios --value "com.yourname.newapp"`
5. **Firebase**: create a new Firebase project (enable Email/Password auth and Firestore), then run
   `flutterfire configure --project=<new-project-id>`.
6. **Firestore rules**: paste the rules from `firestore.rules` in the Firebase console (Firestore > Rules > Publish).
7. Run `flutter clean`, `flutter pub get`, `flutter run`.

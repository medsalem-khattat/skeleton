Task 6-7: config + design tokens

1) Unzip at the ROOT of the skeleton Flutter project:
     unzip -o skeleton_config_tokens.zip

2) In lib/main.dart:
     import 'core/config/app_config.dart';
     import 'core/design/design.dart';
     MaterialApp(title: AppConfig.appName, theme: AppTheme.light(), ...)

3) Find what still needs refactoring in the 6 screens:
     ./scripts/check_hardcoded.sh

4) Run:
     flutter pub get && flutter run
     flutter run --dart-define=API_KEY=xxx --dart-define=API_BASE_URL=https://...

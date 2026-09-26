import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeleton/features/auth/application/auth_providers.dart';
import 'package:skeleton/features/home/presentation/home_shell.dart';
import 'package:skeleton/features/profile/application/profile_providers.dart';
import 'package:skeleton/features/profile/data/user_profile.dart';
import 'package:skeleton/features/settings/application/theme_controller.dart';
import 'package:skeleton/features/settings/presentation/settings_screen.dart';
import 'package:skeleton/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('groups appearance and language under drawer settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            drawer: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: const AppNavigationDrawer(),
              ),
            ),
            body: Builder(
              builder: (context) => IconButton(
                tooltip: 'Open menu',
                onPressed: Scaffold.of(context).openDrawer,
                icon: const Icon(Icons.menu),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: Text('Profile')),
            body: const Text('Profile destination'),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          profileProvider.overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                name: 'Samira Example User With A Long Full Name',
                email: 'samira.long-address@example.com',
              ),
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();

    expect(
      find.text('Samira Example User With A Long Full Name'),
      findsOneWidget,
    );
    expect(find.text('samira.long-address@example.com'), findsOneWidget);
    expect(
      tester.getSize(find.byType(ConstrainedBox).first).height,
      greaterThan(190),
    );
    expect(find.text('Profile destination'), findsNothing);
    expect(find.text('Appearance'), findsNothing);
    expect(find.text('Language'), findsNothing);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
    final avatarCenter = tester.getCenter(find.byType(CircleAvatar));
    final nameCenter = tester.getCenter(
      find.text('Samira Example User With A Long Full Name'),
    );
    final emailCenter = tester.getCenter(
      find.text('samira.long-address@example.com'),
    );
    final versionCenter = tester.getCenter(find.text('Version 1.0.0'));
    expect((avatarCenter.dx - nameCenter.dx).abs(), lessThan(1));
    expect((nameCenter.dx - emailCenter.dx).abs(), lessThan(1));
    expect(versionCenter.dx, closeTo(avatarCenter.dx, 1));

    await tester.scrollUntilVisible(
      find.text('Home'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Home'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Settings'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.byType(RadioGroup<ThemeMode>), findsOneWidget);
    expect(find.byType(RadioGroup<String>), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('samira.long-address@example.com'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('samira.long-address@example.com'));
    await tester.pumpAndSettle();
    expect(find.text('Profile destination'), findsOneWidget);

    router.dispose();
  });
}

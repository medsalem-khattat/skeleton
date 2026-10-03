import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skeleton/core/config/feature_config.dart';
import 'package:skeleton/core/config/feature_providers.dart';
import 'package:skeleton/features/home/presentation/home_screen.dart';
import 'package:skeleton/features/notifications/data/app_notification.dart';
import 'package:skeleton/features/notifications/data/notification_inbox_repository.dart';
import 'package:skeleton/l10n/app_localizations.dart';

void main() {
  testWidgets('shows unread badge and opens inbox when tapped', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const Scaffold(body: Text('Notification inbox')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appFeaturesProvider.overrideWithValue(
            const AppFeatures(
              authentication: true,
              home: true,
              profile: false,
              settings: false,
              appearanceSettings: false,
              languageSettings: false,
              deviceAuthentication: false,
              pushNotifications: false,
              notificationInbox: true,
              crashReporting: false,
            ),
          ),
          notificationInboxProvider.overrideWith(
            (ref) => Stream.value([
              AppNotification(
                id: 'unread-1',
                type: AppNotificationType.passwordChanged,
                createdAt: DateTime.utc(2026, 10, 3),
                isRead: false,
              ),
              AppNotification(
                id: 'read-1',
                type: AppNotificationType.passwordChanged,
                createdAt: DateTime.utc(2026, 10, 2),
                isRead: true,
              ),
              AppNotification(
                id: 'unread-2',
                type: AppNotificationType.passwordChanged,
                createdAt: DateTime.utc(2026, 10, 1),
                isRead: false,
              ),
            ]),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byTooltip('2 unread notifications'), findsOneWidget);

    await tester.tap(find.byTooltip('2 unread notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notification inbox'), findsOneWidget);
  });

  testWidgets('hides bell when notification inbox module is disabled', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appFeaturesProvider.overrideWithValue(
            const AppFeatures(
              authentication: false,
              home: true,
              profile: false,
              settings: false,
              pushNotifications: false,
              notificationInbox: false,
              crashReporting: false,
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
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
  });
}

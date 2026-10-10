import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skeleton/features/notifications/data/app_notification.dart';
import 'package:skeleton/features/notifications/data/notification_inbox_repository.dart';
import 'package:skeleton/features/notifications/data/push_notification_service.dart';
import 'package:skeleton/features/notifications/presentation/notification_inbox_screen.dart';
import 'package:skeleton/l10n/app_localizations.dart';

void main() {
  testWidgets('shows password-change notification in the inbox', (
    tester,
  ) async {
    final repository = _FakeNotificationInboxRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationInboxScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Password changed'), findsOneWidget);
    expect(
      find.text('Your account password was changed successfully.'),
      findsOneWidget,
    );
    await tester.pumpAndSettle();

    expect(repository.markedReadIds, isEmpty);
    await tester.tap(find.byTooltip('Mark as read'));
    await tester.pumpAndSettle();
    expect(repository.markedReadIds, ['password-change-1']);
  });

  testWidgets('opens a notification directly from its route ID', (
    tester,
  ) async {
    final repository = _FakeNotificationInboxRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationInboxScreen(notificationId: 'password-change-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Password changed'), findsOneWidget);
    expect(repository.markedReadIds, ['password-change-1']);
  });

  testWidgets('selecting an inbox item opens a status popup', (tester) async {
    final repository = _FakeNotificationInboxRepository();
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationInboxScreen(),
        ),
        GoRoute(
          path: '/notifications/:notificationId',
          builder: (_, state) => NotificationInboxScreen(
            notificationId: state.pathParameters['notificationId'],
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Password changed').first);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text('Your account password was changed successfully.'),
      findsNWidgets(2),
    );
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Read'), findsNothing);
    expect(find.text('Mark as read'), findsOneWidget);
    expect(repository.markedReadIds, isEmpty);

    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();

    expect(repository.markedReadIds, ['password-change-1']);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Unread'), findsNothing);
    expect(find.text('Mark as read'), findsNothing);
  });

  testWidgets('popup shows read status without a mark-as-read action', (
    tester,
  ) async {
    final repository = _FakeNotificationInboxRepository(isRead: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationInboxScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Password changed').first);
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Unread'), findsNothing);
    expect(find.text('Mark as read'), findsNothing);
    expect(repository.markedReadIds, isEmpty);
  });

  testWidgets('close button returns Home after direct notification open', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/notifications/password-change-1',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home screen')),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const Scaffold(body: Text('Notification inbox')),
        ),
        GoRoute(
          path: '/notifications/:notificationId',
          builder: (_, state) => NotificationInboxScreen(
            notificationId: state.pathParameters['notificationId'],
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxRepositoryProvider.overrideWithValue(
            _FakeNotificationInboxRepository(),
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

    expect(find.text('Password changed'), findsOneWidget);
    await tester.tap(find.byTooltip('Close notification'));
    await tester.pumpAndSettle();

    expect(find.text('Home screen'), findsOneWidget);
  });

  testWidgets('inbox close button returns Home', (tester) async {
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home screen')),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationInboxScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxRepositoryProvider.overrideWithValue(
            _FakeNotificationInboxRepository(),
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

    await tester.tap(find.byTooltip('Close notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Home screen'), findsOneWidget);
  });

  test('notification tap builds an inbox or notification detail route', () {
    expect(const NotificationTap().location, '/notifications');
    expect(
      const NotificationTap(notificationId: 'password-change-1').location,
      '/notifications/password-change-1',
    );
  });
}

class _FakeNotificationInboxRepository implements NotificationInboxRepository {
  _FakeNotificationInboxRepository({this.isRead = false});

  final bool isRead;
  final markedReadIds = <String>[];

  @override
  Stream<List<AppNotification>> watch() => Stream.value([
    AppNotification(
      id: 'password-change-1',
      type: AppNotificationType.passwordChanged,
      createdAt: DateTime.utc(2026, 10, 2, 20),
      isRead: isRead,
    ),
  ]);

  @override
  Stream<AppNotification?> watchNotification(String notificationId) =>
      Stream.value(
        AppNotification(
          id: notificationId,
          type: AppNotificationType.passwordChanged,
          createdAt: DateTime.utc(2026, 10, 2, 20),
          isRead: isRead,
        ),
      );

  @override
  Future<void> recordPasswordChanged({required String languageCode}) async {}

  @override
  Future<void> markRead(String notificationId) async {
    markedReadIds.add(notificationId);
  }
}

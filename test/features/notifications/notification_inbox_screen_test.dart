import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/features/notifications/data/app_notification.dart';
import 'package:skeleton/features/notifications/data/notification_inbox_repository.dart';
import 'package:skeleton/features/notifications/data/push_notification_service.dart';
import 'package:skeleton/features/notifications/presentation/notification_inbox_screen.dart';
import 'package:skeleton/l10n/app_localizations.dart';

void main() {
  testWidgets('shows password-change notification and marks it as read', (
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
    expect(find.text('Mark as read'), findsOneWidget);
    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();

    expect(repository.markedReadIds, ['password-change-1']);
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
  final markedReadIds = <String>[];

  @override
  Stream<List<AppNotification>> watch() => Stream.value([
    AppNotification(
      id: 'password-change-1',
      type: AppNotificationType.passwordChanged,
      createdAt: DateTime.utc(2026, 10, 2, 20),
      isRead: false,
    ),
  ]);

  @override
  Stream<AppNotification?> watchNotification(String notificationId) =>
      Stream.value(
        AppNotification(
          id: notificationId,
          type: AppNotificationType.passwordChanged,
          createdAt: DateTime.utc(2026, 10, 2, 20),
          isRead: false,
        ),
      );

  @override
  Future<void> recordPasswordChanged() async {}

  @override
  Future<void> markRead(String notificationId) async {
    markedReadIds.add(notificationId);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/config/feature_config.dart';
import 'package:skeleton/core/config/feature_providers.dart';
import 'package:skeleton/features/auth/application/auth_providers.dart';
import 'package:skeleton/features/notifications/data/notification_inbox_repository.dart';
import 'package:skeleton/features/notifications/data/app_notification.dart';
import 'package:skeleton/features/profile/application/profile_providers.dart';
import 'package:skeleton/features/profile/data/user_profile.dart';
import 'package:skeleton/features/profile/presentation/profile_screen.dart';
import 'package:skeleton/features/settings/presentation/account_security_screen.dart';
import 'package:skeleton/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('profile contains personal details, not security actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appFeaturesProvider.overrideWithValue(
            const AppFeatures(deviceAuthentication: false),
          ),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          profileProvider.overrideWith(
            (ref) => Stream.value(
              const UserProfile(name: 'Sam', email: 'sam@example.com'),
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Account security'), findsNothing);
    expect(find.text('Change password'), findsNothing);
    expect(find.text('Change email'), findsNothing);
    expect(find.text('Change mobile number'), findsNothing);
  });

  testWidgets('records a notification after a successful password change', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final notifications = _FakeNotificationInboxRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appFeaturesProvider.overrideWithValue(
            const AppFeatures(deviceAuthentication: false),
          ),
          authRepositoryProvider.overrideWithValue(auth),
          notificationInboxRepositoryProvider.overrideWithValue(notifications),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountSecurityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'old-pass');
    await tester.enterText(fields.at(1), 'new-pass');
    await tester.enterText(fields.at(2), 'new-pass');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(auth.lastNewPassword, 'new-pass');
    expect(notifications.passwordChangedRecords, 1);
    expect(find.text('Password changed successfully.'), findsOneWidget);
  });

  testWidgets('security dialogs dispose focused fields safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appFeaturesProvider.overrideWithValue(
            const AppFeatures(deviceAuthentication: false),
          ),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountSecurityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    final passwordField = find.byType(TextFormField).first;
    await tester.showKeyboard(passwordField);
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Change email'));
    await tester.pumpAndSettle();
    final emailField = find.byType(TextFormField).first;
    await tester.showKeyboard(emailField);
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('changes mobile number only after SMS verification', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appFeaturesProvider.overrideWithValue(
            const AppFeatures(deviceAuthentication: false),
          ),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountSecurityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final changePhoneTile = find.widgetWithText(
      ListTile,
      'Change mobile number',
    );
    await tester.ensureVisible(changePhoneTile);
    await tester.tap(changePhoneTile);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone number'),
      '+1 415 555 2671',
    );
    await tester.tap(find.text('Send verification code'));
    await tester.pumpAndSettle();

    expect(auth.lastPhoneNumber, '+14155552671');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'SMS verification code'),
      '654321',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current password'),
      'current-pass',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Change mobile number'),
      ),
    );
    await tester.pumpAndSettle();

    expect(auth.lastPhoneVerificationId, 'test-verification-id');
    expect(auth.lastPhoneSmsCode, '654321');
    expect(auth.lastCurrentPassword, 'current-pass');
    expect(find.text('Mobile number updated successfully.'), findsOneWidget);
  });
}

class _FakeNotificationInboxRepository implements NotificationInboxRepository {
  int passwordChangedRecords = 0;
  final markedReadIds = <String>[];

  @override
  Stream<List<AppNotification>> watch() => Stream.value(const []);

  @override
  Stream<AppNotification?> watchNotification(String notificationId) =>
      const Stream.empty();

  @override
  Future<void> recordPasswordChanged() async {
    passwordChangedRecords++;
  }

  @override
  Future<void> markRead(String notificationId) async {
    markedReadIds.add(notificationId);
  }
}

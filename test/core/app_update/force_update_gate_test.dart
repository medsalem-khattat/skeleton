import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/app_update/app_update_policy.dart';
import 'package:skeleton/core/app_update/force_update_gate.dart';
import 'package:skeleton/l10n/app_localizations.dart';

Widget _gateApp() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const ForceUpdateGate(child: Text('Home content')),
  );
}

void main() {
  testWidgets('keeps app content covered while checking update policy', (
    tester,
  ) async {
    final requirement = Completer<AppUpdateRequirement?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateRequirementProvider.overrideWith(
            (ref) => requirement.future,
          ),
        ],
        child: _gateApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Checking for required updates…'), findsOneWidget);
    expect(find.text('Home content'), findsNothing);

    requirement.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Home content'), findsOneWidget);
  });

  testWidgets('blocks app content when an update is required', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateRequirementProvider.overrideWith(
            (ref) async => AppUpdateRequirement(
              minimumVersion: '2.0.0',
              storeUrl: Uri.parse('https://example.com/store'),
            ),
          ),
        ],
        child: _gateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Home content'), findsNothing);
    expect(find.text('Update now'), findsOneWidget);
  });

  testWidgets('keeps app content available when no update is required', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateRequirementProvider.overrideWith((ref) async => null),
        ],
        child: _gateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home content'), findsOneWidget);
    expect(find.text('Update required'), findsNothing);
  });

  testWidgets('shows a blocking retry screen when update policy is invalid', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateRequirementProvider.overrideWith(
            (ref) async => throw StateError('Invalid Remote Config'),
          ),
        ],
        child: _gateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update check unavailable'), findsOneWidget);
    expect(find.text('Home content'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
  });
}

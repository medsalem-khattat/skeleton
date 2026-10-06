import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/app_update/app_update_policy.dart';

void main() {
  group('isAppVersionBelowMinimum', () {
    test('requires an update when the installed version is older', () {
      expect(
        isAppVersionBelowMinimum(
          installedVersion: '1.9.0',
          minimumVersion: '1.10.0',
        ),
        isTrue,
      );
    });

    test('does not require an update when versions are equal', () {
      expect(
        isAppVersionBelowMinimum(
          installedVersion: '2.0.0',
          minimumVersion: '2.0.0',
        ),
        isFalse,
      );
    });

    test('does not require an update when the installed version is newer', () {
      expect(
        isAppVersionBelowMinimum(
          installedVersion: '2.1.0',
          minimumVersion: '2.0.0',
        ),
        isFalse,
      );
    });

    test('uses semantic ordering for prerelease versions', () {
      expect(
        isAppVersionBelowMinimum(
          installedVersion: '2.0.0-beta.1',
          minimumVersion: '2.0.0',
        ),
        isTrue,
      );
    });

    test('rejects an invalid configured version', () {
      expect(
        () => isAppVersionBelowMinimum(
          installedVersion: '1.2.3',
          minimumVersion: 'latest',
        ),
        throwsFormatException,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/router/app_routes.dart';

void main() {
  group('authRedirect', () {
    test('requires verification for signed-in unverified accounts', () {
      expect(
        AppRoutes.authRedirect(
          isLoggedIn: true,
          emailVerified: false,
          location: AppRoutes.home,
        ),
        AppRoutes.verifyEmail,
      );
    });

    test('allows unverified accounts to remain on verification screen', () {
      expect(
        AppRoutes.authRedirect(
          isLoggedIn: true,
          emailVerified: false,
          location: AppRoutes.verifyEmail,
        ),
        isNull,
      );
    });

    test('sends verified accounts from verification to home', () {
      expect(
        AppRoutes.authRedirect(
          isLoggedIn: true,
          emailVerified: true,
          location: AppRoutes.verifyEmail,
        ),
        AppRoutes.home,
      );
    });

    test('sends signed-out users away from the verification screen', () {
      expect(
        AppRoutes.authRedirect(
          isLoggedIn: false,
          emailVerified: false,
          location: AppRoutes.verifyEmail,
        ),
        AppRoutes.login,
      );
    });
  });
}

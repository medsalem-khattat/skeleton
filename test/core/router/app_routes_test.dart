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

    test('allows signed-out users to access forgot password', () {
      expect(
        AppRoutes.authRedirect(
          isLoggedIn: false,
          emailVerified: false,
          location: AppRoutes.forgotPassword,
        ),
        isNull,
      );
    });

    test('sends verified users away from auth screens', () {
      expect(
        AppRoutes.authRedirect(
          isLoggedIn: true,
          emailVerified: true,
          location: AppRoutes.login,
        ),
        AppRoutes.home,
      );
    });

    test(
      'preserves a notification destination through login and verification',
      () {
        const destination = '/notifications/password-change-1';

        expect(
          AppRoutes.authRedirect(
            isLoggedIn: false,
            emailVerified: false,
            location: destination,
          ),
          '/login?redirect=%2Fnotifications%2Fpassword-change-1',
        );
        expect(
          AppRoutes.authRedirect(
            isLoggedIn: true,
            emailVerified: false,
            location: AppRoutes.login,
            requestedLocation: destination,
          ),
          '/verify-email?redirect=%2Fnotifications%2Fpassword-change-1',
        );
        expect(
          AppRoutes.authRedirect(
            isLoggedIn: true,
            emailVerified: true,
            location: AppRoutes.login,
            requestedLocation: destination,
          ),
          destination,
        );
      },
    );

    test('does not accept external redirect destinations', () {
      expect(
        AppRoutes.authRedirect(
          isLoggedIn: true,
          emailVerified: true,
          location: AppRoutes.login,
          requestedLocation: 'https://example.com',
        ),
        AppRoutes.home,
      );
    });
  });
}

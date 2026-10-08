import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/email_action_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/notifications/data/push_notification_service.dart';
import '../../features/notifications/data/push_token_registrar.dart';
import '../../features/notifications/presentation/notification_inbox_screen.dart';
import '../../features/onboarding/application/onboarding_controller.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../config/feature_providers.dart';
import '../firebase/firebase_providers.dart';
import 'app_routes.dart';

/// Re-runs auth redirects when the Firebase session changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<User?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _sub;

  void refresh() => notifyListeners();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final features = ref.watch(appFeaturesProvider);
  final auth = features.authentication ? ref.watch(firebaseAuthProvider) : null;
  final routerRefresh = _AuthRefresh(
    auth?.authStateChanges() ?? const Stream<User?>.empty(),
  );
  ref.onDispose(routerRefresh.dispose);
  if (auth != null) {
    ref.listen(authControllerProvider, (_, _) => routerRefresh.refresh());
  }
  ref.listen(onboardingControllerProvider, (_, _) => routerRefresh.refresh());

  // Keep route registration conditional on the same feature configuration
  // used by navigation and providers; disabled modules must not be reachable
  // through a stale deep link.
  final routes = <RouteBase>[];
  routes.add(
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
  );
  if (features.authentication) {
    routes.addAll([
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.authAction,
        builder: (context, state) => EmailActionScreen(
          mode: state.uri.queryParameters['mode'],
          actionCode: state.uri.queryParameters['oobCode'],
        ),
      ),
      GoRoute(
        path: AppRoutes.firebaseAuthAction,
        builder: (context, state) => EmailActionScreen(
          mode: state.uri.queryParameters['mode'],
          actionCode: state.uri.queryParameters['oobCode'],
        ),
      ),
    ]);
  }

  if (features.settingsEnabled) {
    routes.add(
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    );
  }

  if (features.notificationInboxEnabled) {
    routes.addAll([
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationInboxScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.notifications}/:notificationId',
        builder: (context, state) => NotificationInboxScreen(
          notificationId: state.pathParameters['notificationId'],
        ),
      ),
    ]);
  }

  final branches = <StatefulShellBranch>[];
  if (features.home) {
    branches.add(
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      ),
    );
  }
  if (features.profileEnabled) {
    branches.add(
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    );
  }
  if (branches.isNotEmpty) {
    routes.add(
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: branches,
      ),
    );
  }

  final router = GoRouter(
    initialLocation: features.initialLocation,
    refreshListenable: routerRefresh,
    redirect: (context, state) {
      final onboardingComplete = ref.read(onboardingControllerProvider);
      final isEmailAction =
          state.matchedLocation == AppRoutes.authAction ||
          state.matchedLocation == AppRoutes.firebaseAuthAction;
      if (!onboardingComplete &&
          state.matchedLocation != AppRoutes.onboarding &&
          !isEmailAction) {
        return AppRoutes.onboarding;
      }
      if (onboardingComplete && state.matchedLocation == AppRoutes.onboarding) {
        return auth?.currentUser == null
            ? (features.authentication
                  ? AppRoutes.login
                  : features.initialLocation)
            : features.authenticatedLocation;
      }
      if (auth == null) return null;
      final user = auth.currentUser;
      if (user != null &&
          !user.emailVerified &&
          state.matchedLocation == AppRoutes.register &&
          ref.read(authControllerProvider).isLoading) {
        return null;
      }
      return AppRoutes.authRedirect(
        isLoggedIn: user != null,
        emailVerified: user?.emailVerified ?? false,
        location: state.matchedLocation,
        authenticatedLocation: features.authenticatedLocation,
        authenticatedLocations: {
          if (features.home) AppRoutes.home,
          if (features.profileEnabled) AppRoutes.profile,
          if (features.settingsEnabled) AppRoutes.settings,
        },
        requestedLocation: state.uri.queryParameters['redirect'],
        notificationInboxEnabled: features.notificationInboxEnabled,
      );
    },
    routes: routes,
  );
  ref.onDispose(router.dispose);
  if (features.pushNotificationsEnabled) {
    final pushClient = ref.watch(pushNotificationClientProvider);
    ref.watch(pushTokenRegistrarProvider);
    var disposed = false;
    final tapSubscription = pushClient.notificationTaps.listen((tap) {
      router.go(
        features.notificationInboxEnabled
            ? tap.location
            : features.authenticatedLocation,
      );
    });
    ref.onDispose(() {
      disposed = true;
      tapSubscription.cancel();
    });
    final initialTap = pushClient.takeInitialNotificationTap();
    if (initialTap != null) {
      scheduleMicrotask(() {
        if (!disposed) {
          router.go(
            features.notificationInboxEnabled
                ? initialTap.location
                : features.authenticatedLocation,
          );
        }
      });
    }
  }
  return router;
});

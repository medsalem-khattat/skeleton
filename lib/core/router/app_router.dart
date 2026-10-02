import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/notifications/data/push_notification_service.dart';
import '../../features/notifications/presentation/notification_inbox_screen.dart';
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
  final authRefresh = auth == null
      ? null
      : _AuthRefresh(auth.authStateChanges());
  if (authRefresh != null) ref.onDispose(authRefresh.dispose);
  if (authRefresh != null) {
    ref.listen(authControllerProvider, (_, _) => authRefresh.refresh());
  }

  final routes = <RouteBase>[];
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
    refreshListenable: authRefresh,
    redirect: (context, state) {
      if (auth == null) return null;
      final user = auth.currentUser;
      return AppRoutes.authRedirect(
        isLoggedIn: user != null,
        emailVerified: user?.emailVerified ?? false,
        location: state.matchedLocation,
        authenticatedLocation: features.authenticatedLocation,
        requestedLocation: state.uri.queryParameters['redirect'],
        notificationInboxEnabled: features.notificationInboxEnabled,
      );
    },
    routes: routes,
  );
  ref.onDispose(router.dispose);
  if (features.pushNotificationsEnabled) {
    final pushClient = ref.watch(pushNotificationClientProvider);
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

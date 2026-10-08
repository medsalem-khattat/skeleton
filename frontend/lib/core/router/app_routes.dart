class AppRoutes {
  static const onboarding = '/onboarding';
  static const authAction = '/auth/action';
  static const firebaseAuthAction = '/__/auth/action';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';

  static const home = '/home';
  static const profile = '/profile';
  static const settings = '/settings';
  static const notifications = '/notifications';

  static String notification(String notificationId) =>
      '$notifications/${Uri.encodeComponent(notificationId)}';

  /// Screens reachable without being signed in.
  static const authRoutes = <String>{login, register, forgotPassword};

  static String? authRedirect({
    required bool isLoggedIn,
    required bool emailVerified,
    required String location,
    String authenticatedLocation = home,
    Set<String> authenticatedLocations = const {home, profile, settings},
    String? requestedLocation,
    bool notificationInboxEnabled = true,
  }) {
    if (location == authAction ||
        location == firebaseAuthAction ||
        location == onboarding) {
      return null;
    }
    final onAuthScreen = authRoutes.contains(location);
    final onVerificationScreen = location == verifyEmail;
    final directNotificationDestination =
        location == notifications || location.startsWith('$notifications/');
    final destination = _validAuthenticatedLocation(
      requestedLocation ?? (directNotificationDestination ? location : null),
      authenticatedLocations: authenticatedLocations,
      notificationInboxEnabled: notificationInboxEnabled,
    );

    if (!isLoggedIn) {
      if (onAuthScreen && !onVerificationScreen) return null;
      return _authLocation(login, destination);
    }
    if (!emailVerified) {
      if (onVerificationScreen) return null;
      return _authLocation(verifyEmail, destination);
    }
    if (onAuthScreen || onVerificationScreen) {
      return destination ?? authenticatedLocation;
    }
    return null;
  }

  static String _authLocation(String route, String? destination) {
    if (destination == null) return route;
    return Uri(
      path: route,
      queryParameters: {'redirect': destination},
    ).toString();
  }

  static String? _validAuthenticatedLocation(
    String? candidate, {
    required Set<String> authenticatedLocations,
    required bool notificationInboxEnabled,
  }) {
    if (candidate == null) return null;
    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !uri.path.startsWith('/')) {
      return null;
    }
    if (authenticatedLocations.contains(uri.path)) {
      return uri.toString();
    }
    if (!notificationInboxEnabled) return null;
    if (uri.path == notifications) return uri.toString();
    final segments = uri.pathSegments;
    if (segments.length == 2 &&
        segments.first == notifications.substring(1) &&
        segments.last.isNotEmpty &&
        !segments.last.contains('/')) {
      return uri.toString();
    }
    return null;
  }
}

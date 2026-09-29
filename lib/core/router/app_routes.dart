class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';

  static const home = '/home';
  static const profile = '/profile';
  static const settings = '/settings';

  /// Screens reachable without being signed in.
  static const authRoutes = <String>{login, register, forgotPassword};

  static String? authRedirect({
    required bool isLoggedIn,
    required bool emailVerified,
    required String location,
  }) {
    final onAuthScreen = authRoutes.contains(location);
    final onVerificationScreen = location == verifyEmail;

    if (!isLoggedIn) {
      return onAuthScreen && !onVerificationScreen ? null : login;
    }
    if (!emailVerified) {
      return onVerificationScreen ? null : verifyEmail;
    }
    return onAuthScreen || onVerificationScreen ? home : null;
  }
}

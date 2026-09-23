class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const home = '/home';
  static const profile = '/profile';
  static const settings = '/settings';

  /// Screens reachable without being signed in.
  static const authRoutes = <String>{login, register, forgotPassword};
}

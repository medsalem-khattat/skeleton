// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get createAccount => 'Create account';

  @override
  String get fullName => 'Full name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get resetInstructions =>
      'Enter your email and we will send you a link to reset your password.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resetLinkSent => 'Password reset email sent. Check your inbox.';

  @override
  String get welcome => 'Welcome';

  @override
  String welcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String get dashboardProfileTitle => 'Your profile';

  @override
  String get dashboardProfileDescription =>
      'View and update your personal details.';

  @override
  String get dashboardSettingsTitle => 'App preferences';

  @override
  String get dashboardSettingsDescription => 'Choose your theme and language.';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get saveFailed => 'Could not save. Please try again.';

  @override
  String get profileLoadFailed => 'Could not load your profile.';

  @override
  String get retry => 'Try again';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get version => 'Version';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutQuestion => 'Log out?';

  @override
  String get logOutBody => 'You will need to sign in again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Use at least 6 characters';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get errorInvalidEmail => 'The email address is not valid.';

  @override
  String get errorUserDisabled => 'This account has been disabled.';

  @override
  String get errorWrongCredentials => 'Incorrect email or password.';

  @override
  String get errorEmailInUse => 'An account already exists for this email.';

  @override
  String get errorWeakPassword =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String get errorNetwork => 'No internet connection. Please try again.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please try again later.';

  @override
  String errorUnknownCode(String code) {
    return 'Something went wrong ($code).';
  }

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get accountSetupFailed =>
      'Your account was created, but profile setup did not finish. Sign in and complete your profile.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';
}

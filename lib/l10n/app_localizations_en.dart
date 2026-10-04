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
  String get phoneRegistrationInstructions =>
      'Verify your phone number with an SMS code to create your account.';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneNumberRequired => 'Phone number is required';

  @override
  String get phoneNumberInvalid =>
      'Enter a valid phone number with country code, such as +14155552671.';

  @override
  String get sendVerificationCode => 'Send verification code';

  @override
  String get resendVerificationCode => 'Resend verification code';

  @override
  String get smsVerificationCode => 'SMS verification code';

  @override
  String get phoneVerificationCodeRequired => 'Enter the verification code';

  @override
  String get phoneRegistrationRequired =>
      'Verify your phone number before creating your account.';

  @override
  String get phoneAutomaticallyVerified =>
      'Phone number verified automatically.';

  @override
  String get phoneVerificationCodeInvalid =>
      'That verification code is invalid. Check it and try again.';

  @override
  String get phoneVerificationExpired =>
      'That verification code expired. Request a new code.';

  @override
  String get phoneVerificationQuotaExceeded =>
      'SMS verification limit reached. Try again later.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String get verifyEmailInstructions =>
      'Before you can use the app, verify your email address using the link we sent you.';

  @override
  String get verificationEmailSent =>
      'Verification email sent. Check your inbox and spam folder.';

  @override
  String get resendVerificationEmail => 'Resend verification email';

  @override
  String get checkVerificationStatus => 'I\'ve verified my email';

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
  String get onboardingWelcomeTitle => 'A clearer place to get started';

  @override
  String get onboardingWelcomeBody =>
      'Find the essential account and app features in one simple place.';

  @override
  String get onboardingSecurityTitle => 'Your account, protected';

  @override
  String get onboardingSecurityBody =>
      'Verify your email, review account security, and manage your devices from Settings.';

  @override
  String get onboardingControlTitle => 'Make the app yours';

  @override
  String get onboardingControlBody =>
      'Choose your appearance, language, notifications, and profile details when you are ready.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingSaveFailed =>
      'Could not save your onboarding choice. Please try again.';

  @override
  String onboardingPageSemantics(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String welcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String get openMenu => 'Open menu';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get deviceAuthTitle => 'Device authentication';

  @override
  String get deviceAuthDescription =>
      'Require your device unlock when opening the app or returning after 1 minute away.';

  @override
  String get deviceAuthReason => 'Unlock Skeleton';

  @override
  String get deviceAuthUnavailable =>
      'Set up a device PIN, pattern, password, or biometrics to use this feature.';

  @override
  String get deviceAuthFailed =>
      'Authentication was not completed. Try again to unlock the app.';

  @override
  String get deviceAuthSaveFailed =>
      'Could not update device authentication. Please try again.';

  @override
  String get deviceAuthLocked => 'Unlock to continue';

  @override
  String get deviceAuthUnlock => 'Unlock';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get changeProfilePhoto => 'Change photo';

  @override
  String get removeProfilePhoto => 'Remove photo';

  @override
  String get profilePhotoUpdated => 'Profile photo updated.';

  @override
  String get profilePhotoRemoved => 'Profile photo removed.';

  @override
  String get profilePhotoTooLarge => 'Choose an image smaller than 5 MB.';

  @override
  String get profilePhotoCleanupFailed =>
      'Your new photo is active, but an older photo could not be removed.';

  @override
  String get profilePhotoRemovalCleanupFailed =>
      'Your photo was removed from the profile, but its stored image could not be deleted.';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get saveFailed => 'Could not save. Please try again.';

  @override
  String get profileSyncFailed =>
      'The profile update could not be completed and account data may be out of sync. Please try again.';

  @override
  String get profileLoadFailed => 'Could not load your profile.';

  @override
  String get retry => 'Try again';

  @override
  String get accountSecurity => 'Account security';

  @override
  String get accountSecurityDescription =>
      'Manage sign-in details and app lock.';

  @override
  String get signOutAllSessions => 'Sign out all devices';

  @override
  String get signOutAllSessionsDescription =>
      'Revoke sessions on all devices, including this one. Other devices may remain active for up to one hour.';

  @override
  String get signOutAllSessionsConfirmation =>
      'All sessions will be revoked. This device signs out now; other devices may retain access for up to one hour. You will need to sign in again.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountDescription =>
      'Permanently delete your account and its data.';

  @override
  String get deleteAccountConfirmation =>
      'This permanently deletes your account, profile, notifications, and stored devices. This cannot be undone.';

  @override
  String get accountActionFailed =>
      'The account action could not be completed. Please try again.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get accountDataExport => 'Export your account data';

  @override
  String get accountDataExportDescription =>
      'Create a JSON copy of your profile and notifications.';

  @override
  String get accountDataExportFailed =>
      'Could not create or share your data export. Please try again.';

  @override
  String get authActionTitle => 'Account email action';

  @override
  String get authActionInstructions =>
      'Complete this account action in the app.';

  @override
  String get authActionInvalidLink =>
      'This link is invalid, expired, or already used. Request a new email and try again.';

  @override
  String get authActionVerified => 'Your email address is verified.';

  @override
  String get authActionPasswordChanged => 'Your password has been reset.';

  @override
  String get authActionEmailRecovered =>
      'Your previous email address has been restored.';

  @override
  String get authActionContinue => 'Continue';

  @override
  String get authActionSubmit => 'Update password';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get supportEmailSubject => 'Support request';

  @override
  String get externalLinkFailed => 'Could not open this link on your device.';

  @override
  String get confirm => 'Confirm';

  @override
  String get changePassword => 'Change password';

  @override
  String get changeEmail => 'Change email';

  @override
  String get changePhoneNumber => 'Change mobile number';

  @override
  String get phoneChangeInstructions =>
      'Enter your new mobile number. We will verify it with an SMS code.';

  @override
  String get phoneNumberNotSet => 'No mobile number added';

  @override
  String get phoneNumberUnchanged =>
      'Enter a mobile number different from your current one.';

  @override
  String get phoneNumberChanged => 'Mobile number updated successfully.';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get newEmail => 'New email';

  @override
  String get passwordChanged => 'Password changed successfully.';

  @override
  String get emailVerificationSent =>
      'A verification link was sent to your new email. Your email changes after you verify it.';

  @override
  String get emailUnchanged =>
      'Enter an email address different from your current one.';

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
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'French';

  @override
  String get notificationsTitle => 'Push notifications';

  @override
  String get notificationPermissionTitle => 'Device notification permission';

  @override
  String get notificationsAccountEnabled =>
      'This account can send push notifications to your devices.';

  @override
  String get notificationsAccountDisabled =>
      'Push notifications are turned off for this account.';

  @override
  String get notificationsPreferenceLoadFailed =>
      'Could not load your notification preference.';

  @override
  String get notificationsPreferenceSaveFailed =>
      'Could not save your notification preference.';

  @override
  String get closeNotifications => 'Close notifications';

  @override
  String get notificationsEnabled => 'Notifications are enabled.';

  @override
  String get notificationsDenied =>
      'Permission denied. Enable notifications in your device settings.';

  @override
  String get notificationsNotEnabled =>
      'Allow notifications to receive updates.';

  @override
  String get notificationsEnable => 'Enable';

  @override
  String get notificationsStatusFailed =>
      'Could not check notification permissions.';

  @override
  String get notificationsRequestFailed =>
      'Could not request notification permissions. Please try again.';

  @override
  String get notificationsEmpty => 'You don\'t have any notifications yet.';

  @override
  String get notificationsLoadFailed => 'Could not load your notifications.';

  @override
  String get passwordChangedNotificationTitle => 'Password changed';

  @override
  String get passwordChangedNotificationBody =>
      'Your account password was changed successfully.';

  @override
  String get passwordChangedNotificationFailed =>
      'Your password changed, but we couldn\'t save the notification.';

  @override
  String get notificationJustNow => 'Just now';

  @override
  String get markNotificationRead => 'Mark as read';

  @override
  String get notificationMarkReadFailed =>
      'Could not mark this notification as read.';

  @override
  String get notificationRead => 'Read';

  @override
  String get notificationUnread => 'Unread';

  @override
  String get notificationNotFound =>
      'This notification is no longer available.';

  @override
  String get closeNotification => 'Close notification';

  @override
  String notificationUnreadCount(int count) {
    return '$count unread notifications';
  }

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
  String get errorRecentLogin =>
      'Please check your current password and try again.';

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
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';
}

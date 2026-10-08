import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @phoneRegistrationInstructions.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone number with an SMS code to create your account.'**
  String get phoneRegistrationInstructions;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// No description provided for @phoneNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number with country code, such as +14155552671.'**
  String get phoneNumberInvalid;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send verification code'**
  String get sendVerificationCode;

  /// No description provided for @resendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Resend verification code'**
  String get resendVerificationCode;

  /// No description provided for @smsVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'SMS verification code'**
  String get smsVerificationCode;

  /// No description provided for @phoneVerificationCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get phoneVerificationCodeRequired;

  /// No description provided for @phoneRegistrationRequired.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone number before creating your account.'**
  String get phoneRegistrationRequired;

  /// No description provided for @phoneAutomaticallyVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified automatically.'**
  String get phoneAutomaticallyVerified;

  /// No description provided for @phoneVerificationCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That verification code is invalid. Check it and try again.'**
  String get phoneVerificationCodeInvalid;

  /// No description provided for @phoneVerificationExpired.
  ///
  /// In en, this message translates to:
  /// **'That verification code expired. Request a new code.'**
  String get phoneVerificationExpired;

  /// No description provided for @phoneVerificationQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'SMS verification limit reached. Try again later.'**
  String get phoneVerificationQuotaExceeded;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailInstructions.
  ///
  /// In en, this message translates to:
  /// **'Before you can use the app, verify your email address using the link we sent you.'**
  String get verifyEmailInstructions;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Check your inbox and spam folder.'**
  String get verificationEmailSent;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerificationEmail;

  /// No description provided for @checkVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified my email'**
  String get checkVerificationStatus;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a link to reset your password.'**
  String get resetInstructions;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get resetLinkSent;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @forceUpdateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for required updates…'**
  String get forceUpdateChecking;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'Update to version {version} to continue using the app.'**
  String forceUpdateMessage(String version);

  /// No description provided for @forceUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get forceUpdateAction;

  /// No description provided for @forceUpdateStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open the app store. Please try again.'**
  String get forceUpdateStoreUnavailable;

  /// No description provided for @forceUpdateCheckFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update check unavailable'**
  String get forceUpdateCheckFailedTitle;

  /// No description provided for @forceUpdateCheckFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not verify this app version. Check your connection and try again.'**
  String get forceUpdateCheckFailedMessage;

  /// No description provided for @forceUpdateRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get forceUpdateRetry;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'A clearer place to get started'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Find the essential account and app features in one simple place.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account, protected'**
  String get onboardingSecurityTitle;

  /// No description provided for @onboardingSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'Verify your email, review account security, and manage your devices from Settings.'**
  String get onboardingSecurityBody;

  /// No description provided for @onboardingControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Make the app yours'**
  String get onboardingControlTitle;

  /// No description provided for @onboardingControlBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your appearance, language, notifications, and profile details when you are ready.'**
  String get onboardingControlBody;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your onboarding choice. Please try again.'**
  String get onboardingSaveFailed;

  /// No description provided for @onboardingPageSemantics.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String onboardingPageSemantics(int current, int total);

  /// No description provided for @welcomeName.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeName(String name);

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenu;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @deviceAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Device authentication'**
  String get deviceAuthTitle;

  /// No description provided for @deviceAuthDescription.
  ///
  /// In en, this message translates to:
  /// **'Require your device unlock when opening the app or returning after 1 minute away.'**
  String get deviceAuthDescription;

  /// No description provided for @deviceAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Skeleton'**
  String get deviceAuthReason;

  /// No description provided for @deviceAuthUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Set up a device PIN, pattern, password, or biometrics to use this feature.'**
  String get deviceAuthUnavailable;

  /// No description provided for @deviceAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication was not completed. Try again to unlock the app.'**
  String get deviceAuthFailed;

  /// No description provided for @deviceAuthSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update device authentication. Please try again.'**
  String get deviceAuthSaveFailed;

  /// No description provided for @deviceAuthLocked.
  ///
  /// In en, this message translates to:
  /// **'Unlock to continue'**
  String get deviceAuthLocked;

  /// No description provided for @deviceAuthUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get deviceAuthUnlock;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changeProfilePhoto;

  /// No description provided for @removeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removeProfilePhoto;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed.'**
  String get profilePhotoRemoved;

  /// No description provided for @profilePhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Choose an image smaller than 5 MB.'**
  String get profilePhotoTooLarge;

  /// No description provided for @profilePhotoCleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Your new photo is active, but an older photo could not be removed.'**
  String get profilePhotoCleanupFailed;

  /// No description provided for @profilePhotoRemovalCleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Your photo was removed from the profile, but its stored image could not be deleted.'**
  String get profilePhotoRemovalCleanupFailed;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get saveFailed;

  /// No description provided for @profileSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'The profile update could not be completed and account data may be out of sync. Please try again.'**
  String get profileSyncFailed;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile.'**
  String get profileLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account security'**
  String get accountSecurity;

  /// No description provided for @accountSecurityDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage sign-in details and app lock.'**
  String get accountSecurityDescription;

  /// No description provided for @signOutAllSessions.
  ///
  /// In en, this message translates to:
  /// **'Sign out all devices'**
  String get signOutAllSessions;

  /// No description provided for @signOutAllSessionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Revoke sessions on all devices, including this one. Other devices may remain active for up to one hour.'**
  String get signOutAllSessionsDescription;

  /// No description provided for @signOutAllSessionsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'All sessions will be revoked. This device signs out now; other devices may retain access for up to one hour. You will need to sign in again.'**
  String get signOutAllSessionsConfirmation;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and its data.'**
  String get deleteAccountDescription;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, profile, notifications, and stored devices. This cannot be undone.'**
  String get deleteAccountConfirmation;

  /// No description provided for @accountActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The account action could not be completed. Please try again.'**
  String get accountActionFailed;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @accountDataExport.
  ///
  /// In en, this message translates to:
  /// **'Export your account data'**
  String get accountDataExport;

  /// No description provided for @accountDataExportDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a JSON copy of your profile and notifications.'**
  String get accountDataExportDescription;

  /// No description provided for @accountDataExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create or share your data export. Please try again.'**
  String get accountDataExportFailed;

  /// No description provided for @authActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account email action'**
  String get authActionTitle;

  /// No description provided for @authActionInstructions.
  ///
  /// In en, this message translates to:
  /// **'Complete this account action in the app.'**
  String get authActionInstructions;

  /// No description provided for @authActionInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'This link is invalid, expired, or already used. Request a new email and try again.'**
  String get authActionInvalidLink;

  /// No description provided for @authActionVerified.
  ///
  /// In en, this message translates to:
  /// **'Your email address is verified.'**
  String get authActionVerified;

  /// No description provided for @authActionPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset.'**
  String get authActionPasswordChanged;

  /// No description provided for @authActionEmailRecovered.
  ///
  /// In en, this message translates to:
  /// **'Your previous email address has been restored.'**
  String get authActionEmailRecovered;

  /// No description provided for @authActionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authActionContinue;

  /// No description provided for @authActionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get authActionSubmit;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @supportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Support request'**
  String get supportEmailSubject;

  /// No description provided for @externalLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link on your device.'**
  String get externalLinkFailed;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change mobile number'**
  String get changePhoneNumber;

  /// No description provided for @phoneChangeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your new mobile number. We will verify it with an SMS code.'**
  String get phoneChangeInstructions;

  /// No description provided for @phoneNumberNotSet.
  ///
  /// In en, this message translates to:
  /// **'No mobile number added'**
  String get phoneNumberNotSet;

  /// No description provided for @phoneNumberUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Enter a mobile number different from your current one.'**
  String get phoneNumberUnchanged;

  /// No description provided for @phoneNumberChanged.
  ///
  /// In en, this message translates to:
  /// **'Mobile number updated successfully.'**
  String get phoneNumberChanged;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @newEmail.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get newEmail;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get passwordChanged;

  /// No description provided for @emailVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'A verification link was sent to your new email. Your email changes after you verify it.'**
  String get emailVerificationSent;

  /// No description provided for @emailUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address different from your current one.'**
  String get emailUnchanged;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Device notification permission'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationsAccountEnabled.
  ///
  /// In en, this message translates to:
  /// **'This account can send push notifications to your devices.'**
  String get notificationsAccountEnabled;

  /// No description provided for @notificationsAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'Push notifications are turned off for this account.'**
  String get notificationsAccountDisabled;

  /// No description provided for @notificationsPreferenceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your notification preference.'**
  String get notificationsPreferenceLoadFailed;

  /// No description provided for @notificationsPreferenceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your notification preference.'**
  String get notificationsPreferenceSaveFailed;

  /// No description provided for @closeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Close notifications'**
  String get closeNotifications;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are enabled.'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Enable notifications in your device settings.'**
  String get notificationsDenied;

  /// No description provided for @notificationsNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to receive updates.'**
  String get notificationsNotEnabled;

  /// No description provided for @notificationsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get notificationsEnable;

  /// No description provided for @notificationsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check notification permissions.'**
  String get notificationsStatusFailed;

  /// No description provided for @notificationsRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not request notification permissions. Please try again.'**
  String get notificationsRequestFailed;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your notifications.'**
  String get notificationsLoadFailed;

  /// No description provided for @passwordChangedNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChangedNotificationTitle;

  /// No description provided for @passwordChangedNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your account password was changed successfully.'**
  String get passwordChangedNotificationBody;

  /// No description provided for @passwordChangedNotificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Your password changed, but we couldn\'t save the notification.'**
  String get passwordChangedNotificationFailed;

  /// No description provided for @notificationJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationJustNow;

  /// No description provided for @markNotificationRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markNotificationRead;

  /// No description provided for @notificationMarkReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not mark this notification as read.'**
  String get notificationMarkReadFailed;

  /// No description provided for @notificationRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationRead;

  /// No description provided for @notificationUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationUnread;

  /// No description provided for @notificationNotFound.
  ///
  /// In en, this message translates to:
  /// **'This notification is no longer available.'**
  String get notificationNotFound;

  /// No description provided for @closeNotification.
  ///
  /// In en, this message translates to:
  /// **'Close notification'**
  String get closeNotification;

  /// No description provided for @notificationUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread notifications'**
  String notificationUnreadCount(int count);

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutQuestion;

  /// No description provided for @logOutBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again.'**
  String get logOutBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'The email address is not valid.'**
  String get errorInvalidEmail;

  /// No description provided for @errorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get errorUserDisabled;

  /// No description provided for @errorWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorWrongCredentials;

  /// No description provided for @errorRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please check your current password and try again.'**
  String get errorRecentLogin;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email.'**
  String get errorEmailInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 6 characters.'**
  String get errorWeakPassword;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please try again.'**
  String get errorNetwork;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorUnknownCode.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong ({code}).'**
  String errorUnknownCode(String code);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

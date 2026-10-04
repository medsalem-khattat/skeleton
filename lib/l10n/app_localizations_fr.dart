// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get signInToContinue => 'Connectez-vous pour continuer';

  @override
  String get phoneRegistrationInstructions =>
      'Vérifiez votre numéro de téléphone avec un code SMS pour créer votre compte.';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get phoneNumberRequired => 'Le numéro de téléphone est obligatoire';

  @override
  String get phoneNumberInvalid =>
      'Saisissez un numéro valide avec l\'indicatif du pays, par exemple +14155552671.';

  @override
  String get sendVerificationCode => 'Envoyer le code de vérification';

  @override
  String get resendVerificationCode => 'Renvoyer le code de vérification';

  @override
  String get smsVerificationCode => 'Code de vérification SMS';

  @override
  String get phoneVerificationCodeRequired =>
      'Saisissez le code de vérification';

  @override
  String get phoneRegistrationRequired =>
      'Vérifiez votre numéro de téléphone avant de créer votre compte.';

  @override
  String get phoneAutomaticallyVerified =>
      'Numéro de téléphone vérifié automatiquement.';

  @override
  String get phoneVerificationCodeInvalid =>
      'Ce code de vérification est invalide. Vérifiez-le puis réessayez.';

  @override
  String get phoneVerificationExpired =>
      'Ce code de vérification a expiré. Demandez un nouveau code.';

  @override
  String get phoneVerificationQuotaExceeded =>
      'La limite de vérification par SMS est atteinte. Réessayez plus tard.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get verifyEmailTitle => 'Vérifiez votre adresse e-mail';

  @override
  String get verifyEmailInstructions =>
      'Avant d’utiliser l’application, vérifiez votre adresse e-mail avec le lien que nous vous avons envoyé.';

  @override
  String get verificationEmailSent =>
      'E-mail de vérification envoyé. Vérifiez votre boîte de réception et vos courriers indésirables.';

  @override
  String get resendVerificationEmail => 'Renvoyer l’e-mail de vérification';

  @override
  String get checkVerificationStatus => 'J’ai vérifié mon adresse e-mail';

  @override
  String get createAnAccount => 'Créer un compte';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get fullName => 'Nom complet';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get haveAccount => 'J’ai déjà un compte';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get resetInstructions =>
      'Saisissez votre e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe.';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get resetLinkSent =>
      'E-mail de réinitialisation envoyé. Vérifiez votre boîte de réception.';

  @override
  String get welcome => 'Bienvenue';

  @override
  String welcomeName(String name) {
    return 'Bienvenue, $name';
  }

  @override
  String get openMenu => 'Ouvrir le menu';

  @override
  String get home => 'Accueil';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get deviceAuthTitle => 'Authentification de l’appareil';

  @override
  String get deviceAuthDescription =>
      'Demander le déverrouillage de l’appareil à l’ouverture ou après une minute d’absence.';

  @override
  String get deviceAuthReason => 'Déverrouiller Skeleton';

  @override
  String get deviceAuthUnavailable =>
      'Configurez un code PIN, un schéma, un mot de passe ou une biométrie sur votre appareil pour utiliser cette fonctionnalité.';

  @override
  String get deviceAuthFailed =>
      'L’authentification n’a pas abouti. Réessayez pour déverrouiller l’application.';

  @override
  String get deviceAuthSaveFailed =>
      'Impossible de modifier l’authentification de l’appareil. Veuillez réessayer.';

  @override
  String get deviceAuthLocked => 'Déverrouillez pour continuer';

  @override
  String get deviceAuthUnlock => 'Déverrouiller';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get profileUpdated => 'Profil mis à jour';

  @override
  String get saveFailed => 'Échec de l’enregistrement. Veuillez réessayer.';

  @override
  String get profileSyncFailed =>
      'La mise à jour du profil n’a pas abouti et les données du compte peuvent être désynchronisées. Veuillez réessayer.';

  @override
  String get profileLoadFailed => 'Impossible de charger votre profil.';

  @override
  String get retry => 'Réessayer';

  @override
  String get accountSecurity => 'Sécurité du compte';

  @override
  String get accountSecurityDescription =>
      'Gérez vos identifiants et le verrouillage de l’application.';

  @override
  String get signOutAllSessions => 'Déconnecter tous les appareils';

  @override
  String get signOutAllSessionsDescription =>
      'Révoquer les sessions sur tous les appareils, y compris celui-ci. Les autres appareils peuvent rester actifs jusqu’à une heure.';

  @override
  String get signOutAllSessionsConfirmation =>
      'Toutes les sessions seront révoquées. Cet appareil sera déconnecté immédiatement ; les autres peuvent conserver l’accès pendant une heure. Vous devrez vous reconnecter.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountDescription =>
      'Supprimer définitivement votre compte et ses données.';

  @override
  String get deleteAccountConfirmation =>
      'Votre compte, votre profil, vos notifications et vos appareils enregistrés seront définitivement supprimés. Cette action est irréversible.';

  @override
  String get accountActionFailed =>
      'L’action sur le compte n’a pas abouti. Veuillez réessayer.';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d’utilisation';

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get supportEmailSubject => 'Demande d’assistance';

  @override
  String get externalLinkFailed =>
      'Impossible d’ouvrir ce lien sur votre appareil.';

  @override
  String get confirm => 'Confirmer';

  @override
  String get changePassword => 'Modifier le mot de passe';

  @override
  String get changeEmail => 'Modifier l’adresse e-mail';

  @override
  String get changePhoneNumber => 'Modifier le numéro de mobile';

  @override
  String get phoneChangeInstructions =>
      'Saisissez votre nouveau numéro de mobile. Nous le vérifierons avec un code SMS.';

  @override
  String get phoneNumberNotSet => 'Aucun numéro de mobile ajouté';

  @override
  String get phoneNumberUnchanged =>
      'Saisissez un numéro de mobile différent de votre numéro actuel.';

  @override
  String get phoneNumberChanged => 'Le numéro de mobile a été mis à jour.';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get newEmail => 'Nouvelle adresse e-mail';

  @override
  String get passwordChanged => 'Le mot de passe a été modifié.';

  @override
  String get emailVerificationSent =>
      'Un lien de vérification a été envoyé à votre nouvelle adresse. Le changement sera appliqué après vérification.';

  @override
  String get emailUnchanged =>
      'Saisissez une adresse différente de votre adresse actuelle.';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Système';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageFrench => 'Français';

  @override
  String get notificationsTitle => 'Notifications push';

  @override
  String get notificationPermissionTitle =>
      'Autorisation de notification de l’appareil';

  @override
  String get notificationsAccountEnabled =>
      'Ce compte peut envoyer des notifications push à vos appareils.';

  @override
  String get notificationsAccountDisabled =>
      'Les notifications push sont désactivées pour ce compte.';

  @override
  String get notificationsPreferenceLoadFailed =>
      'Impossible de charger votre préférence de notification.';

  @override
  String get notificationsPreferenceSaveFailed =>
      'Impossible d’enregistrer votre préférence de notification.';

  @override
  String get closeNotifications => 'Fermer les notifications';

  @override
  String get notificationsEnabled => 'Les notifications sont activées.';

  @override
  String get notificationsDenied =>
      'Autorisation refusée. Activez les notifications dans les paramètres de votre appareil.';

  @override
  String get notificationsNotEnabled =>
      'Autorisez les notifications pour recevoir des mises à jour.';

  @override
  String get notificationsEnable => 'Activer';

  @override
  String get notificationsStatusFailed =>
      'Impossible de vérifier les autorisations de notification.';

  @override
  String get notificationsRequestFailed =>
      'Impossible de demander l’autorisation de notification. Veuillez réessayer.';

  @override
  String get notificationsEmpty => 'Vous n’avez pas encore de notification.';

  @override
  String get notificationsLoadFailed =>
      'Impossible de charger vos notifications.';

  @override
  String get passwordChangedNotificationTitle => 'Mot de passe modifié';

  @override
  String get passwordChangedNotificationBody =>
      'Le mot de passe de votre compte a été modifié.';

  @override
  String get passwordChangedNotificationFailed =>
      'Votre mot de passe a été modifié, mais la notification n’a pas pu être enregistrée.';

  @override
  String get notificationJustNow => 'À l’instant';

  @override
  String get markNotificationRead => 'Marquer comme lue';

  @override
  String get notificationMarkReadFailed =>
      'Impossible de marquer cette notification comme lue.';

  @override
  String get notificationRead => 'Lue';

  @override
  String get notificationUnread => 'Non lue';

  @override
  String get notificationNotFound =>
      'Cette notification n’est plus disponible.';

  @override
  String get closeNotification => 'Fermer la notification';

  @override
  String notificationUnreadCount(int count) {
    return '$count notifications non lues';
  }

  @override
  String get version => 'Version';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String get logOutQuestion => 'Se déconnecter ?';

  @override
  String get logOutBody => 'Vous devrez vous reconnecter.';

  @override
  String get cancel => 'Annuler';

  @override
  String get emailRequired => 'L’e-mail est obligatoire';

  @override
  String get emailInvalid => 'Saisissez un e-mail valide';

  @override
  String get passwordRequired => 'Le mot de passe est obligatoire';

  @override
  String get passwordTooShort => 'Utilisez au moins 6 caractères';

  @override
  String get nameRequired => 'Le nom est obligatoire';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get errorInvalidEmail => 'L’adresse e-mail n’est pas valide.';

  @override
  String get errorUserDisabled => 'Ce compte a été désactivé.';

  @override
  String get errorWrongCredentials => 'E-mail ou mot de passe incorrect.';

  @override
  String get errorRecentLogin =>
      'Vérifiez votre mot de passe actuel et réessayez.';

  @override
  String get errorEmailInUse => 'Un compte existe déjà avec cet e-mail.';

  @override
  String get errorWeakPassword =>
      'Mot de passe trop faible. Utilisez au moins 6 caractères.';

  @override
  String get errorNetwork => 'Pas de connexion Internet. Veuillez réessayer.';

  @override
  String get errorTooManyAttempts => 'Trop de tentatives. Réessayez plus tard.';

  @override
  String errorUnknownCode(String code) {
    return 'Un problème est survenu ($code).';
  }

  @override
  String get errorGeneric => 'Un problème est survenu. Veuillez réessayer.';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';
}

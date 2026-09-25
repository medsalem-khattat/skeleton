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
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

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
  String get dashboardProfileTitle => 'Votre profil';

  @override
  String get dashboardProfileDescription =>
      'Consultez et modifiez vos informations personnelles.';

  @override
  String get dashboardSettingsTitle => 'Préférences de l’application';

  @override
  String get dashboardSettingsDescription =>
      'Choisissez votre thème et votre langue.';

  @override
  String get home => 'Accueil';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get profileUpdated => 'Profil mis à jour';

  @override
  String get saveFailed => 'Échec de l’enregistrement. Veuillez réessayer.';

  @override
  String get profileLoadFailed => 'Impossible de charger votre profil.';

  @override
  String get retry => 'Réessayer';

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
  String get accountSetupFailed =>
      'Votre compte a été créé, mais la configuration du profil a échoué. Connectez-vous et complétez votre profil.';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';
}

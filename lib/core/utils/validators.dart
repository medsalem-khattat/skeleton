import '../../l10n/app_localizations.dart';

/// Each validator takes the current [AppLocalizations] and returns
/// a function you can pass straight to a form field's `validator:`.
class Validators {
  static String? Function(String?) email(AppLocalizations l10n) {
    return (value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return l10n.emailRequired;
      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
      return ok ? null : l10n.emailInvalid;
    };
  }

  static String? Function(String?) password(AppLocalizations l10n) {
    return (value) {
      if (value == null || value.isEmpty) return l10n.passwordRequired;
      if (value.length < 6) return l10n.passwordTooShort;
      return null;
    };
  }

  static String? Function(String?) nameRequired(AppLocalizations l10n) {
    return (value) {
      if (value == null || value.trim().isEmpty) return l10n.nameRequired;
      return null;
    };
  }
}

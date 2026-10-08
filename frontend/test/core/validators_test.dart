import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/utils/validators.dart';
import 'package:skeleton/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('Validators.email', () {
    final validate = Validators.email(l10n);

    test('rejects empty and malformed emails', () {
      expect(validate(null), 'Email is required');
      expect(validate('  '), 'Email is required');
      expect(validate('not-an-email'), 'Enter a valid email');
      expect(validate('a@b'), 'Enter a valid email');
    });

    test('accepts a valid email', () {
      expect(validate('user@example.com'), isNull);
      expect(validate('  user@example.com  '), isNull);
    });
  });

  group('Validators.password', () {
    final validate = Validators.password(l10n);

    test('rejects empty and short passwords', () {
      expect(validate(null), 'Password is required');
      expect(validate(''), 'Password is required');
      expect(validate('12345'), 'Use at least 6 characters');
    });

    test('accepts 6+ characters', () {
      expect(validate('123456'), isNull);
    });
  });

  group('Validators.nameRequired', () {
    final validate = Validators.nameRequired(l10n);

    test('rejects blank values', () {
      expect(validate('  '), 'Name is required');
      expect(validate(null), 'Name is required');
    });

    test('accepts non-empty values', () {
      expect(validate('Sam'), isNull);
    });
  });

  test('messages are translated', () {
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(Validators.email(fr)(''), fr.emailRequired);
    expect(fr.emailRequired, isNot(l10n.emailRequired));
  });
}

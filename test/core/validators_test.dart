import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty and malformed emails', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('  '), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });

    test('accepts a valid email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('  user@example.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty and short passwords', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), isNotNull);
    });

    test('accepts 6+ characters', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.required', () {
    test('rejects blank values and uses the label', () {
      expect(Validators.required('  ', 'Name'), 'Name is required');
      expect(Validators.required(null), 'This field is required');
    });

    test('accepts non-empty values', () {
      expect(Validators.required('Sam'), isNull);
    });
  });
}

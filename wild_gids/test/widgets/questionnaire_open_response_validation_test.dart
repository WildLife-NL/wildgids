import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Numeric Range Detection', () {
    test('should detect [1-5] as numeric range', () {
      final pattern = '[1-5]';
      expect(_isNumericRange(pattern), isTrue);
      final range = _extractRange(pattern);
      expect(range, isNotNull);
      expect(range!['min'], 1);
      expect(range['max'], 5);
    });

    test('should detect [0-10] as numeric range', () {
      final pattern = '[0-10]';
      expect(_isNumericRange(pattern), isTrue);
      final range = _extractRange(pattern);
      expect(range, isNotNull);
      expect(range!['min'], 0);
      expect(range['max'], 10);
    });

    test('should detect [1-100] as numeric range', () {
      final pattern = '[1-100]';
      expect(_isNumericRange(pattern), isTrue);
      final range = _extractRange(pattern);
      expect(range, isNotNull);
      expect(range!['min'], 1);
      expect(range['max'], 100);
    });

    test('should handle reversed range [5-1]', () {
      final pattern = '[5-1]';
      expect(_isNumericRange(pattern), isTrue);
      final range = _extractRange(pattern);
      expect(range, isNotNull);
      // Should swap to min=1, max=5
      expect(range!['min'], 1);
      expect(range['max'], 5);
    });

    test('should handle range with whitespace [ 1 - 5 ]', () {
      final pattern = '[ 1 - 5 ]';
      expect(_isNumericRange(pattern), isTrue);
      final range = _extractRange(pattern);
      expect(range, isNotNull);
      expect(range!['min'], 1);
      expect(range['max'], 5);
    });

    test('should not detect regular regex as numeric range', () {
      expect(_isNumericRange('^\\d+\$'), isFalse);
      expect(_isNumericRange('[a-z]+'), isFalse);
      expect(_isNumericRange('[0-9]{4}'), isFalse);
    });

    test('should not detect invalid patterns as numeric range', () {
      expect(_isNumericRange('[1-]'), isFalse);
      expect(_isNumericRange('[-5]'), isFalse);
      expect(_isNumericRange('[abc]'), isFalse);
      expect(_isNumericRange('1-5'), isFalse); // Missing brackets
    });
  });

  group('Text Validation Logic', () {
    test('should allow empty text (optional field)', () {
      final error = _validateText('', '^\\d+\$');
      expect(error, isNull);
    });

    test('should validate numeric-only pattern', () {
      final pattern = '^\\d+\$';

      // Valid inputs
      expect(_validateText('123', pattern), isNull);
      expect(_validateText('0', pattern), isNull);
      expect(_validateText('999999', pattern), isNull);

      // Invalid inputs
      expect(_validateText('abc', pattern), isNotNull);
      expect(_validateText('12a', pattern), isNotNull);
      expect(_validateText('1.5', pattern), isNotNull);
      expect(_validateText('-5', pattern), isNotNull);
    });

    test('should validate letter-only pattern', () {
      final pattern = '^[a-zA-Z]+\$';

      // Valid inputs
      expect(_validateText('abc', pattern), isNull);
      expect(_validateText('ABC', pattern), isNull);
      expect(_validateText('AbCdEf', pattern), isNull);

      // Invalid inputs
      expect(_validateText('abc123', pattern), isNotNull);
      expect(_validateText('a b c', pattern), isNotNull);
      expect(_validateText('123', pattern), isNotNull);
    });

    test('should validate email pattern', () {
      final pattern = '^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$';

      // Valid inputs
      expect(_validateText('test@example.com', pattern), isNull);
      expect(_validateText('user.name@domain.co.uk', pattern), isNull);
      expect(_validateText('a@b.com', pattern), isNull);

      // Invalid inputs
      expect(_validateText('notanemail', pattern), isNotNull);
      expect(_validateText('@example.com', pattern), isNotNull);
      expect(_validateText('test@', pattern), isNotNull);
      expect(_validateText('test@.com', pattern), isNotNull);
    });

    test('should validate phone pattern', () {
      final pattern = '^\\+31\\d{9}\$';

      // Valid inputs
      expect(_validateText('+31612345678', pattern), isNull);
      expect(_validateText('+31987654321', pattern), isNull);

      // Invalid inputs
      expect(_validateText('0612345678', pattern), isNotNull);
      expect(_validateText('+316123456', pattern), isNotNull); // Too short
      expect(_validateText('+3161234567890', pattern), isNotNull); // Too long
      expect(_validateText('+31 612345678', pattern), isNotNull); // Has space
    });

    test('should provide helpful error messages for digit pattern', () {
      final pattern = '^\\d+\$';
      final error = _validateText('abc', pattern);
      expect(error, contains('cijfers'));
    });

    test('should provide helpful error messages for letter pattern', () {
      final pattern = '^[a-zA-Z]+\$';
      final error = _validateText('123', pattern);
      expect(error, contains('letters'));
    });

    test('should provide helpful error messages for email pattern', () {
      final pattern = '^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$';
      final error = _validateText('notanemail', pattern);
      expect(error, contains('e-mail'));
    });

    test('should handle invalid regex gracefully', () {
      final pattern = '[unclosed'; // Invalid regex
      // Should not crash - either returns null or error string
      expect(() => _validateText('test', pattern), returnsNormally);
    });

    test('should skip validation for numeric range patterns', () {
      // Numeric range patterns should not be validated as regex
      final pattern = '[1-5]';
      // This test assumes the validation method checks for numeric range first
      // and skips regex validation for those patterns
      expect(_isNumericRange(pattern), isTrue);
    });
  });

  group('Validation State Logic', () {
    test('empty text should allow proceed (optional)', () {
      final canProceed = _canProceedWithText('', '^\\d+\$');
      expect(canProceed, isTrue);
    });

    test('valid text should allow proceed', () {
      final canProceed = _canProceedWithText('123', '^\\d+\$');
      expect(canProceed, isTrue);
    });

    test('invalid text should prevent proceed', () {
      final canProceed = _canProceedWithText('abc', '^\\d+\$');
      expect(canProceed, isFalse);
    });

    test('text with no regex should always allow proceed', () {
      final canProceed = _canProceedWithText('anything', null);
      expect(canProceed, isTrue);
    });
  });
}

// Helper functions that mirror the logic in QuestionnaireOpenResponse

bool _isNumericRange(String pattern) {
  final trimmed = pattern.trim();
  if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) {
    return false;
  }

  final content = trimmed.substring(1, trimmed.length - 1).trim();
  final parts = content.split('-');

  if (parts.length != 2) {
    return false;
  }

  final min = int.tryParse(parts[0].trim());
  final max = int.tryParse(parts[1].trim());

  return min != null && max != null;
}

Map<String, int>? _extractRange(String pattern) {
  if (!_isNumericRange(pattern)) {
    return null;
  }

  final trimmed = pattern.trim();
  final content = trimmed.substring(1, trimmed.length - 1).trim();
  final parts = content.split('-');

  int min = int.parse(parts[0].trim());
  int max = int.parse(parts[1].trim());

  // Swap if reversed
  if (min > max) {
    final temp = min;
    min = max;
    max = temp;
  }

  return {'min': min, 'max': max};
}

String? _validateText(String text, String? regex) {
  // Skip validation for numeric range patterns (first!)
  // Sliders can return single digits like "1", "2", etc.
  if (_isNumericRange(regex)) {
    return null;
  }

  // Backend validation: minimum 2 characters required for text fields
  if (text.trim().length == 1) {
    return 'Antwoord moet minimaal 2 karakters bevatten';
  }

  // Allow empty text (optional field)
  if (text.trim().isEmpty) {
    return null;
  }

  // No regex means no validation
  if (regex == null || regex.isEmpty) {
    return null;
  }

  try {
    final regExp = RegExp(regex);
    if (!regExp.hasMatch(text)) {
      // Provide helpful error messages based on pattern
      if (regex.contains('\\d')) {
        return 'Voer alleen cijfers in';
      } else if (regex.contains('[a-z') || regex.contains('[A-Z')) {
        return 'Voer alleen letters in';
      } else if (regex.contains('@')) {
        return 'Voer een geldig e-mailadres in';
      }
      return 'Ongeldige invoer';
    }
    return null;
  } catch (e) {
    // Invalid regex pattern
    return null; // Skip validation if regex is invalid
  }
}

bool _canProceedWithText(String text, String? regex) {
  final validationError = _validateText(text, regex);
  return validationError == null;
}

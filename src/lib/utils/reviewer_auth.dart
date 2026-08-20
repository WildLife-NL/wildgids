import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Temporary Play Store review login. Remove after the review and disable the
/// reviewer account on the server.
///
/// Configure via `.env` (do not commit the token):
/// `REVIEWER_EMAIL`, `REVIEWER_TOKEN`, `REVIEWER_PIN`
///
/// [REVIEWER_TOKEN] must be the session token from a completed login, not the
/// 6-digit e-mail verification code.
class ReviewerAuth {
  static const emailKey = 'REVIEWER_EMAIL';
  static const tokenKey = 'REVIEWER_TOKEN';
  static const pinKey = 'REVIEWER_PIN';
  static const minTokenLength = 16;

  static String _read(String key) {
    try {
      return dotenv.env[key]?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// All three values must be set; otherwise the bypass stays off.
  static bool get isConfigured {
    return email.isNotEmpty &&
        token.isNotEmpty &&
        pin.isNotEmpty &&
        hasValidToken;
  }

  static bool get hasValidToken => token.length >= minTokenLength;

  static String get email => _read(emailKey);
  static String get token => _read(tokenKey);
  static String get pin => _read(pinKey);

  static bool isReviewerEmail(String? value) {
    if (!isConfigured || value == null) return false;
    return value.trim().toLowerCase() == email.toLowerCase();
  }

  static bool isValidPin(String? code) {
    if (!isConfigured || code == null) return false;
    return code.trim() == pin;
  }

  /// Debug-only: explains why the bypass is on/off (never prints the token).
  static void logStatusFor(String? attemptedEmail) {
    if (!kDebugMode) return;

    final attempted = attemptedEmail?.trim().toLowerCase() ?? '';
    final configuredEmail = email.toLowerCase();
    final emailMatches =
        configuredEmail.isNotEmpty && attempted == configuredEmail;

    if (isConfigured && emailMatches) {
      debugPrint(
        '[ReviewerAuth] Bypass ON for $attempted '
        '(token length ${token.length})',
      );
      return;
    }

    final reasons = <String>[];
    if (email.isEmpty) reasons.add('REVIEWER_EMAIL missing');
    if (pin.isEmpty) reasons.add('REVIEWER_PIN missing');
    if (token.isEmpty) {
      reasons.add('REVIEWER_TOKEN missing');
    } else if (!hasValidToken) {
      reasons.add(
        'REVIEWER_TOKEN too short (${token.length} chars; '
        'need >= $minTokenLength — not the 6-digit mail code)',
      );
    }
    if (configuredEmail.isNotEmpty &&
        attempted.isNotEmpty &&
        !emailMatches) {
      reasons.add(
        'email mismatch (typed "$attempted", configured "$configuredEmail")',
      );
    }

    debugPrint(
      '[ReviewerAuth] Bypass OFF'
      '${reasons.isEmpty ? '' : ': ${reasons.join('; ')}'}',
    );
  }
}

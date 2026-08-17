import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Temporary Play Store review login. Remove after the review and disable the
/// reviewer account on the server.
///
/// Configure via `.env` (do not commit the token):
/// `REVIEWER_EMAIL`, `REVIEWER_TOKEN`, `REVIEWER_PIN`
class ReviewerAuth {
  static const emailKey = 'REVIEWER_EMAIL';
  static const tokenKey = 'REVIEWER_TOKEN';
  static const pinKey = 'REVIEWER_PIN';

  static String _read(String key) {
    try {
      return dotenv.env[key]?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// All three values must be set; otherwise the bypass stays off.
  static bool get isConfigured {
    return email.isNotEmpty && token.isNotEmpty && pin.isNotEmpty;
  }

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
}

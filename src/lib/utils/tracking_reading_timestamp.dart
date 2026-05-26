/// Builds timestamps accepted by POST `/tracking-reading/`.
///
/// The API requires `timestamp` to be strictly before server "now". Device
/// clocks are often a few seconds ahead, so we always subtract a buffer and
/// retry once using the server time from a 400 response when available.
class TrackingReadingTimestamp {
  TrackingReadingTimestamp._();

  /// Default margin below device clock (and below server clock in practice).
  static const Duration _safetyBuffer = Duration(seconds: 5);

  static final RegExp _serverNowPattern = RegExp(
    r'timestamp must be before now\s+(\S+)',
    caseSensitive: false,
  );

  /// Timestamp safe to send on the first POST attempt.
  static DateTime forRequest({DateTime? preferred}) {
    final deviceNow = DateTime.now().toUtc();
    var ts = (preferred ?? deviceNow).toUtc();
    if (!ts.isBefore(deviceNow)) {
      ts = deviceNow;
    }
    return ts.subtract(_safetyBuffer);
  }

  /// Parses server "now" from a 400 problem response body.
  static DateTime? parseServerNowFromErrorBody(String body) {
    final match = _serverNowPattern.firstMatch(body);
    if (match == null) return null;
    return DateTime.tryParse(match.group(1)!);
  }

  /// One second before the server's stated "now".
  static DateTime beforeServerNow(DateTime serverNow) =>
      serverNow.toUtc().subtract(const Duration(seconds: 1));

  static bool isTimestampValidationError(int statusCode, String body) =>
      statusCode == 400 &&
      body.contains('timestamp must be before now');
}

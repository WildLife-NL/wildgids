import 'package:intl/intl.dart';

/// UTC instants from the API, shown in the device local timezone.
class ApiDateTime {
  ApiDateTime._();

  static final RegExp _timezoneSuffix = RegExp(
    r'([zZ]|[+-]\d{2}:?\d{2})$',
  );

  /// Parses API `date-time` values as a UTC instant.
  static DateTime parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return DateTime.now().toUtc();
    }

    final value = raw.trim();
    final parsed = DateTime.parse(value);

    if (_timezoneSuffix.hasMatch(value)) {
      return parsed.toUtc();
    }

    // Naive timestamps from the API are UTC (Zulu), not local wall clock.
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  /// User-selected local date/time → ISO-8601 UTC for POST bodies.
  static String toApiIso(DateTime selected) {
    final local = selected.isUtc ? selected.toLocal() : selected;
    return local.toUtc().toIso8601String();
  }

  /// Local wall clock for UI labels.
  static DateTime toLocal(DateTime value) => value.toUtc().toLocal();

  static String formatNl(
    DateTime value, {
    String pattern = 'dd MMM yyyy, HH:mm',
  }) =>
      DateFormat(pattern).format(toLocal(value));

  /// `DD-MM-YYYY | HH:mm` (waarneming summary / logbook cards).
  static String formatSummary(DateTime value) {
    final local = toLocal(value);
    final date =
        '${local.day.toString().padLeft(2, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date | $time';
  }
}

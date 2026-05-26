import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/utils/api_datetime.dart';

void main() {
  test('parse treats Z suffix as UTC', () {
    final instant = ApiDateTime.parse('2026-05-26T12:00:00Z');
    expect(instant, DateTime.utc(2026, 5, 26, 12));
  });

  test('formatNl shows local wall clock for UTC instant', () {
    final instant = DateTime.utc(2026, 5, 26, 12);
    final label = ApiDateTime.formatNl(instant, pattern: 'HH:mm');
    final expected = ApiDateTime.toLocal(instant);
    expect(label, '${expected.hour.toString().padLeft(2, '0')}:'
        '${expected.minute.toString().padLeft(2, '0')}');
  });

  test('toApiIso converts local selection to UTC', () {
    final local = DateTime(2026, 5, 26, 14, 30);
    expect(
      DateTime.parse(ApiDateTime.toApiIso(local)).toUtc(),
      local.toUtc(),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/utils/tracking_reading_timestamp.dart';

void main() {
  test('parseServerNowFromErrorBody extracts server time', () {
    const body =
        '{"detail":"timestamp must be before now 2026-05-26T09:04:47Z"}';
    final parsed = TrackingReadingTimestamp.parseServerNowFromErrorBody(body);
    expect(parsed, DateTime.utc(2026, 5, 26, 9, 4, 47));
  });

  test('beforeServerNow is one second earlier', () {
    final serverNow = DateTime.utc(2026, 5, 26, 9, 4, 47);
    final ts = TrackingReadingTimestamp.beforeServerNow(serverNow);
    expect(ts, DateTime.utc(2026, 5, 26, 9, 4, 46));
  });

  test('forRequest is before device now', () {
    final deviceNow = DateTime.now().toUtc();
    final ts = TrackingReadingTimestamp.forRequest();
    expect(ts.isBefore(deviceNow), isTrue);
  });
}

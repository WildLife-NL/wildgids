import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/utils/last_sent_tracking_location.dart';

void main() {
  tearDown(LastSentTrackingLocation.clear);

  test('isUnchanged is false before any send', () {
    expect(LastSentTrackingLocation.isUnchanged(52.0, 5.0), isFalse);
  });

  test('isUnchanged is true for the same coordinates', () {
    LastSentTrackingLocation.record(52.0907, 5.1214);
    expect(LastSentTrackingLocation.isUnchanged(52.0907, 5.1214), isTrue);
  });

  test('isUnchanged is false after meaningful movement', () {
    LastSentTrackingLocation.record(52.0907, 5.1214);
    expect(LastSentTrackingLocation.isUnchanged(52.1000, 5.1214), isFalse);
  });

  test('clear resets state', () {
    LastSentTrackingLocation.record(52.0, 5.0);
    LastSentTrackingLocation.clear();
    expect(LastSentTrackingLocation.hasSent, isFalse);
    expect(LastSentTrackingLocation.isUnchanged(52.0, 5.0), isFalse);
  });
}

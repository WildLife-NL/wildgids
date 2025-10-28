abstract class TrackingApiInterface {
  Future<void> addTrackingReading({
    required double lat,
    required double lon,
    required DateTime timestampUtc,
  });
}

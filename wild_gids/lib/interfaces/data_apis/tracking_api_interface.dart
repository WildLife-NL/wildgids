class TrackingNotice {
  final String text;
  final int? severity;
  TrackingNotice(this.text, {this.severity});
}

abstract class TrackingApiInterface {
  Future<TrackingNotice?> addTrackingReading({
    required double lat,
    required double lon,
    required DateTime timestampUtc,
  });
}

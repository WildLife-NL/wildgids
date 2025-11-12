import 'dart:async';
import 'package:geolocator/geolocator.dart';

class FreshPositionResult {
  final Position? provisional; // last known (may be null)
  final Position? fresh;       // high-accuracy fix (may be null)
  FreshPositionResult({this.provisional, this.fresh});
}

class LocationHelpers {
  /// Returns: lastKnown (provisional) quickly, then tries to obtain a fresh,
  /// high-accuracy fix within [freshTimeout].
  static Future<FreshPositionResult> getFreshPosition({
    Duration lastKnownTimeout = const Duration(milliseconds: 400),
    Duration freshTimeout     = const Duration(seconds: 7),
    double goodEnoughAccuracyMeters = 5, // tighten if you want
  }) async {
    // 1) Permissions + service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Let the caller decide how to handle; we still try lastKnown
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    // 2) Provisional (last known) – fast, may be stale
    Position? provisional;
    try {
      // lastKnown can resolve very quickly or be null; don’t block.
      provisional = await Geolocator.getLastKnownPosition()
          .timeout(lastKnownTimeout);
    } catch (_) {}

    // 3) Fresh fix via stream (more reliable than a single getCurrentPosition on some devices)
    final settings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // give us the first one that comes
      timeLimit: Duration(seconds: 10),
    );

    final c = Completer<Position?>();
    StreamSubscription<Position>? sub;

    void finish(Position? p) {
      if (!c.isCompleted) c.complete(p);
      sub?.cancel();
    }

    try {
      sub = Geolocator.getPositionStream(locationSettings: settings).listen(
        (pos) {
          // Accept the first "good enough" fix
          final acc = pos.accuracy.isFinite ? pos.accuracy : 9999;
          if (acc <= goodEnoughAccuracyMeters) {
            finish(pos);
          }
        },
        onError: (_) => finish(null),
      );

      // Also set an overall timeout
      Future.delayed(freshTimeout, () => finish(null));
    } catch (_) {
      finish(null);
    }

    final fresh = await c.future;
    return FreshPositionResult(provisional: provisional, fresh: fresh);
  }
}

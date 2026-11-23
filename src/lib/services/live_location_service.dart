import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Owns the one native position stream shared by maps and explicit walk recording.
/// Geolocator caches this stream, so changing background mode requires a restart.
class LiveLocationService {
  LiveLocationService({Stream<Position> Function(LocationSettings)? source})
    : _source =
          source ??
          ((settings) =>
              Geolocator.getPositionStream(locationSettings: settings));

  static final instance = LiveLocationService();
  final Stream<Position> Function(LocationSettings) _source;
  final Map<StreamController<Position>, bool> _clients = {};
  StreamSubscription<Position>? _native;
  bool? _background;
  Future<void> _changes = Future.value();

  static LocationSettings settings(bool background, TargetPlatform platform) {
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: background,
        showBackgroundLocationIndicator: background,
      );
    }
    if (platform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig:
            background
                ? const ForegroundNotificationConfig(
                  notificationTitle: 'WildGids neemt je wandeling op',
                  notificationText:
                      'Je route wordt bijgehouden. Open WildGids om te pauzeren of stoppen.',
                  enableWakeLock: true,
                )
                : null,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );
  }

  Stream<Position> watch({bool background = false}) {
    late StreamController<Position> controller;
    controller = StreamController<Position>(
      onListen: () {
        _clients[controller] = background;
        _reconfigure();
      },
      onCancel: () async {
        _clients.remove(controller);
        await _reconfigure();
      },
    );
    return controller.stream;
  }

  Future<void> _reconfigure() {
    _changes = _changes.then((_) async {
      final desired =
          _clients.isEmpty ? null : _clients.values.any((value) => value);
      if (_native != null && desired == _background) return;
      await _native?.cancel();
      _native = null;
      _background = desired;
      if (desired == null) return;
      try {
        _native = _source(settings(desired, defaultTargetPlatform)).listen(
          (position) {
            for (final client in _clients.keys.toList()) {
              client.add(position);
            }
          },
          onError: _reportError,
          onDone: () {
            _native = null;
            _background = null;
            _reportError(StateError('Location stream ended'));
          },
        );
      } catch (error) {
        _reportError(error);
      }
    });
    return _changes;
  }

  void _reportError(Object error) {
    for (final client in _clients.keys.toList()) {
      client.addError(error);
    }
  }
}

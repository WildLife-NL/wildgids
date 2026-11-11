import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/models/walk_recording.dart';
import 'package:wildgids/services/live_location_service.dart';
import 'package:wildgids/services/walk_store.dart';

class WalkRecorder extends ChangeNotifier {
  WalkRecorder({
    WalkStore? store,
    LiveLocationService? locations,
    Future<String?> Function()? owner,
    Future<void> Function()? authorize,
    DateTime Function()? now,
  }) : _store = store ?? FileWalkStore(),
       _locations = locations ?? LiveLocationService.instance,
       _owner =
           owner ??
           (() async =>
               (await SharedPreferences.getInstance()).getString('userID')),
       _authorize = authorize ?? _checkPermission,
       _now = now ?? DateTime.now;

  final WalkStore _store;
  final LiveLocationService _locations;
  final Future<String?> Function() _owner;
  final Future<void> Function() _authorize;
  final DateTime Function() _now;
  StreamSubscription<Position>? _positions;
  Timer? _ticker;
  DateTime? _runningSince;
  DateTime? _acceptAfter;
  DateTime? _lastSignal;
  DateTime? _lastCheckpoint;
  WalkPoint? _latestFix;
  bool _newSegment = true;
  bool _disposed = false;
  bool _busy = false;
  int _generation = 0;
  String? _account;
  bool _loaded = false;
  Future<void> _writes = Future.value();
  WalkRecording? _current;
  List<WalkRecording> _saved = [];
  String? error;
  String? gpsMessage;
  bool needsLocationSettings = false;

  WalkRecording? get current => _current;
  List<WalkRecording> get saved => List.unmodifiable(_saved);
  bool get recording => _runningSince != null;
  bool get busy => _busy;
  bool get ready => _loaded;
  WalkPoint? get sightingPosition =>
      _latestFix != null &&
              _now().difference(_latestFix!.time) < const Duration(seconds: 30)
          ? _latestFix
          : null;
  Duration get elapsed =>
      Duration(milliseconds: _current?.activeMilliseconds ?? 0) +
      (_runningSince == null
          ? Duration.zero
          : _now().difference(_runningSince!));

  static Future<void> _checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(
        'Zet locatievoorzieningen aan om je wandeling op te nemen.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw StateError(
        'Geef WildGids locatietoegang in de instellingen om een wandeling op te nemen.',
      );
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (_busy) return;
    _busy = true;
    try {
      final account = await _owner();
      if (_loaded && account == _account) return;
      await _pause();
      if (_loaded && !await _persist()) {
        _loaded = false;
        _account = null;
        _current = null;
        _saved = [];
        return;
      }
      await _writes;
      _account = account;
      _current = null;
      _saved = [];
      _loaded = false;
      if (account == null || account.isEmpty) {
        throw StateError('Log in om je wandelingen te bewaren.');
      }
      final archive = await _store.load(account);
      _current = archive.draft;
      _saved = archive.saved;
      _loaded = true;
      needsLocationSettings = false;
      error =
          _current == null
              ? null
              : 'Je vorige opname is onderbroken. Hervat of bewaar de wandeling.';
    } catch (_) {
      error = 'Wandelingen konden niet worden geladen. Probeer het opnieuw.';
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> start() async {
    if (_busy || recording) return;
    if (!_loaded) await initialize();
    if (!_loaded) return;
    _busy = true;
    _notify();
    final generation = _generation;
    try {
      await _authorize();
      if (_disposed || generation != _generation) return;
      final time = _now();
      _current ??= WalkRecording(
        id: time.microsecondsSinceEpoch.toString(),
        startedAt: time,
      );
      error = null;
      needsLocationSettings = false;
      gpsMessage = 'Je locatie zoeken…';
      _acceptAfter = time;
      _lastSignal = null;
      _latestFix = null;
      _newSegment = true;
      _runningSince = time;
      if (!await _persist()) return;
      if (_disposed || generation != _generation) return;
      _positions = _locations
          .watch(background: true)
          .listen(
            _onPosition,
            onError:
                (Object _) => _interrupt(
                  'Locatie niet beschikbaar. Je wandeling is gepauzeerd.',
                ),
          );
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        final last = _lastSignal ?? _acceptAfter!;
        if (_now().difference(last) > const Duration(seconds: 30)) {
          gpsMessage = 'We wachten op je locatie. Je tijd loopt door.';
          _newSegment = true;
        }
        _checkpoint();
        _notify();
      });
    } catch (exception) {
      needsLocationSettings = exception is StateError;
      error =
          exception is StateError
              ? exception.message.toString()
              : 'Opnemen kon niet starten. Controleer je locatietoegang.';
      await _pause();
    } finally {
      _busy = false;
      _notify();
    }
  }

  void _onPosition(Position position) {
    if (!recording || _current == null) return;
    final now = _now();
    if (!position.latitude.isFinite ||
        !position.longitude.isFinite ||
        position.latitude.abs() > 90 ||
        position.longitude.abs() > 180 ||
        !position.accuracy.isFinite ||
        position.accuracy <= 0 ||
        position.accuracy > 35 ||
        position.timestamp.isBefore(_acceptAfter!) ||
        now.difference(position.timestamp) > const Duration(seconds: 30) ||
        position.timestamp.isAfter(now.add(const Duration(seconds: 5)))) {
      return;
    }
    if (_latestFix != null && !position.timestamp.isAfter(_latestFix!.time)) {
      return;
    }
    if (_lastSignal != null &&
        now.difference(_lastSignal!) > const Duration(seconds: 30)) {
      _newSegment = true;
    }
    final previous = _current!.points.isEmpty ? null : _current!.points.last;
    bool moved = true;
    if (previous != null) {
      final seconds =
          position.timestamp.difference(previous.time).inMilliseconds / 1000;
      if (seconds <= 0) return;
      if (!_newSegment) {
        final meters = Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          position.latitude,
          position.longitude,
        );
        // Suppress stationary jitter and implausible walking jumps.
        if (meters / seconds > 8) return;
        moved = meters >= 5;
      }
    }
    _lastSignal = now;
    _latestFix = WalkPoint(
      position.latitude,
      position.longitude,
      position.timestamp,
    );
    gpsMessage = null;
    _checkpoint();
    if (!moved) return;
    final point = WalkPoint(
      position.latitude,
      position.longitude,
      position.timestamp,
      newSegment: _newSegment,
    );
    _newSegment = false;
    _current = _current!.copyWith(points: [..._current!.points, point]);
    unawaited(_persist());
    _notify();
  }

  void _checkpoint() {
    if (_lastCheckpoint == null ||
        _now().difference(_lastCheckpoint!) >= const Duration(seconds: 15)) {
      unawaited(_persist());
    }
  }

  Future<void> _pause() async {
    if (recording) {
      _current = _current?.copyWith(
        activeMilliseconds: elapsed.inMilliseconds,
        updatedAt: _now(),
      );
    }
    _runningSince = null;
    _ticker?.cancel();
    _ticker = null;
    final subscription = _positions;
    _positions = null;
    await subscription?.cancel();
    gpsMessage = null;
    _newSegment = true;
  }

  Future<void> pause() async {
    if (_busy) return;
    _busy = true;
    await _pause();
    await _persist();
    _busy = false;
    _notify();
  }

  Future<void> _interrupt(String message) async {
    await _pause();
    needsLocationSettings = true;
    error = message;
    await _persist();
    _notify();
  }

  Future<bool> _persist() async {
    final owner = _account;
    if (!_loaded || owner == null) return false;
    _lastCheckpoint = _now();
    final snapshot = WalkArchive(
      draft: _current?.copyWith(
        activeMilliseconds: elapsed.inMilliseconds,
        updatedAt: _now(),
      ),
      saved: List.of(_saved),
    );
    var success = true;
    _writes = _writes.then((_) async {
      try {
        await _store.save(owner, snapshot);
      } catch (_) {
        success = false;
        await _pause();
        error =
            'Opslaan mislukt. De opname is gepauzeerd. Probeer opnieuw; sluit de app niet.';
        needsLocationSettings = false;
        _notify();
      }
    });
    await _writes;
    return success;
  }

  Future<bool> finish({required bool save}) async {
    if (_busy || _current == null) return false;
    _busy = true;
    await _pause();
    final draft = _current!;
    final previous = List<WalkRecording>.of(_saved);
    if (save) _saved = [draft.copyWith(finishedAt: _now()), ..._saved];
    _current = null;
    final success = await _persist();
    if (!success) {
      _current = draft;
      _saved = previous;
    }
    if (success) error = null;
    _busy = false;
    _notify();
    return success;
  }

  Future<void> addSighting(
    WalkSighting sighting, {
    required String walkId,
  }) async {
    if (_current?.id != walkId ||
        _current!.sightings.any((s) => s.id == sighting.id)) {
      return;
    }
    _current = _current!.copyWith(
      sightings: [..._current!.sightings, sighting],
    );
    await _persist();
    _notify();
  }

  Future<void> deleteSaved(String id) async {
    if (_busy) return;
    _busy = true;
    final previous = _saved;
    _saved = _saved.where((walk) => walk.id != id).toList();
    if (!await _persist()) _saved = previous;
    _busy = false;
    _notify();
  }

  Future<void> closeAccount() async {
    _generation++;
    await _pause();
    await _persist();
    _loaded = false;
    _account = null;
    _current = null;
    _saved = [];
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _positions?.cancel();
    super.dispose();
  }
}

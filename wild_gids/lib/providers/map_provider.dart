import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildrapport/models/enums/location_type.dart';

// R8
import 'package:wildrapport/models/api_models/interaction_query_result.dart';
import 'package:wildrapport/managers/api_managers/interaction_query_manager.dart';

// R7
import 'package:wildrapport/models/animal_waarneming_models/animal_pin.dart';
import 'package:wildrapport/models/api_models/detection_pin.dart';
import 'package:wildrapport/managers/api_managers/animal_pins_manager.dart';
import 'package:wildrapport/managers/api_managers/detection_pins_manager.dart';

import 'package:wildrapport/interfaces/data_apis/tracking_api_interface.dart'
  show TrackingApiInterface, TrackingNotice, TrackingReadingResponse;
import 'package:wildrapport/managers/encounter_message_manager.dart';
import 'package:wildrapport/managers/api_managers/vicinity_manager.dart';
import 'dart:async';



class MapProvider extends ChangeNotifier {
  TrackingApiInterface? _trackingApi;
  // ===== Location state =====
  Position? selectedPosition;
  String selectedAddress = '';
  Position? currentPosition;
  String currentAddress = '';
  MapController? _mapController;
  bool _isLoading = false;
  final bool _isDisposed = false;

  Timer? _trackingTimer;
bool _isTracking = false;
Duration _trackingInterval = const Duration(minutes: 5);

bool get isTracking => _isTracking;
Duration get trackingInterval => _trackingInterval;


  bool get isLoading => _isLoading;
  bool get isInitialized => _mapController != null;

TrackingNotice? _lastTrackingNotice;
TrackingNotice? get lastTrackingNotice => _lastTrackingNotice;

  MapController get mapController {
    if (_mapController == null) {
      debugPrint(
        '[MapProvider] Warning: accessing uninitialized map controller, creating new instance',
      );
      _mapController = MapController();
    }
    return _mapController!;
  }

void setTrackingApi(TrackingApiInterface api) {
  _trackingApi = api;
}

/// Call this to send the user's current GPS location to the backend.
Future<TrackingNotice?> sendTrackingPingFromPosition(Position pos) async {
  if (_trackingApi == null) {
    debugPrint('[MapProvider] ⚠️ TrackingApi not set - cannot send tracking ping');
    return null;
  }

  debugPrint('[MapProvider] 📍 Sending tracking ping for position: ${pos.latitude}, ${pos.longitude}');

  try {
    final notice = await _trackingApi!.addTrackingReading(
      lat: pos.latitude,
      lon: pos.longitude,
      timestampUtc: DateTime.now().toUtc(),
    );

    if (notice != null) {
      _lastTrackingNotice = notice;
      debugPrint('[MapProvider] 🔔 Got tracking notice, adding to global queue');
      
      // Add to global encounter message manager
      EncounterMessageManager().addNotice(notice);
      
      notifyListeners(); // if any UI wants to react to changes
      debugPrint('[MapProvider] ✓ tracking-reading OK; notice="${notice.text}"'
          ' sev=${notice.severity ?? '-'}');
    } else {
      debugPrint('[MapProvider] ✓ tracking-reading OK; no notice from backend');
    }
    return notice;
  } catch (e) {
    debugPrint('[MapProvider] ❌ tracking-reading failed: $e');
    return null;
  }
}


  // ===== R7: Animals & Detections =====
  final List<AnimalPin> _animalPins = [];
  final List<DetectionPin> _detectionPins = [];

  bool _animalPinsLoading = false;
  bool _detectionPinsLoading = false;

  String? _animalPinsError;
  String? _detectionPinsError;

  AnimalPinsManager? _animalPinsManager;
  DetectionPinsManager? _detectionPinsManager;

  void setAnimalPinsManager(AnimalPinsManager manager) {
    _animalPinsManager = manager;
  }

  void setDetectionPinsManager(DetectionPinsManager manager) {
    _detectionPinsManager = manager;
  }

  List<AnimalPin> get animalPins => List.unmodifiable(_animalPins);
  List<DetectionPin> get detectionPins => List.unmodifiable(_detectionPins);

  bool get animalPinsLoading => _animalPinsLoading;
  bool get detectionPinsLoading => _detectionPinsLoading;

  String? get animalPinsError => _animalPinsError;
  String? get detectionPinsError => _detectionPinsError;

  // ===== R8: Interactions =====
  final List<InteractionQueryResult> _interactions = [];
  bool _interactionsLoading = false;
  String? _interactionsError;

  InteractionQueryManager? _interactionsManager;
  void setInteractionsManager(InteractionQueryManager manager) {
    _interactionsManager = manager;
  }

  VicinityManager? _vicinityManager;
  void setVicinityManager(VicinityManager manager) {
    _vicinityManager = manager;
  }

  List<InteractionQueryResult> get interactions =>
      List.unmodifiable(_interactions);
  bool get interactionsLoading => _interactionsLoading;
  String? get interactionsError => _interactionsError;
  bool get hasInteractions => _interactions.isNotEmpty;

  int get totalPins =>
      _animalPins.length + _detectionPins.length + _interactions.length;

  Future<List<TrackingReadingResponse>> getMyTrackingReadings() async {
    if (_trackingApi == null) return [];
    try {
      return await _trackingApi!.getMyTrackingReadings();
    } catch (e) {
      debugPrint('[MapProvider] getMyTrackingReadings failed: $e');
      return [];
    }
  }

  // ===== Lifecycle / base map helpers =====
  Future<void> initialize() async {
    if (_mapController != null) {
      debugPrint('[MapProvider] Map controller already initialized, skipping');
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      _mapController = MapController();
      await Future.delayed(const Duration(milliseconds: 100));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to initialize map controller: $e');
    }
  }

  void setMapController(MapController controller) {
    if (_mapController != null && _mapController != controller) {
      _mapController?.dispose();
    }
    _mapController = controller;
    notifyListeners();
  }

  void setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    Future.microtask(() {
      if (!_isDisposed) notifyListeners();
    });
  }

  Future<void> updatePosition(Position position, String address) async {
    if (_isDisposed) return;
    currentPosition = position;
    currentAddress = address;

    if (selectedAddress != LocationType.unknown.displayText) {
      selectedPosition = position;
      selectedAddress = address;
    }

    Future.microtask(() {
      if (!_isDisposed) {
        setLoading(false);
        notifyListeners();
      }
    });
  }

  void setSelectedLocation(Position position, String address) {
    selectedPosition = position;
    selectedAddress = address;
    notifyListeners();
  }

  Future<void> clearSelectedLocation() async {
    setLoading(true);
    selectedPosition = null;
    selectedAddress = LocationType.unknown.displayText;
    notifyListeners();
    setLoading(false);
  }

  Future<void> resetToCurrentLocation(Position position, String address) async {
    setLoading(true);
    selectedPosition = null;
    selectedAddress = '';
    await Future.delayed(const Duration(milliseconds: 50));
    selectedPosition = position;
    selectedAddress = address;
    currentPosition = position;
    currentAddress = address;
    setLoading(false);
    notifyListeners();
  }

  Future<void> resetState() async {
    setLoading(true);
    selectedPosition = null;
    selectedAddress = '';
    currentPosition = null;
    currentAddress = '';
    notifyListeners();
    setLoading(false);
  }

  Future<void> resetMapState() async {
    _isLoading = true;
    notifyListeners();

    selectedPosition = null;
    selectedAddress = '';
    currentPosition = null;
    currentAddress = '';

    // clear pins & errors
    _animalPins.clear();
    _detectionPins.clear();
    _interactions.clear();
    _animalPinsError = null;
    _detectionPinsError = null;
    _interactionsError = null;
    _animalPinsLoading = false;
    _detectionPinsLoading = false;
    _interactionsLoading = false;

    await Future.delayed(const Duration(milliseconds: 50));
    _isLoading = false;
    notifyListeners();
  }

  // ===== Loaders (R8) =====
  Future<void> loadInteractions({
    required double lat,
    required double lon,
    required int radiusMeters,
    DateTime? after,
    DateTime? before,
  }) async {
    if (_interactionsManager == null) {
      debugPrint(
        '[MapProvider] InteractionsManager not set. Call setInteractionsManager() first.',
      );
      return;
    }

    _interactionsLoading = true;
    _interactionsError = null;
    _interactions.clear();
    notifyListeners();

    try {
      final clamped = radiusMeters.clamp(250, 20000);
      final results = await _interactionsManager!.loadNearby(
        lat: lat,
        lon: lon,
        radiusMeters: clamped,
        after: after,
        before: before,
      );

      _interactions
        ..clear()
        ..addAll(results);

      _interactionsLoading = false;
      _interactionsError = null;
      notifyListeners();
    } catch (e) {
      _interactionsLoading = false;
      _interactionsError = e.toString();
      notifyListeners();
    }
  }

  void clearInteractions() {
    _interactions.clear();
    _interactionsError = null;
    _interactionsLoading = false;
    notifyListeners();
  }

  // ===== Loaders (R7) =====
  Future<void> loadAnimalPins({
    required double lat,
    required double lon,
    required int radiusMeters,
    DateTime? after,
    DateTime? before,
  }) async {
    if (_animalPinsManager == null) {
      debugPrint(
        '[MapProvider] AnimalPinsManager not set. Call setAnimalPinsManager() first.',
      );
      return;
    }

    _animalPinsLoading = true;
    _animalPinsError = null;
    _animalPins.clear();
    notifyListeners();

    try {
      final all = await _animalPinsManager!.loadAll();

      final filtered =
          all.where((pin) {
            final d = Geolocator.distanceBetween(lat, lon, pin.lat, pin.lon);
            if (d > radiusMeters) return false;

            if (after != null && pin.seenAt.isBefore(after)) return false;
            if (before != null && pin.seenAt.isAfter(before)) return false;

            return true;
          }).toList();

      debugPrint(
        '[R7/Animals] all=${all.length} kept=${filtered.length} '
        '(r=${radiusMeters}m, after=$after, before=$before)'
        '${filtered.isNotEmpty ? ' first=${filtered.first.speciesName} @ ${filtered.first.lat},${filtered.first.lon}' : ''}',
      );

      _animalPins
        ..clear()
        ..addAll(filtered);

      _animalPinsLoading = false;
      notifyListeners();
    } catch (e) {
      _animalPinsLoading = false;
      _animalPinsError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadDetectionPins({
    required double lat,
    required double lon,
    required int radiusMeters,
    DateTime? after,
    DateTime? before,
  }) async {
    if (_detectionPinsManager == null) {
      debugPrint(
        '[MapProvider] DetectionPinsManager not set. Call setDetectionPinsManager() first.',
      );
      return;
    }

    _detectionPinsLoading = true;
    _detectionPinsError = null;
    _detectionPins.clear();
    notifyListeners();

    try {
      final all = await _detectionPinsManager!.loadAll();

      final filtered =
          all.where((pin) {
            final d = Geolocator.distanceBetween(lat, lon, pin.lat, pin.lon);
            if (d > radiusMeters) return false;

            if (after != null && pin.detectedAt.isBefore(after)) return false;
            if (before != null && pin.detectedAt.isAfter(before)) return false;

            return true;
          }).toList();

      debugPrint(
        '[R7/Detections] all=${all.length} kept=${filtered.length} '
        '(r=${radiusMeters}m, after=$after, before=$before)'
        '${filtered.isNotEmpty ? ' first @ ${filtered.first.lat},${filtered.first.lon} ts=${filtered.first.detectedAt.toIso8601String()}' : ''}',
      );

      _detectionPins
        ..clear()
        ..addAll(filtered);

      _detectionPinsLoading = false;
      notifyListeners();
    } catch (e) {
      _detectionPinsLoading = false;
      _detectionPinsError = e.toString();
      notifyListeners();
    }
  }

  /// Load all data from the vicinity endpoint (NEW preferred method)
  /// This replaces separate loadAnimalPins, loadDetectionPins, loadInteractions calls
  Future<void> loadVicinity() async {
    if (_vicinityManager == null) {
      debugPrint(
        '[MapProvider] VicinityManager not set. Call setVicinityManager() first.',
      );
      return;
    }

    _animalPinsLoading = true;
    _detectionPinsLoading = true;
    _interactionsLoading = true;
    notifyListeners();

    try {
      final vicinity = await _vicinityManager!.loadVicinity();

      _animalPins
        ..clear()
        ..addAll(vicinity.animals);

      _detectionPins
        ..clear()
        ..addAll(vicinity.detections);

      _interactions
        ..clear()
        ..addAll(vicinity.interactions);

      _animalPinsLoading = false;
      _detectionPinsLoading = false;
      _interactionsLoading = false;
      _animalPinsError = null;
      _detectionPinsError = null;
      _interactionsError = null;

      debugPrint(
        '[MapProvider/Vicinity] Loaded ${_animalPins.length} animals, '
        '${_detectionPins.length} detections, ${_interactions.length} interactions',
      );

      notifyListeners();
    } catch (e) {
      _animalPinsLoading = false;
      _detectionPinsLoading = false;
      _interactionsLoading = false;
      _animalPinsError = e.toString();
      _detectionPinsError = e.toString();
      _interactionsError = e.toString();
      debugPrint('[MapProvider/Vicinity] Error loading vicinity: $e');
      notifyListeners();
    }
  }

  /// Convenience to load everything for the current view (LEGACY - kept for compatibility)
  /// Prefer using loadVicinity() instead
  Future<void> loadAllPinsForView({
    required double lat,
    required double lon,
    required int radiusMeters,
    DateTime? after,
    DateTime? before,
  }) async {
    await Future.wait([
      loadAnimalPins(
        lat: lat,
        lon: lon,
        radiusMeters: radiusMeters,
        after: after,
        before: before,
      ),
      loadDetectionPins(
        lat: lat,
        lon: lon,
        radiusMeters: radiusMeters,
        after: after,
        before: before,
      ),
      loadInteractions(
        lat: lat,
        lon: lon,
        radiusMeters: radiusMeters,
        after: after,
        before: before,
      ),
    ]);
  }
      /// Sends one tracking ping using the freshest position we have.
/// Falls back to getting a new fix if needed.
Future<void> _sendTrackingNow() async {
  try {
    final pos = currentPosition ??
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 7),
          ),
        );
    await sendTrackingPingFromPosition(pos);
  } catch (e) {
    debugPrint('[MapProvider] tracking ping skipped: $e');
  }
}


/// Starts periodic pings. Fires one immediately, then repeats.
void startTracking({Duration? interval}) {
  if (_trackingApi == null) {
    debugPrint('[MapProvider] Cannot start tracking: TrackingApi not set');
    return;
  }
  _trackingTimer?.cancel();
  _trackingInterval = interval ?? _trackingInterval;

  _isTracking = true;
  notifyListeners();

  // fire now, then periodically
  _sendTrackingNow();
  _trackingTimer = Timer.periodic(_trackingInterval, (_) => _sendTrackingNow());

  debugPrint(
    '[MapProvider] tracking STARTED every ${_trackingInterval.inSeconds}s',
  );
}

/// Stops periodic pings.
void stopTracking() {
  _trackingTimer?.cancel();
  _trackingTimer = null;
  if (_isTracking) {
    _isTracking = false;
    // Don't call notifyListeners during dispose - it causes setState during widget tree lock
    // notifyListeners();
  }
  debugPrint('[MapProvider] tracking STOPPED');
}

@override
void dispose() {
  _trackingTimer?.cancel();
  super.dispose();
}
}

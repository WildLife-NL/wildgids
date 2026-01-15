import 'dart:collection';
import 'package:wildgids/interfaces/data_apis/detections_api_interface.dart';
import 'package:wildgids/models/api_models/detection_pin.dart';

class DetectionPinsManager {
  final DetectionsApiInterface api;

  // Optional time-to-live for cache (set to null to disable TTL)
  final Duration? cacheTtl;

  List<DetectionPin>? _cache;
  DateTime? _cachedAt;

  DetectionPinsManager(this.api, {this.cacheTtl});

  Future<List<DetectionPin>> loadAll({bool forceRefresh = false}) async {
    final isFresh =
        _cache != null &&
        (!forceRefresh) &&
        (cacheTtl == null ||
            (_cachedAt != null &&
                DateTime.now().difference(_cachedAt!) < cacheTtl!));

    if (isFresh) return UnmodifiableListView(_cache!);

    try {
      final data = await api.getAllDetections();
      _cache = List<DetectionPin>.unmodifiable(data);
      _cachedAt = DateTime.now();
      return _cache!;
    } catch (e) {
      // Re-throw so UI can show an error
      rethrow;
    }
  }

  void clearCache() {
    _cache = null;
    _cachedAt = null;
  }
}


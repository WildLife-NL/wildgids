import 'dart:collection';
import 'package:wildgids/interfaces/data_apis/animals_api_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';

class AnimalPinsManager {
  final AnimalsApiInterface api;

  // Optional time-to-live for cache (set to null to disable TTL)
  final Duration? cacheTtl;

  List<AnimalPin>? _cache;
  DateTime? _cachedAt;

  AnimalPinsManager(this.api, {this.cacheTtl});

  Future<List<AnimalPin>> loadAll({bool forceRefresh = false}) async {
    final isFresh =
        _cache != null &&
        (!forceRefresh) &&
        (cacheTtl == null ||
            (_cachedAt != null &&
                DateTime.now().difference(_cachedAt!) < cacheTtl!));

    if (isFresh) return UnmodifiableListView(_cache!);

    try {
      final data = await api.getAllAnimals();
      _cache = List<AnimalPin>.unmodifiable(data);
      _cachedAt = DateTime.now();
      return _cache!;
    } catch (e) {
      rethrow;
    }
  }

  void clearCache() {
    _cache = null;
    _cachedAt = null;
  }
}


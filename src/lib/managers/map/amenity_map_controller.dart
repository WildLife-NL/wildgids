import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wildgids/managers/map/living_lab_manager.dart';
import 'package:wildgids/models/ui_models/map_amenity.dart';

class AmenityMapController extends ChangeNotifier {
  AmenityMapController({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const parkAssets = {
    'np-zuid-kennemerland': 'assets/data/amenities/zuid_kennemerland.json',
    'grenspark-kempenbroek': 'assets/data/amenities/kempenbroek.json',
  };
  final AssetBundle _bundle;
  final labs = LivingLabManager().getAllLivingLabs();
  final _enabledCategories = AmenityCategory.values.toSet();
  List<MapAmenity> _amenities = const [];
  bool _disposed = false;
  bool isLoading = false;
  String? error;

  List<MapAmenity> get amenities => _amenities;
  Set<AmenityCategory> get enabledCategories =>
      Set.unmodifiable(_enabledCategories);
  List<MapAmenity> get visibleAmenities => _amenities
      .where((amenity) => _enabledCategories.contains(amenity.category))
      .toList(growable: false);

  Future<void> load() async {
    if (isLoading || _disposed) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final amenities = <MapAmenity>[];
      for (final park in parkAssets.entries) {
        final catalog = AmenityCatalog.fromJson(
          jsonDecode(await _bundle.loadString(park.value)),
          livingLabId: park.key,
        );
        amenities.addAll(catalog.amenities);
      }
      if (_disposed) return;
      _amenities = List.unmodifiable(amenities);
    } catch (exception) {
      if (_disposed) return;
      debugPrint('[Amenities] Cannot load catalog: $exception');
      error = 'Voorzieningen konden niet worden geladen.';
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void setCategory(AmenityCategory category, bool enabled) {
    if (enabled) {
      _enabledCategories.add(category);
    } else {
      _enabledCategories.remove(category);
    }
    notifyListeners();
  }

  void setAllCategories(bool enabled) {
    _enabledCategories.clear();
    if (enabled) _enabledCategories.addAll(AmenityCategory.values);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

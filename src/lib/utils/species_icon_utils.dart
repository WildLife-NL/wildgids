import 'package:flutter/foundation.dart';
import 'package:wildlifenl_assets/wildlifenl_assets.dart';

/// ===============================
/// MAP ICONS (silhouette icons)
/// ===============================
String? getSpeciesIconPath(String? speciesName) {
  if (speciesName == null || speciesName.trim().isEmpty) return null;

  // Package checks 'boommarten' but backend sends 'boommarter'
  final name = speciesName.toLowerCase();
  if (name.contains('boommarter')) {
    const path = 'packages/wildlifenl_assets/assets/icons/animals/boommarter.png';
    _log(speciesName, path);
    return path;
  }
if (name.contains('bever') || name.contains('beaver')) {
  const path =
      'packages/wildlifenl_assets/assets/icons/animals/bever.png';
  _log(speciesName, path);
  return path;
}
  final path = getAnimalIconPath(speciesName);
  _log(speciesName, path);
  return path;
}

/// ===============================
/// CARD IMAGES (full color images) — always use local wildgids assets
/// ===============================
String? getSpeciesCardImagePath(String? speciesName) {
  if (speciesName == null || speciesName.trim().isEmpty) return null;

  final normalized = speciesName.trim().toLowerCase().replaceAll(' ', '-');
  final path = 'assets/images/color-animals/$normalized.png';
  _log(speciesName, path);
  return path;
}

void _log(String name, String? path) {
  assert(() {
    debugPrint('[SpeciesIcon] "$name" -> ${path ?? 'null'}');
    return true;
  }());
}
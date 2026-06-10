import 'package:flutter/foundation.dart';
import 'package:wildlifenl_assets/wildlifenl_assets.dart';
import 'package:wildgids/utils/species_image_resolver.dart';

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
if (name.contains('exmoorpony') || name.contains('exmoor pony')) {
  const path =
      'packages/wildlifenl_assets/assets/icons/animals/exmoorpony.png';
  _log(speciesName, path);
  return path;
}
if (name.contains('wildkat') ||
    name.contains('wild kat') ||
    name.contains('wildekat') ||
    name.contains('wilde kat') ||
    name.contains('wildcat')) {
  final aliases = <String>['wilde kat', 'wild kat', 'wildcat', 'wildkat'];
  for (final alias in aliases) {
    final resolved = getAnimalIconPath(alias);
    if (resolved != null && resolved.isNotEmpty) {
      _log(speciesName, resolved);
      return resolved;
    }
  }

  const fallbackPath =
      'packages/wildlifenl_assets/assets/icons/animals/wilde_zwijn.png';
  _log(speciesName, fallbackPath);
  return fallbackPath;
}



if (name.contains('shetlandpony') || name.contains('shetland pony')) {
  const path =
      'packages/wildlifenl_assets/assets/icons/animals/shetlandpony.png';
  _log(speciesName, path);
  return path;
}

if (name.contains('taurus') || name.contains('tauros')) {
  final resolved = getAnimalIconPath('tauros') ?? getAnimalIconPath('taurus');
  if (resolved != null && resolved.isNotEmpty) {
    _log(speciesName, resolved);
    return resolved;
  }
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

  // Reuse the centralized resolver that already maps tricky names
  // (for example: "Europese nerts" -> "europesenerts.png").
  final resolved = SpeciesImageResolver.drawingForCommonName(speciesName);
  if (resolved != null && resolved.isNotEmpty) {
    _log(speciesName, resolved);
    return resolved;
  }

  final trimmed = speciesName.trim().toLowerCase();
  final candidates = <String>[
    trimmed,
    trimmed.replaceAll('-', ' '),
    trimmed.replaceAll(' ', ''),
    trimmed.replaceAll(' ', '-'),
  ];

  final path = 'assets/images/color-animals/${candidates.first}.png';
  _log(speciesName, path);
  return path;
}

void _log(String name, String? path) {
  assert(() {
    debugPrint('[SpeciesIcon] "$name" -> ${path ?? 'null'}');
    return true;
  }());
}
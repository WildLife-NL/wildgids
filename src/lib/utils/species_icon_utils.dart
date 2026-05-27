import 'package:flutter/foundation.dart';

/// ===============================
/// CARD IMAGES (full color images)
/// ===============================
String? getSpeciesCardImagePath(String? speciesName) {
  if (speciesName == null || speciesName.trim().isEmpty) {
    return null;
  }

  final normalized = speciesName
      .trim()
      .toLowerCase()
      .replaceAll(' ', '-');

  final path = 'assets/images/color-animals/$normalized.png';

  _logSpeciesImageResolution(speciesName, path);

  return path;
}

/// ===============================
/// MAP ICONS (silhouette icons)
/// ===============================
String? getSpeciesIconPath(String? speciesName) {
  if (speciesName == null) return null;

  final name = speciesName.toLowerCase();

  if (name.contains('wolf')) return 'assets/icons/animals/wolf.png';
  if (name.contains('vos') || name.contains('fox')) {
    return 'assets/icons/animals/vos.png';
  }
  if (name.contains('das') || name.contains('badger')) {
    return 'assets/icons/animals/das.png';
  }
  if (name.contains('ree') || name.contains('deer')) {
    return 'assets/icons/animals/ree.png';
  }
  if (name.contains('zwijn') || name.contains('boar')) {
    return 'assets/icons/animals/wild_zwijn.png';
  }
  if (name.contains('damhert')) return 'assets/icons/animals/damhert.png';
  if (name.contains('egel') || name.contains('hedgehog')) {
    return 'assets/icons/animals/egel.png';
  }
  if (name.contains('eekhoorn') || name.contains('squirrel')) {
    return 'assets/icons/animals/eekhoorn.png';
  }
  if (name.contains('bever') || name.contains('beaver')) {
    return 'assets/icons/animals/beaver.png';
  }
  if (name.contains('boommarten') || name.contains('marten')) {
    return 'assets/icons/animals/boommarten.png';
  }
  if (name.contains('hooglander') || name.contains('highlander')) {
    return 'assets/icons/animals/hooglander.png';
  }
  if (name.contains('wisent') || name.contains('bison')) {
    return 'assets/icons/animals/winsent.png';
  }

  _logSpeciesImageResolution(speciesName, null);

  return null;
}

void _logSpeciesImageResolution(
  String originalName,
  String? resolvedPath,
) {
  if (!kDebugMode) return;

  debugPrint(
    '[SpeciesIcon] "$originalName" -> ${resolvedPath ?? 'null'}',
  );
}
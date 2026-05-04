import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

abstract class MapStateInterface {
  static const double minLat = 51.2;
  static const double maxLat = 52.0;
  static const double minLng = 4.9;
  static const double maxLng = 5.9;

  static const LatLng denBoschCenter = LatLng(51.6988, 5.3041);
  static const String standardTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String satelliteTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  void constrainMapCamera(MapController mapController);

  void animateToLocation({
    required MapController mapController,
    required LatLng targetLocation,
    required double targetZoom,
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 500),
  });
}

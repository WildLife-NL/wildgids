import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildgids/interfaces/map/location_service_interface.dart';
import 'package:wildgids/interfaces/map/map_service_interface.dart';
import 'package:wildgids/interfaces/map/map_state_interface.dart';
import 'package:wildlifenl_map_logic_components/wildlifenl_map_logic_components.dart'
    show NetherlandsMapManager;

class LocationMapManager
    extends NetherlandsMapManager
    implements
        LocationServiceInterface,
        MapServiceInterface,
        MapStateInterface {
  static const LatLng denBoschCenter = LatLng(51.6988, 5.3041);
  static const String standardTileUrl = NetherlandsMapManager.standardTileUrl;
  static const String satelliteTileUrl = NetherlandsMapManager.satelliteTileUrl;
  static const List<String> standardTileSubdomains =
      NetherlandsMapManager.standardTileSubdomains;

  /// Carto `urlTemplate` uses `{r}`; enable retina tiles on dense displays.
  static bool tileRetinaMode(BuildContext context) =>
      RetinaMode.isHighDensity(context);
}


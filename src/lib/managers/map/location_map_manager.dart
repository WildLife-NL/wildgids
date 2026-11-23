import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:wildgids/interfaces/map/location_service_interface.dart';
import 'package:wildgids/interfaces/map/map_service_interface.dart';
import 'package:wildgids/interfaces/map/map_state_interface.dart';
import 'package:wildlifenl_map_logic_components/wildlifenl_map_logic_components.dart'
    show NetherlandsMapManager;

class LocationMapManager extends NetherlandsMapManager
    implements
        LocationServiceInterface,
        MapServiceInterface,
        MapStateInterface {
  static String get standardTileUrl {
    final key =
        dotenv.isInitialized
            ? dotenv.env['CARTO_BASEMAP_API_KEY']?.trim() ?? ''
            : '';
    final base = NetherlandsMapManager.standardTileUrl;
    if (key.isEmpty) return base;

    final keyParameter = RegExp(r'([?&])key=[^&]*');
    if (keyParameter.hasMatch(base)) {
      return base.replaceFirstMapped(
        keyParameter,
        (match) => '${match[1]}key=${Uri.encodeQueryComponent(key)}',
      );
    }

    final separator = base.contains('?') ? '&' : '?';
    return '$base${separator}key=${Uri.encodeQueryComponent(key)}';
  }

  static Map<String, String> get standardTileHeaders => {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
      'X-Ios-Bundle-Identifier': 'com.wildlife.wildgids',
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...{
      'X-Android-Package': 'com.wildlife.wildgids',
      if (dotenv.isInitialized &&
          (dotenv.env['CARTO_ANDROID_CERT']?.trim().isNotEmpty ?? false))
        'X-Android-Cert': dotenv.env['CARTO_ANDROID_CERT']!.trim(),
    },
  };
  static const String satelliteTileUrl = NetherlandsMapManager.satelliteTileUrl;
  static const List<String> standardTileSubdomains =
      NetherlandsMapManager.standardTileSubdomains;

  /// Carto `urlTemplate` uses `{r}`; enable retina tiles on dense displays.
  static bool tileRetinaMode(BuildContext context) =>
      RetinaMode.isHighDensity(context);
}

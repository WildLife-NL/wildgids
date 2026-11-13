import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlifenl_map_logic_components/wildlifenl_map_logic_components.dart'
    show NetherlandsMapManager;
import 'package:wildgids/managers/map/location_map_manager.dart';

void main() {
  tearDown(() {
    dotenv.clean();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'CARTO key is read from configuration and template tokens remain intact',
    () {
      dotenv.loadFromString(envString: 'CARTO_BASEMAP_API_KEY=test-key');
      final template = LocationMapManager.standardTileUrl;
      expect(template, contains('basemaps.cartocdn.com'));
      for (final token in ['{s}', '{z}', '{x}', '{y}', '{r}']) {
        expect(template, contains(token));
      }
      expect(template, endsWith('?key=test-key'));
    },
  );

  test(
    'preserves the component URL when configuration is missing or empty',
    () {
      dotenv.loadFromString(envString: 'CARTO_BASEMAP_API_KEY=');
      expect(
        LocationMapManager.standardTileUrl,
        NetherlandsMapManager.standardTileUrl,
      );
    },
  );

  test('encodes special characters in configured keys', () {
    dotenv.loadFromString(envString: 'CARTO_BASEMAP_API_KEY=a+b&c');
    final keys =
        RegExp(r'[?&]key=([^&]*)')
            .allMatches(LocationMapManager.standardTileUrl)
            .map((match) => match.group(1))
            .toList();
    expect(keys, ['a%2Bb%26c']);
  });

  test(
    'iOS sends the registered app identifier; other platforms do not impersonate iOS',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(LocationMapManager.standardTileHeaders, {
        'X-Ios-Bundle-Identifier': 'com.wildlife.wildgids',
      });
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(LocationMapManager.standardTileHeaders, {
        'X-Android-Package': 'com.wildlife.wildgids',
      });
    },
  );

  test('Android sends the configured signing certificate only on Android', () {
    dotenv.loadFromString(envString: 'CARTO_ANDROID_CERT=AA:BB:CC');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(LocationMapManager.standardTileHeaders, {
      'X-Android-Package': 'com.wildlife.wildgids',
      'X-Android-Cert': 'AA:BB:CC',
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      LocationMapManager.standardTileHeaders.containsKey('X-Android-Cert'),
      isFalse,
    );
  });
}

import 'package:flutter/material.dart';

class AssetPreloader {
  static Future<void> precacheAllAssets(BuildContext context) async {
    // Create a list of futures for parallel loading
    final List<Future<void>> precacheFutures = [];

    final List<String> assets = [
      // Logo assets
      'assets/LogoWildlifeNL.png',
      'assets/LogoHeadWildlifeNL.png',

      // Animal assets
      'assets/wolf.png',

      // GIF assets
      'assets/gifs/login.gif',
      'assets/gifs/thankyou.gif',

      // Icon assets
      'assets/icons/marked_earth.png',
      'assets/icons/report.png',
      'assets/icons/my_report.png',

      // Rapporteren icons
      'assets/icons/rapporteren/crop_icon.png',
      'assets/icons/rapporteren/health_icon.png',
      'assets/icons/rapporteren/sighting_icon.png',
      'assets/icons/rapporteren/accident_icon.png',
      'assets/location/location_icon.png',
    ];

    // Pre-create image providers for better caching
    for (final String asset in assets) {
      final provider = AssetImage(asset);
      precacheFutures.add(
        precacheImage(provider, context).catchError((error) {
          debugPrint('Failed to load asset: $asset');
          return null;
        }),
      );
    }

    // Wait for all images to be cached
    await Future.wait(precacheFutures);
  }
}

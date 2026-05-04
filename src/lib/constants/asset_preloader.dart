import 'package:flutter/material.dart';

class AssetPreloader {
  static Future<void> precacheAllAssets(BuildContext context) async {
    // Create a list of futures for parallel loading
    final List<Future<void>> precacheFutures = [];

    final List<String> assets = [
      // Logo assets
      'assets/LogoWildlifeNL.png',
      'assets/LogoHeadWildlifeNL.png',

      // Animal icon assets
      'assets/icons/animals/wolf.png',
      'assets/icons/animals/vos.png',
      'assets/icons/animals/das.png',
      'assets/icons/animals/ree.png',
      'assets/icons/animals/wild_zwijn.png',
      'assets/icons/animals/damhert.png',
      'assets/icons/animals/egel.png',
      'assets/icons/animals/eekhoorn.png',
      'assets/icons/animals/beaver.png',
      'assets/icons/animals/boommarten.png',
      'assets/icons/animals/hooglander.png',
      'assets/icons/animals/winsent.png',

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

      // Animal photos (assets/animals)
      'assets/animals/wolf.png',
      'assets/animals/vos.png',
      'assets/animals/das.png',
      'assets/animals/ree.png',
      'assets/animals/damhert.png',
      'assets/animals/edelhert.png',
      'assets/animals/wild zwijn.png',
      'assets/animals/bever.png',
      'assets/animals/eekhoorn.png',
      'assets/animals/egel.png',
      'assets/animals/steenmarter.png',
      'assets/animals/boommarter.png',
      'assets/animals/bunzing.png',
      'assets/animals/wezel.png',
      'assets/animals/hermelijn.png',
      'assets/animals/otter.png',
      'assets/animals/wild kat.png',
      'assets/animals/wisent.png',
      'assets/animals/hooglander.png',
      'assets/animals/galloway.png',
      'assets/animals/konikpaard.png',
      'assets/animals/shetland pony.png',
      'assets/animals/exmoor pony.png',
      'assets/animals/tauros.png',
      'assets/animals/europese nerts.png',
      'assets/animals/woelrat.png',
      'assets/animals/goudjakhals.png',
      'assets/animals/haas.png',
      'assets/animals/konijn.png',
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class LocationMapPreview extends StatelessWidget {
  const LocationMapPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Consumer<MapProvider>(
      builder: (context, mapProvider, child) {
        // Show loading only when neither current nor selected position is known
        if (mapProvider.currentPosition == null &&
            mapProvider.selectedPosition == null) {
          return Container(
            height: responsive.hp(14),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(responsive.sp(3.75)),
              ),
            ),
            child: Center(
              child: SizedBox(
                width: responsive.sp(6),
                height: responsive.sp(6),
                child: Lottie.asset(
                  'assets/loaders/loading_paw.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                  frameRate: FrameRate(60),
                ),
              ),
            ),
          );
        }

        // Get the position to display (either selected or current)
        final position =
            mapProvider.selectedPosition ?? mapProvider.currentPosition!;
        final point = LatLng(position.latitude, position.longitude);

        return Stack(
          children: [
            SizedBox(
              height: responsive.hp(14),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(responsive.sp(3.75)),
                ),
                child: flutter_map.FlutterMap(
                  mapController: mapProvider.mapController,
                  options: flutter_map.MapOptions(
                    initialCenter: point,
                    initialZoom: 15,
                    interactionOptions: const flutter_map.InteractionOptions(
                      flags: flutter_map.InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    flutter_map.TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.wildgids.app',
                    ),
                    flutter_map.MarkerLayer(
                      markers: [
                        flutter_map.Marker(
                          point: point,
                          width: responsive.sp(6),
                          height: responsive.sp(6),
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: responsive.sp(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Fullscreen expand icon removed; selection now triggered via 'Selecteer' button in parent UI
          ],
        );
      },
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/models/enums/location_type.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:lottie/lottie.dart';

class LocationMapPreview extends StatelessWidget {
  const LocationMapPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, child) {
        // Show placeholder for unknown location
        if (mapProvider.selectedAddress == LocationType.unknown.displayText) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Geen locatie geselecteerd',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        // Show loading animation when either position is null OR address is empty
        if (mapProvider.currentPosition == null ||
            mapProvider.selectedAddress.isEmpty) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 100,
                height: 100,
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

        return SizedBox(
          height: 150,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.wildrapport.app',
                ),
                flutter_map.MarkerLayer(
                  markers: [
                    flutter_map.Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

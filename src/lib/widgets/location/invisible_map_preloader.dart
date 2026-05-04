import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/providers/map_provider.dart';

class InvisibleMapPreloader extends StatelessWidget {
  const InvisibleMapPreloader({super.key});

  @override
  Widget build(BuildContext context) {
    final mapController = context.read<MapProvider>().mapController;

    return Opacity(
      opacity: 0,
      child: SizedBox(
        width: 1,
        height: 1,
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: const LatLng(
              52.0,
              5.0,
            ), // Can be any default NL position
            initialZoom: 5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: const [],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/managers/map/location_map_manager.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/screens/shared/overzicht_screen.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:wildrapport/models/api_models/interaction_query_result.dart';

class KaartOverviewScreen extends StatefulWidget {
  const KaartOverviewScreen({super.key});

  @override
  State<KaartOverviewScreen> createState() => _KaartOverviewScreenState();
}

class _KaartOverviewScreenState extends State<KaartOverviewScreen>
    with TickerProviderStateMixin {
  final _location = LocationMapManager();

  Timer? _debounce;
  static const _debounceMs = 450;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel(); // <-- clean up debounce timer
    super.dispose();
  }

  void _queueFetch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (mounted) _fetchAllForView();
    });
  }

  Future<void> _fetchAllForView() async {
    final map = context.read<MapProvider>();
    final camera = map.mapController.camera;
    final center = camera.center;
    final zoom = camera.zoom;

    final widthPx = MediaQuery.of(context).size.width;
    final metersPerPixel =
        156543.03392 *
        math.cos(center.latitude * math.pi / 180.0) /
        math.pow(2.0, zoom);
    final radius = ((widthPx / 2) * metersPerPixel).round().clamp(1000, 30000);

    final now = DateTime.now().toUtc();
    final after = now.subtract(const Duration(days: 30));

    await map.loadAllPinsForView(
      lat: center.latitude,
      lon: center.longitude,
      radiusMeters: radius,
      after: after,
      before: now,
    );

    debugPrint(
      '[Map] initial totals  animals=${map.animalPins.length} '
      'detections=${map.detectionPins.length} interactions=${map.interactions.length} '
      'total=${map.totalPins}',
    );
  }

  Future<void> _bootstrap() async {
    final map = context.read<MapProvider>();
    final app = context.read<AppStateProvider>();
    final mgr = _location;

    // Get a position (cache → GPS)
    Position? pos = app.isLocationCacheValid ? app.cachedPosition : null;
    pos ??= await mgr.determinePosition();
    if (!mounted || pos == null) return;

    // clamp to NL center if outside
    if (!mgr.isLocationInNetherlands(pos.latitude, pos.longitude)) {
      pos = Position(
        latitude: LocationMapManager.denBoschCenter.latitude,
        longitude: LocationMapManager.denBoschCenter.longitude,
        timestamp: DateTime.now(),
        accuracy: 100,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    // Set the position immediately
    await map.resetToCurrentLocation(pos, 'Locatie gevonden'); // fallback text

// Send tracking ping once on first load (R2)
    context.read<MapProvider>().sendTrackingPingFromPosition(pos);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        map.mapController.move(LatLng(pos!.latitude, pos.longitude), 15);

        final now = DateTime.now().toUtc();
        await map.loadAllPinsForView(
          lat: pos.latitude,
          lon: pos.longitude,
          radiusMeters: 5000, // start wide
          after: now.subtract(const Duration(days: 365)),
          before: now,
        );

        debugPrint(
          '[Map] initial totals  animals=${map.animalPins.length} '
          'detections=${map.detectionPins.length} interactions=${map.interactions.length} '
          'total=${map.totalPins}',
        );

        _queueFetch(); // keep the debounced updates on pan/zoom
      } catch (_) {}
    });

    try {
      final address = await mgr.getAddressFromPosition(pos);
      if (!mounted) return;
      // Update address without clearing position
      map.setSelectedLocation(pos, address);
    } catch (e) {
      debugPrint('[Kaart] Reverse geocoding failed on web: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapProvider>();
    final pos = map.selectedPosition ?? map.currentPosition;

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) return true;
        context.read<NavigationStateInterface>().pushReplacementBack(
          context,
          const OverzichtScreen(),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kaart'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.read<NavigationStateInterface>().pushReplacementBack(
                  context,
                  const OverzichtScreen(),
                );
              }
            },
          ),
        ),
        body:
            pos == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                  children: [
                    fm.FlutterMap(
                      mapController: map.mapController,
                      options: fm.MapOptions(
                        initialCenter: LatLng(pos.latitude, pos.longitude),
                        initialZoom: 15,
                        interactionOptions: const fm.InteractionOptions(
                          flags: fm.InteractiveFlag.all,
                        ),
                        onMapEvent: (evt) => _queueFetch(),
                      ),
                      children: [
                        fm.TileLayer(
                          urlTemplate: LocationMapManager.standardTileUrl,
                          userAgentPackageName: 'com.wildrapport.app',
                        ),
                        // animal pins
                        fm.MarkerLayer(
                          markers:
                              map.animalPins.map((pin) {
                                return fm.Marker(
                                  point: LatLng(pin.lat, pin.lon),
                                  width: 32,
                                  height: 32,
                                  child: const Icon(
                                    Icons.pets,
                                    size: 28,
                                  ),
                                );
                              }).toList(),
                        ),

                        // detection pins
                        fm.MarkerLayer(
                          markers:
                              map.detectionPins.map((pin) {
                                return fm.Marker(
                                  point: LatLng(pin.lat, pin.lon),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.sensors,
                                    size: 34,
                                  ),
                                );
                              }).toList(),
                        ),
                        fm.MarkerLayer(
                          markers: [
                            fm.Marker(
                              point: LatLng(pos.latitude, pos.longitude),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.my_location, size: 30),
                            ),
                          ],
                        ),
                        // interaction pins
                        fm.MarkerLayer(
                          markers:
                              map.interactions.map((
                                InteractionQueryResult itx,
                              ) {
                                return fm.Marker(
                                  point: LatLng(itx.lat, itx.lon),
                                  width: 36,
                                  height: 36,
                                  child: GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder:
                                            (_) => Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    itx.speciesName ??
                                                        itx.typeName ??
                                                        'Interactie',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    itx.description ??
                                                        'Geen omschrijving',
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    itx.moment
                                                        .toLocal()
                                                        .toString(),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '${itx.lat.toStringAsFixed(5)}, ${itx.lon.toStringAsFixed(5)}',
                                                  ),
                                                ],
                                              ),
                                            ),
                                      );
                                    },
                                    child: const Icon(Icons.place, size: 28),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),

                    // ── Status chips: one per layer ────────────────────────────────────────────────
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Builder(
                        builder: (context) {
                          final mp = context.watch<MapProvider>();

                          Widget chip(
                            String label,
                            int count, {
                            bool loading = false,
                            bool error = false,
                            IconData? icon,
                          }) {
                            final text =
                                loading
                                    ? '$label: …'
                                    : (error
                                        ? '$label: Err'
                                        : '$label: $count');
                            return Chip(
                              avatar:
                                  icon != null ? Icon(icon, size: 16) : null,
                              label: Text(text),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }

                          return Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  chip(
                                    'Animals',
                                    mp.animalPins.length,
                                    loading: mp.animalPinsLoading,
                                    error: mp.animalPinsError != null,
                                    icon: Icons.pets,
                                  ),
                                  chip(
                                    'Detections',
                                    mp.detectionPins.length,
                                    loading: mp.detectionPinsLoading,
                                    error: mp.detectionPinsError != null,
                                    icon: Icons.sensors,
                                  ),
                                  chip(
                                    'Interacts',
                                    mp.interactions.length,
                                    loading: mp.interactionsLoading,
                                    error: mp.interactionsError != null,
                                    icon: Icons.place,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Center on me',
          onPressed: () async {
            final fresh = await _location.determinePosition();
            if (fresh != null) {
              final addr = await _location.getAddressFromPosition(fresh);
              await context.read<MapProvider>().resetToCurrentLocation(
                fresh,
                addr,
              );
              context.read<MapProvider>().mapController.move(
                LatLng(fresh.latitude, fresh.longitude),
                16,
              );

              // Send tracking ping when user recenters (R2)
      context.read<MapProvider>().sendTrackingPingFromPosition(fresh);
              _queueFetch();
            }
          },
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/managers/map/location_map_manager.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/screens/shared/overzicht_screen.dart';
import 'package:wildrapport/screens/profile/profile_screen.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart'
    as cl;
import 'package:wildrapport/managers/map/location_helpers.dart';
import 'package:wildrapport/widgets/overlay/encounter_notice_overlay.dart';

class KaartOverviewScreen extends StatefulWidget {
  const KaartOverviewScreen({super.key});

  @override
  State<KaartOverviewScreen> createState() => _KaartOverviewScreenState();
}

class _KaartOverviewScreenState extends State<KaartOverviewScreen>
    with TickerProviderStateMixin {
  final _location = LocationMapManager();

  // cache things we must clean up
  late MapProvider _mp;                    // <— cached provider
  StreamSubscription<Position>? _posSub;
  VoidCallback? _mpListener;
  bool _listenerAttached = false;
  Timer? _debounce;
  String? _lastNoticeKey;

  double? _lastZoom;
  static const _debounceMs = 450;

  bool _useClusters = true;
  static const double _clusterUntilZoom = 16.0;

static const double _initialZoom = 15.0; // same as your initialZoom
bool _followUser = true;
bool _mapReady = false;




@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _mp = context.read<MapProvider>();

  _mpListener ??= () {
    debugPrint('[Kaart] 📨 Listener triggered');
    final n = _mp.lastTrackingNotice;
    
    if (n == null) {
      debugPrint('[Kaart] No tracking notice to show');
      return;
    }
    
    if (!mounted) {
      debugPrint('[Kaart] Widget not mounted, skipping notice');
      return;
    }
    
    debugPrint('[Kaart] Received notice: "${n.text}" (severity: ${n.severity})');

    // Dedup the same notice
    final key = '${n.text}|${n.severity ?? ''}';
    if (_lastNoticeKey == key) {
      debugPrint('[Kaart] Duplicate notice, skipping');
      return;
    }
    _lastNoticeKey = key;

    debugPrint('[Kaart] Scheduling SnackBar to show');
    
    // Schedule the snackbar to show after the current frame completes
    // This ensures we're not modifying the widget tree during a build
    Future.microtask(() {
      if (!mounted) return;
      
      // Use a post-frame callback as an extra safety layer
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        try {
          debugPrint('[Kaart] 🎉 Showing encounter notice dialog: "${n.text}"');
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => EncounterNoticeOverlay(message: n.text),
          );
        } catch (e) {
          debugPrint('[Kaart] ❌ Failed to show tracking notice: $e');
        }
      });
    });
  };

  if (!_listenerAttached) {
    debugPrint('[Kaart] 🔗 Attaching listener to MapProvider');
    _mp.addListener(_mpListener!);
    _listenerAttached = true;
  }
}

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _startFollowingMe();
  }

@override
void dispose() {
  _debounce?.cancel();
  _posSub?.cancel();                      // <— IMPORTANT
  if (_listenerAttached && _mpListener != null) {
    _mp.removeListener(_mpListener!);
  }
  _mp.stopTracking();
  super.dispose();
}


  void _queueFetch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (mounted) _fetchAllForView();
    });
  }

void _startFollowingMe() {
  const settings = LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 5,
  );

  _posSub = Geolocator.getPositionStream(locationSettings: settings).listen(
    (pos) async {
      if (!mounted) return;

      // accuracy can be null on some platforms
      final double acc = pos.accuracy;
      final String accStr =
          (acc.isNaN || acc.isInfinite || acc <= 0) ? '?' : acc.toStringAsFixed(1);

      debugPrint(
        '[ME/live] ${pos.latitude.toStringAsFixed(6)}, '
        '${pos.longitude.toStringAsFixed(6)}  acc=$accStr m',
      );

      // use cached provider, not context.read(...)
      await _mp.updatePosition(pos, _mp.currentAddress);

      // 🔔 Send tracking ping on position update to check for encounters
      debugPrint('[ME/live] 📡 Sending tracking ping for position update');
      final notice = await _mp.sendTrackingPingFromPosition(pos);
      if (notice != null) {
        debugPrint('[ME/live] 🔔 Received notice from tracking ping: "${notice.text}"');
        // Display the message immediately as per requirement
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => EncounterNoticeOverlay(message: notice.text),
          );
        }
      } else {
        debugPrint('[ME/live] No notice from position update');
      }

      // ✅ keep center on user only when following
      if (_followUser) {
        final z = _mp.mapController.camera.zoom;
        _mp.mapController.move(LatLng(pos.latitude, pos.longitude), z);
      }
    },
  );
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

    // Log all animals with JSON output
    debugPrint('═══════════════════════════════════════════════════════════════');
    debugPrint('[ANIMALS] Total count: ${map.animalPins.length}');
    debugPrint('═══════════════════════════════════════════════════════════════');
    
    for (int i = 0; i < map.animalPins.length; i++) {
      final animal = map.animalPins[i];
      try {
        final jsonOutput = jsonEncode({
          'index': i,
          'id': animal.id,
          'speciesName': animal.speciesName,
          'lat': animal.lat,
          'lon': animal.lon,
          'seenAt': animal.seenAt.toIso8601String(),
        });
        debugPrint('[ANIMAL $i] JSON: $jsonOutput');
      } catch (e) {
        debugPrint('[ANIMAL $i] Error serializing: $e');
        debugPrint('[ANIMAL $i] Raw: id=${animal.id}, species=${animal.speciesName}, lat=${animal.lat}, lon=${animal.lon}, seenAt=${animal.seenAt}');
      }
    }
    debugPrint('═══════════════════════════════════════════════════════════════');
  }

 Future<void> _bootstrap() async {
  final map = context.read<MapProvider>();
  final app = context.read<AppStateProvider>();
  final mgr = _location; // LocationMapManager

  // 1) Get a position (cache → GPS)
  Position? pos = app.isLocationCacheValid ? app.cachedPosition : null;
  pos ??= await mgr.determinePosition();

  // Log what we got
  debugPrint('[Loc] raw=${pos?.latitude},${pos?.longitude}');

  // 2) Fallback to NL center if missing/outside bounds
  if (pos == null ||
      !mgr.isLocationInNetherlands(pos.latitude, pos.longitude)) {
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
    debugPrint('[Loc] using fallback center: '
        '${pos.latitude},${pos.longitude}');
  }

  // 3) Apply immediately to provider (don't wait for address)
  await map.resetToCurrentLocation(pos, 'Locatie gevonden');

  // 4) Send one tracking ping (R2) on first load
  debugPrint('[Kaart/Bootstrap] 📡 Sending initial tracking ping');
  final initialNotice = await map.sendTrackingPingFromPosition(pos);
  if (initialNotice != null) {
    debugPrint('[Kaart/Bootstrap] 🔔 Initial ping returned notice: "${initialNotice.text}"');
  } else {
    debugPrint('[Kaart/Bootstrap] Initial ping returned no notice');
  }
  
  debugPrint('[Kaart/Bootstrap] ⏰ Starting periodic tracking (every 10s)');
  map.startTracking(interval: const Duration(seconds: 10));

  // 5) Move camera & load data after first frame so the map is mounted
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      map.mapController.move(LatLng(pos!.latitude, pos.longitude), _initialZoom);

      final now = DateTime.now().toUtc();
      await map.loadAllPinsForView(
        lat: pos.latitude,
        lon: pos.longitude,
        radiusMeters: 5000, // start fairly wide
        after: now.subtract(const Duration(days: 365)),
        before: now,
      );

      debugPrint('[Map] initial totals  '
          'animals=${map.animalPins.length} '
          'detections=${map.detectionPins.length} '
          'interactions=${map.interactions.length} '
          'total=${map.totalPins}');

      // Log all animals with JSON output
      debugPrint('═══════════════════════════════════════════════════════════════');
      debugPrint('[BOOTSTRAP ANIMALS] Total count: ${map.animalPins.length}');
      debugPrint('═══════════════════════════════════════════════════════════════');
      
      for (int i = 0; i < map.animalPins.length; i++) {
        final animal = map.animalPins[i];
        try {
          final jsonOutput = jsonEncode({
            'index': i,
            'id': animal.id,
            'speciesName': animal.speciesName,
            'lat': animal.lat,
            'lon': animal.lon,
            'seenAt': animal.seenAt.toIso8601String(),
          });
          debugPrint('[BOOTSTRAP ANIMAL $i] JSON: $jsonOutput');
        } catch (e) {
          debugPrint('[BOOTSTRAP ANIMAL $i] Error serializing: $e');
          debugPrint('[BOOTSTRAP ANIMAL $i] Raw: id=${animal.id}, species=${animal.speciesName}, lat=${animal.lat}, lon=${animal.lon}, seenAt=${animal.seenAt}');
        }
      }
      debugPrint('═══════════════════════════════════════════════════════════════');

      _queueFetch(); // keep in sync with pan/zoom
    } catch (_) {}
  });

  // 6) Reverse-geocode address (don’t block UI)
  try {
    final address = await mgr.getAddressFromPosition(pos);
    if (!mounted) return;
    map.setSelectedLocation(pos, address);
  } catch (e) {
    debugPrint('[Kaart] Reverse geocoding failed: $e');
  }
}


  Widget _clusterBadge({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    // circular icon with a small count badge
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.95),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                blurRadius: 6,
                spreadRadius: 1,
                offset: Offset(0, 2),
                color: Colors.black26,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Helper to build a scrollable bottom sheet that won't overflow
  Widget _buildBottomSheet(List<Widget> children) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0, top: 6.0),
              child: IconButton(
                icon: const Icon(Icons.person),
                color: AppColors.brown,
                iconSize: 22.0,
                onPressed: () {
                  debugPrint('[KaartOverviewScreen] profile icon pressed');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
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
                        initialZoom: _initialZoom,
                          onMapReady: () {
    debugPrint('[Map] ready');
    _mapReady = true;
  },

interactionOptions: const fm.InteractionOptions(
  flags: fm.InteractiveFlag.drag |
         fm.InteractiveFlag.pinchZoom |
         fm.InteractiveFlag.doubleTapZoom |
         fm.InteractiveFlag.scrollWheelZoom |
         fm.InteractiveFlag.flingAnimation |
         fm.InteractiveFlag.pinchMove,
),


onMapEvent: (evt) {
  final mp = context.read<MapProvider>();
  final currentZoom = mp.mapController.camera.zoom;
  final isProgrammatic = evt.source == fm.MapEventSource.mapController;

  // Stop following only on user gestures
  if (!isProgrammatic && (evt is fm.MapEventMoveStart || evt is fm.MapEventMove)) {
    if (_followUser) _followUser = false; // no setState needed
  }

  // Handle zoom changes only for user gestures
  if (!isProgrammatic && _lastZoom != currentZoom) {
    _lastZoom = currentZoom;

    _queueFetch();

    final next = currentZoom < _clusterUntilZoom;
    if (next != _useClusters && mounted) {
      setState(() => _useClusters = next);
    }

    // Recenter only if following (still user-driven)
    final p = mp.currentPosition ?? mp.selectedPosition;
    if (_followUser && p != null) {
      mp.mapController.move(LatLng(p.latitude, p.longitude), currentZoom);
    }
  }

  // Only fetch after a user pan ends
  if (!isProgrammatic && evt is fm.MapEventMoveEnd) {
    _queueFetch();
  }
},




                      ),
                      children: [
                        fm.TileLayer(
                          urlTemplate: LocationMapManager.standardTileUrl,
                          userAgentPackageName: 'com.wildrapport.app',
                        ),

                        // ── ANIMALS ───────────────────────────────────────────────────────────────
                        _useClusters
                            ? cl.MarkerClusterLayerWidget(
                              options: cl.MarkerClusterLayerOptions(
                                markers:
                                    map.animalPins
                                        .map(
                                          (pin) => fm.Marker(
                                            point: LatLng(pin.lat, pin.lon),
                                            width: 32,
                                            height: 32,
                                            child: const Icon(
                                              Icons.pets,
                                              size: 28,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                maxClusterRadius: 60,
                                disableClusteringAtZoom: 99,
                                padding: const EdgeInsets.all(40),
                                maxZoom: 17.0,
                                polygonOptions: const cl.PolygonOptions(
                                  borderColor: Colors.transparent,
                                ),
                                zoomToBoundsOnClick: true,
                                markerChildBehavior: true,
                                builder:
                                    (context, markers) => _clusterBadge(
                                      icon: Icons.pets,
                                      count: markers.length,
                                      color: Colors.teal,
                                    ),
                              ),
                            )
                            : fm.MarkerLayer(
                              markers:
                                  map.animalPins
                                      .map(
                                        (pin) => fm.Marker(
                                          point: LatLng(pin.lat, pin.lon),
                                          width:
                                              44, // bigger, easier tap target
                                          height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              showModalBottomSheet(
                                                context: context,
                                                builder: (_) =>
                                                    _buildBottomSheet([
                                                  Text(
                                                    pin.speciesName ?? 'Dier',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Waargenomen: ${pin.seenAt.toLocal().toString().substring(0, 16)}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Locatie: ${pin.lat.toStringAsFixed(5)}, ${pin.lon.toStringAsFixed(5)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ]),
                                              );
                                            },
                                            child: const Icon(
                                              Icons.pets,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),

                        // ── DETECTIONS ────────────────────────────────────────────────────────────
                        _useClusters
                            ? cl.MarkerClusterLayerWidget(
                              options: cl.MarkerClusterLayerOptions(
                                markers:
                                    map.detectionPins
                                        .map(
                                          (pin) => fm.Marker(
                                            point: LatLng(pin.lat, pin.lon),
                                            width: 40,
                                            height: 40,
                                            child: const Icon(
                                              Icons.sensors,
                                              size: 34,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                maxClusterRadius: 60,
                                disableClusteringAtZoom: 99,
                                padding: const EdgeInsets.all(40),
                                maxZoom: 17.0,
                                polygonOptions: const cl.PolygonOptions(
                                  borderColor: Colors.transparent,
                                ),
                                zoomToBoundsOnClick: true,
                                markerChildBehavior: true,
                                builder:
                                    (context, markers) => _clusterBadge(
                                      icon: Icons.sensors,
                                      count: markers.length,
                                      color: Colors.indigo,
                                    ),
                              ),
                            )
                            : fm.MarkerLayer(
                              markers:
                                  map.detectionPins
                                      .map(
                                        (pin) => fm.Marker(
                                          point: LatLng(pin.lat, pin.lon),
                                          width: 44,
                                          height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              showModalBottomSheet(
                                                context: context,
                                                builder: (_) =>
                                                    _buildBottomSheet([
                                                  const Text(
                                                    'Detectie',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '${pin.lat.toStringAsFixed(5)}, ${pin.lon.toStringAsFixed(5)}',
                                                  ),
                                                ]),
                                              );
                                            },
                                            child: const Icon(
                                              Icons.sensors,
                                              size: 34,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),

                        // ── CURRENT POSITION ─────────────────────────────────────────────────────
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

                        // ── INTERACTIONS (keep this LAST so it receives taps first) ──────────────
                        _useClusters
                            ? cl.MarkerClusterLayerWidget(
                              options: cl.MarkerClusterLayerOptions(
                                markers:
                                    map.interactions
                                        .map(
                                          (itx) {
                                            // Calculate age for color
                                            final age = DateTime.now().difference(itx.moment);
                                            final isRecent = age.inHours < 1;
                                            final pinColor = isRecent ? Colors.red : Colors.deepOrange;
                                            
                                            return fm.Marker(
                                              point: LatLng(itx.lat, itx.lon),
                                              width: 44, // easier tap target
                                              height: 44,
                                              child: GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    builder: (_) =>
                                                        _buildBottomSheet([
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
                                                    ]),
                                                  );
                                                },
                                                child: Icon(
                                                  Icons.place,
                                                  size: 28,
                                                  color: pinColor,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                        .toList(),
                                maxClusterRadius: 60,
                                disableClusteringAtZoom: 99,
                                padding: const EdgeInsets.all(40),
                                maxZoom: 17.0,
                                polygonOptions: const cl.PolygonOptions(
                                  borderColor: Colors.transparent,
                                ),
                                zoomToBoundsOnClick: true,
                                markerChildBehavior:
                                    true, // let child handle taps
                                builder:
                                    (context, markers) => _clusterBadge(
                                      icon: Icons.place,
                                      count: markers.length,
                                      color: Colors.deepOrange,
                                    ),
                              ),
                            )
                            : fm.MarkerLayer(
                              markers:
                                  map.interactions
                                      .map(
                                        (itx) {
                                          // Calculate age for color
                                          final age = DateTime.now().difference(itx.moment);
                                          final isRecent = age.inHours < 1;
                                          final pinColor = isRecent ? Colors.red : Colors.deepOrange;
                                          
                                          return fm.Marker(
                                            point: LatLng(itx.lat, itx.lon),
                                            width: 44,
                                            height: 44,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  builder: (_) =>
                                                      _buildBottomSheet([
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
                                                  ]),
                                                );
                                              },
                                              child: Icon(
                                                Icons.place,
                                                size: 28,
                                                color: pinColor,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                      .toList(),
                            ),
                      ],
                    ),

                    // ── Status chips ────────────────────────────────────────────────────────────
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
  child: const Icon(Icons.my_location),
onPressed: () async {
  final mp = context.read<MapProvider>();
  debugPrint('[FAB] tapped');

  // instant jump (no rebuild)
  _followUser = true;

  // pick a quick target
  Position? target = mp.currentPosition ?? mp.selectedPosition;
  target ??= await Geolocator.getLastKnownPosition();

  if (target != null) {
    mp.mapController.move(LatLng(target.latitude, target.longitude), _initialZoom);
  } else {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Zoeken naar je locatie…'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
  }

  // resolve fresh GPS + address in background (don’t block the jump)
  Future(() async {
    Position? fresh;
    try {
      fresh = await Geolocator
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}

    fresh ??= target;
    if (fresh == null || !mounted) return;

    String address = mp.currentAddress ?? 'Locatie gevonden';
    try {
      final a = await _location.getAddressFromPosition(fresh);
      if (a != null && a.trim().isNotEmpty) address = a;
    } catch (e) {
      debugPrint('[FAB] Reverse geocoding failed: $e');
    }

    await mp.resetToCurrentLocation(fresh, address);
    await mp.sendTrackingPingFromPosition(fresh);

    if (_followUser) {
      mp.mapController.move(LatLng(fresh.latitude, fresh.longitude), _initialZoom);
    }
    _queueFetch(); // now ok to refetch for the new view
  });
},

)



      ),
    );
  }
}

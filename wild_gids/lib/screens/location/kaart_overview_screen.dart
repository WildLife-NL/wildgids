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
import 'dart:convert';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart'
    as cl;

// Small helper struct for icon styling by age
class _IconStyle {
  final Color color;
  final double size;
  const _IconStyle(this.color, this.size);
}

class KaartOverviewScreen extends StatefulWidget {
  const KaartOverviewScreen({super.key});

  @override
  State<KaartOverviewScreen> createState() => _KaartOverviewScreenState();
}

class _KaartOverviewScreenState extends State<KaartOverviewScreen>
    with TickerProviderStateMixin {
  final _location = LocationMapManager();

  // cache things we must clean up
  late MapProvider _mp; // <— cached provider
  StreamSubscription<Position>? _posSub;
  Timer? _debounce;

  double? _lastZoom;
  static const _debounceMs = 450;

  bool _useClusters = true;
  static const double _clusterUntilZoom = 17.0;

  static const double _initialZoom = 15.0; // Initial zoom when map loads
  bool _followUser = true;

  // Filter state (default: show only last hour; enable others via filter)
  bool _showAnimals = true;
  bool _showDetections = true;
  bool _showInteractions = true;
  bool _showAnimalsNew = true; // < 24h
  bool _showAnimalsMedium = false; // 24h - 1 week
  bool _showAnimalsOld = false; // > 1 week
  bool _showDetectionsNew = true;
  bool _showDetectionsMedium = false;
  bool _showDetectionsOld = false;
  bool _showInteractionsNew = true;
  bool _showInteractionsMedium = false;
  bool _showInteractionsOld = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mp = context.read<MapProvider>();
    // Note: Encounter messages are now handled globally via GlobalEncounterHandler
    // No need for local listener here
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
    _posSub?.cancel();
    _mp.stopTracking();
    super.dispose();
  }

  void _queueFetch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (mounted) {
        final map = context.read<MapProvider>();
        map.loadVicinity();
      }
    });
  }

  void _startFollowingMe() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    _posSub = Geolocator.getPositionStream(locationSettings: settings).listen((
      pos,
    ) async {
      if (!mounted) return;

      // accuracy can be null on some platforms
      final double acc = pos.accuracy;
      final String accStr =
          (acc.isNaN || acc.isInfinite || acc <= 0)
              ? '?'
              : acc.toStringAsFixed(1);

      debugPrint(
        '[ME/live] ${pos.latitude.toStringAsFixed(6)}, '
        '${pos.longitude.toStringAsFixed(6)}  acc=$accStr m',
      );

      // use cached provider, not context.read(...)
      await _mp.updatePosition(pos, _mp.currentAddress);

      // 🔔 Send tracking ping on position update - only if tracking is enabled
      final appStateProvider = context.read<AppStateProvider>();
      if (appStateProvider.isLocationTrackingEnabled) {
        debugPrint('[ME/live] 📡 Sending tracking ping for position update');
        final notice = await _mp.sendTrackingPingFromPosition(pos);
        if (notice != null) {
          debugPrint(
            '[ME/live] 🔔 Received notice from tracking ping: "${notice.text}"',
          );
          // Notice will be displayed via the MapProvider listener and popup dialog
        } else {
          debugPrint('[ME/live] No notice from position update');
        }
      } else {
        debugPrint(
          '[ME/live] ⚠️ Skipping tracking ping - tracking disabled by user',
        );
      }

      // ✅ keep center on user only when following
      if (_followUser) {
        final z = _mp.mapController.camera.zoom;
        _mp.mapController.move(LatLng(pos.latitude, pos.longitude), z);
      }
    });
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
      debugPrint(
        '[Loc] using fallback center: '
        '${pos.latitude},${pos.longitude}',
      );
    }

    // 3) Apply immediately to provider (don't wait for address)
    await map.resetToCurrentLocation(pos, 'Locatie gevonden');

    // 4) Send one tracking ping (R2) on first load - only if tracking is enabled
    final appStateProvider = context.read<AppStateProvider>();
    if (appStateProvider.isLocationTrackingEnabled) {
      debugPrint('[Kaart/Bootstrap] 📡 Sending initial tracking ping');
      final initialNotice = await map.sendTrackingPingFromPosition(pos);
      if (initialNotice != null) {
        debugPrint(
          '[Kaart/Bootstrap] 🔔 Initial ping returned notice: "${initialNotice.text}"',
        );
      } else {
        debugPrint('[Kaart/Bootstrap] Initial ping returned no notice');
      }

      debugPrint('[Kaart/Bootstrap] ⏰ Starting periodic tracking (every 10s)');
      map.startTracking(interval: const Duration(seconds: 10));
    } else {
      debugPrint('[Kaart/Bootstrap] ⚠️ Location tracking is disabled by user');
      // Location tracking is optional, so we don't show a dialog
      // User can enable it later from profile settings if desired
    }

    // 5) Move camera & load data after first frame so the map is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        map.mapController.move(
          LatLng(pos!.latitude, pos.longitude),
          _initialZoom,
        );

        // Use new vicinity endpoint to load all data
        await map.loadVicinity();

        debugPrint(
          '[Map] initial totals  '
          'animals=${map.animalPins.length} '
          'detections=${map.detectionPins.length} '
          'interactions=${map.interactions.length} '
          'total=${map.totalPins}',
        );

        // Log all animals with JSON output
        debugPrint(
          '═══════════════════════════════════════════════════════════════',
        );
        debugPrint('[BOOTSTRAP ANIMALS] Total count: ${map.animalPins.length}');
        debugPrint(
          '═══════════════════════════════════════════════════════════════',
        );

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
            debugPrint(
              '[BOOTSTRAP ANIMAL $i] Raw: id=${animal.id}, species=${animal.speciesName}, lat=${animal.lat}, lon=${animal.lon}, seenAt=${animal.seenAt}',
            );
          }
        }
        debugPrint(
          '═══════════════════════════════════════════════════════════════',
        );

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

  /// Returns true if timestamp is within the last 31 days
  bool _within31Days(DateTime timestamp) {
    return DateTime.now().difference(timestamp) < const Duration(days: 31);
  }

  /// Check if a pin should be shown based on filter settings
  bool _shouldShowPin(
    DateTime timestamp,
    bool showType,
    bool showNew,
    bool showMedium,
    bool showOld,
  ) {
    if (!showType) return false;

    final now = DateTime.now();
    final age = now.difference(timestamp);

    if (age < const Duration(hours: 24)) {
      return showNew;
    } else if (age < const Duration(days: 7)) {
      return showMedium;
    } else {
      return showOld;
    }
  }

  /// Show filter dialog
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 600,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.darkGreen,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_list, color: Colors.white),
                            const SizedBox(width: 12),
                            const Text(
                              'Filter Map Icons',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // Scrollable content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main categories
                              _buildFilterSection('Main Categories', [
                                _buildFilterCheckbox(
                                  'Show Animals',
                                  _showAnimals,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showAnimals = v ?? true,
                                    ),
                                  ),
                                  Icons.pets,
                                ),
                                _buildFilterCheckbox(
                                  'Show Detections',
                                  _showDetections,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showDetections = v ?? true,
                                    ),
                                  ),
                                  Icons.sensors,
                                ),
                                _buildFilterCheckbox(
                                  'Show Interactions',
                                  _showInteractions,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showInteractions = v ?? true,
                                    ),
                                  ),
                                  Icons.place,
                                ),
                              ]),

                              const Divider(height: 32),

                              // Animals by age
                              _buildFilterSection('Animals by Age', [
                                _buildFilterCheckbox(
                                  'New (< 24 hours)',
                                  _showAnimalsNew,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showAnimalsNew = v ?? true,
                                    ),
                                  ),
                                  Icons.fiber_new,
                                ),
                                _buildFilterCheckbox(
                                  'Recent (24h - 1 week)',
                                  _showAnimalsMedium,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showAnimalsMedium = v ?? true,
                                    ),
                                  ),
                                  Icons.access_time,
                                ),
                                _buildFilterCheckbox(
                                  'Old (> 1 week)',
                                  _showAnimalsOld,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showAnimalsOld = v ?? true,
                                    ),
                                  ),
                                  Icons.history,
                                ),
                              ]),

                              const Divider(height: 32),

                              // Detections by age
                              _buildFilterSection('Detections by Age', [
                                _buildFilterCheckbox(
                                  'New (< 24 hours)',
                                  _showDetectionsNew,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showDetectionsNew = v ?? true,
                                    ),
                                  ),
                                  Icons.fiber_new,
                                ),
                                _buildFilterCheckbox(
                                  'Recent (24h - 1 week)',
                                  _showDetectionsMedium,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showDetectionsMedium = v ?? true,
                                    ),
                                  ),
                                  Icons.access_time,
                                ),
                                _buildFilterCheckbox(
                                  'Old (> 1 week)',
                                  _showDetectionsOld,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showDetectionsOld = v ?? true,
                                    ),
                                  ),
                                  Icons.history,
                                ),
                              ]),

                              const Divider(height: 32),

                              // Interactions by age
                              _buildFilterSection('Interactions by Age', [
                                _buildFilterCheckbox(
                                  'New (< 24 hours)',
                                  _showInteractionsNew,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showInteractionsNew = v ?? true,
                                    ),
                                  ),
                                  Icons.fiber_new,
                                ),
                                _buildFilterCheckbox(
                                  'Recent (24h - 1 week)',
                                  _showInteractionsMedium,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showInteractionsMedium = v ?? true,
                                    ),
                                  ),
                                  Icons.access_time,
                                ),
                                _buildFilterCheckbox(
                                  'Old (> 1 week)',
                                  _showInteractionsOld,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showInteractionsOld = v ?? true,
                                    ),
                                  ),
                                  Icons.history,
                                ),
                              ]),

                              const SizedBox(height: 16),

                              // Reset and Apply buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setDialogState(() {
                                          setState(() {
                                            _showAnimals = true;
                                            _showDetections = true;
                                            _showInteractions = true;
                                            _showAnimalsNew = true;
                                            _showAnimalsMedium = true;
                                            _showAnimalsOld = true;
                                            _showDetectionsNew = true;
                                            _showDetectionsMedium = true;
                                            _showDetectionsOld = true;
                                            _showInteractionsNew = true;
                                            _showInteractionsMedium = true;
                                            _showInteractionsOld = true;
                                          });
                                        });
                                      },
                                      child: const Text('Reset All'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.darkGreen,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Apply'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildFilterSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGreen,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildFilterCheckbox(
    String label,
    bool value,
    Function(bool?) onChanged,
    IconData icon,
  ) {
    return CheckboxListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.darkGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.darkGreen,
    );
  }

  /// Helper to build a scrollable bottom sheet that won't overflow
  Widget _buildBottomSheet(List<Widget> children) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: 400,
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
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
          centerTitle: true,
          title: const Text('Kaart', style: TextStyle(fontFamily: 'Overpass')),
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
                color: Colors.black,
                iconSize: 32.0,
                onPressed: () {
                  debugPrint('[KaartOverviewScreen] profile icon pressed');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
                        },

                        interactionOptions: const fm.InteractionOptions(
                          flags:
                              fm.InteractiveFlag.drag |
                              fm.InteractiveFlag.pinchZoom |
                              fm.InteractiveFlag.doubleTapZoom |
                              fm.InteractiveFlag.scrollWheelZoom |
                              fm.InteractiveFlag.flingAnimation |
                              fm.InteractiveFlag.pinchMove,
                        ),

                        onMapEvent: (evt) {
                          final mp = context.read<MapProvider>();
                          final currentZoom = mp.mapController.camera.zoom;
                          final isProgrammatic =
                              evt.source == fm.MapEventSource.mapController;

                          // Stop following only on user gestures
                          if (!isProgrammatic &&
                              (evt is fm.MapEventMoveStart ||
                                  evt is fm.MapEventMove)) {
                            if (_followUser)
                              _followUser = false; // no setState needed
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
                              mp.mapController.move(
                                LatLng(p.latitude, p.longitude),
                                currentZoom,
                              );
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
                                        .where((pin) => _within31Days(pin.seenAt))
                                        .where(
                                          (pin) => _shouldShowPin(
                                            pin.seenAt,
                                            _showAnimals,
                                            _showAnimalsNew,
                                            _showAnimalsMedium,
                                            _showAnimalsOld,
                                          ),
                                        )
                                        .map((pin) {
                                          final style = _iconStyleForTimestamp(
                                            pin.seenAt,
                                          );
                                          return fm.Marker(
                                            point: LatLng(pin.lat, pin.lon),
                                            width: (style.size + 8).clamp(
                                              24.0,
                                              44.0,
                                            ),
                                            height: (style.size + 8).clamp(
                                              24.0,
                                              44.0,
                                            ),
                                            child:
                                                _getAnimalIconPath(
                                                          pin.speciesName,
                                                        ) !=
                                                        null
                                                    ? SizedBox(
                                                      width: style.size,
                                                      height: style.size,
                                                      child: ColorFiltered(
                                                        colorFilter:
                                                            ColorFilter.mode(
                                                              style.color,
                                                              BlendMode.srcIn,
                                                            ),
                                                        child: Image.asset(
                                                          _getAnimalIconPath(
                                                            pin.speciesName,
                                                          )!,
                                                          width: style.size,
                                                          height: style.size,
                                                          fit: BoxFit.contain,
                                                          errorBuilder: (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Icon(
                                                              Icons.pets,
                                                              size:
                                                                  style.size *
                                                                  0.9,
                                                              color:
                                                                  style.color,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    )
                                                    : Icon(
                                                      Icons.pets,
                                                      size: style.size,
                                                      color: style.color,
                                                    ),
                                          );
                                        })
                                        .toList()
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
                                      color: AppColors.darkGreen,
                                    ),
                              ),
                            )
                            : fm.MarkerLayer(
                              markers:
                                  map.animalPins
                                      .where((pin) => _within31Days(pin.seenAt))
                                      .where(
                                        (pin) => _shouldShowPin(
                                          pin.seenAt,
                                          _showAnimals,
                                          _showAnimalsNew,
                                          _showAnimalsMedium,
                                          _showAnimalsOld,
                                        ),
                                      )
                                      .map((pin) {
                                        return fm.Marker(
                                          point: LatLng(pin.lat, pin.lon),
                                          width:
                                              44, // bigger, easier tap target
                                          height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (_) => Dialog(
                                                      child: _buildBottomSheet([
                                                        // Show animal icon if available (centered)
                                                        if (_getAnimalIconPath(
                                                              pin.speciesName,
                                                            ) !=
                                                            null)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 12,
                                                                ),
                                                            child: Center(
                                                              child: Image.asset(
                                                                _getAnimalIconPath(
                                                                  pin.speciesName,
                                                                )!,
                                                                width: 80,
                                                                height: 80,
                                                                fit:
                                                                    BoxFit
                                                                        .contain,
                                                                errorBuilder: (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return const Icon(
                                                                    Icons.pets,
                                                                    size: 64,
                                                                    color:
                                                                        AppColors
                                                                            .darkGreen,
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),

                                                        // Animal name
                                                        Text(
                                                          'Animal: ${pin.speciesName ?? 'Onbekend'}',
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                AppColors
                                                                    .darkGreen,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),

                                                        // Date
                                                        Builder(
                                                          builder: (context) {
                                                            final local =
                                                                pin.seenAt
                                                                    .toLocal();
                                                            final dateStr =
                                                                '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
                                                            return Text(
                                                              'Date: $dateStr',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    AppColors
                                                                        .darkGreen,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),

                                                        // Time
                                                        Builder(
                                                          builder: (context) {
                                                            final local =
                                                                pin.seenAt
                                                                    .toLocal();
                                                            final timeStr =
                                                                '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
                                                            return Text(
                                                              'Time: $timeStr',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    AppColors
                                                                        .darkGreen,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),

                                                        // Location
                                                        Text(
                                                          'Location: ${pin.lat.toStringAsFixed(5)}, ${pin.lon.toStringAsFixed(5)}',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                AppColors
                                                                    .darkGreen,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ]),
                                                    ),
                                              );
                                            },
                                            child: Builder(
                                              builder: (ctx) {
                                                final style =
                                                    _iconStyleForTimestamp(
                                                      pin.seenAt,
                                                    );
                                                return _getAnimalIconPath(
                                                          pin.speciesName,
                                                        ) !=
                                                        null
                                                    ? SizedBox(
                                                      width: style.size,
                                                      height: style.size,
                                                      child: ColorFiltered(
                                                        colorFilter:
                                                            ColorFilter.mode(
                                                              style.color,
                                                              BlendMode.srcIn,
                                                            ),
                                                        child: Image.asset(
                                                          _getAnimalIconPath(
                                                            pin.speciesName,
                                                          )!,
                                                          width: style.size,
                                                          height: style.size,
                                                          fit: BoxFit.contain,
                                                          errorBuilder: (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Icon(
                                                              Icons.pets,
                                                              size:
                                                                  style.size *
                                                                  0.9,
                                                              color:
                                                                  style.color,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    )
                                                    : Icon(
                                                      Icons.pets,
                                                      size: style.size,
                                                      color: style.color,
                                                    );
                                              },
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                            ),

                        // ── DETECTIONS ────────────────────────────────────────────────────────────
                        _useClusters
                            ? cl.MarkerClusterLayerWidget(
                              options: cl.MarkerClusterLayerOptions(
                                markers:
                                    map.detectionPins
                                        .where((pin) => _within31Days(pin.detectedAt))
                                        .where(
                                          (pin) => _shouldShowPin(
                                            pin.detectedAt,
                                            _showDetections,
                                            _showDetectionsNew,
                                            _showDetectionsMedium,
                                            _showDetectionsOld,
                                          ),
                                        )
                                        .map((pin) {
                                          final style = _iconStyleForTimestamp(
                                            pin.detectedAt,
                                          );

                                          return fm.Marker(
                                            point: LatLng(pin.lat, pin.lon),
                                            width: (style.size + 8).clamp(
                                              24.0,
                                              44.0,
                                            ),
                                            height: (style.size + 8).clamp(
                                              24.0,
                                              44.0,
                                            ),
                                            child: Icon(
                                              Icons.sensors,
                                              size: style.size,
                                              color: style.color,
                                            ),
                                          );
                                        })
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
                                      color: AppColors.darkGreen,
                                    ),
                              ),
                            )
                            : fm.MarkerLayer(
                              markers:
                                  map.detectionPins
                                      .where((pin) => _within31Days(pin.detectedAt))
                                      .where(
                                        (pin) => _shouldShowPin(
                                          pin.detectedAt,
                                          _showDetections,
                                          _showDetectionsNew,
                                          _showDetectionsMedium,
                                          _showDetectionsOld,
                                        ),
                                      )
                                      .map((pin) {
                                        final style = _iconStyleForTimestamp(
                                          pin.detectedAt,
                                        );

                                        return fm.Marker(
                                          point: LatLng(pin.lat, pin.lon),
                                          width: (style.size + 8).clamp(
                                            24.0,
                                            44.0,
                                          ),
                                          height: (style.size + 8).clamp(
                                            24.0,
                                            44.0,
                                          ),
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (_) => Dialog(
                                                      child: _buildBottomSheet([
                                                        // Centered sensor icon for detections
                                                        const Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                bottom: 12,
                                                              ),
                                                          child: Center(
                                                            child: Icon(
                                                              Icons.sensors,
                                                              size: 64,
                                                              color:
                                                                  AppColors
                                                                      .darkGreen,
                                                            ),
                                                          ),
                                                        ),

                                                        // Title
                                                        const Text(
                                                          'Detectie',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                AppColors
                                                                    .darkGreen,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),

                                                        // Date
                                                        Builder(
                                                          builder: (context) {
                                                            final local =
                                                                pin.detectedAt
                                                                    .toLocal();
                                                            final dateStr =
                                                                '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
                                                            return Text(
                                                              'Date: $dateStr',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    AppColors
                                                                        .darkGreen,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),

                                                        // Time
                                                        Builder(
                                                          builder: (context) {
                                                            final local =
                                                                pin.detectedAt
                                                                    .toLocal();
                                                            final timeStr =
                                                                '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
                                                            return Text(
                                                              'Time: $timeStr',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    AppColors
                                                                        .darkGreen,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),

                                                        // Location
                                                        Text(
                                                          'Location: ${pin.lat.toStringAsFixed(5)}, ${pin.lon.toStringAsFixed(5)}',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                AppColors
                                                                    .darkGreen,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ]),
                                                    ),
                                              );
                                            },
                                            child: Icon(
                                              Icons.sensors,
                                              size: style.size,
                                              color: style.color,
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                            ),

                        // ── CURRENT POSITION ─────────────────────────────────────────────────────
                        // Only show user location pin if tracking is enabled
                        if (context
                            .watch<AppStateProvider>()
                            .isLocationTrackingEnabled)
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
                                        .where((itx) => _within31Days(itx.moment))
                                        .where(
                                          (itx) => _shouldShowPin(
                                            itx.moment,
                                            _showInteractions,
                                            _showInteractionsNew,
                                            _showInteractionsMedium,
                                            _showInteractionsOld,
                                          ),
                                        )
                                        .map((itx) {
                                      return fm.Marker(
                                        point: LatLng(itx.lat, itx.lon),
                                        width: 44, // easier tap target
                                        height: 44,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (_) => Dialog(
                                                    child: _buildBottomSheet([
                                                      // Centered icon (use animal icon when available)
                                                      if (_getAnimalIconPath(
                                                            itx.speciesName,
                                                          ) !=
                                                          null)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                bottom: 12,
                                                              ),
                                                          child: Center(
                                                            child: Image.asset(
                                                              _getAnimalIconPath(
                                                                itx.speciesName,
                                                              )!,
                                                              width: 80,
                                                              height: 80,
                                                              fit:
                                                                  BoxFit
                                                                      .contain,
                                                              errorBuilder: (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) {
                                                                return const Icon(
                                                                  Icons.place,
                                                                  size: 64,
                                                                  color:
                                                                      AppColors
                                                                          .darkGreen,
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        )
                                                      else
                                                        const Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                bottom: 12,
                                                              ),
                                                          child: Center(
                                                            child: Icon(
                                                              Icons.place,
                                                              size: 64,
                                                              color:
                                                                  AppColors
                                                                      .darkGreen,
                                                            ),
                                                          ),
                                                        ),

                                                      // Title (species or interaction type)
                                                      Text(
                                                        itx.speciesName ??
                                                            itx.typeName ??
                                                            'Interactie',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              AppColors
                                                                  .darkGreen,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 6),

                                                      // Date
                                                      Builder(
                                                        builder: (context) {
                                                          final local =
                                                              itx.moment
                                                                  .toLocal();
                                                          final dateStr =
                                                              '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
                                                          return Text(
                                                            'Date: $dateStr',
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  AppColors
                                                                      .darkGreen,
                                                            ),
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          );
                                                        },
                                                      ),
                                                      const SizedBox(height: 4),

                                                      // Time
                                                      Builder(
                                                        builder: (context) {
                                                          final local =
                                                              itx.moment
                                                                  .toLocal();
                                                          final timeStr =
                                                              '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
                                                          return Text(
                                                            'Time: $timeStr',
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  AppColors
                                                                      .darkGreen,
                                                            ),
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          );
                                                        },
                                                      ),
                                                      const SizedBox(height: 8),

                                                      // Location
                                                      Text(
                                                        'Location: ${itx.lat.toStringAsFixed(5)}, ${itx.lon.toStringAsFixed(5)}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              AppColors
                                                                  .darkGreen,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),

                                                      // Optional description (after main lines)
                                                      if (itx.description !=
                                                              null &&
                                                          itx.description!
                                                              .trim()
                                                              .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          itx.description!,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                AppColors
                                                                    .darkGreen,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ]),
                                                  ),
                                            );
                                          },
                                          child: Builder(
                                            builder: (ctx) {
                                              final style =
                                                  _iconStyleForTimestamp(
                                                    itx.moment,
                                                  );
                                              return _getAnimalIconPath(
                                                        itx.speciesName,
                                                      ) !=
                                                      null
                                                  ? SizedBox(
                                                    width: style.size,
                                                    height: style.size,
                                                    child: ColorFiltered(
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                            style.color,
                                                            BlendMode.srcIn,
                                                          ),
                                                      child: Image.asset(
                                                        _getAnimalIconPath(
                                                          itx.speciesName,
                                                        )!,
                                                        width: style.size,
                                                        height: style.size,
                                                        fit: BoxFit.contain,
                                                        errorBuilder: (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Icon(
                                                            Icons.place,
                                                            size:
                                                                style.size *
                                                                0.9,
                                                            color: style.color,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  )
                                                  : Icon(
                                                    Icons.place,
                                                    size: style.size,
                                                    color: style.color,
                                                  );
                                            },
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                builder:
                                    (context, markers) => _clusterBadge(
                                      icon: Icons.place,
                                      count: markers.length,
                                      color: AppColors.darkGreen,
                                    ),
                              ),
                            )
                            : fm.MarkerLayer(
                              markers:
                                  map.interactions
                                      .where((itx) => _within31Days(itx.moment))
                                      .where(
                                        (itx) => _shouldShowPin(
                                          itx.moment,
                                          _showInteractions,
                                          _showInteractionsNew,
                                          _showInteractionsMedium,
                                          _showInteractionsOld,
                                        ),
                                      )
                                      .map((itx) {
                                        return fm.Marker(
                                          point: LatLng(itx.lat, itx.lon),
                                          width: 44,
                                          height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (_) => Dialog(
                                                      child: _buildBottomSheet([
                                                        // Centered icon (use animal icon when available)
                                                        if (_getAnimalIconPath(
                                                              itx.speciesName,
                                                            ) !=
                                                            null)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 12,
                                                                ),
                                                            child: Center(
                                                              child: Image.asset(
                                                                _getAnimalIconPath(
                                                                  itx.speciesName,
                                                                )!,
                                                                width: 80,
                                                                height: 80,
                                                                fit:
                                                                    BoxFit
                                                                        .contain,
                                                                errorBuilder: (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return const Icon(
                                                                    Icons.place,
                                                                    size: 64,
                                                                    color:
                                                                        AppColors
                                                                            .darkGreen,
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          )
                                                        else
                                                          const Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                  bottom: 12,
                                                                ),
                                                            child: Center(
                                                              child: Icon(
                                                                Icons.place,
                                                                size: 64,
                                                                color:
                                                                    AppColors
                                                                        .darkGreen,
                                                              ),
                                                            ),
                                                          ),

                                                        // Title (species or interaction type)
                                                        Text(
                                                          itx.speciesName ??
                                                              itx.typeName ??
                                                              'Interactie',
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                AppColors
                                                                    .darkGreen,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),

                                                        // Date
                                                        Builder(
                                                          builder: (context) {
                                                            final local =
                                                                itx.moment
                                                                    .toLocal();
                                                            final dateStr =
                                                                '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
                                                            return Text(
                                                              'Date: $dateStr',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    AppColors
                                                                        .darkGreen,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),

                                                        // Time
                                                        Builder(
                                                          builder: (context) {
                                                            final local =
                                                                itx.moment
                                                                    .toLocal();
                                                            final timeStr =
                                                                '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
                                                            return Text(
                                                              'Time: $timeStr',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    AppColors
                                                                        .darkGreen,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),

                                                        // Location
                                                        Text(
                                                          'Location: ${itx.lat.toStringAsFixed(5)}, ${itx.lon.toStringAsFixed(5)}',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                AppColors
                                                                    .darkGreen,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ]),
                                                    ),
                                              );
                                            },
                                            child: Builder(
                                              builder: (ctx) {
                                                final style =
                                                    _iconStyleForTimestamp(
                                                      itx.moment,
                                                    );
                                                return _getAnimalIconPath(
                                                          itx.speciesName,
                                                        ) !=
                                                        null
                                                    ? SizedBox(
                                                      width: style.size,
                                                      height: style.size,
                                                      child: ColorFiltered(
                                                        colorFilter:
                                                            ColorFilter.mode(
                                                              style.color,
                                                              BlendMode.srcIn,
                                                            ),
                                                        child: Image.asset(
                                                          _getAnimalIconPath(
                                                            itx.speciesName,
                                                          )!,
                                                          width: style.size,
                                                          height: style.size,
                                                          fit: BoxFit.contain,
                                                          errorBuilder: (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Icon(
                                                              Icons.place,
                                                              size:
                                                                  style.size *
                                                                  0.9,
                                                              color:
                                                                  style.color,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    )
                                                    : Icon(
                                                      Icons.place,
                                                      size: style.size,
                                                      color: style.color,
                                                    );
                                              },
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                            ),
                      ],
                    ),

                    // ── Status chips ────────────────────────────────────────────────────────────
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Builder(
                        builder: (context) {
                          final mp = context.watch<MapProvider>();
                          final maxW = MediaQuery.of(context).size.width * 0.92;

                          Widget chip(
                            String label,
                            int count, {
                            bool loading = false,
                            bool error = false,
                            IconData? icon,
                          }) {
                            final text =
                                loading ? '$label: …' : '$label: $count';
                            return Chip(
                              avatar:
                                  icon != null ? Icon(icon, size: 16) : null,
                              label: Text(
                                text,
                                style: const TextStyle(fontSize: 13),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }

                          return Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxW),
                              child: Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      chip(
                                        'Animals',
                                        mp.animalPins
                                            .where((pin) => _within31Days(pin.seenAt))
                                            .where((pin) => _shouldShowPin(pin.seenAt, _showAnimals, _showAnimalsNew, _showAnimalsMedium, _showAnimalsOld))
                                            .length,
                                        loading: mp.animalPinsLoading,
                                        error: mp.animalPinsError != null,
                                        icon: Icons.pets,
                                      ),
                                      chip(
                                        'Detections',
                                        mp.detectionPins
                                            .where((pin) => _within31Days(pin.detectedAt))
                                            .where((pin) => _shouldShowPin(pin.detectedAt, _showDetections, _showDetectionsNew, _showDetectionsMedium, _showDetectionsOld))
                                            .length,
                                        loading: mp.detectionPinsLoading,
                                        error: mp.detectionPinsError != null,
                                        icon: Icons.sensors,
                                      ),
                                      chip(
                                        'Interacts',
                                        mp.interactions
                                            .where((itx) => _within31Days(itx.moment))
                                            .where((itx) => _shouldShowPin(itx.moment, _showInteractions, _showInteractionsNew, _showInteractionsMedium, _showInteractionsOld))
                                            .length,
                                        loading: mp.interactionsLoading,
                                        error: mp.interactionsError != null,
                                        icon: Icons.place,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Filter button ───────────────────────────────────────────────────────────
                    Positioned(
                      left: 16,
                      bottom: 80,
                      child: FloatingActionButton(
                        heroTag: 'filter_btn',
                        backgroundColor: AppColors.darkGreen,
                        child: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                        ),
                        onPressed: () => _showFilterDialog(context),
                      ),
                    ),
                  ],
                ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Center on me',
          backgroundColor: AppColors.darkGreen,
          child: const Icon(Icons.my_location, color: Colors.white),
          onPressed: () async {
            final mp = context.read<MapProvider>();
            debugPrint('[FAB] tapped');

            _followUser = true;

            // pick a quick target
            Position? target = mp.currentPosition ?? mp.selectedPosition;
            target ??= await Geolocator.getLastKnownPosition();

            if (target != null) {
              // Preserve current zoom level when centering
              final currentZoom = mp.mapController.camera.zoom;
              mp.mapController.move(
                LatLng(target.latitude, target.longitude),
                currentZoom,
              );
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Zoeken naar je locatie…'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
            }

            // resolve fresh GPS + address in background (don’t block the jump)
            Future(() async {
              Position? fresh;
              try {
                fresh = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                ).timeout(const Duration(seconds: 2));
              } catch (_) {}

              fresh ??= target;
              if (fresh == null || !mounted) return;

              String address = mp.currentAddress;
              try {
                final a = await _location.getAddressFromPosition(fresh);
                if (a.trim().isNotEmpty) address = a;
              } catch (e) {
                debugPrint('[FAB] Reverse geocoding failed: $e');
              }

              await mp.resetToCurrentLocation(fresh, address);
              await mp.sendTrackingPingFromPosition(fresh);

              if (_followUser) {
                mp.mapController.move(
                  LatLng(fresh.latitude, fresh.longitude),
                  _initialZoom,
                );
              }
              _queueFetch();
            });
          },
        ),
      ),
    );
  }

  /// Maps species names to their corresponding icon paths
  String? _getAnimalIconPath(String? speciesName) {
    if (speciesName == null) return null;

    final name = speciesName.toLowerCase();

    // Map species names to icon file names
    if (name.contains('wolf')) return 'assets/icons/animals/wolf.png';
    if (name.contains('vos') || name.contains('fox'))
      return 'assets/icons/animals/vos.png';
    if (name.contains('das') || name.contains('badger'))
      return 'assets/icons/animals/das.png';
    if (name.contains('ree') || name.contains('deer'))
      return 'assets/icons/animals/ree.png';
    if (name.contains('zwijn') || name.contains('boar'))
      return 'assets/icons/animals/wild_zwijn.png';
    if (name.contains('damhert')) return 'assets/icons/animals/damhert.png';
    if (name.contains('egel') || name.contains('hedgehog'))
      return 'assets/icons/animals/egel.png';
    if (name.contains('eekhoorn') || name.contains('squirrel'))
      return 'assets/icons/animals/eekhoorn.png';
    if (name.contains('bever') || name.contains('beaver'))
      return 'assets/icons/animals/beaver.png';
    if (name.contains('boommarten') || name.contains('marten'))
      return 'assets/icons/animals/boommarten.png';
    if (name.contains('hooglander') || name.contains('highlander'))
      return 'assets/icons/animals/hooglander.png';
    if (name.contains('wisent') || name.contains('bison'))
      return 'assets/icons/animals/winsent.png';

    return null; // Return null if no matching icon is found, will show default pets icon
  }

  // Simple struct for icon styling based on age (top-level _IconStyle is declared above)

  _IconStyle _iconStyleForTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final age = now.difference(timestamp);

    if (age.inMinutes < 60) {
      return const _IconStyle(Color(0xFF000000), 32.0);
    } else if (age.inHours < 24) {
      return const _IconStyle(Color(0xFF2F2E2E), 28.0);
    } else if (age.inDays < 7) {
      return const _IconStyle(Color(0xFF4D4D4D), 22.0);
    }
    return _IconStyle(Colors.grey.shade600, 20.0);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/constants/app_colors.dart';
//import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/screens/game/challenge_screen.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
//import 'package:wildgids/screens/shared/rapporteren.dart';
//import 'package:wildgids/screens/species/species_list_screen.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';
import 'package:wildgids/widgets/overlay/encounter_message_overlay.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildlifenl_map_logic_components/wildlifenl_map_logic_components.dart'
    show MapStateInterface;
import 'package:wildgids/screens/profile/profile_screen.dart';
import 'package:wildgids/widgets/map/animal_detail_card.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';
import 'package:wildgids/models/api_models/detection_pin.dart';
import 'package:wildgids/models/animal_waarneming_models/interaction_to_animal_pin.dart';
import 'package:wildgids/widgets/map/detection_detail_dialog.dart';
import 'package:wildgids/data_managers/tracking_api.dart';
import 'package:wildgids/interfaces/data_apis/tracking_api_interface.dart';
import 'package:wildgids/config/app_config.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';
import 'package:wildgids/constants/location_sharing_config.dart';
import 'dart:async';
import 'dart:convert';
import 'package:wildgids/utils/species_icon_utils.dart';
import 'dart:math' as math;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart'
    as cl;

class _IconStyle {
  final Color color;
  final double size;
  const _IconStyle(this.color, this.size);
}

class KaartOverviewScreen extends StatefulWidget {
  final bool showBottomNav;

  const KaartOverviewScreen({
    super.key,
    this.showBottomNav = true,
  });
  @override
  State<KaartOverviewScreen> createState() => _KaartOverviewScreenState();
}

class _KaartOverviewScreenState extends State<KaartOverviewScreen>
    with TickerProviderStateMixin {
  static const double _minMapZoom = 5.0;
  static const double _maxMapZoom = 17.5;
  fm.MapOptions? _mapOptions;
  final _location = LocationMapManager();

  bool _mapReady = false;
  LatLng? _pendingCenter;
  double? _pendingZoom;

  late MapProvider _mp;
  StreamSubscription<Position>? _posSub;
  VoidCallback? _mpListener;
  bool _listenerAttached = false;
  String? _lastNoticeKey;
  Timer? _pinsRefreshDebounce;
  LatLng? _lastPinsRefreshCenter;
  static const _pinsRefreshDebounceMs = 800;
  static const _pinsRefreshMinMoveMeters = 25.0;

  double? _lastZoom;

  bool _useClusters = true;
  static const double _clusterUntilZoom = 17.0;

  static const double _initialZoom = 15.0;
  bool _followUser = false;

  AnimalPin? _selectedAnimalDetail;
  String? _selectedAnimalIconPath;
  DetectionPin? _selectedDetectionDetail;

  bool _showTrackingHistory = false;
  bool _showLegend = false;
  List<TrackingReadingResponse> _trackingHistory = [];
  bool _loadingTrackingHistory = false;
  final int _trackingHistoryMinutes = 5;

  double _scaleBarWidth = 80;
  String _scaleBarLabel = '100 m';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mp = context.read<MapProvider>();

    if (!_mp.isInitialized) {
      _mp.initialize();
    }

    _mapOptions ??= fm.MapOptions(
        initialCenter: LatLng(
          _mp.currentPosition?.latitude ??
              MapStateInterface.defaultCenter.latitude,
          _mp.currentPosition?.longitude ??
              MapStateInterface.defaultCenter.longitude,
        ),
        initialZoom: _initialZoom,
        minZoom: _minMapZoom,
        maxZoom: _maxMapZoom,
        onMapReady: () {
          debugPrint('[Map] ready');
          _mapReady = true;
          _applyPendingCamera();
          _updateScaleBar();
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
          if (!_mapReady) return;
          final mp = context.read<MapProvider>();
          final currentZoom = mp.mapController.camera.zoom;
          final isProgrammatic = evt.source == fm.MapEventSource.mapController;

          if (!isProgrammatic &&
              (evt is fm.MapEventMoveStart || evt is fm.MapEventMove)) {
            if (_followUser) _followUser = false;
          }

          if (evt is fm.MapEventRotate && mounted) {
            setState(() {});
          }

          if (!isProgrammatic && _lastZoom != currentZoom) {
            _lastZoom = currentZoom;
            final next = currentZoom < _clusterUntilZoom;
            if (next != _useClusters && mounted) {
              setState(() => _useClusters = next);
            }
            _updateScaleBar();
            final p = mp.currentPosition ?? mp.selectedPosition;
            final appStateProvider = context.read<AppStateProvider>();
            if (_followUser &&
                appStateProvider.isLocationTrackingEnabled &&
                p != null) {
              mp.mapController.move(
                LatLng(p.latitude, p.longitude),
                currentZoom,
              );
            }
          }

          if (!isProgrammatic && evt is fm.MapEventMoveEnd) {
            _updateScaleBar();
          }
        },
      );

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

      debugPrint(
        '[Kaart] Received notice: "${n.text}" (severity: ${n.severity})',
      );

      final key = '${n.text}|${n.severity ?? ''}';
      if (_lastNoticeKey == key) {
        debugPrint('[Kaart] Duplicate notice, skipping');
        return;
      }
      _lastNoticeKey = key;

      if (!kIsWeb) {
        debugPrint('[Kaart] Skipping in-map overlay on mobile platforms');
        return;
      }

      debugPrint('[Kaart] Scheduling popup dialog to show');

      Future.microtask(() {
        if (!mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          try {
            debugPrint('[Kaart] 🎉 Showing message-style popup: "${n.text}" (web only)');
            showDialog(
              context: context,
              barrierDismissible: true,
              builder:
                  (_) => EncounterMessageOverlay(
                    message: n.text,
                    title:
                        n.severity == 1
                            ? 'Waarschuwing'
                            : (n.severity == 2 ? 'Melding' : 'Informatie'),
                    severity: n.severity,
                  ),
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
    _posSub?.cancel();
    _pinsRefreshDebounce?.cancel();
    if (_listenerAttached && _mpListener != null) {
      _mp.removeListener(_mpListener!);
    }
    _mp.stopTracking();
    super.dispose();
  }

  //bool get _devDebugToolsEnabled => dotenv.env['DEV_DEBUG_TOOLS'] == 'true' || dotenv.env['DEV_DEBUG_TOOLS'] == '1';


  

  void _schedulePinsRefresh({bool immediate = false}) {
    _pinsRefreshDebounce?.cancel();
    if (immediate) {
      unawaited(_refreshMapPins());
      return;
    }
    _pinsRefreshDebounce = Timer(
      const Duration(milliseconds: _pinsRefreshDebounceMs),
      () {
        if (mounted) unawaited(_refreshMapPins());
      },
    );
  }

  Future<void> _refreshMapPins() async {
    final map = context.read<MapProvider>();
    final pos = map.currentPosition ?? map.selectedPosition;
    if (pos != null && _lastPinsRefreshCenter != null) {
      final moved = Geolocator.distanceBetween(
        _lastPinsRefreshCenter!.latitude,
        _lastPinsRefreshCenter!.longitude,
        pos.latitude,
        pos.longitude,
      );
      if (moved < _pinsRefreshMinMoveMeters) {
        return;
      }
    }

    debugPrint('[Map] Refreshing pins via loadAllPinsFromVicinity()');
    try {
      await map.loadAllPinsFromVicinity();
      if (pos != null) {
        _lastPinsRefreshCenter = LatLng(pos.latitude, pos.longitude);
      }
      debugPrint(
        '[Map] Refreshed pins: animals=${map.animalPins.length} '
        'detections=${map.detectionPins.length} '
        'interactions=${map.interactions.length}',
      );
    } catch (e) {
      debugPrint('[Map] loadAllPinsFromVicinity failed: $e');
    }
  }

  void _startFollowingMe() {
    final mp = context.read<MapProvider>();
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    _posSub = Geolocator.getPositionStream(locationSettings: settings).listen((
      pos,
    ) async {
      if (!mounted) return;

      final double acc = pos.accuracy;
      final String accStr =
          (acc.isNaN || acc.isInfinite || acc <= 0)
              ? '?'
              : acc.toStringAsFixed(1);

      debugPrint(
        '[ME/live] ${pos.latitude.toStringAsFixed(6)}, '
        '${pos.longitude.toStringAsFixed(6)}  acc=$accStr m',
      );

      final appStateProvider = context.read<AppStateProvider>();
      await mp.updatePosition(pos, mp.currentAddress);

      if (appStateProvider.isLocationTrackingEnabled && !mp.isTracking) {
        mp.startTracking(interval: LocationSharingConfig.updateInterval);
      }

      if (appStateProvider.isLocationTrackingEnabled) {
        debugPrint('[ME/live] 📡 Sending tracking ping for position update');
        final notice = await _mp.sendTrackingPingFromPosition(pos);
        if (notice != null) {
          debugPrint(
            '[ME/live] 📔 Received notice from tracking ping: "${notice.text}"',
          );
        } else {
          debugPrint('[ME/live] No notice from position update');
        }
      } else {
        debugPrint(
          '[ME/live] ⚠️ Skipping tracking ping - tracking disabled by user',
        );
      }

      if (_followUser &&
          appStateProvider.isLocationTrackingEnabled &&
          mp.isInitialized) {
        final z = mp.mapController.camera.zoom;
        mp.mapController.move(LatLng(pos.latitude, pos.longitude), z);
      }

      _schedulePinsRefresh();
    });
  }

  // (dev helper removed)
  Future<void> _bootstrap() async {
    final map = context.read<MapProvider>();
    final app = context.read<AppStateProvider>();
    final mgr = _location;

    await map.initialize();

    Position? pos = app.isLocationCacheValid ? app.cachedPosition : null;
    pos ??= await mgr.determinePosition();

    debugPrint('[Loc] raw=${pos?.latitude},${pos?.longitude}');

    final hasGps = pos != null;
    if (hasGps) {
      var address = map.currentAddress;
      if (address.isEmpty) {
        address = await mgr.getAddressFromPosition(pos);
      }
      await map.resetToCurrentLocation(pos, address);
      _pendingCenter = LatLng(pos.latitude, pos.longitude);
      _pendingZoom = _initialZoom;
    } else {
      debugPrint(
        '[Loc] No GPS fix yet; map centered on NL overview (not device location)',
      );
      _pendingCenter = MapStateInterface.defaultCenter;
      _pendingZoom = 8.0;
    }
    _applyPendingCamera();

    debugPrint('[Kaart/Bootstrap] Loading map pins (POST+GET) before tracking ping');
    try {
      await map.loadAllPinsFromVicinity().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('[Kaart/Bootstrap] Vicinity load timeout after 15s');
        },
      );
      if (hasGps) {
        _lastPinsRefreshCenter = LatLng(pos.latitude, pos.longitude);
      }
      debugPrint(
        '[Kaart/Bootstrap] Pins loaded: '
        'animals=${map.animalPins.length} '
        'detections=${map.detectionPins.length} '
        'interactions=${map.interactions.length}',
      );
    } catch (e) {
      debugPrint('[Kaart/Bootstrap] Failed to load pins: $e');
    }

    if (hasGps && app.isLocationTrackingEnabled) {
      debugPrint('[Kaart/Bootstrap] 📡 Sending initial tracking ping');
      final initialNotice = await map.sendTrackingPingFromPosition(pos);
      if (initialNotice != null) {
        debugPrint(
          '[Kaart/Bootstrap] 📔 Initial ping returned notice: "${initialNotice.text}"',
        );
      } else {
        debugPrint('[Kaart/Bootstrap] Initial ping returned no notice');
      }

      debugPrint(
        '[Kaart/Bootstrap] Starting periodic tracking '
        '(every ${LocationSharingConfig.updateInterval.inMinutes} minutes)',
      );
      map.startTracking(interval: LocationSharingConfig.updateInterval);
    } else if (!hasGps) {
      debugPrint(
        '[Kaart/Bootstrap] Skipping tracking ping until GPS is available',
      );
    } else {
      debugPrint('[Kaart/Bootstrap] ⚠️ Location tracking is disabled by user');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final gps = pos;
        if (hasGps && gps != null) {
          _pendingCenter = LatLng(gps.latitude, gps.longitude);
          _pendingZoom = _initialZoom;
          _applyPendingCamera();
        }

        debugPrint('[Bootstrap] Loading map pins from tracking-reading API');
        try {
          await map.loadAllPinsFromVicinity().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('[Bootstrap] ⚠️ Vicinity API timeout after 15s');
              return;
            },
          );
        } catch (e) {
          debugPrint('[Bootstrap] ❌ Failed to load vicinity data: $e');
        }
        debugPrint(
          '[Map] initial totals  '
          'animals=${map.animalPins.length} '
          'detections=${map.detectionPins.length} '
          'interactions=${map.interactions.length} '
          'total=${map.totalPins}',
        );

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
      } catch (_) {}
    });

    if (hasGps) {
      try {
        final address = await mgr.getAddressFromPosition(pos);
        if (!mounted) return;
        map.setSelectedLocation(pos, address);
      } catch (e) {
        debugPrint('[Kaart] Reverse geocoding failed: $e');
      }
    }
  }

  Future<void> _loadTrackingHistory() async {
    if (_loadingTrackingHistory) return;

    setState(() {
      _loadingTrackingHistory = true;
    });

    try {
      final trackingApi = TrackingApi(AppConfig.shared.apiClient);

      final readings = await trackingApi.getMyTrackingReadings().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout after 10 seconds');
        },
      );

      if (!mounted) return;

      if (readings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geen tracking gegevens beschikbaar'),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _loadingTrackingHistory = false);
        return;
      }

      final sorted = List<TrackingReadingResponse>.from(readings);
      sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final oldest = sorted.first.timestamp;
      final newest = sorted.last.timestamp;
      final now = DateTime.now();

      debugPrint('[TRACKING] CRITICAL DATA:');
      debugPrint('[TRACKING] Now: ${now.toIso8601String()}');
      debugPrint(
        '[TRACKING] Newest in DB: ${newest.toIso8601String()} (${now.difference(newest).inSeconds}s ago)',
      );
      debugPrint(
        '[TRACKING] Oldest in DB: ${oldest.toIso8601String()} (${now.difference(oldest).inSeconds}s ago)',
      );
      debugPrint('[TRACKING] Total readings: ${readings.length}');

      final threshold = now.subtract(
        Duration(minutes: _trackingHistoryMinutes),
      );

      final filteredReadings =
          readings.where((r) => r.timestamp.isAfter(threshold)).toList();

      if (filteredReadings.isEmpty && readings.isNotEmpty) {
        final oneDayAgo = now.subtract(const Duration(days: 1));
        final recentOnlyReadings =
            readings.where((r) => r.timestamp.isAfter(oneDayAgo)).toList();

        if (recentOnlyReadings.isNotEmpty) {
          debugPrint(
            '[TRACKING] No data in 5min window, but found ${recentOnlyReadings.length} readings from last 24h',
          );
          setState(() {
            _trackingHistory = recentOnlyReadings;
            _showTrackingHistory = true;
            _loadingTrackingHistory = false;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${recentOnlyReadings.length} locaties van laatste 24 uur (geen recente in 5min)',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      setState(() {
        _trackingHistory = filteredReadings;
        _showTrackingHistory = true;
        _loadingTrackingHistory = false;
      });

      if (!mounted) return;

      String message;
      if (filteredReadings.isEmpty) {
        final oneDayAgo = now.subtract(const Duration(days: 1));
        final recentOnlyReadings =
            readings.where((r) => r.timestamp.isAfter(oneDayAgo)).toList();

      if (recentOnlyReadings.isNotEmpty) {
          message =
              '${recentOnlyReadings.length} locaties van vandaag (geen pingen in $_trackingHistoryMinutes min)';
        } else {
          message = 'Geen locaties in laatste $_trackingHistoryMinutes minuten';
        }
      } else {
        message =
            '${filteredReadings.length} locaties van laatste $_trackingHistoryMinutes minuten';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loadingTrackingHistory = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verzoek timeout - probeer opnieuw'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTrackingHistory = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _clusterBadge({
    required IconData icon,
    required int count,
    required Color color,
    required double mapRotation,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    double size;
    double iconSize;
    double badgeFontSize;
    double badgePadH;
    double badgePadV;
    double badgeOffset;
    if (screenWidth < 400) {
      size = 30;
      iconSize = 16;
      badgeFontSize = 9;
      badgePadH = 4;
      badgePadV = 1.5;
      badgeOffset = -4;
    } else if (screenWidth < 700) {
      size = 36;
      iconSize = 19;
      badgeFontSize = 11;
      badgePadH = 5;
      badgePadV = 2;
      badgeOffset = -5;
    } else {
      size = 42;
      iconSize = 22;
      badgeFontSize = 12;
      badgePadH = 6;
      badgePadV = 2;
      badgeOffset = -6;
    }
    return Transform.rotate(
      angle: -mapRotation * math.pi / 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.95),
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
            child: Icon(icon, size: iconSize, color: Colors.white),
          ),
          Positioned(
            right: badgeOffset,
            top: badgeOffset,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: badgePadH,
                vertical: badgePadV,
              ),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: badgeFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateScaleBar() {
    if (!_mp.isInitialized) return;

    final center = _mp.mapController.camera.center;
    final zoom = _mp.mapController.camera.zoom;

    const earthCircumference = 40075016.686;
    final metersPerPixel =
        math.cos(center.latitude * math.pi / 180) *
        earthCircumference /
        (256 * math.pow(2, zoom));

    const candidates = [
      5,
      10,
      20,
      50,
      100,
      200,
      300,
      500,
      750,
      1000,
      1500,
      2000,
      5000,
      10000,
      20000,
      50000,
      100000,
      200000,
      500000,
    ];

    // Keep the visual scale bar more compact in pixels.
    const targetWidthPx = 115.0;
    double chosenMeters = candidates.first.toDouble();
    double chosenWidth = chosenMeters / metersPerPixel;
    double bestDistance = (chosenWidth - targetWidthPx).abs();

    for (final m in candidates) {
      final widthPx = m / metersPerPixel;
      final distance = (widthPx - targetWidthPx).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        chosenMeters = m.toDouble();
        chosenWidth = widthPx;
      }
    }

    final label =
        chosenMeters >= 1000
            ? '${(chosenMeters / 1000).toStringAsFixed(chosenMeters % 1000 == 0 ? 0 : 1)} km'
            : '${chosenMeters.toInt()} m';

    if ((chosenWidth - _scaleBarWidth).abs() > 0.5 || _scaleBarLabel != label) {
      setState(() {
        _scaleBarWidth = chosenWidth.clamp(32, 150);
        _scaleBarLabel = label;
      });
    }
  }

  void _applyPendingCamera() {
    if (!_mapReady || _pendingCenter == null || _pendingZoom == null) return;
    try {
      final mp = context.read<MapProvider>();
      mp.mapController.move(_pendingCenter!, _pendingZoom!);
      _nudgeMapToTriggerTiles();
    } catch (e) {
      debugPrint('[Map] Failed to apply pending camera: $e');
    }
  }

  void _nudgeMapToTriggerTiles() {
    final mp = context.read<MapProvider>();
    if (!mp.isInitialized) return;
    final cam = mp.mapController.camera;
    final LatLng c = cam.center;
    const double delta = 0.000001;
    try {
      mp.mapController.move(
        LatLng(c.latitude + delta, c.longitude + delta),
        cam.zoom,
      );
      mp.mapController.move(c, cam.zoom);
    } catch (e) {
      debugPrint('[Map] Nudge failed: $e');
    }
  }

  void _showAnimalDetailCard(AnimalPin pin, String? iconPath) {
    setState(() {
      _selectedAnimalDetail = pin;
      _selectedAnimalIconPath = iconPath;
    });
  }

  void _closeAnimalDetailCard() {
    setState(() {
      _selectedAnimalDetail = null;
      _selectedAnimalIconPath = null;
      _selectedDetectionDetail = null;
    });
  }

  void _onTabSelected(NavTab tab) {
    if (tab == NavTab.kaart) return;

    Widget page;

    switch (tab) {
      case NavTab.ontdekken:
      case NavTab.zones:
        page = const ChallengeScreen();
        break;

      case NavTab.waarneming:
        page = const WaarnemmingStartScreen();
        break;

      case NavTab.logboek:
        page = const LogbookScreen();
        break;

      case NavTab.instellingen:
      case NavTab.profile:
        page = const ProfileScreen();
        break;

      case NavTab.kaart:
        return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 230),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, __) => page,
        transitionsBuilder: (_, animation, __, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Get border color based on detection type
  Color _getBorderColorForDetectionType(String? detectionType) {
    
    if (detectionType == null) return Colors.white;
    
    final type = detectionType.toLowerCase();
    
    if (type.contains('visual') ||type.contains('camera') ||type.contains('foto') ||type.contains('image')) {
  return const Color(0xFF00BFD8); // Aqua
} else if (type.contains('acoustic') || type.contains('geluid')) {
      return const Color(0xFFFF9100); // Orange
    } else if (type.contains('waarneming') || type.contains('sighting')) {
      return const Color(0xFF8613A8); // Purple
    } else if (type.contains('collision') || type.contains('botsing')) {
      return const Color(0xFF0078DA); // Blue
    } else if (type.contains('schadamelding') || type.contains('damage')) {
      return const Color(0xFF008C7B); // teal
    } else if (type.contains('collar')) {
      return const Color(0xFFFE008E); // pink
    }
    
    return Colors.white;
  }

  int? _eventCountForPin(AnimalPin pin) {
    final type = pin.reportType?.toLowerCase();
    final isFixedPin =
        type?.contains('camera') == true ||
        type?.contains('foto') == true ||
        type?.contains('acoustic') == true ||
        type?.contains('geluid') == true;

    return isFixedPin ? 3 : null;
  }
  /// Build styled animal pin with white circle and colored border
  Widget _buildStyledAnimalPin(
    String? speciesName,
    String? detectionType,
    _IconStyle style,
    {int? eventCount}
  ) {
    final borderColor = _getBorderColorForDetectionType(detectionType);
    final type = detectionType?.toLowerCase();

final bool isCamera =
    type?.contains('camera') == true ||
    type?.contains('foto') == true;
    

final bool isAcoustic =
    type?.contains('acoustic') == true ||
    type?.contains('geluid') == true;
    final iconPath = getSpeciesIconPath(speciesName);

final bool isCollar =
    type?.contains('collar') == true;
    
    return SizedBox(
    width: style.size + 28,
    height: style.size + 28,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
      Container(
        width: style.size + 16,
        height: style.size + 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center icon
          if (isCamera)
  Icon(
    Icons.camera_alt,
    size: style.size * 0.9,
    color: style.color,
  )
else if (isAcoustic)
  Icon(
    Icons.graphic_eq,
    size: style.size * 0.9,
    color: style.color,
  )
else if (iconPath != null)
  SizedBox(
    width: style.size,
    height: style.size,
    child: ColorFiltered(
      colorFilter: ColorFilter.mode(
        style.color,
        BlendMode.srcIn,
      ),
      child: Image.asset(
        iconPath,
        width: style.size,
        height: style.size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.pets,
            size: style.size * 0.9,
            color: style.color,
          );
        },
      ),
    ),
  )
else
  Icon(
    Icons.pets,
    size: style.size,
    color: style.color,
  ),
          
          // Event count badge (top-right)
if (eventCount != null && eventCount > 0)
  Positioned(
    top: -2,
    right: -2,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: borderColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
          ),
        ],
      ),
      child: Text(
        '$eventCount',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),

// Collar badge
if (isCollar)
  Positioned(
    top: -2,
    right: -2,
    child: Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: borderColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.settings_remote,
        size: 11,
        color: Colors.white,
      ),
    ),
  )
            
              ],
      ),
    ), // closes Container
  ],
),
);

  }
bool _isVisualDetection(String? value) {
  final lower = value?.toLowerCase() ?? '';
  return lower.contains('visual') ||
      lower.contains('camera') ||
      lower.contains('foto') ||
      lower.contains('image');
}

Widget _buildStyledDetectionPin(
  DetectionPin pin,
  _IconStyle style,
) {
  final borderColor = _getBorderColorForDetectionType(pin.deviceType);

  return SizedBox(
    width: style.size + 28,
    height: style.size + 28,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: style.size + 16,
          height: style.size + 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: borderColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
  _isVisualDetection(pin.deviceType)
      ? Icons.camera_alt
      : Icons.sensors,
  size: style.size * 0.8,
  color: style.color,
),
        ),
      ],
    ),
  );
}

Widget _legendRow(
  Color color,
  String label, {
  IconData? icon,
  IconData? badgeIcon,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: color,
                  width: 3,
                ),
              ),
              child: icon != null
                  ? Icon(
                      icon,
                      size: 16,
                      color: Colors.black,
                    )
                  : null,
            ),

            if (badgeIcon != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    badgeIcon,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: 12),

        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapProvider>();
    final pos = map.selectedPosition ?? map.currentPosition;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: false,
        body:
            pos == null
                ? const Center(child: CircularProgressIndicator())
                : _mapOptions == null
                ? const Center(child: CircularProgressIndicator())
                : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Stack(
                      children: [
                        fm.FlutterMap(
                          mapController: map.mapController,
                          options: _mapOptions!,
                          children: [
                            fm.TileLayer(
                              urlTemplate: LocationMapManager.standardTileUrl,
                              subdomains: LocationMapManager.standardTileSubdomains,
                              userAgentPackageName: 'com.wildgids.app',
                              retinaMode: LocationMapManager.tileRetinaMode(context),
                              keepBuffer: 1,
                            ),

                            _useClusters
                                ? cl.MarkerClusterLayerWidget(
                                  options: cl.MarkerClusterLayerOptions(
                                    markers: map.animalPins.map((pin) {
                                              final style =
                                                  _iconStyleForTimestamp(
                                                    pin.seenAt,
                                                  );
                                              final mapRotation =
                                                  map
                                                      .mapController
                                                      .camera
                                                      .rotation;
                                              return fm.Marker(
                                                point: LatLng(pin.lat, pin.lon),
                                                width: (style.size + 24).clamp(
                                                  30.0,
                                                  56.0,
                                                ),
                                                height: (style.size + 24).clamp(
                                                  30.0,
                                                  56.0,
                                                ),
                                                rotate: false,
                                                child: Transform.rotate(
                                                  angle:
                                                      -mapRotation *
                                                      math.pi /
                                                      180,
                                                  child: _buildStyledAnimalPin(
                                                    pin.speciesName,
                                                    pin.reportType,
                                                    eventCount: _eventCountForPin(pin),
                                                    style,
                                                  ),
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
                                          mapRotation:
                                              map.mapController.camera.rotation,
                                        ),
                                  ),
                                )
                                
                                : fm.MarkerLayer(
                                  markers: map.animalPins.map((pin) {
                                            final mapRotation =
                                                map
                                                    .mapController
                                                    .camera
                                                    .rotation;
                                            return fm.Marker(
                                              point: LatLng(pin.lat, pin.lon),
                                              width: 56,
                                              height: 56,
                                              rotate: false,
                                              child: Transform.rotate(
                                                angle:
                                                    -mapRotation *
                                                    math.pi /
                                                    180,
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () {
                                                    _showAnimalDetailCard(pin, getSpeciesCardImagePath(pin.speciesName));
                                                    _selectedDetectionDetail = null;
                                                  },
                                                  child: Builder(
                                                    builder: (ctx) {
                                                      final style =
                                                          _iconStyleForTimestamp(
                                                            pin.seenAt,
                                                          );
                                                      return _buildStyledAnimalPin(
                                                        pin.speciesName,
                                                        pin.reportType,
                                                        eventCount: _eventCountForPin(pin),
                                                        style,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                ),

                            _useClusters
                                ? cl.MarkerClusterLayerWidget(
                                  options: cl.MarkerClusterLayerOptions(
                                    markers: map.detectionPins.map((pin) {
                                              final style =
                                                  _iconStyleForTimestamp(
                                                    pin.detectedAt,
                                                  );
                                              final mapRotation =
                                                  map
                                                      .mapController
                                                      .camera
                                                      .rotation;

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
                                                rotate: false,
                                                child: Transform.rotate(
                                                  angle:
                                                      -mapRotation *
                                                      math.pi /
                                                      180,
                                                  child: GestureDetector(
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedAnimalDetail = null;
                                                        _selectedAnimalIconPath = null;
                                                        _selectedDetectionDetail = pin;
                                                      });
                                                    },
                                                    child: _buildStyledDetectionPin(
                                                      pin,
                                                      style,
                                                    ),
                                                    
                                                  ),
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
                                          mapRotation:
                                              map.mapController.camera.rotation,
                                        ),
                                  ),
                                )
                                : fm.MarkerLayer(
                                  markers: map.detectionPins.map((pin) {
                                            final style =
                                                _iconStyleForTimestamp(
                                                  pin.detectedAt,
                                                );
                                            final mapRotation =
                                                map
                                                    .mapController
                                                    .camera
                                                    .rotation;

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
                                              rotate: false,
                                              child: Transform.rotate(
                                                angle:
                                                    -mapRotation *
                                                    math.pi /
                                                    180,
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedAnimalDetail = null;
                                                      _selectedAnimalIconPath = null;
                                                      _selectedDetectionDetail = pin;
                                                    });
                                                  },
                                                  child: _buildStyledDetectionPin(
                                                    pin,
                                                    style,
                                                  ),
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                ),

                            if (context
                                .watch<AppStateProvider>()
                                .isLocationTrackingEnabled)
                              Builder(
                                builder: (context) {
                                  final mapRotation =
                                      map.mapController.camera.rotation;
                                  return fm.MarkerLayer(
                                    markers: [
                                      fm.Marker(
                                        point: LatLng(
                                          pos.latitude,
                                          pos.longitude,
                                        ),
                                        width: 40,
                                        height: 40,
                                        rotate: false,
                                        child: Transform.rotate(
                                          angle: -mapRotation * math.pi / 180,
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withValues(alpha: 0.25),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                Container(
                                                  width: 14,
                                                  height: 14,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                            if (_showTrackingHistory &&
                                _trackingHistory.isNotEmpty)
                              fm.PolylineLayer(
                                polylines: [
                                  fm.Polyline(
                                    points:
                                        _trackingHistory
                                            .map(
                                              (r) => LatLng(
                                                r.latitude,
                                                r.longitude,
                                              ),
                                            )
                                            .toList(),
                                    color: Colors.blue.withValues(alpha: 0.6),
                                    strokeWidth: 2.0,
                                  ),
                                ],
                              ),

                            if (_showTrackingHistory &&
                                _trackingHistory.isNotEmpty)
                              fm.CircleLayer(
                                circles:
                                    _trackingHistory.map((reading) {
                                      return fm.CircleMarker(
                                        point: LatLng(
                                          reading.latitude,
                                          reading.longitude,
                                        ),
                                        radius: 4,
                                        color: Colors.blue.withValues(alpha: 0.8),
                                        borderColor: Colors.white,
                                        borderStrokeWidth: 1,
                                        useRadiusInMeter: false,
                                      );
                                    }).toList(),
                              ),

                            _useClusters
                                ? cl.MarkerClusterLayerWidget(
                                  options: cl.MarkerClusterLayerOptions(
                                    markers: map.interactions.map((itx) {
                                              final mapRotation =
                                                  map
                                                      .mapController
                                                      .camera
                                                      .rotation;
                                              return fm.Marker(
                                                point: LatLng(itx.lat, itx.lon),
                                                width: 56,
                                                height: 56,
                                                rotate: false,
                                                child: Transform.rotate(
                                                  angle:
                                                      -mapRotation *
                                                      math.pi /
                                                      180,
                                                  child: GestureDetector(
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    onTap: () {
                                                      _showAnimalDetailCard(
                                                        itx.toAnimalPin(),
                                                        getSpeciesCardImagePath(itx.speciesName),
                                                      );
                                                      _selectedDetectionDetail = null;
                                                    },
                                                    child: Builder(
                                                      builder: (ctx) {
                                                        final style =
                                                            _iconStyleForTimestamp(
                                                              itx.moment,
                                                            );
                                                        return _buildStyledAnimalPin(
                                                          itx.speciesName,
                                                          itx.typeName,
                                                          style,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              );
                                            })
                                            .toList(),
                                    builder:
                                        (context, markers) => _clusterBadge(
                                          icon: Icons.place,
                                          count: markers.length,
                                          color: AppColors.darkGreen,
                                          mapRotation:
                                              map.mapController.camera.rotation,
                                        ),
                                  ),
                                )
                                : fm.MarkerLayer(
                                  markers: map.interactions.map((itx) {
                                        final mapRotation =
                                            map.mapController.camera.rotation;
                                        return fm.Marker(
                                          point: LatLng(itx.lat, itx.lon),
                                          width: 56,
                                          height: 56,
                                          rotate: false,
                                          child: Transform.rotate(
                                            angle: -mapRotation * math.pi / 180,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                _showAnimalDetailCard(
                                                  itx.toAnimalPin(),
                                                  getSpeciesCardImagePath(itx.speciesName),
                                                );
                                                _selectedDetectionDetail = null;
                                              },
                                              child: Builder(
                                                builder: (ctx) {
                                                  final style =
                                                      _iconStyleForTimestamp(itx.moment);
                                                  return _buildStyledAnimalPin(
                                                    itx.speciesName,
                                                    itx.typeName,
                                                    style,
                                                    eventCount: null,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                          ],
                        ),

                        Positioned(
                          left: 12,
                          bottom: 44,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _scaleBarLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: _scaleBarWidth,
                                  height: 3,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
  right: 14,
bottom: 45,
  child: GestureDetector(
    onTap: () {
      setState(() {
        _showLegend = !_showLegend;
      });
    },
   child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: const Color(0xFF222222),
    borderRadius: BorderRadius.circular(26),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.22),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        _showLegend ? Icons.close : Icons.help_outline,
        size: 19,
        color: Colors.white,
      ),
      const SizedBox(width: 8),
      const Text(
        'Legenda',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ],
  ),
),
  ),
                        ),
                        Positioned(
                          top: 90,
                          right: 14,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: 56,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: _followUser
                                        ? 'Kaart volgt je locatie (uit)'
                                        : 'Kaart volgt je locatie (aan)',
                                    onLongPress: _loadTrackingHistory,
                                    onPressed: () {
                                      setState(() {
                                        if (_showTrackingHistory) {
                                          _showTrackingHistory = false;
                                        }
                                        _followUser = !_followUser;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.directions_walk,
                                      color:
                                          _followUser
                                              ? const Color(0xFF37A904)
                                              : Colors.white,
                                    ),
                                  ),
                                  Container(
                                    width: 30,
                                    height: 1,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  IconButton(
                                      tooltip: 'Mijn locatie',
                                      onPressed: () async {
                                        final mp = context.read<MapProvider>();
                                        final target =
                                            mp.currentPosition ?? mp.selectedPosition;
                                        if (target == null || !mp.isInitialized) return;
                                        mp.mapController.move(
                                          LatLng(target.latitude, target.longitude),
                                          mp.mapController.camera.zoom,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.my_location,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: IgnorePointer(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '© OpenTopoMap',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black.withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '© OpenStreetMap contributors',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showLegend)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                setState(() => _showLegend = false);
                              },
                              child: const SizedBox.expand(),
                            ),
                          ),
                        if (_showLegend)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _legendRow(
                        const Color(0xFF8613A8),
                        'Waarneming',
                      ),
                      _legendRow(
                        const Color(0xFF00BFD8),
                        'Cameraval',
                        icon: Icons.camera_alt,
                      ),
                      _legendRow(
                        const Color(0xFFFF9100),
                        'Akoestische sensor',
                        icon: Icons.graphic_eq,
                      ),
                      _legendRow(
                        const Color(0xFFFE008E),
                        'Diergedragen sensor',
                        badgeIcon: Icons.settings_remote,
                      ),
                      _legendRow(
                        const Color(0xFF0078DA),
                        'Dieraanrijding',
                      ),
                      _legendRow(
                        const Color(0xFF008C7B),
                        'Schademelding',
                      ),
                    ],
                  ),
                ),
              ),
            ),
                                  if (_selectedAnimalDetail != null)
                                    Positioned(
                                      bottom: 105,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: SizedBox(
                                          width: math.min(
                                            460,
                                            MediaQuery.of(context).size.width - 12,
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: GestureDetector(
                                            behavior: HitTestBehavior.translucent,
                                            onTap: () {
                                              if (_showLegend) {
                                                setState(() => _showLegend = false);
                                              }
                                            },
                                            child: Stack(
                                              children: [
                                                AnimalDetailCard(
                                                  animal: _selectedAnimalDetail,
                                                  iconPath: _selectedAnimalIconPath,
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.close, color: Colors.grey),
                                                    splashRadius: 20,
                                                    onPressed: _closeAnimalDetailCard,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            )
                                          ),
                                        ),
                                      ),
                                    ),
                        

                                  if (_selectedDetectionDetail != null)
                                    Positioned(
                                      bottom: 105,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: SizedBox(
                                          width: math.min(
                                            460,
                                            MediaQuery.of(context).size.width - 12,
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: Stack(
                                              children: [
                                                DetectionDetailDialog(
                                                  detection: _selectedDetectionDetail!,
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.close, color: Colors.grey),
                                                    splashRadius: 20,
                                                    onPressed: () {
                                                      setState(() {
                                                        _selectedDetectionDetail = null;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                      ],
                    ),
                  ),
                ),
        floatingActionButton: null,
        bottomNavigationBar:
            widget.showBottomNav
                ? SafeArea(
                  top: false,
                  child: CustomNavBar(
                    currentTab: NavTab.kaart,
                    onTabSelected: _onTabSelected,
                  ),
                )
                : null,
      ),
    );
  }

  
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
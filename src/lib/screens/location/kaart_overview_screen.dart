import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/screens/shared/rapporteren.dart';
import 'package:wildgids/screens/species/species_list_screen.dart';
import 'package:wildgids/widgets/overlay/encounter_message_overlay.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/screens/profile/profile_screen.dart';
import 'package:wildgids/widgets/map/interaction_detail_dialog.dart';
import 'package:wildgids/widgets/map/animal_detail_dialog.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';
import 'package:wildgids/models/animal_waarneming_models/interaction_to_animal_pin.dart';
import 'package:wildgids/widgets/map/detection_detail_dialog.dart';
import 'package:wildgids/data_managers/tracking_api.dart';
import 'package:wildgids/interfaces/data_apis/tracking_api_interface.dart';
import 'package:wildgids/config/app_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';
import 'package:wildgids/constants/mock_location.dart';
import 'package:wildgids/constants/location_sharing_config.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart'
    as cl;

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
  Timer? _debounce;
  String? _lastNoticeKey;

  double? _lastZoom;
  static const _debounceMs = 450;

  bool _useClusters = true;
  static const double _clusterUntilZoom = 17.0;

  static const double _initialZoom = 15.0;
  bool _followUser = true;

  bool _showAnimals = true;
  bool _showDetections = true;
  bool _showInteractions = true;
  bool _showAnimalsNew = true;
  bool _showAnimalsMedium = false;
  bool _showAnimalsOld = false;
  bool _showDetectionsNew = true;
  bool _showDetectionsMedium = false;
  bool _showDetectionsOld = false;
  bool _showInteractionsNew = true;
  bool _showInteractionsMedium = false;
  bool _showInteractionsOld = false;

  bool _showTrackingHistory = false;
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
              LocationMapManager.denBoschCenter.latitude,
          _mp.currentPosition?.longitude ??
              LocationMapManager.denBoschCenter.longitude,
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
            _queueFetch();
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
            _queueFetch();
            _updateScaleBar();
          }
        },
      );

    _mpListener ??= () {
      debugPrint('[Kaart] ðŸ“¨ Listener triggered');
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
            debugPrint('[Kaart] ðŸŽ‰ Showing message-style popup: "${n.text}" (web only)');
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
            debugPrint('[Kaart] âŒ Failed to show tracking notice: $e');
          }
        });
      });
    };

    if (!_listenerAttached) {
      debugPrint('[Kaart] ðŸ”— Attaching listener to MapProvider');
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
    _posSub?.cancel();
    if (_listenerAttached && _mpListener != null) {
      _mp.removeListener(_mpListener!);
    }
    _mp.stopTracking();
    super.dispose();
  }

  bool get _devDebugToolsEnabled => dotenv.env['DEV_DEBUG_TOOLS'] == 'true' || dotenv.env['DEV_DEBUG_TOOLS'] == '1';

  void _injectMockPins() {
    final map = context.read<MapProvider>();
    final center = map.isInitialized
        ? map.mapController.camera.center
        : LatLng(
            LocationMapManager.denBoschCenter.latitude,
            LocationMapManager.denBoschCenter.longitude,
          );

    final now = DateTime.now().toUtc();
    final species = [
      'Vos',
      'Wolf',
      'Das',
      'Ree',
      'Wild zwijn',
      'Damhert',
      'Egel',
      'Eekhoorn',
    ];

    final dx = [0.0000, 0.0012, -0.0012, 0.0018, -0.0018, 0.0009, -0.0009, 0.0015];
    final dy = [0.0000, 0.0010, -0.0010, -0.0016, 0.0016, -0.0008, 0.0008, 0.0013];

    final animals = <AnimalPin>[];
    for (int i = 0; i < species.length; i++) {
      final ts = i < 3
          ? now.subtract(Duration(minutes: (i + 1) * 10))
          : (i < 6
              ? now.subtract(Duration(hours: (i - 2) * 6))
              : now.subtract(Duration(days: 8 + i)));

      animals.add(
        AnimalPin(
          id: 'mock-${i + 1}',
          lat: center.latitude + (dy[i % dy.length]),
          lon: center.longitude + (dx[i % dx.length]),
          seenAt: ts,
          speciesName: species[i],
        ),
      );
    }

    map.setMockVicinity(animals: animals);

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Mock dieren geplaatst rond de kaart'),
            duration: Duration(seconds: 2),
          ),
        );
      setState(() {});
    }
  }

  void _emitDevTrackingNotice() {
    final map = context.read<MapProvider>();
    map.emitMockTrackingNotice('Dier in de buurt (testmelding)', severity: 2);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Testmelding verstuurd (notificatie)'),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  void _queueFetch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (mounted) _fetchAllForView();
    });
  }

  void _startFollowingMe() {
    final mp = context.read<MapProvider>();
    if (MockLocation.enabled) {
      final pos = MockLocation.position();
      mp.updatePosition(pos, mp.currentAddress);
      if (_mapReady && mp.isInitialized) {
        final z = mp.mapController.camera.zoom;
        mp.mapController.move(LatLng(pos.latitude, pos.longitude), z);
      } else {
        _pendingCenter = LatLng(pos.latitude, pos.longitude);
        _pendingZoom = _initialZoom;
      }
      return;
    }
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

      if (appStateProvider.isLocationTrackingEnabled) {
        debugPrint('[ME/live] ðŸ“¡ Sending tracking ping for position update');
        final notice = await _mp.sendTrackingPingFromPosition(pos);
        if (notice != null) {
          debugPrint(
            '[ME/live] ðŸ”” Received notice from tracking ping: "${notice.text}"',
          );
        } else {
          debugPrint('[ME/live] No notice from position update');
        }
      } else {
        debugPrint(
          '[ME/live] âš ï¸ Skipping tracking ping - tracking disabled by user',
        );
      }

      if (_followUser &&
          appStateProvider.isLocationTrackingEnabled &&
          mp.isInitialized) {
        final z = mp.mapController.camera.zoom;
        mp.mapController.move(LatLng(pos.latitude, pos.longitude), z);
      }
    });
  }

  Future<void> _fetchAllForView() async {
    final map = context.read<MapProvider>();

    debugPrint('[Map] Fetching data from vicinity endpoint');

    await map.loadAllPinsFromVicinity();

    debugPrint(
      '[Map] vicinity totals  animals=${map.animalPins.length} '
      'detections=${map.detectionPins.length} interactions=${map.interactions.length} '
      'total=${map.totalPins}',
    );

    debugPrint(
      'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•',
    );
    debugPrint('[ANIMALS] Total count: ${map.animalPins.length}');
    debugPrint(
      'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•',
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
        debugPrint('[ANIMAL $i] JSON: $jsonOutput');
      } catch (e) {
        debugPrint('[ANIMAL $i] Error serializing: $e');
        debugPrint(
          '[ANIMAL $i] Raw: id=${animal.id}, species=${animal.speciesName}, lat=${animal.lat}, lon=${animal.lon}, seenAt=${animal.seenAt}',
        );
      }
    }
    debugPrint(
      'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•',
    );
  }

  Future<void> _bootstrap() async {
    final map = context.read<MapProvider>();
    final app = context.read<AppStateProvider>();
    final mgr = _location;

    await map.initialize();

    Position? pos = app.isLocationCacheValid ? app.cachedPosition : null;
    pos ??= await mgr.determinePosition();

    debugPrint('[Loc] raw=${pos?.latitude},${pos?.longitude}');

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

    await map.resetToCurrentLocation(pos, 'Locatie gevonden');

    _pendingCenter = LatLng(pos.latitude, pos.longitude);
    _pendingZoom = _initialZoom;
    _applyPendingCamera();

    if (app.isLocationTrackingEnabled) {
      debugPrint('[Kaart/Bootstrap] ðŸ“¡ Sending initial tracking ping');
      final initialNotice = await map.sendTrackingPingFromPosition(pos);
      if (initialNotice != null) {
        debugPrint(
          '[Kaart/Bootstrap] ðŸ”” Initial ping returned notice: "${initialNotice.text}"',
        );
      } else {
        debugPrint('[Kaart/Bootstrap] Initial ping returned no notice');
      }

      debugPrint(
        '[Kaart/Bootstrap] Starting periodic tracking '
        '(every ${LocationSharingConfig.updateInterval.inMinutes} minutes)',
      );
      map.startTracking(interval: LocationSharingConfig.updateInterval);
    } else {
      debugPrint('[Kaart/Bootstrap] âš ï¸ Location tracking is disabled by user');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        _pendingCenter = LatLng(pos!.latitude, pos.longitude);
        _pendingZoom = _initialZoom;
        _applyPendingCamera();

        debugPrint('[Bootstrap] Loading data from vicinity endpoint');
        try {
          await map.loadAllPinsFromVicinity().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('[Bootstrap] âš ï¸ Vicinity API timeout after 15s');
              return;
            },
          );
        } catch (e) {
          debugPrint('[Bootstrap] âŒ Failed to load vicinity data: $e');
        }

        debugPrint(
          '[Map] initial totals  '
          'animals=${map.animalPins.length} '
          'detections=${map.detectionPins.length} '
          'interactions=${map.interactions.length} '
          'total=${map.totalPins}',
        );

        debugPrint(
          'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•',
        );
        debugPrint('[BOOTSTRAP ANIMALS] Total count: ${map.animalPins.length}');
        debugPrint(
          'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•',
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
          'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•',
        );

        _queueFetch();
      } catch (_) {}
    });

    try {
      final address = await mgr.getAddressFromPosition(pos);
      if (!mounted) return;
      map.setSelectedLocation(pos, address);
    } catch (e) {
      debugPrint('[Kaart] Reverse geocoding failed: $e');
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

      debugPrint('[TRACKING] ðŸ”´ CRITICAL DATA:');
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

  bool _within31Days(DateTime timestamp) {
    return DateTime.now().difference(timestamp) < const Duration(days: 31);
  }

  bool _shouldShowPin(
    DateTime timestamp,
    bool showType,
    bool showNew,
    bool showMedium,
    bool showOld,
  ) {
    if (!showType) {
      debugPrint('[Filter] Type hidden: showType=$showType');
      return false;
    }

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
      500,
      1000,
      2000,
      5000,
      10000,
      20000,
      50000,
      100000,
      200000,
      500000,
    ];

    const targetWidthPx = 150.0;
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
        _scaleBarWidth = chosenWidth.clamp(40, 200);
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
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth =
                                      MediaQuery.of(context).size.width;
                                  double fontSize = 20;
                                  double iconSize = 24;
                                  if (screenWidth < 350) {
                                    fontSize = 16;
                                    iconSize = 18;
                                  } else if (screenWidth < 420) {
                                    fontSize = 14;
                                    iconSize = 14;
                                  }
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Kaartpictogrammen filteren',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: iconSize,
                                        ),
                                        tooltip: 'Toepassen',
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.pets,
                                        size: 20,
                                        color: AppColors.darkGreen,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Dieren',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildFilterCheckbox(
                                  'Nieuw (< 24 uur)',
                                  _showAnimalsNew,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showAnimalsNew = v ?? true,
                                    ),
                                  ),
                                  Icons.fiber_new,
                                ),
                                _buildFilterCheckbox(
                                  'Recent (24u - 1 week)',
                                  _showAnimalsMedium,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showAnimalsMedium = v ?? true,
                                    ),
                                  ),
                                  Icons.access_time,
                                ),
                                _buildFilterCheckbox(
                                  'Oud (> 1 week)',
                                  _showAnimalsOld,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showAnimalsOld = v ?? true,
                                    ),
                                  ),
                                  Icons.history,
                                ),

                                const SizedBox(height: 16),

                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.sensors,
                                        size: 20,
                                        color: AppColors.darkGreen,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Detecties',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildFilterCheckbox(
                                  'Nieuw (< 24 uur)',
                                  _showDetectionsNew,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showDetectionsNew = v ?? true,
                                    ),
                                  ),
                                  Icons.fiber_new,
                                ),
                                _buildFilterCheckbox(
                                  'Recent (24u - 1 week)',
                                  _showDetectionsMedium,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showDetectionsMedium = v ?? true,
                                    ),
                                  ),
                                  Icons.access_time,
                                ),
                                _buildFilterCheckbox(
                                  'Oud (> 1 week)',
                                  _showDetectionsOld,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showDetectionsOld = v ?? true,
                                    ),
                                  ),
                                  Icons.history,
                                ),

                                const SizedBox(height: 16),

                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.place,
                                        size: 20,
                                        color: AppColors.darkGreen,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Interacties',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildFilterCheckbox(
                                  'Nieuw (< 24 uur)',
                                  _showInteractionsNew,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showInteractionsNew = v ?? true,
                                    ),
                                  ),
                                  Icons.fiber_new,
                                ),
                                _buildFilterCheckbox(
                                  'Recent (24u - 1 week)',
                                  _showInteractionsMedium,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showInteractionsMedium = v ?? true,
                                    ),
                                  ),
                                  Icons.access_time,
                                ),
                                _buildFilterCheckbox(
                                  'Oud (> 1 week)',
                                  _showInteractionsOld,
                                  (v) => setDialogState(
                                    () => setState(
                                      () => _showInteractionsOld = v ?? true,
                                    ),
                                  ),
                                  Icons.history,
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                        child: const Text('Alles herstellen'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  void _onTabSelected(NavTab tab) {
    if (tab == NavTab.kaart) return;
    final navigation = context.read<NavigationStateInterface>();
    switch (tab) {
      case NavTab.zones:
        navigation.pushReplacementForward(context, const SpeciesListScreen());
        break;
      case NavTab.rapporten:
        navigation.pushReplacementForward(context, const Rapporteren());
        break;
      case NavTab.logboek:
        navigation.pushReplacementForward(context, const LogbookScreen());
        break;
      case NavTab.profile:
        navigation.pushReplacementForward(context, const ProfileScreen());
        break;
      case NavTab.kaart:
        break;
    }
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
                              subdomains: const ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'com.wildgids.app',
                              keepBuffer: 1,
                            ),

                            _useClusters
                                ? cl.MarkerClusterLayerWidget(
                                  options: cl.MarkerClusterLayerOptions(
                                    markers:
                                        map.animalPins
                                            .where(
                                              (pin) =>
                                                  _within31Days(pin.seenAt),
                                            )
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
                                              final style =
                                                  _iconStyleForTimestamp(
                                                    pin.seenAt,
                                                  );
                                              final Color animalColor = Colors.grey;
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
                                                                    BlendMode
                                                                        .srcIn,
                                                                  ),
                                                              child: Image.asset(
                                                                _getAnimalIconPath(
                                                                  pin.speciesName,
                                                                )!,
                                                                width:
                                                                    style.size,
                                                                height:
                                                                    style.size,
                                                                fit:
                                                                    BoxFit
                                                                        .contain,
                                                                errorBuilder: (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return Icon(
                                                                    Icons.pets,
                                                                    size:
                                                                        style
                                                                            .size *
                                                                        0.9,
                                                                    color:
                                                                        animalColor,
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          )
                                                          : Icon(
                                                            Icons.pets,
                                                            size: style.size,
                                                            color: animalColor,
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
                                  markers:
                                      map.animalPins
                                          .where(
                                            (pin) => _within31Days(pin.seenAt),
                                          )
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
                                            final mapRotation =
                                                map
                                                    .mapController
                                                    .camera
                                                    .rotation;
                                            return fm.Marker(
                                              point: LatLng(pin.lat, pin.lon),
                                              width: 44,
                                              height: 44,
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
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            _,
                                                          ) => AnimalDetailDialog(
                                                            animal: pin,
                                                            animalIconPath:
                                                                _getAnimalIconPath(
                                                                  pin.speciesName,
                                                                ),
                                                          ),
                                                    );
                                                  },
                                                  child: Builder(
                                                    builder: (ctx) {
                                                      final style =
                                                          _iconStyleForTimestamp(
                                                            pin.seenAt,
                                                          );
                                                      final Color animalColor = Colors.grey;
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
                                                                    animalColor,
                                                                    BlendMode
                                                                        .srcIn,
                                                                  ),
                                                              child: Image.asset(
                                                                _getAnimalIconPath(
                                                                  pin.speciesName,
                                                                )!,
                                                                width:
                                                                    style.size,
                                                                height:
                                                                    style.size,
                                                                fit:
                                                                    BoxFit
                                                                        .contain,
                                                                errorBuilder: (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return Icon(
                                                                    Icons.pets,
                                                                    size:
                                                                        style
                                                                            .size *
                                                                        0.9,
                                                                    color:
                                                                        animalColor,
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          )
                                                          : Icon(
                                                            Icons.pets,
                                                            size: style.size,
                                                            color: animalColor,
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
                                    markers:
                                        map.detectionPins
                                            .where(
                                              (pin) =>
                                                  _within31Days(pin.detectedAt),
                                            )
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
                                                      showDialog(
                                                        context: context,
                                                        builder:
                                                            (_) =>
                                                                DetectionDetailDialog(
                                                                  detection:
                                                                      pin,
                                                                ),
                                                      );
                                                    },
                                                    child: Icon(
                                                      Icons.sensors,
                                                      size: style.size,
                                                      color: Colors.white,
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
                                  markers:
                                      map.detectionPins
                                          .where(
                                            (pin) =>
                                                _within31Days(pin.detectedAt),
                                          )
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
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (_) =>
                                                              DetectionDetailDialog(
                                                                detection: pin,
                                                              ),
                                                    );
                                                  },
                                                  child: Icon(
                                                    Icons.sensors,
                                                    size: style.size,
                                                    color: Colors.white,
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
                                    markers:
                                        map.interactions
                                            .where(
                                              (itx) =>
                                                  _within31Days(itx.moment),
                                            )
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
                                              final mapRotation =
                                                  map
                                                      .mapController
                                                      .camera
                                                      .rotation;
                                              return fm.Marker(
                                                point: LatLng(itx.lat, itx.lon),
                                                width: 44,
                                                height: 44,
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
                                                      showDialog(
                                                        context: context,
                                                        builder:
                                                            (
                                                              _,
                                                            ) => InteractionDetailDialog(
                                                              interaction: itx,
                                                              animalIconPath:
                                                                  _getAnimalIconPath(
                                                                    itx.speciesName,
                                                                  ),
                                                            ),
                                                      );
                                                    },
                                                    child: Builder(
                                                      builder: (ctx) {
                                                        final style =
                                                            _iconStyleForTimestamp(
                                                              itx.moment,
                                                            );
                                                        final Color interactionColor = Colors.black;
                                                        return _getAnimalIconPath(
                                                                  itx.speciesName,
                                                                ) !=
                                                                null
                                                            ? SizedBox(
                                                              width: style.size,
                                                              height:
                                                                  style.size,
                                                              child: ColorFiltered(
                                                                colorFilter:
                                                                    ColorFilter.mode(
                                                                      interactionColor,
                                                                      BlendMode
                                                                          .srcIn,
                                                                    ),
                                                                child: Image.asset(
                                                                  _getAnimalIconPath(
                                                                    itx.speciesName,
                                                                  )!,
                                                                  width:
                                                                      style
                                                                          .size,
                                                                  height:
                                                                      style
                                                                          .size,
                                                                  fit:
                                                                      BoxFit
                                                                          .contain,
                                                                  errorBuilder: (
                                                                    context,
                                                                    error,
                                                                    stackTrace,
                                                                  ) {
                                                                    return Icon(
                                                                      Icons
                                                                          .place,
                                                                      size:
                                                                          style
                                                                              .size *
                                                                          0.9,
                                                                      color:
                                                                          interactionColor,
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            )
                                                            : Icon(
                                                              Icons.place,
                                                              size: style.size,
                                                              color:
                                                                  interactionColor,
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
                                  markers: map.interactions
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
                                        final mapRotation =
                                            map.mapController.camera.rotation;
                                        return fm.Marker(
                                          point: LatLng(itx.lat, itx.lon),
                                          width: 44,
                                          height: 44,
                                          rotate: false,
                                          child: Transform.rotate(
                                            angle: -mapRotation * math.pi / 180,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => AnimalDetailDialog(
                                                    animal: itx.toAnimalPin(),
                                                    animalIconPath:
                                                        _getAnimalIconPath(itx.speciesName),
                                                  ),
                                                );
                                              },
                                              child: Builder(
                                                builder: (ctx) {
                                                  final style =
                                                      _iconStyleForTimestamp(itx.moment);
                                                  final Color interactionColor = Colors.black;
                                                  return _getAnimalIconPath(itx.speciesName) != null
                                                      ? SizedBox(
                                                          width: style.size,
                                                          height: style.size,
                                                          child: ColorFiltered(
                                                            colorFilter: ColorFilter.mode(
                                                              interactionColor,
                                                              BlendMode.srcIn,
                                                            ),
                                                            child: Image.asset(
                                                              _getAnimalIconPath(itx.speciesName)!,
                                                              width: style.size,
                                                              height: style.size,
                                                              fit: BoxFit.contain,
                                                              errorBuilder:
                                                                  (context, error, stackTrace) => Icon(
                                                                    Icons.place,
                                                                    size: style.size * 0.9,
                                                                    color: interactionColor,
                                                                  ),
                                                            ),
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons.place,
                                                          size: style.size,
                                                          color: interactionColor,
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
                                    tooltip: 'Volgen',
                                    onPressed: () {
                                      if (_showTrackingHistory) {
                                        setState(() {
                                          _showTrackingHistory = false;
                                          _followUser = !_followUser;
                                        });
                                      } else {
                                        _loadTrackingHistory();
                                      }
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
                                  GestureDetector(
                                    onLongPress: () => _showFilterDialog(context),
                                    child: IconButton(
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
                        if (_devDebugToolsEnabled)
                          Positioned(
                            top: 210,
                            right: 20,
                            child: GestureDetector(
                              onTap: _injectMockPins,
                              onLongPress: _emitDevTrackingNotice,
                              child: const Icon(
                                Icons.bug_report,
                                color: Colors.black54,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        floatingActionButton: null,
        bottomNavigationBar: SafeArea(
          top: false,
          child: CustomNavBar(
            currentTab: NavTab.kaart,
            onTabSelected: _onTabSelected,
          ),
        ),
      ),
    );
  }

  String? _getAnimalIconPath(String? speciesName) {
    if (speciesName == null) return null;

    final name = speciesName.toLowerCase();

    if (name.contains('wolf')) return 'assets/icons/animals/wolf.png';
    if (name.contains('vos') || name.contains('fox')) {
      return 'assets/icons/animals/vos.png';
    }
    if (name.contains('das') || name.contains('badger')) {
      return 'assets/icons/animals/das.png';
    }
    if (name.contains('ree') || name.contains('deer')) {
      return 'assets/icons/animals/ree.png';
    }
    if (name.contains('zwijn') || name.contains('boar')) {
      return 'assets/icons/animals/wild_zwijn.png';
    }
    if (name.contains('damhert')) return 'assets/icons/animals/damhert.png';
    if (name.contains('egel') || name.contains('hedgehog')) {
      return 'assets/icons/animals/egel.png';
    }
    if (name.contains('eekhoorn') || name.contains('squirrel')) {
      return 'assets/icons/animals/eekhoorn.png';
    }
    if (name.contains('bever') || name.contains('beaver')) {
      return 'assets/icons/animals/beaver.png';
    }
    if (name.contains('boommarten') || name.contains('marten')) {
      return 'assets/icons/animals/boommarten.png';
    }
    if (name.contains('hooglander') || name.contains('highlander')) {
      return 'assets/icons/animals/hooglander.png';
    }
    if (name.contains('wisent') || name.contains('bison')) {
      return 'assets/icons/animals/winsent.png';
    }

    return null;
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


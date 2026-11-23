import 'package:wildgids/widgets/reporting/report_layout.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wildgids/widgets/map/carto_attribution.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/models/beta_models/location_model.dart';
import 'package:wildgids/models/enums/location_source.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/screens/waarneming/location_datetime_screen.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({
    super.key,
    this.initialLocation,
    this.initialDateTime,
    this.onCancel,
    this.freezeInitialLocation = false,
    this.returnSelection = false,
  });
  final LatLng? initialLocation;
  final DateTime? initialDateTime;
  final VoidCallback? onCancel;
  final bool freezeInitialLocation;
  final bool returnSelection;

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late fm.MapController _mapController;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  bool _userPickedLocation = false;
  bool _locating = true;
  late final LocationMapManager _locationService;

  // Fallback map center (NL) only when no GPS/cache is available yet.
  static const LatLng defaultCenter = LatLng(52.0116, 5.8020);

  @override
  void initState() {
    super.initState();
    _mapController = fm.MapController();
    _locationService = LocationMapManager();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapLocation());
    });
  }

  Position? _cachedPositionFromApp() {
    final app = context.read<AppStateProvider>();
    if (app.isLocationCacheValid && app.cachedPosition != null) {
      return app.cachedPosition;
    }
    return context.read<MapProvider>().currentPosition;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _applyGpsPoint(LatLng point) {
    setState(() {
      _currentLocation = point;
      if (!_userPickedLocation) {
        _selectedLocation = point;
      }
    });
    try {
      _mapController.move(point, 15.0);
    } catch (_) {
      // Map may not be ready on the first frame.
    }
  }

  Future<void> _bootstrapLocation() async {
    if (!mounted) return;
    if (widget.initialLocation != null) {
      _applyGpsPoint(widget.initialLocation!);
      setState(() {
        _userPickedLocation = true;
        _locating = false;
      });
      return;
    }
    if (widget.freezeInitialLocation) {
      setState(() => _locating = false);
      return;
    }

    final cached = _cachedPositionFromApp();
    if (cached != null) {
      _applyGpsPoint(LatLng(cached.latitude, cached.longitude));
      if (mounted) setState(() => _locating = false);
    }

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        _applyGpsPoint(LatLng(lastKnown.latitude, lastKnown.longitude));
      }
    } catch (_) {}

    try {
      final position = await _locationService.determinePosition();
      if (!mounted || position == null) return;
      _applyGpsPoint(LatLng(position.latitude, position.longitude));
    } catch (_) {
      // No GPS — user can still pick on the map.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
      setState(() {
        _selectedLocation = _currentLocation;
      });
    }
  }

  void _onMapTap(LatLng latlng) {
    setState(() {
      _userPickedLocation = true;
      _selectedLocation = latlng;
    });
  }

  void _onSelectPressed() {
    if (_selectedLocation != null) {
      // Save location to app state
      final sightingManager = context.read<AnimalSightingReportingInterface>();
      final navigationManager = context.read<NavigationStateInterface>();

      final location = LocationModel(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        source: LocationSource.manual,
      );

      sightingManager.updateLocation(location);

      if (widget.returnSelection) {
        Navigator.of(context).pop(_selectedLocation);
        return;
      }

      // API expects a system location; use GPS when available, else mirror manual.
      if (_currentLocation != null) {
        sightingManager.updateLocation(
          LocationModel(
            latitude: _currentLocation!.latitude,
            longitude: _currentLocation!.longitude,
            source: LocationSource.system,
          ),
        );
      } else {
        sightingManager.updateLocation(
          LocationModel(
            latitude: _selectedLocation!.latitude,
            longitude: _selectedLocation!.longitude,
            source: LocationSource.system,
          ),
        );
      }

      debugPrint(
        '[LocationSelection] Selected location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
      );

      // Navigate to the date/time selection screen
      navigationManager.pushForward(
        context,
        LocationDateTimeScreen(
          selectedLocation: _selectedLocation!,
          initialDateTime: widget.initialDateTime,
        ),
      );
    }
  }

  void _handleBackNavigation() {
    debugPrint('[LocationSelectionScreen] Back button pressed');
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      final navigationManager = context.read<NavigationStateInterface>();
      navigationManager.resetToHome(context);
    }
  }

  LatLng _mapInitialCenter() {
    if (widget.initialLocation != null) return widget.initialLocation!;
    if (_currentLocation != null) return _currentLocation!;
    final cached = _cachedPositionFromApp();
    if (cached != null) {
      return LatLng(cached.latitude, cached.longitude);
    }
    return defaultCenter;
  }

  @override
  Widget build(BuildContext context) => ReportLayout(
    title: 'Waar zag je het dier?',
    stage: 'Locatie',
    onBack: _handleBackNavigation,
    scroll: false,
    footer: ReportAction(
      label: 'Verder',
      onPressed: _selectedLocation != null ? _onSelectPressed : null,
    ),
    child: Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                fm.FlutterMap(
                  mapController: _mapController,
                  options: fm.MapOptions(
                    initialCenter: _mapInitialCenter(),
                    initialZoom: 15.0,
                    interactionOptions: const fm.InteractionOptions(
                      flags:
                          fm.InteractiveFlag.pinchZoom |
                          fm.InteractiveFlag.drag,
                    ),
                    onTap: (tapPosition, point) => _onMapTap(point),
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate: LocationMapManager.standardTileUrl,
                      tileProvider: fm.NetworkTileProvider(
                        headers: LocationMapManager.standardTileHeaders,
                      ),
                      subdomains: LocationMapManager.standardTileSubdomains,
                      userAgentPackageName: 'com.wildgids.app',
                      retinaMode: LocationMapManager.tileRetinaMode(context),
                      keepBuffer: 1,
                    ),
                    fm.MarkerLayer(
                      markers: [
                        // Current location (blue dot)
                        if (_currentLocation != null)
                          fm.Marker(
                            point: _currentLocation!,
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF0D53FF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        // Selected location (red pin)
                        if (_selectedLocation != null)
                          fm.Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFfDB5E5A),
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const CartoAttribution(alignment: Alignment.bottomLeft),
                if (_locating && _currentLocation == null)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33FFFFFF),
                      child: Center(
                        child: CircularProgressIndicator(color: GuideStyle.ink),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 18,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'report-location',
                    onPressed:
                        _currentLocation == null
                            ? null
                            : _centerOnCurrentLocation,
                    tooltip: 'Mijn locatie',
                    backgroundColor: GuideStyle.ink,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.touch_app_outlined, color: GuideStyle.ink),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tik om de plek aan te passen.',
                style: TextStyle(color: GuideStyle.muted, fontSize: 15),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

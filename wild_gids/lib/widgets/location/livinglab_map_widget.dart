import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildrapport/interfaces/location/location_screen_interface.dart';
import 'package:wildrapport/managers/map/location_map_manager.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:wildrapport/screens/location/location_screen.dart';
import 'package:wildrapport/screens/belonging/belonging_location_screen.dart';
import 'package:wildrapport/widgets/location/location_data_card.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';

class LivingLabMapScreen extends StatefulWidget {
  final String labName;
  final LatLng labCenter;
  final double boundaryOffset;
  final LocationMapManager? locationService; // For testing
  final LocationMapManager? mapService; // For testing
  final bool isFromPossession;

  const LivingLabMapScreen({
    super.key,
    required this.labName,
    required this.labCenter,
    this.boundaryOffset = 0.018,
    this.locationService,
    this.mapService,
    this.isFromPossession = false,
  });

  @override
  State<LivingLabMapScreen> createState() => _LivingLabMapScreenState();
}

class _LivingLabMapScreenState extends State<LivingLabMapScreen> {
  static const String _standardTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _satelliteTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  // Boundary variables
  late final double minLat;
  late final double maxLat;
  late final double minLng;
  late final double maxLng;
  late final List<LatLng> squareBoundary;

  late final LocationMapManager _locationService;
  late final LocationMapManager _mapService;
  late final MapProvider _mapProvider;

  Position? _currentPosition;
  String _currentAddress = '';
  LatLng? _markedLocation;
  String _markedAddress = '';
  bool _isLoading = true;
  bool _isSatelliteView = false;
  bool _shouldNavigate = false;
  String? _navigateToScreen;

  @override
  void initState() {
    super.initState();
    debugPrint('[LivingLabMapScreen] Initializing screen');
    _initializeServices();
    _initializeBoundaries();
    _quickLocationCheck();
  }

  void _initializeServices() {
    debugPrint('[LivingLabMapScreen] Initializing services');
    _locationService = widget.locationService ?? LocationMapManager();
    _mapService = widget.mapService ?? LocationMapManager();
    _mapProvider = context.read<MapProvider>();
    debugPrint(
      '[LivingLabMapScreen] Map controller initialized: ${_mapProvider.isInitialized}',
    );
  }

  void _initializeBoundaries() {
    minLat = widget.labCenter.latitude - widget.boundaryOffset;
    maxLat = widget.labCenter.latitude + widget.boundaryOffset;
    minLng = widget.labCenter.longitude - (widget.boundaryOffset * 1.556);
    maxLng = widget.labCenter.longitude + (widget.boundaryOffset * 1.556);

    squareBoundary = [
      LatLng(maxLat, minLng),
      LatLng(maxLat, maxLng),
      LatLng(minLat, maxLng),
      LatLng(minLat, minLng),
      LatLng(maxLat, minLng),
    ];
  }

  void _initializeMapView() {
    debugPrint('[LivingLabMapScreen] Initializing map view');
    debugPrint('[LivingLabMapScreen] Moving map to lab center');
    _mapProvider.mapController.move(widget.labCenter, 15);
  }

  Future<void> _quickLocationCheck() async {
    _isLoading = true;

    final appState = context.read<AppStateProvider>();
    if (appState.isLocationCacheValid && appState.cachedPosition != null) {
      debugPrint(
        '\x1B[36m[LivingLabMapScreen] Using cached location data\x1B[0m',
      );
      await _handleUserLocation(appState.cachedPosition!, animate: false);
      return;
    }

    final lastPosition = await Geolocator.getLastKnownPosition();
    if (!mounted) return;

    if (lastPosition != null) {
      await _handleUserLocation(lastPosition, animate: false);
    }

    _initLocation();
  }

  void _constrainMap() {
    final currentCenter = _mapProvider.mapController.camera.center;
    var newCenter = currentCenter;

    if (currentCenter.latitude < minLat) {
      newCenter = LatLng(minLat, newCenter.longitude);
    } else if (currentCenter.latitude > maxLat) {
      newCenter = LatLng(maxLat, newCenter.longitude);
    }

    if (currentCenter.longitude < minLng) {
      newCenter = LatLng(newCenter.latitude, minLng);
    } else if (currentCenter.longitude > maxLng) {
      newCenter = LatLng(newCenter.latitude, maxLng);
    }

    if (newCenter != currentCenter) {
      _mapProvider.mapController.move(
        newCenter,
        _mapProvider.mapController.camera.zoom,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleUserLocation(
    Position position, {
    bool animate = true,
  }) async {
    bool isInBounds =
        position.latitude >= minLat &&
        position.latitude <= maxLat &&
        position.longitude >= minLng &&
        position.longitude <= maxLng;

    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentPosition = position;
        _markedLocation = null;
        _markedAddress = '';
        _currentAddress =
            isInBounds ? 'Fetching address...' : 'Buiten het onderzoeksgebied';
      });
    }

    if (isInBounds && animate) {
      _mapProvider.mapController.move(
        LatLng(position.latitude, position.longitude),
        16,
      );
    } else if (!isInBounds && animate) {
      _mapProvider.mapController.move(widget.labCenter, 15);
    }

    if (isInBounds) {
      await _updateAddress(position);
    }
  }

  Future<void> _initLocation() async {
    final appState = context.read<AppStateProvider>();
    if (appState.isLocationCacheValid && appState.cachedPosition != null) {
      debugPrint(
        '[LivingLabMapScreen] Using cached location for initialization',
      );
      await _handleUserLocation(appState.cachedPosition!, animate: false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (!mounted) return;

      await _handleUserLocation(position, animate: false);
    } catch (e) {
      debugPrint('Error getting location: $e');
      await _getReducedAccuracyLocation();
    }
  }

  Future<void> _getReducedAccuracyLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.reduced,
        ),
      );

      if (!mounted) return;

      await _handleUserLocation(position, animate: false);
    } catch (e) {
      debugPrint('Error getting reduced accuracy location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentAddress = 'Locatie niet beschikbaar';
        });
      }
    }
  }

  Future<void> _updateAddress(Position position) async {
    final address = await _locationService.getAddressFromPosition(position);
    if (!mounted) return;

    setState(() {
      _currentAddress = address;
    });
  }

  Future<void> _handleTap(TapPosition tapPosition, LatLng point) async {
    // Check if tapped point is within Living Lab boundaries
    if (point.latitude < minLat ||
        point.latitude > maxLat ||
        point.longitude < minLng ||
        point.longitude > maxLng) {
      debugPrint('[LivingLabMapScreen] Tap outside boundaries - ignoring');
      return;
    }

    final tempPoint = point;
    if (mounted) {
      setState(() {
        _markedLocation = tempPoint;
        _markedAddress = 'Fetching address...';
      });
    }

    try {
      final address = await _mapService.getAddressFromLatLng(point);
      if (!mounted) return;

      setState(() {
        _markedAddress = address;
      });
    } catch (e) {
      debugPrint('Error fetching address: $e');
      if (mounted) {
        setState(() {
          _markedAddress = 'Address unavailable';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldNavigate) {
      debugPrint(
        '[LivingLabMapScreen] Handling navigation in build: _navigateToScreen= $_navigateToScreen',
      );
      final navTarget = _navigateToScreen;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final navigationManager = context.read<NavigationStateInterface>();
          if (navTarget == 'possession') {
            debugPrint(
              '[LivingLabMapScreen] Navigating to BelongingLocationScreen',
            );
            navigationManager.pushReplacementBack(
              context,
              const BelongingLocationScreen(),
            );
          } else if (navTarget == 'location') {
            debugPrint('[LivingLabMapScreen] Navigating to LocationScreen');
            navigationManager.pushReplacementBack(
              context,
              const LocationScreen(),
            );
          }
        }
      });
      _shouldNavigate = false;
      _navigateToScreen = null;
    }

    return Scaffold(
      body: SafeArea(
        child: Consumer<MapProvider>(
          builder: (context, mapProvider, child) {
            debugPrint(
              '[LivingLabMapScreen] Building map widget, initialized: ${mapProvider.isInitialized}',
            );
            if (!mapProvider.isInitialized) {
              debugPrint('[LivingLabMapScreen] Showing loading indicator');
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                FlutterMap(
                  mapController: mapProvider.mapController,
                  options: MapOptions(
                    minZoom: 14,
                    maxZoom: 18,
                    initialCenter: widget.labCenter,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onPositionChanged: (MapPosition position, bool hasGesture) {
                      if (hasGesture) _constrainMap();
                    },
                    onTap: _handleTap,
                    onMapReady: () {
                      debugPrint('[LivingLabMapScreen] Map is ready');
                      _initializeMapView();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          _isSatelliteView
                              ? _satelliteTileUrl
                              : _standardTileUrl,
                      userAgentPackageName: 'com.wildrapport.app',
                    ),
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: squareBoundary,
                          color: Colors.blue.withValues(alpha: 0.3),
                          borderColor: Colors.blue,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),
                if (_markedLocation == null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkGreen,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tik op de kaart om een locatie te kiezen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: _markedLocation == null ? 76 : 16,
                  left: 16,
                  right: 16,
                  child: LocationDataCard(
                    cityName:
                        _markedLocation != null
                            ? _getLocationCity(_markedAddress)
                            : _getLocationCity(_currentAddress),
                    streetName:
                        _markedLocation != null
                            ? _getLocationStreet(_markedAddress)
                            : _getLocationStreet(_currentAddress),
                    houseNumber:
                        _markedLocation != null
                            ? _getLocationHouseNumber(_markedAddress)
                            : _getLocationHouseNumber(_currentAddress),
                    isLoading: _isLoading,
                    isCurrentLocation: _markedLocation == null,
                    latitude:
                        _markedLocation?.latitude ?? _currentPosition?.latitude,
                    longitude:
                        _markedLocation?.longitude ??
                        _currentPosition?.longitude,
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(
                  icon: Icons.arrow_back,
                  label: 'Terug',
                  onPressed: () {
                    final navigationManager =
                        context.read<NavigationStateInterface>();
                    if (widget.isFromPossession) {
                      navigationManager.pushReplacementBack(
                        context,
                        const BelongingLocationScreen(),
                      );
                    } else {
                      navigationManager.pushReplacementBack(
                        context,
                        const LocationScreen(),
                      );
                    }
                  },
                ),
                _buildNavButton(
                  icon: _isSatelliteView ? Icons.map : Icons.satellite,
                  label: _isSatelliteView ? 'Kaart' : 'Satelliet',
                  onPressed: () {
                    setState(() {
                      _isSatelliteView = !_isSatelliteView;
                    });
                  },
                ),
                _buildNavButton(
                  icon: Icons.my_location,
                  label: 'Mijn Locatie',
                  onPressed: _handleLocationButtonPress,
                ),
                _buildNavButton(
                  icon: Icons.check_circle,
                  label: 'Bevestig',
                  onPressed:
                      _markedLocation != null
                          ? () async {
                            debugPrint(
                              '[LivingLabMapScreen] Confirm button pressed, isFromPossession: ${widget.isFromPossession}',
                            );

                            final position = Position(
                              latitude: _markedLocation!.latitude,
                              longitude: _markedLocation!.longitude,
                              timestamp: DateTime.now(),
                              accuracy: 0,
                              altitude: 0,
                              altitudeAccuracy: 0,
                              heading: 0,
                              headingAccuracy: 0,
                              speed: 0,
                              speedAccuracy: 0,
                              isMocked: false,
                            );

                            final mapProvider = context.read<MapProvider>();
                            debugPrint(
                              '[LivingLabMapScreen] Setting selected location',
                            );
                            mapProvider.setSelectedLocation(
                              position,
                              _markedAddress,
                            );

                            if (!widget.isFromPossession) {
                              final locationManager =
                                  context.read<LocationScreenInterface>();
                              debugPrint(
                                '[LivingLabMapScreen] Calling getLocationAndDateTime',
                              );
                              await locationManager.getLocationAndDateTime(
                                context,
                              );
                            }

                            debugPrint(
                              '[LivingLabMapScreen] Setting _shouldNavigate to true',
                            );
                            setState(() {
                              _shouldNavigate = true;
                              _navigateToScreen =
                                  widget.isFromPossession
                                      ? 'possession'
                                      : 'location';
                            });
                          }
                          : null,
                  isEnabled: _markedLocation != null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isEnabled = true,
  }) {
    final color =
        isEnabled ? AppColors.brown : AppColors.brown.withValues(alpha: 0.3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_currentPosition != null &&
        _locationService.isLocationInNetherlands(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        )) {
      markers.add(
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 28,
          height: 28,
          rotate: false,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[100]!.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_markedLocation != null) {
      markers.add(
        Marker(
          point: _markedLocation!,
          width: 50,
          height: 50,
          rotate: false,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.3),
            ),
            child: const Icon(Icons.location_pin, color: Colors.red, size: 28),
          ),
        ),
      );
    }

    return markers;
  }

  void _handleLocationButtonPress() {
    if (_currentPosition != null) {
      _handleUserLocation(_currentPosition!, animate: true);
    } else {
      _initLocation();
    }
  }

  String? _getLocationCity(String address) {
    final parts = address.split(',');
    return parts.length > 2 ? parts[2].trim() : null;
  }

  String? _getLocationStreet(String address) {
    final parts = address.split(',');
    if (parts.isNotEmpty) {
      final streetParts = parts[0].trim().split(' ');
      return streetParts.length > 1
          ? streetParts.take(streetParts.length - 1).join(' ')
          : streetParts[0];
    }
    return null;
  }

  String? _getLocationHouseNumber(String address) {
    final parts = address.split(',');
    if (parts.isNotEmpty) {
      final streetParts = parts[0].trim().split(' ');
      return streetParts.length > 1 ? streetParts.last : null;
    }
    return null;
  }
}

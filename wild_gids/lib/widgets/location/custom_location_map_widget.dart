import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildrapport/managers/map/location_map_manager.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:wildrapport/widgets/location/location_data_card.dart';
import 'package:provider/provider.dart';

class CustomLocationMapScreen extends StatefulWidget {
  final bool isFromPossession;
  final LocationMapManager? locationService;
  final LocationMapManager? mapService;

  const CustomLocationMapScreen({
    super.key,
    this.isFromPossession = false,
    this.locationService,
    this.mapService,
  });

  @override
  State<CustomLocationMapScreen> createState() =>
      _CustomLocationMapScreenState();
}

class _CustomLocationMapScreenState extends State<CustomLocationMapScreen> {
  static const String _standardTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _satelliteTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  late final LocationMapManager _locationService;
  late final LocationMapManager _mapService;
  late final MapProvider _mapProvider;

  Position? _currentPosition;
  String _currentAddress = '';
  LatLng? _markedLocation;
  String _markedAddress = '';
  bool _isLoading = true;
  bool _isSatelliteView = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[CustomLocationMapScreen] Initializing screen');
    _initializeServices();
    _quickLocationCheck();
  }

  void _initializeServices() {
    debugPrint('[CustomLocationMapScreen] Initializing services');
    _locationService = widget.locationService ?? LocationMapManager();
    _mapService = widget.mapService ?? LocationMapManager();
    _mapProvider = context.read<MapProvider>();
    debugPrint(
      '[CustomLocationMapScreen] Map controller initialized: ${_mapProvider.isInitialized}',
    );
    if (!_mapProvider.isInitialized) {
      // Ensure a map controller exists to avoid blank map on first open
      _mapProvider.initialize();
    }
  }

  void _quickLocationCheck() async {
    debugPrint('[CustomLocationMapScreen] Checking cached location');

    // Try to use current position from MapProvider if available
    final cachedPosition = _mapProvider.currentPosition;
    if (cachedPosition != null) {
      debugPrint(
        '[CustomLocationMapScreen] Using cached position from MapProvider',
      );
      setState(() {
        _currentPosition = cachedPosition;
        _currentAddress = _mapProvider.currentAddress;
        _isLoading = false;
      });
      _initializeMapView();
      return;
    }

    // Otherwise get fresh location
    try {
      final position = await _locationService.determinePosition();
      if (!mounted) return;

      if (position != null) {
        final address = await _locationService.getAddressFromPosition(position);
        if (!mounted) return;

        setState(() {
          _currentPosition = position;
          _currentAddress = address;
          _isLoading = false;
        });
        _initializeMapView();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[CustomLocationMapScreen] Error getting location: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeMapView() {
    if (_currentPosition != null) {
      debugPrint('[CustomLocationMapScreen] Initializing map view');
      final center = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      _mapProvider.mapController.move(center, 15);
    }
  }

  void _handleTap(LatLng tappedPoint) async {
    debugPrint('[CustomLocationMapScreen] Map tapped at: $tappedPoint');

    setState(() {
      _markedLocation = tappedPoint;
      _markedAddress = 'Adres ophalen...';
    });

    try {
      final address = await _mapService.getAddressFromLatLng(tappedPoint);
      if (!mounted) return;

      setState(() {
        _markedAddress = address;
      });

      debugPrint('[CustomLocationMapScreen] Address retrieved: $address');
    } catch (e) {
      debugPrint('[CustomLocationMapScreen] Error getting address: $e');
      if (mounted) {
        setState(() {
          _markedAddress = 'Adres niet beschikbaar';
        });
      }
    }
  }

  void _confirmLocation() {
    if (_markedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tik op de kaart om een locatie te selecteren'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    debugPrint(
      '[CustomLocationMapScreen] Confirming location: $_markedLocation',
    );
    debugPrint('[CustomLocationMapScreen] Address: $_markedAddress');

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
    );

    _mapProvider.setSelectedLocation(position, _markedAddress);
    debugPrint('[CustomLocationMapScreen] Location set in MapProvider');

    // Navigate back
    Navigator.pop(context);
  }

  // Satellite toggle and center controls removed from UI; helpers not needed

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: AppColors.offWhite,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final center =
        _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(52.3874, 4.5753); // Default to Netherlands center

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapProvider.mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 18,
              onTap: (tapPosition, point) => _handleTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    _isSatelliteView ? _satelliteTileUrl : _standardTileUrl,
                userAgentPackageName: 'com.wildrapport.app',
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 40,
                      height: 40,
                      rotate: false,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              if (_markedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _markedLocation!,
                      width: 40,
                      height: 40,
                      rotate: false,
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
          Positioned(
            left: 16,
            top: 16,
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
              latitude: _markedLocation?.latitude ?? _currentPosition?.latitude,
              longitude:
                  _markedLocation?.longitude ?? _currentPosition?.longitude,
            ),
          ),
        ],
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkGreen,
                      side: BorderSide(color: AppColors.darkGreen),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Annuleren'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Bevestigen'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

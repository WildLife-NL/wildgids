import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/interfaces/filters/dropdown_interface.dart';
import 'package:wildrapport/interfaces/location/location_screen_interface.dart';
import 'package:wildrapport/interfaces/map/location_service_interface.dart';
import 'package:wildrapport/managers/map/location_screen_manager.dart';
import 'package:wildrapport/managers/map/location_map_manager.dart';
import 'package:wildrapport/models/enums/date_time_type.dart';
import 'package:wildrapport/models/enums/dropdown_type.dart';
import 'package:wildrapport/models/enums/location_type.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:wildrapport/screens/location/map_screen.dart';
import 'package:wildrapport/screens/belonging/belonging_location_screen.dart';
import 'package:wildrapport/widgets/location/livinglab_map_widget.dart';
import 'package:wildrapport/widgets/location/location_display.dart';
import 'package:wildrapport/widgets/location/location_map_preview.dart';
import 'package:wildrapport/widgets/location/time_selection_row.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class LocationScreenUIWidget extends StatefulWidget {
  const LocationScreenUIWidget({super.key});

  @override
  State<LocationScreenUIWidget> createState() => _LocationScreenUIWidgetState();
}

class _LocationScreenUIWidgetState extends State<LocationScreenUIWidget> {
  late final LocationServiceInterface _locationService;
  String _selectedLocation = LocationType.current.displayText;
  late final MapProvider _mapProvider;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _locationService = LocationMapManager();
    _mapProvider = context.read<MapProvider>();
    _initializeMap();
    _updateSelectedLocation();
  }

  // Add listener for map provider changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateSelectedLocation() {
    if (_mapProvider.selectedPosition == null) {
      setState(() {
        _selectedLocation =
            _mapProvider.selectedAddress == LocationType.unknown.displayText
                ? LocationType.unknown.displayText
                : LocationType.current.displayText;
      });
      return;
    }

    final selectedPoint = LatLng(
      _mapProvider.selectedPosition!.latitude,
      _mapProvider.selectedPosition!.longitude,
    );

    String newLocation = LocationType.current.displayText;

    if (_isWithinBoundary(
      selectedPoint,
      const LatLng(52.3874, 4.5753),
      0.018,
    )) {
      newLocation = LocationType.npZuidKennemerland.displayText;
    } else if (_isWithinBoundary(
      selectedPoint,
      const LatLng(51.1950, 5.7230),
      0.045,
    )) {
      newLocation = LocationType.grensparkKempenbroek.displayText;
    }

    // Update dropdown immediately
    setState(() {
      _selectedLocation = newLocation;
    });
  }

  bool _isWithinBoundary(LatLng point, LatLng center, double tolerance) {
    return (point.latitude >= center.latitude - tolerance &&
            point.latitude <= center.latitude + tolerance) &&
        (point.longitude >= center.longitude - tolerance &&
            point.longitude <= center.longitude + tolerance);
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;

    // Reset state variables
    _selectedLocation = LocationType.current.displayText;
    _isExpanded = false;

    // Handle case where location is already selected
    if (_mapProvider.selectedPosition != null) {
      _mapProvider.updatePosition(
        _mapProvider.selectedPosition!,
        _mapProvider.selectedAddress,
      );
      // Schedule map update for next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateMapView(_mapProvider.selectedPosition!);
      });
      return;
    }

    // Try to use cached location first
    final appState = context.read<AppStateProvider>();
    if (appState.isLocationCacheValid && appState.cachedPosition != null) {
      debugPrint('[LocationScreenUIWidget] Using cached location data');
      final position = appState.cachedPosition!;
      final address = appState.cachedAddress ?? '';

      if (_locationService.isLocationInNetherlands(
        position.latitude,
        position.longitude,
      )) {
        _mapProvider.updatePosition(position, address);
        _updateMapView(position);
        return;
      }
    }

    // Fall back to getting new location if cache is invalid or outside NL
    final position = await _locationService.determinePosition();
    if (!mounted) return;

    if (position != null &&
        _locationService.isLocationInNetherlands(
          position.latitude,
          position.longitude,
        )) {
      final address = await _locationService.getAddressFromPosition(position);
      if (!mounted) return;

      _mapProvider.updatePosition(position, address);
      _updateMapView(position);
    }
  }

  // Helper method to update map view
  Future<void> _updateMapView(Position position) async {
    // Schedule the map update for after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      while (mounted && (!_mapProvider.isInitialized)) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      if (!mounted) return;

      try {
        _mapProvider.mapController.move(
          LatLng(position.latitude, position.longitude),
          15,
        );
      } catch (e) {
        debugPrint('Error moving map: $e');
      }
    });
  }

  void _handleLocationSelection(String location) async {
    // Immediate UI update for dropdown
    setState(() {
      _selectedLocation = location;
      _isExpanded = false;
    });

    final mapProvider = context.read<MapProvider>();

    if (location == LocationType.unknown.displayText) {
      await mapProvider.clearSelectedLocation();
      return;
    }

    if (location == LocationType.current.displayText) {
      mapProvider.setLoading(true);

      // Try to use cached location first
      final appState = context.read<AppStateProvider>();
      if (appState.isLocationCacheValid && appState.cachedPosition != null) {
        debugPrint('[LocationScreenUIWidget] Using cached location data');
        final position = appState.cachedPosition!;
        final address = appState.cachedAddress ?? '';

        if (_locationService.isLocationInNetherlands(
          position.latitude,
          position.longitude,
        )) {
          await mapProvider.resetToCurrentLocation(position, address);
          _updateMapView(position);
          return;
        }
      }

      // Fall back to getting new location if cache is invalid or outside NL
      final position = await _locationService.determinePosition();
      if (!mounted) return;

      if (position != null &&
          _locationService.isLocationInNetherlands(
            position.latitude,
            position.longitude,
          )) {
        final address = await _locationService.getAddressFromPosition(position);
        if (!mounted) return;

        await mapProvider.resetToCurrentLocation(position, address);
        _updateMapView(position);
      } else {
        mapProvider.setLoading(false);
      }
    } else if (location == LocationType.npZuidKennemerland.displayText) {
      _navigateToLivingLab(
        'Nationaal Park Zuid-Kennemerland',
        const LatLng(52.3874, 4.5753),
        0.018,
      );
    } else if (location == LocationType.grensparkKempenbroek.displayText) {
      _navigateToLivingLab(
        'Grenspark Kempen-Broek',
        const LatLng(51.1950, 5.7230),
        0.045,
      );
    }
  }

  void _navigateToLivingLab(String labName, LatLng center, double offset) {
    final mapProvider = context.read<MapProvider>();
    mapProvider.setLoading(true);
    mapProvider.currentPosition = null;
    mapProvider.currentAddress = '';

    // Check if we're in the possession flow by checking the current context
    final isFromPossession =
        ModalRoute.of(context)?.settings.name == 'PossesionLocationScreen' ||
        context.findAncestorWidgetOfExactType<BelongingLocationScreen>() !=
            null;

    debugPrint(
      '[LocationScreenUIWidget] Navigating to LivingLab. isFromPossession: $isFromPossession',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          name: isFromPossession ? 'PossesionLivingLabMap' : 'LivingLabMap',
        ),
        builder:
            (_) => MapScreen(
              title: labName,
              mapWidget: LivingLabMapScreen(
                labName: labName,
                labCenter: center,
                boundaryOffset: offset,
                isFromPossession: isFromPossession,
              ),
            ),
      ),
    );
  }

  void _handleLocationIconTap() {
    debugPrint('Location icon tapped in LocationScreenUIWidget');
  }

  @override
  Widget build(BuildContext context) {
    final dropdownInterface = context.read<DropdownInterface>();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecteer locatie',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brown,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 160,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.brown.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            dropdownInterface.buildDropdown(
              type: DropdownType.location,
              selectedValue: _selectedLocation,
              isExpanded: _isExpanded,
              onExpandChanged: (value) => setState(() => _isExpanded = value),
              onOptionSelected: _handleLocationSelection,
              context: context,
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const LocationMapPreview(),
                  LocationDisplay(
                    onLocationIconTap: _handleLocationIconTap,
                    locationText: context.watch<MapProvider>().selectedAddress,
                    isLoading:
                        context.watch<MapProvider>().selectedAddress.isEmpty,
                    position:
                        context.watch<MapProvider>().selectedPosition ??
                        context.watch<MapProvider>().currentPosition,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datum en tijd',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brown,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 130,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.brown.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TimeSelectionRow(
              initialSelection:
                  context.read<LocationScreenInterface>().selectedDateTime,
              initialDate:
                  context.read<LocationScreenInterface>().customDateTime,
              onOptionSelected: (selectedOption) {
                final locationManager = context.read<LocationScreenInterface>();
                if (locationManager is LocationScreenManager) {
                  locationManager.updateDateTime(selectedOption);
                }
              },
              onDateSelected: (date) {
                final locationManager = context.read<LocationScreenInterface>();
                if (locationManager is LocationScreenManager) {
                  locationManager.updateDateTime(
                    DateTimeType.custom.displayText,
                    date: date,
                  );
                }
              },
              onTimeSelected: (time) {
                final locationManager = context.read<LocationScreenInterface>();
                if (locationManager is LocationScreenManager) {
                  locationManager.updateDateTime(
                    DateTimeType.custom.displayText,
                    time: time,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/interfaces/location/location_screen_interface.dart';
import 'package:wildgids/interfaces/map/location_service_interface.dart';
import 'package:wildgids/managers/map/location_screen_manager.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/models/enums/date_time_type.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/providers/map_provider.dart';
// Removed dropdown-based navigation; map navigation handled within preview widget
import 'package:wildgids/widgets/location/location_display.dart';
import 'package:wildgids/widgets/location/location_map_preview.dart';
import 'package:wildgids/screens/location/map_screen.dart';
import 'package:wildgids/widgets/location/custom_location_map_widget.dart';
import 'package:wildgids/screens/belonging/belonging_location_screen.dart';
import 'package:wildgids/widgets/location/time_selection_row.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class LocationScreenUIWidget extends StatefulWidget {
  const LocationScreenUIWidget({super.key});

  @override
  State<LocationScreenUIWidget> createState() => _LocationScreenUIWidgetState();
}

class _LocationScreenUIWidgetState extends State<LocationScreenUIWidget> {
  late final LocationServiceInterface _locationService;
  late final MapProvider _mapProvider;
  bool _useCurrentChecked = false;

  @override
  void initState() {
    super.initState();
    _locationService = LocationMapManager();
    _mapProvider = context.read<MapProvider>();
    _initializeMap();
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

  Future<void> _initializeMap() async {
    if (!mounted) return;

    // Reset state variables

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

  // Dropdown selection removed; interaction handled via map preview expand button

  // Navigation handled by LocationMapPreview expand button

  void _handleLocationIconTap() {
    debugPrint('Location icon tapped in LocationScreenUIWidget');
  }

  void _applyCurrentAsSelected() {
    final mp = context.read<MapProvider>();
    final pos = mp.currentPosition;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Huidige locatie nog niet beschikbaar')),
      );
      return;
    }
    mp.setSelectedLocation(pos, mp.currentAddress);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Huidige locatie geselecteerd')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      color: Colors.black,
                      fontFamily: 'Roboto',
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _useCurrentChecked = !_useCurrentChecked),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _useCurrentChecked,
                              onChanged: (v) => setState(() => _useCurrentChecked = v ?? false),
                            ),
                            const Text('Huidige locatie'),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_useCurrentChecked) {
                            _applyCurrentAsSelected();
                          } else {
                            final isFromPossession =
                                ModalRoute.of(context)?.settings.name ==
                                    'PossesionLocationScreen' ||
                                context
                                        .findAncestorWidgetOfExactType<
                                          BelongingLocationScreen
                                        >() !=
                                    null;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                settings: RouteSettings(
                                  name:
                                      isFromPossession
                                          ? 'PossesionCustomMap'
                                          : 'CustomMap',
                                ),
                                builder:
                                    (_) => MapScreen(
                                      title: 'Selecteer locatie',
                                      mapWidget: CustomLocationMapScreen(
                                        isFromPossession: isFromPossession,
                                      ),
                                    ),
                              ),
                            );
                          }
                        },
                        child: const Text('Selecteer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Bevestig uw huidige locatie of kies Selecteer voor de kaart',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontFamily: 'Roboto',
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(15),
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
                      color: Colors.black,
                      fontFamily: 'Roboto',
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
          ],
        ),
      ),
    );
  }
}


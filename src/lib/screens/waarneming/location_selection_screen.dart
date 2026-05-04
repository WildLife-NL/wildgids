import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/models/beta_models/location_model.dart';
import 'package:wildgids/models/enums/location_source.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/screens/waarneming/location_datetime_screen.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late fm.MapController _mapController;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  late final LocationMapManager _locationService;

  // Default center (Netherlands)
  static const LatLng defaultCenter = LatLng(52.0116, 5.8020);

  @override
  void initState() {
    super.initState();
    _mapController = fm.MapController();
    _locationService = LocationMapManager();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final Position? position = await _locationService.determinePosition();
      if (!mounted || position == null) return;
      final gpsPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = gpsPoint;
      });
      _mapController.move(gpsPoint, 15.0);
    } catch (_) {
      // Keep default center when GPS is unavailable.
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
        LocationDateTimeScreen(selectedLocation: _selectedLocation!),
      );
    }
  }

  void _handleBackNavigation() {
    debugPrint('[LocationSelectionScreen] Back button pressed');
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      final navigationManager = context.read<NavigationStateInterface>();
      navigationManager.resetToHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
          CustomAppBar(
            leftIcon: Icons.arrow_back_ios,
            centerText: 'Waarneming',
            rightIcon: null,
            showUserIcon: false,
            useFixedText: true,
            onLeftIconPressed: _handleBackNavigation,
            iconColor: Colors.black,
            textColor: Colors.black,
            fontScale: 1.4,
            iconScale: 1.15,
            userIconScale: 1.15,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 12, 0, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Identificeer locatie:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
              ),
            ),
          ),
          // Card container with map + instructions
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.75, // 75% of screen
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: const Color(0xFF999999),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Map area with rounded top corners
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            // Flutter Map
                            fm.FlutterMap(
                              mapController: _mapController,
                              options: fm.MapOptions(
                                initialCenter: defaultCenter,
                                initialZoom: 15.0,
                                interactionOptions: const fm.InteractionOptions(
                                  flags: fm.InteractiveFlag.pinchZoom |
                                      fm.InteractiveFlag.drag,
                                ),
                                onTap: (tapPosition, point) => _onMapTap(point),
                              ),
                              children: [
                                fm.TileLayer(
                                  urlTemplate: LocationMapManager.standardTileUrl,
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                  userAgentPackageName: 'com.wildgids.app',
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

                            // Crosshair button (bottom right)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: GestureDetector(
                                onTap: _centerOnCurrentLocation,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF333333),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Instruction text with top border (acts as bottom border for map)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.black.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Tik op de kaart om de locatie van\nde dierwarneming te bepalen.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Select button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedLocation != null ? _onSelectPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF37A904),
                    disabledBackgroundColor: const Color(0xFFEFEFEF),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFFACACAC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Selecteer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
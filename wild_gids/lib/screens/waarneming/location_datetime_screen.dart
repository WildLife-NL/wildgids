import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/screens/waarneming/animals_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';

class LocationDateTimeScreen extends StatefulWidget {
  final LatLng selectedLocation;

  const LocationDateTimeScreen({super.key, required this.selectedLocation});

  @override
  State<LocationDateTimeScreen> createState() => _LocationDateTimeScreenState();
}

class _LocationDateTimeScreenState extends State<LocationDateTimeScreen> {
  late fm.MapController _mapController;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _mapController = fm.MapController();
    _selectedDateTime = DateTime.now();
  }

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      final navigationManager = context.read<NavigationStateInterface>();
      navigationManager.resetToHome(context);
    }
  }

  Future<void> _pickDate() async {
    final DateTime initialDate = _selectedDateTime;
    final DateTime firstDate = DateTime(initialDate.year - 5);
    final DateTime lastDate = DateTime(initialDate.year + 5);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF37A904), // header background & selected
              onPrimary: Colors.white, // header/selected text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF37A904), // buttons
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay initialTime = TimeOfDay.fromDateTime(_selectedDateTime);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF37A904), // header background & selected
                onPrimary: Colors.white, // header/selected text color
                onSurface: Colors.black, // body text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF37A904), // buttons
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _onNextPressed() {
    final navigationManager = context.read<NavigationStateInterface>();
    final sightingManager = context.read<AnimalSightingReportingInterface>();

    // Save selected date/time into app state
    sightingManager.updateDateTime(_selectedDateTime);
    
    debugPrint(
      '[LocationDateTime] Next with location: ${widget.selectedLocation.latitude}, ${widget.selectedLocation.longitude} and datetime: $_selectedDateTime',
    );

    navigationManager.pushForward(
      context,
      const AnimalsScreen(appBarTitle: 'Selecteer Dier'),
    );
  }

  String _formatDate(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(1, '0');
    final String month = dateTime.month.toString().padLeft(1, '0');
    final String year = dateTime.year.toString();
    return '$day-$month-$year';
  }

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Same header as location selection
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
            const SizedBox(height: 8),

            // Main card container
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Waar en wanneer werd het\ndier gezien?',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Map snippet + selected location inside its own card
                        GestureDetector(
                          onTap: () {
                            // Go back to the location selection screen to change
                            Navigator.of(context).pop();
                          },
                          child: Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: Colors.black.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Map preview
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  child: SizedBox
                                     (
                                    height: 180,
                                    child: fm.FlutterMap(
                                      mapController: _mapController,
                                      options: fm.MapOptions(
                                        initialCenter: widget.selectedLocation,
                                        initialZoom: 16.0,
                                        interactionOptions:
                                            const fm.InteractionOptions(
                                          flags: fm.InteractiveFlag.pinchZoom |
                                              fm.InteractiveFlag.drag,
                                        ),
                                      ),
                                      children: [
                                        fm.TileLayer(
                                          urlTemplate:
                                              LocationMapManager.standardTileUrl,
                                          userAgentPackageName: 'com.wildgids.app',
                                        ),
                                        fm.MarkerLayer(
                                          markers: [
                                            fm.Marker(
                                              point: widget.selectedLocation,
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
                                  ),
                                ),

                                // Selected location row (placeholder address)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    border: Border(
                                      top: BorderSide(
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 20,
                                        color: Colors.black,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${widget.selectedLocation.latitude.toStringAsFixed(2)}, ${widget.selectedLocation.longitude.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          'Datum en Tijd:',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Datum',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 14,
                                              color: const Color(0xFF7A7A7A),
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDate(_selectedDateTime),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                          ),
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 20,
                                            color: Color(0xFF7A7A7A),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tijd',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 14,
                                              color: const Color(0xFF7A7A7A),
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTime(_selectedDateTime),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                          ),
                                          const Icon(
                                            Icons.access_time,
                                            size: 20,
                                            color: Color(0xFF7A7A7A),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom buttons
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: Color.fromARGB(59, 0, 0, 0),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Vorige',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF37A904),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Volgende',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

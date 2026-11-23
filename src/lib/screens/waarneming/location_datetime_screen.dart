import 'package:wildgids/widgets/reporting/report_layout.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';
import 'package:flutter/material.dart';
import 'package:wildgids/widgets/map/carto_attribution.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/screens/waarneming/animals_screen.dart';

class LocationDateTimeScreen extends StatefulWidget {
  final LatLng selectedLocation;
  final DateTime? initialDateTime;

  const LocationDateTimeScreen({
    super.key,
    required this.selectedLocation,
    this.initialDateTime,
  });

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
    _selectedDateTime = widget.initialDateTime ?? DateTime.now();
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
              primary: GuideStyle.ink, // header background & selected
              onPrimary: Colors.white, // header/selected text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: GuideStyle.ink, // buttons
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
                primary: GuideStyle.ink, // header background & selected
                onPrimary: Colors.white, // header/selected text color
                onSurface: Colors.black, // body text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: GuideStyle.ink, // buttons
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
  Widget build(BuildContext context) => ReportLayout(
    title: 'Wanneer was het?',
    stage: 'Datum en tijd',
    onBack: _handleBackNavigation,
    footer: ReportAction(label: 'Verder', onPressed: _onNextPressed),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 170,
            child: fm.FlutterMap(
              mapController: _mapController,
              options: fm.MapOptions(
                initialCenter: widget.selectedLocation,
                initialZoom: 16.0,
                interactionOptions: const fm.InteractionOptions(
                  flags: fm.InteractiveFlag.pinchZoom | fm.InteractiveFlag.drag,
                ),
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
                const CartoAttribution(),
              ],
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.edit_location_alt_outlined),
          label: const Text('Locatie aanpassen'),
          style: TextButton.styleFrom(foregroundColor: GuideStyle.ink),
        ),
        const SizedBox(height: 16),
        _momentField(
          'Datum',
          _formatDate(_selectedDateTime),
          Icons.calendar_today_outlined,
          _pickDate,
        ),
        const SizedBox(height: 12),
        _momentField(
          'Tijd',
          _formatTime(_selectedDateTime),
          Icons.schedule_outlined,
          _pickTime,
        ),
      ],
    ),
  );

  Widget _momentField(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) => Material(
    color: GuideStyle.surface,
    borderRadius: BorderRadius.circular(8),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      leading: Icon(icon, color: GuideStyle.ink),
      title: Text(
        label,
        style: const TextStyle(color: GuideStyle.muted, fontSize: 14),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: GuideStyle.ink,
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(
        Icons.edit_outlined,
        color: GuideStyle.ink,
        size: 20,
      ),
    ),
  );
}

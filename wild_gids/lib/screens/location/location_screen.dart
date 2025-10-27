import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgets/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:widgets/models/enums/location_source.dart';
import 'package:widgets/models/location_model.dart';
import 'package:widgets/screens/waarneming/animal_list_overview_screen.dart';
import 'package:widgets/widgets/shared_ui_widgets/app_bar.dart';
import 'package:widgets/widgets/shared_ui_widgets/bottom_app_bar.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _placeController = TextEditingController();

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  void _saveAndBackToOverview(BuildContext context) {
    final mgr = context.read<AnimalSightingReportingInterface>();

    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voer geldige coördinaten in')),
      );
      return;
    }

    mgr.updateLocation(
      LocationModel(
        latitude: lat,
        longitude: lon,
        placeName: _placeController.text.trim().isEmpty
            ? null
            : _placeController.text.trim(),
        source: LocationSource.manual,
      ),
    );

    // Store a timestamp as well
    mgr.updateDateTime(DateTime.now());

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AnimalListOverviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Locatie',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Voer de locatie in',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lonController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _placeController,
                      decoration: const InputDecoration(
                        labelText: 'Plaatsnaam (optioneel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onBackPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AnimalListOverviewScreen()),
        ),
        onNextPressed: () => _saveAndBackToOverview(context),
        showNextButton: true,
      ),
    );
  }
}

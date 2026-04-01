import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/providers/submitted_sightings_provider.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/screens/logbook/sighting_detail_screen.dart';
import 'package:wildgids/screens/shared/overzicht_screen.dart';

class RecentSightingsScreen extends StatelessWidget {
  const RecentSightingsScreen({super.key});

  void _handleBackNavigation(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OverzichtScreen()),
      (route) => false,
    );
  }

  String _getLocationDisplay(List? locations) {
    if (locations?.isEmpty != false) {
      return 'Locatie nog niet ingesteld';
    }
    final loc = locations!.first;
    if (loc.streetName != null && loc.houseNumber != null) {
      return '${loc.streetName} ${loc.houseNumber}, ${loc.cityName ?? ""}';
    } else if (loc.streetName != null) {
      return '${loc.streetName}, ${loc.cityName ?? ""}';
    } else if (loc.cityName != null) {
      return loc.cityName!;
    }
    if (loc.latitude != null && loc.longitude != null) {
      return '${loc.latitude?.toStringAsFixed(2)}, ${loc.longitude?.toStringAsFixed(2)}';
    }
    return 'Locatie nog niet ingesteld';
  }

  String _getDateTimeDisplay(dynamic dateTimeModel) {
    if (dateTimeModel == null) {
      return 'Datum en tijd nog niet ingesteld';
    }
    try {
      final dt = dateTimeModel.dateTime as DateTime?;
      if (dt == null) {
        return 'Datum en tijd nog niet ingesteld';
      }
      final date = '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$date | $time';
    } catch (e) {
      return 'Datum en tijd nog niet ingesteld';
    }
  }

  String _convertToPngPath(String? imagePath) {
    if (imagePath == null) {
      debugPrint('[RecentSightings._convertToPngPath] Input is null');
      return '';
    }
    if (imagePath.isEmpty) {
      debugPrint('[RecentSightings._convertToPngPath] Input is empty');
      return '';
    }
    // Convert 'assets/animals/wolf.png' to 'assets/animals/PNG/wolf.png'
    final converted = imagePath.replaceFirst('assets/animals/', 'assets/animals/PNG/');
    debugPrint('[RecentSightings._convertToPngPath] Converting: $imagePath -> $converted');
    return converted;
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
              centerText: 'Logboek',
              leftIcon: Icons.arrow_back_ios,
              rightIcon: null,
              showUserIcon: false,
              useFixedText: true,
              onLeftIconPressed: () => _handleBackNavigation(context),
              textColor: Colors.black,
              fontScale: 1.4,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            Expanded(
              child: Consumer<SubmittedSightingsProvider>(
                builder: (context, provider, _) {
                  if (provider.submittedSightings.isEmpty) {
                    return Center(
                      child: Text(
                        'Geen waarnemingen ingediend',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.submittedSightings.length,
                    itemBuilder: (context, index) {
                      final sighting = provider.submittedSightings[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SightingDetailScreen(sighting: sighting),
                              ),
                            );
                          },
                          child: SizedBox(
                            height: 220,
                            child: Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFF999999),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Image section
                                  _buildImageSection(_convertToPngPath(
                                      sighting.animals?.isNotEmpty == true
                                          ? sighting.animals!.first.animalImagePath
                                          : null)),
                                  const SizedBox(width: 12),
                                  // Details section
                                  _buildDetailsSection(sighting),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(String? imagePath) {
    debugPrint('[RecentSightings._buildImageSection] imagePath: $imagePath');
    
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: const Color(0xFFE0D9C9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        border: Border.all(
          color: Colors.grey[400] ?? Colors.grey,
          width: 2,
        ),
      ),
      child: (imagePath != null && imagePath.isNotEmpty)
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('[RecentSightings] Error loading image at $imagePath: $error');
                  return Icon(
                    Icons.pets,
                    size: 40,
                    color: Colors.grey[400],
                  );
                },
              ),
            )
          : Center(
              child: Icon(
                Icons.pets,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
    );
  }

  Widget _buildDetailsSection(dynamic sighting) {
    final animalName = sighting.animals?.isNotEmpty == true
        ? sighting.animals!.first.animalName
        : 'Dier';
    final animalImagePath = sighting.animals?.isNotEmpty == true
        ? sighting.animals!.first.animalImagePath
        : null;
    final aantal = sighting.animals?.length ?? 0;
    final location = _getLocationDisplay(sighting.locations);
    final dateTime = _getDateTimeDisplay(sighting.dateTime);

    debugPrint('[RecentSightings] ==== SIGHTING DETAILS ====');
    debugPrint('[RecentSightings] Animal name: $animalName');
    debugPrint('[RecentSightings] Original image path: $animalImagePath');
    debugPrint('[RecentSightings] Converted image path: ${_convertToPngPath(animalImagePath)}');
    debugPrint('[RecentSightings] Is path null: ${animalImagePath == null}');
    debugPrint('[RecentSightings] Is path empty: ${animalImagePath?.isEmpty ?? "N/A"}');
    debugPrint('[RecentSightings] ==== END SIGHTING ====');

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Waarneming',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              animalName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            _buildMetadataRow([
              ('Aantal', '$aantal'),
            ]),
            const SizedBox(height: 4),
            _buildMetadataRow([
              ('Datum', dateTime.split('|')[0].trim()),
              ('Tijd', dateTime.split('|').length > 1 ? dateTime.split('|')[1].trim() : ''),
            ]),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.location_on, location),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(List<(String, String)> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _buildDetailColumn(items[i].$1, items[i].$2),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 115, 115, 115)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 115, 115, 115),
            ),
          ),
        ),
      ],
    );
  }
}

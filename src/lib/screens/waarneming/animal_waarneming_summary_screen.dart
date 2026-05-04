import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/reporting/interaction_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/screens/location/location_screen.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/screens/shared/rapporteren.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/models/enums/animal_gender.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';

class AnimalWaarnemingSummaryScreen extends StatefulWidget {
  final int totalCount;

  const AnimalWaarnemingSummaryScreen({
    super.key,
    required this.totalCount,
  });

  @override
  State<AnimalWaarnemingSummaryScreen> createState() =>
      _AnimalWaarnemingSummaryScreenState();
}

class _AnimalWaarnemingSummaryScreenState
    extends State<AnimalWaarnemingSummaryScreen> {
  bool _isSubmitting = false;


  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    debugPrint('[AnimalWaarnemingSummaryScreen] _handleSubmit called');
    try {
      final sightingManager =
          context.read<AnimalSightingReportingInterface>();
      final interactionManager = context.read<InteractionInterface>();
      var sighting = sightingManager.getCurrentanimalSighting();

      debugPrint('[AnimalWaarnemingSummaryScreen] Submitting sighting: $sighting');

      if (sighting != null) {
        if (sighting.locations == null || sighting.locations!.isEmpty) {
          throw Exception('Geen locatie geselecteerd');
        }
        if (sighting.dateTime?.dateTime == null) {
          throw Exception('Geen datum/tijd geselecteerd');
        }

        // If animals list is empty (skipped details), populate with selected animal N times
        if ((sighting.animals?.isEmpty ?? true) && sighting.animalSelected != null && widget.totalCount > 0) {
          debugPrint('[AnimalWaarnemingSummaryScreen] Animals list was empty, populating with selected animal x${widget.totalCount}');
          final animalsToAdd = List<AnimalModel>.from(
            sighting.animals ?? [],
          );
          for (int i = 0; i < widget.totalCount; i++) {
            animalsToAdd.add(sighting.animalSelected!);
          }
          // Create a new sighting with the populated animals list
          sighting = sighting.copyWith(animals: animalsToAdd);
          sightingManager.updateCurrentanimalSighting(sighting);
        }

        // Make sure grouped/edited animal entries are synced before sending.
        sightingManager.syncObservedAnimalsToSighting();

        // Real submit to backend via the same interaction pipeline.
        final response = await submitReport(
          sightingManager,
          interactionManager,
          context,
        );
        if (response == null) {
          throw Exception(
            'Geen verbinding of verzenden mislukt. Controleer internet en probeer opnieuw.',
          );
        }

        // Clear the current sighting and navigate to logbook
        sightingManager.clearCurrentanimalSighting();
        debugPrint('[AnimalWaarnemingSummaryScreen] Navigating to logbook');
        if (!context.mounted) return;
        context.read<NavigationStateInterface>().pushAndRemoveUntil(
              context,
              const LogbookScreen(),
            );
      } else {
        debugPrint('[AnimalWaarnemingSummaryScreen] No sighting found to submit');
      }
    } catch (e, stackTrace) {
      debugPrint('[AnimalWaarnemingSummaryScreen] Error submitting: $e');
      debugPrint('[AnimalWaarnemingSummaryScreen] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Versturen mislukt: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleExit() {
    final sightingManager =
        context.read<AnimalSightingReportingInterface>();
    sightingManager.clearCurrentanimalSighting();
    context.read<NavigationStateInterface>().pushAndRemoveUntil(
          context,
          const Rapporteren(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final sightingManager =
        context.read<AnimalSightingReportingInterface>();
    final sighting = sightingManager.getCurrentanimalSighting();
    final selectedAnimal = sighting?.animalSelected;
    
    const appBarTitle = 'Waarneming';

    if (selectedAnimal == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6F4),
        body: const Center(
          child: Text('No animal selected'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Bar
            CustomAppBar(
              centerText: appBarTitle,
              rightIcon: Icons.exit_to_app_rounded,
              onRightIconPressed: _handleExit,
              showUserIcon: false,
              useFixedText: true,
              textColor: Colors.black,
              iconColor: Colors.grey,
              fontScale: 1.4,
              iconScale: 0.85,
              userIconScale: 1.15,
            ),
            // Main card container
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
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
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Heading
                          const Text(
                            'Overzicht',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Animal info card (compact)
                          Center(
                            child: SizedBox(
                              width: 140,
                              child: Card(
                                shadowColor: const Color.fromARGB(133, 0, 0, 0)
                                    .withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: const Color(0xFF999999),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Image area
                                    Center(
                                      child: SizedBox(
                                        width: 140,
                                        height: 120,
                                        child: AspectRatio(
                                          aspectRatio: 1.0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(14),
                                                topRight: Radius.circular(14),
                                              ),
                                              color: Colors.white,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(14),
                                                topRight: Radius.circular(14),
                                              ),
                                              child: SizedBox.expand(
                                                child: selectedAnimal
                                                            .animalImagePath !=
                                                        null
                                                    ? Image(
                                                        image: AssetImage(
                                                          selectedAnimal
                                                              .animalImagePath!,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Center(
                                                        child: Icon(
                                                          Icons
                                                              .image_not_supported_outlined,
                                                          size: 50,
                                                          color:
                                                              Colors.grey[400],
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Divider line
                                    Container(
                                      height: 1,
                                      color: const Color(0xFF999999),
                                      width: 140,
                                    ),
                                    // Name area
                                    Container(
                                      width: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(14),
                                          bottomRight: Radius.circular(14),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        selectedAnimal.animalName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Total aantal
                          Text(
                            'Aantal: ${widget.totalCount}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Individual animal details
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFFE8E8E8),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ..._buildAnimalDetailsList(sighting?.animals ?? []),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Location and DateTime info
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFFE8E8E8),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Location
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F0F0),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.location_on, size: 18, color: Colors.grey[700]),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Locatie',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _getLocationDisplay(sighting?.locations),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Divider(
                                    color: Colors.grey.withValues(alpha: 0.15),
                                    height: 1,
                                    thickness: 1,
                                  ),
                                  const SizedBox(height: 14),
                                  // Date/Time
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F0F0),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Datum & Tijd',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _getDateTimeDisplay(sighting?.dateTime),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
                            color: Color(0xFF999999),
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
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF37A904),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _isSubmitting ? 'Bezig met versturen...' : 'Versturen',
                          style: const TextStyle(
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
      bottomNavigationBar: SizedBox.shrink(),
    );
  }

List<Widget> _buildAnimalDetailsList(List animals) {
    final details = <Widget>[];
    
    if (animals.isEmpty) {
      return [
        const Center(
          child: Text(
            'Geen dier details beschikbaar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ];
    }

    int animalIndex = 1;
    int totalAnimals = 0;
    
    // First count total animals
    for (final animal in animals) {
      if (animal?.genderViewCounts == null || animal.genderViewCounts.isEmpty) {
        continue;
      }
      totalAnimals += (animal.genderViewCounts.length as int);
    }
    
    int currentAnimalCount = 0;
    
    // Loop through each animal in the list
    for (final animal in animals) {
      if (animal?.genderViewCounts == null || animal.genderViewCounts.isEmpty) {
        continue;
      }

      // Loop through each gender/age combination for this animal
      for (final genderViewCount in animal.genderViewCounts) {
        final gender = _getGenderDisplay(genderViewCount.gender);
        final viewCount = genderViewCount.viewCount;
        
        // Determine the age
        String age = 'Onbekend';
        if (viewCount.pasGeborenAmount > 0) {
          age = 'Pas geboren';
        } else if (viewCount.onvolwassenAmount > 0) {
          age = 'Jong';
        } else if (viewCount.volwassenAmount > 0) {
          age = 'Volwassen';
        }

        // Add a detail item with icon box
        details.add(
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pets, size: 18, color: Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dier $animalIndex',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$gender, $age',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        
        currentAnimalCount++;
        
        // Add divider between animals (but not after the last one)
        if (currentAnimalCount < totalAnimals) {
          details.add(const SizedBox(height: 14));
          details.add(
            Divider(
              color: Colors.grey.withValues(alpha: 0.15),
              height: 1,
              thickness: 1,
            ),
          );
          details.add(const SizedBox(height: 14));
        }
        
        animalIndex++;
      }
    }

    if (details.isEmpty) {
      return [
        const Center(
          child: Text(
            'Geen dier details beschikbaar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ];
    }

    return details;
  }

  String _getGenderDisplay(AnimalGender gender) {
    switch (gender) {
      case AnimalGender.mannelijk:
        return 'Mannelijk';
      case AnimalGender.vrouwelijk:
        return 'Vrouwelijk';
      case AnimalGender.onbekend:
        return 'Onbekend';
    }
  }

  String _getLocationDisplay(List? locations) {
    if (locations?.isEmpty != false) {
      return 'Locatie nog niet ingesteld';
    }
    final loc = locations!.first;
    // Try to show address if available
    if (loc.streetName != null && loc.houseNumber != null) {
      return '${loc.streetName} ${loc.houseNumber}, ${loc.cityName ?? ""}';
    } else if (loc.streetName != null) {
      return '${loc.streetName}, ${loc.cityName ?? ""}';
    } else if (loc.cityName != null) {
      return loc.cityName!;
    }
    // Fall back to showing coordinates in a readable format
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
      // Format: DD-MM-YYYY | HH:MM
      final date = '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$date | $time';
    } catch (e) {
      return 'Datum en tijd nog niet ingesteld';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/reporting/interaction_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/screens/location/location_screen.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/models/enums/animal_gender.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildgids/models/animal_waarneming_models/view_count_model.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';
import 'package:wildgids/providers/submitted_sightings_provider.dart';
import 'package:wildgids/utils/api_datetime.dart';
import 'package:wildgids/utils/species_image_resolver.dart';

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
          final placeholder = AnimalModel(
            animalId: sighting.animalSelected!.animalId,
            animalImagePath: sighting.animalSelected!.animalImagePath,
            animalName: sighting.animalSelected!.animalName,
            category: sighting.animalSelected!.category,
            condition: sighting.animalSelected!.condition,
            genderViewCounts: [
              AnimalGenderViewCount(
                gender: AnimalGender.onbekend,
                viewCount: ViewCountModel(unknownAmount: 1),
              ),
            ],
          );
          for (int i = 0; i < widget.totalCount; i++) {
            animalsToAdd.add(placeholder);
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
        if (!mounted) return;
        if (response == null) {
          throw Exception(
            'Geen verbinding of verzenden mislukt. Controleer internet en probeer opnieuw.',
          );
        }

        final submittedProvider = context.read<SubmittedSightingsProvider>();
        submittedProvider.addSighting(sighting);

        // Clear the current sighting and navigate to logbook
        sightingManager.clearCurrentanimalSighting();
        debugPrint('[AnimalWaarnemingSummaryScreen] Navigating to logbook');
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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const WaarnemmingStartScreen(),
      ),
      (route) => false,
    );
  }

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sightingManager =
        context.read<AnimalSightingReportingInterface>();
    final sighting = sightingManager.getCurrentanimalSighting();
    final selectedAnimal = sighting?.animalSelected;
    final selectedAnimalImagePath =
        SpeciesImageResolver.drawingForCommonName(selectedAnimal?.animalName) ??
        selectedAnimal?.animalImagePath;

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
              centerText: 'Waarneming',
              rightIcon: null,
              showUserIcon: false,
              useFixedText: true,
              onLeftIconPressed: _handleBackNavigation,
              textColor: Colors.black,
              fontScale: 1.4,
              iconScale: 1.15,
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
                                                child: selectedAnimalImagePath !=
                                                        null
                                                    ? Image(
                                                        image: AssetImage(
                                                          selectedAnimalImagePath,
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                          const SizedBox(height: 12),
                          // Divider line
                          Container(
                            height: 1,
                            color: const Color(0xFF999999),
                          ),
                          const SizedBox(height: 16),
                          // Individual animal details
                          ..._buildAnimalDetailsList(sighting?.animals ?? []),
                          const SizedBox(height: 16),
                          // Divider line
                          Container(
                            height: 1,
                            color: const Color(0xFF999999),
                          ),
                          const SizedBox(height: 16),
                          // Location and DateTime info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Location
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Locatie:',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _getLocationDisplay(sighting?.locations),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Date/Time
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Datum & Tijd:',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _getDateTimeDisplay(sighting?.dateTime),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                        onPressed: _handleExit,
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
                          'Begin Opnieuw',
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
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF37A904),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Versturen',
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
    // Loop through each animal in the list
    for (final animal in animals) {
      if (animal?.genderViewCounts == null || animal.genderViewCounts.isEmpty) {
        details.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    'Dier:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Onbekend, Onbekend',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        );
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

        // Add a detail row for this animal
        details.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Dier $animalIndex:',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '$gender, $age',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        
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
      return ApiDateTime.formatSummary(dt);
    } catch (e) {
      return 'Datum en tijd nog niet ingesteld';
    }
  }
}

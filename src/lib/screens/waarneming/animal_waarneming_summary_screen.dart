import 'package:wildgids/models/enums/animal_count_mode.dart';
import 'package:wildgids/widgets/reporting/report_layout.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/reporting/interaction_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/constants/sighting_report_activities.dart';
import 'package:wildgids/screens/location/location_screen.dart';
import 'package:wildgids/utils/sighting_submit_navigation.dart';
import 'package:wildgids/screens/waarneming/walk_sighting_flow.dart';
import 'package:wildgids/models/enums/animal_gender.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildgids/models/animal_waarneming_models/view_count_model.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';
import 'package:wildgids/providers/submitted_sightings_provider.dart';
import 'package:wildgids/utils/api_datetime.dart';

class AnimalWaarnemingSummaryScreen extends StatefulWidget {
  final int totalCount;

  const AnimalWaarnemingSummaryScreen({super.key, required this.totalCount});

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
      final sightingManager = context.read<AnimalSightingReportingInterface>();
      final interactionManager = context.read<InteractionInterface>();
      var sighting = sightingManager.getCurrentanimalSighting();

      debugPrint(
        '[AnimalWaarnemingSummaryScreen] Submitting sighting: $sighting',
      );

      if (sighting != null) {
        if (sighting.locations == null || sighting.locations!.isEmpty) {
          throw Exception('Geen locatie geselecteerd');
        }
        if (sighting.dateTime?.dateTime == null) {
          throw Exception('Geen datum/tijd geselecteerd');
        }

        // If animals list is empty (skipped details), populate with selected animal N times
        if (sighting.countMode == AnimalCountMode.exact &&
            (sighting.animals?.isEmpty ?? true) &&
            sighting.animalSelected != null &&
            widget.totalCount > 0) {
          debugPrint(
            '[AnimalWaarnemingSummaryScreen] Animals list was empty, populating with selected animal x${widget.totalCount}',
          );
          final animalsToAdd = List<AnimalModel>.from(sighting.animals ?? []);
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Je waarneming is op dit apparaat opgeslagen. '
                'Probeer opnieuw zodra je verbinding hebt.',
              ),
            ),
          );
          return;
        }

        final submittedProvider = context.read<SubmittedSightingsProvider>();
        submittedProvider.addSighting(sighting);

        sightingManager.clearCurrentanimalSighting();
        debugPrint(
          '[AnimalWaarnemingSummaryScreen] Submit OK — '
          'questionnaire: ${response.questionnaire.questions?.length ?? 0} questions',
        );
        navigateAfterSightingSubmit(context, response);
      } else {
        debugPrint(
          '[AnimalWaarnemingSummaryScreen] No sighting found to submit',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[AnimalWaarnemingSummaryScreen] Error submitting: $e');
      debugPrint('[AnimalWaarnemingSummaryScreen] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Versturen mislukt: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleExit() {
    final walkSession = context.read<WalkSightingSession?>();
    if (walkSession != null) {
      walkSession.close();
      return;
    }
    final sightingManager = context.read<AnimalSightingReportingInterface>();
    sightingManager.clearCurrentanimalSighting();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WaarnemmingStartScreen()),
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
    final sighting =
        context
            .read<AnimalSightingReportingInterface>()
            .getCurrentanimalSighting();
    final animal = sighting?.animalSelected;
    return ReportLayout(
      title: 'Klopt alles?',
      stage: 'Controle',
      onBack: _handleBackNavigation,
      footer:
          animal == null
              ? null
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReportAction(
                    label: 'Verstuur waarneming',
                    busy: _isSubmitting,
                    onPressed: _isSubmitting ? null : _handleSubmit,
                  ),
                  TextButton(
                    onPressed: _isSubmitting ? null : _handleExit,
                    style: TextButton.styleFrom(
                      foregroundColor: GuideStyle.muted,
                    ),
                    child: const Text('Begin opnieuw'),
                  ),
                ],
              ),
      child:
          animal == null
              ? const Text('Geen dier geselecteerd.')
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReportAnimal(animal: animal, height: 160),
                  const SizedBox(height: 12),
                  Center(
                    child: Chip(
                      backgroundColor: GuideStyle.surface,
                      side: BorderSide.none,
                      avatar: const Icon(
                        Icons.pets_outlined,
                        size: 18,
                        color: GuideStyle.ink,
                      ),
                      label: Text(
                        (sighting?.countMode ?? AnimalCountMode.exact).summary(
                          sighting?.animalCount ?? widget.totalCount,
                        ),
                        style: const TextStyle(
                          color: GuideStyle.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ReportSurface(
                    child: Column(
                      children: [
                        _summaryRow(
                          'Locatie',
                          _getLocationDisplay(sighting?.locations),
                        ),
                        const Divider(height: 28, color: GuideStyle.border),
                        _summaryRow(
                          'Datum en tijd',
                          _getDateTimeDisplay(sighting?.dateTime),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ReportSurface(child: _buildActivitySection(sighting)),
                  if (sighting?.animals?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 14),
                    ReportSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildAnimalDetailsList(sighting!.animals!),
                      ),
                    ),
                  ],
                ],
              ),
    );
  }

  Widget _buildActivitySection(dynamic sighting) {
    final human = _humanActivityDisplay(
      sighting?.humanActivity,
      sighting?.humanActivityOther,
    );
    final animal = _perceivedAnimalActivityDisplay(
      sighting?.perceivedAnimalActivity,
      sighting?.perceivedAnimalActivityOther,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activiteit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _summaryRow('Wat deed jij?', human),
        const SizedBox(height: 8),
        _summaryRow('Wat deed het dier?', animal),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
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
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  String _humanActivityDisplay(String? apiValue, String? other) {
    if (apiValue == null || apiValue.isEmpty) {
      return 'Niet ingevuld';
    }
    final label = SightingReportActivityCatalog.labelNlForHuman(apiValue);
    if (SightingReportActivityCatalog.isOtherHuman(apiValue) &&
        other != null &&
        other.trim().isNotEmpty) {
      return '$label $other';
    }
    return label;
  }

  String _perceivedAnimalActivityDisplay(String? apiValue, String? other) {
    if (apiValue == null || apiValue.isEmpty) {
      return 'Niet ingevuld';
    }
    final label = SightingReportActivityCatalog.labelNlForPerceivedAnimal(
      apiValue,
    );
    if (SightingReportActivityCatalog.isOtherPerceivedAnimal(apiValue) &&
        other != null &&
        other.trim().isNotEmpty) {
      return '$label $other';
    }
    return label;
  }

  List<Widget> _buildAnimalDetailsList(List animals) {
    final details = <Widget>[];

    if (animals.isEmpty) {
      return [
        const Center(
          child: Text(
            'Geen dier details beschikbaar',
            style: TextStyle(fontSize: 14, color: Colors.grey),
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
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
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
            style: TextStyle(fontSize: 14, color: Colors.grey),
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

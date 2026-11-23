import 'package:wildgids/widgets/reporting/report_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/models/enums/animal_age.dart';
import 'package:wildgids/models/enums/animal_gender.dart';
import 'package:wildgids/models/enums/animal_condition.dart';
import 'package:wildgids/models/animal_waarneming_models/view_count_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildgids/screens/waarneming/animal_waarneming_summary_screen.dart';

class AnimalWaarnemingDetailsScreen extends StatefulWidget {
  final int animalIndex; // 0-based index (0 = Dier 1, 1 = Dier 2, etc)
  final int totalCount; // Total number of animals

  const AnimalWaarnemingDetailsScreen({
    super.key,
    required this.animalIndex,
    required this.totalCount,
  });

  @override
  State<AnimalWaarnemingDetailsScreen> createState() =>
      _AnimalWaarnemingDetailsScreenState();
}

class _AnimalWaarnemingDetailsScreenState
    extends State<AnimalWaarnemingDetailsScreen> {
  AnimalAge selectedAge = AnimalAge.onbekend;
  AnimalGender selectedGender = AnimalGender.onbekend;
  AnimalCondition? selectedCondition;
  late TextEditingController otherConditionController;

  void _handleBackNavigation() {
    if (widget.animalIndex > 0) {
      // Go to previous animal details
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AnimalWaarnemingDetailsScreen(
                animalIndex: widget.animalIndex - 1,
                totalCount: widget.totalCount,
              ),
        ),
      );
    } else {
      // Go back to animal_aantal_screen
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
    }
  }

  void _handleNext() {
    // Save the current animal's details before moving on
    final sightingManager = context.read<AnimalSightingReportingInterface>();
    final sighting = sightingManager.getCurrentanimalSighting();
    final currentAnimal = sighting?.animalSelected;

    if (currentAnimal == null) return;

    // Create a ViewCountModel with the selected age
    final viewCount = ViewCountModel();
    if (selectedAge == AnimalAge.pasGeboren) {
      viewCount.pasGeborenAmount = 1;
    } else if (selectedAge == AnimalAge.onvolwassen) {
      viewCount.onvolwassenAmount = 1;
    } else if (selectedAge == AnimalAge.volwassen) {
      viewCount.volwassenAmount = 1;
    } else {
      viewCount.unknownAmount = 1;
    }

    // Create the complete AnimalGenderViewCount with both gender and age
    final genderViewCount = AnimalGenderViewCount(
      gender: selectedGender,
      viewCount: viewCount,
    );

    // Update selectedAnimal with this complete gender/age data
    final updatedAnimal = AnimalModel(
      animalId: currentAnimal.animalId,
      animalImagePath: currentAnimal.animalImagePath,
      animalName: currentAnimal.animalName,
      category: currentAnimal.category,
      genderViewCounts: [genderViewCount],
      condition: selectedCondition,
      conditionDetail:
          selectedCondition == AnimalCondition.andere &&
                  otherConditionController.text.isNotEmpty
              ? otherConditionController.text
              : null,
    );

    sightingManager.updateSelectedAnimal(updatedAnimal);

    // Finalize/save this animal to the animals list, but keep it selected for the next iteration
    sightingManager.finalizeAnimal(clearSelected: false);

    // Reset the selected animal to have empty genderViewCounts for the next animal
    final freshAnimal = AnimalModel(
      animalId: currentAnimal.animalId,
      animalImagePath: currentAnimal.animalImagePath,
      animalName: currentAnimal.animalName,
      category: currentAnimal.category,
      genderViewCounts: [],
      condition: null,
      conditionDetail: null,
    );
    sightingManager.updateSelectedAnimal(freshAnimal);

    if (widget.animalIndex < widget.totalCount - 1) {
      // Reset state for next animal
      setState(() {
        selectedAge = AnimalAge.onbekend;
        selectedGender = AnimalGender.onbekend;
        selectedCondition = null;
        otherConditionController.text = '';
      });

      // Go to next animal details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AnimalWaarnemingDetailsScreen(
                animalIndex: widget.animalIndex + 1,
                totalCount: widget.totalCount,
              ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  AnimalWaarnemingSummaryScreen(totalCount: widget.totalCount),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    otherConditionController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sightingManager = context.read<AnimalSightingReportingInterface>();
    final sighting = sightingManager.getCurrentanimalSighting();
    final current = sighting?.animalSelected;
    if (current != null) {
      selectedCondition = current.condition;
      if (current.conditionDetail != null) {
        otherConditionController.text = current.conditionDetail!;
      }

      final viewCount = current.viewCount;
      if (viewCount != null) {
        selectedAge = viewCount.getAge();
      }
      final gender = current.gender;
      if (gender != null) selectedGender = gender;
    }
  }

  @override
  void dispose() {
    otherConditionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animal =
        context
            .read<AnimalSightingReportingInterface>()
            .getCurrentanimalSighting()
            ?.animalSelected;
    return ReportLayout(
      title: 'Dier ${widget.animalIndex + 1} van ${widget.totalCount}',
      stage: 'Details',
      onBack: _handleBackNavigation,
      footer:
          animal == null
              ? null
              : ReportAction(
                label:
                    widget.animalIndex < widget.totalCount - 1
                        ? 'Volgend dier'
                        : 'Controleer waarneming',
                onPressed: _handleNext,
              ),
      child:
          animal == null
              ? const Text('Kies eerst een dier.')
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReportAnimal(animal: animal, height: 130),
                  const SizedBox(height: 24),
                  ReportChoices<AnimalAge>(
                    label: 'Leeftijd',
                    values: const [
                      AnimalAge.onbekend,
                      AnimalAge.pasGeboren,
                      AnimalAge.onvolwassen,
                      AnimalAge.volwassen,
                    ],
                    selected: selectedAge,
                    labelFor: _getEnumLabel,
                    onSelected: (value) => setState(() => selectedAge = value),
                  ),
                  const SizedBox(height: 24),
                  ReportChoices<AnimalGender>(
                    label: 'Geslacht',
                    values: const [
                      AnimalGender.onbekend,
                      AnimalGender.mannelijk,
                      AnimalGender.vrouwelijk,
                    ],
                    selected: selectedGender,
                    labelFor: _getEnumLabel,
                    onSelected:
                        (value) => setState(() => selectedGender = value),
                  ),
                  const SizedBox(height: 24),
                  ReportChoices<AnimalCondition>(
                    label: 'Gezondheid',
                    values: const [
                      AnimalCondition.gezond,
                      AnimalCondition.ziek,
                      AnimalCondition.dood,
                      AnimalCondition.andere,
                    ],
                    selected: selectedCondition,
                    labelFor: _getEnumLabel,
                    onSelected:
                        (value) => setState(() => selectedCondition = value),
                  ),
                  if (selectedCondition == AnimalCondition.andere) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: otherConditionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Toelichting',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
    );
  }

  String _getEnumLabel(dynamic value) {
    if (value is AnimalAge) {
      switch (value) {
        case AnimalAge.pasGeboren:
          return 'Pas geboren';
        case AnimalAge.onvolwassen:
          return 'Onvolwassen';
        case AnimalAge.volwassen:
          return 'Volwassen';
        case AnimalAge.onbekend:
          return 'Onbekend';
      }
    } else if (value is AnimalGender) {
      switch (value) {
        case AnimalGender.mannelijk:
          return 'Mannelijk';
        case AnimalGender.vrouwelijk:
          return 'Vrouwelijk';
        case AnimalGender.onbekend:
          return 'Onbekend';
      }
    } else if (value is AnimalCondition) {
      switch (value) {
        case AnimalCondition.gezond:
          return 'Gezond';
        case AnimalCondition.ziek:
          return 'Gewond/Ziek';
        case AnimalCondition.dood:
          return 'Dood';
        case AnimalCondition.andere:
          return 'Anders';
        case AnimalCondition.levend:
          return 'Levend';
      }
    }
    return 'Onbekend';
  }
}

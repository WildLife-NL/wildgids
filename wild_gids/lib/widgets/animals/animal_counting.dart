import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildrapport/models/enums/animal_age.dart';
import 'package:wildrapport/models/enums/animal_age_extensions.dart';
import 'package:wildrapport/models/enums/animal_gender.dart';
import 'package:wildrapport/models/animal_waarneming_models/view_count_model.dart';
import 'package:wildrapport/widgets/animals/counter_widget.dart';
import 'package:wildrapport/widgets/overlay/error_overlay.dart';
import 'package:wildrapport/widgets/toasts/snack_bar_with_progress.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/white_bulk_button.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/models/animal_waarneming_models/observed_animal_entry.dart';
import 'package:wildrapport/models/enums/animal_condition.dart';


class AnimalCounting extends StatefulWidget {
  final Function(String)? onAgeSelected;
  final VoidCallback? onAddToList;

  const AnimalCounting({super.key, this.onAgeSelected, this.onAddToList});

  @override
  State<AnimalCounting> createState() => _AnimalCountingState();
}

class _AnimalCountingState extends State<AnimalCounting> {
  String? selectedAge;
  String? selectedGender;
  String? lastSelectedGender; // Add this to remember the last gender
  int currentCount = 0;
  bool _forceRebuild = false;
  final GlobalKey<AnimalCounterState> _counterKey =
      GlobalKey<AnimalCounterState>();

  AnimalAge _convertStringToAnimalAge(String ageString) {
    return AnimalAgeExtensions.fromApiString(ageString);
  }

  AnimalGender _convertStringToAnimalGender(String genderString) {
    switch (genderString) {
      case "Mannelijk":
        return AnimalGender.mannelijk;
      case "Vrouwelijk":
        return AnimalGender.vrouwelijk;
      case "Onbekend":
      default:
        return AnimalGender.onbekend;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void _handleCountChanged(String name, int count) {
    setState(() {
      currentCount = count;
    });
  }

void _validateAndAddToList(BuildContext context) {
  // 1. Validate input first
  List<String> errors = [];

  if (selectedAge == null) {
    errors.add('Selecteer een leeftijd');
  }

  if (selectedGender == null) {
    errors.add('Selecteer een geslacht');
  }

  if (currentCount <= 0) {
    errors.add('Voer een aantal groter dan 0 in');
  }

  if (errors.isNotEmpty) {
    showDialog(
      context: context,
      builder: (context) => ErrorOverlay(messages: errors),
    );
    return;
  }

  // 2. Get the manager + current sighting
  final mgr = context.read<AnimalSightingReportingInterface>();
  final sighting = mgr.getCurrentanimalSighting();
  final currentAnimal = sighting?.animalSelected;

  if (currentAnimal == null) {
    // nothing selected? just bail
    return;
  }

  // 3. Convert UI strings -> enums
  final AnimalAge ageEnum = _convertStringToAnimalAge(selectedAge!);
  final AnimalGender genderEnum = _convertStringToAnimalGender(selectedGender!);

  // We don't let the user pick condition yet in this screen,
  // so fallback to whatever is on the selected animal,
  // or just "other".
  final AnimalCondition conditionEnum =
      currentAnimal.condition ?? AnimalCondition.andere;

  // 4. Build one batch entry for the chosen combo
  final entry = ObservedAnimalEntry(
    age: ageEnum,
    gender: genderEnum,
    condition: conditionEnum,
    count: currentCount,
  );

  // 5. Save it in the manager
  mgr.addObservedAnimal(entry);

  // 6. Sync into the legacy AnimalSightingModel.animals
  // so later screens + API transformer can still read it
  mgr.syncObservedAnimalsToSighting();

  // 7. Reset local UI so user can add another batch
  setState(() {
    // Remember last gender if you still want that UX
    lastSelectedGender = selectedGender;

    selectedAge = null;
    selectedGender = null;
    currentCount = 0;

    // force rebuild trick stays if you still need it
    _forceRebuild = !_forceRebuild;
  });

  // reset the counter widget visually
  (_counterKey.currentState as AnimalCounterState).reset();

  // 8. Tell parent screen "we added something"
  widget.onAddToList?.call();

  // 9. Show success toast/snack
  SnackBarWithProgress.show(
    context: context,
    message: 'Dier toegevoegd aan de lijst',
  );
}


  void _handleAgeSelection(String age) {
    setState(() {
      if (selectedAge == age) {
        selectedAge = null;
      } else {
        selectedAge = age;
      }
    });
  }

  void _handleGenderSelection(String gender) {
    setState(() {
      if (selectedGender == gender) {
        selectedGender = null;
        // Don't update lastSelectedGender when deselecting
      } else {
        selectedGender = gender;
        lastSelectedGender = gender; // Remember this gender
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the animal sighting manager
    context.watch<AnimalSightingReportingInterface>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    constraints.maxHeight -
                    MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top section with age/gender buttons that can change
                  SizedBox(
                    height: 300, // Fixed height for the top section
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize:
                                    MainAxisSize.min, // Keep this as min
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .stretch, // Ensure buttons stretch
                                children: [
                                  _buildHeader('Leeftijd'),
                                  // Filter out null widgets and add spacing only between non-null widgets
                                  ..._buildAgeButtonsWithSpacing(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisSize:
                                    MainAxisSize.min, // Keep this as min
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .stretch, // Ensure buttons stretch
                                children: [
                                  _buildHeader('Geslacht'),
                                  // Filter out null widgets and add spacing only between non-null widgets
                                  ..._buildGenderButtonsWithSpacing(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Add extra space here to move the Aantal section lower
                  const SizedBox(height: 30),
                  // Fixed position "Aantal" section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        _buildHeader('Aantal'),
                        const SizedBox(height: 8),
                        AnimalCounter(
                          key: _counterKey,
                          name: "Example",
                          height: 49,
                          onCountChanged: _handleCountChanged,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 350,
                          child: WhiteBulkButton(
                            text: "Voeg toe aan de lijst",
                            showIcon: false,
                            height: 85,
                            onPressed: () => _validateAndAddToList(context),
                          ),
                        ),
                        // Add extra padding at the bottom to ensure the button is visible
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.brown,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeButton(String text) {
    final bool isSelected = text == selectedAge;

    return SizedBox(
      height: 64.5, // Same height as the button
      child: WhiteBulkButton(
        text: text,
        height: 64.5,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        textAlign: TextAlign.center,
        showIcon: false,
        backgroundColor: isSelected ? AppColors.lightGreen : null,
        onPressed: () => _handleAgeSelection(text),
      ),
    );
  }

  Widget _buildGenderButton(String text) {
    final bool isSelected = text == selectedGender;

    return SizedBox(
      height: 64.5, // Same height as the button
      child: WhiteBulkButton(
        text: text,
        height: 64.5,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        textAlign: TextAlign.center,
        showIcon: false,
        backgroundColor: isSelected ? AppColors.lightGreen : null,
        onPressed: () => _handleGenderSelection(text),
      ),
    );
  }

  bool _isAgeAlreadyAdded(String genderText, String ageText) {
    final manager = context.read<AnimalSightingReportingInterface>();
    final sighting = manager.getCurrentanimalSighting();
    final selectedGender = _convertStringToAnimalGender(genderText);
    final selectedAge = _convertStringToAnimalAge(ageText);

    // Check in the animals list
    final animals = sighting?.animals;
    if (animals == null || animals.isEmpty) {
      debugPrint('_isAgeAlreadyAdded: No animals in list');
      return false;
    }

    // Check all animals in the list
    for (final animal in animals) {
      // Find the gender view count for the selected gender
      final genderVC = animal.genderViewCounts.firstWhere(
        (gvc) => gvc.gender == selectedGender,
        orElse:
            () => AnimalGenderViewCount(
              gender: selectedGender,
              viewCount: ViewCountModel(),
            ),
      );

      // Check if this age is already added for this gender
      bool hasCount = false;
      switch (selectedAge) {
        case AnimalAge.pasGeboren:
          hasCount = (genderVC.viewCount.pasGeborenAmount > 0);
          break;
        case AnimalAge.onvolwassen:
          hasCount = (genderVC.viewCount.onvolwassenAmount > 0);
          break;
        case AnimalAge.volwassen:
          hasCount = (genderVC.viewCount.volwassenAmount > 0);
          break;
        case AnimalAge.onbekend:
          hasCount = (genderVC.viewCount.unknownAmount > 0);
          break;
      }

      if (hasCount) {
        debugPrint(
          '_isAgeAlreadyAdded: Found count for gender=$genderText, age=$ageText',
        );
        return true;
      }
    }

    debugPrint(
      '_isAgeAlreadyAdded: No count found for gender=$genderText, age=$ageText',
    );
    return false;
  }

  bool _areAllAgesFilledForGender(String genderText) {
    final manager = context.read<AnimalSightingReportingInterface>();
    final sighting = manager.getCurrentanimalSighting();
    final selectedGender = _convertStringToAnimalGender(genderText);

    final genderVC = sighting?.animalSelected?.genderViewCounts.firstWhere(
      (gvc) => gvc.gender == selectedGender,
      orElse:
          () => AnimalGenderViewCount(
            gender: selectedGender,
            viewCount: ViewCountModel(),
          ),
    );

    if (genderVC == null) return false;

    return (genderVC.viewCount.pasGeborenAmount > 0) &&
        (genderVC.viewCount.onvolwassenAmount > 0) &&
        (genderVC.viewCount.volwassenAmount > 0) &&
        (genderVC.viewCount.unknownAmount > 0);
  }

  List<Widget> _buildAgeButtonsWithSpacing() {
    final List<Widget> result = [];
    final ageOptions = [
      AnimalAge.pasGeboren.label,
      AnimalAge.onvolwassen.label,
      AnimalAge.volwassen.label,
      AnimalAge.onbekend.label,
    ];

    // Count visible and hidden buttons
    int visibleCount = 0;

    // Add visible buttons with spacing
    for (int i = 0; i < ageOptions.length; i++) {
      // Check if this age is already added for the selected gender
      bool disable = false;
      if (selectedGender != null) {
        disable = _isAgeAlreadyAdded(selectedGender!, ageOptions[i]);
      } else {
        disable =
            _isAgeAlreadyAdded("Mannelijk", ageOptions[i]) ||
            _isAgeAlreadyAdded("Vrouwelijk", ageOptions[i]) ||
            _isAgeAlreadyAdded("Onbekend", ageOptions[i]);
      }

      // Only add visible buttons
      if (!disable) {
        if (visibleCount > 0) {
          result.add(const SizedBox(height: 8)); // Add spacing between buttons
        }
        result.add(Flexible(child: _buildAgeButton(ageOptions[i])));
        visibleCount++;
      }
    }

    // Add SizedBoxes at the end to maintain consistent height
    int hiddenCount = ageOptions.length - visibleCount;
    for (int i = 0; i < hiddenCount; i++) {
      if (result.isNotEmpty) {
        result.add(const SizedBox(height: 8)); // Add spacing
      }
      result.add(
        Flexible(child: SizedBox(height: 64.5)),
      ); // Same height as buttons
    }

    return result;
  }

  List<Widget> _buildGenderButtonsWithSpacing() {
    final List<Widget> result = [];
    final genderOptions = ["Mannelijk", "Vrouwelijk", "Onbekend"];

    // Count visible and hidden buttons
    int visibleCount = 0;

    // Add visible buttons with spacing
    for (int i = 0; i < genderOptions.length; i++) {
      // Check if all ages are filled for this gender
      bool disable = _areAllAgesFilledForGender(genderOptions[i]);

      // Only add visible buttons
      if (!disable) {
        if (visibleCount > 0) {
          result.add(const SizedBox(height: 8)); // Add spacing between buttons
        }
        result.add(Flexible(child: _buildGenderButton(genderOptions[i])));
        visibleCount++;
      }
    }

    // Add SizedBoxes at the end to maintain consistent height
    int hiddenCount = genderOptions.length - visibleCount;
    for (int i = 0; i < hiddenCount; i++) {
      if (result.isNotEmpty) {
        result.add(const SizedBox(height: 8)); // Add spacing
      }
      result.add(
        Flexible(child: SizedBox(height: 64.5)),
      ); // Same height as buttons
    }

    // Add an extra SizedBox at the end for alignment with age column
    // The age column has 4 options while gender has 3, so we need one extra space
    result.add(const SizedBox(height: 8)); // Add spacing
    result.add(
      Flexible(child: SizedBox(height: 64.5)),
    ); // Extra SizedBox for alignment

    return result;
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/models/enums/animal_age.dart';
import 'package:wildrapport/models/enums/animal_age_extensions.dart';
import 'package:wildrapport/models/enums/animal_gender.dart';
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
  int currentCount = 1; // Default to 1
  bool _forceRebuild = false;
  late final FixedExtentScrollController _countController;

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
    // Initialize the wheel controller with index matching value 1
    _countController = FixedExtentScrollController(
      initialItem: currentCount - 1,
    );
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _validateAndAddToList(BuildContext context) {
    // 1. Validate input first
    List<String> errors = [];
    bool missingAge = selectedAge == null;
    bool missingGender = selectedGender == null;

    // If both are missing, show combined message
    if (missingAge && missingGender) {
      errors.add('Selecteer een leeftijd en geslacht');
    } else {
      // Show specific messages for what's missing
      if (missingAge) {
        errors.add('Selecteer een leeftijd');
      }
      if (missingGender) {
        errors.add('Selecteer een geslacht');
      }
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
    final AnimalGender genderEnum = _convertStringToAnimalGender(
      selectedGender!,
    );

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
      currentCount = 1; // Reset to default 1

      // force rebuild trick stays if you still need it
      _forceRebuild = !_forceRebuild;
    });
    // Reset the wheel position to 1 as well (index 0)
    try {
      _countController.animateToItem(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } catch (_) {
      // In case controller isn't attached yet
      _countController.jumpToItem(0);
    }

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
                    height: 260, // Fixed height for the top section
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
                  // Add spacing between age/gender and Aantal section
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 2,
                    ),
                    child: Column(
                      children: [
                        // Header + instructional subtitle for the number picker
                        Column(
                          children: [
                            _buildHeader('Kies een aantal'),
                            const Text(
                              'Scroll om een aantal te kiezen',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Scrollable number picker like in the image
                        Container(
                          height: 120,
                          width: 100,
                          decoration: BoxDecoration(
                            color: AppColors.offWhite,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppColors.brown300,
                              width: 2,
                            ),
                          ),
                          child: ListWheelScrollView.useDelegate(
                            controller: _countController,
                            itemExtent: 40,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                currentCount = index + 1; // Values 1..100
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                final int value = index + 1;
                                final bool isSelected = value == currentCount;
                                return Center(
                                  child: Container(
                                    width: 70,
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AppColors.brown300
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$value',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: 100, // 1 to 100
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 350,
                          child: WhiteBulkButton(
                            text: "Voeg toe aan de lijst",
                            showIcon: false,
                            height: 50,
                            backgroundColor: AppColors.lightMintGreen100,
                            borderColor: AppColors.lightGreen,
                            // Ensure this button also uses Roboto/black and no drop shadow
                            textStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              color: Colors.black,
                            ),
                            showShadow: false,
                            onPressed: () => _validateAndAddToList(context),
                          ),
                        ),
                        // Add extra padding at the bottom to ensure the button is visible
                        SizedBox(height: 4),
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Roboto',
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
        backgroundColor:
            isSelected ? AppColors.brown300 : AppColors.lightMintGreen100,
        borderColor:
            isSelected ? AppColors.lightMintGreen100 : AppColors.brown300,
        hoverBackgroundColor: AppColors.brown300,
        hoverBorderColor: AppColors.lightMintGreen100,
        // Make the button text use Roboto and black, and remove drop shadows
        textStyle: const TextStyle(fontFamily: 'Roboto', color: Colors.black),
        showShadow: false,
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
        backgroundColor:
            isSelected ? AppColors.brown300 : AppColors.lightMintGreen100,
        borderColor:
            isSelected ? AppColors.lightMintGreen100 : AppColors.brown300,
        hoverBackgroundColor: AppColors.brown300,
        hoverBorderColor: AppColors.lightMintGreen100,
        // Make the button text use Roboto and black, and remove drop shadows
        textStyle: const TextStyle(fontFamily: 'Roboto', color: Colors.black),
        showShadow: false,
        onPressed: () => _handleGenderSelection(text),
      ),
    );
  }

  List<Widget> _buildAgeButtonsWithSpacing() {
    final List<Widget> result = [];
    final ageOptions = [
      AnimalAge.pasGeboren.label,
      AnimalAge.onvolwassen.label,
      AnimalAge.volwassen.label,
      AnimalAge.onbekend.label,
    ];

    // Always show all buttons - no filtering
    for (int i = 0; i < ageOptions.length; i++) {
      if (i > 0) {
        result.add(const SizedBox(height: 8)); // Add spacing between buttons
      }
      result.add(Flexible(child: _buildAgeButton(ageOptions[i])));
    }

    return result;
  }

  List<Widget> _buildGenderButtonsWithSpacing() {
    final List<Widget> result = [];
    final genderOptions = ["Mannelijk", "Vrouwelijk", "Onbekend"];

    // Always show all buttons - no filtering
    for (int i = 0; i < genderOptions.length; i++) {
      if (i > 0) {
        result.add(const SizedBox(height: 8)); // Add spacing between buttons
      }
      result.add(Flexible(child: _buildGenderButton(genderOptions[i])));
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

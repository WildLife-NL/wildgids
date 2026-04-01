import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/models/enums/animal_age.dart';
import 'package:wildgids/models/enums/animal_gender.dart';
import 'package:wildgids/models/enums/animal_condition.dart';
import 'package:wildgids/models/animal_waarneming_models/view_count_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
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

  void _handleBackNavigation() {
    if (widget.animalIndex > 0) {
      // Go to previous animal details
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimalWaarnemingDetailsScreen(
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
    final sightingManager =
        context.read<AnimalSightingReportingInterface>();
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
      condition: currentAnimal.condition,
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
      condition: currentAnimal.condition,
    );
    sightingManager.updateSelectedAnimal(freshAnimal);
    
    if (widget.animalIndex < widget.totalCount - 1) {
      // Reset state for next animal
      setState(() {
        selectedAge = AnimalAge.onbekend;
        selectedGender = AnimalGender.onbekend;
      });
      
      // Go to next animal details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimalWaarnemingDetailsScreen(
            animalIndex: widget.animalIndex + 1,
            totalCount: widget.totalCount,
          ),
        ),
      );
    } else {
      // Last animal - go to summary screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimalWaarnemingSummaryScreen(totalCount: widget.totalCount),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sightingManager =
        context.read<AnimalSightingReportingInterface>();
    final sighting = sightingManager.getCurrentanimalSighting();
    final selectedAnimal = sighting?.animalSelected;

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Heading
                          Center(
                            child: Text(
                              'Dier ${widget.animalIndex + 1} Details',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Animal card with image
                          Center(
                            child: SizedBox(
                              width: 180,
                              child: Card(
                                shadowColor: const Color.fromARGB(133, 0, 0, 0).withValues(alpha: 0.1),
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
                                        width: 180,
                                        height: 150,
                                        child: AspectRatio(
                                          aspectRatio: 1.0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(14),
                                                topRight: Radius.circular(14),
                                              ),
                                              color: Colors.white,
                                            ),
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(14),
                                                topRight: Radius.circular(14),
                                              ),
                                              child: SizedBox.expand(
                                                child: selectedAnimal.animalImagePath !=
                                                        null
                                                    ? Image(
                                                        image: AssetImage(
                                                          selectedAnimal.animalImagePath!,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Center(
                                                        child: Icon(
                                                          Icons
                                                              .image_not_supported_outlined,
                                                          size: 50,
                                                          color: Colors.grey[400],
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
                                      width: 180,
                                    ),
                                    // Name area
                                    Container(
                                      width: 180,
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
                                          fontSize: 16,
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
                          const SizedBox(height: 20),
                          // Age selector
                          _buildSelectorSection('Leeftijd:', [
                            AnimalAge.onbekend,
                            AnimalAge.pasGeboren,
                            AnimalAge.onvolwassen,
                            AnimalAge.volwassen,
                          ], (age) {
                            setState(() => selectedAge = age as AnimalAge);
                          }, selectedAge),
                          const SizedBox(height: 16),
                          // Gender selector
                          _buildSelectorSection('Geslacht:', [
                            AnimalGender.onbekend,
                            AnimalGender.mannelijk,
                            AnimalGender.vrouwelijk,
                          ], (gender) {
                            setState(() =>
                                selectedGender = gender as AnimalGender);
                          }, selectedGender),
                          const SizedBox(height: 20),
                          // Next animal button - only show if not the final animal
                          if (widget.animalIndex < widget.totalCount - 1)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                    color: const Color(0xFF999999),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: _handleNext,
                                child: const Text(
                                  '+ Volgende Dier',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
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
                          side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.3),
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
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF37A904),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          widget.animalIndex == widget.totalCount - 1
                              ? 'Indienen'
                              : 'Klaar met dieren',
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

  Widget _buildSelectorSection(
    String label,
    List<dynamic> options,
    Function(dynamic) onSelected,
    dynamic selectedValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            final label = _getEnumLabel(option);
            return OutlinedButton(
              onPressed: () => onSelected(option),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF333333)
                      : const Color(0xFF999999),
                  width: isSelected ? 2 : 1.5,
                ),
                backgroundColor:
                    isSelected ? const Color(0xFF333333) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
        case AnimalCondition.levend:
          return 'Levend';
        case AnimalCondition.andere:
          return 'Anders';
      }
    }
    return 'Onbekend';
  }
}

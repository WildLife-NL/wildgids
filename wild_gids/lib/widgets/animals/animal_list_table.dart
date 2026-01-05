import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/models/enums/animal_age.dart';
import 'package:wildgids/models/enums/animal_gender.dart';
import 'package:wildgids/models/animal_waarneming_models/view_count_model.dart';

class AnimalListTable extends StatefulWidget {
  const AnimalListTable({super.key});

  @override
  AnimalListTableState createState() => AnimalListTableState();
}

class AnimalListTableState extends State<AnimalListTable> {
  late final AnimalSightingReportingInterface _animalSightingManager;
  bool _isEditing = false;
  final TextEditingController _opmerkingController = TextEditingController();
  final Map<String, int> _tempCounts = {};
  final Map<String, TextEditingController> _controllers = {};

  String getDescription() {
    return _opmerkingController.text;
  }

  void clearTextFields() {
    _opmerkingController.clear();
    for (var controller in _controllers.values) {
      controller.clear();
    }
  }

  /// Completely reset all table data: description, temporary counts,
  /// underlying animal view counts in the active sighting.
  void clearAllData() {
    final animalSightingManager =
        context.read<AnimalSightingReportingInterface>();
    final currentSighting = animalSightingManager.getCurrentanimalSighting();

    // Reset description in manager and controller
    _opmerkingController.clear();
    animalSightingManager.updateDescription('');

    // Clear temp counts and controllers
    _tempCounts.clear();
    for (var controller in _controllers.values) {
      controller.clear();
    }

    // Reset all animal view counts to zero
    if (currentSighting?.animals != null) {
      for (var animal in currentSighting!.animals!) {
        final zeroViewCount = ViewCountModel(
          pasGeborenAmount: 0,
          onvolwassenAmount: 0,
          volwassenAmount: 0,
          unknownAmount: 0,
        );
        final updatedAnimal = AnimalModel(
          animalId: animal.animalId,
          animalImagePath: animal.animalImagePath,
          animalName: animal.animalName,
          genderViewCounts: [
            AnimalGenderViewCount(
              gender: animal.gender ?? AnimalGender.onbekend,
              viewCount: zeroViewCount,
            ),
          ],
          condition: animal.condition,
        );
        animalSightingManager.updateAnimal(updatedAnimal);
      }
    }

    setState(() {});
  }

  /// Clear only the remarks (Opmerkingen) field and manager description, keep counts intact.
  void clearRemarksOnly() {
    final animalSightingManager =
        context.read<AnimalSightingReportingInterface>();
    _opmerkingController.clear();
    animalSightingManager.updateDescription('');
    setState(() {});
  }

  // Formatter to cap numeric input at a maximum value.
  // Prevents entering numbers greater than [max] directly.
  // If user pastes a larger number it is truncated to max.
  static TextInputFormatter maxValueFormatter(int max) =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) return newValue;
        final value = int.tryParse(newValue.text) ?? 0;
        if (value > max) {
          return TextEditingValue(
            text: max.toString(),
            selection: TextSelection.collapsed(offset: max.toString().length),
          );
        }
        return newValue;
      });

  @override
  void initState() {
    super.initState();
    debugPrint('AnimalListTable - initState');
    _animalSightingManager = context.read<AnimalSightingReportingInterface>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('Adding listener to animalSightingManager');
        _animalSightingManager.addListener(_handleStateChange);
      }
    });

    final currentSighting = _animalSightingManager.getCurrentanimalSighting();
    _opmerkingController.text = currentSighting?.description ?? '';
  }

  @override
  void dispose() {
    _opmerkingController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }

    if (mounted) {
      _animalSightingManager.removeListener(_handleStateChange);
    }

    super.dispose();
  }

  void _handleStateChange() {
    if (mounted) {
      debugPrint(
        '_handleStateChange called - rebuilding table with new values',
      );
      setState(() {
        // This will trigger a rebuild of the table with new values
      });
    }
  }

  void toggleEditMode() {
    debugPrint('toggleEditMode: changing from $_isEditing to ${!_isEditing}');

    if (_isEditing) {
      // If we're currently in edit mode and toggling out, save the changes
      debugPrint('Exiting edit mode - saving changes');
      _saveChanges();
    } else {
      // Just entering edit mode, no need to save
      setState(() {
        _isEditing = true;
      });
    }
  }

  void saveChanges() {
    if (_isEditing) {
      _saveChanges();
    }
  }

  void _saveChanges() {
    final animalSightingManager =
        context.read<AnimalSightingReportingInterface>();
    final currentSighting = animalSightingManager.getCurrentanimalSighting();

    debugPrint(
      'Before updates - Current sighting: ${currentSighting?.toJson()}',
    );
    debugPrint('Temporary counts to save: $_tempCounts');

    // Save the description
    animalSightingManager.updateDescription(_opmerkingController.text);

    // Update counts for each animal
    if (currentSighting?.animals != null) {
      for (var animal in currentSighting!.animals!) {
        if (animal.gender == null) continue;

        debugPrint(
          'Updating animal: ${animal.animalName}, Gender: ${animal.gender}',
        );

        // Create new ViewCountModel with updated values
        final viewCount = ViewCountModel(
          pasGeborenAmount:
              _tempCounts['${AnimalAge.pasGeboren.name}_${animal.gender!.name}'] ??
              animal.viewCount?.pasGeborenAmount ??
              0,
          onvolwassenAmount:
              _tempCounts['${AnimalAge.onvolwassen.name}_${animal.gender!.name}'] ??
              animal.viewCount?.onvolwassenAmount ??
              0,
          volwassenAmount:
              _tempCounts['${AnimalAge.volwassen.name}_${animal.gender!.name}'] ??
              animal.viewCount?.volwassenAmount ??
              0,
          unknownAmount:
              _tempCounts['${AnimalAge.onbekend.name}_${animal.gender!.name}'] ??
              animal.viewCount?.unknownAmount ??
              0,
        );

        debugPrint(
          'New view counts for ${animal.animalName}: ${viewCount.toJson()}',
        );

        // Create updated animal with new view count
        final updatedAnimal = AnimalModel(
          animalId: animal.animalId,
          animalImagePath: animal.animalImagePath,
          animalName: animal.animalName,
          genderViewCounts: [
            AnimalGenderViewCount(gender: animal.gender!, viewCount: viewCount),
          ],
          condition: animal.condition,
        );

        // Update the animal in the manager
        debugPrint('Calling updateAnimal on manager with updated animal');
        animalSightingManager.updateAnimal(updatedAnimal);
      }
    }

    setState(() {
      _isEditing = false;
      _tempCounts.clear();
      _controllers.clear();
    });

    debugPrint(
      'After updates - Current sighting: ${animalSightingManager.getCurrentanimalSighting()?.toJson()}',
    );
  }

  // Helper method to get count from temporary storage

  // Helper method to store temporary count

  List<AnimalGender> _getUsedGenders(BuildContext context) {
    // Always return all three genders in the correct order: female, male, unknown
    return [
      AnimalGender.vrouwelijk,
      AnimalGender.mannelijk,
      AnimalGender.onbekend,
    ];
  }

  int _getCountForAgeAndGender(
    AnimalAge age,
    AnimalGender gender,
    BuildContext context,
  ) {
    final animalSightingManager =
        context.read<AnimalSightingReportingInterface>();
    final currentSighting = animalSightingManager.getCurrentanimalSighting();

    if (currentSighting?.animals == null || currentSighting!.animals!.isEmpty) {
      debugPrint('_getCountForAgeAndGender: No animals in sighting');
      return 0;
    }

    // Sum up counts from ALL animals in the list (not just the first one)
    int totalCount = 0;

    for (final animal in currentSighting.animals!) {
      // Find the gender view count for the specified gender
      final genderViewCount = animal.genderViewCounts.firstWhere(
        (gvc) => gvc.gender == gender,
        orElse:
            () => AnimalGenderViewCount(
              gender: gender,
              viewCount: ViewCountModel(),
            ),
      );

      // Add the count for the specified age
      switch (age) {
        case AnimalAge.pasGeboren:
          totalCount += genderViewCount.viewCount.pasGeborenAmount;
          break;
        case AnimalAge.onvolwassen:
          totalCount += genderViewCount.viewCount.onvolwassenAmount;
          break;
        case AnimalAge.volwassen:
          totalCount += genderViewCount.viewCount.volwassenAmount;
          break;
        case AnimalAge.onbekend:
          totalCount += genderViewCount.viewCount.unknownAmount;
          break;
      }
    }

    debugPrint(
      '_getCountForAgeAndGender: Total count for Age: ${age.name}, Gender: ${gender.name} = $totalCount (from ${currentSighting.animals!.length} animals)',
    );
    return totalCount;
  }

  // Get or create controller for a specific cell
  TextEditingController _getController(AnimalAge age, AnimalGender gender) {
    final key = '${age.name}_${gender.name}';
    if (!_controllers.containsKey(key)) {
      final currentCount = _getCurrentCount(age, gender);
      _controllers[key] = TextEditingController(text: currentCount.toString());
    }
    return _controllers[key]!;
  }

  int _getCurrentCount(AnimalAge age, AnimalGender gender) {
    final key = '${age.name}_${gender.name}';
    if (_isEditing) {
      // During editing, prefer temp counts but fall back to actual counts
      final count =
          _tempCounts[key] ?? _getCountForAgeAndGender(age, gender, context);
      debugPrint('_getCurrentCount for $key (editing mode): $count');
      return count;
    }
    final count = _getCountForAgeAndGender(age, gender, context);
    debugPrint('_getCurrentCount for $key (view mode): $count');
    return count;
  }

  // _handleNextPressed method has been removed

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the animal sighting manager
    final animalSightingManager =
        context.watch<AnimalSightingReportingInterface>();
    final currentSighting = animalSightingManager.getCurrentanimalSighting();
    final usedGenders = _getUsedGenders(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Table(
                          border: TableBorder.all(
                            color: Colors.black,
                            width: 1,
                          ),
                          columnWidths: {
                            0: const FlexColumnWidth(2.0),
                            for (var i = 0; i < usedGenders.length; i++)
                              i + 1: const FlexColumnWidth(1.0),
                          },
                          children: [
                            _buildHeaderRow(usedGenders),
                            ...List.generate(
                              4,
                              (index) => _buildDataRow(
                                index + 1,
                                usedGenders,
                                context,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDescriptionSection(currentSighting!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(List<AnimalGender> usedGenders) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            height: 50.0,
            // Removed per-cell border to prevent double thick lines (TableBorder already draws grid)
            decoration: const BoxDecoration(color: Colors.white),
            child: const Padding(
              padding: EdgeInsets.all(5.0),
              child: Center(
                child: Text(
                  'Leeftijd',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        ...usedGenders.map((gender) => _buildHeaderCell(gender)),
      ],
    );
  }

  Widget _buildHeaderCell(AnimalGender gender) {
    String icon;
    switch (gender) {
      case AnimalGender.vrouwelijk:
        icon = 'â™€';
        break;
      case AnimalGender.mannelijk:
        icon = 'â™‚';
        break;
      case AnimalGender.onbekend:
        icon = '?';
        break;
    }

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Container(
        height: 50.0,
        // Removed per-cell border to avoid doubled lines
        decoration: const BoxDecoration(color: Colors.white),
        child: Center(
          child: Text(
            icon,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  TableRow _buildDataRow(
    int index,
    List<AnimalGender> usedGenders,
    BuildContext context,
  ) {
    AnimalAge age;
    String ageLabel;

    switch (index) {
      case 1:
        age = AnimalAge.pasGeboren;
        ageLabel = 'Pas geboren';
        break;
      case 2:
        age = AnimalAge.onvolwassen;
        ageLabel = 'Jong';
        break;
      case 3:
        age = AnimalAge.volwassen;
        ageLabel = 'Volwassen';
        break;
      case 4:
        age = AnimalAge.onbekend;
        ageLabel = 'Onbekend';
        break;
      default:
        age = AnimalAge.onbekend;
        ageLabel = 'Onbekend';
    }

    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            // Removed per-cell border (grid handled by TableBorder)
            decoration: const BoxDecoration(color: Colors.white),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                ageLabel,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        ...usedGenders.map((gender) => _buildDataCell(age, gender, context)),
      ],
    );
  }

  TableCell _buildDataCell(
    AnimalAge age,
    AnimalGender gender,
    BuildContext context,
  ) {
    final count = _getCurrentCount(age, gender);
    debugPrint(
      'Building cell for Age: ${age.name}, Gender: ${gender.name}, Count: $count, IsEditing: $_isEditing',
    );

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Container(
        height: 50.0,
        // Removed per-cell border (TableBorder provides lines)
        decoration: const BoxDecoration(color: Colors.white),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child:
                _isEditing
                    ? TextFormField(
                      controller: _getController(age, gender),
                      minLines: 1,
                      maxLines: null,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                        AnimalListTableState.maxValueFormatter(100),
                      ],
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        border: InputBorder.none,
                        label: Text('type..'),
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      onTap: () {
                        // Clear the text when tapped
                        final controller = _getController(age, gender);
                        final key = '${age.name}_${gender.name}';
                        // Store the current value in tempCounts before clearing
                        if (!_tempCounts.containsKey(key)) {
                          _tempCounts[key] = int.tryParse(controller.text) ?? 0;
                        }
                        // Clear the text
                        controller.text = "";
                      },
                      onChanged: (value) {
                        if (!mounted) return;
                        var count = int.tryParse(value) ?? 0;
                        if (count > 100) {
                          count = 100;
                          final controller = _getController(age, gender);
                          controller.text = '100';
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                        }
                        final key = '${age.name}_${gender.name}';
                        _tempCounts[key] = count;
                        debugPrint('Updated temp count: $key = $count');
                      },
                    )
                    : Text(
                      count == 0 ? '' : count.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(AnimalSightingModel currentSighting) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opmerkingen',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            // Removed fixed height so the field can expand as user types.
            // Constrain only the minimum height to keep initial single-line appearance.
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.brown.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _opmerkingController,
                  minLines: 1,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    label: Text('Typ hier...'),
                  ),
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move the listener setup here to prevent multiple attachments
    final manager = context.read<AnimalSightingReportingInterface>();
    manager.removeListener(_handleStateChange); // Remove any existing listener
    manager.addListener(_handleStateChange);
  }
}


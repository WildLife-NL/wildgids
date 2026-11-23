import 'package:wildgids/widgets/guide/animal_name.dart';
import 'package:wildgids/widgets/reporting/report_layout.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';
import 'package:flutter/material.dart';
import 'package:wildgids/widgets/shared_ui_widgets/category_picker.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';

import 'package:wildgids/screens/waarneming/animal_aantal_screen.dart';
import 'package:wildgids/widgets/guide/animal_artwork.dart';
import 'package:wildgids/utils/species_image_resolver.dart';

class AnimalsScreen extends StatefulWidget {
  final String appBarTitle;

  const AnimalsScreen({super.key, required this.appBarTitle});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimalManagerInterface _animalManager;
  late final AnimalSightingReportingInterface _animalSightingManager;
  late final NavigationStateInterface _navigationManager;
  late final AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  List<AnimalModel>? _animals;
  String? _error;
  bool _isLoading = true;
  List<String> _categories = ['Alle'];
  String _selectedCategory = 'Alle';

  @override
  void initState() {
    super.initState();
    debugPrint('[AnimalsScreen] Initializing screen');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Set a default duration
    );
    _animalManager = context.read<AnimalManagerInterface>();
    _animalSightingManager = context.read<AnimalSightingReportingInterface>();
    _navigationManager = context.read<NavigationStateInterface>();
    _animalManager.addListener(_handleStateChange);
    _validateAndLoad();
    _loadCategories();
  }

  void _validateAndLoad() {
    // Try to validate and set up sighting context, but don't block screen load
    final isValid = _animalSightingManager.validateActiveAnimalSighting();
    if (!isValid) {
      debugPrint(
        '[AnimalsScreen] No active animal sighting - attempting to initialize',
      );
      // Try to create a basic sighting state if needed
    }
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    debugPrint('[AnimalsScreen] Starting to load animals');
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      debugPrint(
        '[AnimalsScreen] Calling getAnimalsByBackendCategory with category: $_selectedCategory',
      );
      final animals = await _animalManager.getAnimalsByBackendCategory(
        category: _selectedCategory == 'Alle' ? null : _selectedCategory,
      );

      debugPrint('[AnimalsScreen] API returned ${animals.length} animals');

      // Filter out the placeholder/unknown entry from the selection list
      final filtered =
          animals.where((a) {
            final name = a.animalName.trim().toLowerCase();
            final id = (a.animalId ?? '').trim().toLowerCase();
            return name != 'onbekend' && id != 'unknown';
          }).toList();

      debugPrint(
        '[AnimalsScreen] Successfully loaded ${animals.length} animals (showing ${filtered.length} after filtering unknown)',
      );

      if (mounted) {
        setState(() {
          _animals = filtered;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[AnimalsScreen] ERROR: Failed to load animals');
      debugPrint('[AnimalsScreen] Error details: $e');
      debugPrint('[AnimalsScreen] Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    debugPrint('[AnimalsScreen] Disposing screen');
    _scrollController.dispose();
    _animationController.dispose();
    _animalManager.removeListener(_handleStateChange);
    super.dispose();
  }

  void _handleStateChange() {
    if (mounted) {
      _loadAnimals();
    }
  }

  // _toggleExpanded removed â€” dropdown replaced by custom filter UI

  void _handleAnimalSelection(AnimalModel selectedAnimal) {
    _animalSightingManager.processAnimalSelection(
      selectedAnimal,
      _animalManager,
    );

    _navigationManager.pushForward(context, const AnimalAantalScreen());
  }

  void _handleBackNavigation() {
    debugPrint('[AnimalsScreen] Back button pressed');
    // Reset search before navigating back
    _animalManager.updateSearchTerm('');
    // Prefer popping; if stack was cleared, reset to home to avoid a blank screen
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      _navigationManager.resetToHome(context);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _animalManager.getBackendCategories();
      if (mounted) {
        setState(() {
          _categories = ['Alle', ...categories];
        });
      }
    } catch (e) {
      debugPrint('[AnimalsScreen] Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) => ReportLayout(
    title: 'Welk dier zag je?',
    stage: 'Dier kiezen',
    onBack: _handleBackNavigation,
    scroll: false,
    child: CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: CategoryPicker(
              categories: _categories,
              selected: _selectedCategory,
              enabled: !_isLoading && _error == null,
              onChanged: (category) {
                setState(() => _selectedCategory = category);
                _loadAnimals();
              },
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: GuideStyle.ink),
            ),
          )
        else if (_error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('De dieren konden niet worden geladen.'),
                  TextButton(
                    onPressed: _loadAnimals,
                    child: const Text('Opnieuw proberen'),
                  ),
                ],
              ),
            ),
          )
        else if (_animals?.isEmpty ?? true)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Geen dieren in deze categorie.')),
          )
        else
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AnimalName.gridColumns(
                context,
                _animals!.map((animal) => animal.animalName),
                width:
                    MediaQuery.sizeOf(context).width.clamp(0, 680).toDouble() -
                    40,
                reserved: 24,
              ),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent:
                  215 + (MediaQuery.textScalerOf(context).scale(1) - 1) * 80,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final animal = _animals![index];
              return Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: GuideStyle.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _handleAnimalSelection(animal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: AnimalArtwork(
                          imagePath:
                              SpeciesImageResolver.drawingForCommonName(
                                animal.animalName,
                              ) ??
                              animal.animalImagePath,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: AnimalName(
                          animal.animalName,
                          style: const TextStyle(
                            color: GuideStyle.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: _animals!.length),
          ),
      ],
    ),
  );
}

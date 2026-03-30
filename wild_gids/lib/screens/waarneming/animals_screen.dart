import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';

import 'package:wildgids/screens/waarneming/animal_counting_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/widgets/animals/scrollable_animal_grid.dart';

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
  // dropdown expansion state no longer used (custom UI)
  final TextEditingController _searchController = TextEditingController();
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
    // Ensure search is reset when (re)entering this screen
    _searchController.text = '';
    _searchController.addListener(() => setState(() {}));
    _animalManager.updateSearchTerm('');
    _animalManager.addListener(_handleStateChange);
    _validateAndLoad();
    _loadCategories();
  }

  void _validateAndLoad() {
    // Try to validate and set up sighting context, but don't block screen load
    final isValid = _animalSightingManager.validateActiveAnimalSighting();
    if (!isValid) {
      debugPrint('[AnimalsScreen] No active animal sighting - attempting to initialize');
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

      debugPrint('[AnimalsScreen] Calling getAnimalsByBackendCategory with category: $_selectedCategory');
      final animals = await _animalManager.getAnimalsByBackendCategory(
        category: _selectedCategory == 'Alle' ? null : _selectedCategory,
      );

      debugPrint('[AnimalsScreen] API returned ${animals.length} animals');

      // Filter out the placeholder/unknown entry from the selection list
      final filtered = animals.where((a) {
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
    _searchController.dispose();
    // Remove listener BEFORE clearing search term to prevent setState on disposed widget
    _animalManager.removeListener(_handleStateChange);
    // Clear any lingering search term so future visits show all animals
    _animalManager.updateSearchTerm('');
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

    _navigationManager.pushForward(context, AnimalCountingScreen());
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
      await _animalManager.getBackendCategories();
    } catch (e) {
      // Keep empty list on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    // New waarneming-styled layout: grey background, Waarneming header,
    // and a card container with search + animal grid.

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Waarneming',
              rightIcon: null,
              showUserIcon: false,
              useFixedText: true,
              onLeftIconPressed: _handleBackNavigation,
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.4,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 12, 0, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecteer Dier:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 4),
                        // Search bar
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.2),
                              width: 1.2,
                            ),
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.black.withValues(alpha: 0.6),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Zoeken...',
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    suffixIcon:
                                        (_searchController.text.isNotEmpty)
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                _animalManager
                                                    .updateSearchTerm('');
                                                setState(() {});
                                              },
                                            )
                                            : null,
                                  ),
                                  onChanged: (val) {
                                    _animalManager.updateSearchTerm(val);
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Animal grid fills remaining space
                        Expanded(
                          child: ScrollableAnimalGrid(
                            animals: _animals,
                            isLoading: _isLoading,
                            error: _error,
                            scrollController: _scrollController,
                            onAnimalSelected: _handleAnimalSelection,
                            onRetry: _loadAnimals,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

